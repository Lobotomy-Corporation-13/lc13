/mob/living/simple_animal/hostile/rcorp_abno/easy/redblooded
	name = "Red Blooded American"
	desc = "A bright red demon with oversized arms and greasy black hair. It is keeping its eyes focused on you."
	maxHealth = 1200
	health = 1200
	rapid_melee = 1
	melee_queue_distance = 2
	move_to_delay = 4
	melee_damage_type = RED_DAMAGE
	ranged = TRUE
	ranged_cooldown_time = 0.5 SECONDS
	casingtype = /obj/item/ammo_casing/caseless/rca_true_patriot
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1, PALE_DAMAGE = 2)
	melee_damage_lower = 15
	melee_damage_upper = 20
	original_abno = /mob/living/simple_animal/hostile/abnormality/redblooded

	var/ammo = 6
	var/max_ammo = 6
	var/reload_time = 2 SECONDS
	var/last_reload_time = 0
	var/bloodlust = 0 //more you do repression, more damage it deals. decreases on other works.

	abno_additional_instructions = "<h1>You are Red Blooded American, A Support Role Abnormality.</h1><br>\
		<b>|The American Way|: When you pick on a tile at least 2 sqrs away, You will consume 1 ammo to fire 6 pellets which deal 18 damage each.<br>\
		You passively reload 1 ammo every 2 seconds, but you can also reload 1 ammo by hitting humans or mechs.</b>"

	var/list/breach_quotes = list(
		"Time to wipe you freakshits out!",
		"HA! It's over for you freaks!",
		"You're outmatched! Just drop dead already!",
		"Eat shit, you fucking commies!",
		"This is going to be fun!",
	)

/mob/living/simple_animal/hostile/rcorp_abno/easy/redblooded/Initialize()
	. = ..()
	icon_state = "american_aggro"
	say(pick(breach_quotes))

/mob/living/simple_animal/hostile/rcorp_abno/easy/redblooded/proc/Reload()
	playsound(src, 'sound/weapons/gun/general/bolt_rack.ogg', 25, TRUE)
	to_chat(src, span_nicegreen("You reload your shotgun..."))
	ammo += 1

/mob/living/simple_animal/hostile/rcorp_abno/easy/redblooded/Life()
	. = ..()
	if (last_reload_time < world.time - reload_time)
		last_reload_time = world.time
		if (ammo < max_ammo)
			Reload()

/mob/living/simple_animal/hostile/rcorp_abno/easy/redblooded/AttackingTarget(atom/attacked_target)
	if(ammo < max_ammo)
		if(isliving(attacked_target))
			Reload()
		if(ismecha(attacked_target))
			Reload()
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/redblooded/MoveToTarget(list/possible_targets)
	if(ranged_cooldown <= world.time)
		OpenFire(target)
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/redblooded/OpenFire(atom/A)
	if(get_dist(src, A) >= 2)
		if(ammo <= 0)
			to_chat(src, span_warning("Out of ammo!"))
			return FALSE
		else
			ammo -= 1
			return ..()
	else
		return FALSE

/obj/item/ammo_casing/caseless/rca_true_patriot
	name = "true patriot casing"
	desc = "a true patriot casing"
	projectile_type = /obj/projectile/rcorp_true_patriot
	pellets = 6
	variance = 25

/obj/projectile/rca_true_patriot
	name = "american pellet"
	desc = "100% real, surplus military ammo."
	damage_type = RED_DAMAGE

	damage = 18
