/obj/item/paper/distortion/clue
	name = "page"
	desc = "A sheet of office paper, soft at the edges. Something is written on it."
	var/role
	var/lifetime = 3 MINUTES

/obj/item/paper/distortion/clue/Initialize(mapload, mob/living/simple_animal/hostile/distortion/advanced/another_day/owner, start_alpha = 255)
	. = ..()
	alpha = start_alpha
	if(!istype(owner))
		return
	info = replacetext(info, "%BOSS%", owner.people["boss"])
	info = replacetext(info, "%COWORKER%", owner.people["coworker"])
	info = replacetext(info, "%FRIEND%", owner.people["friend"])
	owner.RegisterClue(src, role)
	animate(src, alpha = 40, time = lifetime)
	addtimer(CALLBACK(src, PROC_REF(StartFading)), lifetime)

/obj/item/paper/distortion/clue/boss
	role = "boss"

/obj/item/paper/distortion/clue/boss/review
	name = "quarterly performance review"
	info = {"
		<table bgcolor='#2b2b33' width=100%><tr><td>
			<font size=4 face='Times New Roman' color='#c9b36a'><div align=center>
				<b>HUMAN RESOURCES</b><br>
				<font size=2>Quarterly Performance Review</font>
			</div></font>
		</td></tr></table>
		<hr size=2>
		<font size=2 face='Times New Roman'>
			<b>Employee:</b> you<br>
			<b>Reviewer:</b> %BOSS%<br>
			<b>Period:</b> Q3
			<hr size=1>
			<b>Summary</b><br>
			<font size=1>Meets expectations. Takes on additional work without complaint.
			Stayed on for the Q3 close when the rest of the team rolled off.
			Recommend expanded responsibilities at no change in grade.</font>
			<br><br>
			<b>Notes</b><br>
			<font size=1>No leave taken this year. Please address.</font>
			<hr size=1>
			<div align=right><font size=1>Signed, %BOSS%</font></div>
		</font>
	"}

/obj/item/paper/distortion/clue/boss/memo
	name = "memo"
	info = {"
		<table bgcolor='#2b2b33' width=100%><tr><td>
			<font size=4 face='Times New Roman' color='#c9b36a'><div align=center>
				<b>INTERNAL MEMORANDUM</b>
			</div></font>
		</td></tr></table>
		<hr size=2>
		<font size=2 face='Times New Roman'>
			<b>To:</b> you<br>
			<b>From:</b> %BOSS%<br>
			<b>Re:</b> Tonight
			<hr size=1>
			See me before you go home.
			<br><br><br>
			<font face='Comic Sans MS' color='#7a1f1f'><i>did not go home</i></font><br>
			<font size=1><i>(pressed hard enough to tear the page)</i></font>
		</font>
	"}

/obj/item/paper/distortion/clue/boss/overtime
	name = "overtime sheet"
	info = {"
		<table bgcolor='#2b2b33' width=100%><tr><td>
			<font size=4 face='Times New Roman' color='#c9b36a'><div align=center>
				<b>OVERTIME AUTHORISATION</b>
			</div></font>
		</td></tr></table>
		<hr size=2>
		<font size=2 face='Times New Roman'>
			<b>Employee:</b> you<br>
			<b>Week ending:</b> last week
			<hr size=1>
			<table width=100% border=1 cellpadding=2><font face='Courier New'>
				<tr><td>Mon</td><td>Tue</td><td>Wed</td><td>Thu</td><td>Fri</td><td>Sat</td><td>Sun</td></tr>
				<tr><td>4.0</td><td>3.5</td><td>5.0</td><td>4.5</td><td>6.0</td><td>8.0</td><td>3.0</td></tr>
			</font></table>
			<br>
			<b>Approved:</b> %BOSS%<br>
			<b>Reason:</b> as discussed
		</font>
	"}

/obj/item/paper/distortion/clue/coworker
	role = "coworker"

/obj/item/paper/distortion/clue/coworker/email
	name = "printed email"
	info = {"
		<table bgcolor='#e4e4e4' width=100%><tr><td><font size=2 face='Courier New'>
			<b>From:</b> %BOSS%<br>
			<b>To:</b> All staff<br>
			<b>Subject:</b> Congratulations
		</font></td></tr></table>
		<hr size=1>
		<font size=2 face='Times New Roman'>
			Please join me in congratulating %COWORKER% on the promotion to team lead.
			<br><br>
			The restructuring proposal was exactly the initiative this department needed,
			and it is good to see it recognised.
			<br><br>
			Regards,<br>
			%BOSS%
		</font>
	"}

/obj/item/paper/distortion/clue/coworker/proposal
	name = "proposal cover page"
	info = {"
		<br><br>
		<font size=5 face='Times New Roman'><div align=center><b>RESTRUCTURING PROPOSAL</b></div></font>
		<font size=2 face='Times New Roman'><div align=center>Draft 4</div></font>
		<br><br>
		<hr size=2>
		<font size=2 face='Times New Roman'><div align=center>
			Prepared by: <font color='#555555'>&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;</font>
			<font size=1><i>(scratched out, pressed through the page)</i></font><br>
			Prepared by: %COWORKER%
			<br><br>
			<font size=1>Attached: 31 pages. You can tell where the staples used to be.</font>
		</div></font>
	"}

/obj/item/paper/distortion/clue/coworker/sticky_note
	name = "sticky note"
	info = {"
		<table bgcolor='#f2e27a' width=100%><tr><td>
			<font size=2 face='Comic Sans MS' color='#1b2f6b'><i>
				Can you cover my shift again Thursday? Something came up.<br>
				I'll make it up to you, promise.
				<br><br>
				- %COWORKER%
			</i></font>
		</td></tr></table>
		<br>
		<font size=1><i>(the back has eleven tally marks)</i></font>
	"}

/obj/item/paper/distortion/clue/friend
	role = "friend"

/obj/item/paper/distortion/clue/friend/phone_log
	name = "phone log"
	info = {"
		<table bgcolor='#1d1d22' width=100%><tr><td><font size=2 face='Courier New' color='#d8d8d8'>
			<b>MISSED CALLS</b>
			<hr size=1>
			%FRIEND%&nbsp;&nbsp;Tue 19:12<br>
			%FRIEND%&nbsp;&nbsp;Tue 21:40<br>
			%FRIEND%&nbsp;&nbsp;Wed 08:03<br>
			%FRIEND%&nbsp;&nbsp;Fri 18:55<br>
			%FRIEND%&nbsp;&nbsp;Fri 18:57<br>
			%FRIEND%&nbsp;&nbsp;Sat 12:30<br>
			%FRIEND%&nbsp;&nbsp;Sun 22:14
			<hr size=1>
			Call back: <i>(nothing)</i>
		</font></td></tr></table>
	"}

/obj/item/paper/distortion/clue/friend/birthday_card
	name = "birthday card"
	info = {"
		<table bgcolor='#f6e6ee' width=100%><tr><td>
			<font size=4 face='Times New Roman' color='#8a3b5c'><div align=center><i>Happy Birthday</i></div></font>
			<hr size=1>
			<font size=2 face='Comic Sans MS' color='#1b2f6b'><i>
				To %FRIEND%,
				<br><br>
				Happy birthday. I know I missed it. I know I missed the last one. Work has been
			</i></font>
			<br><br>
			<font size=1><i>(it stops there. The envelope is addressed and has no stamp.)</i></font>
		</td></tr></table>
	"}

/obj/item/paper/distortion/clue/friend/chat_log
	name = "chat log"
	info = {"
		<font size=2 face='Courier New'><table width=100% cellpadding=2>
			<tr><td bgcolor='#dfe8f5'><b>%FRIEND%:</b> are you coming tonight</td></tr>
			<tr><td bgcolor='#dfe8f5'><b>%FRIEND%:</b> everyone's asking</td></tr>
			<tr><td bgcolor='#e9e9e9' align=right><b>you:</b> sorry. work.</td></tr>
			<tr><td bgcolor='#dfe8f5'><b>%FRIEND%:</b> it's always work</td></tr>
			<tr><td bgcolor='#dfe8f5'><b>%FRIEND%:</b> hello?</td></tr>
			<tr><td bgcolor='#dfe8f5'><b>%FRIEND%:</b> ok</td></tr>
		</table></font>
	"}
