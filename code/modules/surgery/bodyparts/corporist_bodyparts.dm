// Corporist Bodyparts - The Ring's Corporist School
// Full-body prosthetics for Maestro and Apprentice species

#define CORPORIST_LIGHT_BRUTE_MSG "marred"
#define CORPORIST_MEDIUM_BRUTE_MSG "dented"
#define CORPORIST_HEAVY_BRUTE_MSG "falling apart"

#define CORPORIST_LIGHT_BURN_MSG "scorched"
#define CORPORIST_MEDIUM_BURN_MSG "charred"
#define CORPORIST_HEAVY_BURN_MSG "smoldering"

// CORPORIST MAESTRO BODYPARTS
// Sleek metallic prosthetics with gaps, glass panes, sharp claws

/obj/item/bodypart/head/corporist_maestro
	name = "corporist maestro head"
	desc = "A sleek prosthetic head with glass panes revealing inner workings. The craftsmanship is disturbingly artistic."
	icon = 'icons/mob/human_parts.dmi'
	icon_state = "maestro_head"
	species_id = "maestro"
	status = BODYPART_ROBOTIC
	brute_reduction = 5
	burn_reduction = 4
	light_brute_msg = CORPORIST_LIGHT_BRUTE_MSG
	medium_brute_msg = CORPORIST_MEDIUM_BRUTE_MSG
	heavy_brute_msg = CORPORIST_HEAVY_BRUTE_MSG
	light_burn_msg = CORPORIST_LIGHT_BURN_MSG
	medium_burn_msg = CORPORIST_MEDIUM_BURN_MSG
	heavy_burn_msg = CORPORIST_HEAVY_BURN_MSG

/// Override to use organic rendering path for [species_id]_[body_zone] icon pattern
/obj/item/bodypart/head/corporist_maestro/is_organic_limb()
	return TRUE

/obj/item/bodypart/chest/corporist_maestro
	name = "corporist maestro torso"
	desc = "A massive prosthetic torso with metallic textures and glass panes showing innards. A masterwork of the Corporist school."
	icon = 'icons/mob/human_parts.dmi'
	icon_state = "maestro_chest"
	species_id = "maestro"
	status = BODYPART_ROBOTIC
	brute_reduction = 5
	burn_reduction = 4
	light_brute_msg = CORPORIST_LIGHT_BRUTE_MSG
	medium_brute_msg = CORPORIST_MEDIUM_BRUTE_MSG
	heavy_brute_msg = CORPORIST_HEAVY_BRUTE_MSG
	light_burn_msg = CORPORIST_LIGHT_BURN_MSG
	medium_burn_msg = CORPORIST_MEDIUM_BURN_MSG
	heavy_burn_msg = CORPORIST_HEAVY_BURN_MSG

/obj/item/bodypart/chest/corporist_maestro/is_organic_limb()
	return TRUE

/obj/item/bodypart/l_arm/corporist_maestro
	name = "corporist maestro left arm"
	desc = "A prosthetic arm with large gaps in its center and sharp claws at the end. White chassis with gust-patterned design."
	icon = 'icons/mob/human_parts.dmi'
	icon_state = "maestro_l_arm"
	species_id = "maestro"
	status = BODYPART_ROBOTIC
	brute_reduction = 5
	burn_reduction = 4
	light_brute_msg = CORPORIST_LIGHT_BRUTE_MSG
	medium_brute_msg = CORPORIST_MEDIUM_BRUTE_MSG
	heavy_brute_msg = CORPORIST_HEAVY_BRUTE_MSG
	light_burn_msg = CORPORIST_LIGHT_BURN_MSG
	medium_burn_msg = CORPORIST_MEDIUM_BURN_MSG
	heavy_burn_msg = CORPORIST_HEAVY_BURN_MSG

/obj/item/bodypart/l_arm/corporist_maestro/is_organic_limb()
	return TRUE

/obj/item/bodypart/r_arm/corporist_maestro
	name = "corporist maestro right arm"
	desc = "A prosthetic arm with large gaps in its center and sharp claws at the end. White chassis with gust-patterned design."
	icon = 'icons/mob/human_parts.dmi'
	icon_state = "maestro_r_arm"
	species_id = "maestro"
	status = BODYPART_ROBOTIC
	brute_reduction = 5
	burn_reduction = 4
	light_brute_msg = CORPORIST_LIGHT_BRUTE_MSG
	medium_brute_msg = CORPORIST_MEDIUM_BRUTE_MSG
	heavy_brute_msg = CORPORIST_HEAVY_BRUTE_MSG
	light_burn_msg = CORPORIST_LIGHT_BURN_MSG
	medium_burn_msg = CORPORIST_MEDIUM_BURN_MSG
	heavy_burn_msg = CORPORIST_HEAVY_BURN_MSG

/obj/item/bodypart/r_arm/corporist_maestro/is_organic_limb()
	return TRUE

/obj/item/bodypart/l_leg/corporist_maestro
	name = "corporist maestro left leg"
	desc = "A full-bodied prosthetic leg with white chassis and gust-patterned design. Ends in a silver-adorned high-heel."
	icon = 'icons/mob/human_parts.dmi'
	icon_state = "maestro_l_leg"
	species_id = "maestro"
	status = BODYPART_ROBOTIC
	brute_reduction = 5
	burn_reduction = 4
	light_brute_msg = CORPORIST_LIGHT_BRUTE_MSG
	medium_brute_msg = CORPORIST_MEDIUM_BRUTE_MSG
	heavy_brute_msg = CORPORIST_HEAVY_BRUTE_MSG
	light_burn_msg = CORPORIST_LIGHT_BURN_MSG
	medium_burn_msg = CORPORIST_MEDIUM_BURN_MSG
	heavy_burn_msg = CORPORIST_HEAVY_BURN_MSG

/obj/item/bodypart/l_leg/corporist_maestro/is_organic_limb()
	return TRUE

/obj/item/bodypart/r_leg/corporist_maestro
	name = "corporist maestro right leg"
	desc = "A full-bodied prosthetic leg with white chassis and gust-patterned design. Ends in a silver-adorned high-heel."
	icon = 'icons/mob/human_parts.dmi'
	icon_state = "maestro_r_leg"
	species_id = "maestro"
	status = BODYPART_ROBOTIC
	brute_reduction = 5
	burn_reduction = 4
	light_brute_msg = CORPORIST_LIGHT_BRUTE_MSG
	medium_brute_msg = CORPORIST_MEDIUM_BRUTE_MSG
	heavy_brute_msg = CORPORIST_HEAVY_BRUTE_MSG
	light_burn_msg = CORPORIST_LIGHT_BURN_MSG
	medium_burn_msg = CORPORIST_MEDIUM_BURN_MSG
	heavy_burn_msg = CORPORIST_HEAVY_BURN_MSG

/obj/item/bodypart/r_leg/corporist_maestro/is_organic_limb()
	return TRUE

// CORPORIST APPRENTICE BODYPARTS
// Iron maiden style - white/yellow/gold, knightly appearance

/obj/item/bodypart/head/corporist_apprentice
	name = "corporist apprentice head"
	desc = "A humanoid prosthetic head with shapely lines running across the cheeks. Gold highlights accent the design, with black machinery visible at the neck."
	icon = 'icons/mob/human_parts.dmi'
	icon_state = "apprentice_head"
	species_id = "apprentice"
	status = BODYPART_ROBOTIC
	brute_reduction = 5
	burn_reduction = 4
	light_brute_msg = CORPORIST_LIGHT_BRUTE_MSG
	medium_brute_msg = CORPORIST_MEDIUM_BRUTE_MSG
	heavy_brute_msg = CORPORIST_HEAVY_BRUTE_MSG
	light_burn_msg = CORPORIST_LIGHT_BURN_MSG
	medium_burn_msg = CORPORIST_MEDIUM_BURN_MSG
	heavy_burn_msg = CORPORIST_HEAVY_BURN_MSG

/obj/item/bodypart/head/corporist_apprentice/is_organic_limb()
	return TRUE

/obj/item/bodypart/chest/corporist_apprentice
	name = "corporist apprentice torso"
	desc = "A humanoid prosthetic torso with gold highlights. Black machinery and wires are visible at the chest, and the center resembles a human skeleton in its construction."
	icon = 'icons/mob/human_parts.dmi'
	icon_state = "apprentice_chest"
	species_id = "apprentice"
	status = BODYPART_ROBOTIC
	brute_reduction = 5
	burn_reduction = 4
	light_brute_msg = CORPORIST_LIGHT_BRUTE_MSG
	medium_brute_msg = CORPORIST_MEDIUM_BRUTE_MSG
	heavy_brute_msg = CORPORIST_HEAVY_BRUTE_MSG
	light_burn_msg = CORPORIST_LIGHT_BURN_MSG
	medium_burn_msg = CORPORIST_MEDIUM_BURN_MSG
	heavy_burn_msg = CORPORIST_HEAVY_BURN_MSG

/obj/item/bodypart/chest/corporist_apprentice/is_organic_limb()
	return TRUE

/obj/item/bodypart/l_arm/corporist_apprentice
	name = "corporist apprentice left arm"
	desc = "A humanoid prosthetic arm with shapely lines where human joints would lie. Gold highlights accent the design, with the palm featuring black coloring."
	icon = 'icons/mob/human_parts.dmi'
	icon_state = "apprentice_l_arm"
	species_id = "apprentice"
	status = BODYPART_ROBOTIC
	brute_reduction = 5
	burn_reduction = 4
	light_brute_msg = CORPORIST_LIGHT_BRUTE_MSG
	medium_brute_msg = CORPORIST_MEDIUM_BRUTE_MSG
	heavy_brute_msg = CORPORIST_HEAVY_BRUTE_MSG
	light_burn_msg = CORPORIST_LIGHT_BURN_MSG
	medium_burn_msg = CORPORIST_MEDIUM_BURN_MSG
	heavy_burn_msg = CORPORIST_HEAVY_BURN_MSG

/obj/item/bodypart/l_arm/corporist_apprentice/is_organic_limb()
	return TRUE

/obj/item/bodypart/r_arm/corporist_apprentice
	name = "corporist apprentice right arm"
	desc = "A humanoid prosthetic arm with shapely lines where human joints would lie. Gold highlights accent the design, with the palm featuring black coloring."
	icon = 'icons/mob/human_parts.dmi'
	icon_state = "apprentice_r_arm"
	species_id = "apprentice"
	status = BODYPART_ROBOTIC
	brute_reduction = 5
	burn_reduction = 4
	light_brute_msg = CORPORIST_LIGHT_BRUTE_MSG
	medium_brute_msg = CORPORIST_MEDIUM_BRUTE_MSG
	heavy_brute_msg = CORPORIST_HEAVY_BRUTE_MSG
	light_burn_msg = CORPORIST_LIGHT_BURN_MSG
	medium_burn_msg = CORPORIST_MEDIUM_BURN_MSG
	heavy_burn_msg = CORPORIST_HEAVY_BURN_MSG

/obj/item/bodypart/r_arm/corporist_apprentice/is_organic_limb()
	return TRUE

/obj/item/bodypart/l_leg/corporist_apprentice
	name = "corporist apprentice left leg"
	desc = "A humanoid prosthetic leg with shapely lines at the joints. Gold highlights accent the design, with black machinery and wires visible at the thigh."
	icon = 'icons/mob/human_parts.dmi'
	icon_state = "apprentice_l_leg"
	species_id = "apprentice"
	status = BODYPART_ROBOTIC
	brute_reduction = 5
	burn_reduction = 4
	light_brute_msg = CORPORIST_LIGHT_BRUTE_MSG
	medium_brute_msg = CORPORIST_MEDIUM_BRUTE_MSG
	heavy_brute_msg = CORPORIST_HEAVY_BRUTE_MSG
	light_burn_msg = CORPORIST_LIGHT_BURN_MSG
	medium_burn_msg = CORPORIST_MEDIUM_BURN_MSG
	heavy_burn_msg = CORPORIST_HEAVY_BURN_MSG

/obj/item/bodypart/l_leg/corporist_apprentice/is_organic_limb()
	return TRUE

/obj/item/bodypart/r_leg/corporist_apprentice
	name = "corporist apprentice right leg"
	desc = "A humanoid prosthetic leg with shapely lines at the joints. Gold highlights accent the design, with black machinery and wires visible at the thigh."
	icon = 'icons/mob/human_parts.dmi'
	icon_state = "apprentice_r_leg"
	species_id = "apprentice"
	status = BODYPART_ROBOTIC
	brute_reduction = 5
	burn_reduction = 4
	light_brute_msg = CORPORIST_LIGHT_BRUTE_MSG
	medium_brute_msg = CORPORIST_MEDIUM_BRUTE_MSG
	heavy_brute_msg = CORPORIST_HEAVY_BRUTE_MSG
	light_burn_msg = CORPORIST_LIGHT_BURN_MSG
	medium_burn_msg = CORPORIST_MEDIUM_BURN_MSG
	heavy_burn_msg = CORPORIST_HEAVY_BURN_MSG

/obj/item/bodypart/r_leg/corporist_apprentice/is_organic_limb()
	return TRUE

#undef CORPORIST_LIGHT_BRUTE_MSG
#undef CORPORIST_MEDIUM_BRUTE_MSG
#undef CORPORIST_HEAVY_BRUTE_MSG

#undef CORPORIST_LIGHT_BURN_MSG
#undef CORPORIST_MEDIUM_BURN_MSG
#undef CORPORIST_HEAVY_BURN_MSG
