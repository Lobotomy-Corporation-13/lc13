///Unlike most LCL abnormality, this one gets most of its abilities with few requirements. It can't really fight, but it sure as hell can be annoying.
///Due to its incredibly low health, the player is going to need to learn the hard way that there's a limit to how much you can mess with people before they just kill you.
/mob/living/simple_animal/hostile/limbus_abno/simple_smile
	true_name = "Gone with a Simple Smile"
	maxHealth = 400
	health = 400
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 2)
	original_abno = /mob/living/simple_animal/hostile/abnormality/smile
	attack_action_types = list(/datum/action/cooldown/limbus_abno_action/smile_gobble,
	/datum/action/cooldown/limbus_abno_action/smile_puke,
	/datum/action/cooldown/limbus_abno_action/smile_hoard,
	/datum/action/cooldown/limbus_abno_action/smile_id_bump,
	/datum/action/cooldown/limbus_abno_action/smile_knockdown)
	abno_additional_instructions = "You like nothing more than to mess with people and vanish without a trace. \
	You gain desire from stealing things from people, and send them on a wild goose chase to get it back.\
	You CANNOT eat things or knockdown people by default, and instead need to rely on your abilities to do so. So try to plan your mischief ahead if you can.\
	You produce ego much faster than other abnormalities, use this as a bargaining chip if they ever get tired of your antics."
	diet_list = list(/obj/item)
	hunger_cooldown_time = 15 SECONDS
	desire_cooldown_time = 30 SECONDS
	desire_loss = 5
	desire_on_eat = 30
	diet_value = 20
	delete_food = FALSE
	ego_list = list(
		/datum/ego_datum/weapon/trick,
		/datum/ego_datum/armor/trick,
	)
	ego_desire_gained = 15 //Creates ego really fast due to how annoying it is. Literally the only reason not to shoot it on sight beyond the roleplay aspect.
	var/gobble = FALSE //If smile will eat the things it attacks.
	var/max_gobble = 3 //How many things can be gobbled up at once.
	var/list/gobbled_things = list()
	var/turf/treasure_turf

	var/id_bump = FALSE
	var/knockdown_count = 3
	var/max_knockdown = 3

/mob/living/simple_animal/hostile/limbus_abno/simple_smile/Initialize()
	. = ..()
	treasure_turf = get_turf(src)

/mob/living/simple_animal/hostile/limbus_abno/simple_smile/UnarmedAttack(atom/A, proximity)
	. = ..()
	if(!iscarbon(A))
		return

	var/mob/living/carbon/victim = A
	if(id_bump)
		var/obj/item/card/id/id_card = victim.get_idcard()
		if(id_card)
			AdjustDesire(30)
			id_card.forceMove(get_turf(victim))
			id_bump = FALSE

	if(knockdown_count < max_knockdown)
		AdjustDesire(30)
		victim.Knockdown(20)
		var/obj/item/held = victim.get_active_held_item()
		victim.dropItemToGround(held) //The classic.
		knockdown_count++

/mob/living/simple_animal/hostile/limbus_abno/simple_smile/AbnoEat(food)
	var/obj/object = food
	if(!gobble || istype(object, /obj/item/bodypart/head))
		return FALSE
	if((object.resistance_flags & INDESTRUCTIBLE) || object.anchored) //Letting it eat nearly anything is 100% going to bite me in the ass somehow but fuck it, it's funny.
		return FALSE

	. = ..()
	if(!.)
		return FALSE
	gobbled_things += object
	object.forceMove(src) //This cat just ate my fucking ID.
	if(gobbled_things.len >= max_gobble)
		gobble = FALSE

/mob/living/simple_animal/hostile/limbus_abno/simple_smile/updatehealth()
	..()
	if(health <= 150 && gobbled_things.len)
		PukeOut()

/mob/living/simple_animal/hostile/limbus_abno/simple_smile/proc/PukeOut()
	var/turf/T = get_turf(src)
	for(var/obj/item/I in contents)
		if(gobbled_things.Find(I))
			playsound(get_turf(src), 'sound/effects/splat.ogg', 50, TRUE)
			gobbled_things -= I
			I.forceMove(T)

///The ability to eat things outright. Can't do it by default and needs to activate this ability first, giving them a limited amount of things to eat before the ability runs out.
/datum/action/cooldown/limbus_abno_action/smile_gobble
	name = "Borrow"
	desc = "Gives you the ability to eat the next few objects you attack. Nearly anything that isn't nailed down or alive can be absorbed. If they want it back, they'll have to beat it out of you."
	icon_icon = 'icons/mob/actions/actions_animal.dmi'
	button_icon_state = "coffer"
	transparent_when_unavailable = TRUE
	cooldown_time = 30 SECONDS
	desire_req = 80

/datum/action/cooldown/limbus_abno_action/smile_gobble/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/simple_smile/smile = abno_user
	smile.gobble = TRUE
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/smile_puke
	name = "Let it out"
	desc = "Pukes out all that you ate. Does not affect your hunger or desire bar."
	icon_icon = 'icons/mob/actions/actions_xeno.dmi'
	button_icon_state = "alien_barf"
	cooldown_time = 10 SECONDS

/datum/action/cooldown/limbus_abno_action/smile_puke/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/simple_smile/smile = abno_user
	if(!smile.gobbled_things.len)
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/smile_puke/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/simple_smile/smile = abno_user
	smile.PukeOut()
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/smile_hoard
	name = "Hoard"
	desc = "Teleports you and anything you're dragging back to your cell."
	icon_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = "nos_teleport"
	cooldown_time = 1 MINUTES

/datum/action/cooldown/limbus_abno_action/smile_hoard/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/simple_smile/smile = abno_user
	if(smile.pulling)
		smile.pulling.forceMove(smile.treasure_turf)
	playsound(smile, 'sound/abnormalities/scaredycat/cateleport.ogg', 50, FALSE, 4)
	playsound(smile.treasure_turf, 'sound/abnormalities/scaredycat/cateleport.ogg', 50, FALSE, 4) //We play it both on where it teleports and where it teleported from.
	smile.forceMove(smile.treasure_turf)
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/smile_id_bump
	name = "ID Bump"
	desc = "Makes the next person you attack drop their ID."
	icon_icon = 'icons/obj/card.dmi'
	button_icon_state = "fixer_id"
	cooldown_time = 30 SECONDS

/datum/action/cooldown/limbus_abno_action/smile_id_bump/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/simple_smile/smile = abno_user
	smile.id_bump = TRUE
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/smile_knockdown
	name = "Knockdown"
	desc = "Makes your next few attacks trip people, dropping any items they were holding."
	icon_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = "generic_slam"
	cooldown_time = 45 SECONDS

/datum/action/cooldown/limbus_abno_action/smile_knockdown/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/simple_smile/smile = abno_user
	smile.knockdown_count = 0
	StartCooldown()
