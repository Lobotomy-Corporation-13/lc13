// Pathstrider progression materials.
// Stackable resources spent on ascensions and traces. Two kinds:
// Path Material (sin-tied, one family per path) and Trace Material
// (four ordeal-sourced families). Three rarities each (T1 = 2-star,
// T2 = 3-star, T3 = 4-star). Icons use path_resources_small.dmi.

// Shared material registry: maps (category, family key, tier) to the stack
// type and a cached icon. Built once, shared by the Path Screen and anything
// else that needs to look up a material by its family/tier.
GLOBAL_LIST_EMPTY(path_mat_types)
GLOBAL_LIST_EMPTY(path_mat_icons)
GLOBAL_LIST_EMPTY(path_mat_names)

/proc/BuildPathMatRegistry()
	if(length(GLOB.path_mat_types))
		return
	var/list/defs = list(
		list("path", PATH_KEY_DESTRUCTION,  /obj/item/stack/path_material/wrath),
		list("path", PATH_KEY_HUNT,         /obj/item/stack/path_material/envy),
		list("path", PATH_KEY_ERUDITION,    /obj/item/stack/path_material/pride),
		list("path", PATH_KEY_NIHILITY,     /obj/item/stack/path_material/gloom),
		list("path", PATH_KEY_HARMONY,      /obj/item/stack/path_material/lust),
		list("path", PATH_KEY_PRESERVATION, /obj/item/stack/path_material/sloth),
		list("path", PATH_KEY_ABUNDANCE,    /obj/item/stack/path_material/gluttony),
		list("trace", TRACE_FAMILY_FANG,    /obj/item/stack/trace_material/fang),
		list("trace", TRACE_FAMILY_LENS,    /obj/item/stack/trace_material/lens),
		list("trace", TRACE_FAMILY_ICHOR,   /obj/item/stack/trace_material/ichor),
		list("trace", TRACE_FAMILY_WARD,    /obj/item/stack/trace_material/ward),
	)
	for(var/list/d in defs)
		var/cat = d[1]
		var/key = d[2]
		var/base = d[3]
		var/list/tiers = list(base, text2path("[base]/t2"), text2path("[base]/t3"))
		for(var/i in 1 to 3)
			var/mt = tiers[i]
			GLOB.path_mat_types["[cat]|[key]|[i]"] = mt
			var/obj/item/stack/inst = new mt()
			GLOB.path_mat_icons["[cat]|[key]|[i]"] = icon2base64(icon(inst.icon, inst.icon_state))
			GLOB.path_mat_names["[cat]|[key]|[i]"] = inst.name
			qdel(inst)

/// Returns the stack type for a (category, family key, tier), or null.
/proc/GetPathMatType(cat, key, tier)
	BuildPathMatRegistry()
	return GLOB.path_mat_types["[cat]|[key]|[tier]"]

/// Returns the cached base64 icon for a (category, family key, tier).
/proc/GetPathMatIcon(cat, key, tier)
	BuildPathMatRegistry()
	return GLOB.path_mat_icons["[cat]|[key]|[tier]"]

/// Returns the display name for a (category, family key, tier).
/proc/GetPathMatName(cat, key, tier)
	BuildPathMatRegistry()
	return GLOB.path_mat_names["[cat]|[key]|[tier]"]

// Path Material (main, sin-tied)

/// Base path material. One family per path, three rarity tiers.
/// Spent on ascensions (any tier) and traces (with Trace Material).
/obj/item/stack/path_material
	name = "path material"
	singular_name = "path material"
	desc = "Crystallized sin drawn from an abnormality."
	icon = 'ModularLobotomy/_Lobotomyicons/path_resources_small.dmi'
	icon_state = "mat_wrath"
	w_class = WEIGHT_CLASS_SMALL
	max_amount = 99
	novariants = TRUE
	merge_type = /obj/item/stack/path_material
	/// Which path this feeds, one of PATH_KEY_*.
	var/path_key = PATH_KEY_DESTRUCTION
	/// Rarity tier: PATH_MAT_T1 / T2 / T3.
	var/tier = PATH_MAT_T1

/// Stacks merge across a whole subtree, not just an exact type, and the higher
/// tiers are declared as subtypes of the tier-1 entry. That let a T2 or T3
/// stack fold into a T1 one and be spent at the lower rate. Materials merge
/// only with their own exact type.
/obj/item/stack/path_material/can_merge(obj/item/stack/check)
	if(check.type != type)
		return FALSE
	return ..()

/obj/item/stack/path_material/examine(mob/user)
	. = ..()
	. += span_notice("Rarity: [tier + 1]-star (Tier [tier]) path material.")
	. += span_notice("Spent on ascensions and traces for the Path of [uppertext(copytext(path_key, 1, 2))][copytext(path_key, 2)].")

// Wrath / Destruction

/obj/item/stack/path_material/wrath
	name = "ashen cinder"
	singular_name = "ashen cinder"
	desc = "A cinder of crystallized wrath, wrenched from an abnormality. Feeds the Path of Destruction."
	icon_state = "mat_wrath"
	path_key = PATH_KEY_DESTRUCTION
	tier = PATH_MAT_T1
	merge_type = /obj/item/stack/path_material/wrath

/obj/item/stack/path_material/wrath/t2
	name = "ember"
	singular_name = "ember"
	icon_state = "mat_wrath_2"
	tier = PATH_MAT_T2
	merge_type = /obj/item/stack/path_material/wrath/t2

/obj/item/stack/path_material/wrath/t3
	name = "pyre"
	singular_name = "pyre"
	icon_state = "mat_wrath_3"
	tier = PATH_MAT_T3
	merge_type = /obj/item/stack/path_material/wrath/t3

// Envy / The Hunt

/obj/item/stack/path_material/envy
	name = "keen fang"
	singular_name = "keen fang"
	desc = "A shard of sharpened envy, taken from an abnormality. Feeds the Path of the Hunt."
	icon_state = "mat_envy"
	path_key = PATH_KEY_HUNT
	tier = PATH_MAT_T1
	merge_type = /obj/item/stack/path_material/envy

/obj/item/stack/path_material/envy/t2
	name = "talon"
	singular_name = "talon"
	icon_state = "mat_envy_2"
	tier = PATH_MAT_T2
	merge_type = /obj/item/stack/path_material/envy/t2

/obj/item/stack/path_material/envy/t3
	name = "apex fang"
	singular_name = "apex fang"
	icon_state = "mat_envy_3"
	tier = PATH_MAT_T3
	merge_type = /obj/item/stack/path_material/envy/t3

// Pride / Erudition

/obj/item/stack/path_material/pride
	name = "cold axiom"
	singular_name = "cold axiom"
	desc = "A cold axiom of pride, distilled from an abnormality. Feeds the Path of Erudition."
	icon_state = "mat_pride"
	path_key = PATH_KEY_ERUDITION
	tier = PATH_MAT_T1
	merge_type = /obj/item/stack/path_material/pride

/obj/item/stack/path_material/pride/t2
	name = "theorem"
	singular_name = "theorem"
	icon_state = "mat_pride_2"
	tier = PATH_MAT_T2
	merge_type = /obj/item/stack/path_material/pride/t2

/obj/item/stack/path_material/pride/t3
	name = "absolute proof"
	singular_name = "absolute proof"
	icon_state = "mat_pride_3"
	tier = PATH_MAT_T3
	merge_type = /obj/item/stack/path_material/pride/t3

// Gloom / Nihility

/obj/item/stack/path_material/gloom
	name = "hollow dust"
	singular_name = "hollow dust"
	desc = "A mote of hollow gloom, drawn from an abnormality. Feeds the Path of Nihility."
	icon_state = "mat_gloom"
	path_key = PATH_KEY_NIHILITY
	tier = PATH_MAT_T1
	merge_type = /obj/item/stack/path_material/gloom

/obj/item/stack/path_material/gloom/t2
	name = "void"
	singular_name = "void"
	icon_state = "mat_gloom_2"
	tier = PATH_MAT_T2
	merge_type = /obj/item/stack/path_material/gloom/t2

/obj/item/stack/path_material/gloom/t3
	name = "abyssal silence"
	singular_name = "abyssal silence"
	icon_state = "mat_gloom_3"
	tier = PATH_MAT_T3
	merge_type = /obj/item/stack/path_material/gloom/t3

// Lust / Harmony

/obj/item/stack/path_material/lust
	name = "faint chord"
	singular_name = "faint chord"
	desc = "A resonant chord of lust, gathered from an abnormality. Feeds the Path of Harmony."
	icon_state = "mat_lust"
	path_key = PATH_KEY_HARMONY
	tier = PATH_MAT_T1
	merge_type = /obj/item/stack/path_material/lust

/obj/item/stack/path_material/lust/t2
	name = "hymn"
	singular_name = "hymn"
	icon_state = "mat_lust_2"
	tier = PATH_MAT_T2
	merge_type = /obj/item/stack/path_material/lust/t2

/obj/item/stack/path_material/lust/t3
	name = "grand chorus"
	singular_name = "grand chorus"
	icon_state = "mat_lust_3"
	tier = PATH_MAT_T3
	merge_type = /obj/item/stack/path_material/lust/t3

// Sloth / Preservation

/obj/item/stack/path_material/sloth
	name = "chipped ward"
	singular_name = "chipped ward"
	desc = "A tempered fragment of sloth, salvaged from an abnormality. Feeds the Path of Preservation."
	icon_state = "mat_sloth"
	path_key = PATH_KEY_PRESERVATION
	tier = PATH_MAT_T1
	merge_type = /obj/item/stack/path_material/sloth

/obj/item/stack/path_material/sloth/t2
	name = "bulwark"
	singular_name = "bulwark"
	icon_state = "mat_sloth_2"
	tier = PATH_MAT_T2
	merge_type = /obj/item/stack/path_material/sloth/t2

/obj/item/stack/path_material/sloth/t3
	name = "aegis"
	singular_name = "aegis"
	icon_state = "mat_sloth_3"
	tier = PATH_MAT_T3
	merge_type = /obj/item/stack/path_material/sloth/t3

// Gluttony / Abundance

/obj/item/stack/path_material/gluttony
	name = "withered seed"
	singular_name = "withered seed"
	desc = "A seed of endless gluttony, harvested from an abnormality. Feeds the Path of Abundance."
	icon_state = "mat_gluttony"
	path_key = PATH_KEY_ABUNDANCE
	tier = PATH_MAT_T1
	merge_type = /obj/item/stack/path_material/gluttony

/obj/item/stack/path_material/gluttony/t2
	name = "bloom"
	singular_name = "bloom"
	icon_state = "mat_gluttony_2"
	tier = PATH_MAT_T2
	merge_type = /obj/item/stack/path_material/gluttony/t2

/obj/item/stack/path_material/gluttony/t3
	name = "everharvest"
	singular_name = "everharvest"
	icon_state = "mat_gluttony_3"
	tier = PATH_MAT_T3
	merge_type = /obj/item/stack/path_material/gluttony/t3

// Trace Material (secondary, ordeal-sourced)

/// Base trace material. Four families, three rarity tiers each.
/// Spent on traces alongside the path's own Path Material.
/obj/item/stack/trace_material
	name = "trace material"
	singular_name = "trace material"
	desc = "Residue condensed from an ordeal."
	icon = 'ModularLobotomy/_Lobotomyicons/path_resources_small.dmi'
	icon_state = "trace_fang"
	w_class = WEIGHT_CLASS_SMALL
	max_amount = 99
	novariants = TRUE
	merge_type = /obj/item/stack/trace_material
	/// Which trace family, one of TRACE_FAMILY_*.
	var/family = TRACE_FAMILY_FANG
	/// Rarity tier: PATH_MAT_T1 / T2 / T3.
	var/tier = PATH_MAT_T1

/// Same subtree-merge trap as the path materials above.
/obj/item/stack/trace_material/can_merge(obj/item/stack/check)
	if(check.type != type)
		return FALSE
	return ..()

/obj/item/stack/trace_material/examine(mob/user)
	. = ..()
	. += span_notice("Rarity: [tier + 1]-star (Tier [tier]) trace material.")
	. += span_notice("Spent on trace upgrades.")

// Fang (Destruction, The Hunt)

/obj/item/stack/trace_material/fang
	name = "bloodworn fang"
	singular_name = "bloodworn fang"
	desc = "Predatory residue left by an ordeal. A trace material for the Destruction and Hunt paths."
	icon_state = "trace_fang"
	family = TRACE_FAMILY_FANG
	tier = PATH_MAT_T1
	merge_type = /obj/item/stack/trace_material/fang

/obj/item/stack/trace_material/fang/t2
	name = "rending fang"
	singular_name = "rending fang"
	icon_state = "trace_fang_2"
	tier = PATH_MAT_T2
	merge_type = /obj/item/stack/trace_material/fang/t2

/obj/item/stack/trace_material/fang/t3
	name = "devouring fang"
	singular_name = "devouring fang"
	icon_state = "trace_fang_3"
	tier = PATH_MAT_T3
	merge_type = /obj/item/stack/trace_material/fang/t3

// Lens (Erudition, Nihility)

/obj/item/stack/trace_material/lens
	name = "clouded lens"
	singular_name = "clouded lens"
	desc = "Cold clarity condensed from an ordeal. A trace material for the Erudition and Nihility paths."
	icon_state = "trace_lens"
	family = TRACE_FAMILY_LENS
	tier = PATH_MAT_T1
	merge_type = /obj/item/stack/trace_material/lens

/obj/item/stack/trace_material/lens/t2
	name = "lucid lens"
	singular_name = "lucid lens"
	icon_state = "trace_lens_2"
	tier = PATH_MAT_T2
	merge_type = /obj/item/stack/trace_material/lens/t2

/obj/item/stack/trace_material/lens/t3
	name = "oracle lens"
	singular_name = "oracle lens"
	icon_state = "trace_lens_3"
	tier = PATH_MAT_T3
	merge_type = /obj/item/stack/trace_material/lens/t3

// Ichor (Abundance, Harmony)

/obj/item/stack/trace_material/ichor
	name = "thin ichor"
	singular_name = "thin ichor"
	desc = "Living ichor congealed from an ordeal. A trace material for the Abundance and Harmony paths."
	icon_state = "trace_ichor"
	family = TRACE_FAMILY_ICHOR
	tier = PATH_MAT_T1
	merge_type = /obj/item/stack/trace_material/ichor

/obj/item/stack/trace_material/ichor/t2
	name = "rich ichor"
	singular_name = "rich ichor"
	icon_state = "trace_ichor_2"
	tier = PATH_MAT_T2
	merge_type = /obj/item/stack/trace_material/ichor/t2

/obj/item/stack/trace_material/ichor/t3
	name = "sacred ichor"
	singular_name = "sacred ichor"
	icon_state = "trace_ichor_3"
	tier = PATH_MAT_T3
	merge_type = /obj/item/stack/trace_material/ichor/t3

// Ward (Preservation)

/obj/item/stack/trace_material/ward
	name = "cracked ward"
	singular_name = "cracked ward"
	desc = "Battered warding drawn from an ordeal. A trace material for the Preservation path."
	icon_state = "trace_ward"
	family = TRACE_FAMILY_WARD
	tier = PATH_MAT_T1
	merge_type = /obj/item/stack/trace_material/ward

/obj/item/stack/trace_material/ward/t2
	name = "tempered ward"
	singular_name = "tempered ward"
	icon_state = "trace_ward_2"
	tier = PATH_MAT_T2
	merge_type = /obj/item/stack/trace_material/ward/t2

/obj/item/stack/trace_material/ward/t3
	name = "adamant ward"
	singular_name = "adamant ward"
	icon_state = "trace_ward_3"
	tier = PATH_MAT_T3
	merge_type = /obj/item/stack/trace_material/ward/t3

// Material pouch (holds large amounts of both material kinds)

/// A bag that stores path and trace material stacks in bulk. Bought from the
/// Omni-Synthesizer or emptied into it for storage.
/obj/item/storage/bag/path_materials
	name = "cosmic material pouch"
	desc = "A pocket of folded space that swallows Pathstrider materials by the hundred. Empty it into an Omni-Synthesizer to bank them."
	icon = 'icons/obj/mining.dmi'
	icon_state = "satchel_bspace"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_NORMAL
	component_type = /datum/component/storage/concrete/stack
	/// Suppresses the "full" spam while walking over materials.
	var/spam_protection = FALSE
	/// Mob whose movement we're listening to for auto-pickup.
	var/mob/listeningTo

/obj/item/storage/bag/path_materials/ComponentInitialize()
	. = ..()
	var/datum/component/storage/concrete/stack/STR = GetComponent(/datum/component/storage/concrete/stack)
	STR.allow_quick_empty = TRUE
	STR.allow_quick_gather = TRUE
	STR.set_holdable(list(/obj/item/stack/path_material, /obj/item/stack/trace_material))
	STR.max_w_class = WEIGHT_CLASS_SMALL
	STR.max_items = 40
	STR.max_combined_stack_amount = 3000

/obj/item/storage/bag/path_materials/equipped(mob/user)
	. = ..()
	if(listeningTo == user)
		return
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(PickupMaterials))
	listeningTo = user

/obj/item/storage/bag/path_materials/dropped()
	. = ..()
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
		listeningTo = null

/// Scoops up any material stacks on the wearer's tile as they move over them.
/obj/item/storage/bag/path_materials/proc/PickupMaterials(mob/living/user)
	var/show_message = FALSE
	var/turf/tile = user.loc
	if(!isturf(tile))
		return
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(!STR)
		return
	for(var/A in tile)
		if(!is_type_in_typecache(A, STR.can_hold))
			continue
		if(SEND_SIGNAL(src, COMSIG_TRY_STORAGE_INSERT, A, user, TRUE))
			show_message = TRUE
		else if(!spam_protection)
			to_chat(user, span_warning("Your [name] is full and can't hold any more!"))
			spam_protection = TRUE
	if(show_message)
		playsound(user, "rustle", 50, TRUE)
		user.visible_message(span_notice("[user] scoops up the materials beneath [user.p_them()]."), \
			span_notice("You scoop up the materials beneath you with your [name]."))
	spam_protection = FALSE
