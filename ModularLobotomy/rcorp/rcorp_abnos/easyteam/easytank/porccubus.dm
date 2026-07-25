#define STATUS_EFFECT_ADDICTION /datum/status_effect/rca_porccubus_addiction
//Defined as a tank due to its projectile immunity
/mob/living/simple_animal/hostile/rcorp_abno/easy/porccubus
	name = "Porccubus"
	desc = "A long flowerlike creature covered in thorns. It seems to swat away anything thrown its way."
	maxHealth = 3000 //Porcc is quite fragile in melee so health is doubled
	health = 3000
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 1, PALE_DAMAGE = 1.5)
	ranged = TRUE
	ranged_cooldown_time = 0.5 SECONDS //will dash at people if they get out of range, cooldown short because it doesnt move
	melee_damage_lower = 15
	melee_damage_upper = 20
	rapid_melee = 3 //you can withdraw out of its range very easily so it needs to be a little harder to melee it
	melee_reach = 2
	melee_damage_type = WHITE_DAMAGE
	faction = list("hostile", "porccubus") //so that he stops attacking overdosed people while still not attacking random abnormalities
	original_abno = /mob/living/simple_animal/hostile/abnormality/porccubus

	var/teleport_cooldown_time = 5 MINUTES
	var/teleport_cooldown
	var/leap_recharge_time = 2 SECONDS
	var/leap_charges = 3
	var/max_leap_charges = 3
	var/timer_added = FALSE
	var/in_charging = FALSE

	attack_action_types = list(/datum/action/innate/rca_abnormality_attack/toggle/porccubus_dash_toggle)

	abno_additional_instructions = "<h1>You are Porccubus, A Tank Role Abnormality.</h1><br>\
		<b>|Fluttering|: You are immune to all projectiles. However you are unable to move. \
		However, If you click on a tile that is at least 3 tiles away from you. You will spend a leap charge to dash to that tile. \
		You regain a leap charge every 3 seconds, and you can hold a max of 3 at a time.<br>\
		<br>\
		|Unbearable Pleasure|: \
		<br>\
		|Happiness|: Your melee attack has a range of 2 tiles.</b>"

/mob/living/simple_animal/hostile/rcorp_abno/easy/porccubus/Initialize()
	. = ..()
	playsound(src, 'sound/abnormalities/porccubus/head_explode_laugh.ogg', 50, FALSE, 4)
	icon_living = "porrcubus"
	icon_state = icon_living
	ranged_cooldown = world.time + ranged_cooldown_time

/datum/action/innate/rca_abnormality_attack/toggle/porccubus_dash_toggle
	name = "Toggle Dash"
	button_icon_state = "porccubus_toggle0"
	chosen_attack_num = 2
	chosen_message = span_colossus("You won't dash anymore.")
	button_icon_toggle_activated = "porccubus_toggle1"
	toggle_attack_num = 1
	toggle_message = span_colossus("You will now dash to your target when possible.")
	button_icon_toggle_deactivated = "porccubus_toggle0"

//Drug-related Code
/mob/living/simple_animal/hostile/rcorp_abno/easy/porccubus/proc/DrugOverdose(mob/living/carbon/human/addict, ckey, nirvana = FALSE)//apply 3 drugs at once and speedruns the withdrawal process,
	var/datum/status_effect/rca_porccubus_addiction/PA = addict.has_status_effect(STATUS_EFFECT_ADDICTION)
	if(PA)
		OverdoseEffect(PA,nirvana)//if nirvana is false then they will barely get any buffs. bypass ckey restrictions
		return
	PA = addict.apply_status_effect(STATUS_EFFECT_ADDICTION)
	OverdoseEffect(PA,nirvana)

/mob/living/simple_animal/hostile/rcorp_abno/easy/porccubus/proc/OverdoseEffect(datum/status_effect/rca_porccubus_addiction/PA, nirvana)
	PA.IncreaseTolerance(nirvana, 1)
	PA.withdrawal_cooldown_time = 1 SECONDS
	PA.withdrawal_cooldown_time = 1 SECONDS
	if(nirvana)
		PA.sanity_gain = 60 //this basically instantly snaps them out of insanity and they get to play god for like 2 minute

/mob/living/simple_animal/hostile/rcorp_abno/easy/porccubus/Move()
	return FALSE

/mob/living/simple_animal/hostile/rcorp_abno/easy/porccubus/bullet_act(obj/projectile/P)
	visible_message(span_warning("Porccubus playfully swat [P] projectile away!"))
	return FALSE //COME CLOSER AND GET DRUGGED COWARD

//Breach Code Attacks
/mob/living/simple_animal/hostile/rcorp_abno/easy/porccubus/OpenFire(atom/A)
	if(client)
		switch(chosen_attack)
			if(1)
				DashChecker(target)
		return

	if(!target)
		return
	if(!isliving(target))
		return
	DashChecker(A)

/mob/living/simple_animal/hostile/rcorp_abno/easy/porccubus/proc/DashChecker(atom/target)
	var/dist = get_dist(target, src)
	if(dist > 2 && leap_charges > 0 && !in_charging)
		PorcDash(target)

/mob/living/simple_animal/hostile/rcorp_abno/easy/porccubus/proc/PorcDash(atom/target)//additionally, it can dash to its target every 0.5 seconds if it's out of range, the AI will kill itself in a suicide charge anyways
	in_charging = TRUE
	var/list/dash_line = getline(src, target)
	for(var/turf/line_turf in dash_line) //checks if there's a valid path between the turf and the friend
		if(line_turf.is_blocked_turf(exclude_mobs = TRUE))
			break
		forceMove(line_turf)
		SLEEP_CHECK_DEATH(1)
	playsound(src, 'sound/abnormalities/porccubus/porccu_giggle.ogg', 10, FALSE, 4) // This thing is absurdly loud
	ranged_cooldown = world.time + ranged_cooldown_time
	leap_charges -= 1
	if(!timer_added)
		addtimer(CALLBACK(src, PROC_REF(AddCharge)), leap_recharge_time)
		timer_added = TRUE
	in_charging = FALSE

/mob/living/simple_animal/hostile/rcorp_abno/easy/porccubus/AttackingTarget(atom/attacked_target)
	var/mob/living/carbon/human/H
	if(ishuman(attacked_target))
		H = attacked_target
	. = ..()
	if(!H)
		return
	if(!H.sanity_lost)
		return
	var/nirvana = FALSE
	if(get_attribute_level(H, TEMPERANCE_ATTRIBUTE) < 60) //if they have under 60 temp they actually get all the stats from overdose, otherwise they just get fucked.
		nirvana = TRUE
	DrugOverdose(H, H.ckey, nirvana)
	LoseTarget()
	if(!client) //Stops the AI but not the player, just incase some rabbit is hyperdosed on porcc juice and needs to be insaned again
		H.faction += "porccubus" //that guy's already fucked, even if they can kill porccubus safely now, porccubus has done its job of being a cunt

/mob/living/simple_animal/hostile/rcorp_abno/easy/porccubus/proc/AddCharge()
	if(leap_charges < max_leap_charges)
		leap_charges++
		to_chat(src, "<span class='notice'> You now have [leap_charges]/[max_leap_charges] leap charges.</span>")
		timer_added = FALSE
		if(leap_charges < max_leap_charges)
			addtimer(CALLBACK(src, PROC_REF(AddCharge)), leap_recharge_time)
			timer_added = TRUE

//Drug Item
//this is only obtainable if someone else dies from the addiction, but it's the only way to get drugged without being maimed by porcc
//its also funny if a rabbit goes on a drug binge from the corpses of his teammates
/obj/item/rca_porccubus_drug
	name = "Porccubus stinger"
	desc = "A stinger extracted from Porccubus or those affected by it. Using this will greatly boost your stats and grant you passive sanity regen, \
	however when the effect runs out you will die.	You may refresh the effect with multiple of these however the effect will be lessened with each usage until you die."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "porrcubus_drug"

//taking this drug as your first hit instead of porccubus will lead to an instant increased tolerance so using it at the last moment is less rewarded
/obj/item/rca_porccubus_drug/attack_self(mob/user)
	if(!ishuman(user))
		return //stop drugging my cat please
	var/buff_attributes = TRUE
	var/mob/living/carbon/human/H = user
	var/datum/status_effect/rca_porccubus_addiction/PA = H.has_status_effect(STATUS_EFFECT_ADDICTION)
	if(!PA)
		PA = H.apply_status_effect(STATUS_EFFECT_ADDICTION)
		buff_attributes = FALSE //tolerance won't apply extra attribute so it doesn't feel like you took two drugs at once
	PA.IncreaseTolerance(buff_attributes)
	qdel(src)


//ideally, we want the drug to feel like an excellent short term decision and a terrible long term one.
//random stats :
//3 drug uses before max tolerance
//30 minutes before the stats start going into the negative on first use
//if you take a drug the moment your buffed stat reaches 0, you can technically keep your stats in the positive for up to 40 minutes before you're truly screwed
//at max tolerance, your stats will go up to +60 but decrease every 10 seconds, which will take around 10 minutes to reach 0, and then another 10 minutes to become -60
//a lot of these numbers are bound to change as balancing this is really hard without it being not worth the risk or too broken because of the duration
/datum/status_effect/rca_porccubus_addiction
	id = "rca_porccubus_addiction"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/rca_porccubus_addiction
	var/withdrawal_cooldown
	var/withdrawal_cooldown_time = 60 SECONDS
	var/tolerance_sanity_gain = 60
	var/sanity_gain = 60
	var/attribute_gain = 30
	var/previous_addict = FALSE
	var/mob/living/carbon/human/addict

/atom/movable/screen/alert/status_effect/rca_porccubus_addiction
	name = "Indescribable pleasure"
	desc = "YOU FEEL HAPPY, YOU FEEL GREATER THAN YOU EVER DID IN YOUR ENTIRE LIFE! MORE, YOU WANT MORE! YOU FEEL LIKE YOU WILL DIE WITHOUT THIS!"

/datum/status_effect/rca_porccubus_addiction/on_apply()
	. = ..()
	withdrawal_cooldown = withdrawal_cooldown_time + world.time
	if(!ishuman(owner))
		owner.remove_status_effect(src)
		return

	addict = owner
	playsound(addict, 'sound/abnormalities/porccubus/porccu_giggle.ogg', 50, FALSE, 4)
	ADD_TRAIT(addict, TRAIT_COMBATFEAR_IMMUNE, type) //essentially the only buffs that don't get worse as time goes on
	addict.adjust_all_attribute_buffs(attribute_gain)

//wow this sure feels great I sure do hope there are no negative consequences for my hubris
/datum/status_effect/rca_porccubus_addiction/tick()
	if(withdrawal_cooldown < world.time)
		addict.adjustSanityLoss(-sanity_gain)
		addict.adjust_all_attribute_buffs(-1)
		sanity_gain--
		withdrawal_cooldown = withdrawal_cooldown_time + world.time

	if(addict.sanity_lost && sanity_gain < 0)
		addict.remove_status_effect(src)
	return ..()

//every time you take another hit the effects decrease
/datum/status_effect/rca_porccubus_addiction/proc/IncreaseTolerance(extra_attribute = TRUE, tolerance_amount = 0)
	for(var/i = 0 to tolerance_amount)
		if(withdrawal_cooldown_time > 30 SECONDS)
			withdrawal_cooldown_time -= 25 SECONDS //"I can stop whenever I want"

		if(attribute_gain > 0)
			attribute_gain -= 10

		if(extra_attribute)
			addict.adjust_all_attribute_buffs(attribute_gain)

		if(tolerance_sanity_gain > 10)
			tolerance_sanity_gain -= 25
		sanity_gain = tolerance_sanity_gain

	withdrawal_cooldown = withdrawal_cooldown_time + world.time
	playsound(addict, 'sound/abnormalities/porccubus/porccu_giggle.ogg', 50, FALSE, 4)

/datum/status_effect/rca_porccubus_addiction/on_remove()
	. = ..()
	if(!ishuman(owner))
		return
	var/obj/item/bodypart/head/head = addict.get_bodypart("head")
	if(QDELETED(head))
		return
	playsound(addict, 'sound/abnormalities/porccubus/head_explode_laugh.ogg', 50, FALSE, 4)
	var/obj/expanding_head = HeadExplode(head)
	sleep(2 SECONDS) //mostly so the head exploding is synced in with the sound effect and animation
	head.dismember(silent = TRUE)
	QDEL_NULL(head)
	addict.regenerate_icons()
	addict.vis_contents -= expanding_head
	playsound(addict, 'sound/abnormalities/porccubus/head_explode.ogg', 50, FALSE, 4)
	var/turf/orgin = get_turf(addict)
	var/list/all_turfs = RANGE_TURFS(2, orgin)
	new /obj/effect/gibspawner/generic/silent(get_turf(addict))
	for(var/i = 1 to 3)
		var/obj/item/porccubus_drug/drug = new(get_turf(addict)) //if you still want to try it out after seeing a man's head fucking explode
		var/turf/open/Y = pick(all_turfs - orgin)
		if(!LAZYLEN(all_turfs))
			return
		drug.throw_at(Y, 2, 3)
		all_turfs -= Y //so it doesn't throw all of them on the same tiles

//we copy the head icon and apply it as a vis content. because while overlays can't be animated, visual objects that have overlays on them can
/datum/status_effect/rca_porccubus_addiction/proc/HeadExplode(obj/item/bodypart/head/head)
	var/obj/expanding_head = new()
	expanding_head.layer = -BODY_FRONT_LAYER
	expanding_head.plane = FLOAT_PLANE
	expanding_head.mouse_opacity = 0
	expanding_head.vis_flags = VIS_INHERIT_DIR|VIS_INHERIT_DIR
	expanding_head.add_overlay(head.get_limb_icon(TRUE, TRUE, TRUE))
	addict.vis_contents += expanding_head
	addict.managed_vis_overlays += expanding_head
	animate(expanding_head, transform = matrix()*2, color = "#FF0000", pixel_y = expanding_head.pixel_y - 5, time = 2 SECONDS) //you can actually still somewhat see the head under it but the overlay should hide it well enough
	return expanding_head

#undef STATUS_EFFECT_ADDICTION
