/proc/getviewsize(view)
	if(isnum(view))
		var/totalviewrange = (view < 0 ? -1 : 1) + 2 * view
		return list(totalviewrange, totalviewrange)
	else
		var/list/viewrangelist = splittext(view,"x")
		return list(text2num(viewrangelist[1]), text2num(viewrangelist[2]))

// PORTED FROM TGSTATION: PR #65180
/// Takes a string or num view, and converts it to pixel width/height in a list(pixel_width, pixel_height)
/proc/view_to_pixels(view)
	if(!view)
		return list(0, 0)
	var/list/view_info = getviewsize(view)
	view_info[1] *= 32
	view_info[2] *= 32
	return view_info

// PORTED FROM TGSTATION: PR #82767
/**
* Frustrated with bugs in can_see(), this instead uses viewers for a much more effective approach.
* ### Things to note:
* - Src/source must be a mob. `viewers()` returns mobs.
* - Adjacent objects are always considered visible.
*/

/// The default tile-distance between two atoms for one to consider the other as visible.
// Note: This was originally 7 in the PR I ported it from, but our view is 17x15 (8 tiles horizontally and 7 tiles vertically). Setting to 8 to avoid weirdness.
#define DEFAULT_SIGHT_DISTANCE 8

/// Basic check to see if the src object can see the target object.
#define CAN_I_SEE(target) ((src in viewers(DEFAULT_SIGHT_DISTANCE, target)) || in_range(target, src))


/// Checks the visibility between two other objects.
#define CAN_THEY_SEE(target, source) ((source in viewers(DEFAULT_SIGHT_DISTANCE, target)) || in_range(target, source))


/// Further checks distance between source and target.
#define CAN_SEE_RANGED(target, source, dist) ((source in viewers(dist, target)) || in_range(target, source))
