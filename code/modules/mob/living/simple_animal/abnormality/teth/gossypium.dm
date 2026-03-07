/mob/living/simple_animal/hostile/abnormality/gossypium //That fucking flower that I hate, coded by Xeros

	name = "Drenched Gossypium"
	desc = "A large, round cluster of white flowers, marred by patches of bloodstains. Its roots dangle beneath the cluster."
	icon = 'ModularLobotomy/_Lobotomyicons/32x48.dmi'
	icon_state = "fragment"
	icon_living = "fragment"
	portrait = "fragment"
	maxHealth = 900
	health = 900
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1.5, PALE_DAMAGE = 1.5)
	ranged = TRUE
	melee_damage_lower = 8
	melee_damage_upper = 12
	rapid_melee = 2
	melee_damage_type = BLACK_DAMAGE
	stat_attack = HARD_CRIT
	attack_sound = 'sound/abnormalities/fragment/attack.ogg'
	attack_verb_continuous = "stabs"
	attack_verb_simple = "stab"
	faction = list("hostile")
	can_breach = TRUE
	threat_level = TETH_LEVEL
	start_qliphoth = 5
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 60,
		ABNORMALITY_WORK_INSIGHT = 40,
		ABNORMALITY_WORK_ATTACHMENT = 40,
		ABNORMALITY_WORK_REPRESSION = 40,
	)
	work_damage_amount = 5
	work_damage_type = RED_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/lust

	ego_list = list(
		/datum/ego_datum/weapon/fragment,
		/datum/ego_datum/armor/fragment,
	)
	gift_type =  /datum/ego_gifts/fragments
	abnormality_origin = ABNORMALITY_ORIGIN_LIMBUS

	var/angy = FALSE
	var/calm_down_time = 600

/mob/living/simple_animal/hostile/abnormality/gossypium/Initialize(mapload) //Code shamelessly yoinked from Nosferatu
	. = ..()
	AddComponent(/datum/component/bloodfeast, siphon = TRUE, range = 2, starting = 0)

/mob/living/simple_animal/hostile/abnormality/gossypium/Life()
	. = ..()
	if(!.)
		return
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	if(!bloodfeast) // This could potentially happen with admins playing around or something
		return
	if(bloodfeast.blood_amount > 1500) // If we have over 1500 blood saved up, we get angy
		bloodfeast.blood_amount = 0 //So it doesn't just end up perma-pissed after getting enraged
		Berzerk()
		return

/mob/living/simple_animal/hostile/abnormality/gossypium/proc/Berzerk()
	if(angy || IsContained()) // No bricking the mob by Berzerking when we aren't supposed to.
		return
	playsound(get_turf(src), 'sound/abnormalities/nosferatu/transform.ogg', 35, 8)
	angy = TRUE
	move_to_delay -= 1
	update_icon()
	retreat_distance = 0
	minimum_distance = 0
	calm_down_time = (world.time+calm_down_time) //Calms down after a bit
	if(calm_down_time>world.time) //No need to calm down if you're not pissed off
		angy = FALSE
		move_to_delay = 3 //resets the movespeed so stacks don't result in permanent zoomies
		return
	//if(napalm_cooldown>world.time)
	//	return FALSE
	//napalm_cooldown = (world.time+napalm_cd_duration)
