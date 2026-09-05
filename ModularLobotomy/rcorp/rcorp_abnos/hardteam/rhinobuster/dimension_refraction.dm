//Rhinobuster because he pierces rhinos and is a semi sneaky bastard
/mob/living/simple_animal/hostile/rcorp_abno/hard/dimensional_refraction
	name = "Dimensional Refraction Variant"
	desc = "A barely visible haze, your radio seems to grow garbled when it gets close."
	del_on_death = TRUE
	maxHealth = 1200
	health = 1200
	alpha = 128 //Starts out a bit more visible so players can possess him
	density = FALSE
	damage_coeff = list(RED_DAMAGE = 0, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1)
	move_to_delay = 3
	original_abno = /mob/living/simple_animal/hostile/abnormality/dimensional_refraction

	var/cooldown_time = 3
	var/aoe_damage = 20

	abno_additional_instructions = "<h1>You are Dimensional Refraction Variant, A Rhino Piercer Role Abnormality.</h1><br>\
		<b>|Strange Phenomenon|: You are immune to RED damage. \
		Upon joining the round you become incredibly hard to see with the naked eye. \
		This ability may also be triggered through taking damage incase no one decides to take the role of DRV. <br>\
		<br>\
		|Vacuum Phenomenon|: You are unable of performing physical attacks, instead when entering melee range of something you will instead passively affect it. \
		This will cause 20 RED damage every 0.3 seconds and apply 2 |White Fragility| to those within your melee range. \
		If their HP falls to 50% trigger |Refraction|, if their HP falls to 10% trigger |Diffraction|. \
		This effect pierces through Rhino suits harming the pilot directly. <br>\
		<br>\
		|Refraction|: When the health of your target falls to 50% or lower you will refract all radio devices on their person.\
		This will cause their radios to turn off, neither receiving nor sending communications until taken off and fixed. <br>\
		<br>\
		|Diffraction|: When the health of your target falls to 10% or lower you will diffract your target itself. \
		This will cause one of the targets limbs (excluding the head) to separate from the body itself. \
		As long as the targets health is below the threshold this effect will trigger for every instance of damage you perform. \
		This effect does not apply if the target has lost all limbs. <br>\
		<br>\
		|White Fragility|: Raises WHITE damage taken by 10% per stack. </b>"

/mob/living/simple_animal/hostile/rcorp_abno/hard/dimensional_refraction/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(Melter)), cooldown_time)

/mob/living/simple_animal/hostile/rcorp_abno/hard/dimensional_refraction/Login()
	. = ..()
	if(!. || !client)
		return FALSE
	alpha = 30

/mob/living/simple_animal/hostile/rcorp_abno/hard/dimensional_refraction/proc/Melter()
	for(var/mob/living/L in livinginview(1, src))
		if(faction_check_mob(L))
			continue

		L.deal_damage(aoe_damage, RED_DAMAGE, flags = (DAMAGE_UNTRACKABLE | DAMAGE_FORCED), attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		if(L.stat == DEAD) //No tracking DRVs location through corpses you clever girl
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(L), pick(GLOB.alldirs))


		if(!ishuman(L))
			continue
		var/mob/living/carbon/human/C = L

		//Give them white fragile
		L.apply_lc_white_fragile(2)

		//Remove Radio if HP under 50%
		if(L.health<=L.maxHealth*0.5)
			for(var/obj/item/radio/R in C.get_all_gear())
				R.emp_act(EMP_LIGHT)
				to_chat(C,span_danger("You hear your radio crackle!!"))


		//Dismember if under 10% HP
		if(L.health<=L.maxHealth*0.1)
			//Lop off a random arm
			new /obj/effect/temp_visual/smash_effect(get_turf(C))
			var/obj/item/bodypart/arm = pick(C.get_bodypart(BODY_ZONE_R_ARM), C.get_bodypart(BODY_ZONE_L_ARM), C.get_bodypart(BODY_ZONE_L_LEG), C.get_bodypart(BODY_ZONE_L_LEG))

			arm?.dismember() //not all limbs can be removed.

	addtimer(CALLBACK(src, PROC_REF(Melter)), cooldown_time)


/mob/living/simple_animal/hostile/rcorp_abno/hard/dimensional_refraction/AttackingTarget()
	return FALSE

/mob/living/simple_animal/hostile/rcorp_abno/hard/dimensional_refraction/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	alpha = 30 //Due to DRV starting visible and only cloaking on login we need the AI to cloak when harmed
