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
		/datum/action/item_action/sparkle_summon_gun,
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
	user.eye_color = target.eye_color
	user.underwear = target.underwear
	user.underwear_color = target.underwear_color
	user.updateappearance()

	// Set hair after updateappearance so DNA does not override
	user.hairstyle = target.hairstyle
	user.hair_color = target.hair_color
	user.facial_hairstyle = target.facial_hairstyle
	user.facial_hair_color = target.facial_hair_color
	user.gradient_style = target.gradient_style
	user.gradient_color = target.gradient_color
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
	else
		// Target has no armor — hide outfit visually
		icon_state = ""
		flags_inv = NONE
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

	// Copy ID/PDA data — disguise even if target has no ID/PDA
	var/obj/item/card/id/user_id = user.get_idcard(TRUE)
	if(user_id)
		var/obj/item/card/id/target_id = target.get_idcard(TRUE)
		if(target_id)
			user_id.registered_name = target_id.registered_name
			user_id.assignment = target_id.assignment
			if(target_id.registered_account)
				user_id.registered_account = target_id.registered_account
		else
			// Target has no ID — use target's name so user's real identity is hidden
			user_id.registered_name = target.real_name
			user_id.assignment = "Civilian"
		user_id.update_label()

	var/obj/item/pda/user_pda = user.get_item_by_slot(ITEM_SLOT_ID)
	if(istype(user_pda))
		var/obj/item/pda/target_pda = target.get_item_by_slot(ITEM_SLOT_ID)
		if(istype(target_pda))
			user_pda.owner = target_pda.owner
			user_pda.ownjob = target_pda.ownjob
		else
			// Target has no PDA — use target's name so user's real identity is hidden
			user_pda.owner = target.real_name
			user_pda.ownjob = "Civilian"
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

// --- Sparkle Gun (Volatile Sparkler) ---

/obj/projectile/ego_bullet/sparkle_bullet
	name = "sparkle round"
	damage = 18
	damage_type = RED_DAMAGE

/obj/item/ego_weapon/ranged/sparkle_gun
	name = "Volatile Sparkler"
	desc = "A compact white and red signal pistol with diagonal crimson stripes along the barrel and a red sparkle emblem on the grip. It feels dangerously festive."
	icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/enders_sprites_left.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/enders_sprites_right.dmi'
	icon_state = "sparkle_gun"
	inhand_icon_state = "sparkle_gun"
	projectile_path = /obj/projectile/ego_bullet/sparkle_bullet
	fire_delay = 4
	shotsleft = 6
	reloadtime = 1.2 SECONDS
	fire_sound = 'sound/weapons/gun/pistol/shot.ogg'
	vary_fire_sound = FALSE
	fire_sound_volume = 70
	force = 5
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 80
	)
	/// Which shot number (1-6) is the elation bullet. 0 = not yet assigned
	var/elation_bullet = 0
	/// Tracks which shot we're on in the current magazine
	var/current_shot = 0
	/// Whether the empowered elation state is active
	var/elation_active = FALSE
	/// Timer ID for ending the elation state
	var/elation_timer_id = null
	/// Whether the next melee hit gets a damage buff from a non-elation self-shot
	var/damage_buff = FALSE
	/// Stored original force value to restore after elation ends
	var/saved_force = 0

/obj/item/ego_weapon/ranged/sparkle_gun/Initialize()
	. = ..()
	elation_bullet = rand(4, 6)

/obj/item/ego_weapon/ranged/sparkle_gun/examine(mob/user)
	. = ..()
	. += span_notice("Shot [current_shot]/[initial(shotsleft)]. The elation round is somewhere in the last three chambers.")
	if(damage_buff)
		. += span_warning("Your next melee strike will be empowered!")
	if(elation_active)
		. += span_danger("ELATION is active! Melee and teleport with afterattack!")

/// Override reload — after reloading, assign a new elation bullet
/obj/item/ego_weapon/ranged/sparkle_gun/reload_ego(mob/user)
	. = ..()
	if(shotsleft == initial(shotsleft))
		elation_bullet = rand(4, 6)
		current_shot = 0

/// Override attack_self — if we have ammo, do the roulette self-shot instead of reloading
/obj/item/ego_weapon/ranged/sparkle_gun/attack_self(mob/user)
	if(elation_active)
		to_chat(user, span_warning("You can't reload during elation!"))
		return
	// If out of ammo or reloading, do normal reload
	if(shotsleft <= 0 || is_reloading)
		return ..()
	// Roulette self-shot
	INVOKE_ASYNC(src, PROC_REF(roulette_self_shot), user)

/// Points the gun at your head and pulls the trigger
/obj/item/ego_weapon/ranged/sparkle_gun/proc/roulette_self_shot(mob/living/user)
	user.visible_message(span_danger("[user] points [src] at their own head..."), span_danger("You point [src] at your head..."))
	if(!do_after(user, 1 SECONDS, src))
		to_chat(user, span_notice("You lower the gun."))
		return
	// Consume a shot
	current_shot++
	process_chamber()
	if(current_shot == elation_bullet)
		// Elation bullet — take damage and enter empowered state
		playsound(user, 'sound/weapons/gun/pistol/shot.ogg', 70, TRUE)
		user.visible_message(span_danger("[user] fires [src] into their own head! A burst of red sparks erupts!"), span_userdanger("BANG! The elation round fires! Pain and exhilaration flood through you!"))
		user.deal_damage(30, RED_DAMAGE)
		ActivateElation(user)
	else
		// Empty chamber — damage buff
		playsound(user, 'sound/weapons/gun/general/dry_fire.ogg', 50, TRUE)
		user.visible_message(span_notice("[user] pulls the trigger... *click*. Nothing happens."), span_notice("*Click*. The chamber was empty... you feel emboldened."))
		damage_buff = TRUE

/// Override process_fire — non-elation shots fire confetti, elation shot fires real bullet
/obj/item/ego_weapon/ranged/sparkle_gun/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, temporary_damage_multiplier = 1)
	if(elation_active)
		return // Can't fire during elation
	current_shot++
	if(current_shot != elation_bullet)
		// Non-elation: confetti! No damage
		if(!CanUseEgo(user))
			return
		if(semicd)
			return
		// Confetti VFX
		var/turf/target_turf = get_turf(target)
		if(target_turf)
			for(var/i in 1 to 3)
				var/obj/effect/temp_visual/sparks/S = new(target_turf)
				S.color = rgb(rand(100, 255), rand(100, 255), rand(100, 255))
		playsound(user, 'sound/items/party_horn.ogg', 50, TRUE)
		process_chamber()
		semicd = TRUE
		addtimer(CALLBACK(src, PROC_REF(reset_semicd)), fire_delay)
		user.update_inv_hands()
		return TRUE
	// Elation bullet — fire real projectile
	return ..()

/// Override afterattack — during elation, teleport instead of firing
/obj/item/ego_weapon/ranged/sparkle_gun/afterattack(atom/target, mob/living/user, flag, params)
	if(elation_active && !flag)
		// Teleport to clicked location
		var/turf/target_turf = get_turf(target)
		if(!target_turf)
			return
		var/turf/start_turf = get_turf(user)
		if(start_turf == target_turf)
			return
		// Create afterimage trail
		var/list/line_list = getline(start_turf, target_turf)
		for(var/i in 1 to length(line_list))
			var/turf/T = line_list[i]
			var/obj/effect/temp_visual/decoy/D = new(T, user)
			D.color = rgb(rand(100, 255), rand(100, 255), rand(100, 255))
			D.alpha = min(150 + i * 15, 255)
			animate(D, alpha = 0, time = 2 + i * 2)
		// Teleport
		playsound(start_turf, 'sound/effects/hokma_meltdown_short.ogg', 25, TRUE)
		user.forceMove(target_turf)
		playsound(target_turf, 'sound/effects/hokma_meltdown_short.ogg', 25, TRUE)
		return
	return ..()

/// Override melee attack — apply damage buff if active
/obj/item/ego_weapon/ranged/sparkle_gun/attack(mob/M, mob/user)
	if(damage_buff && isliving(M) && M != user)
		damage_buff = FALSE
		var/original_force = force
		force *= 3
		var/obj/effect/temp_visual/sparks/S = new(get_turf(M))
		S.color = "#FF4444"
		playsound(user, 'sound/weapons/slash.ogg', 50, TRUE)
		. = ..()
		force = original_force
		return
	return ..()

/// Activates the 8-second elation empowered state
/obj/item/ego_weapon/ranged/sparkle_gun/proc/ActivateElation(mob/living/user)
	elation_active = TRUE
	saved_force = force
	force = 35
	attack_verb_continuous = list("smashes", "bashes", "strikes")
	attack_verb_simple = list("smash", "bash", "strike")
	// Register move signal for afterimage trail
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(ElationMoveVFX))
	// VFX
	var/datum/effect_system/spark_spread/sparks = new
	sparks.set_up(6, 0, get_turf(user))
	sparks.start()
	to_chat(user, span_userdanger("ELATION! The world bursts into color!"))
	// 8 second timer
	elation_timer_id = addtimer(CALLBACK(src, PROC_REF(DeactivateElation), user), 8 SECONDS, TIMER_STOPPABLE)

/// Deactivates the elation state and forces a reload
/obj/item/ego_weapon/ranged/sparkle_gun/proc/DeactivateElation(mob/living/user)
	if(!elation_active)
		return
	elation_active = FALSE
	force = saved_force
	attack_verb_continuous = initial(attack_verb_continuous)
	attack_verb_simple = initial(attack_verb_simple)
	// Unregister move signal
	if(!QDELETED(user))
		UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
		to_chat(user, span_notice("The elation fades. The gun clicks empty."))
		var/datum/effect_system/spark_spread/sparks = new
		sparks.set_up(4, 0, get_turf(user))
		sparks.start()
	// Force reload needed
	shotsleft = 0
	forced_melee = FALSE
	elation_timer_id = null

/// Creates colorful afterimage trail when moving during elation
/obj/item/ego_weapon/ranged/sparkle_gun/proc/ElationMoveVFX(datum/source)
	SIGNAL_HANDLER
	set waitfor = FALSE
	var/mob/living/user = source
	if(QDELETED(user))
		return
	var/obj/viscon_filtereffect/distortedform_trail/trail = new(user.loc, themob = user, waittime = 5)
	trail.vis_contents += user
	trail.filters += filter(type = "drop_shadow", x = 0, y = 0, size = 3, offset = 2, color = rgb(rand(100, 255), rand(100, 255), rand(100, 255)))
	trail.filters += filter(type = "blur", size = 3)
	animate(trail, alpha = 120)
	animate(alpha = 0, time = 10)

/// Clean up elation state when dropped
/obj/item/ego_weapon/ranged/sparkle_gun/dropped(mob/living/user)
	if(elation_active)
		DeactivateElation(user)
	return ..()

/// Clean up elation on destroy
/obj/item/ego_weapon/ranged/sparkle_gun/Destroy()
	if(elation_timer_id)
		deltimer(elation_timer_id)
		elation_timer_id = null
	return ..()

// Action datum for summoning the Volatile Sparkler
/datum/action/item_action/sparkle_summon_gun
	name = "Summon Volatile Sparkler"
	desc = "Summon a compact signal pistol to your hands."
	button_icon_state = "monodrama"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'
	/// Reference to the summoned gun
	var/obj/item/ego_weapon/ranged/sparkle_gun/summoned_gun

/datum/action/item_action/sparkle_summon_gun/Trigger()
	if(!istype(target, /obj/item/clothing/suit/armor/ego_gear/sparkle_outfit))
		return
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/user = owner

	// If we already have a gun and it's in our hands, put it away
	if(summoned_gun && !QDELETED(summoned_gun))
		if(summoned_gun in user.held_items)
			qdel(summoned_gun)
			summoned_gun = null
			to_chat(user, span_notice("The Volatile Sparkler dissipates."))
			return
		// Gun exists but not in hands — try to re-equip it
		if(user.put_in_hands(summoned_gun))
			to_chat(user, span_notice("You draw the Volatile Sparkler."))
			return
		// Can't equip — destroy and recreate
		qdel(summoned_gun)
		summoned_gun = null

	// Create a new gun
	summoned_gun = new /obj/item/ego_weapon/ranged/sparkle_gun(user)
	if(user.put_in_hands(summoned_gun))
		playsound(user, 'sound/magic/summon_magic.ogg', 30, TRUE)
		to_chat(user, span_notice("You summon the Volatile Sparkler."))
	else
		to_chat(user, span_warning("Your hands are full!"))
		qdel(summoned_gun)
		summoned_gun = null

/datum/action/item_action/sparkle_summon_gun/Remove(mob/living/L)
	if(summoned_gun && !QDELETED(summoned_gun))
		qdel(summoned_gun)
		summoned_gun = null
	return ..()

// --- Sparkle Fumo ---

/obj/item/toy/plush/sparkle_fumo
	name = "Sparkle Fumo"
	desc = "A soft plush doll of a girl in a red kimono. She has a simple, pleasant smile."
	icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'
	icon_state = "sparkle_plush"

// --- Sparkle Bomb Dolls ---
// Structures that appear as plush dolls but trigger dialog sequences when interacted with.
// After dialog completes, they reveal they are not real bombs and become normal plush items.

/obj/structure/sparkle_bomb_doll
	name = "suspicious doll"
	desc = "A plush doll sitting innocently on the ground. It looks like it might have something to say."
	icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'
	icon_state = "sparkle_plush"
	density = FALSE
	anchored = TRUE
	/// Whether dialog is currently running
	var/in_dialog = FALSE
	/// The mob currently in dialog
	var/mob/living/dialog_user
	/// Flag to advance dialog early when user clicks during a wait
	var/advance_dialog = FALSE
	/// Whether dialog has completed
	var/dialog_complete = FALSE

/obj/structure/sparkle_bomb_doll/attack_hand(mob/living/user)
	if(dialog_complete)
		return
	if(in_dialog)
		if(user == dialog_user)
			advance_dialog = TRUE
		return
	in_dialog = TRUE
	dialog_user = user
	INVOKE_ASYNC(src, PROC_REF(RunDialog), user)

/// Returns TRUE if dialog can continue
/obj/structure/sparkle_bomb_doll/proc/can_continue()
	return !QDELETED(src) && !QDELETED(dialog_user)

/// Override in subtypes to define the dialog sequence
/obj/structure/sparkle_bomb_doll/proc/RunDialog(mob/living/user)
	EndDialog()

/// The doll says a line out loud, then waits
/obj/structure/sparkle_bomb_doll/proc/say_line(text, delay_time = 2 SECONDS)
	if(!can_continue())
		return
	say(text)
	DialogWait(delay_time)

/// Shows narration text to the dialog user only
/obj/structure/sparkle_bomb_doll/proc/narrate(text, delay_time = 2 SECONDS)
	if(!can_continue())
		return
	to_chat(dialog_user, span_notice("<i>[text]</i>"))
	DialogWait(delay_time)

/// Waits for the specified duration or until the user clicks to advance
/obj/structure/sparkle_bomb_doll/proc/DialogWait(delay_time = 2 SECONDS)
	advance_dialog = FALSE
	var/end_time = world.time + delay_time
	while(world.time < end_time && !advance_dialog && !QDELETED(src))
		sleep(2)
	advance_dialog = FALSE

/// Prompts the dialog user with choices, returns the selected string
/obj/structure/sparkle_bomb_doll/proc/prompt_choice(mob/living/user, list/choices)
	if(!can_continue() || !length(choices))
		return null
	var/chosen = input(user, "Choose a response:", name) as null|anything in choices
	if(!chosen)
		chosen = choices[1]
	if(can_continue())
		visible_message(span_notice("<b>[user]</b> responds, \"[chosen]\""))
	return chosen

/// Ends the dialog and converts the structure into a normal sparkle fumo plush
/obj/structure/sparkle_bomb_doll/proc/EndDialog()
	var/turf/T = get_turf(src)
	if(T)
		var/final_name = name
		var/obj/item/toy/plush/sparkle_fumo/P = new(T)
		P.name = final_name
	dialog_complete = TRUE
	qdel(src)

// --- "Constable" Doll (Zwei-themed) ---

/obj/structure/sparkle_bomb_doll/constable
	name = "\"Constable\" Doll"
	desc = "A plush doll wearing a tiny blue constable uniform. It radiates self-importance."

/obj/structure/sparkle_bomb_doll/constable/RunDialog(mob/living/user)
	say_line("You've finally arrived! I am the constable around these parts, and right now I'm posing as a bomb!")
	if(!can_continue())
		return
	var/choice = prompt_choice(user, list(
		"You're not very good at disguises, are you?",
		"Are you really a bomb?"
	))
	if(!can_continue())
		return
	if(choice == "Are you really a bomb?")
		say_line("I'm about to explode, and that's all you're concerned about?")
		if(!can_continue())
			return
		say_line("All right. Now that you've found me, it's my turn to complete my mission. I'll count down from five, and then explode!")
		ConstableCountdown(user)
		return
	// "You're not very good at disguises" path
	say_line("What do you know? This is called foreshadowing!")
	if(!can_continue())
		return
	prompt_choice(user, list("Bombs are playable characters now?"))
	if(!can_continue())
		return
	say_line("You don't like it? Fine. I'm now the Bomb Devil then.")
	name = "\"Bomb Devil\" Doll"
	if(!can_continue())
		return
	say_line("Satisfied? If not, you'll just have to make do. Now that you've found me, it's my turn to complete my mission. I'll count down from five, and then explode!")
	ConstableCountdown(user)

/obj/structure/sparkle_bomb_doll/constable/proc/ConstableCountdown(mob/living/user)
	if(!can_continue())
		return
	say_line("Five...")
	say_line("Four...")
	say_line("One...!")
	if(!can_continue())
		return
	prompt_choice(user, list("Where's three?", "Where's two?"))
	if(!can_continue())
		return
	if(name == "\"Bomb Devil\" Doll")
		say_line("Did I miss a number? Oh, so I did. No matter though, I've never learned how to count — I mean, Bomb Devil doll has never learned how to count.")
		if(!can_continue())
			return
		say_line("I'm not even a real bomb! Was it surprising, shocking, horrifying? No? Really? Fine. That's too bad then.")
	else
		say_line("Is it really that important? I'm not even a real bomb!")
		if(!can_continue())
			return
		say_line("Was it surprising, shocking, horrifying? No? Really? Fine. That's too bad then.")
	narrate("The [name] finally falls silent. You open it up and uncover its true nature — a mere toy equipped with a remote speaker.")
	EndDialog()

// --- "Detective" Doll (Seven-themed) ---

/obj/structure/sparkle_bomb_doll/detective
	name = "\"Detective\" Doll"
	desc = "A plush doll wearing a miniature investigator's coat. It has a magnifying glass stitched to one hand."

/obj/structure/sparkle_bomb_doll/detective/RunDialog(mob/living/user)
	say_line("Ha, so we meet. I am the City's famed detective.")
	if(!can_continue())
		return
	say_line("Got yourself into a pickle? I'm more than happy to help, but unfortunately, I'm preoccupied with a couple of unsolved cases... So, you'll have to wait your turn.")
	if(!can_continue())
		return
	prompt_choice(user, list(
		"I just need that bomb in your hands.",
		"You're telling me your case is related to the bomb?",
		"I need your help finding a bomb."
	))
	if(!can_continue())
		return
	say_line("Bomb? Drat... It completely slipped my mind!")
	if(!can_continue())
		return
	say_line("I need your help. You seem like you have a sharp eye. Help me connect the evidence between these two cases, and I'll tell you about the bomb.")
	say_line("The first case is a factory arson in the Backstreets. We found a wrench, a doll, and half a liter of unidentified fluid at the scene. Forensics confirmed: the fluid was a red herring.")
	say_line("The second case is an auction robbery in District 10. Thieves broke in, stole a prototype ampule, and left behind a wrench, a doll, and a half-dead red herring at the scene.")
	say_line("Those are all the details. There must be a link between these two cases. Which piece of evidence do you think is the deciding one?")
	if(!can_continue())
		return
	var/evidence = prompt_choice(user, list(
		"The wrench.",
		"The doll.",
		"The red herring.",
		"The bomb.",
		"It's you — you were at both crime scenes!"
	))
	if(!can_continue())
		return
	if(evidence == "It's you — you were at both crime scenes!")
		say_line("Correct! You're good. Your mind is pretty sharp!")
		if(!can_continue())
			return
		say_line("Seeing as you've put in the effort, I'll throw you a bone: The bomb's not here. This is only a prank I've craftily set up. You'd better look elsewhere!")
	else
		if(evidence == "The wrench.")
			say_line("Wrong answer! The wrench is a tool, but neither case is about construction work!")
		else if(evidence == "The doll.")
			say_line("Wrong answer! The dolls at the two scenes are modeled after different people — they're not the same!")
		else if(evidence == "The red herring.")
			say_line("Wrong answer! A \"red herring\" is a fake clue to misdirect. It's not meant to be evidence!")
		else
			say_line("Wrong answer! Neither case mentions a bomb. Are you imagining things?")
		if(!can_continue())
			return
		say_line("It's been a while since I've had a visitor, and you haven't impressed me at all. I'm sorely disappointed...")
		if(!can_continue())
			return
		say_line("But, seeing as you've put in the effort, I'll throw you a bone: The bomb's not here. This is only a prank I've craftily set up. You'd better look elsewhere!")
	narrate("The detective doll's voice fades, leaving behind a body buzzing with white noise. It seems this pitiful doll was nothing more than a makeshift megaphone.")
	EndDialog()

// --- "Inventor" Doll (District 20 / T Corp.-themed) ---

/obj/structure/sparkle_bomb_doll/inventor
	name = "\"Inventor\" Doll"
	desc = "A plush doll wearing tiny goggles and a leather apron stained with soot. It clutches a miniature patent document."

/obj/structure/sparkle_bomb_doll/inventor/RunDialog(mob/living/user)
	say_line("Ah, a visitor! Welcome, welcome! I am a certified Grade 1 Inventor, holder of Patent Number 7,204,881-T!")
	if(!can_continue())
		return
	var/choice = prompt_choice(user, list(
		"What did you invent?",
		"I don't care about patents. Are you a bomb?"
	))
	if(!can_continue())
		return
	if(choice == "I don't care about patents. Are you a bomb?")
		say_line("A bomb? Please! I am a PATENTED explosive device! There's a very important legal distinction!")
		if(!can_continue())
			return
		say_line("Do you have any idea how long the Technology Administration Agency takes to process a patent? Seven months! And that's WITH expedited processing!")
	else
		say_line("What did I invent? Only the most revolutionary device the City has ever seen!")
		if(!can_continue())
			return
		say_line("I submitted my patent application in triplicate, paid the filing fee of 340,000 Ahn — which, by the way, is highway robbery — and waited seven agonizing months!")
	if(!can_continue())
		return
	say_line("The examiner had the audacity to ask me, 'Is this not just a toaster?' A TOASTER! Can a toaster detonate with the force of an imaginary neutron bomb?")
	if(!can_continue())
		return
	prompt_choice(user, list(
		"Can it?",
		"It IS just a toaster, isn't it?"
	))
	if(!can_continue())
		return
	say_line("...Well, no. Technically speaking, it cannot. The patent was, in fact, approved under the category of 'small kitchen appliances.'")
	say_line("But that's beside the point! The INTENT was explosive! The spirit of innovation cannot be constrained by mere bureaucratic categories!")
	if(!can_continue())
		return
	say_line("In any case, I am most certainly not a real bomb. I am a patented toaster with delusions of grandeur. There's a difference!")
	narrate("The \"Inventor\" Doll winds down with a final self-satisfied huff. Inside, you find nothing but cotton stuffing and a crumpled patent rejection letter.")
	EndDialog()

// --- "Sweeper" Doll (Night in the Backstreets-themed) ---

/obj/structure/sparkle_bomb_doll/sweeper
	name = "\"Sweeper\" Doll"
	desc = "A plush doll shaped like a humanoid metal tank. It has a fixed grin painted on its faceplate."

/obj/structure/sparkle_bomb_doll/sweeper/RunDialog(mob/living/user)
	say_line("ATTENTION. ATTENTION. This unit is Sweeper Model S-0771. Current time: approaching 3:13 AM. The Night will begin shortly.")
	if(!can_continue())
		return
	var/choice = prompt_choice(user, list(
		"It's not nighttime.",
		"You're a doll, not a Sweeper.",
		"Should I be worried?"
	))
	if(!can_continue())
		return
	if(choice == "It's not nighttime.")
		say_line("IRRELEVANT. This unit operates on its own internal clock. According to my calculations, the Night begins in approximately... now.")
	else if(choice == "You're a doll, not a Sweeper.")
		say_line("INCORRECT. This unit has been freshly converted from human material into a fully operational — ...cotton-based patrol unit.")
	else
		say_line("AFFIRMATIVE. You should be very worried. This unit will now begin consumption protocol.")
	if(!can_continue())
		return
	say_line("First wave: Initiated. All organic material in the vicinity will be consumed.")
	say_line("Consumption in progress... consumption in progress...")
	say_line("...")
	say_line("ERROR. Consumption module not found. This unit appears to lack a digestive system.")
	if(!can_continue())
		return
	prompt_choice(user, list(
		"Because you're made of cotton.",
		"That must be very inconvenient."
	))
	if(!can_continue())
		return
	say_line("ACKNOWLEDGED. This unit concedes that it may, in fact, be a plush doll and not a genuine Sweeper unit.")
	say_line("Second wave: Cancelled. Third wave: Also cancelled. The Night is hereby postponed indefinitely.")
	if(!can_continue())
		return
	say_line("This unit recommends you stay indoors regardless. Not because of Sweepers. Simply because the Backstreets are unpleasant.")
	narrate("The \"Sweeper\" Doll emits one final burst of static before going silent. Inside, you find a tiny music box that was playing pre-recorded announcements.")
	EndDialog()

// --- "Furmur" Doll (the silent starer) ---

/obj/structure/sparkle_bomb_doll/furmur
	name = "\"Furmur\" Doll"
	desc = "A plush doll that is staring directly at you. Its expression is unreadable."

/obj/structure/sparkle_bomb_doll/furmur/RunDialog(mob/living/user)
	narrate("The \"Furmur\" doll is staring right at you.")
	if(!can_continue())
		return
	prompt_choice(user, list(
		"Can I dismantle your bomb?",
		"Stare back."
	))
	if(!can_continue())
		return
	narrate("The \"Furmur\" doll continues to stare right at you.")
	if(!can_continue())
		return
	prompt_choice(user, list(
		"Can you speak, please?",
		"Continue to stare back."
	))
	if(!can_continue())
		return
	narrate("The \"Furmur\" doll's eyes never blink. Honestly, if they did, it would be quite unsettling.")
	narrate("Anyway, it's just an ordinary plush toy. Can you really expect it to utter a single word?")
	if(!can_continue())
		return
	prompt_choice(user, list(
		"If you don't speak, your silence means consent.",
		"Keep staring at it."
	))
	if(!can_continue())
		return
	narrate("It must be pointed out that this doll has no suspicious features at all. It exudes an aura befitting of a doll, not that of a bomb.")
	narrate("...which means there is no need to bother it anymore. It's best to put an end to this farce.")
	EndDialog()

// --- "Fool" Doll ---

/obj/structure/sparkle_bomb_doll/fool
	name = "\"Fool\" Doll"
	desc = "A plush doll with a cheerful grin and a tiny jester's cap. It seems eager to please."

/obj/structure/sparkle_bomb_doll/fool/RunDialog(mob/living/user)
	say_line("Hello, I'm a bomb! There's still some time before I explode, so you can take a look around first!")
	if(!can_continue())
		return
	var/choice = prompt_choice(user, list(
		"I'm here to defuse you.",
		"All right. I'll go take a look around then.",
		"Can I just wait around here for a moment?"
	))
	if(!can_continue())
		return
	if(choice == "I'm here to defuse you.")
		say_line("Defuse? No problem! Executing self-defusing program — this won't take long!")
	else if(choice == "All right. I'll go take a look around then.")
		say_line("That's no problem of course! But if you don't want to go too far, I can also play a soothing tune for you in case you get bored!")
	else
		say_line("We do not have this function called \"Wait Around\"! But it's no problem — to ease any boredom during your wait, I can play a soothing song for you!")
	if(!can_continue())
		return
	say_line("Now playing Never Give Up, Never Surrender by the trending superstar Ast Rickley from the Streets of Music...")
	say_line("...Oh, hang on, this District's Wing has not purchased the rights to this song — we can't play it here. How about this, I'll recite it for you — next up, please enjoy a recital of Never Give Up, Never Surrender!")
	if(!can_continue())
		return
	say_line("O Aha! If you ask me how I feel about you, don't tell me that you pretend not to see!")
	say_line("THEY will never give you up, never make you sad! THEY will never give you up, never make you cry!")
	say_line("THEY will never say goodbye to you, never tell lies to hurt you — praise Aha!")
	narrate("After the almost tearful exclamation of \"Praise Aha!\" comes to pass, all that's left in the doll's mouth is the lingering echo of an irritating cassette tape. Turns out it isn't a bomb after all, but a vintage tape recorder.")
	EndDialog()

// --- "Outlaw" Doll ---

/obj/structure/sparkle_bomb_doll/outlaw
	name = "\"Outlaw\" Doll"
	desc = "A plush doll wearing a tiny leather jacket and an eyepatch. It smells faintly of the Backstreets."

/obj/structure/sparkle_bomb_doll/outlaw/RunDialog(mob/living/user)
	say_line("Welcome to the Backstreets, stranger! I am a dangerous bomb, and an outlaw who despises law and order. May you have a splendid day!")
	if(!can_continue())
		return
	var/choice = prompt_choice(user, list(
		"You're pretty polite.",
		"I'm guessing you're also not a real bomb.",
		"You don't look or sound that dangerous."
	))
	if(!can_continue())
		return
	if(choice == "You're pretty polite.")
		say_line("Thank you, but courtesy doesn't hide my hazardous lunacy. If you're unconvinced, let me show you: Go fudge yourself, you muddle-fudger!")
	else if(choice == "I'm guessing you're also not a real bomb.")
		say_line("I'm not, but so what? I'm still crazy and dangerous. In case you don't believe me, allow me to show you: Go fudge yourself, you muddle-fudger!")
	else
		say_line("Really? Fork you. If you think this isn't intense enough, I don't mind showing you what real danger and madness look like.")
	if(!can_continue())
		return
	say_line("To be frank, I didn't become an outlaw because I'm a fudgin' bomb. It's because I'm the fudgin' owner of an ancient, mad, forbidden curse.")
	say_line("Care to experience it? I can chant it for you, but Miss Sparkle won't be responsible for any of the consequences.")
	if(!can_continue())
		return
	var/choice2 = prompt_choice(user, list(
		"Let's see what you've got!",
		"Forget it. I value my life too much."
	))
	if(!can_continue())
		return
	if(choice2 == "Let's see what you've got!")
		say_line("Holy fudge, you're more insane than I am! Let me gather my wits...")
	else
		say_line("Oh? You scared, lil' fudgehead? It's too late, I tell you! You've already opened Pandora's box...")
	if(!can_continue())
		return
	say_line("...The ritual is ready. Perk up your ears and listen closely to the most ancient, primal fear etched into the very fudgin' genes of humanity —")
	say_line("Bloomska, boomska, little sparkleeesss!!! Bloomska, boomska, little sparkleeesss!!!")
	narrate("The striking resemblance to the jingle of a legendary children's cartoon instantly rings an alarm within you! Profound muscle memory prompts you to swing your arms in a wide arc, catapulting the doll into the air.")
	narrate("If the doll's words just now are not false, then indeed there won't be a bomb going off anytime soon. No need to worry...?")
	EndDialog()

// --- "Fixer" Doll (Grade 9 incompetence) ---

/obj/structure/sparkle_bomb_doll/fixer
	name = "\"Fixer\" Doll"
	desc = "A plush doll wearing a threadbare coat and a crooked Hana-issued badge. The badge looks expired."

/obj/structure/sparkle_bomb_doll/fixer/RunDialog(mob/living/user)
	say_line("Halt! I am a licensed Fixer, Grade 9, and I'm here to handle this bomb threat!")
	say_line("First things first — I need to assess the hazard level. Let me consult the Hana classification system...")
	if(!can_continue())
		return
	say_line("Hmm... A bomb... that would be... Urban Myth? No, wait — Urban Legend? No, that's for sewer creatures...")
	if(!can_continue())
		return
	var/choice = prompt_choice(user, list(
		"You have no idea what you're doing, do you?",
		"Take your time."
	))
	if(!can_continue())
		return
	if(choice == "You have no idea what you're doing, do you?")
		say_line("Excuse me! I graduated — well, I ALMOST graduated from the Hana licensing program! I failed the exam three times, but the fourth attempt is going great so far!")
	else
		say_line("Thank you for your patience. Most people aren't this understanding. My last three clients fired me before I even got through the assessment form.")
	if(!can_continue())
		return
	say_line("Let me try again. A bomb in the field... that's at LEAST an Urban Plague. Actually, you know what? I'm going to classify this as Star of the City. Go big or go home!")
	if(!can_continue())
		return
	prompt_choice(user, list(
		"Star of the City? For a doll?",
		"Isn't that a bit much?"
	))
	if(!can_continue())
		return
	say_line("You're right, you're right. I always overdo it. My Office went bankrupt because I classified a stray cat as Impuritas Civitatis and called in an Arbiter. We still owe damages.")
	say_line("Okay, let me just file a proper report instead. I'll need a pen and form H-7B and — oh.")
	say_line("...I don't have hands. I'm a doll.")
	if(!can_continue())
		return
	say_line("You know what, I'm going to level with you. I can't grade something that isn't a real threat. And this? This isn't a real bomb. I may be Grade 9, but even I can tell that much.")
	narrate("The \"Fixer\" Doll slumps forward, defeated by its own incompetence. Inside, you find a crumpled, half-filled Hana assessment form with every box checked incorrectly.")
	EndDialog()

// --- "Gambler" Doll (District 10 / J Corp) ---

/obj/structure/sparkle_bomb_doll/gambler
	name = "\"Gambler\" Doll"
	desc = "A plush doll wearing a tiny sequined vest and holding a miniature Fortune Wheel. Its grin is unsettlingly confident."

/obj/structure/sparkle_bomb_doll/gambler/RunDialog(mob/living/user)
	say_line("Welcome, welcome! You've just stepped into the Nest of Gambling, and in this Nest, ALL decisions are made by the Fortune Wheel!")
	if(!can_continue())
		return
	var/choice = prompt_choice(user, list(
		"Fine, spin the wheel.",
		"I'd rather just know if you're a bomb.",
		"Why does everything need a wheel?"
	))
	if(!can_continue())
		return
	if(choice == "Why does everything need a wheel?")
		say_line("Why? Because luck is the only fair judge in this City! The Fortune Wheel doesn't care about your District, your Wing, or your grade. It only cares about probability!")
	else if(choice == "I'd rather just know if you're a bomb.")
		say_line("Know? KNOW?! In District 10, we don't 'know' things. We GAMBLE on things! Much more exciting!")
	else
		say_line("That's the spirit! Nothing ventured, nothing gained!")
	if(!can_continue())
		return
	say_line("The question before the Wheel: Is this doll a bomb? Spinning now...")
	say_line("...And it lands on: 'Not a bomb.' Well! Best of three, obviously.")
	if(!can_continue())
		return
	say_line("Spinning again... 'Still not a bomb.' Hmph. Best of five, then!")
	say_line("Spinning... 'Definitely not a bomb.' This wheel is clearly malfunctioning.")
	if(!can_continue())
		return
	var/choice2 = prompt_choice(user, list(
		"You rigged this, didn't you?",
		"Just accept the results."
	))
	if(!can_continue())
		return
	if(choice2 == "You rigged this, didn't you?")
		say_line("Rigged?! I would NEVER — okay, fine. Every slot on the wheel says 'Not a bomb.' I may have had a hand in the design.")
	else
		say_line("Accept? A true gambler never accepts! But... fine. The evidence is overwhelming. Every slot on the wheel says 'Not a bomb.' I designed it myself.")
	if(!can_continue())
		return
	say_line("The house always wins. And the house says: no bomb. I also owe you a refund for the three spins, but I'm a doll with no money. So... take it up with the Oufi Association?")
	narrate("The \"Gambler\" Doll's Fortune Wheel clatters to the ground. Upon inspection, every single slot reads \"Not a bomb\" in increasingly fancy handwriting.")
	EndDialog()

// --- "Salesperson" Doll (K Corp) ---

/obj/structure/sparkle_bomb_doll/salesperson
	name = "\"Salesperson\" Doll"
	desc = "A plush doll in a pristine emerald-green suit. It has a name tag that reads 'Employee of the Month' in glittery letters."

/obj/structure/sparkle_bomb_doll/salesperson/RunDialog(mob/living/user)
	say_line("CONGRATULATIONS! You've been selected for an EXCLUSIVE, once-in-a-lifetime security consultation!")
	if(!can_continue())
		return
	var/choice = prompt_choice(user, list(
		"Just tell me about the bomb.",
		"What's the deal?"
	))
	if(!can_continue())
		return
	if(choice == "Just tell me about the bomb.")
		say_line("The bomb? Great question! Did you know that 9 out of 10 bomb-adjacent casualties could have been prevented with K Corp. HP Ampules? Only 5,000 Ahn per vial!")
	else
		say_line("I'm SO glad you asked! For a limited time, K Corp. is offering the Bomb Survival Starter Pack: three HP Ampules and a commemorative tote bag for just 12,000 Ahn!")
	if(!can_continue())
		return
	say_line("But why stop there? For an additional 80,000 Ahn per month, you can upgrade to our Premium Life Insurance policy! Brain intact? We'll have you back on your feet in no time!")
	if(!can_continue())
		return
	var/choice2 = prompt_choice(user, list(
		"I'm not buying anything.",
		"How much for the bomb defusal?"
	))
	if(!can_continue())
		return
	if(choice2 == "How much for the bomb defusal?")
		say_line("Excellent question! Our Premium Bomb Defusal Package is available for the low, low price of 4,000,000 Ahn! That includes the defusal itself, a post-defusal wellness check, AND a complimentary doll — that's me!")
	else
		say_line("Not buying? But this is a LIMITED-TIME offer! The bomb could go off at any moment! ...Allegedly! Don't you want to be PREPARED?")
	if(!can_continue())
		return
	say_line("Okay, okay. Full disclosure — there is no bomb. This entire scenario was a customer acquisition strategy designed to create a sense of urgency.")
	say_line("The K Corp. marketing division calls it 'Explosive Savings Event.' I call it my Tuesday.")
	narrate("The \"Salesperson\" Doll powers down mid-pitch, a tiny K Corp. business card falling from its hand. The card reads: \"For all your post-explosion recovery needs!\"")
	EndDialog()

// --- "Rat" Doll (Backstreets lowest rung) ---

/obj/structure/sparkle_bomb_doll/rat
	name = "\"Rat\" Doll"
	desc = "A plush doll that looks like it's been through a lot. Its tiny coat is patched and its button eyes are mismatched."

/obj/structure/sparkle_bomb_doll/rat/RunDialog(mob/living/user)
	say_line("H-Hey! Don't come any closer! I'm a very dangerous bomb! I work for the Five Fingers, and they sent me here personally!")
	if(!can_continue())
		return
	var/choice = prompt_choice(user, list(
		"Which Finger?",
		"You don't look dangerous."
	))
	if(!can_continue())
		return
	if(choice == "Which Finger?")
		say_line("Which Finger? The, uh... the Thumb! Yeah, the Thumb sent me! ...No wait, it was the Index. Actually — the Middle! Definitely the Middle. They value courtesy, and I'm very courteous!")
	else
		say_line("Not dangerous?! I'll have you know I once — okay, I've never actually done anything dangerous. But I COULD! I'm affiliated with... the Thumb! No — the Index! The Middle? One of them!")
	if(!can_continue())
		return
	var/choice2 = prompt_choice(user, list(
		"You're making this up.",
		"Sure, I believe you."
	))
	if(!can_continue())
		return
	if(choice2 == "Sure, I believe you.")
		say_line("You... you do? Really? Nobody's ever — ...No. No, you're being sarcastic, aren't you. I can tell. Even the other Rats can tell when someone's being sarcastic.")
	else
		say_line("...Yeah. Yeah, I'm making it up. I'm not with any Finger. I'm just a Rat. The lowest of the low. You know what Rats are? We're the people that even the Syndicates won't recruit.")
	if(!can_continue())
		return
	say_line("I just... I thought if I pretended to be a bomb, someone would actually pay attention to me. Just once. In the Backstreets, nobody looks at you unless you're a threat.")
	if(!can_continue())
		return
	var/choice3 = prompt_choice(user, list(
		"That's actually kind of sad.",
		"You could try being something other than a bomb."
	))
	if(!can_continue())
		return
	if(choice3 == "That's actually kind of sad.")
		say_line("...You think so? Heh. That might be the nicest thing anyone's said to me. Most people just kick me into the gutter.")
	else
		say_line("Something other than a bomb? Like what, a Fixer? Ha! You need augmentations for that, and I can't even afford dinner.")
	if(!can_continue())
		return
	say_line("Anyway... thanks for talking to me. You're the first person who's actually stuck around this long. I'm not a bomb, obviously. I'm just... lonely.")
	narrate("The \"Rat\" Doll falls quiet, its mismatched button eyes somehow looking a little less sad than before. It's not a bomb — just a doll that wanted someone to talk to.")
	EndDialog()

// --- "Messenger" Doll (Index Finger) ---

/obj/structure/sparkle_bomb_doll/messenger
	name = "\"Messenger\" Doll"
	desc = "A plush doll carrying a tiny sealed scroll. It has an air of absolute, unshakeable authority."

/obj/structure/sparkle_bomb_doll/messenger/RunDialog(mob/living/user)
	say_line("Halt. I carry an official Prescript from the Index Finger. You are hereby REQUIRED to follow its instructions. Failure to comply will have... consequences.")
	if(!can_continue())
		return
	var/choice = prompt_choice(user, list(
		"Let's hear it.",
		"I don't follow Prescripts."
	))
	if(!can_continue())
		return
	if(choice == "I don't follow Prescripts.")
		say_line("You don't follow Prescripts? How bold. How reckless. How... irrelevant, because I'm going to read it to you anyway. That IS the consequence.")
	else
		say_line("A wise decision. The Index Finger smiles upon the obedient. Metaphorically. Fingers don't actually smile.")
	if(!can_continue())
		return
	say_line("Prescript, Article 47, Section 12. Step One: Face the nearest wall and state your full name and favorite color.")
	if(!can_continue())
		return
	var/step1 = prompt_choice(user, list(
		"Fine. I'll do it.",
		"That's ridiculous."
	))
	if(!can_continue())
		return
	if(step1 == "Fine. I'll do it.")
		say_line("Very good. The wall has acknowledged your existence. Probably.")
	else
		say_line("Ridiculous? The Prescript does not recognize the concept of 'ridiculous.' Noted and ignored. Moving on.")
	if(!can_continue())
		return
	say_line("Step Two: Perform three respectful bows to the doll — that's me.")
	if(!can_continue())
		return
	var/step2 = prompt_choice(user, list(
		"...Fine.",
		"Absolutely not."
	))
	if(!can_continue())
		return
	if(step2 == "...Fine.")
		say_line("One... two... three. Excellent. Your form could use work, but the Prescript accepts it.")
	else
		say_line("Your defiance has been noted. It will be filed alongside all other defiances, in a very large cabinet, which no one checks.")
	if(!can_continue())
		return
	say_line("Step Three: Declare aloud that the Prescript is wise and just.")
	if(!can_continue())
		return
	var/step3 = prompt_choice(user, list(
		"The Prescript is wise and just.",
		"The Prescript is nonsense."
	))
	if(!can_continue())
		return
	if(step3 == "The Prescript is wise and just.")
		say_line("The Prescript thanks you for your honesty.")
	else
		say_line("The Prescript has chosen to interpret that as a compliment.")
	if(!can_continue())
		return
	say_line("The ritual is complete. As per Article 47, Section 12, Final Clause: this doll is hereby officially declared NOT a bomb.")
	say_line("The outcome was the same regardless of your choices, by the way. The Index Finger works in mysterious ways.")
	narrate("The \"Messenger\" Doll neatly rolls up its tiny scroll and goes still. The Prescript, upon closer inspection, is just a grocery list written in very authoritative handwriting.")
	EndDialog()

// --- "Time Collector" Doll (District 20 / T Corp) ---

/obj/structure/sparkle_bomb_doll/time_collector
	name = "\"Time Collector\" Doll"
	desc = "A plush doll in a sepia-toned uniform clutching a miniature ledger. A tiny pocket watch is stitched to its chest."

/obj/structure/sparkle_bomb_doll/time_collector/RunDialog(mob/living/user)
	say_line("Good day. I am an authorized Time Collector, District 20, Badge Number TC-4401. You have outstanding charges on your account.")
	if(!can_continue())
		return
	say_line("The charges are as follows: Time Tax, base rate. Bomb Proximity Surcharge. Conversation Processing Fee. And a Late Payment Penalty.")
	if(!can_continue())
		return
	var/choice = prompt_choice(user, list(
		"I'm not paying.",
		"How much do I owe?"
	))
	if(!can_continue())
		return
	if(choice == "How much do I owe?")
		say_line("Let me calculate... Base Time Tax: 40 minutes. Bomb Proximity Surcharge: 2 hours. Processing Fee: 15 minutes. Late Penalty: 1 hour.")
		if(!can_continue())
			return
		say_line("That's 3 hours and 55 minutes. Oh, and there's a Calculation Fee for the time I just spent calculating: add another 30 minutes.")
		say_line("And a Notification Fee for informing you of the Calculation Fee: 10 more minutes. Your new total is 4 hours and 35 minutes.")
	else
		say_line("Refusal to pay has been noted. As per T Corp. Collection Protocol, I am authorized to repossess your remaining allocated lifespan.")
		if(!can_continue())
			return
		say_line("Initiating lifespan repossession... Accessing temporal ledger... Calibrating collection apparatus...")
	if(!can_continue())
		return
	say_line("...ERROR. Ledger capacity insufficient. This unit's ledger is... doll-sized. It can only hold approximately four seconds of collected time.")
	say_line("I... I cannot actually collect anything from you. This is deeply embarrassing.")
	if(!can_continue())
		return
	var/choice2 = prompt_choice(user, list(
		"So you're not a bomb either?",
		"The real Time Collectors must be disappointed in you."
	))
	if(!can_continue())
		return
	if(choice2 == "The real Time Collectors must be disappointed in you.")
		say_line("Please don't tell them about this. The real Time Collectors are MUCH scarier. They have full-sized ledgers and absolutely no sense of humor.")
	else
		say_line("A bomb? No. I am a decommissioned tax form with a speaker taped to the back. I was repurposed for this role without my consent, much like most things in District 20.")
	if(!can_continue())
		return
	say_line("Consider your debt forgiven. Not out of kindness — I simply lack the bureaucratic infrastructure to enforce it. Good day.")
	narrate("The \"Time Collector\" Doll's pocket watch ticks one final time before going silent. Its ledger, upon inspection, contains only the entry: \"COLLECTED: 0 hours, 0 minutes, 0 seconds. STATUS: Failure.\"")
	EndDialog()

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
