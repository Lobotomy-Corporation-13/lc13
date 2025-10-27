/mob/living/simple_animal/hostile/distortion/envy_humanity
	name = "The Envy of Humanity"
	desc = "A writhing, shifting mass that hungers to become what it can never truly be."
	icon = 'ModularLobotomy/_Lobotomyicons/resurgence_64x96.dmi'
	icon_state = "envy"
	pixel_x = -16
	base_pixel_x = -16
	maxHealth = 2500
	health = 2500
	fear_level = WAW_LEVEL
	can_spawn = TRUE
	move_to_delay = 3
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 1.5)
	melee_damage_lower = 40
	melee_damage_upper = 45
	melee_damage_type = BLACK_DAMAGE
	stat_attack = HARD_CRIT
	attack_sound = 'sound/hallucinations/growl1.ogg'
	attack_verb_continuous = "tears at"
	attack_verb_simple = "tear at"

	// Ranged scanning capability
	ranged = TRUE
	ranged_cooldown_time = 3 SECONDS
	retreat_distance = 0
	minimum_distance = 0

	// Distortion-specific variables
	ego_list = list() // TODO: Add EGO items when designed
	gender = NEUTER
	egoist_outfit = /datum/outfit/job/civilian
	egoist_attributes = 80
	loot = list(/obj/item/documents/ncorporation, /obj/item/documents/ncorporation)
	monolith_abnormality = null // Not convertible
	unmanifest_effect = /obj/effect/gibspawner/human

	// Envy-specific variables
	/// List of recorded human data - stores appearance information
	var/list/recorded_bodies = list()
	/// Reference to the current human body we're inhabiting (if any)
	var/mob/living/carbon/human/current_disguise = null
	/// Reference to the current simple mob we're possessing (if any)
	var/mob/living/simple_animal/current_possessed_mob = null
	/// Reference to the current carbon mob we're possessing (if any)
	var/mob/living/carbon/current_possessed_carbon = null
	/// Recorded mind from a possessed carbon (if any)
	var/datum/mind/recorded_carbon_mind = null
	/// Are we currently in scanning mode?
	var/scanning_mode = TRUE
	/// Cooldown for scanning
	var/scan_cooldown = 0
	/// List of items created for current disguise (for cleanup)
	var/list/current_disguise_items = list()
	/// Are we currently in hidden/stealth mode?
	var/hidden_mode = FALSE
	/// Timer for ambient hidden messages
	var/next_hidden_message = 0

/mob/living/simple_animal/hostile/distortion/envy_humanity/Initialize()
	. = ..()
	recorded_bodies = list()

// Player-controlled version with action buttons
/mob/living/simple_animal/hostile/distortion/envy_humanity/player/Login()
	. = ..()
	to_chat(src, span_purple("You are the Envy of Humanity!"))
	to_chat(src, span_notice("You can:"))
	to_chat(src, span_notice("- Scan humans by targeting them (ranged attack)"))
	to_chat(src, span_notice("- Assume recorded forms to infiltrate and fight"))
	to_chat(src, span_notice("- Possess dead mobs (simple or carbon) by attacking their corpses"))
	to_chat(src, span_notice("- Use Lullaby of the Hidden to become nearly invisible"))
	to_chat(src, span_notice("- Phase through doors by attacking them"))
	to_chat(src, span_notice("- Explosively revert from human form when needed"))
	to_chat(src, span_notice("- Abandon possessed vessels when needed"))

/mob/living/simple_animal/hostile/distortion/envy_humanity/player/Initialize()
	. = ..()
	// Grant the assume form action
	var/datum/action/cooldown/assume_form/transform = new()
	transform.Grant(src)

	// Grant toggle scanning action
	var/datum/action/innate/toggle_scanning/toggle = new()
	toggle.Grant(src)

	// Grant lullaby stealth action
	var/datum/action/cooldown/lullaby_hidden/lullaby = new()
	lullaby.Grant(src)

	// Grant pained screech action
	var/datum/action/cooldown/pained_screech/screech = new()
	screech.Grant(src)

// Override EscapeConfinement to phase out instead of attacking
/mob/living/simple_animal/hostile/distortion/envy_humanity/EscapeConfinement()
	// Cannot escape while inside another form
	if(current_disguise || current_possessed_mob || current_possessed_carbon)
		return

	// Phase through buckles (like chairs, beds, etc)
	if(buckled)
		buckled.unbuckle_mob(src, force = TRUE)
		visible_message(span_warning("[src] phases through [buckled]!"))

	// Phase out of containers
	if(!isturf(targets_from.loc) && targets_from.loc != null)
		var/atom/container = targets_from.loc
		var/turf/exit_turf = get_turf(container)
		if(exit_turf)
			forceMove(exit_turf)
			visible_message(span_warning("[src] phases out of [container]!"))

// Override AttackingTarget to possess dead simple mobs and carbon mobs
/mob/living/simple_animal/hostile/distortion/envy_humanity/AttackingTarget(atom/attacked_target)
	// Cannot attack while inside another form
	if(current_disguise || current_possessed_mob || current_possessed_carbon)
		return FALSE

	// Door phasing - teleport through doors instead of attacking them
	if(istype(attacked_target, /obj/machinery/door) || istype(attacked_target, /obj/structure/mineral_door))
		var/turf/door_turf = get_turf(attacked_target)
		if(door_turf)
			forceMove(door_turf)
		return TRUE

	if(attacked_target == src)
		return FALSE

	// Break stealth if trying to attack while hidden
	if(hidden_mode)
		BreakStealth()

	// Check if target is a dead carbon mob we can possess
	if(istype(attacked_target, /mob/living/carbon))
		var/mob/living/carbon/C = attacked_target
		// Only possess if: dead and we're not already in a form (mind is now recorded rather than blocking possession)
		if(C.stat == DEAD && !current_disguise && !current_possessed_mob && !current_possessed_carbon)
			PossessCarbon(C)
			return TRUE

	// Check if target is a dead simple mob we can possess
	if(istype(attacked_target, /mob/living/simple_animal))
		var/mob/living/simple_animal/SA = attacked_target
		// Only possess if: dead, no existing mind/player, and we're not already in a form
		if(SA.stat == DEAD && !SA.mind && !current_disguise && !current_possessed_mob && !current_possessed_carbon)
			PossessMob(SA)
			return TRUE

	// Normal attack behavior for everything else
	return ..()

// Override OpenFire to scan instead of attacking
/mob/living/simple_animal/hostile/distortion/envy_humanity/OpenFire(atom/A)
	// Cannot use ranged attacks while inside another form
	if(current_disguise || current_possessed_mob || current_possessed_carbon)
		return

	// If we're not in scanning mode or on cooldown, don't scan
	if(!scanning_mode || world.time < scan_cooldown)
		return

	// Check if target is a human
	if(!ishuman(A))
		return

	var/mob/living/carbon/human/target = A

	// Perform the scan
	ScanHuman(target)

	// Set cooldown
	scan_cooldown = world.time + ranged_cooldown_time
	ranged_cooldown = world.time + ranged_cooldown_time

/// Scans a human and records their appearance
/mob/living/simple_animal/hostile/distortion/envy_humanity/proc/ScanHuman(mob/living/carbon/human/target)
	if(!target || !ishuman(target))
		return FALSE

	// Check if target is deleted or being deleted
	if(QDELETED(target))
		return FALSE

	// Check if this human is actually another Envy in disguise
	var/mob/living/simple_animal/hostile/distortion/envy_humanity/hidden_envy = locate(/mob/living/simple_animal/hostile/distortion/envy_humanity) in target
	if(hidden_envy)
		to_chat(src, span_warning("You sense another of your kind within this vessel..."))
		return FALSE

	// Verify target still exists and has critical data
	if(QDELETED(target) || !target.dna)
		return FALSE

	if(!target.dna.species)
		to_chat(src, span_warning("[target] has no discernible species data!"))
		return FALSE

	if(!target.real_name)
		to_chat(src, span_warning("[target] has no identity to record!"))
		return FALSE

	// Check if already scanned - if so, this will update the recording
	var/updating = FALSE
	if(recorded_bodies[target.real_name])
		to_chat(src, span_notice("Updating recorded data for [target.real_name]..."))
		updating = TRUE

	// Record the human's data (create new list to ensure clean data)
	var/list/body_data = list()
	body_data["real_name"] = target.real_name
	body_data["gender"] = target.gender
	body_data["species"] = target.dna.species.type

	// Copy DNA (with additional safety check)
	if(QDELETED(target) || !target.dna)
		return FALSE
	var/datum/dna/copied_dna = new /datum/dna
	target.dna.copy_dna(copied_dna)
	body_data["dna"] = copied_dna

	// Record attributes (with safety checks to ensure numeric values)
	body_data["fortitude"] = get_attribute_level(target, FORTITUDE_ATTRIBUTE) || 0
	body_data["prudence"] = get_attribute_level(target, PRUDENCE_ATTRIBUTE) || 0
	body_data["temperance"] = get_attribute_level(target, TEMPERANCE_ATTRIBUTE) || 0
	body_data["justice"] = get_attribute_level(target, JUSTICE_ATTRIBUTE) || 0

	// Record assigned role
	if(target.mind && target.mind.assigned_role)
		body_data["assigned_role"] = target.mind.assigned_role
	else
		body_data["assigned_role"] = "Unknown"

	// Appearance details
	body_data["underwear"] = target.underwear
	body_data["underwear_color"] = target.underwear_color
	body_data["eye_color"] = target.eye_color
	body_data["facial_hairstyle"] = target.facial_hairstyle
	body_data["facial_hair_color"] = target.facial_hair_color
	body_data["hairstyle"] = target.hairstyle
	body_data["hair_color"] = target.hair_color
	body_data["gradient_style"] = target.gradient_style || null
	body_data["gradient_color"] = target.gradient_color || "000"

	// Record ALL equipment worn by target
	var/list/equipment = list()

	// Verify target still valid before equipment scan
	if(QDELETED(target))
		return FALSE

	// Record each equipment slot
	var/obj/item/uniform_item = target.get_item_by_slot(ITEM_SLOT_ICLOTHING)
	if(uniform_item)
		equipment["uniform"] = uniform_item.type

	var/obj/item/suit_item = target.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(suit_item)
		equipment["suit"] = suit_item.type

	var/obj/item/shoes_item = target.get_item_by_slot(ITEM_SLOT_FEET)
	if(shoes_item)
		equipment["shoes"] = shoes_item.type

	var/obj/item/gloves_item = target.get_item_by_slot(ITEM_SLOT_GLOVES)
	if(gloves_item)
		equipment["gloves"] = gloves_item.type

	var/obj/item/head_item = target.get_item_by_slot(ITEM_SLOT_HEAD)
	if(head_item)
		equipment["head"] = head_item.type

	var/obj/item/mask_item = target.get_item_by_slot(ITEM_SLOT_MASK)
	if(mask_item)
		equipment["mask"] = mask_item.type

	var/obj/item/neck_item = target.get_item_by_slot(ITEM_SLOT_NECK)
	if(neck_item)
		equipment["neck"] = neck_item.type

	var/obj/item/ears_item = target.get_item_by_slot(ITEM_SLOT_EARS)
	if(ears_item)
		equipment["ears"] = ears_item.type

	var/obj/item/glasses_item = target.get_item_by_slot(ITEM_SLOT_EYES)
	if(glasses_item)
		equipment["glasses"] = glasses_item.type

	var/obj/item/belt_item = target.get_item_by_slot(ITEM_SLOT_BELT)
	if(belt_item)
		equipment["belt"] = belt_item.type

	var/obj/item/back_item = target.get_item_by_slot(ITEM_SLOT_BACK)
	if(back_item)
		equipment["back"] = back_item.type

	var/obj/item/card/id/id_item = target.get_item_by_slot(ITEM_SLOT_ID)
	if(id_item)
		equipment["id"] = id_item.type
		// Record ID card data
		body_data["id_registered_name"] = id_item.registered_name
		body_data["id_assignment"] = id_item.assignment
		body_data["id_access_txt"] = id_item.access_txt

	var/obj/item/lpocket_item = target.get_item_by_slot(ITEM_SLOT_LPOCKET)
	if(lpocket_item)
		equipment["l_pocket"] = lpocket_item.type

	var/obj/item/rpocket_item = target.get_item_by_slot(ITEM_SLOT_RPOCKET)
	if(rpocket_item)
		equipment["r_pocket"] = rpocket_item.type

	var/obj/item/suitstore_item = target.get_item_by_slot(ITEM_SLOT_SUITSTORE)
	if(suitstore_item)
		equipment["suit_store"] = suitstore_item.type

	// Record held items
	var/obj/item/left_hand_item = target.get_item_for_held_index(LEFT_HANDS)
	if(left_hand_item)
		equipment["l_hand"] = left_hand_item.type

	var/obj/item/right_hand_item = target.get_item_for_held_index(RIGHT_HANDS)
	if(right_hand_item)
		equipment["r_hand"] = right_hand_item.type

	body_data["equipment"] = equipment

	// Verify target still valid before recording actions
	if(QDELETED(target))
		return FALSE

	// Record actions (same limitations as body preservation unit)
	var/list/action_types = list()
	if(target.actions && islist(target.actions))
		for(var/datum/action/A in target.actions)
			// Skip item actions and spell actions
			if(istype(A, /datum/action/item_action))
				continue
			if(istype(A, /datum/action/spell_action))
				continue
			action_types += A.type
	body_data["action_types"] = action_types

	// Store the body data (this will overwrite any existing entry)
	recorded_bodies[target.real_name] = body_data

	// Build detailed feedback message (ensure all values are numeric)
	var/stats_text = "F:[body_data["fortitude"] || 0] P:[body_data["prudence"] || 0] T:[body_data["temperance"] || 0] J:[body_data["justice"] || 0]"
	var/role_text = body_data["assigned_role"] || "Unknown"

	if(updating)
		to_chat(src, span_boldnotice("Form UPDATED: [target.real_name]"))
		to_chat(src, span_notice("  Role: [role_text] | Stats: [stats_text]"))
		to_chat(src, span_notice("  Equipment: [length(equipment)] items"))
	else
		to_chat(src, span_boldnotice("Form RECORDED: [target.real_name]"))
		to_chat(src, span_notice("  Role: [role_text] | Stats: [stats_text]"))
		to_chat(src, span_notice("  Equipment: [length(equipment)] items"))

	// Debug logging
	log_game("[key_name(src)] [updating ? "updated" : "recorded"] form data for [target.real_name] ([role_text], [stats_text], [length(equipment)] items)")

	return TRUE

/// Creates a human body based on recorded data and transfers into it
/mob/living/simple_animal/hostile/distortion/envy_humanity/proc/AssumeForm(target_name)
	if(!recorded_bodies[target_name])
		to_chat(src, span_warning("No such form recorded."))
		return FALSE

	// Can't assume a form if already in one
	if(current_disguise && !QDELETED(current_disguise))
		to_chat(src, span_warning("You are already inhabiting a form!"))
		return FALSE

	// Can't assume human form while possessing a mob
	if(current_possessed_mob && !QDELETED(current_possessed_mob))
		to_chat(src, span_warning("You must abandon your current vessel first!"))
		return FALSE

	// Can't assume human form while possessing a carbon
	if(current_possessed_carbon && !QDELETED(current_possessed_carbon))
		to_chat(src, span_warning("You must abandon your current vessel first!"))
		return FALSE

	// Break stealth before transforming
	if(hidden_mode)
		BreakStealth()

	var/list/body_data = recorded_bodies[target_name]

	visible_message(span_danger("[src] begins to twist and reshape itself!"))
	playsound(src, 'sound/magic/demon_consume.ogg', 75, TRUE)

	// Brief transformation delay
	if(!do_after(src, 1.5 SECONDS, src))
		to_chat(src, span_warning("Transformation interrupted!"))
		return FALSE

	// Create the human body
	var/mob/living/carbon/human/new_body = new(get_turf(src))

	// Apply stored appearance
	new_body.real_name = body_data["real_name"]
	new_body.gender = body_data["gender"]

	// Apply DNA
	if(istype(body_data["dna"], /datum/dna))
		var/datum/dna/stored_dna = body_data["dna"]
		stored_dna.transfer_identity(new_body)

	// Set species
	var/species_type = body_data["species"]
	if(ispath(species_type, /datum/species))
		new_body.set_species(species_type)

	// Appearance details
	new_body.underwear = body_data["underwear"]
	new_body.underwear_color = body_data["underwear_color"]
	new_body.eye_color = body_data["eye_color"]
	new_body.facial_hairstyle = body_data["facial_hairstyle"]
	new_body.facial_hair_color = body_data["facial_hair_color"]
	new_body.hairstyle = body_data["hairstyle"]
	new_body.hair_color = body_data["hair_color"]
	new_body.gradient_style = body_data["gradient_style"]
	new_body.gradient_color = body_data["gradient_color"]

	new_body.updateappearance()

	// Apply recorded attributes to match the original target's stats
	if(body_data["fortitude"])
		var/target_fortitude = body_data["fortitude"]
		var/current_fortitude = get_attribute_level(new_body, FORTITUDE_ATTRIBUTE)
		new_body.adjust_attribute_level(FORTITUDE_ATTRIBUTE, target_fortitude - current_fortitude)

	if(body_data["prudence"])
		var/target_prudence = body_data["prudence"]
		var/current_prudence = get_attribute_level(new_body, PRUDENCE_ATTRIBUTE)
		new_body.adjust_attribute_level(PRUDENCE_ATTRIBUTE, target_prudence - current_prudence)

	if(body_data["temperance"])
		var/target_temperance = body_data["temperance"]
		var/current_temperance = get_attribute_level(new_body, TEMPERANCE_ATTRIBUTE)
		new_body.adjust_attribute_level(TEMPERANCE_ATTRIBUTE, target_temperance - current_temperance)

	if(body_data["justice"])
		var/target_justice = body_data["justice"]
		var/current_justice = get_attribute_level(new_body, JUSTICE_ATTRIBUTE)
		new_body.adjust_attribute_level(JUSTICE_ATTRIBUTE, target_justice - current_justice)

	// Add distortion traits to the body
	ADD_TRAIT(new_body, TRAIT_BRUTEPALE, MAGIC_TRAIT)
	ADD_TRAIT(new_body, TRAIT_BRUTESANITY, MAGIC_TRAIT)
	ADD_TRAIT(new_body, TRAIT_SANITYIMMUNE, MAGIC_TRAIT)
	ADD_TRAIT(new_body, TRAIT_GENELESS, MAGIC_TRAIT)
	ADD_TRAIT(new_body, TRAIT_COMBATFEAR_IMMUNE, MAGIC_TRAIT)

	// Clear the current disguise items list
	current_disguise_items = list()

	// Equip all recorded equipment
	var/list/equipment = body_data["equipment"]
	if(islist(equipment))
		// Equip items in proper order (uniform first for slots to work)

		// Uniform
		if(equipment["uniform"])
			var/uniform_type = equipment["uniform"]
			var/obj/item/clothing/under/U = new uniform_type()
			U.has_sensor = NO_SENSORS  // Disable sensors
			new_body.equip_to_slot_or_del(U, ITEM_SLOT_ICLOTHING, TRUE)
			current_disguise_items += U

		// Suit
		if(equipment["suit"])
			var/suit_type = equipment["suit"]
			var/obj/item/S = new suit_type()
			S.equip_delay_self = 0
			new_body.equip_to_slot_or_del(S, ITEM_SLOT_OCLOTHING, TRUE)
			current_disguise_items += S

		// Back
		if(equipment["back"])
			var/back_type = equipment["back"]
			var/obj/item/B = new back_type()
			new_body.equip_to_slot_or_del(B, ITEM_SLOT_BACK, TRUE)
			current_disguise_items += B

		// Belt
		if(equipment["belt"])
			var/belt_type = equipment["belt"]
			var/obj/item/BT = new belt_type()
			new_body.equip_to_slot_or_del(BT, ITEM_SLOT_BELT, TRUE)
			current_disguise_items += BT

		// Gloves
		if(equipment["gloves"])
			var/gloves_type = equipment["gloves"]
			var/obj/item/G = new gloves_type()
			new_body.equip_to_slot_or_del(G, ITEM_SLOT_GLOVES, TRUE)
			current_disguise_items += G

		// Shoes
		if(equipment["shoes"])
			var/shoes_type = equipment["shoes"]
			var/obj/item/SH = new shoes_type()
			new_body.equip_to_slot_or_del(SH, ITEM_SLOT_FEET, TRUE)
			current_disguise_items += SH

		// Head
		if(equipment["head"])
			var/head_type = equipment["head"]
			var/obj/item/H = new head_type()
			new_body.equip_to_slot_or_del(H, ITEM_SLOT_HEAD, TRUE)
			current_disguise_items += H

		// Mask
		if(equipment["mask"])
			var/mask_type = equipment["mask"]
			var/obj/item/M = new mask_type()
			new_body.equip_to_slot_or_del(M, ITEM_SLOT_MASK, TRUE)
			current_disguise_items += M

		// Neck
		if(equipment["neck"])
			var/neck_type = equipment["neck"]
			var/obj/item/N = new neck_type()
			new_body.equip_to_slot_or_del(N, ITEM_SLOT_NECK, TRUE)
			current_disguise_items += N

		// Ears
		if(equipment["ears"])
			var/ears_type = equipment["ears"]
			var/obj/item/E = new ears_type()
			new_body.equip_to_slot_or_del(E, ITEM_SLOT_EARS, TRUE)
			current_disguise_items += E

		// Glasses
		if(equipment["glasses"])
			var/glasses_type = equipment["glasses"]
			var/obj/item/GL = new glasses_type()
			new_body.equip_to_slot_or_del(GL, ITEM_SLOT_EYES, TRUE)
			current_disguise_items += GL

		// ID Card (with special data copying)
		if(equipment["id"])
			var/id_type = equipment["id"]
			var/obj/item/card/id/ID = new id_type()
			// Copy ID data
			if(body_data["id_registered_name"])
				ID.registered_name = body_data["id_registered_name"]
			if(body_data["id_assignment"])
				ID.assignment = body_data["id_assignment"]
			if(body_data["id_access_txt"])
				ID.access_txt = body_data["id_access_txt"]
				ID.access = ID.text2access(ID.access_txt)
			ID.update_label()
			new_body.equip_to_slot_or_del(ID, ITEM_SLOT_ID, TRUE)
			current_disguise_items += ID

		// Suit storage
		if(equipment["suit_store"])
			var/suitstore_type = equipment["suit_store"]
			var/obj/item/SS = new suitstore_type()
			new_body.equip_to_slot_or_del(SS, ITEM_SLOT_SUITSTORE, TRUE)
			current_disguise_items += SS

		// Pockets
		if(equipment["l_pocket"])
			var/lpocket_type = equipment["l_pocket"]
			var/obj/item/LP = new lpocket_type()
			new_body.equip_to_slot_or_del(LP, ITEM_SLOT_LPOCKET, TRUE)
			current_disguise_items += LP

		if(equipment["r_pocket"])
			var/rpocket_type = equipment["r_pocket"]
			var/obj/item/RP = new rpocket_type()
			new_body.equip_to_slot_or_del(RP, ITEM_SLOT_RPOCKET, TRUE)
			current_disguise_items += RP

		// Held items
		if(equipment["l_hand"])
			var/lhand_type = equipment["l_hand"]
			var/obj/item/LH = new lhand_type()
			new_body.put_in_l_hand(LH)
			current_disguise_items += LH

		if(equipment["r_hand"])
			var/rhand_type = equipment["r_hand"]
			var/obj/item/RH = new rhand_type()
			new_body.put_in_r_hand(RH)
			current_disguise_items += RH

	// Transfer mind to the new body
	if(mind)
		mind.transfer_to(new_body)

	// Move the distortion inside the human (hidden)
	forceMove(new_body)
	current_disguise = new_body

	// Grant recorded actions (same as body preservation unit)
	var/list/stored_action_types = body_data["action_types"]
	if(islist(stored_action_types))
		for(var/T in stored_action_types)
			var/datum/action/G = new T()
			G.Grant(new_body)

	// Grant the reversion action to the human body
	var/datum/action/innate/explosive_reversion/revert_action = new()
	revert_action.Grant(new_body)
	revert_action.source_distortion = src

	// Register death signal for the human body
	RegisterSignal(new_body, COMSIG_LIVING_DEATH, PROC_REF(OnDisguiseDeath))

	visible_message(span_danger("[new_body] stands where [src] once was!"))
	to_chat(new_body, span_userdanger("You now wear the flesh of [body_data["real_name"]]..."))

	return TRUE

/// Possesses a dead simple mob and reanimates it
/mob/living/simple_animal/hostile/distortion/envy_humanity/proc/PossessMob(mob/living/simple_animal/target)
	if(!target || !istype(target, /mob/living/simple_animal))
		return FALSE

	// Safety checks
	if(target.stat != DEAD)
		to_chat(src, span_warning("The target must be dead to possess!"))
		return FALSE

	if(target.mind)
		to_chat(src, span_warning("This vessel already has a soul!"))
		return FALSE

	if(current_disguise || current_possessed_mob || current_possessed_carbon)
		to_chat(src, span_warning("You are already inhabiting another form!"))
		return FALSE

	// Break stealth before possessing
	if(hidden_mode)
		BreakStealth()

	// Begin possession sequence
	visible_message(span_danger("[src] begins to seep into [target]'s corpse!"))
	to_chat(src, span_boldnotice("You begin entering [target]..."))
	playsound(src, 'sound/magic/demon_consume.ogg', 75, TRUE)

	// Create dark energy visual effect
	var/obj/effect/temp_visual/dir_setting/wraith/possession_effect = new(get_turf(target))
	possession_effect.color = "#000000"
	animate(possession_effect, alpha = 0, time = 3 SECONDS)

	// Possession delay (can be interrupted)
	if(!do_after(src, 3 SECONDS, target))
		to_chat(src, span_warning("The possession fails!"))
		visible_message(span_notice("[src] recoils from [target]!"))
		return FALSE

	// Success! Possess the mob
	visible_message(span_userdanger("[target] twitches violently and rises, eyes glowing unnaturally!"))
	playsound(target, 'sound/hallucinations/growl1.ogg', 50, TRUE)

	// Fully revive and heal the target
	target.revive(full_heal = TRUE, admin_revive = FALSE)
	target.fully_heal()

	// Transfer mind into the possessed mob
	if(mind)
		mind.transfer_to(target)

	// Move distortion inside the mob (hidden)
	forceMove(target)
	current_possessed_mob = target

	// Grant the abandon vessel action (check if they already have one)
	var/datum/action/innate/abandon_vessel/abandon = locate() in target.actions
	if(!abandon)
		abandon = new()
		abandon.Grant(target)
	abandon.source_distortion = src

	// Register death signal for the possessed mob
	RegisterSignal(target, COMSIG_LIVING_DEATH, PROC_REF(OnPossessedMobDeath))

	to_chat(target, span_userdanger("You now inhabit the body of [target]!"))
	to_chat(target, span_notice("Use the 'Abandon Vessel' action to leave this body."))

	return TRUE

/// Possesses a dead carbon mob and reanimates it
/mob/living/simple_animal/hostile/distortion/envy_humanity/proc/PossessCarbon(mob/living/carbon/target)
	if(!target || !istype(target, /mob/living/carbon))
		return FALSE

	// Safety checks
	if(target.stat != DEAD)
		to_chat(src, span_warning("The target must be dead to possess!"))
		return FALSE

	if(current_disguise || current_possessed_mob || current_possessed_carbon)
		to_chat(src, span_warning("You are already inhabiting another form!"))
		return FALSE

	// Clear any old recorded mind from previous possession
	recorded_carbon_mind = null

	// Record the target's mind if they have one
	if(target.mind)
		recorded_carbon_mind = target.mind
		to_chat(src, span_notice("You sense a lingering soul in this vessel..."))

	// Break stealth before possessing
	if(hidden_mode)
		BreakStealth()

	// Begin possession sequence
	visible_message(span_danger("[src] begins to seep into [target]'s corpse!"))
	to_chat(src, span_boldnotice("You begin entering [target]..."))
	playsound(src, 'sound/magic/demon_consume.ogg', 75, TRUE)

	// Create dark energy visual effect
	var/obj/effect/temp_visual/dir_setting/wraith/possession_effect = new(get_turf(target))
	possession_effect.color = "#000000"
	animate(possession_effect, alpha = 0, time = 3 SECONDS)

	// Possession delay (can be interrupted)
	if(!do_after(src, 3 SECONDS, target))
		to_chat(src, span_warning("The possession fails!"))
		visible_message(span_notice("[src] recoils from [target]!"))
		return FALSE

	// Success! Possess the mob
	visible_message(span_userdanger("[target] twitches violently and rises, eyes glowing unnaturally!"))
	playsound(target, 'sound/hallucinations/growl1.ogg', 50, TRUE)

	// Fully revive and heal the target
	target.revive(full_heal = TRUE, admin_revive = FALSE)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		H.fully_heal(TRUE)
	else
		target.setMaxHealth(target.maxHealth)
		target.health = target.maxHealth

	// Transfer mind into the possessed mob
	if(mind)
		mind.transfer_to(target)

	// Move distortion inside the mob (hidden)
	forceMove(target)
	current_possessed_carbon = target

	// Grant the abandon vessel action (check if they already have one)
	var/datum/action/innate/abandon_vessel/abandon = locate() in target.actions
	if(!abandon)
		abandon = new()
		abandon.Grant(target)
	abandon.source_distortion = src

	// Register death signal for the possessed carbon
	RegisterSignal(target, COMSIG_LIVING_DEATH, PROC_REF(OnPossessedCarbonDeath))

	to_chat(target, span_userdanger("You now inhabit the body of [target]!"))
	to_chat(target, span_notice("Use the 'Abandon Vessel' action to leave this body."))

	return TRUE

/// Cleanup all items created for the disguise
/mob/living/simple_animal/hostile/distortion/envy_humanity/proc/CleanupDisguiseItems()
	if(!length(current_disguise_items))
		return

	for(var/obj/item/I in current_disguise_items)
		if(!QDELETED(I))
			qdel(I)

	current_disguise_items = list()

/// Called when the human disguise dies
/mob/living/simple_animal/hostile/distortion/envy_humanity/proc/OnDisguiseDeath(mob/living/carbon/human/H, gibbed)
	SIGNAL_HANDLER

	if(QDELETED(src) || stat == DEAD)
		return

	// Unregister the signal
	UnregisterSignal(H, COMSIG_LIVING_DEATH)

	// Force reversion
	visible_message(span_userdanger("The disguise fails as the body dies!"))
	RevertForm()

	// Take damage for losing the disguise violently
	adjustBruteLoss(200)

/// Called when the possessed mob dies
/mob/living/simple_animal/hostile/distortion/envy_humanity/proc/OnPossessedMobDeath(mob/living/simple_animal/M, gibbed)
	SIGNAL_HANDLER

	if(QDELETED(src) || stat == DEAD)
		return

	// Unregister the signal
	UnregisterSignal(M, COMSIG_LIVING_DEATH)

	// Force ejection
	visible_message(span_userdanger("The vessel fails as [M] dies!"))
	AbandonVessel()

	// Take damage for losing the vessel violently
	adjustBruteLoss(150)

/// Called when the possessed carbon dies
/mob/living/simple_animal/hostile/distortion/envy_humanity/proc/OnPossessedCarbonDeath(mob/living/carbon/C, gibbed)
	SIGNAL_HANDLER

	if(QDELETED(src) || stat == DEAD)
		return

	// Unregister the signal
	UnregisterSignal(C, COMSIG_LIVING_DEATH)

	// Force ejection
	visible_message(span_userdanger("The vessel fails as [C] dies!"))
	AbandonCarbonVessel()

	// Take damage for losing the vessel violently
	adjustBruteLoss(150)

/// Leaves the possessed mob's body
/mob/living/simple_animal/hostile/distortion/envy_humanity/proc/AbandonVessel()
	if(!current_possessed_mob || QDELETED(current_possessed_mob))
		return FALSE

	var/turf/exit_turf = get_turf(current_possessed_mob)

	// Unregister death signal
	UnregisterSignal(current_possessed_mob, COMSIG_LIVING_DEATH)

	// Transfer mind back to distortion
	if(current_possessed_mob.mind)
		current_possessed_mob.mind.transfer_to(src)

	// Move distortion back to the world
	forceMove(exit_turf)

	// Visual and audio effects
	visible_message(span_userdanger("[current_possessed_mob] convulses violently as something tears free!"))
	playsound(exit_turf, 'sound/magic/demon_consume.ogg', 75, TRUE)

	// Kill the possessed mob
	current_possessed_mob.gib()

	// Blood splatter effect
	new /obj/effect/temp_visual/dir_setting/wraith(exit_turf)

	// Clear reference
	current_possessed_mob = null

	visible_message(span_danger("[src] tears free from the dying vessel!"))
	return TRUE

/// Leaves the possessed carbon body
/mob/living/simple_animal/hostile/distortion/envy_humanity/proc/AbandonCarbonVessel()
	if(!current_possessed_carbon || QDELETED(current_possessed_carbon))
		return FALSE

	var/turf/exit_turf = get_turf(current_possessed_carbon)

	// Unregister death signal
	UnregisterSignal(current_possessed_carbon, COMSIG_LIVING_DEATH)

	// Transfer mind back to distortion
	if(current_possessed_carbon.mind)
		current_possessed_carbon.mind.transfer_to(src)

	// Move distortion back to the world
	forceMove(exit_turf)

	// Visual and audio effects
	visible_message(span_userdanger("[current_possessed_carbon] convulses violently as something tears free!"))
	playsound(exit_turf, 'sound/magic/demon_consume.ogg', 75, TRUE)

	// Restore the recorded mind if we have one
	if(recorded_carbon_mind && !QDELETED(recorded_carbon_mind))
		recorded_carbon_mind.transfer_to(current_possessed_carbon)
		to_chat(current_possessed_carbon, span_notice("You feel your consciousness returning to your body..."))
		recorded_carbon_mind = null

	// Kill the possessed carbon (without gibbing)
	current_possessed_carbon.death()

	// Blood splatter effect
	new /obj/effect/temp_visual/dir_setting/wraith(exit_turf)

	// Clear reference
	current_possessed_carbon = null

	visible_message(span_danger("[src] tears free from the dying vessel!"))
	return TRUE

/// Called when the human body is gibbed/reverted
/mob/living/simple_animal/hostile/distortion/envy_humanity/proc/RevertForm()
	if(!current_disguise || QDELETED(current_disguise))
		return

	var/turf/exit_turf = get_turf(current_disguise)

	// Unregister death signal
	UnregisterSignal(current_disguise, COMSIG_LIVING_DEATH)

	// Cleanup all created items BEFORE gibbing
	CleanupDisguiseItems()

	// Transfer mind back
	if(current_disguise.mind)
		current_disguise.mind.transfer_to(src)

	// Move back to the world
	forceMove(exit_turf)

	// Visual effects
	visible_message(span_userdanger("[current_disguise] violently convulses and explodes!"))
	playsound(exit_turf, 'sound/effects/splat.ogg', 100, TRUE)

	// Create blood effects
	for(var/turf/TF in orange(1, exit_turf))
		if(TF.density)
			continue
		var/obj/effect/decal/cleanable/blood/B = new(TF)
		B.bloodiness = 100

	// Gib the human body
	for(var/obj/item/W in current_disguise.contents)
		if(!current_disguise.dropItemToGround(W))
			qdel(W)
	new /obj/effect/gibspawner/human/bodypartless(get_turf(current_disguise))
	qdel(current_disguise)
	current_disguise = null

	// Dramatic entrance
	new /obj/effect/temp_visual/dir_setting/wraith(exit_turf)
	visible_message(span_danger("[src] emerges from the remains!"))

/// Death handling - if we die while in a body, both die
/mob/living/simple_animal/hostile/distortion/envy_humanity/death(gibbed)
	// Cleanup items first
	CleanupDisguiseItems()

	// Kill human disguise if present
	if(current_disguise && !QDELETED(current_disguise))
		current_disguise.gib()
		current_disguise = null

	// Kill possessed mob if present
	if(current_possessed_mob && !QDELETED(current_possessed_mob))
		current_possessed_mob.death()
		current_possessed_mob = null

	// Kill possessed carbon if present
	if(current_possessed_carbon && !QDELETED(current_possessed_carbon))
		// Restore mind before death if we recorded one
		if(recorded_carbon_mind && !QDELETED(recorded_carbon_mind))
			recorded_carbon_mind.transfer_to(current_possessed_carbon)
			recorded_carbon_mind = null
		current_possessed_carbon.death()
		current_possessed_carbon = null

	// Clear any leftover recorded mind
	recorded_carbon_mind = null

	return ..()

/// Life proc for ambient hidden messages
/mob/living/simple_animal/hostile/distortion/envy_humanity/Life()
	. = ..()
	if(!.)
		return

	// Send ambient messages while hidden
	if(hidden_mode && world.time > next_hidden_message)
		SendHiddenMessage()
		next_hidden_message = world.time + 1 MINUTES

/// Pained Screech - AoE attack that deals WHITE damage and inflicts Horror
/mob/living/simple_animal/hostile/distortion/envy_humanity/proc/PainedScreech()
	if(stat == DEAD)
		return

	// Visual and audio effects
	visible_message(span_userdanger("[src] releases a horrifying screech!"))
	playsound(src, 'sound/distortions/envy_scream.ogg', 75, TRUE)

	// Create visual effect
	new /obj/effect/temp_visual/fragment_song(get_turf(src))

	// Get all turfs in range (similar to Big Wolf's Howl - 20 tile range)
	var/list/turfs_to_check = orange(20, src)

	// Deal damage and apply Horror to all living mobs in range
	for(var/mob/living/L in turfs_to_check)
		// Skip if same faction
		if(faction_check_mob(L, FALSE))
			continue

		// Skip if dead
		if(L.stat == DEAD)
			continue

		// Deal WHITE damage (50, similar to Big Wolf)
		L.deal_damage(50, WHITE_DAMAGE)

		// Apply Horror status effect
		L.apply_status_effect(/datum/status_effect/horror, src)

	to_chat(src, span_boldnotice("You unleash your anguish upon all nearby!"))

/// Enters stealth mode
/mob/living/simple_animal/hostile/distortion/envy_humanity/proc/EnterStealth()
	if(hidden_mode)
		return

	hidden_mode = TRUE
	visible_message(span_warning("[src] begins to fade from view..."))

	// Animate alpha dropping over 3 seconds
	animate(src, alpha = 5, time = 3 SECONDS)

	// After animation completes, set invisibility and mouse opacity
	addtimer(CALLBACK(src, PROC_REF(CompleteStealth)), 3 SECONDS)

	next_hidden_message = world.time + 1 MINUTES

/// Completes the stealth transition
/mob/living/simple_animal/hostile/distortion/envy_humanity/proc/CompleteStealth()
	if(!hidden_mode)
		return

	invisibility = INVISIBILITY_OBSERVER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	density = FALSE
	fear_level = 0
	to_chat(src, span_notice("You fade into the shadows..."))

/// Breaks stealth mode
/mob/living/simple_animal/hostile/distortion/envy_humanity/proc/BreakStealth()
	if(!hidden_mode)
		return

	hidden_mode = FALSE
	invisibility = initial(invisibility)
	mouse_opacity = initial(mouse_opacity)
	density = initial(density)
	fear_level = WAW_LEVEL

	// Quickly restore alpha
	animate(src, alpha = 255, time = 0.5 SECONDS)

	visible_message(span_danger("[src] suddenly materializes!"))
	to_chat(src, span_warning("Your presence is revealed!"))

/// Sends ambient hidden message to nearby mobs
/mob/living/simple_animal/hostile/distortion/envy_humanity/proc/SendHiddenMessage()
	var/list/hidden_messages = list(
		"A hushed melody sinks past you...",
		"You hear a faint, eerie lullaby in the distance...",
		"An unsettling tune drifts through the air...",
		"A haunting melody whispers at the edge of your hearing...",
		"You feel a chill as an otherworldly song passes by...",
		"The air seems to hum with an unnatural lullaby..."
	)

	var/message = pick(hidden_messages)

	// Send message to nearby humans
	for(var/mob/living/carbon/human/H in view(7, src))
		to_chat(H, span_notice(message))

// Action datums

/// Action to choose and assume a recorded form
/datum/action/cooldown/assume_form
	name = "Assume Form"
	desc = "Transform into one of your recorded human forms."
	icon_icon = 'icons/mob/actions/actions_changeling.dmi'
	button_icon_state = "transform"
	transparent_when_unavailable = TRUE
	cooldown_time = 10 SECONDS
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/cooldown/assume_form/Trigger()
	. = ..()
	if(!.)
		return FALSE

	var/mob/living/simple_animal/hostile/distortion/envy_humanity/envy = owner
	if(!istype(envy))
		return FALSE

	// Check if already in a form
	if(envy.current_disguise && !QDELETED(envy.current_disguise))
		to_chat(owner, span_warning("You are already inhabiting a form!"))
		return FALSE

	// Check if we have any recorded forms
	if(!length(envy.recorded_bodies))
		to_chat(owner, span_warning("You have not recorded any forms yet!"))
		return FALSE

	// Let the player choose which form to assume
	var/list/form_choices = list()
	for(var/name in envy.recorded_bodies)
		form_choices[name] = envy.recorded_bodies[name]

	var/chosen_form = input(owner, "Choose a form to assume:", "Assume Form") as null|anything in form_choices
	if(!chosen_form)
		return FALSE

	// Assume the chosen form
	if(envy.AssumeForm(chosen_form))
		StartCooldown()
		return TRUE

	return FALSE

/// Action granted to human bodies to revert explosively
/datum/action/innate/explosive_reversion
	name = "Explosive Reversion"
	desc = "Violently shed this flesh and return to your true form."
	icon_icon = 'icons/mob/actions/actions_changeling.dmi'
	button_icon_state = "sting_transform"
	var/mob/living/simple_animal/hostile/distortion/envy_humanity/source_distortion

/datum/action/innate/explosive_reversion/Activate()
	if(!source_distortion || QDELETED(source_distortion))
		to_chat(owner, span_warning("Connection to true form lost!"))
		return

	// Warning phase
	to_chat(owner, span_userdanger("You begin to vibrate violently!"))
	owner.visible_message(span_danger("[owner] begins shaking violently!"))
	owner.Jitter(100)
	playsound(owner, 'sound/abnormalities/nothingthere/disguise.ogg', 75, TRUE)

	// Add vibration overlay
	var/mutable_appearance/vibrate_overlay = mutable_appearance('icons/effects/effects.dmi', "electricity2")
	vibrate_overlay.color = "#000000"
	owner.add_overlay(vibrate_overlay)

	// 2 second delay
	if(!do_after(owner, 2 SECONDS, owner))
		owner.cut_overlay(vibrate_overlay)
		to_chat(owner, span_notice("You stabilize the form..."))
		return

	// Revert!
	owner.cut_overlay(vibrate_overlay)
	source_distortion.RevertForm()

/// Action granted to possessed mobs to abandon the vessel
/datum/action/innate/abandon_vessel
	name = "Abandon Vessel"
	desc = "Tear yourself free from this body, killing it in the process."
	icon_icon = 'icons/mob/actions/actions_changeling.dmi'
	button_icon_state = "sting_lsd"
	var/mob/living/simple_animal/hostile/distortion/envy_humanity/source_distortion

/datum/action/innate/abandon_vessel/Activate()
	if(!source_distortion || QDELETED(source_distortion))
		to_chat(owner, span_warning("Connection to true form lost!"))
		return

	// Warning phase
	to_chat(owner, span_userdanger("You begin tearing at the vessel from within!"))
	owner.visible_message(span_danger("[owner] convulses violently!"))
	owner.Jitter(100)
	playsound(owner, 'sound/magic/demon_consume.ogg', 50, TRUE)

	// Add dark energy overlay
	var/mutable_appearance/dark_overlay = mutable_appearance('icons/effects/effects.dmi', "electricity2")
	dark_overlay.color = "#000000"
	owner.add_overlay(dark_overlay)

	// 1.5 second delay
	if(!do_after(owner, 1.5 SECONDS, owner))
		owner.cut_overlay(dark_overlay)
		to_chat(owner, span_notice("You settle back into the vessel..."))
		return

	// Abandon!
	owner.cut_overlay(dark_overlay)

	// Check which type of vessel we're in and abandon accordingly
	if(source_distortion.current_possessed_carbon && owner == source_distortion.current_possessed_carbon)
		source_distortion.AbandonCarbonVessel()
	else if(source_distortion.current_possessed_mob && owner == source_distortion.current_possessed_mob)
		source_distortion.AbandonVessel()
	else
		to_chat(owner, span_warning("Error: Unable to determine vessel type!"))

/// Pained Screech - Horror-inducing AoE attack
/datum/action/cooldown/pained_screech
	name = "Pained Screech"
	desc = "Release a horrifying screech that damages nearby enemies and inflicts them with Horror."
	icon_icon = 'icons/mob/actions/actions_changeling.dmi'
	button_icon_state = "resonant_shriek"
	cooldown_time = 30 SECONDS
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/cooldown/pained_screech/Trigger()
	. = ..()
	if(!.)
		return FALSE

	var/mob/living/simple_animal/hostile/distortion/envy_humanity/envy = owner
	if(!istype(envy))
		return FALSE

	// Cannot use while in another form
	if(envy.current_disguise || envy.current_possessed_mob || envy.current_possessed_carbon)
		to_chat(owner, span_warning("You cannot use this ability while inhabiting another form!"))
		return FALSE

	// Perform the screech
	envy.PainedScreech()
	StartCooldown()
	return TRUE

/// Lullaby of the Hidden - stealth ability
/datum/action/cooldown/lullaby_hidden
	name = "Lullaby of the Hidden"
	desc = "Fade into shadows, becoming nearly invisible. Attacking or toggling this ability will break your stealth."
	icon_icon = 'icons/mob/actions/actions_changeling.dmi'
	button_icon_state = "dissonant_shriek"
	cooldown_time = 5 SECONDS
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/cooldown/lullaby_hidden/Trigger()
	. = ..()
	if(!.)
		return FALSE

	var/mob/living/simple_animal/hostile/distortion/envy_humanity/envy = owner
	if(!istype(envy))
		return FALSE

	// Cannot use while in another form
	if(envy.current_disguise || envy.current_possessed_mob || envy.current_possessed_carbon)
		to_chat(owner, span_warning("You cannot use this ability while inhabiting another form!"))
		return FALSE

	// Toggle stealth
	if(envy.hidden_mode)
		envy.BreakStealth()
	else
		envy.EnterStealth()

	StartCooldown()
	return TRUE

/// Toggle between scanning mode and normal mode
/datum/action/innate/toggle_scanning
	name = "Toggle Scanning Mode"
	desc = "Toggle between scanning humans and normal behavior."
	button_icon = 'icons/mob/actions/actions_ecult.dmi'
	button_icon_state = "blind"
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE
	var/enabled = TRUE

/datum/action/innate/toggle_scanning/Activate()
	var/mob/living/simple_animal/hostile/distortion/envy_humanity/envy = owner
	if(!istype(envy))
		return

	envy.scanning_mode = !envy.scanning_mode
	enabled = envy.scanning_mode

	if(envy.scanning_mode)
		to_chat(owner, span_notice("Scanning mode ENABLED. You will scan humans when targeting them."))
		button_icon_state = "blind"
	else
		to_chat(owner, span_warning("Scanning mode DISABLED. You will attack normally."))
		button_icon_state = "soulshackle"

	UpdateButtonIcon()

// Horror status effect - applied by Pained Screech
/datum/status_effect/horror
	id = "horror"
	duration = 10 SECONDS // 10 seconds total duration
	tick_interval = 1 SECONDS // Tick every 1 second
	alert_type = /atom/movable/screen/alert/status_effect/horror
	var/mob/living/simple_animal/hostile/distortion/envy_humanity/source_envy // The Envy that caused this

/datum/status_effect/horror/on_creation(mob/living/new_owner, envy_source)
	source_envy = envy_source
	return ..()

/datum/status_effect/horror/on_apply()
	if(!owner || !source_envy)
		return FALSE
	to_chat(owner, span_userdanger("You are gripped by an overwhelming sense of HORROR!"))
	return TRUE

/datum/status_effect/horror/tick()
	if(!owner || !source_envy || QDELETED(source_envy))
		qdel(src)
		return

	// Check if source is dead
	if(source_envy.stat == DEAD)
		to_chat(owner, span_notice("The horror fades as your tormentor falls..."))
		qdel(src)
		return

	// Check if we have line of sight to the Envy
	if(!can_see(owner, source_envy, 7))
		to_chat(owner, span_notice("Breaking line of sight weakens the horror..."))
		qdel(src)
		return

	// Check if we are facing the Envy
	if(!is_A_facing_B(owner, source_envy))
		return // Don't take damage if not facing, but don't remove effect

	// Deal WHITE damage equal to 10% of max SP
	var/damage_to_deal = 0
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		damage_to_deal = H.maxSanity * 0.1
	else
		// For non-humans, use a default calculation based on health
		damage_to_deal = owner.maxHealth * 0.05 // 5% of max health as fallback

	if(damage_to_deal > 0)
		owner.deal_damage(damage_to_deal, WHITE_DAMAGE)
		to_chat(owner, span_warning("The horrifying visage tears at your mind!"))

/datum/status_effect/horror/on_remove()
	if(owner)
		to_chat(owner, span_notice("The horror gradually fades from your mind..."))

// Alert for Horror status effect
/atom/movable/screen/alert/status_effect/horror
	name = "Horror"
	desc = "You are gripped by overwhelming horror! Looking at the source will damage your sanity!"
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "allure"
