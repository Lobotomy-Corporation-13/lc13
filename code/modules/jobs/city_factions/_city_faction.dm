// A city faction is a leader job plus every job that names it in `leader`.
// Membership and slot counts live on the job datums; this only owns the
// per-round state. SScity_factions drives it.

/datum/city_faction
	/// Display name, used in the leaderless refusal message.
	var/name = "Faction"
	/// CITY_FACTION_ALWAYS skips the draw, MAJOR and MINOR are drawn for.
	var/category = CITY_FACTION_MAJOR
	/// The job that leads this faction. Members name it in their `leader`.
	var/leader_job
	/// Member job datums, rebuilt by LinkJobs() on every occupation rebuild.
	var/list/datum/job/members = list()
	/// FALSE lets members spawn whether or not the leader slot was taken.
	var/requires_leader = TRUE
	/// Set when the leader slot is actually taken.
	var/leader_filled = FALSE

/// Whether member jobs can be taken right now.
/datum/city_faction/proc/MembersOpen()
	return !requires_leader || leader_filled

/// Finds every job naming this faction's leader, backlinks them and opens their
/// slots. Members start open on purpose - the lobby preference menu hides any
/// job sitting at zero total and spawn positions, and players must be able to
/// pre-select a leader-gated job.
/datum/city_faction/proc/LinkJobs()
	members = list()
	var/datum/job/leader = SSjob.type_occupations[leader_job]
	if(leader)
		leader.city_faction = src
		leader.total_positions = leader.faction_positions
		leader.spawn_positions = leader.faction_positions
	for(var/datum/job/job in SSjob.occupations)
		if(job.leader != leader_job || job.type == leader_job)
			continue
		job.city_faction = src
		members += job
	leader_filled = FALSE
	ApplyMemberSlots()

/// Called once the leader is assigned. Safe to call more than once.
/datum/city_faction/proc/OpenMembers()
	leader_filled = TRUE
	ApplyMemberSlots()

/// Stamps each member's authored slot count back onto its job datum.
/datum/city_faction/proc/ApplyMemberSlots()
	for(var/datum/job/member in members)
		member.total_positions = member.faction_positions
		member.spawn_positions = member.faction_positions

/// Shuts the members. The leader is left alone so it stays latejoinable.
/datum/city_faction/proc/CloseMembers()
	leader_filled = FALSE
	for(var/datum/job/member in members)
		member.total_positions = 0
		member.spawn_positions = 0

/// Shuts the whole faction, leader included, for factions the round did not draw.
/datum/city_faction/proc/CloseFaction()
	CloseMembers()
	var/datum/job/leader = SSjob.type_occupations[leader_job]
	if(!leader)
		return
	leader.total_positions = 0
	leader.spawn_positions = 0
