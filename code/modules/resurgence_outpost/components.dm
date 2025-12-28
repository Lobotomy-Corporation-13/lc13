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

/obj/item/resurgence_component/rope
	name = "rope"
	icon = 'icons/obj/power.dmi'
	desc = "Strong woven rope, useful for binding and construction."
	color = "#a07935"
	icon_state = "coil"

// ============================================
// Nails - Stack type for construction
// ============================================

/obj/item/stack/resurgence_nails
	name = "nails"
	desc = "Metal nails for construction."
	singular_name = "nail"
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-silver" // Placeholder
	max_amount = 50
	w_class = WEIGHT_CLASS_SMALL

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

