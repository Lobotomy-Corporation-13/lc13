/obj/item/coin/casino_token
	name = "J-Corp Casino Token"
	desc = "From a closer look, you can see this is a token from the casino gift shops, not actual currency!"
	material_flags = MATERIAL_ADD_PREFIX | MATERIAL_COLOR

/obj/item/coin/casino_token/wood
	desc = "The cheapest kind of casino token. Maybe the wishing well might see this as a fitting sacrifice?"
	custom_materials = list(/datum/material/wood = 400)

/obj/item/coin/casino_token/iron
	desc = "The second cheapest kind of casino token. Throwing it in the wishing well is one option, but you can gamble more to get even better tokens."
	custom_materials = list(/datum/material/iron = 400)

/obj/item/coin/casino_token/silver
	desc = "This token is pretty valuable. Not only is it worth a lot of ahn, but also werewolves won't mug you!" //Awful joke
	custom_materials = list(/datum/material/silver = 400)

/obj/item/coin/casino_token/gold
	desc = "This token is a high value token. The wishing well will pay out with something good, but will you go higher for more riches?"
	custom_materials = list(/datum/material/gold = 400)

/obj/item/coin/casino_token/diamond
	desc = "This token is worth a lot of ahn in casinos! It is about the amount of money the average nest citizen makes in a month!"
	custom_materials = list(/datum/material/diamond = 400)

GLOBAL_LIST_EMPTY(possible_loot_jcorp)

/obj/item/a_gift/jcorp
	name = "J Corp Brand Lootbox"
	desc = "What could be inside of this?"
	icon_state = "jcorplootbox1" //Sprite by RayAleciana
	inhand_icon_state = "jcorplootbox"
	slot_flags = ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_SMALL

/obj/item/a_gift/jcorp/Initialize()
	. = ..()
	icon_state = "jcorplootbox[rand(1,3)]"

/obj/item/a_gift/jcorp/get_gift_type()
	if(!GLOB.possible_loot_jcorp.len)
		var/list/gift_types_list = list(
		/obj/item/toy/plush/blank,
		/obj/item/toy/plush/yisang,
		/obj/item/toy/plush/faust,
		/obj/item/toy/plush/don,
		/obj/item/toy/plush/ryoshu,
		/obj/item/toy/plush/meursault,
		/obj/item/toy/plush/honglu,
		/obj/item/toy/plush/heathcliff,
		/obj/item/toy/plush/ishmael,
		/obj/item/toy/plush/rodion,
		/obj/item/toy/plush/sinclair,
		/obj/item/toy/plush/outis,
		/obj/item/toy/plush/gregor,
		/obj/item/toy/plush/yuri,
		/obj/item/clothing/suit/armor/ego_gear/city/zweijunior,
		/obj/item/ego_weapon/city/zweihander,
		/obj/item/ego_weapon/city/zweihander/knife,
		/obj/item/ego_weapon/city/zweiwest,
		/obj/item/clothing/suit/armor/ego_gear/city/zwei,
		/obj/item/clothing/suit/armor/ego_gear/city/zweiriot,
		/obj/item/clothing/suit/armor/ego_gear/city/zweiwest,
		/obj/item/ego_weapon/city/zweibaton,
		/obj/item/ego_weapon/city/shi_assassin,
		/obj/item/ego_weapon/city/shi_knife,
		/obj/item/clothing/suit/armor/ego_gear/city/shi,
		/obj/item/clothing/suit/armor/ego_gear/city/shilimbus,
		/obj/item/ego_weapon/city/seven,
		/obj/item/ego_weapon/city/seven_fencing,
		/obj/item/ego_weapon/city/liu/fire,
		/obj/item/clothing/suit/armor/ego_gear/city/seven,
		/obj/item/clothing/suit/armor/ego_gear/city/sevenrecon,
		/obj/item/clothing/suit/armor/ego_gear/city/liu,
		/obj/item/clothing/suit/armor/ego_gear/city/liu/section5,
		/obj/item/ego_weapon/city/liu/fist,
		/obj/item/clothing/suit/armor/ego_gear/city/cinq,
		/obj/item/ego_weapon/city/cinq,
		/obj/item/clothing/suit/armor/ego_gear/city/devyat_suit/weak,
		/obj/item/ego_weapon/city/zweihander/vet,
		/obj/item/ego_weapon/city/zweiwest/vet,
		/obj/item/clothing/suit/armor/ego_gear/city/zweivet,
		/obj/item/clothing/suit/armor/ego_gear/city/zweiwestvet,
		/obj/item/ego_weapon/city/shi_assassin/sakura,
		/obj/item/ego_weapon/city/shi_assassin/serpent,
		/obj/item/ego_weapon/city/shi_assassin/vet,
		/obj/item/ego_weapon/city/shi_assassin/director,
		/obj/item/clothing/suit/armor/ego_gear/city/shi/vet,
		/obj/item/clothing/suit/armor/ego_gear/city/shilimbus/vet,
		/obj/item/ego_weapon/city/seven/vet,
		/obj/item/ego_weapon/city/seven_fencing/vet,
		/obj/item/clothing/suit/armor/ego_gear/city/sevenvet,
		/obj/item/clothing/suit/armor/ego_gear/city/sevenvet/intel,
		/obj/item/ego_weapon/city/liu/fire/fist,
		/obj/item/ego_weapon/city/liu/fire/spear,
		/obj/item/clothing/suit/armor/ego_gear/city/liuvet,
		/obj/item/clothing/suit/armor/ego_gear/city/liuvet/section2,
		/obj/item/clothing/suit/armor/ego_gear/city/liuvet/section5,
		/obj/item/ego_weapon/city/liu/fist/vet,
		/obj/item/ego_weapon/city/devyat_trunk,
		/obj/item/ego_weapon/city/devyat_trunk/demo,
		/obj/item/clothing/suit/armor/ego_gear/city/devyat_suit,
		/obj/item/ego_weapon/city/hana,
		/obj/item/clothing/suit/armor/ego_gear/city/hana,
		/obj/item/clothing/suit/armor/ego_gear/city/hanacombat,
		/obj/item/clothing/suit/armor/ego_gear/city/hanacombat/paperwork,
		/obj/item/clothing/suit/armor/ego_gear/city/hanadirector,
		/obj/item/clothing/suit/armor/ego_gear/city/zweijunior,
		/obj/item/ego_weapon/city/zweiwest,
		/obj/item/ego_weapon/city/zweihander,
		/obj/item/ego_weapon/city/zweihander/knife,
		/obj/item/clothing/suit/armor/ego_gear/city/zwei,
		/obj/item/clothing/suit/armor/ego_gear/city/zweiriot,
		/obj/item/clothing/suit/armor/ego_gear/city/zweiwest,
		/obj/item/ego_weapon/city/zweibaton,
		/obj/item/ego_weapon/city/zweiwest/vet,
		/obj/item/ego_weapon/city/zweihander/vet,
		/obj/item/clothing/suit/armor/ego_gear/city/zweiwestvet,
		/obj/item/clothing/suit/armor/ego_gear/city/zweiwestleader,
		/obj/item/clothing/suit/armor/ego_gear/city/zweivet,
		/obj/item/clothing/suit/armor/ego_gear/city/zweileader,
		/obj/item/ego_weapon/city/shi_assassin,
		/obj/item/ego_weapon/city/shi_knife,
		/obj/item/clothing/suit/armor/ego_gear/city/shi,
		/obj/item/clothing/suit/armor/ego_gear/city/shilimbus,
		/obj/item/ego_weapon/city/shi_assassin/yokai,
		/obj/item/ego_weapon/city/shi_assassin/sakura,
		/obj/item/ego_weapon/city/shi_assassin/serpent,
		/obj/item/ego_weapon/city/shi_assassin/vet,
		/obj/item/ego_weapon/city/shi_assassin/director,
		/obj/item/clothing/suit/armor/ego_gear/city/shi/vet,
		/obj/item/clothing/suit/armor/ego_gear/city/shi/director,
		/obj/item/clothing/suit/armor/ego_gear/city/shilimbus/vet,
		/obj/item/clothing/suit/armor/ego_gear/city/shilimbus/director,
		/obj/item/ego_weapon/city/shi_assassin,
		/obj/item/ego_weapon/city/shi_knife,
		/obj/item/clothing/suit/armor/ego_gear/city/shi,
		/obj/item/clothing/suit/armor/ego_gear/city/shilimbus,
		/obj/item/ego_weapon/city/shi_assassin/yokai,
		/obj/item/ego_weapon/city/shi_assassin/sakura,
		/obj/item/ego_weapon/city/shi_assassin/serpent,
		/obj/item/ego_weapon/city/shi_assassin/vet,
		/obj/item/ego_weapon/city/shi_assassin/director,
		/obj/item/clothing/suit/armor/ego_gear/city/shi/vet,
		/obj/item/clothing/suit/armor/ego_gear/city/shi/director,
		/obj/item/clothing/suit/armor/ego_gear/city/shilimbus/vet,
		/obj/item/clothing/suit/armor/ego_gear/city/shilimbus/director,
		/obj/item/clothing/suit/armor/ego_gear/city/liu,
		/obj/item/clothing/suit/armor/ego_gear/city/liu/section5,
		/obj/item/ego_weapon/city/liu/fire,
		/obj/item/ego_weapon/city/liu/fist,
		/obj/item/ego_weapon/city/liu/fist/vet,
		/obj/item/ego_weapon/city/liu/fire/fist,
		/obj/item/ego_weapon/city/liu/fire/spear,
		/obj/item/ego_weapon/city/liu/fire/sword,
		/obj/item/clothing/suit/armor/ego_gear/city/liuvet,
		/obj/item/clothing/suit/armor/ego_gear/city/liuvet/section2,
		/obj/item/clothing/suit/armor/ego_gear/city/liuvet/section4,
		/obj/item/clothing/suit/armor/ego_gear/city/liuvet/section5,
		/obj/item/clothing/suit/armor/ego_gear/city/liuleader,
		/obj/item/clothing/suit/armor/ego_gear/city/liuleader/section5,
		/obj/item/ego_weapon/city/seven,
		/obj/item/ego_weapon/city/seven_fencing,
		/obj/item/clothing/suit/armor/ego_gear/city/seven,
		/obj/item/clothing/suit/armor/ego_gear/city/sevenrecon,
		/obj/item/binoculars,
		/obj/item/ego_weapon/city/seven/vet,
		/obj/item/ego_weapon/city/seven_fencing/vet,
		/obj/item/clothing/suit/armor/ego_gear/city/sevenvet,
		/obj/item/clothing/suit/armor/ego_gear/city/sevenvet/intel,
		/obj/item/clothing/suit/armor/ego_gear/city/sevendirector,
		/obj/item/ego_weapon/city/seven/director,
		/obj/item/ego_weapon/city/seven/cane,
		/obj/item/ego_weapon/city/seven_fencing/dagger,
		/obj/item/powered_gadget/detector_gadget/abnormality,
		/obj/item/powered_gadget/slowingtrapmk1,
		/obj/item/clerkbot_gadget,
		/obj/item/powered_gadget/handheld_taser,
		/obj/item/forcefield_projector,
		/obj/item/reagent_containers/hypospray/emais,
		/obj/item/clothing/glasses/meson,
		/obj/item/powered_gadget/vitals_projector,
		/obj/item/powered_gadget/enkephalin_injector,
		/obj/item/powered_gadget/detector_gadget/ordeal,
		/obj/item/managerbullet,
		/obj/item/powered_gadget/teleporter,
		/obj/item/trait_injector/agent_workchance_trait_injector,
		/obj/item/trait_injector/clerk_fear_immunity_injector,
		/obj/item/trait_injector/officer_upgrade_injector,
		/obj/item/ego_gift_extractor,
		/obj/item/device/plushie_extractor,
		/obj/item/managerbullet,
		/obj/item/ksyringe,
		/obj/item/ego_weapon/city/kcorp,
		/obj/item/ego_weapon/shield/kcorp,
		/obj/item/ego_weapon/city/kcorp/axe,
		/obj/item/ego_weapon/ranged/pistol/kcorp,
		/obj/item/storage/box/kcorp_armor,
		/obj/item/ego_weapon/city/kcorp/spear,
		/obj/item/ego_weapon/city/kcorp/dspear,
		/obj/item/ego_weapon/ranged/pistol/kcorp/smg,
		/obj/item/ego_weapon/ranged/pistol/kcorp/nade,
		/obj/item/clothing/suit/armor/ego_gear/city/kcorp_l3,
		/obj/item/toy/plush/bongy,
		/obj/item/toy/plush/bongy,
		/obj/item/clothing/suit/armor/ego_gear/city/kcorp_sci,
		/obj/item/storage/box/ncorp_seals,
		/obj/item/storage/box/ncorp_seals/white,
		/obj/item/storage/box/ncorp_seals/black,
		/obj/item/ego_weapon/city/ncorp_nail,
		/obj/item/ego_weapon/city/ncorp_nail/big,
		/obj/item/ego_weapon/city/ncorp_brassnail,
		/obj/item/ego_weapon/city/ncorp_brassnail/big,
		/obj/item/ego_weapon/city/ncorp_hammer,
		/obj/item/ego_weapon/city/ncorp_hammer/big,
		/obj/item/clothing/suit/armor/ego_gear/city/ncorp,
		/obj/item/clothing/suit/armor/ego_gear/city/ncorp/vet,
		/obj/item/storage/box/ncorp_seals/pale,
		/obj/item/ego_weapon/city/ncorp_hammer/hand,
		/obj/item/ego_weapon/city/ncorp_hammer/grippy,
		/obj/item/ego_weapon/city/ncorp_nail/huge,
		/obj/item/ego_weapon/city/ncorp_nail/grip,
		/obj/item/ego_weapon/city/ncorp_brassnail/huge,
		/obj/item/ego_weapon/city/ncorp_brassnail/rose,
		/obj/item/clothing/suit/armor/ego_gear/city/grosshammmer,
		/obj/item/clothing/suit/armor/ego_gear/city/ncorpcommander,
		/obj/item/clothing/suit/space/hardsuit/rabbit,
		/obj/item/clothing/suit/space/hardsuit/rabbit/leader,
		/obj/item/gun/energy/e_gun/rabbitdash,
		/obj/item/ego_weapon/city/rabbit_rush,
		/obj/item/ego_weapon/city/rabbit_blade,
		/obj/item/ego_weapon/city/reindeer,
		/obj/item/gun/energy/e_gun/rabbitdash/sniper,
		/obj/item/gun/energy/e_gun/rabbitdash/laser,
		/obj/item/gun/energy/e_gun/rabbitdash/heavy,
		/obj/item/gun/energy/e_gun/rabbitdash/small,
		/obj/item/gun/energy/e_gun/rabbitdash/shotgun,
		/obj/item/ego_weapon/city/rabbit_blade/command,
		/obj/item/ego_weapon/city/reindeer/captain,
		/obj/item/gun/energy/e_gun/rabbit/minigun,
		/obj/item/gun/energy/e_gun/rabbit/nopin,
		/obj/item/clothing/under/suit/lobotomy/rabbit,
		/obj/item/toy/plush/myo,
		/obj/item/toy/plush/rabbit,
		/obj/item/clothing/under/suit/lobotomy/rcorp_command,
		/obj/item/clothing/head/beret/tegu/rcorp,
		/obj/item/clothing/neck/cloak/rcorp,
		/obj/item/powered_gadget/detector_gadget/ordeal,
		/obj/item/reagent_containers/food/drinks/soda_cans/wellcheers_red,
		/obj/item/reagent_containers/food/drinks/soda_cans/wellcheers_white,
		/obj/item/reagent_containers/food/drinks/soda_cans/wellcheers_purple,
		/obj/item/ego_weapon/ranged/sodashotty,
		/obj/item/ego_weapon/ranged/sodarifle,
		/obj/item/ego_weapon/ranged/sodasmg,
		/obj/item/ego_weapon/ranged/shrimp/assault,
		/obj/item/ego_weapon/ranged/shrimp/minigun,
		/obj/item/grenade/spawnergrenade/shrimp,
		/obj/item/trait_injector/shrimp_injector,
		/obj/item/grenade/spawnergrenade/shrimp/super,
		/obj/item/grenade/spawnergrenade/shrimp/hostile,
		/obj/item/reagent_containers/pill/shrimptoxin,
		/obj/item/fishing_rod/wellcheers,
		/mob/living/simple_animal/hostile/shrimp,
		/obj/item/ego_weapon/city/wcorp,
		/obj/item/clothing/suit/armor/ego_gear/wcorp,
		/obj/item/ego_weapon/city/wcorp/fist,
		/obj/item/ego_weapon/city/wcorp/axe,
		/obj/item/ego_weapon/city/wcorp/spear,
		/obj/item/ego_weapon/city/wcorp/dagger,
		/obj/item/ego_weapon/city/wcorp/hammer,
		/obj/item/ego_weapon/city/wcorp/hatchet,
		/obj/item/ego_weapon/city/wcorp/shield,
		/obj/item/ego_weapon/city/wcorp/shield/spear,
		/obj/item/ego_weapon/city/wcorp/shield/club,
		/obj/item/ego_weapon/city/wcorp/shield/axe,
		/obj/item/clothing/head/ego_hat/wcorp,
		/obj/item/clothing/under/suit/lobotomy/wcorp,
		/obj/item/powered_gadget/teleporter,
		/obj/item/ego_weapon/mini/hayong,
		/obj/item/ego_weapon/shield/walpurgisnacht,
		/obj/item/ego_weapon/lance/suenoimpossible,
		/obj/item/ego_weapon/shield/sangria,
		/obj/item/ego_weapon/mini/soleil,
		/obj/item/ego_weapon/mini/crow,
		/obj/item/ego_weapon/taixuhuanjing,
		/obj/item/ego_weapon/revenge,
		/obj/item/ego_weapon/shield/hearse,
		/obj/item/ego_weapon/mini/hearse,
		/obj/item/ego_weapon/raskolot,
		/obj/item/ego_weapon/vogel,
		/obj/item/ego_weapon/nobody,
		/obj/item/ego_weapon/ungezifer,
		/obj/item/clothing/suit/armor/ego_gear/limbus/limbus_coat,
		/obj/item/clothing/suit/armor/ego_gear/limbus/limbus_coat_short,
		/obj/item/clothing/suit/armor/ego_gear/limbus/durante,
		/obj/item/ego_weapon/lance/sangre,
		/obj/item/clothing/suit/armor/ego_gear/limbus/ego/minos,
		/obj/item/clothing/suit/armor/ego_gear/limbus/ego/cast,
		/obj/item/clothing/suit/armor/ego_gear/limbus/ego/branch,
		/obj/item/clothing/under/limbus/shirt,
		/obj/item/clothing/accessory/limbusvest,
		/obj/item/clothing/under/limbus/prison,
		/obj/item/clothing/neck/limbus_tie,
		/obj/item/stack/spacecash/c50,
		/obj/item/stack/spacecash/c100,
		/obj/item/stack/spacecash/c200,
		/obj/item/stack/spacecash/c500,
		/obj/item/clothing/suit/armor/ego_gear/city/blade_lineage_salsu,
		/obj/item/ego_weapon/ranged/city/thumb,
		/obj/item/clothing/suit/armor/ego_gear/city/thumb,
		/obj/item/clothing/suit/armor/ego_gear/city/index,
		/obj/item/clothing/suit/armor/ego_gear/city/blade_lineage_cutthroat,
		/obj/item/clothing/suit/armor/ego_gear/city/thumb_capo,
		/obj/item/clothing/suit/armor/ego_gear/index_proxy,
		/obj/item/ego_weapon/city/index,
		/obj/item/ego_weapon/city/awl,
		/obj/item/ego_weapon/city/kurokumo,
		/obj/item/ego_weapon/city/bladelineage,
		/obj/item/ego_weapon/ranged/city/thumb/capo,
		/obj/item/ego_weapon/city/thumbmelee,
		/obj/item/clothing/suit/armor/ego_gear/city/blade_lineage_admin,
		/obj/item/clothing/suit/armor/ego_gear/city/index_mess,
		/obj/item/clothing/suit/armor/ego_gear/city/thumb_sottocapo,
		/obj/item/ego_weapon/city/index/proxy,
		/obj/item/ego_weapon/city/index/proxy/spear,
		/obj/item/ego_weapon/city/index/yan,
		/obj/item/ego_weapon/ranged/city/thumb/sottocapo,
		/obj/item/ego_weapon/city/thumbcane,
		/obj/item/ego_weapon/city/rats,
		/obj/item/ego_weapon/city/rats/knife,
		/obj/item/ego_weapon/city/rats/scalpel,
		/obj/item/ego_weapon/city/rats/brick,
		/obj/item/ego_weapon/city/rats/pipe,
		/obj/item/ego_weapon/city/axegang,
		/obj/item/ego_weapon/city/sweeper,
		/obj/item/ego_weapon/city/axegang/leader,
		/obj/item/ego_weapon/city/district23,
		/obj/item/ego_weapon/city/district23/pierre,
		/obj/item/ego_weapon/city/sweeper/hooksword,
		/obj/item/ego_weapon/city/sweeper/sickle,
		/obj/item/ego_weapon/city/sweeper/claw,
		/obj/item/clothing/suit/armor/ego_gear/city/mariachi,
		/obj/item/clothing/suit/armor/ego_gear/city/mariachi/vivaz,
		/obj/item/ego_weapon/city/mariachi_blades,
		/obj/item/ego_weapon/city/ting_tang,
		/obj/item/ego_weapon/city/ting_tang/cleaver,
		/obj/item/ego_weapon/city/ting_tang/pipe,
		/obj/item/clothing/suit/armor/ego_gear/city/ting_tang,
		/obj/item/clothing/suit/armor/ego_gear/city/ting_tang/puffer,
		/obj/item/clothing/suit/armor/ego_gear/city/ting_tang/rustic,
		/obj/item/clothing/suit/armor/ego_gear/city/ting_tang/boss,
		/obj/item/ego_weapon/city/ting_tang/knife,
		/obj/item/clothing/suit/armor/ego_gear/city/mariachi/aida,
		/obj/item/ego_weapon/city/mariachi,
		/obj/item/ego_weapon/city/mariachi/dual,
		/obj/item/clothing/suit/armor/ego_gear/city/mariachi/aida/boss,
		/obj/item/ego_weapon/city/mariachi/dual/boss,
		/obj/item/ego_weapon/city/yun,
		/obj/item/ego_weapon/city/yun/shortsword,
		/obj/item/ego_weapon/city/yun/chainsaw,
		/obj/item/ego_weapon/city/yun/fist,
		/obj/item/ego_weapon/city/zweihander/streetlight_baton,
		/obj/item/ego_weapon/city/streetlight_bat,
		/obj/item/ego_weapon/city/streetlight_greatsword,
		/obj/item/ego_weapon/city/leaflet/round,
		/obj/item/ego_weapon/city/leaflet/wide,
		/obj/item/ego_weapon/city/cane/cane,
		/obj/item/ego_weapon/city/cane/claw,
		/obj/item/ego_weapon/city/cane/briefcase,
		/obj/item/ego_weapon/city/cane/fist,
		/obj/item/ego_weapon/city/leaflet/square,
		/obj/item/clothing/suit/armor/ego_gear/city/mirae,
		/obj/item/ego_weapon/city/donghwan,
		/obj/item/ego_weapon/city/mirae,
		/obj/item/ego_weapon/city/mirae/page,
		/obj/item/clothing/suit/armor/ego_gear/city/udjat,
		/obj/item/ego_weapon/city/fixerblade,
		/obj/item/ego_weapon/city/fixergreatsword,
		/obj/item/ego_weapon/city/fixerhammer,
		/obj/item/ego_weapon/city/jeong,
		/obj/item/ego_weapon/city/jeong/large,
		/obj/item/ego_weapon/city/molar,
		/obj/item/ego_weapon/city/molar/olga,
		/obj/item/clothing/suit/armor/ego_gear/city/blue_reverb,
		/obj/item/ego_weapon/black_silence_gloves,
		/obj/item/ego_weapon/city/vermillion,
		/obj/item/ego_weapon/mimicry/kali,
		/obj/item/ego_weapon/city/reverberation,
		/obj/item/ego_weapon/city/pt/slash,
		/obj/item/ego_weapon/city/dawn/sword,
		/obj/item/ego_weapon/city/dawn/cello,
		/obj/item/ego_weapon/city/wedge,
		/obj/item/ego_weapon/ranged/city/fullstop/assault,
		/obj/item/ego_weapon/ranged/city/fullstop/sniper,
		/obj/item/ego_weapon/ranged/city/fullstop/pistol,
		/obj/item/clothing/suit/armor/ego_gear/city/fullstop,
		/obj/item/clothing/suit/armor/ego_gear/city/fullstop/sniper,
		/obj/item/clothing/suit/armor/ego_gear/city/wedge,
		/obj/item/clothing/suit/armor/ego_gear/city/wedge/female,
		/obj/item/clothing/suit/armor/ego_gear/city/dawn,
		/obj/item/clothing/suit/armor/ego_gear/city/dawn/vet,
		/obj/item/clothing/suit/armor/ego_gear/city/dawn/female,
		/obj/item/ego_weapon/city/dawn/zwei,
		/obj/item/ego_weapon/ranged/city/fullstop/deagle,
		/obj/item/clothing/suit/armor/ego_gear/city/dawnleader,
		/obj/item/clothing/suit/armor/ego_gear/city/wedgeleader,
		/obj/item/clothing/suit/armor/ego_gear/city/fullstopleader,
		/obj/item/storage/box/rosespanner,
		/obj/item/storage/box/rosespanner/white,
		/obj/item/storage/box/rosespanner/black,
		/obj/item/ego_weapon/city/rosespanner/hammer,
		/obj/item/ego_weapon/city/rosespanner/spear,
		/obj/item/ego_weapon/city/rosespanner/minihammer,
		/obj/item/clothing/suit/armor/ego_gear/city/rosespannerrep,
		/obj/item/clothing/suit/armor/ego_gear/city/rosespanner,
		/obj/item/storage/box/rosespanner/pale,
		)
		for(var/V in gift_types_list)
			var/obj/item/I = V
			if((!initial(I.icon_state)) || (!initial(I.inhand_icon_state)) || (initial(I.item_flags) & (ABSTRACT | DROPDEL)))
				gift_types_list -= V
		GLOB.possible_loot_jcorp = gift_types_list
	var/gift_type = pick(GLOB.possible_loot_jcorp)
	return gift_type

// Slot Machines

/obj/machinery/jcorp_slot_machine
	name = "J Corp Slot Machine"
	desc = "Just put in your casino token to gamble!"
	icon = 'icons/obj/economy.dmi'
	icon_state = "slots1"
	anchored = FALSE
	max_integrity = 2000
	density = TRUE
	use_power = 0

/obj/machinery/jcorp_slot_machine/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/coin/casino_token))
		if(!do_after(user, 2 SECONDS, src))
			return
		if(istype(I, /obj/item/coin/casino_token/diamond))
			process_gamble(5)
		else if(istype(I, /obj/item/coin/casino_token/gold))
			process_gamble(4)
		else if(istype(I, /obj/item/coin/casino_token/silver))
			process_gamble(3)
		else if(istype(I, /obj/item/coin/casino_token/iron))
			process_gamble(2)
		else if(istype(I, /obj/item/coin/casino_token/wood))
			process_gamble(1)
		else
			to_chat(user, span_userdanger("Wait a minute.... This isn't a legit token!"))
			return
		qdel(I)
	else
		return ..()

/obj/machinery/jcorp_slot_machine/proc/process_gamble(var/token_value)
	var/result = rand(20)
	var/final_value = 0
	if(result <= 9)
		final_value = 0
		visible_message(span_notice("The machine buzzes as nothing comes out"))
	else if(result == 10)
		final_value = token_value - 1
		visible_message(span_notice("The machine buzzes as a less valuable token comes out."))
	else if(result <= 19)
		final_value = token_value
		visible_message(span_notice("The machine chimes as twice as many tokens come out"))
		print_prize(final_value)
	else
		final_value = token_value + 1
		if(final_value == 6)
			visible_message(span_notice("The machine chimes as twice as many tokens come out"))
			print_prize(final_value)
		else
			visible_message(span_notice("The machine makes all kind of noises as a more valuable token comes out!"))
	if(final_value > 0)
		print_prize(final_value)

/obj/machinery/jcorp_slot_machine/proc/print_prize(var/token_value)
	switch(token_value)
		if(1)
			new /obj/item/coin/casino_token/wood(get_turf(src))
		if(2)
			new /obj/item/coin/casino_token/iron(get_turf(src))
		if(3)
			new /obj/item/coin/casino_token/silver(get_turf(src))
		if(4)
			new /obj/item/coin/casino_token/gold(get_turf(src))
		if(5 to INFINITY) //Shouldn't be possible to get higher than six but might as well put a failsafe
			new /obj/item/coin/casino_token/diamond(get_turf(src))

/obj/item/blood_slots
	name = "J Corp Blood Slots"
	desc = "A peculiar device sold by J Corp that uses health as currency for gambling! It can give a variety of prizes!"
	icon = 'icons/obj/syringe.dmi'
	icon_state = "sampler"
	slot_flags = ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_SMALL
	var/cooldown_timer = 2 SECONDS
	var/cooldown

/obj/item/blood_slots/Initialize()
	. = ..()
	cooldown = world.time

/obj/item/blood_slots/attack_self(mob/living/user)
	..()
	if(cooldown <= world.time)
		to_chat(user, span_notice("You feel the injector jab into you!"))
		user.adjustBruteLoss(50)
		var/result = rand(1,100)
		switch(result)
			if(1 to 55)
				to_chat(user, span_notice("The machine buzzes."))
			if(56 to 90)
				to_chat(user, span_notice("The machine gives off a healing pulse."))
				user.adjustBruteLoss(-100)
				new /obj/effect/temp_visual/heal(get_turf(user), "#FF4444")
				for(var/mob/living/carbon/human/H in view(4, get_turf(src)))
					if(H.stat >= HARD_CRIT)
						continue
					H.adjustBruteLoss(-100)
					new /obj/effect/temp_visual/heal(get_turf(H), "#FF4444")
			if(90 to 99)
				to_chat(user, span_notice("The machine dispenses a token!"))
				new /obj/item/coin/casino_token/iron(get_turf(src))
			if(100)
				to_chat(user, span_notice("The machine dispenses a token!"))
				new /obj/item/coin/casino_token/silver(get_turf(src))
		cooldown = world.time + cooldown_timer




// J Corp ERT Gear (We can move this code in case somebody adds some of the gear to gacha)
