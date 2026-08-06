/mob/living/simple_animal/hostile/limbus_abno/funeral

	maxHealth = 1350 //I am a menace to society.
	health = 1350
	blood_volume = 0
	ranged = TRUE

	move_to_delay = 4
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.5, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1.0, PALE_DAMAGE = 2)
	ego_list = list(
		/datum/ego_datum/weapon/solemnvow,
		/datum/ego_datum/weapon/solemnlament,
		/datum/ego_datum/armor/solemnlament,
	)

	del_on_death = FALSE

	var/gun_cooldown = 0
	var/gun_cooldown_time = 4 SECONDS
	var/gun_damage = 60

	var/obj/effect/proc_holder/ability/aimed/casket_swarm/casket

	//LCL unique Variables
	original_abno = /mob/living/simple_animal/hostile/abnormality/funeral
	abno_additional_instructions = "You like insight work, \
	Before these scientists trapped you, you came here to bring \
	peaceful death to the poor souls trapped here."

	desire_active = TRUE
	liked_objects_list = list(
		/obj/structure/chair/wood,
		/obj/item/food/grown/harebell,
		)
	max_counter = 3
	desire_loss = 15
	desire_on_pet = 3
	desire_on_talk = 1
	rep_desire_gain = -5
	delete_food = FALSE

	can_breach = TRUE
	attack_action_types = list(
		/datum/action/cooldown/limbus_abno_action/swap_attack/funeral_casket
		)

	egg_icon = 'ModularLobotomy/_Lobotomyicons/abno_cores/he.dmi'
	egg_sprite = "funeral"

/*-----\
|Vitals|
\-----*/
/mob/living/simple_animal/hostile/limbus_abno/funeral/Initialize()
	.  = ..()
	casket = new

/mob/living/simple_animal/hostile/limbus_abno/funeral/Destroy()
	if(casket)
		QDEL_NULL(casket)
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/funeral/AttackingTarget(atom/attacked_target)
	if(!target)
		GiveTarget(attacked_target)
	return OpenFire()

/mob/living/simple_animal/hostile/limbus_abno/funeral/OpenFire()
	if(!can_act)
		return
	if(client)
		switch(chosen_attack)
			if(1)
				SpiritGun(target)
			if(2)
				chosen_attack = 1
				icon_state = "funeral_coffin_butterfly_less"
				SLEEP_CHECK_DEATH(1.75 SECONDS)
				icon_state = "funeral_coffin"
				casket.Perform(target, src)
				icon_state = "funeral"

/*----------\
|Containment|
\----------*/

/mob/living/simple_animal/hostile/limbus_abno/AdjustDesire(desire_amount)
	. = ..()
	if(.) //Desire Amount equals zero
		return
	AdjustCounter(-1)

/mob/living/simple_animal/hostile/limbus_abno/funeral/Breach()
	breached = TRUE
	unstable = TRUE
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/funeral/Unbreach()
	breached = FALSE
	unstable = FALSE
	return ..()

/*---\
|Misc|
\---*/
/mob/living/simple_animal/hostile/limbus_abno/funeral/proc/SpiritGun(atom/target)
	if(!isliving(target)||gun_cooldown > world.time)
		return
	var/mob/living/cooler_target = target
	if(cooler_target.stat == DEAD)
		return
	icon_state = "funeral_gun"
	visible_message(span_danger("[src] levels one of its arms at [cooler_target]!"))
	cooler_target.apply_status_effect(/datum/status_effect/spirit_gun_target) // Re-used for visual indicator
	dir = get_cardinal_dir(src, target)
	gun_cooldown = world.time + gun_cooldown_time
	SLEEP_CHECK_DEATH(1.5 SECONDS)
	playsound(get_turf(src), 'sound/abnormalities/funeral/spiritgun.ogg', 75, 1, 3)
	cooler_target.remove_status_effect(/datum/status_effect/spirit_gun_target)
	can_act = TRUE
	icon_state = "funeral"

	var/line_of_sight = getline(get_turf(src), get_turf(target)) //better simulates a projectile attack
	for(var/turf/T in line_of_sight)
		if(DensityCheck(T))
			return
	cooler_target.deal_damage(gun_damage, WHITE_DAMAGE, src, attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
	visible_message(span_danger("[cooler_target] is hit by butterflies!"))
	//No longer because fuck you.
	if(ishuman(target))
		var/mob/living/carbon/human/kickass_grade1_target = target
		if(kickass_grade1_target.sanity_lost)
			kickass_grade1_target.death()
			kickass_grade1_target.apply_status_effect(/datum/status_effect/butterfly_death_anim)

/mob/living/simple_animal/hostile/limbus_abno/funeral/proc/DensityCheck(turf/T) //TRUE if dense or airlocks closed
	if(T.density)
		return TRUE
	for(var/obj/machinery/door/D in T.contents)
		if(D.density)
			return TRUE
	return FALSE

/*-----\
|Action|
\-----*/
/datum/action/cooldown/limbus_abno_action/swap_attack/funeral_casket
	name = "Funeral Casket."
	desc = "Release a swarm of butterflies in the direction you click."
	desire_req = 30
	cooldown_time = 20 SECONDS
	swap_attack = 2
