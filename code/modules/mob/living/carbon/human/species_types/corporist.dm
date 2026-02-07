// Corporist Species - The Ring's Corporist School
// Full-body prosthetic species for Maestro and Apprentice

/datum/species/corporist_maestro
	name = "Corporist Maestro"
	id = "corporist_maestro"
	say_mod = "states"
	sexes = 0
	use_skintones = FALSE
	species_traits = list(NOBLOOD, NOEYESPRITES)
	inherent_traits = list(
		TRAIT_ADVANCEDTOOLUSER,
		TRAIT_NOMETABOLISM,
		TRAIT_TOXIMMUNE,
		TRAIT_RESISTHEAT,
		TRAIT_NOBREATH,
		TRAIT_RESISTCOLD,
		TRAIT_RESISTHIGHPRESSURE,
		TRAIT_RESISTLOWPRESSURE,
		TRAIT_RADIMMUNE,
		TRAIT_GENELESS,
		TRAIT_NOFIRE,
		TRAIT_PIERCEIMMUNE,
		TRAIT_NOHUNGER,
		TRAIT_LIMBATTACHMENT,
		TRAIT_NOCLONELOSS
	)
	inherent_biotypes = MOB_ROBOTIC|MOB_HUMANOID
	meat = null
	damage_overlay_type = "synth"
	mutanttongue = /obj/item/organ/tongue/robot
	species_language_holder = /datum/language_holder/synthetic
	limbs_id = "maestro"
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | MIRROR_MAGIC | RACE_SWAP | ERT_SPAWN | SLIME_EXTRACT
	bodypart_overides = list(
		BODY_ZONE_L_ARM = /obj/item/bodypart/l_arm/corporist_maestro,
		BODY_ZONE_R_ARM = /obj/item/bodypart/r_arm/corporist_maestro,
		BODY_ZONE_HEAD = /obj/item/bodypart/head/corporist_maestro,
		BODY_ZONE_L_LEG = /obj/item/bodypart/l_leg/corporist_maestro,
		BODY_ZONE_R_LEG = /obj/item/bodypart/r_leg/corporist_maestro,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/corporist_maestro
	)

/datum/species/corporist_maestro/on_species_gain(mob/living/carbon/C)
	. = ..()
	for(var/obj/item/bodypart/BP in C.bodyparts)
		BP.change_bodypart_status(BODYPART_ROBOTIC, FALSE, FALSE)
		BP.brute_reduction = 5
		BP.burn_reduction = 4
	C.set_safe_hunger_level()

/datum/species/corporist_maestro/on_species_loss(mob/living/carbon/C)
	. = ..()
	for(var/obj/item/bodypart/BP in C.bodyparts)
		BP.change_bodypart_status(BODYPART_ORGANIC, FALSE, TRUE)
		BP.brute_reduction = initial(BP.brute_reduction)
		BP.burn_reduction = initial(BP.burn_reduction)

/datum/species/corporist_apprentice
	name = "Corporist Apprentice"
	id = "corporist_apprentice"
	say_mod = "states"
	sexes = 0
	use_skintones = FALSE
	species_traits = list(NOBLOOD, NOEYESPRITES, HAIR)

	/// Stored original hair color to restore on species loss
	var/original_hair_color
	/// Stored original gradient color to restore on species loss
	var/original_gradient_color
	inherent_traits = list(
		TRAIT_ADVANCEDTOOLUSER,
		TRAIT_NOMETABOLISM,
		TRAIT_TOXIMMUNE,
		TRAIT_RESISTHEAT,
		TRAIT_NOBREATH,
		TRAIT_RESISTCOLD,
		TRAIT_RESISTHIGHPRESSURE,
		TRAIT_RESISTLOWPRESSURE,
		TRAIT_RADIMMUNE,
		TRAIT_GENELESS,
		TRAIT_NOFIRE,
		TRAIT_PIERCEIMMUNE,
		TRAIT_NOHUNGER,
		TRAIT_LIMBATTACHMENT,
		TRAIT_NOCLONELOSS
	)
	inherent_biotypes = MOB_ROBOTIC|MOB_HUMANOID
	meat = null
	damage_overlay_type = "synth"
	mutanttongue = /obj/item/organ/tongue/robot
	species_language_holder = /datum/language_holder/synthetic
	limbs_id = "apprentice"
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | MIRROR_MAGIC | RACE_SWAP | ERT_SPAWN | SLIME_EXTRACT
	bodypart_overides = list(
		BODY_ZONE_L_ARM = /obj/item/bodypart/l_arm/corporist_apprentice,
		BODY_ZONE_R_ARM = /obj/item/bodypart/r_arm/corporist_apprentice,
		BODY_ZONE_HEAD = /obj/item/bodypart/head/corporist_apprentice,
		BODY_ZONE_L_LEG = /obj/item/bodypart/l_leg/corporist_apprentice,
		BODY_ZONE_R_LEG = /obj/item/bodypart/r_leg/corporist_apprentice,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/corporist_apprentice
	)

/datum/species/corporist_apprentice/on_species_gain(mob/living/carbon/C)
	. = ..()
	for(var/obj/item/bodypart/BP in C.bodyparts)
		BP.change_bodypart_status(BODYPART_ROBOTIC, FALSE, FALSE)
		BP.brute_reduction = 5
		BP.burn_reduction = 4
	C.set_safe_hunger_level()
	// Force hair to white and gradient to gray
	if(ishuman(C))
		var/mob/living/carbon/human/H = C
		original_hair_color = H.hair_color
		original_gradient_color = H.gradient_color
		H.hair_color = "FFF"
		if(H.gradient_style)
			H.gradient_color = "888"
		H.update_hair()

/datum/species/corporist_apprentice/on_species_loss(mob/living/carbon/C)
	. = ..()
	for(var/obj/item/bodypart/BP in C.bodyparts)
		BP.change_bodypart_status(BODYPART_ORGANIC, FALSE, TRUE)
		BP.brute_reduction = initial(BP.brute_reduction)
		BP.burn_reduction = initial(BP.burn_reduction)
	// Restore original hair colors
	if(ishuman(C))
		var/mob/living/carbon/human/H = C
		if(original_hair_color)
			H.hair_color = original_hair_color
		if(original_gradient_color)
			H.gradient_color = original_gradient_color
		H.update_hair()

/// Override handle_hair to allow hair rendering despite robotic head
/datum/species/corporist_apprentice/handle_hair(mob/living/carbon/human/H, forced_colour)
	H.remove_overlay(HAIR_LAYER)
	var/obj/item/bodypart/head/HD = H.get_bodypart(BODY_ZONE_HEAD)
	if(!HD)
		return

	if(HAS_TRAIT(H, TRAIT_HUSK))
		return

	// Skip the BODYPART_ROBOTIC check - apprentices keep their hair
	var/datum/sprite_accessory/S
	var/list/standing = list()

	var/hair_hidden = FALSE
	var/facialhair_hidden = FALSE
	var/dynamic_hair_suffix = ""
	var/dynamic_fhair_suffix = ""

	if(H.head)
		var/obj/item/I = H.head
		if(isclothing(I))
			var/obj/item/clothing/C = I
			dynamic_fhair_suffix = C.dynamic_fhair_suffix
		if(I.flags_inv & HIDEFACIALHAIR)
			facialhair_hidden = TRUE

	if(H.wear_mask)
		var/obj/item/I = H.wear_mask
		if(isclothing(I))
			var/obj/item/clothing/C = I
			dynamic_fhair_suffix = C.dynamic_fhair_suffix
		if(I.flags_inv & HIDEFACIALHAIR)
			facialhair_hidden = TRUE

	if(H.facial_hairstyle && (FACEHAIR in species_traits) && (!facialhair_hidden || dynamic_fhair_suffix))
		S = GLOB.facial_hairstyles_list[H.facial_hairstyle]
		if(S)
			var/mutable_appearance/facial_overlay = mutable_appearance(S.icon, "[S.icon_state]", -HAIR_LAYER)
			if(forced_colour)
				facial_overlay.color = forced_colour
			else
				facial_overlay.color = "#[H.facial_hair_color]"
			standing += facial_overlay

	if(H.head)
		var/obj/item/I = H.head
		if(isclothing(I))
			var/obj/item/clothing/C = I
			dynamic_hair_suffix = C.dynamic_hair_suffix
		if(I.flags_inv & HIDEHAIR)
			hair_hidden = TRUE

	if(H.wear_mask)
		var/obj/item/I = H.wear_mask
		if(I.flags_inv & HIDEHAIR)
			hair_hidden = TRUE

	if(H.hairstyle && (HAIR in species_traits) && (!hair_hidden || dynamic_hair_suffix))
		S = GLOB.hairstyles_list[H.hairstyle]
		if(S)
			var/mutable_appearance/hair_overlay = mutable_appearance(S.icon, "[S.icon_state]", -HAIR_LAYER)
			if(forced_colour)
				hair_overlay.color = forced_colour
			else
				hair_overlay.color = "#[H.hair_color]"
			if(OFFSET_FACE in offset_features)
				hair_overlay.pixel_x += offset_features[OFFSET_FACE][1]
				hair_overlay.pixel_y += offset_features[OFFSET_FACE][2]
			standing += hair_overlay

			if(H.gradient_style)
				var/datum/sprite_accessory/gradient = GLOB.hair_gradients_list[H.gradient_style]
				if(gradient)
					var/icon/temp = icon(S.icon, S.icon_state)
					temp.Blend(icon(gradient.icon, gradient.icon_state), ICON_ADD)
					var/mutable_appearance/gradient_overlay = mutable_appearance(temp)
					gradient_overlay.color = "#[H.gradient_color]"
					gradient_overlay.layer = -HAIR_LAYER
					if(OFFSET_FACE in offset_features)
						gradient_overlay.pixel_x += offset_features[OFFSET_FACE][1]
						gradient_overlay.pixel_y += offset_features[OFFSET_FACE][2]
					standing += gradient_overlay

	if(standing.len)
		H.overlays_standing[HAIR_LAYER] = standing

	H.apply_overlay(HAIR_LAYER)
