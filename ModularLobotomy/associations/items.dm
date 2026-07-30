/obj/item/potential_tester
	name = "Hana Association Potential Tester"
	desc = "A device that can check the potential of civilians."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "potential_scanner"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_SMALL
	var/list/stats = list(
		FORTITUDE_ATTRIBUTE,
		PRUDENCE_ATTRIBUTE,
		TEMPERANCE_ATTRIBUTE,
		JUSTICE_ATTRIBUTE,
	)

/obj/item/potential_tester/afterattack(atom/target, mob/user, proximity_flag)
	. = ..()
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		var/stattotal
		var/grade
		for(var/attribute in stats)
			stattotal+=get_attribute_level(H, attribute)
		stattotal /= 4	//Potential is an average of stats
		grade = round((stattotal)/20)	//Get the average level-20, divide by 20
		to_chat(user, span_notice("Current Potential - [stattotal]."))

		//Under grade 9 doesn't register
		if(10-grade>=10)
			to_chat(user, span_notice("Potential too low to give grade. Not recommended to issue fixer license."))
			return

		to_chat(user, span_notice("Recommended Grade - [10-grade]."))
		to_chat(user, span_notice("Adjust grade based off accomplishments."))
		return

	to_chat(user, span_notice("No human potential identified."))


/obj/item/storage/box/ids/fixer
	name = "box of spare fixer IDs"
	illustration = "id"

/obj/item/storage/box/ids/fixer/PopulateContents()
	for(var/i in 1 to 7)
		new /obj/item/card/id/fixercard(src)

/obj/item/storage/box/ids/fixerdirector
	name = "box of spare fixer director IDs"
	illustration = "id"

/obj/item/storage/box/ids/fixerdirector/PopulateContents()
	for(var/i in 1 to 7)
		new /obj/item/card/id/fixerdirector(src)

//Fixer Leveller
/obj/item/attribute_increase/fixer
	name = "n corp training accelerator"
	desc = "A fluid used to increase the stats of a non-assocaition fixer. Use in hand to activate. Increases stats more the lower your potential."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "tcorp_syringe"
	amount = 1
	var/total_adjust = 0
	var/max_attributes = 130
	var/list/usable_roles = list("Civilian", "Office Director", "Office Fixer",
		"Subsidary Office Director", "Fixer")
	var/adjusting = FALSE

/obj/item/attribute_increase/fixer/attack_self(mob/living/carbon/human/user)
	//only civilians can use this.
	if(!adjusting)
		if(!(user?.mind?.assigned_role in usable_roles))
			to_chat(user, span_danger("You cannot use this item, as you must not belong to an association."))
			return

		//max stats can't gain stats
		if(get_attribute_level(user, TEMPERANCE_ATTRIBUTE)>=max_attributes)
			to_chat(user, span_danger("You feel like you won't gain anything."))
			return

		adjusting = TRUE

		//Guarantee one
		total_adjust += amount

		//Adjust by an extra attribute under level 2
		if(get_attribute_level(user, TEMPERANCE_ATTRIBUTE)<=40)
			total_adjust += amount
			total_adjust += amount

		//And one more under level 3
		if(get_attribute_level(user, TEMPERANCE_ATTRIBUTE)<=60)
			total_adjust += amount

		if(get_attribute_level(user, TEMPERANCE_ATTRIBUTE) < 40 && get_attribute_level(user, TEMPERANCE_ATTRIBUTE) + total_adjust >= 40)
			var/choice = alert("Are you sure you want to become level 2? This will restrict access to lower level skills.", , "Yes", "No")
			if(choice == "No")
				total_adjust = 0
				adjusting = FALSE
				return

		if(get_attribute_level(user, TEMPERANCE_ATTRIBUTE) < 60 && get_attribute_level(user, TEMPERANCE_ATTRIBUTE) + total_adjust >= 60)
			var/choice = alert("Are you sure you want to become level 3? This will restrict access to lower level skills.", , "Yes", "No")
			if(choice == "No")
				adjusting = FALSE
				total_adjust = 0
				return

		if(get_attribute_level(user, TEMPERANCE_ATTRIBUTE) < 100 && get_attribute_level(user, TEMPERANCE_ATTRIBUTE) + total_adjust >= 100)
			var/choice = alert("Are you sure you want to become level 4? This will restrict access to lower level skills.", , "Yes", "No")
			if(choice == "No")
				adjusting = FALSE
				total_adjust = 0
				return

		to_chat(user, span_nicegreen("You suddenly feel different."))
		user.adjust_all_attribute_levels(total_adjust)
		to_chat(user, "<span class='nicegreen'>You gained [total_adjust] potential!</span>")
		adjusting = FALSE
		qdel(src)

/obj/item/paramedic_cloak
	name = "Paramedic Ruins Cloaking Device"
	desc = "A device that can be used by Paramedics to hide from the dangers of the ruins."
	icon = 'ModularLobotomy/_Lobotomyicons/velvetfu.dmi'
	icon_state = "velvet"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_SMALL
	var/cloak_active = FALSE
	var/cloak_cooldown = 0
	var/cloak_cooldown_time = 15 SECONDS
	var/cloak_alpha = 150
	var/public_use = FALSE

/obj/item/paramedic_cloak/attack_self(mob/user)
	. = ..()
	ToggleCloak(user)

/obj/item/paramedic_cloak/proc/ToggleCloak(mob/living/user)
	if(!ishuman(user))
		return

	var/mob/living/carbon/human/H = user
	if(!public_use)
		if(!H.mind || H.mind.assigned_role != "Paramedic")
			to_chat(user, span_warning("This tool's systems do not recognize you."))
			return

	if(!cloak_active)
		if(world.time < cloak_cooldown)
			var/remaining = round((cloak_cooldown - world.time) / 10)
			to_chat(user, span_warning("Cloaking systems recharging. Ready in [remaining] seconds."))
			return
		ActivateCloak(user)
	else
		DeactivateCloak(user)

/obj/item/paramedic_cloak/proc/ActivateCloak(mob/living/user)
	cloak_active = TRUE
	to_chat(user, span_notice("You activate the cloaking field."))
	playsound(user, 'sound/effects/stealthoff.ogg', 30, TRUE)
	animate(user, alpha = cloak_alpha, time = 5 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(FullCloak), user), 5 SECONDS)

/obj/item/paramedic_cloak/proc/FullCloak(mob/living/user)
	if(!cloak_active)
		return
	user.density = FALSE
	user.invisibility = 0
	to_chat(user, span_notice("You are now fully cloaked."))

/obj/item/paramedic_cloak/proc/DeactivateCloak(mob/living/user)
	cloak_active = FALSE
	cloak_cooldown = world.time + cloak_cooldown_time
	to_chat(user, span_warning("Your cloaking field deactivates!"))
	playsound(user, 'sound/effects/stealthoff.ogg', 30, TRUE)
	user.density = TRUE
	user.invisibility = initial(user.invisibility)
	animate(user, alpha = 255, time = 2 SECONDS)

/obj/item/paramedic_cloak/equipped(mob/living/user, slot)
	. = ..()
	RegisterSignal(user, COMSIG_MOB_ITEM_ATTACK, PROC_REF(OnAttack))
	RegisterSignal(user, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnDamage))

/obj/item/paramedic_cloak/dropped(mob/living/user)
	. = ..()
	UnregisterSignal(user, COMSIG_MOB_ITEM_ATTACK)
	UnregisterSignal(user, COMSIG_MOB_APPLY_DAMGE)
	if(cloak_active)
		DeactivateCloak(user)

/obj/item/paramedic_cloak/proc/OnAttack(mob/living/user)
	SIGNAL_HANDLER
	if(cloak_active)
		DeactivateCloak(user)

/obj/item/paramedic_cloak/proc/OnDamage(mob/living/user, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(cloak_active && damage > 0)
		to_chat(user, span_warning("Your cloak flickers and fails as you take damage!"))
		DeactivateCloak(user)
