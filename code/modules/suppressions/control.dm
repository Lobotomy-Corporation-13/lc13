/datum/suppression/control
	name = CONTROL_CORE_SUPPRESSION
	desc = "Assignments on the abnormality work consoles will be scrambled each meltdown/ordeal."
	reward_text = "The facility is rewarded with extra 10 LOB points."
	run_text = "The core suppression of Control department has begun. The work assignments will be scrambled each meltdown."

/datum/suppression/control/Run(run_white = FALSE, silent = FALSE)
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_MELTDOWN_START, PROC_REF(OnMeltdown))
	OnMeltdown()

/datum/suppression/control/End(silent = FALSE)
	UnregisterSignal(SSdcs, COMSIG_GLOB_MELTDOWN_START)
	for(var/obj/machinery/computer/abnormality/C in GLOB.lobotomy_devices)
		C.scramble_list = alist()
	// Reward!
	SSlobotomy_corp.AddLobPoints(10, "[CONTROL_CORE_SUPPRESSION] completion reward")
	// Award achievement for completing Malkuth's core suppression
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.stat != DEAD)
			H.client?.give_award(/datum/award/achievement/lc13/suppress_malkuth, H)
	return ..()

/// Randomizes the works at every meltdown using the Fisher-Yates shuffle (https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle)
/datum/suppression/control/proc/OnMeltdown(datum/source, ordeal = FALSE)
	SIGNAL_HANDLER
	var/alist/final_list = alist()
	var/list/normal_works = list(ABNORMALITY_WORK_INSTINCT, ABNORMALITY_WORK_INSIGHT, ABNORMALITY_WORK_ATTACHMENT, ABNORMALITY_WORK_REPRESSION)
	var/list/swapped_works = normal_works.Copy()
	for(var/i in 1 to 3)
		swapped_works.Swap(i, rand(i + 1, 4))
		final_list[normal_works[i]] = swapped_works[i]

	final_list[normal_works[4]] = swapped_works[4]
	for(var/obj/machinery/computer/abnormality/console in GLOB.lobotomy_devices)
		console.scramble_list = final_list
