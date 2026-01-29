/*
This file holds EGO datums for Realized EGO.
These should NEVER be enabled on the Well. These datums exist so they can show up in the Test Range without having to make some weird unique list. (I guess this file IS that weird unique list?)

'Realized' and 'Assimilation' tags are automatically applied as appropiate.
Note: I chose to tag these Realizations based on their own active and passive abilities. If they have a weapon that interacts with them in some way, I didn't factor it into their tags.
*/

// Basic definition
/datum/ego_datum/armor/realized
	well_enabled = FALSE
	cost = 100 // The Test Range EGO printer is sorted by descending EGO cost, followed by "where does it appear in the directory tree". At 100, these Realizations will appear AFTER the base ALEPHs.

/* ------------------ ZAYIN Realizations ------------------*/

/// Confessional - Penitence (One Sin and Hundreds of Good Deeds)
/datum/ego_datum/armor/realized/confessional
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/confessional
	ego_tags = list(EGO_TAG_SPECIAL_RANGED, EGO_TAG_AOE_RADIAL, EGO_TAG_SUPPORT, EGO_TAG_SUSTAIN)
/// Prophet - Bible (???)
/datum/ego_datum/armor/realized/prophet
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/prophet
/// Blood Maiden - Little Alice (Bottle of Tears)
/datum/ego_datum/armor/realized/maiden
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/maiden
/// Wellcheers - Soda (Wellcheers Vending Machine)
// Warning: This one can very easily be used to lag the server via spawning a bunch of this armour in the test range and using the ability once on each copy.
// We may need to blacklist it, if it gets exploited. However there are easier ways to lag the server or be annoying.
/datum/ego_datum/armor/realized/wellcheers
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/wellcheers
	ego_tags = list(EGO_TAG_SUMMONER)
/// Comatose - Dozing (Sleeping Beauty)
/datum/ego_datum/armor/realized/comatose
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/comatose
	ego_tags = list(EGO_TAG_HAZARDOUS)
/// Broken Crown - Bucket (Wishing Well)
/datum/ego_datum/armor/realized/brokencrown
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/brokencrown

/* ------------------ TETH Realizations ------------------*/

/// Mouth of God - Beak (Punishing Bird)
/datum/ego_datum/armor/realized/mouth
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/mouth
	ego_tags = list(EGO_TAG_AOE_RADIAL)
/// One with the Universe - Fragments From Somewhere (Fragment of the Universe)
/datum/ego_datum/armor/realized/universe
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/universe
	ego_tags = list(EGO_TAG_AOE_RADIAL, EGO_TAG_DEBUFFER)
/// Death Stare - Red Eyes (Spider Bud)
/datum/ego_datum/armor/realized/death
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/death
	ego_tags = list(EGO_TAG_AOE_RADIAL, EGO_TAG_DEBUFFER, EGO_TAG_MOBILITY)
/// Passion of the Fearless One - Life for a Daredevil (Crumbling Armour)
/datum/ego_datum/armor/realized/fear
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/fear
/// Exsanguination - Wrist Cutter (Bloodbath)
/datum/ego_datum/armor/realized/exsanguination
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/exsanguination
/// Ember Matchlight - Fourth Match Flame (Scorched Girl)
/datum/ego_datum/armor/realized/ember_matchlight
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/ember_matchlight
	ego_tags = list(EGO_TAG_AOE_RADIAL, EGO_TAG_HAZARDOUS)
/// Sakura Bloom - Cherry Blossoms (Grave of Cherry Blossoms)
/datum/ego_datum/armor/realized/sakura_bloom
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/sakura_bloom
	ego_tags = list(EGO_TAG_SUPPORT, EGO_TAG_SUSTAIN, EGO_TAG_HAZARDOUS)
/// Stupor - Sloshing (Fairy Gentleman)
/datum/ego_datum/armor/realized/stupor
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/stupor
/// Eldtree - Midwinter Nightmare (Faelantern)
/datum/ego_datum/armor/realized/eldtree
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/eldtree
	ego_tags = list(EGO_TAG_DEBUFFER)

/* ------------------ HE Realizations ------------------*/

/// Grinder MK52 - Grinder MK4 (All-Around Helper)
/datum/ego_datum/armor/realized/grinder
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/grinder
	ego_tags = list(EGO_TAG_AOE_PIERCING, EGO_TAG_MOBILITY)
/// Big Iron - Magic Bullet (Der Freischütz)
/datum/ego_datum/armor/realized/bigiron
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/bigiron
/// Solemn Eulogy - Solemn Lament (Funeral of the Dead Butterflies)
/datum/ego_datum/armor/realized/eulogy
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/eulogy
/// Our Galaxy - Galaxy (Child of the Galaxy)
/datum/ego_datum/armor/realized/ourgalaxy
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/ourgalaxy
	ego_tags = list(EGO_TAG_SUPPORT, EGO_TAG_HAZARDOUS)
/// Together Forever - Unrequited Love (Piscine Mermaid)
/datum/ego_datum/armor/realized/forever
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/forever
/// Endless Wisdom - Harvest (Scarecrow Searching for Wisdom)
/datum/ego_datum/armor/realized/wisdom
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/wisdom
/// Boundless Empathy - Logging (Warm-Hearted Woodsman)
/datum/ego_datum/armor/realized/empathy
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/empathy
/// Unbroken Valor - Courage (Scaredy Cat)
/datum/ego_datum/armor/realized/valor
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/valor
/// Forever Home - Homing Instinct (The Road Home)
/datum/ego_datum/armor/realized/home
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/home
	ego_tags = list(EGO_TAG_SPECIAL_RANGED, EGO_TAG_SUPPORT, EGO_TAG_AOE_RADIAL)
/// Dimension Ripper - Dimension Shredder (Wayward Passenger)
/datum/ego_datum/armor/realized/dimension_ripper
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/dimension_ripper
	ego_tags = list(EGO_TAG_AOE_RADIAL)
/// Experimentation - AEDD (Shock Centipede)
/datum/ego_datum/armor/realized/experimentation
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/experimentation
	ego_tags = list(EGO_TAG_SUSTAIN, EGO_TAG_AOE_RADIAL, EGO_TAG_SUPPORT, EGO_TAG_HAZARDOUS)

/* ------------------ WAW Realizations ------------------*/

/// Gold Experience - Gold Rush (King of Greed)
/datum/ego_datum/armor/realized/goldexperience
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/goldexperience
	ego_tags = list(EGO_TAG_DEBUFFER, EGO_TAG_MOBILITY)
	testrange_blacklisted = TRUE // Teleports elsewhere within the Z Level. This lets people leave the test range; technically this shouldn't affect the facility but let's err on the safe side
/// Quenched with Blood - Sword Sharpened with Tears (Knight of Despair)
/datum/ego_datum/armor/realized/quenchedblood
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/quenchedblood
	ego_tags = list(EGO_TAG_RANGED)
/// Love and Justice - In the Name of Love and Hate (Queen of Hatred)
/datum/ego_datum/armor/realized/lovejustice
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/lovejustice
	ego_tags = list(EGO_TAG_SPECIAL_RANGED, EGO_TAG_AOE_PIERCING, EGO_TAG_SUPPORT)
/// Wounded Courage - Blind Rage (Servant of Wrath)
/datum/ego_datum/armor/realized/woundedcourage
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/woundedcourage
	ego_tags = list(EGO_TAG_AOE_RADIAL)
/// Crimson Lust - Crimson Scar (Little Red Riding Hooded Mercenary)
/datum/ego_datum/armor/realized/crimson
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/crimson
	ego_tags = list(EGO_TAG_HAZARDOUS, EGO_TAG_AOE_RADIAL, EGO_TAG_SUSTAIN) // Debatable sustain tag, the mark is difficult to take advantage of for sustain
/// Eyes of God - Lamp (Big Bird)
/datum/ego_datum/armor/realized/eyes
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/eyes
	ego_tags = list(EGO_TAG_DEBUFFER)
/// Wit of Cruelty - Oppression (Blue Smocked Shepherd)
/datum/ego_datum/armor/realized/cruelty
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/cruelty
/// For Whom the Bell Tolls - Dead Silence (Price of Silence)
/datum/ego_datum/armor/realized/bell_tolls
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/bell_tolls
/// Capitalism - Executive
// Warning: This one can very easily be used to lag the server via spawning a bunch of this armour in the test range and using the ability once on each copy.
// We may need to blacklist it, if it gets exploited. However there are easier ways to lag the server or be annoying.
/datum/ego_datum/armor/realized/capitalism
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/capitalism
	ego_tags = list(EGO_TAG_SUMMONER, EGO_TAG_HAZARDOUS) // Tagged as hazardous because they LOVE FFing you
/// Duality of Harmony - Assonance (Yang)
/datum/ego_datum/armor/realized/duality_yang
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/duality_yang
	ego_tags = list(EGO_TAG_AOE_RADIAL, EGO_TAG_SUSTAIN, EGO_TAG_SUPPORT)
/// Harmony of Duality - Discord (Yin)
/datum/ego_datum/armor/realized/duality_yin
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/duality_yin
	ego_tags = list(EGO_TAG_SPECIAL_RANGED, EGO_TAG_AOE_PIERCING, EGO_TAG_SUPPORT)
/// Repentance - Bleeding Heart (Flesh Idol)
// This one has a heal that goes off of player list, however it has a Z level check. The only possible people this could heal are people in the tutorial or records intern area.
/datum/ego_datum/armor/realized/repentance
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/repentance
	ego_tags = list(EGO_TAG_HAZARDOUS, EGO_TAG_SUPPORT)
/// Living Nest - Exuviae (Naked Nest)
/datum/ego_datum/armor/realized/nest
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/nest
	ego_tags = list(EGO_TAG_SUMMONER, EGO_TAG_DEBUFFER)

/* ------------------ ALEPH Realizations ------------------*/

/// Al Coda - Da Capo (The Silent Orchestra)
/datum/ego_datum/armor/realized/alcoda
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/alcoda
/// Head of God - Justitia (Judgement Bird)
/datum/ego_datum/armor/realized/head
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/head
	ego_tags = list(EGO_TAG_AOE_RADIAL, EGO_TAG_DEBUFFER)
/// Shell - Mimicry (Nothing There)
/datum/ego_datum/armor/realized/shell
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/shell
	ego_tags = list(EGO_TAG_AOE_RADIAL, EGO_TAG_SUSTAIN)
/// Laughter - Smile (Mountain of Smiling Bodies)
/datum/ego_datum/armor/realized/laughter
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/laughter
	ego_tags = list(EGO_TAG_AOE_RADIAL, EGO_TAG_DEBUFFER)
/// Fallen Color - Out of Space (Lady out of Space)
/datum/ego_datum/armor/realized/fallencolors
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/fallencolors
	ego_tags = list(EGO_TAG_SPECIAL_RANGED, EGO_TAG_KNOCKBACK)

/* ------------------ Personal EGO Realizations (Effloresced) ------------------*/

/// Farmwatch (Dongrang)
/datum/ego_datum/armor/realized/farmwatch
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/farmwatch
/// Spicebush (Dongbaek)
/datum/ego_datum/armor/realized/spicebush
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/spicebush
/// Scorching Desperation (Philip)
/datum/ego_datum/armor/realized/desperation
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/desperation
	ego_tags = list(EGO_TAG_HAZARDOUS)
/// Gasharpoon (Ahab)
/datum/ego_datum/armor/realized/gasharpoon
	item_path = /obj/item/clothing/suit/armor/ego_gear/realization/gasharpoon

