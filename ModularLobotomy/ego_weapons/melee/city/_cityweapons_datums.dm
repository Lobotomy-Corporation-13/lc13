/*
This file holds EGO datums for the City weapons.
If you're wondering |why|, it's so that they can appear in the Test Range.
There are, of course, other ways to do this, but this is the one that integrates the most cleanly with the current systems (IMO)
Incidentally it also serves as a nice repository of City weapons so you can look all of them up in a centralized file. I'll do my best to keep it tidy.

Their costs are a little out of whack compared to regular EGO precisely because they're NOT EGO, they're balanced in quite a different way. For example the Hana weapon has ALEPH statreqs, but
its DPS is somewhere between WAW and ALEPH. In general, all City weapons tend to have significantly higher statreqs than EGO (which makes sense; EGO is meant to be used by Ayin's weakest 9-5 jobbers)
At any rate the cost shouldn't matter for gameplay, it's simply used for sorting.

All of these datums should be disabled in the Well.

Also, this file avoids giving a datum to 'template' types, like /obj/item/ego_weapon/city/dawn, there are quite a few of these that were created for the sake of easier inheritance.
However I don't think players should really get to see those.
*/

// Basic definition

/datum/ego_datum/weapon/city
	well_enabled = FALSE
	origin = "City"

/*
------------------ Associations ------------------
Usually divided into branches ("Zwei South" as opposed to "Zwei West") and organized in sections ("Liu South Section 6" as opposed to "Liu South Section 2").
Lower-number Sections tend to have better Fixers.
Association gear is mostly HE for grunts, low WAW for veterans and high WAW for directors (if you were comparing it to Lobotomy EGO) (I mean this gameplay-wise not lorewise) (This is an observation of mine not a directive).
*/

/* ------------------ 1 - Hana ------------------*/

/// Hana Weapon System
/datum/ego_datum/weapon/city/hana
	item_path = /obj/item/ego_weapon/city/hana
	cost = 90

/* ------------------ 2 - Zwei ------------------*/

// | Zwei South |
//
/// Zwei South Zweihander
/datum/ego_datum/weapon/city/zwei_south
	item_path = /obj/item/ego_weapon/city/zweihander
	cost = 40

/// Zwei South Veteran Zweihander
/datum/ego_datum/weapon/city/zwei_south/vet
	item_path = /obj/item/ego_weapon/city/zweihander/vet
	cost = 60

/// Zwei South Einhander
/datum/ego_datum/weapon/city/zwei_south/knife
	item_path = /obj/item/ego_weapon/city/zweihander/knife
	cost = 25

/// Zwei South Baton
/datum/ego_datum/weapon/city/zwei_south/baton
	item_path = /obj/item/ego_weapon/city/zweibaton
	cost = 40

// | Zwei West |
//
/// Zwei West Greatsword
/datum/ego_datum/weapon/city/zwei_west
	item_path = /obj/item/ego_weapon/city/zweiwest
	cost = 40

/// Zwei West Veteran Greatsword
/datum/ego_datum/weapon/city/zwei_west/vet
	item_path = /obj/item/ego_weapon/city/zweiwest/vet
	cost = 60

/* ------------------ 4 - Shi ------------------*/

/// Shi Knife
/datum/ego_datum/weapon/city/shi_knife
	item_path = /obj/item/ego_weapon/city/shi_knife
	cost = 60

// | Shi South |
//
// Assassin Weapons (Boundary of Death)
/// Shi South Sheathed Blade
/datum/ego_datum/weapon/city/shi_south_assassin
	item_path = /obj/item/ego_weapon/city/shi_assassin
	cost = 60

/// Shi South Sakura Blade
/datum/ego_datum/weapon/city/shi_south_assassin/sakura
	item_path = /obj/item/ego_weapon/city/shi_assassin/sakura

/// Shi South Serpent Blade
/datum/ego_datum/weapon/city/shi_south_assassin/serpent
	item_path = /obj/item/ego_weapon/city/shi_assassin/serpent

/// Shi South Yokai Blade
/datum/ego_datum/weapon/city/shi_south_assassin/yokai
	item_path = /obj/item/ego_weapon/city/shi_assassin/yokai

/// Shi South Veteran Sheathed Blade
/datum/ego_datum/weapon/city/shi_south_assassin/vet
	item_path = /obj/item/ego_weapon/city/shi_assassin/vet
	cost = 75

/// Shi South Director Sheathed Blade
/datum/ego_datum/weapon/city/shi_south_assassin/director
	item_path = /obj/item/ego_weapon/city/shi_assassin/director
	cost = 90

/* ------------------ 5 - Cinq ------------------*/
// This one is a bit weirdly laid out because the type path naming scheme for Cinq is giving me ominous vibes. Sorry

// | Cinq South |
//
/// Cinq Rapier
/datum/ego_datum/weapon/city/cinq
	item_path = /obj/item/ego_weapon/city/cinq
	cost = 50

/// Cinq Section 4 Rapier
/datum/ego_datum/weapon/city/cinq/section4
	item_path = /obj/item/ego_weapon/city/cinq/section4
	cost = 60

/// Cinq Section 5 Director's Rapier
/datum/ego_datum/weapon/city/cinq/section5_director
	item_path = /obj/item/ego_weapon/city/cinq/section5
	cost = 80

/// Cinq Section 4 Director's Rapier
/datum/ego_datum/weapon/city/cinq/section4/director
	item_path = /obj/item/ego_weapon/city/cinq/section4/director
	cost = 85

// | Cinq West |
//
/// Cinq West Rapier
/datum/ego_datum/weapon/city/cinq/west
	item_path = /obj/item/ego_weapon/city/cinq/section4/west

/// Cinq West Selfie Stick
/* This is commented out because there's no purpose to making a datum to it. I'm just filling out the list for the sake of complete documentation.
/datum/ego_datum/weapon/city/cinqwest_selfiestick
	item_path = /obj/item/ego_weapon/city/cinqwest_selfiestick
	cost = 25
	testrange_blacklisted = TRUE // Test Range livestreams are slop and banned by The Eye
*/

/* ------------------ 6 - Liu ------------------*/

// | Liu South |
//
// 'Fire' weapons (damage gain from nearby allies)
/// Liu South S1/2 Blade
/datum/ego_datum/weapon/city/liu_south_fire
	item_path = /obj/item/ego_weapon/city/liu/fire
	cost = 40

/// Liu South S1/2 Glove
/datum/ego_datum/weapon/city/liu_south_fire/fist
	item_path = /obj/item/ego_weapon/city/liu/fire/fist
	cost = 60

/// Liu South S1/2 Spear
/datum/ego_datum/weapon/city/liu_south_fire/spear
	item_path = /obj/item/ego_weapon/city/liu/fire/spear
	cost = 75

/// Liu South S1 Director's Sword
/datum/ego_datum/weapon/city/liu_south_fire/sword
	item_path = /obj/item/ego_weapon/city/liu/fire/sword
	cost = 90

// 'Fist' weapons (combo system)
/// Liu South S4/5/6 Gloves
/datum/ego_datum/weapon/city/liu_south_fist
	item_path = /obj/item/ego_weapon/city/liu/fist
	cost = 40

/// Liu South S4/5/6 Veteran Gloves
/datum/ego_datum/weapon/city/liu_south_fist/vet
	item_path = /obj/item/ego_weapon/city/liu/fist/vet
	cost = 75

/* ------------------ 7 - Seven ------------------*/

// | Seven South |
//
// 'Analysis' weapons (need to hit the same target X amount of times to be able to view their health and gain extra damage against them)
/// Seven South Blade
/datum/ego_datum/weapon/city/seven_south_analysis
	item_path = /obj/item/ego_weapon/city/seven
	cost = 60

/// Seven South Veteran Blade
/datum/ego_datum/weapon/city/seven_south_analysis/vet
	item_path = /obj/item/ego_weapon/city/seven/vet
	cost = 75

/// Seven South Director's Blade
/datum/ego_datum/weapon/city/seven_south_analysis/director_sword
	item_path = /obj/item/ego_weapon/city/seven/director
	cost = 90

/// Seven South Director's Cane
/datum/ego_datum/weapon/city/seven_south_analysis/director_cane
	item_path = /obj/item/ego_weapon/city/seven/cane
	cost = 90

// 'Fencing' weapons (gains the damage bonus from analysis weapons after the first hit, but loses the ability to view their health)
/// Seven South Fencing Foil
/datum/ego_datum/weapon/city/seven_south_fencing
	item_path = /obj/item/ego_weapon/city/seven_fencing
	cost = 60

/// Seven South Veteran Fencing Foil
/datum/ego_datum/weapon/city/seven_south_fencing/vet
	item_path = /obj/item/ego_weapon/city/seven_fencing/vet
	cost = 75

/// Seven South Fencing Dagger
/datum/ego_datum/weapon/city/seven_south_fencing/dagger
	item_path = /obj/item/ego_weapon/city/seven_fencing/dagger
	cost = 90

/* ------------------ 9 - Devyat ------------------*/

// | Devyat North |
//
/// Devyat North Courier Trunk
/datum/ego_datum/weapon/city/devyat_north
	item_path = /obj/item/ego_weapon/city/devyat_trunk
	cost = 40

/// Devyat North Heavy Courier Trunk
/datum/ego_datum/weapon/city/devyat_north/demo
	item_path = /obj/item/ego_weapon/city/devyat_trunk/demo
	cost = 60

/* ------------------ 10 - Dieci ------------------*/

// 'Combo' weapons (similar to Liu combo gloves, can do a very funny 20 hit combo)
/// Dieci Gloves
/datum/ego_datum/weapon/city/dieci_south
	item_path = /obj/item/ego_weapon/city/dieci
	cost = 40

/*
------------------ Fixer Offices & Workshops ------------------
*/

/* ------------------ Cane Office ------------------*/

// All these weapons have a distinct charge mechanic.
/// Cane Office Cane
/datum/ego_datum/weapon/city/cane_office_cane
	item_path = /obj/item/ego_weapon/city/cane/cane
	cost = 75

/// Cane Office Claw
/datum/ego_datum/weapon/city/cane_office_claw
	item_path = /obj/item/ego_weapon/city/cane/claw
	cost = 75

/// Cane Office Gauntlet
/datum/ego_datum/weapon/city/cane_office_fist
	item_path = /obj/item/ego_weapon/city/cane/fist
	cost = 75

/// Cane Office Briefcase
/datum/ego_datum/weapon/city/cane_office_briefcase
	item_path = /obj/item/ego_weapon/city/cane/briefcase
	cost = 75

/* ------------------ Dawn Office ------------------*/

// These weapons cause an AoE after hitting 2 different targets.
/// Dawn Office Sword
/datum/ego_datum/weapon/city/dawn
	item_path = /obj/item/ego_weapon/city/dawn/sword
	cost = 60

/// Dawn Office Cello Case
/datum/ego_datum/weapon/city/dawn/cello
	item_path = /obj/item/ego_weapon/city/dawn/cello
	cost = 60

/// Dawn Office Zweihander
/datum/ego_datum/weapon/city/dawn/zweihander
	item_path = /obj/item/ego_weapon/city/dawn/zwei
	cost = 60

/* ------------------ Echo Office ------------------*/

// Electric Fixer
//
/// Sodom
/datum/ego_datum/weapon/city/echo_office_sodom
	item_path = /obj/item/ego_weapon/city/echo/twins/sodom
	cost = 60
/// Gomorrah
/datum/ego_datum/weapon/city/echo_office_gomorrah
	item_path = /obj/item/ego_weapon/city/echo/twins/gomorrah
	cost = 60

// Metal Fixer
//
/// Eria
/datum/ego_datum/weapon/city/echo_office_eria
	item_path = /obj/item/ego_weapon/shield/eria
	cost = 60
/// Iria
/datum/ego_datum/weapon/city/echo_office_iria
	item_path = /obj/item/ego_weapon/city/echo/iria
	cost = 60

// Flame Fixer
//
/// Sunstrike
/datum/ego_datum/weapon/city/echo_office_sunstrike
	item_path = /obj/item/ego_weapon/city/echo/sunstrike
	cost = 60

/* ------------------ Full-Stop Office ------------------*/

/// Full-Stop Office Pistol
/datum/ego_datum/weapon/city/fullstop
	item_path = /obj/item/ego_weapon/ranged/city/fullstop/pistol
	cost = 40

/// Full-Stop Office Assault Rifle
/datum/ego_datum/weapon/city/fullstop/assault
	item_path = /obj/item/ego_weapon/ranged/city/fullstop/assault
	cost = 40

/// Full-Stop Office Sniper
/datum/ego_datum/weapon/city/fullstop/sniper
	item_path = /obj/item/ego_weapon/ranged/city/fullstop/sniper
	cost = 40

/// Full-Stop Office Magnum
/datum/ego_datum/weapon/city/fullstop/deagle
	item_path = /obj/item/ego_weapon/ranged/city/fullstop/deagle
	cost = 65

/* ------------------ Jeong's Office ------------------*/

/// Jeong's Office Wakizashi
/datum/ego_datum/weapon/city/jeong
	item_path = /obj/item/ego_weapon/city/jeong
	cost = 60

/// Jeong's Office Katana
/datum/ego_datum/weapon/city/jeong
	item_path = /obj/item/ego_weapon/city/jeong
	cost = 75

/* ------------------ Leaflet Workshop ------------------*/

/// Leaflet Round Hammer
/datum/ego_datum/weapon/city/leaflet_round
	item_path = /obj/item/ego_weapon/city/leaflet/round
	cost = 40

/// Leaflet Wide Hammer
/datum/ego_datum/weapon/city/leaflet_wide
	item_path = /obj/item/ego_weapon/city/leaflet/wide
	cost = 40

/// Leaflet Square Hammer
/datum/ego_datum/weapon/city/leaflet_square
	item_path = /obj/item/ego_weapon/city/leaflet/square
	cost = 60
