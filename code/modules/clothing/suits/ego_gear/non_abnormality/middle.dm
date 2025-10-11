// The Middle Armor

//Little Brother Hawaii Shirt
/obj/item/clothing/suit/armor/ego_gear/city/middle
	name = "little brother hawaii shirt"
	desc = "A hawaii shirt worn by the Little Brothers of the Middle."
	icon = 'ModularLobotomy/_Lobotomyicons/middle_icons.dmi'
	worn_icon = 'ModularLobotomy/_Lobotomyicons/middle_worn.dmi'
	icon_state = "lilbro_hawaii"
	armor = list(RED_DAMAGE = 30, WHITE_DAMAGE = 20, BLACK_DAMAGE = 20, PALE_DAMAGE = 20)
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 60
	)

//Little Sister Hawaii Shirt
/obj/item/clothing/suit/armor/ego_gear/city/middle/little_sister
	name = "little sister hawaii shirt"
	desc = "A hawaii shirt worn by the Little Sisters of the Middle."
	icon_state = "lilsis_hawaii"

//Middle Tank Top
/obj/item/clothing/suit/armor/ego_gear/city/middle/tank_top
	name = "middle tank top"
	desc = "A tank top worn by the Middle."
	icon_state = "lil_tank"

//Younger Brother Coat
/obj/item/clothing/suit/armor/ego_gear/city/middle_younger
	name = "younger brother coat"
	desc = "Coat worn by The Younger Brothers of the Middle."
	icon = 'ModularLobotomy/_Lobotomyicons/middle_icons.dmi'
	worn_icon = 'ModularLobotomy/_Lobotomyicons/middle_worn.dmi'
	icon_state = "midbro_coat"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 30, BLACK_DAMAGE = 30, PALE_DAMAGE = 30)
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 80
	)

//Younger Sister Coat
/obj/item/clothing/suit/armor/ego_gear/city/middle_younger/younger_sister
	name = "younger sister coat"
	desc = "Coat worn by The Younger Sisters of the Middle."
	icon_state = "midsis_coat"

//Big Brother Gear
/obj/item/clothing/suit/armor/ego_gear/city/middle_big
	name = "big brother gear"
	desc = "Gear worn by The Big Brothers of the Middle."
	icon = 'ModularLobotomy/_Lobotomyicons/middle_icons.dmi'
	worn_icon = 'ModularLobotomy/_Lobotomyicons/middle_worn.dmi'
	icon_state = "bigbro_gear"
	neck = /obj/item/clothing/neck/ego_neck/middle_cape
	armor = list(RED_DAMAGE = 60, WHITE_DAMAGE = 50, BLACK_DAMAGE = 50, PALE_DAMAGE = 50)
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100
	)
	var/obj/effect/proc_holder/ability/great_leap/great_leap_ability = null

/obj/item/clothing/suit/armor/ego_gear/city/middle_big/Initialize()
	. = ..()
	// Create the ability but don't grant it yet
	great_leap_ability = new /obj/effect/proc_holder/ability/great_leap
	var/datum/action/spell_action/ability/item/A = great_leap_ability.action
	A.SetItem(src)

/obj/item/clothing/suit/armor/ego_gear/city/middle_big/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_OCLOTHING && ishuman(user))
		// Check if user is Big Brother
		if(user.mind && user.mind.assigned_role == "Big Brother")
			// Grant the ability action to the user
			if(great_leap_ability)
				var/datum/action/spell_action/ability/item/A = great_leap_ability.action
				A.Grant(user)
				to_chat(user, span_boldnotice("The Big Brother Gear grants you the power of the Great Leap!"))

/obj/item/clothing/suit/armor/ego_gear/city/middle_big/dropped(mob/living/carbon/human/user)
	. = ..()
	// Remove the ability action from the user
	if(great_leap_ability)
		var/datum/action/spell_action/ability/item/A = great_leap_ability.action
		A.Remove(user)

//Big Sister Gear
/obj/item/clothing/suit/armor/ego_gear/city/middle_big/big_sister
	name = "big sister gear"
	desc = "Gear worn by The Big Sisters of the Middle."
	icon_state = "bigsis_gear"

/obj/item/clothing/neck/ego_neck/middle_cape
	name = "big sibling's cape"
	desc = "A cape worn by Big Siblings of the Middle."
	icon = 'ModularLobotomy/_Lobotomyicons/middle_icons.dmi'
	worn_icon = 'ModularLobotomy/_Lobotomyicons/middle_worn.dmi'
	icon_state = "big_coat"

/obj/item/clothing/glasses/middle_sunglasses
	name = "middle sunglasses"
	desc = "Sunglasses worn by the Middle, great for aura farming."
	icon = 'ModularLobotomy/_Lobotomyicons/middle_icons.dmi'
	worn_icon = 'ModularLobotomy/_Lobotomyicons/middle_worn.dmi'
	icon_state = "big_shades"
	inhand_icon_state = "sunglasses"
	darkness_view = 1
	flash_protect = FLASH_PROTECTION_FLASH
	tint = 1

// The Books of Vengeance - Belt items for all ranks
// When equipped on belt, marks attackers with Vengeance Mark
//Little Brother's Book of Vengeance
/obj/item/storage/book/middle
	name = "the book of vengeance"
	desc = "A sacred text of the Middle, its pages filled with records of grudges and retribution. The Little Brothers carry it as both scripture and symbol. Those who attack its bearer will be marked for vengeance."
	icon = 'ModularLobotomy/_Lobotomyicons/middle_icons.dmi'
	worn_icon = 'ModularLobotomy/_Lobotomyicons/middle_worn.dmi'
	icon_state = "lil_book"
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_NORMAL
	var/vengeance_mark_stacks = 2

/obj/item/storage/book/middle/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 2
	STR.max_w_class = WEIGHT_CLASS_SMALL

/obj/item/storage/book/middle/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_BELT)
		RegisterSignal(user, COMSIG_PARENT_ATTACKBY, PROC_REF(MarkAttacker))
		RegisterSignal(user, COMSIG_ATOM_ATTACK_HAND, PROC_REF(MarkAttacker))
		RegisterSignal(user, COMSIG_ATOM_ATTACK_ANIMAL, PROC_REF(MarkAttacker))

/obj/item/storage/book/middle/dropped(mob/living/carbon/human/user)
	. = ..()
	UnregisterSignal(user, COMSIG_PARENT_ATTACKBY)
	UnregisterSignal(user, COMSIG_ATOM_ATTACK_HAND)
	UnregisterSignal(user, COMSIG_ATOM_ATTACK_ANIMAL)

/obj/item/storage/book/middle/proc/MarkAttacker(mob/living/carbon/human/victim, attacker, attacker_weapon)
	SIGNAL_HANDLER
	var/mob/living/actual_attacker = null

	// COMSIG_PARENT_ATTACKBY passes: victim, weapon, attacker, params
	// COMSIG_ATOM_ATTACK_HAND/ANIMAL passes: victim, attacker
	if(istype(attacker, /obj/item))
		// This is COMSIG_PARENT_ATTACKBY, attacker_weapon is actually the attacker
		if(isliving(attacker_weapon))
			actual_attacker = attacker_weapon
	else if(isliving(attacker))
		// This is COMSIG_ATOM_ATTACK_HAND or COMSIG_ATOM_ATTACK_ANIMAL
		actual_attacker = attacker

	// Apply Vengeance Mark to the attacker
	if(actual_attacker && actual_attacker != victim)
		actual_attacker.apply_vengeance_mark(vengeance_mark_stacks)
		to_chat(victim, span_danger("The Book of Vengeance marks [actual_attacker] for retribution!"))

//Younger Brother's Book of Vengeance
/obj/item/storage/book/middle/younger
	name = "the book of vengeance"
	desc = "A sacred text of the Middle, its pages filled with records of grudges and retribution. The Younger Brothers carry it as both scripture and symbol of authority."
	worn_icon_state = "mid_book"
	icon_state = "mid_book"

//Big Brother's Book of Vengeance
/obj/item/storage/book/middle/big
	name = "the great book of vengeance"
	desc = "A sacred text of the Middle, its pages filled with records of grudges and retribution. The Big Brothers have mastered its teachings."
	worn_icon_state = "big_book"
	icon_state = "big_book"
