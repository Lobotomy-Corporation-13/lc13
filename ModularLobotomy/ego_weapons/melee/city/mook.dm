/obj/item/ego_weapon/shield/scabbard/mook_sheath
	name = "Mook Workshop - Ye Model II Sheath"
	desc = "A black sheath adorned with pale silver ornaments."
	special = "The sheath is lined with a special mook patented powder. When the powder is activated, quickly unsheath the blade to sharpen it."
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_weapons.dmi'
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right.dmi'
	// icon_state = "mook_sheath"
	var/powder_buff = TRUE
	// These variables are for keeping the original values of the weapon which got buffed to later revert the buff
	var/sheathed_sword_og_force = null
	var/sheathed_sword_og_attack_speed = null
	var/sheathed_sword_og_hitsound = null
	var/sheathed_sword_og_icon_state = null
	//
	var/correct_sword = /obj/item/ego_weapon/scabbard_sword/mook_sword // mook sword has a greater buff with this
	var/static/list/donotbuff = list() // this is here so that you can't perma-stack damage buffs with more than one mook sheath

/obj/item/ego_weapon/shield/scabbard/mook_sheath/examine(mob/user)
	. = ..()
	if(powder_buff)
		. = "The powder is ready!"

/obj/item/ego_weapon/shield/scabbard/mook_sheath/UnSheathe(mob/living/carbon/human/user)
	if(powder_buff && !(sheathed_sword in donotbuff))
		var/buffed_sword = sheathed_sword
		sheathed_sword_og_force = sheathed_sword.force
		sheathed_sword_og_attack_speed = sheathed_sword.attack_speed
		//playsound
		sheathed_sword.force += 5
		sheathed_sword.attack_speed -= 0.1
		if(istype(buffed_sword, correct_sword))
			sheathed_sword_og_hitsound = sheathed_sword.hitsound
			sheathed_sword_og_icon_state = sheathed_sword.icon_state
			sheathed_sword.force += 10
			sheathed_sword.attack_speed -= 0.2
			//sheathed_sword.icon_state = "newicon"
			//sheathed_sword.hitsound = "newsound"
		addtimer(CALLBACK(src, PROC_REF(Revert_Buff), buffed_sword), 10 SECONDS)
		donotbuff += buffed_sword
		powder_buff = FALSE
	. = ..()

/obj/item/ego_weapon/shield/scabbard/mook_sheath/proc/Revert_Buff(obj/item/ego_weapon/scabbard_sword/buffed_sword)
	buffed_sword.force = sheathed_sword_og_force
	sheathed_sword_og_force = null
	buffed_sword.attack_speed = sheathed_sword_og_attack_speed
	sheathed_sword_og_attack_speed = null
	if(istype(buffed_sword, correct_sword))
		buffed_sword.hitsound = sheathed_sword_og_hitsound
		sheathed_sword_og_hitsound = null
		buffed_sword.icon_state = sheathed_sword_og_icon_state
		sheathed_sword_og_icon_state = null
	donotbuff -= buffed_sword
	addtimer(CALLBACK(src, PROC_REF(PowderCooldown), 20 SECONDS))

/obj/item/ego_weapon/shield/scabbard/mook_sheath/proc/PowderCooldown()
	powder_buff = TRUE
	//overlay code here mook powder to visually tell you your buff is ready

/obj/item/ego_weapon/scabbard_sword/mook_sword
	name = "Mook Workshop - Ye Model II Blade"
	desc = "A sharp sword, its silver hilt is accompanied by an ergonomic grip."
	//icon_state = "mook_blade"
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_weapons.dmi'
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right.dmi'
	force = 60
	damtype = RED_DAMAGE
	attack_verb_continuous = list("slashes", "carves", "gashes", "rends", "slices", "hacks",)
	attack_verb_simple = list("slashes", "carves", "gashes", "rends", "slices", "hacks",)
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 80,
	)

/obj/item/ego_weapon/city/examine(mob/user)
	. = ..()
	if(user.mind)
		if(user.mind.assigned_role in list("Disciplinary Officer", "Combat Research Agent")) //These guys get a bonus to equipping gacha.
			. += span_notice("Due to your abilities, you get a -20 reduction to stat requirements when equipping this weapon.")

/obj/item/ego_weapon/city/CanUseEgo(mob/living/user)
	if(user.mind)
		if(user.mind.assigned_role in list("Disciplinary Officer", "Combat Research Agent")) //These guys get a bonus to equipping gacha.
			equip_bonus = 20
		else
			equip_bonus = 0
	. = ..()



