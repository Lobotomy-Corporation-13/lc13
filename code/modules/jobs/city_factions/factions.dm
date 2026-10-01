// Members are not listed here. A job joins a faction by setting its `leader`.
// The Clinic is always open, everything else is drawn for at roundstart.

/datum/city_faction/clinic
	name = "the Clinic"
	category = CITY_FACTION_ALWAYS
	leader_job = /datum/job/city_clinic
	requires_leader = TRUE
	variants = list(
		/datum/city_faction_variant/clinic/kcorp,
	)
	default_variant = /datum/city_faction_variant/clinic/kcorp

//Major Factions
/datum/city_faction/thumb_south
	name = "the Thumb South"
	category = CITY_FACTION_MAJOR
	leader_job = /datum/job/sottocapo
	requires_leader = TRUE

/datum/city_faction/middle
	name = "the Middle"
	category = CITY_FACTION_MAJOR
	leader_job = /datum/job/big_brother
	requires_leader = TRUE

/datum/city_faction/udjat
	name = "the Udjat"
	category = CITY_FACTION_MAJOR
	leader_job = /datum/job/captain
	requires_leader = TRUE

/datum/city_faction/liu
	name = "Liu South Section 6"
	category = CITY_FACTION_MAJOR
	leader_job = /datum/job/liudirector
	requires_leader = TRUE

//Minor Factions
/datum/city_faction/bladelin
	name = "the Blade Lineage"
	category = CITY_FACTION_MINOR
	leader_job = /datum/job/cutthroat
	requires_leader = TRUE

/datum/city_faction/fullstop
	name = "the Full Stop Office"
	category = CITY_FACTION_MINOR
	leader_job = /datum/job/fullop
	requires_leader = TRUE

/datum/city_faction/dawn
	name = "the Dawn Office"
	category = CITY_FACTION_MINOR
	leader_job = /datum/job/dawnop
	requires_leader = TRUE

/*

Removed because, for some godforsaken reason, isn't showing up on the latejoin menu.
I have NO fucking clue why.

/datum/city_faction/kuroclan
	name = "the Kurokumo Clan"
	category = CITY_FACTION_MINOR
	leader_job = /datum/job/kcaptain
	requires_leader = TRUE
	*/
