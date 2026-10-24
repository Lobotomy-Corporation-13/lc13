// Lets a /datum/job declare its own private radio channel by name and colour,
// without the defines, global list edits and scss a hardcoded channel needs.

/// Frequency string -> hex colour, for job-declared radio channels.
GLOBAL_LIST_EMPTY(freqtocolor)

/// Registers a job's private radio channel and returns its frequency.
/// Idempotent, since SetupOccupations() re-instantiates every job datum.
/proc/RegisterJobRadioChannel(channel_name, channel_color)
	if(GLOB.radiochannels[channel_name])
		return GLOB.radiochannels[channel_name]
	var/freq
	for(var/i = FREQ_JOB_CHANNEL_MIN, i <= FREQ_JOB_CHANNEL_MAX, i += 2)
		if(!("[i]" in GLOB.reverseradiochannels))
			freq = i
			break
	if(!freq)
		freq = return_unused_frequency(TRUE)
		WARNING("Job radio channel pool exhausted, [channel_name] fell back to [freq].")
	GLOB.radiochannels[channel_name] = freq
	GLOB.reverseradiochannels["[freq]"] = channel_name
	GLOB.freqtocolor["[freq]"] = channel_color
	return freq
