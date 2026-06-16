/*
 * ID-card skin gacha registry — banners + skins, with the per-banner
 * rarity pools that PullGacha rolls against.
 *
 * Two datum types live here:
 *
 *   /datum/id_skin       — one cosmetic card override (icon_state,
 *                          rarity, display name, parent banner).
 *
 *   /datum/gacha_banner  — one pull pool (id, name, accent colour,
 *                          ordered preview list, plus three pre-grouped
 *                          rarity buckets the puller picks from).
 *
 * Boot order: SSrefraction_railway.Initialize() calls
 * BuildGachaRegistry(), which constructs the singletons and slots them
 * into SSrefraction_railway.id_skins / .gacha_banners.
 */

/datum/id_skin
	/// Unique key, e.g. "nf_starlight". Used by persistence + UI lookups.
	var/id
	/// Display label shown in the UI.
	var/name
	/// icon_state to slam onto /obj/item/card/id at job-spawn time.
	var/icon_state
	/// "0" | "00" | "000".
	var/rarity
	/// id of the parent banner.
	var/banner_id
	/// Pre-baked base64 PNG of the card icon for the TGUI preview.
	/// Populated once at BuildGachaRegistry time so the UI can render
	/// the icon without a per-open getFlatIcon roundtrip.
	var/icon_data

/datum/gacha_banner
	/// Unique key, e.g. "nova_flare".
	var/id
	/// Display label.
	var/name
	/// Accent colour for the banner card.
	var/display_color
	/// Ordered preview list (skin ids) shown on the banner.
	var/list/skin_ids = list()
	/// Pre-grouped pools for the roller: rarity tier → list of skin ids.
	/// Built once during BuildGachaRegistry from `skin_ids`.
	var/list/pool_0   = list()
	var/list/pool_00  = list()
	var/list/pool_000 = list()

/datum/controller/subsystem/refraction_railway/proc/BuildGachaRegistry()
	id_skins = list()
	gacha_banners = list()

	// ---- Nova Flare banner (V1 content) ----
	var/datum/gacha_banner/nova = new()
	nova.id = "nova_flare"
	nova.name = "Nova Flare"
	nova.display_color = "#3b82f6"

	var/datum/id_skin/starlight_skin = new()
	starlight_skin.id = "nf_starlight"
	starlight_skin.name = "Starlight ID"
	starlight_skin.icon_state = "starlight"
	starlight_skin.rarity = "0"
	starlight_skin.banner_id = "nova_flare"
	id_skins[starlight_skin.id] = starlight_skin
	nova.skin_ids += starlight_skin.id

	var/datum/id_skin/silver_skin = new()
	silver_skin.id = "nf_silver"
	silver_skin.name = "Silver ID"
	silver_skin.icon_state = "silver"
	silver_skin.rarity = "00"
	silver_skin.banner_id = "nova_flare"
	id_skins[silver_skin.id] = silver_skin
	nova.skin_ids += silver_skin.id

	var/datum/id_skin/gold_skin = new()
	gold_skin.id = "nf_gold"
	gold_skin.name = "Gold ID"
	gold_skin.icon_state = "gold"
	gold_skin.rarity = "000"
	gold_skin.banner_id = "nova_flare"
	id_skins[gold_skin.id] = gold_skin
	nova.skin_ids += gold_skin.id

	// Group the banner's pool by rarity for the roller, and bake the
	// preview icon for each skin once so the TGUI can show real card art
	// without a per-open getFlatIcon round trip.
	for(var/skin_id in nova.skin_ids)
		var/datum/id_skin/S = id_skins[skin_id]
		switch(S.rarity)
			if("0")
				nova.pool_0 += S.id
			if("00")
				nova.pool_00 += S.id
			if("000")
				nova.pool_000 += S.id
		S.icon_data = icon2base64(icon('icons/obj/card.dmi', S.icon_state, SOUTH, 1))

	gacha_banners[nova.id] = nova

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
