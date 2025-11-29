// RCE Research System - Base Definitions
// This system allows players to harvest body parts from enemies to unlock pyro weapons

// Global research nodes list
GLOBAL_LIST_EMPTY(rce_research_nodes)

// Research system defines
#define RCE_RESEARCH_TIER_1 1
#define RCE_RESEARCH_TIER_2 2
#define RCE_RESEARCH_TIER_3 3

// Research status constants
#define RESEARCH_LOCKED "locked"
#define RESEARCH_AVAILABLE "available"
#define RESEARCH_IN_PROGRESS "in_progress"
#define RESEARCH_COMPLETED "completed"

// Trait categories
#define TRAIT_CATEGORY_MOVEMENT "movement"
#define TRAIT_CATEGORY_COMBAT "combat"
#define TRAIT_CATEGORY_TYPE "type"
#define TRAIT_CATEGORY_INTELLIGENCE "intelligence"
#define TRAIT_CATEGORY_SPECIAL "special"
#define TRAIT_CATEGORY_ENERGY "energy"
#define TRAIT_CATEGORY_STRUCTURAL "structural"

// Movement traits
#define TRAIT_LIGHTWEIGHT "lightweight"
#define TRAIT_HEAVY "heavy"
#define TRAIT_AGILE "agile"
#define TRAIT_SLUGGISH "sluggish"
#define TRAIT_ERRATIC "erratic"

// Combat traits
#define TRAIT_ARMORED "armored"
#define TRAIT_WEAPONIZED "weaponized"
#define TRAIT_FODDER "fodder"
#define TRAIT_BERSERKER "berserker"
#define TRAIT_PRECISION "precision"
#define TRAIT_BRUTAL "brutal"

// Type traits
#define TRAIT_MECHANICAL "mechanical"
#define TRAIT_ORGANIC "organic"
#define TRAIT_CORRUPTED "corrupted"
#define TRAIT_HYBRID "hybrid"
#define TRAIT_SYNTHETIC "synthetic"
#define TRAIT_ABERRANT "aberrant"

// Intelligence traits
#define TRAIT_NEURAL "neural"
#define TRAIT_RCE_PRIMITIVE "rce_primitive"
#define TRAIT_HIVEMIND "hivemind"
#define TRAIT_ADAPTIVE "adaptive"
#define TRAIT_PROGRAMMED "programmed"

// Special traits
#define TRAIT_ELITE "elite"
#define TRAIT_VOLATILE "volatile"
#define TRAIT_REGENERATIVE "regenerative"
#define TRAIT_TOXIC "toxic"
#define TRAIT_PSIONIC "psionic"
#define TRAIT_EXPERIMENTAL "experimental"

// Energy traits
#define TRAIT_ENERGIZED "energized"
#define TRAIT_EFFICIENT "efficient"
#define TRAIT_OVERCHARGED "overcharged"
#define TRAIT_DEPLETED "depleted"
#define TRAIT_CONDUCTIVE "conductive"

// Structural traits
#define TRAIT_REINFORCED "reinforced"
#define TRAIT_FRAGMENTED "fragmented"
#define TRAIT_MODULAR "modular"
#define TRAIT_OSSIFIED "ossified"
#define TRAIT_CRYSTALLINE "crystalline"

// Research point modifiers
#define TRAIT_BONUS_MAJOR 0.5 // 50% bonus
#define TRAIT_BONUS_MODERATE 0.3 // 30% bonus
#define TRAIT_BONUS_MINOR 0.15 // 15% bonus
#define TRAIT_PENALTY_MINOR -0.15 // 15% penalty
#define TRAIT_PENALTY_MODERATE -0.3 // 30% penalty
#define TRAIT_PENALTY_MAJOR -0.5 // 50% penalty



// Helper proc to get trait description
/proc/get_trait_description(trait)
	switch(trait)
		// Movement
		if(TRAIT_LIGHTWEIGHT)
			return "Enhanced speed or low mass"
		if(TRAIT_HEAVY)
			return "Significant mass or slow movement"
		if(TRAIT_AGILE)
			return "Special movement abilities"
		if(TRAIT_SLUGGISH)
			return "Slower than standard"
		if(TRAIT_ERRATIC)
			return "Unpredictable movement patterns"
		// Combat
		if(TRAIT_ARMORED)
			return "Heavy defensive capabilities"
		if(TRAIT_WEAPONIZED)
			return "High damage output"
		if(TRAIT_FODDER)
			return "Weak or expendable"
		if(TRAIT_BERSERKER)
			return "More dangerous at low health"
		if(TRAIT_PRECISION)
			return "Accurate, targeted attacks"
		if(TRAIT_BRUTAL)
			return "Crude but effective attacks"
		// Type
		if(TRAIT_MECHANICAL)
			return "Robotic or mechanical construction"
		if(TRAIT_ORGANIC)
			return "Flesh and blood construction"
		if(TRAIT_CORRUPTED)
			return "Tainted by greed or corruption"
		if(TRAIT_HYBRID)
			return "Mix of mechanical and organic"
		if(TRAIT_SYNTHETIC)
			return "Artificial organic components"
		if(TRAIT_ABERRANT)
			return "Unnatural or twisted form"
		// Intelligence
		if(TRAIT_NEURAL)
			return "Advanced AI or nervous system"
		if(TRAIT_RCE_PRIMITIVE)
			return "Basic intelligence or instincts"
		if(TRAIT_HIVEMIND)
			return "Connected to collective consciousness"
		if(TRAIT_ADAPTIVE)
			return "Can learn and adjust tactics"
		if(TRAIT_PROGRAMMED)
			return "Follows strict behavioral patterns"
		// Special
		if(TRAIT_ELITE)
			return "Boss or mini-boss tier"
		if(TRAIT_VOLATILE)
			return "Unstable or explosive"
		if(TRAIT_REGENERATIVE)
			return "Self-healing capabilities"
		if(TRAIT_TOXIC)
			return "Poisonous or corrosive elements"
		if(TRAIT_PSIONIC)
			return "Mental or psychic abilities"
		if(TRAIT_EXPERIMENTAL)
			return "Prototype or test subject"
		// Energy
		if(TRAIT_ENERGIZED)
			return "High energy output"
		if(TRAIT_EFFICIENT)
			return "Optimized energy usage"
		if(TRAIT_OVERCHARGED)
			return "Excessive power levels"
		if(TRAIT_DEPLETED)
			return "Low energy reserves"
		if(TRAIT_CONDUCTIVE)
			return "Electrical conductivity"
		// Structural
		if(TRAIT_REINFORCED)
			return "Extra structural support"
		if(TRAIT_FRAGMENTED)
			return "Damaged or incomplete structure"
		if(TRAIT_MODULAR)
			return "Interchangeable parts"
		if(TRAIT_OSSIFIED)
			return "Bone or bone-like structure"
		if(TRAIT_CRYSTALLINE)
			return "Crystal formations"
	return "Unknown trait"

// Helper proc to get trait color for UI
/proc/get_trait_color(trait, favored_list, negative_list, required_list)
	if(trait in required_list)
		return "#FFD700" // Gold for required
	if(trait in favored_list)
		return "#00FF00" // Green for favored
	if(trait in negative_list)
		return "#FF0000" // Red for negative
	return "#808080" // Gray for neutral
