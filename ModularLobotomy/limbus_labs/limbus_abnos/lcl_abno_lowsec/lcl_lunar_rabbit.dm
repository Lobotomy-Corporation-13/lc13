//Lunar Physician, on the LCL base. Dextrous: mixes chems into a held container via a TGUI
//window. Counter drifts on the hunger tick; at 0 she is offered a breach that lets her crawl
//under doors.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit
	true_name = "Lunar Physician"
	original_abno = /mob/living/simple_animal/hostile/abnormality/lunar_rabbit
	maxHealth = 500
	health = 500
	speed = 0.5 //Lower is faster. Every other LCL specimen leaves this at the default 1.
	rapid_melee = 2
	melee_damage_lower = 2
	melee_damage_upper = 25
	melee_damage_type = BLACK_DAMAGE
	attack_verb_continuous = "cuts"
	attack_verb_simple = "cut"
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 2)
	attack_sound = 'sound/abnormalities/cleave.ogg'
	dextrous = TRUE
	held_items = list(null, null)
	possible_a_intents = list(INTENT_HELP, INTENT_GRAB, INTENT_DISARM, INTENT_HARM)
	diet_list = list(
		/obj/item/food/bnuuypudding,
		/obj/item/food/rcorppudding,
		/obj/item/food/myopudding,
		/obj/item/food/mattpudding,
		/obj/item/food/zilupudding,
		/obj/item/food/mumupudding,
		/obj/item/kitchen/knife/shiv/carrot,
		/obj/item/food/cake/carrot,
		/obj/item/food/cakeslice/carrot,
		/obj/item/food/carrotfries,
		/obj/item/food/grown/carrot,
		/obj/item/food/mochi,
	)
	diet_value = 15
	desire_on_eat = 10
	//-0.8 desire per point of post-resistance damage. At or below 100 health the base takes the
	//threshold branch instead and any hit empties the bar.
	rep_desire_gain = -0.8
	rep_threshold = 100
	rep_desire_loss_at_threshold = 100
	desire_on_pet = -5
	//Insight: likes chem equipment, hates surveillance and barriers.
	insight_cooldown_time = 45 SECONDS
	liked_objects_list = list(/obj/item/reagent_containers/glass/beaker, /obj/machinery/chem_master, /obj/machinery/chem_dispenser, /obj/item/reagent_containers/syringe)
	liked_objects_value = 1
	hated_objects_list = list(/obj/structure/barrier_tape, /obj/item/barrier_taperoll, /obj/machinery/camera, /obj/structure/barricade/security)
	hated_objects_value = 8
	hunger_cooldown_time = 3 MINUTES
	//Counter drift runs on the hunger tick, not on individual desire changes.
	max_counter = 3
	attack_action_types = list(/datum/action/cooldown/limbus_abno_action/lunar_dispensary)
	attunement_family = "acupuncture"
	ego_list = list(/datum/ego_datum/armor/lce/acupuncture)
	abno_additional_instructions = "You like instinct and insight. You're a physician with a sense of humour, your paws are as clever as any surgeon's, and you are faster than anything else down here. \
	Carrots, puddings and handmade mochi keep your instincts quiet, so eat your fill, and a tidy room full of beakers and syringes puts you in a good mood. \
	Hold a bottle or beaker and open your Dispensary to brew any chemical you please, then name and colour each dose however you like. What the label says is entirely up to you. \
	Mixing is the work you enjoy, so every dose you make lifts your mood - but it costs you 5 hunger a time, so keep yourself fed if you want to keep working. \
	You do not take being hurt well at all - every blow sours you, and once you are badly wounded a single one is enough to ruin your mood completely, so do not let anyone corner you. \
	You cannot stand being policed or watched either, so asset protection, barrier tape and cameras will all sour your mood - it is very hard to get away with anything with a camera in the room."
	///Rate-limit for the proximity aversion below.
	var/next_aversion_check = 0
	///Roles whose presence costs her desire.
	var/list/disliked_roles = list("LC Asset Protection", "LCA Udjat Leader", "LCA Udjat Agent")
	///Lazily-created host for the Dispensary TGUI window.
	var/datum/tgui_handler/lunar_dispensary/dispensary_ui = null
	// --- Counter drift, all evaluated on the hunger tick ---
	///At or above this Desire the counter climbs.
	var/counter_gain_desire = 80
	///At or below this Desire it falls.
	var/counter_loss_desire = 30
	///At or below this Hunger the tick also costs her Desire.
	var/famine_hunger = 20
	var/famine_desire_loss = 20
	// --- Breach ---
	///TRUE while the breach alert is up. She never breaches on her own.
	var/breach_ready = FALSE
	///Dropping below this while breached ends it.
	var/breach_break_health = 100
	///Breached only: how long squeezing under a door takes.
	var/crawl_time = 3 SECONDS
	var/crawling = FALSE

//original_abno's sprite is 1-direction; Branch 12's moon_rabbit has a 4-direction sheet.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/Initialize(mapload)
	. = ..()
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/32x32.dmi'
	icon_state = "moon_rabbit"
	icon_living = "moon_rabbit"

/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/Destroy()
	QDEL_NULL(dispensary_ui)
	return ..()

//Rebirth re-copies the contained sprite, so re-apply.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/Rebirth()
	..()
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/32x32.dmi'
	icon_state = "moon_rabbit"
	icon_living = "moon_rabbit"

/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/is_literate()
	return TRUE

//The base InsightRoomCheck uses is_path_in_list (exact type), but tape/cameras have subtypes.
//Override the scan to use istype so every variant counts as hated.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/InsightRoomCheck()
	var/room_score = 0
	var/list/room_obj_list = list()
	for(var/obj/O in view(5, src))
		room_obj_list += O
		if(is_type_in_list(O, liked_objects_list))
			room_score += liked_objects_value
		if(is_type_in_list(O, hated_objects_list))
			room_score -= hated_objects_value
	InsightRoomResults(room_score, room_obj_list)

//Loses desire while a disliked_roles human is in view. Objects are handled by InsightRoomCheck.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/Life()
	. = ..()
	if(world.time < next_aversion_check)
		return
	next_aversion_check = world.time + 30 SECONDS
	for(var/mob/living/carbon/human/H in view(5, src))
		var/role = H.mind?.assigned_role
		if(role in disliked_roles)
			AdjustDesire(-3)
			manual_emote("bristles at the [role] nearby.")
			break

//Life() calls this once per hunger_cooldown_time, so the counter drift hangs off it.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/Hungrier(hungry_amount, bypass_check = TRUE)
	. = ..()
	//Mirrors the base guard: skip if the base did not actually tick.
	if(!hunger_active && !bypass_check)
		return
	if(stat >= DEAD)
		return
	//Applied before the counter check, so a famine tick can drop her into the losing band.
	if(hunger_bar <= famine_hunger)
		to_chat(src, span_warning("You are too hungry to enjoy any of this."))
		AdjustDesire(-famine_desire_loss)
	if(desire_bar >= counter_gain_desire)
		if(counter < max_counter)
			AdjustCounter(1)
	else if(desire_bar <= counter_loss_desire)
		AdjustCounter(-1)

//Counter is frozen while breached; any change re-checks the offer.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/AdjustCounter(counter_amount)
	if(breached)
		return
	. = ..()
	UpdateBreachOffer()

///Counter 0 throws a clickable alert instead of breaching. The counter climbing back clears it.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/proc/UpdateBreachOffer()
	if(breached || counter > 0 || stat >= DEAD)
		if(breach_ready)
			breach_ready = FALSE
			clear_alert("lunar_breach")
			to_chat(src, span_nicegreen("You settle. There is still work to do here."))
		return
	if(breach_ready)
		return
	breach_ready = TRUE
	throw_alert("lunar_breach", /atom/movable/screen/alert/lunar_breach)
	to_chat(src, span_userdanger("You have had quite enough of this room. The doors are only \
		doors - click the warning on your screen when you want to leave."))

///Accepting: full heal, unstable, and the door crawl unlocks.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/proc/AcceptBreach()
	if(breached || !breach_ready || stat >= DEAD)
		return FALSE
	breach_ready = FALSE
	clear_alert("lunar_breach")
	Breach()
	adjustHealth(-maxHealth) //Full restoration, same idiom the Punishing Bird uses.
	manual_emote("shakes herself off and drops onto all fours.")
	to_chat(src, span_userdanger("You feel completely well again. Attack a door and you can \
		squeeze under it - it takes a few seconds, so pick your moment."))
	playsound(get_turf(src), 'sound/abnormalities/cleave.ogg', 50, 1)
	return TRUE

///Ends the breach. Restores the counter so the offer is not thrown again immediately.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/Unbreach()
	if(IsContained())
		return
	crawling = FALSE
	manual_emote("stops, and picks herself up off the floor.")
	to_chat(src, span_userdanger("That is enough of that. You are in no state to keep running."))
	AdjustCounter(max_counter)
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/updatehealth()
	. = ..()
	if(!IsContained() && health < breach_break_health)
		Unbreach()

/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/death()
	breach_ready = FALSE
	clear_alert("lunar_breach")
	Unbreach()
	return ..()

/atom/movable/screen/alert/lunar_breach
	name = "The Doors Are Only Doors"
	desc = "You have had enough of being kept. Click this to go, and you will be whole again and \
		small enough to squeeze under any door in the wing. A solid beating will put a stop to it."
	icon = 'ModularLobotomy/_Lobotomyicons/abno_hud.dmi'
	icon_state = "lunar_breach"

/atom/movable/screen/alert/lunar_breach/Click(location, control, params)
	. = ..() //The parent handles the shift-click "examine" path, which prints name + desc.
	if(!usr || usr != owner)
		return
	var/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/rabbit = owner
	if(!istype(rabbit))
		return
	rabbit.AcceptBreach()

//Breached only: attacking a door crawls under it instead. Same forceMove as lc13_cuckoospawn.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/AttackingTarget(atom/attacked_target)
	if(breached && istype(attacked_target, /obj/machinery/door))
		CrawlUnder(attacked_target)
		return
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/proc/CrawlUnder(obj/machinery/door/D)
	if(crawling || QDELETED(D))
		return
	crawling = TRUE
	manual_emote("flattens out and starts working her way under [D]...")
	balloon_alert(src, "squeezing under...")
	if(do_after(src, crawl_time, D))
		//Re-checked: the door or her position can change during the do_after.
		if(!QDELETED(D) && breached && Adjacent(D))
			forceMove(get_turf(D))
			manual_emote("crawls under [D]!")
			playsound(get_turf(src), 'sound/effects/slosh.ogg', 40, 1)
	crawling = FALSE

//Non-harm clicks route through attack_hand so machine UIs open; harm intent attacks instead.
//Eating is done by attacking yourself with a held diet food, see attackby.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/UnarmedAttack(atom/A, proximity)
	if(isliving(A))
		var/mob/living/L = A
		if(IsFriend(L) && !attack_friend)
			to_chat(src, span_warning("You don't feel like hurting [L], they're on your side."))
			return
		AttackingTarget(A)
		return
	if(dextrous && isitem(A))
		A.attack_hand(src)
		update_inv_hands()
		return
	if(a_intent == INTENT_HARM)
		AttackingTarget(A) //Harm intent: smash the machine/structure instead.
		return
	A.attack_hand(src) //Machines, consoles, etc: interact like a person.

//Diet food short-circuits the base attackby, so RepressionWork only runs for non-food hits.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/attackby(obj/item/W, mob/user, params)
	if(is_type_in_list(W, diet_list))
		AbnoEat(W)
		return TRUE
	return ..()

//The Dispensary: opens a chem-dispenser-style window to fill/inspect a held container and
//rename or recolour the individual chemicals inside it. Logic lives on the handler datum
//in lcl_tools/lcl_dispensary_ui.dm.
/datum/action/cooldown/limbus_abno_action/lunar_dispensary
	name = "Dispensary"
	desc = "Open your dispensary to brew chemicals into a container you are holding, and to rename or recolour what is inside. Each dose you mix costs 5 hunger and lifts your mood by 10."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_lunar"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	button_icon_state = "dispensary"
	transparent_when_unavailable = TRUE
	cooldown_time = 1 SECONDS

/datum/action/cooldown/limbus_abno_action/lunar_dispensary/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	if(abno_user.hunger_bar < 10)
		return FALSE

/datum/action/cooldown/limbus_abno_action/lunar_dispensary/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/rabbit = abno_user
	if(isnull(rabbit.dispensary_ui))
		rabbit.dispensary_ui = new(rabbit)
	rabbit.dispensary_ui.ui_interact(rabbit)
	return TRUE

//--------------------------------------
// Lunar Physician "Dispensary" TGUI
//--------------------------------------
// A chem-dispenser-style window for the Lunar Physician LCL abno. It dispenses reagents
// into the container the abno is holding, shows the container's current contents, and
// lets the abno rename and recolour each individual chemical inside (only that
// container's copy of the reagent is affected). Hosted by a lightweight handler datum
// owned by the abno; the held container is read fresh each refresh.

// The reagents the Dispensary can produce.
// Changed to LC13's chemicals to be less destructive.
GLOBAL_LIST_INIT(lunar_dispensary_reagent_types, list(
	/datum/reagent/oxalite,
	/datum/reagent/hydrene,
	/datum/reagent/xenotride,
	/datum/reagent/lithene,
	/datum/reagent/ferroxan,
	/datum/reagent/virothane,
	/datum/reagent/synthryl,
	/datum/reagent/purite,
	/datum/reagent/omnicarbide,
	/datum/reagent/velocium,
	/datum/reagent/cryostraline,
	/datum/reagent/nexalite,
	/datum/reagent/thermate,
	/datum/reagent/verdite,
	/datum/reagent/ionovium,
	/datum/reagent/drug/enkephalin,
))

// Sorted [name, id] list of the dispensable reagents, built once (compile-time static).
GLOBAL_LIST_EMPTY(lunar_dispensary_chems)

/proc/get_lunar_dispensary_chems()
	if(length(GLOB.lunar_dispensary_chems))
		return GLOB.lunar_dispensary_chems
	var/list/name_list = list()
	var/list/name_to_id = list()
	for(var/rtype in GLOB.lunar_dispensary_reagent_types)
		var/datum/reagent/R = GLOB.chemical_reagents_list[rtype]
		if(R && length(R.name) && isnull(name_to_id[R.name]))
			name_list += R.name
			name_to_id[R.name] = ckey(R.name)
	name_list = sortList(name_list)
	for(var/nm in name_list)
		GLOB.lunar_dispensary_chems += list(list("name" = nm, "id" = name_to_id[nm]))
	return GLOB.lunar_dispensary_chems

/datum/tgui_handler/lunar_dispensary
	/// The abno that owns and operates this dispensary.
	var/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/abno = null
	/// How much of a reagent a single dispense adds.
	var/amount = 10
	/// World.time before which the container cannot be purged again.
	var/next_purge = 0
	/// Cooldown between full container purges.
	var/purge_cooldown = 1 MINUTES
	/// Mixing a dose is her work: it costs her stomach and pays her mood.
	var/hunger_per_dispense = 5
	var/desire_per_dispense = 10

/datum/tgui_handler/lunar_dispensary/New(mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/owner)
	abno = owner

/datum/tgui_handler/lunar_dispensary/Destroy()
	abno = null
	return ..()

/datum/tgui_handler/lunar_dispensary/ui_host(mob/user)
	return abno

/datum/tgui_handler/lunar_dispensary/ui_status(mob/user)
	if(user != abno || isnull(abno) || abno.stat >= DEAD)
		return UI_CLOSE
	return UI_INTERACTIVE

/datum/tgui_handler/lunar_dispensary/ui_state(mob/user)
	return GLOB.always_state

/datum/tgui_handler/lunar_dispensary/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "LunarDispensary", "Dispensary")
		ui.open()

// Returns the reagent container the abno is currently holding, or null.
/datum/tgui_handler/lunar_dispensary/proc/GetContainer()
	if(isnull(abno))
		return null
	var/obj/item/reagent_containers/held = abno.get_active_held_item()
	return istype(held) ? held : null

/datum/tgui_handler/lunar_dispensary/ui_data(mob/user)
	var/list/data = list()
	data["amount"] = amount
	var/obj/item/reagent_containers/held = GetContainer()
	data["hasContainer"] = held ? TRUE : FALSE
	data["containerName"] = held ? held.name : null
	var/list/contents = list()
	var/current = 0
	if(held && held.reagents)
		for(var/datum/reagent/R in held.reagents.reagent_list)
			contents += list(list(
				"id" = "[R.type]",
				"name" = R.name,
				"volume" = R.volume,
				"color" = R.color,
			))
			current += R.volume
	data["contents"] = contents
	data["currentVolume"] = held ? current : null
	data["maxVolume"] = (held && held.reagents) ? held.reagents.maximum_volume : null
	data["purgeReady"] = world.time >= next_purge
	data["chemicals"] = get_lunar_dispensary_chems()
	return data

/datum/tgui_handler/lunar_dispensary/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	if(isnull(abno) || abno.stat >= DEAD)
		return
	var/obj/item/reagent_containers/held = GetContainer()
	switch(action)
		if("amount")
			amount = clamp(text2num(params["amount"]), 1, 100)
			. = TRUE
		if("dispense")
			if(!held || !held.reagents)
				return
			var/rtype = GLOB.name2reagent[params["reagent"]]
			if(!rtype || !(rtype in GLOB.lunar_dispensary_reagent_types))
				return
			var/free = held.reagents.maximum_volume - held.reagents.total_volume
			var/actual = min(amount, free)
			if(actual <= 0)
				to_chat(abno, span_warning("[held] is full."))
				return
			//Checked before the reagent is added, so a refused dispense is never charged.
			if(abno.hunger_bar < hunger_per_dispense)
				to_chat(abno, span_warning("You are far too hungry to concentrate on mixing."))
				return
			held.reagents.add_reagent(rtype, actual)
			held.update_icon()
			abno.AdjustHunger(-hunger_per_dispense)
			abno.AdjustDesire(desire_per_dispense)
			. = TRUE
		if("remove")
			if(!held || !held.reagents)
				return
			var/rtype = text2path(params["id"])
			if(!rtype)
				return
			held.reagents.del_reagent(rtype)
			held.update_icon()
			. = TRUE
		if("purge")
			if(!held || !held.reagents)
				return
			if(world.time < next_purge)
				to_chat(abno, span_warning("You need to catch your breath before purging again."))
				return
			next_purge = world.time + purge_cooldown
			held.reagents.clear_reagents()
			held.update_icon()
			. = TRUE
		if("rename")
			var/datum/reagent/R = held ? held.reagents.get_reagent(text2path(params["id"])) : null
			if(!R)
				return
			var/newname = stripped_input(abno, "Rename [R.name]? (blank to skip)", "Dispensary", R.name, MAX_NAME_LEN)
			if(newname && newname != R.name)
				R.name = newname
			. = TRUE
		if("recolor")
			var/datum/reagent/R = held ? held.reagents.get_reagent(text2path(params["id"])) : null
			if(!R)
				return
			var/col = input(abno, "Recolour [R.name]? (cancel to skip)", "Dispensary", R.color) as color|null
			if(col)
				R.color = col
				held.update_icon()
			. = TRUE
	if(.)
		SStgui.update_uis(src)
