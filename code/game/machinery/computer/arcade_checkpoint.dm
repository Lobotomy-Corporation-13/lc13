/// K Corp Immigration Checkpoint - Papers Please inspired
/// Process migration documents at K Corp District 11.
/// Spot discrepancies, stamp APPROVED or DENIED.
/// Game engine runs client-side in JavaScript.

// Name pools for applicant generation
GLOBAL_LIST_INIT(checkpoint_first_names, list(
	"Yun", "Kim", "Park", "Choi", "Kang",
	"Han", "Seo", "Lim", "Shin", "Song",
	"Jang", "Baek", "Yoo", "Moon", "Noh",
	"Elena", "Vergilius", "Dante", "Faust",
	"Roland", "Miriam", "Oscar", "Cecil",
	"Rion", "Sasha", "Tanya", "Boris",
	"Greta", "Lucia", "Ezra", "Mei"))

GLOBAL_LIST_INIT(checkpoint_last_names, list(
	"Sejun", "Minho", "Jiwoo", "Haneul",
	"Doyun", "Soojin", "Taehyung", "Eunji",
	"Jaehyun", "Yeonwoo", "Aris", "Voss",
	"Thane", "Krol", "Holtz", "Varga",
	"Stern", "Reis", "Volk", "Lenz",
	"Wirth", "Kraus", "Blum", "Feld"))

GLOBAL_LIST_INIT(checkpoint_corps, list(
	"K Corp.", "R Corp.", "T Corp.", "G Corp.",
	"N Corp.", "W Corp.", "H Corp.", "P Corp."))

GLOBAL_LIST_INIT(checkpoint_seal_colors, list(
	"K Corp." = "emerald",
	"R Corp." = "red",
	"T Corp." = "sepia",
	"G Corp." = "silver",
	"N Corp." = "white",
	"W Corp." = "blue",
	"H Corp." = "crimson",
	"P Corp." = "gold"))

GLOBAL_LIST_INIT(checkpoint_hair, list(
	"black", "brown", "blonde", "red", "grey", "white"))

GLOBAL_LIST_INIT(checkpoint_eyes, list(
	"brown", "blue", "green", "grey", "amber"))

/obj/machinery/computer/arcade/checkpoint
	name = "K Corp Checkpoint Arcade"
	desc = "Process immigration documents at K Corp District 11. Don't let the wrong ones through."
	icon_state = "arcade"
	icon_keyboard = "no_keyboard"
	icon_screen = "invaders"
	light_color = "#22cc66"
	circuit = /obj/item/circuitboard/computer/arcade/checkpoint
	/// Leaderboard: list of list("name","score")
	var/list/leaderboard = list()
	var/last_sfx_time = 0

/obj/machinery/computer/arcade/checkpoint/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ArcadeCheckpoint", name)
		ui.open()

/obj/machinery/computer/arcade/checkpoint/ui_static_data(mob/user)
	var/list/data = list()
	data["days"] = generate_all_days()
	data["gameDate"] = "984-03-15"
	return data

/obj/machinery/computer/arcade/checkpoint/ui_data(mob/user)
	var/list/data = list()
	data["leaderboard"] = leaderboard
	return data

/obj/machinery/computer/arcade/checkpoint/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("submit_score")
			var/score = text2num(params["score"])
			var/pname = usr?.name || "Unknown"
			leaderboard += list(list("name" = pname, "score" = score))
			leaderboard = sortTim(leaderboard, /proc/cmp_leaderboard_desc)
			if(length(leaderboard) > 10)
				leaderboard.Cut(11)
			prizevend(usr)
			playsound(loc, 'sound/arcade/win.ogg', 50, TRUE)
			. = TRUE
		if("died")
			playsound(loc, 'sound/arcade/lose.ogg', 50, TRUE)
			. = TRUE
		if("restart")
			update_static_data(usr)
			. = TRUE
		if("sfx")
			var/snd = params["s"]
			if(world.time - last_sfx_time < 3)
				return
			last_sfx_time = world.time
			switch(snd)
				if("stamp")
					playsound(loc, 'sound/arcade/hit.ogg', 35, TRUE)
				if("correct")
					playsound(loc, 'sound/arcade/heal.ogg', 30, TRUE)
				if("wrong")
					playsound(loc, 'sound/arcade/boom.ogg', 35, TRUE)
				if("bell")
					playsound(loc, 'sound/arcade/mana.ogg', 30, TRUE)
			. = TRUE

/// Generates all 7 days of applicant data
/obj/machinery/computer/arcade/checkpoint/proc/generate_all_days()
	var/list/days = list()
	for(var/d in 1 to 7)
		days += list(generate_day(d))
	return days

/// Generates one day's data
/obj/machinery/computer/arcade/checkpoint/proc/generate_day(day_num)
	var/list/day = list()
	day["day"] = day_num
	day["timeLimit"] = 180

	// Rules for display
	var/list/rules = list(
		"Check passport expiry date",
		"Valid districts: 1-26 only",
		"Today is 984-03-15"
	)
	var/list/banned = list()
	var/list/stolen = list()
	var/list/dupes = list()

	if(day_num >= 2)
		rules += "Visa required for all"
		rules += "Visa name must match passport"
	if(day_num >= 3)
		rules += "Fixers need Hana license"
		rules += "Fixer minimum age: 20"
	if(day_num >= 4)
		rules += "Wing employees need cert"
		rules += "Check corporate seal color"
		banned += rand(1, 9) * 2
	if(day_num >= 5)
		rules += "Check bulletin for stolen IDs"
		for(var/si in 1 to 3)
			stolen += "NEP-[rand(100000, 999999)]"
	if(day_num >= 6)
		rules += "Visitor visa max 14 days"
		rules += "Verify photo matches"
		banned += rand(10, 19)
	if(day_num >= 7)
		banned += rand(20, 25)
		for(var/di in 1 to 2)
			dupes += "BTP-[rand(100000, 999999)]"

	day["rules"] = rules
	day["banned"] = banned
	day["stolen"] = stolen
	day["dupes"] = dupes

	// Generate applicants
	var/app_count = 10 + day_num
	var/list/applicants = list()
	for(var/ai in 1 to app_count)
		applicants += list(generate_applicant(day_num, banned, stolen, dupes))
	day["applicants"] = applicants
	return day

/// Generates one applicant
/obj/machinery/computer/arcade/checkpoint/proc/generate_applicant(day_num, list/banned, list/stolen, list/dupes)
	var/list/app = list()

	// Identity
	var/fname = pick(GLOB.checkpoint_first_names)
	var/lname = pick(GLOB.checkpoint_last_names)
	var/full_name = "[fname] [lname]"
	var/district = rand(1, 26)
	var/age = rand(18, 55)
	var/dob_year = 984 - age
	var/dob = "[dob_year]-[rand(1,12)]-[rand(1,28)]"
	var/hair = pick(GLOB.checkpoint_hair)
	var/eyes = pick(GLOB.checkpoint_eyes)
	var/has_prosth = prob(40)
	var/prosth = has_prosth ? pick("left arm", "right arm", "jaw", "eyes") : "none"
	var/gender = prob(50) ? "M" : "F"

	app["name"] = full_name
	app["appearance"] = list(
		"hair" = hair,
		"eyes" = eyes,
		"prosthetic" = prosth,
		"gender" = gender
	)

	// Decide if valid or has discrepancy
	var/valid = prob(45 + (7 - day_num) * 2)
	var/list/reasons = list()

	// Build documents based on day
	var/list/docs = list()

	// Passport (always present)
	var/passport_num = "NEP-[rand(100000, 999999)]"
	var/passport_exp = "985-[rand(1,12)]-[rand(1,28)]"
	var/p_name = full_name
	var/p_district = district
	var/p_hair = hair
	var/p_eyes = eyes
	var/p_prosth = prosth

	if(!valid)
		// Build list of possible discrepancies
		var/list/possible = list("expired", "bad_district")
		if(length(banned))
			possible += "banned"
		if(length(stolen) && day_num >= 5)
			possible += "stolen"
		if(day_num >= 6)
			possible += "photo"
		if(day_num >= 2)
			possible += "visa_name"

		var/disc = pick(possible)
		switch(disc)
			if("expired")
				passport_exp = "983-[rand(1,12)]-[rand(1,28)]"
				reasons += "Passport expired"
			if("bad_district")
				p_district = pick(0, 27, 28, 30, 99)
				reasons += "Invalid district"
			if("banned")
				p_district = pick(banned)
				reasons += "Banned district"
			if("stolen")
				passport_num = pick(stolen)
				reasons += "Stolen passport"
			if("photo")
				p_hair = pick(GLOB.checkpoint_hair - hair)
				reasons += "Photo mismatch"
			if("visa_name")
				// handled in visa section below
				valid = FALSE

	docs += list(list(
		"type" = "passport",
		"name" = p_name,
		"dob" = dob,
		"district" = p_district,
		"expires" = passport_exp,
		"number" = passport_num,
		"hair" = p_hair,
		"eyes" = p_eyes,
		"prosthetic" = p_prosth,
		"gender" = gender
	))

	// Visa (day 2+)
	if(day_num >= 2)
		var/visa_type = pick("Worker", "Visitor", "Transit")
		var/visa_exp = "985-[rand(1,12)]-[rand(1,28)]"
		var/v_name = full_name
		var/v_issuer = "K Corp. Bureau"
		var/v_duration = 30

		if(visa_type == "Transit")
			v_duration = 7
		if(visa_type == "Visitor" && day_num >= 6)
			v_duration = 14

		if(!valid && !length(reasons))
			var/vdisc = rand(1, 3)
			switch(vdisc)
				if(1)
					visa_exp = "983-[rand(1,6)]-[rand(1,28)]"
					reasons += "Visa expired"
				if(2)
					v_name = "[pick(GLOB.checkpoint_first_names)] [lname]"
					reasons += "Visa name mismatch"
				if(3)
					if(day_num >= 6 && visa_type == "Visitor")
						v_duration = rand(20, 45)
						reasons += "Visitor duration exceeds 14 days"

		docs += list(list(
			"type" = "visa",
			"name" = v_name,
			"visaType" = visa_type,
			"issuer" = v_issuer,
			"expires" = visa_exp,
			"duration" = v_duration
		))

	// Fixer License (day 3+, some applicants)
	if(day_num >= 3 && prob(35))
		var/f_name = full_name
		var/f_grade = rand(2, 8)
		var/f_fitness = "PASS"
		var/f_issuer = "Hana Association"
		var/f_exp = "985-[rand(1,12)]-[rand(1,28)]"

		if(!valid && !length(reasons))
			var/fdisc = rand(1, 3)
			switch(fdisc)
				if(1)
					if(age < 20)
						reasons += "Fixer under age 20"
					else
						// Force underage
						dob_year = 984 - rand(16, 19)
						dob = "[dob_year]-[rand(1,12)]-[rand(1,28)]"
						// Update passport DOB
						docs[1]["dob"] = dob
						reasons += "Fixer under age 20"
				if(2)
					f_fitness = "FAIL"
					reasons += "Fitness stamp FAIL"
				if(3)
					f_issuer = "Tres Association"
					reasons += "Wrong license issuer"

		docs += list(list(
			"type" = "fixer",
			"name" = f_name,
			"grade" = f_grade,
			"fitness" = f_fitness,
			"issuer" = f_issuer,
			"expires" = f_exp
		))

	// Employment Cert (day 4+, some applicants)
	if(day_num >= 4 && prob(30))
		var/corp = pick(GLOB.checkpoint_corps)
		var/real_seal = GLOB.checkpoint_seal_colors[corp]
		var/seal = real_seal
		var/feather = (corp == "K Corp.") ? "Rank [rand(1,5)]" : "N/A"
		var/e_name = full_name

		if(!valid && !length(reasons))
			var/edisc = rand(1, 2)
			switch(edisc)
				if(1)
					// Wrong seal color
					var/list/wrong = list("emerald", "red", "sepia", "silver", "blue") - real_seal
					seal = pick(wrong)
					reasons += "Wrong seal color"
				if(2)
					// Non-K Corp with Feather
					if(corp != "K Corp.")
						feather = "Rank [rand(1,3)]"
						reasons += "Non-K Corp with Feather rank"

		docs += list(list(
			"type" = "employment",
			"name" = e_name,
			"corp" = corp,
			"seal" = seal,
			"feather" = feather
		))

	// Transit Pass (day 5+, some applicants)
	if(day_num >= 5 && prob(25))
		var/t_dest = 11
		var/t_origin = rand(1, 26)
		var/t_num = "BTP-[rand(100000, 999999)]"
		var/t_name = full_name

		if(!valid && !length(reasons))
			var/tdisc = rand(1, 3)
			switch(tdisc)
				if(1)
					t_dest = pick(1, 5, 8, 14, 20)
					reasons += "Wrong destination"
				if(2)
					if(length(dupes))
						t_num = pick(dupes)
						reasons += "Duplicate pass number"
				if(3)
					if(length(banned))
						t_origin = pick(banned)
						reasons += "Origin is banned district"

		docs += list(list(
			"type" = "transit",
			"name" = t_name,
			"origin" = t_origin,
			"destination" = t_dest,
			"number" = t_num
		))

	app["documents"] = docs
	if(length(reasons))
		app["verdict"] = "DENY"
		app["reasons"] = reasons
	else
		app["verdict"] = "APPROVE"
		app["reasons"] = list()
	return app

// Circuit board
/obj/item/circuitboard/computer/arcade/checkpoint
	name = "K Corp Checkpoint Arcade (Computer Board)"
	icon_state = "generic"
	build_path = /obj/machinery/computer/arcade/checkpoint
