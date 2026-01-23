//The Oracle's Proxy
/datum/job/oracles_proxy
	title = "Oracle Proxy"
	outfit = /datum/outfit/job/oracles_proxy
	department_head = list("the will of the prescript")
	faction = "Station"
	supervisors = "the will of the prescript"
	selection_color = "#cccccc"
	total_positions = 0
	spawn_positions = 0
	display_order = JOB_DISPLAY_ORDER_SYNDICATEHEAD
	trusted_only = TRUE
	access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	minimal_access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	departments = DEPARTMENT_COMMAND | DEPARTMENT_CITY_ANTAGONIST
	paycheck = 1000
	maptype = list("city", "fixers")
	job_important = "You are a wandering proxy of the Index, carrying out prescripts delivered to you by the Oracle. \
		You are not inherently hostile, but you must follow the prescripts you receive. \
		Use your index pager to receive and view your prescripts."
	job_notice = "Avoid killing other players without a reason. Killing a player for stopping your prescripts is a valid reason."

	roundstart_attributes = list(
		FORTITUDE_ATTRIBUTE = 300,
		PRUDENCE_ATTRIBUTE = 300,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100
	)

/datum/job/oracles_proxy/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	H.AddComponent(/datum/component/oracle_proxy_passive)
	. = ..()

/datum/outfit/job/oracles_proxy
	name = "Oracle Proxy"
	jobtype = /datum/job/oracles_proxy

	id = /obj/item/card/id/silver/plastic
	belt = /obj/item/pda/security
	uniform = /obj/item/clothing/under/suit/charcoal
	shoes = /obj/item/clothing/shoes/laceup
	l_hand = /obj/item/ego_weapon/index_vial
	r_hand = /obj/item/clothing/suit/armor/ego_gear/city/index_proxy_wanderer
	accessory = /obj/item/clothing/accessory/index_pager

// Oracle Proxy passive abilities component
/datum/component/oracle_proxy_passive
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Whether the guaranteed evade is available
	var/guaranteed_evade_ready = TRUE

/datum/component/oracle_proxy_passive/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/oracle_proxy_passive/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_damage_taken))

/datum/component/oracle_proxy_passive/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_APPLY_DAMGE)

/datum/component/oracle_proxy_passive/proc/on_damage_taken(datum/source, damage, damagetype, def_zone, attack_source, flags, attack_type)
	SIGNAL_HANDLER
	if(!damage || damage <= 0)
		return

	var/mob/living/carbon/human/H = parent
	if(!istype(H))
		return

	// Check if this is a MELEE or RANGED attack (for evasion mechanics)
	var/is_evadable_attack = (attack_type & ATTACK_TYPE_MELEE) || (attack_type & ATTACK_TYPE_RANGED)

	// Guaranteed Evade: 100% dodge for first MELEE/RANGED hit, 30 second cooldown
	if(is_evadable_attack && guaranteed_evade_ready)
		var/turf/T = get_step(H, pick(GLOB.cardinals))
		if(T && !T.density)
			H.forceMove(T)
			playsound(H, 'sound/weapons/black_silence/evasion.ogg', 50, TRUE)
			guaranteed_evade_ready = FALSE
			addtimer(CALLBACK(src, PROC_REF(recharge_guaranteed_evade)), 30 SECONDS)
			return COMPONENT_MOB_DENY_DAMAGE

	// Check if holding an ego_weapon
	var/obj/item/held = H.get_active_held_item()
	var/holding_ego_weapon = istype(held, /obj/item/ego_weapon)

	// Random Evasion: 50% chance to dodge if NOT holding ego weapon (only for MELEE or RANGED attacks)
	if(!holding_ego_weapon && is_evadable_attack && prob(50))
		var/turf/T = get_step(H, pick(GLOB.cardinals))
		if(T && !T.density)
			H.forceMove(T)
			playsound(H, 'sound/weapons/black_silence/evasion.ogg', 50, TRUE)
			return COMPONENT_MOB_DENY_DAMAGE

	// Clone Decay: Take 5% of damage as CLONE damage
	var/clone_damage = damage * 0.05
	if(clone_damage > 0)
		INVOKE_ASYNC(src, PROC_REF(apply_clone_damage), clone_damage)

/datum/component/oracle_proxy_passive/proc/recharge_guaranteed_evade()
	guaranteed_evade_ready = TRUE

/datum/component/oracle_proxy_passive/proc/apply_clone_damage(damage)
	var/mob/living/L = parent
	if(QDELETED(L) || L.stat == DEAD)
		return
	L.adjustCloneLoss(damage)
