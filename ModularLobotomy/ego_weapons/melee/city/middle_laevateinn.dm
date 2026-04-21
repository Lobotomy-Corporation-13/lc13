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
	pixel_x = -16
	pixel_y = -16
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_SUITSTORE
	force = 20
	damtype = RED_DAMAGE
	attack_speed = 1.5
	w_class = WEIGHT_CLASS_BULKY
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100
	)
	special = "Laevateinn is bound by three chain seals. As you lose HP, seals break at 75%, 50%, and 25% thresholds, \
		increasing the sword's power. Each unseal converts more damage to armor-piercing FIRE (10%, 20%, then 50%). \
		Attacking builds Grudge. Being hit by enemies also grants Grudge (more from heavier hits). \
		At 5+ Grudge, use the sword in-hand to activate your Enhancement Tattoos. \
		Tattoo tier scales with Grudge consumed (5-9: Tier 1, 10-14: Tier 2, 15-19: Tier 3, 20: Tier 4), \
		granting +5/10/15/20 passive bonus damage for 30 seconds. \
		Click a target at range to dash and trigger a combo. Without Tattoos, a basic combo is used. \
		With Tattoos, the combo is empowered based on your seal stage: \
		Full Seal → Stomping, 1 Seal Removed → Gut Ya Like a Fish, \
		2 Seals Removed → Gut Stab, Fully Unsealed → Complete and Total Extermination. \
		During combos, both you and the target are shielded from outside interference."
	/// Current seal stage: 0 = full seal, 1 = unseal1, 2 = unseal2, 3 = full power
	var/seal_stage = 0
	/// Whether a combo is currently in progress
	var/combo_in_progress = FALSE
	COOLDOWN_DECLARE(dash_cd)

/obj/item/ego_weapon/city/laevateinn/build_worn_icon(default_layer, default_icon_file, isinhands, femaleuniform, override_state, override_file)
	var/mutable_appearance/MA = ..()
	if(MA && !isinhands)
		MA.pixel_x -= 16
		MA.pixel_y -= 16
	return MA

/obj/item/ego_weapon/city/laevateinn/CanUseEgo(mob/living/user)
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.mind?.assigned_role == "Middle Ex-Great Brother")
			return TRUE
	return ..()

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
		if(1)
			force = 32
		if(2)
			force = 40
		if(3)
			force = 33
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
	if(!ishuman(user) || combo_in_progress)
		return ..()
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
	playsound(H, 'sound/weapons/bladeslice.ogg', 50, TRUE)
	H.visible_message(span_danger("[H]'s enhancement tattoos flare with power!"))
	to_chat(H, span_notice("Tattoos activated (Tier [tattoo_tier])!"))

/// afterattack — click a target at range (3-7 tiles) to dash and trigger a combo.
/obj/item/ego_weapon/city/laevateinn/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(proximity_flag || combo_in_progress)
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
	if(!COOLDOWN_FINISHED(src, dash_cd))
		to_chat(H, span_warning("Dash is on cooldown!"))
		return

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
/// Applies cutscene_duel to the user so they can't take outside damage during the combo.
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
				user.AddComponent(/datum/component/cutscene_duel, user, 8 SECONDS)
				middle_combo_stomping(target, user, consumed_tier)
				addtimer(CALLBACK(src, PROC_REF(EndCombo)), 8 SECONDS)
			if(1)
				user.AddComponent(/datum/component/cutscene_duel, user, 10 SECONDS)
				middle_combo_gut_fish(target, user, consumed_tier)
				addtimer(CALLBACK(src, PROC_REF(EndCombo)), 10 SECONDS)
			if(2)
				user.AddComponent(/datum/component/cutscene_duel, user, 12 SECONDS)
				middle_combo_gut_stab(target, user, consumed_tier)
				addtimer(CALLBACK(src, PROC_REF(EndCombo)), 12 SECONDS)
			if(3)
				user.AddComponent(/datum/component/cutscene_duel, user, 18 SECONDS)
				middle_combo_total_extermination(target, user, consumed_tier)
				addtimer(CALLBACK(src, PROC_REF(EndCombo)), 18 SECONDS)
	else
		user.AddComponent(/datum/component/cutscene_duel, user, 10 SECONDS)
		middle_combo_chain_grapple(target, user, consumed_tier)
		addtimer(CALLBACK(src, PROC_REF(EndCombo)), 10 SECONDS)

/obj/item/ego_weapon/city/laevateinn/proc/EndCombo()
	combo_in_progress = FALSE
