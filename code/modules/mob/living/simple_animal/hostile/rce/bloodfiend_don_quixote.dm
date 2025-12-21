// ============================================
// LA MANCHA LAND FERRIS WHEEL - Final Boss Arena
// ============================================

/obj/structure/ferris_wheel
	name = "La Mancha Land Ferris Wheel"
	desc = "A massive, corrupted ferris wheel towering over the carnival grounds. The Heart of Greed's influence pulses through its rusted frame."
	icon = 'ModularLobotomy/_Lobotomyicons/rce_bloodfiend_240x288.dmi'
	icon_state = "wheel"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE
	max_integrity = 99999
	layer = ABOVE_MOB_LAYER
	light_color = "#FF0000"
	light_range = 8
	light_power = 2
	// Large sprite offset adjustments (240x288)
	pixel_x = -104
	/// Whether the wheel has been activated
	var/activated = FALSE
	/// List of currently alive gondolas
	var/list/active_gondolas = list()
	/// Total gondolas spawned across all waves
	var/gondolas_spawned = 0
	/// Maximum total gondolas before boss spawns
	var/max_gondolas = 12
	/// Gondolas spawned per wave
	var/gondolas_per_wave = 4
	/// Total gondolas killed
	var/gondolas_killed = 0
	/// Link ID for trigger landmarks (set in map editor)
	var/link_id = "default"

/obj/structure/ferris_wheel/Initialize()
	. = ..()
	AddElement(/datum/element/point_of_interest)
	// Register in global list for trigger landmark linking
	GLOB.bloodfiend_ferris_wheels[link_id] = src

/obj/structure/ferris_wheel/Destroy()
	// Unregister from global list
	if(GLOB.bloodfiend_ferris_wheels[link_id] == src)
		GLOB.bloodfiend_ferris_wheels -= link_id
	return ..()

/obj/structure/ferris_wheel/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	Activate()

/obj/structure/ferris_wheel/bullet_act(obj/projectile/P)
	. = ..()
	Activate()

/// Activates the ferris wheel to start spawning gondolas
/obj/structure/ferris_wheel/proc/Activate()
	if(activated)
		return
	activated = TRUE
	visible_message(span_boldwarning("The ferris wheel groans to life, its corrupted gondolas detaching!"))
	playsound(src, 'sound/abnormalities/bloodbath/Bloodbath_EyeOn.ogg', 100, TRUE)
	SpawnGondolaWave()

/// Spawns a wave of gondolas
/obj/structure/ferris_wheel/proc/SpawnGondolaWave()
	if(gondolas_spawned >= max_gondolas)
		return
	var/list/spawn_turfs = list()
	// Find valid spawn turfs around the wheel
	for(var/turf/T in view(10, src))
		if(T.density)
			continue
		if(T.is_blocked_turf(exclude_mobs = TRUE))
			continue
		// Ensure some distance from wheel center
		if(get_dist(src, T) < 5)
			continue
		spawn_turfs += T
	if(!length(spawn_turfs))
		return
	// Shuffle and pick spawn positions
	spawn_turfs = shuffle(spawn_turfs)
	var/list/gondola_types = list(
		/mob/living/simple_animal/hostile/gondola_spawner/red,
		/mob/living/simple_animal/hostile/gondola_spawner/gray,
		/mob/living/simple_animal/hostile/gondola_spawner/purple
	)
	for(var/i in 1 to gondolas_per_wave)
		if(gondolas_spawned >= max_gondolas)
			break
		if(i > length(spawn_turfs))
			break
		var/turf/spawn_turf = spawn_turfs[i]
		var/gondola_type = pick(gondola_types)
		var/mob/living/simple_animal/hostile/gondola_spawner/G = new gondola_type(spawn_turf)
		G.parent_wheel = src
		active_gondolas += G
		gondolas_spawned++
		RegisterSignal(G, COMSIG_LIVING_DEATH, PROC_REF(OnGondolaDeath))
		// Trigger the drop attack
		INVOKE_ASYNC(G, TYPE_PROC_REF(/mob/living/simple_animal/hostile/gondola_spawner, DropFromSky))

/// Called when a gondola dies
/obj/structure/ferris_wheel/proc/OnGondolaDeath(mob/living/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_LIVING_DEATH)
	active_gondolas -= source
	gondolas_killed++
	// Check if wave is complete
	if(length(active_gondolas) <= 0)
		if(gondolas_killed >= max_gondolas)
			// All gondolas killed - spawn boss
			INVOKE_ASYNC(src, PROC_REF(SpawnDonQuixote))
		else
			// Spawn next wave after a delay
			addtimer(CALLBACK(src, PROC_REF(SpawnGondolaWave)), 3 SECONDS)

/// Spawns Don Quixote after all gondolas are defeated
/obj/structure/ferris_wheel/proc/SpawnDonQuixote()
	visible_message(span_boldwarning("The ferris wheel groans as its structure begins to collapse!"))
	playsound(src, 'sound/effects/ordeals/crimson/dusk_dead.ogg', 100, TRUE)
	// Change wheel to no_sign state
	icon_state = "no_sign"
	// Create the falling sign
	var/obj/structure/ferris_wheel_sign/sign = new(get_turf(src))
	sign.pixel_x = pixel_x
	sign.pixel_y = pixel_y
	// Flash yellow animation
	INVOKE_ASYNC(src, PROC_REF(SignFallSequence), sign)

/// Handles the sign falling sequence
/obj/structure/ferris_wheel/proc/SignFallSequence(obj/structure/ferris_wheel_sign/sign)
	if(QDELETED(sign))
		return
	// Flash yellow several times
	for(var/i in 1 to 4)
		sign.color = "#FFFF00"
		playsound(sign, 'sound/machines/warning-buzzer.ogg', 50, TRUE)
		sleep(0.3 SECONDS)
		sign.color = null
		sleep(0.3 SECONDS)
	if(QDELETED(sign))
		return
	// Final yellow flash before fall
	sign.color = "#FFFF00"
	playsound(sign, 'sound/machines/warning-buzzer.ogg', 75, TRUE)
	sleep(0.5 SECONDS)
	if(QDELETED(sign))
		return
	// Sign falls
	visible_message(span_boldwarning("The La Mancha Land sign breaks free and plummets!"))
	playsound(sign, 'sound/abnormalities/babayaga/land.ogg', 100, TRUE)
	animate(sign, pixel_y = sign.pixel_y - 132, time = 8, easing = QUAD_EASING | EASE_IN)
	sleep(0.8 SECONDS)
	if(QDELETED(sign))
		return
	// Impact effect
	playsound(sign, 'sound/effects/meteorimpact.ogg', 100, TRUE)
	for(var/turf/T in view(3, sign))
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(T, pick(GLOB.alldirs))
	sleep(2 SECONDS)
	// Spawn Don Quixote
	visible_message(span_boldwarning("A figure emerges from the wreckage!"))
	playsound(src, 'sound/abnormalities/bloodbath/Bloodbath_EyeOn.ogg', 100, TRUE)
	new /mob/living/simple_animal/hostile/bloodfiend_boss/don_quixote(get_turf(src))

/// The falling sign from the ferris wheel
/obj/structure/ferris_wheel_sign
	name = "La Mancha Land Sign"
	desc = "The iconic sign of La Mancha Land, now corrupted by greed."
	icon = 'ModularLobotomy/_Lobotomyicons/rce_bloodfiend_240x288.dmi'
	icon_state = "sign"
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

// ============================================
// FERRIS WHEEL ACTIVATION LANDMARK
// ============================================

/obj/effect/landmark/ferris_wheel_trigger
	name = "ferris wheel trigger"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x"
	/// Linked ferris wheel
	var/obj/structure/ferris_wheel/linked_wheel
	/// Link ID for matching to ferris wheel via global list
	var/link_id = "default"

/obj/effect/landmark/ferris_wheel_trigger/Initialize()
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/effect/landmark/ferris_wheel_trigger/LateInitialize()
	. = ..()
	// Find and link to ferris wheel via global list
	var/obj/structure/ferris_wheel/wheel = GLOB.bloodfiend_ferris_wheels[link_id]
	if(wheel)
		linked_wheel = wheel

/obj/effect/landmark/ferris_wheel_trigger/Crossed(atom/movable/AM)
	. = ..()
	if(!ishuman(AM))
		return
	if(!linked_wheel)
		return
	linked_wheel.Activate()

// ============================================
// GONDOLA SPAWNER - Stationary mob that spawns bloodfiends
// ============================================

/mob/living/simple_animal/hostile/gondola_spawner
	name = "Gondola"
	desc = "A corrupted carnival gondola, now a nest for greed-touched bloodfiends."
	icon = 'ModularLobotomy/_Lobotomyicons/rce_bloodfiend_64x64.dmi'
	icon_state = "ferrispod"
	icon_living = "ferrispod"
	pixel_x = -16
	pixel_y = -16
	faction = list("hostile")
	gender = NEUTER
	mob_biotypes = MOB_ORGANIC
	move_to_delay = 0
	stat_attack = HARD_CRIT
	maxHealth = 1500
	health = 1500
	melee_damage_lower = 0
	melee_damage_upper = 0
	obj_damage = 0
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.8, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1.2)
	del_on_death = TRUE
	/// Color for the overlay
	var/overlay_color = "#FF0000"
	/// Cached overlay appearance
	var/mutable_appearance/color_overlay
	/// Weighted spawn list for mobs
	var/list/moblist = list()
	/// List of spawned mobs
	var/list/spawned_mobs = list()
	/// Spawn cooldown tracker
	var/spawn_cooldown = 0
	/// Time between spawns
	var/spawn_cooldown_time = 10 SECONDS
	/// Number of mobs to spawn each cycle
	var/spawn_count = 2
	/// Reference to parent ferris wheel
	var/obj/structure/ferris_wheel/parent_wheel
	/// Whether the gondola has landed (can spawn mobs)
	var/landed = FALSE
	/// Beam connecting to ferris wheel
	var/datum/beam/wheel_beam

/mob/living/simple_animal/hostile/gondola_spawner/Initialize()
	. = ..()
	// Add colored overlay
	color_overlay = mutable_appearance(icon, "ferrispod_overlay")
	color_overlay.color = overlay_color
	add_overlay(color_overlay)
	// Add glow filter
	add_filter("gondola_glow", 2, list("type" = "outline", "color" = overlay_color + "50", "size" = 2))

/mob/living/simple_animal/hostile/gondola_spawner/Move()
	return FALSE // Completely stationary

/mob/living/simple_animal/hostile/gondola_spawner/CanAttack()
	return FALSE // Cannot attack

/mob/living/simple_animal/hostile/gondola_spawner/Life()
	. = ..()
	if(stat == DEAD)
		return FALSE
	if(!landed)
		return
	// Spawn mobs periodically
	if(world.time >= spawn_cooldown)
		SpawnMobs()
		spawn_cooldown = world.time + spawn_cooldown_time

/// Spawns mobs from the gondola
/mob/living/simple_animal/hostile/gondola_spawner/proc/SpawnMobs()
	if(!length(moblist))
		return
	var/list/spawn_turfs = list()
	for(var/turf/T in view(2, src))
		if(!T.density && !T.is_blocked_turf(exclude_mobs = TRUE))
			spawn_turfs += T
	if(!length(spawn_turfs))
		spawn_turfs += get_turf(src)
	for(var/i in 1 to spawn_count)
		var/mob_type = pickweight(moblist)
		var/turf/spawn_turf = pick(spawn_turfs)
		var/mob/living/spawned = new mob_type(spawn_turf)
		spawned.faction = faction.Copy()
		spawned_mobs += spawned
		// Visual effect
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(spawn_turf, pick(GLOB.alldirs))
	playsound(src, 'sound/effects/splat.ogg', 50, TRUE)

/// Drop from sky attack when spawning
/mob/living/simple_animal/hostile/gondola_spawner/proc/DropFromSky()
	var/turf/target_turf = get_turf(src)
	pixel_z = 192
	alpha = 0
	// Warning indicator - custom gondola shadow
	new /obj/effect/temp_visual/gondola_warning(target_turf)
	playsound(target_turf, 'sound/abnormalities/babayaga/charge.ogg', 50, TRUE)
	sleep(1.5 SECONDS)
	if(QDELETED(src) || stat == DEAD)
		return
	// Animate falling
	animate(src, pixel_z = 0, alpha = 255, time = 10)
	sleep(1)
	if(QDELETED(src) || stat == DEAD)
		return
	// Impact
	landed = TRUE
	playsound(src, 'sound/abnormalities/babayaga/land.ogg', 75, TRUE)
	// Create beam to turf 4 tiles above ferris wheel
	if(parent_wheel && !QDELETED(parent_wheel))
		var/turf/wheel_turf = get_turf(parent_wheel)
		var/turf/beam_target = locate(wheel_turf.x, wheel_turf.y + 4, wheel_turf.z)
		if(beam_target)
			wheel_beam = Beam(beam_target, icon_state = "blood", time = INFINITY, maxdistance = 50)
	// Deal damage in range 2
	for(var/mob/living/L in view(2, src))
		if(faction_check_mob(L, TRUE))
			continue
		L.deal_damage(150, RED_DAMAGE, src, attack_type = ATTACK_TYPE_SPECIAL)
	// Visual effects
	for(var/turf/T in view(3, src))
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(T, pick(GLOB.alldirs))
	// Start spawning immediately
	spawn_cooldown = world.time + 2 SECONDS

/mob/living/simple_animal/hostile/gondola_spawner/death(gibbed)
	// Clean up beam
	if(wheel_beam && !QDELETED(wheel_beam))
		qdel(wheel_beam)
		wheel_beam = null
	// Kill all spawned mobs
	for(var/mob/living/M in spawned_mobs)
		if(!QDELETED(M) && M.stat != DEAD)
			M.death()
	spawned_mobs.Cut()
	return ..()

// ============================================
// GONDOLA COLOR VARIANTS
// ============================================

/// Red Gondola - Spawns Fashionista bloodfiends (Area 1)
/mob/living/simple_animal/hostile/gondola_spawner/red
	overlay_color = "#FF0000"
	moblist = list(
		/mob/living/simple_animal/hostile/bloodbag/fashionista = 4,
		/mob/living/simple_animal/hostile/bloodfiend_mook/fashionista = 1
	)

/// Gray Gondola - Spawns Priest bloodfiends (Area 2)
/mob/living/simple_animal/hostile/gondola_spawner/gray
	overlay_color = "#888888"
	moblist = list(
		/mob/living/simple_animal/hostile/bloodbag/priest = 3,
		/mob/living/simple_animal/hostile/bloodbag/priest_alt = 2,
		/mob/living/simple_animal/hostile/bloodfiend_mook/priest = 1
	)

/// Purple Gondola - Spawns Parade bloodfiends (Area 3)
/mob/living/simple_animal/hostile/gondola_spawner/purple
	overlay_color = "#AA00AA"
	moblist = list(
		/mob/living/simple_animal/hostile/bloodbag/parade = 3,
		/mob/living/simple_animal/hostile/bloodfiend_mook/parade = 1,
		/mob/living/simple_animal/hostile/bloodfiend_mook/parade_alt = 1
	)

// ============================================
// GONDOLA WARNING EFFECT
// ============================================

/// Warning effect showing where a gondola will land
/obj/effect/temp_visual/gondola_warning
	name = "falling shadow"
	desc = "Something is falling!"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "warning"
	pixel_x = -32
	base_pixel_x = -32
	pixel_y = -32
	base_pixel_y = -32
	color = "#FF0000"
	alpha = 150
	pixel_x = -16
	pixel_y = -16
	duration = 1.5 SECONDS
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/gondola_warning/Initialize()
	. = ..()
	// Pulsing animation
	animate(src, alpha = 80, time = 5, loop = -1)
	animate(alpha = 150, time = 5)

// ============================================
// DON QUIXOTE - Final Boss of La Mancha Land
// ============================================

/// Don Quixote - The final boss of the bloodfiend RCE event
/mob/living/simple_animal/hostile/bloodfiend_boss/don_quixote
	name = "Don Quixote"
	desc = "The mad knight of La Mancha Land, corrupted by the Heart of Greed into an avatar of crimson avarice. He charges at windmills of flesh, dreaming of blood."
	icon = 'ModularLobotomy/_Lobotomyicons/rce_bloodfiend_32x32.dmi'
	icon_state = "don"
	icon_living = "don"
	maxHealth = 7500
	health = 7500
	melee_damage_lower = 18
	melee_damage_upper = 26
	base_damage_lower = 18
	base_damage_upper = 26
	bleed_stacks = 6
	boss_death_signal = COMSIG_GLOB_BLOODFIEND_DONQUIXOTE_DIED
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.9, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.3)
	ranged = TRUE
	/// Whether Don Quixote can currently act
	var/can_act = FALSE
	/// Whether Don Quixote has landed from spawn animation
	var/landed = FALSE
	// Line Mark Attack (Skill 1)
	/// Cooldown tracker for line mark attack
	var/line_mark_cooldown = 0
	/// Time between line mark attacks
	var/line_mark_cooldown_time = 15 SECONDS
	/// Damage dealt by line mark attack
	var/line_mark_damage = 150
	/// Range for line mark spawn
	var/line_mark_range = 7
	/// Overshoot distance for line marks
	var/line_mark_overshoot = 7
	// MultiSlash AoE (Skill 2)
	/// Cooldown tracker for multislash
	var/multislash_cooldown = 0
	/// Time between multislash attacks
	var/multislash_cooldown_time = 10 SECONDS
	/// Damage per slash
	var/multislash_damage = 50
	/// Radius of the slash AoE
	var/multislash_radius = 2
	/// Range of the slash attack
	var/multislash_range = 4
	/// Number of slashes
	var/multislash_amount = 15
	/// Speed between slashes (deciseconds)
	var/multislash_speed = 1.5
	/// Charge time before slashing
	var/multislash_charge_time = 1.5 SECONDS
	// Drain Beam Attack (Skill 3)
	/// Cooldown tracker for drain beam
	var/drain_cooldown = 0
	/// Time between drain beam attacks
	var/drain_cooldown_time = 30 SECONDS
	/// Range for drain beam
	var/drain_range = 7
	/// Duration of drain effect
	var/drain_duration = 6
	/// Base damage for leaving the drain (doubles each second)
	var/drain_base_damage = 5
	/// Blood gained per human that breaks connection
	var/drain_blood_per_human = 100
	// Tracking Shots (Skill 4)
	/// Cooldown tracker for tracking shots
	var/tracking_shot_cooldown = 0
	/// Time between tracking shots
	var/tracking_shot_cooldown_time = 2.5 SECONDS
	/// Cached magic circle for cleanup
	var/obj/effect/don_quixote_magic_circle/magic_circle
	/// Lines spoken during line mark attack
	var/list/line_mark_lines = list(
		"My lance shall pierce through all who stand before me!",
		"You cannot escape my reach!",
		"The blood of my enemies shall flow!",
		"Face the charge of Don Quixote!"
	)
	/// Lines spoken during multislash attack
	var/list/multislash_lines = list(
		"A thousand cuts for my family!",
		"Each slash... is for those I failed!",
		"My blade dances with the weight of centuries!",
		"FEEL THE FURY OF LA MANCHA!!"
	)
	/// Lines spoken during drain attack
	var/list/drain_lines = list(
		"Your blood... shall join our collection!",
		"The Heart demands tribute!",
		"Stay close... let me take everything from you!",
		"This feast is far from over!"
	)
	/// Whether to announce victory when Don Quixote dies
	var/announce_victory_on_death = TRUE

/mob/living/simple_animal/hostile/bloodfiend_boss/don_quixote/Initialize()
	. = ..()
	// Immune to damage until landed
	status_flags |= GODMODE
	// Start floating above ground
	pixel_y = 20
	// Begin landing sequence after short delay
	addtimer(CALLBACK(src, PROC_REF(LandingSequence)), 0.5 SECONDS)

/// Handles the dramatic landing sequence
/mob/living/simple_animal/hostile/bloodfiend_boss/don_quixote/proc/LandingSequence()
	playsound(src, 'sound/abnormalities/bloodbath/Bloodbath_EyeOn.ogg', 100, TRUE)
	// Animate floating down
	animate(src, pixel_y = 0, time = 1.5 SECONDS, easing = QUAD_EASING | EASE_IN)
	sleep(1.5 SECONDS)
	if(QDELETED(src) || stat == DEAD)
		return
	// Landing impact
	landed = TRUE
	status_flags &= ~GODMODE // No longer immune to damage
	playsound(src, 'sound/abnormalities/babayaga/land.ogg', 100, TRUE)
	playsound(src, 'sound/effects/meteorimpact.ogg', 100, TRUE)
	// Screen shake and knockdown all humans in range 7
	for(var/mob/living/carbon/human/H in view(7, src))
		if(!faction_check_mob(H))
			H.Knockdown(2 SECONDS)
			shake_camera(H, 4, 3)
	// Create floor effect on all turfs in range 5
	for(var/turf/T in view(5, src))
		new /obj/effect/temp_visual/cult/turf/floor(T)
	// Speech after landing
	sleep(1 SECONDS)
	if(QDELETED(src) || stat == DEAD)
		return
	say("Two centuries... Two centuries I kept them safe within these walls. My children. My family.")
	sleep(3 SECONDS)
	if(QDELETED(src) || stat == DEAD)
		return
	say("I had a dream. A foolish dream... that we could live alongside humans. That we could resist our hunger.")
	sleep(3 SECONDS)
	if(QDELETED(src) || stat == DEAD)
		return
	say("But that dream only brought them suffering. Centuries of starvation. Isolation. Madness.")
	sleep(3 SECONDS)
	if(QDELETED(src) || stat == DEAD)
		return
	say("Dulcinea... The Barber... The Priest... They broke because of MY dream. MY failure.")
	sleep(3 SECONDS)
	if(QDELETED(src) || stat == DEAD)
		return
	say("When the Heart offered them peace... how could I deny them? How could I watch them suffer more?")
	sleep(3 SECONDS)
	if(QDELETED(src) || stat == DEAD)
		return
	say("Now we are bound together, forever. And you... you will join our collection.")
	sleep(2 SECONDS)
	if(QDELETED(src) || stat == DEAD)
		return
	can_act = TRUE
	// Initialize cooldowns
	line_mark_cooldown = world.time + 5 SECONDS
	multislash_cooldown = world.time + 3 SECONDS
	drain_cooldown = world.time + 10 SECONDS
	tracking_shot_cooldown = world.time + 2 SECONDS

/mob/living/simple_animal/hostile/bloodfiend_boss/don_quixote/Life()
	. = ..()
	if(stat == DEAD || !can_act || !landed)
		return FALSE
	// Tracking shots every 2.5 seconds
	if(world.time >= tracking_shot_cooldown)
		SpawnTrackingMark()
		tracking_shot_cooldown = world.time + tracking_shot_cooldown_time

/mob/living/simple_animal/hostile/bloodfiend_boss/don_quixote/OpenFire()
	if(!can_act || !landed)
		return
	// Priority: Drain > MultiSlash > Line Marks
	if(drain_cooldown <= world.time)
		DrainBeamAttack()
		return
	if(target && get_dist(src, target) <= multislash_range + 1 && multislash_cooldown <= world.time)
		BloodMultiSlash()
		return
	if(line_mark_cooldown <= world.time)
		LineMarkAttack()

/mob/living/simple_animal/hostile/bloodfiend_boss/don_quixote/face_atom(atom/A)
	if(!can_act)
		return
	. = ..()

/mob/living/simple_animal/hostile/bloodfiend_boss/don_quixote/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/bloodfiend_boss/don_quixote/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/bloodfiend_boss/don_quixote/death(gibbed)
	// Clean up magic circle if any
	if(magic_circle && !QDELETED(magic_circle))
		qdel(magic_circle)
	// Announce victory if enabled
	if(announce_victory_on_death)
		SSgame_director.AnnounceVictory()
	return ..()

// ============================================
// DON QUIXOTE - SKILL 1: LINE MARK ATTACK
// ============================================

/// Spawns marks that fire line attacks at the nearest human
/mob/living/simple_animal/hostile/bloodfiend_boss/don_quixote/proc/LineMarkAttack()
	line_mark_cooldown = world.time + line_mark_cooldown_time
	can_act = FALSE
	// Calculate mark count based on bloodfeast
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	var/blood_percent = 0
	if(bloodfeast)
		blood_percent = bloodfeast.blood_amount / max_blood
	var/num_marks = 2 + FLOOR(blood_percent / 0.25, 1)
	num_marks = clamp(num_marks, 2, 6)
	// Calculate damage multiplier
	var/damage_mult = 1 + (blood_percent * 0.5)
	var/actual_damage = round(line_mark_damage * damage_mult)
	// Find valid turfs for marks
	var/list/possible_turfs = list()
	for(var/turf/T in view(line_mark_range, src))
		if(T.density)
			continue
		if(get_dist(src, T) < 2)
			continue // Not right next to Don Quixote
		possible_turfs += T
	if(!length(possible_turfs))
		can_act = TRUE
		return
	playsound(src, 'sound/abnormalities/nosferatu/special_start.ogg', 75, TRUE)
	if(prob(40))
		say(pick(line_mark_lines))
	manual_emote("raises their lance, marking targets!")
	// Spawn marks
	var/list/marks = list()
	var/list/mark_data = list() // Store attack lines for each mark
	for(var/i in 1 to num_marks)
		if(!length(possible_turfs))
			break
		var/turf/mark_turf = pick(possible_turfs)
		possible_turfs -= mark_turf
		// Find nearest human to Don Quixote (not to the mark)
		var/mob/living/carbon/human/nearest_human
		var/nearest_dist = INFINITY
		for(var/mob/living/carbon/human/H in view(line_mark_range + 5, src))
			if(faction_check_mob(H))
				continue
			var/dist = get_dist(src, H)
			if(dist < nearest_dist)
				nearest_dist = dist
				nearest_human = H
		if(!nearest_human)
			continue
		// Create the mark
		var/obj/effect/don_quixote_mark/mark = new(mark_turf)
		marks += mark
		// Calculate line: mark -> human -> overshoot
		var/turf/target_turf = get_turf(nearest_human)
		var/direction = get_dir(mark_turf, target_turf)
		var/turf/end_turf = get_ranged_target_turf(target_turf, direction, line_mark_overshoot)
		// Orient the mark toward target
		mark.OrientToward(target_turf)
		// Build the attack line with 3x3 AoE around each turf
		var/list/attack_line = list()
		for(var/turf/T in getline(mark_turf, end_turf))
			if(T.density)
				break
			// Add 3x3 area around each turf in the line (radius 1 = 3x3)
			for(var/turf/open/TT in RANGE_TURFS(1, T))
				attack_line |= TT
		// Show warning sparks
		for(var/turf/T in attack_line)
			new /obj/effect/temp_visual/cult/sparks(T)
		// Create warning beam from mark to end point
		var/datum/beam/warning_beam
		if(end_turf)
			warning_beam = mark.Beam(end_turf, icon_state = "blood", time = 1.5 SECONDS, maxdistance = 50)
		// Store data for damage phase
		mark_data[mark] = list("line" = attack_line, "end" = end_turf, "warning_beam" = warning_beam)
	// Warning delay
	SLEEP_CHECK_DEATH(1.5 SECONDS)
	// Damage phase
	playsound(src, 'sound/weapons/ego/censored2.ogg', 100, TRUE)
	for(var/obj/effect/don_quixote_mark/mark in marks)
		if(QDELETED(mark))
			continue
		var/list/data = mark_data[mark]
		if(!data)
			continue
		var/list/attack_line = data["line"]
		var/turf/end_turf = data["end"]
		// Create beam from mark to end
		if(end_turf)
			mark.Beam(end_turf, icon_state = "blood_beam", time = 10, maxdistance = 50)
		// Deal damage along line
		var/list/been_hit = list()
		for(var/turf/T in attack_line)
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(T, pick(GLOB.alldirs))
			for(var/mob/living/L in HurtInTurf(T, been_hit, actual_damage, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL)))
				L.apply_lc_bleed(bleed_stacks)
				been_hit += L
			// Damage barricades
			for(var/obj/structure/barricade/B in T)
				B.take_damage(actual_damage * 2, RED_DAMAGE)
	// Clean up marks
	QDEL_LIST(marks)
	SLEEP_CHECK_DEATH(0.5 SECONDS)
	can_act = TRUE

// ============================================
// DON QUIXOTE - SKILL 2: BLOOD MULTISLASH
// ============================================

/// Enhanced MultiSlash attack based on pale_fixer
/mob/living/simple_animal/hostile/bloodfiend_boss/don_quixote/proc/BloodMultiSlash()
	multislash_cooldown = world.time + multislash_cooldown_time
	can_act = FALSE
	// Face target
	if(target)
		face_atom(target)
	var/turf/slash_start = get_turf(src)
	var/turf/slash_end = get_ranged_target_turf_direct(slash_start, target, multislash_range)
	var/dir_to_target = get_dir(slash_start, slash_end)
	// Create magic circle behind Don Quixote (like hatred_queen's ArcanaBeats)
	magic_circle = new /obj/effect/don_quixote_magic_circle(get_turf(src))
	switch(dir)
		if(EAST)
			magic_circle.pixel_x += 16
			var/matrix/new_matrix = matrix()
			new_matrix.Scale(0.5, 1)
			magic_circle.transform = new_matrix
			magic_circle.layer = layer + 0.1
		if(WEST)
			magic_circle.pixel_x -= 16
			var/matrix/new_matrix = matrix()
			new_matrix.Scale(0.5, 1)
			magic_circle.transform = new_matrix
			magic_circle.layer = layer + 0.1
		if(SOUTH)
			magic_circle.pixel_y -= 16
			magic_circle.layer = layer + 0.1
		if(NORTH)
			magic_circle.pixel_y += 16
			magic_circle.layer = layer - 0.1
	// Calculate damage multiplier based on bloodfeast
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	var/damage_mult = 1
	if(bloodfeast)
		var/blood_percent = bloodfeast.blood_amount / max_blood
		damage_mult = 1 + (blood_percent * 0.5)
	var/actual_damage = round(multislash_damage * damage_mult)
	// Build hit area
	var/list/hitline = list()
	for(var/turf/T in getline(slash_start, slash_end))
		if(T.density)
			break
		for(var/turf/open/TT in RANGE_TURFS(multislash_radius, T))
			hitline |= TT
	// Warning phase - sparks on all affected turfs
	for(var/turf/open/T in hitline)
		new /obj/effect/temp_visual/cult/sparks(T)
	playsound(src, 'sound/abnormalities/bloodbath/Bloodbath_EyeOn.ogg', 75, TRUE)
	say(pick(multislash_lines))
	manual_emote("prepares a devastating flurry!")
	// Charge time
	SLEEP_CHECK_DEATH(multislash_charge_time)
	// Execute multislash
	playsound(src, 'sound/weapons/fixer/generic/blade3.ogg', 100, TRUE)
	var/total_hits = 0
	for(var/i = 1 to multislash_amount)
		if(QDELETED(src) || stat == DEAD)
			break
		for(var/turf/open/T in hitline)
			var/obj/effect/temp_visual/dir_setting/slash/S = new(T, dir_to_target)
			S.pixel_x = rand(-8, 8)
			S.pixel_y = rand(-8, 8)
			S.color = "#FF0000" // Red coded
			animate(S, alpha = 0, time = 1.5)
			for(var/mob/living/L in HurtInTurf(T, list(), actual_damage, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, hurt_structure = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)))
				to_chat(L, span_userdanger("[src] slashes you!"))
				new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(L), dir_to_target)
				total_hits++
			// Damage barricades
			for(var/obj/structure/barricade/B in T)
				B.take_damage(actual_damage, RED_DAMAGE)
		playsound(src, attack_sound, 50, TRUE, 3)
		sleep(multislash_speed)
	playsound(src, 'sound/effects/ordeals/crimson/dusk_dead.ogg', 75, FALSE, 7)
	// Clean up magic circle
	if(magic_circle && !QDELETED(magic_circle))
		qdel(magic_circle)
		magic_circle = null
	// Generate bloodfeast from hits
	if(bloodfeast && total_hits > 0)
		bloodfeast.blood_amount = min(bloodfeast.blood_amount + (total_hits * 25), max_blood)
		last_blood_check = -1
	SLEEP_CHECK_DEATH(0.5 SECONDS)
	can_act = TRUE

// ============================================
// DON QUIXOTE - SKILL 3: DRAIN BEAM ATTACK
// ============================================

/// Tethers all humans in range and punishes them for leaving
/mob/living/simple_animal/hostile/bloodfiend_boss/don_quixote/proc/DrainBeamAttack()
	drain_cooldown = world.time + drain_cooldown_time
	can_act = FALSE
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	playsound(src, 'sound/abnormalities/nosferatu/special_start.ogg', 100, TRUE)
	say(pick(drain_lines))
	manual_emote("extends blood tendrils, binding all nearby!")
	// Change resistances while draining - 0.2 to all damage types
	ChangeResistances(list(BRUTE = 0.2, RED_DAMAGE = 0.2, WHITE_DAMAGE = 0.2, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 0.2))
	// Find all humans in range
	var/list/drain_targets = list() // human -> beam
	for(var/mob/living/carbon/human/H in view(drain_range, src))
		if(faction_check_mob(H))
			continue
		var/datum/beam/B = Beam(H, icon_state = "drainbeam", time = INFINITY, maxdistance = 50)
		drain_targets[H] = B
	if(!length(drain_targets))
		// Restore normal resistances
		ChangeResistances(list(BRUTE = 1, RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.9, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.3))
		can_act = TRUE
		return
	// Process drain for 6 seconds
	var/current_damage = drain_base_damage
	var/loops_completed = 0
	for(var/loop in 1 to drain_duration)
		sleep(1 SECONDS)
		if(QDELETED(src) || stat == DEAD)
			// Clean up beams
			for(var/mob/living/H in drain_targets)
				var/datum/beam/B = drain_targets[H]
				if(B && !QDELETED(B))
					qdel(B)
			// Restore normal resistances
			ChangeResistances(list(BRUTE = 1, RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.9, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.3))
			can_act = TRUE
			return
		loops_completed++
		// Check each target
		var/list/to_remove = list()
		for(var/mob/living/carbon/human/H in drain_targets)
			if(QDELETED(H) || H.stat == DEAD)
				to_remove += H
				continue
			// Check if still in range
			if(!(H in view(drain_range, src)))
				// They left range - clean up their beam, no more damage
				var/datum/beam/B = drain_targets[H]
				if(B && !QDELETED(B))
					qdel(B)
				to_remove += H
			else
				// Still in range - deal drain damage and gain bloodfeast
				H.deal_damage(current_damage, RED_DAMAGE, src, attack_type = ATTACK_TYPE_SPECIAL)
				new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(H), pick(GLOB.alldirs))
				if(bloodfeast)
					bloodfeast.blood_amount = min(bloodfeast.blood_amount + 100, max_blood)
					last_blood_check = -1
		// Remove escaped/dead targets
		for(var/mob/living/H in to_remove)
			drain_targets -= H
		// Double damage for next loop
		current_damage *= 2
	// End of drain - deal scaling burst to anyone still connected
	for(var/mob/living/carbon/human/H in drain_targets)
		if(!QDELETED(H) && H.stat != DEAD)
			// Scaling damage based on loops completed
			var/final_damage = drain_base_damage * (2 ** loops_completed)
			H.deal_damage(final_damage, RED_DAMAGE, src, attack_type = ATTACK_TYPE_SPECIAL)
			to_chat(H, span_userdanger("The blood tendrils constrict violently!"))
			playsound(H, 'sound/effects/ordeals/crimson/dusk_dead.ogg', 50, TRUE)
		// Clean up beam
		var/datum/beam/B = drain_targets[H]
		if(B && !QDELETED(B))
			qdel(B)
	drain_targets.Cut()
	// Restore normal resistances
	ChangeResistances(list(BRUTE = 1, RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.9, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.3))
	SLEEP_CHECK_DEATH(0.5 SECONDS)
	can_act = TRUE

// ============================================
// DON QUIXOTE - SKILL 4: TRACKING PROJECTILES
// ============================================

/// Spawns 3-4 small marks that target and fire at the nearest human
/mob/living/simple_animal/hostile/bloodfiend_boss/don_quixote/proc/SpawnTrackingMark()
	// Find turfs in view 6, but not right next to Don Quixote
	var/list/possible_turfs = list()
	for(var/turf/T in view(6, src))
		if(T.density)
			continue
		if(get_dist(src, T) < 2)
			continue // Not right next to him
		possible_turfs += T
	if(!length(possible_turfs))
		return
	// Find nearest human
	var/mob/living/carbon/human/nearest_human
	var/nearest_dist = INFINITY
	for(var/mob/living/carbon/human/H in view(10, src))
		if(faction_check_mob(H))
			continue
		var/dist = get_dist(src, H)
		if(dist < nearest_dist)
			nearest_dist = dist
			nearest_human = H
	if(!nearest_human)
		return
	// Spawn 3-4 marks on random turfs
	var/num_marks = rand(3, 4)
	for(var/i in 1 to num_marks)
		if(!length(possible_turfs))
			break
		var/turf/mark_turf = pick(possible_turfs)
		possible_turfs -= mark_turf
		var/obj/effect/don_quixote_tracking_mark/mark = new(mark_turf)
		mark.target_human = nearest_human
		mark.owner_don = src
	// Mark handles its own beam and projectile firing

// ============================================
// DON QUIXOTE - HELPER OBJECTS
// ============================================

/// Large magic circle for Don Quixote's line mark attack
/obj/effect/don_quixote_mark
	name = "blood mark"
	desc = "A swirling circle of blood magic."
	icon = 'icons/effects/effects.dmi'
	icon_state = "fellcircle"
	pixel_x = 8
	base_pixel_x = 8
	pixel_y = 8
	base_pixel_y = 8
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	color = "#FF0000"

/obj/effect/don_quixote_mark/Initialize()
	. = ..()
	// Pulsing animation
	animate(src, alpha = 150, time = 3, loop = -1)
	animate(alpha = 255, time = 3)

/// Orients the mark to face a target turf using matrix transform
/obj/effect/don_quixote_mark/proc/OrientToward(turf/target_turf)
	if(!target_turf)
		return
	var/matrix/M = matrix(transform)
	M.Translate(0, 16)
	var/rot_angle = Get_Angle(get_turf(src), target_turf)
	M.Turn(rot_angle)
	transform = M

/// Magic circle that appears behind Don Quixote during multislash (like hatred_queen's sigil)
/obj/effect/don_quixote_magic_circle
	name = "blood circle"
	desc = "A massive circle of blood magic."
	icon = 'icons/effects/effects.dmi'
	icon_state = "fellcircle"
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	color = "#FF0000"

/obj/effect/don_quixote_magic_circle/Initialize()
	. = ..()
	// Pulsing animation
	animate(src, alpha = 150, time = 5, loop = -1)
	animate(alpha = 255, time = 5)

/// Small tracking mark that fires projectiles
/obj/effect/don_quixote_tracking_mark
	name = "targeting mark"
	desc = "A small blood mark tracking a target."
	icon = 'icons/effects/eldritch.dmi'
	icon_state = "blood_cloud_swirl"
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	color = "#FF0000"
	/// Reference to the target human
	var/mob/living/carbon/human/target_human
	/// Reference to Don Quixote
	var/mob/living/simple_animal/hostile/bloodfiend_boss/don_quixote/owner_don
	/// Beam to target
	var/datum/beam/target_beam

/obj/effect/don_quixote_tracking_mark/Initialize()
	. = ..()
	// Start the targeting sequence
	addtimer(CALLBACK(src, PROC_REF(CreateBeam)), 1)
	addtimer(CALLBACK(src, PROC_REF(FireProjectile)), 1 SECONDS)
	QDEL_IN(src, 1.5 SECONDS)

/obj/effect/don_quixote_tracking_mark/proc/CreateBeam()
	if(!target_human || QDELETED(target_human))
		return
	target_beam = Beam(target_human, icon_state = "blood", time = 1 SECONDS, maxdistance = 50)
	playsound(src, 'sound/magic/charge.ogg', 25, TRUE)

/obj/effect/don_quixote_tracking_mark/proc/FireProjectile()
	if(!target_human || QDELETED(target_human) || target_human.stat == DEAD)
		return
	if(!owner_don || QDELETED(owner_don) || owner_don.stat == DEAD)
		return
	// Fire piercing projectile at target
	var/obj/projectile/ego_bullet/don_quixote/P = new(get_turf(src))
	P.firer = owner_don
	P.original = target_human
	P.preparePixelProjectile(target_human, src)
	P.fire()
	playsound(src, 'sound/weapons/fixer/generic/nail1.ogg', 50, TRUE)

/obj/effect/don_quixote_tracking_mark/Destroy()
	if(target_beam && !QDELETED(target_beam))
		qdel(target_beam)
	target_human = null
	owner_don = null
	return ..()

/// Don Quixote's piercing blood lance projectile
/obj/projectile/ego_bullet/don_quixote
	name = "blood lance"
	icon_state = "banquet"
	damage = 75
	damage_type = RED_DAMAGE

/obj/projectile/ego_bullet/don_quixote/Initialize()
	. = ..()
	// Make it piercing
	projectile_piercing = ALL

/obj/projectile/ego_bullet/don_quixote/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	if(isliving(target))
		var/mob/living/L = target
		L.apply_lc_bleed(10)
		playsound(target, 'sound/weapons/fixer/generic/nail1.ogg', 75, TRUE)
		for(var/i in 1 to 2)
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(target), pick(GLOB.alldirs))
