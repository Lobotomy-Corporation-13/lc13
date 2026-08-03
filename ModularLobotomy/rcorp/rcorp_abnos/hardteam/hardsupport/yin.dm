//Support due to big ass beam but zero melee attack making it vulnerable in combat and therefore a backliner
/mob/living/simple_animal/hostile/rcorp_abno/hard/yin
	name = "Yin"
	desc = "A floating black fish that seems to hurt everyone near it."
	is_flying_animal = TRUE
	maxHealth = 1600
	health = 1600
	move_to_delay = 5 //Yin was too slow before
	ranged = TRUE //allows Yin to manually fire Laser
	original_abno = /mob/living/simple_animal/hostile/abnormality/yin

	//Melee
	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 0, PALE_DAMAGE = 1)
	melee_damage_lower = 60 // Doesn't actually swing individually
	melee_damage_upper = 60
	melee_damage_type = BLACK_DAMAGE

	//Ranged
	COOLDOWN_DECLARE(beam)
	var/beam_cooldown = 10 SECONDS
	var/beam_distance = 20

	COOLDOWN_DECLARE(pulse)
	var/pulse_cooldown = 8 SECONDS //Raises pulse cooldown so youre reliant on laser
	var/pulse_damage = 40
	var/pulse_distance = 4

	var/busy = FALSE

	var/list/spawned_effects = list()

	abno_additional_instructions = "<h1>You are Yin, A Tank Role Abnormality.</h1><br>\
		<b>|Ruination|: When you click on a tile which is not right next to you, you will fire a laser towards that tile. \
		The laser deal BLACK damage, and has a 10 second cooldown.<br>\
		<br>\
		|Decay|: Each time you take damage, if your pulse is off cooldown. You will send out a pulse around you, which deals BLACK damage to all humans. \
		The Pulse has a cooldown of 8 seconds.</b>"

/mob/living/simple_animal/hostile/rcorp_abno/hard/yin/Initialize()
	. = ..()
	icon_state = "yin_breach"

/mob/living/simple_animal/hostile/rcorp_abno/hard/yin/Move()
	if(busy)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/yin/Destroy()
	for(var/atom/AT in spawned_effects)
		qdel(AT)
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/yin/proc/PulseOr(user)
	if(COOLDOWN_FINISHED(src, pulse))
		COOLDOWN_START(src, pulse, pulse_cooldown)
		INVOKE_ASYNC(src, PROC_REF(Pulse))


/mob/living/simple_animal/hostile/rcorp_abno/hard/yin/OpenFire()
	FireLaser(target)

/mob/living/simple_animal/hostile/rcorp_abno/hard/yin/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	if(!isliving(source) && !ismecha(source))
		return
	PulseOr(source)

/mob/living/simple_animal/hostile/rcorp_abno/hard/yin/AttackingTarget(atom/attacked_target)
	return FALSE

/mob/living/simple_animal/hostile/rcorp_abno/hard/yin/proc/Pulse()
	var/list/hit_turfs = list()
	var/list/hit = list()
	for(var/i = 1 to pulse_distance)
		var/list/to_hit = range(i, src) - hit_turfs
		hit_turfs |= to_hit
		for(var/turf/open/OT in to_hit)
			hit = HurtInTurf(OT, hit, pulse_damage, BLACK_DAMAGE, null, TRUE, FALSE, TRUE, attack_type = (ATTACK_TYPE_SPECIAL))
			new /obj/effect/temp_visual/small_smoke/yin_smoke/short(OT)
		sleep(3)

/mob/living/simple_animal/hostile/rcorp_abno/hard/yin/proc/FireLaser(mob/target)
	if(busy || !COOLDOWN_FINISHED(src, beam))
		return FALSE
	busy = TRUE
	face_atom(target)
	var/turf/target_turf = get_ranged_target_turf_direct(src, target, beam_distance)
	var/list/to_hit = getline(src, target_turf)
	var/datum/beam/beam = Beam(get_turf(src),"volt_ray")
	for(var/turf/open/OT in to_hit)
		if(!istype(OT) || OT.density)
			break
		beam.target = OT
		beam.redrawing()
		sleep(1)
		new /obj/effect/temp_visual/revenant/cracks/rca_yin(OT)
	for(var/obj/effect/FX in spawned_effects)
		qdel(FX)
	qdel(beam)
	COOLDOWN_START(src, beam, beam_cooldown)
	busy = FALSE
	return TRUE

/obj/effect/temp_visual/revenant/cracks/rca_yin
	icon_state = "yincracks"
	duration = 9
	var/damage = 60
	var/list/faction = list("hostile")

/obj/effect/temp_visual/revenant/cracks/rca_yin/Destroy()
	for(var/turf/T in range(1, src))
		for(var/mob/living/L in T)
			if(faction_check(L.faction, src.faction))
				continue
			L.deal_damage(damage, BLACK_DAMAGE)
		for(var/obj/vehicle/sealed/mecha/V in T)
			V.take_damage(damage, BLACK_DAMAGE)
		new /obj/effect/temp_visual/small_smoke/yin_smoke/long(T)
	return ..()
