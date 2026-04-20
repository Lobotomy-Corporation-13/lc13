////////////////////////////////////////////////////////////
// EYE OF ODIN
//
// A cybernetic eye organ for Thumbfathers. Grants precognitive melee evasion.
//
// === PRECOGNITION STACKS ===
// Starts at 30/30. When the user would take melee or ranged damage, they have a chance to evade.
// Evasion chance scales linearly with stacks: 100% at 30, 40% at 1.
// - Melee: costs max(1, CEILING(damage / 10, 1)) stacks per evade
// - Ranged: costs max(1, CEILING(damage / 25, 1)) stacks per evade (more efficient vs projectiles)
// No cooldown on evasion. Creates an afterimage and shifts the user to a random adjacent tile.
//
// === REGENERATION ===
// Regains 10 stacks every 5 seconds, capped at 30. Uses on_life() with world.time tracking.
//
// === OVERHEAT ===
// When stacks reach 0, the eye overheats for 30 seconds:
// - No evasion, no stack regeneration
// - Each melee hit deals 5% of incoming damage as clone damage
// - Eye color changes from bright red to dark red
// After 30 seconds, stacks fully restore to 30 and eye returns to bright red.
////////////////////////////////////////////////////////////

/obj/item/organ/eyes/robotic/odin_eye
	name = "Eye of Odin"
	desc = "A cybernetic eye implant gifted to a Thumbfather. It replaces the right eye with a glowing red optic that grants precognitive reflexes, allowing the user to evade incoming melee attacks - but overuse burns out the implant temporarily."
	icon = 'icons/obj/spider_house/thumb/thumb_spider_icon.dmi'
	icon_state = "odin_eye"
	eye_color = "FF0000"
	organ_flags = ORGAN_UNREMOVABLE
	/// Current precognition stacks
	var/precognition_stacks = 30
	/// Maximum precognition stacks
	var/max_stacks = 30
	/// Whether the eye is currently overheated
	var/overheated = FALSE
	/// World time when the overheat ends
	var/overheat_end_time = 0
	/// World time when stacks next regenerate
	var/next_regen_time = 0
	/// Eye color when functioning normally
	var/bright_red = "FF0000"
	/// Eye color when overheated
	var/dark_red = "8B0000"

/obj/item/organ/eyes/robotic/odin_eye/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = FALSE, initialising)
	. = ..()
	if(!owner)
		return
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_damage_taken))
	precognition_stacks = max_stacks
	overheated = FALSE
	overheat_end_time = 0
	next_regen_time = world.time + 5 SECONDS

/obj/item/organ/eyes/robotic/odin_eye/Remove(mob/living/carbon/M, special = 0)
	if(M)
		UnregisterSignal(M, COMSIG_MOB_APPLY_DAMGE)
	precognition_stacks = max_stacks
	overheated = FALSE
	overheat_end_time = 0
	eye_color = bright_red
	return ..()

/obj/item/organ/eyes/robotic/odin_eye/on_life()
	. = ..()
	if(!owner || owner.stat == DEAD)
		return

	// Check overheat expiry
	if(overheated)
		if(overheat_end_time > 0 && world.time >= overheat_end_time)
			end_overheat()
		return

	// Stack regeneration every 5 seconds
	if(precognition_stacks < max_stacks && world.time >= next_regen_time)
		var/old_stacks = precognition_stacks
		precognition_stacks = min(precognition_stacks + 10, max_stacks)
		next_regen_time = world.time + 5 SECONDS
		if(precognition_stacks > old_stacks)
			to_chat(owner, span_notice("Your Eye of Odin regenerates precognition. Stacks: [precognition_stacks]/[max_stacks]."))

/obj/item/organ/eyes/robotic/odin_eye/examine(mob/user)
	. = ..()
	if(ishuman(loc))
		if(overheated)
			. += span_danger("The eye is dark and smoldering - it has overheated!")
		else
			. += span_notice("The eye glows with a steady red light. Precognition stacks: [precognition_stacks]/[max_stacks].")

/// Signal handler for incoming damage. Evades melee and ranged attacks by consuming precognition stacks.
/// Melee: costs CEILING(damage / 10, 1) stacks. Ranged: costs CEILING(damage / 25, 1) stacks.
/obj/item/organ/eyes/robotic/odin_eye/proc/on_damage_taken(datum/source, damage, damagetype, def_zone, attack_source, flags, attack_type)
	SIGNAL_HANDLER
	if(!damage || damage <= 0)
		return

	var/is_melee = (attack_type & ATTACK_TYPE_MELEE)
	var/is_ranged = (attack_type & ATTACK_TYPE_RANGED)
	if(!is_melee && !is_ranged)
		return

	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return

	// Overheated: no evasion, take 5% clone damage on melee hits instead
	if(overheated)
		if(is_melee)
			var/clone_damage = damage * 0.05
			if(clone_damage > 0)
				INVOKE_ASYNC(src, PROC_REF(apply_clone_damage), clone_damage)
		return

	// Evade the attack - chance scales with stacks: 100% at 30, 40% at 1 (linear)
	if(precognition_stacks > 0)
		var/evade_chance = 40 + ((precognition_stacks - 1) * 60 / (max_stacks - 1))
		if(!prob(evade_chance))
			return
		// Afterimage at current position, then shift to a random adjacent tile
		new /obj/effect/temp_visual/decoy/fading(get_turf(H), H)
		var/turf/T = get_step(H, pick(GLOB.cardinals))
		if(T && !T.density)
			H.forceMove(T)
		playsound(H, 'sound/weapons/black_silence/evasion.ogg', 50, TRUE)
		// Consume stacks based on attack type (always at least 1)
		// Melee: damage/10 per stack. Ranged: damage/25 per stack (more efficient vs projectiles)
		var/stack_divisor = is_melee ? 10 : 25
		var/stacks_to_lose = max(1, CEILING(damage / stack_divisor, 1))
		precognition_stacks = max(0, precognition_stacks - stacks_to_lose)
		if(precognition_stacks <= 0)
			INVOKE_ASYNC(src, PROC_REF(enter_overheat))
		return COMPONENT_MOB_DENY_DAMAGE

/// Applies clone damage to the owner
/obj/item/organ/eyes/robotic/odin_eye/proc/apply_clone_damage(damage)
	if(QDELETED(owner) || owner.stat == DEAD)
		return
	owner.adjustCloneLoss(damage)

/// Enters the overheat state: no evasion for 30 seconds, eye turns dark red
/obj/item/organ/eyes/robotic/odin_eye/proc/enter_overheat()
	if(overheated)
		return
	overheated = TRUE
	precognition_stacks = 0
	overheat_end_time = world.time + 30 SECONDS
	// Change eye color to dark red
	eye_color = dark_red
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.eye_color = dark_red
		H.regenerate_icons()
	to_chat(owner, span_userdanger("Your Eye of Odin overheats! Your precognitive vision fades..."))

/// Ends the overheat state: restores stacks to max, eye returns to bright red
/obj/item/organ/eyes/robotic/odin_eye/proc/end_overheat()
	if(!overheated)
		return
	overheated = FALSE
	overheat_end_time = 0
	precognition_stacks = max_stacks
	next_regen_time = world.time + 5 SECONDS
	// Change eye color back to bright red
	eye_color = bright_red
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.eye_color = bright_red
		H.regenerate_icons()
	to_chat(owner, span_nicegreen("Your Eye of Odin cools down. Precognitive vision restored. Stacks: [precognition_stacks]/[max_stacks]."))
