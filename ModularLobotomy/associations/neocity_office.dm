/obj/item/structurecapsule/major	//index
	name = "Index Capsule"
	desc = "Use this capsule in a designated major hideout area to start your major."
	template_id = "indexfinger_base"
	delay_time = 0

/obj/item/structurecapsule/major/attack_self()
	var/ready
	for(var/obj/effect/landmark/syndicatebase/landmark in GLOB.landmarks_list)
		if((get_turf(landmark)) == (get_turf(src)))
			ready = TRUE
			break
	if(!ready)
		src.loc.visible_message(span_warning("\The [src] will not function in this area. Please move to a designated major hideout space."))
		return
	..()


/obj/item/structurecapsule/major/thumb
	name = "Thumb Capsule"
	template_id = "thumbfinger_base"
	custom_access = list("thumb_south")

/obj/item/structurecapsule/major/middle
	name = "Middle Capsule"
	template_id = "middle_base"
	custom_access = list("middle")

/obj/item/structurecapsule/major/udjat
	name = "Udjat Capsule"
	template_id = "udjat_base"
	custom_access = list("udjat")

/obj/item/structurecapsule/major/liu
	name = "Liu Capsule"
	template_id = "liu_base"
	custom_access = list("liu")

//Office templates
/datum/map_template/shelter/thumb
	name = "Thumb Base"
	shelter_id = "thumbfinger_base"
	description = "A place for the thumb."
	mappath = "_maps/templates/city_factions/major/thumbfinger.dmm"

/datum/map_template/shelter/middle
	name = "Middle Base"
	shelter_id = "middle_base"
	description = "A place for the middle's u-corp branch."
	mappath = "_maps/templates/city_factions/major/middle.dmm"

/datum/map_template/shelter/udjat
	name = "Udjat Base"
	shelter_id = "udjat_base"
	description = "A place for the Udjat"
	mappath = "_maps/templates/city_factions/major/udjat.dmm"

/datum/map_template/shelter/liu
	name = "Liu Base"
	shelter_id = "liu_base"
	description = "A place for the section 6 of liu south"
	mappath = "_maps/templates/city_factions/major/liu.dmm"

//Minor Factions
/obj/item/structurecapsule/fixer/bladelin
	name = "Blade Lineage Base Capsule"
	template_id = "bladelin_office"
	custom_access = list("bladelin")

/obj/item/structurecapsule/fixer/fullstop
	name = "Full Stop Office Capsule"
	template_id = "fullstop_office"
	custom_access = list("fullstop")

/obj/item/structurecapsule/fixer/kuroclan
	name = "Kurokumo Clan Capsule"
	template_id = "kurokumo_office"
	custom_access = list("kuro")

/obj/item/structurecapsule/fixer/dawn
	name = "Dawn Office Capsule"
	template_id = "dawn_office"
	custom_access = list("dawn")

//Minor Templates
/datum/map_template/shelter/bladelin
	name = "Blade Lineage base"
	shelter_id = "bladelin_office"
	description = "A small base capsule for the roaming members of the Blade Lineage"
	mappath = "_maps/templates/city_factions/minor/bladelin.dmm"

/datum/map_template/shelter/fullstop
	name = "Full Stop Office Base"
	shelter_id = "fullstop_office"
	description = "A small capsule containing an outpost for the fixers of Full Stop office."
	mappath = "_maps/templates/city_factions/minor/fullstopfixers.dmm"

/datum/map_template/shelter/kuroclan
	name = "Kurokumo Clan Base"
	shelter_id = "kurokumo_office"
	description = "A small capsule containing an outpost for the members of the kurokumo clan."
	mappath = "_maps/templates/city_factions/minor/kurokumo.dmm"

/datum/map_template/shelter/dawn
	name = "Dawn Office Base"
	shelter_id = "dawn_office"
	description = "A small capsule containing a quiet retreat for the fixers of dawn office."
	mappath = "_maps/templates/city_factions/minor/dawnoffice.dmm"
