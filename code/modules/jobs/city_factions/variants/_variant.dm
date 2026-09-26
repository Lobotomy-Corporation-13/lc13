// A faction variant is one flavour a faction can run as. The faction keeps the
// same jobs and the same slots; the variant decides what those jobs are called,
// what they wear, what they can open and who they can talk to.
//
// It is chosen once per round during roundstart assignment, which is early
// enough that every member spawns already dressed. Nothing re-dresses anyone
// afterwards, so nothing here has to be safe to apply to a live mob.

/datum/city_faction_variant
	/// Shown in the roundstart announcement.
	var/name = "Variant"
	/// Alt title on the leader job that selects this variant. The player picks
	/// it in their job preferences, exactly as the Representative picks a
	/// corporation, and SScity_factions reads it when the leader is assigned.
	var/leader_alt_title
	/// Private radio channel every job in the faction is moved onto.
	var/radio_channel_name
	var/radio_channel_color = "#8f4a4b"
	/// Shelter template id this variant's base deploys from. Unused until the
	/// capsules land.
	var/template_id

/datum/city_faction_variant/New()
	. = ..()
	// Registered here rather than from a job, because a job can only declare
	// one channel statically and a faction has one per variant. Allocation
	// only has to beat the first SetJobChannel(), and every variant is built
	// during SScity_factions init, long before anyone equips.
	if(radio_channel_name)
		RegisterJobRadioChannel(radio_channel_name, radio_channel_color)

/// Stamp this variant onto one of the faction's jobs. Called for the leader and
/// every member, and again on every SetupOccupations() rebuild.
///
/// Subtypes override this to set outfit, access and display_title per job. The
/// leader deliberately gets no outfit here: its alt title already resolves one
/// through /datum/job/equip(), and setting both would give the same gear two
/// owners. Its display_title is still worth setting, since a leader who chose
/// no alt title has nothing else to fall back on.
/datum/city_faction_variant/proc/ApplyToJob(datum/job/J)
	if(radio_channel_name)
		J.radio_channel_name = radio_channel_name
	return
