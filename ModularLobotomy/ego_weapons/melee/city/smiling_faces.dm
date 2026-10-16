//Support weapons that give you fragility and strength on use.
//Designed to be used as a singlet weapon with another.

/obj/item/ego_weapon/city/smiling_faces
	name = "smiling faces shortsword"
	desc = "A shortsword, that is uncharacteristically clean."
	special = "This weapon gains smoke on hit. Use in hand to release smoke. Releasing smoke gives a strength and fragility boost for a period of time"
	icon_state = "smiling_shortsword"
	inhand_icon_state = "smiling_shortsword"
	force = 30
	damtype = RED_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP
	attack_verb_continuous = list("slices", "stabs")
	attack_verb_simple = list("slice", "stab")
	hitsound = 'sound/weapons/bladeslice.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 40,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 40,
		JUSTICE_ATTRIBUTE = 40,
	)

	var/smoke
	var/max_smoke = 10
	var/smoke_per_hit = 1
	var/smoke_active

	var/smoke_power = 2


/obj/item/ego_weapon/city/smiling_faces/examine(mob/user)
	. = ..()
	. += span_notice("Smoke : [smoke]/[max_smoke]")
	. += span_notice("Smoke Per Hit : [smoke_per_hit]")
	. += span_notice("Smoke Power : [smoke_power]")

/obj/item/ego_weapon/city/smiling_faces/attack_self(mob/living/carbon/human/user)
	..()
	if(smoke == max_smoke)
		smoke = 0
		smoke_active = FALSE
		user.apply_lc_strength(smoke_power)
		user.apply_lc_fragile(smoke_power)

/obj/item/ego_weapon/city/smiling_faces/attack(mob/living/target, mob/living/user)
	..()
	//Don't do it if they are dead
	if(target.stat == DEAD || (target.status_flags & GODMODE))
		return
	smoke += smoke_per_hit

	//If the smoke is bigger than the max, just set it back
	if(smoke > max_smoke)
		smoke = max_smoke

	if((smoke >= max_smoke) && !smoke_active)
		to_chat(user,span_warning("Your [name] has full smoke and is ready!"))
		smoke_active = TRUE


/obj/item/ego_weapon/city/smiling_faces/greatsword
	name = "smiling faces broadsword"
	desc = "A broadsword, that is uncharacteristically clean."
	icon_state = "smiling_broadsword"
	inhand_icon_state = "smiling_broadsword"
	force = 50
	swingstyle = WEAPONSWING_LARGESWEEP
	attack_speed = 2
	attack_verb_continuous = list("cleaves", "cuts")
	attack_verb_simple = list("cleaves", "cuts")
	hitsound = 'sound/weapons/fixer/generic/finisher1.ogg'


//The pipes are a bit more interesting, they gain smoke faster but have ASS damage
/obj/item/ego_weapon/city/smiling_faces/pipe
	name = "smiling faces pipe"
	desc = "A smoking pipe. Experts say it's bad for you."
	icon_state = "smiling_pipe"
	inhand_icon_state = "smiling_pipe"
	force = 20
	swingstyle = WEAPONSWING_SMALLSWEEP
	attack_verb_continuous = list("bashes", "crushes")
	attack_verb_simple = list("bash", "crush")
	hitsound = 'sound/weapons/fixer/generic/club1.ogg'
	smoke_per_hit = 2
	smoke_power = 3


/obj/item/ego_weapon/city/smiling_faces/pipe/long
	name = "smiling faces long pipe"
	desc = "A long smoking pipe. Experts say it's bad for you."
	icon_state = "smiling_longpipe"
	inhand_icon_state = "smiling_longpipe"
	swingstyle = WEAPONSWING_LARGESWEEP
	attack_speed = 1.3
	smoke_per_hit = 3
	smoke_power = 2


/obj/item/ego_weapon/city/smiling_faces/pipe/heavy
	name = "smiling faces large pipe"
	desc = "A long smoking pipe. Experts say it's bad for you."
	icon_state = "smiling_heavypipe"
	inhand_icon_state = "smiling_heavypipe"
	force = 34
	attack_speed = 1.8
	smoke_per_hit = 2
	smoke_power = 4


