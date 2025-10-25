
/datum/filter_setting/
	var/name = "default setting"
	var/list/filter_typepath = list() // lets us set multi item filters if needs be, ie all grenades
	var/list/category = null
	// might be neat to shift these to a factory setting datum

/datum/filter_setting/proc/get_icon_path()
	var/obj/o = pick(filter_typepath)
	return o.icon

/datum/filter_setting/proc/get_icon_state()
	var/obj/o = pick(filter_typepath)
	return o.icon_state

/*
################### Materials
*/

/datum/filter_setting/material/
	category = "Materials"


/datum/filter_setting/material/green
	name = "Green Materials"
	filter_typepath = list(/obj/item/factoryitem/green)

/datum/filter_setting/material/red
	name = "Red Materials"
	filter_typepath = list(/obj/item/factoryitem/red)

/datum/filter_setting/material/blue
	name = "Blue Materials"
	filter_typepath = list(/obj/item/factoryitem/blue)

/datum/filter_setting/material/purple
	name = "Purple Materials"
	filter_typepath = list(/obj/item/factoryitem/purple)

/datum/filter_setting/material/orange
	name = "Orange Materials"
	filter_typepath = list(/obj/item/factoryitem/orange)

/datum/filter_setting/material/silver
	name = "Silver Materials"
	filter_typepath = list(/obj/item/factoryitem/silver)


/*
################### Low tier factory output
*/

/datum/filter_setting/low/
	category = "Low tier"


/datum/filter_setting/low/flare
	name = "Flares"
	filter_typepath = list(/obj/item/flashlight/flare)

/datum/filter_setting/low/pcorp_bread
	name = "P-Corp Bread"
	filter_typepath = list(/obj/item/food/canned/pcorp)

/datum/filter_setting/low/conveyor_belt
	name = "Conveyor Belt"
	filter_typepath = list(
		/obj/item/stack/conveyor,
		/obj/item/stack/conveyor/thirty
		)

/datum/filter_setting/low/emplacement_gun
	name = "Emplacement"
	filter_typepath = list(/obj/machinery/manned_turret/rcorp)

/datum/filter_setting/low/sandbag
	name = "Sandbags"
	filter_typepath = list(
		/obj/item/stack/sheet/mineral/sandbags/ten,
		/obj/item/stack/sheet/mineral/sandbags
		)

/datum/filter_setting/low/medipen
	name = "Medipens"
	filter_typepath = list(/obj/item/reagent_containers/hypospray/medipen/dual)

/datum/filter_setting/low/First_aid_l1
	name = "First Aid"
	filter_typepath = list(/obj/item/storage/First_aid_l1)

/datum/filter_setting/low/all_low_rifles
	name = "All Low Tier Weapons"
	filter_typepath = list(
		/obj/item/gun/energy/e_gun/rabbitdash/sniper,
		/obj/item/gun/energy/e_gun/rabbitdash/white,
		/obj/item/gun/energy/e_gun/rabbitdash/black
		)

/datum/filter_setting/low/rifle_sniper
	name = "R-Corporation X-12 Marksman"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/sniper)

/datum/filter_setting/low/rifle_white
	name = "R-Corporation R-2100 'White Rifle'"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/white)

/datum/filter_setting/low/rifle_black
	name = "R-Corporation R-2400 'Black Rifle'"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/black)

/datum/filter_setting/low/all_low_pistols
	name = "All Low Tier Pistols"
	filter_typepath = list(
		/obj/item/gun/energy/e_gun/rabbitdash/small,
		/obj/item/gun/energy/e_gun/rabbitdash/small/white,
		/obj/item/gun/energy/e_gun/rabbitdash/small/black,
		/obj/item/gun/energy/e_gun/rabbitdash/small/pale,
		/obj/item/gun/energy/e_gun/rabbitdash/small/tinypale,
	)

/datum/filter_setting/low/pistol_small
	name = "R-Corporation R-2020 'Little Iron' (Red)"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/small)

/datum/filter_setting/low/pistol_small_white
	name = "R-Corporation R-2120 'Disco Panic' (White)"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/small/white)

/datum/filter_setting/low/pistol_small_black
	name = "R-Corporation R-2420 'Night Operator' (Black)"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/small/black)

/datum/filter_setting/low/pistol_small_pale
	name = "R-Corporation R-2920 'Wakeup Call' (Pale)"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/small/pale)

/datum/filter_setting/low/pistol_small_tinypale
	name = "R-Corporation X-29 'Mistake'"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/small/tinypale)

/datum/filter_setting/low/all_low_melee
	name = "All Low Tier Melee"
	filter_typepath = list(
		/obj/item/ego_weapon/city/rabbit,
		/obj/item/ego_weapon/city/rabbit/white,
		/obj/item/ego_weapon/city/rabbit/black,
		/obj/item/ego_weapon/city/rabbit/pale,
		/obj/item/ego_weapon/city/rabbit_rush,
		/obj/item/ego_weapon/city/rabbit/throwing
	)

/datum/filter_setting/low/melee_red
	name = "R-1R R-Corp Blade"
	filter_typepath = list(/obj/item/ego_weapon/city/rabbit)

/datum/filter_setting/low/melee_white
	name = "R-1W R-Corp Blade"
	filter_typepath = list(/obj/item/ego_weapon/city/rabbit/white)

/datum/filter_setting/low/melee_black
	name = "R-1B R-Corp Blade"
	filter_typepath = list(/obj/item/ego_weapon/city/rabbit/black)

/datum/filter_setting/low/melee_pale
	name = "R-1P R-Corp Blade"
	filter_typepath = list(/obj/item/ego_weapon/city/rabbit/pale)

/datum/filter_setting/low/melee_rush
	name = "Rush Dagger"
	filter_typepath = list(/obj/item/ego_weapon/city/rabbit_rush)

/datum/filter_setting/low/melee_throwing
	name = "R-1T R-Corp Blade"
	filter_typepath = list(/obj/item/ego_weapon/city/rabbit/throwing)

/*
################### Medium tier factory output
*/

/datum/filter_setting/medium/
	category = "Medium tier"


/datum/filter_setting/medium/radio
	name = "Radio"
	filter_typepath = list(/obj/item/radio/headset)

/datum/filter_setting/medium/healthglasses
	name = "Health Glasses"
	filter_typepath = list(/obj/item/clothing/glasses/hud/health)

/datum/filter_setting/medium/pouches
	name = "All Misc Pouches"
	filter_typepath = list(
		/obj/item/storage/pcorp_pocket/rcorp,
		/obj/item/storage/pcorp_weapon/rcorp,
		/obj/item/storage/rcorp_grenade,
		/obj/item/storage/material_pouch
	)

/datum/filter_setting/medium/pouch_pocket
	name = "Pocket Pouch"
	filter_typepath = list(/obj/item/storage/pcorp_pocket/rcorp)

/datum/filter_setting/medium/pouch_weapon
	name = "Weapon Pouch"
	filter_typepath = list(/obj/item/storage/pcorp_weapon/rcorp)

/datum/filter_setting/medium/pouch_grenade
	name = "Grenade Pouch"
	filter_typepath = list(/obj/item/storage/rcorp_grenade)

/datum/filter_setting/medium/pouch_material
	name = "material Pouch"
	filter_typepath = list(/obj/item/storage/material_pouch)

/datum/filter_setting/medium/taser
	name = "Taser"
	filter_typepath = list(/obj/item/powered_gadget/handheld_taser)

/datum/filter_setting/medium/all_medium_rifles
	name = "All Mid Tier Rifles"
	filter_typepath = list(
		/obj/item/gun/energy/e_gun/rabbitdash/shotgun,
		/obj/item/gun/energy/e_gun/rabbitdash/pale,
		/obj/item/gun/energy/e_gun/rabbit/minigun,
		/obj/item/gun/grenadelauncher
	)

/datum/filter_setting/medium/shotgun
	name = "R-Corporation R-2300 'Chungid'"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/shotgun)

/datum/filter_setting/medium/rifle_pale
	name = "R-Corporation R-2900 'The Solution'"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/pale)

/datum/filter_setting/medium/minigun
	name = "R-Corporation X-15 Minigun"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbit/minigun)

/datum/filter_setting/medium/grenadelauncher
	name = "Grenade Launcher"
	filter_typepath = list(/obj/item/gun/grenadelauncher)

/datum/filter_setting/medium/all_grenades
	name = "All Grenades"
	filter_typepath = list(
		/obj/item/grenade/r_corp,
		/obj/item/grenade/r_corp/white,
		/obj/item/grenade/r_corp/black,
		/obj/item/grenade/r_corp/pale
	)

/datum/filter_setting/medium/grenade
	name = "Grenade (Red)"
	filter_typepath = list(/obj/item/grenade/r_corp)

/datum/filter_setting/medium/grenade_white
	name = "Grenade (White)"
	filter_typepath = list(/obj/item/grenade/r_corp/white)

/datum/filter_setting/medium/grenade_black
	name = "Grenade (Black)"
	filter_typepath = list(/obj/item/grenade/r_corp/black)

/datum/filter_setting/medium/grenade_pale
	name = "Grenade (Pale)"
	filter_typepath = list(/obj/item/grenade/r_corp/pale)

/datum/filter_setting/medium/rabbit_blade
	name = "Multiphase Blade"
	filter_typepath = list(/obj/item/ego_weapon/city/rabbit_blade)

/datum/filter_setting/medium/all_mid_pistols
	name = "All Mid Tier Pistols"
	filter_typepath = list(
		/obj/item/gun/energy/e_gun/rabbitdash/small/smg,
		/obj/item/gun/energy/e_gun/rabbitdash/small/smg/white,
		/obj/item/gun/energy/e_gun/rabbitdash/small/smg/black,
		/obj/item/gun/energy/e_gun/rabbitdash/small/pale,
		/obj/item/gun/energy/e_gun/rabbitdash/small/tinypale
	)

/datum/filter_setting/medium/pistol_smg_red
	name = "R-Corporation R-2540 'Hellspit'"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/small/smg)

/datum/filter_setting/medium/pistol_smg_white
	name = "R-Corporation R-2550 'Skid'"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/small/smg/white)

/datum/filter_setting/medium/pistol_smg_black
	name = "R-Corporation R-2560 'Dreamland'"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/small/smg/black)

/datum/filter_setting/medium/pistol_smg_pale
	name = "R-Corporation R-2950 'Icemilk Magic'"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/small/pale)

/datum/filter_setting/medium/pistol_smg_tinypale
	name = "R-Corporation X-29 'Mistake'"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/small/tinypale)

/datum/filter_setting/medium/First_aid_l2
	name = "First Aid L2 Pouch"
	filter_typepath = list(/obj/item/storage/First_aid_l2)

/datum/filter_setting/medium/stimpack
	name = "Stimulants"
	filter_typepath = list(/obj/item/reagent_containers/hypospray/medipen/stimpack)

/*
################### Medium tier factory output
*/

/datum/filter_setting/high/
	category = "High tier"


/datum/filter_setting/high/thermal
	name = "Thermals"
	filter_typepath = list(/obj/item/clothing/glasses/thermal)


/datum/filter_setting/high/night
	name = "NVG factory"
	filter_typepath = list(/obj/item/clothing/glasses/night)


/datum/filter_setting/high/slowingtrapmk1
	name = "Stun Trapper"
	filter_typepath = list(/obj/item/powered_gadget/slowingtrapmk1)


/datum/filter_setting/high/all_high_rifles
	name = "All High Tier Rifles"
	filter_typepath = list(
		/obj/item/gun/energy/e_gun/rabbitdash/shotgun/white,
		/obj/item/gun/energy/e_gun/rabbitdash/shotgun/black,
		/obj/item/gun/energy/e_gun/rabbitdash/heavy,
		/obj/item/gun/energy/e_gun/rabbitdash/heavysniper,
		/obj/item/gun/energy/e_gun/rabbit/nopin,
		/obj/item/gun/energy/e_gun/rabbit/minigun/tricolor,
		/obj/item/minigunpack
	)


/datum/filter_setting/high/shotgun_white
	name = "R-Corporation R-2330 'Fatty'"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/shotgun/white)

/datum/filter_setting/high/shotgun_black
	name = "R-Corporation R-2430 'Moz'"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/shotgun/black)

/datum/filter_setting/high/heavy_rifle
	name = "R-Corporation X-9 Heavy Rifle"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/heavy)

/datum/filter_setting/high/heavysniper
	name = "R-Corporation X-21 Sniper"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbitdash/heavysniper)

/datum/filter_setting/high/rifle_nopin
	name = "R-Corporation R-2800 'Mark 1'"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbit/nopin)

/datum/filter_setting/high/minigun_tricolor
	name = "R-Corporation R-3500 Minigun"
	filter_typepath = list(/obj/item/gun/energy/e_gun/rabbit/minigun/tricolor)

/datum/filter_setting/high/minigunpack
	name = "X-18 Heavy Minigun"
	filter_typepath = list(/obj/item/minigunpack)

/datum/filter_setting/high/rhinosmall
	name = "Superlight Rhino"
	filter_typepath = list(/obj/vehicle/sealed/mecha/combat/rhinosmall)

/*
################### Misc filters
*/


/datum/filter_setting/misc/
	category = "Misc items"

/datum/filter_setting/misc/person
	name = "People"
	filter_typepath = list(/mob/living/carbon/human)

/datum/filter_setting/misc/person/get_icon_state()
	return "human_basic"
