/mob/living/simple_animal/hostile/abnormality/oracle
	name = "Oracle of No Future"
	desc = "An ancient cryopod with the name 'Maria' etched into the side. \
		You look inside expecting to see the body of the person named, \
		but all you see is a gooey substance at the bottom."
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "oracle"
	icon_living = "oracle"
	portrait = "oracle"
	maxHealth = 1500
	health = 1500
	damage_coeff = list(RED_DAMAGE = 2, WHITE_DAMAGE = 0, BLACK_DAMAGE = 2, PALE_DAMAGE = 2)
	threat_level = ZAYIN_LEVEL
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 60,
		ABNORMALITY_WORK_INSIGHT = 70,
		ABNORMALITY_WORK_ATTACHMENT = 40,
		ABNORMALITY_WORK_REPRESSION = 80,
		"Fall Asleep" = 100,
	)
	work_damage_amount = 5
	work_damage_type = WHITE_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/wrath

	ego_list = list(
		/datum/ego_datum/weapon/dead_dream,
		/datum/ego_datum/armor/dead_dream
	)
//	gift_type =  /datum/ego_gifts/oracle
	abnormality_origin = ABNORMALITY_ORIGIN_ORIGINAL

	observation_prompt = "In a vivid dream you see her, as she was. \
		<br>She was told that it would feel like no time at all. \
		<br>Silently sleeping she dreams of the future, a future she was promised. \
		<br>Before your eyes untold time passes until one day."
	observation_choices = list(
		"The pod broke" = list(TRUE, "You look into the window as you see her stir in her slumber before falling still. \
			<br>Holding your breath in silence, \
			<br>You remember Maria, \
			<br>Forever dreaming of a future she will never see."),
		"She woke up" = list(FALSE, "The pod opens with a hiss as you watch her step out. \
			<br>The joy on her face is immesurable, for she left behind so much to be here. \
			<br>Then she melts away, for this was your dream."),
	)

	var/list/sleeplines = list(
		"Hello...",
		"I am reaching you from beyond the veil...",
		"I cannot move, I cannot speak...",
		"But for you, I have some information to part...",
		"Please wait a moment while I retrieve it for you....",
		"Ah, I have information on the next ordeal.... as you call it...",
		"The next ordeal is...",
	)
	var/list/fakeordeals = list(
		//Some Based off the 7 trumpets
		"Hail of fire and blood..... Thrown to the earth.... burning up nature...",
		"A great mountain..... plunging into the sea..... oceans of blood..... killing sea life....",
		"A star.... falling to earth.... poisoning the fresh water....",
		"The sky goes dark..... all the stars, the moon and even the sun.....",
		"Woe...... Woe to those who dwell on earth....",
		"A star falls to earth.... opening the abyss...",
		"Locusts.... with scorpion tails.... man's face... and lion's teeth.....",
		"Two hundred million troops.... fire and smoke.... and their plague will kill man...",
		"The kingdom of the world has become the kingdom of His Messiah.... reigning forever and ever...",
		//And some I made
		"Cold.... Endless Cold.....",
		"A man with many arms......",
		"A woman without a face.... and many children screaming....",
		// -IP additions
		"In a ruined hallway... scavengers feed on a worker...",
		"Hundred eyes... a endless maw... long legs... im scared...",
		"I hear it around the corner... but i cant look... i dont want to see whats there...",
		"The corner of a room... someone is smiling... their skin isnt on right...",
		"A plume of light erupts from a city...",
		"Monsters... monsters everywhere... they are eating people in the streets...",
		"A woman with a dog head... she is smoking silently...",
		"A person in a blue coat... they fold into a book...",
		)

/mob/living/simple_animal/hostile/abnormality/oracle/Move()
	return FALSE

/mob/living/simple_animal/hostile/abnormality/oracle/CanAttack(atom/the_target)
	return FALSE

/mob/living/simple_animal/hostile/abnormality/oracle/PostWorkEffect(mob/living/carbon/human/user, work_type, pe)
	if(work_type == ABNORMALITY_WORK_INSIGHT)
		user.drowsyness += 30
		user.Sleeping(30 SECONDS) //Sleep with her, so that you can get some information
		for(var/line in sleeplines)
			to_chat(user, span_notice(line))
			SLEEP_CHECK_DEATH(40)
			if(!user.IsSleeping())
				return
		if(prob(50))
			var/chosenfake = pick(fakeordeals)
			to_chat(user, span_notice("[chosenfake]"))
			return
		if(!SSlobotomy_corp.next_ordeal)
			to_chat(user, span_notice("All ordeals.... are completed..."))
			return
		to_chat(user, span_notice("[SSlobotomy_corp.next_ordeal.name]"))
	..()

/mob/living/simple_animal/hostile/abnormality/oracle/Initialize(mob/living/carbon/human/user)
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_ABNORMALITY_BREACH, PROC_REF(OnAbnoBreach))

/mob/living/simple_animal/hostile/abnormality/oracle/Destroy()
	UnregisterSignal(SSdcs, COMSIG_GLOB_ABNORMALITY_BREACH)
	return ..()


/mob/living/simple_animal/hostile/abnormality/oracle/AttemptWork(mob/living/carbon/human/user, work_type)
	if(work_type == "Fall Asleep")
		user.drowsyness += 30
		user.Sleeping(30 SECONDS) // Won't get any info, but you can listen for any breaches for 30 seconds
		var/dream_list
		for(var/datum/oracle_dream/possible_dream as anything in subtypesof(/datum/oracle_dream))
			LAZYADDASSOC(dream_list, possible_dream, possible_dream.weight)
		var/chosen_dream = pickweight(dream_list)
		log_game("[dream_list]")
		SpecialDreams(chosen_dream, user)
		return FALSE
	return TRUE

/mob/living/simple_animal/hostile/abnormality/oracle/proc/OnAbnoBreach(datum/source, mob/living/simple_animal/hostile/abnormality/abno)
	SIGNAL_HANDLER
	if(z != abno.z)
		return
	addtimer(CALLBACK(src, PROC_REF(NotifyEscape), loc, abno), rand(1 SECONDS, 3 SECONDS))

/mob/living/simple_animal/hostile/abnormality/oracle/proc/NotifyEscape(mob/living/carbon/human/user, mob/living/simple_animal/hostile/abnormality/abno)
	if(QDELETED(abno) || abno.stat == DEAD)
		return
	for(var/mob/living/carbon/human/H in GLOB.clients)
		if(H.IsSleeping())
			continue //You need to be sleeping to get notified
		to_chat(H, span_notice("Oh.... [abno]... It has breached containment..."))

//ER stuff
/mob/living/simple_animal/hostile/abnormality/oracle/BreachEffect(mob/living/carbon/human/user, breach_type)//finish this shit
	if(breach_type == BREACH_MINING)
		var/chosenfake = pick(fakeordeals)
		for(var/mob/living/L in livinginrange(48, src))
			if(L.z != z)
				continue
			if(faction_check_mob(L))
				continue
			to_chat(L, span_userdanger("[chosenfake]"))
		addtimer(CALLBACK(src, PROC_REF(NukeAttack)), 90 SECONDS)
	return ..()

/mob/living/simple_animal/hostile/abnormality/oracle/proc/NukeAttack()
	if(stat == DEAD)
		return
	playsound(src, 'sound/magic/wandodeath.ogg', 100, FALSE, 40, falloff_distance = 10)
	for(var/mob/living/L in livinginrange(48, src))
		if(L.z != z)
			continue
		if(faction_check_mob(L))
			continue
		to_chat(L, span_userdanger("Visions of a horrible future flash before your eyes!"))
		L.deal_damage((150 - get_dist(src, L)), WHITE_DAMAGE)
	qdel(src)

/mob/living/simple_animal/hostile/abnormality/oracle/proc/SpecialDreams(datum/oracle_dream/dreamt_set, mob/living/carbon/human/dreamer)
	if(!dreamt_set.dreamt_abnos)
		return
	if(!dreamer.IsSleeping())
		return
	var/forced_abno = FALSE
	for(var/mob/living/simple_animal/hostile/abnormality/foresighted_abno in dreamt_set.dreamt_abnos)
		var/dream_weight = dreamt_set.dreamt_abnos[foresighted_abno]
		var/index = foresighted_abno.threat_level
		if(index == ZAYIN_LEVEL && !forced_abno) // Teehee
			forced_abno = TRUE
			for(var/obj/machinery/computer/abnormality_queue/Q in GLOB.lobotomy_devices)
				Q.UpdateAnomaly(foresighted_abno, "dreamed with oracle to change", FALSE)
				SSabnormality_queue.AnnounceLock()
				SSabnormality_queue.ClearChoices()
				minor_announce("Unknown anomalies have caused all extraction attempts to yield the same ZAYIN abnormality, which has been sent to your facility. \
				Extraction Headquarters is currently searching for a solution, and it apologizes for the inconvenience.", "Extraction Alert:", TRUE)
		SSabnormality_queue.possible_abnormalities[index][foresighted_abno] *= dream_weight
	to_chat(dreamer, span_notice("The oracle shows you [dreamt_set.desc]"))

#define ABNO_GET(X) /mob/living/simple_animal/hostile/abnormality/##X // This will make our life SO much easier.
#define LOW_DREAM_WEIGHT 0.25
#define MEDIUM_DREAM_WEIGHT 0.5

// Base datum type for oracle set dreams.
/datum/oracle_dream
	var/name = "Dream of...nothing?"
	var/desc = "a dream of absolute nothingness. (Contact a developer.)"
	var/dreamlines = "If you see this, something has gone terribly wrong. (Contact a developer pretty please.)"
	var/list/dreamt_abnos
	var/weight = 1

// Dreamlines not added, only descriptions. Therefore descriptions are used to notify players which dream was chosen.
// Obviously, TODO: Dreamlines but dont hold your breath, I am no writer.
/datum/oracle_dream/black_forest
	name = "Dream of a Black Forest"
	desc = "a dream of a forest covered by the deepest dark and the good-intentioned beast at the heart of it."
	dreamt_abnos = list(ABNO_GET(judgement_bird) = 2, ABNO_GET(big_bird) = 2, ABNO_GET(punishing_bird) = 2)
	weight = LOW_DREAM_WEIGHT

/datum/oracle_dream/magical_girls
	name = "Dream of the Magical Defenders"
	desc = "a dream of a magical team of four, doomed from the very start."
	dreamt_abnos = list(ABNO_GET(hatred_queen) = 1.5, ABNO_GET(despair_knight) = 1.5, ABNO_GET(greed_king) = 1.5, ABNO_GET(wrath_servant) = 1.5)
	weight = MEDIUM_DREAM_WEIGHT

/datum/oracle_dream/fairy_feast
	name = "Dream of a Fairy Feast"
	desc = "a dream of deceiving beasts and a brutal feast, all orchestrated by their heartbroken queen."
	dreamt_abnos = list(ABNO_GET(fairy_festival) = 3, ABNO_GET(fairy_gentleman) = 3, ABNO_GET(fairy_longlegs) = 3, ABNO_GET(titania) = 3, ABNO_GET(nobody_is) = 1.5)

/datum/oracle_dream/emerald_path
	name = "Dream of an Emerald Path"
	desc = "a dream of a hopeful group of rejects and their journey to make their dreams come true."
	dreamt_abnos = list(ABNO_GET(woodsman) = 1.5, ABNO_GET(scarecrow) = 1.5, ABNO_GET(scaredy_cat) = 1.5, ABNO_GET(road_home) = 1.5)

/datum/oracle_dream/endless_hunt
	name = "Dream of the Endless Hunt"
	desc = "a dream of endless hunts and cyclical hatred. A dog stands besides its master, and a wolf bares its fangs against the hunter."
	dreamt_abnos = list(ABNO_GET(red_hood) = 1.5, ABNO_GET(big_wolf) = 1.5, ABNO_GET(blue_shepherd) = 1.5, ABNO_GET(red_buddy) = 1.5)
	weight = LOW_DREAM_WEIGHT

/datum/oracle_dream/human_form
	name = "Dream of the Human Form"
	desc = "a dream of human faces and human limbs, human skin and human bones, human organs and human blood, human laughter and human sadness. Everything that makes you human, and makes them not."
	dreamt_abnos = list(ABNO_GET(nothing_there) = 1.5, ABNO_GET(nobody_is) = 1.5, ABNO_GET(kqe) = 1.5, ABNO_GET(pinocchio) = 1.5)

/datum/oracle_dream/suffocating_obsession
	name = "Dream of Suffocating Obsession"
	desc = "a dream of the abyssal depths where countless eyes gaze upon you intently, following your every move." // Honestly out of ideas.
	dreamt_abnos = list(ABNO_GET(dreaming_current) = 2, ABNO_GET(pisc_mermaid) = 2, ABNO_GET(siltcurrent) = 2)

/datum/oracle_dream/forgotten_memorial
	name = "Dream of a Forgotten Memorial"
	desc = "a dream of a wasteland left behind by the winds of war, and the lonely memorial that watches over those who, even now, cannot escape the battlefield."
	dreamt_abnos = list(ABNO_GET(quiet_day) = 2, ABNO_GET(mhz) = 2, ABNO_GET(khz) = 2, ABNO_GET(army) = 2)

/datum/oracle_dream/shrimp_boat
	name = "Dream of the Shrimpiest Boat"
	desc = "a dream of your shrimp friends in your shrimp boat, fishing shrimps in the shrimpy sea for the shrimp corporation. Life is shrimply awesome."
	dreamt_abnos = list(ABNO_GET(shrimp_exec) = 10, ABNO_GET(wellcheers) = 10)

/datum/oracle_dream/lost_orchard
	name = "Dream of an Lost Orchard"
	desc = "a dream of a forgotten apple orchard, littered with rotting fruit and buried tales. Nevertheless, the decaying apples and the maggots within refuse to decay into non-existence."
	dreamt_abnos = list(ABNO_GET(golden_apple) = 2, ABNO_GET(snow_whites_apple) = 2, ABNO_GET(ebony_queen) = 2)

/datum/oracle_dream/bustling_hive
	name = "Dream of a Bustling Hive"
	desc = "a dream of labyrinthine passages inside a titanic beehive, where workers toil endlessly and soldiers stand in everlasting vigil. All for the Queen."
	dreamt_abnos = list(ABNO_GET(queen_bee) = 5, ABNO_GET(general_b) = 5)

/datum/oracle_dream/new_purpose
	name = "Dream of a New Purpose"
	desc = "a dream of a massive queue of purposeless people waiting in front of a colossal construct of machinery and flesh. On the other side, a conveyor belt transports a neverending procession of smiling automata."
	dreamt_abnos = list(ABNO_GET(we_can_change_anything) = 2, ABNO_GET(cleaner) = 2, ABNO_GET(helper) = 2, ABNO_GET(you_strong) = 2, ABNO_GET(steam) = 2, ABNO_GET(kqe) = 2, ABNO_GET(singing_machine) = 2)

/datum/oracle_dream/fated_harmony
	name = "Dream of Fated Harmony"
	desc = "a dream of the festering proliferation of all that is and the desolate silence of all that isn't, lacking in the harmony that can only be restored when the angel and the demon reunite once more."
	dreamt_abnos = list(ABNO_GET(yin) = 5, ABNO_GET(yang) = 5)

/datum/oracle_dream/one_sin // yes, its just the name of the abno. One Sin is dapper like that.
	name = "Dream of the One Sin"
	desc = "a dream of yourself facing a floating skull, while overwhelming light surrounds you on all sides. A booming voice announces its presence, but it's just you and the skull, awaiting your sins. The voice demands your worship, but it's just you and the skull, listening to your confession. The voice declares you a heretic, but it's just you and the skull, judging yet forgiving. As the voice finally grows silent, the skull gently asks: \"Have you found the answers you were looking for?\""
	dreamt_abnos = list(ABNO_GET(onesin) = 5, ABNO_GET(white_night) = 5)

/datum/oracle_dream/soft_hugs
	name = "Dream of Soft Hugs"
	desc = "a dream of factories and production lines churning out soft hugs and shining smiles. The affection that powers these machines will run out someday but for now this place is where happiness is born."
	dreamt_abnos = list(ABNO_GET(hurting_teddy) = 5, ABNO_GET(happyteddybear) = 5)

/datum/oracle_dream/scalding_jealousy // Do you think agents will celebrate when getting this dream?
	name = "Dream of Scalding Jealousy"
	desc = "a dream of a treacherous swamp filled with wraiths of all forms and sizes. A hermit traverses the area, yet for each mile they cross more and more wraiths attach themselves to their essence, starving for attention. The wraith's many boons protect the hermit from the dangers of predators and sickness, yet one forgotten ritual is all that it takes for all wraiths to pounce on them. Nothing remained afterwards but a deafening silence."
	dreamt_abnos = list(ABNO_GET(hurting_teddy) = 1.5, ABNO_GET(whitelake) = 1.5, ABNO_GET(pisc_mermaid) = 1.5, ABNO_GET(galaxy_child) = 1.5, ABNO_GET(despair_knight) = 1.5, ABNO_GET(wrath_servant) = 1.5, ABNO_GET(pygmalion) = 1.5, ABNO_GET(titania) = 1.5, ABNO_GET(melting_love) = 1.5, ABNO_GET(staining_rose) = 1.5)
	weight = LOW_DREAM_WEIGHT

/datum/oracle_dream/melting_clocls // Do you think agents will despair when getting this dream?
	name = "Dream of Melting Clocks"
	desc = "a dream of a field of clockwork pieces, melting under a searing sun. Time drips down slowly like a drop of tar, yearning to be one with the soil, yet it is always scooped up and put back into the clock to begin the cycle anew."
	dreamt_abnos = list(ABNO_GET(sirocco) = 3, ABNO_GET(siren) = 3, ABNO_GET(express_train) = 3, ABNO_GET(silence) = 3, ABNO_GET(nosferatu) = 3, ABNO_GET(seasons) = 3, ABNO_GET(black_sun) = 3, ABNO_GET(star_luminary) = 3, ABNO_GET(staining_rose) = 3)

#undef LOW_DREAM_WEIGHT
#undef MEDIUM_DREAM_WEIGHT
#undef ABNO_GET // Do we want this for general use? Who knows but better safe than sorry.
