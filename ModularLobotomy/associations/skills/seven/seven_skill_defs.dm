/// Registers all Seven Association skill definitions in GLOB.association_skill_definitions.
/proc/init_seven_skill_definitions()
	if(!GLOB.association_skill_definitions[ASSOCIATION_SEVEN])
		GLOB.association_skill_definitions[ASSOCIATION_SEVEN] = list()
	var/list/seven_defs = GLOB.association_skill_definitions[ASSOCIATION_SEVEN]

	// ========================================
	// Analyst Branch — Mark Target + Rupture exploitation
	// ========================================
	seven_defs["Analyst"] = list()
	var/list/analyst = seven_defs["Analyst"]

	analyst["tier1"] = list()
	analyst["tier1"]["a"] = list(\
		"name" = "Case File", \
		"desc" = "Grants Mark Target. Attacking a marked target applies 2 Rupture and deals bonus BLACK damage scaling with the target's Rupture stacks.", \
		"type" = /datum/component/association_skill/seven_case_file)
	analyst["tier1"]["b"] = list(\
		"name" = "Profiling", \
		"desc" = "Grants Mark Target. Attacking a marked target grants 2 Offense Level Up to yourself, up to 10 stacks from this skill.", \
		"type" = /datum/component/association_skill/seven_profiling)

	analyst["tier2"] = list()
	analyst["tier2"]["a"] = list(\
		"name" = "Exploit Weakness", \
		"desc" = "Attacking a marked target applies 2 Defense Level Down. When the marked target's Rupture triggers at 15+ stacks, applies 5 Fragile.", \
		"type" = /datum/component/association_skill/seven_exploit_weakness)
	analyst["tier2"]["b"] = list(\
		"name" = "Patient Hunter", \
		"desc" = "Attacking a marked target with 10+ Rupture deals 25% bonus damage. At 20+ Rupture, also deals bonus BLACK damage equal to 15% of weapon force.", \
		"type" = /datum/component/association_skill/seven_patient_hunter)

	analyst["tier3"] = list()
	analyst["tier3"]["a"] = list(\
		"name" = "Dossier Complete", \
		"desc" = "Grants a powerful attack action (90s cooldown). Dash to your marked target and deliver a 4-hit combo that scales with Rupture stacks. Each hit applies 2 Offense Level Down. Final hit deals double damage with knockback and 5 Fragile.", \
		"type" = /datum/component/association_skill/seven_dossier_complete)
	analyst["tier3"]["b"] = list(\
		"name" = "Surveillance Network", \
		"desc" = "When Rupture triggers on a target you attacked, deals AoE BLACK damage equal to the Rupture stacks to nearby enemies. Damage doubled against marked targets, quadrupled against simple mobs. On kill, applies 15 Rupture to nearby enemies.", \
		"type" = /datum/component/association_skill/seven_surveillance_network)

	// ========================================
	// Coordinator Branch — Team buffs + debuff focus
	// ========================================
	seven_defs["Coordinator"] = list()
	var/list/coordinator = seven_defs["Coordinator"]

	coordinator["tier1"] = list()
	coordinator["tier1"]["a"] = list(\
		"name" = "Intel Briefing", \
		"desc" = "When attacking a target with Rupture, nearby allies gain 3 Offense Level Up. 1 second cooldown.", \
		"type" = /datum/component/association_skill/seven_intel_briefing)
	coordinator["tier1"]["b"] = list(\
		"name" = "Weak Point Analysis", \
		"desc" = "Attacks apply 3 Defense Level Down. If the target has 10+ Defense Level Down, nearby allies gain 3 Offense Level Up. 1 second cooldown.", \
		"type" = /datum/component/association_skill/seven_weak_point_analysis)

	coordinator["tier2"] = list()
	coordinator["tier2"]["a"] = list(\
		"name" = "Comprehensive Report", \
		"desc" = "Attacking a target with 15+ active Rupture grants 2 Strength to nearby allies and applies 4 Offense Level Down to the target. 10 second per-target cooldown.", \
		"type" = /datum/component/association_skill/seven_comprehensive_report)
	coordinator["tier2"]["b"] = list(\
		"name" = "Disinformation", \
		"desc" = "Attacks apply 2 Offense Level Down and 2 Feeble to the target. 1.5 second cooldown.", \
		"type" = /datum/component/association_skill/seven_disinformation)

	coordinator["tier3"] = list()
	coordinator["tier3"]["a"] = list(\
		"name" = "Full Exposure", \
		"desc" = "Grants a powerful attack action (120s cooldown). AoE opener debuffs enemies with Fragile, Defense/Offense Level Down scaling with ally count, and Feeble. Then delivers a 3-hit combo applying Rupture that scales with ally buffs. Final hit force-triggers all Rupture on the target.", \
		"type" = /datum/component/association_skill/seven_full_exposure)
	coordinator["tier3"]["b"] = list(\
		"name" = "Undermining Presence", \
		"desc" = "Attacks strip 2 stacks of each positive buff from the target. When a buff is stripped, heals visible allies for 2% of their max SP. 2 second cooldown on the heal.", \
		"type" = /datum/component/association_skill/seven_undermining_presence)

	// ========================================
	// Operative Branch — Rupture stacking + burst
	// ========================================
	seven_defs["Operative"] = list()
	var/list/operative = seven_defs["Operative"]

	operative["tier1"] = list()
	operative["tier1"]["a"] = list(\
		"name" = "Shadow Step", \
		"desc" = "Attacks convert the target's Offense Level Down and Defense Level Down stacks into Rupture. Applies up to 8 Rupture per hit.", \
		"type" = /datum/component/association_skill/seven_shadow_step)
	operative["tier1"]["b"] = list(\
		"name" = "Quick Assessment", \
		"desc" = "First hit on a new target applies 5 Rupture, second hit 3, third hit 1, then 0. Switching targets resets the counter.", \
		"type" = /datum/component/association_skill/seven_quick_assessment)

	operative["tier2"] = list()
	operative["tier2"]["a"] = list(\
		"name" = "Rupture Cascade", \
		"desc" = "When your attack triggers a Rupture burst on a target, applies 7 Rupture to all nearby enemies excluding the original target. 1 second cooldown.", \
		"type" = /datum/component/association_skill/seven_rupture_cascade)
	operative["tier2"]["b"] = list(\
		"name" = "Pressure Points", \
		"desc" = "Attacks apply Rupture equal to the number of unique debuff types on the target (Fragile, Feeble, Defense Level Down, Offense Level Down). Maximum 4 Rupture per hit.", \
		"type" = /datum/component/association_skill/seven_pressure_points)

	operative["tier3"] = list()
	operative["tier3"]["a"] = list(\
		"name" = "Surgical Strike", \
		"desc" = "Grants a powerful attack action (90s cooldown). Vanish for 2 seconds, then teleport behind the target for a 5-hit combo. Damage increases by 15% per debuff type on the target. Each hit applies 2 Rupture. Final hit deals double damage with bonus BLACK equal to the target's Rupture stacks.", \
		"type" = /datum/component/association_skill/seven_surgical_strike)
	operative["tier3"]["b"] = list(\
		"name" = "Detonation Order", \
		"desc" = "Attacks apply 4 Rupture to targets with fewer than 20 Rupture stacks.", \
		"type" = /datum/component/association_skill/seven_detonation_order)
