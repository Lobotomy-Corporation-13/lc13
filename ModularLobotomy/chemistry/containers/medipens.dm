
/obj/item/reagent_containers/hypospray/medipen/l_health
	name = "L Corporation healing medipen"
	desc = "An autoinjector containing L-Corp healing gel, used to treat physical damage."
	icon_state = "lpenh"
	inhand_icon_state = "stimpen"
	list_reagents = list(/datum/reagent/abnormality/healing_gel = 10)

/obj/item/reagent_containers/hypospray/medipen/l_sanity
	name = "L Corporation mental stabilizer"
	desc = "An autoinjector containing L-Corp sanity concoction, used to treat mental damage."
	icon_state = "lpens"
	inhand_icon_state = "morphen"
	list_reagents = list(/datum/reagent/abnormality/sanity_gel = 10)

/obj/item/reagent_containers/hypospray/medipen/l_mixed
	name = "L Corporation mixed medipen"
	desc = "An autoinjector containing L-Corp mixed gel, used to treat mental and physical damage."
	icon_state = "lpenm"
	inhand_icon_state = "atropen"
	list_reagents = list(/datum/reagent/abnormality/mixed_gel = 10)

//The weird pens
/obj/item/reagent_containers/hypospray/medipen/l_burn
	name = "L Corporation burn salve medipen"
	desc = "An autoinjector containing L-Corp burn gel, used to treat burn damage."
	icon_state = "lpenb"
	inhand_icon_state = "oxapen"
	list_reagents = list(/datum/reagent/abnormality/burn_salve = 10)

/obj/item/reagent_containers/hypospray/medipen/antitoxin
	name = "Universal Anti-Toxin medipen"
	desc = "An autoinjector containing a standard run of the mill antitoxin."
	icon_state = "antitoxin"
	inhand_icon_state = "oxapen"
	list_reagents = list(/datum/reagent/antitoxin = 10)

//K-Corp pens
/obj/item/reagent_containers/hypospray/medipen/k_simple
	name = "K-Corporation Pharmaceutical-Grade Healing Medipen"
	desc = "An autoinjector containing a patented K-corporation medication. This is weaker than what's given in their \
			more standard injectors, not working instantly but over a short period of time."
	icon_state = "kpen"
	inhand_icon_state = "oxapen"
	list_reagents = list(/datum/reagent/abnormality/healing_fast = 10)

/obj/item/reagent_containers/hypospray/medipen/purgeall
	name = "K-Corp Purge-All medipen"
	desc = "An autoinjector containing medication to purge all chemicals."
	icon_state = "kpurge"
	inhand_icon_state = "oxapen"
	list_reagents = list(/datum/reagent/antitoxin = 10)
