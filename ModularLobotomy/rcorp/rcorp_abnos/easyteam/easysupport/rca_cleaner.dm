/mob/living/simple_animal/hostile/rcorp_abno/easysupport/cleaner
	name = "All-Around Cleaner"
	desc = "A tiny robot with helpful intentions. It's cleaning tools release a strong gust, avoid closing the distance"
	maxHealth = 800
	health = 800
	melee_damage_lower = 11
	melee_damage_upper = 12
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.7, WHITE_DAMAGE = 1, BLACK_DAMAGE = 2, PALE_DAMAGE = 2)
	original_abno = /mob/living/simple_animal/hostile/abnormality/cleaner

	abno_additional_instructions = "<h1>You are All-Around Cleaner, A Combat Role Abnormality.</h1><br>\
		<b>|Special Cleaning|: When moving within 2 tile range of a mess you will clean it. \
		When said mess is a human you will violently toss them if they are not in crit. <br>\
		</b>"

	var/bumpdamage = 10

/mob/living/simple_animal/hostile/rcorp_abno/easysupport/cleaner/Initialize()
	. = ..()
	icon = 'ModularLobotomy/_Lobotomyicons/48x48.dmi'
	icon_state = "cleaner"
	pixel_x = -8
	base_pixel_x = -8
	pixel_y = -8
	base_pixel_y = -8

/mob/living/simple_animal/hostile/rcorp_abno/easysupport/cleaner/Move()
	..()
	//Toss meatbags aside
	for(var/mob/living/carbon/human/H in range(1, src))
		if(src.faction_check_mob(H))
			continue
		if(H.stat >= SOFT_CRIT)
			continue
  		visible_message("[src] tosses [H] out of the way!")
		H.deal_damage(bumpdamage, RED_DAMAGE, src)

		var/rand_dir = pick(NORTH, SOUTH, EAST, WEST)
		var/atom/throw_target = get_edge_target_turf(H, rand_dir)
		if(!H.anchored)
			H.throw_at(throw_target, rand(6, 10), 18, H)

		if(H.stat == DEAD)
			H.gib(FALSE, FALSE, FALSE)

	//destroy the unclean
	for(var/turf/tile in view(src, 2))
		tile.wash(CLEAN_SCRUB)
		for(var/A in tile)
			// Clean small items that are lying on the ground
			if(isitem(A))
				var/obj/item/I = A
				if(I.w_class <= WEIGHT_CLASS_SMALL && !ismob(I.loc))
					I.wash(CLEAN_SCRUB)
			// Clean humans that are lying down
			else if(ishuman(A))
				var/mob/living/carbon/human/cleaned_human = A
				if(cleaned_human.body_position == LYING_DOWN)
					cleaned_human.wash(CLEAN_SCRUB)
					cleaned_human.regenerate_icons()
					to_chat(cleaned_human, span_danger("[src] flawlessly cleans you of your features!"))
					ADD_TRAIT(cleaned_human, TRAIT_DISFIGURED, TRAIT_GENERIC) //cleans your face of uneeded features
