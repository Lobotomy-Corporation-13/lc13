//LCL abnos are an entirely different type from regular abnos, and should be designed with player control in mind and the gamemode they're in.
//It is not necessary to copy every feature of the original abno when making an LCL abno, keeping the 'feel' of that abnormality is what matters most.
/mob/living/simple_animal/hostile/limbus_abno
	name = "Limbus specimen"
	desc = "Unidentified creature."
	maxHealth = 400
	health = 400
	faction = ("Neutral") //This should be irrelevant in most context, abnormalities should primarily rely on the friend list and not factions.
	melee_damage_lower = 1
	melee_damage_upper = 2
	attack_sound = 'sound/abnormalities/fragment/attack.ogg'
	pet_bonus = TRUE //Don't forget to not call the parent proc if you don't want the heart effect when pet.
	pet_bonus_emote = "shudders."
	can_be_renamed = TRUE
	a_intent = INTENT_HARM
	move_resist = MOVE_FORCE_STRONG
	pull_force = MOVE_FORCE_STRONG
	var/abno_additional_instructions = "" //Unique additional info to the abnormality.
	var/true_name = "Limbus specimen" //The true name of the abnormality if it can get revealed after enough study.
	var/mob/living/simple_animal/hostile/abnormality/original_abno = null//The original abno type this is based on. If defined, it'll automatically add the name, description and sprite of that abno.

	var/awakened = FALSE //If someone possessed them, we consider them permanently awakened, even after the player logs out.
	var/limbus_map = FALSE //If we're in the LCL gamemode.
	var/attack_friend = FALSE //If they can hit their friends with unarmed attacks.
	var/list/friend_list = list() //Similar to a faction list, but handpicked by the player abno itself.
	var/list/attack_action_types = list()
	var/kickstart_timer = 3.5 MINUTES //How long it will take before an abno's desire and hunger bar will start dropping due to their cooldown after the player logs in.

	//Counter stuff
	var/max_counter = 0 //If set to 0, they have no counter.
	var/counter

	//Hunger stuff
	var/hunger_active = FALSE
	var/max_hunger = 100
	var/hunger_bar = 80
	var/hunger_loss = 10 //How much hunger is substracted per hunger cooldown.
	var/hunger_cooldown_time = 1 MINUTES
	var/hunger_cooldown
	var/starving = FALSE
	var/list/diet_list = list(/obj/item/food) //The type of food they're allowed to eat.
	var/diet_value = 10 //How much nutrition they get from their diet.
	var/delete_food = TRUE //If it qdels the food after eating it.

	//Desire stuff.
	var/desire_active = FALSE
	var/max_desire = 100
	var/desire_bar = 80
	var/desire_loss = 10 //How much desire is substracted per desire cooldown.
	var/desire_cooldown_time = 2 MINUTES //Takes off 10 desire per that amount of time.
	var/desire_cooldown
	var/desire_on_eat = 0 //How much desire is gained per regular eating.
	var/desire_on_eat_threshold = 0 //Will only gain desire_on_eat amount of desire if hunger_bar is above that threshold
	var/desire_on_pet = 0 //How much desire is gained on pet. Can be negative.

	//Repression work stuff
	var/rep_desire_gain = 0 //How much desire is gained or lost per point of damage when you're hit.
	var/rep_desire_loss_at_threshold = 0 //How much desire is lost upon hitting the abno under its rep_threshold
	var/rep_threshold = 0 //If you get hit and your health goes under that threshold, lose rep_desire_loss amount of desire.
	var/rep_min_damage = 1 //How much damage is needed to bother with adjusting the desire at all for repression work.

	//Insight work stuff.
	var/insight_active = FALSE
	var/insight_cooldown_time = 0 //How often the abno will check its surroundings. Don't make this cooldown too low as it might check a lot of items at once.
	var/insight_cooldown
	var/list/liked_objects_list = list(/obj/item/toy/plush) //What objects the abnormality enjoys seeing. Plush by default.
	var/liked_objects_value = 1 //How much a liked object adds to the room score.
	var/list/hated_objects_list = list() //What objects the abnormality hates seeing.
	var/hated_objects_value = 1 //How much a hated object substracts from the room score.

	//Ego stuff.
	var/ego_desire_accumulation = 0
	var/ego_desire_gained = 3
	var/required_ego_desire = 100
	var/ego_desire_cooldown_time = 10 SECONDS
	var/ego_desire_cooldown
	var/list/ego_list = list() //Unfortunately, I couldn't find any easy way of copying the ego list of the original abno, so you have to do it manually for now.

	//Breach overlay stuff.
	var/mutable_appearance/breach_overlay
	var/breach_overlay_x = 16
	var/breach_overlay_y = 0
	var/breach_overlay_z = 65
	var/breach_overlay_scale = 1.5

	var/special_desc = "" //The description used when 'examine more' is done.
	var/unstable = FALSE //Can't be affected by pacifiers and some other tools.

/mob/living/simple_animal/hostile/limbus_abno/Initialize(mapload)
	. = ..()
	toggle_ai(AI_OFF) //Limbus abnos have no need for AI.
	breach_overlay = mutable_appearance('icons/obj/closet.dmi', "cardboard_special", layer + 1)
	breach_overlay.pixel_z = breach_overlay_z
	breach_overlay.pixel_x = breach_overlay_x
	breach_overlay.pixel_x = breach_overlay_y
	breach_overlay.transform = matrix() * breach_overlay_scale
	if(SSmaptype.maptype == "limbus_labs") //If for some reason they spawn outside the limbus map, we're not giving them a healspot since it's designed for their starting cell.
		limbus_map = TRUE
		for(var/turf/open/T in range(3, src)) // Covers most of the cell in healing spots for the abno.
			var/obj/effect/abno_heal_spot/heal_spot = new(T)
			heal_spot.abno = src

	friend_list += src //Add yourself as a friend.

	if(!isnull(original_abno)) //Any changes specific to limbus should be added after their initialize (For example if you want to add a unique death icon.)
		icon = original_abno.icon
		icon_state = original_abno.icon_state
		icon_living = original_abno.icon_living
		icon_dead = original_abno.icon_dead
		true_name = original_abno.name
		desc = original_abno.desc
		//Find a way to set the ego list automatically somehow.

	counter = max_counter
	//There's probably a way to grant actions that takes less words but whatever it works.
	var/datum/action/small_sprite/abnormality/small_action = new /datum/action/small_sprite/abnormality()
	var/datum/action/cooldown/limbus_abno_action/ego_refinement/ego_maker = new /datum/action/cooldown/limbus_abno_action/ego_refinement()
	var/datum/action/cooldown/limbus_abno_action/emergency_satisfaction/instant_satisf = new /datum/action/cooldown/limbus_abno_action/emergency_satisfaction()
	instant_satisf.Grant(src)
	ego_maker.Grant(src)
	small_action.Grant(src)
	for(var/action_type in attack_action_types)
		var/datum/action/cooldown/abno_action = new action_type()
		abno_action.Grant(src)

///A bunch of mechanics only start happening during login. This is to avoid hunger and desire being at 0 on posession because the player showed up later.
/mob/living/simple_animal/hostile/limbus_abno/Login()
	. = ..()
	if(!. || !client)
		return FALSE

	manual_emote("awakens...")
	if(awakened)
		return //We don't want to flood them with notes if they get repossessed multiple times.
	RegisterSignal(src, COMSIG_MOB_CTRLSHIFTCLICKON, PROC_REF(OnCtrlShiftClick), TRUE)
	awakened = TRUE
	addtimer(CALLBACK(src, PROC_REF(ActivateBarCooldowns)), kickstart_timer)
	UpdateBars()
	to_chat(src, span_userdanger("You are an abnormality, slave to your own obsessions and desires. You must keep your needs met at all cost. \
	You will heal while in your starting cell and when your hunger bar is full."))
	to_chat(src, span_warning("[abno_additional_instructions] \n"))
	var/list/food_text_list = list()
	var/food_text = "Here's what you can eat: "
	for(var/diet in diet_list)
		var/obj/thing = diet
		food_text_list += "[thing.name]"
	food_text += jointext(food_text_list, ", ")
	food_text += "."
	to_chat(src, span_notice(food_text))
	to_chat(src, "<span class='span_notice'>If you consider someone a friend, use ctrl + shift + click on them, which will make them less likely to be hurt by your antics.\
	You can remember your diet along your abno instructions in your notes (IC tab) if you ever forget them.")
	if(mind)
		mind.store_memory(abno_additional_instructions)
		mind.store_memory(food_text)

/mob/living/simple_animal/hostile/limbus_abno/ghost()
	..()
	mind = null //We make it repossessable again so the abno at least has the opportunity of being played if someone gets bored of it. Doesn't include logout.

///Due to how repression works in LCL, we need to account for most source of damage inflicted by players, but abnos beating each other up shouldn't count by default.
///Ideally, we want even abnos that like repression to get pissed off if they get too close to death, to not encourage accidental killing during repression work.
///This doesn't include stuff like special damage effects like non projectiles or attacks, but I'm too lazy to code it better and account for every edge case.
/mob/living/simple_animal/hostile/limbus_abno/bullet_act(obj/projectile/P)
	. = ..()
	RepressionWork(P.damage,P.damage_type , P.firer)
	return .

/mob/living/simple_animal/hostile/limbus_abno/attackby(obj/item/W, mob/user)
	. = ..()
	RepressionWork(W.force, W.damtype, user)
	return .

///This proc checks if the damage value is good enough to increase/decrease desire, and if it doesn't get past the threshold. Adjusts the desire if everything's in order.
/mob/living/simple_animal/hostile/limbus_abno/proc/RepressionWork(attack_damage, damage_type, mob/user)
	var/added_desire = 0
	var/calculated_damage = attack_damage * damage_coeff.getCoeff(damage_type)
	if(calculated_damage <= rep_min_damage) //We don't acknowledge a hit that's too weak.
		return
	if(health > rep_threshold)
		added_desire = rep_desire_gain * calculated_damage
	else
		added_desire = -rep_desire_loss_at_threshold

	AdjustDesire(added_desire)

/mob/living/simple_animal/hostile/limbus_abno/Life()
	. = ..()
	if(hunger_cooldown < world.time)
		Hungrier(hunger_loss, FALSE)
		hunger_cooldown = world.time + hunger_cooldown_time

	if((desire_cooldown < world.time) && desire_active)
		AdjustDesire(-desire_loss)
		desire_cooldown = world.time + desire_cooldown_time

	if(ego_desire_cooldown < world.time && desire_active)
		ego_desire_accumulation += ego_desire_gained
		ego_desire_cooldown = ego_desire_cooldown_time + world.time

	if((insight_cooldown < world.time) && insight_active)
		InsightRoomCheck()
		insight_cooldown = world.time + insight_cooldown_time

	var/turf/T = get_turf(src)
	if(isnull(T))
		return
	for(var/obj/effect/abno_heal_spot/heal_spot in T.contents)
		if(heal_spot.abno == src && (health < maxHealth))
			adjustHealth(-maxHealth * 0.01) //The heal is pretty low, but that's because we want abnos to stay in their cell for as long as possible for easier containment.

///Insight work stuff. Checks the immediate surrounding for specific objects, lowering or increasing a score depending on what it finds.
/mob/living/simple_animal/hostile/limbus_abno/proc/InsightRoomCheck()
	var/room_score = 0
	var/list/room_obj_list = list()
	for(var/obj/O in view(5, src)) //Slightly bigger than the size of a cell.
		room_obj_list += O
		if(is_path_in_list(O.type, liked_objects_list))
			room_score += liked_objects_value
		if(is_path_in_list(O.type, hated_objects_list))
			room_score -= hated_objects_value

	InsightRoomResults(room_score, room_obj_list)

///Calculates the final desire gained from the room result, can be overriden for more unique calculations.
/mob/living/simple_animal/hostile/limbus_abno/proc/InsightRoomResults(room_score, list/room_obj_list)
	AdjustDesire(room_score)
	if(room_score > 0)
		to_chat(src,span_notice("You are happy with your surroundings."))
	else
		to_chat(src,span_notice("You are unhappy with your surroundings."))

///Abnos can add someone to a friend list using ctrl + shift + click, which will be unharmed by most (but not all) skills of the abno.
/mob/living/simple_animal/hostile/limbus_abno/proc/OnCtrlShiftClick(mob/living/user, atom/target)
	if(!isliving(target) || (target == src))
		return

	var/list/temp_friend_list = friend_list
	for(var/mob/living/L in temp_friend_list)
		if(target == L)
			friend_list -= L
			to_chat(src,span_notice("You no longer consider [target] a friend."))
			return

	friend_list += target
	to_chat(src,span_notice("You now consider [target] a friend."))

//This proc triggers when the abno gets hungrier. Any specific changes caused by hunger should be made within the 'AdjustHunger' proc and not this one.
/mob/living/simple_animal/hostile/limbus_abno/proc/Hungrier(hungry_amount, bypass_check = TRUE)
	if(hunger_bar > (max_hunger * 0.9) && health < maxHealth)
		adjustBruteLoss(-maxHealth * 0.1) //This might be too much healing, but we'll see.
		to_chat(src,span_notice("As your hunger is satisfied, you heal some of your wounds."))
	if(!hunger_active && !bypass_check)
		return

	AdjustHunger(-hungry_amount)

/mob/living/simple_animal/hostile/limbus_abno/UnarmedAttack(atom/A, proximity)
	var/mob/living/L
	if(isliving(A))
		L = A
		if(IsFriend(L) && !attack_friend)
			to_chat(src,span_warning("You don't feel like hurting [L], they're on your side."))
			return
	. = ..()
	AbnoEat(A)

/mob/living/simple_animal/hostile/limbus_abno/death()
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	..()

/mob/living/simple_animal/hostile/limbus_abno/funpet(mob/living/carbon/human/petter)
	..()
	if(desire_on_pet != 0) //Adjusting desire with no value might trigger stuff we don't want.
		AdjustDesire(desire_on_pet)

///Starts the hunger and desire cooldowns.
/mob/living/simple_animal/hostile/limbus_abno/proc/ActivateBarCooldowns()
	if(hunger_cooldown_time > 0)
		hunger_active = TRUE
		hunger_cooldown = world.time + hunger_cooldown_time
	if(desire_cooldown_time > 0)
		desire_active = TRUE
		desire_cooldown = world.time + desire_cooldown_time
		ego_desire_cooldown = ego_desire_cooldown_time + world.time
	if(insight_cooldown_time > 0)
		insight_active = TRUE
		insight_cooldown = world.time + insight_cooldown_time
	UpdateBars()

//When an abno 'eats' something, which can be anything in their diet, not just the food type. Returns TRUE if eaten successfully.
/mob/living/simple_animal/hostile/limbus_abno/proc/AbnoEat(atom/food)
	for(var/food_type in diet_list)
		if(istype(food, food_type))
			if(hunger_bar == max_hunger)
				to_chat(src,span_warning("You're too full to eat!"))
				return FALSE

			if(diet_value > 0)
				AdjustHunger(diet_value)
			else if(diet_value == 0)
				to_chat(src,span_notice("This didn't satiate your hunger at all..."))
			else
				to_chat(src,span_notice("Somehow, eating [food] made you hungrier."))

			if(desire_on_eat > 0 && desire_on_eat_threshold < hunger_bar)
				AdjustDesire(desire_on_eat)
			playsound(src, 'sound/items/eatfood.ogg', 100, TRUE)
			manual_emote("eats the [food]")
			if(delete_food)
				qdel(food)
			return TRUE

///Procs used to add or substract values of the abno. They all update the action button as they're expected to affect what the abno can and cannot do. Returns FALSE if the value is 0.
/mob/living/simple_animal/hostile/limbus_abno/proc/AdjustDesire(desire_amount)
	if(desire_amount == 0)
		return FALSE
	desire_bar = clamp(desire_bar + desire_amount, 0, max_desire)
	desire_bar = round(desire_bar, 1)
	UpdateBars()
	update_action_buttons()
	return TRUE

/mob/living/simple_animal/hostile/limbus_abno/proc/AdjustCounter(counter_amount)
	if(counter_amount == 0)
		return FALSE
	var/original_counter = counter
	var/pos_counter = IsPositive(counter_amount)
	counter = clamp(counter + counter_amount, 0, max_counter)
	UpdateBars()
	update_action_buttons()

	if(original_counter != counter)
		to_chat(src, "<span class='userdanger'>[counter] COUNTER</span>") //We need a proper hud alert to check counter later, but for now tell them directly when it changes.
	else
		return

	if(pos_counter)
		playsound(src, 'sound/machines/synth_yes.ogg', 20, FALSE)
	else
		playsound(src, 'sound/machines/synth_no.ogg', 20, FALSE)

/mob/living/simple_animal/hostile/limbus_abno/proc/AdjustHunger(feeding_amount)
	if(feeding_amount == 0)
		return FALSE
	hunger_bar = clamp(hunger_bar + feeding_amount, 0, max_hunger)
	hunger_bar = round(hunger_bar, 1)
	if(hunger_bar > 0)
		starving = FALSE
	else if(!starving)
		to_chat(src, span_boldwarning("You're starving!")) //Only shows this message if you weren't already starving to avoid message spam.
		starving = TRUE

	UpdateBars()
	update_action_buttons()
	return TRUE

/mob/living/simple_animal/hostile/limbus_abno/proc/AddBreachEffect()
	add_overlay(breach_overlay)

/mob/living/simple_animal/hostile/limbus_abno/proc/RemoveBreachEffect()
	cut_overlay(breach_overlay)

//There's probably a proc for that already but I'm too lazy to find it. Just returns true if the value is positive or zero, false if negative.
/mob/living/simple_animal/hostile/limbus_abno/proc/IsPositive(value)
	if(value > 0)
		return TRUE
	else
		return FALSE

/mob/living/simple_animal/hostile/limbus_abno/proc/IsFriend(mob/living/friend)
	for(var/mob/living/L in friend_list)
		if(L == friend)
			return TRUE
	return FALSE

/mob/living/simple_animal/hostile/limbus_abno/examine_more(mob/user)
	if(special_desc == "" || isnull(special_desc))
		return ..()

	. = list(special_desc)

///Updates ALL bars, hunger, sanity & counter. Also adds extra info in the description.
/mob/living/simple_animal/hostile/limbus_abno/proc/UpdateBars()
	//Basically copying the alert system for regular hunger.
	var/temp_desc = ""

	switch(hunger_bar)
		if(90 to INFINITY)
			temp_desc += "It looks full, "
			throw_alert("nutrition", /atom/movable/screen/alert/fat)
		if(50 to 90)
			temp_desc += "It looks well fed, "
			clear_alert("nutrition")
		if(25 to 50)
			temp_desc += "It looks really hungry, "
			throw_alert("nutrition", /atom/movable/screen/alert/hungry)
		if(0 to 25)
			temp_desc += "It looks like it's starving, "
			throw_alert("nutrition", /atom/movable/screen/alert/starving)

	switch(desire_bar)
		if(90 to INFINITY)
			temp_desc += "it also looks satisfied."
			throw_alert("abno_mood", /atom/movable/screen/alert/abno_mood/happy)
		if(70 to 90)
			temp_desc += "it also looks content with the way things are."
			throw_alert("abno_mood", /atom/movable/screen/alert/abno_mood/content)
		if(50 to 70)
			temp_desc += "it also doesn't look particularly satisfied or unsatisfied."
			throw_alert("abno_mood", /atom/movable/screen/alert/abno_mood/neutral)
		if(25 to 50)
			temp_desc += "it also looks pissed off!"
			throw_alert("abno_mood", /atom/movable/screen/alert/abno_mood/angry)
		if(0 to 25)
			temp_desc += "it also looks like its about to lose it!"
			throw_alert("abno_mood", /atom/movable/screen/alert/abno_mood/rock_bottom)

	temp_desc += " If you had to guess its qliphoth counter... "
	if(max_counter != 0)
		switch(counter)
			if(0)
				temp_desc += "it looks like it's at zero!"
			if(1)
				temp_desc += "It's almost at zero!"
			if(2 to 3)
				temp_desc += "maybe two, three? You have some time before it might become a problem."
			if(4 to INFINITY)
				temp_desc += "It's at least 4, you really shouldn't have to worry about it right now."
	else
		temp_desc += "it doesn't look like it has one?"

	special_desc = temp_desc

///Abno limbus actions.
/datum/action/cooldown/limbus_abno_action
	var/mob/living/simple_animal/hostile/limbus_abno/abno_user //It's better to use this instead of owner when using those actions.
	//If the relevant needs are under that threshold, the action becomes available. For actions that only works above that number, override and set it manually.
	var/desire_req
	var/hunger_req
	var/counter_req
	var/starving_req = FALSE

///Checks if the user is a limbus abno, and removes it if not.
/datum/action/cooldown/limbus_abno_action/Grant(mob/M)
	..()
	if(istype(M, /mob/living/simple_animal/hostile/limbus_abno))
		abno_user = M
	else
		Remove(owner)

	if(isnull(desire_req))
		desire_req = abno_user.max_desire
	if(isnull(hunger_req))
		hunger_req = abno_user.max_hunger
	if(isnull(counter_req))
		counter_req = abno_user.max_counter

/datum/action/cooldown/limbus_abno_action/IsAvailable()
	. = ..()
	if(isnull(abno_user) || !.)
		return FALSE
	if(starving_req && abno_user.starving)
		return FALSE
	if(desire_req < abno_user.desire_bar || hunger_req < abno_user.hunger_bar || counter_req < abno_user.counter)
		return FALSE
	return TRUE

///An abnormality can create its ego if its desire has been up for a long enough time in total. Give this a proper icon sprite later.
/datum/action/cooldown/limbus_abno_action/ego_refinement
	name = "Expel Ego"
	desc = "Create one of your associated ego. Require a long amount of time spent near your maximum amount of desire."
	cooldown_time = 1 MINUTES

/datum/action/cooldown/limbus_abno_action/ego_refinement/IsAvailable()
	. = ..()
	if(!.)
		return .
	if(abno_user.ego_desire_accumulation < abno_user.required_ego_desire || abno_user.desire_bar < 90)
		return FALSE

/datum/action/cooldown/limbus_abno_action/ego_refinement/Trigger()
	. = ..()
	if(!.)
		return .
	var/datum/ego_datum/ego_picked = pick(abno_user.ego_list)
	if(!ego_picked)
		return FALSE
	playsound(abno_user, 'sound/effects/book_turn.ogg', 50, TRUE, TRUE) //We'll pick a better sound effect later.
	var/obj/item/ego_item = new ego_picked.item_path(get_turf(abno_user))
	if(istype(ego_item, /obj/item/ego_weapon))
		var/obj/item/ego_weapon/weapon = ego_item
		weapon.attribute_requirements = list()
	else if(istype(ego_item, /obj/item/clothing/suit/armor/ego_gear))
		var/obj/item/clothing/suit/armor/ego_gear/armor = ego_item
		armor.attribute_requirements = list()
	abno_user.ego_desire_accumulation -= abno_user.required_ego_desire
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/emergency_satisfaction
	name = "Emergency Satisfaction."
	desc = "Instantly put your desire, hunger and counter at their maximum possible value. Really high cooldown. Using this in a breached state will not unbreach you."
	icon_icon = 'icons/hud/screen_gen.dmi'
	button_icon_state = "mood_happiness_good"
	transparent_when_unavailable = TRUE
	cooldown_time = 20 MINUTES //Severely elongated due to abno pacifiers.

/datum/action/cooldown/limbus_abno_action/emergency_satisfaction/Trigger()
	. = ..()
	if(!.)
		return FALSE
	abno_user.AdjustDesire(abno_user.max_desire)
	abno_user.AdjustHunger(abno_user.max_hunger)
	if(abno_user.max_counter > 0)
		abno_user.AdjustCounter(abno_user.max_counter)
	StartCooldown()

///Abno heal spot
/obj/effect/abno_heal_spot
	name = "Abno heal spot"
	desc = "Where an abno can heal. You shouldn't be able to read this."
	opacity = FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/abno

///Abno desire bar. This looks just like the old mood system, but making new icons would be more fitting.
/atom/movable/screen/alert/abno_mood
	icon = 'icons/hud/screen_gen.dmi'

/atom/movable/screen/alert/abno_mood/happy
	name = "Happy"
	desc = "You feel fulfilled!"
	icon_state = "mood8"
	color = "#32b9b9"

/atom/movable/screen/alert/abno_mood/content
	name = "Content"
	desc = "Things aren't so bad right now."
	icon_state = "mood6"
	color = "#6fb932"

/atom/movable/screen/alert/abno_mood/neutral
	name = "Neutral"
	desc = "Could be better, could be worse."
	icon_state = "mood5"
	color = "#d3d023"

/atom/movable/screen/alert/abno_mood/angry
	name = "Angry"
	desc = "You're at your limit."
	icon_state = "mood3"
	color = "#eb4d42"

/atom/movable/screen/alert/abno_mood/rock_bottom
	name = "Rock bottom"
	desc = "You can't take it anymore."
	icon_state = "mood1"
	color = "#e21717ff"
