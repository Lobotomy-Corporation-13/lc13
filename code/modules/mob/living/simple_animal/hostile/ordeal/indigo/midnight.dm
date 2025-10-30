#define COMBAT_ABILITY_DASH "dash"
#define COMBAT_ABILITY_SLAM "slam"
#define COMBAT_ABILITY_TRASH_DISPOSAL "disposal"
#define COMBAT_ABILITY_SLASH "slash"
#define COMBAT_ABILITY_PARRY "parry"

#define SUPPORT_ABILITY_OFFENSIVE "frenzy"
#define SUPPORT_ABILITY_PERSISTENCE "persistence"
#define SUPPORT_ABILITY_SUMMON "summon"


/mob/living/simple_animal/hostile/ordeal/indigo_midnight
	name = "Matriarch"
	desc = "A humanoid creature wearing metallic armor. The Queen of sweepers."
	icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
	icon_state = "matriarch"
	icon_living = "matriarch"
	icon_dead = "matriarch_dead"
	faction = list("indigo_ordeal")
	maxHealth = 6500
	health = 6500
	stat_attack = DEAD
	pixel_x = -16
	base_pixel_x = -16
	melee_damage_type = BLACK_DAMAGE
	move_to_delay = 3
	rapid_melee = 2
	melee_damage_lower = 60
	melee_damage_upper = 60
	butcher_results = list(/obj/item/food/meat/slab/sweeper = 4)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/sweeper = 3)
	attack_verb_continuous = "stabs"
	attack_verb_simple = "stab"
	attack_sound = 'sound/effects/ordeals/indigo/stab_1.ogg'
	damage_coeff = list(RED_DAMAGE = 0.3, WHITE_DAMAGE = 0.4, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 0.5)
	blood_volume = BLOOD_VOLUME_NORMAL
	move_resist = MOVE_FORCE_OVERPOWERING
	can_patrol = TRUE
	occupied_tiles_up = 1
	offsets_pixel_x = list("south" = -16, "north" = -16, "west" = -16, "east" = -16)

	//How many people has she eaten
	var/belly = 0
	//How mad is she?
	var/phase = 1

	/* ABILITIES SECTION
	!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	The Matriarch has access to some of her own abilities, and a bunch of upgraded abilities from her subordinates:
	Combat:
		- Sweep the Backstreets, a dash ability from Lanky Sweepers. On hit, heals and resets cooldown.
		- Ground Slam, her own ability. Deals RED damage instead of BLACK. Formerly, this checked for BLACK armour, but the germination of the seed of light requires you to suffer, so it checks for RED as normal.
		- Trash Disposal, a lunge from Commander Jacques (RED Indigo Dusk). This makes her leap at a target, and if her leap connects, she will pin them and repeatedly attack, dealing ramping damage and healing herself.
		- Slash, a simple AoE from Commander Adelheide (WHITE Indigo Dusk), who in turn stole it from Lady of the Lake. This is a simple, dodgeable slash, but its shape alternates between wide and long.
	Support:
		- Offensive Command, an ability from Commander Maria (BLACK Indigo Dusk). This makes all nearby allies move and attack faster and harder, making them appropiate threats for endgame.
		- Persistent Command, an ability from Commander Adelheide (WHITE Indigo Dusk). This gives all nearby allies three stacks of Persistence and cuts their ongoing combat ability cooldowns by 90%.
		- Summon Sweepers, her own ability. It's self explanatory.  Will summon standard sweepers as well as variants. Later, able to also summon Indigo Dusks.
	*/
	/// Unable to move or attack while busy.
	var/busy = FALSE
	/// Just unable to attack.
	var/pacified = FALSE

	/// Will initiate Trash Disposal on anyone she's thrown at while this is TRUE. Will not be able to attack while it is TRUE.
	var/lunging = FALSE
	/// An incoming hit will result in a riposte while this is TRUE.
	var/parrying = FALSE
	/// This is TRUE while we're in the process of riposting, we'll not do any further ripostes on incoming attacks.
	var/riposting = FALSE
	/// Add turfs we step onto into a list to hit later, if we're in this state.
	var/dashing = FALSE


	// available_abilities holds the abilities the Matriarch is cleared to use as keys and their current cooldowns as values.
	var/list/available_abilities = list()
	// This one holds the intended cooldown duration for every ability.
	var/list/ability_cooldown_durations = list(
		COMBAT_ABILITY_DASH = 15 SECONDS,
		COMBAT_ABILITY_SLAM = 10 SECONDS,
		COMBAT_ABILITY_SLASH = 8 SECONDS,
		COMBAT_ABILITY_TRASH_DISPOSAL = 20 SECONDS,
		COMBAT_ABILITY_PARRY = 18 SECONDS,
		SUPPORT_ABILITY_OFFENSIVE = 35 SECONDS,
		SUPPORT_ABILITY_PERSISTENCE = 20 SECONDS,
		SUPPORT_ABILITY_SUMMON = 40 SECONDS,
	)
	// These two lists, we will pick and take from to add abilities as the fight progresses. On Initialize we pluck three out of all_combat_abilities to start with as a base.
	var/list/all_combat_abilities = list(COMBAT_ABILITY_DASH, COMBAT_ABILITY_SLAM, COMBAT_ABILITY_SLASH, COMBAT_ABILITY_TRASH_DISPOSAL, COMBAT_ABILITY_PARRY)
	var/list/all_support_abilities = list(SUPPORT_ABILITY_OFFENSIVE, SUPPORT_ABILITY_PERSISTENCE) // Summon is excluded, we have it by default.


	/// We need this to not hit multiple people due to the implementation I used for the dash. Stores every mob hit by the dash, cleared on each dash.
	var/list/dash_hitlist = list()
	/// This one is so we can hit all the turfs with the dash at once, to avoid people dodging it by moving inside of it.
	var/list/dash_hitlist_turfs = list()
	var/dash_range = 7


	// Vars for the size of the slash combat ability. Taken from Lady of the Lake.
	// We will swap these every time we use the ability.
	var/slash_length = 3
	var/slash_width = 1

	var/parry_stop_timer = null
	var/riposte_CDR = 9 SECONDS

	/// How many deciseconds between trash disposal hits? Reduced by 1 decisecond on each hit.
	var/time_between_trash_disposal_hits = 1 SECONDS

	// Frustration mechanic: if ranged attacks are being used on us, punish the players.
	// Formerly went off of hitcount, but this unfairly penalized fast firing guns while letting big war criminal guns like Arcadia get off easy.
	// Now goes off of the bullets' damage value multiplied by our coeff towards it..

	/// Ranged damage taken. Reset by RangedReaction().
	var/frustration_meter
	/// Damage threshold over which we'll trigger a RangedReaction().
	var/frustration_threshold = 150


	/* PHASE SCALING SECTION
	!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	*/
	// Big block of phases_ vars that determine what properties she has in each stage. I found this approach to be more useful for being able to compare and directly tweak the values in one place.

	// Association list of key: phase to value: amount of health under which the next phase gets triggered.
	var/list/phases_health_thresholds = list(1 = 5000, 2 = 2500, 3 = -INFINITY)

	var/list/phases_icon_states = list(1 = "matriarch", 2 = "matriarch_slim", 3 = "matriarch_fast")
	// Association lists that control different balancing values for each phase. The keys are the phase, the values are the corresponding intended value for that phase.
	var/list/phases_move_delays = list(1 = 3, 2 = 2.6, 3 = 2.2)
	var/list/phases_rapid_melee = list(1 = 2, 2 = 3, 3 = 4)
	var/list/phases_melee_damage = list(1 = 60, 2 = 50, 3 = 40)
	var/list/phases_resistance_lists = list(
	1 = list(RED_DAMAGE = 0.3, WHITE_DAMAGE = 0.4, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 0.5),
	2 = list(RED_DAMAGE = 0.4, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 0.25, PALE_DAMAGE = 0.8),
	3 = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.3, PALE_DAMAGE = 1),
	)

	var/list/phases_slam_windup = list(1 = 1.2 SECONDS, 2 = 1 SECONDS, 3 = 0.8 SECONDS)
	var/list/phases_slam_damage = list(1 = 100, 2 = 90, 3 = 80)
	var/list/phases_slam_range = list(1 = 3, 2 = 2, 3 = 2)

	var/list/phases_slash_damage = list(1 = 110, 2 = 90, 3 = 80)

	var/list/phases_dash_windup = list(1 = 1.3 SECONDS, 2 = 0.8 SECONDS, 3 = 0.6 SECONDS)
	var/list/phases_dash_damage = list(1 = 80, 2 = 70, 3 = 60)
	var/list/phases_dash_healing = list(1 = 150, 2 = 200, 3 = 250)

	var/list/phases_riposte_damage = list(1 = 140, 2 = 120, 3 = 100)
	var/list/phases_riposte_healing = list(1 = 200, 2 = 300, 3 = 400)

	var/list/phases_disposal_damage = list(1 = 50, 2 = 44, 3 = 35)
	var/list/phases_disposal_healing = list(1 = 30, 2 = 60, 3 = 100)

/*
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
GENERAL OVERRIDES, PATROLLING AND TARGETING SECTION
This is all code relating to targeting bodies, patrolling and all of that.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*/

/mob/living/simple_animal/hostile/ordeal/indigo_midnight/Initialize(mapload)
	. = ..()
	// Follow me if you want to live.
	var/units_to_add = list(
		/mob/living/simple_animal/hostile/ordeal/indigo_noon = 1,
		/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky = 1,
		/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky = 1,
		/mob/living/simple_animal/hostile/ordeal/indigo_dawn = 1,
		/mob/living/simple_animal/hostile/ordeal/indigo_midnight = 1,
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white = 1,
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black = 1,
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale = 1,
		)
	AddComponent(/datum/component/ai_leadership, units_to_add)

	// Give us three combat abilities and Summon Sweepers to begin with. We begin with half their cooldown ticked down.
	for(var/i in 1 to 3)
		var/chosen_combat_ability = pick_n_take(all_combat_abilities)
		if(chosen_combat_ability)
			available_abilities[chosen_combat_ability] = ability_cooldown_durations[chosen_combat_ability] * 0.5
	available_abilities[SUPPORT_ABILITY_SUMMON] = ability_cooldown_durations[SUPPORT_ABILITY_SUMMON] * 0.5

/mob/living/simple_animal/hostile/ordeal/indigo_midnight/Life()
	. = ..()
	if(!.) // Dead
		return FALSE
	if(health <= phases_health_thresholds[phase])
		PhaseChange()

/mob/living/simple_animal/hostile/ordeal/indigo_midnight/Move(atom/newloc, dir, step_x, step_y)
	if(busy)
		return FALSE
	. = ..()
	if(dashing)
		playsound(src, 'sound/effects/meteorimpact.ogg', 75, TRUE, 2, TRUE)
		dash_hitlist_turfs |= get_turf(newloc)
		for(var/turf/T in view(1, newloc))
			dash_hitlist_turfs |= T

//Remind me to return to this and make complex targeting a option for all creatures. I may make it a TRUE FALSE var.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/ValueTarget(atom/target_thing)
	//Higher brain functions have been turned off.
	if(phase >= 3)
		return ..()

	. = ..()

	if(isliving(target_thing))
		var/mob/living/L = target_thing
		//Hate for corpses since we eats them.
		if(L.stat == DEAD)
			. += 10
		//Highest possible addition is + 9.9
		if(iscarbon(L))
			if(L.stat != DEAD && L.health <= (L.maxHealth * 0.6))
				var/upper = L.maxHealth - HEALTH_THRESHOLD_DEAD
				var/lower = L.health - HEALTH_THRESHOLD_DEAD
				. += min( 2 * ( 1 / ( max( lower, 1 ) / upper ) ), 20)

	/*
	Priority from greatest to least:
	dead close: 90
	close: 80
	dead far: 40
	far: 30
	*/

//Stolen MOSB patrol code
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/CanStartPatrol()
	return (AIStatus != AI_OFF && !(status_flags & GODMODE)) && !target

/mob/living/simple_animal/hostile/ordeal/indigo_midnight/patrol_reset()
	. = ..()
	FindTarget() // Start eating corpses IMMEDIATELLY

/mob/living/simple_animal/hostile/ordeal/indigo_midnight/patrol_select()
	var/list/low_priority_turfs = list() // Oh, you're wounded, how nice.
	var/list/medium_priority_turfs = list() // You're about to die and you are close? Splendid.
	var/list/high_priority_turfs = list() // IS THAT A DEAD BODY?
	for(var/mob/living/carbon/human/H in GLOB.human_list)
		if(H.z != z) // Not on our level
			continue
		if(get_dist(src, H) < 4) // Way too close
			continue
		if(H.stat != DEAD) // Not dead people
			if(H.health < H.maxHealth*0.5)
				if(get_dist(src, H) > 24) // Way too far
					low_priority_turfs += get_turf(H)
					continue
				medium_priority_turfs += get_turf(H)
			continue
		if(get_dist(src, H) > 24) // Those are dead people
			medium_priority_turfs += get_turf(H)
			continue
		high_priority_turfs += get_turf(H)

	var/turf/target_turf
	if(LAZYLEN(high_priority_turfs))
		target_turf = get_closest_atom(/turf/open, high_priority_turfs, src)
	else if(LAZYLEN(medium_priority_turfs))
		target_turf = get_closest_atom(/turf/open, medium_priority_turfs, src)
	else if(LAZYLEN(low_priority_turfs))
		target_turf = get_closest_atom(/turf/open, low_priority_turfs, src)

	if(istype(target_turf))
		patrol_path = get_path_to(src, target_turf, TYPE_PROC_REF(/turf, Distance_cardinal), 0, 200)
		return TRUE
	//unsure if this patrol reset will cause the patrol cooldown even if there is not patrol path.
	patrol_reset()
	return FALSE




/*
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FRUSTRATION & RANGED DEFENSE SECTION
This is all code relating to handling incoming ranged damage.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*/

/mob/living/simple_animal/hostile/ordeal/indigo_midnight/bullet_act(obj/projectile/P)
	// Activating Riposte...
	if(parrying && health > 0 && isliving(P.firer) && (get_dist(P.firer, src) < 15))
		ParryCounter(P.firer)
		return FALSE
	. = ..()
	// Frustration buildup.
	var/bullet_damage_type = P.damage_type
	frustration_meter += (P.damage * damage_coeff.getCoeff(bullet_damage_type)) // If we have 0.5 PALE coeff, and are hit by a 100 PALE damage bullet, add 50 to Frustration.
	if(frustration_meter >= frustration_threshold)
		RangedReaction(P.firer)

	// Activating Parry...
	// This won't activate on low caliber projectiles like Havana.
	if(P.damage >= 20 && health > 0 && prob(75))
		INVOKE_ASYNC(src, PROC_REF(BeginParry)) // It's ASYNC because there's a sleep in it

/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/RangedReaction(mob/living/firer)
	frustration_meter = 0
	if(istype(firer))
		// behaviour towards firer goes here
		say("AIIIIEEE [firer] SHOT ME")
	// general behaviour goes here
	return

/*
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
PHASE SECTION
This is all code relating to handling phase changes.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*/

/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/PhaseChange()
	// Warn players of the phase change.
	icon_state = "phasechange"
	SLEEP_CHECK_DEATH(5)

	// Our max hp is now capped at the max health threshold that got passed to enter this phase.
	maxHealth = phases_health_thresholds[phase]
	phase++

	// This is the bulk of the stat changes. She gets tougher, faster, attacks faster, but deals less damage.
	ChangeResistances(phases_resistance_lists[phase])
	ChangeMoveToDelay(phases_move_delays[phase])
	rapid_melee = phases_rapid_melee[phase]
	melee_damage_lower = phases_melee_damage[phase]
	melee_damage_upper = phases_melee_damage[phase]
	icon_state = phases_icon_states[phase]
	icon_living = phases_icon_states[phase]

	// Gain a new combat ability and support ability. Immediately available.
	var/new_combat_ability = pick_n_take(all_combat_abilities)
	if(new_combat_ability)
		available_abilities[new_combat_ability] = 0
	var/new_support_ability = pick_n_take(all_support_abilities)
	if(new_support_ability)
		available_abilities[new_support_ability] = 0


/*
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
COMBAT SECTION
This is all code relating to Matriarch's combat abilities and auxiliary stuff for combat.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*/

// !!! Melee attack override: Basis of how we call most of our attacks. !!!
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/AttackingTarget(atom/attacked_target)
	if(busy || parrying || riposting || lunging || pacified)
		return FALSE

	var/mob/living/attacked_living = attacked_target
	if(istype(attacked_living) && attacked_living.stat < DEAD && AttemptUseCombatAbility(attacked_target))
		return FALSE

	. = ..()

	if(. && attacked_living)
		var/mob/living/L = attacked_target
		if(L.stat != DEAD)
			if(L.health <= HEALTH_THRESHOLD_DEAD && HAS_TRAIT(L, TRAIT_NODEATH))
				SweeperDevour(L)
		else
			SweeperDevour(L)


/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/AttemptUseCombatAbility(mob/living/victim)
	// This is definitely ONE of the ways to handle this
	// The reason why this is an else if chain, is because I wanted to prioritize certain abilities over others
	// Naturally there are other ways to do this, but this is the simplest, in my opinion
	if((available_abilities[COMBAT_ABILITY_TRASH_DISPOSAL] != null) && available_abilities[COMBAT_ABILITY_TRASH_DISPOSAL] <= world.time)
		INVOKE_ASYNC(src, PROC_REF(TrashDisposalTelegraph), victim)
		return TRUE
	else if((available_abilities[COMBAT_ABILITY_DASH] != null) && available_abilities[COMBAT_ABILITY_DASH] <= world.time)
		INVOKE_ASYNC(src, PROC_REF(SweepTheBackstreets), victim)
		return TRUE
	else if((available_abilities[COMBAT_ABILITY_SLAM] != null) && available_abilities[COMBAT_ABILITY_SLAM] <= world.time)
		INVOKE_ASYNC(src, PROC_REF(AttackGroundSlam), phases_slam_range[phase])
		return TRUE
	else if((available_abilities[COMBAT_ABILITY_SLASH] != null) && available_abilities[COMBAT_ABILITY_SLASH] <= world.time)
		INVOKE_ASYNC(src, PROC_REF(AreaSlash), victim)
		return TRUE
	else
		return FALSE


// !!! Devour override: Handles what happens when we devour a corpse. !!!
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/SweeperDevour(mob/living/L)
	var/devoured_is_sweeper = faction_check_mob(L, TRUE)
	. = ..()
	if(!devoured_is_sweeper)
		// we ate a human/other ordeal/a damn clerkbot or something
		// consequences here
		say("yummy non sweeper corpse")

// !!! Combat ability: Ground Slam. !!!
/// cannibalized from wendigo
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/AttackGroundSlam(range)
	busy = TRUE
	available_abilities[COMBAT_ABILITY_SLAM] = ability_cooldown_durations[COMBAT_ABILITY_SLAM] + world.time

	for(var/turf/W in range(range, src))
		new /obj/effect/temp_visual/guardian/phase(W)
	sleep(phases_slam_windup[phase])
	var/turf/orgin = get_turf(src)
	var/list/all_turfs = RANGE_TURFS(range, orgin)
	for(var/i = 0 to range)
		for(var/turf/T in all_turfs)
			if(get_dist(orgin, T) > i)
				continue
			playsound(T,'sound/effects/bamf.ogg', 60, TRUE, 10)
			new /obj/effect/temp_visual/small_smoke/halfsecond(T)
			for(var/mob/living/carbon/human/L in T)
				if(L == src || L.throwing)
					continue
				to_chat(L, span_userdanger("[src]'s ground slam shockwave sends you flying!"))
				var/turf/thrownat = get_ranged_target_turf_direct(src, L, 8, rand(-10, 10))
				L.throw_at(thrownat, 8, 2, src, TRUE, force = MOVE_FORCE_OVERPOWERING, gentle = TRUE)
				L.deal_damage(phases_slam_damage[phase], RED_DAMAGE)
				shake_camera(L, 2, 1)
			all_turfs -= T
		sleep(1)
	busy = FALSE

// !!! Combat ability: Sweep the Backstreets (dash). !!!

/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/SweepTheBackstreets(atom/prospective_fuel = target)
	if(stat == DEAD || busy || dashing)
		return FALSE
	if(get_dist(src, prospective_fuel) > dash_range)
		return FALSE
	var/turf/dash_start_turf = get_turf(src)
	var/turf/dash_target_turf = get_ranged_target_turf_direct(src, prospective_fuel, dash_range)
	if(!dash_target_turf)
		return FALSE

	/// We got those checks out of the way - prepare to dash.
	available_abilities[COMBAT_ABILITY_DASH] = world.time + ability_cooldown_durations[COMBAT_ABILITY_DASH]
	PrepareDash()
	LoseTarget()
	/// This section is for telegraphing the attack.
	face_atom(prospective_fuel)
	say("+2653 753 842396.+")
	new /obj/effect/temp_visual/dragon_swoop/bubblegum(dash_target_turf)
	SLEEP_CHECK_DEATH(phases_dash_windup[phase])
	/// We're now dashing.
	BeginDash()
	walk_towards(src, dash_target_turf, 0.1)
	SLEEP_CHECK_DEATH(get_dist(src, dash_target_turf) * 0.1)

	/// This part is for some visual/audio feedback.
	var/datum/beam/really_temporary_beam = dash_start_turf.Beam(src, icon_state = "1-full", time = 3)
	really_temporary_beam.visuals.color = "#ee214d"
	playsound(src, 'sound/weapons/fixer/generic/knife3.ogg', 100, FALSE, 4)

	/// We're done dashing. Hit all the affected turfs at the same time (to avoid people dodging it by moving into it).
	/// The Sweeper won't have added the final turf onto its hit list, so we add it here.
	/// Yes it needs to get slept for 0.1 second here because... it hasn't finished moving or something. I've tested it. Trust me.
	SLEEP_CHECK_DEATH(0.1 SECONDS)
	CancelDash()
	dash_hitlist_turfs |= get_turf(src)
	SweepTheBackstreetsHit(dash_hitlist_turfs)
	/// Give the players a tiny bit of time to not instantly get auto hit by the Matriarch after she dashes.
	SLEEP_CHECK_DEATH(0.4 SECONDS)

	/// Re-target our old target.
	if(!client)
		GiveTarget(prospective_fuel)
	busy = FALSE
	return TRUE

/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/SweepTheBackstreetsHit(list/turfs)
	for(var/hit_turf in turfs)
		new /obj/effect/temp_visual/small_smoke/halfsecond(hit_turf)
		for(var/mob/living/hit_mob in HurtInTurf(hit_turf, dash_hitlist, phases_dash_damage[phase], melee_damage_type, check_faction = TRUE, hurt_mechs = TRUE, hurt_structure = TRUE))
			to_chat(hit_mob, span_userdanger("[src] viciously slashes you as she dashes past!"))
			/// We spawn some gibs and heal if the target hit is human.
			if(istype(hit_mob, /mob/living/carbon/human))
				new /obj/effect/gibspawner/generic(get_turf(hit_mob))
				SweeperHealing(phases_dash_healing[phase])
				playsound(hit_mob, attack_sound, 100)
				available_abilities[COMBAT_ABILITY_DASH] = world.time

/// Called when we're entering a dash (passed all the checks).
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/PrepareDash()
	busy = TRUE
	dashing = FALSE
	/// Can't get pushed away during this.
	anchored = TRUE
	/// Reset our hit lists.
	dash_hitlist = list()
	dash_hitlist_turfs = list()

/// Called to begin dashing properly.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/BeginDash()
	busy = FALSE
	/// All turfs we move into while dashing as long as this variable is TRUE will be registered by Move() to be passed onto SweepTheBackstreetsHit() by SweepTheBackstreets().
	dashing = TRUE
	/// We can move again.
	anchored = FALSE
	/// We can move through mobs and tables.
	pass_flags = PASSMOB | PASSTABLE
	density = FALSE

/// This is called when the dash is cancelled early by a failed movement or when the dash reached its destination. It just resets us back to our base state.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/CancelDash()
	dashing = FALSE
	busy = FALSE
	pass_flags = initial(pass_flags)
	density = TRUE

// !!! Combat ability: Slash. !!!

// Copied code from the Lady of the Lake (Gold Noon). It's an AoE slash.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/AreaSlash(mob/living/target, mob/living/user, repeat = TRUE)
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

	available_abilities[COMBAT_ABILITY_SLASH] = ability_cooldown_durations[COMBAT_ABILITY_SLASH] + world.time

	// This is where the actual slash telegraph and hit happen.
	busy = TRUE
	dir = dir_to_target
	playsound(get_turf(src), 'sound/weapons/fixer/generic/sheath2.ogg', 75, 0, 5)
	for(var/turf/T in area_of_effect)
		new /obj/effect/temp_visual/sparkles/adelheide(T) // These are white sparkles. Strange, considering Matri's colour scheme, right? Consider that the floor will be covered in blood.

	visible_message(span_danger("[src] raises her claws...!"))
	SLEEP_CHECK_DEATH(0.6 SECONDS)
	playsound(get_turf(src), 'sound/weapons/fixer/generic/blade3.ogg', 100, 0, 5)
	for(var/turf/T in area_of_effect)
		var/obj/effect/temp_visual/slice/pretty_sliced_up = new(T)
		pretty_sliced_up.color = COLOR_MOSTLY_PURE_PINK
		for(var/mob/living/L in T)
			if(faction_check_mob(L))
				continue
			if (L == src)
				continue
			HurtInTurf(T, list(), phases_slash_damage[phase], melee_damage_type, check_faction = TRUE, hurt_mechs = TRUE)
	SLEEP_CHECK_DEATH(0.4 SECONDS)
	busy = FALSE

	var/old_length = slash_length
	slash_length = slash_width
	slash_width = old_length

	if(repeat && (phase >= 2))
		INVOKE_ASYNC(src, PROC_REF(AreaSlash), target, user, FALSE)
		return TRUE

	return TRUE

// !!! Combat ability: Parry !!!

/// Activates parrying behaviour when hit by a simple_animal.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/attack_animal(mob/living/simple_animal/M, damage)
	// If we're hit in melee by a living mob, while parrying, and are still alive, we retaliate. The attack on us gets cancelled.
	if(parrying && health > 0 && istype(M))
		ParryCounter(M)
		return FALSE
	. = ..()
	// If we're hit by a sufficiently strong melee attack, 75% of the time we will go into our parrying stance.
	if(health > 0 && prob(75))
		INVOKE_ASYNC(src, PROC_REF(BeginParry), M, src) // It's ASYNC because there's a sleep in it

/// Activates parrying behaviour when hit by a human with an object.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/attacked_by(obj/item/I, mob/living/user)
	// If we're hit in melee by a living mob, while parrying, and are still alive, we retaliate. The attack on us gets cancelled.
	if(parrying && health > 0 && istype(user))
		ParryCounter(user)
		return FALSE
	. = ..()
	// If we're hit by a sufficiently strong melee attack, 75% of the time we will go into our parrying stance.
	if(health > 0 && I.force >= 10 && prob(75))
		INVOKE_ASYNC(src, PROC_REF(BeginParry), user, src) // It's ASYNC because there's a sleep in it


/// Enter our parrying stance.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/BeginParry(mob/living/target, mob/living/user)
	if((available_abilities[COMBAT_ABILITY_PARRY] != null) && available_abilities[COMBAT_ABILITY_PARRY] <= world.time)
		available_abilities[COMBAT_ABILITY_PARRY] = ability_cooldown_durations[COMBAT_ABILITY_PARRY] + world.time
		busy = TRUE // This doesn't mean we're parrying just yet.
		// Telegraph that we're beginning a parry to give players time to stop attacking. We're not actively parrying at this point.
		say("676 3246!!")
		visible_message(span_userdanger("[src] enters a parrying stance!"))
		var/atom/temp = new /obj/effect/temp_visual/markedfordeath(get_turf(src))
		temp.pixel_y += 32
		playsound(src, 'sound/abnormalities/crumbling/warning.ogg', 50, FALSE, 3)
		animate(src, 0.4 SECONDS, color = COLOR_MOSTLY_PURE_RED)
		SLEEP_CHECK_DEATH(0.7 SECONDS)
		// Now we actually enter our parry stance.
		parrying = TRUE
		parry_stop_timer = addtimer(CALLBACK(src, PROC_REF(StopParrying)), 1.3 SECONDS, TIMER_STOPPABLE)

/// This proc is called after successfully parrying, or after the timer runs out on our parry stance. It undoes all our changes from going into parry.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/StopParrying(success = FALSE)
	parrying = FALSE
	busy = FALSE
	if(!success)
		visible_message(span_danger("[src] lowers their defensive stance."))
	animate(src, 0.5 SECONDS, color = initial(color))

/// This gets called if someone hits us in our parrying stance. Retaliate by teleporting through them and attacking. We'll heal a bit too.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/ParryCounter(mob/living/victim)
	var/riposte_damage = phases_riposte_damage[phase]
	if(istype(victim, /mob/living/simple_animal/hostile))
		riposte_damage *= 2

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
	really_temporary_beam.visuals.color = COLOR_MOSTLY_PURE_PINK

	// Hit the target.
	src.do_attack_animation(victim)
	playsound(src, 'sound/abnormalities/crumbling/attack.ogg', 75, FALSE)
	new /obj/effect/gibspawner/generic/trash_disposal(get_turf(victim))
	victim.deal_damage(riposte_damage, melee_damage_type)
	visible_message(span_userdanger("[src] deflects [victim]'s attack and performs a counter!"))
	SweeperHealing(phases_riposte_healing[phase])
	// CDR. Shouldn't have hit us...!!!!!!!!!!!!!!
	available_abilities[COMBAT_ABILITY_PARRY] -= riposte_CDR


// !!! Combat ability: Trash Disposal !!!

/// First part of Trash Disposal. It CAN fail. Warns all nearby players they're about to get lunged at, then throws the Matriarch at one.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/TrashDisposalTelegraph(mob/living/victim, mob/living/user = src)
	busy = TRUE
	toggle_ai(AI_OFF)
	LoseTarget()
	walk_to(src, 0) // Resets any ongoing movement

	// Telegraph the attack to players.
	for(var/mob/living/potential_victim in view(10, src))
		if(faction_check_mob(potential_victim, TRUE) || potential_victim.stat >= HARD_CRIT || z != potential_victim.z || (potential_victim.status_flags & GODMODE)) // Dead or in hard crit, insane, or on a different Z level.
			continue
		var/obj/effect/temp_visual/trash_disposal_telegraph/warning = new /obj/effect/temp_visual/trash_disposal_telegraph(get_turf(user))
		walk_towards(warning, potential_victim, 0.1 SECONDS) // This makes our warning move from the Matriarch to the target.

	say("+5363 23 625 513 93477 2576!+")
	user.visible_message(span_userdanger("[user] prepares to leap...!"))
	playsound(src, 'sound/abnormalities/crumbling/warning.ogg', 50, FALSE, 5)

	SLEEP_CHECK_DEATH(2.4 SECONDS)

	busy = FALSE
	lunging = TRUE // While this is active, anyone we get thrown into is fair game for Trash Disposal.
	user.throw_at(victim, 7, 5, src, FALSE)
	user.visible_message(span_danger("[user] leaps at [victim]!"))
	addtimer(CALLBACK(src, PROC_REF(StopLunging)), 2 SECONDS) // Failsafe - resets our state if we miss.

/// This proc is called once we successfully impact someone from our lunge. We pin them and begin the sequence of hits.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/TrashDisposalInitiate(mob/living/victim, mob/living/user = src)
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
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/TrashDisposalHit(mob/living/victim, mob/living/user = src, hit_count)
	pacified = TRUE
	// This do_after controls how fast the hits happen. It can fail if our position changes, or the victim's does.
	if(do_after(user, time_between_trash_disposal_hits, target = victim))
		user.do_attack_animation(victim)
		playsound(user, attack_sound, 100, TRUE)
		new /obj/effect/gibspawner/generic/trash_disposal(get_turf(victim))
		victim.deal_damage(phases_disposal_damage[phase], melee_damage_type)
		SweeperHealing(phases_disposal_healing[phase])
		user.visible_message(span_danger("[user] rips into [victim] and refuels themselves with \his blood!"))
		// Ramp up the speed on each hit.
		time_between_trash_disposal_hits -= 1
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
		if(hit_count >= 8)
			TrashDisposalCleanup(victim, user)
			return TRUE

		// If we reached here, then we weren't interrupted and we can keep hitting our target. Go again.
		INVOKE_ASYNC(src, PROC_REF(TrashDisposalHit), victim, user, hit_count + 1)
		return TRUE
	// We cancel if we didn't reach the early returns that were provided within the do_after.
	TrashDisposalCleanup(victim, user)
	return FALSE

/// This proc reverts the effects that Trash Disposal applied on us and our victim.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/TrashDisposalCleanup(mob/living/victim, mob/living/user = src)
	toggle_ai(AI_ON)
	busy = FALSE
	pacified = FALSE
	lunging = FALSE
	time_between_trash_disposal_hits = initial(time_between_trash_disposal_hits)

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
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/mob/living/what_did_we_just_hit = hit_atom
	// If we directly impacted a living mob that's not in our exact factions, start Trash Disposal on them.
	if(lunging && istype(what_did_we_just_hit) && !faction_check_mob(what_did_we_just_hit, TRUE))
		INVOKE_ASYNC(src, PROC_REF(TrashDisposalInitiate), what_did_we_just_hit, src)
		lunging = FALSE
		return
	// If we didn't directly impact a living mob, check the turf we landed on and look for them there. (People could otherwise dodge by going prone if we don't do this.)
	else if(lunging)
		var/turf/landing_zone = get_turf(src)
		for(var/mob/living/L in landing_zone)
			if(L == throwingdatum.target && !faction_check_mob(L, TRUE))
				INVOKE_ASYNC(src, PROC_REF(TrashDisposalInitiate), L, src)
				lunging = FALSE
				return

	// Failsafe in case we couldn't start our trash disposal.
	lunging = FALSE
	toggle_ai(AI_ON)
	busy = FALSE
	pacified = FALSE
	. = ..()

/// Failsafe proc in case we miss our throw entirely.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/StopLunging()
	lunging = FALSE
	busy = FALSE
	toggle_ai(AI_ON)

/obj/effect/sweeperspawn
	name = "bloodpool"
	desc = "A target warning you of incoming pain"
	icon = 'icons/effects/cult_effects.dmi'
	icon_state = "bloodin"
	move_force = INFINITY
	pull_force = INFINITY
	generic_canpass = FALSE
	movement_type = PHASING | FLYING
	layer = POINT_LAYER	//We want this HIGH. SUPER HIGH. We want it so that you can absolutely, guaranteed, see exactly what is about to hit you.

/obj/effect/sweeperspawn/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(spawnscout)), 6)

/obj/effect/sweeperspawn/proc/spawnscout()
	new /mob/living/simple_animal/hostile/ordeal/indigo_spawn(get_turf(src))
	qdel(src)

// We don't spawn these anymore but I'm keeping it here because one spawns in xicommand.dmm for some reason
/mob/living/simple_animal/hostile/ordeal/indigo_spawn
	name = "sweeper scout"
	desc = "A tall humanoid with a walking cane. It's wearing indigo armor."
	icon = 'ModularLobotomy/_Lobotomyicons/32x48.dmi'
	icon_state = "indigo_dawn"
	icon_living = "indigo_dawn"
	icon_dead = "indigo_dawn_dead"
	faction = list("indigo_ordeal")
	maxHealth = 110
	health = 110
	move_to_delay = 1.3	//Super fast, but squishy and weak.
	stat_attack = HARD_CRIT
	melee_damage_type = BLACK_DAMAGE
	melee_damage_lower = 21
	melee_damage_upper = 24
	attack_verb_continuous = "stabs"
	attack_verb_simple = "stab"
	attack_sound = 'sound/effects/ordeals/indigo/stab_1.ogg'
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 0.8)
	blood_volume = BLOOD_VOLUME_NORMAL

#undef COMBAT_ABILITY_DASH
#undef COMBAT_ABILITY_SLAM
#undef COMBAT_ABILITY_TRASH_DISPOSAL
#undef COMBAT_ABILITY_SLASH

#undef SUPPORT_ABILITY_OFFENSIVE
#undef SUPPORT_ABILITY_PERSISTENCE
#undef SUPPORT_ABILITY_SUMMON
