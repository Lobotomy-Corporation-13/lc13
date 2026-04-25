//Associate fixer
/datum/job/associateroaming
	title = "Roaming Association Fixer"
	outfit = /datum/outfit/job/associate
	department_head = list("Hana association")
	faction = "Station"
	supervisors = "hana association"
	selection_color = "#e09660"
	total_positions = 0
	spawn_positions = 0
	display_order = JOB_DISPLAY_ORDER_FIXER
	trusted_only = TRUE
	access = list(ACCESS_NETWORK)
	minimal_access = list(ACCESS_NETWORK)
	departments = DEPARTMENT_HANA | DEPARTMENT_FIXERS
	paycheck = 700
	maptype = list("fixers", "city")

	//They actually need this for their weapons
	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 100,
								PRUDENCE_ATTRIBUTE = 100,
								TEMPERANCE_ATTRIBUTE = 100,
								JUSTICE_ATTRIBUTE = 100
								)
	job_important = "This is a role to assist existing offices in getting a foothold in the city. You are not to enter the ruins alone."
	job_notice = "You are to assist the offices in their backstreet endeavors. Cryoing to re-roll your association is not allowed and will result in a de-trusting. \
		You are a fixer that recently blew into town to assist the local offices in their endeavors."
	/// Holds a list of players that should not be allowed to join as Roamers this round because they already spawned in as one! Staff no longer have to police this, woa
	var/static/list/temporary_bans = list()

/datum/job/associateroaming/after_spawn(mob/living/carbon/human/H, mob/M)
	//Not fear immune you're basically some goober
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)	//My guy you aren't even from this corporation
	H.set_attribute_limit(100)
	. = ..()
	var/selector = new /obj/item/roamer_kit_selector(get_turf(H))
	H.equip_to_slot_if_possible(selector, ITEM_SLOT_HANDS)
	temporary_bans += H.client

/datum/job/associateroaming/special_check_latejoin(client/C)
	if(C in temporary_bans)
		return FALSE
	return TRUE

/obj/item/roamer_kit_selector
	name = "roaming associate uplink"
	desc = "A communications device tuned to a certain Fixer Association's logistics department, ready to arrange delivery of some equipment. \
	It is currently in a state of quantum superposition - it could be one of many Associations, you just don't quite know which yet. \n\
	Use in-hand to receive equipment from one of two available Associations. These choices are set in stone, and cannot be re-rolled."
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-green"
	inhand_icon_state = "radio"
	var/static/list/common_associations = list("zwei", "shi5", "liu5", "seven6")
	var/static/list/uncommon_associations = list("zweiw", "shi2", "cinq", "cinq4", "cinqwest", "liu1", "devyat", "dieci")
	var/static/list/rare_associations = list("hana", "liu2")
	/// List matching the short little assoc names used previously to a full name that can be used on an ID/selection screen. I had to guess the sections for some of these since it's not included on the gear, went off the Limbus IDs
	var/static/list/pretty_names = list(
		"zwei" = "Zwei South Section 6 Fixer", // If local Assoc is Zwei and you need to find some justification for not being part of them despite being the same section... idk lol figure it out
		"shi5" = "Shi South Section 5 Fixer",
		"liu5" = "Liu South Section 5 Fixer",
		"seven6" = "Seven South Section 6 Fixer",
		"zweiw" = "Zwei West Section 3 Fixer",
		"shi2" = "Shi South Section 2 Fixer",
		"cinq" = "Cinq South Section 5 Fixer",
		"cinq4" = "Cinq South Section 4 Fixer",
		"cinqwest" = "Cinq West Section 3 Fixer",
		"liu1" = "Liu South Section 1 Fixer",
		"devyat" = "Devyat North Section 3 Fixer",
		"dieci" = "Dieci South Section 4 Fixer",
		"hana" = "Hana South Section 3 Fixer",
		"liu2" = "Liu South Section 2 Fixer",
		)
	var/static/uncommon_chance = 30
	var/static/rare_chance = 10
	// These get set on Initialize for each individual instance of this item.
	var/choice_slot_1 // Always Common!
	var/choice_slot_2 // Common, Uncommon or Rare

// On Initialize, load our choice_slot_x vars with the Association choices we get from the common_associations, uncommon_associations and rare_associations lists, while avoiding duplicates.
/obj/item/roamer_kit_selector/Initialize(mapload)
	. = ..()
	var/list/common_pool = common_associations.Copy()
	var/list/uncommon_pool = uncommon_associations.Copy()
	var/list/rare_pool = rare_associations.Copy()

	// Choice Slot 1: Always a Common choice.
	choice_slot_1 = pick_n_take(common_pool)

	// Choice Slot 2: Roll for Common; then roll to see if we replace with Uncommon; then roll to see if we replace with Rare.
	choice_slot_2 = pick_n_take(common_pool)
	if(prob(uncommon_chance))
		choice_slot_2 = pick_n_take(uncommon_pool)
	if(prob(rare_chance))
		choice_slot_2 = pick_n_take(rare_pool)

/obj/item/roamer_kit_selector/attack_self(mob/user)
	. = ..()
	var/mob/living/carbon/human/probably_a_fixer = user
	if(!istype(probably_a_fixer))
		return
	if(!probably_a_fixer.mind)
		return
	if(probably_a_fixer.mind.assigned_role != "Roaming Association Fixer")
		to_chat(user, span_danger("WARNING: UNAUTHORIZED OPERATION DETECTED. CONTINUED ATTEMPTS TO INTERFACE WITH THIS UPLINK WILL BE PROSECUTED.")) // they will not be prosecuted
		playsound(src, 'sound/machines/triple_beep.ogg', 50, FALSE)
		return

	var/list/dictionary = list(pretty_names[choice_slot_1] = choice_slot_1, pretty_names[choice_slot_2] = choice_slot_2, "Refuse (Return to Lobby)" = "uh_oh")
	var/what_did_they_choose = alert(probably_a_fixer, "Choose one of the following roles to take. Note: Section does not necessarily correspond with power. P.S.: 'Refuse' will kill you and ban you from this role for the round. You can play some other role, though.",
	"But Which Association Are You Really From?", pretty_names[choice_slot_1], pretty_names[choice_slot_2], "Refuse (Return to Lobby)")
	var/chosen_asso = dictionary[what_did_they_choose]

	if(!chosen_asso)
		to_chat(probably_a_fixer, span_warning("Equipment delivery cancelled."))
		playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, FALSE)
		return FALSE

	// Claw kills you for tax evasion or something. There's no immersion-friendly way to do this unless you want me to script, like, a train ride coming for you and taking you elsewhere?
	if(chosen_asso == "uh_oh")
		var/turf/origin = get_turf(probably_a_fixer)
		var/list/all_turfs = origin.reachableAdjacentTurfs()
		for(var/turf/T in all_turfs)
			if(T == origin)
				continue
			new /obj/effect/temp_visual/dir_setting/claw_appears(T)
			break
		new /obj/effect/temp_visual/justitia_effect(origin)
		qdel(probably_a_fixer)
		qdel(src)
		return FALSE

	var/armor
	var/weapon

	// We can probably change this a bit to be based on datums or something for more complex roamers in the future if we want? For now, this is mostly following the old implementation
	switch(chosen_asso)
		if("hana")
			armor = /obj/item/clothing/suit/armor/ego_gear/city/hanacombat
			weapon = /obj/item/ego_weapon/city/hana

		if("zwei")
			armor = /obj/item/clothing/suit/armor/ego_gear/city/zwei
			weapon = /obj/item/ego_weapon/city/zweihander

		if("zweiw")
			armor = /obj/item/clothing/suit/armor/ego_gear/city/zweiwest
			weapon = /obj/item/ego_weapon/city/zweiwest

		if("shi2")
			armor = /obj/item/clothing/suit/armor/ego_gear/city/shi
			weapon = /obj/item/ego_weapon/city/shi_assassin

		if("shi5")
			armor = /obj/item/clothing/suit/armor/ego_gear/city/shilimbus
			weapon = /obj/item/ego_weapon/city/shi_assassin

		if("cinq")
			armor = /obj/item/clothing/suit/armor/ego_gear/city/cinq
			weapon = /obj/item/ego_weapon/city/cinq

		if("liu1")
			armor = /obj/item/clothing/suit/armor/ego_gear/city/liu
			weapon = /obj/item/ego_weapon/city/liu/fire/fist

		if("liu2")
			armor = /obj/item/clothing/suit/armor/ego_gear/city/liuvet/section2
			weapon = /obj/item/ego_weapon/city/liu/fire/spear

		if("liu5")
			armor = /obj/item/clothing/suit/armor/ego_gear/city/liu/section5
			weapon = /obj/item/ego_weapon/city/liu/fist

		if("seven6")
			armor = /obj/item/clothing/suit/armor/ego_gear/city/seven
			weapon = /obj/item/ego_weapon/city/seven

		if("devyat")
			armor = /obj/item/clothing/suit/armor/ego_gear/city/devyat_suit
			weapon = /obj/item/ego_weapon/city/devyat_trunk

		if("cinq4")
			armor = /obj/item/clothing/suit/armor/ego_gear/city/cinq
			weapon = /obj/item/ego_weapon/city/cinq/section4

		if("cinqwest")
			armor = /obj/item/clothing/suit/armor/ego_gear/city/cinqwest
			weapon = /obj/item/ego_weapon/city/cinq/section4/west

		if("dieci")
			armor = /obj/item/clothing/suit/armor/ego_gear/city/dieci
			weapon = /obj/item/ego_weapon/city/dieci

	var/turf/T = get_turf(probably_a_fixer)
	if(!istype(T))
		to_chat(probably_a_fixer, span_warning("Could not deliver equipment - you're not standing on a turf? Try again elsewhere."))
		playsound(src, 'sound/machines/triple_beep.ogg', 50, FALSE)
		return FALSE

	if(!armor || !weapon)
		to_chat(probably_a_fixer, span_warning("Failed to deliver equipment for the '[chosen_asso]' selection. Contact someone responsible for this."))
		playsound(src, 'sound/machines/triple_beep.ogg', 50, FALSE)
		return FALSE

	// Spawn and try to equip them with their gear. It'll fall on the floor if they have no room for it.
	armor = new armor(T)
	weapon = new weapon(T)
	probably_a_fixer.equip_to_slot_if_possible(armor, ITEM_SLOT_OCLOTHING, qdel_on_fail = FALSE, disable_warning = FALSE, bypass_equip_delay_self = TRUE)
	probably_a_fixer.equip_to_slot_if_possible(weapon, ITEM_SLOT_HANDS, qdel_on_fail = FALSE, disable_warning = FALSE, bypass_equip_delay_self = TRUE)

	probably_a_fixer.mind.assigned_role = what_did_they_choose

	// Update their ID and PDA to reflect their new role.
	var/list/their_belongings = probably_a_fixer.get_all_gear()
	var/found_id = FALSE
	var/found_pda = FALSE
	for(var/obj/item/possibly_identification_stuff in their_belongings)
		if(istype(possibly_identification_stuff, /obj/item/card/id))
			var/obj/item/card/id/can_i_see_some_id = possibly_identification_stuff
			can_i_see_some_id.assignment = what_did_they_choose
			can_i_see_some_id.update_label()
			found_id = TRUE

		else if(istype(possibly_identification_stuff, /obj/item/pda))
			var/obj/item/pda/cool_pda_i_guess = possibly_identification_stuff
			cool_pda_i_guess.ownjob = what_did_they_choose
			cool_pda_i_guess.update_label()
			found_pda = TRUE
			if(!found_id && cool_pda_i_guess.id)
				cool_pda_i_guess.id.assignment = what_did_they_choose
				cool_pda_i_guess.id.update_label()
				found_id = TRUE

		if(found_id && found_pda)
			break

	to_chat(probably_a_fixer, span_nicegreen("Delivered equipment corresponding to a [what_did_they_choose]. Make us proud."))
	playsound(src, 'sound/machines/terminal_success.ogg', 50, FALSE)
	qdel(src)
	return TRUE
