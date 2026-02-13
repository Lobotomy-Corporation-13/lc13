/*
* Subtypes of stonk_company.dm
* These are the unique stock companies that can
* randomly apppear.
*/
/datum/stonk_company/rat
	name = "Velvets Shoppe"
	desc = "An upstart company formed from a group of \"reformed\" rats from the backstreets."
	product = "Scrap & Guts"

/datum/stonk_company/gpets
	name = "Georges Pets"
	desc = "\"My ARMY of PUPPERS only GROWS!\" -George <br>\
		A dog breeder."
	product = "Dogs"

/datum/stonk_company/framen
	name = "Fixers Ramen"
	desc = "\"Trained under the famous rank 4 chef, <br>\
		come for the best ramen in the district!\"<br> \
		A fixer themed ramen shop."
	product = "Ramen"

/datum/stonk_company/wrcheese
	name = "WeRCheese"
	desc = "\"We are the only source of true cheese.\"<br>\
		A cafe that sells figurines made of cheese."
	product = "Cheese Dolls"

/datum/stonk_company/dangels
	name = "Distilled Angels"
	desc = "\
		\"Always remember the Angels share.\"<br>\
		A store that sells hard drinks imported from K corp."
	product = "Hard Drink"

/datum/stonk_company/parsenal
	name = "Pam\'s Arsenal"
	desc = "\
		\"You get what you get.\" -Pam<br>\
		A major supplier of the districts Zwei gear."
	product = "Weapons & Armor"

/datum/stonk_company/wwell
	name = "Will\'s Wishing Well"
	desc = "\
		\"Ill be honest i dont know what is down there.\" -Well Will<br>\
		A gambling den slash pawn shop."
	product = "Lootboxes"

/datum/stonk_company/rfavilla
	name = "Rival Favilla"
	desc = "\"Rats are reduced to embers with Favilla!\"<br>\
		Rival weapon store to Pams Arsenal."
	product = "Weapons & Armor"

//Less Effort More Risk.
/datum/stonk_company/illigal
	min_performance = 0
	maxstock = 1500

/datum/stonk_company/illigal/Bankrupt()
	maxstock = rand(800,2000)
	return ..()

/datum/stonk_company/illigal/fdepot
	name = "Fairy Supply Depot"
	desc = "\
		\"Selling the lowest quality fumos in the city!\"<br>\
		Made taboo by 12 wings. Trading this stock is ill-advised."
	product = "Illegal Fumos"

/datum/stonk_company/illigal/shrimp
	name ="Shrimpcoin"
	desc = "\
		\"To the Moon!\"<br>\
		Likely a scam company. Sells \"cryptocurrency\", whatever that is."
	product = "Cryptocurrency"
	fluctuation_rate = 7
	market_value = 0.25
