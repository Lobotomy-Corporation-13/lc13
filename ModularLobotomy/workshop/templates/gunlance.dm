
/obj/item/ego_weapon/template/gunlance
	name = "gunlance template"
	desc = "A template for a gunlance from District 24. Popular with guards protecting the excavation sites."
	special = "This E.G.O. can fire bullets. Use in hand to load a bullet."
	icon_state = "gunlancetemplate"
	force = 25
	swingstyle = WEAPONSWING_THRUST

	attack_verb_continuous = list("cuts", "slices")
	attack_verb_simple = list("cuts", "slices")
	hitsound = 'sound/weapons/ego/sword2.ogg'
	var/gun_loaded

	finishedicon = list("finishedgunlance")
	finishedname = list("gunlance", "gunspear")
	finisheddesc ="A gunlance from District 24, ready to use. Popular with guards protecting the excavation sites."

/obj/item/ego_weapon/template/gunlance/attack_self(mob/living/carbon/user)
	if(do_after(user, 35 * attack_speed, src))
		gun_loaded = TRUE
		to_chat(user, span_notice("You load a bullet."))
		balloon_alert(user, "You load a bullet")

/obj/item/ego_weapon/template/gunlance/afterattack(atom/target, mob/living/user, proximity_flag, clickparams)
	if(!CanUseEgo(user) && !active)
		return
	if(!proximity_flag && gun_loaded)
		var/turf/proj_turf = user.loc
		if(!isturf(proj_turf))
			return
		var/obj/projectile/ego_bullet/gunlance/G = new /obj/projectile/ego_bullet/gunlance(proj_turf)
		G.fired_from = src
		playsound(user, 'sound/weapons/gun/shotgun/shot_alt.ogg', 100, TRUE)
		G.firer = user
		G.damage = force
		G.damage_type = damtype
		G.preparePixelProjectile(target, user, clickparams)
		G.fire()
		gun_loaded = FALSE
		return

/obj/projectile/ego_bullet/gunlance
	name = "gunlance bullet"
	damage = 25
	damage_type = RED_DAMAGE
