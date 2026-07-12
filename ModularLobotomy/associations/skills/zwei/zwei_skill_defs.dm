/// Registers all Zwei Association skill definitions in GLOB.association_skill_definitions.
/proc/init_zwei_skill_definitions()
	if(!GLOB.association_skill_definitions[ASSOCIATION_ZWEI])
		GLOB.association_skill_definitions[ASSOCIATION_ZWEI] = list()
	var/list/zwei_defs = GLOB.association_skill_definitions[ASSOCIATION_ZWEI]

	// ========================================
	// Guardian Branch — Self-defense, Defense Level Up manipulation
	// ========================================
	zwei_defs["Guardian"] = list()
	var/list/guardian = zwei_defs["Guardian"]

	guardian["tier1"] = list()
	guardian["tier1"]["a"] = list(\
		"name" = "Iron Stance", \
		"desc" = "On taking damage, gain 3 Defense Level Up stacks. 0.5 second cooldown.", \
		"type" = /datum/component/association_skill/zwei_iron_stance)
	guardian["tier1"]["b"] = list(\
		"name" = "Aggressive Guard", \
		"desc" = "On hitting an enemy, gain 2 Defense Level Up stacks. 1 second cooldown.", \
		"type" = /datum/component/association_skill/zwei_aggressive_guard)

	guardian["tier2"] = list()
	guardian["tier2"]["a"] = list(\
		"name" = "Shieldbreaker", \
		"desc" = "Your attacks deal bonus RED damage equal to your Defense Level Up percentage of your weapon's base damage.", \
		"type" = /datum/component/association_skill/zwei_shieldbreaker)
	guardian["tier2"]["b"] = list(\
		"name" = "Steady Footing", \
		"desc" = "While you have 5 or more Defense Level Up stacks, gain +15% movement speed.", \
		"type" = /datum/component/association_skill/zwei_steady_footing)

	guardian["tier3"] = list()
	guardian["tier3"]["a"] = list(\
		"name" = "Retaliating Onslaught", \
		"desc" = "Grants a powerful attack action (90s cooldown). Consume Defense Level Up stacks for +1% damage per stack. Dash to the target for a 5-hit combo. Each hit grants 2 Defense Level Up. Final hit deals double damage with knockback.", \
		"type" = /datum/component/association_skill/zwei_retaliating_onslaught)
	guardian["tier3"]["b"] = list(\
		"name" = "Unbreakable", \
		"desc" = "On lethal damage, survive at 15% HP, gain 7 Protection stacks and 3 seconds of invulnerability. 5 minute cooldown.", \
		"type" = /datum/component/association_skill/zwei_unbreakable)

	// ========================================
	// Territory Protection Branch — Area defense, ally buffing
	// ========================================
	zwei_defs["Territory Protection"] = list()
	var/list/territory = zwei_defs["Territory Protection"]

	territory["tier1"] = list()
	territory["tier1"]["a"] = list(\
		"name" = "Vigilant Presence", \
		"desc" = "When you take damage, allies within 4 tiles gain 2 Defense Level Up stacks. 1 second cooldown.", \
		"type" = /datum/component/association_skill/zwei_vigilant_presence)
	territory["tier1"]["b"] = list(\
		"name" = "Warden's Watch", \
		"desc" = "+15% damage vs mobs in contracted area (+25% if targeting you). +10% damage vs carbons in contracted area.", \
		"type" = /datum/component/association_skill/zwei_wardens_watch)

	territory["tier2"] = list()
	territory["tier2"]["a"] = list(\
		"name" = "Law and Order", \
		"desc" = "When you take damage, gain Protection stacks scaling with damage received (1 per 15 damage, up to 5). 12 second cooldown.", \
		"type" = /datum/component/association_skill/zwei_law_and_order)
	territory["tier2"]["b"] = list(\
		"name" = "Fortified Position", \
		"desc" = "Attacks grant 2 Defense Level Up. Consecutive hits from the same tile grant +3 additional stacks per hit. Moving resets the bonus.", \
		"type" = /datum/component/association_skill/zwei_fortified_position)

	territory["tier3"] = list()
	territory["tier3"]["a"] = list(\
		"name" = "Earthshatter", \
		"desc" = "Grants a powerful attack action (90s cooldown). AoE ground slam in a 3-tile radius. Combo on closest enemy: 3 hits (6 in contracted area). Each hit applies 2 Defense Level Down to target and 3 Defense Level Up to self. Allies nearby grant bonus hits.", \
		"type" = /datum/component/association_skill/zwei_earthshatter)
	territory["tier3"]["b"] = list(\
		"name" = "Iron Curtain", \
		"desc" = "While in contracted area, absorb 25% of damage dealt to allies within 4 tiles. You take the redirected damage at 50% effectiveness.", \
		"type" = /datum/component/association_skill/zwei_iron_curtain)

	// ========================================
	// Client Protection Branch — Bodyguard, ward protection
	// ========================================
	zwei_defs["Client Protection"] = list()
	var/list/client = zwei_defs["Client Protection"]

	client["tier1"] = list()
	client["tier1"]["a"] = list(\
		"name" = "Designated Ward", \
		"desc" = "Grants Mark for Protection. When your ward takes damage within 7 tiles, they gain 2 Defense Level Up and you gain 3. 1 second cooldown.", \
		"type" = /datum/component/association_skill/zwei_designated_ward)
	client["tier1"]["b"] = list(\
		"name" = "Threatening Presence", \
		"desc" = "Grants Mark for Protection. Your ward takes 15% less damage while you are within 7 tiles. When your ward takes damage, you gain 2 Defense Level Up. 1 second cooldown.", \
		"type" = /datum/component/association_skill/zwei_threatening_presence)

	client["tier2"] = list()
	client["tier2"]["a"] = list(\
		"name" = "Bodyguard's Instinct", \
		"desc" = "When your ward takes damage, gain +30% movement speed for 2 seconds.", \
		"type" = /datum/component/association_skill/zwei_bodyguards_instinct)
	client["tier2"]["b"] = list(\
		"name" = "Shared Resilience", \
		"desc" = "When you gain Defense Level Up stacks, your ward also gains half the amount (within 7 tiles).", \
		"type" = /datum/component/association_skill/zwei_shared_resilience)

	client["tier3"] = list()
	client["tier3"]["a"] = list(\
		"name" = "Guardian's Wrath", \
		"desc" = "Grants a powerful attack action (120s cooldown). Leap to a target from up to 7 tiles. 4-hit combo. If your ward took damage in the last 10 seconds, damage is doubled. Each hit heals your ward for 5% of damage dealt.", \
		"type" = /datum/component/association_skill/zwei_guardians_wrath)
	client["tier3"]["b"] = list(\
		"name" = "Lifelink", \
		"desc" = "When your ward takes damage within 2-7 tiles, block the damage entirely, teleport to them, and take the hit yourself. 5 second cooldown.", \
		"type" = /datum/component/association_skill/zwei_lifelink)
