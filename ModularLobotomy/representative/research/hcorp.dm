//-----H_CORP-----
//H Corp makes unique boluses.
/datum/data/lc13research/hcorparmor
	research_name = "H-Corp Armored Bolus Recipe"
	research_desc = "A bolus that is designed to give the user better armor."
	cost = AVERAGE_RESEARCH_PRICE
	corp = H_CORP_REP

/datum/data/lc13research/hcorparmor/ResearchEffect(obj/structure/representative_console/requester)
	ItemUnlock(requester.order_list, "Armor Bolus Recipe",	/obj/item/bolus/armor, 40)
	..()

/datum/data/lc13research/hcorpflower
	research_name = "H-Corp Flower Bolus Recipe"
	research_desc = "A bolus that is designed to be spread to give the user AOE abilities."
	cost = AVERAGE_RESEARCH_PRICE
	corp = H_CORP_REP

/datum/data/lc13research/hcorpflower/ResearchEffect(obj/structure/representative_console/requester)
	ItemUnlock(requester.order_list, "Flower Bolus Recipe",	/obj/item/bolus/flower, 50)
	..()

/datum/data/lc13research/hcorpcharred
	research_name = "H-Corp Charred Bolus Recipe"
	research_desc = "A bolus that is designed to give the user much better offenses."
	cost = AVERAGE_RESEARCH_PRICE
	corp = H_CORP_REP

/datum/data/lc13research/hcorpcharred/ResearchEffect(obj/structure/representative_console/requester)
	ItemUnlock(requester.order_list, "Charred Bolus Recipe",	/obj/item/bolus/charred, 50)
	..()

/datum/data/lc13research/hcorpsoaked
	research_name = "H-Corp Soaked Bolus Recipe"
	research_desc = "A bolus that is designed to give the user much better SP healing."
	cost = AVERAGE_RESEARCH_PRICE
	corp = H_CORP_REP

/datum/data/lc13research/hcorpsoaked/ResearchEffect(obj/structure/representative_console/requester)
	ItemUnlock(requester.order_list, "Soaked Bolus Recipe",	/obj/item/bolus/soaked, 50)
	..()

/datum/data/lc13research/hcorpmossy
	research_name = "H-Corp Mossy Bolus Recipe"
	research_desc = "A bolus that is designed to give the user better HP Healing."
	cost = AVERAGE_RESEARCH_PRICE
	corp = H_CORP_REP

/datum/data/lc13research/hcorpmossy/ResearchEffect(obj/structure/representative_console/requester)
	ItemUnlock(requester.order_list, "Mossy Bolus Recipe",	/obj/item/bolus/mossy, 50)
	..()

/datum/data/lc13research/hcorprust
	research_name = "H-Corp Rust Bolus Recipe"
	research_desc = "A bolus that is designed to give the user much better temporary armor."
	cost = AVERAGE_RESEARCH_PRICE
	corp = H_CORP_REP

/datum/data/lc13research/hcorprust/ResearchEffect(obj/structure/representative_console/requester)
	ItemUnlock(requester.order_list, "Rust Bolus Recipe",	/obj/item/bolus/rust, 50)
	..()

/datum/data/lc13research/hcorpclay
	research_name = "H-Corp Clay Bolus Recipe"
	research_desc = "A bolus that is designed to give the user temporary movespeed."
	cost = AVERAGE_RESEARCH_PRICE
	corp = H_CORP_REP

/datum/data/lc13research/hcorpclay/ResearchEffect(obj/structure/representative_console/requester)
	ItemUnlock(requester.order_list, "Clay Bolus Recipe",	/obj/item/bolus/clay, 50)
	..()

/datum/data/lc13research/hcorppoison
	research_name = "H-Corp Poison Bolus Recipe"
	research_desc = "A bolus base that poisons the user. We have no idea WHY you'd want this, but you can have it nonetheless."
	cost = AVERAGE_RESEARCH_PRICE
	corp = H_CORP_REP

/datum/data/lc13research/hcorppoison/ResearchEffect(obj/structure/representative_console/requester)
	ItemUnlock(requester.order_list, "Poison Bolus Recipe",	/obj/item/bolus/poison, 70)
	..()

/datum/data/lc13research/hcorpodd
	research_name = "H-Corp Odd Bolus Recipe"
	research_desc = "A bolus base that can be used for a few features. Not terribly popular."
	cost = AVERAGE_RESEARCH_PRICE
	corp = H_CORP_REP

/datum/data/lc13research/hcorpodd/ResearchEffect(obj/structure/representative_console/requester)
	ItemUnlock(requester.order_list, "Odd Bolus Recipe",	/obj/item/bolus/odd, 80)
	..()

/datum/data/lc13research/hcorppale
	research_name = "H-Corp Pale Bolus Recipe"
	research_desc = "A bolus that has no specific use."
	cost = AVERAGE_RESEARCH_PRICE
	corp = H_CORP_REP

/datum/data/lc13research/hcorppale/ResearchEffect(obj/structure/representative_console/requester)
	ItemUnlock(requester.order_list, "Pale Bolus Recipe",	/obj/item/bolus/pale, 100)
	..()
