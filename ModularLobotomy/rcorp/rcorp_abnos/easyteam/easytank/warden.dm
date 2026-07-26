#define STATUS_EFFECT_SOULDRAIN /datum/status_effect/rca_souldrain
//A tank because of projectile immunity and healing
/mob/living/simple_animal/hostile/rcorp_abno/easy/warden
	name = "The Warden"
	desc = "An abnormality that takes the form of a fleshy stick wearing a dress and eyes. You don't want to know what's under that dress. You have a feeling you shouldn't let it drag anyone under it."
	maxHealth = 2500
	health = 2500
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.4, PALE_DAMAGE = 1.5)
	move_to_delay = 4
	melee_damage_lower = 70
	melee_damage_upper = 70
	melee_damage_type = BLACK_DAMAGE
	del_on_death = FALSE
	move_force = 3000 // To crush the lil' humans
	stat_attack = DEAD //Yumyum corpses
	original_abno = /mob/living/simple_animal/hostile/abnormality/warden

	var/normal_sprite = "warden"
	var/finisher_sprite = "warden_attack"
	var/statcheck_fail = FALSE
	var/finishing = FALSE
	var/locked_in = FALSE
	var/mob/living/hooligan
	// If an employee has less than this % of HP left, Warden will kidnap them.
	var/KidnapThreshold = 0.35
	// By default extremely high, you are supposed to be freed by other employees.
	var/KidnapStuntime = 999
	var/contained_people
	var/captured_souls
	var/indoctrinated_morons = list()
	// This is the flat amount of max sanity decrease that kidnapped people get every 6 seconds.
	var/soul_consume_rate = 50

	// Resistance modifiers when Warden is eating/has fully eaten someone's soul.
	// How much does Warden's resistances degrade while digesting someone.
	var/digestion_modifier = 0.2
	// How much does Warden's resistances increase after fully eating someone.
	var/consumed_soul_modifier = 0.1
	// Maximum resistance level that Warden can get by eating people. (if 0.1 then Warden can be 0.1/0.1/0.1/0.1 at maximum)
	var/resistance_cap = 0.2
	// This is the % of max HP that Warden heals after fully consuming someone.
	var/consumed_soul_heal = 0.2

	var/lower_damage_cap = 20
	var/upper_damage_cap = 30
	// Temporary damage down (by default, only affects lower_damage) while digesting someone's soul.
	var/damage_down = 15
	// PERMANENT damage up (lower and upper) when Warden contains a low-risk abnormality.
	var/damage_up = 5
	// PERMANENT damage down (by default, only affects lower_damage) after fully eating someone.
	var/damage_degradation = 10
	// Keeps track of damage received after consuming someone
	var/release_damage
	// Amount of damage required for Warden to surrender the goodies (Kidnapped people)
	var/jailbreak_threshold = 525
	var/overfilled_threshold = 3
	var/overfilled = FALSE // Funny.
	var/agony = FALSE
	var/soul_names = list() // Funny 2.
	var/lastcreepysound
	// Controls both the creepy sound and the soulless agitation cooldown.
	var/creepysoundcooldown = 20 SECONDS
	var/combatmap = TRUE

	abno_additional_instructions = "<h1>You are Warden, A Tank Role Abnormality.</h1><br>\
		<b>|Soul Guard|: You are immune to all projectiles.<br>\
		<br>\
		|Soul Search|: You can see the vitality of others, optimal for picking targets. <br>\
		<br>\
		|Soul Warden|: If you attack a living human with less than 35% HP (or currently insane), you will kidnap them and begin to devour their soul.<br>\
		While devouring someone's soul, you will be slower, weaker and more frail than usual. <br>\
		If you successfully devour a soul you will heal 20% of your HP and you will spawn a subordinate mob. <br>\
		For each soul consumed, you will become faster and more resilient, but your damage will decrease by 10. <br>\
		If you receive 525 pre-reduction damage while in the process of devouring a soul, you will get stunned and puke every single human currently inside of you. <br>\
		Attack a human corpse to consume whatever scraps of their soul remain, healing you for 10% of your maximum HP <br>\
		<br>\
		|Wake-up Call|: Every lifetick there is a 1% chance multiplied by every soul you have captured * 2 to agitate all Soulless Husks. \
		Upon agitating Husks their upper damage will raise by 5, this is indicated by their screaming. \
		This damage increase may be applied repeatedly for each time |Wake-up Call| is triggered.</b>"

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/Initialize()
	. = ..()
	var/datum/atom_hud/medsensor = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED] // Placeholder.
	medsensor.add_hud_to(src) // My crazy idea would be giving it a HUD that puts special effects around vulnerable mobs, but for now this will do.

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/Destroy()
	QDEL_NULL(soul_names) // It WOULD be fun if Warden saved all soul names that it has consumed but I cannot be assed to figure that out.
	for(var/mob/living/carbon/human/L in GLOB.player_list) // Cleanse debuffs
		if(faction_check_mob(L, FALSE) || L.stat == DEAD) // Dead? Fuck them
			continue
		var/datum/status_effect/S = L.has_status_effect(/datum/status_effect/rca_souldrain)
		if(S)
			qdel(S)
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/death(gibbed)
	density = FALSE
	for(var/mob/living/L in indoctrinated_morons)
		indoctrinated_morons -= L
		L.dust()
	Jailbreak()
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/CanAttack(atom/the_target)
	if(finishing)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/Move()
	if(finishing)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/MobBump(mob/M)
	. = ..()
	if(ishuman(M) && (!client)) //used to be no client or no combat map meaning the AI still did this during RCA, so Im leaving it like this, if its utterly broken during testing Ill remove it
		var/mob/living/carbon/human/obstacle = M
		obstacle.Knockdown(2 SECONDS)
		if(obstacle.a_intent != INTENT_HELP) // When a human is on help intent they are going to get pushed no matter what, bugging this little fix I made.
			step_towards(src, obstacle)
			visible_message(span_danger("[src] tramples [obstacle]! She seems annoyed...."), span_danger("You trample [obstacle]!"))
		else // So I will just make it canon.
			obstacle.deal_damage(10, RED_DAMAGE)
			visible_message(span_danger("[src] crashes into [obstacle]! She seems irritated...."), span_danger("You crash into [obstacle]!"))

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/PickTarget(list/Targets) // Shamelessly stolen from MoSB
	var/list/highest_priority = list()
	var/list/lower_priority = list()
	for(var/mob/living/L in Targets)
		if(!CanAttack(L))
			continue
		if(ishuman(L))
			var/mob/living/carbon/human/rascal = L
			if(rascal.health <= (rascal.maxHealth * KidnapThreshold) || rascal.sanity_lost) // KIDNAP THEM, KIDNAP THEM NOOOOOW!!!
				highest_priority += rascal
			else if(rascal.health < (rascal.maxHealth * (KidnapThreshold * 1.5)) || rascal.stat == DEAD) // You are awfully close to getting kidnapped, pal. / Yummers, soul scraps.
				lower_priority += rascal
			continue
		if(L.stat == DEAD)
			continue
	if(LAZYLEN(highest_priority))
		return pick(highest_priority)
	if(LAZYLEN(lower_priority))
		return pick(lower_priority)
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/AttackingTarget(atom/attacked_target)
	if(finishing)
		return FALSE
	if(ishuman(attacked_target))
		var/mob/living/carbon/human/H = attacked_target
		if(H.stat == DEAD)
			CorpseEat(H)
			return FALSE
		if(H.health < (H.maxHealth * KidnapThreshold) || H.sanity_lost)
			finishing = TRUE
			icon_state = finisher_sprite
			playsound(get_turf(src), 'sound/hallucinations/growl1.ogg', 75, 1)
			H.Stun(1 SECONDS)
			to_chat(H, span_userdanger("Oh no."))
			SLEEP_CHECK_DEATH(0.5 SECONDS)
			if(!targets_from.Adjacent(H) || QDELETED(H)) // They can still be saved if you move them away
				icon_state = normal_sprite
				to_chat(H, span_nicegreen("That was far too close."))
				finishing = FALSE
				return
			if(H.stat == DEAD)
				CorpseEat(H, consumed_soul_heal, 50)
				finishing = FALSE
				icon_state = normal_sprite
				return
			Kidnap(H) // It will now try to take your soul and leave your skin. You will become an eternal prisoner under her skirt in GBJ
			LoseTarget(H)
			finishing = FALSE
			icon_state = normal_sprite
			return
	. = ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/proc/CorpseEat(mob/living/carbon/human/corpse, SoulHealing = (consumed_soul_heal/2), SoulProb = 10)
	corpse.dust()
	adjustBruteLoss(-(maxHealth * SoulHealing)) // Heal half from corpses and dust them.
	if(prob(SoulProb))
		captured_souls++

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/proc/Kidnap(mob/living/carbon/human/rulebreaker)
	if(!rulebreaker)
		return FALSE
	if(KidnapStuntime)
		rulebreaker.Stun(KidnapStuntime) // You gotta get saved by another person, nerd.
	else
		to_chat(rulebreaker, span_userdanger("You can still move, attack [src] to escape!!"))
		KidnapStuntime = initial(KidnapStuntime) // Reset the var for future kidnappings
	rulebreaker.forceMove(src)
	ADD_TRAIT(rulebreaker, TRAIT_NOBREATH, type)
	ApplySouldrain(rulebreaker)
	contained_people++
	Weaken()
	return TRUE

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/proc/Jailbreak()
	var/freedom = pick(get_adjacent_open_turfs(src))
	playsound(get_turf(src), 'sound/effects/limbus_death.ogg', 75, 1)
	for(var/atom/movable/i in contents)
		if(isliving(i))
			var/mob/living/L = i
			L.remove_status_effect(STATUS_EFFECT_SOULDRAIN)
			contained_people--
			RevertWeakness()
		i.forceMove(freedom)
	// Just reset the variables after popping.
	release_damage = 0
	SLEEP_CHECK_DEATH(50) // 5 whole seconds of stun, you should be grateful.

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/proc/Indoctrination(mob/living/loser)
	var/notquitefreedom = pick(get_adjacent_open_turfs(src))
	dropHardClothing(loser, get_turf(src))
	var/mob/living/simple_animal/hostile/rca_soulless/L = new(notquitefreedom)
	L.faction = src.faction // This should prevent Pink Midnight and other faction changes from fucking with the aggro.
	loser.death() // Lol, lmao.
	qdel(loser)
	soul_names += loser.real_name
	L.name = "[loser.real_name]"
	L.desc = "[loser.real_name] face is drained of colour and [loser.p_their()] eyes look glassy and unfocused."
	indoctrinated_morons += L
	contained_people--
	captured_souls++
	RevertWeakness()
	Strengthen()

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/proc/Weaken(VulnerabilityFactor = digestion_modifier)
	DamageAlteration(-damage_down)
	ResistanceAlteration(VulnerabilityFactor)
	ChangeMoveToDelayBy(1.25, TRUE)
	UpdatePhase()

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/proc/RevertWeakness(VulnerabilityFactor = digestion_modifier) // Inverse function of Weaken()
	DamageAlteration(damage_down)
	ResistanceAlteration(-(VulnerabilityFactor))
	ChangeMoveToDelayBy(0.8, TRUE)
	UpdatePhase()

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/proc/Strengthen(ResistanceChange = consumed_soul_modifier, DamageChange = -(damage_degradation), SoulHealing = consumed_soul_heal)
	// A tiny bit of damage degradation for each soul consumed, capped at 20 lower damage and 30 upper damage.
	DamageAlteration(DamageChange)
	ResistanceAlteration(-(ResistanceChange))
	ChangeMoveToDelayBy(0.9, TRUE)
	adjustBruteLoss(-(maxHealth * SoulHealing)) // Heals a % of her max HP, fuck you that's why.
	// UpdatePhase() Might not be necessary here.

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/proc/UpdatePhase()
	if(captured_souls < overfilled_threshold)
		return
	else
		if(!overfilled)
			overfilled = TRUE
			ChangeMoveToDelayBy(0.6, TRUE) // Shit just got real.
			adjustBruteLoss(-(maxHealth * 0.5)) // Round two, baby.
			normal_sprite = "warden_suffering"
			finisher_sprite = "warden_agonize"
			lastcreepysound = world.time
			playsound(get_turf(src), 'sound/creatures/legion_spawn.ogg', 80, 0, 8)
			return
		if(contained_people && !agony)
			normal_sprite = "warden_agony" // This version of the sprite has the skirt moving, people are trying to escape from the inside.
			agony = TRUE
		else if(!contained_people)
			normal_sprite = "warden_suffering"
			agony = FALSE


/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/proc/ResistanceAlteration(factor)
	if(factor == 0) // If we called this proc but no alteration is needed.
		return
	var/list/defenses = damage_coeff.getList()
	for(var/damtype in defenses)
		if(damtype == "brute" || damtype == "fire")
			continue			 // Yes, if you set the resistance cap too high (> 0.4) this will actually weaken certain Warden resistances.
		defenses[damtype] = clamp((defenses[damtype] += factor), resistance_cap, 3)						// Why would you do that though?
	ChangeResistances(defenses)

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/proc/DamageAlteration(factor, affects_upper = FALSE) // Just you know, this was a bit cursed in the first iteration.
	melee_damage_lower = clamp((melee_damage_lower + factor), lower_damage_cap, 150)
	melee_damage_upper = clamp((melee_damage_upper + factor), upper_damage_cap, 150)

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/proc/WakeUpBraindeads()
	if(LAZYLEN(indoctrinated_morons))
		for(var/mob/living/simple_animal/hostile/rca_soulless/husk in indoctrinated_morons)
			husk.Agitate(rand(4, 15))

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/Life()
	. = ..()
	if(world.time > lastcreepysound + creepysoundcooldown)
		if(prob(1 + (captured_souls * 2))) // Add creepy whispers scaling with captured souls and upgrade to screams if Warden is overfilled.
			if(overfilled)
				var/message = "A horrible cacophony of discordant voices comes from [src]'s dress."
				if(LAZYLEN(soul_names))
					var/dumbidiot = pick(soul_names)
					message += " You think you can hear [dumbidiot] screaming in there too."
				visible_message("[message]")
				playsound(get_turf(src), 'sound/creatures/legion_spawn.ogg', 60, 0, 8)
				lastcreepysound = world.time
			else
				visible_message("You hear strange sounds coming from beneath [src]'s dress.")
				playsound(get_turf(src), 'sound/spookoween/ghost_whisper.ogg', 60, 0, 8)
				lastcreepysound = world.time
			WakeUpBraindeads()
		return

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/proc/StatCheck_Devour(mob/living/carbon/human/victim)
	victim.Stun(5 SECONDS)
	to_chat(victim, span_userdanger("You feel overwhelmed by the dangers of this facility!"))
	sleep(0.5 SECONDS)
	step_towards(victim, src)
	sleep(1 SECONDS)
	if(QDELETED(victim))
		return
	icon_state = finisher_sprite
	step_towards(victim, src)
	to_chat(victim, span_warning("[src] beckons you with promises of safety."))
	sleep(1 SECONDS)
	if(QDELETED(victim))
		return
	victim.emote("shiver")
	sleep(0.8 SECONDS)
	if(QDELETED(victim))
		return
	to_chat(victim, span_userdanger("You step into [src]'s dress."))
	Kidnap(victim)
	icon_state = normal_sprite
	return

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	release_damage += damage_amount
	if(release_damage >= jailbreak_threshold)
		Jailbreak()

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/bullet_act(obj/projectile/P)
	visible_message(span_userdanger("[src] is unfazed by \the [P]!"))
	new /obj/effect/temp_visual/healing/no_dam(get_turf(src))
	P.Destroy()

/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/proc/ApplySouldrain(mob/living/carbon/human/victim)
	if(!victim)
		return
	victim.apply_status_effect(STATUS_EFFECT_SOULDRAIN, src, soul_consume_rate)

/datum/status_effect/rca_souldrain
	id = "souldrain"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	tick_interval = 6 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/rca_souldrain
	var/collected_soul
	var/mob/living/simple_animal/hostile/rcorp_abno/easy/warden/warden
	var/soul_degradation
	var/consumed = FALSE

/atom/movable/screen/alert/status_effect/rca_souldrain
	name = "Soul Drain"
	desc = "Thoughts, feelings, memories...everything is slipping away... Until freed or turned... you will be healed while your sanity and max sanity are lost."
	icon = 'icons/mob/actions/actions_spells.dmi'
	icon_state = "void_magnet"

/datum/status_effect/rca_souldrain/on_creation(mob/living/new_owner, master, consume_rate) // Easy way to make sure that we do not get fucked by the warden define being too late
	warden = master
	soul_degradation = consume_rate
	return ..()

/datum/status_effect/rca_souldrain/on_apply()
	var/mob/living/carbon/human/status_holder = owner
	status_holder.adjust_attribute_bonus(PRUDENCE_ATTRIBUTE, -20)
	collected_soul += 20
	if(status_holder.sanity_lost || status_holder.stat == DEAD)
		consumed = TRUE
		warden.Indoctrination(status_holder)
	return ..()

/datum/status_effect/rca_souldrain/tick()
	. = ..()
	var/mob/living/carbon/human/status_holder = owner
	if(!warden) // If somehow the Warden doesnt delete your status effect after dying, this will.
		qdel(src)
	var/soulless = get_turf(owner)
	var/girlboss = get_turf(warden)
	if(soulless == girlboss) // Are you still inside the Warden? If yes then get ready to get spiritually husked bucko
		status_holder.adjustBruteLoss(-(status_holder.maxHealth*0.025)) // It cares for your fleshy form while sucking out your soul.
		status_holder.adjust_attribute_bonus(PRUDENCE_ATTRIBUTE, -soul_degradation) // This lowers your maximum sanity
		status_holder.adjustSanityLoss(round(collected_soul*0.1)) // Somehow people can have negative max sanity without insanning if they do not receive damage.
		collected_soul += soul_degradation // The sanity damage increases every tick.
		if(status_holder.sanity_lost || status_holder.stat == DEAD)
			consumed = TRUE
			warden.Indoctrination(status_holder)
	else // If not, then congrats you have mastered the art of teleportation (And you are safe, for now.)
		to_chat(owner, span_nicegreen("That thing is still alive, but you have somehow managed to escape from its grasp."))
		warden.RevertWeakness()
		warden.contained_people--
		qdel(src)

/datum/status_effect/rca_souldrain/on_remove()
	var/mob/living/carbon/human/status_holder = owner
	if(!status_holder && !consumed)
		warden.RevertWeakness()
		warden.contained_people--
		return ..()
	if(status_holder.IsStun())
		status_holder.SetStun(0)
	REMOVE_TRAIT(status_holder, TRAIT_NOBREATH, type)
	status_holder.adjust_attribute_bonus(PRUDENCE_ATTRIBUTE, collected_soul)
	status_holder.adjustSanityLoss(-collected_soul)
	return ..()


// The mob that spawns when someone's soul gets fully consumed.
/mob/living/simple_animal/hostile/rca_soulless
	name = "Soulless husk"
	desc = "A flesh automaton animated only by neurotransmitters after having their divine light severed."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "soulless_husk" // Whatever! Go my codersprite!
	icon_living = "soulless_husk"
	speak_emote = list("screeches")
	attack_verb_continuous = "attacks"
	attack_verb_simple = "attack"
	attack_sound = 'sound/creatures/lc13/lovetown/slam.ogg'
	/* Stats */
	health = 600
	maxHealth = 600
	damage_coeff = list(RED_DAMAGE = 2.2, WHITE_DAMAGE = 0.2, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 0) // No soul all meat, no PALE but extremely weak to RED.
	melee_damage_type = RED_DAMAGE
	melee_damage_lower = 20
	melee_damage_upper = 30
	speed = 2
	move_to_delay = 2
	robust_searching = TRUE
	stat_attack = SOFT_CRIT // They do not kill, or Warden would have a hard time kidnapping people once she snowballs.
	del_on_death = TRUE
	var/desc_change = FALSE

/mob/living/simple_animal/hostile/rca_soulless/Login()
	. = ..()
	to_chat(src, "<h1>You are Soulless Husk, A Warden Minion.</h1><br>\
		<b>|Wake-up Call|: Every lifetick Warden has a chance to agitate all Soulless Husks, upon doing so their upper damage will raise by 5, this is indicated by screaming. \
		This damage increase may be applied repeatedly for each time the Warden triggers |Wake-up Call|.</b>")

/mob/living/simple_animal/hostile/rca_soulless/Life()
	. = ..()
	if(prob(20))
		emote("twitch")

/mob/living/simple_animal/hostile/rca_soulless/death(gibbed)
	. = ..()
	for(var/turf/L in view(4, src))
		if(prob(25) && !(L.density))
			new /obj/item/food/meat/slab/human (get_turf(L))
		var/obj/effect/decal/cleanable/blood/B = new /obj/effect/decal/cleanable/blood(get_turf(L))
		B.bloodiness = 100
		gib()

/mob/living/simple_animal/hostile/rca_soulless/proc/Agitate(WakeUpTime)
	SLEEP_CHECK_DEATH(WakeUpTime)
	emote("scream")
	if(!desc_change)
		desc += " [p_their(TRUE)] limbs seem to be moving erratically, as if controlled by some unseen force."
		desc_change = TRUE
		return
	melee_damage_upper += 5
