// Faces in the Light - a TETH abnormality: a broken street lamp whose light no longer keeps
// the things in it at bay.
//
// Work (containment): working it goes BETTER in darkness and WORSE in bright light - keep the
//   cell dim. Working under a bright light also risks agitating it (a Qliphoth drop).
//
// Breach: it never moves. Instead it looses four "faces" into the halls and settles straight back
//   into containment (it stays workable). The faces are untouchable and near-invisible in the light,
//   and only become visible and killable in darkness (an unlit turf, or a Watchman's dark). They melee
//   for WHITE damage; if one strikes an insane employee it strips their gear, dusts them, and another
//   face is born.

/mob/living/simple_animal/hostile/abnormality/branch12/faces_in_light
	name = "Faces in the Light"
	desc = "A tall, crook-necked lamp bent over as if to read, throwing a slanted cone of pale light \
		across the floor. Faces drift up through the beam - a pair of eyes here, a grin there - and are \
		gone the moment the light shifts."
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/48x64.dmi'
	icon_state = "streetlight"
	icon_living = "streetlight"
	icon_dead = "streetlight_dead"
	pixel_x = -8
	base_pixel_x = -8
	maxHealth = 350
	health = 350
	threat_level = TETH_LEVEL
	start_qliphoth = 1
	neutral_droprate = 50	// neutral work: 50% chance to drop the counter by 1
	bad_droprate = 100		// bad work: always drops it by 1
	stat_attack = HARD_CRIT
	del_on_death = FALSE
	faction = list("hostile")
	// It is only ever a containment object - it does not emit light, so staff control the cell's dark.
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 50,
		ABNORMALITY_WORK_INSIGHT = 50,
		ABNORMALITY_WORK_ATTACHMENT = 50,
		ABNORMALITY_WORK_REPRESSION = 50,
	)
	work_damage_amount = 6
	work_damage_type = WHITE_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/gloom
	ego_list = list(
		/datum/ego_datum/weapon/branch12/gloaming,
		/datum/ego_datum/armor/branch12/gloaming,
	)
	gift_type = /datum/ego_gifts/branch12/gloaming
	observation_prompt = "The lamp flickers, and for a moment the light is thick with faces, every one of \
		them smiling at you. When it steadies they are gone. <br>Do you look closer?"
	observation_choices = list(
		"Look into the light" = list(TRUE, "You lean in. A hundred grins lean back, delighted to be seen. \
			The light feels warmer for a moment, and safer - so long as you keep looking."),
		"Look away" = list(FALSE, "You keep your eyes on your work. Something in the light stops smiling. \
			You can feel it watching the back of your neck, waiting for the dark."),
	)
	/// Loose faces, tracked by signal so they can be capped and cleaned up (better_memories.dm pattern).
	var/list/signal_tracker = list()
	/// Hard cap on how many faces may be loose at once.
	var/max_faces = 8
	/// The cross-fading faces-under-the-lamp idle visual.
	var/obj/effect/faces_in_light_glow/glow

/mob/living/simple_animal/hostile/abnormality/branch12/faces_in_light/Initialize(mapload)
	. = ..()
	status_flags |= GODMODE			// never fought; it only looses the faces
	glow = new /obj/effect/faces_in_light_glow(get_turf(src))

/mob/living/simple_animal/hostile/abnormality/branch12/faces_in_light/Destroy()
	QDEL_NULL(glow)
	for(var/mob/living/M in signal_tracker)
		UnregisterSignal(M, COMSIG_PARENT_QDELETING)
	signal_tracker.Cut()
	return ..()

// Stationary, and never attacks on its own.
/mob/living/simple_animal/hostile/abnormality/branch12/faces_in_light/Move()
	return FALSE

/mob/living/simple_animal/hostile/abnormality/branch12/faces_in_light/CanAttack(atom/the_target)
	return FALSE

// Work is easier the darker the abnormality's own tile is - but in the dark its work bites harder.
/mob/living/simple_animal/hostile/abnormality/branch12/faces_in_light/WorkChance(mob/living/carbon/human/user, chance, work_type)
	return chance + clamp(round((0.5 - TurfLight(get_turf(src))) * 40), -20, 20)

// While it sits in darkness its work damage is 50% higher.
/mob/living/simple_animal/hostile/abnormality/branch12/faces_in_light/WorktickFailure(mob/living/carbon/human/user)
	if(TurfLight(get_turf(src)) < 0.5)
		user.deal_split_damage(round(work_damage_amount * 1.5), work_damage_type, source = src, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_OTHER))
		WorkDamageEffect()
		return
	return ..()

// 0.0 (pitch dark) .. 1.0 (fully lit). Areas without dynamic lighting read as fully lit.
/mob/living/simple_animal/hostile/abnormality/branch12/faces_in_light/proc/TurfLight(turf/T)
	if(!T || !T.lighting_object)
		return 1
	return T.get_lumcount()

// It never leaves its cell. When the counter empties it just looses more faces (up to the cap) and
// settles straight back into containment - modelled on better_memories.dm's minion summoning.
/mob/living/simple_animal/hostile/abnormality/branch12/faces_in_light/ZeroQliphoth(mob/living/carbon/human/user)
	if(length(signal_tracker) >= max_faces)
		return FALSE
	status_flags |= GODMODE
	SpawnFaces(4)
	visible_message(span_userdanger("The lamp gutters, and the faces in its light peel free and scatter into the halls!"))
	playsound(get_turf(src), 'sound/effects/glassbr1.ogg', 60, TRUE)
	if(datum_reference)
		datum_reference.qliphoth_change(start_qliphoth)

/mob/living/simple_animal/hostile/abnormality/branch12/faces_in_light/proc/SpawnFaces(count)
	if(!length(GLOB.xeno_spawn))
		return
	var/list/spawns = GLOB.xeno_spawn.Copy()
	for(var/i in 1 to count)
		if(length(signal_tracker) >= max_faces)
			break
		SpawnFace(spawns.len ? pick_n_take(spawns) : pick(GLOB.xeno_spawn))

// Spawn one tracked, capped face. Faces born from consuming the insane come through here too.
/mob/living/simple_animal/hostile/abnormality/branch12/faces_in_light/proc/SpawnFace(turf/dest)
	if(!dest || length(signal_tracker) >= max_faces)
		return
	var/mob/living/simple_animal/hostile/faces_in_light_face/F = new(dest)
	F.master = src
	RegisterSignal(F, COMSIG_PARENT_QDELETING, PROC_REF(FaceSlain))
	signal_tracker += F

/mob/living/simple_animal/hostile/abnormality/branch12/faces_in_light/proc/FaceSlain(mob/living/L)
	SIGNAL_HANDLER
	signal_tracker -= L
	UnregisterSignal(L, COMSIG_PARENT_QDELETING)

/obj/effect/faces_in_light_glow
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/48x64.dmi'
	icon_state = "face_a"
	layer = ABOVE_MOB_LAYER
	alpha = 0
	pixel_x = -8	// match the body's 48-wide centring
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	var/list/faces = list("face_a", "face_b", "face_c")
	var/idx = 1

/obj/effect/faces_in_light_glow/Initialize(mapload)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(CycleFaces))

// One face fades in, holds, then fades out as the next fades in.
/obj/effect/faces_in_light_glow/proc/CycleFaces()
	set waitfor = FALSE
	while(!QDELETED(src))
		icon_state = faces[idx]
		idx = (idx % faces.len) + 1
		animate(src, alpha = 170, time = 2 SECONDS, easing = SINE_EASING)
		sleep(2.2 SECONDS)
		animate(src, alpha = 0, time = 2 SECONDS, easing = SINE_EASING)
		sleep(2.2 SECONDS)

/mob/living/simple_animal/hostile/faces_in_light_face
	name = "face"
	desc = "A pale grin and a pair of watching eyes, with nothing between them. In the light you can \
		barely make it out, and cannot seem to touch it at all."
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/32x32.dmi'
	icon_state = "face"
	icon_living = "face"
	icon_dead = "face_dead"
	maxHealth = 180
	health = 180
	melee_damage_type = WHITE_DAMAGE
	melee_damage_lower = 8
	melee_damage_upper = 12
	move_to_delay = 5
	stat_attack = HARD_CRIT
	faction = list("hostile")
	del_on_death = TRUE
	can_patrol = TRUE
	alpha = 40
	/// TRUE while it is in the light (immune + near-invisible); recomputed each Life().
	var/hidden = TRUE
	/// The lamp it came from, for cleanup / face tally.
	var/mob/living/simple_animal/hostile/abnormality/branch12/faces_in_light/master

/mob/living/simple_animal/hostile/faces_in_light_face/Initialize(mapload)
	. = ..()
	// Immune in the light via zeroed damage coeffs (not GODMODE); darkness restores them to 1.
	ChangeResistances(list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0))

// In the light: immune, near-invisible, and hits for half. In the dark: visible, vulnerable, full damage.
/mob/living/simple_animal/hostile/faces_in_light_face/Life()
	. = ..()
	if(!.)
		return
	var/turf/T = get_turf(src)
	var/dark = (T && T.lighting_object && T.get_lumcount() < 0.1)
	if(dark == hidden)		// state changed
		hidden = !dark
		if(dark)
			ChangeResistances(list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1))
			alpha = 255
			melee_damage_lower = initial(melee_damage_lower)
			melee_damage_upper = initial(melee_damage_upper)
		else
			ChangeResistances(list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0))
			alpha = 40
			melee_damage_lower = round(initial(melee_damage_lower) * 0.5)
			melee_damage_upper = round(initial(melee_damage_upper) * 0.5)

// Strikes an insane employee -> strip them, dust them, and birth another face.
/mob/living/simple_animal/hostile/faces_in_light_face/AttackingTarget(atom/attacked_target)
	if(ishuman(attacked_target))
		var/mob/living/carbon/human/H = attacked_target
		if(H.sanity_lost && H.stat != DEAD)
			ConsumeInsane(H)
			return
	return ..()

/mob/living/simple_animal/hostile/faces_in_light_face/proc/ConsumeInsane(mob/living/carbon/human/H)
	if(QDELETED(H))
		return
	visible_message(span_userdanger("[src] pours into [H], and where they stood there is only another grin!"))
	dropHardClothing(H, get_turf(H))
	H.drop_all_held_items()
	H.dust()
	if(master)
		master.SpawnFace(get_turf(src))	// a new face, tracked and capped by the lamp
