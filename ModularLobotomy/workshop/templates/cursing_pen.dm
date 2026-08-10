/obj/item/ego_weapon/template/cursing_pen
	name = "cursed pen template"
	desc = "Ink and casing for a cursepen. Rather popular with Hana administration and P-Corporation staff."
	special = "This weapon marks enemies with the associated damage type. They take that damage after 5 seconds."
	icon_state = "pentemplate"
	force = 20
	hitsound = 'sound/abnormalities/book/scribble.ogg'
	attack_verb_continuous = list("scribes", "scribles")
	attack_verb_simple = list("scribe", "scrible")

	var/mark_damage
	finishedicon = list("finishedpen")
	finishedname = list("executive cursed pen", "cursed pen", "cursed fountain pen")
	finisheddesc = "A cursed pen, ready for use. Rather popular with Hana administration and P-Corporation staff."


//Replaces the normal attack with a mark
/obj/item/ego_weapon/template/cursing_pen/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return
	..()
	if(do_after(user, 5 * attack_speed, src))
		playsound(loc, hitsound, 120, TRUE, extrarange = stealthy_audio ? SILENCED_SOUND_EXTRARANGE : -1, falloff_distance = 0)
		target.visible_message(span_danger("[user] markes [target]!"), \
						span_userdanger("[user] marks you!"), COMBAT_MESSAGE_RANGE, user)
		to_chat(user, span_danger("You enscribe a code on [target]!"))
		balloon_alert(user, "You enscribe a code on [target]!")

		mark_damage = force*2
		//I gotta grab  justice here
		var/userjust = (get_modified_attribute_level(user, JUSTICE_ATTRIBUTE))
		var/justicemod = 1 + userjust/100
		mark_damage *= justicemod
		mark_damage *= force_multiplier

		var/obj/effect/infinity/P = new get_turf(target)
		if(damtype == RED_DAMAGE)
			P.color = COLOR_RED

		if(damtype == PALE_DAMAGE)
			P.color = COLOR_CYAN

		if(damtype == BLACK_DAMAGE)
			P.color = COLOR_PURPLE

		addtimer(CALLBACK(src, PROC_REF(cast), target, user), 5 SECONDS * attack_speed)

	else
		to_chat(user, "<span class='spider'><b>Your attack was interrupted!</b></span>")
		balloon_alert(user, "Your attack was interrupted!")
		return

/obj/item/ego_weapon/template/cursing_pen/proc/cast(mob/living/target, mob/living/user)
	target.deal_damage(mark_damage, damtype, user, attack_type = (ATTACK_TYPE_SPECIAL))
	playsound(loc, 'sound/weapons/fixer/generic/energyfinisher3.ogg', 15, TRUE, extrarange = stealthy_audio ? SILENCED_SOUND_EXTRARANGE : -1, falloff_distance = 0)
	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(target), pick(GLOB.alldirs))
	mark_damage = force
