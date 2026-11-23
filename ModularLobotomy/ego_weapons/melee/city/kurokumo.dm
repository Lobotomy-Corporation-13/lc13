
//Kurokumo - Grade 4 with unique mechanics
/obj/item/ego_weapon/city/kurokumo
	name = "kurokumo blade - skyclearing cut"
	desc = "A very sharp blade used by the Kurokumo clan. Get it bloody. Uses the Skyclearing Slash as a technique."
	special = "Skyclearing Cut - Use in hand to empower your next attack. The power increase and stuntime improve with more Dark Cloud Stacks."
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_weapons/kurokumo.dmi'
	icon_state = "kurokumo_sheathed"
	inhand_icon_state = "kurokumo_sheathed"
	force = 52
	attack_speed = 1.2
	damtype = RED_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP

	attack_verb_continuous = list("pokes", "jabs", "tears", "lacerates", "gores")
	attack_verb_simple = list("poke", "jab", "tear", "lacerate", "gore")
	hitsound = 'sound/weapons/bladeslice.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 80
							)
	var/cloud = 0
	var/active = FALSE
	var/skill_name = "Skyclearing Cut"
	var/ability_lock = FALSE

/obj/item/ego_weapon/city/kurokumo/examine(mob/user)
	. = ..()
	. += span_notice("This weapon gains 1 Dark Cloud when attacking.")
	. += span_notice("Current Dark Cloud: [cloud]/10.")

/obj/item/ego_weapon/city/kurokumo/attack(mob/living/target, mob/living/carbon/human/user)
	if(!CanUseEgo(user))
		return
	if((cloud == 10) || (target.stat != DEAD) || target.status_flags & GODMODE)
		cloud++

	if(active && !ability_lock)
		KuroAttack(target, user)
		cloud = 0
		active = FALSE
	..()
	force = initial(force)


/obj/item/ego_weapon/city/kurokumo/attack_self(mob/living/carbon/human/user)
	..()
	if(!CanUseEgo(user))
		return
	if(active)
		active = FALSE
		to_chat(user, span_danger("You unprepare [skill_name]"))
	else
		active = TRUE
		to_chat(user, span_danger("You prepare [skill_name]"))


/obj/item/ego_weapon/city/kurokumo/proc/KuroAttack(mob/living/target, mob/living/carbon/human/user)
	force += 10*cloud	//Give 'em some good damage

	user.Immobilize(15-cloud)	//Min half a second of stuntime, but you are doing crazy damage
	//Visual stuff to give you better feedback
	new /obj/effect/temp_visual/weapon_stun(get_turf(user))
	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(user), pick(GLOB.alldirs))
	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(user), pick(GLOB.alldirs))
	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(user), pick(GLOB.alldirs))




/obj/item/ego_weapon/city/kurokumo/lenticular
	name = "kurokumo blade - lenticular slash"
	desc = "A very sharp blade used by the Kurokumo clan. Get it bloody. Uses the Lenticular Slash as a technique."
	special = "Lenticular Slash - Use in hand to apply Feeble on your next attack."
	icon_state = "kurokumo_lenticular"
	inhand_icon_state = "kurokumo_sheathed"
	skill_name = "Lenticular Slash"


/obj/item/ego_weapon/city/kurokumo/lenticular/KuroAttack(mob/living/target, mob/living/carbon/human/user)
	var/stacks = 1 + round(cloud/3)
	target.apply_lc_feeble(stacks)

	if(cloud != 10)
		user.Immobilize(10-cloud)	//You're immobilized too
		//Visual stuff to give you better feedback
		new /obj/effect/temp_visual/weapon_stun(get_turf(user))

	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(user), pick(GLOB.alldirs))
	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(user), pick(GLOB.alldirs))
	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(user), pick(GLOB.alldirs))


/obj/item/ego_weapon/city/kurokumo/ink
	name = "kurokumo blade - ink over"
	desc = "A very sharp blade used by the Kurokumo clan. Get it bloody. Uses the ink over a technique."
	special = "Ink Over - Use in hand to apply Strength to the user on your next attack. During the stuntime, get a defense bonus increasing with Dark Cloud Stacks."
	icon_state = "kurokumo_ink"
	inhand_icon_state = "kurokumo_sheathed"
	skill_name = "Ink Over"

	var/armor_hold = 0


/obj/item/ego_weapon/city/kurokumo/ink/KuroAttack(mob/living/target, mob/living/carbon/human/user)
	var/stacks = 1 + round(cloud/5)
	user.apply_lc_strength(stacks)

	user.Immobilize(1 SECONDS)	//You're immobilized for one second,
	//Visual stuff to give you better feedback
	new /obj/effect/temp_visual/weapon_stun(get_turf(user))

	//We're using Ability lock here,
	ability_lock = TRUE
	armor_hold = 1 - cloud/20
	user.physiology.red_mod *= armor_hold
	user.physiology.white_mod *= armor_hold
	user.physiology.black_mod *= armor_hold
	user.physiology.pale_mod *= armor_hold

	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(user), pick(GLOB.alldirs))
	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(user), pick(GLOB.alldirs))
	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(user), pick(GLOB.alldirs))

	addtimer(CALLBACK(src, PROC_REF(Return), user), 1 SECONDS)


/obj/item/ego_weapon/city/kurokumo/ink/proc/Return(mob/living/carbon/human/user)
	user.physiology.red_mod /= armor_hold
	user.physiology.white_mod /= armor_hold
	user.physiology.black_mod /= armor_hold
	user.physiology.pale_mod /= armor_hold
	to_chat(user, span_notice("Your defense buff has expired!"))
	ability_lock = FALSE

