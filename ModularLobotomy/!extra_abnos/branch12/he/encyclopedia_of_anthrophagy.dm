// Encyclopedia of Anthrophagy - HE abnormality (a book that eats the well-read).
//
// Work (containment): every work type grants the reader a decaying "knowledge" shield - Insight ("study")
//   gives the most (~25 at a full result), the other three less (~10), both scaled by how many boxes
//   succeeded. Carrying more shield makes work easier (+1% success per 5 shield). At the end of each
//   session the book first tries to devour the reader, with a chance equal to half their current shield -
//   so the better-read they are, the likelier they are eaten. A devoured reader steps the Qliphoth Counter
//   down by one; at zero the book breaches "looking for food".
//
// Combat (breach): it walks the halls on its legs and hunts the LEARNED. It prioritises the highest-Prudence
//   target, deals bonus melee scaled by the target's Prudence, and the single living person with the most
//   Prudence takes DOUBLE that bonus. If its target is more than 10 tiles away it moves three times as fast
//   to close in. It devours the downed to heal fully and grow stronger, and lashes its tongue in a line to
//   catch fleeing food.

// Knowledge shield: modelled on /datum/component/dieci_shield_hp - a flat HP shield that absorbs
// incoming damage before armour and decays by half every 10s.
/datum/component/knowledge_shield
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Current shield HP.
	var/shield_health = 0
	/// Maximum shield HP cap.
	var/max_shield_health = 400
	/// Looping decay timer id - halves the shield every 10 seconds.
	var/decay_timer_id

/datum/component/knowledge_shield/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/knowledge_shield/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_damage))

/datum/component/knowledge_shield/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_APPLY_DAMGE)
	. = ..()

/datum/component/knowledge_shield/Destroy()
	if(decay_timer_id)
		deltimer(decay_timer_id)
		decay_timer_id = null
	var/mob/living/owner = parent
	if(owner && !QDELETED(owner))
		owner.remove_filter("knowledge_shield")
	return ..()

/// Add shield HP, capped at max_shield_health. Starts or resets the decay timer.
/datum/component/knowledge_shield/proc/add_shield(amount)
	if(amount <= 0)
		return
	shield_health = min(shield_health + amount, max_shield_health)
	if(shield_health > 0 && !decay_timer_id)
		start_decay()
	update_shield_visual()

/datum/component/knowledge_shield/proc/start_decay()
	if(decay_timer_id)
		deltimer(decay_timer_id)
	decay_timer_id = addtimer(CALLBACK(src, PROC_REF(decay_tick)), 10 SECONDS, TIMER_STOPPABLE | TIMER_LOOP)

/datum/component/knowledge_shield/proc/decay_tick()
	shield_health = round(shield_health * 0.5)
	if(shield_health <= 0)
		shield_health = 0
		stop_decay()
	update_shield_visual()

/datum/component/knowledge_shield/proc/stop_decay()
	if(decay_timer_id)
		deltimer(decay_timer_id)
		decay_timer_id = null

/// Absorb incoming damage into the shield. Forced damage bypasses it (prevents recursion on overflow).
/datum/component/knowledge_shield/proc/on_damage(datum/source, damage, damagetype, def_zone, atom/damage_source, flags, attack_type)
	SIGNAL_HANDLER
	if(flags & DAMAGE_FORCED)
		return
	if(shield_health <= 0)
		return
	if(damage <= shield_health)
		shield_health -= damage
		spawn_shield_visual()
		if(shield_health <= 0)
			stop_decay()
		update_shield_visual()
		return COMPONENT_MOB_DENY_DAMAGE
	// Partial - the shield breaks and the overflow is re-dealt as forced damage.
	var/overflow = damage - shield_health
	shield_health = 0
	stop_decay()
	spawn_shield_visual()
	update_shield_visual()
	var/mob/living/owner = parent
	INVOKE_ASYNC(owner, TYPE_PROC_REF(/mob/living, deal_damage), overflow, damagetype, damage_source, DAMAGE_FORCED, null, null, def_zone)
	return COMPONENT_MOB_DENY_DAMAGE

/datum/component/knowledge_shield/proc/spawn_shield_visual()
	var/mob/living/owner = parent
	var/obj/effect/temp_visual/shock_shield/effect = new(get_turf(owner))
	effect.transform *= 0.5
	effect.pixel_x += rand(-8, 8)

/// Persistent parchment outline whose intensity scales with the shield amount.
/datum/component/knowledge_shield/proc/update_shield_visual()
	var/mob/living/owner = parent
	if(!owner || QDELETED(owner))
		return
	if(shield_health > 0)
		var/intensity = clamp(shield_health / max_shield_health, 0.3, 1.0)
		var/size_val = round(1 + intensity)
		owner.add_filter("knowledge_shield", 5, list("type" = "outline", "color" = "#E8D8A050", "size" = size_val))
	else
		owner.remove_filter("knowledge_shield")

/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy
	name = "Encyclopedia of Anthrophagy"
	desc = "A great brown book with a single wet eye set in its cover and a maw of torn pages. It walks on \
		thin, jointed legs, and its bookmark hangs from the spine like a lolling red tongue."
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/96x96.dmi'
	icon_state = "anthrophagy"
	icon_living = "anthrophagy"
	icon_dead = "anthrophagy_dead"
	pixel_x = -32
	base_pixel_x = -32
	maxHealth = 1200
	health = 1200
	stat_attack = HARD_CRIT
	move_to_delay = 4
	del_on_death = FALSE
	can_breach = TRUE
	start_qliphoth = 2
	threat_level = HE_LEVEL
	melee_damage_lower = 22
	melee_damage_upper = 30
	melee_damage_type = BLACK_DAMAGE
	attack_sound = 'sound/abnormalities/bigbird/bite.ogg'
	ranged = TRUE
	ranged_cooldown_time = 80
	minimum_distance = 1
	// It hunts a specific person across the map: barrel through crowds and re-path to its prey often.
	generic_canpass = FALSE
	patrol_cooldown_time = 4 SECONDS
	faction = list("hostile")
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)

	//Work - only Insight ("study") is worthwhile, and it is the only source of knowledge.
	work_damage_amount = 8
	work_damage_type = WHITE_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/pride
	max_boxes = 18
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 50,
		ABNORMALITY_WORK_INSIGHT = list(85, 88, 88, 90, 90),
		ABNORMALITY_WORK_ATTACHMENT = 40,
		ABNORMALITY_WORK_REPRESSION = 65,
	)

	ego_list = list(
		/datum/ego_datum/weapon/branch12/consumption,
		/datum/ego_datum/armor/branch12/consumption,
	)
	gift_type = /datum/ego_gifts/branch12/consumption
	gift_message = "The book falls open to a page that was not there before, and lets you keep what you read."

	observation_prompt = "The Encyclopedia lies open, its eye rolled up to watch you. <br>Every page you \
		turn seems to know a little more of you than the last."
	observation_choices = list(
		"Read on" = list(TRUE, "You read until the letters swim, and something of them stays behind your \
			eyes. You feel armoured by what you know - and watched by what knows you."),
		"Close the book" = list(FALSE, "The maw of torn pages works once, slowly, as if tasting the air \
			where your hand just was. It is very patient."),
	)

	/// Bonus melee per point of the target's Prudence (1 per 4 Prudence), on top of base melee.
	var/prudence_bite = 0.25
	/// Meals eaten during the current breach - each one escalates it. Resets on respawn (per-breach state).
	var/meals = 0
	/// Set TRUE while a tongue-lash is animating, to block overlapping attacks.
	var/busy = FALSE
	/// TRUE while sprinting to close on distant prey; guards against redundant speed changes.
	var/rushing = FALSE

/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy/death(gibbed)
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	return ..()

// The worker's current knowledge-shield HP, 0 if they hold none.
/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy/proc/ShieldAmount(mob/living/user)
	var/datum/component/knowledge_shield/shield = user.GetComponent(/datum/component/knowledge_shield)
	return shield ? shield.shield_health : 0

// The more knowledge-shield a worker carries, the easier the study goes: +1% per 5 shield.
/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy/WorkChance(mob/living/carbon/human/user, chance, work_type)
	return chance + round(ShieldAmount(user) / 5)

/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time, canceled)
	. = ..()
	if(canceled)
		return
	// First it tries to devour the reader - chance equal to half the shield they currently carry.
	if(prob(clamp(round(ShieldAmount(user) * 0.5), 0, 100)))
		ConsumeWorker(user)
		return
	// Survivors are armoured further, scaled by how many boxes succeeded (Insight teaches the most).
	var/base = (work_type == ABNORMALITY_WORK_INSIGHT) ? 25 : 10
	GrantKnowledgeShield(user, round(base * min(pe, max_boxes) / max_boxes))

/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy/proc/GrantKnowledgeShield(mob/living/carbon/human/user, amount)
	if(!istype(user) || amount <= 0)
		return
	var/datum/component/knowledge_shield/shield = user.GetComponent(/datum/component/knowledge_shield)
	if(!shield)
		shield = user.AddComponent(/datum/component/knowledge_shield)
	shield.add_shield(amount)

// Eat a reader and step toward breach. When the counter hits 0 the base code fires ZeroQliphoth -> breach.
/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy/proc/ConsumeWorker(mob/living/carbon/human/victim)
	if(!istype(victim))
		return
	visible_message(span_userdanger("The Encyclopedia's torn pages snap shut over [victim] and swallow \
		them whole!"))
	playsound(get_turf(src), 'sound/abnormalities/bigbird/bite.ogg', 70, TRUE)
	victim.gib()
	datum_reference?.qliphoth_change(-1)

/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy/BreachEffect(mob/living/carbon/human/user, breach_type = BREACH_NORMAL)
	. = ..()
	meals = 0
	// Establish the baseline walking speed for the hunt.
	rushing = FALSE
	move_to_delay = initial(move_to_delay)
	ChangeMoveToDelay(initial(move_to_delay))
	visible_message(span_userdanger("The Encyclopedia heaves itself up onto its legs, pages gnashing - it \
		is hungry, and it can smell the learned."))

/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy/PickTarget(list/Targets)
	var/mob/living/carbon/human/best
	var/best_pru = -1
	for(var/mob/living/carbon/human/H in Targets)
		if(H.stat == DEAD || !CanAttack(H))
			continue
		var/pru = get_attribute_level(H, PRUDENCE_ATTRIBUTE)
		if(pru > best_pru)
			best_pru = pru
			best = H
	if(best)
		return best
	return ..()

/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy/proc/HighestPrudenceHuman()
	var/mob/living/carbon/human/best
	var/best_pru = -1
	for(var/mob/living/carbon/human/H in GLOB.human_list)
		if(H.z != z || H.stat == DEAD || isnull(H.ckey))
			continue
		var/pru = get_attribute_level(H, PRUDENCE_ATTRIBUTE)
		if(pru > best_pru)
			best_pru = pru
			best = H
	return best

// Hunt across the map: patrol straight toward the most-learned person instead of wandering at random.
/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy/SelectPatrolLocation()
	var/mob/living/carbon/human/prey = HighestPrudenceHuman()
	if(prey)
		return get_turf(prey)
	return ..()

// The moment a patrol ends, look for prey to lock onto and chase down directly.
/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy/patrol_reset()
	. = ..()
	FindTarget()

// Nothing in the halls stops it reaching the learned - it shoves through other mobs (but not its prey).
/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy/CanPassThrough(atom/blocker, turf/target_turf, blocker_opinion)
	if(isliving(blocker) && blocker != target)
		return TRUE
	return ..()

// It fixates on its chosen prey; being hit by others never makes it switch targets.
/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy/RegisterAggroValue(atom/remembered_target, value, damage_type)
	return FALSE

/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy/AttackingTarget(atom/attacked_target)
	. = ..()
	if(!ishuman(attacked_target))
		return
	var/mob/living/carbon/human/H = attacked_target
	// Devour the downed: a killing bite heals it fully and makes it stronger and faster.
	if(H.health < 0 || H.stat >= HARD_CRIT)
		playsound(get_turf(src), 'sound/abnormalities/bigbird/bite.ogg', 70, TRUE)
		visible_message(span_userdanger("The Encyclopedia devours [H]!"))
		H.gib()
		adjustBruteLoss(-maxHealth * 0.5, forced = TRUE)
		Feed()
		return
	// Bonus damage scaled by how learned the target is; the most learned of all takes double.
	var/bonus = round(get_attribute_level(H, PRUDENCE_ATTRIBUTE) * prudence_bite)
	if(bonus <= 0)
		return
	if(H == HighestPrudenceHuman())
		bonus *= 2
	H.deal_damage(bonus, BLACK_DAMAGE, source = src, attack_type = ATTACK_TYPE_SPECIAL)

// Each meal permanently sharpens it for the rest of the breach (capped).
/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy/proc/Feed()
	meals = min(meals + 1, 5)
	melee_damage_lower = initial(melee_damage_lower) + meals * 3
	melee_damage_upper = initial(melee_damage_upper) + meals * 3

// Closing burst: while its prey (a locked target, or the person it is patrolling toward) is far away,
// lunge at triple speed to close the gap; slow to normal once within striking range. ChangeMoveToDelay
// updates the actual movespeed - just setting move_to_delay only changes how often the AI issues a step.
/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy/Life()
	. = ..()
	if(!.)
		return
	var/atom/prey = target || HighestPrudenceHuman()
	var/should_rush = (prey && get_dist(src, prey) > 5)
	if(should_rush == rushing)
		return
	rushing = should_rush
	var/new_delay = should_rush ? (initial(move_to_delay) / 3) : initial(move_to_delay)
	move_to_delay = new_delay
	ChangeMoveToDelay(new_delay)

/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy/OpenFire(atom/A)
	if(busy || QDELETED(target))
		return
	INVOKE_ASYNC(src, PROC_REF(TongueLash), target)

/mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy/proc/TongueLash(mob/living/lash_target)
	if(busy || QDELETED(lash_target))
		return
	busy = TRUE
	ranged_cooldown = world.time + ranged_cooldown_time
	face_atom(lash_target)
	var/turf/target_turf = get_ranged_target_turf_direct(src, lash_target, 9)
	var/list/path = list()
	for(var/turf/T in getline(src, target_turf))
		if(!isturf(T) || T.density)
			break
		path += T
		new /obj/effect/temp_visual/telegraphing(T)
	if(!length(path))
		busy = FALSE
		return
	SLEEP_CHECK_DEATH(7.5)	// 0.75s tell before the tongue snaps out
	var/datum/beam/beam = Beam(get_turf(src), "volt_ray")
	var/list/hit = list()
	for(var/turf/T in path)
		if(QDELETED(src))
			break
		beam.target = T
		beam.redrawing()
		for(var/mob/living/L in T)
			if(L == src || (L in hit) || faction_check(L.faction, faction))
				continue
			hit += L
			L.deal_damage(35, BLACK_DAMAGE, source = src, attack_type = ATTACK_TYPE_SPECIAL)
		sleep(1)
	qdel(beam)
	busy = FALSE
