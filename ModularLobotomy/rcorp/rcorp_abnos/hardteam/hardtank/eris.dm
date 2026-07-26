//Tank because team healer, refer to _hardtank
/mob/living/simple_animal/hostile/rcorp_abno/hard/eris
	name = "Eris"
	desc = "A towering, intimidating woman without a mouth."
	maxHealth = 1100
	health = 1100
	ranged = TRUE
	melee_damage_lower = 11
	melee_damage_upper = 12
	move_to_delay = 2.6
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.7, WHITE_DAMAGE = 1.3, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 1)
	original_abno = /mob/living/simple_animal/hostile/abnormality/eris

	var/girlboss_level = 0

	abno_additional_instructions = "<h1>You are Eris, A Tank Role Abnormality.</h1><br>\
		<b>|Humanoid Disguise|: You are only able to attack humans who only have a very low amount of health, or if they are dead.<br>\
		If they attack a human who fulfills the above conditions, you will devor them, and gain a stack of 'Girl Boss'<br>\
		<br>\
		|Dine with me...|: Every second, you heal ALL targets that you can see.<br>\
		Your healing increases depending on the amount of 'Girl Boss' you have.<br>\
		<br>\
		|Elegant Form|: When you are attacked by a human, deal WHITE damage to the attacker. This damage is increase depending on your 'Girl Boss' stacks.</b>"

//Okay, but here's the life stuff
/mob/living/simple_animal/hostile/rcorp_abno/hard/eris/Life()
	..()
	healpulse()

//Okay, but here's the attacking stuff
/mob/living/simple_animal/hostile/rcorp_abno/hard/eris/CanAttack(atom/the_target)
	if(!ishuman(the_target))
		return FALSE
	var/mob/living/H = the_target
	if(H.stat >= SOFT_CRIT)
		return TRUE
	return FALSE

/mob/living/simple_animal/hostile/rcorp_abno/hard/eris/AttackingTarget(atom/attacked_target)
	if(ishuman(attacked_target))
		var/mob/living/H = attacked_target
		if(H.stat >= SOFT_CRIT)
			Dine(attacked_target)
			return
	..()

//Okay, but here's the cannibalism
/mob/living/simple_animal/hostile/rcorp_abno/hard/eris/proc/Dine(mob/living/carbon/human/poorfuck)
	manual_emote("unhinges her jaw, revealing many rows of teeth!")
	playsound(get_turf(src), 'sound/abnormalities/bigbird/bite.ogg', 50, 1, 2)
	if(SSmaptype.maptype == "limbus_labs")
		for(var/obj/item/organ/O in poorfuck.getorganszone(BODY_ZONE_HEAD, TRUE))
			O.Remove(poorfuck)
			O.forceMove(get_turf(poorfuck))
	poorfuck.dust()
	new /obj/effect/gibspawner/generic/silent(get_turf(poorfuck))

	//Lose sanity
	for(var/mob/living/carbon/human/H in view(10, get_turf(src)))
		H.deal_damage(girlboss_level*10, WHITE_DAMAGE, src, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))

	SLEEP_CHECK_DEATH(10)
	manual_emote("wipes her mouth with a hankerchief")
	SLEEP_CHECK_DEATH(15)
	say("Thank you for the meal, love.")
	girlboss_level += 1

//Okay, but here's the math
/mob/living/simple_animal/hostile/rcorp_abno/hard/eris/proc/healpulse()
	for(var/mob/living/H in view(10, get_turf(src)))
		if(H.stat >= SOFT_CRIT)
			continue
		//Shamelessly fucking stolen from risk of rain's teddy bear. Maxes out at 20.
		var/healamount = 20 * (TOUGHER_TIMES(girlboss_level))
		H.adjustBruteLoss(-healamount)	//Healing for those around.
		new /obj/effect/temp_visual/heal(get_turf(H), "#FF4444")

//Okay but here's the defensive options
/mob/living/simple_animal/hostile/rcorp_abno/hard/eris/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	if(. <= 0 || !isliving(source) || (attack_type & (ATTACK_TYPE_COUNTER | ATTACK_TYPE_ENVIRONMENT | ATTACK_TYPE_STATUS)))
		return
	var/mob/living/okay_but_heres_the_victim = source
	okay_but_heres_the_victim.deal_damage(40*(TOUGHER_TIMES(girlboss_level)), WHITE_DAMAGE, source = src, attack_type = (ATTACK_TYPE_COUNTER))
