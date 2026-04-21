/// The Middle - Grudge: a stacking buff on the Middle Nursefather.
/// Gained by taking damage and punching targets.
/// Consumed by combos for bonus damage and by Grudge Dash.
/datum/status_effect/stacking/middle_grudge
	id = "middle_grudge"
	alert_type = /atom/movable/screen/alert/status_effect/middle_grudge
	stacking_display_name = "middle_grudge"
	max_stacks = 20
	tick_interval = 30 SECONDS
	stack_decay = 0
	consumed_on_threshold = FALSE

/atom/movable/screen/alert/status_effect/middle_grudge
	name = "The Middle - Grudge"
	desc = "Your grudge grows with every blow taken and every punch thrown. Consume it to empower your combos."
	icon = 'icons/obj/spider_house/middle/middle_spider_icon.dmi'
	icon_state = "middle_grudge"

/datum/status_effect/stacking/middle_grudge/add_stacks(stacks_added)
	var/was_max = (stacks >= max_stacks)
	..()
	if(!was_max && stacks >= max_stacks)
		owner.say("That's a summary execution!")
	UpdateGrudgeOutline()

/datum/status_effect/stacking/middle_grudge/on_remove()
	owner.remove_filter("middle_grudge_outline")
	..()

/// Updates the purple outline based on current stacks. Appears at 10+, grows with stacks.
/datum/status_effect/stacking/middle_grudge/proc/UpdateGrudgeOutline()
	if(stacks < 10)
		owner.remove_filter("middle_grudge_outline")
		return
	var/outline_size = 1 + round((stacks - 10) * 0.2)
	var/alpha_hex = num2text(min(128 + (stacks - 10) * 12, 255), 1, 16)
	if(length(alpha_hex) < 2)
		alpha_hex = "0[alpha_hex]"
	var/outline_color = "#9932CC[alpha_hex]"
	var/current_filter = owner.get_filter("middle_grudge_outline")
	if(current_filter)
		animate(owner.get_filter("middle_grudge_outline"), size = outline_size, color = outline_color, time = 0.3 SECONDS)
	else
		owner.add_filter("middle_grudge_outline", 3, list("type" = "outline", "color" = outline_color, "size" = outline_size))

/datum/status_effect/stacking/middle_grudge/can_have_status()
	return (owner.stat != DEAD)

/datum/status_effect/stacking/middle_grudge/tick()
	if(!can_have_status())
		qdel(src)

/// Helper proc to add Grudge stacks to a mob. Blocked during combos.
/mob/living/proc/AddGrudge(amount)
	// Block grudge gain during combos
	var/obj/item/ego_weapon/city/laevateinn/sword = locate() in contents
	if(!sword && ishuman(src))
		var/mob/living/carbon/human/H = src
		sword = H.s_store
	if(istype(sword) && sword.combo_in_progress)
		return
	var/datum/status_effect/stacking/middle_grudge/G = has_status_effect(/datum/status_effect/stacking/middle_grudge)
	if(!G)
		apply_status_effect(/datum/status_effect/stacking/middle_grudge, amount)
	else
		G.add_stacks(amount)

/// Helper proc to consume Grudge stacks, returns amount actually consumed
/mob/living/proc/ConsumeGrudge(amount)
	var/datum/status_effect/stacking/middle_grudge/G = has_status_effect(/datum/status_effect/stacking/middle_grudge)
	if(!G)
		return 0
	var/consumed = min(G.stacks, amount)
	G.add_stacks(-consumed)
	if(G.stacks <= 0)
		qdel(G)
	return consumed

/// Helper proc to consume ALL Grudge stacks, returns amount consumed
/mob/living/proc/ConsumeAllGrudge()
	var/datum/status_effect/stacking/middle_grudge/G = has_status_effect(/datum/status_effect/stacking/middle_grudge)
	if(!G)
		return 0
	var/consumed = G.stacks
	qdel(G)
	return consumed

/// Helper proc to get current Grudge stacks
/mob/living/proc/GetGrudge()
	var/datum/status_effect/stacking/middle_grudge/G = has_status_effect(/datum/status_effect/stacking/middle_grudge)
	if(!G)
		return 0
	return G.stacks

/// Component that handles gaining Grudge from being hit.
/// Attach to the Middle Nursefather.
/datum/component/middle_grudge_gain
	dupe_mode = COMPONENT_DUPE_UNIQUE

/datum/component/middle_grudge_gain/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/middle_grudge_gain/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_damage_taken))

/datum/component/middle_grudge_gain/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_APPLY_DAMGE)

/datum/component/middle_grudge_gain/proc/on_damage_taken(datum/source, damage, damagetype, def_zone, attack_source, flags, attack_type)
	SIGNAL_HANDLER
	if(!damage || damage <= 0)
		return

	var/mob/living/owner = parent
	var/stacks_to_add
	if(damage >= 100)
		stacks_to_add = 5
	else if(damage >= 50)
		stacks_to_add = 3
	else if(damage >= 20)
		stacks_to_add = 2
	else
		stacks_to_add = 1

	INVOKE_ASYNC(owner, TYPE_PROC_REF(/mob/living, AddGrudge), stacks_to_add)
