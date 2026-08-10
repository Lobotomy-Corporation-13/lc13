
/obj/item/ego_weapon/template/blood_dagger
	name = "blood dagger template"
	desc = "A template for a dagger with an IV tube to attach to your hand. Popular in the backstreets of District 23."
	special = "Use this weapon in hand to increase damage and apply bleed to self."
	icon_state = "blooddaggertemplate"
	force = 22
	swingstyle = WEAPONSWING_THRUST
	attack_verb_continuous = list("stabs", "attacks", "slashes")
	attack_verb_simple = list("stab", "attack", "slash")
	hitsound = 'sound/weapons/ego/rapier1.ogg'

	finishedicon = list("finishedblooddagger")
	finishedname = list("blood dagger", "blood knife")
	finisheddesc ="A dagger with an IV to attach to your hand. Popular in the backstreets of District 23."

/obj/item/ego_weapon/template/blood_dagger/attack_self(mob/living/carbon/user)
	if(!CanUseEgo(user))
		return
	if(!active)
		return
	user.apply_lc_bleed(5)
	user.apply_lc_strength(2)
	to_chat(user,span_warning("Yearning drains your blood... And gives you strength"))
	balloon_alert(user, "Yearning drains your blood... And gives you strength")
