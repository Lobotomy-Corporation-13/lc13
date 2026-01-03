// I was originally going to make a file in DEFINES with each of these types but then I realized I wasn't actually using them anywhere?
// I usually just pull these with typesof(/datum/gamespeed_setting) so there's no need for it? I think?

/// This is default gamespeed.
/datum/gamespeed_setting
	/// The name that will show up when game speed is being voted for. Also basically used as an ID due to how voting works.
	var/player_facing_name = "Default Speed (1x)"
	/// We multiply timelocks and abno arrival times by the inverse of this. For example, coefficient of 1.5 would multiply our timelocks and arrivals by 0.667.
	var/speed_coefficient = 1
	/// Assoc list, the keys are ordeal levels and the values are the minimum amount of melts since the last ordeal for this ordeal to happen
	var/minimum_ordeal_gap = list(1 = 3, 2 = 4, 3 = 5, 4 = 8)
	/// Assoc list, the keys are ordeal levels and the values are how many meltdowns less should it take for each ordeal to happen. Will respect minimum_ordeal_gap
	/// The values should be 0 or negative. If you make them positive you're actually delaying the ordeals further... which I guess is valid? For slower speeds?
	// Sadly you have to fill this out manually, I mean I wish we could just apply the speed_coefficient but it just... won't work well with this.
	var/meltdowns_per_ordeal_adjustment = list(1 = 0, 2 = 0, 3 = 0, 4 = 0)
	/// Can this setting be voted for?
	var/available_setting = TRUE

/datum/gamespeed_setting/fast
	player_facing_name = "Fast Speed (1.25x)"
	available_setting = TRUE
	speed_coefficient = 1.25
	minimum_ordeal_gap = list(1 = 3, 2 = 4, 3 = 4, 4 = 6)
	meltdowns_per_ordeal_adjustment = list(1 = 0, 2 = -1, 3 = -1, 4 = -2)

/// For testing
/datum/gamespeed_setting/ultrafast
	player_facing_name = "Ultra Fast Speed (2x)"
	available_setting = FALSE
	speed_coefficient = 2
	minimum_ordeal_gap = list(1 = 2, 2 = 3, 3 = 3, 4 = 4)
	meltdowns_per_ordeal_adjustment = list(1 = 0, 2 = -2, 3 = -3, 4 = -4)
