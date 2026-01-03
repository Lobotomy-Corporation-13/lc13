/**
 * Resurgence Outpost - Tool Durability System
 *
 * Tools provide work bonuses and XP multipliers but degrade with use.
 * Only active when SSmaptype.maptype == "outpost"
 *
 * Material Tier System:
 * - Wood: 200 base durability, +3 base work/tick, 1.25x XP
 * - Iron: 300 base durability, +5 base work/tick, 1.5x XP
 * - Silver: 500 base durability, +8 base work/tick, 2.0x XP
 *
 * Quality Tier System (determined by crafter's skill):
 * - Shoddy (1): No bonus
 * - Common (2): +2 work, +10% durability
 * - Quality (3): +4 work, +20% durability
 * - Excellent (4): +6 work, +30% durability
 * - Masterwork (5): +8 work, +40% durability
 *
 * Quality tier ranges by crafting skill:
 * - Level 1-4: tiers 1-2
 * - Level 5-9: tiers 1-3
 * - Level 10-14: tiers 2-4
 * - Level 15-19: tiers 3-5
 * - Level 20: tiers 4-5
 */

/// Tool material tier constants
#define TOOL_TIER_NONE 0
#define TOOL_TIER_WOOD 1
#define TOOL_TIER_IRON 2
#define TOOL_TIER_SILVER 3

/// Tool quality tier constants
#define QUALITY_TIER_SHODDY 1
#define QUALITY_TIER_COMMON 2
#define QUALITY_TIER_QUALITY 3
#define QUALITY_TIER_EXCELLENT 4
#define QUALITY_TIER_MASTERWORK 5

/// Durability by material tier
#define DURABILITY_WOOD 200
#define DURABILITY_IRON 300
#define DURABILITY_SILVER 500

/// Work bonus by material tier
#define WORK_BONUS_WOOD 3
#define WORK_BONUS_IRON 5
#define WORK_BONUS_SILVER 8

/// XP multiplier by material tier
#define XP_MULT_WOOD 1.25
#define XP_MULT_IRON 1.5
#define XP_MULT_SILVER 2.0

/// Check if the durability system is active (outpost gamemode only)
/proc/is_durability_active()
	return SSmaptype.maptype == "outpost"

// ============================================
// Quality Tier System
// ============================================

/**
 * Get the quality tier range for a given crafting skill level.
 *
 * Arguments:
 * * skill_level - The crafter's crafting skill (1-20)
 *
 * Returns: list(min_tier, max_tier)
 */
/proc/get_quality_tier_range(skill_level)
	skill_level = clamp(skill_level, 1, 20)
	if(skill_level >= 20)
		return list(QUALITY_TIER_EXCELLENT, QUALITY_TIER_MASTERWORK) // 4-5
	if(skill_level >= 15)
		return list(QUALITY_TIER_QUALITY, QUALITY_TIER_MASTERWORK) // 3-5
	if(skill_level >= 10)
		return list(QUALITY_TIER_COMMON, QUALITY_TIER_EXCELLENT) // 2-4
	if(skill_level >= 5)
		return list(QUALITY_TIER_SHODDY, QUALITY_TIER_QUALITY) // 1-3
	return list(QUALITY_TIER_SHODDY, QUALITY_TIER_COMMON) // 1-2

/**
 * Roll a random quality tier based on crafter's skill level.
 *
 * Arguments:
 * * skill_level - The crafter's crafting skill (1-20)
 *
 * Returns: Quality tier (1-5)
 */
/proc/roll_quality_tier(skill_level)
	var/list/range = get_quality_tier_range(skill_level)
	return rand(range[1], range[2])

/**
 * Get the name of a quality tier.
 *
 * Arguments:
 * * quality_tier - The quality tier (1-5)
 *
 * Returns: Quality tier name
 */
/proc/get_quality_tier_name(quality_tier)
	switch(quality_tier)
		if(QUALITY_TIER_SHODDY)
			return "Shoddy"
		if(QUALITY_TIER_COMMON)
			return "Common"
		if(QUALITY_TIER_QUALITY)
			return "Quality"
		if(QUALITY_TIER_EXCELLENT)
			return "Excellent"
		if(QUALITY_TIER_MASTERWORK)
			return "Masterwork"
	return "Unknown"

/**
 * Get the color for a quality tier (for display).
 *
 * Arguments:
 * * quality_tier - The quality tier (1-5)
 *
 * Returns: Color class name
 */
/proc/get_quality_tier_color(quality_tier)
	switch(quality_tier)
		if(QUALITY_TIER_SHODDY)
			return "bad"
		if(QUALITY_TIER_COMMON)
			return "label"
		if(QUALITY_TIER_QUALITY)
			return "good"
		if(QUALITY_TIER_EXCELLENT)
			return "blue"
		if(QUALITY_TIER_MASTERWORK)
			return "purple"
	return "label"

/**
 * Get the work bonus from quality tier.
 * Each tier adds (tier - 1) * 2 work.
 *
 * Arguments:
 * * quality_tier - The quality tier (1-5)
 *
 * Returns: Additional work per tick
 */
/proc/get_quality_work_bonus(quality_tier)
	quality_tier = clamp(quality_tier, 1, 5)
	return (quality_tier - 1) * 2 // 0, 2, 4, 6, 8

/**
 * Get the durability multiplier from quality tier.
 *
 * Arguments:
 * * quality_tier - The quality tier (1-5)
 *
 * Returns: Durability multiplier (1.0 to 1.4)
 */
/proc/get_quality_durability_mult(quality_tier)
	quality_tier = clamp(quality_tier, 1, 5)
	return 1.0 + (quality_tier - 1) * 0.1 // 1.0, 1.1, 1.2, 1.3, 1.4

/**
 * Get the quality tier of a tool.
 *
 * Arguments:
 * * tool - The tool to check
 *
 * Returns: Quality tier (1-5), or 1 if not set
 */
/proc/get_tool_quality_tier(obj/item/tool)
	if(!tool)
		return QUALITY_TIER_SHODDY
	if(istype(tool, /obj/item/hatchet))
		var/obj/item/hatchet/H = tool
		return H.resurgence_quality_tier
	if(istype(tool, /obj/item/pickaxe))
		var/obj/item/pickaxe/P = tool
		return P.resurgence_quality_tier
	if(istype(tool, /obj/item/scythe))
		var/obj/item/scythe/S = tool
		return S.resurgence_quality_tier
	if(istype(tool, /obj/item/shovel))
		var/obj/item/shovel/SH = tool
		return SH.resurgence_quality_tier
	if(istype(tool, /obj/item/crowbar))
		var/obj/item/crowbar/C = tool
		return C.resurgence_quality_tier
	return QUALITY_TIER_SHODDY

/**
 * Set the quality tier of a tool and update its stats.
 *
 * Arguments:
 * * tool - The tool to modify
 * * quality_tier - The quality tier to set (1-5)
 */
/proc/set_tool_quality_tier(obj/item/tool, quality_tier)
	if(!tool)
		return
	quality_tier = clamp(quality_tier, 1, 5)
	var/durability_mult = get_quality_durability_mult(quality_tier)

	if(istype(tool, /obj/item/hatchet))
		var/obj/item/hatchet/H = tool
		H.resurgence_quality_tier = quality_tier
		H.resurgence_max_durability = round(initial(H.resurgence_max_durability) * durability_mult)
		H.resurgence_durability = H.resurgence_max_durability
		update_tool_name(H)
		return
	if(istype(tool, /obj/item/pickaxe))
		var/obj/item/pickaxe/P = tool
		P.resurgence_quality_tier = quality_tier
		P.resurgence_max_durability = round(initial(P.resurgence_max_durability) * durability_mult)
		P.resurgence_durability = P.resurgence_max_durability
		update_tool_name(P)
		return
	if(istype(tool, /obj/item/scythe))
		var/obj/item/scythe/S = tool
		S.resurgence_quality_tier = quality_tier
		S.resurgence_max_durability = round(initial(S.resurgence_max_durability) * durability_mult)
		S.resurgence_durability = S.resurgence_max_durability
		update_tool_name(S)
		return
	if(istype(tool, /obj/item/shovel))
		var/obj/item/shovel/SH = tool
		SH.resurgence_quality_tier = quality_tier
		SH.resurgence_max_durability = round(initial(SH.resurgence_max_durability) * durability_mult)
		SH.resurgence_durability = SH.resurgence_max_durability
		update_tool_name(SH)
		return
	if(istype(tool, /obj/item/crowbar))
		var/obj/item/crowbar/C = tool
		C.resurgence_quality_tier = quality_tier
		C.resurgence_max_durability = round(initial(C.resurgence_max_durability) * durability_mult)
		C.resurgence_durability = C.resurgence_max_durability
		update_tool_name(C)
		return

/**
 * Update tool name to include quality tier prefix.
 *
 * Arguments:
 * * tool - The tool to update
 */
/proc/update_tool_name(obj/item/tool)
	if(!tool)
		return
	var/quality_tier = get_tool_quality_tier(tool)
	if(quality_tier <= QUALITY_TIER_SHODDY)
		return // Don't prefix shoddy items
	var/quality_name = get_quality_tier_name(quality_tier)
	var/base_name = initial(tool.name)
	tool.name = "[quality_name] [base_name]"

/// Get the tool tier for a given tool
/// Returns TOOL_TIER_NONE (0) if not a tiered tool
/proc/get_tool_tier(obj/item/tool)
	if(!tool)
		return TOOL_TIER_NONE

	// Hatchets
	if(istype(tool, /obj/item/hatchet/wooden))
		return TOOL_TIER_WOOD
	if(istype(tool, /obj/item/hatchet))
		return TOOL_TIER_IRON

	// Pickaxes
	if(istype(tool, /obj/item/pickaxe/improvised))
		return TOOL_TIER_WOOD
	if(istype(tool, /obj/item/pickaxe/silver))
		return TOOL_TIER_SILVER
	if(istype(tool, /obj/item/pickaxe/mini))
		return TOOL_TIER_IRON  // Compact pickaxe = iron tier
	if(istype(tool, /obj/item/pickaxe))
		return TOOL_TIER_IRON

	// Scythe
	if(istype(tool, /obj/item/scythe/wooden))
		return TOOL_TIER_WOOD
	if(istype(tool, /obj/item/scythe))
		return TOOL_TIER_IRON

	// Crowbars
	if(istype(tool, /obj/item/crowbar/large))
		return TOOL_TIER_IRON
	if(istype(tool, /obj/item/crowbar))
		return TOOL_TIER_WOOD  // Compact crowbar = wood tier

	// Shovel
	if(istype(tool, /obj/item/shovel))
		return TOOL_TIER_IRON

	return TOOL_TIER_NONE

/// Get the work bonus for a tool based on its material tier and quality tier
/proc/get_tool_work_bonus(obj/item/tool)
	if(!is_durability_active())
		return 0

	var/base_bonus = 0
	switch(get_tool_tier(tool))
		if(TOOL_TIER_WOOD)
			base_bonus = WORK_BONUS_WOOD
		if(TOOL_TIER_IRON)
			base_bonus = WORK_BONUS_IRON
		if(TOOL_TIER_SILVER)
			base_bonus = WORK_BONUS_SILVER

	// Add quality tier bonus
	var/quality_bonus = get_quality_work_bonus(get_tool_quality_tier(tool))

	return base_bonus + quality_bonus

/// Get the XP multiplier for a tool based on its tier
/proc/get_tool_xp_multiplier(obj/item/tool)
	if(!is_durability_active())
		return 1.0
	switch(get_tool_tier(tool))
		if(TOOL_TIER_WOOD)
			return XP_MULT_WOOD
		if(TOOL_TIER_IRON)
			return XP_MULT_IRON
		if(TOOL_TIER_SILVER)
			return XP_MULT_SILVER
	return 1.0

/// Decrement tool durability by 1
/// Returns TRUE if tool is still usable, FALSE if tool broke
/proc/use_tool_durability(obj/item/tool, mob/user)
	if(!is_durability_active())
		return TRUE
	if(!tool)
		return TRUE

	// Get durability values based on tool type
	var/durability = get_tool_durability(tool)
	var/max_durability = get_tool_max_durability(tool)

	// Tool doesn't have durability
	if(durability < 0)
		return TRUE

	durability--
	set_tool_durability(tool, durability)

	// Check if tool broke
	if(durability <= 0)
		to_chat(user, span_warning("[tool] breaks apart from wear!"))
		playsound(tool, 'sound/effects/bang.ogg', 30, TRUE)
		qdel(tool)
		return FALSE

	// Warn when durability is low (at 20% or less)
	if(max_durability > 0)
		var/percent = (durability / max_durability) * 100
		if(percent <= 20 && percent > 10)
			to_chat(user, span_warning("[tool] is showing signs of wear..."))
		else if(percent <= 10)
			to_chat(user, span_danger("[tool] is about to break!"))

	return TRUE

/// Get the current durability of a tool (-1 if not a durability tool)
/proc/get_tool_durability(obj/item/tool)
	if(!tool)
		return -1
	// Check each tool type
	if(istype(tool, /obj/item/hatchet))
		var/obj/item/hatchet/H = tool
		return H.resurgence_durability
	if(istype(tool, /obj/item/pickaxe))
		var/obj/item/pickaxe/P = tool
		return P.resurgence_durability
	if(istype(tool, /obj/item/scythe))
		var/obj/item/scythe/S = tool
		return S.resurgence_durability
	if(istype(tool, /obj/item/shovel))
		var/obj/item/shovel/SH = tool
		return SH.resurgence_durability
	if(istype(tool, /obj/item/crowbar))
		var/obj/item/crowbar/C = tool
		return C.resurgence_durability
	return -1

/// Get the max durability of a tool (0 if not a durability tool)
/proc/get_tool_max_durability(obj/item/tool)
	if(!tool)
		return 0
	// Check each tool type
	if(istype(tool, /obj/item/hatchet))
		var/obj/item/hatchet/H = tool
		return H.resurgence_max_durability
	if(istype(tool, /obj/item/pickaxe))
		var/obj/item/pickaxe/P = tool
		return P.resurgence_max_durability
	if(istype(tool, /obj/item/scythe))
		var/obj/item/scythe/S = tool
		return S.resurgence_max_durability
	if(istype(tool, /obj/item/shovel))
		var/obj/item/shovel/SH = tool
		return SH.resurgence_max_durability
	if(istype(tool, /obj/item/crowbar))
		var/obj/item/crowbar/C = tool
		return C.resurgence_max_durability
	return 0

/// Set the durability of a tool
/proc/set_tool_durability(obj/item/tool, value)
	if(!tool)
		return
	// Check each tool type
	if(istype(tool, /obj/item/hatchet))
		var/obj/item/hatchet/H = tool
		H.resurgence_durability = value
		return
	if(istype(tool, /obj/item/pickaxe))
		var/obj/item/pickaxe/P = tool
		P.resurgence_durability = value
		return
	if(istype(tool, /obj/item/scythe))
		var/obj/item/scythe/S = tool
		S.resurgence_durability = value
		return
	if(istype(tool, /obj/item/shovel))
		var/obj/item/shovel/SH = tool
		SH.resurgence_durability = value
		return
	if(istype(tool, /obj/item/crowbar))
		var/obj/item/crowbar/C = tool
		C.resurgence_durability = value
		return

/// Get the current durability percentage of a tool (0-100)
/proc/get_tool_durability_percent(obj/item/tool)
	var/durability = get_tool_durability(tool)
	var/max_durability = get_tool_max_durability(tool)
	if(durability < 0 || max_durability <= 0)
		return 100
	return round((durability / max_durability) * 100)

/// Get durability condition text based on percentage
/proc/get_durability_condition(percent)
	if(percent >= 90)
		return list("pristine", "good")
	if(percent >= 70)
		return list("good", "good")
	if(percent >= 50)
		return list("worn", "average")
	if(percent >= 30)
		return list("damaged", "orange")
	if(percent >= 10)
		return list("heavily damaged", "bad")
	return list("about to break", "bad")

// ============================================
// Examine Hooks for Tools
// ============================================

/obj/item/hatchet/examine(mob/user)
	. = ..()
	if(is_durability_active() && resurgence_max_durability > 0)
		var/quality_tier = resurgence_quality_tier
		var/quality_name = get_quality_tier_name(quality_tier)
		var/quality_color = get_quality_tier_color(quality_tier)
		. += span_notice("Quality: <span class='[quality_color]'>[quality_name]</span>")
		var/percent = get_tool_durability_percent(src)
		var/list/condition = get_durability_condition(percent)
		. += span_notice("Durability: [resurgence_durability]/[resurgence_max_durability] ([percent]%) - <span class='[condition[2]]'>[condition[1]]</span>")

/obj/item/pickaxe/examine(mob/user)
	. = ..()
	if(is_durability_active() && resurgence_max_durability > 0)
		var/quality_tier = resurgence_quality_tier
		var/quality_name = get_quality_tier_name(quality_tier)
		var/quality_color = get_quality_tier_color(quality_tier)
		. += span_notice("Quality: <span class='[quality_color]'>[quality_name]</span>")
		var/percent = get_tool_durability_percent(src)
		var/list/condition = get_durability_condition(percent)
		. += span_notice("Durability: [resurgence_durability]/[resurgence_max_durability] ([percent]%) - <span class='[condition[2]]'>[condition[1]]</span>")

/obj/item/scythe/examine(mob/user)
	. = ..()
	if(is_durability_active() && resurgence_max_durability > 0)
		var/quality_tier = resurgence_quality_tier
		var/quality_name = get_quality_tier_name(quality_tier)
		var/quality_color = get_quality_tier_color(quality_tier)
		. += span_notice("Quality: <span class='[quality_color]'>[quality_name]</span>")
		var/percent = get_tool_durability_percent(src)
		var/list/condition = get_durability_condition(percent)
		. += span_notice("Durability: [resurgence_durability]/[resurgence_max_durability] ([percent]%) - <span class='[condition[2]]'>[condition[1]]</span>")

/obj/item/shovel/examine(mob/user)
	. = ..()
	if(is_durability_active() && resurgence_max_durability > 0)
		var/quality_tier = resurgence_quality_tier
		var/quality_name = get_quality_tier_name(quality_tier)
		var/quality_color = get_quality_tier_color(quality_tier)
		. += span_notice("Quality: <span class='[quality_color]'>[quality_name]</span>")
		var/percent = get_tool_durability_percent(src)
		var/list/condition = get_durability_condition(percent)
		. += span_notice("Durability: [resurgence_durability]/[resurgence_max_durability] ([percent]%) - <span class='[condition[2]]'>[condition[1]]</span>")

/obj/item/crowbar/examine(mob/user)
	. = ..()
	if(is_durability_active() && resurgence_max_durability > 0)
		var/quality_tier = resurgence_quality_tier
		var/quality_name = get_quality_tier_name(quality_tier)
		var/quality_color = get_quality_tier_color(quality_tier)
		. += span_notice("Quality: <span class='[quality_color]'>[quality_name]</span>")
		var/percent = get_tool_durability_percent(src)
		var/list/condition = get_durability_condition(percent)
		. += span_notice("Durability: [resurgence_durability]/[resurgence_max_durability] ([percent]%) - <span class='[condition[2]]'>[condition[1]]</span>")
