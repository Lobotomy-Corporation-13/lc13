/*
 * Refraction Railway status-effect glossary: mechanics-only blurbs shown
 * on mob cards. Numbers MUST match code/datums/status_effects/.
 * Built lazily on first console open (safe after SSatoms).
 *
 * Format: terse bullet lines separated by "\n", "X" = the current stack.
 * The card renderer passes `overrideLong` so the CSS tooltip keeps
 * `white-space: pre` and the newlines render as separate lines. Keep
 * each line short — `pre` does not wrap.
 */

GLOBAL_LIST_EMPTY(refraction_status_glossary)

/// Base64 of a status's alert sprite, or null if the path has no sprite.
/proc/RefractionStatusAlertIcon(alert_path)
	if(!ispath(alert_path, /atom/movable/screen/alert))
		return null
	var/atom/movable/screen/alert/A = new alert_path()
	var/result = null
	if(A.icon && A.icon_state)
		result = icon2base64(icon(A.icon, A.icon_state))
	qdel(A)
	return result

/proc/RefractionGlossaryEntry(name, alert_path, desc)
	return list(
		"name" = name,
		"desc" = desc,
		"icon" = RefractionStatusAlertIcon(alert_path),
	)

/// Returns (and caches) the glossary list: list(list("name","desc","icon")).
/proc/RefractionStatusGlossary()
	if(length(GLOB.refraction_status_glossary))
		return GLOB.refraction_status_glossary
	var/list/g = list()
	g += list(RefractionGlossaryEntry("Overheat",
		/atom/movable/screen/alert/status_effect/overheat,
		"- Max Stack: 50\n- Every 5s: take X BURN, then halve X (x4 vs mobs)\n- Removed if no new Overheat by its 2nd damage tick"))
	g += list(RefractionGlossaryEntry("Bleed",
		/atom/movable/screen/alert/status_effect/lc_bleed,
		"- Max Stack: 50\n- On move, NOT while walking: take X BRUTE, then halve X\n- 2s cooldown; x4 vs mobs\n- If it doesn't trigger & none gained 5-10s: all removed"))
	g += list(RefractionGlossaryEntry("Tremor",
		/atom/movable/screen/alert/status_effect/lc_tremor,
		"- Max Stack: 50\n- Slows movement (more per X)\n- Tremor Burst: knocked down X/10 s (mobs: X×5 BRUTE), all Tremor removed\n- Fades if none gained 10-20s"))
	g += list(RefractionGlossaryEntry("Protection",
		/atom/movable/screen/alert/status_effect/protection,
		"- Max Stack: 9\n- Take 10% less damage from ALL sources per X, 10s\n- Multiple sources don't stack (highest kept)"))
	g += list(RefractionGlossaryEntry("Fragile",
		/atom/movable/screen/alert/status_effect/fragile,
		"- Max Stack: 10\n- Take 10% more damage from ALL sources per X, 10s\n- Multiple sources don't stack (highest kept)"))
	var/list/prot_alert = list(
		"RED" = /atom/movable/screen/alert/status_effect/damtype_protection,
		"WHITE" = /atom/movable/screen/alert/status_effect/damtype_protection/white,
		"BLACK" = /atom/movable/screen/alert/status_effect/damtype_protection/black,
		"PALE" = /atom/movable/screen/alert/status_effect/damtype_protection/pale,
	)
	var/list/frag_alert = list(
		"RED" = /atom/movable/screen/alert/status_effect/damtype_protection/fragile,
		"WHITE" = /atom/movable/screen/alert/status_effect/damtype_protection/white/fragile,
		"BLACK" = /atom/movable/screen/alert/status_effect/damtype_protection/black/fragile,
		"PALE" = /atom/movable/screen/alert/status_effect/damtype_protection/pale/fragile,
	)
	for(var/dt in list("RED", "WHITE", "BLACK", "PALE"))
		g += list(RefractionGlossaryEntry("[dt] Protection", prot_alert[dt],
			"- Max Stack: 9\n- Take 10% less [dt] damage per X, 10s\n- Multiple sources don't stack (highest kept)"))
		g += list(RefractionGlossaryEntry("[dt] Fragile", frag_alert[dt],
			"- Max Stack: 10\n- Take 10% more [dt] damage per X, 10s\n- Multiple sources don't stack (highest kept)"))
	g += list(RefractionGlossaryEntry("Damage Up",
		/atom/movable/screen/alert/status_effect/damage_up,
		"- Max Stack: 10\n- Deal 10% more melee damage per X, 10s\n- Multiple sources don't stack (highest kept)"))
	g += list(RefractionGlossaryEntry("Damage Down",
		/atom/movable/screen/alert/status_effect/damage_up/down,
		"- Max Stack: 10\n- Deal 10% less melee damage per X, 10s\n- Multiple sources don't stack (highest kept)"))
	g += list(RefractionGlossaryEntry("Defense Level Up",
		/atom/movable/screen/alert/status_effect/defense_level_up,
		"- Max Stack: 100\n- All damage taken reduced by X/(X+25)\n- 3=10%, 9=26%, 30=55%, 100=80%\n- Stacks add; every 5s X halves (min 1)"))
	g += list(RefractionGlossaryEntry("Defense Level Down",
		/atom/movable/screen/alert/status_effect/defense_level_down,
		"- Max Stack: 100\n- All damage taken increased by X/(X+25)\n- 3=+10%, 9=+26%, 30=+55%, 100=+80%\n- Stacks add; every 5s X halves (min 1)"))
	g += list(RefractionGlossaryEntry("Offense Level Up",
		/atom/movable/screen/alert/status_effect/offense_level_up,
		"- Max Stack: 100\n- All melee damage you deal increased by X/(X+25)\n- 3=10%, 9=26%, 30=55%, 100=80%\n- Stacks add; every 5s X halves (min 1)"))
	g += list(RefractionGlossaryEntry("Offense Level Down",
		/atom/movable/screen/alert/status_effect/offense_level_down,
		"- Max Stack: 100\n- All melee damage you deal decreased by X/(X+25)\n- Stacks add; every 5s X halves (min 1)"))
	g += list(RefractionGlossaryEntry("Poise",
		/atom/movable/screen/alert/status_effect/poise,
		"- Max Stack: 50\n- Each melee: X×2.5% chance to crit\n- On crit: +25% damage, then halve Poise (or spend 1 Concentration)\n- Removed if no crit & none gained 10s"))
	g += list(RefractionGlossaryEntry("Concentration",
		/atom/movable/screen/alert/status_effect/concentration,
		"- Max Stack: 20\n- On a Poise crit: spend 1 instead of halving Poise\n- Decays 1 per 15s; removed if you have no Poise when it decays"))
	g += list(RefractionGlossaryEntry("Sinking",
		/atom/movable/screen/alert/status_effect/sinking,
		"- Max Stack: 50\n- Inactive for the first 5s\n- On taking WHITE/PALE: you take X sanity (mobs: X×4 WHITE), halve X\n- Removed at 0"))
	g += list(RefractionGlossaryEntry("Rupture",
		/atom/movable/screen/alert/status_effect/rupture,
		"- Max Stack: 50\n- Inactive for the first 5s\n- On taking RED/BLACK: you take X BRUTE (mobs: X×4 BRUTE), halve X\n- Removed at 0"))
	GLOB.refraction_status_glossary = g
	return g
