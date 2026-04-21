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
		// Check if user is Big Brother or it is Facility Mode
		if((user.mind && user.mind.assigned_role == "Big Brother") || !(SSmaptype.maptype in SSmaptype.citymaps))
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
	// You'll only be able to receive [vengeance_mark_stacks] from this item once every [mark_grace_period], and not due to attacks with a type listed in [mark_attack_blacklist_types].
	// The cooldown for each assailant is recorded separately in this list.
	var/list/mark_cooldowns = list()
	var/mark_grace_period = 0.5 SECONDS
	var/mark_attack_blacklist_types = (ATTACK_TYPE_STATUS | ATTACK_TYPE_ENVIRONMENT)

/obj/item/storage/book/middle/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 2
	STR.max_w_class = WEIGHT_CLASS_SMALL

/obj/item/storage/book/middle/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_BELT)
		RegisterSignal(user, COMSIG_MOB_APPLY_DAMGE, PROC_REF(MarkAttacker))

/obj/item/storage/book/middle/dropped(mob/living/carbon/human/user)
	. = ..()
	UnregisterSignal(user, COMSIG_MOB_APPLY_DAMGE)

/obj/item/storage/book/middle/proc/MarkAttacker(mob/living/carbon/human/awesome_sibling, damage, damagetype, def_zone, mob/living/source_of_damage, flags, attack_type)
	SIGNAL_HANDLER
	// Basic sanity checks
	if(!istype(awesome_sibling) || !istype(source_of_damage) || source_of_damage.stat >= DEAD || awesome_sibling == source_of_damage)
		return
	// Do not mark null damage/healing; do not mark blacklisted attack types; do not mark untrackable damage.
	if(damage < 0 || attack_type & mark_attack_blacklist_types || flags & DAMAGE_UNTRACKABLE)
		return
	// Do not mark if they're in their grace period. This is to avoid marking shotgunners with 1 trillion marks, and similar issues.
	if(mark_cooldowns[source_of_damage] && mark_cooldowns[source_of_damage] > world.time)
		return

	mark_cooldowns[source_of_damage] = world.time + mark_grace_period

	// Apply Vengeance Mark to the attacker
	source_of_damage.apply_vengeance_mark(vengeance_mark_stacks)
	to_chat(awesome_sibling, span_danger("The Book of Vengeance marks [source_of_damage] for retribution!"))

/obj/item/storage/book/middle/Destroy(force)
	mark_cooldowns = null
	return ..()

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

////////////////////////////////////////////////////////////
// MIDDLE NURSEFATHER (EX-GREAT BROTHER) GEAR

/obj/item/clothing/suit/armor/ego_gear/city/middle_nursefather
	name = "ex-great brother's coat"
	desc = "A massive coat bearing the colors and pattern of the Middle, worn over the shoulders. Its former owner was stripped of his rank but not his pride."
	icon = 'icons/obj/spider_house/middle/middle_spider_icon.dmi'
	worn_icon = 'icons/obj/spider_house/middle/middle_spider_worn.dmi'
	icon_state = "middlefather_outfit"
	neck = /obj/item/clothing/neck/ego_neck/middle_cape/nursefather
	flags_inv = HIDEJUMPSUIT
	equip_delay_self = 0
	armor = list(RED_DAMAGE = 70, WHITE_DAMAGE = 60, BLACK_DAMAGE = 60, PALE_DAMAGE = 60)
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100
	)

/obj/item/clothing/suit/armor/ego_gear/city/middle_nursefather/CanUseEgo(mob/living/carbon/human/user)
	if(user?.mind?.assigned_role == "Middle Ex-Great Brother")
		return TRUE
	return ..()

/obj/item/clothing/neck/ego_neck/middle_cape/nursefather
	name = "ex-great brother's cloak"
	desc = "A heavy cloak worn by a former Great Brother of the Middle."
	icon = 'icons/obj/spider_house/middle/middle_spider_icon.dmi'
	worn_icon = 'icons/obj/spider_house/middle/middle_spider_worn.dmi'
	icon_state = "middlefather_cloak"

/obj/item/clothing/glasses/middle_sunglasses/nursefather
	name = "gold-bridge sunglasses"
	desc = "Thick sunglasses with a gold bridge between the lenses. A signature accessory of the Middle's former Great Brother."
	icon = 'icons/obj/spider_house/middle/middle_spider_icon.dmi'
	worn_icon = 'icons/obj/spider_house/middle/middle_spider_worn.dmi'
	icon_state = "middlefather_sunglasses"

/obj/item/storage/book/middle/nursefather
	name = "the great book of vengeance"
	desc = "A sacred text of the Middle, its pages filled with a lifetime of grudges and retribution. This one belongs to a former Great Brother — its pages are extensive."
	icon = 'icons/obj/spider_house/middle/middle_spider_icon.dmi'
	worn_icon = 'icons/obj/spider_house/middle/middle_spider_worn.dmi'
	icon_state = "middlefather_vengeance"
	worn_icon_state = "middlefather_vengeance"
	vengeance_mark_stacks = 3
