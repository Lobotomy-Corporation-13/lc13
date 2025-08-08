/mob/living
	var/mad_shaking = 0

/mob/living/proc/do_shaky_animation(shaky)
	var/amplitude = min(4, (shaky/100) + 1)
	var/pixel_x_diff = rand(-amplitude, amplitude)
	var/pixel_y_diff = rand(-amplitude/3, amplitude/3)
	animate(src, pixel_x = pixel_x_diff, pixel_y = pixel_y_diff , time = 0.65, loop = 24, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
	animate(pixel_x = -pixel_x_diff , pixel_y = -pixel_y_diff , time = 0.65, flags = ANIMATION_RELATIVE)

/// Returns the string form of the def_zone we have hit.
/mob/living/proc/check_hit_limb_zone_name(hit_zone)
	if(has_limbs)
		return hit_zone
