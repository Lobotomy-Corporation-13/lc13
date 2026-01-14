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
	name = "exsaungination"
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

	owner.adjust_attribute_buff(JUSTICE_ATTRIBUTE, empowered_power_buff) // UNLIMITED POWER (modifier)
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
	owner.adjust_attribute_buff(JUSTICE_ATTRIBUTE, -empowered_power_buff)

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

/obj/item/clothing/suit/armor/ego_gear/realization/crimson
	name = "crimson lust"
	desc = "They are always watching you."
	icon_state = "crimson"
	armor = list(RED_DAMAGE = 80, WHITE_DAMAGE = 50, BLACK_DAMAGE = 60, PALE_DAMAGE = 60)		//No Ability

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
