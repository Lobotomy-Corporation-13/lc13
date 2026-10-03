//Jeong's Office - Grade 5, use in hand to cut your HP by 10%. Next attack deals 5x damage
//The brightest stars last half as long
/obj/item/ego_weapon/city/jeong
	name = "jeong's office wakizashi"
	desc = "A small blade, easy to keep with you. It would be nice to have on hand in a casino brawl."
	special = "On attack, draw a Hanafuda card from your deck. Use in hand to discard a card from your deck and gain 1 SP"
	icon_state = "jeong_fixer"
	force = 39
	attack_speed = 0.7
	damtype = BLACK_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP

	attack_verb_continuous = list("slices", "stabs")
	attack_verb_simple = list("slice", "stab")
	hitsound = 'sound/weapons/bladeslice.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 60,
	)
	var/list/deck = list(
				//Bright Cards
				"Red Crane and Sun",
				"Curtain",
				"Full Moon",
				"Ono no Michikaze",
				"Hoo",
				//Animal Cards
				"Bush Warbler",
				"Lesser Cuckoo",
				"Eight-Plank Bridge",
				"Butterflies",
				"Boar",
				"Geese",
				"Sake",
				"Sika Deer",
				"Barn Swallow"
				)
	var/list/discard = list()

/obj/item/ego_weapon/city/jeong/attack_self(mob/living/carbon/human/user)
	..()
	if(!CanUseEgo(user))
		return
	if(!(length(deck)))
		balloon_alert(user, "You start to shuffle your deck...")
		if(do_after(user, 14, src))
			Reload()
			return
		to_chat(user, "<span class= 'spider'><b>Your shuffle was interrupted!</b></span>")
		balloon_alert(user, "Your shuffle was interrupted!")
		return

	if(!do_after(user, 3, src))
		balloon_alert(user, "Your discard is interrupted.")
		return
	var/drawn = pick(deck)
	deck -= drawn
	discard += drawn
	user.adjustSanityLoss(-1)
	balloon_alert(user, "Discard: [drawn]")

/obj/item/ego_weapon/city/jeong/examine(mob/user)
	. = ..()
	. += span_nicegreen("Current Deck:")
	for(var/card in deck)
		. += span_nicegreen("--[card]--")
		. += span_nicegreen(CardLookup(card))
	. += span_danger("Current Discard:")

	for(var/card in discard)
		. += span_danger("++[card]++")
		. += span_danger(CardLookup(card))


/obj/item/ego_weapon/city/jeong/proc/Reload()
	//Initial didn't work?
	deck = list(
				//Bright Cards
				"Red Crane and Sun",
				"Curtain",
				"Full Moon",
				"Ono no Michikaze",
				"Hoo",
				//Animal Cards
				"Bush Warbler",
				"Lesser Cuckoo",
				"Eight-Plank Bridge",
				"Butterflies",
				"Boar",
				"Geese",
				"Sake",
				"Sika Deer",
				"Barn Swallow"
				)
	discard = initial(discard)

/obj/item/ego_weapon/city/jeong/attack(mob/living/target, mob/living/carbon/human/user)
	if(length(deck))

		//Pick a card, take from the deck and put to discard.
		var/drawn = pick(deck)
		deck -= drawn
		discard += drawn
		balloon_alert(user, "Drawn: [drawn]")


		switch(drawn)
			if("Red Crane and Sun")
				user.adjustBruteLoss(-force/5)

			if("Curtain")
				if(target.health <= target.maxHealth*0.10)
					target.adjustBruteLoss(target.health)

			if("Full Moon")
				user.adjustSanityLoss(-force/5)

			if("Ono no Michikaze")
				user.apply_lc_strength(2)

			if("Hoo")
				force *= 5

			//Animal Cards
			if("Bush Warbler")
				force *= 3
				user.apply_lc_fragile(1)

			if("Lesser Cuckoo")
				force *= 2
				user.Immobilize(3)

			if("Eight-Plank Bridge")
				user.apply_lc_protection(2)
				user.apply_lc_feeble(2)

			if("Butterflies")
				user.apply_lc_fragile(1)
				user.apply_lc_strength(2)

			if("Boar")
				user.adjustSanityLoss(10)
				user.adjustBruteLoss(-15)

			if("Geese")
				user.apply_lc_fragile(1)
				target.apply_status_effect(/datum/status_effect/qliphothoverload)

			if("Sake")
				user.apply_lc_strength(2)
				user.add_confusion(8)

			if("Sika Deer")
				user.apply_lc_fragile(1)
				user.adjustSanityLoss(-10)

			if("Barn Swallow")
				user.adjustSanityLoss(-15)
				user.adjustBruteLoss(-10)



	..()
	force = initial(force)

//Grade 4
/obj/item/ego_weapon/city/jeong/large
	name = "jeong's office katana"
	desc = "A long blade, lightweight and easy to move with. It would be simple to break up a fight with this."
	icon_state = "jeong_long"
	force = 70
	attack_speed = 1.5
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 80
							)


/obj/item/ego_weapon/city/jeong/proc/CardLookup(card)
	switch(card)
		if("Red Crane and Sun")
			return "HP is recovered by damage done"

		if("Curtain")
			return "If the target's HP is under 10%, Kill the target."

		if("Full Moon")
			return "SP is recovered by damage done"

		if("Ono no Michikaze")
			return "Gain 3 Strength"

		if("Hoo")
			return "Deal 5x Damage."

		//Animal Cards
		if("Bush Warbler")
			return "Increases damage done by 3x. Apply Fragile 1 to yourself."

		if("Lesser Cuckoo")
			return "Deal 2x Damage, but stun yourself for 0.3 seconds"

		if("Eight-Plank Bridge")
			return "Gain 2 Protection, and gain 1 Feeble"

		if("Butterflies")
			return "Gain 1 Fragile, and gain 2 Strength."

		if("Boar")
			return "Take 10 SP damage. Heal 15 HP damage."

		if("Geese")
			return "Apply slow. Gain 1 Fragile."

		if("Sake")
			return "Gain 3 Strength, and gain confusion"

		if("Sika Deer")
			return "Gain Fragile and 10 SP."

		if("Barn Swallow")
			return "Take 10 HP damage. Heal 15 SP damage."



//Go ahead. Try and make use of this weapon - Kirie/Kitsunemitsu.
