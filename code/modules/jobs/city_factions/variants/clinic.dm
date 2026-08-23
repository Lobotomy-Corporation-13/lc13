// The Clinic's two parent companies. Outfits and access are deliberately not
// set yet; this is the plumbing, and the gear lands with each company's own PR.

/datum/city_faction_variant/clinic
	radio_channel_name = "Clinic"
	/// What this company calls the people who work the ward.
	var/staff_title = "Clinic Staff"
	/// What it calls the people it sends out. Both specialisation gimmicks
	/// hang off the field role, so it is the one worth naming hardest.
	var/field_title = "Clinic Field Agent"
	/// Gear for the two sub-roles. The Director is absent on purpose: its
	/// outfit is resolved from the alt title the player picked, inside
	/// /datum/job/equip(), and setting it here as well would give the same
	/// slot two owners that can disagree.
	var/staff_outfit
	var/field_outfit
	/// Stat block per role. A company that arms its people differently should
	/// be allowed to train them differently, and the numbers have to be able
	/// to move with the gear: job_attribute_limit caps training, so a variant
	/// issuing heavier armour than its role can qualify for hands out
	/// something nobody can wear. Null or 0 leaves the job's own value alone.
	var/list/director_attributes
	var/director_limit = 0
	var/list/staff_attributes
	var/staff_limit = 0
	var/list/field_attributes
	var/field_limit = 0

/// Push one role's stat block onto its job, where this variant named one.
/datum/city_faction_variant/clinic/proc/SetStats(datum/job/J, list/attributes, limit)
	if(attributes)
		J.roundstart_attributes = attributes.Copy()
	if(limit)
		J.job_attribute_limit = limit

/datum/city_faction_variant/clinic/ApplyToJob(datum/job/J)
	. = ..()
	// Sub-roles first: both are subtypes of the Director's job, so testing the
	// base type first would swallow them.
	if(istype(J, /datum/job/city_clinic/staff))
		J.display_title = staff_title
		if(staff_outfit)
			J.outfit = staff_outfit
		SetStats(J, staff_attributes, staff_limit)
	else if(istype(J, /datum/job/city_clinic/field))
		J.display_title = field_title
		if(field_outfit)
			J.outfit = field_outfit
		SetStats(J, field_attributes, field_limit)
	else if(istype(J, /datum/job/city_clinic))
		// Normally the Director reads as whatever alt title they picked, and
		// that wins over this. It is here for the Director who picked nothing
		// and had a company chosen for them, who would otherwise be the only
		// person in the building with no company on their ID.
		J.display_title = leader_alt_title
		SetStats(J, director_attributes, director_limit)

/datum/city_faction_variant/clinic/kcorp
	name = "K-Corp"
	leader_alt_title = "K-Corp Clinic Director"
	staff_title = "K-Corp Pharmacist"
	field_title = "K-Corp Field Photographer"
	radio_channel_name = "K-Corp Clinic"
	radio_channel_color = "#4c9a5a"
	template_id = "clinic_kcorp"

/datum/city_faction_variant/clinic/mirae
	name = "Mirae"
	leader_alt_title = "Mirae Clinic Director"
	staff_title = "Mirae Physician"
	field_title = "Mirae Insurer"
	staff_outfit = /datum/outfit/job/city_clinic/staff/mirae
	field_outfit = /datum/outfit/job/city_clinic/field/mirae
	//Stated here rather than left to the job's defaults, even though Mirae is
	//the default variant and the numbers currently agree. A company's stats
	//belong next to the gear they were chosen for, or the next person to
	//retune a coat will not think to look in the job file.
	director_limit = 100
	director_attributes = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 100,
							)
	staff_limit = 40
	staff_attributes = list(
							FORTITUDE_ATTRIBUTE = 40,
							PRUDENCE_ATTRIBUTE = 40,
							TEMPERANCE_ATTRIBUTE = 40,
							JUSTICE_ATTRIBUTE = 40,
							)
	field_limit = 80
	field_attributes = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80,
							)
	radio_channel_name = "Mirae Clinic"
	radio_channel_color = "#6f5b8f"
	template_id = "clinic_mirae"
