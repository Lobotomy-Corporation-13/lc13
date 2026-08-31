// I was originally going to make a file in DEFINES with each of these types but then I realized I wasn't actually using them anywhere?
// I usually just pull these with typesof(/datum/gamespeed_setting) so there's no need for it? I think?

/// This is default gamespeed.
/datum/gamespeed_setting
	/// The name that will show up when game speed is being voted for. Also basically used as an ID due to how voting works.
	var/player_facing_name = "Default Speed (1x)"
	/// We multiply timelocks and abno arrival times by the inverse of this. For example, coefficient of 1.5 would multiply our timelocks and arrivals by 0.667.
	var/speed_coefficient = 1
	/// Assoc list, the keys are ordeal levels and the values are the minimum amount of melts since the last ordeal for this ordeal to happen
	var/minimum_ordeal_gap = alist(1 = 3, 2 = 4, 3 = 5, 4 = 6)
	/// Assoc list, the keys are ordeal levels and the values are how many meltdowns less should it take for each ordeal to happen. Will respect minimum_ordeal_gap
	/// The values should be 0 or negative. If you make them positive you're actually delaying the ordeals further... which I guess is valid? For slower speeds?
	// Sadly you have to fill this out manually, I mean I wish we could just apply the speed_coefficient but it just... won't work well with this.
	var/meltdowns_per_ordeal_adjustment = alist(1 = 0, 2 = 0, 3 = 0, 4 = 0)
	/// Can this setting be voted for?
	var/available_setting = TRUE
	var/applied_announcement = "Personnel must be advised: Enkephalin filtering procedures have been shifted back to standard protocols. Ordeal events and Abnormality meltdowns will return to standard frequency."
	var/applied_sfx = 'sound/machines/dun_don_alert.ogg'

/datum/gamespeed_setting/fast
	player_facing_name = "Fast Speed (1.25x)"
	available_setting = TRUE
	speed_coefficient = 1.25
	minimum_ordeal_gap = alist(1 = 3, 2 = 4, 3 = 4, 4 = 5)
	meltdowns_per_ordeal_adjustment = alist(1 = 0, 2 = -1, 3 = -1, 4 = -2)
	applied_announcement = "Personnel must be advised: As a result of changes in internal Enkephalin filtering procedures, Ordeal events for this shift will occur within fewer meltdowns than is the norm. \
	To compensate for this, Extraction has agreed to speed up Abnormality delivery accordingly."

/// For testing
/datum/gamespeed_setting/ultrafast
	player_facing_name = "Ultra Fast Speed (2x)"
	available_setting = FALSE
	speed_coefficient = 2
	minimum_ordeal_gap = alist(1 = 2, 2 = 3, 3 = 3, 4 = 4)
	meltdowns_per_ordeal_adjustment = alist(1 = 0, 2 = -2, 3 = -3, 4 = -4)
	applied_announcement = "Personnel must be advised: Experimental Enkephalin filtering procedures have been enabled, optimizing for speed. \
	As a side effect, the resulting accumulation of impurities will result in significantly faster Ordeal events. Abnormalities will be delivered with twice as much speed so you may prepare E.G.O. to face them. This will be rough. Good luck."
// ------------- PROCS -------------
/datum/gamespeed_setting/proc/ApplyChanges()
	// Timelocks: we need to do these before setting the gamespeed so we can undo potential changes to the original timelock values
	// As in, original Dawn timelock is 12000. If the speed gets changed by 1.25x, it will go down to 9600. We want to change it back to 12000 before applying
	// any new speed.
	HandleTimelocks()

	// Also set next abno spawn time back to whatever it was, then to the correctly modified time.
	HandleAbnoSpawnTime()

	// Now we can set the gamespeed. We don't need the old one anymore.
	SSlobotomy_corp.gamespeed = src

	// Ordeal time
	HandleOrdeals()

	priority_announce(applied_announcement, "Ordeal Frequency Notice", applied_sfx)

/datum/gamespeed_setting/proc/HandleTimelocks()
	var/list/new_timelocks = list()
	for(var/current_timelock in SSlobotomy_corp.ordeal_timelock)
		var/modified_timelock = ((current_timelock) * (SSlobotomy_corp.gamespeed.speed_coefficient)) * (1 / src.speed_coefficient)
		new_timelocks.Add(modified_timelock)

	SSlobotomy_corp.ordeal_timelock = new_timelocks

/datum/gamespeed_setting/proc/HandleAbnoSpawnTime()
	SSabnormality_queue.next_abno_spawn_time *= SSlobotomy_corp.gamespeed.speed_coefficient
	SSabnormality_queue.next_abno_spawn_time *= (1 / src.speed_coefficient)

/datum/gamespeed_setting/proc/HandleOrdeals()
	SSlobotomy_corp.SetNextOrdealTime(TRUE)

// ------------- ABNO BLITZ -------------
/// This one has a bunch of snowflake behaviour, it's not a true game speed setting. It's an adaptation of a former station trait called Abno Blitz.
/// In essence, it skips Dawn and Noon, ups everyone's stats, speeds up Abno arrivals, and forces only WAW+ abnormalities.
/datum/gamespeed_setting/abno_blitz
	player_facing_name = "ABNO BLITZ"
	available_setting = TRUE
	speed_coefficient = 2
	applied_announcement = "Personnel must be advised: Due to a disaster in another branch, this Facility has been requisitioned to hold their most dangerous Abnormalities while repairs are performed, as well as the more volatile specimens already shipped by the Logistics division. \n\n\
	Enhancement bullets have been applied to all personnel. You will be receiving one single ZAYIN - all other Abnormalities will be WAW or ALEPH threat class. Prepare for a Dusk Ordeal.\n\n\
	The Extraction and Architecture Departments wish you the best of luck. Face the Fear, Build the Future."
	applied_sfx = 'sound/effects/suppression.ogg'
	var/list/job_minimum_stats = list(/datum/job/agent = 80, /datum/job/suppression = 80, /datum/job/command = 60, /datum/job/assistant = 40)

/datum/gamespeed_setting/abno_blitz/HandleTimelocks()
	SSlobotomy_corp.ordeal_timelock = list(0, 0, 30 MINUTES, 50 MINUTES, 0, 0, 0, 0, 0)

/datum/gamespeed_setting/abno_blitz/HandleOrdeals()
	SSlobotomy_corp.next_ordeal_level = 3
	SSlobotomy_corp.RollOrdeal()

/datum/gamespeed_setting/abno_blitz/ApplyChanges()
	. = ..()
	HandleExistingHumanStatBuffs()

/datum/gamespeed_setting/abno_blitz/proc/HandleExistingHumanStatBuffs()
	for(var/mob/living/carbon/human/person_that_already_exists in GLOB.player_list)
		if(person_that_already_exists.stat >= DEAD)
			continue
		if(!(person_that_already_exists.mind))
			continue

		// Get their job and compare the job's minimum Blitz stats to what they already have.
		var/datum/job/wageslave_specialization = SSjob.name_occupations[person_that_already_exists.mind.assigned_role]
		for(var/evaluating_job_datum_match in job_minimum_stats)
			if(!istype(wageslave_specialization, evaluating_job_datum_match))
				continue

			// Raise all their attribute limits and levels as appropiate.
			var/minimum_stat_level = job_minimum_stats[evaluating_job_datum_match]
			for(var/attr in person_that_already_exists.attributes)
				var/datum/attribute/current_attr_datum = person_that_already_exists.attributes[attr]
				var/current_attr_limit = current_attr_datum.level_limit
				if(current_attr_limit < minimum_stat_level)
					person_that_already_exists.adjust_attribute_limit(minimum_stat_level-current_attr_limit) // weird: this affects all attributes. thankfully the conditional should stop us from stacking this
				var/current_attr_level = get_raw_level(person_that_already_exists, attr)
				if(current_attr_level < minimum_stat_level)
					person_that_already_exists.adjust_attribute_level(attr, minimum_stat_level-current_attr_level)
			break


