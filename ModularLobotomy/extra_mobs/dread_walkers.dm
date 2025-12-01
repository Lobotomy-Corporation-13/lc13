/// Dread Walkers - Unseen horrors that become visible only to those they mark with their attacks
/// Global list of all humans who have been marked by ANY Dread Walker
GLOBAL_LIST_EMPTY(dread_marked_humans)
/// Global list of all Dread Walkers (for mutual visibility)
GLOBAL_LIST_EMPTY(dread_walkers)
/// Global list of patrol points for Dread Walkers
GLOBAL_LIST_EMPTY(dread_walker_patrol_points)

#define STATUS_EFFECT_DREAD_MARKED /datum/status_effect/dread_marked

/// Patrol landmark for Dread Walkers
/obj/effect/landmark/dread_walker_patrol
	name = "dread walker patrol point"
	icon_state = "x2"

/obj/effect/landmark/dread_walker_patrol/Initialize()
	. = ..()
	GLOB.dread_walker_patrol_points += src

/obj/effect/landmark/dread_walker_patrol/Destroy()
	GLOB.dread_walker_patrol_points -= src
	return ..()

/mob/living/simple_animal/hostile/dread_walker
	name = "Dread Walker"
	desc = "An otherworldly presence that defies perception. You shouldn't be able to see this..."
	icon = 'icons/mob/animal.dmi'
	icon_state = "faithless"
	icon_living = "faithless"
	icon_dead = "faithless_dead"

	invisibility = INVISIBILITY_OBSERVER	// Invisible to all by default
	mouse_opacity = FALSE
	density = FALSE

	health = 200
	maxHealth = 200
	melee_damage_lower = 15
	melee_damage_upper = 25
	melee_damage_type = RED_DAMAGE
	obj_damage = 40
	move_to_delay = 5

	attack_verb_continuous = "rends"
	attack_verb_simple = "rend"
	attack_sound = 'sound/weapons/slash.ogg'

	faction = list("dread")
	mob_biotypes = MOB_UNDEAD|MOB_HUMANOID
	speak_emote = list("whispers", "murmurs")
	emote_see = list("flickers", "phases slightly", "seems to distort reality")

	stat_attack = HARD_CRIT
	robust_searching = TRUE
	vision_range = 9
	aggro_vision_range = 12

	/// Associative list of mob -> image shown to that client
	var/list/client_images = list()
	/// List of humans currently flickering (transitioning to visible)
	var/list/flickering_targets = list()
	/// Cooldown for the spectral touch attack
	var/spectral_touch_cooldown = 0
	var/spectral_touch_cooldown_time = 3 SECONDS
	/// Can the mob act (used during attack animations)
	var/can_act = TRUE

	// Patrol system
	can_patrol = TRUE

	// Behavior state system
	/// Current behavior state: "patrol", "stalking", "marking"
	var/behavior_state = "patrol"
	/// When the current state started
	var/state_start_time = 0

	// Timing durations
	/// How long to patrol before picking a stalking target (2-3 minutes)
	var/patrol_duration = 2.5 MINUTES
	/// How long to stalk before making the marking decision (1-2 minutes)
	var/stalk_duration = 1.5 MINUTES

	// Stalking target
	/// The human we're currently stalking
	var/mob/living/carbon/human/stalked_target = null

	// Teleportation
	/// Cooldown for teleportation
	var/teleport_cooldown = 0
	var/teleport_cooldown_time = 15 SECONDS
	/// Minimum distance to teleport from target
	var/teleport_range_min = 3
	/// Maximum distance to teleport from target
	var/teleport_range_max = 5

	// Speech system
	/// Last time the walker spoke
	var/last_speech_time = 0
	/// Time between speeches
	var/speech_cooldown_time = 30 SECONDS
	/// Atmospheric phrases for patrol
	var/list/patrol_phrases = list(
		"...seeking...",
		"...hunger...",
		"...wandering...",
		"...endless...",
		"...void calls...",
		"...searching...",
		"...alone...",
		"...forgotten..."
	)
	/// Atmospheric phrases for stalking
	var/list/stalking_phrases = list(
		"...I see you...",
		"...watching...",
		"...closer...",
		"...you cannot hide...",
		"...I know...",
		"...found you...",
		"...waiting...",
		"...inevitable..."
	)

/mob/living/simple_animal/hostile/dread_walker/Initialize()
	. = ..()

	// Add self to global Dread Walker list
	GLOB.dread_walkers += src

	// Show all other Dread Walkers to this one (mutual visibility)
	for(var/mob/living/simple_animal/hostile/dread_walker/other_walker in GLOB.dread_walkers)
		if(other_walker != src)
			ShowToDreadWalker(other_walker)
			other_walker.ShowToDreadWalker(src)

	// Create images for all already-marked humans
	for(var/mob/living/carbon/human/H in GLOB.dread_marked_humans)
		ShowToMarked(H)

	// Start patrol behavior (delayed to avoid sleep in Initialize)
	behavior_state = "patrol"
	state_start_time = world.time
	addtimer(CALLBACK(src, PROC_REF(StartPatrol)), 1 SECONDS)

/mob/living/simple_animal/hostile/dread_walker/Destroy()
	// Remove from global list
	GLOB.dread_walkers -= src

	// Clean up all client images
	for(var/mob/M in GLOB.dread_marked_humans)
		if(M.client && client_images[M])
			M.client.images -= client_images[M]

	// Clean up images from other Dread Walkers
	for(var/mob/living/simple_animal/hostile/dread_walker/walker in GLOB.dread_walkers)
		if(walker.client && walker.client_images[src])
			walker.client.images -= walker.client_images[src]
			walker.client_images -= src

	client_images.Cut()
	flickering_targets.Cut()
	return ..()

/// Show this Dread Walker to another Dread Walker (mutual visibility)
/mob/living/simple_animal/hostile/dread_walker/proc/ShowToDreadWalker(mob/living/simple_animal/hostile/dread_walker/walker)
	if(!istype(walker) || !walker.client)
		return

	if(client_images[walker])
		return  // Already showing to this walker

	// Create an image for the other walker's client
	var/image/I = image(icon, src, icon_state, layer, dir = src.dir)
	I.override = TRUE
	I.pixel_x = pixel_x
	I.pixel_y = pixel_y

	walker.client.images += I
	client_images[walker] = I

/// Show this Dread Walker to a marked human
/mob/living/simple_animal/hostile/dread_walker/proc/ShowToMarked(mob/living/carbon/human/H)
	if(!istype(H) || !H.client)
		return

	if(client_images[H])
		return  // Already showing to this human

	// Create an image for this client to see us
	var/image/I = image(icon, src, icon_state, layer, dir = src.dir)
	I.override = TRUE  // Override invisibility
	I.pixel_x = pixel_x
	I.pixel_y = pixel_y

	H.client.images += I
	client_images[H] = I

/// Mark a target globally, starting the flickering reveal process
/mob/living/simple_animal/hostile/dread_walker/proc/MarkTarget(mob/living/carbon/human/H)
	if(!istype(H))
		return

	// Check if already marked or has the status effect
	if(H.has_status_effect(STATUS_EFFECT_DREAD_MARKED))
		return  // Already marked

	// Apply the dread marked status effect (30 seconds)
	H.apply_status_effect(STATUS_EFFECT_DREAD_MARKED)

/// Start the flickering reveal transition for a human
/mob/living/simple_animal/hostile/dread_walker/proc/BeginFlickering(mob/living/carbon/human/H)
	if(!istype(H))
		return

	// Add to this walker's flickering list
	flickering_targets += H

	// Notify the human
	to_chat(H, "<span class='warning'>The air distorts... something watches you from beyond...</span>")
	H.playsound_local(get_turf(H), 'sound/hallucinations/im_here1.ogg', 30, 1)

	// Create initial images for all Dread Walkers with alpha 0
	for(var/mob/living/simple_animal/hostile/dread_walker/walker in GLOB.dread_walkers)
		var/image/I = image(walker.icon, walker, walker.icon_state, walker.layer, dir = walker.dir)
		I.override = TRUE
		I.pixel_x = walker.pixel_x
		I.pixel_y = walker.pixel_y
		I.alpha = 0  // Start invisible

		H.client.images += I
		walker.client_images[H] = I

	// Start the flicker cycle (6-8 flickers)
	var/flicker_count = rand(6, 8)
	FlickerCycle(H, flicker_count)

/// Recursive flickering cycle with smooth alpha transitions
/mob/living/simple_animal/hostile/dread_walker/proc/FlickerCycle(mob/living/carbon/human/H, flickers_remaining)
	if(!H || QDELETED(H) || !H.client)
		// Clean up images
		for(var/mob/living/simple_animal/hostile/dread_walker/walker in GLOB.dread_walkers)
			walker.flickering_targets -= H
			var/image/existing = walker.client_images[H]
			if(existing)
				H.client.images -= existing
				walker.client_images -= H
		return

	if(flickers_remaining <= 0)
		FinishFlickering(H)
		return

	// Animate all Dread Walker images for this human
	for(var/mob/living/simple_animal/hostile/dread_walker/walker in GLOB.dread_walkers)
		var/image/flicker_image = walker.client_images[H]
		if(!flicker_image)
			continue

		// Fade in to alpha 120
		animate(flicker_image, alpha = 120, time = rand(3, 6))
		// Then fade out to alpha 0
		animate(alpha = 0, time = rand(3, 6))

	// Continue cycle after animation completes
	var/delay = rand(6, 12)
	addtimer(CALLBACK(src, PROC_REF(FlickerCycle), H, flickers_remaining - 1), delay)

/// Finish the flickering process and finalize visibility
/mob/living/simple_animal/hostile/dread_walker/proc/FinishFlickering(mob/living/carbon/human/H)
	if(!istype(H))
		return

	// Remove from flickering lists
	for(var/mob/living/simple_animal/hostile/dread_walker/walker in GLOB.dread_walkers)
		walker.flickering_targets -= H

	// Final reveal message
	to_chat(H, "<span class='userdanger'>Your mind reels as unknowable horrors become fully visible to you!</span>")
	H.playsound_local(get_turf(H), 'sound/hallucinations/growl1.ogg', 50, 1)

	// Fade all Dread Walkers to full visibility
	for(var/mob/living/simple_animal/hostile/dread_walker/walker in GLOB.dread_walkers)
		var/image/existing = walker.client_images[H]
		if(existing)
			// Smoothly transition to full visibility
			animate(existing, alpha = 255, time = 5)

/// Update all images when we move or change appearance
/mob/living/simple_animal/hostile/dread_walker/Moved(atom/OldLoc, Dir)
	. = ..()
	UpdateImages()

/// Update direction when we turn
/mob/living/simple_animal/hostile/dread_walker/setDir(newdir)
	. = ..()
	UpdateImages()

/// Refresh all client images to match our current state
/mob/living/simple_animal/hostile/dread_walker/proc/UpdateImages()
	// Update images for marked humans
	for(var/mob/M in GLOB.dread_marked_humans)
		if(!M.client)
			continue

		// Remove old image
		var/image/old_image = client_images[M]
		if(old_image)
			M.client.images -= old_image

		// Create new image with current state
		var/image/new_image = image(icon, src, icon_state, layer, dir = src.dir)
		new_image.override = TRUE
		new_image.pixel_x = pixel_x
		new_image.pixel_y = pixel_y

		M.client.images += new_image
		client_images[M] = new_image

	// Update images for other Dread Walkers
	for(var/mob/living/simple_animal/hostile/dread_walker/walker in GLOB.dread_walkers)
		if(walker == src || !walker.client)
			continue

		// Remove old image
		var/image/old_image = client_images[walker]
		if(old_image)
			walker.client.images -= old_image

		// Create new image with current state
		var/image/new_image = image(icon, src, icon_state, layer, dir = src.dir)
		new_image.override = TRUE
		new_image.pixel_x = pixel_x
		new_image.pixel_y = pixel_y

		walker.client.images += new_image
		client_images[walker] = new_image

/// When we die, make sure to update the icon state for all marked targets
/mob/living/simple_animal/hostile/dread_walker/death(gibbed)
	. = ..()
	icon_state = icon_dead
	UpdateImages()

/// Override melee attack to mark targets
/mob/living/simple_animal/hostile/dread_walker/AttackingTarget()
	. = ..()
	if(ishuman(target))
		MarkTarget(target)

/// Override CanAttack - can target any human for ranged marking, but only attack marked humans in melee
/mob/living/simple_animal/hostile/dread_walker/CanAttack(atom/the_target)
	// Don't attack while patrolling or stalking
	if(behavior_state == "patrol" || behavior_state == "stalking")
		return FALSE

	// When finding a stalk target, allow unmarked humans
	if(behavior_state == "finding_stalk_target")
		if(ishuman(the_target))
			var/mob/living/carbon/human/H = the_target
			// Don't target already marked humans for stalking
			if(H.has_status_effect(STATUS_EFFECT_DREAD_MARKED))
				return FALSE
			return ..()  // Use parent checks
		return FALSE

	if(ishuman(the_target))
		var/mob/living/carbon/human/H = the_target

		// In melee range, only attack if marked
		if(get_dist(src, H) <= melee_reach)
			if(!H.has_status_effect(STATUS_EFFECT_DREAD_MARKED))
				return FALSE  // Can't melee unmarked humans

		// Allow targeting for ranged attacks (SpectralTouch) on anyone
		return ..()  // Use parent checks for godmode, AFK, etc.

	// Don't attack anything else
	return FALSE

/// Handle losing target during combat
/mob/living/simple_animal/hostile/dread_walker/LoseTarget()
	. = ..()
	// If we lost our marked target during combat, return to patrol
	if(behavior_state == "marking")
		ReturnToPatrol()

/// Check if a turf blocks line of sight
/mob/living/simple_animal/hostile/dread_walker/proc/DensityCheck(turf/T)
	if(T.density)
		return TRUE
	for(var/obj/machinery/door/D in T.contents)
		if(D.density)
			return TRUE
	return FALSE

/// Prevent movement during attacks
/mob/living/simple_animal/hostile/dread_walker/Move()
	if(!can_act)
		return FALSE
	return ..()

/// Override patrol_move to not cancel when we have a stalking target
/mob/living/simple_animal/hostile/dread_walker/patrol_move(dest)
	// Don't cancel patrol if we're stalking (we use target for following)
	if(behavior_state == "stalking")
		return FALSE  // Stop patrol, we're stalking now
	return ..()

/// Life cycle - handle behavior state machine
/mob/living/simple_animal/hostile/dread_walker/Life()
	. = ..()
	if(!.)
		return

	// Periodic speech during patrol and stalking
	if(behavior_state == "patrol" || behavior_state == "stalking")
		if(world.time >= last_speech_time + speech_cooldown_time)
			AtmosphericSpeech()

	switch(behavior_state)
		if("patrol")
			HandlePatrolState()
		if("stalking")
			HandleStalkingState()
		if("marking")
			return  // Normal combat behavior - do nothing special in Life()

/// Override speech to only be heard by marked humans and other Dread Walkers
/mob/living/simple_animal/hostile/dread_walker/send_speech(message, range = 7, obj/source = src, bubble_type, list/spans, datum/language/message_language = null, list/message_mods = list())
	var/rendered = compose_message(src, message_language, message, spans, message_mods)

	// Get all potential hearers in range
	for(var/_AM in get_hearers_in_view(range, source))
		var/atom/movable/AM = _AM

		// Check if this hearer can hear Dread Walkers
		var/can_hear = FALSE

		// Other Dread Walkers can always hear
		if(istype(AM, /mob/living/simple_animal/hostile/dread_walker))
			can_hear = TRUE

		// Marked humans can hear
		else if(ishuman(AM))
			var/mob/living/carbon/human/H = AM
			if(H in GLOB.dread_marked_humans)
				can_hear = TRUE

		// If they can hear, send the speech
		if(can_hear)
			AM.Hear(rendered, src, message_language, message, spans, message_mods)

/// Make atmospheric speech based on current state
/mob/living/simple_animal/hostile/dread_walker/proc/AtmosphericSpeech()
	last_speech_time = world.time

	var/message
	if(behavior_state == "patrol")
		message = pick(patrol_phrases)
	else if(behavior_state == "stalking")
		message = pick(stalking_phrases)
	else
		return  // Don't speak during marking

	say(message)

/// Handle patrol state behavior
/mob/living/simple_animal/hostile/dread_walker/proc/HandlePatrolState()
	// Check if we can see any marked humans - if so, attack them immediately
	for(var/mob/living/carbon/human/H in view(vision_range, src))
		if(H.has_status_effect(STATUS_EFFECT_DREAD_MARKED))
			// Found a marked human, switch to marking state and attack
			behavior_state = "marking"
			GiveTarget(H)
			return

	// Check if patrol duration elapsed
	if(world.time - state_start_time >= patrol_duration)
		TryStartStalking()
		return

	// Continue patrolling - pick new patrol point if idle
	if(!patrol_path || !patrol_path.len)
		if(patrol_cooldown <= world.time)
			StartPatrol()

/// Start patrolling to a random patrol landmark
/mob/living/simple_animal/hostile/dread_walker/proc/StartPatrol()
	if(!LAZYLEN(GLOB.dread_walker_patrol_points))
		return FALSE

	var/obj/effect/landmark/patrol_point = pick(GLOB.dread_walker_patrol_points)
	patrol_to(get_turf(patrol_point))
	return TRUE

/// Try to start stalking using FindTarget
/mob/living/simple_animal/hostile/dread_walker/proc/TryStartStalking()
	// Temporarily set state to "stalking" so CanAttack allows finding targets
	var/old_state = behavior_state
	behavior_state = "finding_stalk_target"  // Temporary state

	// Try to find a target using the hostile mob AI
	var/mob/living/found_target = FindTarget()

	// Restore state
	behavior_state = old_state

	// Check if we found a valid human target to stalk
	if(found_target && ishuman(found_target))
		var/mob/living/carbon/human/H = found_target
		// Don't stalk already marked humans
		if(H.has_status_effect(STATUS_EFFECT_DREAD_MARKED))
			state_start_time = world.time  // Reset patrol timer
			LoseTarget()  // Clear the target
			return

		// Start stalking this target
		stalked_target = H
		behavior_state = "stalking"
		state_start_time = world.time
		patrol_reset()  // Stop current patrol
		// Target is already set by FindTarget
	else
		// No valid targets, keep patrolling
		state_start_time = world.time
		LoseTarget()  // Clear any target that was set

/// Handle stalking state behavior
/mob/living/simple_animal/hostile/dread_walker/proc/HandleStalkingState()
	// Validate stalking target
	if(!stalked_target || stalked_target.stat == DEAD || stalked_target.z != z)
		ReturnToPatrol()
		return

	// Check if target is already marked (someone else got them)
	if(stalked_target.has_status_effect(STATUS_EFFECT_DREAD_MARKED))
		ReturnToPatrol()
		return

	// Check if we can see the target
	if(!(stalked_target in view(vision_range, src)))
		TeleportNearTarget()

	// Check if stalk duration elapsed
	if(world.time - state_start_time >= stalk_duration)
		MakeMarkingDecision()

/// Teleport near the stalking target when losing sight
/mob/living/simple_animal/hostile/dread_walker/proc/TeleportNearTarget()
	if(!stalked_target)
		return
	if(teleport_cooldown > world.time)
		return

	teleport_cooldown = world.time + teleport_cooldown_time

	// Get turfs in range 3-5 tiles
	var/list/nearby_turfs = list()
	for(var/turf/T in orange(teleport_range_max, stalked_target))
		if(get_dist(T, stalked_target) >= teleport_range_min)
			if(!T.density)
				nearby_turfs += T

	if(!nearby_turfs.len)
		return

	var/turf/dest = pick(nearby_turfs)
	forceMove(dest)

/// Make the decision to mark or return to patrol (25% chance to mark)
/mob/living/simple_animal/hostile/dread_walker/proc/MakeMarkingDecision()
	if(!stalked_target)
		ReturnToPatrol()
		return

	if(prob(25))  // 25% chance to mark and attack
		behavior_state = "marking"
		MarkTarget(stalked_target)
		// Target is already set from stalking, so we'll start attacking
	else  // 75% chance to return to patrol
		ReturnToPatrol()

/// Return to patrol state
/mob/living/simple_animal/hostile/dread_walker/proc/ReturnToPatrol()
	behavior_state = "patrol"
	state_start_time = world.time
	stalked_target = null
	LoseTarget()  // Clear current target
	StartPatrol()  // Begin new patrol

/// Status effect for being marked by Dread Walkers
/datum/status_effect/dread_marked
	id = "dread_marked"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 30 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/dread_marked

/atom/movable/screen/alert/status_effect/dread_marked
	name = "Marked by Dread"
	desc = "Unknowable horrors from beyond have marked you. You can see and hear them..."
	icon_state = "curse"

/datum/status_effect/dread_marked/on_apply()
	if(!ishuman(owner))
		return FALSE

	var/mob/living/carbon/human/H = owner

	// Add to global marked list
	GLOB.dread_marked_humans += H

	// Start the flickering reveal for all Dread Walkers
	for(var/mob/living/simple_animal/hostile/dread_walker/walker in GLOB.dread_walkers)
		walker.BeginFlickering(H)

	return TRUE

/datum/status_effect/dread_marked/on_remove()
	if(!ishuman(owner))
		return

	var/mob/living/carbon/human/H = owner

	// Remove from global marked list
	GLOB.dread_marked_humans -= H

	// Clean up all Dread Walker images
	for(var/mob/living/simple_animal/hostile/dread_walker/walker in GLOB.dread_walkers)
		walker.flickering_targets -= H

		var/image/existing = walker.client_images[H]
		if(existing && H.client)
			H.client.images -= existing
			walker.client_images -= H

	// Notify the human
	to_chat(H, "<span class='notice'>The otherworldly presence fades from your perception...</span>")

#undef STATUS_EFFECT_DREAD_MARKED
