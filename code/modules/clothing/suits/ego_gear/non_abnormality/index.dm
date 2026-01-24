/obj/item/clothing/suit/armor/ego_gear/city/index
	flags_inv = HIDEJUMPSUIT | HIDEGLOVES
	name = "index proselyte armor"
	desc = "Armor worn by index proselytes."
	icon_state = "index_proselyte"
	armor = list(RED_DAMAGE = 20, WHITE_DAMAGE = 20, BLACK_DAMAGE = 20, PALE_DAMAGE = 30)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)

/obj/item/clothing/suit/armor/ego_gear/index_proxy //Choose your Drip babey
	name = "index proxy armor"
	desc = "Armor worn by index proxies."
	icon_state = "index_proxy_open"
	icon = 'icons/obj/clothing/ego_gear/lc13_armor.dmi'
	worn_icon = 'icons/mob/clothing/ego_gear/lc13_armor.dmi'
	armor = list(RED_DAMAGE = 30, WHITE_DAMAGE = 30, BLACK_DAMAGE = 30, PALE_DAMAGE = 40)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)

/obj/item/clothing/suit/armor/ego_gear/index_proxy/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/adjustable_gear, list("index_proxy_open", "index_proxy_closed"))

/obj/item/clothing/suit/armor/ego_gear/index_proxy/examine(mob/user)
	. = ..()
	if(user.mind)
		if(user.mind.assigned_role in list("Disciplinary Officer", "Combat Research Agent")) //These guys get a bonus to equipping gacha.
			. += span_notice("Due to your abilities, you get a -20 reduction to stat requirements when equipping this armor.")

/obj/item/clothing/suit/armor/ego_gear/index_proxy/CanUseEgo(mob/living/user)
	if(user.mind)
		if(user.mind.assigned_role in list("Disciplinary Officer", "Combat Research Agent")) //These guys get a bonus to equipping gacha.
			equip_bonus = 20
		else
			equip_bonus = 0
	. = ..()

/obj/item/clothing/suit/armor/ego_gear/index_proxy/apprentice
	name = "index proxy apprentice armor"
	desc = "Armor worn by index proxy apprentices. Grants an ability to summon chains."
	icon = 'icons/obj/clothing/ego_gear/lc13_armor.dmi'
	worn_icon = 'icons/mob/clothing/ego_gear/lc13_armor.dmi'
	icon_state = "index_apprentice"

	var/obj/item/ego_weapon/city/index_apprentice_chains/chains_weapon
	var/obj/item/ego_weapon/city/index_procuration/procuration_weapon
	var/mob/living/carbon/human/armor_wearer
	/// Prescript completions stored on armor (persists until armor removed)
	var/prescript_completions = 0

/obj/item/clothing/suit/armor/ego_gear/index_proxy/apprentice/Initialize()
	. = ..()
	var/obj/effect/proc_holder/ability/AS = new /obj/effect/proc_holder/ability/apprentice_chains
	var/datum/action/spell_action/ability/item/A = AS.action
	A.SetItem(src)

/obj/item/clothing/suit/armor/ego_gear/index_proxy/apprentice/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_OCLOTHING && ishuman(user))
		armor_wearer = user
		RegisterSignal(user, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(on_wearer_damaged))

/obj/item/clothing/suit/armor/ego_gear/index_proxy/apprentice/dropped(mob/user)
	. = ..()
	if(armor_wearer)
		UnregisterSignal(armor_wearer, COMSIG_MOB_AFTER_APPLY_DAMGE)
		remove_chains()
		remove_procuration()
		armor_wearer = null

/obj/item/clothing/suit/armor/ego_gear/index_proxy/apprentice/proc/on_wearer_damaged(datum/source)
	SIGNAL_HANDLER
	if(!armor_wearer || !chains_weapon)
		return
	if(armor_wearer.health <= (armor_wearer.maxHealth * 0.5))
		INVOKE_ASYNC(src, PROC_REF(transform_to_procuration), armor_wearer)

/obj/item/clothing/suit/armor/ego_gear/index_proxy/apprentice/proc/grant_chains(mob/living/carbon/human/user)
	if(chains_weapon || procuration_weapon)
		return FALSE

	// If already unlocked, grant Procuration directly
	if(prescript_completions >= 3)
		transform_to_procuration(user)
		return TRUE

	chains_weapon = new /obj/item/ego_weapon/city/index_apprentice_chains
	chains_weapon.linked_armor = src

	if(!user.put_in_hands(chains_weapon))
		QDEL_NULL(chains_weapon)
		to_chat(user, span_warning("You need a free hand to summon the chains!"))
		return FALSE

	to_chat(user, span_userdanger("Chains manifest in your hands!"))
	playsound(get_turf(user), 'sound/abnormalities/onesin/bless.ogg', 50, 0, 4)
	return TRUE

/obj/item/clothing/suit/armor/ego_gear/index_proxy/apprentice/proc/remove_chains(reset_progress = FALSE)
	if(chains_weapon)
		REMOVE_TRAIT(chains_weapon, TRAIT_NODROP, "index_chains")
		var/mob/living/holder = chains_weapon.loc
		if(istype(holder))
			holder.dropItemToGround(chains_weapon, force = TRUE, silent = TRUE)
		QDEL_NULL(chains_weapon)
	if(reset_progress)
		prescript_completions = 0

/obj/item/clothing/suit/armor/ego_gear/index_proxy/apprentice/proc/transform_to_procuration(mob/living/carbon/human/user)
	remove_chains()

	if(procuration_weapon)
		return

	procuration_weapon = new /obj/item/ego_weapon/city/index_procuration
	procuration_weapon.linked_armor = src

	if(!user.put_in_hands(procuration_weapon))
		QDEL_NULL(procuration_weapon)
		to_chat(user, span_warning("You need a free hand for the transformation!"))
		return

	to_chat(user, span_userdanger("Your chains transform into Effloresced E.G.O :: Procuration!"))
	playsound(get_turf(user), 'sound/items/index_beeper_prescript.ogg', 50, 0, 4)
	new /obj/effect/temp_visual/onesin_blessing(get_turf(user))

/obj/item/clothing/suit/armor/ego_gear/index_proxy/apprentice/proc/remove_procuration(reset_progress = FALSE)
	if(procuration_weapon)
		REMOVE_TRAIT(procuration_weapon, TRAIT_NODROP, "index_procuration")
		var/mob/living/holder = procuration_weapon.loc
		if(istype(holder))
			holder.dropItemToGround(procuration_weapon, force = TRUE, silent = TRUE)
		QDEL_NULL(procuration_weapon)
	if(reset_progress)
		prescript_completions = 0

/obj/item/clothing/suit/armor/ego_gear/city/index_mess
	name = "index messenger armor"
	desc = "Armor worn by index messengers."
	icon_state = "yan_cloak"
	armor = list(RED_DAMAGE = 50, WHITE_DAMAGE = 50, BLACK_DAMAGE = 50, PALE_DAMAGE = 60)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 100
							)

/obj/item/clothing/suit/armor/ego_gear/city/index_proxy_wanderer
	name = "wandering index proxy armor"
	desc = "Armor worn by a wandering index proxy."
	icon_state = "index_proxy_wanderer"
	mask = /obj/item/clothing/mask/ego_mask/index_proxy
	armor = list(RED_DAMAGE = 60, WHITE_DAMAGE = 40, BLACK_DAMAGE = 50, PALE_DAMAGE = 60)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 100
							)

/obj/item/clothing/mask/ego_mask/index_proxy
	name = "proxy mask"
	desc = "I keep it covered because it hurts to even look at."
	icon_state = "index_proxy_mask"
	flags_inv = HIDEFACE|HIDESNOUT

/obj/item/clothing/mask/ego_mask/index_proxy_alt
	name = "indulgence in prescripts"
	desc = "The acceptance of the Prescripts is apparent in his execution of them; yet, on the other side of the mask, one may glimpse a hint of resentment for them."
	icon_state = "index_proxy_mask_alt"
	flags_inv = HIDEFACE|HIDESNOUT
