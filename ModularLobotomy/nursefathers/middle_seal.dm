/// Laevateinn Seal System — manages HP healthgates and unseal progression.
/// Attached to the Middle Nursefather. Monitors HP thresholds at 75%, 50%, 25%.
/// Uses COMSIG_MOB_APPLY_DAMGE to check HP after each hit.
/datum/component/laevateinn_seal
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Reference to the Laevateinn weapon
	var/obj/item/ego_weapon/city/laevateinn/weapon
	/// HP thresholds for each gate (populated on first damage check)
	var/list/gate_thresholds
	/// Whether each gate has been triggered
	var/list/gates_triggered = list(FALSE, FALSE, FALSE)
	/// Whether an unseal cutscene is currently playing
	var/unsealing = FALSE
	/// Whether thresholds have been initialized
	var/thresholds_initialized = FALSE
	/// Whether the overheat aura is active (seal stage 2+)
	var/overheat_aura_active = FALSE
	/// Next world.time the overheat aura ticks
	var/next_aura_tick = 0

/datum/component/laevateinn_seal/Initialize(obj/item/ego_weapon/city/laevateinn/_weapon)
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	weapon = _weapon

/datum/component/laevateinn_seal/RegisterWithParent()
	return

/datum/component/laevateinn_seal/UnregisterFromParent()
	return

/datum/component/laevateinn_seal/Destroy()
	if(overheat_aura_active)
		STOP_PROCESSING(SSobj, src)
	weapon = null
	return ..()

/// Overheat aura — ticks every 3 seconds. Stage 2: 2 overheat to nearby, 1 to self. Stage 3: 5 to nearby, 2 to self.
/datum/component/laevateinn_seal/process(delta_time)
	if(!overheat_aura_active || QDELETED(parent))
		STOP_PROCESSING(SSobj, src)
		return

	if(world.time < next_aura_tick)
		return
	next_aura_tick = world.time + 3 SECONDS

	var/mob/living/carbon/human/H = parent
	if(H.stat == DEAD)
		return

	var/nearby_overheat
	var/self_overheat
	var/aura_range
	if(weapon?.seal_stage >= 3)
		nearby_overheat = 5
		self_overheat = 2
		aura_range = 7
	else
		nearby_overheat = 2
		self_overheat = 1
		aura_range = 5

	for(var/mob/living/L in range(aura_range, H))
		if(L == H)
			continue
		L.apply_lc_overheat(nearby_overheat)

	H.apply_lc_overheat(self_overheat)

/// Initializes gate thresholds based on current maxHealth. Called on first damage check.
/datum/component/laevateinn_seal/proc/InitThresholds()
	var/mob/living/carbon/human/H = parent
	if(!istype(H))
		return
	H.updatehealth()
	var/max_hp = H.maxHealth
	gate_thresholds = list(max_hp * 0.75, max_hp * 0.50, max_hp * 0.25)
	thresholds_initialized = TRUE

/// Called by nursefather_passive/middle when damage is taken.
/// Checks if this damage will push HP past a healthgate threshold.
/datum/component/laevateinn_seal/proc/CheckHealthgate(damage)
	if(unsealing || !damage || damage <= 0)
		return

	if(!thresholds_initialized)
		InitThresholds()

	var/mob/living/carbon/human/H = parent
	var/current_hp = H.health
	var/projected_hp = current_hp - damage

	for(var/i in 1 to 3)
		if(gates_triggered[i])
			continue
		var/gate_hp = gate_thresholds[i]
		// Trigger if damage crosses the gate OR if HP is already below the gate (e.g. after resealing)
		if((current_hp > gate_hp && projected_hp <= gate_hp) || (current_hp <= gate_hp))
			gates_triggered[i] = TRUE
			INVOKE_ASYNC(src, PROC_REF(trigger_unseal), i)
			return

/// Triggers the unseal cutscene for the given gate index (1-3).
/datum/component/laevateinn_seal/proc/trigger_unseal(gate_index)
	if(!weapon || QDELETED(parent))
		return

	var/mob/living/carbon/human/H = parent
	unsealing = TRUE

	weapon.SetSealStage(gate_index)

	switch(gate_index)
		if(1)
			H.visible_message(span_userdanger("[H] tears a seal from Laevateinn! The blade begins to glow."))
			H.say("Oh yeah, I'm down to unbox a layer of packaging for this fight!")
		if(2)
			H.visible_message(span_userdanger("[H] rips another seal free! Laevateinn burns with growing intensity!"))
			H.say("Interesting... So this is what it feels like to meet a Great Foe in battle!")
			H.set_light(3, 2, LIGHT_COLOR_FIRE)
			if(!overheat_aura_active)
				overheat_aura_active = TRUE
				START_PROCESSING(SSobj, src)
		if(3)
			H.visible_message(span_userdanger("[H] shatters the final seal! Laevateinn erupts in full, burning fury!"))
			H.say("You're pushin' me to go balls out... Hah!")
			H.set_light(5, 3, LIGHT_COLOR_FIRE)

	new /obj/effect/temp_visual/dir_setting/laevateinn_blast(get_turf(H))
	playsound(H, 'sound/effects/explosion1.ogg', 50, TRUE)
	for(var/mob/M in viewers(7, get_turf(H)))
		shake_camera(M, 3, 4)

	spawn_seal_structure(H)

	sleep(1.5 SECONDS)
	unsealing = FALSE

/// Spawns a warning effect, then a seal structure on a random nearby tile.
/datum/component/laevateinn_seal/proc/spawn_seal_structure(mob/living/carbon/human/H)
	var/list/valid_turfs = list()
	for(var/turf/open/T in orange(2, H))
		if(!T.density)
			valid_turfs += T
	if(!length(valid_turfs))
		return

	var/turf/chosen = pick(valid_turfs)
	new /obj/effect/temp_visual/seal_warning(chosen)
	addtimer(CALLBACK(src, PROC_REF(place_seal), chosen), 1.5 SECONDS)

/// Places the actual seal structure after the warning, with a falling animation from the nursefather's direction.
/datum/component/laevateinn_seal/proc/place_seal(turf/T)
	if(QDELETED(src))
		return
	var/obj/structure/laevateinn_seal/seal = new(T)
	seal.alpha = 0

	var/mob/living/carbon/human/H = parent
	var/start_x = 0
	var/start_y = 32
	if(!QDELETED(H))
		var/dir_from = get_dir(T, get_turf(H))
		switch(dir_from)
			if(NORTH)
				start_x = 0
				start_y = 48
			if(SOUTH)
				start_x = 0
				start_y = -16
			if(EAST)
				start_x = 32
				start_y = 32
			if(WEST)
				start_x = -32
				start_y = 32
			if(NORTHEAST)
				start_x = 24
				start_y = 48
			if(NORTHWEST)
				start_x = -24
				start_y = 48
			if(SOUTHEAST)
				start_x = 24
				start_y = -16
			if(SOUTHWEST)
				start_x = -24
				start_y = -16

	seal.pixel_x = seal.base_pixel_x + start_x
	seal.pixel_y = seal.base_pixel_y + start_y
	animate(seal, pixel_x = seal.base_pixel_x, pixel_y = seal.base_pixel_y, alpha = 255, time = 0.5 SECONDS, easing = BOUNCE_EASING)
	playsound(T, 'sound/effects/meteorimpact.ogg', 40, TRUE)
	new /obj/effect/temp_visual/middle_slam(T)
