// Palermitan Skill Components - 4 Schools
// All skills inherit from /datum/component/palermitan_skill base.
// Pattern mirrors /datum/component/ring_skill from the Ring system.

// BASE SKILL COMPONENT
/datum/component/palermitan_skill
	/// Reference to the human parent
	var/mob/living/carbon/human/human_parent

/datum/component/palermitan_skill/Initialize()
	. = ..()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	human_parent = parent

/datum/component/palermitan_skill/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_attack))

/datum/component/palermitan_skill/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_ITEM_ATTACK)
	human_parent = null
	. = ..()

/// Called when the parent attacks something with an item
/datum/component/palermitan_skill/proc/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	SIGNAL_HANDLER
	return

/// Helper: get Duel Escalates stacks on target (0 if none)
/datum/component/palermitan_skill/proc/get_duel_stacks(mob/living/target)
	var/datum/status_effect/stacking/duel_escalates/D = target.has_status_effect(/datum/status_effect/stacking/duel_escalates)
	if(D)
		return D.stacks
	return 0

/// Helper: get Tremor stacks on target
/datum/component/palermitan_skill/proc/get_tremor_stacks(mob/living/target)
	var/datum/status_effect/stacking/lc_tremor/T = target.has_status_effect(/datum/status_effect/stacking/lc_tremor)
	if(T)
		return T.stacks
	return 0

/// Helper: get Overheat stacks on target
/datum/component/palermitan_skill/proc/get_overheat_stacks(mob/living/target)
	var/datum/status_effect/stacking/lc_burn/B = target.has_status_effect(/datum/status_effect/stacking/lc_burn)
	if(B)
		return B.stacks
	return 0

/// Helper: get the tremor burst threshold from the apprentice's base component
/datum/component/palermitan_skill/proc/get_burst_threshold()
	if(!human_parent)
		return INFINITY
	var/datum/component/palermitan_apprentice/pal = human_parent.GetComponent(/datum/component/palermitan_apprentice)
	if(pal)
		return pal.tremor_burst_threshold
	return INFINITY

/// Helper: apply tremor using the apprentice's current burst threshold
/datum/component/palermitan_skill/proc/apply_tremor(mob/living/target, stacks)
	target.apply_lc_tremor(stacks, get_burst_threshold())

//
// SCHOOL 1: TERREMOTO (Tremor)
//

// T1a: Il Cacciatore - On Hit: 2 Tremor (no burst). Vs DE: +1 OLU
/datum/component/palermitan_skill/terremoto/il_cacciatore

/datum/component/palermitan_skill/terremoto/il_cacciatore/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	apply_tremor(target, 2)
	if(get_duel_stacks(target) >= 3)
		user.apply_lc_offense_level_up(1)

// T1b: Destabilizing Strikes - 1/2/3 Tremor scaling with DE
/datum/component/palermitan_skill/terremoto/destabilizing_strikes

/datum/component/palermitan_skill/terremoto/destabilizing_strikes/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	var/de = get_duel_stacks(target)
	if(de >= 7)
		apply_tremor(target, 3)
	else if(de >= 3)
		apply_tremor(target, 2)
	else
		apply_tremor(target, 1)

// T2a: Palermitan Rapier - Unlocks burst at 15. On burst: +5 OLU +2 Poise
// This skill modifies the burst threshold used by the apprentice's tremor applications.
// It also needs to detect tremor bursts - done by checking stacks before/after.
/datum/component/palermitan_skill/terremoto/palermitan_rapier
	/// The burst threshold this skill sets
	var/burst_threshold = 15

/datum/component/palermitan_skill/terremoto/palermitan_rapier/RegisterWithParent()
	. = ..()
	// Set the burst threshold on the base component
	var/datum/component/palermitan_apprentice/pal = parent.GetComponent(/datum/component/palermitan_apprentice)
	if(pal)
		pal.tremor_burst_threshold = burst_threshold

/datum/component/palermitan_skill/terremoto/palermitan_rapier/UnregisterFromParent()
	// Reset burst threshold
	var/datum/component/palermitan_apprentice/pal = parent?.GetComponent(/datum/component/palermitan_apprentice)
	if(pal)
		pal.tremor_burst_threshold = INFINITY
	. = ..()

/datum/component/palermitan_skill/terremoto/palermitan_rapier/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	// Check tremor stacks before the hit resolves (other skills apply tremor in their on_attack too)
	var/stacks_before = get_tremor_stacks(target)
	if(stacks_before > 0)
		INVOKE_ASYNC(src, PROC_REF(check_burst), target, user, stacks_before)

/datum/component/palermitan_skill/terremoto/palermitan_rapier/proc/check_burst(mob/living/target, mob/living/user, stacks_before)
	if(QDELETED(target) || QDELETED(user))
		return
	var/stacks_after = get_tremor_stacks(target)
	// If tremor dropped significantly or disappeared, a burst happened
	if(stacks_after < stacks_before - 5 || (stacks_before >= burst_threshold && !stacks_after))
		user.apply_lc_offense_level_up(5)
		user.apply_lc_poise(5)
		to_chat(user, span_nicegreen("Tremor Burst! Your Palermitan Rapier grants power!"))

// T2b: Aftershock - Unlocks burst at 25. OLD on high tremor targets
/datum/component/palermitan_skill/terremoto/aftershock
	var/burst_threshold = 25

/datum/component/palermitan_skill/terremoto/aftershock/RegisterWithParent()
	. = ..()
	var/datum/component/palermitan_apprentice/pal = parent.GetComponent(/datum/component/palermitan_apprentice)
	if(pal)
		pal.tremor_burst_threshold = burst_threshold

/datum/component/palermitan_skill/terremoto/aftershock/UnregisterFromParent()
	var/datum/component/palermitan_apprentice/pal = parent?.GetComponent(/datum/component/palermitan_apprentice)
	if(pal)
		pal.tremor_burst_threshold = INFINITY
	. = ..()

/datum/component/palermitan_skill/terremoto/aftershock/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	var/tremor = get_tremor_stacks(target)
	if(tremor >= 20)
		target.apply_lc_offense_level_down(3)
	else if(tremor >= 10)
		target.apply_lc_offense_level_down(2)

// T3a: Sezionatura di Cervo - Activated ability (60s CD)
// Force Tremor Burst + 4 Tremor + 4 Overheat + bonus RED = DE*5, consume 50% DE
/datum/component/palermitan_skill/terremoto/sezionatura
	/// Whether the next hit should trigger the finisher
	var/primed = FALSE
	/// Cooldown tracking
	var/last_use = 0

/datum/component/palermitan_skill/terremoto/sezionatura/RegisterWithParent()
	. = ..()
	// Grant the activated action button
	var/datum/action/innate/sezionatura_activate/act = new()
	act.skill_ref = src
	act.Grant(parent)

/datum/component/palermitan_skill/terremoto/sezionatura/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	if(!primed)
		return
	primed = FALSE
	// Apply effects
	target.apply_lc_tremor(4, INFINITY)
	target.apply_lc_overheat(4)
	// Force tremor burst only if target has 10+ Duel Escalates
	var/de = get_duel_stacks(target)
	if(de >= 10)
		var/datum/status_effect/stacking/lc_tremor/T = target.has_status_effect(/datum/status_effect/stacking/lc_tremor)
		if(T)
			T.TremorBurst()
	// Bonus RED damage = DE * 2
	if(de > 0)
		var/bonus = de * 2
		target.deal_damage(bonus, RED_DAMAGE, source = user, attack_type = ATTACK_TYPE_MELEE)
		to_chat(user, span_green("Sezionatura deals [bonus] bonus RED damage!"))
	// Consume 50% DE
	var/datum/status_effect/stacking/duel_escalates/D = target.has_status_effect(/datum/status_effect/stacking/duel_escalates)
	if(D)
		var/consume = round(D.stacks / 2)
		if(consume > 0)
			D.add_stacks(-consume)
	shake_camera(user, 2, 3)
	playsound(user, 'sound/weapons/punch4.ogg', 60, TRUE)
	to_chat(user, span_userdanger("Sezionatura di Cervo!"))

/// Action button for Sezionatura activation
/datum/action/innate/sezionatura_activate
	name = "Sezionatura di Cervo"
	desc = "Prime your next attack for a devastating finisher. 60 second cooldown."
	button_icon_state = "yourswordinhand"
	var/datum/component/palermitan_skill/terremoto/sezionatura/skill_ref
	var/cooldown_time = 60 SECONDS
	var/last_use = 0

/datum/action/innate/sezionatura_activate/Activate()
	if(!skill_ref)
		return
	if(world.time < last_use + cooldown_time)
		to_chat(owner, span_warning("Sezionatura is on cooldown!"))
		return
	last_use = world.time
	skill_ref.primed = TRUE
	to_chat(owner, span_danger("Your next attack will unleash Sezionatura di Cervo!"))

// T3b: Tectonic Collapse - On Tremor Burst: 3 Fragile + 3 DLD + 2 Overheat
/datum/component/palermitan_skill/terremoto/tectonic_collapse

/datum/component/palermitan_skill/terremoto/tectonic_collapse/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	var/stacks_before = get_tremor_stacks(target)
	if(stacks_before > 0)
		INVOKE_ASYNC(src, PROC_REF(check_burst), target, user, stacks_before)

/datum/component/palermitan_skill/terremoto/tectonic_collapse/proc/check_burst(mob/living/target, mob/living/user, stacks_before)
	if(QDELETED(target) || QDELETED(user))
		return
	var/stacks_after = get_tremor_stacks(target)
	if(stacks_after < stacks_before - 5 || (stacks_before > 0 && !stacks_after))
		target.apply_lc_fragile(3)
		target.apply_lc_defense_level_down(3)
		target.apply_lc_overheat(2)
		to_chat(user, span_nicegreen("Tectonic Collapse! The burst devastates your target!"))

//
// SCHOOL 2: INCENDIO (Overheat)
//

// T1a: Colpi Sottani - On Hit: 2 Overheat. Vs DE: 3 instead
/datum/component/palermitan_skill/incendio/colpi_sottani

/datum/component/palermitan_skill/incendio/colpi_sottani/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	if(get_duel_stacks(target) >= 3)
		target.apply_lc_overheat(3)
	else
		target.apply_lc_overheat(2)

// T1b: Scorching Pursuit - 1 Overheat (2 at 5+ DE). Vs Overheat target: +1 OLU
/datum/component/palermitan_skill/incendio/scorching_pursuit

/datum/component/palermitan_skill/incendio/scorching_pursuit/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	var/de = get_duel_stacks(target)
	if(de >= 5)
		target.apply_lc_overheat(2)
	else
		target.apply_lc_overheat(1)
	if(get_overheat_stacks(target) > 0)
		user.apply_lc_offense_level_up(1)

// T2a: Firestorm - On Hit vs 10+ Overheat: +3 OLU +1 Poise +1 Fragile
/datum/component/palermitan_skill/incendio/firestorm

/datum/component/palermitan_skill/incendio/firestorm/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	if(get_overheat_stacks(target) >= 10)
		user.apply_lc_offense_level_up(3)
		user.apply_lc_poise(3)

// T2b: Smoldering Wounds - 1 DLD per 5 Overheat (max 3)
/datum/component/palermitan_skill/incendio/smoldering_wounds

/datum/component/palermitan_skill/incendio/smoldering_wounds/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	var/overheat = get_overheat_stacks(target)
	if(overheat > 0)
		var/dld = min(round(overheat / 5), 3)
		if(dld > 0)
			target.apply_lc_defense_level_down(dld)

// T3a: La Spada di Palermo - On Hit vs 10+ DE (30s CD): +5 OLU +3 Damage Up, consume 5 DE, inflict 3 Tremor
/datum/component/palermitan_skill/incendio/la_spada
	var/last_proc_time = 0

/datum/component/palermitan_skill/incendio/la_spada/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	if(world.time < last_proc_time + 30 SECONDS)
		return
	var/de = get_duel_stacks(target)
	if(de < 10)
		return
	last_proc_time = world.time
	user.apply_lc_offense_level_up(5)
	user.apply_lc_strength(3)
	apply_tremor(target, 3)
	// Consume 5 DE
	var/datum/status_effect/stacking/duel_escalates/D = target.has_status_effect(/datum/status_effect/stacking/duel_escalates)
	if(D)
		D.add_stacks(-5)
	to_chat(user, span_nicegreen("La Spada di Palermo! Power surges through you!"))

// T3b: Conflagration - On Hit vs 15+ Overheat (10s CD): bonus RED = stacks, reduce by 5, +2 Tremor
/datum/component/palermitan_skill/incendio/conflagration
	var/last_proc_time = 0

/datum/component/palermitan_skill/incendio/conflagration/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	if(world.time < last_proc_time + 10 SECONDS)
		return
	var/overheat = get_overheat_stacks(target)
	if(overheat < 15)
		return
	last_proc_time = world.time
	// Bonus RED = overheat stacks
	target.deal_damage(overheat, RED_DAMAGE, source = user, attack_type = ATTACK_TYPE_MELEE)
	// Reduce overheat by 5
	var/datum/status_effect/stacking/lc_burn/B = target.has_status_effect(/datum/status_effect/stacking/lc_burn)
	if(B)
		B.add_stacks(-5)
	apply_tremor(target, 2)
	to_chat(user, span_nicegreen("Conflagration! [overheat] bonus RED damage!"))

//
// SCHOOL 3: ELEGANZA (Poise/Concentration)
//

// T1a: Relentless Pursuit
// Under 5 DE: +2 Poise. 5+ DE: +5 Poise instead
/datum/component/palermitan_skill/eleganza/relentless_pursuit

/datum/component/palermitan_skill/eleganza/relentless_pursuit/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	var/de = get_duel_stacks(target)
	if(de < 1)
		return
	if(de >= 5)
		user.apply_lc_poise(5)
	else
		user.apply_lc_poise(2)

// T1b: Focused Mind
// Under 5 DE: +1 Poise +1 Concentration (10s CD). 5+ DE: +3 Poise instead
/datum/component/palermitan_skill/eleganza/focused_mind
	var/last_conc_time = 0

/datum/component/palermitan_skill/eleganza/focused_mind/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	var/de = get_duel_stacks(target)
	if(de < 1)
		return
	if(de >= 5)
		user.apply_lc_poise(3)
	else
		user.apply_lc_poise(1)
		if(world.time >= last_conc_time + 10 SECONDS)
			last_conc_time = world.time
			user.apply_lc_concentration(1)

// T2a: Duello Feroce
// On Hit vs 3+ DE: +1 Poise per 3 stacks (max 3) + heal 2 HP/stack (max 10). Halving crit: +1 Concentration
/datum/component/palermitan_skill/eleganza/duello_feroce
	/// Tracks poise before crit to detect halving
	var/poise_before_crit = 0

/datum/component/palermitan_skill/eleganza/duello_feroce/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_POISE_CRIT_ATTACKER, PROC_REF(on_poise_crit))

/datum/component/palermitan_skill/eleganza/duello_feroce/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_POISE_CRIT_ATTACKER)
	. = ..()

/datum/component/palermitan_skill/eleganza/duello_feroce/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	var/de = get_duel_stacks(target)
	if(de < 3)
		return
	// Poise: 1 per 3 stacks, max 3
	var/poise_gain = min(round(de / 3), 3)
	if(poise_gain > 0)
		user.apply_lc_poise(poise_gain)
	// Heal: 2 HP per stack, max 10
	var/heal = min(de * 2, 10)
	if(heal > 0 && ishuman(user))
		var/mob/living/carbon/human/H = user
		H.adjustBruteLoss(-heal)
	// Store poise for crit detection
	var/datum/status_effect/stacking/poise/P = user.has_status_effect(/datum/status_effect/stacking/poise)
	poise_before_crit = P ? P.stacks : 0

/datum/component/palermitan_skill/eleganza/duello_feroce/proc/on_poise_crit(datum/source, mob/living/target, bonus_damage)
	SIGNAL_HANDLER
	// Check if poise was halved (no concentration consumed)
	var/mob/living/user = parent
	var/datum/status_effect/stacking/poise/P = user.has_status_effect(/datum/status_effect/stacking/poise)
	var/poise_after = P ? P.stacks : 0
	// If poise was halved (dropped significantly), concentration wasn't consumed
	if(poise_before_crit > 0 && poise_after < poise_before_crit * 0.75)
		user.apply_lc_concentration(1)

// T2b: Severed Tendon
// On Poise crit: 3 OLD + 1 Fragile. Halving crit: +1 Poise back
/datum/component/palermitan_skill/eleganza/severed_tendon
	var/poise_before_crit = 0

/datum/component/palermitan_skill/eleganza/severed_tendon/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_POISE_CRIT_ATTACKER, PROC_REF(on_poise_crit))

/datum/component/palermitan_skill/eleganza/severed_tendon/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_POISE_CRIT_ATTACKER)
	. = ..()

/datum/component/palermitan_skill/eleganza/severed_tendon/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	// Store poise for crit detection
	var/datum/status_effect/stacking/poise/P = user.has_status_effect(/datum/status_effect/stacking/poise)
	poise_before_crit = P ? P.stacks : 0

/datum/component/palermitan_skill/eleganza/severed_tendon/proc/on_poise_crit(datum/source, mob/living/target, bonus_damage)
	SIGNAL_HANDLER
	if(!isliving(target))
		return
	// Always on crit: 3 OLD + 1 Fragile
	target.apply_lc_offense_level_down(3)
	target.apply_lc_fragile(1)
	// If poise was halved: +5 Poise back
	var/mob/living/user = parent
	var/datum/status_effect/stacking/poise/P = user.has_status_effect(/datum/status_effect/stacking/poise)
	var/poise_after = P ? P.stacks : 0
	if(poise_before_crit > 0 && poise_after < poise_before_crit * 0.75)
		user.apply_lc_poise(5)

// T3a: Valencina's Legacy
// On crit: 3 Tremor + 3 Overheat + DE spread 2 tiles. On crit (15s CD): +1 Concentration
/datum/component/palermitan_skill/eleganza/valencinas_legacy
	var/last_conc_time = 0

/datum/component/palermitan_skill/eleganza/valencinas_legacy/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_POISE_CRIT_ATTACKER, PROC_REF(on_poise_crit))

/datum/component/palermitan_skill/eleganza/valencinas_legacy/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_POISE_CRIT_ATTACKER)
	. = ..()

/datum/component/palermitan_skill/eleganza/valencinas_legacy/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	return

/datum/component/palermitan_skill/eleganza/valencinas_legacy/proc/on_poise_crit(datum/source, mob/living/target, bonus_damage)
	SIGNAL_HANDLER
	if(!isliving(target))
		return
	var/mob/living/user = parent
	// 3 Tremor + 3 Overheat on target
	apply_tremor(target, 3)
	target.apply_lc_overheat(3)
	// DE spread to nearby enemies within 2 tiles
	for(var/mob/living/L in range(2, get_turf(target)))
		if(L == user || L == target)
			continue
		L.apply_duel_escalates(1, user)
	// Concentration on 15s cooldown
	if(world.time >= last_conc_time + 15 SECONDS)
		last_conc_time = world.time
		user.apply_lc_concentration(1)

// T3b: The Famiglia's Honor
// DE max to 30. At 15+ DE: +2 Poise. Halving crit at 15+ DE: +1 Conc. Crit at 20+ DE: 3 Fragile + 3 DLD
/datum/component/palermitan_skill/eleganza/famiglias_honor
	var/poise_before_crit = 0

/datum/component/palermitan_skill/eleganza/famiglias_honor/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_POISE_CRIT_ATTACKER, PROC_REF(on_poise_crit))

/datum/component/palermitan_skill/eleganza/famiglias_honor/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_POISE_CRIT_ATTACKER)
	. = ..()

/datum/component/palermitan_skill/eleganza/famiglias_honor/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	var/de = get_duel_stacks(target)
	// Increase DE max to 30
	var/datum/status_effect/stacking/duel_escalates/D = target.has_status_effect(/datum/status_effect/stacking/duel_escalates)
	if(D)
		D.max_stacks = 30
	// At 15+ DE: +2 Poise
	if(de >= 15)
		user.apply_lc_poise(2)
	// Store poise for crit detection
	var/datum/status_effect/stacking/poise/P = user.has_status_effect(/datum/status_effect/stacking/poise)
	poise_before_crit = P ? P.stacks : 0

/datum/component/palermitan_skill/eleganza/famiglias_honor/proc/on_poise_crit(datum/source, mob/living/target, bonus_damage)
	SIGNAL_HANDLER
	if(!isliving(target))
		return
	var/mob/living/user = parent
	var/de = get_duel_stacks(target)
	// Halving crit at 15+ DE: +1 Concentration
	if(de >= 15)
		var/datum/status_effect/stacking/poise/P = user.has_status_effect(/datum/status_effect/stacking/poise)
		var/poise_after = P ? P.stacks : 0
		if(poise_before_crit > 0 && poise_after < poise_before_crit * 0.75)
			user.apply_lc_concentration(1)
	// Crit at 20+ DE: 3 Fragile + 3 DLD
	if(de >= 20)
		target.apply_lc_fragile(3)
		target.apply_lc_defense_level_down(3)

//
// SCHOOL 4: FONDAMENTI (General)
//

// T1a: Iron Constitution - On taking damage: +2 DLU
/datum/component/palermitan_skill/fondamenti/iron_constitution

/datum/component/palermitan_skill/fondamenti/iron_constitution/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_take_damage))

/datum/component/palermitan_skill/fondamenti/iron_constitution/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_APPLY_DAMGE)
	. = ..()

/datum/component/palermitan_skill/fondamenti/iron_constitution/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	return

/datum/component/palermitan_skill/fondamenti/iron_constitution/proc/on_take_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(!damage || damage <= 0)
		return
	var/mob/living/user = parent
	user.apply_lc_defense_level_up(2)

// T1b: Aggressive Footwork - On Hit: +1 OLU. On taking melee damage: +1 OLU
/datum/component/palermitan_skill/fondamenti/aggressive_footwork

/datum/component/palermitan_skill/fondamenti/aggressive_footwork/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_take_damage))

/datum/component/palermitan_skill/fondamenti/aggressive_footwork/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_APPLY_DAMGE)
	. = ..()

/datum/component/palermitan_skill/fondamenti/aggressive_footwork/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	user.apply_lc_offense_level_up(1)

/datum/component/palermitan_skill/fondamenti/aggressive_footwork/proc/on_take_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(!damage || damage <= 0)
		return
	var/mob/living/user = parent
	user.apply_lc_offense_level_up(1)

// T2a: Predator's Instinct - On Hit vs <50% HP: 2 Fragile +2 Poise. <25%: +5 OLU +2 Poise
/datum/component/palermitan_skill/fondamenti/predators_instinct

/datum/component/palermitan_skill/fondamenti/predators_instinct/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	var/hp_percent = target.health / target.maxHealth
	if(hp_percent < 0.25)
		target.apply_lc_fragile(2)
		user.apply_lc_poise(2)
		user.apply_lc_offense_level_up(5)
		user.apply_lc_poise(2)
	else if(hp_percent < 0.5)
		target.apply_lc_fragile(2)
		user.apply_lc_poise(2)

// T2b: Enduring Spirit - On Hit vs 3+ DE: heal 1 HP/stack (max 5). On taking damage near DE target: +1 DLU
/datum/component/palermitan_skill/fondamenti/enduring_spirit

/datum/component/palermitan_skill/fondamenti/enduring_spirit/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_take_damage))

/datum/component/palermitan_skill/fondamenti/enduring_spirit/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_APPLY_DAMGE)
	. = ..()

/datum/component/palermitan_skill/fondamenti/enduring_spirit/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	var/de = get_duel_stacks(target)
	if(de < 3)
		return
	var/heal = min(de, 5)
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.adjustBruteLoss(-heal)

/datum/component/palermitan_skill/fondamenti/enduring_spirit/proc/on_take_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(!damage || damage <= 0)
		return
	var/mob/living/user = parent
	// Check if any nearby mob has DE from us
	for(var/mob/living/L in range(3, get_turf(user)))
		if(L == user)
			continue
		var/datum/status_effect/stacking/duel_escalates/D = L.has_status_effect(/datum/status_effect/stacking/duel_escalates)
		if(D && D.duelist == user)
			user.apply_lc_defense_level_up(1)
			return

// T3a: Coup de Grace - On Hit vs <20% HP with 5+ DE: bonus RED = DE*3, consume 50%
/datum/component/palermitan_skill/fondamenti/coup_de_grace

/datum/component/palermitan_skill/fondamenti/coup_de_grace/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	var/hp_percent = target.health / target.maxHealth
	if(hp_percent >= 0.2)
		return
	var/de = get_duel_stacks(target)
	if(de < 5)
		return
	var/bonus = de * 3
	target.deal_damage(bonus, RED_DAMAGE, source = user, attack_type = ATTACK_TYPE_MELEE)
	// Consume 50%
	var/datum/status_effect/stacking/duel_escalates/D = target.has_status_effect(/datum/status_effect/stacking/duel_escalates)
	if(D)
		var/consume = round(D.stacks / 2)
		if(consume > 0)
			D.add_stacks(-consume)
	to_chat(user, span_nicegreen("Coup de Gr\u00e2ce! [bonus] bonus RED damage!"))

// T3b: Unbreakable Will - On entering soft crit (60s CD): +5 DLU +3 Protection +heal 10% max HP
/datum/component/palermitan_skill/fondamenti/unbreakable_will
	var/last_proc_time = 0

/datum/component/palermitan_skill/fondamenti/unbreakable_will/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_change))

/datum/component/palermitan_skill/fondamenti/unbreakable_will/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_STATCHANGE)
	. = ..()

/datum/component/palermitan_skill/fondamenti/unbreakable_will/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	return

/datum/component/palermitan_skill/fondamenti/unbreakable_will/proc/on_stat_change(datum/source, new_stat, old_stat)
	SIGNAL_HANDLER
	if(new_stat < SOFT_CRIT)
		return
	if(old_stat >= SOFT_CRIT)
		return
	if(world.time < last_proc_time + 60 SECONDS)
		return
	last_proc_time = world.time
	var/mob/living/user = parent
	user.apply_lc_defense_level_up(5)
	user.apply_lc_protection(3)
	var/heal = round(user.maxHealth * 0.1)
	if(heal > 0)
		user.adjustBruteLoss(-heal)
	to_chat(user, span_boldnotice("Unbreakable Will activates! You refuse to fall!"))
