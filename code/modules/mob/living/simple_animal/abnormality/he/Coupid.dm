/mob/living/simple_animal/hostile/abnormality/cupid
	name = "Coupid"
	desc = "The tiniest rabbit with a flower on its head. It makes you itch looking at it."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "cupid_contained"
	icon_living = "cupid_contained"
	portrait = "cupid"
	var/breach_icon = "cupid_breach"
	core_icon = "cupid_egg"
	del_on_death = TRUE
	maxHealth = 1500
	health = 1500
	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 2, BLACK_DAMAGE = 0, PALE_DAMAGE = 1) //0 is like no damage, 2 is high damage? right???
	melee_damage_type = BLACK_DAMAGE
	can_breach = TRUE
	threat_level = HE_LEVEL
	start_qliphoth = 1
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 10,
		ABNORMALITY_WORK_INSIGHT = 80, //insert botany joke somewhere here
		ABNORMALITY_WORK_ATTACHMENT = 40,
		ABNORMALITY_WORK_REPRESSION = 40,
	)
	work_damage_amount = 12
	work_damage_type = BLACK_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/sloth
	can_patrol = TRUE
	ego_list = list(
		/datum/ego_datum/weapon/allergen,
		/datum/ego_datum/armor/allergen,
	)
	gift_type = /datum/ego_gifts/allergen
	abnormality_origin = ABNORMALITY_ORIGIN_ORIGINAL


	observation_prompt = "There's a field of wheat ahead of you. It's a beautiful sunset, But you're feeling ill."
	observation_choices = list(
		"Go home" = list(TRUE, "As you begin to leave the fields and head home, You feel something grow on your head. It's itchy, But you feel comfortable now."),
		"Rest here for a while" = list(FALSE, "As you stare off, Something scampers up to your leg. You find yourself wheezing for air after that."),
	)
	var/move_timer_id
	var/spawn_tried = 0
	var/flip_cooldown_time = 10 SECONDS
	var/flip_cooldown = 0

/mob/living/simple_animal/hostile/abnormality/cupid/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(80))
		datum_reference.qliphoth_change(-1) //if bad at works, deal with the gooblin
	return

/mob/living/simple_animal/hostile/abnormality/cupid/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	user.reagents.add_reagent(/datum/reagent/toxin/histamine, 5)
	visible_message(span_notice("You find yourself sniffling after work. Should probably be careful breathing near it."))

/mob/living/simple_animal/hostile/abnormality/cupid/BreachEffect(mob/living/carbon/human/user, breach_type)
	SSweather.run_weather(/datum/weather/pollen)
	icon_state = "cupid_breach"
	..()

	//okay. the bnuuy is nuzzling people when he sees them. he's supposed to be a wild bunny not a pet bunny. so let's make some BUULLLLSHIT
/mob/living/simple_animal/hostile/abnormality/cupid/PickTarget(list/Targets)
	return
/mob/living/simple_animal/hostile/abnormality/cupid/Move()
	..()

	//FANCY TIME
/datum/weather/pollen
	name = "pollen"
	immunity_type = "pollen"
	desc = "Pollen. Lots of pollen. A good sign of spring."
	telegraph_message = span_warning("It's a wonderful day...")
	telegraph_duration = 150
	weather_message = span_userdanger("...As pollen begins to choke you from the inside out.")
	weather_overlay = "pollen"
	weather_duration_lower = 1200		//600 per Minute?
	weather_duration_upper = 3000
	perpetual = TRUE //lasts forever!
	end_duration = 100
	end_message = span_boldannounce("Your throat begins to clear!")
	end_overlay = "pollen_fading"
	area_type = /area
	target_trait = ZTRAIT_STATION
	//it lasts until...
/mob/living/simple_animal/hostile/abnormality/cupid/Destroy()
	SSweather.end_weather(/datum/weather/pollen)

/datum/weather/pollen/weather_act(mob/living/carbon/human/L)
	if(ishuman(L))
		L.deal_damage(3, BLACK_DAMAGE, attack_type = (ATTACK_TYPE_ENVIRONMENT)) //okay i felt histans was too mean
		return
//	if(prob(1))
//	user.reagents.add_reagent(/datum/reagent/toxin/histamine, 2) //DON'T RISK KILLING PEOPLE. we want a pest not a murderer.
//		return
