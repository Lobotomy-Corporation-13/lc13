
//Whelp Blade
/obj/item/ego_weapon/miningss13/whelp_blade
	name = "frostbite"
	desc = "It's cold to the touch."
	icon_state = "iceblade"
	force = 20
	damtype = WHITE_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP
	attack_verb_continuous = list("slices", "slashes", "stabs")
	attack_verb_simple = list("slice", "slash", "stab")
	hitsound = 'sound/weapons/fixer/generic/knife3.ogg'

	charge_cost = 5
	charge_effect = "slow the target."
	successfull_activation = "You release your charge, slowing your target!"

/obj/item/ego_weapon/miningss13/whelp_blade/ChargeAttack(mob/living/target, mob/living/user)
	. = ..()
	target.apply_status_effect(/datum/status_effect/qliphothoverload)


//Goliath
/obj/item/ego_weapon/miningss13/goliath
	name = "goliath"
	desc = "A very heavy blade forged out of goliath plating."
	icon_state = "goliath"
	force = 36
	attack_speed = 2
	damtype = RED_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP
	attack_verb_continuous = list("slices", "slashes", "cleaves")
	attack_verb_simple = list("slice", "slash", "cleaves")
	hitsound = 'sound/weapons/fixer/generic/finisher1.ogg'
	ability_type = ABILITY_ON_ACTIVATION
	charge_cost = 20
	charge_effect = "deal massive damage on the next attack."
	successfull_activation = "You use your charge to prep a big cleave!"

/obj/item/ego_weapon/miningss13/goliath/ChargeAttack(mob/living/target, mob/living/user)
	. = ..()
	force = initial(force)*4

/obj/item/ego_weapon/miningss13/goliath/attack(mob/living/M, mob/living/user)
	. = ..()
	force = initial(force)


//Ethereal
/obj/item/ego_weapon/miningss13/ethereal
	name = "ethereal"
	desc = "A blade that is forged from the parts of a hivelord."
	icon_state = "hiveblade"
	force = 18
	damtype = BLACK_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP
	attack_verb_continuous = list("slices", "slashes", "cleaves")
	attack_verb_simple = list("slice", "slash", "cleaves")
	hitsound = 'sound/weapons/bladeslice.ogg'

	charge = TRUE
	charge_cost = 2
	charge_effect = "deal an extra attack in damage."
	successfull_activation = "You release your charge, damaging your opponent!"

/obj/item/ego_weapon/miningss13/ethereal/ChargeAttack(mob/living/target, mob/living/user)
	. = ..()
	target.deal_damage(force, damtype, user, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))


	/*


	//Give them a projectile shot later

	charge_effect = "shoot homing projectiles."
	successfull_activation = "You shoot some projectiles!"

//Ethereal Bullets
/obj/item/ego_weapon/miningss13/ethereal/ChargeAttack(mob/living/target, mob/living/user)
	. = ..()
	var/list/possibletargets = list()
	for(var/mob/living/L in view(10, src))
		if(ishuman(L))
			continue
		possibletargets += L
	if(!LAZYLEN(possibletargets))
		return

	playsound(get_turf(src), 'sound/abnormalities/voiddream/fire.ogg', 50, TRUE)
	for(var/i = 1 to 3)
		var/obj/projectile/P = new /obj/projectile/ethereal(get_turf(src))
		P.firer = src
		var/bullet_target = pick(possibletargets)
		P.original = bullet_target
		P.fire(Get_Angle(src, bullet_target))

/obj/projectile/ethereal
	name = "ethereal"
	icon = 'ModularLobotomy/_Lobotomyicons/mining_abnos/mining_weapons.dmi'
	icon_state = "hivepellet"
	damage = 10
	damage_type = BLACK_DAMAGE
	speed = 3
	homing = TRUE
	homing_turn_speed = 25 //Angle per tick.
	*/
