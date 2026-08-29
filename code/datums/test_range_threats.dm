#define ORIGIN_LC13 "Lobotomy Corporation"
#define ORIGIN_B12 "Branch 12"
#define ORIGIN_COL "City of Light"
#define ORIGIN_RCE "R-Corp Expedition"
#define ORIGIN_JOKE "Joke"

#define D_ORIGIN_ABNORMALITY "Abnormality"
#define D_ORIGIN_ORDEAL "Ordeal"
#define D_ORIGIN_QUEST "Quest"
#define D_ORIGIN_COMBATPAGE "Combat Page"

/datum/test_range_threat
	/// If not set manually, will take the name of the mob.
	var/name = "Unknown Threat"
	/// If not set manually, will take the desc of the mob.
	var/desc = "Placeholder description."
	/// Optional, tell players what they should do to defeat this mob.
	var/battle_guide
	/// Unimportant, see the defines above.
	var/origin = ORIGIN_LC13
	/// Unimportant, See the defines above.
	var/origin_detailed = D_ORIGIN_ABNORMALITY
	/// If this is FALSE, this threat won't show up in the Test Range.
	var/enabled = TRUE
	/// Roughly how difficult this threat is. It's subjective, but I personally rate them based on their difficulty with appropiate gear - TSO may be an ALEPH, but you're fighting it with WAW/ALEPH gear, and it's very easy then.
	var/estimated_difficulty = 1

	/// The path to the mob this threat should spawn. If null, this threat is disabled.
	var/mob_path
	/// List of current spawned instances of this threat.
	var/list/currently_spawned = list()
	/// No more than this amount of instances of this threat can exist at the same time.
	var/max_spawns = 15

	// Tuning: this allows you to customize the spawn a little bit... so, for example, you can let players spawn NT at different phases, or give Warden a certain amount of devoured bodies.
	// Requires some overriding of procs to make this work.
	/// What kind of tuning is this? Example: 'Souls' for Warden, 'Player Scaling' for Matriarch, 'Phase' for Nothing There. If null, it has no tuning.
	var/tuning_name
	/// Tuning starts at this value, and cannot go below it.
	var/tuning_min = 0
	/// Tuning cannot go above this value.
	var/tuning_limit = 100


/datum/test_range_threat/New()
	. = ..()
	if(ispath(mob_path, /mob/living))
		var/mob/living/L = mob_path
		if(name == "Unknown Threat")
			name = L.name
		if(desc == "Placeholder description.")
			desc = L.desc

/// Calls PreSpawn to check if we can spawn it; if we can, it calls Spawn then PostSpawn afterwards. The Test Range Threat Simulator will use this proc to spawn mobs.
/datum/test_range_threat/proc/Start(turf/spawnpoint, tuning)
	if(!PreSpawn(spawnpoint, tuning))
		return FALSE
	var/mob/living/L = Spawn(spawnpoint, tuning)
	PostSpawn(L, tuning)
	return TRUE

/// Pre-spawn checks. You can put side effects here too I guess
/datum/test_range_threat/proc/PreSpawn(turf/spawnpoint, tuning)
	if(max_spawns && ((length(currently_spawned) + 1) > max_spawns))
		to_chat(usr, span_warning("Maximum spawns for [src.name] already reached. Despawn or kill one."))
		return FALSE
	return TRUE

/// Must create and return the threat's mob
/datum/test_range_threat/proc/Spawn(turf/spawnpoint, tuning)
	return new mob_path(spawnpoint)

/// Sets important signals and adds the mob to the lists it should be in.
// Always call ..() when overriding this. You'll probably need to override it in some cases that require BreachEffect or similar things.
/datum/test_range_threat/proc/PostSpawn(mob/living/just_spawned, tuning)
	SHOULD_CALL_PARENT(TRUE)

	if(!istype(just_spawned, mob_path))
		return FALSE
	var/mob/living/our_guy = just_spawned
	currently_spawned |= our_guy
	SStestrange.test_range_living_threats |= our_guy
	RegisterSignal(our_guy, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(OnDeath))
	RegisterSignal(our_guy, COMSIG_ENTER_AREA, PROC_REF(AreaCheck))

	// Disable core drops for any Abnormality that spawns.
	if(isabnormalitymob(our_guy))
		var/mob/living/simple_animal/hostile/abnormality/our_abno = our_guy
		our_abno.core_enabled = FALSE

	return our_guy

/datum/test_range_threat/proc/DespawnOne()
	if(length(currently_spawned))
		var/mob/living/L = pick(currently_spawned)
		SStestrange.Despawn(L)
		return TRUE
	return FALSE

/datum/test_range_threat/proc/DespawnAll()
	for(var/mob/living/L in currently_spawned)
		SStestrange.Despawn(L)

/datum/test_range_threat/proc/OnDeath(mob/living/ded)
	SIGNAL_HANDLER
	UnregisterSignal(ded, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING, COMSIG_ENTER_AREA))
	currently_spawned -= ded
	SStestrange.test_range_living_threats -= ded

// Deletes anything that enters an area that isn't the Test Range fighting area.
/datum/test_range_threat/proc/AreaCheck(mob/living/soon_to_be_ded, area/entered_area)
	SIGNAL_HANDLER
	if(istype(entered_area, /area/test_range_arena))
		return
	SStestrange.Despawn(soon_to_be_ded)

/// Subtype for Abnormalities that should have BreachEffect called on them when spawned in the Test Range. Do not include Abnos which cause global effects, etc in their breach.
// NOTE: If BreachEffect sleeps then spawning these threats will also be delayed. Maybe we can invoke async? I dunno, it should be fine
/datum/test_range_threat/breacher
/datum/test_range_threat/breacher/PostSpawn(mob/living/just_spawned, tuning)
	. = ..()
	var/mob/living/simple_animal/hostile/abnormality/breachy_guy = just_spawned
	if(!istype(breachy_guy))
		return
	breachy_guy.BreachEffect()

// ------------------ !!! ORDEALS !!! ------------------
/datum/test_range_threat/peccatulum_sloth_2
	name = "Peccatulum Acediae?"
	battle_guide = "This enemy appears in the Brown Noon Ordeal. It is slow, but able to inflict TREMOR in a wide area. \n\n\
	It has reach-2 autoattacks, and is able to perform a telegraphed leap with an extremely wide AoE, inflicting TREMOR and TREMOR BURST. It is best to bait this leap before attempting to engage. Very weak to BLACK damage."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ORDEAL
	estimated_difficulty = 2

	mob_path = /mob/living/simple_animal/hostile/ordeal/sin_sloth/noon

/datum/test_range_threat/peccatulum_gluttony_2
	name = "Peccatulum Gulae?"
	battle_guide = "This enemy appears in the Brown Noon Ordeal. It is fragile, but fast, and able to devour you. \n\n\
	Its damage output is not particularly high in normal circumstances, but if it manages to devour you, you must quickly deal enough damage to break out, or begin to take ramping damage. Very weak to BLACK damage."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ORDEAL
	estimated_difficulty = 2

	mob_path = /mob/living/simple_animal/hostile/ordeal/sin_gluttony/noon

/datum/test_range_threat/peccatulum_gloom_2
	name = "Peccatulum Morositatis?"
	battle_guide = "This enemy appears in the Brown Noon Ordeal. It is fragile and unable to attack conventionally. \n\n\
	It has only one attack - a telegraphed slam down that creates a large, radial AoE, dealing heavy WHITE damage. Easy to dodge. This enemy can be popped with ranged weapons from a safe distance, or bursted down with RED, BLACK or PALE damage."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ORDEAL
	estimated_difficulty = 1

	mob_path = /mob/living/simple_animal/hostile/ordeal/sin_gloom/noon

/datum/test_range_threat/peccatulum_pride_2
	name = "Peccatulum Superbiae?"
	battle_guide = "This enemy appears in the Brown Noon Ordeal. It is extremely fragile, but fast, and able to deal heavy BLACK damage in a wide area. \n\n\
	It attacks with fast autoattacks, or a telegraphed, extremely wide charge. Do not get hit by it. Any damage but BLACK damage works."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ORDEAL
	estimated_difficulty = 2

	mob_path = /mob/living/simple_animal/hostile/ordeal/sin_pride/noon

/datum/test_range_threat/peccatulum_wrath_2
	name = "Peccatulum Irae?"
	battle_guide = "This enemy appears in the Brown Noon Ordeal. It is fragile, but deals heavy BLACK damage and is also able to inflict BURN. \n\n\
	Attacks by charging then slamming down in an AoE, or with regular auto-attacks. It is best to burst it down with PALE or RED damage, or use a ranged weapon to kite it."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ORDEAL
	estimated_difficulty = 2

	mob_path = /mob/living/simple_animal/hostile/ordeal/sin_wrath/noon

/datum/test_range_threat/peccatulum_lust_2
	name = "Peccatulum Luxuriae?"
	battle_guide = "This enemy appears in the Brown Noon Ordeal. It is slow, but extremely tanky and able to inflict BLEED at range, and knock back on hit. Deals a good amount of RED damage. \n\n\
	Randomly blocks melee and ranged attacks. Frequently uses a telegraphed shotgun-like attack that inflicts BLEED. If you are hit by it, turning on walk-mode will stop you from proccing BLEED. Use PALE or WHITE damage."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ORDEAL
	estimated_difficulty = 3

	mob_path = /mob/living/simple_animal/hostile/ordeal/sin_lust/noon

/* Can't quite add this one, apparently her death causes ALL handmaidens in the world to go enraged. Annoying as hell, I'll look at it later or something idk
/datum/test_range_threat/gold_noon
	name = "Lady of the Lake"
	battle_guide = "This enemy appears in the Gold Noon Ordeal. She has a good amount of health, but is unable to attack conventionally. \n\n\
	Her only two methods of attack are a forward AoE slash, and a radial AoE attack. This latter attack is typically used when surrounded or approaching a target. They are both dodgeable, but deal decent PALE damage if they land. \n\n\
	The Lady of the Lake is often accompanied by Silent Handmaidens that are passive until provoked. It is a good idea to separate them and deal with them individually. These handmaidens deal PALE damage, and apply a debuff that deals additional WHITE damage when you take damage. \n\n\
	Able to block ranged projectiles and melee attacks when she is not winding up an attack. Wait for the right moment to strike if your weapon has a low fire rate or swing speed."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ORDEAL
	estimated_difficulty = 2

	mob_path = /mob/living/simple_animal/hostile/ordeal/white_lake_corrosion
*/

/datum/test_range_threat/matriarch
	name = "Sweeper Matriarch"
	battle_guide = "This enemy appears in the Indigo Midnight Ordeal. She is physically powerful, and can regenerate large amounts of her health by feeding on dead bodies or landing her combat abilities. \n\n\
	The Matriarch begins at Phase 1 and, as she loses health, will progress towards Phase 3. Every time she changes her phase, her maximum health will be reduced to the phase-change threshold - this means she can't heal back up to her original maximum health. \n\n\
	As the Matriarch changes phases, she will lose damage output, but recover more health from her abilities, and attack and move faster, as well as unlock additional combat abilities. \n\n\
	She begins with 3 random offensive skills out of a pool of 5, and each phase unlocks 1 more. The full set of skills is as follows: Dash (Sweep the Backstreets), Slam (Shockwave), Slash (Claw Swipe), Lunge (Trash Disposal) and Parry. \n\n\
	The Matriarch may also summon allied sweepers to her side. Every time she summons them, the cooldown becomes longer - however, it is refreshed every time she changes phase. Amount and power of summoned sweepers decreases as she changes phases. \n\n\
	She also has minor player scaling - the more people that are ready to fight her when the Ordeal begins, the more health she has, and past a certain threshold, she will be able to summon roving packs of Sweepers throughout the facility. \n\n\
	The Matriarch will react with extreme aggression to being shot at by ranged weaponry - shoot her enough times and she will roar, dealing ramping BLACK damage in a colossal, undodgeable AoE, and increasing the amount of Sweepers she can summon. \n\n\
	To beat her, you simply have to not get hit by her abilities, to avoid healing her. Usage of BLACK armour is heavily recommended - PALE and WHITE weapons are best."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ORDEAL
	estimated_difficulty = 5

	mob_path = /mob/living/simple_animal/hostile/ordeal/indigo_midnight/weak
	max_spawns = 2
	tuning_name = "Player Scaling"
	tuning_min = 1
	tuning_limit = 15

/datum/test_range_threat/matriarch/Spawn(turf/spawnpoint, tuning = 1)
	return new mob_path(spawnpoint, tuning)

/datum/test_range_threat/helix
	name = "Helix of the End"
	battle_guide = "This enemy appears in the Green Midnight Ordeal. It is immobile, and unable to attack conventionally, but has one of the largest health pools of any enemy. Weak to BLACK damage. Heavily resists RED damage. \n\n\
	Repeats the same cycle throughout its fight: \n\n\
	1. Prepares, then fires, a large array of laser beams. These have an extremely long range and pierce walls, dealing a ton of BLACK damage for as long as you linger within them. Throughout these beams' active time, lesser lasers will rain down as AoEs. \n\n\
	2. Stores the array of lasers, then, if it isn't at maximum minion capacity, fires drop-pods with Green Noon and Green Dawn allies to support it. \n\n\
	3. Repeat. As the Helix's health lowers, more lasers will be fired and more minions will be summoned. \n\n\
	Since the BLACK damage from this fight is entirely avoidable, it is recommended to armour yourself against the RED damage dealt by the minions spawned by this Ordeal. BLACK damage, especially BLACK AoE damage, is extremely valuable to have."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ORDEAL
	estimated_difficulty = 4

	mob_path = /mob/living/simple_animal/hostile/ordeal/green_midnight
	max_spawns = 1
	tuning_name = "Player Scaling"
	tuning_min = 1
	tuning_limit = 4

/datum/test_range_threat/helix/Spawn(turf/spawnpoint, tuning = 1)
	return new mob_path(spawnpoint, tuning)

// ------------------ !!! QUEST MOBS !!! ------------------
/datum/test_range_threat/sanguine_flame
	name = "Echo Office Fixer: Sanguine Flame"
	battle_guide = "A fixer from the Echo Office. Wields a spear which deals RED damage as well as applying BURN stacks. Weak to PALE damage, heavily resists RED and WHITE. \n\n\
	Able to use several different combat abilities, but they are all pre-empted by him calling them out. The most important one is a PALE-damage counterattacking stance - do not hit it. \n\n\
	This fixer can also fire a slow, homing projectile. If you can manage to crash it into him, it will stagger him, rendering him helpless and vulnerable."
	origin = ORIGIN_COL
	origin_detailed = D_ORIGIN_QUEST // Technically originally a combat page?
	estimated_difficulty = 3

	mob_path = /mob/living/simple_animal/hostile/humanoid/fixer/flame

/datum/test_range_threat/memory_forger
	name = "Echo Office Fixer: Memory Forger"
	battle_guide = "A fixer from the Echo Office. Deals BLACK damage. Weak to PALE damage, heavily resists BLACK and RED. \n\n\
	Has a few distinct combat abilities - his primary means of attack is firing spike projectiles which travel in a straight line and bounce several times. They are piercing, and will deal high damage to you while healing him on contact. \n\n\
	Thus, it is best to fight this enemy while keeping him at a diagonal angle from you, and out of the path of any bouncing projectiles. \n\n\
	Also able to perform a high damage, telegraphed radial AoE attack. \n\n\
	Can spawn statues which heal him - if you manage to get him to hit his statues with the aforementioned AoE attack, it will stagger him, rendering him helpless and vulnerable."
	origin = ORIGIN_COL
	origin_detailed = D_ORIGIN_QUEST // Technically originally a combat page?
	estimated_difficulty = 3

	mob_path = /mob/living/simple_animal/hostile/humanoid/fixer/metal


// add the other echo guys when ender's PR is merged


/* Can't put this in 'cause the bomb it drops deletes turfs entirely.
/datum/test_range_threat/denial_of_concept
	name = "Denial of Concept"
	battle_guide = "A large, immobile machine. It is unable to attack conventionally, but has great firepower regardless. Deals RED damage and is weak to BLACK. Heavily resists RED damage. \n\n\
	Its primary, and most dangerous attack, is a telegraphed minigun barrage. It is nearly impossible to survive without the use of cover, but you are given ample time to flee from it. \n\n\
	It will periodically fire napalm blasts in all cardinal and intercardinal directions, but this has a long cooldown. These napalm blasts leave a lingering fire trail that deals BURN damage and applies BURN stacks. \n\n\
	If you get too close, it will perform a low-damage knockback AoE to push you away. \n\n\
	When fought in its lair, it will summon Dawn of Green enemies to assist it. \n\n\
	YOU ARE HEAVILY ENCOURAGED NOT TO SPAWN THIS IN THE CLASSIC ARENA."
	origin = ORIGIN_COL // Technically also appears in LC13?
	origin_detailed = D_ORIGIN_QUEST
	estimated_difficulty = 4

	mob_path = /mob/living/simple_animal/hostile/ordeal/grungeon_boss
	max_spawns = 1
*/

// ------------------ !!! ABNORMALITIES !!! ------------------

/datum/test_range_threat/breacher/forsaken_murderer
	name = "Forsaken Murderer"
	battle_guide = "A very weak TETH Abnormality, but regardless it is one of the first threats you'll encounter in a Lobotomy Corporation facility that could actually kill you. \n\n\
	Higher level Agents can easily face-tank it, but it can outmatch lower level Agents in melee. It is relatively weak to ranged kiting. \n\n\
	Its attacks deal RED damage and have knockback, so take care it does not knock you into an awkward position."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ABNORMALITY
	estimated_difficulty = 1
	mob_path = /mob/living/simple_animal/hostile/abnormality/forsaken_murderer

/datum/test_range_threat/breacher/redblooded
	name = "Red-Blooded American"
	battle_guide = "A TETH-class Abnormality which is a hybrid melee-ranged fighter, using a shotgun as its weapon to deal RED damage. Fragile as far as Abnormalities go, but has a high damage output for its threat class.\n\n\
	It must reload after firing six shells, but it is not a particularly long reload. It is usually best to try to burst it down quickly with WHITE damage."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ABNORMALITY
	estimated_difficulty = 2
	mob_path = /mob/living/simple_animal/hostile/abnormality/redblooded

/datum/test_range_threat/breacher/pinocchio
	name = "Pinocchio"
	battle_guide = "A HE-class Abnormality which behaves much more like a Murder-insane Agent than an Abnormality or Ordeal. It has a relatively strong WHITE damage weapon, but can swap it out for other, more powerful weapons. \n\n\
	It is immune to stuns, does not slow down from taking damage, and cannot be made to drop its weapon. Despite its meager health pool, it has wiped many facilities due to its ability to make use of powerful E.G.O. gear, and access to regenerators to replenish itself. \n\n\
	Use RED damage, favour ranged weapons, and begin to flee earlier than you usually would when you get low on health - if you become slowed from your injuries, you will be unable to escape Pinocchio."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ABNORMALITY
	estimated_difficulty = 3
	mob_path = /mob/living/simple_animal/hostile/abnormality/pinocchio

/datum/test_range_threat/funeral
	name = "Funeral of the Dead Butterflies"
	battle_guide = "A HE-class Abnormality with unconventional attack patterns. It deals WHITE damage, but will instantly kill anyone insaned by it. \n\n\
	Able to attack with 'finger-guns' which can only be avoided by breaking line-of-sight, or with a coffin which creates a large, lingering, rectangular area of periodic damage in front of it. \n\n\
	Relatively fragile against WHITE and PALE damage - higher level Agents can easily face-tank its attacks, but it is good practice for all Agents to fight Funeral near walls that can help you avoid its finger-guns."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ABNORMALITY
	estimated_difficulty = 2
	mob_path = /mob/living/simple_animal/hostile/abnormality/funeral

/datum/test_range_threat/breacher/scarecrow
	name = "Scarecrow Searching for Wisdom"
	battle_guide = "A HE-class Abnormality that is able to replenish itself from its victims. Deals BLACK damage, and moves and attacks decently quick. It is not a substantial threat unless it is accompanied by other 'Oz' Abnormalities."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ABNORMALITY
	estimated_difficulty = 2
	mob_path = /mob/living/simple_animal/hostile/abnormality/scarecrow

/datum/test_range_threat/blue_shepherd
	name = "Blue Smocked Shepherd"
	battle_guide = "A HE-class Abnormality with the ability to occassionally attack in a large area. Deals steady BLACK damage. Being caught in its wide slash hurts badly, but it is not too much of a threat unless it is accompanied by Reddened Buddy."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ABNORMALITY
	estimated_difficulty = 3
	mob_path = /mob/living/simple_animal/hostile/abnormality/blue_shepherd

/datum/test_range_threat/ebony_queen
	name = "Ebony Queen's Apple"
	battle_guide = "A WAW-class Abnormality that attacks via BLACK-damage roots and thorns. Unlike most Abnormalities, it is unable to deal 'guaranteed' damage - all its attacks are dodgeable. \n\n\
	Stay on the move and avoid using self-stunning weapons. It is weak to WHITE damage, and immune to BLACK damage."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ABNORMALITY
	estimated_difficulty = 3
	mob_path = /mob/living/simple_animal/hostile/abnormality/ebony_queen

/datum/test_range_threat/breacher/judgement_bird
	name = "Judgement Bird"
	battle_guide = "A WAW-class Abnormality with only one attack - a periodic PALE pulse of damage. It has decently high health, but generally weak resistances, and is especially weak to PALE. \n\n\
	The main threat this Abnormality poses are the Runaway Crows that it spawns. It spawns two when it first breaches, and one on every kill it scores (even on non-human mobs). \n\n\
	These crows are pathetic in terms of health, and have low PALE damage, but they knock down their target on each hit, which causes Agents to drop their weapons. This makes them extremely dangerous - ranged weapons are their main counter."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ABNORMALITY
	estimated_difficulty = 3
	mob_path = /mob/living/simple_animal/hostile/abnormality/judgement_bird
	max_spawns = 3 // You're not Him you can't kill 50 runaway crows unless you frame 1 AoE them

/datum/test_range_threat/warden
	name = "The Warden"
	battle_guide = "A WAW-class Abnormality that consumes its victims' souls, becoming faster but dealing less damage overall (only its lower bound lowers - it can still 'crit', in a sense). \n\n\
	Notably, it is immune to projectiles. It is tanky, and deals BLACK damage, but otherwise unremarkable until it is well-fed. WHITE and PALE damage are strong, and if it is too fast to run away from, you should consider shields."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ABNORMALITY
	estimated_difficulty = 3
	mob_path = /mob/living/simple_animal/hostile/abnormality/warden
	tuning_name = "Souls"
	tuning_limit = 4

// Has non-combat-map-tuning.
/datum/test_range_threat/warden/PostSpawn(mob/living/just_spawned, tuning)
	. = ..()
	var/mob/living/simple_animal/hostile/abnormality/warden/our_gal = just_spawned
	var/souls_we_should_have = clamp(tuning, tuning_min, tuning_limit)
	if(souls_we_should_have && souls_we_should_have > 0)
		for(var/i in 1 to souls_we_should_have)
			if(our_gal.move_to_delay > 1)
				our_gal.ChangeMoveToDelayBy(0.75, TRUE)
				if(our_gal.melee_damage_lower > 30)
					our_gal.melee_damage_lower -= our_gal.damage_down

/datum/test_range_threat/nothing_there
	name = "Nothing There"
	battle_guide = "An ALEPH-class Abnormality that evolves if not suppressed quickly, progressing from Phase 1 to an eventual Phase 3. In all its phases, it deals RED damage, and is weakest to PALE. \n\n\
	Its first phase is a simple, quadrupedal form that is only able to perform melee autoattacks. This is when the Abnormality is at its most vulnerable, but after 30-40 seconds, it will fully heal and move to Phase 2. \n\n\
	Phase 2 is an immobile ovoid form. It cannot attack, and becomes invulnerable to RED damage. After 10-25 seconds, it fully heals and moves to Phase 3. \n\n\
	Phase 3 is a bipedal form that has high resistances all around, including invulnerability to RED damage. It gains two attacks - 'Hello' and 'Goodbye', and will also regenerate if not in active combat. \n\n\
	'Hello' is a frequently-used ranged line AoE attack. It is telegraphed by Nothing There kneeling. The windup for this attack is extremely short to the point of being unreactable if you are far from it, but if you are at point-blank range, it is more forgiving. \n\n\
	It is unlikely that you can dodge it if you are not constantly on the move, and it is able to hit around corners. \n\n\
	'Goodbye' is used less frequently, and is telegraphed by Nothing There transforming its arm into a scythe. The windup for this attack is generous, and the AoE of the attack hits a square of radius 2 from Nothing There's position. \n\n\
	It is nearly guaranteed to kill anyone without heavy RED resistance, so avoid being hit at all."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ABNORMALITY
	estimated_difficulty = 4
	mob_path = /mob/living/simple_animal/hostile/abnormality/nothing_there
	max_spawns = 3
	tuning_name = "Phase"
	tuning_min = 1
	tuning_limit = 3

/datum/test_range_threat/nothing_there/PostSpawn(mob/living/just_spawned, tuning = 0)
	. = ..()
	var/mob/living/simple_animal/hostile/abnormality/nothing_there/meat_puppy = just_spawned
	var/phase_we_want = clamp(tuning, tuning_min, tuning_limit)
	switch(phase_we_want)
		if(3)
			meat_puppy.current_stage = 2
			meat_puppy.next_stage()
		if(2)
			meat_puppy.current_stage = 1
			meat_puppy.next_stage()
		else
			meat_puppy.next_transform = world.time + rand(30 SECONDS, 40 SECONDS)

/datum/test_range_threat/silentorchestra
	name = "The Silent Orchestra"
	battle_guide = "An ALEPH-class Abnormality which deals periodic WHITE damage as it progresses through its Movements. It is unable to move or attack conventionally. \n\n\
	Its resistances change as it performs; first, it is immune to all but PALE damage, then to all but BLACK, then WHITE, then RED, and then it becomes invunlerable. \n\n\
	At the end of its performance, it will execute anyone in range who is below 50% of their max Sanity. \n\n\
	As far as ALEPHs go, it is a pushover, so long as you have at least two types of damage and can locate it quickly enough."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ABNORMALITY
	estimated_difficulty = 2
	mob_path = /mob/living/simple_animal/hostile/abnormality/silentorchestra
	max_spawns = 3

/datum/test_range_threat/last_shot
	name = "Til the Last Shot"
	battle_guide = "An ALEPH-class Abnormality which does not move or attack conventionally. Instead, it spreads meat vines and barricades to impede any attempt to reach it, and summons meat soldiers to fight for it. \n\n\
	Meat soldiers use distinct weaponry - assault rifles that fire in bursts, shotguns that fire a spread of bullets, and snipers that fire powerful, telegraphed shots. They all deal RED damage, and both the soldiers and core are weak to BLACK and fatal to PALE. \n\n\
	Wide AoE weaponry is effective against the soldiers, but it is generally best to rush down and kill the vulnerable core of the Abnormality, which will banish all of its influence. Reach weaponry saves time on destroying the final layer of barricades."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ABNORMALITY
	estimated_difficulty = 3
	mob_path = /mob/living/simple_animal/hostile/abnormality/last_shot
	max_spawns = 3

/datum/test_range_threat/distortedform
	name = "Distorted Form"
	battle_guide = "Often considered by Agents as a Super-ALEPH or ALEPH+ Abnormality. Extremely high health. It cycles through many different other Abnormalities as it fights, shapeshifting into them and using their attacks and resistances. \n\n\
	Attempting to leave vision range of Distorted Form will result in it using Ranged Abnormalities, including the ability to breach more Abnormalities in its Siren form. \n\n\
	It also has access to transform into enemies that cannot be fought elsewhere - its 'Halberd Apostle' is a combination of White Night's Spear and Guardian apostles, for example, and it can also transform into a special version of Bloodbath or Price of Silence. \n\n\
	If Distorted Form is engaging multiple targets, it unlocks new attacks in its normal form; a 'spread' attack that places blue markers on all of its targets, and a 'stack' attack that paralyzes a single target and places a large white marker on them. \n\n\
	When faced with the 'spread' attack, do not linger near other people; keep at least 2 tiles of distance from them until you see acid splash down on each of you. \n\n\
	When faced with the 'stack' attack, find the paralyzed person and remain next to them until a beam crashes down on you. If taking the beam alone, it will instantly kill you with high PALE damage, but when it is shared, it deals trivial amounts of damage."
	origin = ORIGIN_LC13
	origin_detailed = D_ORIGIN_ABNORMALITY
	estimated_difficulty = 5
	mob_path = /mob/living/simple_animal/hostile/abnormality/distortedform
	max_spawns = 3


#undef ORIGIN_LC13
#undef ORIGIN_B12
#undef ORIGIN_COL
#undef ORIGIN_RCE
#undef ORIGIN_JOKE

#undef D_ORIGIN_ABNORMALITY
#undef D_ORIGIN_ORDEAL
#undef D_ORIGIN_QUEST
#undef D_ORIGIN_COMBATPAGE
