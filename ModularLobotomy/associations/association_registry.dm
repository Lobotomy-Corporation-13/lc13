/// A Director's logbook used to formally register fixers with the association.
/// Hit an association fixer with this to register them, granting them the skill tree and EXP system.
/obj/item/association_registry
	name = "association registry"
	desc = "A Director's logbook used to formally register fixers with the association. Hit a fixer with this to register them."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "premade_clipboard"
	w_class = WEIGHT_CLASS_SMALL
	/// The squad this tool registers members to
	var/datum/association_squad/squad
	/// DEBUG: When TRUE, skips the association job check so anyone can be registered. Set via VV for testing.
	var/debug_skip_job_check = FALSE

/obj/item/association_registry/Destroy()
	squad = null
	return ..()

/obj/item/association_registry/examine(mob/user)
	. = ..()
	if(squad)
		. += span_notice("Registered to: [squad.association_name]")
		. += span_notice("Members registered: [length(squad.members)]")
	else
		. += span_warning("Not linked to any squad.")
	if(debug_skip_job_check)
		. += span_boldwarning("DEBUG MODE: Job check disabled — anyone can be registered.")

/// Director uses the registry on themselves to self-register if not already registered.
/obj/item/association_registry/attack_self(mob/user)
	if(!squad)
		to_chat(user, span_warning("This registry is not linked to any squad."))
		return
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	// Only the Association Section Director can self-register as director
	if(!debug_skip_job_check)
		if(H.mind?.assigned_role != "Association Section Director")
			to_chat(user, span_warning("Only an Association Section Director can register as a Director."))
			return
	if(H.GetComponent(/datum/component/association_exp))
		to_chat(user, span_notice("You are already registered as the Director of [squad.association_name]."))
		return
	squad.register_member(H, "director")
	to_chat(user, span_nicegreen("You have registered yourself as the Director of [squad.association_name]."))
	playsound(get_turf(user), 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)

/obj/item/association_registry/attack(mob/living/target, mob/living/user)
	if(!squad)
		to_chat(user, span_warning("This registry is not linked to any squad."))
		return
	if(!ishuman(target))
		return ..()
	var/mob/living/carbon/human/H = target
	var/target_role = H.mind?.assigned_role
	// Check if they have an association job (skippable via debug var)
	if(!debug_skip_job_check)
		if(target_role != "Association Fixer" && target_role != "Association Veteran")
			to_chat(user, span_warning("[H] is not an association fixer."))
			return
	// Check if already registered
	if(H.GetComponent(/datum/component/association_exp))
		to_chat(user, span_warning("[H] is already registered with a squad."))
		return
	// Determine rank from role title
	var/rank = "associate"
	if(target_role == "Association Veteran")
		rank = "veteran"
	// Register them
	squad.register_member(H, rank)
	squad.spawn_association_items(H, rank)
	to_chat(user, span_nicegreen("You have registered [H] with [squad.association_name]."))
	to_chat(H, span_nicegreen("[user] has registered you with [squad.association_name]. Open your Skill Tree to view your abilities."))
	playsound(get_turf(user), 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
