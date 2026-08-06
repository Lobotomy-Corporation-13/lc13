// The containment manipulator: a console in the control booth that pilots a ceiling claw inside
// the cell. It exists so staff can feed a specimen, take something back off it, tidy up after it
// and hose the floor down WITHOUT opening the poddoors, which is the one thing containment is for.
//
// The claw is a real, persistent machine and the camera eye only drags it around - the eye is the
// controller, not the thing you see. That is what lets the claw stay parked in the cell between
// sessions instead of blinking out the moment somebody stops piloting.

#define LCE_CLAW_REACH_TIME 4      // Deciseconds for the claw to reach the floor, and to come back.
#define LCE_CLAW_SPRAY_COST 10     // Water spent per spray.
#define LCE_CLAW_SPRAY_STREAMS 5   // Particles per spray, as the extinguisher does it.
#define LCE_SCAN_STAGES 5          // do_afters in a full scan. Each one that lands is one box.
#define LCE_SCAN_STAGE_TIME 3 SECONDS
#define LCE_SCAN_DRAIN_MIN 5
#define LCE_SCAN_DRAIN_MAX 8
///Hunger and desire are never taken below this by a scan. See the comment on ScanSpecimen.
#define LCE_SCAN_FLOOR 10

/*			CONSOLE			*/

/obj/machinery/computer/camera_advanced/lce_claw
	name = "containment manipulator console"
	desc = "Drives the claw hanging in the cell next door. It can lift things out, lower things \
		in, empty a bag onto the floor and hose the place down, all without anybody opening a door."
	icon_screen = "lce_claw"
	icon_keyboard = "tech_key"
	resistance_flags = INDESTRUCTIBLE
	circuit = null
	//Note: the camera-static setting that matters lives on the eye, not here - see the eye's
	//use_static below, which is what attack_hand() actually reads.
	///Which cell this console reaches into. Set per-instance on the map; falls back to our own area.
	var/area/claw_area = null
	///Persists between piloting sessions. Only null while the claw is destroyed.
	var/obj/machinery/lce_claw/claw = null
	var/max_stored = 21
	var/water_capacity = 100
	var/rebuild_time = 60 SECONDS
	var/rebuild_at = 0
	var/datum/action/innate/lce_claw/grab/grab_action
	var/datum/action/innate/lce_claw/lower/lower_action
	var/datum/action/innate/lce_claw/unload/unload_action
	var/datum/action/innate/lce_claw/spray/spray_action
	var/datum/action/innate/lce_claw/scan/scan_action

/obj/machinery/computer/camera_advanced/lce_claw/Initialize(mapload)
	. = ..()
	flags_1 |= NODECONSTRUCT_1
	//OPENCONTAINER is the whole refill feature: reagent containers pour into anything refillable
	//from their own afterattack, so there is no refill code on this machine at all.
	create_reagents(water_capacity, OPENCONTAINER)
	//Shipped full, the way an extinguisher is. Nobody should have to go and find a bucket before
	//the console will do anything at all.
	reagents.add_reagent(/datum/reagent/water, water_capacity)
	if(!claw_area)
		//get_area is a macro, so it needs landing in a var before the type can be read off it.
		var/area/our_area = get_area(src)
		claw_area = our_area?.type
	if(!ispath(claw_area, /area/lce/containment))
		stack_trace("[src] at [AREACOORD(src)] has claw_area [claw_area || "unset"], which is not \
			an /area/lce/containment subtype. The claw will have nowhere to go.")
	grab_action = new
	lower_action = new
	unload_action = new
	spray_action = new
	scan_action = new

/obj/machinery/computer/camera_advanced/lce_claw/Destroy()
	for(var/obj/item/I in contents)
		I.forceMove(drop_location())
	QDEL_NULL(claw)
	QDEL_NULL(grab_action)
	QDEL_NULL(lower_action)
	QDEL_NULL(unload_action)
	QDEL_NULL(spray_action)
	QDEL_NULL(scan_action)
	return ..()

/obj/machinery/computer/camera_advanced/lce_claw/examine(mob/user)
	. = ..()
	. += span_notice("It is holding [length(contents)] of [max_stored] items.")
	. += span_notice("Water: [round(reagents.get_reagent_amount(/datum/reagent/water))]/[water_capacity] units.")
	if(!claw)
		. += span_warning(rebuild_at > world.time \
			? "The claw is being rebuilt. [DisplayTimeText(rebuild_at - world.time)] remaining." \
			: "No claw is deployed.")

///Somewhere in the cell to hang a new claw from. Prefers open floor; anything at all beats nothing.
/obj/machinery/computer/camera_advanced/lce_claw/proc/FindClawSpot()
	var/list/candidates = get_area_turfs(claw_area, subtypes = TRUE)
	if(!length(candidates))
		return null
	var/list/open_turfs = list()
	for(var/turf/T in candidates)
		if(!T.density)
			open_turfs += T
	return length(open_turfs) ? pick(open_turfs) : pick(candidates)

/obj/machinery/computer/camera_advanced/lce_claw/proc/BuildClaw(mob/user)
	if(claw)
		return TRUE
	if(world.time < rebuild_at)
		to_chat(user, span_warning("The gantry is still reassembling itself. \
			[DisplayTimeText(rebuild_at - world.time)] remaining."))
		return FALSE
	var/turf/spot = FindClawSpot()
	if(!spot)
		to_chat(user, span_warning("The console cannot find the cell it is wired to."))
		return FALSE
	claw = new(spot, src)
	visible_message(span_notice("[src] chatters, and somewhere behind the wall a gantry starts moving."))
	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
	return TRUE

///Called by the claw when it is broken.
/obj/machinery/computer/camera_advanced/lce_claw/proc/ClawLost()
	claw = null
	rebuild_at = world.time + rebuild_time
	if(current_user)
		to_chat(current_user, span_userdanger("The claw goes dead in your hands."))
		remove_eye_control(current_user)
	say("Manipulator offline. Rebuilding.")
	playsound(src, 'sound/machines/buzz-sigh.ogg', 50, FALSE)

/obj/machinery/computer/camera_advanced/lce_claw/CreateEye()
	if(!BuildClaw(usr))
		return
	eyeobj = new /mob/camera/ai_eye/remote/lce_claw(get_turf(claw), src)
	eyeobj.origin = src

/obj/machinery/computer/camera_advanced/lce_claw/GrantActions(mob/living/user)
	..()
	for(var/datum/action/innate/lce_claw/A in list(grab_action, lower_action, unload_action, spray_action, scan_action))
		A.target = src
		A.Grant(user)
		actions += A

//Help intent stows an item. Reagent containers are let through first - otherwise clicking with a
//bucket to fill the tank would be swallowed as a storage insert and the water would never arrive.
/obj/machinery/computer/camera_advanced/lce_claw/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/reagent_containers))
		return ..()
	if(user.a_intent != INTENT_HELP)
		return ..()
	return Stow(I, user) || ..()

///TRUE if the item was taken. Shared by the hand-insert path and the claw's grab.
/obj/machinery/computer/camera_advanced/lce_claw/proc/Stow(obj/item/I, mob/user)
	if(QDELETED(I))
		return FALSE
	if(length(contents) >= max_stored)
		if(user)
			to_chat(user, span_warning("[src] is full."))
		return FALSE
	if(user && !user.transferItemToLoc(I, src))
		return FALSE
	if(!user)
		I.forceMove(src)
	if(user)
		to_chat(user, span_notice("You feed [I] into [src]."))
	playsound(src, 'sound/machines/terminal_prompt.ogg', 40, FALSE)
	return TRUE

/obj/machinery/computer/camera_advanced/lce_claw/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	if(!length(contents))
		to_chat(user, span_notice("[src] is empty."))
		return
	var/obj/item/chosen = tgui_input_list(user, "Retrieve which item?", "Manipulator Store", contents.Copy())
	if(!chosen || !(chosen in contents) || !user.Adjacent(src))
		return
	user.put_in_hands(chosen)
	to_chat(user, span_notice("You take [chosen] out of [src]."))

/*			THE CLAW			*/

//Subtypes the abnormality core extractor, which is already a ceiling claw on a cable: it brings
//the 64x64 offsets, density = FALSE and the high layer, so the claw hovers over the specimen's
//tile instead of being a wall it can be cornered against.
/obj/machinery/lce_claw
	name = "containment manipulator"
	desc = "A claw on a motorised gantry, hanging from the ceiling. Someone in the booth next door \
		is looking through it."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_map/lce_claw.dmi'
	icon_state = "lce_claw"
	parent_type = /obj/machinery/abno_core_extractor
	max_integrity = 200
	use_power = NO_POWER_USE
	var/obj/machinery/computer/camera_advanced/lce_claw/console
	///Blocks movement and further actions while an animation is playing.
	var/busy = FALSE

/obj/machinery/lce_claw/Initialize(mapload, obj/machinery/computer/camera_advanced/lce_claw/our_console)
	. = ..()
	console = our_console

/obj/machinery/lce_claw/Destroy()
	if(console)
		console.ClawLost()
		console = null
	return ..()

/obj/machinery/lce_claw/update_icon_state()
	icon_state = busy ? "lce_claw_held" : "lce_claw"
	return ..()

///Raise the lock, with a watchdog. `busy` also gates movement, so a stuck TRUE would leave the
///claw frozen for the rest of the round - the timer guarantees it comes back no matter what
///happens in between, including a runtime in the payload.
/obj/machinery/lce_claw/proc/SetBusy(duration)
	busy = TRUE
	update_icon_state()
	addtimer(CALLBACK(src, PROC_REF(ClearBusy)), duration + 2 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

/obj/machinery/lce_claw/proc/ClearBusy()
	if(QDELETED(src))
		return
	busy = FALSE
	pixel_z = 0
	update_icon_state()

///The claw closed on nothing. Its target was eaten, burned or otherwise deleted mid-reach.
/obj/machinery/lce_claw/proc/Miss()
	visible_message(span_notice("[src] closes on nothing."))
	playsound(src, 'sound/machines/buzz-two.ogg', 30, TRUE)

///Reach down, do something on the floor, and come back up. `payload` runs at the bottom.
/obj/machinery/lce_claw/proc/Reach(datum/callback/payload)
	set waitfor = FALSE
	if(busy)
		return FALSE
	SetBusy(LCE_CLAW_REACH_TIME * 2)
	flick("lce_claw_closed", src)
	//pixel_z rather than pixel_y: vertical motion that must not disturb layering.
	animate(src, pixel_z = -16, time = LCE_CLAW_REACH_TIME)
	playsound(src, 'sound/machines/terminal_prompt.ogg', 35, TRUE)
	sleep(LCE_CLAW_REACH_TIME)
	if(QDELETED(src))
		return FALSE
	//Async: a runtime inside the payload must not skip the rise and the unlock below.
	payload?.InvokeAsync()
	animate(src, pixel_z = 0, time = LCE_CLAW_REACH_TIME)
	sleep(LCE_CLAW_REACH_TIME)
	if(QDELETED(src))
		return FALSE
	ClearBusy()
	return TRUE

//Every payload takes a weakref rather than the item itself. Half a second passes between choosing
//a target and the claw arriving, which is plenty of time for a specimen to eat the food, for it to
//burn, or for anything else to delete it. resolve() returns null for a deleted datum, so the claw
//simply closes on nothing - and, just as importantly, holding a weakref across the sleep means a
//deleted item is not kept alive by our reference until the animation ends.
/obj/machinery/lce_claw/proc/DoGrab(datum/weakref/item_ref)
	var/obj/item/I = item_ref?.resolve()
	if(!I || I.loc != get_turf(src) || !console)
		Miss()
		return
	if(!console.Stow(I, null))
		visible_message(span_warning("[src] cannot fit [I] into the console."))

/obj/machinery/lce_claw/proc/DoLower(datum/weakref/item_ref)
	var/obj/item/I = item_ref?.resolve()
	if(!I || !console || I.loc != console)
		Miss()
		return
	I.forceMove(get_turf(src))

/*			THE EYE			*/

//Invisible. Everything the pilot sees is the claw itself, which the eye tows along behind it.
/mob/camera/ai_eye/remote/lce_claw
	name = "manipulator feed"
	visible_icon = FALSE
	use_static = USE_STATIC_NONE
	//The base treats `sprint` as a tiles-per-input multiplier, not a delay. Both of these are
	//neutralised so the throttle below is the only thing setting the pace.
	sprint = 10
	acceleration = 0
	///Deciseconds between tiles. A gantry is not a camera drone.
	var/move_delay = 3
	var/next_claw_move = 0
	var/obj/machinery/computer/camera_advanced/lce_claw/console

/mob/camera/ai_eye/remote/lce_claw/Initialize(mapload, obj/machinery/computer/camera_advanced/lce_claw/our_console)
	console = our_console
	return ..()

/mob/camera/ai_eye/remote/lce_claw/Destroy()
	console = null
	return ..()

//Deliberately does NOT call ..(): the parent re-runs its sprint loop, which would move several
//tiles per press and undo the throttle entirely.
/mob/camera/ai_eye/remote/lce_claw/relaymove(mob/living/user, direction)
	if(world.time < next_claw_move)
		return FALSE
	if(console?.claw?.busy)
		return FALSE
	next_claw_move = world.time + move_delay
	dir = direction
	var/turf/step_turf = get_step(src, direction)
	if(step_turf)
		setLoc(step_turf)
	return TRUE

/mob/camera/ai_eye/remote/lce_claw/setLoc(turf/T)
	T = get_turf(T)
	if(!T)
		return
	//The claw is bolted to one cell's gantry. It cannot leave, and it cannot sit inside a wall.
	if(console && !istype(get_area(T), console.claw_area))
		return
	if(T.density)
		return
	. = ..()
	if(console?.claw && !QDELETED(console.claw))
		console.claw.forceMove(T)
		console.claw.dir = dir

//The base has no logout handling at all, so a pilot who disconnects mid-session leaves the
//console reading "already in use" for the rest of the round.
/mob/camera/ai_eye/remote/lce_claw/Logout()
	. = ..()
	if(console && console.current_user == eye_user)
		console.remove_eye_control(eye_user)

/*			ACTIONS			*/

/datum/action/innate/lce_claw
	//The buttons are the claw's own head, cropped out of its sprite, so the control and the thing
	//it drives are the same piece of art.
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lce_map/lce_claw_actions.dmi'
	button_icon_state = "claw_take"
	///Set in Activate() by CheckClaw().
	var/obj/machinery/computer/camera_advanced/lce_claw/console
	var/obj/machinery/lce_claw/claw

///Resolves and validates the console and claw. FALSE means do nothing.
/datum/action/innate/lce_claw/proc/CheckClaw()
	console = target
	if(!istype(console) || !console.claw || QDELETED(console.claw))
		to_chat(owner, span_warning("There is no claw to work with."))
		return FALSE
	claw = console.claw
	if(claw.busy)
		to_chat(owner, span_warning("The claw is already moving."))
		return FALSE
	return TRUE

/datum/action/innate/lce_claw/grab
	name = "Take"
	desc = "Reach down and lift whatever is under the claw into the console."
	button_icon_state = "claw_take"

/datum/action/innate/lce_claw/grab/Activate()
	if(!CheckClaw())
		return
	if(length(console.contents) >= console.max_stored)
		to_chat(owner, span_warning("The console has no room left."))
		return
	var/list/loose = list()
	for(var/obj/item/I in get_turf(claw))
		if(!I.anchored)
			loose += I
	if(!length(loose))
		to_chat(owner, span_warning("There is nothing loose under the claw."))
		return
	var/obj/item/chosen = length(loose) == 1 ? loose[1] \
		: tgui_input_list(owner, "Lift which item?", "Manipulator", loose)
	if(!chosen || QDELETED(chosen) || chosen.loc != get_turf(claw))
		return
	claw.Reach(CALLBACK(claw, TYPE_PROC_REF(/obj/machinery/lce_claw, DoGrab), WEAKREF(chosen)))

/datum/action/innate/lce_claw/lower
	name = "Lower"
	desc = "Set one of the console's stored items down on the floor beneath the claw."
	button_icon_state = "claw_lower"

/datum/action/innate/lce_claw/lower/Activate()
	if(!CheckClaw())
		return
	if(!length(console.contents))
		to_chat(owner, span_warning("The console is empty."))
		return
	var/obj/item/chosen = tgui_input_list(owner, "Lower which item?", "Manipulator", console.contents.Copy())
	if(!chosen || QDELETED(chosen) || chosen.loc != console)
		return
	claw.Reach(CALLBACK(claw, TYPE_PROC_REF(/obj/machinery/lce_claw, DoLower), WEAKREF(chosen)))

/datum/action/innate/lce_claw/unload
	name = "Empty Container"
	desc = "Tip out a bag or box lying under the claw, leaving its contents where it stands."
	button_icon_state = "claw_unload"

/datum/action/innate/lce_claw/unload/Activate()
	if(!CheckClaw())
		return
	var/list/containers = list()
	for(var/obj/item/storage/S in get_turf(claw))
		containers += S
	if(!length(containers))
		to_chat(owner, span_warning("There is nothing under the claw that holds anything."))
		return
	var/obj/item/storage/chosen = length(containers) == 1 ? containers[1] \
		: tgui_input_list(owner, "Empty which container?", "Manipulator", containers)
	if(!chosen || QDELETED(chosen) || chosen.loc != get_turf(claw))
		return
	claw.Reach(CALLBACK(claw, TYPE_PROC_REF(/obj/machinery/lce_claw, DoUnload), WEAKREF(chosen)))

/obj/machinery/lce_claw/proc/DoUnload(datum/weakref/storage_ref)
	var/obj/item/storage/S = storage_ref?.resolve()
	if(!S || S.loc != get_turf(src))
		Miss()
		return
	//This codebase is on the old /datum/component/storage; the signal is the supported way in.
	SEND_SIGNAL(S, COMSIG_TRY_STORAGE_QUICK_EMPTY, get_turf(S))
	visible_message(span_notice("[src] tips [S] out."))

/datum/action/innate/lce_claw/scan
	name = "Scan Specimen"
	desc = "Run a five-stage extraction on whatever is under the claw. It costs the specimen \
		hunger and mood, and it will not finish if they walk away."
	button_icon_state = "claw_scan"

/datum/action/innate/lce_claw/scan/Activate()
	if(!CheckClaw())
		return
	var/list/subjects = list()
	for(var/mob/living/simple_animal/hostile/limbus_abno/A in get_turf(claw))
		if(A.stat >= DEAD)
			continue
		subjects += A
	if(!length(subjects))
		to_chat(owner, span_warning("There is no specimen under the claw."))
		return
	var/mob/living/simple_animal/hostile/limbus_abno/chosen = length(subjects) == 1 ? subjects[1] \
		: tgui_input_list(owner, "Scan which specimen?", "Manipulator", subjects)
	if(!chosen || QDELETED(chosen) || chosen.loc != get_turf(claw))
		return
	if(chosen.desire_bar < LCE_SCAN_FLOOR || chosen.hunger_bar < LCE_SCAN_FLOOR)
		to_chat(owner, span_warning("[chosen] is too depleted to scan."))
		return
	claw.ScanSpecimen(chosen, owner)

/datum/action/innate/lce_claw/spray
	name = "Rinse"
	desc = "Spend ten units of water hosing down the floor under the claw."
	button_icon_state = "claw_rinse"

/datum/action/innate/lce_claw/spray/Activate()
	if(!CheckClaw())
		return
	if(console.reagents.get_reagent_amount(/datum/reagent/water) < LCE_CLAW_SPRAY_COST)
		to_chat(owner, span_warning("The tank is too low. Refill the console."))
		return
	console.reagents.remove_reagent(/datum/reagent/water, LCE_CLAW_SPRAY_COST)
	claw.Spray(owner)

//Water and cleaning are two separate mechanisms in this codebase and the claw needs both:
///datum/reagent/water only washes ACID off things, but it IS what pops monkey cubes; the actual
//scrubbing has to be an explicit wash() the way the shower does it.
/obj/machinery/lce_claw/proc/Spray(mob/user)
	set waitfor = FALSE
	if(busy)
		return
	SetBusy(1 SECONDS)
	var/turf/centre = get_turf(src)
	animate(src, pixel_z = -8, time = 2)
	playsound(src, 'sound/effects/extinguish.ogg', 60, TRUE, -3)
	sleep(2)
	if(QDELETED(src))
		return
	var/list/targets = list(centre)
	for(var/direction in GLOB.cardinals)
		var/turf/T = get_step(centre, direction)
		if(T)
			targets += T
	for(var/i in 1 to LCE_CLAW_SPRAY_STREAMS)
		var/obj/effect/particle_effect/water/W = new(centre)
		W.reagents = new /datum/reagents(5)
		W.reagents.my_atom = W
		//2u rather than the extinguisher's 1u: several downstream thresholds sit exactly on 1.
		W.reagents.add_reagent(/datum/reagent/water, 2)
		var/turf/destination = pick(targets)
		step_towards(W, destination)
		if(QDELETED(W))
			continue
		var/turf/here = get_turf(W)
		W.reagents.expose(here)
		for(var/atom/A in here)
			W.reagents.expose(A)
	//The scrub. /turf/wash() handles the mopable movables on the tile itself.
	for(var/turf/T in targets)
		T.wash(CLEAN_WASH)
		for(var/atom/movable/AM in T)
			if(ismopable(AM))
				continue
			AM.wash(CLEAN_WASH)
	animate(src, pixel_z = 0, time = 2)
	sleep(2)
	if(QDELETED(src))
		return
	ClearBusy()

/*			SCAN			*/

//The scanline. Lives in the specimen's vis_contents so it tracks them, and is clipped to their
//silhouette by an alpha mask fed from their own render output - render_source rather than an
//icon() mask because LCL specimens are frequently 48x48 or 64x64 (an icon() mask only covers
//32x32) and because several of them swap sprite mid-round.
/obj/effect/lce_scanline
	icon = 'icons/effects/effects.dmi'
	icon_state = "transform_effect"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_ID
	plane = FLOAT_PLANE
	layer = FLOAT_LAYER
	appearance_flags = KEEP_TOGETHER
	anchored = TRUE

/obj/machinery/lce_claw/proc/StartScanVisual(mob/living/subject)
	if(QDELETED(subject))
		return null
	var/obj/effect/lce_scanline/line = new(subject)
	//No leading asterisk: with one, BYOND stops drawing the subject normally and only uses it as
	//a render source, which would make the specimen invisible for the whole scan.
	if(!subject.render_target)
		subject.render_target = "lce_scan_[REF(subject)]"
	line.filters += filter(type = "alpha", render_source = subject.render_target)
	subject.vis_contents += line
	return line

/obj/machinery/lce_claw/proc/SweepScanVisual(obj/effect/lce_scanline/line)
	if(QDELETED(line))
		return
	line.pixel_y = 16
	animate(line, pixel_y = -16, time = LCE_SCAN_STAGE_TIME)

/obj/machinery/lce_claw/proc/EndScanVisual(obj/effect/lce_scanline/line, mob/living/subject)
	if(!QDELETED(subject))
		subject.vis_contents -= line
		subject.render_target = null
	if(!QDELETED(line))
		qdel(line)

///How full the specimen was when we started. Sampled ONCE, before any draining, so a scan cannot
///erode its own payout and the number the operator sees is the number they get.
/obj/machinery/lce_claw/proc/ScanQuality(mob/living/simple_animal/hostile/limbus_abno/subject)
	var/list/fractions = list()
	if(subject.max_desire > 0)
		fractions += subject.desire_bar / subject.max_desire
	if(subject.max_hunger > 0)
		fractions += subject.hunger_bar / subject.max_hunger
	//7 of the 11 specimens have no counter at all, so it only counts when there is one.
	if(subject.max_counter > 0)
		fractions += subject.counter / subject.max_counter
	if(!length(fractions))
		return 0.5
	var/total = 0
	for(var/frac in fractions)
		total += frac
	return clamp(total / length(fractions), 0, 1)

///TRUE while the claw is still over the specimen and still ours.
/obj/machinery/lce_claw/proc/ScanStillValid(mob/living/subject)
	return !QDELETED(src) && !QDELETED(subject) && console && console.claw == src \
		&& subject.loc == get_turf(src)

//Five stages, one do_after each. The drain is CLAMPED so hunger and desire can never be taken
//below LCE_SCAN_FLOOR: almost every specimen overrides AdjustDesire/AdjustHunger into breach
//logic - Mountain breaches at counter 0, Queen Bee vents spores at desire 0, Scorched Girl
//detonates at counter 0 and desire 0 ignoring her own cooldown - so a scan must never be the
//thing that empties a bar. It can leave a specimen vulnerable; it cannot pull the trigger.
/obj/machinery/lce_claw/proc/ScanSpecimen(mob/living/simple_animal/hostile/limbus_abno/subject, mob/living/pilot)
	set waitfor = FALSE
	if(busy || QDELETED(subject) || !console)
		return
	var/quality = ScanQuality(subject)
	var/stages_done = 0
	//Pins the claw for the whole sequence - busy also gates the eye's movement.
	SetBusy(LCE_SCAN_STAGES * LCE_SCAN_STAGE_TIME)
	var/obj/effect/lce_scanline/line = StartScanVisual(subject)
	to_chat(subject, span_warning("Something cold passes over you, and keeps passing."))

	for(var/stage in 1 to LCE_SCAN_STAGES)
		if(!ScanStillValid(subject))
			break
		//Re-checked every stage, not just at the start: five stages of drain from a bar that was
		//only just above the floor would otherwise walk it straight through.
		var/desire_room = subject.desire_bar - LCE_SCAN_FLOOR
		var/hunger_room = subject.hunger_bar - LCE_SCAN_FLOOR
		if(desire_room <= 0 || hunger_room <= 0)
			to_chat(pilot, span_warning("The reading flattens out. There is nothing left to draw on."))
			break
		SweepScanVisual(line)
		//The specimen is the do_after target, which is what makes walking away cancel it - the
		//helper snapshots target.loc and breaks the moment it changes.
		if(!do_after(pilot, LCE_SCAN_STAGE_TIME, subject, IGNORE_HELD_ITEM, TRUE, \
			CALLBACK(src, PROC_REF(ScanStillValid), subject)))
			to_chat(pilot, span_warning("The scan breaks off."))
			break
		subject.AdjustDesire(-min(rand(LCE_SCAN_DRAIN_MIN, LCE_SCAN_DRAIN_MAX), desire_room))
		subject.AdjustHunger(-min(rand(LCE_SCAN_DRAIN_MIN, LCE_SCAN_DRAIN_MAX), hunger_room))
		stages_done++
		playsound(src, 'sound/machines/terminal_prompt.ogg', 30, TRUE)

	EndScanVisual(line, subject)
	ClearBusy()
	if(!stages_done)
		to_chat(pilot, span_warning("Nothing was drawn out."))
		return
	YieldEnkephalin(stages_done, quality, pilot)

/obj/machinery/lce_claw/proc/YieldEnkephalin(count, quality, mob/living/pilot)
	var/turf/here = get_turf(src)
	var/stored = 0
	for(var/i in 1 to count)
		var/obj/item/unstable_enkephalin/box = new(here, quality)
		//Straight into the console if there is room, since that is where the claw puts everything
		//else; the floor is the fallback.
		if(console && length(console.contents) < console.max_stored)
			box.forceMove(console)
			stored++
	to_chat(pilot, span_notice("[count] canister\s of unstable enkephalin, around \
		[round(quality * 100)]% charge[stored < count ? " - [count - stored] would not fit and are on the floor" : ""]."))
	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 40, TRUE)

#undef LCE_CLAW_REACH_TIME
#undef LCE_CLAW_SPRAY_COST
#undef LCE_CLAW_SPRAY_STREAMS
#undef LCE_SCAN_STAGES
#undef LCE_SCAN_STAGE_TIME
#undef LCE_SCAN_DRAIN_MIN
#undef LCE_SCAN_DRAIN_MAX
#undef LCE_SCAN_FLOOR
