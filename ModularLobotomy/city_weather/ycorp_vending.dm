// Y Corp Warmth Vending Machine
/obj/machinery/vending/ycorp_warmth
	name = "\improper Y Corp Thermal Equipment"
	desc = "A vending machine stocked with Y Corp's finest cold protection equipment."
	product_slogans = "Stay warm in the coldest storms!;Protection from the freezing winds!;Y Corp - Your warmth provider!"
	product_ads = "Don't let the cold stop you!;Thermal protection at its finest!;Winter is coming, be prepared!"
	icon_state = "robotics"
	color = "#ffaa66"
	products = list(
		// Base wintercoat
		/obj/item/clothing/suit/hooded/wintercoat = 10,

		// Department wintercoats from base game
		/obj/item/clothing/suit/hooded/wintercoat/captain = 2,
		/obj/item/clothing/suit/hooded/wintercoat/security = 5,
		/obj/item/clothing/suit/hooded/wintercoat/medical = 5,
		/obj/item/clothing/suit/hooded/wintercoat/science = 5,
		/obj/item/clothing/suit/hooded/wintercoat/engineering = 5,
		/obj/item/clothing/suit/hooded/wintercoat/hydro = 5,
		/obj/item/clothing/suit/hooded/wintercoat/cargo = 5,
		/obj/item/clothing/suit/hooded/wintercoat/miner = 5,

		// Head of staff wintercoats from ModularLobotomy
		/obj/item/clothing/suit/hooded/wintercoat/security/head = 1,
		/obj/item/clothing/suit/hooded/wintercoat/medical/head = 1,
		/obj/item/clothing/suit/hooded/wintercoat/science/head = 1,
		/obj/item/clothing/suit/hooded/wintercoat/engineering/head = 1,
		/obj/item/clothing/suit/hooded/wintercoat/captain/hop = 1,
		/obj/item/clothing/suit/hooded/wintercoat/cargo/head = 1,

		// Service department wintercoats
		/obj/item/clothing/suit/hooded/wintercoat/service/bartender = 3,
		/obj/item/clothing/suit/hooded/wintercoat/service/chap = 3,

		// Other department wintercoats
		/obj/item/clothing/suit/hooded/wintercoat/security/lawyer = 2,
		/obj/item/clothing/suit/hooded/wintercoat/medical/chem = 3,
		/obj/item/clothing/suit/hooded/wintercoat/medical/gen = 3,
		/obj/item/clothing/suit/hooded/wintercoat/med/para = 3,
		/obj/item/clothing/suit/hooded/wintercoat/sec/pris = 3,
	)

	premium = list(
		// Premium Y Corp items
		/obj/item/flashlight/lantern/ycorp = 5,
		/obj/item/ycorp_lantern_battery = 20,
	)

	default_price = 100
	extra_price = 500
	input_display_header = "Y Corp Thermal Equipment"
