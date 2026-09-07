// Abnormality Extraction Module.
// A crystal-fused console attachment (built on the work_console_upgrade base).
// While installed on an abnormality work console:
//   - a Pathstrider's finished work sheds a trickle of that abno's sin-tied
//     Path Material (main material), scaled by the work result;
//   - the module can spend a charge to force-breach a contained abnormality,
//     which drops a large T1+T2 bundle of that material when it dies.
// Main material comes only from here; Trace Material comes only from Calyxes.

/// Maps an abnormality's sin reagent to its Path Material family key.
/proc/SinToPathKey(sin_type)
	switch(sin_type)
		if(/datum/reagent/abnormality/sin/wrath) return PATH_KEY_DESTRUCTION
		if(/datum/reagent/abnormality/sin/envy) return PATH_KEY_HUNT
		if(/datum/reagent/abnormality/sin/pride) return PATH_KEY_ERUDITION
		if(/datum/reagent/abnormality/sin/gloom) return PATH_KEY_NIHILITY
		if(/datum/reagent/abnormality/sin/lust) return PATH_KEY_HARMONY
		if(/datum/reagent/abnormality/sin/sloth) return PATH_KEY_PRESERVATION
		if(/datum/reagent/abnormality/sin/gluttony) return PATH_KEY_ABUNDANCE
	return null

// ---- The module item ----

/obj/item/work_console_upgrade/pathstrider_extraction
	name = "abnormality extraction module"
	desc = "A crystal-fused console attachment. While installed, a Pathstrider's containment work sheds a trickle of that abnormality's Path Material, and the module can force-breach a contained abnormality to wring a larger yield from its death."
	icon = 'ModularLobotomy/_Lobotomyicons/extraction_module.dmi'
	icon_state = "extraction_module"
	upgrade_slot = "extraction"
	/// Forced-breach charges.
	var/charges = 3
	var/max_charges = 3
	/// Time between charge regen ticks.
	var/charge_regen_time = 10 MINUTES
	/// world.time the next charge finishes regenerating (0 = full).
	var/next_charge_time = 0

/// Spends a charge, starting the regen clock if it was full. Returns success.
/obj/item/work_console_upgrade/pathstrider_extraction/proc/SpendCharge()
	if(charges <= 0)
		return FALSE
	var/was_full = (charges >= max_charges)
	charges--
	if(was_full)
		ScheduleRegen()
	return TRUE

/obj/item/work_console_upgrade/pathstrider_extraction/proc/ScheduleRegen()
	next_charge_time = world.time + charge_regen_time
	addtimer(CALLBACK(src, PROC_REF(RegenCharge)), charge_regen_time)

/obj/item/work_console_upgrade/pathstrider_extraction/proc/RegenCharge()
	charges = min(charges + 1, max_charges)
	if(charges < max_charges)
		ScheduleRegen()
	else
		next_charge_time = 0

/// Seconds until the next charge regenerates (0 if full).
/obj/item/work_console_upgrade/pathstrider_extraction/proc/TimeToNextCharge()
	if(charges >= max_charges || !next_charge_time)
		return 0
	return max(0, round((next_charge_time - world.time) / 10))

/obj/item/work_console_upgrade/pathstrider_extraction/examine(mob/user)
	. = ..()
	. += span_notice("Forced-breach charges: [charges]/[max_charges] (one regenerates every [charge_regen_time / 600] minutes).")
	. += span_notice("Install on an abnormality work console. As a Pathstrider, work the abnormality for a trickle of its Path Material, or use the console's Force Breach button.")

// ---- Passive trickle (hooked from abnormality/work_complete) ----

/// Rewards a Pathstrider a little of the abno's Path Material on finished work.
/obj/machinery/computer/abnormality/proc/TryExtractionReward(mob/living/carbon/human/user, datum/abnormality/abno, pe)
	if(!istype(mechanical_upgrades["extraction"], /obj/item/work_console_upgrade/pathstrider_extraction))
		return
	if(!ishuman(user) || !user.GetPath())
		return
	if(!istype(abno) || QDELETED(abno.current))
		return
	var/key = SinToPathKey(abno.current.chem_type)
	if(!key)
		return
	var/t1_type = GetPathMatType("path", key, 1)
	if(!t1_type)
		return
	var/amount = 0
	var/t2 = 0
	if(pe >= abno.success_boxes)        // good work
		amount = rand(3, 5)
		if(prob(25))
			t2 = 1
	else if(pe >= abno.neutral_boxes)   // neutral
		amount = 2
	else                                // bad
		amount = 1
	var/turf/T = get_turf(user)
	if(!T)
		return
	if(amount > 0)
		new t1_type(T, amount)
	if(t2)
		var/t2_type = GetPathMatType("path", key, 2)
		if(t2_type)
			new t2_type(T, t2)

// ---- Forced breach (triggered from the console screen) ----

/obj/machinery/computer/abnormality/proc/ExtractionForceBreach(mob/living/carbon/human/user)
	if(!istype(user) || !user.GetPath())
		to_chat(user, span_warning("Only a Pathstrider can operate the extraction module."))
		return
	var/obj/item/work_console_upgrade/pathstrider_extraction/mod = mechanical_upgrades["extraction"]
	if(!istype(mod))
		to_chat(user, span_warning("No extraction module is installed on this console."))
		return
	if(!Adjacent(user))
		return
	if(!istype(datum_reference) || QDELETED(datum_reference.current))
		to_chat(user, span_warning("No abnormality is contained here."))
		return
	var/mob/living/simple_animal/hostile/abnormality/breacher = datum_reference.current
	if(!breacher.IsContained())
		to_chat(user, span_warning("[breacher] is not currently contained."))
		return
	if(!breacher.can_breach)
		to_chat(user, span_warning("[breacher] cannot be forced to breach."))
		return
	if(mod.charges <= 0)
		to_chat(user, span_warning("The extraction module has no charges left. They regenerate over time."))
		return
	if(!SinToPathKey(breacher.chem_type))
		to_chat(user, span_warning("[breacher] holds no sin the module can extract."))
		return
	Radio.set_frequency(FREQ_DISCIPLINE)
	Radio.talk_into(src, "ALERT: [user.name] is forcing an extraction breach on [breacher.name]. Contain the fallout.", FREQ_DISCIPLINE)
	if(!do_after(user, 5 SECONDS, src))
		return
	if(mod.charges <= 0 || QDELETED(breacher) || !breacher.IsContained())
		return
	if(!mod.SpendCharge())
		return
	RegisterSignal(breacher, COMSIG_LIVING_DEATH, PROC_REF(OnExtractionBreachDeath), override = TRUE)
	var/turf/DT = pick(GLOB.xeno_spawn)
	breacher.forceMove(DT)
	datum_reference.qliphoth_change(-99)
	visible_message(span_bolddanger("[src] tears [breacher] out of containment in a bloom of crystal!"))
	updateUsrDialog()

/obj/machinery/computer/abnormality/proc/OnExtractionBreachDeath(mob/living/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_LIVING_DEATH)
	DropExtractionReward(source)

/// Large T1+T2 Path Material bundle, scaled by the abno's threat grade.
/obj/machinery/computer/abnormality/proc/DropExtractionReward(mob/living/simple_animal/hostile/abnormality/breacher)
	if(QDELETED(breacher))
		return
	var/key = SinToPathKey(breacher.chem_type)
	var/turf/T = get_turf(breacher)
	if(!key || !T)
		return
	var/t1 = 6
	var/t2 = 2
	switch(breacher.GetRiskLevel())
		if(HE_LEVEL)
			t1 = rand(10, 16)
			t2 = rand(6, 10)
		if(WAW_LEVEL)
			t1 = rand(16, 24)
			t2 = rand(10, 17)
		if(ALEPH_LEVEL)
			t1 = rand(22, 33)
			t2 = rand(16, 25)
		else // ZAYIN / TETH
			t1 = rand(6, 10)
			t2 = rand(2, 4)
	var/t1_type = GetPathMatType("path", key, 1)
	var/t2_type = GetPathMatType("path", key, 2)
	if(t1_type)
		new t1_type(T, t1)
	if(t2_type)
		new t2_type(T, t2)
