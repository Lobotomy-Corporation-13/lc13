// Temporary test skills for validating the association skill system.
// These should be removed once real association skills are implemented.

/// Test skill that prints a message when the owner attacks a target.
/datum/component/association_skill/test_alpha
	skill_name = "Test Alpha"
	skill_desc = "A test skill that prints a message on attack."
	branch = "test_branch"
	tier = 1
	choice = "a"

/datum/component/association_skill/test_alpha/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	to_chat(human_parent, span_nicegreen("Test Alpha: You attacked [target]!"))

/// Test skill that prints a message when the owner takes damage.
/datum/component/association_skill/test_beta
	skill_name = "Test Beta"
	skill_desc = "A test skill that prints a message when you take damage."
	branch = "test_branch"
	tier = 1
	choice = "b"

/datum/component/association_skill/test_beta/on_take_damage(datum/source, damage, damagetype, def_zone)
	if(!can_use_skill())
		return
	to_chat(human_parent, span_warning("Test Beta: You took [damage] [damagetype] damage!"))

// Register test skills in the global skill definitions
/proc/init_test_association_skills()
	if(!GLOB.association_skill_definitions[ASSOCIATION_ZWEI])
		GLOB.association_skill_definitions[ASSOCIATION_ZWEI] = list()
	var/list/zwei_defs = GLOB.association_skill_definitions[ASSOCIATION_ZWEI]
	if(!zwei_defs["test_branch"])
		zwei_defs["test_branch"] = list()
	var/list/branch_defs = zwei_defs["test_branch"]
	if(!branch_defs["tier1"])
		branch_defs["tier1"] = list()
	branch_defs["tier1"]["a"] = list("name" = "Test Alpha", "desc" = "A test skill that prints a message on attack.", "type" = /datum/component/association_skill/test_alpha)
	branch_defs["tier1"]["b"] = list("name" = "Test Beta", "desc" = "A test skill that prints a message when you take damage.", "type" = /datum/component/association_skill/test_beta)

/proc/init_association_skill_definitions()
	init_test_association_skills()
