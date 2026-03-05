/*
This file holds EGO datums for the City weapons.
If you're wondering |why|, it's so that they can appear in the Test Range.
There are, of course, other ways to do this, but this is the one that integrates the most cleanly with the current systems (IMO).
If you tried to use some automated logic to create datums for city weapons it could lead to some undesirable outcomes. I think having to fill them out manually basically makes this into a big
"whitelist" file, which ensures each weapon is vetted by someone before it gets a datum.

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
	ego_tags = list(EGO_TAG_REACH)

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
	testrange_blacklisted = TRUE // Has a serverwide suicide announcement
	ego_tags = list(EGO_TAG_HAZARDOUS)

// | Shi South |
//
// Assassin Weapons (Boundary of Death)
/// Shi South Sheathed Blade
/datum/ego_datum/weapon/city/shi_south_assassin
	item_path = /obj/item/ego_weapon/city/shi_assassin
	cost = 60
	ego_tags = list(EGO_TAG_HAZARDOUS, EGO_TAG_VERSATILE_DAMAGE)
/// Shi South Sakura Blade
/datum/ego_datum/weapon/city/shi_south_assassin/sakura
	item_path = /obj/item/ego_weapon/city/shi_assassin/sakura
/// Shi South Serpent Blade
/datum/ego_datum/weapon/city/shi_south_assassin/serpent
	item_path = /obj/item/ego_weapon/city/shi_assassin/serpent
/// Shi South Yokai Blade
/datum/ego_datum/weapon/city/shi_south_assassin/yokai
	item_path = /obj/item/ego_weapon/city/shi_assassin/yokai
	ego_tags = list(EGO_TAG_HAZARDOUS)
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
	ego_tags = list(EGO_TAG_MOBILITY, EGO_TAG_REACH)
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
	testrange_blacklisted = TRUE // Spawns a selfie stick when created, we don't want that
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
	ego_tags = list(EGO_TAG_COMBO, EGO_TAG_AOE_RADIAL, EGO_TAG_KNOCKBACK)
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
// 'Courier Trunks' empower themselves as the fight goes on, but eventually start damaging their user. They also double as backpacks.
/// Devyat North Courier Trunk
/datum/ego_datum/weapon/city/devyat_north
	item_path = /obj/item/ego_weapon/city/devyat_trunk
	cost = 40
	ego_tags = list(EGO_TAG_HAZARDOUS)
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
	testrange_blacklisted = TRUE // This thing doesn't runtime or anything but the LLLH bug is still there and I don't think anyone should ever get to see or use this weapon while that bug exists
	ego_tags = list(EGO_TAG_COMBO)
/*
------------------ Fixers & Workshops ------------------
*/

/* ------------------ Miscellaneous Fixer ------------------*/

/// Fixer Blade
/datum/ego_datum/weapon/city/fixer
	item_path = /obj/item/ego_weapon/city/fixerblade
	cost = 20
/// Fixer Greatsword
/datum/ego_datum/weapon/city/fixer/greatsword
	item_path = /obj/item/ego_weapon/city/fixergreatsword
/// Fixer Hammer
/datum/ego_datum/weapon/city/fixer/hammer
	item_path = /obj/item/ego_weapon/city/fixerhammer
/// Fixer Pen
/datum/ego_datum/weapon/city/fixer/pen
	item_path = /obj/item/ego_weapon/city/fixerpen

/* ------------------ Yun's Office ------------------*/

/// Yun Office Baton
/datum/ego_datum/weapon/city/yun
	item_path = /obj/item/ego_weapon/city/yun
	cost = 15
/// Yun Office Shortsword
/datum/ego_datum/weapon/city/yun/shortsword
	item_path = /obj/item/ego_weapon/city/yun/shortsword
	cost = 20
/// Yun Office Chainsword
/datum/ego_datum/weapon/city/yun/chainsaw
	item_path = /obj/item/ego_weapon/city/yun/chainsaw
	cost = 20
/// Yun Office Gloves
/datum/ego_datum/weapon/city/yun/gloves
	item_path = /obj/item/ego_weapon/city/yun/fist
	cost = 35

/* ------------------ Streetlight Office ------------------*/

/// Streetlight Greatsword
/datum/ego_datum/weapon/city/streetlight
	item_path = /obj/item/ego_weapon/city/streetlight_greatsword
	cost = 20
/// Streetlight Bat
/datum/ego_datum/weapon/city/streetlight/bat
	item_path = /obj/item/ego_weapon/city/streetlight_bat
	cost = 25
/// Streetlight Baton
/datum/ego_datum/weapon/city/streetlight/baton
	item_path = /obj/item/ego_weapon/city/zweihander/streetlight_baton
	cost = 35

/* ------------------ Full-Stop Office ------------------*/

/// Full-Stop Office Pistol
/datum/ego_datum/weapon/city/fullstop
	item_path = /obj/item/ego_weapon/ranged/city/fullstop/pistol
	cost = 35
/// Full-Stop Office Assault Rifle
/datum/ego_datum/weapon/city/fullstop/assault
	item_path = /obj/item/ego_weapon/ranged/city/fullstop/assault
/// Full-Stop Office Sniper
/datum/ego_datum/weapon/city/fullstop/sniper
	item_path = /obj/item/ego_weapon/ranged/city/fullstop/sniper
/// Full-Stop Office Magnum
/datum/ego_datum/weapon/city/fullstop/deagle
	item_path = /obj/item/ego_weapon/ranged/city/fullstop/deagle
	cost = 65

/* ------------------ Dawn Office ------------------*/

// These weapons cause an AoE after hitting 2 different targets.
/// Dawn Office Sword
/datum/ego_datum/weapon/city/dawn
	item_path = /obj/item/ego_weapon/city/dawn/sword
	cost = 60
	ego_tags = list(EGO_TAG_AOE_RADIAL)
/// Dawn Office Cello Case
/datum/ego_datum/weapon/city/dawn/cello
	item_path = /obj/item/ego_weapon/city/dawn/cello
	cost = 60
/// Dawn Office Zweihander
/datum/ego_datum/weapon/city/dawn/zweihander
	item_path = /obj/item/ego_weapon/city/dawn/zwei
	cost = 60


/* ------------------ Molar Office ------------------*/

// These weapons restore sanity on kill.
/// Molar Chainsword
/datum/ego_datum/weapon/city/molar
	item_path = /obj/item/ego_weapon/city/molar
	cost = 60
	ego_tags = list(EGO_TAG_SUSTAIN)
/// Molar Chainknife
/datum/ego_datum/weapon/city/molar/olga
	item_path = /obj/item/ego_weapon/city/molar/olga
	cost = 75

/* ------------------ Echo Office ------------------*/

// Electric Fixer
//
/// Sodom
/datum/ego_datum/weapon/city/echo_office_sodom
	item_path = /obj/item/ego_weapon/city/echo/twins/sodom
	cost = 60
	ego_tags = list(EGO_TAG_DEBUFFER, EGO_TAG_MULTIHIT, EGO_TAG_LOCKED_POTENTIAL)
/// Gomorrah
/datum/ego_datum/weapon/city/echo_office_gomorrah
	item_path = /obj/item/ego_weapon/city/echo/twins/gomorrah
	cost = 60
	ego_tags = list(EGO_TAG_DEBUFFER, EGO_TAG_MULTIHIT, EGO_TAG_LOCKED_POTENTIAL)

// Metal Fixer
//
/// Eria
/datum/ego_datum/weapon/city/echo_office_eria
	item_path = /obj/item/ego_weapon/shield/eria
	cost = 60
	ego_tags = list(EGO_TAG_SUSTAIN)
/// Iria
/datum/ego_datum/weapon/city/echo_office_iria
	item_path = /obj/item/ego_weapon/city/echo/iria
	cost = 60
	ego_tags = list(EGO_TAG_KNOCKBACK, EGO_TAG_LOCKED_POTENTIAL, EGO_TAG_SUSTAIN)

// Flame Fixer
//
/// Sunstrike
/datum/ego_datum/weapon/city/echo_office_sunstrike
	item_path = /obj/item/ego_weapon/city/echo/sunstrike
	cost = 60
	ego_tags = list(EGO_TAG_DOT)

/* ------------------ Jeong's Office ------------------*/

/// Jeong's Office Wakizashi
/datum/ego_datum/weapon/city/jeong
	item_path = /obj/item/ego_weapon/city/jeong
	cost = 60
/// Jeong's Office Katana
/datum/ego_datum/weapon/city/jeong/large
	item_path = /obj/item/ego_weapon/city/jeong/large
	cost = 75

/* ------------------ Wedge Office ------------------*/

/// Wedge Spear
/datum/ego_datum/weapon/city/wedge
	item_path = /obj/item/ego_weapon/city/wedge
	cost = 75

/* ------------------ Cane Office ------------------*/

// All these weapons have a distinct charge mechanic.
/// Cane Office Cane
/datum/ego_datum/weapon/city/cane_office_cane
	item_path = /obj/item/ego_weapon/city/cane/cane
	cost = 75
	ego_tags = list(EGO_TAG_SUSTAIN)
/// Cane Office Claw
/datum/ego_datum/weapon/city/cane_office_claw
	item_path = /obj/item/ego_weapon/city/cane/claw
	cost = 75
	ego_tags = list(EGO_TAG_MOBILITY)
/// Cane Office Gauntlet
/datum/ego_datum/weapon/city/cane_office_fist
	item_path = /obj/item/ego_weapon/city/cane/fist
	cost = 75
/// Cane Office Briefcase
/datum/ego_datum/weapon/city/cane_office_briefcase
	item_path = /obj/item/ego_weapon/city/cane/briefcase
	cost = 75
	ego_tags = list(EGO_TAG_KNOCKBACK)
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

/* ------------------ Rosespanner Workshop ------------------*/
// Interestingly, these weapons are meant to be able to 'overcharge' and become indiscriminate AOE, however due to the way they handled the adjust charge override it's bugged and doesn't work.
/// Rosespanner Minihammer
/datum/ego_datum/weapon/city/rosespanner_minihammer
	item_path = /obj/item/ego_weapon/city/rosespanner/minihammer
	cost = 60
	ego_tags = list(EGO_TAG_AOE_RADIAL)
/// Rosespanner Hammer
/datum/ego_datum/weapon/city/rosespanner_hammer
	item_path = /obj/item/ego_weapon/city/rosespanner/hammer
	cost = 60
	ego_tags = list(EGO_TAG_AOE_RADIAL)

/// Rosespanner Spear
/datum/ego_datum/weapon/city/rosespanner_spear
	item_path = /obj/item/ego_weapon/city/rosespanner/spear
	cost = 60
	ego_tags = list(EGO_TAG_AOE_RADIAL)

/* ------------------ Dong-hwan, Grade 1 Fixer ------------------*/
// He has so much aura he gets an entire section for his weapon

/// Carver of Scars
/datum/ego_datum/weapon/city/donghwan
	item_path = /obj/item/ego_weapon/city/donghwan
	cost = 90
	ego_tags = list(EGO_TAG_KNOCKBACK, EGO_TAG_HAZARDOUS)

/* ------------------ Colour Fixers ------------------*/

/* This thing is a runtime merchant so I'm going to exercise my free will and civic responsibility to comment it out until it gets fixed. I believe it's running faction checks on stuff it shouldn't
/// Black Silence's Gloves (Black Silence)
/datum/ego_datum/weapon/city/black_silence
	item_path = /obj/item/ego_weapon/black_silence_gloves
	cost = 120
*/

/// Elogio Bianco (Blue Reverberation)
/datum/ego_datum/weapon/city/reverberation
	item_path = /obj/item/ego_weapon/city/reverberation
	cost = 120
	ego_tags = list(EGO_TAG_VERSATILE_DAMAGE, EGO_TAG_AOE_RADIAL, EGO_TAG_HAZARDOUS)

/// Vermillion Cross (Vermillion Cross)
// Contemplating blacklisting this one on principle of "it can very easily get up to thousands of damage by using spicebush" but like, you can do that in the regular game so I dunno
/datum/ego_datum/weapon/city/vermillion
	item_path = /obj/item/ego_weapon/city/vermillion
	cost = 120
	ego_tags = list(EGO_TAG_SUSTAIN)

/// True Mimicry (Red Mist)
/datum/ego_datum/weapon/city/true_mimicry
	item_path = /obj/item/ego_weapon/mimicry/kali
	cost = 120
	ego_tags = list(EGO_TAG_SUSTAIN)

/* I'm also commenting this one because it's causing runtimes - I believe this one is just a simple unregister signal warning for shift click when it is "dropped" (spawned)
/// Viper's Blade / Serpent's Fang / Serpentine Greatsword / Sheathed Serpentine Greatsword (Purple Tear)
// If you are wondering why this is aiming at specifically the blunt subtype, it's because:
// 1. The /pt/ type is just a template and shouldn't be used, 2. Blunt and Guard are the only variants without a typo in their name so it looks better
/datum/ego_datum/weapon/city/purple_tear
	item_path = /obj/item/ego_weapon/city/pt/blunt
	cost = 120
*/
/*
------------------ Wings and other Corporations ------------------
*/

/* ------------------ J Corp ------------------*/
// I'm gonna be honest none of this is actual J Corp stuff it's J Corp Syndicates, but they're in the JCorp file... oh well

// | Ting-Tang Gang |
//
// These weapons deal a random amount of damage that gets weighted more towards the lower end the less sanity you have.
/// Ting Tang Shank
/datum/ego_datum/weapon/city/ting_tang
	item_path = /obj/item/ego_weapon/city/ting_tang
	cost = 25
/// Ting Tang Cleaver
/datum/ego_datum/weapon/city/ting_tang/cleaver
	item_path = /obj/item/ego_weapon/city/ting_tang/cleaver
/// Ting Tang Pipe
/datum/ego_datum/weapon/city/ting_tang/pipe
	item_path = /obj/item/ego_weapon/city/ting_tang/pipe
/// Ting Tang Knife
/datum/ego_datum/weapon/city/ting_tang/knife
	item_path = /obj/item/ego_weapon/city/ting_tang/knife
	cost = 40

// | Los Mariachis |
//
// 'Maracas' type weapons; they have a Poise system.
/// Los Mariachis Maracas
/datum/ego_datum/weapon/city/mariachi
	item_path = /obj/item/ego_weapon/city/mariachi
	cost = 25
/// Los Mariachis Leader Dual Maracas
/datum/ego_datum/weapon/city/mariachi/dual
	item_path = /obj/item/ego_weapon/city/mariachi/dual
	cost = 40
/// Los Mariachis Leader Dual Glowing Maracas
/datum/ego_datum/weapon/city/mariachi/dual/boss
	item_path = /obj/item/ego_weapon/city/mariachi/dual/boss
	cost = 60

// 'Blade' type weapons; they heal SP on kill.
/// Los Mariachis Dual Machetes
/datum/ego_datum/weapon/city/mariachi_blades
	item_path = /obj/item/ego_weapon/city/mariachi_blades
	cost = 25
	ego_tags = list(EGO_TAG_SUSTAIN)

/* ------------------ K Corp ------------------*/

// Melee Weapons
/// K Corp Baton
/datum/ego_datum/weapon/city/kcorp
	item_path = /obj/item/ego_weapon/city/kcorp
	cost = 25
/// K Corp Axe
/datum/ego_datum/weapon/city/kcorp/axe
	item_path = /obj/item/ego_weapon/city/kcorp/axe
/// K Corp Shield
/datum/ego_datum/weapon/city/kcorp/shield
	item_path = /obj/item/ego_weapon/shield/kcorp
/// K Corp Spear
/datum/ego_datum/weapon/city/kcorp/spear
	item_path = /obj/item/ego_weapon/city/kcorp/spear
	cost = 60
/// K Corp Blast Spear
/datum/ego_datum/weapon/city/kcorp/dspear
	item_path = /obj/item/ego_weapon/city/kcorp/dspear
	cost = 60

// Guns
/// K Corp Pistol
/datum/ego_datum/weapon/city/kcorp/pistol
	item_path = /obj/item/ego_weapon/ranged/pistol/kcorp
/// K Corp Machinepistol
/datum/ego_datum/weapon/city/kcorp/smg
	item_path = /obj/item/ego_weapon/ranged/pistol/kcorp/smg
	cost = 60
/// K Corp Grenade Launcher
/datum/ego_datum/weapon/city/kcorp/nade
	item_path = /obj/item/ego_weapon/ranged/pistol/kcorp/nade
	cost = 60
	ego_tags = list(EGO_TAG_AOE_RADIAL, EGO_TAG_HAZARDOUS)

/* ------------------ L Corp ------------------*/

/*
Okay so Lobotomy Corp has some non-EGO weapons, these would be the ERA/DO weapons
However I don't think they really qualify to have a city weapon datum added; there's no point to adding them to the test range (no egoshards unless we wanna add those)
And they're also not obtainable outside of the main LC13 mode AFAIK?
Feel free to add them here if you disagree though.
*/

/* ------------------ N Corp ------------------*/

// | Inquisition |
//
// 'Nail' type weapons; apply marks onto targets hit. These nails can be hit by a hammer to deal the hammer's base force at any range to all marked targets.
/// N Corp Inquisition KleinNagel
/datum/ego_datum/weapon/city/ncorp_nail
	item_path = /obj/item/ego_weapon/city/ncorp_nail
	cost = 25
/// N Corp Inquisition MittleNagel
/datum/ego_datum/weapon/city/ncorp_nail/big
	item_path = /obj/item/ego_weapon/city/ncorp_nail/big
	cost = 60
/// N Corp Inquisition GrossNagel
/datum/ego_datum/weapon/city/ncorp_nail/huge
	item_path = /obj/item/ego_weapon/city/ncorp_nail/huge
	cost = 75
/// N Corp Inquisition Nagel der Gerechten
/datum/ego_datum/weapon/city/ncorp_nail/grip
	item_path = /obj/item/ego_weapon/city/ncorp_nail/grip
	cost = 75

// 'Brass Nail' type weapons; gain nails when hitting a target. When hit by a hammer, boost force on the next hit of the hammer based on the amount of nails.
/// N Corp Inquisition MessingNagel
/datum/ego_datum/weapon/city/ncorp_brassnail
	item_path = /obj/item/ego_weapon/city/ncorp_brassnail
	cost = 25
/// N Corp Inquisition ElektrumNagel
/datum/ego_datum/weapon/city/ncorp_brassnail/big
	item_path = /obj/item/ego_weapon/city/ncorp_brassnail/big
	cost = 60
/// N Corp Inquisition GoldNagel
/datum/ego_datum/weapon/city/ncorp_brassnail/huge
	item_path = /obj/item/ego_weapon/city/ncorp_brassnail/huge
	cost = 75
/// N Corp Inquisition RoseNagel
/datum/ego_datum/weapon/city/ncorp_brassnail/rose
	item_path = /obj/item/ego_weapon/city/ncorp_brassnail/rose
	cost = 75

// 'Hammer' type weapons; can hit a Nail weapon to pop marks for a certain effect.
/// N Corp Inquisition KleinHammer
/datum/ego_datum/weapon/city/ncorp_hammer
	item_path = /obj/item/ego_weapon/city/ncorp_hammer
	cost = 25
/// N Corp Inquisition MittelHammer
/datum/ego_datum/weapon/city/ncorp_hammer/big
	item_path = /obj/item/ego_weapon/city/ncorp_hammer/big
	cost = 60
/// N Corp Inquisition GrossHand
/datum/ego_datum/weapon/city/ncorp_hammer/hand
	item_path = /obj/item/ego_weapon/city/ncorp_hammer/hand
	cost = 75
/// N Corp Inquisition Hand der Gerechten
/datum/ego_datum/weapon/city/ncorp_hammer/grip
	item_path = /obj/item/ego_weapon/city/ncorp_hammer/grippy
	cost = 75


/* ------------------ R Corp ------------------*/
// Not all R Corp weapons are featured here, because some of them don't even use the ego_weapon type and/or they're meant for RCA/RCE primarily.

// Melee
/// R Corp High Frequency Blade
/datum/ego_datum/weapon/city/rcorp_melee
	item_path = /obj/item/ego_weapon/city/rabbit_blade
	cost = 45
	ego_tags = list(EGO_TAG_VERSATILE_DAMAGE)
/// R Corp Rush Dagger
/datum/ego_datum/weapon/city/rcorp_melee/rush
	item_path = /obj/item/ego_weapon/city/rabbit_rush
	ego_tags = list(EGO_TAG_MOBILITY)
/// R Corp Command Saber
/datum/ego_datum/weapon/city/rcorp_melee/command
	item_path = /obj/item/ego_weapon/city/rabbit_blade/command
	cost = 80

// Reindeer Staves
/// R Corp Reindeer Staff
/datum/ego_datum/weapon/city/rcorp_staff
	item_path = /obj/item/ego_weapon/city/reindeer
	cost = 50
	ego_tags = list(EGO_TAG_VERSATILE_DAMAGE, EGO_TAG_SPECIAL_RANGED)
/// R Corp Captain Reindeer Staff
/datum/ego_datum/weapon/city/rcorp_staff/command
	item_path = /obj/item/ego_weapon/city/reindeer/captain
	cost = 75

/* ------------------ W Corp ------------------*/

/// W Corp Baton
/datum/ego_datum/weapon/city/wcorp
	item_path = /obj/item/ego_weapon/city/wcorp
	cost = 25

// 'Type A' weapons, use charge for extra damage and offensive effects.
/// W Corp Gauntlet
/datum/ego_datum/weapon/city/wcorp/fist
	item_path = /obj/item/ego_weapon/city/wcorp/fist
	cost = 60
	ego_tags = list(EGO_TAG_KNOCKBACK)
/// W Corp Axe
/datum/ego_datum/weapon/city/wcorp/axe
	item_path = /obj/item/ego_weapon/city/wcorp/axe
	cost = 60
/// W Corp Spear
/datum/ego_datum/weapon/city/wcorp/spear
	item_path = /obj/item/ego_weapon/city/wcorp/spear
	cost = 60
	ego_tags = list(EGO_TAG_AOE_RADIAL)
/// W Corp Dagger
/datum/ego_datum/weapon/city/wcorp/dagger
	item_path = /obj/item/ego_weapon/city/wcorp/dagger
	cost = 60
/// W Corp Hatchet
/datum/ego_datum/weapon/city/wcorp/hatchet
	item_path = /obj/item/ego_weapon/city/wcorp/hatchet
	cost = 60
	ego_tags = list(EGO_TAG_DEBUFFER)
/// W Corp Warhammer
/datum/ego_datum/weapon/city/wcorp/hammer
	item_path = /obj/item/ego_weapon/city/wcorp/hammer
	cost = 60
	ego_tags = list(EGO_TAG_DEBUFFER)

// 'Type C' weapons, use charge for self and ally shielding.
/// W Corp Shieldblade
/datum/ego_datum/weapon/city/wcorp/shield
	item_path = /obj/item/ego_weapon/city/wcorp/shield
	cost = 60
	ego_tags = list(EGO_TAG_SUSTAIN) // I consider shields health
/// W Corp Shieldclub
/datum/ego_datum/weapon/city/wcorp/shield/club
	item_path = /obj/item/ego_weapon/city/wcorp/shield/club
/// W Corp Shieldaxe
/datum/ego_datum/weapon/city/wcorp/shield/axe
	item_path = /obj/item/ego_weapon/city/wcorp/shield/axe
/// W Corp Shieldglaive
/datum/ego_datum/weapon/city/wcorp/shield/spear
	item_path = /obj/item/ego_weapon/city/wcorp/shield/spear
	cost = 65

/* ------------------ S(hrimp) Corp ------------------*/
// Some of these definitions are in the shrimp.dm file in this folder, others are in a file called special.dm where actual EGO weapons are.

/// Soda Rifle
/datum/ego_datum/weapon/city/shrimp
	item_path = /obj/item/ego_weapon/ranged/sodarifle
	cost = 25
/// Soda Shotgun
/datum/ego_datum/weapon/city/shrimp/shotgun
	item_path = /obj/item/ego_weapon/ranged/sodashotty

/// Soda Submachinegun
/datum/ego_datum/weapon/city/shrimp/smg
	item_path = /obj/item/ego_weapon/ranged/sodasmg
/// Soda Assault Rifle
/datum/ego_datum/weapon/city/shrimp/assault
	item_path = /obj/item/ego_weapon/ranged/shrimp/assault
/// Soda Minigun
/datum/ego_datum/weapon/city/shrimp/minigun
	item_path = /obj/item/ego_weapon/ranged/shrimp/minigun
	cost = 30
/// Shrimp Corp Rambo's Minigun
/datum/ego_datum/weapon/city/shrimp/minigun/rambo
	item_path = /obj/item/ego_weapon/ranged/shrimp/rambominigun
	cost = 100

/* ------------------ Mirae Life Insurance ------------------*/

// These weapons deal both PALE and WHITE and give healing and ahn on kill.
/// Mirae Life Insurance Cane
/datum/ego_datum/weapon/city/mirae
	item_path = /obj/item/ego_weapon/city/mirae
	cost = 75
	ego_tags = list(EGO_TAG_SUSTAIN, EGO_TAG_SPLIT_DAMAGE)
/// Mirae Life Insurance Package
/datum/ego_datum/weapon/city/mirae/page
	item_path = /obj/item/ego_weapon/city/mirae/page

/* ------------------ Limbus Company ------------------*/
// | LCA |
// You know who to add here when we get the remaining sprites and code them

// | LCB (Limbus Company Bus) |
//
/// Ha Yong - Yi Sang
/datum/ego_datum/weapon/city/lcb_hayong
	item_path = /obj/item/ego_weapon/mini/hayong
	cost = 25
	ego_tags = list(EGO_TAG_MOBILITY)
/// Crow's Eye View - Yi Sang
/datum/ego_datum/weapon/city/lcb_ego_crow
	item_path = /obj/item/ego_weapon/mini/crow
	cost = 50
	ego_tags = list(EGO_TAG_MOBILITY)
/// Walpurgisnacht - Faust
/datum/ego_datum/weapon/city/lcb_walpurgisnacht
	item_path = /obj/item/ego_weapon/shield/walpurgisnacht
	cost = 25
/// Sueño Imposible - Don Quixote
/datum/ego_datum/weapon/city/lcb_suenoimposible
	item_path = /obj/item/ego_weapon/lance/suenoimpossible
	cost = 25
/// La Sangre de Sancho - Don Quixote
/datum/ego_datum/weapon/city/lcb_ego_sangre
	item_path = /obj/item/ego_weapon/lance/sangre
	cost = 50
/// S.A.N.G.R.I.A. - Ryoshu
// Yeah yeah we know the actual name
/datum/ego_datum/weapon/city/lcb_sangria
	item_path = /obj/item/ego_weapon/shield/sangria
	cost = 25
/// Soleil - Meursault
/datum/ego_datum/weapon/city/lcb_soleil
	item_path = /obj/item/ego_weapon/mini/soleil
	cost = 25
/// Tai Xuhuan Jing - Hong Lu
/datum/ego_datum/weapon/city/lcb_taixuhuanjing
	item_path = /obj/item/ego_weapon/taixuhuanjing
	cost = 25
/// Revenge - Heathcliff
/datum/ego_datum/weapon/city/lcb_revenge
	item_path = /obj/item/ego_weapon/revenge
	cost = 25
	ego_tags = list(EGO_TAG_KNOCKBACK)
/// Hearse - Ishmael
/datum/ego_datum/weapon/city/lcb_hearse_mace
	item_path = /obj/item/ego_weapon/mini/hearse
	cost = 25
/datum/ego_datum/weapon/city/lcb_hearse_shield
	item_path = /obj/item/ego_weapon/shield/hearse
	cost = 25
/// Raskolot - Rodion
/datum/ego_datum/weapon/city/lcb_raskolot
	item_path = /obj/item/ego_weapon/raskolot
	cost = 25
	ego_tags = list(EGO_TAG_BOOMERANG)
/// Vogel - Sinclair
/datum/ego_datum/weapon/city/lcb_vogel
	item_path = /obj/item/ego_weapon/vogel
	cost = 25
/// Nobody - Outis
/datum/ego_datum/weapon/city/lcb_nobody
	item_path = /obj/item/ego_weapon/nobody
	cost = 25
	ego_tags = list(EGO_TAG_GUNBLADE)
/// Ungezifer - Gregor
/datum/ego_datum/weapon/city/lcb_ungezifer
	item_path = /obj/item/ego_weapon/ungezifer
	cost = 25

// | LCC (Limbus Company Clearing) |
//
/// LCCB Bat
/datum/ego_datum/weapon/city/lccb
	item_path = /obj/item/ego_weapon/city/lccb_bat
	cost = 25
	ego_tags = list(EGO_TAG_KNOCKBACK)
/// LCCB Bat
/datum/ego_datum/weapon/city/lccb/shield
	item_path = /obj/item/ego_weapon/shield/lccb
/// LCCB Pistol
/datum/ego_datum/weapon/city/lccb/pistol
	item_path = /obj/item/ego_weapon/ranged/city/limbuspistol
	ego_tags = list()
/// LCCB Autopistol
/datum/ego_datum/weapon/city/lccb/autopistol
	item_path = /obj/item/ego_weapon/ranged/city/limbusautopistol
	ego_tags = list()

/// LCCB SMG
/datum/ego_datum/weapon/city/lccb/smg
	item_path = /obj/item/ego_weapon/ranged/city/limbussmg
	ego_tags = list()

/// LCCB Shotgun
/datum/ego_datum/weapon/city/lccb/shotgun
	item_path = /obj/item/ego_weapon/ranged/city/limbusshottie

/// LCCB Magnum
/datum/ego_datum/weapon/city/lccb/magnum
	item_path = /obj/item/ego_weapon/ranged/city/limbusmagnum
	cost = 30
	ego_tags = list()

/*
------------------ Syndicates ------------------
Evilpeople organizations and smaller groups of people, including lesser ones, rats and the Finger Syndicates.
*/

/* ------------------ The Thumb ------------------*/

// | Thumb South |
//
/// Thumb South Soldato Rifle
/datum/ego_datum/weapon/city/thumb_south_rifle
	item_path = /obj/item/ego_weapon/ranged/city/thumb
	cost = 60
/// Thumb South Capo Rifle
/datum/ego_datum/weapon/city/thumb_south_rifle/capo
	item_path = /obj/item/ego_weapon/ranged/city/thumb/capo
	cost = 75
/// Thumb South Sottocapo Shotgun
/datum/ego_datum/weapon/city/thumb_south_shotgun
	item_path = /obj/item/ego_weapon/ranged/city/thumb/sottocapo
	cost = 85

/// Thumb South Capo Brass Knuckles
/datum/ego_datum/weapon/city/thumb_south_melee
	item_path = /obj/item/ego_weapon/city/thumbmelee
	cost = 75
/// Thumb South Sottocapo Cane
/datum/ego_datum/weapon/city/thumb_south_melee/cane
	item_path = /obj/item/ego_weapon/city/thumbcane
	cost = 85

// | Thumb East |
// Note: These weapons require ammo to use their gimmick, but it's not in the test range. We could add a vendor if we wanted? For now I don't see the need, but keep it in mind I guess
/// Thumb East Soldato Rifle
/datum/ego_datum/weapon/city/thumb_east
	item_path = /obj/item/ego_weapon/city/thumb_east
	cost = 75
	ego_tags = list(EGO_TAG_AOE_RADIAL, EGO_TAG_HAZARDOUS)
/// Thumb East Capo Podao
/datum/ego_datum/weapon/city/thumb_east/capo
	item_path = /obj/item/ego_weapon/city/thumb_east/podao
	cost = 85

// | Subsidiary: Night Awls |
/// Night Awl Stiletto
/datum/ego_datum/weapon/city/night_awl
	item_path = /obj/item/ego_weapon/city/awl
	cost = 75

// | Subsidiary: Kurokumo Clan |
/// Kurokumo Blade
/datum/ego_datum/weapon/city/kurokumo
	item_path = /obj/item/ego_weapon/city/kurokumo
	cost = 75

/* ------------------ The Index ------------------*/
// These are the variants WITHOUT the Prescript passive (it targets only breached Abnormalities)

// These weapons are 'locked' (deal WHITE damage) and you must target specific bodyparts to 'unlock' them (will deal PALE damage)
/// Index Proselyte Sword
/datum/ego_datum/weapon/city/index
	item_path = /obj/item/ego_weapon/city/fakeindex
	cost = 40
	ego_tags = list(EGO_TAG_VERSATILE_DAMAGE)
/// Index Proxy Sword
/datum/ego_datum/weapon/city/index/proxy
	item_path = /obj/item/ego_weapon/city/fakeindex/proxy
	cost = 60
/// Index Proxy Spear
/datum/ego_datum/weapon/city/index/proxy/spear
	item_path = /obj/item/ego_weapon/city/fakeindex/proxy/spear
/// Index Proxy Dagger
/datum/ego_datum/weapon/city/index/proxy/knife
	item_path = /obj/item/ego_weapon/city/fakeindex/proxy/knife
/// Index Messenger Greatsword
/datum/ego_datum/weapon/city/index/messenger
	item_path = /obj/item/ego_weapon/city/fakeindex/yan
	cost = 90

/* ------------------ The Middle ------------------*/

// These weapons allow you to use powerful counterattacks, and are stronger against targets with vengeance marks.
/// Middle Little Sibling's Chain
/datum/ego_datum/weapon/city/middle
	item_path = /obj/item/ego_weapon/shield/middle_chain
	cost = 40
/// Middle Younger Sibling's Chain
/datum/ego_datum/weapon/city/middle/younger
	item_path = /obj/item/ego_weapon/shield/middle_chain/younger
	cost = 60
/// Middle Big Sibling's Chain
/datum/ego_datum/weapon/city/middle/big
	item_path = /obj/item/ego_weapon/shield/middle_chain/big
	cost = 90

/* ------------------ The Ring ------------------*/
/*
????????
(We have no Ring weapon sprites)
(It'd be funny if we added the Beastbone Blade I think)
*/

/* ------------------ The Pinky ------------------*/
/*
????????
I'm gonna be real I don't even know if we should add these
*/

/* ------------------ Blade Lineage ------------------*/
// If they ever lock in and take back their home, feel free to move them to the Wings section under S-Corp

/// Blade Lineage Katana (I'm pretty sure they're not katanas in Ruina/Limbus...)
/datum/ego_datum/weapon/city/blade_lineage
	item_path = /obj/item/ego_weapon/city/bladelineage
	cost = 75
	ego_tags = list(EGO_TAG_HAZARDOUS, EGO_TAG_LOCKED_POTENTIAL)

/* ------------------ Carnival ------------------*/

/// Carnival Spear
/datum/ego_datum/weapon/city/carnival_spear
	item_path = /obj/item/ego_weapon/city/carnival_spear
	cost = 60

/* ------------------ Axe Gang ------------------*/

/// Axe Gang Axe
/datum/ego_datum/weapon/city/axe_gang
	item_path = /obj/item/ego_weapon/city/axegang
	cost = 25
/// Axe Gang Heavy Axe
/datum/ego_datum/weapon/city/axe_gang/leader
	item_path = /obj/item/ego_weapon/city/axegang/leader
	cost = 40

/* ------------------ Backstreet Butchers ------------------*/

/// District 23 Butcher Knife
/datum/ego_datum/weapon/city/district23
	item_path = /obj/item/ego_weapon/city/district23
	cost = 25
	ego_tags = list(EGO_TAG_SUSTAIN)
/// District 23 Carving Knife
/datum/ego_datum/weapon/city/district23/pierre
	item_path = /obj/item/ego_weapon/city/district23/pierre
	cost = 40

/* ------------------ Rats ------------------*/

/// Rat Hammer
/datum/ego_datum/weapon/city/rats
	item_path = /obj/item/ego_weapon/city/rats
	cost = 10
/// Rat Combat Knife
/datum/ego_datum/weapon/city/rats/knife
	item_path = /obj/item/ego_weapon/city/rats/knife
/// Rat Scalpel
/datum/ego_datum/weapon/city/rats/scalpel
	item_path = /obj/item/ego_weapon/city/rats/scalpel
/// XX-Corp Zippy 3000
/datum/ego_datum/weapon/city/rats/pistol
	item_path = /obj/item/ego_weapon/ranged/pistol/rats
	ego_tags = list(EGO_TAG_HAZARDOUS)
/// A Brick...?
/datum/ego_datum/weapon/city/rats/brick
	item_path = /obj/item/ego_weapon/city/rats/brick
	cost = 20
/// A Pipe...?
/datum/ego_datum/weapon/city/rats/pipe
	item_path = /obj/item/ego_weapon/city/rats/pipe
	cost = 20

/* ------------------ The Sweepers ------------------*/
// This is not a Syndicate but, eh, they've gotta go somewhere, right?

/// Sweeper Hook
/datum/ego_datum/weapon/city/sweeper
	item_path = /obj/item/ego_weapon/city/sweeper
	cost = 40
	ego_tags = list(EGO_TAG_SUSTAIN)
/// Sweeper Sickle
/datum/ego_datum/weapon/city/sweeper/sickle
	item_path = /obj/item/ego_weapon/city/sweeper/sickle
	cost = 60
/// Sweeper Hooksword
/datum/ego_datum/weapon/city/sweeper/hooksword
	item_path = /obj/item/ego_weapon/city/sweeper/hooksword
	cost = 60
/// Sweeper Claw
/datum/ego_datum/weapon/city/sweeper/claw
	item_path = /obj/item/ego_weapon/city/sweeper/claw
	cost = 60
