//All the records for this gamemodes goes into one filing cabinet
/obj/structure/filingcabinet/branch12
	name = "abnormality information cabinet"
	icon_state = "chestdrawer"
	var/virgin = TRUE

/obj/structure/filingcabinet/branch12/proc/fillCurrent()
	var/list/queue = subtypesof(/obj/item/paper/fluff/info/branch12)
	for(var/sheet in queue)
		new sheet(src)

/obj/structure/filingcabinet/branch12/interact(mob/user)
	if(virgin)
		fillCurrent()
		virgin = FALSE
	return ..()

//	-------------TOOLS-------------
//Eye For an Eye
/obj/item/paper/fluff/info/branch12/eye
	name = "Eye for an Eye - O-09-12-193"
	info = {"<h1><center>O-09-12-193</center></h1>	<br>
	Name : Eye for an Eye<br>
	Risk Class : Teth	<br>
	- When used, O-09-12-193 swapped the current hp and sp of the employee working on it.	<br>
	- If an employee triggers the previous effect twice in a day they will immediately panic.	<br>
	- Any additional uses after the second use by the employee who received the bonus will kill them."}

//10 Seconds to Midnight
/obj/item/paper/fluff/info/branch12/midnight
	name = "10 Seconds till Midnight - O-09-12-202"
	info = {"<h1><center>O-09-12-202</center></h1>	<br>
	Name : 10 Seconds till Midnight<br>
	Risk Class : Teth	<br>
	- When an employee used T-09-12-202, the ordeal wouldn’t occur. A qliphoth meltdown of the corresponding meltdown level would take its place. <br>
	- 10 seconds till midnight can only stop ordeals 2 times per shift.	<br>
	- When used, 10 seconds till midnight would lower the qliphoth counter of 5 Abnormalities by 1.	<br>
	- When you stop an ordeal all continuing ordeals will either increase in strength and reward, or decrease in reward."}

//Mislocation
/obj/item/paper/fluff/info/branch12/mislocation
	name = "Mislocation - O-09-12-290"
	info = {"<h1><center>O-09-12-290</center></h1>	<br>
	Name : Mislocation<br>
	Risk Class : Teth<br>
	- Employees sitting at the bench of O-09-12-290 simply refused to die, and would not die unless they left the area under the lamp post."}

//Predestined Compass
/obj/item/paper/fluff/info/branch12/compass
	name = "Predestined Compass - O-09-12-159"
	info = {"<h1><center>O-09-12-159</center></h1>	<br>
	Name : Predestined Compass<br>
	Risk Class : He	<br>
	- Employees who carried O-09-12-159 found themselves to be luckier when working on abnormalities under a meltdown, boosting their PE production. <br>
	- Employees who carried the Predestined Compass, and worked on an abnormality not suffering a qliphoth meltdown would have incredibly terrible luck."}

//	-------------ZAYIN-------------
// Full Wave M'aider
/obj/item/paper/fluff/info/branch12/wave
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/wave
	abno_code = "O-06-12-102"
	abno_info = list(
		"It was noticed upon a good work result on attachment that a soothing song could be heard in other containment units, relaxing the other abnormalities for the rest of the shift.",
		"The relaxed abnormalities seemed more prone to testing, producing more E on average.",
		"Despite being beneficial to E production, an employee should not try to do attachment work twice in a day. Doing so will result in <Redacted> being heard across the facility, slowly doing white damage to all employees.",
		"The <Redacted> can be stopped once a employee gets a good work result on O-06-12-102",
	)

// Statue of Forgiveness
/obj/item/paper/fluff/info/branch12/statue
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/statue_of_forgiveness
	abno_code = "O-03-12-899"
	abno_info = list(
		"When an employee completed a Good work result, the employee was granted a blessing.",
		"When an employee panics while performing a work order, the employee will seek for other employees to attack.",
		"A second blessing cannot be given while an employee is already under the effect of it.",
		"The <Redacted> can be stopped once a employee gets a good work result on O-06-12-102",
	)


// Saga of Man
/obj/item/paper/fluff/info/branch12/saga
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/saga
	abno_code = "M-05-12-443"
	abno_info = list(
		"Saga of Man is inert until worked upon.",
		"When worked, Saga of Man would tell tidings of things to come, signalled by tolling bells.",
		"If the current Age is an Ice Age, all employees took small amounts of burn damage constantly.",
		"If the current Age is a Famine, all employees required more food to stay healthy.",
		"If the current Age is a Plague, all employees would receive periodic toxin damage.",
		"If the current Age is a Golden Age, occasionally ahn would appear in the halls of the facility.",
		"If the current Age is an Industrial Age, occasionally all agents would gain stats periodically.",
		"On All Saint's Day, all employees would spontaneously rise from the dead, or be dusted. The rate of dusting seemed to be a little more than average.",
	)

// You Can Become Better
/obj/item/paper/fluff/info/branch12/become_better
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/become_better
	abno_code = "T-05-12-96"
	abno_info = list(
		"On a good work, T-05-12-96 would sap the corresponding stat of the employee.",
		"T-05-12-96 would return the sapped stat in an 'innate' form.",
	)

// Your Friends Need You
/obj/item/paper/fluff/info/branch12/need_you
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/need_you
	abno_code = "T-05-12-113"
	abno_info = list(
		"When an employee entered T-05-12-113, their body was completely destroyed.",
		"After an employee was destroyed by T-05-12-113, all the agents in the facility got a bit stronger.",
	)

// I can Make Anything
/obj/item/paper/fluff/info/branch12/make_anything
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/make_anything
	abno_code = "O-04-12-533"
	abno_info = list(
		"O-04-12-533 seemed to occasionally gift the player with gadgets wearing the XX-Corp label after a good work result.",
	)

// Relic of Virtue
/obj/item/paper/fluff/info/branch12/relic
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/relic_of_virtue
	abno_code = "O-03-12-442"
	abno_info = list(
		"Over time, the risk class of 06-12-442 would change to match what the facility had.",
		"The success rate of 06-12-442, work damage and PE boxes of 06-12-442 would increase to match.",
		"Performing a bad work on 06-12-442 would reset the employee's stats to 0.",
		"Due to a previous incident (Incident O-03-12-442-B), the Safety Department would like remind all employees that consuming the relic is ill advised. \
			Employees that desecrate the shrine in this way should be aware that the consequences of doing so is unknown.",
	)

//The Rain Can Always Get Worse
/obj/item/paper/fluff/info/branch12/rain_can
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/rain_can
	abno_code = "T-04-217"
	abno_info = list(
		"Each completed work lit T-04-217's lens a colour matching the work type: red for Instinct, white for Insight, black for Attachment, pale for Repression.",
		"A good work result restored a small amount of the employee's SP.",
		"Repeating the work type the lens already showed permanently lowered the Success Rate of ALL further work. Varying the work type avoided this.",
		"This penalty could only be cleared by releasing the machine.",
		"Once the lens was lit, a 'Release' work became available, letting T-04-217 out of its unit. It could not be released while its lens was dark, nor for a short time after returning.",
		"Once released, T-04-217 never attacked. It followed the last employee to disturb it, trailing a wide, coloured rain.",
		"Employees within the rain were shielded against the damage type matching the lens colour.",
		"After roaming for a time, T-04-217 returned to its unit on its own. Forcing it back early left it inert for several minutes.",
	)

//Rabbits
/obj/item/paper/fluff/info/branch12/rabbits
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/rabbit_fever
	abno_code = "F-01-88"
	abno_info = list(
		"Each completed Attachment work split F-01-88, adding another rabbit to the huddle around it. Its maximum PE rose by 2 for every rabbit.",
		"Every rabbit in the huddle lowered the Success Rate of ALL work by 5%.",
		"Repression work while F-01-88 had a huddle scattered the whole brood across the facility, and the main body vanished down a burrow.",
		"While burrowed, F-01-88 could not be worked, and did not resurface until every loosed rabbit was put down.",
		"The loosed rabbits did not fight. They only fled from anyone who drew near, and had to be cornered or shot down.",
	)



//	-------------TETH-------------
// Remnant of the Forest
/obj/item/paper/fluff/info/branch12/rock
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/rock
	abno_code = "O-04-12-120"
	abno_info = list(
		"<Experiment> The employee Johnson began work on O-04-12-120, and O-04-12-120 produced 1 E then promptly disappeared.",
		"Upon further examination O-04-12-120 was found in one of the corridors in the department its containment room was in.",
		"O-04-12-120 showed no signs of anomalous effects when escaped. Employee Johnson then carried O-04-12-120 back to its unit.",
		"O-04-120 has only caused 17 employee deaths to date, three of which were due to blunt force trauma as a result of being launched by breaching abnormalities. The others were a result of an unapproved bet between employees to feed O-04-12-120 to O-01-15.",
		"Please for the love of <REDACTED> do not do that again, that poor rock has had enough abuse as it is.",
		"<Experiment 3> Following the events of <Redacted>, It has been observed that abnormalities originating from the black forest demonstrate high levels of aversion to O-04-12-120. Please keep this in mind as a last-resort failsafe should an emergency involving O-02-63 occurs in the main branch."
	)

// Vow Of A Dove
/obj/item/paper/fluff/info/branch12/dove
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/dove
	abno_code = "O-02-12-251"
	abno_info = list(
		"When the work result was bad, the Qliphoth counter lowered.",
		"When worked on by an employee with 1 or lower Temperance, the Qliphoth counter lowers.",
	)

// Book of Moon
/obj/item/paper/fluff/info/branch12/moon_book
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/moon_book
	abno_code = "M-04-12-20"
	abno_info = list(
		"When the work type was Repression and the work result was good, M-04-12-20 increased the understanding of multiple abnormalities in the facility.",
		"However, this would lower the understanding of M-04-12-20.",
		"After activating this ability, M-04-12-20 would have a chance to lower the qliphoth of any abnormality.",
		"This chance is based off what the current understanding is.",
	)

// The Moon Rabbit
/obj/item/paper/fluff/info/branch12/moon_rabbit
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/moon_rabbit
	abno_code = "M-02-12-29"	//29 is the number of the moon and 6th sense
	abno_info = list(
		"After each work, M-02-12-29 would inject the employee with a drug.",
		"The effects of this drug varied from mildly toxic to beneficial.",
		"To heal from the toxin effects, visit one of the sleepers in the Safety Department and inject Pentetic Acid.",
		"Branch 12 currently has no information on how this abnormality breaches, but it does seem to breach somewhat rarely.",
		"Addendum: Branch 12 has a few theories on how M-02-12-29 breaches.",
		"One senior researcher believes that M-02-12-29 breaches possibly off the phases of the Moon. It is unknown how it assess this.",
		"A second researcher believes that M-02-12-29 breaches based off the alignment of the planets.",
		"A third researcher believes that M-02-12-29 can only breach when Mercury is in retrograde.",
	)

// Coin Chance
/obj/item/paper/fluff/info/branch12/coin_chance
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/coin_chance
	abno_code = "O-04-12-777"
	abno_info = list(
		"After each successful work, the employee working on O-04-12-777 would instinctively flip a corresponding chip from the table.",
		"The result of the coin flip would give the employee a corresponding effect based off the result of the coinflip.",
		"If a red chip was flipped, it would affect the employee's HP.",
		"If a white chip was flipped, it would affect the employee's SP.",
		"If a purple chip was flipped, it would affect both the employee's HP and SP.",
		"If a blue chip was flipped, it would affect the employee's stats.",
	)

// Ulies Workshop
/obj/item/paper/fluff/info/branch12/workshop
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/workshop
	abno_code = "O-01-12-523"
	abno_info = list(
		"After each neutral or failure work, the employee working on O-01-12-523 would spend 200 Facility PE, and in exchange would gift the employee a weapon.",
		"These weapons were of generally poor quality. It is recomended for Clerks to use said weapons.",
	)

//Sunset at the Pyramids
/obj/item/paper/fluff/info/branch12/sunset
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/sunset
	abno_code = "M-04-12-476"
	abno_info = list(
		"When work was completed on M-04-12-476, the lotuses covering it changed colour. The damage it did to the next employee corresponded to the colour of these lotuses.",
		"Carrying out a work type appropriate to the lotus' colour resulted in massively increased success rate, while failing to do so resulted in punishment.",
	)

//Whiff of Nostalgia
/obj/item/paper/fluff/info/branch12/nostalgia
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/nostalgia
	abno_code = "O-04-12-64"
	abno_info = list(
		"When Insight work was completed on O-04-12-64, it would take a chunk of employee's SP and dispense a capsule.",
		"This capsule could be used to heal the SP of the person that used it.",
	)

// Stagehand
/obj/item/paper/fluff/info/branch12/ninja
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/ninja
	abno_code = "O-01-12-72"
	abno_info = list(
		"When an employee died, the Qliphoth Counter Decreased.",
	)

// Scuffed Lioness
/obj/item/paper/fluff/info/branch12/scuffed_lioness
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/scuffed_lioness
	abno_code = "F-02-12-214"
	abno_info = list(
		"When the work result was Bad, the Qliphoth Counter lowered.",
		"Its raking blows knocked employees backward. Being pinned against a wall or in a corner was dangerous during suppression.",
		"When a target kept its distance, F-02-214 sprang the full gap in a single lunge and clawed everyone where it landed.",
		"The more it was wounded, the faster and more vicious it grew - frantic below half of its health, and berserk near death.",
	)
	abno_breach_damage_type = "Red"
	abno_breach_damage_count = "High"

// Clambug
/obj/item/paper/fluff/info/branch12/clambug
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/clambug
	abno_code = "T-03-12-05"
	abno_info = list(
		"When the work result was Bad, the Qliphoth Counter lowered.",
		"Insight and Repression work unsettled T-03-213. On completing such work the Qliphoth Counter always lowered, even when the work itself succeeded.",
		"Employees of low Fortitude were nipped by its mandibles over the course of their work.",
		"Upon escaping, T-03-213 burrowed into the floor. While underground it could not be seen, struck, or tracked, and it passed beneath walls and furnishings alike.",
		"For a short while after burrowing it wandered without regard for the staff, before beginning to hunt.",
		"It surfaced directly beneath a chosen employee and, after a brief tremor of warning, erupted from the ground to strike all those nearby. It repeated this three times before it was left on the surface.",
		"When grievously wounded, T-03-213 immediately dug itself back beneath the ground.",
	)
	abno_breach_damage_type = "Red"
	abno_breach_damage_count = "High"

//Faces in the Light
/obj/item/paper/fluff/info/branch12/faces_in_light
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/faces_in_light
	abno_code = "T-03-12-54"
	abno_info = list(
		"Working on T-03-58 in a darkened cell raised the work success rate. Working under bright light lowered it.",
		"While the cell was kept dark, however, its work dealt roughly 50% more damage to the employee.",
		"When the work result was Neutral, the Qliphoth Counter lowered with a 50% chance.",
		"When the work result was Bad, the Qliphoth Counter always lowered.",
		"When the Qliphoth Counter reached zero, T-03-58 did not leave its unit. Instead, faces spilled out of its light and scattered across the facility.",
		"While any light fell on a face, it could not be harmed and could barely be seen. Bringing a face into darkness - an unlit room, or cut lights - made it visible and vulnerable, and it could then be put down with ordinary force.",
		"The faces attacked in melee for White damage. Their blows landed for only half while they stood in the light.",
		"A face that struck an employee whose sanity was already lost stripped away their equipment, destroyed them, and gave rise to another face.",
	)
	abno_breach_damage_type = "White"
	abno_breach_damage_count = "Low"

//	-------------HE-------------
// The Show Goes On
/obj/item/paper/fluff/info/branch12/show_goes_on
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/show_goes_on
	abno_code = "T-04-12-93"
	abno_info = list(
		"When the work result was not perfect the employee continued working until it was perfect or nearly so.",
		"When the employee was performing the stage prevented damage, death, and interference from external sources.",
		"When the work result was good the employee was healed slightly.",
		"Every time the employee didn’t perform correctly the negative energy damage increased.",
		"When an employee dies in T-04-12-93 and they haven’t performed perfectly, the dead body will continue producing E until it they completed their work.",
	)

// Dearest Friends
/obj/item/paper/fluff/info/branch12/friends
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/friends
	abno_code = "T-02-12-319"
	abno_info = list(
		"When an employee with prudence below level 3 worked on T-02-319, the abnormality reduced white damage dealt when working with that employee.",
		"Employees with prudence level 3 or higher who worked on T-02-319, caused the abnormality to change to red damage and increasing maximum E output to 24.",
		"When T-02-12-319 was worked on with employees with level 3 prudence or higher, the abnormality’s Qliphoth counter would decrease by 1.",
		"Any employee who worked on T-02-12-319 with justice work would reset the abnormality’s counter to the maximum.",
	)

// Ollieoxenfree
/obj/item/paper/fluff/info/branch12/ollieoxenfree
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/ollieoxenfree
	abno_code = "T-06-12-143"
	abno_info = list(
		"When the work result was good and the work type was NOT Attachment the counter lowered by 1 at a low rate.",
		"When the work result was neutral and the work type was Attachment the counter lowered by 1.",
		"When the work result was bad the counter lowered by 1.",
		"T-06-12-143 prefers attachment work over all other types of work. Any other Neutral work besides attachment will lower the counter by 1.",
		"When an employee performed attachment work, T-06-12-143 created an idea.",
		"The ideas obtained by T-06-143 are manifested into this abnormality’s strength whenever it breaches.",
	)


// Deus Ex Machina
/obj/item/paper/fluff/info/branch12/deus_ex_machina
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/deus_ex_machina
	abno_code = "O-06-12-999"	//Angel number for Release
	abno_info = list(
		"When an abnormality in the facility was suppressed, the counter lowered by 1.",
		"When the Qliphoth counter reached 0, the most recently suppressed abnormality was seemingly raised from the dead in the containment cell of O-06-12-999."
	)


// Helios Effigy
/obj/item/paper/fluff/info/branch12/helios
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/helios
	abno_code = "M-03-12-62"
	abno_info = list(
		"When an employee died in the facility, the Qliphoth counter lowered.",
	)


// Long Bird
/obj/item/paper/fluff/info/branch12/long_bird
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/long_bird
	abno_code = "O-02-12-63"
	abno_info = list(
		"When the work result was bad the qliphoth counter lowered by 1.",
		"When an employee worked on O-02-12-63 with less than 3 Fortitude, the qliphoth counter lowered by 1.",
	)

// Fire on the Velvet Horizon
/obj/item/paper/fluff/info/branch12/horizon
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/velvet_horizon
	abno_code = "T-01-12-611"
	abno_info = list(
		"During work, T-01-12-611 dealt constant damage.",
		"If the work result was good, the Qliphoth Counter increased.",
		"When the work result was neutral the qliphoth counter lowered by 1 at a normal rate.",
		"When the work result was bad the qliphoth counter lowered by 1.",
	)

//Golden Weave
/obj/item/paper/fluff/info/branch12/golden_weave
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/weave
	abno_code = "F-01-12-444"
	abno_info = list(
		"When the work result was good the qliphoth counter lowered by 1 at a low rate.",
		"When the work result was bad the qliphoth counter lowered by 1.",
	)


// Extermination Order
/obj/item/paper/fluff/info/branch12/extermination
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/extermination
	abno_code = "O-05-12-775"
	abno_info = list(
		"After each work, the qliphoth counter decreased.",
		"Reading the page reduced the qliphoth counter to 0.",
		"When a qliphoth counter was 0, a random abnormality in the facility would breach, designated O-04-12-775-1.",
		"Upon breaching, this abnormality was considerably more agressive, attacking both employees and other abnormalities.",
		"Completing a work on O-04-12-775 would also deal considerable damage to all breached abnormalities.",
		"Headquarters is confident that you could find some use for this.",
	)

// Inkstained Squid
/obj/item/paper/fluff/info/branch12/inkstained_squid
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/inkstained_squid
	abno_code = "F-04-12-63"
	abno_info = list(
		"Draw, Calculate, and Letter each add their colour to the sheet; Erase wipes the sheet even again. The bar over F-04-63 shows how the three colours stand.",
		"Keeping the three colours even makes all work easier; leaning on any one colour makes all work harder.",
		"A neutral result had a 50% chance to lower the Qliphoth Counter, and a bad result lowered it every time.",
		"When breached it makes no attacks of its own, but it soaks up the colour of any damage it takes and grows resistant to that colour, turning fully immune once it has taken enough - so putting it down needs several damage types.",
		"It strikes back with the colours it has soaked up, in the same mix, and everything it holds resets once it is contained.")

/obj/item/paper/fluff/info/branch12/encyclopedia_of_anthrophagy
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/encyclopedia_of_anthrophagy
	abno_code = "O-04-12-186"
	abno_info = list(
		"Working on O-04-186 grants the reader a fading shield. Insight work gives the most, the other three less, and a better work result gives more.",
		"The more shield an employee carries, the higher their work success rate becomes.",
		"At the end of each work session O-04-186 tries to devour the reader, with a chance equal to half the shield they are carrying - the better armoured they are, the greater the danger.",
		"Every employee it devours lowers the Qliphoth Counter by one; at zero it breaches to hunt for more.",
		"Once breached it chases the employee with the highest Prudence, deals more damage the more Prudence its target has - the single most learned person takes double - sprints when its prey is far off, and devours the downed to heal itself and grow stronger.")

//	-------------WAW-------------
// Queen Keres
/obj/item/paper/fluff/info/branch12/queen_keres
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/queen_keres
	abno_code = "T-01-12-233"
	abno_info = list(
		"When the work result was normal, the Qliphoth counter decreased with a high probability.",
		"When the counter decreased, an agent was knighted by T-01-12-233.",
		"A knighted employee receives an increase in all resistances for the rest of the shift, or until the death of T-01-12-233.",
		"When an employee with level III temperance or below completed their work, the counter lowered.",
	)

// Joe Shmoe
/obj/item/paper/fluff/info/branch12/joe_shmoe
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/joe_shmoe
	abno_code = "T-01-12-111"
	abno_info = list(
		"When the work result was bad, the Qliphoth counter decreased.",
		"When the work result was good, the Qliphoth counter decreased.",
		"When the work result was neutral, the Qliphoth counter increased.",
		"When O-01-12-111’s Qliphoth counter reached 0, A copy of O-01-12-111 appeared in multiple hallways of the facility",
	)

// Passion of Love in Death
/obj/item/paper/fluff/info/branch12/passion
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/passion
	abno_code = "T-01-12-244"
	abno_info = list(
		"When the work result was bad, the Qliphoth counter decreased with a high probability.",
		"When repression work was performed with T-01-244, the Qliphoth counter lowered at a high probability.",
		"When an employee with level 3 justice or higher completed their work, the Qliphoth counter lowered. The same phenomenon occurred at a low rate when temperance was above level 4.",
		"When the work result was good and the employee had level 4 temperance or higher, the Qliphoth Counter increased."
	)

// Hand of Babel
/obj/item/paper/fluff/info/branch12/babel
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/babel
	abno_code = "T-03-12-130"
	abno_info = list(
		"When the work result was good, T-03-12-130 gave the employee a rumor to spread.",
		"While under the effect of this rumor, the employee would heal quickly.",
		"When the rumor became widespread, one employee under the effect of this rumor disappeared, melting into a form known as T-03-12-130.",
	)

// Enchantress of Wands
/obj/item/paper/fluff/info/branch12/enchantress_of_wands
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/enchantress_of_wands
	abno_code = "M-01-12-303"
	abno_info = list(
		"When the work result was bad, the Qliphoth counter decreased.",
		"When the work result was neutral, the Qliphoth counter decreased at a normal rate.",
		"On a good result, M-01-12-303 would gift the employee a magic wand.",
		"M-01-12-303's work rates decreased for every Qliphoth counter above 1.",
	)

// Genie of Pentacles
/obj/item/paper/fluff/info/branch12/pentacle_genie
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/pentacle_genie
	abno_code = "M-01-12-554"
	abno_info = list(
		"When the work result was bad, the Qliphoth counter decreased.",
		"When the work result was neutral, the Qliphoth counter decreased at a low rate.",
		"When breaching, M-01-12-554 lowered the stat bonuses of every employee in the facility and scattered red coins.",
		"M-01-12-554 would return stats for each coin returned to her.",
		"M-01-12-554 seemed to be impervious to all attacks.",
	)

// Ascension Ceremony
/obj/item/paper/fluff/info/branch12/ascension
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/ascension_ceremony
	abno_code = "T-01-12-201"
	abno_info = list(
		"When the work result was bad, the Qliphoth counter decreased.",
		"When the work result was good, the employee recieved an oxygen tank, refilling their oxygen completely.",
	)

// Dead Man's Plan
/obj/item/paper/fluff/info/branch12/deadman
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/deadman
	abno_code = "O-01-12-612"
	abno_info = list(
		"When an abnormality in the facility was suppressed, the qliphoth counter decreased.",
		"WARNING: Do not let any employee marked by O-01-12-612 to leave the facility floor.",
	)

// Dead Bird
/obj/item/paper/fluff/info/branch12/dead_bird
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/dead_bird
	abno_code = "O-02-12-40"
	abno_info = list(
		"When the work result was bad, the Qliphoth counter decreased.",
		"When the work result was normal, the Qliphoth counter decreased at a low rate.",
		"O-02-12-40 would have to be constantly attacked during it breach, until death."
	)

// Beyond The Veil
/obj/item/paper/fluff/info/branch12/veil
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/veil
	abno_code = "M-01-12-991"
	abno_info = list(
		"When the work result was bad, the Qliphoth counter decreased.",
		"When an employee worked on M-01-12-991 with less than 4 Fortitude, the qliphoth counter lowered by 1.",
	)

//	-------------ALEPH-------------
// Old Man and The Pale
/obj/item/paper/fluff/info/branch12/oldman_pale
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/oldman_pale
	abno_code = "T-01-12-127"
	abno_info = list(
		"When the work result was bad, the Qliphoth counter lowered.",
		"When the work result was normal, the Qliphoth counter decreased with an average probability.",
		"When Repression work was performed and the work result was good, the Qliphoth counter.",
		"When an employee went insane while working on T-01-12-127 then employee gained INNOCENCE after 60 seconds.",
		"INNOCENCE could not be cleared, and slowly drained sanity.",
		"Working Inspire on T-01-12-127 with a good result would cause all of The Pale in the facility to be cleared.",
		"Working Inspire on T-01-12-127 with a bad or normal result would cause INNOCENCE to be applied to the employee working on T-01-12-127.",
	)

// Heart of Madness
/obj/item/paper/fluff/info/branch12/madness
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/madness
	abno_code = "T-03-12-598"
	abno_info = list(
		"When the work result was good, the Qliphoth counter of all he risk level and above abnormalities increased.",
		"When Instinct work was completed the employee has a normal chance of getting their hp and sp restored to max.",
		"Upon completion of attachment work the abnormality healed the hp of all employees with low HP in the facility, and the counter was decreased for each healed employee.",
		"On each work completion, T-03-12-598 linked itself to a new employee.",
		"The counter will instantly decrease to 0 if the linked employee dies due to T-03-12-598.",
	)

// Consilium Fracas
/obj/item/paper/fluff/info/branch12/fracas
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/consilium_fracas
	abno_code = "T-01-12-136"
	abno_info = list(
		"When the work result was bad, the Qliphoth counter lowered.",
		"An employee with level 4 or lower fortitude worked on T-01-12-236, they crumbled into ash before the work could begin.",
	)

// Selene Effigy
/obj/item/paper/fluff/info/branch12/fly_moon
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/fly_moon
	abno_code = "M-03-12-02"
	abno_info = list(
		"When an employee died in the facility, the Qliphoth counter lowered.",
		"M-03-12-02 would gain strength for each employee in the facility that went insane.",
		"While breaching, M-03-12-02 would start off in a strengthened state, dealing increased damage.",
		"Once it's strength was all used up, the damage dealt would be decreased.",
	)

// Sage of the World
/obj/item/paper/fluff/info/branch12/world_sage
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/world_sage
	abno_code = "M-01-12-21"
	abno_info = list(
		"M-01-12-21's Qliphoth counter lowered if not worked for 10 minutes.",
		"While breaching, M-01-12-21 would cover the area with tiles to be avoided.",
	)

// Schwartzchild Radius
/obj/item/paper/fluff/info/branch12/black_hole
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/black_hole
	abno_code = "T-03-12-512"		//The last number is the day that nasa released the photo of Saggitarrius A, May 12th
	abno_info = list(
		"When the work result was bad, the Qliphoth counter decreased.",
		"When the work result was neutral, the Qliphoth counter decreased at a normal rate.",
		"WARNING: DO NOT ENTER M-03-12-512."
	)

// Altar of the Black Sun
/obj/item/paper/fluff/info/branch12/black_sun
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/black_sunaltar
	abno_code = "M-03-12-192"
	abno_info = list(
		"This abnormality will rise over the course of 20 minutes",
		"As time goes on, this abnormality boosts your stats significantly",
		"Working on this abnormality will start the next meltdown.",
		"After some time, Waxing of The Black Sun will soak the floor of the facility with blood, causing employees to be filled with rage.",
		"After The Black Sun reaches the zenith, all abnormalities will breach"
		)

// SS13
/obj/item/paper/fluff/info/branch12/ss13
	abno_type = /mob/living/simple_animal/hostile/abnormality/branch12/ss13
	abno_code = "O-04-12-13"
	abno_info = list(
		"O-04-12-13 is currently in orbit above Branch 12, performing research.",
		"When O-04-12-13 has completed substantial research, it will cause PE gain to rapidly improve.",
		"O-04-12-13 can be resupplied by bringing both fuel and supplies to the terminal.",
		"Working on O-04-12-13 sent a message to the staff aboard it, telling them how to manage their station.",
		"Completing an Instinct work will submit a message for engineers to repair the station, using more supplies.",
		"Completing an Insight work will allocate funding to the research staff; speeding up research but causing more hull damage.",
		"Completing an Attachment work will issue extra rations to the staff aboard, reducing the amount of tensions aboard.",
		"Completing a Repression work will initiate martial law, increasing security.",
	)
