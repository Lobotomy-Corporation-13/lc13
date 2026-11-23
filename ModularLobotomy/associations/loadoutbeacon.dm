/obj/item/loadout_beacon
	name = "Loadout Beacon"
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-blue"
	inhand_icon_state = "radio"
	var/datum/loadout/option_a
	var/datum/loadout/option_b
	var/list/available_loadouts = list()
	var/list/rare_loadouts = list()

/obj/item/loadout_beacon/attack_self(mob/living/carbon/human/user)
	..()

	//I have to pick, then make a new datum. using new pick() makes the compiler scream at me.
	var/select_a = pick_n_take(available_loadouts)
	var/select_b = pick_n_take(available_loadouts)
	if(prob(50))
		select_b = pick(rare_loadouts)

	option_a = new select_a
	option_b = new select_b

	//Finding this proc took me way too long
	var/selection = alert("Which Loadout Would you Like?",,"[option_a.name]","[option_b.name]")

	if(selection == option_b.name)
		SpawnShit(option_b, user)

	else	//Fuck you if you try to reroll, you get the common option.
		SpawnShit(option_a, user)

	qdel(option_a)
	qdel(option_b)
	qdel(src)

/obj/item/loadout_beacon/proc/SpawnShit(datum/loadout/option, mob/living/carbon/human/user)
	if(option.weapon)
		new option.weapon (get_turf(user))
	if(option.armor)
		new option.armor (get_turf(user))
	if(option.extra)
		new option.extra (get_turf(user))


/*This is just for posterity.
//This is just for posterity.
/obj/item/loadout_beacon/zwei
	name = "Zwei Loadout Beacon"
	available_loadouts = list(
				/datum/loadout/zwei/zweihander,
				/datum/loadout/zwei/einhander,
				/datum/loadout/zwei/zweibaton,
				/datum/loadout/zwei/zweihanderriot,
				/datum/loadout/zwei/zweibatonriot,
				)

	rare_loadouts = list(
				/datum/loadout/zwei/einhanderrare,
				/datum/loadout/zwei/zweiwest,
				)

/obj/item/loadout_beacon/zweivet
	name = "Zwei Veteran Loadout Beacon"
	available_loadouts = list(
		/datum/loadout/zweivet/zweihander,
		/datum/loadout/zweivet/zweizweihander
	)
	rare_loadouts = list(
		/datum/loadout/zweivet/zweiwest,
	)
*/
/datum/loadout
	var/name = "Generic Loadout"
	var/helmet

/datum/loadout
	var/name = "Generic Loadout"
	var/weapon
	var/armor
	var/extra


/*Zwei Loadouts
//Zwei Loadouts
/datum/loadout/zwei/zweihander
	name = "Zwei South Zweihander"
	weapon = /obj/item/ego_weapon/city/zweihander
	armor = /obj/item/clothing/suit/armor/ego_gear/city/zwei

/datum/loadout/zwei/einhander
	name = "Zwei South Einhander"
	weapon = /obj/item/ego_weapon/city/zweihander/knife
	armor = /obj/item/clothing/suit/armor/ego_gear/city/zwei

/datum/loadout/zwei/einhanderrare
	name = "Zwei West Einhander"
	weapon = /obj/item/ego_weapon/city/zweihander/knife
	armor = /obj/item/clothing/suit/armor/ego_gear/city/zweiwest

/datum/loadout/zwei/zweibaton
	name = "Zwei South Baton"
	weapon = /obj/item/ego_weapon/city/zweibaton
	armor = /obj/item/clothing/suit/armor/ego_gear/city/zwei

/datum/loadout/zwei/zweiwest
	name = "Zwei West Greatsword"
	weapon = /obj/item/ego_weapon/city/zweiwest
	armor = /obj/item/clothing/suit/armor/ego_gear/city/zweiwest

/datum/loadout/zwei/zweihanderriot
	name = "Zwei Riot Zweihander"
	weapon = /obj/item/ego_weapon/city/zweihander
	armor = /obj/item/clothing/suit/armor/ego_gear/city/zweiriot

/datum/loadout/zwei/zweibatonriot
	name = "Zwei Riot Baton"
	weapon = /obj/item/ego_weapon/city/zweibaton
	armor = /obj/item/clothing/suit/armor/ego_gear/city/zweiriot

/datum/loadout/zweivet/zweihander
	name = "Zwei South Veteran Zweihander"
	weapon = /obj/item/ego_weapon/city/zweihander/vet
	armor = /obj/item/clothing/suit/armor/ego_gear/city/zweivet

/datum/loadout/zweivet/zweiwest
	name = "Zwei West Veteran Greatsword"
	weapon = /obj/item/ego_weapon/city/zweiwest/vet
	armor = /obj/item/clothing/suit/armor/ego_gear/city/zweiwestvet

/datum/loadout/zweivet/zweizweihander
	name = "Zwei South Veteran Zweihanders"
	weapon = /obj/item/ego_weapon/city/zweihander/vet
	armor = /obj/item/clothing/suit/armor/ego_gear/city/zweivet
	extra = /obj/item/ego_weapon/city/zweihander/vet

*/

