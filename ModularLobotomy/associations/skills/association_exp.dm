/// Component that tracks association EXP, skill points, branch investments, and ally designations.
/// Attached to each registered association member (Director, Veteran, Associate).
/// Mirrors the ring skill system's /datum/component/artistic_exp pattern.
/datum/component/association_exp
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// The association type (ASSOCIATION_ZWEI, ASSOCIATION_SEVEN, etc.)
	var/association_type
	/// The member's rank ("director", "veteran", "associate")
	var/rank
	/// Reference to the squad datum this member belongs to
	var/datum/association_squad/squad
	/// Total cumulative EXP earned
	var/total_exp = 0
	/// Number of skill points currently available to spend
	var/skill_points_available = 0
	/// Number of skill points already spent
	var/skill_points_spent = 0
	/// Total skill points ever earned (available + spent)
	var/total_skill_points = 0
	/// List of branch names this player has invested in (max ASSOCIATION_MAX_BRANCHES)
	var/list/invested_branches = list()
	/// List of mobs designated as allies (for ally-targeting skills)
	var/list/mob/living/designated_allies = list()
	/// Reference to the granted skill tree action
	var/datum/action/innate/association_skill_tree/tree_action
	/// Reference to the granted designate ally action
	var/datum/action/cooldown/designate_ally/ally_action
	/// Last carbon mob that attacked this member (for death-trigger distress)
	var/mob/living/carbon/last_carbon_attacker
	/// world.time of the last carbon attack (for death-trigger distress)
	var/last_carbon_attack_time = 0
	/// Zwei combat EXP: last time damage-absorbed EXP was awarded
	var/zwei_damage_exp_time = 0
	/// Zwei combat EXP: last time combat-hit EXP was awarded
	var/zwei_hit_exp_time = 0

/datum/component/association_exp/Initialize(assoc_type, _rank, datum/association_squad/_squad)
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE

	association_type = assoc_type
	rank = _rank
	squad = _squad

	// Grant HUD action buttons
	tree_action = new()
	tree_action.Grant(parent)
	// Only association roles (director, veteran, associate) can designate allies
	if(rank == "director" || rank == "veteran" || rank == "associate")
		ally_action = new()
		ally_action.Grant(parent)

	// Apply the ally indicator display effect (visible only to team members)
	var/mob/living/L = parent
	L.apply_status_effect(/datum/status_effect/display/ally_indicator)

	// Register distress check signals (damage + death)
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_distress_check))
	RegisterSignal(parent, COMSIG_LIVING_DEATH, PROC_REF(on_distress_death))

	// Zwei combat EXP hooks
	if(association_type == ASSOCIATION_ZWEI)
		RegisterSignal(parent, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(on_zwei_damage_taken))
		RegisterSignal(parent, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_zwei_combat_hit))

/datum/component/association_exp/Destroy()
	UnregisterSignal(parent, list(COMSIG_MOB_APPLY_DAMGE, COMSIG_LIVING_DEATH, COMSIG_MOB_AFTER_APPLY_DAMGE, COMSIG_MOB_ITEM_ATTACK))
	last_carbon_attacker = null
	if(tree_action)
		QDEL_NULL(tree_action)
	if(ally_action)
		QDEL_NULL(ally_action)
	squad = null
	designated_allies.Cut()
	invested_branches.Cut()
	return ..()

/// Add EXP and check for skill point thresholds. Returns the number of new skill points earned.
/datum/component/association_exp/proc/modify_exp(amount)
	if(amount <= 0)
		return 0

	var/old_exp = total_exp
	total_exp += amount

	// Check how many thresholds we've crossed
	var/new_points = 0
	var/list/thresholds = GLOB.association_exp_thresholds
	for(var/i in 1 to length(thresholds))
		var/threshold = thresholds[i]
		if(old_exp < threshold && total_exp >= threshold)
			new_points++

	if(new_points > 0)
		skill_points_available += new_points
		total_skill_points += new_points
		to_chat(parent, span_nicegreen("You have earned [new_points] new skill point[new_points > 1 ? "s" : ""]! Open your Skill Tree to spend [total_skill_points > 1 ? "them" : "it"]."))

	return new_points

/// Spend skill points. Returns TRUE if successful, FALSE if not enough points.
/datum/component/association_exp/proc/spend_skill_point(cost)
	if(skill_points_available < cost)
		return FALSE
	skill_points_available -= cost
	skill_points_spent += cost
	return TRUE

/// Check if the player can invest in a new branch (max ASSOCIATION_MAX_BRANCHES)
/datum/component/association_exp/proc/can_invest_in_branch(branch_name)
	if(branch_name in invested_branches)
		return TRUE // Already invested, can continue
	if(length(invested_branches) >= ASSOCIATION_MAX_BRANCHES)
		return FALSE // At capacity
	return TRUE

/// Mark a branch as invested. Returns TRUE if successful.
/datum/component/association_exp/proc/invest_in_branch(branch_name)
	if(branch_name in invested_branches)
		return TRUE // Already invested
	if(length(invested_branches) >= ASSOCIATION_MAX_BRANCHES)
		return FALSE
	invested_branches += branch_name
	return TRUE

/// Check if a mob is a designated ally
/datum/component/association_exp/proc/is_designated_ally(mob/living/L)
	return (L in designated_allies)

/// Returns the next EXP threshold the player hasn't reached, or 0 if all reached
/datum/component/association_exp/proc/get_next_threshold()
	var/list/thresholds = GLOB.association_exp_thresholds
	for(var/i in 1 to length(thresholds))
		if(total_exp < thresholds[i])
			return thresholds[i]
	return 0

/// Distress check — triggers emergency skill access when a fixer drops below 50% HP from a carbon attacker.
/datum/component/association_exp/proc/on_distress_check(datum/signal_source, damage, damagetype, def_zone, atom/damage_source)
	SIGNAL_HANDLER
	if(!squad)
		return
	// Track last carbon attacker for death-trigger distress
	if(iscarbon(damage_source))
		last_carbon_attacker = damage_source
		last_carbon_attack_time = world.time
	else
		return
	// Already on contract — skills active, no need for distress
	if(squad.is_on_contract())
		return
	// Check HP would drop below threshold
	var/mob/living/L = parent
	var/projected_hp = L.health - damage
	if(projected_hp >= L.maxHealth * CONTRACT_DISTRESS_HP_THRESHOLD)
		return
	// Check per-victim cooldown
	var/victim_ref = ref(L)
	if(squad.distress_cooldowns[victim_ref] && world.time < squad.distress_cooldowns[victim_ref] + CONTRACT_DISTRESS_COOLDOWN)
		return
	// Trigger distress for the entire squad
	INVOKE_ASYNC(squad, TYPE_PROC_REF(/datum/association_squad, trigger_distress), L, damage_source)

/// Distress death check — triggers emergency when a fixer dies from a recent carbon attack.
/datum/component/association_exp/proc/on_distress_death(datum/signal_source, gibbed)
	SIGNAL_HANDLER
	if(!squad)
		return
	// Only trigger if recently attacked by a carbon (within 10 seconds)
	if(!last_carbon_attacker || QDELETED(last_carbon_attacker))
		return
	if(world.time > last_carbon_attack_time + 10 SECONDS)
		return
	// Check per-victim cooldown
	var/mob/living/L = parent
	var/victim_ref = ref(L)
	if(squad.distress_cooldowns[victim_ref] && world.time < squad.distress_cooldowns[victim_ref] + CONTRACT_DISTRESS_COOLDOWN)
		return
	// Trigger distress for the entire squad
	INVOKE_ASYNC(squad, TYPE_PROC_REF(/datum/association_squad, trigger_distress), L, last_carbon_attacker)

// ============================================================
// Zwei Combat EXP Hooks
// ============================================================

/// Zwei: Award EXP when taking damage while on contract. 1 second cooldown.
/datum/component/association_exp/proc/on_zwei_damage_taken(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(!squad || !squad.is_on_contract())
		return
	if(world.time < zwei_damage_exp_time + 1 SECONDS)
		return
	zwei_damage_exp_time = world.time
	INVOKE_ASYNC(src, PROC_REF(modify_exp), ZWEI_EXP_DAMAGE_ABSORBED)

/// Zwei: Award EXP on combat hits and kills while on contract. 2 second hit cooldown, no kill cooldown.
/datum/component/association_exp/proc/on_zwei_combat_hit(datum/source, mob/living/target, mob/living/user, obj/item/item)
	SIGNAL_HANDLER
	if(!squad || !squad.is_on_contract())
		return
	if(!isliving(target) || target == parent)
		return
	// Check if target is an ally — don't award EXP for hitting allies
	if(is_designated_ally(target))
		return
	// Kill check — target died from this hit
	if(target.stat == DEAD)
		INVOKE_ASYNC(src, PROC_REF(modify_exp), ZWEI_EXP_KILL)
		return
	// Combat hit EXP with cooldown
	if(world.time < zwei_hit_exp_time + 2 SECONDS)
		return
	zwei_hit_exp_time = world.time
	INVOKE_ASYNC(src, PROC_REF(modify_exp), ZWEI_EXP_COMBAT_HIT)
