/*
The main file for the Another Day at Work distortion containing its core behavior.
The taboo and hanging are in taboo.dm, the paper oddities and clues in oddities.dm.

OVERRIDES: 128 - parent and engine procs (Initialize, Life, Teardown...).
TERRITORY: 191 - all of the procs related to its territory datum.
SPEECH: 256 - everything related to recording speech within its territory.
UNDISTORTING: 337 - procs related to undistorting animation
HELPER PROCS: 366 - small shared procs, also used by taboo.dm.
TERRAIN: 394 - the stuff it spawns in it's territory.
*/

/mob/living/simple_animal/hostile/distortion/advanced/another_day
	name = "Another Day at Work"
	desc = "A man covered in... ties?"
	icon = 'ModularLobotomy/_Lobotomyicons/48x96.dmi'
	icon_state = "work"
	maxHealth = 1400
	health = 1400
	pixel_x = -8
	base_pixel_x = -8
	fear_level = TETH_LEVEL
	damage_coeff = list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 0.2, BLACK_DAMAGE = 0.1, PALE_DAMAGE = 0.3)
	melee_damage_lower = 0
	melee_damage_upper = 0
	obj_damage = 0
	ranged = FALSE
	ego_list = list(
		/obj/item/ego_weapon/waging,
		/obj/item/clothing/suit/armor/ego_gear/teth/waging,
	)
	egoist_names = list("Paige Turner", "Larry Sal", "Nota Dollar", "Donnar Profit", "Collin Beck")
	gender = MALE
	sin_reward = /obj/item/solidified_sin/gloom
	monolith_abnormality = /mob/living/simple_animal/hostile/abnormality/black_swan
	territory_cap = 1500
	territory_stages = list(75, 300, 750)
	//This will make it so the territory grows quickly at first, then slows down.
	territory_growth_rate = 1250
	gimmick_stage = 3
	oddities = list(
		/obj/effect/temp_visual/distortion_oddity/paper_drift,
		/obj/effect/temp_visual/distortion_oddity/paper_drift,
		/obj/effect/temp_visual/distortion_oddity/paper_drift,
		/obj/effect/temp_visual/distortion_oddity/paper_drift,
		/obj/item/paperplane/distortion,
		/obj/item/paperplane/distortion,
		/obj/effect/temp_visual/distortion_oddity/paper_drift/clue,
	)
	//Lists of people, drained colors, and drain overlays for tracking the state of the mob.
	//It could look like: people = list("boss" = "Paige Turner", "coworker" = "Larry Sal", "friend" = "Nota Dollar", "self" = "Donnar Profit")
	var/list/people = list()
	//Defines the roles associated with each color tie.
	var/list/color_roles = list("red" = "boss", "blue" = "coworker", "yellow" = "friend")
	var/obj/item/clothing/neck/tie/horrible/another_day/name_tie
	//All of the humans within its territory.
	var/list/listening = list()
	var/forced_whisper_text
	//Colors that are currently drained and their remaining duration.
	var/list/drained = list()
	var/list/drain_overlays = list()
	var/drain_duration = 60 SECONDS
	var/undistort_timer
	var/undistort_time = 30 SECONDS
	var/gives_workload = TRUE
	var/list/next_taboo = list()
	var/taboo_cooldown = 2 SECONDS
	var/sulk_damage = 25
	var/sulk_sanity = 3
	var/hang_threshold = 0.1
	var/list/mind_prefixes = list(
		"A voice moves through your mind.",
		"Something tired speaks from behind your eyes.",
		"A thought that is not yours surfaces.",
		"Someone sighs, very close, inside your head.",
	)
	var/whisper_cooldown = 20 SECONDS
	var/next_whisper = 0
	var/list/sulk_lines = list(
		"I just want to go home.",
		"Nobody asked me.",
		"It will be done by Monday.",
		"I said I was fine.",
		"Please. Not today.",
	)
	//For changing the turfs around the center of the territory.
	var/floor_type = /turf/open/floor/distortion/another_day
	var/wall_type = /turf/closed/indestructible/city/another_day
	// What open turfs it could go over
	var/list/quilt_turf_types = list(/turf/open/floor, /turf/open/indestructible)
	var/list/converted = list()
	var/quilt_fraction = 0.35
	var/quilt_growth_power = 0.5
	//The passive pressure that turns on, once the gimmick stage is reached.
	var/drain_sanity = 2
	var/drain_interval = 10 SECONDS
	var/drain_interval_fast = 3 SECONDS
	var/next_drain = 0
	var/idle_message_chance = 25
	var/list/idle_messages = list(
		"It is later than you think.",
		"Is it still Monday?",
		"The lights have been humming all week.",
		"Just one more thing before I go.",
	)
	//A list of ties that are hanging people! How wonderful...
	var/list/ties = list()
	//A list of clues for each person. Could look like this:
	//list("boss" = list(...), "coworker" = list(...), "friend" = list(...))
	var/list/clues = list()
	var/clues_per_person = 2
	var/list/figure_lines = list(
		"boss" = list("See me before you go home.", "This should have been done yesterday.", "I need it on my desk by morning."),
		"coworker" = list("Can you cover for me again?", "I'll make it up to you, promise.", "You don't mind, do you?"),
		"friend" = list("Are you coming tonight?", "It's always work with you.", "Call me back. Please."),
	)
	var/list/clue_types = list(
		"boss" = /obj/item/paper/distortion/clue/boss,
		"coworker" = /obj/item/paper/distortion/clue/coworker,
		"friend" = /obj/item/paper/distortion/clue/friend,
	)

/*
OVERRIDES
The procs I changed from the base advanced distortion.
*/

//Assigns a random name to each role and spawns the egoist's tie.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/Initialize(mapload)
	. = ..()
	if(!territory)
		return
	//Creates a list of people for each color tie.
	for(var/tie_color in color_roles)
		people[color_roles[tie_color]] = random_unique_name(pick(MALE, FEMALE))
	people["self"] = pick(egoist_names)
	egoist_names = list(people["self"])
	SpawnNameTie()

/mob/living/simple_animal/hostile/distortion/advanced/another_day/Life()
	. = ..()
	if(stat == DEAD)
		return
	TerritoryTick()

/mob/living/simple_animal/hostile/distortion/advanced/another_day/Move()
	return FALSE

/mob/living/simple_animal/hostile/distortion/advanced/another_day/CanAttack(atom/the_target)
	return FALSE

//Got to remove the speech signal from every human we are listening to, and the timers for
//drained colors and other things that the distortion is tracking.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/Teardown()
	if(torn_down)
		return
	for(var/turf/T in converted)
		if(istype(T, floor_type) || istype(T, wall_type))
			T.ChangeTurf(converted[T])
	converted.Cut()
	for(var/obj/structure/another_day_tie/tie in ties)
		qdel(tie)
	for(var/mob/living/carbon/human/H in listening)
		UnregisterSignal(H, COMSIG_MOB_SAY)
	listening.Cut()
	for(var/tie_color in drained)
		deltimer(drained[tie_color])
	drained.Cut()
	if(undistort_timer)
		deltimer(undistort_timer)
		undistort_timer = null
	return ..()

/mob/living/simple_animal/hostile/distortion/advanced/another_day/OnOwnedDeleted(datum/source)
	. = ..()
	if(source == name_tie)
		name_tie = null
	for(var/role in clues)
		LAZYREMOVE(clues[role], source)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/PostUnmanifest(mob/living/carbon/human/egoist)
	new /obj/item/clothing/neck/tie/horrible(get_turf(src))

/*
TERRITORY

Procs related to things happening within the territory, such as registering humans and applying passive effects.
Along with the procs that handle what happens when a stage changes.
*/

// The check that happens every life tick, where it will register new humans inside the territory and unregister those who have left.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/TerritoryTick()
	var/list/inside = HumansInside()
	for(var/mob/living/carbon/human/H in inside)
		if(H in listening)
			continue
		RegisterSignal(H, COMSIG_MOB_SAY, PROC_REF(OnSpeech))
		listening += H
	for(var/mob/living/carbon/human/H in listening)
		if(QDELETED(H) || !(H in inside))
			UnregisterSignal(H, COMSIG_MOB_SAY)
			listening -= H
	for(var/attacker in next_taboo)
		if(next_taboo[attacker] <= world.time)
			next_taboo -= attacker
	PassiveEffects(inside)
	TryHang(inside)
	if(!name_tie)
		SpawnNameTie()

// Once the gimmick stage is reached, add the figure and paper drift oddities are added.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/OnStageChange(old_stage, new_stage)
	if(new_stage < gimmick_stage)
		return
	if(old_stage < gimmick_stage)
		oddities += /obj/effect/temp_visual/distortion_oddity/figure
		oddities += /obj/effect/temp_visual/distortion_oddity/figure
		oddities += /obj/effect/temp_visual/distortion_oddity/paper_drift/clue
	UpdateQuilt()

/mob/living/simple_animal/hostile/distortion/advanced/another_day/OnTerritoryGrown()
	UpdateQuilt()

/mob/living/simple_animal/hostile/distortion/advanced/another_day/ApplyCenterEffects(list/turfs)
	for(var/turf/open/T in turfs)
		if(!is_type_in_list(T, quilt_turf_types))
			continue
		if(!converted[T] && !istype(T, floor_type))
			converted[T] = T.type
			T.ChangeTurf(floor_type)
		//This is done to create a border of walls around the quilt, since NearestTurfs does not find closed turfs.
		for(var/dir in GLOB.cardinals)
			var/turf/next = get_step(T, dir)
			if(!next || converted[next] || !isclosedturf(next) || istype(next, wall_type))
				continue
			converted[next] = next.type
			next.ChangeTurf(wall_type)

// Adds the corrupted tiles around the center of the territory, once gimmick stage is reached.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/UpdateQuilt()
	if(territory.stage < gimmick_stage)
		return
	ApplyCenterEffects(territory.NearestTurfs(QuiltSize()))

// Returns the size of the quilt based on the territory's growth. Which means it increases as the territory grows.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/QuiltSize()
	var/growth = territory.Size() / max(1, territory_start_size)
	return max(1, round(quilt_fraction * territory_start_size * (growth ** quilt_growth_power)))

/*
SPEECH

Procs related to handling speech within the territory, such as registering names and forcing whispers.
*/

//If they say the correct name, tada! They remove one of the colors. Also, got to hear his own name after saying the other 3 names to undistort.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/OnSpeech(mob/living/carbon/human/speaker, list/speech_args)
	SIGNAL_HANDLER
	var/message = speech_args[SPEECH_MESSAGE]
	if(forced_whisper_text)
		speech_args[SPEECH_MESSAGE] = forced_whisper_text
		return
	if(!message)
		return
	for(var/tie_color in color_roles)
		if(findtext(message, people[color_roles[tie_color]]))
			DrainColor(tie_color, speaker)
	if(findtext(message, people["self"]))
		HearOwnName(speaker)
	// If the cap on territory has been reached and the presence is active, force the speaker to whisper.
	if(territory.Size() < territory.cap || !PresenceActive())
		return
	// Clear the original message before forcing the whisper by placing a # before their messsage. We prevent an endless loop by checking whether a forced whisper is already in progress.
	speech_args[SPEECH_MESSAGE] = ""
	forced_whisper_text = message
	INVOKE_ASYNC(speaker, TYPE_PROC_REF(/atom/movable, say), "#[message]", null, null, FALSE, speech_args[SPEECH_LANGUAGE])
	forced_whisper_text = null

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/HearOwnName(mob/living/carbon/human/speaker)
	if(undistort_timer)
		return
	if(drained.len < color_roles.len)
		to_chat(speaker, span_nicegreen("You were close. Other voices are drowning yours out."))
		return
	if(!(src in view(speaker)))
		to_chat(speaker, span_nicegreen("You need to be heard more clearly."))
		return
	StartUndistorting(speaker)

//Removes a color from the distortion, adds a gray overlay to hide that color and sets a timer to restore it after a while!
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/DrainColor(tie_color, mob/living/carbon/human/speaker)
	if(tie_color in drained)
		deltimer(drained[tie_color])
		drained[tie_color] = addtimer(CALLBACK(src, PROC_REF(RestoreColor), tie_color), drain_duration, TIMER_STOPPABLE)
		to_chat(speaker, span_warning("It is already hurting from that name."))
		return
	speaker.Shake(3, 3, 2.5 SECONDS)
	to_chat(speaker, span_nicegreen("Something in this place flinches at that name."))
	drained[tie_color] = addtimer(CALLBACK(src, PROC_REF(RestoreColor), tie_color), drain_duration, TIMER_STOPPABLE)
	var/mutable_appearance/MA = mutable_appearance(icon, "work_drained_[tie_color]")
	drain_overlays[tie_color] = MA
	add_overlay(MA)
	ApplyColor(tie_color, FALSE)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/RestoreColor(tie_color)
	if(!(tie_color in drained))
		return
	drained -= tie_color
	cut_overlay(drain_overlays[tie_color])
	drain_overlays -= tie_color
	ApplyColor(tie_color, TRUE)

//Toggles the effect of a specific color on the distortion, with present determining whether it is turning the effect on or off.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/ApplyColor(tie_color, present)
	switch(tie_color)
		if("red")
			gives_workload = present
		if("blue")
			UpdatePaused()
		if("yellow")
			if(present)
				RemoveModifier(/datum/dc_change/another_day_exposed)
			else
				AddModifier(/datum/dc_change/another_day_exposed)

//Creates a tie with the egoist's name on it, on a random turf in the territory.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/SpawnNameTie()
	name_tie = new(territory.RandomTurf(), people["self"])
	Own(name_tie)

/*
UNDISTORTING

Procs related to undistorting, such as the special effects!
*/

//Basically, restores all drained colors and starts a rays effect around them, then unmanifests after a delay.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/StartUndistorting(mob/living/carbon/human/speaker)
	for(var/tie_color in drained.Copy())
		RestoreColor(tie_color)
	undistort_timer = addtimer(CALLBACK(src, PROC_REF(Unmanifest)), undistort_time, TIMER_STOPPABLE)
	UpdatePaused()
	visible_message(span_notice("The ties go slack, one after another, and something behind them starts to shine."))
	to_chat(speaker, span_nicegreen("He looks up."))
	add_filter("undistort", 1, rays_filter(size = 4, color = "#FFF1B8", offset = 0, density = 10, threshold = 0.15))
	transition_filter("undistort", undistort_time, list(size = 120, offset = 90), SINE_EASING | EASE_IN)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/CancelUndistort()
	if(!undistort_timer)
		return
	deltimer(undistort_timer)
	undistort_timer = null
	remove_filter("undistort")
	UpdatePaused()
	visible_message(span_warning("The light goes out. The ties pull tight again."))

/*
HELPER PROCS

Simple procs that are used often by other procs.
*/

//Simply checks every human to see if they are inside the territory.
//I am mainly doing this since it would be cheaper then checking every turf in the territory, and seeing if a human is on that tile.
//I am not imagining there would be more than like 50 humans alive, even in the worse case.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/HumansInside()
	var/list/inside = list()
	for(var/mob/living/carbon/human/H as anything in GLOB.human_list)
		if(H.z == z && H.stat != DEAD && territory.Contains(get_turf(H)))
			inside += H
	return inside

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/PresenceActive()
	return !("blue" in drained) && !undistort_timer

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/UpdatePaused()
	territory.paused = !PresenceActive()

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/MindSpeak(mob/living/carbon/human/H, line)
	to_chat(H, span_notice("[pick(mind_prefixes)] <i>\"[line]\"</i>"))

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/Mutter(line)
	if(world.time < next_whisper)
		return
	next_whisper = world.time + whisper_cooldown
	whisper(line)

/*
TERRAIN

Stuff related to the terrain that another day spawns, and the stuff that appears on it.
*/

/turf/open/floor/distortion/another_day/Initialize(mapload)
	. = ..()
	icon_state = pick("another_day1", "another_day2", "another_day3", "another_day4")

/turf/closed/indestructible/city/another_day
	name = "quilted wall"
	desc = "Ties, hundreds of them, stitched edge to edge and hung over whatever was here before."
	icon = 'icons/turf/walls/city_another_day.dmi'
	icon_state = "another_day-0"
	base_icon_state = "another_day"

//The effect that is applied to it, allowing it to take meaningful damage from players.
/datum/dc_change/another_day_exposed
	potency = 4
	damage_type = list(RED_DAMAGE, WHITE_DAMAGE, BLACK_DAMAGE, PALE_DAMAGE)

/obj/item/clothing/neck/tie/horrible/another_day
	desc = "A neosilk clip-on tie. This one is disgusting. There is a name on the label."
	var/lifetime = 3 MINUTES
	var/fade_time = 10 SECONDS
	var/drift_time = 4.5 SECONDS

/obj/item/clothing/neck/tie/horrible/another_day/Initialize(mapload, who)
	. = ..()
	desc = "A neosilk clip-on tie. This one is disgusting. The label reads: [who]."
	addtimer(CALLBACK(src, PROC_REF(Expire)), lifetime)
	AnotherDayDrift(src, drift_time, fade_in = TRUE, centered = TRUE)

/obj/item/clothing/neck/tie/horrible/another_day/proc/Expire()
	animate(src, alpha = 0, time = fade_time)
	QDEL_IN(src, fade_time)
