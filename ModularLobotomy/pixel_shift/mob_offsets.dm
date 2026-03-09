/mob/living
	/// Associative list of pixel offsets by source. Format: list(PIXEL_X_OFFSET = list(source = value), ...)
	var/list/offsets

/**
 * Adds an offset to the mob's pixel position.
 *
 * * source: The source of the offset, a string or type path
 * * x_add: pixel_x offset
 * * y_add: pixel_y offset
 * * animate: If TRUE, the mob will animate to the new position. If FALSE, it will instantly move.
 */
/mob/living/proc/add_offsets(source, x_add, y_add, animate = TRUE)
	LAZYINITLIST(offsets)
	if(isnum(x_add))
		if(!offsets[PIXEL_X_OFFSET])
			offsets[PIXEL_X_OFFSET] = list()
		offsets[PIXEL_X_OFFSET][source] = x_add
	if(isnum(y_add))
		if(!offsets[PIXEL_Y_OFFSET])
			offsets[PIXEL_Y_OFFSET] = list()
		offsets[PIXEL_Y_OFFSET][source] = y_add
	update_offsets(animate)

/**
 * Goes through all pixel adjustments and removes any tied to the passed source.
 *
 * * source: The source of the offset to remove
 * * animate: If TRUE, the mob will animate to the position with any offsets removed. If FALSE, it will instantly move.
 */
/mob/living/proc/remove_offsets(source, animate = TRUE)
	for(var/offset in offsets)
		var/list/offset_list = offsets[offset]
		if(offset_list)
			offset_list -= source
			if(!length(offset_list))
				offsets -= offset
	if(!length(offsets))
		offsets = null
	update_offsets(animate)

/**
 * Updates the mob's pixel position according to the offsets.
 *
 * * animate: If TRUE, the mob will animate to the new position. If FALSE, it will instantly move.
 */
/mob/living/proc/update_offsets(animate = FALSE)
	var/new_x = base_pixel_x
	var/new_y = base_pixel_y

	for(var/offset_key in LAZYACCESS(offsets, PIXEL_X_OFFSET))
		new_x += offsets[PIXEL_X_OFFSET][offset_key]
	for(var/offset_key in LAZYACCESS(offsets, PIXEL_Y_OFFSET))
		new_y += offsets[PIXEL_Y_OFFSET][offset_key]

	if(new_x == pixel_x && new_y == pixel_y)
		return FALSE

	if(!animate)
		pixel_x = new_x
		pixel_y = new_y
		return TRUE

	SEND_SIGNAL(src, COMSIG_PAUSE_FLOATING_ANIM, 0.3 SECONDS)
	animate(src, pixel_x = new_x, pixel_y = new_y, time = 2, easing = (EASE_IN|EASE_OUT))
	return TRUE

/// Override to recalculate offsets when base pixel changes
/mob/living/set_base_pixel_x(new_value)
	. = ..()
	if(offsets)
		update_offsets()

/// Override to recalculate offsets when base pixel changes
/mob/living/set_base_pixel_y(new_value)
	. = ..()
	if(offsets)
		update_offsets()
