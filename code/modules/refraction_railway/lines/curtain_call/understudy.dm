/*
 * Curtain Call — zeal_s2n1: The Understudy.
 * Envy of Humanity variant. Fights through AI-controlled human "skins" cut
 * from city roles; only the true form is wave-registered, killing a skin
 * just drags the true form out for a punish window before it dons another.
 */

// Standardized ability wind-up tiers (deciseconds; matches SLEEP_CHECK_DEATH).
#define UNDERSTUDY_TELEGRAPH_FAST   8  // 0.8s
#define UNDERSTUDY_TELEGRAPH_MEDIUM 14 // 1.4s
#define UNDERSTUDY_TELEGRAPH_SLOW   20 // 2.0s

// ---------- Telegraph ----------

/obj/effect/temp_visual/understudy_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom_blank"
	layer = BELOW_MOB_LAYER
	color = "#b026ff"
	duration = 8

// ---------- Movespeed modifiers ----------

/datum/movespeed_modifier/understudy_form
	multiplicative_slowdown = 1.5

// Phase-2 faces opt into this faster modifier (Red Mist's "The Strongest").
/datum/movespeed_modifier/understudy_form/fast
	multiplicative_slowdown = 0.4

// ---------- Custom AI: locked weapon, silent voicelines ----------
/datum/ai_controller/insane/murder/understudy
	lines_type = /datum/ai_behavior/say_line/insanity_lines/understudy_silent

/datum/ai_controller/insane/murder/understudy/TryFindWeapon(is_white_allowed = TRUE)
	return null

// Belt-and-suspenders: TryFindWeapon returning null already starves every standard call site, but if any path ever hands TryEquipWeapon a list directly, swallow it. The form's costume is the only kit it ever wields.
/datum/ai_controller/insane/murder/understudy/TryEquipWeapon(list/potential_weapons)
	return

// Silent variant of the insane-murder voiceline behaviour.
/datum/ai_behavior/say_line/insanity_lines/understudy_silent
	line_type = "murder"

/datum/ai_behavior/say_line/insanity_lines/understudy_silent/perform(delta_time, datum/ai_controller/controller)
	finish_action(controller, TRUE)

// ---------- True form ----------
/mob/living/simple_animal/hostile/distortion/understudy
	name = "The Envy of Humanity"
	desc = "A writhing, shifting mass that grew so far past human it forgot the \
		way back - and adores humanity with all the wretched hunger that growing \
		left behind. It wears other people's lives like costumes, loving each one \
		as helplessly as it loathes the thing wearing them."
	icon = 'ModularLobotomy/_Lobotomyicons/resurgence_64x96.dmi'
	icon_state = "envy"
	pixel_x = -16
	base_pixel_x = -16
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	faction = list("serio_zeal")
	maxHealth = 2500
	health = 2500
	melee_damage_lower = 20
	melee_damage_upper = 28
	melee_damage_type = BLACK_DAMAGE
	move_to_delay = 4
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	attack_sound = 'sound/hallucinations/growl1.ogg'
	damage_coeff = list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 0.4, PALE_DAMAGE = 0.8)
	del_on_death = FALSE
	refraction_manages_own_death = TRUE
	loot = list()

	/// HP chipped off the true form each time a skin is broken.
	var/reveal_damage = 300
	var/reveal_stun_time = 4 SECONDS
	var/reform_delay = 5 SECONDS
	var/reveals_done = 0
	/// Worsening resistances applied on each reveal (index = reveals_done).
	var/list/resist_tiers = list(
		list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 0.4, PALE_DAMAGE = 0.8),
		list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 1.0),
		list(RED_DAMAGE = 1.0, WHITE_DAMAGE = 1.0, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.2),
		list(RED_DAMAGE = 1.25, WHITE_DAMAGE = 1.25, BLACK_DAMAGE = 1.0, PALE_DAMAGE = 1.5),
		list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1.25, PALE_DAMAGE = 2.0),
	)
	/// The skins it can wear (drawn at random, no immediate repeats).
	var/list/form_pool = list(
		/mob/living/carbon/human/understudy_form/ronin,
		/mob/living/carbon/human/understudy_form/butcher,
		/mob/living/carbon/human/understudy_form/scavenger,
		/mob/living/carbon/human/understudy_form/captain,
		/mob/living/carbon/human/understudy_form/big_brother,
		/mob/living/carbon/human/understudy_form/grosshammer,
		/mob/living/carbon/human/understudy_form/messenger,
		/mob/living/carbon/human/understudy_form/dieci,
		/mob/living/carbon/human/understudy_form/zwei,
		/mob/living/carbon/human/understudy_form/shi,
		/mob/living/carbon/human/understudy_form/liu,
		/mob/living/carbon/human/understudy_form/seven,
		/mob/living/carbon/human/understudy_form/devyat,
	)
	var/last_form
	var/mob/living/carbon/human/understudy_form/current_form
	var/dying = FALSE
	var/death_fade_time = 1 SECONDS

	// ---- Refraction Railway recognition ----
	/// Character this boss recognizes among the railway party, matched as a
	/// case-insensitive substring of a member's mob name. Empty = no one.
	var/recognition_target_name = "Ruvin"
	/// Two-part recognition line, said at the start of combat when matched.
	var/recognition_line_1 = "R-Ruvin... I w-wore your face so WELL... your Brothers never even knew-"
	var/recognition_line_2 = "You h-hated yourself enough to t-tear me out... and still I l-love you for it-"
	/// Said as the understudy fades on death (replaces its normal death line
	/// when Ruvin is the one who puts it down).
	var/boss_final_line = "...I just w-wanted to be one of them... like you w-were, Ruvin..."
	/// Once-guard so recognition is attempted a single time per fight.
	var/recognition_attempted = FALSE
	/// TRUE once a party member was actually recognized this fight; makes the
	/// death sequence speak only the final recognition line.
	var/recognized = FALSE
	/// While TRUE the recognition sequence (both halves + 3s after) owns the
	/// understudy's voice; every other line is dropped. Sanctioned lines pass
	/// via recognition_bypass.
	var/recognition_locked = FALSE
	var/recognition_bypass = FALSE

	/// Phase 1 HP floor as a fraction of maxHealth.
	var/phase_trigger_threshold = 0.25
	/// Absolute HP floor, resolved at Initialize.
	var/phase_trigger_hp
	var/phase_2_triggered = FALSE
	/// Replaces form_pool once phase 2 fires.
	var/list/phase_2_form_pool = list(
		/mob/living/carbon/human/understudy_form/red_mist,
		/mob/living/carbon/human/understudy_form/black_silence,
		/mob/living/carbon/human/understudy_form/blue_reverberation,
	)

	var/list/reveal_lines = list(
		"n-no, no, NO - do not, do not L-LOOK at it, the shape b-beneath the face is - is HID-HIDeous -",
		"give it b-back!! give me a face, a n-n-name, a little human n-nothing - I'll be small, I'll be G-GOOD, I'll -",
		"you were - were m-meant to watch THEM. the b-beautiful borrowed them. n-never... never m-m-me -",
		"I am so much M-MORE th-than this and I'd un-unmake ev-every inch to be so much... so much L-LESS -",
	)
	var/list/death_lines = list(
		"...I only - only ever w-wanted... to be one of... of you... j-just... one...",
		"...you were all so w-warm... and I was... only ev-ever... c-c-cold...",
		"...the un-understudy... n-never does... go on... d-does it...",
		"...I l-loved you... loved you so m-much I... c-couldn't... st-stop... t-taking...",
	)
	var/list/lines_phase_2_ruvin = list(
		"...n-no more h-hiding, Ruvin... not from YOU-",
		"...you w-wanted me GONE... so LOOK... look at what's left-",
	)

/mob/living/simple_animal/hostile/distortion/understudy/refracted

/mob/living/simple_animal/hostile/distortion/understudy/Initialize(mapload)
	. = ..()
	phase_trigger_hp = round(maxHealth * phase_trigger_threshold)
	addtimer(CALLBACK(src, PROC_REF(AssumeForm)), 1 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(TryRecognition)), 1.5 SECONDS)

// ---------- Refraction Railway recognition ----------

/// Recognition + death lines bypass the lock; every other line is dropped
/// while the recognition sequence holds the understudy's voice.
/mob/living/simple_animal/hostile/distortion/understudy/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(recognition_locked && !recognition_bypass)
		return
	return ..()

/// Says a framework-sanctioned line past the recognition lock. When an
/// active skin is worn, the line comes out of the FORM's mouth instead
/// of the understudy's — the borrowed face is what Ruvin hears.
/mob/living/simple_animal/hostile/distortion/understudy/proc/SpeakRecognition(message)
	if(!message)
		return
	if(current_form && !QDELETED(current_form))
		current_form.say(message)
		return
	recognition_bypass = TRUE
	say(message)
	recognition_bypass = FALSE

/// Start of combat: if a railway party member's mob name contains
/// recognition_target_name, play the two-part recognition line and hold the
/// speech lock through both parts plus 3 seconds.
/mob/living/simple_animal/hostile/distortion/understudy/proc/TryRecognition()
	if(recognition_attempted || stat == DEAD || dying)
		return
	recognition_attempted = TRUE
	if(!recognition_target_name)
		return
	var/datum/refraction_run/R = FindRefractionRunForZ(z)
	if(!R)
		return
	var/found = FALSE
	for(var/mob/M as anything in R.members)
		if(QDELETED(M))
			continue
		var/their_name = M.real_name || M.name
		if(their_name && findtext(their_name, recognition_target_name))
			found = TRUE
			break
	if(!found)
		return
	recognized = TRUE
	recognition_locked = TRUE
	SpeakRecognition(recognition_line_1)
	addtimer(CALLBACK(src, PROC_REF(RecognitionPart2)), 2 SECONDS)

/mob/living/simple_animal/hostile/distortion/understudy/proc/RecognitionPart2()
	if(QDELETED(src) || stat == DEAD || dying)
		recognition_locked = FALSE
		return
	SpeakRecognition(recognition_line_2)
	addtimer(CALLBACK(src, PROC_REF(EndRecognitionLock)), 3 SECONDS)

/mob/living/simple_animal/hostile/distortion/understudy/proc/EndRecognitionLock()
	recognition_locked = FALSE

// Carries current_form down with the true form so a hard qdel path (team wipe via WipeRoomReserves) doesn't orphan the skin.
/mob/living/simple_animal/hostile/distortion/understudy/Destroy()
	if(current_form && !QDELETED(current_form))
		UnregisterSignal(current_form, COMSIG_LIVING_DEATH)
		qdel(current_form)
	current_form = null
	return ..()

// Phase-1 HP floor: any hit below phase_trigger_hp caps and triggers phase 2.
/mob/living/simple_animal/hostile/distortion/understudy/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && !phase_2_triggered && amount > 0 && stat != DEAD)
		if((health - amount) <= phase_trigger_hp)
			amount = max(0, health - phase_trigger_hp)
			. = ..(amount, updating_health, forced)
			EnterPhase2()
			return
	return ..(amount, updating_health, forced)

// can_act gates AI/Move/Attack without deregistering the controller.
/mob/living/simple_animal/hostile/distortion/understudy/handle_automated_action()
	if(!can_act)
		return
	return ..()

/mob/living/simple_animal/hostile/distortion/understudy/Move(atom/newloc, dir, step_x, step_y)
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/distortion/understudy/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return
	return ..()

// carry_damage = previous skin's missing HP; applied as delayed BRUTE so
// SetupCostume's Fortitude buff lands first.
/mob/living/simple_animal/hostile/distortion/understudy/proc/AssumeForm(carry_damage = 0, turf/at_turf = null)
	if(dying || stat == DEAD || QDELETED(src))
		return
	if(current_form && !QDELETED(current_form))
		return
	var/list/choices = form_pool.Copy()
	if(last_form && length(choices) > 1)
		choices -= last_form
	var/form_type = pick(choices)
	last_form = form_type
	var/turf/T = at_turf || get_turf(src)
	var/mob/living/carbon/human/understudy_form/skin = new form_type(T)
	skin.master = src
	skin.carry_damage = carry_damage
	current_form = skin
	RegisterSignal(skin, COMSIG_LIVING_DEATH, PROC_REF(OnFormDeath))
	if(carry_damage > 0)
		addtimer(CALLBACK(skin, TYPE_PROC_REF(/mob/living/carbon/human/understudy_form, ApplyCarryDamage)), 1 SECONDS)
	// Hide the true form while the skin fights.
	status_flags |= GODMODE
	density = FALSE
	alpha = 0
	invisibility = INVISIBILITY_MAXIMUM
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	can_act = FALSE
	LoseTarget()
	walk(src, 0)
	visible_message(span_warning("[skin] steps onto the stage."))

// Rotate without revealing the true form; HP carries via missing-HP brute.
/mob/living/simple_animal/hostile/distortion/understudy/proc/MorphForm()
	if(dying || stat == DEAD || QDELETED(src) || !current_form || QDELETED(current_form))
		return
	var/missing_hp = max(0, current_form.maxHealth - current_form.health)
	var/turf/T = get_turf(current_form)
	UnregisterSignal(current_form, COMSIG_LIVING_DEATH)
	qdel(current_form)
	current_form = null
	AssumeForm(missing_hp, T)

/mob/living/simple_animal/hostile/distortion/understudy/proc/OnFormDeath(mob/living/source)
	SIGNAL_HANDLER
	if(source != current_form)
		return
	UnregisterSignal(source, COMSIG_LIVING_DEATH)
	INVOKE_ASYNC(src, PROC_REF(RevealTrueForm), get_turf(source))

/mob/living/simple_animal/hostile/distortion/understudy/proc/RevealTrueForm(turf/exit_turf)
	if(dying || QDELETED(src))
		return
	if(!exit_turf)
		exit_turf = get_turf(current_form) || get_turf(src)
	// Burst the broken skin.
	if(current_form && !QDELETED(current_form))
		playsound(exit_turf, 'sound/effects/splat.ogg', 100, TRUE)
		for(var/turf/TF in orange(1, exit_turf))
			if(TF.density)
				continue
			var/obj/effect/decal/cleanable/blood/B = new(TF)
			B.bloodiness = 100
		new /obj/effect/gibspawner/human/bodypartless(exit_turf)
		qdel(current_form)
	current_form = null
	// Emerge: visible, tangible, vulnerable.
	forceMove(exit_turf)
	status_flags &= ~GODMODE
	density = TRUE
	alpha = 255
	invisibility = initial(invisibility)
	mouse_opacity = initial(mouse_opacity)
	new /obj/effect/temp_visual/dir_setting/wraith(exit_turf)
	say(pick(reveal_lines))
	reveals_done++
	ChangeResistances(resist_tiers[clamp(reveals_done, 1, length(resist_tiers))])
	adjustHealth(reveal_damage)
	if(stat == DEAD || health <= 0)
		if(stat != DEAD)
			death()
		return
	can_act = FALSE
	Stun(reveal_stun_time)
	addtimer(CALLBACK(src, PROC_REF(AssumeForm)), reform_delay)

// Phase-2 flip; PlayPhase2Cutscene runs async so the HP floor stays clamped
// (via phase_2_triggered) for the duration of the transition.
/mob/living/simple_animal/hostile/distortion/understudy/proc/EnterPhase2()
	if(phase_2_triggered || dying || QDELETED(src) || stat == DEAD)
		return
	phase_2_triggered = TRUE
	form_pool = phase_2_form_pool.Copy()
	last_form = null
	if(current_form && !QDELETED(current_form))
		UnregisterSignal(current_form, COMSIG_LIVING_DEATH)
		qdel(current_form)
		current_form = null
	INVOKE_ASYNC(src, PROC_REF(PlayPhase2Cutscene))

// 3s transition: knockback ring, jitter loop, all damage coeffs zeroed.
/mob/living/simple_animal/hostile/distortion/understudy/proc/PlayPhase2Cutscene()
	if(dying || QDELETED(src) || stat == DEAD)
		return
	var/turf/center = get_turf(src)
	if(center)
		for(var/mob/living/L in livinginrange(3, src))
			if(L == src || faction_check_mob(L) || L.stat == DEAD)
				continue
			if(L.anchored)
				continue
			var/dir_away = get_dir(center, get_turf(L))
			if(!dir_away)
				dir_away = pick(GLOB.cardinals)
			var/turf/landing = get_ranged_target_turf(L, dir_away, 3)
			L.throw_at(landing, 3, 2, src)
	density = TRUE
	alpha = 255
	invisibility = initial(invisibility)
	mouse_opacity = initial(mouse_opacity)
	ChangeResistances(list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0))
	visible_message(span_userdanger("\The [src] convulses, the borrowed shape splitting open as something hungrier rises through it!"))
	if(recognized)
		say(pick(lines_phase_2_ruvin))
	else
		say("...n-no more h-hiding... I'll be the th-thing you're afraid of-")
	var/end_time = world.time + 3 SECONDS
	while(world.time < end_time)
		if(dying || QDELETED(src) || stat == DEAD)
			return
		do_jitter_animation(300)
		sleep(5)
	if(dying || QDELETED(src) || stat == DEAD)
		return
	ChangeResistances(resist_tiers[clamp(reveals_done, 1, length(resist_tiers))])
	AssumeForm()

/mob/living/simple_animal/hostile/distortion/understudy/death(gibbed)
	if(dying)
		return ..()
	dying = TRUE
	if(current_form && !QDELETED(current_form))
		UnregisterSignal(current_form, COMSIG_LIVING_DEATH)
		qdel(current_form)
		current_form = null
	if(!isturf(loc))
		forceMove(get_turf(src))
	status_flags &= ~GODMODE
	density = TRUE
	alpha = 255
	invisibility = initial(invisibility)
	recognition_locked = FALSE
	if(recognized && boss_final_line)
		SpeakRecognition(boss_final_line)
	else
		say(pick(death_lines))
	. = ..()
	animate(src, alpha = 0, time = death_fade_time)
	QDEL_IN(src, death_fade_time)

// ---------- Skin base ----------
/mob/living/carbon/human/understudy_form
	// Die at 0 HP instead of entering carbon soft/hard crit - prevents players
	// disarming a downed form and walking off with its weapon.
	death_threshold = 0
	/// The true form hiding inside us.
	var/mob/living/simple_animal/hostile/distortion/understudy/master
	/// The role's signature melee weapon, placed in-hand for the AI.
	var/weapon_type
	/// Target effective basic-melee damage per hit; enforced via force_multiplier.
	var/weapon_force = 11
	/// Effective max HP, reached by buffing Fortitude.
	var/form_health = 350
	/// BRUTE applied shortly after spawn to carry over the prior form's missing
	/// HP. 0 = no carry (fresh first appearance).
	var/carry_damage = 0
	/// Damage soaked since this form was donned; triggers force-switch.
	var/damage_taken_this_form = 0
	var/force_switch_threshold = 75
	/// TRUE while a special is resolving - blocks the damage force-switch.
	var/in_special = FALSE
	var/special_cooldown = 0
	var/special_cooldown_time = 8 SECONDS
	var/special_range = 7
	var/special_timer
	var/form_outfit
	/// item path -> slot define for extra worn gear.
	var/list/extra_worn
	/// Dash forms set this; the dash opens the moment the skin is donned.
	var/dash_on_assume = FALSE
	/// Phase-2 faces stay donned and chain through their kit instead of
	/// auto-morphing after each special.
	var/persistent_form = FALSE
	/// Round-robin pointer into the form's ability rotation.
	var/ability_index = 1
	var/abilities_used_this_form = 0
	/// Force-morph after this many abilities (phase-2 faces override the 2).
	var/morph_after_abilities = 2
	/// Every weapon/armor/clothing item spawned for this form, kept so
	/// they qdel with the form regardless of where they ended up.
	var/list/costume_items = list()

/mob/living/carbon/human/understudy_form/Initialize(mapload)
	. = ..()
	faction = list("serio_zeal")
	// equipOutfit can sleep; defer the costume chain off Initialize.
	INVOKE_ASYNC(src, PROC_REF(SetupCostume))

/mob/living/carbon/human/understudy_form/proc/SetupCostume()
	if(QDELETED(src))
		return
	if(form_outfit)
		equipOutfit(form_outfit)
	// Strip any ego_weapon the outfit handed us — the form's weapon_type below is the authoritative kit. Without this, outfits like Ronin (belt katana) leave a second katana in inventory beside the hand one.
	if(weapon_type)
		for(var/obj/item/ego_weapon/E in get_equipped_items(TRUE))
			qdel(E)
		for(var/obj/item/I in held_items)
			if(istype(I, /obj/item/ego_weapon))
				qdel(I)
	for(var/worn_path in extra_worn)
		var/obj/item/X = new worn_path(src)
		MakeCostumeItem(X)
		equip_to_slot_or_del(X, extra_worn[worn_path])
	// Track equipped-slot items AND held items — get_equipped_items explicitly excludes held_items, which used to orphan the Ronin outfit's l_hand admin armor.
	for(var/obj/item/I in get_equipped_items(TRUE))
		MakeCostumeItem(I)
	for(var/obj/item/I in held_items)
		if(I)
			MakeCostumeItem(I)
	if(weapon_type)
		var/obj/item/W = new weapon_type(src)
		if(istype(W, /obj/item/ego_weapon))
			var/obj/item/ego_weapon/E = W
			if(E.force > 0)
				var/aspeed = E.attack_speed ? E.attack_speed : 1
				E.force_multiplier = (weapon_force * min(1, aspeed)) / E.force
		else
			W.force = weapon_force
		MakeCostumeItem(W)
		put_in_hands(W)
	ADD_TRAIT(src, TRAIT_SANITYIMMUNE, "understudy")
	ADD_TRAIT(src, TRAIT_BRUTEPALE, "understudy")
	ADD_TRAIT(src, TRAIT_BRUTESANITY, "understudy")
	ADD_TRAIT(src, TRAIT_PUSHIMMUNE, "understudy")
	ADD_TRAIT(src, TRAIT_SLEEPIMMUNE, "understudy")
	ADD_TRAIT(src, TRAIT_STUNIMMUNE, "understudy")
	ADD_TRAIT(src, TRAIT_IGNOREDAMAGESLOWDOWN, "understudy")
	add_movespeed_modifier(/datum/movespeed_modifier/understudy_form)
	updatehealth()
	var/datum/attribute/F = attributes?[FORTITUDE_ATTRIBUTE]
	if(F)
		var/needed = form_health - maxHealth
		if(needed != 0)
			F.adjust_buff(src, needed)
	updatehealth()
	RegisterSignal(src, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(OnDamageTaken))
	// Recompute force_multiplier per swing so weapons whose own attack() mutates `force` (Black Silence mook → 200 inside the concentration window, old_boys → 130 on parry_buff, allas → 70+ on dash) can't break the DPS-normalize.
	RegisterSignal(src, COMSIG_MOB_ITEM_ATTACK, PROC_REF(OnFormItemAttack))
	var/datum/attribute/J = attributes?[JUSTICE_ATTRIBUTE]
	if(J)
		J.adjust_buff(src, -get_attribute_level(src, JUSTICE_ATTRIBUTE))
	ai_controller = /datum/ai_controller/insane/murder/understudy
	InitializeAIController()
	special_timer = addtimer(CALLBACK(src, PROC_REF(SpecialTick)), 1 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)
	if(dash_on_assume)
		addtimer(CALLBACK(src, PROC_REF(TryOpeningDash)), 3)

// Qdels every tracked costume item by ref so disarmed/floor-dropped pieces still vanish with the form, not just gear still on the body.
/mob/living/carbon/human/understudy_form/Destroy()
	deltimer(special_timer)
	special_timer = null
	master = null
	for(var/obj/item/I as anything in costume_items.Copy())
		if(QDELETED(I))
			continue
		UnregisterSignal(I, COMSIG_PARENT_QDELETING)
		REMOVE_TRAIT(I, TRAIT_NODROP, "understudy")
		qdel(I)
	costume_items.Cut()
	return ..()

// The insane/murder AI calls dropItemToGround(I, force=TRUE) on weapons it deems underpowered, which bypasses TRAIT_NODROP. Refuse for tracked costume items.
/mob/living/carbon/human/understudy_form/dropItemToGround(obj/item/I, force = FALSE, silent = FALSE, invdrop = TRUE)
	if(I in costume_items)
		return FALSE
	return ..()

/mob/living/carbon/human/understudy_form/proc/OnCostumeItemQdel(datum/source)
	SIGNAL_HANDLER
	costume_items -= source

// Fires from the base /obj/item/proc/attack right before damage applies — subclass attack overrides have already mutated `force` by this point, so reading W.force gives the live value. Reclamp the multiplier so effective per-hit damage stays at weapon_force * min(1, attack_speed).
/mob/living/carbon/human/understudy_form/proc/OnFormItemAttack(datum/source, mob/living/M, mob/living/user, obj/item/weapon)
	SIGNAL_HANDLER
	if(!istype(weapon, /obj/item/ego_weapon))
		return
	var/obj/item/ego_weapon/W = weapon
	if(W.force <= 0)
		return
	var/aspeed = W.attack_speed ? W.attack_speed : 1
	W.force_multiplier = (weapon_force * min(1, aspeed)) / W.force

// Deferred via addtimer from AssumeForm so SetupCostume's Fortitude buff has
// settled. adjustBruteLoss bypasses COMSIG_MOB_AFTER_APPLY_DAMGE so this
// doesn't count toward force_switch_threshold.
/mob/living/carbon/human/understudy_form/proc/ApplyCarryDamage()
	if(QDELETED(src) || stat == DEAD)
		return
	if(carry_damage <= 0)
		return
	var/to_apply = min(carry_damage, max(0, maxHealth - 1))
	if(to_apply > 0)
		adjustBruteLoss(to_apply)
	carry_damage = 0

/mob/living/carbon/human/understudy_form/proc/MakeCostumeItem(obj/item/I)
	if(QDELETED(I))
		return
	if(istype(I, /obj/item/ego_weapon))
		var/obj/item/ego_weapon/E = I
		E.attribute_requirements = list()
	else if(istype(I, /obj/item/clothing/suit/armor/ego_gear))
		var/obj/item/clothing/suit/armor/ego_gear/G = I
		G.attribute_requirements = list()
	ADD_TRAIT(I, TRAIT_NODROP, "understudy")
	if(!(I in costume_items))
		costume_items += I
		RegisterSignal(I, COMSIG_PARENT_QDELETING, PROC_REF(OnCostumeItemQdel))

// Fires the signature special on cooldown when the AI has a live target.
/mob/living/carbon/human/understudy_form/proc/SpecialTick()
	if(QDELETED(src) || stat == DEAD)
		return
	if(world.time < special_cooldown || !ai_controller)
		return
	var/atom/T = ai_controller.blackboard[BB_INSANE_CURRENT_ATTACK_TARGET]
	if(!isliving(T) || QDELETED(T))
		return
	var/mob/living/L = T
	if(L.stat == DEAD || get_dist(src, L) > special_range)
		return
	special_cooldown = world.time + special_cooldown_time
	INVOKE_ASYNC(src, PROC_REF(DoSpecial), L)

// AI is paused for the duration so the form can't shamble or basic-melee
// while its ability resolves; ability-internal forceMoves bypass it.
/mob/living/carbon/human/understudy_form/proc/DoSpecial(mob/living/target)
	in_special = TRUE
	if(ai_controller)
		ai_controller.set_ai_status(AI_STATUS_OFF)
	UseSpecial(target)
	in_special = FALSE
	if(stat == DEAD || QDELETED(src))
		return
	if(ai_controller)
		ai_controller.set_ai_status(AI_STATUS_ON)
	abilities_used_this_form++
	var/should_morph
	if(morph_after_abilities > 0)
		should_morph = (abilities_used_this_form >= morph_after_abilities)
	else
		should_morph = !persistent_form
	if(!should_morph)
		return
	if(master && !QDELETED(master) && master.current_form == src)
		master.MorphForm()

// Nearest living non-faction foe within special_range, or null.
/mob/living/carbon/human/understudy_form/proc/FindNearbyPrey()
	var/mob/living/best
	var/best_dist = INFINITY
	for(var/mob/living/L in livinginrange(special_range, src))
		if(L == src || faction_check_mob(L) || L.stat == DEAD)
			continue
		var/d = get_dist(src, L)
		if(d < best_dist)
			best_dist = d
			best = L
	return best

// Dash forms open the fight by dashing immediately if a foe is in range,
// rather than waiting for SpecialTick.
/mob/living/carbon/human/understudy_form/proc/TryOpeningDash()
	if(QDELETED(src) || stat == DEAD)
		return
	var/mob/living/prey = FindNearbyPrey()
	if(!prey)
		return
	if(ai_controller)
		ai_controller.blackboard[BB_INSANE_CURRENT_ATTACK_TARGET] = prey
	special_cooldown = world.time + special_cooldown_time
	INVOKE_ASYNC(src, PROC_REF(DoSpecial), prey)

// Damage accumulates every tick and the morph fires the instant the threshold is crossed, even mid-special — the in-flight ability proc's SLEEP_CHECK_DEATH bails as soon as the form is qdel'd by MorphForm.
/mob/living/carbon/human/understudy_form/proc/OnDamageTaken(datum/source, damage_amount)
	SIGNAL_HANDLER
	if(stat == DEAD || QDELETED(src) || damage_amount <= 0)
		return
	if(health <= 0)
		return
	damage_taken_this_form += damage_amount
	if(damage_taken_this_form < force_switch_threshold)
		return
	if(master && !QDELETED(master) && master.current_form == src)
		INVOKE_ASYNC(master, TYPE_PROC_REF(/mob/living/simple_animal/hostile/distortion/understudy, MorphForm))

/// Per-form telegraphed, dodgeable attack. Overridden by each skin.
/mob/living/carbon/human/understudy_form/proc/UseSpecial(mob/living/target)
	return

// Shared helper: warn a list of turfs, wait, then hit them.
/mob/living/carbon/human/understudy_form/proc/StrikeTurfs(list/turfs, delay, damage, knockdown_time = 0)
	for(var/turf/T in turfs)
		new /obj/effect/temp_visual/understudy_warning(T)
	SLEEP_CHECK_DEATH(delay)
	var/list/been_hit = list()
	for(var/turf/T in turfs)
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		been_hit = HurtInTurf(T, been_hit, damage, RED_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		if(knockdown_time)
			for(var/mob/living/L in T)
				if(L == src || faction_check_mob(L))
					continue
				L.Knockdown(knockdown_time)

// ---------- Skin: Blade Lineage Ronin ----------
// Bespoke outfit — the original /datum/outfit/job/ronin shipped a belt katana (caused the second-weapon stack) and an admin armor in l_hand (the AI tried to swing it as a weapon). Strip both, keep only the cosmetic uniform/glasses/shoes; the form's own weapon_type + extra_worn line below cover the real kit.
/datum/outfit/understudy_ronin
	name = "Understudy: Blade Lineage Ronin"
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	glasses = /obj/item/clothing/glasses/sunglasses
	shoes = /obj/item/clothing/shoes/laceup

/mob/living/carbon/human/understudy_form/ronin
	form_outfit = /datum/outfit/understudy_ronin
	extra_worn = list(/obj/item/clothing/suit/armor/ego_gear/city/blade_lineage_salsu = ITEM_SLOT_OCLOTHING)
	weapon_type = /obj/item/ego_weapon/city/bladelineage
	weapon_force = 14
	special_cooldown_time = 9 SECONDS
	/// Yield My Flesh parry-stance flag.
	var/countering = FALSE
	var/counter_window = 2.5 SECONDS
	/// Counter base; scaled = base * (3 - 2*ratio). 40 at full HP, 120 at 0 HP.
	var/counter_base_damage = 40

// Yield My Flesh - parry stance; first hit consumed counters with HP-scaled damage.
/mob/living/carbon/human/understudy_form/ronin/UseSpecial(mob/living/target)
	if(countering)
		return
	face_atom(target)
	say("Y-yield... your flesh-")
	countering = TRUE
	add_atom_colour("#8B0000", TEMPORARY_COLOUR_PRIORITY)
	new /obj/effect/temp_visual/understudy_warning(get_turf(src))
	Immobilize(counter_window, TRUE)
	playsound(get_turf(src), 'sound/weapons/sear.ogg', 70, TRUE, 5)
	SLEEP_CHECK_DEATH(counter_window)
	if(countering)
		countering = FALSE
		remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#8B0000")

/mob/living/carbon/human/understudy_form/ronin/attacked_by(obj/item/I, mob/living/user)
	if(countering && isliving(user) && user != src && !faction_check_mob(user))
		DoCounter(user, FALSE)
		return
	return ..()

/mob/living/carbon/human/understudy_form/ronin/bullet_act(obj/projectile/P, def_zone, piercing_hit = FALSE)
	if(countering && P && isliving(P.firer) && !faction_check_mob(P.firer))
		DoCounter(P.firer, TRUE)
		return BULLET_ACT_BLOCK
	return ..()

/mob/living/carbon/human/understudy_form/ronin/proc/DoCounter(mob/living/attacker, ranged)
	if(!countering || QDELETED(attacker))
		return
	countering = FALSE
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#8B0000")
	if(ranged)
		var/turf/blink = get_step(get_turf(attacker), pick(GLOB.cardinals))
		if(blink && !blink.density)
			forceMove(blink)
		playsound(get_turf(src), 'sound/weapons/fwoosh.ogg', 50, TRUE)
	face_atom(attacker)
	do_attack_animation(attacker)
	playsound(get_turf(src), 'sound/weapons/bladeslice.ogg', 80, TRUE, 5)
	var/ratio = clamp(health / maxHealth, 0, 1)
	var/scaled = round(counter_base_damage * (3 - 2 * ratio))
	attacker.deal_damage(scaled, RED_DAMAGE, src,
		attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	attacker.apply_lc_bleed(3)

// ---------- Skin: Backstreets Butcher ----------
/mob/living/carbon/human/understudy_form/butcher
	form_outfit = /datum/outfit/job/butcher
	weapon_type = /obj/item/ego_weapon/city/district23/pierre
	weapon_force = 14
	special_cooldown_time = 10 SECONDS

/mob/living/carbon/human/understudy_form/butcher/UseSpecial(mob/living/target)
	say("B-behind... you-")
	var/turf/behind = get_step(target, turn(target.dir, 180))
	if(!behind || behind.density)
		for(var/turf/T in shuffle(range(1, target)))
			if(T == get_turf(target) || T.density)
				continue
			behind = T
			break
	if(behind && !behind.density)
		forceMove(behind)
	face_atom(target)
	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(src), dir)
	playsound(get_turf(src), 'sound/weapons/chainhit.ogg', 70, TRUE, 5)
	var/turf/center = get_turf(src)
	if(!center)
		return
	StrikeTurfs(range(2, center), UNDERSTUDY_TELEGRAPH_MEDIUM, 28)

// ---------- Skin: Rat Scavenger — Junk Lob ----------
/mob/living/carbon/human/understudy_form/scavenger
	form_outfit = /datum/outfit/job/scavenger
	weapon_type = /obj/item/ego_weapon/city/rats
	weapon_force = 14
	special_cooldown_time = 7 SECONDS

/mob/living/carbon/human/understudy_form/scavenger/UseSpecial(mob/living/target)
	say("Scraps... for s-scraps-")
	var/turf/center = get_turf(target)
	if(!center)
		return
	playsound(get_turf(src), 'sound/items/dodgeball.ogg', 60, TRUE, 4)
	StrikeTurfs(range(2, center), UNDERSTUDY_TELEGRAPH_FAST, 24)

// ---------- Skin: Kurokumo Captain ----------
/mob/living/carbon/human/understudy_form/captain
	form_outfit = /datum/outfit/job/kurocaptain
	extra_worn = list(/obj/item/clothing/suit/armor/ego_gear/city/kurokumo = ITEM_SLOT_OCLOTHING)
	weapon_type = /obj/item/ego_weapon/city/kurokumo
	// Kurokumo self-crits 3x; halve weapon_force to keep DPS in cast range.
	weapon_force = 5
	special_cooldown_time = 9 SECONDS

/mob/living/carbon/human/understudy_form/captain/UseSpecial(mob/living/target)
	face_atom(target)
	say("C-critical... watch m-me-")
	Immobilize(UNDERSTUDY_TELEGRAPH_MEDIUM, TRUE)
	var/turf/ahead = get_step(src, dir)
	var/turf/far = ahead ? get_step(ahead, dir) : null
	var/turf/farther = far ? get_step(far, dir) : null
	var/list/arc = list()
	if(ahead)
		arc += range(1, ahead)
	if(far)
		arc |= range(1, far)
	if(farther)
		arc |= range(1, farther)
	visible_message(span_danger("[src] coils for a critical stroke!"))
	playsound(get_turf(src), 'sound/weapons/bladeslice.ogg', 75, TRUE, 5)
	StrikeTurfs(arc, UNDERSTUDY_TELEGRAPH_MEDIUM, 72)

// ---------- Skin: Middle Big Brother ----------
/mob/living/carbon/human/understudy_form/big_brother
	form_outfit = /datum/outfit/job/big_brother
	// Job outfit strips sunglasses from non-players; cape lives on the EGO armor.
	extra_worn = list(
		/obj/item/clothing/suit/armor/ego_gear/city/middle_big = ITEM_SLOT_OCLOTHING,
		/obj/item/clothing/neck/ego_neck/middle_cape = ITEM_SLOT_NECK,
		/obj/item/clothing/glasses/middle_sunglasses = ITEM_SLOT_EYES,
	)
	weapon_type = /obj/item/ego_weapon/shield/middle_chain/big
	weapon_force = 14
	special_range = 9
	special_cooldown_time = 11 SECONDS
	var/countering = FALSE
	var/counter_window = 2.5 SECONDS
	var/counter_damage = 45

/mob/living/carbon/human/understudy_form/big_brother/UseSpecial(mob/living/target)
	if(countering)
		return
	face_atom(target)
	say("F-family... comes f-first-")
	countering = TRUE
	add_atom_colour("#8B008B", TEMPORARY_COLOUR_PRIORITY)
	new /obj/effect/temp_visual/understudy_warning(get_turf(src))
	Immobilize(counter_window, TRUE)
	playsound(get_turf(src), 'sound/weapons/genhit.ogg', 60, TRUE, 4)
	SLEEP_CHECK_DEATH(counter_window)
	EndCounter()

/mob/living/carbon/human/understudy_form/big_brother/proc/EndCounter()
	if(!countering)
		return
	countering = FALSE
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#8B008B")

/mob/living/carbon/human/understudy_form/big_brother/proc/DoCounter(mob/living/attacker, ranged)
	if(!countering || QDELETED(attacker))
		return
	countering = FALSE
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#8B008B")
	if(ranged)
		var/turf/blink = get_step(get_turf(attacker), pick(GLOB.cardinals))
		if(blink && !blink.density)
			forceMove(blink)
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(src), dir)
		playsound(get_turf(src), 'sound/weapons/fwoosh.ogg', 50, TRUE)
	face_atom(attacker)
	do_attack_animation(attacker)
	playsound(get_turf(src), 'sound/weapons/chainhit.ogg', 80, TRUE, 5)
	attacker.deal_damage(counter_damage, BLACK_DAMAGE, src,
		attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	attacker.throw_at(get_edge_target_turf(attacker, get_dir(src, attacker)), 3, 2, src)
	attacker.Knockdown(1 SECONDS)
	var/list/been_hit = list()
	for(var/turf/T in range(1, src))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		been_hit = HurtInTurf(T, been_hit, 18, BLACK_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		for(var/mob/living/L in T)
			if(L == src || L == attacker || faction_check_mob(L))
				continue
			L.Knockdown(1 SECONDS)

/mob/living/carbon/human/understudy_form/big_brother/attacked_by(obj/item/I, mob/living/user)
	if(countering && isliving(user) && user != src && !faction_check_mob(user))
		DoCounter(user, FALSE)
		return
	return ..()

/mob/living/carbon/human/understudy_form/big_brother/bullet_act(obj/projectile/P, def_zone, piercing_hit = FALSE)
	if(countering && P && isliving(P.firer) && !faction_check_mob(P.firer))
		DoCounter(P.firer, TRUE)
		return BULLET_ACT_BLOCK
	return ..()

// ---------- Skin: N Corp Grosshammer ----------
/mob/living/carbon/human/understudy_form/grosshammer
	form_outfit = /datum/outfit/job/grosshammer
	extra_worn = list(
		/obj/item/clothing/suit/armor/ego_gear/city/grosshammmer = ITEM_SLOT_OCLOTHING,
		/obj/item/clothing/head/ego_hat/helmet/ncorp/grosshammer = ITEM_SLOT_HEAD,
	)
	weapon_type = /obj/item/ego_weapon/city/ncorp_hammer/big
	weapon_force = 14
	special_range = 8
	special_cooldown_time = 11 SECONDS

/mob/living/carbon/human/understudy_form/grosshammer/UseSpecial(mob/living/target)
	say("P-purge... purge it ALL-")
	var/list/marks = list()
	for(var/mob/living/L in livinginrange(special_range, src))
		if(L == src || faction_check_mob(L) || L.stat == DEAD)
			continue
		marks |= get_turf(L)
	if(!length(marks) && target)
		marks += get_turf(target)
	if(!length(marks))
		return
	var/list/blast = list()
	for(var/turf/M in marks)
		new /obj/effect/temp_visual/remorse(M)
		for(var/turf/T in range(1, M))
			blast |= T
	for(var/turf/T in blast)
		new /obj/effect/temp_visual/understudy_warning(T)
	playsound(get_turf(src), 'sound/weapons/fixer/generic/nail2.ogg', 70, TRUE, 5)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_FAST)
	var/list/been_hit = list()
	for(var/turf/T in blast)
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		been_hit = HurtInTurf(T, been_hit, 32, BLACK_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	playsound(get_turf(src), 'sound/weapons/genhit3.ogg', 80, TRUE, 6)

// ---------- Skin: Index Messenger ----------
/mob/living/carbon/human/understudy_form/messenger
	form_outfit = /datum/outfit/job/messenger
	extra_worn = list(/obj/item/clothing/suit/armor/ego_gear/city/index_mess = ITEM_SLOT_OCLOTHING)
	weapon_type = /obj/item/ego_weapon/city/index/yan
	weapon_force = 15
	special_range = 7
	special_cooldown_time = 10 SECONDS

/mob/living/carbon/human/understudy_form/messenger/UseSpecial(mob/living/target)
	face_atom(target)
	say("Your p-prescript... is DEATH-")
	Immobilize(UNDERSTUDY_TELEGRAPH_FAST, TRUE)
	var/turf/mark = get_turf(target)
	if(!mark)
		return
	for(var/turf/T in range(2, mark))
		new /obj/effect/temp_visual/understudy_warning(T)
	playsound(get_turf(src), 'sound/weapons/sear.ogg', 70, TRUE, 5)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_FAST)
	for(var/turf/T in range(2, mark))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		for(var/mob/living/L in T)
			if(L == src || faction_check_mob(L))
				continue
			var/dmg = 34
			if(L.health < L.maxHealth * 0.5)
				dmg = round(dmg * 1.45)
			L.deal_damage(dmg, BLACK_DAMAGE, src,
				attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	playsound(get_turf(src), 'sound/weapons/genhit3.ogg', 70, TRUE, 5)

// ---------- Skin: Dieci ----------
/mob/living/carbon/human/understudy_form/dieci
	form_outfit = /datum/outfit/understudy_dieci
	extra_worn = list(/obj/item/clothing/suit/armor/ego_gear/city/dieci = ITEM_SLOT_OCLOTHING)
	weapon_type = /obj/item/ego_weapon/city/dieci/understudy
	weapon_force = 14
	special_range = 5
	special_cooldown_time = 9 SECONDS

/mob/living/carbon/human/understudy_form/dieci/UseSpecial(mob/living/target)
	say("The g-grand... finale-")
	for(var/turf/T in range(3, src))
		new /obj/effect/temp_visual/understudy_warning(T)
	playsound(get_turf(src), 'sound/weapons/sear.ogg', 70, TRUE, 6)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_SLOW)
	var/turf/center = get_turf(src)
	if(!center)
		return
	var/list/been_hit = list()
	var/list/victims = list()
	for(var/turf/T in range(3, center))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		been_hit = HurtInTurf(T, been_hit, 24, PALE_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_SPECIAL))
		for(var/mob/living/L in T)
			if(L == src || faction_check_mob(L) || (L in victims))
				continue
			victims += L
	for(var/mob/living/L in victims)
		L.apply_lc_sinking(4)
		L.throw_at(get_edge_target_turf(L, get_dir(center, L)), 3, 2, src)

/datum/outfit/understudy_dieci
	name = "Understudy - Dieci"
	uniform = /obj/item/clothing/under/color/black
	shoes = /obj/item/clothing/shoes/sneakers/black

// ============================================================
// City Association forms
// ============================================================

// Centipede-style lunge: 3-wide strip warned along the line, forceMove to the
// far open tile, then strike. Returns living victims for caller status.
/mob/living/carbon/human/understudy_form/proc/DashStrike(atom/target, reach = 6, damage = 26, delay = 7, trail_type = null, damage_type = RED_DAMAGE)
	face_atom(target)
	var/turf/start = get_turf(src)
	var/turf/dest = get_turf(target)
	if(!start || !dest)
		return list()
	// Aim 2 tiles past the target so the dash ends on top of them.
	var/dir_to = get_dir(start, dest)
	var/turf/endpoint = dest
	for(var/i in 1 to 2)
		var/turf/nxt = get_step(endpoint, dir_to)
		if(!nxt || nxt.density)
			break
		endpoint = nxt
	var/list/line = getline(start, endpoint)
	if(length(line) > reach + 1)
		line.Cut(reach + 2)
	var/list/strip = list()
	var/turf/landing = start
	var/broken = FALSE
	for(var/turf/T in line)
		if(T.density)
			broken = TRUE
		else if(!broken)
			landing = T
		for(var/turf/W in range(1, T))
			strip |= W
	for(var/turf/T in strip)
		new /obj/effect/temp_visual/understudy_warning(T)
	Immobilize(delay + 1, TRUE)
	SLEEP_CHECK_DEATH(delay)
	if(landing && !landing.density)
		forceMove(landing)
	var/list/been_hit = list()
	for(var/turf/T in strip)
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		been_hit = HurtInTurf(T, been_hit, damage, damage_type,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	if(trail_type)
		for(var/turf/T in line)
			if(!T.density)
				new trail_type(T)
	var/list/victims = list()
	for(var/mob/living/L in been_hit)
		if(L != src && !faction_check_mob(L))
			victims |= L
	return victims

// ---------- Skin: Zwei Association ----------
/mob/living/carbon/human/understudy_form/zwei
	form_outfit = /datum/outfit/understudy_zwei
	extra_worn = list(/obj/item/clothing/suit/armor/ego_gear/city/zwei = ITEM_SLOT_OCLOTHING)
	weapon_type = /obj/item/ego_weapon/city/zweihander
	weapon_force = 14
	special_range = 8
	special_cooldown_time = 10 SECONDS
	dash_on_assume = TRUE

/mob/living/carbon/human/understudy_form/zwei/UseSpecial(mob/living/target)
	say("F-fall... in line-")
	playsound(get_turf(src), 'sound/weapons/genhit.ogg', 70, TRUE, 4)
	DashStrike(target, 6, 26, UNDERSTUDY_TELEGRAPH_MEDIUM)
	if(QDELETED(src) || stat == DEAD)
		return
	var/turf/center = get_turf(src)
	if(!center)
		return
	for(var/turf/T in range(2, center))
		new /obj/effect/temp_visual/understudy_warning(T)
	playsound(get_turf(src), 'sound/weapons/genhit.ogg', 80, TRUE, 5)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_MEDIUM)
	var/list/been_hit = list()
	for(var/turf/T in range(2, center))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		been_hit = HurtInTurf(T, been_hit, 18, RED_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		for(var/mob/living/L in T)
			if(L == src || faction_check_mob(L))
				continue
			L.throw_at(get_edge_target_turf(L, get_dir(center, L)), 4, 2, src)
			L.Knockdown(1 SECONDS)

// ---------- Skin: Shi Association ----------
/mob/living/carbon/human/understudy_form/shi
	form_outfit = /datum/outfit/understudy_shi
	extra_worn = list(/obj/item/clothing/suit/armor/ego_gear/city/shi = ITEM_SLOT_OCLOTHING)
	weapon_type = /obj/item/ego_weapon/city/shi_assassin
	weapon_force = 13
	special_range = 8
	special_cooldown_time = 8 SECONDS
	dash_on_assume = TRUE

/mob/living/carbon/human/understudy_form/shi/UseSpecial(mob/living/target)
	say("...n-no witnesses-")
	playsound(get_turf(src), 'sound/weapons/bladeslice.ogg', 75, TRUE, 4)
	DashStrike(target, 6, 28, UNDERSTUDY_TELEGRAPH_MEDIUM)
	// Flicker again at the (possibly moved) target with half damage / wind-up.
	if(QDELETED(src) || stat == DEAD || QDELETED(target) || target.stat == DEAD)
		return
	playsound(get_turf(src), 'sound/weapons/bladeslice.ogg', 75, TRUE, 4)
	DashStrike(target, 6, 14, UNDERSTUDY_TELEGRAPH_FAST)

/obj/effect/turf_fire/ardor/understudy
	burn_time = 10 SECONDS

// ---------- Skin: Liu Association ----------
/mob/living/carbon/human/understudy_form/liu
	form_outfit = /datum/outfit/understudy_liu
	extra_worn = list(/obj/item/clothing/suit/armor/ego_gear/city/liu = ITEM_SLOT_OCLOTHING)
	weapon_type = /obj/item/ego_weapon/city/liu/fire
	weapon_force = 13
	special_range = 8
	special_cooldown_time = 9 SECONDS
	dash_on_assume = TRUE

/mob/living/carbon/human/understudy_form/liu/UseSpecial(mob/living/target)
	say("F-feel it... feel ALIVE-")
	playsound(get_turf(src), 'sound/weapons/sear.ogg', 70, TRUE, 5)
	var/list/victims = DashStrike(target, 6, 22, UNDERSTUDY_TELEGRAPH_MEDIUM, /obj/effect/turf_fire/ardor/understudy)
	for(var/mob/living/L in victims)
		L.apply_lc_overheat(6)

// ---------- Skin: Seven Association ----------
/mob/living/carbon/human/understudy_form/seven
	form_outfit = /datum/outfit/understudy_seven
	extra_worn = list(/obj/item/clothing/suit/armor/ego_gear/city/seven = ITEM_SLOT_OCLOTHING)
	weapon_type = /obj/item/ego_weapon/city/seven
	weapon_force = 13
	special_range = 8
	special_cooldown_time = 9 SECONDS
	dash_on_assume = TRUE

/mob/living/carbon/human/understudy_form/seven/UseSpecial(mob/living/target)
	say("H-hold... still-")
	playsound(get_turf(src), 'sound/weapons/sear.ogg', 70, TRUE, 4)
	var/list/victims = DashStrike(target, 6, 24, UNDERSTUDY_TELEGRAPH_MEDIUM)
	for(var/mob/living/L in victims)
		L.apply_lc_rupture(6)

// ---------- Skin: Devyat Association ----------
/mob/living/carbon/human/understudy_form/devyat
	form_outfit = /datum/outfit/understudy_devyat
	extra_worn = list(/obj/item/clothing/suit/armor/ego_gear/city/devyat_suit = ITEM_SLOT_OCLOTHING)
	weapon_type = /obj/item/ego_weapon/city/devyat_trunk
	weapon_force = 14
	special_range = 7
	special_cooldown_time = 11 SECONDS

/mob/living/carbon/human/understudy_form/devyat/UseSpecial(mob/living/target)
	say("D-down... you go-")
	var/turf/center = get_turf(target)
	if(!center)
		return
	for(var/turf/T in range(2, center))
		new /obj/effect/temp_visual/understudy_warning(T)
	playsound(get_turf(src), 'sound/weapons/genhit3.ogg', 70, TRUE, 6)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_MEDIUM)
	if(QDELETED(src) || stat == DEAD)
		return
	// Leap onto the marked tile after the wind-up; anyone who stepped off is clear.
	if(center && !center.density)
		forceMove(center)
	var/list/been_hit = list()
	for(var/turf/T in range(2, center))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		been_hit = HurtInTurf(T, been_hit, 28, RED_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		for(var/mob/living/L in T)
			if(L == src || faction_check_mob(L))
				continue
			L.Knockdown(2 SECONDS)
			L.apply_lc_defense_level_down(4)
	playsound(get_turf(src), 'sound/weapons/genhit3.ogg', 80, TRUE, 6)

/datum/outfit/understudy_zwei
	name = "Understudy - Zwei"
	uniform = /obj/item/clothing/under/color/black
	shoes = /obj/item/clothing/shoes/sneakers/black

/datum/outfit/understudy_shi
	name = "Understudy - Shi"
	uniform = /obj/item/clothing/under/color/black
	shoes = /obj/item/clothing/shoes/sneakers/black

/datum/outfit/understudy_liu
	name = "Understudy - Liu"
	uniform = /obj/item/clothing/under/color/black
	shoes = /obj/item/clothing/shoes/sneakers/black

/datum/outfit/understudy_seven
	name = "Understudy - Seven"
	uniform = /obj/item/clothing/under/color/black
	shoes = /obj/item/clothing/shoes/sneakers/black

/datum/outfit/understudy_devyat
	name = "Understudy - Devyat"
	uniform = /obj/item/clothing/under/color/black
	shoes = /obj/item/clothing/shoes/sneakers/black

// ============================================================
// Phase 2 forms
// ============================================================

// ---------- Skin: Red Mist (Kali) ----------
/obj/item/clothing/suit/jacket/leather/overcoat/red_mist
	name = "Red Mist's overcoat"
	desc = "A worn leather overcoat, the inside crusted to a permanent dark red."
	armor = list(RED_DAMAGE = 70, WHITE_DAMAGE = 70, BLACK_DAMAGE = 70, PALE_DAMAGE = 90)

/datum/outfit/understudy_red_mist
	name = "Understudy - Red Mist"
	uniform = /obj/item/clothing/under/color/maroon
	suit = /obj/item/clothing/suit/jacket/leather/overcoat/red_mist
	shoes = /obj/item/clothing/shoes/workboots/mining

/mob/living/carbon/human/understudy_form/red_mist
	form_outfit = /datum/outfit/understudy_red_mist
	weapon_type = /obj/item/ego_weapon/mimicry/kali
	weapon_force = 16
	form_health = 250
	special_range = 7
	special_cooldown_time = 9 SECONDS
	persistent_form = TRUE
	force_switch_threshold = 100
	morph_after_abilities = 5

/mob/living/carbon/human/understudy_form/red_mist/SetupCostume()
	. = ..()
	if(QDELETED(src))
		return
	gender = FEMALE
	body_type = FEMALE
	skin_tone = "caucasian1"
	hair_color = "9B1B1F"
	hairstyle = "Very Long Hair"
	eye_color = "6B0202"
	facial_hairstyle = "Shaved"
	fully_replace_character_name(real_name, "Kali")
	update_body()
	update_hair()
	remove_movespeed_modifier(/datum/movespeed_modifier/understudy_form)
	add_movespeed_modifier(/datum/movespeed_modifier/understudy_form/fast)

/mob/living/carbon/human/understudy_form/red_mist/UseSpecial(mob/living/target)
	switch(ability_index)
		if(1)
			Realization(target)
		if(2)
			Onrush(target)
		if(3)
			FocusSpirit(target)
		if(4)
			GreaterSplitVertical(target)
		if(5)
			GreaterSplitHorizontal(target)
	ability_index = (ability_index % 5) + 1

// Realization - 7x7 cleave with 40 HP lifesteal per unique target (cap 3).
/mob/living/carbon/human/understudy_form/red_mist/proc/Realization(mob/living/target)
	face_atom(target)
	say("...c-come closer-")
	Immobilize(UNDERSTUDY_TELEGRAPH_SLOW, TRUE)
	var/turf/center = get_turf(src)
	if(!center)
		return
	for(var/turf/T in range(3, center))
		new /obj/effect/temp_visual/understudy_warning(T)
	playsound(get_turf(src), 'sound/abnormalities/nothingthere/attack.ogg', 80, TRUE, 6)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_SLOW)
	if(QDELETED(src) || stat == DEAD)
		return
	center = get_turf(src)
	if(!center)
		return
	var/list/been_hit = list()
	for(var/turf/T in range(3, center))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		been_hit = HurtInTurf(T, been_hit, 32, RED_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	var/healed = 0
	var/counted = 0
	for(var/mob/living/L in been_hit)
		if(L == src || faction_check_mob(L))
			continue
		counted++
		if(counted > 3)
			break
		healed += 40
	if(healed)
		adjustBruteLoss(-healed)

// Onrush - 3-wide dash slash; chains to a fresh target on kill (max 2 chains).
/mob/living/carbon/human/understudy_form/red_mist/proc/Onrush(mob/living/target, chains_left = 2)
	if(QDELETED(target) || target.stat == DEAD)
		return
	face_atom(target)
	say("...O-ON-RUSH-")
	var/turf/start = get_turf(src)
	var/turf/dest = get_turf(target)
	if(!start || !dest)
		return
	// Carry 2 tiles past the target, stop at the first wall.
	var/dir_to = get_dir(start, dest)
	var/turf/endpoint = dest
	for(var/i in 1 to 2)
		var/turf/nxt = get_step(endpoint, dir_to)
		if(!nxt || nxt.density)
			break
		endpoint = nxt
	var/list/line = getline(start, endpoint)
	if(length(line) > 8)
		line.Cut(9)
	var/list/strip = list()
	var/turf/landing = start
	for(var/turf/T in line)
		if(T.density)
			break
		landing = T
		for(var/turf/W in range(1, T))
			strip |= W
	for(var/turf/T in strip)
		new /obj/effect/temp_visual/understudy_warning(T)
	Immobilize(UNDERSTUDY_TELEGRAPH_MEDIUM + 1, TRUE)
	playsound(get_turf(src), 'sound/weapons/bladeslice.ogg', 75, TRUE, 5)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_MEDIUM)
	if(QDELETED(src) || stat == DEAD)
		return
	if(landing && !landing.density)
		forceMove(landing)
	var/list/been_hit = list()
	for(var/turf/T in strip)
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		been_hit = HurtInTurf(T, been_hit, 26, RED_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	var/killed = FALSE
	for(var/mob/living/L in been_hit)
		if(L == src || faction_check_mob(L))
			continue
		L.apply_lc_bleed(3)
		if(L.stat == DEAD)
			killed = TRUE
	if(!killed || chains_left <= 0)
		return
	var/mob/living/next_target = FindNearbyPrey()
	if(!next_target || next_target == target)
		return
	SLEEP_CHECK_DEATH(3)
	Onrush(next_target, chains_left - 1)

// Focus Spirit - self-buff stance (Defense Level Up), then a 5x5 cleave.
/mob/living/carbon/human/understudy_form/red_mist/proc/FocusSpirit(mob/living/target)
	say("...f-focus... s-spirit-")
	Immobilize(2 SECONDS, TRUE)
	add_atom_colour("#FF4444", TEMPORARY_COLOUR_PRIORITY)
	new /obj/effect/temp_visual/understudy_warning(get_turf(src))
	playsound(get_turf(src), 'sound/weapons/genhit.ogg', 60, TRUE)
	apply_lc_defense_level_up(20)
	SLEEP_CHECK_DEATH(15)
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#FF4444")
	if(QDELETED(src) || stat == DEAD)
		return
	face_atom(target)
	playsound(get_turf(src), 'sound/weapons/bladeslice.ogg', 90, TRUE, 6)
	var/turf/center = get_turf(src)
	if(!center)
		return
	for(var/turf/T in range(2, center))
		new /obj/effect/temp_visual/understudy_warning(T)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_MEDIUM)
	if(QDELETED(src) || stat == DEAD)
		return
	var/list/been_hit = list()
	for(var/turf/T in range(2, center))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		been_hit = HurtInTurf(T, been_hit, 45, RED_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	for(var/mob/living/L in been_hit)
		if(L == src || faction_check_mob(L))
			continue
		L.apply_lc_bleed(4)

// Greater Split: Vertical - 5x5, per-target cinematic, 500 RED on resolve.
/mob/living/carbon/human/understudy_form/red_mist/proc/GreaterSplitVertical(mob/living/target)
	face_atom(target)
	say("...g-greater... split-")
	Immobilize(UNDERSTUDY_TELEGRAPH_MEDIUM, TRUE)
	var/turf/center = get_turf(src)
	if(!center)
		return
	for(var/turf/T in range(2, center))
		new /obj/effect/temp_visual/understudy_warning(T)
	playsound(get_turf(src), 'sound/weapons/bladeslice.ogg', 90, TRUE, 6)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_MEDIUM)
	if(QDELETED(src) || stat == DEAD)
		return
	center = get_turf(src)
	if(!center)
		return
	var/list/victims = list()
	for(var/turf/T in range(2, center))
		for(var/mob/living/L in T)
			if(L == src || faction_check_mob(L) || L.stat == DEAD)
				continue
			if(L.status_flags & GODMODE)
				continue
			victims |= L
	if(length(victims))
		// Lock victims for the cinematic; Cinematic blocks ~1.52 s.
		for(var/mob/living/L in victims)
			L.Immobilize(15.2, TRUE)
		Cinematic(CINEMATIC_GREATER_SPLIT_V, victims)
	if(QDELETED(src) || stat == DEAD)
		return
	for(var/mob/living/L in victims)
		if(QDELETED(L) || L.stat == DEAD || (L.status_flags & GODMODE))
			continue
		L.deal_damage(500, RED_DAMAGE, src,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	say("...V-v-vert-tical-")

// Greater Split: Horizontal - 9x9, longer wind-up, 750 RED on resolve.
/mob/living/carbon/human/understudy_form/red_mist/proc/GreaterSplitHorizontal(mob/living/target)
	face_atom(target)
	say("...G-GREATER SPLIT-")
	Immobilize(UNDERSTUDY_TELEGRAPH_SLOW, TRUE)
	var/turf/center = get_turf(src)
	if(!center)
		return
	for(var/turf/T in range(4, center))
		new /obj/effect/temp_visual/understudy_warning(T)
	playsound(get_turf(src), 'sound/weapons/bladeslice.ogg', 100, TRUE, 8)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_SLOW)
	if(QDELETED(src) || stat == DEAD)
		return
	center = get_turf(src)
	if(!center)
		return
	var/list/victims = list()
	for(var/turf/T in range(4, center))
		for(var/mob/living/L in T)
			if(L == src || faction_check_mob(L) || L.stat == DEAD)
				continue
			if(L.status_flags & GODMODE)
				continue
			victims |= L
	if(length(victims))
		// Lock victims for the cinematic; Cinematic blocks ~1.4 s.
		for(var/mob/living/L in victims)
			L.Immobilize(14, TRUE)
		Cinematic(CINEMATIC_GREATER_SPLIT_H, victims)
	if(QDELETED(src) || stat == DEAD)
		return
	for(var/mob/living/L in victims)
		if(QDELETED(L) || L.stat == DEAD || (L.status_flags & GODMODE))
			continue
		L.deal_damage(750, RED_DAMAGE, src,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	say("...H-H-HORI-ZONTAL-")

// ---------- Skin: Black Silence (Roland) ----------
/obj/item/clothing/under/suit/charcoal/black_silence
	name = "Black Silence's suit"
	desc = "A charcoal agent's suit. The lining is woven from something that doesn't quite cut."
	armor = list(RED_DAMAGE = 70, WHITE_DAMAGE = 70, BLACK_DAMAGE = 70, PALE_DAMAGE = 90)

/datum/outfit/understudy_black_silence
	name = "Understudy - Black Silence"
	uniform = /obj/item/clothing/under/suit/charcoal/black_silence
	shoes = /obj/item/clothing/shoes/laceup
	mask = /obj/item/clothing/mask/silence
	gloves = /obj/item/clothing/gloves/color/black

/mob/living/carbon/human/understudy_form/black_silence
	form_outfit = /datum/outfit/understudy_black_silence
	weapon_type = /obj/item/ego_weapon/black_silence_gloves/zelkova
	weapon_force = 14
	form_health = 250
	special_range = 8
	special_cooldown_time = 6 SECONDS
	dash_on_assume = TRUE
	persistent_form = TRUE
	force_switch_threshold = 75
	morph_after_abilities = 11
	/// 9 canon workshops + base Gloves for the Furioso slot.
	var/list/weapon_rotation = list(
		/obj/item/ego_weapon/black_silence_gloves/zelkova,
		/obj/item/ego_weapon/black_silence_gloves/ranga,
		/obj/item/ego_weapon/black_silence_gloves/old_boys,
		/obj/item/ego_weapon/black_silence_gloves/allas,
		/obj/item/ego_weapon/black_silence_gloves/mook,
		/obj/item/ego_weapon/black_silence_gloves/logic,
		/obj/item/ego_weapon/black_silence_gloves/durandal,
		/obj/item/ego_weapon/black_silence_gloves/crystal,
		/obj/item/ego_weapon/black_silence_gloves/wheels,
		/obj/item/ego_weapon/black_silence_gloves,
	)
	/// Old Boys (slot 3) parry-stance flag.
	var/countering = FALSE

/mob/living/carbon/human/understudy_form/black_silence/SetupCostume()
	. = ..()
	if(QDELETED(src))
		return
	gender = MALE
	body_type = MALE
	skin_tone = "caucasian1"
	hair_color = "1A1A1A"
	hairstyle = "Business Hair 3"
	eye_color = "3D2817"
	facial_hairstyle = "Shaved"
	fully_replace_character_name(real_name, "Roland")
	update_body()
	update_hair()
	SwapToWeapon(1)

/mob/living/carbon/human/understudy_form/black_silence/proc/SwapToWeapon(slot)
	if(QDELETED(src) || stat == DEAD)
		return
	if(slot < 1 || slot > length(weapon_rotation))
		return
	var/obj/item/old = get_active_held_item()
	if(istype(old, /obj/item/ego_weapon/black_silence_gloves))
		REMOVE_TRAIT(old, TRAIT_NODROP, "understudy")
		qdel(old)
	var/new_weapon_type = weapon_rotation[slot]
	var/obj/item/ego_weapon/W = new new_weapon_type(src)
	if(W.force > 0)
		var/aspeed = W.attack_speed ? W.attack_speed : 1
		W.force_multiplier = (weapon_force * min(1, aspeed)) / W.force
	MakeCostumeItem(W)
	put_in_hands(W)
	playsound(get_turf(src), 'sound/weapons/black_silence/snap.ogg', 40, TRUE, 3)

// Slots 1-9 are workshops, slot 10 is Furioso. Honed Edge applied per ability.
/mob/living/carbon/human/understudy_form/black_silence/UseSpecial(mob/living/target)
	SwapToWeapon(ability_index)
	switch(ability_index)
		if(1)
			ZelkovaSlam(target)
		if(2)
			RangaDash(target)
		if(3)
			OldBoysCounter(target)
		if(4)
			AllasLunge(target)
		if(5)
			MookCut(target)
		if(6)
			LogicShotgun(target)
		if(7)
			DurandalStrike(target)
		if(8)
			CrystalDash(target)
		if(9)
			WheelsSwing(target)
		if(10)
			Furioso(target)
	ability_index = (ability_index % 10) + 1
	if(stat != DEAD && !QDELETED(src))
		apply_lc_offense_level_up(8)

// Old Boys parry (slot 3): first hit during countering triggers DoCounter.
/mob/living/carbon/human/understudy_form/black_silence/attacked_by(obj/item/I, mob/living/user)
	if(countering && isliving(user) && user != src && !faction_check_mob(user))
		DoCounter(user, FALSE)
		return
	return ..()

/mob/living/carbon/human/understudy_form/black_silence/bullet_act(obj/projectile/P, def_zone, piercing_hit = FALSE)
	if(countering && P && isliving(P.firer) && !faction_check_mob(P.firer))
		DoCounter(P.firer, TRUE)
		return BULLET_ACT_BLOCK
	return ..()

/mob/living/carbon/human/understudy_form/black_silence/proc/DoCounter(mob/living/attacker, ranged)
	if(!countering || QDELETED(attacker))
		return
	countering = FALSE
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#222244")
	if(ranged)
		var/turf/blink = get_step(get_turf(attacker), pick(GLOB.cardinals))
		if(blink && !blink.density)
			forceMove(blink)
		playsound(get_turf(src), 'sound/weapons/fwoosh.ogg', 50, TRUE)
	face_atom(attacker)
	do_attack_animation(attacker)
	playsound(get_turf(src), 'sound/weapons/black_silence/mace.ogg', 80, TRUE, 5)
	attacker.deal_damage(40, BLACK_DAMAGE, src,
		attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	if(!attacker.anchored)
		attacker.throw_at(get_edge_target_turf(attacker, get_dir(src, attacker)), 3, 2, src)
	attacker.Knockdown(1 SECONDS)

// Zelkova - 3x3 BLACK on target's tile.
/mob/living/carbon/human/understudy_form/black_silence/proc/ZelkovaSlam(mob/living/target)
	face_atom(target)
	say("...c-clean it-")
	var/turf/T = get_turf(target)
	if(!T)
		return
	for(var/turf/W in range(1, T))
		new /obj/effect/temp_visual/understudy_warning(W)
	playsound(get_turf(src), 'sound/weapons/black_silence/mace.ogg', 75, TRUE, 4)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_FAST)
	if(QDELETED(src) || stat == DEAD)
		return
	var/list/been_hit = list()
	for(var/turf/W in range(1, T))
		new /obj/effect/temp_visual/small_smoke/halfsecond(W)
		been_hit = HurtInTurf(W, been_hit, 35, BLACK_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	for(var/mob/living/L in been_hit)
		if(L == src || faction_check_mob(L))
			continue

// Ranga - shortsword dash through target.
/mob/living/carbon/human/understudy_form/black_silence/proc/RangaDash(mob/living/target)
	say("...s-step in-")
	playsound(get_turf(src), 'sound/weapons/black_silence/shortsword.ogg', 75, TRUE, 4)
	DashStrike(target, 7, 28, UNDERSTUDY_TELEGRAPH_MEDIUM, null, BLACK_DAMAGE)

// Old Boys - 1.5 s parry stance; first hit triggers DoCounter.
/mob/living/carbon/human/understudy_form/black_silence/proc/OldBoysCounter(mob/living/target)
	if(countering)
		return
	face_atom(target)
	say("...g-guard-")
	countering = TRUE
	add_atom_colour("#222244", TEMPORARY_COLOUR_PRIORITY)
	new /obj/effect/temp_visual/understudy_warning(get_turf(src))
	Immobilize(1.5 SECONDS, TRUE)
	playsound(get_turf(src), 'sound/weapons/black_silence/guard.ogg', 60, TRUE, 4)
	SLEEP_CHECK_DEATH(15)
	if(countering)
		countering = FALSE
		remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#222244")

// Allas - 3-wide spear dash, applies Rend Black.
/mob/living/carbon/human/understudy_form/black_silence/proc/AllasLunge(mob/living/target)
	face_atom(target)
	say("...p-pierce-")
	playsound(get_turf(src), 'sound/weapons/ego/spear1.ogg', 75, TRUE, 4)
	var/list/victims = DashStrike(target, 8, 32, UNDERSTUDY_TELEGRAPH_MEDIUM, null, BLACK_DAMAGE)
	for(var/mob/living/L in victims)
		if(L == src || faction_check_mob(L))
			continue
		L.apply_status_effect(/datum/status_effect/rend_black)

// Mook - Judgment Cut on target's snapshot tile.
/mob/living/carbon/human/understudy_form/black_silence/proc/MookCut(mob/living/target)
	face_atom(target)
	say("...j-judgment-")
	var/turf/T = get_turf(target)
	if(!T)
		return
	for(var/turf/W in range(1, T))
		new /obj/effect/temp_visual/understudy_warning(W)
	playsound(get_turf(src), 'sound/weapons/black_silence/longsword_start.ogg', 70, TRUE, 5)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_FAST)
	if(QDELETED(src) || stat == DEAD)
		return
	playsound(T, 'sound/weapons/black_silence/longsword_atk.ogg', 70, TRUE)
	var/list/been_hit = list()
	for(var/turf/W in range(1, T))
		new /obj/effect/temp_visual/small_smoke/halfsecond(W)
		been_hit = HurtInTurf(W, been_hit, 40, BLACK_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))

// Logic - 3-deep, 3-wide shotgun cone; throws hit targets along the cone.
/mob/living/carbon/human/understudy_form/black_silence/proc/LogicShotgun(mob/living/target)
	face_atom(target)
	say("...s-stand back-")
	var/list/cone = list()
	var/blast_dir = dir
	var/turf/cursor = get_turf(src)
	if(!cursor)
		return
	for(var/i in 1 to 3)
		cursor = get_step(cursor, blast_dir)
		if(!cursor || cursor.density)
			break
		cone |= cursor
		for(var/turf/side in list(get_step(cursor, turn(blast_dir, 90)), get_step(cursor, turn(blast_dir, -90))))
			if(side && !side.density)
				cone |= side
	for(var/turf/W in cone)
		new /obj/effect/temp_visual/understudy_warning(W)
	playsound(get_turf(src), 'sound/weapons/black_silence/shotgun.ogg', 75, TRUE, 5)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_MEDIUM)
	if(QDELETED(src) || stat == DEAD)
		return
	var/list/been_hit = list()
	for(var/turf/W in cone)
		new /obj/effect/temp_visual/small_smoke/halfsecond(W)
		been_hit = HurtInTurf(W, been_hit, 30, BLACK_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
	for(var/mob/living/L in been_hit)
		if(L == src || faction_check_mob(L))
			continue
		if(!L.anchored)
			L.throw_at(get_edge_target_turf(L, blast_dir), 3, 2, src)

// Durandal - heavy overhead strike on target's tile.
/mob/living/carbon/human/understudy_form/black_silence/proc/DurandalStrike(mob/living/target)
	face_atom(target)
	say("...j-judge thee-")
	var/turf/T = get_turf(target)
	if(!T)
		return
	new /obj/effect/temp_visual/understudy_warning(T)
	playsound(get_turf(src), 'sound/weapons/black_silence/durandal_up.ogg', 75, TRUE, 5)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_FAST)
	if(QDELETED(src) || stat == DEAD)
		return
	new /obj/effect/temp_visual/small_smoke/halfsecond(T)
	playsound(T, 'sound/weapons/black_silence/durandal_strong.ogg', 80, TRUE, 5)
	for(var/mob/living/L in T)
		if(L == src || faction_check_mob(L))
			continue
		L.deal_damage(50, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))

// Crystal - dash through target, then short evasion-teleport.
/mob/living/carbon/human/understudy_form/black_silence/proc/CrystalDash(mob/living/target)
	face_atom(target)
	say("...g-gone-")
	playsound(get_turf(src), 'sound/weapons/black_silence/duelsword.ogg', 70, TRUE, 4)
	DashStrike(target, 7, 30, UNDERSTUDY_TELEGRAPH_MEDIUM, null, BLACK_DAMAGE)
	if(QDELETED(src) || stat == DEAD)
		return
	var/evade_dir = pick(GLOB.cardinals)
	var/turf/landing = get_turf(src)
	for(var/i in 1 to 3)
		var/turf/nxt = get_step(landing, evade_dir)
		if(!nxt || nxt.density)
			break
		landing = nxt
	if(landing && landing != get_turf(src))
		var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(get_turf(src), src)
		D.alpha = 180
		animate(D, alpha = 0, time = 6)
		forceMove(landing)
		playsound(get_turf(src), 'sound/weapons/black_silence/evasion.ogg', 50, TRUE)

// Wheels - 5x3 greatsword cone; throws hit targets along the swing.
/mob/living/carbon/human/understudy_form/black_silence/proc/WheelsSwing(mob/living/target)
	face_atom(target)
	say("...c-cleave-")
	var/list/cone = list()
	var/swing_dir = dir
	var/turf/cursor = get_turf(src)
	if(!cursor)
		return
	for(var/i in 1 to 5)
		cursor = get_step(cursor, swing_dir)
		if(!cursor || cursor.density)
			break
		cone |= cursor
		for(var/turf/side in list(get_step(cursor, turn(swing_dir, 90)), get_step(cursor, turn(swing_dir, -90))))
			if(side && !side.density)
				cone |= side
	for(var/turf/W in cone)
		new /obj/effect/temp_visual/understudy_warning(W)
	playsound(get_turf(src), 'sound/weapons/black_silence/greatsword.ogg', 80, TRUE, 6)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_MEDIUM)
	if(QDELETED(src) || stat == DEAD)
		return
	var/list/been_hit = list()
	for(var/turf/W in cone)
		new /obj/effect/temp_visual/small_smoke/halfsecond(W)
		been_hit = HurtInTurf(W, been_hit, 45, BLACK_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	for(var/mob/living/L in been_hit)
		if(L == src || faction_check_mob(L))
			continue
		if(!L.anchored)
			L.throw_at(get_edge_target_turf(L, swing_dir), 3, 2, src)

// Furioso - 1:1 recreation of the canon weapon cinematic; 1500 BLACK on the
// final Durandal hit, then self-morph.
/mob/living/carbon/human/understudy_form/black_silence/proc/Furioso(mob/living/target)
	if(QDELETED(target) || target.stat == DEAD)
		return
	var/obj/item/ego_weapon/black_silence_gloves/gloves = get_active_held_item()
	if(!istype(gloves))
		return

	visible_message(span_userdanger("[src] gathers everything into one final strike!"))
	say("...F-FURIOSO-")

	// furioso_start equivalent: godmode self + freeze target.
	status_flags |= GODMODE
	target.Stun(60 SECONDS, ignore_canstun = TRUE)
	ADD_TRAIT(target, TRAIT_MUTE, TIMESTOP_TRAIT)
	walk(target, 0)
	if(isanimal(target))
		var/mob/living/simple_animal/S = target
		S.toggle_ai(AI_OFF)
	if(ishostile(target))
		var/mob/living/simple_animal/hostile/H = target
		H.LoseTarget()
	anchored = TRUE

	var/turf/target_turf
	var/turf/T

	// Dual Revolvers
	gloves.icon_state = "logic"
	update_inv_hands()
	for(var/i in 0 to 1)
		T = get_turf(target)
		new /obj/effect/temp_visual/smash_effect(T)
		target_turf = get_step(get_turf(target), get_dir(src, target))
		if(target_turf && !target.anchored)
			target.Move(target_turf)
		playsound(src, 'sound/weapons/black_silence/revolver.ogg', 100, 1)
		SLEEP_CHECK_DEATH(3.5)

	// Spear (Allas)
	gloves.icon_state = "allas"
	update_inv_hands()
	target_turf = get_step(get_turf(target), get_dir(src, target))
	if(target_turf)
		gloves.dash(src, target_turf)
	T = get_turf(target)
	new /obj/effect/temp_visual/smash_effect(T)
	playsound(src, 'sound/weapons/black_silence/duelsword_strong.ogg', 100, 1)
	SLEEP_CHECK_DEATH(2)

	// Hammer (Old Boys)
	gloves.icon_state = "old_boys"
	update_inv_hands()
	setDir(get_dir(src, target))
	playsound(src, 'sound/weapons/black_silence/mace.ogg', 100, 1)
	target_turf = get_step(get_turf(target), get_dir(src, target))
	T = get_turf(target)
	new /obj/effect/temp_visual/smash_effect(T)
	if(target_turf && !target.anchored)
		target.Move(target_turf)
	SLEEP_CHECK_DEATH(4)

	// LongSword (Mook)
	gloves.icon_state = "mook"
	update_inv_hands()
	playsound(src, 'sound/weapons/black_silence/longsword_start.ogg', 100, 1)
	SLEEP_CHECK_DEATH(1.5)
	T = get_turf(target)
	playsound(T, 'sound/weapons/black_silence/longsword_atk.ogg', 100, 1)
	for(var/i in 0 to 2)
		new /obj/effect/temp_visual/smash_effect(T)
		SLEEP_CHECK_DEATH(1.25)

	// Gauntlets & Shortsword (Ranga)
	gloves.icon_state = "ranga"
	update_inv_hands()
	for(var/i in 0 to 2)
		setDir(get_dir(src, target))
		target_turf = get_step(get_turf(target), get_dir(src, target))
		if(target_turf)
			gloves.dash(src, target_turf)
		T = get_turf(target)
		new /obj/effect/temp_visual/smash_effect(T)
		if(i == 0)
			playsound(src, 'sound/weapons/black_silence/mace.ogg', 100, 1)
			SLEEP_CHECK_DEATH(1)
		if(i == 1)
			playsound(src, 'sound/weapons/black_silence/axe.ogg', 100, 1)
			SLEEP_CHECK_DEATH(1)
		if(i == 2)
			playsound(src, 'sound/weapons/black_silence/shortsword.ogg', 100, 1)
			SLEEP_CHECK_DEATH(3)

	// Mace & Axe (Zelkova)
	gloves.icon_state = "zelkova"
	update_inv_hands()
	setDir(get_dir(src, target))
	playsound(src, 'sound/weapons/black_silence/axe.ogg', 100, 1)
	new /obj/effect/temp_visual/smash_effect(T)
	SLEEP_CHECK_DEATH(3)
	playsound(src, 'sound/weapons/black_silence/mace.ogg', 100, 1)
	new /obj/effect/temp_visual/smash_effect(T)
	SLEEP_CHECK_DEATH(3)

	// Greatsword (Wheels)
	gloves.icon_state = "wheels"
	update_inv_hands()
	target_turf = get_step(get_turf(target), get_dir(src, target))
	playsound(src, 'sound/weapons/black_silence/greatsword.ogg', 100, 1)
	new /obj/effect/temp_visual/smash_effect(T)
	if(target_turf && !target.anchored)
		target.Move(target_turf)
	SLEEP_CHECK_DEATH(5)

	// Dual Swords (Crystal)
	gloves.icon_state = "crystal"
	update_inv_hands()
	target_turf = get_step(get_turf(target), get_dir(src, target))
	if(target_turf)
		gloves.dash(src, target_turf)
	T = get_turf(target)
	new /obj/effect/temp_visual/smash_effect(T)
	playsound(src, 'sound/weapons/black_silence/duelsword_strong.ogg', 100, 1)
	SLEEP_CHECK_DEATH(4)

	// Shotgun (Logic)
	gloves.icon_state = "logic"
	update_inv_hands()
	setDir(get_dir(src, target))
	new /obj/effect/temp_visual/smash_effect(T)
	playsound(src, 'sound/weapons/black_silence/shotgun.ogg', 100, 1)
	target_turf = get_step(get_turf(target), get_dir(src, target))
	if(target_turf)
		target_turf = get_step(target_turf, get_dir(src, target))
	if(target_turf)
		target_turf = get_step(target_turf, get_dir(src, target))
	if(target_turf && !target.anchored)
		target.Move(target_turf)
	SLEEP_CHECK_DEATH(4)

	// Durandal - the finishing sequence; 1500 BLACK lands on the third strike.
	gloves.icon_state = "durandal"
	update_inv_hands()
	target_turf = get_step(get_turf(target), get_dir(target, src))
	if(target_turf)
		gloves.dash(src, target_turf)
	playsound(src, 'sound/weapons/black_silence/durandal_down.ogg', 100, 1)
	T = get_turf(target)
	new /obj/effect/temp_visual/smash_effect(T)
	SLEEP_CHECK_DEATH(3.5)
	target_turf = get_step(get_turf(target), get_dir(src, target))
	if(target_turf)
		gloves.dash(src, target_turf)
	playsound(src, 'sound/weapons/black_silence/durandal_up.ogg', 100, 1)
	new /obj/effect/temp_visual/smash_effect(T)
	SLEEP_CHECK_DEATH(3.5)
	setDir(get_dir(src, target))
	target_turf = get_step(get_turf(target), get_dir(src, target))
	playsound(src, 'sound/weapons/black_silence/durandal_strong.ogg', 100, 1)
	T = get_turf(target)
	new /obj/effect/temp_visual/smash_effect(T)
	if(target_turf && !target.anchored)
		target.Move(target_turf)
	if(!QDELETED(target) && target.stat != DEAD && !(target.status_flags & GODMODE))
		target.deal_damage(1500, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
	SLEEP_CHECK_DEATH(10)

	// furioso_end equivalent: clear godmode/anchor, lift the target freeze.
	status_flags &= ~GODMODE
	anchored = FALSE
	if(!QDELETED(target))
		target.AdjustStun(-60 SECONDS, ignore_canstun = TRUE)
		REMOVE_TRAIT(target, TRAIT_MUTE, TIMESTOP_TRAIT)
		if(isanimal(target))
			var/mob/living/simple_animal/S = target
			S.toggle_ai(initial(S.AIStatus))
	if(!QDELETED(gloves))
		gloves.icon_state = "gloves"
		update_inv_hands()

	// Spent: force a morph (morph_after_abilities = 11 is a backstop).
	if(master && !QDELETED(master) && master.current_form == src)
		INVOKE_ASYNC(master, TYPE_PROC_REF(/mob/living/simple_animal/hostile/distortion/understudy, MorphForm))

// ---------- Skin: Blue Reverberation (Argalia) ----------
/datum/outfit/understudy_blue_reverberation
	name = "Understudy - Blue Reverberation"
	uniform = /obj/item/clothing/under/color/black
	shoes = /obj/item/clothing/shoes/sneakers/black

/mob/living/carbon/human/understudy_form/blue_reverberation
	form_outfit = /datum/outfit/understudy_blue_reverberation
	extra_worn = list(/obj/item/clothing/suit/armor/ego_gear/city/blue_reverb = ITEM_SLOT_OCLOTHING)
	weapon_type = /obj/item/ego_weapon/city/reverberation
	weapon_force = 14
	form_health = 250
	special_range = 8
	special_cooldown_time = 12 SECONDS
	persistent_form = TRUE
	force_switch_threshold = 100
	morph_after_abilities = 5
	/// Looping timer driving the Resonant Hum aura.
	var/hum_timer

/mob/living/carbon/human/understudy_form/blue_reverberation/SetupCostume()
	. = ..()
	if(QDELETED(src))
		return
	gender = FEMALE
	body_type = FEMALE
	skin_tone = "albino"
	hair_color = "D6D6D6"
	hairstyle = "Very Long with Fringe"
	eye_color = "A8BCC8"
	facial_hairstyle = "Shaved"
	fully_replace_character_name(real_name, "Argalia")
	update_body()
	update_hair()
	hum_timer = addtimer(CALLBACK(src, PROC_REF(ResonantHum)), 8 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)

/mob/living/carbon/human/understudy_form/blue_reverberation/Destroy()
	deltimer(hum_timer)
	hum_timer = null
	return ..()

// Vibration is STATUS_EFFECT_UNIQUE; apply_status_effect no-ops once it
// exists, so add_stacks to the existing effect when present.
/mob/living/carbon/human/understudy_form/blue_reverberation/proc/AddVibration(mob/living/target, amount = 1)
	if(QDELETED(target) || target.stat == DEAD)
		return
	var/datum/status_effect/stacking/vibration/V = target.has_status_effect(/datum/status_effect/stacking/vibration)
	if(V)
		V.add_stacks(amount)
	else
		target.apply_status_effect(/datum/status_effect/stacking/vibration, amount)

// Resonant Hum - 5-tile pulse adds a vibration stack to each nearby foe.
/mob/living/carbon/human/understudy_form/blue_reverberation/proc/ResonantHum()
	if(QDELETED(src) || stat == DEAD)
		return
	var/turf/center = get_turf(src)
	if(!center)
		return
	playsound(get_turf(src), 'sound/weapons/fixer/reverb_normal.ogg', 35, TRUE, 3)
	for(var/turf/T in range(5, center))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
	for(var/mob/living/L in livinginrange(5, src))
		if(L == src || faction_check_mob(L) || L.stat == DEAD)
			continue
		AddVibration(L)

/mob/living/carbon/human/understudy_form/blue_reverberation/UseSpecial(mob/living/target)
	switch(ability_index)
		if(1)
			ResonantWave(target)
		if(2)
			TempestuousDanza(target)
		if(3)
			GrandFinale(target)
	ability_index = (ability_index % 3) + 1

// Resonant Wave - three concentric rings: 3x3 WHITE, 5x5 WHITE, 7x7 PALE+Sinking.
/mob/living/carbon/human/understudy_form/blue_reverberation/proc/ResonantWave(mob/living/target)
	face_atom(target)
	say("...l-listen... to the rhythm-")
	// Root the form across all three Fast rings.
	Immobilize(UNDERSTUDY_TELEGRAPH_FAST * 3, TRUE)
	var/turf/center = get_turf(src)
	if(!center)
		return
	for(var/turf/T in range(1, center))
		new /obj/effect/temp_visual/understudy_warning(T)
	playsound(get_turf(src), 'sound/weapons/fixer/reverb_normal.ogg', 70, TRUE, 5)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_FAST)
	if(QDELETED(src) || stat == DEAD)
		return
	var/list/hit1 = list()
	for(var/turf/T in range(1, center))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		hit1 = HurtInTurf(T, hit1, 22, WHITE_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	for(var/turf/T in range(2, center))
		new /obj/effect/temp_visual/understudy_warning(T)
	playsound(get_turf(src), 'sound/weapons/fixer/reverb_normal.ogg', 70, TRUE, 5)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_FAST)
	if(QDELETED(src) || stat == DEAD)
		return
	var/list/hit2 = list()
	for(var/turf/T in range(2, center))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		hit2 = HurtInTurf(T, hit2, 22, WHITE_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	for(var/turf/T in range(3, center))
		new /obj/effect/temp_visual/understudy_warning(T)
	playsound(get_turf(src), 'sound/weapons/fixer/reverb_strong1.ogg', 80, TRUE, 5)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_FAST)
	if(QDELETED(src) || stat == DEAD)
		return
	var/list/hit3 = list()
	for(var/turf/T in range(3, center))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		hit3 = HurtInTurf(T, hit3, 26, PALE_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		for(var/mob/living/L in T)
			if(L == src || faction_check_mob(L))
				continue
			L.apply_lc_sinking(3)

// Tempestuous Danza - teleport-strike every enemy in range 8 once, +vibration.
/mob/living/carbon/human/understudy_form/blue_reverberation/proc/TempestuousDanza(mob/living/target)
	say("...w-we'll shape this... t-together-")
	new /obj/effect/temp_visual/understudy_warning(get_turf(src))
	playsound(get_turf(src), 'sound/weapons/fixer/reverb_normal.ogg', 70, TRUE, 5)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_MEDIUM)
	if(QDELETED(src) || stat == DEAD)
		return
	var/list/danza_targets = list()
	for(var/mob/living/L in livinginrange(8, src))
		if(L == src || faction_check_mob(L) || L.stat == DEAD)
			continue
		danza_targets += L
	if(!length(danza_targets))
		return
	for(var/mob/living/L in danza_targets)
		if(QDELETED(L) || L.stat == DEAD || QDELETED(src) || stat == DEAD)
			continue
		var/turf/dest = null
		for(var/turf/T in shuffle(range(1, get_turf(L))))
			if(T == get_turf(L) || T.density)
				continue
			dest = T
			break
		if(!dest)
			continue
		var/turf/prev = get_turf(src)
		forceMove(dest)
		face_atom(L)
		prev.Beam(dest, "sm_arc_supercharged", time=8)
		new /obj/effect/temp_visual/reverb_slash/right(get_turf(src))
		playsound(get_turf(src), 'sound/weapons/fixer/reverb_normal.ogg', 55, TRUE)
		L.deal_damage(24, WHITE_DAMAGE, src,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		AddVibration(L)
		SLEEP_CHECK_DEATH(3)

// Grand Finale - marking dash pass, then heavy PALE burst per mark; vibration
// >= 3 takes ~1.5x.
/mob/living/carbon/human/understudy_form/blue_reverberation/proc/GrandFinale(mob/living/target)
	say("...t-the f-finale...")
	Immobilize(UNDERSTUDY_TELEGRAPH_SLOW, TRUE)
	playsound(get_turf(src), 'sound/weapons/fixer/reverb_grand_start.ogg', 80, TRUE, 8)
	new /obj/effect/temp_visual/understudy_warning(get_turf(src))
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_SLOW)
	if(QDELETED(src) || stat == DEAD)
		return
	var/turf/original = get_turf(src)
	var/list/marked = list()
	for(var/mob/living/L in livinginrange(10, src))
		if(L == src || faction_check_mob(L) || L.stat == DEAD)
			continue
		marked += L
	if(!length(marked))
		return
	for(var/mob/living/L in marked)
		if(QDELETED(L) || L.stat == DEAD || QDELETED(src) || stat == DEAD)
			continue
		var/turf/dest = null
		for(var/turf/T in shuffle(range(1, get_turf(L))))
			if(T == get_turf(L) || T.density)
				continue
			dest = T
			break
		if(!dest)
			continue
		var/turf/prev = get_turf(src)
		forceMove(dest)
		face_atom(L)
		prev.Beam(dest, "sm_arc_supercharged", time=6)
		new /obj/effect/temp_visual/remorse(get_turf(L))
		playsound(get_turf(src), 'sound/weapons/fixer/reverb_grand_dash.ogg', 50, TRUE)
		SLEEP_CHECK_DEATH(2)
	if(QDELETED(src) || stat == DEAD)
		return
	if(original)
		forceMove(original)
	SLEEP_CHECK_DEATH(UNDERSTUDY_TELEGRAPH_FAST)
	if(QDELETED(src) || stat == DEAD)
		return
	playsound(get_turf(src), 'sound/weapons/fixer/reverb_grand_end.ogg', 80, TRUE, 8)
	for(var/mob/living/L in marked)
		if(QDELETED(L) || L.stat == DEAD)
			continue
		var/datum/status_effect/stacking/vibration/V = L.has_status_effect(/datum/status_effect/stacking/vibration)
		var/damage = 60
		if(V && V.stacks >= 3)
			damage = 90
		new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(L))
		L.deal_damage(damage, PALE_DAMAGE, src,
			attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
