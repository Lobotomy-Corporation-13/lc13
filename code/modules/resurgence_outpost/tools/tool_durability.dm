/**
 * Resurgence Outpost - Tool Durability System
 *
 * Tools provide work bonuses and XP multipliers but degrade with use.
 * Only active when SSmaptype.maptype == "outpost"
 *
 * Tier System:
 * - Wood: 200 durability, +3 work/tick, 1.25x XP
 * - Iron: 300 durability, +5 work/tick, 1.5x XP
 * - Silver: 500 durability, +8 work/tick, 2.0x XP
 */

/// Tool tier constants
#define TOOL_TIER_NONE 0
#define TOOL_TIER_WOOD 1
#define TOOL_TIER_IRON 2
#define TOOL_TIER_SILVER 3

/// Durability by tier
#define DURABILITY_WOOD 200
#define DURABILITY_IRON 300
#define DURABILITY_SILVER 500

/// Work bonus by tier
#define WORK_BONUS_WOOD 3
#define WORK_BONUS_IRON 5
#define WORK_BONUS_SILVER 8

/// XP multiplier by tier
#define XP_MULT_WOOD 1.25
#define XP_MULT_IRON 1.5
#define XP_MULT_SILVER 2.0

/// Check if the durability system is active (outpost gamemode only)
/proc/is_durability_active()
	return SSmaptype.maptype == "outpost"

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

/// Get the work bonus for a tool based on its tier
/proc/get_tool_work_bonus(obj/item/tool)
	if(!is_durability_active())
		return 0
	switch(get_tool_tier(tool))
		if(TOOL_TIER_WOOD)
			return WORK_BONUS_WOOD
		if(TOOL_TIER_IRON)
			return WORK_BONUS_IRON
		if(TOOL_TIER_SILVER)
			return WORK_BONUS_SILVER
	return 0

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
		var/percent = get_tool_durability_percent(src)
		var/list/condition = get_durability_condition(percent)
		. += span_notice("Durability: [resurgence_durability]/[resurgence_max_durability] ([percent]%) - <span class='[condition[2]]'>[condition[1]]</span>")

/obj/item/pickaxe/examine(mob/user)
	. = ..()
	if(is_durability_active() && resurgence_max_durability > 0)
		var/percent = get_tool_durability_percent(src)
		var/list/condition = get_durability_condition(percent)
		. += span_notice("Durability: [resurgence_durability]/[resurgence_max_durability] ([percent]%) - <span class='[condition[2]]'>[condition[1]]</span>")

/obj/item/scythe/examine(mob/user)
	. = ..()
	if(is_durability_active() && resurgence_max_durability > 0)
		var/percent = get_tool_durability_percent(src)
		var/list/condition = get_durability_condition(percent)
		. += span_notice("Durability: [resurgence_durability]/[resurgence_max_durability] ([percent]%) - <span class='[condition[2]]'>[condition[1]]</span>")

/obj/item/shovel/examine(mob/user)
	. = ..()
	if(is_durability_active() && resurgence_max_durability > 0)
		var/percent = get_tool_durability_percent(src)
		var/list/condition = get_durability_condition(percent)
		. += span_notice("Durability: [resurgence_durability]/[resurgence_max_durability] ([percent]%) - <span class='[condition[2]]'>[condition[1]]</span>")

/obj/item/crowbar/examine(mob/user)
	. = ..()
	if(is_durability_active() && resurgence_max_durability > 0)
		var/percent = get_tool_durability_percent(src)
		var/list/condition = get_durability_condition(percent)
		. += span_notice("Durability: [resurgence_durability]/[resurgence_max_durability] ([percent]%) - <span class='[condition[2]]'>[condition[1]]</span>")
