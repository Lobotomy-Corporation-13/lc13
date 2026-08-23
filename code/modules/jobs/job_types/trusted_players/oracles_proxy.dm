//The Oracle's Proxy
/datum/job/oracles_proxy
	title = "Oracle Proxy"
	outfit = /datum/outfit/job/oracles_proxy
	department_head = list("the will of the prescript")
	faction = "Station"
	supervisors = "the will of the prescript"
	selection_color = "#cccccc"
	total_positions = 0
	spawn_positions = 0
	display_order = JOB_DISPLAY_ORDER_SYNDICATEHEAD
	trusted_only = TRUE
	access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	minimal_access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	departments = DEPARTMENT_COMMAND | DEPARTMENT_CITY_ANTAGONIST
	paycheck = 1000
	maptype = list("city", "fixers")
	job_important = "You are a wandering proxy of the Index, carrying out prescripts delivered to you by the Oracle. \
		You are not inherently hostile, but you must follow the prescripts you receive. \
		Use your index pager to receive and view your prescripts. \
		You have buffed stats. You automatically dodge the first attack every 30 seconds, and have a 50% chance to dodge attacks when not holding a weapon. \
		However, all damage you take also inflicts 5% unhealable damage."
	job_notice = "Avoid killing other players without a reason. Killing a player for stopping your prescripts is a valid reason."

	roundstart_attributes = list(
		FORTITUDE_ATTRIBUTE = 300,
		PRUDENCE_ATTRIBUTE = 300,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100
	)

/datum/job/oracles_proxy/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	H.AddComponent(/datum/component/nursefather_passive)
	H.AddComponent(/datum/component/nursefather_music, NURSEFATHER_FINGER_INDEX)
	var/datum/action/innate/view_role_rules/index_oracle/rules_action = new
	rules_action.Grant(H)
	return ..()

/datum/outfit/job/oracles_proxy
	name = "Oracle Proxy"
	jobtype = /datum/job/oracles_proxy

	id = /obj/item/card/id/silver/plastic
	belt = /obj/item/pda/security
	uniform = /obj/item/clothing/under/suit/charcoal
	shoes = /obj/item/clothing/shoes/laceup
	l_hand = /obj/item/ego_weapon/index_vial
	r_hand = /obj/item/clothing/suit/armor/ego_gear/city/index_proxy_wanderer
	accessory = /obj/item/clothing/accessory/index_pager
	l_pocket = /obj/item/apprentice_recruitment/index_proxy

// Index Proxy Apprentice Recruitment Scroll
/obj/item/apprentice_recruitment/index_proxy
	name = "proxy apprenticeship scroll"
	desc = "A scroll that allows you to recruit an apprentice to follow the prescripts."

/obj/item/apprentice_recruitment/index_proxy/get_offer_text(mob/living/user)
	return "[user] is offering to make you their Index Proxy Apprentice. Do you accept?"

/obj/item/apprentice_recruitment/index_proxy/get_offer_title()
	return "Apprenticeship Offer"

/obj/item/apprentice_recruitment/index_proxy/recruit_apprentice(mob/living/carbon/human/H, mob/living/user)
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

	// Give armor
	var/obj/item/clothing/suit/armor/ego_gear/index_proxy/apprentice/armor = new(H.loc)
	H.put_in_hands(armor)

	// Update ID card
	update_id_card(H, "Index Proxy Apprentice")

	// Update mind role
	if(H.mind)
		H.mind.assigned_role = "Index Proxy Apprentice"

	// Give the index pager
	var/obj/item/clothing/accessory/index_pager/pager = new(H.loc)
	H.put_in_hands(pager)

	// Add the oracle proxy passive component and traits
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, "index_apprentice")
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, "index_apprentice")
	H.AddComponent(/datum/component/nursefather_passive)

	// Grant rules action
	var/datum/action/innate/view_role_rules/index_apprentice/rules_action = new
	rules_action.Grant(H)

	// Visual/audio feedback
	to_chat(user, span_notice("You have recruited [H] as your apprentice."))
	playsound(get_turf(H), 'sound/items/index_beeper_prescript.ogg', 50, 0, 4)

	// Show role explanation to the new apprentice
	to_chat(H, span_userdanger("You have become an Index Proxy Apprentice!"))
	to_chat(H, span_boldnotice("You are now an apprentice of [user], a proxy of the Index. \
		You must follow the prescripts delivered to you and assist your mentor in carrying them out. \
		Use your index pager to receive and view your prescripts."))
	to_chat(H, span_boldnotice("You have buffed stats. You automatically dodge the first attack every 30 seconds, \
		and have a 50% chance to dodge attacks when not holding a weapon. \
		However, all damage you take also inflicts 5% unhealable damage."))
	to_chat(H, span_boldwarning("Avoid killing other players without a reason. \
		Killing a player for stopping your prescripts is a valid reason."))

// ================== INDEX ORACLE PROXY RULES ==================

/datum/action/innate/view_role_rules/index_oracle
	name = "View Index Rules"
	desc = "Review the Index Oracle's trusted role rulings."
	rules_title = "Index Oracle - Trusted Role Rulings"
	accent_color = "#4a7c8f"
	window_name = "index_oracle_rules"
	window_size = "600x700"

/datum/action/innate/view_role_rules/index_oracle/get_rules_content()
	return {"
	<div class="section">
		<h2>Your Purpose</h2>
		<p>You are a wandering proxy of the Index, carrying out prescripts delivered to you by the Oracle. You are <span class="warning">not inherently hostile</span>, but you must follow the prescripts you receive. You exist to enact the Oracle's will -- nothing more, nothing less.</p>
	</div>

	<div class="section">
		<h2>The Prescripts</h2>
		<p>Your <b>Index Pager</b> will deliver prescripts to you throughout the round. These are your primary objectives and the core of your roleplay.</p>
		<ul>
			<li>You <span class="good">must</span> follow the prescripts you receive. They are the will of the Oracle.</li>
			<li>You are still beholden to <span class="highlight">server rules</span> when performing prescripts -- this includes escalation.</li>
			<li>If you feel like you're getting too many <span class="highlight">"KILL X IF THEY DO NOT Y"</span> prescripts, then AHelp.</li>
			<li>Use the prescripts as RP hooks -- announce ultimatums, give warnings, negotiate. You are a messenger first, a fighter second.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Recruiting an Apprentice</h2>
		<p>You have a <b>Proxy Apprenticeship Scroll</b> that lets you recruit one player as your apprentice. This is a <span class="good">roleplay opportunity</span> -- choose someone who will engage with the role, not just someone you want to buff.</p>
		<ul>
			<li>Your apprentice receives their own pager and follows the same prescripts.</li>
			<li>They are your responsibility -- guide them and work together.</li>
			<li>The scroll can only be used <span class="warning">once</span>. Choose wisely.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Clone Decay</h2>
		<p>Every wound you take leaves a permanent mark -- <span class="highlight">5% of all damage becomes unhealable</span>. This is not just a mechanic, it's a <span class="warning">roleplay consideration</span>.</p>
		<ul>
			<li>You are powerful but <span class="highlight">not invincible</span>. Every fight chips away at you permanently.</li>
			<li>Pick your battles wisely. Prolonged combat will leave you a shell of your former self.</li>
			<li>Use your evasion passives -- you dodge automatically and more frequently when unarmed. Sometimes discretion is the better part of valor.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Conduct and Escalation</h2>
		<ul>
			<li><span class="warning">Avoid killing other players without a reason.</span> Killing a player for stopping your prescripts is a valid reason.</li>
			<li>You may enter the backstreets with sufficient reasoning but <span class="warning">not</span> for the express purpose of looting or hunting fixers.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Interacting with the Index Syndicate</h2>
		<p>The Index Syndicate being active in the area is not of your concern -- you work independently of them. You can choose to help them if you so desire, but it should not be your priority. After all, whatever happens to them is likely the Prescript's Will.</p>
	</div>
	"}

// ================== INDEX PROXY APPRENTICE RULES ==================

/datum/action/innate/view_role_rules/index_apprentice
	name = "View Index Rules"
	desc = "Review the Index Proxy Apprentice's trusted role rulings."
	rules_title = "Index Proxy Apprentice - Trusted Role Rulings"
	accent_color = "#4a7c8f"
	window_name = "index_apprentice_rules"
	window_size = "600x700"

/datum/action/innate/view_role_rules/index_apprentice/get_rules_content()
	return {"
	<div class="section">
		<h2>Your Purpose</h2>
		<p>You have been recruited by an Index Proxy to serve as their apprentice. You must follow the prescripts you receive and <span class="good">assist your mentor</span> in carrying them out. Your loyalty is to the Oracle's will, enacted through your mentor.</p>
	</div>

	<div class="section">
		<h2>The Prescripts</h2>
		<p>Your <b>Index Pager</b> will deliver the same prescripts as your mentor. You share their mission.</p>
		<ul>
			<li>You <span class="good">must</span> follow the prescripts you receive and support your mentor in completing them.</li>
			<li>You are still beholden to <span class="highlight">server rules</span> when performing prescripts -- this includes escalation.</li>
			<li>If you feel like you're getting too many <span class="highlight">"KILL X IF THEY DO NOT Y"</span> prescripts, then AHelp.</li>
			<li>Coordinate with your mentor -- you are their partner, not a solo agent.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Your Mentor</h2>
		<p>The proxy who recruited you is your mentor and your primary point of contact with the Index.</p>
		<ul>
			<li>Work <span class="good">alongside</span> your mentor. Follow their lead on how to approach prescripts.</li>
			<li>If your mentor dies, you are still bound to complete any active prescripts.</li>
			<li>You are not your mentor's servant -- you are their <span class="good">partner in the Oracle's work</span>.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Clone Decay</h2>
		<p>Like your mentor, every wound you take leaves a permanent mark -- <span class="highlight">5% of all damage becomes unhealable</span>.</p>
		<ul>
			<li>You are strong but <span class="highlight">not invincible</span>. Every fight chips away at you permanently.</li>
			<li>Pick your battles wisely. Let your mentor take the lead in dangerous situations.</li>
			<li>You dodge automatically and more frequently when unarmed -- sometimes retreating is the right call.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Chains and Procuration</h2>
		<p>Your armor grants you the ability to summon chains as a weapon. As you prove yourself by completing prescripts, your chains can <span class="good">transform into something greater</span>.</p>
		<ul>
			<li>Completing prescripts progresses you toward <span class="good">Effloresced E.G.O :: Procuration</span>, a stronger weapon.</li>
			<li>If you are gravely wounded while your chains are active, desperation may trigger the transformation early.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Conduct and Escalation</h2>
		<ul>
			<li><span class="warning">Avoid killing other players without a reason.</span> Killing a player for stopping your prescripts is a valid reason.</li>
			<li>You may enter the backstreets with sufficient reasoning but <span class="warning">not</span> for the express purpose of looting or hunting fixers.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Interacting with the Index Syndicate</h2>
		<p>The Index Syndicate being active in the area is not of your concern -- you work independently of them. You can choose to help them if you so desire, but it should not be your priority. After all, whatever happens to them is likely the Prescript's Will.</p>
	</div>
	"}

////////////////////////////////////////////////////////////
// DEBUG TRANSFORM ITEM
// Use in hand to become the Oracle Proxy with full loadout.

/obj/item/oracle_proxy_debug
	name = "oracle's seal"
	desc = "A debug item. Use in hand to transform into the Oracle Proxy with full gear and abilities."
	icon = 'icons/obj/device.dmi'
	icon_state = "hypertool"
	w_class = WEIGHT_CLASS_TINY

/obj/item/oracle_proxy_debug/attack_self(mob/living/user)
	. = ..()
	if(!ishuman(user))
		to_chat(user, span_warning("Only humans can use this."))
		return
	var/mob/living/carbon/human/H = user

	to_chat(H, span_boldnotice("Transforming into Oracle Proxy..."))

	// Drop all held and worn items
	H.drop_all_held_items()
	for(var/obj/item/I in H.get_equipped_items())
		H.dropItemToGround(I, TRUE)

	// Set attributes
	H.set_attribute_limit(300)
	for(var/attr_name in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE, TEMPERANCE_ATTRIBUTE, JUSTICE_ATTRIBUTE))
		var/datum/attribute/A = H.attributes[attr_name]
		if(A)
			if(attr_name in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE))
				A.level = 300
			else
				A.level = 100
			A.on_update(H)

	// Set role
	if(H.mind)
		H.mind.assigned_role = "Oracle Proxy"

	// Add traits
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)

	// Add nursefather passive
	H.AddComponent(/datum/component/nursefather_passive)
	H.AddComponent(/datum/component/nursefather_music, NURSEFATHER_FINGER_INDEX)

	// Equip outfit (includes Caduceus in l_hand, armor in r_hand, pager as accessory, scroll in pocket)
	var/datum/outfit/job/oracles_proxy/outfit = new()
	outfit.equip(H)

	// Grant rules action
	var/datum/action/innate/view_role_rules/index_oracle/rules_action = new
	rules_action.Grant(H)

	to_chat(H, span_boldnotice("You are now the Oracle Proxy. Caduceus and armor are in your hands, pager is on your suit."))

	// Consume the debug item
	qdel(src)

////////////////////////////////////////////////////////////
// GHOST POLL SPAWN ITEM
// Use in hand to poll trusted ghosts, then spawn the selected one as Oracle Proxy.

/obj/item/oracle_proxy_ghost_spawn
	name = "oracle's calling stone"
	desc = "A debug item. Use in hand to poll trusted ghosts for an Oracle Proxy player."
	icon = 'icons/obj/radio.dmi'
	icon_state = "radio"
	w_class = WEIGHT_CLASS_TINY
	/// Whether a poll is currently active
	var/polling = FALSE

/obj/item/oracle_proxy_ghost_spawn/attack_self(mob/living/user)
	if(!ishuman(user))
		to_chat(user, span_warning("Only humans can use this."))
		return
	if(polling)
		to_chat(user, span_warning("A poll is already in progress!"))
		return

	polling = TRUE
	to_chat(user, span_notice("Polling ghosts for an Oracle Proxy candidate..."))

	var/turf/spawn_loc = get_turf(src)

	var/list/candidates = pollGhostCandidates("Do you wish to become the Oracle Proxy?", ROLE_TRAITOR, poll_time = 300)

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
	H.set_attribute_limit(300)
	for(var/attr_name in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE, TEMPERANCE_ATTRIBUTE, JUSTICE_ATTRIBUTE))
		var/datum/attribute/A = H.attributes[attr_name]
		if(A)
			if(attr_name in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE))
				A.level = 300
			else
				A.level = 100
			A.on_update(H)

	// Set role
	if(H.mind)
		H.mind.assigned_role = "Oracle Proxy"

	// Add traits
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)

	// Add nursefather components
	H.AddComponent(/datum/component/nursefather_passive)
	H.AddComponent(/datum/component/nursefather_music, NURSEFATHER_FINGER_INDEX)

	// Equip outfit
	var/datum/outfit/job/oracles_proxy/outfit = new()
	outfit.equip(H)

	// Grant rules action
	var/datum/action/innate/view_role_rules/index_oracle/rules_action = new
	rules_action.Grant(H)

	to_chat(H, span_boldnotice("You are the Oracle Proxy. Caduceus and armor are in your hands, pager is on your suit."))

	// Consume the item
	qdel(src)
