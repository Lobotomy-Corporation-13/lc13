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

2. **Seven Camera** (`/obj/item/camera/seven_intel`) — Modified camera (subtype of `/obj/item/camera`) that creates intel snapshots. When a photo is taken, the camera stores a `/datum/seven_intel_snapshot` containing ground truth data: area name (from `get_area_name()`), mob names (from `mobs_seen`), and held items (from target's `held_items`). This snapshot is used to validate reports later.

3. **Intel Report Paper** (`/obj/item/paper/intel_report`) — Pre-formatted paper with form fields (using the existing `form_fields` system on `/obj/item/paper`). Created by using a Seven Camera photo on a blank Intel Report form. The report presents questions the fixer must answer:
   - "Subject Name:" (text field)
   - "Area Observed:" (text field)
   - "Individuals Present:" (text field, comma-separated names)
   - "Items Carried:" (text field, comma-separated items)
   The server validates answers against the snapshot data using `findtext()` for case-insensitive fuzzy matching. Filing the report on the dossier awards EXP: **5 base + up to 10 accuracy bonus** per filed report. Cooldown: one report per target per 2 minutes.

4. **Backpack Scanner** (`/obj/item/seven_scanner`) — Handheld device. Use on an adjacent carbon mob to scan their worn backpack/bag contents. Takes 3 seconds (`do_after`) and is visible to the target ("X scans Y's belongings..."). Records actual `contents` list of the target's storage item. The fixer then fills out a **Cargo Report** (variant of Intel Report) listing what the target was carrying. Validation and EXP: **3 base + up to 5 accuracy bonus**. Same 2-minute per-target cooldown.

5. **Seven Spyglass Kit** (`/obj/item/storage/box/seven_spyglass`) — Reuses the existing spy bug + spy glasses system (`code/game/objects/items/devices/spyglasses.dm`) with a Seven aesthetic. While actively observing through the spyglass popup window, the fixer earns **1 EXP per 30 seconds** if on contract.

6. **Investigation Dossier** (`/obj/item/seven_dossier`) — Physical storage item (clipboard/folder) with a TGUI interface (`SevenDossier.js`). Stores filed reports indexed by subject name. Each entry shows: subject name, area, timestamp, accuracy score. Summary statistics: total reports filed, total EXP earned from reports, most-observed subject. Reports are added by using a completed Intel Report or Cargo Report on the dossier.

7. **Recorder Receiver** (`/obj/item/seven_receiver`) — An earpiece/handheld radio that links to deployed Seven Recorders for live listening.

   **Live Listening:** Use the Receiver in-hand (`attack_self()`) to open a TGUI panel listing all of the fixer's active recorders (floor-placed and item-attached). Each entry shows: recorder index, deployment type (floor/item), host item name or turf location, lines recorded, and tape remaining. Select a recorder to **tune in** — while tuned in, the fixer hears everything the recorder's `Hear()` captures in real-time, relayed as `to_chat()` messages prefixed with `[RECORDER #N]:`. Only one recorder can be listened to at a time. The fixer can switch between recorders or stop listening from the panel.

   **Note:** Recorder retrieval is handled directly — floor recorders are picked up by clicking, and item-attached recorders are removed via the `[Remove]` button in the host item's examine text (see item 1).

   **Implementation Notes:**
   - Stores `var/list/linked_recorders` referencing the fixer's deployed `/obj/item/seven_recorder` instances.
   - Live listening: When tuned in, registers the receiver as a listener on the recorder's `Hear()` relay. Each message the recorder captures is forwarded via `to_chat(owner, span_notice("[RECORDER #[index]]: [message]"))`.
   - TGUI panel (`SevenReceiver.js` or simple `ui_interact`): Shows list of recorders with status (floor/item-attached, location/host item name, lines recorded, tape remaining). Toggle buttons for listen/stop.

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
- **Defense Level Down** (team enabler): Diminishing returns vulnerability (`stacks/(stacks+25)*100`%) — makes the target easier to kill for everyone
- **Offense Level Down** (suppression): Reduces the target's damage output, protecting your team while you set up

The branches are designed so that:
- **Analyst** focuses on Rupture (build + detonate on a single target)
- **Coordinator** focuses on Defense Level Down + Offense Level Down (team debuffs)
- **Operative** focuses on Rupture + Fragile (burst damage windows)

Mixing branches gives access to all four effects, rewarding the 2-branch investment limit.

#### Powerful Attack System (T3 Skills)

Each branch has one T3 that is a **Powerful Attack** — a cutscene-style multi-hit combo following the same pattern as Zwei's powerful attacks (reference: tiantui flurry in `thumb.dm`). All Seven powerful attacks deal **BLACK damage** (matching their weapon damage type). Same shared mechanics apply: weapon-agnostic, DPS-based damage (`force * force_multiplier * 1.25 / attack_speed`), duel component, weapon lock, immobilization, null/distance checks.

---

#### Branch 1: Analyst (Target Elimination)

**Theme:** Mark one target. Build rupture. Execute with precision. The field agent who gathers intel on a single mark, then eliminates them with surgical strikes. Every hit on your mark feeds the dossier — and the dossier feeds the kill.

**Marking System:** T1 in this branch grants the **Mark Target** action (pointed spell pattern, `InterceptClickOn()`). One mark at a time. Re-marking removes old mark. Mark persists until manually removed, re-marked, or target dies. This is **separate** from the Seven weapon's existing "hit 7 times to store target" mechanic — both systems coexist independently.

**T1 (1pt) — Pick one:**
- **A: Case File** — Mark a target. Your attacks against the marked target apply 2 Rupture stacks. Attacks against non-marked targets apply 0 Rupture. The mark focuses all your investigation on a single subject.
- **B: Profiling** — Mark a target. While you are within 7 tiles of the marked target, gain 1 Offense Level Up stack every 5 seconds (max 10). All stacks are lost when the mark changes or the target moves out of range for more than 10 seconds. Rewards staying near and observing your target.

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
- Case File: `COMSIG_MOB_ITEM_ATTACK` → check if `target == marked_target` → `target.apply_lc_rupture(2)`. No rupture on non-marks.
- Profiling: Process timer every 5s → range check to marked_target → `human_parent.apply_lc_offense_level_up(1)`. Track `stacks_granted` for cleanup on mark change. 10s out-of-range timer via `addtimer`.
- Exploit Weakness: `COMSIG_MOB_ITEM_ATTACK` → if `target == marked_target` + CD clear → `target.apply_lc_defense_level_down(2)`. Register `COMSIG_MOB_AFTER_APPLY_DAMGE` on marked target → detect rupture-source damage (`ATTACK_TYPE_STATUS`) → `target.apply_lc_fragile(3)`.
- Patient Hunter: `COMSIG_MOB_ITEM_ATTACK` → check marked_target rupture stacks → if >= 10: `extra_damage += 25` → if >= 20: `extra_damage_black += 15`. Clean up via `COMSIG_MOB_ITEM_AFTERATTACK`.
- Dossier Complete: `/datum/action/cooldown/dossier_complete` → toggle targeting → `InterceptClickOn` checks `target == marked_target` and rupture >= 10. Read + clear rupture stacks. Apply duel component + immobilize. 4 hits with `sleep()`, damage = `DPS * (1 + stacks * 2 / 100) / 4`. Per-hit: `target.apply_lc_offense_level_down(2)`. Final hit: 2x, knockback, fragile.
- Surveillance Network: Extend mark to `marked_target_secondary`. Hook `COMSIG_MOB_AFTER_APPLY_DAMGE` on both marks → detect rupture BRUTE (`ATTACK_TYPE_STATUS`) → deal 50% as BLACK to other mark if in 15 tiles. `COMSIG_MOB_DEATH` on marks → `other_mark.apply_lc_rupture(5)`.

---

#### Branch 2: Coordinator (Debuff Support)

**Theme:** The handler who knows every enemy's weak point and shares that intel with the team. AoE vulnerability debuffs, ally-benefiting effects. Seven doesn't always need to swing the blade themselves — sometimes the most effective retribution comes from telling your allies exactly where to hit.

**T1 (1pt) — Pick one:**
- **A: Intel Briefing** — Designated allies within 5 tiles of you deal attacks that apply 1 Rupture stack to their targets. 2s internal CD per ally. Your briefings turn every ally into a Seven operative.
- **B: Weak Point Analysis** — Your attacks apply 2 Defense Level Down stacks to the target (1s internal CD). When you hit a target that already has Defense Level Down, nearby designated allies (5 tiles) gain +10% damage for 3 seconds (refreshing). Your analysis exposes openings for the team.

**T2 (2pt) — Pick one:**
- **A: Comprehensive Report** — Every 15 seconds, the enemy with the highest Rupture stacks within 8 tiles automatically receives 3 Fragile stacks and 2 Defense Level Down stacks. A brief visual highlight marks the chosen target. Your detailed reports prioritize the most-investigated target.
- **B: Disinformation** — Your attacks apply 2 Offense Level Down stacks to the target (1.5s internal CD). Targets afflicted with Offense Level Down deal 10% less damage to your designated allies. Your misinformation undermines the enemy's confidence.

**T3 (3pt) — Pick one:**
- **A: Full Exposure** *(Powerful Attack, 120s CD)* — AoE debuff slam in a 4-tile radius centered on self. All enemies hit receive 5 Fragile + 3 Defense Level Down + 3 Offense Level Down. Then, the closest enemy becomes the main target for a 3-hit combo (BLACK DPS). Per-hit: applies 3 Rupture stacks. For each designated ally within 6 tiles at combo start, all debuff stacks applied by this attack are increased by 1 (up to +3 with 3 allies). Final hit: force-triggers all existing Rupture on the target immediately (bypasses 5s activation delay). You've exposed everything — the enemy has nowhere to hide.
- **B: Undermining Presence** *(Passive Aura)* — While on contract, enemies within 5 tiles of you lose 1 Defense Level Up stack and 1 Offense Level Up stack every 5 seconds (stripping enemy buffs). Designated allies within 5 tiles who attack targets affected by any debuff (Rupture, Fragile, DLD, OLD) heal for 3% of damage dealt. Your mere presence erodes enemy strength.

**Full Exposure — Details:**
- **Opener:** AoE ground slam centered on user, 4-tile radius. All enemies in range receive 5 Fragile + 3 DLD + 3 OLD. Closest enemy hit becomes the main target.
- **Combo:** 3 hits. Each hit deals standard DPS as BLACK damage.
- **Per-hit effect:** Each hit applies 3 Rupture stacks to the main target.
- **Condition:** Count designated allies within 6 tiles at combo start. For each ally (up to 3), all debuff stacks from this attack increase by 1 (e.g., with 2 allies: 7 Fragile + 5 DLD + 5 OLD opener, 5 Rupture per hit).
- **Final hit:** Force-triggers all Rupture on target via `INVOKE_ASYNC` calling the rupture status effect's `trigger_rupture()` proc directly. Bypasses the 5-second activation delay.

**Implementation Notes:**
- Intel Briefing: Register `COMSIG_MOB_ITEM_ATTACK` on designated allies within range (refresh tracked list every 5s via process). On ally attack, if CD clear: `target.apply_lc_rupture(1)`. Track `ally_cooldowns[ally_ref] = world.time`.
- Weak Point Analysis: `COMSIG_MOB_ITEM_ATTACK` → `target.apply_lc_defense_level_down(2)` with 1s CD. Check if target had DLD before hit → iterate designated allies in `range(5)` → apply timed `extra_damage += 10` buff via `addtimer` + CALLBACK cleanup (3s).
- Comprehensive Report: Process timer every 15s → iterate `range(8)` for hostile mobs → find highest rupture stacks → `target.apply_lc_fragile(3)` + `target.apply_lc_defense_level_down(2)`. Brief highlight via `new /obj/effect/temp_visual/` on target turf.
- Disinformation: `COMSIG_MOB_ITEM_ATTACK` → `target.apply_lc_offense_level_down(2)` with 1.5s CD. For ally protection: register `COMSIG_MOB_APPLY_DAMGE` on designated allies → when ally takes damage, check attacker for OLD stacks → if yes, reduce damage by 10% via multiplier.
- Full Exposure: `/datum/action/cooldown/full_exposure` → no targeting needed (AoE from self). AoE debuffs in `range(4)`. Count allies via `is_designated_ally()` in `range(6)`. Pick closest hostile → duel component + immobilize → 3 hits. Final hit: find rupture status effect on target → `INVOKE_ASYNC(rupture_effect, PROC_REF(trigger_rupture))`.
- Undermining Presence: Process timer every 5s → iterate hostiles in `range(5)` → check for DLU/OLU status effects → `add_stacks(-1)`. For ally healing: register `COMSIG_MOB_ITEM_ATTACK` on designated allies → check target for any debuffs → `INVOKE_ASYNC` → `ally.adjustBruteLoss(-damage * 0.03)`.

---

#### Branch 3: Operative (Mobility + Burst)

**Theme:** The direct action specialist. Move fast, hit hard, and exploit every gap in the enemy's defenses. While the Analyst builds a case and the Coordinator briefs the team, the Operative is already behind enemy lines. Evolves the old Quick Getaway and Exploit the Gap skills into a proper mobility/ambush specialization.

**T1 (1pt) — Pick one:**
- **A: Shadow Step** — After standing still for 2+ seconds, your next attack within 1 second of moving deals 20% bonus damage and applies 2 Rupture stacks. 3s internal CD. Patience rewards the predator.
- **B: Quick Assessment** — Hitting a new target (different from last hit) applies 3 Rupture stacks. Hitting the same target consecutively increases your attack speed by 10% (stacking up to 3 times / 30%). Switching targets resets the speed bonus. Adapts to whatever the situation demands.

**T2 (2pt) — Pick one:**
- **A: Smoke and Mirrors** *(Active, 30s CD)* — Dash 4 tiles forward in facing direction, drop a 3-tile smoke cloud at your origin, and gain +25% movement speed for 4 seconds. During the speed buff, your attacks apply 1 additional Rupture stack per hit. Enter fast, leave confusion behind.
- **B: Pressure Points** — Your attacks against targets with 5+ Rupture stacks have a 30% chance to apply 2 Fragile stacks. Your attacks against targets with Fragile active apply 1 additional Rupture stack. Creates a self-reinforcing feedback loop between Rupture and Fragile — the more you hit, the worse it gets for them.

**T3 (3pt) — Pick one:**
- **A: Surgical Strike** *(Powerful Attack, 90s CD)* — Requires: target has at least one of Rupture, Fragile, Defense Level Down, or Offense Level Down. Vanish (brief invisibility, 0.5s), then dash to target from up to 5 tiles and deliver a 5-hit combo (BLACK DPS). For each unique debuff type on the target, each hit deals 15% more damage (max +60% with all four debuffs). Per-hit: apply 2 Rupture stacks. First 3 hits: also apply 1 Fragile each. Final hit: 2x DPS, knockback 2 tiles, and if target has 15+ Rupture stacks, instantly trigger all Rupture (bypass 5s activation delay). The investigation's findings dictate the severity of the sentence.
- **B: Ghost Protocol** *(Passive, 5min CD)* — When you take lethal damage, instead of dying: become invisible and intangible for 3 seconds, heal to 50% max HP, gain +40% movement speed for 6 seconds, and your next 3 attacks within 10 seconds each deal 30% bonus damage and apply 5 Rupture stacks. A good operative always has an exit strategy.

**Surgical Strike — Details:**
- **Opener:** Brief invisibility (`alpha = 0`, 0.5s), then dash to target from up to 5 tiles. Must have at least one debuff (Rupture/Fragile/DLD/OLD).
- **Combo:** 5 hits. Fast, precise strikes exploiting every identified weakness.
- **Per-hit effect:** Each hit applies 2 Rupture stacks. First 3 hits also apply 1 Fragile each.
- **Condition:** Count unique debuff types on target. Per debuff: +15% damage to all hits. With all 4 debuffs active: +60% total damage. This rewards setting up debuffs before the finisher.
- **Final hit:** Deals 2x DPS, knockback 2 tiles. If target has 15+ Rupture stacks, force-trigger all Rupture (bypass 5s delay) via `trigger_rupture()`.

**Implementation Notes:**
- Shadow Step: Track `last_move_time` via `COMSIG_MOVABLE_MOVED`. When `world.time - last_move_time >= 2 SECONDS`, set `ambush_ready = TRUE`. On `COMSIG_MOB_ITEM_ATTACK`, if `ambush_ready` and `world.time - last_move_time <= 1 SECOND`: `extra_damage += 20`, `target.apply_lc_rupture(2)`, reset, 3s CD. Clean via afterattack.
- Quick Assessment: Track `last_attacked_target`. On `COMSIG_MOB_ITEM_ATTACK`: if different target → `target.apply_lc_rupture(3)`, reset `consecutive_count`. If same → `consecutive_count++`, apply `next_move_modifier` for attack speed. Cap at 3.
- Smoke and Mirrors: `/datum/action/cooldown/smoke_and_mirrors`. On activate: record origin turf, `forceMove` 4 tiles in facing direction (wall checks), spawn smoke via `datum/effect_system/smoke_spread`. Apply movespeed modifier 4s. Set `bonus_rupture = TRUE` for 4s. `COMSIG_MOB_ITEM_ATTACK` checks flag → `target.apply_lc_rupture(1)`.
- Pressure Points: `COMSIG_MOB_ITEM_ATTACK` → check rupture stacks >= 5 → `prob(30)` → `target.apply_lc_fragile(2)`. Check fragile → `target.apply_lc_rupture(1)`.
- Surgical Strike: `/datum/action/cooldown/surgical_strike` → toggle targeting → check any debuff. `alpha = 0` for 0.5s → dash → duel component → immobilize. Count debuff types for multiplier. 5 hits. Final hit: 2x DPS, knockback, conditional `trigger_rupture()`.
- Ghost Protocol: `COMSIG_MOB_APPLY_DAMGE` → lethal check → `COMPONENT_MOB_DENY_DAMAGE`. Heal to 50%. `alpha = 0`, `TRAIT_NOINTERACT_1` for 3s. Movespeed modifier 6s. `ghost_attacks_remaining = 3`. On `COMSIG_MOB_ITEM_ATTACK` while remaining > 0: `extra_damage += 30`, `target.apply_lc_rupture(5)`, decrement. Timers clean up at 3s/6s/10s.

---

#### Seven Branch Synergies

The 2-branch limit creates natural playstyle combos:

| Combo | Playstyle | Strength |
|---|---|---|
| **Analyst + Coordinator** | "The Mastermind" — Mark a target, build rupture personally while exposing them to the whole team's attacks via Intel Briefing. Dossier Complete for solo execution, Full Exposure for team fights. | Best for mixed solo/team play. Maximum debuff stacking on a single priority target. |
| **Analyst + Operative** | "The Assassin" — Mark, build rupture via mobility and ambush, then cash in with Dossier Complete or Surgical Strike. Pure single-target elimination. | Highest burst damage against one enemy. The quintessential Seven hitman. |
| **Coordinator + Operative** | "The Saboteur" — Debuff everything in range with team-wide vulnerability, then move fast and create chaos with Surgical Strike. Less focused on one target but more versatile. | Best for disruption and group fights. The Seven field commander who leads from the front. |

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

### Dieci (NEW) - "The ???"

**Theme:**
<!-- TODO: Define Dieci's combat/RP theme -->

**Gimmick / EXP Source:**
<!-- TODO: Define Dieci's EXP-earning gimmick -->

**Skill Tree:**

| Tier | Choice A | Choice B |
|------|----------|----------|
| T1 | <!-- TODO --> | <!-- TODO --> |
| T2 | <!-- TODO --> | <!-- TODO --> |
| T3 | <!-- TODO --> | <!-- TODO --> |

**Design Notes:**
<!-- TODO -->

---

### Cinq (NEW) - "The ???"

**Theme:**
<!-- TODO: Define Cinq's combat/RP theme -->

**Gimmick / EXP Source:**
<!-- TODO: Define Cinq's EXP-earning gimmick -->

**Skill Tree:**

| Tier | Choice A | Choice B |
|------|----------|----------|
| T1 | <!-- TODO --> | <!-- TODO --> |
| T2 | <!-- TODO --> | <!-- TODO --> |
| T3 | <!-- TODO --> | <!-- TODO --> |

**Design Notes:**
<!-- TODO -->

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
- `ModularLobotomy/associations/skills/cinq/` - Cinq skill tree branch files (TBD)
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
