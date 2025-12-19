// RCE Bestiary Data - Shared data for harvest component and UI bestiary
// This file is the single source of truth for mob harvest data

GLOBAL_LIST_INIT(rce_bestiary_entries, list())
GLOBAL_LIST_INIT(rce_bestiary_folders, list())

/// Initialize the bestiary data on world start
/proc/initialize_rce_bestiary()
	if(length(GLOB.rce_bestiary_entries))
		return // Already initialized

	// ============================================
	// HEART OF GREED UNITS (X-Corp)
	// ============================================

	// Elite units
	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "xcorp_heart_dps",
		name = "Sumptus Excessivi",
		mob_type = /mob/living/simple_animal/hostile/greed/heart/dps,
		folder = "xcorp",
		rank = "Elite",
		lore = "Elite heart warriors whose every attack is an expression of violent excess. Berserkers in the truest sense.",
		traits = list(TRAIT_ORGANIC, TRAIT_ELITE, TRAIT_WEAPONIZED, TRAIT_BRUTAL),
		base_value = 35,
		drop_chance = 100,
		drop_count_min = 1,
		drop_count_max = 2
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "xcorp_heart_ranged",
		name = "Sicarius",
		mob_type = /mob/living/simple_animal/hostile/greed/heart/ranged,
		folder = "xcorp",
		rank = "Elite",
		lore = "Precision killers from the heart units. They have honed their excess into deadly accuracy.",
		traits = list(TRAIT_ORGANIC, TRAIT_ELITE, TRAIT_PRECISION, TRAIT_AGILE),
		base_value = 35,
		drop_chance = 100,
		drop_count_min = 1,
		drop_count_max = 2
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "xcorp_heart",
		name = "Accumulatio",
		mob_type = /mob/living/simple_animal/hostile/greed/heart,
		folder = "xcorp",
		rank = "Elite",
		lore = "Heart unit grunts who have begun the transformation into true excess. Their regenerative capabilities are remarkable.",
		traits = list(TRAIT_ORGANIC, TRAIT_ELITE, TRAIT_HEAVY, TRAIT_ADAPTIVE),
		base_value = 35,
		drop_chance = 100,
		drop_count_min = 1,
		drop_count_max = 2
	))

	// Standard units
	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "xcorp_dps",
		name = "X-Corp Studiose",
		mob_type = /mob/living/simple_animal/hostile/greed/dps,
		folder = "xcorp",
		rank = "Standard",
		lore = "Former researchers who delved too deep into the nature of excess. Their volatile nature makes them unpredictable in combat.",
		traits = list(TRAIT_ORGANIC, TRAIT_VOLATILE, TRAIT_AGILE),
		base_value = 20,
		drop_chance = 70,
		drop_count_min = 1,
		drop_count_max = 2
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "xcorp_tank",
		name = "X-Corp Nimis",
		mob_type = /mob/living/simple_animal/hostile/greed/tank,
		folder = "xcorp",
		rank = "Standard",
		lore = "Heavily armored enforcers whose bodies have calcified into living shields. Their toxic blood corrodes anything it touches.",
		traits = list(TRAIT_ORGANIC, TRAIT_ARMORED, TRAIT_HEAVY, TRAIT_TOXIC),
		base_value = 22,
		drop_chance = 75,
		drop_count_min = 1,
		drop_count_max = 2
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "xcorp_scout",
		name = "X-Corp Praepropere",
		mob_type = /mob/living/simple_animal/hostile/greed/scout,
		folder = "xcorp",
		rank = "Standard",
		lore = "Scouts mutated for speed. They secrete toxins as they move, leaving trails of corruption.",
		traits = list(TRAIT_ORGANIC, TRAIT_AGILE, TRAIT_VOLATILE, TRAIT_TOXIC),
		base_value = 22,
		drop_chance = 75,
		drop_count_min = 1,
		drop_count_max = 1
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "xcorp_sapper",
		name = "X-Corp Ardenter",
		mob_type = /mob/living/simple_animal/hostile/greed/sapper,
		folder = "xcorp",
		rank = "Standard",
		lore = "Sappers with psionic abilities born from their burning desire. They can disrupt minds as easily as machinery.",
		traits = list(TRAIT_ORGANIC, TRAIT_NEURAL, TRAIT_CORRUPTED, TRAIT_TOXIC),
		base_value = 22,
		drop_chance = 75,
		drop_count_min = 1,
		drop_count_max = 1
	))

	// Fodder units
	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "xcorp_base",
		name = "X-Corp Laute",
		mob_type = /mob/living/simple_animal/hostile/greed,
		folder = "xcorp",
		rank = "Fodder",
		lore = "The lowest rung of X-Corp's hierarchy. Once ordinary workers, their bodies have bloated with accumulated excess. Slow but resilient.",
		traits = list(TRAIT_ORGANIC, TRAIT_FODDER, TRAIT_HEAVY),
		base_value = 10,
		drop_chance = 50,
		drop_count_min = 1,
		drop_count_max = 1
	))

	// ============================================
	// GREED TOUCHED UNITS (Clan)
	// ============================================

	// Elite units
	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_corrupter",
		name = "Greed Touched Corrupter",
		mob_type = /mob/living/simple_animal/hostile/clan/ranged/corrupter/greed,
		folder = "greed_clan",
		rank = "Elite",
		lore = "Command units that spread the Greed infection. Their presence warps both flesh and metal.",
		traits = list(TRAIT_CORRUPTED, TRAIT_MECHANICAL, TRAIT_ELITE, TRAIT_NEURAL),
		base_value = 105,
		drop_chance = 100,
		drop_count_min = 2,
		drop_count_max = 3
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_assassin",
		name = "Greed Touched Assassin",
		mob_type = /mob/living/simple_animal/hostile/clan/assassin/greed,
		folder = "greed_clan",
		rank = "Standard",
		lore = "Killers whose corruption grants them aberrant speed and agility.",
		traits = list(TRAIT_CORRUPTED, TRAIT_AGILE, TRAIT_MECHANICAL),
		base_value = 44,
		drop_chance = 85,
		drop_count_min = 1,
		drop_count_max = 1
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_warper",
		name = "Greed Touched Warper",
		mob_type = /mob/living/simple_animal/hostile/clan/ranged/warper/greed,
		folder = "greed_clan",
		rank = "Elite",
		lore = "Psionic entities that can bend space. The corruption has given them terrifying mental powers.",
		traits = list(TRAIT_CORRUPTED, TRAIT_NEURAL, TRAIT_ADAPTIVE, TRAIT_MECHANICAL),
		base_value = 61,
		drop_chance = 95,
		drop_count_min = 1,
		drop_count_max = 2
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_bomber",
		name = "Greed Touched Bomber Spider",
		mob_type = /mob/living/simple_animal/hostile/clan/bomber_spider/greed,
		folder = "greed_clan",
		rank = "Fodder",
		lore = "Explosive units that have embraced self-destruction as their purpose.",
		traits = list(TRAIT_CORRUPTED, TRAIT_VOLATILE, TRAIT_FODDER),
		base_value = 18,
		drop_chance = 55,
		drop_count_min = 1,
		drop_count_max = 1
	))

	// Standard units
	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_demolisher",
		name = "Greed Touched Demolisher",
		mob_type = /mob/living/simple_animal/hostile/clan/demolisher/greed,
		folder = "greed_clan",
		rank = "Elite",
		lore = "Heavy weapons platforms warped into brutal killing machines. They revel in destruction.",
		traits = list(TRAIT_CORRUPTED, TRAIT_WEAPONIZED, TRAIT_HEAVY, TRAIT_BRUTAL, TRAIT_ELITE),
		base_value = 61,
		drop_chance = 95,
		drop_count_min = 1,
		drop_count_max = 2
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_harpooner",
		name = "Greed Touched Harpooner",
		mob_type = /mob/living/simple_animal/hostile/clan/ranged/harpooner/greed,
		folder = "greed_clan",
		rank = "Standard",
		lore = "Brutal hunters that drag prey into melee range. The Greed has made them sadistic.",
		traits = list(TRAIT_CORRUPTED, TRAIT_WEAPONIZED, TRAIT_BRUTAL),
		base_value = 53,
		drop_chance = 90,
		drop_count_min = 1,
		drop_count_max = 1
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_gunner",
		name = "Greed Touched Gunner",
		mob_type = /mob/living/simple_animal/hostile/clan/ranged/gunner/greed,
		folder = "greed_clan",
		rank = "Fodder",
		lore = "Standard infantry corrupted by Greed. Their weapons have fused with their bodies.",
		traits = list(TRAIT_CORRUPTED, TRAIT_WEAPONIZED, TRAIT_FODDER),
		base_value = 18,
		drop_chance = 55,
		drop_count_min = 1,
		drop_count_max = 1
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_sniper",
		name = "Greed Touched Sniper",
		mob_type = /mob/living/simple_animal/hostile/clan/ranged/sniper/greed,
		folder = "greed_clan",
		rank = "Standard",
		lore = "Precision units aberrantly enhanced by the Greed. Their aim is supernaturally accurate.",
		traits = list(TRAIT_CORRUPTED, TRAIT_PRECISION, TRAIT_MECHANICAL),
		base_value = 39,
		drop_chance = 80,
		drop_count_min = 1,
		drop_count_max = 1
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_defender",
		name = "Greed Touched Defender",
		mob_type = /mob/living/simple_animal/hostile/clan/defender/greed,
		folder = "greed_clan",
		rank = "Elite",
		lore = "Heavy units whose armor has ossified into organic-metal hybrid plating.",
		traits = list(TRAIT_CORRUPTED, TRAIT_ARMORED, TRAIT_HEAVY, TRAIT_ELITE),
		base_value = 61,
		drop_chance = 95,
		drop_count_min = 1,
		drop_count_max = 2
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_rapid",
		name = "Greed Touched Rapid",
		mob_type = /mob/living/simple_animal/hostile/clan/ranged/rapid/greed,
		folder = "greed_clan",
		rank = "Standard",
		lore = "Speed units whose corruption manifests as volatile, erratic behavior.",
		traits = list(TRAIT_CORRUPTED, TRAIT_VOLATILE, TRAIT_ERRATIC),
		base_value = 35,
		drop_chance = 75,
		drop_count_min = 1,
		drop_count_max = 1
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_drone",
		name = "Greed Touched Drone",
		mob_type = /mob/living/simple_animal/hostile/clan/drone/greed,
		folder = "greed_clan",
		rank = "Standard",
		lore = "Support units whose neural links have been warped by corruption. They now spread toxins instead of repairs.",
		traits = list(TRAIT_CORRUPTED, TRAIT_NEURAL, TRAIT_TOXIC),
		base_value = 26,
		drop_chance = 65,
		drop_count_min = 1,
		drop_count_max = 1
	))

	// Fodder units
	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_scout",
		name = "Greed Touched Scout",
		mob_type = /mob/living/simple_animal/hostile/clan/scout/greed,
		folder = "greed_clan",
		rank = "Fodder",
		lore = "Light reconnaissance units whose corruption makes them erratic but quick. The Greed has made them expendable.",
		traits = list(TRAIT_CORRUPTED, TRAIT_LIGHTWEIGHT, TRAIT_FODDER),
		base_value = 18,
		drop_chance = 55,
		drop_count_min = 1,
		drop_count_max = 1
	))

	// ============================================
	// GREED TOUCHED BUILDINGS
	// ============================================

	// Turrets - Elite rank (stationary weapons platforms)
	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_turret_l1",
		name = "Greed-Touched Turret, Level 1",
		mob_type = /mob/living/simple_animal/hostile/clan/ranged/turret/level1,
		folder = "greed_clan",
		rank = "Standard",
		lore = "Basic automated defense turrets corrupted by the Greed. Their targeting systems have fused with organic matter.",
		traits = list(TRAIT_CORRUPTED, TRAIT_WEAPONIZED, TRAIT_ARMORED),
		base_value = 35,
		drop_chance = 75,
		drop_count_min = 1,
		drop_count_max = 2
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_turret_l2",
		name = "Greed-Touched Turret, Level 2",
		mob_type = /mob/living/simple_animal/hostile/clan/ranged/turret/level2,
		folder = "greed_clan",
		rank = "Standard",
		lore = "Upgraded defense turrets with enhanced firepower. The corruption has improved their targeting algorithms.",
		traits = list(TRAIT_CORRUPTED, TRAIT_WEAPONIZED, TRAIT_ARMORED, TRAIT_PRECISION),
		base_value = 53,
		drop_chance = 90,
		drop_count_min = 1,
		drop_count_max = 2
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_turret_l3",
		name = "Greed-Touched Turret, Level 3",
		mob_type = /mob/living/simple_animal/hostile/clan/ranged/turret/level3,
		folder = "greed_clan",
		rank = "Elite",
		lore = "Advanced defense turrets with maximum firepower. Flesh and metal have become one in these deadly platforms.",
		traits = list(TRAIT_CORRUPTED, TRAIT_WEAPONIZED, TRAIT_ARMORED, TRAIT_PRECISION, TRAIT_ELITE),
		base_value = 70,
		drop_chance = 100,
		drop_count_min = 2,
		drop_count_max = 3
	))

	// Artillery Turrets - Elite rank (heavy damage dealers)
	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_artillery_l1",
		name = "Greed-Touched Artillery Turret, Level 1",
		mob_type = /mob/living/simple_animal/hostile/clan/ranged/turret/artillery/level1,
		folder = "greed_clan",
		rank = "Standard",
		lore = "Heavy artillery platforms corrupted by the Greed. Their explosive shells leave craters of pulsating flesh.",
		traits = list(TRAIT_CORRUPTED, TRAIT_WEAPONIZED, TRAIT_HEAVY, TRAIT_VOLATILE),
		base_value = 44,
		drop_chance = 85,
		drop_count_min = 1,
		drop_count_max = 2
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_artillery_l2",
		name = "Greed-Touched Artillery Turret, Level 2",
		mob_type = /mob/living/simple_animal/hostile/clan/ranged/turret/artillery/level2,
		folder = "greed_clan",
		rank = "Elite",
		lore = "Upgraded artillery with enhanced explosive power. The corruption has made their shells even more devastating.",
		traits = list(TRAIT_CORRUPTED, TRAIT_WEAPONIZED, TRAIT_HEAVY, TRAIT_VOLATILE, TRAIT_ELITE),
		base_value = 70,
		drop_chance = 100,
		drop_count_min = 2,
		drop_count_max = 3
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_artillery_l3",
		name = "Greed-Touched Artillery Turret, Level 3",
		mob_type = /mob/living/simple_animal/hostile/clan/ranged/turret/artillery/level3,
		folder = "greed_clan",
		rank = "Elite",
		lore = "Advanced artillery platforms with devastating firepower. Their bombardments reshape the battlefield into flesh-covered wastelands.",
		traits = list(TRAIT_CORRUPTED, TRAIT_WEAPONIZED, TRAIT_HEAVY, TRAIT_VOLATILE, TRAIT_ELITE, TRAIT_BRUTAL),
		base_value = 88,
		drop_chance = 100,
		drop_count_min = 2,
		drop_count_max = 4
	))

	// Shield Generators - Elite rank (support structures)
	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_shield_l1",
		name = "Greed-Touched Shield Generator, Level 1",
		mob_type = /mob/living/simple_animal/hostile/clan/shield_generator/level1,
		folder = "greed_clan",
		rank = "Standard",
		lore = "Defensive structures that project protective shields. The corruption has given them regenerative capabilities.",
		traits = list(TRAIT_CORRUPTED, TRAIT_ARMORED, TRAIT_ADAPTIVE),
		base_value = 44,
		drop_chance = 85,
		drop_count_min = 1,
		drop_count_max = 2
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_shield_l2",
		name = "Greed-Touched Shield Generator, Level 2",
		mob_type = /mob/living/simple_animal/hostile/clan/shield_generator/level2,
		folder = "greed_clan",
		rank = "Elite",
		lore = "Upgraded shield generators with enhanced coverage. Their protective fields pulse with corrupted energy.",
		traits = list(TRAIT_CORRUPTED, TRAIT_ARMORED, TRAIT_ADAPTIVE, TRAIT_ELITE),
		base_value = 70,
		drop_chance = 100,
		drop_count_min = 2,
		drop_count_max = 3
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_shield_l3",
		name = "Greed-Touched Shield Generator, Level 3",
		mob_type = /mob/living/simple_animal/hostile/clan/shield_generator/level3,
		folder = "greed_clan",
		rank = "Elite",
		lore = "Advanced shield generators with maximum protection range. They form the backbone of corrupted defensive networks.",
		traits = list(TRAIT_CORRUPTED, TRAIT_ARMORED, TRAIT_ADAPTIVE, TRAIT_ELITE, TRAIT_NEURAL),
		base_value = 88,
		drop_chance = 100,
		drop_count_min = 2,
		drop_count_max = 4
	))

	// Chain Anchors - Various ranks (spawner structures)
	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_anchor_gunner",
		name = "Greed-Touched Gunner Anchor",
		mob_type = /mob/living/simple_animal/hostile/clan/chain_anchor/gunner,
		folder = "greed_clan",
		rank = "Standard",
		lore = "Anchor points that deploy and tether corrupted gunner units. Flesh fused with their weapons.",
		traits = list(TRAIT_CORRUPTED, TRAIT_MECHANICAL, TRAIT_NEURAL),
		base_value = 44,
		drop_chance = 85,
		drop_count_min = 1,
		drop_count_max = 2
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_anchor_sniper",
		name = "Greed-Touched Sniper Anchor",
		mob_type = /mob/living/simple_animal/hostile/clan/chain_anchor/sniper,
		folder = "greed_clan",
		rank = "Standard",
		lore = "Anchor points that deploy corrupted long-range sniper units, their forms twisted by greed.",
		traits = list(TRAIT_CORRUPTED, TRAIT_MECHANICAL, TRAIT_PRECISION),
		base_value = 35,
		drop_chance = 75,
		drop_count_min = 1,
		drop_count_max = 1
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_anchor_rapid",
		name = "Greed-Touched Rapid Anchor",
		mob_type = /mob/living/simple_animal/hostile/clan/chain_anchor/rapid,
		folder = "greed_clan",
		rank = "Standard",
		lore = "Anchor points that deploy corrupted rapid-fire units, their barrels pulsing with flesh.",
		traits = list(TRAIT_CORRUPTED, TRAIT_MECHANICAL, TRAIT_VOLATILE),
		base_value = 39,
		drop_chance = 80,
		drop_count_min = 1,
		drop_count_max = 2
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_anchor_warper",
		name = "Greed-Touched Warper Anchor",
		mob_type = /mob/living/simple_animal/hostile/clan/chain_anchor/warper,
		folder = "greed_clan",
		rank = "Elite",
		lore = "Anchor points that deploy corrupted phase-shifting warpers, reality bending around their twisted forms.",
		traits = list(TRAIT_CORRUPTED, TRAIT_MECHANICAL, TRAIT_NEURAL, TRAIT_ELITE),
		base_value = 61,
		drop_chance = 95,
		drop_count_min = 1,
		drop_count_max = 2
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "greed_anchor_harpooner",
		name = "Greed-Touched Harpooner Anchor",
		mob_type = /mob/living/simple_animal/hostile/clan/chain_anchor/harpooner,
		folder = "greed_clan",
		rank = "Elite",
		lore = "Anchor points that deploy corrupted harpooner units, their chains dripping with viscous corruption.",
		traits = list(TRAIT_CORRUPTED, TRAIT_MECHANICAL, TRAIT_BRUTAL, TRAIT_ELITE),
		base_value = 61,
		drop_chance = 95,
		drop_count_min = 1,
		drop_count_max = 2
	))

	// ============================================
	// BLOODFIEND UNITS
	// ============================================

	// Bosses - Elite rank
	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "bloodfiend_boss_barber",
		name = "The Barber",
		mob_type = /mob/living/simple_animal/hostile/bloodfiend_boss/barber,
		folder = "bloodfiends",
		rank = "Elite",
		lore = "A 3rd Kindred and one of the youngest siblings, The Barber is an eccentric woman obsessed with fashion. She spent centuries giving makeovers to bloodbags, finding it discourteous for visitors to pass through without wearing her handmade outfits. Despite her attractions lacking success - something Dulcinea once teased her about - she remained passionate. Two hundred years of starvation after their rebellion against their father left her mind fragile. The Heart of Greed offered her a cure: hoard blood rather than drink it. Now she harvests with elegant precision, her fashion obsession twisted into bloody collection.",
		traits = list(TRAIT_ORGANIC, TRAIT_ELITE, TRAIT_BRUTAL, TRAIT_AGILE, TRAIT_CORRUPTED),
		base_value = 300,
		drop_chance = 100,
		drop_count_min = 3,
		drop_count_max = 5
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "bloodfiend_boss_priest",
		name = "The Priest",
		mob_type = /mob/living/simple_animal/hostile/bloodfiend_boss/priest,
		folder = "bloodfiends",
		rank = "Elite",
		lore = "A 3rd Kindred, The Priest is a somber but gentle man who dedicated his days to counseling the bloodfiends of his area. Despite his gloomy appearance, he cared dearly for the residents - neglecting his own wellbeing while rotting in his confessional room. His faith was misplaced; he told the suffering to suppress their doubts and act happy. Two centuries of starvation after their rebellion broke him. The Heart of Greed answered his desperate prayers with a new gospel: hoard blood rather than drink it. Now he preaches accumulation to his flock, storing crimson in vessels living and dead.",
		traits = list(TRAIT_ORGANIC, TRAIT_ELITE, TRAIT_BRUTAL, TRAIT_NEURAL, TRAIT_CORRUPTED),
		base_value = 400,
		drop_chance = 100,
		drop_count_min = 3,
		drop_count_max = 5
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "bloodfiend_boss_dulcinea",
		name = "Dulcinea",
		mob_type = /mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea,
		folder = "bloodfiends",
		rank = "Elite",
		lore = "The oldest sibling and a 2nd Kindred, Dulcinea is a bitter and nihilistic woman. Despite her high status as Princess of the Parade, she sees herself as powerless - just another attraction doomed to cycle endlessly. She envies her Father's ignorance and speaks poorly of everyone, including herself. Two centuries of starvation after their rebellion against their father deepened her despair. The Heart of Greed offered escape: hoard blood rather than drink it, find meaning in accumulation. Her hollow laughter now echoes with the ecstasy of swelling reserves, her parade bloated with crimson they can never release.",
		traits = list(TRAIT_ORGANIC, TRAIT_ELITE, TRAIT_BRUTAL, TRAIT_ADAPTIVE, TRAIT_CORRUPTED),
		base_value = 500,
		drop_chance = 100,
		drop_count_min = 4,
		drop_count_max = 6
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "bloodfiend_mook_parade_guard",
		name = "Greed Touched Formal Bloodfiend",
		mob_type = /mob/living/simple_animal/hostile/bloodfiend_mook/parade_guard,
		folder = "bloodfiends",
		rank = "Standard",
		lore = "Elite guards corrupted by the Heart of Greed. Their formal attire conceals bodies bloated with hoarded blood they refuse to consume, growing stronger from accumulation alone. They will never release what they've stored.",
		traits = list(TRAIT_ORGANIC, TRAIT_HEAVY, TRAIT_BRUTAL, TRAIT_CORRUPTED),
		base_value = 40,
		drop_chance = 85,
		drop_count_min = 1,
		drop_count_max = 2
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "bloodfiend_mook_parade",
		name = "Greed Touched Parade Bloodfiend",
		mob_type = /mob/living/simple_animal/hostile/bloodfiend_mook/parade,
		folder = "bloodfiends",
		rank = "Standard",
		lore = "The Heart of Greed twisted their bloodlust into acquisitive frenzy. They strike with wild abandon not to feed, but to collect - storing every drop within their swelling forms, never allowing themselves to consume what they've taken.",
		traits = list(TRAIT_ORGANIC, TRAIT_AGILE, TRAIT_BRUTAL, TRAIT_CORRUPTED),
		base_value = 30,
		drop_chance = 75,
		drop_count_min = 1,
		drop_count_max = 2
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "bloodfiend_mook_parade_alt",
		name = "Greed Touched Marcher Bloodfiend",
		mob_type = /mob/living/simple_animal/hostile/bloodfiend_mook/parade_alt,
		folder = "bloodfiends",
		rank = "Standard",
		lore = "Corrupted by the Heart of Greed into patient hoarders. They endure punishment while methodically extracting blood from their victims, never consuming what they take - only stockpiling it within their swollen forms.",
		traits = list(TRAIT_ORGANIC, TRAIT_ARMORED, TRAIT_ADAPTIVE, TRAIT_CORRUPTED),
		base_value = 30,
		drop_chance = 75,
		drop_count_min = 1,
		drop_count_max = 2
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "bloodfiend_mook_priest",
		name = "Greed Touched Priest Bloodfiend",
		mob_type = /mob/living/simple_animal/hostile/bloodfiend_mook/priest,
		folder = "bloodfiends",
		rank = "Standard",
		lore = "Once devoted to blood rituals, now they worship accumulation itself. The Heart of Greed transformed their hunger into obsessive collection. They gather blood endlessly, storing it within their bodies but never drinking - passing their reserves to their masters when commanded.",
		traits = list(TRAIT_ORGANIC, TRAIT_TOXIC, TRAIT_CORRUPTED),
		base_value = 25,
		drop_chance = 70,
		drop_count_min = 1,
		drop_count_max = 1
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "bloodfiend_mook_fashionista",
		name = "Greed Touched Fashionista Bloodfiend",
		mob_type = /mob/living/simple_animal/hostile/bloodfiend_mook/fashionista,
		folder = "bloodfiends",
		rank = "Standard",
		lore = "The weakest of the greed-touched bloodfiends, newly corrupted by the Heart of Greed. They hoard blood obsessively, jealously guarding what little they've collected.",
		traits = list(TRAIT_ORGANIC, TRAIT_AGILE, TRAIT_CORRUPTED),
		base_value = 15,
		drop_chance = 55,
		drop_count_min = 1,
		drop_count_max = 1
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "bloodbag_parade",
		name = "Greed Touched Parade Bloodbag",
		mob_type = /mob/living/simple_animal/hostile/bloodbag/parade,
		folder = "bloodfiends",
		rank = "Fodder",
		lore = "Mindless husks reanimated by the Parade's bloodfiends, their bodies grotesquely swollen with hoarded crimson. These walking blood vaults shamble forward without thought, exploding violently when destroyed.",
		traits = list(TRAIT_ORGANIC, TRAIT_FODDER, TRAIT_TOXIC, TRAIT_CORRUPTED),
		base_value = 18,
		drop_chance = 60,
		drop_count_min = 1,
		drop_count_max = 1
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "bloodbag_priest_alt",
		name = "Greed Touched Heavy Bloodbag",
		mob_type = /mob/living/simple_animal/hostile/bloodbag/priest_alt,
		folder = "bloodfiends",
		rank = "Fodder",
		lore = "Corpses raised by the Priest's bloodfiends and pumped full of hoarded blood. These mindless husks are sent as explosive offerings - their violent deaths scattering stolen crimson across the battlefield.",
		traits = list(TRAIT_ORGANIC, TRAIT_FODDER, TRAIT_TOXIC, TRAIT_CORRUPTED),
		base_value = 15,
		drop_chance = 55,
		drop_count_min = 1,
		drop_count_max = 1
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "bloodbag_priest",
		name = "Greed Touched Priest Bloodbag",
		mob_type = /mob/living/simple_animal/hostile/bloodbag/priest,
		folder = "bloodfiends",
		rank = "Fodder",
		lore = "Reanimated victims serving as walking storage for hoarded blood. These mindless husks shuffle forward without purpose beyond containment and detonation.",
		traits = list(TRAIT_ORGANIC, TRAIT_FODDER, TRAIT_TOXIC, TRAIT_CORRUPTED),
		base_value = 12,
		drop_chance = 50,
		drop_count_min = 1,
		drop_count_max = 1
	))

	register_bestiary_entry(new /datum/rce_bestiary_entry(
		id = "bloodbag_fashionista",
		name = "Greed Touched Fashionista Bloodbag",
		mob_type = /mob/living/simple_animal/hostile/bloodbag/fashionista,
		folder = "bloodfiends",
		rank = "Fodder",
		lore = "The weakest of the bloodbag husks, created from victims and stuffed with stolen blood. These mindless shells stumble forward, bursting at the seams with crimson they cannot comprehend.",
		traits = list(TRAIT_ORGANIC, TRAIT_FODDER, TRAIT_VOLATILE, TRAIT_CORRUPTED),
		base_value = 10,
		drop_chance = 45,
		drop_count_min = 1,
		drop_count_max = 1
	))

	// ============================================
	// FOLDER DEFINITIONS
	// ============================================

	GLOB.rce_bestiary_folders["xcorp"] = list(
		"id" = "xcorp",
		"name" = "Heart of Greed Units",
		"lore" = "These creatures emerged from deep within X-Corp excavation pits, spawned by a strange flesh construct known as the Heart of Greed. This pulsating organic mass corrupts everything it touches, transforming corpses and beings with weakened willpower into twisted servants. The corrupted spread the Heart's influence, seeking to expand its domain. R-Corp researchers have found their tainted flesh yields valuable biological data for weapon development."
	)

	GLOB.rce_bestiary_folders["greed_clan"] = list(
		"id" = "greed_clan",
		"name" = "Greed Touched Units",
		"lore" = "Resurgence Clan machines sent by the Tinkerer to salvage equipment from X-Corp caves. They encountered the Heart of Greed's corruption - a spreading infection that thrives on resistance. Now these hybrid entities serve the Heart, their mechanical forms fused with pulsating flesh. Their unique composition makes them invaluable research subjects."
	)

	GLOB.rce_bestiary_folders["bloodfiends"] = list(
		"id" = "bloodfiends",
		"name" = "Greed-Touched Bloodfiends",
		"lore" = "The three bloodfiend lords - Dulcinea the 2nd Kindred, and The Barber and The Priest as 3rd Kindred - are siblings, children of La Manchaland's founder. Their father starved them for years, forcing them to resist their primal urge to consume blood. When they finally rebelled, they were defeated and trapped within La Manchaland for over two centuries. Two hundred years of starvation and isolation shattered their minds, leaving them vulnerable. In this fragile state, the Heart of Greed found them - offering a cure to their eternal hunger. To embrace greed, to hoard blood rather than consume it, to join its hivemind and finally find peace. They accepted, and now lead their greed-touched servants in the Heart's name."
	)

/// Register a bestiary entry
/proc/register_bestiary_entry(datum/rce_bestiary_entry/entry)
	GLOB.rce_bestiary_entries[entry.mob_type] = entry

/// Get bestiary entry for a mob type
/proc/get_bestiary_entry(mob_type)
	// First check for exact match
	if(GLOB.rce_bestiary_entries[mob_type])
		return GLOB.rce_bestiary_entries[mob_type]

	// Check parent types
	for(var/entry_type in GLOB.rce_bestiary_entries)
		if(ispath(mob_type, entry_type))
			return GLOB.rce_bestiary_entries[entry_type]

	return null

/// Get bestiary entry for a living mob instance
/proc/get_bestiary_entry_for_mob(mob/living/L)
	return get_bestiary_entry(L.type)

// ============================================
// BESTIARY ENTRY DATUM
// ============================================

/datum/rce_bestiary_entry
	var/id = ""
	var/name = ""
	var/mob_type = null
	var/folder = ""
	var/rank = "Standard" // Elite, Standard, Fodder
	var/lore = ""
	var/list/traits = list()
	var/base_value = 10
	var/drop_chance = 100
	var/drop_count_min = 1
	var/drop_count_max = 1

/datum/rce_bestiary_entry/New(
		id,
		name,
		mob_type,
		folder,
		rank,
		lore,
		list/traits,
		base_value,
		drop_chance,
		drop_count_min,
		drop_count_max
	)
	if(id)
		src.id = id
	if(name)
		src.name = name
	if(mob_type)
		src.mob_type = mob_type
	if(folder)
		src.folder = folder
	if(rank)
		src.rank = rank
	if(lore)
		src.lore = lore
	if(traits)
		src.traits = traits
	if(base_value)
		src.base_value = base_value
	if(drop_chance)
		src.drop_chance = drop_chance
	if(drop_count_min)
		src.drop_count_min = drop_count_min
	if(drop_count_max)
		src.drop_count_max = drop_count_max

/// Generate harvest data from this entry
/datum/rce_bestiary_entry/proc/get_harvest_data()
	var/datum/harvest_data/data = new
	data.traits = traits.Copy()
	data.base_value = base_value
	data.drop_chance = drop_chance
	data.drop_count = rand(drop_count_min, drop_count_max)
	return data
