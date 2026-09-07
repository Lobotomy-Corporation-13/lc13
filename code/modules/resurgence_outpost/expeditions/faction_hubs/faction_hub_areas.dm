// Faction Hub Area Definitions
// Areas for faction trading hubs visited during expeditions

/**
 * Base faction hub area
 * All faction hubs inherit from this
 */
/area/resurgence/faction_hub
	name = "Faction Hub"
	icon_state = "yellow"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	/// The faction ID this hub belongs to
	var/faction_id = null
	/// Whether this hub allows combat
	var/peaceful = TRUE

// ============================================
// RESURGENCE CLAN VILLAGE
// ============================================

/area/resurgence/faction_hub/resurgence_clan
	name = "Resurgence Clan Village"
	icon_state = "green"
	faction_id = "resurgence_clan"

/area/resurgence/faction_hub/resurgence_clan/entrance
	name = "Clan Village - Entrance"

/area/resurgence/faction_hub/resurgence_clan/market
	name = "Clan Village - Market"

/area/resurgence/faction_hub/resurgence_clan/elder_tent
	name = "Clan Village - Elder's Tent"

// ============================================
// JIAJIA-REN VILLAGE
// ============================================

/area/resurgence/faction_hub/jiajia_ren
	name = "Jiajia-ren Village"
	icon_state = "purple"
	faction_id = "jiajia_ren"

/area/resurgence/faction_hub/jiajia_ren/entrance
	name = "Jiajia-ren Village - Entrance"

/area/resurgence/faction_hub/jiajia_ren/nest_market
	name = "Jiajia-ren Village - Nest Market"

/area/resurgence/faction_hub/jiajia_ren/traders_perch
	name = "Jiajia-ren Village - Trader's Perch"

// ============================================
// SANTATA'S GIFT FACTORY
// ============================================

/area/resurgence/faction_hub/santata_factory
	name = "Santata's Gift Factory"
	icon_state = "red"
	faction_id = "santata_factory"

/area/resurgence/faction_hub/santata_factory/entrance
	name = "Factory - Visitor Entrance"

/area/resurgence/faction_hub/santata_factory/showroom
	name = "Factory - Product Showroom"

/area/resurgence/faction_hub/santata_factory/office
	name = "Factory - Dodoru's Office"

// ============================================
// CLOUD TOWN
// ============================================

/area/resurgence/faction_hub/cloud_town
	name = "Cloud Town"
	icon_state = "blue"
	faction_id = "cloud_town"

/area/resurgence/faction_hub/cloud_town/entrance
	name = "Cloud Town - Gates"

/area/resurgence/faction_hub/cloud_town/market_square
	name = "Cloud Town - Market Square"

/area/resurgence/faction_hub/cloud_town/hunters_lodge
	name = "Cloud Town - Hunter's Lodge"

// ============================================
// INSURGENCE CLAN (HOSTILE)
// ============================================

/area/resurgence/faction_hub/insurgence_clan
	name = "Insurgence Outpost"
	icon_state = "darkred"
	faction_id = "insurgence_clan"
	peaceful = FALSE  // Combat zone!

/area/resurgence/faction_hub/insurgence_clan/perimeter
	name = "Insurgence Outpost - Perimeter"

/area/resurgence/faction_hub/insurgence_clan/camp
	name = "Insurgence Outpost - Camp"
