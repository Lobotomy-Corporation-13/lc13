/// Component that allows living mobs to pixel-shift their sprite within a tile for RP positioning.
/// When shifted far enough, other mobs can walk through the tile.
/// Moving normally or being pulled resets the shift and deletes the component.
/datum/component/pixel_shift
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Whether the mob is pixel shifted or not
	var/is_shifted = FALSE
	/// If we are in the shifting setting.
	var/shifting = TRUE
	/// Takes the four cardinal direction defines. Any atoms moving into this atom's tile will be allowed to from the added directions.
	var/passthroughable = NONE
	/// The maximum amount of pixels allowed to move in the turf.
	var/maximum_pixel_shift = 16
	/// The amount of pixel shift required to make the parent passthroughable.
	var/passable_shift_threshold = 8
	/// The parent's original density before shifting, so we can restore it.
	var/original_density = TRUE
	/// Current x offset
	var/pixel_shift_x = 0
	/// Current y offset
	var/pixel_shift_y = 0

/datum/component/pixel_shift/Initialize(...)
	. = ..()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/pixel_shift/RegisterWithParent()
	RegisterSignal(parent, COMSIG_KB_MOB_PIXEL_SHIFT_DOWN, PROC_REF(pixel_shift_down))
	RegisterSignal(parent, COMSIG_KB_MOB_PIXEL_SHIFT_UP, PROC_REF(pixel_shift_up))
	RegisterSignal(parent, list(COMSIG_LIVING_GET_PULLED, COMSIG_MOVABLE_MOVED), PROC_REF(unpixel_shift))
	RegisterSignal(parent, COMSIG_MOB_CLIENT_PRE_LIVING_MOVE, PROC_REF(pre_move_check))
	RegisterSignal(parent, COMSIG_LIVING_CAN_ALLOW_THROUGH, PROC_REF(check_passable))

/datum/component/pixel_shift/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_KB_MOB_PIXEL_SHIFT_DOWN,
		COMSIG_KB_MOB_PIXEL_SHIFT_UP,
		COMSIG_LIVING_GET_PULLED,
		COMSIG_MOVABLE_MOVED,
		COMSIG_MOB_CLIENT_PRE_LIVING_MOVE,
		COMSIG_LIVING_CAN_ALLOW_THROUGH,
	))

/// Overrides Move to Pixel Shift.
/datum/component/pixel_shift/proc/pre_move_check(mob/source, new_loc, direct)
	SIGNAL_HANDLER
	if(shifting)
		// Clear the movement direction queue since we're consuming this move.
		// Normally client/Move() clears these, but we block that call.
		// Without this, the direction "sticks" and shifting continues after key release.
		if(source.client)
			source.client.next_move_dir_add = 0
			source.client.next_move_dir_sub = 0
		if(direct)
			pixel_shift(source, direct)
		return COMSIG_MOB_CLIENT_BLOCK_PRE_LIVING_MOVE

/// Checks if the parent is considered passthroughable from a direction. Projectiles will ignore the check and hit.
/datum/component/pixel_shift/proc/check_passable(mob/source, atom/movable/mover, border_dir)
	SIGNAL_HANDLER
	if(!isprojectile(mover) && !mover.throwing && passthroughable & border_dir)
		return COMPONENT_LIVING_PASSABLE

/// Activates Pixel Shift on Keybind down. Only Pixel Shift movement will be allowed.
/datum/component/pixel_shift/proc/pixel_shift_down()
	SIGNAL_HANDLER
	shifting = TRUE
	return COMSIG_KB_ACTIVATED

/// Disables Pixel Shift on Keybind up. Allows to Move.
/datum/component/pixel_shift/proc/pixel_shift_up()
	SIGNAL_HANDLER
	shifting = FALSE

/// Resets parent pixel offsets to default, restores density, and deletes the component.
/datum/component/pixel_shift/proc/unpixel_shift()
	SIGNAL_HANDLER
	passthroughable = NONE
	if(is_shifted)
		var/mob/living/owner = parent
		owner.remove_offsets(type)
		owner.density = original_density
	qdel(src)

/// In-turf pixel movement which can allow things to pass through if the threshold is met.
/datum/component/pixel_shift/proc/pixel_shift(mob/source, direct)
	passthroughable = NONE
	var/mob/living/owner = parent
	var/was_shifted = is_shifted
	switch(direct)
		if(NORTH)
			if(pixel_shift_y <= maximum_pixel_shift + owner.base_pixel_y)
				pixel_shift_y++
				is_shifted = TRUE
		if(EAST)
			if(pixel_shift_x <= maximum_pixel_shift + owner.base_pixel_x)
				pixel_shift_x++
				is_shifted = TRUE
		if(SOUTH)
			if(pixel_shift_y >= -maximum_pixel_shift + owner.base_pixel_y)
				pixel_shift_y--
				is_shifted = TRUE
		if(WEST)
			if(pixel_shift_x >= -maximum_pixel_shift + owner.base_pixel_x)
				pixel_shift_x--
				is_shifted = TRUE
	if(is_shifted)
		if(!was_shifted)
			original_density = owner.density
			owner.density = FALSE
		owner.add_offsets(type, x_add = pixel_shift_x, y_add = pixel_shift_y, animate = FALSE)

	// Yes, I know this sets it to true for everything if more than one is matched.
	// Movement doesn't check diagonals, and instead just checks EAST or WEST, depending on where you are for those.
	if(owner.pixel_y > passable_shift_threshold)
		passthroughable |= EAST | SOUTH | WEST
	else if(owner.pixel_y < -passable_shift_threshold)
		passthroughable |= NORTH | EAST | WEST
	if(owner.pixel_x > passable_shift_threshold)
		passthroughable |= NORTH | SOUTH | WEST
	else if(owner.pixel_x < -passable_shift_threshold)
		passthroughable |= NORTH | EAST | SOUTH
