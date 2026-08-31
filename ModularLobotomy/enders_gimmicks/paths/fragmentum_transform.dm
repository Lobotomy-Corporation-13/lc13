// Fragmentum transformation: a short animation of an ordeal mob being
// corrupted - gold crystal spikes erupt from its body, then settle as it
// becomes its fragmentum variant. Built for trailer footage.
//
// Trigger on any covered mob by calling Fragmentize() on it (e.g. from VV,
// Call Proc). The mob hides, the morph plays over it, and at the end it is
// replaced by its fragmentum type. Animation art is per-mob in the
// fragmentum_tf_*.dmi sheets (state "corrupt", 9 frames).

// The morph timing baked into every fragmentum_tf_*.dmi (8 frames at 0.2s +
// a 0.6s hold on the final fragmentum frame = 2.2s). The visual is removed one
// beat into that hold, exactly as the real fragmentum mob is spawned in.
#define FRAGMENTUM_TF_DURATION 20

/obj/effect/temp_visual/fragmentum_transform
	icon_state = "corrupt"
	layer = ABOVE_MOB_LAYER
	duration = FRAGMENTUM_TF_DURATION
	randomdir = FALSE
	/// The fragmentum mob spawned in place once the morph finishes.
	var/result_type

/obj/effect/temp_visual/fragmentum_transform/Initialize(mapload, _icon, _result, _px, _py)
	if(_icon)
		icon = _icon
	if(!isnull(_px))
		pixel_x = _px
	if(!isnull(_py))
		pixel_y = _py
	result_type = _result
	. = ..()
	set_light(3, 1, "#e0a038")

/obj/effect/temp_visual/fragmentum_transform/Destroy()
	if(result_type)
		var/turf/T = get_turf(src)
		if(T)
			new result_type(T)
		result_type = null
	return ..()

// ---------------------------------------------------------------------------
// Corruption hook on ordeal mobs
// ---------------------------------------------------------------------------

/// The fragmentum mob type this ordeal turns into. Null = not corruptible.
/mob/living/simple_animal/hostile/ordeal/var/frag_result
/// The transformation animation sheet (state "corrupt") for this ordeal.
/mob/living/simple_animal/hostile/ordeal/var/frag_tf_icon

/// Removes this mob and drops in the morph effect, which spawns its fragmentum
/// variant when it finishes. No-op if not corruptible or already corrupted.
/mob/living/simple_animal/hostile/ordeal/proc/Fragmentize()
	if(!frag_result || !frag_tf_icon || istype(src, frag_result))
		return
	var/turf/T = get_turf(src)
	if(!T)
		return
	playsound(src, 'sound/effects/gravhit.ogg', 60, TRUE)
	new /obj/effect/temp_visual/fragmentum_transform(T, frag_tf_icon, frag_result, pixel_x, pixel_y)
	qdel(src)

// ---------------------------------------------------------------------------
// Which ordeals can be corrupted, and into what (dawns + noons of each colour)
// ---------------------------------------------------------------------------

/mob/living/simple_animal/hostile/ordeal/amber_bug/frag_result = /mob/living/simple_animal/hostile/ordeal/amber_bug/fragmentum
/mob/living/simple_animal/hostile/ordeal/amber_bug/frag_tf_icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_tf_amber_dawn.dmi'

/mob/living/simple_animal/hostile/ordeal/green_bot/frag_result = /mob/living/simple_animal/hostile/ordeal/green_bot/fragmentum
/mob/living/simple_animal/hostile/ordeal/green_bot/frag_tf_icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_tf_green_dawn.dmi'

/mob/living/simple_animal/hostile/ordeal/green_bot_big/frag_result = /mob/living/simple_animal/hostile/ordeal/green_bot_big/fragmentum
/mob/living/simple_animal/hostile/ordeal/green_bot_big/frag_tf_icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_tf_green_noon.dmi'

/mob/living/simple_animal/hostile/ordeal/violet_fruit/frag_result = /mob/living/simple_animal/hostile/ordeal/violet_fruit/fragmentum
/mob/living/simple_animal/hostile/ordeal/violet_fruit/frag_tf_icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_tf_violet_dawn.dmi'

/mob/living/simple_animal/hostile/ordeal/violet_monolith/frag_result = /mob/living/simple_animal/hostile/ordeal/violet_monolith/fragmentum
/mob/living/simple_animal/hostile/ordeal/violet_monolith/frag_tf_icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_tf_violet_noon.dmi'

/mob/living/simple_animal/hostile/ordeal/indigo_dawn/frag_result = /mob/living/simple_animal/hostile/ordeal/indigo_dawn/fragmentum
/mob/living/simple_animal/hostile/ordeal/indigo_dawn/frag_tf_icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_tf_indigo_dawn.dmi'
