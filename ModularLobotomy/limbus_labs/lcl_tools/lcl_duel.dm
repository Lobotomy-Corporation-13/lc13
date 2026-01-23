/obj/item/lcl_duel
	name = "Abnormality Repression Device"
	desc = "A Lobotomy Corporation gadget that was repurposed to safely repress abnormality without fully supressing them,\
	When used, the user and the abnormality will be able to hurt but not kill each other; indirect source of damage that cannot be tracked might bypass this.\
	The repression will automatically end once either your or the abnormality's health gets low enough, giving you back lost health and sanity."
	icon = 'ModularLobotomy/_Lobotomyicons/lcl_tools.dmi'
	icon_state = "lcl_duel"
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lcorp_left.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lcorp_right.dmi'
	force = 0
	hitsound = 'sound/weapons/ego/justitia2.ogg'
	var/mob/living/simple_animal/hostile/limbus_abno/linked_abno
	var/mob/living/carbon/human/agent
	var/initial_agent_health
	var/initial_agent_sanity
	var/initial_abno_health

/obj/item/lcl_duel/afterattack(atom/A, mob/living/user, proximity_flag, params)
	if(!do_after(user, 5 SECONDS, src))
		return
	var/mob/living/simple_animal/hostile/limbus_abno/LA = A
	if(!istype(LA))
		return
	if(linked_abno == LA)
		to_chat(user, span_warning("You are already repressing this abnormality!"))
		return

	if(linked_abno)
		to_chat(user, span_warning("You are already repressing another abnormality!"))
		return

	if(!ishuman(user))
		return

	linked_abno = LA
	agent = user
	to_chat(agent, span_bolddanger("The duel with [linked_abno] is starting!"))
	to_chat(linked_abno, span_bolddanger("The duel with [agent] is starting!"))
	playsound(src, 'sound/misc/whistle.ogg', 50, TRUE)
	initial_agent_health = agent.health
	initial_agent_sanity = agent.sanityhealth
	initial_abno_health = linked_abno.health
	RegisterSignal(agent, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, PROC_REF(AgentAttacking))
	RegisterSignal(agent, COMSIG_PARENT_ATTACKBY, PROC_REF(GenAttackBy))
	RegisterSignal(agent, COMSIG_ATOM_BULLET_ACT, PROC_REF(GenBulletAct))
	RegisterSignal(linked_abno, COMSIG_ATOM_BULLET_ACT, PROC_REF(GenBulletAct))
	RegisterSignal(linked_abno, COMSIG_PARENT_ATTACKBY, PROC_REF(GenAttackBy))
	RegisterSignal(linked_abno, COMSIG_HOSTILE_ATTACKINGTARGET, PROC_REF(AbnoAttacking))

/obj/item/lcl_duel/proc/AgentAttacking(datum/source, atom/A, proximity)
	SIGNAL_HANDLER
	if(A != linked_abno)
		return
	FighterHealthCheck()

/obj/item/lcl_duel/proc/AbnoAttacking(datum/source, atom/attacked_target)
	SIGNAL_HANDLER
	if(attacked_target != agent)
		return
	FighterHealthCheck()

/obj/item/lcl_duel/proc/GenAttackBy(datum/source, obj/item/I, mob/user)
	SIGNAL_HANDLER
	if(user != linked_abno && user != agent)
		return
	FighterHealthCheck()

/obj/item/lcl_duel/proc/GenBulletAct(datum/source, obj/projectile/P)
	SIGNAL_HANDLER
	if(P.firer != linked_abno && P.firer != agent)
		return
	FighterHealthCheck()

/obj/item/lcl_duel/proc/FighterHealthCheck()
	if(agent.stat < CONSCIOUS  || linked_abno.health < (linked_abno.getMaxHealth() * 0.4))
		EndDuel()
		return

/obj/item/lcl_duel/proc/EndDuel()
	to_chat(agent, span_bolddanger("The duel is over! You feel your body go back to the way it was before the duel."))
	to_chat(linked_abno, span_bolddanger("The duel is over! You feel your body go back to the way it was before the duel."))
	playsound(src, 'sound/misc/whistle.ogg', 50, TRUE)
	addtimer(CALLBACK(src, PROC_REF(HealFighters), agent, linked_abno), 1) //Due to some weird bullshit with frei freaking out if I adjust Health during the proc, we're slightly delaying the heal.
	UnregisterSignal(agent, list(COMSIG_HUMAN_MELEE_UNARMED_ATTACK, COMSIG_ATOM_BULLET_ACT, COMSIG_PARENT_ATTACKBY))
	UnregisterSignal(linked_abno, list(COMSIG_HOSTILE_ATTACKINGTARGET, COMSIG_ATOM_BULLET_ACT, COMSIG_PARENT_ATTACKBY))
	linked_abno = null
	agent = null

/obj/item/lcl_duel/proc/HealFighters(mob/living/carbon/human/H, mob/living/simple_animal/hostile/limbus_abno/LA)
	if(agent.stat == DEAD)
		agent.revive(full_heal = TRUE, admin_revive = TRUE) //This can probably be abused but who cares about powergaming in LCL of all things.
	H.adjustBruteLoss(H.health - initial_agent_health)
	H.adjustSanityLoss(H.sanityhealth - initial_agent_sanity)
	LA.adjustBruteLoss(LA.health - initial_abno_health)
