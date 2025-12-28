//All the records for this gamemodes goes into one filing cabinet
/obj/structure/filingcabinet/mining
	name = "abnormality information cabinet"
	icon_state = "chestdrawer"
	var/virgin = TRUE

/obj/structure/filingcabinet/mining/proc/fillCurrent()
	var/list/queue = subtypesof(/obj/item/paper/fluff/info/mining)
	for(var/sheet in queue)
		new sheet(src)

/obj/structure/filingcabinet/mining/interact(mob/user)
	if(virgin)
		fillCurrent()
		virgin = FALSE
	return ..()

//Heh. All of these are from Branch 13 get it? Like SS13?
//  ------------TETH------------
//Ice Whelp
/obj/item/paper/fluff/info/mining/whelp
	abno_type = /mob/living/simple_animal/hostile/abnormality/mining/ice_whelp
	abno_code = "S-02-13-03"
	abno_info = list(
		"When the work result was Normal, the Qliphoth Counter lowered.",
	)


//	-------------HE-------------
// Herald
/obj/item/paper/fluff/info/mining/herald
	abno_type = /mob/living/simple_animal/hostile/abnormality/mining/herald
	abno_code = "S-06-13-05"	//S for "Space" because "M" is for "Myth"
	abno_info = list(
		"When the work result was Normal, the Qliphoth Counter lowered with a normal probability.",
		"When the work result was Bad, the Qliphoth Counter lowered with a high probability.",
	)

//Legionnaire
/obj/item/paper/fluff/info/mining/legionnaire
	abno_type = /mob/living/simple_animal/hostile/abnormality/mining/legionnaire
	abno_code = "S-01-13-06"
	abno_info = list(
		"When the work result was Normal, the Qliphoth Counter lowered with a normal probability.",
		"When the work result was Bad, the Qliphoth Counter lowered with a high probability.",
	)

//Pandora
/obj/item/paper/fluff/info/mining/pandora
	abno_type = /mob/living/simple_animal/hostile/abnormality/mining/pandora
	abno_code = "S-06-13-02"
	abno_info = list(
		"When the work result was Normal, the Qliphoth Counter lowered with a normal probability.",
		"When the work result was Bad, the Qliphoth Counter lowered with a high probability.",
	)
