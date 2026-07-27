//Technically its damage is pretty low for a piercer but the range is so high that it wraps around to being good
/mob/living/simple_animal/hostile/rcorp_abno/hard/fire_bird
	name = "The Firebird"
	desc = "A large bird covered in searing flame, you are constantly burnt as it bathes you in light."
	maxHealth = 2000
	health = 2000
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.4, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 2.0)
	light_color = COLOR_LIGHT_ORANGE
	light_range = 20
	light_power = 20
	original_abno = /mob/living/simple_animal/hostile/abnormality/fire_bird

	var/pulse_cooldown
	var/pulse_cooldown_time = 1 SECONDS
	var/pulse_damage = 12
	var/dash_cooldown
	var/dash_cooldown_time = 5 SECONDS
	var/obj/effect/proc_holder/ability/aimed/rca_dash/firebird/ourdash

	abno_additional_instructions = "<h1>You are Alriune, A Rhino Piercer Role Abnormality.</h1><br>\
		<b>|Burning Awe|: You will constantly emit brilliant light in a 20 tile range. \
		You are incapable of attacking others and instead rely on your 'Vivid Flame' and 'Feather of Honor' to do damage. <br>\
		<br>\
		|Vivid Flame|: All hostile humans within a 48 tile sightline of yourself will be burnt by you. \
		This damage applies every second and is split in 12 RED damage and 6 BURN damage. \
		This will be repeated 3 times before you cycle to another attack. \
		Each petal will deal 20 WHITE damage to those they hit. <br>\
		<br>\
		|Feather of Honor|: When attacked you will attempt to dash at your target. \<br>\
		This dash will leave a trail of fire and deal 20 damage to any hostile humans you hit. \
		If your dash hits a insane target you will instead char them, this is a instant kill. \
		<br>\
		|Fervent Stoking|: Fire tiles left behind by your dash will set any that walk over it ablaze and will fade away in 3 seconds. \
		These fire tiles inflict 8 firestacks on any humans that walk over, hostile or friendly. \
		This afterburn will inflict small consistent chip BURN damage until is extinguished, rolled out or naturally expires. .</b>"

//Initialize
/mob/living/simple_animal/hostile/rcorp_abno/hard/fire_bird/Initialize()
	. = ..()
	ourdash = new()
	icon_state = icon_living

//Attacks
/mob/living/simple_animal/hostile/rcorp_abno/hard/fire_bird/proc/crispynugget()
	pulse_cooldown = world.time + pulse_cooldown_time
	for(var/mob/living/carbon/human/L in livinginview(48, src))
		if(!faction_check_mob(L))
			L.deal_damage(pulse_damage, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
			L.deal_damage(pulse_damage * 0.5, FIRE, src, attack_type = (ATTACK_TYPE_SPECIAL))

/mob/living/simple_animal/hostile/rcorp_abno/hard/fire_bird/proc/retaliatedash()
	if(dash_cooldown > world.time)
		return
	dash_cooldown = world.time + dash_cooldown_time
	if(!(status_flags & GODMODE))
		dash_cooldown = world.time + dash_cooldown_time
		ourdash.Perform(target,src)

/mob/living/simple_animal/hostile/rcorp_abno/hard/fire_bird/attackby(obj/item/I, mob/living/user, params)
	..()
	GiveTarget(user)
	retaliatedash()

/mob/living/simple_animal/hostile/rcorp_abno/hard/fire_bird/bullet_act(obj/projectile/Proj, def_zone, piercing_hit = FALSE)
	..()
	if(Proj.firer && ishuman(Proj.firer))
		var/mob/living/carbon/carbon_firer = Proj.firer
		GiveTarget(carbon_firer)
	retaliatedash()

/obj/effect/proc_holder/ability/aimed/rca_dash/firebird
	name = "firebird dash"
	dash_speed =  0.5
	dash_damage = 20
	dash_range = 50
	windup_delay = 1 SECONDS
	cooldown_time = 5 SECONDS
	env_breaking = TRUE

/obj/effect/proc_holder/ability/aimed/rca_dash/firebird/Finalize(target, mob/living/user, list/path_list)
	for(var/turf/T in path_list)
		FlickOnAtom(T,'icons/effects/effects.dmi',"smoke",5)
	playsound(get_turf(user), 'sound/abnormalities/firebird/Firebird_Hit.ogg', 100, 0, 20) //TEMPORARY
	if(!do_after(user, 11, target = user))
		EndCharge(user)
		return
	return ..()

/obj/effect/proc_holder/ability/aimed/rca_dash/firebird/TurfEffects(turf/T, mob/living/ourthing)
	for(var/turf/U in GetRange(T, 1))
		if(!U)
			break
		if(isopenturf(U) && !HasIdentList(U))
			//Real effect since fire produces light
			new /obj/effect/turf_fire/rca_firebird(U)
		var/list/new_hits = HurtInTurf(ourthing, U, list(), dash_damage, WHITE_DAMAGE, hurt_mechs = TRUE, flags = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		var/flicks = FALSE
		for(var/mob/living/L in new_hits)//damage applied to targets in range
			visible_message(span_boldwarning("[src] blazes through [L]!"))
			if(ourthing.faction_check_mob(L))
				L.deal_damage(dash_damage, FIRE, ourthing, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
				if(ishuman(L))
					var/mob/living/carbon/human/H = L
					if(H.sanity_lost) // TODO: TEMPORARY AS HELL
						H.deal_damage(999, FIRE, ourthing, flags = (DAMAGE_FORCED))
				if(!flicks)
					FlickOnAtom(U,'icons/effects/effects.dmi',"cleave",5)
					flicks = TRUE
	return ..()

//The specific fire
//The special fire type
/obj/effect/turf_fire/rca_firebird
	fire_damage = 8
	burn_time = 3 SECONDS
