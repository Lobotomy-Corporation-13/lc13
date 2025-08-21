//G corp remenants, Survivors of the Smoke War
//Their function is as common cannon fodder. Manager buffs make them much more effective in battle.
/mob/living/simple_animal/hostile/ordeal/steel_dawn
	name = "gene corp remnant"
	desc = "A insect augmented employee of the fallen Gene corp. Word on the street says that they banded into common backstreet gangs after the Smoke War."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "gcorp1"
	icon_living = "gcorp1"
	icon_dead = "gcorp_corpse"
	faction = list("Gene_Corp")
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID|MOB_BUG
	maxHealth = 220
	health = 220
	melee_damage_type = RED_DAMAGE
	vision_range = 8
	move_to_delay = 2.2
	melee_damage_lower = 10
	melee_damage_upper = 13
	wander = FALSE
	attack_verb_continuous = "stabs"
	attack_verb_simple = "stab"
	footstep_type = FOOTSTEP_MOB_SHOE
	a_intent = INTENT_HELP
	possible_a_intents = list(INTENT_HELP, INTENT_HARM)
	//similar to a human
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	butcher_results = list(/obj/item/food/meat/slab/buggy = 2)
	silk_results = list(/obj/item/stack/sheet/silk/steel_simple = 1)
	//What AI are we using?
	var/morale = "Normal"
	var/morale_active = TRUE

/mob/living/simple_animal/hostile/ordeal/steel_dawn/Initialize()
	. = ..()
	attack_sound = "sound/effects/ordeals/steel/gcorp_attack[pick(1,2,3)].ogg"
	if(icon_state == "gcorp_beetle")
		return
	var/type_into_text = "[type]"
	if(type_into_text == "/mob/living/simple_animal/hostile/ordeal/steel_dawn") //due to being a root of noon
		icon_living = "gcorp[pick(1,2,3,4)]"
		icon_state = icon_living

/mob/living/simple_animal/hostile/ordeal/steel_dawn/Life()
	. = ..()
	if(morale_active)
		//If you got no morale
		if(morale == "Retreat" || morale == "No Morale")
			ranged = 1
			retreat_distance = 5
			minimum_distance = 5
			a_intent_change(INTENT_HELP)

		else
			ranged = 0
			retreat_distance = 0
			minimum_distance = 1
			a_intent_change(INTENT_HARM)

	//Passive regen when below 50% health.
	if(health <= maxHealth*0.5 && stat != DEAD)
		if(morale != "Zealous")
			morale = "Retreat"
		adjustBruteLoss(-2)
		if(!target)
			adjustBruteLoss(-6)

	else
		morale = "Normal"

	//Soldiers when off duty will let eachother move around.
/mob/living/simple_animal/hostile/ordeal/steel_dawn/Aggro()
	. = ..()
	a_intent_change(INTENT_HARM)

/mob/living/simple_animal/hostile/ordeal/steel_dawn/LoseAggro()
	. = ..()
	a_intent_change(INTENT_HELP)



/mob/living/simple_animal/hostile/ordeal/steel_dawn/beefy
	name = "gene corp shocktrooper"
	icon_state = "gcorp_beetle"
	icon_living = "gcorp_beetle"
	icon_dead = "dead_beetle"
	faction = list("Gene_Corp")
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID|MOB_BUG
	maxHealth = 1300
	health = 1300
	melee_damage_lower = 40
	melee_damage_upper = 45
	move_to_delay = 4


/mob/living/simple_animal/hostile/ordeal/steel_dawn/medic
	name = "gene corp corpsmen"
	desc = "A insect augmented employee of the fallen Gene corp. It carries a dufflebag of scavenged medical supplies."
	icon_state = "gcorp_medic"
	icon_living = "gcorp_medic"
	icon_dead = "gcorp_corpse"
	faction = list("Gene_Corp")
	maxHealth = 200
	health = 200
	melee_damage_lower = 5
	melee_damage_upper = 10
	retreat_distance = 5
	minimum_distance = 5
	rapid_melee = 1
	ranged = 1
	morale_active = FALSE
	loot = list(/obj/item/stack/medical/suture/emergency)
	var/patient_giveup_count = 0
	var/patient_reset_cooldown = 0
	var/patient_reset_delay = 5 SECONDS
	var/list/previous_patient_list = list()

/mob/living/simple_animal/hostile/ordeal/steel_dawn/medic/ValueTarget(atom/target_thing)
	. = ..()
	if(istype(target_thing, /mob/living/simple_animal/hostile/ordeal/steel_dawn))
		var/mob/living/simple_animal/hostile/ordeal/steel_dawn/L = target_thing
		//Highest possible addition is + 9.9
		if(L.health <= (L.maxHealth * 0.8))
			var/upper = L.maxHealth - HEALTH_THRESHOLD_DEAD
			var/lower = L.health - HEALTH_THRESHOLD_DEAD
			. += min( 2 * ( 1 / ( max( lower, 1 ) / upper ) ), 20)

/mob/living/simple_animal/hostile/ordeal/steel_dawn/medic/handle_automated_action()
	. = ..()
	if(patient_reset_cooldown <= world.time)
		if(length(previous_patient_list))
			patient_reset_cooldown = world.time + patient_reset_delay
			previous_patient_list.Cut()

/mob/living/simple_animal/hostile/ordeal/steel_dawn/medic/MoveToTarget(list/possible_targets)
	..()
	if(isliving(target))
		var/mob/living/L = target
		if(faction_check_mob(L))
			if(L.health >= L.maxHealth || L.stat == DEAD) //is this target an unhurt friend? stop trying to heal it.
				LoseTarget()
				return
			patient_giveup_count++
	if(patient_giveup_count > 30) //The medic only has so much time and supplies.
		previous_patient_list += target
		LoseTarget()

/mob/living/simple_animal/hostile/ordeal/steel_dawn/medic/AttackingTarget(atom/attacked_target)
	if(ishostile(attacked_target))
		var/mob/living/simple_animal/hostile/H = attacked_target
		if(H != src)
			if(faction_check_mob(H) && H.health < H.maxHealth)
				H.adjustBruteLoss(-10)
				visible_message(span_notice("[src] provides medical supplies to \the <b>[H]</b>."),
					span_notice("You encourage <b>[H]'s</b> regeneration, leaving <b>[H]</b> at <b>[H.health]/[H.maxHealth]</b> health."))
				return
	return ..()

/mob/living/simple_animal/hostile/ordeal/steel_dawn/medic/CanAttack(atom/the_target)
	if(see_invisible < the_target.invisibility)
		return FALSE
	//Trying to hijack the proc before it checks for faction.
	if(ishostile(the_target))
		var/mob/living/simple_animal/hostile/M = the_target
		if(M.status_flags & GODMODE)
			return FALSE
		if(M.stat != DEAD)
			if(!(locate(M) in previous_patient_list) && faction_check_mob(M) && M.health < M.maxHealth) //is it hurt? let's go heal it if it is
				return TRUE
	return ..()

/mob/living/simple_animal/hostile/ordeal/steel_dawn/medic/Aggro()
	..()
	if(isliving(target))
		if(faction_check_mob(target)) //oh the target is a friend no need to flee
			ranged = 0
			retreat_distance = 0
			minimum_distance = 1
			patient_giveup_count = 0
		else
			ranged = 1
			retreat_distance = 5
			minimum_distance = 5

/mob/living/simple_animal/hostile/ordeal/steel_dawn/medic/LoseAggro()
	..()
	ranged = 1
	retreat_distance = 5
	minimum_distance = 5
	patient_giveup_count = 0
