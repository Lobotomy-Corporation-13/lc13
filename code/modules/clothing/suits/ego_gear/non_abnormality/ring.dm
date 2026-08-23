// The Ring - Syndicate of Artists
// Corporist School - Utilizes interaction between human bones and muscles
// "Those who utilize the interaction between human bones and muscles, and the contraction and elongation thereof."

/obj/item/clothing/suit/armor/ego_gear/city/ring_maestro
	name = "corporist maestro garb"
	desc = "Draped white robes with a gilded trim worn by a Maestro of the Corporist school."
	icon = 'icons/obj/spider_house/ring/ring_icons.dmi'
	worn_icon = 'icons/obj/spider_house/ring/ring_maestro_worn.dmi'
	icon_state = "ring_maestro"
	worn_x_dimension = 48
	worn_y_dimension = 48
	clothing_flags = LARGE_WORN_ICON
	hat = /obj/item/clothing/head/ego_hat/ring_maestro
	armor = list(RED_DAMAGE = 60, WHITE_DAMAGE = 50, BLACK_DAMAGE = 60, PALE_DAMAGE = 40)
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100
	)

/obj/item/clothing/head/ego_hat/ring_maestro
	name = "corporist maestro hat"
	desc = "A large-brimmed hat featuring a litany of holes through its brim. A signature piece of a Corporist Maestro's attire."
	icon = 'icons/obj/spider_house/ring/ring_icons.dmi'
	worn_icon = 'icons/obj/spider_house/ring/ring_maestro_worn.dmi'
	icon_state = "ring_maestro_hat"
	worn_x_dimension = 48
	worn_y_dimension = 48
	clothing_flags = LARGE_WORN_ICON

// Iron Maiden Armor - Two-phase armor that summons the Fascia weapon
// Phase 1 (Defensive): Reflects damage back on attackers and inflicts bleed. Weapon has Iron Curtain ability.
// Phase 2 (Offensive, <50% HP): Armor becomes invisible, weapon transforms into a leap-based attacker.
/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice
	name = "iron maiden armor"
	desc = "Heavy white armor with bright yellow and golden highlights, featuring a faint iridescence. Spikes protrude from the lower dress-like half, and chains hang from thick bands at the elbows. Somewhat knightly in appearance. Grants the ability to summon the Fascia weapon."
	icon_state = "ring_apprentice"
	hat = /obj/item/clothing/head/ego_hat/helmet/ring_apprentice
	armor = list(RED_DAMAGE = 50, WHITE_DAMAGE = 40, BLACK_DAMAGE = 50, PALE_DAMAGE = 20)
	slowdown = 0.75
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 80
	)

	/// Current armor phase (1 = defensive, 2 = offensive)
	var/phase = 1
	/// Phase 1 weapon reference
	var/obj/item/ego_weapon/city/ring/fascia/phase1_weapon
	/// Phase 2 weapon reference
	var/obj/item/ego_weapon/city/ring/fascia_unleashed/phase2_weapon
	/// Current wearer
	var/mob/living/carbon/human/armor_wearer
	/// Whether Iron Curtain mode is active (multiplies reflect damage)
	var/iron_curtain = FALSE
	/// Timer ID for Iron Curtain deactivation
	var/iron_curtain_timer_id
	/// Cooldown before phase 2 can trigger again after returning to phase 1 (world.time)
	var/phase2_cooldown
	/// Reference to the Reforge Iron Maiden action granted during phase 2
	var/datum/action/cooldown/reforge_iron_maiden/reforge_action
	/// Whether a ghost spirit inhabits the armor/weapon
	var/possessed = FALSE
	/// The spirit mob sheltered in the armor when no weapon is active
	var/mob/living/simple_animal/fascia_spirit/bound_spirit

/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/Initialize()
	. = ..()
	var/obj/effect/proc_holder/ability/AS = new /obj/effect/proc_holder/ability/ring_summon_fascia
	var/datum/action/spell_action/ability/item/A = AS.action
	A.SetItem(src)

/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/Destroy()
	remove_phase1_weapon()
	remove_phase2_weapon()
	remove_reforge_action()
	if(iron_curtain)
		deactivate_iron_curtain()
	bound_spirit = null
	ClearWearer()
	return ..()

/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_OCLOTHING && ishuman(user))
		armor_wearer = user
		RegisterSignal(user, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_damage_reflect))
		RegisterSignal(user, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(on_wearer_damaged))
		RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_wearer_deleted))

/// Drops the wearer reference along with the signals that depend on it
/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/proc/ClearWearer()
	if(!armor_wearer)
		return
	UnregisterSignal(armor_wearer, list(COMSIG_MOB_APPLY_DAMGE, COMSIG_MOB_AFTER_APPLY_DAMGE, COMSIG_PARENT_QDELETING))
	armor_wearer = null

/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/proc/on_wearer_deleted(datum/source)
	SIGNAL_HANDLER
	ClearWearer()

/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/relaymove(mob/living/user, direction)
	return //stops buckled message spam for the spirit

/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/dropped(mob/user)
	. = ..()
	if(armor_wearer)
		remove_phase1_weapon()
		remove_phase2_weapon()
		if(iron_curtain)
			deactivate_iron_curtain()
		if(phase == 2)
			armor_wearer.remove_movespeed_modifier(/datum/movespeed_modifier/iron_maiden_fractured)
		remove_reforge_action()
		// Spirit is already sheltered by remove_phase1/2_weapon - keep it safe in the armor
		if(bound_spirit)
			to_chat(bound_spirit, span_notice("The armor is removed. You remain sheltered within, waiting..."))
		ClearWearer()
		// Reset to phase 1
		phase = 1
		icon_state = "ring_apprentice"
		update_icon()

/// Signal handler for COMSIG_MOB_APPLY_DAMGE - reflects damage back to attacker during phase 1
/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/proc/on_damage_reflect(datum/source, damage, damagetype, def_zone, attack_source, flags, attack_type)
	SIGNAL_HANDLER
	if(phase != 1 || !armor_wearer)
		return
	if(!(attack_type & ATTACK_TYPE_MELEE))
		return
	if(!isliving(attack_source) || attack_source == armor_wearer)
		return
	INVOKE_ASYNC(src, PROC_REF(do_reflect_damage), attack_source, damage)

/// Applies reflect damage and bleed to the attacker (called async from signal handler)
/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/proc/do_reflect_damage(mob/living/attacker, damage)
	if(QDELETED(attacker) || QDELETED(armor_wearer) || attacker.stat == DEAD)
		return
	var/reflect_damage = damage * 0.1
	var/bleed_stacks = 2
	if(iron_curtain)
		reflect_damage *= 20
		bleed_stacks = 4
	attacker.deal_damage(reflect_damage, RED_DAMAGE, armor_wearer, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL | ATTACK_TYPE_COUNTER))
	attacker.apply_lc_bleed(bleed_stacks)

/// Signal handler for COMSIG_MOB_AFTER_APPLY_DAMGE - checks if wearer drops below 50% HP for phase transition
/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/proc/on_wearer_damaged(datum/source)
	SIGNAL_HANDLER
	if(phase != 1 || !armor_wearer)
		return
	if(phase2_cooldown > world.time)
		return
	if(armor_wearer.health <= (armor_wearer.maxHealth * 0.5))
		INVOKE_ASYNC(src, PROC_REF(enter_phase2))

/// Transitions the armor to phase 2 - armor becomes invisible, weapon transforms
/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/proc/enter_phase2()
	if(phase == 2)
		return
	phase = 2

	// Deactivate Iron Curtain if active
	if(iron_curtain)
		deactivate_iron_curtain()

	// Remove helmet if worn
	if(armor_wearer)
		var/obj/item/clothing/head/ego_hat/helmet/ring_apprentice/worn_helmet = armor_wearer.get_item_by_slot(ITEM_SLOT_HEAD)
		if(istype(worn_helmet))
			armor_wearer.dropItemToGround(worn_helmet, force = TRUE)
			qdel(worn_helmet)
			to_chat(armor_wearer, span_warning("The helmet shatters as the Iron Maiden fractures!"))

	// Make armor invisible, reduce resistances, and apply speed boost
	icon_state = null
	src.armor = getArmor(red = 30, white = 40, black = 30, pale = 20)
	update_icon()
	if(armor_wearer)
		armor_wearer.update_inv_wear_suit()
		armor_wearer.add_movespeed_modifier(/datum/movespeed_modifier/iron_maiden_fractured)

	// Transform weapon from phase 1 to phase 2
	// remove_phase1_weapon() shelters any spirit into armor automatically
	remove_phase1_weapon()
	if(armor_wearer && !phase2_weapon)
		phase2_weapon = new /obj/item/ego_weapon/city/ring/fascia_unleashed
		phase2_weapon.LinkArmor(src)
		if(!armor_wearer.put_in_hands(phase2_weapon))
			QDEL_NULL(phase2_weapon)
			to_chat(armor_wearer, span_warning("You need a free hand for the transformation!"))
			return
		// grant_spirit_to_weapon transfers spirit from armor to new weapon
		if(bound_spirit)
			grant_spirit_to_weapon(phase2_weapon)

	// Grant the Reforge action
	if(armor_wearer)
		grant_reforge_action()

	// Heal 15% max HP on fracture
	if(armor_wearer)
		var/heal_amount = round(armor_wearer.maxHealth * 0.15)
		armor_wearer.adjustBruteLoss(-heal_amount)
		to_chat(armor_wearer, span_userdanger("The Iron Maiden fractures! The Fascia transforms, revealing its true form! (+[heal_amount] HP)"))
		playsound(get_turf(armor_wearer), 'sound/weapons/fixer/generic/finisher1.ogg', 50, 0, 4)

/// Grants the appropriate weapon based on current phase
/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/proc/grant_weapon(mob/living/carbon/human/user)
	if(phase1_weapon || phase2_weapon)
		return FALSE

	if(phase == 2)
		phase2_weapon = new /obj/item/ego_weapon/city/ring/fascia_unleashed
		phase2_weapon.LinkArmor(src)
		if(!user.put_in_hands(phase2_weapon))
			QDEL_NULL(phase2_weapon)
			to_chat(user, span_warning("You need a free hand to summon the weapon!"))
			return FALSE
		// Transfer sheltered spirit to new weapon
		if(bound_spirit)
			grant_spirit_to_weapon(phase2_weapon)
	else
		phase1_weapon = new /obj/item/ego_weapon/city/ring/fascia
		phase1_weapon.LinkArmor(src)
		if(!user.put_in_hands(phase1_weapon))
			QDEL_NULL(phase1_weapon)
			to_chat(user, span_warning("You need a free hand to summon the weapon!"))
			return FALSE
		// Transfer sheltered spirit to new weapon
		if(bound_spirit)
			grant_spirit_to_weapon(phase1_weapon)

	to_chat(user, span_userdanger("The Fascia manifests in your hands!"))
	playsound(get_turf(user), 'sound/abnormalities/onesin/bless.ogg', 50, 0, 4)
	return TRUE

/// Removes the phase 1 weapon
/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/proc/remove_phase1_weapon()
	if(phase1_weapon)
		// Shelter spirit in armor before destroying weapon
		shelter_spirit_from_weapon(phase1_weapon)
		REMOVE_TRAIT(phase1_weapon, TRAIT_NODROP, "ring_fascia")
		var/mob/living/holder = phase1_weapon.loc
		if(istype(holder))
			holder.dropItemToGround(phase1_weapon, force = TRUE, silent = TRUE)
		QDEL_NULL(phase1_weapon)

/// Removes the phase 2 weapon
/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/proc/remove_phase2_weapon()
	if(phase2_weapon)
		// Shelter spirit in armor before destroying weapon
		shelter_spirit_from_weapon(phase2_weapon)
		REMOVE_TRAIT(phase2_weapon, TRAIT_NODROP, "ring_fascia")
		var/mob/living/holder = phase2_weapon.loc
		if(istype(holder))
			holder.dropItemToGround(phase2_weapon, force = TRUE, silent = TRUE)
		QDEL_NULL(phase2_weapon)

/// Moves a spirit from a weapon into the armor for safekeeping
/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/proc/shelter_spirit_from_weapon(obj/item/weapon)
	var/mob/living/simple_animal/fascia_spirit/spirit
	var/obj/item/ego_weapon/city/ring/fascia/F1 = weapon
	var/obj/item/ego_weapon/city/ring/fascia_unleashed/F2 = weapon
	if(istype(F1) && F1.bound_spirit)
		spirit = F1.bound_spirit
		F1.bound_spirit = null
		F1.possessed = FALSE
		F1.empowered = FALSE
		if(F1.empower_timer_id)
			deltimer(F1.empower_timer_id)
			F1.empower_timer_id = null
	else if(istype(F2) && F2.bound_spirit)
		spirit = F2.bound_spirit
		F2.bound_spirit = null
		F2.possessed = FALSE
		F2.empowered = FALSE
		if(F2.empower_timer_id)
			deltimer(F2.empower_timer_id)
			F2.empower_timer_id = null

	if(!spirit)
		return

	// Move spirit into armor
	spirit.forceMove(src)
	spirit.bound_weapon = null
	bound_spirit = spirit
	possessed = TRUE

	// Remove weapon-dependent actions while in armor
	for(var/datum/action/cooldown/fascia_empower_strike/action in spirit.actions)
		action.Remove(spirit)
		qdel(action)
	for(var/datum/action/cooldown/fascia_compel_dash/action in spirit.actions)
		action.Remove(spirit)
		qdel(action)

	to_chat(spirit, span_notice("The weapon dissipates. You retreat into the armor, waiting..."))

/// Transfers the sheltered spirit from armor into a newly created weapon
/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/proc/grant_spirit_to_weapon(obj/item/weapon)
	if(!bound_spirit)
		return

	var/mob/living/simple_animal/fascia_spirit/spirit = bound_spirit

	// Move spirit into weapon
	spirit.forceMove(weapon)
	spirit.bound_weapon = weapon

	// Set refs on weapon
	var/obj/item/ego_weapon/city/ring/fascia/F1 = weapon
	var/obj/item/ego_weapon/city/ring/fascia_unleashed/F2 = weapon
	if(istype(F1))
		F1.bound_spirit = spirit
		F1.possessed = TRUE
	else if(istype(F2))
		F2.bound_spirit = spirit
		F2.possessed = TRUE

	// Clear armor refs
	bound_spirit = null

	// Grant actions pointing to new weapon
	var/datum/action/cooldown/fascia_empower_strike/empower_action = new(spirit)
	empower_action.weapon_ref = WEAKREF(weapon)
	empower_action.Grant(spirit)

	var/datum/action/cooldown/fascia_compel_dash/dash_action = new(spirit)
	dash_action.weapon_ref = WEAKREF(weapon)
	dash_action.Grant(spirit)

	to_chat(spirit, span_nicegreen("A new weapon manifests! You flow into the blade."))

/// Activates Iron Curtain mode - massively boosts reflect damage, slows the user
/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/proc/activate_iron_curtain()
	if(!armor_wearer || phase != 1)
		return
	iron_curtain = TRUE
	armor_wearer.add_atom_colour("#FFD700", TEMPORARY_COLOUR_PRIORITY)
	armor_wearer.add_movespeed_modifier(/datum/movespeed_modifier/iron_curtain)
	to_chat(armor_wearer, span_userdanger("Iron Curtain! Your body becomes an immovable fortress of spikes!"))
	playsound(get_turf(armor_wearer), 'sound/weapons/fixer/generic/finisher1.ogg', 50, 0, 4)
	iron_curtain_timer_id = addtimer(CALLBACK(src, PROC_REF(deactivate_iron_curtain)), 5 SECONDS, TIMER_STOPPABLE)

/// Deactivates Iron Curtain mode - restores normal movement and color
/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/proc/deactivate_iron_curtain()
	if(iron_curtain_timer_id)
		deltimer(iron_curtain_timer_id)
		iron_curtain_timer_id = null
	iron_curtain = FALSE
	if(armor_wearer && !QDELETED(armor_wearer))
		armor_wearer.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#FFD700")
		armor_wearer.remove_movespeed_modifier(/datum/movespeed_modifier/iron_curtain)
		to_chat(armor_wearer, span_notice("Iron Curtain fades. Your movement returns to normal."))

/// Grants the Reforge Iron Maiden action to the wearer
/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/proc/grant_reforge_action()
	if(reforge_action || !armor_wearer)
		return
	reforge_action = new(src)
	reforge_action.linked_armor = src
	reforge_action.Grant(armor_wearer)

/// Removes the Reforge Iron Maiden action from the wearer
/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/proc/remove_reforge_action()
	if(reforge_action)
		reforge_action.Remove(reforge_action.owner)
		QDEL_NULL(reforge_action)

/// Returns the armor to phase 1 from phase 2 (called by the Reforge action)
/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/proc/return_to_phase1()
	if(phase != 2)
		return
	phase = 1

	// Restore armor appearance, resistances, and remove speed boost
	icon_state = "ring_apprentice"
	src.armor = getArmor(red = 50, white = 40, black = 50, pale = 20)
	update_icon()
	if(armor_wearer)
		armor_wearer.remove_movespeed_modifier(/datum/movespeed_modifier/iron_maiden_fractured)
		armor_wearer.update_inv_wear_suit()

	// Transform weapon back to phase 1
	// remove_phase2_weapon() shelters any spirit into armor automatically
	remove_phase2_weapon()
	if(armor_wearer && !phase1_weapon)
		phase1_weapon = new /obj/item/ego_weapon/city/ring/fascia
		phase1_weapon.LinkArmor(src)
		if(!armor_wearer.put_in_hands(phase1_weapon))
			QDEL_NULL(phase1_weapon)
			to_chat(armor_wearer, span_warning("You need a free hand to reform the weapon!"))
		else if(bound_spirit)
			grant_spirit_to_weapon(phase1_weapon)

	// Remove the reforge action
	remove_reforge_action()

	// Set 30 second cooldown before phase 2 can trigger again
	phase2_cooldown = world.time + 30 SECONDS

	if(armor_wearer)
		to_chat(armor_wearer, span_userdanger("The Iron Maiden reforges itself around you!"))
		playsound(get_turf(armor_wearer), 'sound/abnormalities/onesin/bless.ogg', 50, 0, 4)

/obj/item/clothing/head/ego_hat/helmet/ring_apprentice
	name = "iron maiden helmet"
	desc = "A helmet with sharp golden eyes painted on and two white spikes on each side. Part of the Corporist apprentice's ensemble."
	icon = 'icons/obj/spider_house/ring/ring_mask.dmi'
	worn_icon = 'icons/obj/spider_house/ring/ring_mask_worn.dmi'
	icon_state = "ring_apprentice_mask"

/// Prevents equipping the helmet while the linked armor is in phase 2
/obj/item/clothing/head/ego_hat/helmet/ring_apprentice/mob_can_equip(mob/living/M, mob/living/equipper, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/armor = H.get_item_by_slot(ITEM_SLOT_OCLOTHING)
		if(istype(armor) && armor.phase == 2)
			to_chat(M, span_warning("The helmet refuses to attach while the Iron Maiden is fractured!"))
			return FALSE
	return ..()

// Ability for summoning the Fascia weapon from Iron Maiden armor
/obj/effect/proc_holder/ability/ring_summon_fascia
	name = "Summon Fascia"
	desc = "Summon or dismiss the Fascia weapon from the Iron Maiden armor."
	action_icon = 'icons/mob/actions/actions_ecult.dmi'
	action_icon_state = "mansus_link"
	base_icon_state = "mansus_link"
	cooldown_time = 5 SECONDS

/obj/effect/proc_holder/ability/ring_summon_fascia/Perform(target, mob/user)
	if(!ishuman(user))
		return ..()

	var/mob/living/carbon/human/H = user
	var/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/armor = H.get_item_by_slot(ITEM_SLOT_OCLOTHING)

	if(!istype(armor))
		to_chat(user, span_warning("You must be wearing the Iron Maiden armor!"))
		return ..()

	// Toggle weapon - dismiss if exists, summon if not
	if(armor.phase1_weapon)
		armor.remove_phase1_weapon()
		to_chat(user, span_notice("The Fascia dissipates."))
		playsound(get_turf(user), 'sound/abnormalities/onesin/bless.ogg', 50, 0, 4)
	else if(armor.phase2_weapon)
		armor.remove_phase2_weapon()
		to_chat(user, span_notice("The Fascia dissipates."))
		playsound(get_turf(user), 'sound/abnormalities/onesin/bless.ogg', 50, 0, 4)
	else
		armor.grant_weapon(H)

	return ..()

// Action to return from phase 2 to phase 1 via a long channel
/datum/action/cooldown/reforge_iron_maiden
	name = "Reforge Iron Maiden"
	desc = "Channel your will to reforge the fractured Iron Maiden armor, returning to the defensive phase."
	icon_icon = 'icons/obj/spider_house/ring/ring_icons.dmi'
	button_icon_state = "reforge_maiden"
	cooldown_time = 0
	check_flags = AB_CHECK_HANDS_BLOCKED | AB_CHECK_CONSCIOUS

	/// Linked armor reference
	var/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/linked_armor

/datum/action/cooldown/reforge_iron_maiden/Trigger(trigger_flags)
	. = ..(trigger_flags)
	if(!.)
		return FALSE

	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE

	if(!linked_armor || linked_armor.phase != 2)
		to_chat(H, span_warning("The armor is not in a state that can be reforged!"))
		return FALSE

	to_chat(H, span_notice("You begin reforging the Iron Maiden..."))
	playsound(get_turf(H), 'sound/weapons/fixer/generic/finisher1.ogg', 25, 0, 4)

	if(!do_after(H, 5 SECONDS, H))
		to_chat(H, span_warning("You were interrupted!"))
		return FALSE

	// Verify armor still exists and is still in phase 2
	if(QDELETED(linked_armor) || linked_armor.phase != 2 || linked_armor.armor_wearer != H)
		return FALSE

	linked_armor.return_to_phase1()
	return TRUE

/datum/action/cooldown/reforge_iron_maiden/Destroy()
	linked_armor = null
	return ..()

/// Iron Curtain movespeed modifier - massive slowdown during Iron Curtain activation
/datum/movespeed_modifier/iron_curtain
	multiplicative_slowdown = 3

/// Iron Maiden fractured speed boost - flips 0.75 slowdown to 1.25 speed boost in phase 2
/datum/movespeed_modifier/iron_maiden_fractured
	multiplicative_slowdown = -1

/// Fascia leap miss slowdown - applied when landing with no adjacent enemies
/datum/movespeed_modifier/fascia_leap_miss
	multiplicative_slowdown = 1
