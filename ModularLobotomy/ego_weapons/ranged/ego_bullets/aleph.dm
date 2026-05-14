/obj/projectile/ego_bullet/star
	name = "star"
	icon_state = "star"
	damage = 28 // Multiplied by 1.5x when at high SP
	damage_type = WHITE_DAMAGE

/obj/projectile/ego_bullet/adoration
	name = "slime projectile"
	icon_state = "slime"
	desc = "A glob of infectious slime. It's going for your heart."
	damage = 40	//Fires 3
	speed = 0.8
	damage_type = BLACK_DAMAGE
	hitsound = "sound/effects/footstep/slime1.ogg"

/obj/projectile/ego_bullet/adoration/dot
	color = "#111111"
	speed = 1.3

/obj/projectile/ego_bullet/adoration/dot/on_hit(target)
	. = ..()
	var/mob/living/H = target
	if(!isbot(H) && isliving(H) && !QDELETED(H))
		H.visible_message("<span class='warning'>[target] is hit by [src], they seem to wither away!</span>")
		for(var/i = 1 to 14)
			addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/living, deal_damage), rand(4,8), BLACK_DAMAGE, firer, null, (ATTACK_TYPE_STATUS)), 2 SECONDS * i)

/obj/projectile/ego_bullet/adoration/aoe
	color = "#6666BB"

/obj/projectile/ego_bullet/adoration/aoe/on_hit(target)
	. = ..()
	for(var/mob/living/L in view(2, target))
		new /obj/effect/temp_visual/revenant/cracks(get_turf(L))
		L.deal_damage(50, BLACK_DAMAGE, firer, attack_type = (ATTACK_TYPE_RANGED))
	return BULLET_ACT_HIT

/obj/projectile/ego_bullet/nihil
	name = "dark energy"
	icon_state = "nihil"
	desc = "Just looking at it seems to suck the life out of you..."
	damage = 35	//Fires 4 +10 damage per upgrade, up to 75
	speed = 0.7
	damage_type = WHITE_DAMAGE

	hitsound = 'sound/abnormalities/nihil/filter.ogg'
	var/damage_list = list(WHITE_DAMAGE)
	var/icon_list = list()
	var/list/powers = list("hatred", "despair", "greed", "wrath")

/obj/projectile/ego_bullet/nihil/on_hit(atom/target, blocked = FALSE)
	if(powers[1] != "hearts")
		return ..()
	if(ishuman(target) && isliving(firer)) //this only happens with the queen of hatred upgrade
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
					H.adjustSanityLoss(-damage*0.2)
				if(BLACK_DAMAGE)
					H.adjustBruteLoss(-damage*0.1)
					H.adjustSanityLoss(-damage*0.1)
				else // Red or pale
					H.adjustBruteLoss(-damage*0.2)
			H.visible_message("<span class='warning'>[src] vanishes on contact with [H]!</span>")
			qdel(src)
			return BULLET_ACT_BLOCK
	return ..()

/obj/projectile/ego_bullet/nihil/fire(angle, atom/direct_target)
	if(fired_from)
		if(istype(fired_from, /obj/item/ego_weapon/ranged/nihil))
			var/obj/item/ego_weapon/ranged/nihil/our_weapon = fired_from
			powers = our_weapon.powers
	. = ..()
	if(powers[1] == "hearts")
		icon_list += "heart"
		damage += 10
	if(powers[2] == "spades")
		icon_list += "spade"
		damage_list += PALE_DAMAGE
		damage += 10
	if(powers[3] == "diamonds")
		icon_list += "diamond"
		damage_list += RED_DAMAGE
		damage += 10
	if(powers[4] == "clubs")
		icon_list += "club"
		damage_list += BLACK_DAMAGE
		damage += 10

	if(length(icon_list) > 0)
		icon_state = "nihil_[pick(icon_list)]"
		color = pick("#818589", "#C0C0C0")
	else
		color = pick("#36454F", "#818589")
	damage_type = pick(damage_list)

/obj/projectile/ego_bullet/pink
	name = "heart-piercing bullet"
	damage = 130
	damage_type = WHITE_DAMAGE

	hitscan = TRUE
	damage_falloff_tile = 5//the damage ramps up; 5 extra damage per tile. Maximum range is about 32 tiles, dealing 290 damage

/obj/projectile/ego_bullet/pink/on_hit(atom/target, blocked = FALSE, pierce_hit)
	new /obj/effect/temp_visual/friend_hearts(get_turf(target))//looks better than impact_effect_type and works
	return ..()

/obj/projectile/ego_bullet/arcadia
	name = "arcadia"
	damage = 140 // VERY high damage
	damage_type = RED_DAMAGE

/obj/projectile/ego_bullet/ego_hookah
	name = "havana"
	icon_state = "smoke"
	damage = 6
	damage_type = PALE_DAMAGE
	speed = 2
	range = 6

/// Ammo fired in Willing by default. Weak, fired quickly, very high spread. Hardly something appropiate for you to be using in ALEPH tier unless you're desperate.
/obj/projectile/ego_bullet/willing
	name = "fleshy round"
	icon_state = "bonebullet"
	color = COLOR_MOSTLY_PURE_RED
	speed = 0.5
	damage = 22
	damage_type = RED_DAMAGE

/// Ammo fired in Willing while Inexorable is active. Fired about half as fast as the normal ammo, but quite strong and much more precise.
// Useful, but doesn't beat out real weapons in terms of damage.
/obj/projectile/ego_bullet/willing/heavy
	name = "bone round"
	color = null
	speed = 0.4
	damage = 45

/obj/projectile/ego_bullet/willing/heavy/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	if(isliving(target))
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(target), pick(GLOB.alldirs))

/// Ammo fired in Willing while Entrenched is active (final stage). Fired slower than the previous, but extremely strong, accurate and pierces through one mob.
// This is very strong, even for ALEPH, but limited by you only being able to fire it while standing still, after having progressed the gun to the entrenched state.
/obj/projectile/ego_bullet/willing/superheavy
	name = "heavy bone round"
	color = null
	speed = 0.3
	damage = 70
	projectile_piercing = PASSMOB

/obj/projectile/ego_bullet/willing/superheavy/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	if(isliving(target))
		for(var/i in 1 to 2)
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(target), pick(GLOB.alldirs))
	if(pierces >= 2)
		qdel(src)

/obj/projectile/ego_bullet/black
	name = "black"
	icon_state = "atrocket"
	speed = 0.6
	damage = 50
	damage_type = BLACK_DAMAGE
	var/projectile_damage_multiplier = 1
	var/base_explosion_damage = 160
	var/base_explosion_falloff_per_tile = 35
	var/explosion_radius = 3
	var/iff_coeff = 0.40
	var/datum/status_effect/status_type = /datum/status_effect/display/black_weapon_shellshock
	var/resonance = FALSE
	var/resonance_radius_increase = 1
	var/resonance_damage_increase = 60
	var/resonance_iff_coeff = 0.20

/obj/projectile/ego_bullet/black/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	Detonate(target)

/obj/projectile/ego_bullet/black/proc/Detonate(atom/target)
	if(resonance)
		explosion_radius += resonance_radius_increase
		base_explosion_damage += resonance_damage_increase
		iff_coeff = resonance_iff_coeff

	projectile_damage_multiplier = (damage / initial(damage)) // Calculate our projectile damage modifier (Faith & Promise, Broken Crown Shimmering, etc...)

	base_explosion_damage *= projectile_damage_multiplier

	// Establish what turfs are to be hit.
	var/turf/epicenter = (QDELETED(target) || !istype(target)) ? get_turf(src) : get_turf(target)
	var/list/affected_turfs = list()
	for(var/turf/T in view(explosion_radius, epicenter))
		affected_turfs |= T

	// Explosion aesthetics.
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(RadialShockwaveVisual), epicenter, explosion_radius, 1)
	playsound(epicenter, 'sound/abnormalities/armyinblack/black_explosion.ogg', 60, TRUE, 5, ignore_walls = TRUE)
	var/atom/vfx = new /obj/effect/temp_visual/black_explosion(epicenter)
	vfx.transform *= 0.85

	var/mob/living/john_aib = firer
	var/should_do_iff = (!QDELETED(john_aib) && istype(john_aib))
	var/list/hitlist = list()

	for(var/turf/T2 in affected_turfs)
		// Calculate the distance only once for each turf
		var/distance_from_epicenter = max(get_dist(T2, epicenter), 0) // get_dist gives you -1 if it's the same turf
		for(var/mob/living/L in T2)
			if(L in hitlist)
				continue
			if(L.stat >= DEAD)
				continue
			hitlist |= L

			// Calculate if we should apply IFF to this mob, and calculate final damage
			var/please_have_mercy = (should_do_iff && (john_aib.faction_check_mob(L))) // && stops us from doing a faction check with a null john_aib
			var/final_damage = max(base_explosion_damage - (distance_from_epicenter * base_explosion_falloff_per_tile), 0) // We don't wanna go into the negatives here

			if(please_have_mercy)
				final_damage *= iff_coeff

			L.deal_damage(final_damage, damage_type, source = john_aib, attack_type = (ATTACK_TYPE_RANGED)) // john_aib can be null but that's okay
			if(resonance && !please_have_mercy) // Apply our status_type if this was a resonant shot, and if IFF doesn't apply to this mob
				L.apply_status_effect(status_type)

			// Gib corpses
			if(L.stat >= DEAD)
				L.gib()
				continue

			// Knockback
			var/throw_comparison = T2 == epicenter ? null : epicenter // If they're standing directly in the epicenter we need to take special measures
			var/throw_dir = throw_comparison ? get_cardinal_dir(throw_comparison, L) : pick(GLOB.cardinals) // Take a random cardinal if they're directly on top of us
			if(!QDELETED(L) && L.health > 0)
				if(L != firer)
					L.safe_throw_at(target = get_ranged_target_turf(epicenter, throw_dir, explosion_radius + distance_from_epicenter), range = max(1, (explosion_radius - distance_from_epicenter) + 1), speed = 5, spin = TRUE, gentle = TRUE)
				else
					L.apply_status_effect(/datum/status_effect/black_weapon_rocketjump)
					L.safe_throw_at(target = get_ranged_target_turf(epicenter, throw_dir, 10), range = (10 - distance_from_epicenter * 2), speed = (13 - distance_from_epicenter * 2), spin = FALSE, gentle = TRUE)

/datum/status_effect/display/black_weapon_shellshock
	id = "black_weapon_shellshock"
	status_type = STATUS_EFFECT_REFRESH
	duration = 10 SECONDS
	tick_interval = -1 // We don't need to tick
	alert_type = null
	display_icon = 'ModularLobotomy/_Lobotomyicons/status_icons_10x10.dmi'
	display_name = "shellshock"
	var/slowdown = /datum/movespeed_modifier/black_weapon_shellshock
	var/animal_shred = /datum/dc_change/black_weapon_shellshock
	var/human_shred_coeff = 1.25
	var/applied_debuffs = FALSE

/datum/status_effect/display/black_weapon_shellshock/on_apply()
	. = ..()
	if(!istype(owner) || owner.stat >= DEAD)
		return FALSE
	// Slowdown
	owner.add_movespeed_modifier(slowdown)
	// Shred
	var/mob/living/simple_animal/animal_owner = owner
	var/mob/living/carbon/human/human_owner = owner
	if(istype(animal_owner))
		animal_owner.AddModifier(animal_shred)
	else if(istype(human_owner))
		human_owner.physiology.red_mod *= human_shred_coeff
		human_owner.physiology.white_mod *= human_shred_coeff
		human_owner.physiology.black_mod *= human_shred_coeff
		human_owner.physiology.pale_mod *= human_shred_coeff

	// So we know if we have to remove these later
	applied_debuffs = TRUE

/datum/status_effect/display/black_weapon_shellshock/on_remove()
	. = ..()
	if(applied_debuffs)
		owner.remove_movespeed_modifier(slowdown)
		var/mob/living/simple_animal/animal_owner = owner
		var/mob/living/carbon/human/human_owner = owner
		if(istype(animal_owner))
			animal_owner.RemoveModifier(animal_shred)
		else if(istype(human_owner))
			human_owner.physiology.red_mod /= human_shred_coeff
			human_owner.physiology.white_mod /= human_shred_coeff
			human_owner.physiology.black_mod /= human_shred_coeff
			human_owner.physiology.pale_mod /= human_shred_coeff

/datum/movespeed_modifier/black_weapon_shellshock
	flags = IS_ACTUALLY_MULTIPLICATIVE
	multiplicative_slowdown = 1.6

/datum/dc_change/black_weapon_shellshock
	potency = 1.25
	damage_type = list(RED_DAMAGE, WHITE_DAMAGE, BLACK_DAMAGE, PALE_DAMAGE)

/datum/status_effect/black_weapon_rocketjump
	id = "black_weapon_rocketjump"
	duration = 2 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/black_weapon_rocketjump
	status_type = STATUS_EFFECT_REFRESH
	var/power_modifier = 100 // Double damage...!? And speed I guess. Count it as 'momentum'.

/datum/status_effect/black_weapon_rocketjump/on_apply()
	. = ..()
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/H = owner
	H.adjust_attribute_bonus(JUSTICE_ATTRIBUTE, power_modifier)

/datum/status_effect/black_weapon_rocketjump/on_remove()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.adjust_attribute_bonus(JUSTICE_ATTRIBUTE, -power_modifier)

/atom/movable/screen/alert/status_effect/black_weapon_rocketjump
	name = "Rocket Jump...!?"
	desc = "Are you insane!? Your momentum carries you, increasing your Power Modifier by 100."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "strength"
