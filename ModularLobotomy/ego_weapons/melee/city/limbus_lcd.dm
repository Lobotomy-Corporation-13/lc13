//This is the BL Broad's OSIR blade. G5.
/obj/item/ego_weapon/shield/parry/osir
	name = "LCD OSIR Blade"
	desc = "My dream of the homeland is dead. This is who I am now."
	special = "Use in hand to dash and start a parry. Successfully parrying applies a speedboost."
	icon_state = "osir_blade"
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_weapons.dmi'
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right.dmi'
	force = 40
	attack_speed = 1
	damtype = WHITE_DAMAGE	//Fights distortions...
	swingstyle = WEAPONSWING_LARGESWEEP

	attack_verb_continuous = list("cuts", "smacks", "bashes")
	attack_verb_simple = list("cuts", "smacks", "bashes")
	hitsound = 'sound/weapons/bladeslice.ogg'
	reductions = list(20, 30, 10, 0) // 60
	projectile_block_duration = 1 SECONDS
	block_duration = 1 SECONDS
	block_cooldown = 3 SECONDS
	block_sound = 'sound/weapons/ego/clash1.ogg'
	projectile_block_message = "You swat the projectile out of the air!"
	block_message = "You attempt to parry the attack!"
	hit_message = "parries the attack!"
	block_cooldown_message = "You rearm your blade."

	var/dodgelanding

/obj/item/ego_weapon/shield/parry/osir/attack_self(mob/living/carbon/user)
	if(user.dir == 1)
		dodgelanding = locate(user.x, user.y + 5, user.z)
	if(user.dir == 2)
		dodgelanding = locate(user.x, user.y - 5, user.z)
	if(user.dir == 4)
		dodgelanding = locate(user.x + 5, user.y, user.z)
	if(user.dir == 8)
		dodgelanding = locate(user.x - 5, user.y, user.z)
	user.adjustStaminaLoss(15, TRUE, TRUE)
	user.throw_at(dodgelanding, 3, 2, spin = FALSE)
	user.Immobilize(1 SECONDS)
	..()

/obj/item/ego_weapon/shield/parry/osir/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	..()
	if(attack_type == MELEE_ATTACK && active_block)
		owner.add_movespeed_modifier(/datum/movespeed_modifier/osir_blade)
		addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/osir_blade), 5 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

/datum/movespeed_modifier/osir_blade
	variable = TRUE
	multiplicative_slowdown = -0.5

//Kim and Ezra's Gear is all G3.

/obj/item/ego_weapon/city/bladelineage/lcd
	name = "lcd swordsman blade"
	desc = "A blade that is used by some LCD agents."
	icon_state = "kim_lcd"
	inhand_icon_state = "blade_lineage"
	force = 58
	attack_speed = 1
	damtype = WHITE_DAMAGE
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 80,
	)



//Ezra's Weapons work by giving debuffs if she hits the same target X times.
/obj/item/ego_weapon/city/screw_atelier
	name = "Screw Atelier Drill Hammer"
	desc = "A weapon used by the LCD team. Made by Atelier Workshop!"
	special = "Attack the same target repeatedly to apply Fragile."
	icon_state = "screw_atelier"
	inhand_icon_state = "screw_atelier"
	force = 60
	damtype = BLACK_DAMAGE

	var/stored_target
	var/hit_number
	var/hit_target = 6

	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 100,
	)


/obj/item/ego_weapon/city/screw_atelier/attack(mob/living/target, mob/living/user)
	..()
	if(target != stored_target)
		stored_target = target
		to_chat(user, span_notice("You pursue a new target."))
		hit_number = 0
		return
	else
		hit_number++

	if(hit_number >= hit_target)
		user.say("Rip 'em to shreds!")
		hit_number = 0
		//Screw Atelier is Black, and Nester workshop is white, they will synergize a bit.
		user.apply_lc_fragile(3)


//Nester is supposed to synergize with Screw Atelier.
/obj/item/ego_weapon/city/nester
	name = "Nester Workshop Hammer"
	desc = "A weapon used by the LCD team. Made in Nester workshop!"
	special = "Attack the same target repeatedly to slow them down on hit and apply Black Fragile."
	icon_state = "nesterr"
	inhand_icon_state = "nester"
	force = 60
	damtype = WHITE_DAMAGE

	var/stored_target
	var/hit_number
	var/hit_target = 4

	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 100,
	)


/obj/item/ego_weapon/city/nester/attack(mob/living/target, mob/living/user)
	..()
	if(target != stored_target)
		stored_target = target
		to_chat(user, span_notice("You pursue a new target."))
		hit_number = 0
		return
	else
		hit_number++

	if(hit_number >= hit_target)
		to_chat(user, span_danger("They're not getting away!"))
		hit_number = 0
		user.apply_lc_black_fragile(2)
		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			H.add_movespeed_modifier(/datum/movespeed_modifier/nester)
			addtimer(CALLBACK(H, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/nester), 7 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
			//Represents Tremor. I don't like using Limbus statuses for fucking everything.

		else
			target.apply_status_effect(/datum/status_effect/qliphothoverload)


/datum/movespeed_modifier/nester
	multiplicative_slowdown = 0.8

