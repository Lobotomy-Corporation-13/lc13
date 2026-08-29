//Placed in the tank category due to its ability to lifesteal during combat
/mob/living/simple_animal/hostile/rcorp_abno/easy/scarecrow
	name = "Scarecrow Searching for Wisdom"
	desc = "An abnormality taking form of a scarecrow with metal rake in place of its hand. It seems to constantly eye your head, keep it away from any corpses."
	del_on_death = FALSE
	maxHealth = 1000
	health = 1000
	rapid_melee = 2
	move_to_delay = 3
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 2)
	melee_damage_lower = 20
	melee_damage_upper = 24
	melee_damage_type = BLACK_DAMAGE
	original_abno = /mob/living/simple_animal/hostile/abnormality/scarecrow

	/// Can't move/attack when it's TRUE
	var/finishing = FALSE
	var/healthmodifier = 0.02	//Can restore up to 12% HP from a drain, lowered from its previous value due to scarecrow healing being too fast.
	var/attack_healthmodifier = 0.05 //Restores 5% of HP
	var/target_hit = FALSE
	var/hunger = FALSE

	attack_action_types = list(/datum/action/cooldown/rca_hungering)

	abno_additional_instructions = "<h1>You are Scarecrow Searching for Wisdom, A Tank Role Abnormality.</h1><br>\
		<b>|Seeking Wisdom|: When you attack corpses, You heal.<br>\
		Unlike other abnormalities which use corpses, you are able to reuse the corpses you drain as many times as you would like.<br>\
		|Hungering for Wisdom|: You have an ability which causes you to enter a 'Hungering' State.<br>\
		While you are in the 'Hungering' State, You have increased movement speed and melee damage. As well, Your melee attack heal 5% of your max HP on hit.<br>\
		You will need to hit at least on human every 6 seconds in order to keep this state active.<br>\
		However, If you don't hit any humans you will lose 5% of your max HP, become slowed down for 3.5 seconds and lose your 'Hungering' state.</b>"

/datum/action/cooldown/rca_hungering
	name = "Hungering for Wisdom"
	icon_icon = 'icons/mob/actions/actions_rcorp.dmi'
	button_icon_state = "hungering"
	desc = "Gain a short speed/damage boost to rush at your foes!"
	cooldown_time = 300
	var/speeded_up = 1.5
	var/punishment_speed = 6
	var/speed_duration = 60
	var/weaken_duration = 30
	var/min_dam_buff = 25
	var/max_dam_buff = 30
	var/min_dam_old
	var/max_dam_old
	var/old_speed

/datum/action/cooldown/rca_hungering/Trigger()
	if(!..())
		return FALSE
	if (istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/easy/scarecrow))
		var/sound/heartbeat = sound('sound/health/fastbeat.ogg', repeat = TRUE)
		var/mob/living/simple_animal/hostile/rcorp_abno/easy/scarecrow/H = owner
		if(H.hunger == TRUE)
			to_chat(H, span_nicegreen("YOU ARE RUSHING RIGHT NOW!"))
			return FALSE
		else
			old_speed = H.move_to_delay
			H.move_to_delay = speeded_up
			H.playsound_local(get_turf(H),heartbeat,40,0, channel = CHANNEL_HEARTBEAT, use_reverb = FALSE)
			H.UpdateSpeed()
			H.target_hit = FALSE
			H.color = "#ff5770"
			H.manual_emote("starts twitching...")
			H.hunger = TRUE
			min_dam_old = H.melee_damage_lower
			max_dam_old = H.melee_damage_upper
			H.melee_damage_lower = min_dam_buff
			H.melee_damage_upper = max_dam_buff
			to_chat(H, span_nicegreen("THEIR WISDOM, SHALL BE YOURS!"))
			addtimer(CALLBACK(src, PROC_REF(Hunger)), speed_duration)
			StartCooldown()

/datum/action/cooldown/rca_hungering/proc/Hunger()
	if (istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/easy/scarecrow))
		var/mob/living/simple_animal/hostile/rcorp_abno/easy/scarecrow/H = owner
		if (H.target_hit)
			addtimer(CALLBACK(src, PROC_REF(Hunger)), speed_duration)
			H.target_hit = FALSE
			to_chat(H, span_nicegreen("YOUR FEAST CONTINUES!"))
		else
			H.stop_sound_channel(CHANNEL_HEARTBEAT)
			H.melee_damage_lower = min_dam_old
			H.melee_damage_upper = max_dam_old
			H.move_to_delay = punishment_speed
			H.deal_damage(100, WHITE_DAMAGE, flags = (DAMAGE_FORCED))
			H.color = null
			H.manual_emote("starts slowing down...")
			to_chat(H, span_userdanger("No... I need that wisdom..."))
			H.target_hit = TRUE
			addtimer(CALLBACK(src, PROC_REF(RushEnd)), weaken_duration)
			H.UpdateSpeed()

/datum/action/cooldown/rca_hungering/proc/RushEnd()
	if (istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/easy/scarecrow))
		var/mob/living/simple_animal/hostile/rcorp_abno/easy/scarecrow/H = owner
		H.move_to_delay = old_speed
		to_chat(H, span_nicegreen("You calm down from your feast..."))
		H.hunger = FALSE
		H.UpdateSpeed()

/mob/living/simple_animal/hostile/rcorp_abno/easy/scarecrow/Initialize()
	. = ..()
	icon_living = "scarecrow_breach"
	icon_state = icon_living

/mob/living/simple_animal/hostile/rcorp_abno/easy/scarecrow/CanAttack(atom/the_target)
	if(finishing)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/scarecrow/Move()
	if(finishing)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/scarecrow/death(gibbed)
	density = FALSE
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/scarecrow/AttackingTarget(atom/attacked_target)
	. = ..()
	if(.)
		if(!istype(attacked_target, /mob/living/carbon/human))
			return
		target_hit = TRUE
		if (hunger == TRUE)
			adjustBruteLoss(-(maxHealth * attack_healthmodifier))
			playsound(get_turf(src), 'sound/abnormalities/scarecrow/start_drink.ogg', 50, 1)
		var/mob/living/carbon/human/H = attacked_target
		if(H.health < 0 && stat != DEAD && !finishing && H.getorgan(/obj/item/organ/brain))
			finishing = TRUE
			H.Stun(10 SECONDS)
			playsound(get_turf(src), 'sound/abnormalities/scarecrow/start_drink.ogg', 50, 1)
			SLEEP_CHECK_DEATH(2)
			for(var/i = 1 to 6)
				if(!targets_from.Adjacent(H) || QDELETED(H)) // They can still be saved if you move them away
					finishing = FALSE
					return
				playsound(get_turf(src), 'sound/abnormalities/scarecrow/drink.ogg', 50, 1)
				if(H.health < -120) //prevents infinite healing, corpse is too mangled
					break
				H.adjustBruteLoss(20)
				adjustBruteLoss(-(maxHealth * healthmodifier))
				SLEEP_CHECK_DEATH(4)
			if(!targets_from.Adjacent(H) || QDELETED(H))
				finishing = FALSE
				return
			finishing = FALSE
