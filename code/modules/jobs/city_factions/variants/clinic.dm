// The Clinic's two parent companies. Outfits and access are deliberately not
// set yet; this is the plumbing, and the gear lands with each company's own PR.

/datum/city_faction_variant/clinic
	radio_channel_name = "Clinic"
	/// What this company calls the people who work the ward.
	var/staff_title = "Clinic Staff"
	/// What it calls the people it sends out. Both specialisation gimmicks
	/// hang off the field role, so it is the one worth naming hardest.
	var/field_title = "Clinic Field Agent"

/datum/city_faction_variant/clinic/ApplyToJob(datum/job/J)
	. = ..()
	// Sub-roles first: both are subtypes of the Director's job, so testing the
	// base type first would swallow them.
	if(istype(J, /datum/job/city_clinic/staff))
		J.display_title = staff_title
	else if(istype(J, /datum/job/city_clinic/field))
		J.display_title = field_title
	else if(istype(J, /datum/job/city_clinic))
		// Normally the Director reads as whatever alt title they picked, and
		// that wins over this. It is here for the Director who picked nothing
		// and had a company chosen for them, who would otherwise be the only
		// person in the building with no company on their ID.
		J.display_title = leader_alt_title

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
	staff_title = "Mirae Claims Physician"
	field_title = "Mirae Recovery Agent"
	radio_channel_name = "Mirae Clinic"
	radio_channel_color = "#6f5b8f"
	template_id = "clinic_mirae"
