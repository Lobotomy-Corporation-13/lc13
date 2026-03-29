// ================== GENERAL VIEW ROLE RULES ==================
// Base action for viewing role-specific rules in a browser window.
// Subtype this and override get_rules_content() to add your rules.

/datum/action/innate/view_role_rules
	name = "View Role Rules"
	desc = "Review your role's rules and guidelines."
	icon_icon = 'icons/hud/actions.dmi'
	button_icon_state = "round_end"
	check_flags = AB_CHECK_CONSCIOUS
	/// Title displayed at the top of the rules window
	var/rules_title = "Role Rules"
	/// Accent color for headers and borders
	var/accent_color = "#8b4513"
	/// Browser window ID
	var/window_name = "role_rules"
	/// Browser window size
	var/window_size = "600x500"

/datum/action/innate/view_role_rules/Activate()
	var/mob/living/L = owner
	if(!istype(L))
		return

	var/content = get_rules_content()
	if(!content)
		to_chat(L, span_warning("No rules available."))
		return

	var/html = {"
<!DOCTYPE html>
<html>
<head>
	<style>
		body {
			background-color: #1a1a1a;
			color: #c0c0c0;
			font-family: 'Segoe UI', Tahoma, sans-serif;
			padding: 20px;
			line-height: 1.6;
		}
		h1 {
			color: [accent_color];
			border-bottom: 2px solid [accent_color];
			padding-bottom: 10px;
		}
		h2 {
			color: #d4af37;
			margin-top: 20px;
		}
		.highlight {
			color: #ff6b6b;
			font-weight: bold;
		}
		.good {
			color: #7cfc00;
		}
		.warning {
			color: #ffa500;
		}
		ul {
			margin-left: 20px;
		}
		li {
			margin-bottom: 8px;
		}
		.section {
			background-color: #2a2a2a;
			padding: 15px;
			margin: 10px 0;
			border-left: 3px solid [accent_color];
		}
	</style>
</head>
<body>
	<h1>[rules_title]</h1>
	[content]
</body>
</html>
	"}

	L << browse(html, "window=[window_name];size=[window_size]")

/// Override this proc in subtypes to provide the rules body HTML (everything inside <body> after the title)
/datum/action/innate/view_role_rules/proc/get_rules_content()
	return ""

// ================== INDEX ORACLE PROXY RULES ==================

/datum/action/innate/view_role_rules/index_oracle
	name = "View Index Rules"
	desc = "Review the Index Oracle's trusted role rulings."
	rules_title = "Index Oracle - Trusted Role Rulings"
	accent_color = "#4a7c8f"
	window_name = "index_oracle_rules"
	window_size = "600x700"

/datum/action/innate/view_role_rules/index_oracle/get_rules_content()
	return {"
	<div class="section">
		<h2>Your Purpose</h2>
		<p>You are a wandering proxy of the Index, carrying out prescripts delivered to you by the Oracle. You are <span class="warning">not inherently hostile</span>, but you must follow the prescripts you receive. You exist to enact the Oracle's will -- nothing more, nothing less.</p>
	</div>

	<div class="section">
		<h2>The Prescripts</h2>
		<p>Your <b>Index Pager</b> will deliver prescripts to you throughout the round. These are your primary objectives and the core of your roleplay.</p>
		<ul>
			<li>You <span class="good">must</span> follow the prescripts you receive. They are the will of the Oracle.</li>
			<li>You are still beholden to <span class="highlight">server rules</span> when performing prescripts -- this includes escalation.</li>
			<li>If you feel like you're getting too many <span class="highlight">"KILL X IF THEY DO NOT Y"</span> prescripts, then AHelp.</li>
			<li>Use the prescripts as RP hooks -- announce ultimatums, give warnings, negotiate. You are a messenger first, a fighter second.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Recruiting an Apprentice</h2>
		<p>You have a <b>Proxy Apprenticeship Scroll</b> that lets you recruit one player as your apprentice. This is a <span class="good">roleplay opportunity</span> -- choose someone who will engage with the role, not just someone you want to buff.</p>
		<ul>
			<li>Your apprentice receives their own pager and follows the same prescripts.</li>
			<li>They are your responsibility -- guide them and work together.</li>
			<li>The scroll can only be used <span class="warning">once</span>. Choose wisely.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Clone Decay</h2>
		<p>Every wound you take leaves a permanent mark -- <span class="highlight">5% of all damage becomes unhealable</span>. This is not just a mechanic, it's a <span class="warning">roleplay consideration</span>.</p>
		<ul>
			<li>You are powerful but <span class="highlight">not invincible</span>. Every fight chips away at you permanently.</li>
			<li>Pick your battles wisely. Prolonged combat will leave you a shell of your former self.</li>
			<li>Use your evasion passives -- you dodge automatically and more frequently when unarmed. Sometimes discretion is the better part of valor.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Conduct and Escalation</h2>
		<ul>
			<li><span class="warning">Avoid killing other players without a reason.</span> Killing a player for stopping your prescripts is a valid reason.</li>
			<li>You may enter the backstreets with sufficient reasoning but <span class="warning">not</span> for the express purpose of looting or hunting fixers.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Interacting with the Index Syndicate</h2>
		<p>The Index Syndicate being active in the area is not of your concern -- you work independently of them. You can choose to help them if you so desire, but it should not be your priority. After all, whatever happens to them is likely the Prescript's Will.</p>
	</div>
	"}

// ================== INDEX PROXY APPRENTICE RULES ==================

/datum/action/innate/view_role_rules/index_apprentice
	name = "View Index Rules"
	desc = "Review the Index Proxy Apprentice's trusted role rulings."
	rules_title = "Index Proxy Apprentice - Trusted Role Rulings"
	accent_color = "#4a7c8f"
	window_name = "index_apprentice_rules"
	window_size = "600x700"

/datum/action/innate/view_role_rules/index_apprentice/get_rules_content()
	return {"
	<div class="section">
		<h2>Your Purpose</h2>
		<p>You have been recruited by an Index Proxy to serve as their apprentice. You must follow the prescripts you receive and <span class="good">assist your mentor</span> in carrying them out. Your loyalty is to the Oracle's will, enacted through your mentor.</p>
	</div>

	<div class="section">
		<h2>The Prescripts</h2>
		<p>Your <b>Index Pager</b> will deliver the same prescripts as your mentor. You share their mission.</p>
		<ul>
			<li>You <span class="good">must</span> follow the prescripts you receive and support your mentor in completing them.</li>
			<li>You are still beholden to <span class="highlight">server rules</span> when performing prescripts -- this includes escalation.</li>
			<li>If you feel like you're getting too many <span class="highlight">"KILL X IF THEY DO NOT Y"</span> prescripts, then AHelp.</li>
			<li>Coordinate with your mentor -- you are their partner, not a solo agent.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Your Mentor</h2>
		<p>The proxy who recruited you is your mentor and your primary point of contact with the Index.</p>
		<ul>
			<li>Work <span class="good">alongside</span> your mentor. Follow their lead on how to approach prescripts.</li>
			<li>If your mentor dies, you are still bound to complete any active prescripts.</li>
			<li>You are not your mentor's servant -- you are their <span class="good">partner in the Oracle's work</span>.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Clone Decay</h2>
		<p>Like your mentor, every wound you take leaves a permanent mark -- <span class="highlight">5% of all damage becomes unhealable</span>.</p>
		<ul>
			<li>You are strong but <span class="highlight">not invincible</span>. Every fight chips away at you permanently.</li>
			<li>Pick your battles wisely. Let your mentor take the lead in dangerous situations.</li>
			<li>You dodge automatically and more frequently when unarmed -- sometimes retreating is the right call.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Chains and Procuration</h2>
		<p>Your armor grants you the ability to summon chains as a weapon. As you prove yourself by completing prescripts, your chains can <span class="good">transform into something greater</span>.</p>
		<ul>
			<li>Completing prescripts progresses you toward <span class="good">Effloresced E.G.O :: Procuration</span>, a stronger weapon.</li>
			<li>If you are gravely wounded while your chains are active, desperation may trigger the transformation early.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Conduct and Escalation</h2>
		<ul>
			<li><span class="warning">Avoid killing other players without a reason.</span> Killing a player for stopping your prescripts is a valid reason.</li>
			<li>You may enter the backstreets with sufficient reasoning but <span class="warning">not</span> for the express purpose of looting or hunting fixers.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Interacting with the Index Syndicate</h2>
		<p>The Index Syndicate being active in the area is not of your concern -- you work independently of them. You can choose to help them if you so desire, but it should not be your priority. After all, whatever happens to them is likely the Prescript's Will.</p>
	</div>
	"}
