//Streetlight stuff, this is all Grade 7 teth stuff, leader is grade 6.
/obj/item/ego_weapon/city/streetlight_greatsword
	name = "streetlight greatsword"
	desc = "A greatsword used by a fixer with big shoes to fill.'Maybe... I should have told her how I felt.'"
	special = "This weapon has 3 modes. On Deflect, you will push back attackers. \
		On Prepared Mind, gain Protection when attacked. \
		On Fleet Footsteps, gain a movespeed buff when attacked. "
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_weapons/streetlight.dmi'
	icon_state = "streetlight_greatsword"
	force = 36
	attack_speed = 2
	swingstyle = WEAPONSWING_LARGESWEEP
	damtype = RED_DAMAGE

	inhand_icon_state = "claymore"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb_continuous = list("attacks", "slashes", "stabs", "slices", "tears", "lacerates", "rips", "dices", "cuts")
	attack_verb_simple = list("attack", "slash", "stab", "slice", "tear", "lacerate", "rip", "dice", "cut")
	var/mode = "Deflect"
	// Can be "Deflect", "Fleet" and "Prep"

/obj/item/ego_weapon/city/streetlight_greatsword/attack_self(mob/living/carbon/human/user)
	. = ..()
	switch(mode)
		if("Deflect")
			mode = "Fleet"
			to_chat(user, span_notice("You swap to Fleet Footsteps."))
		if("Fleet")
			mode = "Prep"
			to_chat(user, span_notice("You swap to Prepared Mind."))
		if("Prep")
			mode = "Deflect"
			to_chat(user, span_notice("You swap to Deflect."))

/obj/item/ego_weapon/city/streetlight_greatsword/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	. = ..()
	if(attack_type == MELEE_ATTACK && mode == "Deflect")
		goonchem_vortex(get_turf(owner), 1, 1)

	if(attack_type == MELEE_ATTACK && mode == "Prep")
		owner.apply_lc_protection(1)

	if(attack_type == MELEE_ATTACK && mode =="Fleet")
		owner.add_movespeed_modifier(/datum/movespeed_modifier/mars)
		addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/mars), 1 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

/datum/movespeed_modifier/mars
	multiplicative_slowdown = -0.1

/obj/item/ego_weapon/city/streetlight_bat
	name = "streetlight office bat"
	desc = "A yellow and black bat, its metal is warm to the touch. Is it with the warmth of friends, or the hatred of those who've had something taken from them?"
	special = "This weapon deals split damage, 20 Red and 10 White. Use in hand to charge an AOE that deals damage to the user."
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_weapons/streetlight.dmi'
	icon_state = "streetlight_bat"
	force = 20
	attack_speed = 1.5
	damtype = RED_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP

	knockback = KNOCKBACK_LIGHT
	attack_verb_continuous = list("bashes", "crushes")
	attack_verb_simple = list("bash", "crush")

	var/aoe_range = 4
	var/inuse

/obj/item/ego_weapon/city/streetlight_bat/attack(mob/living/target, mob/living/user)
	..()
	var/userjust = (get_modified_attribute_level(user, JUSTICE_ATTRIBUTE))
	var/justicemod = 1 + userjust/100
	var/damage = 10 * justicemod * force_multiplier
	target.deal_damage(damage, WHITE_DAMAGE, user, attack_type = (ATTACK_TYPE_MELEE))

/obj/item/ego_weapon/city/streetlight_bat/attack_self(mob/living/carbon/human/user)
	. = ..()
	if(!CanUseEgo(user))
		return

	if(inuse)
		return

	inuse = TRUE
	if(do_after(user, 20))	//2 Seconds for an aoe
		inuse = FALSE
		playsound(src, 'sound/weapons/ego/cannon.ogg', 50, TRUE)
		user.adjustBruteLoss(10)	//Very small.
		for(var/turf/T in view(aoe_range, user))
			if(prob(30))
				new /obj/effect/temp_visual/fire/fast(T)
			user.HurtInTurf(T, list(), force*0.5, WHITE_DAMAGE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_SPECIAL))


	inuse = FALSE

//He has zwei moves in his 2nd iteration, give it to him here.
//I wanted his to not just be strictly worse than the Zwei one so I copypasta'd and added some extra code.
/obj/item/ego_weapon/city/streetlight_baton
	name = "streetlight office baton"
	desc = "A  baton compatible with Zwei techniques. It carries a sense of regret..."
	special = "Use in hand to buff your defense and speed, and the defense and speed of everyone around you. Deals Stamina Damage."
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_weapons/streetlight.dmi'
	icon_state = "streetlight_founder"
	inhand_icon_state = "streetlight_founder"
	force = 32
	damtype = BLACK_DAMAGE
	swingstyle = WEAPONSWING_SMALLSWEEP

	attack_verb_continuous = list("bashes", "crushes")
	attack_verb_simple = list("bash", "crush")
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 40,
							TEMPERANCE_ATTRIBUTE = 40,
							JUSTICE_ATTRIBUTE = 40
							)

	var/ready = TRUE
	var/defense_buff_self = 0.8
	var/defense_buff_others = 0.7
	var/list/buffed_people = list()


/obj/item/ego_weapon/city/zweibaton/attack(mob/living/target, mob/living/carbon/human/user)
	..()
	if(!ishuman(target))
		return
	var/mob/living/carbon/human/T = target
	T.adjustStaminaLoss(force*2, TRUE, TRUE)

/obj/item/ego_weapon/city/streetlight_baton/attack_self(mob/living/carbon/human/user)
	..()
	if(!CanUseEgo(user))
		return

	if(!ready)
		return
	ready = FALSE
	user.Immobilize(3 SECONDS)
	user.physiology.red_mod *= defense_buff_self
	user.physiology.white_mod *= defense_buff_self
	user.physiology.black_mod *= defense_buff_self
	user.physiology.pale_mod *= defense_buff_self
	user.add_movespeed_modifier(/datum/movespeed_modifier/san)
	addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/san), 3 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

	to_chat(user, span_userdanger("FIGHT FOR US ALL!"))

	for(var/mob/living/carbon/human/L in orange(5, get_turf(user)))
		L.physiology.red_mod *= defense_buff_others
		L.physiology.white_mod *= defense_buff_others
		L.physiology.black_mod *= defense_buff_others
		L.physiology.pale_mod *= defense_buff_others
		buffed_people += L
		L.add_movespeed_modifier(/datum/movespeed_modifier/san)
		addtimer(CALLBACK(L, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/san), 3 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

		//Visible message just didn't work here. No clue why.
		to_chat(L, span_userdanger("FIGHT FOR US ALL!"))

	playsound(src, 'sound/misc/whistle.ogg', 50, TRUE)
	addtimer(CALLBACK(src, PROC_REF(Return), user), 3 SECONDS)

/obj/item/ego_weapon/city/streetlight_baton/proc/Return(mob/living/carbon/human/user)
	user.physiology.red_mod /= defense_buff_self
	user.physiology.white_mod /= defense_buff_self
	user.physiology.black_mod /= defense_buff_self
	user.physiology.pale_mod /= defense_buff_self
	to_chat(user, span_notice("Your defense buff has expired!"))

	for(var/mob/living/carbon/human/L in buffed_people)
		L.physiology.red_mod /= defense_buff_others
		L.physiology.white_mod /= defense_buff_others
		L.physiology.black_mod /= defense_buff_others
		L.physiology.pale_mod /= defense_buff_others
		to_chat(L, span_notice("Your defense buff has expired!"))
	buffed_people = list()

	addtimer(CALLBACK(src, PROC_REF(Cooldown), user), 15 SECONDS)

/obj/item/ego_weapon/city/streetlight_baton/proc/Cooldown(mob/living/carbon/human/user)
	ready = TRUE
	to_chat(user, span_notice("You can use your buff again."))


/datum/movespeed_modifier/san
	variable = TRUE
	multiplicative_slowdown = -0.2
