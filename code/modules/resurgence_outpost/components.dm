/**
 * Resurgence Outpost - Crafted Components
 *
 * Custom components unique to Resurgence Outpost crafting.
 * Uses base game materials where possible (wood, metal, leather, glass, etc.)
 */

// ============================================
// Base Component
// ============================================

/obj/item/resurgence_component
	name = "component"
	desc = "A crafted component."
	icon = 'icons/obj/device.dmi'
	icon_state = "intm_circuit"
	w_class = WEIGHT_CLASS_SMALL

// ============================================
// Rope - Made from cloth at Crafting Table
// ============================================

/obj/item/stack/resurgence_rope
	name = "rope"
	singular_name = "rope"
	desc = "Strong woven rope, useful for binding and construction."
	icon = 'icons/obj/power.dmi'
	icon_state = "coil"
	color = "#a07935"
	max_amount = 50
	w_class = WEIGHT_CLASS_SMALL
	merge_type = /obj/item/stack/resurgence_rope

// ============================================
// Ash Plating - Metal component
// ============================================

/obj/item/resurgence_component/ash_plating
	name = "ash plating"
	desc = "A reinforced metal plating coated with ash residue for heat resistance."
	icon = 'icons/obj/module.dmi'
	icon_state = "ash_plating"

// ============================================
// Microchips - Electronic components
// ============================================

/obj/item/resurgence_component/microchip
	name = "basic microchip"
	desc = "A simple processing chip for basic electronics."
	icon = 'icons/obj/module.dmi'
	icon_state = "cpu"

/obj/item/resurgence_component/microchip/advanced
	name = "advanced microchip"
	desc = "An advanced processing chip for complex electronics."
	icon_state = "cpu_adv"

/obj/item/resurgence_component/microchip/super
	name = "super microchip"
	desc = "A high-performance processing chip for sophisticated machinery."
	icon_state = "cpu_super"

// ============================================
// Vines - Dropped from trees, used for rope
// ============================================

/obj/item/stack/resurgence_vines
	name = "vines"
	desc = "Flexible plant vines harvested from trees. Can be woven into rope."
	singular_name = "vine"
	icon = 'icons/obj/power.dmi'
	icon_state = "coil"
	color = "#4a8c3b"  // Green color
	max_amount = 50
	w_class = WEIGHT_CLASS_SMALL
	merge_type = /obj/item/stack/resurgence_vines

// ============================================
// Fertilizer - Made from coal, used for farming
// ============================================

/obj/item/stack/resurgence_fertilizer
	name = "fertilizer"
	desc = "Nutrient-rich soil amendment made from processed coal. Used to prepare farm plots."
	singular_name = "fertilizer"
	icon = 'icons/obj/storage.dmi'
	icon_state = "plantbag"
	max_amount = 50
	w_class = WEIGHT_CLASS_SMALL
	merge_type = /obj/item/stack/resurgence_fertilizer

// ============================================
// Sandstone Crafting from Glass Ore
// ============================================

/// Allow crafting sandstone from glass ore via attack_self (converts ALL sand at once)
/obj/item/stack/ore/glass/attack_self(mob/user)
	. = ..()
	if(.)
		return

	// Only in outpost gamemode
	if(SSmaptype.maptype != "outpost")
		return

	if(amount < 1)
		return

	var/convert_amount = amount
	to_chat(user, span_notice("You begin compressing [convert_amount] sand into sandstone..."))
	if(!do_after(user, 2 SECONDS, src))
		return

	if(QDELETED(src) || amount < 1)
		return

	// Get the actual amount to convert (may have changed during do_after)
	convert_amount = amount

	// Create sandstone stack
	var/obj/item/stack/sheet/mineral/sandstone/S = new(user.drop_location(), convert_amount)
	use(convert_amount)
	user.put_in_hands(S)
	to_chat(user, span_notice("You compress the sand into [convert_amount] sandstone bricks."))
	playsound(user, 'sound/effects/stonedoor_openclose.ogg', 30, TRUE)

/// Allow breaking down sandstone into sand via attack_self (converts ALL sandstone at once)
/obj/item/stack/sheet/mineral/sandstone/attack_self(mob/user)
	. = ..()
	if(.)
		return

	// Only in outpost gamemode
	if(SSmaptype.maptype != "outpost")
		return

	if(amount < 1)
		return

	var/convert_amount = amount
	to_chat(user, span_notice("You begin crushing [convert_amount] sandstone into sand..."))
	if(!do_after(user, 2 SECONDS, src))
		return

	if(QDELETED(src) || amount < 1)
		return

	// Get the actual amount to convert (may have changed during do_after)
	convert_amount = amount

	// Create sand stack
	var/obj/item/stack/ore/glass/S = new(user.drop_location(), convert_amount)
	use(convert_amount)
	user.put_in_hands(S)
	to_chat(user, span_notice("You crush the sandstone into [convert_amount] sand."))
	playsound(user, 'sound/effects/stonedoor_openclose.ogg', 30, TRUE)

