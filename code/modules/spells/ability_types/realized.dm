/* E.G.O assimilation */
/obj/effect/proc_holder/ability/ego_assimilation
	name = "E.G.O assimilation"
	desc = "Convert an ALEPH E.G.O. weapon into a weapon compatible with your suit. Can only be used once."
	action_icon = 'icons/obj/ego_weapons.dmi'
	action_icon_state = ""
	base_icon_state = "template"
	var/target_type = /obj/item/ego_weapon/mimicry
	var/obj/structure/toolabnormality/wishwell/linked_structure

/obj/effect/proc_holder/ability/ego_assimilation/Perform(atom/target, user)
	..()
	target = FindItems(user)//take the return value of the FindItems() proc here
	if(!target)
		to_chat(user, span_notice("There are no E.G.O weapons nearby."))
		return
	if(!istype(target, /obj/item/ego_weapon))
		to_chat(user, span_notice("That is not an E.G.O weapon."))
		return
	if(!linked_structure)//Refer to wishing well for a list of all ALEPH E.G.O
		linked_structure = GLOB.wishwell
		if(!linked_structure)
			to_chat(user, span_notice("This ability is currently unavailable."))
			return
	if(target.type in linked_structure.alephitem)//"alephitem" is a list
		new target_type(get_turf(target))
		qdel(target)
		DeleteAbility(user)//Deletes the ability and removes it from the ego suit
		return
	to_chat(user, span_notice("Target's risk level is too low."))

/obj/effect/proc_holder/ability/ego_assimilation/proc/FindItems(user)
	var/list/stufflist = list()
	var/obj/item/ego_weapon/chosen_ego
	for(var/obj/item/ego_weapon/i in view(2, user))
		if(istype(i, target_type)) // If you're trying to create a Gasharpoon weapon then consuming a Gasharpoon weapon to do it is a bit counterintuitive
			continue
		stufflist += i
	chosen_ego = input(user, "Which E.G.O will you assimilate?") as null|anything in stufflist
	if(!chosen_ego)
		return
	return chosen_ego

/obj/effect/proc_holder/ability/ego_assimilation/proc/DeleteAbility(mob/living/carbon/human/user)
	var/obj/item/clothing/suit/armor/ego_gear/realization/mysuit = user.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(!istype(mysuit))
		return
	mysuit.realized_ability = null//sets it to a null value
	qdel(src)

/obj/effect/proc_holder/ability/ego_assimilation/farmwatch
	base_icon_state = "farmwatch"
	action_icon_state = "farmwatch"
	target_type = /obj/item/ego_weapon/farmwatch

/obj/effect/proc_holder/ability/ego_assimilation/spicebush
	base_icon_state = "spicebush"
	action_icon_state = "spicebush"
	target_type = /obj/item/ego_weapon/spicebush

/obj/effect/proc_holder/ability/ego_assimilation/gasharpoon
	base_icon_state = "gasharpoon"
	action_icon_state = "gasharpoon"
	target_type = /obj/item/ego_weapon/shield/gasharpoon

/obj/effect/proc_holder/ability/ego_assimilation/waxen
	action_icon = 'ModularLobotomy/!extra_abnos/community/!icons/community_weapons.dmi'
	base_icon_state = "combust"
	action_icon_state = "combust"
	target_type = /obj/item/ego_weapon/shield/waxen

/obj/effect/proc_holder/ability/ego_assimilation/eldtree
	base_icon_state = "lce_lantern"
	action_icon_state = "lce_lantern"
	target_type = /obj/item/ego_weapon/wield/eldtree

/* Fragment of the Universe - One with the Universe */
/obj/effect/proc_holder/ability/universe_song
	name = "Song of the Universe"
	desc = "An ability that allows its user to damage and slow down the enemies around them."
	action_icon_state = "universe_song0"
	base_icon_state = "universe_song"
	cooldown_time = 20 SECONDS

	var/damage_amount = 50 // Amount of white damage dealt to enemies per "pulse".
	var/damage_slowdown = 0.7 // Slowdown per pulse
	var/damage_count = 5 // How many times the damage and slowdown is applied
	var/damage_range = 6

/obj/effect/proc_holder/ability/universe_song/Perform(target, mob/user)
	playsound(get_turf(user), 'sound/abnormalities/fragment/sing.ogg', 50, 0, 4)
	Pulse(user)
	for(var/i = 1 to damage_count - 1)
		addtimer(CALLBACK(src, PROC_REF(Pulse), user), i*3)
	return ..()

/obj/effect/proc_holder/ability/universe_song/proc/Pulse(mob/user)
	new /obj/effect/temp_visual/fragment_song(get_turf(user))
	for(var/mob/living/L in view(damage_range, user))
		if(user.faction_check_mob(L, FALSE))
			continue
		if(L.stat == DEAD)
			continue
		L.deal_damage(damage_amount, WHITE_DAMAGE, user, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))
		new /obj/effect/temp_visual/revenant(get_turf(L))
		if(ishostile(L))
			var/mob/living/simple_animal/hostile/H = L
			H.TemporarySpeedChange(damage_slowdown, 5 SECONDS) // Slow down

/mob/living/simple_animal/hostile/shrimp_soldier/friendly/capitalism_shrimp
	name = "wellcheers corp liquidation officer"

/mob/living/simple_animal/hostile/shrimp_soldier/friendly/capitalism_shrimp/Initialize()
	.=..()
	QDEL_IN(src, (90 SECONDS))

/obj/effect/proc_holder/ability/shrimp
	name = "Backup Shrimp"
	desc = "Spawns 6 wellcheers corp liquidation officers for a period of time."
	action_icon_state = "shrimp0"
	base_icon_state = "shrimp"
	cooldown_time = 90 SECONDS



/obj/effect/proc_holder/ability/shrimp/Perform(target, mob/user)
	for(var/i = 1 to 6)
		new /mob/living/simple_animal/hostile/shrimp_soldier/friendly/capitalism_shrimp(get_turf(user))
	return ..()

/* Big Bird - Eyes of God */
/obj/effect/proc_holder/ability/lamp
	name = "Lamp of Salvation"
	desc = "An ability that slows and weakens all enemies around the user."
	action_icon_state = "lamp0"
	base_icon_state = "lamp"
	cooldown_time = 30 SECONDS

	var/debuff_range = 8
	var/debuff_slowdown = 0.5 // Slowdown per use(funfact this was meant to be an 80% slow but I accidentally made it 20%)

/obj/effect/proc_holder/ability/lamp/Perform(target, mob/user)
	cooldown = world.time + (2 SECONDS)
	if(!do_after(user, 1.5 SECONDS))
		to_chat(user, span_warning("You must stand still to see!"))
		return
	playsound(get_turf(user), 'sound/abnormalities/bigbird/hypnosis.ogg', 75, 0, 2)
	for(var/mob/living/L in view(debuff_range, user))
		if(user.faction_check_mob(L, FALSE))
			continue
		if(L.stat == DEAD)
			continue
		new /obj/effect/temp_visual/revenant(get_turf(L))
		if(ishostile(L))
			var/mob/living/simple_animal/hostile/H = L
			H.apply_status_effect(/datum/status_effect/salvation)
			H.TemporarySpeedChange(1 + debuff_slowdown , 15 SECONDS, TRUE) // Slow down_status_effect(/datum/status_effect/salvation)
	return ..()

/datum/status_effect/salvation
	id = "salvation"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 15 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/salvation

/datum/status_effect/salvation/on_apply()
	. = ..()
	if(!isanimal(owner))
		return
	var/mob/living/simple_animal/M = owner
	M.AddModifier(/datum/dc_change/salvation)

/datum/status_effect/salvation/on_remove()
	. = ..()
	if(!isanimal(owner))
		return
	var/mob/living/simple_animal/M = owner
	M.RemoveModifier(/datum/dc_change/salvation)

/atom/movable/screen/alert/status_effect/salvation
	name = "Salvation"
	desc = "You will be saved... Also makes you to be more vulnerable to all attacks."
	icon = 'icons/mob/actions/actions_ability.dmi'
	icon_state = "salvation"

/* Nothing There - Shell */
/obj/effect/proc_holder/ability/goodbye
	name = "Goodbye"
	desc = "An ability that does massive damage in an area and heals you."
	action_icon_state = "goodbye0"
	base_icon_state = "goodbye"
	cooldown_time = 30 SECONDS

	var/damage_amount = 400 // Amount of good bye damage

/obj/effect/proc_holder/ability/goodbye/Perform(target, mob/user)
	var/mob/living/carbon/human/H = user
	cooldown = world.time + (1.5 SECONDS)
	playsound(get_turf(user), 'sound/abnormalities/nothingthere/goodbye_cast.ogg', 75, 0, 5)
	if(!do_after(user, 1 SECONDS))
		to_chat(user, span_warning("You must stand still to do the nothing there classic!"))
		return
	for(var/turf/T in view(2, user))
		new /obj/effect/temp_visual/nt_goodbye(T)
		for(var/mob/living/L in T)
			if(user.faction_check_mob(L, FALSE))
				continue
			if(L.stat == DEAD)
				continue
			H.adjustBruteLoss(-10)
			L.deal_damage(damage_amount, RED_DAMAGE, user, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			if(L.health < 0)
				L.gib()
	playsound(get_turf(user), 'sound/abnormalities/nothingthere/goodbye_attack.ogg', 75, 0, 7)
	return ..()
/* Mosb - Laughter */
/obj/effect/proc_holder/ability/screach
	name = "Screach"
	desc = "An ability that damages all enemies around the user and increases their weakness to black damage."
	action_icon_state = "screach0"
	base_icon_state = "screach"
	cooldown_time = 20 SECONDS

	var/damage_amount = 200 // Amount of black damage dealt to enemies. Humans receive half of it.
	var/damage_range = 7

/obj/effect/proc_holder/ability/screach/Perform(target, mob/user)
	cooldown = world.time + (2 SECONDS)
	playsound(get_turf(user), 'sound/abnormalities/mountain/bite.ogg', 50, 0)
	if(!do_after(user, 1.5 SECONDS))
		to_chat(user, span_warning("You must stand still to screach!"))
		return
	var/mob/living/carbon/human/H = user
	playsound(get_turf(user), 'sound/abnormalities/mountain/scream.ogg', 75, 0, 2)
	visible_message(span_danger("[H] screams wildly!"))
	new /obj/effect/temp_visual/voidout(get_turf(H))
	for(var/mob/living/L in view(damage_range, user))
		if(user.faction_check_mob(L, FALSE))
			continue
		if(L.stat == DEAD)
			continue
		L.deal_damage(ishuman(L) ? damage_amount*0.5 : damage_amount, BLACK_DAMAGE, user, attack_type = (ATTACK_TYPE_SPECIAL))
		L.apply_status_effect(/datum/status_effect/mosb_black_debuff)
	return ..()

/datum/status_effect/mosb_black_debuff
	id = "mosb_black_debuff"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 15 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/mosb_black_debuff

/datum/status_effect/mosb_black_debuff/on_apply()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.physiology.black_mod *= 1.5
		return
	var/mob/living/simple_animal/M = owner
	M.AddModifier(/datum/dc_change/mosb_black)

/datum/status_effect/mosb_black_debuff/on_remove()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.physiology.black_mod /= 1.5
		return
	var/mob/living/simple_animal/M = owner
	M.RemoveModifier(/datum/dc_change/mosb_black)

/atom/movable/screen/alert/status_effect/mosb_black_debuff
	name = "Dread"
	desc = "Your fear is causing you to be more vulnerable to BLACK attacks."
	icon = 'icons/mob/actions/actions_ability.dmi'
	icon_state = "screach"

/* Judgement Bird - Head of God */
/obj/effect/proc_holder/ability/judgement
	name = "Soul Judgement"
	desc = "An ability that damages all enemies around the user and increases their weakness to pale damage."
	action_icon_state = "judgement0"
	base_icon_state = "judgement"
	cooldown_time = 20 SECONDS

	var/damage_amount = 150 // Amount of pale damage dealt to enemies. Humans receive half of it.
	var/damage_range = 9

/obj/effect/proc_holder/ability/judgement/Perform(target, mob/user)
	cooldown = world.time + (2 SECONDS)
	playsound(get_turf(user), 'sound/abnormalities/judgementbird/pre_ability.ogg', 50, 0)
	var/obj/effect/temp_visual/judgement/still/J = new (get_turf(user))
	animate(J, pixel_y = 24, time = 1.5 SECONDS)
	if(!do_after(user, 1.5 SECONDS))
		to_chat(user, span_warning("You must stand still to perform judgement!"))
		return
	playsound(get_turf(user), 'sound/abnormalities/judgementbird/ability.ogg', 75, 0, 2)
	for(var/mob/living/L in view(damage_range, user))
		if(user.faction_check_mob(L, FALSE))
			continue
		if(L.stat == DEAD)
			continue
		new /obj/effect/temp_visual/judgement(get_turf(L))
		L.deal_damage(ishuman(L) ? damage_amount*0.5 : damage_amount, PALE_DAMAGE, user, attack_type = (ATTACK_TYPE_SPECIAL))
		L.apply_status_effect(/datum/status_effect/judgement_pale_debuff)
	return ..()

/datum/status_effect/judgement_pale_debuff
	id = "judgement_pale_debuff"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 15 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/judgement_pale_debuff

/datum/status_effect/judgement_pale_debuff/on_apply()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.physiology.pale_mod /= 1.5
		return
	var/mob/living/simple_animal/M = owner
	M.AddModifier(/datum/dc_change/godhead)

/datum/status_effect/judgement_pale_debuff/on_remove()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.physiology.pale_mod *= 1.5
		return
	var/mob/living/simple_animal/M = owner
	M.RemoveModifier(/datum/dc_change/godhead)

/atom/movable/screen/alert/status_effect/judgement_pale_debuff
	name = "Soul Drain"
	desc = "Your sinful actions have made your soul more vulnerable to PALE attacks."
	icon = 'icons/mob/actions/actions_ability.dmi'
	icon_state = "judgement"

/obj/effect/proc_holder/ability/fire_explosion
	name = "Match flame"
	desc = "An ability that deals high amount of RED damage to EVERYONE around the user after short delay."
	action_icon_state = "fire0"
	base_icon_state = "fire"
	cooldown_time = 30 SECONDS
	var/explosion_damage = 1000 // Humans receive half of it.
	var/explosion_range = 6

/obj/effect/proc_holder/ability/fire_explosion/Perform(target, mob/user)
	cooldown = world.time + (5 SECONDS)
	playsound(get_turf(user), 'sound/abnormalities/scorchedgirl/pre_ability.ogg', 50, 0, 2)
	if(!do_after(user, 1.5 SECONDS))
		to_chat(user, span_warning("You must stand still to ignite the explosion!"))
		return
	playsound(get_turf(user), 'sound/abnormalities/scorchedgirl/ability.ogg', 60, 0, 4)
	var/obj/effect/temp_visual/human_fire/F = new(get_turf(user))
	F.alpha = 0
	F.dir = user.dir
	animate(F, alpha = 255, time = (2 SECONDS))
	if(!do_after(user, 2.5 SECONDS))
		to_chat(user, span_warning("You must stand still to finish the ability!"))
		animate(F, alpha = 0, time = 5)
		return
	animate(F, alpha = 0, time = 5)
	INVOKE_ASYNC(src, PROC_REF(FireExplosion), get_turf(user))
	return ..()

/obj/effect/proc_holder/ability/fire_explosion/proc/FireExplosion(turf/T)
	playsound(T, 'sound/abnormalities/scorchedgirl/explosion.ogg', 125, 0, 8)
	for(var/i = 1 to explosion_range)
		for(var/turf/open/TT in spiral_range_turfs(i, T) - spiral_range_turfs(i-1, T))
			new /obj/effect/temp_visual/fire(TT)
			for(var/mob/living/L in TT)
				if(L.stat == DEAD)
					continue
				playsound(get_turf(L), 'sound/effects/wounds/sizzle2.ogg', 25, TRUE)
				L.deal_damage(ishuman(L) ? explosion_damage*0.5 : explosion_damage, RED_DAMAGE, attack_type = (ATTACK_TYPE_SPECIAL))
		sleep(1)

/* King of Greed - Gold Experience */
/obj/effect/proc_holder/ability/road_of_gold
	name = "The Road of Gold"
	desc = "An ability that teleports you to the nearest non-visible threat.If you use a Gold Rush weapon, you can significantly weaken the enemy for a few seconds."
	action_icon_state = "gold0"
	base_icon_state = "gold"
	cooldown_time = 30 SECONDS

	var/list/spawned_effects = list()
	var/using_goldrush

/obj/effect/proc_holder/ability/road_of_gold/Perform(mob/living/simple_animal/hostile/target, mob/user)
	if(!istype(user))
		return ..()
	cooldown = world.time + (2 SECONDS)
	target = null
	var/dist = 100
	for(var/mob/living/simple_animal/hostile/H in GLOB.alive_mob_list)
		if(H.z != user.z)
			continue
		if(H.stat == DEAD)
			continue
		if(H.status_flags & GODMODE)
			continue
		if(user.faction_check_mob(H, FALSE))
			continue
		if(H in view(7, user))
			continue
		var/t_dist = get_dist(user, H)
		if(t_dist >= dist)
			continue
		dist = t_dist
		target = H
	if(!target)
		to_chat(user, span_notice("You can't find anything else nearby!"))
		return ..()
	Circle(null, null, user)
	var/pre_circle_dir = user.dir
	to_chat(user, span_warning("You begin along the Road of Gold to your target!"))
	if(!do_after(user, 15, src))
		to_chat(user, span_warning("You abandon your path!"))
		CleanUp()
		return ..()
	animate(user, alpha = 0, time = 5)
	step_towards(user, get_step(user, pre_circle_dir))
	new /obj/effect/temp_visual/guardian/phase(get_turf(src))
	var/turf/open/target_turf = get_step_towards(target, user)
	if(!istype(target_turf))
		target_turf = pick(get_adjacent_open_turfs(target))
	if(!target_turf)
		to_chat(user, span_warning("No road leads to that target!?"))
		CleanUp()
		return ..()
	var/obj/effect/qoh_sygil/kog/KS = Circle(target_turf, get_step(target_turf, pick(GLOB.cardinals)), null)
	sleep(5)
	user.dir = get_dir(user, target)
	animate(user, alpha = 255, time = 5)
	new /obj/effect/temp_visual/guardian/phase/out(get_turf(KS))
	user.forceMove(get_turf(KS))
	CleanUp()
	sleep(2.5)
	step_towards(user, get_step_towards(KS, target))
	if(get_dist(user, target) <= 1)
		var/obj/item/held = user.get_active_held_item()
		if(held)
			held.attack(target, user)
			if(held == /obj/item/ego_weapon/goldrush/nihil || held == /obj/item/ego_weapon/goldrush)
				target.apply_status_effect(/datum/status_effect/GoldStaggered)
	return ..()

/obj/effect/proc_holder/ability/road_of_gold/proc/CleanUp()
	for(var/obj/effect/FX in spawned_effects)
		if(istype(FX, /obj/effect/qoh_sygil/kog))
			var/obj/effect/qoh_sygil/kog/KS = FX
			KS.fade_out()
			continue
		FX.Destroy()
	listclearnulls(spawned_effects)

/obj/effect/proc_holder/ability/road_of_gold/proc/Circle(turf/first_target, turf/second_target, mob/user = null)
	var/obj/effect/qoh_sygil/kog/KS
	if(user)
		KS = new(get_turf(user))
	else
		KS = new(first_target)
	spawned_effects += KS
	var/matrix/M = matrix(KS.transform)
	M.Translate(0, 32)
	var/rot_angle
	var/my_dir
	if(user)
		my_dir = user.dir
		rot_angle = Get_Angle(user, get_step(user, my_dir))
	else
		my_dir = get_dir(first_target, second_target)
		rot_angle = Get_Angle(first_target, get_step_towards(first_target, second_target))
	M.Turn(rot_angle)
	switch(my_dir)
		if(EAST)
			M.Scale(0.5, 1)
			KS.layer += 0.1
		if(WEST)
			M.Scale(0.5, 1)
			KS.layer += 0.1
		if(NORTH)
			M.Scale(1, 0.5)
			KS.layer += 0.1
		if(SOUTH)
			M.Scale(1, 0.5)
			KS.layer -= 0.1
	KS.transform = M
	return KS

/datum/status_effect/GoldStaggered
	status_type = STATUS_EFFECT_UNIQUE
	duration = 5 SECONDS

/datum/status_effect/GoldStaggered/on_apply()
	. = ..()
	var/mob/living/simple_animal/M = owner
	M.AddModifier(/datum/dc_change/gold_staggered)

/datum/status_effect/GoldStaggered/on_remove()
	. = ..()
	var/mob/living/simple_animal/M = owner
	M.RemoveModifier(/datum/dc_change/gold_staggered)


/* Servant of Wrath - Wounded Courage */
/obj/effect/proc_holder/ability/justice_and_balance
	name = "For the Justice and Balance of this Land"
	desc = "An ability with 3 charges. Each use smashes all enemies in the area around you and buffs you, the third charge is amplified. \
		Each hit grants you a temporary bonus to justice, hitting the same target increases this bonus."
	action_icon_state = "justicebalance0"
	base_icon_state = "justicebalance"
	cooldown_time = 1 MINUTES

	var/max_charges = 3
	var/charges = 3
	var/list/spawned_effects = list()
	var/list/SFX = list(
		'sound/abnormalities/wrath_servant/big_smash3.ogg',
		'sound/abnormalities/wrath_servant/big_smash2.ogg',
		'sound/abnormalities/wrath_servant/big_smash1.ogg'
		)
	var/damage = 30
	var/list/targets_hit = list()

/obj/effect/proc_holder/ability/justice_and_balance/Perform(target, user)
	INVOKE_ASYNC(src, PROC_REF(Smash), user, charges)
	charges--
	if(charges < 1)
		charges = max_charges
		targets_hit = list()
		return ..()

/obj/effect/proc_holder/ability/justice_and_balance/proc/Smash(mob/user, on_use_charges)
	playsound(user, SFX[on_use_charges], 25*(4-on_use_charges))
	var/temp_dam = damage
	temp_dam *= 1 + (get_attribute_level(user, JUSTICE_ATTRIBUTE)/100)
	if(on_use_charges <= 1)
		temp_dam *= 1.5
	for(var/turf/open/T in range(3, user))
		if(T.z != user.z)
			continue
		new /obj/effect/temp_visual/small_smoke/halfsecond/green(T)
		for(var/mob/living/L in T)
			if(L.status_flags & GODMODE)
				continue
			if(L == user)
				continue
			if(L.stat == DEAD)
				continue
			if(user.faction_check_mob(L))
				continue
			if(L in targets_hit)
				targets_hit[L] += 1
			else
				targets_hit[L] = 1
			L.deal_damage(temp_dam, BLACK_DAMAGE, user, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	var/datum/status_effect/stacking/justice_and_balance/JAB = H.has_status_effect(/datum/status_effect/stacking/justice_and_balance)
	if(!JAB)
		JAB = H.apply_status_effect(/datum/status_effect/stacking/justice_and_balance)
		if(!JAB)
			return
	for(var/hit in targets_hit)
		JAB.add_stacks(targets_hit[hit])

/datum/status_effect/stacking/justice_and_balance
	id = "EGO_JAB"
	status_type = STATUS_EFFECT_UNIQUE
	stacks = 0
	tick_interval = 10
	alert_type = /atom/movable/screen/alert/status_effect/justice_and_balance
	var/next_tick = 0

/atom/movable/screen/alert/status_effect/justice_and_balance
	name = "Justice and Balance"
	desc = "The power to preserve balance is in your hands. \
		Your Justice is increased by "
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "JAB"

/datum/status_effect/stacking/justice_and_balance/process()
	if(!owner)
		qdel(src)
		return
	if(next_tick < world.time)
		tick()
		next_tick = world.time + tick_interval
	if(duration != -1 && duration < world.time)
		qdel(src)

/datum/status_effect/stacking/justice_and_balance/add_stacks(stacks_added)
	if(!ishuman(owner))
		return
	if(stacks <= 0 && stacks_added < 0)
		qdel(src)
		return
	var/mob/living/carbon/human/H = owner
	H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, stacks_added)
	stacks += stacks_added
	linked_alert.desc = initial(linked_alert.desc)+"[stacks]!"
	tick_interval = max(10 - (stacks/10), 0.1)

/datum/status_effect/stacking/justice_and_balance/can_have_status()
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/H = owner
	if(H.stat == DEAD)
		return FALSE
	var/obj/item/clothing/suit/armor/ego_gear/realization/woundedcourage/WC = H.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(!istype(WC))
		return FALSE
	return TRUE

/obj/effect/proc_holder/ability/punishment
	name = "Punishment"
	desc = "Causes massive damage in a small area only when you take a blow."
	action_icon_state = "bird0"
	base_icon_state = "bird"
	cooldown_time = 25 SECONDS

/obj/effect/proc_holder/ability/punishment/Perform(target, mob/user)
	var/mob/living/carbon/human/H = user
	H.apply_status_effect(/datum/status_effect/punishment)
	return ..()

/datum/status_effect/punishment
	id = "EGO_P2"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/punishment
	duration = 5 SECONDS

/atom/movable/screen/alert/status_effect/punishment
	name = "Ready to punish"
	desc = "You're ready to punish."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "punishment"

/datum/status_effect/punishment/on_apply()
	. = ..()
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMGE, PROC_REF(Rage))

/datum/status_effect/punishment/proc/Rage(mob/us, damage_amount, damage_type, def_zone, mob/attacker, damage_flags, attack_type)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/H = owner
	if(attacker == us)
		return
	H.apply_status_effect(/datum/status_effect/pbird)
	H.remove_status_effect(/datum/status_effect/punishment)
	to_chat(H, span_userdanger("You strike back at the wrong doer!"))
	playsound(H, 'sound/abnormalities/apocalypse/beak.ogg', 100, FALSE, 12)
	for(var/turf/T in view(2, H))
		new /obj/effect/temp_visual/beakbite(T)
		for(var/mob/living/L in T)
			if(H.faction_check_mob(L, FALSE))
				continue
			if(L.stat == DEAD)
				continue
			L.deal_damage(500, RED_DAMAGE, H, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL | ATTACK_TYPE_COUNTER))
			if(L.health < 0)
				L.gib()

/datum/status_effect/pbird
	id = "EGO_PBIRD"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/pbird
	duration = 20 SECONDS

/atom/movable/screen/alert/status_effect/pbird
	name = "Punishment"
	desc = "Their wrong doing brings you rage. \
		Your Justice is increased by 10."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "punishment"

/datum/status_effect/pbird/on_apply()
	. = ..()
	var/mob/living/carbon/human/H = owner
	owner.color = COLOR_RED
	H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, 10)

/datum/status_effect/pbird/on_remove()
	. = ..()
	var/mob/living/carbon/human/H = owner
	owner.color = null
	H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, -10)

/obj/effect/proc_holder/ability/petal_blizzard
	name = "Petal Blizzard"
	desc = "Creates a big area of healing at the cost of double damage taken for a short period of time."
	action_icon_state = "petalblizzard0"
	base_icon_state = "petalblizzard"
	cooldown_time = 30 SECONDS
	var/healing_amount = 70 // Amount of healing to plater per "pulse".
	var/healing_range = 8

/obj/effect/proc_holder/ability/petal_blizzard/Perform(target, mob/user)
	var/mob/living/carbon/human/H = user
	to_chat(H, span_userdanger("You feel frailer!"))
	H.apply_status_effect(/datum/status_effect/bloomdebuff)
	playsound(get_turf(user), 'sound/weapons/fixer/generic/sword3.ogg', 75, 0, 7)
	for(var/turf/T in view(healing_range, user))
		pick(new /obj/effect/temp_visual/cherry_aura(T), new /obj/effect/temp_visual/cherry_aura2(T), new /obj/effect/temp_visual/cherry_aura3(T))
		for(var/mob/living/carbon/human/L in T)
			if(!user.faction_check_mob(L, FALSE))
				continue
			if(L.status_flags & GODMODE)
				continue
			if(L.stat == DEAD)
				continue
			if(L.is_working) //no work heal :(
				continue
			L.adjustBruteLoss(-healing_amount)
			L.adjustSanityLoss(-healing_amount)
	return ..()

/datum/status_effect/bloomdebuff
	id = "bloomdebuff"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 15 SECONDS		//Lasts 30 seconds
	alert_type = /atom/movable/screen/alert/status_effect/bloomdebuff

/atom/movable/screen/alert/status_effect/bloomdebuff
	name = "Blooming Sakura"
	desc = "You Take 1.5x Damage."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "marked_for_death"

/datum/status_effect/bloomdebuff/on_apply()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/L = owner
		L.physiology.red_mod *= 1.5
		L.physiology.white_mod *= 1.5
		L.physiology.black_mod *= 1.5
		L.physiology.pale_mod *= 1.5

/datum/status_effect/bloomdebuff/tick()
	var/mob/living/carbon/human/Y = owner
	if(Y.sanity_lost)
		Y.death()
	if(owner.stat == DEAD)
		for(var/mob/living/carbon/human/H in GLOB.player_list)
			if(H.stat != DEAD)
				H.adjustBruteLoss(-100) // It heals everyone to full
				H.adjustSanityLoss(-100) // It heals everyone to full

/datum/status_effect/bloomdebuff/on_remove()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/L = owner
		to_chat(L, span_userdanger("You feel normal!"))
		L.physiology.red_mod /= 1.5
		L.physiology.white_mod /= 1.5
		L.physiology.black_mod /= 1.5
		L.physiology.pale_mod /= 1.5

/mob/living/simple_animal/hostile/farmwatch_plant//TODO: give it an effect with the corresponding suit.
	name = "Tree of Desires"
	desc = "The growing results of your research."
	health = 60
	maxHealth = 60
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "farmwatch_tree"
	icon_living = "farmwatch_tree"
	icon_dead = "farmwatch_tree"
	faction = list("neutral")
	del_on_death = FALSE
	area_index = MOB_SIMPLEANIMAL_INDEX // Don't trip regenerator threat mode

/mob/living/simple_animal/hostile/farmwatch_plant/Move()
	return FALSE

/mob/living/simple_animal/hostile/farmwatch_plant/CanAttack(atom/the_target)
	return FALSE

/mob/living/simple_animal/hostile/farmwatch_plant/Initialize()
	. = ..()
	QDEL_IN(src, 15 SECONDS)

/mob/living/simple_animal/hostile/farmwatch_plant/death()
	density = FALSE
	animate(src, alpha = 0, time = 1)
	QDEL_IN(src, 1)
	..()

/mob/living/simple_animal/hostile/spicebush_plant
	name = "Soon-to-bloom flower"
	desc = "The reason you bloomed, sowing seeds of nostalgia, was to set your heart upon our new beginning."
	health = 1
	maxHealth = 1
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "spicebush_tree"
	icon_living = "spicebush_tree"
	icon_dead = "spicebush_tree"
	faction = list("neutral")
	del_on_death = FALSE
	area_index = MOB_SIMPLEANIMAL_INDEX // Don't trip regenerator threat mode
	var/pulse_cooldown
	var/pulse_cooldown_time = 1.8 SECONDS
	var/pulse_damage = -2

/mob/living/simple_animal/hostile/spicebush_plant/Move()
	return FALSE

/mob/living/simple_animal/hostile/spicebush_plant/CanAttack(atom/the_target)
	return FALSE

/mob/living/simple_animal/hostile/spicebush_plant/Initialize()
	. = ..()
	QDEL_IN(src, 20 SECONDS)

/mob/living/simple_animal/hostile/spicebush_plant/Life()
	. = ..()
	if(!.) // Dead
		return FALSE
	if((pulse_cooldown < world.time) && !(status_flags & GODMODE))
		HealPulse()

/mob/living/simple_animal/hostile/spicebush_plant/death()
	density = FALSE
	playsound(src, 'sound/weapons/ego/farmwatch_tree.ogg', 100, 1)
	animate(src, alpha = 0, time = 1 SECONDS)
	QDEL_IN(src, 1 SECONDS)
	..()

/mob/living/simple_animal/hostile/spicebush_plant/proc/HealPulse()
	pulse_cooldown = world.time + pulse_cooldown_time
	//playsound(src, 'sound/abnormalities/rudolta/throw.ogg', 50, FALSE, 4)//TODO: proper SFX goes here
	for(var/mob/living/carbon/human/L in range(8, src))//livinginview(8, src))
		if(L.stat == DEAD || L.is_working)
			continue
		L.adjustBruteLoss(-2)
		L.adjustSanityLoss(-2)

/obj/effect/proc_holder/ability/overheat
	name = "Overheat"
	desc = "Burn yourself away in exchange for power."
	action_icon_state = "overheat0"
	base_icon_state = "overheat"
	cooldown_time = 2.5 MINUTES

/obj/effect/proc_holder/ability/overheat/Perform(target, mob/user)
	var/mob/living/carbon/human/H = user
	to_chat(H, span_userdanger("Ashes to ashes!"))
	H.apply_status_effect(/datum/status_effect/overheat)
	return ..()

/datum/status_effect/overheat
	id = "overheat"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 15 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/overheat

/atom/movable/screen/alert/status_effect/overheat
	name = "Overheating"
	desc = "You have full burn stacks in exchange for justice."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "mortis"

/datum/status_effect/overheat/on_apply()
	. = ..()
	var/mob/living/carbon/human/H = owner
	H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, 40)
	H.apply_lc_burn(50)
	var/datum/status_effect/stacking/lc_burn/B = H.has_status_effect(/datum/status_effect/stacking/lc_burn)
	B.safety = FALSE

/datum/status_effect/overheat/on_remove()
	. = ..()
	var/mob/living/carbon/human/H = owner
	H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, -40)
	H.remove_status_effect(STATUS_EFFECT_LCBURN)

/* Yang - Duality */
/obj/effect/proc_holder/ability/tranquility
	name = "Tranquility"
	desc = "An ability that does massive white damage in an area and heals people's health and sanity. \
	Healing someone that's wearing harmony of duality will grant them huge buffs to their defenses and stats."
	action_icon_state = "yangform0"
	base_icon_state = "yangform"
	cooldown_time = 60 SECONDS

	var/damage_amount = 300 // Amount of explosion damage
	var/explosion_range = 15

/obj/effect/proc_holder/ability/tranquility/Perform(target, mob/living/carbon/human/user)
	cooldown = world.time + (1.5 SECONDS)
	if(!do_after(user, 1 SECONDS))
		to_chat(user, span_warning("You must stand still to explode!"))
		return
	new /obj/effect/temp_visual/explosion/fast(get_turf(user))
	var/turf/orgin = get_turf(user)
	var/list/all_turfs = RANGE_TURFS(explosion_range, orgin)
	for(var/i = 0 to explosion_range)
		for(var/turf/T in all_turfs)
			if(get_dist(user, T) > i)
				continue
			new /obj/effect/temp_visual/dir_setting/speedbike_trail(T)
			user.HurtInTurf(damage_amount, list(), WHITE_DAMAGE, attack_type = (ATTACK_TYPE_SPECIAL))
			for(var/mob/living/carbon/human/L in T)
				if(!user.faction_check_mob(L, FALSE))
					continue
				if(L.stat == DEAD)
					continue
				if(L.is_working) //no work heal :(
					continue
				L.adjustBruteLoss(-120)
				L.adjustSanityLoss(-120)
				new /obj/effect/temp_visual/healing(get_turf(L))
				if(istype(L.get_item_by_slot(ITEM_SLOT_OCLOTHING), /obj/item/clothing/suit/armor/ego_gear/realization/duality_yin))
					L.apply_status_effect(/datum/status_effect/duality_yang)
			all_turfs -= T
	return ..()

/datum/status_effect/duality_yang
	id = "EGO_YANG"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/duality_yang
	duration = 90 SECONDS

/atom/movable/screen/alert/status_effect/duality_yang
	name = "Duality of harmony"
	desc = "Decreases white and pale damage taken by 25%. \
		All your stats are increased by 10."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "duality"

/datum/status_effect/duality_yang/on_apply()
	. = ..()
	var/mob/living/carbon/human/H = owner
	H.physiology.white_mod *= 0.75
	H.physiology.pale_mod *= 0.75
	H.adjust_attribute_buff(FORTITUDE_ATTRIBUTE, 10)
	H.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, 10)
	H.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, 10)
	H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, 10)

/datum/status_effect/duality_yang/on_remove()
	. = ..()
	var/mob/living/carbon/human/H = owner
	H.physiology.white_mod /= 0.75
	H.physiology.pale_mod /= 0.75
	H.adjust_attribute_buff(FORTITUDE_ATTRIBUTE, -10)
	H.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, -10)
	H.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, -10)
	H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, -10)

/*Child of the Galaxy - Our Galaxy */
/obj/effect/proc_holder/ability/galaxy_gift
	name = "An Eternal Farewell"
	desc = "Gives people around you a tiny pebble which will heal SP and HP for a short time."
	action_icon_state = "galaxy0"
	base_icon_state = "galaxy"
	cooldown_time = 60 SECONDS
	var/range = 6

/obj/effect/proc_holder/ability/galaxy_gift/Perform(target, mob/living/carbon/human/user)
	if(!istype(user))
		return
	var/list/existing_gifted = list()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.has_status_effect(/datum/status_effect/galaxy_gift))
			existing_gifted += H
	playsound(get_turf(user), 'sound/abnormalities/despairknight/gift.ogg', 50, 0, 2) //placeholder, uses KoD blessing noise at the moment
	for(var/turf/T in view(range, user))
		new /obj/effect/temp_visual/galaxy_aura(T)
		for(var/mob/living/carbon/human/H in T)
			if(!user.faction_check_mob(H, FALSE))
				continue
			if(H.stat == DEAD)
				continue
			if(H.is_working)
				continue
			var/datum/status_effect/galaxy_gift/new_gift = H.apply_status_effect(/datum/status_effect/galaxy_gift)
			new_gift.caster = user
			if(H == user)
				new_gift.watch_death = TRUE
			existing_gifted |= H
	for(var/mob/living/carbon/human/H in existing_gifted)
		var/datum/status_effect/galaxy_gift/gift = H.has_status_effect(/datum/status_effect/galaxy_gift)
		if(!gift)
			continue
		gift.gifted = existing_gifted
	return ..()

/datum/status_effect/galaxy_gift
	id = "galaxygift"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 30 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/galaxy_gift
	var/base_heal_amt = 0.5
	var/base_dmg_amt = 45
	var/watch_death = FALSE
	var/list/gifted
	var/mob/living/carbon/human/caster

/atom/movable/screen/alert/status_effect/galaxy_gift
	name = "Parting Gift"
	desc = "You recover SP and HP over time temporarliy."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "friendship"

/datum/status_effect/galaxy_gift/tick()
	. = ..()
	if(!ishuman(owner))
		qdel(src)
		return
	var/mob/living/carbon/human/Y = owner
	listclearnulls(gifted)
	for(var/mob/living/carbon/human/H in gifted)
		if(H == Y)
			continue
		if(H == caster)
			continue
		if(H.stat == DEAD || QDELETED(H))
			gifted -= H
			if(H) // If there's even anything left to remove
				H.remove_status_effect(/datum/status_effect/galaxy_gift)
	if(caster.stat == DEAD || QDELETED(Y))
		return watch_death ? Pop() : FALSE
	var/heal_mult = LAZYLEN(gifted)
	heal_mult = max(3, heal_mult)
	Y.adjustBruteLoss(-(base_heal_amt*heal_mult))
	Y.adjustSanityLoss(-(base_heal_amt*heal_mult))

/datum/status_effect/galaxy_gift/proc/Pop()
	var/damage_mult = LAZYLEN(gifted)
	for(var/mob/living/carbon/human/H in gifted)
		H.deal_damage(base_dmg_amt*damage_mult, BLACK_DAMAGE, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))
		H.remove_status_effect(/datum/status_effect/galaxy_gift)
		new /obj/effect/temp_visual/pebblecrack(get_turf(H))
		playsound(get_turf(H), "shatter", 50, TRUE)
		to_chat(H, span_userdanger("Your pebble violently shatters!"))
		caster = null
	return

/* Sleeping Beauty - Comatose */
/obj/effect/proc_holder/ability/comatose
	name = "Comatose"
	desc = "Fall asleep to gain 99% resistance to all normal damage."
	action_icon_state = "comatose0"
	base_icon_state = "comatose"
	cooldown_time = 30 SECONDS

/obj/effect/proc_holder/ability/comatose/Perform(target, mob/living/carbon/human/user)
	if(istype(user.get_item_by_slot(ITEM_SLOT_OCLOTHING), /obj/item/clothing/suit/armor/ego_gear/realization/comatose))
		user.Stun(15 SECONDS)
		user.Knockdown(1)
		user.playsound_local(get_turf(user), "sound/abnormalities/happyteddy/teddy_lullaby.ogg", 25, 0)
		user.apply_status_effect(/datum/status_effect/dreaming)
		return ..()

/datum/status_effect/dreaming
	id = "EGO_SLEEPING"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/dreaming
	duration = 15 SECONDS

/atom/movable/screen/alert/status_effect/dreaming
	name = "Dreams of comfort"
	desc = "Decreases damage taken from conventional damage types by 99%"
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "comatose"

/datum/status_effect/dreaming/on_apply()
	. = ..()
	var/mob/living/carbon/human/H = owner
	H.physiology.red_mod /= 100
	H.physiology.white_mod /= 100
	H.physiology.black_mod /= 100
	H.physiology.pale_mod /= 100

/datum/status_effect/dreaming/on_remove()
	. = ..()
	var/mob/living/carbon/human/H = owner
	H.physiology.red_mod *= 100
	H.physiology.white_mod *= 100
	H.physiology.black_mod *= 100
	H.physiology.pale_mod *= 100

/* Wishing Well - Broken Crown */
/obj/effect/proc_holder/ability/brokencrown
	name = "Broken Crown"
	desc = "Extract a random empowered E.G.O. weapon once, return it to the armor to try for a different weapon. The item will automatically be returned if the armor is taken off."
	action_icon_state = "brokencrown0"
	base_icon_state = "brokencrown"
	cooldown_time = 5 MINUTES
	var/obj/structure/toolabnormality/wishwell/linked_structure
	var/list/ego_list = list()
	var/obj/item/ego_weapon/chosenEGO
	var/obj/item/linkeditem = null
	var/ready = TRUE

/obj/effect/proc_holder/ability/brokencrown/proc/Absorb(obj/item/I, mob/living/user)
	if(!ego_list || ready)
		to_chat(user, span_notice("You need to use this ability before you can recharge it!"))
		return FALSE
	if(!is_type_in_list(I, ego_list))
		return FALSE
	if(is_ego_melee_weapon(I))
		if(I.force_multiplier < 1.2)
			to_chat(user, span_notice("You must use a weapon with a damage multiplier of 20% or higher!"))
			return FALSE
		Reload(I, user)
		return TRUE
	return FALSE

/obj/effect/proc_holder/ability/brokencrown/proc/Reload(obj/item/I, mob/living/user)
	to_chat(user, span_nicegreen("The ability has been recharged."))
	ready = TRUE
	qdel(I)

/obj/effect/proc_holder/ability/brokencrown/Perform(target, mob/living/carbon/human/user)
	if(!ready)
		to_chat(user, span_notice("This ability has been spent and needs to be recharged."))
		return
	if(istype(user.get_item_by_slot(ITEM_SLOT_OCLOTHING), /obj/item/clothing/suit/armor/ego_gear/realization/brokencrown))
		user.playsound_local(get_turf(user), "sound/abnormalities/bloodbath/Bloodbath_EyeOn.ogg", 25, 0)
		if(!linked_structure)
			linked_structure = locate(/obj/structure/toolabnormality/wishwell) in world.contents
			if(!linked_structure) //Somehow you got this ego on a non-facility map
				ego_list += /obj/item/ego_weapon/mimicry
				ego_list += /obj/item/ego_weapon/smile
				ego_list += /obj/item/ego_weapon/da_capo
				linked_structure = TRUE
		if(!LAZYLEN(ego_list))
			for(var/egoitem in linked_structure.alephitem)
				if(ispath(egoitem, /obj/item/ego_weapon) || ispath(egoitem, /obj/item/ego_weapon/ranged))
					ego_list += egoitem
					continue
		chosenEGO = pick(ego_list)
		var/obj/item/ego = chosenEGO //Not sure if there is a better way to do this
		if(ispath(ego, /obj/item/ego_weapon))
			var/obj/item/ego_weapon/egoweapon = new ego(get_turf(user))
			egoweapon.force_multiplier = 1.20
			egoweapon.name = "shimmering [egoweapon.name]"
			egoweapon.set_light(3, 6, "#D4FAF37")
			egoweapon.color = "#FFD700"
			linkeditem = egoweapon

		else if(ispath(ego, /obj/item/ego_weapon/ranged))
			var/obj/item/ego_weapon/ranged/egogun = new ego(get_turf(user))
			egogun.force_multiplier = 1.20
			egogun.projectile_damage_multiplier = 1.20
			egogun.name = "shimmering [egogun.name]"
			egogun.set_light(3, 6, "#D4FAF37")
			egogun.color = "#FFD700"
			linkeditem = egogun
		ready = FALSE
		return ..()

/obj/effect/proc_holder/ability/brokencrown/proc/Reabsorb()
	if(linkeditem && !ready)
		linkeditem.visible_message(span_userdanger("<font color='#CECA2B'>[linkeditem] glows brightly for a moment then... fades away without a trace.</font>"))
		qdel(linkeditem)
		ready = TRUE
	return

/* Opened Can of Wellcheers - Wellcheers */
/obj/effect/proc_holder/ability/wellcheers
	name = "Wellcheers Crew"
	desc = "Call up 3 of your finest crewmates for a period of time."
	action_icon_state = "shrimp0"
	base_icon_state = "shrimp"
	cooldown_time = 90 SECONDS

/obj/effect/proc_holder/ability/wellcheers/Perform(target, mob/user)
	for(var/i = 1 to 3)
		new /mob/living/simple_animal/hostile/shrimp/friendly(get_turf(user))
	return ..()

/mob/living/simple_animal/hostile/shrimp/friendly //HUGE buff shrimp
	name = "wellcheers boat fisherman"
	health = 700
	maxHealth = 700
	desc = "Are those fists?"
	melee_damage_lower = 40
	melee_damage_upper = 45
	icon_state = "wellcheers_ripped"
	icon_living = "wellcheers_ripped"
	faction = list("neutral", "shrimp")

/mob/living/simple_animal/hostile/shrimp/friendly/Initialize()
	.=..()
	AddComponent(/datum/component/knockback, 1, FALSE, TRUE)
	QDEL_IN(src, (90 SECONDS))

/mob/living/simple_animal/hostile/shrimp/friendly/AttackingTarget(atom/attacked_target)
	. = ..()
	if(.)
		var/mob/living/L = attacked_target
		if(L.health < 0 || L.stat == DEAD)
			L.gib() //Punch them so hard they explode
/* Flesh Idol - Repentance */
/obj/effect/proc_holder/ability/prayer
	name = "Prayer"
	desc = "An ability that does causes you to start praying reducing damage taken by 25% but removing your ability to move and lowers justice by 80. \
	When you finish praying everyone gets a 20 justice increase and gets healed."
	action_icon_state = "flesh0"
	base_icon_state = "flesh"
	cooldown_time = 180 SECONDS

/obj/effect/proc_holder/ability/prayer/Perform(target, mob/living/carbon/human/user)
	user.apply_status_effect(/datum/status_effect/flesh1)
	cooldown = world.time + (15 SECONDS)
	to_chat(user, span_userdanger("You start praying..."))
	if(!do_after(user, 15 SECONDS))
		user.remove_status_effect(/datum/status_effect/flesh1)
		return
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(!user.faction_check_mob(H, FALSE))
			continue
		if(H.stat == DEAD)
			continue
		if(H.z != user.z)
			continue
		playsound(H, 'sound/abnormalities/onesin/bless.ogg', 100, FALSE, 12)
		to_chat(H, span_nicegreen("[user]'s prayer was heard!"))
		H.adjustBruteLoss(-100)
		H.adjustSanityLoss(-100)
		H.apply_status_effect(/datum/status_effect/flesh2)
		new /obj/effect/temp_visual/healing(get_turf(H))
	return ..()

/datum/status_effect/flesh1
	id = "FLESH1"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/flesh1
	duration = 15 SECONDS
	tick_interval = 3 SECONDS

/atom/movable/screen/alert/status_effect/flesh1
	name = "A prayer to god"
	desc = "You take random damage while praying."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "flesh"

/datum/status_effect/flesh1/on_apply()
	. = ..()
	var/mob/living/carbon/human/H = owner
	ADD_TRAIT(H, TRAIT_IMMOBILIZED, type)

/datum/status_effect/flesh1/tick()
	. = ..()
	var/mob/living/carbon/human/H = owner
	var/list/damtypes = list(RED_DAMAGE, WHITE_DAMAGE, BLACK_DAMAGE, PALE_DAMAGE)
	var/damage = pick(damtypes)
	H.deal_damage(7, damage, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_STATUS))

/datum/status_effect/flesh1/on_remove()
	. = ..()
	var/mob/living/carbon/human/H = owner
	REMOVE_TRAIT(H, TRAIT_IMMOBILIZED, type)

/datum/status_effect/flesh2
	id = "FLESH2"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/flesh2
	duration = 60 SECONDS

/atom/movable/screen/alert/status_effect/flesh2
	name = "An answer from god"
	desc = "Increases justice by 20."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "flesh"

/datum/status_effect/flesh2/on_apply()
	. = ..()
	var/mob/living/carbon/human/H = owner
	H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, 20)

/datum/status_effect/flesh2/on_remove()
	. = ..()
	var/mob/living/carbon/human/H = owner
	H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, -20)

/obj/effect/proc_holder/ability/nest
	name = "Worm spawn"
	desc = "Spawns 7 worms that will seak out abormalities to infest in making them weaker to red damage."
	action_icon_state = "worm0"
	base_icon_state = "worm"
	cooldown_time = 30 SECONDS



/obj/effect/proc_holder/ability/nest/Perform(target, mob/user)
	for(var/i = 1 to 7)
		playsound(get_turf(user), 'sound/misc/moist_impact.ogg', 30, 1)
		var/landing
		landing = locate(user.x + pick(-2,-1,0,1,2), user.y + pick(-2,-1,0,1,2), user.z)
		var/mob/living/simple_animal/hostile/naked_nest_serpent_friend/W = new(get_turf(user))
		W.origin_nest = user
		W.throw_at(landing, 0.5, 2, spin = FALSE)
	return ..()

/datum/status_effect/stacking/infestation
	id = "EGO_NEST"
	status_type = STATUS_EFFECT_UNIQUE
	stacks = 1
	stack_decay = 0 //Without this the stacks were decaying after 1 sec
	duration = 15 SECONDS //Lasts for 4 minutes
	alert_type = /atom/movable/screen/alert/status_effect/justice_and_balance
	max_stacks = 20
	consumed_on_threshold = FALSE
	var/red = 0

/atom/movable/screen/alert/status_effect/infestation
	name = "Infestation"
	desc = "Your weakness to red damage is increased by "
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "infest"

/datum/status_effect/stacking/infestation/on_apply()
	. = ..()
	var/mob/living/simple_animal/M = owner
	M.AddModifier(/datum/dc_change/infested)

/datum/status_effect/stacking/infestation/on_remove()
	. = ..()
	var/mob/living/simple_animal/M = owner
	M.RemoveModifier(/datum/dc_change/infested)

/datum/status_effect/stacking/infestation/add_stacks(stacks_added)
	. = ..()
	if(!isanimal(owner))
		return
	var/mob/living/simple_animal/M = owner
	var/datum/dc_change/infested/mod = M.HasDamageMod(/datum/dc_change/infested)
	mod.potency = 1+(stacks/20)
	M.UpdateResistances()
	linked_alert.desc = initial(linked_alert.desc)+"[stacks*5]%!"

/mob/living/simple_animal/hostile/naked_nest_serpent_friend
	name = "friendly naked serpent"
	desc = "A sickly looking green-colored worm but looks friendly."
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "nakednest_serpent"
	icon_living = "nakednest_serpent"
	a_intent = "harm"
	melee_damage_lower = 1
	melee_damage_upper = 1
	maxHealth = 500
	health = 500 //STOMP THEM STOMP THEM NOW.
	move_to_delay = 3
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	stat_attack = HARD_CRIT
	density = FALSE //they are worms.
	robust_searching = 1
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	mob_size = MOB_SIZE_SMALL
	pass_flags = PASSTABLE | PASSMOB
	layer = ABOVE_NORMAL_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_OPAQUE //Clicking anywhere on the turf is good enough
	del_on_death = 1
	vision_range = 18 //two screens away
	faction = list("neutral")
	var/mob/living/carbon/human/origin_nest

/mob/living/simple_animal/hostile/naked_nest_serpent_friend/Initialize()
	.=..()
	AddComponent(/datum/component/swarming)
	QDEL_IN(src, (20 SECONDS))

/mob/living/simple_animal/hostile/naked_nest_serpent_friend/AttackingTarget(atom/attacked_target)
	var/mob/living/L = attacked_target
	var/datum/status_effect/stacking/infestation/INF = L.has_status_effect(/datum/status_effect/stacking/infestation)
	if(!INF)
		INF = L.apply_status_effect(/datum/status_effect/stacking/infestation)
		if(!INF)
			return
	INF.add_stacks(1)
	qdel(src)
	. = ..()

/mob/living/simple_animal/hostile/naked_nest_serpent_friend/LoseAggro() //its best to return home
	..()
	if(origin_nest)
		for(var/mob/living/carbon/human/H in oview(vision_range, src))
			if(origin_nest == H.tag)
				Goto(H, 5, 0)
				return
/mob/living/simple_animal/hostile/naked_nest_serpent_friend/Life()
	..()
	if(origin_nest)
		for(var/mob/living/carbon/human/H in oview(vision_range, src))
			if(origin_nest == H.tag)
				Goto(H, 5, 0)
				return

/* Wayward Passenger - Dimension Ripper */
/obj/effect/proc_holder/ability/rip_space
	name = "Rip Space"
	desc = "Travel at light speed between portals to attack your enemies."
	action_icon_state = "ripper0"
	base_icon_state = "ripper"
	cooldown_time = 1 MINUTES

/obj/effect/proc_holder/ability/rip_space/Perform(target, mob/living/user)
	var/list/targets = list()
	for(var/mob/living/L in view(8, user))
		if(L.stat == DEAD)
			continue
		if(L.status_flags & GODMODE)
			continue
		if(user.faction_check_mob(L, FALSE))
			continue
		targets += L
	if(!(LAZYLEN(targets)))
		to_chat(user, span_warning("There are no enemies nearby!"))
		return

	cooldown = world.time + (7 SECONDS)
	var/turf/origin = get_turf(user)
	var/dash_count = min(targets.len*3, 30) //Max 10 targets (7 Seconds)
	user.density = FALSE
	ADD_TRAIT(user, TRAIT_IMMOBILIZED, type)
	var/obj/effect/portal/warp/P = new(origin)
	playsound(user, 'sound/abnormalities/wayward_passenger/ripspace_begin.ogg', 100, 0)
	sleep(1 SECONDS)
	qdel(P)
	user.alpha = 0

	for(var/i = 1 to dash_count)
		var/mob/living/L = pick(targets)
		dash_attack(L, user)
		if(L.stat == DEAD)
			targets -= L
		if(!LAZYLEN(targets) || user.stat == DEAD)
			break

	user.alpha = 255
	new /obj/effect/temp_visual/rip_space(origin)
	user.forceMove(origin)
	user.density = TRUE
	REMOVE_TRAIT(user, TRAIT_IMMOBILIZED, type)
	playsound(user, 'sound/abnormalities/wayward_passenger/ripspace_end.ogg', 100, 0)
	return ..()

/obj/effect/proc_holder/ability/rip_space/proc/dash_attack(mob/living/target, mob/living/user)
	var/list/potential_TP = list()
	for(var/turf/T in range(3, target))
		if(T in range(2, target))
			continue
		potential_TP += T
	var/turf/start_point = pick(potential_TP)
	var/turf/end_point = get_step(get_turf(target), get_dir(start_point, target))
	end_point = get_step(end_point, get_dir(start_point, target))
	var/obj/effect/temp_visual/rip_space/X = new(start_point)
	var/obj/effect/temp_visual/rip_space/Y = new(end_point)

	var/obj/projectile/ripper_dash_effect/DE = new(start_point)
	DE.preparePixelProjectile(Y, X)
	DE.name = user.name
	DE.fire()
	user.orbit(DE, 0, 0, 0, 0, 0)

	sleep(1)
	target.deal_damage(100, RED_DAMAGE, user, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	new /obj/effect/temp_visual/rip_space_slash(get_turf(target))
	new /obj/effect/temp_visual/ripped_space(get_turf(target))
	playsound(user, 'sound/abnormalities/wayward_passenger/ripspace_hit.ogg', 75, 0)
	sleep(1)
	qdel(DE)

/obj/projectile/ripper_dash_effect
	speed = 0.32
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "ripper_dash"
	projectile_piercing = ALL

/obj/projectile/ripper_dash_effect/on_hit(atom/target, blocked = FALSE)
	return

/obj/effect/proc_holder/ability/aedd_curl_up
	name = "Curl Up"
	desc = "Immobilize yourself and gain an universal shield equivalent to 50% of your maximum health for 5 seconds. Accumulates Self-Charge when being hit, and larger hits grant more Self-Charge. \n\
	If the shield is broken, cooldown on this ability is multiplied by 4.5x and you gain Fragile. If it doesn't, retaliate with a BLACK damage AoE that scales with Fortitude and inversely scales with remaining shield health. Cooldown: 25s."
	action_icon_state = "ripper0"
	base_icon_state = "ripper"
	cooldown_time = 25 SECONDS
	var/curl_shield_overlay = icon('ModularLobotomy/_Lobotomyicons/tegu_effects.dmi', "pale_shield")
	var/curl_shield_timer
	var/curl_cooldown_timer
	var/curl_base_cooldown = 25 SECONDS
	var/curl_shatter_cooldown_multiplier = 4.5
	var/shock_radius = 2
	var/shock_base_damage = 100
	var/shield_health = 0
	var/activated = FALSE
	var/ready = TRUE

/// This override ensures we can use our custom cooldown logic.
/obj/effect/proc_holder/ability/aedd_curl_up/Perform(target, mob/living/user)
	if((!ready) || (activated))
		to_chat(user, span_warning("This ability isn't ready yet."))
		return FALSE
	var/mob/living/carbon/human/our_guy = user
	if(!istype(our_guy))
		return FALSE
	if(our_guy.is_working)
		to_chat(our_guy, span_warning("You cannot cower from the duties of your work."))
		return FALSE
	var/obj/item/clothing/suit/armor/ego_gear/realization/experimentation/our_suit = user.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(!istype(our_suit))
		return FALSE

	// Go on cooldown.
	ready = FALSE
	curl_cooldown_timer = addtimer(CALLBACK(src, PROC_REF(Refresh), user), curl_base_cooldown, TIMER_STOPPABLE)
	cooldown = world.time + curl_base_cooldown
	update_icon()

	// Actual ability here.
	ActivateShield(our_guy)

/// Applies the shield to the user, registering a signal for taking damage.
/obj/effect/proc_holder/ability/aedd_curl_up/proc/ActivateShield(mob/living/carbon/human/user)
	activated = TRUE
	user.Immobilize(5 SECONDS, TRUE) // You are immobilized. This doesn't get removed early if you lose the shield. Stand your ground!

	shield_health = (user.maxHealth * 0.50) // 50% of your HP as an universal shield.
	RegisterSignal(user, COMSIG_MOB_APPLY_DAMGE, PROC_REF(ShieldHitReaction)) // Important, this actually handles intercepting hits and lowering shield HP.
	RegisterSignal(user, COMSIG_WORK_STARTED, PROC_REF(WorkRevert)) // no
	curl_shield_timer = addtimer(CALLBACK(src, PROC_REF(RemoveShield), user, FALSE), 5 SECONDS, TIMER_STOPPABLE)

	// Aesthetics
	playsound(get_turf(user), 'sound/weapons/fixer/generic/energy3.ogg', 75, 0)
	user.add_overlay(curl_shield_overlay) // Looks like a manager PALE shield.
	user.visible_message(span_danger("[user] takes up a defensive stance, shielding \himself with \his E.G.O suit!"), span_notice("You curl up into a defensive stance, using your E.G.O to create a shield around yourself."))


/// Called by the timeout timer or by the shield being shattered, in which case violent == TRUE.
/obj/effect/proc_holder/ability/aedd_curl_up/proc/RemoveShield(mob/living/carbon/human/user, violent = FALSE)
	deltimer(curl_shield_timer)
	UnregisterSignal(user, COMSIG_MOB_APPLY_DAMGE)
	UnregisterSignal(user, COMSIG_WORK_STARTED)
	user.cut_overlay(curl_shield_overlay)
	activated = FALSE
	if(violent)
		user.visible_message(span_danger("[user]'s shield shatters!"), span_userdanger("Your E.G.O.'s shield shatters, and your accumulated charge is lost!"))
	else
		user.visible_message(span_danger("[user] abandons \his defensive stance, shocking \his surroundings!"), span_warning("You abandon your defensive stance and unleash an electrical shock around yourself!"))
		ShockAOE(user, shield_health)
	shield_health = 0

/// Signal handler that prevents damage by returning COMPONENT_MOB_DENY_DAMAGE. Unfortunately has to replicate some damage calculation code.
/obj/effect/proc_holder/ability/aedd_curl_up/proc/ShieldHitReaction(mob/living/carbon/human/user, damage_amount, damage_type, def_zone)
	SIGNAL_HANDLER
	if(!ishuman(user))
		return
	var/obj/item/clothing/suit/armor/ego_gear/realization/experimentation/our_suit = user.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(!istype(our_suit))
		return FALSE

	// Below is a bunch of recycled code from Manager Shield bullets and the deal_damage proc itself, because the system simply isn't built to handle things like this properly, sadly.

	// Determine how much we're blocking based on our armour and physiology.
	var/blocked = 0
	if((damage_type != (BRUTE || STAMINA)))
		blocked = user.run_armor_check(def_zone, damage_type) // This is armour from our EGO gear.

	var/hit_percent = (100-blocked)/100
	hit_percent = (hit_percent * (100-user.physiology.damage_resistance))/100 // Factor in general damage resistance from physiology.

	switch(damage_type) // Now we have to account for physiology... for some reason, damage_resistance is expressed as a value between 0 and 100 but x_mod is a coefficient... GRAHHHH
		if(RED_DAMAGE)
			hit_percent = (hit_percent * user.physiology.red_mod)
		if(WHITE_DAMAGE)
			hit_percent = (hit_percent * user.physiology.white_mod)
		if(BLACK_DAMAGE)
			hit_percent = (hit_percent * user.physiology.black_mod)
		if(PALE_DAMAGE)
			hit_percent = (hit_percent * user.physiology.pale_mod)

	var/final_damage = damage_amount * hit_percent

	if(final_damage <= 0) // We took 0 damage, or healed from the attack. Don't react to this.
		return

	if(final_damage >= shield_health) // The damage exceeds our shield's health.
		var/chipped_through_damage = final_damage - shield_health // Calculate the "overkill" on our shield...
		shield_health = 0
		ShatterShield(user, chipped_through_damage, damage_type, def_zone) // Remove our shield and deal the "overkill" damage. That is to say, if our shield had 50 hp and we took 60 damage, deal 10.

		// Lose all charge and un-empower if our shield shatters. The reason we handle this here instead of ShatterShield is because we already pulled our suit in this proc so it's less wasteful.
		our_suit.charge = 0
		our_suit.RevertBuff()

		return COMPONENT_MOB_DENY_DAMAGE // Deny the original damage so it doesn't "double dip".

	else // We took damage, but not more than our shield's current health.
		shield_health = max(0, (shield_health - final_damage)) // Never allow shield_health to become negative. Theoretically it could never happen since it is handled in the prior case, but I want to be cautious
		// Shield aesthetics, taken from Shock Centipede itself
		var/obj/effect/temp_visual/shock_shield/AT = new /obj/effect/temp_visual/shock_shield(get_turf(user))
		AT.transform *= 0.5
		var/random_x = rand(-8, 8)
		AT.pixel_x += random_x
		var/random_y = rand(-12, 12)
		AT.pixel_y += random_y

		our_suit.AdjustCharge(1) // Gain 1 charge on any hit.
		if(final_damage > 5) // Generate charge if we took noticeable damage. (This is post reductions............................!!!!!!!!!!!!!!!!!)
			our_suit.AdjustCharge(1)
			if(final_damage > 25) // Generate extra charge if we really got cooked.
				our_suit.AdjustCharge(2)

		playsound(get_turf(user), 'sound/mecha/mech_shield_deflect.ogg', 70)

		if(our_suit.empowered)
			our_suit.StartArcLightning() // If we're empowered, cause an arc lightning to start. Normally it's called by the "apply damage" signal but we're literally intercepting that one in this proc

		return COMPONENT_MOB_DENY_DAMAGE // Deny the damage.

/// Proc called if the shield breaks due to damage. We go on a longer cooldown than usual and deal any overkill damage, and then apply fragile to the user.
/obj/effect/proc_holder/ability/aedd_curl_up/proc/ShatterShield(mob/living/carbon/human/user, damage_amount, damage_type, limb)
	RemoveShield(user, violent = TRUE)

	var/remaining_time = timeleft(curl_cooldown_timer)
	var/new_duration = remaining_time * curl_shatter_cooldown_multiplier
	deltimer(curl_cooldown_timer)
	curl_cooldown_timer = addtimer(CALLBACK(src, PROC_REF(Refresh), user), new_duration, TIMER_STOPPABLE) // Your ability will now refresh way slower than it should.
	cooldown = world.time + new_duration
	update_icon()

	user.deal_damage(damage_amount, damage_type, flags = (DAMAGE_FORCED | DAMAGE_UNTRACKABLE | DAMAGE_PIERCING), def_zone = limb) // This is DAMAGE_PIERCING because we already applied armour reductions.
	playsound(get_turf(user), 'sound/effects/glassbr1.ogg', 100, 0, 10)
	user.apply_lc_fragile(1)

	// Add some special effect when shattering in the future, maybe? I don't know, it's an option.

/// Called if you start a work with the shield active. Be grateful I didn't just make it shatter
/obj/effect/proc_holder/ability/aedd_curl_up/proc/WorkRevert(mob/living/carbon/human/user)
	SIGNAL_HANDLER
	to_chat(user, span_warning("<b>A mysterious force compels you to dissipate your shield as you begin your work! Wow!</b>"))
	RemoveShield(user, FALSE)

/// This is called at the end of our cooldown, to re-enable the skill.
/obj/effect/proc_holder/ability/aedd_curl_up/proc/Refresh(mob/living/carbon/human/user)
	ready = TRUE

	if(!istype(user))
		return FALSE
	var/obj/item/clothing/suit/armor/ego_gear/realization/experimentation/our_suit = user.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(!istype(our_suit))
		return FALSE

	// Tell the user that they're ready to ball
	SEND_SOUND(user, sound('sound/abnormalities/armyinblack/black_heartbeat.ogg'))
	flash_color(user, flash_color = COLOR_PALE_BLUE_GRAY, flash_time = 1 SECONDS)
	user.visible_message(span_danger("[user]'s [our_suit.name] E.G.O. begins to spark with electrical excitement."), span_nicegreen("Your [our_suit.name] E.G.O. sparks with electrical excitement - it has recharged, and you can use its ability again."))

/// AoE called when our shield expires without shattering. We deal more damage the closer we got to shattering. Scales off Fort instead of Justice.
/obj/effect/proc_holder/ability/aedd_curl_up/proc/ShockAOE(mob/living/carbon/human/user, remaining_health)
	var/userfort = (get_modified_attribute_level(user, FORTITUDE_ATTRIBUTE))
	var/fortitudemod = 1 + userfort/100
	var/remaininghealthmod = (1 + (0.93 ** (remaining_health * 0.4))) // More damage as the shield has less health left when it expires.

	var/final_damage = (shock_base_damage) * (remaininghealthmod)
	final_damage*=fortitudemod

	var/final_radius = shock_radius // Radius is increased by 1 tile if we got close to shattering.
	if(remaining_health < 40)
		final_radius += 1

	playsound(get_turf(user), 'sound/abnormalities/kqe/hitsound2.ogg', 100, FALSE, 10)
	for(var/turf/T in view(final_radius, user))
		new /obj/effect/temp_visual/blubbering_smash(get_turf(T))
		for(var/mob/living/L in T)
			if(user.faction_check_mob(L))
				continue
			L.deal_damage(final_damage, BLACK_DAMAGE, user, attack_type = (ATTACK_TYPE_SPECIAL | ATTACK_TYPE_COUNTER))
			new /obj/effect/temp_visual/justitia_effect(T)

// For the Eldtree realization. Prevents enemies from swapping targets to anybody but the caster, makes them take extra WHITE damage on hit, and if the caster dies while this is active, they retaliate with a spike explosion.
/obj/effect/proc_holder/ability/fairy_lure
	name = "Fairy Lure"
	desc = "Applies the 'Distracted' status effect to nearby enemies, forcing them to target you and making them take extra WHITE damage on hit. \n\
	'Distracted' lasts until a certain amount of WHITE damage is caused by it or until it times out.\n\
	This ability scales with Temperance starting at 120 and its bonuses reach their maximum at 200 Temperance. These bonuses include the range, cooldown, debuff duration and debuff damage cap. Base Cooldown: 50s."
	action_icon_state = "fairy_lure"
	base_icon_state = "fairy_lure"
	cooldown_time = 50 SECONDS
	var/ready = TRUE
	var/activated = FALSE

	/// Base radius (tiles) of the Lure. Scales with Temperance.
	var/base_ability_range = 5
	/// Base duration of the Lured debuff. Scales with Temperance. Remember that it can end early via damage.
	var/base_debuff_duration = 8 SECONDS
	/// Base maximum damage during the Lured debuff. After it's dealt this much WHITE damage pre-reductions, it'll be destroyed (or it can time out first). Scales with Temperance.
	var/base_debuff_damagecap = 500

	// Temperance scaling vars for the ability. It's basically linear scaling.
	var/tempscaling_lowest_temp = 120
	var/tempscaling_highest_temp = 200

	// These vars establish the limit of the bonuses that can be gained by having a higher Temperance. Most Agents will get the realization at about 115-130 Temp, a decked out Agent should have like 130-150 Temp, if you spec into Temp you probably are gonna end up at about 160ish, only real psychopaths can get up to 200
	var/tempscaling_max_ability_range_increase = 7
	var/tempscaling_max_ability_cd_decrease = 28 SECONDS
	var/tempscaling_max_debuff_duration_increase = 11 SECONDS
	var/tempscaling_max_debuff_damagecap_increase = 900

	// These vars control the power of the spike explosion if the user dies while under this ability's power.
	var/martyrdom_radius = 8
	var/martyrdom_base_damage = 1500
	var/martyrdom_damage_falloff_per_tile = 100

	// Filter stuff stolen from Arbiters. This is a visual effect
	var/filter
	var/f1

/// This proc maps the user's temperance to a certain value, we use this for providing temperance scaling to our cooldown, range, duration and damage cap.
// Send user's temperance as first argument and the tempscaling_max_X var that we're scaling for, this returns a scaled value according to the user's temperance relative to its minimum and maximum scaling values.
// Example: With Temperance 150, tempscaling_lowest_temp of 120, tempscaling_highest_temp of 200 and a tempscaling_max_ability_cd_decrease of 200 (20 seconds), we will get 75 deciseconds (7.5s) of CDR.
/obj/effect/proc_holder/ability/fairy_lure/proc/LinearTempScalingMap(usertemp, max_increase)
	return floor(min(max_increase, ((usertemp - tempscaling_lowest_temp) * (max_increase) / (tempscaling_highest_temp - tempscaling_lowest_temp))))

/obj/effect/proc_holder/ability/fairy_lure/Perform(target, mob/user)
	if((!ready) || (activated)) // Can only cast this once it's off cooldown and the debuff has timed out from any enemies it's on.
		to_chat(user, span_warning("This ability isn't ready yet."))
		return FALSE
	var/mob/living/carbon/human/caster = user
	if(!istype(caster))
		return
	var/obj/item/clothing/suit/armor/ego_gear/realization/eldtree/eldtree_armour = caster.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(!istype(eldtree_armour))
		return

	var/final_ability_cooldown = cooldown_time
	var/final_ability_range = base_ability_range
	var/final_debuff_duration = base_debuff_duration
	var/final_debuff_damagecap = base_debuff_damagecap

	var/user_temperance = (get_modified_attribute_level(caster, TEMPERANCE_ATTRIBUTE))
	if((user_temperance > tempscaling_lowest_temp) && (tempscaling_lowest_temp != tempscaling_highest_temp)) // Activate temp scaling if our temperance is above the minimum for scaling, and that second conditional is to avoid division by zero errors
		// I know this looks like a mess
		// We are essentially linearly mapping the user's temperance between the minimum temp scaling amount and maximum temp scaling amount to a value between 0 and the maximum of the respective scaling.
		// We use min() to ensure you can't get higher values than the maximum scaling allowed, and we use floor() to get rid of decimals.
		// Basically more temp = better
		var/scaled_cdr = LinearTempScalingMap(user_temperance, tempscaling_max_ability_cd_decrease)
		var/scaled_extra_range = LinearTempScalingMap(user_temperance, tempscaling_max_ability_range_increase)
		var/scaled_extra_duration = LinearTempScalingMap(user_temperance, tempscaling_max_debuff_duration_increase)
		var/scaled_extra_damagecap = LinearTempScalingMap(user_temperance, tempscaling_max_debuff_damagecap_increase)

		final_ability_cooldown = max(1, final_ability_cooldown - scaled_cdr)
		final_ability_range += scaled_extra_range
		final_debuff_duration += scaled_extra_duration
		final_debuff_damagecap += scaled_extra_damagecap

	playsound(get_turf(caster), 'sound/abnormalities/faelantern/faelantern_giggle.ogg', 75, 0, 5)
	caster.visible_message(span_danger("[caster] shines with an ominous glow, hypnotizing nearby enemies to focus on them!"), span_nicegreen("You resonate with your [eldtree_armour.name] E.G.O. armour, distracting nearby enemies."))

	for(var/turf/T in view(final_ability_range, user))
		new /obj/effect/temp_visual/gravpush(T)
		for(var/mob/living/simple_animal/hostile/L in T)
			if(user.faction_check_mob(L, FALSE))
				continue
			if(L.stat >= DEAD)
				continue
			if(L.status_flags & GODMODE)
				continue

			L.apply_status_effect(/datum/status_effect/display/eldtree_lured, caster, final_debuff_damagecap, final_debuff_duration)
			L.FindTarget(list(caster), TRUE) // We use FindTarget instead of GiveTarget in case someone wants to override their mob's FindTarget so we don't disrupt it here

	activated = TRUE
	ready = FALSE

	// Filter visual
	if(!filter)
		filter = TRUE
		user.add_filter("eldtree_caster", 3, list("type"="drop_shadow", "x"=0, "y"=0, "size"=5, "offset"=2, "color"=rgb(4, 30, 87), "name" = "eldtree_caster"))

	f1 = user.filters["eldtree_caster"]
	animate(f1,color = rgb(3, 1, 22),time=5)

	// Setting cooldown and ability end
	addtimer(CALLBACK(src, PROC_REF(AbilityEnd), user), final_debuff_duration, TIMER_UNIQUE|TIMER_OVERRIDE) // Latest time at which the debuff wears off the enemies
	addtimer(CALLBACK(src, PROC_REF(Refresh), user), final_ability_cooldown) // When the ability comes off CD
	RegisterSignal(user, COMSIG_LIVING_DEATH, PROC_REF(Martyrdom))
	cooldown = world.time + final_ability_cooldown
	update_icon()

/// This is called at the end of our cooldown, to re-enable the skill.
/obj/effect/proc_holder/ability/fairy_lure/proc/Refresh(mob/living/carbon/human/user)
	ready = TRUE
	if(!activated)
		ReadyAlert(user)

/// This is called at the end of the debuff timeout, when we're sure no enemies have the debuff anymore.
/obj/effect/proc_holder/ability/fairy_lure/proc/AbilityEnd(mob/living/carbon/human/user)
	UnregisterSignal(user, COMSIG_LIVING_DEATH)
	activated = FALSE
	INVOKE_ASYNC(src, PROC_REF(ResetFilters), user)
	if(ready)
		ReadyAlert(user)

/// Removes the black glow effect from the user.
/obj/effect/proc_holder/ability/fairy_lure/proc/ResetFilters(mob/living/carbon/human/user)
	f1 = user.filters["eldtree_caster"]
	animate(f1,alpha=0,time=3)
	sleep(4)
	user.remove_filter("eldtree_caster")
	filter = null
	f1 = null

/// Alerts the player that they can use their ability again.
/obj/effect/proc_holder/ability/fairy_lure/proc/ReadyAlert(mob/living/carbon/human/user)
	if(!istype(user))
		return FALSE
	var/obj/item/clothing/suit/armor/ego_gear/realization/eldtree/our_suit = user.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(!istype(our_suit))
		return FALSE

	// Tell the user that they're ready to ball
	SEND_SOUND(user, sound('sound/abnormalities/faelantern/faelantern_uproot_finalpart.ogg'))
	flash_color(user, flash_color = COLOR_PALE_BLUE_GRAY, flash_time = 1 SECONDS)
	user.visible_message(span_danger("The eyes on [user]'s [our_suit.name] E.G.O. armour restlessly flit about in agitation."), span_nicegreen("Your [our_suit.name] E.G.O. armour's ability has recharged."))

/// Called when the user dies while under the effects of Fairy Lure. Big spike explosion that cares not for view. Scales off Fortitude.
/// It snapshots all the important stuff then calls the actual explosion as an async due to the fact it sleeps.
// I will remember you for as long as I live, John Faelantern.
/obj/effect/proc_holder/ability/fairy_lure/proc/Martyrdom(datum/source, gibbed)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/fallen_hero = source
	if(istype(fallen_hero))
		UnregisterSignal(fallen_hero, COMSIG_LIVING_DEATH)
		var/turf/epicenter = get_turf(fallen_hero)
		var/list/our_factions = fallen_hero.faction
		var/fallen_hero_name = fallen_hero.name
		INVOKE_ASYNC(src, PROC_REF(DeathSpikeExplosion), epicenter, our_factions, fallen_hero_name)
		return

// I'm taking you all with me...!!!!!!!!!!
/obj/effect/proc_holder/ability/fairy_lure/proc/DeathSpikeExplosion(turf/epicenter, list/friendly_factions, dead_name)
	if(!epicenter)
		return
	playsound(epicenter, 'sound/abnormalities/faelantern/faelantern_uproot.ogg', 90, FALSE, 10)
	epicenter.visible_message(span_userdanger("[dead_name]'s dead body erupts in a storm of roots and spikes!"))
	var/list/turf/already_hit_turfs = list()
	var/list/mob_hitlist = list()

	for(var/i in 1 to martyrdom_radius) // Hits the initial turf first, then the ones around it, then the ones around those... etc, while never repeating hit turfs.
		var/final_damage = martyrdom_base_damage - (martyrdom_damage_falloff_per_tile * (i - 1))
		var/spike_size = max(1 - ((i - 1) * 0.15), 0.4) // First spike looks bigger than the second set, etc

		for(var/turf/open/T in range(i - 1, epicenter)) // Only hits open turfs
			// Only hit each turf once
			if(T in already_hit_turfs)
				continue
			already_hit_turfs |= T

			// Spike visual
			var/obj/effect/temp_visual/faespike/fast/R = new(T)
			R.transform *= spike_size
			var/correct_direction = get_dir(epicenter, T)
			R.dir = correct_direction
			if(correct_direction & EAST)
				R.pixel_x += 16
			else if(correct_direction & WEST)
				R.pixel_x -= 16

			// Hit all non-faction members in that turf
			for(var/mob/living/victim in T)
				if(faction_check(friendly_factions, victim.faction, FALSE))
					continue
				if(victim in mob_hitlist)
					continue
				if(victim.stat >= DEAD)
					continue
				if(victim.status_flags & GODMODE)
					continue
				mob_hitlist |= victim
				victim.deal_damage(final_damage, RED_DAMAGE, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL | ATTACK_TYPE_COUNTER))
				victim.visible_message(span_danger("[victim] is pierced by a vengeful burrowing root!"), span_userdanger("You're pierced by a vengeful burrowing root!"))
				playsound(T, 'sound/weapons/ego/lce_lantern_spike_hit.ogg', 60, TRUE, 6)
				// Hit VFX
				var/obj/effect/temp_visual/dir_setting/slash/temp = new (T)
				temp.dir = pick(NORTHWEST, NORTHEAST, EAST, WEST)
				temp.color = "#dfb440"
				temp.transform *= 1.9
				temp.layer = POINT_LAYER + 1

				if(!victim)
					continue

		sleep(0.1 SECONDS) // This kinda makes it possible for enemies to dodge it like players can dodge a WN pulse but, you know, lock in?

// This is the status effect applied by Fairy Lure. It does two important things:
// 1. Anytime an enemy tries to swap target to anything but the caster of Fairy Lure, it will be rejected
// 2. When the enemy takes damage from anything but environmental damage, they'll take 10 flat WHITE damage + 10% of the original damage as additional WHITE damage.
// It will also apply a visual filter to the enemy.
// The debuff will either time out based on the 'debuff_duration' on_creation argument, or once available_damage reaches 0.
/datum/status_effect/display/eldtree_lured
	id = "eldtree_lured"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1 // We remove this with a timer set by the ability that causes it.
	tick_interval = -1 // We don't need to tick
	alert_type = null
	display_name = "fairy_lure"

	var/mob/living/simple_animal/hostile/lured
	var/mob/living/carbon/human/eldtree_user
	var/onhit_available_damage = INFINITY
	var/onhit_base_flat_damage = 25
	var/onhit_original_damage_coeff = 0.15
	var/timeout_timer
	var/filter
	var/f1

// We use on_creation instead of on_apply because it's more convenient since we have easy access to the arguments used to create the status.
/datum/status_effect/display/eldtree_lured/on_creation(mob/living/simple_animal/hostile/new_owner, mob/living/carbon/human/caster, damagecap, debuff_duration)
	if(!(..()))
		return FALSE
	// Ensure we get a valid caster, owner, damage cap and duration.
	if(!(istype(new_owner)) || !(istype(caster)))
		return FALSE
	if(!(damagecap > 0) || !(debuff_duration > 0))
		return FALSE
	lured = new_owner
	eldtree_user = caster
	onhit_available_damage = damagecap
	timeout_timer = addtimer(CALLBACK(src, PROC_REF(DebuffEnd)), debuff_duration, TIMER_STOPPABLE) // Timer will have to get deleted if we end the debuff early from reaching damagecap

	// We add a visual filter here. Why not in on_apply? Because on_apply is actually being called way back in the ..() call in this proc, so the lines below it (setting lured and etc) haven't happened
	if(!filter)
		filter = TRUE
		lured.add_filter("eldtree_lured", 3, list("type"="drop_shadow", "x"=0, "y"=0, "size"=2, "offset"=2, "color"=rgb(4, 30, 87), "name" = "eldtree_lured"))

	f1 = lured.filters["eldtree_lured"]
	animate(f1,color = rgb(3, 1, 22),time=5)

	RegisterSignal(lured, COMSIG_HOSTILE_GAINEDTARGET, PROC_REF(EyesOnMe))
	RegisterSignal(lured, COMSIG_MOB_APPLY_DAMGE, PROC_REF(ReceiveOnhitDamage))
	RegisterSignal(lured, COMSIG_LIVING_DEATH, PROC_REF(DebuffEnd))
	RegisterSignal(eldtree_user, COMSIG_LIVING_DEATH, PROC_REF(DebuffEnd))
	return TRUE

/datum/status_effect/display/eldtree_lured/on_remove()
	. = ..()
	if(lured)
		UnregisterSignal(lured, COMSIG_HOSTILE_GAINEDTARGET)
		UnregisterSignal(lured, COMSIG_MOB_APPLY_DAMGE)
		UnregisterSignal(lured, COMSIG_LIVING_DEATH)
		UnregisterSignal(eldtree_user, COMSIG_LIVING_DEATH)
		lured.remove_filter("eldtree_lured")
		filter = null
		f1 = null

/datum/status_effect/display/eldtree_lured/proc/DebuffEnd()
	qdel(src)

// Called when a mob with this status effect runs GiveTarget.
/datum/status_effect/display/eldtree_lured/proc/EyesOnMe(mob/living/simple_animal/hostile/source, atom/new_target)
	SIGNAL_HANDLER
	if((eldtree_user) && (new_target != eldtree_user))
		lured.FindTarget(list(eldtree_user), TRUE) // Make them target us instead. The TRUE argument is the only thing that stands between this code and the server box getting instantly nuked, don't ask me why this proc asks for a "HasTargetsList" argument when it could just check if it was given a list
		return COMPONENT_HOSTILE_REFUSE_AGGRO // Reject their attempt to swap targets

// Called when a mob with this status effect takes damage.
/datum/status_effect/display/eldtree_lured/proc/ReceiveOnhitDamage(mob/us, damage_amount, damage_type, def_zone, mob/attacker, damage_flags, attack_type)
	SIGNAL_HANDLER
	if(attack_type & (ATTACK_TYPE_ENVIRONMENT | ATTACK_TYPE_STATUS))
		return
	if(!(IsColorDamageType(damage_type)) && (damage_type != BRUTE))
		return
	var/lured_incoming_damage_coeff = lured.damage_coeff.getCoeff(damage_type)
	var/lured_white_coeff = lured.damage_coeff.getCoeff(WHITE_DAMAGE)
	if(damage_amount < 1 || lured_incoming_damage_coeff <= 0 || lured_white_coeff <= 0)
		return
	if(!CheckDamageCap())
		return
	var/damage_to_deal = floor(onhit_base_flat_damage + (damage_amount * onhit_original_damage_coeff))
	damage_to_deal = clamp(damage_to_deal, 1, onhit_available_damage)
	lured.deal_damage(damage_to_deal, WHITE_DAMAGE, source = eldtree_user, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_STATUS))
	onhit_available_damage -= damage_to_deal
	CheckDamageCap()

/datum/status_effect/display/eldtree_lured/proc/CheckDamageCap()
	if(onhit_available_damage < 1)
		qdel(src)
		return FALSE
	return TRUE

// For the Crimson Lust realization.
/// A moderately powerful AoE attack that can FF. Every target hit gives you more Power Modifier. While the buff is active, you can dualwield the CrimScar guns.
// Based on Ruina's combat page, idea was from Potassium_19
/obj/effect/proc_holder/ability/strike_without_hesitation
	name = "Strike Without Hesitation"
	desc = "After a 2 second wind-up, throw your hunting blades towards anything in the vicinity, dealing 300 RED damage indiscriminately to anything within 6 tiles of you. Humans take 66% less damage. \n\
	Gain 5 Power Modifier per target hit by this ability for 15 seconds, up to 50 Power Modifier. While the buff is active, you may dual wield Crimson Scar handcannons and your Crimson Claw's throw will hit all nearby enemies. Additionally, refreshes the duration of the buff earned from Hunter's Mark. \n\
	Cooldown: 45s."
	action_icon = 'icons/obj/projectiles.dmi'
	action_icon_state = "hunter_blade"
	base_icon_state = "hunter_blade"
	cooldown_time = 45 SECONDS
	/// Radius of the ability, in tiles.
	var/radius = 6
	/// Power Modifier (attack damage and movespeed) gained per target hit.
	var/powermod_per_target = 5
	/// Maximum amount of Power Modifier that can be gained with the skill.
	var/powermod_cap = 50
	/// Base damage dealt, always RED.
	var/base_damage = 300
	/// Multiply damage dealt against Carbons by this amount (they take less damage)
	var/carbon_coeff = 0.34
	/// Amount of time it takes to execute this skill, this is also how long allies have to flee if they don't wanna get caught in it, and how long the telegraph lasts.
	var/windup = 2 SECONDS

	var/datum/reusable_visual_pool/RVP = new(100)

/obj/effect/proc_holder/ability/strike_without_hesitation/Perform(target, mob/living/user)
	var/mob/living/carbon/human/our_guy = user
	if(!istype(our_guy))
		return FALSE
	var/obj/item/clothing/suit/armor/ego_gear/realization/crimson/our_suit = user.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(!istype(our_suit))
		return FALSE
	cooldown = world.time + windup + 1 // Just in case someone wants to be funny and spam this
	update_icon()
	user.say("No hesitation!")
	playsound(user, 'sound/abnormalities/crumbling/warning.ogg', 60, FALSE, 4)
	user.visible_message(span_userdanger("[user] twitches, a frenzied look in \his eyes...!"))
	var/list/danger_turfs = oview(radius, user)
	for(var/turf/T in danger_turfs)
		RVP.NewCultSparks(T, windup)

	if(!do_after(our_guy, windup, timed_action_flags = IGNORE_HELD_ITEM, interaction_key = "strike_without_hesitation", max_interact_count = 1))
		qdel(RVP) // Clears our telegraph visuals on an early cancel
		RVP = new(100) // We kinda need that pool back though
		return
	. = ..()

	user.SpinAnimation(4, 1)
	playsound(user, 'sound/abnormalities/redhood/throw.ogg', 100, TRUE, 3)
	user.visible_message(span_danger("[user] flings hunting blades into the air!"))

	var/targets_hit = MultiThrowScan(user, danger_turfs)
	var/final_powermod = min((targets_hit * powermod_per_target), powermod_cap)
	// Gain status effect here.
	our_guy.apply_status_effect(/datum/status_effect/crimlust_no_hesitation, final_powermod, our_suit)

/obj/effect/proc_holder/ability/strike_without_hesitation/proc/MultiThrowScan(mob/living/user, list/turfs_to_check)
	if(!ishuman(user))
		return
	var/targets_found = 0
	for(var/turf/T in turfs_to_check)
		for(var/mob/living/target in T)
			if(target == user)
				continue
			if((target.stat >= DEAD) || (target.status_flags & GODMODE))
				continue
			if(istype(target, /mob/living/simple_animal/projectile_blocker_dummy))
				continue
			targets_found++

			// This little block of code staggers out the blades falling on the enemies in a non-uniform way
			var/delay = targets_found
			delay++
			if(prob(50))
				delay++
			addtimer(CALLBACK(src, PROC_REF(BladeImpact), target, user), delay)

	if(targets_found <= 0)
		to_chat(user, span_warning("There's nothing nearby...! Your frustration sends you into an impotent rage!")) // I mean you'll still get the buff, but 0 power modifier and it hit nothing

	return targets_found

// A hunting blade 'falls' on the target.
/obj/effect/proc_holder/ability/strike_without_hesitation/proc/BladeImpact(mob/living/A, mob/living/user)
	if(QDELETED(A))
		return
	var/turf/target_turf = get_turf(A)

	var/dealing_damage = base_damage

	// Effects
	var/obj/effect/temp_visual/unhesitant_blade/B = new /obj/effect/temp_visual/unhesitant_blade(target_turf)
	B.alpha = 120
	B.pixel_z += 180
	B.pixel_x += rand(-128, 128)
	animate(B, alpha = 250, pixel_x = 0, pixel_z = 0, time = 2)
	animate(alpha = 0, time = 1)
	B.SpinAnimation(3, 2)
	sleep(1)
	if(istype(A))
		if(iscarbon(A))
			dealing_damage *= carbon_coeff
		A.visible_message(span_danger("[A] is hit by a falling hunter's blade!"), span_userdanger("You are hit by a falling hunter's blade!"))
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(A), pick(GLOB.alldirs))
		playsound(A, 'sound/abnormalities/redhood/attack_3.ogg', 33, TRUE, 3)
		A.deal_damage(dealing_damage, RED_DAMAGE, user, attack_type = (ATTACK_TYPE_SPECIAL)) // Damage has to be last in case it qdels the enemy </3


// A replacement for the decoy we'd usually be able to use with Crimson Claw throwing code (we don't have access to an atom to pass into decoy creation)
/obj/effect/temp_visual/unhesitant_blade
	name = "unhesitant blade"
	icon = 'icons/obj/ego_weapons.dmi'
	icon_state = "crimsonclaw"
	duration = 1 SECONDS
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/// No Hesitation status effect. Gives you a certain amount of power modifier (can be 0 if you hit nothing with the skill), and allows you to dual wield CrimScars.
// The code for this dual wielding is kinda split between this status effect and the gun itself, the reason for this is that I want to make 100% sure it affects any CrimScars you may have.
// We could, of course, go the much simpler route of only applying the effect to the guns you're holding, or the guns you have stored in specific slots if you want to be fancy, but I thought this approach was better.
/datum/status_effect/crimlust_no_hesitation
	id = "crimlust_no_hesitation"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 15 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/no_hesitation
	var/powermod_bonus = 0
	var/list/modified_guns = list()
	var/obj/item/clothing/head/ego_hat/helmet/crimson/spawned_hood

/atom/movable/screen/alert/status_effect/no_hesitation
	name = "No Hesitation"
	desc = "You're driven by vengeful conviction. Power Modifier is increased by "
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "strength"

/datum/status_effect/crimlust_no_hesitation/on_creation(mob/living/new_owner, power_modifier = 0)
	if(!(..()))
		return FALSE
	if(!(ishuman(new_owner)))
		return FALSE
	var/mob/living/carbon/human/our_guy = new_owner

	powermod_bonus = power_modifier

	// If we have the Mark Payout status effect, link to it here
	var/datum/status_effect/crimlust_mark_payout/successful_mercenary = our_guy.has_status_effect(/datum/status_effect/crimlust_mark_payout)
	if(successful_mercenary)
		successful_mercenary.LinkBuffs(src)

	// We now need to find any CrimScars that may be in our mainhand or offhand and allow us to dual wield them. This isn't necessary for CrimScars anywhere else in our inventory,
	// because they will need to be passed into the hands at some point and we handle applying the weapon weight change in their equipped(). But any guns already in our hands need this block of code.
	var/obj/item/ego_weapon/ranged/pistol/crimson/mainhand_gun = new_owner.get_active_held_item()
	if(istype(mainhand_gun))
		mainhand_gun.weapon_weight = WEAPON_LIGHT
		mainhand_gun.realization_empowered_mode = TRUE
		modified_guns |= mainhand_gun
	var/obj/item/ego_weapon/ranged/pistol/crimson/offhand_gun = new_owner.get_inactive_held_item()
	if(istype(offhand_gun))
		offhand_gun.weapon_weight = WEAPON_LIGHT
		offhand_gun.realization_empowered_mode = TRUE
		modified_guns |= offhand_gun

	our_guy.adjust_attribute_bonus(JUSTICE_ATTRIBUTE, powermod_bonus)
	linked_alert.desc = initial(linked_alert.desc)+"[powermod_bonus], your Crimson Claw's throw hits all nearby targets, and you may dual-wield Crimson Scars."

	// This snippet is "borrowed" and modified from EGO hat code. We will forcefully put a hood on, unless for some reason we can't remove their hat
	var/obj/item/clothing/head/headgear = our_guy.get_item_by_slot(ITEM_SLOT_HEAD)
	if(isnull(headgear))
		spawned_hood = new
		our_guy.equip_to_slot(spawned_hood, ITEM_SLOT_HEAD) // Equip the hood!
	else if(!HAS_TRAIT(headgear, TRAIT_NODROP))
		our_guy.dropItemToGround(headgear) // Drop the other hat, if it exists.
		spawned_hood = new
		our_guy.equip_to_slot(spawned_hood, ITEM_SLOT_HEAD) // Equip the hood!

	return TRUE


// We need a destroy AND remove override, destroy specifically because on_remove isn't called when the owner is qdel'd
/datum/status_effect/crimlust_no_hesitation/Destroy(force)
	for(var/obj/item/ego_weapon/ranged/pistol/crimson/did_you_try_smuggling_one_of_these in modified_guns) // Edge case of someone juggling like 500 guns and trying to permanently make one dual wieldable
		if(!QDELETED(did_you_try_smuggling_one_of_these))
			did_you_try_smuggling_one_of_these.weapon_weight = WEAPON_MEDIUM
			did_you_try_smuggling_one_of_these.realization_empowered_mode = FALSE
			modified_guns -= did_you_try_smuggling_one_of_these

	if(spawned_hood)
		QDEL_NULL(spawned_hood)

	return ..()


/datum/status_effect/crimlust_no_hesitation/on_remove()
	. = ..()
	var/mob/living/carbon/human/our_guy = owner
	if(!istype(our_guy))
		return

	var/obj/item/ego_weapon/ranged/pistol/crimson/mainhand_gun = owner.get_active_held_item()
	if(istype(mainhand_gun))
		mainhand_gun.weapon_weight = WEAPON_MEDIUM
		mainhand_gun.realization_empowered_mode = FALSE
	var/obj/item/ego_weapon/ranged/pistol/crimson/offhand_gun = owner.get_inactive_held_item()
	if(istype(offhand_gun))
		offhand_gun.weapon_weight = WEAPON_MEDIUM
		offhand_gun.realization_empowered_mode = FALSE

	our_guy.adjust_attribute_bonus(JUSTICE_ATTRIBUTE, -powermod_bonus)

