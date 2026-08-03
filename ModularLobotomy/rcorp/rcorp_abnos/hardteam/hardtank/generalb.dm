//Tank due to extremely spammable AoE with smoke effect and ALEPH level breach
/mob/living/simple_animal/hostile/rcorp_abno/hard/general_b
	name = "General Bee"
	desc = "A bee humanoid creature. There seem to be cannons on it's back releasing spores."
	health = 3000
	maxHealth = 3000
	damage_coeff = list(RED_DAMAGE = 0.3, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1)
	melee_damage_lower = 40
	melee_damage_upper = 52
	melee_damage_type = RED_DAMAGE
	original_abno = /mob/living/simple_animal/hostile/abnormality/general_b

	var/fire_cooldown_time = 3 SECONDS	//She has 4 cannons, fires 4 times faster than the artillery bees
	var/fire_cooldown
	var/fireball_range = 30
	var/volley_count
	var/datum/action/innate/rca_toggle_artillery_sight/sight_ability

	abno_additional_instructions = "<h1>You are General Bee, A Tank Role Abnormality.</h1><br>\
		<b>|Queen's Vanguard|: You have the ability to extend your sight range. \
		First use extends sight by 5 tiles in all direction, second use extends sight in all directions by another 10 tiles. \
		You will also extend view range by 10 tiles in the direction you are facing however you will lose 10 tiles of sight behind you. \
		You may change the direction of this ability by shift clicking in a direction, moving cancels this ability. <br>\
		<br>\
		|Praetorian Artillery|: You may fire 4 spore shells in quick succession, each use having a 3 second cooldown. \
		When all 4 spore shells are used you will enter a 9 second cooldown before next volley is ready. \
		Each spore shell will do 80 RED and 80 BLACK damage in a 5x5 AOE centered around the shell. \
		If the target is not visible from the shell's position it will deal no damage. <br>\
		<br>\
		|Spores|: When your |Praetorian Artillery| makes impact it will rapidly spread spores in a wide area. \
		Theses spores while harmless heavily disrupt vision, which also disrupts sight based abilities. \
		Such abilities include your own Spore Bombs and Reindeer Mindwhips. </b>"

/mob/living/simple_animal/hostile/rcorp_abno/hard/general_b/Login()
	. = ..()
	if(!. || !client)
		return FALSE
	sight_ability.original_sight = src.sight

/mob/living/simple_animal/hostile/rcorp_abno/hard/general_b/Initialize()
	. = ..()
	icon = 'ModularLobotomy/_Lobotomyicons/48x96.dmi'
	icon_living = "general_breach"
	icon_state = icon_living
	var/obj/effect/proc_holder/ability/aimed/rca_artillery_shell/shell_ability = new
	src.AddSpell(shell_ability)
	var/datum/action/spell_action/ability/item/A = shell_ability.action
	A.set_item = src //it wants an /obj/item though so its kinda bad but i dont really feel like figuring it out
	sight_ability = new
	sight_ability.Grant(src)
	sight_ability.new_sight = SEE_TURFS

/mob/living/simple_animal/hostile/rcorp_abno/hard/general_b/proc/AimShell()
	fire_cooldown = world.time + fire_cooldown_time
	var/list/targets = list()
	for(var/mob/living/L in livinginrange(fireball_range, src))
		if(L.z != z)
			continue
		if(L.status_flags & GODMODE)
			continue
		if(faction_check_mob(L, FALSE))
			continue
		if(L.stat == DEAD)
			continue
		targets += L
	if(!(targets.len > 0))
		return
	FireShell(pick(targets), FALSE)
	volley_count+=1
	if(volley_count>=4)
		volley_count=0
		fire_cooldown = world.time + fire_cooldown_time*3	//Triple cooldown every 4 shells

/mob/living/simple_animal/hostile/rcorp_abno/hard/general_b/proc/FireShell(target, called_by_ability)
	var/turf/target_turf = get_turf(target)
	if(target_turf.density)
		to_chat(src, span_notice("Can't fire at that location!"))
		if(called_by_ability)// Used so that Perform() can return on the targeted ability.
			return TRUE
		return
	to_chat(src, span_notice("You fire at the target!"))
	new /obj/effect/rca_beeshell(target_turf, faction)

/datum/action/innate/rca_toggle_artillery_sight
	name = "Toggle Artillery Sight"
	desc = "Toggle your ability to see extremely far away and through walls (but not see whats behind them)."
	icon_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = "zoom_toggle0"
	background_icon_state = "bg_abnormality"
	var/toggle_on_message = span_warning("You increase your vision range!")
	var/button_icon_toggle_activated = "zoom_toggle1"
	var/toggle_off_message = span_warning("You deactivate your artillery sight.")
	var/button_icon_toggle_deactivated = "zoom_toggle0"
	var/zoom_level = 0
	var/zoom_out_amt_level1 = 5
	var/zoom_out_amt_level2 = 15
	var/zoom_out_amt
	var/zoom_amt = 10
	var/original_sight
	var/new_sight = SEE_TURFS

/datum/action/innate/rca_toggle_artillery_sight/Activate()
	to_chat(owner, toggle_on_message)
	zoom_level ++
	switch(zoom_level)
		if(1)
			zoom_out_amt = zoom_out_amt_level1
			ActivateSignals()
		if(2)
			zoom_out_amt = zoom_out_amt_level2
			button_icon_state = button_icon_toggle_activated
			UpdateButtonIcon()
			active = TRUE

	owner.sight |= new_sight
	owner.regenerate_icons()
	owner.client.view_size.zoomOut(zoom_out_amt, zoom_amt, owner.dir)
	return ..()

/datum/action/innate/rca_toggle_artillery_sight/proc/ActivateSignals()
	SIGNAL_HANDLER

	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(Deactivate))
	RegisterSignal(owner, COMSIG_ATOM_DIR_CHANGE, PROC_REF(Rotate))

/datum/action/innate/rca_toggle_artillery_sight/Deactivate()
	to_chat(owner, toggle_off_message)
	DeactivateSignals()
	button_icon_state = button_icon_toggle_deactivated
	UpdateButtonIcon()

	owner.sight = original_sight
	owner.regenerate_icons()
	zoom_level = 0
	active = FALSE
	owner.client.view_size.zoomIn()
	return ..()

/datum/action/innate/rca_toggle_artillery_sight/proc/DeactivateSignals()
	SIGNAL_HANDLER

	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
	UnregisterSignal(owner, COMSIG_ATOM_DIR_CHANGE)

/datum/action/innate/rca_toggle_artillery_sight/proc/Rotate(old_dir, new_dir)
	SIGNAL_HANDLER

	owner.regenerate_icons()
	owner.client.view_size.zoomOut(zoom_out_amt, zoom_amt, new_dir)

/obj/effect/proc_holder/ability/aimed/rca_artillery_shell
	name = "Fire Artillery Shell Barrage"
	desc = "An ability that allows the user to fire a shell from it's artillery cannons. Quick to fire, but will need a reload after 4 shots."
	action_icon = 'icons/mob/actions/actions_abnormality.dmi'
	action_background_icon_state = "bg_abnormality"
	action_icon_state = "artillery0"
	base_icon_state = "artillery"
	cooldown_time = 3 SECONDS

	var/artillery_range = 30
	var/volley_count = 0

/obj/effect/proc_holder/ability/aimed/rca_artillery_shell/Perform(target, mob/living/simple_animal/hostile/abnormality/general_b/user)
	if(get_dist(user, target) > artillery_range)
		to_chat(user, span_notice("Too far from our cannon's range!"))
		return
	if(user.FireShell((target), TRUE))
		return
	..()
	volley_count += 1
	if(volley_count >= 4)
		volley_count = 0
		cooldown += cooldown_time * 2 //Triple cooldown every 4 shots
	return

/obj/effect/rca_beeshell
	name = "bee shell"
	desc = "A target warning you of incoming pain"
	icon = 'icons/effects/effects.dmi'
	icon_state = "beetillery"
	move_force = INFINITY
	pull_force = INFINITY
	generic_canpass = FALSE
	movement_type = PHASING | FLYING
	var/boom_damage = 160 //Half Red, Half Black
	var/list/faction = list("hostile")
	layer = POINT_LAYER	//We want this HIGH. SUPER HIGH. We want it so that you can absolutely, guaranteed, see exactly what is about to hit you.

/obj/effect/rca_beeshell/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(explode)), 3.5 SECONDS)

/obj/effect/rca_beeshell/New(loc, ...)
	. = ..()
	if(args[2])
		faction = args[2]

//Smaller Scorched Girl bomb
/obj/effect/rca_beeshell/proc/explode()
	playsound(get_turf(src), 'sound/effects/explosion2.ogg', 50, 0, 8)
	for(var/mob/living/L in view(2, src))
		if(faction_check(faction, L.faction, FALSE))
			continue
		L.deal_split_damage(boom_damage, list(RED_DAMAGE, BLACK_DAMAGE), attack_type = (ATTACK_TYPE_SPECIAL))
		if(L.health < 0)
			L.gib()
	new /obj/effect/temp_visual/explosion(get_turf(src))
	var/datum/effect_system/smoke_spread/S = new
	S.set_up(4, get_turf(src))	//Make the smoke bigger
	S.start()
	qdel(src)
