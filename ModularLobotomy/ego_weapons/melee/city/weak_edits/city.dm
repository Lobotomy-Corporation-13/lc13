//Copy of the baton
/obj/item/ego_weapon/city/zweibaton/protection
	name = "city protection baton"
	desc = "A riot club used by the local protection."
	special = "Attack a human to stun them after a period of time."
	icon_state = "protection_baton"
	inhand_icon_state = "protection_baton"
	force = 30
	attribute_requirements = list()



//Bad indexstuff
/obj/item/ego_weapon/city/fakeindex
	name = "index recruit sword"
	desc = "A sheathed sword used by index recruits."
	special = "Hit the bodypart you're told to target to gain unlock stacks. At 3 stacks, this weapon switches to PALE damage. Missing the target bodypart removes 1 stack. Attacking insane targets always grants a stack and deals PALE damage."
	icon_state = "index"
	inhand_icon_state = "index"
	force = 20
	damtype = WHITE_DAMAGE

	attack_verb_continuous = list("smacks", "hammers", "beats")
	attack_verb_simple = list("smack", "hammer", "beat")
	var/target_bodypart
	var/unlock_stacks = 0
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 60,
	)

/obj/item/ego_weapon/city/fakeindex/attack(mob/living/target, mob/living/user)
	// Handle bodypart targeting mechanic for humans
	if(ishuman(target))
		var/mob/living/carbon/human/H = target

		// Special handling for insane targets
		if(H.sanity_lost)
			// Always gain a stack when hitting insane targets
			if(unlock_stacks < 3)
				unlock_stacks++
				to_chat(user, span_nicegreen("You strike the insane target! Unlock stacks: [unlock_stacks]/3"))
			// Temporarily switch to PALE damage for this attack
			var/original_damtype = damtype
			damtype = PALE_DAMAGE
			. = ..()
			// Restore original damage type after attack
			if(unlock_stacks < 3)
				damtype = original_damtype
			return

		// Set correct damage type based on current unlock stacks BEFORE processing attack
		if(unlock_stacks >= 3)
			damtype = PALE_DAMAGE
		else
			damtype = WHITE_DAMAGE

		// Determine which bodypart was actually hit
		var/obj/item/bodypart/affecting = H.get_bodypart(ran_zone(user.zone_selected))

		if(affecting)
			var/hit_zone = affecting.body_zone

			// Check if we have a target bodypart - mechanic continues even after unlocking
			if(target_bodypart)
				// Check if they hit the correct bodypart
				if(hit_zone == target_bodypart)
					// Correct hit! Gain a stack (up to 3 max)
					if(unlock_stacks < 3)
						unlock_stacks++
						to_chat(user, span_nicegreen("You strike the [affecting.name] perfectly! Unlock stacks: [unlock_stacks]/3"))

						// Check if we've reached 3 stacks
						if(unlock_stacks >= 3)
							to_chat(user, span_userdanger("Your weapon unlocks, now dealing PALE damage!"))
					else
						to_chat(user, span_nicegreen("You strike the [affecting.name] perfectly!"))
				else
					// Wrong bodypart! Lose 1 stack
					if(unlock_stacks > 0)
						unlock_stacks--
						to_chat(user, span_danger("You missed the target bodypart! Lost 1 unlock stack. ([unlock_stacks]/3)"))
						if(unlock_stacks < 3)
							to_chat(user, span_warning("Your weapon has been locked back to WHITE damage!"))

			// Always pick a new random target bodypart for the next attack
			var/list/possible_zones = list(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
			target_bodypart = pick(possible_zones)

			// Get the bodypart name for display
			var/obj/item/bodypart/target_part = H.get_bodypart(target_bodypart)
			if(target_part)
				to_chat(user, span_warning("Target their [target_part.name] next!"))

	return ..()

//proxy randomizer
/obj/effect/spawner/lootdrop/proxy
	name = "proxy weapon spawner"
	lootdoubles = FALSE

	loot = list(
		/obj/item/ego_weapon/city/fakeindex/proxy = 1,
		/obj/item/ego_weapon/city/fakeindex/proxy/spear = 1,
		/obj/item/ego_weapon/city/fakeindex/proxy/knife = 1,
	)

/obj/item/ego_weapon/city/fakeindex/proxy
	name = "index longsword"
	desc = "A long sword used by index proxies."
	icon_state = "indexlongsword"
	inhand_icon_state = "indexlongsword"
	attack_verb_continuous = list("slices", "slashes", "stabs")
	attack_verb_simple = list("slice", "slash", "stab")
	hitsound = 'sound/weapons/bladeslice.ogg'
	force = 45
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 80,
	)

//Just gonna set this to the big proxy weapon for requirement reasons
/obj/item/ego_weapon/city/fakeindex/proxy/spear
	name = "index spear"
	desc = "A spear used by index proxies."
	icon_state = "indexspear"
	inhand_icon_state = "indexspear"
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left_64x64.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right_64x64.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	hitsound = 'sound/weapons/fixer/generic/nail1.ogg'
	attack_speed = 1.2
	reach = 2
	stuntime = 5

/obj/item/ego_weapon/city/fakeindex/proxy/knife
	name = "index dagger"
	desc = "A dagger used by index proxies."
	icon_state = "indexdagger"
	inhand_icon_state = "indexdagger"
	force = 30
	attack_speed = 0.5


//Fockin massive sword
/obj/item/ego_weapon/city/fakeindex/yan
	name = "index greatsword"
	desc = "A greatsword sword used by a specific index messenger."
	icon_state = "indexgreatsword"
	inhand_icon_state = "indexgreatsword"
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left_64x64.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right_64x64.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	attack_verb_continuous = list("cleaves", "cuts")
	attack_verb_simple = list("cleaves", "cuts")
	hitsound = 'sound/weapons/fixer/generic/finisher1.ogg'
	force = 70
	attack_speed = 2
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100,
	)


//Blade Lineage
/obj/item/ego_weapon/city/bladelineage/city
	special = "Use this weapon in hand to immobilize yourself for 3 seconds and deal 3x damage on the next attack within 5 seconds. This empowered attack also deals 2% more damage per 1% of your missing HP, on top of the 3x damage."
	force = 30
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 60,
	)
	multiplier = 3

//Kurokumo
/obj/item/ego_weapon/city/kurokumo/weak
	force = 52
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 60,
	)

//Thumb
/obj/item/ego_weapon/ranged/city/thumb/city
	force = 35
	projectile_damage_multiplier = 1
	projectile_path = /obj/projectile/ego_bullet/citythumb // does 30 damage (odd, there's no force mod on this one)
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 60,
	)

/obj/projectile/ego_bullet/citythumb
	damage = 30
	damage_type = RED_DAMAGE
	armour_penetration = 50 //50% True Damage. Ignores 50% of armor
	ignore_bulletproof = TRUE

//Capo
/obj/item/ego_weapon/ranged/city/thumb/capo/city
	force = 44
	projectile_damage_multiplier = 1
	projectile_path = /obj/projectile/ego_bullet/citythumb/capo // does 30 damage (odd, there's no force mod on this one)
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 80,
	)

/obj/projectile/ego_bullet/citythumb/capo
	damage = 45

//Sottocapo
/obj/item/ego_weapon/ranged/city/thumb/sottocapo/city
	force = 10	//It's a pistol
	projectile_damage_multiplier = 1
	projectile_path = /obj/projectile/ego_bullet/citythumb/sottocapo // total 80 AP damage
	pellets = 8
	variance = 16
	reloadtime = 7 SECONDS // it is a bit stronger, but requires a bit longer reload time. (either hit with it or step back for downtime)
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100,
	)

/obj/projectile/ego_bullet/citythumb/sottocapo
	damage = 10

//wepaons are kinda uninteresting
/obj/item/ego_weapon/city/thumbmelee/weak
	force = 52
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 80,
	)

/obj/item/ego_weapon/city/thumbcane/weak
	force = 70
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100,
	)

/obj/item/clothing/suit/armor/ego_gear/city/thumb/city
	name = "thumb soldato armor"
	desc = "Armor worn by thumb grunts."
	icon_state = "thumb"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 30, BLACK_DAMAGE = 30, PALE_DAMAGE = 30)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)

/obj/item/clothing/suit/armor/ego_gear/city/thumb_capo/city
	name = "thumb capo armor"
	desc = "Armor worn by thumb capos."
	icon_state = "capo"
	armor = list(RED_DAMAGE = 50, WHITE_DAMAGE = 40, BLACK_DAMAGE = 40, PALE_DAMAGE = 40)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)


/obj/item/clothing/suit/armor/ego_gear/city/ncorp/weak
	name = "nagel und hammer armor"
	desc = "Armor worn by Nagel Und Hammer."
	icon_state = "ncorp"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 20, BLACK_DAMAGE = 20, PALE_DAMAGE = 50)
	attribute_requirements = list()

/obj/item/clothing/suit/armor/ego_gear/city/kcorp_l1/weak
	attribute_requirements = list()
