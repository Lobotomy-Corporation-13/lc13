GLOBAL_LIST_EMPTY(department_chipped)
/obj/item/department_chip
	name = "Training Agent Chip"
	desc = "A Training agent chip. \
			Use in hand to give one the buffs of a training agent."
	icon = 'ModularLobotomy/_Lobotomyicons/station_traits.dmi'
	icon_state = "training_chip"
	slot_flags = ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_SMALL


/obj/item/department_chip/attack_self(mob/living/carbon/human/user)
	..()

	var/list/can_class = list(
			"Agent Intern",
			"Agent",
			"Agent Captain",
			)

	if(!(user?.mind?.assigned_role in can_class))
		return ..()

	if(user in GLOB.department_chipped)
		to_chat(user, span_notice("You already chose a department buff."))
		return

	GLOB.department_chipped |= user

	if(SSmaptype.chosen_trait == FACILITY_TRAIT_DEPARTMENTAL_BUFFS)
		to_chat(user, span_notice("You already have a department buff."))
		return

	DepartmentAdd(user)
	qdel(src)


/obj/item/department_chip/proc/DepartmentAdd(mob/living/carbon/human/user)
	ADD_TRAIT(user, TRAIT_BONUS_EXP, JOB_TRAIT)

/obj/item/department_chip/control
	name = "Control Agent Chip"
	desc = "A Control agent chip. \
			Use in hand to give one the buffs of a control agent."
	icon_state = "control_chip"

/obj/item/department_chip/control/DepartmentAdd(mob/living/carbon/human/user)
	user.add_movespeed_modifier(/datum/movespeed_modifier/assault)


/obj/item/department_chip/command
	name = "Command Agent Chip"
	desc = "A Command agent chip. \
			Use in hand to give one the buffs of a command agent."
	icon_state = "command_chip"

/obj/item/department_chip/command/DepartmentAdd(mob/living/carbon/human/user)
	user.adjust_attribute_buff(FORTITUDE_ATTRIBUTE, 3)
	user.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, 3)
	user.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, 3)
	user.adjust_attribute_buff(JUSTICE_ATTRIBUTE, 3)


/obj/item/department_chip/info
	name = "Information Agent Chip"
	desc = "An Information agent chip. \
			Use in hand to give one the buffs of an information agent."
	icon_state = "info_chip"

/obj/item/department_chip/info/DepartmentAdd(mob/living/carbon/human/user)
	user.adjust_attribute_bonus(TEMPERANCE_ATTRIBUTE, 10)


/obj/item/department_chip/safety
	name = "Safety Agent Chip"
	desc = "A Safety agent chip. \
			Use in hand to give one the buffs of a safety agent."
	icon_state = "safety_chip"

/obj/item/department_chip/safety/DepartmentAdd(mob/living/carbon/human/user)
	user.adjust_attribute_buff(FORTITUDE_ATTRIBUTE, 10)
	user.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, 10)


 /obj/item/department_chip/discipline
	name = "Disciplinary Agent Chip"
	desc = "A Disciplinart agent chip. \
			Use in hand to give one the buffs of a disciplinary agent."
	icon_state = "discipline_chip"

/obj/item/department_chip/discipline/DepartmentAdd(mob/living/carbon/human/user)
	ADD_TRAIT(user, TRAIT_STRONG_MELEE, JOB_TRAIT)


/obj/item/department_chip/welfare
	name = "Welfare Agent Chip"
	desc = "A Welfare agent chip. \
			Use in hand to give one the buffs of a welfare agent."
	icon_state = "welfare_chip"

/obj/item/department_chip/welfare/DepartmentAdd(mob/living/carbon/human/user)
	user.physiology.red_mod /= 1.07
	user.physiology.white_mod /= 1.07
	user.physiology.black_mod /= 1.07
	user.physiology.pale_mod /= 1.07


/obj/item/department_chip/extraction
	name = "Extraction Agent Chip"
	desc = "An Extraction agent chip. \
			Use in hand to give one the buffs of an extraction agent."
	icon_state = "extraction_chip"

/obj/item/department_chip/extraction/DepartmentAdd(mob/living/carbon/human/user)
	user.adjust_attribute_bonus(FORTITUDE_ATTRIBUTE, 5)
	user.adjust_attribute_bonus(PRUDENCE_ATTRIBUTE, 5)
	user.adjust_attribute_bonus(JUSTICE_ATTRIBUTE, 5)


/obj/item/department_chip/records
	name = "Records Agent Chip"
	desc = "A Records agent chip. \
			Use in hand to give one the buffs of a records agent."
	icon_state = "records_chip"

/obj/item/department_chip/records/DepartmentAdd(mob/living/carbon/human/user)
	user.adjust_attribute_limit(30)
