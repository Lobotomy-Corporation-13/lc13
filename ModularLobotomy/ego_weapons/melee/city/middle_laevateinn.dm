/// Laevateinn — the sealed relic sword of the Middle Nursefather.
/// Starts weak, gains power as the wielder loses HP (unseal at 75%, 50%, 25%).
/// attack_self() consumes Grudge into Tattoos (self-buff).
/// afterattack() at range dashes to target and triggers a combo.
/obj/item/ego_weapon/city/laevateinn
	name = "Laevateinn"
	desc = "An oversized metallic sword bound by three layers of chain seals. A burning Relic of immense power, though its current wielder is not its rightful owner."
	icon = 'icons/obj/spider_house/middle/laevateinn_icon.dmi'
	lefthand_file = 'icons/obj/spider_house/middle/laevateinn_left.dmi'
	righthand_file = 'icons/obj/spider_house/middle/laevateinn_right.dmi'
	icon_state = "laevateinn_fullseal"
	inhand_icon_state = "laevateinn_fullseal"
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	worn_icon = 'icons/obj/spider_house/middle/laevateinn_worn.dmi'
	worn_icon_state = "laevateinn_fullseal"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_SUITSTORE
	var/datum/element/item_scaling/scaling_element
	force = 20
	hitsound = 'sound/weapons/middle_nursefather/middlefather_melee_sealed.ogg'
	damtype = RED_DAMAGE
	attack_speed = 1.5
	w_class = WEIGHT_CLASS_BULKY
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100
	)
	special = {"Laevateinn is bound by three chain seals that break as you lose HP (75%, 50%, 25% thresholds).
Each unseal changes base damage and adds armor-piercing FIRE damage:
  <b>Full Seal</b>: 20 base (RED) | 0 FIRE damage | 4 Bleed per hit
  <b>1 Seal Removed</b>: 32 base (RED) | +3 FIRE damage | 2 Bleed + 1 Overheat per hit
  <b>2 Seals Removed</b>: 40 base (RED) | +10 FIRE damage | 1 Bleed + 3 Overheat per hit
  <b>Fully Unsealed</b>: 33 base (RED) | +32 FIRE damage | 6 Overheat per hit

<b>Overheat Aura</b>: At 2 seals removed, Laevateinn radiates heat that applies Overheat to nearby enemies within 5 tiles.
At full unseal, the aura intensifies and expands to 7 tiles.

<b>Grudge</b>: Built by attacking (+1 per hit) and taking damage (heavier hits = more Grudge, max 20).
At 10+ Grudge, you gain a purple outline that grows with stacks.
At max Grudge, a line is declared: a summary execution is in order.

<b>Enhancement Tattoos</b>: Use the sword in-hand with 5+ Grudge to consume ALL Grudge into a Tattoo buff.
Tier scales with Grudge consumed — Tier 1 (5-9), Tier 2 (10-14), Tier 3 (15-19), Tier 4 (20).
Tattoos grant +5/10/15/20 passive bonus damage per hit for 30 seconds, and empower your next dash combo.

<b>Dash Combo</b>: Click a living target 3-7 tiles away to dash to them (costs 10 Grudge, 10s cooldown).
The dash triggers a combo attack. Without Tattoos, a basic combo is performed.
With Tattoos active, the combo is empowered based on your current seal stage:
  Full Seal → Stomping | 1 Seal Removed → I'll Gut Ya Like a Fish
  2 Seals Removed → Gut Stab | Fully Unsealed → Complete and Total Extermination
Empowered combos consume the Tattoo buff. All combos have wall-breaking knockback.
During combos, the target is shielded from outside damage, and damage to you is reduced to 1. Grudge gain is paused.

<b>Reseal</b>: Examine the sword to reseal it, restoring all chain seals and removing seal structures from the map."}
	/// Current seal stage: 0 = full seal, 1 = unseal1, 2 = unseal2, 3 = full power
	var/seal_stage = 0
	/// Whether a combo is currently in progress
	var/combo_in_progress = FALSE
	COOLDOWN_DECLARE(dash_cd)
	COOLDOWN_DECLARE(reseal_cd)

/obj/item/ego_weapon/city/laevateinn/Initialize(mapload)
	. = ..()
	scaling_element = new(src)
	scaling_element.Attach(src, 1, 0.8, -20, -20)

/obj/item/ego_weapon/city/laevateinn/build_worn_icon(default_layer, default_icon_file, isinhands, femaleuniform, override_state, override_file)
	var/mutable_appearance/MA = ..()
	if(MA && !isinhands)
		MA.pixel_x -= 16
		MA.pixel_y -= 16
	return MA

/obj/item/ego_weapon/city/laevateinn/CanUseEgo(mob/living/user)
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.mind?.assigned_role == "Ex Great Brother")
			return TRUE
	return ..()

/// Checks if the user is the rightful wielder (Ex Great Brother).
/obj/item/ego_weapon/city/laevateinn/proc/IsRightfulWielder(mob/living/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	if(H.mind?.assigned_role == "Ex Great Brother")
		return TRUE
	return FALSE

/// Grants weapon-related components when picked up.
/// In city mode, burns non-rightful wielders.
/obj/item/ego_weapon/city/laevateinn/pickup(mob/user)
	. = ..()
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user

	if(SSmaptype.maptype in SSmaptype.citymaps)
		if(!IsRightfulWielder(H))
			BurnUnworthyWielder(H)
			return
		// The Ex-Great Brother is not the rightful owner of Laevateinn — it resists, but he forces it
		H.deal_damage(5, FIRE, flags = DAMAGE_PIERCING)
		to_chat(H, span_warning("Laevateinn burns in your grip — you are not its rightful owner. But you force it to obey."))

	// Grant weapon-related components
	if(!H.GetComponent(/datum/component/middle_grudge_gain))
		H.AddComponent(/datum/component/middle_grudge_gain)
	if(!H.GetComponent(/datum/component/laevateinn_seal))
		H.AddComponent(/datum/component/laevateinn_seal, src)
	// Non-Great Brother users need the /middle passive for seal healthgates (clone damage won't apply to them)
	if(!IsRightfulWielder(H))
		if(!H.GetComponent(/datum/component/nursefather_passive/middle))
			H.AddComponent(/datum/component/nursefather_passive/middle)

/// Removes weapon-related components when dropped. Doesn't remove passive from Great Brother.
/obj/item/ego_weapon/city/laevateinn/dropped(mob/user)
	. = ..()
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	var/datum/component/middle_grudge_gain/grudge = H.GetComponent(/datum/component/middle_grudge_gain)
	if(grudge)
		qdel(grudge)
	var/datum/component/laevateinn_seal/seal = H.GetComponent(/datum/component/laevateinn_seal)
	if(seal)
		qdel(seal)
	// Only remove passive from non-Great Brother users (Great Brother keeps it permanently)
	if(!IsRightfulWielder(H))
		var/datum/component/nursefather_passive/middle/passive = H.GetComponent(/datum/component/nursefather_passive/middle)
		if(passive)
			qdel(passive)

/// Burns an unworthy wielder who tries to hold or drag Laevateinn in city mode.
/obj/item/ego_weapon/city/laevateinn/proc/BurnUnworthyWielder(mob/living/carbon/human/H)
	to_chat(H, span_userdanger("Laevateinn sears your flesh! The relic rejects you!"))
	H.visible_message(span_danger("[H] screams as Laevateinn burns [H.p_their()] hands!"))
	H.deal_damage(25, FIRE, flags = DAMAGE_PIERCING)
	H.apply_lc_overheat(10)
	new /obj/effect/temp_visual/dir_setting/laevateinn_blast(get_turf(H))
	playsound(H, 'sound/effects/burn.ogg', 50, TRUE)
	H.dropItemToGround(src, TRUE)

/// Prevents non-rightful wielders from dragging in city mode.
/obj/item/ego_weapon/city/laevateinn/attack_hand(mob/user)
	if((SSmaptype.maptype in SSmaptype.citymaps) && ishuman(user) && !IsRightfulWielder(user))
		var/mob/living/carbon/human/H = user
		BurnUnworthyWielder(H)
		return
	return ..()

/obj/item/ego_weapon/city/laevateinn/examine(mob/user)
	. = ..()
	if(seal_stage > 0 && ishuman(user))
		. += span_notice("<a href='?src=[REF(src)];reseal=1'>Reseal Laevateinn</a> — restore all chain seals.")

/obj/item/ego_weapon/city/laevateinn/Topic(href, href_list)
	. = ..()
	if(href_list["reseal"])
		var/mob/living/carbon/human/user = usr
		if(!istype(user))
			return
		if(!(src in user.held_items))
			to_chat(user, span_warning("You need to be holding Laevateinn to reseal it."))
			return
		if(seal_stage <= 0)
			to_chat(user, span_warning("Laevateinn is already fully sealed."))
			return
		if(combo_in_progress)
			to_chat(user, span_warning("Cannot reseal during a combo!"))
			return
		ResealWeapon(user)

/// Reseals Laevateinn to stage 0, removing all seal structures from the map.
/obj/item/ego_weapon/city/laevateinn/proc/ResealWeapon(mob/living/carbon/human/user)
	// Remove all seal structures from the map
	for(var/obj/structure/laevateinn_seal/seal in world)
		qdel(seal)

	// Reset seal stage
	SetSealStage(0)
	user.set_light(0)
	COOLDOWN_START(src, reseal_cd, 10 SECONDS)

	// Reset the seal component gates
	var/datum/component/laevateinn_seal/seal_comp = user.GetComponent(/datum/component/laevateinn_seal)
	if(seal_comp)
		seal_comp.gates_triggered = list(FALSE, FALSE, FALSE)
		seal_comp.thresholds_initialized = FALSE
		if(seal_comp.overheat_aura_active)
			seal_comp.overheat_aura_active = FALSE
			STOP_PROCESSING(SSobj, seal_comp)

	// Visual feedback
	new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(user))
	playsound(user, 'sound/weapons/middle_nursefather/middlefather_break_seal.ogg', 50, TRUE)
	user.visible_message(span_notice("[user] rebinds the chain seals on Laevateinn."))
	to_chat(user, span_notice("Laevateinn has been resealed."))

/// Updates icon state to match current seal stage
/obj/item/ego_weapon/city/laevateinn/proc/UpdateSealVisuals()
	var/list/seal_states = list("laevateinn_fullseal", "laevateinn_unseal1", "laevateinn_unseal2", "laevateinn_fullpower")
	var/new_state = seal_states[seal_stage + 1]
	icon_state = new_state
	inhand_icon_state = new_state
	worn_icon_state = new_state
	update_icon()
	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_hands()
		M.regenerate_icons()

/// Sets the seal stage and updates weapon stats.
/// Higher stages convert a portion of damage to armor-bypassing FIRE.
/obj/item/ego_weapon/city/laevateinn/proc/SetSealStage(new_stage)
	seal_stage = clamp(new_stage, 0, 3)
	switch(seal_stage)
		if(0)
			force = 20
			hitsound = 'sound/weapons/middle_nursefather/middlefather_melee_sealed.ogg'
		if(1)
			force = 32
			hitsound = 'sound/weapons/middle_nursefather/middlefather_blunt.ogg'
		if(2)
			force = 40
			hitsound = 'sound/weapons/middle_nursefather/middlefather_slash.ogg'
		if(3)
			force = 33
			hitsound = 'sound/weapons/middle_nursefather/middlefather_scorch_slash.ogg'
	UpdateSealVisuals()

/// Returns the FIRE bypass damage for the current seal stage.
/obj/item/ego_weapon/city/laevateinn/proc/GetFireBypass()
	switch(seal_stage)
		if(0)
			return 0
		if(1)
			return 3
		if(2)
			return 10
		if(3)
			return 32
	return 0

/// Normal attack — build Grudge, apply FIRE bypass and Tattoo bonus damage.
/obj/item/ego_weapon/city/laevateinn/attack(mob/living/target, mob/living/user)
	if(!ishuman(user) || combo_in_progress)
		return ..()
	var/mob/living/carbon/human/H = user

	. = ..()
	H.AddGrudge(1)

	// Apply FIRE bypass damage (armor-ignoring, based on seal stage)
	var/fire_bypass = GetFireBypass()
	if(fire_bypass > 0)
		middle_combo_damage(target, H, fire_bypass, FIRE)

	// Apply Bleed/Overheat on hit based on seal stage
	switch(seal_stage)
		if(0)
			target.apply_lc_bleed(4)
		if(1)
			target.apply_lc_bleed(2)
			target.apply_lc_overheat(1)
		if(2)
			target.apply_lc_bleed(1)
			target.apply_lc_overheat(3)
		if(3)
			target.apply_lc_overheat(6)

	// Apply Tattoo passive bonus damage
	var/datum/status_effect/middle_tattoos/T = H.has_status_effect(/datum/status_effect/middle_tattoos)
	if(T)
		var/tattoo_bonus = T.GetDamageBonus()
		if(tattoo_bonus > 0)
			middle_combo_damage(target, H, tattoo_bonus, RED_DAMAGE)

/// attack_self — Activate Tattoos: consume Grudge into a self-buff.
/obj/item/ego_weapon/city/laevateinn/attack_self(mob/user)
	if(!ishuman(user))
		return ..()
	if(combo_in_progress)
		to_chat(user, span_warning("Cannot activate Tattoos during a combo!"))
		return
	var/mob/living/carbon/human/H = user

	if(H.GetGrudge() < 5)
		to_chat(H, span_warning("Not enough Grudge! ([H.GetGrudge()]/5)"))
		return

	// Consume Grudge → determine tier
	var/grudge_consumed = H.ConsumeAllGrudge()
	var/tattoo_tier
	switch(grudge_consumed)
		if(5 to 9)
			tattoo_tier = 1
		if(10 to 14)
			tattoo_tier = 2
		if(15 to 19)
			tattoo_tier = 3
		if(20 to INFINITY)
			tattoo_tier = 4
		else
			tattoo_tier = 1

	// Apply Tattoos to self
	H.ApplyMiddleTattoos(tattoo_tier)

	// Visual/audio feedback
	new /obj/effect/temp_visual/dir_setting/laevateinn_blast(get_turf(H))
	playsound(H, 'sound/weapons/middle_nursefather/middlefather_dash.ogg', 50, TRUE)
	H.visible_message(span_danger("[H]'s enhancement tattoos flare with power!"))
	to_chat(H, span_notice("Tattoos activated (Tier [tattoo_tier])!"))

/// afterattack — click a target at range (3-7 tiles) to dash and trigger a combo.
/// Also checks for mirror_weakened targets for the free execution dash.
/obj/item/ego_weapon/city/laevateinn/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(combo_in_progress)
		return
	if(!isliving(target) || !ishuman(user))
		return
	var/mob/living/L = target
	var/mob/living/carbon/human/H = user
	if(L.stat == DEAD || L == H)
		return

	// Mirror shard execution — free dash to mirror_weakened targets at any range
	var/datum/status_effect/mirror_weakened/weakened = L.has_status_effect(/datum/status_effect/mirror_weakened)
	if(weakened)
		INVOKE_ASYNC(src, PROC_REF(MirrorExecution), L, H, weakened)
		return

	if(proximity_flag)
		return

	var/dist = get_dist(H, L)
	if(dist < 3 || dist > 7)
		return
	if(!COOLDOWN_FINISHED(src, dash_cd))
		var/time_left = DisplayTimeText(COOLDOWN_TIMELEFT(src, dash_cd))
		to_chat(H, span_warning("Dash is on cooldown! ([time_left] remaining)"))
		return
	if(H.GetGrudge() < 10)
		to_chat(H, span_warning("Not enough Grudge to dash! ([H.GetGrudge()]/10)"))
		return

	H.ConsumeGrudge(10)
	INVOKE_ASYNC(src, PROC_REF(DashAndCombo), L, H)

/// Dashes to a target and triggers a combo based on Tattoo + seal stage.
/obj/item/ego_weapon/city/laevateinn/proc/DashAndCombo(mob/living/target, mob/living/carbon/human/user)
	COOLDOWN_START(src, dash_cd, 10 SECONDS)
	combo_in_progress = TRUE

	// Dash animation — direct line from origin to target
	var/turf/origin = get_turf(user)
	var/turf/dest = get_turf(target)
	var/dash_dir = get_dir(user, target)

	// Smoke at origin
	var/obj/effect/temp_visual/dir_setting/smoke_afterdash/aftersmoke = new(origin, dash_dir)
	aftersmoke.color = "#D8B4FE"
	// Smoke trail along direct line (not 8-directional)
	var/list/line_turfs = getline(origin, dest)
	for(var/turf/T in line_turfs)
		if(T == origin || T == dest)
			continue
		var/obj/effect/temp_visual/dir_setting/smoke_dash/trailsmoke = new(T, dash_dir)
		trailsmoke.color = "#D8B4FE"

	// Fade out + move
	animate(user, alpha = 0, pixel_y = user.base_pixel_y + 16, time = 0.15 SECONDS)
	sleep(0.15 SECONDS)
	user.forceMove(get_step(target, get_dir(target, user)))
	user.pixel_y = user.base_pixel_y + 12
	animate(user, alpha = 255, pixel_y = user.base_pixel_y, time = 0.15 SECONDS, easing = BOUNCE_EASING)
	user.setDir(get_dir(user, target))

	// Trigger combo
	TriggerCombo(target, user)

/// Determines which combo to trigger based on seal stage and tattoo presence.
/// Reduces incoming damage to 1 during combo (doesn't deny — mobs keep aggro).
/obj/item/ego_weapon/city/laevateinn/proc/TriggerCombo(mob/living/target, mob/living/carbon/human/user)
	var/tattoo_tier = user.GetMiddleTattooTier()
	var/has_tattoos = (tattoo_tier > 0)
	var/consumed_tier = 0

	// Powered combos consume tattoos
	if(has_tattoos)
		consumed_tier = user.ConsumeMiddleTattoos()

	if(has_tattoos)
		switch(seal_stage)
			if(0)
				user.apply_status_effect(/datum/status_effect/middle_combo_protection, 8 SECONDS)
				middle_combo_stomping(target, user, consumed_tier)
				addtimer(CALLBACK(src, PROC_REF(EndCombo)), 8 SECONDS)
			if(1)
				user.apply_status_effect(/datum/status_effect/middle_combo_protection, 10 SECONDS)
				middle_combo_gut_fish(target, user, consumed_tier)
				addtimer(CALLBACK(src, PROC_REF(EndCombo)), 10 SECONDS)
			if(2)
				user.apply_status_effect(/datum/status_effect/middle_combo_protection, 12 SECONDS)
				middle_combo_gut_stab(target, user, consumed_tier)
				addtimer(CALLBACK(src, PROC_REF(EndCombo)), 12 SECONDS)
			if(3)
				user.apply_status_effect(/datum/status_effect/middle_combo_protection, 18 SECONDS)
				middle_combo_total_extermination(target, user, consumed_tier)
				addtimer(CALLBACK(src, PROC_REF(EndCombo)), 18 SECONDS)
	else
		user.apply_status_effect(/datum/status_effect/middle_combo_protection, 10 SECONDS)
		middle_combo_chain_grapple(target, user, consumed_tier)
		addtimer(CALLBACK(src, PROC_REF(EndCombo)), 10 SECONDS)

/obj/item/ego_weapon/city/laevateinn/proc/EndCombo()
	combo_in_progress = FALSE
	// Clean up combo protection if still active
	if(ismob(loc))
		var/mob/living/user = loc
		user.remove_status_effect(/datum/status_effect/middle_combo_protection)
	else if(ishuman(loc?.loc))
		var/mob/living/user = loc.loc
		user.remove_status_effect(/datum/status_effect/middle_combo_protection)

/// Mirror Shard execution — free dash to a mirror_weakened target, then gib the relic user
/// and deal 200 RED to the held target. No grudge cost, ignores cooldown.
/// Works regardless of whether the clicked target is the relic user or the pinned victim.
/obj/item/ego_weapon/city/laevateinn/proc/MirrorExecution(mob/living/clicked, mob/living/carbon/human/user, datum/status_effect/mirror_weakened/weakened)
	combo_in_progress = TRUE

	// Resolve who is the relic user (gets gibbed) and who is the pinned target (takes 200 RED)
	var/mob/living/relic_user
	var/mob/living/pinned_target
	if(weakened.is_relic_user)
		relic_user = clicked
		pinned_target = weakened.partner
	else
		pinned_target = clicked
		relic_user = weakened.partner

	// Lock both victims in place for the entire execution
	if(relic_user && !QDELETED(relic_user))
		ADD_TRAIT(relic_user, TRAIT_IMMOBILIZED, "mirror_execution")
	if(pinned_target && !QDELETED(pinned_target))
		ADD_TRAIT(pinned_target, TRAIT_IMMOBILIZED, "mirror_execution")

	// Dash animation — dash to whichever was clicked
	var/turf/origin = get_turf(user)
	var/turf/dest = get_turf(clicked)
	var/dash_dir = get_dir(user, clicked)

	var/obj/effect/temp_visual/dir_setting/smoke_afterdash/aftersmoke = new(origin, dash_dir)
	aftersmoke.color = "#D8B4FE"
	var/list/line_turfs = getline(origin, dest)
	for(var/turf/T in line_turfs)
		if(T == origin || T == dest)
			continue
		var/obj/effect/temp_visual/dir_setting/smoke_dash/trailsmoke = new(T, dash_dir)
		trailsmoke.color = "#D8B4FE"

	animate(user, alpha = 0, pixel_y = user.base_pixel_y + 16, time = 0.15 SECONDS)
	sleep(0.15 SECONDS)
	user.forceMove(get_step(clicked, get_dir(clicked, user)))
	user.pixel_y = user.base_pixel_y + 12
	animate(user, alpha = 255, pixel_y = user.base_pixel_y, time = 0.15 SECONDS, easing = BOUNCE_EASING)
	user.setDir(get_dir(user, clicked))

	// Say the line based on relic user's gender
	var/gendered_word = "boy"
	if(relic_user && !QDELETED(relic_user))
		if(relic_user.gender == FEMALE)
			gendered_word = "girl"
	user.say("Good [gendered_word]...")
	playsound(user, 'sound/weapons/middle_nursefather/middlefather_slash.ogg', 50, TRUE)

	// Build tension — camera shake and blade charge
	sleep(1 SECONDS)
	if(relic_user && !QDELETED(relic_user))
		shake_camera(relic_user, 2, 2)
	if(pinned_target && !QDELETED(pinned_target))
		shake_camera(pinned_target, 2, 2)
	new /obj/effect/temp_visual/dir_setting/laevateinn_blast(get_turf(user))
	playsound(user, 'sound/weapons/middle_nursefather/middlefather_scorch_slash.ogg', 60, TRUE)

	sleep(1 SECONDS)

	// Execute — gib the relic user, devastate the pinned target
	var/turf/execution_turf = get_turf(user)
	if(relic_user && !QDELETED(relic_user))
		relic_user.visible_message(span_userdanger("[user] cleaves through [relic_user] and [pinned_target] in a single, devastating arc!"))
		shake_camera(relic_user, 3, 5)
		relic_user.gib()
	if(pinned_target && !QDELETED(pinned_target))
		shake_camera(pinned_target, 3, 5)
		pinned_target.deal_damage(200, RED_DAMAGE)
		pinned_target.remove_status_effect(/datum/status_effect/mirror_weakened)
		REMOVE_TRAIT(pinned_target, TRAIT_IMMOBILIZED, "mirror_execution")

	// Explosive finish
	new /obj/effect/temp_visual/dir_setting/laevateinn_blast(execution_turf)
	new /obj/effect/temp_visual/dir_setting/middle_blast(execution_turf)
	playsound(execution_turf, 'sound/weapons/middle_nursefather/middlefather_heavy_ring.ogg', 75, TRUE)
	playsound(execution_turf, 'sound/weapons/middle_nursefather/middlefather_slash.ogg', 80, TRUE)
	shake_camera(user, 3, 5)

	combo_in_progress = FALSE

////////////////////////////////////////////////////////////
// MIDDLE APPRENTICE — THERMAL BLADES
// Dual-wield pair. Attacking with one triggers a follow-up hit from the other.
// Default: 2 Bleed per hit. With Tattoos active: 2 Overheat instead.
// attack_self: consume 5+ Grudge into Tattoos (capped at Tier 2).

/obj/item/ego_weapon/city/thermal_blade
	name = "thermal blade"
	desc = "A short blade infused with thermal energy. Designed to be wielded in pairs by the Middle's apprentices."
	icon = 'icons/obj/spider_house/middle/middle_spider_icon.dmi'
	lefthand_file = 'icons/obj/spider_house/middle/middle_spider_left.dmi'
	righthand_file = 'icons/obj/spider_house/middle/middle_spider_right.dmi'
	icon_state = "thermalblade_1"
	force = 22
	damtype = RED_DAMAGE
	attack_speed = 1.0
	w_class = WEIGHT_CLASS_NORMAL
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 80
	)
	special = "Thermal Blades are wielded in pairs. Attacking with one triggers a follow-up strike from the other. \
		Each hit inflicts 2 Bleed. Taking damage builds Grudge. \
		Use in-hand with 5+ Grudge to activate Tattoos (capped at Tier 2, +5/10 bonus damage, 30 seconds). \
		While Tattoos are active, blades also inflict 2 Overheat on top of the Bleed. \
		Click a target at range (3-7 tiles) while Tattoos are active to dash through them, \
		landing a few tiles past. Consumes the Tattoo buff and deactivates the blades."
	/// Whether this blade is currently doing a follow-up (prevents infinite loops)
	var/following_up = FALSE
	base_icon_state = "thermalblade_1"

/// Updates icon_state to active or inactive variant.
/obj/item/ego_weapon/city/thermal_blade/proc/UpdateActiveVisuals(active)
	if(active)
		icon_state = "[base_icon_state]_active"
	else
		icon_state = base_icon_state
	update_icon()
	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_hands()

/// Grants weapon-related components when picked up.
/obj/item/ego_weapon/city/thermal_blade/pickup(mob/user)
	. = ..()
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(!H.GetComponent(/datum/component/middle_grudge_gain))
		H.AddComponent(/datum/component/middle_grudge_gain)
	// Only the Middle Apprentice gets the standard nursefather passive (dodge + 5% clone)
	if(H.mind?.assigned_role == "Middle Apprentice")
		if(!H.GetComponent(/datum/component/nursefather_passive))
			H.AddComponent(/datum/component/nursefather_passive)

/// Removes weapon-related components when dropped — only if no other thermal blade is held.
/obj/item/ego_weapon/city/thermal_blade/dropped(mob/user)
	. = ..()
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	// Don't remove components if they still have another thermal blade
	if(locate(/obj/item/ego_weapon/city/thermal_blade) in H.held_items)
		return
	var/datum/component/middle_grudge_gain/grudge = H.GetComponent(/datum/component/middle_grudge_gain)
	if(grudge)
		qdel(grudge)
	// Only remove passive if it was granted by us (standard, not /middle)
	var/datum/component/nursefather_passive/passive = H.GetComponent(/datum/component/nursefather_passive)
	if(passive && !istype(passive, /datum/component/nursefather_passive/middle))
		qdel(passive)

/obj/item/ego_weapon/city/thermal_blade/CanUseEgo(mob/living/user)
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.mind?.assigned_role == "Middle Apprentice")
			return TRUE
	return ..()

/obj/item/ego_weapon/city/thermal_blade/attack(mob/living/target, mob/living/user)
	if(!ishuman(user))
		return ..()
	var/mob/living/carbon/human/H = user

	. = ..()
	H.AddGrudge(1)

	// Apply Bleed, and Overheat if Tattoos active
	target.apply_lc_bleed(2)
	var/has_tattoos = H.has_status_effect(/datum/status_effect/middle_tattoos)
	if(has_tattoos)
		target.apply_lc_overheat(2)

	// Tattoo passive bonus damage
	var/datum/status_effect/middle_tattoos/T = H.has_status_effect(/datum/status_effect/middle_tattoos)
	if(T)
		var/tattoo_bonus = T.GetDamageBonus()
		if(tattoo_bonus > 0)
			middle_combo_damage(target, H, tattoo_bonus, RED_DAMAGE)

	// Follow-up attack from the other blade
	if(!following_up)
		var/obj/item/ego_weapon/city/thermal_blade/other = locate() in H.held_items
		if(other && other != src && !other.following_up)
			INVOKE_ASYNC(src, PROC_REF(FollowUpAttack), other, target, H)

/obj/item/ego_weapon/city/thermal_blade/proc/FollowUpAttack(obj/item/ego_weapon/city/thermal_blade/other_blade, mob/living/target, mob/living/carbon/human/user)
	sleep(0.1 SECONDS)
	if(QDELETED(target) || QDELETED(user) || QDELETED(other_blade))
		return
	if(target.stat == DEAD || user.stat == DEAD)
		return
	if(!(other_blade in user.held_items))
		return
	if(!user.Adjacent(target))
		return

	other_blade.following_up = TRUE
	user.do_attack_animation(target, no_effect = TRUE)
	target.deal_damage(other_blade.force, RED_DAMAGE)
	playsound(target, 'sound/weapons/middle_nursefather/middlefather_melee_sealed.ogg', 50, TRUE)

	// Apply Bleed, and Overheat if Tattoos active
	target.apply_lc_bleed(2)
	var/has_tattoos = user.has_status_effect(/datum/status_effect/middle_tattoos)
	if(has_tattoos)
		target.apply_lc_overheat(2)

	other_blade.following_up = FALSE

/// attack_self — consume 5+ Grudge into Tattoos (capped at Tier 2 for apprentice).
/obj/item/ego_weapon/city/thermal_blade/attack_self(mob/user)
	if(!ishuman(user))
		return ..()
	var/mob/living/carbon/human/H = user

	if(H.GetGrudge() < 5)
		to_chat(H, span_warning("Not enough Grudge! ([H.GetGrudge()]/5)"))
		return

	var/grudge_consumed = H.ConsumeAllGrudge()
	var/tattoo_tier
	switch(grudge_consumed)
		if(5 to 9)
			tattoo_tier = 1
		if(10 to INFINITY)
			tattoo_tier = 2
		else
			tattoo_tier = 1

	H.ApplyMiddleTattoos(tattoo_tier)

	// Switch both blades to active sprites
	for(var/obj/item/ego_weapon/city/thermal_blade/blade in H.held_items)
		blade.UpdateActiveVisuals(TRUE)

	new /obj/effect/temp_visual/dir_setting/laevateinn_blast(get_turf(H))
	playsound(H, 'sound/weapons/middle_nursefather/middlefather_dash.ogg', 50, TRUE)
	H.visible_message(span_danger("[H]'s enhancement tattoos flare with power!"))
	to_chat(H, span_notice("Tattoos activated (Tier [tattoo_tier])!"))

/// afterattack — click a target at range (3-7 tiles) while Tattoos active to dash through them.
/obj/item/ego_weapon/city/thermal_blade/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(proximity_flag)
		return
	if(!isliving(target) || !ishuman(user))
		return
	var/mob/living/L = target
	var/mob/living/carbon/human/H = user
	if(L.stat == DEAD || L == H)
		return
	var/dist = get_dist(H, L)
	if(dist < 3 || dist > 7)
		return
	if(!H.has_status_effect(/datum/status_effect/middle_tattoos))
		to_chat(H, span_warning("You need active Tattoos to dash!"))
		return

	INVOKE_ASYNC(src, PROC_REF(ThermalDash), L, H)

/// Dashes through the target, landing a few tiles past them. Consumes Tattoos.
/obj/item/ego_weapon/city/thermal_blade/proc/ThermalDash(mob/living/target, mob/living/carbon/human/user)
	// Consume tattoos and deactivate blade sprites
	user.ConsumeMiddleTattoos()
	for(var/obj/item/ego_weapon/city/thermal_blade/blade in user.held_items)
		blade.UpdateActiveVisuals(FALSE)

	var/dash_dir = get_dir(user, target)
	var/turf/target_turf = get_turf(target)

	// Deal a slash as we pass through
	user.do_attack_animation(target, no_effect = TRUE)
	target.deal_damage(force, RED_DAMAGE, source = user)
	target.apply_lc_bleed(3)
	new /obj/effect/temp_visual/dir_setting/middle_slash(get_turf(target), dash_dir)
	playsound(target, 'sound/weapons/middle_nursefather/middlefather_scorch_slash.ogg', 55, TRUE)

	// Move to target's tile first
	user.forceMove(target_turf)

	// Continue past them 2-3 tiles, stopping at walls
	var/tiles_past = 3
	var/turf/current = target_turf
	for(var/i in 1 to tiles_past)
		var/turf/next = get_step(current, dash_dir)
		if(!next)
			break
		if(next.density)
			break
		var/blocked = FALSE
		for(var/obj/O in next)
			if(O.density && O.anchored)
				blocked = TRUE
				break
		if(blocked)
			break
		current = next

	user.forceMove(current)
	user.setDir(dash_dir)

/obj/item/ego_weapon/city/thermal_blade/offhand
	icon_state = "thermalblade_2"
	base_icon_state = "thermalblade_2"
