//Los Mariachis - Grade 7 with poise crits, white version of Kurokumo.
/obj/item/ego_weapon/city/mariachi
	name = "maraca"
	desc = "A single maraca used by Los Mariachis."
	special = "This weapon gains 1 poise for every attack. 1 poise gives you a 2% chance to crit at 3x damage, stacking linearly. Critical hits reduce poise to 0."
	icon_state = "maracas"
	inhand_icon_state = "maracas"
	force = 22
	damtype = WHITE_DAMAGE

	attack_verb_continuous = list("bashes", "clubs")
	attack_verb_simple = list("bashes", "clubs")
	hitsound = 'sound/weapons/fixer/generic/maracas1.ogg'
	var/poise = 0

/obj/item/ego_weapon/city/mariachi/examine(mob/user)
	. = ..()
	. += "Current Poise: [poise]/20."

/obj/item/ego_weapon/city/mariachi/attack(mob/living/target, mob/living/carbon/human/user)
	if(!CanUseEgo(user))
		return
	poise+=1
	if(poise>= 20)
		poise = 20

	//Crit itself.
	if(prob(poise*2))
		force*=3
		to_chat(user, span_userdanger("Critical!"))
		poise = 0
	..()
	force = initial(force)

/obj/item/ego_weapon/city/mariachi/attack_self(mob/user)
	var/obj/item/clothing/suit/armor/ego_gear/city/mariachi/aida/Y = user.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(istype(Y))
		to_chat(user,span_notice("You shake the maracas. Your performance is beautiful."))
		playsound(src, 'sound/weapons/fixer/generic/maracas_shake.ogg', 50, TRUE)
	else
		to_chat(user,span_warning("Someone as uninspiring as you? You are not worthy to shake the maracas."))

//Sp healing for jobbers
/obj/item/ego_weapon/city/mariachi_blades
	name = "dual machetes"
	desc = "A pair of machetes used by the Los Mariachis."
	special = "On kill, heal 15 sanity."
	icon_state = "mariachi_blades"
	inhand_icon_state = "mariachi_blades"
	force = 22
	damtype = WHITE_DAMAGE

	attack_verb_continuous = list("slashes", "slices")
	attack_verb_simple = list("slash", "slice")
	hitsound = 'sound/weapons/fixer/generic/blade1.ogg'

/obj/item/ego_weapon/city/mariachi_blades/attack(mob/living/target, mob/living/carbon/human/user)
	var/living = FALSE
	if(!CanUseEgo(user))
		return
	if(target.stat != DEAD)
		living = TRUE
	..()
	if(target.stat == DEAD && living)
		user.adjustSanityLoss(-15)
		living = FALSE

//Leader, Grade 6 (She's pretty weak)
/obj/item/ego_weapon/city/mariachi/dual
	name = "maracas"
	desc = "A pair of maracas used by the leader of Los Mariachis."
	icon_state = "dualmaracas"
	inhand_icon_state = "dualmaracas"
	force = 19		//Double the maracas twice the attack speed.
	attack_speed = 0.5
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 40,
							TEMPERANCE_ATTRIBUTE = 40,
							JUSTICE_ATTRIBUTE = 40
							)

//Pre-nerf Aida, the real prize of J-corp. Grade 5
/obj/item/ego_weapon/city/mariachi/dual/boss
	name = "glowing maracas"
	desc = "A pair of glowing maracas used by the leader of Los Mariachis. Only seen by the no longer living."
	icon_state = "dualmaracas_boss"
	inhand_icon_state = "dualmaracas_boss"
	force = 25
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)
