////////////////////////////////////////////////////////////
// MIDDLE NURSEFATHER — EX-GREAT BROTHER
//
// A former Great Brother of the Middle. Highest HP pool of any nursefather.
// Wields Laevateinn, a sealed burning relic sword that unseals as he takes damage.
// Grappler playstyle — punches weaken targets, setting up grab combos.
// Missing right arm. No dodge passive, 2.5% clone damage instead of 5%.
////////////////////////////////////////////////////////////

/datum/job/middle_nursefather
	title = "Ex Great Brother"
	outfit = /datum/outfit/job/middle_nursefather
	department_head = list("the Middle")
	faction = "Station"
	supervisors = "the house of spiders"
	selection_color = "#9932CC"
	total_positions = 0
	spawn_positions = 0
	display_order = JOB_DISPLAY_ORDER_SYNDICATEHEAD
	trusted_only = TRUE
	access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	minimal_access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	departments = DEPARTMENT_COMMAND | DEPARTMENT_CITY_ANTAGONIST
	paycheck = 1000
	maptype = list("city", "fixers")
	job_important = "You are a former Great Brother of the Middle, stripped of your rank but not your strength. \
		You wield Laevateinn, a stolen burning Relic sealed by three layers of chains. You are NOT its rightful owner — it burns you each time you draw it. \
		As you take damage, seals break (at 75%, 50%, 25% HP), increasing your power and converting damage to armor-piercing fire. \
		Attacking and taking hits builds Grudge. Use the sword in-hand with 5+ Grudge to activate Enhancement Tattoos, buffing your damage. \
		Click a target at range to dash and unleash a combo — empowered by your Tattoos and seal stage. \
		You are missing your right arm. You do not dodge like other Nursefathers, but take reduced clone damage (2.5%). \
		You can recruit one apprentice using your recruitment scroll."
	job_notice = "You are a member of the Middle. Protect your siblings, spoil your apprentice, and write down anyone who wrongs you in the Book of Vengeance. \
		Those who slight the Middle will face summary execution."

	roundstart_attributes = list(
		FORTITUDE_ATTRIBUTE = 500,
		PRUDENCE_ATTRIBUTE = 500,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100
	)

/datum/job/middle_nursefather/after_spawn(mob/living/carbon/human/H, mob/M)
	// Remove right arm
	var/obj/item/bodypart/r_arm = H.get_bodypart(BODY_ZONE_R_ARM)
	if(r_arm)
		r_arm.drop_limb()
		qdel(r_arm)

	// Add traits
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)

	// Permanent components — not tied to weapon
	H.AddComponent(/datum/component/nursefather_passive/middle)
	H.AddComponent(/datum/component/nursefather_music, NURSEFATHER_FINGER_MIDDLE)
	// Other weapon-related components (grudge, seal) are granted by Laevateinn on pickup

	. = ..()

/datum/outfit/job/middle_nursefather
	name = "Ex Great Brother"
	jobtype = /datum/job/middle_nursefather

	id = /obj/item/card/id/silver/plastic
	belt = /obj/item/storage/book/middle/nursefather
	uniform = /obj/item/clothing/under/suit/charcoal
	suit = /obj/item/clothing/suit/armor/ego_gear/city/middle_nursefather
	suit_store = /obj/item/ego_weapon/city/laevateinn
	shoes = /obj/item/clothing/shoes/laceup
	glasses = /obj/item/clothing/glasses/middle_sunglasses/nursefather
	gloves = /obj/item/clothing/gloves/color/white
	l_pocket = /obj/item/apprentice_recruitment/middle_nursefather
	r_pocket = /obj/item/pda/security
	backpack_contents = list(\
		/obj/item/middle_car_phone = 1,\
		/obj/item/middle_stamp_card = 1\
	)

////////////////////////////////////////////////////////////
// APPRENTICE RECRUITMENT SCROLL

/obj/item/apprentice_recruitment/middle_nursefather
	name = "middle apprenticeship scroll"
	desc = "A scroll that allows you to recruit an apprentice into the Middle."

/obj/item/apprentice_recruitment/middle_nursefather/get_offer_text(mob/living/user)
	return "[user] is offering to make you their Middle Apprentice. Do you accept?"

/obj/item/apprentice_recruitment/middle_nursefather/get_offer_title()
	return "Apprenticeship Offer"

/obj/item/apprentice_recruitment/middle_nursefather/recruit_apprentice(mob/living/carbon/human/H, mob/living/user)
	// Set attributes
	H.set_attribute_limit(200)

	var/datum/attribute/fort = H.attributes[FORTITUDE_ATTRIBUTE]
	var/datum/attribute/prud = H.attributes[PRUDENCE_ATTRIBUTE]
	var/datum/attribute/temp = H.attributes[TEMPERANCE_ATTRIBUTE]
	var/datum/attribute/just = H.attributes[JUSTICE_ATTRIBUTE]

	if(fort)
		fort.level = 200
		fort.on_update(H)
	if(prud)
		prud.level = 200
		prud.on_update(H)
	if(temp)
		temp.level = 100
		temp.on_update(H)
	if(just)
		just.level = 100
		just.on_update(H)

	// Give armor (hood is attached as ego hat) and thermal blades
	var/obj/item/clothing/suit/armor/ego_gear/city/middle_apprentice/armor = new(H.loc)
	H.put_in_hands(armor)
	var/obj/item/ego_weapon/city/thermal_blade/blade1 = new(H.loc)
	H.put_in_hands(blade1)
	var/obj/item/ego_weapon/city/thermal_blade/blade2 = new(H.loc)
	H.put_in_hands(blade2)

	// Update ID card
	update_id_card(H, "Middle Apprentice")

	// Update mind role
	if(H.mind)
		H.mind.assigned_role = "Middle Apprentice"

	// Add traits — weapon-related components (passive, grudge) are granted by thermal blades on pickup
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, "middle_apprentice")
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, "middle_apprentice")

	// Give mirror shard relic
	var/obj/item/ruin_relic/mirror_shard/shard = new(H.loc)
	H.put_in_hands(shard)

	// Feedback
	to_chat(user, span_notice("You have recruited [H] as your apprentice."))
	playsound(get_turf(H), 'sound/abnormalities/onesin/bless.ogg', 50, 0, 4)

	to_chat(H, span_userdanger("You have become a Middle Apprentice!"))
	to_chat(H, span_boldnotice("You are now an apprentice of [user], a former Great Brother of the Middle. \
		You wield dual Thermal Blades — attack with one to trigger a follow-up strike from the other. \
		Taking damage builds Grudge. Use a blade in-hand with 5+ Grudge to activate your Enhancement Tattoos. \
		While Tattoos are active, your blades inflict Overheat instead of Bleed."))
	to_chat(H, span_boldnotice("You automatically dodge the first attack every 30 seconds, \
		and have a 50% chance to dodge attacks when not holding a weapon. \
		However, all damage you take also inflicts 5% unhealable damage."))
	to_chat(H, span_boldnotice("You carry a strange mirror shard. Find a quiet moment alone to attune to it. \
		Once attuned, use it in hand to cloak yourself. Your first attack while cloaked will pin the target down."))
	to_chat(H, span_boldwarning("Protect your siblings. Enact vengeance on those who wrong the Middle."))

////////////////////////////////////////////////////////////
// DEBUG TRANSFORM ITEM

/obj/item/middle_nursefather_debug
	name = "ex-great brother's signet"
	desc = "A debug item. Use in hand to transform into the Ex Great Brother with full gear and abilities."
	icon = 'icons/obj/spider_house/middle/middle_spider_icon.dmi'
	icon_state = "middle_grudge"
	w_class = WEIGHT_CLASS_TINY

/obj/item/middle_nursefather_debug/attack_self(mob/living/user)
	if(!ishuman(user))
		to_chat(user, span_warning("Only humans can use this."))
		return
	var/mob/living/carbon/human/H = user

	to_chat(H, span_boldnotice("Transforming into Ex Great Brother..."))

	// Drop all held and worn items
	H.drop_all_held_items()
	for(var/obj/item/I in H.get_equipped_items())
		H.dropItemToGround(I, TRUE)

	// Remove right arm
	var/obj/item/bodypart/r_arm = H.get_bodypart(BODY_ZONE_R_ARM)
	if(r_arm)
		r_arm.drop_limb()
		qdel(r_arm)

	// Set attributes
	H.set_attribute_limit(500)
	for(var/attr_name in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE, TEMPERANCE_ATTRIBUTE, JUSTICE_ATTRIBUTE))
		var/datum/attribute/A = H.attributes[attr_name]
		if(A)
			if(attr_name in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE))
				A.level = 500
			else
				A.level = 100
			A.on_update(H)

	// Set role
	if(H.mind)
		H.mind.assigned_role = "Ex Great Brother"

	// Add traits
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)

	// Permanent components
	H.AddComponent(/datum/component/nursefather_passive/middle)
	H.AddComponent(/datum/component/nursefather_music, NURSEFATHER_FINGER_MIDDLE)

	// Equip outfit — other weapon-related components (grudge, seal) are granted by Laevateinn on pickup
	var/datum/outfit/job/middle_nursefather/outfit = new()
	outfit.equip(H)

	to_chat(H, span_boldnotice("You are now the Ex Great Brother. Laevateinn is on your back."))

	// Consume the debug item
	qdel(src)

////////////////////////////////////////////////////////////
// GHOST POLL SPAWN ITEM

/obj/item/middle_nursefather_ghost_spawn
	name = "ex-great brother's calling"
	desc = "A debug item. Use in hand to poll trusted ghosts for a Ex Great Brother player."
	icon = 'icons/obj/spider_house/middle/middle_spider_icon.dmi'
	icon_state = "middle_grudge"
	w_class = WEIGHT_CLASS_TINY
	/// Whether a poll is currently active
	var/polling = FALSE

/obj/item/middle_nursefather_ghost_spawn/attack_self(mob/living/user)
	if(!ishuman(user))
		to_chat(user, span_warning("Only humans can use this."))
		return
	if(polling)
		to_chat(user, span_warning("A poll is already in progress!"))
		return

	polling = TRUE
	to_chat(user, span_notice("Polling ghosts for a Ex Great Brother candidate..."))

	var/turf/spawn_loc = get_turf(src)

	var/list/candidates = pollGhostCandidates("Do you wish to become the Ex Great Brother?", ROLE_TRAITOR, poll_time = 300)

	if(QDELETED(src))
		return

	// Filter for trusted players
	var/list/trusted_candidates = list()
	for(var/mob/dead/observer/candidate in candidates)
		if(candidate.client && is_trusted_player(candidate.client))
			trusted_candidates += candidate
		else if(candidate.client)
			to_chat(candidate, span_warning("You were not selected because this role requires trusted player status."))

	if(!length(trusted_candidates))
		to_chat(user, span_warning("No trusted candidates accepted the poll."))
		polling = FALSE
		return

	var/mob/dead/observer/chosen = pick(trusted_candidates)
	var/mob/living/carbon/human/H = makeBody(chosen)
	if(!H)
		to_chat(user, span_warning("Failed to create a body for the candidate."))
		polling = FALSE
		return

	H.forceMove(spawn_loc)

	// Remove right arm
	var/obj/item/bodypart/r_arm = H.get_bodypart(BODY_ZONE_R_ARM)
	if(r_arm)
		r_arm.drop_limb()
		qdel(r_arm)

	// Set attributes
	H.set_attribute_limit(500)
	for(var/attr_name in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE, TEMPERANCE_ATTRIBUTE, JUSTICE_ATTRIBUTE))
		var/datum/attribute/A = H.attributes[attr_name]
		if(A)
			if(attr_name in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE))
				A.level = 500
			else
				A.level = 100
			A.on_update(H)

	// Set role
	if(H.mind)
		H.mind.assigned_role = "Ex Great Brother"

	// Add traits
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)

	// Permanent components
	H.AddComponent(/datum/component/nursefather_passive/middle)
	H.AddComponent(/datum/component/nursefather_music, NURSEFATHER_FINGER_MIDDLE)

	// Equip outfit — other weapon-related components (grudge, seal) are granted by Laevateinn on pickup
	var/datum/outfit/job/middle_nursefather/outfit = new()
	outfit.equip(H)

	to_chat(H, span_boldnotice("You are the Ex Great Brother. Laevateinn is on your back."))

	// Consume the item
	qdel(src)
