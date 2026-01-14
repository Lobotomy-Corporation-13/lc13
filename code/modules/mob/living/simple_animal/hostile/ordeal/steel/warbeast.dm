
// A walking terror its mind barely kept together by its superiors.
/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight
	name = "gene corp warbeast"
	desc = "A towering insectoid terror, the only evidence of its human nature being the torn shreds of an employees uniform draped over its shoulders."
	icon = 'ModularLobotomy/_Lobotomyicons/gcorp_warbeast.dmi'
	icon_state = "gcorp"
	icon_living = "gcorp"
	icon_dead = "gcorp_corpse"
	speak_emote = list("chitters", "buzzes")
	pixel_x = -16
	base_pixel_x = -16
	death_message = "falls to the floor violently spasming before falling still."
	maxHealth = 7500
	health = 7500
	buffed = 5
	rapid_melee = 1
	melee_damage_lower = 50
	melee_damage_upper = 60
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 1.3, PALE_DAMAGE = 0.8)
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	death_sound = 'sound/voice/mook_death.ogg'
	butcher_results = list(/obj/item/food/meat/slab/buggy = 2)
	silk_results = list(/obj/item/stack/sheet/silk/steel_advanced = 2)
	var/swat_cooldown = 0
	var/swat_delay = 12 SECONDS
	var/spearhead_cooldown = 0
	var/spearhead_delay = 10 SECONDS
	var/behavior = 0

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_STRONG_GRABBER, "initialize")

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/handle_automated_action()
	. = ..()
	if(stat == DEAD)
		return
	if(buffed < 5)
		buffed++
	if(target)
		if(buffed >= 4 && spearhead_cooldown <= world.time)
			if(get_dist(src, target) >= 3)
				Spearhead(target)
				return

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/Move()
	if(behavior == 1)
		return FALSE
	..()

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/bullet_act(obj/projectile/P)
	if(getStaminaLoss() < 50)
		//I keep using stamina loss as a mechanic -IP
		adjustStaminaLoss(5)
	else
		if(behavior != 1)
			if(prob(85))
				visible_message(span_warning("[src] blocks [P]!"))
				flick("gcorp_def", src)
				return BULLET_ACT_BLOCK
	return ..()

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/update_icon_state()
	if(behavior == 1)
		icon_state = "gcorp_spearhead"
		return
	return ..()

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/AttackingTarget(atom/attacked_target)
	. = ..()
	if(!. || behavior == 1)
		return
	if(isliving(attacked_target))
		var/mob/living/L = attacked_target
		if(buffed >= 2 && swat_cooldown <= world.time)
			SwatAway(L)
			return

//Attacks
/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/proc/SwatAway(mob/living/L)
	to_chat(L, span_userdanger("[src] swats you away using its forelimbs!"))
	var/turf/thrownat = get_ranged_target_turf_direct(src, L, 4, rand(-10, 10))
	L.throw_at(thrownat, 8, 2, src, TRUE, force = MOVE_FORCE_OVERPOWERING, gentle = TRUE)
	shake_camera(L, 2, 1)
	if(target_memory[L] < 100)
		LoseTarget()
	swat_cooldown = world.time + swat_delay

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/proc/Spearhead(mob/living/L)
	behavior = 1
	update_icon()

	//Stolem from big wolf -IP
	do_shaky_animation(2)
	if(do_after(src, 1 SECONDS, target = src))
		var/turf/wallcheck = get_turf(src)
		for(var/i = 0 to 10)
			if(get_turf(src) != wallcheck || stat == DEAD)
				break
			wallcheck = get_step(src, get_dir(src, get_turf(L)))
			if(!ClearSky(wallcheck))
				break
			//without this the attack happens instantly
			SLEEP_CHECK_DEATH(1)
			new /obj/effect/temp_visual/slice(wallcheck)
			var/kill_target
			var/list/hit_mobs = HurtInTurf(wallcheck, list(), 10, RED_DAMAGE, null, TRUE, FALSE, TRUE, hurt_structure = TRUE)
			for(var/mob/living/enemy in hit_mobs)
				if(enemy.stat == DEAD)
					continue
				if(enemy == L)
					kill_target = enemy
					break
			if(kill_target)
				Evicerate(kill_target)
				break
			forceMove(wallcheck)
			playsound(wallcheck, 'sound/abnormalities/doomsdaycalendar/Lor_Slash_Generic.ogg', 20, 0, 4)

	behavior = 0
	update_icon()
	spearhead_cooldown = world.time + spearhead_delay

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_midnight/proc/Evicerate(mob/living/L)
	if(!L)
		return FALSE

	start_pulling(L)
	visible_message(span_danger("[src] grabs [L]!"), \
			span_userdanger("Your grabbed by [src]!"),
			span_hear("You hear aggressive shuffling!"), COMBAT_MESSAGE_RANGE, src)

	L.AdjustImmobilized(10)

	for(var/i = 1 to 7)
		if(L.pulledby != src)
			break

		if(do_mob(src, L, 3))
			playsound(loc, attack_sound, 50, TRUE, TRUE)
			do_attack_animation(L)
			L.deal_damage(melee_damage_upper, RED_DAMAGE)

		if(L.stat > SOFT_CRIT && L.stat != DEAD && i > 3)
			if(ishuman(L))
				buffed += 5
				adjustBruteLoss(-50)
			visible_message(span_danger("[src] tears apart [L]!"), \
				span_userdanger("Your torn apart by [src]!"),
				span_hear("You hear wet tearing!"), COMBAT_MESSAGE_RANGE, src)
			playsound(get_turf(src), 'sound/effects/dismember.ogg', 20, 0, 4)
			SLEEP_CHECK_DEATH(2)
			playsound(get_turf(src), 'sound/effects/ordeals/steel/gcorp_chitter.ogg', 20, 0, 4)
			//Death does sanity damage aoe anyways so it should be fine to leave it as such.
			L.gib(FALSE,TRUE,TRUE)
			break

	stop_pulling(L)
	return TRUE
