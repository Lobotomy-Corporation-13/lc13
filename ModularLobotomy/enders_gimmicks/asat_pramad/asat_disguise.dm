// Asat Pramad's disguises.
//
// Two ways to put on a face, sharing one body underneath:
//   Mimic   copies any particular human, wherever they are, down to their DNA.
//   Stranger builds someone who never existed: random appearance, random name,
//           and a civilian's clothes off the street.
//
// Either way the disguise is a real human mob and Asat is moved inside it, the
// way envy_humanity wears a body. He is not deleted and not merely recoloured;
// he is a passenger. Dropping the disguise, or the disguise dying, puts him
// back on the floor where it stood.
//
// Sparkle's disguise edits a human in place, which cannot work here: Asat is a
// simple animal with none of a human's appearance vars, so the body has to be
// built rather than repainted.

/// Tint on the disguise effects, matched to his hand.
#define ASAT_DISGUISE_COLOR "#4E3CD4"

/mob/living/simple_animal/hostile/asat_pramad
	/// The body he is currently wearing, if any.
	var/mob/living/carbon/human/worn_body
	var/datum/action/cooldown/asat_mimic/mimic_action
	var/datum/action/cooldown/asat_stranger/stranger_action

// ---- Wearing a body ----

/// TRUE while he is inside a disguise.
/mob/living/simple_animal/hostile/asat_pramad/proc/IsDisguised()
	return worn_body && !QDELETED(worn_body)

/// Moves him inside a finished body and hands over control.
/mob/living/simple_animal/hostile/asat_pramad/proc/WearBody(mob/living/carbon/human/body)
	if(!body || QDELETED(body))
		return FALSE
	var/turf/here = get_turf(src)
	var/obj/effect/temp_visual/turn_book/T = new(here)
	T.color = ASAT_DISGUISE_COLOR
	playsound(here, 'sound/magic/demon_consume.ogg', 50, TRUE)
	// A veiled shape cannot wear a face; step back into the world first.
	if(veiled)
		Unveil()
	if(mind)
		mind.transfer_to(body)
	forceMove(body)
	worn_body = body
	// His own AI keeps running while he is a passenger, and the nearest thing
	// to swing at is the body he is standing inside. Shut it off for the
	// duration; the player is driving the disguise, not him.
	LoseTarget()
	toggle_ai(AI_OFF)
	// Coming out again has to be available from inside the body, so the action
	// is granted to the disguise rather than to him.
	var/datum/action/innate/asat_shed/shed = new()
	shed.Grant(body)
	shed.wearer = src
	RegisterSignal(body, COMSIG_LIVING_DEATH, PROC_REF(OnBodyDeath))
	body.visible_message(span_warning("[body] straightens up, and something behind the eyes settles."))
	return TRUE

/// Steps back out of the body, leaving it behind as a corpse.
/mob/living/simple_animal/hostile/asat_pramad/proc/ShedBody(silent = FALSE)
	if(!IsDisguised())
		return FALSE
	var/mob/living/carbon/human/body = worn_body
	var/turf/exit = get_turf(body)
	UnregisterSignal(body, COMSIG_LIVING_DEATH)
	worn_body = null
	if(body.mind)
		body.mind.transfer_to(src)
	forceMove(exit)
	toggle_ai(AI_ON)
	var/obj/effect/temp_visual/turn_book/T = new(exit)
	T.color = ASAT_DISGUISE_COLOR
	if(!silent)
		playsound(exit, 'sound/magic/demon_consume.ogg', 60, TRUE)
		body.visible_message(span_userdanger("[body] comes apart, and Asat Pramad steps out of the pieces!"))
	// The borrowed shape does not outlive the wearing.
	if(!QDELETED(body))
		body.dust()
	return TRUE

/// If the disguise is killed, he is turned out of it rather than dying with it.
/mob/living/simple_animal/hostile/asat_pramad/proc/OnBodyDeath(mob/living/carbon/human/body, gibbed)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(ShedBody), TRUE)
	visible_message(span_userdanger("The body fails, and something unfolds out of it."))

/// Never swing at the body he is wearing, whatever the AI thinks. Belt and
/// braces alongside switching the AI off in WearBody.
/mob/living/simple_animal/hostile/asat_pramad/CanAttack(atom/the_target)
	if(the_target == worn_body)
		return FALSE
	return ..()

// ---- Building the bodies ----

/// Copies a human down to their DNA, then wears the copy.
/mob/living/simple_animal/hostile/asat_pramad/proc/MimicHuman(mob/living/carbon/human/target)
	if(!istype(target) || QDELETED(target))
		return FALSE
	if(!target.dna)
		to_chat(src, span_warning("There is nothing in [target] to copy."))
		return FALSE
	var/mob/living/carbon/human/body = new(get_turf(src))
	body.real_name = target.real_name
	body.name = target.name
	body.gender = target.gender
	target.dna.copy_dna(body.dna)
	body.dna.transfer_identity(body)
	if(target.dna.species)
		body.set_species(target.dna.species.type)
	body.hairstyle = target.hairstyle
	body.hair_color = target.hair_color
	body.facial_hairstyle = target.facial_hairstyle
	body.facial_hair_color = target.facial_hair_color
	body.eye_color = target.eye_color
	body.gradient_style = target.gradient_style
	body.gradient_color = target.gradient_color
	body.underwear = target.underwear
	body.underwear_color = target.underwear_color
	body.updateappearance()
	// Dress the copy in the same kinds of things the original is wearing.
	CopyWornKit(target, body)
	return WearBody(body)

/// Builds someone who never existed and wears them.
/mob/living/simple_animal/hostile/asat_pramad/proc/BecomeStranger()
	var/mob/living/carbon/human/body = new(get_turf(src))
	randomize_human(body)
	body.real_name = random_unique_name(body.gender)
	body.name = body.real_name
	body.updateappearance()
	// Someone off the street, dressed like it.
	body.equipOutfit(/datum/outfit/job/civilian)
	return WearBody(body)

/// Puts copies of whatever the original is wearing onto the duplicate, so the
/// mimicry does not stop at the skin. Copies types, never the items themselves,
/// so nothing is stolen off a living person.
/mob/living/simple_animal/hostile/asat_pramad/proc/CopyWornKit(mob/living/carbon/human/from, mob/living/carbon/human/onto)
	var/static/list/copied_slots = list(
		ITEM_SLOT_ICLOTHING,
		ITEM_SLOT_OCLOTHING,
		ITEM_SLOT_FEET,
		ITEM_SLOT_GLOVES,
		ITEM_SLOT_HEAD,
		ITEM_SLOT_MASK,
		ITEM_SLOT_EYES,
		ITEM_SLOT_NECK,
		ITEM_SLOT_BACK,
	)
	for(var/slot in copied_slots)
		var/obj/item/worn = from.get_item_by_slot(slot)
		if(!worn)
			continue
		var/obj/item/copy = new worn.type()
		onto.equip_to_slot_or_del(copy, slot, TRUE)

// ---- Actions ----

/datum/action/cooldown/asat_mimic
	name = "Wear a Face"
	desc = "Copy anyone at all, wherever they are, and step inside the copy. You are not changed, only hidden."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/asat_pramad.dmi'
	button_icon_state = "action_mimic"
	cooldown_time = 15 SECONDS

/datum/action/cooldown/asat_mimic/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/asat_pramad/asat = owner
	if(!istype(asat))
		return FALSE
	if(asat.IsDisguised())
		to_chat(asat, span_warning("You are already wearing a face."))
		return FALSE
	// Anyone, anywhere. He does not need to see them to know their shape.
	var/list/candidates = list()
	for(var/mob/living/carbon/human/candidate in GLOB.human_list)
		if(candidate == asat || QDELETED(candidate) || candidate.stat == DEAD)
			continue
		if(!candidate.dna)
			continue
		// Two people can share a name, so collisions get numbered rather than
		// silently overwriting each other in the list.
		var/label = candidate.real_name
		var/suffix = 2
		while(candidates[label])
			label = "[candidate.real_name] ([suffix])"
			suffix++
		candidates[label] = candidate
	if(!length(candidates))
		to_chat(asat, span_warning("There is no one to copy."))
		return FALSE
	var/picked = tgui_input_list(asat, "Whose face?", "Wear a Face", sortList(candidates))
	if(!picked || !candidates[picked])
		return FALSE
	var/mob/living/carbon/human/target = candidates[picked]
	if(QDELETED(target))
		to_chat(asat, span_warning("There is nothing left of them to copy."))
		return FALSE
	if(asat.MimicHuman(target))
		StartCooldown()
	return TRUE

/datum/action/cooldown/asat_stranger
	name = "Wear a Stranger"
	desc = "Put on someone who never existed, dressed as anyone off the street."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/asat_pramad.dmi'
	button_icon_state = "action_stranger"
	cooldown_time = 15 SECONDS

/datum/action/cooldown/asat_stranger/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/asat_pramad/asat = owner
	if(!istype(asat))
		return FALSE
	if(asat.IsDisguised())
		to_chat(asat, span_warning("You are already wearing a face."))
		return FALSE
	if(asat.BecomeStranger())
		StartCooldown()
	return TRUE

/// Granted to the disguise itself, since that is who is holding the reins.
/datum/action/innate/asat_shed
	name = "Shed This Face"
	desc = "Come apart, and stand up as yourself."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/asat_pramad.dmi'
	button_icon_state = "action_shed"
	/// The passenger wearing this body.
	var/mob/living/simple_animal/hostile/asat_pramad/wearer

/datum/action/innate/asat_shed/Activate()
	if(!wearer || QDELETED(wearer))
		return
	wearer.ShedBody()

#undef ASAT_DISGUISE_COLOR
