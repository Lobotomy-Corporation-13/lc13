// Der Fluchshutze, implemnted by neadsy_ - Sprites by Cringelord
/* /mob/living/simple_animal/hostile/abnormality/der_fluchschutze
	name = "Der Fluchschütze"
	desc = "A tall man adorned in some sort of military uniform, they loom over you, holding their large shotgun."
	icon = 'ModularLobotomy/_Lobotomyicons/32x64.dmi'
	icon_state = "DrFluShots"
	icon_living = "DrFluShots"
	portrait = "Der_Fluchschutze"
	maxHealth = 1000
	health = 1000
	ranged = TRUE
	minimum_distance = 1
	retreat_distance = 2
	attack_sound = 'sound/weapons/black_silence/shotgun.ogg'
	projectiletype = /obj/projectile/fellround
	ranged_cooldown_time = 4 SECONDS
	move_to_delay = 5
	can_breach = TRUE
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 0.7, FIRE = 0.5)
	stat_attack = HARD_CRIT
	vision_range = 20
	aggro_vision_range = 25
	del_on_death = FALSE

	can_breach = TRUE
	threat_level = HE_LEVEL
	faction = list("der_fluchschutze") // Scrap with them abnos!!!!
	start_qliphoth = 3
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 35,
		ABNORMALITY_WORK_INSIGHT = 20, // the only thing he cares about is shooting you
		ABNORMALITY_WORK_ATTACHMENT = 60,
		ABNORMALITY_WORK_REPRESSION = 50,
	)
	max_boxes = 16
	work_damage_amount = 8
	work_damage_type = RED_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/wrath
	patrol_cooldown_time = 10 SECONDS

	ego_list = list(
		/datum/ego_datum/weapon/fellbullet,
		/datum/ego_datum/weapon/fellscatter,
		/datum/ego_datum/armor/fellbullet,
	)
	gift_type =  /datum/ego_gifts/
	abnormality_origin = ABNORMALITY_ORIGIN_LIMBUS

	observation_prompt = "The Abnormality towers over you, it prepares its shotgun. Ready to fire, it says... 'This is a warzone, and my gun must blow somebody up...' \
	 In the corner of your eye, you see a silver glimmer: A pendant the Abnormality lost? or perhaps intentionally discarded..."
	observation_choices = list(
		"Inform the Abnormality you are on their side." = list(TRUE, "'alright then, keep the fight going for me.'"),
		"Return the pendant to the Abnormality." = list(FALSE, "The Abnormality opens the pendant and begins lashing out, firing bullets indescriminantly.\
		 You manage to escape before you are seriously hurt."),
	)

	/obj/projectile/fellround
	name = "Fell Bullet Round"
	desc = "A shotgun shell, its headed straight for you."
	damage_type = RED_DAMAGE
	damage = 20
	speed = 5
	alpha = 0
	spread = 20

/obj/projectile/fellround/Initialize()
	. = ..()
	hitsound = "sound/abnormalities/fluchschutze/fell_bullet2.ogg"
	animate(src, alpha = 255, time = 1) \*
