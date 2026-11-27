//Yun Office.
//The Gimmick is that every weapon comes with downsides, but they all do crazy damage.

/obj/item/ego_weapon/city/yun
	name = "yun office baton"
	desc = "A stern baton. It's easy to see how callous the previous user must have been."
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_weapons/yun.dmi'
	icon_state = "yun_fixer"
	force = 18
	damtype = RED_DAMAGE

	attack_verb_continuous = list("slices", "slashes", "stabs")
	attack_verb_simple = list("slice", "slash", "stab")


//Has Great damage, but each attack lowers your Health. Getting hit at less than half HP though, will give you giga strength.
//Kinda supposed to be like the Dark Souls Tearstones.
/obj/item/ego_weapon/city/yun/shortsword
	name = "yun office shortsword"
	desc = "A shortsword of decent quality. Holding it fills you with the ambition of a pure-hearted newbie."
	special = "Deals 2 damage to the user on attack. If damaged when health is below half, get a strength and protection bonus"
	icon_state = "yun_sword"
	force = 25
	attack_speed = 0.7
	attack_verb_continuous = list("slices", "slashes", "stabs")
	attack_verb_simple = list("slice", "slash", "stab")
	hitsound = 'sound/weapons/bladeslice.ogg'
	swingstyle = WEAPONSWING_LARGESWEEP

/obj/item/ego_weapon/city/yun/shortsword/attack(mob/living/target, mob/living/user)
	if(!..())
		return
	user.adjustBruteLoss(2)

/obj/item/ego_weapon/city/yun/shortsword/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	. = ..()
	if(owner.health <= owner.maxHealth * 0.5)
		owner.apply_lc_strength(2)
		owner.apply_lc_protection(2)


//So it always applies fragile and has you take fragile if you are attacked too many times by the same thing.
/obj/item/ego_weapon/city/yun/chainsaw
	name = "yun office chainsword"
	desc = "A heavy chainsword. You'd need an augmentation to use it with only one hand. It looks pricey."
	special = "Applies Fragile on hit. When held, if attacked 3 times by the same target, applies Fragile to the user."
	icon_state = "yun_chainsword"
	force = 32
	attack_verb_continuous = list("slices", "saws", "rips")
	attack_verb_simple = list("slice", "saw", "rip")
	hitsound = 'sound/abnormalities/helper/attack.ogg'
	var/mark
	var/mark_count

/obj/item/ego_weapon/city/yun/chainsaw/attack(mob/living/target, mob/living/user)
	if(!..())
		return
	target.apply_lc_fragile(2)

/obj/item/ego_weapon/city/yun/chainsaw/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	. = ..()

	//Getting hit by the same thing three times gives you fragile.
	if(mark == hitby)
		mark_count++
		if(mark_count >= 2)
			owner.apply_lc_fragile(1)
	else
		mark_count = 0

	mark = hitby


//Grade 6, still junk
//So using the ability gives people around you protection, but the user Fragile and Speed.
/obj/item/ego_weapon/city/yun/fist
	name = "yun office gloves"
	desc = "Gloves used by the operator of yun office."
	special = "User this weapon in hand to give nearby allies protection, the user gains fragile and a movespeed buff."
	icon_state = "yun_fist"
	force = 32
	attack_verb_continuous = list("punches", "jabs", "slaps")
	attack_verb_simple = list("punches", "jabs", "slaps")
	hitsound = 'sound/weapons/punch1.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 40,
							TEMPERANCE_ATTRIBUTE = 40,
							JUSTICE_ATTRIBUTE = 40
							)
	var/inuse

/obj/item/ego_weapon/city/yun/fist/melee_attack_chain(mob/user, atom/target, params)
	..()
	hitsound = "sound/weapons/punch[pick(1,2,3,4)].ogg"

/obj/item/ego_weapon/city/yun/fist/attack_self(mob/living/carbon/human/user)
	. = ..()
	if(!CanUseEgo(user))
		return

	if(inuse)
		return
	inuse = TRUE
	if(do_after(user, 20))	//2 Seconds for a party buff.
		inuse = FALSE
		playsound(src, 'sound/misc/whistle.ogg', 50, TRUE)
		for(var/mob/living/carbon/human/L in range(3, get_turf(user)))
			if(L == user)
				continue
			L.apply_lc_protection(2)

		user.apply_lc_fragile(1)
		user.add_movespeed_modifier(/datum/movespeed_modifier/yun)
		addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/yun), 2 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

	inuse = FALSE


/datum/movespeed_modifier/yun
	multiplicative_slowdown = -0.2


