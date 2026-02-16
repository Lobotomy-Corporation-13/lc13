// Ring Artist Antagonist Datums
// Antagonist datums for the Corporist school of The Ring

/datum/antagonist/ring_artist
	name = "Ring Artist"
	roundend_category = "ring artists"
	antagpanel_category = "Ring"
	show_in_roundend = TRUE
	show_in_antagpanel = TRUE
	/// List of grades received during the round
	var/list/grades_received = list()

/datum/antagonist/ring_artist/on_gain()
	. = ..()
	owner.special_role = name
	// Grant view rules action
	if(owner.current)
		var/datum/action/innate/view_role_rules/ring_artist/action = new(owner.current)
		action.Grant(owner.current)

/datum/antagonist/ring_artist/on_removal()
	// Remove view rules action
	if(owner?.current)
		for(var/datum/action/innate/view_role_rules/ring_artist/action in owner.current.actions)
			action.Remove(owner.current)
	. = ..()

/// Returns formatted HTML content for the rules window
/datum/antagonist/ring_artist/proc/get_rules_html()
	return {"<html><head><style>
		body { background: #1a1a1a; color: #d4d4d4; font-family: Arial, sans-serif; padding: 15px; }
		h1 { color: #ff6b6b; border-bottom: 2px solid #ff6b6b; padding-bottom: 5px; }
		h2 { color: #ffa500; margin-top: 20px; }
		.expected { color: #7cfc00; }
		.permitted { color: #ffd700; }
		.violation { color: #ff4444; font-weight: bold; }
		.info { color: #87ceeb; }
		ul { margin: 5px 0; }
		li { margin: 3px 0; }
	</style></head><body>
		<h1>Ring Artist Rules</h1>
		<p class='info'>You are a member of The Ring, a Syndicate devoted to creating art that reflects the human condition.</p>
	</body></html>"}

/datum/antagonist/ring_artist/roundend_report()
	var/list/report = list()

	report += printplayer(owner)

	// Get EXP info from the artistic_exp component
	var/mob/living/carbon/human/H = owner.current
	if(istype(H))
		var/datum/component/artistic_exp/exp_comp = H.GetComponent(/datum/component/artistic_exp)
		if(exp_comp)
			report += "<b>Final Artistic EXP:</b> [exp_comp.exp]"
			report += "<b>Skill Points Earned:</b> [exp_comp.skill_points + exp_comp.skill_points_spent]"
			if(exp_comp.main_school)
				report += "<b>Main School:</b> [capitalize(exp_comp.main_school)]"

	// Show grades received
	if(length(grades_received))
		report += "<b>Grades Received:</b> [grades_received.Join(", ")]"

		// Count each grade type
		var/list/grade_counts = list("S" = 0, "A" = 0, "B" = 0, "C" = 0, "F" = 0)
		for(var/grade in grades_received)
			if(grade in grade_counts)
				grade_counts[grade]++

		report += "<b>Grade Summary:</b> S:[grade_counts["S"]] A:[grade_counts["A"]] B:[grade_counts["B"]] C:[grade_counts["C"]] F:[grade_counts["F"]]"
	else
		report += "<b>Grades Received:</b> None"

	return report.Join("<br>")

/datum/antagonist/ring_artist/roundend_report_footer()
	var/list/result = list()

	// Find the artist with highest EXP (excluding Maestro - they don't compete)
	var/highest_exp = 0
	var/datum/antagonist/ring_artist/top_artist = null

	for(var/datum/antagonist/ring_artist/RA in GLOB.antagonists)
		// Skip maestros - they are the judges, not the judged
		if(istype(RA, /datum/antagonist/ring_artist/maestro))
			continue
		if(!RA.owner || !RA.owner.current)
			continue
		if(!ishuman(RA.owner.current))
			continue

		var/mob/living/carbon/human/H = RA.owner.current
		var/datum/component/artistic_exp/exp_comp = H.GetComponent(/datum/component/artistic_exp)
		if(exp_comp && exp_comp.exp > highest_exp)
			highest_exp = exp_comp.exp
			top_artist = RA

	if(top_artist)
		result += "<br><span class='header'>Top Ring Artist:</span>"
		result += "<b>[top_artist.owner.name]</b> earned [highest_exp] Artistic EXP!"
		if(length(top_artist.grades_received))
			result += "<b>Their Grades:</b> [top_artist.grades_received.Join(", ")]"

	return result.Join("<br>")

// ===================== MAESTRO =====================

/datum/antagonist/ring_artist/maestro
	name = "Ring Maestro"

/datum/antagonist/ring_artist/maestro/greet()
	to_chat(owner.current, span_userdanger("You are a Maestro of the Corporist school!"))
	to_chat(owner.current, span_boldnotice("The Ring is a Syndicate devoted to creating art that reflects the human condition through exhibiting human suffering."))
	to_chat(owner.current, span_boldnotice("As a Corporist, you specialize in utilizing the interaction between human bones and muscles."))
	to_chat(owner.current, " ")
	to_chat(owner.current, span_bold("RULES OF CONDUCT:"))
	to_chat(owner.current, span_nicegreen("EXPECTED: Creating art from the flesh of creatures"))
	to_chat(owner.current, span_nicegreen("EXPECTED: Educating others about the Corporist arts"))
	to_chat(owner.current, span_nicegreen("EXPECTED: Teaching and mentoring aspiring artists"))
	to_chat(owner.current, span_notice("PERMITTED: Judging others' artwork (fairly or unfairly, for artistic reasons)"))
	to_chat(owner.current, span_warning("PERMITTED: Slaying those who prevent your art from being created"))
	to_chat(owner.current, span_warning("PERMITTED: Slaying those who insult, break, or steal your artwork"))
	to_chat(owner.current, span_boldwarning("VIOLATION: Killing those who pose no threat to your art or artistic mission"))
	to_chat(owner.current, " ")
	to_chat(owner.current, span_notice("Use the 'View Ring Rules' action to review your rules and judging guidelines."))

/datum/antagonist/ring_artist/maestro/get_rules_html()
	return {"<html><head><style>
		body { background: #1a1a1a; color: #d4d4d4; font-family: Arial, sans-serif; padding: 15px; }
		h1 { color: #ff6b6b; border-bottom: 2px solid #ff6b6b; padding-bottom: 5px; }
		h2 { color: #ffa500; margin-top: 20px; }
		h3 { color: #87ceeb; margin-top: 15px; }
		.expected { color: #7cfc00; }
		.permitted { color: #ffd700; }
		.violation { color: #ff4444; font-weight: bold; }
		.info { color: #87ceeb; }
		.grade-s { color: #ff00ff; font-weight: bold; }
		.grade-a { color: #00ff00; }
		.grade-b { color: #ffff00; }
		.grade-c { color: #ffa500; }
		.grade-f { color: #ff4444; }
		ul { margin: 5px 0; }
		li { margin: 3px 0; }
		table { border-collapse: collapse; width: 100%; margin: 10px 0; }
		th, td { border: 1px solid #555; padding: 8px; text-align: left; vertical-align: top; }
		th { background: #333; color: #ffa500; }
		td { background: #252525; }
		.aspect { color: #87ceeb; font-weight: bold; }
	</style></head><body>
		<h1>Corporist Maestro - Rules of Conduct</h1>
		<p class='info'>You are a Maestro of the Corporist school of The Ring, a Syndicate devoted to creating art that reflects the human condition through exhibiting human suffering.</p>

		<h2>Conduct</h2>
		<ul>
			<li class='expected'>EXPECTED: Creating art from the flesh of creatures</li>
			<li class='expected'>EXPECTED: Educating others about the Corporist arts</li>
			<li class='expected'>EXPECTED: Teaching and mentoring aspiring artists</li>
			<li class='permitted'>PERMITTED: Judging others' artwork (fairly or unfairly, for artistic reasons)</li>
			<li class='permitted'>PERMITTED: Slaying those who prevent your art from being created</li>
			<li class='permitted'>PERMITTED: Slaying those who insult, break, or steal your artwork</li>
			<li class='violation'>VIOLATION: Killing those who pose no threat to your art or artistic mission</li>
		</ul>

		<h2>Judging Guidelines</h2>
		<p>When evaluating an artwork, the Maestro should consider these four aspects:</p>

		<table>
			<tr>
				<th>Aspect</th>
				<th>What to Evaluate</th>
				<th>Questions to Ask</th>
			</tr>
			<tr>
				<td class='aspect'>Composition</td>
				<td>The bodyparts and creatures used in the artwork</td>
				<td>Do the materials follow an artistic theme? Is there meaning in their selection? Did they use specific creature types or bodypart combinations intentionally?</td>
			</tr>
			<tr>
				<td class='aspect'>Investment</td>
				<td>The tier of the artwork and materials invested</td>
				<td>How many resources did they put into this work? Did they take time to build it up, or is it a rushed piece? Higher tiers show greater dedication.</td>
			</tr>
			<tr>
				<td class='aspect'>Technique</td>
				<td>The technique grade from the sculpting minigame</td>
				<td>How delicate and precise was their handywork? A high technique grade (A or S) shows mastery of the craft. Low grades suggest carelessness.</td>
			</tr>
			<tr>
				<td class='aspect'>Vision</td>
				<td>The custom description written by the artist</td>
				<td>Did they describe their own artwork? How eloquent and meaningful is their description? Does it convey artistic intent and vision?</td>
			</tr>
		</table>

		<h3>Grading Criteria</h3>
		<ul>
			<li class='grade-s'>S Grade (30 min cooldown): A true masterwork. Profound artistic vision that transcends the medium. Reserve this for exceptional works that move you deeply.</li>
			<li class='grade-a'>A Grade (5 min cooldown): Excellent technique and creativity. Shows mastery of the Corporist arts.</li>
			<li class='grade-b'>B Grade: Competent work that demonstrates solid skill and understanding.</li>
			<li class='grade-c'>C Grade: Adequate but uninspired. The artist shows potential but lacks vision.</li>
			<li class='grade-f'>F Grade: Poor execution or a failed artistic vision. A teaching moment.</li>
		</ul>

		<h3>Judging Philosophy</h3>
		<ul>
			<li>You may grade based on artistic merit, rewarding those who show true talent.</li>
			<li>You may also grade unfairly for artistic reasons - rivalry, drama, and favoritism are all part of the art world.</li>
			<li>A higher tier artwork does not guarantee a higher grade - a small piece with vision may outshine a large but soulless work.</li>
			<li>Your judgment shapes your students' futures. Use this power wisely... or don't.</li>
		</ul>

		<h3>Remember</h3>
		<p>You cannot judge your own artwork. A true artist seeks the judgment of others.</p>
	</body></html>"}

// ===================== APPRENTICE =====================

/datum/antagonist/ring_artist/apprentice
	name = "Ring Apprentice"

/datum/antagonist/ring_artist/apprentice/greet()
	to_chat(owner.current, span_userdanger("You have become a Corporist Apprentice!"))
	to_chat(owner.current, span_boldnotice("You now serve your Maestro and The Ring's artistic vision."))
	to_chat(owner.current, span_boldnotice("Your previous life is behind you. The art is all that matters now."))
	to_chat(owner.current, " ")
	to_chat(owner.current, span_bold("RULES OF CONDUCT:"))
	to_chat(owner.current, span_warning("Your previous faction allegiances are LOST"))
	to_chat(owner.current, span_warning("Your previous special permissions are LOST"))
	to_chat(owner.current, span_notice("PERMITTED: Defending your art and your Maestro's vision"))
	to_chat(owner.current, span_boldwarning("VIOLATION: Killing those unrelated to your artistic mission"))
	to_chat(owner.current, " ")
	to_chat(owner.current, span_notice("Use the 'View Ring Rules' action to review your rules at any time."))

/datum/antagonist/ring_artist/apprentice/get_rules_html()
	return {"<html><head><style>
		body { background: #1a1a1a; color: #d4d4d4; font-family: Arial, sans-serif; padding: 15px; }
		h1 { color: #ff6b6b; border-bottom: 2px solid #ff6b6b; padding-bottom: 5px; }
		h2 { color: #ffa500; margin-top: 20px; }
		h3 { color: #87ceeb; margin-top: 15px; }
		.expected { color: #7cfc00; }
		.permitted { color: #ffd700; }
		.violation { color: #ff4444; font-weight: bold; }
		.warning { color: #ffa500; }
		.info { color: #87ceeb; }
		ul { margin: 5px 0; }
		li { margin: 3px 0; }
	</style></head><body>
		<h1>Corporist Apprentice - Rules of Conduct</h1>
		<p class='info'>You have been elevated to Apprentice of the Corporist school. Your previous life is behind you - the art is all that matters now.</p>

		<h2>Your New Identity</h2>
		<ul>
			<li class='warning'>Your previous faction allegiances are LOST</li>
			<li class='warning'>Your previous special permissions are LOST</li>
			<li>You now serve your Maestro and The Ring's artistic vision</li>
			<li>Your body has been transformed into a prosthetic vessel for your art</li>
		</ul>

		<h2>Conduct</h2>
		<ul>
			<li class='expected'>EXPECTED: Creating art from the flesh of creatures</li>
			<li class='expected'>EXPECTED: Following your Maestro's guidance</li>
			<li class='permitted'>PERMITTED: Defending your art and your Maestro's vision</li>
			<li class='permitted'>PERMITTED: Competition with other students for the Maestro's favor</li>
			<li class='violation'>VIOLATION: Killing those unrelated to your artistic mission</li>
		</ul>

		<h2>Competition</h2>
		<p>As an Apprentice, you are above the petty squabbles of Students, but competition for the Maestro's favor continues:</p>
		<ul>
			<li>Your artwork will be judged by the Maestro</li>
			<li>Earn EXP through creating and refining artwork</li>
			<li>The artist with the most EXP is celebrated at round end</li>
			<li>Higher grades from the Maestro mean greater recognition</li>
		</ul>

		<h3>Remember</h3>
		<p>You have given up everything to pursue the arts. Make it worth the sacrifice.</p>
	</body></html>"}

// ===================== STUDENT =====================

/datum/antagonist/ring_artist/student
	name = "Ring Student"

/datum/antagonist/ring_artist/student/greet()
	to_chat(owner.current, span_userdanger("You are now a Student of The Ring!"))
	to_chat(owner.current, span_boldnotice("You have proven your dedication to the artistic path."))
	to_chat(owner.current, span_boldnotice("Compete with your fellow students for the Maestro's favor."))
	to_chat(owner.current, " ")
	to_chat(owner.current, span_bold("RULES OF CONDUCT:"))
	to_chat(owner.current, span_warning("Your previous faction allegiances are LOST"))
	to_chat(owner.current, span_notice("Your previous special permissions are KEPT"))
	to_chat(owner.current, span_notice("PERMITTED: Defending your art"))
	to_chat(owner.current, span_notice("PERMITTED: Infighting and sabotage against other students for better grades"))
	to_chat(owner.current, span_boldwarning("VIOLATION: Killing those unrelated to your artistic mission"))
	to_chat(owner.current, " ")
	to_chat(owner.current, span_boldnotice("TIP: Sabotage is preferred over murder. If you must kill, don't get caught."))
	to_chat(owner.current, span_notice("Use the 'View Ring Rules' action for detailed sabotage methods and competition rules."))

/datum/antagonist/ring_artist/student/get_rules_html()
	return {"<html><head><style>
		body { background: #1a1a1a; color: #d4d4d4; font-family: Arial, sans-serif; padding: 15px; }
		h1 { color: #ff6b6b; border-bottom: 2px solid #ff6b6b; padding-bottom: 5px; }
		h2 { color: #ffa500; margin-top: 20px; }
		h3 { color: #87ceeb; margin-top: 15px; }
		.expected { color: #7cfc00; }
		.permitted { color: #ffd700; }
		.violation { color: #ff4444; font-weight: bold; }
		.warning { color: #ffa500; }
		.info { color: #87ceeb; }
		.tip { color: #ff69b4; font-style: italic; }
		ul { margin: 5px 0; }
		li { margin: 3px 0; }
	</style></head><body>
		<h1>Ring Student - Rules of Conduct</h1>
		<p class='info'>You have proven your dedication to the artistic path. Now compete with your fellow students for the Maestro's favor.</p>

		<h2>Your Status</h2>
		<ul>
			<li class='warning'>Your previous faction allegiances are LOST</li>
			<li class='permitted'>Your previous special permissions are KEPT</li>
			<li>You are a student of The Ring, learning the Corporist arts</li>
		</ul>

		<h2>Conduct</h2>
		<ul>
			<li class='permitted'>PERMITTED: Defending your art</li>
			<li class='permitted'>PERMITTED: Infighting and sabotage against other students</li>
			<li class='permitted'>PERMITTED: Competition for the Maestro's favor</li>
			<li class='violation'>VIOLATION: Killing those unrelated to your artistic mission</li>
		</ul>

		<h2>Competition</h2>
		<p>The Ring encourages artistic competition among students:</p>
		<ul>
			<li>The student with the highest Artistic EXP at round end is celebrated as the Top Ring Artist</li>
			<li>Grades from the Maestro affect your standing and provide EXP bonuses</li>
			<li>Sabotage of other students' art is not only permitted - it is expected</li>
			<li>An Apprentice may be chosen from among the most promising students</li>
		</ul>

		<h2>Sabotage Methods</h2>
		<p class='info'>The art world is cutthroat. Here are some ways to get ahead:</p>
		<ul>
			<li><b>Destroy rival artwork</b> - A smashed sculpture cannot earn a grade</li>
			<li><b>Steal artwork</b> - Claim a rival's creation as your own before they can show the Maestro</li>
			<li><b>Lead dangerous creatures to rivals</b> - Accidents happen in the art world</li>
			<li><b>Interfere with sculpting</b> - Interrupt a rival's work to ruin their concentration</li>
			<li><b>Spread misinformation</b> - Tell the Maestro their work is derivative or stolen</li>
			<li><b>Hoard materials</b> - Bodies are finite. Claim them before your rivals can</li>
			<li><b>Distract with false opportunities</b> - Send rivals on wild goose chases</li>
		</ul>

		<h3>Guidelines for Violence</h3>
		<ul>
			<li class='tip'>Sabotage is preferred over murder</li>
			<li class='tip'>If you must kill a rival, don't get caught</li>
			<li class='tip'>Make it look like an accident or abnormality attack</li>
			<li class='tip'>Dead rivals can't compete, but witnesses can report you</li>
		</ul>

		<h3>Remember</h3>
		<p>The Maestro's judgment is final. Curry their favor through excellent art... or through the destruction of your competition.</p>
	</body></html>"}
