/*
 * Curtain Call — zeal_s4n2: Achiyalabopa.
 *
 * An actor who climbed too high. The stage became their temple, the
 * audience their congregation, and somewhere along the line they
 * stopped being a person and started being a sky. The storm around
 * her is what remains of the audience's awe — a fixed weather of
 * worship that follows her wherever she goes.
 *
 * Two phases:
 *   P1 — Storm of Heaven. She is untouchable while the storm holds.
 *        Survive the duration. Killing her Mirage Reapers shaves
 *        seconds off the timer.
 *   P2 — The Will of Humanity. Coreflames begin to bloom around her.
 *        Bear one, cast Piercing Strike, the divine spear impales
 *        her for an 8-second vulnerability window. Coreflame burns
 *        out with the strike. Repeat until she falls.
 *
 * Sprites:
 *   Achiyalabopa: ModularLobotomy/_Lobotomyicons/teaser_mobs4.dmi
 *     achiyalabopa          — calm form (P1)
 *     achiyalabopa_enraged  — P2 form, also used while telegraphing
 *   Mirage Reaper: ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi
 *     mirage_reaper / mirage_reaper_dead          (P1 spawns)
 *     mirage_reaper_v2 / mirage_reaper_v2_dead    (P2 spawns)
 */

#define ACHIYA_PHASE_1 1
#define ACHIYA_PHASE_2 2

#define ACHIYA_PHASE_1_DURATION       (90 SECONDS)
#define ACHIYA_AOE_HIT_SHAVE          (5 SECONDS)
#define ACHIYA_STORM_RADIUS           15
#define ACHIYA_REAPER_CAP             6
#define ACHIYA_REAPER_SPAWN_INTERVAL  (8 SECONDS)
#define ACHIYA_COREFLAME_CAP          2
#define ACHIYA_COREFLAME_INTERVAL     (20 SECONDS)
#define ACHIYA_VULN_DURATION          (8 SECONDS)
#define ACHIYA_THUNDER_INTERVAL       (3 SECONDS)
#define ACHIYA_JUDGMENT_INTERVAL      (15 SECONDS)
#define ACHIYA_WHIP_INTERVAL          (20 SECONDS)

// ---------- Storm tile overlay ----------
// Spawned on every floor turf in view(ACHIYA_STORM_RADIUS, boss) at
// Initialize, qdel'd in death(). Replaces the global weather datum the
// old facility version used.

/obj/effect/achiyalabopa_storm_tile
	name = "storm of heaven"
	icon = 'icons/effects/weather_effects.dmi'
	icon_state = "rain_storm"
	alpha = 90
	color = "#3a2a5e"
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE

// ---------- Telegraph & strike temp_visuals ----------

/obj/effect/temp_visual/divine_judgment_warning
	icon = 'icons/effects/effects.dmi'
	icon_state = "tbird_bolt"
	duration = 1 SECONDS
	layer = ABOVE_MOB_LAYER
	color = "#8a4dff"

/obj/effect/temp_visual/divine_judgment_warning/Initialize()
	. = ..()
	animate(src, alpha = 100, time = 5, loop = -1)
	animate(alpha = 255, time = 5)

/obj/effect/temp_visual/divine_judgment_strike
	icon = 'icons/effects/effects.dmi'
	icon_state = "anom"
	duration = 1 SECONDS
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/thunderbolt_strike
	icon = 'icons/effects/effects.dmi'
	icon_state = "tbird_bolt"
	duration = 0.5 SECONDS
	layer = ABOVE_MOB_LAYER
	light_range = 2
	light_power = 2
	light_color = LIGHT_COLOR_ELECTRIC_CYAN

// Pre-strike warning painted on every Thunder Whip cone tile while the
// boss winds up. Uses the same 1x1 bolt sprite the old divine
// thunderbolt used; longer duration than the strike visual so it stays
// visible until the strike wave actually reaches each tile.
/obj/effect/temp_visual/thunder_whip_warning
	icon = 'icons/effects/effects.dmi'
	icon_state = "tbird_bolt"
	duration = 1 SECONDS
	layer = ABOVE_MOB_LAYER
	color = "#8a4dff"

// Passive thunder marker — telegraphs the 3x3 PALE AoE with a purple
// helix-macrolaser-style warning sprite (96x96, pixel-offset to center
// on the source tile), then explodes after `duration`. The object IS
// the warning visual; it qdels itself at the end of Explode().
/obj/effect/divine_thunderbolt
	name = "divine thunderbolt"
	desc = "LOOK OUT!"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "warning"
	color = "#8a4dff"
	pixel_x = -32
	base_pixel_x = -32
	pixel_y = -32
	base_pixel_y = -32
	layer = ABOVE_MOB_LAYER
	move_force = INFINITY
	pull_force = INFINITY
	generic_canpass = FALSE
	movement_type = PHASING | FLYING
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/mob/living/simple_animal/hostile/achiyalabopa/master
	var/duration = 2 SECONDS
	var/range = 1
	var/boom_damage = 50

/obj/effect/divine_thunderbolt/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(Explode)), duration)

/obj/effect/divine_thunderbolt/proc/Explode()
	playsound(get_turf(src), 'sound/abnormalities/thunderbird/tbird_bolt.ogg', 50, FALSE, 8)
	var/list/turfs_to_check = range(range, src)
	var/list/reapers_hit = list()
	for(var/mob/living/L in turfs_to_check)
		if(QDELETED(master) && istype(L, /mob/living/simple_animal/hostile/mirage_reaper))
			continue
		if(istype(L, /mob/living/simple_animal/hostile/mirage_reaper))
			reapers_hit |= L
			continue
		if(!ishuman(L))
			continue
		var/mob/living/carbon/human/H = L
		var/dmg = boom_damage
		if(H.has_status_effect(/datum/status_effect/awe_struck))
			dmg = dmg * 1.5
		H.deal_damage(dmg, PALE_DAMAGE)
		H.electrocute_act(1, src, flags = SHOCK_NOSTUN)
	for(var/obj/vehicle/V in turfs_to_check)
		V.take_damage(boom_damage, PALE_DAMAGE)
	if(master && !QDELETED(master) && length(reapers_hit))
		master.ShaveAndKillReapers(reapers_hit)
	new /obj/effect/temp_visual/tbirdlightning(get_turf(src))
	qdel(src)

// ---------- Piercing Spear (impaled visual) ----------
// Spawned by Piercing Strike, attaches to boss for the vulnerability
// window, follows on Move via signal, qdels when MakeVulnerable's
// timer expires.

/obj/effect/piercing_spear
	name = "divine spear"
	desc = "A radiant spear of pure light, manifestation of humanity's will to survive."
	icon = 'ModularLobotomy/_Lobotomyicons/32x96.dmi'
	icon_state = "myform_staff"
	layer = FLY_LAYER
	light_range = 4
	light_power = 3
	light_color = LIGHT_COLOR_ORANGE
	anchored = TRUE
	color = "#FFD700"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/piercing_spear/Initialize()
	. = ..()
	animate(src, transform = turn(matrix(), 15), time = 2)

// ---------- Hope Blade ----------
// Materialized in the hands of an unarmed Hope-bearer.

/obj/item/ego_weapon/hope_blade
	name = "hope blade"
	desc = "A blade forged from hope itself. It shimmers with golden light."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "spellblade"
	force = 34
	damtype = PALE_DAMAGE
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	hitsound = 'sound/weapons/bladeslice.ogg'
	attribute_requirements = list()
	w_class = WEIGHT_CLASS_NORMAL

// ---------- Awe Struck status effect ----------
// Re-applied every few seconds by the boss to every human in view. Only
// inflicts 6 stacks of generic Fragility (all damage taken up) — no
// movement restriction. Skips application on anyone already carrying
// Hope or Will of Humanity. When Hope or Will of Humanity is granted,
// they explicitly remove this status and clear all Fragile stacks at
// the same time (see Hope/WoH on_apply procs).

/datum/status_effect/awe_struck
	id = "awe_struck"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/awe_struck
	duration = -1
	tick_interval = 1 SECONDS
	var/mob/living/simple_animal/hostile/achiyalabopa/source_mob

/atom/movable/screen/alert/status_effect/awe_struck
	name = "Awe Struck"
	desc = "You are overwhelmed by the storm's pressure. Your body feels fragile under its weight."
	icon_state = "blooddrunk"

/datum/status_effect/awe_struck/on_apply()
	. = ..()
	if(!.)
		return
	if(owner.has_status_effect(/datum/status_effect/hope) || owner.has_status_effect(/datum/status_effect/will_of_humanity))
		return FALSE
	to_chat(owner, span_userdanger("The storm's pressure bears down on you — every blow she lands will strike you harder."))
	return TRUE

// Self-clean if the source boss is gone — catches the edge case where
// the bearer dies, the boss dies while they're still dead/out-of-view,
// and the boss's death() cleanup iteration misses them. Within one
// tick (1s) of the source going down, this status removes itself.
/datum/status_effect/awe_struck/tick()
	if(!source_mob || QDELETED(source_mob) || source_mob.stat == DEAD)
		qdel(src)
		return
	return ..()

// Awe Struck no longer applies any stacking debuff, so there's nothing
// to clean up on removal beyond the chat message.
/datum/status_effect/awe_struck/on_remove()
	to_chat(owner, span_notice("The storm's pressure eases."))
	return ..()

// ---------- Hope status effect ----------
// Spread by the Coreflame's bearer via the Hope Aura action, or applied
// to the bearer themselves on equip. Golden tint, +4 Strength,
// materializes a Hope Blade for unarmed humans. Application strips
// Awe Struck and clears every Fragile stack on the target.

/datum/status_effect/hope
	id = "hope"
	status_type = STATUS_EFFECT_REFRESH
	duration = 60 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/hope
	var/original_color
	var/obj/item/ego_weapon/hope_blade/granted_blade

/atom/movable/screen/alert/status_effect/hope
	name = "Hope"
	desc = "You are filled with hope! You deal increased damage."
	icon_state = "lightingorb"

/datum/status_effect/hope/on_apply()
	. = ..()
	if(!.)
		return
	owner.remove_status_effect(/datum/status_effect/awe_struck)
	ClearAllFragile(owner)
	owner.apply_lc_strength(4)
	if(ismob(owner))
		var/mob/M = owner
		original_color = M.color
		M.color = "#FFD700"
	owner.add_filter("hope_glow", 2, list("type" = "outline", "color" = "#FFD70080", "size" = 2))
	addtimer(CALLBACK(src, PROC_REF(glow_loop)), rand(1, 19))
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		var/has_ego_weapon = FALSE
		for(var/obj/item/I in H.get_all_gear())
			if(istype(I, /obj/item/ego_weapon))
				has_ego_weapon = TRUE
				break
		if(!has_ego_weapon)
			granted_blade = new /obj/item/ego_weapon/hope_blade(get_turf(H))
			H.put_in_hands(granted_blade)
			to_chat(H, span_nicegreen("A blade of hope materializes in your hands!"))
	to_chat(owner, span_nicegreen("You are filled with hope! Nothing can stop you now!"))
	return TRUE

/datum/status_effect/hope/on_remove()
	if(ismob(owner))
		var/mob/M = owner
		M.color = original_color
	owner.remove_filter("hope_glow")
	if(granted_blade && !QDELETED(granted_blade))
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			H.dropItemToGround(granted_blade)
		qdel(granted_blade)
		granted_blade = null
	to_chat(owner, span_notice("The feeling of hope fades..."))
	return ..()

/datum/status_effect/hope/proc/glow_loop()
	var/filter = owner.get_filter("hope_glow")
	if(filter)
		animate(filter, alpha = 180, time = 15, loop = -1)
		animate(alpha = 80, time = 25)

// ---------- Fragile clearing helper ----------
// Removes every Fragile-family stacking debuff from `target`: generic
// Fragile + the four damage-type Fragiles. Used by Hope and Will of
// Humanity to undo the Awe Struck pressure when granted.

/proc/ClearAllFragile(mob/living/target)
	if(!target)
		return
	var/datum/status_effect/F
	F = target.has_status_effect(/datum/status_effect/stacking/protection/fragile)
	if(F)
		qdel(F)
	F = target.has_status_effect(/datum/status_effect/stacking/damtype_protection/fragile)
	if(F)
		qdel(F)
	F = target.has_status_effect(/datum/status_effect/stacking/damtype_protection/white/fragile)
	if(F)
		qdel(F)
	F = target.has_status_effect(/datum/status_effect/stacking/damtype_protection/black/fragile)
	if(F)
		qdel(F)
	F = target.has_status_effect(/datum/status_effect/stacking/damtype_protection/pale/fragile)
	if(F)
		qdel(F)

// ---------- Hope Aura action ----------
// Granted by Will of Humanity. The single Coreflame-bearer activates it
// to spread Hope to nearby allies — the only way to give them the awe
// immunity and the Hope buff while only one Coreflame can be carried.

/datum/action/cooldown/hope_aura
	name = "Hope Aura"
	desc = "Grant the Hope buff to all nearby allies — 60s of golden strength and awe immunity. Cooldown matches Hope's duration."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "spell_default"
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE
	cooldown_time = 60 SECONDS

/datum/action/cooldown/hope_aura/Trigger()
	if(!..())
		return FALSE
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/H = owner
	var/affected = 0
	for(var/mob/living/carbon/human/A in view(5, H))
		if(A == H)
			continue
		if(A.stat == DEAD)
			continue
		A.apply_status_effect(/datum/status_effect/hope)
		affected++
	if(!affected)
		to_chat(H, span_warning("There is no one nearby to hear your call."))
		return FALSE
	to_chat(H, span_nicegreen("Hope spreads to [affected] nearby [affected == 1 ? "ally" : "allies"]!"))
	playsound(H, 'sound/magic/staff_healing.ogg', 50, TRUE)
	StartCooldown()
	return TRUE

// ---------- Will of Humanity status effect ----------
// Granted when a Coreflame is equipped. Grants Piercing Strike spell
// (one-shot vulnerability window on the boss) and the Hope Aura action
// (spread Hope to teammates). On apply, strips Awe Struck and clears
// every Fragile stack. On the holder dropping the Coreflame (or it
// being consumed/destroyed), the status removes itself via tick().

/datum/status_effect/will_of_humanity
	id = "will_of_humanity"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	alert_type = /atom/movable/screen/alert/status_effect/will_of_humanity
	var/obj/item/coreflame/coreflame_item
	var/mutable_appearance/will_overlay
	var/obj/effect/proc_holder/spell/pointed/piercing_strike/strike_spell
	var/datum/action/cooldown/hope_aura/hope_action

/atom/movable/screen/alert/status_effect/will_of_humanity
	name = "Will of Humanity"
	desc = "You carry the Will of Humanity. Strike down what threatens it."
	icon_state = "crucible"

/datum/status_effect/will_of_humanity/on_creation(mob/living/new_owner, obj/item/coreflame/coreflame)
	. = ..()
	if(.)
		coreflame_item = coreflame

/datum/status_effect/will_of_humanity/on_apply()
	. = ..()
	if(!.)
		return
	owner.remove_status_effect(/datum/status_effect/awe_struck)
	ClearAllFragile(owner)
	will_overlay = mutable_appearance('icons/effects/effects.dmi', "blessed", ABOVE_MOB_LAYER)
	owner.add_overlay(will_overlay)
	owner.color = "#b3a400"
	strike_spell = new(owner)
	owner.AddSpell(strike_spell)
	hope_action = new(owner)
	hope_action.Grant(owner)
	to_chat(owner, span_userdanger("You are now the Will of Humanity! Use Piercing Strike to wound her, or Hope Aura to share your gift."))
	return TRUE

/datum/status_effect/will_of_humanity/on_remove()
	if(will_overlay)
		owner.cut_overlay(will_overlay)
		QDEL_NULL(will_overlay)
	owner.color = initial(owner.color)
	if(strike_spell)
		owner.RemoveSpell(strike_spell)
		QDEL_NULL(strike_spell)
	if(hope_action)
		hope_action.Remove(owner)
		QDEL_NULL(hope_action)
	if(coreflame_item && !QDELETED(coreflame_item) && (coreflame_item in owner.get_contents()))
		owner.dropItemToGround(coreflame_item)
	to_chat(owner, span_warning("The Will of Humanity has left you..."))
	return ..()

/datum/status_effect/will_of_humanity/tick()
	if(!coreflame_item || QDELETED(coreflame_item))
		qdel(src)
		return
	var/holding = FALSE
	for(var/obj/item/I in owner.get_contents())
		if(I == coreflame_item)
			holding = TRUE
			break
	if(!holding)
		qdel(src)

// ---------- Piercing Strike spell ----------
// Pointed spell: cast on Achiyalabopa to trigger her vulnerability
// window. Consumes the Coreflame on cast — single-use, then the next
// Coreflame must be picked up for another vulnerability cycle.

/obj/effect/proc_holder/spell/pointed/piercing_strike
	name = "Piercing Strike"
	desc = "Call down a divine spear from the heavens at a target location. If it strikes Achiyalabopa, she's impaled and her defenses crumble for an 8-second window (1.5× from RED/WHITE/BLACK, 3× from PALE). Spear lands 1.5 seconds after the cast — aim where she'll be, not where she is. Consumes the Coreflame regardless of whether it hits."
	school = "transmutation"
	charge_max = 50
	clothes_req = FALSE
	human_req = FALSE
	range = 14
	active_msg = "You raise your hand to the heavens..."
	deactive_msg = "You lower your hand."
	self_castable = FALSE
	action_icon = 'icons/mob/actions/actions_abnormality.dmi'
	action_icon_state = "artillery0"
	sound = 'sound/magic/lightningshock.ogg'
	var/spear_damage = 150

/obj/effect/proc_holder/spell/pointed/piercing_strike/cast(list/targets, mob/living/user)
	if(!length(targets))
		return
	var/turf/target_turf = get_turf(targets[1])
	if(!target_turf)
		return
	ExecuteStrike(user, target_turf)
	return TRUE

// Async because we sleep for the 1.5-second drop animation. cast() has
// already returned by the time this completes, and the Coreflame /
// Will-of-Humanity cleanup has already cascaded.
/obj/effect/proc_holder/spell/pointed/piercing_strike/proc/ExecuteStrike(mob/living/user, turf/target_turf)
	set waitfor = FALSE
	user.visible_message(span_userdanger("[user] calls down a divine spear from the heavens!"))
	playsound(target_turf, 'sound/magic/staff_healing.ogg', 50, TRUE)
	new /obj/effect/temp_visual/cult/sparks(target_turf)
	var/obj/effect/piercing_spear/spear = new(target_turf)
	spear.pixel_y = 96
	spear.alpha = 100
	animate(spear, alpha = 255, time = 5)
	sleep(5)
	animate(spear, pixel_y = 0, time = 10, easing = EASE_IN)
	playsound(target_turf, 'sound/weapons/pierce.ogg', 100, TRUE)
	sleep(10)
	new /obj/effect/temp_visual/explosion(target_turf)
	playsound(target_turf, 'sound/magic/clockwork/ratvar_attack.ogg', 100, TRUE)
	var/mob/living/simple_animal/hostile/achiyalabopa/hit_boss = null
	for(var/mob/living/L in target_turf)
		L.deal_damage(spear_damage, PALE_DAMAGE)
		to_chat(L, span_userdanger("You are struck by the divine spear!"))
		if(istype(L, /mob/living/simple_animal/hostile/achiyalabopa))
			hit_boss = L
	if(hit_boss && !hit_boss.dying && hit_boss.stat != DEAD)
		hit_boss.visible_message(span_userdanger("[hit_boss] is impaled by the divine spear! Her defenses crumble!"))
		hit_boss.MakeVulnerable(ACHIYA_VULN_DURATION, spear)
		if(!QDELETED(user))
			var/obj/item/coreflame/CF = locate(/obj/item/coreflame) in user.get_contents()
			if(CF)
				user.dropItemToGround(CF)
				qdel(CF)
				var/datum/status_effect/hope/burnup_hope = user.apply_status_effect(/datum/status_effect/hope)
				if(burnup_hope)
					burnup_hope.duration = world.time + (15 SECONDS)
				to_chat(user, span_nicegreen("The Coreflame burns out — its last warmth keeps the awe off you for fifteen seconds."))
	else
		QDEL_IN(spear, 2 SECONDS)
		if(!QDELETED(user))
			to_chat(user, span_warning("The spear missed — the Coreflame is still yours."))

// ---------- Coreflame ----------
// The pickup. Spawns around the boss in Phase 2. Anyone (no attribute
// gate, unlike the original facility version) can pick it up to gain
// Will of Humanity → Piercing Strike. Consumed on Piercing Strike cast.

/obj/item/coreflame
	name = "Coreflame"
	desc = "A brilliant flame that burns with the collective will of humanity. Bear it, and you will be able to wound the one who became the storm."
	icon = 'ModularLobotomy/_Lobotomyicons/32x48.dmi'
	icon_state = "bough_bough"
	light_system = MOVABLE_LIGHT
	light_range = 6
	light_power = 3
	light_color = LIGHT_COLOR_ORANGE
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT
	var/mob/living/carbon/human/current_holder
	var/mob/living/simple_animal/hostile/achiyalabopa/parent_boss

/obj/item/coreflame/Initialize()
	. = ..()
	set_light_on(TRUE)

/obj/item/coreflame/equipped(mob/user, slot)
	. = ..()
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(current_holder && current_holder != H && current_holder.stat != DEAD)
		return
	current_holder = H
	H.apply_status_effect(/datum/status_effect/will_of_humanity, src)
	RegisterSignal(H, COMSIG_LIVING_DEATH, PROC_REF(OnHolderDeath))
	visible_message(span_userdanger("[H] claims the Coreflame!"))
	playsound(src, 'sound/magic/staff_healing.ogg', 75, TRUE)

/obj/item/coreflame/dropped(mob/user)
	. = ..()
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/datum/status_effect/will_of_humanity/will_effect = H.has_status_effect(/datum/status_effect/will_of_humanity)
		if(will_effect)
			H.remove_status_effect(/datum/status_effect/will_of_humanity)
		UnregisterSignal(H, COMSIG_LIVING_DEATH)
	if(user && user.stat != DEAD)
		current_holder = null

/obj/item/coreflame/Destroy()
	if(current_holder)
		UnregisterSignal(current_holder, COMSIG_LIVING_DEATH)
		current_holder = null
	if(parent_boss && !QDELETED(parent_boss))
		parent_boss.active_coreflames -= src
		parent_boss = null
	return ..()

/obj/item/coreflame/proc/OnHolderDeath(datum/source)
	SIGNAL_HANDLER
	if(!current_holder || QDELETED(current_holder))
		return
	current_holder.dropItemToGround(src)
	if(parent_boss && !QDELETED(parent_boss))
		forceMove(get_turf(parent_boss))
		visible_message(span_userdanger("The Coreflame tears free of [current_holder] and hurls itself toward [parent_boss]!"))
		playsound(get_turf(src), 'sound/magic/staff_healing.ogg', 75, TRUE)

// ---------- Mirage Reaper ----------
// Passive add. Spawned around the boss every ACHIYA_REAPER_SPAWN_INTERVAL.
// Each kill in Phase 1 shaves ACHIYA_REAPER_KILL_SHAVE off the timer.
// Burst into flames on touching a Will-of-Humanity holder.

/mob/living/simple_animal/hostile/mirage_reaper
	name = "Mirage Reaper"
	desc = "A feathery entity that materializes from the storm's edge."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "mirage_reaper"
	icon_living = "mirage_reaper"
	icon_dead = "mirage_reaper_dead"
	maxHealth = 150
	health = 150
	melee_damage_lower = 7
	melee_damage_upper = 10
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.5)
	melee_damage_type = BLACK_DAMAGE
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	move_to_delay = 4
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"
	attack_sound = 'sound/creatures/lc13/lovetown/slam.ogg'
	death_sound = 'sound/effects/ghost.ogg'
	emote_hear = list("echoes", "screeches")
	speak_chance = 5
	speed = 2
	del_on_death = TRUE
	faction = list("hostile")
	var/mob/living/simple_animal/hostile/achiyalabopa/parent_boss

/mob/living/simple_animal/hostile/mirage_reaper/AttackingTarget(atom/attacked_target)
	if(isliving(attacked_target))
		var/mob/living/L = attacked_target
		if(L.has_status_effect(/datum/status_effect/will_of_humanity))
			visible_message(span_warning("[src] bursts into flames upon touching [L]!"))
			playsound(get_turf(src), 'sound/magic/fireball.ogg', 50, TRUE)
			new /obj/effect/temp_visual/fire(get_turf(src))
			// 10 HP to the bearer + every living human within 5 tiles of them.
			for(var/mob/living/carbon/human/H in range(5, L))
				if(H.stat == DEAD)
					continue
				H.adjustBruteLoss(-10, forced = TRUE)
			dust()
			return
	return ..()

// Phase 2 visual variant — spawned with the v2 icon set once the boss
// has transitioned. Mechanically identical to the base reaper.
/mob/living/simple_animal/hostile/mirage_reaper/v2
	icon_state = "mirage_reaper_v2"
	icon_living = "mirage_reaper_v2"
	icon_dead = "mirage_reaper_v2_dead"

// ---------- Achiyalabopa ----------

/mob/living/simple_animal/hostile/achiyalabopa
	name = "Achiyalabopa"
	desc = "A magnificent golden being. The storm follows her like an audience that forgot how to leave."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs4.dmi'
	icon_state = "achiyalabopa"
	icon_living = "achiyalabopa"
	icon_dead = "achiyalabopa"
	maxHealth = 8000
	health = 8000
	damage_coeff = list(RED_DAMAGE = 0.0, WHITE_DAMAGE = 0.0, BLACK_DAMAGE = 0.0, PALE_DAMAGE = 0.0)
	melee_damage_lower = 15
	melee_damage_upper = 25
	melee_damage_type = PALE_DAMAGE
	attack_verb_continuous = "smites"
	attack_verb_simple = "smite"
	attack_sound = 'ModularLobotomy/_Lobotomysounds/weapons/guns/manager_wind.ogg'
	death_sound = 'sound/spookoween/ghosty_wind.ogg'
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	ranged_ignores_vision = TRUE
	vision_range = 15
	aggro_vision_range = 20
	move_to_delay = 12
	generic_canpass = FALSE
	del_on_death = FALSE
	faction = list("hostile")
	refraction_manages_own_death = TRUE
	// Sprite is 64-wide — shift -16 to center it on the 32-tile.
	pixel_x = -16
	base_pixel_x = -16

	var/phase = ACHIYA_PHASE_1
	var/phase_1_remaining = ACHIYA_PHASE_1_DURATION
	var/is_vulnerable = FALSE
	var/dying = FALSE
	/// Length of the death fade-out.
	var/death_fade_time = 2 SECONDS

	// ---- Refraction Railway recognition ----
	/// Character this boss recognizes among the railway party, matched as a
	/// case-insensitive substring of a member's mob name. Empty = no one.
	var/recognition_target_name = "Bong Bong"
	/// Two-part recognition line, said at the start of combat when matched.
	var/recognition_line_1 = "Bong Bong. You who hurled the coreflames and cast a GOD from the heavens. I have not forgotten."
	var/recognition_line_2 = "Kneel, blasphemer. You will be PUNISHED for your crimes against a GOD — as all heretics must."
	/// Said as she fades on death (replaces her silent collapse when Bong Bong
	/// is the one who brings her down).
	var/boss_final_line = "...impossible... a GOD... cannot fall... to you... again..."
	/// Once-guard so recognition is attempted a single time per fight.
	var/recognition_attempted = FALSE
	/// TRUE once a party member was actually recognized this fight; makes the
	/// death sequence speak only the final recognition line.
	var/recognized = FALSE
	/// While TRUE the recognition sequence (both halves + 3s after) owns her
	/// voice; every other line is dropped. Sanctioned lines pass via
	/// recognition_bypass.
	var/recognition_locked = FALSE
	var/recognition_bypass = FALSE

	/// Phase-shift barks when Bong Bong is on field: the Coreflame that once
	/// felled her blooms again, and she names her judge.
	var/list/phase_2_lines_bong = list(
		"The flame again?! You would cast a GOD down a SECOND time, Bong Bong?!",
		"So the heretic returns with my own fire. KNEEL - and be JUDGED!",
	)

	var/list/storm_overlays = list()
	var/list/active_reapers = list()
	var/list/active_coreflames = list()

	var/obj/effect/piercing_spear/impaled_spear
	var/list/baseline_phase_2_coeff = list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 0.2, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 0.4)
	var/list/vulnerable_coeff       = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1.5, PALE_DAMAGE = 3.0)

	var/next_thunder = 0
	var/next_judgment = 0
	var/next_whip = 0
	var/next_reaper_spawn = 0
	var/next_coreflame_spawn = 0
	var/next_awe_check = 0
	var/phase_1_timer_id = null
	var/is_performing_aoe = FALSE
	var/is_performing_whip = FALSE

/mob/living/simple_animal/hostile/achiyalabopa/Initialize(mapload)
	. = ..()
	set_light(8, 6, LIGHT_COLOR_ORANGE)
	addtimer(CALLBACK(src, PROC_REF(PaintStorm)), 1)
	next_thunder = world.time + ACHIYA_THUNDER_INTERVAL
	next_judgment = world.time + 10 SECONDS
	next_whip = world.time + 15 SECONDS
	next_reaper_spawn = world.time + 5 SECONDS
	phase_1_timer_id = addtimer(CALLBACK(src, PROC_REF(Phase1Tick)), 1 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)
	UpdateHUD()
	visible_message(span_userdanger("Achiyalabopa descends. The storm settles over the stage."))
	addtimer(CALLBACK(src, PROC_REF(TryRecognition)), 1.5 SECONDS)

// ---------- Refraction Railway recognition ----------

/// Recognition + death lines bypass the lock; every other line is dropped
/// while the recognition sequence holds her voice.
/mob/living/simple_animal/hostile/achiyalabopa/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(recognition_locked && !recognition_bypass)
		return
	return ..()

/// Says a framework-sanctioned line past the recognition lock.
/mob/living/simple_animal/hostile/achiyalabopa/proc/SpeakRecognition(message)
	if(!message)
		return
	recognition_bypass = TRUE
	say(message)
	recognition_bypass = FALSE

/// Start of combat: if a railway party member's mob name contains
/// recognition_target_name, play the two-part recognition line and hold the
/// speech lock through both parts plus 3 seconds.
/mob/living/simple_animal/hostile/achiyalabopa/proc/TryRecognition()
	if(recognition_attempted || stat == DEAD || dying)
		return
	recognition_attempted = TRUE
	if(!recognition_target_name)
		return
	var/datum/refraction_run/R = FindRefractionRunForZ(z)
	if(!R)
		return
	var/found = FALSE
	for(var/mob/M as anything in R.members)
		if(QDELETED(M))
			continue
		var/their_name = M.real_name || M.name
		if(their_name && findtext(their_name, recognition_target_name))
			found = TRUE
			break
	if(!found)
		return
	recognized = TRUE
	recognition_locked = TRUE
	SpeakRecognition(recognition_line_1)
	addtimer(CALLBACK(src, PROC_REF(RecognitionPart2)), 2 SECONDS)

/mob/living/simple_animal/hostile/achiyalabopa/proc/RecognitionPart2()
	if(QDELETED(src) || stat == DEAD || dying)
		recognition_locked = FALSE
		return
	SpeakRecognition(recognition_line_2)
	addtimer(CALLBACK(src, PROC_REF(EndRecognitionLock)), 3 SECONDS)

/mob/living/simple_animal/hostile/achiyalabopa/proc/EndRecognitionLock()
	recognition_locked = FALSE

/mob/living/simple_animal/hostile/achiyalabopa/Destroy()
	if(phase_1_timer_id)
		deltimer(phase_1_timer_id)
		phase_1_timer_id = null
	for(var/obj/effect/achiyalabopa_storm_tile/O in storm_overlays)
		if(!QDELETED(O))
			qdel(O)
	storm_overlays = null
	for(var/mob/living/simple_animal/hostile/mirage_reaper/R in active_reapers)
		if(!QDELETED(R))
			UnregisterSignal(R, COMSIG_LIVING_DEATH)
			qdel(R)
	active_reapers = null
	for(var/obj/item/coreflame/CF in active_coreflames)
		if(!QDELETED(CF))
			qdel(CF)
	active_coreflames = null
	if(impaled_spear && !QDELETED(impaled_spear))
		UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
		qdel(impaled_spear)
		impaled_spear = null
	return ..()

// ---------- Storm overlay painting ----------

/mob/living/simple_animal/hostile/achiyalabopa/proc/PaintStorm()
	var/list/floor_tiles = list()
	for(var/turf/open/floor/T in view(ACHIYA_STORM_RADIUS, src))
		floor_tiles += T
	if(length(floor_tiles) > 500)
		return
	for(var/turf/open/floor/T in floor_tiles)
		var/obj/effect/achiyalabopa_storm_tile/O = new(T)
		storm_overlays += O

// ---------- Overhead HUD ----------
// Golden countdown in Phase 1. Cleared (empty string) on Phase 2 entry
// and left empty for the rest of the fight — no vulnerability text.

/mob/living/simple_animal/hostile/achiyalabopa/proc/UpdateHUD()
	maptext_width = 96
	maptext_height = 32
	maptext_x = -32
	maptext_y = 40
	if(phase == ACHIYA_PHASE_1)
		var/seconds = round(phase_1_remaining / 10)
		maptext = MAPTEXT("<font color='#ffd700'>[seconds]s</font>")
	else
		maptext = ""

// ---------- Phase 1 timer ----------

/mob/living/simple_animal/hostile/achiyalabopa/proc/Phase1Tick()
	if(stat == DEAD || dying)
		return
	if(phase != ACHIYA_PHASE_1)
		return
	phase_1_remaining = max(0, phase_1_remaining - 1 SECONDS)
	UpdateHUD()
	if(phase_1_remaining <= 0)
		EnterPhase2()

/mob/living/simple_animal/hostile/achiyalabopa/proc/EnterPhase2()
	if(phase >= ACHIYA_PHASE_2)
		return
	phase = ACHIYA_PHASE_2
	if(phase_1_timer_id)
		deltimer(phase_1_timer_id)
		phase_1_timer_id = null
	icon_state = "achiyalabopa_enraged"
	icon_living = "achiyalabopa_enraged"
	ChangeResistances(baseline_phase_2_coeff)
	UpdateHUD()
	visible_message(span_userdanger("[src] roars — the storm thins, and a Coreflame begins to bloom in her shadow!"))
	if(recognized)
		say(pick(phase_2_lines_bong))
	playsound(src, 'sound/magic/clockwork/narsie_attack.ogg', 75, TRUE, 20)
	next_coreflame_spawn = world.time + 2 SECONDS

// ---------- AI dispatch ----------

/mob/living/simple_animal/hostile/achiyalabopa/handle_automated_action()
	if(stat == DEAD || dying)
		return
	. = ..()
	if(world.time >= next_awe_check)
		next_awe_check = world.time + 3 SECONDS
		INVOKE_ASYNC(src, PROC_REF(ApplyAweStruck))
	if(world.time >= next_thunder)
		next_thunder = world.time + ACHIYA_THUNDER_INTERVAL
		INVOKE_ASYNC(src, PROC_REF(SummonThunder))
	if(world.time >= next_reaper_spawn && length(active_reapers) < ACHIYA_REAPER_CAP)
		next_reaper_spawn = world.time + ACHIYA_REAPER_SPAWN_INTERVAL
		INVOKE_ASYNC(src, PROC_REF(SpawnMirageReaper))
	if(phase >= ACHIYA_PHASE_2 && world.time >= next_coreflame_spawn && length(active_coreflames) < ACHIYA_COREFLAME_CAP)
		next_coreflame_spawn = world.time + ACHIYA_COREFLAME_INTERVAL
		INVOKE_ASYNC(src, PROC_REF(SpawnCoreflame))
	if(!is_performing_aoe && !is_performing_whip)
		if(world.time >= next_judgment)
			next_judgment = world.time + ACHIYA_JUDGMENT_INTERVAL
			INVOKE_ASYNC(src, PROC_REF(DivineJudgment))
			return
		if(world.time >= next_whip && target)
			next_whip = world.time + ACHIYA_WHIP_INTERVAL
			INVOKE_ASYNC(src, PROC_REF(ThunderWhip), target)

/mob/living/simple_animal/hostile/achiyalabopa/Move()
	if(is_performing_aoe || is_performing_whip)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/achiyalabopa/AttackingTarget(atom/attacked_target)
	if(is_performing_aoe || is_performing_whip)
		return FALSE
	if(isliving(attacked_target))
		var/mob/living/L = attacked_target
		if(L.has_status_effect(/datum/status_effect/awe_struck))
			var/saved_lower = melee_damage_lower
			var/saved_upper = melee_damage_upper
			melee_damage_lower = round(saved_lower * 1.5)
			melee_damage_upper = round(saved_upper * 1.5)
			. = ..()
			melee_damage_lower = saved_lower
			melee_damage_upper = saved_upper
			return .
	return ..()

// ---------- Phase 1 invulnerability ----------

/mob/living/simple_animal/hostile/achiyalabopa/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(dying || stat == DEAD)
		return ..()
	if(phase == ACHIYA_PHASE_1 && amount > 0)
		new /obj/effect/temp_visual/healing/no_dam(get_turf(src))
		return 0
	return ..()

// ---------- Passive Mirage Reaper spawn ----------

/mob/living/simple_animal/hostile/achiyalabopa/proc/SpawnMirageReaper()
	var/turf/origin = get_turf(src)
	if(!origin)
		return
	var/list/candidates = list()
	for(var/turf/open/floor/T in range(3, origin))
		if(T == origin)
			continue
		if(T.density)
			continue
		candidates += T
	if(!length(candidates))
		return
	var/spawn_count = rand(3, 4)
	spawn_count = min(spawn_count, ACHIYA_REAPER_CAP - length(active_reapers), length(candidates))
	if(spawn_count <= 0)
		return
	for(var/i in 1 to spawn_count)
		var/turf/spawn_turf = pick_n_take(candidates)
		var/mob/living/simple_animal/hostile/mirage_reaper/R
		if(phase >= ACHIYA_PHASE_2)
			R = new /mob/living/simple_animal/hostile/mirage_reaper/v2(spawn_turf)
		else
			R = new /mob/living/simple_animal/hostile/mirage_reaper(spawn_turf)
		R.parent_boss = src
		active_reapers += R
		RegisterSignal(R, COMSIG_LIVING_DEATH, PROC_REF(OnReaperDeath))
		RegisterSignal(R, COMSIG_PARENT_QDELETING, PROC_REF(OnReaperQdel))
		R.toggle_ai(AI_ON)
		playsound(spawn_turf, 'sound/magic/lightningshock.ogg', 35, TRUE)
		new /obj/effect/temp_visual/thunderbolt_strike(spawn_turf)

/mob/living/simple_animal/hostile/achiyalabopa/proc/OnReaperDeath(mob/living/simple_animal/hostile/mirage_reaper/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	active_reapers -= source

/mob/living/simple_animal/hostile/achiyalabopa/proc/OnReaperQdel(mob/living/simple_animal/hostile/mirage_reaper/source)
	SIGNAL_HANDLER
	active_reapers -= source

// ---------- Coreflame spawn ----------

/mob/living/simple_animal/hostile/achiyalabopa/proc/SpawnCoreflame()
	var/turf/origin = get_turf(src)
	if(!origin)
		return
	var/list/candidates = list()
	for(var/turf/open/floor/T in range(6, origin))
		if(T.density)
			continue
		candidates += T
	if(!length(candidates))
		return
	var/turf/spawn_turf = pick(candidates)
	var/obj/item/coreflame/CF = new(spawn_turf)
	CF.parent_boss = src
	active_coreflames += CF
	new /obj/effect/temp_visual/sparkles(spawn_turf)
	playsound(spawn_turf, 'sound/magic/staff_healing.ogg', 50, TRUE)
	visible_message(span_nicegreen("A Coreflame blooms near [src]!"))

// ---------- AoE damage helper ----------
// Used by Divine Judgment, Thunder Whip, and Divine Thunderbolt. Hits
// non-faction mobs (players) for the supplied damage. Mirage Reapers
// caught in the area are added to the caller's reapers_hit set —
// damage is NOT applied to them here; the caller calls
// ShaveAndKillReapers afterwards to shave the Phase 1 timer (1s per
// reaper hit) and unmake every reaper in the set. Returns TRUE only
// for non-reaper hits so callers can fire their "struck by..." chat
// line just at players.

/mob/living/simple_animal/hostile/achiyalabopa/proc/AoEDamageMob(mob/living/L, amount, damtype, list/reapers_hit)
	if(L == src)
		return FALSE
	if(istype(L, /mob/living/simple_animal/hostile/mirage_reaper))
		if(reapers_hit)
			reapers_hit |= L
		return FALSE
	if(faction_check_mob(L))
		return FALSE
	if(L.has_status_effect(/datum/status_effect/awe_struck))
		amount = amount * 1.5
	L.deal_damage(amount, damtype)
	return TRUE

// Called by each AoE proc after it finishes processing its damage
// zone. Shaves Phase 1 by 1 second per unique reaper hit, then unmakes
// every reaper in the set so the AoE itself was their killing blow.
// No-op if no reapers were caught.

/mob/living/simple_animal/hostile/achiyalabopa/proc/ShaveAndKillReapers(list/reapers_hit)
	var/count = length(reapers_hit)
	if(count <= 0)
		return
	if(phase == ACHIYA_PHASE_1)
		phase_1_remaining = max(0, phase_1_remaining - (count * ACHIYA_AOE_HIT_SHAVE))
		UpdateHUD()
		playsound(src, 'sound/creatures/lc13/sea_terrors/reaper_scream.ogg', 60, FALSE)
		visible_message(span_nicegreen("[count] Mirage Reaper\s torn out of the storm — her countdown lurches forward!"))
		if(phase_1_remaining <= 0)
			EnterPhase2()
	for(var/mob/living/simple_animal/hostile/mirage_reaper/R in reapers_hit)
		if(!QDELETED(R) && R.stat != DEAD)
			R.death()

// ---------- Awe Struck aura ----------
// Refreshed every 3 seconds. Applies Awe Struck (which inflicts 6
// Fragile and no movement block) to every human in view that doesn't
// already carry Hope or Will of Humanity — those two are total awe
// immunity and the dispel path for the debuff.

/mob/living/simple_animal/hostile/achiyalabopa/proc/ApplyAweStruck()
	for(var/mob/living/carbon/human/H in view(vision_range, src))
		if(H.stat == DEAD)
			continue
		if(H.has_status_effect(/datum/status_effect/hope))
			continue
		if(H.has_status_effect(/datum/status_effect/will_of_humanity))
			continue
		if(H.has_status_effect(/datum/status_effect/awe_struck))
			continue
		var/datum/status_effect/awe_struck/awe = H.apply_status_effect(/datum/status_effect/awe_struck)
		if(awe)
			awe.source_mob = src

// ---------- Passive Thunder (per-target) ----------

/mob/living/simple_animal/hostile/achiyalabopa/proc/SummonThunder()
	var/thunder_range = 7
	var/targets_hit = 0
	var/max_targets = 3
	for(var/mob/living/carbon/human/L in range(thunder_range, src))
		if(L.stat == DEAD)
			continue
		if(targets_hit >= max_targets)
			break
		targets_hit++
		var/obj/effect/divine_thunderbolt/E = new(get_turf(L.loc))
		E.master = src
	var/turf/origin = get_turf(src)
	var/list/candidate_turfs = list()
	for(var/turf/open/floor/T in range(thunder_range, src))
		if(T == origin)
			continue
		if(T.density)
			continue
		candidate_turfs += T
	var/list/picked_turfs = list()
	while(length(candidate_turfs) > 0 && length(picked_turfs) < 5)
		var/turf/T = pick_n_take(candidate_turfs)
		var/too_close = FALSE
		for(var/turf/P in picked_turfs)
			if(get_dist(T, P) < 2)
				too_close = TRUE
				break
		if(too_close)
			continue
		picked_turfs += T
	for(var/turf/T in picked_turfs)
		var/obj/effect/divine_thunderbolt/E = new(T)
		E.master = src

// ---------- Divine Judgment (cardinal plus pattern, 10-tile arms) ----------
// Scaled to match Distorted Form's DFLine reach. 3 waves; each wave
// randomly picks between thin plus (boss-tile included) and wide plus
// (boss column safe).

/mob/living/simple_animal/hostile/achiyalabopa/proc/DivineJudgment()
	is_performing_aoe = TRUE
	visible_message(span_userdanger("[src] raises her wings — divine judgment descends!"))
	playsound(src, 'sound/magic/clockwork/narsie_attack.ogg', 75, TRUE, 20)
	DivineJudgmentWave(1)

/mob/living/simple_animal/hostile/achiyalabopa/proc/DivineJudgmentWave(wave_number)
	if(stat == DEAD || dying)
		is_performing_aoe = FALSE
		return
	var/pattern_type = pick("plus", "plus_wide")
	var/list/danger_tiles = (pattern_type == "plus") ? GetPlusPattern() : GetWidePlusPattern()
	for(var/turf/T in danger_tiles)
		new /obj/effect/temp_visual/divine_judgment_warning(T)
	addtimer(CALLBACK(src, PROC_REF(DivineJudgmentStrike), danger_tiles, wave_number), 1 SECONDS)

/mob/living/simple_animal/hostile/achiyalabopa/proc/DivineJudgmentStrike(list/danger_tiles, wave_number)
	if(stat == DEAD || dying)
		is_performing_aoe = FALSE
		return
	playsound(get_turf(src), 'sound/magic/lightningbolt.ogg', 100, TRUE, 20)
	var/list/reapers_hit = list()
	for(var/turf/T in danger_tiles)
		new /obj/effect/temp_visual/divine_judgment_strike(T)
		for(var/mob/living/L in T)
			if(AoEDamageMob(L, 100, PALE_DAMAGE, reapers_hit))
				to_chat(L, span_userdanger("You are struck by divine judgment!"))
	ShaveAndKillReapers(reapers_hit)
	if(wave_number < 3)
		addtimer(CALLBACK(src, PROC_REF(DivineJudgmentWave), wave_number + 1), 1 SECONDS)
	else
		is_performing_aoe = FALSE

/mob/living/simple_animal/hostile/achiyalabopa/proc/GetPlusPattern()
	var/list/danger_tiles = list()
	var/turf/center = get_turf(src)
	if(!center)
		return danger_tiles
	danger_tiles += center
	for(var/i = 1 to 10)
		var/turf/T_north = locate(center.x, center.y + i, center.z)
		if(T_north)
			danger_tiles += T_north
		var/turf/T_south = locate(center.x, center.y - i, center.z)
		if(T_south)
			danger_tiles += T_south
		var/turf/T_east = locate(center.x + i, center.y, center.z)
		if(T_east)
			danger_tiles += T_east
		var/turf/T_west = locate(center.x - i, center.y, center.z)
		if(T_west)
			danger_tiles += T_west
	return danger_tiles

/mob/living/simple_animal/hostile/achiyalabopa/proc/GetWidePlusPattern()
	var/list/danger_tiles = list()
	var/turf/center = get_turf(src)
	if(!center)
		return danger_tiles
	// Center column/row of the cross is SAFE — boss-tile-line is the dodge corridor.
	for(var/i = 1 to 10)
		var/turf/T_north_left = locate(center.x - 1, center.y + i, center.z)
		if(T_north_left)
			danger_tiles += T_north_left
		var/turf/T_north_right = locate(center.x + 1, center.y + i, center.z)
		if(T_north_right)
			danger_tiles += T_north_right
		var/turf/T_south_left = locate(center.x - 1, center.y - i, center.z)
		if(T_south_left)
			danger_tiles += T_south_left
		var/turf/T_south_right = locate(center.x + 1, center.y - i, center.z)
		if(T_south_right)
			danger_tiles += T_south_right
		var/turf/T_east_top = locate(center.x + i, center.y + 1, center.z)
		if(T_east_top)
			danger_tiles += T_east_top
		var/turf/T_east_bottom = locate(center.x + i, center.y - 1, center.z)
		if(T_east_bottom)
			danger_tiles += T_east_bottom
		var/turf/T_west_top = locate(center.x - i, center.y + 1, center.z)
		if(T_west_top)
			danger_tiles += T_west_top
		var/turf/T_west_bottom = locate(center.x - i, center.y - 1, center.z)
		if(T_west_bottom)
			danger_tiles += T_west_bottom
	return danger_tiles

// ---------- Thunder Whip (forward cone, growing waves) ----------
// Scaled cone: length 5→7→9, width 1→2→3 across two iterations. Waves
// strike in turfs-of-3 by distance.

/mob/living/simple_animal/hostile/achiyalabopa/proc/ThunderWhip(atom/attack_target)
	set waitfor = FALSE
	is_performing_whip = TRUE
	face_atom(attack_target)
	icon_state = "achiyalabopa_enraged"
	visible_message(span_userdanger("[src] raises her wings — lightning crackles in the air!"))
	playsound(get_turf(src), 'sound/magic/lightningshock.ogg', 75, TRUE)
	var/smash_width = 1
	var/smash_length = 5
	var/dir_to_target = get_cardinal_dir(get_turf(src), get_turf(attack_target))
	var/turf/source_turf = get_turf(src)
	var/list/area_of_effect = list()
	var/turf/second_line = get_ranged_target_turf(source_turf, dir_to_target, smash_length - 2)
	for(var/i = 0, i < 2, i++)
		var/list/middle_line = getline(source_turf, get_ranged_target_turf(source_turf, dir_to_target, smash_length))
		for(var/turf/T in middle_line)
			if(T.density)
				break
			var/perp_a = NORTH
			var/perp_b = SOUTH
			if(dir_to_target == NORTH || dir_to_target == SOUTH)
				perp_a = EAST
				perp_b = WEST
			for(var/turf/Y in getline(T, get_ranged_target_turf(T, perp_a, smash_width)))
				if(Y.density)
					break
				if(Y in area_of_effect)
					continue
				area_of_effect += Y
			for(var/turf/U in getline(T, get_ranged_target_turf(T, perp_b, smash_width)))
				if(U.density)
					break
				if(U in area_of_effect)
					continue
				area_of_effect += U
		source_turf = get_ranged_target_turf(second_line, dir_to_target, smash_length)
		smash_length += 2
		smash_width++
	for(var/turf/T in area_of_effect)
		new /obj/effect/temp_visual/thunder_whip_warning(T)
	SLEEP_CHECK_DEATH(0.5 SECONDS)
	if(!LAZYLEN(area_of_effect))
		is_performing_whip = FALSE
		if(phase < ACHIYA_PHASE_2)
			icon_state = "achiyalabopa"
		return
	var/list/sorted_turfs = list()
	var/turf/my_turf = get_turf(src)
	var/max_distance = 0
	for(var/turf/T in area_of_effect)
		var/distance = get_dist(my_turf, T)
		if(!sorted_turfs["[distance]"])
			sorted_turfs["[distance]"] = list()
		sorted_turfs["[distance]"] += T
		if(distance > max_distance)
			max_distance = distance
	var/turfs_per_wave = 3
	var/delay_per_wave = 1.5
	var/turfs_struck = 0
	var/list/reapers_hit = list()
	for(var/dist = 0 to max_distance)
		var/list/turfs_at_distance = sorted_turfs["[dist]"]
		if(!turfs_at_distance)
			continue
		for(var/turf/T in turfs_at_distance)
			if(stat == DEAD || dying)
				is_performing_whip = FALSE
				if(phase < ACHIYA_PHASE_2)
					icon_state = "achiyalabopa"
				ShaveAndKillReapers(reapers_hit)
				return
			new /obj/effect/temp_visual/thunderbolt_strike(T)
			playsound(T, 'sound/magic/lightningbolt.ogg', 50, TRUE)
			for(var/mob/living/L in T)
				if(AoEDamageMob(L, 100, PALE_DAMAGE, reapers_hit))
					to_chat(L, span_userdanger("You are struck by divine lightning!"))
			turfs_struck++
			if(turfs_struck % turfs_per_wave == 0)
				sleep(delay_per_wave)
	ShaveAndKillReapers(reapers_hit)
	is_performing_whip = FALSE
	if(phase < ACHIYA_PHASE_2)
		icon_state = "achiyalabopa"

// ---------- Vulnerability cycle ----------

/mob/living/simple_animal/hostile/achiyalabopa/proc/MakeVulnerable(duration, obj/effect/piercing_spear/spear)
	if(is_vulnerable)
		return
	is_vulnerable = TRUE
	ChangeResistances(vulnerable_coeff)
	animate(src, color = "#FF8888", time = 5)
	visible_message(span_userdanger("[src]'s storm falters — the spear finds the seam in her wings!"))
	if(spear && !QDELETED(spear))
		impaled_spear = spear
		spear.forceMove(loc)
		spear.layer = ABOVE_MOB_LAYER
		RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(UpdateSpearPosition))
		addtimer(CALLBACK(src, PROC_REF(RemoveImpaledSpear), impaled_spear), duration)
	addtimer(CALLBACK(src, PROC_REF(RestoreDefenses)), duration)

/mob/living/simple_animal/hostile/achiyalabopa/proc/UpdateSpearPosition()
	SIGNAL_HANDLER
	if(!impaled_spear || QDELETED(impaled_spear))
		return
	impaled_spear.forceMove(loc)

/mob/living/simple_animal/hostile/achiyalabopa/proc/RemoveImpaledSpear(obj/effect/piercing_spear/spear)
	if(spear && !QDELETED(spear))
		animate(spear, alpha = 0, time = 10)
		QDEL_IN(spear, 10)
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
	impaled_spear = null

/mob/living/simple_animal/hostile/achiyalabopa/proc/RestoreDefenses()
	if(!is_vulnerable)
		return
	is_vulnerable = FALSE
	ChangeResistances(baseline_phase_2_coeff)
	animate(src, color = initial(color), time = 10)
	visible_message(span_warning("[src]'s storm closes around the wound."))

// ---------- Death ----------

/mob/living/simple_animal/hostile/achiyalabopa/death(gibbed)
	if(dying)
		return ..()
	dying = TRUE
	recognition_locked = FALSE
	if(phase_1_timer_id)
		deltimer(phase_1_timer_id)
		phase_1_timer_id = null
	for(var/obj/effect/achiyalabopa_storm_tile/O in storm_overlays)
		if(!QDELETED(O))
			qdel(O)
	storm_overlays = null
	for(var/mob/living/simple_animal/hostile/mirage_reaper/R in active_reapers.Copy())
		UnregisterSignal(R, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
		active_reapers -= R
		if(!QDELETED(R))
			R.gib()
	if(impaled_spear && !QDELETED(impaled_spear))
		UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
		qdel(impaled_spear)
		impaled_spear = null
	for(var/obj/item/coreflame/CF in active_coreflames.Copy())
		if(!QDELETED(CF))
			qdel(CF)
	active_coreflames = null
	for(var/mob/living/carbon/human/H in view(ACHIYA_STORM_RADIUS, src))
		var/datum/status_effect/awe_struck/awe = H.has_status_effect(/datum/status_effect/awe_struck)
		if(awe)
			qdel(awe)
	maptext = ""
	visible_message(span_userdanger("[src] collapses. The storm fades from the stage."))
	if(recognized)
		SpeakRecognition(boss_final_line)
	. = ..()
	animate(src, alpha = 0, time = death_fade_time)
	QDEL_IN(src, death_fade_time)

// ---------- Refraction Railway subtype ----------

/mob/living/simple_animal/hostile/achiyalabopa/refracted
	// Refraction Railway variant. Tuning overrides (if any) go here in
	// future passes — base stats already match the locked numbers.
