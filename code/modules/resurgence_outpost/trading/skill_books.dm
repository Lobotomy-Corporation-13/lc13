/**
 * Resurgence Outpost - Skill Books
 *
 * Books that grant XP to Resurgence Machine stats when read.
 * Uses the granter book framework.
 */

// XP amounts per tier (noticeable progress toward level up)
#define SKILL_BOOK_XP_TIER1 25   // Basic - small boost
#define SKILL_BOOK_XP_TIER2 50   // Standard - decent boost
#define SKILL_BOOK_XP_TIER3 100  // Advanced - significant boost

/obj/item/book/granter/resurgence_skill
	name = "skill book"
	desc = "A worn manual containing knowledge about a particular skill."
	icon_state = "book"
	pages_to_mastery = 2
	oneuse = TRUE

	/// The stat type this book grants XP to (crafting, mining, harvesting, cooking, analysis)
	var/stat_type = "crafting"
	/// Display name of the skill
	var/skill_name = "Crafting"
	/// Amount of XP granted
	var/xp_amount = SKILL_BOOK_XP_TIER1
	/// Tier of the book (1-3)
	var/tier = 1

/obj/item/book/granter/resurgence_skill/Initialize()
	. = ..()
	// Set up remarks based on skill
	setup_remarks()

/obj/item/book/granter/resurgence_skill/proc/setup_remarks()
	switch(stat_type)
		if("crafting")
			remarks = list(
				"The illustrations show precise hand movements...",
				"Measure twice, cut once... makes sense.",
				"Quality comes from patience and practice...",
				"So that's how you reinforce the joints..."
			)
		if("mining")
			remarks = list(
				"Strike at the natural fault lines...",
				"The angle of the pickaxe is crucial...",
				"Listen for hollow sounds in the rock...",
				"Ore veins follow predictable patterns..."
			)
		if("harvesting")
			remarks = list(
				"Harvest at the peak of ripeness...",
				"A clean cut promotes regrowth...",
				"The root system holds the key...",
				"Soil quality affects everything..."
			)
		if("cooking")
			remarks = list(
				"Temperature control is everything...",
				"Let the ingredients speak to you...",
				"Timing separates good from great...",
				"A sharp knife is a safe knife..."
			)
		if("analysis")
			remarks = list(
				"Observe before acting...",
				"Data without context is meaningless...",
				"Patterns emerge from careful study...",
				"Question your assumptions..."
			)

/obj/item/book/granter/resurgence_skill/already_known(mob/user)
	// Can always read skill books (they just give XP)
	return FALSE

/obj/item/book/granter/resurgence_skill/on_reading_start(mob/user)
	to_chat(user, span_notice("You begin studying the [skill_name] manual..."))

/obj/item/book/granter/resurgence_skill/on_reading_finished(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("The knowledge in this book seems beyond your comprehension."))
		return

	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)

	if(!istype(core))
		to_chat(user, span_warning("You lack the mechanical core needed to internalize this knowledge."))
		return

	// Award the XP
	core.award_xp(stat_type, xp_amount)
	to_chat(user, span_notice("You gain valuable insight into [skill_name]! (+[xp_amount] XP)"))
	playsound(user, 'sound/effects/phasein.ogg', 25, TRUE)
	onlearned(user)

/obj/item/book/granter/resurgence_skill/recoil(mob/user)
	to_chat(user, span_warning("The pages crumble to dust in your hands..."))
	qdel()

// ==================== Crafting Books ====================

/obj/item/book/granter/resurgence_skill/crafting
	name = "Beginner's Guide to Crafting"
	desc = "A basic manual covering fundamental crafting techniques."
	stat_type = "crafting"
	skill_name = "Crafting"
	xp_amount = SKILL_BOOK_XP_TIER1
	tier = 1
	custom_price = 50

/obj/item/book/granter/resurgence_skill/crafting/intermediate
	name = "Intermediate Crafting Manual"
	desc = "A detailed guide to advanced crafting methods and material properties."
	xp_amount = SKILL_BOOK_XP_TIER2
	tier = 2
	custom_price = 100

/obj/item/book/granter/resurgence_skill/crafting/advanced
	name = "Master Craftsman's Tome"
	desc = "A comprehensive treatise on the art of crafting, written by a renowned artificer."
	xp_amount = SKILL_BOOK_XP_TIER3
	tier = 3
	custom_price = 200

// ==================== Mining Books ====================

/obj/item/book/granter/resurgence_skill/mining
	name = "Prospector's Handbook"
	desc = "A basic guide to mining techniques and ore identification."
	stat_type = "mining"
	skill_name = "Mining"
	xp_amount = SKILL_BOOK_XP_TIER1
	tier = 1
	custom_price = 50

/obj/item/book/granter/resurgence_skill/mining/intermediate
	name = "Underground Extraction Manual"
	desc = "A detailed guide covering efficient mining methods and geological surveying."
	xp_amount = SKILL_BOOK_XP_TIER2
	tier = 2
	custom_price = 100

/obj/item/book/granter/resurgence_skill/mining/advanced
	name = "Deep Earth Compendium"
	desc = "An exhaustive study of mining techniques, ore veins, and underground survival."
	xp_amount = SKILL_BOOK_XP_TIER3
	tier = 3
	custom_price = 200

// ==================== Harvesting Books ====================

/obj/item/book/granter/resurgence_skill/harvesting
	name = "Farmer's Almanac"
	desc = "A basic guide to plant cultivation and harvesting."
	stat_type = "harvesting"
	skill_name = "Harvesting"
	xp_amount = SKILL_BOOK_XP_TIER1
	tier = 1
	custom_price = 50

/obj/item/book/granter/resurgence_skill/harvesting/intermediate
	name = "Agricultural Methods"
	desc = "A detailed manual on crop management, soil health, and yield optimization."
	xp_amount = SKILL_BOOK_XP_TIER2
	tier = 2
	custom_price = 100

/obj/item/book/granter/resurgence_skill/harvesting/advanced
	name = "Botanical Mastery"
	desc = "A comprehensive guide to advanced farming techniques and rare plant cultivation."
	xp_amount = SKILL_BOOK_XP_TIER3
	tier = 3
	custom_price = 200

// ==================== Cooking Books ====================

/obj/item/book/granter/resurgence_skill/cooking
	name = "Basic Recipes"
	desc = "A simple cookbook with fundamental cooking techniques."
	stat_type = "cooking"
	skill_name = "Cooking"
	xp_amount = SKILL_BOOK_XP_TIER1
	tier = 1
	custom_price = 50

/obj/item/book/granter/resurgence_skill/cooking/intermediate
	name = "Culinary Arts"
	desc = "A detailed cookbook covering advanced preparation and cooking methods."
	xp_amount = SKILL_BOOK_XP_TIER2
	tier = 2
	custom_price = 100

/obj/item/book/granter/resurgence_skill/cooking/advanced
	name = "Gastronomic Excellence"
	desc = "A masterwork cookbook containing secrets from renowned chefs."
	xp_amount = SKILL_BOOK_XP_TIER3
	tier = 3
	custom_price = 200

// ==================== Analysis Books ====================

/obj/item/book/granter/resurgence_skill/analysis
	name = "Introduction to Analysis"
	desc = "A basic guide to observation and data interpretation."
	stat_type = "analysis"
	skill_name = "Analysis"
	xp_amount = SKILL_BOOK_XP_TIER1
	tier = 1
	custom_price = 50

/obj/item/book/granter/resurgence_skill/analysis/intermediate
	name = "Research Methodology"
	desc = "A detailed manual on systematic analysis and pattern recognition."
	xp_amount = SKILL_BOOK_XP_TIER2
	tier = 2
	custom_price = 100

/obj/item/book/granter/resurgence_skill/analysis/advanced
	name = "Treatise on Observation"
	desc = "A comprehensive guide to advanced analytical techniques and deductive reasoning."
	xp_amount = SKILL_BOOK_XP_TIER3
	tier = 3
	custom_price = 200

#undef SKILL_BOOK_XP_TIER1
#undef SKILL_BOOK_XP_TIER2
#undef SKILL_BOOK_XP_TIER3
