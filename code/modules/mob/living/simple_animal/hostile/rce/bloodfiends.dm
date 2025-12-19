/// Base bloodfiend mook type - gains damage and resistance buffs from blood_feast
/mob/living/simple_animal/hostile/bloodfiend_mook
	name = "bloodfiend"
	desc = "A greed-touched humanoid wearing bloody attire. Corrupted by the Heart of Greed, they hoard blood obsessively - never consuming it, only growing their collection. They grow stronger from accumulation alone."
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
	/// Last recorded blood amount for buff updates
	var/last_blood_check = 0
	/// Whether currently in enraged state (50%+ blood)
	var/enraged = FALSE

/mob/living/simple_animal/hostile/bloodfiend_mook/Initialize()
	. = ..()
	base_damage_lower = melee_damage_lower
	base_damage_upper = melee_damage_upper
	AddComponent(/datum/component/bloodfeast, siphon = TRUE, range = 2, starting = 0, max_amount = max_blood)

/mob/living/simple_animal/hostile/bloodfiend_mook/Life()
	. = ..()
	if(stat == DEAD)
		return FALSE
	UpdateBloodBuff()

/// Updates damage based on current blood_feast percentage
/// At 50% blood: +25% damage
/// At 100% blood: +50% damage
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

/mob/living/simple_animal/hostile/bloodfiend_mook/bullet_act(obj/projectile/P)
	// 50% damage reduction at 15+ blood thorns stacks
	var/datum/status_effect/stacking/blood_thorns/BT = has_status_effect(/datum/status_effect/stacking/blood_thorns)
	if(BT && BT.stacks >= 15)
		P.damage *= 0.5
	return ..()

/// Fashionista - Weakest variant
/mob/living/simple_animal/hostile/bloodfiend_mook/fashionista
	name = "Greed Touched Fashionista Bloodfiend"
	desc = "The weakest of the greed-touched bloodfiends, newly corrupted by the Heart of Greed. They hoard blood obsessively, jealously guarding what little they've collected."
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
	name = "Greed Touched Priest Bloodfiend"
	desc = "Once devoted to blood rituals, now they worship accumulation itself. The Heart of Greed transformed their prayers into inventory counts, their sacrifices into deposits."
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
/mob/living/simple_animal/hostile/bloodfiend_mook/parade
	name = "Greed Touched Parade Bloodfiend"
	desc = "The Heart of Greed twisted their bloodlust into acquisitive frenzy. They strike with wild abandon not to feed, but to collect - each drop extracted is another coin in their master's coffers."
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
/mob/living/simple_animal/hostile/bloodfiend_mook/parade_alt
	name = "Greed Touched Marcher Bloodfiend"
	desc = "Corrupted by the Heart of Greed into patient hoarders. They endure punishment while methodically extracting blood from their victims, never consuming what they take - only stockpiling it."
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
/mob/living/simple_animal/hostile/bloodfiend_mook/parade_guard
	name = "Greed Touched Formal Bloodfiend"
	desc = "Elite guards who protect the blood vaults with unwavering devotion. Their formal attire conceals bodies bloated with hoarded blood they refuse to spend, growing stronger from accumulation alone."
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

/mob/living/simple_animal/hostile/bloodfiend_mook/parade_guard/UpdateEnragedVisual()
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
	desc = "A mindless husk reanimated by bloodfiends and stuffed with hoarded blood. This walking corpse serves only as storage, shambling forward without thought until it explodes violently upon death."
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

/// Withered Vessel - Weakest variant
/mob/living/simple_animal/hostile/bloodbag/fashionista
	name = "Greed Touched Fashionista Bloodbag"
	desc = "The weakest of the bloodbag husks, a reanimated corpse stuffed with stolen blood. This mindless shell stumbles forward, bursting at the seams with crimson it cannot comprehend."
	maxHealth = 200
	health = 200
	melee_damage_lower = 2
	melee_damage_upper = 4
	explosion_damage = 12
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.6, WHITE_DAMAGE = 1.4, BLACK_DAMAGE = 0.9, PALE_DAMAGE = 1.3)

/// Tithe Vessel - Standard variant
/mob/living/simple_animal/hostile/bloodbag/priest
	name = "Greed Touched Priest Bloodbag"
	desc = "A reanimated victim of the Priest's flock, its hollow body serving as walking storage for hoarded blood. This mindless husk shuffles forward without purpose beyond containment and detonation."
	maxHealth = 250
	health = 250
	melee_damage_lower = 3
	melee_damage_upper = 5
	explosion_damage = 15
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.7, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1.3, PALE_DAMAGE = 1.2)

/// Offering Vessel - Slightly stronger variant
/mob/living/simple_animal/hostile/bloodbag/priest_alt
	name = "Greed Touched Heavy Bloodbag"
	desc = "A corpse raised by the Priest's bloodfiends and pumped full of hoarded blood. This mindless husk is sent to punish intruders - its explosive death scattering stolen crimson across the battlefield."
	maxHealth = 275
	health = 275
	melee_damage_lower = 4
	melee_damage_upper = 6
	explosion_damage = 18
	bleed_stacks = 2
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.2, WHITE_DAMAGE = 0.7, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.3)

/// Procession Vessel - Strongest variant
/mob/living/simple_animal/hostile/bloodbag/parade
	name = "Greed Touched Parade Bloodbag"
	desc = "A mindless husk reanimated by the Parade's bloodfiends, its body grotesquely swollen with hoarded crimson. This walking blood vault shambles forward without thought, exploding violently when destroyed."
	maxHealth = 350
	health = 350
	melee_damage_lower = 5
	melee_damage_upper = 7
	explosion_damage = 22
	explosion_bleed = 7
	bleed_stacks = 2
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.9, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 1.3, PALE_DAMAGE = 0.7)
