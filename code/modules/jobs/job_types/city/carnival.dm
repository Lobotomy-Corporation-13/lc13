/datum/job/carnival
	title = "Carnival"
	faction = "Station"
	total_positions = 2
	spawn_positions = 2
	supervisors = "your self."
	selection_color = "#555555"
	access = list(ACCESS_CARGO)
	minimal_access = list(ACCESS_CARGO)
	departments = DEPARTMENT_SERVICE
	outfit = /datum/outfit/job/carnival
	display_order = JOB_DISPLAY_ORDER_ANTAG
	exp_requirements = 300

	allow_bureaucratic_error = FALSE
	maptype = "city"
	paycheck = 100

	allow_bureaucratic_error = FALSE
	maptype = list("wonderlabs", "city")
	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 80,
								PRUDENCE_ATTRIBUTE = 80,
								TEMPERANCE_ATTRIBUTE = 80,
								JUSTICE_ATTRIBUTE = 80
								)



/datum/job/carnival/after_spawn(mob/living/carbon/human/H, mob/M, latejoin = FALSE)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	H.set_species(/datum/species/synth/carnival)
	job_important = "You are a Carnival member. Your goal is to gather silk by using the silkweaver on mobs and humans, then sell your woven armors.\n\
			You MAY enter the Ruins to hunt mobs for silk, but you must NOT loot any weapons, armor, or ahn from the Ruins. You also must NOT loot or use gear from other roles.\n\
			While wearing your Carnival Robes, you do NOT need to escalate — you may freely hunt and silk other players. Other players may also attack you without escalation.\n\
			You must NOT kill other players before the 10 minute mark, to give them time to ready up.\n\
			You must NEVER remove someone from the round. Do NOT throw away, eat, or otherwise destroy a player's head."
	var/datum/action/innate/carnival_rules/rules_action = new(H)
	rules_action.Grant(H)
	..()

/datum/outfit/job/carnival
	name = "Carnival"
	jobtype = /datum/job/carnival
	uniform = /obj/item/clothing/under/suit/black
	belt = /obj/item/pda/roboticist
	suit = null
	l_pocket = null
	ears = /obj/item/radio/headset/wcorp/safety
	mask = /obj/item/clothing/mask/carnival_mask
	gloves = /obj/item/clothing/gloves/color/black

	backpack_contents = list(
		/obj/item/book/granter/crafting_recipe/carnival/weaving_armor = 1,
		/obj/item/stack/sheet/silk/indigo_simple = 4,
		/obj/item/stack/sheet/silk/green_simple = 4,
		/obj/item/stack/sheet/silk/amber_simple = 4,
		/obj/item/stack/sheet/silk/steel_simple = 4,
		/obj/item/stack/sheet/silk/human_simple = 1)

	implants = list(
		/obj/item/organ/cyberimp/arm/carnival,		//theyre full body prosthetics, the blades are inside them
		/obj/item/organ/cyberimp/eyes/hud/medical,)	//replaces their med nvg

/datum/action/innate/carnival_rules
	name = "Carnival Rules"
	desc = "Review the rules and guidelines for playing as a Carnival member."
	icon_icon = 'icons/hud/actions.dmi'
	button_icon_state = "round_end"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/innate/carnival_rules/Activate()
	var/mob/living/L = owner
	if(!istype(L))
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
			color: #8b4513;
			border-bottom: 2px solid #8b4513;
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
			border-left: 3px solid #8b4513;
		}
	</style>
</head>
<body>
	<h1>Carnival Rules</h1>

	<div class='section'>
		<h2>Your Goal</h2>
		<p>You are a member of the Carnival. Your <span class='good'>primary objective</span> is to gather silk
		by using your <span class='good'>silkweaver</span> on mobs and humans, and then selling your woven armors to other players.</p>
	</div>

	<div class='section'>
		<h2>Ruins &amp; Looting</h2>
		<p>You <span class='good'>ARE allowed</span> to enter the Ruins for the purpose of hunting down mobs for silk.</p>
		<p>You are <span class='highlight'>NOT allowed</span> to loot any <span class='highlight'>weapons, armor, or ahn</span> from the Ruins.
		You are there to hunt, not to scavenge.</p>
		<p>You are also <span class='highlight'>NOT allowed</span> to loot or use <span class='highlight'>gear from other roles</span>.
		Stick to your own Carnival equipment.</p>
	</div>

	<div class='section'>
		<h2>PvP Rules</h2>
		<p>While you are wearing your <span class='good'>Carnival Robes</span>, there is <span class='good'>no need to escalate</span>.
		You are freely allowed to hunt down and silk other players as long as you are wearing the robes.</p>
		<p>Be aware: <span class='highlight'>other players may also attack you without escalation</span>.
		Wearing the robes makes you a valid target for everyone.</p>
		<p>You must <span class='highlight'>NOT kill other players before the 10 minute mark</span>.
		Give them time to ready up before you start hunting.</p>
	</div>

	<div class='section'>
		<h2>Round Removal</h2>
		<p>You are <span class='highlight'>NEVER allowed</span> to permanently remove someone from the round.</p>
		<p><span class='highlight'>Do NOT</span> throw away, eat, or otherwise destroy another player's head.
		Their body must remain recoverable so they can be revived.</p>
	</div>
</body>
</html>
	"}

	L << browse(html, "window=carnival_rules;size=600x500")
