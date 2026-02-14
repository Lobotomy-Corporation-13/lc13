/obj/item/clothing/suit/armor/ego_gear/realization // 240 without ability. You have to be an EX level agent to get these.
	name = "unknown realized ego"
	desc = "Notify coders immediately!"
	icon = 'icons/obj/clothing/ego_gear/realization.dmi'
	worn_icon = 'icons/mob/clothing/ego_gear/realized.dmi'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 100
							)
	/// Type of realized ability, if any
	var/obj/effect/proc_holder/ability/realized_ability = null
	/// Set the ego_assimilation ability if the realized EGO is able to assimilate a weapon into a corresponding weapon (example: Gasharpoon armour can turn an ALEPH weapon into Gasharpoon weapon)
	var/obj/effect/proc_holder/ability/ego_assimilation/assimilation_ability = null

/obj/item/clothing/suit/armor/ego_gear/realization/Initialize()
	. = ..()
	if(realized_ability)
		var/obj/effect/proc_holder/ability/AS = new realized_ability
		var/datum/action/spell_action/ability/item/A = AS.action
		A.SetItem(src)
	if(assimilation_ability)
		var/obj/effect/proc_holder/ability/ego_assimilation/ASSIM = new assimilation_ability
		var/datum/action/spell_action/ability/item/A2 = ASSIM.action
		A2.SetItem(src)

/*Armor totals:
Ability 	230
No Ability	250
*/
/* ZAYIN Realizations */

/obj/item/clothing/suit/armor/ego_gear/realization/confessional
	name = "confessional"
	desc = "Come my child. Tell me your sins."
	icon_state = "confessional"
	armor = list(RED_DAMAGE = 50, WHITE_DAMAGE = 100, BLACK_DAMAGE = 40, PALE_DAMAGE = 40)	//Ranged
	realized_ability = /obj/effect/proc_holder/ability/aimed/cross_spawn

/obj/item/clothing/suit/armor/ego_gear/realization/prophet
	name = "prophet"
	desc = "And they have conquered him by the blood of the Lamb and by the word of their testimony, for they loved not their lives even unto death."
	icon_state = "prophet"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 80, BLACK_DAMAGE = 70, PALE_DAMAGE = 60)	//No ability.
	flags_inv = HIDEJUMPSUIT|HIDEGLOVES|HIDESHOES
	hat = /obj/item/clothing/head/ego_hat/prophet_hat

/obj/item/clothing/head/ego_hat/prophet_hat
	name = "prophet"
	desc = "For this reason, rejoice, you heavens and you who dwell in them. Woe to the earth and the sea, because the devil has come down to you with great wrath, knowing that he has only a short time."
	icon_state = "prophet"

/obj/item/clothing/suit/armor/ego_gear/realization/maiden
	name = "blood maiden"
	desc = "Soaked in blood, and yet pure in heart."
	icon_state = "maiden"
	armor = list(RED_DAMAGE = 60, WHITE_DAMAGE = 60, BLACK_DAMAGE = 80, PALE_DAMAGE = 50)	//No ability. 250

/obj/item/clothing/suit/armor/ego_gear/realization/wellcheers
	name = "wellcheers"
	desc = " I’ve found true happiness in cracking open a cold one after a hard day’s work, covered in sea water and sweat. \
	I’m at the port now but we gotta take off soon to catch some more shrimp. Never know what your future holds, bros."
	icon_state = "wellcheers"
	armor = list(RED_DAMAGE = 80, WHITE_DAMAGE = 50, BLACK_DAMAGE = 50, PALE_DAMAGE = 50)	//Support
	realized_ability = /obj/effect/proc_holder/ability/wellcheers
	hat = /obj/item/clothing/head/ego_hat/wellcheers_hat

/obj/item/clothing/head/ego_hat/wellcheers_hat
	name = "wellcheers"
	desc = "You’re really missing out on life if you’ve never tried shrimp."
	icon_state = "wellcheers"

/obj/item/clothing/suit/armor/ego_gear/realization/comatose
	name = "comatose"
	desc = "...ZZZ..."
	icon_state = "comatose"
	armor = list(RED_DAMAGE = 50, WHITE_DAMAGE = 80, BLACK_DAMAGE = 50, PALE_DAMAGE = 50)	//Defensive
	realized_ability = /obj/effect/proc_holder/ability/comatose

/obj/item/clothing/suit/armor/ego_gear/realization/brokencrown
	name = "broken crown"
	desc = "Shall we get to work? All we need to do is what we’ve always done."
	icon_state = "brokencrown"
	armor = list(RED_DAMAGE = 70, WHITE_DAMAGE = 60, BLACK_DAMAGE = 50, PALE_DAMAGE = 50)	//Broken Crown
	realized_ability = /obj/effect/proc_holder/ability/brokencrown
	hat = /obj/item/clothing/head/ego_hat/brokencrown

/obj/item/clothing/suit/armor/ego_gear/realization/brokencrown/dropped(mob/user) //Reload the item automatically if dropped
	for(var/datum/action/spell_action/ability/item/theability in actions)
		if(istype(theability.target, /obj/effect/proc_holder/ability/brokencrown))
			var/obj/effect/proc_holder/ability/brokencrown/power = theability.target
			power.Reabsorb()
	. = ..()

/obj/item/clothing/suit/armor/ego_gear/realization/brokencrown/attackby(obj/item/I, mob/living/user, params) //Reload the item
	for(var/datum/action/spell_action/ability/item/theability in actions)
		if(istype(theability.target, /obj/effect/proc_holder/ability/brokencrown))
			var/obj/effect/proc_holder/ability/brokencrown/power = theability.target
			if(power.Absorb(I,user))
				return
	return ..()

/obj/item/clothing/head/ego_hat/brokencrown
	name = "broken crown"
	desc = "One fell down and the rest came tumbling after."
	icon_state = "brokencrown"

/obj/item/clothing/suit/armor/ego_gear/realization/energyconversion
	name = "energy conversion"
	desc = "Just open up the machine, step inside, and press the button to make it shut. Now everything will be just fine."
	icon_state = "energy_conversion"
	armor = list(RED_DAMAGE = 90, WHITE_DAMAGE = 60, BLACK_DAMAGE = 50, PALE_DAMAGE = 50) //Lower red damage when it gets an ability probably

/* TETH Realizations */

/obj/item/clothing/suit/armor/ego_gear/realization/mouth
	name = "mouth of god"
	desc = "And the mouth of god spoke: You will be punished."
	icon_state = "mouth"
	armor = list(RED_DAMAGE = 70, WHITE_DAMAGE = 60, BLACK_DAMAGE = 40, PALE_DAMAGE = 60)		//Defensive
	realized_ability = /obj/effect/proc_holder/ability/punishment

/obj/item/clothing/suit/armor/ego_gear/realization/universe
	name = "one with the universe"
	desc = "One with all, it all comes back to yourself."
	icon_state = "universe"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 50, BLACK_DAMAGE = 80, PALE_DAMAGE = 60)		//Support
	realized_ability = /obj/effect/proc_holder/ability/universe_song
	hat = /obj/item/clothing/head/ego_hat/universe_hat

/obj/item/clothing/head/ego_hat/universe_hat
	name = "one with the universe"
	desc = "See. All. Together. Know. Us."
	icon_state = "universe"
	flags_inv = HIDEMASK | HIDEHAIR

/obj/item/clothing/suit/armor/ego_gear/realization/death
	name = "death stare"
	desc = "Last words are for fools who haven’t said enough."
	icon_state = "death"
	armor = list(RED_DAMAGE = 80, WHITE_DAMAGE = 40, BLACK_DAMAGE = 60, PALE_DAMAGE = 50)		//Melee with slow
	realized_ability = /obj/effect/proc_holder/ability/aimed/gleaming_eyes

/obj/item/clothing/suit/armor/ego_gear/realization/fear
	name = "passion of the fearless one"
	desc = "Man fears the darkness, and so he scrapes away at the edges of it with fire.\
	Grants various buffs to life of a daredevil when equipped."
	icon_state = "fear"
	armor = list(RED_DAMAGE = 80, WHITE_DAMAGE = 70, BLACK_DAMAGE = 70, PALE_DAMAGE = 10)		//Melee, makes weapon better
	flags_inv = null

/obj/item/clothing/suit/armor/ego_gear/realization/exsanguination
	name = "exsanguination"
	desc = "It keeps your suit relatively clean."
	icon_state = "exsanguination"
	armor = list(RED_DAMAGE = 60, WHITE_DAMAGE = 80, BLACK_DAMAGE = 60, PALE_DAMAGE = 50)			//No ability

/obj/item/clothing/suit/armor/ego_gear/realization/ember_matchlight
	name = "ember matchlight"
	desc = "If I must perish, then I'll make you meet the same fate."
	icon_state = "ember_matchlight"
	armor = list(RED_DAMAGE = 80, WHITE_DAMAGE = 40, BLACK_DAMAGE = 50, PALE_DAMAGE = 60)		//Melee
	realized_ability = /obj/effect/proc_holder/ability/fire_explosion

/obj/item/clothing/suit/armor/ego_gear/realization/sakura_bloom
	name = "sakura bloom"
	desc = "The forest will never return to its original state once it dies. Cherish the rain."
	icon_state = "sakura_bloom"
	armor = list(RED_DAMAGE = 60, WHITE_DAMAGE = 80, BLACK_DAMAGE = 40, PALE_DAMAGE = 50)		//Healing
	realized_ability = /obj/effect/proc_holder/ability/petal_blizzard
	hat = /obj/item/clothing/head/ego_hat/sakura_hat

/obj/item/clothing/head/ego_hat/sakura_hat
	name = "sakura bloom"
	desc = "Spring is coming."
	worn_icon = 'icons/mob/clothing/big_hat.dmi'
	icon_state = "sakura"

/obj/item/clothing/suit/armor/ego_gear/realization/stupor
	name = "stupor"
	desc = "Drink! Drink yourselves into a stupor! Foul tasting louts like you won't satisfy me until you're all as pickled as me, hah!" //Descriptions made by Anonmare
	icon_state = "stupor" //Art by TemperanceTempy
	armor = list(RED_DAMAGE = 80, WHITE_DAMAGE = 30, BLACK_DAMAGE = 50, PALE_DAMAGE = 70)		//Defensive
	hat = /obj/item/clothing/head/ego_hat/stupor

/obj/item/clothing/head/ego_hat/stupor
	name = "stupor"
	desc = "Many people look for oblivion at the bottom of the glass, I can't be blamed if I give it to 'em now, can I?"
	icon_state = "stupor"

/*
This Realization has several effects.
1. Grants the Fairy Lure ability, placing a debuff on enemies which allows you to lock enemy aggro on yourself and make them take extra WHITE damage when hit for a while
or until the damage cap on the debuff is hit. While Fairy Lure is active on yourself, if you die, you will unleash a RED damage reprisal AOE.
2. Allows you to Assimilate an ALEPH E.G.O. weapon into the Eldtree weapon.
3. Buffs the Eldtree weapon by allowing you to regenerate HP/SP through a "marking" mechanic, basically whack an enemy with an unwielded hit then cash it in with a wielded hit. HP from melee, SP from ranged.
*/
/obj/item/clothing/suit/armor/ego_gear/realization/eldtree
	name = "eldtree"
	desc = "Not a single good thing in this City is freely given."
	icon_state = "lce_lantern"
	armor = list(RED_DAMAGE = 80, WHITE_DAMAGE = 40, BLACK_DAMAGE = 40, PALE_DAMAGE = 70)		// 230, you're going to be under some serious heat if you take this so pack defensive options
	realized_ability = /obj/effect/proc_holder/ability/fairy_lure
	assimilation_ability = /obj/effect/proc_holder/ability/ego_assimilation/eldtree

/* HE Realizations */

/obj/item/clothing/suit/armor/ego_gear/realization/grinder
	name = "grinder MK52"
	desc = "The blades are not just decorative."
	icon_state = "grinder"
	armor = list(RED_DAMAGE = 70, WHITE_DAMAGE = 40, BLACK_DAMAGE = 60, PALE_DAMAGE = 60)		//Melee
	realized_ability = /obj/effect/proc_holder/ability/aimed/helper_dash

/obj/item/clothing/suit/armor/ego_gear/realization/bigiron
	name = "big iron"
	desc = "A hefty silk coat with a blue smock."
	icon_state = "big_iron"
	armor = list(RED_DAMAGE = 60, WHITE_DAMAGE = 50, BLACK_DAMAGE = 60, PALE_DAMAGE = 60)		//Ranged

/obj/item/clothing/suit/armor/ego_gear/realization/eulogy
	name = "solemn eulogy"
	desc = "Death is not extinguishing the light, it is putting out the lamp as dawn has come."
	icon_state = "eulogy"
	armor = list(RED_DAMAGE = 30, WHITE_DAMAGE = 80, BLACK_DAMAGE = 80, PALE_DAMAGE = 40)

/obj/item/clothing/suit/armor/ego_gear/realization/ourgalaxy
	name = "our galaxy"
	desc = "Walk this night sky with me. The galaxy dotted with numerous hopes. We'll count the stars and never be alone."
	icon_state = "ourgalaxy"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 60, BLACK_DAMAGE = 70, PALE_DAMAGE = 60)		//Healing
	realized_ability = /obj/effect/proc_holder/ability/galaxy_gift

/obj/item/clothing/suit/armor/ego_gear/realization/forever
	name = "together forever"
	desc = "I would move Heaven and Earth to be together forever with you."
	icon_state = "forever"
	armor = list(RED_DAMAGE = 60, WHITE_DAMAGE = 80, BLACK_DAMAGE = 60, PALE_DAMAGE = 50)		//No ability
	hat = /obj/item/clothing/head/ego_hat/forever_hat

/obj/item/clothing/head/ego_hat/forever_hat
	name = "together forever"
	desc = "I've gotten used to bowing and scraping to you, so I cut off my own limbs."
	icon_state = "forever"

/obj/item/clothing/suit/armor/ego_gear/realization/wisdom
	name = "endless wisdom"
	desc = "Poor stuffing of straw. I'll give you the wisdom to ponder over anything."
	icon_state = "wisdom"
	armor = list(RED_DAMAGE = 60, WHITE_DAMAGE = 80, BLACK_DAMAGE = 60, PALE_DAMAGE = 50)		//No ability
	flags_inv = HIDESHOES
	hat = /obj/item/clothing/head/ego_hat/wisdom_hat

/obj/item/clothing/head/ego_hat/wisdom_hat
	name = "endless wisdom"
	desc = "I was left with nothing, nothing but empty brains and rotting bodies."
	icon_state = "wisdom"

/obj/item/clothing/suit/armor/ego_gear/realization/empathy
	name = "boundless empathy"
	desc = "Tin-cold woodsman. I'll give you the heart to forgive and love anyone."
	icon_state = "empathy"
	armor = list(RED_DAMAGE = 80, WHITE_DAMAGE = 60, BLACK_DAMAGE = 60, PALE_DAMAGE = 50)		//No ABility
	flags_inv = HIDEGLOVES|HIDESHOES

/obj/item/clothing/suit/armor/ego_gear/realization/valor
	name = "unbroken valor"
	desc = "Cowardly kitten, I'll give you the courage to stand up to anything and everything."
	icon_state = "valor"
	armor = list(RED_DAMAGE = 70, WHITE_DAMAGE = 50, BLACK_DAMAGE = 50, PALE_DAMAGE = 80)		//No ability

/obj/item/clothing/suit/armor/ego_gear/realization/home //This name would SO much easier if we didnt aleady USE HOMING INSTINCT AHHHHHHHHHHHHHHHHHHH
	name = "forever home"
	desc = "Last of all, road that is lost. I will send you home."
	icon_state = "home"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 60, BLACK_DAMAGE = 80, PALE_DAMAGE = 50)		//Support
	flags_inv = HIDEGLOVES|HIDESHOES
	realized_ability = /obj/effect/proc_holder/ability/aimed/house_spawn

/obj/item/clothing/suit/armor/ego_gear/realization/dimension_ripper
	name = "dimension ripper"
	desc = "Lost and abandoned, tossed out like trash, having no place left in the City."
	icon_state = "dimension_ripper"
	armor = list(RED_DAMAGE = 70, WHITE_DAMAGE = 50, BLACK_DAMAGE = 60, PALE_DAMAGE = 50)		//Melee
	realized_ability = /obj/effect/proc_holder/ability/rip_space

/obj/item/clothing/suit/armor/ego_gear/realization/gift
	name = "gift"
	desc = "Play with me! Join my friends and laugh with us."
	icon_state = "gift"
	armor = list(RED_DAMAGE = 60, WHITE_DAMAGE = 60, BLACK_DAMAGE = 80, PALE_DAMAGE = 50)

/* This Realization has several effects:
1. Grants an ability: Curl Up. Gives a universal shield (think Manager Shield Bullets) to the user. While it is active, accumulates charge for this armour. If the shield breaks, lose all charge.
If it survives, unleash an AoE attack that gets stronger the less health the shield had left.
2. Grants a passive ability: Self-Charge. The armour accumulates charge from using the ability and from the AEDD weapon. Once it reaches maximum charge, empowers the user.
This empowered state makes them arc lightning to all nearby foes when taking damage, and gives a large amount of power modifier while it lasts.
3. Empowers the AEDD weapon to low ALEPH tier in strength.
*/
/obj/item/clothing/suit/armor/ego_gear/realization/experimentation
	name = "experimentation"
	desc = "Just as they wished to test and examine me, I would also wish to experiment with attaining freedom."
	icon_state = "lce_aedd_inactive"
	armor = list(RED_DAMAGE = 70, WHITE_DAMAGE = 50, BLACK_DAMAGE = 70, PALE_DAMAGE = 40)		// Tank, survivability-based. Also buffs AEDD weapon (abysmal by default)
	realized_ability = /obj/effect/proc_holder/ability/aedd_curl_up
	var/mob/living/carbon/human/owner
	/// Current amount of Self-Charge. Gained by blocking hits with Curl Up and landing hits with AEDD E.G.O. weapon special. Lost when entering Empowered state or shield is shattered.
	var/charge = 0
	/// Maximum amount of Self-Charge. Also represents the amount needed to enter Empowered state.
	var/max_charge = 30

	/// If TRUE, we won't be able to gain Self-Charge.
	var/empowered = FALSE
	/// Empowered state lasts this long.
	var/empowered_duration = 20 SECONDS
	/// Amount of Power Modifier gained while Empowered. This boosts melee attack damage and movement speed.
	var/empowered_power_buff = 40

	/// Amount of tiles that our lightning reaches out to. Mind, if we hit an enemy 4 tiles away with our lightning, that enemy will continue to chain with a radius of 4 tiles, so we could hit an enemy... potentially across the entire map.
	var/arc_lightning_range = 4
	/// Amount of damage dealt by our arc lightning. This is flat, not multiplied by anything (except enemy weaknesses).
	var/arc_lightning_damage = 50
	/// Holds current arc lightning cooldown.
	var/arc_lightning_cooldown
	/// Period of time in between possible arc lightning procs.
	var/arc_lightning_cooldown_duration = 2 SECONDS
	/// Failsafe to avoid insane amounts of recursion. Arc lightning will never chain to more than 30 turfs.
	var/arc_lightning_max_chains = 30
	// These hitlists are to avoid repeating hits.
	var/list/arc_lightning_turf_hitlist = list()
	var/list/arc_lightning_mob_hitlist = list()

	/// Timer for exiting Empowered.
	var/revert_buff_timer

/obj/item/clothing/suit/armor/ego_gear/realization/experimentation/examine(mob/user)
	. = ..()
	. += span_notice("This E.G.O. can accumulate <b>Self-Charge</b>. After reaching [max_charge] stacks of Self-Charge, <b>receive +40 Power Modifier</b> and <b>retaliate with BLACK damage chain lightning to all nearby enemies when taking damage</b>. This buff lasts 20 seconds.")
	. += span_notice("This E.G.O. will <b>empower the AEDD E.G.O. weapon while worn</b>, allowing it to be <b>permanently charged</b> and causing any further charging of the weapon to <b>enable an area attack for the next swing which accumulates 3 Self-Charge</b> for this E.G.O. per target hit.")
	. += span_danger("<b>Current Self-Charge: [charge]/[max_charge].</b>")
	if(empowered)
		. += span_danger("Currently <b>empowered!</b>")

/// Set our owner when equipped to the exosuit slot. If we're being put ANYWHERE ELSE, remove our owner after reverting any buffs we may have given them.
/obj/item/clothing/suit/armor/ego_gear/realization/experimentation/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_OCLOTHING && ishuman(user))
		owner = user
	else
		RevertBuff()
		owner = null

/// Remove buffs when being dropped.
/obj/item/clothing/suit/armor/ego_gear/realization/experimentation/dropped(mob/user)
	. = ..()
	RevertBuff()
	owner = null

/// This proc is used by the Curl Up ability and the AEDD E.G.O. weapon to add charge to this armour.
/obj/item/clothing/suit/armor/ego_gear/realization/experimentation/proc/AdjustCharge(amount)
	if(empowered)
		return
	charge = clamp(charge + amount, 0, max_charge) // Charge can never < 0 and can never > max_charge
	if(amount > 0)
		new /obj/effect/temp_visual/healing/charge(get_turf(src)) // cool vfx
	if(charge >= max_charge)
		ActivateBuff()

// The buff isn't a status effect because it doesn't need to be - BUT this is, admittedly, unsafe, and could cause permanent changes to Power Modifier in some rare edge cases (armour deleted?)
// If maints hate this I can make it a status effect
/// Gain Power Modifier and shock nearby enemies when taking damage, for a certain period of time. Also updates the armour's sprite.
/obj/item/clothing/suit/armor/ego_gear/realization/experimentation/proc/ActivateBuff()
	if(!ishuman(owner) || empowered)
		return
	charge = 0 // Goodbye Charge
	empowered = TRUE // Stop gaining charge and you can't trigger this state while it's already ongoing to double up on buffs

	owner.adjust_attribute_bonus(JUSTICE_ATTRIBUTE, empowered_power_buff) // UNLIMITED POWER (modifier)
	RegisterSignal(owner, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(StartArcLightning)) // When taking damage, cause a chain lightning effect.
	revert_buff_timer = addtimer(CALLBACK(src, PROC_REF(RevertBuff)), empowered_duration, TIMER_STOPPABLE) // Revert the buff after this period of time.

	// Player feedback: message, sound and icon state change.
	owner.visible_message(span_danger("[owner]'s [src.name] E.G.O. begins to wildly arc with electricity!"), span_nicegreen("<b>Your [src.name] E.G.O. has reached maximum charge, and begins violently discharging electricity, empowering you!</b>"))
	playsound(src, 'sound/magic/lightningshock.ogg', 80, FALSE, 5)

	// Make the suit's icon state change to the sparking version.
	icon_state = "lce_aedd_active"
	owner.regenerate_icons()

/// Walk all our changes from ActivateBuff back
/obj/item/clothing/suit/armor/ego_gear/realization/experimentation/proc/RevertBuff()
	if(!ishuman(owner) || !empowered)
		return
	deltimer(revert_buff_timer)
	UnregisterSignal(owner, COMSIG_MOB_AFTER_APPLY_DAMGE)
	empowered = FALSE
	owner.adjust_attribute_bonus(JUSTICE_ATTRIBUTE, -empowered_power_buff)

	owner.visible_message(span_danger("[owner]'s [src.name] E.G.O. settles down, the electric arcs gradually fading away."), span_warning("Your [src.name] E.G.O. has finished discharging, and its power and influence wane back to normal."))
	icon_state = "lce_aedd_inactive"
	owner.regenerate_icons()

// Called when user is hit. Will reset the arc lightning hitlist, perform a scan around the user. If it manages to find a target, sets off arc lightning and starts the cooldown.
/obj/item/clothing/suit/armor/ego_gear/realization/experimentation/proc/StartArcLightning()
	SIGNAL_HANDLER
	if(!ishuman(owner))
		return
	if(arc_lightning_cooldown > world.time) // No you can't shock people 50 times in 1 tick by diving into an amber bug swarm
		return
	arc_lightning_turf_hitlist = list()
	arc_lightning_mob_hitlist = list()
	var/turf/startpoint = get_turf(owner)

	// If we found an enemy within range, well, they already got shocked, so set the cooldown.
	if(ArcLightningScan(startpoint, 1))
		playsound(startpoint, 'sound/abnormalities/thunderbird/tbird_bolt.ogg', 50, vary = TRUE, extrarange = 5)
		arc_lightning_cooldown = world.time + arc_lightning_cooldown_duration

/obj/item/clothing/suit/armor/ego_gear/realization/experimentation/proc/ArcLightningScan(turf/origin, chains)
	if(chains >= arc_lightning_max_chains) // Alright calm down
		return
	// Get all the nearby turfs and eliminate turfs we've already hit
	var/list/valid_turfs = view(arc_lightning_range, origin)
	valid_turfs -= arc_lightning_turf_hitlist
	// Try to find a mob that isn't dead and isn't in our faction. Considers allies, too. Won't hurt 'em though, gives a buff instead.
	var/mob/living/found_mob
	for(var/turf/T in valid_turfs)
		for(var/mob/living/L in T)
			if((L.stat >= DEAD) || istype(L, /mob/living/simple_animal/projectile_blocker_dummy) || (L in arc_lightning_mob_hitlist) || L == owner)
				continue
			found_mob = L
			break
	// Found one? Shock them.
	if(found_mob)
		var/turf/impact_turf = get_turf(found_mob)
		var/datum/beam/new_beam = origin.Beam(impact_turf, icon_state="lightning[rand(1,12)]", time = 3)
		new_beam.visuals.color = "#70c2e0" // The lion refuses to use colour palette defines
		new_beam.visuals.layer = POINT_LAYER
		arc_lightning_turf_hitlist |= impact_turf
		INVOKE_ASYNC(src, PROC_REF(ArcLightningHit), impact_turf, chains) // ArcLightningHit will call this same proc recursively.
		return TRUE
	return FALSE

/// Proc which deals damage to all mobs that aren't in the owner's faction in the given turf, gives BLACK protection to allies in the turf, and will attempt to chain lightning again from that turf.
/obj/item/clothing/suit/armor/ego_gear/realization/experimentation/proc/ArcLightningHit(turf/target_turf, chains)
	for(var/mob/living/L in target_turf)
		if(L in arc_lightning_mob_hitlist) // This mob was already zapped. Ignore!
			continue
		if(L == owner || L.stat >= DEAD) // duh
			continue

		if(owner.faction_check_mob(L)) // Ally. Don't damage, give BLACK protection up to 3 stacks.
			to_chat(L, span_nicegreen("Electricity harmlessly arcs through you, and you feel it protect you against BLACK damage!"))
			var/datum/status_effect/stacking/damtype_protection/black/current_stacks = L.has_status_effect(/datum/status_effect/stacking/damtype_protection/black/)
			var/current_stack_amount = current_stacks ? current_stacks.stacks : 0
			var/new_stack_amount = current_stack_amount + 1
			if(new_stack_amount >= 4)
				current_stacks.refresh()
			else
				L.apply_lc_black_protection(new_stack_amount)

			var/obj/item/clothing/suit/armor/ego_gear/realization/experimentation/also_has_suit_like_ours = L.get_item_by_slot(ITEM_SLOT_OCLOTHING)
			if(istype(also_has_suit_like_ours)) // If they're wearing this same realization, give them 1 self-charge (it's funny)
				also_has_suit_like_ours.AdjustCharge(1)

		else // Enemy. Zap!
			L.deal_damage(arc_lightning_damage, BLACK_DAMAGE, source = owner, attack_type = (ATTACK_TYPE_SPECIAL | ATTACK_TYPE_COUNTER))
			to_chat(L, span_danger("Electricity arcs through you, shocking you!"))

		arc_lightning_mob_hitlist |= L // Add mob we just hit to our mob hitlist.

	new /obj/effect/temp_visual/justitia_effect(target_turf)
	playsound(target_turf, 'sound/weapons/fixer/generic/energy2.ogg', 40, vary = TRUE, extrarange = 5)
	sleep(0.2 SECONDS)
	ArcLightningScan(target_turf, chains + 1)

/* WAW Realizations */

/obj/item/clothing/suit/armor/ego_gear/realization/goldexperience
	name = "gold experience"
	desc = "A jacket made of gold is hardly light. But it shines like the sun."
	icon_state = "gold_experience"
	armor = list(RED_DAMAGE = 80, WHITE_DAMAGE = 60, BLACK_DAMAGE = 50, PALE_DAMAGE = 40)			//Melee
	realized_ability = /obj/effect/proc_holder/ability/road_of_gold

/obj/item/clothing/suit/armor/ego_gear/realization/quenchedblood
	name = "quenched with blood"
	desc = "A suit of armor, forged with tears and quenched in blood. Justice will prevail."
	icon_state = "quenchedblood"
	armor = list(RED_DAMAGE = 50, WHITE_DAMAGE = 60, BLACK_DAMAGE = 40, PALE_DAMAGE = 80)		//Ranged
	flags_inv = HIDEJUMPSUIT|HIDESHOES|HIDEGLOVES
	realized_ability = /obj/effect/proc_holder/ability/aimed/despair_swords

/obj/item/clothing/suit/armor/ego_gear/realization/lovejustice
	name = "love and justice"
	desc = "If my duty is to defeat and reform evil, can I reform my evil self as well?"
	icon_state = "lovejustice"
	armor = list(RED_DAMAGE = 60, WHITE_DAMAGE = 50, BLACK_DAMAGE = 70, PALE_DAMAGE = 50)		//Healing
	flags_inv = HIDEGLOVES
	realized_ability = /obj/effect/proc_holder/ability/aimed/arcana_slave

/obj/item/clothing/suit/armor/ego_gear/realization/woundedcourage
	name = "wounded courage"
	desc = "'Tis better to have loved and lost than never to have loved at all.\
	Grants you the ability to use a Blind Rage in both hands and attack with both at the same time."
	icon_state = "woundedcourage"
	armor = list(RED_DAMAGE = 70, WHITE_DAMAGE = 40, BLACK_DAMAGE = 70, PALE_DAMAGE = 50)		//Melee
	flags_inv = HIDEJUMPSUIT | HIDEGLOVES | HIDESHOES
	realized_ability = /obj/effect/proc_holder/ability/justice_and_balance
	hat = /obj/item/clothing/head/ego_hat/woundedcourage_hat

/obj/item/clothing/head/ego_hat/woundedcourage_hat
	name = "wounded courage"
	desc = "An excuse to overlook your own misdeeds."
	icon_state = "woundedcourage"
	flags_inv = HIDEMASK | HIDEEYES

/* This Realization has several effects:
1. Grants an ability: Strike Without Hesitation. Wind-up AoE that damages all nearby mobs and gives you Power Mod per target hit.
Also lets you dual wield Crimson Scars and makes your Crimson Claw bounce between all nearby enemies.
2. Grants a passive ability: Hunter's Mark. An Ordeal enemy or breached Abnormality is marked every once in a while. You can track them using an item action called Hunter's Trail.
If you land the killing blow on that enemy, you get a buff and a heal.
3. Empowers the Crimson Scar and Crimson Claw weapons:
- Crimson Claw gets higher damage and inflicts Hemorrhage on combo finisher/thrown attack, Hemorrhage does nothing on its own but when consumed by CrimScar it deals damage based on the user's Fortitude.
- Crimson Scar gets higher damage and piercing ammo, and can load a Hollowpoint Shell that consumes Hemorrhage.
4. If both the buff from Hunter's Mark's payout and Strike Without Hesitation are active at once, you get HP regen and stun immunity for a bit. Both buffs will refresh eachother's duration when applied.
*/
/obj/item/clothing/suit/armor/ego_gear/realization/crimson
	name = "crimson lust"
	desc = "They are always watching you."
	icon_state = "crimson" // Sprites by Mel Taculo.
	armor = list(RED_DAMAGE = 80, WHITE_DAMAGE = 40, BLACK_DAMAGE = 50, PALE_DAMAGE = 60) // 230, since it has an ability and passives.
	realized_ability = /obj/effect/proc_holder/ability/strike_without_hesitation // Wind-up indiscriminate AoE damage that grants an empowered state based on amount of targets hit. More targets hit = more power. Also lets you dual wield CrimScar. Special interaction with BWBBW and Cobalt Scar.
	actions_types = list(/datum/action/item_action/crimlust_hunter_trail)
	/// World time at which we applied the last mark
	var/last_applied_mark_time
	/// Holds the timer for applying the next mark. Doesn't necessarily mean a mark WILL be applied when it ends, just that we'll check and try to apply one
	var/mark_apply_timer
	/// The cooldown for a successful mark.
	var/mark_apply_cooldown_time = 120 SECONDS
	/// Holds a reference to the last mark status effect we applied.
	var/datum/status_effect/crimlust_mark/last_applied_mark_datum
	/// A list of breached Abnormalities. Ordeals are pulled from Lobotomy Corp subsystem in PickMarkTarget()
	var/list/valid_mark_candidates = list()
	/// These ones can't ever be chosen for our mark
	var/list/mark_blacklisted_types = list(
		/mob/living/simple_animal/hostile/abnormality/training_rabbit, // duh
		/mob/living/simple_animal/hostile/abnormality/training_rabbit/boar, // duh
		/mob/living/simple_animal/hostile/abnormality/wrath_servant, // Issues with the way she's recontained
		/mob/living/simple_animal/hostile/abnormality/sirocco, // Invincible
		/mob/living/simple_animal/hostile/abnormality/highway_devotee, // Invincible
		/mob/living/simple_animal/hostile/abnormality/branch12/rock, // You have better things to hunt than boulders
		/mob/living/simple_animal/hostile/abnormality/branch12/black_hole, // This one is beyond you
	)
	// These vars are used for scaling the "early-pop" mark threshold
	var/mark_payout_hp_scaling_base_threshold = 2000
	var/mark_payout_hp_scaling_threshold_max_increase = 1500
	var/mark_payout_hp_scaling_target_lowest_health = 1500
	var/mark_payout_hp_scaling_target_highest_health = 6000

// Don't actually assign this as the hat for the armour, we apply it while under a certain buff and remove it after. I guess players can take it off early if they want
/obj/item/clothing/head/ego_hat/helmet/crimson
	name = "crimson lust"
	desc = "A bright red hood that you don't really have the time to inspect too closely right now."
	icon_state = "crimson"

/obj/item/clothing/suit/armor/ego_gear/realization/crimson/examine(mob/user)
	. = ..()
	. += span_notice("This E.G.O. will periodically apply <b>Hunter's Mark</b> to a random enemy, allowing you to <b>track them</b> using the <b>Hunter's Trail</b> ability. \
	This mark lasts 50 seconds and a new one is applied every 120 seconds. \
	If you <b>land the finishing blow</b> on this enemy, you will be <b>healed and gain a temporary bonus to Power Modifier</b>. If Strike Without Hesitation's buff is active, refreshes it. \
	Powerful enemies will grant the same reward after you deal enough damage to them.")
	. += ""
	. += span_notice("This E.G.O. will <b>empower</b> the <b>Crimson Claw</b> and <b>Crimson Scar</b> weapons when worn.")
	. += span_notice("<b>Crimson Claw (sword) bonuses</b>: Increased damage. Gains Justice scaling on its throwing attack. \
	Applies <b>Hemorrhage</b> on combo finisher or throwing attack. Hemorrhage deals damage when consumed, scaling off of the user's Fortitude.")
	. += ""
	. += span_notice("<b>Crimson Scar (hand cannon) bonuses</b>: Increased damage. Infinite ammo. Default ammunition is now piercing. Fires faster, fires more pellets and can be <b>dual wielded</b> while Strike Without Hesitation is active. \
	Can now load a hollowpoint shell by reloading the weapon. Hollowpoint ammunition is accurate and hard-hitting, also <b>consuming Hemorrhage.</b>")
	. += ""
	. += span_info("When under the effects of both <b>Strike without Hesitation</b> and <b>Hunter's Mark's payout</b>, gain HP regen and stun immunity.")

// This armour will need to be aware of every Abnormality that breaches so it can potentially mark them. It's better than scanning the whole abno list every time
/obj/item/clothing/suit/armor/ego_gear/realization/crimson/Initialize(mapload)
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_ABNORMALITY_BREACH, PROC_REF(AddAbnoToCandidateList))

/obj/item/clothing/suit/armor/ego_gear/realization/crimson/Destroy(force)
	UnregisterSignal(SSdcs, COMSIG_GLOB_ABNORMALITY_BREACH)
	return ..()

// Called every time an Abno breaches, we add it to our potential targets list.
/obj/item/clothing/suit/armor/ego_gear/realization/crimson/proc/AddAbnoToCandidateList(datum/source, mob/living/simple_animal/hostile/abnormality/breached)
	SIGNAL_HANDLER
	if(!istype(breached))
		return
	if(breached.type in mark_blacklisted_types)
		return
	if(is_tutorial_level(breached.z))
		return
	/*if(!(breached.area_index & (MOB_ABNORMALITY_INDEX | MOB_HOSTILE_INDEX)))
		return
	This would avoid some questionable mark targets like Friendlybreach QoH/Pyg, only issue is that we don't have a way to detect when they become hostile. So uh, I guess we can still mark them.
		*/
	valid_mark_candidates |= breached
	RegisterSignal(breached, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(RemoveAbnoFromCandidateList))

// And when an abno we previously added to our list gets deleted or killed, we remove it.
/obj/item/clothing/suit/armor/ego_gear/realization/crimson/proc/RemoveAbnoFromCandidateList(datum/source)
	SIGNAL_HANDLER
	if(!isabnormalitymob(source))
		return
	UnregisterSignal(source, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	valid_mark_candidates -= source

/// Chooses 1 random target out of all breached Abnormalities and ongoing Ordeal mobs. Unfortunately this means some special mobs like Runaway Crows or Grown Strong can't be selected.
// I think it'd be too expensive to run constant scans for potential mark targets, I believe this is the least expensive option all things considered.
/obj/item/clothing/suit/armor/ego_gear/realization/crimson/proc/PickMarkTarget(mob/living/carbon/human/hunter)
	if(!ishuman(hunter))
		return FALSE

	if(hunter.stat >= DEAD)
		return FALSE

	// If our mark is still on cooldown, set a timer to call this once the cooldown ends.
	var/time_since_mark = last_applied_mark_time ? world.time - last_applied_mark_time : INFINITY
	if(time_since_mark < mark_apply_cooldown_time)
		SetupMarkTimer(hunter, (mark_apply_cooldown_time - time_since_mark + 1))
		return FALSE

	if(!QDELETED(last_applied_mark_datum)) // Should never ever happen
		qdel(last_applied_mark_datum)

	var/list/potential_targets = list() // New list.
	potential_targets |= valid_mark_candidates // Add all breaching abnormalities to the new list.

	var/list/ongoing_ordeals = SSlobotomy_corp.current_ordeals
	if(length(ongoing_ordeals) > 0) // If there's at least 1 ongoing ordeal...
		for(var/datum/ordeal/O in ongoing_ordeals) // Add every ordeal mob into the new list.
			potential_targets |= O.ordeal_mobs // |= prevents Pink Midnight from causing duplicate entries

	for(var/mob/living/prospect in potential_targets)
		if((prospect.z != hunter.z) || (prospect.has_status_effect(/datum/status_effect/crimlust_mark))) // Z level check, also checks for targets already marked for whatever reason
			potential_targets -= prospect

	if(length(potential_targets) <= 0) // No targets found...
		SetupMarkTimer(hunter, 5 SECONDS) // Check again in 5s. An 'expensive' run of this proc should only happen like once every 120s, this proc will mostly be run while valid_mark_candidates and ongoing_ordeals are empty lists.
		return FALSE

	var/mob/living/chosen_target = pick(potential_targets)
	var/target_maxhp = chosen_target.maxHealth
	var/mark_hp = mark_payout_hp_scaling_base_threshold + floor(clamp(((target_maxhp - mark_payout_hp_scaling_target_lowest_health) * (mark_payout_hp_scaling_threshold_max_increase) / (mark_payout_hp_scaling_target_highest_health - mark_payout_hp_scaling_target_lowest_health)), 0, mark_payout_hp_scaling_threshold_max_increase))
	last_applied_mark_datum = chosen_target.apply_status_effect(/datum/status_effect/crimlust_mark, hunter, mark_hp)
	last_applied_mark_time = world.time
	SetupMarkTimer(hunter, mark_apply_cooldown_time) // Call this again once the cooldown's over.

	SEND_SOUND(hunter, sound('sound/abnormalities/armyinblack/black_heartbeat.ogg'))
	flash_color(hunter, flash_color = COLOR_RED_LIGHT, flash_time = 1 SECONDS)

	TrackTarget(hunter, TRUE)
	return TRUE

// Called once when first acquiring a new marked target, and can be called again by the user if they want. Tells you in chat/balloon alert roughly where your target is.
/obj/item/clothing/suit/armor/ego_gear/realization/crimson/proc/TrackTarget(mob/living/carbon/human/hunter, first_time = FALSE)
	if(QDELETED(last_applied_mark_datum))
		to_chat(hunter, span_warning("You're currently not hunting anything - there's nothing to track."))
		return

	var/mob/living/chosen_target = last_applied_mark_datum.owner

	var/where_are_they = get_dir(hunter, chosen_target)
	var/how_far = get_dist(hunter, chosen_target)
	var/dir_message = ""
	if(where_are_they & NORTH)
		dir_message = "north"
	else if (where_are_they & SOUTH)
		dir_message = "south"

	if(where_are_they & EAST)
		dir_message += "east"
	else
		dir_message += "west"
	var/assembled_message = "You sense [chosen_target] [how_far] meters [dir_message] of you, in [chosen_target.loc.loc]."
	if(first_time)
		assembled_message += " The hunt is on."
	var/final_message = first_time ? span_userdanger(assembled_message) : span_warning(assembled_message)
	to_chat(hunter, final_message)
	hunter.balloon_alert(hunter, assembled_message)

// Called when the armour enters our inventory in any slot
/obj/item/clothing/suit/armor/ego_gear/realization/crimson/equipped(mob/user, slot)
	. = ..()
	if(!(ishuman(user)) || !(slot == ITEM_SLOT_OCLOTHING)) // If not being grabbed by a human, or not being put on the EGO armour slot, clear the ongoing timer for performance's sake.
		ClearMarkTimer()
		return
	PickMarkTarget(user) // Try to immediately set a marked target. Handles cooldown checking by itself and sets up the timer if no targets are available.

// If you take off the armour then we nuke any active marks and the timer
/obj/item/clothing/suit/armor/ego_gear/realization/crimson/dropped(mob/user)
	. = ..()
	ClearMarkTimer()
	QDEL_NULL(last_applied_mark_datum)

/obj/item/clothing/suit/armor/ego_gear/realization/crimson/proc/SetupMarkTimer(mob/user, in_how_long)
	ClearMarkTimer()
	mark_apply_timer = addtimer(CALLBACK(src, PROC_REF(PickMarkTarget), user), in_how_long, TIMER_STOPPABLE)

/obj/item/clothing/suit/armor/ego_gear/realization/crimson/proc/ClearMarkTimer()
	if(mark_apply_timer)
		deltimer(mark_apply_timer)
		mark_apply_timer = null

// Allows us to track our target if we need to do it again for whatever reason.
/datum/action/item_action/crimlust_hunter_trail
	name = "Hunter's Trail"
	desc = "Concentrate for 2 seconds to track down your currently marked target."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/teguicons.dmi'
	button_icon_state = "red_target"
	var/cooldown

// This needs to be a full override because item actions normally click the item they're associated to
/datum/action/item_action/crimlust_hunter_trail/Trigger()
	if(!IsAvailable())
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_ACTION_TRIGGER, src) & COMPONENT_ACTION_BLOCK_TRIGGER)
		return FALSE
	if(cooldown > world.time)
		return FALSE
	cooldown = world.time + 1 SECONDS
	var/obj/item/clothing/suit/armor/ego_gear/realization/crimson/our_suit = target
	if(!istype(our_suit))
		return
	if(!do_after(owner, 2 SECONDS, timed_action_flags = IGNORE_USER_LOC_CHANGE | IGNORE_HELD_ITEM, interaction_key = "crimlust_hunter_trail", max_interact_count = 1))
		to_chat(owner, span_warning("You lose concentration, and fail to track your target."))
		return
	our_suit.TrackTarget(owner, FALSE)

// This status effect does nothing except add a visual mark and check if its owner is killed by the person who applied it/they deal enough damage. If they do, then they get the payout buff.
/datum/status_effect/crimlust_mark
	id = "crimlust_mark"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 50 SECONDS
	tick_interval = -1 // We don't need to tick
	alert_type = null
	var/mob/living/carbon/human/crimlust_user
	var/mob/living/simple_animal/hostile/marked_owner
	var/mutable_appearance/mark_overlay
	var/bounty_claimed = FALSE
	var/damage_left = 2000

/datum/status_effect/crimlust_mark/on_creation(mob/living/new_owner, mob/living/carbon/human/mercenary, mark_hp = 2000)
	if(!(..()))
		return FALSE
	if(!(ishostile(new_owner)) || !(ishuman(mercenary)))
		qdel(src)
		return FALSE

	marked_owner = new_owner
	crimlust_user = mercenary
	damage_left = mark_hp
	mark_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/teguicons.dmi', "red_target", ABOVE_MOB_LAYER)

	// Mark visual
	var/icon/target_icon = icon(marked_owner.icon, marked_owner.icon_state, marked_owner.dir)
	var/icon_height = target_icon.Height()
	var/icon_width = target_icon.Width()
	var/height_diff = icon_height - 32
	var/width_diff = icon_width - 32
	mark_overlay.pixel_y += 36 + floor((height_diff * 0.6))
	mark_overlay.pixel_x += (width_diff * 0.5)
	mark_overlay.alpha = 190
	mark_overlay.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	marked_owner.add_overlay(mark_overlay)

	// Signal for detecting killing blows
	RegisterSignal(marked_owner, COMSIG_MOB_APPLY_DAMGE, PROC_REF(CheckDeath)) // It really sucks we have to use APPLY_DAMGE here and not AFTER_APPLY_DAMGE, the problem is that anything that qdels or gibs on death won't send PostDamageReaction and refactoring damage to make that happen is too intrusive for this little PR
	// Remove this status if the caster dies
	RegisterSignal(crimlust_user, COMSIG_LIVING_DEATH, PROC_REF(Cancel))
	return TRUE

/datum/status_effect/crimlust_mark/on_remove()
	. = ..()
	if(marked_owner)
		marked_owner.cut_overlay(mark_overlay)
	if(crimlust_user)
		var/success_message
		if(bounty_claimed == "death")
			success_message = "You've completed your hunt. Another nightmare is kept from haunting your nights."
		else if(bounty_claimed == "damage")
			success_message = "Your target is ravaged by grievous wounds. Keep it up and you'll be able to hang its head over your bed."
		var/message = !isnull(success_message) ? span_nicegreen(success_message) : span_warning("You weren't able to complete your hunt.")
		to_chat(crimlust_user, message)

// Called when the marked enemy is taking damage. Sadly we can't use AFTER_APPLY_DAMGE as explained previously. Also we don't check to make sure we're still wearing Crimson Lust here, because I could but like, this is being run on every hit so let's not
/datum/status_effect/crimlust_mark/proc/CheckDeath(datum/source, damage_amount, damage_type, def_zone, source_of_damage, flags, attack_type)
	SIGNAL_HANDLER
	if(!marked_owner || bounty_claimed)
		return
	if(!(source_of_damage == crimlust_user))
		return
	if(marked_owner.stat >= DEAD)
		return
	var/datum/dam_coeff/damage_coeff = marked_owner.damage_coeff
	var/final_damage_dealt = (damage_amount * damage_coeff.getCoeff(damage_type)) // In an ideal world this calc would be unnecessary but this isn't an ideal world
	damage_left -= final_damage_dealt
	if((marked_owner.health - final_damage_dealt <= 0))
		bounty_claimed = "death" // Determines the message sent to the user
		Payout()
	else if(damage_left <= 0)
		bounty_claimed = "damage" // Determines the message sent to the user
		Payout()

// Called only when the owner is killed by the Crimlust user/the Crimlust user deals enough damage
/datum/status_effect/crimlust_mark/proc/Payout()
	if(crimlust_user)
		crimlust_user.apply_status_effect(/datum/status_effect/crimlust_mark_payout)
	qdel(src)

/datum/status_effect/crimlust_mark/proc/Cancel()
	SIGNAL_HANDLER
	qdel(src)

/// This buff is given when killing a marked target. It heals your HP and SP once and gives you PowerMod
/// If No Hesitation is present, refreshes it (the buff, not the ability), and will give the owner stun immunity and periodic HP regen.
/datum/status_effect/crimlust_mark_payout
	id = "crimlust_mark_payout"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 20 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/crimlust_mark_payout
	var/powermod_bonus = 20
	var/initial_hp_sp_heal = 40
	var/empowered_tick_healing = 6
	var/check_for_linked_buff = FALSE
	var/datum/status_effect/crimlust_no_hesitation/linked_buff
	var/mutable_appearance/eye_vfx

/datum/status_effect/crimlust_mark_payout/on_creation(mob/living/new_owner, ...)
	. = ..()
	if(!ishuman(new_owner))
		qdel(src)
	var/mob/living/carbon/human/our_owner = new_owner

	// Link to No Hesitation if it already exists
	var/datum/status_effect/crimlust_no_hesitation/angry_mercenary = new_owner.has_status_effect(/datum/status_effect/crimlust_no_hesitation)
	if(angry_mercenary)
		LinkBuffs(angry_mercenary)

	// HP/SP initial heal and VFX
	our_owner.adjustBruteLoss(-initial_hp_sp_heal)
	our_owner.adjustSanityLoss(-initial_hp_sp_heal)
	for(var/i in 1 to 2)
		new /obj/effect/temp_visual/heal(get_turf(owner), "#FF4444")
		new /obj/effect/temp_visual/heal(get_turf(owner), "#6E6EFF")

	// Power Modifier gain
	our_owner.adjust_attribute_bonus(JUSTICE_ATTRIBUTE, powermod_bonus)

	// Flaming eye overlay
	eye_vfx = mutable_appearance('icons/effects/effects.dmi', "redhood_eye_effect", ABOVE_MOB_LAYER)
	our_owner.add_overlay(eye_vfx)

// On every tick of this status, if we're linked to an active No Hesitation, recover some HP.
/datum/status_effect/crimlust_mark_payout/tick()
	. = ..()
	if(!check_for_linked_buff)
		return
	if(!QDELETED(linked_buff))
		owner.adjustBruteLoss(-empowered_tick_healing)
	else
		UnlinkBuffs()

// When this buff falls off, undo our Power Mod buff and unlink the buff from No Hesitation which will also drop our stun immunity.
/datum/status_effect/crimlust_mark_payout/on_remove()
	. = ..()
	UnlinkBuffs()
	var/mob/living/carbon/human/our_owner = owner
	if(istype(our_owner))
		our_owner.adjust_attribute_bonus(JUSTICE_ATTRIBUTE, -powermod_bonus)
		if(eye_vfx)
			our_owner.cut_overlay(eye_vfx)

// Called when either: 1. This buff is created and No Hesitation exists or 2. By No Hesitation if it's created while this exists
/datum/status_effect/crimlust_mark_payout/proc/LinkBuffs(datum/status_effect/crimlust_no_hesitation/link_to_this)
	if(linked_buff) // This should never happen. We shouldn't have a reference to No Hesitation already
		return
	check_for_linked_buff = TRUE
	linked_buff = link_to_this
	linked_buff.refresh()
	refresh()
	ADD_TRAIT(owner, TRAIT_STUNIMMUNE, "crimlust_empowered")
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(EmpoweredMoveVFX))

// This is called once this buff is falling off or when we detect that No Hesitation fell off. We lose stun immunity and we'll stop checking if No Hesitation is active for our HP regen
/datum/status_effect/crimlust_mark_payout/proc/UnlinkBuffs()
	check_for_linked_buff = FALSE
	linked_buff = null
	REMOVE_TRAIT(owner, TRAIT_STUNIMMUNE, "crimlust_empowered")
	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)

// A brief afterimage while moving if both buffs are active
/datum/status_effect/crimlust_mark_payout/proc/EmpoweredMoveVFX(datum/source, OldLoc, Dir, Forced)
	SIGNAL_HANDLER
	if(!owner)
		return
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(OldLoc, owner)
	D.alpha = 200
	animate(D, alpha = 0, time = 3)

/atom/movable/screen/alert/status_effect/crimlust_mark_payout
	name = "Successful Hunt"
	desc = "You've laid one of your nightmares to rest. Power Modifier is increased by 20."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "hunt_finished"

/obj/item/clothing/suit/armor/ego_gear/realization/eyes
	name = "eyes of god"
	desc = "And the eyes of god spoke: You will be saved."
	icon_state = "eyes"
	armor = list(RED_DAMAGE = 50, WHITE_DAMAGE = 60, BLACK_DAMAGE = 80, PALE_DAMAGE = 40)		//Support
	realized_ability = /obj/effect/proc_holder/ability/lamp

/obj/item/clothing/suit/armor/ego_gear/realization/eyes/examine(mob/user)
	. = ..()
	. += "<span class='notice'>The wearer can sense it whenever an abnormality breaches.</span>"

/obj/item/clothing/suit/armor/ego_gear/realization/eyes/equipped(mob/user, slot, initial = FALSE)
	. = ..()
	if(item_action_slot_check(slot, user))
		RegisterSignal(SSdcs, COMSIG_GLOB_ABNORMALITY_BREACH, PROC_REF(OnAbnoBreach))

/obj/item/clothing/suit/armor/ego_gear/realization/eyes/dropped(mob/user)
	UnregisterSignal(SSdcs, COMSIG_GLOB_ABNORMALITY_BREACH)
	return ..()

/obj/item/clothing/suit/armor/ego_gear/realization/eyes/proc/OnAbnoBreach(datum/source, mob/living/simple_animal/hostile/abnormality/abno)
	SIGNAL_HANDLER
	if(!ishuman(loc))
		return
	if(loc.z != abno.z)
		return
	addtimer(CALLBACK(src, PROC_REF(NotifyEscape), loc, abno), rand(1 SECONDS, 3 SECONDS))

/obj/item/clothing/suit/armor/ego_gear/realization/eyes/proc/NotifyEscape(mob/living/carbon/human/user, mob/living/simple_animal/hostile/abnormality/abno)
	if(QDELETED(abno) || abno.stat == DEAD || loc != user)
		return
	to_chat(user, "<span class='warning'>You can sense the escape of [abno]...</span>")
	playsound(get_turf(user), 'sound/abnormalities/bigbird/hypnosis.ogg', 25, 1, -4)
	var/turf/start_turf = get_turf(user)
	var/turf/last_turf = get_ranged_target_turf_direct(start_turf, abno, 5)
	var/list/navline = getline(start_turf, last_turf)
	for(var/turf/T in navline)
		new /obj/effect/temp_visual/cult/turf/floor(T)

/obj/item/clothing/suit/armor/ego_gear/realization/cruelty
	name = "wit of cruelty"
	desc = "In the face of pain there are no heroes."
	icon_state = "cruelty"
	armor = list(RED_DAMAGE = 80, WHITE_DAMAGE = 50, BLACK_DAMAGE = 70, PALE_DAMAGE = 50)		//No Ability
	flags_inv = HIDEJUMPSUIT|HIDEGLOVES|HIDESHOES

/obj/item/clothing/suit/armor/ego_gear/realization/bell_tolls
	name = "for whom the bell tolls"
	desc = "I suppose if a man has something once, always something of it remains."
	icon_state = "thirteen"
	armor = list(RED_DAMAGE = 50, WHITE_DAMAGE = 50, BLACK_DAMAGE = 80, PALE_DAMAGE = 70)		//No Ability

/obj/item/clothing/suit/armor/ego_gear/realization/capitalism
	name = "capitalism"
	desc = "While the miser is merely a capitalist gone mad, the capitalist is a rational miser."
	icon_state = "capitalism"
	armor = list(RED_DAMAGE = 70, WHITE_DAMAGE = 70, BLACK_DAMAGE = 60, PALE_DAMAGE = 30)		//Support
	realized_ability = /obj/effect/proc_holder/ability/shrimp

/obj/item/clothing/suit/armor/ego_gear/realization/duality_yang
	name = "duality of harmony"
	desc = "When good and evil meet discord and assonance will be quelled."
	icon_state = "duality_yang"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 80, BLACK_DAMAGE = 40, PALE_DAMAGE = 70)		//Healing
	realized_ability = /obj/effect/proc_holder/ability/tranquility

/obj/item/clothing/suit/armor/ego_gear/realization/duality_yin
	name = "harmony of duality"
	desc = "All that isn't shall become all that is."
	icon_state = "duality_yin"
	armor = list(RED_DAMAGE = 70, WHITE_DAMAGE = 40, BLACK_DAMAGE = 80, PALE_DAMAGE = 40)		//Support
	realized_ability = /obj/effect/proc_holder/ability/aimed/yin_laser

/obj/item/clothing/suit/armor/ego_gear/realization/repentance
	name = "repentance"
	desc = "If you pray hard enough, perhaps god will answer it?"
	icon_state = "repentance"
	armor = list(RED_DAMAGE = 80, WHITE_DAMAGE = 40, BLACK_DAMAGE = 40, PALE_DAMAGE = 70)		//Healing
	realized_ability = /obj/effect/proc_holder/ability/prayer

/obj/item/clothing/suit/armor/ego_gear/realization/nest
	name = "living nest"
	desc = "Grow eternally, let our nest reach the horizon!"
	icon_state = "nest"
	armor = list(RED_DAMAGE = 80, WHITE_DAMAGE = 60, BLACK_DAMAGE = 50, PALE_DAMAGE = 40)		//Support
	realized_ability = /obj/effect/proc_holder/ability/nest
	var/CanSpawn = FALSE

/obj/item/clothing/suit/armor/ego_gear/realization/nest/equipped(mob/user, slot, initial = FALSE)
	. = ..()
	if(slot == ITEM_SLOT_OCLOTHING)
		CanSpawn = TRUE
		addtimer(CALLBACK(src, PROC_REF(Spawn),user), 10 SECONDS)

/obj/item/clothing/suit/armor/ego_gear/realization/nest/dropped(mob/user)
	CanSpawn = FALSE
	return ..()

/obj/item/clothing/suit/armor/ego_gear/realization/nest/proc/Reset(mob/user)
	if(!CanSpawn)
		return
	Spawn(user)

/obj/item/clothing/suit/armor/ego_gear/realization/nest/proc/Spawn(mob/user)
	if(!CanSpawn)
		return
	addtimer(CALLBACK(src, PROC_REF(Reset),user), 10 SECONDS)
	playsound(get_turf(user), 'sound/misc/moist_impact.ogg', 30, 1)
	var/mob/living/simple_animal/hostile/naked_nest_serpent_friend/W = new(get_turf(user))
	W.origin_nest = user

/* ALEPH Realizations */

/obj/item/clothing/suit/armor/ego_gear/realization/alcoda
	name = "al coda"
	desc = "Harmonizes well."
	icon_state = "coda"
	armor = list(RED_DAMAGE = 70, WHITE_DAMAGE = 100, BLACK_DAMAGE = 60, PALE_DAMAGE = 20)		//No Ability

/obj/item/clothing/suit/armor/ego_gear/realization/head
	name = "head of god"
	desc = "And the head of god spoke: You will be judged."
	icon_state = "head"
	armor = list(RED_DAMAGE = 50, WHITE_DAMAGE = 50, BLACK_DAMAGE = 50, PALE_DAMAGE = 80)		//Support
	realized_ability = /obj/effect/proc_holder/ability/judgement

/obj/item/clothing/suit/armor/ego_gear/realization/shell
	name = "shell"
	desc = "Armor of humans, for humans, by humans. Is it as 'human' as you?"
	icon_state = "shell"
	realized_ability = /obj/effect/proc_holder/ability/goodbye
	armor = list(RED_DAMAGE = 80, WHITE_DAMAGE = 60, BLACK_DAMAGE = 30, PALE_DAMAGE = 60)			//Melee

/obj/item/clothing/suit/armor/ego_gear/realization/laughter
	name = "laughter"
	desc = "I do not recognize them, I must not, lest I end up like them. \
			Through the silence, I hear them, I see them. The faces of all my friends are with me laughing too."
	icon_state = "laughter"
	armor = list(RED_DAMAGE = 50, WHITE_DAMAGE = 50, BLACK_DAMAGE = 80, PALE_DAMAGE = 50)		//Support
	flags_inv = HIDEJUMPSUIT|HIDESHOES|HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR
	realized_ability = /obj/effect/proc_holder/ability/screach

/obj/item/clothing/suit/armor/ego_gear/realization/fallencolors
	name = "fallen color"
	desc = "Where does one go after falling into a black hole?"
	icon_state = "fallencolors"
	realized_ability = /obj/effect/proc_holder/ability/aimed/blackhole
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 80, BLACK_DAMAGE = 80, PALE_DAMAGE = 30)		//Defensive
	var/canSUCC = TRUE

/obj/item/clothing/suit/armor/ego_gear/realization/fallencolors/equipped(mob/user, slot, initial = FALSE)
	. = ..()
	if(slot == ITEM_SLOT_OCLOTHING)
		RegisterSignal(user, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnDamaged))

/obj/item/clothing/suit/armor/ego_gear/realization/fallencolors/dropped(mob/user)
	UnregisterSignal(user, COMSIG_MOB_APPLY_DAMGE)
	return ..()

/obj/item/clothing/suit/armor/ego_gear/realization/fallencolors/proc/Reset()
	canSUCC = TRUE

/obj/item/clothing/suit/armor/ego_gear/realization/fallencolors/proc/OnDamaged(mob/living/carbon/human/user)
	//goonchem_vortex(get_turf(src), 1, 3)
	if(!canSUCC)
		return
	if(user.is_working)
		return
	canSUCC = FALSE
	addtimer(CALLBACK(src, PROC_REF(Reset)), 2 SECONDS)
	for(var/turf/T in view(3, user))
		new /obj/effect/temp_visual/revenant(T)
		for(var/mob/living/L in T)
			if(user.faction_check_mob(L, FALSE))
				continue
			if(L.stat == DEAD)
				continue
			var/atom/throw_target = get_edge_target_turf(L, get_dir(L, get_step_away(L, get_turf(src))))
			L.throw_at(throw_target, 1, 1)
			L.deal_damage(5, WHITE_DAMAGE, user, attack_type = (ATTACK_TYPE_SPECIAL))


/* Effloresced (Personal) E.G.O */
/obj/item/clothing/suit/armor/ego_gear/realization/farmwatch
	name = "farmwatch"
	desc = "Haha. You're right, the calf doesn't recognize me."
	icon_state = "farmwatch"
	armor = list(RED_DAMAGE = 70, WHITE_DAMAGE = 70, BLACK_DAMAGE = 40, PALE_DAMAGE = 60)
	hat = /obj/item/clothing/head/ego_hat/farmwatch_hat
	assimilation_ability = /obj/effect/proc_holder/ability/ego_assimilation/farmwatch

/obj/item/clothing/head/ego_hat/farmwatch_hat
	name = "farmwatch"
	desc = "I'll gather a team again... hire another secretary... There'll be a lot to do."
	icon_state = "farmwatch"

/obj/item/clothing/suit/armor/ego_gear/realization/spicebush
	name = "spicebush"
	desc = "I've always wished to be a bud. Soon to bloom, bearing a scent within."
	icon_state = "spicebush"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 70, BLACK_DAMAGE = 70, PALE_DAMAGE = 60)
	assimilation_ability = /obj/effect/proc_holder/ability/ego_assimilation/spicebush

/obj/item/clothing/suit/armor/ego_gear/realization/desperation
	name = "Scorching Desperation"
	desc = "Those feelings only become more dull over time."
	icon_state = "desperation"
	armor = list(RED_DAMAGE = 70, WHITE_DAMAGE = 40, BLACK_DAMAGE = 60, PALE_DAMAGE = 60)
	realized_ability = /obj/effect/proc_holder/ability/overheat
	assimilation_ability = /obj/effect/proc_holder/ability/ego_assimilation/waxen

/obj/item/clothing/suit/armor/ego_gear/realization/gasharpoon
	name = "gasharpoon"
	desc = "We must find the Pallid Whale! Look alive, men! Spring! Roar!"
	icon_state = "gasharpoon"
	armor = list(RED_DAMAGE = 60, WHITE_DAMAGE = 70, BLACK_DAMAGE = 20, PALE_DAMAGE = 80)//230, required for the corresponding weapon abilities
	assimilation_ability = /obj/effect/proc_holder/ability/ego_assimilation/gasharpoon
