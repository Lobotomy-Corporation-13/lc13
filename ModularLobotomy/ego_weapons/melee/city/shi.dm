//Shi has 2 different modes. Dash Attacks and Boundary of Death.
//Shi Assassin (Current one being used right now) uses Boundary of death.

/obj/item/ego_weapon/city/shi_knife
	name = "shi association knife"
	desc = "A blade that is used by Shi Section 2 assassins to go out with honour."
	special = "Attack yourself with this weapon to instantly kill yourself."
	icon_state = "shi_dagger"
	force = 40
	damtype = RED_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP

	attack_verb_continuous = list("pokes", "jabs", "tears", "lacerates", "gores")
	attack_verb_simple = list("poke", "jab", "tear", "lacerate", "gore")
	hitsound = 'sound/weapons/bladeslice.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 60
	)
	var/force_update = 44
	var/static/suicide_used = list()

/obj/item/ego_weapon/city/shi_knife/attack(mob/living/target, mob/living/carbon/human/user)
	force = force_update
	if(target == user)
		if(user.ckey in suicide_used)
			to_chat(user, span_warning("To suicide once more would bring dishonor to your name."))
			return
		user.death()
		for(var/mob/M in GLOB.player_list)
			to_chat(M, span_userdanger("[uppertext(user.real_name)] has gone out with honor. 灰は灰に "))
		new /obj/effect/temp_visual/BoD(get_turf(target))
		suicide_used |= user.ckey
	if(!CanUseEgo(user))
		return
	..()

//Boundary of death users
//Grade 5
/obj/item/ego_weapon/city/shi_assassin
	name = "shi association sheathed blade"
	desc = "A blade that is used by Shi Section 2."
	special = "Use this weapon in hand to immobilize yourself for 1 second, cut your HP by 25%, and deal 2x damage in pale."
	icon_state = "shiassassin"
	force = 42
	attack_speed = 1.2
	damtype = RED_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP

	attack_verb_continuous = list("pokes", "jabs", "tears", "lacerates", "gores")
	attack_verb_simple = list("poke", "jab", "tear", "lacerate", "gore")
	hitsound = 'sound/weapons/bladeslice.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 60
							)
	var/ready = TRUE
	var/multiplier = 2


/obj/item/ego_weapon/city/shi_assassin/attack_self(mob/living/carbon/human/user)
	..()
	if(!CanUseEgo(user))
		return

	if(!ready)
		return
	ready = FALSE
	user.Immobilize(17)
	to_chat(user, span_userdanger("Draw."))
	force*=multiplier
	damtype = PALE_DAMAGE
	user.adjustBruteLoss(user.maxHealth*0.25)

	addtimer(CALLBACK(src, PROC_REF(Return), user), 5 SECONDS)

/obj/item/ego_weapon/city/shi_assassin/attack(mob/living/target, mob/living/carbon/human/user)
	..()
	if(force != initial(force))
		to_chat(user, span_userdanger("Boundary of Death."))
		new /obj/effect/temp_visual/BoD(get_turf(target))
		force = initial(force)
	damtype = initial(damtype)

/obj/item/ego_weapon/city/shi_assassin/proc/Return(mob/living/carbon/human/user)
	force = initial(force)
	ready = TRUE
	to_chat(user, span_notice("Your blade is ready."))
	damtype = initial(damtype)

/obj/effect/temp_visual/BoD
	icon_state = "BoD"
	duration = 17 //in deciseconds
	randomdir = FALSE

//Grade 4
/obj/item/ego_weapon/city/shi_assassin/vet
	name = "shi association veteran sheathed blade"
	desc = "A blade that is used by Shi Section 2 veterans. It's extremely sharp."
	icon_state = "shiassassin_vet"
	force = 50
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 60
							)

//Grade 3
/obj/item/ego_weapon/city/shi_assassin/director
	name = "shi association director sheathed blade"
	desc = "A blade that is used by Shi Section 2 directors. It's extremely sharp."
	icon_state = "shiassassin_director"
	force = 63
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 80
							)

//Specialist Shi Blades (I had the sprites.)
/obj/item/ego_weapon/city/shi_assassin/sakura
	name = "shi association sakura blade"
	desc = "A unique specialized assassin blade that is used by Shi Section 2. Created for highly armored targets, this one deals white damage."
	icon_state = "shi_sakura"
	damtype = WHITE_DAMAGE

/obj/item/ego_weapon/city/shi_assassin/serpent
	name = "shi association serpent blade"
	desc = "A unique specialized assassin blade that is used by Shi Section 2. Created for highly armored targets, this one deals black damage."
	icon_state = "shi_serpent"
	damtype = BLACK_DAMAGE

/obj/item/ego_weapon/city/shi_assassin/yokai
	name = "shi association yokai blade"
	desc = "A unique specialized assassin blade that is used by Shi Section 2. Created for highly armored targets, this one deals pale damage."
	special = "Use this weapon in hand to immobilize yourself for 1 second, cut your HP by 25%, and deal 4x damage."
	force = 18
	icon_state = "shi_yokai"
	damtype = PALE_DAMAGE

	multiplier = 4

/*
Shi East Weaponry
They use bowblades!
The bowblade acts as a decent melee weapon, with a large sweep style.
Nock the bowblade with a Shi East Arrow to turn it into a ranged weapon - gain Target Aim stacks to empower your shot.

Firing normally will result in a weak shot.
To empower your shots, you will have to increase your Target Aim.
Target Aim starts at 0 and goes up to 4. You can increase it by landing melee attacks with your bowblade, which will raise it by 1 on each hit to a certain maximum.
You can also assume a stance and hold your breath to increase your Target Aim with do_afters. This impairs your mobility.

An empowered shot will deal more damage and have higher projectile speed based on the amount of Focus.
At 2 Target Aim, your arrow will embed into the target and cause a strong, stackable debuff. They can remove the arrow, but it comes at a cost.
At 4 Target Aim, you will no longer fire a projectile - it turns into a point-and-click mini cutscene instead.

Arrows will never be deleted when used (unless something goes horribly wrong), they'll either embed into their target/fall onto the floor.
*/
#define SHI_EAST_UNLOAD_FIRED_SHOT "unload_fired_shot"
#define SHI_EAST_UNLOAD_MANUAL "unload_manual"
#define SHI_EAST_UNLOAD_FUMBLE "unload_fumble"

/obj/item/ego_weapon/ranged/city/shi_east
	name = "shi association bowblade"
	desc = "A great blade which is also strung with a tense, red bowstring. This is a stealthy hybrid weapon used by the Shi Association's eastern branch, able to puncture distant targets and cleave through nearby ones. \n\
	It feels ominous to look at."
	special = "This weapon functions as a hybrid melee-ranged weapon. When unloaded, use as a common melee weapon. To load this weapon, hit it with a Shi East Arrow. You will be slowed if moving with a loaded arrow. To unload, alt-click. \n\
	After loading, you may fire the weapon. Normal shots will be ineffective - you must gain and stack the \"Target Aim\" status effect to unlock the full potential of this weapon. Do this by using the weapon in-hand with a loaded arrow - melee strikes will also stack it to a lower maximum."

	item_flags = SLOWS_WHILE_IN_HAND // This weapon only has slowdown when loaded.
	weapon_weight = WEAPON_HEAVY
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left_64x64.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right_64x64.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	icon_state = "shi_east"
	inhand_icon_state = "shi_east"

	forced_melee = TRUE

	// Melee
	force = 50
	damtype = RED_DAMAGE
	attack_speed = 1.6
	swingstyle = WEAPONSWING_LARGESWEEP
	var/max_target_aim_stacks_from_melee = 2

	// Ranged
	projectile_path = /obj/projectile/ego_bullet/shi_east_arrow
	fire_sound = 'sound/weapons/gun/rifle/shot_alt.ogg'
	fire_delay = 20
	shotsleft = 0
	reloadtime = 0
	var/ranged_slowdown = 0.6
	var/obj/item/shi_east_arrow/loaded_arrow
	var/hold_breath_cycle_duration = 2.2 SECONDS
	var/hold_breath_active = FALSE
	var/glimmer_ready = FALSE
	var/glimmer_windup = 1 SECONDS
	var/glimmer_travel_time = 0.6 SECONDS

/* -------------------- DESCRIPTION STUFF -------------------- */
/obj/item/ego_weapon/ranged/city/shi_east/examine(mob/user)
	. = ..()
	. += span_notice("<a href='?src=[REF(src)];action=full_examine'>\[View Expanded Description]</a>")

/obj/item/ego_weapon/ranged/city/shi_east/Topic(href, list/href_list)
	. = ..()
	if(.)
		return
	if(href_list["action"] != "full_examine")
		return
	var/mob/user = usr
	if(!QDELETED(user) && istype(user))
		on_examine(user)

/obj/item/ego_weapon/ranged/city/shi_east/proc/on_examine(mob/user)
	if(QDELETED(user) || !istype(user))
		return
	. = list()
	. += span_info("This weapon has two modes: melee, and ranged. They aren't compatible with eachother - load a Shi East Arrow to enable ranged mode, then unload or fire it to enter melee mode again. Unload by alt-clicking.")
	. += span_info("Hitting an enemy in melee while in ranged mode will automatically unload the arrow and swap to melee mode - you will strike the enemy as normal. <br />")

	. += span_info("The arrows used by this weapon are physical objects - as such, your ammo is limited. However, these arrows are not lost when fired - they will fall to the ground or become embedded on impact. Thus, you can recover them.")
	. += span_info("The arrows fired by this weapon may cause status effects on-hit - if so, they will be detailed in those arrows' description. <br />")

	. += span_info("This weapon is able to generate stacks of the <b>Target Aim</b> status effect, up to 4. This status effect empowers the next fired Shi East Arrow.")
	. += span_info("<b>Target Aim</b> has a limited duration, and a maximum of 4 stacks. You may generate it in one of two ways:")
	. += span_info("1. Land melee strikes with this weapon. This can stack Target Aim up to [max_target_aim_stacks_from_melee] stacks.")
	. += span_info("2. Hold your breath. Use the weapon in-hand while an arrow is nocked. This will begin a series of channeled windups, each lasting [hold_breath_cycle_duration * 0.1]s. While holding your breath, you will be <b>pacified</b>. \
	Each finished cycle will give you one Target Aim stack. While holding your breath with 0 or 1 Target Aim stacks, you will be slowed. With any more, moving during these cycles will break your concentration and reset your Target Aim stacks. <br />")

	. += span_info("Each stack of <b>Target Aim</b> will increase projectile velocity and damage for your arrows, as well as <b>unlock special effects</b> on certain thresholds.")
	. += span_info("<b>2 Target Aim:</b> Arrows <b>embed</b> on targets. Embedding causes special effects based on the arrow embedded - read their description for details.")
	. += span_info("<b>4 Target Aim:</b> Your focus heightens, and your shot becomes a certainty. Projectile damage type overridden to PALE, and instead of firing a projectile, you will be <b>guaranteed to land a hit</b> on the next mob you click.")

	for(var/line in .)
		to_chat(user, line)

/* -------------------- LOADING, UNLOADING -------------------- */

/// Nock an arrow by hitting the bow with it; will call LoadArrow().
/obj/item/ego_weapon/ranged/city/shi_east/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	if(!(src in user.held_items)) // Stop people from loading the bow in our inventory. You have to be holding it.
		to_chat(user, span_warning("You must hold [src] to nock an arrow onto it!"))
		return FALSE
	if(istype(I, /obj/item/shi_east_arrow))
		if(loaded_arrow)
			to_chat(user, span_warning("There's already an arrow nocked in [src]!"))
			return FALSE
		return LoadArrow(user, I)

/// Handles the loading of arrows.
/obj/item/ego_weapon/ranged/city/shi_east/proc/LoadArrow(mob/user, obj/item/shi_east_arrow/arrow)
	if(!istype(user) || !istype(arrow))
		return FALSE

	// Set the loaded arrow and allow us to fire it.
	loaded_arrow = arrow
	loaded_arrow.forceMove(src)
	projectile_path = loaded_arrow.projectile_path
	forced_melee = FALSE

	// Slowdown while you've got a loaded bow out.
	slowdown = ranged_slowdown
	user.update_equipment_speed_mods()

	// Aesthetics/Feedback
	icon_state = initial(icon_state) + "_loaded"
	//playsound(get_turf(user), ...)
	to_chat(user, span_notice("You nock [arrow] against the bowstring..."))
	return TRUE

/// Alt-click to manually unload an arrow.
/obj/item/ego_weapon/ranged/city/shi_east/AltClick(mob/user)
	return UnloadArrow(user, SHI_EAST_UNLOAD_MANUAL)

/// Automatically unload the bow if we store it.
/obj/item/ego_weapon/ranged/city/shi_east/equipped(mob/living/user, slot)
	. = ..()
	if((slot != ITEM_SLOT_HANDS) && loaded_arrow)
		UnloadArrow(user, SHI_EAST_UNLOAD_FUMBLE)

/// Called when we need to remove an arrow from the bow; either by firing it, unloading it or accidentally dropping it. Reverses what LoadArrow() does, basically.
/obj/item/ego_weapon/ranged/city/shi_east/proc/UnloadArrow(mob/living/carbon/human/user, unload_type = SHI_EAST_UNLOAD_MANUAL)
	if(!loaded_arrow)
		to_chat(user, span_warning("There is no arrow nocked in [src]!"))
		return FALSE
	if(!istype(user))
		return FALSE

	switch(unload_type)
		if(SHI_EAST_UNLOAD_MANUAL)
			loaded_arrow.forceMove(get_turf(user))
			user.put_in_active_hand(loaded_arrow)
			to_chat(user, span_notice("You remove [loaded_arrow] from the bowstring."))
			//playsound(get_turf(user), ...)
		if(SHI_EAST_UNLOAD_FUMBLE)
			loaded_arrow.forceMove(get_turf(user))
		if(SHI_EAST_UNLOAD_FIRED_SHOT)
			loaded_arrow.moveToNullspace()

	forced_melee = TRUE
	hold_breath_active = FALSE
	slowdown = initial(slowdown)
	user.update_equipment_speed_mods()
	loaded_arrow = null

	icon_state = initial(icon_state)

/* -------------------- COMBAT: HOLD BREATH -------------------- */

/// Begin Hold Breath by using the loaded weapon.
/obj/item/ego_weapon/ranged/city/shi_east/attack_self(mob/user)
	if(!loaded_arrow)
		return
	INVOKE_ASYNC(src, PROC_REF(StartHoldBreath), user) // HoldBreathCycle() sleeps

/// Begin the process of holding breath. hold_breath_active is checked constantly by the do_afters in HoldBreathCycle(), so that's one of our 'escape routes' from the cycle.
/obj/item/ego_weapon/ranged/city/shi_east/proc/StartHoldBreath(mob/living/carbon/human/user)
	if(!istype(user))
		return
	if(hold_breath_active)
		return
	user.visible_message(span_danger("[user] begins holding [user.p_their()] breath! It looks like they're about to loose an arrow!"), span_info("You begin preparing to take the shot."))
	hold_breath_active = TRUE // Won't be able to melee while this is active, btw

	var/datum/status_effect/stacking/shi_east_target_aim/focus = user.has_status_effect(/datum/status_effect/stacking/shi_east_target_aim)
	var/started_with_root = FALSE
	if(focus && focus.stacks >= 2)
		HoldBreathRoot(user)
		started_with_root = TRUE
	HoldBreathCycle(user, started_with_root) // Recursive proc!

/// Recursive proc. Increases Target Aim stacks; if we have 0 or 1, we get a slowdown and we can move while channeling. Once we get our second stack, we get briefly immobilized,
/// then the cycles for the 3rd and 4th stacks require us to be still.
/obj/item/ego_weapon/ranged/city/shi_east/proc/HoldBreathCycle(mob/living/carbon/human/user, already_rooted = FALSE)
	if(!user)
		return

	var/datum/status_effect/stacking/shi_east_target_aim/focus = user.has_status_effect(/datum/status_effect/stacking/shi_east_target_aim)
	if(focus)
		focus.refresh()
	var/user_target_aim_stacks = (focus ? focus.stacks : 0)

	var/do_after_flags = null
	if(user_target_aim_stacks < 2) // When Target Aim stacks are 0 or 1, let us move slowly during the process.
		user.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/shi_east_hold_breath, multiplicative_slowdown = (user_target_aim_stacks + 1) * 0.7)
		do_after_flags = IGNORE_USER_LOC_CHANGE
	else
		user.remove_movespeed_modifier(/datum/movespeed_modifier/shi_east_hold_breath)

	// Here's the actual windup...
	if(do_after(user, hold_breath_cycle_duration, timed_action_flags = do_after_flags, extra_checks = CALLBACK(src, PROC_REF(HoldBreathExtraChecks)), interaction_key = "shi_east_target_aim", max_interact_count = 1))
		// If the do_after succeeds, either apply the new status effect or increase the existing status' stacks by 1.
		if(focus)
			focus.add_stacks(1)
			if((focus.stacks >= 2) && !already_rooted) // Immobilize the user once to stop them from accidentally breaking the cycles. After that, they're free to cancel it voluntarily by moving.
				HoldBreathRoot(user)
				already_rooted = TRUE

		else
			user.apply_status_effect(/datum/status_effect/stacking/shi_east_target_aim)
	else
		// If we fail the do_after, it means we moved after the 2nd stack or swapped hands. Stop the cycles.
		EndHoldBreath(user, FALSE)
		return

	// If we reached max stacks, stop the cycles and immobilize the user until they fire.
	if(focus && focus.stacks >= 4)
		EndHoldBreath(user, TRUE)
		FullDraw(user)
		RegisterSignal(focus, COMSIG_PARENT_QDELETING, PROC_REF(FullDrawExpire))
		return

	// Continue the cycle.
	else if(hold_breath_active)
		HoldBreathCycle(user, already_rooted)

/// Used as a callback in the do_after
/obj/item/ego_weapon/ranged/city/shi_east/proc/HoldBreathExtraChecks()
	return hold_breath_active

/obj/item/ego_weapon/ranged/city/shi_east/proc/HoldBreathRoot(mob/living/user)
	user.Immobilize(0.8 SECONDS)
	SEND_SOUND(user, sound(('sound/abnormalities/armyinblack/black_heartbeat.ogg')))

/obj/item/ego_weapon/ranged/city/shi_east/proc/FullDraw(mob/living/carbon/human/user)
	ADD_TRAIT(user, TRAIT_IMMOBILIZED, "shi_east_full_draw")
	glimmer_ready = TRUE

/obj/item/ego_weapon/ranged/city/shi_east/proc/FullDrawExpire(datum/status_effect/expiring)
	SIGNAL_HANDLER
	glimmer_ready = FALSE
	REMOVE_TRAIT(expiring.owner, TRAIT_IMMOBILIZED, "shi_east_full_draw")

/// Stops the Hold Breath cycles by flipping the hold_breath_active var.
/obj/item/ego_weapon/ranged/city/shi_east/proc/EndHoldBreath(mob/living/carbon/human/user, success = TRUE)
	if(!success)
		user.balloon_alert(user, "Lost concentration. Target Aim reset.")
		user.remove_status_effect(/datum/status_effect/stacking/shi_east_target_aim)
	user.remove_movespeed_modifier(/datum/movespeed_modifier/shi_east_hold_breath)
	hold_breath_active = FALSE

/datum/movespeed_modifier/shi_east_hold_breath
	multiplicative_slowdown = 0
	variable = TRUE

/* -------------------- COMBAT: FIRING THE ARROW -------------------- */

/obj/item/ego_weapon/ranged/city/shi_east/can_trigger_gun(mob/living/user)
	if(loaded_arrow && !glimmer_ready)
		return TRUE
	else
		if(!glimmer_ready)
			to_chat(user, span_warning("You need to nock an arrow to fire this weapon!"))
		return FALSE

/obj/item/ego_weapon/ranged/city/shi_east/fire_projectile(atom/target, mob/living/user, params, distro, quiet, zone_override, spread, atom/fired_from, temporary_damage_multiplier)
	. = ..()
	var/obj/projectile/ego_bullet/shi_east_arrow/fired_arrow_proj = .
	if(!istype(fired_arrow_proj))
		return
	var/target_aim_stacks_used = 0

	var/datum/status_effect/stacking/how_much_target_aim_did_we_fire_with = user.has_status_effect(/datum/status_effect/stacking/shi_east_target_aim)
	if(how_much_target_aim_did_we_fire_with)
		target_aim_stacks_used = how_much_target_aim_did_we_fire_with.stacks

		if(target_aim_stacks_used >= 4) // We shouldn't need this; it's a failsafe
			FullDrawExpire(how_much_target_aim_did_we_fire_with)

		qdel(how_much_target_aim_did_we_fire_with)

	fired_arrow_proj.LinkToArrowItem(loaded_arrow, target_aim_stacks_used)
	UnloadArrow(user, SHI_EAST_UNLOAD_FIRED_SHOT)

/obj/item/ego_weapon/ranged/city/shi_east/afterattack(atom/target, mob/living/user, flag, params)
	. = ..()
	if(!isliving(target))
		return
	if(!glimmer_ready)
		return
	INVOKE_ASYNC(src, PROC_REF(GlimmerAttack), target, user)

/obj/item/ego_weapon/ranged/city/shi_east/proc/GlimmerAttack(mob/living/target, mob/living/carbon/human/user)
	if(!target || !user)
		return
	if(!loaded_arrow)
		to_chat(user, span_warning("There is no arrow nocked in [src]!"))
		return
	if(!do_after(user, glimmer_windup, target, timed_action_flags = IGNORE_TARGET_LOC_CHANGE, interaction_key = "shi_east_glimmer", max_interact_count = 1))
		return
	new /obj/effect/temp_visual/BoD(get_turf(target))
	addtimer(CALLBACK(src, PROC_REF(GlimmerHit), target, user, loaded_arrow), glimmer_travel_time)
	UnloadArrow(user, SHI_EAST_UNLOAD_FIRED_SHOT)
	user.remove_status_effect(/datum/status_effect/stacking/shi_east_target_aim)

/obj/item/ego_weapon/ranged/city/shi_east/proc/GlimmerHit(mob/living/target, mob/living/carbon/human/user, obj/item/shi_east_arrow/arrow)
	if(!target || !user || !arrow)
		return
	target.deal_damage(arrow.damage_per_target_aim[4], PALE_DAMAGE, source = user, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
	if(!(arrow.Embed(user, target, 4)))
		arrow.forceMove(get_turf(target))
	log_combat(user, target, "shot (Bow's Glimmer)", src)

/* -------------------- COMBAT: MELEE -------------------- */

/obj/item/ego_weapon/ranged/city/shi_east/melee_attack_chain(mob/user, atom/target, params)
	if(hold_breath_active)
		return TRUE
	if(loaded_arrow && (reach == 1 ? user.Adjacent(target) : CheckToolReach(user, target, reach)))
		UnloadArrow(user, SHI_EAST_UNLOAD_FUMBLE)
	. = ..()

/obj/item/ego_weapon/ranged/city/shi_east/attack(mob/living/M, mob/living/user)
	var/mob_was_alive = (istype(M) && M.stat < DEAD)
	. = ..()
	if(!.)
		return
	if(!mob_was_alive || (M == user))
		return
	var/datum/status_effect/stacking/shi_east_target_aim/focus = user.has_status_effect(/datum/status_effect/stacking/shi_east_target_aim)
	if(!focus)
		user.apply_status_effect(/datum/status_effect/stacking/shi_east_target_aim)
	else if(focus.stacks < max_target_aim_stacks_from_melee)
		focus.add_stacks(1)
	else
		focus.refresh()


/* -------------------- ARROW ITEM AND PROJECTILE -------------------- */

// Item
/obj/item/shi_east_arrow
	name = "shi east liferender arrow"
	desc = "A bowblade arrow used by the Shi Association's eastern branch. This one is specialized to deal heavy damage to internal organs and cause bleeding."
	icon_state = "skub"
	damtype = RED_DAMAGE
	var/projectile_path = /obj/projectile/ego_bullet/shi_east_arrow

	var/alist/damage_per_target_aim = alist(0 = 44, 1 = 66, 2 = 88, 3 = 100, 4 = 70)
	var/alist/speed_per_target_aim = alist(0 = 1.2, 1 = 1, 2 = 0.7, 3 = 0.3, 4 = 0.2)

	// Unimplemented, but I'm sure you can guess what this is meant to be. Maybe someday? For now, I think it's overkill.
	//var/list/embed_chemicals

	var/alist/embed_organ_damage_per_target_aim = alist(0 = 0, 1 = 0, 2 = 7, 3 = 12, 4 = 18)
	var/embed_organ_damage_simplemob_conversion_coeff = 10
	var/embed_procced_organ_damage = 2

	var/embed_periodic_offense_down = 0
	var/embed_periodic_defense_down = 3
	var/embed_periodic_bleed = 4

	var/removal_delay = 1.3 SECONDS
	var/removal_bleed_stacks = 25
	var/removal_damage = 20

	var/list/current_embed_data = list()

/obj/item/shi_east_arrow/withering
	name = "shi east withering arrow"
	desc = "A bowblade arrow used by the Shi Association's eastern branch. This one is coated with a neurotoxin that saps the target's strength and reflexes, weakening their offensive and defensive capabilities."

	embed_organ_damage_per_target_aim = alist(0 = 0, 1 = 0, 2 = 0, 3 = 2, 4 = 4)
	embed_procced_organ_damage = 0

	embed_periodic_offense_down = 5
	embed_periodic_defense_down = 6
	embed_periodic_bleed = 0

	removal_bleed_stacks = 20
	removal_damage = 10

/// Called by the projectile to embed the arrow item into the victim, applying the status effect.
/obj/item/shi_east_arrow/proc/Embed(mob/living/shi_assassin, mob/living/victim, target_aim_stacks = 2)
	current_embed_data["firer"] = shi_assassin
	current_embed_data["target_aim_stacks_used"] = target_aim_stacks
	var/datum/status_effect/stacking/shi_east_lodged_arrow/already_cooked = victim.has_status_effect(/datum/status_effect/stacking/shi_east_lodged_arrow)
	if(already_cooked)
		return (already_cooked.AddArrow(src))
	else
		return (victim.apply_status_effect(/datum/status_effect/stacking/shi_east_lodged_arrow, 0, src))

/// Called by the status effect once it's time to remove the arrow item from the victim, placing it back into the playfield.
/obj/item/shi_east_arrow/proc/Unembed(destination)
	// Case 1: Destination is null. If the arrow still has data on who fired it, and that person hasn't been deleted, teleport the arrow to them. Otherwise, delete the arrow.
	if(!destination) // I pray this never happens.
		var/mob/living/shi_assassin = current_embed_data["firer"]
		if(!QDELETED(shi_assassin)) // Teleport the arrow to the shooter I guess.
			forceMove(get_turf(shi_assassin))
		else // Both something went terribly wrong with the victim AND the shooter. The arrow is annihilated out of existence.
			qdel(src)

	// Case 2: Destination is a turf. Put the arrow on the turf.
	if(isturf(destination))
		forceMove(destination)

	// Case 3: Destination is a human. Put it in their hands/turf beneath them.
	else if(ishuman(destination))
		var/mob/living/carbon/human/our_guy = destination
		forceMove(get_turf(our_guy))
		our_guy.put_in_active_hand(src)

	// Case 4: Anything else. Put it on the thing's turf.
	else
		var/atom/thingy = destination
		forceMove(get_turf(thingy))

	current_embed_data = list()

/obj/item/shi_east_arrow/proc/EmbedEffect(mob/living/victim)
	if(!istype(victim))
		return
	if(embed_periodic_offense_down > 0)
		victim.apply_lc_offense_level_down(embed_periodic_offense_down)
	if(embed_periodic_defense_down > 0)
		victim.apply_lc_defense_level_down(embed_periodic_offense_down)
	if(embed_periodic_bleed > 0)
		victim.apply_lc_bleed(embed_periodic_bleed)

/obj/item/shi_east_arrow/proc/UnembedEffect(mob/living/victim, brutal = FALSE)
	if(!istype(victim))
		return
	// When I add skills, brutal == TRUE will increase the effects from unembedding.
	victim.apply_lc_bleed(removal_bleed_stacks)
	victim.deal_damage(removal_damage, damtype, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_STATUS))

/obj/item/shi_east_arrow/proc/EmbedMovementProc(mob/living/victim)
	if(!istype(victim))
		return
	if(ishuman(victim) && current_embed_data["target_organ"])
		var/mob/living/carbon/human/human_victim = victim
		var/list/valid_organs = human_victim.getorganslot(current_embed_data["target_organ"])
		if(!length(valid_organs))
			return
		var/obj/item/organ/unfortunate_organ = pick(valid_organs)
		unfortunate_organ.applyOrganDamage(embed_procced_organ_damage)
	else if(isanimal(victim))
		victim.deal_damage(embed_procced_organ_damage * embed_organ_damage_simplemob_conversion_coeff, BRUTE, source = current_embed_data["firer"], flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_STATUS))

/obj/item/shi_east_arrow/proc/EmbedPeriodicProc(mob/living/victim)
	if(!istype(victim))
		return


// Projectile
/obj/projectile/ego_bullet/shi_east_arrow
	icon_state = "arrow"
	damage = 44
	speed = 1.2
	var/obj/item/shi_east_arrow/linked_arrow_item
	var/target_aim_stacks = 0

/obj/projectile/ego_bullet/shi_east_arrow/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_PARENT_QDELETING, PROC_REF(DropArrowItem))

/obj/projectile/ego_bullet/shi_east_arrow/proc/LinkToArrowItem(obj/item/shi_east_arrow/arrow_item, used_target_aim_stacks = 0)
	if(!istype(arrow_item))
		CRASH("Shi East Arrow projectile attempted to be linked with an invalid item.")

	linked_arrow_item = arrow_item
	name = arrow_item.name

	target_aim_stacks = used_target_aim_stacks
	speed = linked_arrow_item.speed_per_target_aim[target_aim_stacks]
	damage = linked_arrow_item.damage_per_target_aim[target_aim_stacks]
	damage_type = (target_aim_stacks >= 4) ? PALE_DAMAGE : linked_arrow_item.damtype

/obj/projectile/ego_bullet/shi_east_arrow/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	if(target_aim_stacks >= 2)
		linked_arrow_item.Embed(firer, target, target_aim_stacks)

/obj/projectile/ego_bullet/shi_east_arrow/proc/DropArrowItem()
	SIGNAL_HANDLER
	if(linked_arrow_item && !length(linked_arrow_item.current_embed_data))
		linked_arrow_item.forceMove(get_turf(src))
	linked_arrow_item = null


/* -------------------- TARGET AIM BUFF -------------------- */
/datum/status_effect/stacking/shi_east_target_aim
	id = "shi_east_target_aim"
	status_type = STATUS_EFFECT_REFRESH
	duration = 4 SECONDS
	tick_interval = 10 SECONDS
	max_stacks = 4
	stacks = 1
	stack_decay = 0
	consumed_on_threshold = FALSE
	alert_type = /atom/movable/screen/alert/status_effect/shi_east_target_aim
	stacking_display_name = "poise"

/datum/status_effect/stacking/shi_east_target_aim/add_stacks(stacks_added)
	. = ..()
	if(!owner || !linked_alert)
		return
	refresh()
	linked_alert.desc = initial(linked_alert.desc) + " [stacks]/4 stacks."
	var/message
	switch(stacks)
		if(1)
			message = "1/4 - Sight and confirm the target..."
			to_chat(owner, span_info(message))
		if(2)
			message = "2/4 - Account for wind speed and direction..."
			to_chat(owner, span_info(message))
		if(3)
			message = "3/4 - Hold your breath."
			to_chat(owner, span_info(message))
		if(4)
			message = "<b>死 - Full draw.</b>"
			to_chat(owner, span_nicegreen(message))

	owner.balloon_alert(owner, message)

/atom/movable/screen/alert/status_effect/shi_east_target_aim
	name = "Target Aim"
	desc = "Your next fired Shi East Arrow is empowered."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "poise"

/* -------------------- LODGED ARROW DEBUFF -------------------- */
/datum/status_effect/stacking/shi_east_lodged_arrow
	id = "shi_east_lodged_arrow"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	tick_interval = 51
	max_stacks = 4
	stacks = 1
	stack_decay = 0
	consumed_on_threshold = FALSE
	alert_type = /atom/movable/screen/alert/status_effect/shi_east_lodged_arrow
	stacking_display_name = "concentration"
	var/list/lodged_arrows = list()
	var/duration_on_simplemobs = 20 SECONDS
	var/list/permitted_organ_targets = list(
		ORGAN_SLOT_HEART,
		ORGAN_SLOT_LUNGS,
		ORGAN_SLOT_LIVER,
		ORGAN_SLOT_STOMACH,
		ORGAN_SLOT_APPENDIX,
		)

/datum/status_effect/stacking/shi_east_lodged_arrow/on_creation(mob/living/new_owner, stacks_to_apply, obj/item/shi_east_arrow/source_arrow)
	if(!istype(new_owner) || !istype(source_arrow))
		return FALSE
	owner = new_owner
	. = ..()
	if(!.)
		return FALSE
	AddArrow(source_arrow)
	RegisterSignal(owner, COMSIG_PARENT_EXAMINE, PROC_REF(WhenOwnerExamined))

/datum/status_effect/stacking/shi_east_lodged_arrow/on_apply()
	. = ..()
	if(!owner)
		return FALSE
	RegisterSignal(owner, COMSIG_PARENT_QDELETING, PROC_REF(DropAllArrows))
	return TRUE

/datum/status_effect/stacking/shi_east_lodged_arrow/on_remove()
	. = ..()
	UnregisterSignal(owner, list(COMSIG_PARENT_QDELETING, COMSIG_PARENT_EXAMINE))

/datum/status_effect/stacking/shi_east_lodged_arrow/tick()
	if(!can_have_status())
		qdel(src)
	else
		for(var/arrow in lodged_arrows) // No need to do an implicit istype here, we're pretty sure these are arrows
			var/obj/item/shi_east_arrow/cool_arrow = arrow
			cool_arrow.EmbedPeriodicProc(owner)

/datum/status_effect/stacking/shi_east_lodged_arrow/proc/AddArrow(obj/item/shi_east_arrow/embedding_arrow)
	if(!istype(embedding_arrow))
		return
	if((stacks + 1) >= max_stacks)
		embedding_arrow.forceMove(get_turf(owner))
		return
	lodged_arrows |= embedding_arrow
	stacks = length(lodged_arrows)
	update_stacking_number()

	var/target_aim_stacks_used = embedding_arrow.current_embed_data["target_aim_stacks_used"]
	// For animals, remove the arrow on a timer.
	if(istype(owner, /mob/living/simple_animal))
		addtimer(CALLBACK(src, PROC_REF(RemoveArrow), owner), duration_on_simplemobs)
		owner.deal_damage((embedding_arrow.embed_organ_damage_per_target_aim[target_aim_stacks_used] * embedding_arrow.embed_organ_damage_simplemob_conversion_coeff), BRUTE, source = embedding_arrow.current_embed_data["firer"], flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_RANGED))
	else if(istype(owner, /mob/living/carbon/human))
		// Tell the arrow what organ slot it should deal its damage to
		var/mob/living/carbon/human/human_owner = owner
		var/targeted_organ_slot = pick(permitted_organ_targets)
		embedding_arrow.current_embed_data["target_organ"] = targeted_organ_slot

		// Deal the initial burst of organ damage from the embed
		var/list/valid_organs = human_owner.getorganslot(targeted_organ_slot)
		var/obj/item/organ/unfortunate_organ = pick(valid_organs)
		unfortunate_organ.applyOrganDamage(embedding_arrow.embed_organ_damage_per_target_aim[target_aim_stacks_used])
	return TRUE

/datum/status_effect/stacking/shi_east_lodged_arrow/proc/RemoveArrow(mob/living/removing, brutal = FALSE)
	if(EmptyCheck())
		return
	var/obj/item/shi_east_arrow/arrow = pick(lodged_arrows)
	arrow.UnembedEffect(owner, brutal)
	arrow.Unembed(removing)
	lodged_arrows -= arrow
	add_stacks(-1)
	EmptyCheck()

/datum/status_effect/stacking/shi_east_lodged_arrow/proc/DropAllArrows()
	var/turf/owner_turf = (!QDELETED(owner) ? get_turf(owner) : null)
	for(var/obj/item/shi_east_arrow/arrow in lodged_arrows)
		arrow.Unembed(owner_turf)
		lodged_arrows -= arrow
		add_stacks(-1)
	EmptyCheck()

/datum/status_effect/stacking/shi_east_lodged_arrow/proc/EmptyCheck()
	if(!length(lodged_arrows))
		qdel(src)
		return TRUE
	return FALSE

/datum/status_effect/stacking/shi_east_lodged_arrow/proc/WhenOwnerExamined(mob/living/our_owner, mob/examiner, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("There's [stacks] arrow(s) stuck in [our_owner.p_them()]. <a href='?src=[REF(src)];action=remove_arrow'>\[Remove Arrow (HARMFUL)]</a>")

/datum/status_effect/stacking/shi_east_lodged_arrow/proc/AttemptManualRemoval(mob/living/remover)
	if(!QDELETED(remover) && istype(remover) && remover.Adjacent(owner))
		var/message = (remover == owner) ? "[remover] begins pulling an arrow out from [remover.p_their()] own chest...!" : "[remover] begins pulling an arrow out from [owner]'s chest...!"
		remover.visible_message(span_danger(message))
		if(do_after(remover, 1.4 SECONDS, owner))
			RemoveArrow(remover)

/datum/status_effect/stacking/shi_east_lodged_arrow/Topic(href, list/href_list)
	. = ..()
	if(.)
		return
	if(href_list["action"] != "remove_arrow")
		return
	var/mob/user = usr
	AttemptManualRemoval(user)

/atom/movable/screen/alert/status_effect/shi_east_lodged_arrow
	name = "Lodged Arrow"
	desc = "A large arrow is stuck in your chest! Click this alert to begin removing it (will cause damage)."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "concentration"

/atom/movable/screen/alert/status_effect/shi_east_lodged_arrow/Click(location, control, params)
	. = ..()
	var/mob/living/L = usr
	if(!istype(L) || L != owner)
		return
	var/datum/status_effect/stacking/shi_east_lodged_arrow/the_status = attached_effect
	if(!istype(the_status))
		return
	L.changeNext_move(CLICK_CD_RAPID)
	return the_status.AttemptManualRemoval(L)


#undef SHI_EAST_UNLOAD_FIRED_SHOT
#undef SHI_EAST_UNLOAD_MANUAL
#undef SHI_EAST_UNLOAD_FUMBLE
