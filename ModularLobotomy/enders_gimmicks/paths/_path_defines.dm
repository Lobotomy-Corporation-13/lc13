// ============================================================
// Path System — Constants, Defines, and Signal Strings
// ============================================================
// This file MUST be included before all other path files.
// ============================================================

// --- Resource Defaults ---
#define PATH_MAX_ENERGY_DEFAULT 100
#define PATH_MAX_AP_DEFAULT     5

// --- PvP Trace Scaling Targets ---
// Trace level at which PvP damage matches the original pvp_balance.md baseline.
// Below target: PvP damage is reduced (default-trace players hit softer).
// At target: PvP damage matches baseline.
// Above target: PvP damage is slightly higher (small reward for L11/L12).
#define PATH_TARGET_TRACE_BASIC    6
#define PATH_TARGET_TRACE_SKILL    10
#define PATH_TARGET_TRACE_ULT      10
#define PATH_TARGET_TRACE_PASSIVE  10

// --- Skill Tree Node Types ---
#define PATH_NODE_STAT    "stat"
#define PATH_NODE_ABILITY "ability"
#define PATH_NODE_PASSIVE "passive"

// --- Ability Target Strings ---
#define PATH_ABILITY_BASIC    "basic"
#define PATH_ABILITY_BURST    "burst"
#define PATH_ABILITY_ULTIMATE "ultimate"
#define PATH_ABILITY_PASSIVE  "passive"

// --- Elemental Types ---
#define PATH_ELEMENT_PHYSICAL  "physical"
#define PATH_ELEMENT_FIRE      "fire"
#define PATH_ELEMENT_ICE       "ice"
#define PATH_ELEMENT_LIGHTNING "lightning"
#define PATH_ELEMENT_WIND      "wind"
#define PATH_ELEMENT_QUANTUM   "quantum"
#define PATH_ELEMENT_IMAGINARY "imaginary"

// --- Path Realm ---
/// How many players may walk the Path Realm at once. Each loads its own
/// Z-level, so this only bounds simultaneous Z-level loading.
#define PATH_REALM_MAX_CONCURRENT 4

// --- Combat Tuning ---
// These two only affect PvE. The PvP pipeline in deal_path_damage() (pvp_factor,
// HP-ratio scaling, armour average) is untouched, so the figures in
// plans/pvp_balance.md and plans/lever_4_hp_growth_reduction.md still hold.

/// Damage fraction for basic swings after the first hit of a turn. A turn fits
/// roughly six swings, so at the old 0.1 every swing but the first read as a
/// no-op to players.
#define PATH_FOLLOWUP_MULT 0.3
/// Flat damage multiplier against non-human targets only.
#define PATH_PVE_DAMAGE_MULT 1.5
/// Extra damage reduction at Lv.1, decaying linearly to zero at this level.
/// Lifts the early-game floor without touching the tuned Lv.60+ endpoint.
#define PATH_LOW_LEVEL_DR      12
#define PATH_LOW_LEVEL_DR_ZERO 60

// --- Speed & Turn System ---
#define PATH_BASE_SPEED    100
#define PATH_TURN_BASE     5 SECONDS

/// Turn state: can attack or use skill
#define PATH_TURN_READY    0
/// Turn state: already attacked this turn, skill locked
#define PATH_TURN_ATTACKED 1
/// Turn state: already used skill this turn, AP/energy locked
#define PATH_TURN_SKILLED  2

// --- DoT Types ---
#define PATH_DOT_BLEED      "bleed"
#define PATH_DOT_BURN       "burn"
#define PATH_DOT_SHOCK      "shock"
#define PATH_DOT_WIND_SHEAR "wind_shear"

// --- RES Defaults ---
/// 20% RES to non-weak elements
#define PATH_RES_DEFAULT  20
/// 0% RES to weak element
#define PATH_RES_WEAK     0
/// 40% RES for boss/white enemies
#define PATH_RES_BOSS     40
/// Min effective RES after PEN (clamp)
#define PATH_RES_MIN      -100
/// Max effective RES after PEN (clamp)
#define PATH_RES_MAX      90

// --- Progression Material Rarity Tiers ---
/// T1 = 2-star, T2 = 3-star, T3 = 4-star (star count = tier + 1)
#define PATH_MAT_T1 1
#define PATH_MAT_T2 2
#define PATH_MAT_T3 3

// --- Path Keys (match /datum/path leaf types) ---
#define PATH_KEY_DESTRUCTION  "destruction"
#define PATH_KEY_HUNT         "hunt"
#define PATH_KEY_ERUDITION    "erudition"
#define PATH_KEY_NIHILITY     "nihility"
#define PATH_KEY_HARMONY      "harmony"
#define PATH_KEY_PRESERVATION "preservation"
#define PATH_KEY_ABUNDANCE    "abundance"

// --- Trace Material Family Keys ---
#define TRACE_FAMILY_FANG  "fang"
#define TRACE_FAMILY_LENS  "lens"
#define TRACE_FAMILY_ICHOR "ichor"
#define TRACE_FAMILY_WARD  "ward"

// --- Custom Signals ---
/// Sent when a path is assigned to a mob. Args: (datum/path)
#define COMSIG_MOB_PATH_ASSIGNED   "mob_path_assigned"
/// Sent when a path is removed from a mob. Args: (datum/path)
#define COMSIG_MOB_PATH_REMOVED    "mob_path_removed"
/// Sent when path energy changes. Args: (new_energy, max_energy)
#define COMSIG_PATH_ENERGY_CHANGED "path_energy_changed"
/// Sent when path action points change. Args: (new_ap, max_ap)
#define COMSIG_PATH_AP_CHANGED     "path_ap_changed"
/// Sent on the TARGET mob when an ally path user buffs them. Args: (datum/path/source_path, buff_type)
#define COMSIG_MOB_PATH_ALLY_BUFFED "mob_path_ally_buffed"
/// Buff type strings for COMSIG_MOB_PATH_ALLY_BUFFED
#define PATH_BUFF_BENEDICTION "benediction"
#define PATH_BUFF_DMG_UP      "dmg_buff"
#define PATH_BUFF_HEAL        "heal"
#define PATH_BUFF_SHIELD      "shield"
