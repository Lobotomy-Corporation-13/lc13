//this is in a separate file other than the weak_edits cuz it has a good chunk of code
//fell bullet isnt in here cuz it doesnt have justice scaling
//sticking ego WILL be in here

/obj/item/ego_weapon/mini/fourleaf_clover/city // buffed red damage to the same dmg/atk-spd as BL blade
	force = 46
	attack_speed = 1.2
	icon_state = "sticking"
	attributes_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
	)

#define STATUS_EFFECT_GAZE /datum/status_effect/stacking/perversion_weapon_gaze
#define STATUS_EFFECT_CONTEMPT /datum/status_effect/display/perversion_weapon_contempt
#define COLOR_PERVERSION_LANCE "#e2a91a"
#define COLOR_PERVERSION_KATANA "#c50e0e"
/obj/item/ego_weapon/perversion/weak

//nukes justice scaling & FF checks (aside from fell bullet). confused? look at ModularLobotomy/ego_weapons/melee/abnormality/aleph.dm, base perversion should be in there
	name = "perversion"
	desc = "A twisting, ornate polearm. There's a blood-red blade sheathed within it. \n\
	'Be awed, or be awe-struck.'"
	special = "This weapon has two forms, each with differing special attacks. In its Lance form, it inflicts Gaze on targets, and in its Katana form, it deals additional damage to targets with Gaze. \n\
	Switching the weapon from Lance to Katana form has a cooldown, and performs a special attack."
	icon_state = "perversion_lance"
	icon = 'icons/obj/ego_weapons.dmi'
	lefthand_file = 'icons/mob/inhands/64x64_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/64x64_righthand.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	force = 89 // Change lance_force too
	swingstyle = WEAPONSWING_THRUST
	swingcolor = COLOR_PERVERSION_LANCE
	damtype = BLACK_DAMAGE
	attack_speed = 1.6 // Change lance_attack_speed too
	attack_verb_continuous = list("pierces", "skewers", "perforates", "impales", "gores")
	attack_verb_simple = list("pierce", "skewer", "perforate", "impale", "gore")
	hitsound = 'sound/weapons/ego/perversion_lance_1.ogg'
	hitsound_vary = FALSE
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 80
							)

	/// Empty this out and use it to avoid multihitting stuff on each AoE
	var/list/shared_hitlist

	/// Combo hit counter!
	var/combo = 0
	var/combo_timeout_timer
	var/combo_timeout_duration = 3 SECONDS

	/// Keeps track of your last hit mob. Combo requires you to focus on one, like Da Capo (this is actually a buff as it lets you reset)
	var/last_target_hit

	/// List of cooldowns for balloon alerts... To avoid spamming the user. Duration for all is 0.5s
	var/list/balloon_text_cooldowns = list("unsheathe_cd", "combo_timeout", "lance_lunge" = 0, "katana_dash" = 0, "katana_no_gaze" = 0)
	// You may unsheathe the weapon to turn it from a lance into a katana, the process of unsheathing also does a very strong AOE that gets EXTREMELY powerful on opponents with Gaze stacks.
	var/sheathed = TRUE
	var/unsheathe_cooldown
	var/unsheathe_cooldown_duration = 30 SECONDS
	var/unsheathe_windup = 0.7 SECONDS
	var/sheathe_sound = 'sound/weapons/ego/perversion_sheathe.ogg'
	var/unsheathe_sound = 'sound/weapons/ego/perversion_unsheathe.ogg'

	// Cascading Gaze of Awe Underneath Contempt is the attack automatically performed when unsheathing the katana

	var/cascading_gaze_active = FALSE
	/// Var used exclusively for insane edge cases of the weapon being deleted mid-draw attack to avoid irreversible effects. Can happen with Broken Crown, I think.
	var/mob/living/carbon/human/cascading_gaze_last_used_by
	/// Timer until we forcefully revert changes from Cascading Gaze
	var/cascading_gaze_active_timer
	/// Radius in tiles.
	var/cascading_gaze_radius = 3
	/// Holds all the turfs that will be hit by Cascading Gaze
	var/list/cascading_gaze_affected_turfs = list()
	/// We compare our user's location against this turf to determine whether they have moved during the attack or not (Records core?), if they have, we recalculate the turfs
	var/turf/cascading_gaze_epicenter
	/// Holds things that should be deleted after ending Cascading Gaze.
	var/list/cascading_gaze_residual_datums = list()
	var/cascading_gaze_hit_sounds_list = list('sound/weapons/ego/perversion_katana_1.ogg', 'sound/weapons/ego/perversion_katana_2.ogg')
	var/cascading_gaze_finisher_sound = 'sound/weapons/ego/perversion_draw_finisher.ogg'

	/// Multiplies katana force by this much for the Finisher
	var/cascading_gaze_base_damage_coeff = 1.25
	/// How much damage each tick of being inside the damaging AoE deals.
	var/cascading_gaze_periodic_damage = 30
	/// How often the damaging AoE ticks
	var/cascading_gaze_periodic_tick_rate = 0.6 SECONDS
	/// You'll be locked in place and the projectile deleting area will linger for this many ticks (duration of each determined by previous var).
	var/cascading_gaze_tick_amount = 4
	/// Add to the previous coefficient per gaze stacks on the target we're hitting
	var/cascading_gaze_additive_damage_coeff_per_gaze = 0.4
	/// You'll take [this var]x as much damage while channeling the ability.
	var/cascading_gaze_physiology_coeff = 0.5
	/// These projectile types will create shrapnel.
	var/cascading_gaze_shrapnel_sources = list(/obj/projectile/ego_bullet/special_fellbullet, /obj/projectile/ego_bullet/ego_fellbullet)
	/// Shrapnel from the Fell Bullet interaction applies this much Gaze per hit...
	var/cascading_gaze_shrapnel_gaze_application = 1
	/// The Fell Bullet interaction will generate [pellets] pieces of shrapnel [repeat] times.
	var/list/cascading_gaze_shrapnel_amount = list("repeat" = 3, "pellets" = 5)

	/* ------------ LANCE VARS ------------ */
	// Lance template vars. Used to update the weapon's attributes when sheathing the weapon

	// Icon vars
	var/lance_icon = 'icons/obj/ego_weapons.dmi'
	var/lance_icon_state = "perversion_lance"
	var/lance_inhands_list = list("left" = 'icons/mob/inhands/64x64_lefthand.dmi', "right" = 'icons/mob/inhands/64x64_righthand.dmi')
	var/lance_swingcolor = COLOR_PERVERSION_LANCE

	// Text vars
	var/lance_desc = "A twisting, ornate polearm. There's a blood-red blade sheathed within it. \n\
	'Be awed, or be awe-struck.'"
	var/lance_attack_verb_continuous = list("pierces", "skewers", "perforates", "impales", "gores")
	var/lance_attack_verb_simple = list("pierce", "skewer", "perforate", "impale", "gore")

	// Sound vars
	var/lance_basic_hitsound = 'sound/weapons/ego/perversion_lance_1.ogg'
	var/lance_followup_hitsound = 'sound/weapons/ego/perversion_lance_2.ogg'

	// Combat vars
	var/lance_force = 89
	var/lance_attack_speed = 1.6
	/// The weapon applies this many Gaze stacks per hit in lance form.
	var/base_gaze_application = 1

	// Lance dash. Similar to Dark Carnival/Crow's Eye View/Thumb East opener. This lets you dash at a faraway target, dealing extra damage and applying more Gaze.
	var/lance_dash_range = 4
	var/lance_dash_cooldown
	var/lance_dash_cooldown_duration = 5 SECONDS
	var/lance_dash_extra_gaze_stacks = 1

	// Immediately after a dash, your next attack will do an AoE thrust through your enemy, dealing damage and applying more Gaze. Also hits the main target.
	var/lance_followup_range = 2
	var/lance_followup_damage_coeff = 0.5
	var/lance_followup_extra_gaze_stacks = 2

	/* ------------ KATANA VARS ------------ */
	// Katana template vars. Used to update the weapon's attributes when drawing the weapon

	// Icon vars
	var/katana_icon = 'icons/obj/ego_weapons.dmi'
	var/katana_icon_state = "perversion_katana"
	var/katana_inhands_list = list("left" = 'icons/mob/inhands/64x64_lefthand.dmi', "right" = 'icons/mob/inhands/64x64_righthand.dmi')
	var/katana_swingcolor = COLOR_PERVERSION_KATANA

	// Text vars
	var/katana_desc = "A blood-red sword, removed from its gilded armour. \n\
	The brittle pride will be gradually chipped away when bereft of the disdain that shielded it, so it would be best to sheathe this once your bloody labours are finished."
	var/list/katana_attack_verb_continuous = list("slashes", "slices", "cleaves", "sunders", "carves", "disembowels", "eviscerates", "bisects", "splits", "rends", "rips", "anatomizes", "styles on")
	var/list/katana_attack_verb_simple = list("slash", "slice", "cleave", "sunder", "carve", "disembowel", "eviscerate", "bisect", "split", "rend", "anatomize", "style on")

	// Sound vars
	var/katana_basic_hitsound = 'sound/weapons/ego/perversion_katana_1.ogg'
	var/katana_cleave_hitsound = 'sound/weapons/ego/perversion_katana_2.ogg'
	var/katana_finisher_hitsound = 'sound/weapons/ego/perversion_katana_4.ogg'

	// Combat vars
	// Katana should have less base DPS than the lance. Sheathe it you aurafarmer
	var/katana_force = 65
	var/katana_attack_speed = 1.4
	var/katana_base_damage_coeff = 1
	var/katana_additive_damage_coeff_per_gaze = 0.15 // 0: 1x, 1: 1.15x, 2: 1.3x, 3: 1.45x, 4: 1.6x, 5: 1.75x, 6: 1.9x, Contempt: 2.05x

	var/katana_dash_range = 6
	var/katana_dash_cooldown
	var/katana_dash_cooldown_duration = 2.5 SECONDS

	var/katana_cleave_range = 3
	var/katana_cleave_degrees = 90

	var/katana_finisher_damage_coeff = 1.6


/obj/item/ego_weapon/perversion/Destroy(force)
	if(cascading_gaze_active)
		DrawAttackEnd(cascading_gaze_last_used_by)
	for(var/anything in cascading_gaze_residual_datums) // I really really hope you didn't put anything weird here.
		qdel(anything)
	return ..()

/obj/item/ego_weapon/perversion/GetSwingColor()
	var/color
	sheathed ? (color = lance_swingcolor) : (color = katana_swingcolor)
	return color

/obj/item/ego_weapon/perversion/examine(mob/user)
	. = ..()
	. += span_notice("<a href='?src=[REF(src)];action=full_examine'>\[View Expanded Description]</a>")

/obj/item/ego_weapon/perversion/Topic(href, list/href_list)
	. = ..()
	if(.)
		return
	if(href_list["action"] != "full_examine")
		return
	var/mob/user = usr
	if(!QDELETED(user) && istype(user))
		on_examine(user, user)

/obj/item/ego_weapon/perversion/weak/proc/on_examine(mob/user)
	if(QDELETED(user) || !istype(user))
		return
	. = list()
	. += span_info("While sheathed, this weapon inflicts [base_gaze_application] stacks of Gaze on enemies each hit.")
	. += span_info("<b>Lance Dash</b>: Initiate by attacking at range. Applies [lance_dash_extra_gaze_stacks] additional Gaze stacks, has a range of [lance_dash_range] tiles, cooldown of [lance_dash_cooldown_duration * 0.1] seconds.")
	. += span_info("<b>Lance Followup</b>: Deals [lance_followup_damage_coeff]x of original damage in a [lance_followup_range] tile long AoE, also applying [lance_followup_extra_gaze_stacks] additional Gaze stacks. Includes the original target.")
	. += span_info("")
	. += span_info("While unsheathed, this weapon loses [lance_force - katana_force] force, but deals (1 + [katana_additive_damage_coeff_per_gaze] * gaze stacks)x damage to enemies. Contempt counts as 7 Gaze stacks.")
	. += span_info("All Katana special attacks require Gaze/Contempt on your target to work.")
	. += span_info("<b>Katana Dash</b>: Initiate by attacking at range. Has a range of [katana_dash_range] tiles, cooldown of [katana_dash_cooldown_duration * 0.1] seconds.")
	. += span_info("<b>Katana Cleave</b>: Deals its damage in a [katana_cleave_degrees] degree wide, [katana_cleave_range] tile long slash. Original target will not take additional damage.")
	. += span_info("<b>Katana Finisher</b>: Clears Gaze/Contempt and deals [katana_finisher_damage_coeff]x damage before Force Multiplier and Gaze calculations.")
	. += span_info("")
	. += span_info("The weapon may be drawn once every [unsheathe_cooldown_duration * 0.1] seconds.")
	. += span_info("The draw attack will consist of [cascading_gaze_tick_amount - 1] hits dealing [cascading_gaze_periodic_damage] damage, and a finisher hit dealing [katana_force * cascading_gaze_base_damage_coeff] damage. These values are pre-Gaze scaling.")
	for(var/line in .)
		to_chat(user, line)

// This is the core loop that gets run over and over for our draw attack. It recursively calls itself until we've run through all our ticks, or something happens to cancel the attack.
// The hit happens instantly when this is called - the delay is actually at the end of this proc, to see whether or not we call the next one.
/obj/item/ego_weapon/perversion/weak/proc/DrawAttackLoop(mob/living/carbon/human/user, iteration = 1)
	if(QDELETED(src) || QDELETED(user) || user.stat >= DEAD || user.get_active_held_item() != src)
		DrawAttackEnd(user)
		return

	if(cascading_gaze_epicenter != get_turf(user))
		DrawAttackCalculateAffectedTurfs(user, ((cascading_gaze_tick_amount * cascading_gaze_periodic_tick_rate) - (cascading_gaze_periodic_tick_rate * (iteration - 1))))

	// Clear the hitlist for every iteration.
	shared_hitlist = list()

	// If this iteration should be the last, set to TRUE.
	var/should_end = (iteration >= cascading_gaze_tick_amount)

	// Slash VFX will be bigger if we're on the last iteration
	var/matrix/vfx_matrix = matrix()
	if(should_end)
		vfx_matrix *= 1.8

	// Determine the base damage for this iteration. For the small hits it's the periodic damage, for the finisher it's the katana's force * a certain coeff.
	// Once we have this base damage; when dealing damage to an enemy, we will also further multiply it for that enemy, based on stacks of Gaze/Contempt they might have.
	var/base_damage = should_end ? (force * cascading_gaze_base_damage_coeff * force_multiplier) : (cascading_gaze_periodic_damage * force_multiplier)

	playsound(get_turf(user), (should_end ? cascading_gaze_finisher_sound : pick(cascading_gaze_hit_sounds_list)), 70, vary = !should_end, extrarange = 7)

	for(var/turf/T in cascading_gaze_affected_turfs)
		var/sent_visual = FALSE
		for(var/mob/living/L in T)
			if((L in shared_hitlist) || (L.stat >= DEAD))
				continue

			shared_hitlist |= L

			// Calculating damage based on gaze or contempt
			var/datum/status_effect/stacking/perversion_weapon_gaze/gazing = L.has_status_effect(STATUS_EFFECT_GAZE)
			var/datum/status_effect/display/perversion_weapon_contempt/contempting = L.has_status_effect(STATUS_EFFECT_CONTEMPT)
			var/extra_coeff = 1
			if(contempting)
				extra_coeff += (cascading_gaze_additive_damage_coeff_per_gaze * 7)
				contempting.refresh()
			else if(gazing)
				extra_coeff += (cascading_gaze_additive_damage_coeff_per_gaze * (gazing.stacks))
				gazing.refresh()

			// Blood VFX / Gibs on finisher. This has to be done before the damage to avoid issues with qdel'ing mobs.
			var/obj/effect/temp_visual/dir_setting/bloodsplatter/blood_vfx = new (T, pick(GLOB.alldirs))
			blood_vfx.transform = vfx_matrix
			var/victim_is_robotic = (L.mob_biotypes & MOB_ROBOTIC)
			if(victim_is_robotic)
				blood_vfx.color = COLOR_ALMOST_BLACK
			if(should_end)
				if(victim_is_robotic)
					new /obj/effect/gibspawner/scrap_metal(T)
				else
					new /obj/effect/gibspawner/generic/trash_disposal(T)

			// Deal the damage
			var/final_damage = base_damage * extra_coeff
			L.deal_damage(final_damage, damtype, source = user, flags = (should_end ? null : DAMAGE_FORCED), attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))

			if(!sent_visual)
				SendSlashDecoyVisual(T, user, TRUE, should_end)
			sent_visual = TRUE

	// We're done with this iteration. If this wasn't the finisher and we haven't gone over an arbitrary safety limit of iterations, do a do_after. If it succeeds, move to the next iteration.
	if(!should_end && iteration < 60 && do_after(user, cascading_gaze_periodic_tick_rate, timed_action_flags = (IGNORE_USER_LOC_CHANGE)))
		INVOKE_ASYNC(src, PROC_REF(DrawAttackLoop), user, iteration + 1)
	else
		DrawAttackEnd(user)
	return

// Called when we intercept a fell bullet/fell slug. Sends out some waves of shrapnel towards nearby enemies.
/obj/item/ego_weapon/perversion/weak/proc/CreateShrapnelSpray(turf/T, mob/living/carbon/human/owner, mob/living/carbon/human/fraud, intended_damage = 25, intended_damtype = RED_DAMAGE)
	// We'll do this a total of X times...
	for(var/i in 1 to cascading_gaze_shrapnel_amount["repeat"])
		playsound(T, 'sound/weapons/ego/perversion_shrapnel_scatter.ogg', 100, TRUE, 8)
		var/list/new_pellets = list()
		var/list/targets_list = list()

		// Gather valid targets into the targets_list for each iteration. This means each enemy can only be targeted once per 'wave' of shrapnel, but multiple times per call of this proc.
		for(var/mob/living/L in viewers(9, T))
			if(L.stat >= DEAD)
				continue
			targets_list |= L

		// Create Y pellets... their stats will be based on the fell bullet user's. So, if they fire a 2x portal empowered, 20% projectile damage modifier, MOBA ranged bullet, the shrapnel will have accordingly busted damage.
		for(var/j in 1 to cascading_gaze_shrapnel_amount["pellets"])
			new_pellets |= new /obj/projectile/ego_bullet/fell_shrapnel(T, fraud, owner, intended_damtype, intended_damage * 0.5, cascading_gaze_shrapnel_gaze_application)

		// For every pellet we created, try to target an enemy with it. If there are no valid enemies left to target, just fire the pellet in a random direction.
		for(var/obj/projectile/ego_bullet/fell_shrapnel/P in new_pellets)
			var/atom/target
			if(!length(targets_list))
				target = get_ranged_target_turf(T, pick(GLOB.alldirs), 9)
			else
				target = pick_n_take(targets_list)
			P.starting = T
			P.firer = fraud
			P.fired_from = T
			P.yo = target.y - T.y
			P.xo = target.x - T.x
			P.original = target
			P.preparePixelProjectile(target, T)
			P.fire()

		// Small delay between waves of shrapnel.
		sleep(0.3 SECONDS)


// This is an additional AoE caused when we strike the same target we previously hit with a lance lunge. It will hit in an AoE, including the main target, too. Deals damage and inflicts extra Gaze.
/obj/item/ego_weapon/perversion/weak/proc/LanceFollowupThrust(turf/target, mob/living/carbon/human/user)
	if(!target || !user)
		return

	// Assemble turfs to be hit
	var/turf/endpoint = get_ranged_target_turf_direct(user, target, lance_followup_range)
	if(!endpoint)
		return
	var/list/line = getline(get_step_towards(user, endpoint), endpoint)
	for(var/turf/T in line)
		for(var/turf/T2 in view(1, T))
			if(get_dist(T2, user) <= lance_followup_range)
				line |= T2

	line -= get_turf(user)

	// Damage calc
	var/final_damage = force * force_multiplier
	final_damage*=lance_followup_damage_coeff

	for(var/turf/T3 in line)
		new /obj/effect/temp_visual/perversion_thrust_visual(T3)

		for(var/mob/living/L in T3)
			if(L in shared_hitlist)
				continue
			if(L.stat >= DEAD)
				continue

			shared_hitlist |= L

			new /obj/effect/temp_visual/dir_setting/bloodsplatter(T3, pick(GLOB.alldirs))

			L.deal_damage(final_damage, damtype, source = user, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			if(L && L.health > 0)
				ApplyGaze(L, lance_followup_extra_gaze_stacks)

// Receives a line of turfs to hit with a slash. It will add both turfs and mobs into the hitlist to avoid repeating slashes.
/obj/item/ego_weapon/perversion/weak/proc/KatanaCleaveHit(list/turf_line, mob/living/carbon/human/user)
	if(!islist(turf_line) || !user)
		return

	// Damage calc
	var/base_damage = force * force_multiplier

	for(var/turf/T in turf_line)
		if(T in shared_hitlist)
			continue
		if(!isturf(T))
			continue

		shared_hitlist |= T
		var/obj/vfx = new /obj/effect/temp_visual/slice(T)
		vfx.color = swingcolor

		for(var/mob/living/L in T)
			if(L in shared_hitlist)
				continue
			if(L.stat >= DEAD)
				continue

			shared_hitlist |= L
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(T, pick(GLOB.alldirs))

			// We want to deal more damage if the enemy has Gaze or Contempt (7 stacks of Gaze).
			var/final_damage = base_damage
			var/datum/status_effect/display/perversion_weapon_contempt/contempting = L.has_status_effect(STATUS_EFFECT_CONTEMPT)
			if(contempting)
				final_damage *= (1 + (katana_additive_damage_coeff_per_gaze * 7))
			else
				var/datum/status_effect/stacking/perversion_weapon_gaze/gazing = L.has_status_effect(STATUS_EFFECT_GAZE)
				if(gazing)
					final_damage *= (1 + (katana_additive_damage_coeff_per_gaze * gazing.stacks))

			L.deal_damage(final_damage, damtype, source = user, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))

#undef STATUS_EFFECT_GAZE
#undef STATUS_EFFECT_CONTEMPT
#undef COLOR_PERVERSION_LANCE
#undef COLOR_PERVERSION_KATANA
