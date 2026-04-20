////////////////////////////////////////////////////////////
// EX THUMB SOTTOCAPO
//
// A trusted player role for a former Sottocapo of the Thumb's spider house
// who dual-wields a rapier and katana with acceleration propellant ammunition.
// They have 150 Fortitude and come equipped with their weapons, armor, ammo,
// Eye of Odin, and a suspicious phone for ordering additional ammo supplies.
////////////////////////////////////////////////////////////

/datum/job/ex_thumb_sottocapo
	title = "Ex Thumb Sottocapo"
	outfit = /datum/outfit/job/ex_thumb_sottocapo
	department_head = list("Thumb Sottocapo")
	faction = "Station"
	supervisors = "the Thumb's hierarchy"
	selection_color = "#8b0000"
	total_positions = 0
	spawn_positions = 0
	display_order = JOB_DISPLAY_ORDER_SYNDICATEHEAD
	trusted_only = TRUE
	access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	minimal_access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	departments = DEPARTMENT_COMMAND | DEPARTMENT_CITY_ANTAGONIST
	paycheck = 1000
	maptype = list("city", "fixers")
	job_important = "You are a former Sottocapo of the Thumb - a high-ranking operative of the spider house. \
		You dual-wield a rapier and katana loaded with acceleration propellant ammunition. \
		Your combo requires weapon-swapping: lunge with one weapon, AoE sweep with the other, then finish with the first. \
		Your Eye of Odin grants precognitive evasion against melee attacks, but overheats if overused. \
		Use your suspicious phone to order additional ammunition."
	job_notice = "You are a Syndicate operative. Act accordingly."

	roundstart_attributes = list(
		FORTITUDE_ATTRIBUTE = 150,
		PRUDENCE_ATTRIBUTE = 150,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100
	)

/datum/job/ex_thumb_sottocapo/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	H.AddComponent(/datum/component/nursefather_passive)
	H.AddComponent(/datum/component/nursefather_music, NURSEFATHER_FINGER_THUMB)

	// Insert the Eye of Odin
	var/obj/item/organ/eyes/robotic/odin_eye/eye = new()
	eye.Insert(H)

	// Equip armor into hand (too bulky for suit slot auto-equip)
	var/obj/item/clothing/suit/armor/ego_gear/city/thumb_spider/ex_sottocapo/armor = new(H)
	H.put_in_l_hand(armor)

	// Put weapons and ammo boxes into backpack directly
	var/obj/item/storage/backpack/BP = locate() in H.contents
	if(BP)
		new /obj/item/ego_weapon/city/thumbfather_rapier(BP)
		new /obj/item/ego_weapon/city/thumbfather_katana(BP)
		new /obj/item/storage/box/thumb_east_ammo/acceleration(BP)
		new /obj/item/storage/box/thumb_east_ammo/acceleration(BP)

	// Grant rules action
	var/datum/action/innate/view_role_rules/thumb_nursefather/rules = new
	rules.Grant(H)

	. = ..()

/datum/outfit/job/ex_thumb_sottocapo
	name = "Ex Thumb Sottocapo"
	jobtype = /datum/job/ex_thumb_sottocapo

	id = /obj/item/card/id/silver/plastic
	belt = /obj/item/pda/security
	uniform = /obj/item/clothing/under/suit/charcoal
	shoes = /obj/item/clothing/shoes/laceup
	r_pocket = /obj/item/nursefather_phone
	l_pocket = /obj/item/apprentice_recruitment/thumb_nursefather

////////////////////////////////////////////////////////////
// NURSEFATHER PHONE - Ammo requisition device
//
// A suspicious phone that lets the Ex Thumb Sottocapo order additional
// boxes of acceleration propellant ammunition for 1500 ahn.
////////////////////////////////////////////////////////////

/obj/item/nursefather_phone
	name = "suspicious phone"
	desc = "A heavily encrypted phone used by Thumb operatives to place discreet supply orders. The contact list has a single entry labeled 'Procurement'."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "suspiciousphone"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/nursefather_phone/attack_self(mob/living/user)
	. = ..()
	if(!isliving(user))
		return

	var/obj/item/card/id/C = user.get_idcard(TRUE)
	if(!C)
		to_chat(user, span_warning("You need an ID card to place an order."))
		return
	if(!C.registered_account)
		to_chat(user, span_warning("Your ID card has no registered bank account."))
		return

	var/datum/bank_account/account = C.registered_account
	var/cost = 1500

	if(!account.has_money(cost))
		to_chat(user, span_warning("Insufficient funds. You need [cost] ahn to order ammunition. You have [account.account_balance] ahn."))
		playsound(src, 'sound/machines/buzz-two.ogg', 25, TRUE)
		return

	// Confirm the purchase
	var/confirm = tgui_alert(user, "Order a box of acceleration propellant ammunition for [cost] ahn? (Balance: [account.account_balance] ahn)", "Ammunition Requisition", list("Confirm", "Cancel"))
	if(confirm != "Confirm")
		return
	// Re-check after the alert (user could have moved, spent money, etc.)
	if(!Adjacent(user) || QDELETED(src) || QDELETED(user))
		return
	if(!account.has_money(cost))
		to_chat(user, span_warning("Insufficient funds."))
		playsound(src, 'sound/machines/buzz-two.ogg', 25, TRUE)
		return

	account.adjust_money(-cost)
	var/obj/item/storage/box/thumb_east_ammo/acceleration/ammo_box = new(get_turf(user))
	if(!user.put_in_hands(ammo_box))
		ammo_box.forceMove(get_turf(user))
	playsound(src, 'sound/effects/cashregister.ogg', 25, TRUE)
	to_chat(user, span_notice("Order confirmed. A box of acceleration propellant ammunition has been delivered. Remaining balance: [account.account_balance] ahn."))

/obj/item/nursefather_phone/examine(mob/user)
	. = ..()
	. += span_notice("Use in-hand to order a box of acceleration propellant ammunition for <b>1500 ahn</b>.")

////////////////////////////////////////////////////////////
// THUMB APPRENTICE RECRUITMENT SCROLL
/obj/item/apprentice_recruitment/thumb_nursefather
	name = "thumb apprenticeship scroll"
	desc = "A scroll that allows you to recruit an apprentice into the Thumb's spider house."

/obj/item/apprentice_recruitment/thumb_nursefather/get_offer_text(mob/living/user)
	return "[user] is offering to make you their Thumb Apprentice. Do you accept?"

/obj/item/apprentice_recruitment/thumb_nursefather/get_offer_title()
	return "Apprenticeship Offer"

/obj/item/apprentice_recruitment/thumb_nursefather/recruit_apprentice(mob/living/carbon/human/H, mob/living/user)
	// Any prior Nursefather role (Ring, Index, etc.) is automatically cleaned up by
	// COMSIG_NURSEFATHER_RECRUITMENT_OVERRIDE sent in the base class before this proc runs.

	// Set attributes
	H.set_attribute_limit(200)

	var/datum/attribute/fort = H.attributes[FORTITUDE_ATTRIBUTE]
	var/datum/attribute/prud = H.attributes[PRUDENCE_ATTRIBUTE]
	var/datum/attribute/temp = H.attributes[TEMPERANCE_ATTRIBUTE]
	var/datum/attribute/just = H.attributes[JUSTICE_ATTRIBUTE]

	if(fort)
		fort.level = 40
		fort.on_update(H)
	if(prud)
		prud.level = 40
		prud.on_update(H)
	if(temp)
		temp.level = 40
		temp.on_update(H)
	if(just)
		just.level = 40
		just.on_update(H)

	// Give armor (tier 1)
	var/obj/item/clothing/suit/armor/ego_gear/city/thumb_spider/apprentice/armor = new(H.loc)
	H.put_in_hands(armor)

	// Give weapons (tier 1)
	var/obj/item/ego_weapon/city/thumbapprentice_katana/katana = new(H.loc)
	H.put_in_hands(katana)
	var/obj/item/ego_weapon/city/thumbapprentice_greatsword/greatsword = new(H.loc)
	H.put_in_hands(greatsword)

	// Update ID card
	update_id_card(H, "Thumb Apprentice")

	// Update mind role
	if(H.mind)
		H.mind.assigned_role = "Thumb Apprentice"

	// Add traits
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, "thumb_apprentice")
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, "thumb_apprentice")

	// Grant Palermitan systems
	// Base passives (Duello + Palermitan Style + nursefather interactions)
	H.AddComponent(/datum/component/palermitan_apprentice, user)
	// EXP tracking
	H.AddComponent(/datum/component/palermitan_exp)
	// Duel challenge action
	var/datum/action/innate/thumb_duel_challenge/duel_action = new()
	duel_action.Grant(H)
	// Skill tree action
	var/datum/action/innate/palermitan_tree/tree_action = new()
	tree_action.Grant(H)

	// Grant rules action
	var/datum/action/innate/view_role_rules/thumb_apprentice/app_rules = new
	app_rules.Grant(H)

	// Feedback
	to_chat(user, span_notice("You have recruited [H] as your apprentice."))
	playsound(get_turf(H), 'sound/abnormalities/onesin/bless.ogg', 50, 0, 4)

	to_chat(H, span_userdanger("You have become a Thumb Apprentice!"))
	to_chat(H, span_boldnotice("You are now an apprentice of [user], a former Sottocapo of the Thumb's spider house. \
		You have been given a katana and greatsword, along with apprentice armor. \
		Your gear will grow stronger as you do."))
	to_chat(H, span_boldnotice("You have two new abilities: \
		'Challenge to Duel' lets you challenge others to duels for progression. \
		'Palermitan Skill Tree' lets you spend skill points earned from duels."))
	to_chat(H, span_boldnotice("Review your role rules by clicking the 'View Thumb Rules' action button."))
	to_chat(H, span_boldwarning("Follow the orders of your mentor. Act in the Thumb's interest."))

////////////////////////////////////////////////////////////
// ROLE RULES ACTIONS

/datum/action/innate/view_role_rules/thumb_nursefather
	name = "View Thumb Rules"
	desc = "Review the Ex Thumb Sottocapo's trusted role rulings."
	rules_title = "Ex Thumb Sottocapo - Trusted Role Rulings"
	accent_color = "#8b0000"
	window_name = "thumb_nursefather_rules"
	window_size = "600x700"

/datum/action/innate/view_role_rules/thumb_nursefather/get_rules_content()
	return {"
	<div class="section">
		<h2>Your Purpose</h2>
		<p>You are a former Sottocapo of the Thumb's spider house &mdash; a high-ranking operative who dual-wields a rapier and katana loaded with acceleration propellant ammunition. You have gone independent, but your skills and connections remain.</p>
	</div>

	<div class="section">
		<h2>Combat Style</h2>
		<p>Your weapons use the <b>Acceleration Round</b> system and a <b>cross-combo</b> that requires weapon-swapping between your rapier and katana.</p>
		<ul>
			<li>Every 2nd hit triggers your off-hand weapon for a follow-up attack at reduced damage.</li>
			<li>Spending acceleration rounds grants <span class="good">Poise</span> (rapier) or <span class="good">Concentration</span> (katana).</li>
			<li>Poise crits apply Tremor and Overheat to your target.</li>
			<li>Use your <b>suspicious phone</b> to order additional ammunition.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Recruiting an Apprentice</h2>
		<p>You have a <b>Thumb Apprenticeship Scroll</b> that lets you recruit one player as your apprentice. This is a <span class="good">roleplay opportunity</span> &mdash; choose someone who will engage with the role.</p>
		<ul>
			<li>Your apprentice starts weak (40 attributes) with evolving gear that grows through duels.</li>
			<li>They learn the <b>Palermitan Style</b> &mdash; a sword technique focused on single-target hunts.</li>
			<li>You are their <span class="good">mentor</span>. Guide them, correct them when they lose, share drinks with them.</li>
			<li>The scroll can only be used <span class="warning">once</span>. Choose wisely.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Mentoring Your Apprentice</h2>
		<p>Your apprentice benefits from your guidance in several ways:</p>
		<ul>
			<li><b>Sharing drinks:</b> When your apprentice offers you an alcoholic drink, they gain EXP from the exchange.</li>
			<li><b>Sharing meals:</b> When your apprentice offers you food, they gain EXP. Accept their service graciously.</li>
			<li><b>Glass bottles:</b> Throwing or hitting your apprentice with a glass bottle grants them EXP. A Thumb tradition.</li>
			<li><b>Daily training:</b> Striking your apprentice with a weapon grants them EXP. Discipline through combat is the Thumb way.</li>
			<li><b>Post-duel correction:</b> After your apprentice loses a duel, punch them with <b>bare fists</b> within 1.5 minutes to grant bonus attributes. The correction escalates in severity with repeated use.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Conduct and Escalation</h2>
		<ul>
			<li><span class="warning">Avoid killing other players without a reason.</span> You are a Syndicate operative, but not a mindless killer.</li>
			<li>You may use your apprentice recruitment as an RP hook to interact with other players.</li>
			<li>Your apprentice's duels require the other player to accept the challenge prompt.</li>
			<li><span class="good">You may intimidate others</span> into dueling your apprentice &mdash; leveraging your status and reputation to pressure people into accepting is the Thumb way.</li>
			<li>If someone of <span class="highlight">lower rank</span> than you tries to avoid a duel, you may <span class="good">rough them up</span> to remind them of their place. The Thumb does not tolerate disrespect from inferiors.</li>
			<li>However, <span class="warning">avoid killing without buildup and escalation</span>. Outright murdering someone over a refused duel with no warning is a violation. Threaten first, escalate if they persist, and only resort to serious violence after giving them chances.</li>
		</ul>
	</div>

	<div class="section">
		<h2>The Thumb's Interest</h2>
		<p>You may still have connections to the Thumb, but you operate independently. Your primary goal is to <span class="good">train your apprentice</span> and pursue your own interests in the City.</p>
	</div>
	"}

/datum/action/innate/view_role_rules/thumb_apprentice
	name = "View Thumb Rules"
	desc = "Review the Thumb Apprentice's trusted role rulings."
	rules_title = "Thumb Apprentice - Trusted Role Rulings"
	accent_color = "#8b0000"
	window_name = "thumb_apprentice_rules"
	window_size = "600x800"

/datum/action/innate/view_role_rules/thumb_apprentice/get_rules_content()
	return {"
	<div class="section">
		<h2>Your Purpose</h2>
		<p>You have been recruited by a former Sottocapo of the Thumb to learn the <b>Palermitan Style</b> &mdash; a sword technique renowned for relentlessly focusing on a single prey during a hunt, concluded with a Coup de Gr&acirc;ce.</p>
	</div>

	<div class="section">
		<h2>Progression Through Duels</h2>
		<p>Your primary means of growing stronger is through <b>dueling other players</b>. Use the 'Challenge to Duel' action to challenge someone.</p>
		<ul>
			<li>Duels create an arena ring. Stepping outside the ring or entering critical condition means you lose.</li>
			<li><span class="good">Winning</span> grants more attributes and EXP. <span class="warning">Losing</span> still grants some &mdash; you always learn.</li>
			<li>Fighting <span class="good">stronger opponents</span> grants more rewards than fighting weaker ones.</li>
			<li>Your gear <span class="good">evolves automatically</span> as your attributes grow (4 tiers).</li>
			<li>At tier 2+, your weapons gain a <span class="good">dual-wield follow-up</span> mechanic.</li>
		</ul>
	</div>

	<div class="section">
		<h2>The Palermitan Skill Tree</h2>
		<p>Open your <b>Palermitan Skill Tree</b> to spend skill points earned from duels. There are 4 schools:</p>
		<ul>
			<li><b>Terremoto</b> &mdash; Tremor focus. Destabilize your prey and trigger devastating Tremor Bursts.</li>
			<li><b>Incendio</b> &mdash; Overheat focus. Burn them down with escalating fire damage.</li>
			<li><b>Eleganza</b> &mdash; Poise and Concentration. Build crit chance and sustain your momentum.</li>
			<li><b>Fondamenti</b> &mdash; General combat fundamentals. Offense and defense for any build.</li>
		</ul>
		<p>You can invest in <span class="warning">2 schools maximum</span>. Choose wisely.</p>
	</div>

	<div class="section">
		<h2>Lessons Learned</h2>
		<p>Dueling different types of opponents teaches you unique passive abilities. Check the <b>Lessons Learned</b> tab in your skill tree to see what you've unlocked and what's available.</p>
		<ul>
			<li>Each role has its own passive with 3 tiers (unlocked at 1, 3, and 5 duels).</li>
			<li>Passives are permanent and themed around the opponent's fighting style.</li>
		</ul>
	</div>

	<div class="section">
		<h2>The Duel Escalates</h2>
		<p>Your core mechanic: every hit inflicts <b>'The Duel Escalates'</b> on your target. The more stacks they have, the stronger you become against them &mdash; more damage, less damage taken, and your skills scale with the stacks.</p>
	</div>

	<div class="section">
		<h2>Your Mentor</h2>
		<p>The Sottocapo who recruited you is your mentor. They can help you in several ways:</p>
		<ul>
			<li><b>Sharing drinks:</b> Offering your mentor an alcoholic drink grants you EXP. Show respect to your teacher.</li>
			<li><b>Sharing a meal:</b> Offering your mentor food also grants EXP. Service to your superiors is expected.</li>
			<li><b>Showing respect:</b> Bowing or saluting near higher-ranked players or your mentor grants EXP. The Thumb values politeness above all.</li>
			<li><b>Daily training:</b> When your mentor strikes you with a weapon, you gain EXP from the discipline. Pain is the best teacher.</li>
			<li><b>Post-duel correction:</b> After you lose a duel, your mentor can punch you with bare fists to grant bonus attributes. It hurts, but you learn.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Conduct and Escalation</h2>
		<ul>
			<li>Duels must be <span class="good">consensual</span> &mdash; the other player must accept your challenge.</li>
			<li>Your mentor may <span class="good">intimidate and rough up</span> those who try to avoid dueling you &mdash; that is the Thumb way. Let your mentor handle the persuasion.</li>
			<li>You yourself should <span class="warning">not attack people who decline</span>. You are an apprentice &mdash; you have no authority to punish others. That is your mentor's role.</li>
			<li><span class="warning">Avoid killing other players without a reason.</span> Duels are non-lethal by design (healing on duel end).</li>
			<li>Follow your mentor's lead. Act in the Thumb's interest.</li>
			<li>Your duels are meant to be a <span class="good">spectacle</span> &mdash; the Palermitan Style is put on display for all to behold.</li>
		</ul>
	</div>
	"}

////////////////////////////////////////////////////////////
// DEBUG TRANSFORM ITEM
// Use in hand to become the Ex Thumb Sottocapo with full loadout.

/obj/item/thumb_nursefather_debug
	name = "thumbfather signet ring"
	desc = "A debug item. Use in hand to transform into the Ex Thumb Sottocapo with full gear and abilities."
	icon = 'icons/obj/device.dmi'
	icon_state = "hypertool"
	w_class = WEIGHT_CLASS_TINY

/obj/item/thumb_nursefather_debug/attack_self(mob/living/user)
	. = ..()
	if(!ishuman(user))
		to_chat(user, span_warning("Only humans can use this."))
		return
	var/mob/living/carbon/human/H = user

	to_chat(H, span_boldnotice("Transforming into Ex Thumb Sottocapo..."))

	// Drop all held and worn items
	H.drop_all_held_items()
	for(var/obj/item/I in H.get_equipped_items())
		H.dropItemToGround(I, TRUE)

	// Set attributes
	H.set_attribute_limit(200)
	for(var/attr_name in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE, TEMPERANCE_ATTRIBUTE, JUSTICE_ATTRIBUTE))
		var/datum/attribute/A = H.attributes[attr_name]
		if(A)
			if(attr_name in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE))
				A.level = 150
			else
				A.level = 100
			A.on_update(H)

	// Set role
	if(H.mind)
		H.mind.assigned_role = "Ex Thumb Sottocapo"

	// Add traits
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)

	// Insert Eye of Odin
	var/obj/item/organ/eyes/robotic/odin_eye/eye = new()
	eye.Insert(H)

	// Add nursefather passive
	H.AddComponent(/datum/component/nursefather_passive)
	H.AddComponent(/datum/component/nursefather_music, NURSEFATHER_FINGER_THUMB)

	// Equip outfit basics
	var/datum/outfit/job/ex_thumb_sottocapo/outfit = new()
	outfit.equip(H)

	// Spawn armor into hand
	var/obj/item/clothing/suit/armor/ego_gear/city/thumb_spider/ex_sottocapo/armor = new(H)
	H.put_in_hands(armor)

	// Spawn weapons and ammo into backpack
	var/obj/item/storage/backpack/BP = locate() in H.contents
	if(BP)
		new /obj/item/ego_weapon/city/thumbfather_rapier(BP)
		new /obj/item/ego_weapon/city/thumbfather_katana(BP)
		new /obj/item/storage/box/thumb_east_ammo/acceleration(BP)
		new /obj/item/storage/box/thumb_east_ammo/acceleration(BP)

	// Grant rules action
	var/datum/action/innate/view_role_rules/thumb_nursefather/rules = new
	rules.Grant(H)

	to_chat(H, span_boldnotice("You are now the Ex Thumb Sottocapo. Check your backpack for weapons and ammo."))

	// Consume the debug item
	qdel(src)

////////////////////////////////////////////////////////////
// GHOST POLL SPAWN ITEM
// Use in hand to poll trusted ghosts, then spawn the selected one as Ex Thumb Sottocapo.

/obj/item/thumb_nursefather_ghost_spawn
	name = "thumbfather's calling card"
	desc = "A debug item. Use in hand to poll trusted ghosts for an Ex Thumb Sottocapo player."
	icon = 'icons/obj/radio.dmi'
	icon_state = "radio"
	w_class = WEIGHT_CLASS_TINY
	/// Whether a poll is currently active
	var/polling = FALSE

/obj/item/thumb_nursefather_ghost_spawn/attack_self(mob/living/user)
	if(!ishuman(user))
		to_chat(user, span_warning("Only humans can use this."))
		return
	if(polling)
		to_chat(user, span_warning("A poll is already in progress!"))
		return

	polling = TRUE
	to_chat(user, span_notice("Polling ghosts for an Ex Thumb Sottocapo candidate..."))

	var/turf/spawn_loc = get_turf(src)

	var/list/candidates = pollGhostCandidates("Do you wish to become the Ex Thumb Sottocapo?", ROLE_TRAITOR, poll_time = 300)

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

	// Set attributes
	H.set_attribute_limit(200)
	for(var/attr_name in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE, TEMPERANCE_ATTRIBUTE, JUSTICE_ATTRIBUTE))
		var/datum/attribute/A = H.attributes[attr_name]
		if(A)
			if(attr_name in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE))
				A.level = 150
			else
				A.level = 100
			A.on_update(H)

	// Set role
	if(H.mind)
		H.mind.assigned_role = "Ex Thumb Sottocapo"

	// Add traits
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)

	// Insert Eye of Odin
	var/obj/item/organ/eyes/robotic/odin_eye/eye = new()
	eye.Insert(H)

	// Add nursefather components
	H.AddComponent(/datum/component/nursefather_passive)
	H.AddComponent(/datum/component/nursefather_music, NURSEFATHER_FINGER_THUMB)

	// Equip outfit
	var/datum/outfit/job/ex_thumb_sottocapo/outfit = new()
	outfit.equip(H)

	// Spawn armor into hand
	var/obj/item/clothing/suit/armor/ego_gear/city/thumb_spider/ex_sottocapo/armor = new(H)
	H.put_in_hands(armor)

	// Spawn weapons and ammo into backpack
	var/obj/item/storage/backpack/BP = locate() in H.contents
	if(BP)
		new /obj/item/ego_weapon/city/thumbfather_rapier(BP)
		new /obj/item/ego_weapon/city/thumbfather_katana(BP)
		new /obj/item/storage/box/thumb_east_ammo/acceleration(BP)
		new /obj/item/storage/box/thumb_east_ammo/acceleration(BP)

	// Grant rules action
	var/datum/action/innate/view_role_rules/thumb_nursefather/rules = new
	rules.Grant(H)

	to_chat(H, span_boldnotice("You are the Ex Thumb Sottocapo. Check your backpack for weapons and ammo."))

	// Consume the item
	qdel(src)
