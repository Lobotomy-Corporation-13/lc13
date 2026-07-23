/mob/living/simple_animal/hostile/rcorp_abno/easy/pisc_mermaid
	name = "Piscine Mermaid"
	desc = "A limbless abnormality ressembling a mermaid. Their heart shaped eyes look at you with both love and jealousy."
	del_on_death = FALSE
	maxHealth = 1500
	health = 1500
	damage_coeff = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 2) //not that bad without a lover
	rapid_melee = 2
	melee_damage_lower = 15
	melee_damage_upper = 20 //really subpar damage and speed but most of her damage is oxyloss anyway
	move_to_delay = 2.8
	melee_damage_type = BLACK_DAMAGE
	original_abno = /mob/living/simple_animal/hostile/abnormality/pisc_mermaid

	var/suffocation_range = 10

	abno_additional_instructions = "<h1>You are All-Around Cleaner, A Combat Role Abnormality.</h1><br>\
		<b>|Unrequited Love|: When within a 10 tile sightline of a hostile human being you will do passive OXY damage to them. \
		This OXY damage also known as suffocation pierces mechs however it is also passively healed when not within your sightline. <br>\
		</b>"

/mob/living/simple_animal/hostile/rcorp_abno/easy/pisc_mermaid/Initialize()
	. = ..()
	icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
	icon_living = "pmermaid_breach"
	icon_dead = "pmermaid_slain"
	icon_state = icon_living
	pixel_y = -16
	base_pixel_y = -16

/mob/living/simple_animal/hostile/rcorp_abno/easy/pisc_mermaid/death(gibbed)
	density = FALSE
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/pisc_mermaid/Life()
	. = ..()
	if(!.)
		return
	for(var/mob/living/carbon/human/H in oview(src, suffocation_range))
		if(faction_check(src.faction, H.faction)) // I LOVE NESTING IF STATEMENTS
			continue
		//they suffocate everyone they can see but you can just get out of her view to stop it
		H.adjustOxyLoss(3, updating_health=TRUE, forced=TRUE)
		new /obj/effect/temp_visual/mermaid_drowning(get_turf(H))
