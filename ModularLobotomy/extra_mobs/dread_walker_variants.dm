/// Dread Walker Variants - Different forms of the unseen horror with unique attacks
/// All attacks respect the visibility system - only marked humans can perceive them

// ==================== FORGOTTEN WALKER ====================
/// A fading presence that drains memories and consciousness
/mob/living/simple_animal/hostile/dread_walker/forgotten
	name = "Forgotten Walker"
	desc = "A presence that seems to fade from memory even as you look at it..."
	icon = 'icons/mob/animal.dmi'
	icon_state = "forgotten"
	icon_living = "forgotten"
	icon_dead = "forgotten"

	health = 600
	maxHealth = 600
	melee_damage_lower = 12
	melee_damage_upper = 18
	melee_damage_type = WHITE_DAMAGE
	move_to_delay = 6

	attack_verb_continuous = "drains"
	attack_verb_simple = "drain"
	attack_sound = 'sound/hallucinations/whispers.ogg'

	/// Cooldown for memory drain attack
	var/memory_drain_cooldown = 0
	var/memory_drain_cooldown_time = 8 SECONDS

	var/list/forgotten_phrases = list(
		"...forgotten...",
		"...fading...",
		"...who were you...",
		"...memories dissolve...",
		"...erasing..."
	)

/mob/living/simple_animal/hostile/dread_walker/forgotten/Initialize()
	. = ..()
	patrol_phrases = forgotten_phrases
	stalking_phrases = list(
		"...I remember you...",
		"...your name fades...",
		"...soon forgotten...",
		"...like you never existed..."
	)

/mob/living/simple_animal/hostile/dread_walker/forgotten/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		TryMemoryDrain(target)

/// Attempt to drain memories from target
/mob/living/simple_animal/hostile/dread_walker/forgotten/proc/TryMemoryDrain(mob/living/carbon/human/victim)
	if(memory_drain_cooldown > world.time)
		return
	if(!prob(30))
		return

	memory_drain_cooldown = world.time + memory_drain_cooldown_time

	MarkedPlaysound(get_turf(src), 'sound/hallucinations/im_here1.ogg', 40, TRUE)

	// White flash overlay for victim only - use victim's icon for silhouette effect
	var/image/flash = image(victim.icon, victim, victim.icon_state, ABOVE_MOB_LAYER)
	flash.alpha = 200
	flash.color = "#ffffff"
	if(victim.client)
		victim.client.images += flash
		animate(flash, alpha = 0, time = 10)
		addtimer(CALLBACK(src, PROC_REF(CleanupVictimImage), flash, victim), 10)

	victim.adjustSanityLoss(25)
	victim.add_confusion(2 SECONDS)
	victim.hallucination += 30
	to_chat(victim, span_warning("Your memories blur as something feeds upon them..."))

/// Clean up a victim-specific image
/mob/living/simple_animal/hostile/dread_walker/forgotten/proc/CleanupVictimImage(image/I, mob/living/carbon/human/victim)
	if(victim?.client)
		victim.client.images -= I

// ==================== OTHERTHING WALKER ====================
/// A brutish, aggressive creature that rends flesh
/mob/living/simple_animal/hostile/dread_walker/otherthing
	name = "Otherthing Walker"
	desc = "A twisted mass of limbs and hunger..."
	icon = 'icons/mob/animal.dmi'
	icon_state = "otherthing"
	icon_living = "otherthing"
	icon_dead = "otherthing"

	health = 900
	maxHealth = 900
	melee_damage_lower = 20
	melee_damage_upper = 30
	melee_damage_type = RED_DAMAGE
	move_to_delay = 4

	attack_verb_continuous = "rends"
	attack_verb_simple = "rend"
	attack_sound = 'sound/weapons/slash.ogg'

	/// Whether currently in frenzy mode
	var/frenzied = FALSE
	/// Cooldown for frenzy
	var/frenzy_cooldown = 0
	var/frenzy_cooldown_time = 30 SECONDS
	/// Original move delay before frenzy
	var/original_move_delay = 4
	/// Aura image shown during frenzy
	var/image/frenzy_aura = null

	var/list/otherthing_phrases = list(
		"...hunger...",
		"...rend...",
		"...flesh...",
		"...consume..."
	)

/mob/living/simple_animal/hostile/dread_walker/otherthing/Initialize()
	. = ..()
	original_move_delay = move_to_delay
	patrol_phrases = otherthing_phrases
	stalking_phrases = list(
		"...found prey...",
		"...your flesh...",
		"...soon...",
		"...mine..."
	)

/mob/living/simple_animal/hostile/dread_walker/otherthing/Life()
	. = ..()
	if(!.)
		return

	// Check for frenzy trigger
	if(!frenzied && health < maxHealth * 0.5)
		EnterFrenzy()

/// Enter frenzy mode when below 50% health
/mob/living/simple_animal/hostile/dread_walker/otherthing/proc/EnterFrenzy()
	if(frenzied || frenzy_cooldown > world.time)
		return

	frenzied = TRUE
	move_to_delay = 2
	rapid_melee = 3
	melee_damage_lower += 5
	melee_damage_upper += 10

	MarkedPlaysound(get_turf(src), 'sound/voice/growl1.ogg', 60, TRUE)
	MarkedVisibleMessage(span_danger("[src] enters a frenzied rage, its form blurring with violence!"))

	// Create red aura for marked viewers - use our own icon for silhouette
	frenzy_aura = image(icon, src, icon_state, ABOVE_MOB_LAYER)
	frenzy_aura.color = "#ff0000"
	frenzy_aura.alpha = 100
	for(var/mob/living/carbon/human/H in GLOB.dread_marked_humans)
		if(H.client)
			H.client.images += frenzy_aura

	addtimer(CALLBACK(src, PROC_REF(EndFrenzy)), 10 SECONDS)

/// End frenzy mode
/mob/living/simple_animal/hostile/dread_walker/otherthing/proc/EndFrenzy()
	frenzied = FALSE
	frenzy_cooldown = world.time + frenzy_cooldown_time
	move_to_delay = original_move_delay
	rapid_melee = 1
	melee_damage_lower -= 5
	melee_damage_upper -= 10

	// Clean up aura
	if(frenzy_aura)
		for(var/mob/living/carbon/human/H in GLOB.dread_marked_humans)
			if(H.client)
				H.client.images -= frenzy_aura
		frenzy_aura = null

	MarkedVisibleMessage(span_notice("[src]'s frenzy subsides..."))

/mob/living/simple_animal/hostile/dread_walker/otherthing/AttackingTarget()
	. = ..()
	if(. && frenzied && ishuman(target))
		// Extra blood effect during frenzy
		var/mob/living/carbon/human/H = target
		MarkedVisualEffect(get_turf(H), 'icons/effects/blood.dmi', "splatter1", 8)

// ==================== MORPH WALKER ====================
/// A shapeshifting horror that confuses and disorients
/mob/living/simple_animal/hostile/dread_walker/morph
	name = "Morph Walker"
	desc = "Its form shifts and changes, never quite the same..."
	icon = 'icons/mob/animal.dmi'
	icon_state = "morph"
	icon_living = "morph"
	icon_dead = "morph"

	health = 700
	maxHealth = 700
	melee_damage_lower = 15
	melee_damage_upper = 22
	melee_damage_type = BLACK_DAMAGE
	move_to_delay = 5

	attack_verb_continuous = "corrupts"
	attack_verb_simple = "corrupt"
	attack_sound = 'sound/effects/blobattack.ogg'

	/// Cooldown for shifting form
	var/shift_cooldown = 0
	var/shift_cooldown_time = 12 SECONDS

	var/list/morph_phrases = list(
		"...changing...",
		"...shifting...",
		"...what am I...",
		"...becoming..."
	)

/mob/living/simple_animal/hostile/dread_walker/morph/Initialize()
	. = ..()
	patrol_phrases = morph_phrases
	stalking_phrases = list(
		"...I could be you...",
		"...your face...",
		"...wearing your skin...",
		"...becoming you..."
	)

/mob/living/simple_animal/hostile/dread_walker/morph/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		TryShiftingForm()

/// Attempt to teleport and leave a decoy
/mob/living/simple_animal/hostile/dread_walker/morph/proc/TryShiftingForm()
	if(shift_cooldown > world.time)
		return
	if(!prob(25))
		return

	shift_cooldown = world.time + shift_cooldown_time

	var/turf/old_loc = get_turf(src)
	var/list/valid_turfs = list()
	for(var/turf/T in range(4, src))
		if(!T.density && !DensityCheck(T))
			valid_turfs += T

	if(!valid_turfs.len)
		return

	var/turf/new_loc = pick(valid_turfs)

	// Create decoy image at old location for marked humans
	var/image/decoy = image(icon, old_loc, icon_state, layer)
	decoy.alpha = 180
	for(var/mob/living/carbon/human/H in GLOB.dread_marked_humans)
		if(H.client)
			H.client.images += decoy

	MarkedPlaysound(old_loc, 'sound/effects/blobattack.ogg', 40, TRUE)
	forceMove(new_loc)
	UpdateImages()

	// Cause hallucinations to nearby marked humans from the disorienting shift
	for(var/mob/living/carbon/human/H in view(5, old_loc))
		if(H in GLOB.dread_marked_humans)
			H.hallucination += 40
			to_chat(H, span_warning("Reality warps as the creature shifts..."))

	// Fade out decoy
	animate(decoy, alpha = 0, time = 30)
	addtimer(CALLBACK(src, PROC_REF(CleanupDecoy), decoy), 30)

/// Clean up decoy image
/mob/living/simple_animal/hostile/dread_walker/morph/proc/CleanupDecoy(image/decoy)
	for(var/mob/living/carbon/human/H in GLOB.dread_marked_humans)
		if(H.client)
			H.client.images -= decoy

// ==================== RAW PROPHET WALKER ====================
/// A visionary horror that inflicts terrifying prophecies
/mob/living/simple_animal/hostile/dread_walker/raw_prophet
	name = "Prophet Walker"
	desc = "Eyes that have seen too much, now forcing visions upon others..."
	icon = 'icons/mob/eldritch_mobs.dmi'
	icon_state = "raw_prophet"
	icon_living = "raw_prophet"
	icon_dead = "raw_prophet"

	health = 500
	maxHealth = 500
	melee_damage_lower = 10
	melee_damage_upper = 15
	melee_damage_type = WHITE_DAMAGE
	move_to_delay = 7

	attack_verb_continuous = "touches"
	attack_verb_simple = "touch"
	attack_sound = 'sound/hallucinations/whispers.ogg'

	// Ranged attack capability
	ranged = TRUE
	ranged_cooldown_time = 6 SECONDS
	projectiletype = null // We use custom vision attack instead

	/// Cooldown for prophetic vision
	var/vision_cooldown = 0
	var/vision_cooldown_time = 15 SECONDS

	var/list/prophet_phrases = list(
		"...I have seen...",
		"...the end...",
		"...it comes...",
		"...inevitable..."
	)

/mob/living/simple_animal/hostile/dread_walker/raw_prophet/Initialize()
	. = ..()
	patrol_phrases = prophet_phrases
	stalking_phrases = list(
		"...I see your death...",
		"...it is written...",
		"...no escape...",
		"...your fate..."
	)

/mob/living/simple_animal/hostile/dread_walker/raw_prophet/OpenFire(atom/A)
	if(!ishuman(A))
		return
	PropheticVision(A)

/// Inflict a prophetic vision on the target
/mob/living/simple_animal/hostile/dread_walker/raw_prophet/proc/PropheticVision(mob/living/carbon/human/victim)
	if(!victim || vision_cooldown > world.time)
		return

	vision_cooldown = world.time + vision_cooldown_time
	ranged_cooldown = world.time + ranged_cooldown_time

	to_chat(victim, span_userdanger("You see glimpses of horrors yet to come..."))
	victim.playsound_local(get_turf(victim), 'sound/hallucinations/growl1.ogg', 50, TRUE)

	MarkedVisibleMessage(span_danger("[src] fixes its gaze upon [victim]!"))

	// Create vision effect on victim - purple silhouette
	var/image/vision = image(victim.icon, victim, victim.icon_state, ABOVE_MOB_LAYER)
	vision.color = "#8800ff"
	vision.alpha = 200
	if(victim.client)
		victim.client.images += vision
		animate(vision, alpha = 0, time = 20)
		addtimer(CALLBACK(src, PROC_REF(CleanupVisionImage), vision, victim), 20)

	// Deal WHITE damage based on current sanity
	var/damage = 20 + max(0, (100 - victim.sanityhealth) * 0.3)
	victim.adjustSanityLoss(damage)

	// Cause brief hallucination effect
	victim.hallucination += 50

/// Clean up vision image
/mob/living/simple_animal/hostile/dread_walker/raw_prophet/proc/CleanupVisionImage(image/I, mob/living/carbon/human/victim)
	if(victim?.client)
		victim.client.images -= I

// ==================== STALKER WALKER ====================
/// A predatory hunter that drains life force
/mob/living/simple_animal/hostile/dread_walker/stalker
	name = "Stalker Walker"
	desc = "A patient predator that feeds on the life force of its prey..."
	icon = 'icons/mob/eldritch_mobs.dmi'
	icon_state = "stalker"
	icon_living = "stalker"
	icon_dead = "stalker"

	health = 750
	maxHealth = 750
	melee_damage_lower = 18
	melee_damage_upper = 25
	melee_damage_type = PALE_DAMAGE
	move_to_delay = 4

	attack_verb_continuous = "drains"
	attack_verb_simple = "drain"
	attack_sound = 'sound/effects/ghost.ogg'

	var/list/stalker_phrases = list(
		"...hunting...",
		"...patient...",
		"...following...",
		"...prey..."
	)

/mob/living/simple_animal/hostile/dread_walker/stalker/Initialize()
	. = ..()
	patrol_phrases = stalker_phrases
	stalking_phrases = list(
		"...your life...",
		"...I hunger...",
		"...give me warmth...",
		"...so cold..."
	)

/mob/living/simple_animal/hostile/dread_walker/stalker/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		LifeSiphon(target)

/// Siphon life from the target
/mob/living/simple_animal/hostile/dread_walker/stalker/proc/LifeSiphon(mob/living/carbon/human/victim)
	var/healed = min(melee_damage_upper * 0.5, maxHealth - health)
	if(healed <= 0)
		return

	adjustBruteLoss(-healed)

	// Create siphon visual effect - pale silhouette on victim
	var/image/siphon = image(victim.icon, victim, victim.icon_state, ABOVE_MOB_LAYER)
	siphon.color = "#ccccff"
	siphon.alpha = 150

	for(var/mob/living/carbon/human/H in GLOB.dread_marked_humans)
		if(H.client)
			H.client.images += siphon

	animate(siphon, alpha = 0, time = 8)
	addtimer(CALLBACK(src, PROC_REF(CleanupSiphon), siphon), 8)

	victim.playsound_local(get_turf(victim), 'sound/effects/ghost.ogg', 30, TRUE)
	to_chat(victim, span_warning("You feel your life force being drained away..."))

	// Life drain causes fleeting visions
	if(prob(40))
		victim.hallucination += 25

/// Clean up siphon effect
/mob/living/simple_animal/hostile/dread_walker/stalker/proc/CleanupSiphon(image/I)
	for(var/mob/living/carbon/human/H in GLOB.dread_marked_humans)
		if(H.client)
			H.client.images -= I

// ==================== ASH WALKER ====================
/// A burning specter that leaves scorched earth
/mob/living/simple_animal/hostile/dread_walker/ash_walker
	name = "Ash Walker"
	desc = "Smoldering embers trail in its wake, burning without light..."
	icon = 'icons/mob/eldritch_mobs.dmi'
	icon_state = "ash_walker"
	icon_living = "ash_walker"
	icon_dead = "ash_walker"

	health = 850
	maxHealth = 850
	melee_damage_lower = 22
	melee_damage_upper = 28
	melee_damage_type = RED_DAMAGE
	move_to_delay = 4

	attack_verb_continuous = "burns"
	attack_verb_simple = "burn"
	attack_sound = 'sound/items/welder.ogg'

	/// Cooldown for ash cloud
	var/ash_cloud_cooldown = 0
	var/ash_cloud_cooldown_time = 15 SECONDS
	/// Active cloud turfs and images
	var/list/cloud_turfs = list()
	var/list/cloud_images = list()

	var/list/ash_phrases = list(
		"...burning...",
		"...ash to ash...",
		"...smoldering...",
		"...consumed..."
	)

/mob/living/simple_animal/hostile/dread_walker/ash_walker/Initialize()
	. = ..()
	patrol_phrases = ash_phrases
	stalking_phrases = list(
		"...burn with me...",
		"...your warmth...",
		"...into cinders...",
		"...nothing remains..."
	)

/mob/living/simple_animal/hostile/dread_walker/ash_walker/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		SmolderingStrike(target)
		TryAshCloud()

/// Apply smoldering effect to target
/mob/living/simple_animal/hostile/dread_walker/ash_walker/proc/SmolderingStrike(mob/living/carbon/human/victim)
	// Create fake fire overlay visible only to marked humans - orange silhouette
	var/image/fire = image(victim.icon, victim, victim.icon_state, ABOVE_MOB_LAYER)
	fire.color = "#ff4400"
	fire.alpha = 150

	for(var/mob/living/carbon/human/H in GLOB.dread_marked_humans)
		if(H.client)
			H.client.images += fire

	animate(fire, alpha = 0, time = 50)
	addtimer(CALLBACK(src, PROC_REF(CleanupFireImage), fire), 50)

	victim.playsound_local(get_turf(victim), 'sound/items/welder.ogg', 40, TRUE)
	to_chat(victim, span_danger("Invisible flames scorch your flesh!"))

	// Deal burn damage over time
	addtimer(CALLBACK(src, PROC_REF(BurnTick), victim, 1), 10)
	addtimer(CALLBACK(src, PROC_REF(BurnTick), victim, 2), 20)
	addtimer(CALLBACK(src, PROC_REF(BurnTick), victim, 3), 30)

/// Apply burn damage tick
/mob/living/simple_animal/hostile/dread_walker/ash_walker/proc/BurnTick(mob/living/carbon/human/victim, tick)
	if(QDELETED(victim) || victim.stat == DEAD)
		return
	victim.deal_damage(5, RED_DAMAGE, src)
	if(tick == 3)
		to_chat(victim, span_notice("The phantom flames finally fade..."))

/// Clean up fire image
/mob/living/simple_animal/hostile/dread_walker/ash_walker/proc/CleanupFireImage(image/I)
	for(var/mob/living/carbon/human/H in GLOB.dread_marked_humans)
		if(H.client)
			H.client.images -= I

/// Try to create an ash cloud
/mob/living/simple_animal/hostile/dread_walker/ash_walker/proc/TryAshCloud()
	if(ash_cloud_cooldown > world.time)
		return
	if(!prob(20))
		return

	ash_cloud_cooldown = world.time + ash_cloud_cooldown_time
	CreateAshCloud()

/// Create ash cloud around self
/mob/living/simple_animal/hostile/dread_walker/ash_walker/proc/CreateAshCloud()
	var/turf/center = get_turf(src)
	cloud_turfs = list()
	cloud_images = list()

	for(var/turf/T in range(1, center))
		cloud_turfs += T
		var/image/ash = image('icons/effects/effects.dmi', T, "smoke", ABOVE_OPEN_TURF_LAYER)
		ash.color = "#4a4a4a"
		ash.alpha = 150
		cloud_images += ash

	for(var/mob/living/carbon/human/H in GLOB.dread_marked_humans)
		if(H.client)
			H.client.images += cloud_images

	MarkedVisibleMessage(span_danger("[src] releases a cloud of choking ash!"))
	MarkedPlaysound(center, 'sound/effects/smoke.ogg', 50, TRUE)

	// Process cloud damage
	addtimer(CALLBACK(src, PROC_REF(CloudDamageTick)), 10)
	addtimer(CALLBACK(src, PROC_REF(CloudDamageTick)), 30)
	addtimer(CALLBACK(src, PROC_REF(CloudDamageTick)), 50)
	addtimer(CALLBACK(src, PROC_REF(EndAshCloud)), 80)

/// Deal damage to marked humans in cloud
/mob/living/simple_animal/hostile/dread_walker/ash_walker/proc/CloudDamageTick()
	for(var/mob/living/carbon/human/H in GLOB.dread_marked_humans)
		if(get_turf(H) in cloud_turfs)
			H.deal_damage(8, RED_DAMAGE, src)
			to_chat(H, span_warning("The ash burns your lungs!"))

/// Clean up ash cloud
/mob/living/simple_animal/hostile/dread_walker/ash_walker/proc/EndAshCloud()
	for(var/mob/living/carbon/human/H in GLOB.dread_marked_humans)
		if(H.client)
			H.client.images -= cloud_images
	cloud_turfs = list()
	cloud_images = list()

// ==================== VAT BEAST WALKER ====================
/// A massive, toxic horror that corrodes and poisons
/mob/living/simple_animal/hostile/dread_walker/vat_beast
	name = "Vat Beast Walker"
	desc = "A hulking mass of corruption that oozes toxic slime..."
	icon = 'icons/mob/vatgrowing.dmi'
	icon_state = "vat_beast"
	icon_living = "vat_beast"
	icon_dead = "vat_beast"

	health = 1000
	maxHealth = 1000
	melee_damage_lower = 25
	melee_damage_upper = 35
	melee_damage_type = BLACK_DAMAGE
	move_to_delay = 6

	attack_verb_continuous = "slams"
	attack_verb_simple = "slam"
	attack_sound = 'sound/effects/blobattack.ogg'

	/// Cooldown for corrosive slam
	var/slam_cooldown = 0
	var/slam_cooldown_time = 10 SECONDS

	var/list/vat_phrases = list(
		"...growing...",
		"...spreading...",
		"...consuming...",
		"...absorbing..."
	)

/mob/living/simple_animal/hostile/dread_walker/vat_beast/Initialize()
	. = ..()
	patrol_phrases = vat_phrases
	stalking_phrases = list(
		"...join the mass...",
		"...become one...",
		"...assimilate...",
		"...part of us..."
	)

/mob/living/simple_animal/hostile/dread_walker/vat_beast/AttackingTarget()
	. = ..()
	if(. && ishuman(target))
		TryCorrosiveSlam()

/// Attempt a corrosive slam attack
/mob/living/simple_animal/hostile/dread_walker/vat_beast/proc/TryCorrosiveSlam()
	if(slam_cooldown > world.time)
		return
	if(!prob(30))
		return

	slam_cooldown = world.time + slam_cooldown_time

	can_act = FALSE
	MarkedPlaysound(get_turf(src), 'sound/effects/blobattack.ogg', 75, TRUE)
	MarkedVisibleMessage(span_danger("[src] rears back, preparing to slam!"))

	// Show danger zone - use scorch effect
	for(var/turf/T in range(1, src))
		MarkedVisualEffect(T, 'icons/effects/effects.dmi', "scorch", 8)

	addtimer(CALLBACK(src, PROC_REF(ExecuteSlam)), 8)

/// Execute the slam attack
/mob/living/simple_animal/hostile/dread_walker/vat_beast/proc/ExecuteSlam()
	MarkedPlaysound(get_turf(src), 'sound/effects/blobattack.ogg', 100, TRUE)

	for(var/mob/living/carbon/human/H in range(1, src))
		if(H in GLOB.dread_marked_humans)
			H.deal_damage(40, BLACK_DAMAGE, src)
			to_chat(H, span_userdanger("Corrosive slime burns through your defenses!"))
			H.playsound_local(get_turf(H), 'sound/effects/blobattack.ogg', 60, TRUE)

			// Corrosion effect image - green silhouette
			var/image/corrosion = image(H.icon, H, H.icon_state, ABOVE_MOB_LAYER)
			corrosion.color = "#44ff00"
			corrosion.alpha = 180
			if(H.client)
				H.client.images += corrosion
				animate(corrosion, alpha = 0, time = 30)
				addtimer(CALLBACK(src, PROC_REF(CleanupCorrosion), corrosion, H), 30)

	can_act = TRUE

/// Clean up corrosion effect
/mob/living/simple_animal/hostile/dread_walker/vat_beast/proc/CleanupCorrosion(image/I, mob/living/carbon/human/victim)
	if(victim?.client)
		victim.client.images -= I

// ==================== NARSIAN WALKER ====================
/// A cult-touched horror that spreads madness
/mob/living/simple_animal/hostile/dread_walker/narsian
	name = "Narsian Walker"
	desc = "Touched by forbidden powers, it whispers truths that shatter sanity..."
	icon = 'icons/mob/pets.dmi'
	icon_state = "narsian"
	icon_living = "narsian"
	icon_dead = "narsian"

	health = 650
	maxHealth = 650
	melee_damage_lower = 14
	melee_damage_upper = 20
	melee_damage_type = PALE_DAMAGE
	move_to_delay = 5

	attack_verb_continuous = "whispers to"
	attack_verb_simple = "whisper to"
	attack_sound = 'sound/hallucinations/whispers.ogg'

	// Ranged capability
	ranged = TRUE
	ranged_cooldown_time = 8 SECONDS
	projectiletype = null

	/// Cooldown for eldritch whisper
	var/whisper_cooldown = 0
	var/whisper_cooldown_time = 12 SECONDS
	/// Whether blood ritual is active
	var/ritual_active = FALSE

	var/list/narsian_phrases = list(
		"...Nar-Sie...",
		"...the blood...",
		"...sacrifice...",
		"...awakening..."
	)

/mob/living/simple_animal/hostile/dread_walker/narsian/Initialize()
	. = ..()
	patrol_phrases = narsian_phrases
	stalking_phrases = list(
		"...blood calls...",
		"...join us...",
		"...the ritual...",
		"...become vessel..."
	)

/mob/living/simple_animal/hostile/dread_walker/narsian/Life()
	. = ..()
	if(!.)
		return

	// Check for blood ritual trigger
	if(!ritual_active && health < maxHealth * 0.25)
		BloodRitual()

/mob/living/simple_animal/hostile/dread_walker/narsian/OpenFire(atom/A)
	if(!ishuman(A))
		return
	EldritchWhisper(A)

/// Whisper eldritch truths at the target
/mob/living/simple_animal/hostile/dread_walker/narsian/proc/EldritchWhisper(mob/living/carbon/human/victim)
	if(!victim || whisper_cooldown > world.time)
		return

	whisper_cooldown = world.time + whisper_cooldown_time
	ranged_cooldown = world.time + ranged_cooldown_time

	victim.playsound_local(get_turf(victim), 'sound/hallucinations/whispers.ogg', 50, TRUE)

	// Red rune effect around victim - dark red silhouette
	var/image/rune = image(victim.icon, victim, victim.icon_state, ABOVE_MOB_LAYER)
	rune.color = "#880000"
	rune.alpha = 180
	if(victim.client)
		victim.client.images += rune
		animate(rune, alpha = 0, time = 20)
		addtimer(CALLBACK(src, PROC_REF(CleanupRune), rune, victim), 20)

	to_chat(victim, span_cultlarge("Incomprehensible whispers flood your mind..."))
	MarkedVisibleMessage(span_danger("[src] whispers forbidden words at [victim]!"))

	victim.adjustSanityLoss(20)

	// Chance for hallucination
	if(prob(30))
		victim.hallucination += 100

/// Clean up rune image
/mob/living/simple_animal/hostile/dread_walker/narsian/proc/CleanupRune(image/I, mob/living/carbon/human/victim)
	if(victim?.client)
		victim.client.images -= I

/// Blood ritual to heal when critically wounded
/mob/living/simple_animal/hostile/dread_walker/narsian/proc/BloodRitual()
	if(ritual_active)
		return

	ritual_active = TRUE
	can_act = FALSE

	MarkedPlaysound(get_turf(src), 'sound/hallucinations/whispers.ogg', 70, TRUE)
	MarkedVisibleMessage(span_cultlarge("[src] begins a dark ritual, blood swirling around it!"))

	// Create blood circle effect
	var/list/ritual_images = list()
	for(var/turf/T in range(1, src))
		var/image/blood = image('icons/effects/blood.dmi', T, "splatter1", ABOVE_OPEN_TURF_LAYER)
		blood.color = "#660000"
		blood.alpha = 180
		ritual_images += blood

	for(var/mob/living/carbon/human/H in GLOB.dread_marked_humans)
		if(H.client)
			H.client.images += ritual_images

	// Heal over duration
	addtimer(CALLBACK(src, PROC_REF(RitualHealTick)), 10)
	addtimer(CALLBACK(src, PROC_REF(RitualHealTick)), 20)
	addtimer(CALLBACK(src, PROC_REF(RitualHealTick)), 30)
	addtimer(CALLBACK(src, PROC_REF(RitualHealTick)), 40)
	addtimer(CALLBACK(src, PROC_REF(EndRitual), ritual_images), 50)

/// Heal tick during ritual
/mob/living/simple_animal/hostile/dread_walker/narsian/proc/RitualHealTick()
	adjustBruteLoss(-50)

/// End blood ritual
/mob/living/simple_animal/hostile/dread_walker/narsian/proc/EndRitual(list/ritual_images)
	for(var/mob/living/carbon/human/H in GLOB.dread_marked_humans)
		if(H.client)
			H.client.images -= ritual_images

	can_act = TRUE
	ritual_active = FALSE
	MarkedVisibleMessage(span_notice("[src]'s ritual concludes..."))
