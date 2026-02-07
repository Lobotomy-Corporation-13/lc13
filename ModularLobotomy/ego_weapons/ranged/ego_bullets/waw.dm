/obj/projectile/ego_bullet/ego_correctional
	name = "correctional"
	damage = 10
	damage_type = BLACK_DAMAGE

/obj/projectile/ego_bullet/ego_hornet
	name = "hornet"
	damage = 55
	damage_type = RED_DAMAGE

/obj/projectile/ego_bullet/ego_hatred
	name = "magic beam"
	icon_state = "qoh1"
	damage_type = BLACK_DAMAGE
	damage = 50
	spread = 10

/obj/projectile/ego_bullet/ego_hatred/on_hit(atom/target, blocked = FALSE)
	if(ishuman(target) && isliving(firer))
		var/mob/living/carbon/human/H = target
		var/mob/living/user = firer
		if(firer==target)
			return BULLET_ACT_BLOCK
		if(user.faction_check_mob(H)) // Our faction
			if(H.is_working)
				H.visible_message("<span class='warning'>[src] vanishes on contact with [H]... but nothing happens!</span>")
				qdel(src)
				return BULLET_ACT_BLOCK
			switch(damage_type)
				if(WHITE_DAMAGE)
					H.adjustSanityLoss(-10)
				if(BLACK_DAMAGE)
					H.adjustBruteLoss(-5)
					H.adjustSanityLoss(-5)
				else // Red or pale
					H.adjustBruteLoss(-10)
			H.visible_message("<span class='warning'>[src] vanishes on contact with [H]!</span>")
			qdel(src)
			return BULLET_ACT_BLOCK
	..()

/obj/projectile/ego_bullet/ego_hatred/Initialize()
	. = ..()
	icon_state = "qoh[pick(1,2,3)]"
	damage_type = pick(RED_DAMAGE, WHITE_DAMAGE, BLACK_DAMAGE, PALE_DAMAGE)

/obj/projectile/ego_bullet/ego_magicbullet
	name = "magic bullet"
	icon_state = "magic_bullet"
	damage = 80
	speed = 0.1
	damage_type = BLACK_DAMAGE
	projectile_piercing = PASSMOB
	range = 18 // Don't want people shooting it through the entire facility
	hit_nondense_targets = TRUE

/obj/projectile/ego_bullet/ego_magicbullet/abnormality
	damage = 70 // Lower damage, inflicts a status effect.

/obj/projectile/ego_bullet/ego_magicbullet/abnormality/on_hit(atom/target, blocked = FALSE, pierce_hit)
	if(istype(target, /mob/living/simple_animal/hostile/der_freis_portal))
		var/mob/living/simple_animal/hostile/der_freis_portal/P = target
		P.death()
	else if(istype(target, /mob/living))
		var/mob/living/the_target = target
		the_target.apply_dark_flame(7)
	. = ..()



/obj/projectile/ego_bullet/ego_solemnlament
	name = "solemn lament"
	icon_state = "whitefly"
	damage = 35
	speed = 0.35
	damage_type = WHITE_DAMAGE

/obj/projectile/ego_bullet/ego_solemnvow
	name = "solemn vow"
	icon_state = "blackfly"
	damage = 35
	speed = 0.35
	damage_type = BLACK_DAMAGE

//Smartgun
/obj/projectile/ego_bullet/ego_loyalty // not actually used at the moment
	name = "loyalty"
	icon_state = "loyalty"
	damage = 4
	speed = 0.2
	damage_type = RED_DAMAGE

/obj/projectile/ego_bullet/ego_loyalty/iff
	name = "loyalty IFF"
	damage = 9
	nodamage = TRUE	//Damage is calculated later
	projectile_piercing = PASSMOB

/obj/projectile/ego_bullet/ego_loyalty/iff/on_hit(atom/target, blocked = FALSE)
	if(!ishuman(target))
		nodamage = FALSE
	else
		return
	..()
	if(!ishuman(target))
		qdel(src)

/// Fired from the Loyalty rifle's UGL. Will go right through mobs and nondense stuff until it reaches the thing you clicked on or a wall.
/obj/projectile/ego_bullet/loyalty_ugl
	name = "loyal grenade"
	icon_state = "bolter"
	damage = 20
	range = 16
	nodamage = TRUE	// Damage is calculated later
	speed = 0.8
	projectile_piercing = PASSMOB
	// No hitsound - we play a sound on detonation

	var/tile_radius = 3
	/// Damage at epicenter (distance 0)
	var/base_damage = 180
	/// Each tile away from the epicenter reduces damage by this much
	var/falloff_per_dist = 40
	var/list/hitlist = list()
	/// We'll update the range the first time we move. We don't want to go any further than the distance between our firer and the original target.
	var/updated_range = FALSE

/obj/projectile/ego_bullet/loyalty_ugl/on_hit(atom/target, blocked = FALSE)
	if(target == original || (target.density && !ismob(target)))
		nodamage = FALSE
		qdel(src)
	else
		return
	..()

/obj/projectile/ego_bullet/loyalty_ugl/Moved(atom/OldLoc, Dir)
	. = ..()
	// Okay so, we don't want the grenade to go any further than the distance between the firer and our original target. We can't do this on Initialize because we won't have
	// the original var by then. So we just do it once the first time we move.
	if(!updated_range)
		updated_range = TRUE
		range = get_dist(firer, original)
	if(isturf(original) && loc == original)
		qdel(src)

/// Whenever this thing finally meets its end, blow up.
/obj/projectile/ego_bullet/loyalty_ugl/Destroy(force)
	Detonate()
	return ..()

/// Explode, dealing damage and knocking back all nearby enemies. Ignore anything that has the firer's faction. Also gib dead things.
/obj/projectile/ego_bullet/loyalty_ugl/proc/Detonate()
	var/mob/living/nadeslinger = firer
	if(!istype(nadeslinger))
		return
	var/turf/impact_turf = get_turf(src)

	// Aesthetics
	playsound(impact_turf, 'sound/abnormalities/armyinblack/black_explosion.ogg', 60, FALSE, 5, ignore_walls = TRUE)
	var/atom/vfx = new /obj/effect/temp_visual/black_explosion(impact_turf)
	vfx.transform *= 0.6
	INVOKE_ASYNC(src, PROC_REF(DetonationShockwaveVisual), impact_turf, tile_radius)

	// Shake the screen of the firer
	var/dist_from_epicenter = get_dist(nadeslinger, impact_turf)
	var/screenshake_intensity = clamp((3.5 - (dist_from_epicenter * 0.4)), 0.3, 3.5)
	shake_camera(nadeslinger, 3, screenshake_intensity)

	// Check every turf in our radius, hit mobs once at most. This can hit corpses.
	var/list/affected_turfs = RANGE_TURFS(tile_radius, impact_turf)
	for(var/turf/T in affected_turfs)
		for(var/mob/living/M in T)
			if(M in hitlist)
				continue
			if(nadeslinger.faction_check_mob(M))
				continue

			hitlist |= M

			// Damage
			var/final_damage = base_damage * (damage / initial(damage)) // This is unhinged as hell but the best way to get the Force Multiplier (EO upgrade, Faith & Promise) to affect the explosion.
			var/distance_from_epicenter = clamp(get_dist(M, impact_turf), 0, 3)
			final_damage -= (distance_from_epicenter * falloff_per_dist)
			M.deal_damage(final_damage, damage_type, source = nadeslinger, attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))

			// Knockback
			var/throw_comparison = get_turf(M) == impact_turf ? null : impact_turf // If they're standing directly in the epicenter we need to take special measures
			var/throw_dir = throw_comparison ? get_cardinal_dir(throw_comparison, M) : pick(GLOB.cardinals) // Take a random cardinal if they're directly on top of us
			if(M)
				M.safe_throw_at(target = get_ranged_target_turf(impact_turf, throw_dir, 4), range = 5, speed = 5, thrower = nadeslinger, spin = TRUE)
				// Gib corpses
				if(M.stat >= DEAD)
					M.gib()

// Recycled from Thumb East. Visual shockwave with the good old smoke vfx.
/obj/projectile/ego_bullet/loyalty_ugl/proc/DetonationShockwaveVisual(turf/origin, radius)
	var/list/already_rendered = list()
	// There may be a less expensive way to do this. I'm open to ideas.
	for(var/i in 1 to radius)
		var/list/turfs_to_spawn_visual_at = list()
		for(var/turf/T in orange(i, origin))
			turfs_to_spawn_visual_at |= T
		turfs_to_spawn_visual_at -= already_rendered
		for(var/turf/T2 in turfs_to_spawn_visual_at)
			new /obj/effect/temp_visual/small_smoke/halfsecond(T2)
			already_rendered |= T2
		sleep(2)

/obj/projectile/ego_bullet/ego_executive
	name = "executive"
	damage = 12
	damage_type = PALE_DAMAGE	//hehe

/obj/projectile/ego_bullet/ego_crimson
	name = "crimson"
	damage = 14
	damage_type = RED_DAMAGE

// This one is fired by Crimson Scar by default when wearing Crimson Lust. Under a certain buff, fires 4 pellets instead of 3 with a higher spread.
/obj/projectile/ego_bullet/ego_crimson/lust
	name = "hateful crimson"
	damage = 22
	projectile_piercing = PASSMOB

/obj/projectile/ego_bullet/ego_crimson/lust/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	if(pierces >= 2)
		qdel(src)

// This one is fired by Crimson Scar when wearing Crimson Lust while this mode is toggled on. It's only 1 pellet and more accurate. Slower firerate. Consumes Hemorrhage.
/obj/projectile/ego_bullet/ego_crimson/lust_hollowpoint
	name = "hollowpoint shell"
	damage = 100

/obj/projectile/ego_bullet/ego_crimson/lust_hollowpoint/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	if(!isliving(target))
		return
	var/mob/living/horrid_awful_wolf_in_our_nightmares = target
	var/datum/status_effect/display/crimlust_hemorrhage/well_deserved_wound = horrid_awful_wolf_in_our_nightmares.has_status_effect(/datum/status_effect/display/crimlust_hemorrhage)
	if(well_deserved_wound)
		well_deserved_wound.Consume()

/obj/projectile/ego_bullet/ego_ecstasy
	name = "ecstasy"
	icon_state = "ecstasy"
	damage_type = WHITE_DAMAGE
	damage = 10
	speed = 1.3
	range = 6

/obj/projectile/ego_bullet/ego_ecstasy/Initialize()
	. = ..()
	color = pick(COLOR_RED, COLOR_YELLOW, COLOR_LIME, COLOR_CYAN, COLOR_MAGENTA, COLOR_ORANGE)

//Smartpistol
/obj/projectile/ego_bullet/ego_praetorian
	name = "praetorian"
	icon_state = "loyalty"
	damage = 15
	nodamage = TRUE	//Damage is calculated later
	damage_type = RED_DAMAGE
	projectile_piercing = PASSMOB
	homing = TRUE
	homing_turn_speed = 30		//Angle per tick.
	var/homing_range = 9

/obj/projectile/ego_bullet/ego_praetorian/on_hit(atom/target, blocked = FALSE)
	if(!ishuman(target))
		nodamage = FALSE
	else
		return
	..()
	if(!ishuman(target))
		qdel(src)

/obj/projectile/ego_bullet/ego_praetorian/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(fireback)), 3)

/obj/projectile/ego_bullet/ego_praetorian/proc/fireback()
	var/list/targetslist = list()
	for(var/mob/living/L in range(homing_range, src))
		if(ishuman(L) || isbot(L))
			continue
		if(L.stat == DEAD)
			continue
		if(L.status_flags & GODMODE)
			continue
		targetslist+=L
	if(!LAZYLEN(targetslist))
		return
	homing_target = pick(targetslist)

/obj/projectile/ego_bullet/ego_magicpistol
	name = "magic pistol"
	icon_state = "magic_bullet"
	damage = 40
	speed = 0.1
	damage_type = BLACK_DAMAGE
	projectile_piercing = PASSMOB

//tommygun
/obj/projectile/ego_bullet/ego_intention
	name = "good intentions"
	damage = 12
	speed = 0.2
	damage_type = RED_DAMAGE

//laststop
/obj/projectile/ego_bullet/ego_laststop
	name = "laststop"
	damage = 145
	damage_type = RED_DAMAGE

/obj/projectile/ego_bullet/ego_aroma
	name = "aroma"
	icon_state = "arrow_aroma"
	damage = 140
	damage_type = WHITE_DAMAGE

//Assonance, our one hitscan laser
/obj/projectile/beam/assonance
	name = "assonance"
	icon_state = "omnilaser"
	hitsound = null
	damage = 50
	damage_type = WHITE_DAMAGE
	hitscan = TRUE
	muzzle_type = /obj/effect/projectile/muzzle/laser/white
	tracer_type = /obj/effect/projectile/tracer/laser/white
	impact_type = /obj/effect/projectile/impact/laser/white
	wound_bonus = -100
	bare_wound_bonus = -100

/obj/projectile/beam/assonance/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	if(pierce_hit)
		return
	if(!ishostile(target))
		return
	var/mob/living/simple_animal/hostile/H = target
	if(H.stat == DEAD || H.status_flags & GODMODE)
		return
	for(var/mob/living/carbon/human/Yin in view(7, H))
		var/obj/item/ego_weapon/wield/discord/D = Yin.get_active_held_item()
		if(istype(D, /obj/item/ego_weapon/wield/discord))
			if(!D.CanUseEgo(Yin))
				continue
			Yin.adjustBruteLoss(-10)
			Yin.adjustSanityLoss(-10)
			new /obj/effect/temp_visual/healing(get_turf(Yin))
			break
	return

//feather of honor
/obj/projectile/ego_bullet/ego_feather
	name = "feather"
	icon_state = "lava"
	damage = 40
	damage_type = WHITE_DAMAGE
	homing = TRUE
	speed = 1.5

//Exuviae
/obj/projectile/ego_bullet/ego_exuviae
	name = "serpents exuviae"
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "nakednest_serpent"
	desc = "A sterile naked nest serpent"
	damage = 120
	damage_type = RED_DAMAGE
	hitsound = "sound/effects/wounds/pierce1.ogg"

/obj/projectile/ego_bullet/ego_exuviae/on_hit(target)
	. = ..()
	if(isliving(target))
		var/mob/living/simple_animal/M = target
		if(!ishuman(M) && !M.has_status_effect(/datum/status_effect/rend_red))
			new /obj/effect/temp_visual/cult/sparks(get_turf(M))
			M.apply_status_effect(/datum/status_effect/rend_red)

//feather of valor
/obj/projectile/ego_bullet/ego_warring
	name = "feather of valor"
	icon_state = "arrow"
	damage = 75
	damage_type = BLACK_DAMAGE

/obj/projectile/ego_bullet/ego_warring/on_hit(atom/target, blocked = FALSE)
	. = ..()
	var/obj/item/ego_weapon/ranged/warring/bow = fired_from
	var/mob/living/L = target
	if(!isliving(target))
		return
	if((L.stat == DEAD) || L.status_flags & GODMODE)//if the target is dead or godmode
		return FALSE
	bow.HandleCharge(1, target)
	return

//feather of valor cont'd
/obj/projectile/ego_bullet/ego_warring2
	name = "feather of valor"
	icon_state = "lava"
	hitsound = null
	damage = 125
	damage_type = BLACK_DAMAGE
	hitscan = TRUE
	muzzle_type = /obj/effect/projectile/muzzle/laser/warring
	tracer_type = /obj/effect/projectile/tracer/warring
	impact_type = /obj/effect/projectile/impact/laser/warring

/obj/effect/projectile/muzzle/laser/warring
	name = "lightning flash"
	icon_state = "muzzle_warring"
/obj/effect/projectile/tracer/warring
	name = "lightning beam"
	icon_state = "warring"
/obj/effect/projectile/impact/laser/warring
	name = "lightning impact"
	icon_state = "impact_warring"

/obj/projectile/ego_bullet/ego_warring2/on_hit(atom/target, blocked = FALSE)
	. = ..()
	var/mob/living/carbon/human/H = target
	var/mob/living/user = firer
	if(user.faction_check_mob(H))//player faction
		H.adjustSanityLoss(-damage*0.2)
		H.electrocute_act(1, src, flags = SHOCK_NOSTUN)
		H.Knockdown(50)
		return BULLET_ACT_BLOCK
	qdel(src)

/obj/projectile/ego_bullet/ego_banquet
	name = "banquet"
	icon_state = "banquet"
	damage = 100
	damage_type = BLACK_DAMAGE

/obj/projectile/ego_bullet/ego_banquet/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	var/mob/living/victim = target
	// When impacting a living target, play a sound and create some fake bloodsplatters for extra impact.
	// Kinda tempting to make it spawn real blood so you can go pick it up for Bloodfeast?
	if(istype(victim) && victim.stat < DEAD)
		playsound(victim, 'sound/weapons/fixer/generic/nail1.ogg', 75, TRUE)
		for(var/i in 1 to 3)
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(victim), pick(GLOB.alldirs))
		// Bonus: if the projectile was shot by a human from the Banquet staff, any spawned bat minions will forcefully target whatever this projectile just hit.
		if(ishuman(firer))
			var/mob/living/carbon/human/owner = firer
			var/obj/item/ego_weapon/ranged/banquet/staff = owner.get_active_held_item()
			if(istype(staff))
				for(var/mob/living/simple_animal/hostile/banquet_bat/goon in staff.bound_bats)
					if(goon.z != goon.master.z)
						continue
					goon.ReceiveOrderedTarget(victim)

/obj/projectile/ego_bullet/ego_blind_rage
	name = "blind rage"
	icon_state = "blind_rage"
	damage = 15
	damage_type = BLACK_DAMAGE

/obj/projectile/ego_bullet/ego_blind_rage/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	if(!isliving(target))
		return
	var/mob/living/L = target
	L.apply_status_effect(/datum/status_effect/wrath_burning)

/obj/projectile/ego_bullet/ego_innocence
	name = "innocence"
	icon_state = "energy"
	damage = 19 // Can dual wield, full auto
	damage_type = WHITE_DAMAGE

/obj/projectile/ego_bullet/ego_hypocrisy
	name = "hypocrisy"
	icon_state = "arrow_greyscale"
	color = "#AAFF00"
	damage = 90 //50 damage is transfered to the spawnable trap
	damage_type = RED_DAMAGE


/obj/projectile/ego_bullet/ego_bride
	name = "bride"
	icon_state = "bride"
	damage = 55
	damage_type = WHITE_DAMAGE

/obj/projectile/ego_bullet/ego_supershotgun
	name = "super shotgun"
	damage = 10
	damage_type = RED_DAMAGE

/obj/projectile/ego_bullet/ego_fellbullet
	name = "fell bullet"
	icon_state = "fell_bullet"
	damage = 40
	speed = 0.1
	damage_type = RED_DAMAGE
	projectile_piercing = PASSMOB
	range = 36
	hit_nondense_targets = TRUE

/obj/projectile/ego_bullet/ego_fellscatter
	name = "fell pellet"
	damage = 10//7 pellets
	damage_type = RED_DAMAGE
	spread = 50

/obj/projectile/ego_bullet/ego_fellscatter/greater
	name = "fell pellet"
	icon_state = "fell_pellet"
	damage = 20//generated by friendly fire effect
	damage_type = RED_DAMAGE
	spread = 50

/obj/projectile/ego_bullet/special_fellbullet
	name = "fell bullet"
	icon_state = "fell_bullet"
	damage = 80
	speed = 0.1
	damage_type = RED_DAMAGE
	projectile_piercing = PASSMOB
	range = 18
	hit_nondense_targets = TRUE

/obj/projectile/ego_bullet/special_fellbullet/on_hit(atom/target, blocked = FALSE, angle)
	. = ..()
	var/mob/living/carbon/human/H = target
	if(ishuman(H))
		if(H.stat == DEAD)
			return FALSE
		INVOKE_ASYNC(src, PROC_REF(MagicBulletEffect), angle)
		damage /= 2

/obj/projectile/ego_bullet/special_fellbullet/prehit_pierce(atom/A)
	. = ..()
	var/mob/living/carbon/human/H = A
	if(ishuman(H))
		return PROJECTILE_PIERCE_NONE

/obj/projectile/ego_bullet/special_fellbullet/proc/MagicBulletEffect(angle, atom/direct_target)
	var/obj/effect/fellcircle/circle = new(get_turf(src))
	circle.FireBullets(Angle, damage)

/obj/effect/fellcircle//thing that shoots
	name = "magic circle"
	desc = "A circle of red magic featuring a six-pointed star "
	icon = 'icons/effects/effects.dmi'
	icon_state = "fellcircle"
	var/pellets = 7
	var/shotsleft = 4
	var/angle = 0
	var/damage = 80
	var/damage_mult = 1

/obj/effect/fellcircle/Initialize()
	QDEL_IN(src, 10 SECONDS)
	return ..()

/obj/effect/fellcircle/proc/FireBullets(angle, damage)
	playsound(src, 'sound/abnormalities/fluchschutze/fell_portal.ogg', 50, FALSE)
	if(damage > 80)//the damage of the slug that produced this effect
		damage_mult = (damage/80)//convert this into a decimal we can multiply the bullet's damage with
	sleep(1 SECONDS)
	animate(src, alpha = 0, time = 4 SECONDS)
	for(var/i = 0, i < shotsleft, i++)
		sleep(0.5 SECONDS)
		playsound(src, 'sound/abnormalities/fluchschutze/fell_scatter2.ogg', 25, TRUE)
		for(var/ii = 0, ii < pellets, ii++)
			var/obj/projectile/ego_bullet/ego_fellscatter/greater/bullet = new(get_turf(src))
			bullet.damage *= damage_mult
			bullet.fire(angle)
	QDEL_IN(src, 1 SECONDS)
