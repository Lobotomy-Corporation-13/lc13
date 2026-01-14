// Indigo Dusk - Commanders. They are four powerful sweepers, one of each damage type. RED & PALE are aggresive fighters and WHITE & BLACK are leaders which buff allies.
// Previous iteration of them, they were simply 4 strong sweepers which each patrolled around the facility, leading normal sweepers with them.
// They have been changed to this new version as of a rework made during August of 2025.

/// This is the base template for a dusk. Never spawn these.
/// Base shared type by all Indigo Dusks.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk
	name = "\proper Commander Templatus"
	desc = "You stare into its eyes, and realize it is not meant to be here. It really shouldn't be here - it's an error. Then again, are any of us meant to be here? Anyhow, it shouldn't be a tough fight."
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
	/// If this is TRUE, creates a leadership component on Initialize.
	var/commanding_officer = TRUE
	/// If this is FALSE, we don't get to eat human corpses, they should be saved for the Matriarch.
	var/permitted_to_feast = TRUE
	// Combat ability vars. Not implemented for base type.
	var/special_ability_cooldown = 0
	var/special_ability_cooldown_duration = 10 SECONDS
	var/special_ability_damage = 30
	var/special_ability_activated = FALSE
	// Buff ability vars. Not implemented for base type.
	var/buff_ability_capable = FALSE
	var/buff_ability_cooldown = 0
	var/buff_ability_cooldown_duration = 25 SECONDS
	var/buff_ability_range = 11

/// This override adds the mobs that will form part of our squad as we patrol around.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/Initialize(mapload)
	. = ..()
	if(commanding_officer)
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
		if(!permitted_to_feast && ishuman(L)) // We do not get to activate Devour on human corpses if the Matriarch wants the corpse for herself.
			return

		if(L.stat != DEAD)
			if(L.health <= HEALTH_THRESHOLD_DEAD && HAS_TRAIT(L, TRAIT_NODEATH))
				SweeperDevour(L)
		else
			SweeperDevour(L)

/// Prioritizes attacking corpses when injured.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/PickTarget(list/Targets)
	if(permitted_to_feast && health <= maxHealth * 0.7) // If we're damaged enough
		var/list/highest_priority = list()
		for(var/mob/living/L in Targets)
			if(!CanAttack(L))
				continue
			if(ishuman(L))
				continue
			if(L.health < 0 || L.stat == DEAD)
				highest_priority += L
		if(LAZYLEN(highest_priority))
			return pick(highest_priority)
	var/list/lower_priority = list() // We aren't exactly damaged, but it'd be a good idea to finish the wounded first
	for(var/mob/living/L in Targets)
		if(!CanAttack(L))
			continue
		if(ishuman(L))
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

/// This proc uses the special combat ability for this type. On this base type, it is unimplemented. Implement in subtypes.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/proc/UseSpecialAbility(mob/living/target = null, mob/living/user = src)
	if(special_ability_cooldown > world.time)
		return FALSE
	special_ability_cooldown = world.time + special_ability_cooldown_duration
	return TRUE

/// This override is what makes officer-types use their buff. Code taken from Steel Dusk.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/handle_automated_action()
	. = ..()
	if(buff_ability_capable && target && buff_ability_cooldown < world.time && stat != DEAD)
		ActivateBuff()

/// This proc will apply our buff effect to allies in range.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/proc/ActivateBuff()
	buff_ability_cooldown = world.time + buff_ability_cooldown_duration
	say("296 9246 8572!!")
	audible_message(span_danger("[src] issues a command to \his allies!"))
	new /obj/effect/temp_visual/screech(get_turf(src))

	for(var/turf/T in range(buff_ability_range, src))
		for(var/mob/living/simple_animal/hostile/ordeal/goon in T)
			// Apply the buff only to people who are: 1. Not us, 2. In our faction, 3. Not the Matriarch because holy shit
			if(src != goon && faction_check_mob(goon, TRUE) && !istype(goon, /mob/living/simple_animal/hostile/ordeal/indigo_midnight))
				ApplyBuffEffect(goon)

/// Empty proc. Override this with the actual buff effect for the officer type.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/proc/ApplyBuffEffect(mob/living/simple_animal/hostile/ordeal/goon)

/// RED Commander. A bruiser that collects nearby blood to enter an empowered state, gaining lifesteal and higher movement speed.
/// Also has access to Trash Disposal: Telegraphed lunge at a target. If it connects, stuns them and beats them up for a while. Can be cancelled by dragging away.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red
	name = "\proper Commander Jacques"
	desc = "A tall humanoid with red claws. They're dripping with blood."
	gender = MALE
	// Consider that this guy is gonna end up regenning a decent chunk of health before tweaking these values
	health = 1650
	maxHealth = 1650
	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 0.7)
	icon_state = "jacques"
	icon_living = "jacques"
	rapid_melee = 3
	move_to_delay = 3.5
	melee_damage_type = RED_DAMAGE
	melee_damage_lower = 12
	melee_damage_upper = 16
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	special_ability_cooldown_duration = 15 SECONDS
	special_ability_damage = 20
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/sweeper = 1)
	// These following three ranged vars are just because I want them to initiate Trash Disposal from range.
	ranged = TRUE
	projectiletype = null
	simple_mob_flags = SILENCE_RANGED_MESSAGE
	var/can_move = TRUE
	var/can_act = TRUE
	/// A failsafe timer in case we miss our lunge, resets it.
	var/lunge_reset_timer
	/// How many deciseconds between trash disposal hits? Reduced by 1 decisecond on each hit.
	var/time_between_trash_disposal_hits = 1 SECONDS
	/// How many times should we smack the target in Trash Disposal?
	var/max_trash_disposal_hits = 8
	/// Are we currently performing Trash Disposal? Do not mistake for special_ability_activated: that controls whether we're in the middle of the lunge that starts it.
	var/trash_disposal_active = FALSE
	/// This is the amount of time the telegraph for Trash Disposal lasts, that is to say, how long a player has to dodge it.
	var/trash_disposal_windup_duration = 2.1 SECONDS
	/// How much damage needs to be taken by the commander to interrupt Trash Disposal? Can be interrupted in other ways, too.
	var/trash_disposal_damagetaken_cap = 300
	/// How much damage have we taken during Trash Disposal?
	var/trash_disposal_damagetaken = 0
	/// Are we in our blood-empowered state?
	var/empowered = FALSE
	/// How many blood units do we lose per life tick? Consider that each blood decal is 50 blood.
	var/empowered_blood_decay = 60
	/// Health regenned per life tick while empowered
	var/empowered_periodic_regen = 10
	/// Health regenned per hit while empowered
	var/empowered_hit_regen = 15

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/Initialize(mapload)
	. = ..()
	// Go on half-cooldown for Trash Disposal as soon as we spawn.
	special_ability_cooldown += special_ability_cooldown_duration * 0.5
	// Add our Bloodfeast component that lets us siphon blood.
	AddComponent(/datum/component/bloodfeast, siphon = TRUE, range = 2, starting = 300, threshold = 2000, max_amount = 2000)

	if(SSmaptype.maptype in SSmaptype.citymaps)
		guaranteed_butcher_results += list(/obj/item/head_trophy/indigo_head = 1)
		// Becomes more powerful in City maps. This mob is meant to have a ton of backup, but it won't in the City. At most it'll have some basic goons in the Sweeper Church tile, but it won't have its fellow commanders.
		// Consider that the City Boss Event can spawn Tomerry, this is pretty tame compared to that.
		maxHealth += 600
		health += 600
		melee_damage_lower += 3
		melee_damage_upper += 3
		empowered_hit_regen += 5
		empowered_blood_decay -= 10
		empowered_periodic_regen += 5

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	// Add damage taken during trash disposal to the right var so we know when to interrupt it.
	if(trash_disposal_active)
		trash_disposal_damagetaken += damage_amount

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/Move(atom/newloc, dir, step_x, step_y)
	if(!can_move)
		return FALSE
	. = ..()

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/UseSpecialAbility(mob/living/victim, mob/living/user)
	if(victim.stat >= DEAD)
		return FALSE
	. = ..()

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return FALSE
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
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/OpenFire(atom/A)
	if(client && isliving(A))
		UseSpecialAbility(A)
		return
	else if(!client && prob(35) && get_dist(src, A) < 7)
		UseSpecialAbility(A)
		return

/// In our Life tick, we Empower above a certain amount of gathered blood. If we're already empowered, we decay our amount of blood (which also regens us a bit).
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/Life()
	. = ..()
	var/datum/component/bloodfeast/gathered_blood = GetComponent(/datum/component/bloodfeast)
	if(!empowered && gathered_blood)
		if(gathered_blood.blood_amount > 200)
			Empower(gathered_blood)
	else
		EmpowerDecay(gathered_blood)

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/UseSpecialAbility(mob/living/victim = target, mob/living/user = src)
	if(..() && victim && !trash_disposal_active)
		INVOKE_ASYNC(src, PROC_REF(TrashDisposalTelegraph), victim, user)
		return TRUE
	return FALSE

/// Enters an empowered state when we have enough blood. Attack and move faster, and regen HP on hit and life tick.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/proc/Empower(datum/component/bloodfeast/bloodfeast_component)
	empowered = TRUE
	animate(src, 1 SECONDS, color = "#882020", transform = matrix()*1.10)
	ChangeMoveToDelay(move_to_delay - 0.5)
	rapid_melee += 1

/// Reverts the effects of Empower.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/proc/EmpowerRevert()
	empowered = FALSE
	animate(src, 0.6 SECONDS, color = initial(color), transform = initial(transform))
	ChangeMoveToDelay(initial(move_to_delay))
	rapid_melee = initial(rapid_melee)

/// Called on every life tick while empowered. Regen some health, lose some blood and revert empower if we ran out.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/proc/EmpowerDecay(datum/component/bloodfeast/bloodfeast_component)
	if(bloodfeast_component)
		bloodfeast_component.blood_amount = max(bloodfeast_component.blood_amount - empowered_blood_decay, 0)
		SweeperHealing(empowered_periodic_regen)
		if(bloodfeast_component.blood_amount <= 0)
			EmpowerRevert()

/// First part of Trash Disposal. It CAN fail. Warns players they're about to get lunged at, then throws the commander at them.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/proc/TrashDisposalTelegraph(mob/living/victim, mob/living/user = src)
	can_move = FALSE
	can_act = FALSE
	move_resist = INFINITY
	toggle_ai(AI_OFF)
	LoseTarget()
	walk_to(src, 0) // Resets any ongoing movement

	// Telegraph the attack to players.
	var/obj/effect/temp_visual/trash_disposal_telegraph/warning = new /obj/effect/temp_visual/trash_disposal_telegraph(get_turf(user))
	say("+5363 23 625 513 93477 2576!+")
	user.visible_message(span_userdanger("[user] prepares to leap at [victim]!"))
	playsound(src, 'sound/abnormalities/crumbling/warning.ogg', 50, FALSE, 5)
	walk_towards(warning, victim, 0.1 SECONDS) // This makes our warning move from the commander to the target.
	SLEEP_CHECK_DEATH(trash_disposal_windup_duration)

	can_move = TRUE
	can_act = TRUE
	move_resist = initial(move_resist)

	special_ability_activated = TRUE // While this is active, anyone we get thrown into is fair game for Trash Disposal.
	user.throw_at(victim, 7, 5, src, FALSE)
	user.visible_message(span_danger("[user] leaps at [victim]!"))
	lunge_reset_timer = addtimer(CALLBACK(src, PROC_REF(StopLunging)), 2 SECONDS, TIMER_STOPPABLE) // Failsafe - resets our state if we miss.

/// This proc is called once we successfully impact someone from our lunge. We pin them and begin the sequence of hits.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/proc/TrashDisposalInitiate(mob/living/victim, mob/living/user = src)
	trash_disposal_damagetaken = 0
	trash_disposal_active = TRUE
	deltimer(lunge_reset_timer)

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
		animal_trash.toggle_ai(AI_OFF)
		walk_to(animal_trash, 0)
		animal_trash.LoseTarget()

	victim.visible_message(span_danger("[victim] is pinned down by [src]!"), span_userdanger("You're pinned down by [src]!"))
	var/turf/target_deathbed = get_turf(victim)
	new /obj/effect/temp_visual/weapon_stun(target_deathbed)
	user.forceMove(target_deathbed)
	say("3462 7239...")
	INVOKE_ASYNC(src, PROC_REF(TrashDisposalHit), victim, user, 1)

/// This proc calls itself over and over until either: 1. Target dies, 2. Reached max amount of hits, 3. Interrupted by damage taken, 4. do_after fails (position change)
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/proc/TrashDisposalHit(mob/living/victim, mob/living/user = src, hit_count)
	// Only perform the hit if we haven't taken enough damage to interrupt the sequence
	if(trash_disposal_damagetaken < trash_disposal_damagetaken_cap)
		// This do_after controls how fast the hits happen. It can fail if our position changes, or the victim's does.
		if(do_after(user, time_between_trash_disposal_hits, target = victim))
			user.do_attack_animation(victim)
			playsound(user, attack_sound, 100, TRUE)
			SpawnAppropiateGibs(victim)
			victim.deal_damage(special_ability_damage, melee_damage_type, src, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			SweeperHealing(special_ability_damage * 2)
			user.visible_message(span_danger("[user] rips into [victim] and refuels \himself with [victim.p_their()] blood!"))
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
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/proc/TrashDisposalCleanup(mob/living/victim, mob/living/user = src)
	toggle_ai(AI_ON)
	can_move = TRUE
	can_act = TRUE
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
			freed_animal.toggle_ai(AI_ON)
			return

/// Handles initiating a Trash Disposal if TrashDisposalTelegraph()'s throw managed to hit something.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
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
	toggle_ai(AI_ON)
	can_move = TRUE
	can_act = TRUE
	. = ..()

/// Failsafe proc in case we miss our throw entirely.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/proc/StopLunging()
	special_ability_activated = FALSE
	can_move = TRUE
	can_act = TRUE
	if(!trash_disposal_active)
		toggle_ai(AI_ON)

/obj/effect/temp_visual/trash_disposal_telegraph
	name = "Trash Designator Circle"
	icon = 'icons/mob/telegraphing/telegraph_holographic.dmi'
	icon_state = "target_circle"
	desc = "Uh oh."
	duration = 2.2 SECONDS
	randomdir = FALSE
	movement_type = PHASING | FLYING
	layer = POINT_LAYER

/obj/effect/gibspawner/generic/trash_disposal
	gibamounts = list(1, 1, 1)
	sound_vol = 30

/// PALE Commander. A frontliner that... deals PALE damage. That's quite enough as it is, but on top of that, they have access to a parry and counter followup.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale
	name = "\proper Commander Silvina"
	desc = "A tall humanoid with glowing pale fists."
	gender = FEMALE
	icon_state = "silvina"
	icon_living = "silvina"
	health = 1550
	maxHealth = 1550
	rapid_melee = 2
	move_to_delay = 3.5
	melee_damage_type = PALE_DAMAGE
	melee_damage_lower = 13
	melee_damage_upper = 17
	attack_verb_continuous = "pummels"
	attack_verb_simple = "pummel"
	damage_coeff = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 0.7, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 0.5)
	special_ability_cooldown_duration = 12 SECONDS
	special_ability_damage = 40
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/sweeper = 1)
	/// When TRUE, we will deflect almost all types of damage taken, and if we haven't already, counterattack.
	var/parrying = FALSE
	/// We'll only use our counterattack once per parry.
	var/counter_used = FALSE
	var/parry_stop_timer = null
	/// We shave this value off our parry cooldown when successfully riposting a target.
	var/counter_CDR = 9 SECONDS

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale/Initialize(mapload)
	. = ..()
	if(SSmaptype.maptype in SSmaptype.citymaps)
		guaranteed_butcher_results += list(/obj/item/head_trophy/indigo_head/pale = 1)

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale/PreDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	if(source)
		var/should_retaliate = !(attack_type & (ATTACK_TYPE_COUNTER | ATTACK_TYPE_ENVIRONMENT | ATTACK_TYPE_STATUS))
		if(should_retaliate && parrying && health > 0 && isliving(source))
			INVOKE_ASYNC(src, PROC_REF(Parry), source)
			return FALSE

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	if(source)
		var/should_retaliate = !(attack_type & (ATTACK_TYPE_COUNTER | ATTACK_TYPE_ENVIRONMENT | ATTACK_TYPE_STATUS))
		if(should_retaliate && . >= 30 && health > 0 && prob(75))
			INVOKE_ASYNC(src, PROC_REF(UseSpecialAbility))

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale/Move(atom/newloc, dir, step_x, step_y)
	if(special_ability_activated)
		return FALSE
	. = ..()

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale/AttackingTarget(atom/attacked_target)
	if(special_ability_activated)
		return FALSE
	. = ..()

/// Enter our parrying stance.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale/UseSpecialAbility(mob/living/target, mob/living/user)
	if(..())
		special_ability_activated = TRUE // This doesn't mean we're parrying just yet.
		counter_used = FALSE // Means we haven't used our riposte yet.

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

/// This proc is called after the timer runs out on our parry stance. It undoes all our changes from going into parry.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale/proc/StopParrying(success = FALSE)
	parrying = FALSE
	special_ability_activated = FALSE
	if(!success)
		visible_message(span_danger("[src] lowers \his defensive stance."))
	animate(src, 0.5 SECONDS, color = initial(color))

/// This gets called if someone hits us in our parrying stance. This proc just does visual and audio feedback that the attack was parried - the actual hit happens in ParryCounter only if they're in LoS and in range.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale/proc/Parry(mob/living/victim)
	// Indicate that we landed a parry.
	face_atom(victim)
	var/datum/effect_system/spark_spread/parry_sparks = new /datum/effect_system/spark_spread
	parry_sparks.set_up(4, 0, loc)
	parry_sparks.start()
	playsound(src, 'sound/weapons/parry.ogg', 100, FALSE, 5)

	if(!counter_used && can_see(src, victim, 12))
		counter_used = TRUE
		ParryCounter(victim)

/// The riposte that punishes someone who attacked us while we were parrying. This doesn't end the parry, but we won't be able to riposte for the rest of it.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale/proc/ParryCounter(mob/living/victim)
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
	victim.deal_damage(special_ability_damage, melee_damage_type, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_COUNTER))
	visible_message(span_userdanger("[src] deflects [victim]'s attack and performs a counter!"))
	SpawnAppropiateGibs(victim)
	SweeperHealing(maxHealth * 0.25)

	// CDR. Shouldn't have hit us...!!!!!!!!!!!!!!
	special_ability_cooldown -= counter_CDR

/// The WHITE Commander. This one is able to give Persistence to its underlings periodically. Can also shorten the cooldown of combat abilities for fellow Commanders.
/// For its combat ability, slashes in an area every once in a while, exactly like Lady of the Lake, just a bit smaller.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white
	name = "\proper Commander Adelheide"
	maxHealth = 2000
	health = 2000
	desc = "A tall humanoid with a white greatsword."
	gender = FEMALE
	icon_state = "adelheide"
	icon_living = "adelheide"
	melee_damage_type = WHITE_DAMAGE
	melee_damage_lower = 38
	melee_damage_upper = 43
	rapid_melee = 1
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	move_to_delay = 4
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 1.5, PALE_DAMAGE = 0.7)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/sweeper = 1)
	special_ability_cooldown_duration = 7 SECONDS
	special_ability_damage = 55
	buff_ability_capable = TRUE
	buff_ability_cooldown_duration = 18 SECONDS
	/// Shortens cooldowns for combat abilities for neighbors hit by this one's buff.
	var/buff_CDR = 5 SECONDS
	// Vars for the size of the slash combat ability. Taken from Lady of the Lake.
	var/slash_length = 2
	var/slash_width = 1

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white/Initialize(mapload)
	. = ..()
	if(SSmaptype.maptype in SSmaptype.citymaps)
		guaranteed_butcher_results += list(/obj/item/head_trophy/indigo_head/white = 1)

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white/CanAttack(atom/the_target)
	if(ishuman(the_target))
		var/mob/living/carbon/human/L = the_target
		if(L.sanity_lost && L.stat != DEAD)
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white/ApplyBuffEffect(mob/living/simple_animal/hostile/ordeal/goon)
	goon.GainPersistence(2) // Nanomachines, son. They harden in response to physical trauma...

	// Shorten combat ability cooldowns for Indigo Noon & Dusk allies. Ongoing cooldowns, that is.
	switch(goon.type)
		if(/mob/living/simple_animal/hostile/ordeal/indigo_dusk) // Other Commanders - Lower CD on Trash Disposal (Jacques), Hammer Slam (Maria), Parry (Silvina)
			var/mob/living/simple_animal/hostile/ordeal/indigo_dusk/fellow_commander = goon
			fellow_commander.special_ability_cooldown -= buff_CDR
		if(/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky) // Lanky Sweepers - Lower CD on Sweep the Backstreets (the dash)
			var/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky/beanstalk_lookin_guy = goon
			beanstalk_lookin_guy.dash_cooldown -= buff_CDR
		if(/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky) // Chunky Sweepers - Lower CD on Extract Fuel (the empowered lifesteal attack after being hit)
			var/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky/stocky_one = goon
			stocky_one.extract_fuel_cooldown -= buff_CDR

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white/UseSpecialAbility(mob/living/target, mob/living/user)
	if(..())
		INVOKE_ASYNC(src, PROC_REF(AreaSlash), target, user)
		return TRUE

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white/AttackingTarget(atom/attacked_target)
	if(special_ability_activated)
		return FALSE
	var/mob/living/creature_to_be_bisected = attacked_target
	if(istype(creature_to_be_bisected) && creature_to_be_bisected.stat != DEAD && UseSpecialAbility(creature_to_be_bisected)) // Cancel our attack if we're able to use our special instead
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white/Move(atom/newloc, dir, step_x, step_y)
	if(special_ability_activated)
		return FALSE
	. = ..()

// Copied code from the Lady of the Lake (Gold Noon). It's an AoE slash.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white/proc/AreaSlash(mob/living/target, mob/living/user)
	var/dir_to_target = get_cardinal_dir(get_turf(src), get_turf(target))
	var/turf/source_turf = get_turf(src)
	var/turf/area_of_effect = list()
	var/turf/middle_line = list()
	// Following switch statement handles building the Area of Effect for the slash.
	switch(dir_to_target)
		if(EAST)
			middle_line = getline(get_step_towards(source_turf, target), get_ranged_target_turf(source_turf, EAST, slash_length))
			for(var/turf/T in middle_line)
				if(T.density)
					break
				for(var/turf/Y in getline(T, get_ranged_target_turf(T, NORTH, slash_width)))
					if (Y.density)
						break
					if (Y in area_of_effect)
						continue
					area_of_effect += Y
				for(var/turf/U in getline(T, get_ranged_target_turf(T, SOUTH, slash_width)))
					if (U.density)
						break
					if (U in area_of_effect)
						continue
					area_of_effect += U
		if(WEST)
			middle_line = getline(get_step_towards(source_turf, target), get_ranged_target_turf(source_turf, WEST, slash_length))
			for(var/turf/T in middle_line)
				if(T.density)
					break
				for(var/turf/Y in getline(T, get_ranged_target_turf(T, NORTH, slash_width)))
					if (Y.density)
						break
					if (Y in area_of_effect)
						continue
					area_of_effect += Y
				for(var/turf/U in getline(T, get_ranged_target_turf(T, SOUTH, slash_width)))
					if (U.density)
						break
					if (U in area_of_effect)
						continue
					area_of_effect += U
		if(SOUTH)
			middle_line = getline(get_step_towards(source_turf, target), get_ranged_target_turf(source_turf, SOUTH, slash_length))
			for(var/turf/T in middle_line)
				if(T.density)
					break
				for(var/turf/Y in getline(T, get_ranged_target_turf(T, EAST, slash_width)))
					if (Y.density)
						break
					if (Y in area_of_effect)
						continue
					area_of_effect += Y
				for(var/turf/U in getline(T, get_ranged_target_turf(T, WEST, slash_width)))
					if (U.density)
						break
					if (U in area_of_effect)
						continue
					area_of_effect += U
		if(NORTH)
			middle_line = getline(get_step_towards(source_turf, target), get_ranged_target_turf(source_turf, NORTH, slash_length))
			for(var/turf/T in middle_line)
				if(T.density)
					break
				for(var/turf/Y in getline(T, get_ranged_target_turf(T, EAST, slash_width)))
					if (Y.density)
						break
					if (Y in area_of_effect)
						continue
					area_of_effect += Y
				for(var/turf/U in getline(T, get_ranged_target_turf(T, WEST, slash_width)))
					if (U.density)
						break
					if (U in area_of_effect)
						continue
					area_of_effect += U
		else
			for(var/turf/T in view(1, src))
				if (T.density)
					break
				if (T in area_of_effect)
					continue
				area_of_effect |= T
	if (!LAZYLEN(area_of_effect))
		return

	// This is where the actual slash telegraph and hit happen.
	special_ability_activated = TRUE
	dir = dir_to_target
	playsound(get_turf(src), 'sound/weapons/fixer/generic/sheath2.ogg', 75, 0, 5)
	for(var/turf/T in area_of_effect)
		new /obj/effect/temp_visual/sparkles/adelheide(T)
	visible_message(span_danger("[src] raises \his greatsword...!"))
	SLEEP_CHECK_DEATH(0.6 SECONDS)
	playsound(get_turf(src), 'sound/weapons/fixer/generic/blade3.ogg', 100, 0, 5)
	for(var/turf/T in area_of_effect)
		new /obj/effect/temp_visual/slice(T)
		for(var/mob/living/L in T)
			if(faction_check_mob(L))
				continue
			if (L == src)
				continue
			HurtInTurf(T, list(), special_ability_damage, melee_damage_type, check_faction = TRUE, exact_faction_match = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			playsound(T, attack_sound, 100, TRUE)
			// Big slice VFX
			var/obj/effect/temp_visual/dir_setting/slash/temp = new (T)
			temp.dir = NORTHWEST
			temp.transform = temp.transform * 1.75

	SLEEP_CHECK_DEATH(0.4 SECONDS)
	special_ability_activated = FALSE

/obj/effect/temp_visual/sparkles/adelheide
	duration = 0.6 SECONDS

/// The BLACK commander. A bit more threatening in melee (since you're likelier to have good BLACK armour against this ordeal).
/// Can periodically give its allies a powerful buff, increasing their attack and movement speed, as well as their melee damage. Can do a large AoE hammer slam, with knockback if you get hit.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black
	name = "\proper Commander Maria"
	desc = "A tall humanoid with a large black hammer."
	gender = FEMALE
	health = 1650
	maxHealth = 1650
	icon_state = "maria"
	icon_living = "maria"
	melee_damage_type = BLACK_DAMAGE
	melee_damage_lower = 40
	melee_damage_upper = 45
	rapid_melee = 1
	attack_verb_continuous = "slams"
	attack_verb_simple = "stam"
	move_to_delay = 4
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 0.7, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 1.5)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/sweeper = 1)
	buff_ability_capable = TRUE
	buff_ability_cooldown_duration = 25 SECONDS
	special_ability_damage = 60
	special_ability_cooldown_duration = 12 SECONDS
	// The below bonuses are flat and additive.
	/// Raise ally attack damage by this amount
	var/buff_melee_bonus = 4
	/// Lower ally move delay by this amount
	var/buff_movespeed_bonus = 0.7
	/// Raise ally rapid_melee by this amount
	var/buff_attackspeed_bonus = 1
	/// Buff lasts this long
	var/buff_duration = 8 SECONDS
	/// Telegraph duration for the hammer slam attack
	var/slam_windup = 1.3 SECONDS
	/// Range in tiles of the hammer slam attack
	var/slam_range = 2

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black/Initialize(mapload)
	. = ..()
	if(SSmaptype.maptype in SSmaptype.citymaps)
		guaranteed_butcher_results += list(/obj/item/head_trophy/indigo_head/black = 1)

/// Maria's buff is handled purely with timers, no status effect datum is involved.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black/ApplyBuffEffect(mob/living/simple_animal/hostile/ordeal/goon)
	BlackCommanderBuff(goon)
	addtimer(CALLBACK(src, PROC_REF(BlackCommanderBuffRevert), goon), buff_duration) // IN THEORY. IF MARIA IS GIBBED BEFORE THE BUFF REVERTS. THE AFFECTED SWEEPERS MAY BE PERMA BUFFED. Coding a fix for this is more trouble than it's worth

/// The buff briefly colours the sweepers black to indicate they were hit by it.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black/proc/BlackCommanderBuff(mob/living/simple_animal/hostile/ordeal/goon)
	var/prev_color = goon.color
	goon.rapid_melee += buff_attackspeed_bonus
	goon.ChangeMoveToDelay(goon.move_to_delay - buff_movespeed_bonus)
	goon.melee_damage_lower += buff_melee_bonus
	goon.melee_damage_upper += buff_melee_bonus
	animate(goon, time = 0.7 SECONDS, color = "#1a1717")
	animate(time = 1.1 SECONDS, color = prev_color)

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black/proc/BlackCommanderBuffRevert(mob/living/simple_animal/hostile/ordeal/goon)
	// I'm reverting the buff like this instead of using initial() in case those values change during the buff for whatever reason, such as lanky noon Evasive Mode.
	goon.rapid_melee -= buff_attackspeed_bonus
	goon.ChangeMoveToDelay(goon.move_to_delay + buff_movespeed_bonus)
	goon.melee_damage_lower -= buff_melee_bonus
	goon.melee_damage_upper -= buff_melee_bonus

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black/AttackingTarget(atom/attacked_target)
	if(special_ability_activated)
		return FALSE
	var/mob/living/creature_to_be_pancaked = attacked_target
	if(istype(creature_to_be_pancaked) && creature_to_be_pancaked.stat != DEAD && UseSpecialAbility(creature_to_be_pancaked)) // Cancel our attack if we can use our special instead
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black/Move(atom/newloc, dir, step_x, step_y)
	if(special_ability_activated)
		return FALSE
	. = ..()

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black/UseSpecialAbility(mob/living/target, mob/living/user)
	if(prob(20))
		return FALSE // Will not always use its hammer slam when possible, add a bit of randomness into it.
	if(..())
		INVOKE_ASYNC(src, PROC_REF(AreaSlam), target, user)
		return TRUE

/// Big, targeted AoE slam, easy to dodge, but will knock you back if hit. A choke-breaker.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black/proc/AreaSlam(mob/living/target, mob/living/user)
	special_ability_activated = TRUE
	var/turf/target_turf = get_turf(target)
	var/list/affected_turfs = view(slam_range, target_turf)

	// Telegraph
	playsound(get_turf(src), 'sound/weapons/fixer/generic/dodge.ogg', 100, FALSE, extrarange = 5)
	for(var/turf/L in affected_turfs)
		new /obj/effect/temp_visual/sparkles/maria(L)
	visible_message(span_danger("[src] raises \his hammer...!"))
	SLEEP_CHECK_DEATH(slam_windup)

	// Hit
	for(var/turf/T in affected_turfs)
		new /obj/effect/temp_visual/smash_effect(T)
		for(var/mob/living/L in HurtInTurf(T, list(), special_ability_damage, melee_damage_type, check_faction = TRUE, exact_faction_match = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)))
			var/throw_comparison = L.loc == target_turf ? src : target_turf // if they're standing on the turf we're targeting we'll throw them directly away from us
			var/throw_dir = get_cardinal_dir(throw_comparison, L)
			if(L)
				L.safe_throw_at(target = get_ranged_target_turf(target_turf, throw_dir, 4), range = 4, speed = 2, thrower = src, spin = TRUE)
				if(L.health < 0)
					L.gib()
	playsound(get_turf(src), 'sound/weapons/ego/hammer.ogg', 100, FALSE, extrarange = 5)
	SLEEP_CHECK_DEATH(0.5 SECONDS)
	special_ability_activated = FALSE

/obj/effect/temp_visual/sparkles/maria
	duration = 1.3 SECONDS
	color = COLOR_BLACK
