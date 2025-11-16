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
	gender = FEMALE
	icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
	icon_state = "matriarch"
	icon_living = "matriarch"
	icon_dead = "matriarch_dead"
	faction = list("indigo_ordeal")
	maxHealth = 7500
	health = 7500
	stat_attack = DEAD
	pixel_x = -16
	base_pixel_x = -16
	layer = ABOVE_MOB_LAYER // So goofballs like Red Hood don't render over her, also so she renders on top of whatever she pins with Disposal
	melee_damage_type = BLACK_DAMAGE
	move_to_delay = 3
	rapid_melee = 2
	melee_damage_lower = 55
	melee_damage_upper = 55
	butcher_results = list(/obj/item/food/meat/slab/sweeper = 4)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/sweeper = 3)
	attack_verb_continuous = "stabs"
	attack_verb_simple = "stab"
	attack_sound = 'sound/effects/ordeals/indigo/stab_1.ogg'
	damage_coeff = list(RED_DAMAGE = 0.3, WHITE_DAMAGE = 0.4, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 0.5)
	blood_volume = BLOOD_VOLUME_NORMAL
	move_resist = MOVE_FORCE_OVERPOWERING
	can_patrol = TRUE
	patrol_cooldown_time = 8 SECONDS
	offsets_pixel_x = list("south" = -16, "north" = -16, "west" = -16, "east" = -16)
	ranged = TRUE
	projectiletype = null
	simple_mob_flags = SILENCE_RANGED_MESSAGE

	/// How many non-sweeper corpses has she eaten? Boosts attack speed and movespeed.
	var/belly = 0

	/// Controls a ton of different parts of her balancing. This is a number from 1 to 3. If it isn't, something is horribly wrong.
	var/phase = 1

	// Player scaling vars.
	var/player_scaling = 1
	var/player_scaling_health_per_player = 300
	var/player_scaling_grunts_per_player = 1
	var/player_scaling_commanders_per_player = 0.34

	/// If we reach this amount of players, we will be spawning a ton of sweepers around the facility, not just as part of the Matriarch's retinue.
	// The sweepers spawned by this won't automatically come to the Matriarch's aid, they patrol with their own commanders.
	var/player_scaling_nitb_threshold = 4

	/// Holds the commanders we've deployed as part of the NitB
	var/list/nitb_deployed_commanders = list()

	var/nitb_cooldown = INFINITY
	var/nitb_cooldown_duration = 5 MINUTES

	/// List of all bound, spawned sweepers in our retinue
	var/list/allied_sweepers = list()
	/// List of just the bound retinue commanders
	var/list/deployed_commanders = list()
	/// List of just the bound retinue grunts
	var/list/deployed_grunts = list()

	/// Types of available commanders to spawn for our retinue. We will pick n take out of this list to avoid duplicates, we will replenish it when they die.
	var/list/retinue_commander_types = list(
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/retinue,
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white/retinue,
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black/retinue,
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale/retinue,
	)
	/// Types of available grunts to spawn for our retinue.
	var/list/retinue_grunt_types = list(
		/mob/living/simple_animal/hostile/ordeal/indigo_noon/retinue,
		/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky/retinue,
		/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky/retinue,
	)
	// Technically, we could get away with just using 1 list here and deriving how many commanders/grunts there are with a for loop and istype check, but I'd rather not?

	/// Types of commanders that can be spawned for the NitB player scaling mechanic. We are also gonna pick n take out of this one to avoid duplicates...
	// Mainly to avoid a situation where 3 Marias spawn and give the sweepers 0 move delay (lol)
	var/list/nitb_commander_types = list(
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red,
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white,
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black,
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale,
	)

	/* ABILITY VARIABLES SECTION
	!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	The Matriarch has access to some of her own abilities, and a bunch of upgraded abilities from her subordinates:
	Combat:
		- Sweep the Backstreets, a dash ability from Lanky Sweepers. This version has a larger AoE. On hit, heals and resets cooldown. At Phase 2 and later, has a followup AoE slam.
		- Ground Slam, her own ability. Deals RED damage instead of BLACK. Formerly, this checked for BLACK armour, but the germination of the seed of light requires you to suffer, so it checks for RED as normal.
		- Trash Disposal, a lunge from Commander Jacques (RED Indigo Dusk). This makes her leap at a target, and if her leap connects, she will pin them and repeatedly attack, dealing ramping damage and healing herself. Unlike Jacques', this will telegraph against all nearby targets, making it hard to tell who is the real target.
		- Slash, a simple AoE from Commander Adelheide (WHITE Indigo Dusk), who in turn stole it from Lady of the Lake. Added lifesteal. This is a simple, dodgeable slash, but its shape alternates between wide and long, and it repeats once after Phase 2.
		- Parry, a defensive ability from Commander Silvina (PALE Indigo Dusk), which prevents incoming damage and retaliates with a riposte, healing and lowering its own cooldown if it lands.

	Support:
		- Offensive Command, an ability from Commander Maria (BLACK Indigo Dusk). This makes all nearby allies move and attack faster and harder, making them appropiate threats for endgame.
		- Persistent Command, an ability from Commander Adelheide (WHITE Indigo Dusk). This gives all nearby allies three stacks of Persistence and resets their combat ability cooldowns.
		- Summon Sweepers, her own ability. It's self explanatory.  Will summon standard sweepers as well as variants. Later, able to also summon Indigo Dusks.
	*/

	/// Currently winding up an attack?
	var/preparing = FALSE

	/// Activate dashing behaviour (AoE, VFX, sound) while moving while this is TRUE.
	var/dashing = FALSE
	/// Currently lunging as part of Trash Disposal? Will initiate Trash Disposal on anyone she's thrown at while this is TRUE.
	var/lunging = FALSE
	/// Currently going to town on someone as part of Trash Disposal?
	var/disposing = FALSE
	/// Currently in the active phase of Parry? An incoming hit will result in a riposte while this is TRUE.
	var/parrying = FALSE
	/// This is TRUE while we're in the process of riposting, we'll not do any further ripostes on incoming attacks.
	var/riposting = FALSE
	/// Used to only riposte once per parry.
	var/riposte_used = FALSE

	// available_abilities holds the abilities the Matriarch is cleared to use as keys and their current cooldowns as values.
	var/list/available_abilities = list()
	// This one holds the intended cooldown duration for every ability.
	var/list/ability_cooldown_durations = list(
		COMBAT_ABILITY_DASH = 15 SECONDS, // Dash CD is reset on dash hit
		COMBAT_ABILITY_SLAM = 10 SECONDS,
		COMBAT_ABILITY_SLASH = 8 SECONDS,
		COMBAT_ABILITY_TRASH_DISPOSAL = 22 SECONDS,
		COMBAT_ABILITY_PARRY = 18 SECONDS, // Parry has CDR if a riposte lands
		SUPPORT_ABILITY_OFFENSIVE = 30 SECONDS,
		SUPPORT_ABILITY_PERSISTENCE = 20 SECONDS,
		SUPPORT_ABILITY_SUMMON = 80 SECONDS, // Summon CD is reset every phasechange. This also gets increased by 20s every time it gets used.
	)
	// These two lists, we will pick_n_take from to add abilities as the fight progresses. On Initialize we pluck three out of locked_combat_abilities to start with as a base.
	var/list/locked_combat_abilities = list(COMBAT_ABILITY_DASH, COMBAT_ABILITY_SLAM, COMBAT_ABILITY_SLASH, COMBAT_ABILITY_TRASH_DISPOSAL, COMBAT_ABILITY_PARRY)
	var/list/locked_support_abilities = list(SUPPORT_ABILITY_OFFENSIVE, SUPPORT_ABILITY_PERSISTENCE) // Summon is excluded, we have it by default.


	// Sweep the Backstreets (Dash) variables
	/// We need this to not hit multiple people due to the implementation I used for the dash. Stores every mob hit by the dash, cleared on each dash.
	var/list/dash_hitlist = list()
	/// This is also a hitlist but for turfs instead.
	var/list/dash_hitlist_turfs = list()
	var/dash_range = 7

	// Area Slash variables
	// Vars for the size of the slash combat ability. Taken from Lady of the Lake.
	// We will swap these every time we use the ability.
	var/slash_length = 3
	var/slash_width = 2

	// Parry & Riposte variables
	/// This var will hold the timer for our parry.
	var/parry_stop_timer = null
	/// Reduce Parry's CD by this much on a successful riposte.
	var/riposte_CDR = 14 SECONDS

	// Trash Disposal variables
	/// How many deciseconds between trash disposal hits? Reduced by 1 decisecond on each hit.
	var/time_between_trash_disposal_hits = 1 SECONDS
	/// A failsafe timer in case we miss our lunge, resets it.
	var/lunge_reset_timer

	// Buff (Frenzy & Persistence) variables
	/// Range in tiles of our buff abilities.
	var/buff_ability_range = 13
	// The below bonuses are flat and additive. They are applied on our offensive buff.
	/// Raise ally attack damage by this amount
	var/buff_melee_bonus = 6
	/// Lower ally move delay by this amount
	var/buff_movespeed_bonus = 0.8
	/// Raise ally rapid_melee by this amount
	var/buff_attackspeed_bonus = 1.2
	/// Buff lasts this long
	var/buff_duration = 12 SECONDS

	// You get a small breather in between her spamming support abilities.
	var/general_support_cooldown = 0
	var/general_support_cooldown_duration = 4.5 SECONDS

	// Frustration mechanic: if ranged attacks are being used on us, punish the players.
	// Formerly went off of hitcount, but this unfairly penalized fast firing guns while letting big war criminal guns like Arcadia get off easy.
	// Now goes off of the bullets' damage value multiplied by our coeff towards it.

	/// Ranged damage taken. Reset by RangedReaction().
	var/frustration_meter = 0
	/// Damage threshold over which we'll trigger a RangedReaction(). Increased by amount of players.
	var/frustration_threshold = 100
	/// Amount of times we've reached our frustration_threshold. The higher this gets, the more cooked you are.
	var/frustration_procced = 0

	var/pulse_cooldown
	var/pulse_cooldown_time = 8 SECONDS // This also controls the "window of opportunity" that you can use ranged on the Matriarch during before she'll punish you again for it
	var/pulse_base_damage = 50 // Scales off frustration procs.

	/* PHASE SCALING SECTION
	!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	*/
	// Big block of phases_ vars that determine what properties she has in each stage. I found this approach to be more useful for being able to compare and directly tweak the values in one place.
	// A general "rule" she follows, is that she gets more frantic and quick in her movements and attacks as the fight progresses, and heals more, but deals less damage and is more vulnerable.

	// Association list of key: phase to value: amount of health under which the next phase gets triggered.
	var/list/phases_health_thresholds = list(1 = 5000, 2 = 2800, 3 = -INFINITY)

	// The icons she uses in each phase.
	var/list/phases_icon_states = list(1 = "matriarch", 2 = "matriarch_slim", 3 = "matriarch_fast")

	// Association lists that control different balancing values for each phase. The keys are the phase, the values are the corresponding intended value for that phase.
	var/list/phases_move_delays = list(1 = 3, 2 = 2.6, 3 = 2.4)
	var/list/phases_rapid_melee = list(1 = 2, 2 = 3, 3 = 4)
	var/list/phases_melee_damage = list(1 = 55, 2 = 48, 3 = 40)
	var/list/phases_resistance_lists = list(
	1 = list(RED_DAMAGE = 0.3, WHITE_DAMAGE = 0.4, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 0.5),
	2 = list(RED_DAMAGE = 0.4, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 0.25, PALE_DAMAGE = 0.8),
	3 = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.3, PALE_DAMAGE = 1),
	)

	// Slam phase scaling variables
	var/list/phases_slam_windup = list(1 = 1.2 SECONDS, 2 = 0.9 SECONDS, 3 = 0.6 SECONDS)
	var/list/phases_slam_damage = list(1 = 120, 2 = 110, 3 = 80)
	var/list/phases_slam_range = list(1 = 3, 2 = 3, 3 = 2)

	// Slash phase scaling variables
	var/list/phases_slash_damage = list(1 = 110, 2 = 100, 3 = 90)
	var/list/phases_slash_healing = list(1 = 75, 2 = 100, 3 = 200)

	// Dash phase scaling variables
	var/list/phases_dash_windup = list(1 = 1.1 SECONDS, 2 = 0.9 SECONDS, 3 = 0.8 SECONDS)
	var/list/phases_dash_damage = list(1 = 80, 2 = 70, 3 = 60)
	var/list/phases_dash_healing = list(1 = 100, 2 = 150, 3 = 250)

	// Parry & Riposte scaling variables
	var/list/phases_riposte_damage = list(1 = 160, 2 = 150, 3 = 140)
	var/list/phases_riposte_healing = list(1 = 200, 2 = 300, 3 = 500)

	// Trash Disposal scaling variables
	var/list/phases_disposal_damage = list(1 = 60, 2 = 50, 3 = 40)
	var/list/phases_disposal_healing = list(1 = 75, 2 = 100, 3 = 150)

	// Summon Sweepers scaling variables
	var/list/phases_squad_size_grunts = list(1 = 6, 2 = 5, 3 = 4)
	var/list/phases_squad_size_commanders = list(1 = 2, 2 = 1, 3 = 0)

// Here be procs

/*
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
GENERAL OVERRIDES, PATROLLING AND TARGETING SECTION
This is all code relating to targeting corpses, patrolling and all of that. Includes a lot of important overrides like Life() and Move().
Some other overrides like AttackingTarget() are in the Combat section instead.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*/

/mob/living/simple_animal/hostile/ordeal/indigo_midnight/Initialize(mapload)
	. = ..()
	// Follow me if you want to live. All Sweeper types will be included in our Leadership component.
	var/units_to_add = list(
		/mob/living/simple_animal/hostile/ordeal/indigo_noon/retinue = 1,
		/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky/retinue = 1,
		/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky/retinue = 1,
		/mob/living/simple_animal/hostile/ordeal/indigo_dawn = 1,
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/retinue = 1,
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white/retinue = 1,
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black/retinue = 1,
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale/retinue = 1,
		)
	AddComponent(/datum/component/ai_leadership/matriarch, units_to_add, 50) // This leadership component has some special behaviour. Check near the bottom of the file to find it.
	nitb_cooldown = world.time + (nitb_cooldown_duration * 0.33)
	HandlePlayerScaling()

	// Give us three combat abilities and Summon Sweepers to begin with. We begin with half their cooldown ticked down.
	for(var/i in 1 to 3)
		var/chosen_combat_ability = pick_n_take(locked_combat_abilities)
		if(chosen_combat_ability)
			available_abilities[chosen_combat_ability] = world.time + ability_cooldown_durations[chosen_combat_ability] * 0.5
	available_abilities[SUPPORT_ABILITY_SUMMON] = world.time + ability_cooldown_durations[SUPPORT_ABILITY_SUMMON] * 0.5

// Called on Initialize() to update our stuff to right values for amount of players we're facing. Please never call this ever again
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/HandlePlayerScaling()
	var/amount_of_dangerous_fuel = length(AllLivingAgents(TRUE))
	player_scaling = amount_of_dangerous_fuel

	// Health scaling
	var/bonus_health = player_scaling_health_per_player * amount_of_dangerous_fuel
	maxHealth += bonus_health
	adjustBruteLoss(-bonus_health)
	for(var/i in 1 to 3)
		phases_health_thresholds[i] += bonus_health

	// Small amount of extra wiggle room for triggering her ranged retaliation for more players
	frustration_threshold += (bonus_health * 0.10)

	// If the boss is deemed too easy, break open the safety glass to unleash "retinue size player scaling" (at the moment, only NitB is affected by player scaling)

/mob/living/simple_animal/hostile/ordeal/indigo_midnight/Life()
	. = ..()
	if(!.) // Dead
		return FALSE
	if(CanAct() && health <= phases_health_thresholds[phase])
		PhaseChange()

/mob/living/simple_animal/hostile/ordeal/indigo_midnight/handle_automated_action()
	. = ..()
	if(lose_patience_timeout && !QDELETED(target) && AIStatus == AI_IDLE && patience_last_interaction + lose_patience_timeout < world.time)
		LosePatience() // She can, sometimes, have a target while idle but far away from her target, causing her to not patrol towards them.

	AttemptUseSupportAbility() // Try to use a support ability every once in a while. The proc we're calling checks if any are ready.
	NightInTheBackstreets() // This has a cooldown, don't worry. It will also only trigger if the player scaling's hit a certain amount.

/mob/living/simple_animal/hostile/ordeal/indigo_midnight/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	if(CanAct() && health <= phases_health_thresholds[phase])
		PhaseChange()

/mob/living/simple_animal/hostile/ordeal/indigo_midnight/Move(atom/newloc, dir, step_x, step_y)
	if(preparing || disposing || parrying || riposting) // You can't move during these. Never add lunging/dashing to this check, we kinda need to move during those
		return FALSE
	. = ..()

	// As we move while dashing, make some small_smoke vfx all around the Matriarch, play a sound, and hit everyone around us. Don't worry, the proc has a mob hitlist, there won't be any double hits.
	if(dashing)
		playsound(src, 'sound/effects/meteorimpact.ogg', 75, TRUE, 2, TRUE)
		dash_hitlist_turfs |= get_turf(newloc)
		SweepTheBackstreetsHit(get_turf(newloc))
		for(var/turf/T in view(1, newloc))
			if(!(T in dash_hitlist_turfs))
				dash_hitlist_turfs |= T // Okay I know |= automatically checks if it's already in the list, but I only want to render the small_smoke once per turf, I think the ifcheck is less expensive than actually creating a tempvisual, right?
				SweepTheBackstreetsHit(T)
				new /obj/effect/temp_visual/small_smoke/halfsecond(T)

/mob/living/simple_animal/hostile/ordeal/indigo_midnight/FindTarget(list/possible_targets, HasTargetsList)
	if(!CanAct())
		return null
	. = ..()

//Remind me to return to this and make complex targeting a option for all creatures. I may make it a TRUE FALSE var.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/ValueTarget(atom/target_thing)
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

//Stolen MOSB patrol code: modified.
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
		var/turf/the_promised_land = patrol_path[patrol_path.len] // Yes yes I know .len is bad but if I use length(patrol_path) here it runtimes. For some reason...?
		if(istype(the_promised_land))
			SEND_SIGNAL(src, COMSIG_PATROL_START, the_promised_land) // LET'S FUCKING GOOOOOOOOOOOOOO (this makes our leadership component tell our goons to come with us)
		return TRUE
	//unsure if this patrol reset will cause the patrol cooldown even if there is not patrol path.
	patrol_reset()
	return FALSE




/*
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FRUSTRATION & DEFENSE SECTION
This is all code relating to handling incoming damage.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*/

// Before we take damage: if we're parrying, and it's a parriable attack, deny the damage and parry the attack.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/PreDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	if(source)
		var/should_retaliate = !(attack_type & (ATTACK_TYPE_COUNTER | ATTACK_TYPE_ENVIRONMENT | ATTACK_TYPE_STATUS))
		if(should_retaliate && parrying && health > 0 && isliving(source))
			INVOKE_ASYNC(src, PROC_REF(Parry), source)
			return FALSE

// After we take damage: Consider turning on our parry if it's available, and tally any ranged damage to our frustration meter.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	if(source)
		var/should_retaliate = !(attack_type & (ATTACK_TYPE_COUNTER | ATTACK_TYPE_ENVIRONMENT | ATTACK_TYPE_STATUS))
		if(CanAct() && should_retaliate && . >= 25 && health > 0 && prob(75))
			INVOKE_ASYNC(src, PROC_REF(BeginParry))
		if(attack_type & ATTACK_TYPE_RANGED)
			// Frustration buildup.
			frustration_meter += (damage_amount) // PostDamageReaction's ..() is giving us the post-coeff damage amount

			if(frustration_meter >= frustration_threshold)
				INVOKE_ASYNC(src, PROC_REF(RangedReaction), source) // Punish players for using ranged on the Matriarch. This will also reset our frustration_meter

// She will do this after she's been shot for enough damage. You can get away with it a couple times but eventually she becomes way too much of an issue if you abuse ranged kiting on her.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/RangedReaction(mob/living/firer)
	if(pulse_cooldown > world.time)
		return FALSE
	frustration_meter = 0
	frustration_procced++
	audible_message(span_danger("[src] howls in frustration!"))
	visible_message(span_userdanger("It really doesn't seem like using ranged weaponry on her is a good idea..."))

	// Facility-wide AoE damage. Scales off amount of times it's happened. Clueless people on the other side of the facility will be mostly spared, there is distance dropoff.
	pulse_cooldown = world.time + pulse_cooldown_time
	var/pulse_scaled_damage = pulse_base_damage + (frustration_procced * 25) // This becomes a facility-wiping obliteration nuke if you spam ranged on her

	var/sound/sfx = sound('sound/weapons/resonator_blast.ogg')
	for(var/mob/living/L in urange(90, src))
		if(faction_check_mob(L, TRUE))
			continue
		SEND_SOUND(L, sfx)

		var/distance = round(get_dist(src, L))
		var/final_damage = max((pulse_scaled_damage - (distance * 2)), (frustration_procced * 20))
		L.deal_damage(final_damage, BLACK_DAMAGE, source = src, attack_type = (ATTACK_TYPE_SPECIAL))
		shake_camera(L, 4, 5)
		to_chat(L, span_userdanger("A piercing howl corrodes your very being!"))

	// Increase our squad size each time this procs.
	for(var/i in 1 to 3)
		phases_squad_size_grunts[i] += 1

	if(frustration_procced % 4 == 0) // Every 4th proc of this...
		for(var/j in 1 to 3)
			phases_squad_size_commanders[j] += 1 // We won't ever have more than 4 Commanders, since each one is unique. Well, we could, if I wanted to... but it feels weird.

	SLEEP_CHECK_DEATH(0.5 SECONDS)

	if(CanAct() && istype(firer) && (available_abilities[COMBAT_ABILITY_DASH] != null))
		INVOKE_ASYNC(src, PROC_REF(SweepTheBackstreets), firer) // If we have our dash unlocked, use it immediately regardless of cooldown. This will only happen if we're not busy doing something else.
	return

/*
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
PHASE SECTION
This is all code relating to handling phase changes.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*/

/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/PhaseChange()
	preparing = TRUE
	// Warn players of the phase change.
	icon_state = "phasechange"
	SLEEP_CHECK_DEATH(5)

	// Our max hp is now capped at the max health threshold that got passed to enter this phase.
	phase++
	maxHealth = phases_health_thresholds[phase-1]
	adjustBruteLoss(-INFINITY, TRUE, TRUE) // Brute loss needs to be reset, just trust me on this one I think

	// This is the bulk of the stat changes. She moves faster, attacks faster, but deals less damage.
	ChangeResistances(phases_resistance_lists[phase])

	UpdateBellyScaling() // Updates our movetodelay and rapid_melee. Factors in corpses eaten.

	melee_damage_lower = phases_melee_damage[phase]
	melee_damage_upper = phases_melee_damage[phase]
	icon_state = phases_icon_states[phase]
	icon_living = phases_icon_states[phase]

	// Gain a new combat ability and support ability. Immediately available.
	var/new_combat_ability = pick_n_take(locked_combat_abilities)
	if(new_combat_ability)
		available_abilities[new_combat_ability] = world.time
	var/new_support_ability = pick_n_take(locked_support_abilities)
	if(new_support_ability)
		available_abilities[new_support_ability] = world.time

	available_abilities[SUPPORT_ABILITY_SUMMON] = world.time // Reset cooldown on Summon.

	if(phase == 3)
		ability_cooldown_durations[COMBAT_ABILITY_DASH] *= 0.5 // Dash more often at phase 3 because it's funny

	preparing = FALSE

/*
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
COMBAT SECTION
This is all code relating to Matriarch's combat abilities and auxiliary stuff for combat.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*/

// !!! CanAct as a proc rather than a var: She has so many possible states she can be in, that it's more expedient to check if she should be able to do something in a proc !!!
// You may be wondering by this point WHY we have all these different states she can be in. The thing is, we can't have one of the combat abilities' "cleanup" procs un-busy us while we're supposed to be winding something up.
// If we just have one generic can_act variable, some really messed up stuff can happen and she can lock you in a 50 hit DMC air juggle combo out of trash disposal. Just trust me on this one.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/CanAct()
	return !(preparing || lunging || parrying || riposting || dashing || disposing)

// !!! Melee attack override: Basis of how we call most of our attacks. !!!
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/AttackingTarget(atom/attacked_target)
	if(!CanAct())
		return FALSE

	var/mob/living/attacked_living = attacked_target
	if(istype(attacked_living) && attacked_living.stat < DEAD && AttemptUseCombatAbility(attacked_target)) // If we can use one of our combat abilities, do that instead of an autoattack.
		return FALSE

	. = ..() // We have autoattacked our target.

	if(. && attacked_living) // Devour them if they're mob/living and they're dead.
		var/mob/living/L = attacked_target
		if(L.stat != DEAD)
			if(L.health <= HEALTH_THRESHOLD_DEAD && HAS_TRAIT(L, TRAIT_NODEATH))
				SweeperDevour(L)
		else
			SweeperDevour(L)

// !!! OpenFire override: This is how we use our lunge or our dash at range. !!!
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/OpenFire(atom/A)
	if(!CanAct())
		return FALSE
	var/mob/living/victim = A
	if(!(istype(A)))
		return FALSE

	// Prioritize using our dash at range, since Trash Disposal is less likely to land (and more importantly, our dash can go through friendlies).
	if(get_dist(src, victim) < 6 && (available_abilities[COMBAT_ABILITY_DASH] != null) && (available_abilities[COMBAT_ABILITY_DASH] <= world.time) && prob(60)) // Will only use our dash 60% of the time that it's off cooldown and we check this proc
		INVOKE_ASYNC(src, PROC_REF(SweepTheBackstreets), victim)
		return
	else if(get_dist(src, victim) < 8 && (available_abilities[COMBAT_ABILITY_TRASH_DISPOSAL] != null) && (available_abilities[COMBAT_ABILITY_TRASH_DISPOSAL] <= world.time) && prob(40)) // Will use our disposal 40% of the time that it's off CD and we didn't dash instead
		INVOKE_ASYNC(src, PROC_REF(TrashDisposalTelegraph), victim)
		return

// !!! This proc handles casting our combat abilities, prioritizing Disposal>Dash>Slam>Slash. It is called from melee attacks. !!!
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/AttemptUseCombatAbility(mob/living/victim)
	if(!CanAct())
		return FALSE
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
	var/devoured_is_human = ishuman(L)
	if(!L)
		return FALSE
	if(devoured_is_human && (SSmaptype.maptype in SSmaptype.citymaps))
		return FALSE
	visible_message(span_danger("[src] devours [L]!"), span_userdanger("You feast on [L], restoring your health!"))

	// Feeding on a non human will recover health by 10% of the corpse's max hp.
	if(!devoured_is_human)
		SweeperHealing(L.maxHealth*0.1)
	// Feeding on a human will give us 40% of our max health, capped at a flat 1500, and increase belly scaling.
	else
		SweeperHealing(min(maxHealth * 0.4), 1500)
		belly++
		UpdateBellyScaling()
	L.gib()
	return TRUE

// Called every time we phasechange or devour someone, to correctly apply scaling based on human corpses eaten.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/UpdateBellyScaling()
	// Attack and move faster for each corpse eaten, scales up to 5 corpses. We gain 0.2 rapid melee and lose 0.1 move delay per corpse. This can get pretty wild pretty fast.
	var/extra_speed = clamp(belly, 1, 5)
	extra_speed *= 0.1
	ChangeMoveToDelay(phases_move_delays[phase] - extra_speed)
	rapid_melee = (phases_rapid_melee[phase] + (extra_speed * 2))

// !!! Combat ability: Ground Slam. !!!
/// cannibalized from wendigo
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/AttackGroundSlam(range)
	if(!CanAct())
		return FALSE

	preparing = TRUE
	available_abilities[COMBAT_ABILITY_SLAM] = ability_cooldown_durations[COMBAT_ABILITY_SLAM] + world.time

	for(var/turf/W in range(range, src))
		new /obj/effect/temp_visual/guardian/phase(W)
	sleep(phases_slam_windup[phase])
	var/turf/orgin = get_turf(src)
	var/list/all_turfs = RANGE_TURFS(range, orgin)
	var/list/hit_list = list()
	for(var/i = 0 to range)
		for(var/turf/T in all_turfs)
			if(get_dist(orgin, T) > i)
				continue
			playsound(T,'sound/effects/bamf.ogg', 60, TRUE, 10)
			new /obj/effect/temp_visual/small_smoke/halfsecond(T)
			for(var/mob/living/L in T)
				if((L == src) || (L in hit_list) || (L.throwing) || (faction_check_mob(L, TRUE)))
					continue
				hit_list |= L
				to_chat(L, span_userdanger("[src]'s ground slam shockwave sends you flying!"))
				var/turf/thrownat = get_ranged_target_turf_direct(src, L, 8, rand(-10, 10))
				L.throw_at(thrownat, 8, 2, src, TRUE, force = MOVE_FORCE_OVERPOWERING)
				L.deal_damage(phases_slam_damage[phase], RED_DAMAGE)
				shake_camera(L, 2, 1)
			all_turfs -= T
		sleep(1)
	preparing = FALSE

// !!! Combat ability: Sweep the Backstreets (dash). !!!
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/SweepTheBackstreets(atom/prospective_fuel = target)
	if(stat >= DEAD || !CanAct())
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
	var/obj/effect/temp_visual/dragon_swoop/bubblegum/matriarch/telegraph = new(dash_start_turf)
	walk_towards(telegraph, dash_target_turf, 0.1 SECONDS)
	SLEEP_CHECK_DEATH(phases_dash_windup[phase])
	/// We're now dashing.
	BeginDash()
	walk_towards(src, dash_target_turf, 0.2)
	SLEEP_CHECK_DEATH(get_dist(src, dash_target_turf) * 0.2)

	/// Yes it needs to get slept for 0.2 seconds here because... it hasn't finished moving or something. I've tested it. Trust me.
	SLEEP_CHECK_DEATH(0.2 SECONDS)
	CancelDash()

	walk(src, 0)

	// Followup slam on phase 2 and after.
	if(phase >= 2)
		var/list/followup_hitlist = list()
		SLEEP_CHECK_DEATH(0.1 SECONDS)
		for(var/turf/T in view(2, src))
			playsound(T,'sound/effects/tableslam.ogg', 100, TRUE, 10)
			new /obj/effect/temp_visual/smash_effect(T)
			for(var/mob/living/L in T)
				if((L == src) || (L in followup_hitlist) || (L.throwing) || (faction_check_mob(L, TRUE)))
					continue
				followup_hitlist |= L
				to_chat(L, span_userdanger("[src]'s follow-up slam sends you flying!"))
				var/turf/thrownat = get_ranged_target_turf_direct(src, L, 8, rand(-10, 10))
				L.throw_at(thrownat, 8, 2, src, TRUE, force = MOVE_FORCE_OVERPOWERING, gentle = TRUE)
				L.deal_damage(phases_slam_damage[phase], RED_DAMAGE)
				shake_camera(L, 2, 1)

	/// Give the players a tiny bit of time to not instantly get auto hit by the Matriarch after she dashes.
	SLEEP_CHECK_DEATH(0.2 SECONDS)

	preparing = FALSE
	return TRUE

/obj/effect/temp_visual/dragon_swoop/bubblegum/matriarch
	duration = 0.9 SECONDS
	layer = POINT_LAYER
	movement_type = FLYING | PHASING

/// This proc deals damage to the things we dash through. Called by Move() while we're dashing.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/SweepTheBackstreetsHit(turf/impacted)
	if(istype(impacted))
		for(var/mob/living/hit_mob in HurtInTurf(impacted, dash_hitlist, phases_dash_damage[phase], melee_damage_type, check_faction = TRUE, exact_faction_match = TRUE, hurt_mechs = TRUE, hurt_structure = TRUE))
			if(hit_mob.stat >= DEAD)
				continue
			to_chat(hit_mob, span_userdanger("[src] viciously slashes you as she dashes past!"))
			playsound(hit_mob, attack_sound, 100)

			SpawnAppropiateGibs(hit_mob) // This will end up creating a lot of gibs throughout the fight. Ideally we should implement a way for gibs to "merge" so we don't end up with 20 on the same tile.

			if(ishuman(hit_mob))
				available_abilities[COMBAT_ABILITY_DASH] = world.time // Cooldown reset if a human gets hit. This used to be ANY mob but it's extremely cruel to let her full heal off LRRHM or similar

			// Big slice VFX
			var/obj/effect/temp_visual/dir_setting/slash/temp = new(impacted)
			temp.dir = dir
			temp.transform = temp.transform * 2.5
			temp.color = COLOR_RED

			if(hit_mob.mob_biotypes & MOB_ORGANIC)
				SweeperHealing(phases_dash_healing[phase])

/// Called when we're entering a dash (passed all the checks).
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/PrepareDash()
	walk_to(src, 0)
	preparing = TRUE
	dashing = FALSE
	/// Can't get pushed away during this.
	anchored = TRUE
	/// Reset our hit lists.
	dash_hitlist = list()
	dash_hitlist_turfs = list()

/// Called to begin dashing properly.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/BeginDash()
	preparing = FALSE
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
	anchored = FALSE
	pass_flags = initial(pass_flags)
	density = TRUE

// !!! Combat ability: Slash. !!!
// Copied code from the Lady of the Lake (Gold Noon). It's an AoE slash.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/AreaSlash(mob/living/target, mob/living/user, repeat = TRUE)
	if(!CanAct())
		return FALSE
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

	// Set our cooldown once we reach this point.
	available_abilities[COMBAT_ABILITY_SLASH] = ability_cooldown_durations[COMBAT_ABILITY_SLASH] + world.time

	// This is where the actual slash telegraph and hit happen.
	preparing = TRUE
	dir = dir_to_target
	playsound(get_turf(src), 'sound/weapons/fixer/generic/sheath2.ogg', 75, 0, 5)
	for(var/turf/T in area_of_effect)
		new /obj/effect/temp_visual/sparkles/matriarch(T)

	visible_message(span_danger("[src] raises her claws...!"))
	SLEEP_CHECK_DEATH(0.8 SECONDS)
	playsound(get_turf(src), 'sound/weapons/fixer/generic/blade3.ogg', 100, 0, 5)
	for(var/turf/T in area_of_effect)
		var/obj/effect/temp_visual/slice/pretty_sliced_up = new(T)
		pretty_sliced_up.color = COLOR_RED
		for(var/mob/living/L in T)
			if(faction_check_mob(L, TRUE))
				continue
			if (L == src)
				continue

			L.deal_damage(phases_slash_damage[phase], melee_damage_type)
			// Big slice VFX
			var/obj/effect/temp_visual/saw_effect/temp = new (T)
			temp.transform = temp.transform * 1.25
			temp.color = COLOR_RED

			SpawnAppropiateGibs(L)
			playsound(T, attack_sound, 100, FALSE)
			SweeperHealing(phases_slash_healing[phase])

	SLEEP_CHECK_DEATH(0.2 SECONDS)
	preparing = FALSE

	var/old_length = slash_length
	slash_length = slash_width
	slash_width = old_length

	// On phase 2 and 3, we will use this proc twice in a row.
	if(repeat && (phase >= 2) && target)
		INVOKE_ASYNC(src, PROC_REF(AreaSlash), target, user, FALSE)
		return TRUE

	return TRUE

/obj/effect/temp_visual/sparkles/matriarch
	duration = 0.8 SECONDS
	color = COLOR_STRONG_BLUE

// !!! Combat ability: Parry !!!
// Replace the current triggers with a PreDamageReaction() once damage refactor is merged. Will also let us parry special attacks.

/// Enter our parrying stance.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/BeginParry()
	if((available_abilities[COMBAT_ABILITY_PARRY] != null) && available_abilities[COMBAT_ABILITY_PARRY] <= world.time)
		// Set cooldown.
		available_abilities[COMBAT_ABILITY_PARRY] = ability_cooldown_durations[COMBAT_ABILITY_PARRY] + world.time

		preparing = TRUE // This doesn't mean we're parrying just yet.
		riposte_used = FALSE // Reset from previous uses.

		// Telegraph that we're beginning a parry to give players time to stop attacking. We're not actively parrying at this point.
		say("676 3246!!")
		visible_message(span_userdanger("[src] enters a parrying stance!"))
		var/atom/temp = new /obj/effect/temp_visual/markedfordeath(get_turf(src))
		temp.pixel_y += 48
		temp.layer = POINT_LAYER
		temp.transform *= 1.5
		playsound(src, 'sound/abnormalities/crumbling/warning.ogg', 50, FALSE, 3)
		animate(src, 0.4 SECONDS, color = COLOR_RED)
		SLEEP_CHECK_DEATH(0.7 SECONDS)
		// Now we actually enter our parry stance.
		parrying = TRUE
		preparing = FALSE
		parry_stop_timer = addtimer(CALLBACK(src, PROC_REF(StopParrying)), 1.1 SECONDS, TIMER_STOPPABLE)

/// This proc is called after successfully parrying, or after the timer runs out on our parry stance. It undoes all our changes from going into parry.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/StopParrying(success = FALSE)
	parrying = FALSE
	if(!success)
		visible_message(span_danger("[src] lowers \his defensive stance."))
	animate(src, 0.5 SECONDS, color = initial(color))

/// Proc that gets called every time we're hit in our parrying stance. Will riposte if possible.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/Parry(mob/living/victim)
	// Indicate that we landed a parry.
	face_atom(victim)
	var/datum/effect_system/spark_spread/parry_sparks = new /datum/effect_system/spark_spread
	parry_sparks.set_up(4, 0, loc)
	parry_sparks.start()
	playsound(src, 'sound/weapons/parry.ogg', 100, FALSE, 5)

	if((!riposte_used) && (!dashing && !disposing && !preparing) && (can_see(src, victim, 14)))
		riposte_used = TRUE
		ParryCounter(victim)

/// This gets called if someone hits us in our parrying stance. Retaliate by teleporting through them and attacking. We'll heal a bit too.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/ParryCounter(mob/living/victim)
	if(dashing || lunging)
		return FALSE

	riposting = TRUE

	var/riposte_damage = phases_riposte_damage[phase]
	if(istype(victim, /mob/living/simple_animal/hostile))
		riposte_damage *= 3 // Triple damage if we're riposting an ordeal, distortion or abno.

	SLEEP_CHECK_DEATH(0.2 SECONDS)

	// Teleport to the target and add a visual demonstrating it.
	var/turf/destination_turf = get_ranged_target_turf_direct(src, victim, get_dist(src, victim) + 1)
	var/turf/origin = get_turf(src)
	src.forceMove(destination_turf)
	var/datum/beam/really_temporary_beam = origin.Beam(src, icon_state = "1-full", time = 3)
	really_temporary_beam.visuals.color = COLOR_RED

	riposting = FALSE

	// Hit the target.
	src.do_attack_animation(victim)
	playsound(src, 'sound/abnormalities/crumbling/attack.ogg', 75, FALSE)
	victim.deal_damage(riposte_damage, melee_damage_type)
	SpawnAppropiateGibs(victim)
	visible_message(span_userdanger("[src] deflects [victim]'s attack and performs a counter!"))
	if(victim.mob_biotypes & MOB_ORGANIC)
		SweeperHealing(phases_riposte_healing[phase])

	// CDR. Shouldn't have hit us...!!!!!!!!!!!!!!
	available_abilities[COMBAT_ABILITY_PARRY] -= riposte_CDR


// !!! Combat ability: Trash Disposal !!!
/// First part of Trash Disposal. It CAN fail. Warns all nearby players they're about to get lunged at, then throws the Matriarch at one.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/TrashDisposalTelegraph(mob/living/victim, mob/living/user = src)
	preparing = TRUE
	available_abilities[COMBAT_ABILITY_TRASH_DISPOSAL] = ability_cooldown_durations[COMBAT_ABILITY_TRASH_DISPOSAL] + world.time
	toggle_ai(AI_OFF)
	LoseTarget()
	walk_to(src, 0) // Resets any ongoing movement
	var/true_target = victim

	// Telegraph the attack to players.
	for(var/mob/living/potential_victim in view(10, src))
		if(faction_check_mob(potential_victim, TRUE) || potential_victim.stat >= HARD_CRIT || z != potential_victim.z || (potential_victim.status_flags & GODMODE)) // Dead or in hard crit, insane, or on a different Z level.
			continue
		var/obj/effect/temp_visual/trash_disposal_telegraph/warning = new /obj/effect/temp_visual/trash_disposal_telegraph(get_turf(user))
		walk_towards(warning, potential_victim, 0.1 SECONDS) // This makes our warning move from the Matriarch to the target.
		if(prob(33))
			true_target = potential_victim // This should roughly shuffle our true target, maybe, I don't know, it's 3 AM I'm sleepy. I don't wanna pull all the possible victims and pick()

	say("+5363 23 625 513 93477 2576!+")
	user.visible_message(span_userdanger("[user] prepares to leap...!"))
	playsound(src, 'sound/abnormalities/crumbling/warning.ogg', 50, FALSE, 5)

	SLEEP_CHECK_DEATH(2.4 SECONDS) // You should run

	lunging = TRUE // While this is active, anyone we get thrown into is fair game for Trash Disposal.
	preparing = FALSE
	user.throw_at(true_target, 8, 5, src, FALSE)
	user.visible_message(span_danger("[user] leaps at [true_target]!"))
	lunge_reset_timer = addtimer(CALLBACK(src, PROC_REF(StopLunging)), 2 SECONDS, TIMER_STOPPABLE) // Failsafe - resets our state if we miss.

/// This proc is called once we successfully impact someone from our lunge. We pin them and begin the sequence of hits.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/TrashDisposalInitiate(mob/living/victim, mob/living/user = src)
	lunging = FALSE
	deltimer(lunge_reset_timer)

	if(victim)
		disposing = TRUE
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
	disposing = TRUE
	// This do_after controls how fast the hits happen. It can fail if our position changes, or the victim's does.
	if(do_after(user, time_between_trash_disposal_hits, target = victim))
		user.do_attack_animation(victim)
		playsound(user, attack_sound, 100, TRUE)
		SpawnAppropiateGibs(victim)
		victim.deal_damage(phases_disposal_damage[phase], melee_damage_type)
		SweeperHealing(phases_disposal_healing[phase])
		user.visible_message(span_danger("[user] rips into [victim] and refuels herself with [victim.p_their()] blood!"))
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
	disposing = FALSE
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
	disposing = FALSE
	. = ..()

/// Failsafe proc in case we miss our throw entirely.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/StopLunging()
	lunging = FALSE
	disposing = FALSE
	toggle_ai(AI_ON)

/*
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUPPORT SECTION
This is all code relating to Matriarch's support abilities and sweeper summoning.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*/

// !!! Gets called once in a while by handle_automated_action. Tries to use one of our support abilities, if ready and it makes sense to. !!!
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/AttemptUseSupportAbility()
	if(general_support_cooldown > world.time) // This is so we don't spam the buffs super quickly
		return FALSE

	// First, figure out how many sweepers we have and how many we /could/ have.
	var/amount_grunts = length(deployed_grunts)
	var/amount_commanders = length(deployed_commanders)

	var/missing_grunts = phases_squad_size_grunts[phase] - amount_grunts
	var/missing_commanders = phases_squad_size_commanders[phase] - amount_commanders

	// This will be TRUE if we're missing a commander or if we're missing four grunts. In that case, we'll try to summon some allies.
	var/really_oughta_get_some_goons = ((missing_grunts >= 4) || ((missing_commanders >= 1) && length(retinue_commander_types) > 0)) // Summon sweepers only if missing >=1 Commander or >=4 Grunts

	if(really_oughta_get_some_goons && (available_abilities[SUPPORT_ABILITY_SUMMON] != null) && available_abilities[SUPPORT_ABILITY_SUMMON] <= world.time)
		available_abilities[SUPPORT_ABILITY_SUMMON] = world.time + ability_cooldown_durations[SUPPORT_ABILITY_SUMMON]
		ability_cooldown_durations[SUPPORT_ABILITY_SUMMON] += 20 SECONDS // Every time she uses it, it takes a bit longer to use the next time. Still gets reset by phase change.
		var/turf/spawn_here = get_ranged_target_turf(src, pick(GLOB.cardinals), 2)
		INVOKE_ASYNC(src, PROC_REF(SummonSweepers), missing_grunts, missing_commanders, spawn_here)
		general_support_cooldown = world.time + general_support_cooldown_duration
		audible_message(span_userdanger("[src] calls for reinforcements!"))
		return TRUE

	// If we have deployed allies, and we're in combat, use one of our buff abilities.
	else if(target && (amount_grunts > 0 || amount_commanders > 0))
		// Frenzy is prioritized.
		if((available_abilities[SUPPORT_ABILITY_OFFENSIVE] != null) && available_abilities[SUPPORT_ABILITY_OFFENSIVE] <= world.time)
			available_abilities[SUPPORT_ABILITY_OFFENSIVE] = world.time + ability_cooldown_durations[SUPPORT_ABILITY_OFFENSIVE]
			INVOKE_ASYNC(src, PROC_REF(ActivateBuff), SUPPORT_ABILITY_OFFENSIVE)
			general_support_cooldown = world.time + general_support_cooldown_duration
			return TRUE

		// Persistence otherwise.
		else if((available_abilities[SUPPORT_ABILITY_PERSISTENCE] != null) && available_abilities[SUPPORT_ABILITY_PERSISTENCE] <= world.time)
			available_abilities[SUPPORT_ABILITY_PERSISTENCE] = world.time + ability_cooldown_durations[SUPPORT_ABILITY_PERSISTENCE]
			INVOKE_ASYNC(src, PROC_REF(ActivateBuff), SUPPORT_ABILITY_PERSISTENCE)
			general_support_cooldown = world.time + general_support_cooldown_duration
			return TRUE
		else
			return FALSE
	else
		return FALSE

/// This proc summons as many grunts and commanders as you ask it to at the turf "emergence". It will not check if we have the capacity for them. That is handled by AttemptUseSupportAbility.
// This sleeps so never call it directly, use INVOKE_ASYNC
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/SummonSweepers(amount_grunts, amount_commanders, turf/emergence)
	var/turf/open/prospective_turf = emergence
	if(!(istype(prospective_turf)))
		prospective_turf = get_turf(src)

	var/list/deployment_turfs = list()
	for(var/turf/T in view(1, prospective_turf))
		if(istype(T, /turf/closed/indestructible/fakeglass)) // If we're near an indestructible window, forget about fancy deployment, we're all spawning on the Matriarch's turf
			deployment_turfs = list()
			prospective_turf = get_turf(src)
			break
		deployment_turfs |= T

	new /obj/effect/temp_visual/sweeper_squad_warning(prospective_turf)
	sleep(3 SECONDS) // Not sleep_check_death, I don't care if you kill the matriarch, you're gonna deal with the GOONS

	if(amount_commanders > 0)
		for(var/i in 1 to amount_commanders)
			var/turf/final_deployment_turf = pick_n_take(deployment_turfs)
			if(!final_deployment_turf)
				final_deployment_turf = prospective_turf

			var/commander_type = pick_n_take(retinue_commander_types) // We will place their type back into the available pool once they die
			new /obj/effect/specific_sweeper_spawn(final_deployment_turf, commander_type, src)

	if(amount_grunts > 0)
		for(var/i in 1 to amount_grunts)
			var/turf/final_deployment_turf = pick_n_take(deployment_turfs)
			if(!final_deployment_turf)
				final_deployment_turf = prospective_turf

			var/grunt_type = pick(retinue_grunt_types)
			new /obj/effect/specific_sweeper_spawn(final_deployment_turf, grunt_type, src)


/// Only called if we meet player_scaling_nitb_threshold
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/NightInTheBackstreets()
	if(player_scaling < player_scaling_nitb_threshold || nitb_cooldown > world.time)
		return FALSE

	// Stop her from trying to do NitB if she's not on the facility Z Level
	var/turf/sample_dept_center = pick(GLOB.department_centers)
	var/turf/our_turf = get_turf(src)
	if(!(sample_dept_center) || (our_turf.z != sample_dept_center.z))
		return FALSE

	// If we have enough players, spawn Sweepers with a commander in a department center. They won't be bound to the Matriarch, but will still be part of the Ordeal.
	// No limit on how many grunts there could be, by the way. As long as we need to spawn a NITB Commander, we spawn 'em.

	var/required_amount_nitb_commanders = clamp(floor(player_scaling * player_scaling_commanders_per_player), 0, 4)
	var/missing_commanders = required_amount_nitb_commanders - length(nitb_deployed_commanders)
	if(missing_commanders < 1)
		return

	nitb_cooldown = world.time + nitb_cooldown_duration
	audible_message(span_userdanger("You hear a distant clamour as more Sweepers arrive in the facility."))
	var/list/cloned_dept_centers = GLOB.department_centers.Copy()

	for(var/i in 1 to missing_commanders)
		var/nitb_commander_type = pick_n_take(nitb_commander_types)
		if(!nitb_commander_type)
			return // yeowch! out of commanders! we'd have to dupe one... nuh uh

		var/turf/dept_center = pick_n_take(cloned_dept_centers)
		if(!dept_center)
			return // ????????????

		var/nitb_grunts_amount = floor(player_scaling * player_scaling_grunts_per_player)
		var/list/nitb_deployment_turfs = list()

		for(var/turf/open/T2 in view(2, dept_center))
			nitb_deployment_turfs |= T2

		new /obj/effect/temp_visual/sweeper_squad_warning(dept_center)

		for(var/j in 1 to nitb_grunts_amount)
			var/turf/final_nitb_deploy_turf = pick_n_take(nitb_deployment_turfs)
			if(!final_nitb_deploy_turf)
				final_nitb_deploy_turf = dept_center

			var/nitb_grunt_type = pick(list(
				/mob/living/simple_animal/hostile/ordeal/indigo_noon,
				/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky,
				/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky,
			))
			new /obj/effect/specific_sweeper_spawn(final_nitb_deploy_turf, nitb_grunt_type, src, FALSE)

		new /obj/effect/specific_sweeper_spawn(dept_center, nitb_commander_type, src, FALSE)

/// Signal handler that will remove the dead sweeper from our lists, and also place a dead commander's type back into the available pool.
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/RegisterSweeperDeath(mob/living/dead_neighbor)
	SIGNAL_HANDLER
	var/dead_type = dead_neighbor.type
	if(ispath(dead_type, /mob/living/simple_animal/hostile/ordeal/indigo_dusk))
		if(!(dead_neighbor in nitb_deployed_commanders))
			retinue_commander_types |= dead_type
		else
			nitb_commander_types |= dead_type

	deployed_commanders -= dead_neighbor
	nitb_deployed_commanders -= dead_neighbor
	deployed_grunts -= dead_neighbor
	allied_sweepers -= dead_neighbor


// !!! Support abilities: Frenzy / Persistence !!!
/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/ActivateBuff(buff_type = null)
	if((buff_type != SUPPORT_ABILITY_OFFENSIVE) && (buff_type != SUPPORT_ABILITY_PERSISTENCE))
		return FALSE

	say("296 9246 8572!!")
	audible_message(span_danger("[src] issues a command to \his children, rallying them to fight for \him!"))
	var/obj/effect/temp_visual/screech/command = new(get_turf(src))
	command.color = (buff_type == SUPPORT_ABILITY_OFFENSIVE ? COLOR_BLACK : COLOR_WHITE)

	var/datum/component/ai_leadership/matriarch/bond_of_motherhood = GetComponent(/datum/component/ai_leadership/matriarch)
	bond_of_motherhood.HeadCount(src) // Calls allied sweepers to the Matriarch.

	for(var/turf/T in range(buff_ability_range, src))
		for(var/mob/living/simple_animal/hostile/ordeal/goon in T)
			// Apply the buff only to people who are: 1. Not us, 2. In our faction
			if(src != goon && faction_check_mob(goon, TRUE))
				switch(buff_type)
					if(SUPPORT_ABILITY_OFFENSIVE)
						ApplyFrenzyBonus(goon) // This can stack with Maria's and it's very funny (war crime)
						addtimer(CALLBACK(src, PROC_REF(RevertFrenzyBonus), goon), buff_duration)

					if(SUPPORT_ABILITY_PERSISTENCE)
						goon.GainPersistence(2) // Nanomachines, son. They harden in response to physical trauma...

						// Resets combat ability cooldowns for Indigo Noon & Dusk allies.
						switch(goon.type)
							if(/mob/living/simple_animal/hostile/ordeal/indigo_dusk) // Commanders - Reset CD on Trash Disposal (Jacques), Hammer Slam (Maria), Parry (Silvina), Slash (Adelheide)
								var/mob/living/simple_animal/hostile/ordeal/indigo_dusk/favourite_child = goon
								favourite_child.special_ability_cooldown = world.time
							if(/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky) // Lanky Sweepers - Reset CD on Sweep the Backstreets (the dash)
								var/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky/beanstalk_lookin_guy = goon
								beanstalk_lookin_guy.dash_cooldown = world.time
							if(/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky) // Chunky Sweepers - Reset CD on Extract Fuel (the empowered lifesteal attack after being hit)
								var/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky/stocky_one = goon
								stocky_one.extract_fuel_cooldown = world.time


/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/ApplyFrenzyBonus(mob/living/simple_animal/hostile/neighbor)
	var/prev_color = neighbor.color
	neighbor.rapid_melee += buff_attackspeed_bonus
	neighbor.ChangeMoveToDelay(neighbor.move_to_delay - buff_movespeed_bonus)
	neighbor.melee_damage_lower += buff_melee_bonus
	neighbor.melee_damage_upper += buff_melee_bonus
	animate(neighbor, time = 0.7 SECONDS, color = "#1a1717")
	animate(time = 1.1 SECONDS, color = prev_color)

/mob/living/simple_animal/hostile/ordeal/indigo_midnight/proc/RevertFrenzyBonus(mob/living/simple_animal/hostile/neighbor)
	// I'm reverting the buff like this instead of using initial() in case those values change during the buff for whatever reason, such as lanky noon Evasive Mode.
	neighbor.rapid_melee -= buff_attackspeed_bonus
	neighbor.ChangeMoveToDelay(neighbor.move_to_delay + buff_movespeed_bonus)
	neighbor.melee_damage_lower -= buff_melee_bonus
	neighbor.melee_damage_upper -= buff_melee_bonus


/obj/effect/temp_visual/sweeper_squad_warning
	name = "ominous warning"
	desc = "They're in the walls! Run!"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "sweeper_warning"
	duration = 3 SECONDS
	pixel_x = -32
	base_pixel_x = -32
	pixel_y = -32
	base_pixel_y = -32
	randomdir = FALSE

// Old, we don't use this anymore but it's used elsewhere in the codebase for some reason
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

/obj/effect/specific_sweeper_spawn
	name = "bloodpool"
	desc = "Did it just break through the outer platings...!?"
	icon = 'icons/effects/cult_effects.dmi'
	icon_state = "bloodin"
	move_force = INFINITY
	pull_force = INFINITY
	generic_canpass = FALSE
	movement_type = PHASING | FLYING
	layer = POINT_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/mob/living/simple_animal/hostile/ordeal/indigo_midnight/matriarch
	var/datum/component/ai_leadership/matriarch/her_divine_right_to_rule_all_sweepers
	var/datum/ordeal/matriarch_ordeal_reference
	var/should_bind_to_matriarch = TRUE

/obj/effect/specific_sweeper_spawn/Initialize(mapload, type, mother, retinue = TRUE)
	. = ..()
	if(!type || !ispath(type, /mob/living/simple_animal/hostile/ordeal) || !mother)
		qdel(src)
		return
	if(istype(mother, /mob/living/simple_animal/hostile/ordeal/indigo_midnight))
		matriarch = mother
		her_divine_right_to_rule_all_sweepers = matriarch.GetComponent(/datum/component/ai_leadership/matriarch)
		if(matriarch.ordeal_reference)
			matriarch_ordeal_reference = matriarch.ordeal_reference
		should_bind_to_matriarch = retinue
	addtimer(CALLBACK(src, PROC_REF(SpawnSweeper), type), 1 SECONDS)

/obj/effect/specific_sweeper_spawn/proc/SpawnSweeper(type)
	if(!ispath(type, /mob/living/simple_animal/hostile/ordeal))
		qdel(src)
		return

	var/mob/living/simple_animal/hostile/ordeal/new_neighbor = new type(get_turf(src))

	if(matriarch)
		if(matriarch_ordeal_reference) // Add 'em to our ordeal reference
			new_neighbor.ordeal_reference = matriarch_ordeal_reference
			matriarch_ordeal_reference.ordeal_mobs |= new_neighbor

		if(should_bind_to_matriarch)
			matriarch.RegisterSignal(new_neighbor, COMSIG_LIVING_DEATH, TYPE_PROC_REF(/mob/living/simple_animal/hostile/ordeal/indigo_midnight, RegisterSweeperDeath))
			matriarch.allied_sweepers |= new_neighbor
			her_divine_right_to_rule_all_sweepers.Recruit(new_neighbor) // Add to our Leadership component followers
			her_divine_right_to_rule_all_sweepers.FollowLeader(new_neighbor) // Get over here.

		if(istype(new_neighbor, /mob/living/simple_animal/hostile/ordeal/indigo_dusk))
			var/mob/living/simple_animal/hostile/ordeal/indigo_dusk/favourite_child = new_neighbor
			favourite_child.permitted_to_feast = FALSE // Disallow from eating human corpses, those are for the Matriarch
			favourite_child.stat_attack = HARD_CRIT // They will go sicko mode on corpses they can't devour if we don't set this

			if(should_bind_to_matriarch)
				matriarch.deployed_commanders |= new_neighbor
			else
				matriarch.nitb_deployed_commanders |= new_neighbor
		else
			var/mob/living/simple_animal/hostile/ordeal/indigo_noon/less_favourite_child = new_neighbor
			if(istype(less_favourite_child))
				less_favourite_child.permitted_to_feast = FALSE // Disallow from eating human corpses, those are for the Matriarch
				less_favourite_child.stat_attack = HARD_CRIT // They will go sicko mode on corpses they can't devour if we don't set this
			if(should_bind_to_matriarch)
				matriarch.deployed_grunts |= new_neighbor

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


// Special Sweepers spawned by the Matriarch. They won't have Leadership components, and they will be commanded directly by the Matriarch.
// It'd be more convenient to just set this var to false as they're spawned, but sadly they initialize with the component, and I'd rather not remove the component after it's already been created

// Matriarch's basic sweeper summoning will summon these /retinue types and recruit them into her Leadership component, having them tag along with her for all her patrols.
// However, Sweepers spawned as part of the NitB (>= 4 player scaling) will not be these retinue types, and will patrol on their own.

// I understand it looks really strange to have 7 subtypes for this, but hey, the green ordeals do it too. It will also make it easier to rebalance them in the future.
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/retinue
	commanding_officer = FALSE
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white/retinue
	commanding_officer = FALSE
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black/retinue
	commanding_officer = FALSE
/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale/retinue
	commanding_officer = FALSE

/mob/living/simple_animal/hostile/ordeal/indigo_noon/retinue
/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky/retinue
/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky/retinue


// A component subtype for some special behaviour I want in these Sweepers, since I'd rather not mess with the actual component itself.
/datum/component/ai_leadership/matriarch

// No longer disbands absent troops, just makes them meet up with the Matriarch. Everyone who doesn't have a target, actually.
/datum/component/ai_leadership/matriarch/HeadCount(atom/U)
	if(world.time < headcount_cooldown || (!(length(followers) > 0)))
		return

	Regroup()

	headcount_cooldown = world.time + headcount_delay

/datum/component/ai_leadership/matriarch/FollowLeader(mob/living/L)
	if(!L || L.stat >= DEAD) // L can be null here for some reason
		return
	var/mob/living/simple_animal/hostile/ordeal/indigo_midnight/matriarch = parent
	var/mob/living/simple_animal/hostile/ordeal/neighbor = L
	if(!matriarch || !(istype(matriarch)) || !(istype(neighbor)))
		return

	if(!(neighbor.target)) // Only unoccupied Sweepers
		if(get_dist(matriarch, neighbor) < 10) // Closer Sweepers use simpler pathing
			walk_to(neighbor, matriarch, 3, neighbor.move_to_delay)
		else
			var/turf/matriarch_turf = get_turf(parent)
			neighbor.patrol_to(matriarch_turf) // Dear god, they have to use A* (walk_to will just make them bang their head on a wall in some cases)


#undef COMBAT_ABILITY_DASH
#undef COMBAT_ABILITY_SLAM
#undef COMBAT_ABILITY_TRASH_DISPOSAL
#undef COMBAT_ABILITY_SLASH
#undef COMBAT_ABILITY_PARRY

#undef SUPPORT_ABILITY_OFFENSIVE
#undef SUPPORT_ABILITY_PERSISTENCE
#undef SUPPORT_ABILITY_SUMMON
