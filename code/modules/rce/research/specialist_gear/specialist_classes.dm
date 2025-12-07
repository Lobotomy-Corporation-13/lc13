// R-Corp Specialist Class System
// Implants that transform Rooks into specialized combat roles

// Base specialist implant
/obj/item/organ/cyberimp/rce_specialist
	name = "R-Corp specialist implant"
	desc = "A military-grade neural implant that reconfigures the user's combat capabilities."
	icon_state = "imp_jetpack-on"
	slot = ORGAN_SLOT_BRAIN_ANTISTUN
	organ_flags = NONE // Not edible - allows attack() to work for implanting
	var/class_name = "Specialist"
	var/list/attribute_modifiers = list()
	var/list/granted_traits = list()
	var/specialist_type = null
	var/list/usable_roles = list(
		"R-Corp Rook",
		"Rook Squad Captain",
		"Robin Squad Captain",
		"Robin Section Leader",
		"Robin Squad Sergeant",
		"Section A Robin",
		"Section B Robin",
		"Section C Robin"
	)

/obj/item/organ/cyberimp/rce_specialist/Insert(mob/living/carbon/M, special, drop_if_replaced)
	. = ..()
	if(!ishuman(M))
		return

	var/mob/living/carbon/human/H = M

	// Check if user has a valid role title
	var/datum/job/user_job = H.mind?.assigned_role
	if(!user_job || !(user_job.title in usable_roles))
		to_chat(H, span_warning("This implant is only compatible with R-Corp Rook and Robin personnel."))
		Remove(H)
		return

	// Apply class transformation
	ApplyClassTransformation(H)

/obj/item/organ/cyberimp/rce_specialist/Remove(mob/living/carbon/M, special)
	if(ishuman(M))
		RemoveClassTransformation(M)
	return ..()

/obj/item/organ/cyberimp/rce_specialist/proc/ApplyClassTransformation(mob/living/carbon/human/H)
	// Apply attribute modifiers
	for(var/attribute in attribute_modifiers)
		H.adjust_attribute_bonus(attribute, attribute_modifiers[attribute])

	// Grant traits
	for(var/trait in granted_traits)
		ADD_TRAIT(H, trait, ORGAN_TRAIT)

	to_chat(H, span_notice("You have been transformed into a [class_name]!"))
	to_chat(H, span_nicegreen("You can now use [class_name] specialist weapons and equipment."))
	H.playsound_local(H, 'sound/magic/lightning_chargeup.ogg', 50, TRUE)

/obj/item/organ/cyberimp/rce_specialist/proc/RemoveClassTransformation(mob/living/carbon/human/H)
	// Remove attribute modifiers
	for(var/attribute in attribute_modifiers)
		H.adjust_attribute_bonus(attribute, -attribute_modifiers[attribute])

	// Remove traits
	for(var/trait in granted_traits)
		REMOVE_TRAIT(H, trait, ORGAN_TRAIT)

	to_chat(H, span_notice("The [class_name] transformation has ended."))

// HELLFIRE ROOSTER IMPLANT
/obj/item/organ/cyberimp/rce_specialist/hellfire
	name = "Hellfire Rooster combat implant"
	desc = "Transforms the user into a Hellfire Rooster, granting immunity to fire and enhanced pyrotechnic capabilities."
	class_name = "Hellfire Rooster"
	specialist_type = SPECIALIST_HELLFIRE
	attribute_modifiers = list(
		FORTITUDE_ATTRIBUTE = 20,
		PRUDENCE_ATTRIBUTE = -20,
		TEMPERANCE_ATTRIBUTE = 0,
		JUSTICE_ATTRIBUTE = 40
	)
	granted_traits = list(
		TRAIT_RESISTHEAT,
		TRAIT_NOFIRE
	)
	// No special actions - class just enables weapon usage

/obj/item/clothing/suit/armor/ego_gear/hellfire
	name = "r-corp hellfire rooster suit"
	desc = "Custom armor made for the hellfire units, perfect at protecting the user from flames. Requires Hellfire Rooster combat implant."
	slowdown = 0.5
	icon = 'icons/obj/clothing/suits.dmi'
	worn_icon = 'icons/mob/clothing/suit.dmi'
	icon_state = "hunter"
	inhand_icon_state = "hostrench"
	armor = list(RED_DAMAGE = 50, WHITE_DAMAGE = 30, BLACK_DAMAGE = 30, PALE_DAMAGE = 30, FIRE = 100)
	hat = /obj/item/clothing/head/ego_hat/helmet/hellfire
	allowed = list(/obj/item/gun, /obj/item/ego_weapon, /obj/item/melee, /obj/item/auto_flamethrower)

/obj/item/clothing/suit/armor/ego_gear/hellfire/mob_can_equip(mob/living/M, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE)
	if(!ishuman(M))
		return FALSE

	var/mob/living/carbon/human/H = M
	// Check for Hellfire Rooster implant
	if(!locate(/obj/item/organ/cyberimp/rce_specialist/hellfire) in H.internal_organs)
		if(!disable_warning)
			to_chat(H, span_warning("You need the Hellfire Rooster combat implant to use this armor!"))
		return FALSE

	return ..()

/obj/item/clothing/head/ego_hat/helmet/hellfire
	name = "r-corp hellfire rooster helmet"
	desc = "A custom made helmet worn by hellfire roosters."
	icon = 'icons/obj/clothing/masks.dmi'
	worn_icon = 'icons/mob/clothing/mask.dmi'
	icon_state = "hunter"
	inhand_icon_state = "hunter"
	resistance_flags = FIRE_PROOF | ACID_PROOF
	flags_inv = HIDEFACIALHAIR|HIDEFACE|HIDEEYES|HIDEEARS|HIDEHAIR|HIDESNOUT

// HEAVY HELLFIRE ROOSTER ARMOR - Upgraded version with better resistances
/obj/item/clothing/suit/armor/ego_gear/hellfire/heavy
	name = "r-corp heavy hellfire suit"
	desc = "Reinforced armor for veteran hellfire units. Offers superior protection while maintaining fire immunity. Requires Hellfire Rooster combat implant."
	color = "#b41e00"
	armor = list(RED_DAMAGE = 70, WHITE_DAMAGE = 50, BLACK_DAMAGE = 50, PALE_DAMAGE = 50, FIRE = 100)
	hat = /obj/item/clothing/head/ego_hat/helmet/hellfire/heavy

/obj/item/clothing/head/ego_hat/helmet/hellfire/heavy
	name = "r-corp heavy hellfire helmet"
	desc = "A reinforced helmet worn by veteran hellfire roosters."
	color = "#b41e00"

// VENOM RATTLESNAKE IMPLANT
/obj/item/organ/cyberimp/rce_specialist/venom
	name = "Venom Rattlesnake combat implant"
	desc = "Transforms the user into a Venom Rattlesnake, specializing in territorial control and toxic warfare."
	class_name = "Venom Rattlesnake"
	specialist_type = SPECIALIST_VENOM
	attribute_modifiers = list(
		FORTITUDE_ATTRIBUTE = 0,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 0,
		JUSTICE_ATTRIBUTE = -20
	)

// VENOM RATTLESNAKE ARMOR - Immune to own venom/acid
/obj/item/clothing/suit/armor/ego_gear/venom
	name = "r-corp venom rattlesnake suit"
	desc = "Custom armor made for the venom units, providing complete immunity to toxic and acidic damage. Requires Venom Rattlesnake combat implant."
	slowdown = 0.2
	icon = 'icons/obj/clothing/suits.dmi'
	worn_icon = 'icons/mob/clothing/suit.dmi'
	icon_state = "venom"
	inhand_icon_state = "hostrench"
	armor = list(RED_DAMAGE = 30, WHITE_DAMAGE = 30, BLACK_DAMAGE = 50, PALE_DAMAGE = 30, ACID = 100, TOX = 100)
	hat = /obj/item/clothing/head/ego_hat/helmet/venom
	var/venom_immune = TRUE // Flag for venom weapons to check

/obj/item/clothing/suit/armor/ego_gear/venom/mob_can_equip(mob/living/M, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE)
	if(!ishuman(M))
		return FALSE

	var/mob/living/carbon/human/H = M
	// Check for Venom Rattlesnake implant
	if(!locate(/obj/item/organ/cyberimp/rce_specialist/venom) in H.internal_organs)
		if(!disable_warning)
			to_chat(H, span_warning("You need the Venom Rattlesnake combat implant to use this armor!"))
		return FALSE

	return ..()

/obj/item/clothing/head/ego_hat/helmet/venom
	name = "r-corp venom rattlesnake helmet"
	desc = "A custom made helmet worn by venom rattlesnakes, with sealed breathing apparatus to prevent self-poisoning."
	icon = 'icons/obj/clothing/masks.dmi'
	worn_icon = 'icons/mob/clothing/mask.dmi'
	icon_state = "venom"
	inhand_icon_state = "venom"
	resistance_flags = FIRE_PROOF | ACID_PROOF
	flags_inv = HIDEFACIALHAIR|HIDEFACE|HIDEEYES|HIDEEARS|HIDEHAIR|HIDESNOUT

// HEAVY VENOM RATTLESNAKE ARMOR - Upgraded version with better resistances
/obj/item/clothing/suit/armor/ego_gear/venom/heavy
	name = "r-corp heavy venom suit"
	desc = "Reinforced armor for veteran venom units. Offers superior protection while maintaining acid and toxin immunity. Requires Venom Rattlesnake combat implant."
	color = "#509b50"
	armor = list(RED_DAMAGE = 50, WHITE_DAMAGE = 50, BLACK_DAMAGE = 70, PALE_DAMAGE = 50, ACID = 100, TOX = 100)
	hat = /obj/item/clothing/head/ego_hat/helmet/venom/heavy

/obj/item/clothing/head/ego_hat/helmet/venom/heavy
	name = "r-corp heavy venom helmet"
	desc = "A reinforced helmet worn by veteran venom rattlesnakes."
	color = "#509b50"

// STORM RAM IMPLANT
/obj/item/organ/cyberimp/rce_specialist/storm
	name = "Storm Ram combat implant"
	desc = "Transforms the user into a Storm Ram, granting enhanced durability and electromagnetic assault capabilities."
	class_name = "Storm Ram"
	specialist_type = SPECIALIST_STORM
	attribute_modifiers = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = -20,
		TEMPERANCE_ATTRIBUTE = 0,
		JUSTICE_ATTRIBUTE = 40
	)
	granted_traits = list(
		TRAIT_PUSHIMMUNE,
		TRAIT_SHOCKIMMUNE,
		TRAIT_NOGUNS
	)

// STORM RAM ARMOR - Speeds up the user
/obj/item/clothing/suit/armor/ego_gear/storm
	name = "r-corp storm ram suit"
	desc = "Custom armor made for the storm units, with integrated mobility enhancers that increase movement speed. Requires Storm Ram combat implant."
	slowdown = -0.15
	icon = 'icons/obj/clothing/suits.dmi'
	worn_icon = 'icons/mob/clothing/suit.dmi'
	icon_state = "storm"
	inhand_icon_state = "hostrench"
	armor = list(RED_DAMAGE = 60, WHITE_DAMAGE = 50, BLACK_DAMAGE = 60, PALE_DAMAGE = 50)
	hat = /obj/item/clothing/head/ego_hat/helmet/storm

/obj/item/clothing/suit/armor/ego_gear/storm/mob_can_equip(mob/living/M, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE)
	if(!ishuman(M))
		return FALSE

	var/mob/living/carbon/human/H = M
	// Check for Storm Ram implant
	if(!locate(/obj/item/organ/cyberimp/rce_specialist/storm) in H.internal_organs)
		if(!disable_warning)
			to_chat(H, span_warning("You need the Storm Ram combat implant to use this armor!"))
		return FALSE

	return ..()

/obj/item/clothing/head/ego_hat/helmet/storm
	name = "r-corp storm ram helmet"
	desc = "A custom made helmet worn by storm rams, featuring enhanced sensory systems for rapid response."
	icon = 'icons/obj/clothing/masks.dmi'
	worn_icon = 'icons/mob/clothing/mask.dmi'
	icon_state = "storm"
	inhand_icon_state = "storm"
	resistance_flags = FIRE_PROOF | ACID_PROOF
	flags_inv = HIDEFACIALHAIR|HIDEFACE|HIDEEYES|HIDEEARS|HIDEHAIR|HIDESNOUT

// HEAVY STORM RAM ARMOR - Upgraded version with better resistances
/obj/item/clothing/suit/armor/ego_gear/storm/heavy
	name = "r-corp heavy storm suit"
	desc = "Reinforced armor for veteran storm units. Offers superior protection while maintaining mobility enhancements. Requires Storm Ram combat implant."
	color = "#3939ab"
	armor = list(RED_DAMAGE = 80, WHITE_DAMAGE = 70, BLACK_DAMAGE = 80, PALE_DAMAGE = 70)
	hat = /obj/item/clothing/head/ego_hat/helmet/storm/heavy

/obj/item/clothing/head/ego_hat/helmet/storm/heavy
	name = "r-corp heavy storm helmet"
	desc = "A reinforced helmet worn by veteran storm rams."
	color = "#3939ab"
