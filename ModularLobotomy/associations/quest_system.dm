// Base quest datum
/datum/city_quest
	var/name = "Unnamed Quest"
	var/desc = "Quest description"
	var/reward_ahn = 500
	var/quest_type = "generic"
	var/datum/mind/quest_mind // Mind that accepted this quest
	var/completed = FALSE
	var/turned_in = FALSE
	var/obj/item/quest_contract/contract_item // Physical contract item
	// Lock variables
	var/time_lock = 0          // World time in ticks when quest can appear (0 = no lock)
	var/grade_lock = 0         // Minimum grade required (0 = no lock, 1-9 valid grades, lower = better)
	var/office_lock = FALSE    // Requires being in an office to accept
	// Expiration tracking for board cleanup
	var/refresh_count = 0      // How many board refreshes this quest has survived
	var/max_refreshes = 3      // Remove from board after this many refreshes without being accepted

/datum/city_quest/proc/on_accept(datum/mind/M)
	quest_mind = M
	create_contract()
	return TRUE

/datum/city_quest/proc/create_contract()
	if(!quest_mind?.current)
		return
	var/mob/living/carbon/human/H = quest_mind.current
	if(!ishuman(H))
		return

	// Create and give contract item
	contract_item = new /obj/item/quest_contract(get_turf(H), src)
	H.put_in_hands(contract_item)
	to_chat(H, span_notice("You receive a physical contract for '[name]'."))

/datum/city_quest/proc/update_contract()
	if(contract_item)
		contract_item.update_contract_info()

/datum/city_quest/Destroy()
	if(contract_item)
		qdel(contract_item)
		contract_item = null
	return ..()

/datum/city_quest/proc/check_completion()
	return FALSE

/datum/city_quest/proc/on_complete()
	completed = TRUE
	if(quest_mind?.current)
		to_chat(quest_mind.current, span_nicegreen("Contract '[name]' completed!"))
	update_contract()

/datum/city_quest/proc/grant_reward()
	if(!quest_mind?.current || !turned_in)
		return
	var/mob/living/carbon/human/H = quest_mind.current
	if(!ishuman(H))
		return

	// Give the Ahn reward
	H.put_in_hands(new /obj/item/holochip(get_turf(H), reward_ahn))

	// Track quest completion
	if(quest_mind.quest_tracker)
		quest_mind.quest_tracker.total_quests_completed++
		quest_mind.quest_tracker.ahn_earned += reward_ahn

/datum/city_quest/proc/get_progress_text()
	return "In Progress"

/// Check if this quest can be generated (enough targets exist on the map)
/datum/city_quest/proc/can_generate()
	return TRUE

/// Calculate player's grade based on their stats (same formula as /obj/structure/potential)
/datum/city_quest/proc/get_player_grade(mob/living/carbon/human/H)
	if(!ishuman(H))
		return 10 // Worst grade for non-humans
	var/stattotal = 0
	var/list/stats = list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE, TEMPERANCE_ATTRIBUTE, JUSTICE_ATTRIBUTE)
	for(var/attribute in stats)
		stattotal += get_attribute_level(H, attribute)
	stattotal /= 4 // Average of stats
	var/grade = round(stattotal / 20)
	// Return grade 1-10 (lower = better, 10 = no grade)
	return clamp(10 - grade, 1, 10)

/// Check if a player can accept this quest based on grade and office locks
/datum/city_quest/proc/can_accept(mob/living/carbon/human/H)
	if(!ishuman(H))
		return FALSE

	// Check grade lock
	if(grade_lock > 0)
		var/player_grade = get_player_grade(H)
		if(player_grade > grade_lock) // Higher number = worse grade
			return FALSE

	// Check office lock
	if(office_lock)
		var/in_office = FALSE
		for(var/datum/fixer_office/F in GLOB.all_fixer_offices)
			if(H in F.members)
				in_office = TRUE
				break
		if(!in_office)
			return FALSE

	return TRUE

// HUNT QUESTS
/datum/city_quest/hunt
	quest_type = "hunt"
	var/mob_type_to_kill = /mob/living/simple_animal/hostile
	var/kill_count_required = 5
	var/kills_completed = 0
	var/list/valid_targets = list() // Specific mob types that count
	var/list/registered_attackers = list() // Mobs with registered attack signals (for office mate sharing)
	var/list/registered_death_targets = list() // Mobs with registered death signals

/datum/city_quest/hunt/on_accept(datum/mind/M)
	. = ..()
	// Register attack signal for quest holder
	RegisterSignal(M.current, COMSIG_MOB_ITEM_AFTERATTACK, PROC_REF(on_attack))
	registered_attackers += M.current

	// Register attack signals for office mates (office sharing)
	var/datum/fixer_office/holder_office = get_holder_office()
	if(holder_office)
		for(var/mob/living/carbon/human/office_mate in holder_office.members)
			if(office_mate == M.current) // Skip quest holder, already registered
				continue
			if(!(office_mate in registered_attackers))
				RegisterSignal(office_mate, COMSIG_MOB_ITEM_AFTERATTACK, PROC_REF(on_attack))
				registered_attackers += office_mate

/datum/city_quest/hunt/Destroy()
	// Unregister all attack signals
	for(var/mob/M in registered_attackers)
		UnregisterSignal(M, COMSIG_MOB_ITEM_AFTERATTACK)
	registered_attackers.Cut()
	// Unregister all death signals
	for(var/mob/living/L in registered_death_targets)
		UnregisterSignal(L, COMSIG_LIVING_DEATH)
	registered_death_targets.Cut()
	return ..()

/// Get the fixer office the quest holder belongs to
/datum/city_quest/hunt/proc/get_holder_office()
	if(!quest_mind?.current)
		return null
	var/mob/living/carbon/human/H = quest_mind.current
	if(!ishuman(H))
		return null
	for(var/datum/fixer_office/F in GLOB.all_fixer_offices)
		if(H in F.members)
			return F
	return null

/datum/city_quest/hunt/proc/on_attack(datum/source, atom/target, mob/user)
	if(!isliving(target))
		return
	var/mob/living/L = target
	// Only register death signal if not already registered
	if(!(L in registered_death_targets))
		RegisterSignal(L, COMSIG_LIVING_DEATH, PROC_REF(on_target_death))
		registered_death_targets += L

/datum/city_quest/hunt/proc/on_target_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	// Clean up signal registration
	UnregisterSignal(source, COMSIG_LIVING_DEATH)
	registered_death_targets -= source
	// Don't process if quest is already completed or turned in
	if(completed || turned_in)
		return
	if(is_valid_target(source))
		kills_completed++
		check_completion()
		if(quest_mind?.current)
			to_chat(quest_mind.current, span_notice("Contract progress: [kills_completed]/[kill_count_required] [source] killed."))
		update_contract()

/datum/city_quest/hunt/proc/is_valid_target(mob/living/L)
	if(!valid_targets.len) // Accept any hostile
		return istype(L, mob_type_to_kill)
	return (L.type in valid_targets)

/datum/city_quest/hunt/check_completion()
	if(kills_completed >= kill_count_required)
		on_complete()
		return TRUE
	return FALSE

/datum/city_quest/hunt/get_progress_text()
	return "[kills_completed]/[kill_count_required] killed"

/datum/city_quest/hunt/can_generate()
	// Count how many valid targets exist on the map
	var/target_count = 0
	for(var/mob/living/L in GLOB.mob_living_list)
		if(!L.z) // Skip mobs not on a z-level
			continue
		if(is_valid_target(L))
			target_count++
			if(target_count >= kill_count_required)
				return TRUE
	return FALSE

// Hunt quest examples
/datum/city_quest/hunt/worms
	name = "Exterminate Amber Bugs"
	desc = "Hunt and kill 10 Amber Bugs (the worm-like creatures) in the backstreets."
	kill_count_required = 10
	reward_ahn = 1000
	valid_targets = list(/mob/living/simple_animal/hostile/ordeal/amber_bug)

/datum/city_quest/hunt/worm_boss
	name = "Amber Worm Elimination"
	desc = "Take down 2 Amber Worm creatures - the larger worm variants."
	kill_count_required = 2
	reward_ahn = 2000
	valid_targets = list(/mob/living/simple_animal/hostile/ordeal/amber_dusk)
	grade_lock = 6

/datum/city_quest/hunt/sweepers
	name = "Sweeper Cleanup"
	desc = "Eliminate 6 Sweepers of any type polluting the backstreets."
	kill_count_required = 6
	reward_ahn = 1200
	valid_targets = list(/mob/living/simple_animal/hostile/ordeal/indigo_dawn,
						/mob/living/simple_animal/hostile/ordeal/indigo_noon,
						/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky,
						/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky)

/datum/city_quest/hunt/sweeper_variants
	name = "Mutant Sweeper Research"
	desc = "Hunt 1 Chunky Sweeper and 1 Lanky Sweeper for research purposes."
	kill_count_required = 2
	reward_ahn = 1600
	valid_targets = list(/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky,
						/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky)
	grade_lock = 7

/datum/city_quest/hunt/gcorp_patrol
	name = "G-Corp Patrol Elimination"
	desc = "Take out 5 G-Corp remnants."
	kill_count_required = 5
	reward_ahn = 1400
	valid_targets = list(/mob/living/simple_animal/hostile/ordeal/steel_dawn,
						/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon)

/datum/city_quest/hunt/gcorp_elite
	name = "G-Corp Elite Bounty"
	desc = "Eliminate 1 G-Corp corporal."
	kill_count_required = 1
	reward_ahn = 1200
	valid_targets = list(/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon)
	grade_lock = 7

/datum/city_quest/hunt/bots_small
	name = "Bot Scrap Collection"
	desc = "Destroy 4 small Green Bots for their parts."
	kill_count_required = 4
	reward_ahn = 800
	valid_targets = list(/mob/living/simple_animal/hostile/ordeal/green_bot)

/datum/city_quest/hunt/bots_big
	name = "Big Bot Bounty"
	desc = "Destroy 2 Big Green Bots threatening the area."
	kill_count_required = 2
	reward_ahn = 1400
	valid_targets = list(/mob/living/simple_animal/hostile/ordeal/green_bot_big)
	office_lock = TRUE

/datum/city_quest/hunt/mixed_threats
	name = "Backstreet Cleanup"
	desc = "Clear out 15 hostiles of Sweeper, Amber, G-Corp or Bot types from the backstreets."
	kill_count_required = 15
	reward_ahn = 1200
	valid_targets = list(/mob/living/simple_animal/hostile/ordeal/amber_bug,
						/mob/living/simple_animal/hostile/ordeal/amber_dusk,
						/mob/living/simple_animal/hostile/ordeal/indigo_dawn,
						/mob/living/simple_animal/hostile/ordeal/indigo_noon,
						/mob/living/simple_animal/hostile/ordeal/steel_dawn,
						/mob/living/simple_animal/hostile/ordeal/green_bot,
						/mob/living/simple_animal/hostile/ordeal/green_bot_big,
						/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon)

/datum/city_quest/hunt/rats
	name = "Rat Extermination"
	desc = "Eliminate 4 Rats roaming the backstreets."
	kill_count_required = 4
	reward_ahn = 800
	valid_targets = list(/mob/living/simple_animal/hostile/humanoid/rat)

// Special mob hunt quests - only appear if mobs exist
/datum/city_quest/hunt/clown_menace
	name = "Clown Threat Elimination"
	desc = "A dangerous clown has been spotted. Eliminate this threat to public safety."
	kill_count_required = 1
	reward_ahn = 2400
	valid_targets = list(/mob/living/simple_animal/hostile/retaliate/clown)
	time_lock = 20 MINUTES
	grade_lock = 6

/datum/city_quest/hunt/jungle_mooks
	name = "Jungle Mook Infestation"
	desc = "Strange jungle creatures have appeared within the backstreets. Clear out 2 of these mooks."
	kill_count_required = 2
	reward_ahn = 2000
	valid_targets = list(/mob/living/simple_animal/hostile/jungle/mook)
	time_lock = 25 MINUTES
	grade_lock = 6
	office_lock = TRUE

/datum/city_quest/hunt/faithless_purge
	name = "Faithless Extermination"
	desc = "The Faithless must be destroyed. Hunt down 2 of these abominations."
	kill_count_required = 2
	reward_ahn = 2500
	valid_targets = list(/mob/living/simple_animal/hostile/faithless)
	time_lock = 30 MINUTES
	grade_lock = 5
	office_lock = TRUE

/datum/city_quest/hunt/blood_fiend_boss
	name = "Blood Fiend Boss Bounty"
	desc = "EXTREME DANGER: A Blood Fiend Boss has been located. Eliminate it for a massive reward."
	kill_count_required = 1
	reward_ahn = 5000
	valid_targets = list(/mob/living/simple_animal/hostile/humanoid/blood/fiend/boss)
	time_lock = 45 MINUTES
	grade_lock = 4
	office_lock = TRUE

/datum/city_quest/hunt/blood_fiends
	name = "Blood Fiend Hunting"
	desc = "Hunt down 4 Blood Fiends terrorizing the district."
	kill_count_required = 4
	reward_ahn = 3200
	valid_targets = list(/mob/living/simple_animal/hostile/humanoid/blood/fiend)
	time_lock = 35 MINUTES
	grade_lock = 5

/datum/city_quest/hunt/blood_bags
	name = "Blood Bag Cleanup"
	desc = "Eliminate 8 Blood Bags to prevent further contamination."
	kill_count_required = 8
	reward_ahn = 2400
	valid_targets = list(/mob/living/simple_animal/hostile/humanoid/blood/bag)
	time_lock = 30 MINUTES
	grade_lock = 6

/datum/city_quest/hunt/ghost_busting
	name = "Paranormal Elimination"
	desc = "Vengeful spirits have been reported. Destroy 3 hostile ghosts."
	kill_count_required = 3
	reward_ahn = 3600
	valid_targets = list(/mob/living/simple_animal/hostile/retaliate/ghost)
	time_lock = 25 MINUTES
	grade_lock = 4
	office_lock = TRUE

// COLLECT QUESTS
/datum/city_quest/collect
	quest_type = "collect"
	var/items_required = 10
	var/list/items_to_collect = list() // Item types needed
	var/list/items_collected = list() // Actual item refs

/datum/city_quest/collect/Destroy()
	items_collected.Cut()
	return ..()

/datum/city_quest/collect/proc/try_collect_item(obj/item/I)
	if(!can_collect_item(I))
		return FALSE
	items_collected += I
	qdel(I)
	check_completion()
	update_contract()
	return TRUE

/datum/city_quest/collect/proc/can_collect_item(obj/item/I)
	if(items_collected.len >= items_required)
		return FALSE
	for(var/item_type in items_to_collect)
		if(istype(I, item_type))
			return TRUE
	return FALSE

/datum/city_quest/collect/proc/on_item_destroyed(obj/item/source)
	SIGNAL_HANDLER
	items_collected -= source
	check_completion()

/datum/city_quest/collect/proc/submit_items(obj/structure/quest_board/board)
	// Items are already deleted when collected, just clear the list
	items_collected.Cut()
	completed = TRUE
	turned_in = TRUE
	grant_reward()

/datum/city_quest/collect/check_completion()
	if(items_collected.len >= items_required)
		on_complete()
		return TRUE
	return FALSE

/datum/city_quest/collect/get_progress_text()
	return "[items_collected.len]/[items_required] collected"

/datum/city_quest/collect/can_generate()
	// Count how many valid items exist on the map
	var/item_count = 0
	for(var/obj/item/I in world)
		if(!I.z) // Skip items not on a z-level
			continue
		if(can_collect_item(I))
			item_count++
			if(item_count >= items_required)
				return TRUE
	return FALSE

// Collect quest examples
/datum/city_quest/collect/tres_metal
	name = "Tres Metal Collection"
	desc = "Gather 5 pieces of Tres Metal (basic forge material) from the backstreets."
	items_required = 5
	reward_ahn = 1600
	items_to_collect = list(/obj/item/tresmetal)

/datum/city_quest/collect/sweeper_meat
	name = "Sweeper Meat Harvest"
	desc = "Collect 6 pieces of Sweeper meat for... research purposes."
	items_required = 6
	reward_ahn = 1200
	items_to_collect = list(/obj/item/food/meat/slab/sweeper)

/datum/city_quest/collect/worm_meat
	name = "Worm Meat Collection"
	desc = "Gather 6 pieces of Worm meat - it's surprisingly valuable."
	items_required = 6
	reward_ahn = 1000
	items_to_collect = list(/obj/item/food/meat/slab/worm)

/datum/city_quest/collect/robot_meat
	name = "Mechanical Parts Salvage"
	desc = "Collect 5 pieces of Robot 'meat' from destroyed bots."
	items_required = 5
	reward_ahn = 1400
	items_to_collect = list(/obj/item/food/meat/slab/robot)

/datum/city_quest/collect/human_meat
	name = "Evidence Collection"
	desc = "Collect 3 pieces of... evidence... from defeated humanoids. No questions asked."
	items_required = 3
	reward_ahn = 1800
	items_to_collect = list(/obj/item/food/meat/slab/human)

/datum/city_quest/collect/meat_variety
	name = "Exotic Meat Sampler"
	desc = "Collect 2 each of Sweeper, Worm, and Robot meat for a special client."
	items_required = 6
	reward_ahn = 2000
	items_to_collect = list(/obj/item/food/meat/slab/sweeper,
							/obj/item/food/meat/slab/worm,
							/obj/item/food/meat/slab/robot)
	office_lock = TRUE

/datum/city_quest/collect/weapons
	name = "Weapon Confiscation"
	desc = "Collect 5 weapons from the backstreets."
	items_required = 5
	reward_ahn = 1600
	items_to_collect = list(/obj/item/ego_weapon)
	office_lock = TRUE

/datum/city_quest/collect/mixed_salvage
	name = "General Salvage Operation"
	desc = "Collect any 10 valuable items from the backstreets."
	items_required = 10
	reward_ahn = 1200
	items_to_collect = list(/obj/item/tresmetal,
							/obj/item/ego_weapon)

/datum/city_quest/collect/resurgence_tapes
	name = "Lost Tape Recovery"
	desc = "Collect 3 old tapes containing historical records. These resurgence tapes are highly valuable."
	items_required = 3
	reward_ahn = 2400
	items_to_collect = list(/obj/item/tape/resurgence)
	grade_lock = 7

/datum/city_quest/collect/single_tape
	name = "Tape Acquisition"
	desc = "Acquire just one resurgence tape for archival purposes."
	items_required = 1
	reward_ahn = 1000
	items_to_collect = list(/obj/item/tape/resurgence)

// Special item collect quests - only appear if items exist
/datum/city_quest/collect/raw_pe
	name = "Raw PE Acquisition"
	desc = "Collect 2 units of Raw PE (Positive Enkephalin) for research."
	items_required = 2
	reward_ahn = 3000
	items_to_collect = list(/obj/item/rawpe)
	time_lock = 30 MINUTES
	grade_lock = 5
	office_lock = TRUE

/datum/city_quest/collect/refined_pe
	name = "Refined PE Collection"
	desc = "Acquire a single unit of Refined PE - extremely valuable material."
	items_required = 1
	reward_ahn = 5000
	items_to_collect = list(/obj/item/refinedpe)
	time_lock = 45 MINUTES
	grade_lock = 4
	office_lock = TRUE

/datum/city_quest/collect/redacted_tape
	name = "Classified Tape Recovery"
	desc = "URGENT: Retrieve the REDACTED resurgence tape. Handle with extreme care."
	items_required = 1
	reward_ahn = 8000
	items_to_collect = list(/obj/item/tape/resurgence/redacted)
	time_lock = 60 MINUTES
	grade_lock = 4

/datum/city_quest/collect/ayin_plush
	name = "Lost Artifact Recovery"
	desc = "A rare Ayin plush has been reported. Retrieve it for our archives."
	items_required = 1
	reward_ahn = 4000
	items_to_collect = list(/obj/item/toy/plush/ayin)
	time_lock = 40 MINUTES
	grade_lock = 5

// INFO QUESTS
/datum/city_quest/info
	quest_type = "info"
	var/items_required = 10
	var/list/items_to_show = list() // Item types needed
	var/list/items_shown = list() // Items that have been shown

/datum/city_quest/info/Destroy()
	items_shown.Cut()
	return ..()

/datum/city_quest/info/proc/try_show_item(obj/item/I)
	if(!can_show_item(I))
		return FALSE
	// Check if we already counted this specific item
	if(I in items_shown)
		return FALSE
	items_shown += I
	check_completion()
	update_contract()
	return TRUE

/datum/city_quest/info/proc/can_show_item(obj/item/I)
	for(var/item_type in items_to_show)
		if(istype(I, item_type))
			return TRUE
	return FALSE

/datum/city_quest/info/proc/submit_info(obj/structure/quest_board/board)
	// Just mark as complete, don't delete items
	completed = TRUE
	turned_in = TRUE
	grant_reward()

/datum/city_quest/info/check_completion()
	if(items_shown.len >= items_required)
		on_complete()
		return TRUE
	return FALSE

/datum/city_quest/info/get_progress_text()
	return "[items_shown.len]/[items_required] documented"

/datum/city_quest/info/can_generate()
	// Count how many valid items exist on the map
	var/item_count = 0
	for(var/obj/item/I in world)
		if(!I.z) // Skip items not on a z-level
			continue
		if(can_show_item(I))
			item_count++
			if(item_count >= items_required)
				return TRUE
	return FALSE

// Info quest examples
/datum/city_quest/info/tres_survey
	name = "Material Survey"
	desc = "Show us 5 pieces of Tres Metal for market analysis."
	items_required = 5
	reward_ahn = 150 // Less than collect quest
	items_to_show = list(/obj/item/tresmetal)

/datum/city_quest/info/meat_quality
	name = "Meat Quality Assessment"
	desc = "Show us samples of different meat types (2 each) for quality testing."
	items_required = 6
	reward_ahn = 200
	items_to_show = list(/obj/item/food/meat/slab/sweeper,
						/obj/item/food/meat/slab/worm,
						/obj/item/food/meat/slab/robot)

/datum/city_quest/info/weapon_catalog
	name = "Weapon Documentation"
	desc = "Show us 3 different weapons for our records."
	items_required = 3
	reward_ahn = 250 // Less than collect quest
	items_to_show = list(/obj/item/ego_weapon, /obj/item/gun)

/datum/city_quest/info/rare_materials
	name = "Rare Material Assessment"
	desc = "Show us any rare crafting materials you find."
	items_required = 2
	reward_ahn = 300
	items_to_show = list(/obj/item/tresmetal/cobalt, /obj/item/tresmetal/bloodiron)

/datum/city_quest/info/combat_gear
	name = "Combat Equipment Review"
	desc = "Show us any combat-ready equipment for evaluation (weapons or armor)."
	items_required = 4
	reward_ahn = 200
	items_to_show = list(/obj/item/ego_weapon, /obj/item/clothing/suit/armor/ego_gear)

/datum/city_quest/info/salvage_audit
	name = "Salvage Value Audit"
	desc = "Show us 8 items of any value found in the backstreets."
	items_required = 8
	reward_ahn = 150
	items_to_show = list(/obj/item/tresmetal,
						/obj/item/ego_weapon,
						/obj/item/stack/spacecash,
						/obj/item/food/meat/slab)

/datum/city_quest/info/tape_verification
	name = "Historical Tape Verification"
	desc = "Show us 2 resurgence tapes for authentication. The tapes will not be taken."
	items_required = 2
	reward_ahn = 400
	items_to_show = list(/obj/item/tape/resurgence)

/datum/city_quest/info/rare_finds
	name = "Rare Artifact Documentation"
	desc = "Show us any combination of rare items: tapes, anomaly cores, or documents."
	items_required = 3
	reward_ahn = 1500
	items_to_show = list(/obj/item/tape/resurgence,
						/obj/item/raw_anomaly_core,
						/obj/item/documents)
	office_lock = TRUE

// PICTURE QUESTS
/datum/city_quest/picture
	quest_type = "picture"
	var/list/targets_to_photograph = list() // Mob/obj types needed
	var/pictures_required = 1
	var/list/pictures_submitted = list() // Submitted photo items
	var/require_alive = FALSE // If TRUE, dead mobs don't count
	var/list/photographed_mobs = list() // Track mobs already photographed to require unique targets

/datum/city_quest/picture/Destroy()
	pictures_submitted.Cut()
	photographed_mobs.Cut()
	return ..()

/datum/city_quest/picture/proc/try_submit_picture(obj/item/photo/P)
	if(!P.picture)
		return FALSE
	if(pictures_submitted.len >= pictures_required)
		return FALSE

	// Check if this photo already submitted
	if(P in pictures_submitted)
		return FALSE

	// Check if photo contains valid target and get the target mob
	var/mob/valid_target = get_valid_target_from_photo(P)

	// If no valid target mob found, fall back to is_valid_photo() for special quests (like monolith)
	if(!valid_target)
		if(!is_valid_photo(P))
			return FALSE
	else
		// Check if this specific mob has already been photographed (must be unique targets)
		if(valid_target in photographed_mobs)
			if(quest_mind?.current)
				to_chat(quest_mind.current, span_warning("You've already submitted a photo of this target!"))
			return FALSE
		photographed_mobs += valid_target

	pictures_submitted += P
	RegisterSignal(P, COMSIG_PARENT_QDELETING, PROC_REF(on_picture_destroyed))
	P.forceMove(null) // Move to nullspace
	check_completion()
	update_contract()
	return TRUE

/// Returns the first valid target mob found in the photo, or null if none
/datum/city_quest/picture/proc/get_valid_target_from_photo(obj/item/photo/P)
	if(!P.picture)
		return null
	if(!LAZYLEN(P.picture.mobs_seen))
		return null

	for(var/mob/M in P.picture.mobs_seen)
		// Skip deleted mobs (garbage collected references)
		if(QDELETED(M))
			continue
		// Check if dead when we need alive
		if(require_alive && (M in P.picture.dead_seen))
			continue

		// Check if valid target type
		for(var/target_type in targets_to_photograph)
			if(istype(M, target_type))
				return M
	return null

/datum/city_quest/picture/proc/is_valid_photo(obj/item/photo/P)
	return get_valid_target_from_photo(P) != null

/datum/city_quest/picture/proc/on_picture_destroyed(obj/item/photo/source)
	SIGNAL_HANDLER
	pictures_submitted -= source
	check_completion()

/datum/city_quest/picture/proc/submit_pictures(obj/structure/quest_board/board)
	// Delete all submitted photos
	for(var/obj/item/photo/P in pictures_submitted)
		qdel(P)
	pictures_submitted.Cut() // Clear the list
	completed = TRUE
	turned_in = TRUE
	grant_reward()

/datum/city_quest/picture/check_completion()
	if(pictures_submitted.len >= pictures_required)
		on_complete()
		return TRUE
	return FALSE

/datum/city_quest/picture/get_progress_text()
	return "[pictures_submitted.len]/[pictures_required] photographed"

/datum/city_quest/picture/can_generate()
	if(!targets_to_photograph.len)
		return TRUE // No specific targets required
	// Count how many valid targets exist on the map
	var/target_count = 0
	for(var/mob/living/L in GLOB.mob_living_list)
		if(!L.z) // Skip mobs not on a z-level
			continue
		if(require_alive && L.stat == DEAD)
			continue
		for(var/target_type in targets_to_photograph)
			if(istype(L, target_type))
				target_count++
				if(target_count >= pictures_required)
					return TRUE
				break
	return FALSE

// Picture quest examples
/datum/city_quest/picture/amber_documentation
	name = "Amber Bug Documentation"
	desc = "Take a photograph of a living Amber Bug for our records."
	pictures_required = 1
	reward_ahn = 400
	targets_to_photograph = list(/mob/living/simple_animal/hostile/ordeal/amber_bug)
	require_alive = TRUE

/datum/city_quest/picture/amber_dusk_photo
	name = "Amber Dusk Sighting"
	desc = "Photograph a living Amber Dusk - the larger worm variant. Extremely valuable intel."
	pictures_required = 1
	reward_ahn = 800
	targets_to_photograph = list(/mob/living/simple_animal/hostile/ordeal/amber_dusk)
	require_alive = TRUE

/datum/city_quest/picture/sweeper_types
	name = "Sweeper Variant Study"
	desc = "Photograph 2 different types of Sweepers (Dawn, Noon, Chunky, or Lanky) for research."
	pictures_required = 2
	reward_ahn = 600
	targets_to_photograph = list(/mob/living/simple_animal/hostile/ordeal/indigo_dawn,
								/mob/living/simple_animal/hostile/ordeal/indigo_noon,
								/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky,
								/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky)

/datum/city_quest/picture/gcorp_surveillance
	name = "G-Corp Unit Surveillance"
	desc = "Photograph any living G-Corp remnant."
	pictures_required = 1
	reward_ahn = 500
	targets_to_photograph = list(/mob/living/simple_animal/hostile/ordeal/steel_dawn,
								/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon)
	require_alive = TRUE

/datum/city_quest/picture/bot_analysis
	name = "Bot Configuration Analysis"
	desc = "Photograph both a small and big Green Bot for technical analysis."
	pictures_required = 2
	reward_ahn = 600
	targets_to_photograph = list(/mob/living/simple_animal/hostile/ordeal/green_bot,
								/mob/living/simple_animal/hostile/ordeal/green_bot_big)

/datum/city_quest/picture/combat_documentation
	name = "Combat Documentation"
	desc = "Photograph 3 dead hostiles of any type. For the archives."
	pictures_required = 3
	reward_ahn = 400
	targets_to_photograph = list(/mob/living/simple_animal/hostile/ordeal)
	require_alive = FALSE

/datum/city_quest/picture/combat_documentation/get_valid_target_from_photo(obj/item/photo/P)
	if(!P.picture?.mobs_seen?.len)
		return null

	for(var/mob/M in P.picture.mobs_seen)
		if(QDELETED(M))
			continue
		if(M in P.picture.dead_seen) // Only count dead ones
			for(var/target_type in targets_to_photograph)
				if(istype(M, target_type))
					return M
	return null

/datum/city_quest/picture/rat_census
	name = "Rat Population Survey"
	desc = "Photograph 3 different rats (dead or alive) to help track the infestation."
	pictures_required = 3
	reward_ahn = 300
	targets_to_photograph = list(/mob/living/simple_animal/hostile/humanoid/rat)

/datum/city_quest/picture/monolith_sighting
	name = "Anomalous Structure Documentation"
	desc = "Photograph the mysterious Monolith if you encounter one."
	pictures_required = 1
	reward_ahn = 2000
	require_alive = FALSE
	time_lock = 35 MINUTES

/datum/city_quest/picture/monolith_sighting/is_valid_photo(obj/item/photo/P)
	if(!P.picture)
		return FALSE

	// Check the description for monolith
	if(findtext(P.picture.picture_desc, "monolith"))
		return TRUE

	return FALSE

/datum/city_quest/picture/priest_encounter
	name = "Redeemed Star Sighting"
	desc = "Photograph the Redeemed Star of the Echo Office if you encounter them."
	pictures_required = 1
	reward_ahn = 1500
	targets_to_photograph = list(/mob/living/simple_animal/npc/priest)
	require_alive = TRUE

/datum/city_quest/picture/amber_knight_photo
	name = "Amber Knight Documentation"
	desc = "Capture a photo of the Amber Knight fixer. They appear in flashes of electricity."
	pictures_required = 1
	reward_ahn = 1500
	targets_to_photograph = list(/mob/living/simple_animal/npc/electic)
	require_alive = TRUE

/datum/city_quest/picture/tinkerer_meeting
	name = "Tinkerer Encounter"
	desc = "Photograph the elusive Tinkerer."
	pictures_required = 1
	reward_ahn = 1800
	targets_to_photograph = list(/mob/living/simple_animal/npc/tinkerer,
								/mob/living/simple_animal/npc/tinkerer_speech)
	require_alive = TRUE

/datum/city_quest/picture/archsage_wisdom
	name = "Arch Sage Visitation"
	desc = "Photograph the Arch Sage."
	pictures_required = 1
	reward_ahn = 1600
	targets_to_photograph = list(/mob/living/simple_animal/npc/archsage)
	require_alive = TRUE
	time_lock = 30 MINUTES

/datum/city_quest/picture/misguiding_light
	name = "Misguiding Light Evidence"
	desc = "Photograph the Misguiding Light, also known as Joey. Handle with extreme caution. They should be located outside of the fallen L-Corp Branch"
	pictures_required = 1
	reward_ahn = 1700
	targets_to_photograph = list(/mob/living/simple_animal/npc/joey)
	require_alive = TRUE
	time_lock = 40 MINUTES

// DISTORTION QUESTS
/datum/city_quest/distortion
	quest_type = "distortion"
	var/mob_type_to_spawn = /mob/living/simple_animal/hostile/distortion
	var/mob/living/spawned_mob
	var/photo_taken = FALSE
	var/spawn_announced = FALSE

/datum/city_quest/distortion/Destroy()
	if(spawned_mob && !QDELETED(spawned_mob))
		qdel(spawned_mob)
	return ..()

/datum/city_quest/distortion/on_accept(datum/mind/M)
	. = ..()
	// Find distortion landmarks and spawn the mob
	var/list/possible_spawns = list()
	for(var/obj/effect/landmark/distortion/L in GLOB.landmarks_list)
		possible_spawns += L

	if(!possible_spawns.len)
		to_chat(M.current, span_warning("No suitable location found for the distortion. Contract cancelled."))
		return FALSE

	var/obj/effect/landmark/distortion/chosen_spawn = pick(possible_spawns)
	spawned_mob = new mob_type_to_spawn(get_turf(chosen_spawn))

	// Register death signal to fail quest if killed before photo
	RegisterSignal(spawned_mob, COMSIG_LIVING_DEATH, PROC_REF(on_distortion_death))

	to_chat(M.current, span_warning("A distortion has manifested somewhere in the city. Find and photograph it!"))
	return TRUE

/datum/city_quest/distortion/proc/on_distortion_death(mob/living/source)
	SIGNAL_HANDLER
	if(!photo_taken && quest_mind?.current)
		to_chat(quest_mind.current, span_warning("The distortion was destroyed before you could photograph it! Contract failed."))
		// Quest fails but doesn't get removed from active quests

/datum/city_quest/distortion/proc/try_photo(obj/item/photo/P)
	if(!P.picture || photo_taken)
		return FALSE

	// Check if the spawned mob is in the photo
	if(spawned_mob in P.picture.mobs_seen)
		// Check if it's alive in the photo
		if(!(spawned_mob in P.picture.dead_seen))
			photo_taken = TRUE
			check_completion()
			update_contract()
			return TRUE
	return FALSE

/datum/city_quest/distortion/check_completion()
	if(photo_taken)
		on_complete()
		return TRUE
	return FALSE

/datum/city_quest/distortion/get_progress_text()
	if(!spawned_mob || QDELETED(spawned_mob))
		return "Distortion lost"
	if(spawned_mob.stat == DEAD)
		return "Distortion dead - photo needed while alive"
	if(photo_taken)
		return "Photographed!"
	return "Find and photograph the distortion"

// Distortion quest examples
/datum/city_quest/distortion/another_day
	name = "Another Day's Work Sighting"
	desc = "A corporate distortion has appeared in the backstreets. Photograph it for our records. Moderate threat."
	reward_ahn = 2500
	mob_type_to_spawn = /mob/living/simple_animal/hostile/distortion/another_day_work

/datum/city_quest/distortion/bunnyman
	name = "Bunnyman Sighting"
	desc = "The Bunnyman distortion has appeared in the backstreets. Document this anomaly. High threat level."
	reward_ahn = 3500
	mob_type_to_spawn = /mob/living/simple_animal/hostile/distortion/bunnyman
	grade_lock = 6

/datum/city_quest/distortion/lantern
	name = "Lantern Bearer Sighting"
	desc = "A Lantern distortion has appeared in the backstreets. Extreme caution advised."
	reward_ahn = 4000
	mob_type_to_spawn = /mob/living/simple_animal/hostile/distortion/lantern
	grade_lock = 5

/datum/city_quest/distortion/papa_bongy
	name = "Papa Bongy Sighting"
	desc = "Papa Bongy has appeared in the backstreets! Document this rare distortion. EXTREME DANGER."
	reward_ahn = 5000
	mob_type_to_spawn = /mob/living/simple_animal/hostile/distortion/papa_bongy
	grade_lock = 5

/datum/city_quest/distortion/timeripper
	name = "Timeripper Sighting"
	desc = "A Timeripper distortion has appeared in the backstreets. Photograph before temporal instability increases. MAXIMUM THREAT."
	reward_ahn = 6000
	mob_type_to_spawn = /mob/living/simple_animal/hostile/distortion/timeripper
	grade_lock = 4
