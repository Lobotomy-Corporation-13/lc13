// Priest Fixer - Lauel / Redeemed Star
// A pacifist support/tank boss that protects allies via Lifelink

/mob/living/simple_animal/hostile/humanoid/fixer/priest
	name = "Redeemed Star"
	desc = "Too young to be called a man, but too mature to be called a boy. He had white hair and white skin. His eyes are calm and he had stubborn lips."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "priest"
	icon_living = "priest"
	faction = list("echo_office")
	gender = MALE
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	robust_searching = TRUE
	density = FALSE
	see_in_dark = 7
	vision_range = 12
	aggro_vision_range = 20
	move_to_delay = 4
	stat_attack = HARD_CRIT
	maxHealth = 2500
	health = 2500
	melee_damage_lower = 0
	melee_damage_upper = 0
	melee_damage_type = RED_DAMAGE
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.5, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 0.8)
	a_intent = INTENT_HARM
	mob_size = MOB_SIZE_HUGE
	loot_armor = list(
		/obj/item/clothing/suit/armor/ego_gear/city/echo/stars,
	)

	// Lifelink System
	var/list/lifelinked_mobs = list()
	var/max_lifelinks = 4
	var/lifelink_range = 6
	var/list/lifelink_beams = list()
	var/lifelink_damage_reduction = 0.5

	// Feeble System (tracked as vars, not status effect)
	var/feeble_stacks = 0
	var/max_feeble_stacks = 5
	var/base_stagger_mult = 0.5
	var/feeble_stagger_bonus = 0.3
	var/feeble_decay_time = 10 SECONDS
	var/list/feeble_wisps = list()

	// Stagger System
	var/stagger_amount = 0
	var/max_stagger = 750
	var/stagger_decay_rate = 40
	var/stagger_decay_time = 2 SECONDS
	var/stagger_stun_duration = 5 SECONDS
	var/is_staggered = FALSE
	// Stagger resistance changes (more vulnerable when staggered)
	var/list/stagger_resistances = list(RED_DAMAGE = 1.0, WHITE_DAMAGE = 1.0, BLACK_DAMAGE = 1.0, PALE_DAMAGE = 1.6)
	var/list/normal_resistances = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 0.8)

	// Intercept System
	var/counter_delay = 1.5 SECONDS
	var/counter_damage = 40
	var/counter_range = 2
	var/guard_sound = 'sound/weapons/purple_tear/guard.ogg'
	var/guard_sound_cooldown = 1 SECONDS
	var/last_guard_sound = 0
	var/intercept_count = 0
	var/intercepts_per_feeble = 2
	var/performing_counter = FALSE

	// Crisis Mode
	var/crisis_mode = FALSE
	var/crisis_power_boost = 0.3

	// Voice line cooldown
	var/last_voice_line = 0
	var/voice_line_cooldown = 4 SECONDS

	// Processing
	var/lifelink_update_timer
	var/stagger_decay_timer
	var/feeble_decay_timer
	/// Current stagger bar overlay reference
	var/mutable_appearance/current_stagger_bar

/mob/living/simple_animal/hostile/humanoid/fixer/priest/Initialize()
	. = ..()
	// Create wisps
	SpawnWisps()
	// Create stagger bar
	CreateStaggerBar()
	// Start processing timers
	lifelink_update_timer = addtimer(CALLBACK(src, PROC_REF(UpdateLifelinks)), 1 SECONDS, TIMER_LOOP|TIMER_STOPPABLE)
	stagger_decay_timer = addtimer(CALLBACK(src, PROC_REF(DecayStagger)), stagger_decay_time, TIMER_LOOP|TIMER_STOPPABLE)
	feeble_decay_timer = addtimer(CALLBACK(src, PROC_REF(DecayFeeble)), feeble_decay_time, TIMER_LOOP|TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/humanoid/fixer/priest/Destroy()
	// Clean up beams
	for(var/datum/beam/B in lifelink_beams)
		QDEL_NULL(B)
	lifelink_beams.Cut()
	// Clean up wisps
	for(var/obj/effect/wisp/W in feeble_wisps)
		QDEL_NULL(W)
	feeble_wisps.Cut()
	// Clean up timers
	deltimer(lifelink_update_timer)
	deltimer(stagger_decay_timer)
	deltimer(feeble_decay_timer)
	// Remove lifelinks from allies
	for(var/mob/living/M in lifelinked_mobs)
		M.remove_status_effect(/datum/status_effect/lifelinked)
	lifelinked_mobs.Cut()
	return ..()

// Voice line with cooldown check
/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/TrySay(message)
	if(world.time < last_voice_line + voice_line_cooldown)
		return
	last_voice_line = world.time
	say(message)

// Wisps represent Feeble stacks (5 wisps = 0 stacks, 0 wisps = 5 stacks)
/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/SpawnWisps()
	var/wisps_to_spawn = max_feeble_stacks - feeble_stacks
	// Remove existing wisps first
	for(var/obj/effect/wisp/W in feeble_wisps)
		qdel(W)
	feeble_wisps.Cut()
	// Spawn new wisps with delays so they spread out in orbit
	for(var/i in 1 to wisps_to_spawn)
		addtimer(CALLBACK(src, PROC_REF(SpawnSingleWisp)), (i - 1) * 3)  // 0.3 second delay between each

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/SpawnSingleWisp()
	if(stat == DEAD)
		return
	var/obj/effect/wisp/priest/W = new(get_turf(src))
	W.orbit(src, 20)
	feeble_wisps += W

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/UpdateWisps()
	var/target_wisps = max_feeble_stacks - feeble_stacks
	var/current_wisps = feeble_wisps.len
	if(target_wisps < current_wisps)
		// Remove wisps
		var/to_remove = current_wisps - target_wisps
		for(var/i in 1 to to_remove)
			if(feeble_wisps.len)
				var/obj/effect/wisp/W = feeble_wisps[feeble_wisps.len]
				feeble_wisps -= W
				qdel(W)
	else if(target_wisps > current_wisps)
		// Add wisps with delays so they spread out
		var/wisps_to_add = target_wisps - current_wisps
		for(var/i in 1 to wisps_to_add)
			addtimer(CALLBACK(src, PROC_REF(SpawnSingleWisp)), (i - 1) * 3)

// Stagger bar (inverted - shows stability remaining)
/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/CreateStaggerBar()
	current_stagger_bar = mutable_appearance('icons/effects/progessbar.dmi', "prog_bar_100", ABOVE_MOB_LAYER)
	current_stagger_bar.pixel_y = 32
	add_overlay(current_stagger_bar)

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/UpdateStaggerBar()
	// Remove only the stagger bar overlay, preserve other overlays
	if(current_stagger_bar)
		cut_overlay(current_stagger_bar)
	var/stability_percent = round(((max_stagger - stagger_amount) / max_stagger) * 100, 5)
	stability_percent = clamp(stability_percent, 0, 100)
	current_stagger_bar = mutable_appearance('icons/effects/progessbar.dmi', "prog_bar_[stability_percent]", ABOVE_MOB_LAYER)
	current_stagger_bar.pixel_y = 32
	add_overlay(current_stagger_bar)

// Lifelink Management
/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/UpdateLifelinks()
	if(stat == DEAD || is_staggered)
		return
	// Find potential allies to link
	var/list/potential_allies = list()
	for(var/mob/living/M in view(lifelink_range, src))
		if(M == src)
			continue
		if(M.stat == DEAD)
			continue
		if(!faction_check_mob(M, FALSE))
			continue
		if(M in lifelinked_mobs)
			continue
		potential_allies += M
	// Prioritize echo_office faction allies
	var/list/echo_allies = list()
	var/list/other_allies = list()
	for(var/mob/living/M in potential_allies)
		if(istype(M, /mob/living/simple_animal/hostile))
			var/mob/living/simple_animal/hostile/H = M
			if("echo_office" in H.faction)
				echo_allies += M
				continue
		other_allies += M
	// Add links up to max
	while(lifelinked_mobs.len < max_lifelinks && (echo_allies.len || other_allies.len))
		var/mob/living/to_link
		if(echo_allies.len)
			to_link = echo_allies[1]
			echo_allies -= to_link
		else if(other_allies.len)
			to_link = other_allies[1]
			other_allies -= to_link
		if(to_link)
			CreateLifelink(to_link)
	// Remove links to dead/distant allies
	for(var/mob/living/M in lifelinked_mobs)
		if(M.stat == DEAD || get_dist(src, M) > lifelink_range * 2)
			RemoveLifelink(M)
	// Update movement target to follow lowest HP ally
	FollowLowestHPAlly()

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/CreateLifelink(mob/living/ally)
	if(ally in lifelinked_mobs)
		return
	lifelinked_mobs += ally
	// Apply status effect to ally
	ally.apply_status_effect(/datum/status_effect/lifelinked, src)
	// Create beam
	var/datum/beam/B = Beam(ally, icon_state="medbeam", time=INFINITY, maxdistance=lifelink_range * 2, beam_type=/obj/effect/ebeam/medical)
	lifelink_beams[ally] = B

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/RemoveLifelink(mob/living/ally)
	if(!(ally in lifelinked_mobs))
		return
	lifelinked_mobs -= ally
	// Remove status effect
	ally.remove_status_effect(/datum/status_effect/lifelinked)
	// Remove beam
	if(lifelink_beams[ally])
		var/datum/beam/B = lifelink_beams[ally]
		qdel(B)
		lifelink_beams -= ally

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/RemoveAllLifelinks()
	for(var/mob/living/M in lifelinked_mobs)
		RemoveLifelink(M)

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/FollowLowestHPAlly()
	if(!lifelinked_mobs.len)
		return
	var/mob/living/lowest_hp_ally
	var/lowest_hp_percent = 1
	for(var/mob/living/M in lifelinked_mobs)
		var/hp_percent = M.health / M.maxHealth
		if(hp_percent < lowest_hp_percent)
			lowest_hp_percent = hp_percent
			lowest_hp_ally = M
	if(lowest_hp_ally && lowest_hp_ally != target)
		// Follow the ally like the clan drone does
		target = lowest_hp_ally
		if(ai_controller)
			ai_controller.current_movement_target = target

// Called by lifelinked status effect when ally takes damage
/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/OnAllyDamaged(mob/living/ally, damage, damage_type, mob/living/attacker)
	if(is_staggered || performing_counter)
		return FALSE
	// Teleport to ally
	var/turf/ally_turf = get_turf(ally)
	forceMove(ally_turf)
	// Play guard sound (with cooldown)
	if(world.time > last_guard_sound + guard_sound_cooldown)
		playsound(src, guard_sound, 75, TRUE)
		TrySay(pick("I'm here.", "It's alright.", "Don't worry, friend."))
		last_guard_sound = world.time
	// Apply reduced damage to self (no stagger)
	var/redirected_damage = damage * lifelink_damage_reduction
	ApplyLifelinkDamage(redirected_damage, damage_type)
	// Increment intercept count
	intercept_count++
	if(intercept_count >= intercepts_per_feeble)
		intercept_count = 0
		AddFeebleStack()
	// Start counter attack
	StartCounterAttack(attacker)
	return TRUE

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/ApplyLifelinkDamage(damage, damage_type)
	// Apply damage without triggering stagger
	switch(damage_type)
		if(RED_DAMAGE)
			adjustRedLoss(damage)
		if(WHITE_DAMAGE)
			adjustWhiteLoss(damage)
		if(BLACK_DAMAGE)
			adjustBlackLoss(damage)
		if(PALE_DAMAGE)
			adjustPaleLoss(damage)
		else
			adjustBruteLoss(damage)

// Don't move during counter attacks or when staggered
/mob/living/simple_animal/hostile/humanoid/fixer/priest/Move()
	if(performing_counter || is_staggered)
		return FALSE
	return ..()

// Counter Attack
/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/StartCounterAttack(mob/living/attacker)
	performing_counter = TRUE
	// Add warning overlay to all turfs in counter range
	for(var/turf/T in range(counter_range, src))
		T.add_overlay(icon('icons/effects/effects.dmi', "galaxy_aura"))
		addtimer(CALLBACK(T, TYPE_PROC_REF(/atom, cut_overlay), icon('icons/effects/effects.dmi', "galaxy_aura")), counter_delay)
	// Visual telegraph on self
	new /obj/effect/temp_visual/cult/sparks(get_turf(src))
	// Delayed AoE counter
	addtimer(CALLBACK(src, PROC_REF(ExecuteCounterAttack)), counter_delay)

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/ExecuteCounterAttack()
	performing_counter = FALSE
	if(stat == DEAD || is_staggered)
		return
	var/actual_damage = counter_damage
	if(crisis_mode)
		actual_damage *= (1 + crisis_power_boost)
	// Deal damage to all enemies in range
	var/list/been_hit = list()
	TrySay(pick("Please, step back.", "I'd rather not do this.", "...If you insist."))
	playsound(src, 'sound/weapons/fixer/generic/finisher1.ogg', 50, TRUE)
	for(var/turf/T in range(counter_range, src))
		new /obj/effect/temp_visual/cult/sparks(T)
		been_hit = HurtInTurf(T, been_hit, actual_damage, PALE_DAMAGE, check_faction = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_COUNTER))

// Stagger System
/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/AddStagger(damage)
	if(is_staggered)
		return
	var/stagger_mult = base_stagger_mult + (feeble_stacks * feeble_stagger_bonus)
	stagger_amount += damage * stagger_mult
	UpdateStaggerBar()
	if(stagger_amount >= max_stagger)
		TriggerStagger()

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/DecayStagger()
	if(is_staggered)
		return
	if(stagger_amount > 0)
		stagger_amount = max(0, stagger_amount - stagger_decay_rate)
		UpdateStaggerBar()

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/TriggerStagger()
	is_staggered = TRUE
	stagger_amount = max_stagger
	UpdateStaggerBar()
	// Disconnect all lifelinks
	RemoveAllLifelinks()
	// Reset feeble stacks
	feeble_stacks = 0
	UpdateWisps()
	// Add stagger overlay and change resistances
	var/mutable_appearance/stagger_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/tegumobs.dmi', "small_stagger", layer + 0.1)
	add_overlay(stagger_overlay)
	ChangeResistances(stagger_resistances)
	say("...Ah. I see.")
	visible_message(span_danger("[src] staggers and falls to their knees!"))
	// Use SLEEP_CHECK_DEATH pattern
	SLEEP_CHECK_DEATH(stagger_stun_duration)
	// Recovery
	ChangeResistances(normal_resistances)
	cut_overlay(stagger_overlay)
	is_staggered = FALSE
	stagger_amount = 0
	UpdateStaggerBar()
	say("...Right. Let's continue, shall we?")
	visible_message(span_notice("[src] recovers their composure."))

// Feeble System
/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/AddFeebleStack()
	if(feeble_stacks < max_feeble_stacks)
		feeble_stacks++
		UpdateWisps()

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/DecayFeeble()
	if(feeble_stacks > 0)
		feeble_stacks--
		UpdateWisps()

// Crisis Mode
/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/CheckCrisisMode()
	if(crisis_mode)
		return
	if(health <= maxHealth * 0.25)
		EnterCrisisMode()

/mob/living/simple_animal/hostile/humanoid/fixer/priest/proc/EnterCrisisMode()
	crisis_mode = TRUE
	// Heal 50% of missing HP
	var/missing_hp = maxHealth - health
	var/heal_amount = missing_hp * 0.5
	adjustBruteLoss(-heal_amount)
	// Add wing overlays
	add_overlay(mutable_appearance('icons/effects/effects.dmi', "breach", ABOVE_MOB_LAYER))
	add_overlay(mutable_appearance('icons/effects/effects.dmi', "galaxy_aura", ABOVE_MOB_LAYER))
	say("Despite all the struggles, I shall remain myself...")
	visible_message(span_danger("Wings of light emerge from [src]'s back!"))

// Override damage handling
/mob/living/simple_animal/hostile/humanoid/fixer/priest/deal_damage(damage_amount, damage_type = BRUTE, source = null, flags = null, attack_type = null, blocked = null, def_zone = null, wound_bonus = 0, bare_wound_bonus = 0, sharpness = SHARP_NONE)
	. = ..()
	// Only add stagger from direct damage (not lifelink)
	AddStagger(damage_amount)
	CheckCrisisMode()

/mob/living/simple_animal/hostile/humanoid/fixer/priest/bullet_act(obj/projectile/P, def_zone, piercing_hit = FALSE)
	. = ..()
	// Stagger is handled in deal_damage

/mob/living/simple_animal/hostile/humanoid/fixer/priest/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	// Stagger is handled in deal_damage

// Pacifist - no direct attacks
/mob/living/simple_animal/hostile/humanoid/fixer/priest/AttackingTarget(atom/attacked_target)
	return FALSE

/mob/living/simple_animal/hostile/humanoid/fixer/priest/OpenFire()
	return FALSE

// Custom wisp subtype for the priest
/obj/effect/wisp/priest
	name = "light fragment"
	desc = "A gentle fragment of light orbiting the priest."
	light_range = 3

// Lifelinked status effect
/datum/status_effect/lifelinked
	id = "lifelinked"
	duration = -1
	alert_type = null
	var/mob/living/simple_animal/hostile/humanoid/fixer/priest/linked_priest

/datum/status_effect/lifelinked/on_creation(mob/living/new_owner, mob/living/simple_animal/hostile/humanoid/fixer/priest)
	linked_priest = priest
	return ..()

/datum/status_effect/lifelinked/on_apply()
	if(!linked_priest || QDELETED(linked_priest))
		return FALSE
	// Register damage signal
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnOwnerDamaged))
	// Visual indicator
	owner.add_overlay(mutable_appearance('icons/effects/effects.dmi', "shield1", -MUTATIONS_LAYER))
	return TRUE

/datum/status_effect/lifelinked/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMGE)
	owner.cut_overlay(mutable_appearance('icons/effects/effects.dmi', "shield1", -MUTATIONS_LAYER))
	linked_priest = null

/datum/status_effect/lifelinked/proc/OnOwnerDamaged(datum/source, damage, damage_type, def_zone, attack_source, flags, attack_type)
	SIGNAL_HANDLER
	if(!linked_priest || QDELETED(linked_priest) || linked_priest.stat == DEAD)
		qdel(src)
		return
	// Get attacker
	var/mob/living/attacker
	if(isliving(attack_source))
		attacker = attack_source
	// Redirect damage to priest (use INVOKE_ASYNC to avoid sleep issues)
	INVOKE_ASYNC(src, PROC_REF(ProcessDamageRedirect), damage, damage_type, attacker)
	// Cancel damage on the ally
	return COMPONENT_MOB_DENY_DAMAGE

/datum/status_effect/lifelinked/proc/ProcessDamageRedirect(damage, damage_type, mob/living/attacker)
	if(!linked_priest || QDELETED(linked_priest) || linked_priest.stat == DEAD)
		return
	linked_priest.OnAllyDamaged(owner, damage, damage_type, attacker)
