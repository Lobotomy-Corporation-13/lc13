// ============================================================
// Path Component — Mob Integration Layer
// ============================================================
// Attaches to a mob to manage their active path. Provides
// clean lifecycle management and helper procs for querying.
// ============================================================

/datum/component/path_holder
	/// The active path datum
	var/datum/path/active_path

/datum/component/path_holder/Initialize(datum/path/new_path)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	active_path = new_path
	active_path.AssignTo(parent)

/datum/component/path_holder/Destroy()
	if(active_path)
		active_path.Remove()
		QDEL_NULL(active_path)
	return ..()

// ============================================================
// Helper Procs on /mob/living/carbon/human
// ============================================================

/// Returns the active /datum/path or null
/mob/living/carbon/human/proc/GetPath()
	var/datum/component/path_holder/holder = GetComponent(/datum/component/path_holder)
	if(!holder)
		return null
	return holder.active_path

/// Returns TRUE if the mob has a path
/mob/living/carbon/human/proc/HasPath()
	return !!GetPath()

/// Creates a path instance and attaches it. Returns FALSE if already has a path.
/mob/living/carbon/human/proc/GrantPath(path_type)
	if(GetPath())
		return FALSE
	var/datum/path/new_path = new path_type()
	AddComponent(/datum/component/path_holder, new_path)
	return TRUE

/// Removes the active path. Returns FALSE if no path.
/mob/living/carbon/human/proc/RemovePath()
	var/datum/component/path_holder/holder = GetComponent(/datum/component/path_holder)
	if(!holder)
		return FALSE
	qdel(holder)
	return TRUE
