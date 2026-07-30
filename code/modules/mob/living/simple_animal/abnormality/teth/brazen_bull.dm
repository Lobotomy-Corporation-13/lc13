// Originally by cow11star. It was bugged and never added, so I fixed it up.
// It's a TETH that is quite likely to break out, qlipdropping on Bad works and on some Neutral works. Higher than average work damage, pretty meh work rates.
// Once out, runs around trying to charge at people, and acts as a stat-stick inbetween charges. Can charge again 7 seconds after ending its previous charge.
/mob/living/simple_animal/hostile/abnormality/brazen_bull
	name = "Brazen Bull"
	desc = "A bull made of a copper and zinc alloy. There's someone trapped inside it."
	icon = 'ModularLobotomy/_Lobotomyicons/64x48.dmi'
	icon_state = "brz_bull"
	portrait = "brazen_bull"
	pixel_x = -15
	base_pixel_x = -15
	icon_living = "brz_bull"
	maxHealth = 1200
	health = 1200
	vision_range = 11
	aggro_vision_range = 17
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1, PALE_DAMAGE = 2)
	melee_damage_lower = 10
	melee_damage_upper = 16
	melee_damage_type = RED_DAMAGE
	rapid_melee = 1.5
	stat_attack = HARD_CRIT
	attack_sound = 'sound/weapons/fast_slam.ogg'
	attack_verb_continuous = "smacks"
	attack_verb_simple = "smack"
	faction = list("hostile")
	can_breach = TRUE
	threat_level = TETH_LEVEL
	start_qliphoth = 2
	work_chances = list(
						ABNORMALITY_WORK_INSTINCT = list(20, 20, 20, 30, 30),
						ABNORMALITY_WORK_INSIGHT = list(40, 40, 50, 50, 50),
						ABNORMALITY_WORK_ATTACHMENT = list(20, 25, 30, 30, 35),
						ABNORMALITY_WORK_REPRESSION = list(50, 50, 40, 40, 40)
						)
	work_damage_amount = 7
	work_damage_type = RED_DAMAGE
	ego_list = list(
		/datum/ego_datum/weapon/capote,
		/datum/ego_datum/armor/capote
		)
	gift_type = /datum/ego_gifts/capote

	abnormality_origin = ABNORMALITY_ORIGIN_LIMBUS

	var/obj/effect/proc_holder/ability/aimed/dash/brazen_bull/ourdash

/mob/living/simple_animal/hostile/abnormality/brazen_bull/Initialize()
	. = ..()
	ourdash = new()

/mob/living/simple_animal/hostile/abnormality/brazen_bull/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-1)

/mob/living/simple_animal/hostile/abnormality/brazen_bull/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(60))
		datum_reference.qliphoth_change(-1)

/mob/living/simple_animal/hostile/abnormality/brazen_bull/handle_automated_action()
	. = ..()
	if(!can_act || IsContained() || stat == DEAD)
		return
	charge_check()

/mob/living/simple_animal/hostile/abnormality/brazen_bull/proc/charge_check()
	var/list/possible_targets = list()
	for(var/mob/living/carbon/human/H in view(20, src))
		possible_targets += H
	if(LAZYLEN(possible_targets))
		FindTarget(list(pick(possible_targets)), TRUE) // The list(pick()) here makes it equally likely for anyone to be targeted. If you removed it, it'd be based on individual threat level
		var/dir_to_target = get_cardinal_dir(get_turf(src), get_turf(target))
		if(dir_to_target)
			ourdash.Perform(target, src)
			return
	return

/mob/living/simple_animal/hostile/abnormality/brazen_bull/BreachEffect(mob/living/carbon/human/user)
	.=..()
	if(user)
		GiveTarget(user)
