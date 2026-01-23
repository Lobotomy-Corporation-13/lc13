/mob/living/simple_animal/hostile/limbus_abno/helper
	true_name = "All-Around Helper"
	original_abno = /mob/living/simple_animal/hostile/abnormality/helper
	melee_damage_lower = 0
	melee_damage_upper = 0 //Harmless in its base state.
	pixel_x = -16
	base_pixel_x = -16
	pixel_y = -16
	base_pixel_y = -16
	blood_volume = 0
	rapid_melee = 4
	attack_sound = 'sound/abnormalities/helper/attack.ogg'
	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 1, BLACK_DAMAGE = 2, PALE_DAMAGE = 2)
	abno_additional_instructions = "You live to serve! You like to clean and cook, following what your programming tells you without question. \
	Some may think you don't always pick the right tools for the job, but you know better! You don't like it when things are too clean around you, as it doesn't make you feel needed. \
	Still, you have a job to do, and you must do it right! You're fine with being roughened up a bit too, it shows how high quality of a product you are that you can withtand those blows! \
	When some of the following words are spoken, you feel the urge to act: 'CLEAN' 'COOK''FIGHT'"
	hunger_cooldown_time = 3 MINUTES
	diet_value = 50
	desire_loss = 5
	desire_on_pet = 40
	desire_on_eat = 20
	rep_desire_gain = 20
	insight_cooldown_time = 1 MINUTES
	liked_objects_list = (/obj/effect/decal/cleanable)
	diet_list = list(/obj/item/stock_parts/cell)
	liked_objects_value = 5
	attack_action_types = list(/datum/action/cooldown/limbus_abno_action/helper_fight,
	/datum/action/cooldown/limbus_abno_action/helper_clean,
	/datum/action/cooldown/limbus_abno_action/helper_cook,
	/datum/action/cooldown/limbus_abno_action/helper_craft)
	ego_list = list(
		/datum/ego_datum/weapon/grinder,
		/datum/ego_datum/armor/grinder,
	)
	///These are the three functions mentioned in helper's main story. Bodyguard, cleaning and cooking. Of course, helper interpret those as mixed up.
	var/cook_mode = FALSE
	var/clean_mode = FALSE
	var/fight_mode = FALSE
	var/mode_cooldown_time = 1 MINUTES
	var/mode_cooldown = 0
	var/dir_to_target
	var/dash_speed = 1
	var/charging = FALSE
	var/obj/item/reagent_containers/spray/cleaner/clean_spray
	var/list/hit_targets =  list()
	var/static/list/deepfry_blacklisted_items = typecacheof(list(/obj/item/bodypart/head,
	/obj/item/organ/brain,
	/obj/item/card/id,
	/obj/item/storage,
	/obj/item/pda))

/mob/living/simple_animal/hostile/limbus_abno/helper/Initialize(mapload)
	. = ..()
	clean_spray = new(src) //We spawn the spray inside helper because it saves us a little bit of copypaste code.
	clean_spray.stream_mode = TRUE
	clean_spray.volume = 1000
	clean_spray.list_reagents = list(/datum/reagent/space_cleaner = 1000) //No way they'd ever run out, right?

/datum/action/cooldown/limbus_abno_action/helper_fight
	name = "FIGHT MODE"
	desc = "Puts you into 'cleaning mode', letting you spin towards distant target. Can only be triggered on low mood or if you hear the word 'CLEAN'. Consume some energy to activate."
	icon_icon = 'icons/mob/actions/actions_ability.dmi'
	button_icon_state = "helper_dash0"
	transparent_when_unavailable = TRUE
	cooldown_time = 1 MINUTES
	desire_req = 30

/datum/action/cooldown/limbus_abno_action/helper_fight/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	if(abno_user.hunger_bar < 10)
		return FALSE

/datum/action/cooldown/limbus_abno_action/helper_fight/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/helper/helpies = abno_user
	helpies.AdjustHunger(-10)
	if(helpies.ChangeMode("fight", "clean", TRUE))
		StartCooldown()
		return TRUE
	return FALSE

/datum/action/cooldown/limbus_abno_action/helper_clean
	name = "CLEAN MODE"
	desc = "Puts you into 'cooking mode'. Can also be triggered if you hear the word 'COOK'. Consume some energy to activate."
	icon_icon = 'icons/obj/janitor.dmi'
	button_icon_state = "cleaner"
	transparent_when_unavailable = TRUE
	cooldown_time = 1 MINUTES

/datum/action/cooldown/limbus_abno_action/helper_clean/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	if(abno_user.hunger_bar < 10)
		return FALSE

/datum/action/cooldown/limbus_abno_action/helper_clean/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/helper/helpies = abno_user
	if(helpies.ChangeMode("clean", "cook", TRUE))
		helpies.AdjustHunger(-10)
		StartCooldown()
		return TRUE
	return FALSE

/datum/action/cooldown/limbus_abno_action/helper_cook
	name = "COOK MODE"
	desc = "Puts you into 'fighting mode', allowing you to turn dough into finished meals, and deepfrying the rest. Can also be triggered if you hear the word 'FIGHT'. Consume some energy to activate."
	icon_icon = 'icons/obj/food/food.dmi'
	button_icon_state = "meat"
	transparent_when_unavailable = TRUE
	cooldown_time = 1 MINUTES

/datum/action/cooldown/limbus_abno_action/helper_cook/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	if(abno_user.hunger_bar < 10)
		return FALSE

/datum/action/cooldown/limbus_abno_action/helper_cook/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/helper/helpies = abno_user
	if(helpies.ChangeMode("cook", "fight", TRUE))
		helpies.AdjustHunger(-10)
		StartCooldown()
		return TRUE
	return FALSE

/datum/action/cooldown/limbus_abno_action/helper_craft
	name = "Craft Cells"
	desc = "Lets you craft batteries from just one piece of metal and wire as long as it's under you. Necessary to keep yourself running."
	icon_icon = 'icons/obj/power.dmi'
	button_icon_state = "cell"
	transparent_when_unavailable = TRUE
	cooldown_time = 15 SECONDS

/datum/action/cooldown/limbus_abno_action/helper_craft/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/obj/item/stack/sheet/metal/picked_metal
	var/obj/item/stack/cable_coil/picked_cable
	var/turf/T = get_turf(abno_user)
	for(var/obj/item/stack/S in T)
		if(istype(S, /obj/item/stack/sheet/metal))
			picked_metal = S
		if(istype(S, /obj/item/stack/cable_coil))
			picked_cable = S
		if(picked_cable && picked_metal)
			picked_cable.amount -= 1
			picked_metal.amount -= 1
			if(picked_cable.amount < 1)
				qdel(picked_cable)
			if(picked_metal.amount < 1)
				qdel(picked_metal)
			new /obj/item/stock_parts/cell/hyper(T)
			abno_user.manual_emote("crafts a cell from a concerningly low amount of material.")
			StartCooldown()
			return TRUE

	return FALSE

/mob/living/simple_animal/hostile/limbus_abno/helper/Hear(message, atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, list/message_mods)
	. = ..()
	if(speaker == src)
		return .
	if(findtext(raw_message, "fight") && !cook_mode)
		ChangeMode("cook", "fight")
		return .
	if(findtext(raw_message, "clean") && !fight_mode)
		ChangeMode("fight", "clean")
		return .
	if(findtext(raw_message, "cook") && !clean_mode)
		ChangeMode("clean", "cook")
		return .

//Resets most stats relevant to modes and sets it to another mode like cleaning, cooking, and fighting. (Might add more later if it's funny)
//It's arguable if cleaning mode in the original story is swapped with its cooking or 'light security' mode, but here we assume it's a little bit of both.
/mob/living/simple_animal/hostile/limbus_abno/helper/proc/ChangeMode(picked_mode, heard_input = "N/A", bypass_cd = FALSE)
	if(mode_cooldown > world.time && !bypass_cd)
		say("ERROR. Must wait until current procedure is complete before accepting '[heard_input]' input. Thank you for choosing All Around Helper for your home!")
		return FALSE
	melee_damage_lower = 0
	melee_damage_upper = 0
	cook_mode = FALSE
	clean_mode = FALSE
	fight_mode = FALSE
	ranged = FALSE
	friendly_verb_continuous = "nuzzles"
	friendly_verb_simple = "nuzzle"
	switch(picked_mode)
		if("cook") //Perceived as 'cleaning' by helper. Lower attack than fighting mode.
			cook_mode = TRUE
			icon_living = "helper_breach"
			melee_damage_lower = 10
			melee_damage_upper = 15
			manual_emote("pulls out cooking tools.")
		if("clean") //Perceived as 'fighting' by helper.
			clean_mode = TRUE
			icon_living = "helper"
			ranged = TRUE
			clean_spray.list_reagents = list(/datum/reagent/space_cleaner = 1000)
			friendly_verb_continuous = "cleans"
			friendly_verb_simple = "clean"
			manual_emote("pulls out cleaning tools.")
		if("fight") //Perceived as 'cleaning' by helper.
			fight_mode = TRUE
			icon_living = "helper_breach"
			ranged = TRUE
			melee_damage_lower = 20
			melee_damage_upper = 25
			manual_emote("pulls out very sharp blades.")
	mode_cooldown = world.time + mode_cooldown_time
	icon_state = icon_living
	update_icon()
	return TRUE

/mob/living/simple_animal/hostile/limbus_abno/helper/OpenFire(atom/A)
	. = ..()
	if(clean_mode && clean_spray)
		clean_spray.spray(A, src)
	if(fight_mode && !charging)
		SpinCharge(A)

/mob/living/simple_animal/hostile/limbus_abno/helper/Move(turf/newloc, direction, step_x, step_y)
	if(charging)
		if(turn(dir_to_target, 180) != direction)
			dir_to_target = direction
		else
			to_chat(src, span_userdanger("You can't do 180 degree turns!"))
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/helper/UnarmedAttack(atom/A, proximity)
	if(charging)
		return
	. = ..()

	if(cook_mode && isitem(A))
		if(hunger_bar < 5)
			return
		var/obj/item/I = A
		var/turf/T = get_turf(I)
		if(istype(I, /obj/item/food/dough))
			new /obj/item/food/bread/meat(T) //Don't ask where it got the meat.
			qdel(I)
		if(istype(I, /obj/item/food/flatdough))
			new /obj/item/food/pizza/meat(T)
			qdel(I)
		if(istype(I, /obj/item/food/cakebatter))
			new /obj/item/food/cake/slimecake(T) //Don't ask either.
			qdel(I)
		if(QDELETED(I) && istype(I, /obj/item/food))
			manual_emote("cooks [I] with remarkable precision.")
			AdjustDesire(50)
			AdjustHunger(-5) //We assume what was deleted was just cooked, which costs some energy.
			return
		//Surely giving them the power to deepfry nearly everything is smart.
		if(!is_type_in_typecache(I, deepfry_blacklisted_items) || is_type_in_typecache(I, GLOB.oilfry_blacklisted_items) || HAS_TRAIT(I, TRAIT_NODROP) || (I.item_flags & (ABSTRACT | DROPDEL)))
			if(hunger_bar < 20)
				return
			var/obj/item/food/deepfryholder/fried = new /obj/item/food/deepfryholder(src, I)
			fried.fry(10)
			fried.reagents.add_reagent(/datum/reagent/consumable/cooking_oil, 10)
			fried.MakeEdible()
			fried.forceMove(T)
			AdjustHunger(-20)
			manual_emote("deepfries [I].")
			playsound(T, 'sound/machines/ding.ogg', 50, TRUE)

	if(clean_mode)
		A.wash(CLEAN_WASH)

/mob/living/simple_animal/hostile/limbus_abno/helper/proc/SpinCharge(atom/target)
	charging = TRUE
	dir_to_target = get_dir(get_turf(src), get_turf(target))
	var/para = TRUE
	if(dir_to_target in list(WEST, NORTHWEST, SOUTHWEST))
		para = FALSE
	SpinAnimation(1.3 SECONDS, 1, para)
	addtimer(CALLBACK(src, PROC_REF(ActiveSpinCharge)), 1.5 SECONDS)
	playsound(src, 'sound/abnormalities/helper/rise.ogg', 100, 1)

//I had to remove a lot of stuff that shouldn't be relevant in an LCL gamemode from the original helper dash. If you use an LCL mob outside LCL, I'm not responsible.
/mob/living/simple_animal/hostile/limbus_abno/helper/proc/ActiveSpinCharge()
	var/stop_charge = FALSE
	var/turf/T = get_step(get_turf(src), dir_to_target)
	if(!T)
		charging = FALSE
		return
	if(T.density)
		stop_charge = TRUE

	for(var/obj/structure/window/W in T.contents)
		W.obj_destruction("spinning blades")

	for(var/obj/machinery/door/D in T.contents)
		if(!D.CanAStarPass(null))
			stop_charge = TRUE
			break
		if(D.density)
			INVOKE_ASYNC(D, TYPE_PROC_REF(/obj/machinery/door, open), 2)
	if(stop_charge)
		playsound(src, 'sound/abnormalities/helper/disable.ogg', 75, 1)
		SLEEP_CHECK_DEATH(3 SECONDS)
		charging = FALSE
		hit_targets = list()
		return

	forceMove(T)
	var/para = TRUE
	if(dir_to_target in list(WEST, NORTHWEST, SOUTHWEST))
		para = FALSE
	SpinAnimation(3, 1, para)
	playsound(src, "sound/abnormalities/helper/move0[pick(1,2,3)].ogg", rand(50, 70), 1)
	var/list/hit_turfs = range(1, T)
	for(var/mob/living/L in hit_turfs)
		if(!IsFriend(L) && !LAZYFIND(hit_targets, L))
			visible_message(span_boldwarning("[src] runs through [L]!"))
			to_chat(L, span_userdanger("[src] pierces you with their spinning blades!"))
			playsound(L, attack_sound, 75, 1)
			var/turf/LT = get_turf(L)
			new /obj/effect/temp_visual/kinetic_blast(LT)
			L.deal_damage(40, RED_DAMAGE)
			L.apply_lc_bleed(5)
			hit_targets += L
			if(L.stat >= HARD_CRIT)
				L.gib()
				continue

	addtimer(CALLBACK(src, PROC_REF(ActiveSpinCharge)), dash_speed)
