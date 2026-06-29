// --------- SHRIMP DUNGEON BOSS ENEMIES ---------
// --------- (badly) MADE BY XEROS               ---------

/mob/living/simple_animal/hostile/shrimp_hos
	name = "Wellcheers Head of Security"
	desc = "A heavily armored, gas mask-clad shrimp, armed with a semi-automatic shotgun and gas grenades." //Literally just the Enforcer from Cultic lmao
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "wellcheers_hos"
	icon_living = "wellcheers_hos"
	icon_dead = "wellcheers_hos_dead"
	attack_sound = 'sound/abnormalities/clock/clank.ogg'
	faction = list("shrimp")
	gender = MALE
	maxHealth = 7500
	health = 7500
	melee_damage_lower = 28
	melee_damage_upper = 34
	ranged = TRUE
	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 1)
	move_to_delay = 5.5
	rapid = 5
	rapid_fire_delay = 4.3
	ranged_cooldown_time = 23
	casingtype = /obj/item/ammo_casing/caseless/ego_shrimpsoldier
	projectilesound = 'sound/weapons/gun/shotgun/shot.ogg'
	var/datum/beam/current_beam = null
	var/grenade_cooldown
	var/grenade_cd_duration = 30 SECONDS


/mob/living/simple_animal/hostile/shrimp_hos/OpenFire(atom/A) //We able to gas them? No? Bust out the shotty.
	if(!can_act)
		return
	if(gas_grenade())
		return FALSE
	if(PrepareToFire(A))
		return ..()
	return FALSE

/mob/living/simple_animal/hostile/shrimp_hos/proc/PrepareToFire(atom/A) //Copypasted code from TTLS snipers. Intended to serve as the "warning" for the shotgun.
	current_beam = Beam(A, icon_state="blood", time = 0.7 SECONDS)
	playsound(src, 'sound/weapons/gun/shotgun/rack.ogg', 200, TRUE, 2)
	can_act = FALSE
	SLEEP_CHECK_DEATH(0.9 SECONDS) //WAY faster than the grungeon boss
	can_act = TRUE
	return TRUE

/mob/living/simple_animal/hostile/shrimp_hos/proc/gas_grenade()
	if(grenade_cooldown>world.time)
		return FALSE
	playsound(src, 'sound/magic/clockwork/invoke_general.ogg', 200, TRUE, 2)
	grenade_cooldown = (world.time+grenade_cd_duration)
	SLEEP_CHECK_DEATH(12)
	return TRUE
