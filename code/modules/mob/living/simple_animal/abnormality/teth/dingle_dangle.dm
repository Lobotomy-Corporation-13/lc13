#define STATUS_EFFECT_DANGLE /datum/status_effect/dangle
/mob/living/simple_animal/hostile/abnormality/dingledangle
	name = "Dingle-Dangle"
	desc = "A cone that goes up to the ceiling with a ribbon tied around it. Bodies are strung up around it, seeming to be tied to the ceiling."
	icon = 'ModularLobotomy/_Lobotomyicons/64x96.dmi'
	icon_state = "dangle"
	portrait = "dingle_dangle"
	maxHealth = 600
	health = 600
	threat_level = TETH_LEVEL
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(70, 60, 40, 40, 40),
		ABNORMALITY_WORK_INSIGHT = list(30, 40, 70, 70, 70),
		ABNORMALITY_WORK_ATTACHMENT = 40,
		ABNORMALITY_WORK_REPRESSION = 40,
	)
	start_qliphoth = 3
	pixel_x = -16
	base_pixel_x = -16
	work_damage_amount = 8
	work_damage_type = WHITE_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/envy

	ego_list = list(
		/datum/ego_datum/weapon/lutemia,
		/datum/ego_datum/armor/lutemia
	)
	gift_type = /datum/ego_gifts/lutemis
	gift_message = "Let's all become fruits. Let's hang together. Your despair, sadness... Let's all dangle down."
	abnormality_origin = ABNORMALITY_ORIGIN_WONDERLAB

	observation_prompt = "You pass by the containment cell and, in the corner of your eye, spy your comrades dangling from ribbons, furiously scratching at their necks in choked agony."
	observation_choices = list(
		"Save them" = list(TRUE, "Regardless of your resolution, you find yourself before the tree anyway as one of its ribbons wrap around your neck. <br>\
			\"Let's dangle together, let your sorrows, your pain dangle, let's all dangle down...\" <br>It whispers into your mind. <br>\
			Your comrades were never here, the life passes from your body painlessly. <br> None of this is real."),
		"Do not save them" = list(TRUE, "Regardless of your resolution, you find yourself before the tree anyway as one of its ribbons wrap around your neck. <br>\
			\"Let's dangle together, let your sorrows, your pain dangle, let's all dangle down...\" <br>It whispers into your mind. <br>\
			Your comrades were never here, the life passes from your body painlessly. <br> None of this is real."),
	)

	var/fragility_stacks
	var/empower_stacks


/mob/living/simple_animal/hostile/abnormality/dingledangle/Life()
	..()
	//~0.5% chance for each stack
	if(prob(100 - (fragility_stacks+empower_stacks) *0.5 ))
		return

	var/list/targets = list()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.z!=z)
			continue
		targets+=H
	
	if(!length(targets))
		return

	if(fragility_stacks)
		var/mob/living/carbon/human/Y = pick(targets)
		Y.apply_lc_white_fragile(1)
		Y.balloon_alert(Y, "You feel the tree calling out for your sorrows.")
		fragility_stacks--

	SLEEP_CHECK_DEATH(20)
	//Force a 2 second break between them

	if(empower_stacks)
		var/mob/living/carbon/human/Y = pick(targets)
		Y.apply_lc_white_strength(2)
		Y.balloon_alert(Y, "You feel the tree whispering in your mind.")
		empower_stacks--


//Introduction to our hallucinations. This is a global hallucination, but it's all it really does.
/mob/living/simple_animal/hostile/abnormality/dingledangle/ZeroQliphoth(mob/living/carbon/human/user)
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		H.hallucination += 10

	fragility_stacks+=3	//Get 3 Fragility Stacks to release later
	datum_reference.qliphoth_change(3)

/mob/living/simple_animal/hostile/abnormality/dingledangle/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time, canceled)
	//give it some empowerment to use.
	empower_stacks+=2

	//if your prudence is low, give a short hallucination, apply empowerment and lower counter.
	if(get_attribute_level(user, PRUDENCE_ATTRIBUTE) < 40) // below level 2
		user.hallucination += 20
		empower_stacks += 4
		datum_reference.qliphoth_change(-1)
		return ..()

	if(get_attribute_level(user, FORTITUDE_ATTRIBUTE) >= 80) // fort 4 or higher
		return ..()

	if(get_attribute_level(user, PRUDENCE_ATTRIBUTE) < 60) // below level 3, don't dust.
		return ..()

	//If you dust, release a shitload of empowerment into the system
	empower_stacks+=10

	//I mean it does this in wonderlabs
	//But here's the twist: You get a better ego.
	user.client?.give_award(/datum/award/achievement/abno/lutemis, user)
	if(user && !canceled)
		var/location = get_turf(user)
		new /obj/item/clothing/suit/armor/ego_gear/he/lutemis(location)
	if(user?.stat != DEAD) //dusting sets you dead before the animation, we don't want to dust user twice after failing work
		user.dust()

/mob/living/simple_animal/hostile/abnormality/dingledangle/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	fragility_stacks+=5	//Get 5 Fragility Stacks
