// Mirae Life Insurance clothing, and the outfits that put it on people.
//
// The company's look is one silhouette in three tempers: the Director in near
// black, the Insurer in the field brown, and Staff in a pale grey-white that
// is deliberately the least armoured-looking of the three, because Staff are
// the ones who are not supposed to be in the fight.
//
// Armour totals are matched to what clean city armour pays at the same
// requirement tier, so none of these is a better deal than what a Thumb or a
// Zwei of equal standing wears. Measured across every
// /obj/item/clothing/suit/armor/ego_gear/city that carries no slowdown:
//
//   tier 100 -> 210 total   (udjat, thumb sottocapo, index messenger, and the
//                            company's own existing insurance jacket)
//   tier  80 -> 130 total   (thumb capo, los mariachis, younger brother)
//   tier  20 ->  20 total   (the L-Corp vest, issued to people who cannot use
//                            E.G.O. at all, which is the Staff case exactly)
//
// None of them take a slowdown, so none of them is buying its armour with one.

/obj/item/clothing/under/suit/lobotomy/mirae_director
	name = "mirae director's suit"
	desc = "A black three-piece cut close, with a silver pin at the lapel. \
		The pin is the only thing on it that catches light."
	icon_state = "mirae_director"

/obj/item/clothing/under/suit/lobotomy/mirae_insurer
	name = "mirae insurer's suit"
	desc = "A brown field suit, hard-wearing and unremarkable. Easy to forget, \
		which is most of the job."
	icon_state = "mirae_insurer"

/obj/item/clothing/under/suit/lobotomy/mirae_staff
	name = "mirae clinic whites"
	desc = "A pale ward uniform. Nothing about it is built to be worn outside."
	icon_state = "mirae_staff"

/obj/item/clothing/suit/armor/ego_gear/city/mirae_director_coat
	name = "mirae director's overcoat"
	desc = "A long black coat, weighted in the hem. The inside pockets are \
		sized for documents rather than for anything useful in a fight."
	icon_state = "mirae_director_coat"
	armor = list(RED_DAMAGE = 50, WHITE_DAMAGE = 80, BLACK_DAMAGE = 50, PALE_DAMAGE = 30)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 100,
							)

/obj/item/clothing/suit/armor/ego_gear/city/mirae_insurer_coat
	name = "mirae insurer's coat"
	desc = "A brown working coat with reinforced forearms. Recovering a body \
		means getting close to whatever made it one."
	icon_state = "mirae_insurer_coat"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 40, BLACK_DAMAGE = 30, PALE_DAMAGE = 20)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80,
							)

/obj/item/clothing/suit/armor/ego_gear/city/mirae_staff_coat
	name = "mirae ward coat"
	desc = "A pale clinic coat. It will keep blood off the uniform underneath \
		and will not do anything else."
	icon_state = "mirae_staff_coat"
	armor = list(RED_DAMAGE = 0, WHITE_DAMAGE = 10, BLACK_DAMAGE = 10, PALE_DAMAGE = 0)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 20,
							PRUDENCE_ATTRIBUTE = 20,
							TEMPERANCE_ATTRIBUTE = 20,
							JUSTICE_ATTRIBUTE = 20,
							)

// Every Mirae role wears the watch and the laceups. The watch is an accessory
// rather than a belt item because none of these three has a belt slot to spare,
// and the company would rather its people carried the client list than chose
// to. The shoes replace the base clinic outfit's white sneakers, which are a
// hospital's shoe on a suit that is not a hospital's.
/datum/outfit/job/city_clinic/miraeclinicdirector
	name = "Mirae Clinic Director"

	accessory = /obj/item/clothing/accessory/mirae_watch
	shoes = /obj/item/clothing/shoes/laceup
	uniform = /obj/item/clothing/under/suit/lobotomy/mirae_director
	suit = /obj/item/clothing/suit/armor/ego_gear/city/mirae_director_coat
	head = null
	l_hand = /obj/item/ego_weapon/city/mirae_cane
	backpack_contents = list(
		/obj/item/storage/firstaid/medical = 1,
		/obj/item/structurecapsule/clinic/mirae = 1,
	)

/datum/outfit/job/city_clinic/staff/mirae
	name = "Mirae Claims Physician"

	accessory = /obj/item/clothing/accessory/mirae_watch
	shoes = /obj/item/clothing/shoes/laceup
	uniform = /obj/item/clothing/under/suit/lobotomy/mirae_staff
	suit = /obj/item/clothing/suit/armor/ego_gear/city/mirae_staff_coat
	head = null

/datum/outfit/job/city_clinic/field/mirae
	name = "Mirae Recovery Agent"

	accessory = /obj/item/clothing/accessory/mirae_watch
	shoes = /obj/item/clothing/shoes/laceup
	uniform = /obj/item/clothing/under/suit/lobotomy/mirae_insurer
	suit = /obj/item/clothing/suit/armor/ego_gear/city/mirae_insurer_coat
	head = null
	l_hand = /obj/item/ego_weapon/city/mirae_case
	backpack_contents = list(/obj/item/pinpointer/crew = 1)


/datum/map_template/shelter/clinic_mirae
	name = "Mirae Clinic"
	shelter_id = "clinic_mirae"
	description = "A Mirae Life Insurance clinic: a policy office at the \
		street door and a ward behind it."
	mappath = "_maps/templates/clinic_office/mirae.dmm"

/obj/item/structurecapsule/clinic
	name = "Clinic Capsule"
	desc = "Use this in a designated clinic plot to raise the building."
	template_id = "clinic_mirae"
	custom_access = list("clinic")
	// The template is 25x20 and the default scan box is 23x13, which covers
	// 299 of its 500 tiles - the outer doors would silently miss their access.
	// GrantDoorAccess() centres the same way the loader does, so matching the
	// numbers matches the footprint exactly.
	access_scan_width = 25
	access_scan_height = 20
	delay_time = 0

/// Refuses anywhere but the plot set aside for it, the way the syndicate
/// capsules do. A clinic dropped in the middle of a street would take the
/// street with it.
/obj/item/structurecapsule/clinic/attack_self()
	var/ready = FALSE
	for(var/obj/effect/landmark/clinicbase/landmark in GLOB.landmarks_list)
		if(get_turf(landmark) == get_turf(src))
			ready = TRUE
			break
	if(!ready)
		loc.visible_message(span_warning("\The [src] will not function here. \
			Take it to the plot the company has been sold."))
		return
	get_template()
	ClearFootprint(get_turf(src))
	..()

/// Demolish whatever is standing on the plot before the clinic lands on it.
///
/// check_deploy() refuses on any closed turf or dense anchored object, so an
/// empty lot that happens to be walled - which is what a plot for sale looks
/// like - can never be built on. The building is going to replace all of this
/// anyway; the only question is whether the Director has to dismantle a
/// perimeter by hand first.
///
/// Scoped to the template's own footprint, taken from the template rather than
/// recomputed, so what gets cleared is exactly what gets built over and the
/// two can never drift apart.
/obj/item/structurecapsule/clinic/proc/ClearFootprint(turf/center)
	if(!template || !center)
		return
	var/cleared = 0
	for(var/turf/T in template.get_affected_turfs(center, TRUE))
		for(var/obj/O in T)
			// Mobs and loose items are left alone. Anything solid and bolted
			// down is what the loader would trip over.
			if(O.density && O.anchored)
				qdel(O)
				cleared++
		if(istype(T, /turf/closed))
			T.ChangeTurf(/turf/open/floor/plating)
			cleared++
	if(cleared)
		visible_message(span_warning("\The [src] shears the plot flat."))
		playsound(src, 'sound/effects/explosionfar.ogg', 60, TRUE)

/obj/item/structurecapsule/clinic/mirae
	name = "Mirae Clinic Capsule"
	desc = "A bluespace capsule in company brown. It holds a policy office, a \
		ward, and the paperwork that connects them."
	icon = 'ModularLobotomy/_Lobotomyicons/mirae.dmi'
	icon_state = "mirae_capsule"
	template_id = "clinic_mirae"
