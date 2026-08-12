// Queen of Hatred, on the LCL base. Runs on a VILLAINY meter instead of a counter: it drains
// on its own and refills from facility chaos. At 0 she enters HYSTERIA - immobile, 95%
// resistances, 3 minute clock - and then picks hero or dragon breach.

// Passive-form bolts mend humans instead of damaging them. The dragon has no ranged attack, so
// !breached is a sufficient test. MendHuman decides whether it pays villainy.
/obj/projectile/hatred/lcl/on_hit(atom/target, blocked = FALSE)
	var/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Q = firer
	if(ishuman(target) && istype(Q) && !Q.breached)
		var/mob/living/carbon/human/H = target
		if(H.is_working) // Never interrupt someone mid-work.
			H.visible_message(span_warning("[src] vanishes on contact with [H]... but nothing happens!"))
			qdel(src)
			return BULLET_ACT_BLOCK
		Q.MendHuman(H, damage_type)
		qdel(src)
		return BULLET_ACT_BLOCK
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen
	true_name = "Queen of Hatred"
	egg_icon_state = "hatred_egg"
	original_abno = /mob/living/simple_animal/hostile/abnormality/hatred_queen
	maxHealth = 3500
	health = 3500
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.3, PALE_DAMAGE = 1.5)
	melee_damage_lower = 5 // The passive form barely melees. The dragon retunes this.
	melee_damage_upper = 10
	melee_damage_type = BLACK_DAMAGE
	attack_verb_continuous = "swats at"
	ranged = TRUE
	ranged_cooldown_time = 12
	projectiletype = /obj/projectile/hatred/lcl
	projectilesound = 'sound/abnormalities/hatredqueen/attack.ogg'
	attack_sound = 'sound/abnormalities/hatredqueen/attack.ogg'
	death_sound = 'sound/abnormalities/hatredqueen/dead.ogg'
	max_counter = 0 // Villainy IS her breach clock; a second one would just double up the HUD.
	// Needs. She loves an audience and being doted on; being beaten does nothing for her.
	desire_on_pet = 25
	desire_on_talk = 1
	insight_cooldown_time = 1 MINUTES
	liked_objects_list = list(/obj/item/toy/plush, /obj/item/toy/figure, /obj/item/toy/foamblade)
	liked_objects_value = 4
	hated_objects_list = list(/obj/item/storage/book, /obj/item/paper_bin)
	hated_objects_value = 2
	// Parent paths, so each covers its whole family.
	diet_list = list(
		/obj/item/food/cakeslice,
		/obj/item/food/pie,
		/obj/item/food/donut,
		/obj/item/food/cookie,
		/obj/item/food/candy,
		/obj/item/food/chocolatebar,
		/obj/item/food/icecreamsandwich,
		/obj/item/food/grown/berries,
	)
	diet_value = 20
	desire_on_eat = 10
	rep_desire_gain = -5 // Being hit costs her desire on top of the villainy it drains.
	hunger_cooldown_time = 3 MINUTES
	attunement_family = "love"
	ego_list = list(/datum/ego_datum/armor/lce/love)
	// A magical girl has hands, and reads what people leave for her.
	dextrous = TRUE
	held_items = list(null, null)
	attack_action_types = list(
		/datum/action/cooldown/limbus_abno_action/qoh_beam,
		/datum/action/cooldown/limbus_abno_action/qoh_beats,
		/datum/action/cooldown/limbus_abno_action/qoh_marker,
		/datum/action/cooldown/limbus_abno_action/qoh_hope,
		/datum/action/cooldown/limbus_abno_action/qoh_nihility,
		/datum/action/cooldown/limbus_abno_action/qoh_resist,
		/datum/action/cooldown/limbus_abno_action/qoh_villain,
		/datum/action/cooldown/limbus_abno_action/qoh_hero,
	)
	abno_additional_instructions = "You are a magical girl, and a magical girl needs villains. \
		Your VILLAINY meter is your conviction that the world still needs you - it drains on its own, \
		faster the less satisfied you are, and every real blow you take chips it away. \
		It refills when the facility falls apart: people dying, you striking other specimens, \
		and above all healing the WOUNDED with your wand - you can see who is hurt at a glance, \
		and mending someone who was already fine earns you nothing. If it ever empties you fall \
		into Hysteria, where you cannot move or fight and have three minutes to decide what you are. \
		People talking to you buys you time. So does refusing to give in. You can also move the meter \
		yourself: HOPE takes a large piece of it back, and NIHILITY throws a piece away. \
		You have hands, and you can read."

	// --- Villainy ---
	var/max_villainy = 100
	var/villainy = 100
	var/villainy_loss = 5 // Per drain tick in the passive state.
	var/villainy_cooldown_time = 30 SECONDS
	/// No passive drain for this long after she spawns or is reborn. Damage still costs her.
	var/villainy_grace = 10 MINUTES
	var/villainy_cooldown = 0
	var/villainy_min_damage = 10 // Passive state only: hits under this are beneath her notice.
	var/villainy_per_damage = 0.15
	var/next_villainy_credit = 0 // Shared rate limit for the two "active" gain sources.
	var/villainy_credit_delay = 1 SECONDS
	// --- Hysteria ---
	var/hysteric = FALSE
	var/hysteria_started = 0
	var/hysteria_duration = 3 MINUTES // Full -> empty with no input at all.
	var/hysteria_tick_time = 6 SECONDS
	var/hysteria_choice_delay = 105 SECONDS // The choice unlocks well before the bar would
	                                        // empty, so reaching it is never in doubt.
	/// How much time a single Resist buys back, converted to villainy at the current drain rate.
	var/hysteria_resist_time = 90 SECONDS
	var/hysteria_damage_multiplier = 3
	var/hysteria_speech_gain = 20
	var/list/pre_hysteria_coeffs
	// --- Breach ---
	var/breached = FALSE
	// --- Locks. Hysteria and the marker both freeze the body and can overlap, so they are
	// tracked by reason - can_act only returns when EVERY reason has cleared.
	var/list/act_blocks = list()
	// --- Kit ---
	var/obj/effect/qoh_wand/wand = null
	var/mob/camera/qoh_marker/marker = null
	/// Reentrancy guard. mind.transfer_to() fires Logout() on the marker, and the marker's
	/// Logout() calls RecallMarker() - so a normal recall would re-enter itself mid-way.
	var/recalling_marker = FALSE
	/// Passive form needs villainy OR desire above these. The dragon ignores both.
	var/marker_villainy_req = 70
	var/marker_desire_req = 70
	/// A one-off lockout from the moment she spawns. Nothing to do with the two bars - it
	/// exists so she cannot open the round by immediately scouting the whole facility.
	var/marker_startup_delay = 5 MINUTES
	var/marker_ready_at = 0
	/// The source's "hatred" is 1-direction; "hatred_breach" is the same girl in all four.
	var/passive_icon_state = "hatred_breach"
	/// The dragon's arrival hurts. BLACK damage in a small radius around the destination.
	var/teleport_aoe_damage = 40
	var/teleport_aoe_range = 2
	/// Flat desire bonus on top of desire_on_eat for anything sweet, whatever it was.
	var/sweet_desire_bonus = 5
	var/beam_cooldown = 0
	/// Arcana Slave is her showpiece, not a rotation button - three minutes in the passive
	/// form. The dragon has almost nothing else left, so it gets it back every 30 seconds.
	var/beam_cooldown_time = 3 MINUTES
	var/beam_cooldown_time_breached = 30 SECONDS
	var/beam_startup = 2 SECONDS
	var/beam_damage = 10
	var/beam_maximum_ticks = 60
	/// Hope pays villainy straight back; Nihility throws it away. Both are hers to press.
	var/hope_villainy = 40
	var/nihility_villainy = 30
	var/beats_cooldown = 0
	var/beats_cooldown_time = 15 SECONDS
	/// Healed per target instead of damaged, when Beats catches someone she will not hurt.
	var/beats_heal = 15
	var/beats_damage = 60 // Plan decision 4. The source's 250 is tuned for a normal round.
	var/datum/looping_sound/qoh_beam/beamloop
	var/datum/beam/current_beam
	var/list/spawned_effects = list()

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Initialize(mapload)
	. = ..()
	beamloop = new(list(src), FALSE)
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(OnMobDeath))
	SpawnWand()
	icon_state = passive_icon_state
	icon_living = passive_icon_state
	marker_ready_at = world.time + marker_startup_delay
	villainy_cooldown = world.time + villainy_grace
	// Advanced medical HUD: mending only pays for someone actually hurt, so she has to see it.
	var/datum/atom_hud/medsensor = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
	if(medsensor)
		medsensor.add_hud_to(src)
	UpdateBars()

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Destroy()
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	ClearSygils()
	if(current_beam)
		QDEL_NULL(current_beam)
	if(beamloop)
		QDEL_NULL(beamloop)
	if(wand)
		QDEL_NULL(wand)
	RecallMarker(TRUE) // Never leave a player stranded in the camera.
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/SpawnWand()
	if(breached || wand)
		return
	var/turf/wand_turf = get_ranged_target_turf(src, WEST, 1)
	wand = new(wand_turf || get_turf(src))

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/ClearSygils()
	for(var/obj/effect/qoh_sygil/S in spawned_effects)
		S.fade_out()
	spawned_effects.Cut()

// Order matters: the wand is placed before ..() moves her, so it lands on the tile she left.
// Doing it after parks it on top of her, and re-centring on a timer fights OpenFire.
/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Move()
	if(wand)
		wand.forceMove(get_turf(src))
	return ..()

// ============================ THE VILLAINY METER ============================

// Gains are announced in green with a "(+villainy)" tag. Losses are silent; the bar is enough.
#define QOH_VILLAINY_GAIN(str) ("<span style='color: #7ee87e'>" + str + " <b>(+villainy)</b></span>")

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/AdjustVillainy(villainy_amount, reason)
	if(villainy_amount == 0 || breached)
		return FALSE
	if(villainy_amount > 0 && reason && villainy < max_villainy)
		to_chat(src, QOH_VILLAINY_GAIN(reason))
	villainy = clamp(villainy + villainy_amount, 0, max_villainy)
	villainy = round(villainy, 1)
	UpdateBars()
	update_action_buttons()
	if(villainy <= 0)
		if(hysteric)
			Breach()
		else
			GoHysteric()
	return TRUE

// The two "active" gain sources both run through here so one beam tick or a fast weapon
// cannot spam the bar.
/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/CreditHeroism(villainy_gain, desire_gain, message)
	if(breached || world.time < next_villainy_credit)
		return FALSE
	next_villainy_credit = world.time + villainy_credit_delay
	AdjustVillainy(villainy_gain, message)
	AdjustDesire(desire_gain)
	return TRUE

// Flat bonus for anything sweet, read off the food's SUGAR/FRUIT flags rather than diet_list.
/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/IsSweetFood(atom/food)
	if(!istype(food, /obj/item/food))
		return FALSE
	var/obj/item/food/F = food
	return (F.foodtypes & (SUGAR|FRUIT)) ? TRUE : FALSE

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/attackby(obj/item/W, mob/user, params)
	if(is_type_in_list(W, diet_list))
		AbnoEat(W)
		return TRUE
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/AbnoEat(atom/food)
	// Read this BEFORE the parent runs - the base qdels the food once it has been eaten.
	var/was_sweet = IsSweetFood(food)
	. = ..()
	if(. && was_sweet)
		AdjustDesire(sweet_desire_bonus)
		to_chat(src, span_nicegreen("Sweet. Everything is a little easier to bear when something is sweet."))
	return .

// Only pays villainy if there was damage to fix. WHITE bolts mend SP, anything else mends
// brute/burn/toxin. Untreatable damage says so, or the meter silently fails to move.
// Passive form mends humans and friends, and only damages other specimens. The dragon has no
// mercy branch: everything caught takes the hit.
/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/ShouldMend(mob/living/L)
	return !breached && (ishuman(L) || IsFriend(L))

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/MendHuman(mob/living/carbon/human/H, bolt_damage_type)
	if(QDELETED(H))
		return FALSE
	var/mending_mind = (bolt_damage_type == WHITE_DAMAGE)
	var/missing_sanity = max(0, H.maxSanity - H.sanityhealth)
	var/healable_body = H.getBruteLoss() + H.getFireLoss() + H.getToxLoss()
	var/untouchable = H.getOxyLoss() + H.getCloneLoss()
	var/worth_it = mending_mind ? missing_sanity : healable_body

	if(worth_it > 0)
		if(mending_mind)
			H.adjustSanityLoss(-10)
		else
			H.adjustBruteLoss(-5)
		H.visible_message(span_nicegreen("[src]'s magic bursts into warmth on contact with [H]!"))
		CreditHeroism(3, 3, "Someone is better for you being here.")
		return TRUE

	// Nothing gained. Say which of the two reasons it was.
	var/hurt_elsewhere = mending_mind ? (healable_body + untouchable) : (missing_sanity + untouchable)
	H.visible_message(span_warning("[src]'s magic washes over [H] and finds nothing to mend."))
	if(hurt_elsewhere > 0)
		to_chat(src, span_warning("[H] is hurt in a way your magic cannot reach - \
			[mending_mind ? "their wounds are in the body, not the mind" : "there is nothing here you know how to close"]. No villainy for you."))
	else
		to_chat(src, span_warning("[H] is perfectly at peace. There is nothing to save them from, \
			and nothing in it for you."))
	return FALSE

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Life()
	. = ..()
	if(!. || breached)
		return
	if(hysteric)
		if(world.time >= villainy_cooldown)
			// A fixed drain: max_villainy over hysteria_duration, so an untouched bar empties
			// in exactly hysteria_duration.
			AdjustVillainy(-(max_villainy * hysteria_tick_time / hysteria_duration))
			villainy_cooldown = world.time + hysteria_tick_time
		UpdateBars() // Keeps the countdown maptext live between drain ticks.
		return
	if(world.time >= villainy_cooldown)
		// Drains twice as fast at empty desire as at full: a miserable magical girl loses
		// faith in the job much quicker.
		var/desire_frac = max_desire ? clamp(desire_bar / max_desire, 0, 1) : 0
		AdjustVillainy(-villainy_loss * (2 - desire_frac))
		villainy_cooldown = world.time + villainy_cooldown_time

// Passive: post-resistance damage, floored at villainy_min_damage. Hysteric: RAW damage, since
// 95% resistances would otherwise make post-resist values ~1 and the beatdown pointless.
/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/RepressionWork(attack_damage, damage_type, mob/user)
	. = ..()
	if(breached)
		return
	var/dmg = hysteric ? attack_damage : attack_damage * damage_coeff.getCoeff(damage_type)
	if(dmg <= 0)
		return
	if(!hysteric && dmg < villainy_min_damage)
		return
	AdjustVillainy(-dmg * villainy_per_damage * (hysteric ? hysteria_damage_multiplier : 1))

// Passive gains. A human dying anywhere on her z proves the world still needs her; another
// specimen dying in front of her proves it so hard the bar refills outright.
/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/OnMobDeath(datum/source, mob/living/died, gibbed)
	SIGNAL_HANDLER
	if(breached || QDELETED(died) || died == src || died.z != z)
		return
	if(istype(died, /mob/living/simple_animal/hostile/limbus_abno))
		if(get_dist(src, died) > 7)
			return
		AdjustVillainy(max_villainy, "[died] falls in front of you. THIS is why the world still needs a magical girl.")
		AdjustDesire(25)
		return
	if(!ishuman(died) || !died.mind)
		return
	// The signal is z-wide, so the victim is only named when she could actually have seen it.
	var/witnessed = (get_dist(src, died) <= 7) && (died in view(7, src))
	AdjustVillainy(10, witnessed ? \
		"<b>[died] dies right in front of you.</b> You could not save them - but that is exactly why someone like you has to be here." : \
		"<b>Somewhere out there, somebody stops.</b> You feel it the way you always do: the chaos is unfolding again, and people need saving.")

// TODO (plan decision 3, deferred): "another LCL abno breached" should also feed the meter
// (+25). It needs a global LCL-breach hook, which means editing the shared LCL base, so it
// is intentionally not wired here yet. When that hook exists, register it and call
// AdjustVillainy(25) from the handler.

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/is_literate()
	return TRUE

// Hooks UnarmedAttack, not AttackingTarget: the latter is the AI path and she is player-driven.
// Hands work as the Lunar Physician's do - non-harm clicks route through attack_hand so items
// are picked up and machine UIs open, and only harm intent still swings.
/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/UnarmedAttack(atom/A, proximity)
	if(isliving(A))
		. = ..()
		if(istype(A, /mob/living/simple_animal/hostile/limbus_abno) && A != src)
			CreditHeroism(2, 2, "You strike a blow for justice!")
		return
	if(dextrous && isitem(A) && a_intent != INTENT_HARM)
		A.attack_hand(src)
		update_inv_hands()
		return
	if(a_intent == INTENT_HARM)
		return ..()
	A.attack_hand(src) // Machines, consoles, doors: interact like a person.

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/OpenFire(atom/A)
	if(!can_act || breached) // The dragon has no ranged attack, and a frozen body cannot fire.
		return
	if(wand)
		wand.Move(get_step(src, dir))
	return ..()

// ============================ HUD + READOUT ============================

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/UpdateBars()
	..()
	if(breached)
		clear_alert("abno_villainy")
		clear_alert("abno_hysteria")
		return
	throw_alert("abno_villainy", /atom/movable/screen/alert/abno_villainy)
	var/atom/movable/screen/alert/abno_villainy/villainy_alert = alerts["abno_villainy"]
	if(villainy_alert)
		villainy_alert.UpdateVillainy(villainy, max_villainy)
	if(!hysteric)
		clear_alert("abno_hysteria")
		return
	throw_alert("abno_hysteria", /atom/movable/screen/alert/abno_hysteria)
	var/atom/movable/screen/alert/abno_hysteria/hysteria_alert = alerts["abno_hysteria"]
	if(hysteria_alert)
		hysteria_alert.UpdateHysteria(HysteriaSecondsLeft())

// Seconds of Hysteria left at the current drain rate, which is what the countdown shows.
/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/HysteriaSecondsLeft()
	var/per_second = max_villainy / (hysteria_duration / 10)
	if(per_second <= 0)
		return 0
	return max(0, round(villainy / per_second))

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/SelfStatusReadout()
	. = ..()
	if(breached)
		. += "<span class='userdanger'>BREACHED.</span> There is no going back from this. They will have to put you down."
		return .
	. += "Villainy: [round(villainy)]/[max_villainy]"
	if(hysteric)
		. += "<span class='userdanger'>HYSTERIA: [HysteriaSecondsLeft()] seconds before you break.</span>"
		if(world.time < hysteria_started + hysteria_choice_delay)
			. += "You may choose what you become in [round((hysteria_started + hysteria_choice_delay - world.time) / 10)] seconds."
		else
			. += "You may choose what you become <b>now</b>."
	return .

// ============================ THE ACT LOCK ============================

// Hysteria and the marker can overlap, so blocks are tracked by reason and can_act only
// returns when all clear. can_act is the real lock: TRAIT_IMMOBILIZED does nothing to a
// player-driven mob. Move() and AttackingTarget() check it free; OpenFire and abilities do not.
/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/SetActable(reason, allowed)
	if(allowed)
		act_blocks -= reason
	else
		act_blocks |= reason
	can_act = !length(act_blocks)
	update_action_buttons()

// ============================ HYSTERIA ============================

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/GoHysteric()
	if(hysteric || breached)
		return
	hysteric = TRUE // Set first: AdjustVillainy below must not re-enter this.
	hysteria_started = world.time
	RecallMarker(TRUE) // Cannot be out scouting while she is on her knees.
	icon_state = "hatred_psycho"
	icon_living = "hatred_psycho"
	SetActable("hysteria", FALSE)
	pre_hysteria_coeffs = list(
		RED_DAMAGE = damage_coeff.getCoeff(RED_DAMAGE),
		WHITE_DAMAGE = damage_coeff.getCoeff(WHITE_DAMAGE),
		BLACK_DAMAGE = damage_coeff.getCoeff(BLACK_DAMAGE),
		PALE_DAMAGE = damage_coeff.getCoeff(PALE_DAMAGE),
	)
	ChangeResistances(list(RED_DAMAGE = 0.05, WHITE_DAMAGE = 0.05, BLACK_DAMAGE = 0.05, PALE_DAMAGE = 0.05))
	villainy_cooldown = world.time + hysteria_tick_time
	AdjustVillainy(max_villainy) // The bar refills - but now it burns.
	visible_message(span_danger("[src] falls to her knees, muttering something under her breath."))
	to_chat(src, span_userdanger("The world does not need you. You have [round(hysteria_duration / 10)] seconds to decide whether that is true."))
	playsound(src, 'sound/abnormalities/hatredqueen/dead.ogg', 50, FALSE)

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/EndHysteria(celebrate = TRUE)
	if(!hysteric)
		return
	hysteric = FALSE
	SetActable("hysteria", TRUE)
	if(pre_hysteria_coeffs)
		ChangeResistances(pre_hysteria_coeffs)
		pre_hysteria_coeffs = null
	if(!breached)
		icon_state = passive_icon_state
		icon_living = passive_icon_state
		villainy_cooldown = world.time + villainy_cooldown_time
		AdjustVillainy(max_villainy)
	clear_alert("abno_hysteria")
	update_action_buttons()
	if(!celebrate)
		return
	visible_message(span_nicegreen("[src] picks herself up off the floor."))
	for(var/i in 1 to 5)
		addtimer(CALLBACK(src, PROC_REF(SpawnHeart)), i * 2)

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/SpawnHeart()
	if(QDELETED(src))
		return
	new /obj/effect/temp_visual/hatred(get_turf(src))

// Talking her down. Every line she hears while hysteric buys her a little more time.
/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Hear(message, atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, list/message_mods)
	..()
	if(hysteric && !breached && speaker != src)
		AdjustVillainy(hysteria_speech_gain, "[speaker]'s voice reaches you. Someone is still talking to you.")

// ============================ BREACH - THE DRAGON ============================

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/Breach()
	if(breached)
		return
	breached = TRUE
	unstable = TRUE // Pacifier tools no longer work on her.
	EndHysteria(FALSE)
	RecallMarker(TRUE)
	ClearSygils()
	adjustBruteLoss(-maxHealth, forced = TRUE)
	icon = 'ModularLobotomy/_Lobotomyicons/96x64.dmi'
	icon_state = "hatred"
	icon_living = "hatred"
	base_pixel_x = -32
	pixel_x = -32
	faction = list("hatredqueen")
	ranged = FALSE // The projectile attack is gone...
	melee_damage_lower = 30 // ...and replaced with something that actually hurts.
	melee_damage_upper = 45
	melee_damage_type = BLACK_DAMAGE
	attack_verb_continuous = "tears into"
	if(wand)
		QDEL_NULL(wand)
	AddBreachEffect()
	clear_alert("abno_villainy")
	clear_alert("abno_hysteria")
	update_action_buttons()
	visible_message(span_bolddanger("[src] transforms!"))
	to_chat(src, span_userdanger("You breach. There is no way back - the only thing that ends this is your death."))

// Death sends her to the rebirth egg; the base restores the icon, but knows nothing about
// the dragon, so everything Breach() changed has to be undone here by hand.
/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Rebirth()
	..()
	breached = FALSE
	unstable = FALSE
	hysteric = FALSE
	act_blocks.Cut() // Dying mid-beam or mid-teleport leaves a block set; clear the lot.
	can_act = TRUE
	// Dying part-way through the teleport animation leaves her invisible, non-dense and at
	// zero alpha. The base Rebirth restores the icon but knows nothing about any of that.
	invisibility = initial(invisibility)
	density = TRUE
	alpha = initial(alpha)
	base_pixel_x = 0
	pixel_x = 0
	faction = list("neutral")
	ranged = initial(ranged)
	melee_damage_lower = initial(melee_damage_lower)
	melee_damage_upper = initial(melee_damage_upper)
	attack_verb_continuous = initial(attack_verb_continuous)
	ChangeResistances(list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.3, PALE_DAMAGE = 1.5))
	pre_hysteria_coeffs = null
	RemoveBreachEffect()
	// The base Rebirth copies icon_state back off original_abno - i.e. the 1-direction
	// "hatred" - so the 4-direction body has to be re-applied here.
	icon_state = passive_icon_state
	icon_living = passive_icon_state
	SpawnWand()
	villainy = max_villainy
	villainy_cooldown = world.time + villainy_grace
	UpdateBars()
	update_action_buttons()

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/death(gibbed)
	ClearSygils()
	if(current_beam)
		QDEL_NULL(current_beam)
	if(beamloop)
		beamloop.stop()
	if(wand)
		QDEL_NULL(wand)
	RecallMarker(TRUE)
	clear_alert("abno_villainy")
	clear_alert("abno_hysteria")
	return ..()

// ============================ ARCANA SLAVE (the beam) ============================

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/CurrentBeamCooldown()
	return breached ? beam_cooldown_time_breached : beam_cooldown_time

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/BeamAttack(atom/beam_target)
	set waitfor = FALSE
	if(beam_cooldown > world.time || !can_act || !beam_target)
		return FALSE
	var/turf/target_turf = get_turf(beam_target)
	if(!target_turf)
		return FALSE
	// Turn to face the beam before anything else reads dir - the sigil placement below and
	// the beam itself both key off it, so she must be looking down the line she fires.
	face_atom(target_turf)
	var/my_dir = dir
	var/turf/my_turf = get_turf(src)
	SetActable("beam", FALSE)
	if(wand)
		wand.forceMove(my_turf)
	// Verbatim from the source abno (hatred_queen.dm), ellipsis character and all - this is
	// the one place she is still allowed to speak, so it has to be her actual words.
	var/list/beamtalk = list(
		"Heed me, thou that are more azure than justice and more crimson than love…",
		"In the name of those buried in destiny…",
		"I shall make this oath to the light.",
		"Mark the hateful beings who stand before us…",
		"Let your strength merge with mine…",
		"so that we may deliver the power of love to all…",
	)
	for(var/i = 1 to 3)
		var/obj/effect/qoh_sygil/S = new(my_turf)
		spawned_effects += S
		playsound(src, "sound/abnormalities/hatredqueen/beam[clamp(i, 1, 2)].ogg", 50, FALSE, 4 * i)
		var/matrix/M = matrix(S.transform)
		M.Translate(0, i * 16)
		M.Turn(Get_Angle(my_turf, target_turf))
		S.icon_state = "qoh[i]"
		switch(my_dir)
			if(EAST, WEST)
				M.Scale(0.5, 1)
				S.layer += i * 0.1
			if(SOUTH)
				S.layer += i * 0.1
			if(NORTH)
				S.layer -= i * 0.1
		S.transform = M
		// The oath belongs to the magical girl. The dragon charges the same beam in
		// silence - the source gates all of this on `friendly` for the same reason.
		if(!breached)
			addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, say), beamtalk[i * 2 - 1]))
			addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, say), beamtalk[i * 2]), beam_startup / 2)
		SLEEP_CHECK_DEATH(beam_startup)
	if(QDELETED(src) || stat == DEAD)
		ClearSygils()
		SetActable("beam", TRUE) // Do not strand the lock if she died during the windup.
		return
	// Walls do not stop it. It runs the full sixty tiles and burns whatever stands along the
	// line, through however much facility is in the way.
	var/turf/TT = get_ranged_target_turf_direct(my_turf, target_turf, 60)
	var/list/hit_line = getline(my_turf, TT)
	current_beam = my_turf.Beam(TT, "qoh")
	beamloop.start()
	if(!breached)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, say), "ARCANA SLAVE!"))
		// The dragon keeps its own sprite throughout. Its icon is a different sheet that has
		// only "hatred" in it, so a cast pose here would blank it - and the restore below is
		// already skipped while breached, which made that permanent.
		icon_state = "hatredbeats"
	// The dragon opens part-way up the ramp and climbs faster, exactly as the source's
	// hostile branch does - the beam is the only real weapon it has left.
	var/accumulated_beam_damage = breached ? 150 : 0
	var/beam_stage = 1
	var/beam_damage_final = beam_damage
	for(var/h = 1 to beam_maximum_ticks)
		if(QDELETED(src) || stat == DEAD)
			break
		if(breached)
			h += 19
		var/list/already_hit = list()
		if(h >= 40 && accumulated_beam_damage >= 300 && beam_stage < 3)
			beam_stage = 3
			beam_damage_final *= 1.5
			var/matrix/M = matrix()
			M.Scale(8, 1)
			current_beam.visuals.transform = M
			current_beam.visuals.color = COLOR_SOFT_RED
		else if(h >= 20 && accumulated_beam_damage >= 150 && beam_stage < 2)
			beam_stage = 2
			beam_damage_final *= 1.5
			var/matrix/M = matrix()
			M.Scale(4, 1)
			current_beam.visuals.transform = M
			current_beam.visuals.color = COLOR_YELLOW
		for(var/turf/TF in orange((beam_stage - 1), my_turf))
			var/obj/effect/temp_visual/L = new /obj/effect/temp_visual/revenant(TF)
			L.color = current_beam.visuals.color
		for(var/turf/TF in hit_line)
			for(var/mob/living/L in range(beam_stage - 1, TF))
				if(L == src || (L in already_hit) || L.stat == DEAD || (L.status_flags & GODMODE))
					continue
				already_hit += L
				if(ShouldMend(L))
					L.adjustBruteLoss(-beam_damage_final * 0.5)
					if(ishuman(L))
						var/mob/living/carbon/human/H = L
						H.adjustSanityLoss(-beam_damage_final * 0.5)
					continue
				var/truedamage = ishuman(L) ? beam_damage_final : beam_damage_final / 2
				var/damage_before = L.get_damage_amount(BRUTE)
				L.deal_damage(truedamage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
				if(breached && ishuman(L)) // The dragon feeds on what it burns.
					adjustBruteLoss(-abs(L.get_damage_amount(BRUTE) - damage_before))
				if(istype(L, /mob/living/simple_animal/hostile/limbus_abno))
					CreditHeroism(2, 2, null)
				// This is what makes the beam GROW: progress is only banked on things it
				// actually connects with, so a beam fired at nothing stays at stage one.
				accumulated_beam_damage += beam_damage_final
		SLEEP_CHECK_DEATH(1.71)
	QDEL_NULL(current_beam)
	ClearSygils()
	beamloop.stop()
	SLEEP_CHECK_DEATH(4 SECONDS) // She needs a moment after that.
	if(QDELETED(src))
		return
	if(!breached)
		icon_state = hysteric ? "hatred_psycho" : passive_icon_state
	SetActable("beam", TRUE)
	beam_cooldown = world.time + CurrentBeamCooldown()

// ============================ ARCANA BEATS ============================

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/ArcanaBeats(atom/beats_target)
	set waitfor = FALSE
	if(beats_cooldown > world.time || !can_act)
		return FALSE
	// Work out where the line is going, THEN turn to face it, so the sprite and the attack
	// always agree. Facing only when a target existed left her firing sideways.
	var/turf/target_turf = beats_target ? get_ranged_target_turf_direct(src, beats_target, 5) : get_ranged_target_turf(src, dir, 5)
	if(target_turf)
		face_atom(target_turf)
	SetActable("beats", FALSE)
	if(!breached) // As with the beam: the dragon's sheet has no cast pose to switch to.
		icon_state = "hatredbeats"
	visible_message(span_danger("[src] prepares to mark the enemies of justice!"))
	var/list/turfs_to_hit = getline(src, target_turf)
	var/obj/effect/qoh_sygil/S = new(get_turf(src))
	S.icon_state = "qoh1"
	spawned_effects += S
	switch(dir)
		if(EAST, WEST)
			S.pixel_x += (dir == EAST ? 16 : -16)
			var/matrix/new_matrix = matrix()
			new_matrix.Scale(0.5, 1)
			S.transform = new_matrix
			S.layer = (layer + 0.1)
		if(SOUTH)
			S.pixel_y += -16
			S.layer = (layer + 0.1)
		if(NORTH)
			S.pixel_y += 16
			S.layer -= 0.1
	SLEEP_CHECK_DEATH(1.5 SECONDS)
	if(QDELETED(src) || stat == DEAD)
		ClearSygils()
		SetActable("beats", TRUE)
		return
	playsound(src, 'sound/abnormalities/hatredqueen/gun.ogg', 65, FALSE, 10)
	if(!breached)
		icon_state = "hatredrecoil"
	var/list/beats_hit = list()
	var/i = 1
	for(var/turf/T in turfs_to_hit)
		addtimer(CALLBACK(src, PROC_REF(BeatsTurf), T, beats_hit), i * 0.4)
		i++
	SLEEP_CHECK_DEATH(1 SECONDS)
	ClearSygils()
	if(QDELETED(src))
		return
	if(!breached)
		icon_state = hysteric ? "hatred_psycho" : passive_icon_state
	SetActable("beats", TRUE)
	beats_cooldown = world.time + beats_cooldown_time

// Written out rather than using HurtInTurf, because HurtInTurf checks factions and an LCL
// abno's allies live in friend_list, not in a faction.
/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/BeatsTurf(turf/T, list/beats_hit)
	if(QDELETED(src) || !T)
		return
	for(var/turf/TT in range(1, T))
		if(locate(/obj/effect/temp_visual/revenant) in TT)
			continue
		var/obj/effect/temp_visual/TV = new /obj/effect/temp_visual/revenant(TT)
		TV.color = COLOR_SOFT_RED
		for(var/mob/living/L in TT)
			if(L == src || (L in beats_hit) || L.stat == DEAD || (L.status_flags & GODMODE))
				continue
			beats_hit += L
			if(ShouldMend(L))
				L.adjustBruteLoss(-beats_heal)
				if(ishuman(L))
					var/mob/living/carbon/human/H = L
					H.adjustSanityLoss(-beats_heal)
				continue
			L.deal_damage(beats_damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
			if(istype(L, /mob/living/simple_animal/hostile/limbus_abno))
				CreditHeroism(2, 2, null)

// ============================ THE MARKER TELEPORT ============================

// Passive form needs villainy OR desire over the threshold; the dragon skips both.
/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/CanUseMarker()
	// Checked ahead of the breach bypass, so even the dragon waits out the spawn lockout.
	if(world.time < marker_ready_at)
		return FALSE
	if(breached)
		return TRUE
	return (villainy >= marker_villainy_req) || (desire_bar >= marker_desire_req)

// First press projects the reticle, second recalls it and teleports her body to it.
/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/ProjectMarker()
	if(marker || hysteric || !mind || !can_act)
		return FALSE
	if(!CanUseMarker())
		if(world.time < marker_ready_at)
			to_chat(src, span_warning("You are barely awake. The arcana will not answer you for \
				another [round((marker_ready_at - world.time) / 600, 0.1)] minute\s."))
		else
			to_chat(src, span_warning("You reach for the arcana and nothing answers. \
				You are neither sure enough that you are needed, nor happy enough to pretend."))
		return FALSE
	marker = new /mob/camera/qoh_marker(get_turf(src), src)
	SetActable("marker", FALSE)
	possession_locked = TRUE //Her body sits empty while she scouts; it is still hers.
	mind.transfer_to(marker)
	to_chat(marker, span_notice("<b>You cast your sight out ahead of you.</b> Press again to return - your body will follow three seconds later."))
	return TRUE

// abort = TRUE means something went wrong (death, hysteria, logout, deletion): pull the mind
// home and drop the marker without teleporting anywhere.
/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/RecallMarker(abort = FALSE)
	if(!marker || recalling_marker)
		return FALSE
	recalling_marker = TRUE
	var/turf/destination = get_turf(marker)
	if(marker.mind)
		if(QDELETED(src))
			// Called from Destroy(): the body is already going away, so pushing a player
			// into it would strand them in a deleting mob. Ghost them out instead.
			marker.ghostize(FALSE)
		else
			marker.mind.transfer_to(src)
	QDEL_NULL(marker)
	SetActable("marker", TRUE)
	possession_locked = FALSE
	recalling_marker = FALSE
	if(abort || QDELETED(src) || stat == DEAD)
		return FALSE
	to_chat(src, span_notice("You gather yourself. In three seconds, you will be there."))
	addtimer(CALLBACK(src, PROC_REF(MarkerTeleport), destination), 3 SECONDS)
	return TRUE

// Backing out. The cooldown pays for arriving somewhere, so changing your mind costs nothing -
// otherwise a misclick locks the ability out for two minutes.
/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/CancelMarker()
	if(!marker || recalling_marker)
		return FALSE
	RecallMarker(TRUE) // abort: the mind comes home and nothing teleports
	RefundMarkerCooldown()
	to_chat(src, span_notice("You let the marker go. Nothing was spent."))
	return TRUE

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/RefundMarkerCooldown()
	var/datum/action/cooldown/limbus_abno_action/qoh_marker/marker_action = locate() in actions
	if(!marker_action)
		return
	marker_action.next_use_time = 0
	if(marker_action.button)
		marker_action.button.maptext = ""
	marker_action.UpdateButtonIcon()

/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/MarkerTeleport(turf/destination)
	set waitfor = FALSE
	if(QDELETED(src) || stat == DEAD || !destination)
		return
	if(!QoHCanOccupy(destination))
		to_chat(src, span_warning("There is nothing out there to arrive at. You stay where you are."))
		return
	SetActable("teleport", FALSE)
	animate(src, alpha = 0, time = 4)
	new /obj/effect/temp_visual/guardian/phase(get_turf(src))
	SLEEP_CHECK_DEATH(4)
	if(QDELETED(src))
		return
	invisibility = INVISIBILITY_MAXIMUM
	density = FALSE
	forceMove(destination)
	var/obj/effect/qoh_sygil/S = new(destination)
	S.icon_state = "qoh2"
	addtimer(CALLBACK(S, TYPE_PROC_REF(/obj/effect/qoh_sygil, fade_out)), 2 SECONDS)
	SLEEP_CHECK_DEATH(2 SECONDS)
	if(QDELETED(src))
		return
	invisibility = initial(invisibility)
	density = TRUE
	animate(src, alpha = 255, time = 4)
	new /obj/effect/temp_visual/guardian/phase/out(destination)
	if(breached)
		TeleportBurst(destination)
	if(wand)
		wand.forceMove(get_step(src, dir))
	SetActable("teleport", TRUE)

// From the source's TeleportExplode, smaller radius and lower damage. Friends are spared, as
// with her beam and Arcana Beats.
/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/proc/TeleportBurst(turf/epicentre)
	if(QDELETED(src) || !epicentre)
		return
	visible_message(span_bolddanger("[src] lands in a burst of hateful light!"))
	var/obj/effect/temp_visual/VO = new /obj/effect/temp_visual/voidout(epicentre)
	var/matrix/new_matrix = matrix()
	new_matrix.Scale(1.25)
	VO.transform = new_matrix
	playsound(epicentre, 'sound/abnormalities/hatredqueen/gun.ogg', 70, FALSE, 6)
	var/list/already_hit = list()
	for(var/turf/T in view(teleport_aoe_range, epicentre))
		for(var/mob/living/L in T)
			if(L == src || (L in already_hit) || L.stat == DEAD || (L.status_flags & GODMODE) || IsFriend(L))
				continue
			already_hit += L
			L.deal_damage(teleport_aoe_damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))

// The reticle. Invisible to everyone; she sees it because the image is pushed into her own
// client only. It cannot speak - a scout that could talk would be a free intercom.
/mob/camera/qoh_marker
	name = "arcane marker"
	real_name = "arcane marker"
	desc = "A target sigil, hanging in the air."
	see_in_dark = 8
	lighting_alpha = LIGHTING_PLANE_ALPHA_VISIBLE
	sight = NONE
	see_invisible = SEE_INVISIBLE_LIVING
	invisibility = INVISIBILITY_MAXIMUM
	var/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/body
	var/image/current_image
	var/move_delay = 0

/mob/camera/qoh_marker/Initialize(mapload, _body)
	. = ..()
	body = _body
	var/datum/action/innate/qoh_marker_return/R = new
	R.Grant(src)
	var/datum/action/innate/qoh_marker_cancel/X = new
	X.Grant(src)

/mob/camera/qoh_marker/Destroy()
	if(client)
		client.images.Remove(current_image)
	current_image = null
	body = null
	return ..()

/mob/camera/qoh_marker/Login()
	. = ..()
	if(!. || !client)
		return FALSE
	Show()

/mob/camera/qoh_marker/proc/Show()
	if(client)
		client.images.Remove(current_image)
	current_image = image('ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi', src, "qoh_marker", ABOVE_MOB_LAYER)
	current_image.override = TRUE
	current_image.alpha = 200
	if(client)
		client.images |= current_image

/proc/QoHCanOccupy(atom/destination)
	var/turf/T = get_turf(destination)
	if(!T || isspaceturf(T))
		return FALSE
	return !istype(get_area(T), /area/space)

/mob/camera/qoh_marker/Move(atom/newloc, direction)
	if(world.time < move_delay)
		return FALSE
	if(!QoHCanOccupy(newloc))
		to_chat(src, span_warning("Your sight will not carry out into the dark. There is nothing out there to arrive at."))
		move_delay = world.time + 1
		return FALSE
	forceMove(newloc)
	move_delay = world.time + 1

/mob/camera/qoh_marker/forceMove(atom/destination)
	. = ..()
	Show()

// It is a sight, not a voice.
/mob/camera/qoh_marker/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	to_chat(src, span_warning("The marker has no mouth. You cannot speak from out here."))
	return

// Logging out while projected would strand the body frozen forever.
/mob/camera/qoh_marker/Logout()
	. = ..()
	if(body && !QDELETED(body))
		body.RecallMarker(TRUE)

// ============================ HUD ALERTS ============================

///Villainy HUD bar. Her heart hairpin drains from pink to grey as her conviction fades, beside a thermometer of the meter itself.
/atom/movable/screen/alert/abno_villainy
	name = "Villainy"
	desc = "How sure you are that the world still needs a magical girl."
	icon = 'ModularLobotomy/_Lobotomyicons/abno_hud.dmi'
	icon_state = "villainy10"

/atom/movable/screen/alert/abno_villainy/proc/UpdateVillainy(current, maximum)
	var/frac = maximum ? clamp(current / maximum, 0, 1) : 0
	icon_state = "villainy[round(frac * 10)]"
	desc = "Villainy: [round(current)]/[maximum]. At zero, you break."

///Hysteria countdown. A cracked badge carrying the seconds left before she breaches.
/atom/movable/screen/alert/abno_hysteria
	name = "Hysteria"
	desc = "You are on your knees. When this reaches zero, you breach."
	icon = 'ModularLobotomy/_Lobotomyicons/abno_hud.dmi'
	icon_state = "hysteria"
	maptext_x = 6
	maptext_y = 10

/atom/movable/screen/alert/abno_hysteria/proc/UpdateHysteria(seconds_left)
	desc = "[seconds_left] seconds before you breach. Being spoken to, and resisting, both buy you time."
	var/col = "#6fb932" // Comfortable.
	if(seconds_left <= 15)
		col = "#e21717"
	else if(seconds_left <= 40)
		col = "#eb4d42"
	else if(seconds_left <= 70)
		col = "#d3d023"
	maptext = MAPTEXT("<span style='color: [col]'><b>[seconds_left]</b></span>")

// ============================ ACTIONS ============================

/datum/action/cooldown/limbus_abno_action/qoh_beam
	name = "Arcana Slave"
	desc = "Charge a vast beam of love down the line you are facing. It grows as it burns - but only off what it \
		actually hits, so a beam aimed at nothing stays small. It mends any friend caught in it. Three minutes to recharge; \
		far less once you have stopped being the hero."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_qoh"
	icon_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = "qoh_beam"
	transparent_when_unavailable = TRUE
	// Overwritten on each use from CurrentBeamCooldown(); this is only the value before
	// she has fired once.
	cooldown_time = 3 MINUTES

/datum/action/cooldown/limbus_abno_action/qoh_beam/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Q = abno_user
	if(!istype(Q) || Q.hysteric || !Q.can_act || world.time < Q.beam_cooldown)
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/qoh_beam/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Q = abno_user
	Q.BeamAttack(Q.target || get_ranged_target_turf(Q, Q.dir, 7))
	// StartCooldown reads cooldown_time, so it has to be set to whichever of the two
	// beam cooldowns is in force or the button lies about when it is back.
	cooldown_time = Q.CurrentBeamCooldown()
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/qoh_beats
	name = "Arcana Beats"
	desc = "Mark a line of enemies of justice and strike every tile along it."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_qoh"
	icon_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = "qoh_beats"
	transparent_when_unavailable = TRUE
	cooldown_time = 15 SECONDS

/datum/action/cooldown/limbus_abno_action/qoh_beats/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Q = abno_user
	if(!istype(Q) || Q.hysteric || !Q.can_act || world.time < Q.beats_cooldown)
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/qoh_beats/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Q = abno_user
	Q.ArcanaBeats(Q.target || get_ranged_target_turf(Q, Q.dir, 5))
	StartCooldown()

// The recall press is a separate innate action on the marker: the LCL action base binds to a
// limbus abno on Grant and cannot be given to a camera mob.
/datum/action/cooldown/limbus_abno_action/qoh_marker
	name = "Arcane Marker"
	desc = "Cast your sight out as a marker only you can see. Your body cannot move or fight while you are out there. \
		The arcana will only answer while your villainy or your desire is high - unless you have stopped being the hero, \
		in which case it always answers, and your arrival hurts whoever is standing there."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_qoh"
	// Bespoke reticle. actions_abnormality's "qoh_teleport" reads as a blob against this border.
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	button_icon_state = "qoh_marker"
	transparent_when_unavailable = TRUE
	cooldown_time = 2 MINUTES

/datum/action/cooldown/limbus_abno_action/qoh_marker/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Q = abno_user
	if(!istype(Q) || Q.hysteric || Q.marker || !Q.can_act)
		return FALSE
	return Q.CanUseMarker()

/datum/action/cooldown/limbus_abno_action/qoh_marker/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Q = abno_user
	Q.ProjectMarker()
	StartCooldown()

// The second press, granted to the marker when it spawns.
/datum/action/innate/qoh_marker_return
	name = "Return and Translocate"
	desc = "Snap back into your body. Three seconds later it will phase to where this marker stands."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_qoh"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	button_icon_state = "qoh_marker"

/datum/action/innate/qoh_marker_return/Activate()
	var/mob/camera/qoh_marker/M = owner
	if(!istype(M) || !M.body || QDELETED(M.body))
		return
	M.body.RecallMarker()

// The way out. Same recall, no travel, and the Arcane Marker cooldown is handed back.
/datum/action/innate/qoh_marker_cancel
	name = "Dismiss Marker"
	desc = "Let the marker go and return to your body without travelling to it. Costs you nothing - \
		the arcana is only spent on arriving somewhere."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_qoh"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	button_icon_state = "qoh_marker_cancel"

/datum/action/innate/qoh_marker_cancel/Activate()
	var/mob/camera/qoh_marker/M = owner
	if(!istype(M) || !M.body || QDELETED(M.body))
		return
	M.body.CancelMarker()

// Hope and Nihility. The two halves of the meter she can move herself.
/datum/action/cooldown/limbus_abno_action/qoh_hope
	name = "Hope"
	desc = "Remember why you started. Gives you back a large piece of your Villainy. Five minutes to recharge."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_qoh"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	button_icon_state = "qoh_hope"
	transparent_when_unavailable = TRUE
	cooldown_time = 5 MINUTES

// Deliberately still usable on her knees, the same as Resist - it is the one button that
// matches what Hysteria is about.
/datum/action/cooldown/limbus_abno_action/qoh_hope/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Q = abno_user
	if(!istype(Q) || Q.breached)
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/qoh_hope/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Q = abno_user
	Q.AdjustVillainy(Q.hope_villainy, "Someone still needs a magical girl. It might as well be you.")
	Q.manual_emote("straightens up, and the light comes back into her eyes.")
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/qoh_nihility
	name = "Nihility"
	desc = "Let a piece of it go. Costs you Villainy, and brings Hysteria closer. Thirty seconds to recharge."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_qoh"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	button_icon_state = "qoh_nihility"
	transparent_when_unavailable = TRUE
	cooldown_time = 30 SECONDS

// Locked out during Hysteria on purpose: AdjustVillainy breaches her outright if the bar hits
// zero while she is already hysteric, so leaving it live would be a hidden instant-breach
// button sitting next to the deliberate one.
/datum/action/cooldown/limbus_abno_action/qoh_nihility/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Q = abno_user
	if(!istype(Q) || Q.breached || Q.hysteric)
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/qoh_nihility/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Q = abno_user
	Q.AdjustVillainy(-Q.nihility_villainy)
	to_chat(Q, span_warning("You let a piece of it go. It is quieter without it."))
	Q.manual_emote("lets her shoulders drop.")
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/qoh_resist
	name = "Resist"
	desc = "Refuse to give in. Buys you another minute and a half of Hysteria."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_qoh"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	button_icon_state = "qoh_resist"
	transparent_when_unavailable = TRUE
	cooldown_time = 30 SECONDS

/datum/action/cooldown/limbus_abno_action/qoh_resist/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Q = abno_user
	if(!istype(Q) || !Q.hysteric || Q.breached)
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/qoh_resist/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Q = abno_user
	// Expressed as time rather than as a flat number, so retuning hysteria_duration cannot
	// silently change what a Resist is worth.
	Q.AdjustVillainy(Q.max_villainy * (Q.hysteria_resist_time / Q.hysteria_duration), \
		"You refuse. Not here, not like this - there is still someone who needs you.")
	Q.manual_emote("grits her teeth and pushes herself up an inch.")
	StartCooldown()

// The choice. Both unlock together once she has held on long enough.
/datum/action/cooldown/limbus_abno_action/qoh_choice
	transparent_when_unavailable = TRUE
	cooldown_time = 1 SECONDS

/datum/action/cooldown/limbus_abno_action/qoh_choice/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Q = abno_user
	if(!istype(Q) || !Q.hysteric || Q.breached)
		return FALSE
	if(world.time < Q.hysteria_started + Q.hysteria_choice_delay)
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/qoh_villain
	name = "Become the Villain"
	desc = "If the world will not have a hero, it can have a monster instead. This breaches you immediately, and there is no way back."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_qoh"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	button_icon_state = "qoh_villain"
	parent_type = /datum/action/cooldown/limbus_abno_action/qoh_choice

/datum/action/cooldown/limbus_abno_action/qoh_villain/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Q = abno_user
	Q.Breach()
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/qoh_hero
	name = "Become the Hero"
	desc = "Decide that someone out there still needs you. Leaves Hysteria and restores you completely."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_qoh"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	button_icon_state = "qoh_hero"
	parent_type = /datum/action/cooldown/limbus_abno_action/qoh_choice

/datum/action/cooldown/limbus_abno_action/qoh_hero/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/hatred_queen/Q = abno_user
	Q.EndHysteria()
	StartCooldown()
