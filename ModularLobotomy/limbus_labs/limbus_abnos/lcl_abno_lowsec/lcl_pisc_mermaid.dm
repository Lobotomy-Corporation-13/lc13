/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid
	true_name = "Piscine Mermaid"
	maxHealth = 1000
	health = 1000
	damage_coeff = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 2)
	melee_damage_lower = 5
	melee_damage_upper = 10
	melee_damage_type = WHITE_DAMAGE //When not breached, her attacks deal white damage, since she's only being needy and not violent.
	pixel_x = -12
	base_pixel_x = -12
	pet_bonus_emote = "smiles!"
	max_counter = 3
	abno_additional_instructions = "You like attachment and repression. You need love. You're willing to give so much for it.\
	You want to be hugged, or they can beat you up, you do not care, as long as they come back to you. \
	If you breach, the only thing that can bring you back to your senses is the immediate threat of death. Otherwise, your lover will sink into the depths with you. "
	original_abno = /mob/living/simple_animal/hostile/abnormality/pisc_mermaid
	attack_action_types = list(/datum/action/cooldown/limbus_abno_action/mermaid_chokehold, /datum/action/cooldown/limbus_abno_action/mermaid_telepathy, /datum/action/cooldown/limbus_abno_action/dive_dash)
	diet_list = list(/obj/item/food/freshfish, /obj/item/food/cake, /obj/item/food/cakeslice, /obj/item/food/chocolatebar) //Sweets and fish.
	hunger_cooldown_time =  2 MINUTES
	diet_value = 50
	kickstart_timer = 10 MINUTES //Same reason as mountain, she drops too fast early on and needs some time to get to know people.
	desire_cooldown_time = 1 MINUTES //Despite being lowsec, she's *extremely* needy and high maintenance. her mood dropping to 0 after only 10 minutes
	desire_on_eat = 3 //Way less efficient than petting, but you can theoretically keep her happy with cake spam.
	desire_on_pet = 5 //It's easy to do, but you need to pet her a ton before she's happy.
	rep_desire_gain = 0.2
	rep_desire_loss_at_threshold = 100
	rep_threshold = 100
	rep_min_damage = 10
	insight_cooldown_time = 2 MINUTES
	liked_objects_list = list(/obj/effect/decal/cleanable/food/salt)
	liked_objects_value = 10
	ego_list = list(
		/datum/ego_datum/weapon/unrequited,
		/datum/ego_datum/armor/unrequited,
	)
	breach_overlay_z = 45
	var/obj/item/clothing/head/unrequited_crown/crown
	var/mob/living/carbon/human/love_target
	var/mob/living/carbon/human/last_petter
	var/pet_count = 0
	var/breached = FALSE
	var/dashing = FALSE

/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/Initialize(mapload)
	. = ..()
	if(!limbus_map)
		return
	for(var/turf/open/T in range(2, src)) // Fill her cell with safe water
		T.TerraformTurf(/turf/open/water/deep/saltwater/safe, T)

/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/Life()
	. = ..()
	if(!breached)
		return
	if(isnull(love_target) || QDELETED(love_target))
		for(var/mob/living/carbon/human/H in oview(src, 10))
			if(IsFriend(H)) //Friends get spared from the oxyloss, but the lover won't be even if they're a friend.
				continue
			H.adjustOxyLoss(2, updating_health=TRUE, forced=TRUE)
			new /obj/effect/temp_visual/mermaid_drowning(get_turf(H))
		return

	love_target.adjustOxyLoss(4, updating_health = TRUE, forced = TRUE) //This effect's much stronger than the original, but she's (somewhat) easier to supress'
	new /obj/effect/temp_visual/mermaid_drowning(get_turf(love_target))

///Creates mermaid water in front of her, and removes the one that she left if any.
/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/Moved(datum/source)
	. = ..()
	var/turf/og_turf = get_turf(source)
	var/turf/newloc_turf = get_step(og_turf, dir)

	if(og_turf == newloc_turf)
		return .

	for(var/obj/effect/mermaid_water/water in og_turf)
		if(!water.belongs_to_mermaid)
			continue
		animate(water, alpha = 0, time = 2 SECONDS)
		QDEL_IN(water, 2 SECONDS)

	if(dashing)
		return .

	if(istype(newloc_turf, /turf/open/water))
		return .

	var/obj/effect/mermaid_water/new_water = new (newloc_turf)
	new_water.alpha = 0
	new_water.belongs_to_mermaid = TRUE
	animate(new_water, alpha = 255, time = 0.25 SECONDS)

/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/attackby(obj/item/W, mob/user, params)
	. = ..()
	if(love_target == user)
		adjustBruteLoss(W.force * 1.5)
	if(breached && health < 200)
		Unbreach()
		return

/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/death()
	. = ..()
	Unbreach()
	if(crown)
		qdel(crown)

/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/funpet(mob/living/carbon/human/petter)
	..()
	petter.adjustWhiteLoss(10)
	if(last_petter == petter)
		pet_count++
	else
		pet_count = 0
		last_petter = petter

	if(pet_count > 4 && isnull(love_target))
		AssignLover(petter)
		var/obj/item/clothing/head/LCL_unrequited_crown/new_crown = new (get_turf(src))
		insight_cooldown = world.time + insight_cooldown_time //If the crown is still in the room at that time, she'll get angry.
		new_crown.mermaid = src
		crown = new_crown
		playsound(get_turf(src), 'sound/abnormalities/piscinemermaid/bigsplash.ogg', 50, 1)

	if(petter == love_target)
		AdjustDesire(25)

/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/InsightRoomResults(room_score, list/room_obj_list)
	..()
	if(room_obj_list.Find(crown))
		to_chat(src, span_warning("Why is your gift still there? Why didn't they take it? Why. Why. Why."))
		AdjustDesire(-20)

/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/AdjustHunger(feeding_amount)
	..()
	if(starving && !IsPositive(feeding_amount))
		AdjustDesire(15) //Ironically, letting her starve increases her mood due to liking repression work and disliking instinct.

/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/AdjustCounter(counter_amount)
	if(breached)
		return
	..()
	if(counter <= 0)
		BreachState()
		MermaidChokehold()

/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/AdjustDesire(desire_amount)
	. = ..()
	if(!.)
		return FALSE

	if(IsPositive(desire_amount) && desire_bar > 70)
		AdjustCounter(1)
	else if(!IsPositive(desire_amount) && desire_bar < 35)
		AdjustCounter(-1)
	return TRUE

/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/proc/AssignLover(mob/living/carbon/human/lover, assign = TRUE)
	if(assign)
		love_target = lover
		desire_cooldown_time = 1 MINUTES
	else
		love_target = null
		desire_cooldown_time = 30 SECONDS
	UpdateBars()

///Not a skill, only happens at counter 0 entirely outside the mermaid's control. Buffed skills, attacks, and generally a pain in the ass.
/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/proc/BreachState()
	icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
	icon_state = "pmermaid_breach"
	pixel_x = 0
	base_pixel_x = 0
	pixel_y = -16
	base_pixel_y = -16
	breached = TRUE
	melee_damage_lower = 25
	melee_damage_upper = 30
	melee_damage_type = BLACK_DAMAGE
	unstable = TRUE
	AddBreachEffect()

/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/proc/Unbreach()
	manual_emote("calms down...")
	icon = 'ModularLobotomy/_Lobotomyicons/48x32.dmi'
	icon_state = "pmermaid_standing"
	pixel_x = -12
	base_pixel_x = -12
	pixel_y = 0
	base_pixel_y = 0
	breached = FALSE
	melee_damage_lower = 5
	melee_damage_upper = 10
	melee_damage_type = WHITE_DAMAGE
	unstable = FALSE
	AdjustDesire(max_desire)
	AdjustCounter(max_counter)
	AdjustHunger(max_hunger)
	RemoveBreachEffect()

///Allows telepathy to the love target specifically. A telepathy skill already exists, but I'd rather use the limbus abno action for consistency and ease of use.
/datum/action/cooldown/limbus_abno_action/mermaid_telepathy
	name = "Talk to them"
	desc = "Distance is no excuse for neglect. Can only be used if you have a lover. Regains a little bit of desire when used."
	icon_icon = 'icons/mob/actions/actions_changeling.dmi'
	button_icon_state = "hivemind_channel"
	transparent_when_unavailable = TRUE
	cooldown_time = 5 SECONDS

/datum/action/cooldown/limbus_abno_action/mermaid_telepathy/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/mermaid = abno_user
	if(isnull(mermaid.love_target) || QDELETED(mermaid.love_target))
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/mermaid_telepathy/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/mermaid = abno_user
	var/mob/living/love_target = mermaid.love_target

	//Slightly tweaked telepathy code.
	var/msg = stripped_input(usr, "What do you wish to tell [love_target]?", null, "")
	if(!msg)
		return FALSE
	log_directed_talk(mermaid, love_target, msg, LOG_SAY, "[name]")
	to_chat(mermaid, "<span class='revenboldnotice'>You transmit to [love_target]:</span> <span class='revennotice'>[msg]</span>")
	to_chat(love_target, "<span class='revenboldnotice'>You can hear her voice in the back of your mind... </span> <span class='revennotice'>[msg]</span>")
	for(var/ded in GLOB.dead_mob_list)
		if(!isobserver(ded))
			continue
		var/follow_rev = FOLLOW_LINK(ded, mermaid)
		var/follow_whispee = FOLLOW_LINK(ded, love_target)
		to_chat(ded, "[follow_rev] <span class='revenboldnotice'>[mermaid] [name]:</span> <span class='revennotice'>\"[msg]\" to</span> [follow_whispee] [span_name("[love_target]")]")
	mermaid.AdjustDesire(10) //It's very easy to spam to gain desire back, which is kind of the point.
	to_chat(mermaid, span_notice("Talking to [love_target] soothes you."))
	StartCooldown()

///Teleports to the chosen tile, making a mess of things and shoving people out of the way.
/datum/action/cooldown/limbus_abno_action/dive_dash
	name = "Dive and Dash"
	desc = "Lets you dive into the floor and come back up to the spot, doing so violently shoves people out of the way. Only works on spots you have a direct path to."
	icon_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = "porccubus_toggle0"
	transparent_when_unavailable = TRUE
	cooldown_time = 1 MINUTES

/datum/action/cooldown/limbus_abno_action/dive_dash/Trigger()
	. = ..()
	if(!.)
		return
	var/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/mermaid = abno_user
	if(mermaid.ranged) //We assume she somehow has no valid tile to dive into.
		if(!mermaid.breached)
			mermaid.icon_living = "pmermaid_standing"
			mermaid.icon_state = "pmermaid_standing"
		mermaid.manual_emote("rises from the water.")
		return FALSE

	mermaid.ranged = TRUE
	mermaid.manual_emote("is lowering herself deeper into the water.")
	ADD_TRAIT(mermaid, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT("mermaid_dive"))
	if(!mermaid.breached)
		mermaid.icon_living = "pmermaid_laying"
		mermaid.icon_state = "pmermaid_laying"
	StartCooldown()

/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/proc/DiveDash(turf/T)
	REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT("mermaid_dive"))
	if(!breached)
		icon_living = "pmermaid_standing"
		icon_state = "pmermaid_standing"

	dashing = TRUE
	forceMove(T)
	dashing = FALSE
	var/obj/effect/mermaid_water/new_water = new (T)
	new_water.alpha = 0
	new_water.belongs_to_mermaid = TRUE
	animate(new_water, alpha = 255, time = 0.25 SECONDS)
	var/list/turfs = list()
	for(var/turf/turf in range(1, src))
		turfs.Add(turf)
	var/obj/effect/proc_holder/spell/aoe_turf/repulse/R = new(null) //I could make a new subtype but why bother.
	R.cast(turfs, src, 10)
	playsound(get_turf(src), 'sound/abnormalities/piscinemermaid/bigsplash.ogg', 50, 1)

/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/OpenFire(atom/A)
	var/list/dive_line = getline(src, A)
	var/available_turf = TRUE
	for(var/turf/line_turf in dive_line) //checks if there's a valid path between the turf and the friend
		if(line_turf.is_blocked_turf_ignore_climbable() && line_turf.is_blocked_turf(TRUE))
			available_turf = FALSE
	if(available_turf)
		ranged = FALSE
		DiveDash(get_turf(A))

///If a love target exist, instantly teleport to them, create water under them, and Immobilize (not stun) them for 15 seconds.
///This ability has a low cooldown, but requires low desire, so it can't be spammed if she's handled properly.
/datum/action/cooldown/limbus_abno_action/mermaid_chokehold
	name = "Find them"
	desc = "They're not paying attention to you. Pin them down and force them to. Can only be used on low desire. Will cause a breach if they leave you unsatisfied."
	icon_icon = 'icons/mob/actions/actions_animal.dmi'
	button_icon_state = "adjust_vision"
	transparent_when_unavailable = TRUE
	cooldown_time = 1 MINUTES
	desire_req = 50

/datum/action/cooldown/limbus_abno_action/mermaid_chokehold/Trigger()
	if(abno_user.desire_bar > desire_req)
		to_chat(abno_user, span_notice("It's fine, they'll come back. You just need to be patient..."))
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/mermaid = abno_user
	if(mermaid.MermaidChokehold())
		StartCooldown()

/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/proc/MermaidChokehold()
	if(isnull(love_target) || QDELETED(love_target))
		return FALSE
	var/water_range = 1
	if(breached)
		water_range = 4 //This is basically to make the breach very obvious, but doesn't do much mechanically.
	var/turf/loved_turf = get_turf(love_target)
	var/list/water_list = list()
	for(var/turf/open/T in oview(love_target, water_range))
		if(!T.is_blocked_turf(exclude_mobs = TRUE))
			var/obj/effect/mermaid_water/water = new(T)
			water_list += water
	var/chokehold_duration = 15 SECONDS
	if(breached)
		chokehold_duration = 5 SECONDS
	else
		icon_living = "pmermaid_laying"
		icon_state = icon_living
	ADD_TRAIT(love_target, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT("mermaid_choke"))
	ADD_TRAIT(src, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT("mermaid_choke"))
	addtimer(CALLBACK(src, PROC_REF(EndMermaidChokehold), love_target, water_list), chokehold_duration)
	to_chat(love_target, span_userdanger("You can't move, you feel like you need to calm [src] down as fast as you can."))
	to_chat(src, span_userdanger("You decide to stand still so [love_target] pays attention to you."))
	var/list/valid_water_list = water_list.Copy()
	for(var/obj/effect/mermaid_water/water in valid_water_list)
		if(get_turf(water) == loved_turf)
			valid_water_list -= water
	if(!valid_water_list.len)
		return FALSE
	var/turf/picked_water = pick(valid_water_list)
	forceMove(get_turf(picked_water))
	playsound(get_turf(src), 'sound/abnormalities/piscinemermaid/waterjump.ogg', 50, 1)
	return TRUE

/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/proc/EndMermaidChokehold(mob/living/carbon/human/victim, list/water_list)
	if(desire_bar < 70)
		AdjustDesire(-100)
	if(!breached)
		icon_living = "pmermaid_standing"
		icon_state = icon_living
	REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT("mermaid_choke"))
	REMOVE_TRAIT(love_target, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT("mermaid_choke"))
	for(var/obj/effect/mermaid_water/water in water_list)
		if(QDELETED(water))
			continue
		animate(water, alpha = 0, time = 10 SECONDS)
		QDEL_IN(water, 10 SECONDS)

///Limbus version of the brooch. Doesn't give any buffs like the original, but makes handling the mermaid easier.
/obj/item/clothing/head/LCL_unrequited_crown
	name = "Unrequited Gift"
	desc = "Love me, please love me. I'll take off my arms, I'll cut down my legs. Just love me back."
	icon_state = "unrequited_gift"
	icon = 'icons/obj/clothing/ego_gear/head.dmi'
	worn_icon = 'icons/mob/clothing/ego_gear/head.dmi'
	var/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid/mermaid
	var/healing_cooldown_time = 15 SECONDS
	var/healing_cooldown
	var/worn = FALSE
	var/mob/living/carbon/human/wearer

/obj/item/clothing/head/LCL_unrequited_crown/process()
	if(!wearer || QDELETED(wearer))
		STOP_PROCESSING(SSobj, src)
		return
	if(healing_cooldown < world.time)
		new /obj/effect/temp_visual/heart(get_turf(wearer))
		wearer.adjustRedLoss(-wearer.maxHealth * 0.05)
		wearer.adjustWhiteLoss(-wearer.maxHealth * 0.05)
		healing_cooldown = world.time + healing_cooldown_time

/obj/item/clothing/head/LCL_unrequited_crown/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(isnull(mermaid))
		qdel(src)
		return
	if(slot == ITEM_SLOT_HEAD && ishuman(user))
		healing_cooldown = healing_cooldown_time + world.time
		wearer = user
		START_PROCESSING(SSobj, src)
		worn = TRUE
		mermaid.AdjustCounter(mermaid.max_counter)
		mermaid.AdjustDesire(mermaid.max_desire)
		mermaid.AssignLover(user) //If someone else wears it, it will override the previous love target.
	else if(slot != ITEM_SLOT_HEAD && worn)
		STOP_PROCESSING(SSobj, src)
		mermaid.AdjustCounter(-mermaid.max_counter)
		mermaid.AdjustDesire(-mermaid.max_desire)
		qdel(src)
