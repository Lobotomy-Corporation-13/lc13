#define CAT_GADGET 1
#define CAT_EQUIP 2
#define CAT_MEDICAL 3
#define CAT_RESOURCE 4
#define CAT_OTHER 5
//CONSOLE CODE uses a altered form of mining_vendor


/obj/machinery/computer/extraction_cargo/records
	name = "records equipment console"
	icon_screen = "records_cargo"
	order_list = list(
		//Gadgets - Technical Equipment, active, that the Disc team could use.
		new /datum/data/extraction_cargo("Officer Upgrade Injector ",	/obj/item/trait_injector/officer_upgrade_injector,					400, CAT_GADGET) = 1,

		//Minor Equipment.
		new /datum/data/extraction_cargo("Super Power Cell ",			/obj/item/stock_parts/cell/super,									150, CAT_EQUIP) = 1,
		new /datum/data/extraction_cargo("Megaphone ",					/obj/item/megaphone,												150, CAT_EQUIP) = 1,
		new /datum/data/extraction_cargo("Binoculars ",					/obj/item/binoculars,												200, CAT_EQUIP) = 1,

		//Medical
		new /datum/data/extraction_cargo("Epinepherine Medi-Pen ",		/obj/item/reagent_containers/hypospray/medipen,						40, CAT_MEDICAL) = 1,
		new /datum/data/extraction_cargo("Sal-Acid Medi-Pen ",			/obj/item/reagent_containers/hypospray/medipen/salacid,				50, CAT_MEDICAL) = 1,
		new /datum/data/extraction_cargo("Mental-Stabilizer Medi-Pen ",	/obj/item/reagent_containers/hypospray/medipen/mental,				50, CAT_MEDICAL) = 1,

		//Resources - This is for upgrades to the station
		new /datum/data/extraction_cargo("Chemical Extraction Upgrade ",	/obj/item/work_console_upgrade/chemical_extraction_attachment,	120, CAT_RESOURCE) = 1,
		new /datum/data/extraction_cargo("Workchance Calculator Upgrade ",	/obj/item/work_console_upgrade/work_prediction_attachment,		200, CAT_RESOURCE) = 1,
		new /datum/data/extraction_cargo("Abnormality Work Radio ",			/obj/item/work_console_upgrade/radio,							200, CAT_RESOURCE) = 1,
		new /datum/data/extraction_cargo("Meltdown Indicator Upgrade ",		/obj/item/work_console_upgrade/work_meltdown_screen,			200, CAT_RESOURCE) = 1,
		new /datum/data/extraction_cargo("Agent Vitals Upgrade ",			/obj/item/work_console_upgrade/vitals,							200, CAT_RESOURCE) = 1,
		new /datum/data/extraction_cargo("Zayin Free Work Upgrade ",		/obj/item/work_console_upgrade/zayin_freework,					500, CAT_RESOURCE) = 1,

		//Random stuff
		new /datum/data/extraction_cargo("Spraycan ",					/obj/item/toy/crayon/spraycan,										40, CAT_OTHER) = 1,
		new /datum/data/extraction_cargo("Magic 8-Ball ",				/obj/item/toy/eightball,											70, CAT_OTHER) = 1,
		new /datum/data/extraction_cargo("Six-Pack ",					/obj/item/storage/cans,												70, CAT_OTHER) = 1,
		new /datum/data/extraction_cargo("Whiskey ",					/obj/item/reagent_containers/food/drinks/bottle/whiskey,			100, CAT_OTHER) = 1,
		new /datum/data/extraction_cargo("Absinthe ",					/obj/item/reagent_containers/food/drinks/bottle/absinthe/premium,	100, CAT_OTHER) = 1,
		new /datum/data/extraction_cargo("1000 Ahn ",					/obj/item/stack/spacecash/c1000,									200, CAT_OTHER) = 1,
		new /datum/data/extraction_cargo("Pet Whistle",					/obj/item/pet_whistle,												200, CAT_OTHER) = 1,
		new /datum/data/extraction_cargo("Margherita Pizza ",			/obj/item/food/pizza/margherita,									300, CAT_OTHER) = 1,
		new /datum/data/extraction_cargo("Super Gar Glasses ",			/obj/item/clothing/glasses/sunglasses/gar/supergar,					500, CAT_OTHER) = 1,


	)


#undef CAT_GADGET
#undef CAT_EQUIP
#undef CAT_MEDICAL
#undef CAT_RESOURCE
#undef CAT_OTHER
