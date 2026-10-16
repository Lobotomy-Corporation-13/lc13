//Support weapons that give a random ally strength on use in hand.
//Grade 6 weapons.

/obj/item/ego_weapon/city/musician
	name = "cat's claw"
	desc = "A sword used by a long lost musician."
	special = "User this weapon in hand to give a random ally nearby Strength."
	icon_state = "meow"
	inhand_icon_state = "meow"
	force = 30
	damtype = RED_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP
	attack_verb_continuous = list("slices", "stabs")
	attack_verb_simple = list("slice", "stab")
	hitsound = 'sound/weapons/bladeslice.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 40,
		PRUDENCE_ATTRIBUTE = 40,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 40,
	)
	var/inuse

/obj/item/ego_weapon/city/musician/attack_self(mob/living/carbon/human/user)
	. = ..()
	if(!CanUseEgo(user))
		return

	if(inuse)
		return
	inuse = TRUE
	if(do_after(user, 20))	//2 Seconds for a minor strength buff.
		inuse = FALSE
		playsound(src, 'sound/magic/staff_healing.ogg', 200, FALSE, 9)
		var/mob/living/carbon/human/lucky
		var/list/nearby_players
		for(var/mob/living/carbon/human/L in range(5, get_turf(user)))
			if(L == user)
				return
			nearby_players +=L

		lucky = pick(nearby_players)
		lucky.apply_lc_strength(1)

	inuse = FALSE


/obj/item/ego_weapon/city/musician/bat
	name = "heavy peaks"
	desc = "A bat that eminates music."
	icon_state = "musician_bat"
	inhand_icon_state = "musician_bat"
	force = 40
	attack_speed = 1.6
	knockback = KNOCKBACK_LIGHT
	swingstyle = WEAPONSWING_SMALLSWEEP
	attack_verb_continuous = list("bashes", "crushes")
	attack_verb_simple = list("bash", "crush")
	hitsound = 'sound/weapons/fixer/generic/club1.ogg'

/obj/item/ego_weapon/city/musician/hammer
	name = "hard rehersal"
	desc = "A hammer that sings when swung."
	icon_state = "musician_hammer"
	inhand_icon_state = "musician_hammer"
	knockback = KNOCKBACK_HEAVY
	force = 55
	attack_speed = 2
	swingstyle = WEAPONSWING_SMALLSWEEP
	attack_verb_continuous = list("bashes", "crushes")
	attack_verb_simple = list("bash", "crush")
	hitsound = 'sound/weapons/fixer/generic/club1.ogg'
