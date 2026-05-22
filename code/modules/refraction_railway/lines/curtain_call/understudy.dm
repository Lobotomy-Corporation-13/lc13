/*
 * Curtain Call - zeal_s2n1: The Understudy.
 * A variant of The Envy of Humanity. It has no self of its own — it fights
 * by wearing premade, AI-controlled human "skins" cut from city roles. Break
 * a skin and the true form is dragged out into the open: stunned, chipped for
 * a chunk of HP, and a little more fragile than before. A few seconds later
 * it pulls on another face. When the true form finally falls, the act ends.
 *
 * Architecture: only the TRUE FORM is registered with the wave controller, so
 * killing a skin never clears the node — only the true form's death does.
 * Skins are code-spawned carbon humans the true form hides inside (à la
 * Envy's AssumeForm/RevertForm); they're never wave-registered.
 *
 * Each skin carries its role's gear (EGO requirements stripped so the AI can
 * use it, and TRAIT_NODROP so players can't disarm it), is stun/push/sleep
 * immune, has ~500 HP from Fortitude, hits at simple-mob strength, moves
 * slowed, runs a locked-weapon murder AI, and has one telegraphed, dodgeable
 * signature attack.
 */

// ---------- Telegraph ----------

/obj/effect/temp_visual/understudy_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#b026ff"
	duration = 8

// ---------- Movement slow for skins ----------

/datum/movespeed_modifier/understudy_form
	multiplicative_slowdown = 1.5

// ---------- Custom murder AI: keeps its costume weapon ----------
// Same target/approach/attack behaviour as the base insane murderer, but it
// never scavenges or swaps weapons — it fights with the face it was given.
/datum/ai_controller/insane/murder/understudy

/datum/ai_controller/insane/murder/understudy/TryFindWeapon(is_white_allowed = TRUE)
	return null

// ---------- True form ----------
// Display name is "The Envy of Humanity"; the `understudy` type path is kept
// as the internal identifier (distinct from the base distortion Envy).
/mob/living/simple_animal/hostile/understudy
	name = "The Envy of Humanity"
	desc = "A writhing, shifting mass that hungers to become what it can never \
		truly be. It wears other people's lives like costumes."
	icon = 'ModularLobotomy/_Lobotomyicons/resurgence_64x96.dmi'
	icon_state = "envy"
	pixel_x = -16
	base_pixel_x = -16
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	faction = list("serio_zeal")
	maxHealth = 2500
	health = 2500
	melee_damage_lower = 20
	melee_damage_upper = 28
	melee_damage_type = BLACK_DAMAGE
	move_to_delay = 4
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	attack_sound = 'sound/hallucinations/growl1.ogg'
	damage_coeff = list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 0.4, PALE_DAMAGE = 0.8)
	del_on_death = FALSE
	refraction_manages_own_death = TRUE
	loot = list()

	/// HP chipped off the true form each time a skin is broken.
	var/reveal_damage = 300
	var/reveal_stun_time = 4 SECONDS
	var/reform_delay = 5 SECONDS
	var/reveals_done = 0
	/// Worsening resistances applied on each reveal (index = reveals_done).
	var/list/resist_tiers = list(
		list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 0.4, PALE_DAMAGE = 0.8),
		list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 1.0),
		list(RED_DAMAGE = 1.0, WHITE_DAMAGE = 1.0, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.2),
		list(RED_DAMAGE = 1.25, WHITE_DAMAGE = 1.25, BLACK_DAMAGE = 1.0, PALE_DAMAGE = 1.5),
		list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1.25, PALE_DAMAGE = 2.0),
	)
	/// The skins it can wear (drawn at random, no immediate repeats).
	var/list/form_pool = list(
		/mob/living/carbon/human/understudy_form/ronin,
		/mob/living/carbon/human/understudy_form/butcher,
		/mob/living/carbon/human/understudy_form/scavenger,
		/mob/living/carbon/human/understudy_form/chef,
		/mob/living/carbon/human/understudy_form/carnival,
		/mob/living/carbon/human/understudy_form/captain,
	)
	var/last_form
	var/mob/living/carbon/human/understudy_form/current_form
	var/dying = FALSE
	var/death_fade_time = 1 SECONDS

	var/list/reveal_lines = list(
		"No no no - don't LOOK at me!",
		"Give it back. Give me a face, give me ANYTHING!",
		"Wait - wait, I have another one, watch!",
	)
	var/list/death_lines = list(
		"...I never even... got my own name...",
		"Who... was I supposed to be...?",
		"The understudy... never goes on... after all...",
	)

/mob/living/simple_animal/hostile/understudy/refracted

/mob/living/simple_animal/hostile/understudy/Initialize(mapload)
	. = ..()
	// A short beat as the true form, then it pulls on its first face.
	addtimer(CALLBACK(src, PROC_REF(AssumeForm)), 1 SECONDS)

// Pull on a fresh random skin and hide inside it.
/mob/living/simple_animal/hostile/understudy/proc/AssumeForm()
	if(dying || stat == DEAD || QDELETED(src))
		return
	if(current_form && !QDELETED(current_form))
		return
	var/list/choices = form_pool.Copy()
	if(last_form && length(choices) > 1)
		choices -= last_form
	var/form_type = pick(choices)
	last_form = form_type
	var/turf/T = get_turf(src)
	var/mob/living/carbon/human/understudy_form/skin = new form_type(T)
	skin.master = src
	current_form = skin
	RegisterSignal(skin, COMSIG_LIVING_DEATH, PROC_REF(OnFormDeath))
	// Hide the true form inside the skin: intangible, invulnerable, inert.
	status_flags |= GODMODE
	density = FALSE
	alpha = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	AIStatus = AI_OFF
	forceMove(skin)
	visible_message(span_warning("[skin] steps onto the stage."))

// A skin was broken — drag the true form out for a punish window.
/mob/living/simple_animal/hostile/understudy/proc/OnFormDeath(mob/living/source)
	SIGNAL_HANDLER
	if(source != current_form)
		return
	UnregisterSignal(source, COMSIG_LIVING_DEATH)
	INVOKE_ASYNC(src, PROC_REF(RevealTrueForm), get_turf(source))

/mob/living/simple_animal/hostile/understudy/proc/RevealTrueForm(turf/exit_turf)
	if(dying || QDELETED(src))
		return
	if(!exit_turf)
		exit_turf = get_turf(current_form) || get_turf(src)
	// Burst the broken skin (Envy's revert flourish).
	if(current_form && !QDELETED(current_form))
		playsound(exit_turf, 'sound/effects/splat.ogg', 100, TRUE)
		for(var/turf/TF in orange(1, exit_turf))
			if(TF.density)
				continue
			var/obj/effect/decal/cleanable/blood/B = new(TF)
			B.bloodiness = 100
		new /obj/effect/gibspawner/human/bodypartless(exit_turf)
		qdel(current_form)
	current_form = null
	// Emerge: tangible and vulnerable.
	forceMove(exit_turf)
	status_flags &= ~GODMODE
	density = TRUE
	alpha = 255
	mouse_opacity = initial(mouse_opacity)
	new /obj/effect/temp_visual/dir_setting/wraith(exit_turf)
	say(pick(reveal_lines))
	// More fragile each time it's dragged into the light.
	reveals_done++
	damage_coeff = resist_tiers[clamp(reveals_done, 1, length(resist_tiers))]
	// Chip damage from losing the skin.
	adjustHealth(reveal_damage)
	if(stat == DEAD || health <= 0)
		if(stat != DEAD)
			death()
		return
	// Stunned and exposed; players punish the true form directly.
	AIStatus = AI_OFF
	Stun(reveal_stun_time)
	addtimer(CALLBACK(src, PROC_REF(AssumeForm)), reform_delay)

/mob/living/simple_animal/hostile/understudy/death(gibbed)
	if(dying)
		return ..()
	dying = TRUE
	if(current_form && !QDELETED(current_form))
		UnregisterSignal(current_form, COMSIG_LIVING_DEATH)
		qdel(current_form)
		current_form = null
	// Make sure we're back in the world to play the death out.
	if(!isturf(loc))
		forceMove(get_turf(src))
	status_flags &= ~GODMODE
	density = TRUE
	alpha = 255
	say(pick(death_lines))
	. = ..()
	animate(src, alpha = 0, time = death_fade_time)
	QDEL_IN(src, death_fade_time)

// ---------- Skin base ----------
/mob/living/carbon/human/understudy_form
	/// The true form hiding inside us.
	var/mob/living/simple_animal/hostile/understudy/master
	/// The role's signature melee weapon, placed in-hand for the AI.
	var/weapon_type
	var/weapon_force = 22
	/// Effective max HP, reached by buffing Fortitude.
	var/form_health = 500
	/// Telegraphed signature attack.
	var/special_cooldown = 0
	var/special_cooldown_time = 8 SECONDS
	var/special_range = 7
	var/special_timer
	/// Outfit equipped for the look.
	var/form_outfit

/mob/living/carbon/human/understudy_form/Initialize(mapload)
	. = ..()
	faction = list("serio_zeal")
	// (carbon humans leave a corpse on death; the true form bursts + qdels
	// the skin in OnFormDeath, so no del_on_death needed.)
	if(form_outfit)
		equipOutfit(form_outfit)
	// Sticky, requirement-free gear so the AI can always use it and players
	// can't disarm it.
	for(var/obj/item/I in get_equipped_items(TRUE))
		MakeCostumeItem(I)
	// Signature weapon, in hand for the murder AI to swing.
	if(weapon_type)
		var/obj/item/W = new weapon_type(src)
		W.force = weapon_force
		MakeCostumeItem(W)
		put_in_hands(W)
	// Boss stability + the requested damage-type conversions.
	ADD_TRAIT(src, TRAIT_SANITYIMMUNE, "understudy")
	ADD_TRAIT(src, TRAIT_BRUTEPALE, "understudy")
	ADD_TRAIT(src, TRAIT_BRUTESANITY, "understudy")
	ADD_TRAIT(src, TRAIT_PUSHIMMUNE, "understudy")
	ADD_TRAIT(src, TRAIT_SLEEPIMMUNE, "understudy")
	ADD_TRAIT(src, TRAIT_STUNIMMUNE, "understudy")
	ADD_TRAIT(src, TRAIT_IGNOREDAMAGESLOWDOWN, "understudy")
	add_movespeed_modifier(/datum/movespeed_modifier/understudy_form)
	// ~500 HP via Fortitude (human maxHealth derives from it).
	updatehealth()
	var/datum/attribute/F = attributes?[FORTITUDE_ATTRIBUTE]
	if(F)
		var/needed = form_health - maxHealth
		if(needed != 0)
			F.adjust_buff(src, needed)
	updatehealth()
	health = maxHealth
	// Locked-weapon murderer.
	ai_controller = /datum/ai_controller/insane/murder/understudy
	InitializeAIController()
	special_timer = addtimer(CALLBACK(src, PROC_REF(SpecialTick)), 1 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)

/mob/living/carbon/human/understudy_form/Destroy()
	deltimer(special_timer)
	special_timer = null
	master = null
	return ..()

// Strip EGO attribute requirements (so the AI's stats never matter) and make
// the item un-droppable / un-disarmable.
/mob/living/carbon/human/understudy_form/proc/MakeCostumeItem(obj/item/I)
	if(QDELETED(I))
		return
	if(istype(I, /obj/item/ego_weapon))
		var/obj/item/ego_weapon/E = I
		E.attribute_requirements = list()
	else if(istype(I, /obj/item/clothing/suit/armor/ego_gear))
		var/obj/item/clothing/suit/armor/ego_gear/G = I
		G.attribute_requirements = list()
	ADD_TRAIT(I, TRAIT_NODROP, "understudy")

// Fires the signature special on cooldown when the AI has a live target.
/mob/living/carbon/human/understudy_form/proc/SpecialTick()
	if(QDELETED(src) || stat == DEAD)
		return
	if(world.time < special_cooldown || !ai_controller)
		return
	var/atom/T = ai_controller.blackboard[BB_INSANE_CURRENT_ATTACK_TARGET]
	if(!isliving(T) || QDELETED(T))
		return
	var/mob/living/L = T
	if(L.stat == DEAD || get_dist(src, L) > special_range)
		return
	special_cooldown = world.time + special_cooldown_time
	INVOKE_ASYNC(src, PROC_REF(UseSpecial), L)

/// Per-form telegraphed, dodgeable attack. Overridden by each skin.
/mob/living/carbon/human/understudy_form/proc/UseSpecial(mob/living/target)
	return

// Shared helper: warn a list of turfs, wait, then hit them.
/mob/living/carbon/human/understudy_form/proc/StrikeTurfs(list/turfs, delay, damage, knockdown_time = 0)
	for(var/turf/T in turfs)
		new /obj/effect/temp_visual/understudy_warning(T)
	SLEEP_CHECK_DEATH(delay)
	var/list/been_hit = list()
	for(var/turf/T in turfs)
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		been_hit = HurtInTurf(T, been_hit, damage, RED_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		if(knockdown_time)
			for(var/mob/living/L in T)
				if(L == src || faction_check_mob(L))
					continue
				L.Knockdown(knockdown_time)

// ---------- Skin: Blade Lineage Ronin — Iaido Dash ----------
/mob/living/carbon/human/understudy_form/ronin
	form_outfit = /datum/outfit/job/ronin
	weapon_type = /obj/item/ego_weapon/city/bladelineage
	weapon_force = 24
	special_cooldown_time = 9 SECONDS

/mob/living/carbon/human/understudy_form/ronin/UseSpecial(mob/living/target)
	face_atom(target)
	var/turf/start = get_turf(src)
	var/turf/dest = get_turf(target)
	if(!start || !dest)
		return
	var/list/line = getline(start, dest)
	if(length(line) > 6)
		line.Cut(7)
	playsound(get_turf(src), 'sound/weapons/sear.ogg', 60, TRUE, 4)
	StrikeTurfs(line, 7, 30)
	var/turf/landing = line[length(line)]
	if(landing && !landing.density)
		forceMove(landing)

// ---------- Skin: Backstreets Butcher — Meat Hook ----------
/mob/living/carbon/human/understudy_form/butcher
	form_outfit = /datum/outfit/job/butcher
	weapon_type = /obj/item/kitchen/knife/butcher/deadly
	weapon_force = 20
	special_cooldown_time = 10 SECONDS

/mob/living/carbon/human/understudy_form/butcher/UseSpecial(mob/living/target)
	face_atom(target)
	var/turf/start = get_turf(src)
	var/turf/dest = get_turf(target)
	if(!start || !dest)
		return
	var/list/line = getline(start, dest)
	if(length(line) > 7)
		line.Cut(8)
	for(var/turf/T in line)
		new /obj/effect/temp_visual/understudy_warning(T)
	playsound(get_turf(src), 'sound/weapons/chainhit.ogg', 70, TRUE, 5)
	SLEEP_CHECK_DEATH(7)
	// Pull the first living victim on the line in, then bite it.
	for(var/turf/T in line)
		if(T == start)
			continue
		var/mob/living/victim
		for(var/mob/living/L in T)
			if(L == src || faction_check_mob(L))
				continue
			victim = L
			break
		if(victim)
			victim.throw_at(start, 7, 2, src)
			victim.deal_damage(28, RED_DAMAGE, src,
				attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(victim))
			break

// ---------- Skin: Rat Scavenger — Junk Lob ----------
/mob/living/carbon/human/understudy_form/scavenger
	form_outfit = /datum/outfit/job/scavenger
	weapon_type = /obj/item/ego_weapon/city/rats
	weapon_force = 22
	special_cooldown_time = 7 SECONDS

/mob/living/carbon/human/understudy_form/scavenger/UseSpecial(mob/living/target)
	var/turf/center = get_turf(target)
	if(!center)
		return
	playsound(get_turf(src), 'sound/items/dodgeball.ogg', 60, TRUE, 4)
	StrikeTurfs(range(1, center), 8, 24)

// ---------- Skin: Chef — Hot Plate ----------
/mob/living/carbon/human/understudy_form/chef
	form_outfit = /datum/outfit/job/chef
	weapon_type = /obj/item/melee/baton/loaded
	weapon_force = 20
	special_range = 3
	special_cooldown_time = 8 SECONDS

/mob/living/carbon/human/understudy_form/chef/UseSpecial(mob/living/target)
	face_atom(target)
	var/turf/ahead = get_step(src, dir)
	if(!ahead)
		return
	playsound(get_turf(src), 'sound/weapons/punch3.ogg', 60, TRUE, 4)
	StrikeTurfs(range(1, ahead), 7, 26, knockdown_time = 1.5 SECONDS)

// ---------- Skin: Carnival — Sawblade Spin ----------
/mob/living/carbon/human/understudy_form/carnival
	form_outfit = /datum/outfit/job/carnival
	weapon_type = /obj/item/ego_weapon/city/rats/knife
	weapon_force = 22
	special_range = 4
	special_cooldown_time = 7 SECONDS

/mob/living/carbon/human/understudy_form/carnival/UseSpecial(mob/living/target)
	playsound(get_turf(src), 'sound/weapons/sear.ogg', 60, TRUE, 4)
	StrikeTurfs(range(1, src), 7, 22)

// ---------- Skin: Kurokumo Captain — Cross-Slash ----------
/mob/living/carbon/human/understudy_form/captain
	form_outfit = /datum/outfit/job/kurocaptain
	weapon_type = /obj/item/ego_weapon/city/bladelineage
	weapon_force = 24
	special_cooldown_time = 9 SECONDS

/mob/living/carbon/human/understudy_form/captain/UseSpecial(mob/living/target)
	face_atom(target)
	var/turf/ahead = get_step(src, dir)
	var/turf/far = ahead ? get_step(ahead, dir) : null
	var/list/arc = list()
	if(ahead)
		arc += range(1, ahead)
	if(far)
		arc |= range(1, far)
	playsound(get_turf(src), 'sound/weapons/sear.ogg', 70, TRUE, 5)
	StrikeTurfs(arc, 8, 28)
