/// Registers all Dieci Association skill definitions in GLOB.association_skill_definitions.
/proc/init_dieci_skill_definitions()
	if(!GLOB.association_skill_definitions[ASSOCIATION_DIECI])
		GLOB.association_skill_definitions[ASSOCIATION_DIECI] = list()
	var/list/dieci_defs = GLOB.association_skill_definitions[ASSOCIATION_DIECI]

	// ========================================
	// Scholar Branch — Sinking application + exploitation
	// ========================================
	dieci_defs["Scholar"] = list()
	var/list/scholar = dieci_defs["Scholar"]

	scholar["tier1"] = list()
	scholar["tier1"]["a"] = list(\
		"name" = "Deep Study", \
		"desc" = "Melee attacks apply 2 Sinking to the target. On hit, can consume 1 Behavioral knowledge for bonus Sinking equal to the consumed level (5s cooldown).", \
		"type" = /datum/component/association_skill/dieci_deep_study)
	scholar["tier1"]["b"] = list(\
		"name" = "Analytical Strike", \
		"desc" = "Attacking a target with no Sinking stacks applies 8 Sinking.", \
		"type" = /datum/component/association_skill/dieci_analytical_strike)

	scholar["tier2"] = list()
	scholar["tier2"]["a"] = list(\
		"name" = "Drowning Knowledge", \
		"desc" = "Heavy attacks against targets with 15+ Sinking deal 25% bonus damage. On heavy hit, can consume 1 Behavioral knowledge for an additional 5% bonus per level (5s cooldown).", \
		"type" = /datum/component/association_skill/dieci_drowning_knowledge)
	scholar["tier2"]["b"] = list(\
		"name" = "Spreading Decay", \
		"desc" = "Heavy attacks against targets with Sinking apply 5 Sinking to nearby enemies within 2 tiles (2s cooldown). On spread, can consume 1 Behavioral knowledge to also apply Defense Level Down equal to the consumed level (5s cooldown).", \
		"type" = /datum/component/association_skill/dieci_spreading_decay)

	scholar["tier3"] = list()
	scholar["tier3"]["a"] = list(\
		"name" = "Abyssal Revelation", \
		"desc" = "Grants a powerful attack action (90s cooldown). Consumes up to 5 knowledge entries, then shoulder-charges the target for a 5-hit combo with +10% damage per consumed level. Final hit deals PALE damage and triggers Sinking. Grants 2 free empowers.", \
		"type" = /datum/component/association_skill/dieci_abyssal_revelation)
	scholar["tier3"]["b"] = list(\
		"name" = "Tome of Ruin", \
		"desc" = "Every 5th heavy attack on the same target consumes 1 knowledge to trigger their Sinking, apply 5 new Sinking, and grant 1 free empower.", \
		"type" = /datum/component/association_skill/dieci_tome_of_ruin)

	// ========================================
	// Warden Branch — Shield HP enhancement
	// ========================================
	dieci_defs["Warden"] = list()
	var/list/warden = dieci_defs["Warden"]

	warden["tier1"] = list()
	warden["tier1"]["a"] = list(\
		"name" = "Knowledge Barrier", \
		"desc" = "Melee attacks grant 3 shield HP. On hit, can consume 1 Medical knowledge for bonus shield HP equal to the consumed level times 5 (5s cooldown).", \
		"type" = /datum/component/association_skill/dieci_knowledge_barrier)
	warden["tier1"]["b"] = list(\
		"name" = "Reactive Ward", \
		"desc" = "Melee attacks grant 2 shield HP. When your shield absorbs damage, applies 5 Sinking to the attacker.", \
		"type" = /datum/component/association_skill/dieci_reactive_ward)

	warden["tier2"] = list()
	warden["tier2"]["a"] = list(\
		"name" = "Tome Shield", \
		"desc" = "Grants an action (5s cooldown) that consumes your highest Medical knowledge to gain shield HP equal to 10 times the consumed level.", \
		"type" = /datum/component/association_skill/dieci_tome_shield)
	warden["tier2"]["b"] = list(\
		"name" = "Stalwart Presence", \
		"desc" = "Taking damage while at 50+ shield HP grants 3 Protection. On damage taken, can consume 1 Medical knowledge to heal yourself for the consumed level times 2% of max HP (5s cooldown).", \
		"type" = /datum/component/association_skill/dieci_stalwart_presence)

	warden["tier3"] = list()
	warden["tier3"]["a"] = list(\
		"name" = "Golden Aegis", \
		"desc" = "Grants a powerful attack action (90s cooldown). Stomps to apply Sinking in an area, then delivers a 5-hit combo. Each of the first 4 hits consumes knowledge to build shield HP. The final hit consumes up to 200 shield HP for massive bonus damage and triggers Sinking.", \
		"type" = /datum/component/association_skill/dieci_golden_aegis)
	warden["tier3"]["b"] = list(\
		"name" = "Immovable Library", \
		"desc" = "Attacking a target with active Sinking consumes 1 knowledge to gain shield HP equal to twice the target's Sinking stacks. 4 second cooldown.", \
		"type" = /datum/component/association_skill/dieci_immovable_library)

	// ========================================
	// Sage Branch — Knowledge economy maximization
	// ========================================
	dieci_defs["Sage"] = list()
	var/list/sage = dieci_defs["Sage"]

	sage["tier1"] = list()
	sage["tier1"]["a"] = list(\
		"name" = "Extensive Notes", \
		"desc" = "Increases max knowledge to 30. Heavy attacks deal 15% bonus PALE damage. On heavy hit, can consume 1 Spiritual knowledge for an additional 5% bonus per level (5s cooldown).", \
		"type" = /datum/component/association_skill/dieci_extensive_notes)
	sage["tier1"]["b"] = list(\
		"name" = "Applied Learning", \
		"desc" = "Whenever knowledge is consumed, gain 4 Offense Level Up.", \
		"type" = /datum/component/association_skill/dieci_applied_learning)

	sage["tier2"] = list()
	sage["tier2"]["a"] = list(\
		"name" = "Shared Wisdom", \
		"desc" = "Grants an action (15s cooldown) that targets an ally and consumes 1 Spiritual knowledge to grant them Offense Level Up equal to twice the consumed level.", \
		"type" = /datum/component/association_skill/dieci_shared_wisdom)
	sage["tier2"]["b"] = list(\
		"name" = "Efficient Research", \
		"desc" = "Synthesis costs 2 entries instead of 3. Consuming L3+ knowledge refunds 1 entry of the same type at level minus 1. On attack, can consume 1 Spiritual knowledge to grant 2 Offense Level Up to nearby allies (5s cooldown).", \
		"type" = /datum/component/association_skill/dieci_efficient_research)

	sage["tier3"] = list()
	sage["tier3"]["a"] = list(\
		"name" = "Grand Archive", \
		"desc" = "Grants a powerful attack action (90s cooldown). Consumes up to 5 highest knowledge entries, then hurls your Tome at the target for a multi-hit combo. Each hit applies Sinking scaling with consumed level. Final hit deals PALE damage at 1.25x with double Sinking.", \
		"type" = /datum/component/association_skill/dieci_grand_archive)
	sage["tier3"]["b"] = list(\
		"name" = "Infinite Library", \
		"desc" = "Increases max knowledge to 50. Light attacks consume your lowest knowledge to apply Sinking equal to the consumed level. 1 second cooldown.", \
		"type" = /datum/component/association_skill/dieci_infinite_library)
