//Very simple, funny little guy.
/mob/living/simple_animal/hostile/abnormality/branch12/eye_bird
	name = "Seeing Bird"
	desc = "A small floating eye."
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/32x32.dmi'
	icon_state = "seeing_bird"
	icon_living = "seeing_bird"
	portrait = "eye_bird"
	maxHealth = 2200
	health = 2200
	rapid_melee = 4
	move_to_delay = 4
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	pass_flags = PASSTABLE
	faction = list("hostile")
	attack_sound = 'sound/weapons/pbird_bite.ogg'
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 1.6, PALE_DAMAGE = 0)
	melee_damage_lower = 7
	melee_damage_upper = 7
	can_breach = TRUE
	is_flying_animal = TRUE
	melee_damage_type = PALE_DAMAGE
	stat_attack = HARD_CRIT
	threat_level = ALEPH_LEVEL
	start_qliphoth = 1

	ranged = 1
	retreat_distance = 3
	minimum_distance = 1
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(20, 20, 35, 45, 45),
		ABNORMALITY_WORK_INSIGHT = list(20, 20, 40, 50, 50),
		ABNORMALITY_WORK_ATTACHMENT = list(20, 20, 35, 45, 45),
		ABNORMALITY_WORK_REPRESSION = 0,
	)
	work_damage_amount = 10
	work_damage_type = PALE_DAMAGE

	ego_list = list(
		/datum/ego_datum/weapon/branch12/prognostica,
		/datum/ego_datum/armor/branch12/prognostica,)

	abnormality_origin = ABNORMALITY_ORIGIN_BRANCH12
	var/pulse_cooldown
	var/pulse_cooldown_time = 15 SECONDS


/mob/living/simple_animal/hostile/abnormality/branch12/eye_bird/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(40))
		datum_reference.qliphoth_change(-1)
	return


/mob/living/simple_animal/hostile/abnormality/branch12/eye_bird/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-1)
	return


//Ranged stuff
/mob/living/simple_animal/hostile/abnormality/branch12/eye_bird/bullet_act(obj/projectile/Proj)
	..()

	if(!ishuman(Proj.firer))
		return
	Punishment()

//Melee stuff
/mob/living/simple_animal/hostile/abnormality/branch12/eye_bird/attacked_by(obj/item/I, mob/living/user)
	..()
	if(!user)
		return
	Punishment()

/mob/living/simple_animal/hostile/abnormality/branch12/eye_bird/Life()
	. = ..()
	if(!.) // Dead
		return FALSE

	//Pulse stuff
	if((pulse_cooldown < world.time) && !(status_flags & GODMODE))
		pulse_cooldown = world.time + pulse_cooldown_time
		Fragile()

/mob/living/simple_animal/hostile/abnormality/branch12/eye_bird/proc/Fragile()
	for(var/mob/living/carbon/human/H in view(7, src))
		H.apply_lc_fragile(3)

/mob/living/simple_animal/hostile/abnormality/branch12/eye_bird/proc/Punishment()
	for(var/mob/living/carbon/human/H in view(7, src))
		H.apply_lc_fragile(5)
		H.apply_lc_feeble(5)
		H.apply_lc_tremor(3, 15)

	//Take the shit from Black Sun
	var/list/all_turfs = RANGE_TURFS(7, src)
	for(var/turf/open/F in all_turfs)
		if(prob(30))
			addtimer(CALLBACK(src, PROC_REF(Firelaser), F), rand(1,30))

/mob/living/simple_animal/hostile/abnormality/branch12/eye_bird/proc/Firelaser(turf/open/F)
	new /obj/effect/temp_visual/blacksun_laser(F)


