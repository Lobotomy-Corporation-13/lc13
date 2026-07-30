GLOBAL_LIST_EMPTY(geresearched_abnos)

/obj/item/disc_researcher
	name = "General Escape Researcher"
	desc = "A machine to assist the discipline team in researching abnormality breaches. Gives LOB when breaching an abnormality, and PE when an abnormality has no breach information."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "disc_stats"
	//God I fucking hate how I need to have like a whole-ass radio embedded in this shit just to send radio messages
	var/obj/item/radio/Radio


/obj/item/disc_researcher/Initialize(mob/user)
	..()
	Radio = new /obj/item/radio(src)
	Radio.listening = 0

/obj/item/disc_researcher/pre_attack(atom/A, mob/living/user, params)
	if(Scan(A, user))
		return TRUE
	return ..()

/obj/item/disc_researcher/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(Scan(target, user))
		return TRUE
	return ..()

/obj/item/disc_researcher/proc/Scan(atom/A, mob/living/user)
	if(istype(A, /obj/machinery/computer/abnormality))
		var/obj/machinery/computer/abnormality/console = A
		if(console.datum_reference.stupid)	//We NEED to alert people. But just the Disc team.
			var/mob/living/simple_animal/breacher = console.datum_reference.current
			var/lob_amount = round(rand(0,2),0.1)
			Radio.set_frequency(FREQ_DISCIPLINE)
			Radio.talk_into(src, "PRIORITY ALERT: User [user.name] is attempting to perform breach research on [breacher.name]. Reward: A sense of pride and accomplishment.", FREQ_DISCIPLINE)

			if(do_after(user, 50, src))
				Radio.set_frequency(FREQ_DISCIPLINE)
				Radio.talk_into(src, "PRIORITY ALERT: User [user.name] Has successfully breached [breacher.name]. Time to breach: 15 Seconds.", FREQ_DISCIPLINE)
				addtimer(CALLBACK(src, PROC_REF(BreachStupid), breacher, lob_amount, console), 15 SECONDS)
			return TRUE
	if(!isabnormalitymob(A))
		return FALSE

	//Check if we got an abnormality and make sure that it's not already breached or researched
	var/mob/living/simple_animal/hostile/abnormality/breacher = A

	if(!breacher.IsContained())	//What are you trying to pull here buddy?
		return FALSE

	//It's already been researched, tabernak
	if(breacher.type in GLOB.geresearched_abnos)
		to_chat(user, span_warning("This abnormality has already been researched. A second capabilities report is not needed at this moment."))
		return FALSE

	//You get 0.2 Lob for each threat level
	var/lob_amount = breacher.threat_level*0.2

	if(!breacher.can_breach)
		//Here you just get 20 PE per threat level. Just smth small.
		var/pe_reward = lob_amount*100
		to_chat(user, span_warning("This abnormality is incompatible with the [src]. A minor PE bonus of [pe_reward] has been rewarded."))
		SSlobotomy_corp.AdjustAvailableBoxes(pe_reward)
		GLOB.geresearched_abnos += breacher.type
		return FALSE

	//We NEED to alert people. But just the Disc team.
	Radio.set_frequency(FREQ_DISCIPLINE)
	Radio.talk_into(src, "PRIORITY ALERT: User [user.name] is attempting to perform breach research on [breacher.name]. Reward: [lob_amount].", FREQ_DISCIPLINE)

	if(do_after(user, 50, src))
		Radio.set_frequency(FREQ_DISCIPLINE)
		Radio.talk_into(src, "PRIORITY ALERT: User [user.name] Has successfully breached [breacher.name]. Time to breach: 15 Seconds.", FREQ_DISCIPLINE)
		addtimer(CALLBACK(src, PROC_REF(BreachBerry), breacher, lob_amount), 15 SECONDS)
		GLOB.geresearched_abnos += breacher.type

	return TRUE

/obj/item/disc_researcher/proc/BreachStupid(mob/living/simple_animal/hostile/abnormality/breacher, lob_amount, obj/machinery/computer/abnormality/console)
	SSlobotomy_corp.lob_points += lob_amount
	var/turf/T = pick(GLOB.xeno_spawn)
	breacher.forceMove(T)
	console.datum_reference.qliphoth_change(-99)

//DESTROY BERRY
/obj/item/disc_researcher/proc/BreachBerry(mob/living/simple_animal/hostile/abnormality/breacher, lob_amount)
	SSlobotomy_corp.lob_points += lob_amount
	var/turf/T = pick(GLOB.xeno_spawn)
	breacher.forceMove(T)
	breacher.datum_reference.qliphoth_change(-99)
