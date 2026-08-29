#define FRAGMENT_SONG_COOLDOWN (14 SECONDS)

/mob/living/simple_animal/hostile/rcorp_abno/easy/fragment
	name = "Fragment of the Universe"
	desc = "An abnormality taking form of a black ball covered by 'hearts' of different colors. Just by looking at it you can hear a faint melody, avoid being within its line of sight when it sings."
	maxHealth = 800
	health = 800
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1, PALE_DAMAGE = 2)
	ranged = TRUE
	melee_damage_lower = 22
	melee_damage_upper = 25
	rapid_melee = 2
	melee_damage_type = BLACK_DAMAGE
	original_abno = /mob/living/simple_animal/hostile/abnormality/fragment

	var/song_cooldown
	var/song_cooldown_time = 10 SECONDS
	var/song_damage = 8 // Dealt 8 times

	//Visual/Animation Vars
	var/obj/effect/rca_fragment_legs/legs
	var/obj/particle_emitter/fragment_note/particle_note
	var/obj/particle_emitter/fragment_song/particle_song

	//PLAYABLES ACTIONS
	attack_action_types = list(/datum/action/cooldown/rca_fragment_song)

	abno_additional_instructions = "<h1>You are Fragment of the Universe, A Combat Role Abnormality.</h1><br>\
		<b>|Echoes of the Stars|: You are able to trigger your “Song” ability using the button on your screen or a hotkey (Spacebar by Default).<br>\
		While you are using your “Song” all humans that you see will start taking WHITE damage over time.<br>\
		This attack goes through the Rhinos mechs, which can cause the user to panic within the mech and become completely helpless.</b>"

/mob/living/simple_animal/hostile/rcorp_abno/easy/fragment/Initialize()
	..()
	icon_state = "fragment_breach"
	icon_living = "fragment_breach"


/datum/action/cooldown/rca_fragment_song
	name = "Sing"
	icon_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = "fragment"
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE
	cooldown_time = FRAGMENT_SONG_COOLDOWN //14 seconds

/datum/action/cooldown/rca_fragment_song/Trigger()
	if(!..())
		return FALSE
	if(!istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/easy/fragment))
		return FALSE
	var/mob/living/simple_animal/hostile/rcorp_abno/easy/fragment/fragment = owner
	StartCooldown()
	fragment.song()
	return TRUE

/mob/living/simple_animal/hostile/rcorp_abno/easy/fragment/Destroy()
	if(legs)
		QDEL_NULL(legs)
	if(!particle_note)
		return ..()
	particle_note.fadeout()
	particle_song.fadeout()
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/fragment/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/fragment/OpenFire()
	if(!can_act || client)
		return

	if(song_cooldown <= world.time)
		song()

/mob/living/simple_animal/hostile/rcorp_abno/easy/fragment/proc/song()
	if(song_cooldown > world.time)
		return
	can_act = FALSE
	flick("fragment_song_transition" , src)
	SLEEP_CHECK_DEATH(5)

	legs = new(get_turf(src))
	icon_state = "fragment_song_head"
	pixel_y = 5
	particle_note = new(get_turf(src))
	particle_note.pixel_y = 26
	particle_song = new(get_turf(src))
	particle_song.pixel_y = 26
	playsound(get_turf(src), 'sound/abnormalities/fragment/sing.ogg', 50, 0, 4)
	for(var/i = 1 to 8)
		//Animation for bobbing the head left to right
		switch(i)
			if(1)
				animate(src, transform = turn(matrix(), -30), time = 6, flags = SINE_EASING | EASE_OUT )
			if(3)
				animate(src, transform = turn(matrix(), 0), time = 6, flags = SINE_EASING | EASE_IN | EASE_OUT )
			if(5)
				animate(src, transform = turn(matrix(), 30), time = 6, flags = SINE_EASING | EASE_IN | EASE_OUT )
			if(7)
				animate(src, transform = turn(matrix(), 0), time = 6, flags = SINE_EASING | EASE_IN )
		//Animation -END-

		for(var/mob/living/L in view(8, src))
			if(faction_check_mob(L, FALSE))
				continue
			if(L.stat == DEAD)
				continue
			L.deal_damage(song_damage, WHITE_DAMAGE, src, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))
		SLEEP_CHECK_DEATH(3)

	animate(src, pixel_y = 0, time = 0)
	QDEL_NULL(legs)
	flick("fragment_song_transition" , src)
	SLEEP_CHECK_DEATH(5)
	icon_state = "fragment_breach"
	pixel_y = 0
	can_act = TRUE
	song_cooldown = world.time + song_cooldown_time
	if(!particle_note)
		return
	particle_note.fadeout()
	particle_song.fadeout()

//Exists so the head can be animated separatedly from the legs when it sings
/obj/effect/rca_fragment_legs
	name = "Fragment of the Universe"
	desc = "An abnormality taking form of a black ball covered by 'hearts' of different colors. Just by looking at it you can hear a faint melody, avoid being within its line of sight when it sings."
	icon = 'ModularLobotomy/_Lobotomyicons/32x48.dmi'
	icon_state = "fragment_song_legs"
	move_force = INFINITY
	pull_force = INFINITY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

#undef FRAGMENT_SONG_COOLDOWN
