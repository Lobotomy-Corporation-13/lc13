// Meltdown types
#define MELTDOWN_NORMAL 1
#define MELTDOWN_GRAY 2
#define MELTDOWN_GOLD 3
#define MELTDOWN_PURPLE 4
#define MELTDOWN_CYAN 5
#define MELTDOWN_BLACK 6

// TODO: Do something about it, idk
SUBSYSTEM_DEF(lobotomy_corp)
	name = "Lobotomy Corporation"
	flags = SS_KEEP_TIMING | SS_BACKGROUND | SS_NO_FIRE
	wait = 5 MINUTES

	var/list/all_abnormality_datums = list()

	// How many qliphoth_events were called so far
	var/qliphoth_state = 0
	// Current level of the qliphoth meter
	var/qliphoth_meter = 0
	// State at which it will cause qliphoth meltdowns/ordeal
	var/qliphoth_max = 4
	// How many abnormalities will be affected. Cannot be more than current amount of abnos
	var/qliphoth_meltdown_amount = 1
	// What abnormality threat levels are affected by meltdowns
	var/list/qliphoth_meltdown_affected = list(
		ZAYIN_LEVEL,
		TETH_LEVEL,
		HE_LEVEL,
		WAW_LEVEL,
		ALEPH_LEVEL
		)

	// Assoc list of ordeals by level
	var/list/all_ordeals = list(
							1 = list(),
							2 = list(),
							3 = list(),
							4 = list(),
							5 = list(),
							6 = list(),
							7 = list(),
							8 = list(),
							9 = list()
							)
	// At what qliphoth_state next ordeal will happen
	var/next_ordeal_time = 1
	/// At what qliphoth_state did the last ordeal happen? Used to check for minimum ordeal time gap for gamespeed adjustments
	var/last_ordeal_time = 0
	// What ordeal level is being rolled for
	var/next_ordeal_level = 1
	// Minimum time for each ordeal level to occur. If requirement is not met - normal meltdown will occur
	var/list/ordeal_timelock = list(20 MINUTES, 40 MINUTES, 60 MINUTES, 90 MINUTES, 0, 0, 0, 0, 0)
	// Datum of the chosen ordeal. It's stored so manager can know what's about to happen
	var/datum/ordeal/next_ordeal = null
	/// List of currently running ordeals
	var/list/current_ordeals = list()
	// Currently running core suppression
	var/datum/suppression/core_suppression = null
	// List of active core suppressions; Different from above, as there can only be one "main" core
	var/list/active_core_suppressions = list()
	// List of available core suppressions for manager to choose
	var/list/available_core_suppressions = list()
	// Completed Cores and Ordeals
	var/list/completed_challenges = list()
	// State of the core suppression
	var/core_suppression_state = 0
	// Work logs from all abnormalities
	var/list/work_logs = list()
	// Work logs, but from agent perspective. Used mainly for round-end report
	var/list/work_stats = list()
	// List of facility upgrade datums
	var/list/upgrades = list()

	// PE available to be spent
	var/available_box = 0
	// PE specifically for PE Quota
	var/goal_boxes = 0
	// Total PE generated
	var/total_generated = 0
	// Total PE spent
	var/total_spent = 0
	// The number we must reach
	var/box_goal = 0 // Initialized later
	// Where we reached our goal
	var/goal_reached = FALSE
	/// Multiplier to PE earned from working on abnormalities
	var/box_work_multiplier = 1
	/// Multiplier towards attribute points earned for working on melting abnormalities
	var/melt_work_multiplier = 1
	/// The area of effect of manager's bullets; -1 is for direct target only
	var/manager_bullet_area = -1
	/// When TRUE - abnormalities can be possessed by ghosts
	var/enable_possession = FALSE
	/// Amount of abnormalities that agents achieved full understanding on
	var/understood_abnos = 0
	/// The amount of core suppression options that will be available
	var/max_core_options = 3
	/// Points used for facility upgrades
	var/lob_points = 2
	/// Stats for Era/Do after an ordeal is done
	var/ordeal_stats = 0

	/// If TRUE - will not count deaths for auto restart
	var/auto_restart_in_progress = FALSE

	/// Datum which determines how fast the game runs in terms of ordeal frequency, abno arrival time, ordeal timelocks.
	var/datum/gamespeed_setting/gamespeed

	/// List which holds a datum of every gamespeed setting. We give this to the admin tool and to the voting subsystem, to populate their choices.
	// We will store even the disabled ones here, so that admins can still have access to them in their tools.
	/// We'll fill this list in Initialize(). It's probably a bad idea to qdel any of the datums in this list.
	// The disabled gamespeeds will have to be filtered out in the vote subsystem.
	var/list/available_gamespeeds = list()

	/// Amount of time before we check to see if there is a Manager, and if there isn't one, we allow any of our crew to start a Core.
	// ticker.dm uses this value to set a timer on roundstart
	var/core_selection_restriction_lift_timer = 15 MINUTES
	/// If this variable is TRUE, then non-managers are allowed to begin Core Suppressions.
	// Should start as FALSE, then after the amount of time specified in the above var, set to TRUE if there's no Manager, then after a Manager spawns, set to FALSE again.
	var/core_selection_restriction_lifted = FALSE

/datum/controller/subsystem/lobotomy_corp/Initialize(timeofday)
	if(SSmaptype.maptype in SSmaptype.combatmaps) // sleep
		flags |= SS_NO_FIRE
		return ..()

	gamespeed = new
	available_gamespeeds.Add(gamespeed)
	var/list/speeds = subtypesof(/datum/gamespeed_setting)
	for(var/setting_type in speeds)
		available_gamespeeds.Add(new setting_type())

	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(OnMobDeath))
	addtimer(CALLBACK(src, PROC_REF(SetGoal)), 5 MINUTES)
	addtimer(CALLBACK(src, PROC_REF(InitializeOrdeals)), 60 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(PickPotentialSuppressions)), 60 SECONDS)
	for(var/F in subtypesof(/datum/facility_upgrade))
		upgrades += new F

	return ..()

/datum/controller/subsystem/lobotomy_corp/proc/SetGoal()
	var/player_mod = length(GLOB.player_list) * 200	//200 For every client
	var/agent_mod = AvailableAgentCount() * 1000	//1000 more for each Agent.
	box_goal = clamp(player_mod+agent_mod, 2500, 36000)

	if(SSmaptype.maptype in SSmaptype.lc_maps)
		//Here's the anouncement for the trait.
		priority_announce("This shift is a ''[SSmaptype.chosen_trait]'' Shift. All staff is to be advised..", \
						"HQ Control", sound = 'sound/machines/dun_don_alert.ogg')
		return TRUE

/datum/controller/subsystem/lobotomy_corp/proc/InitializeOrdeals()
	// Build ordeals global list
	for(var/type in subtypesof(/datum/ordeal))
		var/datum/ordeal/O = new type()
		if(O.level < 1)
			qdel(O)
			continue
		all_ordeals[O.level] += O

	if(SSmaptype.chosen_trait == FACILITY_TRAIT_ABNO_BLITZ)
		next_ordeal_level = 3
		ordeal_timelock = list(0, 0, 30 MINUTES, 50 MINUTES, 0, 0, 0, 0, 0)
	RollOrdeal()
	return TRUE

// Called when any normal midnight ends
/datum/controller/subsystem/lobotomy_corp/proc/PickPotentialSuppressions(announce = FALSE, extra_core = FALSE)
	if(SSmaptype.chosen_trait == FACILITY_TRAIT_ABNO_BLITZ)
		priority_announce("This shift is a 'Blitz' Shift. Cores have been disabled.", \
						"Core Suppression", sound = 'sound/machines/dun_don_alert.ogg')
		return
	if(istype(core_suppression))
		return
	var/obj/machinery/computer/abnormality_auxiliary/aux_cons = locate() in GLOB.lobotomy_devices
	if(!aux_cons) // There's no consoles, for some reason
		message_admins("Tried to pick potential core suppressions, but there was no auxiliary consoles! Fix it!")
		return
	var/list/cores = subtypesof(/datum/suppression)
	// Remove cores that don't fit requirements
	for(var/core_type in cores)
		var/datum/suppression/C = core_type
		if(!extra_core && initial(C.after_midnight))
			cores -= core_type
			continue
		if(extra_core && !initial(C.after_midnight))
			cores -= core_type
			continue
		// Create to see if it meets requirements and becomes available
		C = new core_type()
		if(!C.available)
			cores -= core_type
		qdel(C)
	for(var/i = 1 to max_core_options)
		if(!LAZYLEN(cores))
			break
		var/core_type = pick(cores)
		available_core_suppressions += core_type
		cores -= core_type
	if(!LAZYLEN(available_core_suppressions))
		return
	// This solution is hacky and extra dirty I hate it
	if(extra_core)
		addtimer(CALLBACK(src, PROC_REF(WarnBeforeReset)), (4 MINUTES))
	if(announce)
		var/announce_text = "[extra_core ? "Extra" : "Sephirah"] Core Suppressions have been made available via auxiliary managerial consoles."
		var/announce_title = "[extra_core ? "Extra" : "Sephirah"] Core Suppression"
		priority_announce(announce_text, \
						announce_title, sound = 'sound/machines/dun_don_alert.ogg')
	for(var/obj/machinery/computer/abnormality_auxiliary/A in GLOB.lobotomy_devices)
		A.audible_message("<span class='notice'>[extra_core ? "Extra " : ""]Core Suppressions are now available!</span>")
		playsound(get_turf(A), 'sound/machines/dun_don_alert.ogg', 50, TRUE)
		A.updateUsrDialog()

/datum/controller/subsystem/lobotomy_corp/proc/WarnBeforeReset()
	for(var/obj/machinery/computer/abnormality_auxiliary/A in GLOB.lobotomy_devices)
		A.audible_message("<span class='userdanger'>Core Suppression options will be disabled if you don't pick one in a minute!</span>")
		playsound(get_turf(A), 'sound/machines/dun_don_alert.ogg', 100, TRUE, 14)
	addtimer(CALLBACK(src, PROC_REF(ResetPotentialSuppressions), TRUE), (1 MINUTES))

/datum/controller/subsystem/lobotomy_corp/proc/ResetPotentialSuppressions(announce = FALSE)
	if(istype(core_suppression) || !LAZYLEN(available_core_suppressions))
		return
	for(var/obj/machinery/computer/abnormality_auxiliary/A in GLOB.lobotomy_devices)
		A.audible_message("<span class='userdanger'>Core Suppression options have been disabled for this shift!</span>")
		playsound(get_turf(A), 'sound/machines/dun_don_alert.ogg', 100, TRUE, 14)
		A.selected_core_type = null
		A.updateUsrDialog()
	available_core_suppressions = list()
	if(announce)
		priority_announce("Core Suppression hasn't been chosen in 5 minutes window and have been disabled for this shift.", \
						"Core Suppression", sound = 'sound/machines/dun_don_alert.ogg')

/datum/controller/subsystem/lobotomy_corp/proc/NewAbnormality(datum/abnormality/new_abno)
	if(!istype(new_abno))
		return FALSE
	all_abnormality_datums += new_abno
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_ABNORMALITY_SPAWN, new_abno)
	return TRUE

/datum/controller/subsystem/lobotomy_corp/proc/WorkComplete(amount = 0, qliphoth_change = TRUE)
	if(qliphoth_change)
		QliphothUpdate()
	AdjustAvailableBoxes(amount)

/datum/controller/subsystem/lobotomy_corp/proc/AdjustAvailableBoxes(amount)
	available_box = max((available_box + amount), 0)
	if(amount > 0)
		total_generated += amount
	else
		total_spent -= amount
	CheckGoal()

/datum/controller/subsystem/lobotomy_corp/proc/AdjustGoalBoxes(amount)
	if(goal_reached)
		AdjustAvailableBoxes(amount)
		return
	goal_boxes = max(goal_boxes + amount, 0)
	if(amount > 0)
		total_generated += amount
	else
		total_spent -= amount
	CheckGoal()

/datum/controller/subsystem/lobotomy_corp/proc/CheckGoal()
	if(goal_reached || box_goal == 0)
		return
	if(available_box + goal_boxes >= box_goal)
		AddLobPoints(4, "Quota Reward")
		available_box -= box_goal - goal_boxes // Leftover is drained
		goal_reached = TRUE

		//You get a C rating if your rating is a D.
		if(SSticker.rating_achieved == "D")
			SSticker.rating_achieved = "C"

		priority_announce("The energy production goal has been reached, and this shift is considered a success. \
				Overtime is approved for finishing any incomplete ordeals.", "Energy Production", sound='sound/misc/notice2.ogg')
		var/pizzatype_list = subtypesof(/obj/item/food/pizza)
		pizzatype_list -= /obj/item/food/pizza/arnold // No murder pizza
		pizzatype_list -= /obj/item/food/pizza/margherita/robo // No robo pizza
		for(var/mob/living/carbon/human/person in GLOB.mob_living_list)
			// Yes, this delivers to dead bodies. It's REALLY FUNNY.
			var/obj/structure/closet/supplypod/centcompod/pod = new()
			var/pizzatype = pick(pizzatype_list)
			new pizzatype(pod)
			pod.explosionSize = list(0,0,0,0)
			to_chat(person, "<span class='nicegreen'>It's pizza time!</span>")
			new /obj/effect/pod_landingzone(get_turf(person), pod)
		for(var/mob/M in GLOB.player_list)
			if(!M.ckey || !M.client)
				continue
			SSpersistence.agent_rep_change[M.ckey] += 3
	return

/datum/controller/subsystem/lobotomy_corp/proc/QliphothUpdate(amount = 1)
	qliphoth_meter += amount
	if(qliphoth_meter >= qliphoth_max)
		QliphothEvent()

/datum/controller/subsystem/lobotomy_corp/proc/QliphothEvent()
	// Update list of abnormalities that can be affected by meltdown
	if((ZAYIN_LEVEL in qliphoth_meltdown_affected) && ROUNDTIME >= 30 MINUTES)
		qliphoth_meltdown_affected -= ZAYIN_LEVEL
	if((TETH_LEVEL in qliphoth_meltdown_affected) && ROUNDTIME >= 60 MINUTES)
		qliphoth_meltdown_affected -= TETH_LEVEL
	qliphoth_meter = 0
	var/abno_amount = length(all_abnormality_datums)
	var/player_count = AvailableAgentCount()
	var/total_count = AvailableAgentCount(suppressioncount = TRUE)
	var/suppression_modifier = 1
	if(player_count != total_count)
		suppression_modifier = 1.3
	qliphoth_max = round((player_count > 1 ? 4 : 3) + player_count*1.5*suppression_modifier + GLOB.Sephirahordealspeed + GetFacilityUpgradeValue(UPGRADE_MELTDOWN_INCREASE)) // Some extra help on non solo rounds
	qliphoth_state += 1
	for(var/datum/abnormality/A in all_abnormality_datums)
		if(istype(A.current))
			A.current.OnQliphothEvent()
	var/ran_ordeal = FALSE
	if(qliphoth_state + 1 >= next_ordeal_time) // If ordeal is supposed to happen on the meltdown after that one
		if(SSmaptype.chosen_trait != FACILITY_TRAIT_ABNO_BLITZ)
			if(istype(next_ordeal) && ordeal_timelock[next_ordeal.level] > ROUNDTIME) // And it's on timelock
				next_ordeal_time += 1 // So it does not appear on the ordeal monitors until timelock is off
	if(qliphoth_state >= next_ordeal_time)
		if(OrdealEvent())
			ran_ordeal = TRUE
	for(var/obj/structure/sign/ordealmonitor/O in GLOB.lobotomy_devices)
		O.update_icon()
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_MELTDOWN_START, ran_ordeal)
	if(ran_ordeal)
		return
	InitiateMeltdown(qliphoth_meltdown_amount, FALSE)
	// Less agents will decrease meltdown count, but more - increase it
	var/agent_mod = 0.4 + (player_count * 0.1)
	qliphoth_meltdown_amount = clamp(round(abno_amount * CONFIG_GET(number/qliphoth_meltdown_percent) * agent_mod), 1, abno_amount * 0.5)

/datum/controller/subsystem/lobotomy_corp/proc/InitiateMeltdown(meltdown_amount = 1, forced = TRUE, type = MELTDOWN_NORMAL, min_time = 60, max_time = 90, alert_text = "Qliphoth meltdown occured in containment zones of the following abnormalities:", alert_sound = 'sound/effects/meltdownAlert.ogg')
	// Honestly, I wish I could do it another way, but oh well
	var/datum/suppression/command/C = GetCoreSuppression(/datum/suppression/command)
	if(istype(C))
		// All abno levels melt
		forced = TRUE
		meltdown_amount += C.meltdown_count_increase
		min_time = round(min_time * C.meltdown_time_multiplier)
		max_time = round(max_time * C.meltdown_time_multiplier)
	var/list/computer_list = list()
	var/list/meltdown_occured = list()
	for(var/obj/machinery/computer/abnormality/cmp in shuffle(GLOB.lobotomy_devices))
		if(!cmp.can_meltdown)
			continue
		if(cmp.meltdown || cmp.datum_reference.working)
			continue
		if(!cmp.datum_reference || !cmp.datum_reference.current)
			continue
		if(!cmp.datum_reference.current.IsContained()) // Does what the old check did, but allows it to be redefined by abnormalities that do so.
			continue
		if(!(cmp.datum_reference.threat_level in qliphoth_meltdown_affected) && !forced)
			continue
		computer_list += cmp
	for(var/i = 1 to meltdown_amount + GLOB.Sephirahmeltmodifier)
		if(!LAZYLEN(computer_list))
			break
		var/obj/machinery/computer/abnormality/computer = pick(computer_list)
		computer_list -= computer
		computer.start_meltdown(type, min_time, max_time)
		meltdown_occured += computer
	if(LAZYLEN(meltdown_occured))
		var/text_info = ""
		for(var/y = 1 to length(meltdown_occured))
			var/obj/machinery/computer/abnormality/computer = meltdown_occured[y]
			text_info += computer.datum_reference.name
			if(y != length(meltdown_occured))
				text_info += ", "
		text_info += "."
		// Announce next ordeal
		if(next_ordeal && (qliphoth_state + 1 >= next_ordeal_time))
			text_info += "\n\n[next_ordeal.name] will trigger on the next meltdown."
		priority_announce("[alert_text] [text_info]", "Qliphoth Meltdown", sound=alert_sound)
		return meltdown_occured

/datum/controller/subsystem/lobotomy_corp/proc/RollOrdeal()
	if(!islist(all_ordeals[next_ordeal_level]) || !LAZYLEN(all_ordeals[next_ordeal_level]))
		return FALSE
	var/list/available_ordeals = list()
	for(var/datum/ordeal/O in all_ordeals[next_ordeal_level])
		if(O.AbleToRun())
			available_ordeals += O
	if(!LAZYLEN(available_ordeals))
		return FALSE
	next_ordeal = pick(available_ordeals)
	all_ordeals[next_ordeal_level] -= next_ordeal

	SetNextOrdealTime()

	next_ordeal_level += 1 // Increase difficulty!
	message_admins("Next ordeal to occur will be [next_ordeal.name].")
	return TRUE

/// Proc that decides on which qliphoth_state the next Ordeal should happen.
// This logic was formerly in RollOrdeal() but I moved it out to more easily factor in gamespeed logic, and to be able to call it without rolling an ordeal.
/datum/controller/subsystem/lobotomy_corp/proc/SetNextOrdealTime(force_minimum_random_delay = FALSE)
	// This snippet was added here because of an edge case when setting a new game speed: we can call this proc with TRUE as a parameter to force the random delay to be -1.
	// Why? Because if you have an ordeal that rolled the random delay as -1, then you speed up the game, you could end up re-rolling the random delay as +1,
	// which would then make the "faster" game speed's ordeal to come later than the "slow" game speed's...
	var/random_delay_amount = 0
	if((force_minimum_random_delay) && (next_ordeal.random_delay))
		random_delay_amount = -1
	else if(next_ordeal.random_delay)
		random_delay_amount = rand(-1, 1)

	// I feel it's important to put this comment here, from ordeal definition: delay = min(6, level * 2) + 1

	/* This check handles the rare case of having no gamespeed when this is called. We just default to the normal gamespeed by instantiating a new one.
	An alternative way could be to just add the gamespeed-specific modifiers only if we have an instantiated gamespeed, but I feel that's more inconsistent.
	This way we ensure the default pacing is whatever the default gamespeed specifies it to be. Otherwise we could have rare, buggy cases where there's
	less (or more) of a gap between ordeals than there would be on the normal gamespeed, depending on any future tweaks made to that base type.
	*/
	if(QDELETED(gamespeed)) // Conditional means "If null or marked for deletion", from what I can gather
		gamespeed = new /datum/gamespeed_setting
	/// This is the bare minimum next qliphoth_state at which the next ordeal can be run, to be used in the max() coming up next
	var/minimum_next_ordeal_time = ((gamespeed.minimum_ordeal_gap[next_ordeal.level]) + (last_ordeal_time))
	next_ordeal_time = max((minimum_next_ordeal_time), ((last_ordeal_time) + (next_ordeal.delay) + (random_delay_amount) + (gamespeed.meltdowns_per_ordeal_adjustment[next_ordeal.level])))

	for(var/obj/structure/sign/ordealmonitor/O in GLOB.lobotomy_devices)
		O.update_icon()

/datum/controller/subsystem/lobotomy_corp/proc/OrdealEvent()
	if(!next_ordeal)
		return FALSE
	if(ordeal_timelock[next_ordeal.level] > ROUNDTIME)
		return FALSE // Time lock
	next_ordeal.Run()
	last_ordeal_time = qliphoth_state
	next_ordeal = null
	RollOrdeal()
	return TRUE // Very sloppy, but will do for now

/// Adds LOB points and notifies players via aux consoles
/datum/controller/subsystem/lobotomy_corp/proc/AddLobPoints(amount = 1, message = "UNKNOWN")
	lob_points += amount
	for(var/obj/machinery/computer/abnormality_auxiliary/A in GLOB.lobotomy_devices)
		A.audible_message("<span class='notice'>[round(amount, 0.001)] LOB point[amount > 1 ? "s" : ""] deposited! Reason: [message].</span>")
		playsound(get_turf(A), 'sound/machines/twobeep_high.ogg', 20, TRUE)
		A.updateUsrDialog()

/// Checks if all agents are dead with ordeals running. Used for procs below.
/datum/controller/subsystem/lobotomy_corp/proc/OrdealDeathCheck()
	// Might be temporary: Only works on high pop
	if(length(GLOB.clients) <= 30)
		return FALSE
	if(!LAZYLEN(current_ordeals))
		return FALSE
	if(SSmaptype.maptype == "skeld")
		return FALSE
	var/agent_count = AvailableAgentCount()
	if(agent_count > 0)
		return FALSE
	return TRUE

/datum/controller/subsystem/lobotomy_corp/proc/OnMobDeath(datum/source, mob/living/died, gibbed)
	SIGNAL_HANDLER
	if(!(SSmaptype.maptype in list("standard", "skeld", "fishing", "wonderlabs")))
		return FALSE
	if(!ishuman(died))
		return FALSE
	if(OrdealDeathCheck() && !auto_restart_in_progress)
		OrdealDeathAutoRestart()
	return TRUE

/// Restarts the round when time reaches 0
/datum/controller/subsystem/lobotomy_corp/proc/OrdealDeathAutoRestart(time = 120 SECONDS)
	auto_restart_in_progress = TRUE
	if(!OrdealDeathCheck())
		// Yay
		auto_restart_in_progress = FALSE
		return FALSE
	if(time <= 0)
		message_admins("The round is over because all agents are dead while ordeals are unresolved!")
		to_chat(world, span_danger("<b>The round is over because all agents are dead while ordeals are unresolved!</b>"))
		SSticker.force_ending = TRUE
		return TRUE
	to_chat(world, span_danger("<b>All agents are dead! If ordeals are left unresolved or new agents don't join, the round will automatically end in <u>[round(time/10)] seconds!</u></b>"))
	addtimer(CALLBACK(src, PROC_REF(OrdealDeathAutoRestart), max(0, time - 30 SECONDS)), 30 SECONDS)
	return TRUE

/// Proc called to adjust the gamespeed, hastens abnormality arrival time, sets new timelocks and recalculates next ordeal time.
/datum/controller/subsystem/lobotomy_corp/proc/AdjustGamespeed(datum/gamespeed_setting/new_gamespeed)
	if(!new_gamespeed) // If this somehow gets called with a null argument...
		return FALSE
	if(gamespeed.speed_coefficient <= 0 || new_gamespeed.speed_coefficient <= 0) // Checking we don't get something that would really mess things up like negative or 0 value
		return FALSE

	// Timelocks: we need to do these before setting the gamespeed so we can undo potential changes to the original timelock values
	// As in, original Dawn timelock is 12000. If the speed gets changed by 1.25x, it will go down to 9600. We want to change it back to 12000 before applying
	// any new speed.
	var/list/new_timelocks = list()
	for(var/current_timelock in ordeal_timelock)
		var/modified_timelock = ((current_timelock) * (gamespeed.speed_coefficient)) * (1 / new_gamespeed.speed_coefficient)
		new_timelocks.Add(modified_timelock)

	ordeal_timelock = new_timelocks

	// Also set next abno spawn time back to whatever it was.
	SSabnormality_queue.next_abno_spawn_time *= gamespeed.speed_coefficient

	// Now we can set the gamespeed. We don't need the old one anymore.
	gamespeed = new_gamespeed

	// Ordeal time
	SetNextOrdealTime(TRUE)

	// Abno arrival speed
	SSabnormality_queue.next_abno_spawn_time *= (1 / gamespeed.speed_coefficient)

/// Proc that checks to see if there's a Manager in the round. If there isn't, allows any crewmember to start a Core Suppression.
// Important: This is called by ticker.dm with a timer set on roundstart
// Somewhat important: This will also get called after unlocking Extra Cores (post-midnight within time limit)
// Also important: When a Manager joins, core_selection_restriction_lifted gets set to FALSE
/datum/controller/subsystem/lobotomy_corp/proc/LiftCoreSelectionRestriction()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.stat == DEAD)
			continue
		if((H.mind.assigned_role == "Manager"))
			return FALSE

	core_selection_restriction_lifted = TRUE
	priority_announce("Personnel must be advised: As there is no Manager currently active for this shift, Architecture has authorized the lifting of the restrictions pertaining to selection of Core Suppressions. \
						This means any of our employees may begin a Suppression. The restrictions will remain lifted until a Manager for this shift awakens. Our employees are encouraged to Face the Fear, and Build the Future.",\
						"Core Selection Override", 'sound/machines/dun_don_alert.ogg')
	return TRUE
