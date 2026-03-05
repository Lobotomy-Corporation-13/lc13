/*
This file holds EGO datums for the City armour.
If you're wondering |why|, it's so that they can appear in the Test Range.
There are, of course, other ways to do this, but this is the one that integrates the most cleanly with the current systems (IMO).

Incidentally it also serves as a nice repository of City armour so you can look all of them up in a centralized file. I'll do my best to keep it tidy.

Their costs are a little out of whack compared to regular EGO precisely because they're NOT EGO, they're balanced in quite a different way.
At any rate the cost shouldn't matter for gameplay, it's simply used for sorting.

All of these datums should be disabled in the Well.
*/

// Basic definition

/datum/ego_datum/armor/city
	well_enabled = FALSE
	origin = "City"

/*
------------------ Associations ------------------
Usually divided into branches ("Zwei South" as opposed to "Zwei West") and organized in sections ("Liu South Section 6" as opposed to "Liu South Section 2").
Lower-number Sections tend to have better Fixers.
Association gear is mostly HE for grunts, low WAW for veterans and high WAW for directors (if you were comparing it to Lobotomy EGO) (I mean this gameplay-wise not lorewise) (This is an observation of mine not a directive).
*/

/* ------------------ 1 - Hana ------------------*/
/// Hana Paperwork Armour
/datum/ego_datum/armor/city/hana
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/hana
	cost = 60
/// Hana Combat Armour
/datum/ego_datum/armor/city/hana/combat
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/hanacombat
	cost = 90
/// Hana Administrative Armour
/datum/ego_datum/armor/city/hana/combat/paperwork
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/hanacombat/paperwork
	cost = 90
/// Hana Director Armour
/datum/ego_datum/armor/city/hana/director
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/hanadirector
	cost = 100

/* ------------------ 2 - Zwei ------------------*/

// | Zwei South |
//
/// Zwei South Armour
/datum/ego_datum/armor/city/zwei_south
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/zwei
	cost = 40
/// Zwei South Casual Jacket
/datum/ego_datum/armor/city/zwei_south/junior
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/zweijunior
	cost = 25
/// Zwei South Riot Armour
/datum/ego_datum/armor/city/zwei_south/riot
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/zweiriot
	cost = 40
/// Zwei South Veteran Armour
/datum/ego_datum/armor/city/zwei_south/vet
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/zweivet
	cost = 60
/// Zwei South Director Armour
/datum/ego_datum/armor/city/zwei_south/director
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/zweileader
	cost = 75

// | Zwei West |
//
/// Zwei West Knight Armour
/datum/ego_datum/armor/city/zwei_west
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/zweiwest
	cost = 40
/// Zwei West Veteran Knight Armour
/datum/ego_datum/armor/city/zwei_west/vet
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/zweiwestvet
	cost = 60
/// Zwei West Knight Director Armour
/datum/ego_datum/armor/city/zwei_west/director
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/zweiwestleader
	cost = 75

/* ------------------ 4 - Shi ------------------*/

// | Shi South |
//
/// Shi South Section 2 Jacket
/datum/ego_datum/armor/city/shi_south
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/shi
	cost = 40
/// Shi South Section 2 Veteran Jacket
/datum/ego_datum/armor/city/shi_south/vet
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/shi/vet
	cost = 60
/// Shi South Section 2 Director Jacket
/datum/ego_datum/armor/city/shi_south/director
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/shi/director
	cost = 75
/// Shi South Section 6 Combat Suit
/datum/ego_datum/armor/city/shi_south/limbus
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/shilimbus
	cost = 40
/// Shi South Section 6 Veteran Combat Suit
/datum/ego_datum/armor/city/shi_south/limbus/vet
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/shilimbus/vet
	cost = 60
/// Shi South Section 6 Director Combat Suit
/datum/ego_datum/armor/city/shi_south/limbus/director
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/shilimbus/director
	cost = 75

/* ------------------ 5 - Cinq ------------------*/

// | Cinq South |
//
/// Cinq South Dueling Gear
/datum/ego_datum/armor/city/cinq_south
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/cinq
	cost = 30

// | Cinq West |
//
/// Cinq West Association Gear
/datum/ego_datum/armor/city/cinq_west
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/cinqwest
	cost = 60

/* ------------------ 6 - Liu ------------------*/

// | Liu South |
/// Liu South S1/2 Combat Suit
/datum/ego_datum/armor/city/liu_south
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/liu
	cost = 40
/// Liu South S5 Combat Jacket
/datum/ego_datum/armor/city/liu_south/section5
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/liu/section5

/// Liu South S1 Veteran Combat Coat
/datum/ego_datum/armor/city/liu_south/vet
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/liuvet
	cost = 60
/// Liu South S2 Veteran Combat Coat
/datum/ego_datum/armor/city/liu_south/vet/section2
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/liuvet/section2
/// Liu South S5 Veteran Jacket
/datum/ego_datum/armor/city/liu_south/vet/section5
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/liuvet/section5
/// Liu South S4 Veteran Jacket
/datum/ego_datum/armor/city/liu_south/vet/section4
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/liuvet/section4

/// Liu South S1 Director Heavy Combat Coat
/datum/ego_datum/armor/city/liu_south/director
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/liuleader
	cost = 75
/// Liu South S1 Director Heavy Combat Coat
/datum/ego_datum/armor/city/liu_south/director/section5
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/liuleader/section5


/* ------------------ 7 - Seven ------------------*/

// | Seven South |
/// Seven South Armour
/datum/ego_datum/armor/city/seven_south
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/seven
	cost = 40
/// Seven South Recon Armour
/datum/ego_datum/armor/city/seven_south/recon
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/sevenrecon
/// Seven South Veteran Armour
/datum/ego_datum/armor/city/seven_south/vet
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/sevenvet
	cost = 60
/// Seven South Intel Armour
/datum/ego_datum/armor/city/seven_south/vet/intel
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/sevenvet/intel
/// Seven South Director Armour
/datum/ego_datum/armor/city/seven_south/director
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/sevendirector
	cost = 75

/* ------------------ 9 - Devyat ------------------*/
// | Devyat North |
/// Devyat North Coat
/datum/ego_datum/armor/city/devyat_north
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/devyat_suit
	cost = 60
/// Devyat North Intern Coat
/datum/ego_datum/armor/city/devyat_north/weak
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/devyat_suit/weak
	cost = 40

/* ------------------ 10 - Dieci ------------------*/

/// Dieci Veteran Gear
/datum/ego_datum/armor/city/dieci
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/dieci
	cost = 60

/*
------------------ Fixers & Workshops ------------------
*/

/* ------------------ Miscellaneous Fixer ------------------*/

/// Fixer Suit
/datum/ego_datum/armor/city/fixer
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/misc
	cost = 25
/// Fixer Black Suit
/datum/ego_datum/armor/city/fixer/second
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/misc/second
/// Fixer Plate Armour
/datum/ego_datum/armor/city/fixer/third
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/misc/third
/// Fixer Kimono
/datum/ego_datum/armor/city/fixer/fourth
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/misc/fourth
/// Fixer Long Jacket
/datum/ego_datum/armor/city/fixer/fifth
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/misc/fifth
/// Fixer Armoured Turtleneck
/datum/ego_datum/armor/city/fixer/sixth
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/misc/sixth
/// Fixer Armoured Jacket
/datum/ego_datum/armor/city/fixer/lone
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/misc/lone

/* ------------------ Full-Stop Office ------------------*/

/// Full Stop Bomber Jacket
/datum/ego_datum/armor/city/fullstop
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/fullstop
	cost = 40
/// Full Stop Sniper Jacket
/datum/ego_datum/armor/city/fullstop/sniper
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/fullstop/sniper
/// Full Stop Director Combat Jacket
/datum/ego_datum/armor/city/fullstop/leader
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/fullstopleader
	cost = 60

/* ------------------ Dawn Office ------------------*/

/// Dawn Office Jacket
/datum/ego_datum/armor/city/dawn
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/dawn
	cost = 40
/// Dawn Office Dress
/datum/ego_datum/armor/city/dawn/female
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/dawn/female
/// Dawn Office Veteran Attire
/datum/ego_datum/armor/city/dawn/vet
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/dawn/vet
/// Dawn Office Leader Jacket
/datum/ego_datum/armor/city/dawn/leader
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/dawnleader
	cost = 60

/* ------------------ Molar Office ------------------*/

/// Molar Boatworks Jacket
/datum/ego_datum/armor/city/molar
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/molar/boatworks
	cost = 40
/// Molar Boatworks Director Wetsuit
/datum/ego_datum/armor/city/molar/director
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/molar/director/boatworks
	cost = 60

/* ------------------ Echo Office ------------------*/

/// Neon Maid Dress
/datum/ego_datum/armor/city/echo_office_maid
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/echo/maid_dress
	cost = 75
/// Reverie Under The Stars
/datum/ego_datum/armor/city/echo_office_stars
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/echo/stars
	cost = 75
/// Plated Outer Cover
/datum/ego_datum/armor/city/echo_office_plated
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/echo/plated
	cost = 75
/// Frilled Maid Outfit/Faux Fur Coat
/datum/ego_datum/armor/city/echo_office_faux
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/echo/faux
	cost = 75

/* ------------------ Wedge Office ------------------*/

/// Wedge Office Jacket
/datum/ego_datum/armor/city/wedge
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/wedge
	cost = 40
/// Wedge Office Dress
/datum/ego_datum/armor/city/wedge/female
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/wedge/female
/// Wedge Office Leader Jacket
/datum/ego_datum/armor/city/wedge/leader
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/wedgeleader
	cost = 60

/* ------------------ Fanghunt Office ------------------*/

/// Fanghunt Office Jacket
/datum/ego_datum/armor/city/fanghunt
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/fanghunt
	cost = 40

/* ------------------ Rosespanner Workshop ------------------*/

/// Rosespanner Fixer Jacket
/datum/ego_datum/armor/city/rosespanner
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/rosespanner
	cost = 40
/// Rosespanner Assassin Jacket
/datum/ego_datum/armor/city/rosespanner/assassin
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/rosespanner/assassin
/// Rosespanner Representative Jacket
/datum/ego_datum/armor/city/rosespanner/rep
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/rosespannerrep
	cost = 60

/* ------------------ The Pequod ------------------*/
// I consider them as more of an Office than part of the U Corp Wing...? Maybe?

/// Pequod Captain's Uniform
/datum/ego_datum/armor/city/pequod_captain
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/pequod_captain
	cost = 35
	testrange_blacklisted = TRUE // I think its sprite is bugged?

/* ------------------ The Udjat ------------------*/
// They're a Grade 1 Fixer Office, allegedly
// You can move them elsewhere once we have The Rest Of The Sprites

/// Udjat Combat Suit
/datum/ego_datum/armor/city/udjat
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/udjat
	cost = 90

/* ------------------ Colour Fixers ------------------*/

/// Jacket of Blue (Blue Reverberation)
/datum/ego_datum/armor/city/reverberation
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/blue_reverb
	cost = 120

/*
------------------ Wings and other Corporations ------------------
*/

/* ------------------ J Corp ------------------*/
// I'm gonna be honest none of this is actual J Corp stuff it's J Corp Syndicates, but they're in the JCorp file... oh well

// | Ting-Tang Gang |
//
/// Red Ting Tang Shirt (There are a blue and yellow variant but they have the same icon state...???? So I'm not including them)
/datum/ego_datum/armor/city/ting_tang
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/ting_tang
	cost = 25
/// Ting Tang Boss Shirt
/datum/ego_datum/armor/city/ting_tang/boss
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/ting_tang/boss
	cost = 40

// | Los Mariachis |
//
/// Los Mariachis Poncho
/datum/ego_datum/armor/city/mariachi
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/mariachi
	cost = 25
/// Los Mariachis Armour (Aida)
/datum/ego_datum/armor/city/mariachi/aida
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/mariachi/aida
	cost = 40
/// Los Mariachis Armour (Aida - Boss) (I wish they named it something it different)
/datum/ego_datum/armor/city/mariachi/aida/boss
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/mariachi/aida/boss
	cost = 60

/* ------------------ K Corp ------------------*/

/// K-Corp L1 Armour
/datum/ego_datum/armor/city/kcorp
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/kcorp_l1
	cost = 40
/// K-Corp L3 Armour
/datum/ego_datum/armor/city/kcorp/l3
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/kcorp_l3
	cost = 60
/// K-Corp Scientist Uniform
/datum/ego_datum/armor/city/kcorp/sci
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/kcorp_sci
	cost = 10

/* ------------------ L Corp ------------------*/

/* Okay so they have a bunch of non EGO armour but I don't consider it city armour and I don't think they need datums.
Feel free to add it I guess??? It shouldn't break anything??? I just don't see the point but go ahead if you want yknow
*/

/* ------------------ N Corp ------------------*/

/// Nagel und Hammer Armour
/datum/ego_datum/armor/city/ncorp_inquisition
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/ncorp
	cost = 60
/// Nagel und Hammer Decorated Armour
/datum/ego_datum/armor/city/ncorp_inquisition/vet
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/ncorp/vet
	cost = 65
/// Nagel und Hammer Grosshammer Armour
/datum/ego_datum/armor/city/ncorp_inquisition/gross
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/grosshammmer
	cost = 100
/// Rüstung der auserwählten Frau Gottes ("Armour of the Chosen Woman of God" according to google translate)
/datum/ego_datum/armor/city/ncorp_inquisition/leader
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/ncorpcommander
	cost = 105

/* ------------------ R Corp ------------------*/
/*
R Corp has an absolute ton of armours that are statistically identical, and aren't actually City armours. They don't have any statreqs either.
I'm gonna make the call not to put them here but feel free to override me and place them here if you want.
*/

/* ------------------ W Corp ------------------*/

/// W-Corp Armour Vest
/datum/ego_datum/armor/city/wcorp
	item_path = /obj/item/clothing/suit/armor/ego_gear/wcorp
	cost = 35

/* ------------------ Mirae Life Insurance ------------------*/

/// Mirae Life Insurance Jacket
/datum/ego_datum/armor/city/mirae
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/mirae
	cost = 90

/* ------------------ Limbus Company ------------------*/
// | LCA |
// Put the vanguard and recon goobers here once we get sprites

// | LCB (Limbus Company Bus) |
//
/// What is Cast - Rodion
/datum/ego_datum/armor/city/lcb_cast
	item_path = /obj/item/clothing/suit/armor/ego_gear/limbus/ego/cast
	cost = 40
/// Branch of Knowledge - Sinclair
/datum/ego_datum/armor/city/lcb_branch
	item_path = /obj/item/clothing/suit/armor/ego_gear/limbus/ego/branch
	cost = 40
/// To Pathos Mathos - Outis
/datum/ego_datum/armor/city/lcb_minos // What exactly does 'minos' mean? I don't know...
	item_path = /obj/item/clothing/suit/armor/ego_gear/limbus/ego/minos
	cost = 40

// | LCC (Limbus Company Clearing) |
// These guys have a ton of identical non-City non-EGO gear... I think it's safe to omit them? Feel free to add them regardless

/*
------------------ Syndicates ------------------
Evilpeople organizations and smaller groups of people, including lesser ones, rats and the Finger Syndicates.
*/

/* ------------------ The Thumb ------------------*/

// | Thumb South |
//
/// Thumb South Soldato Armour
/datum/ego_datum/armor/city/thumb_south
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/thumb
	cost = 40
/// Thumb South Capo Armour
/datum/ego_datum/armor/city/thumb_south/capo
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/thumb_capo
	cost = 60
/// Thumb South Sottocapo Armour
/datum/ego_datum/armor/city/thumb_south/sottocapo
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/thumb_sottocapo
	cost = 75

// | Thumb East |
//
/// Thumb East Soldato Armour
/datum/ego_datum/armor/city/thumb_east
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/thumb_east
	cost = 60
/// Thumb East Capo Armour
/datum/ego_datum/armor/city/thumb_east/capo
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/thumb_east/capo
	cost = 75

// | Subsidiary: Kurokumo Clan |
//
/// Kurokumo Wakashu Dress Jacket
/datum/ego_datum/armor/city/kurokumo
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/kurokumo
	cost = 40
/// Kurokumo Enforcer Dress Shirt
/datum/ego_datum/armor/city/kurokumo/enforcer
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/kurokumo/jacket
	cost = 60
/// Kurokumo Captain Kimono
/datum/ego_datum/armor/city/kurokumo/captain
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/kurokumo/captain
	cost = 65

/* ------------------ The Index ------------------*/

/// Index Proselyte Armour
/datum/ego_datum/armor/city/index
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/index
	cost = 40
/// Index Proxy Armour
/datum/ego_datum/armor/city/index/proxy
	item_path = /obj/item/clothing/suit/armor/ego_gear/index_proxy
	cost = 60
/// Index Messenger Armour
/datum/ego_datum/armor/city/index/messenger
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/index_mess
	cost = 90

/* ------------------ The Middle ------------------*/

/// Middle Little Brother Hawaii Shirt
/datum/ego_datum/armor/city/middle
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/middle
	cost = 40
/// Middle Little Sister Hawaii Shirt
/datum/ego_datum/armor/city/middle/little_sister
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/middle/little_sister
/// Middle Little Sibling Tank Top
/datum/ego_datum/armor/city/middle/tank_top
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/middle/tank_top
/// Middle Younger Brother Coat
/datum/ego_datum/armor/city/middle/younger
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/middle_younger
	cost = 60
/// Middle Younger Sister Coat
/datum/ego_datum/armor/city/middle/younger/younger_sister
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/middle_younger/younger_sister
// Warning: these two come with an ability.
/// Middle Big Brother Gear
/datum/ego_datum/armor/city/middle/big
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/middle_big
	cost = 90
	ego_tags = list(EGO_TAG_AOE_RADIAL, EGO_TAG_MOBILITY, EGO_TAG_HAZARDOUS)
/// Middle Big Sister Gear
/datum/ego_datum/armor/city/middle/big/big_sister
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/middle_big/big_sister

/* ------------------ The Ring ------------------*/
/*
????????
(We have no Ring armour sprites)
*/

/* ------------------ The Pinky ------------------*/
/*
????????
I'm gonna be real I don't even know if we should add these
*/

/* ------------------ Blade Lineage ------------------*/
// If they ever lock in and take back their home, feel free to move them to the Wings section under S-Corp

// These robes give you different degrees of death defiance when YMF-ing with the BL swords.
/// Blade Lineage Salsu Robe
/datum/ego_datum/armor/city/blade_lineage
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/blade_lineage_salsu
	cost = 35
/// Blade Lineage Cutthroat Robe
/datum/ego_datum/armor/city/blade_lineage/cutthroat
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/blade_lineage_cutthroat
	cost = 45
/// Blade Lineage Admin Robe
/datum/ego_datum/armor/city/blade_lineage/admin
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/blade_lineage_admin
	cost = 90

/* ------------------ Carnival ------------------*/

/// Carnival Robe
/datum/ego_datum/armor/city/carnival
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/carnival_robes
	cost = 60

// | Woven Armours |
//
/// Sweeper Suit
/datum/ego_datum/armor/city/carnival/woven_sweeper
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/indigo_armor
	cost = 25
/// Doubting Suit
/datum/ego_datum/armor/city/carnival/woven_green
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/green_armor
	cost = 25
/// Hunger Suit
/datum/ego_datum/armor/city/carnival/woven_amber
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/amber_armor
	cost = 25
/// Soldier's Uniform
/datum/ego_datum/armor/city/carnival/woven_steel
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/steel_armor
	cost = 25
/// Reforged Suit
/datum/ego_datum/armor/city/carnival/woven_azure
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/azure_armor
	cost = 25

/* ------------------ Bloodfiends ------------------*/
// Okay I know they're not a Syndicate but they're red-coloured, you know who else is red? The SS13 Syndicate, so here they are

/// Masquerade Cloak
/datum/ego_datum/armor/city/bloodfiend
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/masquerade_cloak
	cost = 40
	ego_tags = list(EGO_TAG_BLOODFEAST, EGO_TAG_SUSTAIN)
/// Masquerade Coat
/datum/ego_datum/armor/city/bloodfiend/coat
	item_path = /obj/item/clothing/suit/armor/ego_gear/city/masquerade_cloak/masquerade_coat
	cost = 25
