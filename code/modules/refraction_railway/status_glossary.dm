/*
 * Refraction Railway status-effect glossary: mechanics-only blurbs shown
 * on mob cards. Numbers MUST match code/datums/status_effects/.
 * Built lazily on first console open (safe after SSatoms).
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
		"Max stack 50. Every 5 seconds: take BURN equal to the stack, then \
		halve the stack (x4 vs mobs). If no new Overheat is applied by its \
		second damage tick, it is removed entirely."))
	g += list(RefractionGlossaryEntry("Bleed",
		/atom/movable/screen/alert/status_effect/lc_bleed,
		"Max stack 50. When you MOVE — but NOT while walking — take BRUTE \
		equal to the stack, then halve it (2 second cooldown; x4 vs mobs). \
		Walking does not trigger it. If it does not trigger and no new Bleed \
		is gained for 5-10 seconds, all Bleed is removed."))
	g += list(RefractionGlossaryEntry("Tremor",
		/atom/movable/screen/alert/status_effect/lc_tremor,
		"Max stack 50. While you have Tremor you move slower, more per stack, \
		and can be hit by a Tremor Burst: knocked down for (stack / 10) \
		seconds (vs mobs, takes stack x5 BRUTE instead). A burst removes all \
		Tremor. Tremor also fades if no new Tremor is gained for 10-20 \
		seconds."))
	g += list(RefractionGlossaryEntry("Protection",
		/atom/movable/screen/alert/status_effect/protection,
		"Max stack 9. Take 10% less damage from ALL sources per stack, for \
		10 seconds. Does not stack from multiple sources of itself — only \
		the highest value is kept."))
	g += list(RefractionGlossaryEntry("Fragile",
		/atom/movable/screen/alert/status_effect/fragile,
		"Max stack 10. Take 10% more damage from ALL sources per stack, for \
		10 seconds. Does not stack from multiple sources of itself — only \
		the highest value is kept."))
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
			"Max stack 9. Take 10% less [dt] damage per stack, for 10 \
			seconds. Does not stack from multiple sources of itself — only \
			the highest value is kept."))
		g += list(RefractionGlossaryEntry("[dt] Fragile", frag_alert[dt],
			"Max stack 10. Take 10% more [dt] damage per stack, for 10 \
			seconds. Does not stack from multiple sources of itself — only \
			the highest value is kept."))
	g += list(RefractionGlossaryEntry("Damage Up",
		/atom/movable/screen/alert/status_effect/damage_up,
		"Max stack 10. Deal 10% more melee damage per stack, for 10 seconds. \
		Does not stack from multiple sources of itself — only the highest \
		value is kept."))
	g += list(RefractionGlossaryEntry("Damage Down",
		/atom/movable/screen/alert/status_effect/damage_up/down,
		"Max stack 10. Deal 10% less melee damage per stack, for 10 seconds. \
		Does not stack from multiple sources of itself — only the highest \
		value is kept."))
	g += list(RefractionGlossaryEntry("Defense Level Up",
		/atom/movable/screen/alert/status_effect/defense_level_up,
		"Max stack 100. Reduces ALL damage taken by stack / (stack + 25) — \
		3 = 10%, 9 = 26%, 20 = 44%, 30 = 55%, 100 = 80%. Stacks add. Every 5 \
		seconds the stack halves (rounded down, minimum 1), so it must be \
		kept up to hold high defense."))
	g += list(RefractionGlossaryEntry("Defense Level Down",
		/atom/movable/screen/alert/status_effect/defense_level_down,
		"Max stack 100. Increases ALL damage taken by stack / (stack + 25) — \
		3 = +10%, 9 = +26%, 20 = +44%, 30 = +55%, 100 = +80%. Stacks add. \
		Every 5 seconds the stack halves (rounded down, minimum 1). The \
		inverse of Defense Level Up."))
	g += list(RefractionGlossaryEntry("Offense Level Up",
		/atom/movable/screen/alert/status_effect/offense_level_up,
		"Max stack 100. Increases ALL melee damage you deal by stack / \
		(stack + 25) — 3 = 10%, 9 = 26%, 20 = 44%, 30 = 55%, 100 = 80%. \
		Stacks add. Every 5 seconds the stack halves (rounded down, minimum \
		1)."))
	g += list(RefractionGlossaryEntry("Offense Level Down",
		/atom/movable/screen/alert/status_effect/offense_level_down,
		"Max stack 100. Decreases ALL melee damage you deal by stack / \
		(stack + 25). Stacks add. Every 5 seconds the stack halves (rounded \
		down, minimum 1). The inverse of Offense Level Up."))
	g += list(RefractionGlossaryEntry("Poise",
		/atom/movable/screen/alert/status_effect/poise,
		"Max stack 50. Each melee attack has a (stack x 2.5)% chance to \
		critically hit. On a crit: deal +25% bonus damage (off weapon \
		force), then either halve all Poise or, if you have any, consume 1 \
		Concentration instead. If no crit lands and no new Poise is gained \
		for 10 seconds, all Poise is removed."))
	g += list(RefractionGlossaryEntry("Concentration",
		/atom/movable/screen/alert/status_effect/concentration,
		"Max stack 20. Supports Poise: when a Poise crit lands, 1 \
		Concentration is consumed instead of halving Poise. Decays 1 stack \
		every 15 seconds; if you have no Poise when it would decay, all \
		Concentration is removed."))
	g += list(RefractionGlossaryEntry("Sinking",
		/atom/movable/screen/alert/status_effect/sinking,
		"Max stack 50. Inactive for the first 5 seconds. Once active, \
		whenever you take WHITE or PALE damage it triggers: humans take \
		sanity equal to the stack, mobs take WHITE equal to stack x4. The \
		stack then halves; removed at 0."))
	g += list(RefractionGlossaryEntry("Rupture",
		/atom/movable/screen/alert/status_effect/rupture,
		"Max stack 50. Inactive for the first 5 seconds. Once active, \
		whenever you take RED or BLACK damage it triggers: humans take BRUTE \
		equal to the stack, mobs take BRUTE equal to stack x4. The stack \
		then halves; removed at 0."))
	GLOB.refraction_status_glossary = g
	return g
