
/obj/item/storage/box/hcorpfire
	name = "Fire Essence Package"

/obj/item/storage/box/hcorpfire/PopulateContents()
	for(var/i = 1 to 10)
		new /obj/item/essence/fire(src)


/obj/item/storage/box/hcorpwater
	name = "Water Essence Package"

/obj/item/storage/box/hcorpwater/PopulateContents()
	for(var/i = 1 to 10)
		new /obj/item/essence/water(src)


/obj/item/storage/box/hcorpearth
	name = "Earth Essence Package"

/obj/item/storage/box/hcorpearth/PopulateContents()
	for(var/i = 1 to 10)
		new /obj/item/essence/earth(src)


/obj/item/storage/box/hcorpmetal
	name = "Metal Essence Package"

/obj/item/storage/box/hcorpmetal/PopulateContents()
	for(var/i = 1 to 10)
		new /obj/item/essence/metal(src)


/obj/item/storage/box/hcorpwood
	name = "Wood Essence Package"

/obj/item/storage/box/hcorpwood/PopulateContents()
	for(var/i = 1 to 10)
		new /obj/item/essence/wood(src)


/obj/item/storage/box/hcorpvariety
	name = "Variety Essence Package"

/obj/item/storage/box/hcorpvariety/PopulateContents()
	new /obj/item/essence/wood(src)
	new /obj/item/essence/wood(src)
	new /obj/item/essence/fire(src)
	new /obj/item/essence/fire(src)
	new /obj/item/essence/water(src)
	new /obj/item/essence/water(src)
	new /obj/item/essence/earth(src)
	new /obj/item/essence/earth(src)
	new /obj/item/essence/metal(src)
	new /obj/item/essence/metal(src)
