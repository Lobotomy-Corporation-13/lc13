// Fragmentum Touched ordeal mobs: base templates.
// Each is a /fragmentum subtype of an ordeal mob with its corrupted icon,
// name and desc. Behaviour is inherited; per-mob combat tweaks come later.
// State names in the fragmentum DMIs match the originals, so only icon is
// overridden (icon_state/living/dead resolve inside the new file).

// Green
/mob/living/simple_animal/hostile/ordeal/green_bot/fragmentum
	name = "fragmentum doubt alpha"
	desc = "A slim robot with a spear in place of its hand, its frame split open by jagged black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_dawn.dmi'

/mob/living/simple_animal/hostile/ordeal/green_bot/syringe/fragmentum
	name = "fragmentum doubt beta"
	desc = "A slim robot with a syringe in place of its hand. Corrosion has fused the needle to a growth of black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_dawn.dmi'

/mob/living/simple_animal/hostile/ordeal/green_bot/fast/fragmentum
	name = "fragmentum doubt gamma"
	desc = "A slim robot with two spears. Crystal bristles from every joint, and it twitches with alien speed."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_dawn.dmi'

/mob/living/simple_animal/hostile/ordeal/green_bot_big/fragmentum
	name = "fragmentum process of understanding"
	desc = "A big robot with a saw and a machine gun in place of its hands, half-swallowed by crystalline corrosion."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_noon.dmi'

/mob/living/simple_animal/hostile/ordeal/green_dusk/fragmentum
	name = "fragmentum where we must reach"
	desc = "A factory-like structure, still birthing ancient robots even as black crystal devours its shell."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_dusk.dmi'
	/// Next world.time the AoE barrage may fire.
	var/barrage_cooldown = 0
	/// Radius of turfs the barrage scatters its markers across.
	var/barrage_range = 7

/mob/living/simple_animal/hostile/ordeal/green_dusk/fragmentum/Life()
	. = ..()
	if(!.)
		return
	if(world.time >= barrage_cooldown)
		barrage_cooldown = world.time + 15 SECONDS
		INVOKE_ASYNC(src, PROC_REF(FragmentumBarrage))

/// Scatters a mix of 1x1 and 3x3 AoE warning markers over random nearby turfs,
/// weighted toward 1x1, spawning them one at a time with a 0.2s gap.
/mob/living/simple_animal/hostile/ordeal/green_dusk/fragmentum/proc/FragmentumBarrage()
	var/list/candidates = list()
	for(var/turf/open/T in RANGE_TURFS(barrage_range, src))
		candidates += T
	if(!length(candidates))
		return
	for(var/i = 1 to rand(9, 14))
		if(stat == DEAD)
			return
		var/turf/T = pick(candidates)
		if(prob(28))
			new /obj/effect/temp_visual/helix_macrolaser(T)
		else
			new /obj/effect/temp_visual/helix_minilaser(T)
		SLEEP_CHECK_DEATH(2)

/mob/living/simple_animal/hostile/ordeal/green_dusk/fragmentum/ProduceRobot()
	var/turf/T = get_step(get_turf(src), pick(0, EAST))
	var/picked_mob = /mob/living/simple_animal/hostile/ordeal/green_bot_big/factory/fragmentum
	if(prob(50))
		picked_mob = pick(
			/mob/living/simple_animal/hostile/ordeal/green_bot/factory/fragmentum,
			/mob/living/simple_animal/hostile/ordeal/green_bot/syringe/factory/fragmentum,
			/mob/living/simple_animal/hostile/ordeal/green_bot/fast/factory/fragmentum,)
	var/mob/living/simple_animal/hostile/ordeal/nb = new picked_mob(T)
	spawned_mobs += nb
	if(ordeal_reference)
		nb.ordeal_reference = ordeal_reference
		ordeal_reference.ordeal_mobs += nb
	RegisterSignal(nb, COMSIG_PARENT_QDELETING, PROC_REF(DelinkRobot))
	return nb

/mob/living/simple_animal/hostile/ordeal/green_dusk/fragmentum/Produce()
	if(producing || stat == DEAD)
		return
	producing = TRUE
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_dusk_create.dmi'
	icon_state = "green_dusk_create"
	SLEEP_CHECK_DEATH(6)
	visible_message(span_danger("\The [src] produces a new set of robots!"))
	for(var/i = 1 to 3)
		ProduceRobot()
		SLEEP_CHECK_DEATH(1)
	SLEEP_CHECK_DEATH(2)
	icon = initial(icon)
	producing = FALSE
	spawn_progress = -5
	update_icon()

// Fragmentum factory-spawn variants (corrupted icon + self-cleaning corpse)
/mob/living/simple_animal/hostile/ordeal/green_bot/factory/fragmentum
	name = "fragmentum doubt alpha"
	desc = "A slim robot with a spear in place of its hand, its frame split open by jagged black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_dawn.dmi'

/mob/living/simple_animal/hostile/ordeal/green_bot/syringe/factory/fragmentum
	name = "fragmentum doubt beta"
	desc = "A slim robot with a syringe in place of its hand. Corrosion has fused the needle to a growth of black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_dawn.dmi'

/mob/living/simple_animal/hostile/ordeal/green_bot/fast/factory/fragmentum
	name = "fragmentum doubt gamma"
	desc = "A slim robot with two spears. Crystal bristles from every joint, and it twitches with alien speed."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_dawn.dmi'

/mob/living/simple_animal/hostile/ordeal/green_bot_big/factory/fragmentum
	name = "fragmentum process of understanding"
	desc = "A big robot with a saw and a machine gun in place of its hands, half-swallowed by crystalline corrosion."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_noon.dmi'

// Crimson
/obj/projectile/fragmentum_dodgeball
	name = "corroded circus ball"
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "dodgeball"
	damage = 12
	damage_type = WHITE_DAMAGE
	speed = 1
	range = 12

// The dawn clown drops its console-sabotage act and becomes a skittish ranged
// kiter: it keeps its distance and pelts targets with WHITE-damage dodgeballs.
/mob/living/simple_animal/hostile/ordeal/crimson_clown/fragmentum
	name = "fragmentum cheers for the start"
	desc = "A tiny humanoid in jester's attire, its grin frozen and its body studded with black crystal shards."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_crimson_dawn.dmi'
	search_objects = 0
	wanted_objects = list()
	ranged = TRUE
	retreat_distance = 5
	minimum_distance = 6
	ranged_cooldown_time = 20
	projectiletype = /obj/projectile/fragmentum_dodgeball
	projectilesound = 'sound/effects/ordeals/crimson/ball.ogg'
	melee_damage_lower = 8
	melee_damage_upper = 12

/// No-op: this variant hunts agents instead of teleporting to consoles.
/mob/living/simple_animal/hostile/ordeal/crimson_clown/fragmentum/TeleportAway()
	return

/// Parent only allows attacking consoles; retarget onto living enemies.
/mob/living/simple_animal/hostile/ordeal/crimson_clown/fragmentum/CanAttack(atom/the_target)
	if(QDELETED(the_target) || isturf(the_target) || !isliving(the_target))
		return FALSE
	var/mob/living/L = the_target
	if(L.status_flags & GODMODE)
		return FALSE
	if(L.stat > stat_attack)
		return FALSE
	if(faction_check_mob(L) && !attack_same)
		return FALSE
	return TRUE

/mob/living/simple_animal/hostile/ordeal/crimson_noon/fragmentum
	name = "fragmentum harmony of skin"
	desc = "A large clown-like creature with 3 heads full of red tumors, now sprouting crystal spines between the growths."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_crimson_noon.dmi'
	clown_derivitive = /mob/living/simple_animal/hostile/ordeal/crimson_clown/fragmentum

/mob/living/simple_animal/hostile/ordeal/crimson_noon/crimson_dusk/fragmentum
	name = "fragmentum struggle of the peak"
	desc = "A round clown amalgamation holding a hammer and an axe, its flesh cracked open by veins of glowing corrosion."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_crimson_dusk.dmi'
	clown_derivitive = /mob/living/simple_animal/hostile/ordeal/crimson_noon/fragmentum

// Amber
/mob/living/simple_animal/hostile/ordeal/amber_bug/fragmentum
	name = "fragmentum complete food"
	desc = "A tiny worm-like creature with tough chitin and a pair of sharp claws, its shell overgrown with black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_amber_dawn.dmi'

/mob/living/simple_animal/hostile/ordeal/amber_dusk/fragmentum
	name = "fragmentum food chain"
	desc = "A big worm-like creature with jagged teeth. Black crystal erupts along its back where its segments used to be."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_amber_dusk.dmi'

// Indigo
/mob/living/simple_animal/hostile/ordeal/indigo_dawn/fragmentum
	name = "fragmentum unknown scout"
	desc = "A tall humanoid with a walking cane, its indigo armor pierced through by shards of black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_48.dmi'

/mob/living/simple_animal/hostile/ordeal/indigo_dawn/invis/fragmentum
	name = "fragmentum unknown scout"
	desc = "A tall humanoid with a walking cane, its indigo armor pierced through by shards of black crystal. It barely seems to be there."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_48.dmi'

/mob/living/simple_animal/hostile/ordeal/indigo_dawn/skirmisher/fragmentum
	name = "fragmentum unknown scout"
	desc = "A tall humanoid with a walking cane, its indigo armor pierced through by shards of black crystal. This one keeps its distance."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_48.dmi'

/mob/living/simple_animal/hostile/ordeal/indigo_noon/fragmentum
	name = "fragmentum sweeper"
	desc = "A humanoid in metallic armor with bloodied hooks. Crystalline corrosion has grafted itself to the hooks and helm."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_32.dmi'

/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky/fragmentum
	name = "fragmentum sweeper"
	desc = "A humanoid in metallic armor with bloodied hooks. Slabs of black crystal have thickened its bulk; it won't go down easy."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_32.dmi'

/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky/fragmentum
	name = "fragmentum sweeper"
	desc = "A humanoid in metallic armor with bloodied hooks. Thin crystal spines lace its limbs, and it moves with unnatural agility."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_48.dmi'

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/fragmentum
	name = "\proper Fragmentum Commander Jacques"
	desc = "A tall humanoid with red claws dripping blood, black crystal splitting the skin of his arms."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_32.dmi'

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale/fragmentum
	name = "\proper Fragmentum Commander Silvina"
	desc = "A tall humanoid with glowing pale fists, now ringed with jagged corrosion crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_32.dmi'

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white/fragmentum
	name = "\proper Fragmentum Commander Adelheide"
	desc = "A tall humanoid with a white greatsword, its edge fused to a growth of black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_32.dmi'

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black/fragmentum
	name = "\proper Fragmentum Commander Maria"
	desc = "A tall humanoid with a large black hammer, crystalline corrosion crawling up the haft."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_32.dmi'

// Steel
/mob/living/simple_animal/hostile/ordeal/steel_dawn/fragmentum
	name = "fragmentum gene corp remnant"
	desc = "An insect-augmented Gene corp remnant, its carapace shattered and regrown as black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_steel_32.dmi'

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/fragmentum
	name = "fragmentum gene corp corporal"
	desc = "A heavily mutated employee with two sharp insectoid arms, now barbed with fragmentum crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_steel_32.dmi'

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying/fragmentum
	name = "fragmentum gene corp arial scout"
	desc = "A winged, mutated employee with long insectoid arms. Corrosion crystal weighs down its ragged wings."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_steel_32.dmi'

/mob/living/simple_animal/hostile/ordeal/steel_dawn/medic/fragmentum
	name = "fragmentum gene corp corpsmen"
	desc = "An insect-augmented employee clutching a scavenged dufflebag, its body knotted with black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_steel_32.dmi'

/mob/living/simple_animal/hostile/ordeal/steel_dusk/fragmentum
	name = "fragmentum gene corp manager"
	desc = "A bug-headed Gene corp manager. Fragmentum crystal twists its shrieking sonics into something that warps the air."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_steel_48.dmi'

// Violet
/mob/living/simple_animal/hostile/ordeal/violet_fruit/fragmentum
	name = "fragmentum fruit of understanding"
	desc = "A round purple creature leaking mind-damaging gas, its rind cracked open by black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_violet_dawn.dmi'

/mob/living/simple_animal/hostile/ordeal/violet_monolith/fragmentum
	name = "fragmentum grant us love"
	desc = "A dark monolith covered in incomprehensible writing, the script now bleeding gold light through crystalline fractures."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_violet_noon.dmi'

// Brown (Seven Sins)
/mob/living/simple_animal/hostile/ordeal/sin_sloth/fragmentum
	name = "Fragmentum Peccatulum Acediae"
	desc = "It resembles a rock, one split open to reveal a core of black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_32.dmi'

/mob/living/simple_animal/hostile/ordeal/sin_gluttony/fragmentum
	name = "Fragmentum Peccatulum Gulae"
	desc = "These plants gnash and gnaw like a rabid beast, their maws lined with corrosion crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_32.dmi'

/mob/living/simple_animal/hostile/ordeal/sin_gloom/fragmentum
	name = "Fragmentum Peccatulum Morositatis"
	desc = "An insect-like entity with a transparent body, black crystal suspended inside it like frozen rot."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_48.dmi'

/mob/living/simple_animal/hostile/ordeal/sin_pride/fragmentum
	name = "Fragmentum Peccatulum Superbiae"
	desc = "Those spikes look sharp, and half of them are now jagged fragmentum crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_48.dmi'

/mob/living/simple_animal/hostile/ordeal/sin_wrath/fragmentum
	name = "Fragmentum Peccatulum Irae"
	desc = "A dried tentacle full of glowing red liquid, its length crusted over with black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_48.dmi'

/mob/living/simple_animal/hostile/ordeal/sin_lust/fragmentum
	name = "Fragmentum Peccatulum Luxuriae"
	desc = "A creature of fleshy lumps, eager to devour, its rolls split by veins of corrosion."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_lust.dmi'

/mob/living/simple_animal/hostile/ordeal/sin_sloth/noon/fragmentum
	name = "Fragmentum Peccatulum Acediae?"
	desc = "Now the rock has more rocks, and every one of them weeps black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_noon.dmi'

/mob/living/simple_animal/hostile/ordeal/sin_gluttony/noon/fragmentum
	name = "Fragmentum Peccatulum Gulae?"
	desc = "Giant, hungry flowers. Is that blood, or corrosion seeping through the crystal?"
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_noon.dmi'

/mob/living/simple_animal/hostile/ordeal/sin_gloom/noon/fragmentum
	name = "Fragmentum Peccatulum Morositatis?"
	desc = "A large translucent monster full of organs, throwing its crystal-laden weight around like a hammer."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_noon.dmi'

/mob/living/simple_animal/hostile/ordeal/sin_pride/noon/fragmentum
	name = "Fragmentum Peccatulum Superbiae?"
	desc = "A spiky wheel with clawed hands, its rim overgrown into a ring of black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_noon.dmi'

/mob/living/simple_animal/hostile/ordeal/sin_wrath/noon/fragmentum
	name = "Fragmentum Peccatulum Irae?"
	desc = "A far bigger tentacle peccatula with a tail, corrosion crystal bursting from every seam."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_noon.dmi'

/mob/living/simple_animal/hostile/ordeal/sin_lust/noon/fragmentum
	name = "Fragmentum Peccatulum Luxuriae?"
	desc = "It holds its face up like a shield. The soft, rotten flesh is threaded with black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_noon.dmi'

// Gold (Corrosion)
/mob/living/simple_animal/hostile/ordeal/fallen_amurdad_corrosion/fragmentum
	name = "Fragmentum Fallen Nepenthes"
	desc = "A level 1 Lobotomy Corporation agent, corrupted by an abnormality and then claimed again by Fragmentum crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_gold_48.dmi'

/mob/living/simple_animal/hostile/ordeal/beanstalk_corrosion/fragmentum
	name = "Fragmentum Beanstalk Searching for Jack"
	desc = "A Lobotomy Corporation clerk corrupted by an abnormality, its stalk now sheathed in black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_gold_32x48.dmi'

/mob/living/simple_animal/hostile/ordeal/white_lake_corrosion/fragmentum
	name = "Fragmentum Lady of the Lake"
	desc = "An agent captain of central command, corrupted by an abnormality. Corrosion crystal has claimed what was left of her. But how?"
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_gold_32x64.dmi'

/mob/living/simple_animal/hostile/ordeal/silentgirl_corrosion/fragmentum
	name = "Fragmentum Silent Handmaiden"
	desc = "A level 2 Lobotomy Corporation agent corrupted by an abnormality, her silence now edged with black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_gold_32.dmi'

/mob/living/simple_animal/hostile/ordeal/centipede_corrosion/fragmentum
	name = "Fragmentum High-Voltage Centipede"
	desc = "An information team agent corrupted by an abnormality, its charge arcing across crystalline growths. But how?"
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_gold_64x48.dmi'

/mob/living/simple_animal/hostile/ordeal/thunderbird_corrosion/fragmentum
	name = "Fragmentum Thunder Warrior"
	desc = "A disciplinary team agent corrupted by an abnormality, black crystal crackling along its frame. But how?"
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_gold_32x48.dmi'

/mob/living/simple_animal/hostile/ordeal/thunderbird_corrosion_boss/fragmentum
	name = "Fragmentum Thunder Chieftain"
	desc = "A disciplinary officer, heavily corrupted by an abnormality and studded through with fragmentum crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_gold_64.dmi'

/mob/living/simple_animal/hostile/ordeal/KHz_corrosion/fragmentum
	name = "Fragmentum 680 Ham Actor"
	desc = "A control team agent corrupted by an abnormality, its every gesture punctuated by jutting black crystal. But how?"
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_gold_32.dmi'
