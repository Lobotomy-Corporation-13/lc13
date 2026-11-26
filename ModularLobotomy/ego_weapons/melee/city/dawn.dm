//Dawn Office uses an AOE flame after hitting two different things. Grade 5
/obj/item/ego_weapon/city/dawn
	name = "dawn office template"
	desc = "A template for dawn office weapons."
	special = "Hit one enemy, then the other to unleash a weak aoe attack."
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_weapons/dawn.dmi'
	icon_state = "philip"
	inhand_icon_state = "philip"
	damtype = RED_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP

	attack_verb_continuous = list("bashes", "crushes")
	attack_verb_simple = list("bash", "crush")
	var/activated = FALSE
	var/activestate = "philip_burn"
	var/rangeup = FALSE
	var/cost = 5
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 80,
	)

/obj/item/ego_weapon/city/dawn/dropped(mob/user)
	.=..()
	activated = FALSE
	icon_state = initial(icon_state)

/obj/item/ego_weapon/city/dawn/proc/ActiveLoop(mob/living/carbon/human/user)
	if(user.sanityhealth <= cost*2)
		activated = FALSE
		icon_state = initial(icon_state)
		to_chat(user, span_notice("The Stigma Workshop Igniter is deactivated."))
		return
	if(activated == FALSE)
		return
	user.adjustSanityLoss(cost)
	addtimer(CALLBACK(src, PROC_REF(ActiveLoop), user), 1 SECONDS)

/obj/item/ego_weapon/city/dawn/attack_self(mob/living/carbon/human/user)
	..()
	if(!CanUseEgo(user))
		return
	if(user.sanityhealth > cost*2 && activated == FALSE)
		activated = TRUE
		icon_state = activestate
		ActiveLoop(user)
		if(rangeup)
			reach = 2
			stuntime = 2
		to_chat(user, span_notice("You activate the Stigma Workshop Igniter."))
	else if(activated == TRUE)
		activated = FALSE
		icon_state = initial(icon_state)
		if(rangeup)
			reach = 1
			stuntime = 0
		to_chat(user, span_notice("You deactivate the Stigma Workshop Igniter."))
		return
	else
		to_chat(user, span_notice("The Stigma Workshop Igniter requires recharge."))


/obj/item/ego_weapon/city/dawn/attack(mob/living/target, mob/living/user)
	//Happens before the attack so you need to do another attack.
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(H.sanity_lost)
			H.death()
	..()
	if(activated == TRUE)
		target.deal_damage(force, WHITE_DAMAGE, flags = (DAMAGE_FORCED))
		DawnAttack(target, user)
	else
		target.deal_damage(force*0.5, WHITE_DAMAGE, flags = (DAMAGE_FORCED))


/obj/item/ego_weapon/city/dawn/proc/DawnAttack(mob/living/target, mob/living/carbon/human/user)
	return

//Philip's Sword
/obj/item/ego_weapon/city/dawn/sword
	name = "dawn office sword"
	desc = "A plain sword. Oddly enough, there's a semi functional heating mechanism in the hilt."
	icon_state = "philip"
	inhand_icon_state = "philip"
	force = 30
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb_continuous = list("attacks", "slashes", "stabs", "slices", "tears", "lacerates", "rips", "dices", "cuts")
	attack_verb_simple = list("attack", "slash", "stab", "slice", "tear", "lacerate", "rip", "dice", "cut")

/obj/item/ego_weapon/city/dawn/sword/DawnAttack(mob/living/target, mob/living/carbon/human/user)
	var/damage = user.sanityhealth
	target.deal_damage(damage/3, WHITE_DAMAGE, flags = (DAMAGE_FORCED))

//Yuna's Cello Case
/obj/item/ego_weapon/city/dawn/cello
	name = "dawn office cello case"
	desc = "A cello case custom-made for a fixer of the Dawn Office. The inside is filled with extendable blades..."
	icon_state = "yuna"
	inhand_icon_state = "yuna"
	activestate = "yuna_burn"
	force = 35		//Bigger range, less force
	attack_speed = 1.5
	var/aoe_range = 5
	swingstyle = WEAPONSWING_SMALLSWEEP

/obj/item/ego_weapon/city/dawn/cello/DawnAttack(mob/living/target, mob/living/carbon/human/user)
	//not if they're dead
	if(target.stat == DEAD)
		return
	playsound(src, 'sound/weapons/ego/cannon.ogg', 50, TRUE)
	for(var/turf/T in view(aoe_range, target))
		if(prob(30))
			new /obj/effect/temp_visual/fire/fast(T)
		user.HurtInTurf(T, list(), force*0.2, damtype, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_SPECIAL))

//Salvador's Zweihander
/obj/item/ego_weapon/city/dawn/zwei
	name = "dawn office zweihander"
	desc = "A zweihander fitted with a heating mechanism. The blade burns your enemy."
	icon_state = "salvador"
	inhand_icon_state = "salvador"
	activestate = "salvador_burn"
	force = 50		//Bigger range, less force
	attack_speed = 2
	reach = 1
	rangeup = TRUE
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb_continuous = list("attacks", "slashes", "stabs", "slices", "tears", "lacerates", "rips", "dices", "cuts")
	attack_verb_simple = list("attack", "slash", "stab", "slice", "tear", "lacerate", "rip", "dice", "cut")

/obj/item/ego_weapon/city/dawn/zwei/DawnAttack(mob/living/target, mob/living/carbon/human/user)
	target.apply_lc_feeble(2)
	user.apply_lc_protection(2)
	if(get_dist(target, user) >= 2)]
		swingstyle = WEAPONSWING_STAB
	else
		swingstyle = initial(swingstyle)