// Tiansha Star's Bladewound \u5929\u6BBA\u661F\u50B7 - permanent component on a carbon scarred by Arayashiki \u963F\u983C\u8036\u8B58.
// If they ever receive a replacement bodypart and walk within 3 tiles of any Arayashiki or its
// wielder, the wound reopens - each step deals 5 BRUTE.

/datum/component/tiansha_bladewound
	dupe_mode = COMPONENT_DUPE_HIGHLANDER
	can_transfer = FALSE
	/// List of body_zones present at the time of attachment; used to detect a "new" limb later.
	var/list/baseline_zones = list()
	/// Latches TRUE the first time a non-baseline limb is attached.
	var/regrew = FALSE
	/// Range in tiles for the Arayashiki / wielder proximity check.
	var/proximity = 3

/datum/component/tiansha_bladewound/Initialize()
	if(!iscarbon(parent))
		return COMPONENT_INCOMPATIBLE
	var/mob/living/carbon/C = parent
	for(var/obj/item/bodypart/BP in C.bodyparts)
		baseline_zones += BP.body_zone
	RegisterSignal(C, COMSIG_CARBON_ATTACH_LIMB, PROC_REF(OnLimbAttach))
	RegisterSignal(C, COMSIG_MOVABLE_MOVED, PROC_REF(OnMove))
	to_chat(C, span_userdanger("A faint scar of starlight closes the wound. Something has been taken. \u5929\u6BBA\u661F\u50B7"))

/datum/component/tiansha_bladewound/Destroy()
	if(parent)
		UnregisterSignal(parent, list(COMSIG_CARBON_ATTACH_LIMB, COMSIG_MOVABLE_MOVED))
	return ..()

/datum/component/tiansha_bladewound/proc/OnLimbAttach(datum/source, obj/item/bodypart/BP, special)
	SIGNAL_HANDLER
	if(!istype(BP))
		return
	if(!(BP.body_zone in baseline_zones))
		regrew = TRUE

/datum/component/tiansha_bladewound/proc/OnMove(datum/source, atom/OldLoc, Dir, Forced)
	SIGNAL_HANDLER
	if(!regrew)
		return
	if(!iscarbon(parent))
		return
	var/mob/living/carbon/C = parent
	if(C.stat == DEAD)
		return
	for(var/obj/item/ego_weapon/city/arayashiki/A in GLOB.arayashiki_blades)
		if(QDELETED(A))
			continue
		var/in_range = (get_dist(C, A) <= proximity)
		if(!in_range && A.current_wielder && !QDELETED(A.current_wielder))
			in_range = (get_dist(C, A.current_wielder) <= proximity)
		if(!in_range)
			continue
		C.adjustBruteLoss(5, updating_health = TRUE)
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(C), Dir)
		to_chat(C, span_danger("The wound reopens! \u5929\u6BBA\u661F\u50B7"))
		break
