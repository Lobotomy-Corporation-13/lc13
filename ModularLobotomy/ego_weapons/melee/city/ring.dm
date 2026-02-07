// The Ring - Syndicate of Artists
// Corporist School - Utilizes interaction between human bones and muscles
// "Those who utilize the interaction between human bones and muscles, and the contraction and elongation thereof."

// Tibia - Maestro Callisto's weapon, made from his own body
// Collects Corpus Ingredients (Bones and Blood) on melee hit.
// Use in hand to toggle between 4 ranged attack modes. Click at range to fire, consuming resources.
/obj/item/ego_weapon/city/ring/tibia
	name = "Tibia"
	desc = "A massive weapon composed of Callisto's own body. Several large pointed notches line its blade, designed to sculpt flesh with artistic precision."
	special = "Collects Corpus Ingredients on hit. Use in hand to toggle ranged mode. Click at range to fire."
	icon_state = "tibia"
	inhand_icon_state = "tibia"
	icon = 'icons/obj/ring_icons.dmi'
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left_64x64.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right_64x64.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	force = 67
	damtype = RED_DAMAGE
	attack_speed = 1
	swingstyle = WEAPONSWING_LARGESWEEP
	attack_verb_continuous = list("sculpts", "carves", "reshapes", "cleaves")
	attack_verb_simple = list("sculpt", "carve", "reshape", "cleave")
	hitsound = 'sound/weapons/fixer/generic/finisher1.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100
	)

	/// Current Corpus Ingredient (Bones)
	var/bones = 0
	/// Maximum Corpus Ingredient (Bones)
	var/max_bones = 206
	/// Current Corpus Ingredient (Blood)
	var/blood = 0
	/// Maximum Corpus Ingredient (Blood)
	var/max_blood = 5
	/// Current ranged attack mode: "shrapnel", "lance", "deluge", or "needle"
	var/ranged_mode = "shrapnel"
	/// Ranged attack cooldown tracker
	var/ranged_cooldown
	/// Time between ranged attacks
	var/ranged_cooldown_time = 2 SECONDS

/obj/item/ego_weapon/city/ring/tibia/attack(mob/living/target, mob/living/user)
	var/target_was_alive = target && !QDELETED(target) && target.stat != DEAD
	. = ..()
	if(!target || QDELETED(target) || !target_was_alive)
		return
	// Collect Corpus Ingredients on hit - double on kill
	var/bone_gain = 30
	var/blood_gain = 1
	if(target.stat == DEAD)
		bone_gain *= 2
		blood_gain *= 2
	var/old_bones = bones
	var/old_blood = blood
	bones = min(bones + bone_gain, max_bones)
	blood = min(blood + blood_gain, max_blood)
	var/bones_gained = bones - old_bones
	var/blood_gained = blood - old_blood
	var/list/gains = list()
	if(bones_gained > 0)
		gains += "+[bones_gained] Bones"
	if(blood_gained > 0)
		gains += "+[blood_gained] Blood"
	if(length(gains))
		var/kill_text = target.stat == DEAD ? " (KILL BONUS)" : ""
		to_chat(user, span_nicegreen("Corpus Ingredients: [jointext(gains, ", ")][kill_text] ([bones]/[max_bones] Bones, [blood]/[max_blood] Blood)"))

/// Toggle between ranged attack modes
/obj/item/ego_weapon/city/ring/tibia/attack_self(mob/user)
	. = ..()
	switch(ranged_mode)
		if("shrapnel")
			ranged_mode = "lance"
			to_chat(user, span_notice("Ranged mode: Marrow Lance (120 Bones) - Piercing marrow projectile with WHITE damage."))
			balloon_alert(user, "Marrow Lance")
		if("lance")
			ranged_mode = "deluge"
			to_chat(user, span_notice("Ranged mode: Sanguine Deluge (206 Bones + 5 Blood) - Massive area blood eruption."))
			balloon_alert(user, "Sanguine Deluge")
		if("deluge")
			ranged_mode = "needle"
			to_chat(user, span_notice("Ranged mode: Crimson Needle (2 Blood) - Piercing blood projectile."))
			balloon_alert(user, "Crimson Needle")
		if("needle")
			ranged_mode = "shrapnel"
			to_chat(user, span_notice("Ranged mode: Bone Shrapnel (60 Bones) - Burst of bone fragments."))
			balloon_alert(user, "Bone Shrapnel")
	playsound(src, 'sound/items/screwdriver2.ogg', 50, TRUE)

/// Ranged attack - click at range to fire, consuming Corpus Ingredients
/// Shrapnel/Deluge: AoE with 0.75s warning. Lance/Needle: piercing projectile.
/obj/item/ego_weapon/city/ring/tibia/afterattack(atom/A, mob/living/user, proximity_flag, params)
	if(ranged_cooldown > world.time)
		return
	if(!CanUseEgo(user))
		return
	var/turf/target_turf = get_turf(A)
	if(!istype(target_turf))
		return
	if((get_dist(user, target_turf) < 2) || !(target_turf in view(7, user)))
		return

	// Determine resource costs per mode
	var/bone_cost = 0
	var/blood_cost = 0
	var/mode_name = ""

	switch(ranged_mode)
		if("shrapnel")
			bone_cost = 60
			mode_name = "Bone Shrapnel"
		if("lance")
			bone_cost = 120
			mode_name = "Marrow Lance"
		if("deluge")
			bone_cost = 206
			blood_cost = 5
			mode_name = "Sanguine Deluge"
		if("needle")
			blood_cost = 2
			mode_name = "Crimson Needle"

	// Check resources
	if(bones < bone_cost || blood < blood_cost)
		var/list/need = list()
		if(bone_cost > 0)
			need += "[bone_cost] Bones"
		if(blood_cost > 0)
			need += "[blood_cost] Blood"
		to_chat(user, span_warning("Not enough Corpus Ingredients for [mode_name]! (Need: [jointext(need, ", ")])"))
		return

	// Consume resources
	bones -= bone_cost
	blood -= blood_cost

	..()
	ranged_cooldown = world.time + ranged_cooldown_time

	switch(ranged_mode)
		if("lance", "needle")
			// Fire piercing projectile
			fire_tibia_projectile(A, user, params)
			to_chat(user, span_warning("[mode_name]: Fired! ([bones]/[max_bones] Bones, [blood]/[max_blood] Blood remaining)"))
		if("shrapnel", "deluge")
			// AoE attack with 0.75s warning delay
			var/aoe_radius = (ranged_mode == "deluge") ? 2 : 1
			var/ranged_damage = (ranged_mode == "deluge") ? 150 : 40
			var/heals_sp = (ranged_mode == "deluge")
			// 96x96 warning covers the inner 3x3 from center - only place it on center turf
			new /obj/effect/temp_visual/tibia_warning(target_turf)
			// Deluge outer ring (dist > 1) gets spread warnings
			if(aoe_radius >= 2)
				for(var/turf/open/T in range(target_turf, aoe_radius))
					if(get_dist(target_turf, T) > 1)
						new /obj/effect/temp_visual/tibia_spread_warning(T)
			addtimer(CALLBACK(src, PROC_REF(execute_ranged_attack), user, target_turf, aoe_radius, ranged_damage, heals_sp, mode_name), 7.5)

/// Fires a piercing projectile for Lance and Needle modes
/obj/item/ego_weapon/city/ring/tibia/proc/fire_tibia_projectile(atom/target, mob/living/user, params)
	var/turf/proj_turf = get_turf(user)
	var/obj/projectile/ego_bullet/G
	switch(ranged_mode)
		if("lance")
			var/obj/projectile/ego_bullet/tibia_lance/lance = new(proj_turf)
			lance.white_bonus = round(lance.white_bonus * force_multiplier)
			G = lance
		if("needle")
			G = new /obj/projectile/ego_bullet/tibia_needle(proj_turf)
	G.fired_from = src
	G.firer = user
	G.preparePixelProjectile(target, user, params)
	G.fire()
	G.damage *= force_multiplier
	playsound(user, 'sound/weapons/fixer/generic/finisher1.ogg', 50, TRUE)

/// Executes the AoE ranged attack damage after the warning delay
/obj/item/ego_weapon/city/ring/tibia/proc/execute_ranged_attack(mob/living/user, turf/target_turf, aoe_radius, ranged_damage, heals_sp, mode_name)
	if(!user || QDELETED(user) || user.stat == DEAD)
		return
	if(!target_turf)
		return

	playsound(target_turf, 'sound/weapons/fixer/generic/finisher1.ogg', 50, TRUE)

	var/modified_damage = ranged_damage * force_multiplier
	var/targets_hit = 0
	var/list/been_hit = list()
	for(var/turf/open/T in range(target_turf, aoe_radius))
		new /obj/effect/temp_visual/smash_effect(T)
		for(var/mob/living/L in user.HurtInTurf(T, been_hit, modified_damage, RED_DAMAGE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_SPECIAL)))
			if(L in been_hit)
				continue
			if(L.stat < DEAD && !(L.status_flags & GODMODE))
				been_hit += L
				targets_hit++
				L.apply_lc_bleed(4)

	// Sanguine Deluge bonus: heal 5% max SP per target hit
	if(heals_sp && targets_hit > 0 && ishuman(user))
		var/mob/living/carbon/human/H = user
		var/sp_per_target = round(H.maxSanity * 0.05)
		H.adjustSanityLoss(-(sp_per_target * targets_hit))
		to_chat(user, span_nicegreen("[mode_name]: Healed [sp_per_target * targets_hit] SP from [targets_hit] target\s!"))

	to_chat(user, span_warning("[mode_name]: [targets_hit] target\s hit! ([bones]/[max_bones] Bones, [blood]/[max_blood] Blood remaining)"))

/obj/item/ego_weapon/city/ring/tibia/examine(mob/user)
	. = ..()
	var/mode_desc
	switch(ranged_mode)
		if("shrapnel")
			mode_desc = "Bone Shrapnel (60 Bones) - 3x3 burst of bone fragments"
		if("lance")
			mode_desc = "Marrow Lance (120 Bones) - Piercing marrow projectile with WHITE damage"
		if("deluge")
			mode_desc = "Sanguine Deluge (206 Bones + 5 Blood) - Massive 5x5 blood eruption"
		if("needle")
			mode_desc = "Crimson Needle (2 Blood) - Piercing blood projectile"
	. += span_notice("Corpus Ingredients: [bones]/[max_bones] Bones, [blood]/[max_blood] Blood")
	. += span_notice("Ranged Mode: [mode_desc]")

// Warning visual for Tibia ranged attacks - 96x96 purple warning indicator
/obj/effect/temp_visual/tibia_warning
	name = "ominous shadow"
	desc = "GET OUT OF THE WAY!"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "warning"
	color = "#ff4141"
	pixel_x = -32
	base_pixel_x = -32
	pixel_y = -32
	base_pixel_y = -32
	randomdir = FALSE
	duration = 8
	layer = POINT_LAYER

// Spread warning for Sanguine Deluge outer turfs
/obj/effect/temp_visual/tibia_spread_warning
	name = "spreading shadow"
	desc = "GET OUT OF THE WAY!"
	icon = 'icons/effects/effects.dmi'
	icon_state = "spreadwarning"
	color = "#ff4141"
	layer = BELOW_MOB_LAYER
	duration = 8
	alpha = 128
	randomdir = FALSE

// Marrow Lance - piercing projectile for Tibia Lance mode
// Passes through all mobs, applying bleed and WHITE damage to each
/obj/projectile/ego_bullet/tibia_lance
	name = "marrow lance"
	icon_state = "ochre"
	damage = 80
	damage_type = RED_DAMAGE
	projectile_piercing = PASSMOB
	range = 14
	hit_nondense_targets = TRUE
	/// WHITE damage bonus applied on hit
	var/white_bonus = 20

/obj/projectile/ego_bullet/tibia_lance/Moved(atom/OldLoc, Dir)
	. = ..()
	if(fired)
		new /obj/effect/temp_visual/impact_effect/ion(get_turf(src))

/obj/projectile/ego_bullet/tibia_lance/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isliving(target))
		var/mob/living/L = target
		if(L.stat < DEAD)
			L.apply_lc_bleed(4)
			L.deal_damage(white_bonus, WHITE_DAMAGE, firer, attack_type = (ATTACK_TYPE_RANGED))

// Crimson Needle - piercing projectile for Tibia Needle mode
// Passes through all mobs, applying bleed to each
/obj/projectile/ego_bullet/tibia_needle
	name = "crimson needle"
	icon_state = "banquet"
	damage = 30
	damage_type = RED_DAMAGE
	projectile_piercing = PASSMOB
	range = 14
	hit_nondense_targets = TRUE

/obj/projectile/ego_bullet/tibia_needle/Moved(atom/OldLoc, Dir)
	. = ..()
	if(fired)
		var/obj/effect/temp_visual/impact_effect/ion/trail = new(get_turf(src))
		trail.color = "#8B0000"

/obj/projectile/ego_bullet/tibia_needle/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isliving(target))
		var/mob/living/L = target
		if(L.stat < DEAD)
			L.apply_lc_bleed(8)

// Fascia - Phase 1 weapon (Defensive phase)
// Summoned from Iron Maiden armor. Heavy greatsword that inflicts bleed on hit.
// Use in hand to activate Iron Curtain - massively boosts armor's reflect damage.
/obj/item/ego_weapon/city/ring/fascia
	name = "Fascia"
	desc = "A white and yellow greatsword carried by Corporist apprentices. A removable panel on its side conceals a dark, skeletal frame with an interior made of viscera and ribs."
	icon_state = "fascia"
	inhand_icon_state = "fascia"
	force = 90
	damtype = RED_DAMAGE
	attack_speed = 1.4
	swingstyle = WEAPONSWING_LARGESWEEP
	attack_verb_continuous = list("slashes", "cuts", "cleaves")
	attack_verb_simple = list("slash", "cut", "cleave")
	hitsound = 'sound/weapons/bladeslice.ogg'
	attribute_requirements = list()

	/// Linked armor reference
	var/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/linked_armor
	/// Iron Curtain cooldown tracker (world.time)
	var/iron_curtain_cooldown
	/// Whether a ghost spirit inhabits this weapon
	var/possessed = FALSE
	/// The spirit mob inhabiting this weapon
	var/mob/living/simple_animal/fascia_spirit/bound_spirit
	/// Whether the next attack is empowered by the spirit
	var/empowered = FALSE
	/// Bonus RED damage dealt on empowered strike
	var/empower_bonus = 30
	/// Timer ID for empower expiry
	var/empower_timer_id

/obj/item/ego_weapon/city/ring/fascia/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, "ring_fascia")

/obj/item/ego_weapon/city/ring/fascia/Destroy()
	if(empower_timer_id)
		deltimer(empower_timer_id)
	if(bound_spirit)
		// Spirit is qdel'd only if armor can't shelter it (armor handles transfer via shelter_spirit_from_weapon)
		if(!linked_armor)
			QDEL_NULL(bound_spirit)
		bound_spirit = null
	if(linked_armor)
		linked_armor.phase1_weapon = null
		linked_armor = null
	return ..()

/obj/item/ego_weapon/city/ring/fascia/relaymove(mob/living/user, direction)
	return //stops buckled message spam for the spirit

/obj/item/ego_weapon/city/ring/fascia/AllowDrop()
	return FALSE

/obj/item/ego_weapon/city/ring/fascia/equip_to_best_slot(mob/M, check_hand = TRUE)
	to_chat(M, span_warning("The Fascia refuses to leave your grasp!"))
	return FALSE

/obj/item/ego_weapon/city/ring/fascia/mob_can_equip(mob/living/M, mob/living/equipper, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE)
	if(slot != ITEM_SLOT_HANDS)
		to_chat(M, span_warning("The Fascia refuses to leave your grasp!"))
		return FALSE
	return ..()

/obj/item/ego_weapon/city/ring/fascia/canStrip(mob/who)
	return FALSE

/obj/item/ego_weapon/city/ring/fascia/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HANDS)
		RegisterSignal(user, COMSIG_PARENT_EXAMINE, PROC_REF(on_wielder_examined))

/obj/item/ego_weapon/city/ring/fascia/dropped(mob/user)
	UnregisterSignal(user, COMSIG_PARENT_EXAMINE)
	return ..()

/// Called when the wielder is examined - shows possession prompt to ghosts
/obj/item/ego_weapon/city/ring/fascia/proc/on_wielder_examined(datum/source, mob/examiner, list/examine_list)
	SIGNAL_HANDLER
	if(isobserver(examiner) && !possessed)
		examine_list += span_notice("The blade calls out... <a href='byond://?src=[REF(src)];interact=1'>Listen closely.</a>")

/obj/item/ego_weapon/city/ring/fascia/attack_ghost(mob/user)
	if(!isobserver(user))
		return
	try_possess(user)
	return ..()

/obj/item/ego_weapon/city/ring/fascia/Topic(href, href_list)
	. = ..()
	if(href_list["interact"] && isobserver(usr))
		try_possess(usr)

/// Attempts to let a ghost possess this weapon
/obj/item/ego_weapon/city/ring/fascia/proc/try_possess(mob/dead/observer/O)
	if(possessed)
		to_chat(O, span_warning("This blade is already inhabited!"))
		return
	if(!isobserver(O))
		return
	if(!(GLOB.ghost_role_flags & GHOSTROLE_STATION_SENTIENCE))
		to_chat(O, span_warning("Ghost roles are not currently enabled!"))
		return

	var/response = tgui_alert(O, "Do you wish to inhabit this blade?", "Fascia", list("Yes", "No"))
	if(response != "Yes")
		return
	if(QDELETED(src) || QDELETED(O) || possessed)
		return

	possessed = TRUE
	var/mob/living/simple_animal/fascia_spirit/S = new(src)
	S.ckey = O.ckey
	S.fully_replace_character_name(null, "The spirit of [name]")
	S.status_flags |= GODMODE
	S.bound_weapon = src
	bound_spirit = S

	// Copy languages from wielder
	var/mob/living/wielder = get_wielder()
	if(wielder)
		S.copy_languages(wielder, LANGUAGE_MASTER)
		S.update_atom_languages()
		S.grant_all_languages(FALSE, FALSE, TRUE)

	// Grant spirit actions
	var/datum/action/cooldown/fascia_empower_strike/empower_action = new(S)
	empower_action.weapon_ref = WEAKREF(src)
	empower_action.Grant(S)

	var/datum/action/cooldown/fascia_compel_dash/dash_action = new(S)
	dash_action.weapon_ref = WEAKREF(src)
	dash_action.Grant(S)

	to_chat(S, span_nicegreen("You inhabit the Fascia! You can speak to the wielder via say. Use your actions to aid them in battle."))
	if(wielder)
		to_chat(wielder, span_nicegreen("A spirit has inhabited your Fascia!"))

/// Returns the mob currently wielding this weapon
/obj/item/ego_weapon/city/ring/fascia/proc/get_wielder()
	if(ismob(loc))
		return loc
	return null

/// Clears the empower state
/obj/item/ego_weapon/city/ring/fascia/proc/clear_empower()
	empowered = FALSE
	empower_timer_id = null
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#FFD700")

/obj/item/ego_weapon/city/ring/fascia/attack(mob/living/target, mob/living/user)
	// Cannot attack while Iron Curtain is active
	if(linked_armor?.iron_curtain)
		to_chat(user, span_warning("You cannot attack while Iron Curtain is active!"))
		return FALSE
	. = ..()
	// Inflict 3 bleed stacks on hit
	if(target && !QDELETED(target) && target.stat != DEAD)
		target.apply_lc_bleed(3)
	// Empowered strike from spirit
	if(empowered && target && !QDELETED(target) && target.stat != DEAD)
		target.deal_damage(empower_bonus, RED_DAMAGE)
		to_chat(user, span_nicegreen("The Fascia's empowered strike lands! (+[empower_bonus] RED)"))
		if(bound_spirit)
			to_chat(bound_spirit, span_nicegreen("Your empowered strike lands!"))
		empowered = FALSE
		remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#FFD700")
		if(empower_timer_id)
			deltimer(empower_timer_id)
			empower_timer_id = null

/// Iron Curtain activation - use in hand to enter defensive stance
/obj/item/ego_weapon/city/ring/fascia/attack_self(mob/user)
	. = ..()
	if(!linked_armor)
		to_chat(user, span_warning("The weapon has no linked armor!"))
		return

	if(iron_curtain_cooldown > world.time)
		var/remaining = round((iron_curtain_cooldown - world.time) / 10)
		to_chat(user, span_warning("Iron Curtain is recharging! ([remaining] seconds remaining)"))
		return

	if(linked_armor.iron_curtain)
		to_chat(user, span_warning("Iron Curtain is already active!"))
		return

	// Set cooldown (5s duration + 20s CD = 25s between activations)
	iron_curtain_cooldown = world.time + 25 SECONDS
	linked_armor.activate_iron_curtain()

// Fascia Unleashed - Phase 2 weapon (Offensive phase)
// Summoned when the Iron Maiden armor transitions to phase 2 at 50% HP.
// Click at range to leap to a target turf. Deals damage to adjacent mobs on landing.
/obj/item/ego_weapon/city/ring/fascia_unleashed
	name = "Fascia"
	desc = "The Fascia's panel has been torn away, revealing the dark skeletal frame beneath. Viscera and ribs pulse with violent energy, freed from their confines."
	icon_state = "fascia_unleashed"
	inhand_icon_state = "fascia_unleashed"
	force = 90
	damtype = RED_DAMAGE
	attack_speed = 1.4
	swingstyle = WEAPONSWING_LARGESWEEP
	attack_verb_continuous = list("rends", "tears", "rips")
	attack_verb_simple = list("rend", "tear", "rip")
	hitsound = 'sound/weapons/bladeslice.ogg'
	attribute_requirements = list()

	/// Linked armor reference
	var/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/linked_armor
	/// Whether the user is currently mid-leap
	var/is_leaping = FALSE
	/// Leap cooldown tracker (world.time)
	var/leap_cooldown
	/// Maximum leap range in tiles
	var/leap_range = 7
	/// Timer ID for slowdown removal on missed leap
	var/leap_slowdown_timer_id
	/// Whether a ghost spirit inhabits this weapon
	var/possessed = FALSE
	/// The spirit mob inhabiting this weapon
	var/mob/living/simple_animal/fascia_spirit/bound_spirit
	/// Whether the next attack is empowered by the spirit
	var/empowered = FALSE
	/// Bonus RED damage dealt on empowered strike
	var/empower_bonus = 30
	/// Timer ID for empower expiry
	var/empower_timer_id

/obj/item/ego_weapon/city/ring/fascia_unleashed/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, "ring_fascia")

/obj/item/ego_weapon/city/ring/fascia_unleashed/Destroy()
	if(empower_timer_id)
		deltimer(empower_timer_id)
	if(bound_spirit)
		// Spirit is qdel'd only if armor can't shelter it (armor handles transfer via shelter_spirit_from_weapon)
		if(!linked_armor)
			QDEL_NULL(bound_spirit)
		bound_spirit = null
	if(leap_slowdown_timer_id)
		deltimer(leap_slowdown_timer_id)
	if(linked_armor)
		linked_armor.phase2_weapon = null
		linked_armor = null
	return ..()

/obj/item/ego_weapon/city/ring/fascia_unleashed/relaymove(mob/living/user, direction)
	return //stops buckled message spam for the spirit

/obj/item/ego_weapon/city/ring/fascia_unleashed/AllowDrop()
	return FALSE

/obj/item/ego_weapon/city/ring/fascia_unleashed/equip_to_best_slot(mob/M, check_hand = TRUE)
	to_chat(M, span_warning("The Fascia refuses to leave your grasp!"))
	return FALSE

/obj/item/ego_weapon/city/ring/fascia_unleashed/mob_can_equip(mob/living/M, mob/living/equipper, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE)
	if(slot != ITEM_SLOT_HANDS)
		to_chat(M, span_warning("The Fascia refuses to leave your grasp!"))
		return FALSE
	return ..()

/obj/item/ego_weapon/city/ring/fascia_unleashed/canStrip(mob/who)
	return FALSE

/obj/item/ego_weapon/city/ring/fascia_unleashed/attack(mob/living/target, mob/living/user)
	. = ..()
	// Inflict 3 bleed stacks on hit
	if(target && !QDELETED(target) && target.stat != DEAD)
		target.apply_lc_bleed(3)
	// Empowered strike from spirit
	if(empowered && target && !QDELETED(target) && target.stat != DEAD)
		target.deal_damage(empower_bonus, RED_DAMAGE)
		to_chat(user, span_nicegreen("The Fascia's empowered strike lands! (+[empower_bonus] RED)"))
		if(bound_spirit)
			to_chat(bound_spirit, span_nicegreen("Your empowered strike lands!"))
		empowered = FALSE
		remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#FFD700")
		if(empower_timer_id)
			deltimer(empower_timer_id)
			empower_timer_id = null

/// Clears the empower state
/obj/item/ego_weapon/city/ring/fascia_unleashed/proc/clear_empower()
	empowered = FALSE
	empower_timer_id = null
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#FFD700")

/// Returns the mob currently wielding this weapon
/obj/item/ego_weapon/city/ring/fascia_unleashed/proc/get_wielder()
	if(ismob(loc))
		return loc
	return null

/// Leap attack - click at range to leap to a target turf
/obj/item/ego_weapon/city/ring/fascia_unleashed/afterattack(atom/target, mob/living/user, proximity_flag, params)
	. = ..()
	if(proximity_flag)
		return
	if(is_leaping)
		return
	if(!isliving(user))
		return
	if(leap_cooldown > world.time)
		var/remaining = round((leap_cooldown - world.time) / 10)
		to_chat(user, span_warning("Your leap is still recharging! ([remaining] seconds remaining)"))
		return

	// Save the target turf at click time (even if target moves, we leap to original position)
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return

	var/turf/user_turf = get_turf(user)
	var/distance = get_dist(user_turf, target_turf)

	if(distance < 2)
		return // Adjacent, no leap needed
	if(distance > leap_range)
		to_chat(user, span_warning("Target is too far away!"))
		return

	// Check path for dense turfs blocking the way
	for(var/turf/T in getline(user_turf, target_turf))
		if(T == user_turf)
			continue
		if(T.density)
			to_chat(user, span_warning("Something is blocking your path!"))
			return

	// Begin leap
	is_leaping = TRUE

	// Jump animation - lift up
	playsound(user, 'sound/abnormalities/ichthys/jump.ogg', 50, FALSE, -1)
	animate(user, pixel_z = 16, alpha = 180, time = 2)

	// Short delay mid-air
	if(!do_after(user, 0.8 SECONDS, user))
		is_leaping = FALSE
		animate(user, pixel_z = 0, alpha = 255, time = 1)
		user.pixel_z = 0
		return

	if(QDELETED(user))
		return

	// Land at target turf (original position, even if target moved)
	user.forceMove(target_turf)
	animate(user, pixel_z = 0, alpha = 255, time = 1)
	user.pixel_z = 0
	playsound(user, 'sound/weapons/fixer/generic/finisher1.ogg', 50, FALSE, -1)

	is_leaping = FALSE

	// Check for adjacent living mobs
	var/found_adjacent = FALSE
	for(var/mob/living/L in range(1, user))
		if(L == user)
			continue
		if(L.stat == DEAD)
			continue
		// Deal 15 RED damage to each adjacent living mob
		found_adjacent = TRUE
		L.deal_damage(15, RED_DAMAGE, user, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		to_chat(L, span_userdanger("[user] crashes down near you!"))

	if(found_adjacent)
		// Short cooldown on successful landing near enemies
		leap_cooldown = world.time + 1.5 SECONDS
		to_chat(user, span_warning("You crash down onto your targets!"))
	else
		// No adjacent mobs - apply slowdown and longer cooldown
		apply_leap_slowdown(user)
		leap_cooldown = world.time + 10 SECONDS
		to_chat(user, span_warning("You land but find no target nearby..."))

/// Applies temporary slowdown after a missed leap (no adjacent enemies)
/obj/item/ego_weapon/city/ring/fascia_unleashed/proc/apply_leap_slowdown(mob/living/user)
	if(leap_slowdown_timer_id)
		deltimer(leap_slowdown_timer_id)
	user.add_movespeed_modifier(/datum/movespeed_modifier/fascia_leap_miss)
	leap_slowdown_timer_id = addtimer(CALLBACK(src, PROC_REF(remove_leap_slowdown), user), 2.5 SECONDS, TIMER_STOPPABLE)

/// Removes the leap miss slowdown
/obj/item/ego_weapon/city/ring/fascia_unleashed/proc/remove_leap_slowdown(mob/living/user)
	leap_slowdown_timer_id = null
	if(user && !QDELETED(user))
		user.remove_movespeed_modifier(/datum/movespeed_modifier/fascia_leap_miss)

// ========== FASCIA SPIRIT ==========
// Ghost mob that lives inside the Fascia weapon. Speaks privately to the wielder.

/mob/living/simple_animal/fascia_spirit
	name = "Fascia Spirit"
	real_name = "Fascia Spirit"
	desc = "A bound spirit inhabiting the Fascia."
	icon = 'icons/mob/cult.dmi'
	icon_state = "shade"
	icon_living = "shade"
	mob_biotypes = MOB_SPIRIT
	maxHealth = 100
	health = 100
	density = FALSE
	anchored = TRUE
	speak_emote = list("whispers")
	faction = list("neutral")
	status_flags = GODMODE
	del_on_death = FALSE

	/// The weapon this spirit inhabits (null when sheltered in armor)
	var/obj/item/bound_weapon

/mob/living/simple_animal/fascia_spirit/Initialize()
	. = ..()

/mob/living/simple_animal/fascia_spirit/say(message, bubble_type, list/spans, sanitize, datum/language/language, ignore_spam, forced)
	if(!message)
		return
	// Find the wearer - check weapon first, then armor
	var/mob/living/wielder
	if(bound_weapon && ismob(bound_weapon.loc))
		wielder = bound_weapon.loc
	else
		// Spirit is sheltered in armor - find armor_wearer
		var/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/armor = loc
		if(istype(armor) && armor.armor_wearer)
			wielder = armor.armor_wearer
	if(wielder)
		to_chat(wielder, span_notice("Fascia whispers: \"[message]\""))
		to_chat(src, span_notice("You whisper: \"[message]\""))
	else
		to_chat(src, span_warning("No one can hear you..."))

/mob/living/simple_animal/fascia_spirit/Life()
	. = ..()
	// Keep health stable
	health = maxHealth

/mob/living/simple_animal/fascia_spirit/death(gibbed)
	return // Cannot die

/mob/living/simple_animal/fascia_spirit/Destroy()
	// Clear refs on whatever contains us
	if(bound_weapon)
		var/obj/item/ego_weapon/city/ring/fascia/F1 = bound_weapon
		var/obj/item/ego_weapon/city/ring/fascia_unleashed/F2 = bound_weapon
		if(istype(F1))
			F1.bound_spirit = null
			F1.possessed = FALSE
		else if(istype(F2))
			F2.bound_spirit = null
			F2.possessed = FALSE
		bound_weapon = null
	var/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/armor = loc
	if(istype(armor))
		armor.bound_spirit = null
		armor.possessed = FALSE
	return ..()

// ========== FASCIA SPIRIT ACTIONS ==========

// Empower Strike - empowers the next weapon attack within 1.5 seconds
/datum/action/cooldown/fascia_empower_strike
	name = "Empower Strike"
	desc = "Empower the wielder's next attack within 1.5 seconds, dealing +30 bonus RED damage."
	icon_icon = 'icons/obj/ring_icons.dmi'
	button_icon_state = "fascia"
	cooldown_time = 7 SECONDS
	check_flags = AB_CHECK_CONSCIOUS

	/// Reference to the weapon
	var/datum/weakref/weapon_ref

/datum/action/cooldown/fascia_empower_strike/Trigger(trigger_flags)
	. = ..(trigger_flags)
	if(!.)
		return FALSE

	var/obj/item/weapon = weapon_ref?.resolve()
	if(!weapon)
		return FALSE

	// Find the wielder
	var/mob/living/wielder
	if(ismob(weapon.loc))
		wielder = weapon.loc
	if(!wielder)
		to_chat(owner, span_warning("The blade has no wielder!"))
		return FALSE

	// Set empower on the weapon (works for both fascia types)
	var/obj/item/ego_weapon/city/ring/fascia/F1 = weapon
	var/obj/item/ego_weapon/city/ring/fascia_unleashed/F2 = weapon
	if(istype(F1))
		F1.empowered = TRUE
		F1.add_atom_colour("#FFD700", TEMPORARY_COLOUR_PRIORITY)
		if(F1.empower_timer_id)
			deltimer(F1.empower_timer_id)
		F1.empower_timer_id = addtimer(CALLBACK(F1, TYPE_PROC_REF(/obj/item/ego_weapon/city/ring/fascia, clear_empower)), 1.5 SECONDS, TIMER_STOPPABLE)
	else if(istype(F2))
		F2.empowered = TRUE
		F2.add_atom_colour("#FFD700", TEMPORARY_COLOUR_PRIORITY)
		if(F2.empower_timer_id)
			deltimer(F2.empower_timer_id)
		F2.empower_timer_id = addtimer(CALLBACK(F2, TYPE_PROC_REF(/obj/item/ego_weapon/city/ring/fascia_unleashed, clear_empower)), 1.5 SECONDS, TIMER_STOPPABLE)
	else
		return FALSE

	playsound(wielder, 'sound/magic/charge.ogg', 50, TRUE)
	to_chat(wielder, span_nicegreen("The Fascia surges with power!"))
	to_chat(owner, span_nicegreen("You empower the blade!"))
	StartCooldown()
	return TRUE

/datum/action/cooldown/fascia_empower_strike/Destroy()
	weapon_ref = null
	return ..()

// Compel Dash - forces the wielder to dash 5 tiles in their facing direction
/datum/action/cooldown/fascia_compel_dash
	name = "Compel Dash"
	desc = "Compel the wielder to dash 5 tiles in their facing direction."
	icon_icon = 'icons/effects/cult_effects.dmi'
	button_icon_state = "pulse"
	cooldown_time = 5 SECONDS
	check_flags = AB_CHECK_CONSCIOUS

	/// Reference to the weapon
	var/datum/weakref/weapon_ref

/datum/action/cooldown/fascia_compel_dash/Trigger(trigger_flags)
	. = ..(trigger_flags)
	if(!.)
		return FALSE

	var/obj/item/weapon = weapon_ref?.resolve()
	if(!weapon)
		return FALSE

	// Find the wielder
	var/mob/living/wielder
	if(ismob(weapon.loc))
		wielder = weapon.loc
	if(!wielder || wielder.stat == DEAD)
		to_chat(owner, span_warning("The blade has no living wielder!"))
		return FALSE

	// Calculate landing turf in wielder's facing direction
	var/turf/landing
	if(wielder.dir == NORTH)
		landing = locate(wielder.x, wielder.y + 5, wielder.z)
	if(wielder.dir == SOUTH)
		landing = locate(wielder.x, wielder.y - 5, wielder.z)
	if(wielder.dir == EAST)
		landing = locate(wielder.x + 5, wielder.y, wielder.z)
	if(wielder.dir == WEST)
		landing = locate(wielder.x - 5, wielder.y, wielder.z)

	if(!landing)
		to_chat(owner, span_warning("Cannot dash in that direction!"))
		return FALSE

	// Check path for dense turfs
	var/turf/user_turf = get_turf(wielder)
	for(var/turf/T in getline(user_turf, landing))
		if(T == user_turf)
			continue
		if(T.density)
			to_chat(owner, span_warning("Something blocks the path!"))
			return FALSE

	wielder.throw_at(landing, 5, 2, spin = TRUE)
	playsound(wielder, 'sound/abnormalities/ichthys/jump.ogg', 50, FALSE, -1)
	to_chat(wielder, span_warning("The Fascia compels you forward!"))
	to_chat(owner, span_nicegreen("You compel the wielder to dash!"))
	StartCooldown()
	return TRUE

/datum/action/cooldown/fascia_compel_dash/Destroy()
	weapon_ref = null
	return ..()
