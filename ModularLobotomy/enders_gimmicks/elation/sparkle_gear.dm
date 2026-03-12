// Sparkle EGO Gear Set - Elation

/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit
	name = "red kimono dress"
	desc = "A small red kimono dress. Just looking at it makes you feel uneasy, as if something is trying to distract you."
	icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'
	worn_icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_worn.dmi'
	icon_state = "sparkle_outfit"
	armor = list(RED_DAMAGE = 60, WHITE_DAMAGE = 60, BLACK_DAMAGE = 60, PALE_DAMAGE = 60)
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 80
	)
	actions_types = list(
		/datum/action/item_action/sparkle_mimic,
		/datum/action/item_action/sparkle_mimic_test,
		/datum/action/item_action/sparkle_mark,
		/datum/action/item_action/sparkle_disguise_slot/slot1,
		/datum/action/item_action/sparkle_disguise_slot/slot2,
		/datum/action/item_action/sparkle_disguise_slot/slot3,
		/datum/action/item_action/sparkle_clear_slot
	)
	mask = /obj/item/clothing/mask/ego_mask/sparkle_mask
	var/phase_active = FALSE
	var/phase_cooldown = 0
	var/phase_cooldown_time = 10 SECONDS
	/// Timer ID for the passive phase deactivation
	var/phase_timer_id = null
	/// Whether the wearer is currently disguised
	var/disguised = FALSE
	/// Tracks created fake items for cleanup
	var/list/disguise_items = list()
	/// Stores original appearance data for revert
	var/list/stored_originals = list()
	/// The currently marked mob
	var/mob/living/marked_target = null
	/// Whether the mark-phase is active
	var/mark_phase_active = FALSE
	/// Cooldown tracker for mark ability
	var/mark_cooldown = 0
	/// Cooldown duration for mark ability
	var/mark_cooldown_time = 20 SECONDS
	/// Max duration for mark phase
	var/mark_max_duration = 20 SECONDS
	/// Timer ID for mark phase timeout
	var/mark_timer_id = null
	/// Saved disguise target weakrefs for quick-swap slots (1-3)
	var/list/saved_disguises = list(null, null, null)
	/// Weakref to the current disguise target
	var/datum/weakref/current_disguise_target = null
	/// Which saved slot is currently active (0 = none)
	var/active_disguise_slot = 0
	/// Items stored during mark stun to prevent theft
	var/list/stun_stored_items = list()
	/// Reference to the sparkle mask moved aside during disguise
	var/obj/item/clothing/mask/ego_mask/sparkle_mask/stored_mask = null

/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/equipped(mob/living/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_OCLOTHING)
		return
	RegisterSignal(user, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnDamage))
	RegisterSignal(user, COMSIG_MOB_ITEM_ATTACK, PROC_REF(OnAttack))

/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/dropped(mob/living/user)
	if(disguised)
		RemoveDisguise(user)
	if(mark_phase_active && marked_target)
		var/datum/status_effect/sparkle_mark/mark_effect = marked_target.has_status_effect(/datum/status_effect/sparkle_mark)
		if(mark_effect)
			qdel(mark_effect)
	. = ..()
	UnregisterSignal(user, COMSIG_MOB_APPLY_DAMGE)
	UnregisterSignal(user, COMSIG_MOB_ITEM_ATTACK)
	if(phase_active)
		DeactivatePhase(user)

/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/proc/OnDamage(mob/living/user, damage, damagetype, def_zone, source, flags, attack_type)
	SIGNAL_HANDLER
	if(mark_phase_active)
		if(attack_type & ATTACK_TYPE_MELEE)
			// Getting hit by melee while mark is active — stun and break mark
			var/mob/living/target_ref = marked_target
			if(target_ref)
				var/datum/status_effect/sparkle_mark/mark_effect = target_ref.has_status_effect(/datum/status_effect/sparkle_mark)
				if(mark_effect)
					qdel(mark_effect)
			// Store held items inside the outfit to prevent theft during stun
			stun_stored_items = list()
			var/obj/item/l_hand = user.get_item_for_held_index(LEFT_HANDS)
			if(l_hand)
				stun_stored_items["left"] = l_hand
				user.dropItemToGround(l_hand, TRUE)
				l_hand.forceMove(src)
			var/obj/item/r_hand = user.get_item_for_held_index(RIGHT_HANDS)
			if(r_hand)
				stun_stored_items["right"] = r_hand
				user.dropItemToGround(r_hand, TRUE)
				r_hand.forceMove(src)
			user.Stun(20) // 2 seconds
			var/mutable_appearance/stagger_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/tegumobs.dmi', "small_stagger", user.layer + 0.1)
			user.add_overlay(stagger_overlay)
			addtimer(CALLBACK(src, PROC_REF(RestoreAfterMarkStun), user, stagger_overlay), 2 SECONDS)
		return
	if(phase_active)
		return
	if(disguised)
		return
	if(damage <= 0)
		return
	if(world.time < phase_cooldown)
		return
	ActivatePhase(user)

/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/proc/OnAttack(datum/source, mob/target, mob/user, obj/item/weapon)
	SIGNAL_HANDLER
	if(mark_phase_active)
		if(target == marked_target)
			return // Allow attacking marked target without breaking phase
		// Attacking non-marked target breaks mark phase and removes mark
		var/mob/living/target_ref = marked_target
		if(target_ref)
			var/datum/status_effect/sparkle_mark/mark_effect = target_ref.has_status_effect(/datum/status_effect/sparkle_mark)
			if(mark_effect)
				qdel(mark_effect)
		return
	if(phase_active)
		DeactivatePhase(user)

/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/proc/ActivatePhase(mob/living/user)
	phase_active = TRUE
	var/obj/effect/temp_visual/turn_book/T = new(get_turf(user))
	T.color = "#88091B"
	user.alpha = 25
	user.density = FALSE
	user.mouse_opacity = 0
	phase_timer_id = addtimer(CALLBACK(src, PROC_REF(DeactivatePhase), user), 2 SECONDS, TIMER_STOPPABLE)

/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/proc/DeactivatePhase(mob/living/user)
	if(!phase_active)
		return
	phase_active = FALSE
	phase_timer_id = null
	// If mark phase is active, stay invisible — mark controls visibility now
	if(mark_phase_active)
		return
	phase_cooldown = world.time + phase_cooldown_time
	var/obj/effect/temp_visual/turn_book/T = new(get_turf(user))
	T.color = "#88091B"
	user.alpha = 255
	user.density = TRUE
	user.mouse_opacity = 1

/// Removes the stagger overlay after duration expires
/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/proc/RemoveStaggerOverlay(mob/living/user, mutable_appearance/overlay)
	if(!QDELETED(user) && overlay)
		user.cut_overlay(overlay)

/// Restores stagger overlay and re-equips stored items after mark stun ends
/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/proc/RestoreAfterMarkStun(mob/living/user, mutable_appearance/overlay)
	if(!QDELETED(user) && overlay)
		user.cut_overlay(overlay)
	if(!QDELETED(user))
		// Re-equip stored items
		var/obj/item/l_item = stun_stored_items["left"]
		if(l_item && !QDELETED(l_item))
			user.put_in_l_hand(l_item)
		var/obj/item/r_item = stun_stored_items["right"]
		if(r_item && !QDELETED(r_item))
			user.put_in_r_hand(r_item)
	stun_stored_items = list()

/// Activates the mark phase — auto-targets the nearest hostile mob
/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/proc/ActivateMarkPhase(mob/living/user)
	if(mark_phase_active)
		return
	// If already in passive phase, cancel its timer — mark phase takes over
	if(phase_active)
		if(phase_timer_id)
			deltimer(phase_timer_id)
			phase_timer_id = null
		phase_active = FALSE
	// Find nearest hostile living mob
	var/mob/living/nearest = null
	var/nearest_dist = INFINITY
	for(var/mob/living/L in range(5, user))
		if(L == user)
			continue
		if(L.stat == DEAD)
			continue
		if(user.faction_check_mob(L))
			continue
		var/dist = get_dist(user, L)
		if(dist < nearest_dist)
			nearest_dist = dist
			nearest = L

	if(!nearest)
		to_chat(user, span_warning("No valid targets nearby."))
		return

	// Enter phase state (no timer — stays until mark resolves)
	var/obj/effect/temp_visual/turn_book/T = new(get_turf(user))
	T.color = "#88091B"
	user.alpha = 25
	user.density = FALSE
	user.mouse_opacity = 0

	// Apply mark status effect to target
	nearest.apply_status_effect(/datum/status_effect/sparkle_mark, user, src)
	mark_phase_active = TRUE
	marked_target = nearest
	// Mark expires after max duration
	mark_timer_id = addtimer(CALLBACK(src, PROC_REF(MarkTimeout), user), mark_max_duration, TIMER_STOPPABLE)
	to_chat(user, span_notice("You mark [nearest]."))

/// Called when mark phase runs out of time
/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/proc/MarkTimeout(mob/living/user)
	if(!mark_phase_active)
		return
	if(marked_target)
		var/datum/status_effect/sparkle_mark/mark_effect = marked_target.has_status_effect(/datum/status_effect/sparkle_mark)
		if(mark_effect)
			qdel(mark_effect)

/// Ends the mark phase and restores the user from phase state
/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/proc/EndMarkPhase(mob/living/user)
	if(!mark_phase_active)
		return
	mark_phase_active = FALSE
	marked_target = null
	mark_cooldown = world.time + mark_cooldown_time
	if(mark_timer_id)
		deltimer(mark_timer_id)
		mark_timer_id = null
	if(!QDELETED(user))
		var/obj/effect/temp_visual/turn_book/T = new(get_turf(user))
		T.color = "#88091B"
		user.alpha = 255
		user.density = TRUE
		user.mouse_opacity = 1

/obj/item/clothing/mask/ego_mask/sparkle_mask
	name = "fool's mask"
	desc = "A strange red and white fox mask. Who could be hiding under these masks?"
	icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'
	worn_icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_worn.dmi'
	icon_state = "sparkle_mask"
	flags_inv = HIDEFACE|HIDEEYES|HIDEFACIALHAIR|HIDESNOUT
	var/alt_style = FALSE

/obj/item/clothing/mask/ego_mask/sparkle_mask/equipped(mob/M, slot)
	. = ..()
	if(slot != ITEM_SLOT_MASK)
		return
	if(!alt_style)
		ADD_TRAIT(M, TRAIT_SILENT_FOOTSTEPS, MASK_TRAIT)
		ADD_TRAIT(M, TRAIT_UNKNOWN, MASK_TRAIT)

/obj/item/clothing/mask/ego_mask/sparkle_mask/dropped(mob/M)
	REMOVE_TRAIT(M, TRAIT_SILENT_FOOTSTEPS, MASK_TRAIT)
	REMOVE_TRAIT(M, TRAIT_UNKNOWN, MASK_TRAIT)
	return ..()

/obj/item/clothing/mask/ego_mask/sparkle_mask/AltClick(mob/user)
	. = ..()
	if(user.canUseTopic(src, BE_CLOSE, NO_DEXTERITY, FALSE, !iscyborg(user)))
		toggle_style(user)

/obj/item/clothing/mask/ego_mask/sparkle_mask/proc/toggle_style(mob/user)
	if(user.incapacitated())
		return
	alt_style = !alt_style
	if(alt_style)
		icon_state = "sparkle_mask_alt"
		flags_inv = NONE
		REMOVE_TRAIT(user, TRAIT_SILENT_FOOTSTEPS, MASK_TRAIT)
		REMOVE_TRAIT(user, TRAIT_UNKNOWN, MASK_TRAIT)
		to_chat(user, span_notice("You move the mask to the side of your head."))
	else
		icon_state = "sparkle_mask"
		flags_inv = HIDEFACE|HIDEEYES|HIDEFACIALHAIR|HIDESNOUT
		ADD_TRAIT(user, TRAIT_SILENT_FOOTSTEPS, MASK_TRAIT)
		ADD_TRAIT(user, TRAIT_UNKNOWN, MASK_TRAIT)
		to_chat(user, span_notice("You move the mask back over your face."))
	user.update_inv_wear_mask()

/obj/item/clothing/mask/ego_mask/sparkle_mask/examine(mob/user)
	. = ..()
	. += span_notice("Alt-click to adjust the mask's position.")

/obj/item/clothing/shoes/sparkle_shoes
	name = "red string sandals"
	desc = "A pair of simple sandals that have some red string tying them together."
	icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'
	worn_icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_worn.dmi'
	icon_state = "sparkle_shoes"

/obj/item/clothing/gloves/sparkle_gloves
	name = "fool's glove"
	desc = "A single glove for the right hand. What could the fool be hiding?"
	icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'
	worn_icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_worn.dmi'
	icon_state = "sparkle_glove"

/// Applies a full disguise copying the target's appearance, equipment visuals, and ID data
/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/proc/SparkleDisguise(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!target || !ishuman(target) || QDELETED(target))
		return FALSE
	if(!target.dna)
		to_chat(user, span_warning("Target has no DNA data!"))
		return FALSE

	// Store original appearance data (only if not already stored from a previous disguise)
	if(!disguised)
		stored_originals = list()
		stored_originals["real_name"] = user.real_name
		stored_originals["name"] = user.name
		stored_originals["gender"] = user.gender
		stored_originals["hairstyle"] = user.hairstyle
		stored_originals["hair_color"] = user.hair_color
		stored_originals["facial_hairstyle"] = user.facial_hairstyle
		stored_originals["facial_hair_color"] = user.facial_hair_color
		stored_originals["eye_color"] = user.eye_color
		stored_originals["gradient_style"] = user.gradient_style
		stored_originals["gradient_color"] = user.gradient_color
		stored_originals["underwear"] = user.underwear
		stored_originals["underwear_color"] = user.underwear_color

		// Store original DNA
		var/datum/dna/original_dna = new /datum/dna
		user.dna.copy_dna(original_dna)
		stored_originals["dna"] = original_dna

		// Store original armor icons and flags
		stored_originals["armor_icon"] = icon
		stored_originals["armor_worn_icon"] = worn_icon
		stored_originals["armor_icon_state"] = icon_state
		stored_originals["armor_name"] = name
		stored_originals["armor_desc"] = desc
		stored_originals["armor_flags_inv"] = flags_inv

		// Store original under clothing icons
		var/obj/item/clothing/under/user_under = user.get_item_by_slot(ITEM_SLOT_ICLOTHING)
		if(istype(user_under))
			stored_originals["under_icon"] = user_under.icon
			stored_originals["under_worn_icon"] = user_under.worn_icon
			stored_originals["under_icon_state"] = user_under.icon_state
			stored_originals["under_name"] = user_under.name

		// Store original shoes icons
		var/obj/item/clothing/shoes/sparkle_shoes/shoes = user.get_item_by_slot(ITEM_SLOT_FEET)
		if(istype(shoes))
			stored_originals["shoes_icon"] = shoes.icon
			stored_originals["shoes_worn_icon"] = shoes.worn_icon
			stored_originals["shoes_icon_state"] = shoes.icon_state
			stored_originals["shoes_name"] = shoes.name

		// Store original gloves icons
		var/obj/item/clothing/gloves/sparkle_gloves/gloves = user.get_item_by_slot(ITEM_SLOT_GLOVES)
		if(istype(gloves))
			stored_originals["gloves_icon"] = gloves.icon
			stored_originals["gloves_worn_icon"] = gloves.worn_icon
			stored_originals["gloves_icon_state"] = gloves.icon_state
			stored_originals["gloves_name"] = gloves.name

		// Store original ID/PDA data
		var/obj/item/card/id/user_id = user.get_idcard(TRUE)
		if(user_id)
			stored_originals["id_registered_name"] = user_id.registered_name
			stored_originals["id_assignment"] = user_id.assignment
			stored_originals["id_registered_account"] = user_id.registered_account
		var/obj/item/pda/user_pda = user.get_item_by_slot(ITEM_SLOT_ID)
		if(istype(user_pda))
			stored_originals["pda_owner"] = user_pda.owner
			stored_originals["pda_ownjob"] = user_pda.ownjob
	else
		// Already disguised — clean up fake items from current disguise before swapping
		for(var/obj/item/fake_item in disguise_items)
			if(!QDELETED(fake_item))
				qdel(fake_item)
		disguise_items = list()

	// --- Visual Effect ---
	var/obj/effect/temp_visual/turn_book/T = new(get_turf(user))
	T.color = "#88091B"
	playsound(user, 'sound/magic/summon_magic.ogg', 30, TRUE)

	// --- Apply Disguise ---

	// Copy DNA and appearance
	var/datum/dna/target_dna = new /datum/dna
	target.dna.copy_dna(target_dna)
	target_dna.transfer_identity(user)

	user.real_name = target.real_name
	user.name = target.real_name
	user.gender = target.gender
	user.hairstyle = target.hairstyle
	user.hair_color = target.hair_color
	user.facial_hairstyle = target.facial_hairstyle
	user.facial_hair_color = target.facial_hair_color
	user.eye_color = target.eye_color
	user.gradient_style = target.gradient_style
	user.gradient_color = target.gradient_color
	user.underwear = target.underwear
	user.underwear_color = target.underwear_color
	user.updateappearance()
	user.update_hair()

	// Copy armor visuals and flags from target's suit
	var/obj/item/clothing/suit/target_suit = target.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(target_suit)
		name = target_suit.name
		desc = target_suit.desc
		icon = target_suit.icon
		worn_icon = target_suit.worn_icon
		icon_state = target_suit.icon_state
		flags_inv = target_suit.flags_inv
		update_slot_icon()

	// Copy under clothing visuals
	var/obj/item/clothing/under/cur_under = user.get_item_by_slot(ITEM_SLOT_ICLOTHING)
	if(istype(cur_under))
		var/obj/item/clothing/under/target_under = target.get_item_by_slot(ITEM_SLOT_ICLOTHING)
		if(target_under)
			cur_under.name = target_under.name
			cur_under.icon = target_under.icon
			cur_under.worn_icon = target_under.worn_icon
			cur_under.icon_state = target_under.icon_state
			cur_under.update_slot_icon()

	// Copy shoes visuals
	var/obj/item/clothing/shoes/sparkle_shoes/cur_shoes = user.get_item_by_slot(ITEM_SLOT_FEET)
	if(istype(cur_shoes))
		var/obj/item/clothing/shoes/target_shoes = target.get_item_by_slot(ITEM_SLOT_FEET)
		if(target_shoes)
			cur_shoes.name = target_shoes.name
			cur_shoes.icon = target_shoes.icon
			cur_shoes.worn_icon = target_shoes.worn_icon
			cur_shoes.icon_state = target_shoes.icon_state
			cur_shoes.update_slot_icon()

	// Copy gloves visuals
	var/obj/item/clothing/gloves/sparkle_gloves/cur_gloves = user.get_item_by_slot(ITEM_SLOT_GLOVES)
	if(istype(cur_gloves))
		var/obj/item/clothing/gloves/target_gloves = target.get_item_by_slot(ITEM_SLOT_GLOVES)
		if(target_gloves)
			cur_gloves.name = target_gloves.name
			cur_gloves.icon = target_gloves.icon
			cur_gloves.worn_icon = target_gloves.worn_icon
			cur_gloves.icon_state = target_gloves.icon_state
			cur_gloves.update_slot_icon()

	// Handle mask — if sparkle mask is worn, use its toggle to move it aside
	if(!disguised)
		var/obj/item/clothing/mask/our_mask = user.get_item_by_slot(ITEM_SLOT_MASK)
		if(our_mask)
			if(istype(our_mask, /obj/item/clothing/mask/ego_mask/sparkle_mask))
				var/obj/item/clothing/mask/ego_mask/sparkle_mask/smask = our_mask
				if(!smask.alt_style)
					smask.toggle_style(user)
				stored_mask = smask
			else
				user.dropItemToGround(our_mask, TRUE)

	// Copy ID/PDA data
	var/obj/item/card/id/user_id = user.get_idcard(TRUE)
	var/obj/item/card/id/target_id = target.get_idcard(TRUE)
	if(user_id && target_id)
		user_id.registered_name = target_id.registered_name
		user_id.assignment = target_id.assignment
		if(target_id.registered_account)
			user_id.registered_account = target_id.registered_account
		user_id.update_label()

	var/obj/item/pda/user_pda = user.get_item_by_slot(ITEM_SLOT_ID)
	if(istype(user_pda))
		var/obj/item/pda/target_pda = target.get_item_by_slot(ITEM_SLOT_ID)
		if(istype(target_pda))
			user_pda.owner = target_pda.owner
			user_pda.ownjob = target_pda.ownjob
			user_pda.update_label()

	// Create fake pocket items
	disguise_items = list()
	var/obj/item/target_lpocket = target.get_item_by_slot(ITEM_SLOT_LPOCKET)
	if(target_lpocket)
		var/obj/item/fake_lp = new target_lpocket.type()
		user.equip_to_slot_or_del(fake_lp, ITEM_SLOT_LPOCKET, TRUE)
		disguise_items += fake_lp

	var/obj/item/target_rpocket = target.get_item_by_slot(ITEM_SLOT_RPOCKET)
	if(target_rpocket)
		var/obj/item/fake_rp = new target_rpocket.type()
		user.equip_to_slot_or_del(fake_rp, ITEM_SLOT_RPOCKET, TRUE)
		disguise_items += fake_rp

	// Create fake held items
	var/obj/item/target_lhand = target.get_item_for_held_index(LEFT_HANDS)
	if(target_lhand)
		var/obj/item/fake_lh = new target_lhand.type()
		if(istype(fake_lh, /obj/item/ego_weapon))
			var/obj/item/ego_weapon/ego_lh = fake_lh
			ego_lh.attribute_requirements = list()
		user.put_in_l_hand(fake_lh)
		disguise_items += fake_lh

	var/obj/item/target_rhand = target.get_item_for_held_index(RIGHT_HANDS)
	if(target_rhand)
		var/obj/item/fake_rh = new target_rhand.type()
		if(istype(fake_rh, /obj/item/ego_weapon))
			var/obj/item/ego_weapon/ego_rh = fake_rh
			ego_rh.attribute_requirements = list()
		user.put_in_r_hand(fake_rh)
		disguise_items += fake_rh

	disguised = TRUE
	current_disguise_target = WEAKREF(target)
	to_chat(user, span_notice("You now look like [target.real_name]."))
	return TRUE

/// Removes the disguise and restores original appearance
/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/proc/RemoveDisguise(mob/living/carbon/human/user)
	if(!disguised)
		return
	if(!istype(user))
		return

	// Visual effect
	var/obj/effect/temp_visual/turn_book/T = new(get_turf(user))
	T.color = "#88091B"
	playsound(user, 'sound/magic/summon_magic.ogg', 30, TRUE)

	// Delete fake items
	for(var/obj/item/fake_item in disguise_items)
		if(!QDELETED(fake_item))
			qdel(fake_item)
	disguise_items = list()

	// Restore DNA and base appearance
	if(stored_originals["dna"])
		var/datum/dna/original_dna = stored_originals["dna"]
		original_dna.transfer_identity(user)

	user.real_name = stored_originals["real_name"]
	user.name = stored_originals["name"]
	user.gender = stored_originals["gender"]
	user.eye_color = stored_originals["eye_color"]
	user.underwear = stored_originals["underwear"]
	user.underwear_color = stored_originals["underwear_color"]
	user.updateappearance()

	// Restore hair after updateappearance so it doesn't get overridden by DNA
	user.hairstyle = stored_originals["hairstyle"]
	user.hair_color = stored_originals["hair_color"]
	user.facial_hairstyle = stored_originals["facial_hairstyle"]
	user.facial_hair_color = stored_originals["facial_hair_color"]
	user.gradient_style = stored_originals["gradient_style"]
	user.gradient_color = stored_originals["gradient_color"]
	user.update_hair()

	// Restore armor icons and flags
	name = stored_originals["armor_name"]
	desc = stored_originals["armor_desc"]
	icon = stored_originals["armor_icon"]
	worn_icon = stored_originals["armor_worn_icon"]
	icon_state = stored_originals["armor_icon_state"]
	flags_inv = stored_originals["armor_flags_inv"]
	update_slot_icon()

	// Restore under clothing icons
	var/obj/item/clothing/under/user_under = user.get_item_by_slot(ITEM_SLOT_ICLOTHING)
	if(istype(user_under) && stored_originals["under_icon"])
		user_under.name = stored_originals["under_name"]
		user_under.icon = stored_originals["under_icon"]
		user_under.worn_icon = stored_originals["under_worn_icon"]
		user_under.icon_state = stored_originals["under_icon_state"]
		user_under.update_slot_icon()

	// Restore shoes icons
	var/obj/item/clothing/shoes/sparkle_shoes/shoes = user.get_item_by_slot(ITEM_SLOT_FEET)
	if(istype(shoes) && stored_originals["shoes_icon"])
		shoes.name = stored_originals["shoes_name"]
		shoes.icon = stored_originals["shoes_icon"]
		shoes.worn_icon = stored_originals["shoes_worn_icon"]
		shoes.icon_state = stored_originals["shoes_icon_state"]
		shoes.update_slot_icon()

	// Restore gloves icons
	var/obj/item/clothing/gloves/sparkle_gloves/gloves = user.get_item_by_slot(ITEM_SLOT_GLOVES)
	if(istype(gloves) && stored_originals["gloves_icon"])
		gloves.name = stored_originals["gloves_name"]
		gloves.icon = stored_originals["gloves_icon"]
		gloves.worn_icon = stored_originals["gloves_worn_icon"]
		gloves.icon_state = stored_originals["gloves_icon_state"]
		gloves.update_slot_icon()

	// Restore ID/PDA data
	var/obj/item/card/id/user_id = user.get_idcard(TRUE)
	if(user_id && stored_originals["id_registered_name"])
		user_id.registered_name = stored_originals["id_registered_name"]
		user_id.assignment = stored_originals["id_assignment"]
		if(stored_originals["id_registered_account"])
			user_id.registered_account = stored_originals["id_registered_account"]
		user_id.update_label()

	var/obj/item/pda/user_pda = user.get_item_by_slot(ITEM_SLOT_ID)
	if(istype(user_pda) && stored_originals["pda_owner"])
		user_pda.owner = stored_originals["pda_owner"]
		user_pda.ownjob = stored_originals["pda_ownjob"]
		user_pda.update_label()

	stored_originals = list()
	disguised = FALSE
	active_disguise_slot = 0
	current_disguise_target = null

	// Re-equip sparkle mask if we stored one
	if(stored_mask && !QDELETED(stored_mask))
		if(stored_mask.alt_style)
			stored_mask.toggle_style(user)
		stored_mask = null

	to_chat(user, span_notice("Your disguise fades away."))

/// Saves a disguise target weakref to a slot (1-3)
/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/proc/SaveDisguiseSlot(mob/living/carbon/human/user, slot_num, mob/living/carbon/human/target)
	if(slot_num < 1 || slot_num > 3)
		return
	if(!target || !ishuman(target) || QDELETED(target))
		return
	saved_disguises[slot_num] = WEAKREF(target)
	to_chat(user, span_notice("Saved [target.real_name] to disguise slot [slot_num]."))

/// Loads a saved disguise from a slot, applying it instantly
/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/proc/LoadDisguiseSlot(mob/living/carbon/human/user, slot_num)
	if(slot_num < 1 || slot_num > 3)
		return
	if(!saved_disguises[slot_num])
		to_chat(user, span_warning("Disguise slot [slot_num] is empty. Use the Mimic Disguise action first, then save with this button."))
		return
	var/datum/weakref/ref = saved_disguises[slot_num]
	var/mob/living/carbon/human/target = ref.resolve()
	if(!target || !ishuman(target) || QDELETED(target))
		to_chat(user, span_warning("Saved target is no longer available."))
		saved_disguises[slot_num] = null
		return
	if(target.stat == DEAD)
		to_chat(user, span_warning("Saved target is dead."))
		return
	SparkleDisguise(user, target)
	active_disguise_slot = slot_num

// Action datum for mimic disguise (selects from GLOB.player_list)
/datum/action/item_action/sparkle_mimic
	name = "Mimic Disguise"
	desc = "Disguise yourself as another person."
	button_icon_state = "unreliable_narrator"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'

/datum/action/item_action/sparkle_mimic/Trigger()
	if(!istype(target, /obj/item/clothing/suit/armor/ego_gear/sparkle_outfit))
		return
	var/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/outfit = target
	if(!ishuman(owner))
		return

	var/mob/living/carbon/human/user = owner

	if(outfit.disguised)
		outfit.RemoveDisguise(user)
		return

	// Build list of living humans from GLOB.player_list
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H == user)
			continue
		if(H.stat == DEAD)
			continue
		candidates[H.real_name] = H

	if(!length(candidates))
		to_chat(user, span_warning("No valid targets found."))
		return

	var/chosen_name = input(user, "Choose a person to disguise as:", "Mimic Disguise") as null|anything in candidates
	if(!chosen_name)
		return
	if(user.incapacitated())
		return

	var/mob/living/carbon/human/chosen = candidates[chosen_name]
	if(!chosen || QDELETED(chosen))
		to_chat(user, span_warning("Target is no longer available."))
		return

	outfit.SparkleDisguise(user, chosen)

// Test action datum for mimic disguise (selects from nearby humans)
/datum/action/item_action/sparkle_mimic_test
	name = "Mimic Disguise (Close Range)"
	desc = "Disguise yourself as a nearby person."
	button_icon_state = "thousand_faces"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'

/datum/action/item_action/sparkle_mimic_test/Trigger()
	if(!istype(target, /obj/item/clothing/suit/armor/ego_gear/sparkle_outfit))
		return
	var/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/outfit = target
	if(!ishuman(owner))
		return

	var/mob/living/carbon/human/user = owner

	if(outfit.disguised)
		outfit.RemoveDisguise(user)
		return

	// Build list of nearby living humans
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in range(5, user))
		if(H == user)
			continue
		if(H.stat == DEAD)
			continue
		candidates[H.real_name] = H

	if(!length(candidates))
		to_chat(user, span_warning("No valid targets nearby."))
		return

	var/chosen_name = input(user, "Choose a person to disguise as:", "Mimic Disguise (Test)") as null|anything in candidates
	if(!chosen_name)
		return
	if(user.incapacitated())
		return

	var/mob/living/carbon/human/chosen = candidates[chosen_name]
	if(!chosen || QDELETED(chosen))
		to_chat(user, span_warning("Target is no longer available."))
		return

	outfit.SparkleDisguise(user, chosen)

// Action datum for sparkle mark
/datum/action/item_action/sparkle_mark
	name = "Sparkle Mark"
	desc = "Enter phase and place a directional mark on the nearest enemy."
	button_icon_state = "nocturne"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'

/datum/action/item_action/sparkle_mark/Trigger()
	if(!istype(target, /obj/item/clothing/suit/armor/ego_gear/sparkle_outfit))
		return
	var/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/outfit = target
	if(!isliving(owner))
		return
	if(outfit.mark_phase_active)
		return
	if(world.time < outfit.mark_cooldown)
		to_chat(owner, span_warning("Mark is on cooldown."))
		return
	outfit.ActivateMarkPhase(owner)

// --- Disguise Quick-Swap Slot Actions ---
// Click when slot is empty: opens target picker to save a target
// Click when slot has a target saved: loads that disguise instantly
// Click when already disguised as this slot: removes disguise

/datum/action/item_action/sparkle_disguise_slot
	name = "Disguise Slot"
	desc = "Quick-swap disguise slot. Click to save/load."
	button_icon_state = "sparkle_fish"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'
	/// Which slot number this action controls
	var/slot_num = 1

/datum/action/item_action/sparkle_disguise_slot/slot1
	name = "Disguise Slot 1"
	button_icon_state = "sparkle_fish_1"
	slot_num = 1

/datum/action/item_action/sparkle_disguise_slot/slot2
	name = "Disguise Slot 2"
	button_icon_state = "sparkle_fish_2"
	slot_num = 2

/datum/action/item_action/sparkle_disguise_slot/slot3
	name = "Disguise Slot 3"
	button_icon_state = "sparkle_fish_3"
	slot_num = 3

/datum/action/item_action/sparkle_disguise_slot/Trigger()
	if(!istype(target, /obj/item/clothing/suit/armor/ego_gear/sparkle_outfit))
		return
	var/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/outfit = target
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/user = owner

	// If currently disguised as this slot, remove disguise
	if(outfit.disguised && outfit.active_disguise_slot == slot_num)
		outfit.RemoveDisguise(user)
		return

	// If slot has a saved target, load it
	if(outfit.saved_disguises[slot_num])
		outfit.LoadDisguiseSlot(user, slot_num)
		return

	// Slot is empty — if currently disguised, save current disguise target to this slot
	if(outfit.disguised && outfit.current_disguise_target)
		var/mob/living/carbon/human/cur_target = outfit.current_disguise_target.resolve()
		if(cur_target && ishuman(cur_target) && !QDELETED(cur_target))
			outfit.SaveDisguiseSlot(user, slot_num, cur_target)
			outfit.active_disguise_slot = slot_num
			return

	// Not disguised and slot empty — open picker to save a target
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H == user)
			continue
		if(H.stat == DEAD)
			continue
		candidates[H.real_name] = H

	if(!length(candidates))
		to_chat(user, span_warning("No valid targets found."))
		return

	var/chosen_name = input(user, "Choose a person to save to slot [slot_num]:", "Save Disguise Slot [slot_num]") as null|anything in candidates
	if(!chosen_name)
		return
	if(user.incapacitated())
		return

	var/mob/living/carbon/human/chosen = candidates[chosen_name]
	if(!chosen || QDELETED(chosen))
		to_chat(user, span_warning("Target is no longer available."))
		return

	outfit.SaveDisguiseSlot(user, slot_num, chosen)

// Action to clear a saved disguise slot
/datum/action/item_action/sparkle_clear_slot
	name = "Clear Disguise Slot"
	desc = "Clear a saved disguise slot."
	button_icon_state = "narrative_polysemy"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'

/datum/action/item_action/sparkle_clear_slot/Trigger()
	if(!istype(target, /obj/item/clothing/suit/armor/ego_gear/sparkle_outfit))
		return
	var/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/outfit = target
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/user = owner

	// Build list of slots that have saved targets
	var/list/options = list()
	for(var/i in 1 to 3)
		if(outfit.saved_disguises[i])
			var/datum/weakref/ref = outfit.saved_disguises[i]
			var/mob/living/carbon/human/saved = ref.resolve()
			var/slot_label = "Slot [i]"
			if(saved && !QDELETED(saved))
				slot_label = "Slot [i]: [saved.real_name]"
			options += slot_label

	if(!length(options))
		to_chat(user, span_warning("No saved disguises to clear."))
		return

	var/chosen = input(user, "Choose a slot to clear:", "Clear Disguise Slot") as null|anything in options
	if(!chosen)
		return

	// Extract slot number from the chosen string
	var/slot_num = text2num(copytext(chosen, 6, 7))
	if(!slot_num || slot_num < 1 || slot_num > 3)
		return

	outfit.saved_disguises[slot_num] = null
	to_chat(user, span_notice("Cleared disguise slot [slot_num]."))

// Status effect for sparkle mark on target
/datum/status_effect/sparkle_mark
	id = "sparkle_mark"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	tick_interval = -1
	alert_type = null
	/// The sparkle outfit wearer
	var/mob/living/mark_owner
	/// Reference to the outfit
	var/obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/outfit
	var/north_triggered = FALSE
	var/south_triggered = FALSE
	var/east_triggered = FALSE
	var/west_triggered = FALSE
	var/mutable_appearance/overlay_north
	var/mutable_appearance/overlay_south
	var/mutable_appearance/overlay_east
	var/mutable_appearance/overlay_west

/datum/status_effect/sparkle_mark/on_creation(mob/living/new_owner, mob/living/sparkle_user, obj/item/clothing/suit/armor/ego_gear/sparkle_outfit/sparkle_outfit)
	mark_owner = sparkle_user
	outfit = sparkle_outfit
	. = ..()

/datum/status_effect/sparkle_mark/on_apply()
	overlay_north = mutable_appearance('ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi', "sparkle_mark_north", owner.layer + 0.1)
	overlay_south = mutable_appearance('ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi', "sparkle_mark_south", owner.layer + 0.1)
	overlay_east = mutable_appearance('ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi', "sparkle_mark_east", owner.layer + 0.1)
	overlay_west = mutable_appearance('ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi', "sparkle_mark_west", owner.layer + 0.1)
	owner.add_overlay(overlay_north)
	owner.add_overlay(overlay_south)
	owner.add_overlay(overlay_east)
	owner.add_overlay(overlay_west)
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnMarkedDamage))
	return TRUE

/datum/status_effect/sparkle_mark/proc/OnMarkedDamage(datum/signal_source, damage_amount, damage_type, def_zone, source, flags, attack_type)
	SIGNAL_HANDLER
	if(!source || !isliving(source))
		return
	var/turf/attacker_turf = get_turf(source)
	var/turf/target_turf = get_turf(owner)
	if(!attacker_turf || !target_turf)
		return
	var/dx = attacker_turf.x - target_turf.x
	var/dy = attacker_turf.y - target_turf.y
	// Only process if adjacent
	if(abs(dx) > 1 || abs(dy) > 1)
		return
	if(!dx && !dy)
		return
	// Build list of eligible directions based on attacker position
	var/list/eligible = list()
	if(dy > 0 && !north_triggered)
		eligible += NORTH
	if(dy < 0 && !south_triggered)
		eligible += SOUTH
	if(dx > 0 && !east_triggered)
		eligible += EAST
	if(dx < 0 && !west_triggered)
		eligible += WEST
	if(!length(eligible))
		return
	var/chosen_dir = pick(eligible)
	switch(chosen_dir)
		if(NORTH)
			north_triggered = TRUE
			owner.cut_overlay(overlay_north)
		if(SOUTH)
			south_triggered = TRUE
			owner.cut_overlay(overlay_south)
		if(EAST)
			east_triggered = TRUE
			owner.cut_overlay(overlay_east)
		if(WEST)
			west_triggered = TRUE
			owner.cut_overlay(overlay_west)
	// Segment trigger visual — sparks on the target
	var/obj/effect/temp_visual/sparks/S = new(get_turf(owner))
	S.color = "#88091B"
	playsound(owner, 'sound/weapons/slash.ogg', 30, TRUE)
	// Check if all 4 segments are triggered
	if(north_triggered && south_triggered && east_triggered && west_triggered)
		Detonate()

/datum/status_effect/sparkle_mark/proc/Detonate()
	var/turf/T = get_turf(owner)
	// Detonation visual — red explosion and scattered pages
	var/obj/effect/temp_visual/explosion/fast/E = new(T)
	E.color = "#88091B"
	var/obj/effect/temp_visual/turn_book/B = new(T)
	B.color = "#88091B"
	playsound(owner, 'sound/magic/repulse.ogg', 50, TRUE)
	var/damage = 100
	if(isanimal(owner))
		damage *= 4
	owner.deal_damage(damage, RED_DAMAGE, mark_owner)
	qdel(src)

/datum/status_effect/sparkle_mark/on_remove()
	owner.cut_overlay(overlay_north)
	owner.cut_overlay(overlay_south)
	owner.cut_overlay(overlay_east)
	owner.cut_overlay(overlay_west)
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMGE)
	if(outfit && !QDELETED(outfit))
		outfit.EndMarkPhase(mark_owner)
	mark_owner = null
	outfit = null

// Sparkle Hairstyle
/datum/sprite_accessory/hair/twintails_sparkle
	name = "Twintails Sparkle"
	icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'
	icon_state = "twintails_sparkle"

// Consumable item that changes hair to Twintails Sparkle, purple color, no gradient
/obj/item/sparkle_hair_dye
	name = "Sparkle Hair Dye"
	desc = "A consumable hair dye kit. Using it will style your hair into purple twintails. Placeholder description."
	icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'
	icon_state = "twintails_sparkle"
	w_class = WEIGHT_CLASS_TINY

/obj/item/sparkle_hair_dye/attack_self(mob/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(HAS_TRAIT(H, TRAIT_BALD))
		to_chat(H, span_warning("You don't have any hair to dye!"))
		return
	to_chat(H, span_notice("You apply the dye and style your hair into purple twintails."))
	H.hairstyle = "Twintails Sparkle"
	H.hair_color = "FFFFFF"
	H.gradient_style = null
	H.update_hair()
	playsound(loc, 'sound/items/welder2.ogg', 20, TRUE)
	qdel(src)
