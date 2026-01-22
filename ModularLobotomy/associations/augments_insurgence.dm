/obj/machinery/augment_fabricator/insurgence
	name = "Insurgence Augment Fabricator"
	desc = "A specialized machine that produces augments with... unique properties. The prices seem too good to be true."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "protolathe"

	roles = list("Insurgence Transport Agent", "Insurgence Nightwatch Agent", "Prosthetics Surgeon", "Office Director", "Office Fixer", "Doctor")
	sale_percentages = list(75, 80, 90) // Even better discounts
	on_sale_pct = 1.0 // Everything is always on sale
	markup_pct = 0

	available_effects = list(
		// --- Reactive Damage Effects ---
		// list(
		// 	"id" = "struggling_defense",
		// 	"name" = "Struggling Defense",
		// 	"ahn_cost" = 25,
		// 	"ep_cost" = 2, // Positive EP cost
		// 	"desc" = "Each 12.5% of HP lost grants 2.5%*X damage reduction (max 17.5%*X at 87.5% HP lost).",
		// 	"repeatable" = 3, // Max 3 times
		// 	"component" = /datum/component/augment/resisting_augment/struggling_defense
		// ),
		list(
			"id" = "ES_red",
			"name" = "Emergency Shields, RED",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "When you take brute damage while under 50% HP, gain 8 RED Protection. This has a cooldown of 1 minute.",
			"component" = /datum/component/augment/ES_red
		),
		list(
			"id" = "ES_black",
			"name" = "Emergency Shields, BLACK",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "When you take brute damage while under 50% HP, gain 8 BLACK Protection. This has a cooldown of 1 minute.",
			"component" = /datum/component/augment/ES_black
		),
		list(
			"id" = "ES_white",
			"name" = "Emergency Shields, WHITE",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"desc" = "When you take sanity damage while under 50% SP, gain 8 WHITE Protection. This has a cooldown of 1 minute.",
			"component" = /datum/component/augment/ES_white
		),
		list(
			"id" = "defensive_preparations",
			"name" = "Defensive Preparations",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "When taking brute damage, give yourself and all humans within 4 sqrs of you 4 Protection. This has a cooldown of 1.5 minutes.",
			"repeatable" = 3,
			"component" = /datum/component/augment/defensive_preparations
		),
		// list(
		// 	"id" = "reinforcement_nanties",
		// 	"name" = "Reinforcement Nanties",
		// 	"ahn_cost" = 25,
		// 	"ep_cost" = 2,
		// 	"desc" = "When you take damage, you will take 5*X% less damage per human you can see. (Max of 40%).",
		// 	"repeatable" = 3,
		// 	"component" = /datum/component/augment/resisting_augment/reinforcement_nanties
		// ),
		list(
			"id" = "cooling_systems",
			"name" = "Cooling Systems",
			"ahn_cost" = 100,
			"ep_cost" = 4,
			"desc" = "Take 75% less damage from OVERHEAT, however take 25% more damage from RED attacks.",
			"component" = /datum/component/augment/cooling_systems
		),
		list(
			"id" = "stalwart_form",
			"name" = "Stalwart Form",
			"ahn_cost" = 100,
			"ep_cost" = 4,
			"desc" = "Stuns/Knockdowns are 90% less effective on you. However, you will take 15% extra RED and BLACK damage.",
			"component" = /datum/component/augment/stalwart_form
		),
		list(
			"id" = "fireproof",
			"name" = "Fireproof",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "Under 15% HP, you become immune to OVERHEAT damage.",
			"component" = /datum/component/augment/fireproof
		),
		// list(
		// 	"id" = "alert",
		// 	"name" = "Alert",
		// 	"ahn_cost" = 50,
		// 	"ep_cost" = 4,
		// 	"desc" = "The first time you take damage, reduce it by 80% and teleport 3-5 tiles away. Has a cooldown of 60 seconds.",
		// 	"component" = /datum/component/augment/resisting_augment/alert
		// ),
		// --- Attacking Effects ---
		list(
			"id" = "regeneration",
			"name" = "Regeneration",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"desc" = "On hit with a RED weapon, heal a flat 2*X HP (Has a cooldown of half a second)",
			"repeatable" = 3,
			"component" = /datum/component/augment/regeneration
		),
		list(
			"id" = "tranquility",
			"name" = "Tranquility",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"desc" = "On hit with a WHITE weapon, heal a flat 2*X SP (Has a cooldown of half a second)",
			"repeatable" = 3,
			"component" = /datum/component/augment/tranquility
		),
		list(
			"id" = "struggling_strength",
			"name" = "Struggling Strength",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"repeatable" = 3,
			"desc" = "Each 12.5% of HP lost grants 2.5%*X damage increase (max 17.5%*X at 87.5% HP lost).",
			"component" = /datum/component/augment/struggling_strength
		),
		list(
			"id" = "ar_red",
			"name" = "Armor Rend, RED",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "On hit with a RED weapon, inflict 3 BLACK fragility.",
			"component" = /datum/component/augment/ar_red
		),
		list(
			"id" = "ar_black",
			"name" = "Armor Rend, BLACK",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "On hit with a BLACK weapon, inflict 3 RED fragility.",
			"component" = /datum/component/augment/ar_black
		),
		list(
			"id" = "dual_wield",
			"name" = "Strong Arms",
			"ahn_cost" = 200,
			"ep_cost" = 8,
			"desc" = "When you perform a melee attack, if you are holding another weapon in your other hand, attack the same target with your other weapon. This has a cooldown of the other weapons attack speed *4",
			"component" = /datum/component/augment/dual_wield
		),
		list(
			"id" = "unstable",
			"name" = "Unstable",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "While at 50% or higher SP, you BLACK melee attacks deal 20% more damage, but you also take SP damage equal to 5% of your Max SP per hit.",
			"component" = /datum/component/augment/unstable
		),
		list(
			"id" = "shattering_mind_red",
			"name" = "Shattering Mind, RED",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"repeatable" = 3,
			"desc" = "For every 25% of your missing SP, deal an extra 10*X% RED damage.",
			"component" = /datum/component/augment/shattering_mind_red
		),
		list(
			"id" = "shattering_mind_white",
			"name" = "Shattering Mind, WHITE",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"repeatable" = 3,
			"desc" = "For every 25% of your missing SP, deal an extra 10*X% WHITE damage.",
			"component" = /datum/component/augment/shattering_mind_white
		),
		list(
			"id" = "shattering_mind_black",
			"name" = "Shattering Mind, BLACK",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"repeatable" = 3,
			"desc" = "For every 25% of your missing SP, deal an extra 10*X% BLACK damage.",
			"component" = /datum/component/augment/shattering_mind_black
		),
		list(
			"id" = "gashing_wounds",
			"name" = "Gashing Wounds",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"desc" = "On hit with a RED weapon, inflict 2 BLEED (Cooldown of half a second)",
			"component" = /datum/component/augment/gashing_wounds
		),
		list(
			"id" = "backstabber",
			"name" = "Backstabber",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"repeatable" = 3,
			"desc" = "When you attack a mob who has the same direction as you, you will deal RED damage equal to their BLEED stack * 2 * X. (Cooldown of 2 seconds)",
			"component" = /datum/component/augment/backstabber
		),
		list(
			"id" = "scorching_mind",
			"name" = "Scorching Mind",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"desc" = "On hit with a WHITE weapon, inflict 3 OVERHEAT (Cooldown of 1 second.)",
			"component" = /datum/component/augment/scorching_mind
		),
		list(
			"id" = "stigmatize",
			"name" = "Stigmatize",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"repeatable" = 3,
			"desc" = "On hit, inflict 1 OVERHEAT for every 25% of your missing SP. Double the OVERHEAT if the attack is a WHITE weapon. (Has a cooldown of 4 / 2 / 1 seconds, scaling with repeat count.)",
			"component" = /datum/component/augment/stigmatize
		),
		list(
			"id" = "brandish_the_flame",
			"name" = "Brandish the Flame",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"repeatable" = 3,
			"desc" = "On hit against a target with 10+ OVERHEAT, gain Strength equal to (target's OVERHEAT / 10). (Has a cooldown of 15 / X seconds.)",
			"component" = /datum/component/augment/brandish_the_flame
		),
		list(
			"id" = "slothful_decay",
			"name" = "Slothful Decay",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"desc" = "On hit with a BLACK weapon, inflict 2 TREMOR. If the weapon has an attack speed greater than 1.5 second, Inflict an extra 2 TREMOR. (Cooldown of 1.5 seconds.)",
			"component" = /datum/component/augment/slothful_decay
		),
		list(
			"id" = "inner_ardor",
			"name" = "Inner Ardor",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "When making a melee attack, deal an extra 0.5% damage for every point of fire damage you have.",
			"component" = /datum/component/augment/inner_ardor
		),
		// list(
		// 	"id" = "strong_grip",
		// 	"name" = "Strong Grip",
		// 	"ahn_cost" = 100,
		// 	"ep_cost" = 4,
		// 	"desc" = "If you attack while you have HARM intent, your weapon will become unable to be dropped. This effect is removed when you attack in any other intent.",
		// 	"component" = /datum/component/augment/strong_grip
		// ),
		list(
			"id" = "combustion",
			"name" = "Combustion",
			"ahn_cost" = 100,
			"ep_cost" = 6,
			"desc" = "When attacking while having 25+ OVERHEAT, consume 25 OVERHEAT to create an explosion that deals 250 WHITE damage (scaled by Justice) to all simple mobs within 5 sqrs. (Has a cooldown of 10 seconds.)",
			"component" = /datum/component/augment/combustion
		),
		// --- Execution Effects ---
		list(
			"id" = "absorption",
			"name" = "Absorption",
			"ahn_cost" = 100,
			"ep_cost" = 6,
			"desc" = "On kill, regenerate as much HP as the amount of damage you dealt. (Max of 50 HP healing)",
			"component" = /datum/component/augment/absorption
		),
		list(
			"id" = "brutalize",
			"name" = "Brutalize",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"repeatable" = 3,
			"desc" = "On kill, deal 15*X WHITE damage to all simple mobs within 2 sqrs of you.",
			"component" = /datum/component/augment/brutalize
		),
		list(
			"id" = "flesh_morphing",
			"name" = "Flesh-Morphing",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"repeatable" = 3,
			"desc" = "On kill, One human within 4 sqrs of you (not including you), Heals 10% * X of your target max HP.",
			"component" = /datum/component/augment/flesh_morphing
		),
		list(
			"id" = "reclaimed_flame",
			"name" = "Reclaimed Flame",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"repeatable" = 3,
			"desc" = "On kill, heal 20 * X OVERHEAT damage.",
			"component" = /datum/component/augment/reclaimed_flame
		),
		// --- Status Effects ---
		list(
			"id" = "burn_vigor",
			"name" = "OVERHEAT Vigor",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"repeatable" = 3,
			"desc" = "When making a melee attack, deal an extra 10*X% more damage for every 5 OVERHEAT on self.",
			"component" = /datum/component/augment/burn_vigor
		),
		list(
			"id" = "bleed_vigor",
			"name" = "BLEED Vigor",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"repeatable" = 3,
			"desc" = "When making a melee attack, deal an extra 10*X% more damage for every 5 BLEED on self.",
			"component" = /datum/component/augment/bleed_vigor
		),
		// list(
		// 	"id" = "tremor_defense",
		// 	"name" = "TREMOR Defense",
		// 	"ahn_cost" = 25,
		// 	"ep_cost" = 2,
		// 	"repeatable" = 3,
		// 	"desc" = "For every 10 TREMOR on self, take 5*X% less damage from RED/BLACK attacks. (Max of 30% + (X - 1) * 20%)",
		// 	"component" = /datum/component/augment/resisting_augment/tremor_defense
		// ),
		list(
			"id" = "earthquake",
			"name" = "Earthquake",
			"ahn_cost" = 100,
			"ep_cost" = 8,
			"desc" = "When attacking a target with 20+ TREMOR, trigger a TREMOR burst on target and deal (TREMOR on target * 6) RED damage to all mobs within 3 sqrs of the target. This has a cooldown of 30 seconds.",
			"component" = /datum/component/augment/earthquake
		),
		list(
			"id" = "tremor_break",
			"name" = "TREMOR Break",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "When attacking a target with 15+ TREMOR, trigger a TREMOR Burst on the target and inflict (TREMOR on Target / 5) Feeble to the target. This has a cooldown of 30 seconds.",
			"component" = /datum/component/augment/tremor_break
		),
		list(
			"id" = "tremor_burst",
			"name" = "TREMOR Burst",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"desc" = "When attacking a target with 10+ TREMOR, trigger a TREMOR Burst on the target. This has a cooldown of 10 seconds.",
			"component" = /datum/component/augment/tremor_burst
		),
		list(
			"id" = "reflective_tremor",
			"name" = "Reflective TREMOR",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"repeatable" = 4,
			"desc" = "When taking RED/BLACK damage from a melee attack, inflict 2*X TREMOR to the target and X TREMOR to self. (This has a cooldown of 1 second)",
			"component" = /datum/component/augment/reflective_tremor
		),
		// list(
		// 	"id" = "blood_thorns",
		// 	"name" = "Blood Thorns",
		// 	"ahn_cost" = 25,
		// 	"ep_cost" = 2,
		// 	"repeatable" = 3,
		// 	"desc" = "When taking damage while having 5+ BLEED, take (BLEED / 2, rounded up) * X% less damage (max 80%). Then spend 50% of your BLEED to inflict it on the attacker (only works against simple mobs). (Has a cooldown of 3 seconds)",
		// 	"component" = /datum/component/augment/resisting_augment/blood_thorns
		// ),
		list(
			"id" = "blood_jaunt",
			"name" = "Blood Jaunt",
			"ahn_cost" = 200,
			"ep_cost" = 8,
			"desc" = "When you click on a tile outside your melee range and within 3 sqrs, You will teleport to that tile and will inflict 10 BLEED to all foes within 2 sqrs, and yourself. (Has a cooldown of 1 minute) (You need to be in harm intent in order to trigger this.)",
			"component" = /datum/component/augment/blood_jaunt
		),
		list(
			"id" = "sanguine_desire",
			"name" = "Sanguine Desire",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "When making a melee attack to a target with BLEED, heal 3 SP and an extra 2 SP for every status effect they have. (Has a cooldown of 1 second).",
			"component" = /datum/component/augment/sanguine_desire
		),
		list(
			"id" = "pyromaniac",
			"name" = "Pyromaniac",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "When making a melee attack, while having 5+ OVERHEAT on self, transfer 2 OVERHEAT on self to the target.",
			"component" = /datum/component/augment/pyromaniac
		),
		list(
			"id" = "hemomaniac",
			"name" = "Hemomaniac",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "When making a melee attack, while having 5+ BLEED on self, transfer 2 BLEED on self to the target.",
			"component" = /datum/component/augment/hemomaniac
		),
		list(
			"id" = "spreading_embers",
			"name" = "Spreading Embers",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "When attacking a target with 10+ OVERHEAT, inflict 10 OVERHEAT to all foes within 3 sqrs of the target, and inflict 15 OVERHEAT to self. (This has a cooldown of 30 seconds).",
			"component" = /datum/component/augment/spreading_embers
		),
		list(
			"id" = "regenerative_warmth",
			"name" = "Regenerative Warmth",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "Taking OVERHEAT damage heals BRUTE and OVERHEAT damage equal to 50% of OVERHEAT damage taken.",
			"component" = /datum/component/augment/regenerative_warmth
		),
		list(
			"id" = "stoneward_form",
			"name" = "Stoneward Form",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "When you take damage, spawn a Stoneward Statue which every 5 seconds heals all humans near it and gives them 3 TREMOR. (Spawning has a cooldown of 30 seconds)",
			"component" = /datum/component/augment/stoneward_form
		),
		list(
			"id" = "ink_over",
			"name" = "Ink Over",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "When making a melee attack to a target with BLEED, deal 20% more damage, and deal an additional 10% for each status effect they have.",
			"component" = /datum/component/augment/ink_over
		),
		list(
			"id" = "blood_rush",
			"name" = "Blood Rush",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "On Kill, Gain a 50% speed boost for 5 seconds and gain 5 BLEED.",
			"component" = /datum/component/augment/blood_rush
		),
		list(
			"id" = "time_moratorium",
			"name" = "Time Moratorium",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "On hit against a target with 15+ TREMOR, consume 10 TREMOR from the target to trigger the timestop effect around them, with an AoE of 2 and duration of 4 seconds. (Has a cooldown of 30 seconds.)",
			"component" = /datum/component/augment/time_moratorium
		),
		list(
			"id" = "tremor_everlasting",
			"name" = "TREMOR Everlasting",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "On hit against a target with 10+ TREMOR, preform a TREMOR Burst and inflict TREMOR equal to half of their current TREMOR. (Has a cooldown of 30 seconds.)",
			"component" = /datum/component/augment/tremor_everlasting
		),
		list(
			"id" = "tremor_deterioration",
			"name" = "TREMOR Deterioration",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"repeatable" = 3,
			"desc" = "On hit against a target with 4+ TREMOR on self, consume 3 TREMOR on self to trigger an 3x3 AoE centered around the target, which deals half damage of your weapon and inflicts X TREMOR. (Has a cooldown of 2.5 seconds.)",
			"component" = /datum/component/augment/tremor_deterioration
		),
		list(
			"id" = "vibroweld_morph_combat_effect",
			"name" = "Vibroweld Morph-combat effect",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "On hit against a target with 16+ TREMOR on self, consume 15 TREMOR on self to trigger 3 TREMOR Bursts on target. (Has a cooldown of 30 seconds.)",
			"component" = /datum/component/augment/vibroweld_morph_combat_effect
		),
		list(
			"id" = "tremor_ruin",
			"name" = "TREMOR Ruin",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "On hit against a target with 10+ TREMOR, Prefrom a TREMOR Burst and inflict BLACK fragility equal to (targets TREMOR/5). (Has a cooldown of 15 seconds.)",
			"component" = /datum/component/augment/tremor_ruin
		),
		list(
			"id" = "rekindled_flame",
			"name" = "Rekindled Flame",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"repeatable" = 3,
			"desc" = "When attacking a target, inflict 1*X OVERHEAT for every 25% of your missing HP.",
			"component" = /datum/component/augment/rekindled_flame
		),
		list(
			"id" = "force_of_a_wildfire ",
			"name" = "Force of a Wildfire ",
			"ahn_cost" = 100,
			"ep_cost" = 6,
			"desc" = "On kill, All foes who are within 3 sqrs of the user, get inflicted with OVERHEAT equal to the executed target’s OVERHEAT.",
			"component" = /datum/component/augment/force_of_a_wildfire
		),
		list(
			"id" = "unstable_inertia",
			"name" = "Unstable Inertia",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"repeatable" = 3,
			"desc" = "When you take damage, inflict 1*X TREMOR for every 25% of your missing HP.",
			"component" = /datum/component/augment/unstable_inertia
		),
		list(
			"id" = "blood_cycler",
			"name" = "Blood Cycler",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "Any time a mob/human within 3 sqrs of you takes BLEED damage, heal HP equal to 50% of the BLEED damage they have taken. (Max of 100).",
			"component" = /datum/component/augment/blood_cycler
		),
		list(
			"id" = "crimson_cascade",
			"name" = "Crimson Cascade",
			"ahn_cost" = 50,
			"ep_cost" = 4,
			"desc" = "When someone within 3 sqrs takes BLEED damage, gain RED Damage Up equal to their BLEED stacks / 5.",
			"component" = /datum/component/augment/crimson_cascade
		),
		list(
			"id" = "faint_drain",
			"name" = "Faint Drain",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"desc" = "When a mob (not human) within 3 sqrs takes BLEED damage, inflict Feeble equal to their BLEED stacks / 10.",
			"component" = /datum/component/augment/faint_drain
		),

		list(
			"id" = "acidic_blood",
			"name" = "Acidic Blood",
			"ahn_cost" = 25,
			"ep_cost" = 2,
			"repeatable" = 3,
			"desc" = "When you take BLEED damage, Deal BLACK damage equal to the amount of BLEED you have *2X, to all simple mobs within 3 sqrs of you..",
			"component" = /datum/component/augment/acidic_blood
		),

		// --- Negative Effects ---
		list(
			"id" = "mental_corrosion",
			"name" = "Mental Corrosion",
			"ahn_cost" = 0,
			"ep_cost" = -6,
			"desc" = "Your mind slowly corrodes over time. Being near other humans slows the process, but something calls you to the water...",
			"component" = /datum/component/augment/mental_corrosion
		),

		list(
			"id" = "paranoid",
			"name" = "Paranoid ",
			"ahn_cost" = 50,
			"ep_cost" = -2, // Negative EP cost signifies a downside, grants EP
			"desc" = "Whenever you take damage, you take an extra 10 WHITE damage if you don’t have any human insight.",
			"component" = /datum/component/augment/paranoid
		),
		list(
			"id" = "bus",
			"name" = "Boot Up Sequence",
			"ahn_cost" = 25,
			"ep_cost" = -4,
			"desc" = "When you make an attack, gain 3 Feeble. This has a cooldown of 70 seconds.",
			"component" = /datum/component/augment/bus
		),
		list(
			"id" = "overheated",
			"name" = "Overheated",
			"ahn_cost" = 10,
			"ep_cost" = -2,
			"desc" = "When you make an attack, for the next 10 seconds each time you attack you gain 2*X OVERHEAT. This has a cooldown of 1.5 minutes.",
			"repeatable" = 3,
			"component" = /datum/component/augment/overheated
		),
		list(
			"id" = "thanatophobia",
			"name" = "Thanatophobia",
			"ahn_cost" = 25,
			"ep_cost" = -2,
			"desc" = "When you take damage while under 50% HP, take an extra 10 WHITE damage. Has a cooldown of 1 second.",
			"component" = /datum/component/augment/thanatophobia
		),
		list(
			"id" = "pacifist",
			"name" = "Pacifist",
			"ahn_cost" = 25,
			"ep_cost" = -4,
			"desc" = "On kill, gain 3 Feeble",
			"component" = /datum/component/augment/pacifist
		),
		list(
			"id" = "struggling_weakness",
			"name" = "Struggling Weakness",
			"ahn_cost" = 25,
			"ep_cost" = -4,
			"desc" = "For every 25% of HP lost, deal 20%*X less damage..",
			"repeatable" = 3,
			"component" = /datum/component/augment/struggling_weakness
		),
		list(
			"id" = "struggling_fragility",
			"name" = "Struggling Fragility",
			"ahn_cost" = 25,
			"ep_cost" = -4,
			"desc" = "For every 25% of HP lost, take 20%*X more damage..",
			"repeatable" = 3,
			"component" = /datum/component/augment/struggling_fragility
		),
		list(
			"id" = "algophobia",
			"name" = "Algophobia",
			"ahn_cost" = 10,
			"ep_cost" = -2,
			"desc" = "When you take RED damage, take an extra (RED damage) * X WHITE damage. This has a cooldown of 1 second.",
			"repeatable" = 3,
			"component" = /datum/component/augment/algophobia
		),
		list(
			"id" = "weak_arms",
			"name" = "Weak Arms",
			"ahn_cost" = 25,
			"ep_cost" = -4,
			"desc" = "Your melee attacks have their attack speed decreased by half.",
			"component" = /datum/component/augment/weak_arms
		),
		list(
			"id" = "annoyance",
			"name" = "Annoyance",
			"ahn_cost" = 25,
			"ep_cost" = -4,
			"desc" = "After every 8 attacks, all foes within 3 sqrs will start targeting you and you gain 2 Fragile.",
			"component" = /datum/component/augment/annoyance
		),
		list(
			"id" = "allodynia",
			"name" = "Allodynia",
			"ahn_cost" = 10,
			"ep_cost" = -2,
			"desc" = "When you take damage, you gain 2 * X BLEED. (Has a cooldown of 1 second). Also, you take BLEED damage each time you attack. (That has a cooldown of 3 seconds)",
			"repeatable" = 3,
			"component" = /datum/component/augment/allodynia
		),
		list(
			"id" = "internal_vibrations",
			"name" = "Internal Vibrations",
			"ahn_cost" = 10,
			"ep_cost" = -2,
			"desc" = "When you take damage, gain 2 * X TREMOR. Gain double the amount of TREMOR if the damage type was WHITE. If you have 50 TREMOR, TREMOR BURST yourself. (Has a cooldown of 0.5 second)",
			"repeatable" = 3,
			"component" = /datum/component/augment/internal_vibrations
		),
		list(
			"id" = "scalding_skin",
			"name" = "Scalding Skin",
			"ahn_cost" = 10,
			"ep_cost" = -2,
			"desc" = "When you take damage, you will gain OVERHEAT equal to the (damage taken)  / 5. If the damage type was RED, double the gained OVERHEAT. (This has a cooldown of 30 / X seconds)",
			"repeatable" = 3,
			"component" = /datum/component/augment/scalding_skin
		),
		list(
			"id" = "open_wound",
			"name" = "Open Wound",
			"ahn_cost" = 10,
			"ep_cost" = -2,
			"desc" = "After taking BLACK damage, for the next 10 seconds all of your attacks will inflict 2 * X BLEED to self. (Has a cooldown of 20 seconds.)",
			"repeatable" = 3,
			"component" = /datum/component/augment/open_wound
		),
		// Add other effects following this structure
	)

	var/locked = TRUE
	var/lockout_time = 0
	var/initial_lockout_duration = 6000 // 10 minutes in deciseconds

/obj/machinery/augment_fabricator/insurgence/Initialize()
	. = ..()
	// Add Mental Corrosion as a forced negative effect for all Insurgence augments
	for(var/list/effect in available_effects)
		if(effect["id"] == "mental_corrosion")
			effect["forced"] = TRUE // This effect is always included
			effect["ahn_cost"] = 0 // Free!
			break

	// Set lockout timer
	lockout_time = world.time + initial_lockout_duration
	addtimer(CALLBACK(src, PROC_REF(unlock_fabricator)), initial_lockout_duration)
	update_icon()

/obj/machinery/augment_fabricator/insurgence/proc/unlock_fabricator()
	locked = FALSE
	update_icon()
	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)

	// Alert all Insurgence members
	for(var/mob/M in GLOB.player_list)
		if(!M.mind || !M.client)
			continue
		if(M.mind.assigned_role in list("Insurgence Transport Agent", "Insurgence Nightwatch Agent"))
			to_chat(M, span_nicegreen("<b>ALERT:</b> The Insurgence augment fabricator is now operational! You may begin distributing augments."))
			M.playsound_local(M, 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)

/obj/machinery/augment_fabricator/insurgence/ui_interact(mob/user, datum/tgui/ui = null)
	if(locked)
		var/time_left = max(0, round((lockout_time - world.time) / 10)) // Convert to seconds
		to_chat(user, span_warning("The fabricator is still calibrating... [time_left] seconds remaining."))
		playsound(src, 'sound/machines/buzz-two.ogg', 30, TRUE)
		return
	return ..()

/obj/machinery/augment_fabricator/insurgence/attack_hand(mob/user)
	if(locked)
		var/time_left = max(0, round((lockout_time - world.time) / 10)) // Convert to seconds
		to_chat(user, span_warning("The fabricator is still calibrating... [time_left] seconds remaining."))
		playsound(src, 'sound/machines/buzz-two.ogg', 30, TRUE)
		return
	return ..()

/obj/machinery/augment_fabricator/insurgence/examine(mob/user)
	. = ..()
	if(locked)
		var/time_left = max(0, round((lockout_time - world.time) / 10)) // Convert to seconds
		. += span_warning("The system is locked down for calibration. Time remaining: [time_left] seconds.")
	else
		. += span_nicegreen("The system is fully operational.")

/obj/machinery/augment_fabricator/insurgence/make_new_augment()
	return new /obj/item/augment/insurgence

/obj/item/augment/insurgence
	name = "modified augment"
	desc = "This augment seems to have been modified with additional components. The modifications are seamlessly integrated."
	rankAttributeReqs = list(0, 20, 40, 60, 80) // 20 reduction as stated in the MD
	roles = list("Insurgence Transport Agent", "Insurgence Nightwatch Agent")
	var/datum/component/augment/mental_corrosion/corrosion_component // Track the mental corrosion component

/obj/item/augment/insurgence/ApplyEffects(mob/living/carbon/human/H)
	. = ..()
	// Force apply Mental Corrosion if not already present
	var/has_corrosion = FALSE
	for(var/datum/component/augment/mental_corrosion/MC in H.GetComponents(/datum/component/augment/mental_corrosion))
		has_corrosion = TRUE
		corrosion_component = MC // Store reference to existing component
		break

	if(!has_corrosion)
		corrosion_component = H.AddComponent(/datum/component/augment/mental_corrosion, 1) // Store reference to new component
		to_chat(H, span_notice("The augment integrates seamlessly with your body... though something feels different."))

/obj/item/augment/insurgence/proc/get_corrosion_level()
	if(!corrosion_component || QDELETED(corrosion_component))
		return 0
	return corrosion_component.corrosion_level

// Tracking console for Insurgence Clan
/obj/machinery/computer/insurgence_tracker
	name = "augment monitoring console"
	desc = "Monitors the status of distributed augments and their users."
	icon_screen = "comm_logs"
	var/list/tracked_augments = list()

/obj/machinery/computer/insurgence_tracker/ui_interact(mob/user)
	. = ..()
	// Allow ghosts to view
	if(isobserver(user))
		// Ghosts can view without restrictions
	else if(!ishuman(user))
		return
	else
		var/mob/living/carbon/human/H = user
		if(!H.mind || !(H.mind.assigned_role in list("Insurgence Transport Agent", "Insurgence Nightwatch Agent")))
			to_chat(user, span_warning("Access denied. Insurgence credentials required."))
			return

	var/dat = "<h3>Augment User Tracking</h3><hr>"
	dat += "<table border='1' style='width:100%'>"
	dat += "<tr><th>Subject</th><th>Location</th><th>Health</th><th>Corrosion</th><th>Bonds</th><th>Kidnap Ready</th></tr>"

	// Find all humans with mental corrosion
	for(var/mob/living/carbon/human/target in GLOB.alive_mob_list)
		if(!target.mind)
			continue
		for(var/datum/component/augment/mental_corrosion/MC in target.GetComponents(/datum/component/augment/mental_corrosion))
			dat += "<tr>"
			dat += "<td>[target.real_name]</td>"
			dat += "<td>[get_area_name(target)]</td>"
			dat += "<td>[target.health]/[target.maxHealth]</td>"
			dat += "<td><b>[MC.corrosion_level]%</b></td>"

			// Build bonds list
			var/bonds_text = ""
			if(MC.bonds.len > 0)
				var/list/bond_names = list()
				for(var/mob/living/carbon/human/bonded in MC.bonds)
					if(bonded && bonded.real_name)
						bond_names += bonded.real_name
				bonds_text = jointext(bond_names, ", ")
			else
				bonds_text = "None"
			dat += "<td>[bonds_text]</td>"

			// Kidnap eligibility
			if(MC.kidnap_eligible)
				dat += "<td><b><font color='red'>YES</font></b></td>"
			else
				dat += "<td>No</td>"
			dat += "</tr>"

	dat += "</table>"
	dat += "<hr><i>Remember: The Elder One watches. Guide them to the water when ready.</i>"

	var/datum/browser/popup = new(user, "insurgence_tracker", "Augment Monitoring", 600, 400)
	popup.set_content(dat)
	popup.open()

//Mental Corrosion - Insurgence Clan augment effect
/datum/component/augment/mental_corrosion
	var/corrosion_level = 0
	var/next_corrosion_increase = 0
	var/list/bonds = list() // List of humans who reduce corrosion
	var/list/human_interaction_count = list() // Track time spent with humans
	var/interaction_threshold = 50 // Times needed to form a bond
	var/max_bonds = 3 // Maximum bonds allowed
	var/voices_cooldown = 0
	var/water_seek_cooldown = 0
	var/processing = FALSE
	var/kidnap_eligible = FALSE // Once true at 80% corrosion, never goes back

/datum/component/augment/mental_corrosion/Initialize(_repeat = 1)
	. = ..()
	if(!processing)
		START_PROCESSING(SSprocessing, src)
		processing = TRUE
	next_corrosion_increase = world.time + 120 SECONDS

/datum/component/augment/mental_corrosion/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_move))

/datum/component/augment/mental_corrosion/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, COMSIG_MOVABLE_MOVED)
	if(processing)
		STOP_PROCESSING(SSprocessing, src)
		processing = FALSE

/datum/component/augment/mental_corrosion/process(delta_time)
	if(!human_parent || human_parent.stat == DEAD)
		return PROCESS_KILL

	if(human_parent.mind.assigned_role in list("Insurgence Transport Agent", "Insurgence Nightwatch Agent"))
		return PROCESS_KILL

	// Track nearby humans and update interaction counts
	var/list/nearby_humans = list()
	var/insurgence_nearby = FALSE
	var/bonded_humans_nearby = 0

	for(var/mob/living/carbon/human/H in view(7, human_parent))
		if(H == human_parent || H.stat == DEAD)
			continue

		// Check if they're Insurgence members
		if(H.mind && (H.mind.assigned_role in list("Insurgence Transport Agent", "Insurgence Nightwatch Agent")))
			if(H.invisibility != INVISIBILITY_OBSERVER)
				insurgence_nearby = TRUE
			continue

		nearby_humans += H

		// Check if this human is already bonded
		if(H in bonds)
			bonded_humans_nearby++
			continue

		// Track interactions with non-bonded humans
		if(!(H in human_interaction_count))
			human_interaction_count[H] = 0
		human_interaction_count[H]++

		// Check if they can form a bond
		if(human_interaction_count[H] >= interaction_threshold && length(bonds) < max_bonds)
			form_bond(H)

	// Check for insurgence robotic limbs
	var/insurgence_limb_count = 0
	for(var/obj/item/bodypart/BP in human_parent.bodyparts)
		if(istype(BP, /obj/item/bodypart/l_arm/robot/insurgence) || \
		   istype(BP, /obj/item/bodypart/r_arm/robot/insurgence) || \
		   istype(BP, /obj/item/bodypart/l_leg/robot/insurgence) || \
		   istype(BP, /obj/item/bodypart/r_leg/robot/insurgence) || \
		   istype(BP, /obj/item/bodypart/chest/robot/insurgence))
			insurgence_limb_count++

	// Calculate corrosion rate based on nearby humans and bonds
	var/corrosion_rate = 1.0
	if(insurgence_nearby)
		corrosion_rate = 2 // Insurgence members speed up corrosion
	else if(bonded_humans_nearby > 0)
		corrosion_rate = -bonded_humans_nearby * 0.5 // Each bond reduces corrosion by 0.5
	else if(length(nearby_humans) >= 3)
		corrosion_rate = 0.5 // Multiple humans reduce it significantly

	// Each insurgence limb increases corrosion rate by 0.5
	corrosion_rate += insurgence_limb_count * 0.5

	// Increase/decrease corrosion every 2 minutes
	if(world.time >= next_corrosion_increase)
		corrosion_level = clamp(corrosion_level + (6 * corrosion_rate), 0, 100)
		next_corrosion_increase = world.time + 120 SECONDS

		// // Notify user if corrosion decreased due to bonds
		// if(bonded_humans_nearby > 0 && corrosion_level < old_corrosion)
		// 	to_chat(human_parent, span_nicegreen("Your close relationships help stabilize your mind... (-[old_corrosion - corrosion_level]% Mental Corrosion)")) //DEBUG STUFF

		// Check for kidnap eligibility
		if(corrosion_level >= 80 && !kidnap_eligible)
			kidnap_eligible = TRUE

		// // Update HUD if needed
		// if(corrosion_level >= 20)
		// 	human_parent.hud_used?.lingchemdisplay?.invisibility = 0
		// 	human_parent.hud_used?.lingchemdisplay?.maptext = MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='#dd66dd'>[round(corrosion_level)]%</font></div>") //DEBUG STUFF

	// Apply effects based on corrosion level
	if(corrosion_level >= 20 && corrosion_level < 60)
		// Voices from the Elder One
		if(voices_cooldown < world.time)
			voices_cooldown = world.time + rand(120, 180) SECONDS
			// Random position: screen is typically 15x15 tiles, randomize within reasonable bounds
			var/tile_x = rand(3, 11) // Keep away from edges
			var/tile_y = rand(3, 11)
			var/pixel_x = rand(-16, 16)
			var/pixel_y = rand(-16, 16)
			show_blurb(human_parent.client, 40, "You hear a whisper <br> from beyond...", 10, "#ff4848", "black", "center", "[tile_x]:[pixel_x],[tile_y]:[pixel_y]")
			human_parent.playsound_local(human_parent, 'sound/abnormalities/whitenight/whisper.ogg', 15, TRUE)

	else if(corrosion_level >= 60 && corrosion_level < 75)
		// Suggestion to jump into the lake
		if(voices_cooldown < world.time)
			voices_cooldown = world.time + rand(120, 140) SECONDS
			// Random position: screen is typically 15x15 tiles, randomize within reasonable bounds
			var/tile_x = rand(3, 11) // Keep away from edges
			var/tile_y = rand(3, 11)
			var/pixel_x = rand(-16, 16)
			var/pixel_y = rand(-16, 16)
			show_blurb(human_parent.client, 50, "A voice suggests you seek <br> the Great Lake... <br> The water calls to you...", 10, "#ff4848", "black", "center", "[tile_x]:[pixel_x],[tile_y]:[pixel_y]")
			human_parent.playsound_local(human_parent, 'sound/hallucinations/over_here1.ogg', 15, TRUE)

	else if(corrosion_level >= 75 && corrosion_level < 90)
		// Vision impairment
		human_parent.overlay_fullscreen("mental_corrosion", /atom/movable/screen/fullscreen/impaired, 1 + (corrosion_level - 75) / 10)
		if(voices_cooldown < world.time)
			voices_cooldown = world.time + rand(60, 120) SECONDS
			// Random position: screen is typically 15x15 tiles, randomize within reasonable bounds
			var/tile_x = rand(3, 11) // Keep away from edges
			var/tile_y = rand(3, 11)
			var/pixel_x = rand(-16, 16)
			var/pixel_y = rand(-16, 16)
			show_blurb(human_parent.client, 40, "THE LAKE AWAITS. <br> EMBRACE THE DEPTHS.", 10, "#ff4848", "black", "center", "[tile_x]:[pixel_x],[tile_y]:[pixel_y]")
			human_parent.adjustSanityLoss(10)

	else if(corrosion_level >= 90)
		// Force water-seeking behavior
		if(water_seek_cooldown < world.time)
			water_seek_cooldown = world.time + 10 SECONDS
			seek_water()

/datum/component/augment/mental_corrosion/proc/seek_water()
	// Find nearest water turf
	var/turf/nearest_water
	var/min_distance = INFINITY
	for(var/turf/open/water/deep/W in range(14, human_parent))
		var/dist = get_dist(human_parent, W)
		if(dist < min_distance)
			min_distance = dist
			nearest_water = W

	if(nearest_water)
		to_chat(human_parent, span_purple("<b>YOU MUST REACH THE WATER!</b>"))
		human_parent.set_confusion(20)
		// Force movement towards water
		if(human_parent.stat == CONSCIOUS && human_parent.mobility_flags & MOBILITY_MOVE)
			step_towards(human_parent, nearest_water)
			if(DT_PROB(30, 1))
				human_parent.emote("scream")

/datum/component/augment/mental_corrosion/proc/on_move(datum/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	// Check if we entered water
	var/turf/T = get_turf(human_parent)
	if(istype(T, /turf/open/water/deep))
		// Check corrosion level for conversion
		if(corrosion_level >= 60)
			// Initiate conversion sequence
			INVOKE_ASYNC(src, PROC_REF(begin_water_conversion))

/datum/component/augment/mental_corrosion/proc/begin_water_conversion()
	if(!human_parent || human_parent.stat == DEAD)
		return

	// Prevent multiple conversions
	if(human_parent.has_status_effect(/datum/status_effect/conversion_locked))
		return

	// Call the global conversion proc
	enter_conversion_realm(human_parent)

/datum/component/augment/mental_corrosion/proc/form_bond(mob/living/carbon/human/H)
	if(!H || H.stat == DEAD)
		return
	if(H in bonds)
		return
	if(length(bonds) >= max_bonds)
		return
	if(H.mind && (H.mind.assigned_role in list("Insurgence Transport Agent", "Insurgence Nightwatch Agent")))
		return // Insurgence members cannot become bonds

	bonds += H

/obj/item/insurgence_augment_tester
	name = "Insurgence Augment Tester"
	desc = "A device that can check what types of augments the target can use."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "records_stats"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_SMALL
	var/list/stats = list(
		FORTITUDE_ATTRIBUTE,
		PRUDENCE_ATTRIBUTE,
		TEMPERANCE_ATTRIBUTE,
		JUSTICE_ATTRIBUTE,
	)

/obj/item/insurgence_augment_tester/afterattack(atom/target, mob/user, proximity_flag)
	. = ..()
	if(ishuman(target))
		playsound(get_turf(src), 'sound/machines/cryo_warning.ogg', 50, TRUE, -1)
		var/mob/living/carbon/human/H = target

		var/obj/item/augment/A = null
		for(var/atom/movable/i in H.contents)
			if (istype(i, /obj/item/augment))
				A = i
		if(A)
			to_chat(user, span_notice("The target current has the [A.name] augment."))
			// List the augment effects
			if(A.design_details && A.design_details.selected_effects_data && length(A.design_details.selected_effects_data))
				to_chat(user, span_notice("Augment Effects:"))
				var/list/effect_counts = list()
				for(var/list/effect in A.design_details.selected_effects_data)
					var/effect_id = effect["id"]
					effect_counts[effect_id] = (effect_counts[effect_id] || 0) + 1

				var/list/shown_effects = list()
				for(var/list/effect in A.design_details.selected_effects_data)
					var/effect_id = effect["id"]
					if(effect_id in shown_effects)
						continue
					shown_effects += effect_id
					var/count = effect_counts[effect_id]
					var/effect_name = effect["name"]
					var/effect_desc = effect["desc"]
					if(count > 1)
						to_chat(user, span_notice("• [effect_name] (x[count]): [effect_desc]"))
					else
						to_chat(user, span_notice("• [effect_name]: [effect_desc]"))

		var/stattotal
		for(var/attribute in stats)
			stattotal+=get_attribute_level(H, attribute)
		stattotal /= 4	//Potential is an average of stats
		var/best_augment = round(stattotal/20)
		best_augment++
		if(best_augment > 5)
			best_augment = 5
		if(best_augment < 1)
			to_chat(user, span_notice("The target is unable to use any augments."))
			return
		to_chat(user, span_notice("The target is able to use rank [best_augment] or lower augments."))
		return

	to_chat(user, span_notice("No human identified."))
