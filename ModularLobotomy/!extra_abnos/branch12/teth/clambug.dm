// Clambug - a TETH burrowing beetle. On breach it digs underground (invisible,
// immune, untargetable, phases through structures), wanders blind for 10 seconds,
// then hunts. Instead of biting, it surfaces onto its prey's tile, telegraphs a
// 3x3 warning, and erupts for AoE - repeating three times before it is left on
// the surface. It re-burrows after 30 seconds or the instant it drops below half.
/mob/living/simple_animal/hostile/abnormality/branch12/clambug
	name = "Clambug"
	desc = "A hunched beetle the size of a hound, its dark carapace grooved like packed earth. Its \
		soil-caked jaws never stop working."
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/48x48.dmi'
	icon_state = "clambug"
	icon_living = "clambug"
	icon_dead = "clambug_dead"
	pixel_x = -8
	base_pixel_x = -8
	del_on_death = FALSE
	maxHealth = 1200
	health = 1200
	rapid_melee = 1
	melee_queue_distance = 2
	move_to_delay = 3
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 1.3, BLACK_DAMAGE = 1, PALE_DAMAGE = 2)
	melee_damage_lower = 9
	melee_damage_upper = 14
	melee_damage_type = RED_DAMAGE
	attack_sound = 'sound/weapons/bladeslice.ogg'
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	friendly_verb_continuous = "clicks at"
	friendly_verb_simple = "click at"
	faction = list("hostile")
	can_breach = TRUE
	threat_level = TETH_LEVEL
	start_qliphoth = 2
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(60, 60, 55, 55, 50),
		ABNORMALITY_WORK_INSIGHT = list(40, 35, 30, 25, 20),
		ABNORMALITY_WORK_ATTACHMENT = list(50, 50, 45, 45, 40),
		ABNORMALITY_WORK_REPRESSION = list(45, 40, 30, 20, 0),
	)
	work_damage_amount = 6
	work_damage_type = RED_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/gluttony
	ego_list = list(
		/datum/ego_datum/weapon/branch12/chitin,
		/datum/ego_datum/armor/branch12/chitin,
	)
	gift_type = /datum/ego_gifts/branch12/chitin
	death_message = "curls up and goes still, legs folding beneath its shell."
	speak_chance = 2
	emote_see = list("clicks its mandibles...", "scrapes at the floor...")
	wander = FALSE
	observation_prompt = "The clambug presses itself to the floor, jaws grinding at the ground. Do you dig it out, or leave it be?"
	observation_choices = list(
		"Leave it be" = list(TRUE, "You let it burrow undisturbed. It settles, content to chew the earth rather than you."),
		"Dig it out" = list(FALSE, "You pry it from the soil. It thrashes, furious to be hauled into the open."),
	)

	generic_bubbles = alist(
		1 = list("%PERSON keeps well back from %ABNO's grinding jaws.", "%PERSON eyes the loose soil heaped around %ABNO's unit."),
		2 = list("%PERSON works quickly beside the restless beetle.", "%PERSON brushes churned dirt off the work console."),
		3 = list("%PERSON keeps half an eye on %ABNO's shifting soil.", "%PERSON works in time with %ABNO's grinding mandibles."),
		4 = list("%PERSON works calmly beside %ABNO.", "%PERSON scrapes packed earth from %ABNO's grooved shell."),
		5 = list("%PERSON pays %ABNO's endless chewing no mind at all.", "%PERSON works without flinching at the churning dirt."),
	)
	work_bubbles = list(
		ABNORMALITY_WORK_INSTINCT = list("%PERSON sets food down by %ABNO's working jaws."),
		ABNORMALITY_WORK_INSIGHT = list("%PERSON clears the loose soil %ABNO keeps heaping up."),
		ABNORMALITY_WORK_ATTACHMENT = list("%PERSON murmurs to the half-buried beetle."),
		ABNORMALITY_WORK_REPRESSION = list("%PERSON keeps %ABNO from settling back into the soil."),
	)

	being_tested = TRUE

	/// TRUE while underground: invisible, immune, untargetable, phasing.
	var/burrowed = FALSE
	/// TRUE during the blind wander phase - ignores all mobs and just patrols.
	var/ambush_phase = FALSE
	/// TRUE during a transition (digging) or an erupt combo - blocks re-entry.
	var/acting = FALSE
	/// Stoppable timer id for the surfaced re-burrow countdown.
	var/surface_timer
	/// Quiet burrowing ambience - also an audio tell while it is invisible underground.
	var/datum/looping_sound/clambug/soundloop
	/// Set when the next burrow should relocate it to a hallway (after the dig animation).
	var/pending_teleport = FALSE
	/// TRUE while it is below half health, so the panic dive fires once per crossing, not every tick.
	var/panicked = FALSE
	/// Gates ambient work emotes.
	var/work_emote_cooldown = 0
	/// RED damage dealt to everyone in the 3x3 on each eruption.
	var/erupt_damage = 30
	/// How long it wanders blind (ignoring mobs) after burrowing.
	var/ambush_time = 20 SECONDS
	/// Telegraph duration before each eruption.
	var/warning_time = 0.75 SECONDS
	/// How long it stays surfaced before re-burrowing.
	var/reburrow_time = 30 SECONDS
	/// pass_flags added while burrowed so it phases through structures.
	var/burrow_pass_flags = PASSTABLE | PASSGRILLE | PASSGLASS | PASSMOB | PASSMACHINE | PASSSTRUCTURE

/mob/living/simple_animal/hostile/abnormality/branch12/clambug/Initialize()
	. = ..()
	soundloop = new(list(src))

/mob/living/simple_animal/hostile/abnormality/branch12/clambug/Destroy()
	QDEL_NULL(soundloop)
	return ..()

// On breach it (usually) relocates to a hallway - it digs down where it stands, then
// surfaces somewhere in the halls. Same on the half-health panic dive.
/mob/living/simple_animal/hostile/abnormality/branch12/clambug/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	update_icon()
	if(prob(75))
		pending_teleport = TRUE
	INVOKE_ASYNC(src, PROC_REF(EnterBurrow))

// Watches for the half-health panic dive while it is exposed on the surface.
// Edge-triggered: it dives once when it crosses below half, and re-arms only after
// it climbs back above half - otherwise it would re-dive every tick and loop forever.
/mob/living/simple_animal/hostile/abnormality/branch12/clambug/Life()
	. = ..()
	if(!.)
		return
	if(health >= (maxHealth * 0.5))
		panicked = FALSE
		return
	if(panicked || burrowed || acting)
		return
	panicked = TRUE
	if(surface_timer)
		deltimer(surface_timer)
		surface_timer = null
	if(prob(75))
		pending_teleport = TRUE
	INVOKE_ASYNC(src, PROC_REF(EnterBurrow))

// Whisk itself away to a random hallway tile (faelantern style).
/mob/living/simple_animal/hostile/abnormality/branch12/clambug/proc/DoHallwayTeleport()
	if(!length(GLOB.xeno_spawn))
		return
	var/turf/destination = pick(GLOB.xeno_spawn)
	if(destination)
		forceMove(destination)

// Dig under: play the burrow animation, then vanish and start the blind wander.
/mob/living/simple_animal/hostile/abnormality/branch12/clambug/proc/EnterBurrow()
	if(burrowed || acting || stat == DEAD || (status_flags & GODMODE))
		return
	acting = TRUE
	can_act = FALSE
	obj_damage = 0
	LoseTarget()
	density = FALSE
	icon_state = "clambug_burrow"
	flick("clambug_burrow", src) // restart from frame 0 (icon_state anims are world-synced)
	playsound(get_turf(src), 'sound/effects/ordeals/amber/dawn_dig_in.ogg', 50, TRUE, 4)
	SLEEP_CHECK_DEATH(8)
	if(pending_teleport)
		pending_teleport = FALSE
		DoHallwayTeleport()
	burrowed = TRUE
	ambush_phase = TRUE
	alpha = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	pass_flags |= burrow_pass_flags
	soundloop.start()
	can_patrol = TRUE
	can_act = TRUE
	acting = FALSE
	addtimer(CALLBACK(src, PROC_REF(EndAmbushPhase)), ambush_time)

// After the blind window, allow it to acquire and hunt targets again.
/mob/living/simple_animal/hostile/abnormality/branch12/clambug/proc/EndAmbushPhase()
	if(!burrowed)
		return
	ambush_phase = FALSE

// While the blind wander is active it sees no targets, so it only patrols.
/mob/living/simple_animal/hostile/abnormality/branch12/clambug/ListTargets(max_range = vision_range)
	if(ambush_phase)
		return list()
	return ..()

// Wander to a random nearby floor tile rather than the department centers.
/mob/living/simple_animal/hostile/abnormality/branch12/clambug/SelectPatrolLocation()
	var/list/candidates = list()
	for(var/turf/open/T in RANGE_TURFS(8, src))
		if(T.density || T.is_blocked_turf(TRUE))
			continue
		candidates += T
	if(length(candidates))
		return pick(candidates)
	return ..()

// Emits no fear while underground.
/mob/living/simple_animal/hostile/abnormality/branch12/clambug/FearEffect()
	if(burrowed)
		return
	return ..()

// Cannot be hurt while underground.
/mob/living/simple_animal/hostile/abnormality/branch12/clambug/PreDamageReaction(damage_amount, damage_type, source, attack_type)
	if(burrowed)
		return FALSE
	return ..()

// Cannot be targeted by other hostiles while underground.
/mob/living/simple_animal/hostile/abnormality/branch12/clambug/CanBeAttacked()
	if(burrowed)
		return FALSE
	return ..()

// Cannot be camera-tracked while underground.
/mob/living/simple_animal/hostile/abnormality/branch12/clambug/can_track(mob/living/user)
	if(burrowed)
		return FALSE
	return ..()

// While burrowed, "biting" the target instead launches the erupt combo.
/mob/living/simple_animal/hostile/abnormality/branch12/clambug/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return
	if(burrowed)
		if(!acting && ishuman(attacked_target))
			return StartErupt(attacked_target)
		return
	return ..()

// Teleport onto the prey, telegraph, and erupt - three times, surfacing on the last.
/mob/living/simple_animal/hostile/abnormality/branch12/clambug/proc/StartErupt(mob/living/carbon/human/target)
	acting = TRUE
	can_act = FALSE
	for(var/i in 1 to 3)
		if(QDELETED(src) || stat == DEAD)
			return
		if(QDELETED(target) || target.stat == DEAD)
			break
		forceMove(get_turf(target))
		new /obj/effect/temp_visual/clambug_warning(get_turf(src))
		SLEEP_CHECK_DEATH(warning_time)
		Erupt(i == 3)
	Surface()

// The eruption itself: the bug surfaces into view wearing the tall leap sprite,
// deals a 3x3 AoE at the apex, and (on a dive) drops back out of sight. It stays
// frozen (can_act = FALSE, set by StartErupt) for the whole animation.
// Halved leap timings: dive = 3 deciseconds, land = 4 deciseconds.
/mob/living/simple_animal/hostile/abnormality/branch12/clambug/proc/Erupt(last)
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/48x96.dmi'
	icon_state = last ? "clambug_leap_land" : "clambug_leap_dive"
	flick(icon_state, src) // restart from frame 0 (icon_state anims are world-synced)
	alpha = initial(alpha)
	playsound(get_turf(src), 'sound/effects/ordeals/amber/dawn_dig_out.ogg', 60, TRUE, 5)
	SLEEP_CHECK_DEATH(2) // rise to the apex
	var/list/been_hit = list()
	for(var/turf/T in range(1, src))
		been_hit = HurtInTurf(T, been_hit, erupt_damage, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
	for(var/mob/living/carbon/human/H in range(1, src))
		if(faction_check_mob(H, FALSE))
			continue
		H.safe_throw_at(get_edge_target_turf(H, get_dir(src, H)), 2, 3, src)
	SLEEP_CHECK_DEATH(last ? 2 : 1) // let the rest of the leap play out
	icon = initial(icon)
	icon_state = "clambug"
	if(!last)
		alpha = 0 // dive back under, hidden again until the next warning

// Come up for air: restore normal, vulnerable, melee-capable state.
/mob/living/simple_animal/hostile/abnormality/branch12/clambug/proc/Surface()
	burrowed = FALSE
	ambush_phase = FALSE
	acting = FALSE
	obj_damage = 40
	soundloop.stop()
	alpha = initial(alpha)
	density = TRUE
	mouse_opacity = initial(mouse_opacity)
	pass_flags = initial(pass_flags)
	can_act = TRUE
	can_patrol = TRUE
	icon_state = "clambug"
	update_icon()
	surface_timer = addtimer(CALLBACK(src, PROC_REF(EnterBurrow)), reburrow_time, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/abnormality/branch12/clambug/update_icon_state()
	if(stat == DEAD)
		icon_state = icon_dead
		return
	if(status_flags & GODMODE)
		icon_state = "clambug"
		return
	icon_state = burrowed ? "clambug_burrow" : "clambug"

/mob/living/simple_animal/hostile/abnormality/branch12/clambug/death(gibbed)
	soundloop.stop()
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	..()

// Bad work erodes its patience directly.
/mob/living/simple_animal/hostile/abnormality/branch12/clambug/FailureEffect(mob/living/carbon/human/user, work_type, pe, work_time, canceled)
	. = ..()
	datum_reference.qliphoth_change(-1)

// Work gimmicks: it resents being studied/pinned, and nips soft-handed workers.
/mob/living/simple_animal/hostile/abnormality/branch12/clambug/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time, canceled)
	. = ..()
	if(!user)
		return
	if(work_type == ABNORMALITY_WORK_INSIGHT || work_type == ABNORMALITY_WORK_REPRESSION)
		datum_reference.qliphoth_change(-1)
		to_chat(user, span_warning("[src] bristles at being [work_type == ABNORMALITY_WORK_INSIGHT ? "studied" : "pinned down"], mandibles grinding."))
	if(get_attribute_level(user, FORTITUDE_ATTRIBUTE) < 40 && prob(60))
		user.deal_damage(rand(6, 8), RED_DAMAGE, src, attack_type = ATTACK_TYPE_MELEE)
		to_chat(user, span_danger("[src] snaps its jaws and nips you!"))

/mob/living/simple_animal/hostile/abnormality/branch12/clambug/Worktick(mob/living/carbon/human/user, bubble_type = ABNO_BALLOON_GENERIC | ABNO_BALLOON_SPECIFIC, work_type)
	. = ..()
	if(!client && work_emote_cooldown <= world.time && prob(30))
		emote(pick("clicks its mandibles", "skitters in place", "scrapes at the floor"))
		work_emote_cooldown = world.time + (12 SECONDS)

/datum/looping_sound/clambug
	mid_sounds = 'sound/effects/ordeals/amber/dusk_ambience.ogg'
	mid_length = 0.55 SECONDS
	volume = 10

/obj/effect/temp_visual/clambug_warning
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/96x96.dmi'
	icon_state = "warning"
	duration = 7.5
	randomdir = FALSE
	layer = POINT_LAYER
	pixel_x = -32
	pixel_y = -32

