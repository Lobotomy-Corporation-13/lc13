/mob/living/simple_animal/hostile/rcorp_abno/easy/smile
	name = "Gone with a Simple Smile"
	desc = "An abnormality seeming to make up a floating cat face. Looks mischievous, might steal something if you're not careful."
	maxHealth = 400		//He's a little shit.
	health = 400
	rapid_melee = 2
	move_to_delay = 2
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 2)
	melee_damage_lower = 5
	melee_damage_upper = 5
	is_flying_animal = TRUE
	melee_damage_type = BLACK_DAMAGE
	original_abno = /mob/living/simple_animal/hostile/abnormality/smile

	ranged = 1
	retreat_distance = 3
	minimum_distance = 1

	abno_additional_instructions = "<h1>You are Gone with a Simple Smile, A Combat Role Abnormality.</h1><br>\
		<b>|Fading Smile|: Due to your immaterial nature you are capable of levitation, useful incase of chasms.<br> \
		<br>\
		|Cheshire Cat|: Your damage is harmlessly low, however when attacking a human being you will knock them down for 2 seconds. \
		Upon knocking down a human opponent you will begin pulling their weapon allowing for it to be stolen, however pulling slows you down. \
		</b>"

/mob/living/simple_animal/hostile/rcorp_abno/easy/smile/AttackingTarget(atom/attacked_target)
	. = ..()
	if(ishuman(attacked_target))
		var/mob/living/carbon/human/L = attacked_target
		L.Knockdown(20)
		var/obj/item/held = L.get_active_held_item()
		L.dropItemToGround(held) //Drop weapon


	var/list/pullable = list()
	for (var/obj/item/ego_weapon/Y in range(1, src))
		pullable += Y

	for (var/obj/item/ego_weapon/ranged/Z in range(1, src))
		pullable += Z

	if(!LAZYLEN(pullable))
		return

	src.pulled(pick(pullable))
