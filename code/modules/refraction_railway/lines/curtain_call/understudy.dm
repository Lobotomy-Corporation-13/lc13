/*
 * Curtain Call - zeal_s2n1: The Understudy.
 * A variant of The Envy of Humanity. It has no self of its own — it fights
 * by wearing premade, AI-controlled human "skins" cut from city roles. Break
 * a skin and the true form is dragged out into the open: stunned, chipped for
 * a chunk of HP, and a little more fragile than before. A few seconds later
 * it pulls on another face. When the true form finally falls, the act ends.
 *
 * Architecture: only the TRUE FORM is registered with the wave controller, so
 * killing a skin never clears the node — only the true form's death does.
 * Skins are code-spawned carbon humans the true form hides inside (à la
 * Envy's AssumeForm/RevertForm); they're never wave-registered.
 *
 * Each skin carries its role's gear (EGO requirements stripped so the AI can
 * use it, and TRAIT_NODROP so players can't disarm it), is stun/push/sleep
 * immune, has ~200 HP from Fortitude, hits at simple-mob strength, moves
 * slowed, runs a locked-weapon murder AI, and has one telegraphed, dodgeable
 * signature attack.
 */

// ---------- Telegraph ----------

/obj/effect/temp_visual/understudy_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#b026ff"
	duration = 8

// ---------- Movement slow for skins ----------

/datum/movespeed_modifier/understudy_form
	multiplicative_slowdown = 1.5

// ---------- Custom murder AI: keeps its costume weapon ----------
// Same target/approach/attack behaviour as the base insane murderer, but it
// never scavenges or swaps weapons — it fights with the face it was given.
/datum/ai_controller/insane/murder/understudy

/datum/ai_controller/insane/murder/understudy/TryFindWeapon(is_white_allowed = TRUE)
	return null

// ---------- True form ----------
// Display name is "The Envy of Humanity"; the `understudy` type path is kept
// as the internal identifier (distinct from the base distortion Envy).
/mob/living/simple_animal/hostile/understudy
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
	)
	var/last_form
	var/mob/living/carbon/human/understudy_form/current_form
	var/dying = FALSE
	var/death_fade_time = 1 SECONDS

	// The true form's own voice: eldritch, adoring, self-loathing. It cannot
	// bear to be seen as the thing under the borrowed faces.
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

/mob/living/simple_animal/hostile/understudy/refracted

/mob/living/simple_animal/hostile/understudy/Initialize(mapload)
	. = ..()
	// A short beat as the true form, then it pulls on its first face.
	addtimer(CALLBACK(src, PROC_REF(AssumeForm)), 1 SECONDS)

// can_act gates the AI without ever deregistering it: while wearing a skin or
// freshly revealed (can_act = FALSE) the true form searches, moves, and swings
// for nothing - the controller keeps ticking, it just does nothing.
/mob/living/simple_animal/hostile/understudy/handle_automated_action()
	if(!can_act)
		return
	return ..()

/mob/living/simple_animal/hostile/understudy/Move(atom/newloc, dir, step_x, step_y)
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/understudy/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return
	return ..()

// Pull on a fresh random skin and hide inside it.
/mob/living/simple_animal/hostile/understudy/proc/AssumeForm(carry_health = 0, turf/at_turf = null)
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
	skin.carry_health = carry_health
	current_form = skin
	RegisterSignal(skin, COMSIG_LIVING_DEATH, PROC_REF(OnFormDeath))
	// Go fully inert and unseeable while the skin fights: invisible (so nothing
	// can target or hit it), intangible, invulnerable, AI off. It stays on this
	// tile - RevealTrueForm repositions it to wherever the skin breaks.
	status_flags |= GODMODE
	density = FALSE
	alpha = 0
	invisibility = INVISIBILITY_MAXIMUM
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	can_act = FALSE
	LoseTarget()
	walk(src, 0)
	visible_message(span_warning("[skin] steps onto the stage."))
	// The skin speaks in a warped echo of the role it is mimicking.
	if(LAZYLEN(skin.assume_lines))
		skin.say(pick(skin.assume_lines))

// Shift to a different form mid-fight WITHOUT revealing the true form, carrying
// the skin's current HP across. Fired after each ability and when a form has
// soaked enough damage. The true form stays hidden the whole time.
/mob/living/simple_animal/hostile/understudy/proc/MorphForm()
	if(dying || stat == DEAD || QDELETED(src) || !current_form || QDELETED(current_form))
		return
	var/carry = current_form.health
	var/turf/T = get_turf(current_form)
	UnregisterSignal(current_form, COMSIG_LIVING_DEATH)
	qdel(current_form)
	current_form = null
	AssumeForm(carry, T)

// A skin was broken — drag the true form out for a punish window.
/mob/living/simple_animal/hostile/understudy/proc/OnFormDeath(mob/living/source)
	SIGNAL_HANDLER
	if(source != current_form)
		return
	UnregisterSignal(source, COMSIG_LIVING_DEATH)
	INVOKE_ASYNC(src, PROC_REF(RevealTrueForm), get_turf(source))

/mob/living/simple_animal/hostile/understudy/proc/RevealTrueForm(turf/exit_turf)
	if(dying || QDELETED(src))
		return
	if(!exit_turf)
		exit_turf = get_turf(current_form) || get_turf(src)
	// Burst the broken skin (Envy's revert flourish).
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
	// More fragile each time it's dragged into the light.
	reveals_done++
	damage_coeff = resist_tiers[clamp(reveals_done, 1, length(resist_tiers))]
	// Chip damage from losing the skin.
	adjustHealth(reveal_damage)
	if(stat == DEAD || health <= 0)
		if(stat != DEAD)
			death()
		return
	// Stunned and exposed; players punish the true form directly.
	can_act = FALSE
	Stun(reveal_stun_time)
	addtimer(CALLBACK(src, PROC_REF(AssumeForm)), reform_delay)

/mob/living/simple_animal/hostile/understudy/death(gibbed)
	if(dying)
		return ..()
	dying = TRUE
	if(current_form && !QDELETED(current_form))
		UnregisterSignal(current_form, COMSIG_LIVING_DEATH)
		qdel(current_form)
		current_form = null
	// Make sure we're back in the world to play the death out.
	if(!isturf(loc))
		forceMove(get_turf(src))
	status_flags &= ~GODMODE
	density = TRUE
	alpha = 255
	invisibility = initial(invisibility)
	say(pick(death_lines))
	. = ..()
	animate(src, alpha = 0, time = death_fade_time)
	QDEL_IN(src, death_fade_time)

// ---------- Skin base ----------
/mob/living/carbon/human/understudy_form
	/// The true form hiding inside us.
	var/mob/living/simple_animal/hostile/understudy/master
	/// The role's signature melee weapon, placed in-hand for the AI.
	var/weapon_type
	/// Target effective basic-melee damage per hit; enforced via the weapon's
	/// force_multiplier so it holds even when the weapon resets its own force.
	var/weapon_force = 22
	/// Effective max HP, reached by buffing Fortitude.
	var/form_health = 200
	/// HP carried over from the previous form on a morph (0 = spawn at full).
	var/carry_health = 0
	/// Damage soaked since this form was donned; at force_switch_threshold the
	/// Envy force-switches forms (unless mid-ability).
	var/damage_taken_this_form = 0
	var/force_switch_threshold = 75
	/// TRUE while a special is resolving - blocks the damage force-switch.
	var/in_special = FALSE
	/// Telegraphed signature attack.
	var/special_cooldown = 0
	var/special_cooldown_time = 8 SECONDS
	var/special_range = 7
	var/special_timer
	/// Outfit equipped for the look.
	var/form_outfit
	/// Warped mimicry of the role, spoken when the Envy first dons this skin.
	var/list/assume_lines
	/// Extra worn items forced on after the outfit (item path = slot define;
	/// path-keyed so list lookup isn't mistaken for a numeric index), for EGO
	/// armor and cosmetics the job outfit lacks or strips from a non-player.
	var/list/extra_worn

/mob/living/carbon/human/understudy_form/Initialize(mapload)
	. = ..()
	faction = list("serio_zeal")
	// The equip chain can sleep (do_after inside mob_can_equip), which
	// Initialize must not - so defer the whole costume/weapon/AI setup.
	INVOKE_ASYNC(src, PROC_REF(SetupCostume))

// Dresses the skin, locks its gear, buffs it to ~200 HP, and starts its AI.
// Deferred from Initialize because the equip chain can sleep.
/mob/living/carbon/human/understudy_form/proc/SetupCostume()
	if(QDELETED(src))
		return
	// (carbon humans leave a corpse on death; the true form bursts + qdels
	// the skin in OnFormDeath, so no del_on_death needed.)
	if(form_outfit)
		equipOutfit(form_outfit)
	// Force on extra worn gear the outfit doesn't (EGO armor, cosmetics it
	// strips from non-players). MakeCostumeItem first zeroes EGO requirements
	// so the armor actually stays equipped, then we put it in its slot.
	for(var/worn_path in extra_worn)
		var/obj/item/X = new worn_path(src)
		MakeCostumeItem(X)
		equip_to_slot_or_del(X, extra_worn[worn_path])
	// Sticky, requirement-free gear so the AI can always use it and players
	// can't disarm it.
	for(var/obj/item/I in get_equipped_items(TRUE))
		MakeCostumeItem(I)
	// Signature weapon, in hand for the murder AI to swing. Some EGO weapons
	// reset force to their real (high) value on attack, ignoring any force we
	// set - so cap the *effective* hit with force_multiplier (applied to every
	// swing and never reset), landing basic melee around weapon_force.
	if(weapon_type)
		var/obj/item/W = new weapon_type(src)
		if(istype(W, /obj/item/ego_weapon))
			var/obj/item/ego_weapon/E = W
			if(E.force > 0)
				// A fast weapon (attack_speed < 1) swings more often, so cut its
				// per-hit by the same factor to keep DPS at ~weapon_force;
				// normal/slow weapons keep the full per-hit.
				var/aspeed = E.attack_speed ? E.attack_speed : 1
				E.force_multiplier = (weapon_force * min(1, aspeed)) / E.force
		else
			W.force = weapon_force
		MakeCostumeItem(W)
		put_in_hands(W)
	// Boss stability + the requested damage-type conversions.
	ADD_TRAIT(src, TRAIT_SANITYIMMUNE, "understudy")
	ADD_TRAIT(src, TRAIT_BRUTEPALE, "understudy")
	ADD_TRAIT(src, TRAIT_BRUTESANITY, "understudy")
	ADD_TRAIT(src, TRAIT_PUSHIMMUNE, "understudy")
	ADD_TRAIT(src, TRAIT_SLEEPIMMUNE, "understudy")
	ADD_TRAIT(src, TRAIT_STUNIMMUNE, "understudy")
	ADD_TRAIT(src, TRAIT_IGNOREDAMAGESLOWDOWN, "understudy")
	add_movespeed_modifier(/datum/movespeed_modifier/understudy_form)
	// ~200 HP via Fortitude (human maxHealth derives from it).
	updatehealth()
	var/datum/attribute/F = attributes?[FORTITUDE_ATTRIBUTE]
	if(F)
		var/needed = form_health - maxHealth
		if(needed != 0)
			F.adjust_buff(src, needed)
	updatehealth()
	// Carry HP across a morph; otherwise spawn at full.
	health = carry_health > 0 ? min(carry_health, maxHealth) : maxHealth
	// Force-switch when this form soaks too much punishment.
	RegisterSignal(src, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(OnDamageTaken))
	// Strip all Justice so the skin swings and moves at a crawl.
	var/datum/attribute/J = attributes?[JUSTICE_ATTRIBUTE]
	if(J)
		J.adjust_buff(src, -get_attribute_level(src, JUSTICE_ATTRIBUTE))
	// Locked-weapon murderer.
	ai_controller = /datum/ai_controller/insane/murder/understudy
	InitializeAIController()
	special_timer = addtimer(CALLBACK(src, PROC_REF(SpecialTick)), 1 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)

/mob/living/carbon/human/understudy_form/Destroy()
	deltimer(special_timer)
	special_timer = null
	master = null
	return ..()

// Strip EGO attribute requirements (so the AI's stats never matter) and make
// the item un-droppable / un-disarmable.
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

// Runs the form's special, then morphs to a different form (carrying HP) if it
// survived and is still the active skin. in_special blocks the damage switch.
/mob/living/carbon/human/understudy_form/proc/DoSpecial(mob/living/target)
	in_special = TRUE
	UseSpecial(target)
	in_special = FALSE
	if(stat == DEAD || QDELETED(src))
		return
	if(master && !QDELETED(master) && master.current_form == src)
		master.MorphForm()

// Tracks punishment soaked; once over the threshold (and not mid-ability) the
// Envy force-switches to a fresh form, carrying the current HP.
/mob/living/carbon/human/understudy_form/proc/OnDamageTaken(datum/source, damage_amount)
	SIGNAL_HANDLER
	if(in_special || stat == DEAD || QDELETED(src) || damage_amount <= 0)
		return
	// A killing blow should reveal the true form, not morph.
	if(health <= 0)
		return
	damage_taken_this_form += damage_amount
	if(damage_taken_this_form < force_switch_threshold)
		return
	if(master && !QDELETED(master) && master.current_form == src)
		INVOKE_ASYNC(master, TYPE_PROC_REF(/mob/living/simple_animal/hostile/understudy, MorphForm))

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

// ---------- Skin: Blade Lineage Ronin - charged strike ----------
// Copies the bladelineage katana: a "Yield my flesh" wind-up (rooted), then a
// lunge whose force scales with missing HP (x(3 - 2*hp/maxhp)).
/mob/living/carbon/human/understudy_form/ronin
	form_outfit = /datum/outfit/job/ronin
	extra_worn = list(/obj/item/clothing/suit/armor/ego_gear/city/blade_lineage_salsu = ITEM_SLOT_OCLOTHING)
	weapon_type = /obj/item/ego_weapon/city/bladelineage
	weapon_force = 27
	special_cooldown_time = 9 SECONDS
	assume_lines = list(
		"the b-b-blade... only honest th-thing... c-cut me, cut, t-teach me to be t-true like y-you -",
		"to d-draw a sword is to BE someone, some-ONE... I'd die a r-real death, a HUman death, j-just to -",
	)

/mob/living/carbon/human/understudy_form/ronin/UseSpecial(mob/living/target)
	face_atom(target)
	say("Y-yield... your flesh-")
	Immobilize(1.2 SECONDS, TRUE)
	// Sheds a spare Blade Lineage robe as it sets its stance.
	new /obj/item/clothing/suit/armor/ego_gear/city/blade_lineage_salsu(get_turf(src))
	var/turf/start = get_turf(src)
	var/turf/dest = get_turf(target)
	if(!start || !dest)
		return
	var/list/line = getline(start, dest)
	if(length(line) > 5)
		line.Cut(6)
	playsound(get_turf(src), 'sound/weapons/sear.ogg', 70, TRUE, 5)
	var/ratio = clamp(health / maxHealth, 0, 1)
	var/scaled = round(26 * (3 - 2 * ratio))
	StrikeTurfs(line, 8, scaled)
	var/turf/landing = line[length(line)]
	if(landing && !landing.density)
		forceMove(landing)

// ---------- Skin: Backstreets Butcher — Meat Hook ----------
/mob/living/carbon/human/understudy_form/butcher
	form_outfit = /datum/outfit/job/butcher
	weapon_type = /obj/item/ego_weapon/city/district23/pierre
	weapon_force = 27
	special_cooldown_time = 10 SECONDS
	assume_lines = list(
		"fresh - f-fresh meat... you're all such b-beautiful meat and I am not, not even TH-THAT -",
		"h-hold still, hold ST-STILL... I only - only want the p-part of you that gets to be a p-p-person -",
	)

/mob/living/carbon/human/understudy_form/butcher/UseSpecial(mob/living/target)
	face_atom(target)
	say("C-come... be my m-meat-")
	var/turf/start = get_turf(src)
	var/turf/dest = get_turf(target)
	if(!start || !dest)
		return
	var/list/line = getline(start, dest)
	if(length(line) > 7)
		line.Cut(8)
	for(var/turf/T in line)
		new /obj/effect/temp_visual/understudy_warning(T)
	playsound(get_turf(src), 'sound/weapons/chainhit.ogg', 70, TRUE, 5)
	SLEEP_CHECK_DEATH(7)
	// Pull the first living victim on the line in, then bite it.
	for(var/turf/T in line)
		if(T == start)
			continue
		var/mob/living/victim
		for(var/mob/living/L in T)
			if(L == src || faction_check_mob(L))
				continue
			victim = L
			break
		if(victim)
			victim.throw_at(start, 7, 2, src)
			victim.deal_damage(28, RED_DAMAGE, src,
				attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(victim))
			break

// ---------- Skin: Rat Scavenger — Junk Lob ----------
/mob/living/carbon/human/understudy_form/scavenger
	form_outfit = /datum/outfit/job/scavenger
	weapon_type = /obj/item/ego_weapon/city/rats
	weapon_force = 27
	special_cooldown_time = 7 SECONDS
	assume_lines = list(
		"scraps, sc-scraps... a p-person can be built from scraps, c-can't it? please, p-please let it be b-built -",
		"you th-throw away so much of being... of being HUman... let me have it, the l-leftovers, ANY - any of it -",
	)

/mob/living/carbon/human/understudy_form/scavenger/UseSpecial(mob/living/target)
	say("Scraps... for s-scraps-")
	var/turf/center = get_turf(target)
	if(!center)
		return
	playsound(get_turf(src), 'sound/items/dodgeball.ogg', 60, TRUE, 4)
	StrikeTurfs(range(1, center), 8, 24)

// ---------- Skin: Kurokumo Captain - Poise crit ----------
// The kurokumo blade builds Poise on its own swings; this special is the
// payoff: a telegraphed guaranteed 3x crit in a short arc.
/mob/living/carbon/human/understudy_form/captain
	form_outfit = /datum/outfit/job/kurocaptain
	extra_worn = list(/obj/item/clothing/suit/armor/ego_gear/city/kurokumo = ITEM_SLOT_OCLOTHING)
	weapon_type = /obj/item/ego_weapon/city/kurokumo
	// Kurokumo self-crits for 3x, so target ~10 to keep even crits near 30.
	weapon_force = 10
	special_cooldown_time = 9 SECONDS
	assume_lines = list(
		"p-poise... com-composure... is THIS how a - how a person h-holds itself? I p-practiced, watch, w-watch me -",
		"I st-studied your stillness so l-long... tell me it looks h-human, tell me, t-tell me it d-does -",
	)

/mob/living/carbon/human/understudy_form/captain/UseSpecial(mob/living/target)
	face_atom(target)
	say("C-critical... watch m-me-")
	Immobilize(1 SECONDS, TRUE)
	var/turf/ahead = get_step(src, dir)
	var/turf/far = ahead ? get_step(ahead, dir) : null
	var/list/arc = list()
	if(ahead)
		arc += range(1, ahead)
	if(far)
		arc |= range(1, far)
	visible_message(span_danger("[src] coils for a critical stroke!"))
	playsound(get_turf(src), 'sound/weapons/bladeslice.ogg', 75, TRUE, 5)
	StrikeTurfs(arc, 8, 72)

// ---------- Skin: Middle Big Brother - Counter ----------
// Copies the middle chain: a guard stance that ripostes the first hit it
// takes (blinking to a shooter first), then throws the attacker clear.
/mob/living/carbon/human/understudy_form/big_brother
	form_outfit = /datum/outfit/job/big_brother
	// The job outfit lists the sunglasses but strips them from non-players, and
	// the cape lives on the Middle EGO armor - force both on for the look.
	extra_worn = list(
		/obj/item/clothing/suit/armor/ego_gear/city/middle_big = ITEM_SLOT_OCLOTHING,
		/obj/item/clothing/neck/ego_neck/middle_cape = ITEM_SLOT_NECK,
		/obj/item/clothing/glasses/middle_sunglasses = ITEM_SLOT_EYES,
	)
	weapon_type = /obj/item/ego_weapon/shield/middle_chain/big
	weapon_force = 27
	special_range = 9
	special_cooldown_time = 11 SECONDS
	assume_lines = list(
		"f-family... fa-FAMily... if I l-love you enough, will you - will you let me be one of the -",
		"I'll p-protect you, I'll PROVIDE, just - just call me b-brother, call me a-anything human -",
	)
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

// While guarding, the first melee hit is blocked and countered.
/mob/living/carbon/human/understudy_form/big_brother/attacked_by(obj/item/I, mob/living/user)
	if(countering && isliving(user) && user != src && !faction_check_mob(user))
		DoCounter(user, FALSE)
		return
	return ..()

// While guarding, a bullet is blocked and the chain reels in the shooter.
/mob/living/carbon/human/understudy_form/big_brother/bullet_act(obj/projectile/P, def_zone, piercing_hit = FALSE)
	if(countering && P && isliving(P.firer) && !faction_check_mob(P.firer))
		DoCounter(P.firer, TRUE)
		return BULLET_ACT_BLOCK
	return ..()

// ---------- Skin: N Corp Grosshammer - Mark & Detonate ----------
// Copies the nail+hammer: marks several targets, then detonates every mark
// at once. Marks snapshot tiles, so stepping off dodges.
/mob/living/carbon/human/understudy_form/grosshammer
	form_outfit = /datum/outfit/job/grosshammer
	extra_worn = list(
		/obj/item/clothing/suit/armor/ego_gear/city/grosshammmer = ITEM_SLOT_OCLOTHING,
		/obj/item/clothing/head/ego_hat/helmet/ncorp/grosshammer = ITEM_SLOT_HEAD,
	)
	weapon_type = /obj/item/ego_weapon/city/ncorp_hammer/big
	weapon_force = 28
	special_range = 8
	special_cooldown_time = 11 SECONDS
	assume_lines = list(
		"flesh is h-holy and I am n-not... not flesh... let me hammer the wr-wrongness OUT and be cl-clean like you -",
		"impure, im-pure... I am the m-most impure thing h-here... p-purge me, purge me into a p-person -",
	)

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
	for(var/turf/T in marks)
		new /obj/effect/temp_visual/understudy_warning(T)
	playsound(get_turf(src), 'sound/weapons/fixer/generic/nail2.ogg', 70, TRUE, 5)
	SLEEP_CHECK_DEATH(9)
	var/list/been_hit = list()
	for(var/turf/T in marks)
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		been_hit = HurtInTurf(T, been_hit, 32, BLACK_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	playsound(get_turf(src), 'sound/weapons/genhit3.ogg', 80, TRUE, 6)

// ---------- Skin: Index Messenger - Prescript / Execute ----------
// Copies the index greatsword: marks a tile then a heavy slam, with bonus
// damage if the marked victim is already below half HP.
/mob/living/carbon/human/understudy_form/messenger
	form_outfit = /datum/outfit/job/messenger
	extra_worn = list(/obj/item/clothing/suit/armor/ego_gear/city/index_mess = ITEM_SLOT_OCLOTHING)
	weapon_type = /obj/item/ego_weapon/city/index/yan
	weapon_force = 30
	special_range = 7
	special_cooldown_time = 10 SECONDS
	assume_lines = list(
		"a p-prescript... I'll w-write myself a self... follow the l-lines, follow, b-become the part -",
		"tell me the o-orders, tell me how to - how to BE... I'll obey my w-way into being h-human -",
	)

/mob/living/carbon/human/understudy_form/messenger/UseSpecial(mob/living/target)
	face_atom(target)
	say("Your p-prescript... is DEATH-")
	Immobilize(1.2 SECONDS, TRUE)
	var/turf/mark = get_turf(target)
	if(!mark)
		return
	for(var/turf/T in range(1, mark))
		new /obj/effect/temp_visual/understudy_warning(T)
	playsound(get_turf(src), 'sound/weapons/sear.ogg', 70, TRUE, 5)
	SLEEP_CHECK_DEATH(9)
	for(var/turf/T in range(1, mark))
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

// ---------- Skin: Dieci - Grand Finale ----------
// Copies the dieci finisher: a PALE shockwave around itself that throws
// players out and stacks Sinking.
/mob/living/carbon/human/understudy_form/dieci
	form_outfit = /datum/outfit/understudy_dieci
	extra_worn = list(/obj/item/clothing/suit/armor/ego_gear/city/dieci = ITEM_SLOT_OCLOTHING)
	weapon_type = /obj/item/ego_weapon/city/dieci/understudy
	weapon_force = 27
	special_range = 5
	special_cooldown_time = 9 SECONDS
	assume_lines = list(
		"kn-knowledge... if I l-learn enough of you... I'll KNOW how to b-be you, won't I? w-won't I?",
		"I r-read every page of every l-life you lived... and st-still I cannot... cannot b-become the r-reader -",
	)

/mob/living/carbon/human/understudy_form/dieci/UseSpecial(mob/living/target)
	say("The g-grand... finale-")
	for(var/turf/T in range(2, src))
		new /obj/effect/temp_visual/understudy_warning(T)
	playsound(get_turf(src), 'sound/weapons/sear.ogg', 70, TRUE, 6)
	SLEEP_CHECK_DEATH(8)
	var/turf/center = get_turf(src)
	if(!center)
		return
	var/list/been_hit = list()
	var/list/victims = list()
	for(var/turf/T in range(2, center))
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

// Dieci has no job outfit; dress the skin in the association robe.
/datum/outfit/understudy_dieci
	name = "Understudy - Dieci"
	uniform = /obj/item/clothing/under/color/black
