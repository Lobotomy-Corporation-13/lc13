# Association Rework Plan

## Overview

Rework the Association system from static skill-book abilities into a dynamic **skill tree + EXP progression** system, modeled after the Ring Skill Tree (`ModularLobotomy/ring_skills/`). Each association will have its own gimmick for earning EXP and a 3-tier skill tree with binary choices per tier.

## Goals

1. **Remove Liu** as an association choice (temporarily shelved).
2. **Add two new associations**: Dieci and Cinq.
3. **Rework Zwei and Seven** from skill-book abilities to a proper skill tree.
4. **Each association earns EXP differently** by performing their thematic gimmick (parallel to how Ring artists earn EXP from creating artwork).
5. **Unified skill tree UI** - reuse or adapt the `RingSkillTree.js` TGUI pattern for an `AssociationSkillTree` interface.
6. **Remove the old skill-book system** for affected associations (skillgranter items become obsolete).

## Design Guidelines - Association Identity

Associations are **not heroes**. They are self-interested organizations that interact with the facility and its people to further their own goals. While their gimmicks may involve helping, healing, or protecting civilians, this is always a **means to an end**, never the end itself.

**Core Principles:**

1. **Transactional, not altruistic.** Every interaction an association has with civilians or other roles should be motivated by what the association gets out of it. Dieci don't interview you because they care about your feelings - they want your story for their research. Zwei don't protect you out of kindness - you're standing behind their defensive line and they need bodies between them and the enemy. The benefit to others is a side effect, not the goal.

2. **Association goals come first.** Each association has its own objectives (research, territory, contracts, reputation, etc.). Protecting civilians is only useful insofar as it serves those objectives. If a civilian has nothing to offer, the association has no obligation to help them.

3. **Mutual benefit, not charity.** When associations provide benefits to other players (SP healing, buffs, protection), it should be framed as a trade or transaction. The other player gets something useful, but the association member gets something they need more (EXP, information, leverage, positioning).

4. **Morally gray, not evil.** Associations aren't villains - they don't go around hurting innocents for fun. They're professionals with a job to do. They can be friendly, personable, even generous - but there's always an angle. Think "corporate contractor" not "selfless guardian."

5. **RP-driven conflict potential.** Because associations are self-interested, there should be natural tension points: What happens when the association's goals conflict with the facility's needs? When two associations want the same thing? When a civilian refuses to cooperate? These create organic RP scenarios without requiring anyone to be "the bad guy."

---

## Architecture (Mirroring Ring System)

### New Components / Datums

| Ring Equivalent | Association Equivalent | Purpose |
|---|---|---|
| `/datum/component/artistic_exp` | `/datum/component/association_exp` | Tracks EXP, skill points, association investment |
| `/datum/component/ring_skill` | `/datum/component/association_skill` | Base skill component with on_attack / on_damage hooks |
| `/datum/ring_skill_tree` | `/datum/association_skill_tree` | TGUI datum for the skill tree UI |
| `GLOB.ring_skill_definitions` | `GLOB.association_skill_definitions` | Global skill definitions per association |
| `RingSkillTree.js` | `AssociationSkillTree.js` | TGUI React interface |

### Key Differences from Ring System

- **One association per player** (not multi-school). The Director picks the association, everyone in the squad gets that one.
- **EXP source is per-association** rather than a universal "create artwork" action.
- **No school-limit cap** - you only have your one association's tree.
- **Starting points may vary by job tier** (Director > Veteran > Associate), or all start at 0 and earn through play.

### Ally Designation (Universal — All Associations)

All association members receive a **Designate Allies** action as part of their base kit (not a skill tree pick — granted automatically with the association). This lets the fixer mark specific players as allies so that ally-targeting skills (auras, buffs, damage absorption, etc.) only affect designated allies rather than every nearby mob.

**Why this exists:** Without it, skills like Vigilant Presence or Iron Curtain would buff/protect hostile mobs and enemy players in range. The ally list gives the fixer control over who benefits from their abilities.

**How it works:**
- `/datum/action/cooldown/designate_ally` — uses the same pointed spell pattern as Mark for Protection (`InterceptClickOn()` + click-to-select), but can select **multiple** players.
- Click a player to add them to your `list/designated_allies`. Click them again to remove them.
- Fellow association squad members (Director, Veteran, Associate) are **automatically** added to the ally list on round start.
- The ally list is stored on the `/datum/component/association_exp` component (accessible to all skills).
- Skills that reference "allies" (Vigilant Presence, Iron Curtain, Earthshatter ally count, etc.) check `is_designated_ally(mob/living/L)` which returns `TRUE` if L is in the list.
- No limit on the number of designated allies.
- Visual feedback: designated allies see a small icon over the fixer's head; the fixer sees a small icon over each ally's head.

```dm
/datum/action/cooldown/designate_ally
	name = "Designate Ally"
	desc = "Click a player to add or remove them from your ally list. Allies benefit from your protective skills."
	cooldown_time = 1 SECONDS
	check_flags = AB_CHECK_CONSCIOUS
	click_to_activate = TRUE

/datum/action/cooldown/designate_ally/InterceptClickOn(mob/living/user, params, atom/target)
	if(!isliving(target) || target == user)
		return FALSE
	var/datum/component/association_exp/exp = user.GetComponent(/datum/component/association_exp)
	if(!exp)
		return FALSE
	if(target in exp.designated_allies)
		exp.designated_allies -= target
		to_chat(user, span_warning("[target] removed from your ally list."))
		to_chat(target, span_warning("You are no longer designated as [user]'s ally."))
	else
		exp.designated_allies += target
		to_chat(user, span_nicegreen("[target] added to your ally list."))
		to_chat(target, span_nicegreen("[user] has designated you as an ally."))
	StartCooldown()
	return TRUE
```

**New file:** `ModularLobotomy/associations/skills/_designate_ally.dm`

### Skill Tree Structure (Per Association)

Each association has **2-3 branches** (like Ring schools), allowing players to specialize within their association. Each branch has **3 tiers**, each tier has **2 choices (a/b)** - pick one. Tier cost scales (1 / 2 / 3 points per tier). This mirrors the Ring multi-school pattern exactly.

**Branch Investment Rules:**
- Each association defines how many branches it has (2 or 3)
- Players can invest in a **maximum of 2 branches** (same as Ring's `max_schools = 2`)
- This forces meaningful specialization: with 3 branches, you must leave one empty
- A branch counts as "invested" once you spend any skill points in it
- Full investment in one branch costs 6 points (1 + 2 + 3); two branches = 12 points

**Association Branch Counts:**
| Association | Branches | Max Invested |
|---|---|---|
| Zwei | 3 (Guardian, Territory, Client) | 2 |
| Seven | 3 (Analyst, Coordinator, Operative) | 2 |
| Dieci | TBD (2-3) | 2 |
| Cinq | TBD (2-3) | 2 |

---

## Ring System Reference (For Implementation)

This section contains the full patterns and code from the Ring Skill Tree system that this rework is based on. Since the new branch will not have direct access to these files, everything needed to replicate the pattern is documented here.

### 1. EXP Component (`/datum/component/artistic_exp`)

**Source:** `ModularLobotomy/ring_skills/artistic_exp.dm`

Tracks EXP, skill points, and school investment. The association equivalent should mirror this structure.

```dm
/datum/component/artistic_exp
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Current artistic EXP
	var/exp = 0
	/// Skill points available to spend
	var/skill_points = 0
	/// Skill points already spent
	var/skill_points_spent = 0
	/// Schools the player has invested in
	var/list/schools_invested = list()
	/// Maximum number of schools this player can invest in (2 for students, 3 for apprentice, 4 for maestro)
	var/max_schools = 2
	/// The main school this player identifies with (for examine text)
	var/main_school = null

	/// EXP thresholds for skill points (fast for first 4 levels, then slows down)
	var/static/list/exp_thresholds = list(30, 70, 120, 180, 350, 600, 950, 1400, 1950, 2600, 3350, 4200)
```

**Key Procs:**

```dm
/// Get the next EXP threshold
/datum/component/artistic_exp/proc/get_next_threshold()
	var/total_points = skill_points + skill_points_spent
	if(total_points >= length(exp_thresholds))
		return exp_thresholds[length(exp_thresholds)]
	return exp_thresholds[total_points + 1]

/// Modify EXP (positive or negative)
/datum/component/artistic_exp/proc/modify_exp(amount)
	exp = max(0, exp + amount)
	if(amount > 0)
		to_chat(parent, span_nicegreen("You gained [amount] Artistic EXP! ([exp] total)"))
	else if(amount < 0)
		to_chat(parent, span_warning("You lost [abs(amount)] Artistic EXP! ([exp] total)"))
	check_skill_points()

/// Add EXP from artistic activities (flat amounts)
/datum/component/artistic_exp/proc/add_activity_exp(activity_type)
	var/exp_gain = 0
	switch(activity_type)
		if("create_artwork")
			exp_gain = 5
		if("add_body")
			exp_gain = 3
	if(exp_gain > 0)
		modify_exp(exp_gain)

/// Check if we've earned new skill points
/datum/component/artistic_exp/proc/check_skill_points()
	var/total_points_earned = 0
	for(var/i in 1 to length(exp_thresholds))
		if(exp >= exp_thresholds[i])
			total_points_earned = i
		else
			break
	var/new_points = total_points_earned - skill_points_spent
	if(new_points > skill_points)
		var/points_gained = new_points - skill_points
		skill_points = new_points
		to_chat(parent, span_greentext("You earned [points_gained] new skill point(s)! Open the Ring Skill Tree to spend them."))
		var/mob/M = parent
		if(istype(M))
			SEND_SOUND(M, sound('sound/machines/chime.ogg'))

/// Spend a skill point
/datum/component/artistic_exp/proc/spend_skill_point(cost = 1)
	if(skill_points < cost)
		return FALSE
	skill_points -= cost
	skill_points_spent += cost
	return TRUE

/// Refund all skill points
/datum/component/artistic_exp/proc/refund_all_points()
	skill_points += skill_points_spent
	skill_points_spent = 0
	schools_invested = list()
	return TRUE

/// Check if player can invest in a school
/datum/component/artistic_exp/proc/can_invest_in_school(school_name)
	if(school_name in schools_invested)
		return TRUE
	if(length(schools_invested) >= max_schools)
		return FALSE
	return TRUE

/// Register investment in a school
/datum/component/artistic_exp/proc/invest_in_school(school_name)
	if(!(school_name in schools_invested))
		schools_invested += school_name

/// Grant starting skill points and set max schools based on role
/datum/component/artistic_exp/proc/grant_starting_points(role)
	switch(role)
		if("maestro")
			skill_points = 8
			max_schools = 4
		if("apprentice")
			skill_points += 4
			max_schools = 3
		// Students start with 0 skill points and max 2 schools (default)
```

**Signals registered:** `COMSIG_PARENT_EXAMINE` for showing school info / EXP stats on examine.

---

### 2. Base Skill Component (`/datum/component/ring_skill`)

**Source:** `ModularLobotomy/ring_skills/schools/_schools.dm`

Base class all skills inherit from. Provides signal hooks and helper procs.

```dm
/datum/component/ring_skill
	/// Name of the skill
	var/skill_name = "Base Skill"
	/// Description of the skill
	var/skill_desc = "A ring skill."
	/// Which school this skill belongs to
	var/school = "corporist"
	/// Which tier (1-3)
	var/tier = 1
	/// Which choice (a or b)
	var/choice = "a"
	/// Reference to the human parent
	var/mob/living/carbon/human/human_parent

/datum/component/ring_skill/Initialize()
	. = ..()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	human_parent = parent

/datum/component/ring_skill/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_attack))
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_take_damage))
	RegisterSignal(parent, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(on_after_take_damage))

/datum/component/ring_skill/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_MOB_ITEM_ATTACK,
		COMSIG_MOB_APPLY_DAMGE,
		COMSIG_MOB_AFTER_APPLY_DAMGE
	))
	human_parent = null
	. = ..()

/// Called when the parent attacks something with an item
/datum/component/ring_skill/proc/on_attack(datum/source, mob/living/target, obj/item/weapon)
	SIGNAL_HANDLER
	return

/// Called when the parent is about to take damage
/datum/component/ring_skill/proc/on_take_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	return

/// Called after the parent takes damage
/datum/component/ring_skill/proc/on_after_take_damage(datum/source, damage, damagetype, def_zone, wound_bonus, bare_wound_bonus, sharpness, atom/attacker, flags, attack_type)
	SIGNAL_HANDLER
	return
```

**Helper procs (all on `/datum/component/ring_skill`):**

```dm
/// Check if user has any positive stacking effect (Protection or Damage Up)
/datum/component/ring_skill/proc/has_positive_effect(mob/living/user)
	if(user.has_status_effect(/datum/status_effect/stacking/protection))
		return TRUE
	if(user.has_status_effect(/datum/status_effect/stacking/damage_up))
		return TRUE
	return FALSE

/// Check if target is bleeding
/datum/component/ring_skill/proc/target_is_bleeding(mob/living/target)
	return !!target.has_status_effect(/datum/status_effect/stacking/lc_bleed)

/// Get bleed stacks on target
/datum/component/ring_skill/proc/get_bleed_stacks(mob/living/target)
	var/datum/status_effect/stacking/lc_bleed/bleed = target.has_status_effect(/datum/status_effect/stacking/lc_bleed)
	if(!bleed)
		return 0
	return bleed.stacks

/// Count status effects on target (bleed, overheat, tremor, mental_decay)
/datum/component/ring_skill/proc/count_status_effects(mob/living/target)
	var/count = 0
	if(target.has_status_effect(/datum/status_effect/stacking/lc_bleed))
		count++
	if(target.has_status_effect(/datum/status_effect/stacking/lc_overheat))
		count++
	if(target.has_status_effect(/datum/status_effect/stacking/lc_tremor))
		count++
	if(target.has_status_effect(/datum/status_effect/stacking/lc_mental_decay))
		count++
	return count

/// Apply random status effect
/datum/component/ring_skill/proc/apply_random_effect(mob/living/target, stacks = 1)
	var/effect_type = pick("bleed", "overheat", "tremor", "mental_decay")
	switch(effect_type)
		if("bleed")
			target.apply_lc_bleed(stacks)
		if("overheat")
			target.apply_lc_overheat(stacks)
		if("tremor")
			target.apply_lc_tremor(stacks)
		if("mental_decay")
			target.apply_lc_mental_decay(stacks)
	return effect_type

/// Add protection stacks additively, capped at ring_max
/datum/component/ring_skill/proc/add_ring_protection(mob/living/user, stacks_to_add, ring_max = 5)
	var/datum/status_effect/stacking/protection/P = user.has_status_effect(/datum/status_effect/stacking/protection)
	if(!P)
		user.apply_status_effect(/datum/status_effect/stacking/protection, min(stacks_to_add, ring_max))
		return
	if(P.stacks >= ring_max)
		return
	var/add_amount = min(stacks_to_add, ring_max - P.stacks)
	P.add_stacks(add_amount)

/// Add damage up stacks additively, capped at ring_max
/datum/component/ring_skill/proc/add_ring_strength(mob/living/user, stacks_to_add, ring_max = 5)
	var/datum/status_effect/stacking/damage_up/S = user.has_status_effect(/datum/status_effect/stacking/damage_up)
	if(!S)
		user.apply_status_effect(/datum/status_effect/stacking/damage_up, min(stacks_to_add, ring_max))
		return
	if(S.stacks >= ring_max)
		return
	var/add_amount = min(stacks_to_add, ring_max - S.stacks)
	S.add_stacks(add_amount)
```

---

### 3. Skill Tree Datum (`/datum/ring_skill_tree`)

**Source:** `ModularLobotomy/ring_skills/ring_skill_tree.dm`

Handles the TGUI interface. Contains `ui_data()` to send data and `ui_act()` to handle skill selection.

```dm
/datum/ring_skill_tree
	var/mob/living/carbon/human/viewer

/datum/ring_skill_tree/New(mob/living/carbon/human/user)
	viewer = user

/datum/ring_skill_tree/Destroy()
	viewer = null
	return ..()

/datum/ring_skill_tree/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RingSkillTree")
		ui.open()

/datum/ring_skill_tree/ui_state(mob/user)
	return GLOB.conscious_state
```

**ui_data() - sends EXP info + school tiers to TGUI:**

```dm
/datum/ring_skill_tree/ui_data(mob/user)
	var/list/data = list()
	var/datum/component/artistic_exp/exp_comp = viewer.GetComponent(/datum/component/artistic_exp)
	if(!exp_comp)
		return data

	data["exp"] = exp_comp.exp
	data["next_threshold"] = exp_comp.get_next_threshold()
	data["skill_points"] = exp_comp.skill_points
	data["skill_points_spent"] = exp_comp.skill_points_spent
	data["schools_invested"] = exp_comp.schools_invested
	data["main_school"] = exp_comp.main_school
	data["max_schools"] = exp_comp.max_schools

	// Build skill data for each school
	data["schools"] = list()

	// Example school entry:
	data["schools"] += list(list(
		"name" = "Fauvists",
		"id" = "fauvist",
		"desc" = "Those who use primary colors and complex lines.",
		"theme" = "Predatory aggression, WHITE/SP damage focus.",
		"tiers" = get_school_tiers("fauvist", exp_comp)
	))
	// ... repeat for each school ...

	return data
```

**get_school_tiers() - builds tier/choice data from GLOB definitions:**

```dm
/datum/ring_skill_tree/proc/get_school_tiers(school_id, datum/component/artistic_exp/exp_comp)
	var/list/tiers = list()
	var/list/skill_defs = GLOB.ring_skill_definitions[school_id]
	if(!skill_defs)
		return tiers

	for(var/tier_num in 1 to 3)
		var/list/tier_data = list(
			"tier" = tier_num,
			"cost" = tier_num,
			"choices" = list()
		)

		var/previous_completed = (tier_num == 1) || has_tier_completed(school_id, tier_num - 1)
		var/can_afford = exp_comp.skill_points >= tier_num
		var/can_invest = exp_comp.can_invest_in_school(school_id)

		var/list/tier_skills = skill_defs["tier[tier_num]"]
		if(tier_skills)
			for(var/choice in list("a", "b"))
				var/list/skill_info = tier_skills[choice]
				if(!skill_info)
					continue
				var/skill_type = skill_info["type"]
				var/is_selected = has_skill(skill_type)
				var/other_choice = (choice == "a") ? "b" : "a"
				var/other_selected = has_skill(tier_skills[other_choice]["type"])

				tier_data["choices"] += list(list(
					"id" = choice,
					"name" = skill_info["name"],
					"desc" = skill_info["desc"],
					"type" = "[skill_type]",
					"selected" = is_selected,
					"excluded" = other_selected,
					"available" = (previous_completed && can_afford && can_invest && !is_selected && !other_selected),
					"locked" = !previous_completed
				))
		tiers += list(tier_data)
	return tiers

/datum/ring_skill_tree/proc/has_tier_completed(school_id, tier_num)
	var/list/skill_defs = GLOB.ring_skill_definitions[school_id]
	if(!skill_defs)
		return FALSE
	var/list/tier_skills = skill_defs["tier[tier_num]"]
	if(!tier_skills)
		return FALSE
	for(var/choice in list("a", "b"))
		var/list/skill_info = tier_skills[choice]
		if(skill_info && has_skill(skill_info["type"]))
			return TRUE
	return FALSE

/datum/ring_skill_tree/proc/has_skill(skill_type)
	var/datum/component/ring_skill/skill = locate(skill_type) in viewer.GetComponents(/datum/component/ring_skill)
	return !!skill
```

**ui_act() - handles skill selection and main school setting:**

```dm
/datum/ring_skill_tree/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("select_skill")
			var/skill_type = text2path(params["skill_type"])
			var/school_id = params["school"]
			var/tier = text2num(params["tier"])
			if(!skill_type)
				return FALSE

			var/datum/component/artistic_exp/exp_comp = viewer.GetComponent(/datum/component/artistic_exp)
			if(!exp_comp)
				return FALSE

			if(exp_comp.skill_points < tier)
				to_chat(viewer, span_warning("You don't have enough skill points!"))
				return FALSE
			if(!exp_comp.can_invest_in_school(school_id))
				to_chat(viewer, span_warning("You can only invest in 2 schools maximum!"))
				return FALSE

			if(!exp_comp.spend_skill_point(tier))
				return FALSE
			exp_comp.invest_in_school(school_id)

			// Add the skill component
			viewer.AddComponent(skill_type)

			to_chat(viewer, span_nicegreen("You have learned a new skill!"))
			playsound(viewer, 'sound/machines/chime.ogg', 50, TRUE)
			return TRUE

		if("set_main_school")
			var/school_id = params["school"]
			if(!school_id)
				return FALSE
			var/datum/component/artistic_exp/exp_comp = viewer.GetComponent(/datum/component/artistic_exp)
			if(!exp_comp)
				return FALSE
			if(!(school_id in exp_comp.schools_invested))
				to_chat(viewer, span_warning("You must invest in a school before claiming it!"))
				return FALSE
			exp_comp.main_school = school_id
			return TRUE
	return FALSE
```

---

### 4. Global Skill Definitions (`GLOB.ring_skill_definitions`)

**Source:** `ModularLobotomy/ring_skills/ring_skill_tree.dm` (bottom of file)

Format for defining skills per school. Each school has tier1/tier2/tier3 with choices a/b.

```dm
GLOBAL_LIST_INIT(ring_skill_definitions, init_ring_skill_definitions())

/proc/init_ring_skill_definitions()
	var/list/defs = list()

	defs["fauvist"] = list(
		"tier1" = list(
			"a" = list(
				"name" = "Predator's Scent",
				"desc" = "+15% damage vs bleeding targets",
				"type" = /datum/component/ring_skill/fauvist/predators_scent
			),
			"b" = list(
				"name" = "Maddening Maw",
				"desc" = "Attacks on bleeding targets deal 15% of your melee damage as additional WHITE damage",
				"type" = /datum/component/ring_skill/fauvist/maddening_maw
			)
		),
		"tier2" = list(
			"a" = list(
				"name" = "Rending Claws",
				"desc" = "Attacks apply 2 bleed stacks",
				"type" = /datum/component/ring_skill/fauvist/rending_claws
			),
			"b" = list(
				"name" = "Savage Instinct",
				"desc" = "After hitting a bleeding target, gain +15% damage for 4 seconds (refreshes on hit)",
				"type" = /datum/component/ring_skill/fauvist/savage_instinct
			)
		),
		"tier3" = list(
			"a" = list(
				"name" = "Spreading Wounds",
				"desc" = "When hitting bleeding target, adjacent enemies gain 3 bleed",
				"type" = /datum/component/ring_skill/fauvist/spreading_wounds
			),
			"b" = list(
				"name" = "Primal Terror",
				"desc" = "Hitting targets with 10+ bleed deals 20 WHITE damage and removes 5 bleed stacks",
				"type" = /datum/component/ring_skill/fauvist/primal_terror
			)
		)
	)

	// ... repeat for each school ...
	return defs
```

**Association Equivalent (`GLOB.association_skill_definitions`):**

The association version follows the exact same pattern, but each association has multiple branches (like schools). Here's how Zwei's 3 branches would be defined:

```dm
GLOBAL_LIST_INIT(association_skill_definitions, init_association_skill_definitions())

/proc/init_association_skill_definitions()
	var/list/defs = list()

	// Zwei has 3 branches, each structured like a Ring school
	defs["zwei"] = list(
		"branches" = list(
			list(
				"name" = "Guardian",
				"id" = "zwei_guardian",
				"desc" = "Personal defense with defense-to-offense conversion.",
				"theme" = "You ARE the shield. Build Defense Level Up stacks, convert them to damage.",
				"tiers" = list(
					"tier1" = list(
						"a" = list("name" = "Iron Stance", "desc" = "On taking melee damage, gain 3 Defense Level Up stacks. 0.5s CD.", "type" = /datum/component/association_skill/zwei/guardian/iron_stance),
						"b" = list("name" = "Aggressive Guard", "desc" = "On hitting an enemy, gain 2 Defense Level Up stacks. 1s CD.", "type" = /datum/component/association_skill/zwei/guardian/aggressive_guard)
					),
					"tier2" = list(
						"a" = list("name" = "Shieldbreaker", "desc" = "Attacks deal bonus RED damage equal to your Defense Level Up % of weapon base damage.", "type" = /datum/component/association_skill/zwei/guardian/shieldbreaker),
						"b" = list("name" = "Steady Footing", "desc" = "While you have any Defense Level Up stacks, gain +15% movement speed.", "type" = /datum/component/association_skill/zwei/guardian/steady_footing)
					),
					"tier3" = list(
						"a" = list("name" = "Retaliating Onslaught", "desc" = "Powerful Attack (90s CD): Dash + 5-hit combo. DLU stacks boost damage, consumed after.", "type" = /datum/component/association_skill/zwei/guardian/retaliating_onslaught),
						"b" = list("name" = "Unbreakable", "desc" = "On lethal hit: survive at 15% HP, gain 7 Protection + 3s invuln. 5min CD.", "type" = /datum/component/association_skill/zwei/guardian/unbreakable)
					)
				)
			),
			list(
				"name" = "Territory Protection",
				"id" = "zwei_territory",
				"desc" = "Area defense, ally buffs, and enemy debuffs.",
				"theme" = "Hold the line, defend the zone. Aura effects and area denial.",
				"tiers" = list(
					"tier1" = list(
						"a" = list("name" = "Vigilant Presence", "desc" = "Allies within 4 tiles gain 2 Defense Level Up stacks every 10s.", "type" = /datum/component/association_skill/zwei/territory/vigilant_presence),
						"b" = list("name" = "Warden's Watch", "desc" = "+15% damage vs mobs in contracted area (+25% if their target is yourself).", "type" = /datum/component/association_skill/zwei/territory/wardens_watch)
					),
					"tier2" = list(
						"a" = list("name" = "Law and Order", "desc" = "Hostiles entering within 5 tiles receive 2 Tremor stacks. 15s CD per target.", "type" = /datum/component/association_skill/zwei/territory/law_and_order),
						"b" = list("name" = "Fortified Position", "desc" = "Stationary 3s+ in contracted area: +5 Defense Level Up every 5s. Moving removes stacks.", "type" = /datum/component/association_skill/zwei/territory/fortified_position)
					),
					"tier3" = list(
						"a" = list("name" = "Earthshatter", "desc" = "Powerful Attack (90s CD): AoE slam + 3-hit combo at 50% DPS (6 in contracted area). Per-hit: 2 Defense Level Down to target, 3 Defense Level Up to self.", "type" = /datum/component/association_skill/zwei/territory/earthshatter),
						"b" = list("name" = "Iron Curtain", "desc" = "In contracted area: absorb 25% of ally damage within 4 tiles (redirected to you at 50%).", "type" = /datum/component/association_skill/zwei/territory/iron_curtain)
					)
				)
			),
			list(
				"name" = "Client Protection",
				"id" = "zwei_client",
				"desc" = "Targeted bodyguard for a single ward.",
				"theme" = "Mark one person, protect them with everything you have.",
				"tiers" = list(
					"tier1" = list(
						"a" = list("name" = "Designated Ward", "desc" = "Mark a player. Within 7 tiles, they gain 2 Defense Level Up every 10s.", "type" = /datum/component/association_skill/zwei/client/designated_ward),
						"b" = list("name" = "Threatening Presence", "desc" = "Mark a player. Hostiles attacking your ward deal 10% less damage while you're near.", "type" = /datum/component/association_skill/zwei/client/threatening_presence)
					),
					"tier2" = list(
						"a" = list("name" = "Bodyguard's Instinct", "desc" = "When ward takes damage, gain +30% speed for 2s. Arrow points to ward if distant.", "type" = /datum/component/association_skill/zwei/client/bodyguards_instinct),
						"b" = list("name" = "Shared Resilience", "desc" = "When you gain Defense Level Up stacks, your ward gains half (within 7 tiles).", "type" = /datum/component/association_skill/zwei/client/shared_resilience)
					),
					"tier3" = list(
						"a" = list("name" = "Guardian's Wrath", "desc" = "Powerful Attack (120s CD): Leap + 4-hit combo. Double damage if ward was hurt recently. Per-hit: heals ward.", "type" = /datum/component/association_skill/zwei/client/guardians_wrath),
						"b" = list("name" = "Lifelink", "desc" = "Ward takes melee/ranged damage: teleport to them and take the hit instead. 15s CD.", "type" = /datum/component/association_skill/zwei/client/lifelink)
					)
				)
			)
		)
	)

	// Seven, Dieci, Cinq follow same pattern...
	return defs
```

---

### 5. TGUI Interface (`RingSkillTree.js`)

**Source:** `tgui/packages/tgui/interfaces/RingSkillTree.js`

Full React component. The association version should adapt this, replacing "school" terminology with "association".

```jsx
import { useBackend, useLocalState } from '../backend';
import {
  Box, Button, Flex, Icon, NoticeBox, ProgressBar, Section, Stack, Tabs,
} from '../components';
import { Window } from '../layouts';

// Color themes per school
const SCHOOL_COLORS = {
  fauvist: '#c44536',
  pointillist: '#4a7c59',
  cubist: '#5b7c99',
  corporist: '#8b4513',
};

export const RingSkillTree = (props, context) => {
  const { act, data } = useBackend(context);
  const [selectedSchool, setSelectedSchool] = useLocalState(
    context, 'selectedSchool', 'fauvist'
  );

  const {
    exp = 0, next_threshold = 50, skill_points = 0,
    skill_points_spent = 0, schools_invested = [],
    schools = [], main_school = null, max_schools = 2,
  } = data;

  const currentSchool = schools.find(s => s.id === selectedSchool);
  const canInvestInSchool = schools_invested.length < max_schools
    || schools_invested.includes(selectedSchool);

  return (
    <Window width={700} height={550} title="Ring Skill Tree">
      <Window.Content>
        <Stack vertical fill>
          {/* Header: EXP bar + skill points */}
          <Stack.Item>
            <Section>
              <Stack>
                <Stack.Item grow>
                  <Box bold>Artistic EXP</Box>
                  <ProgressBar value={exp} maxValue={next_threshold} color="purple">
                    {exp} / {next_threshold}
                  </ProgressBar>
                </Stack.Item>
                <Stack.Item basis="200px">
                  <Box bold>Skill Points</Box>
                  <Box fontSize="1.5em" textAlign="center" color="gold">
                    {skill_points} available
                    <Box fontSize="0.6em" color="gray">({skill_points_spent} spent)</Box>
                  </Box>
                </Stack.Item>
              </Stack>
              {/* Schools invested display + main school buttons */}
            </Section>
          </Stack.Item>

          {/* School Tabs */}
          <Stack.Item>
            <Tabs fluid>
              {schools.map(school => (
                <Tabs.Tab key={school.id}
                  selected={selectedSchool === school.id}
                  onClick={() => setSelectedSchool(school.id)}
                  color={selectedSchool === school.id ? SCHOOL_COLORS[school.id] : null}>
                  {school.name}
                </Tabs.Tab>
              ))}
            </Tabs>
          </Stack.Item>

          {/* School Content - tiers and choices */}
          <Stack.Item grow>
            {currentSchool ? <SchoolDisplay ... /> : <NoticeBox>No data</NoticeBox>}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
```

**Key sub-components:**

- `SchoolDisplay` - Shows school name/desc/theme + list of `TierDisplay`
- `TierDisplay` - Shows tier number, cost, lock/check icons, two `SkillChoice` side by side
- `SkillChoice` - Individual skill box with visual states:
  - **selected** (green check, highlighted border)
  - **excluded** (red X, grayed out - the other choice was picked)
  - **locked** (lock icon, dark bg - previous tier not completed)
  - **available** (gold border + "Learn Skill" button)
  - On click / button click: `act('select_skill', { skill_type, school, tier })`

---

### 6. Skill Tree Action (Opens the TGUI)

**Source:** `ModularLobotomy/actions/corporist_actions.dm`

Action button that creates/opens the skill tree datum.

```dm
/datum/action/innate/ring_skill_tree
	name = "Ring Skill Tree"
	desc = "Open the Ring Skill Tree to spend your skill points."
	icon_icon = 'icons/obj/ring_icons.dmi'
	button_icon_state = "skill_tree"
	check_flags = AB_CHECK_CONSCIOUS
	var/datum/ring_skill_tree/skill_tree_datum

/datum/action/innate/ring_skill_tree/Activate()
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return
	var/datum/component/artistic_exp/exp_comp = H.GetComponent(/datum/component/artistic_exp)
	if(!exp_comp)
		to_chat(H, span_warning("You have no artistic experience."))
		return
	if(!skill_tree_datum)
		skill_tree_datum = new(H)
	skill_tree_datum.ui_interact(H)

/datum/action/innate/ring_skill_tree/Remove(mob/M)
	if(skill_tree_datum)
		QDEL_NULL(skill_tree_datum)
	. = ..()
```

---

### 7. Example Skill Implementations

**Passive on-attack skill (Corporist - Butcher Ribs):**

```dm
/datum/component/ring_skill/corporist/butcher_ribs
	skill_name = "Butcher - Ribs"
	skill_desc = "On Hit: Apply 2 bleed to target and gain 1 Protection."
	school = "corporist"
	tier = 1
	choice = "a"
	var/bleed_stacks = 2
	var/protection_stacks = 1

/datum/component/ring_skill/corporist/butcher_ribs/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target) || target.stat == DEAD)
		return
	target.apply_lc_bleed(bleed_stacks)
	add_ring_protection(human_parent, protection_stacks)
	// ... synergy bonuses ...
```

**Passive + extra signal skill (Fauvist - Predator's Scent, uses AFTERATTACK to clean up):**

```dm
/datum/component/ring_skill/fauvist/predators_scent
	skill_name = "Predator's Scent"
	school = "fauvist"
	tier = 1
	choice = "a"
	var/damage_bonus = 15
	var/active_bonus = 0

/datum/component/ring_skill/fauvist/predators_scent/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return
	if(target_is_bleeding(target))
		active_bonus = damage_bonus
		human_parent.extra_damage += active_bonus

/datum/component/ring_skill/fauvist/predators_scent/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_ITEM_AFTERATTACK, PROC_REF(on_afterattack))

/datum/component/ring_skill/fauvist/predators_scent/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_ITEM_AFTERATTACK)
	. = ..()

/datum/component/ring_skill/fauvist/predators_scent/proc/on_afterattack(datum/source, mob/living/target, obj/item/weapon)
	SIGNAL_HANDLER
	if(active_bonus > 0)
		human_parent.extra_damage -= active_bonus
		active_bonus = 0
```

**Timed buff skill (Fauvist - Savage Instinct):**

```dm
/datum/component/ring_skill/fauvist/savage_instinct
	school = "fauvist"
	tier = 2
	choice = "b"
	var/damage_buff = 15
	var/buff_duration = 4 SECONDS
	var/buff_active = FALSE
	var/buff_timer_id

/datum/component/ring_skill/fauvist/savage_instinct/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target) || !target_is_bleeding(target))
		return
	if(buff_active)
		if(buff_timer_id)
			deltimer(buff_timer_id)
	else
		buff_active = TRUE
		human_parent.extra_damage += damage_buff
	buff_timer_id = addtimer(CALLBACK(src, PROC_REF(remove_buff)), buff_duration, TIMER_STOPPABLE)

/datum/component/ring_skill/fauvist/savage_instinct/proc/remove_buff()
	if(buff_active)
		buff_active = FALSE
		human_parent.extra_damage -= damage_buff

/datum/component/ring_skill/fauvist/savage_instinct/UnregisterFromParent()
	if(buff_timer_id)
		deltimer(buff_timer_id)
	if(buff_active)
		human_parent.extra_damage -= damage_buff
	. = ..()
```

**Active ability skill (Corporist - Exhibition Arrangements, grants a cooldown action):**

```dm
/datum/component/ring_skill/corporist/exhibition_arrangements
	school = "corporist"
	tier = 3
	choice = "b"
	var/buff_active = FALSE
	var/buff_duration = 8 SECONDS
	var/buff_timer_id
	var/mob/living/last_target

/datum/component/ring_skill/corporist/exhibition_arrangements/RegisterWithParent()
	. = ..()
	// Grant the activation action button
	var/datum/action/cooldown/exhibition_arrangements_activate/action = new(human_parent)
	action.skill_ref = WEAKREF(src)
	action.Grant(human_parent)

/datum/component/ring_skill/corporist/exhibition_arrangements/UnregisterFromParent()
	for(var/datum/action/cooldown/exhibition_arrangements_activate/action in human_parent.actions)
		action.Remove(human_parent)
	if(buff_timer_id)
		deltimer(buff_timer_id)
	last_target = null
	. = ..()

// The action that activates the skill
/datum/action/cooldown/exhibition_arrangements_activate
	name = "Exhibition Arrangements"
	cooldown_time = 30 SECONDS
	check_flags = AB_CHECK_CONSCIOUS
	var/datum/weakref/skill_ref

/datum/action/cooldown/exhibition_arrangements_activate/Trigger(trigger_flags)
	. = ..()
	if(!.)
		return FALSE
	var/datum/component/ring_skill/corporist/exhibition_arrangements/skill = skill_ref?.resolve()
	if(!skill)
		return FALSE
	skill.activate_buff()
	StartCooldown()
	return TRUE
```

---

### 8. Current Association System (Old - Being Replaced)

**Job Definitions:** `code/modules/jobs/job_types/trusted_players/association/col_association.dm`
- `/datum/job/director` - 1 position, 120 attrs, COMMAND|ASSOCIATION dept, paycheck 700
- `/datum/job/veteran` - 0-1 positions (enabled when Director spawns), 100 attrs
- `/datum/job/associate` - 0-3 positions (enabled when Director spawns), 80 attrs
- All get `TRAIT_WORK_FORBIDDEN`, Director/Veteran get `TRAIT_COMBATFEAR_IMMUNE`
- Director's `after_spawn()` picks random antag role, enables Veteran/Associate slots

**Gear Beacon:** `ModularLobotomy/associations/association_beacon.dm`
- `/obj/item/choice_beacon/association` - Director picks from subtypes of `/obj/item/storage/box/association`
- Each box spawns weapons, armor, and skill books for the chosen association

**Old Skill Books:** `ModularLobotomy/associations/skills/skillgranter.dm`
- `/obj/item/assoc_skill_granter` - checks job title, grants action abilities, deleted after use
- Three tiers: Associate (base skills), Veteran (more skills), Director (all skills)
- Skills are hardcoded `/datum/action/cooldown/` and `/datum/action/innate/` types

**Old Zwei Skills:**
- Your Shield: 30% DR for 5s (15s CD)
- Stand Proud: 1s godmode + 3s immobilize (10s CD)
- Protect the Innocent: 50% DR buff to lower-level allies for 15s (45s CD, Veteran+)
- Flexible Suppression: 30% max HP brute to big targets (5min CD, Director)
- Last Stand: Revive on death, then DoT until dead (30min CD, Veteran+)

**Old Seven Skills:**
- Analysis: Toggle medical HUD + thermals
- Third Eye: 5s x-ray + thermals (60s CD)
- Quick Getaway: 1.5x all damage mods + speed boost + smoke (20s CD)
- Weakness Analyzed: 1.4x black_mod debuff on nearby for 15s (60s CD, Veteran+)
- Field Command: Toggle 10% DR + speed buff to nearby allies (Veteran+)
- Exploit the Gap: Speed dash then 1.2x all damage vulnerability on nearby for 30s (90s CD, Director)

---

## Contract System

The contract system is the **universal EXP framework** that all associations use. Contracts formalize the work that associations do, turning "standing around helping for free" into tracked, rewarded, professional engagements.

### Why Contracts Exist

**The Problem:** Currently, association fixers (especially Zwei) patrol and protect for free because they want to keep players alive and the round going. There is no mechanical difference between "doing your job" and "doing nothing." Civilians and facilities (like the clinic) have no money to hire fixers even if they wanted to. The result is that the association's transactional identity is lost - they're just free bodyguards.

**The Solution:** Association skill tree abilities **only function while on an active contract.** No contract = no skills. Contracts are also the **only way to earn EXP.** This makes contracts mechanically necessary, not optional flavor.

### Contract Sources & EXP Multipliers

Contracts can come from three sources. Anyone can hire the association, but civilian contracts are the most rewarding:

| Contract Source | EXP Multiplier | Notes |
|---|---|---|
| **Civilian/other role contract** | **2x EXP** | Any non-association, non-Hana player hires a fixer directly. Most rewarding because it requires real player interaction. |
| **Hana-issued contract** | **1x EXP** | Hana creates the contract, funds it from their unlimited budget. Baseline steady work to keep fixers busy. |
| **No active contract** | **0 EXP, no skills** | Skill tree abilities are disabled. Cannot progress. |

**Important: Association fixers CANNOT give themselves contracts.** They must always be hired by someone else - either the Hana or any other non-association role. This enforces the transactional nature of the system: you are a professional being contracted, not a volunteer choosing your own assignments.

**Why civilians give 2x EXP:** The Hana is the easy, reliable contract source - they're always available and have unlimited money. Civilian contracts require the fixer to actually go out, interact with people, and convince someone to hire them. This harder, more interactive path is rewarded with double EXP, incentivizing fixers to engage with the broader playerbase rather than just camping the Hana terminal.

### How Contracts Work

**Who Can Create Contracts:**

- **Any non-association player (civilians, clinic staff, command, etc.):** Can approach a fixer and offer a contract directly, or post one on a contract board. They pay from their own funds. Gives **2x EXP** - the most rewarding source.
- **Hana (Administrator / Representative):** Contract dispatcher. Uses a **Contract Terminal** (TGUI interface). Has unlimited funding. Gives 1x EXP - steady baseline work. This is an addition to their existing role, not a replacement.
- **Association fixers:** **Cannot** create contracts for themselves or each other. They must be hired.

**Contract Types:**

Contracts are split into **universal types** (available to all associations) and **association-specific types** (unique to each association's specialty).

*Universal:*

1. **Patrol Route** - Mark two or more waypoints on the city map. Fixer must visit them in order and loop for the contract duration. Available to all associations - the basic "go here, do your thing" contract.

*Zwei-Specific:*

2. **Guard Area** (Zwei only) - Designate a zone on the city map to protect. Must stay within the area's radius for the contract duration. Reflects Zwei's area defense specialization.

3. **Protect Person** (Zwei only) - Target a specific player. Must stay within 5-7 tiles of the client for the duration. The fixer must **accept** the contract offer. Reflects Zwei's personal bodyguard work.

*Other associations will have their own specific contract types defined in their sections.*

**Contract Parameters:**
- **Duration:** 3 / 5 / 10 minutes (set by the contract creator)
- **Funding:** Credit amount offered as payment (Hana has unlimited funds; civilian contracts paid from their own wallet)
- **Target/Location:** Who or where the contract applies to

**Contract Lifecycle:**
1. Contract is created (by Hana, civilian, or any non-association role)
2. Fixer accepts the contract (from a terminal, contract board, or direct offer prompt)
3. Timer starts, skills activate, EXP begins ticking
4. Fixer fulfills the contract by staying on task for the duration
5. **Bonus EXP** accrues from relevant actions during the contract (combat, damage taken, etc. - varies by association)
6. Contract completes → lump sum EXP payout + payment transfer
7. Fixer needs a new contract to keep skills active

**Contract Rules:**
- One active contract per fixer at a time
- Short cooldown between contracts (~30s, prevents instant re-contracting)
- Association fixers **cannot** create contracts for themselves or other association members
- Breaking a contract early (leaving area/client) → contract fails, reduced EXP, cooldown penalty
- Fixer can **decline** a contract offer (they're professionals, not slaves)

### The Hana's Role (Additions to Existing Job)

This is **not** a new role. These are additions to the existing Hana job (`code/modules/jobs/job_types/trusted_players/hana.dm`).

**Current Hana System:**
- 3 tiers: Administrator (1, 100 attrs, command), Representative (2, 80 attrs, trusted), Intern (2, 60 attrs, not trusted)
- Currently has: `hanafetchquest` verb (spawns a diamond coin), unlimited funding, ID access
- Very limited mechanical tools - mostly RP-based authority

**New Additions - Contract Dispatcher Tools:**

The existing Hana gains a new **Contract Terminal** (TGUI interface) as part of their toolkit, alongside their existing quest and admin tools. This gives them concrete mechanical authority over the fixers they're supposed to be managing.

**Contract Terminal (New TGUI - added to existing Hana abilities):**
- Create contracts with type, duration, funding, and target/location
- View all active contracts and their status (who's on what job)
- View completed contracts (history/stats)
- Only Hana Administrator and Representative can create contracts (not Interns)
- Interns can view the contract board but not create Hana-tier contracts

**Why Fixers Still Need the Hana (Even at 1x EXP):**
- Hana contracts are **reliable and funded** - civilians may not always have money or be willing to hire
- Hana contracts come with **payment from unlimited budget** - guaranteed income even when no civilian is hiring
- Hana can create **Patrol Routes** (Zwei-specific, Hana-issued only)
- Hana keeps fixers busy during **downtime** when no civilians need protection - 1x EXP is better than 0 EXP
- The Hana is the **safety net** that ensures fixers always have work, even if the lucrative civilian contracts aren't available

**Why the Hana is Motivated:**
- Hana performance is tracked: contracts issued, contracts completed, total fixer time on-contract
- This gives them a concrete job beyond RP - they're managing a workforce
- A Hana who isn't creating contracts is leaving fixers idle with no skills and no EXP
- Could tie into round-end reports showing Hana effectiveness

**When No Hana is Present:**
- Fixers rely entirely on civilians and other roles to hire them (2x EXP)
- This actually gives better EXP per contract, but is less reliable (civilians may not hire)
- Any non-association player can create contracts, so the system doesn't break
- Having a Hana is still valuable for the steady funded work between civilian contracts

### Client Benefits (Why Civilians Accept Contracts)

When a Protect Person contract is active, the client receives benefits while their fixer is nearby:

- **Damage Reduction Aura:** ~10-15% less damage taken while the contracted fixer is within range
- **SP Stabilization:** Slower SP decay / minor passive SP regen from the security of having a bodyguard
- **Visible Protection Status:** Examine text shows "Under [Association] protection" - an RP deterrent
- Benefits only active while the fixer is within contract range

These benefits incentivize civilians to **accept** contracts when offered, creating the mutual transaction loop.

### Contract System - New Files

- `ModularLobotomy/associations/contracts/contract_datum.dm` - Base contract datum (type, duration, funding, target, status)
- `ModularLobotomy/associations/contracts/contract_terminal.dm` - Physical terminal object + TGUI for Hana
- `ModularLobotomy/associations/contracts/contract_actions.dm` - Contract actions (civilian offer, fixer accept/decline, view active contract)
- `ModularLobotomy/associations/contracts/contract_citymap.dm` - City map generation datum for contract location picking
- `tgui/packages/tgui/interfaces/ContractTerminal.js` - Hana's contract creation/management UI (includes city map view)
- `tgui/packages/tgui/interfaces/ContractBoard.js` - Fixer's contract browsing/accepting UI (could be same as terminal with reduced permissions)
- `tgui/packages/tgui/interfaces/ContractCityMap.js` - City map TGUI component (reusable, embedded in ContractTerminal)

### Contract City Map (Location Picker)

For contracts that require picking locations (Guard Area, Patrol Route), the Contract Terminal displays an **interactive city map** that the contract creator can click on to place waypoints or define zones.

**Reference System:** `code/game/machinery/facility_holomap.dm` + `code/controllers/subsystem/holomap.dm`

The existing holomap system generates maps by iterating all turfs on a z-level and drawing pixels onto a 480x480 icon canvas. The contract city map uses a similar approach but is purpose-built for the contract TGUI:

**How the Existing Holomap Generates Maps:**

```dm
// From code/controllers/subsystem/holomap.dm - generateBaseHolomap()
// Iterates Z_TURFS(zlevel), checks turf type, draws colored pixels:
//   - HOLOMAP_OBSTACLE for walls/grilles
//   - HOLOMAP_PATH for floors/catwalks
//   - Skips rock/hidden areas
// Uses a 480x480 icon canvas (HOLOMAP_ICON) with pixel offsets:
//   HOLOMAP_PIXEL_OFFSET_X = (480 / 2) - world.maxx / 2
//   HOLOMAP_PIXEL_OFFSET_Y = (480 / 2) - world.maxy / 2
// Each turf = 1 pixel on the map, drawn at (T.x + offset_x, T.y + offset_y)

// Area overlays are generated separately in generateHolomapAreaOverlays()
// Each area with a holomap_color gets its turfs drawn in that color
```

**Contract City Map - Differences from Holomap:**

The contract city map is NOT a full holomap. It is a **TGUI-based interactive map** that only shows the city area:

1. **Only records `/area/city` turfs where `in_city == TRUE`**
   - The `/area/city` type (`code/game/area/areas/lobotomy_corp.dm:265`) has `var/in_city = TRUE` by default
   - Subtypes like `/area/city/outskirts`, `/area/city/backstreets_alley`, `/area/city/backstreets_room` set `in_city = FALSE`
   - This filters the map to only show the actual city streets and buildings, not the backstreets/outskirts/ruins

2. **1:1 scale with the actual game map** - each tile = 1 pixel on the map, same as the holomap

3. **TGUI viewport with 25x25 chunk display** - The full city map is too large to display at once in TGUI at a readable scale. Instead:
   - The map is rendered server-side as tile data (list of x,y coordinates with type: wall/floor/empty)
   - TGUI displays a **25x25 tile viewport** of the map at a time
   - The user navigates with **Arrow Keys** to pan the viewport **one tile at a time**
   - The viewport position is tracked server-side and sent to TGUI on each update

4. **Clickable tiles for placing waypoints/zones:**
   - **Patrol Route:** Click tiles to place numbered waypoints (1, 2, 3...). Fixers must visit them in order.
   - **Guard Area (Zwei):** Click a center tile, then define a radius. The zone is highlighted on the map.
   - Placed markers are shown as colored overlays on the map tiles.
   - Can click an existing waypoint to remove it.

**Map Generation (Server-Side):**

```dm
// Pseudocode for contract city map generation
/datum/contract_citymap
	/// 2D list of tile data: list(x = list(y = tile_type))
	/// tile_type: CITYMAP_EMPTY, CITYMAP_WALL, CITYMAP_FLOOR
	var/list/tile_data = list()
	/// Bounds of the city area (min/max x,y that have city tiles)
	var/min_x, min_y, max_x, max_y
	/// Current viewport position (top-left corner of the 25x25 view)
	var/view_x, view_y
	/// List of placed waypoints: list(list("x" = x, "y" = y, "order" = n))
	var/list/waypoints = list()
	/// Guard zone center + radius (for Zwei Guard Area contracts)
	var/zone_center_x, zone_center_y, zone_radius

/datum/contract_citymap/proc/generate_city_map()
	// Iterate all turfs on the city z-level
	// For each turf:
	//   - Check if turf.loc is /area/city and area.in_city == TRUE
	//   - If yes, record as CITYMAP_WALL or CITYMAP_FLOOR based on turf type
	//   - Track min/max bounds for the viewport clamping
	// Start viewport centered on the map
```

**TGUI Data Flow:**

```
ui_data() sends:
  - 25x25 grid of tile data (relative to current viewport position)
  - viewport position (view_x, view_y)
  - map bounds (for clamping navigation)
  - list of waypoints (with positions relative to viewport for rendering)
  - guard zone data if applicable

ui_act() handles:
  - "move_viewport" with direction (N/S/E/W) - shifts viewport by 1 tile
  - "place_waypoint" with x,y (relative to viewport) - adds a patrol waypoint
  - "remove_waypoint" with index - removes a waypoint
  - "set_guard_zone" with x,y,radius - defines a Zwei guard area
```

**Why 25x25 Chunks:**
- At 1:1 scale, the full city map could be 200+ tiles wide. Displaying that in TGUI would be tiny and unreadable.
- 25x25 at a reasonable pixel size (~12-16px per tile) fits comfortably in a TGUI window (~300-400px).
- Arrow key navigation lets the user pan smoothly, one tile at a time, to find the exact location they want.
- The viewport acts like a "magnifying glass" over the city map.

---

## Associations

---

### Zwei (Section 6) - "The Shield"

**Theme:** Civil protection and peacekeeping. Zwei are professional bodyguards and area defenders who sell protection as a service. They fight defensively, prioritizing their client's safety over killing threats. Two sub-styles exist in lore: South (undercover, zweihanders) and West (heavy armor, broadswords/shields).

**Gimmick / EXP Source: Protection Contracts**

Zwei earn EXP through the contract system by fulfilling protection duties:

- **Passive EXP tick** while on contract and within range of client/area (~1 EXP per 10s)
- **Bonus EXP** for taking damage while near the client/in the guarded area (absorbing hits = fulfilling your duty)
- **Bonus EXP** for engaging hostiles that are within range of the client/area (neutralizing threats)
- **Contract completion bonus** based on duration and whether the client survived/area was held

**Contract-Specific Behavior:**
- Zwei skill tree abilities **only function while on an active contract**
- Guard Area contracts create a visible zone boundary (so the Zwei knows their post)
- Protect Person contracts show a tether/indicator to the client
- Breaking contract range starts a warning timer (~15s grace period) before contract fails

**Skill Tree - 3 Branches:**

Zwei has 3 branches. Players can invest in a maximum of 2.

**Core Status Effect: Defense Level Up** — Zwei skills primarily use the Defense Level Up status effect, which provides diminishing returns damage reduction: `(stacks / (stacks + 25)) * 100`%. Stacks additively and halves every 5 seconds, so active combat is needed to maintain high defense. Key reference values: 3 stacks = 10%, 9 = 26%, 20 = 44%, 30 = 55%, 100 = 80%.

#### Powerful Attack System (T3 Skills)

Each branch has one T3 that is a **Powerful Attack** — a cutscene-style multi-hit combo similar to the Tiantui Star's Blade flurry (`thumb.dm`). These attacks share the following mechanics:

**Shared Mechanics:**

1. **Weapon-agnostic:** Works with whatever melee weapon the user is holding. Uses that weapon's attack animation (`do_attack_animation()`) and hitsound.
2. **DPS-based damage:** Each hit deals damage equal to the weapon's DPS: `(force * force_multiplier * 1.25) / attack_speed`. This normalizes damage across fast/slow weapons — a fast dagger and a slow greatsword deal the same total damage per hit.
3. **Opening AoE:** Each attack starts with a unique AoE opener (dash, slam, leap, etc.) that varies by branch. The first enemy hit by the AoE becomes the **main target** for the combo.
4. **Duel Component:** On AoE hit, the main target receives `/datum/component/cutscene_duel` which **prevents ALL damage from sources other than the user** for the duration of the cutscene. This is removed when the combo ends. Prevents other players from kill-stealing or griefing during the attack.
5. **Weapon lock:** The user's held weapon receives `TRAIT_NODROP` for the combo duration, preventing it from being disarmed or dropped mid-attack. Removed on cleanup.
6. **Immobilization:** Both user and target are immobilized for the combo duration (user via `Immobilize()` + `changeNext_move()`, simplemob targets via `toggle_ai(AI_OFF)` + `Immobilize()`, humans via `Immobilize()`).
7. **Null/distance checks:** Each combo step checks `if(!target || !user || get_dist(target, user) > 15)` before continuing, same as tiantui flurry.
8. **Conditional bonuses:** Each attack has conditions that increase damage or add extra effects (more hits, bonus stacks, etc.).
9. **Per-hit effects:** Each individual hit can trigger a status effect application.

**Reference Pattern (from `thumb.dm`):**
- Action toggles targeting mode → click target → `PrepareAttack()` checks resources
- `InitiateCombo()` immobilizes both, disables simplemob AI, plays initial clash VFX
- `ExecuteCombo()` chains hits with `sleep()` between them, each hit calls `ComboHit()` (plays attack anim + sound) and `deal_damage(dps, damtype)`
- Final hit deals bonus damage, applies finisher effects, camera shake
- Cleanup: re-enable simplemob AI, unimmobilize, remove duel component, remove `TRAIT_NODROP` from weapon

```dm
/// Duel component - prevents damage from anyone except the designated attacker
/datum/component/cutscene_duel
	var/mob/living/attacker

/datum/component/cutscene_duel/Initialize(mob/living/designated_attacker)
	attacker = designated_attacker
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_damage))

/datum/component/cutscene_duel/proc/on_damage(datum/source, damage, damagetype, def_zone, blocked, forced, spread_flags, wound_bonus, bare_wound_bonus, sharpness, atom/incoming_attacker)
	SIGNAL_HANDLER
	if(incoming_attacker != attacker)
		return COMPONENT_MOB_DENY_DAMAGE

/datum/component/cutscene_duel/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_APPLY_DAMGE)
	attacker = null
	. = ..()
```

---

#### Branch 1: Guardian (Self-Defense)

**Theme:** You ARE the shield. Personal defense, with some skills converting defense into offense.

**T1 (1pt) — Pick one:**
- **A: Iron Stance** — On taking melee damage, gain 3 Defense Level Up stacks. 0.5s internal CD.
- **B: Aggressive Guard** — On hitting an enemy, gain 2 Defense Level Up stacks. 1s internal CD.

**T2 (2pt) — Pick one:**
- **A: Shieldbreaker** — Your attacks deal bonus RED damage equal to your Defense Level Up percentage of your weapon's base damage.
- **B: Steady Footing** — While you have any Defense Level Up stacks, gain +15% movement speed.

**T3 (3pt) — Pick one:**
- **A: Retaliating Onslaught** *(Powerful Attack, 90s CD)* — Dash forward 3 tiles. Multi-hit combo on first enemy hit. Bonus: each Defense Level Up stack increases total damage by 1%, stacks consumed after. Per-hit: applies 1 Tremor.
- **B: Unbreakable** *(Passive)* — On lethal damage, survive at 15% HP, gain 7 Protection stacks + 3s invulnerability. 5min CD.

**Retaliating Onslaught — Details:**
- **Opener:** Dash forward 3 tiles in facing direction, damaging enemies in the line (like `FlurryDash` with `dash_through = TRUE`). First enemy hit becomes the main target.
- **Combo:** 5 hits. User dashes to/through target between strikes.
- **Per-hit effect:** Each hit applies 1 Tremor stack to the target.
- **Condition:** Before the combo starts, read the user's current Defense Level Up stacks. Total combo damage is multiplied by `1 + (stacks / 100)`. All Defense Level Up stacks are consumed (set to 0) after the combo ends. At 25 stacks = +25% damage, at 50 stacks = +50%.
- **Final hit:** Deals 2x DPS instead of 1x, applies 3 Tremor, knocks target back 2 tiles.

**Implementation Notes:**
- Iron Stance: `COMSIG_MOB_AFTER_APPLY_DAMGE` → check melee → `apply_lc_defense_level_up(3)` with 0.5s cooldown var.
- Aggressive Guard: `COMSIG_MOB_ITEM_ATTACK` → `apply_lc_defense_level_up(2)` with 1s cooldown var.
- Shieldbreaker: `COMSIG_MOB_ITEM_ATTACK` → read Defense Level Up percentage → `INVOKE_ASYNC` → `target.deal_damage(weapon_base * def_pct, RED_DAMAGE)`.
- Steady Footing: Check for Defense Level Up status effect → add/remove movespeed modifier.
- Retaliating Onslaught: `/datum/action/cooldown/` → toggle targeting → `afterattack` override → `PrepareAttack()` → `InitiateCombo()`. Calc DPS = `(weapon.force * weapon.force_multiplier * 1.25) / weapon.attack_speed`. Read DLU stacks, apply multiplier, execute 5 hits with `sleep()` between each, consume stacks at end.
- Unbreakable: `COMSIG_MOB_APPLY_DAMGE` → lethal check → `COMPONENT_MOB_DENY_DAMAGE`, heal to 15%, `apply_lc_protection(7)`, 3s invuln.

---

#### Branch 2: Territory Protection (Area Defense)

**Theme:** Hold the line, defend the zone. Buff allies, debuff enemies that enter your territory.

**T1 (1pt) — Pick one:**
- **A: Vigilant Presence** — Allies within 4 tiles gain 2 Defense Level Up stacks every 10s.
- **B: Warden's Watch** — +15% damage vs mobs in contracted area (+25% if their target is yourself).

**T2 (2pt) — Pick one:**
- **A: Law and Order** — Hostiles entering within 5 tiles receive 2 Tremor stacks. 15s CD per target.
- **B: Fortified Position** — While stationary 3s+ in contracted area, gain 5 Defense Level Up stacks every 5s. Moving removes stacks from this skill.

**T3 (3pt) — Pick one:**
- **A: Earthshatter** *(Powerful Attack, 90s CD)* — AoE slam around self (3-tile radius). Multi-hit combo on closest enemy hit (each hit deals 50% DPS). Bonus: in contracted area, double number of hits. Per-hit: applies 2 Defense Level Down to target and 3 Defense Level Up to self.
- **B: Iron Curtain** *(Passive)* — While in contracted area, absorb 25% of all damage dealt to allies within 4 tiles (redirected to you at 50% effectiveness).

**Earthshatter — Details:**
- **Opener:** AoE ground slam centered on the user, 3-tile radius. All enemies in range take 0.5x DPS damage and are briefly stunned (0.5s). Closest enemy hit becomes the main target.
- **Combo:** 3 hits base (each hit deals 50% of weapon DPS). If used while **in contracted area**, the combo has 6 hits instead (doubled). The reduced per-hit damage is compensated by the high hit count and per-hit effects.
- **Per-hit effect:** Each hit applies 2 Defense Level Down stacks to the target (weakening their defenses for the team) and 3 Defense Level Up stacks to the user (building your own defense while attacking).
- **Condition:** For each ally within 5 tiles at the start of the combo, gain 1 additional bonus hit (up to +3). This rewards the Zwei for protecting a group.
- **Final hit:** Overhead slam that knocks target into the ground — applies 3 Tremor stacks and 1s stun.

**Implementation Notes:**
- Vigilant Presence: Process timer every 10s → `for(var/mob/living/L in range(4, human_parent))` → check `is_designated_ally(L)` → `L.apply_lc_defense_level_up(2)`.
- Warden's Watch: `COMSIG_MOB_ITEM_ATTACK` → contract area check → `extra_damage += 15` (or 25 if target's current target is the user). Clean up via `COMSIG_MOB_ITEM_AFTERATTACK`.
- Law and Order: Proximity check for hostiles → `target.apply_lc_tremor(2)`. Per-target cooldown tracking.
- Fortified Position: Track `last_move_time` via `COMSIG_MOVABLE_MOVED` → stationary 3s+ → `apply_lc_defense_level_up(5)` every 5s. On move: remove all stacks gained from this skill.
- Earthshatter: `/datum/action/cooldown/` → no targeting needed (AoE from self). On activate: AoE damage (0.5x DPS) in `range(3)` → pick closest hostile → apply duel component → immobilize → execute combo (each hit = 0.5x DPS). Check contract area for hit doubling, count designated allies via `is_designated_ally()` in `range(5)` for bonus hits.
- Iron Curtain: While in contracted area, register `COMSIG_MOB_AFTER_APPLY_DAMGE` on designated allies (via `is_designated_ally()`) in `range(4)` → redirect 25% of their damage to self at 50% effectiveness (so self takes 12.5% of ally's original damage). Refresh tracked ally list every 5s based on range + designation status.

---

#### Branch 3: Client Protection (Bodyguard)

**Theme:** One person, your responsibility. Mark a ward and devote everything to keeping them alive.

**Marking System:** T1 in this branch grants the **Mark for Protection** action (pointed spell pattern from `thin_line.dm`). One ward at a time. Re-marking removes old mark. Mark persists until manually removed, re-marked, or ward dies.

**T1 (1pt) — Pick one:**
- **A: Designated Ward** — Mark a player. While within 7 tiles, they gain 2 Defense Level Up stacks every 10s.
- **B: Threatening Presence** — Mark a player. Hostiles attacking your ward deal 10% less damage while you're nearby.

**T2 (2pt) — Pick one:**
- **A: Bodyguard's Instinct** — When your ward takes damage, gain +30% speed for 2s. Arrow indicator if distant.
- **B: Shared Resilience** — When you gain Defense Level Up stacks, your ward also gains half (within 7 tiles).

**T3 (3pt) — Pick one:**
- **A: Guardian's Wrath** *(Powerful Attack, 120s CD)* — Leap to a target from up to 7 tiles. Multi-hit combo. Bonus: if ward took damage in last 10s, damage is doubled. Per-hit: heals ward for 5% of damage dealt.
- **B: Lifelink** *(Passive)* — Ward takes melee/ranged damage: teleport to them, take the hit instead. 5s internal CD.

**Guardian's Wrath — Details:**
- **Opener:** Leap to target from up to 7 tiles away (same leap animation as tiantui final hit — `animate()` upward, `forceMove()` to landing zone, animate downward). Landing impact deals 1x DPS in a 1-tile radius around the landing zone. Enemy landed on (or closest in impact radius) becomes the main target.
- **Combo:** 4 hits. Furious close-range strikes defending your ward's honor.
- **Per-hit effect:** Each hit heals the ward for 5% of damage dealt (if ward is alive and within 10 tiles). This rewards the bodyguard for fighting near their client.
- **Condition:** If the ward **took any damage in the last 10 seconds**, all combo hits deal **double damage**. The Zwei fights hardest when their client is hurt. Additionally, if the ward is within 5 tiles during the combo, the user gains 2 Protection stacks per hit.
- **Final hit:** Deals 2x DPS, applies 5 Tremor stacks, knocks target back 3 tiles away from the ward's position.

**Implementation Notes:**
- Mark Action: `/datum/action/cooldown/mark_for_protection` using pointed spell pattern (`InterceptClickOn()` + click-to-select). Store `var/mob/living/ward`.
- Designated Ward: Process timer → if within 7 tiles of ward → `ward.apply_lc_defense_level_up(2)`.
- Threatening Presence: Register `COMSIG_MOB_APPLY_DAMGE` on ward → check if attacker hostile + Zwei within 7 tiles → damage *= 0.9.
- Bodyguard's Instinct: Register `COMSIG_MOB_AFTER_APPLY_DAMGE` on ward → movespeed modifier on self, 2s timer. Arrow via `client.images`.
- Shared Resilience: Hook into Defense Level Up stack changes on self → apply half to ward if in range.
- Guardian's Wrath: `/datum/action/cooldown/` → toggle targeting → click target → leap animation → apply duel component → immobilize → check `ward_last_damage_time` for double damage condition → execute 4 hits. Per-hit: `INVOKE_ASYNC` → `ward.adjustBruteLoss(-damage * 0.05)` if ward in range.
- Lifelink: Register `COMSIG_MOB_APPLY_DAMGE` on ward → `COMPONENT_MOB_DENY_DAMAGE` → teleport to ward → `INVOKE_ASYNC` redirect damage to self. 5s cooldown, 2-7 tile range.

---

#### Zwei Branch Synergies

The 2-branch limit creates natural playstyle combos:

| Combo | Playstyle | Strength |
|---|---|---|
| **Guardian + Territory** | "The Fortress" - Unkillable zone defender. Retaliating Onslaught consumes defense stacks for a massive offensive burst, Earthshatter weakens groups. | Best for Guard Area contracts. Two powerful attacks, self-sufficient. |
| **Guardian + Client** | "The Bodyguard" - Tanky protector who builds Defense Level Up, shares it with ward via Shared Resilience, then dumps it into Retaliating Onslaught for burst damage. Guardian's Wrath heals the ward. | Best for Protect Person contracts. Offense fueled by defense. |
| **Territory + Client** | "The Commander" - Zone controller with a ward. Earthshatter weakens groups while Guardian's Wrath punishes anyone who hurts the client. | Hybrid. Two different powerful attacks for different situations. Less personal survivability. |

---

**Zwei Design Notes:**
- Most skills use **Defense Level Up** stacks (diminishing returns: `stacks/(stacks+25)*100`%) instead of the old Protection (10%/stack)
- **Shieldbreaker** (Guardian T2a) is the key defense→offense conversion: bonus RED damage = your Defense Level Up percentage
- **T3 Powerful Attacks** follow the tiantui flurry pattern (`thumb.dm`): cutscene combo with immobilize, multi-hit DPS-based damage, duel component for damage isolation, and conditional bonuses
- Each hit deals weapon DPS (`force * force_multiplier * 1.25 / attack_speed`) so all weapons are equally viable
- Skills **only function while on an active contract** - no contract = no abilities
- The pointed spell pattern from `thin_line.dm` is used for the Mark for Protection targeting
- The lifelinked damage redirect pattern uses `COMSIG_MOB_APPLY_DAMGE` + `COMPONENT_MOB_DENY_DAMAGE` + `INVOKE_ASYNC`
- Old skills for reference: Your Shield (30% DR 5s), Stand Proud (1s godmode), Protect the Innocent (50% DR to allies), Flexible Suppression (% HP damage), Last Stand (revive)

---

### Seven (Section 4) - "The Eye"

**Theme:** Intelligence, investigation, and retribution. Seven are professional detectives and private investigators who specialize in solving mysteries and disturbances for the Corporations, namely the Distortion Phenomenon. They have knowledge of nearly everything in the City — any Syndicate, Office, and Incident is known to them. Their HQ is in the Southern Branch.

Seven's work follows a two-phase approach: **investigation first, retribution second.** Their Fixers are valued for discretion and observation skills. During missions, they are recommended to not rush into combat. Instead, they gather intelligence, build a case, and then — once the perpetrator is identified — they exact punishment with surgical precision. While not a combat Association, members are trained in the minimum required skills to repel any hostiles, using simple weapons of various tech.

**Gimmick / EXP Source: Investigation Contracts**

Seven earn EXP through intelligence gathering. Their investigation tools **only work on carbon mobs** (players with inventories who can speak), emphasizing player interaction over mob farming.

**Investigation Toolkit (items in gear box):**

1. **Seven Recorder** (`/obj/item/seven_recorder`) — A covert listening device disguised as a mundane object ("worn notebook" / "pocket watch"). Records all `Hear()` messages within range. Max 3 active recorders per fixer. EXP is earned based on **lines of conversation recorded**: 1 EXP per 5 lines captured, capped at **5 EXP per minute per recorder** (prevents AFK farming in busy areas).

   **Two deployment modes:**

   - **Floor Placement:** Use the recorder on a floor tile to place it as a hidden object (same pattern as spy bug placement). The recorder sits on the turf disguised as its mundane cover item. Records all `Hear()` messages in range. Can be picked back up by the fixer.

   - **Attachment to Item:** Use the recorder on any `/obj/item` to secretly attach it. The recorder `forceMove()`s into the item's contents and registers `COMSIG_MOVABLE_HEAR` on the item to capture surroundings. Crucially, the recorder **continues to hear even when the item is inside a backpack or container** — it registers `Hear()` on whatever mob is carrying the item (re-registering via `COMSIG_ITEM_PICKUP` / `COMSIG_ITEM_DROPPED` as the item changes hands). This means planting a recorder on someone's pen, then slipping it into their bag, lets the recorder hear everything around that person.

     **Examine Visibility:**
     - **Placing fixer:** When the Seven member who planted the recorder examines the host item, they always see: `"A Seven Recorder is attached to this item. [Remove]"` — the `[Remove]` is a clickable `href` button.
     - **Other mobs:** For the first **10 minutes** after placement, the recorder is completely invisible on examine. After 10 minutes, all examiners see: `"There is a small device attached to this item. [Remove]"` — with the same clickable remove button.
     - **Removal:** Anyone who can see the recorder on examine can click `[Remove]` to detach it, **as long as they are holding the item** (in active hand). The recorder is `forceMove()`'d to the remover's hands. If they aren't holding it, they receive: `"You need to be holding the item to remove the device."`

   **Recorder Storage & Retrieval:**
   - Floor-placed recorders can be picked up by clicking them.
   - Item-attached recorders are removed via the examine `[Remove]` button by the placing fixer while holding the host item (see above).
   - All recorders store their recordings on an internal tape (subtype of `/obj/item/tape`). The tape can be ejected, played back, or printed as a transcript (same as base tape recorder).

   **Implementation Notes:**
   - Subtype of `/obj/item/taperecorder` for `Hear()` recording.
   - Floor placement: `forceMove(get_turf(target))`, set `invisibility` to hide, add to `GLOB.seven_active_recorders`.
   - Item attachment: `forceMove(host_item)`, store `var/obj/item/host_item` and `var/mob/owner` (placing fixer). Register `COMSIG_MOVABLE_HEAR` on the host item. To hear through containers: also register `COMSIG_ITEM_PICKUP` and `COMSIG_ITEM_DROPPED` on the host item — on pickup, register `COMSIG_MOVABLE_HEAR` on the new carrier mob; on drop, unregister from the old carrier. This relay chain ensures the recorder captures speech near whoever is carrying the item.
   - Examine hook: Override `examine()` on the host item (or use `COMSIG_PARENT_EXAMINE` signal). Check `usr == owner` for always-visible text. For non-owners, check `world.time >= attached_time + 10 MINUTES`. Both cases show the `[Remove]` button: `<a href='?src=\ref[recorder];action=remove'>Remove</a>` with `Topic()` handler that validates `usr.get_active_held_item() == host_item`. Anyone who can see the recorder can remove it.
   - EXP tracking: `var/lines_recorded_this_minute = 0`, `var/exp_this_minute = 0`. Each `Hear()` increments `lines_recorded_this_minute`. Every 5 lines, grant 1 EXP (if `exp_this_minute < 5`). Reset both counters every 60 seconds via `addtimer`.
   - Visibility timer: `var/attached_time` set to `world.time` on attachment. Examine check: `world.time >= attached_time + 10 MINUTES` for non-owner visibility.

2. **Seven Camera** (`/obj/item/camera/seven_intel`) — A covert camera disguised as a mundane item ("pocket mirror" / "cigarette case"). Subtype of `/obj/item/camera` with stealth modifications: **no flash** (`flash = FALSE`), **no shutter sound** (override `captureimage()` to skip `playsound`), and **no visible message** to subjects (override the "[user] takes a photo" `visible_message` to only show to the user via `to_chat`). The camera silently creates intel snapshots — storing a `/datum/seven_intel_snapshot` containing ground truth data: area name (from `get_area_name()`), mob names (from `mobs_seen`), and held items (from target's `held_items`). This snapshot is used to validate reports later.

3. **Intel Report Paper** (`/obj/item/paper/intel_report`) — Pre-formatted paper with form fields (using the existing `form_fields` system on `/obj/item/paper`). Created by using a Seven Camera photo on a blank Intel Report form. The report presents questions the fixer must answer:
   - "Subject Name:" (text field)
   - "Area Observed:" (text field)
   - "Individuals Present:" (text field, comma-separated names)
   - "Items Carried:" (text field, comma-separated items)
   The server validates answers against the snapshot data using `findtext()` for case-insensitive fuzzy matching. Filing the report on the dossier awards EXP: **5 base + up to 10 accuracy bonus** per filed report. Cooldown: one report per target per 2 minutes.

4. **Backpack Scanner** (`/obj/item/seven_scanner`) — A covert scanning device disguised as a mundane handheld item ("worn PDA" / "old phone"). Works at a range of up to **5 tiles** — click on a visible carbon mob to discreetly scan their worn backpack/bag contents. Takes 3 seconds (internal timer, **no `do_after` progress bar**) during which the fixer must maintain line of sight. If line of sight breaks or the target moves out of range, the scan fails silently. **No visible message** is shown to the target or bystanders — only the scanning fixer receives feedback: `"You discreetly scan [target]'s belongings..."` on start and `"Scan complete."` on success. Records actual `contents` list of the target's storage item. The fixer then fills out a **Cargo Report** (variant of Intel Report) listing what the target was carrying. Validation and EXP: **3 base + up to 5 accuracy bonus**. Same 2-minute per-target cooldown.

5. **Seven Spyglass Kit** (`/obj/item/storage/box/seven_spyglass`) — Reuses the existing spy bug + spy glasses system (`code/game/objects/items/devices/spyglasses.dm`) with a Seven aesthetic. While actively observing through the spyglass popup window, the fixer earns **1 EXP per 30 seconds** if on contract.

6. **Investigation Dossier** (`/obj/item/seven_dossier`) — Physical storage item (clipboard/folder) with a TGUI interface (`SevenDossier.js`). Stores filed reports indexed by subject name. Each entry shows: subject name, area, timestamp, accuracy score. Summary statistics: total reports filed, total EXP earned from reports, most-observed subject. Reports are added by using a completed Intel Report or Cargo Report on the dossier.

7. **Recorder Receiver** (`/obj/item/seven_receiver`) — An earpiece/handheld radio that links to deployed Seven Recorders for live listening.

   **Live Listening:** Use the Receiver in-hand (`attack_self()`) to open a TGUI panel listing all of the fixer's active recorders (floor-placed and item-attached). Each entry shows: recorder index, deployment type (floor/item), host item name or turf location, lines recorded, and tape remaining. Select a recorder to **tune in** — while tuned in, the fixer hears everything the recorder's `Hear()` captures in real-time, relayed as `to_chat()` messages prefixed with `[RECORDER #N]:`. Only one recorder can be listened to at a time. The fixer can switch between recorders or stop listening from the panel.

   **Note:** Recorder retrieval is handled directly — floor recorders are picked up by clicking, and item-attached recorders are removed via the `[Remove]` button in the host item's examine text (see item 1).

   **Implementation Notes:**
   - Stores `var/list/linked_recorders` referencing the fixer's deployed `/obj/item/seven_recorder` instances.
   - Live listening: When tuned in, registers the receiver as a listener on the recorder's `Hear()` relay. Each message the recorder captures is forwarded via `to_chat(owner, span_notice("[RECORDER #[index]]: [message]"))`.
   - TGUI panel (`SevenReceiver.js` or simple `ui_interact`): Shows list of recorders with status (floor/item-attached, location/host item name, lines recorded, tape remaining). Toggle buttons for listen/stop.

8. **Seven Requisition Catalog** (`/obj/item/seven_catalog`) — A small handheld device (disguised as a "worn address book") that opens a TGUI shop interface when used in-hand (`attack_self()`). Allows the fixer to purchase replacement gadgets and consumables for ahn. Payment is deducted from the user's ID card bank account.

   **Available Items:**

   | Item | Price (ahn) |
   |------|-------------|
   | Seven Recorder | 200 |
   | Seven Camera | 150 |
   | Intel Report Paper (x3) | 50 |
   | Backpack Scanner | 200 |
   | Seven Spyglass Kit | 300 |
   | Investigation Dossier | 100 |
   | Recorder Receiver | 150 |

   **Implementation Notes:**
   - `/obj/item/seven_catalog` with `attack_self()` → `ui_interact()`.
   - TGUI panel (`SevenCatalog.js`): Simple list of items with name, description, price, and "Buy" button.
   - `ui_act("buy", params)` handler: Validates purchase using ID card bank account pattern:
   ```dm
   var/obj/item/card/id/C
   if(isliving(usr))
       var/mob/living/L = usr
       C = L.get_idcard(TRUE)
       if(!C || !C.registered_account)
           to_chat(L, span_warning("You need a valid ID card with a bank account."))
           return
       var/datum/bank_account/account = C.registered_account
       if(!account.adjust_money(-item_price))
           to_chat(L, span_warning("Insufficient funds."))
           return
       L.playsound_local(get_turf(src), 'sound/effects/cashregister.ogg', 25, 3, 3)
       var/obj/item/new_item = new item_path(get_turf(L))
       L.put_in_hands(new_item)
   ```
   - `ui_data()` returns list of available items with name, desc, price, and type path.

**Intel Snapshot Validation System:**

```dm
/// Ground truth captured when a photo is taken or scan is performed
/datum/seven_intel_snapshot
	/// Reference to the photo datum
	var/datum/picture/photo
	/// Area name where the photo was taken
	var/area_name
	/// List of mob names visible in the photo
	var/list/mob_names = list()
	/// List of item names held/worn by targets
	var/list/mob_items = list()
	/// World.time when snapshot was taken
	var/timestamp

/// On taking a photo with Seven Camera:
/obj/item/camera/seven_intel/after_picture(mob/user, datum/picture/picture)
	var/datum/seven_intel_snapshot/snapshot = new()
	snapshot.photo = picture
	snapshot.area_name = get_area_name(get_turf(user))
	for(var/mob/living/M in picture.mobs_seen)
		snapshot.mob_names += M.name
		for(var/obj/item/I in M.held_items)
			snapshot.mob_items += I.name
	snapshot.timestamp = world.time
	// Store snapshot on the camera for later report creation
	stored_snapshots += snapshot
```

**Seven-Specific Contract Types:**

- **Investigate Person** (Seven only) — Target a specific carbon player. The fixer must gather intelligence on them using Seven tools and file reports. Duration-based. EXP ticks while on contract and actively observing/investigating the target. Reflects Seven's role as private investigators hired to watch specific individuals.

- **Surveillance Post** (Seven only) — Mark a location on the city map. The fixer must place recording devices, maintain surveillance over the area, and file reports on activity observed there. EXP ticks while recorders are active in the designated area. Reflects Seven's role in monitoring locations for suspicious activity.

**EXP Sources Summary:**

| Activity | EXP Gain | Notes |
|---|---|---|
| Passive contract tick | 1 EXP / 10s | While on active contract |
| Recorder lines captured | 1 EXP per 5 lines recorded | Max 5 EXP/min per recorder, max 3 recorders |
| Spyglass active observation | 1 EXP / 30s | While popup is open on contract |
| Filed Intel Report (photo) | 5 base + up to 10 accuracy bonus | 1 per target per 2min |
| Filed Cargo Report (scan) | 3 base + up to 5 accuracy bonus | 1 per target per 2min |
| Combat (hitting contracted target) | 1 EXP per hit | Standard combat bonus |
| Contract completion bonus | 10-30 EXP | Based on duration + success |

**Contract-Specific Behavior:**
- Seven skill tree abilities **only function while on an active contract**
- Investigate Person contracts show a subtle indicator pointing to the target's direction
- Surveillance Post contracts highlight the monitored area boundary
- Breaking contract parameters (leaving area, losing track of target) starts a warning timer (~15s) before contract fails

**Skill Tree — 3 Branches:**

Seven has 3 branches. Players can invest in a maximum of 2.

**Core Status Effect: Rupture** — Seven skills primarily use the Rupture status effect, a delayed-trigger debuff: stacks build up, remain inactive for 5 seconds after application, then when the target takes RED or BLACK damage, all stacks burst for BRUTE damage (equal to stacks for humans, stacks × 4 for simple mobs). Stacks halve after triggering. This mirrors the investigation→retribution loop perfectly: build intel (stacks), wait for the right moment (activation delay), then strike (trigger).

**Secondary Effects (exploitation hierarchy):**
- **Rupture** (core payload): Build stacks, trigger for burst BRUTE damage
- **Fragile** (amplifier): Increases all damage taken, making rupture triggers and subsequent hits hit harder
- **Feeble** (crippling): Reduces the target's melee damage dealt (`apply_lc_feeble`) — cripples the target's ability to fight back while you build your case
- **Defense Level Down** (team enabler): Diminishing returns vulnerability (`stacks/(stacks+25)*100`%) — makes the target easier to kill for everyone
- **Offense Level Down** (suppression): Reduces the target's damage output via diminishing returns, protecting your team while you set up

The branches are designed so that:
- **Analyst** focuses on Rupture (build + detonate on a single target)
- **Coordinator** focuses on Defense Level Down + Offense Level Down + Feeble (team debuffs and target suppression)
- **Operative** focuses on Rupture + Fragile (burst damage windows)

Mixing branches gives access to all five effects, rewarding the 2-branch investment limit.

#### Branch 1: Analyst (Target Elimination)

**Theme:** Mark one target. Build rupture and convert it into devastating single-target damage. The field agent who gathers intel on a single mark, then eliminates them with surgical strikes. Every hit on your mark feeds the dossier — and the dossier feeds the kill. Applies some Rupture, but the Operative builds stacks faster.

**Marking System:** T1 in this branch grants the **Mark Target** action (pointed spell pattern, `InterceptClickOn()`). One mark at a time. Re-marking removes old mark. Mark persists until manually removed, re-marked, or target dies. This is **separate** from the Seven weapon's existing "hit 7 times to store target" mechanic — both systems coexist independently.

**T1 (1pt) — Pick one:**
- **A: Case File** — Mark a target. Your attacks against the marked target apply 2 Rupture stacks and deal bonus BLACK damage equal to 1% of your weapon's base force per Rupture stack on them (max +40% at 40 stacks). The mark focuses your investigation — every piece of evidence builds the case and sharpens the blade.
- **B: Profiling** — Mark a target. Each time you attack the marked target, gain 2 Offense Level Up stacks (max 10 from this skill). All stacks are lost when the mark changes or the target dies. Each attack deepens your understanding of the subject.

**T2 (2pt) — Pick one:**
- **A: Exploit Weakness** — Your attacks against the marked target also apply 2 Defense Level Down stacks (1s internal CD). Additionally, when the mark's Rupture triggers (burst damage), apply 3 Fragile stacks to them — exposing the wounds you've opened.
- **B: Patient Hunter** — While your marked target has 10+ Rupture stacks, your attacks against them deal 25% more damage. While they have 20+ stacks, your attacks also deal bonus BLACK damage equal to 15% of your weapon's base force. The longer you observe, the more devastating your strikes.

**T3 (3pt) — Pick one:**
- **A: Dossier Complete** *(Powerful Attack, 90s CD)* — Can only target your marked target. Requires: target has 10+ Rupture stacks. Dash to target from up to 6 tiles, 4-hit combo (BLACK DPS). All Rupture stacks on the target are consumed before the combo; total damage is multiplied by `1 + (consumed_stacks * 2 / 100)` (20 stacks = +40%, 40 stacks = +80%). Per-hit: applies 2 Offense Level Down. Final hit: knockback 2 tiles + 5 Fragile stacks. The investigation is complete — sentence is carried out.
- **B: Surveillance Network** *(Passive)* — Gain a secondary mark slot (can mark 2 targets simultaneously). When one marked target takes Rupture trigger damage, the other marked target also takes 50% of that Rupture burst's BRUTE damage as BLACK damage (range: 15 tiles between marks). Killing a marked target immediately grants 5 Rupture stacks to your other mark. Your web of surveillance connects your targets.

**Dossier Complete — Details:**
- **Opener:** Dash to marked target from up to 6 tiles (same dash pattern as tiantui). Target must be marked and have 10+ Rupture stacks.
- **Combo:** 4 hits. Precise, clinical strikes.
- **Pre-combo:** Read and consume all Rupture stacks on target. Calculate damage multiplier: `1 + (consumed_stacks * 2 / 100)`.
- **Per-hit effect:** Each hit applies 2 Offense Level Down stacks. Damage per hit = `DPS * multiplier / 4`.
- **Final hit:** Deals 2x base hit damage, knockback 2 tiles, applies 5 Fragile stacks.
- **Condition:** More Rupture stacks = more damage. At 40 stacks (achievable with focused Case File attacking), the combo gets +80% total damage.

**Implementation Notes:**
- Case File: `COMSIG_MOB_ITEM_ATTACK` → check if `target == marked_target` → `target.apply_lc_rupture(2)` + get rupture stacks → `bonus_black_damage = min(40, stacks) * 0.01 * weapon.force`. No rupture or bonus on non-marks.
- Profiling: `COMSIG_MOB_ITEM_ATTACK` → if `target == marked_target` → `human_parent.apply_lc_offense_level_up(2)`. Track `stacks_granted` (cap at 10). On mark change or `COMSIG_MOB_DEATH` of mark → `human_parent.apply_lc_offense_level_up(-stacks_granted)` to remove.
- Exploit Weakness: `COMSIG_MOB_ITEM_ATTACK` → if `target == marked_target` + CD clear → `target.apply_lc_defense_level_down(2)`. Register `COMSIG_MOB_AFTER_APPLY_DAMGE` on marked target → detect rupture-source damage (`ATTACK_TYPE_STATUS`) → `target.apply_lc_fragile(3)`.
- Patient Hunter: `COMSIG_MOB_ITEM_ATTACK` → check marked_target rupture stacks → if >= 10: `extra_damage += 25` → if >= 20: `extra_damage_black += 15`. Clean up via `COMSIG_MOB_ITEM_AFTERATTACK`.
- Dossier Complete: `/datum/action/cooldown/dossier_complete` → toggle targeting → `InterceptClickOn` checks `target == marked_target` and rupture >= 10. Read + clear rupture stacks. Apply duel component + immobilize. 4 hits with `sleep()`, damage = `DPS * (1 + stacks * 2 / 100) / 4`. Per-hit: `target.apply_lc_offense_level_down(2)`. Final hit: 2x, knockback, fragile.
- Surveillance Network: Extend mark to `marked_target_secondary`. Hook `COMSIG_MOB_AFTER_APPLY_DAMGE` on both marks → detect rupture BRUTE (`ATTACK_TYPE_STATUS`) → deal 50% as BLACK to other mark if in 15 tiles. `COMSIG_MOB_DEATH` on marks → `other_mark.apply_lc_rupture(5)`.

---

#### Branch 2: Coordinator (Debuff Support)

**Theme:** The handler who knows every enemy's weak point and shares that intel with the team. AoE vulnerability debuffs, ally-benefiting effects. Seven doesn't always need to swing the blade themselves — sometimes the most effective retribution comes from telling your allies exactly where to hit.

**T1 (1pt) — Pick one:**
- **A: Intel Briefing** — When you hit a target that has Rupture, all designated allies within 5 tiles gain 3 Offense Level Up stacks. 1s internal CD. Your briefings empower the team to capitalize on your findings.
- **B: Weak Point Analysis** — Your attacks apply 3 Defense Level Down stacks to the target (1s internal CD). When you hit a target that has 10+ Defense Level Down stacks, designated allies within 5 tiles gain 3 Offense Level Up stacks. 1s internal CD. Your analysis exposes openings for the team.

**T2 (2pt) — Pick one:**
- **A: Comprehensive Report** — When you hit a target that has 10+ Rupture stacks, apply 3 Fragile stacks and 2 Defense Level Down stacks to them. 10s internal CD per target. A brief visual highlight marks the chosen target. Your detailed reports crack open the most-investigated subjects.
- **B: Disinformation** — Your attacks apply 2 Offense Level Down stacks and 2 Feeble stacks to the target (1.5s internal CD). Your misinformation undermines the enemy's confidence and cripples their ability to fight.

**T3 (3pt) — Pick one:**
- **A: Full Exposure** *(Powerful Attack, 120s CD)* — AoE debuff slam in a 4-tile radius centered on self. All enemies hit receive 5 Fragile + 3 Defense Level Down + 3 Offense Level Down + 3 Feeble. Then, the closest enemy becomes the main target for a 3-hit combo (BLACK DPS). Per-hit: applies 3 Rupture stacks. For each designated ally within 6 tiles at combo start, all debuff stacks applied by this attack are increased by 1 (up to +3 with 3 allies). Final hit: force-triggers all existing Rupture on the target immediately (bypasses 5s activation delay). You've exposed everything — the enemy has nowhere to hide.
- **B: Undermining Presence** *(Passive)* — When you hit an enemy that has Defense Level Up or Offense Level Up, strip 2 stacks of each. Additionally, designated allies within 5 tiles who attack targets affected by any debuff (Rupture, Fragile, Feeble, DLD, OLD) heal for 3% of damage dealt. Your strikes erode enemy strength.

**Full Exposure — Details:**
- **Opener:** AoE ground slam centered on user, 4-tile radius. All enemies in range receive 5 Fragile + 3 DLD + 3 OLD + 3 Feeble. Closest enemy hit becomes the main target.
- **Combo:** 3 hits. Each hit deals standard DPS as BLACK damage.
- **Per-hit effect:** Each hit applies 3 Rupture stacks to the main target.
- **Condition:** Count designated allies within 6 tiles at combo start. For each ally (up to 3), all debuff stacks from this attack increase by 1 (e.g., with 2 allies: 7 Fragile + 5 DLD + 5 OLD + 5 Feeble opener, 5 Rupture per hit).
- **Final hit:** Force-triggers all Rupture on target via `INVOKE_ASYNC` calling the rupture status effect's `trigger_rupture()` proc directly. Bypasses the 5-second activation delay.

**Implementation Notes:**
- Intel Briefing: `COMSIG_MOB_ITEM_ATTACK` → check target for Rupture status effect → if present and 1s CD clear → iterate designated allies in `range(5, owner)` → `ally.apply_lc_offense_level_up(3)`. Track `last_briefing = world.time`.
- Weak Point Analysis: `COMSIG_MOB_ITEM_ATTACK` → `target.apply_lc_defense_level_down(3)` with 1s CD. Check target DLD stacks >= 10 → iterate designated allies in `range(5, owner)` → `ally.apply_lc_offense_level_up(3)`. Same 1s CD shared with the DLD application.
- Comprehensive Report: `COMSIG_MOB_ITEM_ATTACK` → check target rupture stacks >= 10 → check `target_cooldowns[target_ref]` for 10s CD → `target.apply_lc_fragile(3)` + `target.apply_lc_defense_level_down(2)`. Brief highlight via `new /obj/effect/temp_visual/` on target turf. Track `target_cooldowns[target_ref] = world.time`.
- Disinformation: `COMSIG_MOB_ITEM_ATTACK` → `target.apply_lc_offense_level_down(2)` + `target.apply_lc_feeble(2)` with 1.5s CD.
- Full Exposure: `/datum/action/cooldown/full_exposure` → no targeting needed (AoE from self). AoE debuffs in `range(4)`: `apply_lc_fragile(5)` + `apply_lc_defense_level_down(3)` + `apply_lc_offense_level_down(3)` + `apply_lc_feeble(3)`. Count allies via `is_designated_ally()` in `range(6)`. Pick closest hostile → duel component + immobilize → 3 hits. Final hit: find rupture status effect on target → `INVOKE_ASYNC(rupture_effect, PROC_REF(trigger_rupture))`.
- Undermining Presence: `COMSIG_MOB_ITEM_ATTACK` → check target for DLU/OLU status effects → if present, `add_stacks(-2)` on each. For ally healing: register `COMSIG_MOB_ITEM_ATTACK` on designated allies (via ally designation callback, same as Intel Briefing) → check `get_dist(owner, ally) <= 5` → check target for any debuffs (Rupture/Fragile/Feeble/DLD/OLD) → `INVOKE_ASYNC` → `ally.adjustBruteLoss(-damage * 0.03)`.

---

#### Branch 3: Operative (Rupture Specialist)

**Theme:** The Rupture expert. Every skill in this branch builds, amplifies, or detonates Rupture stacks. While the Analyst marks a single target and the Coordinator debuffs the field, the Operative stacks Rupture fast and triggers it hard. The branch rewards aggressive attacking with escalating Rupture payoffs.

**T1 (1pt) — Pick one:**
- **A: Shadow Step** — Your attacks apply Rupture stacks equal to the target's combined Offense Level Down and Defense Level Down stacks divided by 2 (max 8 Rupture per hit). The more exposed the target, the deeper your strikes cut.
- **B: Quick Assessment** — Hitting a new target (different from last hit) applies 5 Rupture stacks. Consecutive hits on the same target apply diminishing Rupture: 5 → 3 → 1 → 0. Switching targets resets the count. First impressions hit hardest.

**T2 (2pt) — Pick one:**
- **A: Rupture Cascade** — When your attack triggers a target's Rupture burst, apply 5 Rupture stacks to all other enemies within 3 tiles of the target. 5s internal CD. Your interrogations have a way of making everyone nearby nervous.
- **B: Pressure Points** — Your attacks apply 1 additional Rupture stack for each unique debuff type on the target (Fragile, Feeble, DLD, OLD — max +4 Rupture per hit). The more compromised the target, the faster the case builds.

**T3 (3pt) — Pick one:**
- **A: Surgical Strike** *(Powerful Attack, 90s CD)* — Requires: target has at least one of Rupture, Fragile, Feeble, Defense Level Down, or Offense Level Down. Vanish (invisibility for 2 seconds). If the target is still within 7 tiles and in line of sight after the 2 seconds, teleport behind them and deliver a 5-hit combo (BLACK DPS). If line of sight is lost, the attack is cancelled (cooldown is refunded). For each unique debuff type on the target, each hit deals 15% more damage (max +75% with all five debuffs). Per-hit: apply 2 Rupture stacks. First hit: apply 3 Fragile. Final hit: 2x DPS, knockback 2 tiles, final hit deals bonus BLACK damage equal to the target's current Rupture stacks. The investigation's findings dictate the severity of the sentence.
- **B: Detonation Order** *(Passive)* — Your attacks apply 4 Rupture stacks to the target, as long as the target has less than 20 Rupture stacks. Ensures every target you touch reaches critical mass.

**Surgical Strike — Details:**
- **Opener:** Vanish (`alpha = 0`, immobilize self, 2 seconds). After 2 seconds, check target is within 7 tiles and in LoS (`can_see(owner, target)`). If valid: teleport behind target (`get_step(target, REVERSE_DIR(target.dir))`), begin combo. If invalid: cancel, refund cooldown.
- **Combo:** 5 hits. Fast, precise strikes exploiting every identified weakness.
- **Per-hit effect:** Each hit applies 2 Rupture stacks. First hit applies 3 Fragile.
- **Condition:** Count unique debuff types on target (Rupture, Fragile, Feeble, DLD, OLD). Per debuff: +15% damage to all hits. With all 5 debuffs active: +75% total damage. This rewards setting up debuffs before the finisher.
- **Final hit:** Apply zoro overlay on target (`target.add_overlay(icon('icons/effects/effects.dmi', "zoro"))`), brief delay, remove overlay (`target.cut_overlay(...)`), then deal 2x DPS + bonus BLACK damage equal to the target's current Rupture stacks, knockback 2 tiles. Same slash visual pattern as `puss_in_boots.dm`'s `Execute()`.

**Implementation Notes:**
- Shadow Step: `COMSIG_MOB_ITEM_ATTACK` → get target's OLD stacks + DLD stacks → `rupture_amount = min(8, round((old_stacks + dld_stacks) / 2))` → if > 0: `target.apply_lc_rupture(rupture_amount)`.
- Quick Assessment: Track `last_attacked_target` and `consecutive_hits`. On `COMSIG_MOB_ITEM_ATTACK`: if different target → reset `consecutive_hits = 0`. Apply rupture based on `consecutive_hits`: 0 → 5, 1 → 3, 2 → 1, 3+ → 0. Then `consecutive_hits++`. Update `last_attacked_target`.
- Rupture Cascade: Register `COMSIG_MOB_AFTER_APPLY_DAMGE` on owner → detect rupture-source burst damage (`ATTACK_TYPE_STATUS`) → if 5s CD clear → iterate enemies in `range(3, target)` excluding target → `enemy.apply_lc_rupture(5)`.
- Pressure Points: `COMSIG_MOB_ITEM_ATTACK` → count unique debuff types on target (Fragile, Feeble, DLD, OLD — not Rupture itself) → `target.apply_lc_rupture(count)` if count > 0.
- Surgical Strike: `/datum/action/cooldown/surgical_strike` → toggle targeting → check any debuff on target. `alpha = 0` + immobilize owner for 2s via `addtimer`. After 2s: check `can_see(owner, target)` and `get_dist(owner, target) <= 7` → if fail: `alpha = 255`, unimmobilize, refund CD, return. If pass: `forceMove(get_step(target, REVERSE_DIR(target.dir)))`, `alpha = 255`, duel component → immobilize target. Count debuff types for multiplier. 5 hits. Final hit: `target.add_overlay(icon('icons/effects/effects.dmi', "zoro"))` → `SLEEP_CHECK_DEATH(14)` → `target.cut_overlay(...)` → deal 2x DPS + `target_rupture_stacks` as bonus BLACK damage, knockback 2 tiles. (Zoro slash overlay pattern from `puss_in_boots.dm` Execute).
- Detonation Order: `COMSIG_MOB_ITEM_ATTACK` → check target rupture stacks < 20 → `target.apply_lc_rupture(4)`.

---

#### Seven Branch Synergies

The 2-branch limit creates natural playstyle combos:

| Combo | Playstyle | Strength |
|---|---|---|
| **Analyst + Coordinator** | "The Mastermind" — Mark a target, build rupture personally while exposing them to the whole team's attacks via Intel Briefing. Dossier Complete for solo execution, Full Exposure for team fights. | Best for mixed solo/team play. Maximum debuff stacking on a single priority target. |
| **Analyst + Operative** | "The Assassin" — Mark a target, stack Rupture fast via Case File + Quick Assessment, then detonate with Detonation Order or finish with Surgical Strike. Pure single-target Rupture execution. | Highest Rupture burst on one enemy. The quintessential Seven hitman. |
| **Coordinator + Operative** | "The Saboteur" — Debuff with DLD/OLD via Coordinator, then convert those debuffs into Rupture via Shadow Step. Rupture Cascade spreads stacks across groups. Surgical Strike finishes what the debuffs started. | Best for group fights. Coordinator debuffs feed Operative's Rupture engine. |

---

**Seven Design Notes:**
- Most skills use **Rupture** stacks as the core mechanic, with Fragile/DLD/OLD as supporting debuffs
- **Rupture's 5-second activation delay** mechanically enforces the "don't rush into combat" lore — Seven must plan their attacks, not spam them
- The **Analyst Mark** is independent from the weapon's hit-to-store mechanic — both coexist and can be used on different targets
- **T3 Powerful Attacks** follow the tiantui flurry pattern (`thumb.dm`): cutscene combo with immobilize, multi-hit DPS-based damage, duel component, conditional bonuses
- All Seven powerful attacks deal **BLACK damage** (matching their weapon damage type)
- Each hit deals weapon DPS (`force * force_multiplier * 1.25 / attack_speed`) so all weapons are equally viable
- Skills **only function while on an active contract** — no contract = no abilities
- The pointed spell pattern from `thin_line.dm` is used for the Mark Target targeting
- Ghost Protocol's lethal-save uses `COMSIG_MOB_APPLY_DAMGE` + `COMPONENT_MOB_DENY_DAMAGE` + `INVOKE_ASYNC`
- Investigation tools only work on `/mob/living/carbon` targets (players with inventories who can speak)
- Intel Report validation uses `findtext()` fuzzy matching (case-insensitive, partial match)
- Old skills for reference: Analysis (HUD), Third Eye (x-ray), Quick Getaway (speed+smoke), Weakness Analyzed (1.4x black vuln), Field Command (toggle ally buff), Exploit the Gap (speed + vuln debuff)

---

### Dieci (NEW) - "The Scholar"

**Theme:** Knowledge collection and charity. The Dieci Association specializes in gathering knowledge through helping others — healing the injured, training civilians, hosting community events. They store this knowledge in a sacred tome, then convert it into raw combat power. But knowledge is consumed when used for strength and must be regained through further study and service. To the public, they are the "Association of Charity." To themselves, charity is the method — knowledge is the goal.

Dieci fixers fall into two categories: **Fists** (fight directly using enhanced physical strength) and **Keys** (use specially enlarged keys as weapons). Both draw power from the same knowledge reserves via their golden stoles. The distinction defines their combat branches, not their knowledge-gathering methods.

**Core Mechanic: Knowledge Tome & Active Knowledge**

The Dieci's unique item is the **Knowledge Tome** — a sacred book given on contract start. It serves as their EXP interface, event launcher, knowledge storage, and combat fuel source.

**Active Knowledge** is the Dieci's combat resource. Each time the Dieci performs an Individual Charity activity, they gain an **Active Knowledge entry** — a short piece of information about what they learned, with flavor text:

- **From healing:** `"[target]'s wounds were [deep lacerations across their forearm / severe chemical burns along their chest / ...]"`
- **From blessed food:** `"[target]'s reaction to the food was [a moment of quiet relief / a grateful sigh of contentment / ...]"`
- **From examining:** `"[target] exhibited [unusual bone structure suggesting rapid growth / signs of prolonged exposure to enkephalin / ...]"`
- **From events:** Each completed event tick generates 1 Active Knowledge entry: `"The attendees responded to the [reading/training/sermon] with [rapt attention / visible improvement / ...]"`

**The Knowledge Loop:**

1. **Gain Active Knowledge** — Perform charity activities. Each generates an Active Knowledge entry (viewable via a Dieci action that lists all current entries with their flavor text).
2. **Record into Tome** — Use the Tome in hand → `do_after` channel → all current Active Knowledge entries are **written into the Tome** as stored knowledge. Active Knowledge is cleared. The Tome now holds these entries.
3. **Consume in combat** — Dieci combat skills and weapon buffs **consume Active Knowledge entries** to power up. Each skill costs X entries. When Active Knowledge is empty, combat skills stop functioning.
4. **Re-read the Tome** — Use the Tome in hand → `do_after` channel → **restore Active Knowledge** from stored entries in the Tome. The Dieci re-reads their notes and regains their combat fuel.
5. **Cycle repeats** — Re-reading restores old knowledge, but doing more charity generates **new** entries (and EXP). The Tome can only restore what was previously recorded.

**Key rules:**
- **Max Active Knowledge entries:** 20 (can be increased by skill tree)
- **Recording** transfers Active → Stored (Active is cleared, Stored gains entries)
- **Re-reading** transfers Stored → Active (Stored is cleared, Active gains entries). 3-second `do_after` channel.
- **Recording** also requires a 3-second `do_after` channel
- Active Knowledge entries from charity activities are generated **in addition to** EXP — doing charity gives both EXP (permanent) and Active Knowledge (consumable)
- **EXP** is still earned separately and used for skill tree progression, event costs, etc.

Creates the loop: **do charity → gain Active Knowledge + EXP → record into Tome → consume knowledge in combat → re-read Tome to restore → eventually run out of stored knowledge → do more charity**

---

### EXP Sources — Individual Charity

Dieci earns EXP and **Active Knowledge entries** through acts of service and study. Some activities are free, others require purchasing items from the Tome's shop. Each charity activity grants both EXP (permanent) and 1 Active Knowledge entry (consumable combat fuel).

| Activity | EXP | Active Knowledge | Type | Notes |
|---|---|---|---|---|
| Examine living mob type | 1 EXP | +1 entry | Anatomical | Use Tome on mob, first time only per type |
| Examine dead body | 3 / 5 EXP | +1 entry | Anatomical | 5s do_after. 3 EXP if NPC, 5 EXP if player (has ckey). Once per body until revived. |
| Observe combat | 1 EXP | +1 entry (chance) | Behavioral | Watch a carbon fight — 20% chance per attack/damage event on observed target |
| Healing Kit use | 2/3/5 EXP | +1 entry | Medical | 3 tiers: Basic (50 ahn, 20 uses), Standard (100, 40), Advanced (200, 80) |
| Blessed Food consumed | 2 EXP | +1 entry | Spiritual | Additive applied to food, EXP on eat (must see eater) |
| Event tick completed | varies | +1 entry | Spiritual | From hosting public events |
| Passive contract tick | 1 EXP / 10s | — | — | No Active Knowledge |
| Contract completion | 10-30 EXP | — | — | No Active Knowledge |

#### Knowledge Types & Levels

Active Knowledge entries come in **4 types**, each tied to different skill branches and activities:

| Type | Source Activities | Flavor |
|---|---|---|
| **Anatomical** | Examining mobs (living or dead) | Physical structure, biology, weaknesses |
| **Behavioral** | Observing combat | Fighting patterns, reactions, tendencies |
| **Medical** | Healing Kit use | Wound treatment, recovery, physiology |
| **Spiritual** | Sacred Seasoning, Events | Emotional responses, morale, faith |

Each entry also has a **level** (1-5) based on the source or synthesis:

| Level | How to Obtain | Description |
|---|---|---|
| **Level 1** | Examine living mob, Observe combat, Healing Kit (Basic), Sacred Seasoning, Events | Common knowledge |
| **Level 2** | Examine dead NPC body, Healing Kit (Standard), or synthesize 3x Level 1 | Detailed knowledge |
| **Level 3** | Examine dead player body (has ckey), Healing Kit (Advanced), or synthesize 3x Level 2 | Rare knowledge |
| **Level 4** | Synthesize 3x Level 3 | Exceptional knowledge |
| **Level 5** | Synthesize 3x Level 4 | Masterwork knowledge |

**Knowledge Synthesis:**

Combine **3 Active Knowledge entries of the same type and level** to create **1 entry of the next level** (same type). Performed via the Tome's TGUI — select the type and level to synthesize, consumes 3 entries, produces 1 higher-level entry.

- 3x Level 1 Anatomical → 1x Level 2 Anatomical
- 3x Level 2 Medical → 1x Level 3 Medical
- 3x Level 4 Spiritual → 1x Level 5 Spiritual
- Level 5 is the maximum — cannot be synthesized further
- Types must match — cannot combine Anatomical + Medical
- Synthesis is instant (no `do_after`) but can only be done through the Tome's TGUI

**Reaching high levels:** Level 4 requires 9x Level 1 entries (3→1→3→1). Level 5 requires 27x Level 1 entries. This makes Level 5 knowledge extremely valuable and time-consuming to produce.

**How types and levels matter for combat:**
- Different skill branches prefer different knowledge types — one branch might consume Anatomical knowledge for bonus damage, while another consumes Spiritual knowledge for defensive buffs
- Higher-level knowledge gives **stronger effects** when consumed (e.g., consuming a Level 3 entry gives 3x the buff of a Level 1, Level 5 gives 5x)
- Skills specify which types they accept and the minimum level — versatile skills accept any type, specialized skills require specific types for full effect
- This encourages varied charity work rather than spamming one activity
- The synthesis system rewards stockpiling lower-level knowledge and converting it upward for powerful combat bursts

---

#### Dieci Charity Items (Purchased from Tome Shop)

The Tome's TGUI has a **shop tab** (same pattern as Seven's Requisition Catalog) where the Dieci can buy charity items using ahn from their ID card bank account.

**1. Healing Kits** (`/obj/item/dieci_healing_kit`) — Multiple variants

Medical kits marked with the Dieci's golden stole emblem. Used to heal others in a hands-on, deliberate process. Each use heals 10 brute + 10 burn. Three tiers available:

| Variant | Cost | Uses | EXP per Heal | Total Healing |
|---|---|---|---|---|
| **Basic Healing Kit** | 50 ahn | 20 | 2 EXP | 200 brute + 200 burn |
| **Standard Healing Kit** | 100 ahn | 40 | 3 EXP | 400 brute + 400 burn |
| **Advanced Healing Kit** | 200 ahn | 80 | 5 EXP | 800 brute + 800 burn |

Higher tiers last longer and award more EXP per heal (Basic = 2, Standard = 3, Advanced = 5).

**Mechanic:**
1. Dieci attacks a `/mob/living/carbon` with the kit (click on target)
2. If target is not the user and target has brute or burn damage → begin a **3-second `do_after`** channel
3. On success: heal 10 brute + 10 burn on the target → visible message: `"[user] carefully tends to [target]'s wounds with practiced hands."` → award **3 EXP** → consume 1 use
4. After healing, **immediately start another 3-second `do_after`** for the next heal cycle (the Dieci can keep healing the same target in a chain)
5. Chain breaks if: Dieci moves, target moves, target is fully healed, Dieci is interrupted, or kit runs out of uses
6. When uses reach 0 → `qdel(src)`, visible message: `"The healing kit crumbles, its supplies spent."`

**Implementation:**
```dm
/obj/item/dieci_healing_kit
	name = "basic Dieci healing kit"
	desc = "A small medical kit bearing the golden emblem of the Dieci Association."
	icon_state = "dieci_healkit"
	var/uses = 20
	var/max_uses = 20
	var/heal_amount = 10
	var/exp_per_heal = 2
	/// Weakref to the Dieci who purchased this kit (for EXP tracking)
	var/datum/weakref/owner_ref

/obj/item/dieci_healing_kit/standard
	name = "standard Dieci healing kit"
	uses = 40
	max_uses = 40
	exp_per_heal = 3

/obj/item/dieci_healing_kit/advanced
	name = "advanced Dieci healing kit"
	uses = 80
	max_uses = 80
	exp_per_heal = 5

/obj/item/dieci_healing_kit/attack(mob/living/carbon/target, mob/living/user)
	if(target == user)
		to_chat(user, span_warning("You can only use this on others."))
		return
	if(!target.getBruteLoss() && !target.getFireLoss())
		to_chat(user, span_notice("[target] has no wounds to treat."))
		return
	start_heal_chain(target, user)

/obj/item/dieci_healing_kit/proc/start_heal_chain(mob/living/carbon/target, mob/living/user)
	if(!do_after(user, 3 SECONDS, target))
		return
	if(QDELETED(src) || QDELETED(target) || uses <= 0)
		return
	// Heal
	target.adjustBruteLoss(-heal_amount)
	target.adjustFireLoss(-heal_amount)
	user.visible_message(span_notice("[user] carefully tends to [target]'s wounds with practiced hands."))
	// Award EXP
	var/mob/living/owner = owner_ref?.resolve()
	if(owner)
		var/datum/component/association_exp/exp = owner.GetComponent(/datum/component/association_exp)
		exp?.modify_exp(exp_per_heal)
	// Consume use
	uses--
	if(uses <= 0)
		to_chat(user, span_notice("The healing kit crumbles, its supplies spent."))
		qdel(src)
		return
	// Continue chain if target still has damage
	if(target.getBruteLoss() || target.getFireLoss())
		start_heal_chain(target, user)
```

**2. Sacred Seasoning** (`/obj/item/dieci_sacred_seasoning`) — 50 ahn, 3 uses

A small vial of blessed spice. When applied to food, it imbues the food with restorative properties. Anyone who eats the blessed food heals SP, and the Dieci who applied it earns EXP.

**Mechanic:**
1. Dieci uses the Sacred Seasoning on a `/obj/item/food` (click seasoning on food item)
2. The food gains a `dieci_blessing` component that stores a weakref to the Dieci owner
3. Visible message: `"[user] sprinkles sacred seasoning over [food], blessing it with restorative properties."`
4. Consume 1 use of the seasoning. When uses reach 0 → `qdel(src)`
5. When anyone eats the blessed food: heal **15 SP** (`adjustSanityLoss(-15)`) → visible message: `"You feel a wave of calm wash over you as you eat the blessed food."` → award **2 EXP** to the Dieci **only if the Dieci can see the eater** (`dieci.can_see(eater)`). The Dieci must witness the act of charity to gain knowledge from it.

**Implementation:**
```dm
/obj/item/dieci_sacred_seasoning
	name = "sacred seasoning"
	desc = "A vial of blessed spice from the Dieci Association. Apply to food to imbue it with restorative properties."
	icon_state = "dieci_seasoning"
	var/uses = 3
	var/datum/weakref/owner_ref

/obj/item/dieci_sacred_seasoning/afterattack(obj/item/food/target, mob/living/user, proximity_flag)
	. = ..()
	if(!proximity_flag || !istype(target))
		return
	if(uses <= 0)
		return
	target.AddComponent(/datum/component/dieci_blessing, owner_ref)
	user.visible_message(span_notice("[user] sprinkles sacred seasoning over [target], blessing it with restorative properties."))
	uses--
	if(uses <= 0)
		to_chat(user, span_notice("The seasoning vial is empty."))
		qdel(src)

/// Component added to blessed food
/datum/component/dieci_blessing
	var/datum/weakref/dieci_ref

/datum/component/dieci_blessing/Initialize(datum/weakref/owner)
	dieci_ref = owner
	RegisterSignal(parent, COMSIG_FOOD_EATEN, PROC_REF(on_eaten))

/datum/component/dieci_blessing/proc/on_eaten(datum/source, mob/living/eater, mob/living/feeder)
	SIGNAL_HANDLER
	// Heal SP
	INVOKE_ASYNC(src, PROC_REF(apply_blessing), eater)

/datum/component/dieci_blessing/proc/apply_blessing(mob/living/eater)
	eater.adjustSanityLoss(-15)
	to_chat(eater, span_notice("You feel a wave of calm wash over you as you eat the blessed food."))
	// Award EXP to the Dieci — only if they can see the eater
	var/mob/living/dieci = dieci_ref?.resolve()
	if(dieci && dieci.can_see(eater))
		var/datum/component/association_exp/exp = dieci.GetComponent(/datum/component/association_exp)
		exp?.modify_exp(2)
```

**3. Examine Living Mob (Bestiary Scan)** — Free, uses the Tome directly:

The Tome has a built-in **Bestiary** — a combat_log_book-style database that stores detailed information about scanned creatures. When the Dieci clicks a `/mob/living/simple_animal/hostile` with the Tome in hand, they scan it and add its full combat data to the Tome's bestiary. This follows the same pattern as `combat_log_book.dm`.

**Scanning behavior:**
- Click any `/mob/living/simple_animal/hostile` with the Tome via `afterattack()` — no `do_after`, instant scan
- If the mob's `type` is already in the bestiary → `"This type of [name] is already in your tome."` (no EXP, no duplicate)
- If new type → extract full creature data, add to bestiary, award **1 EXP**, generate 1 **Anatomical** Active Knowledge entry whose **level depends on the mob's max HP**:

| Max HP | Knowledge Level |
|---|---|
| 1 – 399 | Level 1 |
| 400 – 799 | Level 2 |
| 800 – 1199 | Level 3 |
| 1200 – 1599 | Level 4 |
| 1600+ | Level 5 |
- Visible message: `"[user] studies [target] carefully, recording observations in their tome."`
- Sound: `'sound/machines/terminal_prompt_confirm.ogg'`

**Data extracted per mob (same fields as combat_log_book.dm):**

| Field | Source | Notes |
|---|---|---|
| `type` | `H.type` | Used for duplicate checking |
| `name` | `H.name` | Display name |
| `icon` | `icon2base64(getFlatIcon(H))` | Base64 icon for TGUI display |
| `health` / `max_health` | `H.health` / `H.maxHealth` | Current and max HP |
| `move_to_delay` | `H.move_to_delay` | Movement speed |
| `resistances` | `H.damage_coeff` → `DC.red`, `DC.white`, `DC.black`, `DC.pale` | Damage type multipliers (or "?" if null) |
| `melee_damage_lower/upper` | `H.melee_damage_lower/upper` | Melee damage range |
| `melee_damage_type` | `H.melee_damage_type` | RED/WHITE/BLACK/PALE |
| `rapid_melee` / `attack_cooldown` | `H.rapid_melee` / `H.attack_cooldown` | Attack speed info |
| `is_ranged` | Check `H.casingtype` or `H.projectiletype` | Whether mob has ranged attacks |
| `ranged_damage` / `ranged_damage_type` | From instantiated projectile | Ranged damage info (if applicable) |
| `ranged_cooldown_time` | `H.ranged_cooldown_time` | Ranged fire rate |
| `rapid` / `rapid_fire_delay` | `H.rapid` / `H.rapid_fire_delay` | Burst fire info (if applicable) |
| `notes` | `""` (user-editable) | Player can add personal notes |

**TGUI — "DieciTomeBestiary" interface:**

Follows the same layout as `CombatLogBook.js` with page navigation:
- **Header:** Creature icon (base64) + name
- **Vital Statistics:** Health, movement speed, melee damage/speed, ranged info (if applicable)
- **Damage Resistances:** Red/White/Black/Pale with color-coded labels (Resistant/Normal/Weak/Vulnerable/Fatal)
- **Field Notes:** Editable `TextArea` for user notes (saved via `"update_notes"` action)
- **Navigation:** Previous/Next page buttons, page counter `"Page X of Y"`
- **Empty state:** `"No creatures scanned yet. Use the tome on hostile creatures to study them."`

**TGUI Actions:** `"next_page"`, `"prev_page"`, `"update_notes"` — identical to CombatLogBook

The bestiary is accessed via the Tome's `attack_self()` when it contains scanned creatures, or via a dedicated "View Bestiary" button in the Tome's main TGUI.

```dm
/obj/item/dieci_tome
	/// Bestiary database — list of assoc lists, one per scanned mob type
	var/list/bestiary_database = list()
	/// Current bestiary page for TGUI navigation
	var/bestiary_page = 1

/obj/item/dieci_tome/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!istype(target, /mob/living/simple_animal/hostile))
		return
	if(!proximity_flag)
		return

	var/mob/living/simple_animal/hostile/H = target

	// Check if this type is already scanned
	var/mob_type = H.type
	for(var/list/entry in bestiary_database)
		if(entry["type"] == mob_type)
			to_chat(user, span_notice("This type of [H.name] is already in your tome."))
			return

	// Extract creature data — same pattern as combat_log_book.dm
	var/list/creature_data = list()
	creature_data["type"] = H.type
	creature_data["name"] = H.name
	creature_data["icon"] = icon2base64(getFlatIcon(H))
	creature_data["notes"] = ""

	// Health
	creature_data["health"] = H.health
	creature_data["max_health"] = H.maxHealth

	// Movement speed
	creature_data["move_to_delay"] = H.move_to_delay

	// Resistances (damage coefficients)
	var/list/resistances = list()
	if(H.damage_coeff)
		var/datum/dam_coeff/DC = H.damage_coeff
		resistances["red"] = DC.red
		resistances["white"] = DC.white
		resistances["black"] = DC.black
		resistances["pale"] = DC.pale
	else
		resistances["red"] = "?"
		resistances["white"] = "?"
		resistances["black"] = "?"
		resistances["pale"] = "?"

	// Melee damage
	creature_data["melee_damage_lower"] = H.melee_damage_lower
	creature_data["melee_damage_upper"] = H.melee_damage_upper
	creature_data["melee_damage_type"] = H.melee_damage_type

	// Melee attack speed
	if(H.rapid_melee > 1)
		creature_data["rapid_melee"] = H.rapid_melee
	else if(H.attack_cooldown > 0)
		creature_data["attack_cooldown"] = H.attack_cooldown
	else
		creature_data["rapid_melee"] = 1

	// Ranged info — check casingtype first, then projectiletype
	if(H.casingtype)
		var/obj/item/ammo_casing/casing = new H.casingtype
		if(casing.projectile_type)
			var/obj/projectile/P = new casing.projectile_type
			creature_data["ranged_damage"] = P.damage
			creature_data["ranged_damage_type"] = P.damage_type
			qdel(P)
		qdel(casing)
		creature_data["is_ranged"] = TRUE
		creature_data["ranged_cooldown_time"] = H.ranged_cooldown_time
		if(H.rapid > 0)
			creature_data["rapid"] = H.rapid
			creature_data["rapid_fire_delay"] = H.rapid_fire_delay
	else if(H.projectiletype)
		var/obj/projectile/P = new H.projectiletype
		creature_data["ranged_damage"] = P.damage
		creature_data["ranged_damage_type"] = P.damage_type
		qdel(P)
		creature_data["is_ranged"] = TRUE
		creature_data["ranged_cooldown_time"] = H.ranged_cooldown_time
		if(H.rapid > 0)
			creature_data["rapid"] = H.rapid
			creature_data["rapid_fire_delay"] = H.rapid_fire_delay
	else
		creature_data["is_ranged"] = FALSE

	creature_data["resistances"] = resistances

	bestiary_database += list(creature_data)
	to_chat(user, span_notice("You study [H.name] and record your observations in your tome."))
	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)

	// Award EXP
	var/datum/component/association_exp/exp = user.GetComponent(/datum/component/association_exp)
	exp?.modify_exp(1)
	// Generate Active Knowledge — level scales with mob max HP (400 HP per tier, cap at 5)
	var/knowledge_level = clamp(round(H.maxHealth / 400) + 1, 1, 5)
	add_active_knowledge("Anatomical", knowledge_level, "[H.name] — [pick("exhibits aggressive territorial behavior", "shows signs of heightened predatory instincts", "possesses unusual anatomical features worth documenting")]")
	user.visible_message(span_notice("[user] studies [target] carefully, recording observations in their tome."))
```

**Bestiary TGUI data/actions** (on the Tome):

```dm
/// Bestiary UI data — returned when viewing the bestiary page
/obj/item/dieci_tome/proc/bestiary_ui_data()
	var/list/data = list()
	data["creatures"] = bestiary_database
	data["current_page"] = bestiary_page
	data["total_pages"] = length(bestiary_database)
	if(length(bestiary_database) > 0 && bestiary_page <= length(bestiary_database))
		data["current_creature"] = bestiary_database[bestiary_page]
	else
		data["current_creature"] = null
	return data

/// Bestiary UI actions — same as CombatLogBook
/obj/item/dieci_tome/proc/bestiary_ui_act(action, params)
	switch(action)
		if("bestiary_next")
			if(bestiary_page < length(bestiary_database))
				bestiary_page++
				return TRUE
		if("bestiary_prev")
			if(bestiary_page > 1)
				bestiary_page--
				return TRUE
		if("bestiary_notes")
			if(length(bestiary_database) > 0 && bestiary_page <= length(bestiary_database))
				bestiary_database[bestiary_page]["notes"] = params["notes"]
				return TRUE
	return FALSE
```

**New TGUI file:** `tgui/packages/tgui/interfaces/DieciTomeBestiary.js` — largely mirrors `CombatLogBook.js` with the same helper functions (`getDamageTypeColor`, `getHealthDescription`, `getResistanceLabel`, etc.) and layout. Can be embedded as a tab/section within the Tome's main TGUI rather than a separate window.

**4. Examine Dead Body** — Free, uses the Tome on a dead `/mob/living/carbon/human`:

Click a dead human body with the Tome → **5-second `do_after`** channel → on success:
- If the body has a `ckey` (player-controlled): award **5 EXP**, generate 1 **Anatomical (Level 3)** Active Knowledge entry. Flavor: `"[target]'s cause of death reveals [detailed text about injuries, organ state, etc.]"`
- If the body has no `ckey` (NPC): award **3 EXP**, generate 1 **Anatomical (Level 2)** Active Knowledge entry. Flavor: `"[target]'s remains show [text about physical structure, abnormalities, etc.]"`
- Mark the body as examined by adding a `dieci_examined` trait: `ADD_TRAIT(target, TRAIT_DIECI_EXAMINED, DIECI_TRAIT)`
- Cannot examine a body that already has `TRAIT_DIECI_EXAMINED`
- The trait is **removed when the body is revived** via `COMSIG_LIVING_REVIVE`: register `RegisterSignal(target, COMSIG_LIVING_REVIVE, PROC_REF(on_revive))` → in handler: `REMOVE_TRAIT(target, TRAIT_DIECI_EXAMINED, DIECI_TRAIT)` + `UnregisterSignal(target, COMSIG_LIVING_REVIVE)`

```dm
/// On the Tome's afterattack when in study mode, targeting a dead human
/obj/item/dieci_tome/proc/examine_dead_body(mob/living/carbon/human/target, mob/living/user)
	if(target.stat != DEAD)
		return
	if(HAS_TRAIT(target, TRAIT_DIECI_EXAMINED))
		to_chat(user, span_notice("You have already studied this body."))
		return
	to_chat(user, span_notice("You begin examining [target]'s body..."))
	if(!do_after(user, 5 SECONDS, target))
		return
	if(QDELETED(target) || target.stat != DEAD || HAS_TRAIT(target, TRAIT_DIECI_EXAMINED))
		return
	ADD_TRAIT(target, TRAIT_DIECI_EXAMINED, DIECI_TRAIT)
	RegisterSignal(target, COMSIG_LIVING_REVIVE, PROC_REF(on_target_revive))
	var/has_ckey = !!target.ckey
	var/exp_amount = has_ckey ? 5 : 3
	var/knowledge_level = has_ckey ? 3 : 2
	// Award EXP
	var/datum/component/association_exp/exp = user.GetComponent(/datum/component/association_exp)
	exp?.modify_exp(exp_amount)
	// Generate Active Knowledge
	var/flavor = has_ckey ? "[target]'s cause of death reveals [pick("severe trauma to the cranium", "multiple lacerations across the torso", "signs of catastrophic organ failure")]" : "[target]'s remains show [pick("unusual bone density", "traces of unknown compounds in the tissue", "evidence of prolonged physical stress")]"
	add_active_knowledge("Anatomical", knowledge_level, flavor)
	user.visible_message(span_notice("[user] carefully examines [target]'s body, recording observations in their tome."))

/obj/item/dieci_tome/proc/on_target_revive(datum/source)
	SIGNAL_HANDLER
	REMOVE_TRAIT(source, TRAIT_DIECI_EXAMINED, DIECI_TRAIT)
	UnregisterSignal(source, COMSIG_LIVING_REVIVE)
```

**5. Observe Combat** — Free action, watch a carbon fight:

The Dieci has an **Observe** action (`/datum/action/cooldown/dieci_observe`) — a pointed spell that targets a `/mob/living/carbon`. While observing:
- Register `COMSIG_MOB_ITEM_ATTACK` on the observed target (they attack someone) and `COMSIG_MOB_AFTER_APPLY_DAMGE` on the observed target (they take damage)
- On each signal fire: if the attacker/damage source is NOT the Dieci → **20% chance** to generate 1 **Behavioral (Level 1)** Active Knowledge entry + award 1 EXP
- Flavor: `"[target] [pick("instinctively guards their left side", "telegraphs strikes with a shoulder drop", "flinches before retaliating")]"`
- Observation ends if: Dieci uses the action again (toggle off), target dies, target moves more than 7 tiles away from Dieci, or Dieci loses line of sight
- The Dieci can only observe **one target at a time**

```dm
/datum/action/cooldown/dieci_observe
	name = "Observe"
	desc = "Begin observing a target's combat behavior to gain knowledge."
	cooldown_time = 5 SECONDS
	var/mob/living/carbon/observed_target
	var/datum/weakref/owner_ref

/datum/action/cooldown/dieci_observe/proc/start_observing(mob/living/carbon/target, mob/living/user)
	if(observed_target)
		stop_observing()
	observed_target = target
	RegisterSignal(target, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_observed_attack))
	RegisterSignal(target, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(on_observed_damaged))
	RegisterSignal(target, COMSIG_LIVING_DEATH, PROC_REF(on_observed_death))
	RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(on_observed_moved))
	to_chat(user, span_notice("You begin observing [target]'s behavior..."))

/datum/action/cooldown/dieci_observe/proc/on_observed_attack(datum/source, mob/living/target, obj/item/weapon)
	SIGNAL_HANDLER
	var/mob/living/user = owner_ref?.resolve()
	if(!user || source == user) // Don't count if Dieci is the one being attacked
		return
	if(prob(20))
		INVOKE_ASYNC(src, PROC_REF(generate_behavioral_knowledge), source, user)

/datum/action/cooldown/dieci_observe/proc/on_observed_damaged(datum/source, damage, damagetype)
	SIGNAL_HANDLER
	var/mob/living/user = owner_ref?.resolve()
	if(!user)
		return
	// Check that the damage source is not the Dieci (attacker info from signal args)
	if(prob(20))
		INVOKE_ASYNC(src, PROC_REF(generate_behavioral_knowledge), source, user)

/datum/action/cooldown/dieci_observe/proc/on_observed_moved(datum/source)
	SIGNAL_HANDLER
	var/mob/living/user = owner_ref?.resolve()
	if(!user || get_dist(user, observed_target) > 7 || !user.can_see(observed_target))
		stop_observing()

/datum/action/cooldown/dieci_observe/proc/stop_observing()
	if(!observed_target)
		return
	UnregisterSignal(observed_target, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_MOB_AFTER_APPLY_DAMGE, COMSIG_LIVING_DEATH, COMSIG_MOVABLE_MOVED))
	observed_target = null
```

**6. Tome & Bookcase Interaction:**

Dieci tomes can be **stored in any `/obj/structure/bookcase`** (uses the existing `isbook()` check — the Tome should pass this by being a subtype of `/obj/item/book` or by adding it to the `isbook()` proc).

Additionally, Dieci can **retrieve a new blank tome** from any bookcase:
- Examine or use the bookcase with an empty hand while having the Dieci association component → option to "Take blank tome" appears
- Creates a new `/obj/item/dieci_tome` with `owner_ref` set to the Dieci
- This allows Dieci to store filled tomes (with stored knowledge) in bookcases for safekeeping and grab fresh ones
- Multiple tomes can exist — but only the one in-hand is used for recording/re-reading
- Stored tomes in bookcases **retain their stored knowledge entries**, so the Dieci can build a personal library over time

**Implementation:** Make `/obj/item/dieci_tome` a subtype of `/obj/item/book` so it naturally works with bookcases. Add an `attackby` override or `attack_hand` extension on `/obj/structure/bookcase` to offer blank tome generation for Dieci fixers.

**Tome Shop Summary:**

| Item | Cost | Uses | Effect | EXP per Use |
|---|---|---|---|---|
| Basic Healing Kit | 50 ahn | 20 | Heal 10 brute + 10 burn per use (3s do_after, chains) | 2 EXP |
| Standard Healing Kit | 100 ahn | 40 | Same as basic, more uses | 3 EXP |
| Advanced Healing Kit | 200 ahn | 80 | Same as basic, most uses | 5 EXP |
| Sacred Seasoning | 50 ahn | 3 | Apply to food → heals 15 SP when eaten | 2 EXP |

---

### EXP Sources — Public Events (Major)

Dieci can use their Tome to **host public events** — extended group activities that benefit attendees and generate large amounts of EXP. Events are the fastest way to earn EXP but require significant time, ahn investment, and active participation.

**How Events Work:**

1. Dieci uses Tome in hand → selects event type from TGUI → ahn cost is deducted from ID card bank account
2. A **visible event zone** (5-tile radius) is created centered on where they activated the Tome
3. A visible announcement goes out: `"[user] is hosting a [Event Name]! Gather around!"`
4. The event consists of **ticks** — periodic check-ins where the Dieci must use their Tome in hand within the zone
5. Each tick: Dieci uses Tome in hand → **5-second `do_after` channel** → on success, Dieci says a line aloud (visible message) → tick completes → attendees receive benefits
6. **The Tome can only be activated within the event zone.** Clicking outside does nothing.
7. **If any tick is missed or the `do_after` is interrupted, the event ends immediately.** No ahn refund.
8. Between ticks, the Dieci is free to **move around the zone, talk, and RP** with attendees
9. Cooldown: **5 minutes** between events

**Event 1: Book Reading** (SP Healing)

| | |
|---|---|
| **Duration** | ~4 minutes (6 ticks, 40s apart) |
| **Ahn Cost** | 100 |
| **Per-tick benefit** | Attendees in zone heal 8 SP |
| **EXP** | 3 per completed tick + 2 per attendee per tick |
| **Flavor lines** | `"[user] opens their tome and reads aloud: 'In darkness, the pursuit of understanding is the only true light...'"` |

**Flow:** Dieci sets up zone → uses tome (5s channel) → reads a passage → attendees heal 8 SP → ~35 seconds of free RP time → next tick → repeat 6 times. Total SP healed per attendee: up to 48 SP.

**Event 2: Training Session** (Attribute Boost)

| | |
|---|---|
| **Duration** | ~5 minutes (6 ticks, 50s apart) |
| **Ahn Cost** | 200 |
| **Per-tick benefit** | All attendees in zone gain +1 to ALL attributes (Fortitude, Prudence, Temperance, Justice) for 5 minutes |
| **EXP** | 4 per completed tick + 3 per attendee per tick |
| **Flavor lines** | `"[user] demonstrates a defensive stance and instructs: 'Guard your center — all strength flows from balance.'"` |

**Flow:** Dieci sets up zone → uses tome (5s channel) → demonstrates technique → attendees get +1 all stats → ~45 seconds of free RP time → next tick → repeat 6 times. Attendees who stay for all 6 ticks gain +6 to all attributes for 5 minutes. Attribute bonus duration refreshes per tick (so attending tick 6 gives +6 all stats for 5 more minutes from that point).

**Event 3: Charity Sermon** (Ahn Generation)

| | |
|---|---|
| **Duration** | ~7 minutes (7 ticks, 60s apart) |
| **Ahn Cost** | 300 |
| **Per-tick benefit** | Each attendee in zone earns 25 ahn (via ID card bank account) |
| **EXP** | 5 per completed tick + 4 per attendee per tick |
| **Flavor lines** | `"[user] raises their tome and speaks with conviction: 'To share knowledge freely is the highest form of wealth...'"` |

**Flow:** Dieci sets up zone → uses tome (5s channel) → delivers sermon → attendees each earn 25 ahn → ~55 seconds of free RP time → next tick → repeat 7 times. Total ahn per attendee: up to 175 ahn. The Dieci earns **no ahn** from this event — it is pure charity. Highest EXP reward to compensate.

**Event Summary:**

| Event | Duration | Ahn Cost | Ticks | Tick Interval | Per-Tick Benefit | EXP per Tick |
|---|---|---|---|---|---|---|
| Book Reading | ~4 min | 100 | 6 | 40s | 8 SP heal | 3 + 2/attendee |
| Training Session | ~5 min | 200 | 6 | 50s | +1 all attributes (5min) | 4 + 3/attendee |
| Charity Sermon | ~7 min | 300 | 7 | 60s | 25 ahn each | 5 + 4/attendee |

**EXP Examples:**
- Book Reading with 3 attendees: `(3 + 2*3) * 6 = 54 EXP`
- Training Session with 4 attendees: `(4 + 3*4) * 6 = 96 EXP`
- Charity Sermon with 5 attendees: `(5 + 4*5) * 7 = 175 EXP`

---

### EXP & Active Knowledge Summary

| Activity | EXP | Knowledge | Type | Level | Notes |
|---|---|---|---|---|---|
| Bestiary scan (living mob) | 1 | +1 | Anatomical | 1–5 (by HP) | Click hostile mob with Tome, first time per type. Level scales with maxHealth (400 HP per tier, cap at 5) |
| Examine dead body (NPC) | 3 | +1 | Anatomical | 2 | 5s do_after, once until revived |
| Examine dead body (player) | 5 | +1 | Anatomical | 3 | 5s do_after, once until revived |
| Observe combat | 1 | +1 (20% chance) | Behavioral | 1 | Per attack/damage on observed target |
| Healing Kit (Basic) | 2 | +1 | Medical | 1 | 50 ahn, 20 uses |
| Healing Kit (Standard) | 3 | +1 | Medical | 2 | 100 ahn, 40 uses |
| Healing Kit (Advanced) | 5 | +1 | Medical | 3 | 200 ahn, 80 uses |
| Sacred Seasoning eaten | 2 | +1 | Spiritual | 1 | Must see eater, 50 ahn for 3 uses |
| Event tick completed | varies | +1 | Spiritual | 1 | From hosting public events |
| Passive contract tick | 1 / 10s | — | — | — | No Active Knowledge |
| Contract completion | 10-30 | — | — | — | No Active Knowledge |

### Design Notes

- **Two resources:** EXP (permanent, for skill tree progression) and Active Knowledge (consumable combat fuel with flavor text, typed and leveled)
- **4 knowledge types** (Anatomical, Behavioral, Medical, Spiritual) encourage varied charity work and tie into different skill branches
- **5 knowledge levels** — Levels 1-3 come from activities, Levels 4-5 only from synthesis (3 same-type same-level → 1 higher). Level 5 costs 27x Level 1 entries, making it a major investment
- **The knowledge loop:** do charity → gain Active Knowledge + EXP → record into Tome → consume in combat → re-read Tome to restore → run out → do more charity
- Active Knowledge entries have **readable flavor text** (viewable via action), making each piece of knowledge feel tangible
- **Recording** and **re-reading** both require `do_after` channels — the Dieci must take time to write/study
- **Dead body examination** uses `TRAIT_DIECI_EXAMINED` + `COMSIG_LIVING_REVIVE` to prevent re-examining until the body is revived
- **Observe system** creates a passive knowledge gain from watching others fight — rewards positioning near combat without participating
- **Tomes are `/obj/item/book` subtypes** so they naturally work with bookcases. Dieci can build personal libraries of stored knowledge across multiple tomes
- **Bestiary system** follows the `combat_log_book.dm` pattern — `afterattack()` on hostile mobs, `icon2base64(getFlatIcon())` for icons, assoc list database, TGUI with page navigation and editable notes. Embedded in the Tome rather than a separate item
- Events are the **fastest source** of both EXP and Active Knowledge but cost ahn, time (4-7 minutes), and active participation
- Other players are **incentivized to attend** events (free SP, attributes, ahn), creating natural social gameplay
- The Dieci is **most useful to the team outside of combat** and **strongest in combat immediately after helping others**
- Events encourage **RP** by design — long durations with free time between ticks, visible spoken lines, gathering players together
- The ahn cost means Dieci must earn money from contracts before they can host events, preventing event spam

**Skill Tree — 3 Branches (pick 2):**

**Core Combat Mechanic: Imbue Knowledge** (available to ALL Dieci, not branch-locked)

The Dieci's weapon deals **RED damage** by default. Using the **Imbue Knowledge** action (`/datum/action/cooldown/dieci_imbue`, 5s CD) consumes 1 Active Knowledge entry (lowest level first) and converts weapon damage to **PALE** for `level × 5` seconds (Level 1 = 5s, Level 5 = 25s). While in PALE mode, melee hits apply **2 Sinking stacks** to the target. This is the core damage loop:

1. Hit with RED weapon → build Sinking stacks (from branch skills)
2. Sinking activates after 5 seconds
3. Use Imbue Knowledge → weapon becomes PALE
4. Each PALE hit **triggers** Sinking (SP damage = stacks, halves stacks) AND applies 2 new stacks (which inherit the already-activated state, so the next hit triggers again)
5. Sustained PALE hitting = repeated Sinking triggers + replenishment
6. Run out of Active Knowledge → weapon reverts to RED → repeat cycle

Visual: weapon gets a pale glow overlay during PALE mode. Sound: `'sound/machines/terminal_prompt_confirm.ogg'` on activation.

```dm
/datum/action/cooldown/dieci_imbue
	name = "Imbue Knowledge"
	desc = "Consume Active Knowledge to convert your weapon to PALE damage, enabling Sinking triggers."
	cooldown_time = 5 SECONDS
	/// Whether PALE mode is currently active
	var/pale_active = FALSE
	/// Timer for reverting to RED
	var/revert_timer

/datum/action/cooldown/dieci_imbue/proc/activate(mob/living/carbon/human/user)
	var/datum/component/dieci_knowledge/knowledge = user.GetComponent(/datum/component/dieci_knowledge)
	if(!knowledge)
		return
	var/list/consumed = knowledge.consume_lowest_knowledge(1)
	if(!length(consumed))
		to_chat(user, span_warning("You have no Active Knowledge to imbue!"))
		return
	var/consumed_level = consumed[1]["level"]
	var/duration = consumed_level * 5 SECONDS
	pale_active = TRUE
	// Override weapon damtype to PALE
	var/obj/item/weapon = user.get_active_held_item()
	if(weapon)
		weapon.damtype = PALE_DAMAGE
	// Register attack signal for Sinking application
	RegisterSignal(user, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_pale_attack))
	to_chat(user, span_notice("You channel your knowledge into your weapon. It glows with a pale light."))
	playsound(get_turf(user), 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
	// Set revert timer
	if(revert_timer)
		deltimer(revert_timer)
	revert_timer = addtimer(CALLBACK(src, PROC_REF(revert_pale), user), duration, TIMER_STOPPABLE)
	StartCooldown()

/datum/action/cooldown/dieci_imbue/proc/on_pale_attack(datum/source, mob/living/target, obj/item/weapon)
	SIGNAL_HANDLER
	if(!pale_active || !istype(target))
		return
	target.apply_lc_sinking(2)

/datum/action/cooldown/dieci_imbue/proc/revert_pale(mob/living/carbon/human/user)
	pale_active = FALSE
	revert_timer = null
	UnregisterSignal(user, COMSIG_MOB_ITEM_ATTACK)
	var/obj/item/weapon = user.get_active_held_item()
	if(weapon)
		weapon.damtype = RED_DAMAGE
	to_chat(user, span_notice("The pale glow fades from your weapon."))
```

**Sinking Reference:**
- Max 50 stacks, 5s activation delay on first application
- Once active: WHITE or PALE damage triggers it → SP damage = stacks (humans) or WHITE × 4 (simple mobs), then halves stacks
- `apply_lc_sinking(stacks)` — adds to existing (already activated) effect, no new delay
- Defined in `code/datums/status_effects/debuffs.dm:1956-2051`

**Design Note:** Dieci does NOT use Fragile or Defense Level Down. Their debuff identity is purely **Sinking**.

---

#### `dieci_shield_hp` Component

A flat HP shield that absorbs **raw incoming damage** before the Dieci's real HP. No armor or physiology interaction — the shield simply subtracts the damage value from its pool. If the shield absorbs all damage (reducing the hit to 0 HP damage), it shows the `/obj/effect/temp_visual/shock_shield` effect. If damage exceeds shield HP, the shield breaks and the overflow is dealt normally. Granted by Warden branch T1 skills.

**Shield HP caps at 500**, but the Dieci can only gain it in small amounts through skills (2-3 per melee hit) and by consuming Active Knowledge (10 × level via Tome Shield). Combined with the **halving every 10 seconds** decay, reaching high values requires constant combat activity and knowledge expenditure. The shield starts at 0 and must be built up.

Example: Warden with Knowledge Barrier restoring 3/hit. Rapid attacking builds shield to ~40-50 before decay catches up. Using Tome Shield with a Level 3 entry adds +30 instantly. Without sustained input, 50 → 25 → 12 → 6 → 3 → 1 → 0 over a minute.

```dm
/datum/component/dieci_shield_hp
	/// Current shield HP — starts at 0, must be built up via skills/knowledge
	var/shield_health = 0
	/// Hard cap on shield HP
	var/max_shield_health = 500
	/// Callback proc when shield absorbs any damage (partial or full block)
	var/datum/callback/on_shield_absorb
	/// Timer for the 10s halving decay
	var/decay_timer

/datum/component/dieci_shield_hp/Initialize()
	. = ..()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	shield_health = 0 // Starts empty — must be built up
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_damage))
	// Start the halving decay timer — repeats every 10 seconds
	decay_timer = addtimer(CALLBACK(src, PROC_REF(decay_shield)), 10 SECONDS, TIMER_STOPPABLE | TIMER_LOOP)

/datum/component/dieci_shield_hp/Destroy()
	on_shield_absorb = null
	if(decay_timer)
		deltimer(decay_timer)
		decay_timer = null
	return ..()

/// Every 10 seconds, halve the shield HP
/datum/component/dieci_shield_hp/proc/decay_shield()
	if(shield_health <= 0)
		return
	shield_health = max(0, round(shield_health / 2))

/// Intercept incoming damage — flat shield HP absorbs raw damage values, no armor/physiology interaction
/datum/component/dieci_shield_hp/proc/on_damage(datum/source, damage, damage_type, def_zone, attacker, flags, attack_type)
	SIGNAL_HANDLER
	if(shield_health <= 0 || damage <= 0)
		return // Shield is down or no damage, passes through normally

	// Fire absorb callback on ANY shield absorption (used by Reactive Ward, Immovable Library, etc.)
	on_shield_absorb?.Invoke(parent, attacker, min(damage, shield_health))

	if(damage >= shield_health)
		// Shield breaks — overflow damage passes through to normal HP
		var/overflow = damage - shield_health
		shield_health = 0
		if(overflow > 0)
			INVOKE_ASYNC(src, PROC_REF(deal_overflow), parent, overflow, damage_type, def_zone, attacker)
		return COMPONENT_MOB_DENY_DAMAGE
	else
		// Shield absorbs all damage — show shock_shield visual
		shield_health -= damage
		var/obj/effect/temp_visual/shock_shield/AT = new /obj/effect/temp_visual/shock_shield(get_turf(parent))
		AT.transform *= 0.5
		AT.pixel_x += rand(-8, 8)
		AT.pixel_y += rand(-12, 12)
		playsound(get_turf(parent), 'sound/mecha/mech_shield_deflect.ogg', 70)
		return COMPONENT_MOB_DENY_DAMAGE

/// Deal overflow damage when shield breaks
/datum/component/dieci_shield_hp/proc/deal_overflow(mob/living/target, damage, damage_type, def_zone, attacker)
	target.deal_damage(damage, damage_type, attacker)

/// Add shield HP (capped at max_shield_health = 500)
/datum/component/dieci_shield_hp/proc/restore_shield(amount)
	shield_health = min(max_shield_health, shield_health + amount)
```

---

#### Branch 1: Scholar (Sinking Focus)

**Theme:** Apply and exploit Sinking stacks. The Scholar builds Sinking with RED hits and amplifies PALE mode triggers. Deep knowledge of weakness turns every strike into a mounting threat.

**T1 (1pt) — Pick one:**
- **A: Deep Study** — Each melee attack applies 3 Sinking stacks to the target.
- **B: Analytical Strike** — Hitting a target with no Sinking applies 8 Sinking stacks. Hitting a target that already has Sinking applies 1 stack instead.

**T2 (2pt) — Pick one:**
- **A: Drowning Knowledge** — While Imbue Knowledge is active (PALE mode), attacks on targets with 15+ Sinking deal 25% bonus weapon damage.
- **B: Spreading Decay** — While in PALE mode, hitting a target that has Sinking also applies 2 Sinking to all enemies within 2 tiles of the target. 2s internal CD.

**T3 (3pt) — Pick one:**
- **A: Abyssal Revelation** *(Powerful Attack, 90s CD)* — Requires Imbue Knowledge to be active. Consume all remaining Imbue duration. Dash to target within 5 tiles, 5-hit PALE combo. Each hit applies 5 Sinking. Final hit: 2x DPS + **immediately triggers all Sinking** on the target (bypasses 5s activation delay). After the combo, grants 10 seconds of fresh PALE mode (no knowledge consumed).
- **B: Tome of Ruin** *(Passive)* — Every 5th consecutive PALE-mode melee hit on the same target **immediately triggers all Sinking** on the target (bypasses activation delay) and then applies 5 new Sinking stacks. Also, Imbue Knowledge duration is extended by 2 seconds each time Sinking triggers from your attacks.

**Abyssal Revelation — Details:**
- **Opener:** Dash up to 5 tiles toward target. If target is adjacent, skip the dash.
- **Combo:** 5 hits, all PALE damage. DPS = `(weapon.force * weapon.force_multiplier * 1.25) / weapon.attack_speed`.
- **Per-hit effect:** Apply 5 Sinking stacks to target.
- **Final hit:** 2x DPS. After dealing damage, find the target's Sinking status effect and call `trigger_sinking()` directly — this bypasses the normal 5s activation delay.
- **After combo:** Grant 10 seconds of PALE mode (same as Imbue Knowledge active state) without consuming Active Knowledge.

**Implementation Notes:**
- Deep Study: `COMSIG_MOB_ITEM_ATTACK` → `target.apply_lc_sinking(3)`.
- Analytical Strike: `COMSIG_MOB_ITEM_ATTACK` → check `target.has_status_effect(/datum/status_effect/stacking/sinking)` → if no Sinking: `apply_lc_sinking(8)`, else: `apply_lc_sinking(1)`.
- Drowning Knowledge: `COMSIG_MOB_ITEM_ATTACK` → check `imbue_action.pale_active` → get target's Sinking stacks via `target.has_status_effect(...)` → if stacks ≥ 15, deal `weapon.force * 0.25` bonus damage via `INVOKE_ASYNC` → `target.deal_damage()`.
- Spreading Decay: `COMSIG_MOB_ITEM_ATTACK` → check `imbue_action.pale_active` → check target has Sinking → 2s CD check → `for(var/mob/living/L in range(2, target))` excluding target and user → `L.apply_lc_sinking(2)`.
- Abyssal Revelation: `/datum/action/cooldown/dieci_abyssal` → requires `imbue_action.pale_active` → consume remaining timer (`deltimer(revert_timer)`) → cutscene_duel + immobilize → 5 PALE hits → final hit: `var/datum/status_effect/stacking/sinking/S = target.has_status_effect(...)` → `if(S) S.trigger_sinking()` → grant 10s PALE via `imbue_action.revert_timer = addtimer(..., 10 SECONDS, ...)`.
- Tome of Ruin: Track `var/pale_combo_count = 0` and `var/datum/weakref/combo_target_ref`. On `COMSIG_MOB_ITEM_ATTACK` → if `imbue_action.pale_active`: if target != last combo target → reset count. Increment count. At 5 → `var/datum/status_effect/stacking/sinking/S = target.has_status_effect(...)` → `if(S && S.stacks > 0) INVOKE_ASYNC(S, PROC_REF(trigger_sinking))` → then `target.apply_lc_sinking(5)` → reset count. For duration extension: hook into Sinking trigger somehow or simply extend timer by 2s after each 5th-hit trigger.

---

#### Branch 2: Warden (Shield Focus)

**Theme:** The `dieci_shield_hp` component branch. Knowledge becomes a literal barrier. The Warden fights behind a shield of accumulated wisdom, absorbing punishment and retaliating through Sinking applied on blocks.

**T1 (1pt) — Pick one:**
- **A: Knowledge Barrier** — Gain the `dieci_shield_hp` component (starts at 0, max 500). Landing melee attacks restores **3 shield HP**.
- **B: Reactive Ward** — Gain the `dieci_shield_hp` component (starts at 0, max 500). Landing melee attacks restores **2 shield HP**. Whenever the shield absorbs any amount of damage (partial or full), apply **5 Sinking** to the attacker.

**T2 (2pt) — Pick one:**
- **A: Tome Shield** — Action: consume 1 Active Knowledge entry to restore shield HP = **10 × entry level**. 5s CD.
- **B: Stalwart Presence** — Shield decay is reduced (halves every **15 seconds** instead of 10). While shield HP is above **50**, gain **+15% movement speed**.

**T3 (3pt) — Pick one:**
- **A: Golden Aegis** *(Powerful Attack, 90s CD)* — Consume all Active Knowledge entries (min 3). Shield set to **100 HP**, cannot break for **8 seconds**. Each time the shield absorbs damage during this period, apply Sinking = damage absorbed / 5 to the attacker. After 8s, release an AoE **PALE shockwave** (3-tile radius) dealing damage = remaining shield HP. Shield resets to base max HP after.
- **B: Immovable Library** *(Passive)* — Shield passively regenerates **1 HP every 5 seconds**. Whenever the shield absorbs any amount of damage (partial or full), your **next melee attack within 3s deals PALE damage** instead of RED and applies **5 Sinking**. No Active Knowledge cost for this conversion.

**Golden Aegis — Details:**
- **Activation:** Consume all Active Knowledge (minimum 3 entries required). Shield HP is set to 100 regardless of current value. Shield becomes **unbreakable** for 8 seconds (damage still reduces shield HP, but it cannot go below 1).
- **During buff:** Each time the shield absorbs damage (on every `on_damage` where shield > 0), apply Sinking stacks = `round(damage_absorbed / 5)` (min 1) to the attacker.
- **After 8s:** AoE PALE shockwave centered on the Dieci, 3-tile radius. All enemies in range take PALE damage = current shield HP value. Apply 5 Sinking to all enemies hit. Then shield resets to **0** (must rebuild).
- **Combo with Imbue:** If Imbue Knowledge is also active, the shockwave triggers Sinking on enemies that already had active stacks.

**Implementation Notes:**
- Knowledge Barrier: On skill registration → `parent.AddComponent(/datum/component/dieci_shield_hp)`. `COMSIG_MOB_ITEM_ATTACK` → `shield_comp.restore_shield(3)`.
- Reactive Ward: On skill registration → `parent.AddComponent(/datum/component/dieci_shield_hp)`. `COMSIG_MOB_ITEM_ATTACK` → `shield_comp.restore_shield(2)`. Set `shield_comp.on_shield_absorb = CALLBACK(src, PROC_REF(on_shield_hit))` → `on_shield_hit(user, attacker, absorbed)` → `attacker.apply_lc_sinking(5)`.
- Tome Shield: `/datum/action/cooldown/dieci_tome_shield` with 5s CD → consume 1 Active Knowledge → `shield_comp.restore_shield(10 * level)`.
- Stalwart Presence: Override `shield_comp.decay_timer` interval to 15s instead of 10s. Track shield HP → `add_movespeed_modifier(/datum/movespeed_modifier/dieci_stalwart)` (multiplicative_slowdown = -0.15, variable = TRUE) when above 50 HP, remove when below.
- Golden Aegis: `/datum/action/cooldown/dieci_golden_aegis` → consume all knowledge → `shield_comp.shield_health = 100` → set `aegis_active = TRUE` → pause decay timer → register special on_damage handler that applies Sinking → `addtimer(8 SECONDS)` → AoE PALE via `for(var/mob/living/L in range(3, user))` → `L.deal_damage(shield_comp.shield_health, PALE_DAMAGE, user)` + `L.apply_lc_sinking(5)` → `shield_comp.shield_health = 0` → resume decay timer → `aegis_active = FALSE`.
- Immovable Library: Start a 5s repeating `addtimer` → `shield_comp.restore_shield(1)`. Set `shield_comp.on_shield_absorb = CALLBACK(...)` → on any shield absorption: set `var/pale_counter_active = TRUE` + `addtimer(CALLBACK(reset_pale_counter), 3 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)`. On `COMSIG_MOB_ITEM_ATTACK` → if `pale_counter_active`: force this hit to PALE via `INVOKE_ASYNC` → `target.deal_damage(weapon.force, PALE_DAMAGE, user)` + `target.apply_lc_sinking(5)` + reset flag. (Return damage modification signal or deal extra PALE damage separately.)

---

#### Branch 3: Sage (Knowledge Enhancement)

**Theme:** Maximize the Active Knowledge economy. The Sage makes every piece of knowledge count more — longer buffs, cheaper synthesis, stronger consumption effects, and the ability to share knowledge with allies. At peak knowledge reserves, the Sage's weapon permanently channels PALE energy.

**T1 (1pt) — Pick one:**
- **A: Extensive Notes** — Max Active Knowledge increased from **20 to 30**. Imbue Knowledge duration increased by **50%** (level × 7.5s instead of × 5s).
- **B: Applied Learning** — Each time Active Knowledge is consumed (for any purpose — Imbue, Tome Shield, skills, etc.), gain **4 Offense Level Up** stacks.

**T2 (2pt) — Pick one:**
- **A: Shared Wisdom** — Action: target an ally within 5 tiles. Consume 1 Active Knowledge entry → give the ally **+5% damage per knowledge level** for 30s. Also apply Sinking = knowledge level × 2 to all enemies within 3 tiles of the ally. 15s CD.
- **B: Efficient Research** — Synthesis costs **2 entries instead of 3** to create the next level. Consuming Level 3+ knowledge in combat refunds **1 entry of the same type, one level lower** (partial refund).

**T3 (3pt) — Pick one:**
- **A: Grand Archive** *(Powerful Attack, 90s CD)* — Consume up to **5 Active Knowledge entries** (min 3). Each consumed entry = 1 hit in the combo. Each hit's damage type depends on knowledge type: **Anatomical/Behavioral = RED**, **Medical = WHITE**, **Spiritual = PALE**. Per-hit: apply Sinking = knowledge level × 2. Final hit: 2x DPS + apply Sinking = total consumed levels × 2.
- **B: Infinite Library** *(Passive)* — Active Knowledge **has no max cap**. When holding **25+ entries**, weapon passively deals PALE damage (always, no Imbue needed). When holding **35+ entries**, melee attacks also passively apply 2 Sinking per hit. Consuming knowledge at 35+ does not lose the passive until you drop below the threshold.

**Grand Archive — Details:**
- **Activation:** Consume 3-5 Active Knowledge entries (player chooses via TGUI popup or auto-selects lowest first).
- **Combo:** Number of hits = number of entries consumed (3 to 5). Each hit uses the consumed entry's type to determine damage type:
  - Anatomical → RED damage
  - Behavioral → RED damage
  - Medical → WHITE damage (can trigger Sinking if stacks are active!)
  - Spiritual → PALE damage (triggers Sinking)
- **Per-hit:** DPS damage + apply Sinking stacks = consumed entry's level × 2.
- **Final hit:** 2x DPS. Apply bonus Sinking = sum of all consumed levels × 2. For example, consuming L2 + L3 + L1 + L4 + L1 = total 11, so final hit applies 22 Sinking.
- **Strategy:** Consuming Spiritual/Medical entries at the end ensures PALE/WHITE final hits trigger accumulated Sinking.

**Implementation Notes:**
- Extensive Notes: On skill registration → `knowledge_comp.max_knowledge = 30`. Override Imbue duration calc to multiply by 7.5 instead of 5.
- Applied Learning: Hook into all knowledge consumption events (track via component signal). On consume → `human_parent.apply_lc_offense_level_up(4)`. OLU naturally halves every 5s so sustained consumption keeps it high.
- Shared Wisdom: `/datum/action/cooldown/dieci_shared_wisdom` with 15s CD → pointed at ally → consume 1 knowledge → apply `/datum/status_effect/dieci_wisdom_buff` to ally (damage_mult = 1 + 0.05 * level, 30s duration) → `for(var/mob/living/L in range(3, ally))` → check hostile → `L.apply_lc_sinking(level * 2)`.
- Efficient Research: Modify synthesis logic in Tome TGUI handler → change required count from 3 to 2. On knowledge consumption in combat → if consumed level ≥ 3 → `knowledge_comp.add_knowledge(type, level - 1, "Residual insight from [type] study")`.
- Grand Archive: `/datum/action/cooldown/dieci_grand_archive` → TGUI popup or auto-select → consume 3-5 entries → store their types/levels → cutscene_duel + immobilize → N hits. Per-hit: determine damtype from entry type, deal DPS damage, `target.apply_lc_sinking(entry_level * 2)`. Final hit: 2x DPS + `target.apply_lc_sinking(total_levels * 2)`.
- Infinite Library: On skill registration → `knowledge_comp.max_knowledge = INFINITY` (or a very high number like 999). Track threshold via `COMSIG_DIECI_KNOWLEDGE_CHANGED` (new signal on add/remove). At 25+ → override weapon damtype to PALE permanently (register `COMSIG_MOB_ITEM_ATTACK` to set damtype before hit). At 35+ → also `target.apply_lc_sinking(2)` per hit. Check thresholds on every knowledge change.

---

### Branch Synergies

| Combo | Playstyle | Strength |
|---|---|---|
| **Scholar + Warden** | "The Fortress Scholar" — Build Sinking aggressively while the shield buys time. Shield blocks with Reactive Ward apply Sinking passively; PALE mode triggers accumulated stacks. | Best sustained 1v1. Shield absorbs punishment while Sinking overwhelms. |
| **Scholar + Sage** | "The Master Archivist" — Maximum Sinking application with knowledge efficiency. Never run out of knowledge, every piece of knowledge amplifies Sinking. Applied Learning + Deep Study = constant Sinking + damage buffs. | Highest damage output. Knowledge fuels relentless offense. |
| **Warden + Sage** | "The Living Library" — Shield + knowledge buffs + support. Hard to kill, helps allies, and Infinite Library provides passive PALE without consuming knowledge. | Best support + survivability. Never runs dry. |

### Implementation Notes (General)

- **No Fragile or DLD** — Dieci's debuff identity is purely Sinking
- Core status effect is **Sinking** (`code/datums/status_effects/debuffs.dm:1956-2051`) — max 50 stacks, 5s activation delay, triggers on WHITE/PALE damage
- The `dieci_shield_hp` component uses `COMSIG_MOB_APPLY_DAMGE` → flat subtract raw damage from shield HP → `COMPONENT_MOB_DENY_DAMAGE`. No armor/physiology recalculation. Shows `/obj/effect/temp_visual/shock_shield` on full block (0 HP damage to user). Overflow damage dealt normally via `deal_damage()`. Max 500 HP, starts at 0, built up in small amounts via skills (3/hit, 2/hit) and Active Knowledge consumption (10 × level). **Halves every 10 seconds** (15s with Stalwart Presence), creating a "use it or lose it" dynamic
- **Imbue Knowledge** is the universal RED→PALE conversion action — all Dieci have it regardless of branch
- Sinking stacks added to an already-activated effect do NOT get a new 5s delay — this makes PALE mode hits trigger + replenish in the same attack
- `trigger_sinking()` can be called directly on the status effect datum to bypass the 5s activation delay (used by Abyssal Revelation and Tome of Ruin)
- **Weapon damtype override:** Skills that change damtype (Imbue, Immovable Library counter, Infinite Library passive) modify `weapon.damtype` directly or deal extra damage of the alternate type via `INVOKE_ASYNC` → `target.deal_damage()`

### New Files to Create

- `ModularLobotomy/associations/skills/dieci/scholar.dm`
- `ModularLobotomy/associations/skills/dieci/warden.dm`
- `ModularLobotomy/associations/skills/dieci/sage.dm`
- `ModularLobotomy/associations/skills/dieci/dieci_shield_hp.dm`
- `ModularLobotomy/associations/skills/dieci/imbue_knowledge.dm`
- `tgui/packages/tgui/interfaces/DieciTomeBestiary.js`

---

### Cinq (NEW) - "The Blade"

**Theme:** Honor dueling and professional combat. Cinq are elite duelists who hire out their blades for single combat — one-on-one encounters where reputation, money, and sometimes lives are on the line. They view combat as an art form built on composure and discipline. A Cinq fixer does not brawl; they duel. Their work ranges from honorable formal duels (first blood, to incapacitation) to ruthless contracted kills (to the death). Outside of duels, they train obsessively, honing the split-second focus that separates a clean critical strike from a wasted swing.

Cinq's identity is the **duel itself** — an isolated, formal contest between two combatants. Their in-place duel system creates a sealed bubble that prevents outside interference, turning any hallway, street corner, or elevator into an arena. Poise and Concentration are their mechanical language: Poise represents the razor-edge focus that enables devastating criticals, while Concentration represents the deeper discipline that sustains that focus under pressure.

**Gimmick / EXP Source: Dueling**

Cinq earn EXP through winning duels and completing duel contracts. Their duel system **only works on carbon mobs** (players), emphasizing player interaction.

### Duel System

Cinq's core mechanic is the **formal duel** — a structured one-on-one fight that happens in-place with a duel component blocking all outside interference. When a duel begins, a visible ring (range 8 tiles from the duel's center point) is created that only the two duelists can see. If either combatant leaves the ring, they **immediately lose** the duel, take SP damage equal to 75% of their current SP, and are slowed for 5 seconds. Duels are the primary way Cinq earns EXP and the vehicle for their contract work.

**Duel Levels:**

| Level | End Condition | Post-Duel Healing | Risk |
|-------|--------------|-------------------|------|
| **Level 1: First Blood** | Either combatant reaches 25% HP | Both fully healed (`fully_heal()`) | Low — training/honor duels |
| **Level 2: Submission** | Either combatant reaches crit threshold | Both healed to 50% max HP | Medium — serious disputes |
| **Level 3: To the Death** | One combatant dies (`COMSIG_LIVING_DEATH`) | None | Lethal — contracted kills |

**Duel Types:**

1. **Consensual Duel** — The Cinq fixer uses the **Challenge to Duel** action (`/datum/action/cooldown/cinq_challenge`) on a carbon mob. A TGUI prompt appears for the target: "Accept Duel? Level: [1/2/3]" with Accept/Decline buttons. Target has 30 seconds to respond. On accept, duel begins after a 3-second countdown. Both players can be anyone — Cinq vs Cinq, Cinq vs civilian, etc.

2. **Contracted Duel (Forced)** — The Cinq fixer is hired to duel a specific target. Uses the **Throw the Glove** action (`/datum/action/cooldown/cinq_glove_throw`) — a projectile glove is thrown at the target (3-tile range, same as `throw_at()` pattern). On hit, the target receives a visible message: `"[user] throws a dueling glove at [target]'s feet — a formal challenge!"` After a 5-second delay (during which both parties can prepare), the duel begins automatically with no consent required. Only available while on a Duel Person contract. The glove is a `/obj/item/cinq_glove` that auto-deletes after the duel starts.

**Duel Component (`/datum/component/cinq_duel`):**

Applied to BOTH duelists when a duel begins. Prevents ALL damage from sources other than the other duelist. This is the same pattern as `/datum/component/cutscene_duel` but extended for longer-duration player-vs-player duels.

```dm
/datum/component/cinq_duel
	/// The other duelist — only this mob can damage us
	var/mob/living/opponent
	/// Duel level (1, 2, or 3)
	var/duel_level = 1
	/// Reference to the duel datum managing this fight
	var/datum/cinq_duel_instance/duel_instance

/datum/component/cinq_duel/Initialize(mob/living/opponent_mob, level, datum/cinq_duel_instance/instance)
	opponent = opponent_mob
	duel_level = level
	duel_instance = instance
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_damage))

/datum/component/cinq_duel/proc/on_damage(datum/source, damage, damagetype, def_zone, blocked, forced, spread_flags, wound_bonus, bare_wound_bonus, sharpness, atom/incoming_attacker)
	SIGNAL_HANDLER
	if(incoming_attacker != opponent)
		return COMPONENT_MOB_DENY_DAMAGE
	// After damage passes through, check end conditions
	INVOKE_ASYNC(duel_instance, TYPE_PROC_REF(/datum/cinq_duel_instance, check_end_condition))
```

**Duel Instance Datum (`/datum/cinq_duel_instance`):**

Manages the lifecycle of a single duel. Created when a duel begins, destroyed when it ends.

```dm
/datum/cinq_duel_instance
	var/mob/living/duelist_a
	var/mob/living/duelist_b
	var/duel_level = 1
	var/duel_active = FALSE
	/// Who initiated (for EXP/ahn tracking — the Cinq fixer)
	var/mob/living/initiator
	/// Center turf of the duel ring
	var/turf/ring_center
	/// Ring radius in tiles
	var/ring_range = 8
	/// Visual ring overlay images (only visible to duelists)
	var/list/ring_images = list()

/datum/cinq_duel_instance/proc/start_duel()
	duel_active = TRUE
	// Create the duel ring centered between the two duelists
	ring_center = get_turf(duelist_a)
	create_ring_visuals()
	duelist_a.AddComponent(/datum/component/cinq_duel, duelist_b, duel_level, src)
	duelist_b.AddComponent(/datum/component/cinq_duel, duelist_a, duel_level, src)
	// Track movement for ring boundary
	RegisterSignal(duelist_a, COMSIG_MOVABLE_MOVED, PROC_REF(on_duelist_moved))
	RegisterSignal(duelist_b, COMSIG_MOVABLE_MOVED, PROC_REF(on_duelist_moved))
	if(duel_level == 3)
		RegisterSignal(duelist_a, COMSIG_LIVING_DEATH, PROC_REF(on_death))
		RegisterSignal(duelist_b, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	duelist_a.visible_message(span_boldwarning("A formal duel begins between [duelist_a] and [duelist_b]!"))

/datum/cinq_duel_instance/proc/create_ring_visuals()
	// Create ring border overlay images visible only to duelists
	// Use /image objects added to duelist clients so only they can see the ring
	for(var/turf/T in circle_range(ring_center, ring_range))
		if(get_dist(T, ring_center) >= ring_range - 1) // Border tiles only
			var/image/I = image('icons/effects/effects.dmi', T, "yourstate") // placeholder icon
			I.alpha = 128
			ring_images += I
	if(duelist_a.client)
		duelist_a.client.images += ring_images
	if(duelist_b.client)
		duelist_b.client.images += ring_images

/datum/cinq_duel_instance/proc/on_duelist_moved(datum/source)
	SIGNAL_HANDLER
	var/mob/living/mover = source
	if(!duel_active)
		return
	if(get_dist(get_turf(mover), ring_center) > ring_range)
		// Left the ring — immediate loss with penalty
		INVOKE_ASYNC(src, PROC_REF(ring_forfeit), mover)

/datum/cinq_duel_instance/proc/ring_forfeit(mob/living/deserter)
	if(!duel_active)
		return
	var/mob/living/winner = (deserter == duelist_a) ? duelist_b : duelist_a
	// SP penalty: 75% of current SP
	deserter.adjustSanityLoss(deserter.sanityhealth * 0.75)
	to_chat(deserter, span_userdanger("You fled the dueling ring! You forfeit the duel!"))
	// Slow for 5 seconds
	deserter.add_movespeed_modifier(/datum/movespeed_modifier/cinq_forfeit_slow)
	addtimer(CALLBACK(deserter, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/cinq_forfeit_slow), 5 SECONDS)
	end_duel(winner)

/datum/cinq_duel_instance/proc/check_end_condition()
	if(!duel_active)
		return
	switch(duel_level)
		if(1) // First Blood: 25% HP
			if(duelist_a.health <= duelist_a.maxHealth * 0.25)
				end_duel(duelist_b)
			else if(duelist_b.health <= duelist_b.maxHealth * 0.25)
				end_duel(duelist_a)
		if(2) // Submission: crit threshold
			if(duelist_a.health <= duelist_a.crit_threshold)
				end_duel(duelist_b)
			else if(duelist_b.health <= duelist_b.crit_threshold)
				end_duel(duelist_a)
		// Level 3 handled by on_death signal

/datum/cinq_duel_instance/proc/on_death(datum/source)
	SIGNAL_HANDLER
	var/mob/living/dead_one = source
	var/mob/living/winner = (dead_one == duelist_a) ? duelist_b : duelist_a
	INVOKE_ASYNC(src, PROC_REF(end_duel), winner)

/datum/cinq_duel_instance/proc/end_duel(mob/living/winner)
	duel_active = FALSE
	var/mob/living/loser = (winner == duelist_a) ? duelist_b : duelist_a
	// Remove duel components
	qdel(duelist_a.GetComponent(/datum/component/cinq_duel))
	qdel(duelist_b.GetComponent(/datum/component/cinq_duel))
	// Clean up signals
	UnregisterSignal(duelist_a, list(COMSIG_LIVING_DEATH, COMSIG_MOVABLE_MOVED))
	UnregisterSignal(duelist_b, list(COMSIG_LIVING_DEATH, COMSIG_MOVABLE_MOVED))
	// Remove ring visuals from both clients
	if(duelist_a.client)
		duelist_a.client.images -= ring_images
	if(duelist_b.client)
		duelist_b.client.images -= ring_images
	ring_images.Cut()
	// Announce
	winner.visible_message(span_boldwarning("[winner] wins the duel against [loser]!"))
	// Healing (delayed to avoid mid-signal issues, same pattern as lcl_duel.dm)
	switch(duel_level)
		if(1) // Full heal both
			addtimer(CALLBACK(src, PROC_REF(heal_both_full)), 1)
		if(2) // Heal both to 50%
			addtimer(CALLBACK(src, PROC_REF(heal_both_half)), 1)
		// Level 3: no healing
	// Award ahn to winner via ID card bank account
	var/ahn_reward = list(1 = 100, 2 = 250, 3 = 500)[duel_level]
	var/obj/item/card/id/C = winner.get_idcard(TRUE)
	if(C?.registered_account)
		C.registered_account.adjust_money(ahn_reward)
		winner.playsound_local(get_turf(winner), 'sound/effects/cashregister.ogg', 25, 3, 3)
		to_chat(winner, span_boldnotice("You earned [ahn_reward] ahn for winning the duel!"))
	// Award EXP to initiator if they won
	if(winner == initiator)
		var/datum/component/association_exp/exp = winner.GetComponent(/datum/component/association_exp)
		if(exp)
			exp.modify_exp(10 * duel_level) // 10/20/40 EXP
```

**Cinq-Specific Contract Types:**

- **Duel Person** (Cinq only) — Target a specific carbon player. The Cinq fixer must find and duel the target using the Throw the Glove action (forced, no consent). Contract specifies duel level. Contract completes when the duel ends (win or lose, but winning gives bonus EXP + ahn). Reflects Cinq's role as hired blades.

- **Champion Contract** (Cinq only) — A client hires the Cinq fixer to fight on their behalf. The client designates an opponent. The Cinq fixer must duel the specified target as the client's champion. Works identically to Duel Person mechanically (forced glove throw), but the contract payment comes from the client, not Hana. If the Cinq wins, both the fixer and the client benefit. The client must stay within 10 tiles during the duel to witness it (or contract is downgraded to standard Duel Person payout).

**Contract-Specific Behavior:**
- Cinq skill tree abilities **only function while on an active contract**
- Duel Person contracts show a direction indicator pointing toward the target
- Champion Contracts show indicators for both the client and the target
- Failing to initiate a duel within the contract duration = contract failure

**Target Grade EXP Bonus:**

When a duel ends in victory, the Cinq fixer earns bonus EXP based on the target's attribute grade. The target's "potential" is calculated from their 4 attributes (Fortitude, Prudence, Temperance, Justice):

```dm
/// Calculate target grade for EXP bonus
var/stattotal = 0
for(var/attribute in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE, TEMPERANCE_ATTRIBUTE, JUSTICE_ATTRIBUTE))
	stattotal += get_attribute_level(target, attribute)
stattotal /= 4  // Average of stats
var/grade = clamp(10 - round(stattotal / 20), 1, 9)  // Grade 1 (strongest) to 9 (weakest)
var/grade_bonus = max(0, (10 - grade) * 3)  // Grade 1 = 27 bonus EXP, Grade 5 = 15, Grade 9 = 3
```

Higher-grade (stronger) opponents yield more bonus EXP, rewarding Cinq fixers for taking on challenging duels rather than farming weak targets.

**EXP Sources Summary:**

| Activity | EXP Gain | Notes |
|---|---|---|
| Passive contract tick | 1 EXP / 10s | While on active contract |
| Duel victory (Level 1) | 10 EXP | First blood |
| Duel victory (Level 2) | 20 EXP | Submission |
| Duel victory (Level 3) | 40 EXP | To the death |
| Target grade bonus | 3-27 EXP | Based on target's attribute grade (stronger = more) |
| Poise crit during duel | 2 EXP per crit | Only while duel component active |
| Contract completion bonus | 10-30 EXP | Based on duration + outcome |

**Ahn Rewards:**

| Duel Level | Winner Reward |
|---|---|
| Level 1 | 500 ahn |
| Level 2 | 1250 ahn |
| Level 3 | 2500 ahn |

**Skill Tree — 3 Branches:**

Cinq has 3 branches. Players can invest in a maximum of 2.

**Core Status Effects: Poise and Concentration** — Cinq skills primarily use the Poise and Concentration status effects. Poise (max 50 stacks) grants `stacks * 2.5`% crit chance per melee attack. On crit: 25% weapon force as bonus damage, signals sent (`COMSIG_POISE_CRIT_ATTACKER` to attacker, `COMSIG_POISE_CRIT_TARGET` to target). After crit: if Concentration exists, consume 1 Concentration stack; otherwise halve all Poise stacks. Poise decays completely if no crit or new stacks gained within a 10-second tick. Concentration (max 10 stacks) protects Poise from halving on crit and decays 1 stack per 15 seconds; if no Poise exists, all Concentration is removed.

#### Branch 1: Duelist (Poise Focus)

**Theme:** Build and exploit Poise stacks for devastating criticals. The Duelist lives for the crit — every swing is calibrated to push Poise higher, and every crit lands like a hammer. Skills hook into `COMSIG_POISE_CRIT_ATTACKER` to reward and amplify the crit cycle.

**T1 (1pt) — Pick one:**
- **A: Keen Edge** — Each melee attack grants 3 Poise stacks. The simplest path to a critical strike: swing often, swing true.
- **B: Opening Gambit** — The first attack against a new target applies 8 Poise stacks; subsequent attacks on the same target apply 1. Switching targets resets the count. Size up your opponent in a single glance.

**T2 (2pt) — Pick one:**
- **A: Precision Strike** — On Poise crit, deal an additional 15% of your weapon's force as bonus damage and apply 3 Fragile stacks to the target (replace-if-higher). Your crits expose the flaws in their stance.
- **B: Momentum** — On Poise crit, regain Poise stacks equal to 50% of the stacks consumed or halved by the crit (minimum 3). Crits fuel crits — each successful strike feeds the next.

**T3 (3pt) — Pick one:**
- **A: Decisive Blow** *(Powerful Attack, 90s CD)* — Requires: 15+ Poise stacks. Dash forward 4 tiles. 5-hit combo on first enemy hit. Half of your Poise stacks are consumed before the combo; each consumed stack adds 2% to total combo damage (at 30 Poise: consume 15, +30% damage). You also gain Concentration equal to half the consumed stacks (max 5). Per-hit: apply 2 Fragile (replace-if-higher). Final hit: 2x DPS, knockback 3 tiles. Convert your edge into endurance.
- **B: Ceaseless Pressure** *(Passive)* — Every 5th consecutive melee hit on the same target is an automatic crit (bypassing the probability roll) and grants 5 Poise. Switching targets resets the count. Relentless discipline replaces fleeting focus.

**Decisive Blow — Details:**
- **Opener:** Dash forward 4 tiles in facing direction. First enemy hit becomes the main target.
- **Combo:** 5 hits. Rapid precision strikes.
- **Pre-combo:** Read current Poise stacks. Consume half (rounded down). Calculate damage multiplier: `1 + (consumed_stacks * 2 / 100)`. Grant Concentration = `min(5, round(consumed / 2))`. E.g., at 30 Poise: consume 15, +30% damage, gain 5 Concentration. At 50 Poise: consume 25, +50% damage, gain 5 Concentration.
- **Per-hit effect:** Each hit applies 2 Fragile (replace-if-higher) via `apply_lc_fragile(2)`.
- **Final hit:** Deals 2x DPS, knockback 3 tiles.
- **Condition:** More Poise stacks = more combo damage + more Concentration gained (capped at 5). You keep half your Poise for continued fighting.

**Implementation Notes:**
- Keen Edge: `COMSIG_MOB_ITEM_ATTACK` → `human_parent.apply_lc_poise(3)`.
- Opening Gambit: Track `var/mob/living/last_target` and `var/consecutive_count`. On `COMSIG_MOB_ITEM_ATTACK`: if `target != last_target` → `last_target = target`, `consecutive_count = 0`, `human_parent.apply_lc_poise(8)`. Else → `human_parent.apply_lc_poise(1)`, `consecutive_count++`.
- Precision Strike: `COMSIG_POISE_CRIT_ATTACKER` → `INVOKE_ASYNC` → `target.deal_damage(weapon.force * 0.15, weapon.damtype)` + `target.apply_lc_fragile(3)`.
- Momentum: Snapshot pre-crit poise stacks on `COMSIG_MOB_ITEM_ATTACK` (store `var/pre_crit_poise`). On `COMSIG_POISE_CRIT_ATTACKER` → calculate `lost = pre_crit_poise - current_poise` → `human_parent.apply_lc_poise(max(3, round(lost / 2)))`.
- Decisive Blow: `/datum/action/cooldown/decisive_blow` → toggle targeting → `InterceptClickOn` checks Poise >= 15. Read current poise stacks, `var/consumed = round(current_poise / 2)`. Remove `consumed` stacks via `apply_lc_poise(-consumed)`. Multiplier = `1 + (consumed * 2 / 100)`. Grant `human_parent.apply_lc_concentration(min(5, round(consumed / 2)))`. Apply cutscene_duel component + immobilize. 5 hits with `sleep()`. Per-hit: `target.apply_lc_fragile(2)`. Final hit: 2x DPS, `throw_at(target, 3)`.
- Ceaseless Pressure: Track `var/datum/weakref/combo_target` and `var/combo_hits = 0`. On `COMSIG_MOB_ITEM_ATTACK`: if `WEAKREF(target) != combo_target` → reset `combo_target = WEAKREF(target)`, `combo_hits = 0`. `combo_hits++`. At 5: `INVOKE_ASYNC(poise_effect, PROC_REF(do_poise_crit), target, user, weapon)` + `human_parent.apply_lc_poise(5)`, reset `combo_hits = 0`. No `buffs.dm` edits needed.

---

#### Branch 2: Skirmisher (Speed Focus)

**Theme:** Movement speed, hit-and-run tactics. The Skirmisher fights like quicksilver — closing distance in a flash, landing a burst of strikes, then pulling back before the opponent can react. Skills reward aggressive positioning and punish enemies who cannot keep up.

**T1 (1pt) — Pick one:**
- **A: Quick Step** — On landing a melee hit, gain +15% movement speed for 4 seconds (refreshes on hit). Also grants Poise stacks equal to your total active Cinq speed bonus / 5 (e.g., 15% speed = 3 Poise, 45% speed = 9 Poise). The faster you move, the sharper your edge.
- **B: First Strike** — Your first melee hit on a new target deals 20% bonus damage and grants 5 Poise. Only triggers once per target — switching to a different target resets it. The initiative belongs to whoever moves first.

**T2 (2pt) — Pick one:**
- **A: Flurry** — After landing 3 consecutive melee hits on the same target within 4 seconds, your 4th hit deals 50% bonus damage and grants 3 Poise stacks. Resets after the bonus hit triggers. Sustained aggression overwhelms the opponent's guard.
- **B: Rush Down** — On Poise crit, gain +30% movement speed for 4 seconds. A perfect strike fuels your momentum.

**T3 (3pt) — Pick one:**
- **A: Blade Dance** *(Powerful Attack, 90s CD)* — Dash to target from up to 5 tiles. 6-hit rapid combo. Between each hit, the user teleports to a random adjacent tile of the target (creating a "dancing around" visual). Per-hit: gain 2 Poise stacks. If the user has +15% or more speed bonus from Cinq skills when initiating, add 2 bonus hits (8 total). Final hit: 2x DPS, applies 5 Fragile (replace-if-higher), grants +30% speed for 5 seconds after combo ends. Speed is life.
- **B: Afterimage** *(Passive)* — Track steps taken. After moving 20+ steps, your next melee attack deals 35% bonus damage, grants 5 Poise, and resets the step counter. Additionally, 20% chance on being hit by melee to dodge the attack entirely (damage negated via `COMPONENT_MOB_DENY_DAMAGE`). You're never where they expect you to be.

**Blade Dance — Details:**
- **Opener:** Dash to target from up to 5 tiles. Target becomes the main target.
- **Combo:** 6 hits base (8 if Cinq speed buffs >= 15%). User `forceMove()`'d to `pick(get_adjacent_turfs(target))` between each hit.
- **Per-hit effect:** Each hit grants user 2 Poise stacks.
- **Final hit:** Deals 2x DPS, applies 5 Fragile (replace-if-higher), grants +30% speed for 5 seconds.
- **Condition:** Speed buffs from Cinq sources (Quick Step, Rush Down) are checked. If active, bonus hits are added.

**Implementation Notes:**
- Quick Step: `COMSIG_MOB_ITEM_ATTACK` → `owner.add_movespeed_modifier(/datum/movespeed_modifier/cinq_quick_step)` (multiplicative_slowdown = -0.15, variable = TRUE). Set/refresh timer via `addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/cinq_quick_step), 4 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)`. Then calculate Poise: sum the absolute `multiplicative_slowdown` values of active Cinq speed modifiers (quick_step = 0.15, disengage = 0.3, blade_dance_finisher = 0.3), multiply by 100, divide by 5 → `human_parent.apply_lc_poise(round(total_speed_percent / 5))`. E.g., Quick Step alone = 3 Poise, Quick Step + Disengage = 9 Poise.
- First Strike: Track `var/datum/weakref/last_target` and `var/first_strike_used`. On `COMSIG_MOB_ITEM_ATTACK`: if `WEAKREF(target) != last_target` → set `last_target = WEAKREF(target)`, `first_strike_used = FALSE`. If `!first_strike_used` → deal `weapon.force * 0.2` bonus damage via `INVOKE_ASYNC` → `target.deal_damage()` + `human_parent.apply_lc_poise(5)`, set `first_strike_used = TRUE`.
- Flurry: Track `var/datum/weakref/combo_target`, `var/combo_count`, `var/combo_last_time`. On `COMSIG_MOB_ITEM_ATTACK`: if same target (weakref match) and `world.time - combo_last_time < 4 SECONDS` → `combo_count++`. At 3: set `var/flurry_ready = TRUE`. On next `COMSIG_MOB_ITEM_ATTACK` while `flurry_ready` and same target → deal `weapon.force * 0.5` bonus damage via `INVOKE_ASYNC` → `target.deal_damage()` + `human_parent.apply_lc_poise(3)`, set `flurry_ready = FALSE`, reset count. Different target → reset all.
- Rush Down: `COMSIG_POISE_CRIT_ATTACKER` → `owner.add_movespeed_modifier(/datum/movespeed_modifier/cinq_rush_down)` (multiplicative_slowdown = -0.3, variable = TRUE). Set/refresh timer via `addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/cinq_rush_down), 4 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)`.
- Blade Dance: `/datum/action/cooldown/blade_dance` → toggle targeting → click target within 5 tiles. Apply cutscene_duel + immobilize. Check for Cinq speed modifiers → 6 or 8 hits. Between each hit: `human_parent.forceMove(pick(get_adjacent_turfs(target)))`. Per-hit: `human_parent.apply_lc_poise(2)`. Final hit: 2x DPS, `target.apply_lc_fragile(5)`, `owner.add_movespeed_modifier(/datum/movespeed_modifier/cinq_blade_dance_finisher)` (multiplicative_slowdown = -0.3) for 5s.
- Afterimage: Track `var/steps_taken = 0`. On `COMSIG_MOVABLE_MOVED` → `steps_taken++`. On `COMSIG_MOB_ITEM_ATTACK` → if `steps_taken >= 20` → deal `weapon.force * 0.35` bonus damage via `INVOKE_ASYNC` → `target.deal_damage()` + `human_parent.apply_lc_poise(5)`, reset `steps_taken = 0`. Dodge: `COMSIG_MOB_APPLY_DAMGE` → check `attack_type & ATTACK_TYPE_MELEE` → `prob(20)` → `to_chat` message → return `COMPONENT_MOB_DENY_DAMAGE`.

---

#### Branch 3: Fencer (Concentration Focus)

**Theme:** Sustain Poise through Concentration management and defensive counterplay. The Fencer is the patient combatant who builds an unshakeable foundation of Concentration, protecting their Poise stacks through careful timing and reactive techniques. Where the Duelist explodes in criticals and the Skirmisher dances in speed, the Fencer endures — their Poise never faltering because their Concentration never breaks.

**T1 (1pt) — Pick one:**
- **A: Composed Guard** — On taking melee damage, gain 2 Concentration stacks. 1s internal CD. Every blow absorbed deepens your focus.
- **B: Measured Response** — On landing a melee hit, gain 2 Poise stacks. Every 3rd hit, also gain 1 Concentration stack. A disciplined rhythm of attack and focus.

**T2 (2pt) — Pick one:**
- **A: Iron Focus** — Every 2nd Poise crit, gain 2 Concentration stacks. Discipline sharpens through repetition.
- **B: Riposte** — When hit by a melee attack, you have a `10 * (your Concentration stacks)`% chance to negate the damage entirely, move to a random adjacent tile, and consume 2 Concentration. At 10 Concentration (max) = 100% dodge. Your focus lets you read attacks before they land.

**T3 (3pt) — Pick one:**
- **A: Fencer's Finale** *(Powerful Attack, 90s CD)* — Requires: 8+ Concentration stacks. Enter a 3-second parry stance (immobilized, visible aura). During the stance, all melee damage against you is negated. If hit during the stance, immediately end the parry and dash to the attacker for the combo. If not hit, after 3 seconds dash to nearest enemy within 5 tiles. Deliver a 4-hit combo. All Concentration stacks are consumed; each consumed stack adds 5% to total combo damage. Per-hit: apply 2 Poise to self and 2 Defense Level Down to target. Final hit: 2x DPS, grants Protection stacks equal to half the consumed Concentration (rounded down). The patience pays off — or is punished.
- **B: Unshakeable** *(Passive)* — When your Poise stacks are halved by a crit (because you had no Concentration), immediately gain Concentration stacks equal to half the Poise stacks lost (minimum 2). Additionally, taking any damage while you have Poise grants 1 Concentration (2s CD). Your discipline adapts to recover from any setback.

**Fencer's Finale — Details:**
- **Opener:** Enter parry stance — immobilize self, add visible "guard" overlay. Register `COMSIG_MOB_APPLY_DAMGE` to block incoming melee hits. If hit: immediately cancel the 3s timer, store the attacker as the combo target, and proceed to combo phase. If not hit after 3 seconds: find nearest enemy within 5 tiles as the combo target.
- **Combo:** 4 hits. Dash to combo target.
- **Pre-combo:** Read and consume all Concentration stacks. Calculate damage multiplier: `1 + (consumed_stacks * 5 / 100)`. At 5 stacks = +25%, at 10 stacks (max) = +50%.
- **Per-hit effect:** Each hit grants user 2 Poise stacks and applies 2 Defense Level Down stacks to target.
- **Final hit:** Deals 2x DPS. Grants user Protection stacks = `round(consumed_concentration / 2)` (e.g., 10 consumed → 5 Protection).
- **Condition:** More Concentration stacks = more damage and more Protection reward. Getting hit during parry triggers an instant counter — enemies are punished for attacking you.

**Implementation Notes:**
- Composed Guard: `COMSIG_MOB_AFTER_APPLY_DAMGE` → check `attack_type & ATTACK_TYPE_MELEE` → 1s CD check → `human_parent.apply_lc_concentration(2)`.
- Measured Response: Track `var/hit_count = 0`. On `COMSIG_MOB_ITEM_ATTACK` → `human_parent.apply_lc_poise(2)` + `hit_count++`. If `hit_count >= 3` → `human_parent.apply_lc_concentration(1)`, reset `hit_count = 0`.
- Iron Focus: Track `var/crit_count = 0`. On `COMSIG_POISE_CRIT_ATTACKER` → `crit_count++`. If `crit_count >= 2` → `human_parent.apply_lc_concentration(2)`, reset `crit_count = 0`.
- Riposte: `COMSIG_MOB_APPLY_DAMGE` → check `attack_type & ATTACK_TYPE_MELEE` → get Concentration stacks via `human_parent.get_lc_concentration()` → `prob(10 * stacks)` → consume 2 Concentration via `human_parent.apply_lc_concentration(-2)` → `human_parent.forceMove(pick(get_adjacent_turfs(human_parent)))` → return `COMPONENT_MOB_DENY_DAMAGE`. No CD — Concentration cost is the limiter.
- Fencer's Finale: `/datum/action/cooldown/fencers_finale` → check Concentration >= 8. Phase 1 (parry): immobilize user, add guard overlay, store `var/parry_timer_id = addtimer(CALLBACK(src, PROC_REF(start_combo), null), 3 SECONDS, TIMER_STOPPABLE)`. Register `COMSIG_MOB_APPLY_DAMGE` → if melee → `COMPONENT_MOB_DENY_DAMAGE` + `deltimer(parry_timer_id)` + `INVOKE_ASYNC(src, PROC_REF(start_combo), attacker)`. `start_combo(target)` proc: remove overlay, unimmobilize, unregister parry signal. If `target` is null → find nearest enemy via `for(var/mob/living/L in range(5))` sorted by `get_dist`. Read + consume all Concentration. Multiplier = `1 + (consumed * 5 / 100)`. Dash to target, apply cutscene_duel + immobilize target. Execute 4 hits. Per-hit: `human_parent.apply_lc_poise(2)` + `target.apply_lc_defense_level_down(2)`. Final hit: 2x DPS, `apply_lc_protection(round(consumed / 2))`.
- Unshakeable: Two signal hooks. (1) Crit recovery: snapshot pre-crit Poise on `COMSIG_MOB_ITEM_ATTACK` (store `var/pre_crit_poise`). On `COMSIG_POISE_CRIT_ATTACKER` → if no Concentration existed at crit time → calculate `lost = pre_crit_poise - current_poise` → `human_parent.apply_lc_concentration(max(2, round(lost / 2)))`. (2) Damage generation: `COMSIG_MOB_AFTER_APPLY_DAMGE` → 2s CD → check owner has Poise stacks > 0 → `human_parent.apply_lc_concentration(1)`. No buffs.dm edits needed.

---

#### Cinq Branch Synergies

The 2-branch limit creates natural playstyle combos:

| Combo | Playstyle | Strength |
|---|---|---|
| **Duelist + Skirmisher** | "The Swashbuckler" — Build Poise rapidly (Keen Edge + Quick Step), explosive crits + speed. Blade Dance builds Poise too, offering two powerful attacks with different timing. | Highest burst damage potential. Aggressive, high-risk with two Powerful Attacks. |
| **Duelist + Fencer** | "The Master Duelist" — Poise + Concentration synergy. Iron Focus regenerates Concentration through crits. Ceaseless Pressure guarantees crits every 5 hits + restocks Poise. | Most sustainable crit engine. Best for extended 1v1 duels. |
| **Skirmisher + Fencer** | "The Untouchable" — Speed from Quick Step + Rush Down, dodge from Afterimage, damage negation from Riposte + Composed Guard. Two defensive tools that still build Poise. | Hardest to kill. Defense through mobility and counterplay. |

---

**Cinq Design Notes:**
- Core status effects are **Poise** (crit chance) and **Concentration** (crit protection), both already implemented in `code/datums/status_effects/buffs.dm:1250-1406`
- The two key signals `COMSIG_POISE_CRIT_ATTACKER` and `COMSIG_POISE_CRIT_TARGET` (defined in `code/__DEFINES/dcs/signals.dm:1089-1091`) have **no existing handlers** — all Cinq skill hooks are clean additions
- **Fragile** uses "replace-if-higher" stacking — skills apply specific stack counts, not additive
- **Speed boosts** use `add_movespeed_modifier()` with negative `multiplicative_slowdown` (-0.15 = 15% faster, -0.3 = 30% faster). New modifier datums needed: `/datum/movespeed_modifier/cinq_quick_step`, `/datum/movespeed_modifier/cinq_rush_down`, `/datum/movespeed_modifier/cinq_blade_dance_finisher`
- **T3 Powerful Attacks** follow the tiantui flurry pattern (`thumb.dm`): cutscene combo with immobilize, multi-hit DPS-based damage, cutscene_duel component (separate from cinq_duel), conditional bonuses
- Each hit deals weapon DPS (`force * force_multiplier * 1.25 / attack_speed`) so all weapons are equally viable
- The **cinq_duel** component is distinct from **cutscene_duel** — cinq_duel is for formal PvP duels (longer, HP thresholds, healing), cutscene_duel is for brief powerful attack animations
- Skills **only function while on an active contract** — no contract = no abilities
- The **glove throw** for forced duels uses `throw_at()` pattern with a `/obj/item/cinq_glove` projectile
- Duel system references `lcl_duel.dm` for the `addtimer(CALLBACK, 1)` heal delay workaround
- **Concentration max_stacks** must be changed from 20 → 10 in `buffs.dm:1367`
- **Ceaseless Pressure** and **Unshakeable** are both purely signal-driven — no `buffs.dm` edits needed
- Poise's `active_this_period` flag (buffs.dm:1263) is the key var for understanding decay behavior

---

## Files to Create / Modify

### New Files
- `ModularLobotomy/associations/association_exp.dm` - EXP tracking component (mirrors `artistic_exp.dm`)
- `ModularLobotomy/associations/association_skill_tree.dm` - Skill tree datum + GLOB definitions (mirrors `ring_skill_tree.dm`)
- `ModularLobotomy/associations/skills/_association_skills.dm` - Base association skill component (mirrors `_schools.dm`)
- `ModularLobotomy/associations/skills/zwei/guardian.dm` - Zwei Guardian branch skills (Iron Stance, Aggressive Guard, Shieldbreaker, Steady Footing, Retaliating Onslaught, Unbreakable)
- `ModularLobotomy/associations/skills/zwei/territory.dm` - Zwei Territory Protection branch skills (Vigilant Presence, Warden's Watch, Law and Order, Fortified Position, Earthshatter, Iron Curtain)
- `ModularLobotomy/associations/skills/zwei/client.dm` - Zwei Client Protection branch skills (Designated Ward, Threatening Presence, Bodyguard's Instinct, Shared Resilience, Guardian's Wrath, Lifelink)
- `ModularLobotomy/associations/skills/_cutscene_duel.dm` - Shared cutscene duel component (prevents outside damage during powerful attacks)
- `ModularLobotomy/associations/skills/_designate_ally.dm` - Universal ally designation action (all associations)
- `ModularLobotomy/associations/skills/zwei/mark_action.dm` - Mark for Protection targeted action (shared by T1a and T1b of Client branch)
- `ModularLobotomy/associations/skills/seven/analyst.dm` - Seven Analyst branch skills (Case File, Profiling, Exploit Weakness, Patient Hunter, Dossier Complete, Surveillance Network)
- `ModularLobotomy/associations/skills/seven/coordinator.dm` - Seven Coordinator branch skills (Intel Briefing, Weak Point Analysis, Comprehensive Report, Disinformation, Full Exposure, Undermining Presence)
- `ModularLobotomy/associations/skills/seven/operative.dm` - Seven Operative branch skills (Shadow Step, Quick Assessment, Smoke and Mirrors, Pressure Points, Surgical Strike, Ghost Protocol)
- `ModularLobotomy/associations/skills/seven/mark_action.dm` - Mark Target pointed spell action (Analyst branch)
- `ModularLobotomy/associations/skills/seven/investigation_items.dm` - Seven Recorder, Recorder Receiver, Seven Camera, Backpack Scanner, Seven Spyglass Kit
- `ModularLobotomy/associations/skills/seven/intel_report.dm` - Intel Report Paper, Cargo Report, `/datum/seven_intel_snapshot`, validation logic
- `ModularLobotomy/associations/skills/seven/dossier.dm` - Investigation Dossier item + datum
- `tgui/packages/tgui/interfaces/SevenDossier.js` - Dossier TGUI viewer (report list by subject, stats)
- `ModularLobotomy/associations/skills/dieci/` - Dieci skill tree branch files (TBD)
- `ModularLobotomy/associations/skills/cinq/duelist.dm` - Cinq Duelist branch skills (Keen Edge, Opening Gambit, Precision Strike, Momentum, Decisive Blow, Ceaseless Pressure)
- `ModularLobotomy/associations/skills/cinq/skirmisher.dm` - Cinq Skirmisher branch skills (Quick Step, First Strike, Flurry, Rush Down, Blade Dance, Afterimage)
- `ModularLobotomy/associations/skills/cinq/fencer.dm` - Cinq Fencer branch skills (Composed Guard, Measured Response, Iron Focus, Riposte, Fencer's Finale, Unshakeable)
- `ModularLobotomy/associations/skills/cinq/duel_system.dm` - `/datum/cinq_duel_instance`, `/datum/component/cinq_duel`, Challenge to Duel action, Throw the Glove action, `/obj/item/cinq_glove`
- `ModularLobotomy/associations/contracts/contract_datum.dm` - Base contract datum
- `ModularLobotomy/associations/contracts/contract_terminal.dm` - Physical terminal + TGUI for Hana
- `ModularLobotomy/associations/contracts/contract_actions.dm` - Contract actions (civilian offer, fixer accept/decline, view)
- `ModularLobotomy/associations/contracts/contract_citymap.dm` - City map generation datum for location picking
- `tgui/packages/tgui/interfaces/AssociationSkillTree.js` - Skill tree TGUI interface
- `tgui/packages/tgui/interfaces/ContractTerminal.js` - Hana contract creation/management TGUI (with embedded city map)
- `tgui/packages/tgui/interfaces/ContractBoard.js` - Fixer contract browsing/accepting TGUI
- `tgui/packages/tgui/interfaces/ContractCityMap.js` - City map TGUI component (reusable)

### Modified Files
- `ModularLobotomy/associations/association_beacon.dm` - Remove Liu box, add Dieci/Cinq boxes, update gear spawns
- `code/modules/jobs/job_types/trusted_players/association/col_association.dm` - Hook EXP component + contract actions into job spawning
- `code/modules/jobs/job_types/trusted_players/hana.dm` - Add contract terminal verb/action, expand Hana tools
- `ModularLobotomy/associations/skills/skillgranter.dm` - Deprecate or remove old skill book system for reworked associations

### Removed / Deprecated
- `ModularLobotomy/associations/skills/liu/` - All Liu skill files (shelved)
- Old Zwei/Seven skillgranter subtypes (replaced by skill tree)

---

## Implementation Order

1. Create contract system (contract datum, terminal, actions, TGUI)
2. Update Hana role with contract terminal access
3. Create base `association_exp` and `association_skill` components (with contract integration)
4. Create `association_skill_tree` datum with GLOB definitions (empty trees initially)
5. Create `AssociationSkillTree.js` TGUI (adapt from `RingSkillTree.js`)
6. Implement Zwei skill tree + contract EXP hooks
7. Implement Seven skill tree + contract EXP hooks
8. Implement Dieci skill tree + gimmick + gear
9. Implement Cinq skill tree + gimmick + gear
10. Update `association_beacon.dm` (remove Liu, add new associations)
11. Update job spawning to grant EXP component + contract actions + skill tree action
12. Remove old skill book system for affected associations
13. Testing and balance pass
