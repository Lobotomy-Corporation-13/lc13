/obj/item/organ/heart/gland/plasma
	true_name = "effluvium sanguine-synonym emitter"
	cooldown_low = 1200
	cooldown_high = 1800
	icon_state = "slime"
	uses = -1
	mind_control_uses = 1
	mind_control_duration = 800

/obj/item/organ/heart/gland/plasma/activate()
	to_chat(owner, span_warning("You feel bloated."))
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(to_chat), owner, span_userdanger("A massive stomachache overcomes you.")), 150)
	addtimer(CALLBACK(src, PROC_REF(vomit_plasma)), 200)

/obj/item/organ/heart/gland/plasma/proc/vomit_plasma()
	if(!owner)
		return
	//Burn everything around
	for(var/turf/open/T in view(3, get_turf(src)))
		if(locate(/obj/effect/turf_fire/liu) in T)
			for(var/obj/effect/turf_fire/liu/fire in T)
				qdel(fire)
		new /obj/effect/turf_fire/liu(T)
	owner.visible_message(span_warning("[owner] unleashes a wave of flames!"))
