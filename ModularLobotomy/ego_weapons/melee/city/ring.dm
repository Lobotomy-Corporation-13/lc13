// The Ring - Syndicate of Artists
// Corporist School - Utilizes interaction between human bones and muscles
// "Those who utilize the interaction between human bones and muscles, and the contraction and elongation thereof."

// Tibia - Maestro Callisto's weapon, made from his own body
// Collects Corpus Ingredients (Bones and Blood) on melee hit.
// Use in hand to toggle between 4 ranged attack modes. Click at range to fire, consuming resources.
/obj/item/ego_weapon/city/ring/tibia
	name = "Tibia"
	desc = "A massive weapon composed of Callisto's own body. Several large pointed notches line its blade, designed to sculpt flesh with artistic precision."
	special = "Collects Corpus Ingredients on hit. Stuns targets for half your recovery time. Use in hand to toggle ranged mode. Click at range to fire."
	icon_state = "tibia"
	inhand_icon_state = "tibia"
	icon = 'icons/obj/spider_house/ring/ring_icons.dmi'
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left_64x64.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right_64x64.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	force = 68
	damtype = RED_DAMAGE
	attack_speed = 1
	reach = 2
	stuntime = 5
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
	/// Timer ID for disgust buildup on non-Maestro holders
	var/disgust_timer_id

/// Checks if a user is authorized to use the Tibia without triggering the disgust system
/obj/item/ego_weapon/city/ring/tibia/proc/is_authorized(mob/user)
	if(!ishuman(user))
		return TRUE
	var/mob/living/carbon/human/H = user
	if(H.mind?.assigned_role in list("Corporist Maestro", "Corporist Apprentice"))
		return TRUE
	// Disgust only triggers on city maps
	if(!(SSmaptype.maptype in SSmaptype.citymaps))
		return TRUE
	// Disgust doesn't trigger on the testing range
	if(is_tutorial_level(H.z))
		return TRUE
	return FALSE

/obj/item/ego_weapon/city/ring/tibia/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HANDS)
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			if(H.mind?.assigned_role == "Corporist Apprentice")
				to_chat(H, span_notice("The Tibia's fleshy composition makes you uneasy, but your corporist body suppresses the revulsion."))
			else if(!is_authorized(user))
				start_disgust_timer(H)

/obj/item/ego_weapon/city/ring/tibia/dropped(mob/user)
	stop_disgust_timer()
	return ..()

/obj/item/ego_weapon/city/ring/tibia/Destroy()
	stop_disgust_timer()
	return ..()

/// Starts the disgust buildup timer for non-Maestro holders
/obj/item/ego_weapon/city/ring/tibia/proc/start_disgust_timer(mob/living/carbon/human/H)
	stop_disgust_timer()
	disgust_timer_id = addtimer(CALLBACK(src, PROC_REF(apply_disgust), H), 2 SECONDS, TIMER_STOPPABLE | TIMER_LOOP)

/// Stops the disgust buildup timer
/obj/item/ego_weapon/city/ring/tibia/proc/stop_disgust_timer()
	if(disgust_timer_id)
		deltimer(disgust_timer_id)
		disgust_timer_id = null

/// Applies disgust to unauthorized holders and force drops at 100+
/obj/item/ego_weapon/city/ring/tibia/proc/apply_disgust(mob/living/carbon/human/H)
	if(QDELETED(H) || QDELETED(src))
		stop_disgust_timer()
		return
	if(!H.is_holding(src))
		stop_disgust_timer()
		return
	// Double-check they're still not authorized
	if(is_authorized(H))
		stop_disgust_timer()
		return

	H.adjust_disgust(20)
	if(H.disgust >= 100)
		to_chat(H, span_warning("The Tibia's fleshy composition overwhelms you with disgust!"))
		H.dropItemToGround(src, TRUE)
		stop_disgust_timer()

/obj/item/ego_weapon/city/ring/tibia/attack(mob/living/target, mob/living/user)
	var/target_was_alive = target && !QDELETED(target) && target.stat != DEAD
	. = ..()
	if(!target || QDELETED(target) || !target_was_alive)
		return
	// Stun target for half the user's stuntime
	if(stuntime && target.stat != DEAD)
		target.Immobilize(round(stuntime * 0.5))
		new /obj/effect/temp_visual/weapon_stun(get_turf(target))
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(target), pick(GLOB.alldirs))
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(target), pick(GLOB.alldirs))
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(target), pick(GLOB.alldirs))
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
			addtimer(CALLBACK(src, PROC_REF(execute_ranged_attack), user, target_turf, aoe_radius, ranged_damage, heals_sp, mode_name), 5)

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
	actions_types = list(/datum/action/item_action/fascia_heartbeat_surge)
	special = "Phase 1 (Defensive). Summoned from the Iron Maiden armor. Inflicts 3 bleed on hit. \
		Use in hand to activate Iron Curtain (5s, 25s CD) — massively boosts armor reflect but slows movement. \
		Heartbeat Surge: plant blade, dash up to 5 tiles, perform an 8-hit combo on the first target hit (15s CD). \
		A ghost can possess this weapon for Empower Strike (+30 RED) and Compel Dash (forced 5-tile dash) abilities. \
		The spirit has a hunger system that scales weapon damage from -25% (starving) to +10% (gorged)."

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
	/// Heartbeat Surge cooldown tracker (world.time)
	var/heartbeat_surge_cooldown
	/// Whether Heartbeat Surge targeting is active
	var/special_ability_targeting = FALSE
	/// Whether a surge is currently in progress
	var/is_surging = FALSE
	/// Reference to the planted sword visual
	var/obj/structure/fascia_planted/planted_visual

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

/obj/item/ego_weapon/city/ring/fascia/attackby(obj/item/I, mob/user, params)
	// Allow feeding the spirit with food or bodyparts
	if(possessed && bound_spirit)
		if(istype(I, /obj/item/food) || istype(I, /obj/item/bodypart))
			if(bound_spirit.feed(I, user))
				return
	return ..()

/obj/item/ego_weapon/city/ring/fascia/examine(mob/user)
	. = ..()
	// Only show hunger info to the wielder
	if(possessed && bound_spirit && ismob(loc) && user == loc)
		var/hunger_percent = round((bound_spirit.hunger / bound_spirit.max_hunger) * 100)
		var/multiplier = bound_spirit.get_damage_multiplier()
		var/damage_mod = round((multiplier - 1) * 100)
		var/mod_text
		if(damage_mod > 0)
			mod_text = span_nicegreen("+[damage_mod]%")
		else if(damage_mod < 0)
			mod_text = span_warning("[damage_mod]%")
		else
			mod_text = "0%"
		. += span_notice("Fascia's hunger: [round(bound_spirit.hunger)]/[bound_spirit.max_hunger] ([hunger_percent]%)")
		. += span_notice("Damage modifier: [mod_text]")
		. += span_notice("Feed it with food or organic bodyparts to increase hunger.")

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

	// Grant info actions
	var/datum/action/innate/view_role_rules/fascia/rules_action = new(S)
	rules_action.Grant(S)

	var/datum/action/innate/check_fascia_hunger/hunger_action = new(S)
	hunger_action.Grant(S)

	to_chat(S, span_nicegreen("You inhabit the Fascia! You can speak to the wielder via say. Use your actions to aid them in battle and keep yourself fed!"))
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
	if(is_surging)
		return FALSE
	// Cannot attack while Iron Curtain is active
	if(linked_armor?.iron_curtain)
		to_chat(user, span_warning("You cannot attack while Iron Curtain is active!"))
		return FALSE
	// Apply hunger damage multiplier from spirit
	var/original_force = force
	if(possessed && bound_spirit)
		force = round(force * bound_spirit.get_damage_multiplier())
	. = ..()
	force = original_force
	// Inflict 3 bleed stacks on hit
	if(target && !QDELETED(target) && target.stat != DEAD)
		target.apply_lc_bleed(3)
	// Empowered strike from spirit
	if(empowered && target && !QDELETED(target) && target.stat != DEAD)
		var/modified_empower = empower_bonus
		if(possessed && bound_spirit)
			modified_empower = round(empower_bonus * bound_spirit.get_damage_multiplier())
		target.deal_damage(modified_empower, RED_DAMAGE)
		to_chat(user, span_nicegreen("The Fascia's empowered strike lands! (+[modified_empower] RED)"))
		if(bound_spirit)
			to_chat(bound_spirit, span_nicegreen("Your empowered strike lands!"))
		empowered = FALSE
		remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#FFD700")
		if(empower_timer_id)
			deltimer(empower_timer_id)
			empower_timer_id = null

/// Heartbeat Surge targeting - click at range after activating the action
/obj/item/ego_weapon/city/ring/fascia/afterattack(atom/target, mob/living/user, proximity_flag, params)
	if(special_ability_targeting && !proximity_flag && isliving(user))
		special_ability_targeting = FALSE
		INVOKE_ASYNC(src, PROC_REF(perform_heartbeat_surge), user, get_dir(user, target))
		return
	return ..()

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
	name = "Fascia Unleashed"
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
	actions_types = list(/datum/action/item_action/fascia_heartbeat_surge)
	special = "Phase 2 (Offensive). Triggers when the Iron Maiden wearer drops below 50% HP. Armor becomes invisible, grants +1.25 speed. \
		Click at range to Leap up to 7 tiles, dealing 15 RED to all adjacent targets on landing (1.5s CD). Missed leaps inflict a slowdown (10s CD). \
		Heartbeat Surge: plant blade, dash up to 5 tiles, perform an 8-hit slash combo on the first target hit (15s CD). \
		A ghost can possess this weapon for Empower Strike (+30 RED) and Compel Dash (forced 5-tile dash) abilities. \
		Use Reforge Iron Maiden (5s channel, 30s CD) to return to Phase 1."

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
	/// Heartbeat Surge cooldown tracker (world.time)
	var/heartbeat_surge_cooldown
	/// Whether Heartbeat Surge targeting is active
	var/special_ability_targeting = FALSE
	/// Whether a surge is currently in progress
	var/is_surging = FALSE
	/// Reference to the planted sword visual
	var/obj/structure/fascia_planted/planted_visual

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
	if(is_surging)
		return FALSE
	// Apply hunger damage multiplier from spirit
	var/original_force = force
	if(possessed && bound_spirit)
		force = round(force * bound_spirit.get_damage_multiplier())
	. = ..()
	force = original_force
	// Inflict 3 bleed stacks on hit
	if(target && !QDELETED(target) && target.stat != DEAD)
		target.apply_lc_bleed(3)
	// Empowered strike from spirit
	if(empowered && target && !QDELETED(target) && target.stat != DEAD)
		var/modified_empower = empower_bonus
		if(possessed && bound_spirit)
			modified_empower = round(empower_bonus * bound_spirit.get_damage_multiplier())
		target.deal_damage(modified_empower, RED_DAMAGE)
		to_chat(user, span_nicegreen("The Fascia's empowered strike lands! (+[modified_empower] RED)"))
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

/// Leap attack or Heartbeat Surge - click at range
/obj/item/ego_weapon/city/ring/fascia_unleashed/afterattack(atom/target, mob/living/user, proximity_flag, params)
	// Heartbeat Surge targeting takes priority
	if(special_ability_targeting && !proximity_flag && isliving(user))
		special_ability_targeting = FALSE
		INVOKE_ASYNC(src, PROC_REF(perform_heartbeat_surge), user, get_dir(user, target))
		return
	. = ..()
	if(proximity_flag)
		return
	if(is_leaping || is_surging)
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
	move_resist = INFINITY
	speak_emote = list("whispers")
	faction = list("neutral")
	status_flags = GODMODE
	del_on_death = FALSE

	/// The weapon this spirit inhabits (null when sheltered in armor)
	var/obj/item/bound_weapon
	/// Spirit hunger level (0-100, starts at 50)
	var/hunger = 50
	/// Maximum hunger level
	var/max_hunger = 100
	/// Hunger decay per Life() tick (0.067 = ~10 hunger per 5 minutes)
	var/hunger_decay = 0.067

/mob/living/simple_animal/fascia_spirit/Initialize()
	. = ..()

/// Returns the damage multiplier based on hunger (0 hunger = -25%, 50 = 0%, 100 = +10%)
/mob/living/simple_animal/fascia_spirit/proc/get_damage_multiplier()
	if(hunger <= 50)
		// Scale from -25% at 0 to 0% at 50
		return 1 + ((hunger - 50) * 0.005)
	else
		// Scale from 0% at 50 to +10% at 100
		return 1 + ((hunger - 50) * 0.002)

/// Feed the Fascia with food or bodyparts
/mob/living/simple_animal/fascia_spirit/proc/feed(obj/item/I, mob/user)
	var/feed_amount = 0

	if(istype(I, /obj/item/food))
		feed_amount = 10
		to_chat(user, span_notice("You feed [I] to the Fascia. It seems satisfied."))
	else if(istype(I, /obj/item/bodypart))
		var/obj/item/bodypart/BP = I
		if(BP.status == BODYPART_ROBOTIC)
			to_chat(user, span_warning("The Fascia rejects the robotic limb with disgust."))
			return FALSE
		feed_amount = 15
		to_chat(user, span_notice("You feed [I] to the Fascia. It hungrily consumes the flesh!"))
	else
		return FALSE

	hunger = clamp(hunger + feed_amount, 0, max_hunger)
	to_chat(src, span_nicegreen("You consume the offering! Hunger: [round(hunger)]/[max_hunger]"))
	playsound(user, 'sound/items/eatfood.ogg', 50, TRUE)
	qdel(I)
	return TRUE

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
	// Decay hunger over time
	if(hunger > 0)
		hunger = max(0, hunger - hunger_decay)
		// Warn wielder at low hunger
		if(hunger == 25 || hunger == 10 || hunger == 0)
			var/mob/living/wielder
			if(bound_weapon && ismob(bound_weapon.loc))
				wielder = bound_weapon.loc
			if(wielder)
				if(hunger == 0)
					to_chat(wielder, span_boldwarning("The Fascia is starving! Weapon damage reduced by 25%."))
				else
					to_chat(wielder, span_warning("The Fascia hungers... ([round(hunger)]/[max_hunger])"))

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
	icon_icon = 'icons/obj/spider_house/ring/ring_icons.dmi'
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

// Compel Dash - forces the wielder to dash 5 tiles in their facing direction, damaging mobs along the path
/datum/action/cooldown/fascia_compel_dash
	name = "Compel Dash"
	desc = "Compel the wielder to dash 5 tiles in their facing direction, dealing 50 RED damage to all in the way."
	icon_icon = 'icons/effects/cult_effects.dmi'
	button_icon_state = "pulse"
	cooldown_time = 5 SECONDS
	check_flags = AB_CHECK_CONSCIOUS

	/// Reference to the weapon
	var/datum/weakref/weapon_ref
	/// Whether a dash is currently in progress
	var/is_dashing = FALSE

/datum/action/cooldown/fascia_compel_dash/Trigger(trigger_flags)
	. = ..(trigger_flags)
	if(!.)
		return FALSE

	if(is_dashing)
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

	INVOKE_ASYNC(src, PROC_REF(perform_dash), wielder)
	StartCooldown()
	return TRUE

/// Performs a ScratchDash-style dash, moving tile-by-tile and damaging nearby mobs
/datum/action/cooldown/fascia_compel_dash/proc/perform_dash(mob/living/wielder)
	is_dashing = TRUE
	var/dash_dir = wielder.dir
	var/list/hit_mob = list()

	playsound(wielder, 'sound/abnormalities/ichthys/jump.ogg', 50, FALSE, -1)
	to_chat(wielder, span_warning("The Fascia compels you forward!"))
	to_chat(owner, span_nicegreen("You compel the wielder to dash!"))

	var/turf/current_turf = get_turf(wielder)
	for(var/i = 1 to 5)
		if(QDELETED(wielder) || wielder.stat == DEAD)
			break
		if(get_turf(wielder) != current_turf)
			break
		var/turf/next_turf = get_step(wielder, dash_dir)
		if(!next_turf || isclosedturf(next_turf))
			break
		if(locate(/obj/structure/window) in next_turf.contents)
			break
		if(locate(/obj/structure/table) in next_turf.contents)
			break
		if(locate(/obj/structure/railing) in next_turf.contents)
			break
		var/door_blocked = FALSE
		for(var/obj/machinery/door/D in next_turf.contents)
			if(D.density)
				door_blocked = TRUE
				break
		if(door_blocked)
			break
		sleep(1)
		wielder.forceMove(next_turf)
		current_turf = next_turf
		playsound(next_turf, 'sound/abnormalities/doomsdaycalendar/Lor_Slash_Generic.ogg', 20, 0, 4)
		for(var/turf/T in orange(get_turf(wielder), 1))
			if(isclosedturf(T))
				continue
			new /obj/effect/temp_visual/slice(T)
			hit_mob = wielder.HurtInTurf(T, hit_mob, 50, RED_DAMAGE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))

	is_dashing = FALSE

/datum/action/cooldown/fascia_compel_dash/Destroy()
	weapon_ref = null
	return ..()

// ========== HEARTBEAT SURGE ==========
// Action that lets the wielder plant their blade, dash forward, and claw at the first living target hit.
// Available on both Fascia phases.

/// Planted sword visual - cannot be interacted with
/obj/structure/fascia_planted
	name = "planted Fascia"
	desc = "The Fascia, driven into the ground."
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_weapons.dmi'
	icon_state = "planted_fascia"
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE

/obj/structure/fascia_planted/attack_hand(mob/living/user, list/modifiers)
	to_chat(user, span_warning("The blade is firmly planted and will not budge."))
	return TRUE

/obj/structure/fascia_planted/attackby(obj/item/I, mob/user, params)
	return TRUE

/// Heartbeat Surge action button - toggles targeting mode
/datum/action/item_action/fascia_heartbeat_surge
	name = "Heartbeat Surge"
	desc = "Plant your blade and dash forward, clawing at the first target you hit. Click a direction after activating."
	icon_icon = 'icons/obj/spider_house/ring/ring_icons.dmi'
	button_icon_state = "fascia"

/datum/action/item_action/fascia_heartbeat_surge/Trigger()
	var/obj/item/ego_weapon/city/ring/fascia/F1 = owner.get_active_held_item()
	var/obj/item/ego_weapon/city/ring/fascia_unleashed/F2 = owner.get_active_held_item()
	if(istype(F1))
		if(F1.is_surging)
			return
		if(F1.heartbeat_surge_cooldown > world.time)
			var/remaining = round((F1.heartbeat_surge_cooldown - world.time) / 10)
			to_chat(owner, span_warning("Heartbeat Surge is recharging! ([remaining] seconds remaining)"))
			return
		F1.special_ability_targeting = !F1.special_ability_targeting
		if(F1.special_ability_targeting)
			to_chat(owner, span_colossus("Let the cadence of your heartbeat surge, Fascia..."))
		else
			to_chat(owner, span_notice("You lower your stance."))
	else if(istype(F2))
		if(F2.is_surging)
			return
		if(F2.heartbeat_surge_cooldown > world.time)
			var/remaining = round((F2.heartbeat_surge_cooldown - world.time) / 10)
			to_chat(owner, span_warning("Heartbeat Surge is recharging! ([remaining] seconds remaining)"))
			return
		F2.special_ability_targeting = !F2.special_ability_targeting
		if(F2.special_ability_targeting)
			to_chat(owner, span_colossus("Let the cadence of your heartbeat surge, Fascia..."))
		else
			to_chat(owner, span_notice("You lower your stance."))

// ========== HEARTBEAT SURGE PROCS (Phase 1) ==========

/// Performs the full Heartbeat Surge sequence for Phase 1 Fascia
/obj/item/ego_weapon/city/ring/fascia/proc/perform_heartbeat_surge(mob/living/user, dash_dir)
	if(is_surging || QDELETED(user) || user.stat == DEAD)
		return

	// Cannot use while Iron Curtain is active
	if(linked_armor?.iron_curtain)
		to_chat(user, span_warning("You cannot use Heartbeat Surge while Iron Curtain is active!"))
		return

	is_surging = TRUE
	heartbeat_surge_cooldown = world.time + 15 SECONDS

	var/turf/sword_turf = get_turf(user)
	var/saved_inhand = inhand_icon_state
	var/saved_lefthand = lefthand_file
	var/saved_righthand = righthand_file

	// Plant the sword visual
	planted_visual = new /obj/structure/fascia_planted(sword_turf)
	planted_visual.icon_state = "planted_fascia"

	// Hide the weapon's inhand sprite
	inhand_icon_state = null
	lefthand_file = null
	righthand_file = null
	user.update_inv_hands()

	playsound(user, 'sound/abnormalities/ichthys/jump.ogg', 50, FALSE, -1)

	// Lift user off the ground and add shadow
	var/lift_amount = 8
	var/mutable_appearance/shadow_overlay = mutable_appearance('icons/obj/spider_house/ring/ring_icons.dmi', "shadow")
	shadow_overlay.pixel_y = -lift_amount
	shadow_overlay.alpha = 125
	user.add_overlay(shadow_overlay)
	animate(user, pixel_y = user.base_pixel_y + lift_amount, time = 2, easing = QUAD_EASING)
	sleep(2)

	// Dash tile-by-tile, stopping one tile before the first living mob
	var/mob/living/victim
	for(var/i = 1 to 5)
		if(QDELETED(user) || user.stat == DEAD)
			break
		var/turf/next_turf = get_step(user, dash_dir)
		if(!next_turf || isclosedturf(next_turf))
			break
		if(locate(/obj/structure/window) in next_turf.contents)
			break
		if(locate(/obj/structure/table) in next_turf.contents)
			break
		if(locate(/obj/structure/railing) in next_turf.contents)
			break
		var/door_blocked = FALSE
		for(var/obj/machinery/door/D in next_turf.contents)
			if(D.density)
				door_blocked = TRUE
				break
		if(door_blocked)
			break

		// Check for a living mob on the next tile before moving there
		for(var/mob/living/L in next_turf)
			if(L == user || L.stat == DEAD)
				continue
			victim = L
			break
		if(victim)
			break

		sleep(1)
		user.forceMove(next_turf)
		playsound(next_turf, 'sound/abnormalities/doomsdaycalendar/Lor_Slash_Generic.ogg', 20, 0, 4)

	// Remove shadow and lower user back to ground
	user.cut_overlay(shadow_overlay)
	animate(user, pixel_y = user.base_pixel_y, time = 2, easing = QUAD_EASING)
	sleep(2)

	if(victim && !QDELETED(victim) && victim.stat != DEAD)
		perform_claw_combo(user, victim, sword_turf, saved_inhand, saved_lefthand, saved_righthand, dash_dir)
	else
		// No target hit — walk back to sword
		return_to_sword(user, sword_turf)
		cleanup_surge(user, sword_turf, saved_inhand, saved_lefthand, saved_righthand)

/// Performs the 8-hit claw combo with pixel pushback
/obj/item/ego_weapon/city/ring/fascia/proc/perform_claw_combo(mob/living/user, mob/living/target, turf/sword_turf, saved_inhand, saved_lefthand, saved_righthand, direction)
	var/dx = 0
	var/dy = 0
	if(direction & EAST)
		dx = 1
	if(direction & WEST)
		dx = -1
	if(direction & NORTH)
		dy = 1
	if(direction & SOUTH)
		dy = -1

	// Lock both in place
	var/combo_duration = 2.5 SECONDS
	user.Immobilize(combo_duration)
	user.changeNext_move(combo_duration)
	target.Immobilize(combo_duration)

	// Handle simple mobs
	var/mob/living/simple_animal/hostile/simple_target
	if(istype(target, /mob/living/simple_animal/hostile))
		simple_target = target
		simple_target.toggle_ai(AI_OFF)

	// Justice scaling for damage against simple mobs
	var/hit_damage = 10
	if(simple_target)
		var/justice_mod = 1 + (get_modified_attribute_level(user, JUSTICE_ATTRIBUTE) / 100)
		hit_damage = round(hit_damage * justice_mod)

	var/accumulated_px = 0

	for(var/i = 1 to 8)
		if(QDELETED(target) || target.stat == DEAD || QDELETED(user) || user.stat == DEAD)
			break
		user.do_attack_animation(target, ATTACK_EFFECT_CLAW)
		playsound(user, 'sound/weapons/slice.ogg', 50, TRUE)
		target.deal_damage(hit_damage, RED_DAMAGE, user, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))

		// Pixel nudge - push target back 12px, user follows
		accumulated_px += 12
		animate(target, pixel_x = target.base_pixel_x + (dx * accumulated_px), pixel_y = target.base_pixel_y + (dy * accumulated_px), time = 1, easing = QUAD_EASING)
		animate(user, pixel_x = user.base_pixel_x + (dx * accumulated_px), pixel_y = user.base_pixel_y + (dy * accumulated_px), time = 1, easing = QUAD_EASING)

		// Step to next tile when accumulated pushback crosses a tile boundary
		if(accumulated_px >= 32)
			var/turf/next = get_step(target, direction)
			if(next && !isclosedturf(next))
				target.forceMove(next)
				user.forceMove(get_turf(target))
			accumulated_px -= 32
			target.pixel_x = target.base_pixel_x + (dx * accumulated_px)
			target.pixel_y = target.base_pixel_y + (dy * accumulated_px)
			user.pixel_x = user.base_pixel_x + (dx * accumulated_px)
			user.pixel_y = user.base_pixel_y + (dy * accumulated_px)

		sleep(2)

	// Reset pixel offsets
	if(!QDELETED(target))
		animate(target, pixel_x = target.base_pixel_x, pixel_y = target.base_pixel_y, time = 2)
	if(!QDELETED(user))
		animate(user, pixel_x = user.base_pixel_x, pixel_y = user.base_pixel_y, time = 2)

	// Reactivate simple mob AI
	if(simple_target && !QDELETED(simple_target))
		simple_target.toggle_ai(AI_ON)

	sleep(3)
	// Walk back to sword
	return_to_sword(user, sword_turf)
	// Restore weapon and feed spirit
	cleanup_surge(user, sword_turf, saved_inhand, saved_lefthand, saved_righthand)
	if(possessed && bound_spirit)
		bound_spirit.hunger = clamp(bound_spirit.hunger + 15, 0, bound_spirit.max_hunger)
		to_chat(user, span_notice("The Fascia hungrily consumes the blood from your claws."))
		to_chat(bound_spirit, span_nicegreen("You feast on the blood... Hunger: [round(bound_spirit.hunger)]/[bound_spirit.max_hunger]"))

/// Walks the user back to the sword tile-by-tile
/obj/item/ego_weapon/city/ring/fascia/proc/return_to_sword(mob/living/user, turf/sword_turf)
	if(QDELETED(user) || !sword_turf)
		return
	// Face toward the sword
	var/return_dir = get_dir(user, sword_turf)
	if(return_dir)
		user.setDir(return_dir)
	// Walk back tile-by-tile
	for(var/i = 1 to 7)
		if(QDELETED(user) || get_turf(user) == sword_turf)
			break
		step_towards(user, sword_turf)
		sleep(2)
	// Ensure we end up on the sword turf
	if(!QDELETED(user) && get_turf(user) != sword_turf)
		user.forceMove(sword_turf)

/// Cleans up the surge state - restores weapon visuals
/obj/item/ego_weapon/city/ring/fascia/proc/cleanup_surge(mob/living/user, turf/sword_turf, saved_inhand, saved_lefthand, saved_righthand)
	if(!QDELETED(user))
		user.pixel_x = user.base_pixel_x
		user.pixel_y = user.base_pixel_y
	inhand_icon_state = saved_inhand
	lefthand_file = saved_lefthand
	righthand_file = saved_righthand
	if(!QDELETED(user))
		user.update_inv_hands()
	if(planted_visual)
		QDEL_NULL(planted_visual)
	is_surging = FALSE

// ========== HEARTBEAT SURGE PROCS (Phase 2) ==========

/// Performs the full Heartbeat Surge sequence for Phase 2 Fascia
/obj/item/ego_weapon/city/ring/fascia_unleashed/proc/perform_heartbeat_surge(mob/living/user, dash_dir)
	if(is_surging || QDELETED(user) || user.stat == DEAD)
		return
	is_surging = TRUE
	heartbeat_surge_cooldown = world.time + 15 SECONDS

	var/turf/sword_turf = get_turf(user)
	var/saved_inhand = inhand_icon_state
	var/saved_lefthand = lefthand_file
	var/saved_righthand = righthand_file

	// Plant the sword visual
	planted_visual = new /obj/structure/fascia_planted(sword_turf)
	planted_visual.icon_state = "planted_fascia_unleashed"

	// Hide the weapon's inhand sprite
	inhand_icon_state = null
	lefthand_file = null
	righthand_file = null
	user.update_inv_hands()

	playsound(user, 'sound/abnormalities/ichthys/jump.ogg', 50, FALSE, -1)

	// Backflip — lift higher and spin 360 degrees
	var/lift_amount = 20
	var/mutable_appearance/shadow_overlay = mutable_appearance('icons/obj/spider_house/ring/ring_icons.dmi', "shadow")
	shadow_overlay.pixel_y = -lift_amount
	shadow_overlay.alpha = 125
	user.add_overlay(shadow_overlay)
	animate(user, pixel_y = user.base_pixel_y + lift_amount, time = 3, easing = QUAD_EASING)
	user.SpinAnimation(speed = 5, loops = 1)
	sleep(5)

	// Dash tile-by-tile, stopping one tile before the first living mob
	var/mob/living/victim
	for(var/i = 1 to 5)
		if(QDELETED(user) || user.stat == DEAD)
			break
		var/turf/next_turf = get_step(user, dash_dir)
		if(!next_turf || isclosedturf(next_turf))
			break
		if(locate(/obj/structure/window) in next_turf.contents)
			break
		if(locate(/obj/structure/table) in next_turf.contents)
			break
		if(locate(/obj/structure/railing) in next_turf.contents)
			break
		var/door_blocked = FALSE
		for(var/obj/machinery/door/D in next_turf.contents)
			if(D.density)
				door_blocked = TRUE
				break
		if(door_blocked)
			break

		// Check for a living mob on the next tile before moving there
		for(var/mob/living/L in next_turf)
			if(L == user || L.stat == DEAD)
				continue
			victim = L
			break
		if(victim)
			break

		sleep(1)
		user.forceMove(next_turf)
		playsound(next_turf, 'sound/abnormalities/doomsdaycalendar/Lor_Slash_Generic.ogg', 20, 0, 4)

	// Remove shadow and lower user back to ground
	user.cut_overlay(shadow_overlay)
	animate(user, pixel_y = user.base_pixel_y, time = 3, easing = QUAD_EASING)
	sleep(3)

	if(victim && !QDELETED(victim) && victim.stat != DEAD)
		perform_claw_combo(user, victim, sword_turf, saved_inhand, saved_lefthand, saved_righthand, dash_dir)
	else
		// No target hit — walk back to sword
		return_to_sword(user, sword_turf)
		cleanup_surge(user, sword_turf, saved_inhand, saved_lefthand, saved_righthand)

/// Performs the 8-hit slash combo with pixel pushback for Phase 2
/obj/item/ego_weapon/city/ring/fascia_unleashed/proc/perform_claw_combo(mob/living/user, mob/living/target, turf/sword_turf, saved_inhand, saved_lefthand, saved_righthand, direction)
	var/dx = 0
	var/dy = 0
	if(direction & EAST)
		dx = 1
	if(direction & WEST)
		dx = -1
	if(direction & NORTH)
		dy = 1
	if(direction & SOUTH)
		dy = -1

	// Lock both in place
	var/combo_duration = 2.5 SECONDS
	user.Immobilize(combo_duration)
	user.changeNext_move(combo_duration)
	target.Immobilize(combo_duration)

	// Handle simple mobs
	var/mob/living/simple_animal/hostile/simple_target
	if(istype(target, /mob/living/simple_animal/hostile))
		simple_target = target
		simple_target.toggle_ai(AI_OFF)

	// Justice scaling for damage against simple mobs
	var/hit_damage = 10
	if(simple_target)
		var/justice_mod = 1 + (get_modified_attribute_level(user, JUSTICE_ATTRIBUTE) / 100)
		hit_damage = round(hit_damage * justice_mod)

	var/accumulated_px = 0

	for(var/i = 1 to 8)
		if(QDELETED(target) || target.stat == DEAD || QDELETED(user) || user.stat == DEAD)
			break
		user.do_attack_animation(target, ATTACK_EFFECT_SLASH)
		playsound(user, 'sound/weapons/slice.ogg', 50, TRUE)
		target.deal_damage(hit_damage, RED_DAMAGE, user, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))

		// Pixel nudge - push target back 12px, user follows
		accumulated_px += 12
		animate(target, pixel_x = target.base_pixel_x + (dx * accumulated_px), pixel_y = target.base_pixel_y + (dy * accumulated_px), time = 1, easing = QUAD_EASING)
		animate(user, pixel_x = user.base_pixel_x + (dx * accumulated_px), pixel_y = user.base_pixel_y + (dy * accumulated_px), time = 1, easing = QUAD_EASING)

		// Step to next tile when accumulated pushback crosses a tile boundary
		if(accumulated_px >= 32)
			var/turf/next = get_step(target, direction)
			if(next && !isclosedturf(next))
				target.forceMove(next)
				user.forceMove(get_turf(target))
			accumulated_px -= 32
			target.pixel_x = target.base_pixel_x + (dx * accumulated_px)
			target.pixel_y = target.base_pixel_y + (dy * accumulated_px)
			user.pixel_x = user.base_pixel_x + (dx * accumulated_px)
			user.pixel_y = user.base_pixel_y + (dy * accumulated_px)

		sleep(2)

	// Reset pixel offsets
	if(!QDELETED(target))
		animate(target, pixel_x = target.base_pixel_x, pixel_y = target.base_pixel_y, time = 2)
	if(!QDELETED(user))
		animate(user, pixel_x = user.base_pixel_x, pixel_y = user.base_pixel_y, time = 2)

	// Reactivate simple mob AI
	if(simple_target && !QDELETED(simple_target))
		simple_target.toggle_ai(AI_ON)

	sleep(3)
	// Walk back to sword
	return_to_sword(user, sword_turf)
	// Restore weapon and feed spirit
	cleanup_surge(user, sword_turf, saved_inhand, saved_lefthand, saved_righthand)
	if(possessed && bound_spirit)
		bound_spirit.hunger = clamp(bound_spirit.hunger + 15, 0, bound_spirit.max_hunger)
		to_chat(user, span_notice("The Fascia hungrily consumes the blood from your claws."))
		to_chat(bound_spirit, span_nicegreen("You feast on the blood... Hunger: [round(bound_spirit.hunger)]/[bound_spirit.max_hunger]"))

/// Walks the user back to the sword tile-by-tile
/obj/item/ego_weapon/city/ring/fascia_unleashed/proc/return_to_sword(mob/living/user, turf/sword_turf)
	if(QDELETED(user) || !sword_turf)
		return
	// Face toward the sword
	var/return_dir = get_dir(user, sword_turf)
	if(return_dir)
		user.setDir(return_dir)
	// Walk back tile-by-tile
	for(var/i = 1 to 7)
		if(QDELETED(user) || get_turf(user) == sword_turf)
			break
		step_towards(user, sword_turf)
		sleep(2)
	// Ensure we end up on the sword turf
	if(!QDELETED(user) && get_turf(user) != sword_turf)
		user.forceMove(sword_turf)

/// Cleans up the surge state for Phase 2
/obj/item/ego_weapon/city/ring/fascia_unleashed/proc/cleanup_surge(mob/living/user, turf/sword_turf, saved_inhand, saved_lefthand, saved_righthand)
	if(!QDELETED(user))
		user.pixel_x = user.base_pixel_x
		user.pixel_y = user.base_pixel_y
	inhand_icon_state = saved_inhand
	lefthand_file = saved_lefthand
	righthand_file = saved_righthand
	if(!QDELETED(user))
		user.update_inv_hands()
	if(planted_visual)
		QDEL_NULL(planted_visual)
	is_surging = FALSE

// ================== RING EGO DATUMS ==================
// Placed here rather than in _cityweapons_datums.dm / _cityarmor_datums.dm
// to prevent DM merge conflicts with other sub-PRs that modify those shared files.

/// Tibia (Maestro Weapon)
/datum/ego_datum/weapon/city/ring_tibia
	item_path = /obj/item/ego_weapon/city/ring/tibia
	cost = 100
	ego_tags = list(EGO_TAG_REACH, EGO_TAG_SPECIAL_RANGED, EGO_TAG_AOE_RADIAL, EGO_TAG_AOE_PIERCING, EGO_TAG_DOT)

/// Fascia (Apprentice Weapon — reads stats from weapon, dispenses Iron Maiden armor)
/datum/ego_datum/weapon/city/ring_fascia
	item_path = /obj/item/ego_weapon/city/ring/fascia
	dispense_path = /obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice
	cost = 90
	ego_tags = list(EGO_TAG_MOBILITY, EGO_TAG_DOT)

/// Corporist Maestro Garb
/datum/ego_datum/armor/city/ring_maestro
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/ring_maestro
	cost = 100

/// Fascia Unleashed (Phase 2 — also dispenses Iron Maiden armor)
/datum/ego_datum/weapon/city/ring_fascia_unleashed
	item_path = /obj/item/ego_weapon/city/ring/fascia_unleashed
	dispense_path = /obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice
	cost = 90
	ego_tags = list(EGO_TAG_MOBILITY, EGO_TAG_DOT)

/// Iron Maiden Armour (Apprentice)
/datum/ego_datum/armor/city/ring_apprentice
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice
	cost = 90
	ego_tags = list(EGO_TAG_MOBILITY)
