// Association Rework - Defines and Global Variables

// Association type constants
#define ASSOCIATION_ZWEI "zwei"
#define ASSOCIATION_SEVEN "seven"
#define ASSOCIATION_DIECI "dieci"
#define ASSOCIATION_CINQ "cinq"

// Maximum number of branches a player can invest in
#define ASSOCIATION_MAX_BRANCHES 2

// Contract state constants
#define CONTRACT_STATE_PENDING "pending"
#define CONTRACT_STATE_ACTIVE "active"
#define CONTRACT_STATE_COMPLETED "completed"
#define CONTRACT_STATE_FAILED "failed"

// Contract source constants (who created the contract)
#define CONTRACT_SOURCE_HANA "hana"
#define CONTRACT_SOURCE_CIVILIAN "civilian"

// Contract category constants
#define CONTRACT_CATEGORY_DURATION "duration"
#define CONTRACT_CATEGORY_OBJECTIVE "objective"

// Duration tier constants (in deciseconds)
#define CONTRACT_TIER_SHORT (6 MINUTES)
#define CONTRACT_TIER_MEDIUM (10 MINUTES)
#define CONTRACT_TIER_LONG (20 MINUTES)

// Passive EXP tick for duration-based contracts
#define CONTRACT_PASSIVE_EXP_TICK 1
#define CONTRACT_PASSIVE_INTERVAL (10 SECONDS)

// Completion EXP bonuses by tier
#define CONTRACT_COMPLETION_SHORT 25
#define CONTRACT_COMPLETION_MEDIUM 38
#define CONTRACT_COMPLETION_LONG 63
#define CONTRACT_COMPLETION_OBJECTIVE 76

// Civilian contracts give double EXP
#define CONTRACT_CIVILIAN_EXP_MULT 2

// Cooldown between contracts (after last one ends)
#define CONTRACT_COOLDOWN (30 SECONDS)

// Distress system constants
#define CONTRACT_DISTRESS_COOLDOWN (5 MINUTES)
#define CONTRACT_DISTRESS_DURATION (60 SECONDS)
#define CONTRACT_DISTRESS_HP_THRESHOLD 0.5

// City map tile type constants
#define CITYMAP_EMPTY 0
#define CITYMAP_WALL 1
#define CITYMAP_FLOOR 2

// City map viewport size (tiles shown at once)
#define CITYMAP_VIEWPORT_SIZE 20

// City map viewport movement step
#define CITYMAP_MOVE_STEP 10

// Maximum waypoints per map session
#define CITYMAP_MAX_WAYPOINTS 10

// Patrol contract constants
#define CONTRACT_PATROL_STAY_TIME (30 SECONDS)
#define CONTRACT_PATROL_RADIUS 3
#define CONTRACT_PATROL_BASE_COST 200
#define CONTRACT_PATROL_COST_PER_POINT 150
#define CONTRACT_PATROL_EXP_PER_POINT 25

// EXP thresholds - cumulative EXP required for each skill point (12 total)
GLOBAL_LIST_INIT(association_exp_thresholds, list(30, 70, 120, 180, 350, 600, 950, 1400, 1950, 2600, 3350, 4200))

// Global list of all active squads
GLOBAL_LIST_EMPTY(association_squads)

// Global skill definitions - populated by individual skill files
// Structure: association_skill_definitions[association_type][branch_name][tier_key][choice] = list("name", "desc", "type")
// tier_key = "tier1", "tier2", "tier3"
// choice = "a" or "b"
GLOBAL_LIST_EMPTY(association_skill_definitions)

/// Returns the human-readable name for an association type constant
/proc/association_type_to_name(association_type)
	switch(association_type)
		if(ASSOCIATION_ZWEI)
			return "Zwei"
		if(ASSOCIATION_SEVEN)
			return "Seven"
		if(ASSOCIATION_DIECI)
			return "Dieci"
		if(ASSOCIATION_CINQ)
			return "Cinq"
	return "Unknown"

/// Returns the skill point cost for a given tier (1-3)
/proc/association_tier_cost(tier)
	switch(tier)
		if(1)
			return 1
		if(2)
			return 2
		if(3)
			return 3
	return 0
