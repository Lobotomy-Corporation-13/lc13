
/obj/item/ego_weapon/lce
	icon = 'icons/obj/lce_egoweapons.dmi'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 20,
							PRUDENCE_ATTRIBUTE = 20,
							TEMPERANCE_ATTRIBUTE = 20,
							JUSTICE_ATTRIBUTE = 20
							)


//Grinder is supposed to be like the chainswords in Darktide.
/obj/item/ego_weapon/lce/grinder
	name = "LCE EGO: Grinder MK 4"
	desc = "A chainsword that reminds you of something..."
	special = "Use this weapon in hand to rev it up, making it attack 4 times in succession."
	icon_state = "grinder"
	force = 13
	attack_speed = 1	//has a very low DPS so that they can rev it up for multihits
	damtype = RED_DAMAGE
	attack_verb_continuous = list("slices", "saws", "rips")
	attack_verb_simple = list("slice", "saw", "rip")
	hitsound = 'sound/abnormalities/helper/attack.ogg'
	var/chainsaw_amount = 4
	var/revved = FALSE
	var/saw_speed = 3

/obj/item/ego_weapon/lce/grinder/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return FALSE
	if(revved)
		stuntime = 10
	..()
	if(revved)
		chainsaw_amount--
		if(chainsaw_amount)
			addtimer(CALLBACK(src, PROC_REF(attack), target, user), saw_speed)
		else
			stuntime = 0
			revved = FALSE
			chainsaw_amount = initial(chainsaw_amount)


/obj/item/ego_weapon/lce/grinder/attack_self(mob/living/user)
	if(!revved)
		revved = TRUE
		to_chat(user, span_warning("You rev up Grinder MK4."))
		balloon_alert(user, "You rev up Grinder MK4.")
	else
		revved = FALSE
		to_chat(user, span_warning("You shut off Grinder MK4."))
		balloon_alert(user, "You shut off Grinder MK4.")
	..()


/obj/item/ego_weapon/lce/smile
	name = "LCE EGO: Smile"
	desc = "Putting your hands into it is rather unpleasant."
	icon_state = "smile"
	special = "This weapon hits a second time after a windup that heals the user and slows the target."
	force = 40
	attack_speed = 1.6
	damtype = BLACK_DAMAGE
	hitsound = 'sound/weapons/ego/hammer.ogg'

/obj/item/ego_weapon/lce/smile/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return
	..()
	if(do_after(user, 7, src))
		target.deal_damage(force, BLACK_DAMAGE, user, attack_type = (ATTACK_TYPE_MELEE))
		playsound(src, 'sound/weapons/fixer/generic/gen2.ogg', 100, TRUE)
		user.adjustBruteLoss(-force/3)
	else
		to_chat(user, "<span class= 'spider'><b>Your attack was interrupted!</b></span>")
		balloon_alert(user, "Your attack was interrupted!")
		return
