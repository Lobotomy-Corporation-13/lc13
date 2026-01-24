//Copy of the baton
/obj/item/ego_weapon/city/zweibaton/protection
	name = "city protection baton"
	desc = "A riot club used by the local protection."
	special = "Attack a human to stun them after a period of time."
	icon_state = "protection_baton"
	inhand_icon_state = "protection_baton"
	force = 30
	attribute_requirements = list()



//Bad indexstuff
/obj/item/ego_weapon/city/fakeindex
	name = "index recruit sword"
	desc = "A sheathed sword used by index recruits."
	special = "Hit the bodypart you're told to target to gain unlock stacks. At 3 stacks, this weapon switches to PALE damage. Missing the target bodypart removes 1 stack. Attacking insane targets always grants a stack and deals PALE damage."
	icon_state = "index"
	inhand_icon_state = "index"
	force = 20
	damtype = WHITE_DAMAGE

	attack_verb_continuous = list("smacks", "hammers", "beats")
	attack_verb_simple = list("smack", "hammer", "beat")
	var/target_bodypart
	var/unlock_stacks = 0
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 60,
	)

/obj/item/ego_weapon/city/fakeindex/attack(mob/living/target, mob/living/user)
	// Handle bodypart targeting mechanic for humans
	if(ishuman(target))
		var/mob/living/carbon/human/H = target

		// Special handling for insane targets
		if(H.sanity_lost)
			// Always gain a stack when hitting insane targets
			if(unlock_stacks < 3)
				unlock_stacks++
				to_chat(user, span_nicegreen("You strike the insane target! Unlock stacks: [unlock_stacks]/3"))
			// Temporarily switch to PALE damage for this attack
			var/original_damtype = damtype
			damtype = PALE_DAMAGE
			. = ..()
			// Restore original damage type after attack
			if(unlock_stacks < 3)
				damtype = original_damtype
			return

		// Set correct damage type based on current unlock stacks BEFORE processing attack
		if(unlock_stacks >= 3)
			damtype = PALE_DAMAGE
		else
			damtype = WHITE_DAMAGE

		// Determine which bodypart was actually hit
		var/obj/item/bodypart/affecting = H.get_bodypart(ran_zone(user.zone_selected))

		if(affecting)
			var/hit_zone = affecting.body_zone

			// Check if we have a target bodypart - mechanic continues even after unlocking
			if(target_bodypart)
				// Check if they hit the correct bodypart
				if(hit_zone == target_bodypart)
					// Correct hit! Gain a stack (up to 3 max)
					if(unlock_stacks < 3)
						unlock_stacks++
						to_chat(user, span_nicegreen("You strike the [affecting.name] perfectly! Unlock stacks: [unlock_stacks]/3"))

						// Check if we've reached 3 stacks
						if(unlock_stacks >= 3)
							to_chat(user, span_userdanger("Your weapon unlocks, now dealing PALE damage!"))
					else
						to_chat(user, span_nicegreen("You strike the [affecting.name] perfectly!"))
				else
					// Wrong bodypart! Lose 1 stack
					if(unlock_stacks > 0)
						unlock_stacks--
						to_chat(user, span_danger("You missed the target bodypart! Lost 1 unlock stack. ([unlock_stacks]/3)"))
						if(unlock_stacks < 3)
							to_chat(user, span_warning("Your weapon has been locked back to WHITE damage!"))

			// Always pick a new random target bodypart for the next attack
			var/list/possible_zones = list(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
			target_bodypart = pick(possible_zones)

			// Get the bodypart name for display
			var/obj/item/bodypart/target_part = H.get_bodypart(target_bodypart)
			if(target_part)
				to_chat(user, span_warning("Target their [target_part.name] next!"))

	return ..()

//proxy randomizer
/obj/effect/spawner/lootdrop/proxy
	name = "proxy weapon spawner"
	lootdoubles = FALSE

	loot = list(
		/obj/item/ego_weapon/city/fakeindex/proxy = 1,
		/obj/item/ego_weapon/city/fakeindex/proxy/spear = 1,
		/obj/item/ego_weapon/city/fakeindex/proxy/knife = 1,
	)

/obj/item/ego_weapon/city/fakeindex/proxy
	name = "index longsword"
	desc = "A long sword used by index proxies."
	icon_state = "indexlongsword"
	inhand_icon_state = "indexlongsword"
	attack_verb_continuous = list("slices", "slashes", "stabs")
	attack_verb_simple = list("slice", "slash", "stab")
	hitsound = 'sound/weapons/bladeslice.ogg'
	force = 45
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 80,
	)

//Just gonna set this to the big proxy weapon for requirement reasons
/obj/item/ego_weapon/city/fakeindex/proxy/spear
	name = "index spear"
	desc = "A spear used by index proxies."
	icon_state = "indexspear"
	inhand_icon_state = "indexspear"
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left_64x64.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right_64x64.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	hitsound = 'sound/weapons/fixer/generic/nail1.ogg'
	attack_speed = 1.2
	reach = 2
	stuntime = 5

/obj/item/ego_weapon/city/fakeindex/proxy/knife
	name = "index dagger"
	desc = "A dagger used by index proxies."
	icon_state = "indexdagger"
	inhand_icon_state = "indexdagger"
	force = 30
	attack_speed = 0.5


//Fockin massive sword
/obj/item/ego_weapon/city/fakeindex/yan
	name = "index greatsword"
	desc = "A greatsword sword used by a specific index messenger."
	icon_state = "indexgreatsword"
	inhand_icon_state = "indexgreatsword"
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left_64x64.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right_64x64.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	attack_verb_continuous = list("cleaves", "cuts")
	attack_verb_simple = list("cleaves", "cuts")
	hitsound = 'sound/weapons/fixer/generic/finisher1.ogg'
	force = 70
	attack_speed = 2
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100,
	)


//Blade Lineage
/obj/item/ego_weapon/city/bladelineage/city
	special = "Use this weapon in hand to immobilize yourself for 3 seconds and deal 3x damage on the next attack within 5 seconds. This empowered attack also deals 2% more damage per 1% of your missing HP, on top of the 3x damage."
	force = 30
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 60,
	)
	multiplier = 3

//Kurokumo
/obj/item/ego_weapon/city/kurokumo/weak
	force = 52
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 60,
	)

//Thumb
/obj/item/ego_weapon/ranged/city/thumb/city
	force = 35
	projectile_damage_multiplier = 1
	projectile_path = /obj/projectile/ego_bullet/citythumb // does 30 damage (odd, there's no force mod on this one)
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 60,
	)

/obj/projectile/ego_bullet/citythumb
	damage = 30
	damage_type = RED_DAMAGE
	armour_penetration = 50 //50% True Damage. Ignores 50% of armor
	ignore_bulletproof = TRUE

//Capo
/obj/item/ego_weapon/ranged/city/thumb/capo/city
	force = 44
	projectile_damage_multiplier = 1
	projectile_path = /obj/projectile/ego_bullet/citythumb/capo // does 30 damage (odd, there's no force mod on this one)
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 80,
	)

/obj/projectile/ego_bullet/citythumb/capo
	damage = 45

//Sottocapo
/obj/item/ego_weapon/ranged/city/thumb/sottocapo/city
	force = 10	//It's a pistol
	projectile_damage_multiplier = 1
	projectile_path = /obj/projectile/ego_bullet/citythumb/sottocapo // total 80 AP damage
	pellets = 8
	variance = 16
	reloadtime = 7 SECONDS // it is a bit stronger, but requires a bit longer reload time. (either hit with it or step back for downtime)
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100,
	)

/obj/projectile/ego_bullet/citythumb/sottocapo
	damage = 10

//wepaons are kinda uninteresting
/obj/item/ego_weapon/city/thumbmelee/weak
	force = 52
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 80,
	)

/obj/item/ego_weapon/city/thumbcane/weak
	force = 70
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100,
	)

/obj/item/clothing/suit/armor/ego_gear/city/thumb/city
	name = "thumb soldato armor"
	desc = "Armor worn by thumb grunts."
	icon_state = "thumb"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 30, BLACK_DAMAGE = 30, PALE_DAMAGE = 30)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)

/obj/item/clothing/suit/armor/ego_gear/city/thumb_capo/city
	name = "thumb capo armor"
	desc = "Armor worn by thumb capos."
	icon_state = "capo"
	armor = list(RED_DAMAGE = 50, WHITE_DAMAGE = 40, BLACK_DAMAGE = 40, PALE_DAMAGE = 40)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)


/obj/item/clothing/suit/armor/ego_gear/city/ncorp/weak
	name = "nagel und hammer armor"
	desc = "Armor worn by Nagel Und Hammer."
	icon_state = "ncorp"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 20, BLACK_DAMAGE = 20, PALE_DAMAGE = 50)
	attribute_requirements = list()

/obj/item/clothing/suit/armor/ego_gear/city/kcorp_l1/weak
	attribute_requirements = list()

//Index Apprentice Chains - granted by armor
/obj/item/ego_weapon/city/index_apprentice_chains
	name = "index apprentice chains"
	desc = "Chains granted by the index proxy apprentice armor."
	special = "Fulfill your prescript by slaying your target 3 times to transform. Use in hand to receive a prescript. Click at range to leap attack (grants 1 prescript completion). Hit the correct bodypart on humans to gain progress. Reaching half health also triggers the transformation."
	icon = 'icons/obj/index_sora_base.dmi'
	icon_state = "apprentice_chains"
	lefthand_file = 'icons/obj/index_sora_worn.dmi'
	righthand_file = 'icons/obj/index_sora_worn.dmi'
	inhand_icon_state = "apprentice_chains"
	force = 50
	damtype = RED_DAMAGE
	attack_verb_continuous = list("lashes", "whips", "strikes")
	attack_verb_simple = list("lash", "whip", "strike")

	/// Current prescript target (breached abnormality)
	var/mob/living/simple_animal/hostile/abnormality/prescript_target
	/// Linked armor (stores prescript_completions)
	var/obj/item/clothing/suit/armor/ego_gear/index_proxy/apprentice/linked_armor
	/// Leap attack cooldown tracker
	var/leap_cooldown
	/// Leap attack cooldown time
	var/leap_cooldown_time = 8 SECONDS
	/// Leap attack range
	var/leap_range = 8
	/// Can attack flag for leap
	var/can_attack = TRUE
	/// Current target bodypart for humans
	var/target_bodypart
	attribute_requirements = list()

/obj/item/ego_weapon/city/index_apprentice_chains/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, "index_chains")

/obj/item/ego_weapon/city/index_apprentice_chains/Destroy()
	if(linked_armor)
		linked_armor.chains_weapon = null
		linked_armor = null
	return ..()

/obj/item/ego_weapon/city/index_apprentice_chains/AllowDrop()
	return FALSE

/obj/item/ego_weapon/city/index_apprentice_chains/equip_to_best_slot(mob/M, check_hand = TRUE)
	to_chat(M, span_warning("The chains refuse to leave your grasp!"))
	return FALSE

/obj/item/ego_weapon/city/index_apprentice_chains/mob_can_equip(mob/living/M, mob/living/equipper, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE)
	if(slot != ITEM_SLOT_HANDS)
		to_chat(M, span_warning("The chains refuse to leave your grasp!"))
		return FALSE
	return ..()

/obj/item/ego_weapon/city/index_apprentice_chains/canStrip(mob/who)
	return FALSE

/obj/item/ego_weapon/city/index_apprentice_chains/examine(mob/user)
	. = ..()
	var/completions = linked_armor ? linked_armor.prescript_completions : 0
	. += span_notice("Prescript completions: [completions]/3")
	if(prescript_target)
		if(prescript_target.stat == DEAD)
			. += span_warning("Your prescript target has died. Use in hand to get a new one.")
		else
			. += span_warning("Current prescript target: [prescript_target]")

/obj/item/ego_weapon/city/index_apprentice_chains/attack_self(mob/user)
	. = ..()
	// Check if we have a prescript target
	if(prescript_target)
		if(prescript_target.stat == DEAD)
			prescript_target = null
			to_chat(user, span_notice("Your prescript has died. Use it in hand again to receive a new prescript."))
		else
			to_chat(user, span_notice("Your prescript target is [prescript_target]. Slay them with this weapon!"))
		return

	// Get a new prescript target
	var/list/breached = list()
	for(var/mob/living/simple_animal/hostile/abnormality/B in GLOB.abnormality_mob_list)
		if(!(B.status_flags & GODMODE) && (B.stat != DEAD))
			breached += B
	if(LAZYLEN(breached))
		prescript_target = pick(breached)
		to_chat(user, span_userdanger("Your prescript target is [prescript_target]. Slay them with this weapon!"))
	else
		to_chat(user, span_notice("There are no prescripts available."))

/obj/item/ego_weapon/city/index_apprentice_chains/attack(mob/living/target, mob/living/user)
	if(!can_attack)
		return
	var/was_living = (target.stat != DEAD)

	// Bodypart targeting for humans
	if(ishuman(target))
		var/mob/living/carbon/human/H = target

		// Determine which bodypart was actually hit
		var/obj/item/bodypart/affecting = H.get_bodypart(ran_zone(user.zone_selected))

		if(affecting && target_bodypart)
			var/hit_zone = affecting.body_zone

			// Check if they hit the correct bodypart
			if(hit_zone == target_bodypart)
				// Correct hit! Gain a prescript completion
				if(linked_armor && linked_armor.prescript_completions < 3)
					linked_armor.prescript_completions++
					to_chat(user, span_nicegreen("You strike the [affecting.name] perfectly! Prescript progress: [linked_armor.prescript_completions]/3"))
					playsound(get_turf(user), 'sound/abnormalities/onesin/bless.ogg', 50, 0, 4)
					check_transform(user)
			else
				// Wrong bodypart! Lose 1 completion
				if(linked_armor && linked_armor.prescript_completions > 0)
					linked_armor.prescript_completions--
					to_chat(user, span_danger("You missed the target bodypart! Lost 1 prescript progress. ([linked_armor.prescript_completions]/3)"))

		// Always pick a new random target bodypart for the next attack
		var/list/possible_zones = list(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
		target_bodypart = pick(possible_zones)

		// Get the bodypart name for display
		var/obj/item/bodypart/target_part = H.get_bodypart(target_bodypart)
		if(target_part)
			to_chat(user, span_warning("Target their [target_part.name] next!"))

	. = ..()

	// Check if we killed our prescript target
	if(target.stat == DEAD && target == prescript_target && was_living)
		prescript_complete(user)

/obj/item/ego_weapon/city/index_apprentice_chains/proc/prescript_complete(mob/living/user)
	prescript_target = null
	if(linked_armor)
		linked_armor.prescript_completions++
		to_chat(user, span_userdanger("You have completed your prescript! ([linked_armor.prescript_completions]/3)"))
	playsound(get_turf(user), 'sound/abnormalities/onesin/bless.ogg', 50, 0, 4)
	check_transform(user)

/obj/item/ego_weapon/city/index_apprentice_chains/proc/check_transform(mob/living/user)
	if(linked_armor && linked_armor.prescript_completions >= 3)
		linked_armor.transform_to_procuration(user)

// Leap attack - click at range
/obj/item/ego_weapon/city/index_apprentice_chains/afterattack(atom/target, mob/living/user, proximity_flag, params)
	. = ..()
	if(proximity_flag)
		return
	if(!can_attack)
		return
	if(!isliving(target))
		return
	var/mob/living/A = target
	if(leap_cooldown > world.time)
		to_chat(user, span_warning("Your leap is still recharging!"))
		return
	if(!can_see(user, A, leap_range))
		to_chat(user, span_warning("Target is too far or out of sight!"))
		return
	if(do_after(user, 5, src))
		leap_cooldown = world.time + leap_cooldown_time
		playsound(src, 'sound/abnormalities/ichthys/jump.ogg', 50, FALSE, -1)
		animate(user, alpha = 1, pixel_x = 0, pixel_z = 16, time = 0.1 SECONDS)
		user.pixel_z = 16
		sleep(0.5 SECONDS)
		if(QDELETED(user))
			return
		else if(QDELETED(A) || !can_see(user, A, leap_range))
			animate(user, alpha = 255, pixel_x = 0, pixel_z = -16, time = 0.1 SECONDS)
			user.pixel_z = 0
			return
		for(var/i in 2 to get_dist(user, A))
			step_towards(user, A)
		if(get_dist(user, A) < 2)
			LeapAttack(A, user)
		to_chat(user, span_warning("You leap towards [A]!"))
		animate(user, alpha = 255, pixel_x = 0, pixel_z = -16, time = 0.1 SECONDS)
		user.pixel_z = 0

/obj/item/ego_weapon/city/index_apprentice_chains/proc/LeapAttack(atom/A, mob/living/user)
	A.attackby(src, user)
	can_attack = FALSE
	addtimer(CALLBACK(src, PROC_REF(LeapReset)), 20)
	// Grant one prescript completion for leap attack
	if(linked_armor)
		linked_armor.prescript_completions++
		to_chat(user, span_userdanger("Your leap grants you prescript progress! ([linked_armor.prescript_completions]/3)"))
	playsound(get_turf(user), 'sound/abnormalities/onesin/bless.ogg', 50, 0, 4)
	check_transform(user)

/obj/item/ego_weapon/city/index_apprentice_chains/proc/LeapReset()
	can_attack = TRUE

//Effloresced E.G.O :: Procuration - upgraded weapon from chains
/obj/item/ego_weapon/city/index_procuration
	name = "Effloresced E.G.O :: Procuration"
	desc = "H-having such an unshakable conviction about what's good and evil is nothing short of amazing, he said..."
	special = "Click at range to dash attack. Dashing costs 1 charge (regain 1 charge every 10 seconds). Dashing applies a 2 second slowdown. Dashing while slowed resets the slowdown timer."
	icon = 'icons/obj/index_sora_ego_base.dmi'
	icon_state = "procuration"
	lefthand_file = 'icons/obj/index_sora_ego_worn.dmi'
	righthand_file = 'icons/obj/index_sora_ego_worn.dmi'
	inhand_icon_state = "procuration"
	force = 30
	damtype = PALE_DAMAGE
	attack_speed = 0.5
	attack_verb_continuous = list("slashes", "rends", "tears")
	attack_verb_simple = list("slash", "rend", "tear")
	attribute_requirements = list()

	var/obj/item/clothing/suit/armor/ego_gear/index_proxy/apprentice/linked_armor
	/// Current dash charges
	var/dash_charges = 3
	/// Maximum dash charges
	var/max_dash_charges = 3
	/// Time between dashes (cooldown)
	var/dash_cooldown_time = 1 SECONDS
	/// Dash cooldown tracker
	var/dash_cooldown
	/// Time to regain one charge
	var/dash_recharge_time = 10 SECONDS
	/// Timer ID for charge regeneration
	var/recharge_timer_id
	/// Dash range
	var/dash_range = 8
	/// Whether user is currently slowed from dashing
	var/is_slowed = FALSE
	/// Timer ID for slowdown removal
	var/slowdown_timer_id

/obj/item/ego_weapon/city/index_procuration/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, "index_procuration")

/obj/item/ego_weapon/city/index_procuration/Destroy()
	if(slowdown_timer_id)
		deltimer(slowdown_timer_id)
	if(recharge_timer_id)
		deltimer(recharge_timer_id)
	if(linked_armor)
		linked_armor.procuration_weapon = null
		linked_armor = null
	return ..()

/obj/item/ego_weapon/city/index_procuration/examine(mob/user)
	. = ..()
	. += span_notice("Dash charges: [dash_charges]/[max_dash_charges]")

/obj/item/ego_weapon/city/index_procuration/AllowDrop()
	return FALSE

/obj/item/ego_weapon/city/index_procuration/equip_to_best_slot(mob/M, check_hand = TRUE)
	to_chat(M, span_warning("The weapon refuses to leave your grasp!"))
	return FALSE

/obj/item/ego_weapon/city/index_procuration/mob_can_equip(mob/living/M, mob/living/equipper, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE)
	if(slot != ITEM_SLOT_HANDS)
		to_chat(M, span_warning("The weapon refuses to leave your grasp!"))
		return FALSE
	return ..()

/obj/item/ego_weapon/city/index_procuration/canStrip(mob/who)
	return FALSE

// Dash attack - click at range
/obj/item/ego_weapon/city/index_procuration/afterattack(atom/target, mob/living/user, proximity_flag, params)
	. = ..()
	if(proximity_flag)
		return
	if(dash_cooldown > world.time)
		to_chat(user, span_warning("You must wait before dashing again!"))
		return
	if(dash_charges <= 0)
		to_chat(user, span_warning("You have no dash charges remaining! ([dash_charges]/[max_dash_charges])"))
		return
	if(!can_see(user, target, dash_range))
		to_chat(user, span_warning("Target is too far or out of sight!"))
		return

	// Consume a charge and start cooldown
	dash_charges--
	dash_cooldown = world.time + dash_cooldown_time

	// Start recharge timer if not already running
	if(!recharge_timer_id)
		recharge_timer_id = addtimer(CALLBACK(src, PROC_REF(recharge_dash)), dash_recharge_time, TIMER_STOPPABLE)

	// Perform dash
	var/turf/target_turf = get_turf(user)
	var/list/line_turfs = list(target_turf)
	var/list/mobs_to_hit = list()

	for(var/turf/T in getline(user, get_ranged_target_turf_direct(user, target, dash_range)))
		if(T.density)
			break
		target_turf = T
		line_turfs += T

	user.forceMove(target_turf)

	// Visual effects and damage
	for(var/i = 1 to line_turfs.len)
		var/turf/T = line_turfs[i]
		if(!istype(T))
			continue
		for(var/mob/living/L in view(1, T))
			mobs_to_hit |= L
		var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(T, user)
		D.alpha = min(150 + i*15, 255)
		animate(D, alpha = 0, time = 2 + i*2)
		for(var/turf/TT in range(T, 1))
			new /obj/effect/temp_visual/small_smoke/halfsecond(TT)
		playsound(user, 'sound/weapons/bladeslice.ogg', 50, 1)

	// Damage mobs in path
	for(var/mob/living/L in mobs_to_hit)
		if(user.faction_check_mob(L))
			continue
		if(L.status_flags & GODMODE)
			continue
		visible_message(span_boldwarning("[user] slashes through [L]!"))
		new /obj/effect/temp_visual/cleave(get_turf(L))
		L.deal_damage(force, PALE_DAMAGE, user, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))

	to_chat(user, span_warning("You dash forward!"))

	// Apply slowdown
	ApplyDashSlowdown(user)

/obj/item/ego_weapon/city/index_procuration/proc/ApplyDashSlowdown(mob/living/user)
	// If already slowed, reset the timer
	if(is_slowed && slowdown_timer_id)
		deltimer(slowdown_timer_id)
		to_chat(user, span_danger("Your slowdown timer has been reset!"))
	else
		// Apply new slowdown
		is_slowed = TRUE
		user.add_movespeed_modifier(/datum/movespeed_modifier/procuration_dash)
		to_chat(user, span_danger("The dash slows you down!"))

	// Set timer to remove slowdown
	slowdown_timer_id = addtimer(CALLBACK(src, PROC_REF(RemoveDashSlowdown), user), 2 SECONDS, TIMER_STOPPABLE)

/obj/item/ego_weapon/city/index_procuration/proc/RemoveDashSlowdown(mob/living/user)
	is_slowed = FALSE
	slowdown_timer_id = null
	if(user && !QDELETED(user))
		user.remove_movespeed_modifier(/datum/movespeed_modifier/procuration_dash)
		to_chat(user, span_notice("Your movement returns to normal."))

/obj/item/ego_weapon/city/index_procuration/proc/recharge_dash()
	recharge_timer_id = null
	if(dash_charges < max_dash_charges)
		dash_charges++
		// If still not at max, start another recharge timer
		if(dash_charges < max_dash_charges)
			recharge_timer_id = addtimer(CALLBACK(src, PROC_REF(recharge_dash)), dash_recharge_time, TIMER_STOPPABLE)

/datum/movespeed_modifier/procuration_dash
	multiplicative_slowdown = 1.5

//Ability for summoning chains
/obj/effect/proc_holder/ability/apprentice_chains
	name = "Summon Chains"
	desc = "Summon or dismiss the index apprentice chains."
	action_icon = 'icons/mob/actions/actions_ecult.dmi'
	action_icon_state = "mansus_link"
	base_icon_state = "mansus_link"
	cooldown_time = 5 SECONDS

/obj/effect/proc_holder/ability/apprentice_chains/Perform(target, mob/user)
	if(!ishuman(user))
		return ..()

	var/mob/living/carbon/human/H = user
	var/obj/item/clothing/suit/armor/ego_gear/index_proxy/apprentice/armor = H.get_item_by_slot(ITEM_SLOT_OCLOTHING)

	if(!istype(armor))
		to_chat(user, span_warning("You must be wearing the apprentice armor!"))
		return ..()

	// If procuration exists, dismiss it and reset progress
	if(armor.procuration_weapon)
		armor.remove_procuration(reset_progress = TRUE)
		to_chat(user, span_notice("The weapon dissipates and your progress resets."))
		playsound(get_turf(user), 'sound/abnormalities/onesin/bless.ogg', 50, 0, 4)
		return ..()

	// Toggle chains
	if(armor.chains_weapon)
		armor.remove_chains(reset_progress = TRUE)
		to_chat(user, span_notice("The chains dissipate and your progress resets."))
		playsound(get_turf(user), 'sound/abnormalities/onesin/bless.ogg', 50, 0, 4)
	else
		armor.grant_chains(H)

	return ..()
