//Combat because hes a real boy, can do anything a human can including shooting you with your own gun... as long as someone plays
/mob/living/simple_animal/hostile/rcorp_abno/easy/pinocchio
	name = "Pinocchio"
	desc = "A wooden humanoid puppet, may be possessed by higher forces. Looks highly flammable, aside from that youd have to harm its soul. "
	maxHealth = 600
	health = 600
	//If you kill unconscious Pino youll have to kill him with a welder or magic soul damage, fuck you if you want a free kill
	damage_coeff = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0.1, FIRE = 2)
	del_on_death = FALSE
	core = FALSE
	move_resist = MOVE_RESIST_DEFAULT //So the abnos can drag him outta there
	original_abno = /mob/living/simple_animal/hostile/abnormality/pinocchio

	var/mob/living/carbon/human/species/rca_pinocchio/realboy = null

	abno_additional_instructions = "<h1>You are Pinocchio, A Combat Role Abnormality.</h1><br>\
		<b>|Learning|: When joining the round you will become 'human', you may do anything a human would do such as use weapons and wear armor. \
		However as a abnormality you possess natural damage resistances as well as stun immunity and night vision. \
		If attempting to disguise as a human your cut strings will still be visible through face covering and may give you away. <br>\
		<br>\
		|Lies|: You spawn with the Liars Lyre, this weapon will erase itself when dropped for 3 seconds. \
		You may examine this weapon to see its damage and other attributes. <br>\
		<br>\
		|Curiosity|: BLACK, WHITE and PALE damage are simplified, instead of taking SP damage you will just be dealt HP damage instead. \
		When taking PALE instead of taking percentual damage you will take flat damage as usual instead. \
		Your attributes are all at 100 except for Fortitude which is at 400 stats. </b>"

/mob/living/simple_animal/hostile/rcorp_abno/easy/pinocchio/Login()
	. = ..()
	if(client)
		RealBoy() //The real abno

//Our sleeping beauty cant run off
/mob/living/simple_animal/hostile/rcorp_abno/easy/pinocchio/Move()
	return

//Eepy and wont fight back
/mob/living/simple_animal/hostile/rcorp_abno/easy/pinocchio/CanAttack()
	return

/mob/living/simple_animal/hostile/rcorp_abno/easy/pinocchio/death()
	//Did you think itd be free? Summoning a angry fort insane pino on your head
	RealBoy()
	. = ..()
//Breach
/mob/living/simple_animal/hostile/rcorp_abno/easy/pinocchio/proc/RealBoy()
	playsound(src, 'sound/abnormalities/pinocchio/activate.ogg', 40, 0, 1)
	density = FALSE
	animate(src, alpha = 0,pixel_x = 0, pixel_z = 16, time = 4 SECONDS)
	SLEEP_CHECK_DEATH(1 SECONDS)
	realboy = new (get_turf(src)) //Technically the breach version is a separate entity, requires a lot of tinkering but works.
	realboy.name = "Pinocchio the Liar"
	realboy.real_name = "Pinocchio the Liar"
	realboy.adjust_all_attribute_levels(100)
	realboy.adjust_attribute_bonus(FORTITUDE_ATTRIBUTE, 400) // 600 health
	realboy.health = realboy.maxHealth
	realboy.alpha = 0
	realboy.pixel_z = 16
	animate(realboy, alpha = 255,pixel_x = 0, pixel_z = -16, time = 0.5 SECONDS)
	realboy.pixel_z = 0
	realboy.put_in_l_hand(new /obj/item/ego_weapon/marionette/rca_abnormality(realboy))
	if(client)
		mind.transfer_to(realboy)
	realboy.ai_controller = /datum/ai_controller/insane/murder/rca_puppet
	realboy.InitializeAIController()
	realboy.apply_status_effect(/datum/status_effect/panicked_type/rca_puppet)
	QDEL_IN(src, 5 SECONDS) //We dont need a invisible super pino running around

//Special item
/obj/item/ego_weapon/marionette/rca_abnormality
	name = "liar's lyre"
	desc = "A wooden axe, somehow wickedly sharp. Looks fragile."
	damtype = WHITE_DAMAGE

	item_flags = ABSTRACT
	var/delete_timer

/obj/item/ego_weapon/marionette/rca_abnormality/attack(mob/living/M, mob/living/user)
	if(ishuman(M))
		var/mob/living/carbon/human/L = M
		if(L.sanity_lost)
			damtype = RED_DAMAGE
	..()
	damtype = WHITE_DAMAGE

/obj/item/ego_weapon/marionette/rca_abnormality/dropped(mob/user)
	. = ..()
	if(!QDELING(src))
		delete_timer = addtimer(CALLBACK(src, PROC_REF(TryDelete), user), 3 SECONDS, TIMER_STOPPABLE)

/obj/item/ego_weapon/marionette/rca_abnormality/proc/TryDelete(mob/user)
	if(!delete_timer)
		return
	deltimer(delete_timer)
	delete_timer = null
	qdel(src)

/obj/item/ego_weapon/marionette/rca_abnormality/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(delete_timer)
		deltimer(delete_timer)
		delete_timer = null
	if(user.dna.species.id != "puppet")
		to_chat(user, span_warning("The [src] collapses into splinters in your hands!"))
		qdel(src)
		return

	//Special panic type for carbon mob
/datum/ai_controller/insane/murder/rca_puppet
	lines_type = /datum/ai_behavior/say_line/insanity_murder/rca_puppet
	continue_processing_when_client = FALSE //Prevents playable pinocchio from going around murdering everyone.

/datum/ai_controller/insane/murder/rca_puppet/CanTarget(atom/movable/thing)
	. = ..()
	var/mob/living/living_pawn = pawn
	if(. && isliving(thing) && living_pawn.faction_check_mob(thing))
		return FALSE

/datum/status_effect/panicked_type/rca_puppet
	icon = null

/datum/ai_behavior/say_line/insanity_murder/rca_puppet
	lines = list(
		"I'm keen to learn as usual. Would you like to see me learn?",
		"Lalala... I sing along to the song of lies all the people sing.",
		"Did I look just like a human? I hope I did...",
		"It's people's fault for falling for my lies."
		)

//Carbon code
/mob/living/carbon/human/species/rca_pinocchio //a real boy. Compatiable with being spawned by admins to boot! Can't panic outside of fear, though.
	race = /datum/species/rca_puppet
	faction = list("hostile")
	var/core_enabled = FALSE

/mob/living/carbon/human/species/rca_pinocchio/Initialize(mapload, cubespawned=FALSE, mob/spawner) //There is basically no documentation for bodyparts and hair, so this was the next best thing.
	. = ..()
	var/strings = icon('icons/mob/mutant_bodyparts.dmi', "strings_pinnochio_ADJ")
	src.add_overlay(strings)

/mob/living/carbon/human/species/rca_pinocchio/canBeHandcuffed()
	return FALSE

/mob/living/carbon/human/species/rca_pinocchio/UnarmedAttack(atom/A, proximity)
	if((istype(A, /obj/structure/toolabnormality/touch)) || (istype(A, /obj/structure/bough)))
		to_chat(src, span_userdanger("YOUR FOOLISHNESS IS IMPRESSIVE."))
		return
	. = ..()

/mob/living/carbon/human/species/rca_pinocchio/death(gibbed)
	if(!QDELETED(src))
		dropItemToGround(get_inactive_held_item())
		dropItemToGround(get_active_held_item())
		QDEL_IN(src, 15) //In theory we could do an egg transformation at this point but I have no sprite.
	..()

/mob/living/carbon/human/species/rca_pinocchio/Destroy()
	CreateAbnoCore()
	..()

/mob/living/carbon/human/species/rca_pinocchio/proc/CreateAbnoCore()//this is at the carbon level
	var/obj/structure/abno_core/C = new(get_turf(src))
	C.name = "Pinocchio Core"
	C.desc = "The core of Pinocchio"
	C.icon_state = ""//core icon goes here
	C.contained_abno = /mob/living/simple_animal/hostile/rcorp_abno/easy/pinocchio//release()ing or extract()ing this core will spawn the abnormality, making it a valid core.
	C.threat_level = 3
	C.icon = 'ModularLobotomy/_Lobotomyicons/abno_cores/he.dmi'
	C.ego_list = list(
		/datum/ego_datum/weapon/marionette,
		/datum/ego_datum/armor/marionette,
	)

/datum/species/rca_puppet
	name = "Puppet"
	id = "puppet"
	sexes = FALSE
	hair_color = "352014"
	say_mod = "creaks, snaps"
	attack_verb = "slash"
	attack_sound = 'sound/abnormalities/pinocchio/attack.ogg'
	miss_sound = 'sound/abnormalities/pinocchio/attack.ogg'
	meat = /obj/item/stack/sheet/mineral/wood
	knife_butcher_results = list(/obj/item/stack/sheet/mineral/wood = 5)
	species_traits = list(NO_UNDERWEAR,NOBLOOD,NOEYESPRITES)
	inherent_traits = list(TRAIT_ADVANCEDTOOLUSER,TRAIT_NOMETABOLISM,TRAIT_TOXIMMUNE,TRAIT_NOBREATH,TRAIT_RESISTCOLD,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_RADIMMUNE,TRAIT_GENELESS,\
	TRAIT_NOHUNGER,TRAIT_XENO_IMMUNE,TRAIT_NOCLONELOSS,TRAIT_LIGHT_STEP,TRAIT_BRUTEPALE,TRAIT_BRUTESANITY, TRAIT_TRUE_NIGHT_VISION, TRAIT_COMBATFEAR_IMMUNE, TRAIT_IGNOREDAMAGESLOWDOWN, \
	TRAIT_NODROP, TRAIT_STUNIMMUNE, TRAIT_PUSHIMMUNE, )
	punchdamagelow = 10
	punchdamagehigh = 15
	redmod = 1.2 //Matches wearing its own E.G.O.
	whitemod = 0.5
	blackmod = 0.7
	palemod = 0.9
	stunmod = 0
	payday_modifier = 0 //broke ass
	bodypart_overides = list(
	BODY_ZONE_L_ARM = /obj/item/bodypart/l_arm/rca_puppet,\
	BODY_ZONE_R_ARM = /obj/item/bodypart/r_arm/rca_puppet,\
	BODY_ZONE_HEAD = /obj/item/bodypart/head/rca_puppet,\
	BODY_ZONE_L_LEG = /obj/item/bodypart/l_leg/rca_puppet,\
	BODY_ZONE_R_LEG = /obj/item/bodypart/r_leg/rca_puppet,\
	BODY_ZONE_CHEST = /obj/item/bodypart/chest/rca_puppet)
	speedmod = 1.3
	changesource_flags = MIRROR_BADMIN | WABBAJACK
	burnmod = 1.5

/datum/species/puppet/check_roundstart_eligible()
	return FALSE //heck no

/obj/item/bodypart/head/rca_puppet
	name = "puppet abnormality head"
	desc = "a head made of ...wood?"
	icon = 'icons/mob/human_parts.dmi'
	icon_state = "puppet_head"
	dismemberable = FALSE
	can_be_disabled = FALSE

/obj/item/bodypart/chest/rca_puppet
	name = "puppet abnormality torso"
	desc = "a torso made of ...wood?"
	icon = 'icons/mob/human_parts.dmi'
	icon_state = "puppet_chest"

/obj/item/bodypart/l_arm/rca_puppet
	name = "puppet abnormality left arm"
	desc = "a limb made of ...wood?"
	icon = 'icons/mob/human_parts.dmi'
	icon_state = "puppet_l_arm"
	dismemberable = FALSE
	can_be_disabled = FALSE

/obj/item/bodypart/r_arm/rca_puppet
	name = "puppet abnormality right arm"
	desc = "a limb made of ...wood?"
	icon = 'icons/mob/human_parts.dmi'
	icon_state = "puppet_r_arm"
	dismemberable = FALSE
	can_be_disabled = FALSE

/obj/item/bodypart/l_leg/rca_puppet
	name = "puppet abnormality left leg"
	desc = "a limb made of ...wood?"
	icon = 'icons/mob/human_parts.dmi'
	icon_state = "puppet_l_leg"
	dismemberable = FALSE
	can_be_disabled = FALSE

/obj/item/bodypart/r_leg/rca_puppet
	name = "puppet abnormality right leg"
	desc = "a limb made of ...wood?"
	icon = 'icons/mob/human_parts.dmi'
	icon_state = "puppet_r_leg"
	dismemberable = FALSE
	can_be_disabled = FALSE
