// ============================================
// BLOODFIEND BOSSES - Area guardians that unlock progression when killed
// ============================================

/// Base boss bloodfiend type - high health, blood draining tank
/mob/living/simple_animal/hostile/bloodfiend_boss
	name = "Bloodfiend Boss"
	desc = "A massive bloodfiend radiating an aura of crimson power."
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
	move_to_delay = 5
	stat_attack = HARD_CRIT
	del_on_death = FALSE
	maxHealth = 5000
	health = 5000
	melee_damage_lower = 15
	melee_damage_upper = 20
	melee_damage_type = RED_DAMAGE
	attack_sound = 'sound/abnormalities/nosferatu/attack.ogg'
	attack_verb_continuous = "rends"
	attack_verb_simple = "rend"
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.2)
	butcher_results = list(/obj/item/food/meat/slab/crimson = 3)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/crimson = 5)
	/// Maximum blood for buff calculations
	var/max_blood = 3000
	/// Bleed stacks applied on hit
	var/bleed_stacks = 5
	/// Base melee damage lower, used for buff calculations
	var/base_damage_lower = 15
	/// Base melee damage upper, used for buff calculations
	var/base_damage_upper = 20
	/// Last recorded blood amount for buff updates
	var/last_blood_check = 0
	/// Whether currently in enraged state (50%+ blood)
	var/enraged = FALSE
	/// Signal sent on death to destroy area blockers
	var/boss_death_signal

/mob/living/simple_animal/hostile/bloodfiend_boss/Initialize()
	. = ..()
	base_damage_lower = melee_damage_lower
	base_damage_upper = melee_damage_upper
	AddComponent(/datum/component/bloodfeast, siphon = TRUE, range = 3, starting = 0, max_amount = max_blood)
	AddElement(/datum/element/point_of_interest)

/mob/living/simple_animal/hostile/bloodfiend_boss/Life()
	. = ..()
	if(stat == DEAD)
		return FALSE
	UpdateBloodBuff()

/mob/living/simple_animal/hostile/bloodfiend_boss/proc/UpdateBloodBuff()
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	if(!bloodfeast)
		return
	if(bloodfeast.blood_amount == last_blood_check)
		return
	last_blood_check = bloodfeast.blood_amount

	var/buff_percent = bloodfeast.blood_amount / max_blood
	var/damage_mult = 1 + (buff_percent * 0.5)
	melee_damage_lower = round(base_damage_lower * damage_mult)
	melee_damage_upper = round(base_damage_upper * damage_mult)

	var/should_enrage = buff_percent >= 0.5
	if(should_enrage != enraged)
		enraged = should_enrage
		UpdateEnragedVisual()

/mob/living/simple_animal/hostile/bloodfiend_boss/proc/UpdateEnragedVisual()
	if(enraged)
		color = "#FF6666"
	else
		color = initial(color)

/mob/living/simple_animal/hostile/bloodfiend_boss/AttackingTarget()
	. = ..()
	if(istype(target, /mob/living))
		var/mob/living/L = target
		L.apply_lc_bleed(bleed_stacks)

/mob/living/simple_animal/hostile/bloodfiend_boss/death(gibbed)
	. = ..()
	if(boss_death_signal)
		SEND_SIGNAL(SSdcs, boss_death_signal, src)

// ============================================
// BOSS VARIANTS
// ============================================

/// The Barber - Area 1 Boss
/mob/living/simple_animal/hostile/bloodfiend_boss/barber
	name = "The Barber"
	desc = "A bloodfiend of elegant cruelty, known for their precise and bloody cuts. The guardian of the first area."
	icon = 'ModularLobotomy/_Lobotomyicons/rce_bloodfiend_64x64.dmi'
	icon_state = "nicolina_base"
	icon_living = "nicolina_base"
	maxHealth = 4500
	health = 4500
	pixel_x = -16
	base_pixel_x = -16
	pixel_y = -16
	base_pixel_y = -16
	melee_damage_lower = 12
	melee_damage_upper = 18
	base_damage_lower = 12
	base_damage_upper = 18
	bleed_stacks = 4
	boss_death_signal = COMSIG_GLOB_BLOODFIEND_BARBER_DIED
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.2, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.9, PALE_DAMAGE = 1.1)

/// The Priest - Area 2 Boss
/mob/living/simple_animal/hostile/bloodfiend_boss/priest
	name = "The Priest"
	desc = "A bloodfiend devoted to unholy rituals of blood and sacrifice. The guardian of the second area."
	icon = 'ModularLobotomy/_Lobotomyicons/rce_bloodfiend_32x32.dmi'
	icon_state = "curiambro"
	icon_living = "curiambro"
	maxHealth = 5500
	health = 5500
	melee_damage_lower = 14
	melee_damage_upper = 20
	base_damage_lower = 14
	base_damage_upper = 20
	bleed_stacks = 5
	boss_death_signal = COMSIG_GLOB_BLOODFIEND_PRIEST_DIED
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.7, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 1.3, PALE_DAMAGE = 1.1)

/// Dulcinea - Area 3 Boss
/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea
	name = "Dulcinea"
	desc = "The Princess of the Happy Parade, a bloodfiend of terrible joy. The guardian of the third area."
	icon = 'ModularLobotomy/_Lobotomyicons/rce_bloodfiend_64x64.dmi'
	icon_state = "dulcinea"
	icon_living = "dulcinea"
	pixel_x = -16
	base_pixel_x = -16
	maxHealth = 6500
	health = 6500
	melee_damage_lower = 16
	melee_damage_upper = 22
	base_damage_lower = 16
	base_damage_upper = 22
	bleed_stacks = 6
	boss_death_signal = COMSIG_GLOB_BLOODFIEND_DULCINEA_DIED
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.6, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 1.2)
