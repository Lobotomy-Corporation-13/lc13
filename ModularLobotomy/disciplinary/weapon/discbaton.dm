/obj/item/ego_weapon/disc/baton
	name = "L-Corp Advanced Suppression Baton"
	desc = "A baton used by L-Corp."
	special = "Use in hand to prepare a slow attack."
	icon = 'ModularLobotomy/_Lobotomyicons/discweapons.dmi'
	icon_state = "discbat"
	force = 40
	stuntime = 7	//Does shitloads of damage.
	attack_speed = 1.5
	swingstyle = WEAPONSWING_LARGESWEEP
	damtype = RED_DAMAGE
	attack_verb_continuous = list("bats", "bashes")
	attack_verb_simple = list("bat", "bash")
	var/charged = FALSE

/obj/item/ego_weapon/disc/baton/attack(mob/living/M, mob/living/user)
	..()
	if(charged)
		M.apply_status_effect(/datum/status_effect/qliphothoverload)
		charged = FALSE

/obj/item/ego_weapon/disc/baton/attack_self(mob/user)
	if(charged)
		return
	if(do_after(user, 12, src))
		charged = TRUE
		to_chat(user,span_warning("Stun activated."))
		balloon_alert(user, "Stun activated.")
