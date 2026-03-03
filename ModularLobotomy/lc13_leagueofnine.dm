


/*--------------------------\
|League of Nine ID Imprinter|
\--------------------------*/
// heavily based off of hypnochair.dm - look in tgui/packages/tgui/interfaces/idimprinter.js for the ui code
/obj/machinery/idimprinter
	name = "identity imprinter"
	desc = "A recent development by the New League of Nine Littérateurs, this machine extracts an Identity from the Mirror and forces it onto the person. Simply force a person inside and turn it on. Interrupting impritation is ill-advised."
	icon = 'icons/obj/machines/implantchair.dmi'
	icon_state = "hypnochair" //temporary
	verb_say = "dictates"
	verb_ask = "inquiries"
	verb_exclaim = "dictates"
	density = TRUE
	opacity = FALSE
	use_power = NO_POWER_USE

	var/imprinting = FALSE ///Is the machine imprinting an identity right now?
	var/start_time = 0 ///Time when the imprinting was started, to calculate effect in case of interruption
	var/trigger_phrase = "" ///Trigger phrase to implant
	var/timerid = 0 ///Timer ID for imprinting
	var/message_cooldown = 0 ///Cooldown for breakout message
	var/enter_message = "<span class='notice'><b>You feel dosens of pricks pierce your skin, holding you in place. Was this really a good idea?</b></span>"
	var/identitylevel = 5 /*this decides what "tier" of identity you get. you gotta have a minimum # in each virtue to meet tier requirements cuz of gear & balance
1 - urban legend (mariachi, ting-tang, base fixer gear) - no stats lol
2 - urban plague (mariachi/tingtang boss, middle little sib, kcorp L1, warp baton, fullstop) 60-stats
3 - urban nightmare (grade 6-5 fixers - molars, south & east soldatos, mittlehammers, index proselytes, assoc fixer, kcorp L3, warp L3/modified/type C) 80-stats
4 - urban nightmare but better (roaming assoc fixers ala cinq west, devyat, liu2, capos (not east), index proxies, r-corp..? check with maintainer) 100-stats
5 - star of the city (eastern capos, sottocapo, messenger, grand inq, directors) 120 stats - literally the only case of you ever getting this is if you sacrifice the assoc director/your boss/a second syndicate leader
*/

	var/alist/identities = alist(
		1 = list(
			"mariachimarraca" = list("weapon" = /obj/item/ego_weapon/city/mariachi, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/mariachi),
			"mariachiblades" = list("weapon" = /obj/item/ego_weapon/city/mariachi_blades, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/mariachi/vivaz),
			"ting-tangknife" = list("weapon" = /obj/item/ego_weapon/city/ting_tang, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/ting_tang),
			"ting-tangcleaver" = list("weapon" = /obj/item/ego_weapon/city/ting_tang/cleaver, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/ting_tang/puffer),
			"ting-tangpipe" = list("weapon" = /obj/item/ego_weapon/city/ting_tang/pipe, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/ting_tang/rustic),
			"greatswordfixer" = list("weapon" = /obj/item/ego_weapon/city/fixergreatsword, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/misc/second),
			"swordfixer" = list("weapon" = /obj/item/ego_weapon/city/fixerblade, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/misc/sixth),
			"hammerfixer" = list("weapon" = /obj/item/ego_weapon/city/fixerhammer, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/misc/fifth),
		),
		2 = list(
			"mariachiboss" = list("weapon" = /obj/item/ego_weapon/city/mariachi/dual, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/mariachi/aida),
			"ting-tangboss" = list("weapon" = /obj/item/ego_weapon/city/ting_tang/knife, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/ting_tang/boss),
			"middlelittle" = list("weapon" = /obj/item/storage/box/league_of_nine/littlesibling, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/middle/tank_top),
			"kcorpl1baton" = list("weapon" = /obj/item/ego_weapon/city/kcorp, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/kcorp_l1),
			"kcorpl1axe" = list("weapon" = /obj/item/ego_weapon/city/kcorp/axe, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/kcorp_l1),
			"warpjobber" = list("weapon" = /obj/item/ego_weapon/city/wcorp, "armor" = /obj/item/clothing/suit/armor/ego_gear/wcorp),
			"fullstopassault" = list("weapon" = /obj/item/ego_weapon/ranged/city/fullstop/assault, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/fullstop),
			"fullstopsniper" = list("weapon" = /obj/item/ego_weapon/ranged/city/fullstop/sniper, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/fullstop/sniper),
		),
		3 = list(
			"molarnormie" = list("weapon" = /obj/item/ego_weapon/city/molar, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/molar/boatworks),
			"southsoldato" = list("weapon" = /obj/item/ego_weapon/ranged/city/thumb, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/thumb),
			"eastsoldato" = list("weapon" = /obj/item/storage/box/league_of_nine/eastsoldato, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/thumb_east),
			"mittelhammer" = list("weapon" = /obj/item/storage/box/league_of_nine/mittelhammer, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/ncorp/vet),
			"indexproselyte" = list("weapon" = /obj/item/ego_weapon/city/index, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/index),
			"kcorpspear" = list("weapon" = /obj/item/storage/box/league_of_nine/kcorpl3spear, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/kcorp_l3),
			"kcorpblastspear" = list("weapon" = /obj/item/storage/box/league_of_nine/kcorpl3blastspear, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/kcorp_l3),
			"warpfist" = list("weapon" = /obj/item/ego_weapon/city/wcorp/fist, "armor" = /obj/item/clothing/suit/armor/ego_gear/wcorp),
			"warpaxe" = list("weapon" = /obj/item/ego_weapon/city/wcorp/axe, "armor" = /obj/item/clothing/suit/armor/ego_gear/wcorp),
			"warphatchet" = list("weapon" = /obj/item/ego_weapon/city/wcorp/hatchet, "armor" = /obj/item/clothing/suit/armor/ego_gear/wcorp),
			"warphammer" = list("weapon" = /obj/item/ego_weapon/city/wcorp/hammer, "armor" = /obj/item/clothing/suit/armor/ego_gear/wcorp),
			//assoc fixers to be added when rework is merged
		),
		4 = list(
			"cinqwest" = list("weapon" = /obj/item/storage/box/league_of_nine/cinqwest, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/cinqwest),
			"zweiwest" = list("weapon" = /obj/item/ego_weapon/city/zweiwest, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/zweiwest),
			"devyat" = list("weapon" = /obj/item/ego_weapon/city/devyat_trunk, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/devyat_suit),
			"liu2" = list("weapon" = /obj/item/ego_weapon/city/liu/fire/spear, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/liuvet/section2),
			"southcapo" = list("weapon" = /obj/item/ego_weapon/ranged/city/thumb/capo, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/thumb_capo),
			"indexproxy" = list("weapon" = /obj/item/ego_weapon/city/index/proxy/spear, "armor" = /obj/item/clothing/suit/armor/ego_gear/index_proxy),
			//assoc vets to be added when rework is merged
		),
		5 = list(
			"eastcapo" = list("weapon" = /obj/item/storage/box/league_of_nine/eastcapo, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/thumb_east/capo),
			"sottocapo" = list("weapon" = /obj/item/storage/box/league_of_nine/sottocapo, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/thumb_sottocapo),
			"indexmessenger" = list("weapon" = /obj/item/storage/box/league_of_nine/messenger, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/index_mess),
			"grandinquisitor" = list("weapon" = /obj/item/storage/box/league_of_nine/grandinquisitor, "armor" = /obj/item/clothing/suit/armor/ego_gear/city/ncorpcommander),
			//directors to be added when rework is merged
		)
	)

/obj/machinery/idimprinter/Initialize()
	. = ..()
	open_machine()
	update_icon()

/obj/machinery/idimprinter/container_resist_act(mob/living/user) //how the imprinter reacts to the occupant trying to break free
	user.changeNext_move(CLICK_CD_BREAKOUT)
	user.last_special = world.time + CLICK_CD_BREAKOUT
	user.visible_message("<span class='notice'>You see [user] kicking against the door of [src]!</span>", \
		"<span class='notice'>You lean on the back of [src] and start pushing the door open... (this will take about [DisplayTimeText(600)].)</span>", \
		"<span class='hear'>You hear a metallic creaking from [src].</span>")
	playsound(get_turf(src), 'ModularLobotomy/_Lobotomysounds/id_imprinter_sounds/deny1.ogg', 25, TRUE)
	say("WARNING! The subject is attempting to disrupt the imprinting process!")
	if(do_after(user,(600), target = src))
		if(!user || user.stat != CONSCIOUS || user.loc != src || state_open)
			return
		user.visible_message(span_warning("[user] successfully broke out of [src]!"), \
			span_notice("You successfully break out of [src]!"))
		open_machine()

/obj/machinery/idimprinter/relaymove(mob/living/user, direction)
	if(message_cooldown <= world.time)
		message_cooldown = world.time + 50
		to_chat(user, "<span class='warning'>[src]'s seal won't budge!</span>")

/obj/machinery/idimprinter/ui_state(mob/user)
	return GLOB.notcontained_state

/obj/machinery/idimprinter/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "IDImprinter", name)
		ui.open()

/obj/machinery/idimprinter/ui_data()
	var/list/data = list()
	var/mob/living/mob_occupant = occupant

	data["occupied"] = mob_occupant ? 1 : 0
	data["open"] = state_open
	data["imprinting"] = imprinting

	data["occupant"] = list()
	if(mob_occupant)
		data["occupant"]["name"] = mob_occupant.name
		data["occupant"]["stat"] = mob_occupant.stat

	return data

/obj/machinery/idimprinter/ui_act(action, params) //this is just what interacting with the ui does for the machine. hit door? open/close door.
	. = ..()
	if(.)
		return

	switch(action)
		if("door")
			if(state_open)
				close_machine()
			else
				if(!imprinting)
					open_machine()
			. = TRUE
		if("imprint")
			if(!imprinting)
				imprint()
			else
				interrupt_imprinting()
			. = TRUE

/obj/machinery/idimprinter/proc/imprint() //the proc that handles imprinting the victim and applying the effects
	var/mob/living/carbon/human/H = occupant
	var/obj/item/I = H.get_equipped_items()
	if(!H || !istype(H))
		interrupt_imprinting()
	if(I in H.get_all_gear()) //marked for destgrok review
		if(!HAS_TRAIT(I, TRAIT_NODROP))
			playsound(get_turf(src), 'ModularLobotomy/_Lobotomysounds/id_imprinter_sounds/deny1.ogg', 25, TRUE)
			say("Please remove all non-organic items such as radios, uniforms, and shoes, before using the imprinter.")
			return
	to_chat(H, "<span class='warning'>You can feel those pricks turn into nails, searing past your skin!</span>")
	say("Nagel und Hammer thanks you for your dedication to the new ideal.")
	playsound(get_turf(src), 'ModularLobotomy/_Lobotomysounds/id_imprinter_sounds/deny1.ogg', 25, TRUE)
	H.become_blind("idimprinter")
	ADD_TRAIT(H, TRAIT_DEAF, "idimprinter")
	imprinting = TRUE
	START_PROCESSING(SSobj, src)
	start_time = world.time
	update_icon()
	timerid = addtimer(CALLBACK(src, PROC_REF(finish_imprinting)), 450, TIMER_STOPPABLE)

/obj/machinery/idimprinter/process(delta_time) //flavorstuff while imprintings
	var/mob/living/carbon/human/H = occupant
	if(!istype(H) || H != occupant)
		interrupt_imprinting()
		return
	if(DT_PROB(5, delta_time))
		to_chat(H, "Infinite possibilities... [pick(\
			"My memories - they're being replaced. Is this what I really want..?",\
			"I feel myself bleeding out...",\
			"Everything's so violent, so bloody-...",\
			"I see myself. Why do I look so different..?",\
			"A whole entire world, shattered before my eyes..."\
		)]</span>")

/obj/machinery/idimprinter/proc/finish_imprinting() // this is what happens after succesful imprinting, and when the gear is applied
	var/mob/living/carbon/human/H = occupant
	if(!H || !istype(H))
		interrupt_imprinting()
		return

	var/list/occupant_attributes = H.attributes //ok! lets begin deciding what requirements the victim meets!
	if(!occupant_attributes || !LAZYLEN(occupant_attributes))
		return FALSE // crazy error
	for(var/attr_name in H.attributes)
		var/datum/attribute/attr = H.attributes[attr_name]
		if(attr.get_raw_level() >= 119)
			identitylevel = min(identitylevel, 5)
		else if(attr.get_raw_level() >= 99)
			identitylevel = min(identitylevel, 4)
		else if(attr.get_raw_level() >= 79)
			identitylevel = min(identitylevel, 3)
		else if(attr.get_raw_level() >= 59)
			identitylevel = min(identitylevel, 2)
		else
			identitylevel = 1

	var/chosen_identity = pick(identities[identitylevel]) //roll the dice from the selected identity level

//hold your horses, let's define these real quick
	var/obj/item/identity_weapon = identities[identitylevel][chosen_identity]["weapon"] //just an item cuz of boxes
	var/obj/item/clothing/suit/armor/ego_gear/identity_armor = identities[identitylevel][chosen_identity]["armor"]

//time to equip armor!
	var/obj/item/are_we_wearing_something = H.get_item_by_slot(ITEM_SLOT_OCLOTHING)

	if(isnull(are_we_wearing_something))
		identity_armor = new(src)
		if(H.can_equip(identity_armor, ITEM_SLOT_OCLOTHING, disable_warning = TRUE)) //equip away, no delay!
			H.equip_to_slot(identity_armor, ITEM_SLOT_OCLOTHING)
		else
			interrupt_imprinting()
			identity_armor.forceMove(get_turf(src)) //drop new ID armor onto imprinter turf

	else if(HAS_TRAIT(are_we_wearing_something, TRAIT_NODROP))
		interrupt_imprinting()
		return

	else
		identity_armor = new(src)
		H.dropItemToGround(are_we_wearing_something) //this literally should never happen cuz of previous checks- but just in case
		if(H.can_equip(identity_armor, ITEM_SLOT_OCLOTHING, disable_warning = TRUE)) //equip away, no delay!
			H.equip_to_slot(identity_armor, ITEM_SLOT_OCLOTHING)
		else
			interrupt_imprinting()
			identity_armor.forceMove(get_turf(src)) //drops new ID armor onto the turf the machine is on

//weapon time!
	var/obj/item/are_we_holding_something = H.get_active_held_item()

	if(isnull(are_we_holding_something))
		identity_weapon = new(src)
		if(H.can_equip(identity_weapon, ITEM_SLOT_HANDS, disable_warning = TRUE)) //equip w/ delay
			H.put_in_r_hand(identity_weapon)
		else
			interrupt_imprinting()
			identity_weapon.forceMove(get_turf(src)) //drop new ID weapon onto imprinter turf

	else if(HAS_TRAIT(are_we_holding_something, TRAIT_NODROP))
		interrupt_imprinting()
		return

	else
		identity_weapon = new(src)
		H.dropItemToGround(are_we_holding_something) //this literally should never happen cuz of previous checks- but just in case
		if(H.can_equip(identity_weapon, ITEM_SLOT_HANDS, disable_warning = TRUE)) //equip w/ no delay
			H.put_in_r_hand(identity_weapon)
		else
			interrupt_imprinting()
			identity_weapon.forceMove(get_turf(src)) //drops new ID weapon onto the turf the machine is on

//this what happens after everything goes right and the occupant is released - still apart of finish_imprinting proc
	imprinting = FALSE
	STOP_PROCESSING(SSobj, src)
	update_icon()
	audible_message("<span class='notice'>[src] pings!</span>")
	playsound(src, 'ModularLobotomy/_Lobotomysounds/id_imprinter_sounds/print2.ogg', 30, TRUE)
	say("A new era is upon us. Imprinting complete.")

	if(QDELETED(H) || H != occupant)
		occupant = null
		return
	H.cure_blind("idimprinter")
	REMOVE_TRAIT(occupant, TRAIT_DEAF, "idimprinter")
	occupant = null

/obj/machinery/idimprinter/proc/interrupt_imprinting() // what happens if imprinting is interrupted
	var/mob/living/carbon/human/H = occupant
	deltimer(timerid)
	imprinting = FALSE
	STOP_PROCESSING(SSobj, src)
	update_icon()

	if(QDELETED(H))
		occupant = null
		return
	H.cure_blind("idimprinter")
	REMOVE_TRAIT(H, TRAIT_DEAF, "idimprinter")
	var/time_diff = world.time - start_time
	switch(time_diff)
		if(0 to 100)
			H.adjustBruteLoss(H.maxHealth*0.9, TRUE, TRUE)
		if(101 to 200)
			H.adjustBruteLoss(H.maxHealth*0.95, TRUE, TRUE)
		if(201 to INFINITY)
			H.adjustBruteLoss(H.maxHealth*1, TRUE, TRUE)
	occupant = null

/obj/machinery/idimprinter/update_icon_state()
	icon_state = initial(icon_state)
	if(state_open)
		icon_state += "_open"
	if(occupant)
		if(imprinting)
			icon_state += "_active"
		else
			icon_state += "_occupied"

/obj/machinery/idimprinter/relaymove(mob/living/user, direction)
	if(message_cooldown <= world.time)
		message_cooldown = world.time + 50
		to_chat(user, "<span class='warning'>[src]'s door won't budge!</span>")


/obj/machinery/idimprinter/MouseDrop_T(mob/target, mob/user)
	if(HAS_TRAIT(user, TRAIT_UI_BLOCKED) || !Adjacent(user) || !user.Adjacent(target) || !isliving(target) || !ISADVANCEDTOOLUSER(user))
		return

	close_machine(target)


