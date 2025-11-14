GLOBAL_LIST_INIT(low_security, list(
	/mob/living/simple_animal/hostile/limbus_abno/scorched_girl,
	/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid,
	/mob/living/simple_animal/hostile/limbus_abno/laetitia,
	/mob/living/simple_animal/hostile/limbus_abno/simple_smile,
	/mob/living/simple_animal/hostile/limbus_abno/helper,
	/mob/living/simple_animal/hostile/limbus_abno/pbird
))

GLOBAL_LIST_INIT(high_security, list(
	/mob/living/simple_animal/hostile/limbus_abno/mountain,
	/mob/living/simple_animal/hostile/limbus_abno/queen_bee
))

//These are the lcl abnos that can actually be used. The ones above are those that show in the preference list.
//In other words, the list below can be changed freely and mid round, the list above shouldn't as it must always contains every single lcl abno that exist for reference.
GLOBAL_LIST_INIT(available_low_sec_abno, list(
	/mob/living/simple_animal/hostile/limbus_abno/scorched_girl,
	/mob/living/simple_animal/hostile/limbus_abno/pisc_mermaid,
	/mob/living/simple_animal/hostile/limbus_abno/laetitia,
	/mob/living/simple_animal/hostile/limbus_abno/simple_smile,
	/mob/living/simple_animal/hostile/limbus_abno/helper,
	/mob/living/simple_animal/hostile/limbus_abno/pbird
))

GLOBAL_LIST_INIT(available_high_sec_abno, list(
	/mob/living/simple_animal/hostile/limbus_abno/mountain,
	/mob/living/simple_animal/hostile/limbus_abno/queen_bee))

/obj/effect/landmark/start/limbus_abnospawn
	name = "Limbus abno spawner"
	desc = "It spawns a limbus abno. Notify a coder. Thanks!"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x4"
	delete_after_roundstart = FALSE

//Split into Lowsec and Highsec
/obj/effect/landmark/start/limbus_abnospawn/lowsec
	name = "lowsec limbus abno spawner"
	icon_state = "x3"

/obj/effect/landmark/start/limbus_abnospawn/highsec
	name = "highsec limbus abno spawner"
	icon_state = "x2"
