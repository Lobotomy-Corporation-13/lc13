
/obj/item/essence
	name = "bolus essence"
	desc = "You should not be seeing this!."
	icon = 'ModularLobotomy/_Lobotomyicons/bolus.dmi'
	icon_state = "essence"

/obj/item/essence/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/bolus))
		I.attackby(src, user, params)

/obj/item/essence/wood
	name = "wood essence"
	desc = "An essence of wood for bolus mixing"
	icon_state = "wood"

/obj/item/essence/fire
	name = "fire essence"
	desc = "An essence of fire for bolus mixing"
	icon_state = "fire"

/obj/item/essence/earth
	name = "earth essence"
	desc = "An essence of earth for bolus mixing"
	icon_state = "earth"

/obj/item/essence/metal
	name = "metal essence"
	desc = "An essence of metal for bolus mixing"
	icon_state = "metal"

/obj/item/essence/water
	name = "water essence"
	desc = "An essence of water for bolus mixing"
	icon_state = "water"
