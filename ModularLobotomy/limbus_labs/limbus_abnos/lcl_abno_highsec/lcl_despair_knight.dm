//Knight of Despair, on the LCL base. Blesses one human, manifests beside them as a camera mob
//while her body crystallises, and breaches if that human dies or goes insane.

//Breach rapier. Base is 40 PALE; -20% for 120-HP agents.
/obj/projectile/despair_rapier/lcl
	damage = 32

/mob/living/simple_animal/hostile/limbus_abno/despair_knight
	true_name = "Knight of Despair"
	original_abno = /mob/living/simple_animal/hostile/abnormality/despair_knight
	maxHealth = 2000
	health = 2000
	pixel_x = -8
	base_pixel_x = -8
	ranged = TRUE
	ranged_cooldown_time = 3 SECONDS
	melee_damage_lower = 15
	melee_damage_upper = 20
	melee_damage_type = WHITE_DAMAGE
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 1.0, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 0.5)
	attack_sound = 'sound/abnormalities/despairknight/attack.ogg'
	desire_on_pet = 20
	insight_cooldown_time = 40 SECONDS
	liked_objects_list = list(/obj/item/toy/plush, /obj/item/ego_weapon, /obj/item/clothing/suit/armor/ego_gear)
	liked_objects_value = 5
	desire_on_eat = 5
	diet_value = 30
	diet_list = list(/obj/item/food/frozen_treats/despaired_delight)
	rep_desire_gain = 3
	hunger_cooldown_time = 3 MINUTES
	max_counter = 0 //No counter: losing the blessed is the only breach trigger.
	// A knight has hands, same as her sister.
	dextrous = TRUE
	held_items = list(null, null)
	attunement_family = "despair"
	ego_list = list(/datum/ego_datum/armor/lce/despair)
	attack_action_types = list(
		/datum/action/cooldown/limbus_abno_action/despair_bless,
		/datum/action/cooldown/limbus_abno_action/despair_whisper,
		/datum/action/cooldown/limbus_abno_action/despair_manifest,
		/datum/action/cooldown/limbus_abno_action/despair_defend_tp,
		/datum/action/cooldown/limbus_abno_action/despair_rapidfire,
		/datum/action/cooldown/limbus_abno_action/despair_slash,
		/datum/action/cooldown/limbus_abno_action/despair_retort,
	)
	abno_additional_instructions = "You like attachment and insight. You are a knight who lives only to protect someone, anyone. \
	Choose one human and bless them: whisper into their mind, and manifest at their side as a ghostly guardian only they can see. \
	Only while manifested do you truly watch over them, hearing and seeing all that surrounds them. While you are manifested your \
	true body hardens into crystal, near-untouchable but unable to act until you return. Your vow cannot be taken back while they live, \
	but if they are taken from you, grief will break you - and once the vow is free you may swear it to someone new. \
	If they are gravely hurt you may rush to their side to defend them. You care little for food or for being roughed up, only devotion soothes you - \
	though anything the deep blue of your own tears is another matter, and you will take it from anyone - \
	but if it turns out to be junk, raw, gross or toxic underneath, the colour was a lie and you are worse off for it. \
	And should the one you swore to protect die or lose their mind, grief will shatter you, and you will turn your blades on everything. \
	You have hands, and you can read."
	///The human she currently watches over.
	var/mob/living/carbon/human/blessed_human = null
	///The ghostly projection, while manifested.
	var/mob/camera/despair_manifest/manifest = null
	///TRUE while her body is crystallised (manifested).
	var/crystallized = FALSE
	///Breach state.
	var/breached = FALSE
	///Defend window bookkeeping.
	var/defend_ready = FALSE
	var/defend_window_end = 0
	var/defend_cooldown = 0
	///Affinity a blessing grants. Safe limit = affinity/3, so 75 is +25%.
	var/bless_affinity = 75
	// --- Dark blue food ---
	///Extra Desire on top of desire_on_eat for food that reads as dark blue.
	var/blue_food_desire = 20
	///Minimum blue channel.
	var/blue_min = 60
	///Minimum lead blue must have over red and green.
	var/blue_margin = 30
	///Maximum luminance, so cyan and pastels are excluded.
	var/blue_max_lum = 120
	///Any of these flags voids the blue bonus.
	var/foul_foodtypes = JUNKFOOD | RAW | GROSS | TOXIC
	///Desire lost instead of gained when the food carries a foul flag.
	var/foul_food_desire = 20

/mob/living/simple_animal/hostile/limbus_abno/despair_knight/is_literate()
	return TRUE

/mob/living/simple_animal/hostile/limbus_abno/despair_knight/Initialize(mapload)
	. = ..()
	icon_state = "despair_friendly"
	icon_living = "despair_friendly"

/mob/living/simple_animal/hostile/limbus_abno/despair_knight/Destroy()
	ClearBlessing()
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/despair_knight/Login()
	. = ..()
	if(!. || !client)
		return FALSE
	if(crystallized && !manifest)
		Crystallize(FALSE)
		to_chat(src, span_notice("The crystal sloughs off you. You can move again."))

/mob/living/simple_animal/hostile/limbus_abno/despair_knight/SelfStatusReadout()
	. = ..()
	. += "Blessed: [blessed_human ? blessed_human.real_name : "no one"]"
	. += "State: [breached ? "BREACHED" : (crystallized ? "manifested (crystal)" : "watchful")]"

//A sprite's colour cannot be read at runtime, so food colour is taken from its reagent mix.
///Volume-weighted reagent colour, or the item's own tint. list(r, g, b), or null.
/mob/living/simple_animal/hostile/limbus_abno/despair_knight/proc/FoodColour(atom/food)
	if(istext(food.color))
		return ReadRGB(food.color)
	if(!food.reagents || !length(food.reagents.reagent_list))
		return null
	var/r = 0
	var/g = 0
	var/b = 0
	var/total = 0
	for(var/datum/reagent/R in food.reagents.reagent_list)
		var/list/c = ReadRGB(R.color)
		if(!c || R.volume <= 0)
			continue
		r += c[1] * R.volume
		g += c[2] * R.volume
		b += c[3] * R.volume
		total += R.volume
	if(!total)
		return null
	return list(round(r / total), round(g / total), round(b / total))

///TRUE if the food reads as dark blue. Thresholds calibrated against every reagent colour in
///the game: 24 pass, purples and cyans do not.
/mob/living/simple_animal/hostile/limbus_abno/despair_knight/proc/IsDarkBlue(atom/food)
	var/list/c = FoodColour(food)
	if(!c)
		return FALSE
	if(c[3] < blue_min)
		return FALSE
	if((c[3] - c[1]) < blue_margin || (c[3] - c[2]) < blue_margin)
		return FALSE
	//Without this red guard every purple passes.
	if((c[1] * 2) > c[3])
		return FALSE
	//Dark only.
	if((c[1] * 0.299 + c[2] * 0.587 + c[3] * 0.114) > blue_max_lum)
		return FALSE
	return TRUE

///Foodtype flags, from the item or its edible component.
/mob/living/simple_animal/hostile/limbus_abno/despair_knight/proc/FoodTypes(atom/food)
	if(istype(food, /obj/item/food))
		var/obj/item/food/F = food
		return F.foodtypes
	var/datum/component/edible/E = food.GetComponent(/datum/component/edible)
	return E ? E.foodtypes : NONE

//Dark blue food is edible on top of diet_list and pays blue_food_desire, or costs
//foul_food_desire instead if it carries a foul flag.
/mob/living/simple_animal/hostile/limbus_abno/despair_knight/AbnoEat(atom/food)
	var/blue = IsDarkBlue(food)
	var/foul = blue && (FoodTypes(food) & foul_foodtypes)
	var/list/saved_diet = diet_list
	if(blue && !is_type_in_list(food, diet_list))
		//Swapped in for this call only, so diet_list does not grow. Foul food stays edible so
		//the penalty can land.
		diet_list = diet_list + list(food.type)
	. = ..()
	diet_list = saved_diet
	if(!. || !blue)
		return
	if(foul)
		AdjustDesire(-foul_food_desire)
		to_chat(src, span_warning("The colour was right. What is inside it is not."))
	else
		AdjustDesire(blue_food_desire)
		to_chat(src, span_nicegreen("It is the right colour. For a moment, that is almost a comfort."))

// Blessing - choose a human, watch/hear/whisper, and raise their attunement safe limit.
//Not gated on breached: the only block is someone already holding the blessing.
/mob/living/simple_animal/hostile/limbus_abno/despair_knight/proc/BlessHuman()
	if(blessed_human)
		to_chat(src, span_warning("You have already given your blessing to [blessed_human]. Such a vow cannot be taken back."))
		return
	var/list/nearby = list()
	for(var/mob/living/carbon/human/H in viewers(7, src))
		if(H != src && H.stat < DEAD)
			nearby += H
	if(!length(nearby))
		to_chat(src, span_warning("There is no one nearby to bless."))
		return
	var/mob/living/carbon/human/chosen = input(src, "Choose who to watch over.", "Give Blessing") as null|anything in nearby
	if(!chosen || blessed_human || breached)
		return
	blessed_human = chosen
	//She only perceives their surroundings while directly observing (manifested beside them),
	//so there is no passive hear/see relay to spam her while she sits in her body.
	//QDELETING matters as much as death: cryo deletes the ward's mob outright, and without this
	//the vow was left pointing at a corpse-less ghost of a reference.
	RegisterSignal(chosen, list(COMSIG_LIVING_DEATH, COMSIG_HUMAN_INSANE, COMSIG_PARENT_QDELETING), PROC_REF(OnBlessedLost))
	RegisterSignal(chosen, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(OnBlessedHurt))
	//+25% attunement safe limit for her EGO family.
	var/key = "[chosen.ckey]-[attunement_family]"
	GLOB.lce_attunement_affinity[key] = min(300, (GLOB.lce_attunement_affinity[key] || 0) + bless_affinity)
	RefreshLCEAttunement(chosen, attunement_family)
	chosen.add_overlay(mutable_appearance('ModularLobotomy/_Lobotomyicons/tegu_effects.dmi', "despair", -MUTATIONS_LAYER))
	playsound(get_turf(chosen), 'sound/abnormalities/despairknight/gift.ogg', 50, FALSE, 2)
	to_chat(chosen, span_nicegreen("You feel protected. A distant knight watches over you."))
	to_chat(src, span_hypnophrase("<i>You take [chosen] under your protection.</i>"))
	update_action_buttons()

//Tears down the whole bond: view, manifest, relay, overlay, affinity boost.
/mob/living/simple_animal/hostile/limbus_abno/despair_knight/proc/ClearBlessing()
	if(manifest)
		ReturnToBody()
	if(!blessed_human)
		return
	var/mob/living/carbon/human/H = blessed_human
	//Dropped first, so anything this proc goes on to touch cannot re-enter through a stale vow.
	blessed_human = null
	defend_ready = FALSE
	clear_alert("despair_danger")
	//Keyed by ckey rather than by mob, so it is still worth undoing when the mob has gone.
	if(H.ckey)
		var/key = "[H.ckey]-[attunement_family]"
		GLOB.lce_attunement_affinity[key] = max(0, (GLOB.lce_attunement_affinity[key] || 0) - bless_affinity)
	//Everything below reaches into the ward itself, and this often runs because the ward is being
	//deleted - cryo does exactly that. Touching a mob mid-Destroy is how the vow used to break.
	if(!QDELETED(H))
		UnregisterSignal(H, list(COMSIG_LIVING_DEATH, COMSIG_HUMAN_INSANE, COMSIG_MOB_AFTER_APPLY_DAMGE, COMSIG_PARENT_QDELETING))
		H.cut_overlay(mutable_appearance('ModularLobotomy/_Lobotomyicons/tegu_effects.dmi', "despair", -MUTATIONS_LAYER))
		RefreshLCEAttunement(H, attunement_family)
		to_chat(H, span_warning("The protection over you fades away."))
	update_action_buttons()

//Only breach trigger. Breach() clears the blessing, freeing her to bless again.
/mob/living/simple_animal/hostile/limbus_abno/despair_knight/proc/OnBlessedLost(datum/source)
	SIGNAL_HANDLER
	to_chat(src, span_userdanger("Your blessed one is lost to you. Grief takes hold."))
	INVOKE_ASYNC(src, PROC_REF(Breach))

/mob/living/simple_animal/hostile/limbus_abno/despair_knight/proc/DespairWhisper()
	if(!blessed_human)
		to_chat(src, span_warning("You have no one to whisper to."))
		return
	var/msg = input(src, "Whisper into their mind:", "Blessing") as null|text
	if(!msg || !blessed_human)
		return
	msg = trim(msg)
	if(!msg)
		return
	to_chat(blessed_human, span_hypnophrase("<i>[msg]</i>"))
	to_chat(src, span_notice("You whisper to [blessed_human]: \"[msg]\""))
	log_directed_talk(src, blessed_human, msg, LOG_SAY, "despair blessing")

// Manifest - a controllable ghost projection; the body crystallises while she is out.
/mob/living/simple_animal/hostile/limbus_abno/despair_knight/proc/DoManifest()
	if(communion_view)
		to_chat(src, span_warning("You cannot manifest while communing through your EGO."))
		return
	if(QDELETED(blessed_human) || manifest || crystallized || breached || !mind)
		return
	Crystallize(TRUE)
	manifest = new /mob/camera/despair_manifest(get_turf(blessed_human), src, blessed_human)
	possession_locked = TRUE //The crystal is not vacant, whatever a ghost sees.
	mind.transfer_to(manifest)

//Cannot commune through EGO while manifested (and vice versa - manifest is blocked above).
/mob/living/simple_animal/hostile/limbus_abno/despair_knight/CommuneMenu()
	if(manifest || crystallized)
		to_chat(src, span_warning("You cannot commune while manifested."))
		return
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/despair_knight/proc/ReturnToBody()
	if(!manifest)
		return
	//Dropped BEFORE the mind moves. client.images belongs to the client, not the mob, so once the
	//mind has left the projection its Destroy() finds no client to clean up and the image is
	//stranded in the player's client pointing at a deleted mob.
	manifest.ClearImage()
	if(manifest.mind)
		manifest.mind.transfer_to(src)
	QDEL_NULL(manifest)
	possession_locked = FALSE
	Crystallize(FALSE)

//Crystal state: massively reduced damage, and cannot move/attack/fire while it lasts.
/mob/living/simple_animal/hostile/limbus_abno/despair_knight/proc/Crystallize(active)
	crystallized = active
	if(active)
		ChangeResistances(list(RED_DAMAGE = 0.1, WHITE_DAMAGE = 0.1, BLACK_DAMAGE = 0.1, PALE_DAMAGE = 0.1))
		icon = 'ModularLobotomy/_Lobotomyicons/despair_crystal.dmi'
		icon_state = "despair_crystal"
	else
		ChangeResistances(list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 1.0, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 0.5))
		icon = original_abno.icon
		icon_state = breached ? "despair_breach" : "despair_friendly"
		icon_living = icon_state

/mob/living/simple_animal/hostile/limbus_abno/despair_knight/Move()
	if(crystallized)
		return FALSE
	return ..()

// Defend - alert + a timed teleport when the blessed is gravely hurt.
/mob/living/simple_animal/hostile/limbus_abno/despair_knight/proc/OnBlessedHurt(datum/source, damage, damagetype)
	SIGNAL_HANDLER
	if(QDELETED(blessed_human) || world.time < defend_cooldown)
		return
	var/hp_frac = blessed_human.health / blessed_human.maxHealth
	var/sp_frac = 1
	if(blessed_human.maxSanity)
		sp_frac = blessed_human.sanityhealth / blessed_human.maxSanity
	if(hp_frac >= 0.5 && sp_frac >= 0.5)
		return
	defend_cooldown = world.time + 15 SECONDS
	defend_ready = TRUE
	defend_window_end = world.time + 10 SECONDS
	throw_alert("despair_danger", /atom/movable/screen/alert/despair_danger)
	var/mob/receiver = manifest ? manifest : src
	to_chat(receiver, span_userdanger("[blessed_human] is in grave danger! You may rush to their defence for the next 10 seconds."))
	addtimer(CALLBACK(src, PROC_REF(EndDefendWindow)), 10 SECONDS)
	update_action_buttons()

/mob/living/simple_animal/hostile/limbus_abno/despair_knight/proc/EndDefendWindow()
	defend_ready = FALSE
	clear_alert("despair_danger")
	update_action_buttons()

/mob/living/simple_animal/hostile/limbus_abno/despair_knight/proc/DefendTeleport()
	if(!defend_ready || QDELETED(blessed_human) || crystallized)
		return
	var/turf/ward_turf = get_turf(blessed_human)
	if(!ward_turf) //Nowhere to rush to; forceMove(null) would put her in nullspace.
		return
	var/turf/dest = get_step(ward_turf, pick(GLOB.cardinals))
	if(!dest || dest.density)
		dest = ward_turf
	if(manifest)
		ReturnToBody()
	new /obj/effect/temp_visual/guardian/phase(get_turf(src))
	forceMove(dest)
	new /obj/effect/temp_visual/guardian/phase/out(dest)
	EndDefendWindow()
	to_chat(src, span_nicegreen("You appear at [blessed_human]'s side to defend them."))

// Breach - hostile state with the retuned attack kit.
/mob/living/simple_animal/hostile/limbus_abno/despair_knight/proc/Breach()
	if(breached)
		return
	ClearBlessing()
	breached = TRUE
	unstable = TRUE
	melee_damage_lower = 15
	melee_damage_upper = 20
	icon = original_abno.icon
	icon_state = "despair_breach"
	icon_living = "despair_breach"
	AddBreachEffect()
	manual_emote("shatters into a hostile fury!")
	to_chat(src, span_userdanger("You breach! Grief-stricken, you turn your blades on the facility."))
	update_action_buttons()

//Nearest non-friend living target for the breach attacks (or null).
/mob/living/simple_animal/hostile/limbus_abno/despair_knight/proc/GetBreachTarget()
	var/mob/living/best = null
	var/best_dist = 99
	for(var/mob/living/L in view(9, src))
		if(L == src || IsFriend(L) || L.stat >= DEAD)
			continue
		var/d = get_dist(src, L)
		if(d < best_dist)
			best_dist = d
			best = L
	return best

/mob/living/simple_animal/hostile/limbus_abno/despair_knight/proc/RapidFire(mob/living/tgt)
	if(crystallized)
		return
	if(!tgt)
		tgt = GetBreachTarget()
	if(!tgt)
		to_chat(src, span_warning("There is no target in sight."))
		return
	var/tries = 10
	for(var/round = 1 to 12)
		if(QDELETED(tgt) || tgt.stat >= DEAD)
			break
		if(tries < 1)
			break
		var/turf/T = get_step(get_turf(src), pick(1,4,5,6,8,9,10))
		if(T.density)
			round -= 1
			tries--
			continue
		if(!do_after(src, 2, target = src))
			break
		DeferProjectile(/obj/projectile/despair_rapier/lcl, tgt, T, 3)
		playsound(get_turf(src), 'sound/abnormalities/despairknight/attack.ogg', 25, FALSE, 4)

/mob/living/simple_animal/hostile/limbus_abno/despair_knight/proc/SlashAttack()
	if(crystallized)
		return
	var/mob/living/tgt = GetBreachTarget()
	var/dir_to = tgt ? get_cardinal_dir(get_turf(src), get_turf(tgt)) : dir
	var/turf/source_turf = get_step(get_turf(src), dir_to)
	if(!source_turf)
		return
	playsound(get_turf(src), 'sound/weapons/bladeslice.ogg', 50, FALSE, 5)
	var/list/aoe = list()
	var/upline = (dir_to == NORTH || dir_to == SOUTH) ? EAST : NORTH
	var/downline = (dir_to == NORTH || dir_to == SOUTH) ? WEST : SOUTH
	for(var/turf/T in getline(source_turf, get_ranged_target_turf(source_turf, dir_to, 2)))
		if(T.density)
			break
		aoe |= T
		for(var/turf/Y in getline(T, get_ranged_target_turf(T, upline, 1)))
			if(!Y.density)
				aoe |= Y
		for(var/turf/U in getline(T, get_ranged_target_turf(T, downline, 1)))
			if(!U.density)
				aoe |= U
	for(var/turf/T in aoe)
		new /obj/effect/temp_visual/revenant(T)
	SLEEP_CHECK_DEATH(1 SECONDS)
	for(var/turf/T in aoe)
		new /obj/effect/temp_visual/smash_effect(T)
		HurtInTurf(T, list(), 16, WHITE_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))

/mob/living/simple_animal/hostile/limbus_abno/despair_knight/proc/HopelessRetort()
	if(crystallized)
		return
	var/mob/living/tgt = GetBreachTarget()
	var/dir_to = tgt ? get_cardinal_dir(get_turf(src), get_turf(tgt)) : dir
	var/delay = 3
	for(var/turf/bullet_turf in orange(get_turf(src), 2))
		if(!isopenturf(bullet_turf))
			continue
		DeferProjectile(/obj/projectile/despair_rapier/lcl, get_step(bullet_turf, dir_to), bullet_turf, delay)
		delay++

//Ranged click while breached fires a small volley toward the clicked target.
/mob/living/simple_animal/hostile/limbus_abno/despair_knight/OpenFire(atom/A)
	if(crystallized || !breached)
		return FALSE
	if(!A)
		A = target
	if(!A)
		return FALSE
	ranged_cooldown = world.time + ranged_cooldown_time
	var/tries = 8
	for(var/i = 1 to 4)
		if(tries < 1)
			break
		var/turf/T = get_step(get_turf(src), pick(1,2,4,5,6,8,9,10))
		if(T.density)
			i -= 1
			tries--
			continue
		DeferProjectile(/obj/projectile/despair_rapier/lcl, A, T, 3)
	playsound(get_turf(src), 'sound/abnormalities/despairknight/attack.ogg', 50, FALSE, 4)
	return TRUE

// The ghostly projection mob.
/mob/camera/despair_manifest
	name = "ghostly knight"
	real_name = "ghostly knight"
	desc = "A pale-blue apparition of a sorrowful knight."
	see_in_dark = 8
	lighting_alpha = LIGHTING_PLANE_ALPHA_VISIBLE
	sight = NONE
	see_invisible = SEE_INVISIBLE_LIVING
	invisibility = INVISIBILITY_MAXIMUM
	var/mob/living/simple_animal/hostile/limbus_abno/despair_knight/body
	var/mob/living/carbon/human/blessed
	var/image/current_image
	var/move_delay = 0

/mob/camera/despair_manifest/Initialize(mapload, _body, _blessed)
	. = ..()
	body = _body
	blessed = _blessed
	if(blessed)
		RegisterSignal(blessed, COMSIG_PARENT_QDELETING, PROC_REF(OnBlessedGone))
	var/datum/action/innate/despair_return/R = new
	R.Grant(src)

/mob/camera/despair_manifest/Destroy()
	ClearImage()
	body = null
	blessed = null
	return ..()

///Takes the projection's image back off every client that could be holding it. The body is in
///that list because ReturnToBody() hands the mind over before this mob dies, so by then the
///viewer is the knight, not the projection.
/mob/camera/despair_manifest/proc/ClearImage()
	if(!current_image)
		return
	for(var/client/C in list(client, blessed?.client, body?.client))
		C.images -= current_image
	current_image = null

/mob/camera/despair_manifest/proc/OnBlessedGone(datum/source)
	SIGNAL_HANDLER
	//Deferred: this fires from inside the ward's Destroy(), and the recall moves a player's mind.
	if(body)
		INVOKE_ASYNC(body, TYPE_PROC_REF(/mob/living/simple_animal/hostile/limbus_abno/despair_knight, ReturnToBody))

/mob/camera/despair_manifest/Login()
	. = ..()
	if(!. || !client)
		return FALSE
	//A projection that outlived its ward is a dead end - there is nothing to watch, nothing to
	//move towards, and the body is still crystallised. Never leave anyone logged into one.
	if(QDELETED(blessed))
		to_chat(src, span_warning("The one you watched over is gone. You are drawn back into your body."))
		body?.ReturnToBody()
		return
	to_chat(src, span_notice("<b>You manifest beside [blessed].</b> Only they can see or hear you. Stay close to them."))
	Show()

//A light-blue ghostly image of the knight, shown only to the blessed (and to the manifest).
/mob/camera/despair_manifest/proc/Show()
	if(blessed?.client)
		blessed.client.images.Remove(current_image)
	if(client)
		client.images.Remove(current_image)
	current_image = image('ModularLobotomy/_Lobotomyicons/48x48.dmi', src, "despair_friendly", MOB_LAYER, dir = dir)
	current_image.override = TRUE
	current_image.color = "#8fb8ff"
	current_image.alpha = 160
	current_image.pixel_x = -8
	if(blessed?.client)
		blessed.client.images |= current_image
	if(client)
		client.images |= current_image

/mob/camera/despair_manifest/Move(atom/newloc, direction)
	if(world.time < move_delay)
		return FALSE
	if(QDELETED(blessed) || get_dist(newloc, blessed) > 9)
		to_chat(src, span_warning("You cannot drift so far from the one you watch over."))
		recall()
		return FALSE
	forceMove(newloc)
	move_delay = world.time + 1

/mob/camera/despair_manifest/forceMove(atom/destination)
	dir = get_dir(get_turf(src), destination)
	. = ..()
	Show()

/mob/camera/despair_manifest/proc/recall()
	var/turf/home = QDELETED(blessed) ? null : get_turf(blessed)
	//No ward left to snap back to. forceMove(null) here would leave the player's client sitting in
	//a nullspace camera with nothing to look at and no way back out of it.
	if(!home)
		body?.ReturnToBody()
		return
	forceMove(home)

//Speech only reaches the blessed (and the manifest itself).
/mob/camera/despair_manifest/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(!message)
		return
	message = capitalize(trim(copytext_char(sanitize(message), 1, MAX_MESSAGE_LEN)))
	if(!message)
		return
	var/rendered = "<span class='game say'>[span_name("[name]")] <span class='message'>whispers, \"[message]\"</span></span>"
	to_chat(blessed, rendered)
	to_chat(src, rendered)
	//Runechat above the ghost, seen only by the blessed (and the projection itself).
	if(blessed?.client)
		blessed.create_chat_message(src, language, message, spans)
	if(client)
		create_chat_message(src, language, message, spans)
	for(var/mob/dead/observer/O in GLOB.dead_mob_list)
		to_chat(O, rendered)

//While manifested she hears the room around her blessed directly, like any mob standing there.
/mob/camera/despair_manifest/Hear(message, atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, list/message_mods = list())
	if(client?.prefs?.chat_on_map && (client.prefs.see_chat_non_mob || ismob(speaker)))
		create_chat_message(speaker, message_language, raw_message, spans)
	to_chat(src, compose_message(speaker, message_language, raw_message, radio_freq, spans, message_mods))

/datum/action/innate/despair_return
	name = "Return to Body"
	desc = "Withdraw from your projection and return to your crystallised body."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_despair"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lce_actions.dmi'
	button_icon_state = "end_communion"

/datum/action/innate/despair_return/Activate()
	var/mob/camera/despair_manifest/M = owner
	if(M.body)
		M.body.ReturnToBody()

// Alerts
/atom/movable/screen/alert/despair_danger
	name = "Blessed in Danger"
	desc = "Your blessed one is gravely hurt and under attack!"
	icon = 'ModularLobotomy/_Lobotomyicons/abno_hud.dmi'
	icon_state = "despair_danger"

// Actions
/datum/action/cooldown/limbus_abno_action/despair_bless
	name = "Give Blessing"
	desc = "Choose a nearby human to watch over. Whisper to them, raise their EGO attunement safe limit, and manifest at their side to see and hear all around them. Once given, the blessing cannot be revoked."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_despair"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	button_icon_state = "despair_bless"
	cooldown_time = 5 SECONDS

/datum/action/cooldown/limbus_abno_action/despair_bless/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/despair_knight/K = abno_user
	K.BlessHuman()
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/despair_whisper
	name = "Whisper"
	desc = "Whisper privately into the mind of the one you have blessed."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_despair"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lce_actions.dmi'
	button_icon_state = "whisper"
	transparent_when_unavailable = TRUE
	cooldown_time = 3 SECONDS

/datum/action/cooldown/limbus_abno_action/despair_whisper/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/despair_knight/K = abno_user
	if(!istype(K) || !K.blessed_human)
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/despair_whisper/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/despair_knight/K = abno_user
	K.DespairWhisper()
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/despair_manifest
	name = "Manifest"
	desc = "Appear beside your blessed as a ghostly projection only they can perceive. Your body hardens to crystal - nigh-invulnerable, but unable to move or fight - until you return."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_despair"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	button_icon_state = "despair_manifest"
	transparent_when_unavailable = TRUE
	cooldown_time = 3 SECONDS

/datum/action/cooldown/limbus_abno_action/despair_manifest/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/despair_knight/K = abno_user
	if(!istype(K) || !K.blessed_human || K.manifest || K.breached || K.communion_view)
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/despair_manifest/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/despair_knight/K = abno_user
	K.DoManifest()
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/despair_defend_tp
	name = "Rush to Defend"
	desc = "Teleport to your gravely-wounded blessed one. Only usable in the brief window after they are hurt. The blessing remains."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_despair"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	button_icon_state = "despair_defend"
	transparent_when_unavailable = TRUE
	cooldown_time = 1 SECONDS

/datum/action/cooldown/limbus_abno_action/despair_defend_tp/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/despair_knight/K = abno_user
	if(!istype(K) || !K.defend_ready || K.crystallized || world.time >= K.defend_window_end)
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/despair_defend_tp/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/despair_knight/K = abno_user
	K.DefendTeleport()
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/despair_rapidfire
	name = "Rapid Fire"
	desc = "Loose a rapid flurry of tear-forged rapiers at the nearest foe."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_despair"
	//"sniper_zoom" lives in actions_items.dmi, not actions_ability.dmi - this button was
	//rendering with no icon at all.
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"
	transparent_when_unavailable = TRUE
	cooldown_time = 8 SECONDS

/datum/action/cooldown/limbus_abno_action/despair_rapidfire/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/despair_knight/K = abno_user
	if(!istype(K) || K.crystallized)
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/despair_rapidfire/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/despair_knight/K = abno_user
	K.RapidFire()
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/despair_slash
	name = "Despair Slash"
	desc = "Cleave the ground before you. Only in your breached fury."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_despair"
	icon_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "repulse"
	transparent_when_unavailable = TRUE
	cooldown_time = 10 SECONDS

/datum/action/cooldown/limbus_abno_action/despair_slash/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/despair_knight/K = abno_user
	if(!istype(K) || !K.breached || K.crystallized)
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/despair_slash/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/despair_knight/K = abno_user
	K.SlashAttack()
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/despair_retort
	name = "Hopeless Retort"
	desc = "Conjure a wall of rapiers that fly outward. Only in your breached fury."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_despair"
	//There is no "genericcharge" state in any action sheet in the repo - this button was
	//rendering with no icon. "charge" is the nearest real state.
	icon_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "charge"
	transparent_when_unavailable = TRUE
	cooldown_time = 12 SECONDS

/datum/action/cooldown/limbus_abno_action/despair_retort/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/despair_knight/K = abno_user
	if(!istype(K) || !K.breached || K.crystallized)
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/despair_retort/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/despair_knight/K = abno_user
	K.HopelessRetort()
	StartCooldown()

