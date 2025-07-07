
/obj/effect/proc_holder/spell/aimed
	name = "aimed projectile spell"
	base_icon_state = "projectile"
	var/projectile_type = /obj/projectile/magic/teleport
	var/deactive_msg = "You discharge your projectile..."
	var/active_msg = "You charge your projectile!"
	var/active_icon_state = "projectile"
	var/list/projectile_var_overrides = list()
	var/projectile_amount = 1	//Projectiles per cast.
	var/current_amount = 0	//How many projectiles left.
	var/projectiles_per_fire = 1		//Projectiles per fire. Probably not a good thing to use unless you override ready_projectile().

/obj/effect/proc_holder/spell/aimed/Click()
	var/mob/living/user = usr
	if(!istype(user))
		return
	var/msg
	if(!can_cast(user))
		msg = span_warning("You can no longer cast [name]!")
		remove_ranged_ability(msg)
		return
	if(active)
		msg = span_notice("[deactive_msg]")
		if(charge_type == "recharge")
			var/refund_percent = current_amount/projectile_amount
			charge_counter = charge_max * refund_percent
			start_recharge()
		remove_ranged_ability(msg)
		on_deactivation(user)
	else
		msg = span_notice("[active_msg] <B>Left-click to shoot it at a target!</B>")
		current_amount = projectile_amount
		add_ranged_ability(user, msg, TRUE)
		on_activation(user)

/obj/effect/proc_holder/spell/aimed/proc/on_activation(mob/user)
	return

/obj/effect/proc_holder/spell/aimed/proc/on_deactivation(mob/user)
	return

/obj/effect/proc_holder/spell/aimed/update_icon()
	if(!action)
		return
	action.button_icon_state = "[base_icon_state][active]"
	action.UpdateButtonIcon()

/obj/effect/proc_holder/spell/aimed/InterceptClickOn(mob/living/requester, params, atom/target)
	if(..())
		return FALSE
	var/ran_out = (current_amount <= 0)
	if(!cast_check(!ran_out, ranged_ability_user))
		remove_ranged_ability()
		return FALSE
	var/list/targets = list(target)
	perform(targets, ran_out, user = ranged_ability_user)
	return TRUE

/obj/effect/proc_holder/spell/aimed/cast(list/targets, mob/living/user)
	var/target = targets[1]
	var/turf/T = user.loc
	var/turf/U = get_step(user, user.dir) // Get the tile infront of the move, based on their direction
	if(!isturf(U) || !isturf(T))
		return FALSE
	fire_projectile(user, target)
	user.newtonian_move(get_dir(U, T))
	if(current_amount <= 0)
		remove_ranged_ability() //Auto-disable the ability once you run out of bullets.
		charge_counter = 0
		start_recharge()
		on_deactivation(user)
	return TRUE

/obj/effect/proc_holder/spell/aimed/proc/fire_projectile(mob/living/user, atom/target)
	current_amount--
	var/list/fired_projs = list()
	for(var/i in 1 to projectiles_per_fire)
		var/obj/projectile/P = new projectile_type(user.loc)
		P.firer = user
		P.preparePixelProjectile(target, user)
		for(var/V in projectile_var_overrides)
			if(P.vars[V])
				P.vv_edit_var(V, projectile_var_overrides[V])
		ready_projectile(P, target, user, i)
		P.fire()
		fired_projs += P
	return fired_projs

/obj/effect/proc_holder/spell/aimed/proc/ready_projectile(obj/projectile/P, atom/target, mob/user, iteration)
	return

/obj/effect/proc_holder/spell/aimed/lightningbolt
	name = "Lightning Bolt"
	desc = "Fire a lightning bolt at your foes! It will jump between targets, but can't knock them down."
	school = SCHOOL_EVOCATION
	charge_max = 100
	clothes_req = FALSE
	invocation = "P'WAH, UNLIM'TED P'WAH"
	invocation_type = INVOCATION_SHOUT
	cooldown_min = 20
	base_icon_state = "lightning"
	action_icon_state = "lightning0"
	sound = 'sound/magic/lightningbolt.ogg'
	active = FALSE
	projectile_var_overrides = list("zap_range" = 15, "zap_power" = 20000, "zap_flags" = ZAP_MOB_DAMAGE)
	active_msg = "You energize your hands with arcane lightning!"
	deactive_msg = "You let the energy flow out of your hands back into yourself..."
	projectile_type = /obj/projectile/magic/aoe/lightning

/obj/effect/proc_holder/spell/aimed/fireball
	name = "Fireball"
	desc = "This spell fires an explosive fireball at a target."
	school = SCHOOL_EVOCATION
	charge_max = 60
	clothes_req = FALSE
	invocation = "ONI SOMA"
	invocation_type = INVOCATION_SHOUT
	range = 20
	cooldown_min = 20 //10 deciseconds reduction per rank
	projectile_type = /obj/projectile/magic/aoe/fireball
	base_icon_state = "fireball"
	action_icon_state = "fireball0"
	sound = 'sound/magic/fireball.ogg'
	active_msg = "You prepare to cast your fireball spell!"
	deactive_msg = "You extinguish your fireball... for now."
	active = FALSE

/obj/effect/proc_holder/spell/aimed/fireball/fire_projectile(list/targets, mob/living/user)
	var/range = 6 + 2*spell_level
	projectile_var_overrides = list("range" = range)
	return ..()

/obj/effect/proc_holder/spell/aimed/spell_cards
	name = "Spell Cards"
	desc = "Blazing hot rapid-fire homing cards. Send your foes to the shadow realm with their mystical power!"
	school = SCHOOL_EVOCATION
	charge_max = 50
	clothes_req = FALSE
	invocation = "Sigi'lu M'Fan 'Tasia"
	invocation_type = INVOCATION_SHOUT
	range = 40
	cooldown_min = 10
	projectile_amount = 5
	projectiles_per_fire = 7
	projectile_type = /obj/projectile/spellcard
	base_icon_state = "spellcard"
	action_icon_state = "spellcard0"
	var/datum/weakref/current_target_weakref
	var/projectile_turnrate = 10
	var/projectile_pixel_homing_spread = 32
	var/projectile_initial_spread_amount = 30
	var/projectile_location_spread_amount = 12
	var/datum/component/lockon_aiming/lockon_component
	ranged_clickcd_override = TRUE

/obj/effect/proc_holder/spell/aimed/spell_cards/on_activation(mob/M)
	QDEL_NULL(lockon_component)
	lockon_component = M.AddComponent(/datum/component/lockon_aiming, 5, typecacheof(list(/mob/living)), 1, null, CALLBACK(src, PROC_REF(on_lockon_component)))

/obj/effect/proc_holder/spell/aimed/spell_cards/proc/on_lockon_component(list/locked_weakrefs)
	if(!length(locked_weakrefs))
		current_target_weakref = null
		return
	current_target_weakref = locked_weakrefs[1]
	var/atom/A = current_target_weakref.resolve()
	if(A)
		var/mob/M = lockon_component.parent
		M.face_atom(A)

/obj/effect/proc_holder/spell/aimed/spell_cards/on_deactivation(mob/M)
	QDEL_NULL(lockon_component)

/obj/effect/proc_holder/spell/aimed/spell_cards/ready_projectile(obj/projectile/P, atom/target, mob/user, iteration)
	if(current_target_weakref)
		var/atom/A = current_target_weakref.resolve()
		if(A && get_dist(A, user) < 7)
			P.homing_turn_speed = projectile_turnrate
			P.homing_inaccuracy_min = projectile_pixel_homing_spread
			P.homing_inaccuracy_max = projectile_pixel_homing_spread
			P.set_homing_target(current_target_weakref.resolve())
	var/rand_spr = rand()
	var/total_angle = projectile_initial_spread_amount * 2
	var/adjusted_angle = total_angle - ((projectile_initial_spread_amount / projectiles_per_fire) * 0.5)
	var/one_fire_angle = adjusted_angle / projectiles_per_fire
	var/current_angle = iteration * one_fire_angle * rand_spr - (projectile_initial_spread_amount / 2)
	P.pixel_x = rand(-projectile_location_spread_amount, projectile_location_spread_amount)
	P.pixel_y = rand(-projectile_location_spread_amount, projectile_location_spread_amount)
	P.preparePixelProjectile(target, user, null, current_angle)

/obj/effect/proc_holder/spell/aimed/fairy
	name = "Fairy"
	desc = "Fire a line of damaging essence using power of the Fairy singularity."
	school = SCHOOL_EVOCATION
	charge_max = 100
	clothes_req = FALSE
	projectile_amount = 5
	invocation_type = "none"
	base_icon_state = "lightning"
	action_icon_state = "lightning0"
	sound = 'sound/magic/arbiter/fairy.ogg'
	active_msg = "You activate the power of Fairy singularity!"
	deactive_msg = "You let the energy flow out of your hands back into its storage space..."
	projectile_type = /obj/projectile/beam/fairy
	var/damage_type = BLACK_DAMAGE

/obj/effect/proc_holder/spell/aimed/fairy/fire_projectile(mob/living/user, atom/target)
	current_amount--
	var/list/fired_projs = list()
	for(var/i in 1 to projectiles_per_fire)
		var/obj/projectile/P = new projectile_type(user.loc)
		P.damage_type = damage_type
		if(damage_type == PALE_DAMAGE)
			P.damage = 30
		P.firer = user
		P.preparePixelProjectile(target, user)
		for(var/V in projectile_var_overrides)
			if(P.vars[V])
				P.vv_edit_var(V, projectile_var_overrides[V])
		ready_projectile(P, target, user, i)
		P.fire()
		fired_projs += P
	return fired_projs

/obj/effect/proc_holder/spell/aimed/pillar
	name = "Pillar"
	desc = "Fire a heavy pillar that will initiate meltdown process for each console it hits and throw enemies around."
	school = SCHOOL_EVOCATION
	charge_max = 300
	clothes_req = FALSE
	invocation_type = "none"
	base_icon_state = "immrod"
	action_icon_state = "immrod"
	sound = 'sound/magic/arbiter/pillar_start.ogg'
	active_msg = "You prepare the pillar."
	deactive_msg = "You remove the pillar from this plane, for now..."
	projectile_type = /obj/projectile/magic/aoe/pillar
	var/fire_delay = 1 SECONDS
	var/damage_type = BLACK_DAMAGE

/obj/effect/proc_holder/spell/aimed/pillar/fire_projectile(mob/living/user, atom/target)
	current_amount--
	var/list/fired_projs = list()
	switch(damage_type)
		if(RED_DAMAGE)
			projectile_type = /obj/projectile/magic/aoe/pillar/red
		if(WHITE_DAMAGE)
			projectile_type = /obj/projectile/magic/aoe/pillar/white
		if(BLACK_DAMAGE)
			projectile_type = /obj/projectile/magic/aoe/pillar
		if(PALE_DAMAGE)
			projectile_type = /obj/projectile/magic/aoe/pillar/pale
	for(var/i in 1 to projectiles_per_fire)
		var/obj/projectile/P = new projectile_type(get_turf(user))
		P.firer = user
		P.preparePixelProjectile(target, user)
		for(var/V in projectile_var_overrides)
			if(P.vars[V])
				P.vv_edit_var(V, projectile_var_overrides[V])
		ready_projectile(P, target, user, i)
		addtimer(CALLBACK (P, TYPE_PROC_REF(/obj/projectile, fire)), fire_delay)
		fired_projs += P
	return fired_projs

/// It's just Fairy, with a different icon and slight stat differences. You get less Thin Lines, they do more damage, they recharge faster.
/obj/effect/proc_holder/spell/aimed/fairy/thin_line
	name = "Thin Line"
	desc = "Fire a thin line of damaging essence, dealing the damage type corresponding to your active singularity."
	projectile_amount = 4
	charge_max = 80

/// Replaces Pillar. Loses meltdown capability, in exchange it can be used more often. Rather than firing a projectile, it's an extremely long and piercing line AOE.
/// You need to stand still for line_telegraph_duration in order to fire. Moving or being interrupted will refund the spell though.
/obj/effect/proc_holder/spell/aimed/thick_line
	name = "Thick Line"
	desc = "Manifest a powerful, damaging line of energy after a brief windup. Pierces enemies and walls. Deals damage according to your active singularity."
	school = SCHOOL_EVOCATION
	charge_max = 120
	clothes_req = FALSE
	invocation_type = "none"
	base_icon_state = "immrod"
	action_icon_state = "immrod"
	sound = 'sound/magic/arbiter/storm_create.ogg'
	active_msg = "You prepare a powerful Thick Line."
	deactive_msg = "You abort the Thick Line generation process."
	projectile_type = null
	/// Important for Singularity Swap spell. Determines the damage type dealt by the spell, this var gets edited by Singularity Swap.
	var/damage_type = BLACK_DAMAGE
	/// Base damage for being hit by Thick Line.
	var/line_damage = 350
	/// How much PALE damage should be reduced by. If line_damage is 350 and pale_damage_coefficient is 0.5, then PALE Thick Line deals 175 PALE (survivable with PALE V).
	var/pale_damage_coefficient = 0.5
	/// Delay before casting Thick Line. Also counts as the amount of time the telegraphing lasts for it.
	var/line_telegraph_duration = 1.2 SECONDS
	/// Just leaving this here in case someone wants to be funny.
	var/hurts_structures = FALSE

/obj/effect/proc_holder/spell/aimed/thick_line/fire_projectile(mob/living/user, atom/target)
	current_amount--
	var/datum/reusable_visual_pool/RVP = new(500)
	var/list/been_hit = list()
	var/turf/user_turf = get_turf(user)
	var/turf/end_turf = get_ranged_target_turf_direct(user, target, 50)
	var/list/main_line_turfs = getline(user_turf, end_turf)
	main_line_turfs -= user_turf
	var/list/affected_turfs = list()
	// Initially we have a 1 tile thick line from origin to target. We make every turf in the line add its surrounding turfs to the affected turfs.
	// This gives us a line with 3 tiles of thickness. Is there a better way to do this? Maybe. I just went off of U-Turn's implementation for this.
	for(var/turf/main_line_turf in main_line_turfs)
		for(var/turf/surrounding_line_turf in view(main_line_turf, 1))
			affected_turfs |= surrounding_line_turf

	for(var/turf/T in affected_turfs)
		RVP.NewCultSparks(T, line_telegraph_duration)
	// We have a windup during which we telegraph the spell. If the do_after is not interrupted, we fire the spell.
	if(do_after(user, line_telegraph_duration, interaction_key = "thick_line", max_interact_count = 1))
		playsound(user, 'sound/magic/arbiter/storm_fire.ogg', 50)
		for(var/turf/T2 in affected_turfs)
			ThickLineHit(user, T2, been_hit)
	// If the do_after is interrupted, we refund most of the spell charge. The reason why we have to only partially refund the spell is so Arbiters don't spam their telegraph,
	// which I imagine could lag the server.
	else
		// Why is this a timer? Because the proc that calls fire_projectile sets charge_counter = 0 afterwards, so we have to do it after because I don't want to override it.
		addtimer(CALLBACK(src, PROC_REF(CancelCastRefund), user), 0.5 SECONDS)
	return list()

// We hurt absolutely everything that isn't both Head faction and hostile faction. Also you can't hide in disposals or whatever.
/obj/effect/proc_holder/spell/aimed/thick_line/proc/ThickLineHit(mob/living/user, turf/hit_turf, list/hit_list)
	user.HurtInTurf(hit_turf, hit_list, (damage_type == PALE_DAMAGE ? line_damage * pale_damage_coefficient : line_damage), damage_type, null, TRUE, TRUE, TRUE, hurt_hidden = TRUE, hurt_structure = hurts_structures)

/obj/effect/proc_holder/spell/aimed/thick_line/proc/CancelCastRefund(mob/living/user)
	if(user)
		to_chat(user, span_notice("Your Singularity collects the dissipated energy from your cancelled Thick Line."))
		charge_counter = charge_max * 0.8
		start_recharge()
