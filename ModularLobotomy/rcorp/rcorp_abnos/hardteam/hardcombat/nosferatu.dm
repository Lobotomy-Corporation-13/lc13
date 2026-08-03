#define NOSFERATU_BANQUET_COOLDOWN (12 SECONDS)
//Thrown into combat due to frontline role revolving around AoE and regen
/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu
	name = "Nosferatu"
	desc = "A vampire, huh. Think I heard of it somewhere. Blood seems to be drawn to it, don't let it near any."
	maxHealth = 2000
	health = 2000
	move_to_delay = 6
	rapid_melee = 1
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.4, PALE_DAMAGE = 1.5)
	melee_damage_lower = 35
	melee_damage_upper = 45 //has a wide range, he can critically hit you
	melee_damage_type = RED_DAMAGE
	ranged = TRUE
	retreat_distance = 2
	minimum_distance = 1
	projectiletype = /obj/projectile/rca_nosferatu_bat
	original_abno = /mob/living/simple_animal/hostile/abnormality/nosferatu

	// Combat stuff
	var/banquet_cooldown
	var/banquet_cooldown_time = 12 SECONDS
	var/banquet_damage = 100
	var/banquet_range = 3
	var/berzerk = FALSE
	var/mist_cooldown
	var/mist_cooldown_time = 30 SECONDS
	var/mist_form = FALSE
	// Minion stuff
	var/list/spawned_bats = list()
	var/summon_cooldown_time = 15 SECONDS
	var/bat_spawn_limit = 6
	var/spawns_bats = TRUE

	// PLAYABLES ATTACKS
	attack_action_types = list(
		/datum/action/cooldown/rca_nosferatu_banquet,
		/datum/action/cooldown/rca_nosferatu_mistform,
	)

	abno_additional_instructions = "<h1>You are Nosferatu, A Combat Role Abnormality.</h1><br>\
		<b>|Bloodfeast|: When walking within a 2 tile range of blood you will absorb it, you will start the round with 1000 blood. \
		When attacking a human in melee gain 200 blood, if in critical state or dead instead drain all their blood and gain blood equal to their blood volume. \
		Your blades also go through friendly abnormalities, however do note they are also easily stopped by obstacles.<br>\
		<br>\
		|Noble Repose|: You are unable to perform melee attacks instead relying on ranged projectiles attacks. \
		These projectiles have a 25% chance to summon |Sanguine Bat| upon use. \
		If these projectiles impact a human they are guaranteed to summon |Sanguine Bat| and will also leave behind 200 blood on the floor. \
		The projectile will not summon bats if you are past the limit. <br>\
		<br>\
		|Danse Macabre|: You may use the ability Mist Form to gain complete immunity to damage and non-density. \
		Non-density allows you to move through living entities that block your path as if they weren't there. \
		You may also fly over terrain such as water or chasms during Mist Form, however if Mist Form is to end you may fall into this terrain. \
		In case of a chasm or lava death would be near instant. <br>\
		<br>\
		|Banquet of Blood|: You may perform a circular AOE reaching out 3 tiles in all directions centered around yourself through your Banquet ability. \
		If |Shapeshifting| is active you will also spend 400 blood to trigger this AoE a second time in a rebound. \
		Targets hit by this AOE will be dealt BLACK damage and inflicted with 15 stacks of |Bleed|. \
		If a human is taken into critical state by this attack they will be drained of all their blood, you gain blood equal to amount drained. <br>\
		<br>\
		|Bleed|: When a target with bleed moves, they will take True damage equal to the stack, then it reduces by half(rounded down). \
		They may prevent this by either standing still until the stack expires or walking instead of running. <br>\
		<br>\
		|Shapeshifting|: Once you reach 3000 stored blood you will immediately consume all of it to enter a berserk state. \
		In this state you lose your ranged attack but are now able to melee, your speed is also greatly boosted. \
		You will also start to passively spawn |Sanguine Bat| every 5 seconds while in this form, the bats will not be summoned if you are past the limit. \
		If you reach 3000 blood again while in the berserk state you will gain regeneration, \
		this regeneration starts at 15 HP per second and scales with blood stored, capping out at 7000 blood for 35 hp healed per second.\
		<br>\
		<br>\
		|Sanguine Bat|: These Sanguine Bats will collect blood from any targets they hit. \
		The bats may give you their stored blood by interacting with you. \
		Upon death they will spill a large portion of the blood they had stored onto the floor. \
		You possess a limit of 6 active Sanguine Bats at all times. </b>"

// Playables buttons
/datum/action/cooldown/rca_nosferatu_banquet
	name = "Banquet"
	icon_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = "nosferatu"
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE
	cooldown_time = NOSFERATU_BANQUET_COOLDOWN //12 seconds

/datum/action/cooldown/rca_nosferatu_banquet/Trigger()
	if(!..())
		return FALSE
	if(!istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu))
		return FALSE
	var/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu/nosferatu = owner
	StartCooldown()
	nosferatu.Banquet()
	return TRUE

/datum/action/cooldown/rca_nosferatu_mistform
	name = "Mist Form"
	icon_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = "nos_teleport"
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE
	cooldown_time = NOSFERATU_BANQUET_COOLDOWN //12 seconds

/datum/action/cooldown/rca_nosferatu_mistform/Trigger()
	if(!..())
		return FALSE
	if(!istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu))
		return FALSE
	var/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu/nosferatu = owner
	StartCooldown()
	nosferatu.MistForm()
	return TRUE

// Spawning stuff
/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/bloodfeast, range = 2, starting = 1000)
	pixel_x = 0
	base_pixel_x = 0
	icon_state = "nosferatu_breach"
	icon_living = icon_state
	var/list/units_to_add = list(
		/mob/living/simple_animal/hostile/rca_nosferatu_mob = 8
		)
	AddComponent(/datum/component/ai_leadership, units_to_add, 4)
	mist_cooldown = world.time + mist_cooldown_time
	banquet_cooldown = world.time + banquet_cooldown_time

/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu/Life()
	. = ..()
	if(!.)
		return
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	if(!bloodfeast) // This could potentially happen with admins playing around or something
		return
	if(bloodfeast.blood_amount < 3000) // If we have over 3000 blood saved up, we can start using some for regeneration
		return
	var/amount_healed = clamp(bloodfeast.blood_amount * 0.0050, 1, 35) // 15-35 hp healed per second, consuming blood, scaling based on total blood
	src.adjustBruteLoss(-amount_healed)
	AdjustThirst(-amount_healed)

/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu/proc/AdjustThirst(blood_amount)
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	bloodfeast.AdjustBlood(blood_amount)
	if(bloodfeast.blood_amount > 3000 && !berzerk)
		Berzerk()

/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu/proc/Berzerk()
	if(mist_form) // No bricking the mob by Berzerking when we aren't supposed to.
		return
	AdjustThirst(-3000)
	playsound(get_turf(src), 'sound/abnormalities/nosferatu/transform.ogg', 35, 8)
	ChangeMoveToDelayBy(-3)
	berzerk = TRUE
	icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
	pixel_x = -16
	base_pixel_x = -16
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(get_turf(src), src)
	animate(D, alpha = 0, transform = matrix()*2, time = 5)
	retreat_distance = null
	minimum_distance = null
	projectiletype = null
	projectilesound = null
	addtimer(CALLBACK(src, PROC_REF(BatSpawn)), 5 SECONDS)

/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu/add_splatter_floor(turf/T, small_drip) //no spilling blood, it just works.
	return

// Special attacks
/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu/OpenFire()
	if(!can_act || mist_form)
		return
	if(client)
		return ..()
	if((banquet_cooldown < world.time) && (get_dist(src, target) < 4))
		Banquet()
		return
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu/Shoot(atom/targeted_atom)
	. = ..()
	if(istype(., /obj/projectile/rca_nosferatu_bat))
		var/obj/projectile/rca_nosferatu_bat/P = .
		P.owner = src

/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu/Move()
	if(!can_act)
		return FALSE
	..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu/AttackingTarget(atom/attacked_target)
	if(mist_form)
		return
	if(!ismob(attacked_target))
		return ..()
	if(!berzerk)
		OpenFire(attacked_target)
		return
	if(!ishuman(target))
		return ..()
	var/mob/living/carbon/human/H = attacked_target
	AdjustThirst(200)
	if(H.health < 0 || H.stat == DEAD)
		AdjustThirst(H.blood_volume) // gain up to 2000 blood by draining a corpse
		H.Drain()
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu/proc/BatSpawn(atom/the_target)
	if(!spawns_bats)
		return
	var/target_atom = the_target
	if(!target_atom) // Wondering why we pass the_target to this proc? Its because the mob's projectile calls BatSpawn(target) on hit!
		target_atom = src
		addtimer(CALLBACK(src, PROC_REF(BatSpawn)), summon_cooldown_time)
	if(isclosedturf(get_turf(target_atom)))
		var/newturf = get_step_towards(get_turf(target_atom), src)
		if(isclosedturf(newturf))
			return
		target_atom = newturf
	playsound(get_turf(target_atom), 'sound/abnormalities/nosferatu/batspawn.ogg', 50, 1)
	//How many we have spawned
	listclearnulls(spawned_bats)
	for(var/mob/living/L in spawned_bats)
		if(L.stat == DEAD)
			spawned_bats -= L
	if(length(spawned_bats) >= bat_spawn_limit)
		return

	//Actually spawning them
	var/mob/living/simple_animal/hostile/rca_nosferatu_mob/B = new(get_turf(target_atom))
	spawned_bats+=B

/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu/proc/Banquet()//AOE attack
	if(mist_form) // No attack abilities while in mist form
		return
	banquet_cooldown = world.time + banquet_cooldown_time
	can_act = FALSE
	var/turf/myturf = get_turf(src)
	var/list/all_turfs = circleviewturfs(myturf, banquet_range)
	playsound(get_turf(src), 'sound/abnormalities/nosferatu/special_start.ogg', 50, 0, 5)
	for(var/turf/E in all_turfs)
		new /obj/effect/temp_visual/cult/sparks(E)
	SLEEP_CHECK_DEATH(7)
	for(var/i = 1 to banquet_range)
		var/counter = 0
		for(var/turf/T in all_turfs)
			if(get_dist(myturf, T) != i)
				continue
			addtimer(CALLBACK(src, PROC_REF(DoAttack), T, all_turfs), ((counter * 0.2) + 3 * (i+1)) + 0.5 SECONDS)
			counter += 1
	if(berzerk) // Spend 400 blood in berzerker mode to perform a more powerful version - a second attack with wider reach
		SLEEP_CHECK_DEATH(14)
		var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
		if(bloodfeast.blood_amount >= 400)
			AdjustThirst(-400)
			var/extended_range = banquet_range + 1
			all_turfs = circleviewturfs(myturf, extended_range)
			for(var/turf/E in all_turfs)
				new /obj/effect/temp_visual/cult/sparks(E)
			for(var/i = extended_range, i > 0, i--)
				var/counter = 0
				for(var/turf/T in all_turfs)
					if(get_dist(myturf, T) != i)
						continue
					addtimer(CALLBACK(src, PROC_REF(DoAttack), T, all_turfs), ((counter * 0.2) + 3 * (clamp(5 - i,0 ,5))) + 0.5 SECONDS)
					counter += 1
	SLEEP_CHECK_DEATH(20)
	can_act = TRUE

/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu/proc/DoAttack(turf/T, list/all_turfs)
	if(stat == DEAD)
		return
	var/obj/effect/temp_visual/smash_effect/bloodeffect =  new(T)
	bloodeffect.color = "#b52e19"
	playsound(T, 'sound/abnormalities/nosferatu/attack_special.ogg', 25, 0, 5)
	for(var/mob/living/L in HurtInTurf(T, list(), banquet_damage, BLACK_DAMAGE, check_faction = TRUE, exact_faction_match = TRUE, hurt_mechs = TRUE, hurt_structure = TRUE, break_not_destroy = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)))
		all_turfs -= T
		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			H.apply_lc_bleed(15)
			if(H.health < 0)
				AdjustThirst(H.blood_volume) // gain up to 2000 blood by draining a corpse
				H.Drain()
		else
			L.deal_damage(banquet_damage * 0.5, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)) // deal extra damage instead of bleed to nonhumans

/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu/proc/MistForm()
	if(!can_act)
		return
	playsound(get_turf(src), 'sound/abnormalities/nosferatu/batspawn.ogg', 75, 1)
	addtimer(CALLBACK(src, PROC_REF(ReAppear)), 5 SECONDS)
	mist_form = TRUE
	density = FALSE
	is_flying_animal = TRUE
	ChangeResistances(list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0))
	icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
	pixel_x = -16
	base_pixel_x = -16
	icon_state = "nosferatu_evade"

/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu/proc/ReAppear()
	incorporeal_move = null
	mist_form = FALSE
	density = TRUE
	is_flying_animal = FALSE
	ChangeResistances(list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.4, PALE_DAMAGE = 1.5))
	if(!berzerk)
		pixel_x = 0
		base_pixel_x = 0
		icon = 'ModularLobotomy/_Lobotomyicons/32x48.dmi'
	icon_state = icon_living

// This snippet of code makes it so that attacks from its minions give it blood.
/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu/attack_animal(mob/living/simple_animal/M)
	if(istype(M, /mob/living/simple_animal/hostile/rca_nosferatu_mob))
		var/mob/living/simple_animal/hostile/rca_nosferatu_mob/blood_transfer_target = M
		var/datum/component/bloodfeast/target_bloodfeast = blood_transfer_target.GetComponent(/datum/component/bloodfeast)
		if(target_bloodfeast.blood_amount >= 100)
			var/amount_to_transfer = clamp(target_bloodfeast.blood_amount, 100, 1000)
			target_bloodfeast.AdjustBlood(-amount_to_transfer)
			AdjustThirst(amount_to_transfer)
			visible_message(span_danger("<b>[blood_transfer_target]</b> transfers some collected blood to [src]!"))
			playsound(get_turf(src), 'sound/abnormalities/nosferatu/bloodcollect.ogg', 10, 1)
		else
			blood_transfer_target.LoseTarget()
		return
	..()

/obj/projectile/rca_nosferatu_bat
	name = "bat"
	icon_state = "bat"
	damage = 25
	hitsound = 'sound/abnormalities/nosferatu/bat_attack.ogg'
	var/mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu/owner = null

/obj/projectile/rca_nosferatu_bat/on_hit(atom/target, blocked = FALSE)
	. = ..()
	var/guaranteed_spawn = FALSE
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(H.stat == DEAD)
			return
		var/obj/effect/decal/cleanable/blood/B = new(get_turf(src))
		B.bloodiness = 200 // 200 Blood for nosferatu or its minions to collect
		guaranteed_spawn = TRUE
	if(owner)
		if(!guaranteed_spawn && prob(75))
			return
		owner.BatSpawn(target)

// Bat minion - A trash mob that automatically harvests blood on attacks and returns blood to nosferatu. Dangerous.
/mob/living/simple_animal/hostile/rca_nosferatu_mob
	name = "\improper Sanguine bat"
	desc = "It looks like a bat."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "nosferatu_mob"
	icon_living = "nosferatu_mob"
	icon_dead = "nosferatu_mob"
	is_flying_animal = TRUE
	density = FALSE
	status_flags = MUST_HIT_PROJECTILE // Lets them be shot
	speak_emote = list("screeches")
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	attack_sound = 'sound/abnormalities/nosferatu/bat_attack.ogg'
	del_on_death = TRUE
	health = 300
	maxHealth = 300
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 1.8, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 2)
	melee_damage_type = RED_DAMAGE
	melee_damage_lower = 5
	melee_damage_upper = 20
	move_to_delay = 1.3 //very fast, very weak.
	stat_attack = HARD_CRIT
	ranged = TRUE
	retreat_distance = 3
	minimum_distance = 1

/mob/living/simple_animal/hostile/rca_nosferatu_mob/Login()
	. = ..()
	to_chat(src, "<h1>You are Sanguine Bat, A Nosferatu Minion.</h1><br>\
		<b>|Fear of Water|: Your sanguine wings allow you to fly over certain obstacles such as water or chasms. <br>\
		<br>\
		|Bloodsucking|: When within a 1 tile range of blood you will absorb that blood and store it, if killed leave behind a portion of the blood you drank.<br>\
		<br>\
		|Digging Teeth|: When attacking a living being gain a bit of blood, if attacking a human in a critical state or dead, drain all their blood.<br>\
		<br>\
		|Avid Thirst|: When attacking Nosferatu if your stored Blood is 100 or more give up to 1000 stored blood to him.</b>")

/mob/living/simple_animal/hostile/rca_nosferatu_mob/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/bloodfeast, range = 1)

/mob/living/simple_animal/hostile/rca_nosferatu_mob/proc/AdjustThirst(blood_amount)
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	bloodfeast.AdjustBlood(blood_amount)

/mob/living/simple_animal/hostile/rca_nosferatu_mob/AttackingTarget(atom/attacked_target) // They gain blood on hit
	. = ..()
	if(!ishuman(attacked_target))
		return
	var/mob/living/carbon/human/H = attacked_target
	if(H.health < 0 || H.stat == DEAD)
		AdjustThirst(H.blood_volume) // gain up to 2000 blood by draining a corpse
		H.Drain()
		return
	AdjustThirst(100)

/mob/living/simple_animal/hostile/rca_nosferatu_mob/OpenFire(atom/A)
	if(istype(A, /mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu))
		return
	visible_message(span_danger("<b>[src]</b> flies around, seemingly aiming for [A]!"))
	ranged_cooldown = world.time + ranged_cooldown_time

/mob/living/simple_animal/hostile/rca_nosferatu_mob/PickTarget(list/Targets)
	var/list/priority = list()
	for(var/mob/living/L in Targets)
		if(istype(L, /mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu))
			var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
			if(bloodfeast.blood_amount >= 500)
				return L // We have a bunch of blood, time to give it to bossman.4
			continue
		if(!CanAttack(L))
			continue
		priority += L
	if(LAZYLEN(priority))
		return pick(priority)

/mob/living/simple_animal/hostile/rca_nosferatu_mob/CanAttack(atom/the_target)
	if(istype(the_target, /mob/living/simple_animal/hostile/rcorp_abno/hard/nosferatu))
		return TRUE
	return ..()

/mob/living/simple_animal/hostile/rca_nosferatu_mob/death(gibbed)
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	var/obj/effect/decal/cleanable/blood/B = new(get_turf(src))
	B.bloodiness = (bloodfeast.blood_amount * 0.5) // drops half of its blood on death. This is potentially far more than what fits in a splatter.
	..()

#undef NOSFERATU_BANQUET_COOLDOWN
