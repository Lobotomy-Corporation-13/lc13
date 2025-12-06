// R-Corp Specialist Class System
// Implants that transform Rooks into specialized combat roles

// Base specialist implant
/obj/item/organ/cyberimp/rce_specialist
	name = "R-Corp specialist implant"
	desc = "A military-grade neural implant that reconfigures the user's combat capabilities."
	icon_state = "cyber_implant"
	slot = ORGAN_SLOT_BRAIN_ANTISTUN
	var/class_name = "Specialist"
	var/list/attribute_modifiers = list()
	var/list/granted_traits = list()
	var/specialist_type = null
	var/datum/status_effect/specialist_class/class_effect
	var/list/usable_roles = list(
		"R-Corp Rook",
		"Rook Squad Captain",
		"Robin Squad Captain",
		"Robin Section Leader",
		"Robin Squad Sergeant",
		"Section A Robin",
		"Section B Robin",
		"Section C Robin"
	)

/obj/item/organ/cyberimp/rce_specialist/Insert(mob/living/carbon/M, special, drop_if_replaced)
	. = ..()
	if(!ishuman(M))
		return

	var/mob/living/carbon/human/H = M

	// Check if user has a valid role title
	if(!(H.mind?.assigned_role?.title in usable_roles))
		to_chat(H, span_warning("This implant is only compatible with R-Corp Rook and Robin personnel."))
		Remove(H)
		return

	// Apply class transformation
	ApplyClassTransformation(H)

/obj/item/organ/cyberimp/rce_specialist/Remove(mob/living/carbon/M, special)
	if(ishuman(M))
		RemoveClassTransformation(M)
	return ..()

/obj/item/organ/cyberimp/rce_specialist/proc/ApplyClassTransformation(mob/living/carbon/human/H)
	// Apply attribute modifiers
	for(var/attribute in attribute_modifiers)
		H.adjust_attribute_bonus(attribute, attribute_modifiers[attribute])

	// Grant traits
	for(var/trait in granted_traits)
		ADD_TRAIT(H, trait, ORGAN_TRAIT)

	// Apply status effect for visual/mechanical tracking
	class_effect = H.apply_status_effect(/datum/status_effect/specialist_class, specialist_type)

	// Lock out normal weapons
	ADD_TRAIT(H, TRAIT_NOGUNS, ORGAN_TRAIT)

	to_chat(H, span_notice("You have been transformed into a [class_name]!"))
	to_chat(H, span_nicegreen("You can now use [class_name] specialist weapons and equipment."))
	H.playsound_local(H, 'sound/magic/lightning_chargeup.ogg', 50, TRUE)

/obj/item/organ/cyberimp/rce_specialist/proc/RemoveClassTransformation(mob/living/carbon/human/H)
	// Remove attribute modifiers
	for(var/attribute in attribute_modifiers)
		H.adjust_attribute_bonus(attribute, -attribute_modifiers[attribute])

	// Remove traits
	for(var/trait in granted_traits)
		REMOVE_TRAIT(H, trait, ORGAN_TRAIT)

	// Remove status effect
	if(class_effect)
		H.remove_status_effect(class_effect)

	// Restore weapon usage
	REMOVE_TRAIT(H, TRAIT_NOGUNS, ORGAN_TRAIT)

	to_chat(H, span_notice("The [class_name] transformation has ended."))

// HELLFIRE ROOSTER IMPLANT
/obj/item/organ/cyberimp/rce_specialist/hellfire
	name = "Hellfire Rooster combat implant"
	desc = "Transforms the user into a Hellfire Rooster, granting immunity to fire and enhanced pyrotechnic capabilities."
	class_name = "Hellfire Rooster"
	specialist_type = SPECIALIST_HELLFIRE
	attribute_modifiers = list(
		FORTITUDE_ATTRIBUTE = 20,
		PRUDENCE_ATTRIBUTE = -20,
		TEMPERANCE_ATTRIBUTE = 0,
		JUSTICE_ATTRIBUTE = 40
	)
	granted_traits = list(
		TRAIT_RESISTHEAT,
		TRAIT_NOFIRE
	)
	// No special actions - class just enables weapon usage

// VENOM RATTLESNAKE IMPLANT
/obj/item/organ/cyberimp/rce_specialist/venom
	name = "Venom Rattlesnake combat implant"
	desc = "Transforms the user into a Venom Rattlesnake, specializing in territorial control and toxic warfare."
	class_name = "Venom Rattlesnake"
	specialist_type = SPECIALIST_VENOM
	attribute_modifiers = list(
		FORTITUDE_ATTRIBUTE = 0,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 0,
		JUSTICE_ATTRIBUTE = -20
	)

// STORM RAM IMPLANT
/obj/item/organ/cyberimp/rce_specialist/storm
	name = "Storm Ram combat implant"
	desc = "Transforms the user into a Storm Ram, granting enhanced durability and electromagnetic assault capabilities."
	class_name = "Storm Ram"
	specialist_type = SPECIALIST_STORM
	attribute_modifiers = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = -20,
		TEMPERANCE_ATTRIBUTE = 0,
		JUSTICE_ATTRIBUTE = 40
	)
	granted_traits = list(
		TRAIT_PUSHIMMUNE,
		TRAIT_SHOCKIMMUNE,
		TRAIT_NOGUNS
	)

// STATUS EFFECT FOR TRACKING
/datum/status_effect/specialist_class
	id = "specialist_class"
	duration = -1
	alert_type = null
	var/specialist_type

/datum/status_effect/specialist_class/on_creation(mob/living/new_owner, specialist)
	. = ..()
	specialist_type = specialist

// Persistent fire effect
/obj/effect/persistent_fire
	name = "raging flames"
	desc = "Intense flames that won't go out!"
	icon = 'icons/effects/fire.dmi'
	icon_state = "3"
	anchored = TRUE
	density = FALSE
	opacity = FALSE
	var/damage_per_second = 20
	var/duration

/obj/effect/persistent_fire/Initialize(mapload, fire_duration = 30 SECONDS)
	. = ..()
	duration = fire_duration
	START_PROCESSING(SSobj, src)
	QDEL_IN(src, duration)

/obj/effect/persistent_fire/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/persistent_fire/process()
	for(var/mob/living/L in get_turf(src))
		// Check for Hellfire immunity
		if(L.has_status_effect(/datum/status_effect/specialist_class))
			var/datum/status_effect/specialist_class/SC = L.has_status_effect(/datum/status_effect/specialist_class)
			if(SC.specialist_type == SPECIALIST_HELLFIRE)
				continue // Immune to own flames

		L.deal_damage(damage_per_second, FIRE)
		L.adjust_fire_stacks(1)
		L.IgniteMob()

	// Chance to spread
	if(prob(10))
		SpreadFire()

/obj/effect/persistent_fire/proc/SpreadFire()
	for(var/turf/T in orange(1, src))
		if(locate(/obj/effect/persistent_fire) in T)
			continue
		if(prob(30))
			new /obj/effect/persistent_fire(T, duration / 2)
