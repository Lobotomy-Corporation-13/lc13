/* Der Fluchshutze, implemnted by neadsy_ - Sprites by Cringelord
This was ACTUAL hell to make, I was cooking up straight EVIL in a kettle
Pretty Basic HE with a cool gimmick */
/mob/living/simple_animal/hostile/abnormality/der_fluchschutze
	name = "Der Fluchschütze"
	desc = "A tall man adorned in some sort of military uniform, they loom over you, holding their large shotgun."
	icon = 'ModularLobotomy/_Lobotomyicons/32x64.dmi'
	icon_state = "DrFluShots"
	icon_living = "DrFluShots"
	portrait = "derfluschutz"
	del_on_death = TRUE
	maxHealth = 1300
	health = 1300 // Chunky lad, will be standing still for long amounts of time, needs to not get destroyed instantly
	rapid_melee = 1
	melee_queue_distance = 2
	move_to_delay = 4
	attack_sound = 'sound/weapons/ego/mace1.ogg'
	attack_verb_continuous = "bashes"
	attack_verb_simple = "hit"
	melee_damage_type = BLACK_DAMAGE
	stat_attack = HARD_CRIT
	ranged = TRUE
	being_tested = TRUE
	enablePB = TRUE // This is a new var made specifically for derflusch, If TRUE it skips the check that disables using guns in melee range
	ranged_cooldown_time = 2 SECONDS
	casingtype = /obj/item/ammo_casing/caseless/fellround
	projectilesound = 'sound/abnormalities/fluchschutze/fell_bullet.ogg'
	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 0.7, FIRE = 0.5) // again, needs to be tough
	melee_damage_lower = 15
	melee_damage_upper = 25 // "get away from me" - Der fluch probably, do NOT let this lad melee you
	faction = list("derfluchschutze") // *incoming call...* "KILL EVERYONE"
	can_breach = TRUE
	can_act = TRUE
	threat_level = HE_LEVEL
	start_qliphoth = 3
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 35,
		ABNORMALITY_WORK_INSIGHT = 20,
		ABNORMALITY_WORK_ATTACHMENT = 60,
		ABNORMALITY_WORK_REPRESSION = 45,
	)
	max_boxes = 16
	work_damage_amount = 10
	work_damage_type = RED_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/wrath

	ego_list = list(
		/datum/ego_datum/weapon/fellbullet,
		/datum/ego_datum/weapon/fellscatter,
		/datum/ego_datum/armor/fellbullet,
	)
	gift_type = /datum/ego_gifts/fellbullet
	gift_message = "You too, chose to deal with the devil."
	abnormality_origin = ABNORMALITY_ORIGIN_LIMBUS

	observation_prompt = "The Abnormality towers over you, it prepares its shotgun. Ready to fire, it says... 'This is a warzone, and my gun must blow somebody up...' \
	In the corner of your eye, you see a silver glimmer: A pendant the Abnormality lost? or perhaps intentionally discarded..."
	observation_choices = list(
		"Inform the Abnormality you are on their side." = list(TRUE, "'alright then, keep the fight going for me.'"),
		"Return the pendant to the Abnormality." = list(FALSE, "The Abnormality opens the pendant and begins lashing out, firing bullets indescriminantly.\
			You manage to escape before you are seriously hurt."),
	)

	var/ammo = 2 // How much ammo he starts with
	var/max_ammo = 2 // max ammo he can have at any given time
	var/reload_time = 5 SECONDS // how long for passive reload
	var/last_reload_time = 0 // when he last reloaded
	var/sacrifice_spawn = 10 // How many sacrifices he spawns
	var/firecooldown = 60 SECONDS // how often he can use his sacrifice spawn
	var/lastfired = 0 // when he last used his sacrifice spawn
	var/staggered = FALSE // if he is staggered
	var/stagger = 0 // how many sacrifices have been destroyed
	var/aiming = FALSE // if he is aiming at sacrifices

	//Simple bool check if we're breached or not to use less processing power.
	var/breached = FALSE

/mob/living/simple_animal/hostile/abnormality/der_fluchschutze/Login()
	. = ..()
	if(!. || !client)
		return FALSE
	to_chat(src, "<h1>You are Der Fluchschutze, A Support Role Abnormality.</h1><br>\
		<b>|I shall Fire|: When you click on a tile or enemy at least 2 tiles away, You will consume 1 ammo to fire 5 pellets which deal 25 red damage each.<br>\
		<b>|Ammo|: You have a max of 2 ammo at any given time. You passively reload 1 ammo every second, but you can also reload 1 ammo by hitting humans or mechs.</b>")

/mob/living/simple_animal/hostile/abnormality/der_fluchschutze/SuccessEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if (prob(30))
		datum_reference.qliphoth_change(1) // once his counter lowers it will be tough to raise it
	return

/mob/living/simple_animal/hostile/abnormality/der_fluchschutze/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(40))
		datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/der_fluchschutze/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/der_fluchschutze/PostWorkEffect(mob/living/carbon/human/user, work_type, pe)
	if(work_type == ABNORMALITY_WORK_ATTACHMENT)
		if (prob(20))
			datum_reference.qliphoth_change(-2) // big qlipoth dip at a low chance, go big or go home.
		return ..()
	return ..()


//Breach

/mob/living/simple_animal/hostile/abnormality/der_fluchschutze/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	breached = TRUE

/mob/living/simple_animal/hostile/abnormality/der_fluchschutze/proc/Reload()
	playsound(src, 'sound/abnormalities/fluchschutze/fell_aim.ogg', 25, TRUE)
	to_chat(src, span_nicegreen("You reload your shotgun..."))
	ammo += 1

/mob/living/simple_animal/hostile/abnormality/der_fluchschutze/Life()
	..()
	if (!breached)
		return

	if (last_reload_time < world.time - reload_time)
		last_reload_time = world.time
		if (ammo < max_ammo)
			Reload()

	if(lastfired + firecooldown <= world.time)
		if(prob(25))
			aiming = TRUE
			updatedefense()
			lastfired = world.time
			can_act = FALSE
			for(var/i = 1 to sacrifice_spawn)
				var/turf/W = pick(GLOB.xeno_spawn)
				var/mob/living/simple_animal/hostile/der_flusch_sacrifice/E = new(get_turf(W))
				playsound(get_turf(src), 'sound/abnormalities/fluchschutze/fell_aim.ogg', 35, 0, 20)
				playsound('sound/abnormalities/fluchschutze/fell_magic.ogg', 35, 0, 20)
				IconChange(aiming = TRUE)
				E.Boss = src

	if(lastfired + 21 SECONDS <= world.time && staggered == FALSE)
		aiming = FALSE
		can_act = TRUE
		updatedefense()
		IconChange(aiming = FALSE)

	if(stagger >= 2)
		staggered = TRUE
		to_chat(src, span_warning("You are staggered!"))
	if(world.time >= lastfired + 40 SECONDS)
		staggered = FALSE
		stagger = 0
		to_chat(src, span_nicegreen("You are no longer staggered!"))

/mob/living/simple_animal/hostile/abnormality/der_fluchschutze/AttackingTarget(atom/attacked_target)
	if(ammo < max_ammo)
		if(isliving(attacked_target)) // same as RBA, getting hit by him lets him reload, potentially denying your escape
			Reload()
		if(ismecha(attacked_target))
			Reload()

	if(ranged_cooldown <= world.time + 1) // Delays Point-Blanks a bit because they HURT
		if(ammo > 0)
			if(prob(50))
				OpenFire(target)
			return ..()
	return FALSE

/mob/living/simple_animal/hostile/abnormality/der_fluchschutze/OpenFire(atom/A)
	if(staggered == FALSE && can_act == TRUE)
		if(get_dist(src, A) >= 1)
			if(ammo <= 0)
				to_chat(src, span_warning("Out of ammo!"))
				return FALSE
			else
				ammo -= 1
				return ..()
	else
		return FALSE


/mob/living/simple_animal/hostile/abnormality/der_fluchschutze/proc/sacrificedestroyed(/mob/living/simple_animal/hostile/der_flusch_sacrifice/E)
	stagger += 1

/mob/living/simple_animal/hostile/abnormality/der_fluchschutze/proc/updatedefense()
	if(aiming == TRUE)
		damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 0.5, FIRE = 0.5)
	else
		damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 0.7, FIRE = 0.5)

/mob/living/simple_animal/hostile/abnormality/der_fluchschutze/proc/IconChange(aiming)
	if(aiming == TRUE)
		icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
		update_icon()
	else
		icon = 'ModularLobotomy/_Lobotomyicons/32x64.dmi'
		update_icon()

//gunstuff
/obj/item/ammo_casing/caseless/fellround
	name = "Fell Bullet Casing"
	desc = "a casing from the gun destined to pierce the one who the wielder loves most."
	projectile_type = /obj/projectile/fellround
	pellets = 5
	variance = 25


/obj/projectile/fellround
	name = "Fell Bullet Round"
	desc = "A shotgun pellet, its headed straight for you."
	damage_type = RED_DAMAGE
	damage = 20
	speed = 0.4
	spread = 15

/obj/projectile/fellround/Initialize()
	. = ..()
	hitsound = "sound/abnormalities/fluchschutze/fell_scatter2.ogg"


// Sacrifice and their related effects
/mob/living/simple_animal/hostile/der_flusch_sacrifice
	name = "Refracted G-Corp Soldier"
	desc = "A strange G-Corp Soldier, It seems unresponsive. A portal hovers behind its head. You feel like you are being watched. <br> \
	<b>Refracted in the lens of the shooter, Der Fluchschütze is using this target as a sacrifice!</b>"
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "fluch_sacrifice"
	icon_living = "fluch_sacrifice"
	maxHealth = 150
	health = 150
	can_patrol = FALSE
	faction = list("derfluchschutze")
	wander = 0
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	obj_damage = 0
	del_on_death = TRUE
	density = TRUE
	environment_smash = ENVIRONMENT_SMASH_NONE
	death_message = "Shatters..."
	AIStatus = AI_OFF
	var/mob/living/simple_animal/hostile/abnormality/der_fluchschutze/Boss
	var/deathtimer = 0
	var/exploded = FALSE
	var/mob/living/simple_animal/hostile/der_flusch_sacrifice/E

/mob/living/simple_animal/hostile/der_flusch_sacrifice/proc/ShatterSoul()
	if(Boss)
		Boss = null
	dust(TRUE,TRUE,TRUE)

/mob/living/simple_animal/hostile/der_flusch_sacrifice/Move()
	return FALSE

/mob/living/simple_animal/hostile/der_flusch_sacrifice/Initialize()
	..()
	addtimer(CALLBACK(src, PROC_REF(explode)), 20 SECONDS)

/mob/living/simple_animal/hostile/der_flusch_sacrifice/death()
	if(exploded != TRUE)
		Boss.sacrificedestroyed(src)
		playsound(get_turf(src), 'sound/effects/ordeals/brown_end.ogg', 35, 0, 20)
		qdel(src)
	return

/mob/living/simple_animal/hostile/der_flusch_sacrifice/proc/explode()
	//NEed to set the var for when we fucking die
	playsound('sound/abnormalities/fluchschutze/fell_scatter.ogg', 35, 0, 20)
	exploded = TRUE
	playsound(get_turf(src), 'sound/effects/explosion2.ogg', 50, 0, 8)
	for(var/turf/T in range(3, src))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		for(var/mob/living/L in T)
			var/throw_dir = get_dir(src, L)
			if(!throw_dir)
				throw_dir = pick(NORTH, SOUTH, EAST, WEST) // random dir if on same tile
			var/throw_target = get_edge_target_turf(L, throw_dir)
			L.throw_at(throw_target, 4, 2)
			L.deal_damage(70, RED_DAMAGE)
	qdel(src)
