//This is a Bolus is pale themed. Comes with a martial art!

/obj/item/bolus/pale
	name = "pale bolus"
	desc = "A bolus that is used for various effects."
	icon_state = "bolus_pale"
	abilities = list(
			"WOOD 5: User gained a new way to fight with their madness.",
			"WOOD 7: User gains 5 Tremor.",
			"WATER 3: User entered into a meditative sleep.",
			"WATER 10: User gained the ability to use a new martial art.",
			"FIRE 4: User is permanently, very slightly more susceptable to fire.",
			"FIRE 8: User seems to have gained very strong hand to hand combat abilities.",
			"EARTH 3: User emits a large amount of smoke",
			"EARTH 8: User gains pale protection and pale strength",
			"METAL 6: User gains a high amount of armor and immobilizes.",
			)

	var/datum/martial_art/psychotic_brawling/psychofist = new
	var/armor_mod = 5


/obj/item/bolus/pale/Bolus_Special(mob/living/carbon/human/user)
	if(wood_in >= 5)
		psychofist.teach(user)
		addtimer(CALLBACK(src, PROC_REF(RemoveMadness), user), 5 MINUTES)

	if(wood_in >= 7)
		user.apply_lc_tremor(3, 3)

	if(water_in >= 3)
		user.drowsyness += 30

	if(water_in >= 10)
		//This one is permanent
		var/datum/martial_art/null_palm/style = new
		style.teach(user, TRUE)

	if(fire_in >= 4)
		user.physiology.burn_mod *= 1.05

	if(fire_in >= 8)
		if(user.fisticuffs_bonus < 25)
			user.fisticuffs_bonus = 25	//It's pretty funny.

	if(earth_in >= 3)
		var/datum/effect_system/smoke_spread/S = new
		S.set_up(7, get_turf(user))
		S.start()
		qdel(S)

	if(earth_in >= 8)
		user.apply_lc_pale_protection(5)
		user.apply_lc_pale_strength(5)

	if(metal_in >= 6)
		user.physiology.red_mod /= armor_mod
		user.physiology.white_mod /= armor_mod
		user.physiology.black_mod /= armor_mod
		user.physiology.pale_mod /= armor_mod
		addtimer(CALLBACK(src, PROC_REF(RemoveArmor), user), 15 SECONDS)
		user.Immobilize(15 SECONDS)


/obj/item/bolus/pale/Destroy(mob/living/carbon/human/user)
	qdel(psychofist)
	..()

/obj/item/bolus/pale/proc/RemoveMadness(mob/living/carbon/human/user)
	psychofist.remove(user)

/obj/item/bolus/pale/proc/RemoveArmor(mob/living/carbon/human/user)
	user.physiology.red_mod *= armor_mod
	user.physiology.white_mod *= armor_mod
	user.physiology.black_mod *= armor_mod
	user.physiology.pale_mod *= armor_mod



//The actual martial art.
/datum/martial_art/null_palm
	name = "Null Palm"
	id = MARTIALART_NULLFIST
	help_verb = /mob/living/proc/nullpalm_help
	display_combos = FALSE

/datum/martial_art/null_palm/disarm_act(mob/living/A, mob/living/D)
	if(!can_use(A))
		return FALSE
	if(!D.stat)
		to_chat(A, "<span class='spider'>You begin to wind up an attack...</span>")
		if(!do_after(A, 4, target = D))
			to_chat(A, "<span class='spider'><b>Your attack was interrupted!</b></span>")
			return TRUE //martial art code was a mistake
		D.visible_message("<span class='danger'>[A] slams their palm into [D]!</span>", \
						"<span class='userdanger'>[A] slams their palm into you!!</span>", COMBAT_MESSAGE_RANGE, A)
		to_chat(A, "<span class='danger'>You throw all your weight into your palm striking [D]!</span>")
		playsound(get_turf(A), 'sound/weapons/cqchit1.ogg', 50, TRUE, -1)
		var/atom/throw_target = get_edge_target_turf(D, A.dir)
		D.throw_at(throw_target, 4, 3, A)
		log_combat(A, D, "attacked (CQC)")
	return TRUE

/datum/martial_art/null_palm/grab_act(mob/living/A, mob/living/D)
	if(!can_use(A))
		return FALSE
	if(!D.stat)
		if(!do_after(A, 3, target = D))
			to_chat(A, "<span class='spider'><b>Your attack was interrupted!</b></span>")
			return TRUE //martial art code was a mistake
		D.visible_message("<span class='danger'>[A] slams [D] into the ground!</span>", \
						"<span class='userdanger'>You're slammed into the ground by [A]!</span>", COMBAT_MESSAGE_RANGE, A)
		to_chat(A, "<span class='danger'>You slam [D] into the ground!</span>")
		playsound(get_turf(A), 'sound/weapons/cqchit1.ogg', 50, TRUE, -1)

		if(ishuman(D))
			D.Knockdown(20)
		if(istype(D, /mob/living/simple_animal))
			var/mob/living/simple_animal/L = D
			L.apply_status_effect(/datum/status_effect/qliphothoverload)

		log_combat(A, D, "slammed (CQC)")
	return TRUE


/mob/living/proc/nullpalm_help()
	set name = "Remember The Basics"
	set desc = "You try to remember some of the basics of Null Palm."
	set category = "Kenjitsu"
	to_chat(usr, "<b><i>You try to remember some of the basics of Null Palm.</i></b>")

	to_chat(usr, "<span class='notice'>Palm Strike</span>: Disarm. Slam your palm into your opponent after a windup.")
	to_chat(usr, "<span class='notice'>Slam</span>: Grab. Pick up your enemy and slam them down.")

