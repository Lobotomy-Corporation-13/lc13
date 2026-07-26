// Generic, reusable status effects for the LCE attunement system.
// Any LCE gear that pushes a wearer past their safe attunement limit applies these.

// Attunement Overload: pushing attunement past your safe limit strains your mind,
// lowering your maximum SP. The reduction scales with how far past the limit you are.
// Applied and removed by the worn LCE armor via RefreshAttunement().
/datum/status_effect/attunement_overload
	id = "attunement_overload"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1 // Permanent until the armor removes it.
	alert_type = /atom/movable/screen/alert/status_effect/attunement_overload
	/// The exact PRUDENCE reduction we applied, so on_remove restores the same amount.
	var/sp_reduction = 0

/atom/movable/screen/alert/status_effect/attunement_overload
	name = "Attunement Overload"
	desc = "You have pushed your EGO past your safe attunement limit. Your maximum SP is \
		reduced and attacking recoils into you. Lower your attunement to recover."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_actions.dmi'
	icon_state = "overload"

/datum/status_effect/attunement_overload/on_creation(mob/living/new_owner, reduction = 0)
	sp_reduction = reduction
	return ..()

/datum/status_effect/attunement_overload/on_apply()
	. = ..()
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/H = owner
	// Lower max SP via PRUDENCE's *stat bonus*, NOT its level/buff. stat_bonus feeds
	// maxSanity but is ignored by stat checks like CanUseEgo, so the wearer's SP ceiling
	// drops while they keep access to their EGO gear (e.g. a 20/20/20/20 researcher).
	H.adjust_attribute_bonus(PRUDENCE_ATTRIBUTE, -sp_reduction)
	H.updatehealth()

/datum/status_effect/attunement_overload/on_remove()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.adjust_attribute_bonus(PRUDENCE_ATTRIBUTE, sp_reduction)
		H.updatehealth()
	return ..()

// Custom sparks that fly off an overloaded LCE suit as it attacks past the safe limit,
// so onlookers can see the wearer is straining their EGO.
/obj/effect/temp_visual/lce_overload_spark
	icon = 'ModularLobotomy/_Lobotomyicons/lce_overload_spark.dmi'
	icon_state = "s0"
	duration = 5
	randomdir = FALSE

/obj/effect/temp_visual/lce_overload_spark/Initialize()
	icon_state = "s[rand(0, 2)]"
	. = ..()
	pixel_x = rand(-4, 4)
	pixel_y = rand(-2, 6)
	animate(src, pixel_x = pixel_x + rand(-12, 12), pixel_y = pixel_y + rand(6, 16), alpha = 0, time = duration)
