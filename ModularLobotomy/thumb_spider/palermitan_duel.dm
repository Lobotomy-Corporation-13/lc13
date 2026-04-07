////////////////////////////////////////////////////////////
// PALERMITAN DUEL SYSTEM
// PvP duel system for Thumb Apprentice progression.
// Creates an arena ring, detects win/loss, grants rewards.
////////////////////////////////////////////////////////////

/// Training dummy for solo duel testing
/mob/living/simple_animal/hostile/palermitan_dummy
	name = "training dummy"
	desc = "A training dummy for duel practice."
	icon = 'icons/mob/simple_human.dmi'
	icon_state = "psycho_knife"
	icon_living = "psycho_knife"
	maxHealth = 500
	health = 500
	stat_attack = CONSCIOUS
	faction = list("neutral")
	melee_damage_lower = 10
	melee_damage_upper = 15
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"
	/// Fake attributes for reward calculation (simple_animals don't have real attributes)
	var/fake_attributes = 100

////////////////////////////////////////////////////////////
// DUEL DATUM
/datum/thumb_duel
	/// The player who initiated the duel (usually the apprentice)
	var/mob/living/challenger
	/// The player/mob who accepted the duel
	var/mob/living/opponent
	/// Center turf of the arena
	var/turf/arena_center
	/// Radius of the arena in tiles
	var/arena_radius = 7
	/// Whether the duel is currently active
	var/active = FALSE
	/// Timer for periodic arena checks
	var/check_timer
	/// List of spawned wall effects (for cleanup)
	var/list/arena_walls = list()

/datum/thumb_duel/New(mob/living/init_challenger, mob/living/init_opponent)
	challenger = init_challenger
	opponent = init_opponent

/datum/thumb_duel/Destroy()
	if(active)
		cleanup()
	challenger = null
	opponent = null
	arena_center = null
	return ..()

/// Starts the duel after both participants are ready
/datum/thumb_duel/proc/start_duel()
	if(active)
		return
	if(QDELETED(challenger) || QDELETED(opponent))
		qdel(src)
		return

	// Calculate arena center as midpoint between the two participants
	var/turf/t1 = get_turf(challenger)
	var/turf/t2 = get_turf(opponent)
	if(!t1 || !t2 || t1.z != t2.z)
		qdel(src)
		return
	var/mid_x = round((t1.x + t2.x) / 2)
	var/mid_y = round((t1.y + t2.y) / 2)
	arena_center = locate(mid_x, mid_y, t1.z)
	if(!arena_center)
		qdel(src)
		return

	active = TRUE

	// Register signals for win/loss detection
	RegisterSignal(challenger, COMSIG_MOB_STATCHANGE, PROC_REF(on_challenger_stat_change))
	RegisterSignal(opponent, COMSIG_MOB_STATCHANGE, PROC_REF(on_opponent_stat_change))

	// Spawn arena walls and start check loop
	spawn_arena_walls()
	check_timer = addtimer(CALLBACK(src, PROC_REF(arena_check_loop)), 5 SECONDS, TIMER_STOPPABLE)

	to_chat(challenger, span_boldwarning("The duel begins!"))
	to_chat(opponent, span_boldwarning("The duel begins!"))
	playsound(arena_center, 'sound/effects/alert.ogg', 50, FALSE, 8)

/// Spawns visual barrier markers on the border ring (non-dense, trigger on Crossed)
/datum/thumb_duel/proc/spawn_arena_walls()
	// Clean up old walls first
	for(var/obj/effect/temp_visual/duel_wall/W in arena_walls)
		if(!QDELETED(W))
			qdel(W)
	arena_walls.Cut()
	// Spawn new walls on the border ring
	if(!arena_center)
		return
	for(var/turf/T in RANGE_TURFS(arena_radius, arena_center))
		if(get_dist(T, arena_center) == arena_radius)
			var/obj/effect/temp_visual/duel_wall/wall = new(T)
			wall.duel_ref = src
			arena_walls += wall

/// Periodic check loop — refreshes walls (they're temp_visuals and expire)
/datum/thumb_duel/proc/arena_check_loop()
	if(!active)
		return
	spawn_arena_walls()
	check_timer = addtimer(CALLBACK(src, PROC_REF(arena_check_loop)), 5 SECONDS, TIMER_STOPPABLE)

/// Signal handler: challenger entered crit
/datum/thumb_duel/proc/on_challenger_stat_change(datum/source, new_stat, old_stat)
	SIGNAL_HANDLER
	if(new_stat >= SOFT_CRIT)
		INVOKE_ASYNC(src, PROC_REF(end_duel), opponent, challenger, "was defeated")

/// Signal handler: opponent entered crit
/datum/thumb_duel/proc/on_opponent_stat_change(datum/source, new_stat, old_stat)
	SIGNAL_HANDLER
	if(new_stat >= SOFT_CRIT)
		INVOKE_ASYNC(src, PROC_REF(end_duel), challenger, opponent, "was defeated")

/// Called by duel_wall when a participant steps on the barrier
/datum/thumb_duel/proc/on_barrier_crossed(mob/living/crosser)
	if(!active)
		return
	if(crosser == challenger)
		INVOKE_ASYNC(src, PROC_REF(end_duel), opponent, challenger, "left the ring")
	else if(crosser == opponent)
		INVOKE_ASYNC(src, PROC_REF(end_duel), challenger, opponent, "left the ring")

/// Ends the duel, heals players, grants rewards
/datum/thumb_duel/proc/end_duel(mob/living/winner, mob/living/loser, reason = "")
	if(!active)
		return
	active = FALSE

	// Announce result
	if(winner && !QDELETED(winner))
		to_chat(winner, span_boldnotice("You won the duel! [loser] [reason]."))
	if(loser && !QDELETED(loser))
		to_chat(loser, span_boldwarning("You lost the duel."))

	// Heal winner 50% of missing HP, loser 25%
	if(winner && !QDELETED(winner))
		var/winner_missing = winner.maxHealth - winner.health
		if(winner_missing > 0)
			winner.adjustBruteLoss(-(winner_missing * 0.5))
	if(loser && !QDELETED(loser))
		var/loser_missing = loser.maxHealth - loser.health
		if(loser_missing > 0)
			loser.adjustBruteLoss(-(loser_missing * 0.25))

	// Grant rewards
	grant_duel_rewards(winner, loser)

	// Cleanup and self-delete
	cleanup()
	qdel(src)

/// Cleans up signals, timers, and arena walls
/datum/thumb_duel/proc/cleanup()
	if(challenger && !QDELETED(challenger))
		UnregisterSignal(challenger, COMSIG_MOB_STATCHANGE)
	if(opponent && !QDELETED(opponent))
		UnregisterSignal(opponent, COMSIG_MOB_STATCHANGE)
	deltimer(check_timer)
	for(var/obj/effect/temp_visual/duel_wall/W in arena_walls)
		if(!QDELETED(W))
			qdel(W)
	arena_walls.Cut()

////////////////////////////////////////////////////////////
// DUEL REWARDS (Step 6)

/// Grants attribute growth, EXP, and role tracking after a duel
/datum/thumb_duel/proc/grant_duel_rewards(mob/living/winner, mob/living/loser)
	if(!winner || !loser)
		return

	// Determine which participant is the apprentice
	var/mob/living/carbon/human/apprentice
	var/mob/living/opponent_mob
	var/player_won = FALSE

	if(ishuman(winner))
		var/mob/living/carbon/human/HW = winner
		if(HW.GetComponent(/datum/component/palermitan_apprentice))
			apprentice = HW
			opponent_mob = loser
			player_won = TRUE
	if(!apprentice && ishuman(loser))
		var/mob/living/carbon/human/HL = loser
		if(HL.GetComponent(/datum/component/palermitan_apprentice))
			apprentice = HL
			opponent_mob = winner
			player_won = FALSE

	if(!apprentice)
		return

	// Get opponent's average attributes
	var/opponent_avg = 100
	if(istype(opponent_mob, /mob/living/simple_animal/hostile/palermitan_dummy))
		var/mob/living/simple_animal/hostile/palermitan_dummy/D = opponent_mob
		opponent_avg = D.fake_attributes
	else if(ishuman(opponent_mob))
		var/mob/living/carbon/human/HO = opponent_mob
		var/total = 0
		var/count = 0
		for(var/attr_name in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE, TEMPERANCE_ATTRIBUTE, JUSTICE_ATTRIBUTE))
			var/datum/attribute/A = HO.attributes[attr_name]
			if(A)
				total += A.level
				count++
		if(count > 0)
			opponent_avg = total / count

	// Get apprentice's average attributes
	var/apprentice_avg = 40
	var/total_app = 0
	var/count_app = 0
	for(var/attr_name in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE, TEMPERANCE_ATTRIBUTE, JUSTICE_ATTRIBUTE))
		var/datum/attribute/A = apprentice.attributes[attr_name]
		if(A)
			total_app += A.level
			count_app++
	if(count_app > 0)
		apprentice_avg = total_app / count_app

	// Calculate ratio and modifiers
	var/ratio = 1.0
	if(apprentice_avg > 0)
		ratio = clamp(opponent_avg / apprentice_avg, 0.25, 2.0)
	var/win_modifier = player_won ? 1.0 : 0.25

	// === ATTRIBUTE GROWTH ===
	var/base_gain = 6
	var/gain_per_attr = round(base_gain * ratio * win_modifier)
	if(gain_per_attr > 0)
		for(var/attr_name in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE, TEMPERANCE_ATTRIBUTE, JUSTICE_ATTRIBUTE))
			var/datum/attribute/A = apprentice.attributes[attr_name]
			if(A)
				A.level = min(200, A.level + gain_per_attr)
				A.on_update(apprentice)
		to_chat(apprentice, span_notice("You gained [gain_per_attr] to each attribute from the duel."))

	// === EXP GROWTH ===
	var/base_exp = 20
	var/exp_gained = round(base_exp * ratio * win_modifier)
	var/datum/component/palermitan_exp/exp_comp = apprentice.GetComponent(/datum/component/palermitan_exp)
	if(exp_comp && exp_gained > 0)
		exp_comp.modify_exp(exp_gained)

	// === ROLE TRACKING ===
	if(exp_comp && opponent_mob?.mind)
		exp_comp.increment_role_duel(opponent_mob.mind.assigned_role)

	// === GEAR TIER-UP CHECK ===
	check_gear_tierup(apprentice)

	// === CORRECTION ELIGIBILITY (on loss) ===
	if(!player_won)
		var/datum/component/palermitan_apprentice/pal = apprentice.GetComponent(/datum/component/palermitan_apprentice)
		if(pal)
			pal.correction_eligible = TRUE
			pal.correction_deadline = world.time + 1.5 MINUTES
			// Store what a correction would grant (0.25x of win value)
			var/correction_gain = round(base_gain * ratio * 0.25)
			pal.potential_correction_attrs = correction_gain
			to_chat(apprentice, span_info("Your mentor can correct you within 1.5 minutes for additional attribute growth."))

/// Checks if the apprentice's attributes warrant a gear tier-up
/proc/check_gear_tierup(mob/living/carbon/human/apprentice)
	if(!istype(apprentice))
		return
	// Get the minimum attribute level (all 4 must meet the threshold)
	var/min_attr = INFINITY
	for(var/attr_name in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE, TEMPERANCE_ATTRIBUTE, JUSTICE_ATTRIBUTE))
		var/datum/attribute/A = apprentice.attributes[attr_name]
		if(A)
			min_attr = min(min_attr, A.level)
	if(min_attr == INFINITY)
		return

	// Determine what tier the attributes support: (attrs / 2) >= requirement
	var/effective = round(min_attr / 2)
	var/new_tier = 1
	if(effective >= 100)
		new_tier = 4
	else if(effective >= 80)
		new_tier = 3
	else if(effective >= 60)
		new_tier = 2

	// Update weapons
	for(var/obj/item/ego_weapon/city/thumbapprentice_katana/K in apprentice.GetAllContents())
		if(K.tier < new_tier)
			K.set_tier(new_tier)
			to_chat(apprentice, span_boldnotice("Your katana has evolved to tier [new_tier]!"))
	for(var/obj/item/ego_weapon/city/thumbapprentice_greatsword/G in apprentice.GetAllContents())
		if(G.tier < new_tier)
			G.set_tier(new_tier)
			to_chat(apprentice, span_boldnotice("Your greatsword has evolved to tier [new_tier]!"))
	// Update armor (worn or carried)
	var/obj/item/clothing/suit/armor/ego_gear/city/thumb_spider/apprentice/worn = apprentice.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(istype(worn) && worn.tier < new_tier)
		worn.set_tier(new_tier)
		to_chat(apprentice, span_boldnotice("Your armor has evolved to tier [new_tier]!"))
	for(var/obj/item/clothing/suit/armor/ego_gear/city/thumb_spider/apprentice/A in apprentice.GetAllContents())
		if(A.tier < new_tier)
			A.set_tier(new_tier)

////////////////////////////////////////////////////////////
// DUEL WALL EFFECT

/// Visual barrier for the duel arena border — NOT dense, ends duel on contact
/obj/effect/temp_visual/duel_wall
	name = "duel barrier"
	desc = "A shimmering barrier marking the edge of a duel."
	icon = 'icons/turf/walls/hierophant_wall_temp.dmi'
	icon_state = "hierophant_wall_temp-0"
	base_icon_state = "hierophant_wall_temp"
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_HIERO_WALL)
	canSmoothWith = list(SMOOTH_GROUP_HIERO_WALL)
	duration = 6 SECONDS
	layer = BELOW_MOB_LAYER
	density = FALSE
	anchored = TRUE
	color = "#c4a000"
	light_range = MINIMUM_USEFUL_LIGHT_RANGE
	light_color = "#c4a000"
	/// Reference to the duel datum
	var/datum/thumb_duel/duel_ref

/obj/effect/temp_visual/duel_wall/Initialize(mapload)
	. = ..()
	if(smoothing_flags & (SMOOTH_CORNERS|SMOOTH_BITMASK))
		QUEUE_SMOOTH_NEIGHBORS(src)
		QUEUE_SMOOTH(src)

/obj/effect/temp_visual/duel_wall/Destroy()
	if(smoothing_flags & (SMOOTH_CORNERS|SMOOTH_BITMASK))
		QUEUE_SMOOTH_NEIGHBORS(src)
	duel_ref = null
	return ..()

/// When a duel participant steps on the barrier, they lose
/obj/effect/temp_visual/duel_wall/Crossed(atom/movable/crossing)
	. = ..()
	if(!duel_ref || !duel_ref.active)
		return
	if(!isliving(crossing))
		return
	var/mob/living/crosser = crossing
	if(crosser == duel_ref.challenger || crosser == duel_ref.opponent)
		duel_ref.on_barrier_crossed(crosser)

////////////////////////////////////////////////////////////
// DUEL CHALLENGE ACTION

/// Action button granted to Thumb Apprentices to challenge players/dummies to duels
/datum/action/innate/thumb_duel_challenge
	name = "Challenge to Duel"
	desc = "Challenge a nearby player or dummy to a duel."
	button_icon_state = "yourswordinhand"
	/// Active duel (only one at a time)
	var/datum/thumb_duel/current_duel

/datum/action/innate/thumb_duel_challenge/Activate()
	var/mob/living/carbon/human/user = owner
	if(!istype(user))
		return
	if(current_duel?.active)
		to_chat(user, span_warning("You are already in a duel!"))
		return

	// Find nearby valid targets (humans + dummies)
	var/list/nearby = list()
	for(var/mob/living/carbon/human/H in view(7, user))
		if(H != user && H.stat == CONSCIOUS)
			nearby += H
	for(var/mob/living/simple_animal/hostile/palermitan_dummy/D in view(7, user))
		if(D.stat == CONSCIOUS)
			nearby += D
	if(!length(nearby))
		to_chat(user, span_warning("No valid targets nearby."))
		return

	var/mob/living/target = tgui_input_list(user, "Who do you challenge?", "Duel Challenge", nearby)
	if(!target || QDELETED(target) || QDELETED(user))
		return
	if(get_dist(user, target) > 7)
		to_chat(user, span_warning("[target] is too far away."))
		return

	// Dummies auto-accept
	if(istype(target, /mob/living/simple_animal/hostile/palermitan_dummy))
		current_duel = new /datum/thumb_duel(user, target)
		current_duel.start_duel()
		return

	// Challenge a human player
	to_chat(target, span_boldnotice("[user] challenges you to a duel!"))
	var/response = tgui_alert(target, "[user] challenges you to a duel. Accept?", "Duel Challenge", list("Accept", "Decline"))
	if(response != "Accept")
		to_chat(user, span_warning("[target] declined your challenge."))
		return
	// Validate both still ok
	if(QDELETED(user) || QDELETED(target) || user.stat != CONSCIOUS || target.stat != CONSCIOUS)
		return
	if(get_dist(user, target) > 12)
		to_chat(user, span_warning("[target] is too far away now."))
		return

	current_duel = new /datum/thumb_duel(user, target)
	current_duel.start_duel()
