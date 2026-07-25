#define STATUS_EFFECT_FALSEKIND /datum/status_effect/rca_false_kindness
/mob/living/simple_animal/hostile/rcorp_abno/easy/drifting_fox
	name = "Drifting Fox"
	desc = "A large shaggy fox with gleaming yellow eyes; And torn umbrellas lodged into its back. It seems quite skittish, best not let it escape."
	del_on_death = FALSE
	maxHealth = 1000
	health = 1000
	rapid_melee = 2
	move_to_delay = 5.2
	damage_coeff = list( RED_DAMAGE = 0.9, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 1.5 )
	melee_damage_lower = 5
	melee_damage_upper = 15 // Idea taken from the old PR, have a large damage range to immitate its fucked rolls and crit chance.
	melee_damage_type = BLACK_DAMAGE
	original_abno = /mob/living/simple_animal/hostile/abnormality/drifting_fox

	var/umbrella_spawn_number = 1
	var/umbrella_spawn_time = 5 SECONDS
	var/umbrella_spawn_limit = 4
	var/list/spawned_mobs = list()
	var/initial_mobs_spawned

	abno_additional_instructions = "<h1>You are Drifting Fox, A Combat Role Abnormality.</h1><br>\
		<b>|Tattored Shelter|: After losing 10% of your health, you will start spawning Worn Umbrellas around you. \
		Worn Umbrellas will teleport to you if you move too far away from them. \
		Also, You will gain a slight speed boost for each Umbrella you have alive.<br>\
		<br>\
		<b>|Last Struggle|: When attacking or being attacked within melee you have a small chance to evade. \
		Evading initiates a 5 tile dash in the direction you were facing away from. \
		Upon evading you will then spawn a Worn Umbrella where you were standing. <br> \
		<br>\
		|Worn Umbrellas|: Worn Umbrellas will passively attack humans that they can see by firing a 3x3 AoE on their targets. \
		If the target gets hit by the AoE, They will gain a debuff which causes them to take more BLACK damage from all sources. \
		However, if the umbrellas are broken you will lose 5% HP and gain slight temporary slowdown for each umbrella broken.<br></b>"

/mob/living/simple_animal/hostile/rcorp_abno/easy/drifting_fox/Initialize()
		. = ..()
		icon_living = "fox_breach"
		icon_state = icon_living
		pixel_y = -6

/mob/living/simple_animal/hostile/rcorp_abno/easy/drifting_fox/death(gibbed)
	icon = 'ModularLobotomy/_Lobotomyicons/abno_cores/he.dmi'
	pixel_x = -16
	pixel_y = 0
	density = FALSE
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/drifting_fox/Life()
	. = ..()
	if(!.) // Dead
		return FALSE
	if(health <= 900 && !initial_mobs_spawned)
		playsound(src, 'sound/abnormalities/drifting_fox/fox_aoe_sound.ogg', 50, FALSE, 4)
		initial_mobs_spawned = TRUE
		addtimer(CALLBACK(src, PROC_REF(UmbrellaLoop)), 30 SECONDS)
		for(var/i=4, i>=1, i--) //spawn 4 umbrellas right off the bat
			var/mob/living/simple_animal/hostile/rca_umbrella/newmob = new(get_turf(src))
			newmob.faction = faction
			spawned_mobs+=newmob
			newmob.friend = src
			newmob.GoToFox()
			newmob.ranged_cooldown_time = rand(20,80)
			move_to_delay = clamp(move_to_delay - 1, 3, 7) //Speed up
			UpdateSpeed()

/mob/living/simple_animal/hostile/rcorp_abno/easy/drifting_fox/AttackingTarget(atom/attacked_target)
	..()
	if(prob(10))
		Dodge()

/mob/living/simple_animal/hostile/rcorp_abno/easy/drifting_fox/attacked_by(obj/item/I, mob/living/user)
	..()
	if(prob(30))
		Dodge()

/mob/living/simple_animal/hostile/rcorp_abno/easy/drifting_fox/proc/UmbrellaLoop()
	listclearnulls(spawned_mobs)
	for(var/mob/living/L in spawned_mobs)
		if(L.stat == DEAD)
			spawned_mobs -= L
	if(length(spawned_mobs) > umbrella_spawn_limit)
		return
	var/mob/living/simple_animal/hostile/rca_umbrella/newmob = new(get_turf(src))
	newmob.faction = faction
	spawned_mobs+=newmob
	newmob.friend = src
	newmob.GoToFox()
	newmob.ranged_cooldown_time = rand(20,80)
	move_to_delay = clamp(move_to_delay - 1, 3, 7) //Speed up
	addtimer(CALLBACK(src, PROC_REF(UmbrellaLoop)), umbrella_spawn_time)

//Here's the dodge code. It's a fox so it's skittish, It's gonna dodge back and drop an umbrella at it's feet.
// It dodges upon getting melee hit *sometimes* and *sometimes* on attack
/mob/living/simple_animal/hostile/rcorp_abno/easy/drifting_fox/proc/Dodge()
	//Spawn an umbrella here
	if(length(spawned_mobs) < umbrella_spawn_limit)
		var/mob/living/simple_animal/hostile/rca_umbrella/newmob = new(get_turf(src))
		newmob.faction = faction
		spawned_mobs+=newmob
		newmob.friend = src
		newmob.GoToFox()
		newmob.ranged_cooldown_time = rand(20,80)

	if (stat == DEAD)
		return FALSE

	//Grab the direction we face away from,
	var/dash_dir = turn(dir, 180)

	var/turf/next_turf = get_step(src, dash_dir)
	if(next_turf.density)	//Here's the deal, we check if there's a wall directly behind us
		//Set our density false
		density = FALSE
		//And dash forwards
		dash_dir = dir


	for(var/i = 1 to 5)
		next_turf = get_step(src, dash_dir)
		if(!next_turf)
			break
		if(next_turf.density)
			break
		forceMove(next_turf)
		SLEEP_CHECK_DEATH(1)

	density = TRUE


//Summons
/mob/living/simple_animal/hostile/rca_umbrella
	name = "Umbrella"
	desc = "A tattered and worn umbrella; The fox seems to have many to spare, however upon breaking they leave many splinters, it's likely these splinters will harm the fox."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "foxbrella"
	icon_living = "foxbrella"
	faction = list("hostile")
	maxHealth = 125
	health = 125
	density = FALSE
	status_flags = MUST_HIT_PROJECTILE // Allows projectiles to hit non-dense mob
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 0.7, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 2)
	del_on_death = FALSE
	ranged = TRUE
	ranged_cooldown_time = 3 SECONDS
	var/teleport_cooldown_time = 10 SECONDS
	var/teleport_cooldown
	/// The drifting fox
	var/mob/living/simple_animal/hostile/rcorp_abno/friend

/mob/living/simple_animal/hostile/rca_umbrella/Login()
	. = ..()
	to_chat(src, "<h1>You are Umbrella, A Drifting Fox Minion.</h1><br>\
		<b>|Scattering Sorrow|: When attacking you will perform a 3x3 AoE in the area you targetted, anyone hit will take BLACK damage and gain BLACK Fragility. <br>\
		<br>\
		|Sunshower|: While alive raise Drifting Fox's speed, every 10 seconds teleport to Drifting Fox if not in sight.<br>\
		<br>\
		|Old and Abandoned|: When killed cause Drifting Fox to lose 5% of its HP and lower it's speed.</b>")

/// Deal damge to the fox
/mob/living/simple_animal/hostile/rca_umbrella/death(gibbed)
	visible_message(span_notice("[src] falls to the ground as the umbrella closes in on itself!"))
	if(friend)
		friend.deal_damage(100, BLACK_DAMAGE, flags = (DAMAGE_FORCED | DAMAGE_UNTRACKABLE), attack_type = (ATTACK_TYPE_SPECIAL))
		friend.move_to_delay = clamp(move_to_delay + 1, 3, 7) //Slowdown
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	return ..()

///checks if the fox is in view every 10 seconds, and if not teleports to it
/mob/living/simple_animal/hostile/rca_umbrella/Life()
	. = ..()
	if(!friend || stat == DEAD) //for some reason life() works on death ain't that something
		return
	if(QDELETED(friend)) //Fox died, we're gone too
		death()
		return
	if(teleport_cooldown < world.time)
		teleport_cooldown = world.time + teleport_cooldown_time
		if(!can_see(src, friend, vision_range))
			GoToFox()

/mob/living/simple_animal/hostile/rca_umbrella/proc/GoToFox()
	if(!friend)
		return
	var/turf/move_turf = get_step(friend, pick(1,2,4,5,6,8,9,10))
	if(!isopenturf(move_turf))
		move_turf = get_turf(friend)
	forceMove(move_turf)
	LoseTarget()

/mob/living/simple_animal/hostile/rca_umbrella/OpenFire()
	ranged_cooldown_time = rand(20,80) //keeps them attacking asynchronously
	if(!isliving(target))
		LoseTarget()
		return
	var/turf/target_turf = get_turf(target)
	for(var/turf/L in view(1, target_turf))
		new /obj/effect/temp_visual/cult/sparks(L)
	SLEEP_CHECK_DEATH(6)
	for(var/turf/T in view(1, target_turf))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		for(var/mob/living/carbon/human/H in HurtInTurf(T, list(), 15, BLACK_DAMAGE, null, TRUE, FALSE, TRUE, FALSE, TRUE, TRUE, attack_type = (ATTACK_TYPE_SPECIAL)))
			H.apply_status_effect(STATUS_EFFECT_FALSEKIND)
	playsound(target_turf, 'sound/abnormalities/drifting_fox/fox_umbrella.ogg', 25, TRUE, 4)
	ranged_cooldown = world.time + ranged_cooldown_time

/mob/living/simple_animal/hostile/rca_umbrella/Move()
	return FALSE

/mob/living/simple_animal/hostile/rca_umbrella/AttackingTarget(atom/attacked_target)
	if(!target)
		GiveTarget(attacked_target)
	OpenFire()
	return

/datum/status_effect/rca_false_kindness // MAYBE the black sunder shti works this time.
	id = "rca_false_kindness"
	duration = 2 SECONDS //lasts 2 seconds becuase this is for an AI that attacks fast as shit, its not meant to fuck you up with other things.
	alert_type = /atom/movable/screen/alert/status_effect/rca_false_kindness
	status_type = STATUS_EFFECT_REFRESH

/atom/movable/screen/alert/status_effect/rca_false_kindness
	name = "False Kindness"
	desc = "You feel the weight of your mistakes. Take more BLCK damage."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "false_kindness" //Bit of a placeholder sprite, it works-ish so

/datum/status_effect/false_kindness/on_apply() //" Borrowed " from Ptear blade, courtesy of gong.
	. = ..()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/status_holder = owner //Stolen from Ptear Blade, MAYBE works on people?
	to_chat(status_holder, span_userdanger("You feel the foxes gaze upon you!"))
	status_holder.physiology.black_mod *= 1.3

/datum/status_effect/false_kindness/on_remove()
	. = ..()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/status_holder = owner
	to_chat(status_holder, span_userdanger("You feel as though its gaze has lifted.")) //stolen from PT wep, but I asked so this 100% ok.
	status_holder.physiology.black_mod /= 1.3

#undef STATUS_EFFECT_FALSEKIND
