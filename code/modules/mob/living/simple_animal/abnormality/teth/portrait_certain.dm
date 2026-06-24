#define INTERLOPER_STATUS /datum/status_effect/display/interloper
/mob/living/simple_animal/hostile/abnormality/portrait_certain
	name = "portrait of a certain day"
	desc = "A headless humanoid wearing a large coat. Where the creatures legs should be is a large skull."
	icon = 'ModularLobotomy/_Lobotomyicons/96x64.dmi'
	icon_state = "portrait_certain"
	icon_living = "portrait_certain"
	portrait = "portrait_certain"
	threat_level = TETH_LEVEL
	maxHealth = 800
	health = 800
	pixel_x = -32
	base_pixel_x = -32
	melee_damage_lower = 15
	melee_damage_upper = 20
	melee_damage_type = RED_DAMAGE
	faction = list("hostile")
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 50,
		ABNORMALITY_WORK_INSIGHT = 50,
		ABNORMALITY_WORK_ATTACHMENT = 50,
		ABNORMALITY_WORK_REPRESSION = 50,
	)
	work_damage_amount = 6
	work_damage_type = WHITE_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/sloth
	//  Wrath x0.5, Sloth 1.5, Gluttony 1, Envy  0.75
	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 1, BLACK_DAMAGE = 0.75, PALE_DAMAGE = 1.5)
	can_breach = TRUE
	start_qliphoth = 2

	ego_list = list(
		/datum/ego_datum/weapon/recollection,
		/datum/ego_datum/armor/recollection,
	)
	gift_type =  /datum/ego_gifts/recollection

	abnormality_origin = ABNORMALITY_ORIGIN_LIMBUS

	observation_prompt = "My masters portrait, can you see it?"
	observation_choices = list(
		"I can" = list(TRUE, "Thank you, i can see him again reflected in your eye."),
		"I cant" = list(FALSE, "That cannot be, not after so much."),
	)

	//Amount of humans who can be marked
	var/marked_interloper_limit = 0
	//Amount of workticks
	var/worktick_event_count = 0
	//Cooldown for Portrait Attack
	var/portrait_cooldown = 0
	var/portrait_delay = 30 SECONDS
	//Amount of interlopers marked
	var/interloper_count = 0
	//Cooldown for interloper mark
	var/interloper_cooldown = 0
	var/interloper_delay = 10 SECONDS
	//Portrait memory game.
	var/old_portrait
	var/new_portrait
	var/angry = FALSE

	var/static/obj/structure/certain_portrait/picture
	var/list/interlopers = list()
	var/list/portraits = list()

/mob/living/simple_animal/hostile/abnormality/portrait_certain/HandleStructures()
	. = ..()
	if(!.)
		return
	if(!picture || isnull(picture))
		picture = SpawnConnectedStructure(/obj/structure/certain_portrait, 0, 2)

/mob/living/simple_animal/hostile/abnormality/portrait_certain/AttemptWork(mob/living/carbon/human/user, work_type)
	var/list/worktypes  = list(1 = ABNORMALITY_WORK_INSTINCT,2 = ABNORMALITY_WORK_INSIGHT,3 = ABNORMALITY_WORK_ATTACHMENT,4 = ABNORMALITY_WORK_REPRESSION)
	var/prefer_work = worktypes[old_portrait]
	if(old_portrait && prefer_work != work_type)
		say("You dont belong here.")
		visible_message("[src] attempts to weakly lunge at [user]!")
		angry = TRUE
	else
		say("My master, my poor master.")
	return TRUE

/mob/living/simple_animal/hostile/abnormality/portrait_certain/SpeedWorktickOverride(mob/living/carbon/human/user, work_speed, init_work_speed, work_type)
	if(angry)
		return init_work_speed * 0.7
	return work_speed

/mob/living/simple_animal/hostile/abnormality/portrait_certain/ChanceWorktickOverride(mob/living/carbon/human/user, work_chance, init_work_chance, work_type)
	if(angry)
		return work_chance / 2
	return work_chance

/mob/living/simple_animal/hostile/abnormality/portrait_certain/PostWorkEffect()
	. = ..()
	angry = FALSE
	if(QDELETED(picture))
		picture = SpawnConnectedStructure(/obj/structure/certain_portrait, 0, 2)

	if(prob(35))
		say("My master, can you remember him?")
	old_portrait = new_portrait
	var/list/possible_master = list(1,2,3,4)
	possible_master -= old_portrait
	new_portrait = pick(possible_master)
	picture.icon_state = "portrait[new_portrait]"
	picture.update_icon()

/mob/living/simple_animal/hostile/abnormality/portrait_certain/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/abnormality/portrait_certain/AttackingTarget(atom/attacked_target)
	. = ..()
	if(!can_act)
		return FALSE
	var/mob/living/carbon/L = attacked_target
	if(L.has_status_effect(INTERLOPER_STATUS))
		var/bonus_damage_dealt = (rand(melee_damage_lower,melee_damage_upper) * 0.2)
		L.deal_damage(bonus_damage_dealt, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE))

/mob/living/simple_animal/hostile/abnormality/portrait_certain/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/portrait_certain/Destroy()
	for(var/datum/status_effect/S in interlopers)
		qdel(S)
	DetonatePortraits(TRUE)
	interlopers.Cut()
	portraits.Cut()
	return ..()

/mob/living/simple_animal/hostile/abnormality/portrait_certain/death(gibbed)
	update_icon()
	density = FALSE
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	return ..()

/mob/living/simple_animal/hostile/abnormality/portrait_certain/handle_automated_action()
	. = ..()
	if(!can_act || IsContained() || stat == DEAD)
		return
	var/our_hp = PERCENT(health / maxHealth)
	//If less than 1 portrait in portraits list, portrait attack.
	if(target && portrait_cooldown <= world.time && length(portraits) < 1)
		Portraits()
		return
	if(target && interloper_cooldown <= world.time)
		CheckInterloper()
		marked_interloper_limit = round(100 - our_hp)
		if(length(interlopers) < marked_interloper_limit)
			InflictInterloper()
		interloper_cooldown = world.time + interloper_delay
		return

/mob/living/simple_animal/hostile/abnormality/portrait_certain/ValueTarget(atom/target_thing)
	. = ..()

	if(iscarbon(target_thing))
		var/mob/living/carbon/L = target_thing
		if(L.has_status_effect(INTERLOPER_STATUS))
			. += 10

/*-----*\
|Special|
\------*/
/mob/living/simple_animal/hostile/abnormality/portrait_certain/proc/VibeCheck(mob/living/carbon/agent, forced = FALSE)
	if(!IsContained() || QDELETED(picture))
		return FALSE

	say("My master, can you remember him?")
	var/list/possible_master = list(1,2,3,4)
	possible_master -= old_portrait
	picture.icon_state = "portrait[pick(possible_master)]"
	picture.update_icon()
	return TRUE

/mob/living/simple_animal/hostile/abnormality/portrait_certain/proc/InflictInterloper()
	for(var/mob/living/carbon/L in view(7, src))
		if(L.stat == DEAD || !iscarbon(L) || L.has_status_effect(INTERLOPER_STATUS))
			continue

		interlopers += L.apply_status_effect(INTERLOPER_STATUS)
		break
	if(prob(35))
		say("Leave, interloper.")

/mob/living/simple_animal/hostile/abnormality/portrait_certain/proc/CheckInterloper()
	for(var/datum/status_effect/S in interlopers)
		if(S.owner)
			var/mob/living/L = S.owner
			if(L.stat != DEAD)
				continue
			L.remove_status_effect(INTERLOPER_STATUS)
		interlopers -= S

/mob/living/simple_animal/hostile/abnormality/portrait_certain/proc/Portraits()
	var/list/places = list()
	places += SurroundTarget(src, 2)
	var/amt = length(places)
	if(amt < 5)
		return FALSE

	dir = 2
	var/portrait_random = rand(1,amt)
	var/true_portrait = clamp(portrait_random, 1 , 4)
	for(var/I = 1 to 5)
		var/spawn_location = pick_n_take(places)
		var/obj/structure/certain_portrait/P = new(get_turf(spawn_location))
		RegisterSignal(P, list(COMSIG_PARENT_QDELETING), PROC_REF(PortraitDestroyed))
		P.abno_reference = src
		if(I == true_portrait)
			P.master_port = TRUE
			P.update_icon()
		portraits += P
	var/prev_color = color
	color = COLOR_PALE_BLUE_GRAY
	ChangeResistances(list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 0.2, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 0.2))
	update_icon_state()
	can_act = FALSE
	SLEEP_CHECK_DEATH(6 SECONDS)
	color = prev_color
	ChangeResistances(list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 1, BLACK_DAMAGE = 0.75, PALE_DAMAGE = 1.5))
	update_icon_state()
	DetonatePortraits()
	can_act = TRUE
	portrait_cooldown = world.time + portrait_delay
	return places

/mob/living/simple_animal/hostile/abnormality/portrait_certain/proc/PortraitDestroyed(obj/structure/certain_portrait/P, master_port)
	portraits -= P
	if(master_port)
		apply_lc_protection(0)
		apply_lc_fragile(5)
		DetonatePortraits(TRUE)

/mob/living/simple_animal/hostile/abnormality/portrait_certain/proc/DetonatePortraits(safe)
	for(var/obj/structure/certain_portrait/P in portraits)
		if(!QDELETED(P))
			UnregisterSignal(P, list(COMSIG_PARENT_QDELETING))
			P.Detonate(safe)
			if(!safe)
				//Should be -0.5 resistance
				apply_lc_protection(5)

	portraits.Cut()

/*-------*\
|Portraits|
\--------*/
/obj/structure/certain_portrait
	name = "dusty portrait"
	desc = "A floating portrait that is too dusty to decern the person depicted."
	icon = 'ModularLobotomy/_Lobotomyicons/certain_day_portraits.dmi'
	icon_state = "portrait5"
	density = FALSE
	anchored = TRUE
	max_integrity = 30
	integrity_failure = 0
	var/mob/living/simple_animal/hostile/abnormality/portrait_certain/abno_reference
	var/master_port = FALSE

/obj/structure/certain_portrait/Initialize()
	. = ..()
	icon_state = "portrait[rand(1,7)]"

/obj/structure/certain_portrait/examine(mob/user)
	. = ..()
	if(master_port)
		. += span_notice("This one looks older than the others.")

/obj/structure/certain_portrait/update_icon_state()
	if(master_port)
		icon_state = "portrait[8]"
	return ..()

/obj/structure/certain_portrait/Destroy()
	if(abno_reference)
		abno_reference.PortraitDestroyed(src, master_port)
		abno_reference = null
	return ..()

/obj/structure/certain_portrait/CanAllowThrough(atom/movable/mover, turf/target)//So bullets will fly over and stuff.
	. = ..()
	if(istype(mover, /obj/projectile))
		return FALSE

/obj/structure/certain_portrait/proc/Detonate(no_damage)
	playsound(loc, 'sound/effects/hit_on_shattered_glass.ogg', 40, TRUE)
	if(!no_damage)
		new /obj/effect/temp_visual/screech(get_turf(src))
		if(abno_reference)
			for(var/mob/living/L in oview(4, src))
				if(!abno_reference.faction_check_mob(L))
					L.deal_damage(30, WHITE_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))

	master_port = FALSE
	QDEL_IN(src, 1)

/*-----------*\
|Status Effect|
\------------*/
/datum/status_effect/display/interloper
	id = "interloper"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	alert_type = null
	on_remove_on_mob_delete = TRUE
	display_name = "interloper"

#undef INTERLOPER_STATUS
