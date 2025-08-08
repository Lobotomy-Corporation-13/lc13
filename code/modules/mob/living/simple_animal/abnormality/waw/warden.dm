#define STATUS_EFFECT_SOULDRAIN /datum/status_effect/souldrain
/mob/living/simple_animal/hostile/abnormality/warden
	name = "The Warden"
	desc = "An abnormality that takes the form of a fleshy stick wearing a dress and eyes. You don't want to know what's under that dress."
	icon = 'ModularTegustation/Teguicons/48x64.dmi'
	icon_state = "warden"
	icon_living = "warden"
	icon_dead = "warden_dead"
	portrait = "warden"
	faction = list("warden")
	maxHealth = 2500
	health = 2500
	pixel_x = -8
	base_pixel_x = -8
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.4, PALE_DAMAGE = 1.5)
	move_to_delay = 4
	melee_damage_lower = 70
	melee_damage_upper = 70
	melee_damage_type = BLACK_DAMAGE
	stat_attack = HARD_CRIT
	attack_sound = 'sound/weapons/slashmiss.ogg'
	attack_verb_continuous = "claws"
	attack_verb_simple = "claws"
	faction = list("warden") // Are you OUTSIDE of your CELL?!?!
	del_on_death = FALSE
	can_breach = TRUE
	can_patrol = TRUE
	move_force = 3000 // To crush the lil' humans
	patrol_cooldown_time = 5 SECONDS
	threat_level = WAW_LEVEL
	start_qliphoth = 1 // It has a chance to breach every time another abnormality breaches.
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 40,
		ABNORMALITY_WORK_INSIGHT = 15,
		ABNORMALITY_WORK_ATTACHMENT = 0,
		ABNORMALITY_WORK_REPRESSION = 50,
		"Release" = 100,
	)
	work_damage_amount = 8
	work_damage_type = BLACK_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/gluttony

	ego_list = list(
		/datum/ego_datum/weapon/correctional,
		/datum/ego_datum/armor/correctional,
	)
	gift_type =  /datum/ego_gifts/correctional
	abnormality_origin = ABNORMALITY_ORIGIN_ARTBOOK

	observation_prompt = "She wanders the facility's halls, doing her rounds and picking the last of us off. <br>\
		As far as I know it's just me left. <br>\
		The site burial went off and escape is impossible, yet, the other abnormalities remain in their cells - if they leave she forces them back inside. <br>\
		Maybe if I enter one of the unused cells, she might leave me alone?"
	observation_choices = list(
		"Enter a cell" = list(TRUE, "I step inside and lock the door behind me, <br>I'm stuck inside. <br>\
			She passes by the containment unit and peers through the glass and seems satisfied."),
		"Surrender to her" = list(FALSE, "Steeling myself, I confront her during one of her rounds. <br>I tell her I'm tired and just want it to end. <br>\
			She gets closer and lifts her skirt(?) and I'm thrust underneath, my colleagues are here- they're alive and well! <br>\
			But, they seem despondent. <br>One looks at me says simply; \"In here, you're with us. Forever.\""),
	)
	var/normal_sprite = "warden"
	var/finisher_sprite = "warden_attack"

	var/statcheck_fail = FALSE

	var/combatmap = FALSE

	var/finishing = FALSE
	var/locked_in = FALSE
	var/mob/living/hooligan
	var/AreasToPatrol = list()
	var/breach_time = 3 MINUTES

	// Frustration + Release mechanics
	var/attitude
	var/frustration
	var/released = FALSE
	// This is used to check if Warden killed any hostile mob in its current "patrol"
	var/RecontainedSomething = FALSE

	// If an employee has less than this % of HP left, Warden will kidnap them.
	var/KidnapThreshold = 0.25
	// By default extremely high, you are supposed to be freed by other employees.
	var/KidnapStuntime = 999

	var/contained_people
	var/captured_souls
	var/indoctrinated_morons = list()
	// This is the flat amount of max sanity decrease that kidnapped people get every 6 seconds.
	var/soul_consume_rate = 10

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

	// If available agents with a level higher than the level threshold is less than this var, then activate weakjail
	var/weakjailthreshold = 2
	// This is the level threshold to activate weakjail
	var/weaklevelthreshold = 3
	// If this is true then Warden can be popped open like a piñata with enough damage (normally it's only on-kill), and also it does not stun those it consumes.
	var/weakjail = FALSE
	// Keeps track of damage received after consuming someone on weakjail mode.
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

/mob/living/simple_animal/hostile/abnormality/warden/Login() // VERY WIP, when the RCA tweaks actually get made then this can be changed.
	. = ..()
	to_chat(src, "<h1>You are Warden, A Tank Role Abnormality.</h1><br>\
		<b>|Soul Guard|: You are immune to all projectiles.<br>\
		<br>\
		|Soul Warden|: If you attack a living human with less than [KidnapThreshold * 100]% HP (or currently insane), you will kidnap them and begin to devour their soul.<br>\
		While devouring someone's soul, you will be slower, weaker and more frail than usual. <br>\
		If you successfully devour a soul you will heal [consumed_soul_heal * 100]% of your HP and you will spawn a subordinate mob. <br>\
		For each soul consumed, you will become faster and more resilient, but your damage will decrease by [damage_degradation].<br>\
		If you receive [jailbreak_threshold] pre-reduction damage while in the process of devouring a soul, you will get stunned and puke every single human currently inside of you.<br>\
		Attack a human corpse to consume whatever scraps of their soul remain, healing you for [consumed_soul_heal * 50]% of your maximum HP </b>")

/mob/living/simple_animal/hostile/abnormality/warden/Initialize()
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_ABNORMALITY_BREACH, PROC_REF(OnAbnoBreach))
	if(IsCombatMap())
		CombatMapTweaks()

/mob/living/simple_animal/hostile/abnormality/warden/Destroy()
	UnregisterSignal(SSdcs, COMSIG_GLOB_ABNORMALITY_BREACH)
	QDEL_NULL(soul_names) // It WOULD be fun if Warden saved all soul names that it has consumed but I cannot be assed to figure that out.
	QDEL_NULL(AreasToPatrol)
	for(var/mob/living/carbon/human/L in GLOB.player_list) // Cleanse debuffs
		if(faction_check_mob(L, FALSE) || L.stat == DEAD) // Dead? Fuck them
			continue
		var/datum/status_effect/S = L.has_status_effect(/datum/status_effect/souldrain)
		if(S)
			qdel(S)
	return ..()

/mob/living/simple_animal/hostile/abnormality/warden/death(gibbed)
	density = FALSE
	for(var/mob/living/L in indoctrinated_morons)
		indoctrinated_morons -= L
		L.dust()
	Jailbreak()
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	..()

/mob/living/simple_animal/hostile/abnormality/warden/CanAttack(atom/the_target)
	if(finishing)
		return FALSE
	if(!combatmap)
		if(ishuman(the_target) && attitude <= 1)
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/abnormality/warden/Move()
	if(finishing)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/abnormality/warden/MobBump(mob/M)
	. = ..()
	if(ishuman(M) && (!combatmap || !client))
		var/mob/living/carbon/human/obstacle = M
		obstacle.Knockdown(2 SECONDS)
		if(obstacle.a_intent != INTENT_HELP) // When a human is on help intent they are going to get pushed no matter what, bugging this little fix I made.
			step_towards(src, obstacle)
			visible_message(span_danger("[src] tramples [obstacle]! She seems annoyed...."), span_danger("You trample [obstacle]!"))
			HandleFrustration(1)
		else // So I will just make it canon.
			obstacle.deal_damage(10, RED_DAMAGE)
			visible_message(span_danger("[src] crashes into [obstacle]! She seems irritated...."), span_danger("You crash into [obstacle]!"))
			HandleFrustration(2)
// Okay then, try to put the necessary RCA tweaks inside this proc, especially if they are just value changes.
/mob/living/simple_animal/hostile/abnormality/warden/proc/CombatMapTweaks() // WIP
	combatmap = TRUE
	weakjail = TRUE
	soul_consume_rate = 50
	KidnapThreshold = 35
	var/datum/atom_hud/medsensor = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED] // Placeholder.
	medsensor.add_hud_to(src) // My crazy idea would be giving it a HUD that puts special effects around vulnerable mobs, but for now this will do.
	return

/mob/living/simple_animal/hostile/abnormality/warden/PickTarget(list/Targets) // Shamelessly stolen from MoSB
	var/list/rulebreakers = list()
	var/list/highest_priority = list()
	var/list/lower_priority = list()
	for(var/mob/living/L in Targets)
		if(!CanAttack(L))
			continue
		if(istype(L, /mob/living/simple_animal/hostile/abnormality)) // Are you a weakling breach, perchance?
			if(L.stat == DEAD)
				continue
			var/mob/living/simple_animal/hostile/abnormality/prisoner = L
			if(!prisoner.IsContained() && prisoner.threat_level != ALEPH_LEVEL && prisoner.datum_reference)
				rulebreakers += L // AAAAIIIEEEEEEE GO BACK TO YOUR CEEEEEEELL
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
	if(LAZYLEN(rulebreakers))
		return pick(rulebreakers)
	if(LAZYLEN(highest_priority))
		return pick(highest_priority)
	if(LAZYLEN(lower_priority))
		return pick(lower_priority)
	return ..()

/mob/living/simple_animal/hostile/abnormality/warden/AttackingTarget(atom/attacked_target)
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
			if(combatmap)
				return // WIP
			return
	else if(istype(attacked_target, /mob/living/simple_animal/hostile))
		if(combatmap)
			return FALSE
		var/mob/living/simple_animal/hostile/target = attacked_target
		if(prob(10))
			finishing = TRUE
			icon_state = finisher_sprite
			playsound(get_turf(src), 'sound/effects/ordeals/amber/dusk_attack.ogg', 60, 1)
			target.adjustBruteLoss(melee_damage_upper * 5) // Big damage.
			SLEEP_CHECK_DEATH(0.5 SECONDS)
			finishing = FALSE
			icon_state = normal_sprite
			return
	. = ..()
	if(istype(attacked_target, /mob/living/simple_animal/hostile/abnormality))
		var/mob/living/simple_animal/hostile/abnormality/fugitive = attacked_target
		if(fugitive.stat == DEAD)
			DamageAlteration(damage_up, affects_upper = TRUE)
			RecontainedSomething = TRUE

/mob/living/simple_animal/hostile/abnormality/warden/proc/CorpseEat(mob/living/carbon/human/corpse, SoulHealing = (consumed_soul_heal/2), SoulProb = 10)
	corpse.dust()
	adjustBruteLoss(-(maxHealth * SoulHealing)) // Heal half from corpses and dust them.
	if(prob(SoulProb))
		captured_souls++

/mob/living/simple_animal/hostile/abnormality/warden/proc/Kidnap(mob/living/carbon/human/rulebreaker)
	if(!rulebreaker)
		return FALSE
	if(!rulebreaker.sanity_lost && !combatmap)
		SoloCheck() // Ok sure lets throw you a bone here.
	if(KidnapStuntime)
		rulebreaker.Stun(KidnapStuntime) // You gotta get saved by another person, nerd.
	else
		to_chat(rulebreaker, span_userdanger("You can still move, attack [src] to escape!!")) // If there is no stun, then weakjail (should) be TRUE.
		KidnapStuntime = initial(KidnapStuntime) // Reset the var for future kidnappings
	rulebreaker.forceMove(src)
	ADD_TRAIT(rulebreaker, TRAIT_NOBREATH, type)
	ApplySouldrain(rulebreaker)
	contained_people++
	Weaken()
	return TRUE

/mob/living/simple_animal/hostile/abnormality/warden/proc/Jailbreak()
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
	if(!combatmap)
		weakjail = FALSE
	release_damage = 0
	SLEEP_CHECK_DEATH(50) // 5 whole seconds of stun, you should be grateful.

/mob/living/simple_animal/hostile/abnormality/warden/proc/Indoctrination(mob/living/loser)
	var/notquitefreedom = pick(get_adjacent_open_turfs(src))
	dropHardClothing(loser, get_turf(src))
	var/mob/living/simple_animal/hostile/soulless/L = new(notquitefreedom)
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

/mob/living/simple_animal/hostile/abnormality/warden/proc/Weaken(VulnerabilityFactor = digestion_modifier)
	DamageAlteration(-damage_down)
	ResistanceAlteration(VulnerabilityFactor)
	ChangeMoveToDelayBy(1.25, TRUE)
	UpdatePhase()

/mob/living/simple_animal/hostile/abnormality/warden/proc/RevertWeakness(VulnerabilityFactor = digestion_modifier) // Inverse function of Weaken()
	DamageAlteration(damage_down)
	ResistanceAlteration(-(VulnerabilityFactor))
	ChangeMoveToDelayBy(0.8, TRUE)
	UpdatePhase()

/mob/living/simple_animal/hostile/abnormality/warden/proc/Strengthen(ResistanceChange = consumed_soul_modifier, DamageChange = -(damage_degradation), SoulHealing = consumed_soul_heal)
	// A tiny bit of damage degradation for each soul consumed, capped at 20 lower damage and 30 upper damage.
	DamageAlteration(DamageChange)
	ResistanceAlteration(-(ResistanceChange))
	ChangeMoveToDelayBy(0.9, TRUE)
	adjustBruteLoss(-(maxHealth * SoulHealing)) // Heals a % of her max HP, fuck you that's why.
	// UpdatePhase() Might not be necessary here.

/mob/living/simple_animal/hostile/abnormality/warden/proc/UpdatePhase()
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


/mob/living/simple_animal/hostile/abnormality/warden/proc/ResistanceAlteration(factor)
	if(factor == 0) // If we called this proc but no alteration is needed.
		return
	var/list/defenses = damage_coeff.getList()
	for(var/damtype in defenses)
		if(damtype == "brute" || damtype == "fire")
			continue			 // Yes, if you set the resistance cap too high (> 0.4) this will actually weaken certain Warden resistances.
		defenses[damtype] = clamp((defenses[damtype] += factor), resistance_cap, 3)						// Why would you do that though?
	ChangeResistances(defenses)

/mob/living/simple_animal/hostile/abnormality/warden/proc/DamageAlteration(factor, affects_upper = FALSE) // Just you know, this was a bit cursed in the first iteration.
	melee_damage_lower = clamp((melee_damage_lower + factor), lower_damage_cap, 150)
	if(combatmap || affects_upper)
		melee_damage_upper = clamp((melee_damage_upper + factor), upper_damage_cap, 150)

/mob/living/simple_animal/hostile/abnormality/warden/proc/HandleFrustration(amount)
	frustration = min((frustration + amount), 10)
	if(frustration == 10)
		attitude = min((attitude + 1), 2)
		frustration = 0

/mob/living/simple_animal/hostile/abnormality/warden/proc/SoloCheck()
	if(combatmap)
		return
	var/vandals = 0
	for(var/mob/living/carbon/human/L in GLOB.player_list)
		if(L.stat >= HARD_CRIT || L.sanity_lost || z != L.z) // Dead or in hard crit, insane, or on a different Z level.
			continue
		if(get_user_level(L) <= weaklevelthreshold)	// If their pals are too weak, lets throw the kidnapped agent a bone.
			continue
		vandals += 1
	if(vandals <= weakjailthreshold) // Let's not talk about how a "Solo" check applies to a duo by default, I do not want to hear it.
		KidnapStuntime = 0
		weakjail = TRUE

/mob/living/simple_animal/hostile/abnormality/warden/proc/HuntFugitives()
	var/list/breached_abnos = list()
	for(var/datum/abnormality/A in SSlobotomy_corp.all_abnormality_datums)
		if(!A.current)
			continue
		var/mob/living/simple_animal/hostile/abnormality/possible_escapee = A.current
		if(z != possible_escapee.z || possible_escapee.stat == DEAD || possible_escapee == src)
			continue
		if(!possible_escapee.IsContained() && possible_escapee.threat_level != ALEPH_LEVEL)
			breached_abnos += possible_escapee
	if(LAZYLEN(breached_abnos))
		var/mob/living/simple_animal/hostile/abnormality/escapee = pick(breached_abnos)
		return escapee
	else
		return FALSE


/mob/living/simple_animal/hostile/abnormality/warden/proc/WakeUpBraindeads()
	if(LAZYLEN(indoctrinated_morons))
		for(var/mob/living/simple_animal/hostile/soulless/husk in indoctrinated_morons)
			husk.Agitate(rand(4, 15))

/mob/living/simple_animal/hostile/abnormality/warden/patrol_select()
	if(SSmaptype.maptype in SSmaptype.autopossess)
		return
	if(hooligan) // Lets just fucking copy this from NI, I am tired.
		var/turf/trytorun = get_turf(hooligan)
		if(!trytorun)
			hooligan = null
			return
		SEND_SIGNAL(src, COMSIG_PATROL_START, src, trytorun) //Overrides the usual proc to target a specific tile
		SEND_GLOBAL_SIGNAL(src, COMSIG_GLOB_PATROL_START, src, trytorun)
		patrol_to(trytorun)
		return
	if(!LAZYLEN(GLOB.department_centers))
		return
	var/turf/target_center
	if(!LAZYLEN(AreasToPatrol))
		for(var/pos_targ in GLOB.department_centers)
			var/possible_center_distance = get_dist(src, pos_targ)
			if(possible_center_distance > 4 && possible_center_distance < 60)
				AreasToPatrol += pos_targ
	target_center = pick(AreasToPatrol)
	SEND_SIGNAL(src, COMSIG_PATROL_START, src, target_center)
	SEND_GLOBAL_SIGNAL(src, COMSIG_GLOB_PATROL_START, src, target_center)
	patrol_path = get_path_to(src, target_center, TYPE_PROC_REF(/turf, Distance_cardinal), 0, 200)
	AreasToPatrol -= target_center

/mob/living/simple_animal/hostile/abnormality/warden/Life()
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

/mob/living/simple_animal/hostile/abnormality/warden/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(!statcheck_fail) // If the person is going to get kidnapped, do not breach too early.
		manual_emote("screeches loudly!")
		attitude = 2
		datum_reference.qliphoth_change(-1)

/mob/living/simple_animal/hostile/abnormality/warden/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(!statcheck_fail) // See above.
		if(attitude == 2)
			manual_emote("shrieks at [user]!")
			datum_reference.qliphoth_change(-1)
		else
			manual_emote("glares at [user].")
			attitude = min((attitude + 1), 2)

/mob/living/simple_animal/hostile/abnormality/warden/AttemptWork(mob/living/carbon/human/user, work_type)
	. = ..()
	if(work_type == "Release")
		released = TRUE
		user.Immobilize(1.5 SECONDS)
		manual_emote("stares intensely at [user].")
		SLEEP_CHECK_DEATH(1.5 SECONDS)
		if(prob(attitude * 25)) // 50% at bad mood to go badly, 25% at neutral mood.
			visible_message(span_danger("[src] lets out a terrible screech!!"))
			attitude = min((attitude + 1), 2) // Enrages her, almost guaranteed to hostile-breach.
		else
			visible_message(span_nicegreen("[src] relaxes, seemingly willing to cooperate.")) // I have no idea what to write here, the fact is that she is happy that agents rely on her.
			attitude = max((attitude - 1), 0) // Calms her down by one mood level.
		datum_reference.qliphoth_change(-1)
		return

	statcheck_fail = FALSE
	if(get_attribute_level(user, JUSTICE_ATTRIBUTE) < 80 && get_attribute_level(user, FORTITUDE_ATTRIBUTE) < 80)
		statcheck_fail = TRUE
		user.emote("shiver") // Welp, you are fucked my dude.

/mob/living/simple_animal/hostile/abnormality/warden/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	if(statcheck_fail)
		StatCheck_Devour(user)
		released = TRUE // If you attack her, she will immediately become hostile. (Lorewise, technically the devoured employee *did* free her willingly.)
		datum_reference.qliphoth_change(-1)
	..()

/mob/living/simple_animal/hostile/abnormality/warden/proc/StatCheck_Devour(mob/living/carbon/human/victim)
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

/mob/living/simple_animal/hostile/abnormality/warden/proc/OnAbnoBreach(datum/source, mob/living/simple_animal/hostile/abnormality/abno)
	SIGNAL_HANDLER
	if(!IsContained())
		return
	if(istype(abno, /mob/living/simple_animal/hostile/abnormality/punishing_bird))
		return
	if(istype(abno, /mob/living/simple_animal/hostile/abnormality/training_rabbit))
		return
	if(abno.threat_level != ALEPH_LEVEL && prob(33 + (attitude * 15))) // Local Warden too scared to ¿fistfight? (Does it even have fists?) WhiteNight
		datum_reference.qliphoth_change(-1)

/mob/living/simple_animal/hostile/abnormality/warden/proc/MeltdownEffect(mob/living/carbon/human/user)

/mob/living/simple_animal/hostile/abnormality/warden/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	if(attitude < 2)
		var/mob/living/simple_animal/hostile/abnormality/escapee = HuntFugitives()
		if(escapee)
			hooligan = escapee
	else // Are we frustrated? Are we not busy? Snap the neck of the agent in front of you.
		GiveTarget(user)
	addtimer(CALLBACK(src, PROC_REF(TrySelfcontain)), breach_time)

/mob/living/simple_animal/hostile/abnormality/warden/proc/TrySelfcontain() // It will try to self-contain if "passive" breaching
	if(combatmap) // How?
		return
	if(attitude == 2) // Will not self-contain (and won't try anymore) if enraged
		return
	if(contained_people || target) // Will not self-contain while eating souls or mid-combat, but it will try again later.
		addtimer(CALLBACK(src, PROC_REF(TrySelfcontain)), 1 MINUTES)
		return
	var/witnesses
	for(var/mob/living/carbon/human/onlooker in oview(8, src))
		witnesses++
	if(witnesses)
		HandleFrustration(2)
		addtimer(CALLBACK(src, PROC_REF(TrySelfcontain)), 30 SECONDS)
		return
	if(!RecontainedSomething) // The Warden wasted her time, she gets pissy.
		attitude = min((attitude + 1), 2)
	adjustBruteLoss(-maxHealth, forced = TRUE)
	toggle_ai(AI_OFF)
	status_flags |= GODMODE
	forceMove(get_turf(datum_reference.landmark))
	dir = SOUTH
	datum_reference.qliphoth_change(start_qliphoth)

/mob/living/simple_animal/hostile/abnormality/warden/attackby(obj/item/W, mob/user, params)
	. = ..()
	if(ishuman(user) && attitude != 2) // No need to keep checking when already enraged.
		if(released || attitude == 1)
			attitude = 2 // Immediate rage.
			GiveTarget(user)
		else
			HandleFrustration(rand(3, 7)) // More RNG = Funny.

/mob/living/simple_animal/hostile/abnormality/warden/apply_damage(damage, damagetype, def_zone, blocked, forced, spread_damage, wound_bonus, bare_wound_bonus, sharpness, white_healable)
	. = ..()
	if(weakjail)
		release_damage += damage
		if(release_damage >= jailbreak_threshold)
			Jailbreak()

/mob/living/simple_animal/hostile/abnormality/warden/bullet_act(obj/projectile/P)
	visible_message(span_userdanger("[src] is unfazed by \the [P]!"))
	new /obj/effect/temp_visual/healing/no_dam(get_turf(src))
	P.Destroy()

/mob/living/simple_animal/hostile/abnormality/warden/proc/ApplySouldrain(mob/living/carbon/human/victim)
	if(!victim)
		return
	victim.apply_status_effect(STATUS_EFFECT_SOULDRAIN, src, soul_consume_rate)

/datum/status_effect/souldrain
	id = "souldrain"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	tick_interval = 6 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/souldrain
	var/collected_soul
	var/mob/living/simple_animal/hostile/abnormality/warden/warden
	var/soul_degradation
	var/consumed = FALSE

/atom/movable/screen/alert/status_effect/souldrain
	name = "Soul Drain"
	desc = "Thoughts, feelings, memories...everything is slipping away..."
	icon = 'icons/mob/actions/actions_spells.dmi'
	icon_state = "void_magnet"

/datum/status_effect/souldrain/on_creation(mob/living/new_owner, master, consume_rate) // Easy way to make sure that we do not get fucked by the warden define being too late
	warden = master
	soul_degradation = consume_rate
	return ..()

/datum/status_effect/souldrain/on_apply()
	var/mob/living/carbon/human/status_holder = owner
	status_holder.adjust_attribute_bonus(PRUDENCE_ATTRIBUTE, -20)
	collected_soul += 20
	if(status_holder.sanity_lost || status_holder.stat == DEAD)
		consumed = TRUE
		warden.Indoctrination(status_holder)
	return ..()

/datum/status_effect/souldrain/tick()
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

/datum/status_effect/souldrain/on_remove()
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
/mob/living/simple_animal/hostile/soulless
	name = "Soulless husk"
	desc = "A flesh automaton animated only by neurotransmitters after having their divine light severed."
	icon = 'ModularTegustation/Teguicons/32x32.dmi'
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

	var/catatonic = TRUE

/mob/living/simple_animal/hostile/soulless/Initialize()
	. = ..()
	if(IsCombatMap())
		catatonic = FALSE

/mob/living/simple_animal/hostile/soulless/CanAttack(atom/the_target)
	if(catatonic)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/soulless/Move()
	if(catatonic)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/soulless/AttackingTarget(atom/attacked_target)
	if(catatonic)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/soulless/Life()
	. = ..()
	if(catatonic)
		if(prob(20))
			emote("twitch")

/mob/living/simple_animal/hostile/soulless/death(gibbed)
	. = ..()
	for(var/turf/L in view(4, src))
		if(prob(25) && !(L.density))
			new /obj/item/food/meat/slab/human (get_turf(L))
		var/obj/effect/decal/cleanable/blood/B = new /obj/effect/decal/cleanable/blood(get_turf(L))
		B.bloodiness = 100
		gib()

/mob/living/simple_animal/hostile/soulless/proc/Agitate(WakeUpTime)
	SLEEP_CHECK_DEATH(WakeUpTime)
	emote("scream")
	if(catatonic)
		desc += " [p_their(TRUE)] limbs seem to be moving erratically, as if controlled by some unseen force."
		catatonic = FALSE
		return
	melee_damage_upper += 5

