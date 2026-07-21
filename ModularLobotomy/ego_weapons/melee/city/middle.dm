// The Middle - Syndicate that uses chains as weapons
// Each rank has their own chain weapon with different stats

//Little Brother Chain
/obj/item/ego_weapon/shield/middle_chain
	name = "little brother's chain"
	desc = "A heavy chain used by The Little Brothers of the Middle. Swung with brutal efficiency."
	special = "Blocking will enter a counter-attacking stance, able to counter-attack against melee attackers and inflicting Vengeance Mark on them. This weapon deals more damage depending on how much Vengeance Mark the target has."
	icon = 'ModularLobotomy/_Lobotomyicons/middle_icons.dmi'
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/middle_worn_l.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/middle_worn_r.dmi'
	icon_state = "lil_chain"
	force = 34
	attack_speed = 1.2
	damtype = BLACK_DAMAGE

	swingcolor = "#8c559c"
	attack_verb_continuous = list("whips", "lashes", "strikes", "batters")
	attack_verb_simple = list("whip", "lash", "strike", "batter")
	hitsound = 'sound/weapons/fixer/generic/middle_attack.ogg'

	reductions = list(0, 0, 0, 0) //Tanking? Na, we eat all of the damage.
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

	// Vengeance Mark system
	var/vengeance_mark_stacks_per_hit = 4
	var/vengeance_damage_bonus = 0.03 // 3% per stack for Little Brother
	var/counter_damage_multiplier = 1.4 // 40% bonus damage on counter-attacks
	// Counterattack system
	/// Incoming attacks must match one of these types to be countered.
	var/attack_types_countered = (ATTACK_TYPE_MELEE)
	/// Attacks of the correct type will be countered, up to [this var] tiles away. Determines how big a view() proc is.
	var/counter_range = 12
	/// Avoids atomizing people who fire a shotgun at you via race condition nonsense (this var must be FALSE to do a counterattack, doing one sets to TRUE)
	var/already_countered = FALSE

/obj/item/ego_weapon/shield/middle_chain/examine(mob/user)
	. = ..()
	if(user.mind)
		if(user.mind.assigned_role in list("Disciplinary Officer", "Combat Research Agent"))
			. += span_notice("Due to your abilities, you get a -20 reduction to stat requirements when equipping this weapon.")

/obj/item/ego_weapon/shield/middle_chain/CanUseEgo(mob/living/user)
	if(user.mind)
		if(user.mind.assigned_role in list("Disciplinary Officer", "Combat Research Agent"))
			equip_bonus = 20
		else
			equip_bonus = 0
	. = ..()

/obj/item/ego_weapon/shield/middle_chain/attack_self(mob/user)//FIXME: Find a better way to use this override!
	if(block == 0) //Extra check because shields returns nothing on 1
		if(..())
			// Add purple color effect when blocking
			if(ishuman(user))
				var/mob/living/carbon/human/H = user
				H.add_atom_colour("#8B008B", TEMPORARY_COLOUR_PRIORITY) // Dark purple/magenta color
				H.Immobilize(block_duration)
			already_countered = FALSE
			return TRUE
		else
			return FALSE

/obj/item/ego_weapon/shield/middle_chain/AnnounceBlock(mob/living/carbon/human/source, damage, damagetype, def_zone, mob/living/source_of_damage, flags, attack_type)
	// Perform counter-attack if we have a valid attacker - but not ourselves
	if(istype(source_of_damage) && !QDELETED(source_of_damage) && source_of_damage != source)

		if(!(attack_type & attack_types_countered))
			return

		// We need this to avoid countering multiple times per block
		if(already_countered)
			return

		if(source.Adjacent(source_of_damage))
			Counterattack(source, damage, damagetype, source_of_damage, flags, attack_type)
		else if(CheckToolReach(source, source_of_damage, counter_range))
			CloseTheGap(source, damage, damagetype, source_of_damage, flags, attack_type)

		. = ..() // Doesn't perform ..() unless a counter is done! This is to avoid confusing people with text saying 'Ricardo counters the attack!' despite nothing happening.

//Override DisableBlock to clean up attacker-tracking signals and remove color
/obj/item/ego_weapon/shield/middle_chain/DisableBlock(mob/living/carbon/human/user)
	// Remove purple color effect
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#8B008B")

	// Call parent DisableBlock
	..()

//Override attack to apply Vengeance Mark bonus damage (but not apply stacks - only counter-attacks apply stacks)
/obj/item/ego_weapon/shield/middle_chain/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return FALSE

	// Check for Vengeance Mark and calculate bonus damage (not against yourself)
	var/datum/status_effect/stacking/vengeance_mark/VM = target.has_status_effect(STATUS_EFFECT_VENGEANCEMARK)
	if(VM && VM.stacks > 0 && target != user)
		var/bonus_multiplier = 1 + (VM.stacks * vengeance_damage_bonus)
		force = round(initial(force) * bonus_multiplier)
		to_chat(user, span_danger("Your chains strike with vengeful fury! ([VM.stacks] marks)"))

	// Perform attack
	. = ..()

	// Safeguard. You were previously able to smuggle 20 vengeance mark's worth of boost into your additional force and end up with biblical damage numbers on a counterattack.
	force = initial(force)

/obj/item/ego_weapon/shield/middle_chain/proc/Counterattack(mob/living/carbon/human/user, damage, damagetype, mob/living/attacker, flags, attack_type)
	if(QDELETED(user) || QDELETED(attacker) || !istype(user) || !istype(attacker))
		return

	already_countered = TRUE

	// Apply counter-attack damage bonus (40% more damage)
	var/original_force = initial(force)
	var/total_multiplier = counter_damage_multiplier

	// Check for Vengeance Mark and add bonus damage
	var/datum/status_effect/stacking/vengeance_mark/VM = attacker.has_status_effect(STATUS_EFFECT_VENGEANCEMARK)
	if(VM && VM.stacks > 0)
		total_multiplier += (VM.stacks * vengeance_damage_bonus)
		to_chat(user, span_danger("Your counter-attack strikes with vengeful fury! ([VM.stacks] marks)"))

	force = round(original_force * total_multiplier)

	// Perform counter-attack
	user.do_attack_animation(attacker)
	attacker.attacked_by(src, user)
	if(!QDELETED(attacker))
		var/atom/throw_target = get_edge_target_turf(attacker, user.dir)
		attacker.throw_at(throw_target, rand(2, 3), 3, user)
	to_chat(user, span_userdanger("Your chains lash out at [attacker]!"))
	log_combat(user, attacker, "counters with", src.name, "(DAMTYPE: [uppertext(damtype)])")
	playsound(get_turf(attacker), hitsound, 50, TRUE)

	// Apply Vengeance Mark stacks after counter-attack, if they still live.
	if(!QDELETED(attacker) && attacker.health > 0)
		attacker.apply_vengeance_mark(vengeance_mark_stacks_per_hit)

	// Reset force
	force = original_force

/obj/item/ego_weapon/shield/middle_chain/proc/CloseTheGap(mob/living/carbon/human/user, damage, damagetype, mob/living/attacker, flags, attack_type)
	var/turf/target_turf = get_step(get_turf(attacker), pick(GLOB.cardinals))
	if(target_turf)
		// Teleport to firer
		user.forceMove(target_turf)
		user.setDir(get_dir(user, attacker))

		// Visual and audio effects
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(user), user.dir)
		playsound(get_turf(user), 'sound/weapons/fwoosh.ogg', 50, TRUE)
		user.visible_message(span_warning("[user]'s chains suddenly lash out, pulling them towards [attacker]!"))
		Counterattack(user, damage, damagetype, attacker, flags, attack_type)

//Younger Brother Chain
/obj/item/ego_weapon/shield/middle_chain/younger
	name = "younger brother's chain"
	desc = "A reinforced chain used by The Younger Brothers of the Middle. Heavier and more lethal than the standard chain."
	icon_state = "mid_chain"
	force = 49
	attack_speed = 1.3
	vengeance_damage_bonus = 0.05 // 5% per stack for Younger Brother
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 80,
	)
	swingcolor = "#654b75"

//Big Brother Chain
/obj/item/ego_weapon/shield/middle_chain/big
	name = "big brother's chain"
	desc = "A masterfully crafted chain used by The Big Brothers of the Middle. Each link is a weapon in itself."
	special = "This weapon can enter a counter-attacking stance by being used in-hand. When hit by a ranged attack, teleports to the assailant and counter-attacks them. Blocking will counter-attack melee or ranged attackers and inflicts Vengeance Mark to them. This weapon deals more damage depending on how much Vengeance Mark the target has."
	icon_state = "big_chain"
	force = 63
	attack_speed = 1.4
	hitsound = 'sound/weapons/fixer/generic/middle_big_attack.ogg'
	vengeance_damage_bonus = 0.08 // 8% per stack for Big Brother
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100,
	)
	attack_types_countered = (ATTACK_TYPE_MELEE | ATTACK_TYPE_RANGED)
	swingcolor = "#462e56"
