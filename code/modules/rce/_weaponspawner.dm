//TODO:
//Refactor this. CBA right now - Kirie
/obj/effect/landmark/rcorp
	name = "rcorp requisitions"
	desc = "It spawns an item. Notify a coder. Thanks!"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x4"
	var/list/possible_items = list(
		/obj/item/gun/energy/e_gun/rabbitdash/sniper/iff,
		/obj/item/gun/energy/e_gun/rabbitdash/white/iff,
		/obj/item/gun/energy/e_gun/rabbitdash/black/iff,
	)


/obj/effect/landmark/rcorp/Initialize()
	. = ..()
	var/spawning = pick(possible_items)
	new spawning(get_turf(src))
	qdel(src)

/obj/effect/landmark/rcorp/midweapon
	possible_items = list(
		/obj/item/gun/energy/e_gun/rabbitdash/shotgun/iff,
		/obj/item/gun/energy/e_gun/rabbitdash/pale/iff,
		/obj/item/gun/energy/e_gun/rabbit/minigun/iff,
		/obj/item/gun/grenadelauncher,
	)

/obj/effect/landmark/rcorp/highweapon
	possible_items = list(
		/obj/item/gun/energy/e_gun/rabbitdash/shotgun/white/iff,
		/obj/item/gun/energy/e_gun/rabbitdash/shotgun/black/iff,
		/obj/item/gun/energy/e_gun/rabbitdash/heavy/iff,
		/obj/item/gun/energy/e_gun/rabbitdash/heavysniper, // Already IFF
		/obj/item/gun/energy/e_gun/rabbit/nopin/iff,
		/obj/item/gun/energy/e_gun/rabbit/minigun/tricolor, // Already IFF
		/obj/item/minigunpack,

	)


/obj/effect/landmark/rcorp/melee
	possible_items = list(
		/obj/item/ego_weapon/city/rabbit,
		/obj/item/ego_weapon/city/rabbit/white,
		/obj/item/ego_weapon/city/rabbit/black,
		/obj/item/ego_weapon/city/rabbit/pale,
		/obj/item/ego_weapon/city/rabbit_rush,
		/obj/item/ego_weapon/city/rabbit/throwing,
	)

/obj/effect/landmark/rcorp/pistol
	possible_items = list(
		/obj/item/gun/energy/e_gun/rabbitdash/small/iff,
		/obj/item/gun/energy/e_gun/rabbitdash/small/white/iff,
		/obj/item/gun/energy/e_gun/rabbitdash/small/black/iff,
		/obj/item/gun/energy/e_gun/rabbitdash/small/pale/iff,
		/obj/item/gun/energy/e_gun/rabbitdash/small/tinypale/iff,
	)

/obj/effect/landmark/rcorp/pistol2
	possible_items = list(
		/obj/item/gun/energy/e_gun/rabbitdash/small/smg/iff,
		/obj/item/gun/energy/e_gun/rabbitdash/small/smg/white/iff,
		/obj/item/gun/energy/e_gun/rabbitdash/small/smg/black/iff,
		/obj/item/gun/energy/e_gun/rabbitdash/small/pale/iff,
		/obj/item/gun/energy/e_gun/rabbitdash/small/tinypale/iff,
	)



/obj/effect/landmark/rcorp/grenade
	possible_items = list(
		/obj/item/grenade/r_corp,
		/obj/item/grenade/r_corp/white,
		/obj/item/grenade/r_corp/black,
		/obj/item/grenade/r_corp/pale,
	)


/obj/effect/landmark/rcorp/turret
	possible_items = list(
		/obj/machinery/manned_turret/rcorp,
		/obj/machinery/manned_turret/rcorp/red,
		/obj/machinery/manned_turret/rcorp/white,
		/obj/machinery/manned_turret/rcorp/black
	)

//Random Pouch
/obj/effect/landmark/rcorp/pouch
	possible_items = list(
		/obj/item/storage/pcorp_pocket/rcorp,
		/obj/item/storage/pcorp_weapon/rcorp,
		/obj/item/storage/rcorp_grenade,
		/obj/item/storage/material_pouch,

	)
