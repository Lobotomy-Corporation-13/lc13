//Grade 4-5 Weapons, heal sanity on kill
/obj/item/ego_weapon/city/molar
	name = "molar chainsword"
	desc = "A chainsword used by the Molar Office. It's heavy, and well made."
	special = "This weapon loses damage over time. Use in hand to return it to full damage."
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_weapons/molar.dmi'
	icon_state = "mika"
	force = 60
	damtype = RED_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP

	attack_verb_continuous = list("slices", "saws", "rips")
	attack_verb_simple = list("slice", "saw", "rip")
	hitsound = 'sound/abnormalities/helper/attack.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 60,
	)
	var/rev_min = 30
	var/rev_max = 60
	var/on = TRUE	//To save on processing power, if we're at min power we turn off the engine.
	var/inuse

/obj/item/ego_weapon/city/molar/examine(mob/user)
	. = ..()
	. += span_notice("Rev Minimum : [rev_min]")
	. += span_notice("Rev Maximum : [rev_max]")
/obj/item/ego_weapon/city/molar/Initialize(mob/living/target, mob/living/carbon/human/user)
	..()
	RevLoop()

/obj/item/ego_weapon/city/molar/proc/RevLoop()
	if(force <= rev_min)
		on = FALSE
		//No Chainsaw? No cool sound effect.
		hitsound = 'sound/weapons/genhit1.ogg'
		return
	force --
	addtimer(CALLBACK(src, PROC_REF(RevLoop), user), 1 SECONDS)


/obj/item/ego_weapon/city/molar/attack_self(mob/living/carbon/human/user)
	..()
	if(!CanUseEgo(user))
		return

	if(inuse)
		return
	inuse = TRUE

	if(do_after(user, 10))	//1 Second to reset your weapon.
		inuse = FALSE
		//If you're not on, you have to restart the clock
		if(!on)
			on = TRUE
			addtimer(CALLBACK(src, PROC_REF(RevLoop), user), 1 SECONDS)
			hitsound = 'sound/abnormalities/helper/attack.ogg'
		force = rev_max



/obj/item/ego_weapon/city/molar/olga
	name = "molar chainknife"
	desc = "A short chainsword used by the Molar Office's leader. Its chain sings with the speed it moves at."
	icon_state = "olga"
	force = 37
	rev_min = 30
	rev_max = 60
	attack_speed = 0.7
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 60,	//She's got bad temperance, get it? Because temperance is another word for not drinking alcohol?
							JUSTICE_ATTRIBUTE = 80
							)
