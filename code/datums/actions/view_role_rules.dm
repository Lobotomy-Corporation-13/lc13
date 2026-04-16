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
