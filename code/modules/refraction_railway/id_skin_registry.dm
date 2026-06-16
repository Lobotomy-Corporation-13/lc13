/*
 * ID-card skin gacha registry — every cosmetic ID skin in the game,
 * grouped into global rarity pools, plus the banners that "feature"
 * a curated subset (highlights) at boosted roll weights.
 *
 * Two datum types live here:
 *
 *   /datum/id_skin       — one cosmetic card override (icon_state,
 *                          rarity, display name, baked preview icon).
 *                          Skins live in one global rarity pool, not
 *                          per-banner.
 *
 *   /datum/gacha_banner  — one rate-up pool. Each banner has a name +
 *                          accent colour + a `highlight_skin_ids`
 *                          list. Highlights appear in the home
 *                          preview orbit and roll at 2x weight inside
 *                          their rarity bucket — you can still pull
 *                          any skin off any banner, but the banner's
 *                          featured skins are noticeably likelier.
 *
 * Boot order: SSrefraction_railway.Initialize() calls
 * BuildGachaRegistry(), which constructs the singletons + global
 * pools and slots them into the subsystem.
 */

/datum/id_skin
	/// Unique key, e.g. "kenyan". Used by persistence + UI lookups.
	var/id
	/// Display label shown in the UI.
	var/name
	/// icon_state to slam onto /obj/item/card/id at job-spawn time.
	var/icon_state
	/// "0" | "00" | "000".
	var/rarity
	/// Pre-baked base64 PNG of the card icon for the TGUI preview.
	/// Populated once at BuildGachaRegistry time so the UI can render
	/// the icon without a per-open getFlatIcon roundtrip.
	var/icon_data

/datum/gacha_banner
	/// Unique key, e.g. "crimson_banner".
	var/id
	/// Display label.
	var/name
	/// Accent colour for the banner card + the home preview ball.
	var/display_color
	/// Featured skin ids — these orbit around the home preview ball
	/// and get a 2x roll weight inside their rarity bucket. Every
	/// other skin in the game is still pullable here at the base rate.
	var/list/highlight_skin_ids = list()

/datum/controller/subsystem/refraction_railway/proc/BuildGachaRegistry()
	id_skins = list()
	gacha_banners = list()
	gacha_pool_0 = list()
	gacha_pool_00 = list()
	gacha_pool_000 = list()

	// ---- All ID-card skins, grouped by rarity. Add new content here. ----
	var/list/skin_defs = list(
		// 0 (common)
		list("id" = "pearl",     "name" = "Pearl",     "icon_state" = "pearl",     "rarity" = "0"),
		list("id" = "indigo",    "name" = "Indigo",    "icon_state" = "indigo",    "rarity" = "0"),
		list("id" = "seafoam",   "name" = "Seafoam",   "icon_state" = "seafoam",   "rarity" = "0"),
		list("id" = "orangegcn", "name" = "Orange GCN","icon_state" = "orangegcn", "rarity" = "0"),
		list("id" = "blue",      "name" = "Blue",      "icon_state" = "blue",      "rarity" = "0"),
		list("id" = "blackgcn",  "name" = "Black GCN", "icon_state" = "blackgcn",  "rarity" = "0"),
		list("id" = "sin_wrath", "name" = "Wrath",     "icon_state" = "sin_wrath", "rarity" = "0"),
		list("id" = "sin_lust",  "name" = "Lust",      "icon_state" = "sin_lust",  "rarity" = "0"),
		list("id" = "sin_sloth", "name" = "Sloth",     "icon_state" = "sin_sloth", "rarity" = "0"),
		list("id" = "sin_glutt", "name" = "Gluttony",  "icon_state" = "sin_glutt", "rarity" = "0"),
		list("id" = "sin_gloom", "name" = "Gloom",     "icon_state" = "sin_gloom", "rarity" = "0"),
		list("id" = "sin_pride", "name" = "Pride",     "icon_state" = "sin_pride", "rarity" = "0"),
		list("id" = "sin_envy",  "name" = "Envy",      "icon_state" = "sin_envy",  "rarity" = "0"),
		// 00 (rare)
		list("id" = "fortitude",      "name" = "Fortitude",      "icon_state" = "fortitude",      "rarity" = "00"),
		list("id" = "prudence",       "name" = "Prudence",       "icon_state" = "prudence",       "rarity" = "00"),
		list("id" = "temperance",     "name" = "Temperance",     "icon_state" = "temperance",     "rarity" = "00"),
		list("id" = "justice",        "name" = "Justice",        "icon_state" = "justice",        "rarity" = "00"),
		list("id" = "gold",           "name" = "Gold",           "icon_state" = "gold",           "rarity" = "00"),
		list("id" = "starlight_gold", "name" = "Starlight Gold", "icon_state" = "starlight_gold", "rarity" = "00"),
		list("id" = "ice",            "name" = "Ice",            "icon_state" = "ice",            "rarity" = "00"),
		list("id" = "rosegold",       "name" = "Rose Gold",      "icon_state" = "rosegold",       "rarity" = "00"),
		list("id" = "silvergcn",      "name" = "Silver GCN",     "icon_state" = "silvergcn",      "rarity" = "00"),
		list("id" = "gunmetal",       "name" = "Gunmetal",       "icon_state" = "gunmetal",       "rarity" = "00"),
		list("id" = "medical",        "name" = "Medical",        "icon_state" = "medical",        "rarity" = "00"),
		list("id" = "science",        "name" = "Science",        "icon_state" = "science",        "rarity" = "00"),
		list("id" = "bloodmoon",      "name" = "Blood Moon",     "icon_state" = "bloodmoon",      "rarity" = "00"),
		list("id" = "nightsky",       "name" = "Night Sky",      "icon_state" = "nightsky",       "rarity" = "00"),
		list("id" = "medalred",       "name" = "Red Medal",      "icon_state" = "medalred",       "rarity" = "00"),
		list("id" = "medalblue",      "name" = "Blue Medal",     "icon_state" = "medalblue",      "rarity" = "00"),
		list("id" = "roman",          "name" = "Roman",          "icon_state" = "roman",          "rarity" = "00"),
		list("id" = "carp",           "name" = "Carp",           "icon_state" = "carp",           "rarity" = "00"),
		// 000 (very rare)
		list("id" = "kenyan",            "name" = "Kenyan",            "icon_state" = "kenyan",            "rarity" = "000"),
		list("id" = "american",          "name" = "American",          "icon_state" = "american",          "rarity" = "000"),
		list("id" = "flame",             "name" = "Flame",             "icon_state" = "flame",             "rarity" = "000"),
		list("id" = "rainbow",           "name" = "Rainbow",           "icon_state" = "rainbow",           "rarity" = "000"),
		list("id" = "gundam",            "name" = "Gundam",            "icon_state" = "gundam",            "rarity" = "000"),
		list("id" = "cherry",            "name" = "Cherry",            "icon_state" = "cherry",            "rarity" = "000"),
		list("id" = "transparent_black", "name" = "Transparent Black", "icon_state" = "transparent_black", "rarity" = "000"),
		list("id" = "transparent_blue",  "name" = "Transparent Blue",  "icon_state" = "transparent_blue",  "rarity" = "000"),
		list("id" = "transparent_ruby",  "name" = "Transparent Ruby",  "icon_state" = "transparent_ruby",  "rarity" = "000"),
		list("id" = "divinelight",       "name" = "Divine Light",      "icon_state" = "divinelight",       "rarity" = "000"),
	)

	for(var/list/def in skin_defs)
		var/datum/id_skin/S = new()
		S.id         = def["id"]
		S.name       = def["name"]
		S.icon_state = def["icon_state"]
		S.rarity     = def["rarity"]
		S.icon_data  = icon2base64(icon('icons/obj/card.dmi', S.icon_state, SOUTH, 1))
		id_skins[S.id] = S
		switch(S.rarity)
			if("0")
				gacha_pool_0 += S.id
			if("00")
				gacha_pool_00 += S.id
			if("000")
				gacha_pool_000 += S.id

	// ---- Banners. Each features specific 000s + a few thematic 00s. ----
	// All banners draw from the global rarity pools above; highlights
	// just get a 2x roll weight inside their bucket.
	var/list/banner_defs = list(
		list(
			"id"         = "crimson_banner",
			"name"       = "Crimson Banner",
			"color"      = "#dc2626",
			"highlights" = list(
				"kenyan", "american",
				"bloodmoon", "medalred", "roman", "gold",
			),
		),
		list(
			"id"         = "prism_drift",
			"name"       = "Prism Drift",
			"color"      = "#3b82f6",
			"highlights" = list(
				"flame", "rainbow",
				"ice", "medalblue", "nightsky", "starlight_gold",
			),
		),
		// Auric Crown carries the four virtues as its 00 rate-up
		// (fortitude/prudence/temperance/justice) — they share the
		// banner's sacred / divine theme and stay grouped here so a
		// player chasing the virtues doesn't have to switch banners.
		list(
			"id"         = "auric_crown",
			"name"       = "Auric Crown",
			"color"      = "#d4af37",
			"highlights" = list(
				"gundam", "cherry", "divinelight",
				"fortitude", "prudence", "temperance", "justice",
			),
		),
		list(
			"id"         = "phantom_glass",
			"name"       = "Phantom Glass",
			"color"      = "#22c55e",
			"highlights" = list(
				"transparent_black", "transparent_blue", "transparent_ruby",
				"silvergcn", "gunmetal", "science", "medical", "rosegold",
			),
		),
	)
	for(var/list/bdef in banner_defs)
		var/datum/gacha_banner/B = new()
		B.id                 = bdef["id"]
		B.name               = bdef["name"]
		B.display_color      = bdef["color"]
		var/list/highlights  = bdef["highlights"]
		B.highlight_skin_ids = highlights.Copy()
		gacha_banners[B.id]  = B

	// Bake the three rarity-tinted fracture sprites once. The 96x96
	// gatch_tear icon is the white base; ICON_MULTIPLY tints it via the
	// rarity colour.
	gacha_fracture_icons = list()
	var/list/tints = list(
		"gray" = "#7a7a7a",
		"red"  = "#c04020",
		"gold" = "#d4af37",
	)
	for(var/key in tints)
		var/icon/I = icon('icons/effects/96x96.dmi', "gatch_tear", SOUTH, 1)
		I.Blend(tints[key], ICON_MULTIPLY)
		gacha_fracture_icons[key] = icon2base64(I)
