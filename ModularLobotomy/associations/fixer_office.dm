// Global list for all offices
GLOBAL_LIST_EMPTY(all_fixer_offices)

// Fixer Office Datum
/datum/fixer_office
	var/name = "Unnamed Office"
	var/mob/living/carbon/human/director
	var/list/members = list()
	var/max_members = 8
	var/office_color = "#000000"
	var/creation_time
	var/office_budget = 0
	var/list/member_actions = list() // Track action datums for cleanup

/datum/fixer_office/New()
	. = ..()
	creation_time = world.time

/datum/fixer_office/Destroy()
	// Remove all members
	for(var/mob/living/carbon/human/H in members)
		remove_member(H)
	
	// Invalidate all badges linked to this office
	for(var/obj/item/clothing/accessory/office_badge/badge in world)
		if(badge.linked_office == src)
			badge.linked_office = null
			badge.name = "defunct [name] badge"
			badge.desc = "A badge from the now-defunct [name]. It no longer has any power."
			badge.update_icon()
	
	// Clean up radio if implemented
	
	// Remove from global list
	GLOB.all_fixer_offices -= src
	return ..()

/datum/fixer_office/proc/add_member(mob/living/carbon/human/H)
	if(H in members)
		return
	if(members.len >= max_members)
		return FALSE
		
	members += H
	
	// Grant office management action
	var/datum/action/office_menu/OM = new(src)
	OM.Grant(H)
	member_actions[H] = OM

	// Give basic headset
	var/obj/item/radio/headset/headset = new(get_turf(H))
	H.put_in_hands(headset)

	// Give office badge
	var/obj/item/clothing/accessory/office_badge/badge = new(get_turf(H))
	badge.linked_office = src
	badge.name = "[name] member badge"
	badge.update_icon()
	H.put_in_hands(badge)

	to_chat(H, span_nicegreen("You've joined [name]!"))
	to_chat(H, span_notice("Use your Office Menu action to manage office settings."))
		
	return TRUE

/datum/fixer_office/proc/remove_member(mob/living/carbon/human/H)
	if(!(H in members))
		return
		
	members -= H
	
	// Remove office management action
	if(H in member_actions)
		var/datum/action/office_menu/OM = member_actions[H]
		OM.Remove(H)
		qdel(OM)
		member_actions -= H
	
	to_chat(H, span_warning("You've left [name]."))
	
	// Badge removal handled separately if needed
	
	// If director leaves, disband office
	if(H == director)
		disband()
		return

// Removed HUD functionality - using action buttons instead

/datum/fixer_office/proc/disband()
	// Announce disbanding
	minor_announce("[name] has been disbanded.", "Office Registration")
	
	// Remove all members first
	var/list/members_copy = members.Copy()
	for(var/mob/living/carbon/human/H in members_copy)
		remove_member(H)
		
	// Clean up and destroy
	qdel(src)

/datum/fixer_office/proc/get_member_count()
	return members.len

/datum/fixer_office/proc/is_member(mob/living/carbon/human/H)
	return (H in members)

/datum/fixer_office/proc/is_director(mob/living/carbon/human/H)
	return (H == director)

/datum/fixer_office/proc/transfer_leadership(mob/living/carbon/human/new_director)
	if(!(new_director in members))
		return FALSE

	var/old_director = director
	director = new_director

	to_chat(old_director, span_warning("You have transferred leadership of [name] to [new_director.real_name]."))
	to_chat(new_director, span_nicegreen("You are now the representative of [name]!"))

	// Give new director some recruitment badges
	for(var/i in 1 to 3)
		var/obj/item/clothing/accessory/office_badge/badge = new(get_turf(new_director))
		badge.linked_office = src
		badge.name = "[name] recruitment badge"
		badge.update_icon()

	return TRUE

/// Replaces an old body with a new body in the office (used for BPU revival)
/// Does NOT trigger disband even if the old body was the director
/datum/fixer_office/proc/replace_member(mob/living/carbon/human/old_body, mob/living/carbon/human/new_body, was_director = FALSE)
	if(!new_body)
		return FALSE

	// Remove old body from members without triggering disband
	if(old_body && (old_body in members))
		members -= old_body
		if(member_actions[old_body])
			var/datum/action/office_menu/OM = member_actions[old_body]
			OM.Remove(old_body)
			qdel(OM)
			member_actions -= old_body

	// Add new body as member
	add_member(new_body)

	// Restore director status if they were the director
	if(was_director)
		director = new_body

	return TRUE

// Office Management Action
/datum/action/office_menu
	name = "Office Menu"
	desc = "Open your office management menu."
	button_icon_state = "template"
	button_icon = 'icons/mob/actions/actions_items.dmi'
	var/datum/fixer_office/linked_office

/datum/action/office_menu/New(datum/fixer_office/office)
	. = ..()
	linked_office = office
	name = "[office.name] Menu"

/datum/action/office_menu/Trigger()
	if(!owner || !linked_office)
		return
	var/datum/office_management/OM = new
	OM.selected_office = linked_office
	OM.ui_interact(owner)

/datum/action/office_menu/IsAvailable()
	if(!owner || !linked_office)
		return FALSE
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/H = owner
	return (H in linked_office.members)