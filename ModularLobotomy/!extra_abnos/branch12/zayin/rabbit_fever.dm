// Rabbit Fever - a Zayin that multiplies. Each Attachment work spawns another rabbit
// huddled around it (a harmless effect) and raises its max PE by 2, but every
// clone that exists drops all work success by 5%. Doing Repression work while it
// has clones makes the whole brood bolt: the clones scatter across the facility as
// wandering mobs that must be hunted down, and the main body vanishes down a burrow
// - never truly breaching, just sitting inert and unworkable until they are gone.

/mob/living/simple_animal/hostile/abnormality/branch12/rabbit_fever
	name = "Rabbit Fever"
	desc = "A single grey rabbit, or so it looks at a glance. Its eyes track you flatly, and the \
		shadows at its back seem to shift as though there were more of it than there ought to be."
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/32x48.dmi'
	icon_state = "rabbit"
	icon_living = "rabbit"
	icon_dead = "rabbit"
	maxHealth = 600
	health = 600
	threat_level = ZAYIN_LEVEL
	can_breach = FALSE
	start_qliphoth = 2
	melee_damage_lower = 0
	melee_damage_upper = 0
	stat_attack = HARD_CRIT
	del_on_death = FALSE
	faction = list("hostile")
	can_patrol = FALSE
	wander = FALSE
	success_boxes = 99 // Under normal circumstances, impossible
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 65,
		ABNORMALITY_WORK_INSIGHT = 65,
		ABNORMALITY_WORK_ATTACHMENT = 80,
		ABNORMALITY_WORK_REPRESSION = 50,
	)
	max_boxes = 8
	work_damage_amount = 5
	work_damage_type = BLACK_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/lust
	ego_list = list(
		/datum/ego_datum/weapon/branch12/warren,
		/datum/ego_datum/armor/branch12/warren,
	)
	gift_type = /datum/ego_gifts/branch12/warren
	observation_prompt = "The rabbit sits alone in the corner of its unit, watching you. \
		<br>As you step closer, the dark behind it twitches - for just a moment there seem to be \
		a dozen of it, huddled and staring, before there is only the one again."
	observation_choices = list(
		"Reach out to it" = list(TRUE, "You offer your hand. It leans into it, warm and trembling, \
			and for a moment the huddled shapes behind it settle, content to be one."),
		"Keep your distance" = list(FALSE, "You keep back. Its ears flatten, and the shadows at its \
			back multiply and scatter, as if insulted to be kept so few."),
	)

	generic_bubbles = alist(
		1 = list("%PERSON flinches under %ABNO's flat, unblinking stare.", "%PERSON counts the huddle again and gets a different number."),
		2 = list("%PERSON works quickly, unsettled by the huddle pressing close.", "%PERSON tries not to watch the shadows shifting behind %ABNO."),
		3 = list("%PERSON works steadily while %ABNO watches.", "%PERSON keeps half an eye on how many rabbits there are."),
		4 = list("%PERSON works calmly among the rabbits.", "%PERSON pays the staring huddle no mind."),
		5 = list("%PERSON sits easily amid the huddle, unbothered.", "%PERSON lets %ABNO press close without a second thought."),
	)
	work_bubbles = list(
		ABNORMALITY_WORK_INSTINCT = list("%PERSON sets down a handful of greens for the huddle."),
		ABNORMALITY_WORK_INSIGHT = list("%PERSON tries to tally the rabbits and loses count."),
		ABNORMALITY_WORK_ATTACHMENT = list("%PERSON sits quietly beside %ABNO, keeping it company."),
		ABNORMALITY_WORK_REPRESSION = list("%PERSON pens the restless huddle back into its corner."),
	)

	being_tested = TRUE

	/// Harmless clone effects currently huddled around it (each = +2 max PE, -5% work).
	var/list/clone_effects = list()
	/// Wandering clone mobs loosed across the facility. It stays burrowed until these are dead.
	var/list/wandering_clones = list()
	/// TRUE while the brood is loose: shows the burrow and cannot be worked.
	var/released = FALSE
	/// Cap on how large the huddle can get.
	var/max_clones = 10
	/// Spotted body variants a huddled/loosed rabbit picks from.
	var/list/rabbit_variants = list("rabbit", "rabbit1", "rabbit2", "rabbit3")

// -5% work success for each clone huddled around it.
/mob/living/simple_animal/hostile/abnormality/branch12/rabbit_fever/WorkChance(mob/living/carbon/human/user, chance, work_type)
	return max(0, chance - (clone_effects.len * 5))

// Can't be worked while its brood is loose.
/mob/living/simple_animal/hostile/abnormality/branch12/rabbit_fever/AttemptWork(mob/living/carbon/human/user, work_type)
	if(released)
		to_chat(user, span_warning("[src] has fled down its burrow. It cannot be worked until the escaped rabbits are dealt with."))
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/abnormality/branch12/rabbit_fever/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	. = ..()
	if(released)
		return
	if(work_type == ABNORMALITY_WORK_ATTACHMENT)
		AddClone()
	else if(work_type == ABNORMALITY_WORK_REPRESSION && LAZYLEN(clone_effects))
		ReleaseClones()

// Spawn one more huddled rabbit, centred on the body but shoved 16-48px off in each axis.
/mob/living/simple_animal/hostile/abnormality/branch12/rabbit_fever/proc/AddClone()
	if(clone_effects.len >= max_clones)
		return
	var/obj/effect/rabbit_clone/C = new(get_turf(src))
	C.icon_state = pick(rabbit_variants)
	C.pixel_x = pick(-1, 1) * rand(16, 48)
	C.pixel_y = pick(-1, 1) * rand(16, 48)
	C.dir = pick(GLOB.cardinals)
	clone_effects += C
	datum_reference.max_boxes += 2
	visible_message(span_warning("[src] shivers, and another rabbit slinks out to join the huddle."))

// The brood bolts: each huddled clone becomes a wandering mob teleported to its own
// hallway tile (no two share a spot unless the facility runs out of room).
/mob/living/simple_animal/hostile/abnormality/branch12/rabbit_fever/proc/ReleaseClones()
	released = TRUE
	var/list/spawns = GLOB.xeno_spawn.Copy()
	for(var/obj/effect/rabbit_clone/C in clone_effects)
		var/turf/dest = spawns.len ? pick_n_take(spawns) : pick(GLOB.xeno_spawn)
		var/mob/living/simple_animal/hostile/rabbit_wanderer/W = new(dest)
		W.master = src
		W.icon_state = C.icon_state // keep the same spotted variant when it bolts
		W.icon_living = C.icon_state
		wandering_clones += W
		datum_reference.max_boxes -= 2
		clone_effects -= C
		qdel(C)
	icon_state = "burrow"
	update_icon()
	visible_message(span_userdanger("[src] bolts down its burrow, and its brood scatters across the facility!"))

// Called by a wandering clone when it dies; when the last one falls, the body returns.
/mob/living/simple_animal/hostile/abnormality/branch12/rabbit_fever/proc/CloneKilled(mob/clone)
	wandering_clones -= clone
	if(released && !LAZYLEN(wandering_clones))
		Return()

/mob/living/simple_animal/hostile/abnormality/branch12/rabbit_fever/proc/Return()
	released = FALSE
	icon_state = "rabbit"
	update_icon()
	visible_message(span_notice("[src] creeps back up out of its burrow, whole and alone once more."))

/mob/living/simple_animal/hostile/abnormality/branch12/rabbit_fever/update_icon_state()
	if(released)
		icon_state = "burrow"
	else
		icon_state = "rabbit"
	return ..()

/mob/living/simple_animal/hostile/abnormality/branch12/rabbit_fever/Destroy()
	for(var/obj/effect/rabbit_clone/C in clone_effects)
		qdel(C)
	clone_effects = null
	wandering_clones = null
	return ..()

/obj/effect/rabbit_clone
	name = "rabbit"
	desc = "One of the brood, pressed close to its kin."
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/32x48.dmi'
	icon_state = "rabbit"
	anchored = TRUE
	density = FALSE
	layer = BELOW_MOB_LAYER

/mob/living/simple_animal/hostile/rabbit_wanderer
	name = "rabbit"
	desc = "One of the brood, loosed to roam the halls. It bolts from anyone who comes near."
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/32x48.dmi'
	icon_state = "rabbit"
	icon_living = "rabbit"
	icon_dead = "rabbit"
	maxHealth = 60
	health = 60
	move_to_delay = 4
	// Harmless: it never attacks, it only flees and keeps its distance (illusion/escape).
	retreat_distance = 8
	minimum_distance = 8
	melee_damage_lower = 0
	melee_damage_upper = 0
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	faction = list("hostile")
	can_patrol = TRUE
	del_on_death = TRUE
	/// The body it split from; notified on death so it can return once all are dead.
	var/mob/living/simple_animal/hostile/abnormality/branch12/rabbit_fever/master

/mob/living/simple_animal/hostile/rabbit_wanderer/AttackingTarget()
	return FALSE

/mob/living/simple_animal/hostile/rabbit_wanderer/Destroy()
	if(master)
		master.CloneKilled(src)
		master = null
	return ..()

/obj/structure/warren_burrow
	name = "burrow"
	desc = "A dark hole clawed into the ground, just wide enough for a person to vanish into."
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/32x48.dmi'
	icon_state = "burrow"
	anchored = TRUE
	density = FALSE
	layer = BELOW_MOB_LAYER
	/// The weapon that dug this; cleared if the hole is filled in.
	var/obj/item/ego_weapon/support/warren/origin

/obj/structure/warren_burrow/Destroy()
	if(origin && origin.burrow == src)
		origin.burrow = null
	origin = null
	return ..()

// Clods flung up while a burrow is being dug - they erupt, arc, and fall back.
/obj/effect/temp_visual/warren_dirt
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/effects/abnoeffects.dmi'
	icon_state = "clod1"
	duration = 9
	layer = ABOVE_ALL_MOB_LAYER

/obj/effect/temp_visual/warren_dirt/Initialize(mapload)
	. = ..()
	icon_state = "clod[rand(1, 3)]"
	var/dx = rand(-16, 16)                  // thrown outward
	var/peak = rand(10, 20)                 // how high it flies
	var/up = round(duration * 0.45)
	// erupt: rise to the peak, decelerating
	animate(src, pixel_x = dx * 0.5, pixel_y = peak, time = up, easing = SINE_EASING | EASE_OUT)
	// then fall back down, accelerating, fading as it lands
	animate(pixel_x = dx, pixel_y = -2, alpha = 0, time = duration - up, easing = SINE_EASING | EASE_IN)
