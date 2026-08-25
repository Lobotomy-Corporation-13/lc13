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
	/// Variant types this faction can run as. Empty means it has none.
	var/list/variants = list()
	/// Variant used when the leader asked for nothing, or when there is no
	/// leader. Deliberately a named default rather than a random pick: the
	/// jobs advertise this one's titles in the lobby, so rolling a different
	/// one would make the advertisement a lie. Falls back to the first entry
	/// in `variants`.
	var/default_variant
	/// Instances of `variants`, built once at init so their radio channels are
	/// allocated before anyone can equip.
	var/list/datum/city_faction_variant/variant_pool = list()
	/// The variant running this round. Set once, during roundstart assignment.
	var/datum/city_faction_variant/active_variant

/// Whether member jobs can be taken right now.
/datum/city_faction/proc/MembersOpen()
	return !requires_leader || leader_filled

/// Build the variant instances. Separate from choosing one, because every
/// variant's radio channel has to be registered whether or not it is picked.
/datum/city_faction/proc/BuildVariants()
	variant_pool = list()
	for(var/variant_type in variants)
		variant_pool += new variant_type()

/// The variant used when nobody chose one.
/datum/city_faction/proc/DefaultVariant()
	if(!variant_pool.len)
		return null
	if(default_variant)
		for(var/datum/city_faction_variant/V in variant_pool)
			if(V.type == default_variant)
				return V
	return variant_pool[1]

/// The variant a leader's chosen alt title asks for, or null if they set none.
/datum/city_faction/proc/VariantForTitle(chosen)
	if(!chosen)
		return null
	for(var/datum/city_faction_variant/V in variant_pool)
		if(V.leader_alt_title == chosen)
			return V
	return null

/// Commit to a variant for the round and stamp it onto every job.
///
/// The single entry point for the choice. Both the leader's pick and the
/// random fallback come through here, and it refuses to run twice, so a second
/// Director cannot re-roll a clinic that people are already working in.
/datum/city_faction/proc/SetVariant(datum/city_faction_variant/V)
	if(active_variant || !V)
		return FALSE
	active_variant = V
	ApplyVariant()
	return TRUE

/// Push the active variant onto the leader and every member. Safe to repeat;
/// ApplyToJobs() calls it again after each SetupOccupations() rebuild.
/datum/city_faction/proc/ApplyVariant()
	if(!active_variant)
		return
	var/datum/job/leader = SSjob.type_occupations[leader_job]
	if(leader)
		active_variant.ApplyToJob(leader)
	for(var/datum/job/member in members)
		active_variant.ApplyToJob(member)

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
	//SetupOccupations() rebuilds every job datum from scratch, so a variant
	//chosen earlier this round has to be stamped back on.
	ApplyVariant()

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
