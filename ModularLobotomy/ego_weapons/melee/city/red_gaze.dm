// ============================================================
// Red Gaze (Vergilius) — Colored Fixer EGO
// ============================================================
// Base stats of a Grade 1 / 120 attribute colored fixer weapon.
// Gimmicks TBD.

/// Render layer for the no-suit Lavacrum body overlay: above the suit (15), below hair (9).
#define LAVACRUM_LAYER 12
/// Render layer for the Lavacrum thorn crown: above hair (9).
#define THORNCROWN_LAYER 8
/// Pixels a suspended target (and the spears converging on it) are raised.
#define LAVACRUM_RAISE_PIXELS 22

/obj/item/ego_weapon/city/gladius
	name = "gladius"
	desc = "A blade of solidified crimson carried by the Color Fixer known as the Red Gaze. \
		It hums with a quiet, smoldering heat."
	special = null // Built dynamically in examine() as a collapsible, sectioned breakdown.
	icon = 'ModularLobotomy/_Lobotomyicons/red_gaze_icons.dmi'
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/red_gaze_left.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/red_gaze_right.dmi'
	icon_state = "gladius"
	inhand_icon_state = "gladius"
	force = 60
	damtype = RED_DAMAGE
	attack_speed = 1
	hitsound = 'sound/weapons/fixer/gladius_melee.ogg'
	attack_verb_continuous = list("slashes", "cuts", "stabs")
	attack_verb_simple = list("slash", "cut", "stab")
	actions_types = list(/datum/action/item_action/red_gaze/follow_flow, /datum/action/item_action/red_gaze/open_path, /datum/action/item_action/red_gaze/blinding_bloodcleaver, /datum/action/item_action/red_gaze/drown_blood, /datum/action/item_action/red_gaze/bloodfiend_funeral, /datum/action/item_action/red_gaze/end_lavacrum)
	/// Action types that only show while transformed (Lavacrum Sanguinis State).
	var/static/list/lavacrum_action_types = list(/datum/action/item_action/red_gaze/blinding_bloodcleaver, /datum/action/item_action/red_gaze/drown_blood, /datum/action/item_action/red_gaze/bloodfiend_funeral)
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 120,
		PRUDENCE_ATTRIBUTE = 120,
		TEMPERANCE_ATTRIBUTE = 120,
		JUSTICE_ATTRIBUTE = 120,
	)
	/// Overheat stacks applied on each hit.
	var/overheat_per_hit = 3
	/// Superthermogenesis stacks applied per hit, gated by a cooldown.
	var/superthermo_per_hit = 1
	COOLDOWN_DECLARE(superthermo_cd)
	/// Whether the examine breakdown is expanded (toggled by the clickable button in examine).
	var/special_expanded = FALSE
	/// Whether the Lavacrum Sanguinis State is currently active.
	var/lavacrum_active = FALSE
	/// Whether the 2.4s activation wind-up is in progress (blocks re-activation).
	var/lavacrum_winding = FALSE
	/// Stored blood required to enter the Lavacrum Sanguinis State (50% of cap).
	var/activation_threshold = 3000
	/// Blood drained per second while in the Lavacrum Sanguinis State.
	var/blood_drain_per_second = 200
	/// Bleed stacks applied per hit while in the state.
	var/bleed_on_hit = 5
	/// Fraction of damage dealt returned to the user as healing (BRUTE) and as SP/sanity.
	var/lifesteal_fraction = 0.1
	var/sanity_lifesteal = 0.05
	/// The blood gauge shown above the user during the state.
	var/datum/progressbar/lavacrum/lavacrum_bar
	/// The body overlay used when transforming without the matching suit.
	var/mutable_appearance/lavacrum_overlay
	/// The thorn-crown overlay shown above the hair in both transform variants.
	var/mutable_appearance/thorncrown_overlay
	/// The human the state/overlay is currently applied to.
	var/mob/living/carbon/human/lavacrum_user
	/// The matching suit being transformed, if worn.
	var/obj/item/clothing/suit/armor/ego_gear/city/red_gaze/lavacrum_armor
	/// Cached original armor datum, restored when the wind-up ends or the state cancels.
	var/datum/armor/saved_armor
	/// The mob the bleed-damage signal is currently registered on.
	var/mob/bleed_listener
	/// TRUE while an action cutscene is mid-play (blocks overlapping actions).
	var/ability_active = FALSE
	/// Per-action time cooldowns.
	COOLDOWN_DECLARE(follow_flow_cd)
	COOLDOWN_DECLARE(open_path_cd)
	/// Fraction of max HP spent (BRUTE) to use each action.
	var/follow_flow_cost = 0.05
	var/open_path_cost = 0.1
	/// Following the Flow: weave radius, number of weaving passes, per-strike base damage.
	var/follow_flow_range = 6
	var/follow_flow_passes = 2
	var/follow_flow_max_targets = 6
	var/follow_flow_damage = 60
	/// I Shall Open the Path: search radius, dash-through length, suspend duration, dash-through strikes, base damage.
	var/open_path_range = 7
	var/open_path_lunge = 6
	var/open_path_raise_time = 25
	var/open_path_hits = 4
	var/open_path_damage = 90
	/// Transformed actions (Blinding Bloodcleaver / Drown in Blood / Funeral for a Dead Bloodfiend).
	COOLDOWN_DECLARE(cleaver_cd)
	COOLDOWN_DECLARE(drown_cd)
	COOLDOWN_DECLARE(funeral_cd)
	var/cleaver_cost = 0.1
	var/drown_cost = 0.2
	var/funeral_cost = 0.3
	var/cleaver_self_bleed = 10
	var/drown_self_bleed = 15
	var/funeral_self_bleed = 25
	/// Blinding Bloodcleaver crimson wave: max travel tiles + per-hit base damage.
	var/crimson_wave_range = 14
	var/crimson_wave_damage = 60
	/// Drown in Blood spear barrage count range.
	var/spear_count_min = 6
	var/spear_count_max = 8
	/// Max-HP fraction spent to conjure a bloodspear in the off-hand while transformed.
	var/spear_hp_cost = 0.05
	/// Funeral for a Dead Bloodfiend: area, scattered pool count, per-attack base damage, Bleed per hit.
	var/funeral_range = 7
	var/funeral_pool_count = 12
	var/funeral_pool_damage = 50
	var/funeral_spike_damage = 120
	var/funeral_dash_damage = 80
	var/funeral_bleed_per_hit = 3

/obj/item/ego_weapon/city/gladius/Initialize()
	. = ..()
	AddComponent(/datum/component/bloodfeast, siphon = TRUE, range = 4, starting = 0, threshold = 3000, max_amount = 6000)

/obj/item/ego_weapon/city/gladius/examine(mob/user)
	. = ..()
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	if(bloodfeast)
		. += span_notice("It has [round(bloodfeast.blood_amount)] / [bloodfeast.blood_cap] units of stored blood.")
	if(!special_expanded)
		. += span_notice("A blood-feeding EGO blade with many effects. <a href='byond://?src=[REF(src)];red_gaze_special=1'>(Show all effects)</a>")
		return
	. += span_notice("<a href='byond://?src=[REF(src)];red_gaze_special=1'>(Hide effects)</a>")
	. += span_notice("<b>--- Bloodfeast (passive) ---</b>")
	. += span_notice("Siphons nearby spilled blood and blood trails (+10 each). Stores the slain target's max HP on kill, and (Bleed x 10) whenever a mob Bleeds within range.")
	. += span_notice("<b>--- On Hit ---</b>")
	. += span_notice("Inflicts [overheat_per_hit] Overheat and 1 Superthermogenesis (the latter at most once every 1.5s). Heals [round(lifesteal_fraction * 100)]% HP and [round(sanity_lifesteal * 100)]% SP of the damage dealt.")
	. += span_notice("<b>--- Actions (held) ---</b>")
	. += span_notice("Every action hit heals you for [round(lifesteal_fraction * 100)]% of its damage as HP and [round(sanity_lifesteal * 100)]% as SP, and scales with the target's Overheat/Bleed (+1% each, max +50%) plus your own Bleed while transformed (+2% each, max +50%). Listed damage is base, before Justice scaling.")
	. += span_notice("Following the Flow (cost [round(follow_flow_cost * 100)]% max HP, 8s): dash-weave through every nearby foe, striking each [follow_flow_passes] times for [follow_flow_damage] base per hit.")
	. += span_notice("I Shall Open the Path (cost [round(open_path_cost * 100)]% max HP, 12s): impale + suspend the nearest foe, then dash through for [open_path_damage] (gutstab) plus [open_path_hits]x[open_path_damage] (dash); other foes on the path take [open_path_damage].")
	. += span_notice("<b>--- Lavacrum Sanguinis State ---</b>")
	. += span_notice("Use in-hand with at least 50% stored blood to transform: the blade locks to your hand, you gain +25% speed, stored blood drains over time, your strikes inflict [bleed_on_hit] Bleed, and you heal from your own Bleed. Wearing the matching suit hardens it; the state ends when blood runs out.")
	. += span_notice("<b>--- Blood Arts (while transformed) ---</b>")
	. += span_notice("These replace your held actions, cost more max HP, and inflict Bleed on you when used (same heal + scaling as the base actions).")
	. += span_notice("Blinding Bloodcleaver (cost [round(cleaver_cost * 100)]% max HP, +[cleaver_self_bleed] self-Bleed, 8s): weave-strike all foes ([follow_flow_passes]x[follow_flow_damage]), then loose a crimson wave dealing [crimson_wave_damage] base along its path.")
	. += span_notice("Drown in Blood (cost [round(drown_cost * 100)]% max HP, +[drown_self_bleed] self-Bleed, 12s): gutstab ([open_path_damage]) + suspend, [spear_count_min]-[spear_count_max] blood spears at [open_path_damage] each, then a dash ([open_path_hits]x[open_path_damage]).")
	. += span_notice("Funeral for a Dead Bloodfiend (cost [round(funeral_cost * 100)]% max HP, +[funeral_self_bleed] self-Bleed, 25s): a screen-wide 5-hit rite - two pool waves ([funeral_pool_damage] each), a spike eruption ([funeral_spike_damage]), then two dashes ([funeral_dash_damage] each) - hitting every foe in range.")
	. += span_notice("<b>--- Bloodspear (conjured, transformed) ---</b>")
	. += span_notice("While transformed, use the gladius in-hand with an empty off-hand (cost [round(spear_hp_cost * 100)]% max HP) to tear off a throwable bloodspear; it readies a throw automatically and lasts 10 seconds. A direct hit deals 60 base scaled damage and 15 Bleed, then the spear is spent. If it misses (a wall or the ground) it swells for a second - blocking pickup - then erupts for 50 base scaled damage and 10 Bleed to all foes within 2 tiles.")
	. += span_notice("<b>--- Status Effects Inflicted ---</b>")
	. += span_notice("<b>Overheat</b> | Applied by: basic hits, I Shall Open the Path, and Drown in Blood ([overheat_per_hit] stacks each). | Effect: ticks true damage over time.")
	. += span_notice("<b>Superthermogenesis</b> | Applied by: basic hits and most action strikes (1 stack each, max 10). | Effect: 15s after the first stack, erupts for 0.5% of max HP per stack - FIRE on people, BRUTE on creatures.")
	. += span_notice("<b>Bleed</b> | Applied by: the Funeral ([funeral_bleed_per_hit]/hit) and transformed basic hits ([bleed_on_hit]/hit); the blood arts also apply it to YOU on use. | Effect: feeds your action damage scaling and the lifesteal economy, and powers Blinding Blood.")
	. += span_notice("<b>Blinding Blood</b> | Applied by: Drown in Blood's spears and the Funeral's spikes (1-3 stacks, max 5). | Effect: 10s after the first stack it detonates for (target Bleed x stacks) BRUTE (x4 vs creatures), then applies (5 x stacks) Bleed.")

/obj/item/ego_weapon/city/gladius/Topic(href, href_list)
	. = ..()
	if(href_list["red_gaze_special"])
		special_expanded = !special_expanded
		if(usr)
			usr.examinate(src)

/obj/item/ego_weapon/city/gladius/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return
	var/was_alive = (target.stat < DEAD)
	. = ..()
	if(!.)
		return
	// Lifesteal: heal a fraction of the damage dealt (scaled by Justice and resistance).
	if(was_alive && !(target.status_flags & GODMODE))
		var/justicemod = 1 + (get_modified_attribute_level(user, JUSTICE_ATTRIBUTE) / 100)
		var/dealt = force * justicemod
		if(isanimal(target))
			var/mob/living/simple_animal/S = target
			dealt *= max(0, S.damage_coeff.getCoeff(damtype))
		else
			dealt *= max(0, (100 - target.run_armor_check(null, damtype, silent = TRUE)) / 100)
		Lifesteal(user, dealt)
	// Killing a target feeds the blade its max HP (both normal and Lavacrum states).
	if(was_alive && target.stat == DEAD)
		var/datum/component/bloodfeast/bf = GetComponent(/datum/component/bloodfeast)
		bf?.AdjustBlood(target.maxHealth)
		return
	if(target.stat == DEAD)
		return
	if(target.status_flags & GODMODE)
		return
	target.apply_lc_overheat(overheat_per_hit)
	if(COOLDOWN_FINISHED(src, superthermo_cd))
		target.apply_lc_superthermogenesis(superthermo_per_hit)
		COOLDOWN_START(src, superthermo_cd, 1.5 SECONDS)
	if(lavacrum_active)
		target.apply_lc_bleed(bleed_on_hit)

/// Returns the current stack count of a stacking status effect on M, or 0 if absent.
/obj/item/ego_weapon/city/gladius/proc/GetStatusStacks(mob/living/M, status_path)
	var/datum/status_effect/stacking/S = M.has_status_effect(status_path)
	return S ? S.stacks : 0

// ============================================================
// Active actions — Following the Flow / I Shall Open the Path
// ============================================================
// Two HUD actions granted while the gladius is held. Both cost a % of the
// user's max HP (BRUTE), heal 10% of the damage they deal, and scale with the
// target's Overheat/Bleed (and the wielder's own Bleed while transformed).

/datum/action/item_action/red_gaze
	icon_icon = 'ModularLobotomy/_Lobotomyicons/red_gaze_icons.dmi'

/datum/action/item_action/red_gaze/follow_flow
	name = "Following the Flow"
	desc = "Weave through every nearby foe in a flurry of crimson slashes. Costs 5% of your max HP; heals for 10% of the damage dealt."
	button_icon_state = "follow_flow"

/datum/action/item_action/red_gaze/follow_flow/IsAvailable()
	var/obj/item/ego_weapon/city/gladius/G = target
	if(istype(G) && !COOLDOWN_FINISHED(G, follow_flow_cd))
		return FALSE
	return ..()

/datum/action/item_action/red_gaze/open_path
	name = "I Shall Open the Path"
	desc = "Charge, then lunge forward in a fiery sweep that cleaves all in your path and erupts at its end. Costs 10% of your max HP; heals for 10% of the damage dealt."
	button_icon_state = "open_path"

/datum/action/item_action/red_gaze/open_path/IsAvailable()
	var/obj/item/ego_weapon/city/gladius/G = target
	if(istype(G) && !COOLDOWN_FINISHED(G, open_path_cd))
		return FALSE
	return ..()

// --- Transformed-state actions (shown only while in the Lavacrum Sanguinis State) ---

/datum/action/item_action/red_gaze/blinding_bloodcleaver
	name = "Blinding Bloodcleaver"
	desc = "Weave through nearby foes, then loose a traveling crimson slash-wave toward the nearest enemy. Costs 10% of your max HP and gives you Bleed; heals for 10% of the damage dealt."
	button_icon_state = "blinding_bloodcleaver"

/datum/action/item_action/red_gaze/blinding_bloodcleaver/IsAvailable()
	var/obj/item/ego_weapon/city/gladius/G = target
	if(istype(G) && !COOLDOWN_FINISHED(G, cleaver_cd))
		return FALSE
	return ..()

/datum/action/item_action/red_gaze/drown_blood
	name = "Drown in Blood"
	desc = "Impale and suspend the nearest foe, then conjure a ring of blood spears that impale it with Blinding Blood before you dash through. Costs 20% of your max HP and gives you Bleed; heals for 10% of the damage dealt."
	button_icon_state = "drown_blood"

/datum/action/item_action/red_gaze/drown_blood/IsAvailable()
	var/obj/item/ego_weapon/city/gladius/G = target
	if(istype(G) && !COOLDOWN_FINISHED(G, drown_cd))
		return FALSE
	return ..()

/datum/action/item_action/red_gaze/bloodfiend_funeral
	name = "Funeral for a Dead Bloodfiend"
	desc = "A screen-wide rite in five strikes: two waves of blood pools, a massive spike eruption that crashes down with Blinding Blood, then two dashes through everything. Costs 30% of your max HP and gives you heavy Bleed; heals for 10% HP and 5% SP of the damage dealt."
	button_icon_state = "bloodfiend_funeral"

/datum/action/item_action/red_gaze/bloodfiend_funeral/IsAvailable()
	var/obj/item/ego_weapon/city/gladius/G = target
	if(istype(G) && !COOLDOWN_FINISHED(G, funeral_cd))
		return FALSE
	return ..()

// Shown only while in an endless (admin-suit) Lavacrum state — ends it at will.
/datum/action/item_action/red_gaze/end_lavacrum
	name = "End Lavacrum Sanguinis"
	desc = "End the Lavacrum Sanguinis State at will."
	button_icon_state = "shin"

// Only show the action buttons while the weapon is held.
/obj/item/ego_weapon/city/gladius/item_action_slot_check(slot, mob/user)
	return slot == ITEM_SLOT_HANDS

/obj/item/ego_weapon/city/gladius/ui_action_click(mob/living/user, actiontype)
	if(!CanUseEgo(user) || !ishuman(user))
		return
	if(istype(actiontype, /datum/action/item_action/red_gaze/follow_flow))
		FollowFlow(user)
	else if(istype(actiontype, /datum/action/item_action/red_gaze/open_path))
		OpenPath(user)
	else if(istype(actiontype, /datum/action/item_action/red_gaze/blinding_bloodcleaver))
		BlindingBloodcleaver(user)
	else if(istype(actiontype, /datum/action/item_action/red_gaze/drown_blood))
		DrownInBlood(user)
	else if(istype(actiontype, /datum/action/item_action/red_gaze/bloodfiend_funeral))
		FuneralForBloodfiend(user)
	else if(istype(actiontype, /datum/action/item_action/red_gaze/end_lavacrum))
		if(lavacrum_active)
			EndLavacrum()

/// TRUE if the mob is wearing the admin red_gaze suit (free, endless Lavacrum).
/obj/item/ego_weapon/city/gladius/proc/HasAdminSuit(mob/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	return istype(H.wear_suit, /obj/item/clothing/suit/armor/ego_gear/city/red_gaze/admin)

/// Show the base actions when not transformed, the blood arts when transformed (held only).
/// The "End Lavacrum" button only appears during an endless (admin-suit) state.
/obj/item/ego_weapon/city/gladius/proc/SyncActionButtons(mob/user)
	if(!user)
		return
	var/held = user.is_holding(src)
	for(var/datum/action/A in actions)
		var/show
		if(istype(A, /datum/action/item_action/red_gaze/end_lavacrum))
			show = held && lavacrum_active && HasAdminSuit(user)
		else
			var/is_lava = (A.type in lavacrum_action_types)
			show = held && (is_lava == lavacrum_active)
		if(show)
			A.Grant(user)
		else
			A.Remove(user)

/// Grey the action buttons now, then refresh them again once `delay` has elapsed.
/obj/item/ego_weapon/city/gladius/proc/RefreshActionButtons(delay)
	RefreshActionButtonsNow()
	addtimer(CALLBACK(src, PROC_REF(RefreshActionButtonsNow)), delay)

/obj/item/ego_weapon/city/gladius/proc/RefreshActionButtonsNow()
	for(var/datum/action/A in actions)
		A.UpdateButtonIcon()

/// Damage multiplier from status stacks (the bonus moved off basic swings):
/// +1% per Overheat/Bleed on the target (cap +50%), plus +2% per Bleed on the
/// wielder while transformed (cap +50%).
/obj/item/ego_weapon/city/gladius/proc/StatusMult(mob/living/L, mob/living/user)
	var/target_bonus = min(0.5, (GetStatusStacks(L, /datum/status_effect/stacking/lc_overheat) + GetStatusStacks(L, /datum/status_effect/stacking/lc_bleed)) * 0.01)
	var/self_bonus = 0
	if(lavacrum_active)
		self_bonus = min(0.5, GetStatusStacks(user, /datum/status_effect/stacking/lc_bleed) * 0.02)
	return 1 + target_bonus + self_bonus

/// Deal one ability strike to L and heal off it immediately (per-hit lifesteal). Returns the real damage.
/obj/item/ego_weapon/city/gladius/proc/AbilityHit(mob/living/L, mob/living/user, base)
	if(QDELETED(L) || L.stat == DEAD || (L.status_flags & GODMODE))
		return 0
	var/justicemod = 1 + (get_modified_attribute_level(user, JUSTICE_ATTRIBUTE) / 100)
	var/dmg = base * justicemod * StatusMult(L, user)
	L.deal_damage(dmg, damtype, user, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	var/real = dmg
	if(isanimal(L))
		var/mob/living/simple_animal/S = L
		real *= max(0, S.damage_coeff.getCoeff(damtype))
	else
		real *= max(0, (100 - L.run_armor_check(null, damtype, silent = TRUE)) / 100)
	Lifesteal(user, real)
	return real

/// Heal the wielder for a fraction of damage dealt: BRUTE (lifesteal_fraction) + SP/sanity (sanity_lifesteal).
/obj/item/ego_weapon/city/gladius/proc/Lifesteal(mob/living/user, damage)
	if(damage <= 0)
		return
	user.adjustBruteLoss(-damage * lifesteal_fraction)
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.adjustSanityLoss(-damage * sanity_lifesteal)

/// Collect valid hostile targets (not the user, not allied/dead/godmode) within `radius`.
/obj/item/ego_weapon/city/gladius/proc/CollectEnemies(mob/living/user, radius)
	. = list()
	for(var/mob/living/L in range(radius, user))
		if(L == user)
			continue
		if(faction_check(user.faction, L.faction))
			continue
		if(L.stat == DEAD || (L.status_flags & GODMODE))
			continue
		. += L

/// Following the Flow — weave through every nearby foe in a dashing flurry.
/obj/item/ego_weapon/city/gladius/proc/FollowFlow(mob/living/carbon/human/user)
	set waitfor = FALSE
	if(ability_active || !COOLDOWN_FINISHED(src, follow_flow_cd))
		return
	var/list/targets = CollectEnemies(user, follow_flow_range)
	if(!length(targets))
		to_chat(user, span_warning("There is no one to flow toward."))
		return
	if(length(targets) > follow_flow_max_targets)
		targets.Cut(follow_flow_max_targets + 1)
	ability_active = TRUE
	user.adjustBruteLoss(user.maxHealth * follow_flow_cost)
	COOLDOWN_START(src, follow_flow_cd, 8 SECONDS)
	RefreshActionButtons(8 SECONDS)
	user.visible_message(span_warning("[user] surges into a flurry of crimson slashes!"), span_userdanger("You follow the flow!"))
	DoFlurry(user, targets, follow_flow_damage)
	ability_active = FALSE

/// Weave through `targets` in `follow_flow_passes` passes, striking each; returns real damage dealt.
/obj/item/ego_weapon/city/gladius/proc/DoFlurry(mob/living/carbon/human/user, list/targets, damage)
	user.Immobilize(follow_flow_passes * length(targets) * 2 + 4)
	. = 0
	for(var/sweep in 1 to follow_flow_passes)
		for(var/mob/living/L in targets)
			if(QDELETED(L) || L.stat == DEAD)
				continue
			var/turf/prev = get_turf(user)
			var/turf/dest = get_step(L.loc, pick(GetSafeDir(get_turf(L))))
			if(dest)
				user.forceMove(dest)
			user.setDir(get_dir(user, L))
			playsound(get_turf(user), hitsound, 50, TRUE)
			var/obj/effect/temp_visual/reverb_slash/VFX = new(get_turf(user))
			VFX.dir = get_dir(user, L)
			VFX.color = "#FF0000"
			if(prev)
				prev.Beam(get_turf(user), "sm_arc_dbz_referance", time = 6)
			. += AbilityHit(L, user, damage)
			L.apply_lc_superthermogenesis(1)
			sleep(2)

/// I Shall Open the Path — charge, gutstab the nearest foe, raise them, then dash through.
/obj/item/ego_weapon/city/gladius/proc/OpenPath(mob/living/carbon/human/user)
	set waitfor = FALSE
	if(ability_active || !COOLDOWN_FINISHED(src, open_path_cd))
		return
	var/mob/living/target = NearestEnemy(user, open_path_range)
	if(!target)
		to_chat(user, span_warning("There is no path to open."))
		return
	ability_active = TRUE
	user.adjustBruteLoss(user.maxHealth * open_path_cost)
	COOLDOWN_START(src, open_path_cd, 12 SECONDS)
	RefreshActionButtons(12 SECONDS)
	user.visible_message(span_warning("[user]'s gladius blazes white-hot..."), span_userdanger("I shall open the path!"))
	user.Immobilize(open_path_raise_time + 30)
	if(!ChargeBlade(user, target))
		ability_active = FALSE
		return
	Gutstab(user, target)
	SuspendTarget(target, open_path_raise_time)
	sleep(open_path_raise_time)
	DropTarget(target)
	if(!QDELETED(target))
		DashThrough(user, target, target, open_path_hits)
	ability_active = FALSE

// --- Shared impale-combo helpers (used by Open the Path and Drown in Blood) ---

/// Returns the nearest valid hostile within `radius`, or null.
/obj/item/ego_weapon/city/gladius/proc/NearestEnemy(mob/living/user, radius)
	var/mob/living/best
	var/bestdist = INFINITY
	for(var/mob/living/L in CollectEnemies(user, radius))
		var/d = get_dist(user, L)
		if(d < bestdist)
			bestdist = d
			best = L
	return best

/// Brief fiery wind-up facing the target; returns FALSE if the target is lost.
/obj/item/ego_weapon/city/gladius/proc/ChargeBlade(mob/living/user, mob/living/target)
	user.setDir(get_dir(user, target))
	playsound(get_turf(user), hitsound, 60, TRUE)
	new /obj/effect/temp_visual/fire(get_turf(user))
	sleep(6)
	return !(QDELETED(target) || target.stat == DEAD)

/// Gutstab: close to the target and run them through. Returns real damage dealt.
/obj/item/ego_weapon/city/gladius/proc/Gutstab(mob/living/user, mob/living/target)
	var/turf/approach = get_step(target, get_dir(target, user))
	if(approach && !approach.density)
		var/turf/prev = get_turf(user)
		user.forceMove(approach)
		prev.Beam(get_turf(user), "sm_arc_dbz_referance", time = 6)
	user.setDir(get_dir(user, target))
	playsound(get_turf(target), 'sound/effects/burn.ogg', 60, TRUE)
	var/obj/effect/temp_visual/reverb_slash/stab = new(get_turf(target))
	stab.dir = get_dir(user, target)
	stab.color = "#FF0000"
	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(target), get_dir(user, target))
	. = AbilityHit(target, user, open_path_damage)
	target.apply_lc_overheat(overheat_per_hit)
	target.apply_lc_superthermogenesis(1)

/// Suspend the target off the ground (AI off for simple mobs / Immobilize for humans + raise). Caller sleeps.
/obj/item/ego_weapon/city/gladius/proc/SuspendTarget(mob/living/target, duration)
	if(QDELETED(target) || target.stat == DEAD)
		return
	if(isanimal(target))
		var/mob/living/simple_animal/hostile/H = target
		if(istype(H))
			H.toggle_ai(AI_OFF)
			addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/living/simple_animal/hostile, toggle_ai), AI_ON), duration)
	else if(ishuman(target))
		target.Immobilize(duration + 5)
	animate(target, 0.3 SECONDS, pixel_y = target.base_pixel_y + LAVACRUM_RAISE_PIXELS, easing = QUAD_EASING)

/// Drop a suspended target back to the ground.
/obj/item/ego_weapon/city/gladius/proc/DropTarget(mob/living/target)
	if(!QDELETED(target))
		animate(target, 0.2 SECONDS, pixel_y = target.base_pixel_y, easing = QUAD_EASING)

/// Dash from the user through `anchor` to the far side, cleaving the line. `primary` takes `primary_hits` strikes.
/obj/item/ego_weapon/city/gladius/proc/DashThrough(mob/living/user, mob/living/anchor, mob/living/primary, primary_hits)
	var/turf/start = get_turf(user)
	var/turf/dest = start
	var/list/path = list()
	for(var/turf/T in getline(user, get_ranged_target_turf_direct(user, anchor, open_path_lunge)))
		if(T == start)
			continue
		if(T.density)
			break
		dest = T
		path += T
	. = 0
	var/list/cleaved = list()
	for(var/turf/T in path)
		var/obj/effect/temp_visual/decoy/D = new(T, user)
		D.alpha = 128
		D.color = "#FF0000"
		for(var/mob/living/L in view(1, T))
			if(L == user || (L in cleaved) || faction_check(user.faction, L.faction) || L.stat == DEAD || (L.status_flags & GODMODE))
				continue
			cleaved += L
			var/hits = (L == primary) ? primary_hits : 1
			for(var/i in 1 to hits)
				. += AbilityHit(L, user, open_path_damage)
			L.apply_lc_overheat(overheat_per_hit)
			L.apply_lc_superthermogenesis(1)
	if(dest && dest != start)
		start.Beam(dest, "sm_arc_dbz_referance", time = 6)
		user.forceMove(dest)
	shake_camera(user, 2, 3)
	playsound(get_turf(user), 'sound/effects/burn.ogg', 70, TRUE, extrarange = 6)

// ============================================================
// Transformed-state actions — Blinding Bloodcleaver / Drown in Blood
// ============================================================

/// Blinding Bloodcleaver — Following the Flow, then a traveling crimson slash-wave.
/obj/item/ego_weapon/city/gladius/proc/BlindingBloodcleaver(mob/living/carbon/human/user)
	set waitfor = FALSE
	if(ability_active || !COOLDOWN_FINISHED(src, cleaver_cd))
		return
	var/list/targets = CollectEnemies(user, follow_flow_range)
	if(!length(targets))
		to_chat(user, span_warning("There is no one to cleave."))
		return
	if(length(targets) > follow_flow_max_targets)
		targets.Cut(follow_flow_max_targets + 1)
	ability_active = TRUE
	user.adjustBruteLoss(user.maxHealth * cleaver_cost)
	user.apply_lc_bleed(cleaver_self_bleed)
	COOLDOWN_START(src, cleaver_cd, 8 SECONDS)
	RefreshActionButtons(8 SECONDS)
	user.visible_message(span_warning("[user] erupts into a blinding storm of blood!"), span_userdanger("Blinding Bloodcleaver!"))
	DoFlurry(user, targets, follow_flow_damage)
	FireCrimsonWave(user)
	ability_active = FALSE

/// Fire a traveling crimson slash-wave toward the nearest enemy; 3-wide perpendicular AoE per tile.
/obj/item/ego_weapon/city/gladius/proc/FireCrimsonWave(mob/living/user)
	var/mob/living/aim = NearestEnemy(user, crimson_wave_range)
	if(!aim)
		return 0
	var/turf/origin = get_turf(user)
	var/obj/effect/temp_visual/crimson_wave/W = new(origin)
	var/matrix/M = matrix()
	M.Turn(Get_Angle(origin, get_turf(aim)))
	W.transform = M
	W.dir = get_dir(origin, get_turf(aim))
	. = 0
	var/list/hit = list()
	var/turf/prev = origin
	var/count = 0
	for(var/turf/T in getline(origin, get_ranged_target_turf_direct(user, aim, crimson_wave_range)))
		if(T == origin)
			continue
		if(T.density)
			break
		count++
		if(count > crimson_wave_range)
			break
		W.forceMove(T)
		var/step_dir = get_dir(prev, T)
		var/list/band = list(T, get_step(T, turn(step_dir, 90)), get_step(T, turn(step_dir, -90)))
		for(var/turf/BT in band)
			if(!BT)
				continue
			new /obj/effect/temp_visual/cult/sparks(BT)
			for(var/mob/living/L in BT)
				if(L == user || (L in hit) || faction_check(user.faction, L.faction) || L.stat == DEAD || (L.status_flags & GODMODE))
					continue
				hit += L
				. += AbilityHit(L, user, crimson_wave_damage)
				L.apply_lc_superthermogenesis(1)
		prev = T
		sleep(1)
	qdel(W)

/obj/effect/temp_visual/crimson_wave
	icon = 'ModularLobotomy/_Lobotomyicons/red_gaze_96x96.dmi'
	icon_state = "crimson_slash"
	pixel_x = -32
	pixel_y = -32
	duration = 3 SECONDS
	randomdir = FALSE

/// Drown in Blood — impale + suspend the nearest foe, barrage it with blood spears, then dash through.
/obj/item/ego_weapon/city/gladius/proc/DrownInBlood(mob/living/carbon/human/user)
	set waitfor = FALSE
	if(ability_active || !COOLDOWN_FINISHED(src, drown_cd))
		return
	var/mob/living/target = NearestEnemy(user, open_path_range)
	if(!target)
		to_chat(user, span_warning("There is no one to drown."))
		return
	ability_active = TRUE
	user.adjustBruteLoss(user.maxHealth * drown_cost)
	user.apply_lc_bleed(drown_self_bleed)
	COOLDOWN_START(src, drown_cd, 12 SECONDS)
	RefreshActionButtons(12 SECONDS)
	user.visible_message(span_warning("[user]'s gladius calls forth a tide of blood!"), span_userdanger("Drown in blood!"))
	user.Immobilize(open_path_raise_time + 30)
	if(!ChargeBlade(user, target))
		ability_active = FALSE
		return
	Gutstab(user, target)
	SuspendTarget(target, open_path_raise_time)
	// Spears fade in during the tail of the suspend, then launch at the same moment as before.
	var/spear_fade = 4
	sleep(max(0, open_path_raise_time - spear_fade))
	var/list/spears = SpawnSpears(target)
	sleep(spear_fade)
	LaunchSpears(user, target, spears)
	DropTarget(target)
	if(!QDELETED(target))
		DashThrough(user, target, target, open_path_hits)
	ability_active = FALSE

/// Conjure a ring of blood spears around the target, fading them in (not yet launched). Returns the spear list.
/obj/item/ego_weapon/city/gladius/proc/SpawnSpears(mob/living/target)
	. = list()
	if(QDELETED(target))
		return
	var/turf/tt = get_turf(target)
	var/list/ring = list()
	for(var/turf/T in orange(1, target))
		ring += T
	if(!length(ring))
		return
	var/count = min(rand(spear_count_min, spear_count_max), length(ring))
	for(var/i in 1 to count)
		var/turf/ST = pick_n_take(ring)
		var/obj/effect/temp_visual/blood_spear/SP = new(ST)
		SP.alpha = 0
		var/matrix/M = matrix()
		M.Turn(Get_Angle(ST, tt) - 45)
		SP.transform = M
		animate(SP, 4, alpha = 255, easing = QUAD_EASING)
		. += SP

/// Launch the spawned spears into the (still-raised) target, impaling it and applying Blinding Blood. Returns real dmg.
/obj/item/ego_weapon/city/gladius/proc/LaunchSpears(mob/living/user, mob/living/target, list/spears)
	. = 0
	if(QDELETED(target))
		return
	var/turf/tt = get_turf(target)
	for(var/obj/effect/temp_visual/blood_spear/SP in spears)
		var/turf/ST = get_turf(SP)
		if(!ST)
			continue
		// Converge to the raised target (offset by the suspend height).
		animate(SP, 0.3 SECONDS, pixel_x = (tt.x - ST.x) * 32, pixel_y = (tt.y - ST.y) * 32 + LAVACRUM_RAISE_PIXELS, easing = QUAD_EASING)
	sleep(3)
	if(QDELETED(target))
		return
	new /obj/effect/temp_visual/dir_setting/bloodsplatter(tt, pick(GLOB.alldirs))
	for(var/obj/effect/temp_visual/blood_spear/SP in spears)
		. += AbilityHit(target, user, open_path_damage)
		qdel(SP)
	if(target.stat != DEAD)
		var/stacks = clamp(round((GetStatusStacks(target, /datum/status_effect/stacking/lc_bleed) + GetStatusStacks(user, /datum/status_effect/stacking/lc_bleed)) / 10), 1, 3)
		target.apply_blinding_blood(stacks)

/obj/effect/temp_visual/blood_spear
	icon = 'ModularLobotomy/_Lobotomyicons/red_gaze_icons.dmi'
	icon_state = "blood_spear_45"
	duration = 6
	randomdir = FALSE

// ============================================================
// Funeral for a Dead Bloodfiend — 5-attack screen-wide finisher
// ============================================================
// 1-2: spread large blood pools over the area (AoE damage + Bleed each pulse).
// 3:   the pools erupt into massive spikes that crash down (big hit + Bleed + Blinding Blood).
// 4-5: two crimson dashes that sweep every target.

/// Deal an AoE pulse to every valid foe in range (AbilityHit heals per hit).
/obj/item/ego_weapon/city/gladius/proc/FuneralPulse(mob/living/user, base, blinding = FALSE)
	for(var/mob/living/L in CollectEnemies(user, funeral_range))
		AbilityHit(L, user, base)
		L.apply_lc_bleed(funeral_bleed_per_hit)
		if(blinding)
			var/stacks = clamp(round((GetStatusStacks(L, /datum/status_effect/stacking/lc_bleed) + GetStatusStacks(user, /datum/status_effect/stacking/lc_bleed)) / 10), 1, 3)
			L.apply_blinding_blood(stacks)

/// Funeral for a Dead Bloodfiend — the ultimate blood art.
/obj/item/ego_weapon/city/gladius/proc/FuneralForBloodfiend(mob/living/carbon/human/user)
	set waitfor = FALSE
	if(ability_active || !COOLDOWN_FINISHED(src, funeral_cd))
		return
	if(!length(CollectEnemies(user, funeral_range)))
		to_chat(user, span_warning("There is no one to bury."))
		return
	ability_active = TRUE
	user.adjustBruteLoss(user.maxHealth * funeral_cost)
	user.apply_lc_bleed(funeral_self_bleed)
	COOLDOWN_START(src, funeral_cd, 25 SECONDS)
	RefreshActionButtons(25 SECONDS)
	user.visible_message(span_warning("[user] begins a funeral rite, and the ground drowns in blood!"), span_userdanger("Funeral for a Dead Bloodfiend!"))
	user.Immobilize(40)
	var/list/pools = list()
	// --- Attacks 1 & 2: spread large blood pools + AoE pulse. ---
	for(var/wave in 1 to 2)
		var/list/area_turfs = list()
		for(var/turf/T in range(funeral_range, user))
			if(!T.density)
				area_turfs += T
		for(var/i in 1 to funeral_pool_count)
			if(!length(area_turfs))
				break
			var/turf/PT = pick_n_take(area_turfs)
			var/obj/effect/decal/cleanable/blood/splatter/P = new(PT)
			P.transform = matrix() * 1.8
			pools += P
		playsound(get_turf(user), 'sound/effects/bleed.ogg', 60, TRUE, extrarange = 6)
		FuneralPulse(user, funeral_pool_damage)
		sleep(6)
	// --- Attack 3: pools erupt into massive spikes, then crash down. ---
	for(var/obj/effect/decal/cleanable/blood/splatter/P in pools)
		if(QDELETED(P))
			continue
		var/turf/ST = get_turf(P)
		var/obj/effect/temp_visual/blood_pillar/SK = new(ST)
		SK.transform = matrix() * 2.5
		SK.pixel_y = -24
		SK.alpha = 0
		animate(SK, 0.3 SECONDS, pixel_y = 0, alpha = 255, easing = QUAD_EASING)
	sleep(5)
	shake_camera(user, 3, 4)
	playsound(get_turf(user), 'sound/effects/bleed.ogg', 75, TRUE, extrarange = 8)
	FuneralPulse(user, funeral_spike_damage, blinding = TRUE)
	for(var/obj/effect/decal/cleanable/blood/splatter/P in pools)
		if(!QDELETED(P))
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(P), pick(GLOB.alldirs))
			qdel(P)
	pools.Cut()
	sleep(4)
	// --- Attacks 4 & 5: two crimson dashes through everything. ---
	for(var/dash in 1 to 2)
		var/mob/living/farthest
		var/bestdist = -1
		for(var/mob/living/L in CollectEnemies(user, funeral_range))
			var/d = get_dist(user, L)
			if(d > bestdist)
				bestdist = d
				farthest = L
		if(farthest)
			var/turf/start = get_turf(user)
			var/turf/dest = get_ranged_target_turf_direct(user, farthest, funeral_range)
			for(var/turf/T in getline(start, dest))
				if(T == start)
					continue
				if(T.density)
					break
				dest = T
			if(dest && dest != start)
				var/obj/effect/temp_visual/decoy/D = new(start, user)
				D.alpha = 128
				D.color = "#FF0000"
				start.Beam(dest, "sm_arc_dbz_referance", time = 6)
				user.forceMove(dest)
		FuneralPulse(user, funeral_dash_damage)
		sleep(4)
	ability_active = FALSE

/obj/effect/temp_visual/blood_pillar
	icon = 'ModularLobotomy/_Lobotomyicons/red_gaze_icons.dmi'
	icon_state = "blood_spear"
	duration = 8
	randomdir = FALSE

/// While transformed, conjure a temporary bloodspear into the user's empty off-hand.
/obj/item/ego_weapon/city/gladius/proc/TryConjureSpear(mob/living/user)
	if(!ishuman(user) || user.get_active_held_item() != src)
		return
	if(user.get_inactive_held_item())
		to_chat(user, span_warning("Your other hand is full."))
		return
	var/mob/living/carbon/human/H = user
	var/spear_hand = H.get_inactive_hand_index()
	var/obj/item/ego_weapon/city/bloodspear/SP = new(get_turf(H))
	SP.source_gladius = src
	SP.creator = H
	if(!H.put_in_inactive_hand(SP))
		qdel(SP)
		to_chat(H, span_warning("You can't grasp the bloodspear."))
		return
	H.adjustBruteLoss(H.maxHealth * spear_hp_cost)
	H.visible_message(span_warning("[H] tears a spear of blood from the gladius!"), span_userdanger("You conjure a bloodspear!"))
	playsound(get_turf(H), 'sound/effects/bleed.ogg', 50, TRUE)
	// Make the spear the active hand and ready a throw.
	if(spear_hand)
		H.swap_hand(spear_hand)
	H.throw_mode_on()
	SP.despawn_timer = QDEL_IN(SP, 10 SECONDS)

// ============================================================
// Bloodspear — transient conjured throwable
// ============================================================
// Conjured by the gladius while transformed. Disappears after 10s. When thrown
// into a living target it deals the same scaled damage as the blood arts plus
// 15 Bleed, then deletes itself. Cannot be thrown without meeting its attributes.

/obj/item/ego_weapon/city/bloodspear
	name = "bloodspear"
	desc = "A spear of congealed blood torn from the gladius. It will not hold its shape for long."
	icon = 'ModularLobotomy/_Lobotomyicons/red_gaze_icons.dmi'
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/red_gaze_left.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/red_gaze_right.dmi'
	icon_state = "spear_lavacrum"
	inhand_icon_state = "spear_lavacrum"
	force = 5
	throwforce = 30
	throw_speed = 3
	throw_range = 7
	damtype = RED_DAMAGE
	attack_verb_continuous = list("stabs", "impales", "gores")
	attack_verb_simple = list("stab", "impale", "gore")
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 120,
		PRUDENCE_ATTRIBUTE = 120,
		TEMPERANCE_ATTRIBUTE = 120,
		JUSTICE_ATTRIBUTE = 120,
	)
	/// The gladius that conjured this (drives the thrown-hit damage scaling).
	var/obj/item/ego_weapon/city/gladius/source_gladius
	/// The wielder who conjured it (the scaling/Bleed source on a thrown hit).
	var/mob/living/creator
	/// Base thrown-hit damage (before justice + status scaling).
	var/spear_throw_damage = 60
	/// Bleed applied to a target struck by the throw.
	var/spear_throw_bleed = 15
	/// On a miss: base AoE damage, Bleed, and radius of the delayed explosion.
	var/spear_explode_damage = 50
	var/spear_explode_bleed = 10
	var/spear_explode_radius = 2
	/// TRUE once the miss explosion sequence has begun (blocks pickup / re-trigger).
	var/exploding = FALSE
	/// Stoppable despawn timer (cancelled when the spear begins to detonate).
	var/despawn_timer

// Gate throwing behind the EGO attribute requirements; swap back to the other hand after throwing.
/obj/item/ego_weapon/city/bloodspear/on_thrown(mob/living/carbon/user, atom/target)
	if(!CanUseEgo(user))
		return
	. = ..()
	if(. && istype(user))
		user.swap_hand()

/// Deal one scaled strike to L (reuses the gladius's ability scaling, with a justice-only fallback).
/obj/item/ego_weapon/city/bloodspear/proc/ScaledHit(mob/living/L, base)
	if(QDELETED(L) || L.stat == DEAD || (L.status_flags & GODMODE))
		return
	var/mob/living/user = creator
	if(!QDELETED(source_gladius) && !QDELETED(user))
		source_gladius.AbilityHit(L, user, base)
	else if(!QDELETED(user))
		var/justicemod = 1 + (get_modified_attribute_level(user, JUSTICE_ATTRIBUTE) / 100)
		L.deal_damage(base * justicemod, damtype, user, attack_type = (ATTACK_TYPE_THROWING | ATTACK_TYPE_SPECIAL))
	else
		L.deal_damage(base, damtype, attack_type = (ATTACK_TYPE_THROWING | ATTACK_TYPE_SPECIAL))

/obj/item/ego_weapon/city/bloodspear/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(exploding)
		return
	if(isliving(hit_atom))
		var/mob/living/L = hit_atom
		if(L.stat != DEAD && !(L.status_flags & GODMODE))
			ScaledHit(L, spear_throw_damage)
			L.apply_lc_bleed(spear_throw_bleed)
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(L), pick(GLOB.alldirs))
			playsound(get_turf(L), 'sound/weapons/fixer/lavacrum_spear_melee.ogg', 40, TRUE)
			qdel(src)
			return
	// Missed (wall, dead body, or fell on the ground): swell and detonate.
	GrowAndExplode()
	return

/// On a miss, grow over a second (unliftable) then burst for a scaled AoE.
/obj/item/ego_weapon/city/bloodspear/proc/GrowAndExplode()
	if(exploding)
		return
	exploding = TRUE
	anchored = TRUE
	if(despawn_timer)
		deltimer(despawn_timer)
		despawn_timer = null
	animate(src, transform = matrix() * 1.5, time = 1 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(Explode)), 1 SECONDS)

/obj/item/ego_weapon/city/bloodspear/proc/Explode()
	var/turf/E = get_turf(src)
	if(E)
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(E, pick(GLOB.alldirs))
		playsound(E, 'sound/effects/bleed.ogg', 60, TRUE, extrarange = 4)
		var/mob/living/user = creator
		for(var/mob/living/L in range(spear_explode_radius, E))
			if(L == user || L.stat == DEAD || (L.status_flags & GODMODE))
				continue
			if(!QDELETED(user) && faction_check(user.faction, L.faction))
				continue
			ScaledHit(L, spear_explode_damage)
			L.apply_lc_bleed(spear_explode_bleed)
	qdel(src)

// ============================================================
// Superthermogenesis — delayed heat detonation
// ============================================================
// Stacks build on hit (capped at 10). 15 seconds after the first
// stack is applied, the heat erupts for (stacks * 0.5)% of the
// target's max HP — FIRE on carbons, BRUTE on simple mobs — then clears.

/datum/status_effect/stacking/superthermogenesis
	id = "superthermogenesis"
	alert_type = /atom/movable/screen/alert/status_effect/superthermogenesis
	stacking_display_name = "superthermogenesis"
	display_icon_file = 'ModularLobotomy/_Lobotomyicons/red_gaze_10x10.dmi'
	max_stacks = 10
	stack_decay = 0
	consumed_on_threshold = FALSE
	/// Percent of max HP dealt per stack on detonation.
	var/damage_percent_per_stack = 0.5
	/// Timer handle for the pending detonation.
	var/detonate_timer

/atom/movable/screen/alert/status_effect/superthermogenesis
	name = "Superthermogenesis"
	desc = "Heat festers within you. Soon, it will erupt."
	icon = 'ModularLobotomy/_Lobotomyicons/red_gaze_icons.dmi'
	icon_state = "superthermogenesis"

/datum/status_effect/stacking/superthermogenesis/on_apply()
	. = ..()
	if(!.)
		return
	detonate_timer = addtimer(CALLBACK(src, PROC_REF(Detonate)), 15 SECONDS, TIMER_STOPPABLE)

// No passive decay; the effect persists until it detonates.
/datum/status_effect/stacking/superthermogenesis/tick()
	return

/datum/status_effect/stacking/superthermogenesis/proc/Detonate()
	detonate_timer = null
	if(!owner || owner.stat == DEAD || (owner.status_flags & GODMODE))
		qdel(src)
		return
	var/damage = owner.maxHealth * stacks * (damage_percent_per_stack / 100)
	var/damage_type = iscarbon(owner) ? FIRE : BRUTE
	owner.deal_damage(damage, damage_type, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_STATUS))
	owner.playsound_local(owner, 'sound/effects/burn.ogg', 50, TRUE)
	qdel(src)

/datum/status_effect/stacking/superthermogenesis/Destroy()
	if(detonate_timer)
		deltimer(detonate_timer)
		detonate_timer = null
	return ..()

// Mob Proc
/mob/living/proc/apply_lc_superthermogenesis(stacks)
	var/datum/status_effect/stacking/superthermogenesis/S = src.has_status_effect(/datum/status_effect/stacking/superthermogenesis)
	if(!S)
		src.apply_status_effect(/datum/status_effect/stacking/superthermogenesis, stacks)
	else
		S.add_stacks(stacks)

// ============================================================
// Blinding Blood — delayed detonation tied to the target's Bleed
// ============================================================
// Applied by the Drown in Blood spear impalement. 10 seconds after the first
// stack, it bursts for (target Bleed * stacks) BRUTE (x4 vs simple mobs), then
// expires and inflicts (5 * stacks) Bleed.

/datum/status_effect/stacking/blinding_blood
	id = "blinding_blood"
	alert_type = /atom/movable/screen/alert/status_effect/blinding_blood
	stacking_display_name = "blinding_blood"
	display_icon_file = 'ModularLobotomy/_Lobotomyicons/red_gaze_10x10.dmi'
	max_stacks = 5
	stack_decay = 0
	consumed_on_threshold = FALSE
	/// Timer handle for the pending detonation.
	var/detonate_timer

/atom/movable/screen/alert/status_effect/blinding_blood
	name = "Blinding Blood"
	desc = "Blood seeps into the wound and clouds your sight. It will burst soon."
	icon = 'ModularLobotomy/_Lobotomyicons/red_gaze_icons.dmi'
	icon_state = "blinding_blood"

/datum/status_effect/stacking/blinding_blood/on_apply()
	. = ..()
	if(!.)
		return
	if(!detonate_timer)
		detonate_timer = addtimer(CALLBACK(src, PROC_REF(Detonate)), 10 SECONDS, TIMER_STOPPABLE)

// No passive decay; persists until it detonates.
/datum/status_effect/stacking/blinding_blood/tick()
	return

/datum/status_effect/stacking/blinding_blood/proc/Detonate()
	detonate_timer = null
	if(!owner || owner.stat == DEAD || (owner.status_flags & GODMODE))
		qdel(src)
		return
	var/datum/status_effect/stacking/lc_bleed/B = owner.has_status_effect(/datum/status_effect/stacking/lc_bleed)
	var/bleed = B ? B.stacks : 0
	var/damage = bleed * stacks
	if(isanimal(owner))
		damage *= 4
	if(damage > 0)
		owner.deal_damage(damage, BRUTE, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_STATUS))
	owner.playsound_local(owner, 'sound/effects/bleed.ogg', 50, TRUE)
	owner.apply_lc_bleed(5 * stacks)
	qdel(src)

/datum/status_effect/stacking/blinding_blood/Destroy()
	if(detonate_timer)
		deltimer(detonate_timer)
		detonate_timer = null
	return ..()

/mob/living/proc/apply_blinding_blood(stacks)
	var/datum/status_effect/stacking/blinding_blood/S = src.has_status_effect(/datum/status_effect/stacking/blinding_blood)
	if(!S)
		src.apply_status_effect(/datum/status_effect/stacking/blinding_blood, stacks)
	else
		S.add_stacks(stacks)

// ============================================================
// Lavacrum Sanguinis State
// ============================================================
// attack_self spends a 2.4s wind-up to enter a blood-fueled transformation:
// the weapon locks to the hand, drains stored blood (200/sec), inflicts Bleed
// on hit, and shows a blood gauge overhead. Wearing the matching suit hardens
// it during the wind-up and transforms its appearance; otherwise a body
// overlay is applied. The state ends when stored blood reaches 0.

/obj/item/ego_weapon/city/gladius/equipped(mob/user, slot, initial)
	. = ..()
	// Keep the bleed-damage listener pointed at the current holder.
	if(bleed_listener && bleed_listener != user)
		UnregisterSignal(bleed_listener, COMSIG_STATUS_BLEED_DAMAGE)
	RegisterSignal(user, COMSIG_STATUS_BLEED_DAMAGE, PROC_REF(OnBleedDamage), override = TRUE)
	bleed_listener = user
	SyncActionButtons(user)

/obj/item/ego_weapon/city/gladius/dropped(mob/user, silent)
	. = ..()
	if(lavacrum_active)
		EndLavacrum()
	if(bleed_listener)
		UnregisterSignal(bleed_listener, COMSIG_STATUS_BLEED_DAMAGE)
		bleed_listener = null

/obj/item/ego_weapon/city/gladius/Destroy()
	if(lavacrum_active)
		EndLavacrum()
	return ..()

/// Nearby Bleed damage feeds the blade; the wielder's own Bleed also heals them while transformed.
/obj/item/ego_weapon/city/gladius/proc/OnBleedDamage(datum/source, mob/bleeder, stacks)
	SIGNAL_HANDLER
	var/datum/component/bloodfeast/bf = GetComponent(/datum/component/bloodfeast)
	bf?.AdjustBlood(stacks * 10)
	if(lavacrum_active && bleeder == bleed_listener)
		var/mob/living/L = bleed_listener
		if(istype(L))
			L.adjustBruteLoss(-stacks)

/obj/item/ego_weapon/city/gladius/attack_self(mob/living/user)
	if(lavacrum_winding)
		return
	if(lavacrum_active)
		// While transformed, in-hand use conjures a bloodspear in the empty off-hand.
		TryConjureSpear(user)
		return
	if(!ishuman(user))
		return
	// The admin suit lets the wielder bloom with no stored-blood requirement.
	var/datum/component/bloodfeast/bf = GetComponent(/datum/component/bloodfeast)
	if(!HasAdminSuit(user) && (!bf || bf.blood_amount < activation_threshold))
		to_chat(user, span_warning("The gladius needs at least [activation_threshold] stored blood to bloom."))
		return
	var/mob/living/carbon/human/H = user
	lavacrum_winding = TRUE
	lavacrum_user = H
	H.Immobilize(24)
	H.visible_message(span_warning("[H]'s blade begins to bloom with seething blood!"), \
		span_userdanger("You let the gladius bloom..."))
	playsound(get_turf(H), 'sound/weapons/fixer/enter_lavacrum.ogg', 60, TRUE)
	if(istype(H.wear_suit, /obj/item/clothing/suit/armor/ego_gear/city/red_gaze))
		// Armoured branch: harden and transform the suit during the wind-up.
		lavacrum_armor = H.wear_suit
		saved_armor = lavacrum_armor.armor
		lavacrum_armor.armor = lavacrum_armor.armor.setRating(red = 95, white = 95, black = 95, pale = 95)
		lavacrum_armor.icon_state = "red_gaze_lavacrum_anim"
		lavacrum_armor.worn_icon_state = "red_gaze_lavacrum_anim"
		H.update_inv_wear_suit()
		addtimer(CALLBACK(src, PROC_REF(FinishArmorPhase), H), 24)
	else
		// Unarmoured branch: apply the animated body overlay during the wind-up.
		add_lavacrum_overlay(H, anim = TRUE)
		addtimer(CALLBACK(src, PROC_REF(FinishOverlayPhase), H), 24)

/// Wind-up over (suit branch): settle the suit, lock it on, rename it, enter the state.
/obj/item/ego_weapon/city/gladius/proc/FinishArmorPhase(mob/living/carbon/human/H)
	lavacrum_winding = FALSE
	if(QDELETED(src) || QDELETED(H) || H.stat == DEAD || loc != H)
		RevertArmor()
		return
	if(QDELETED(lavacrum_armor) || lavacrum_armor != H.wear_suit)
		RevertArmor()
		return
	if(saved_armor)
		lavacrum_armor.armor = saved_armor
	lavacrum_armor.icon_state = "red_gaze_lavacrum"
	lavacrum_armor.worn_icon_state = "red_gaze_lavacrum"
	lavacrum_armor.name = "Effloresced E.G.O :: Lavacrum Sanguinis"
	ADD_TRAIT(lavacrum_armor, TRAIT_NODROP, STICKY_NODROP)
	RegisterSignal(lavacrum_armor, COMSIG_PARENT_QDELETING, PROC_REF(OnArmorDestroyed))
	H.update_inv_wear_suit()
	EnterLavacrum(H)

/// Wind-up over (no-suit branch): settle the overlay, enter the state.
/obj/item/ego_weapon/city/gladius/proc/FinishOverlayPhase(mob/living/carbon/human/H)
	lavacrum_winding = FALSE
	if(QDELETED(src) || QDELETED(H) || H.stat == DEAD || loc != H)
		remove_lavacrum_overlay()
		return
	finalize_lavacrum_overlay()
	EnterLavacrum(H)

/// Build and apply the blood overlay between the suit and hair layers.
/obj/item/ego_weapon/city/gladius/proc/add_lavacrum_overlay(mob/living/carbon/human/H, anim = TRUE)
	if(lavacrum_overlay)
		remove_lavacrum_overlay()
	lavacrum_user = H
	lavacrum_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/red_gaze_worn.dmi', anim ? "lavacrum_anim" : "lavacrum", -LAVACRUM_LAYER)
	H.add_overlay(lavacrum_overlay)

/// Swap the animated overlay for its static end state.
/obj/item/ego_weapon/city/gladius/proc/finalize_lavacrum_overlay()
	if(!lavacrum_overlay || QDELETED(lavacrum_user))
		return
	lavacrum_user.cut_overlay(lavacrum_overlay)
	lavacrum_overlay.icon_state = "lavacrum"
	lavacrum_user.add_overlay(lavacrum_overlay)

/// Remove the blood overlay from the wearer.
/obj/item/ego_weapon/city/gladius/proc/remove_lavacrum_overlay()
	if(lavacrum_overlay && !QDELETED(lavacrum_user))
		lavacrum_user.cut_overlay(lavacrum_overlay)
	lavacrum_overlay = null

/// Apply the thorn-crown overlay (above hair) — shown whether or not the suit is worn.
/obj/item/ego_weapon/city/gladius/proc/add_thorncrown(mob/living/carbon/human/H)
	if(thorncrown_overlay)
		remove_thorncrown()
	thorncrown_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/red_gaze_worn.dmi', "lavacrum_thorncrown", -THORNCROWN_LAYER)
	H.add_overlay(thorncrown_overlay)

/// Remove the thorn-crown overlay from the wearer.
/obj/item/ego_weapon/city/gladius/proc/remove_thorncrown()
	if(thorncrown_overlay && !QDELETED(lavacrum_user))
		lavacrum_user.cut_overlay(thorncrown_overlay)
	thorncrown_overlay = null

/// Restore the suit to its base form (used on cancel and on state end).
/obj/item/ego_weapon/city/gladius/proc/RevertArmor()
	if(lavacrum_armor && !QDELETED(lavacrum_armor))
		if(saved_armor)
			lavacrum_armor.armor = saved_armor
		lavacrum_armor.icon_state = initial(lavacrum_armor.icon_state)
		lavacrum_armor.worn_icon_state = initial(lavacrum_armor.worn_icon_state)
		lavacrum_armor.name = initial(lavacrum_armor.name)
		REMOVE_TRAIT(lavacrum_armor, TRAIT_NODROP, STICKY_NODROP)
		UnregisterSignal(lavacrum_armor, COMSIG_PARENT_QDELETING)
		var/mob/living/carbon/human/H = lavacrum_armor.loc
		if(ishuman(H))
			H.update_inv_wear_suit()
	lavacrum_armor = null
	saved_armor = null

/obj/item/ego_weapon/city/gladius/proc/OnArmorDestroyed(datum/source)
	SIGNAL_HANDLER
	lavacrum_armor = null
	saved_armor = null
	EndLavacrum()

/obj/item/ego_weapon/city/gladius/proc/OnHolderDeath(datum/source)
	SIGNAL_HANDLER
	EndLavacrum()

/// Begin the active state: lock the weapon, transform it, start the drain and gauge.
/obj/item/ego_weapon/city/gladius/proc/EnterLavacrum(mob/living/carbon/human/H)
	if(lavacrum_active)
		return
	lavacrum_active = TRUE
	lavacrum_user = H
	icon_state = "gladius_lavacrum"
	inhand_icon_state = "gladius_lavacrum"
	update_icon_state()
	H.update_inv_hands()
	ADD_TRAIT(src, TRAIT_NODROP, STICKY_NODROP)
	H.add_movespeed_modifier(/datum/movespeed_modifier/lavacrum)
	add_thorncrown(H)
	var/datum/component/bloodfeast/bf = GetComponent(/datum/component/bloodfeast)
	if(bf)
		lavacrum_bar = new(H, bf.blood_cap, H)
		lavacrum_bar.update(bf.blood_amount)
	RegisterSignal(H, COMSIG_LIVING_DEATH, PROC_REF(OnHolderDeath))
	START_PROCESSING(SSfastprocess, src)
	SyncActionButtons(H)

/obj/item/ego_weapon/city/gladius/process(delta_time)
	if(!lavacrum_active)
		return PROCESS_KILL
	var/datum/component/bloodfeast/bf = GetComponent(/datum/component/bloodfeast)
	if(!bf)
		EndLavacrum()
		return PROCESS_KILL
	// The admin suit keeps the state endless: no drain and no auto-end at 0.
	if(!HasAdminSuit(lavacrum_user))
		bf.AdjustBlood(-blood_drain_per_second * delta_time)
		if(bf.blood_amount <= 0)
			EndLavacrum()
			return PROCESS_KILL
	lavacrum_bar?.update(bf.blood_amount)

/// Tear down the active state and revert everything.
/obj/item/ego_weapon/city/gladius/proc/EndLavacrum()
	if(!lavacrum_active)
		return
	lavacrum_active = FALSE
	STOP_PROCESSING(SSfastprocess, src)
	icon_state = initial(icon_state)
	inhand_icon_state = initial(inhand_icon_state)
	update_icon_state()
	REMOVE_TRAIT(src, TRAIT_NODROP, STICKY_NODROP)
	if(lavacrum_user)
		UnregisterSignal(lavacrum_user, COMSIG_LIVING_DEATH)
		lavacrum_user.remove_movespeed_modifier(/datum/movespeed_modifier/lavacrum)
		SyncActionButtons(lavacrum_user)
		if(ishuman(lavacrum_user))
			lavacrum_user.update_inv_hands()
	if(lavacrum_armor)
		RevertArmor()
	else
		remove_lavacrum_overlay()
	remove_thorncrown()
	QDEL_NULL(lavacrum_bar)
	lavacrum_user = null

// Lock the weapon to the hand while transformed (devyat pattern).
/obj/item/ego_weapon/city/gladius/equip_to_best_slot(mob/M, check_hand = TRUE)
	if(lavacrum_active)
		to_chat(M, span_warning("The gladius is fused to your grip while it blooms!"))
		return FALSE
	. = ..()

/obj/item/ego_weapon/city/gladius/mob_can_equip(mob/living/M, mob/living/equipper, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE)
	if(lavacrum_active)
		to_chat(M, span_warning("The gladius is fused to your grip while it blooms!"))
		return FALSE
	. = ..()

/// +25% movement speed granted while in the Lavacrum Sanguinis State.
/datum/movespeed_modifier/lavacrum
	multiplicative_slowdown = -0.25

// ============================================================
// Lavacrum blood gauge — custom progress bar
// ============================================================

/datum/progressbar/lavacrum/New(mob/User, goal_number, atom/target)
	. = ..()
	if(QDELETED(src))
		return
	bar.icon = 'ModularLobotomy/_Lobotomyicons/red_gaze_icons.dmi'
	bar.icon_state = "lavacrum_bar_0"

/datum/progressbar/lavacrum/update(progress)
	progress = clamp(progress, 0, goal)
	if(progress == last_progress)
		return
	last_progress = progress
	bar.icon_state = "lavacrum_bar_[round(((progress / goal) * 100), 5)]"

#undef LAVACRUM_LAYER
#undef THORNCROWN_LAYER
#undef LAVACRUM_RAISE_PIXELS
