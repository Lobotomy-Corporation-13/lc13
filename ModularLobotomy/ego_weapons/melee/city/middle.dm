// The Middle - Syndicate that uses chains as weapons
// Each rank has their own chain weapon with different stats

//Little Brother Chain
/obj/item/ego_weapon/shield/middle_chain
	name = "little brother's chain"
	desc = "A heavy chain used by The Little Brothers of the Middle. Swung with brutal efficiency."
	special = "Blocking will counter-attack the attacker and inflicts Vengeance Mark to the attacker. This weapon deals more damage depending on how much Vengeance Mark the target has."
	icon = 'ModularLobotomy/_Lobotomyicons/middle_icons.dmi'
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/middle_worn_l.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/middle_worn_r.dmi'
	icon_state = "lil_chain"
	force = 34
	attack_speed = 1.2
	damtype = BLACK_DAMAGE

	attack_verb_continuous = list("whips", "lashes", "strikes", "batters")
	attack_verb_simple = list("whip", "lash", "strike", "batter")
	hitsound = 'sound/weapons/fixer/generic/middle_attack.ogg'

	reductions = list(20, 20, 20, 20) // 80
	projectile_block_duration = 1 SECONDS
	block_duration = 1 SECONDS
	block_cooldown = 3 SECONDS
	block_sound = 'sound/weapons/fixer/generic/middle_counter.ogg'
	projectile_block_message ="Your chains swats the projectile away!"
	block_message = "You attempt to counter the attack!"
	hit_message = "counters the attack!"
	block_cooldown_message = "You reposition your chains."

	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 60,
	)

	// Counter-attack system
	var/mob/living/last_attacker = null
	// Vengeance Mark system
	var/vengeance_mark_stacks_per_hit = 4
	var/vengeance_damage_bonus = 0.03 // 3% per stack for Little Brother
	var/counter_damage_multiplier = 1.4 // 40% bonus damage on counter-attacks
	var/countering = FALSE

/obj/item/ego_weapon/shield/middle_chain/attack_self(mob/user)//FIXME: Find a better way to use this override!
	if(block == 0) //Extra check because shields returns nothing on 1
		if(..())
			// Add purple color effect when blocking
			if(ishuman(user))
				var/mob/living/carbon/human/H = user
				H.add_atom_colour("#8B008B", TEMPORARY_COLOUR_PRIORITY) // Dark purple/magenta color

			// Register signals to disable blocking when attacked by hand or item
			RegisterSignal(user, COMSIG_ATOM_ATTACK_HAND, PROC_REF(NoParry), override = TRUE)//creates runtimes without overrides, double check if something's fucked
			RegisterSignal(user, COMSIG_PARENT_ATTACKBY, PROC_REF(NoParry), override = TRUE)//728 and 729 must be able to unregister the signal of 730
			// Register signals to capture attacker for counter-attack
			RegisterSignal(user, COMSIG_ATOM_ATTACK_HAND, PROC_REF(CaptureAttacker), override = TRUE)
			RegisterSignal(user, COMSIG_PARENT_ATTACKBY, PROC_REF(CaptureAttacker), override = TRUE)
			RegisterSignal(user, COMSIG_ATOM_ATTACK_ANIMAL, PROC_REF(CaptureAttacker), override = TRUE)
			countering = TRUE
			return TRUE
		else
			return FALSE

/obj/item/ego_weapon/shield/middle_chain/proc/NoParry(mob/living/carbon/human/user, obj/item/L)//Disables AnnounceBlock when attacked by an item or a human
	SIGNAL_HANDLER
	UnregisterSignal(user, COMSIG_MOB_APPLY_DAMGE)//y'all can't behave

//Captures the attacker reference when user is attacked
/obj/item/ego_weapon/shield/middle_chain/proc/CaptureAttacker(mob/living/carbon/human/user, attacker)
	SIGNAL_HANDLER
	if(isliving(attacker))
		last_attacker = attacker
	else if(istype(attacker, /obj/item))
		// When attacked by an item, the user parameter in COMSIG_PARENT_ATTACKBY is actually the attacker
		if(isliving(user))
			last_attacker = user

/obj/item/ego_weapon/shield/middle_chain/AnnounceBlock(mob/living/carbon/human/source, damage, damagetype, def_zone)
	// Perform counter-attack if we have a valid attacker
	if(last_attacker && !QDELETED(last_attacker))
		// Apply counter-attack damage bonus (40% more damage)
		var/original_force = initial(force)
		force = round(force * counter_damage_multiplier)

		// Perform counter-attack
		source.do_attack_animation(last_attacker)
		last_attacker.attacked_by(src, source)
		var/atom/throw_target = get_edge_target_turf(last_attacker, source.dir)
		last_attacker.throw_at(throw_target, rand(2, 3), 3, source)
		to_chat(source, span_userdanger("Your chains lash out at [last_attacker]!"))
		log_combat(source, last_attacker, "counters with", src.name, "(DAMTYPE: [uppertext(damtype)])")
		playsound(get_turf(last_attacker), hitsound, 50, TRUE)

		// Apply Vengeance Mark stacks after counter-attack
		if(isliving(last_attacker))
			last_attacker.apply_vengeance_mark(vengeance_mark_stacks_per_hit)

		// Reset force and clear attacker
		force = original_force
		last_attacker = null

	..()

//Override DisableBlock to clean up attacker-tracking signals and remove color
/obj/item/ego_weapon/shield/middle_chain/DisableBlock(mob/living/carbon/human/user)
	// Remove purple color effect
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#8B008B")

	// Unregister attacker-tracking signals
	UnregisterSignal(user, COMSIG_ATOM_ATTACK_HAND)
	UnregisterSignal(user, COMSIG_PARENT_ATTACKBY)
	UnregisterSignal(user, COMSIG_ATOM_ATTACK_ANIMAL)
	// Clear attacker reference
	last_attacker = null
	// Call parent DisableBlock
	countering = FALSE
	..()

//Override attack to apply Vengeance Mark bonus damage (but not apply stacks - only counter-attacks apply stacks)
/obj/item/ego_weapon/shield/middle_chain/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return FALSE

	// Check for Vengeance Mark and calculate bonus damage
	var/datum/status_effect/stacking/vengeance_mark/VM = target.has_status_effect(STATUS_EFFECT_VENGEANCEMARK)
	var/original_force = initial(force)
	if(VM && VM.stacks > 0)
		var/bonus_multiplier = 1 + (VM.stacks * vengeance_damage_bonus)
		force = round(force * bonus_multiplier)
		to_chat(user, span_danger("Your chains strike with vengeful fury! ([VM.stacks] marks)"))

	// Perform attack
	. = ..()

	// Reset force
	force = original_force

//Younger Brother Chain
/obj/item/ego_weapon/shield/middle_chain/younger
	name = "younger brother's chain"
	desc = "A reinforced chain used by The Younger Brothers of the Middle. Heavier and more lethal than the standard chain."
	icon_state = "mid_chain"
	force = 49
	attack_speed = 1.3
	reductions = list(40, 40, 40, 40) // 160
	vengeance_damage_bonus = 0.05 // 5% per stack for Younger Brother
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 80,
	)

//Big Brother Chain
/obj/item/ego_weapon/shield/middle_chain/big
	name = "big brother's chain"
	desc = "A masterfully crafted chain used by The Big Brothers of the Middle. Each link is a weapon in itself."
	special = "This weapon blocks projectiles while attacking. When blocking a projectile, teleports to the shooter and counter-attacks them. Blocking will counter-attack the attacker and inflicts Vengeance Mark to the attacker. This weapon deals more damage depending on how much Vengeance Mark the target has."
	icon_state = "big_chain"
	force = 63
	attack_speed = 1.4
	hitsound = 'sound/weapons/fixer/generic/middle_big_attack.ogg'
	reductions = list(60, 60, 60, 60) // 240
	vengeance_damage_bonus = 0.08 // 8% per stack for Big Brother
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100,
	)

// Override hit_reaction to teleport to projectile firer
/obj/item/ego_weapon/shield/middle_chain/big/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	if(attack_type == PROJECTILE_ATTACK && countering)
		// Get the projectile's firer
		var/obj/projectile/P = hitby
		if(istype(P) && P.firer && !QDELETED(P.firer))
			var/mob/living/firer = P.firer
			if(isliving(firer))
				// Get position next to the firer
				var/turf/target_turf = get_step(get_turf(firer), pick(GLOB.cardinals))
				if(target_turf)
					// Teleport to firer
					owner.forceMove(target_turf)
					owner.setDir(get_dir(owner, firer))

					// Visual and audio effects
					new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(owner), owner.dir)
					playsound(get_turf(owner), 'sound/weapons/fwoosh.ogg', 50, TRUE)
					owner.visible_message(span_warning("[owner] chains suddenly lash out, pulling them toward [firer]!"))

					// Perform counter-attack on the firer
					var/original_force = initial(force)
					// DISABLED: Counter damage multiplier causing unlimited damage
					force = round(force * counter_damage_multiplier)
					owner.do_attack_animation(firer)
					firer.attacked_by(src, owner)

					// Apply Vengeance Mark
					if(isliving(firer))
						firer.apply_vengeance_mark(vengeance_mark_stacks_per_hit)

					var/atom/throw_target = get_edge_target_turf(firer, owner.dir)
					firer.throw_at(throw_target, rand(2, 3), 3, owner)
					to_chat(owner, span_userdanger("Your chains lash out at [firer]!"))
					log_combat(owner, firer, "teleport-counters with", src.name, "(DAMTYPE: [uppertext(damtype)])")
					playsound(get_turf(firer), hitsound, 50, TRUE)

					// Reset force
					force = original_force

		// Call parent to handle the projectile block
		return ..()
	return ..()
