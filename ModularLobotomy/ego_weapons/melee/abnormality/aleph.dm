/obj/item/ego_weapon/paradise
	name = "paradise lost"
	desc = "\"Behold: you stood at the door and knocked, and it was opened to you. \
	I come from the end, and I am here to stay for but a moment.\""
	special = "This weapon has a ranged attack."
	icon_state = "paradise"
	worn_icon_state = "paradise"
	force = 70
	damtype = PALE_DAMAGE
	attack_verb_continuous = list("purges", "purifies")
	attack_verb_simple = list("purge", "purify")
	hitsound = 'sound/weapons/ego/paradise.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100,
	)
	var/ranged_cooldown
	var/ranged_cooldown_time = 0.8 SECONDS
	var/ranged_damage = 70

/obj/item/ego_weapon/paradise/afterattack(atom/A, mob/living/user, proximity_flag, params)
	if(ranged_cooldown > world.time)
		return
	if(!CanUseEgo(user))
		return
	var/turf/target_turf = get_turf(A)
	if(!istype(target_turf))
		return
	if((get_dist(user, target_turf) < 2) || !(target_turf in view(10, user)))
		return
	..()
	var/mob/living/carbon/human/H = user
	ranged_cooldown = world.time + ranged_cooldown_time
	playsound(target_turf, 'sound/weapons/ego/paradise_ranged.ogg', 50, TRUE)
	var/damage_dealt = 0
	var/modified_damage = (ranged_damage*force_multiplier)
	for(var/turf/open/T in range(target_turf, 1))
		new /obj/effect/temp_visual/paradise_attack(T)
		for(var/mob/living/L in user.HurtInTurf(T, list(), modified_damage, PALE_DAMAGE, hurt_mechs = TRUE))
			if((L.stat < DEAD) && !(L.status_flags & GODMODE))
				damage_dealt += modified_damage
	if(damage_dealt > 0)
		H.adjustStaminaLoss(-damage_dealt*0.2)
		H.adjustBruteLoss(-damage_dealt*0.1)
		H.adjustFireLoss(-damage_dealt*0.1)
		H.adjustSanityLoss(-damage_dealt*0.1)

/obj/item/ego_weapon/paradise/get_clamped_volume()
	return 40

/obj/item/ego_weapon/justitia
	name = "justitia"
	desc = "A sharp sword covered in bandages. It may be able to not only cut flesh but trace of sins as well."
	special = "This weapon has a combo system."
	icon_state = "justitia"
	force = 25
	damtype = PALE_DAMAGE
	attack_verb_continuous = list("attacks", "slashes", "stabs", "slices", "tears", "lacerates", "rips", "dices", "cuts")
	attack_verb_simple = list("attack", "slash", "stab", "slice", "tear", "lacerate", "rip", "dice", "cut")
	hitsound = 'sound/weapons/ego/justitia1.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 100
							)
	crit_multiplier = 0	//No crits for you, you have the combo system.

	var/combo = 0
	/// Maximum world.time after which combo is reset
	var/combo_time
	/// Wait time between attacks for combo to reset
	var/combo_wait = 10

/obj/item/ego_weapon/justitia/attack(mob/living/M, mob/living/user)
	if(!CanUseEgo(user))
		return
	if(world.time > combo_time)
		combo = 0
	combo_time = world.time + combo_wait
	switch(combo)
		if(5)
			hitsound = 'sound/weapons/ego/justitia2.ogg'
			force *= 1.5
			user.changeNext_move(CLICK_CD_MELEE * 0.5)
		if(1,4)
			hitsound = 'sound/weapons/ego/justitia3.ogg'
			user.changeNext_move(CLICK_CD_MELEE * 0.3)
		if(6)
			hitsound = 'sound/weapons/ego/justitia4.ogg'
			combo = -1
			user.changeNext_move(CLICK_CD_MELEE * 1.2)
			var/turf/T = get_turf(M)
			new /obj/effect/temp_visual/justitia_effect(T)
			user.HurtInTurf(T, list(), 50, PALE_DAMAGE)
		else
			hitsound = 'sound/weapons/ego/justitia1.ogg'
			user.changeNext_move(CLICK_CD_MELEE * 0.4)
	..()
	combo += 1
	force = initial(force)

/obj/item/ego_weapon/justitia/get_clamped_volume()
	return 40


/// This scythe attacks quickly for a good amount of WHITE damage with a 3-hit combo.
/// It has a special ability that summons three musical notes around you - landing the combo finisher in one will deal a lot of damage in an AoE,
/// and buff the weapon by increasing its "Movement", from the first movement up until the fourth.
// The intended gameplay loop with this weapon is to "space out" the music note detonations to prolong Movement for as long as possible. That is to say,
// you should perform some normal combos on an enemy rather than spending all the finishers on musical notes.
#define DA_CAPO_MUSICNOTE_DEFAULT "default"
/obj/item/ego_weapon/da_capo
	name = "da capo"
	desc = "A scythe that swings silently and with discipline like a conductor's gestures and baton. \
	If there were a score for this song, it would be one that sings of the apocalypse."
	special = "This weapon has a 3-hit combo, but only against the same target. <b>Use it in-hand</b> to spawn 3 musical notes around yourself.\
	\nLanding your combo's finisher on one of these musical notes will <b>detonate it</b>, dealing 1.2x of the resulting damage in an AoE.\
	\nDetonating a musical note will also advance your <b>Movement</b>. You begin at the First Movement, and can reach up to the Fourth. \
	Each Movement increases your weapon's damage further. <b>Reaching the Fourth Movement unlocks Finale</b>, a 6-hit combo with a powerful AoE finisher.\
	\nYour Movement will <b>expire after 7 seconds</b> if it is not replaced by the next. You will begin anew from the First Movement if you progress past the Fourth."
	icon_state = "da_capo"
	force = 37 // It attacks very fast
	attack_speed = 0.5
	swingstyle = WEAPONSWING_LARGESWEEP
	damtype = WHITE_DAMAGE
	attack_verb_continuous = list("slashes", "slices", "rips", "cuts")
	attack_verb_simple = list("slash", "slice", "rip", "cut")
	hitsound = 'sound/weapons/ego/da_capo1.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)
	crit_multiplier = 0	// No crits for you, you have the combo system.

	var/combo = 0 // I am copy-pasting justitia "combo" system and nobody can stop me
	/// The time at which your combo will reset.
	var/combo_time
	/// How large your window to continue your combo is, in deciseconds.
	var/combo_timeout_duration = 16

	/// Damage multiplier for the third hit in the basic combo.
	var/combo_3hit_finisher_coeff = 1.5
	/// Damage multiplier for the sixth hit in the final "Finale" combo.
	var/combo_6hit_finisher_coeff = 3

	var/waltz_partner // I'm making Da Capo a waltzing weapon, it should play like a rhythm game - Kirie

	/// Current movement. Think of it as a power level. This should always be a number between 1 and 4.
	var/current_movement = 1
	/// We use current_movement as the index for this list. The corresponding value is added to force before each hit.
	var/list/movement_force_bonuses = list(0, 6, 10, 14)
	/// Holds a timer datum for our current Movement's expiration.
	var/movement_timer
	/// How long our movement lasts before expiring.
	var/movement_timer_duration = 7 SECONDS

	/// This is a ring VFX around the user. Non functional, purely aesthetic.
	var/obj/effect/temp_visual/da_capo_ring/music_notes_ring

	/// List which holds a reference to all active music notes for this weapon.
	var/list/music_notes_list = list()
	/// Are we ready to summon more music notes?
	var/music_notes_ready = TRUE
	/// Holds a timer datum for refreshing our ability to summon notes.
	var/music_notes_summon_timer
	/// How long is the cooldown on summoning notes?
	var/music_notes_summon_timer_duration = 40 SECONDS
	/// How many notes should be summoned on each use? This should probably always be 3. I mean, that's how I balanced it, at least.
	var/music_notes_summon_amount = 3
	/// Range for the AoE when a music note is blown up.
	var/music_notes_detonation_range = 5
	/// Coefficient for the damage dealt by music notes, this is applied on top of force and justice.
	var/music_notes_damage_coeff = 1.2
	/// How long it takes for each music note to complete 1 revolution around the user.
	var/music_notes_aesthetic_rotation_time = 4 SECONDS

	/// Any organic mob killed by a Soundwave() which has a maximum health higher than this value will be headbombed, which is purely aesthetic.
	// The reason for this is because I don't want to headbomb swarms of weak enemies like Amber Dawns.
	var/headbomb_hp_requirement = 150

/obj/item/ego_weapon/da_capo/attack(mob/living/M, mob/living/user)
	if(!CanUseEgo(user))
		return

	// If the mob we hit was a note, save it in the following var. Otherwise keep it as null
	var/mob/da_capo_musicnote/hit_note
	if(istype(M, /mob/da_capo_musicnote))
		hit_note = M

	var/finished_combo = FALSE // This var will be set to TRUE if we land a hit with the final hit of the 3hit combo or 6hit combo.

	force = initial(force) + movement_force_bonuses[current_movement] // Pick the correct force bonus to add depending on what Movement we're on.
	attack_speed = initial(attack_speed)

	// Your combo cancels if you took too long to hit the enemy, or if you didn't hit your "partner".
	if(world.time > combo_time)
		combo = 0
	if((!hit_note) && ((!waltz_partner) || (waltz_partner != M)))
		combo = 0
		waltz_partner = M

	combo_time = world.time + combo_timeout_duration

	if(current_movement < 4)
		// The code for the 3-hit combo.
		switch(combo)
			if(1)
				hitsound = 'sound/weapons/ego/da_capo2.ogg'
			if(2)
				hitsound = 'sound/weapons/ego/da_capo3.ogg'
				force *= combo_3hit_finisher_coeff
				combo = -1
				finished_combo = TRUE
			else
				combo = 0 // Trust me. This is due to how the 6hit combo can be at like, hit 4, then wear off mid-combo. This works just fine. Trust me.
				hitsound = 'sound/weapons/ego/da_capo1.ogg'
	else
		// The code for the 6-hit combo: on the Fourth Movement.
		switch(combo)
			if(0, 2, 4)
				hitsound = 'sound/weapons/ego/da_capo1.ogg'
				attack_speed -= 0.2
			if(1, 3)
				hitsound = 'sound/weapons/ego/da_capo2.ogg'
				attack_speed -= 0.3
			if(5)
				hitsound = 'sound/weapons/ego/da_capo3.ogg'
				force *= combo_6hit_finisher_coeff
				// Call an AOE, but exclude our main target from it
				Soundwave(music_notes_damage_coeff, music_notes_detonation_range, user, M)
				// Big slice VFX
				var/obj/effect/temp_visual/slice/temp = new (get_turf(M))
				temp.transform = temp.transform * 2.5
				if(music_notes_ring)
					music_notes_ring.Finale()
				// SFX
				playsound(src, 'sound/weapons/ego/da_capo_finale.ogg', 75, FALSE, 5)
				addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), src, 'sound/weapons/ego/da_capo_finale_claps.ogg', 80, FALSE, 5), 1 SECONDS)
				// We're done here
				combo = -1
				finished_combo = TRUE
				NextMovement(user) // This should throw us back to 1st Movement
			else
				hitsound = 'sound/weapons/ego/da_capo1.ogg'

	if(hit_note)
		playsound(src, hitsound, get_clamped_volume(), TRUE) // We aren't hitting anything, but I'd like to have the hitsound anyway, you know? Feedback and stuff
		if(finished_combo) // Finisher: detonate the note, and progress to the next movement.
			user.visible_message(span_danger("[user] confidently swings [src] at thin air, causing a melodic blast!"), span_danger("You expertly slice through a musical note with [src], causing a melodic blast!"))
			NoteDetonation(hit_note, user)
			NextMovement(user)

		else // You hit a note, but not with a finisher. The note is destroyed with no extra effect. Yikes.
			hit_note.Consume()
			user.visible_message(span_danger("[user] confidently swings [src] at thin air...?!"), span_danger("You slice through a musical note with [src], but lack the momentum to cause a melodic blast!"))

		user.changeNext_move((CLICK_CD_MELEE * attack_speed) * (finished_combo ? 1.4 : 1)) // We need to apply click delay ourselves here, since we're not hitting
		combo += 1
		force = initial(force)
		return TRUE // We don't actually "hit" anything here. This is so we don't do the attack anim towards the root of the 64x64 icon (looks janky AF)

	..() // The actual hit.

	if(finished_combo)
		user.changeNext_move(CLICK_CD_MELEE * attack_speed * 1.4)

	combo += 1
	force = initial(force)

/// Cleanup in case this weapon gets destroyed. Will get rid of the ring and any notes.
/obj/item/ego_weapon/da_capo/Destroy(force)
	RingCleanup()
	for(var/mob/da_capo_musicnote/note in music_notes_list)
		qdel(note)
	return ..()

/// Use in-hand to summon the Musical Notes. Has a cooldown.
/obj/item/ego_weapon/da_capo/attack_self(mob/living/carbon/human/user)
	. = ..()
	if(CanUseEgo(user) && music_notes_ready)
		music_notes_ready = FALSE
		INVOKE_ASYNC(src, PROC_REF(SummonNotes), user)
		addtimer(CALLBACK(src, PROC_REF(ReadyNotes), user), music_notes_summon_timer_duration)

/// Proc that is called by a timer after the cooldown for summoning notes ends. It readies the weapon to summon them again, and alerts the player.
/obj/item/ego_weapon/da_capo/proc/ReadyNotes(mob/living/user)
	music_notes_ready = TRUE
	var/sound/sfx = sound('sound/abnormalities/armyinblack/black_heartbeat.ogg')
	var/sfx_delay = 0.8 SECONDS
	ReadyNotesWarning(user, sfx)
	addtimer(CALLBACK(src, PROC_REF(ReadyNotesWarning), user, sfx), sfx_delay)
	addtimer(CALLBACK(src, PROC_REF(ReadyNotesWarning), user, sfx), sfx_delay * 2)
	to_chat(user, span_nicegreen("You are ready to begin the performance anew - [src] is ready to manifest more notes."))
	balloon_alert(user, "You are ready to begin the performance anew - [src] is ready to manifest more notes.")

/// This proc sends a specified sound to the user, directly, and flashes their screen with a colour.
/obj/item/ego_weapon/da_capo/proc/ReadyNotesWarning(mob/living/user, sound/sfx)
	SEND_SOUND(user, sfx)
	flash_color(user, flash_color = COLOR_PALE_BLUE_GRAY, flash_time = 1 SECONDS)

/// Summons musical notes around the player.
/obj/item/ego_weapon/da_capo/proc/SummonNotes(mob/living/carbon/human/subject)
	if(music_notes_summon_amount <= 0)
		return FALSE

	RingCleanup(music_notes_ring) // This shouldn't ever happen, but get rid of an existing ring if it's still around.
	music_notes_ring = new(get_turf(subject))
	RegisterSignal(music_notes_ring, COMSIG_PARENT_QDELETING, PROC_REF(RingCleanup)) // Register a signal to remove its reference if it deletes itself.
	music_notes_ring.orbit(subject, 0, TRUE, 0, 0, pre_rotation = FALSE)
	music_notes_ring.BecomeVisibleToUser(subject)

	to_chat(subject, span_notice("You resonate with [src], manifesting musical notes around yourself."))
	balloon_alert(subject, "You resonate with [src], manifesting musical notes around yourself.")
	playsound(src, 'sound/magic/summonitems_generic.ogg', 65, FALSE, -5)

	// Spawn the notes!
	for(var/i in 1 to music_notes_summon_amount)
		var/mob/da_capo_musicnote/new_note = new(get_turf(subject))
		music_notes_list += new_note
		new_note.BindTo(subject, music_notes_list) // Important: this is what makes them actually visible to the user
		RegisterSignal(new_note, COMSIG_PARENT_QDELETING, PROC_REF(NoteDestructionCleanup))
		new_note.orbit(subject, 2, TRUE, music_notes_aesthetic_rotation_time, pre_rotation = FALSE)

		sleep((music_notes_aesthetic_rotation_time / music_notes_summon_amount)) // This makes them look spread out in a circle.

/// Called when a note is destroyed, we remove the note reference from our list and if there are none left, we also call RingCleanup().
/obj/item/ego_weapon/da_capo/proc/NoteDestructionCleanup(mob/da_capo_musicnote/obliterated)
	SIGNAL_HANDLER
	music_notes_list -= obliterated
	if(length(music_notes_list) <= 0)
		if(music_notes_ring)
			music_notes_ring.has_notes_remaining = FALSE
			INVOKE_ASYNC(src, PROC_REF(RingCleanup), music_notes_ring)

/// Proc used to clean-up the ring.
/obj/item/ego_weapon/da_capo/proc/RingCleanup(obj/effect/temp_visual/da_capo_ring/garbage)
	SIGNAL_HANDLER
	if(garbage)
		UnregisterSignal(garbage, COMSIG_PARENT_QDELETING)
		if((!(garbage.has_notes_remaining)) && (current_movement != 4))
			QDEL_IN(garbage, 2.5 SECONDS)
			animate(garbage, 2 SECONDS, alpha = 0)

/// Blows up a note. Will also call NoteDetonationSpecial(), for whoever wants to implement the Al Coda we've discussed.
// (context: we've talked about Al Coda buffing this weapon to have new types of notes with special effects and/or buffs)
/obj/item/ego_weapon/da_capo/proc/NoteDetonation(mob/da_capo_musicnote/hit_note, mob/living/carbon/human/user)
	playsound(loc, 'sound/weapons/ego/da_capo_note_detonation.ogg', (65 + (current_movement * 3)), TRUE, frequency = 1 + (current_movement * 0.1))
	new /obj/effect/temp_visual/screech(get_turf(user))
	Soundwave(music_notes_damage_coeff, music_notes_detonation_range, user)

	INVOKE_ASYNC(src, PROC_REF(NoteDetonationSpecial), hit_note.special_type, user) // Special effects for Al Coda. Unimplemented as of 2025/09/02
	INVOKE_ASYNC(hit_note, TYPE_PROC_REF(/mob/da_capo_musicnote, Consume)) // Plays an animation and deletes the note

/// Called when detonating a note, to apply effects depending on what the note's special type was. (Al Coda stuff).
/// Shouldn't rely on the note anymore, it could be deleted by now.
/obj/item/ego_weapon/da_capo/proc/NoteDetonationSpecial(note_special_type, mob/living/carbon/human/user)
	return TRUE // Implement some switch case or something with the note_special_type.

/// Handles creating an AoE for our 6hit combo finisher and for detonating the musical notes. Warning: this has no visuals of its own.
/obj/item/ego_weapon/da_capo/proc/Soundwave(damage_coeff, wave_range, mob/living/carbon/human/user, mob/living/target)
	var/final_damage = force
	var/userjust = (get_modified_attribute_level(user, JUSTICE_ATTRIBUTE))
	var/justicemod = 1 + userjust/100
	final_damage*=justicemod
	final_damage*=force_multiplier
	final_damage*=damage_coeff

	for(var/mob/living/L in view(wave_range, user))
		// First conditional for this check: faction check. Second conditional: to exclude our main target, if we receive one. Third: don't hit dead things.
		if(!(user.faction_check_mob(L, TRUE)) && !(target && target == L) && (L.stat < DEAD))
			// I have to save these four vars in case our attack qdels the enemy
			var/turf/hit_turf = get_turf(L)
			var/victim_name = L.name
			var/victim_maxhp = L.maxHealth
			var/victim_biotypes = L.mob_biotypes

			to_chat(L, span_userdanger("The music of the apocalypse pierces through you!"))
			balloon_alert(L, "The music of the apocalypse pierces through you!")
			L.deal_damage(final_damage, damtype)
			// If we're hitting a target with enough max hp, who is an organic mob, and was either deleted or killed by the attack, we headbomb them.
			// This is purely aesthetic.
			if((victim_maxhp >= headbomb_hp_requirement) && (victim_biotypes & MOB_ORGANIC) && (!L || L.stat >= DEAD))
				hit_turf.visible_message(span_danger("\The [victim_name]'s head explodes!"))
				playsound(hit_turf, 'sound/weapons/ego/da_capo_headbomb.ogg', 75, TRUE)
				new /obj/effect/gibspawner/generic/trash_disposal(hit_turf) // This type spawns less gibs than usual.

			new /obj/effect/temp_visual/sparkles(hit_turf)

/// Advance to the next Movement, increasing weapon damage and giving it some visual flair.
/obj/item/ego_weapon/da_capo/proc/NextMovement(mob/living/carbon/human/user)
	filters = null
	var/rgb_color_values = 135 // We intensify this white colour as the movements progress
	var/movement_progress_chat_alert_string = "Da capo - you begin anew at the First Movement."
	if(current_movement >= 4) // If you've reached the last movement, begin again. That's in theme, right?
		current_movement = 1
		deltimer(movement_timer)
	else
		current_movement++
		StartMovementTimeoutCountdown(user)
		switch(current_movement)
			if(2)
				movement_progress_chat_alert_string = "Sostenuto - you advance to the Second Movement."
			if(3)
				movement_progress_chat_alert_string = "Accelerando e Crescendo - you advance to the Third Movement."
			if(4)
				movement_progress_chat_alert_string = "Stringendo - you advance to the Fourth Movement."
		rgb_color_values += current_movement * 30
		filters += filter(type="drop_shadow", x=0, y=0, size=current_movement - 1, offset = 1, color=rgb(rgb_color_values, rgb_color_values, rgb_color_values))
	to_chat(user, span_nicegreen(movement_progress_chat_alert_string))
	balloon_alert(user, movement_progress_chat_alert_string)

/// Sets a timer for your Movement to expire if you don't refresh it in time. Unrelated to the basic 3hit combo.
/obj/item/ego_weapon/da_capo/proc/StartMovementTimeoutCountdown(mob/living/carbon/human/user)
	deltimer(movement_timer)
	movement_timer = addtimer(CALLBACK(src, PROC_REF(MovementTimeout), user), movement_timer_duration, TIMER_STOPPABLE)

/// Returns the weapon to 1st Movement and removes ongoing timers and visuals. Unrelated to the basic 3hit combo.
/obj/item/ego_weapon/da_capo/proc/MovementTimeout(mob/living/carbon/human/user)
	filters = null
	current_movement = 1
	to_chat(user, span_nicegreen("Da capo - the scythe's power wanes and its influence recedes. You begin anew at the First Movement.")) // Why nicegreen? All the other Movement messages use it, so it's easier to track in chat.
	balloon_alert(user, "Da Capo - The Scythe's power wanes and itss influence recedes. You begin anew at the First Movement.")
	deltimer(movement_timer)
	if(music_notes_ring && !(music_notes_ring.has_notes_remaining))
		RingCleanup(music_notes_ring)

/// This proc controls the actual volume for the weapon's hitsound.
// for the longest time i thought it had something to do with like, physical volume, as in, size
/obj/item/ego_weapon/da_capo/get_clamped_volume()
	return 35 + (current_movement * 2)

/// VFX - a ring that encircles the player, in the music notes spin around.
/// We delete this manually when the weapon runs out of notes.
// Uses some code to be only visible to the user, stolen right out of Star Luminary.
/obj/effect/temp_visual/da_capo_ring
	name = "unending performance"
	desc = "And again!"
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_effects64x64.dmi'
	icon_state = ""
	var/visible_icon_state = "da_capo_ring"
	var/image/visible_image
	layer = BELOW_MOB_LAYER
	alpha = 150
	duration = 35 SECONDS
	base_pixel_x = -16
	pixel_x = -16
	base_pixel_y = -16
	pixel_y = -16
	var/client/user_client
	var/has_notes_remaining = TRUE

// Logic for these three procs was basically ripped out of Star Luminary, thank you Eidos. Makes it so only the user can see them.
/obj/effect/temp_visual/da_capo_ring/Initialize(mapload)
	. = ..()
	visible_image = image(icon, src, visible_icon_state, layer)
	visible_image.override = TRUE

/obj/effect/temp_visual/da_capo_ring/Destroy(force)
	BecomeInvisibleToUser()
	QDEL_NULL(visible_image)
	user_client = null
	return ..()

/obj/effect/temp_visual/da_capo_ring/proc/Finale()
	icon_state = "da_capo_ring"
	QDEL_IN(src, 2 SECONDS)
	animate(src, 1.5 SECONDS, easing = EASE_IN | QUAD_EASING, transform = transform*4.5)
	animate(src, 1.5 SECONDS, alpha = 0)

/obj/effect/temp_visual/da_capo_ring/proc/BecomeVisibleToUser(mob/living/carbon/human/user)
	if(!user.client)
		return
	user_client = user.client
	if(user_client)
		user_client.images |= visible_image

/obj/effect/temp_visual/da_capo_ring/proc/BecomeInvisibleToUser()
	if(!user_client)
		return
	user_client.images -= visible_image

/// This is a dummy mob for Da Capo's ability. It isn't an actual AI controlled thing.
// Uses some code to be only visible to the user, stolen right out of Star Luminary.
/mob/da_capo_musicnote
	name = "musical note"
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_effects64x64.dmi'
	icon_state = ""
	var/visible_icon_state = "da_capo_note"
	var/image/visible_image
	layer = ABOVE_ALL_MOB_LAYER
	density = FALSE
	throwforce = 0
	move_resist = INFINITY
	status_flags = GODMODE
	base_pixel_x = -16
	pixel_x = -16
	base_pixel_y = -16
	pixel_y = -16
	var/mob/living/carbon/human/bound_to
	var/client/user_client
	/// How long it lasts before vanishing.
	var/duration = 27 SECONDS
	/// This var holds a string that tells the weapon what to do when this note is detonated. Behaviour for each type should be implemented in the weapon.
	var/special_type = DA_CAPO_MUSICNOTE_DEFAULT

/mob/da_capo_musicnote/Initialize(mapload)
	. = ..()
	// This part makes it actually visible, but only by the person who used the ability
	visible_image = image(icon, src, visible_icon_state, layer)
	visible_image.override = TRUE
	visible_image.filters += filter(type="drop_shadow", x=0, y=0, size = 1, offset = 1, color=rgb(240, 240, 240)) // Players were struggling to find them over darker enemies
	QDEL_IN(src, duration) // It's a temporary thing.

/mob/da_capo_musicnote/attackby(obj/item/W, mob/user, params)
	if(..())
		return TRUE
	if(istype(W, /obj/item/ego_weapon/da_capo))
		return W.attack(src, user)

/mob/da_capo_musicnote/Destroy(force)
	Cleanup(TRUE) // We call this with TRUE so it doesn't try to qdel itself again, we're already destroying it
	return ..()

/// We call this proc when a note is hit by Da Capo.
/mob/da_capo_musicnote/proc/Consume()
	if(visible_image)
		visible_image.filters = null
		visible_image.icon_state = "da_capo_note_destroyed" // Death animation
	QDEL_IN(src, 1.5 SECONDS)

// The following two procs are for the "only the user can see this" stuff. Taken from Star Luminary, slightly modified (user's client is stored as a type var)
/mob/da_capo_musicnote/proc/BecomeVisibleToUser(mob/living/carbon/human/user)
	if(!user.client)
		return
	user_client = user.client
	if(user_client)
		user_client.images |= visible_image

/mob/da_capo_musicnote/proc/BecomeInvisibleToUser()
	if(!user_client)
		return
	user_client.images -= visible_image

/// Proc called by Da Capo on each note once it is created. Importantly, it will let the user see the notes which are normally invisible.
/mob/da_capo_musicnote/proc/BindTo(mob/living/carbon/human/subject)
	if(subject)
		bound_to = subject
		BecomeVisibleToUser(bound_to)
		RegisterSignal(bound_to, COMSIG_PARENT_QDELETING, PROC_REF(Cleanup))
		RegisterSignal(bound_to, COMSIG_LIVING_DEATH, PROC_REF(Cleanup))

/// Cleans up the mob, removing references and unregistering signals.
/// Called when destroyed, with TRUE as a parameter, or called by the signals set in BindTo() without any parameters (so called_by_destroy = FALSE)
/mob/da_capo_musicnote/proc/Cleanup(called_by_destroy = FALSE)
	SIGNAL_HANDLER
	BecomeInvisibleToUser()
	visible_image.filters = null
	QDEL_NULL(visible_image)
	if(bound_to)
		UnregisterSignal(bound_to, COMSIG_PARENT_QDELETING)
		UnregisterSignal(bound_to, COMSIG_LIVING_DEATH)
		bound_to = null
	if(!called_by_destroy)
		qdel(src)

#undef DA_CAPO_MUSICNOTE_DEFAULT

/obj/item/ego_weapon/da_capo/get_clamped_volume()
	return 40

/obj/item/ego_weapon/mimicry
	name = "mimicry"
	desc = "The yearning to imitate the human form is sloppily reflected on the E.G.O, \
	as if it were a reminder that it should remain a mere desire."
	special = "This weapon heals you on hit."
	icon_state = "mimicry"
	lefthand_file = 'icons/mob/inhands/64x64_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/64x64_righthand.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	force = 65
	damtype = RED_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP
	attack_verb_continuous = list("slashes", "slices", "rips", "cuts")
	attack_verb_simple = list("slash", "slice", "rip", "cut")
	hitsound = 'sound/abnormalities/nothingthere/attack.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)


/obj/item/ego_weapon/mimicry/attack(mob/living/target, mob/living/carbon/human/user)
	if(!CanUseEgo(user))
		return
	if(!(target.status_flags & GODMODE) && target.stat != DEAD)
		var/heal_amt = force*0.15
		if(isanimal(target))
			var/mob/living/simple_animal/S = target
			if(S.damage_coeff.getCoeff(damtype) > 0)
				heal_amt *= S.damage_coeff.getCoeff(damtype)
			else
				heal_amt = 0
		user.adjustBruteLoss(-heal_amt)
	..()

/obj/item/ego_weapon/mimicry/get_clamped_volume()
	return 40

/obj/item/ego_weapon/twilight
	name = "twilight"
	desc = "Just like how the ever-watching eyes, the scale that could measure any and all sin, \
	and the beak that could swallow everything protected the peace of the Black Forest... \
	The wielder of this armament may also bring peace as they did."
	icon_state = "twilight"
	worn_icon_state = "twilight"
	force = 35
	swingstyle = WEAPONSWING_LARGESWEEP
	damtype = RED_DAMAGE // It's all damage types, actually
	attack_verb_continuous = list("slashes", "slices", "rips", "cuts")
	attack_verb_simple = list("slash", "slice", "rip", "cut")
	hitsound = 'sound/weapons/ego/twilight.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 120,
							PRUDENCE_ATTRIBUTE = 120,
							TEMPERANCE_ATTRIBUTE = 120,
							JUSTICE_ATTRIBUTE = 120
							)
	crit_multiplier = 0	//It's twlilight

/obj/item/ego_weapon/twilight/attack(mob/living/M, mob/living/user)
	if(!CanUseEgo(user))
		return
	..()
	for(var/damage_type in list(WHITE_DAMAGE, BLACK_DAMAGE, PALE_DAMAGE))
		damtype = damage_type
		M.attacked_by(src, user)
	damtype = initial(damtype)

/obj/item/ego_weapon/twilight/EgoAttackInfo(mob/user)
	if(force_multiplier != 1)
		return span_notice("It deals [round((force * 4) * force_multiplier)] red, white, black and pale damage combined. (+ [(force_multiplier - 1) * 100]%)")
	return span_notice("It deals [force * 4] red, white, black and pale damage combined.")

/obj/item/ego_weapon/goldrush
	name = "gold rush"
	desc = "The weapon of someone who can swing their weight around like a truck"
	special = "This weapon deals its damage after a short windup."
	icon_state = "gold_rush"
	force = 140
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)
	var/goldrush_damage = 140
	var/finisher_on = TRUE //this is for a subtype, it should NEVER be false on this item.
	damtype = RED_DAMAGE
	crit_multiplier = 0	//Can't crit anyways.

//Replaces the normal attack with the gigafuck punch
/obj/item/ego_weapon/goldrush/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return
	if(!finisher_on)
		..()
		return
	if(do_after(user, 4, target))

		target.visible_message(span_danger("[user] rears up and slams into [target]!"), \
						span_userdanger("[user] punches you with everything you got!!"), vision_distance = COMBAT_MESSAGE_RANGE, ignored_mobs = user)
		to_chat(user, span_danger("You throw your entire body into this punch!"))
		balloon_alert(user, "You throw your entire body into this punch!")
		goldrush_damage = force
		//I gotta regrab  justice here
		var/userjust = (get_modified_attribute_level(user, JUSTICE_ATTRIBUTE))
		var/justicemod = 1 + userjust/100
		goldrush_damage *= justicemod
		goldrush_damage *= force_multiplier

		if(ishuman(target))
			goldrush_damage = 50

		target.apply_damage(goldrush_damage, RED_DAMAGE, null, target.run_armor_check(null, RED_DAMAGE), spread_damage = TRUE)		//MASSIVE fuckoff punch

		playsound(src, 'sound/weapons/fixer/generic/gen2.ogg', 50, TRUE)
		goldrush_damage = initial(goldrush_damage)
	else
		to_chat(user, "<span class='spider'><b>Your attack was interrupted!</b></span>")
		balloon_alert(user, "Your attack was interrupted!")
		return

/obj/item/ego_weapon/goldrush/attackby(obj/item/I, mob/living/user, params)
	..()
	if(!istype(I, /obj/item/nihil/diamond))
		return
	new /obj/item/ego_weapon/goldrush/nihil(get_turf(src))
	to_chat(user,span_warning("The [I] seems to drain all of the light away as it is absorbed into [src]!"))
	balloon_alert(user, "The [I] seems to drain all of the light away as it was abosrbed into [src]!")
	playsound(user, 'sound/abnormalities/nihil/filter.ogg', 15, FALSE, -3)
	qdel(I)
	qdel(src)

/obj/item/ego_weapon/smile
	name = "smile"
	desc = "The monstrous mouth opens wide to devour the target, its hunger insatiable."
	special = "This weapon instantly kills targets below 10% health"	//To make it more unique, if it's too strong
	icon_state = "smile"
	force = 110 //Slightly less damage, has an ability
	attack_speed = 1.6
	damtype = BLACK_DAMAGE
	attack_verb_continuous = list("slams", "attacks")
	attack_verb_simple = list("slam", "attack")
	hitsound = 'sound/weapons/ego/hammer.ogg'
	usesound = 'sound/weapons/ego/hammer.ogg'
	toolspeed = 0.12
	tool_behaviour = TOOL_MINING
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)

/obj/item/ego_weapon/smile/attack(mob/living/target, mob/living/carbon/human/user)
	if(!CanUseEgo(user))
		return
	. = ..()
	if((target.health <= target.maxHealth * 0.1 || target.stat == DEAD) && !(target.status_flags & GODMODE))	//Makes up for the lack of damage by automatically killing things under 10% HP
		target.gib()
		user.adjustBruteLoss(-user.maxHealth * 0.15)	//Heal 15% HP. Moved here from the armor, because that's a nightmare to code

/obj/item/ego_weapon/smile/get_clamped_volume()
	return 50

/obj/item/ego_weapon/smile/suicide_act(mob/living/carbon/user)
	. = ..()
	user.visible_message(span_suicide("[user] holds \the [src] in front of [user.p_them()], and begins to swing [user.p_them()]self with it! It looks like [user.p_theyre()] trying to commit suicide!"))
	playsound(user, 'sound/weapons/ego/hammer.ogg', 50, TRUE, -1)
	user.gib()
	return MANUAL_SUICIDE

/obj/item/ego_weapon/blooming
	name = "blooming"
	desc = "A rose is a rose, by any other name."
	special = "Use this weapon to change its damage type between red, white and pale."	//like a different rabbit knife. No black though
	icon_state = "rosered"
	force = 80 //Less damage, can swap damage type
	damtype = RED_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP
	attack_verb_continuous = list("cuts", "slices")
	attack_verb_simple = list("cuts", "slices")
	hitsound = 'sound/weapons/ego/rapier2.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 100
							)

/obj/item/ego_weapon/blooming/attack_self(mob/living/user)
	switch(damtype)
		if(RED_DAMAGE)
			damtype = WHITE_DAMAGE
			force = 70 //Prefers red, you can swap to white if needed
			icon_state = "rosewhite"
		if(WHITE_DAMAGE)
			damtype = PALE_DAMAGE
			force = 50
			icon_state = "rosepale"
		if(PALE_DAMAGE)
			damtype = RED_DAMAGE
			force = 80
			icon_state = "rosered"
	to_chat(user, span_notice("[src] will now deal [force] [damtype] damage."))
	balloon_alert(user, "[src] will now deal [force] [damtype] damage.")
	playsound(src, 'sound/items/screwdriver2.ogg', 50, TRUE)

/obj/item/ego_weapon/censored
	name = "CENSORED"
	desc = "(CENSORED) has the ability to (CENSORED), but this is a horrendous sight for those watching. \
			Looking at the E.G.O for more than 3 seconds will make you sick."
	special = "Using it in hand will activate its special ability. To perform this attack - click on a distant target."
	icon_state = "censored"
	worn_icon_state = "censored"
	force = 70	//there's a focus on the ranged attack here.
	damtype = BLACK_DAMAGE
	swingstyle = WEAPONSWING_THRUST
	attack_verb_continuous = list("attacks")
	attack_verb_simple = list("attack")
	hitsound = 'sound/weapons/ego/censored1.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)

	var/special_attack = FALSE
	var/special_damage = 240
	var/special_cooldown
	var/special_cooldown_time = 10 SECONDS
	var/special_checks_faction = TRUE

/obj/item/ego_weapon/censored/attack_self(mob/living/user)
	if(!CanUseEgo(user))
		return
	if(special_cooldown > world.time)
		return
	special_attack = !special_attack
	if(special_attack)
		to_chat(user, span_notice("You prepare a special attack."))
		balloon_alert(user, "You prepare a special attack.")
	else
		to_chat(user, span_notice("You decide to not use the special attack."))
		balloon_alert(user, "You decide to not use the special attakc.")

/obj/item/ego_weapon/censored/afterattack(atom/A, mob/living/user, proximity_flag, params)
	if(!CanUseEgo(user))
		return
	if(special_cooldown > world.time)
		return
	if(!special_attack)
		return
	special_attack = FALSE
	var/turf/target_turf = get_ranged_target_turf_direct(user, A, 4)
	var/list/turfs_to_hit = getline(user, target_turf)
	for(var/turf/T in turfs_to_hit)
		if(T.density)
			break
		new /obj/effect/temp_visual/cult/sparks(T)
	playsound(user, 'sound/weapons/ego/censored2.ogg', 75)
	special_cooldown = world.time + special_cooldown_time
	if(!do_after(user, 7, src))
		return
	playsound(user, 'sound/weapons/ego/censored3.ogg', 75)
	var/turf/MT = get_turf(user)
	MT.Beam(target_turf, "censored", time=5)
	var/modified_damage = (special_damage * force_multiplier)
	for(var/turf/T in turfs_to_hit)
		if(T.density)
			break
		for(var/mob/living/L in T)
			if(special_checks_faction && user.faction_check_mob(L))
				if(ishuman(L))
					var/mob/living/carbon/human/H = L
					if(!H.sanity_lost)
						continue
				else
					continue
			L.apply_damage(modified_damage, BLACK_DAMAGE, null, L.run_armor_check(null, BLACK_DAMAGE), spread_damage = TRUE)
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(L), pick(GLOB.alldirs))

/obj/item/ego_weapon/censored/get_clamped_volume()
	return 30

/obj/item/ego_weapon/soulmate
	name = "Soulmate"
	desc = "The course of true love never did run smooth."
	special = "Hitting enemies will mark them. Hitting marked enemies will give different buffs depending on attack type."
	icon_state = "soulmate"
	force = 40
	swingstyle = WEAPONSWING_LARGESWEEP
	damtype = RED_DAMAGE
	attack_speed = 0.8
	attack_verb_continuous = list("cuts", "slices")
	attack_verb_simple = list("cuts", "slices")
	hitsound = 'sound/weapons/blade1.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 100
							)

	var/bladebuff = FALSE
	var/gunbuff = FALSE
	var/list/blademark_targets = list()
	var/list/gunmark_targets = list()
	var/gun_cooldown
	var/blademark_cooldown
	var/gunmark_cooldown
	var/gun_cooldown_time = 1 SECONDS
	var/mark_cooldown_time = 15 SECONDS

/obj/item/ego_weapon/soulmate/Initialize()
	RegisterSignal(src, COMSIG_PROJECTILE_ON_HIT, PROC_REF(projectile_hit))
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)

/obj/item/ego_weapon/soulmate/attack(mob/living/target, mob/living/user)
	..()
	if(isliving(target) && !(gunbuff))
		if(target in gunmark_targets)
			gunmark_targets = list()
			bladebuff = TRUE
			icon_state = "soulmate_blade"
			update_icon_state()
			update_icon()
			attack_speed = 0.4
			gunmark_cooldown = world.time + mark_cooldown_time
			addtimer(CALLBACK(src, PROC_REF(BladeRevert)), 50)
			return
		if(!(bladebuff) && blademark_cooldown <= world.time)
			blademark_targets += target

/obj/item/ego_weapon/soulmate/afterattack(atom/target, mob/living/user, proximity_flag, clickparams)
	if(!CanUseEgo(user))
		return
	if(!proximity_flag && gun_cooldown <= world.time)
		var/turf/proj_turf = user.loc
		if(!isturf(proj_turf))
			return
		var/obj/projectile/ego_bullet/gunblade/G = new /obj/projectile/ego_bullet/gunblade(proj_turf)
		if(gunbuff)
			G.damage = 90
			G.icon_state = "red_laser"
			playsound(user, 'sound/weapons/ionrifle.ogg', 100, TRUE)
		else
			G.fired_from = src //for signal check
			playsound(user, 'sound/weapons/plasma_cutter.ogg', 100, TRUE)
		G.firer = user
		G.preparePixelProjectile(target, user, clickparams)
		G.fire()
		G.damage *= force_multiplier
		gun_cooldown = world.time + gun_cooldown_time
		return

/obj/item/ego_weapon/soulmate/proc/projectile_hit(atom/fired_from, atom/movable/firer, atom/target, Angle)
	SIGNAL_HANDLER
	if(isliving(target) && !(bladebuff))
		if(target in blademark_targets)
			blademark_targets = list()
			gunbuff = TRUE
			icon_state = "soulmate_gun"
			update_icon_state()
			update_icon()
			blademark_cooldown = world.time + mark_cooldown_time
			addtimer(CALLBACK(src, PROC_REF(GunRevert)), 80)
			return TRUE
		if(!(gunbuff) && gunmark_cooldown <= world.time)
			gunmark_targets += target
	return TRUE

/obj/item/ego_weapon/soulmate/proc/BladeRevert()
	if(bladebuff)
		icon_state = "soulmate"
		update_icon_state()
		update_icon()
		attack_speed = 0.8
		bladebuff = FALSE

/obj/item/ego_weapon/soulmate/proc/GunRevert()
	if(gunbuff)
		icon_state = "soulmate"
		update_icon_state()
		update_icon()
		gunbuff = FALSE

/obj/projectile/ego_bullet/gunblade
	name = "energy bullet"
	damage = 60
	damage_type = RED_DAMAGE
	icon_state = "ice_1"

/obj/item/ego_weapon/space
	name = "out of space"
	desc = "It hails from realms whose mere existence stuns the brain and numbs us with the black extra-cosmic gulfs it throws open before our frenzied eyes."
	special = "Use this weapon in hand to dash. Attack after a dash for an AOE."
	icon_state = "space"
	force = 35	//Half white, half black.
	damtype = WHITE_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP
	attack_verb_continuous = list("cuts", "attacks", "slashes")
	attack_verb_simple = list("cut", "attack", "slash")
	hitsound = 'sound/weapons/rapierhit.ogg'
	crit_multiplier = 0	//does multi-damage
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 80
							)
	var/canaoe
	var/dash_stamina_drain = 40

/obj/item/ego_weapon/space/Initialize()
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)

/obj/item/ego_weapon/space/attack_self(mob/living/carbon/user)
	if(!CanUseEgo(user))
		return
	var/dodgelanding
	if(user.dir == 1)
		dodgelanding = locate(user.x, user.y + 5, user.z)
	if(user.dir == 2)
		dodgelanding = locate(user.x, user.y - 5, user.z)
	if(user.dir == 4)
		dodgelanding = locate(user.x + 5, user.y, user.z)
	if(user.dir == 8)
		dodgelanding = locate(user.x - 5, user.y, user.z)

	//Nullcatch (should never happen)
	if(!dodgelanding)
		return

	icon_state = "space_aoe"
	update_icon_state()
	user.density = FALSE
	user.adjustStaminaLoss(dash_stamina_drain, TRUE, TRUE)
	user.throw_at(dodgelanding, 3, 2, spin = FALSE) // This still collides with people, by the way.
	canaoe = TRUE
	sleep(3)
	user.density = TRUE

/obj/item/ego_weapon/space/attack(mob/living/target, mob/living/user)
	..()
	if(!CanUseEgo(user))
		return
	var/userjust = (get_modified_attribute_level(user, JUSTICE_ATTRIBUTE))
	var/justicemod = 1 + userjust/100
	var/damage = force * justicemod * force_multiplier
	target.apply_damage(damage, BLACK_DAMAGE, null, target.run_armor_check(null, BLACK_DAMAGE), spread_damage = TRUE)

	if(!canaoe)
		return
	if(do_after(user, 5, src, IGNORE_USER_LOC_CHANGE))
		playsound(src, 'sound/weapons/rapierhit.ogg', 100, FALSE, 4)
		for(var/turf/T in orange(3, user))
			new /obj/effect/temp_visual/smash_effect(T)

		for(var/mob/living/L in range(3, user))
			var/aoe = force
			aoe*=justicemod
			aoe*=force_multiplier
			if(L == user || ishuman(L))
				continue
			L.apply_damage(aoe, BLACK_DAMAGE, null, L.run_armor_check(null, BLACK_DAMAGE), spread_damage = TRUE)
			L.apply_damage(aoe, WHITE_DAMAGE, null, L.run_armor_check(null, WHITE_DAMAGE), spread_damage = TRUE)
	icon_state = "space"
	update_icon_state()
	canaoe = FALSE

/obj/item/ego_weapon/space/EgoAttackInfo(mob/user)
	if(force_multiplier != 1)
		return span_notice("It deals [round(force * force_multiplier)] of both white and black damage. (+ [(force_multiplier - 1) * 100]%)")
	return span_notice("It deals [force] of both white and black damage.")

/obj/item/ego_weapon/seasons
	name = "Seasons Greetings"
	desc = "If you are reading this let a developer know."
	special = "This E.G.O. will transform to match the seasons."
	icon_state = "spring"
	force = 80
	damtype = RED_DAMAGE
	attack_verb_continuous = list("pokes", "jabs")
	attack_verb_simple = list("poke", "jab")
	hitsound = 'sound/weapons/ego/spear1.ogg'
	var/current_season = "winter"
	var/mob/current_holder
	var/list/season_list = list(
		"spring" = list(80, 1, 1, list("bashes", "bludgeons"), list("bash", "bludgeon"), 'sound/weapons/fixer/generic/gen1.ogg', "vernal equinox", WHITE_DAMAGE, WHITE_DAMAGE,
		"A gigantic, thorny bouquet of roses."),
		"summer" = list(120, 1.6, 1, list("tears", "slices", "mutilates"), list("tear", "slice","mutilate"), 'sound/abnormalities/seasons/summer_attack.ogg', "summer solstice", RED_DAMAGE, RED_DAMAGE,
		"Looks some sort of axe or bladed mace. An unbearable amount of heat comes off of it."),
		"fall" = list(100, 1.2, 1, list("crushes", "burns"), list("crush", "burn"), 'sound/abnormalities/seasons/fall_attack.ogg', "autumnal equinox",BLACK_DAMAGE ,BLACK_DAMAGE,
		"In nature, a light is often used as a simple but effective lure. This weapon follows the same premise."),
		"winter" = list(80, 1, 2, list("skewers", "jabs"), list("skewer", "jab"), 'sound/abnormalities/seasons/winter_attack.ogg', "winter solstice",PALE_DAMAGE ,PALE_DAMAGE,
		"This odd weapon is akin to the biting cold of the north.")
		)
	var/transforming = TRUE
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)

/obj/item/ego_weapon/seasons/Initialize()
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)
	RegisterSignal(SSdcs, COMSIG_GLOB_SEASON_CHANGE, PROC_REF(Transform))
	Transform()

/obj/item/ego_weapon/seasons/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(!user)
		return
	current_holder = user

/obj/item/ego_weapon/seasons/dropped(mob/user)
	. = ..()
	current_holder = null

/obj/item/ego_weapon/seasons/attack_self(mob/user)
	..()
	if(transforming)
		to_chat(user,span_warning("[src] will no longer transform to match the seasons."))
		balloon_alert(user, "[src] will no longer transform to match the seasons.")
		transforming = FALSE
		special = "This E.G.O. will not transform to match the seasons."
		return
	if(!transforming)
		to_chat(user,span_warning("[src] will now transform to match the seasons."))
		balloon_alert(user, "[src] will now transform to match the seasons.")
		transforming = TRUE
		special = "This E.G.O. will transform to match the seasons."
		return

/obj/item/ego_weapon/seasons/proc/Transform()
	if(!transforming)
		return
	current_season = SSlobotomy_events.current_season
	icon_state = current_season
	if(current_season == "summer")
		knockback = KNOCKBACK_LIGHT
		lefthand_file = 'icons/mob/inhands/64x64_lefthand.dmi'
		righthand_file = 'icons/mob/inhands/64x64_righthand.dmi'
		inhand_x_dimension = 64
		inhand_y_dimension = 64
	else
		knockback = FALSE
		lefthand_file = 'icons/mob/inhands/weapons/ego_lefthand.dmi'
		righthand_file = 'icons/mob/inhands/weapons/ego_righthand.dmi'
		inhand_x_dimension = 32
		inhand_y_dimension = 32
	update_icon_state()
	if(current_holder)
		to_chat(current_holder,span_notice("[src] suddenly transforms!"))
		balloon_alert(current_holder, "[src] suddenly transforms!")
		current_holder.update_inv_hands()
		playsound(current_holder, "sound/abnormalities/seasons/[current_season]_change.ogg", 50, FALSE)
	force = season_list[current_season][1]
	attack_speed = season_list[current_season][2]
	reach = season_list[current_season][3]
	if(reach > 1)
		stuntime = 5
		swingstyle = WEAPONSWING_THRUST
	else
		stuntime = 0
		swingstyle = WEAPONSWING_SMALLSWEEP
	attack_verb_continuous = season_list[current_season][4]
	attack_verb_simple = season_list[current_season][5]
	hitsound = season_list[current_season][6]
	name = season_list[current_season][7]
	damtype = season_list[current_season][8]
	desc = season_list[current_season][10]

/obj/item/ego_weapon/seasons/get_clamped_volume()
	return 40

/obj/item/ego_weapon/shield/distortion
	name = "distortion"
	desc = "The fragile human mind is fated to twist and distort."
	special = "This weapon requires two hands to use and always blocks ranged attacks."
	icon_state = "distortion"
	force = 35 //Twilight but lower in terms of damage
	attack_speed = 1.8
	damtype = RED_DAMAGE
	knockback = KNOCKBACK_MEDIUM
	attack_verb_continuous = list("pulverizes", "bashes", "slams", "blockades")
	attack_verb_simple = list("pulverize", "bash", "slam", "blockade")
	hitsound = 'sound/abnormalities/distortedform/slam.ogg'
	reductions = list(60, 60, 60, 60)
	projectile_block_duration = 3 SECONDS
	block_duration = 4.5 SECONDS
	block_cooldown = 2.5 SECONDS
	block_sound = 'sound/weapons/ego/heavy_guard.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 100
							)

	attacking = TRUE //ALWAYS blocking ranged attacks

/obj/item/ego_weapon/shield/distortion/Initialize()
	. = ..()
	aggro_on_block *= 4

/obj/item/ego_weapon/shield/distortion/EgoAttackInfo(mob/user)
	return span_notice("It deals [force * 4] red, white, black and pale damage combined.")

/obj/item/ego_weapon/shield/distortion/attack(mob/living/target, mob/living/user)
	. = ..()
	if(!.)
		return
	for(var/damage_type in list(WHITE_DAMAGE, BLACK_DAMAGE, PALE_DAMAGE))
		damtype = damage_type
		target.attacked_by(src, user)
	damtype = initial(damtype)

/obj/item/ego_weapon/shield/distortion/CanUseEgo(mob/living/user)
	. = ..()
	if(user.get_inactive_held_item())
		to_chat(user, span_notice("You cannot use [src] with only one hand!"))
		balloon_alert(user, "You cannot use the [src] with only one hand!")
		return FALSE

/obj/item/ego_weapon/shield/distortion/AnnounceBlock(mob/living/carbon/human/source, damage, damagetype, def_zone)
	if(src != source.get_active_held_item() || !CanUseEgo(source))
		DisableBlock(source)
		return
	..()

/obj/item/ego_weapon/shield/distortion/DisableBlock(mob/living/carbon/human/user)
	if(!block)
		return
	..()

/obj/item/ego_weapon/shield/distortion/get_clamped_volume()
	return 40

/obj/item/ego_weapon/shield/distortion/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	if(!CanUseEgo(owner)) //No blocking with one hand
		return
	..()

/obj/item/ego_weapon/shield/distortion/DropStance() //ALWAYS blocking ranged attacks, NEVER drop your stance!
	return

/obj/item/ego_weapon/farmwatch
	name = "farmwatch"
	desc = "What use is technology that cannot change the world?"
	special = "Activate this weapon in your hand to plant 4 trees of desire. Killing them with this weapon restores HP and sanity."
	icon_state = "farmwatch"
	force = 84
	attack_speed = 1.3
	damtype = RED_DAMAGE
	attack_verb_continuous = list("slashes", "slices", "rips", "cuts", "reaps")
	attack_verb_simple = list("slash", "slice", "rip", "cut", "reap")
	hitsound = 'sound/weapons/ego/farmwatch.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)
	var/ability_cooldown
	var/ability_cooldown_time = 20 SECONDS

/obj/item/ego_weapon/farmwatch/attack(mob/living/target, mob/living/carbon/human/user)
	if(!CanUseEgo(user))
		return
	if(istype(target, /mob/living/simple_animal/hostile/farmwatch_plant))
		if (force <= (initial(force) * 2))
			force += 22//this is a bit over one fourth of 84. Keeps nice whole numbers on examine text
		playsound(src, 'sound/weapons/ego/farmwatch_tree.ogg', 200, 1)
		user.adjustBruteLoss(-10)
		user.adjustSanityLoss(-15)
		to_chat(user, span_notice("You reap the fruits of your labor!"))
		balloon_alert(user, "You reap the fruits of your labor!")
		..()
		return
	..()
	force = initial(force)

/obj/item/ego_weapon/farmwatch/attack_self(mob/user)
	if(!CanUseEgo(user))
		return
	if(ability_cooldown > world.time)
		to_chat(user, span_warning("You have used this ability too recently!"))
		balloon_alert(user, "You have used this ability too recently!")
		return
	playsound(src, 'sound/effects/ordeals/white/white_reflect.ogg', 50, TRUE)
	to_chat(user, "You cultivate seeds of desires.")
	balloon_alert(user, "You cultivate seeds of desires.")
	ability_cooldown = world.time + ability_cooldown_time
	spawn_plant(user, EAST, NORTH)
	spawn_plant(user, WEST, NORTH)
	spawn_plant(user, EAST, SOUTH)
	spawn_plant(user, WEST, SOUTH)
	..()

/obj/item/ego_weapon/farmwatch/proc/spawn_plant(mob/user, dir1, dir2)
	var/turf/T = get_turf(user)
	T = get_ranged_target_turf(T, dir1, 2)//spawns one spicebush plant 2 tiles away in each corner
	T = get_ranged_target_turf(T, dir2, 2)
	new /mob/living/simple_animal/hostile/farmwatch_plant(get_turf(T))//mob located at ability_types/realized.dm

/obj/item/ego_weapon/spicebush//TODO: actually code this
	name = "spicebush"
	desc = "and the scent of the grave was in full bloom."
	special = "Activate this weapon in your hand to plant 4 soon-to-bloom flowers. While fragile, they will restore the HP and sanity of nearby humans."
	icon_state = "spicebush"
	worn_icon = 'icons/obj/clothing/belt_overlays.dmi'
	worn_icon_state = "spicebush"
	force = 70
	reach = 2
	attack_speed = 1.2
	damtype = WHITE_DAMAGE
	attack_verb_continuous = list("slashes", "slices", "pokes", "cuts", "stabs")
	attack_verb_simple = list("slash", "slice", "poke", "cut", "stab")
	hitsound = 'sound/weapons/ego/spicebush.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)
	var/ability_cooldown
	var/ability_cooldown_time = 30 SECONDS

/obj/item/ego_weapon/spicebush/attack_self(mob/user)
	if(!CanUseEgo(user))
		return
	if(ability_cooldown > world.time)
		to_chat(user, span_warning("You have used this ability too recently!"))
		balloon_alert(user, "You have used this ability too recently!")
		return
	if(do_after(user, 20, src))
		playsound(src, 'sound/weapons/ego/spicebush_special.ogg', 50, FALSE)
		to_chat(user, "You plant some flower buds.")
		balloon_alert(user, "You plant some flower buds.")
		spawn_plant(user, EAST, NORTH)//spawns one spicebush plant 2 tiles away in each corner
		spawn_plant(user, WEST, NORTH)
		spawn_plant(user, EAST, SOUTH)
		spawn_plant(user, WEST, SOUTH)
	ability_cooldown = world.time + ability_cooldown_time
	..()

/obj/item/ego_weapon/spicebush/proc/spawn_plant(mob/user, dir1, dir2)
	var/turf/T = get_turf(user)
	T = get_ranged_target_turf(T, dir1, 2)
	T = get_ranged_target_turf(T, dir2, 2)
	new /mob/living/simple_animal/hostile/spicebush_plant(get_turf(T))//mob located at ability_types/realized.dm

/obj/item/ego_weapon/spicebush/get_clamped_volume()
	return 30

/obj/item/ego_weapon/spicebush/fan
	desc = "I will leave behind a morrow, strong and fertile like fallen petals."
	icon_state = "spicebush_2"
	reach = 1
	attack_speed = 1
	worn_icon = 'icons/obj/clothing/belt_overlays.dmi'
	worn_icon_state = "spicebush_2"
	hitsound = 'sound/weapons/slap.ogg'
	var/ranged_cooldown
	var/ranged_cooldown_time = 1 SECONDS
	var/ranged_damage = 70

/obj/item/ego_weapon/spicebush/fan/proc/ResetIcons()
	playsound(src, 'sound/weapons/ego/spicebush_openfan.ogg', 50, TRUE)
	icon_state = "spicebush_2"

/obj/item/ego_weapon/spicebush/fan/attack_self(mob/user)
	if(!CanUseEgo(user))
		return
	playsound(src, 'sound/weapons/ego/spicebush_openfan.ogg', 50, TRUE)
	icon_state = "spicebush_2a"
	addtimer(CALLBACK(src, PROC_REF(ResetIcons)), 30 SECONDS)
	..()

/obj/item/ego_weapon/spicebush/fan/afterattack(atom/A, mob/living/user, proximity_flag, params)
	if(ranged_cooldown > world.time)
		return
	if(!CanUseEgo(user))
		return
	var/turf/target_turf = get_turf(A)
	if(!istype(target_turf))
		return
	if((get_dist(user, target_turf) < 2) || (get_dist(user, target_turf) > 10))
		return
	..()
	ranged_cooldown = world.time + ranged_cooldown_time
	playsound(target_turf, 'sound/weapons/ego/spicebush_fan.ogg', 50, TRUE)
	var/damage_dealt = 0
	var/modified_damage = (ranged_damage * force_multiplier)
	if(do_after(user, 5))
		for(var/turf/open/T in range(target_turf, 1))
			new /obj/effect/temp_visual/spicebloom(T)
			for(var/mob/living/L in T.contents)
				L.apply_damage(modified_damage, WHITE_DAMAGE, null, L.run_armor_check(null, WHITE_DAMAGE), spread_damage = TRUE)
				if((L.stat < DEAD) && !(L.status_flags & GODMODE))
					damage_dealt += modified_damage

/obj/effect/temp_visual/spicebloom
	icon = 'ModularLobotomy/_Lobotomyicons/tegu_effects.dmi'
	icon_state = "spicebush"
	duration = 10

/obj/item/ego_weapon/mockery
	name = "mockery"
	desc = "...If I earned a name, will I get to receive love and hate from you? \
	Will you remember me as that name, as someone whom you cared for?"
	special = "Use this weapon in hand to swap between forms. The whip has higher reach, the hammer deals damage in an area, and the bat knocks back enemies."
	icon_state = "mockery_whip"
	force = 35
	attack_speed = 0.5
	reach = 3
	damtype = BLACK_DAMAGE
	attack_verb_continuous = list("lacerates", "disciplines")
	attack_verb_simple = list("lacerate", "discipline")
	hitsound = 'sound/weapons/whip.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)
	var/mob/current_holder
	var/form = "whip"
	var/list/weapon_list = list(
		"whip" = list(35, 0.5, 3, list("lacerates", "disciplines"), list("lacerate", "discipline"), 'sound/weapons/whip.ogg'),
		"sword" = list(80, 1, 1, list("tears", "slices", "mutilates"), list("tear", "slice","mutilate"), 'sound/weapons/fixer/generic/blade4.ogg'),
		"hammer" = list(40, 1.4, 1, list("crushes"), list("crush"), 'sound/weapons/fixer/generic/baton2.ogg'),
		"bat" = list(120, 1.6, 1, list("bludgeons", "bashes"), list("bludgeon", "bash"), 'sound/weapons/fixer/generic/gen1.ogg')
		)

/obj/item/ego_weapon/mockery/Initialize()
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)

/obj/item/ego_weapon/mockery/attack_self(mob/user)
	. = ..()
	if(!CanUseEgo(user))
		return
	SwitchForm(user)

/obj/item/ego_weapon/mockery/equipped(mob/user, slot)
	. = ..()
	if(!user)
		return
	current_holder = user

/obj/item/ego_weapon/mockery/dropped(mob/user)
	. = ..()
	current_holder = null

/obj/item/ego_weapon/mockery/attack(mob/living/target, mob/living/carbon/human/user)
	if(form == "bat")
		knockback = KNOCKBACK_LIGHT
	else
		knockback = FALSE

	. = ..()
	if(!.)
		return

	if(form != "hammer")
		return

	for(var/mob/living/L in view(2, target))
		var/aoe = force
		var/userjust = (get_modified_attribute_level(user, JUSTICE_ATTRIBUTE))
		var/justicemod = 1 + userjust/100
		aoe*=justicemod
		if(user.faction_check_mob(L))
			continue
		L.apply_damage(aoe, BLACK_DAMAGE, null, L.run_armor_check(null, BLACK_DAMAGE), spread_damage = TRUE)
		new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(L))

/obj/item/ego_weapon/mockery/get_clamped_volume()
	return 40

// Radial menu
/obj/item/ego_weapon/mockery/proc/SwitchForm(mob/user)
	var/list/armament_icons = list(
		"whip" = image(icon = src.icon, icon_state = "mockery_whip"),
		"sword"  = image(icon = src.icon, icon_state = "mockery_sword"),
		"hammer"  = image(icon = src.icon, icon_state = "mockery_hammer"),
		"bat"  = image(icon = src.icon, icon_state = "mockery_bat")
	)
	armament_icons = sortList(armament_icons)
	var/choice = show_radial_menu(user, src , armament_icons, custom_check = CALLBACK(src, PROC_REF(CheckMenu), user), radius = 42, require_near = TRUE)
	if(!choice || !CheckMenu(user))
		return
	form = choice
	Transform()

/obj/item/ego_weapon/mockery/proc/CheckMenu(mob/user)
	if(!istype(user))
		return FALSE
	if(QDELETED(src))
		return FALSE
	if(user.incapacitated() || !user.is_holding(src))
		return FALSE
	return TRUE

/obj/item/ego_weapon/mockery/proc/Transform()
	icon_state = "mockery_[form]"
	update_icon_state()
	if(current_holder)
		to_chat(current_holder,span_notice("[src] suddenly transforms!"))
		balloon_alert(current_holder, "[src] suddenly transforms!")
		current_holder.update_inv_hands()
		current_holder.playsound_local(current_holder, 'sound/effects/blobattack.ogg', 75, FALSE)
	force = weapon_list[form][1]
	attack_speed = weapon_list[form][2]
	reach = weapon_list[form][3]
	attack_verb_continuous = weapon_list[form][4]
	attack_verb_simple = weapon_list[form][5]
	hitsound = weapon_list[form][6]

/obj/item/ego_weapon/oberon
	name = "oberon"
	desc = "Then yes, I am the Oberon you seek."
	special = "Use this weapon in hand to swap between forms. This form has higher reach, hits 3 times, and builds up attack speed before unleasheing a powerful burst of damage."
	icon_state = "oberon_whip"
	lefthand_file = 'icons/mob/inhands/64x64_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/64x64_righthand.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	force = 30
	attack_speed = 0.8
	reach = 3
	damtype = BLACK_DAMAGE
	attack_verb_continuous = list("lacerates", "disciplines")
	attack_verb_simple = list("lacerate", "discipline")
	hitsound = 'sound/weapons/whip.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 120,
							PRUDENCE_ATTRIBUTE = 120,
							TEMPERANCE_ATTRIBUTE = 120,
							JUSTICE_ATTRIBUTE = 120
							)
	var/mob/current_holder
	var/form = "whip"
	var/list/weapon_list = list(
		"whip" = list(30, 0.8, 3, list("lacerates", "disciplines"), list("lacerate", "discipline"), 'sound/weapons/whip.ogg', BLACK_DAMAGE, "This form has higher reach, hits 3 times, and builds up attack speed before unleasheing a powerful burst of damage."),
		"sword" = list(55, 0.8, 1, list("tears", "slices", "mutilates"), list("tear", "slice","mutilate"), 'sound/weapons/fixer/generic/blade4.ogg', BLACK_DAMAGE, "This form can fire a projectile and does both RED DAMAGE and BLACK DAMAGE."),
		"hammer" = list(55, 1.4, 1, list("crushes"), list("crush"), 'sound/weapons/fixer/generic/baton2.ogg', BLACK_DAMAGE, "This form deals damage in an area and incease the RED and BLACK vulnerability by 0.2 to everything in that area."),
		"bat" = list(160, 1.6, 1, list("bludgeons", "bashes"), list("bludgeon", "bash"), 'sound/weapons/fixer/generic/gen1.ogg', RED_DAMAGE, "This form does RED DAMAGE and knocks back enemies."),
		"scythe" = list(100, 1.2, 1, list("slashes", "slices", "rips", "cuts"), list("slash", "slice", "rip", "cut"), 'sound/abnormalities/nothingthere/attack.ogg', RED_DAMAGE, "This form does RED DAMAGE and does 50% more damage when hitting targets below 50% health.")
		)
	var/gun_cooldown
	var/gun_cooldown_time = 1 SECONDS
	var/build_up = 0.8
	var/smashing = FALSE
	var/combo_time
	var/combo_wait = 15

/*
	Each form is meant to have their own purpose and niche,
	Whip: Far reaching melee and raw fast attacking black damage.(It looks cool as hell and has good dps I think. It's an aleph fusion of logging and aninmalism with animalism's multiple hits when you attack and loggings attack speed build up into aoe burst.)
	Sword: Raw mixed damage/ranged weapon also.(Since its like a buffed soulmate without the mark gimmick.)
	Hammer: Black damage aoe support/armor weakener.(Meant to combo with the other weapons with the red and black rend it has and to deal with groups also incase you somehow kill oberon before amber midnight.)
	Bat: Slow attacking red damage with knockback.(Simple yes, but it's useful versus stuff like Censored or Black Fixer. I guess it's an upgrade/sidegrade of flesh is willing and summer solstice but that wasn't intentional since it was black before I changed it.)
	Scythe: A good finisher that has dps on par with the sword when the target has 50% hp or lower while being slightly worse than aleph dps wise otherwise I think.(Used to be a shittier mimicry)
	Whip, Sword, and Bat are meant to be raw damage, Hammer is meant to be utility, and  Scythe is meant to be a finisher.
*/

/obj/item/ego_weapon/oberon/Initialize()
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)

/obj/item/ego_weapon/oberon/attack_self(mob/user)
	. = ..()
	if(!CanUseEgo(user))
		return
	SwitchForm(user)

/obj/item/ego_weapon/oberon/equipped(mob/user, slot)
	. = ..()
	if(!user)
		return
	current_holder = user

/obj/item/ego_weapon/oberon/dropped(mob/user)
	. = ..()
	current_holder = null

/obj/item/ego_weapon/oberon/attack(mob/living/target, mob/living/carbon/human/user)
	if(world.time > combo_time)
		build_up = 0.8
	combo_time = world.time + combo_wait
	knockback = FALSE
	switch(form)
		if("scythe")
			if(target.health <= (target.maxHealth * 0.5))
				playsound(get_turf(target), 'sound/abnormalities/nothingthere/goodbye_attack.ogg', 75, 0, 7)
				new /obj/effect/temp_visual/nobody_grab(get_turf(target))
				force = 150
			else
				force = 100

		if("bat")
			knockback = KNOCKBACK_MEDIUM

	. = ..()
	if(!.)
		return

	var/userjust = (get_modified_attribute_level(user, JUSTICE_ATTRIBUTE))
	var/justicemod = 1 + userjust / 100

	switch(form)
		if("sword")
			var/red = force
			red*=justicemod
			target.apply_damage(red * force_multiplier, RED_DAMAGE, null, target.run_armor_check(null, RED_DAMAGE), spread_damage = TRUE)

		if("whip")
			var/multihit = force
			multihit*= justicemod
			for(var/i = 1 to 2)
				sleep(2)
				if(target in view(reach,user))
					playsound(loc, hitsound, get_clamped_volume(), TRUE, extrarange = stealthy_audio ? SILENCED_SOUND_EXTRARANGE : -1, falloff_distance = 0)
					user.do_attack_animation(target)
					target.attacked_by(src, user)
					log_combat(user, target, pick(attack_verb_continuous), src.name, "(INTENT: [uppertext(user.a_intent)]) (DAMTYPE: [uppertext(damtype)])")

		if("hammer")
			for(var/mob/living/L in view(2, target))
				var/aoe = force
				aoe*=justicemod
				if(user.faction_check_mob(L))
					continue
				L.apply_damage(aoe * force_multiplier, BLACK_DAMAGE, null, L.run_armor_check(null, BLACK_DAMAGE), spread_damage = TRUE)
				new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(L))
				if(!ishuman(L))
					if(!L.has_status_effect(/datum/status_effect/rend_black))
						L.apply_status_effect(/datum/status_effect/rend_black)
					if(!L.has_status_effect(/datum/status_effect/rend_red))
						L.apply_status_effect(/datum/status_effect/rend_red)

/obj/item/ego_weapon/oberon/melee_attack_chain(mob/user, atom/target, params)
	..()
	switch(form)
		if("whip")
			if(isliving(target))
				user.changeNext_move(CLICK_CD_MELEE * build_up) // Starts a little fast, but....
				if (build_up <= 0.1)
					build_up = 0.8
					user.changeNext_move(CLICK_CD_MELEE * 4)
					if(!smashing)
						to_chat(user,span_warning("The whip starts to thrash around uncontrollably!"))
						balloon_alert(user, "The whip starts to trash around uncontrollably!")
						Smash(user, target)
				else
					build_up -= (0.1/3)//sortof silly but its a way to fix each whip hit from increasing build up 3 times as it should.
			else
				user.changeNext_move(CLICK_CD_MELEE * 0.8)

/obj/item/ego_weapon/oberon/proc/Smash(mob/user, atom/target)
	smashing = TRUE
	playsound(user, 'sound/abnormalities/woodsman/woodsman_prepare.ogg', 50, 0, 3)
	var/userjust = (get_modified_attribute_level(user, JUSTICE_ATTRIBUTE))
	var/justicemod = 1 + userjust/100
	var/smash_damage = 170
	smash_damage *= justicemod
	sleep(0.5 SECONDS)
	for(var/i = 0; i < 3; i++)
		for(var/turf/T in view(3, user))
			new /obj/effect/temp_visual/nobody_grab(T)
			for(var/mob/living/L in T)
				if(user.faction_check_mob(L))
					continue
				L.apply_damage(smash_damage * force_multiplier, BLACK_DAMAGE, null, L.run_armor_check(null, BLACK_DAMAGE), spread_damage = TRUE)
		playsound(user, 'sound/abnormalities/fairy_longlegs/attack.ogg', 75, 0, 3)
		sleep(0.5 SECONDS)
	smashing = FALSE
	return

/obj/item/ego_weapon/oberon/get_clamped_volume()
	return 40

/obj/item/ego_weapon/oberon/afterattack(atom/target, mob/living/user, proximity_flag, clickparams)
	if(!CanUseEgo(user))
		return
	switch(form)
		if("sword")
			if(!proximity_flag && gun_cooldown <= world.time)
				var/turf/proj_turf = user.loc
				if(!isturf(proj_turf))
					return
				var/obj/projectile/ego_bullet/gunblade/G = new /obj/projectile/ego_bullet/gunblade(proj_turf)
				G.damage = 90
				G.icon_state = "red_laser"
				playsound(user, 'sound/weapons/ionrifle.ogg', 100, TRUE)
				G.firer = user
				G.preparePixelProjectile(target, user, clickparams)
				G.fire()
				G.damage *= force_multiplier
				gun_cooldown = world.time + gun_cooldown_time
				return
// Radial menu
/obj/item/ego_weapon/oberon/proc/SwitchForm(mob/user)
	var/list/armament_icons = list(
		"whip" = image(icon = src.icon, icon_state = "oberon_whip"),
		"sword"  = image(icon = src.icon, icon_state = "oberon_sword"),
		"hammer"  = image(icon = src.icon, icon_state = "oberon_hammer"),
		"bat"  = image(icon = src.icon, icon_state = "oberon_bat"),
		"scythe" = image(icon = src.icon, icon_state = "oberon_scythe")
	)
	armament_icons = sortList(armament_icons)
	var/choice = show_radial_menu(user, src , armament_icons, custom_check = CALLBACK(src, PROC_REF(CheckMenu), user), radius = 42, require_near = TRUE)
	if(!choice || !CheckMenu(user))
		return
	form = choice
	Transform()

/obj/item/ego_weapon/oberon/proc/CheckMenu(mob/user)
	if(!istype(user))
		return FALSE
	if(QDELETED(src))
		return FALSE
	if(user.incapacitated() || !user.is_holding(src))
		return FALSE
	return TRUE

/obj/item/ego_weapon/oberon/proc/Transform()
	icon_state = "oberon_[form]"
	update_icon_state()
	if(current_holder)
		to_chat(current_holder,span_notice("[src] suddenly transforms!"))
		balloon_alert(current_holder, "[src] suddenly transforms!")
		current_holder.update_inv_hands()
		current_holder.playsound_local(current_holder, 'sound/effects/blobattack.ogg', 75, FALSE)
	force = weapon_list[form][1]
	attack_speed = weapon_list[form][2]
	reach = weapon_list[form][3]
	attack_verb_continuous = weapon_list[form][4]
	attack_verb_simple = weapon_list[form][5]
	hitsound = weapon_list[form][6]
	damtype = weapon_list[form][7]
	special = "Use this weapon in hand to swap between forms. [weapon_list[form][8]]"
	build_up = 0.8

/obj/item/ego_weapon/shield/gasharpoon
	name = "gasharpoon"
	desc = "As long as I can kill the pallid whale with my own two hands... I care not about what happens next."
	special = "Activate in your hand while wearing the corresponding suit to change forms. Each form has a unique ability; alt-click or right-click and select 'revert' to change forms again."
	icon_state = "gasharpoon"
	lefthand_file = 'icons/mob/inhands/64x64_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/64x64_righthand.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	force = 70
	attack_speed = 1.2
	damtype = PALE_DAMAGE
	attack_verb_continuous = list("stabs", "jabs", "slaps", "skewers")
	attack_verb_simple = list("stab", "jab", "slap", "skewer")
	hitsound = 'sound/weapons/ego/gasharpoon_hit.ogg'
	reductions = list(60, 40, 70, 40)
	projectile_block_duration = 2 SECONDS
	block_duration = 3 SECONDS
	block_cooldown = 2 SECONDS
	block_sound = 'sound/weapons/ego/gasharpoon_queeblock.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)
	var/form
	var/mob/current_holder
	var/dodgeturf
	var/gun_cooldown
	var/gun_cooldown_time = 2 SECONDS
	var/burst_size = 5
	var/matching_armor = /obj/item/clothing/suit/armor/ego_gear/realization/gasharpoon
	var/list/weapon_list = list(
		"pip" = list(40, 1.6, 1, 'sound/weapons/ego/gasharpoon_piphit.ogg', "You burn the E.G.O of the innocent deckhand."),
		"starbuck" = list(70, 1, 1, 'sound/weapons/ego/gasharpoon_starbuckhit.ogg', "Your burn the E.G.O of your first mate."),
		"queeqeg" = list(70, 1.6, 2, 'sound/weapons/ego/gasharpoon_queehit.ogg', "You burn the E.G.O of the indominable harpooneer.")
		)

/obj/item/ego_weapon/shield/gasharpoon/Initialize()
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)
	RegisterSignal(src, COMSIG_PROJECTILE_ON_HIT, PROC_REF(projectile_hit))

/obj/item/ego_weapon/shield/gasharpoon/equipped(mob/user, slot)
	. = ..()
	if(!user)
		return
	current_holder = user

/obj/item/ego_weapon/shield/gasharpoon/dropped(mob/user)
	. = ..()
	Revert()
	current_holder = null

/obj/item/ego_weapon/shield/gasharpoon/attack(mob/living/M, mob/living/user)
	. = ..()
	if(!.)
		return FALSE
	if(form != "pip")//pip form gets an AOE attack
		return
	for(var/mob/living/L in view(1, M))
		var/aoe = 30
		var/userjust = (get_modified_attribute_level(user, JUSTICE_ATTRIBUTE))
		var/justicemod = 1 + userjust/100
		aoe*=justicemod
		aoe*=force_multiplier
		if(L == user || ishuman(L))
			continue
		L.apply_damage(aoe, PALE_DAMAGE, null, L.run_armor_check(null, PALE_DAMAGE), spread_damage = TRUE)
		new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(L))

/obj/item/ego_weapon/shield/gasharpoon/afterattack(atom/target, mob/living/user, proximity_flag, clickparams)
	if(!CanUseEgo(user))
		return
	if(form != "starbuck")
		return
	if(!check_suit(user))
		return
	if(!proximity_flag && gun_cooldown <= world.time)
		var/turf/proj_turf = user.loc
		if(!isturf(proj_turf))
			return
		gun_cooldown = world.time + gun_cooldown_time
		for(var/i = 0 , i <= burst_size, i++)
			var/obj/projectile/ego_bullet/gasharpoon/G = new /obj/projectile/ego_bullet/gasharpoon(proj_turf)
			G.fired_from = src //for signal check
			playsound(user, 'sound/weapons/ego/gasharpoon_fire.ogg', 100, TRUE)
			G.firer = user
			var/spread = rand(-25,25)
			G.preparePixelProjectile(target, user, clickparams, spread)
			G.fire()
			sleep(0.1 SECONDS)
		return

/obj/item/ego_weapon/shield/gasharpoon/attack_self(mob/living/carbon/user)
	if(!CanUseEgo(user))
		return
	if(!check_suit(user))
		return
	if(!form)
		SwitchForm(user)
		return
	if(form == "pip")//better bloodbath dodge
		switch(user.dir)
			if(NORTH)
				dodgeturf = locate(user.x, user.y + 5, user.z)
			if(SOUTH)
				dodgeturf = locate(user.x, user.y - 5, user.z)
			if(EAST)
				dodgeturf = locate(user.x + 5, user.y, user.z)
			if(WEST)
				dodgeturf = locate(user.x - 5, user.y, user.z)
		user.adjustStaminaLoss(5, TRUE, TRUE)
		user.throw_at(dodgeturf, 3, 2, spin = TRUE)
	if(form == "queeqeg")
		..()//NOW you can use the shield

#define STATUS_EFFECT_PALLIDNOISE /datum/status_effect/stacking/pallid_noise//located in debuffs.dm

/obj/item/ego_weapon/shield/gasharpoon/AnnounceBlock(mob/living/carbon/user)//block
	..()
	var/aoe = 5
	var/userfort = (get_modified_attribute_level(user, FORTITUDE_ATTRIBUTE))
	var/fortmod = 1 + userfort/100
	aoe*=fortmod
	aoe*=force_multiplier
	for(var/turf/T in view(1, user))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
	for(var/mob/living/L in view(1, user))
		if(L == user || ishuman(L))
			continue
		L.apply_damage(aoe, PALE_DAMAGE, null, L.run_armor_check(null, PALE_DAMAGE), spread_damage = TRUE)
		var/datum/status_effect/stacking/pallid_noise/P = L.has_status_effect(/datum/status_effect/stacking/pallid_noise)
		if(!P)
			L.apply_status_effect(STATUS_EFFECT_PALLIDNOISE)
			return
		P.add_stacks(1)

#undef STATUS_EFFECT_PALLIDNOISE

// Radial menu
/obj/item/ego_weapon/shield/gasharpoon/proc/SwitchForm(mob/user)
	var/list/armament_icons = list(
		"pip" = image(icon = src.icon, icon_state = "gasharpoon_pip"),
		"starbuck"  = image(icon = src.icon, icon_state = "gasharpoon_starbuck"),
		"queeqeg"  = image(icon = src.icon, icon_state = "gasharpoon_queeqeg")
	)
	armament_icons = sortList(armament_icons)
	var/choice = show_radial_menu(user, src , armament_icons, custom_check = CALLBACK(src, PROC_REF(CheckMenu), user), radius = 42, require_near = TRUE)
	if(!choice || !CheckMenu(user))
		return
	form = choice
	Transform()

/obj/item/ego_weapon/shield/gasharpoon/proc/CheckMenu(mob/user)
	if(!istype(user))
		return FALSE
	if(QDELETED(src))
		return FALSE
	if(user.incapacitated() || !user.is_holding(src))
		return FALSE
	return TRUE

/obj/item/ego_weapon/shield/gasharpoon/proc/Transform()
	icon_state = "gasharpoon_[form]"
	update_icon_state()
	if(current_holder)
		current_holder.update_inv_hands()
		current_holder.playsound_local(current_holder, 'sound/weapons/ego/gasharpoon_transform.ogg', 75, FALSE)
	force = weapon_list[form][1]
	attack_speed = weapon_list[form][2]
	reach = weapon_list[form][3]
	hitsound = weapon_list[form][4]
	to_chat(current_holder, span_notice(weapon_list[form][5]))
	balloon_alert(current_holder, weapon_list[form][5])

/obj/item/ego_weapon/shield/gasharpoon/proc/Revert()
	if(!form)//is it not transformed?
		return
	form = initial(form)
	icon_state = initial(icon_state)
	update_icon_state()
	force = initial(force)
	attack_speed = initial(attack_speed)
	reach = initial(reach)
	hitsound = initial(hitsound)
	if(current_holder)
		to_chat(current_holder,span_notice("[src] returns to its original shape."))
		balloon_alert(current_holder, "[src] returns to it's original shape.")
		current_holder.update_inv_hands()
		current_holder.playsound_local(current_holder, 'sound/weapons/ego/gasharpoon_transform.ogg', 75, FALSE)

/obj/item/ego_weapon/shield/gasharpoon/verb/Toggle()//this is just a verb that calls Revert. Verbs appear in the right-click drop-down menu
	set name = "Revert"
	set category = "Object"
	return Revert()

/obj/item/ego_weapon/shield/gasharpoon/AltClick(mob/user)
	..()
	return Revert()

/obj/item/ego_weapon/shield/gasharpoon/get_clamped_volume()
	return 40


/obj/item/ego_weapon/shield/gasharpoon/proc/projectile_hit(atom/fired_from, atom/movable/firer, atom/target, Angle)
	SIGNAL_HANDLER
	return TRUE

/obj/item/ego_weapon/shield/gasharpoon/proc/check_suit(mob/living/carbon/user)
	var/mob/living/carbon/human/H = user
	var/obj/item/clothing/suit/armor/ego_gear/realization/gasharpoon/P = H.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(!istype(P, matching_armor))
		Revert()
		to_chat(current_holder,span_notice("[src] appears unable to release its full potential."))
		balloon_alert(current_holder, "[src] appears unable to release it's full potential.")
		return FALSE
	return TRUE

/obj/projectile/ego_bullet/gasharpoon
	name = "harpoon"
	icon_state = "gasharpoon"
	damage = 25
	damage_type = PALE_DAMAGE
	hitsound = "sound/weapons/ego/gasharpoon_bullet_impact.ogg"

/obj/item/ego_weapon/wield/darkcarnival
	name = "dark carnival"
	desc = "Get ready! I'm comin' to get ya!"
	icon_state = "dark_carnival"
	special = "This weapon deals RED damage when wielded and WHITE otherwise."
	swingstyle = WEAPONSWING_LARGESWEEP
	icon_state = "dark_carnival"
	lefthand_file = 'icons/mob/inhands/64x64_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/64x64_righthand.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	force = 90
	damtype = WHITE_DAMAGE
	wielded_attack_speed = 0.5
	wielded_reach = 2
	wielded_force = 52
	attack_speed = 1.2
	attack_verb_continuous = list("slashes", "slices", "rips", "cuts")
	attack_verb_simple = list("slash", "slice", "rip", "cut")
	hitsound = 'sound/abnormalities/clownsmiling/egoslash.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)

	var/dash_cooldown
	var/dash_cooldown_time = 4 SECONDS
	var/dash_range = 6

/obj/item/ego_weapon/wield/darkcarnival/OnWield(obj/item/source, mob/user)
	damtype = RED_DAMAGE
	hitsound = 'sound/abnormalities/clownsmiling/egostab.ogg'
	icon_state = "dark_carnival_open"
	stuntime = 3
	swingstyle = WEAPONSWING_THRUST
	return ..()

/obj/item/ego_weapon/wield/darkcarnival/on_unwield(obj/item/source, mob/user)
	damtype = WHITE_DAMAGE
	hitsound = 'sound/abnormalities/clownsmiling/egoslash.ogg'
	icon_state = "dark_carnival"
	stuntime = 0
	swingstyle = WEAPONSWING_LARGESWEEP
	return ..()

/obj/item/ego_weapon/wield/darkcarnival/afterattack(atom/A, mob/living/user, proximity_flag, params)
	if(!CanUseEgo(user))
		return
	if(!isliving(A))
		return
	if(dash_cooldown > world.time)
		to_chat(user, "<span class='warning'>Your dash is still recharging!")
		balloon_alert(user, "Your dash is still recharging!")
		return
	if((get_dist(user, A) < 2) || (!(can_see(user, A, dash_range))))
		return
	..()
	dash_cooldown = world.time + dash_cooldown_time
	for(var/i in 2 to get_dist(user, A))
		step_towards(user,A)
	if((get_dist(user, A) < 2))
		A.attackby(src,user)
	playsound(src, 'sound/abnormalities/clownsmiling/jumpscare.ogg', 50, FALSE, 9)
	to_chat(user, "<span class='warning'>You dash to [A]!")
	balloon_alert(user, "You dash to [A]!")

/obj/item/ego_weapon/faith
	name = "starbound faith"
	desc = "The blue marble is desperately clasped between two blackened hands. \
	Hope, Faith, Zealotry. The Stars illuminate the path to salvation, and countless hands reach forward to grasp it."
	icon_state = "faith"
	inhand_icon_state = "galaxy"
	force = 85
	swingstyle = WEAPONSWING_LARGESWEEP
	damtype = BLACK_DAMAGE
	attack_speed = 1.2
	attack_verb_continuous = list("slams", "attacks")
	attack_verb_simple = list("slam", "attack")
	hitsound = 'sound/weapons/ego/rapier2.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 100
							)
	color = LIGHT_COLOR_BLUE
	light_system = MOVABLE_LIGHT
	light_range = 0
	light_power = 1
	light_on = FALSE

	var/ritual_cooldown
	var/ritual_cooldown_time = 300 SECONDS
	var/ritual_duration = 100 SECONDS
	var/ritual_ongoing = FALSE
	var/ritual_active = FALSE
	var/ritual_master = FALSE
	var/ritual_synchronization = FALSE

	var/healing = FALSE
	var/awakened = FALSE

	var/shot_cooldown_time = 2 SECONDS
	var/shot_cooldown

	var/buff_timer

// Add a fuckton of player-facing notifications

/obj/item/ego_weapon/faith/dropped(mob/user)
	. = ..()
	deltimer(buff_timer)
	reset()

/obj/item/ego_weapon/faith/attack(mob/living/target, mob/living/carbon/human/user)
	. = ..()
	if(healing)
		var/userjust = (get_modified_attribute_level(user, JUSTICE_ATTRIBUTE))
		var/justicemod = 1 + (userjust / 100)
		if(!(target.status_flags & GODMODE) && target.stat != DEAD)
			var/heal_amt = (force * 0.08 * force_multiplier * justicemod)
			if(isanimal(target))
				var/mob/living/simple_animal/S = target
				if(S.damage_coeff.getCoeff(damtype) > 0)
					heal_amt *= S.damage_coeff.getCoeff(damtype)
				else
					heal_amt = 5
			user.adjustSanityLoss(-heal_amt)

/obj/item/ego_weapon/faith/afterattack(atom/target, mob/living/user, proximity_flag, clickparams)
	..()
	if(awakened && (!proximity_flag && shot_cooldown <= world.time))
		var/turf/proj_turf = get_turf(user)
		if(!proj_turf)
			return
		var/obj/projectile/ego_bullet/star_bound/boolet = new /obj/projectile/ego_bullet/star_bound(proj_turf)
		boolet.fired_from = src // For signal check
		playsound(user, 'sound/weapons/plasma_cutter.ogg', 100, TRUE)
		boolet.firer = user
		boolet.preparePixelProjectile(target, user, clickparams)
		boolet.fire()
		boolet.damage *= force_multiplier
		shot_cooldown = world.time + shot_cooldown_time
		return

/obj/item/ego_weapon/faith/attack_self(mob/living/user)
	. = ..()
	if(!ishuman(user))
		return
	if((ritual_cooldown > world.time))
		return
	ritual_cooldown = world.time + ritual_cooldown_time
	var/mob/living/carbon/human/wielder = user
	if(!(wielder.has_status_effect(/datum/status_effect/starcultist)))
		to_chat(wielder, span_warning("The staff refuses to answer your calling. Reject not the truth of the Stars."))
		balloon_alert(wielder, "The staff refuses to answer your calling. Reject not the truth of the Stars.")
		return
	if(ritual_active || ritual_ongoing)
		return
	var/cultist_in_ritual = cultist_check(wielder)
	if(cultist_in_ritual < 1)
		to_chat(wielder, span_warning("The staff shines briefly then fizzles out, unable to reach fellow followers of the Star."))
		balloon_alert(wielder, "The staff shines briefly then fizzles out, unable to reach fellow followers of the Star.")
		return
	to_chat(wielder, span_warning("The staff vibrates in your hands, trying to reach towards all followers of the Star."))
	balloon_alert(wielder, "The staff vibrates in your hands, trying to reach towardsa ll followers of the Star.")
	playsound(user, 'sound/weapons/plasma_cutter.ogg', 100, TRUE)
	start_ritual(wielder)

/obj/item/ego_weapon/faith/proc/cultist_check(mob/living/user)
	var/cultist_count
	for(var/mob/living/carbon/human/cultman in oview(4, user))
		if(cultman.has_status_effect(/datum/status_effect/starcultist))
			if(!ritual_master)
				var/obj/item/ego_weapon/faith/cultist_wand = cultman.is_holding_item_of_type(/obj/item/ego_weapon/faith)
				if(cultist_wand)
					if(cultist_wand.ritual_master)
						sync_ritual(user)
						return
			cultist_count++
	return cultist_count

/obj/item/ego_weapon/faith/proc/sync_ritual(mob/living/user)
	ritual_synchronization = TRUE
	ritual_ongoing = TRUE
	to_chat(user, span_notice("You feel that a ritual is already underway nearby, and your staff attunes to it."))
	balloon_alert(user, "You feel that a ritual is already underway nearby, and your staff attunes to it")
	for(var/i = 1 to 12)
		if(!user)
			reset()
			return
		if(!do_after(user, 0.5 SECONDS))
			break
		if(ritual_active)
			break
	ritual_synchronization = FALSE
	ritual_ongoing = FALSE
	if(ritual_active)
		to_chat(user, span_nicegreen("Your staff thrums with energy."))
		balloon_alert(user, "Your staff thrums with energy.")
	else
		playsound(user, 'sound/effects/zzzt.ogg', 60, TRUE)
		to_chat(user, span_warning("The light in your staff fizzles out, something must have gone wrong."))
		balloon_alert(user, "The light in your staff fizzles out, something must have gone wrong.")
/obj/item/ego_weapon/faith/proc/start_ritual(mob/living/user)
	ritual_master = TRUE
	ritual_ongoing = TRUE
	ritual_progress(user)

/obj/item/ego_weapon/faith/proc/ritual_progress(mob/living/user)
	var/ritual_level
	for(var/i = 1 to 3)
		if(!user)
			reset()
			return
		if(!do_after(user, 2 SECONDS))
			to_chat(user, span_danger("You lose your focus, and the ritual is cut short!"))
			balloon_alert(user, "You lose your focus, and the ritual is cut short!")
			break
		playsound(user, 'sound/effects/curse5.ogg', 60, TRUE)
		if((cultist_check(user) < 1 + i))
			break
		ritual_level++
	ritual_end(user, ritual_level)

/obj/item/ego_weapon/faith/proc/ritual_end(mob/living/user, ritual_level)
	ritual_master = FALSE
	ritual_ongoing = FALSE
	if(!ritual_level)
		return
	for(var/mob/living/carbon/human/cultman in oview(4, user))
		if(cultman.has_status_effect(/datum/status_effect/starcultist))
			var/obj/item/ego_weapon/faith/cultist_wand = cultman.is_holding_item_of_type(/obj/item/ego_weapon/faith)
			if(cultist_wand)
				if(cultist_wand.ritual_synchronization)
					cultist_wand.ritual_effect(ritual_level)
	ritual_effect(user, ritual_level)

/obj/item/ego_weapon/faith/proc/ritual_effect(mob/living/user, ritual_level)
	if(ritual_active)
		return
	ritual_active = TRUE
	set_light_on(ritual_active)
	light_range = ritual_level
	switch(ritual_level)
		if(1)
			to_chat(user, span_nicegreen("Your staff slightly loosens its grasp on the holy marble and you feel a surge of courage coursing through you."))
			balloon_alert(user, "Your staff slightly loosens it's grasp on the holy marble and you feel a surge of courage coursing through you.")
			healing = TRUE
		if(2)
			to_chat(user, span_nicegreen("Your staff loosens its grasp on the holy marble and its light invigorates your every swing."))
			balloon_alert(user, "Your staff loosens it's grasp on the holy marble and it's light invigorates your every swing.")
			healing = TRUE
			force += 25
		if(3)
			to_chat(user, span_nicegreen("The Star is unbound if only for a moment, illuminating your path with its majestic light and empowering your attacks with otherwordly energy."))
			balloon_alert(user, "The Star is unbound if only for a moment, illuminating your path with it's majestic light and empowering your attacks with otherworldy energy.")
			icon_state = "awakened_faith"
			healing = TRUE
			force += 45
			awakened = TRUE

	//icon_state = "faith[ritual_level]" 	-Probably will remain this way, but it would be nice to have alternative sprites for every ritual level.
	buff_timer = addtimer(CALLBACK(src, PROC_REF(remove_effects)), ritual_duration, TIMER_STOPPABLE)

/obj/item/ego_weapon/faith/proc/remove_effects()
	reset()

/obj/item/ego_weapon/faith/proc/reset()
	icon_state = initial(icon_state)
	force = initial(force)
	ritual_ongoing = FALSE
	ritual_active = FALSE
	ritual_master = FALSE
	ritual_synchronization = FALSE
	healing = FALSE
	awakened = FALSE
	set_light_on(ritual_active)
	light_range = initial(light_range)

/obj/projectile/ego_bullet/star_bound
	name = "starbound energy"
	damage = 85
	damage_type = WHITE_DAMAGE
	icon_state = "star"
