/*
* Ramshackle Stonk Code.
*/

/datum/stonk_company
	//If no name is defined then it wont appear.
	var/name
	var/desc = "THIS IS NOT A COMPANY ALERT YOUR ADMIN"
	var/product = "RUNTIMES"
	var/current_value = 100
	var/last_value = 100
	// A base value that is turned into change using market value
	var/base_value  = 100
	// A base for the muliplier which is multiplied by preformance and optimism
	var/market_value = 0.10
	/*
	* The current performance of the company.
	* Rises and falls by the whims of imaginary employees.
	*/
	var/performance = 0
	var/min_performance = -10
	//If this is true all stocks are dumped and the company resets.
	var/bankrupt = 0
	//  The maximum amount of value a stock can have before being investigated.
	var/maxstock = 10000
	//ISSUE: This will become false if anyone checks the news.
	var/news_notif = FALSE

	//Used for visuals
	var/disp_value_change = 0
	/*
	* Optimism is a value effected by random events.
	* If optimism is in the negative then the company
	* has a chance of becoming bankrupt.
	* Optimism also effects the fluctuate() proc
	* that alters stock values.
	*/
	var/optimism = 0
	var/average_shares = 100
	var/outside_shareholders = 5
	var/available_shares = 100
	var/fluctuation_rate = 15
	var/fluctuation_counter = 0
	var/list/news = list()
	var/list/values = list()
	var/list/shareholders = list()

/datum/stonk_company/New(company_name, company_product, company_value, company_desc)
	if(company_name)
		name = company_name
	if(company_product)
		product = company_product
	if(company_value)
		current_value = company_value
		values = list(company_value)
	else
		//Gimme a value that is 35% to 200% of default value.
		current_value = current_value * (rand(35,200) / 100)
	if(company_desc)
		desc = company_desc

	/*----------\
	|UI ELEMENTS|
	\----------*/

/datum/stonk_company/proc/companyInfo(obj/machinery/interfacer, datum/stonk_investor/investor, mob/living/carbon/human/viewer, mode = 1, debug_mode = FALSE)
	. = "ID:[name]<br>\
		Desc:[desc]<br>\
		Product:[product]| Value:[current_value]| "
	if(investor)
		. += "Shares:[investor.ReturnStonkValue(src)]|"
	if(debug_mode)
		. += "<br>optimism:[optimism]|<br>\
			performance:[performance]"
	else
		. += "<br>\
			Optimism:[NameOptimism(optimism)]|"
	. += "<br>"
	GENERAL_BUTTON(REF(interfacer),"buyshares",REF(src),"Buy")
	. += " "
	GENERAL_BUTTON(REF(interfacer),"sellshares",REF(src),"Sell")
	. += "<br>"
	for(var/i = 1 to 2)
		GENERAL_BUTTON(REF(interfacer),"companymenubutton",i,"[NameButtons(i)]")
	. += "<br>"
	switch(mode)
		if(1)
			. += plotBarGraph(values, "[name] share value per share")
		if(2)
			. += "Financial News <br>"
			for(var/i in news)
				. += i
	news_notif = FALSE

/datum/stonk_company/proc/NameButtons(butt)
	switch(butt)
		if(1)
			return "BAR GRAPH"
		if(2)
			return "NEWS"

/datum/stonk_company/proc/NameOptimism(val)
	var/refined_value = round(val)
	switch(refined_value)
		if(-INFINITY to -6)
			return "AWFUL"
		if(-5 to -1)
			return "BAD"
		if(0)
			return "NORMAL"
		if(1 to 4)
			return "GOOD"
		if(5 to INFINITY)
			return "GREAT"

	/*-------------------\
	|Process Four Minutes|
	\-------------------*/

/datum/stonk_company/proc/CalculateMinutes(datum/stonk_investor/I)
	fluctuation_counter += rand(5,fluctuation_rate)
	if (fluctuation_counter >= fluctuation_rate)
		GenerateNews(I, rand(1,6))
		fluctuation_counter = 0
		if (!bankrupt)
			fluctuate()

	/*------------\
	|Generate News|
	\------------*/

/datum/stonk_company/proc/GenerateNews(datum/stonk_investor/I, effect)
	if(bankrupt && prob(15))
		bankrupt = FALSE
		GenerateNewsText(I, 3, "[name] has been bailed out of bankruptsy.")
		return
	if((!bankrupt && optimism < 0 && prob(abs(optimism) * 3)) || current_value < 10)
		Bankrupt()
		GenerateNewsText(I, 3, "[name] has filed for bankruptsy.")
		return


	var/bad_news = list("The owner of [name] has been suspected of commiting a Taboo",
		"Rats have stolen the staff of [name]",
		"An excutive at [name] is being charged with corruption",
		"The owner of [name] has distorted",
		"[name] had a poor earnings report, citing espionage",
		"[name] had a senior manager shot and killed. They did not have life insurance",
		"[product] sales are down, heavily.",
		"A defect was discovered with [product]. They are being recalled",
		"Employees at [name] had an incident that requires sensitivity training",
		"A gang that identifies themselves as [pick("The Green Grinners", "The Gang Gang", "The Toe")] have stolen a large amount of [product]",
		)

	var/neutral_news = list("[name] has released a new advertising campaign",
		"[name] has launched a service discount",
		"[name] has made a murder attempt on a customer",
		"[name] is releasing a new product",
		"[name] has announced a new member of the board",
		"A popular burger chain has created a new burger named after [name]",
		"[name] has sacrificed a middle manager for an unknown reason",
		"[name] had a senior manager shot and killed. Luckily they have life insurance",
		"Prices for [product] are down across the board",
		"[name] had hired a few fixers to assist the company",
		"New reports say that [name] had hired a Shi fixer for an unknown purpose",
		"A senior executive at [name] was involved in insider trading",
		)

	var/good_news = list("The owner of [name] did a backflip infront of a cheering crowd",
		"Rat populations around [name] have decreased significantly",
		"A major competitor to [name] had their CEO die under mysterious circumstances",
		"The public is absolutely raving for [product]! They just can't get enough",
		"Due to public demand, a shareholder of [name] shot themself in the head to show dedication",
		"The daughter of the owner of [name] possibly seen on a yacht in the Great Lake",
		"To show the safety of [product], the owner of [name] ate one on a live broadcast",
		)


	switch(effect)
		if(1)
			GenerateNewsText(I, rand(-3, -1),"\
				[pick(bad_news)], <br>\
				investors are losing faith in the companies survival.")
		if(2 to 3)
			GenerateNewsText(I, rand(-1, 1),"\
				[pick(neutral_news)], <br>\
				investors are yet to see the effect this has on profits.")
		if(4)
			GenerateNewsText(I, rand(1, 3),"\
				[pick(good_news)], <br>\
				company stocks are sure to increase now.")
		else
			return

/datum/stonk_company/proc/GenerateNewsText(datum/stonk_investor/investee, opinion_effect, txt = "ERROR")
	if(opinion_effect)
		affectPublicOpinion(opinion_effect)
	if(investee)
		investee.addToNews(name, txt)
	if(length(news) >= 10)
		news.Cut(1,2)
	news += "[txt]<br>"
	news_notif = TRUE

	/*---------------\
	|Functional Procs|
	\---------------*/

/datum/stonk_company/proc/Bankrupt()
	bankrupt = TRUE
	optimism = 0
	performance = 0
	current_value = 35
	average_shares = 100
	outside_shareholders = 5
	available_shares = 100
	shareholders = list()

	/*----------------\
	|Stolen Stock Code|
	\----------------*/
// Unsure how most of this code works.
/datum/stonk_company/proc/modifyAccount(datum/stonk_investor/stonker, by, force=0)
	if(stonker.budget)
		if (by < 0 && stonker.budget + by < 0 && !force)
			return 0
		stonker.budget += by
		return 1
	return 0

/datum/stonk_company/proc/buyShares(datum/stonk_investor/stonker, howmany)
	if (howmany <= 0)
		return
	howmany = round(howmany)
	var/loss = howmany * current_value
	if(available_shares < howmany)
		return 0
	if(modifyAccount(stonker, -loss))
		supplyDrop(howmany)
		if(!(stonker in shareholders))
			shareholders[stonker] = howmany
		else
			shareholders[stonker] += howmany
		return 1
	return 0

/datum/stonk_company/proc/sellShares(datum/stonk_investor/stonker, howmany)
	if (howmany < 0 || bankrupt)
		return
	howmany = round(howmany)
	var/gain = howmany * current_value
	if(shareholders[stonker] < howmany)
		return 0
	if(modifyAccount(stonker, gain))
		supplyGrowth(howmany)
		shareholders[stonker] -= howmany
		if (shareholders[stonker] <= 0)
			shareholders -= stonker
		return 1
	return 0

//Calculations for outsider trading
/datum/stonk_company/proc/outsiderTrading()
	var/buy = FALSE
	var/active = FALSE
	var/share_change
	var/value_difference = abs(current_value - last_value / 100)

	if(available_shares > 100)
		var/buy_chance = 0
		if(last_value < current_value)
			buy_chance += value_difference
		if(optimism > 4)
			buy_chance += 2
		if(prob(buy_chance))
			active = TRUE
			buy = TRUE

	if(outside_shareholders > 0)
		var/sell_chance = 0
		if(last_value > current_value)
			sell_chance += value_difference
		if(optimism < 3)
			sell_chance += 2
		if(prob(sell_chance))
			active = TRUE
			buy = FALSE

	if(active)
		if(buy)
			share_change = clamp(rand(-10,0),-available_shares,0)
		else
			share_change = clamp(rand(0,10),0,outside_shareholders)
		outside_shareholders -= share_change
		available_shares += share_change
		supplyGrowth(share_change)

	//Called by events to randomly effect trends.
/datum/stonk_company/proc/affectPublicOpinion(boost)
	optimism = clamp(optimism + boost,-20, 20)
	performance = clamp(performance + rand(-1,1),min_performance, 10)

	/*
	* Used in sellShares()
	* This is the only part of the code that alters the current_value
	* Negative value change is up, positive is down.
	*/
/datum/stonk_company/proc/supplyGrowth(amt)
	available_shares = round(max(0, available_shares + amt))

	//Used in buyShares and Fluctuate
/datum/stonk_company/proc/supplyDrop(amt)
	supplyGrowth(-amt)

	//This changes stock value over time. Returns change in value
/datum/stonk_company/proc/fluctuate()
	. = 0
	outsiderTrading()
	//Attempts to regulate the market.
	if(current_value >= 700)
		//Attempts to make stocks above  700 more reliant on optimism
		performance = clamp(performance + -2,-6, 2)
	//Calculate if we are working hard or hardly workig
	var/opti_perf = optimism + performance
	if(opti_perf == 0)
		opti_perf = pick(-2,-1,1)
	// Minimum market modifier is -100% and 100%. Market value is usually around 0.01.
	var/market_modifier = clamp(-1, 1,(market_value*opti_perf) - (rand(0,5)*0.01))
	// The stocks grow by base value altered by market modifier
	. = base_value * market_modifier
	last_value = current_value
	current_value += .
	//Failsafe for negative value stocks
	if(current_value < 5)
		current_value = 5
		performance = 4

	//TOO MANY VALUES THROW THE OLDEST OUT
	if (length(values) >= 50)
		values.Cut(1,2)
	values += current_value

	if(current_value >= maxstock)
		Bankrupt()
		GenerateNewsText(txt = "-The stock value of [name] has alerted district administration.-")
		return
	disp_value_change = current_value - last_value
	return

	//Visual UI for a bar graph based on the values of a list.
/datum/stonk_company/proc/plotBarGraph(list/points, base_text, width=400, height=400)
	var/output = "<table style='border:1px solid black; border-collapse: collapse; width: [width]px; height: [height]px'>"
	if (length(points) && height > 20 && width > 20)
		var/min = points[1]
		var/max = points[1]
		for (var/v in points)
			if (v < min)
				min = v
			if (v > max)
				max = v
		var/cells = (height - 20) / 20
		if (cells > round(cells))
			cells = round(cells) + 1
		var/diff = max - min
		var/ost = diff / cells
		if (min > 0)
			min = max(min - ost, 0)
		diff = max - min
		ost = diff / cells
		var/cval = max
		var/cwid = width / (length(points) + 1)
		for (var/y = cells, y > 0, y--)
			if (y == cells)
				output += "<tr>"
			else
				output += "<tr style='border:none; border-top:1px solid #00ff00; height: 20px'>"
			for (var/x = 0, x <= length(points), x++)
				if (x == 0)
					output += "<td style='border:none; height: 20px; width: [cwid]px; font-size:10px; color:#00ff00; background:black; text-align:right; vertical-align:bottom'>[round(cval - ost)]</td>"
				else
					var/v = points[x]
					if (v >= cval)
						output += "<td style='border:none; height: 20px; width: [cwid]px; background:#0000ff'>&nbsp;</td>"
					else
						output += "<td style='border:none; height: 20px; width: [cwid]px; background:black'>&nbsp;</td>"
			output += "</tr>"
			cval -= ost
		output += "<tr><td style='font-size:10px; height: 20px; width: 100%; background:black; color:green; text-align:center' colspan='[length(points) + 1]'>[base_text]</td></tr>"
	else
		output += "<tr><td style='width:[width]px; height:[height]px; background: black'></td></tr>"
		output += "<tr><td style='font-size:10px; background:black; color:green; text-align:center'>[base_text]</td></tr>"

	return "[output]</table>"
