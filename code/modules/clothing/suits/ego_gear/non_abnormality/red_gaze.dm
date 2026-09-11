/obj/item/clothing/suit/armor/ego_gear/city/red_gaze
	name = "cobalt suit"
	desc = "A dark, pinstriped suit worn by the Color Fixer known as the Red Gaze. \
		Offers excellent defenses against everything."
	icon = 'ModularLobotomy/_Lobotomyicons/red_gaze_icons.dmi'
	worn_icon = 'ModularLobotomy/_Lobotomyicons/red_gaze_worn.dmi'
	icon_state = "red_gaze"
	armor = list(RED_DAMAGE = 70, WHITE_DAMAGE = 80, BLACK_DAMAGE = 80, PALE_DAMAGE = 70)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 120,
							PRUDENCE_ATTRIBUTE = 120,
							TEMPERANCE_ATTRIBUTE = 120,
							JUSTICE_ATTRIBUTE = 120
							)

// Admin variant — identical stats. While worn, the gladius can enter the Lavacrum Sanguinis State
// with no stored-blood requirement and no drain, and grants an action to end the state at will.
/obj/item/clothing/suit/armor/ego_gear/city/red_gaze/admin
	name = "effloresced cobalt suit"
	desc = "A dark, pinstriped suit worn by the Color Fixer known as the Red Gaze. This one blooms without end."
