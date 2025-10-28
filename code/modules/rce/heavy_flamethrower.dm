// Heavy Flamethrower System for RCE
// A powerful flamethrower that requires a fuel tank backpack to operate

// Fuel Tank Backpack
/obj/item/fuel_tank_backpack
	name = "heavy fuel tank"
	desc = "A large fuel tank designed to be worn on the back. Powers heavy flamethrower weapons."
	icon = 'icons/obj/tank.dmi'
	icon_state = "plasmaman_tank"
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	worn_icon = 'icons/mob/clothing/back.dmi'
	var/fuel_amount = 1000
	var/max_fuel = 1000
	var/obj/item/ego_weapon/ranged/heavy_flamethrower/linked_weapon

/obj/item/fuel_tank_backpack/examine(mob/user)
	. = ..()
	. += span_notice("Fuel: [fuel_amount]/[max_fuel]")
	if(fuel_amount < max_fuel)
		. += span_notice("It can be refilled at a fuel tank.")

/obj/item/fuel_tank_backpack/dropped(mob/user)
	. = ..()
	if(linked_weapon)
		to_chat(user, span_warning("The flamethrower's fuel line disconnects!"))
		linked_weapon.fuel_tank = null
		linked_weapon = null

/obj/item/fuel_tank_backpack/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/fuel_tank_backpack))
		var/obj/item/fuel_tank_backpack/other_tank = I
		if(other_tank.fuel_amount <= 0)
			to_chat(user, span_warning("[other_tank] is empty!"))
			return
		if(fuel_amount >= max_fuel)
			to_chat(user, span_warning("[src] is already full!"))
			return
		var/transfer_amount = min(other_tank.fuel_amount, max_fuel - fuel_amount)
		fuel_amount += transfer_amount
		other_tank.fuel_amount -= transfer_amount
		to_chat(user, span_notice("You transfer [transfer_amount] units of fuel from [other_tank] to [src]."))
		playsound(src, 'sound/effects/refill.ogg', 50, TRUE)
		return
	return ..()

/obj/item/fuel_tank_backpack/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!proximity)
		return

	// Refill from fuel dispensers
	if(istype(target, /obj/structure/reagent_dispensers/fueltank))
		if(fuel_amount >= max_fuel)
			to_chat(user, span_warning("[src] is already full!"))
			return
		var/obj/structure/reagent_dispensers/fueltank/F = target
		if(!F.reagents.has_reagent(/datum/reagent/fuel))
			to_chat(user, span_warning("[F] is out of fuel!"))
			return
		var/fuel_needed = max_fuel - fuel_amount
		var/fuel_available = F.reagents.get_reagent_amount(/datum/reagent/fuel)
		var/fuel_to_transfer = min(fuel_needed, fuel_available)
		F.reagents.remove_reagent(/datum/reagent/fuel, fuel_to_transfer)
		fuel_amount += fuel_to_transfer
		user.visible_message(span_notice("[user] refills [src] from [F]."), span_notice("You refill [src] from [F]."))
		playsound(src, 'sound/effects/refill.ogg', 50, TRUE)

// Heavy Flamethrower Weapon
/obj/item/ego_weapon/ranged/heavy_flamethrower
	name = "heavy flamethrower"
	desc = "An industrial-grade flamethrower that requires a fuel tank backpack to operate. Sprays burning fuel that ignites everything in its path."
	special = "Requires a fuel tank backpack to fire. Projectiles pierce through targets and have a chance to ignite the ground."
	icon = 'icons/obj/flamethrower.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/flamethrower_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/flamethrower_righthand.dmi'
	icon_state = "flamethrower1"
	inhand_icon_state = "flamethrower_1"
	projectile_path = /obj/projectile/ego_bullet/heavy_flame
	weapon_weight = WEAPON_HEAVY
	spread = 40
	fire_sound = 'sound/effects/burn.ogg'
	autofire = 0.08 SECONDS
	fire_sound_volume = 10
	var/fuel_per_shot = 5
	var/obj/item/fuel_tank_backpack/fuel_tank

/obj/item/ego_weapon/ranged/heavy_flamethrower/examine(mob/user)
	. = ..()
	if(fuel_tank)
		. += span_notice("Connected to fuel tank: [fuel_tank.fuel_amount]/[fuel_tank.max_fuel] fuel remaining.")
	else
		. += span_warning("No fuel tank connected! Use in-hand to connect to a worn fuel tank.")

/obj/item/ego_weapon/ranged/heavy_flamethrower/proc/connect_tank(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("You can't use this!"))
		return FALSE
	
	var/mob/living/carbon/human/H = user
	
	// Check if already connected
	if(fuel_tank)
		// Disconnect current tank
		fuel_tank.linked_weapon = null
		to_chat(user, span_notice("You disconnect [fuel_tank] from [src]."))
		fuel_tank = null
		return TRUE
	
	// Try to connect to worn tank
	var/obj/item/fuel_tank_backpack/tank = H.back
	if(!istype(tank))
		to_chat(user, span_warning("You need to wear a fuel tank backpack first!"))
		return FALSE
	
	if(tank.linked_weapon && tank.linked_weapon != src)
		to_chat(user, span_warning("[tank] is already connected to another weapon!"))
		return FALSE
	
	// Connect to tank
	fuel_tank = tank
	tank.linked_weapon = src
	to_chat(user, span_notice("You connect [src] to [tank]."))
	playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)
	return TRUE

/obj/item/ego_weapon/ranged/heavy_flamethrower/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HANDS)
		connect_tank(user)

/obj/item/ego_weapon/ranged/heavy_flamethrower/attack_self(mob/user)
	. = ..()
	connect_tank(user)

/obj/item/ego_weapon/ranged/heavy_flamethrower/dropped(mob/user)
	. = ..()
	if(fuel_tank)
		fuel_tank.linked_weapon = null
		to_chat(user, span_warning("The flamethrower's fuel line disconnects!"))
		fuel_tank = null

/obj/item/ego_weapon/ranged/heavy_flamethrower/can_shoot()
	if(!fuel_tank)
		return FALSE
	if(fuel_tank.fuel_amount < fuel_per_shot)
		return FALSE
	return TRUE

/obj/item/ego_weapon/ranged/heavy_flamethrower/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, temporary_damage_multiplier = 1)
	if(!can_shoot())
		if(!fuel_tank)
			to_chat(user, span_warning("You need to wear a fuel tank backpack!"))
		else
			to_chat(user, span_warning("The fuel tank is empty!"))
		return FALSE

	fuel_tank.fuel_amount -= fuel_per_shot
	return ..()

// Heavy Flame Projectile
/obj/projectile/ego_bullet/heavy_flame
	name = "heavy flames"
	icon_state = "flamethrower_fire"
	damage = 8
	damage_type = RED_DAMAGE
	speed = 1.5
	range = 7
	hitsound_wall = 'sound/weapons/tap.ogg'
	impact_effect_type = /obj/effect/temp_visual/impact_effect/red_laser
	projectile_piercing = PASSMOB
	var/fire_chance = 20

/obj/projectile/ego_bullet/heavy_flame/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isliving(target))
		var/mob/living/L = target
		L.apply_lc_burn(3)

/obj/projectile/ego_bullet/heavy_flame/Move(atom/newloc, dir = 0)
	. = ..()
	if(. && isturf(newloc))
		if(prob(fire_chance))
			var/turf/T = newloc
			if(!locate(/obj/effect/turf_fire) in T)
				new /obj/effect/turf_fire(T)
