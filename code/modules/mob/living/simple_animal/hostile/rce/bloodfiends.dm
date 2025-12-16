/// Base bloodfiend mook type - gains damage and resistance buffs from blood_feast
/mob/living/simple_animal/hostile/bloodfiend_mook
	name = "bloodfiend"
	desc = "A humanoid wearing bloody attire and a mask. They seem to grow stronger as they consume blood."
	icon = 'ModularLobotomy/_Lobotomyicons/blood_fiends_32x32.dmi'
	icon_state = "test_meifiend"
	icon_living = "test_meifiend"
	faction = list("hostile")
	gender = NEUTER
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	robust_searching = TRUE
	see_in_dark = 7
	vision_range = 12
	aggro_vision_range = 20
	move_to_delay = 4
	stat_attack = HARD_CRIT
	del_on_death = TRUE
	maxHealth = 600
	health = 600
	melee_damage_lower = 8
	melee_damage_upper = 10
	melee_damage_type = RED_DAMAGE
	attack_sound = 'sound/abnormalities/nosferatu/attack.ogg'
	attack_verb_continuous = "slices"
	attack_verb_simple = "slice"
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.2, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 1.3)
	butcher_results = list(/obj/item/food/meat/slab/crimson = 1)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/crimson = 2)
	/// Maximum blood for buff calculations
	var/max_blood = 1500
	/// Bleed stacks applied on hit
	var/bleed_stacks = 2
	/// Base melee damage lower, used for buff calculations
	var/base_damage_lower = 8
	/// Base melee damage upper, used for buff calculations
	var/base_damage_upper = 10
	/// Base damage coefficients, stored on init for buff calculations
	var/list/base_damage_coeff
	/// Last recorded blood amount for buff updates
	var/last_blood_check = 0
	/// Whether currently in enraged state (50%+ blood)
	var/enraged = FALSE

/mob/living/simple_animal/hostile/bloodfiend_mook/Initialize()
	. = ..()
	base_damage_lower = melee_damage_lower
	base_damage_upper = melee_damage_upper
	base_damage_coeff = damage_coeff.Copy()
	AddComponent(/datum/component/bloodfeast, siphon = TRUE, range = 2, starting = 0, max_amount = max_blood)

/mob/living/simple_animal/hostile/bloodfiend_mook/Life()
	. = ..()
	if(stat == DEAD)
		return FALSE
	UpdateBloodBuff()

/// Updates damage and resistance based on current blood_feast percentage
/// At 50% blood: +25% damage, -25% damage taken
/// At 100% blood: +50% damage, -50% damage taken
/mob/living/simple_animal/hostile/bloodfiend_mook/proc/UpdateBloodBuff()
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	if(!bloodfeast)
		return
	// Only update if blood amount has changed
	if(bloodfeast.blood_amount == last_blood_check)
		return
	last_blood_check = bloodfeast.blood_amount

	var/buff_percent = bloodfeast.blood_amount / max_blood
	// Damage multiplier: 1.0 to 1.5
	var/damage_mult = 1 + (buff_percent * 0.5)
	melee_damage_lower = round(base_damage_lower * damage_mult)
	melee_damage_upper = round(base_damage_upper * damage_mult)

	// Resistance multiplier: 1.0 to 0.5 (take less damage as blood increases)
	var/resist_mult = 1 - (buff_percent * 0.5)
	var/list/new_coeff = list()
	for(var/damage_type in base_damage_coeff)
		new_coeff[damage_type] = base_damage_coeff[damage_type] * resist_mult
	ChangeResistances(new_coeff)

	// Visual change at 50% blood
	var/should_enrage = buff_percent >= 0.5
	if(should_enrage != enraged)
		enraged = should_enrage
		UpdateEnragedVisual()

/// Updates visual appearance when entering/exiting enraged state
/mob/living/simple_animal/hostile/bloodfiend_mook/proc/UpdateEnragedVisual()
	if(enraged)
		color = "#FF6666"
	else
		color = initial(color)

/mob/living/simple_animal/hostile/bloodfiend_mook/AttackingTarget()
	. = ..()
	if(istype(target, /mob/living))
		var/mob/living/L = target
		L.apply_lc_bleed(bleed_stacks)

/// Test Meifiend - Weakest variant
/mob/living/simple_animal/hostile/bloodfiend_mook/meifiend
	name = "Fashionista Bloodfiend"
	desc = "A bloodfiend with a keen eye for style, though their taste runs exclusively to crimson."
	icon = 'ModularLobotomy/_Lobotomyicons/blood_fiends_32x32.dmi'
	icon_state = "test_meifiend"
	icon_living = "test_meifiend"
	maxHealth = 400
	health = 400
	melee_damage_lower = 6
	melee_damage_upper = 8
	base_damage_lower = 6
	base_damage_upper = 8
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.5, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.2)

/// Priest Mook - Standard variant
/mob/living/simple_animal/hostile/bloodfiend_mook/priest
	name = "Bloodfiend of Prayers"
	desc = "A bloodfiend devoted to the rituals of blood. They channel their thirst into unholy strength."
	icon = 'ModularLobotomy/_Lobotomyicons/rce_bloodfiend_32x32.dmi'
	icon_state = "priest_mook"
	icon_living = "priest_mook"
	maxHealth = 500
	health = 500
	melee_damage_lower = 7
	melee_damage_upper = 9
	base_damage_lower = 7
	base_damage_upper = 9
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.6, WHITE_DAMAGE = 0.7, BLACK_DAMAGE = 1.4, PALE_DAMAGE = 1.3)

/// Dulcinea Mook - Balanced variant, slightly more offensive
/mob/living/simple_animal/hostile/bloodfiend_mook/dulcinea
	name = "Bloodfiend of the Happy Parade"
	desc = "A bloodfiend that revels in the festivities of slaughter. Favors offense over defense."
	icon = 'ModularLobotomy/_Lobotomyicons/rce_bloodfiend_32x32.dmi'
	icon_state = "dulcinea_mook"
	icon_living = "dulcinea_mook"
	maxHealth = 550
	health = 550
	melee_damage_lower = 9
	melee_damage_upper = 11
	base_damage_lower = 9
	base_damage_upper = 11
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.4, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 1.3)

/// Dulcinea Mook Alt - Balanced variant, slightly more defensive
/mob/living/simple_animal/hostile/bloodfiend_mook/dulcinea_alt
	name = "Bloodfiend of the Joyful Parade"
	desc = "A bloodfiend that delights in the merriment of carnage. Favors defense over offense."
	icon = 'ModularLobotomy/_Lobotomyicons/rce_bloodfiend_32x32.dmi'
	icon_state = "dulcinea_mook_1"
	icon_living = "dulcinea_mook_1"
	maxHealth = 550
	health = 550
	melee_damage_lower = 7
	melee_damage_upper = 9
	base_damage_lower = 7
	base_damage_upper = 9
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.7, WHITE_DAMAGE = 1.3, BLACK_DAMAGE = 1.4, PALE_DAMAGE = 0.6)

/// Formalfiend - Strongest standered variant
/mob/living/simple_animal/hostile/bloodfiend_mook/formal
	name = "Bloodfiend of the Grand Parade"
	desc = "A bloodfiend of noble bearing who protects the Princess of the Parade."
	icon = 'ModularLobotomy/_Lobotomyicons/blood_fiends_32x32.dmi'
	icon_state = "formalfiend"
	icon_living = "formalfiend"
	maxHealth = 750
	health = 750
	melee_damage_lower = 10
	melee_damage_upper = 12
	base_damage_lower = 10
	base_damage_upper = 12
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.9, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 1.6)
	/// Enraged icon state for formalfiend
	var/icon_enraged = "informalfiend"

/mob/living/simple_animal/hostile/bloodfiend_mook/formal/UpdateEnragedVisual()
	if(enraged)
		icon_state = icon_enraged
		icon_living = icon_enraged
	else
		icon_state = initial(icon_state)
		icon_living = initial(icon_living)

// ============================================
// BLOODBAGS - Fodder units that explode on death
// ============================================

/// Base bloodbag type - fodder units that drop blood and explode on death
/mob/living/simple_animal/hostile/bloodbag
	name = "bloodbag"
	desc = "A bloated vessel of blood, ready to burst at a moment's notice."
	icon = 'ModularLobotomy/_Lobotomyicons/blood_fiends_32x32.dmi'
	icon_state = "bloodbag"
	icon_living = "bloodbag"
	faction = list("hostile")
	gender = NEUTER
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	robust_searching = TRUE
	see_in_dark = 7
	vision_range = 12
	aggro_vision_range = 20
	move_to_delay = 2.5
	stat_attack = HARD_CRIT
	maxHealth = 250
	health = 250
	melee_damage_lower = 3
	melee_damage_upper = 5
	melee_damage_type = RED_DAMAGE
	rapid_melee = 3
	attack_sound = 'sound/effects/ordeals/brown/flea_attack.ogg'
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.4, WHITE_DAMAGE = 1.0, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.5)
	butcher_results = list(/obj/item/food/meat/slab/crimson = 1)
	/// Self-damage dealt when attacking
	var/self_damage = 10
	/// Cooldown tracker for blood dropping
	var/blood_drop_cooldown = 0
	/// Time between blood drops
	var/blood_drop_cooldown_time = 2 SECONDS
	/// Bleed stacks applied on hit
	var/bleed_stacks = 1
	/// Damage dealt by death explosion
	var/explosion_damage = 15
	/// Bleed stacks applied by death explosion
	var/explosion_bleed = 5
	/// Whether currently dying (to prevent multiple explosions)
	var/dying = FALSE

/mob/living/simple_animal/hostile/bloodbag/AttackingTarget()
	. = ..()
	if(istype(target, /mob/living))
		var/mob/living/L = target
		L.apply_lc_bleed(bleed_stacks)
	adjustBruteLoss(self_damage)

/mob/living/simple_animal/hostile/bloodbag/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(blood_drop_cooldown > world.time)
		return
	blood_drop_cooldown = world.time + blood_drop_cooldown_time
	DropBlood()

/// Drops a blood pool on a nearby turf
/mob/living/simple_animal/hostile/bloodbag/proc/DropBlood()
	var/turf/origin = get_turf(src)
	var/list/all_turfs = RANGE_TURFS(1, origin)
	for(var/turf/T in shuffle(all_turfs))
		if(T.is_blocked_turf(exclude_mobs = TRUE))
			continue
		var/obj/effect/decal/cleanable/blood/B = locate() in T
		if(!B)
			B = new /obj/effect/decal/cleanable/blood(T)
			B.bloodiness = 100
			break

/mob/living/simple_animal/hostile/bloodbag/death(gibbed)
	if(dying)
		return
	dying = TRUE
	walk_to(src, 0)
	animate(src, transform = matrix() * 1.8, color = "#FF0000", time = 1.5 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(DeathExplosion)), 1.5 SECONDS)
	QDEL_IN(src, 1.5 SECONDS)
	. = ..()

/// Explodes on death, damaging nearby mobs and barricades
/mob/living/simple_animal/hostile/bloodbag/proc/DeathExplosion()
	playsound(loc, 'sound/effects/ordeals/crimson/dusk_dead.ogg', 60, TRUE)
	var/turf/origin = get_turf(src)
	for(var/turf/T in view(1, origin))
		// Damage mobs
		for(var/mob/living/L in T)
			L.deal_damage(explosion_damage, RED_DAMAGE, attack_type = ATTACK_TYPE_SPECIAL)
			L.apply_lc_bleed(explosion_bleed)
		// Damage barricades (2.5x damage to structures)
		for(var/obj/structure/barricade/B in T)
			B.take_damage(explosion_damage * 2.5, RED_DAMAGE)
		// Drop blood
		if(!T.is_blocked_turf(exclude_mobs = TRUE))
			var/obj/effect/decal/cleanable/blood/blood_pool = locate() in T
			if(!blood_pool)
				blood_pool = new /obj/effect/decal/cleanable/blood(T)
				blood_pool.bloodiness = 100

/// Fashionista Bloodbag - Weakest variant
/mob/living/simple_animal/hostile/bloodbag/fashionista
	name = "Fashionista Bloodbag"
	desc = "A bloated vessel trying desperately to look stylish while bursting at the seams."
	maxHealth = 200
	health = 200
	melee_damage_lower = 2
	melee_damage_upper = 4
	explosion_damage = 12
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.6, WHITE_DAMAGE = 1.4, BLACK_DAMAGE = 0.9, PALE_DAMAGE = 1.3)

/// Bloodbag of Prayers - Standard variant
/mob/living/simple_animal/hostile/bloodbag/priest
	name = "Bloodbag of Prayers"
	desc = "A bloated vessel filled with fervent devotion and far too much blood."
	maxHealth = 250
	health = 250
	melee_damage_lower = 3
	melee_damage_upper = 5
	explosion_damage = 15
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.7, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1.3, PALE_DAMAGE = 1.2)

/// Bloodbag of Prayers Alt - Slightly stronger variant
/mob/living/simple_animal/hostile/bloodbag/priest_alt
	name = "Bloodbag of Punishment"
	desc = "A bloated vessel brimming with zealous fervor and crimson ichor."
	maxHealth = 275
	health = 275
	melee_damage_lower = 4
	melee_damage_upper = 6
	explosion_damage = 18
	bleed_stacks = 2
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.2, WHITE_DAMAGE = 0.7, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.3)

/// Parade Bloodbag - Strongest variant
/mob/living/simple_animal/hostile/bloodbag/parade
	name = "Bloodbag of the Parade"
	desc = "A bloated vessel marching proudly in the procession of slaughter."
	maxHealth = 350
	health = 350
	melee_damage_lower = 5
	melee_damage_upper = 7
	explosion_damage = 22
	explosion_bleed = 7
	bleed_stacks = 2
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.9, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 1.3, PALE_DAMAGE = 0.7)
