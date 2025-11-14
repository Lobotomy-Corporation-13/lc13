/mob/living/simple_animal/hostile/limbus_abno/laetitia
	true_name = "Laetitia"
	maxHealth = 1500
	health = 1500
	melee_damage_lower = 1
	melee_damage_upper = 5
	melee_damage_type = WHITE_DAMAGE
	faction = list("laetitia") //I generally try to avoid faction with LCL abnos, but her summons might try to kill her otherwise. I'll make a summon subtype later, maybe.
	abno_additional_instructions = "You like instinct and attachment. You love friends and pranks. \
	You're a little shy, but you still want your friends to have fun! If you're too bored, you'll start giving gifts left and right! \
	But wait about ten minutes before the big surprise, a prank's no fun without some setup!"
	original_abno = /mob/living/simple_animal/hostile/abnormality/laetitia
	diet_list = list(/obj/item/food/cake, /obj/item/food/cakeslice, /obj/item/food/chocolatebar, /obj/item/food/candy)
	attack_action_types = list(/datum/action/cooldown/limbus_abno_action/laetitia_surprise,
	/datum/action/cooldown/limbus_abno_action/laetitia_gifting,
	/datum/action/cooldown/limbus_abno_action/special_delivery)
	diet_value = 60
	desire_cooldown_time = 30 SECONDS
	desire_loss = 5
	desire_on_pet = 40
	desire_on_eat = 20
	rep_desire_gain = -50
	ego_list = list(
		/datum/ego_datum/weapon/prank,
		/datum/ego_datum/armor/prank,
	)
	var/happy_duration_time = 5 MINUTES
	var/happy_duration
	var/gifting = FALSE
	var/anticipation_start = FALSE
	var/base_anticipation = -100
	var/max_anticipation = 150
	var/anticipation = -100
	var/anticipation_cooldown_time = 1 MINUTES
	var/anticipation_cooldown
	var/anticipation_increase_value = 20

	var/patience = 0
	var/max_patience = 3
	var/list/victim_list = list()
	var/list/possible_gifts = list(/obj/item/food/candy, /obj/item/food/chocolatebar, /obj/item/food/cake/birthday, /obj/item/food/pizza/margherita) //If the gifts are healing, spawns one of those items.

/mob/living/simple_animal/hostile/limbus_abno/laetitia/AttackingTarget(atom/attacked_target)
	if(!isliving(attacked_target))
		return ..()
	if(gifting && isliving(attacked_target))
		to_chat(attacked_target, "<span class='span_warning'>[src] playfully pokes you in the ribs.</span>") //This one is a dead give away, but won't play an attack animation.
		GiveFriend(attacked_target, TRUE)
		return FALSE
	else
		return ..()

/mob/living/simple_animal/hostile/limbus_abno/laetitia/funpet(mob/living/carbon/human/petter)
	..()
	petter.adjustWhiteLoss(-10) //This actually heals your sanity, but...
	if(gifting)
		GiveFriend(petter)

/mob/living/simple_animal/hostile/limbus_abno/laetitia/Life()
	. = ..()

	if(anticipation_start && anticipation_cooldown < world.time)
		anticipation_cooldown = world.time + anticipation_cooldown_time
		anticipation = clamp(anticipation_increase_value + anticipation, base_anticipation, max_anticipation)

	if(desire_bar > 60 && anticipation_start)
		if(isnull(happy_duration))
			happy_duration = world.time + happy_duration_time
		if(happy_duration < world.time)
			FunOver(FALSE)
		return .

	happy_duration = null //Reset the timer
	return .

/mob/living/simple_animal/hostile/limbus_abno/laetitia/attackby(obj/item/W, mob/user, params)
	. = ..()
	if(gifting && isliving(user))
		GiveFriend(user)

/mob/living/simple_animal/hostile/limbus_abno/laetitia/bullet_act(obj/projectile/P)
	. = ..()
	if(gifting && isliving(P.firer))
		GiveFriend(P.firer)

/mob/living/simple_animal/hostile/limbus_abno/laetitia/death()
	. = ..()
	if(anticipation_start)
		Surprise()

/mob/living/simple_animal/hostile/limbus_abno/laetitia/AdjustDesire(desire_amount)
	..()
	if(desire_bar > 0)
		return

	patience++
	if(patience > max_patience)
		patience = 0
		GiveGlobalFriend()

/mob/living/simple_animal/hostile/limbus_abno/laetitia/proc/GiveGlobalFriend()
	to_chat(src, "<span class='span_warning'>Things are too boring around here, so you decide to shake things up!</span>")
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.z != z)
			continue
		if(H.stat == DEAD)
			continue
		GiveFriend(H)

/mob/living/simple_animal/hostile/limbus_abno/laetitia/proc/GiveFriend(mob/living/victim, busted = FALSE)
	if(victim_list.Find(victim) || victim.stat == DEAD)
		return

	anticipation_start = TRUE
	gifting = FALSE
	to_chat(src, "<span class='span_warning'>[victim] got a funny gift! </span>")
	if(rand(1, 5) == 5 || busted) //1 chance out of 5 to notice unless busted is set to true.
		to_chat(victim, "<span class='span_warning'>You hear a high pitched, child-like laugh. </span>")
	AdjustDesire(50) //This makes her happier, which also makes it harder to spam.
	victim_list += victim

///Spawns a friend from every person in the victim list at once, unless the anticipation is negative. Get pranked, silly!
/mob/living/simple_animal/hostile/limbus_abno/laetitia/proc/Surprise()
	for(var/mob/living/victim in victim_list)
		if(QDELETED(victim))
			continue

		var/hurtful = FALSE //Friendly and harmless if false, agressive spawns if not.
		var/surprise_string = "<span class='span_userdanger'>Something emerges from you! You feel... "
		if(anticipation < 0)
			surprise_string += "healthier?"
		else if(anticipation == 0)
			surprise_string += "nothing?"
		else
			hurtful = TRUE
			surprise_string += "terrible!"
		surprise_string += " </span>"
		to_chat(victim, surprise_string)
		var/turf/victim_turf = get_turf(victim)
		victim.adjustRedLoss(round(anticipation, 1))
		if(hurtful)
			var/mob/living/simple_animal/hostile/gift/gift_friend = new (victim_turf)
			friend_list += gift_friend
			gift_friend.faction = list("laetitia")
			if(IsFriend(victim))
				gift_friend.faction.Add("Neutral")
		else
			var/obj/item/special_gift = pick(possible_gifts) //Teehee, just kidding!
			new special_gift(victim_turf)

	playsound(get_turf(src), 'sound/abnormalities/laetitia/spider_born.ogg', 50, 1)
	FunOver()

///If her desire is kept above 50 for five minute straight, empty the victim list.
/mob/living/simple_animal/hostile/limbus_abno/laetitia/proc/FunOver(pranked = TRUE)
	victim_list = list()
	anticipation = base_anticipation
	anticipation_start = FALSE
	happy_duration = null
	if(!pranked)
		to_chat(src, "<span class='span_userdanger'>You feel like your prank isn't good enough, you decide to take away all their gifts without them noticing. Maybe next time?</span>")

///Surprise!!! Activate every single gift at once.
/datum/action/cooldown/limbus_abno_action/laetitia_surprise
	name = "SURPRISE!"
	desc = "Open every single gift that's inside people (not counting special deliveries)! But don't do it too early, or it will be boring! You need to be bored to use this."
	icon_icon = 'icons/effects/blood.dmi'
	button_icon_state = "floor5"
	transparent_when_unavailable = TRUE
	cooldown_time = 5 MINUTES
	desire_req = 50

/datum/action/cooldown/limbus_abno_action/laetitia_surprise/Trigger()
	var/mob/living/simple_animal/hostile/limbus_abno/laetitia/prankster = abno_user
	if(!prankster.victim_list.len)
		to_chat(abno_user, span_notice("What's the point of opening a gift all by yourself? You have to give away some first!"))
		return FALSE
	. = ..()
	if(!.)
		return FALSE
	prankster.Surprise()
	StartCooldown()
	return TRUE

///Turns the 'gifting' variable true, meaning anyone laetitia attacks, gets attacked by, or gets petted by will be infected with a gift.
/datum/action/cooldown/limbus_abno_action/laetitia_gifting
	name = "Give gift"
	desc = "The next person that you attack, that hits you, or pets you is going to get a nice gift! You need to be bored to use this."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/tegu_effects.dmi'
	button_icon_state = "prank_gift"
	transparent_when_unavailable = TRUE
	cooldown_time = 2 MINUTES
	desire_req = 50

/datum/action/cooldown/limbus_abno_action/laetitia_gifting/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/laetitia/prankster = abno_user
	prankster.gifting = TRUE
	StartCooldown()
	return TRUE

/datum/action/cooldown/limbus_abno_action/special_delivery
	name = "Special Delivery"
	desc = "Create a 'normal' gift that has a 50% chance to explode, or to hold a few healing items. You can tell which it is once you've made one, but others can't."
	icon_icon = 'icons/obj/storage.dmi'
	button_icon_state = "giftdeliverypackage3"
	transparent_when_unavailable = TRUE
	cooldown_time = 2 MINUTES

/datum/action/cooldown/limbus_abno_action/special_delivery/Trigger()
	. = ..()
	if(!.)
		return
	var/obj/item/laetitia_bomb_gift/bomb_gift = new (get_turf(abno_user))
	abno_user.AdjustDesire(20)
	bomb_gift.pranked = rand(0, 1)
	StartCooldown()

/obj/item/laetitia_bomb_gift
	name = "Laetitia's special gift."
	desc = "No matter how much you shake the gift, you can't begin to guess what's inside."
	icon = 'icons/obj/storage.dmi'
	icon_state = "giftdeliverypackage3"
	inhand_icon_state = "gift"
	resistance_flags = FLAMMABLE

	var/pranked = FALSE
	var/good_item_spawned = 3 //High risk high reward.
	var/list/good_items = list(
	/obj/item/reagent_containers/hypospray/medipen/mental,
	/obj/item/reagent_containers/hypospray/medipen/salacid,
	/obj/item/reagent_containers/hypospray/medipen/stimpack/traitor,
	/obj/item/reagent_containers/hypospray/medipen/oxandrolone)

/obj/item/laetitia_bomb_gift/examine(mob/user)
	. = ..()
	if(istype(user, /mob/living/simple_animal/hostile/limbus_abno/laetitia))
		if(pranked)
			. += span_notice("That's a lie, you know what's inside. This one's gonna blow up!")
		else
			. += span_notice("Okay, you can tell what's inside, but it's full of boring healing stuff, so you don't really care.")

/obj/item/laetitia_bomb_gift/attack_self(mob/user)
	var/turf/gift_turf = get_turf(src)
	if(pranked)
		explosion(gift_turf, 0, 0, 2, 3, 0, TRUE, FALSE, 0, TRUE) //It hurts like hell and will probably take off limbs, but it's supposed to be a risky gamble.
		playsound(get_turf(src), 'sound/effects/explosion1.ogg', 30, 1) //We call the sound manually to not make them deal with the annoying deafening effect.
	else
		for(var/i = 1 to good_item_spawned)
			var/item_type = pick(good_items)
			new item_type (gift_turf)
	qdel(src)
