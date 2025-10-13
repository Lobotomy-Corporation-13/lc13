// Indigo Dusk - Commanders. They are four powerful sweepers, one of each damage type. RED & PALE are aggresive fighters and WHITE & BLACK are leaders which buff allies.
// Previous iteration of them, they were simply 4 strong sweepers which each patrolled around the facility, leading normal sweepers with them.
// They have been changed to this new version as of a rework made during August of 2025.

/// This is the base template for a dusk. Never spawn these.
/// Base shared type by all Indigo Dusks.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_dead = "sweeper_dead"
	faction = list("indigo_ordeal")
	maxHealth = 1500
	health = 1500
	stat_attack = DEAD
	melee_damage_type = RED_DAMAGE
	rapid_melee = 1
	melee_damage_lower = 13
	melee_damage_upper = 17
	butcher_results = list(/obj/item/food/meat/slab/sweeper = 2)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/sweeper = 1)
	silk_results = list(/obj/item/stack/sheet/silk/indigo_elegant = 1,
						/obj/item/stack/sheet/silk/indigo_advanced = 2,
						/obj/item/stack/sheet/silk/indigo_simple = 4)
	attack_verb_continuous = "stabs"
	attack_verb_simple = "stab"
	attack_sound = 'sound/effects/ordeals/indigo/stab_1.ogg'
	blood_volume = BLOOD_VOLUME_NORMAL
	can_patrol = TRUE

/// This override adds the mobs that will form part of our squad as we patrol around.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/Initialize(mapload)
	. = ..()
	var/units_to_add = list(
		/mob/living/simple_animal/hostile/ordeal/indigo_noon = 1,
		/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky = 1,
		/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky = 1,
		/mob/living/simple_animal/hostile/ordeal/indigo_dawn = 1, // This should be impossible, right? Well, they spawn on CoL at the same time.
		)
	AddComponent(/datum/component/ai_leadership, units_to_add)

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/Aggro()
	. = ..()
	a_intent_change(INTENT_HARM)

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/LoseAggro()
	. = ..()
	a_intent_change(INTENT_HELP) //so that they dont get body blocked by their kin outside of combat

/// This override just handles devouring on hit, if possible.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/AttackingTarget(atom/attacked_target)
	. = ..()
	if(. && isliving(attacked_target))
		var/mob/living/L = attacked_target
		if(L.stat != DEAD)
			if(L.health <= HEALTH_THRESHOLD_DEAD && HAS_TRAIT(L, TRAIT_NODEATH))
				SweeperDevour(L)
		else
			SweeperDevour(L)

/// Prioritizes attacking corpses when injured.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/PickTarget(list/Targets)
	if(health <= maxHealth * 0.7) // If we're damaged enough
		var/list/highest_priority = list()
		for(var/mob/living/L in Targets)
			if(!CanAttack(L))
				continue
			if(L.health < 0 || L.stat == DEAD)
				highest_priority += L
		if(LAZYLEN(highest_priority))
			return pick(highest_priority)
	var/list/lower_priority = list() // We aren't exactly damaged, but it'd be a good idea to finish the wounded first
	for(var/mob/living/L in Targets)
		if(!CanAttack(L))
			continue
		if(L.health < L.maxHealth*0.5 && (L.stat < UNCONSCIOUS))
			lower_priority += L
	if(LAZYLEN(lower_priority))
		return pick(lower_priority)
	return ..()

/// This is a way to make them eat the corpses of friendlies as they move adjacent to them.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/PossibleThreats(max_range, consider_attack_condition)
	. = ..()
	if(health <= maxHealth * 0.8)
		for(var/turf/adjacent_turf in orange(1, src))
			for(var/mob/maybe_sweeper_corpse in adjacent_turf)
				if(faction_check_mob(maybe_sweeper_corpse) && maybe_sweeper_corpse.stat == DEAD)
					. |= maybe_sweeper_corpse

/// Shared base type for the RED and PALE commanders. Don't spawn this in.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter
	health = 1700
	maxHealth = 1700
	rapid_melee = 1.3
	melee_damage_lower = 40
	melee_damage_upper = 45
	var/special_ability_cooldown = 0
	var/special_ability_cooldown_duration = 10 SECONDS
	var/special_ability_damage = 30
	var/special_ability_activated = FALSE

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/proc/UseSpecialAbility(mob/living/target = null, mob/living/user = src)
	if(special_ability_cooldown > world.time)
		return FALSE
	special_ability_cooldown = world.time + special_ability_cooldown_duration
	return TRUE

/// RED Commander. A bruiser that collects nearby blood to enter an empowered state, gaining lifesteal and higher movement speed.
/// Also has access to Trash Disposal: Telegraphed lunge at a target. If it connects, stuns them and beats them up for a while. Can be cancelled by dragging away.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/red
	name = "\proper Commander Jacques"
	desc = "A tall humanoid with red claws. They're dripping with blood."
	// Consider that this guy is gonna end up regenning a decent chunk of health before tweaking these values
	health = 1200
	maxHealth = 1200
	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 0.7)
	icon_state = "jacques"
	icon_living = "jacques"
	rapid_melee = 3
	move_to_delay = 3.5
	melee_damage_type = RED_DAMAGE
	melee_damage_lower = 12
	melee_damage_upper = 16
	special_ability_cooldown_duration = 20 SECONDS
	special_ability_damage = 20
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/sweeper = 1)
	// These following three ranged vars are just because I want them to initiate Trash Disposal from range.
	ranged = TRUE
	projectiletype = null
	simple_mob_flags = SILENCE_RANGED_MESSAGE
	var/can_move = TRUE
	/// How many deciseconds between trash disposal hits? Reduced by 1 decisecond on each hit.
	var/time_between_trash_disposal_hits = 1 SECONDS
	/// How many times should we smack the target in Trash Disposal?
	var/max_trash_disposal_hits = 8
	/// Are we currently performing Trash Disposal? Do not mistake for special_ability_activated: that controls whether we're in the middle of the lunge that starts it.
	var/trash_disposal_active = FALSE
	/// How much damage needs to be taken by the commander to interrupt Trash Disposal? Can be interrupted in other ways, too.
	var/trash_disposal_damagetaken_cap = 300
	/// How much damage have we taken during Trash Disposal?
	var/trash_disposal_damagetaken = 0
	/// Are we in our blood-empowered state?
	var/empowered = FALSE
	/// How many blood units do we lose per life tick? Consider that each blood decal is 50 blood.
	var/empowered_blood_decay = 60
	/// Health regened per life tick while empowered
	var/empowered_periodic_regen = 10
	/// Health regenned per hit while empowered
	var/empowered_hit_regen = 15

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/red/Initialize(mapload)
	. = ..()
	// Go on half-cooldown for Trash Disposal as soon as we spawn.
	special_ability_cooldown += special_ability_cooldown_duration * 0.5
	// Add our Bloodfeast component that lets us siphon blood.
	AddComponent(/datum/component/bloodfeast, siphon = TRUE, range = 2, starting = 0, threshold = 1500, max_amount = 1500)

	if(SSmaptype.maptype in SSmaptype.citymaps)
		guaranteed_butcher_results += list(/obj/item/head_trophy/indigo_head = 1)
		empowered_hit_regen -= 10

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/red/apply_damage(damage, damagetype, def_zone, blocked, forced, spread_damage, wound_bonus, bare_wound_bonus, sharpness, white_healable)
	. = ..()
	// Add damage taken during trash disposal to the right var so we know when to interrupt it.
	if(trash_disposal_active)
		var/damage_coefficient = src.damage_coeff.getCoeff(damagetype)
		var/damage_taken = damage * damage_coefficient
		trash_disposal_damagetaken += damage_taken

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/red/Move(atom/newloc, dir, step_x, step_y)
	if(!can_move)
		return FALSE
	. = ..()

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/red/UseSpecialAbility(mob/living/victim, mob/living/user)
	if(victim.stat >= DEAD)
		return FALSE
	. = ..()

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/red/AttackingTarget(atom/attacked_target)
	if(trash_disposal_active)
		return FALSE
	// Use Trash Disposal when available on melee targets.
	if(isliving(attacked_target) && UseSpecialAbility(attacked_target))
		return FALSE
	. = ..()
	// Some life regen on hit, if we're empowered.
	if(empowered)
		SweeperHealing(empowered_hit_regen)

/// Override to use Trash Disposal at range.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/red/OpenFire(atom/A)
	if(client && isliving(A))
		UseSpecialAbility(A)
		return
	else if(!client && prob(35) && get_dist(src, A) < 7)
		UseSpecialAbility(A)
		return

/// In our Life tick, we Empower above a certain amount of gathered blood. If we're already empowered, we decay our amount of blood (which also regens us a bit).
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/red/Life()
	. = ..()
	var/datum/component/bloodfeast/gathered_blood = GetComponent(/datum/component/bloodfeast)
	if(!empowered && gathered_blood)
		if(gathered_blood.blood_amount > 200)
			Empower(gathered_blood)
	else
		EmpowerDecay(gathered_blood)

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/red/UseSpecialAbility(mob/living/victim = target, mob/living/user = src)
	if(..() && victim && !trash_disposal_active)
		INVOKE_ASYNC(src, PROC_REF(TrashDisposalTelegraph), victim, user)
		return TRUE
	return FALSE

/// Enters an empowered state when we have enough blood. Attack and move faster, and regen HP on hit and life tick.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/red/proc/Empower(datum/component/bloodfeast/bloodfeast_component)
	empowered = TRUE
	animate(src, 1 SECONDS, color = "#882020", transform = matrix()*1.10)
	move_to_delay -= 1
	rapid_melee += 1

/// Reverts the effects of Empower.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/red/proc/EmpowerRevert()
	empowered = FALSE
	animate(src, 0.6 SECONDS, color = initial(color), transform = initial(transform))
	move_to_delay = initial(move_to_delay)
	rapid_melee = initial(rapid_melee)

/// Called on every life tick while empowered. Regen some health, lose some blood and revert empower if we ran out.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/red/proc/EmpowerDecay(datum/component/bloodfeast/bloodfeast_component)
	if(bloodfeast_component)
		bloodfeast_component.blood_amount = max(bloodfeast_component.blood_amount - empowered_blood_decay, 0)
		SweeperHealing(empowered_periodic_regen)
		if(bloodfeast_component.blood_amount <= 0)
			EmpowerRevert()

/// First part of Trash Disposal. It CAN fail. Warns players they're about to get lunged at, then throws the commander at them.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/red/proc/TrashDisposalTelegraph(mob/living/victim, mob/living/user = src)
	can_move = FALSE
	AIStatus = AI_OFF
	LoseTarget()
	walk_to(src, 0) // Resets any ongoing movement

	// Telegraph the attack to players.
	var/obj/effect/temp_visual/trash_disposal_telegraph/warning = new /obj/effect/temp_visual/trash_disposal_telegraph(get_turf(user))
	say("+5363 23 625 513 93477 2576!+")
	user.visible_message(span_userdanger("[user] prepares to leap at [victim]!"))
	playsound(src, 'sound/abnormalities/crumbling/warning.ogg', 50, FALSE, 5)
	walk_towards(warning, victim, 0.1 SECONDS) // This makes our warning move from the commander to the target.
	SLEEP_CHECK_DEATH(2.3 SECONDS)

	can_move = TRUE
	special_ability_activated = TRUE // While this is active, anyone we get thrown into is fair game for Trash Disposal.
	user.throw_at(victim, 7, 5, src, FALSE)
	user.visible_message(span_danger("[user] leaps at [victim]!"))
	addtimer(CALLBACK(src, PROC_REF(StopLunging)), 2 SECONDS) // Failsafe - resets our state if we miss.

/// This proc is called once we successfully impact someone from our lunge. We pin them and begin the sequence of hits.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/red/proc/TrashDisposalInitiate(mob/living/victim, mob/living/user = src)
	trash_disposal_damagetaken = 0
	trash_disposal_active = TRUE

	// Need to disable passive siphoning on our bloodfeast component briefly, so that blood we generate from the Trash Disposal isn't eaten immediately (looks weird)
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	if(bloodfeast)
		bloodfeast.passive_siphon = FALSE

	var/mob/living/carbon/human/human_trash
	var/mob/living/simple_animal/hostile/animal_trash
	if(ishuman(victim))
		human_trash = victim
		human_trash.Paralyze(8 SECONDS) // Human targets are completely incapacitated for the duration of Trash Disposal. This paralyze gets removed on cleanup.
	else if(istype(victim, /mob/living/simple_animal/hostile))
		// I have to do this jank until we get can_act and can_move merged
		animal_trash = victim
		animal_trash.AIStatus = AI_OFF
		walk_to(animal_trash, 0)
		animal_trash.LoseTarget()

	victim.visible_message(span_danger("[victim] is pinned down by [src]!"), span_userdanger("You're pinned down by [src]!"))
	var/turf/target_deathbed = get_turf(victim)
	new /obj/effect/temp_visual/weapon_stun(target_deathbed)
	user.forceMove(target_deathbed)
	say("3462 7239...")
	INVOKE_ASYNC(src, PROC_REF(TrashDisposalHit), victim, user, 1)

/// This proc calls itself over and over until either: 1. Target dies, 2. Reached max amount of hits, 3. Interrupted by damage taken, 4. do_after fails (position change)
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/red/proc/TrashDisposalHit(mob/living/victim, mob/living/user = src, hit_count)
	// Only perform the hit if we haven't taken enough damage to interrupt the sequence
	if(trash_disposal_damagetaken < trash_disposal_damagetaken_cap)
		// This do_after controls how fast the hits happen. It can fail if our position changes, or the victim's does.
		if(do_after(user, time_between_trash_disposal_hits, target = victim))
			user.do_attack_animation(victim)
			playsound(user, attack_sound, 100, TRUE)
			new /obj/effect/gibspawner/generic/trash_disposal(get_turf(victim))
			victim.deal_damage(special_ability_damage, melee_damage_type)
			SweeperHealing(special_ability_damage)
			user.visible_message(span_danger("[user] rips into [victim] and refuels themselves with their blood!"))
			// Ramp up the speed and damage on each hit.
			time_between_trash_disposal_hits -= 1
			special_ability_damage += 3
			// Devour the victim if we killed them, and end the sequence.
			if(victim.health <= 0)
				if(victim.stat != DEAD)
					if(victim.health <= HEALTH_THRESHOLD_DEAD && HAS_TRAIT(victim, TRAIT_NODEATH))
						SweeperDevour(victim)
				else
					SweeperDevour(victim)
				TrashDisposalCleanup(null, user)
				return TRUE
			// If we reached our maximum hitcount with this hit, we're done.
			if(hit_count >= max_trash_disposal_hits)
				TrashDisposalCleanup(victim, user)
				return TRUE

			// If we reached here, then we weren't interrupted and we can keep hitting our target. Go again.
			INVOKE_ASYNC(src, PROC_REF(TrashDisposalHit), victim, user, hit_count + 1)
			return TRUE
	// We cancel if we didn't reach the early returns that were provided within the do_after.
	TrashDisposalCleanup(victim, user)
	return FALSE

/// This proc reverts the effects that Trash Disposal applied on us and our victim.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/red/proc/TrashDisposalCleanup(mob/living/victim, mob/living/user = src)
	AIStatus = AI_ON
	can_move = TRUE
	special_ability_activated = FALSE
	trash_disposal_active = FALSE
	time_between_trash_disposal_hits = initial(time_between_trash_disposal_hits)
	special_ability_damage = initial(special_ability_damage)

	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	if(bloodfeast)
		bloodfeast.passive_siphon = TRUE

	if(victim && isliving(victim))
		GiveTarget(victim)
		if(ishuman(victim))
			var/mob/living/carbon/human/freed_human = victim
			freed_human.remove_status_effect(STATUS_EFFECT_PARALYZED)
			freed_human.visible_message(span_danger("[freed_human] escapes [src]'s pin!"))
			return
		if(istype(victim, /mob/living/simple_animal))
			var/mob/living/simple_animal/freed_animal = victim
			freed_animal.AIStatus = AI_ON
			return

/// Handles initiating a Trash Disposal if TrashDisposalTelegraph()'s throw managed to hit something.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/red/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/mob/living/what_did_we_just_hit = hit_atom
	// If we directly impacted a living mob that's not in our exact factions, start Trash Disposal on them.
	if(special_ability_activated && istype(what_did_we_just_hit) && !faction_check_mob(what_did_we_just_hit, TRUE))
		INVOKE_ASYNC(src, PROC_REF(TrashDisposalInitiate), what_did_we_just_hit, src)
		special_ability_activated = FALSE
		return
	// If we didn't directly impact a living mob, check the turf we landed on and look for them there. (People could otherwise dodge by going prone if we don't do this.)
	else if(special_ability_activated)
		var/turf/landing_zone = get_turf(src)
		for(var/mob/living/L in landing_zone)
			if(L == throwingdatum.target && !faction_check_mob(L, TRUE))
				INVOKE_ASYNC(src, PROC_REF(TrashDisposalInitiate), L, src)
				special_ability_activated = FALSE
				return

	// Failsafe in case we couldn't start our trash disposal.
	special_ability_activated = FALSE
	AIStatus = AI_ON
	can_move = TRUE
	. = ..()

/// Failsafe proc in case we miss our throw entirely.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/red/proc/StopLunging()
	special_ability_activated = FALSE
	can_move = TRUE
	if(!trash_disposal_active)
		AIStatus = AI_ON

/obj/effect/temp_visual/trash_disposal_telegraph
	name = "Trash Designator Circle"
	icon = 'icons/mob/telegraphing/telegraph_holographic.dmi'
	icon_state = "target_circle"
	desc = "Uh oh."
	duration = 2.2 SECONDS
	randomdir = FALSE

/obj/effect/gibspawner/generic/trash_disposal
	gibamounts = list(1, 1, 1)
	sound_vol = 30

/// PALE Commander. A frontliner that... deals PALE damage. That's quite enough as it is, but on top of that, they have access to a parry and counter followup.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/pale
	name = "\proper Commander Silvina"
	desc = "A tall humanoid with glowing pale fists."
	icon_state = "silvina"
	icon_living = "silvina"
	health = 1400
	maxHealth = 1400
	rapid_melee = 1.5
	move_to_delay = 3.5
	melee_damage_type = PALE_DAMAGE
	melee_damage_lower = 13
	melee_damage_upper = 17
	damage_coeff = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 0.7, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 0.5)
	special_ability_cooldown_duration = 12 SECONDS
	special_ability_damage = 40
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/sweeper = 1)
	var/parrying = FALSE
	var/parry_stop_timer = null

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/pale/Initialize(mapload)
	. = ..()
	if(SSmaptype.maptype in SSmaptype.citymaps)
		guaranteed_butcher_results += list(/obj/item/head_trophy/indigo_head/pale = 1)

/// Activates parrying behaviour when hit by a simple_animal.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/pale/attack_animal(mob/living/simple_animal/M, damage)
	// If we're hit in melee by a living mob, while parrying, and are still alive, we retaliate. The attack on us gets cancelled.
	if(parrying && health > 0 && istype(M))
		ParryCounter(M)
		return FALSE
	. = ..()
	// If we're hit by a sufficiently strong melee attack, 75% of the time we will go into our parrying stance.
	if(health > 0 && prob(75))
		INVOKE_ASYNC(src, PROC_REF(UseSpecialAbility), M, src) // It's ASYNC because there's a sleep in it

/// Activates parrying behaviour when hit by a human with an object.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/pale/attacked_by(obj/item/I, mob/living/user)
	// If we're hit in melee by a living mob, while parrying, and are still alive, we retaliate. The attack on us gets cancelled.
	if(parrying && health > 0 && istype(user))
		ParryCounter(user)
		return FALSE
	. = ..()
	// If we're hit by a sufficiently strong melee attack, 75% of the time we will go into our parrying stance.
	if(health > 0 && I.force >= 10 && prob(75))
		INVOKE_ASYNC(src, PROC_REF(UseSpecialAbility), user, src) // It's ASYNC because there's a sleep in it

/// This override has the exact same purpose as the above one, it's just for ranged attacks instead of melee.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/pale/bullet_act(obj/projectile/P)
	if(parrying && health > 0 && isliving(P.firer))
		ParryCounter(P.firer)
		return FALSE
	. = ..()
	// This won't activate on low caliber projectiles like Havana.
	if(P.damage >= 20 && health > 0 && prob(75))
		INVOKE_ASYNC(src, PROC_REF(UseSpecialAbility)) // It's ASYNC because there's a sleep in it

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/pale/Move(atom/newloc, dir, step_x, step_y)
	if(special_ability_activated)
		return FALSE
	. = ..()

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/pale/AttackingTarget(atom/attacked_target)
	if(special_ability_activated)
		return FALSE
	. = ..()

/// Enter our parrying stance.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/pale/UseSpecialAbility(mob/living/target, mob/living/user)
	if(..())
		special_ability_activated = TRUE // This doesn't mean we're parrying just yet.
		// Telegraph that we're beginning a parry to give players time to stop attacking. We're not actively parrying at this point.
		say("676 3246!!")
		visible_message(span_userdanger("[src] enters a parrying stance!"))
		var/atom/temp = new /obj/effect/temp_visual/markedfordeath(get_turf(src))
		temp.pixel_y += 16
		playsound(src, 'sound/abnormalities/crumbling/warning.ogg', 50, FALSE, 3)
		animate(src, 0.4 SECONDS, color = COLOR_BLUE_LIGHT)
		SLEEP_CHECK_DEATH(0.7 SECONDS)
		// Now we actually enter our parry stance.
		parrying = TRUE
		parry_stop_timer = addtimer(CALLBACK(src, PROC_REF(StopParrying)), 1.3 SECONDS, TIMER_STOPPABLE)

/// This proc is called after successfully parrying, or after the timer runs out on our parry stance. It undoes all our changes from going into parry.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/pale/proc/StopParrying(success = FALSE)
	parrying = FALSE
	special_ability_activated = FALSE
	if(!success)
		visible_message(span_danger("[src] lowers their defensive stance."))
	animate(src, 0.5 SECONDS, color = initial(color))

/// This gets called if someone hits us in our parrying stance. Retaliate by teleporting through them and attacking. We'll heal a bit too.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fighter/pale/proc/ParryCounter(mob/living/victim)
	// Clean up our parrying stuff...
	StopParrying(TRUE)
	deltimer(parry_stop_timer)
	parry_stop_timer = null

	// Indicate that we landed a parry.
	var/datum/effect_system/spark_spread/parry_sparks = new /datum/effect_system/spark_spread
	parry_sparks.set_up(4, 0, loc)
	parry_sparks.start()
	playsound(src, 'sound/weapons/parry.ogg', 100, FALSE, 5)
	SLEEP_CHECK_DEATH(0.2 SECONDS)

	// Teleport to the target and add a visual demonstrating it.
	var/turf/destination_turf = get_ranged_target_turf_direct(src, victim, get_dist(src, victim) + 1)
	var/turf/origin = get_turf(src)
	src.forceMove(destination_turf)
	var/datum/beam/really_temporary_beam = origin.Beam(src, icon_state = "1-full", time = 3)
	really_temporary_beam.visuals.color = COLOR_BLUE_LIGHT

	// Hit the target.
	src.do_attack_animation(victim)
	playsound(src, 'sound/abnormalities/crumbling/attack.ogg', 75, FALSE)
	new /obj/effect/gibspawner/generic/trash_disposal(get_turf(victim))
	victim.deal_damage(special_ability_damage, melee_damage_type)
	visible_message(span_userdanger("[src] deflects [victim]'s attack and performs a counter!"))
	SweeperHealing(100)

/// This base type is for officer-type commanders. They buff their allies periodically, but are statsticks in combat otherwise.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/officer
	health = 1200
	maxHealth = 1200
	// Going to give this base type some changed vars to differentiate it from the fighter type, it shouldn't ever spawn anyway but JUST IN CASE.
	icon_state = "adelheide"
	icon_living = "adelheide"
	melee_damage_type = WHITE_DAMAGE
	melee_damage_lower = 30
	melee_damage_upper = 35
	rapid_melee = 1
	move_to_delay = 4
	var/buff_ability_cooldown = 0
	var/buff_ability_cooldown_duration = 40 SECONDS
	var/buff_ability_range = 8

/// This override is what makes officers use their buff. Code taken from Steel Dusk.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/officer/handle_automated_action()
	. = ..()
	if(target && buff_ability_cooldown < world.time && stat != DEAD)
		ActivateBuff()

/// This proc will apply our buff effect to allies in range.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/officer/proc/ActivateBuff()
	buff_ability_cooldown = world.time + buff_ability_cooldown_duration
	say("296 9246 8572!!")
	audible_message(span_danger("[src] issues a command to their allies!"))
	new /obj/effect/temp_visual/screech(get_turf(src))

	for(var/turf/T in range(buff_ability_range, src))
		for(var/mob/living/simple_animal/hostile/ordeal/goon in T)
			// Apply the buff only to people who are: 1. Not us | 2. Indigo Noons, so not Matriarch or other Dusks | 3. In our faction
			if(src != goon && istype(goon, /mob/living/simple_animal/hostile/ordeal/indigo_noon) && faction_check_mob(goon, TRUE))
				ApplyBuffEffect(goon)

/// Empty proc. Override this with the actual buff effect for the officer type.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/officer/proc/ApplyBuffEffect(mob/living/simple_animal/hostile/ordeal/goon)

/// The WHITE Commander. This one is able to give Persistence to its underlings periodically.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/officer/white
	name = "\proper Commander Adelheide"
	maxHealth = 1500
	health = 1500
	desc = "A tall humanoid with a white greatsword."
	icon_state = "adelheide"
	icon_living = "adelheide"
	melee_damage_type = WHITE_DAMAGE
	melee_damage_lower = 38
	melee_damage_upper = 43
	rapid_melee = 1
	move_to_delay = 4
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 1.5, PALE_DAMAGE = 0.7)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/sweeper = 1)

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/officer/white/Initialize(mapload)
	. = ..()
	if(SSmaptype.maptype in SSmaptype.citymaps)
		guaranteed_butcher_results += list(/obj/item/head_trophy/indigo_head/white = 1)

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/officer/white/CanAttack(atom/the_target)
	if(ishuman(the_target))
		var/mob/living/carbon/human/L = the_target
		if(L.sanity_lost && L.stat != DEAD)
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/officer/white/ApplyBuffEffect(mob/living/simple_animal/hostile/ordeal/goon)
	goon.GainPersistence(2)


/// The BLACK commander. A bit more threatening in melee (since you're likelier to have good BLACK armour against this ordeal).
/// Can periodically give its underlings a powerful buff, increasing their attack and movement speed, as well as their melee damage.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/officer/black
	name = "\proper Commander Maria"
	desc = "A tall humanoid with a large black hammer."
	health = 1400
	maxHealth = 1400
	icon_state = "maria"
	icon_living = "maria"
	melee_damage_type = BLACK_DAMAGE
	melee_damage_lower = 43
	melee_damage_upper = 48
	rapid_melee = 1
	move_to_delay = 4
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 0.7, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 1.5)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/sweeper = 1)
	var/buff_melee_bonus = 3
	var/buff_movespeed_bonus = 1
	var/buff_attackspeed_bonus = 1
	var/buff_duration = 7.5 SECONDS

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/officer/black/Initialize(mapload)
	. = ..()
	if(SSmaptype.maptype in SSmaptype.citymaps)
		guaranteed_butcher_results += list(/obj/item/head_trophy/indigo_head/black = 1)

/// Maria's buff is handled purely with timers, no status effect datum is involved.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/officer/black/ApplyBuffEffect(mob/living/simple_animal/hostile/ordeal/goon)
	BlackCommanderBuff(goon)
	addtimer(CALLBACK(src, PROC_REF(BlackCommanderBuffRevert), goon), buff_duration)

/// The buff briefly colours the sweepers black to indicate they were hit by it.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/officer/black/proc/BlackCommanderBuff(mob/living/simple_animal/hostile/ordeal/goon)
	var/prev_color = goon.color
	animate(goon, 0.7 SECONDS, color = "#1a1717")
	goon.rapid_melee += buff_attackspeed_bonus
	goon.move_to_delay -= buff_movespeed_bonus
	goon.melee_damage_lower += buff_melee_bonus
	goon.melee_damage_upper += buff_melee_bonus
	INVOKE_ASYNC(src, PROC_REF(BlackCommanderVisualUndo), goon, prev_color)


/mob/living/simple_animal/hostile/ordeal/indigo_dusk/officer/black/proc/BlackCommanderVisualUndo(mob/living/simple_animal/hostile/ordeal/goon, prev_color)
	sleep(0.7 SECONDS)
	animate(goon, 0.7 SECONDS, color = prev_color)

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/officer/black/proc/BlackCommanderBuffRevert(mob/living/simple_animal/hostile/ordeal/goon)
	// I'm reverting the buff like this instead of using initial() in case those values change during the buff for whatever reason, such as lanky noon Evasive Mode.
	goon.rapid_melee -= buff_attackspeed_bonus
	goon.move_to_delay += buff_movespeed_bonus
	goon.melee_damage_lower -= buff_melee_bonus
	goon.melee_damage_upper -= buff_melee_bonus
