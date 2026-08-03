//Placed in support role because of its spammable AoE + slowdown capabilities
/mob/living/simple_animal/hostile/rcorp_abno/hard/sphinx
	name = "Sphinx"
	desc = "A gigantic stone feline. Your movements feel petrified when looking at it's eye, best look away."
	var/icon_aggro = "sphinx_eye"
	ranged = TRUE
	maxHealth = 2000
	health = 2000
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.5)
	stat_attack = HARD_CRIT
	move_to_delay = 4
	melee_damage_lower = 70
	melee_damage_upper = 100
	attack_sound = 'sound/abnormalities/sphinx/attack.ogg'
	attack_action_types = list(/datum/action/cooldown/rca_sphinx_gaze, /datum/action/cooldown/rca_sphinx_quake)
	melee_damage_type = WHITE_DAMAGE
	secret_chance = TRUE // Why do we live, just to suffer?
	secret_icon_file = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
	secret_icon_state = "sphonx"
	secret_icon_living = "sphonx"
	original_abno = /mob/living/simple_animal/hostile/abnormality/sphinx

	var/curse_cooldown
	var/curse_cooldown_time = 12 SECONDS
	var/quake_cooldown
	var/quake_cooldown_time = 6 SECONDS
	var/quake_damage = 20

	abno_additional_instructions = "<h1>You are Sphinx, A Support Role Abnormality.</h1><br>\
		<b>|Immovable Guardian|: When attacking a target in melee knock them back 3 tiles. \
		This knockback cannot stun. \
		If your attacks drive a human insane they are guaranteed to become Wander insane regardless of stats. <br>\
		<br>\
		|Crumbling Stone|: When performing a ranged attack stones will rise from the tile you targetted, triggering a 3x3 AOE on that tile after a 0.9 second delay. \
		This AOE will do 40 RED damage to those hit, if the attack leaves the target in critical state they will instead be gibbed. <br>\
		<br>\
		|Desert Slab|: When using the Earthquake ability perform a 5x5 AOE centered around yourself. \
		Targets hit by this AOE will take 20 RED damage and be knocked back a random amount. \
		The knockback from this ability does not stun. <br>\
		<br>\
		|Pharaohs Presence|: You possess a Sphinxs Gaze ability, when used you will initiate a AOE attack spanning your entire screen. \
		Humans within this AOE are given 1.2 seconds to react, if by the end of this time period they are facing you they will be affected by |Pharaohs Curse|. \
		If they did not face you but were still within the AOE they will be applied with a heavy slowdown. <br>\
		<br>\
		|Pharaohs Curse|: Those afflicted with |Pharaohs Curse| will be petrified and turned into stone statues. \
		Petrified individuals will return to normal after 8 minutes, they may be freed prematurely if a welder is used to cut them out. \
		If a petrified individual has their stone statue destroyed they will instead crumble to dust, leading to instant death. </b>"

/mob/living/simple_animal/hostile/rcorp_abno/hard/sphinx/Initialize()
	. = ..()
	if(secret_abnormality)
		icon_aggro = "sphonx_eye"
	AddComponent(/datum/component/knockback, 3, FALSE, TRUE)

/datum/action/cooldown/rca_sphinx_gaze
	name = "Sphinx's Gaze"
	icon_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = "sphinx"
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE
	cooldown_time = 12 SECONDS

/datum/action/cooldown/rca_sphinx_gaze/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/rcorp_abno/hard/sphinx/sphinx = owner
	if(!istype(sphinx))
		return FALSE
	if(sphinx.curse_cooldown_time > world.time || !sphinx.can_act)
		return FALSE
	StartCooldown()
	sphinx.StoneVision(FALSE)
	return TRUE

/datum/action/cooldown/rca_sphinx_quake
	name = "Sphinx's Earthquake"
	icon_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = "ebony_barrier"
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE
	cooldown_time = 6 SECONDS

/datum/action/cooldown/rca_sphinx_quake/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/rcorp_abno/hard/sphinx/sphinx = owner
	if(!istype(sphinx))
		return FALSE
	if(sphinx.quake_cooldown > world.time || !sphinx.can_act)
		return FALSE
	StartCooldown()
	sphinx.Quake()
	return TRUE

/mob/living/simple_animal/hostile/rcorp_abno/hard/sphinx/Move()
	if(!can_act)
		return FALSE
	..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/sphinx/PickTarget(list/Targets)
	var/list/priority = list()
	for(var/mob/living/L in Targets)
		if(!CanAttack(L))
			continue
		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			if(H.sanity_lost) //ignore the panicked
				continue
			else
				priority += L
		else
			priority += L
	if(LAZYLEN(priority))
		return pick(priority)

/mob/living/simple_animal/hostile/rcorp_abno/hard/sphinx/AttackingTarget(atom/attacked_target)
	if(!ishuman(attacked_target))
		if(!target)
			GiveTarget(attacked_target)
		return OpenFire(attacked_target)

	var/mob/living/carbon/human/H = attacked_target
	if(!H.sanity_lost)
		if(!target)
			GiveTarget(attacked_target)
		return OpenFire(attacked_target)

	QDEL_NULL(H.ai_controller)
	H.ai_controller = /datum/ai_controller/insane/wander/rca_sphinx //Just incase we need to change this later
	H.InitializeAIController()
	LoseTarget(H)

/mob/living/simple_animal/hostile/rcorp_abno/hard/sphinx/OpenFire()
	if(!can_act)
		return

	if((curse_cooldown <= world.time)  && !client)
		StoneVision(FALSE)
		return
	StoneThrow(target)

/mob/living/simple_animal/hostile/rcorp_abno/hard/sphinx/attackby(obj/item/I, mob/living/user, params)
	..()
	if(!client)
		TryQuake()

/mob/living/simple_animal/hostile/rcorp_abno/hard/sphinx/attack_animal(mob/living/simple_animal/M)
	..()
	if(!client)
		TryQuake()

/mob/living/simple_animal/hostile/rcorp_abno/hard/sphinx/proc/StoneThrow()
	if(!can_act)
		return
	can_act = FALSE
	SLEEP_CHECK_DEATH(3)
	playsound(get_turf(target), 'sound/magic/arbiter/repulse.ogg', 20, 0, 5)
	new /obj/effect/temp_visual/rca_rockwarning(get_turf(target), src)
	SLEEP_CHECK_DEATH(10)
	can_act = TRUE

/mob/living/simple_animal/hostile/rcorp_abno/hard/sphinx/proc/TryQuake()
	if((quake_cooldown <= world.time)  && !client)
		Quake()

/mob/living/simple_animal/hostile/rcorp_abno/hard/sphinx/proc/Quake()
	if(quake_cooldown > world.time || !can_act)
		return
	quake_cooldown = world.time + quake_cooldown_time
	can_act = FALSE
	var/turf/origin = get_turf(src)
	playsound(origin, 'sound/magic/arbiter/knock.ogg', 25, 0, 5)
	SLEEP_CHECK_DEATH(9)
	playsound(get_turf(src), 'sound/effects/ordeals/brown/rock_attack.ogg', 50, 0, 8)
	for(var/turf/T in view(2, src))
		new /obj/effect/temp_visual/smash_effect(T)
		for(var/mob/living/victim in HurtInTurf(T, list(), quake_damage, WHITE_DAMAGE, null, TRUE, FALSE, TRUE, FALSE, TRUE, TRUE, attack_type = (ATTACK_TYPE_SPECIAL)))
			var/throw_target = get_edge_target_turf(victim, get_dir(victim, get_step_away(victim, src)))
			if(!victim.anchored)
				var/throw_velocity = (prob(60) ? 1 : 4)
				victim.throw_at(throw_target, rand(1, 2), throw_velocity, src)
	SLEEP_CHECK_DEATH(8)
	icon_state = icon_living
	SLEEP_CHECK_DEATH(3)
	can_act = TRUE

/mob/living/simple_animal/hostile/rcorp_abno/hard/sphinx/proc/StoneVision(attack_chain)
	if((curse_cooldown > world.time) && !attack_chain)
		return
	if(!attack_chain)
		playsound(get_turf(src), 'sound/abnormalities/sphinx/stone_ready.ogg', 50, 0, 5)
		icon_state = icon_aggro
		can_act = FALSE
		src.set_light(5, 7, "D4FAF37", TRUE)
		for(var/turf/T in view(7, src))
			if(T.density)
				continue
			new /obj/effect/temp_visual/stone_gaze(T)
	curse_cooldown = world.time + curse_cooldown_time
	SLEEP_CHECK_DEATH(12)
	for(var/mob/living/carbon/human/L in viewers(7, src))
		if(L.client && CanAttack(L) && L.stat != DEAD)
			if(!L.is_blind() && is_A_facing_B(L,src))
				StoneCurse(L)
	if(!attack_chain)
		StoneVision(TRUE)
		return
	icon_state = icon_living
	can_act = TRUE
	src.set_light(0, 0, null, FALSE) //using all params takes care of the other procs.
	return

/mob/living/simple_animal/hostile/rcorp_abno/hard/sphinx/proc/StoneCurse(target)
	if(!ishuman(target))
		return
	var/mob/living/carbon/human/H = target
	if(!(H.has_movespeed_modifier(/datum/movespeed_modifier/petrify_partial)))
		H.add_movespeed_modifier(/datum/movespeed_modifier/petrify_partial)
		addtimer(CALLBACK(H, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/rca_petrify_partial), 3 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
		to_chat(H, span_warning("Your whole body feels heavy..."))
		playsound(get_turf(H), 'sound/abnormalities/sphinx/petrify.ogg', 50, 0, 5)
	else
		H.petrify()

// Insanity lines
/datum/ai_controller/insane/wander/rca_sphinx
	lines_type = /datum/ai_behavior/say_line/insanity_sphinx

/datum/movespeed_modifier/rca_petrify_partial
	variable = TRUE
	multiplicative_slowdown = 2

/obj/effect/temp_visual/rca_rockwarning
	name = "moving rocks"
	desc = "A target warning you of incoming pain"
	icon = 'icons/effects/effects.dmi'
	icon_state = "rockwarning"
	duration = 10
	layer = RIPPLE_LAYER // We want this HIGH. SUPER HIGH. We want it so that you can absolutely, guaranteed, see exactly what is about to hit you.
	var/damage = 40 //Red Damage
	var/mob/living/caster // who made this, anyway

/obj/effect/temp_visual/rca_rockwarning/Initialize(mapload, new_caster)
	. = ..()
	if(new_caster)
		caster = new_caster
	addtimer(CALLBACK(src, PROC_REF(explode)), 0.9 SECONDS)

/obj/effect/temp_visual/rca_rockwarning/proc/explode()
	var/turf/target_turf = get_turf(src)
	if(!target_turf)
		return
	if(QDELETED(caster) || caster?.stat == DEAD || !caster)
		return
	playsound(target_turf, 'sound/effects/ordeals/brown/rock_attack.ogg', 50, 0, 8)
	new /obj/effect/temp_visual/rockattack(target_turf)
	for(var/turf/T in view(1, src))
		new /obj/effect/temp_visual/smash_effect(T)
		for(var/mob/living/L in caster.HurtInTurf(T, list(), damage, RED_DAMAGE, null, TRUE, FALSE, TRUE, hurt_hidden = TRUE, hurt_structure = TRUE, attack_type = (ATTACK_TYPE_SPECIAL)))
			if(L.health < 0)
				L.gib()
	qdel(src)
