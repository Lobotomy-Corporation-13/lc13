//Ting-Tang weapons roll a D6, and apply different effects based off that.

//All weapons, but leader are grade 7, they are all quite the jobber anyways.
/obj/item/ego_weapon/city/ting_tang
	name = "ting tang shank"
	desc = "A twisted piece of metal. The shape makes very open wounds."
	icon_state = "tingtang_shank"
	inhand_icon_state = "tingtang_shank"
	force = 22
	attack_speed = 1
	damtype = WHITE_DAMAGE //Almost everyone and their mother in this god forsaken district does something with sanity.

	attack_verb_continuous = list("slices", "gashes", "stabs")
	attack_verb_simple = list("slice", "gash", "stab")
	hitsound = 'sound/weapons/fixer/generic/knife3.ogg'


/obj/item/ego_weapon/city/ting_tang/examine(mob/user)
	. = ..()
	. += span_notice("On Attack: Roll a d6.")
	. += span_notice("1: Deal 1 Damage")
	. += span_notice("5: Apply slow")
	. += span_notice("6: Deal 2x Damage and apply 2 White Fragile.")


/obj/item/ego_weapon/city/ting_tang/attack(mob/living/target, mob/living/user) //mostly stolen from dice code
	var/roll = rand(1, 6)
	balloon_alert(user, "Roll: [roll]")
	switch(roll)
		if(1)
			force = 1
		if(5)
			target.apply_status_effect(/datum/status_effect/qliphothoverload)
		if(6)
			force *= 2
			target.apply_lc_white_fragile(2)
	..()
	force = initial(force)

/obj/item/ego_weapon/city/ting_tang/cleaver
	name = "ting tang cleaver"
	desc = "It's quite heavy, clearly made for throwing your weight around."
	icon_state = "tingtang_cleaver"
	inhand_icon_state = "tingtang_cleaver"
	force = 30
	attack_speed = 1.5
	hitsound = 'sound/weapons/fixer/generic/blade5.ogg'

/obj/item/ego_weapon/city/ting_tang/pipe
	name = "ting tang pipe"
	desc = "A heavy pipe that you're pretty sure used to belong in a car."
	icon_state = "tingtang_pipe"
	inhand_icon_state = "tingtang_pipe"
	force = 38
	attack_speed = 2
	attack_verb_continuous = list("smacks", "bludgeons", "beats")
	attack_verb_simple = list("smack", "bludgeon", "beat")
	hitsound = 'sound/weapons/fixer/generic/baton1.ogg'

/obj/item/ego_weapon/city/ting_tang/knife //Leader, Grade 6
	name = "ting tang knife"
	desc = "The finger hook at the end lets you pull off some sick tricks. If you had the skill."
	icon_state = "tingtang_knife"
	inhand_icon_state = "tingtang_knife"
	force = 30
	swingstyle = WEAPONSWING_LARGESWEEP
	attack_speed = 1
	hitsound = 'sound/weapons/fixer/generic/knife1.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 40,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 40,
							JUSTICE_ATTRIBUTE = 40
							)
