/obj/item/clothing/suit/armor/ego_gear/city/carnival_robes
	name = "Carnival Robe"
	desc = "One of the Robes that the Carnival wear."
	icon_state = "carnival_robe"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 40, BLACK_DAMAGE = 60, PALE_DAMAGE = 0)
	mask = /obj/item/clothing/mask/ego_mask/carnival_mask/real
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)


/obj/item/clothing/mask/ego_mask/carnival_mask
	name = "paper carnival mask"
	desc = "A paper face mask that thoroughly conceals its user identity, it seems to be a attempt at mimicking the carnival's work."
	icon_state = "carnival_mask"
	flags_inv = HIDEFACE|HIDEEYES|HIDEFACIALHAIR|HIDESNOUT

//This mask is a true variant only the Carnival gets
/obj/item/clothing/mask/ego_mask/carnival_mask/real
	name = "carnival mask"
	desc = "A woven face mask that enables the carnival to do their work, the back of the mask is filled with circuitry that would make it difficult to remove from someone's face."
	modifies_speech = TRUE
	blocks_surgery = FALSE

// Ill find a way around this later
/obj/item/clothing/mask/carnival_mask/real/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, "carnival")

/obj/item/clothing/mask/carnival_mask/real/can_speak_language(language)
	return TRUE //Same exact benefits as a robotic tongue

//Remind me to force the mask to make you talk like LoR Carnival later on
/obj/item/clothing/mask/carnival_mask/real/handle_speech(datum/source, list/speech_args)
	speech_args[SPEECH_SPANS] |= SPAN_ROBOT
