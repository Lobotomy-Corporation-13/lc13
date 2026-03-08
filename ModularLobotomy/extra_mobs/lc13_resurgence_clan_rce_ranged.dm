//////////////
// RESURGENCE CLAN RANGED UNITS
//////////////
// Contains all ranged combat units and specialized mobs
// Base ranged type provides charge system and special attack framework
/mob/living/simple_animal/hostile/clan/ranged
	name = "Clan Ranged Unit"
	desc = "A ranged combat unit of the Resurgence Clan."
	icon_state = "clan_scout"
	icon_living = "clan_scout"
	icon_dead = "clan_scout_dead"
	ranged = TRUE
	retreat_distance = 5
	minimum_distance = 4
	ranged_cooldown_time = 30
	projectiletype = /obj/projectile/clan_bullet
	projectilesound = 'sound/weapons/laser.ogg'
	charge = 10
	max_charge = 20
	teleport_away = TRUE
	var/special_attack_cost = 5
	var/special_attack_cooldown = 0
	var/special_attack_cooldown_time = 10 SECONDS

/mob/living/simple_animal/hostile/clan/ranged/OpenFire(atom/A)
	dir = get_cardinal_dir(src, A)
	if(charge >= special_attack_cost && world.time > special_attack_cooldown)
		if(prob(30))
			SpecialAttack(A)
			return
	return ..()

/mob/living/simple_animal/hostile/clan/ranged/proc/SpecialAttack(atom/target)
	return

//////////////
// SNIPER
//////////////
// Long range precision unit with aiming laser
// Special: Piercing shot that goes through all targets
/mob/living/simple_animal/hostile/clan/ranged/sniper
	name = "sniper unit"
	desc = "A long-range precision unit equipped with a high-powered energy rifle."
	icon_state = "clan_sniper"
	maxHealth = 400
	health = 400
	vision_range = 15
	aggro_vision_range = 15
	ranged_cooldown_time = 50
	retreat_distance = 10
	minimum_distance = 8
	projectiletype = /obj/projectile/clan_bullet/sniper
	move_to_delay = 5
	melee_damage_lower = 5
	melee_damage_upper = 10
	var/datum/beam/current_beam = null
	var/aiming = FALSE

/mob/living/simple_animal/hostile/clan/ranged/sniper/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/clan/ranged/sniper/AttackingTarget()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/clan/ranged/sniper/OpenFire(atom/A)
	if(!can_act || aiming)
		return FALSE
	if(PrepareToFire(A))
		return ..()
	return FALSE

/mob/living/simple_animal/hostile/clan/ranged/sniper/proc/PrepareToFire(atom/A)
	// Start aiming sequence
	aiming = TRUE
	can_act = FALSE
	visible_message(span_danger("[src] takes aim at [A]!"))
	playsound(src, 'sound/weapons/beam_sniper.ogg', 75, TRUE)

	// Create aiming beam
	current_beam = Beam(A, icon_state="blood", time = 3 SECONDS)

	// Wait for aim time
	SLEEP_CHECK_DEATH(30)

	// Clean up beam
	if(current_beam)
		QDEL_NULL(current_beam)

	// Check if target is still valid
	if(stat == DEAD)
		can_act = TRUE
		aiming = FALSE
		return FALSE

	can_act = TRUE
	aiming = FALSE
	return TRUE

/mob/living/simple_animal/hostile/clan/ranged/sniper/SpecialAttack(atom/target)
	if(charge < special_attack_cost || world.time < special_attack_cooldown || !can_act || aiming)
		return

	charge -= special_attack_cost
	special_attack_cooldown = world.time + special_attack_cooldown_time

	// Fire piercing shot immediately (no additional delay since we already aimed)
	FirePiercingShot(target)

/mob/living/simple_animal/hostile/clan/ranged/sniper/proc/FirePiercingShot(atom/target)
	if(stat == DEAD || !target)
		return

	visible_message(span_danger("[src] fires a piercing shot!"))
	var/turf/startloc = get_turf(src)
	var/obj/projectile/clan_bullet/piercing/P = new(startloc)
	P.preparePixelProjectile(target, src)
	P.firer = src
	P.fire()
	playsound(src, 'sound/weapons/laser3.ogg', 100, TRUE)

//////////////
// GUNNER
//////////////
// Balanced ranged unit with burst fire capability
// Special: Rapid 3-shot burst
/mob/living/simple_animal/hostile/clan/ranged/gunner
	name = "gunner unit"
	desc = "A standard ranged combat unit with a rapid-fire energy weapon."
	icon_state = "clan_gunner"
	maxHealth = 600
	health = 600
	vision_range = 10
	aggro_vision_range = 10
	ranged_cooldown_time = 10
	retreat_distance = 8
	minimum_distance = 5
	projectiletype = /obj/projectile/clan_bullet/medium
	move_to_delay = 3

/mob/living/simple_animal/hostile/clan/ranged/gunner/SpecialAttack(atom/target)
	if(charge < special_attack_cost || world.time < special_attack_cooldown)
		return

	charge -= special_attack_cost
	special_attack_cooldown = world.time + special_attack_cooldown_time

	visible_message(span_danger("[src] unleashes a burst of fire!"))
	playsound(src, 'sound/weapons/fixer/generic/energy1.ogg', 75, TRUE)

	// Fire 3 shots in quick succession
	for(var/i in 1 to 3)
		addtimer(CALLBACK(src, PROC_REF(BurstFire), target), i * 2)

/mob/living/simple_animal/hostile/clan/ranged/gunner/proc/BurstFire(atom/target)
	if(stat == DEAD || !target)
		return

	var/turf/startloc = get_turf(src)
	var/obj/projectile/clan_bullet/medium/P = new(startloc)
	P.preparePixelProjectile(target, src)
	P.firer = src
	P.fire()
	playsound(src, projectilesound, 50, TRUE)

//////////////
// RAPID UNIT
//////////////
// High fire rate suppression specialist
// Special: Overdrive mode for increased rate of fire
/mob/living/simple_animal/hostile/clan/ranged/rapid
	name = "rapid unit"
	desc = "A agile unit equipped with a micro-blasters."
	icon_state = "clan_rapid"
	maxHealth = 300
	health = 300
	vision_range = 7
	aggro_vision_range = 7
	ranged_cooldown_time = 15 // Time between volleys
	retreat_distance = 6
	minimum_distance = 4
	projectiletype = /obj/projectile/clan_bullet/rapid
	move_to_delay = 2
	move_resist = MOVE_FORCE_NORMAL
	rapid = 3 // Fires 3 shots per volley
	rapid_fire_delay = 2 // 0.2 seconds between shots in volley

/mob/living/simple_animal/hostile/clan/ranged/rapid/SpecialAttack(atom/target)
	if(charge < special_attack_cost || world.time < special_attack_cooldown)
		return

	charge -= special_attack_cost
	special_attack_cooldown = world.time + special_attack_cooldown_time

	visible_message(span_danger("[src] overclocks its weapons!"))
	playsound(src, 'sound/weapons/marauder.ogg', 75, TRUE)

	// Temporarily increase volley size and decrease cooldown
	rapid = 5 // Fire 5 shots instead of 3
	ranged_cooldown_time = 8 // Faster volleys
	addtimer(CALLBACK(src, PROC_REF(ResetFireRate)), 5 SECONDS)

/mob/living/simple_animal/hostile/clan/ranged/rapid/proc/ResetFireRate()
	rapid = initial(rapid)
	ranged_cooldown_time = initial(ranged_cooldown_time)
	visible_message(span_notice("[src]'s weapons return to normal."))

//////////////
// PROJECTILES
//////////////
// ==================== MILITIA RANGED VARIANTS ====================
// Weaker early-game ranged units for raids before 45 minutes.

/// Militia Rapid - weaker suppression unit for early raids
/mob/living/simple_animal/hostile/clan/ranged/rapid/militia
	name = "militia rapid unit"
	desc = "A crudely built rapid-fire unit. Its weapons are inaccurate and underpowered."
	maxHealth = 150
	health = 150
	rapid = 2
	projectiletype = /obj/projectile/clan_bullet/rapid/militia

/// Militia rapid units have no overdrive special attack
/mob/living/simple_animal/hostile/clan/ranged/rapid/militia/SpecialAttack(atom/target)
	return

/// Militia Gunner - weaker gunner for early raids
/mob/living/simple_animal/hostile/clan/ranged/gunner/militia
	name = "militia gunner"
	desc = "A makeshift ranged unit with a weak energy weapon. Its shots lack punch."
	maxHealth = 300
	health = 300
	ranged_cooldown_time = 15
	projectiletype = /obj/projectile/clan_bullet/medium/militia

/// Militia gunners fire 2-shot bursts instead of 3
/mob/living/simple_animal/hostile/clan/ranged/gunner/militia/SpecialAttack(atom/target)
	if(charge < special_attack_cost || world.time < special_attack_cooldown)
		return
	charge -= special_attack_cost
	special_attack_cooldown = world.time + special_attack_cooldown_time
	visible_message(span_danger("[src] unleashes a burst of fire!"))
	playsound(src, 'sound/weapons/fixer/generic/energy1.ogg', 75, TRUE)
	for(var/i in 1 to 2)
		addtimer(CALLBACK(src, PROC_REF(BurstFire), target), i * 2)

// ==================== VETERAN RANGED VARIANTS ====================
// Stronger ranged units for mid-late game (60-90 minutes).

/// Veteran Rapid - tougher suppression unit
/mob/living/simple_animal/hostile/clan/ranged/rapid/veteran
	name = "veteran rapid unit"
	desc = "A battle-proven rapid-fire unit with upgraded targeting systems."
	maxHealth = 450
	health = 450
	projectiletype = /obj/projectile/clan_bullet/rapid/veteran

/// Veteran Gunner - tougher gunner
/mob/living/simple_animal/hostile/clan/ranged/gunner/veteran
	name = "veteran gunner"
	desc = "A hardened ranged unit with a high-output energy weapon."
	maxHealth = 900
	health = 900
	projectiletype = /obj/projectile/clan_bullet/medium/veteran

/// Veteran Sniper - tougher sniper
/mob/living/simple_animal/hostile/clan/ranged/sniper/veteran
	name = "veteran sniper unit"
	desc = "A seasoned marksman unit. Its shots hit harder and its aim is unerring."
	maxHealth = 600
	health = 600
	projectiletype = /obj/projectile/clan_bullet/sniper/veteran

/// Veteran Harpooner - tougher harpooner with higher drop damage
/mob/living/simple_animal/hostile/clan/ranged/harpooner/veteran
	name = "veteran harpooner"
	desc = "An experienced chain specialist with reinforced harpoons and stronger winches."
	maxHealth = 900
	health = 900
	projectiletype = /obj/projectile/clan_bullet/medium/veteran
	final_damage = 70

/// Veteran Warper - tougher warper with faster channel
/mob/living/simple_animal/hostile/clan/ranged/warper/veteran
	name = "veteran warper"
	desc = "A practiced spatial manipulator. Its teleportation channels complete faster."
	maxHealth = 700
	health = 700
	projectiletype = /obj/projectile/clan_bullet/warper/veteran

/// Veteran warper channels in 8 seconds instead of 10
/mob/living/simple_animal/hostile/clan/ranged/warper/veteran/SpecialAttack(atom/target)
	if(charge < special_attack_cost || world.time < special_attack_cooldown || casting || !isliving(target))
		return
	var/found_allies = FALSE
	for(var/mob/living/L in range(2, src))
		if(L == src)
			continue
		if(faction_check_mob(L))
			found_allies = TRUE
			break
	if(!found_allies)
		return
	charge -= special_attack_cost
	special_attack_cooldown = world.time + special_attack_cooldown_time
	var/turf/target_turf = get_turf(target)
	visible_message(span_danger("[src] marks [target] for spatial displacement!"))
	playsound(src, 'sound/magic/blind.ogg', 75, TRUE)
	if(current_mark)
		qdel(current_mark)
	current_mark = new /obj/effect/warper_mark(target_turf)
	casting = TRUE
	magic_circle = new /obj/effect/clan_magic_circle(get_turf(src))
	magic_circle.icon_state = "fellcircle"
	var/matrix/M = matrix(magic_circle.transform)
	M.Translate(0, 16)
	var/rot_angle = Get_Angle(get_turf(src), target_turf)
	M.Turn(rot_angle)
	switch(dir)
		if(EAST)
			M.Scale(0.5, 1)
		if(WEST)
			M.Scale(0.5, 1)
		if(NORTH)
			magic_circle.layer -= 0.2
	magic_circle.transform = M
	var/turf/center = get_turf(src)
	for(var/turf/T in range(4, center))
		var/obj/effect/temp_visual/warper_area/W = new(T)
		area_markers += W
	visible_message(span_userdanger("[src] begins channeling a mass teleportation!"))
	playsound(src, 'sound/magic/charge.ogg', 100, TRUE)
	addtimer(CALLBACK(src, PROC_REF(CompleteTeleport), center), 8 SECONDS)

// ==================== ELITE RANGED VARIANTS ====================
// Endgame ranged units for 90+ minutes.

/// Elite Rapid - endgame suppression with 4-shot volleys
/mob/living/simple_animal/hostile/clan/ranged/rapid/elite
	name = "elite rapid unit"
	desc = "A masterwork suppression platform. Its quad-barrel design delivers withering barrages."
	maxHealth = 600
	health = 600
	rapid = 4
	projectiletype = /obj/projectile/clan_bullet/rapid/elite

/// Elite rapid overdrive fires 6 shots for 7 seconds
/mob/living/simple_animal/hostile/clan/ranged/rapid/elite/SpecialAttack(atom/target)
	if(charge < special_attack_cost || world.time < special_attack_cooldown)
		return
	charge -= special_attack_cost
	special_attack_cooldown = world.time + special_attack_cooldown_time
	visible_message(span_danger("[src] overclocks its weapons!"))
	playsound(src, 'sound/weapons/marauder.ogg', 75, TRUE)
	rapid = 6
	ranged_cooldown_time = 8
	addtimer(CALLBACK(src, PROC_REF(ResetFireRate)), 7 SECONDS)

/// Elite Gunner - endgame gunner with 4-shot burst
/mob/living/simple_animal/hostile/clan/ranged/gunner/elite
	name = "elite gunner"
	desc = "A devastating ranged platform with an overcharged energy cannon."
	maxHealth = 1200
	health = 1200
	projectiletype = /obj/projectile/clan_bullet/medium/elite

/// Elite gunner fires 4-shot bursts
/mob/living/simple_animal/hostile/clan/ranged/gunner/elite/SpecialAttack(atom/target)
	if(charge < special_attack_cost || world.time < special_attack_cooldown)
		return
	charge -= special_attack_cost
	special_attack_cooldown = world.time + special_attack_cooldown_time
	visible_message(span_danger("[src] unleashes a devastating burst!"))
	playsound(src, 'sound/weapons/fixer/generic/energy1.ogg', 75, TRUE)
	for(var/i in 1 to 4)
		addtimer(CALLBACK(src, PROC_REF(BurstFire), target), i * 2)

/// Elite Sniper - endgame sniper
/mob/living/simple_animal/hostile/clan/ranged/sniper/elite
	name = "elite sniper unit"
	desc = "The pinnacle of clan marksman engineering. A single shot can pierce through an entire squad."
	maxHealth = 800
	health = 800
	projectiletype = /obj/projectile/clan_bullet/sniper/elite

/// Elite Harpooner - endgame harpooner
/mob/living/simple_animal/hostile/clan/ranged/harpooner/elite
	name = "elite harpooner"
	desc = "A masterwork chain specialist. Its harpoons are barbed and its winch can drag targets at terrifying speed."
	maxHealth = 1200
	health = 1200
	projectiletype = /obj/projectile/clan_bullet/medium/elite
	final_damage = 80

/// Elite Warper - endgame warper with 7s channel
/mob/living/simple_animal/hostile/clan/ranged/warper/elite
	name = "elite warper"
	desc = "A master of spatial manipulation. Its teleportation channels are nearly instant."
	maxHealth = 800
	health = 800
	projectiletype = /obj/projectile/clan_bullet/warper/elite

/// Elite warper channels in 7 seconds instead of 10
/mob/living/simple_animal/hostile/clan/ranged/warper/elite/SpecialAttack(atom/target)
	if(charge < special_attack_cost || world.time < special_attack_cooldown || casting || !isliving(target))
		return
	var/found_allies = FALSE
	for(var/mob/living/L in range(2, src))
		if(L == src)
			continue
		if(faction_check_mob(L))
			found_allies = TRUE
			break
	if(!found_allies)
		return
	charge -= special_attack_cost
	special_attack_cooldown = world.time + special_attack_cooldown_time
	var/turf/target_turf = get_turf(target)
	visible_message(span_danger("[src] marks [target] for spatial displacement!"))
	playsound(src, 'sound/magic/blind.ogg', 75, TRUE)
	if(current_mark)
		qdel(current_mark)
	current_mark = new /obj/effect/warper_mark(target_turf)
	casting = TRUE
	magic_circle = new /obj/effect/clan_magic_circle(get_turf(src))
	magic_circle.icon_state = "fellcircle"
	var/matrix/M = matrix(magic_circle.transform)
	M.Translate(0, 16)
	var/rot_angle = Get_Angle(get_turf(src), target_turf)
	M.Turn(rot_angle)
	switch(dir)
		if(EAST)
			M.Scale(0.5, 1)
		if(WEST)
			M.Scale(0.5, 1)
		if(NORTH)
			magic_circle.layer -= 0.2
	magic_circle.transform = M
	var/turf/center = get_turf(src)
	for(var/turf/T in range(4, center))
		var/obj/effect/temp_visual/warper_area/W = new(T)
		area_markers += W
	visible_message(span_userdanger("[src] begins channeling a mass teleportation!"))
	playsound(src, 'sound/magic/charge.ogg', 100, TRUE)
	addtimer(CALLBACK(src, PROC_REF(CompleteTeleport), center), 7 SECONDS)

// ==================== PROJECTILES ====================

/obj/projectile/clan_bullet
	name = "energy bolt"
	icon_state = "laser"
	damage = 15
	damage_type = RED_DAMAGE
	projectile_piercing = PASSMOB
	var/passed_faction_mobs = 0
	/// Damage multiplier against resurgence_machine species
	var/resurgence_damage_mult = 1.5

/obj/projectile/clan_bullet/on_hit(atom/target, blocked = FALSE)
	if(isliving(target) && isliving(firer))
		var/mob/living/L = target
		var/mob/living/shooter = firer
		if(shooter.faction_check_mob(L))
			passed_faction_mobs++
			return BULLET_ACT_FORCE_PIERCE
	// Deal triple damage to resurgence_machine species
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(H.dna?.species?.id == "resurgence_machine")
			damage *= resurgence_damage_mult
	..()

/obj/projectile/clan_bullet/prehit_pierce(atom/A)
	if(isliving(A) && isliving(firer))
		var/mob/living/L = A
		var/mob/living/shooter = firer
		if(shooter.faction_check_mob(L))
			return PROJECTILE_PIERCE_HIT
	return ..()

/obj/projectile/clan_bullet/sniper
	name = "high-energy bolt"
	damage = 50
	speed = 0.3

/obj/projectile/clan_bullet/piercing
	name = "piercing energy bolt"
	damage = 60
	speed = 0.3

/obj/projectile/clan_bullet/medium
	damage = 15

/obj/projectile/clan_bullet/rapid
	name = "micro energy bolt"
	damage = 5
	speed = 0.5

/obj/projectile/clan_bullet/rapid/militia
	name = "weak micro bolt"
	damage = 3

/obj/projectile/clan_bullet/medium/militia
	name = "weak energy bolt"
	damage = 10

// Veteran projectiles
/obj/projectile/clan_bullet/rapid/veteran
	name = "hardened micro bolt"
	damage = 7

/obj/projectile/clan_bullet/medium/veteran
	name = "hardened energy bolt"
	damage = 20

/obj/projectile/clan_bullet/sniper/veteran
	name = "hardened high-energy bolt"
	damage = 65

/obj/projectile/clan_bullet/piercing/veteran
	name = "hardened piercing bolt"
	damage = 80

/obj/projectile/clan_bullet/warper/veteran
	name = "hardened void bolt"
	icon_state = "purplelaser"
	damage = 25
	damage_type = BLACK_DAMAGE

// Elite projectiles
/obj/projectile/clan_bullet/rapid/elite
	name = "supercharged micro bolt"
	damage = 10

/obj/projectile/clan_bullet/medium/elite
	name = "supercharged energy bolt"
	damage = 25

/obj/projectile/clan_bullet/sniper/elite
	name = "supercharged high-energy bolt"
	damage = 80

/obj/projectile/clan_bullet/piercing/elite
	name = "supercharged piercing bolt"
	damage = 100

/obj/projectile/clan_bullet/warper/elite
	name = "supercharged void bolt"
	icon_state = "purplelaser"
	damage = 30
	damage_type = BLACK_DAMAGE

/obj/projectile/clan_bullet/warper
	name = "void bolt"
	icon_state = "purplelaser"
	damage = 20
	damage_type = BLACK_DAMAGE
	speed = 0.8

//////////////
// WARPER
//////////////
// Area teleportation specialist
// Channels for 10 seconds to mass teleport allies
/mob/living/simple_animal/hostile/clan/ranged/warper
	name = "warper unit"
	desc = "A specialized unit with spatial manipulation technology."
	icon_state = "clan_warper"
	maxHealth = 500
	health = 500
	vision_range = 12
	aggro_vision_range = 12
	ranged_cooldown_time = 60 // Long cooldown for powerful ability
	retreat_distance = 10
	minimum_distance = 8
	projectiletype = /obj/projectile/clan_bullet/warper
	move_to_delay = 4
	melee_damage_lower = 5
	melee_damage_upper = 10
	special_attack_cost = 10 // Costs more charge
	special_attack_cooldown_time = 30 SECONDS
	var/obj/effect/warper_mark/current_mark
	var/casting = FALSE
	var/list/obj/effect/temp_visual/warper_area/area_markers = list()
	var/obj/effect/clan_magic_circle/magic_circle

/mob/living/simple_animal/hostile/clan/ranged/warper/Move()
	if(casting)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/clan/ranged/warper/CanAttack(atom/the_target)
	if(casting)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/clan/ranged/warper/OpenFire(atom/A)
	if(casting)
		return FALSE
	if(charge >= special_attack_cost && world.time > special_attack_cooldown)
		if(prob(50)) // Higher chance to use special
			SpecialAttack(A)
			return
	return ..()

/mob/living/simple_animal/hostile/clan/ranged/warper/SpecialAttack(atom/target)
	if(charge < special_attack_cost || world.time < special_attack_cooldown || casting || !isliving(target))
		return

	// Check if there are any ally mobs in range to teleport
	var/found_allies = FALSE
	for(var/mob/living/L in range(2, src))
		if(L == src)
			continue
		if(faction_check_mob(L))
			found_allies = TRUE
			break

	if(!found_allies)
		return // Don't waste charge if no allies to teleport

	charge -= special_attack_cost
	special_attack_cooldown = world.time + special_attack_cooldown_time

	// Place mark at target
	var/turf/target_turf = get_turf(target)
	visible_message(span_danger("[src] marks [target] for spatial displacement!"))
	playsound(src, 'sound/magic/blind.ogg', 75, TRUE)

	// Create the destination mark
	if(current_mark)
		qdel(current_mark)
	current_mark = new /obj/effect/warper_mark(target_turf)

	// Start casting
	casting = TRUE

	// Create magic circle visual effect
	magic_circle = new /obj/effect/clan_magic_circle(get_turf(src))
	magic_circle.icon_state = "fellcircle"

	// Adjust circle position and orientation similar to dragonskull
	var/matrix/M = matrix(magic_circle.transform)
	M.Translate(0, 16)
	var/rot_angle = Get_Angle(get_turf(src), target_turf)
	M.Turn(rot_angle)
	switch(dir)
		if(EAST)
			M.Scale(0.5, 1)
		if(WEST)
			M.Scale(0.5, 1)
		if(NORTH)
			magic_circle.layer -= 0.2
	magic_circle.transform = M

	// Create area markers in 5x5 around us
	var/turf/center = get_turf(src)
	for(var/turf/T in range(4, center))
		var/obj/effect/temp_visual/warper_area/W = new(T)
		area_markers += W

	visible_message(span_userdanger("[src] begins channeling a mass teleportation!"))
	playsound(src, 'sound/magic/charge.ogg', 100, TRUE)

	// Channel for 10 seconds
	addtimer(CALLBACK(src, PROC_REF(CompleteTeleport), center), 10 SECONDS)

/mob/living/simple_animal/hostile/clan/ranged/warper/proc/CompleteTeleport(turf/center)
	if(stat == DEAD || !current_mark)
		CancelTeleport()
		return

	// Get all mobs in 5x5 area
	var/list/teleport_targets = list()
	for(var/mob/living/L in range(4, center))
		if(L == src) // Don't teleport self
			continue
		teleport_targets += L

	// Teleport effects
	visible_message(span_hierophant_warning("[src] completes the spatial displacement!"))
	playsound(src, 'sound/magic/wand_teleport.ogg', 100, TRUE)
	playsound(current_mark, 'sound/magic/wand_teleport.ogg', 100, TRUE)

	// Teleport each mob
	var/turf/destination = get_turf(current_mark)
	for(var/mob/living/L in teleport_targets)
		INVOKE_ASYNC(src, PROC_REF(TeleportMob), L, destination)

	// Cleanup
	CancelTeleport()

/mob/living/simple_animal/hostile/clan/ranged/warper/proc/TeleportMob(mob/living/L, turf/destination)
	// Fade out effect
	new /obj/effect/temp_visual/dir_setting/cult/phase/out(get_turf(L), L)
	animate(L, alpha = 0, time = 5, easing = EASE_OUT)
	sleep(5)

	if(!L || L.stat == DEAD)
		return

	// Move mob
	L.forceMove(destination)

	// Fade in effect
	new /obj/effect/temp_visual/dir_setting/cult/phase(destination, L)
	animate(L, alpha = 255, time = 5, easing = EASE_IN)

	// Stun on arrival
	L.Paralyze(20)

/mob/living/simple_animal/hostile/clan/ranged/warper/proc/CancelTeleport()
	casting = FALSE

	// Clean up magic circle
	if(magic_circle)
		qdel(magic_circle)
		magic_circle = null

	// Clean up markers
	for(var/obj/effect/E in area_markers)
		qdel(E)
	area_markers.Cut()

	if(current_mark)
		qdel(current_mark)
		current_mark = null

/mob/living/simple_animal/hostile/clan/ranged/warper/death()
	CancelTeleport()
	return ..()

// Warper visual effects
/obj/effect/warper_mark
	name = "spatial mark"
	desc = "A glowing mark indicating a teleportation destination."
	icon = 'icons/effects/eldritch.dmi'
	icon_state = "blood_cloud_swirl"
	layer = BELOW_MOB_LAYER

/obj/effect/warper_mark/Initialize()
	. = ..()
	animate(src, alpha = 100, time = 5, loop = -1)
	animate(alpha = 255, time = 5)
	QDEL_IN(src, 11 SECONDS)

/obj/effect/temp_visual/warper_area
	name = "displacement field"
	desc = "Space seems to warp and bend here."
	icon = 'icons/effects/cult_effects.dmi'
	icon_state = "floorglow_looping"
	layer = BELOW_MOB_LAYER
	duration = 11 SECONDS
	alpha = 100

/obj/effect/temp_visual/warper_area/Initialize()
	. = ..()
	animate(src, alpha = 50, time = 10, loop = -1)
	animate(alpha = 150, time = 10)

// Magic circle visual
/obj/effect/clan_magic_circle
	name = "magic circle"
	desc = "A circle of red magic featuring a six-pointed star"
	icon = 'icons/effects/effects.dmi'
	icon_state = "fellcircle"
	pixel_x = 8
	base_pixel_x = 8
	pixel_y = 8
	base_pixel_y = 8
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

//////////////
// HARPOONER
//////////////
// Chain specialist that captures and drags targets
// Chains last 15 seconds, pulls 1 tile/second
/mob/living/simple_animal/hostile/clan/ranged/harpooner
	name = "harpooner unit"
	desc = "A specialized ranged unit equipped with chain harpoons for capturing targets."
	icon_state = "clan_harpooner"
	maxHealth = 600
	health = 600
	vision_range = 10
	aggro_vision_range = 10
	ranged_cooldown_time = 8
	retreat_distance = 6
	minimum_distance = 5
	projectiletype = /obj/projectile/clan_bullet/medium
	move_to_delay = 3
	melee_damage_lower = 10
	melee_damage_upper = 15
	teleport_away = TRUE

	// Chain variables
	var/mob/living/carbon/human/chained_target = null
	var/datum/beam/chain_beam
	var/chain_pull_timer
	var/chain_start_time
	var/chain_duration = 15 SECONDS
	var/pull_delay = 10 // 1 second between pulls
	var/harpoon_cooldown = 0
	var/harpoon_cooldown_time = 20 SECONDS
	var/final_damage = 50 // RED damage on drop

/mob/living/simple_animal/hostile/clan/ranged/harpooner/OpenFire(atom/A)
	if(chained_target)
		return FALSE // Can't shoot while pulling someone

	// Use harpoon on humans, regular shots on others
	if(ishuman(A) && world.time > harpoon_cooldown)
		FireHarpoon(A)
		return

	return ..()

/mob/living/simple_animal/hostile/clan/ranged/harpooner/proc/FireHarpoon(atom/target)
	if(chained_target || world.time < harpoon_cooldown)
		return

	visible_message(span_danger("[src] fires a chain harpoon at [target]!"))
	playsound(src, 'sound/weapons/chainhit.ogg', 75, TRUE)

	var/obj/projectile/clan_bullet/harpoon/H = new(get_turf(src))
	H.firer = src
	H.preparePixelProjectile(target, src)
	H.fire()

	harpoon_cooldown = world.time + harpoon_cooldown_time

/mob/living/simple_animal/hostile/clan/ranged/harpooner/proc/BeginChainPull(mob/living/carbon/human/target)
	if(chained_target)
		return

	chained_target = target
	chain_start_time = world.time

	// Apply chained status
	var/datum/status_effect/harpooner_chained/C = chained_target.has_status_effect(/datum/status_effect/harpooner_chained)
	if(!C)
		C = chained_target.apply_status_effect(/datum/status_effect/harpooner_chained)
		C.harpooner = src

	visible_message(span_warning("[src] has caught [chained_target] with their harpoon!"))

	UpdateChainVisuals()
	PullLoop()

/mob/living/simple_animal/hostile/clan/ranged/harpooner/proc/PullLoop()
	if(!chained_target || chained_target.stat == DEAD || !can_see(src, chained_target, 14))
		ReleaseTarget()
		return

	// Check if 15 seconds have passed
	if(world.time >= chain_start_time + chain_duration)
		DropTarget()
		return

	// Check distance
	var/dist = get_dist(src, chained_target)
	if(dist < 2)
		DropTarget()
		return

	// Pull the target
	var/turf/T = get_turf(src)
	chained_target.throw_at(T, 1, 2, src)
	playsound(chained_target, 'sound/weapons/chainhit.ogg', 40, TRUE)

	UpdateChainVisuals()

	// Schedule next pull
	chain_pull_timer = addtimer(CALLBACK(src, PROC_REF(PullLoop)), pull_delay, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/clan/ranged/harpooner/proc/DropTarget()
	if(!chained_target)
		return

	visible_message(span_danger("[src] violently drops [chained_target]!"))
	playsound(chained_target, 'sound/effects/meteorimpact.ogg', 75, TRUE)

	// Deal damage and knockdown
	chained_target.deal_damage(final_damage, RED_DAMAGE, source = src, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))
	chained_target.Knockdown(30)

	// Visual effect
	new /obj/effect/temp_visual/kinetic_blast(get_turf(chained_target))

	ReleaseTarget()

/mob/living/simple_animal/hostile/clan/ranged/harpooner/proc/UpdateChainVisuals()
	if(!chained_target)
		if(chain_beam)
			QDEL_NULL(chain_beam)
		return

	if(!chain_beam)
		chain_beam = Beam(chained_target, icon_state = "chain")

/mob/living/simple_animal/hostile/clan/ranged/harpooner/proc/ReleaseTarget()
	if(!chained_target)
		return

	chained_target.remove_status_effect(/datum/status_effect/harpooner_chained)
	chained_target = null
	UpdateChainVisuals()

	if(chain_pull_timer)
		deltimer(chain_pull_timer)
		chain_pull_timer = null

/mob/living/simple_animal/hostile/clan/ranged/harpooner/death()
	ReleaseTarget()
	return ..()

/mob/living/simple_animal/hostile/clan/ranged/harpooner/Destroy()
	ReleaseTarget()
	return ..()

// Harpooner projectiles
/obj/projectile/clan_bullet/harpoon
	name = "chain harpoon"
	icon_state = "chain_bolt"
	damage = 20
	damage_type = RED_DAMAGE
	speed = 0.5
	var/chain

/obj/projectile/clan_bullet/harpoon/fire(setAngle)
	if(firer)
		chain = firer.Beam(src, icon_state = "chain")
	..()

/obj/projectile/clan_bullet/harpoon/Destroy()
	qdel(chain)
	return ..()

/obj/projectile/clan_bullet/harpoon/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		var/mob/living/simple_animal/hostile/clan/ranged/harpooner/harpooner = firer
		if(istype(harpooner) && get_dist(target, firer) < 15)
			harpooner.BeginChainPull(H)

// Harpooner status effect
/datum/status_effect/harpooner_chained
	id = "harpooner_chained"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/harpooner_chained
	var/mob/living/simple_animal/hostile/clan/ranged/harpooner/harpooner
	var/view_range = 7

/atom/movable/screen/alert/status_effect/harpooner_chained
	name = "Harpooned"
	desc = "You've been caught by a clan harpooner! You can't run away!"
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "locked"

/datum/status_effect/harpooner_chained/on_apply()
	. = ..()
	RegisterSignal(owner, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(check_movement))
	to_chat(owner, span_userdanger("You've been harpooned! You can't escape!"))

/datum/status_effect/harpooner_chained/on_remove()
	UnregisterSignal(owner, COMSIG_MOVABLE_PRE_MOVE)
	to_chat(owner, span_notice("The harpoon releases you."))
	. = ..()

/datum/status_effect/harpooner_chained/proc/check_movement(mob/living/carbon/human/H, turf/NewLoc)
	SIGNAL_HANDLER

	if(!istype(H) || !harpooner)
		return

	// Check if still in view
	if(!(H in view(view_range, harpooner)))
		H.remove_status_effect(/datum/status_effect/harpooner_chained)
		return

	// Prevent moving away
	var/current_dist = get_dist(harpooner, H)
	var/new_dist = get_dist(harpooner, NewLoc)

	if(new_dist > current_dist)
		to_chat(H, span_warning("The chain prevents you from moving further away!"))
		return COMPONENT_MOVABLE_BLOCK_PRE_MOVE

