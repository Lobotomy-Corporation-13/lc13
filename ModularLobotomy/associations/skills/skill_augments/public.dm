//--------------------------------------
// Public Body Modification Importer
//--------------------------------------

/obj/machinery/body_modification_fabricator/public
	name = "Body Modification Importer"
	desc = "A publicly accessible body modification importer. Accepts tickets, charges Ahn, and delivers via express pod after processing."
	icon = 'icons/obj/machines/telecomms.dmi'
	icon_state = "processor"
	allowed_roles = list()

	// Import delay (1-2 minutes)
	var/import_delay_min = 1 MINUTES
	var/import_delay_max = 2 MINUTES

	// Track pending orders (multiple orders can be processed simultaneously)
	var/list/pending_orders = list()
	var/max_concurrent_orders = 5  // Maximum simultaneous orders

/obj/machinery/body_modification_fabricator/public/attack_hand(mob/user)
	to_chat(user, span_notice("This machine only accepts body modification tickets. Insert a ticket to process your order. Orders are delivered via express pod after 1-2 minutes. Current queue: [length(pending_orders)]/[max_concurrent_orders]"))
	return

/obj/machinery/body_modification_fabricator/public/ui_interact(mob/user)
	to_chat(user, span_notice("This machine only accepts body modification tickets. Insert a ticket to process your order."))
	return

/obj/machinery/body_modification_fabricator/public/attackby(obj/item/I, mob/user)
	// Check if we've reached max concurrent orders
	if(length(pending_orders) >= max_concurrent_orders)
		to_chat(user, span_warning("[src] is at maximum capacity! Please wait for current orders to complete."))
		return TRUE

	// Handle body modification ticket processing (no role restrictions for public machine)
	if(istype(I, /obj/item/body_modification_ticket))
		var/obj/item/body_modification_ticket/ticket = I

		// Check if ticket is valid
		if(!ticket.template_name || !length(ticket.selected_skills))
			to_chat(user, span_warning("This ticket appears to be invalid or incomplete!"))
			return TRUE

		// Calculate Ahn cost (material_cost * 20)
		var/ahn_cost = ticket.material_cost * 20

		// Check if user can pay
		if(!can_afford_ahn(user, ahn_cost))
			to_chat(user, span_warning("Insufficient funds! Cost: [ahn_cost] Ahn. Check your ID card balance."))
			return TRUE

		// Deduct the cost
		if(!deduct_ahn_cost(user, ahn_cost))
			to_chat(user, span_warning("Payment failed! Check your ID card and account balance."))
			return TRUE

		// Process the order with delay
		process_import_order(ticket, user)
		return TRUE

	// Reject material insertion
	if(istype(I, /obj/item/tresmetal))
		to_chat(user, span_notice("This importer does not accept materials. It operates on Ahn payments only."))
		return TRUE

	return ..()

/obj/machinery/body_modification_fabricator/public/proc/process_import_order(obj/item/body_modification_ticket/ticket, mob/user)
	// Set up the design from the ticket
	current_design = new /datum/body_modification_design()
	current_design.rank = ticket.rank
	current_design.max_slots = ticket.max_slots
	current_design.max_charge = ticket.max_charge
	current_design.selected_skills = ticket.selected_skills.Copy()
	current_design.total_slot_cost = ticket.total_slot_cost
	current_design.material_cost = ticket.material_cost
	current_design.name = ticket.template_name

	// Generate unique order ID for tracking
	var/order_id = "order_[world.time]_[rand(1000, 9999)]"

	// Store order information
	var/list/order_data = list(
		"order_id" = order_id,
		"design" = current_design,
		"user_ref" = WEAKREF(user),
		"is_injectable" = ticket.is_injectable,
		"order_time" = world.time,
		"orderer_name" = ticket.orderer_name
	)

	// Calculate random delay
	var/delivery_delay = rand(import_delay_min, import_delay_max)

	// Add to pending orders list with unique ID
	pending_orders[order_id] = order_data

	// Consume the ticket
	qdel(ticket)

	// Feedback to user
	to_chat(user, span_notice("[src] beeps, \"Order confirmed! Your body modification will arrive via express pod in approximately [round(delivery_delay / 600)] minutes. Queue position: [length(pending_orders)]/[max_concurrent_orders]\""))
	visible_message(span_notice("[src] whirs to life, processing another import order..."))
	playsound(src, 'sound/machines/ping.ogg', 50, FALSE)

	// Schedule the delivery
	addtimer(CALLBACK(src, PROC_REF(deliver_import), order_data), delivery_delay)

/obj/machinery/body_modification_fabricator/public/proc/deliver_import(list/order_data)
	// Get the design and user info
	var/datum/body_modification_design/design = order_data["design"]
	var/datum/weakref/user_ref = order_data["user_ref"]
	var/is_injectable = order_data["is_injectable"]
	var/orderer_name = order_data["orderer_name"]

	// Create the body modification
	var/obj/item/created_item

	if(is_injectable)
		// Create injectable version
		var/obj/item/body_modification_injectable/injectable = new /obj/item/body_modification_injectable(src)

		// Configure the injectable
		injectable.rank = design.rank
		injectable.max_slots = design.max_slots
		injectable.max_charge = design.max_charge
		injectable.current_charge = injectable.max_charge
		injectable.attached_skills = design.selected_skills.Copy()
		injectable.name = "injectable [design.name]"
		injectable.desc = "An injectable body modification containing programmed skills. Rank [design.rank] template with [length(design.selected_skills)] skills installed."

		// Store skill charge costs
		var/obj/machinery/body_modification_fabricator/fab = locate() in world
		if(fab)
			for(var/skill_type in injectable.attached_skills)
				var/list/skill_info = fab.skill_data[skill_type]
				if(skill_info)
					injectable.skill_charge_costs[skill_type] = skill_info["charge_cost"]

		created_item = injectable

	else
		// Create regular implantable version
		var/obj/item/organ/cyberimp/chest/body_modification/template_organ = new /obj/item/organ/cyberimp/chest/body_modification(src)

		// Configure the organ
		template_organ.rank = design.rank
		template_organ.max_slots = design.max_slots
		template_organ.max_charge = design.max_charge
		template_organ.current_charge = template_organ.max_charge
		template_organ.attached_skills = design.selected_skills.Copy()
		template_organ.name = design.name

		// Store skill charge costs
		var/obj/machinery/body_modification_fabricator/fab = locate() in world
		if(fab)
			for(var/skill_type in template_organ.attached_skills)
				var/list/skill_info = fab.skill_data[skill_type]
				if(skill_info)
					template_organ.skill_charge_costs[skill_type] = skill_info["charge_cost"]

		created_item = template_organ

	// Find delivery location - try to find the user, otherwise deliver to importer location
	var/turf/delivery_turf
	var/mob/recipient = user_ref?.resolve()

	if(recipient && !QDELETED(recipient))
		delivery_turf = get_turf(recipient)
		to_chat(recipient, span_notice("Your body modification order is arriving via express pod!"))
	else
		// User is gone, deliver to the importer's location
		delivery_turf = get_turf(src)

	// Create the delivery pod
	if(delivery_turf)
		var/obj/structure/closet/supplypod/extractionpod/pod = new()
		pod.explosionSize = list(0,0,0,0)
		pod.name = "body modification delivery pod"

		// Add the created item to the pod
		created_item.forceMove(pod)

		// Add a delivery note
		var/obj/item/paper/delivery_note = new(pod)
		delivery_note.name = "Body Modification Import Receipt"
		delivery_note.info = "Order placed by: [orderer_name]<br>Template: [design.name]<br>Rank: [design.rank]<br>Skills installed: [length(design.selected_skills)]<br><br>Thank you for using the Body Modification Import Service!"

		// Create the landing zone and deliver
		new /obj/effect/pod_landingzone(delivery_turf, pod)

		visible_message(span_notice("[src] chimes, \"Import complete! Delivery dispatched.\""))
		playsound(src, 'sound/machines/ping.ogg', 50, FALSE)

	// Remove from pending orders using order ID
	var/order_id = order_data["order_id"]
	pending_orders -= order_id
	current_design = null

/obj/machinery/body_modification_fabricator/public/proc/can_afford_ahn(mob/user, amount)
	var/obj/item/card/id/C
	if(isliving(user))
		var/mob/living/L = user
		C = L.get_idcard(TRUE)
		if(!C)
			return FALSE
		else if(!C.registered_account)
			return FALSE

		var/datum/bank_account/account = C.registered_account
		return (account.account_balance >= amount)
	return FALSE

/obj/machinery/body_modification_fabricator/public/proc/deduct_ahn_cost(mob/user, amount)
	var/obj/item/card/id/C
	if(isliving(user))
		var/mob/living/L = user
		C = L.get_idcard(TRUE)
		if(!C)
			return FALSE
		else if(!C.registered_account)
			return FALSE

		var/datum/bank_account/account = C.registered_account
		if(amount && !account.adjust_money(-amount))
			L.playsound_local(get_turf(src), 'sound/machines/buzz-two.ogg', 25, 3, 3)
			return FALSE
		else
			L.playsound_local(get_turf(src), 'sound/effects/cashregister.ogg', 25, 3, 3)
			return TRUE
	return FALSE

// Override the UI data to show that materials are not needed
/obj/machinery/body_modification_fabricator/public/ui_data(mob/user)
	var/list/data = ..()
	// Override material display to show this is Ahn-based
	data["total_materials"] = "Ahn-based payments"
	return data
