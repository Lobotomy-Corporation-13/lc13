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

// This box & storage component are spawned for Roamer Shi East Fixers as their 'weapon'.
/obj/item/storage/box/shi_east_kit
	name = "shi east assassin's bowblade kit"
	desc = "A small box using P Corp's singularity to house a Shi Association fixer's most essential gear. Contents will <b>not</b> be able to be re-inserted once removed."
	w_class = WEIGHT_CLASS_BULKY
	component_type = /datum/component/storage/concrete/shi_east_kit

/obj/item/storage/box/shi_east_kit/PopulateContents()
	new /obj/item/ego_weapon/ranged/city/shi_east(src)
	new /obj/item/storage/belt/shi_east_quiver(src)
	for(var/i = 1 to 2)
		new /obj/item/shi_east_arrow(src)
	for(var/i = 1 to 2)
		new /obj/item/shi_east_arrow/withering(src)

/datum/component/storage/concrete/shi_east_kit
	can_hold = list(
		/obj/item/ego_weapon/ranged/city/shi_east = TRUE,
		/obj/item/storage/belt/shi_east_quiver = TRUE,
		/obj/item/shi_east_arrow = TRUE,
		)

/obj/item/storage/box/shi_east_kit/facility
	name = "surplus shi east bowblade kit"

/obj/item/storage/box/shi_east_kit/facility/PopulateContents()
	new /obj/item/ego_weapon/ranged/city/shi_east(src)
	new /obj/item/storage/belt/shi_east_quiver(src)
	for(var/i = 1 to 4)
		new /obj/item/shi_east_arrow/facility(src)

#define SHI_EAST_UNLOAD_FIRED_SHOT "unload_fired_shot"
#define SHI_EAST_UNLOAD_MANUAL "unload_manual"
#define SHI_EAST_UNLOAD_FUMBLE "unload_fumble"
#define SHI_EAST_UNLOAD_MELEE "unload_melee"

/obj/item/ego_weapon/ranged/city/shi_east
	name = "shi association bowblade"
	desc = "A great blade which is also strung with a tense, red bowstring. This is a stealthy hybrid weapon used by the Shi Association's eastern branch, able to puncture distant targets and cleave through nearby ones. \n\
	It feels ominous to look at."
	special = "This weapon functions as a hybrid melee-ranged weapon. When unloaded, use as a common melee weapon. To load this weapon, hit it with a Shi East Arrow. You will be slowed if moving with a loaded arrow. To unload, alt-click. \n\
	After loading, you may fire the weapon. Normal shots will be ineffective - you must gain and stack the \"Target Aim\" status effect to unlock the full potential of this weapon. Do this by using the weapon in-hand with a loaded arrow - melee strikes will also stack it to a lower maximum."

	lefthand_file = 'ModularLobotomy/_Lobotomyicons/shi_east_held_left_64x64.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/shi_east_held_right_64x64.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	icon = 'ModularLobotomy/_Lobotomyicons/shi_east_obj.dmi'
	icon_state = "shi_east_bowblade"
	inhand_icon_state = "shi_east_bowblade"
	hitsound = 'sound/weapons/ego/shi_east_melee_hit.ogg'
	forced_melee = TRUE
	item_flags = SLOWS_WHILE_IN_HAND // This weapon only has slowdown when loaded.
	weapon_weight = WEAPON_HEAVY

	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 80
							)
	// Melee
	force = 50
	damtype = RED_DAMAGE
	attack_speed = 1.6
	swingstyle = WEAPONSWING_LARGESWEEP
	attack_verb_continuous = list("tears", "lacerates", "gores", "carves", "slices", "eviscerates", "bisects")
	attack_verb_simple = list("tear", "lacerate", "gore", "carve", "slice", "eviscerate", "bisect")

	var/max_target_aim_stacks_from_melee = 2

	// Ranged
	projectile_path = /obj/projectile/ego_bullet/shi_east_arrow
	fire_sound = 'sound/weapons/ego/shi_east_arrow_fire.ogg'

	// The weapon has unconventional loading and firing mechanics, so ignore these vars...
	fire_delay = 20
	shotsleft = 0
	reloadtime = 0
	// It has a scope!
	zoomable = TRUE
	zoom_amt = 6
	zoom_out_amt = 0
	/// Slowdown applied to the user when carrying this weapon with a nocked arrow.
	var/ranged_slowdown = 0.5
	/// Reference to the currently nocked arrow.
	var/obj/item/shi_east_arrow/loaded_arrow
	/// Each Hold Breath cycle (+1 target aim stack) requires a do_after of this length.
	var/hold_breath_cycle_duration = 1.8 SECONDS
	/// TRUE while we're using Hold Breath, helps us stop the user from doing weird stuff while doing it
	var/hold_breath_active = FALSE
	/// TRUE when our next shot should be Bow's Glimmer, helps us prevent unintentional outcomes
	var/glimmer_ready = FALSE
	/// Base amount of time we give people to escape Bow's Glimmer, regardless of distance (you can basically only react by smokebombing)
	var/glimmer_windup_base = 0.8 SECONDS
	/// Past this range, we add extra time to the windup per tile over this threshold
	var/glimmer_windup_range_threshold = 7
	var/glimmer_windup_extra_per_tile = 0.2 SECONDS
	var/glimmer_travel_time = 1 SECONDS
	var/obj/effect/temp_visual/target_field/glimmer_telegraph_vfx

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
	. += span_info("Hitting an enemy in melee while in ranged mode will automatically unload the arrow and swap to melee mode - you will strike the enemy as normal. <br /><br />")

	. += span_info("The arrows used by this weapon are physical objects - as such, your ammo is limited. However, these arrows are not lost when fired - they will fall to the ground or become embedded on impact. Thus, you can recover them.")
	. += span_info("The arrows fired by this weapon may cause status effects on-hit - if so, they will be detailed in those arrows' description. <br /><br />")

	. += span_info("This weapon is able to generate stacks of the <b>Target Aim</b> status effect, up to 4. This status effect empowers the next fired Shi East Arrow.")
	. += span_info("<b>Target Aim</b> has a limited duration, and a maximum of 4 stacks. You may generate it in one of two ways:")
	. += span_info("1. Land melee strikes with this weapon. This can stack Target Aim up to [max_target_aim_stacks_from_melee] stacks.")
	. += span_info("2. Hold your breath. Use the weapon in-hand while an arrow is nocked. This will begin a series of channeled windups, each lasting [hold_breath_cycle_duration * 0.1]s. While holding your breath, you will be <b>pacified</b>. \
	Each finished cycle will give you one Target Aim stack. While holding your breath with 0 or 1 Target Aim stacks, you will be slowed. With any more, moving during these cycles will break your concentration and reset your Target Aim stacks. <br /><br />")

	. += span_info("Each stack of <b>Target Aim</b> will increase projectile velocity and damage for your arrows, as well as <b>unlock special effects</b> on certain thresholds.")
	. += span_info("<b>2 Target Aim:</b> Arrows <b>embed</b> on targets. Embedding causes special effects based on the arrow embedded - read their description for details. Examine victims who have lodged arrows to pull them out.")
	. += span_info("<b>4 Target Aim:</b> Your focus heightens, and your shot becomes a certainty. Projectile damage type overridden to PALE, and instead of firing a projectile, you will be <b>guaranteed to land a hit</b> on the next mob you click.")

	for(var/line in .)
		to_chat(user, line)

/* -------------------- LOADING, UNLOADING -------------------- */

/// Nock an arrow by hitting the bow with it; will call LoadArrow().
/obj/item/ego_weapon/ranged/city/shi_east/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	if(!istype(I, /obj/item/shi_east_arrow))
		return FALSE
	if(!CanUseEgo(user))
		return FALSE
	if(!(src in user.held_items)) // Stop people from loading the bow in our inventory. You have to be holding it.
		to_chat(user, span_warning("You must hold [src] to nock an arrow onto it!"))
		return FALSE
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
	playsound(get_turf(user), 'sound/weapons/ego/shi_east_arrow_nock.ogg', 100, FALSE)
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
			playsound(get_turf(user), 'sound/weapons/magout.ogg', 100, FALSE)
		if(SHI_EAST_UNLOAD_FUMBLE)
			loaded_arrow.forceMove(get_turf(user))
		if(SHI_EAST_UNLOAD_MELEE)
			loaded_arrow.forceMove(get_turf(user))
			user.put_in_inactive_hand(loaded_arrow)
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
		to_chat(user, span_warning("You need to nock an arrow to begin holding your breath!"))
		return
	INVOKE_ASYNC(src, PROC_REF(StartHoldBreath), user) // HoldBreathCycle() sleeps

/// Begin the process of holding breath. hold_breath_active is checked constantly by the do_afters in HoldBreathCycle(), so that's one of our 'escape routes' from the cycle.
/obj/item/ego_weapon/ranged/city/shi_east/proc/StartHoldBreath(mob/living/carbon/human/user)
	if(!istype(user))
		return
	if(hold_breath_active || glimmer_ready)
		return
	if(!CanUseEgo(user))
		return FALSE
	user.visible_message(span_danger("[user] begins holding [user.p_their()] breath! It looks like they're about to loose an arrow!"), span_info("You begin preparing to take the shot."))
	playsound(get_turf(user), 'sound/weapons/ego/shi_east_holdbreath_start.ogg', 100, FALSE)
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
		user.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/shi_east_hold_breath, multiplicative_slowdown = (user_target_aim_stacks + 1) * 0.5)
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
			user.apply_status_effect(/datum/status_effect/stacking/shi_east_target_aim, 1)
	else
		// If we fail the do_after, it means we moved after the 2nd stack or swapped hands. Stop the cycles.
		EndHoldBreath(user, FALSE)
		return

	// If we reached max stacks, stop the cycles and immobilize the user until they fire.
	if(focus && focus.stacks >= 4 && !glimmer_ready)
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

/// Called to briefly stop and warn the user that any further movement will break focus.
/obj/item/ego_weapon/ranged/city/shi_east/proc/HoldBreathRoot(mob/living/user)
	user.Immobilize(0.5 SECONDS)
	SEND_SOUND(user, sound(('sound/abnormalities/armyinblack/black_heartbeat.ogg')))
	playsound(get_turf(user), 'sound/weapons/ego/shi_east_root.ogg', 100, FALSE)

/// Enables Bow's Glimmer. You can't move until you use your Target Aim or it falls off.
/obj/item/ego_weapon/ranged/city/shi_east/proc/FullDraw(mob/living/carbon/human/user)
	ADD_TRAIT(user, TRAIT_IMMOBILIZED, "shi_east_full_draw")
	glimmer_ready = TRUE
	playsound(get_turf(user), 'sound/weapons/ego/shi_east_holdbreath_fulldraw.ogg', 100, FALSE)

/// Disables Bow's Glimmer.
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

/// Stop the user from firing the weapon if they don't have an arrow. Also stop them from firing if Bow's Glimmer is ready - it's handled in afterattack()
/obj/item/ego_weapon/ranged/city/shi_east/can_trigger_gun(mob/living/user)
	if(loaded_arrow && !glimmer_ready)
		return TRUE
	else
		if(!glimmer_ready)
			to_chat(user, span_warning("You need to nock an arrow to fire this weapon!"))
		return FALSE

/// We need to pass our fired projectiles some information.
/obj/item/ego_weapon/ranged/city/shi_east/ProjectileAdjustment(obj/projectile/proj, turf/targloc, atom/target, mob/living/user)
	. = ..()
	var/obj/projectile/ego_bullet/shi_east_arrow/fired_arrow_proj = proj
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
	return fired_arrow_proj

/// Used to trigger Bow's Glimmer.
/obj/item/ego_weapon/ranged/city/shi_east/afterattack(atom/target, mob/living/user, flag, params)
	. = ..()
	if(!isliving(target))
		return
	if(target == user)
		return
	if(!glimmer_ready)
		return
	if(!CanUseEgo(user))
		return FALSE
	INVOKE_ASYNC(src, PROC_REF(GlimmerAttack), target, user)

/obj/item/ego_weapon/ranged/city/shi_east/proc/GlimmerAttack(mob/living/target, mob/living/carbon/human/user)
	if(!istype(target) || !user)
		return
	if(glimmer_telegraph_vfx)
		return
	if(!loaded_arrow)
		to_chat(user, span_warning("There is no arrow nocked in [src]!"))
		return

	// Figure out how long we should wait.
	var/distance = get_dist(user, target)
	var/distance_based_windup = 0
	if(distance > glimmer_windup_range_threshold)
		distance_based_windup = (distance - glimmer_windup_range_threshold) * glimmer_windup_extra_per_tile
	var/glimmer_windup = glimmer_windup_base + distance_based_windup

	// Telegraph, and do a do_after to see if we can successfully hit the target.
	GlimmerTelegraph(target, glimmer_windup)
	if(!do_after(user, glimmer_windup, target, timed_action_flags = IGNORE_TARGET_LOC_CHANGE, interaction_key = "shi_east_glimmer", max_interact_count = 1))
		CleanupGlimmerTelegraph()
		return

	// If we reach here, the shot was a success.
	CleanupGlimmerTelegraph()
	playsound(get_turf(user), 'sound/weapons/ego/shi_east_arrow_fire.ogg', 100, FALSE)

	// Show the Glimmer VFX overlay
	var/image/cool_overlay = image('ModularLobotomy/_Lobotomyicons/shi_east_effects_64x64.dmi', loc = target, icon_state = "glimmer", layer = FLY_LAYER)

	var/icon/target_icon = icon(target.icon, target.icon_state, target.dir)
	var/icon_height = target_icon.Height()
	var/icon_width = target_icon.Width()
	var/height_diff = 64 - icon_height
	var/width_diff = 64 - icon_width

	cool_overlay.pixel_x -= (width_diff * 0.5)
	cool_overlay.pixel_y -= (height_diff * 0.5)

	// Sloppy re-implementation of flick_overlay_view because it doesn't show it to people further than the world's view range (so, if you're scoped in and far, you won't see the overlay)
	var/list/viewing = list()
	for(var/turf/T in RANGE_TURFS(20, target))
		for(var/mob/M in T)
			if(M.client)
				viewing += M.client
	flick_overlay(cool_overlay, viewing, 2 SECONDS)

	// Set up the actual hit...
	var/angle = Get_Angle(target, user)
	addtimer(CALLBACK(src, PROC_REF(GlimmerHit), target, user, loaded_arrow, angle), glimmer_travel_time)

	// Clean up.
	UnloadArrow(user, SHI_EAST_UNLOAD_FIRED_SHOT)
	user.remove_status_effect(/datum/status_effect/stacking/shi_east_target_aim)

/obj/item/ego_weapon/ranged/city/shi_east/proc/GlimmerHit(mob/living/target, mob/living/carbon/human/user, obj/item/shi_east_arrow/arrow, angle)
	if(!istype(target) || !user || !arrow)
		return

	var/obj/effect/shi_east_glimmer_arrow/shi_east_glimmer_arrow = new(target.loc)
	shi_east_glimmer_arrow.pixel_x = sin(angle) * 32 * 9
	shi_east_glimmer_arrow.pixel_y = cos(angle) * 32 * 9
	var/rotation = Get_Pixel_Angle(shi_east_glimmer_arrow.pixel_y, shi_east_glimmer_arrow.pixel_x)
	shi_east_glimmer_arrow.transform = matrix().Turn(rotation)
	shi_east_glimmer_arrow.add_filter("motionblur",1,list("type"="motion_blur", "x"=0, "y"=3))
	animate(shi_east_glimmer_arrow, pixel_y = 0, pixel_x = 0, time = 0.2 SECONDS, flags = ANIMATION_PARALLEL)
	QDEL_IN(shi_east_glimmer_arrow, 0.2 SECONDS)

	target.deal_damage(arrow.damage_per_target_aim[4], PALE_DAMAGE, source = user, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
	playsound(get_turf(target), 'sound/weapons/ego/shi_east_glimmer_hit.ogg', 100, FALSE)
	if(!(arrow.Embed(user, target, 4, Get_Angle(user, target))))
		arrow.forceMove(get_turf(target))
	log_combat(user, target, "shot (Bow's Glimmer)", src)
	to_chat(target, span_userdanger("You're hit by a [arrow.name]!"))

/obj/item/ego_weapon/ranged/city/shi_east/proc/GlimmerTelegraph(mob/living/target, time = 0.8 SECONDS)
	if(!target)
		return
	var/turf/T = get_turf(target)
	glimmer_telegraph_vfx = new /obj/effect/temp_visual/target_field(T)
	glimmer_telegraph_vfx.orbit(target, 0)
	playsound(T, 'sound/abnormalities/crumbling/warning.ogg', 50, FALSE, -3)
	to_chat(target, span_warning("A chill runs down your spine."))
	var/atom/markvfx = new /obj/effect/temp_visual/markedfordeath(T)
	markvfx.pixel_y += 16
	addtimer(CALLBACK(src, PROC_REF(CleanupGlimmerTelegraph)), time)

/obj/item/ego_weapon/ranged/city/shi_east/proc/CleanupGlimmerTelegraph()
	QDEL_NULL(glimmer_telegraph_vfx)

/obj/effect/shi_east_glimmer_arrow
	name = "shi east glimmering arrow"
	icon = 'ModularLobotomy/_Lobotomyicons/shi_east_obj.dmi'
	icon_state = "shi_east_arrow_proj"
	anchored = TRUE
	layer = ABOVE_ALL_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/* -------------------- COMBAT: MELEE -------------------- */

/obj/item/ego_weapon/ranged/city/shi_east/melee_attack_chain(mob/user, atom/target, params)
	if(hold_breath_active)
		return TRUE
	if(glimmer_ready)
		if(user.Adjacent(target) && isliving(target))
			INVOKE_ASYNC(src, PROC_REF(GlimmerAttack), target, user)
		return TRUE

	if(loaded_arrow && (reach == 1 ? user.Adjacent(target) : CheckToolReach(user, target, reach)))
		UnloadArrow(user, SHI_EAST_UNLOAD_MELEE)
	. = ..()

/obj/item/ego_weapon/ranged/city/shi_east/attack(mob/living/M, mob/living/user)
	var/mob_was_alive = (istype(M) && M.stat < DEAD)
	. = ..()
	if(!.)
		return
	if(!mob_was_alive || (M == user) || (istype(M) && M.status_flags & GODMODE))
		return
	var/datum/status_effect/stacking/shi_east_target_aim/focus = user.has_status_effect(/datum/status_effect/stacking/shi_east_target_aim)
	if(!focus)
		user.apply_status_effect(/datum/status_effect/stacking/shi_east_target_aim, 1)
	else if(focus.stacks < max_target_aim_stacks_from_melee)
		focus.add_stacks(1)
	else
		focus.refresh()

/* -------------------- QUIVER -------------------- */
/obj/item/storage/belt/shi_east_quiver
	name = "shi east quiver"
	desc = "Able to hold up to 死 bowblade arrows. Don't lose them!"
	icon = 'ModularLobotomy/_Lobotomyicons/shi_east_obj.dmi'
	icon_state = "shi_east_quiver_empty"
	inhand_icon_state = null
	worn_icon = 'ModularLobotomy/_Lobotomyicons/shi_east_worn.dmi'
	worn_icon_state = "shi_east_quiver_empty"
	attack_verb_continuous = list("bonks", "taps")
	attack_verb_simple = list("bonk", "tap")
	equip_sound = 'sound/items/equip/toolbelt_equip.ogg'
	w_class = WEIGHT_CLASS_BULKY

/obj/item/storage/belt/shi_east_quiver/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_BULKY
	STR.max_combined_w_class = 16
	STR.set_holdable(list(
		/obj/item/shi_east_arrow
		))

/obj/item/storage/belt/shi_east_quiver/update_icon()
	if(!length(contents))
		icon_state = initial(icon_state)
		worn_icon_state = icon_state
	else
		icon_state = "shi_east_quiver_loaded"
		worn_icon_state = icon_state
	if(isliving(src.loc))
		var/mob/living/M = src.loc
		M.regenerate_icons()
	. = ..()

/* -------------------- ARROW ITEM AND PROJECTILE -------------------- */

// Item
/obj/item/shi_east_arrow
	name = "shi east liferender arrow"
	desc = "A bowblade arrow used by the Shi Association's eastern branch. This one is specialized to deal heavy damage to internal organs and cause bleeding."
	icon = 'ModularLobotomy/_Lobotomyicons/shi_east_obj.dmi'
	icon_state = "shi_east_arrow_liferender"
	damtype = RED_DAMAGE
	w_class = WEIGHT_CLASS_BULKY
	force = 20
	resistance_flags = INDESTRUCTIBLE

	var/projectile_path = /obj/projectile/ego_bullet/shi_east_arrow
	var/mutable_appearance/embedded_overlay

	var/alist/damage_per_target_aim = alist(0 = 44, 1 = 66, 2 = 88, 3 = 100, 4 = 70)
	var/alist/speed_per_target_aim = alist(0 = 1.2, 1 = 1, 2 = 0.7, 3 = 0.3, 4 = 0.2)

	// Unimplemented, but I'm sure you can guess what this is meant to be. Maybe someday? For now, I think it's overkill.
	//var/list/embed_chemicals

	var/alist/embed_organ_damage_per_target_aim = alist(0 = 0, 1 = 0, 2 = 9, 3 = 16, 4 = 22)
	var/embed_organ_damage_simplemob_conversion_coeff = 11
	var/embed_procced_organ_damage = 3
	var/list/permitted_organ_targets = list(
		ORGAN_SLOT_HEART,
		ORGAN_SLOT_LUNGS,
		ORGAN_SLOT_LIVER,
		ORGAN_SLOT_STOMACH,
		)

	var/embed_offense_level_down = 0
	var/embed_defense_level_down = 3
	var/embed_bleed = 4

	var/removal_delay = 2.5 SECONDS
	var/removal_bleed_stacks = 25
	var/removal_damage = 20
	var/removal_brutal_multiplier = 3

	var/list/current_embed_data = list()

/obj/item/shi_east_arrow/withering
	name = "shi east withering arrow"
	desc = "A bowblade arrow used by the Shi Association's eastern branch. This one is coated with a neurotoxin that saps the target's strength and reflexes, weakening their offensive and defensive capabilities."
	icon_state = "shi_east_arrow_withering"
	force = 17

	embed_organ_damage_per_target_aim = alist(0 = 0, 1 = 0, 2 = 4, 3 = 9, 4 = 13)
	embed_procced_organ_damage = 1

	embed_offense_level_down = 5
	embed_defense_level_down = 7
	embed_bleed = 0

	removal_bleed_stacks = 20
	removal_damage = 15

/obj/item/shi_east_arrow/facility
	name = "shi east training arrow"
	desc = "A bowblade arrow used by Shi Association trainees learning how to use a bowblade. This one has seen its fair share of use. Try to take better care of it than its previous owners."

	damage_per_target_aim = alist(0 = 44, 1 = 66, 2 = 88, 3 = 100, 4 = 70)
	embed_organ_damage_per_target_aim = alist(0 = 0, 1 = 0, 2 = 10, 3 = 14, 4 = 21)
	embed_procced_organ_damage = 3
	embed_organ_damage_simplemob_conversion_coeff = 16

	embed_offense_level_down = 2
	embed_defense_level_down = 3
	embed_bleed = 0

	removal_bleed_stacks = 0
	removal_damage = 50

/obj/item/shi_east_arrow/equipped(mob/user, slot, initial)
	. = ..()
	transform = initial(transform)
	pixel_x = 0
	pixel_y = 0

/obj/item/shi_east_arrow/examine(mob/user)
	. = ..()
	. += span_info("This arrow's base damage type is [uppertext(damtype)], and is converted to PALE on 4 Target Aim stacks.")
	. += span_info("This arrow deals [damage_per_target_aim[0]]/[damage_per_target_aim[1]]/[damage_per_target_aim[2]]/[damage_per_target_aim[3]]/[damage_per_target_aim[4]] damage on hit, based on 0/1/2/3/4 Target Aim stacks.<br />")
	. += span_info("For non-human victims, embedded arrows will fall out after 20 seconds. For human victims, they will remain until removed. Arrows can be manually removed by clicking a link shown when examining a victim, or by the victim clicking an alert.")
	. += span_info("When a victim moves with an embedded arrow, they will cause additional effects to be inflicted every 4 steps. Every time this procs, it will go on a 1.2s cooldown, during which steps will not be counted.<br />")
	. += span_info("<b>Embed Initial Organ Damage (Humans):</b> [embed_organ_damage_per_target_aim[2]]/[embed_organ_damage_per_target_aim[3]]/[embed_organ_damage_per_target_aim[4]] based on 2/3/4 Target Aim stacks.")
	. += span_info("<b>Embed Initial Brute Damage (Non-Humans):</b> [embed_organ_damage_per_target_aim[2] * embed_organ_damage_simplemob_conversion_coeff]/[embed_organ_damage_per_target_aim[3] * embed_organ_damage_simplemob_conversion_coeff]/[embed_organ_damage_per_target_aim[4] * embed_organ_damage_simplemob_conversion_coeff] based on 2/3/4 Target Aim stacks.")
	. += span_info("<b>Embed Offense Level Down:</b> [embed_offense_level_down]")
	. += span_info("<b>Embed Defense Level Down:</b> [embed_defense_level_down]")
	. += span_info("<b>Embed Bleed Stacks:</b> [embed_bleed]")
	. += span_info("<b>Embed Movement Proc Organ Damage (Humans):</b> [embed_procced_organ_damage]")
	. += span_info("<b>Embed Movement Proc Brute Damage (Non-Humans):</b> [embed_procced_organ_damage * embed_organ_damage_simplemob_conversion_coeff]")
	. += span_info("<b>Removal Damage:</b> [removal_damage]")
	. += span_info("<b>Removal Bleed Stacks:</b> [removal_bleed_stacks]")

/// Called by the projectile to embed the arrow item into the victim, applying the status effect.
/obj/item/shi_east_arrow/proc/Embed(mob/living/shi_assassin, mob/living/victim, target_aim_stacks = 2, angle)
	if(victim && victim.status_flags & GODMODE)
		return FALSE

	current_embed_data["firer"] = shi_assassin
	current_embed_data["target_aim_stacks_used"] = target_aim_stacks
	var/targeted_organ_slot = pick(permitted_organ_targets)
	var/obj/item/organ/organ_i_guess = victim.getorganslot(targeted_organ_slot)
	if(istype(organ_i_guess))
		current_embed_data["target_organ"] = organ_i_guess

	// There's already some arrow(s) lodged in the target, add ours to that status effect
	var/datum/status_effect/stacking/shi_east_lodged_arrow/already_cooked = victim.has_status_effect(/datum/status_effect/stacking/shi_east_lodged_arrow)
	if(already_cooked)
		var/return_val = already_cooked.AddArrow(src) // This can fail. It'll drop the arrow on their turf, if so.
		if(return_val)
			EmbedEffect(victim)
			ApplyEmbedOverlay(victim, angle)
			return return_val

	// Make a fresh status effect if there isn't one.
	else
		var/return_val = victim.apply_status_effect(/datum/status_effect/stacking/shi_east_lodged_arrow, 0, src)
		if(return_val)
			EmbedEffect(victim)
			ApplyEmbedOverlay(victim, angle)
		return return_val

/obj/item/shi_east_arrow/proc/ApplyEmbedOverlay(mob/living/victim, angle)
	embedded_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/shi_east_overlays_32x32.dmi', "shi_east_arrow_embedded", ABOVE_MOB_LAYER)
	var/matrix/correct_matrix = matrix(angle, MATRIX_ROTATE)
	embedded_overlay.transform = correct_matrix

	var/icon/victim_icon = icon(victim.icon, victim.icon_state, victim.dir)
	var/icon_height = victim_icon.Height()
	var/icon_width = victim_icon.Width()
	var/height_diff = 32 - icon_height
	var/width_diff = 32 - icon_width

	embedded_overlay.pixel_x -= (width_diff * 0.5)
	embedded_overlay.pixel_y -= (height_diff * 0.5)

	victim.add_overlay(embedded_overlay)

/obj/item/shi_east_arrow/proc/RemoveEmbedOverlay(mob/living/victim)
	if(victim)
		victim.cut_overlay(embedded_overlay)
	embedded_overlay = null

/// Called by the status effect once it's time to remove the arrow item from the victim, placing it back into the playfield.
/obj/item/shi_east_arrow/proc/Unembed(destination)
	// Case 1: Destination is null. If the arrow still has data on who fired it, and that person hasn't been deleted, teleport the arrow to them. Otherwise, delete the arrow.
	if(!destination) // I pray this never happens.
		var/mob/living/shi_assassin = current_embed_data["firer"]
		if(!QDELETED(shi_assassin)) // Teleport the arrow to the shooter I guess.
			forceMove(get_turf(shi_assassin))
			visible_message(span_danger("[src] clatters to the ground, mysteriously. It shouldn't be here."))
			AestheticOffset()
		else // Both something went terribly wrong with the victim AND the shooter. The arrow is annihilated out of existence.
			qdel(src)

	// Case 2: Destination is a turf. Put the arrow on the turf.
	else if(isturf(destination))
		forceMove(destination)
		visible_message(span_danger("[src] clatters to the ground."))
		AestheticOffset()
	// Case 3: Destination is a human. Put it in their hands/turf beneath them.
	else if(ishuman(destination))
		var/mob/living/carbon/human/our_guy = destination
		forceMove(get_turf(our_guy))
		our_guy.put_in_active_hand(src)

	// Case 4: Anything else. Put it on the thing's turf.
	else
		var/atom/thingy = destination
		forceMove(get_turf(thingy))
		visible_message(span_danger("[src] clatters to the ground."))
		AestheticOffset()
	current_embed_data = list()

/// Applied once when the arrow is first embedded.
/obj/item/shi_east_arrow/proc/EmbedEffect(mob/living/victim)
	if(!istype(victim))
		return
	var/target_aim_stacks_used = current_embed_data["target_aim_stacks_used"]

	// Large burst of organ damage on humans.
	if(ishuman(victim))
		// Deal the initial burst of organ damage from the embed
		var/obj/item/organ/target_organ = current_embed_data["target_organ"]
		if(target_organ)
			target_organ.applyOrganDamage(embed_organ_damage_per_target_aim[target_aim_stacks_used])

	// Instead of organ damage, large burst of brute damage on simplemobs.
	else if(isanimal(victim))
		victim.deal_damage((embed_organ_damage_per_target_aim[target_aim_stacks_used] * embed_organ_damage_simplemob_conversion_coeff), BRUTE, source = current_embed_data["firer"], flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_RANGED))

	// Apply undecaying stacks of our status effects on embed.
	if(embed_offense_level_down > 0)
		victim.apply_lc_offense_level_down(0, embed_offense_level_down)
	if(embed_defense_level_down > 0)
		victim.apply_lc_defense_level_down(0, embed_defense_level_down)
	if(embed_bleed > 0)
		victim.apply_lc_bleed(0, embed_bleed)

	var/turf/victim_turf = get_turf(victim)
	for(var/i in 1 to 3)
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(victim_turf, pick(GLOB.alldirs))

/// Applied once when the arrow is removed or falls out.
/obj/item/shi_east_arrow/proc/UnembedEffect(mob/living/victim, brutal = FALSE)
	if(!istype(victim))
		return
	RemoveEmbedOverlay(victim)

	// When I add skills, brutal == TRUE will increase the effects from unembedding.

	// Apply a burst of temporary bleed stacks and some damage.
	if(removal_bleed_stacks)
		victim.apply_lc_bleed(removal_bleed_stacks)
	victim.deal_damage(removal_damage, damtype, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_STATUS))

	// Remove the undecaying stacks we may have applied when first embedding.
	var/datum/status_effect/stacking/offense_level_up/offense_level_down/ofdown = victim.has_status_effect(/datum/status_effect/stacking/offense_level_up/offense_level_down)
	var/datum/status_effect/stacking/defense_level_up/defense_level_down/defdown = victim.has_status_effect(/datum/status_effect/stacking/defense_level_up/defense_level_down)
	var/datum/status_effect/stacking/lc_bleed/bleed = victim.has_status_effect(/datum/status_effect/stacking/lc_bleed)
	if(ofdown)
		ofdown.add_undecaying_stacks(-embed_offense_level_down)
	if(defdown)
		defdown.add_undecaying_stacks(-embed_defense_level_down)
	if(bleed)
		bleed.add_undecaying_stacks(-embed_bleed)

	var/turf/victim_turf = get_turf(victim)
	playsound(victim_turf, 'sound/weapons/fixer/generic/spear1.ogg', 40, FALSE)
	for(var/i in 1 to 2)
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(victim_turf, pick(GLOB.alldirs))
	new /obj/effect/decal/cleanable/blood(victim_turf)

/// Procced by the status effect when the victim moves a certain amount...
/obj/item/shi_east_arrow/proc/EmbedMovementProc(mob/living/victim)
	if(!istype(victim))
		return
	if(ishuman(victim))
		var/obj/item/organ/target_organ = current_embed_data["target_organ"]
		if(!target_organ)
			return
		target_organ.applyOrganDamage(embed_procced_organ_damage)
	else if(isanimal(victim))
		victim.deal_damage(embed_procced_organ_damage * embed_organ_damage_simplemob_conversion_coeff, BRUTE, source = current_embed_data["firer"], flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_STATUS))

	to_chat(victim, span_danger("The [src.name] lodged in your chest damages you as you move!"))
	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(victim), pick(GLOB.alldirs))
	new /obj/effect/decal/cleanable/blood(get_turf(victim))

/// Makes arrows look more organically scattered on the ground by adding some pixel offsetting and rotation.
/obj/item/shi_east_arrow/proc/AestheticOffset()
	pixel_x += rand(-12, 12)
	pixel_y += rand(-6, 6)
	var/matrix/M = matrix()
	var/random_angle = rand(0, 359)
	M.Turn(random_angle)
	transform = M
	SpinAnimation(2, rand(0, 1), rand(0, 1), 8) // speeeeen

// Projectile. Bow's Glimmer does NOT use this.
/obj/projectile/ego_bullet/shi_east_arrow
	icon = 'ModularLobotomy/_Lobotomyicons/shi_east_obj.dmi'
	icon_state = "shi_east_arrow_proj"
	damage = 44
	speed = 1.2
	range = 100
	hitsound = 'sound/weapons/ego/shi_east_arrow_hit.ogg'
	hitsound_wall = 'sound/weapons/genhit.ogg'
	var/obj/item/shi_east_arrow/linked_arrow_item
	var/target_aim_stacks = 0

/obj/projectile/ego_bullet/shi_east_arrow/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_PARENT_QDELETING, PROC_REF(DropArrowItem)) // When we get destroyed, if we haven't accomplished an embed, drop the corresponding arrow item.

/// Called by the bow's fire_projectile to pass some info into this projectile.
/obj/projectile/ego_bullet/shi_east_arrow/proc/LinkToArrowItem(obj/item/shi_east_arrow/arrow_item, used_target_aim_stacks = 0)
	if(!istype(arrow_item))
		CRASH("Shi East Arrow projectile attempted to be linked with an invalid item.")

	linked_arrow_item = arrow_item
	name = arrow_item.name

	target_aim_stacks = used_target_aim_stacks
	speed = linked_arrow_item.speed_per_target_aim[target_aim_stacks]
	damage = linked_arrow_item.damage_per_target_aim[target_aim_stacks]
	damage_type = (target_aim_stacks >= 4) ? PALE_DAMAGE : linked_arrow_item.damtype

/// Embed when hitting a target at >= 2 target aim stacks.
/obj/projectile/ego_bullet/shi_east_arrow/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	// If we get slept here and our arrow hits a wall and deletes itself, linked_arrow_item will be nulled and cause a runtime. Don't ask how I know this. (it was a bug with chunky sweepers and PostDamageReaction())
	if(target_aim_stacks >= 2 && isliving(target))
		linked_arrow_item.Embed(firer, target, target_aim_stacks, original_angle)

/obj/projectile/ego_bullet/shi_east_arrow/proc/DropArrowItem()
	SIGNAL_HANDLER
	if(linked_arrow_item && !length(linked_arrow_item.current_embed_data))
		linked_arrow_item.forceMove(get_turf(src))
		linked_arrow_item.visible_message(span_danger("[linked_arrow_item] falls to the ground!"))
		linked_arrow_item.AestheticOffset()
	linked_arrow_item = null


/* -------------------- TARGET AIM BUFF -------------------- */
/datum/status_effect/stacking/shi_east_target_aim
	id = "shi_east_target_aim"
	status_type = STATUS_EFFECT_REFRESH
	duration = 4.4 SECONDS
	tick_interval = 10 SECONDS
	max_stacks = 4
	stacks = 0
	stack_decay = 0
	consumed_on_threshold = FALSE
	alert_type = /atom/movable/screen/alert/status_effect/shi_east_target_aim
	display_icon_file = 'ModularLobotomy/_Lobotomyicons/shi_east_status_10x10.dmi'
	stacking_display_name = "target_aim"

/datum/status_effect/stacking/shi_east_target_aim/add_stacks(stacks_added)
	. = ..()
	if(!owner || !linked_alert)
		return
	if(!stacks_added)
		return
	refresh()
	linked_alert.desc = initial(linked_alert.desc) + " [stacks]/4 stacks."
	var/message
	switch(stacks)
		if(1)
			message = "1/4 - Sight and confirm the target..."
			to_chat(owner, span_info(message))
			owner.overlay_fullscreen("oxy", /atom/movable/screen/fullscreen/oxy, 1)
		if(2)
			message = "2/4 - Account for wind speed and direction..."
			to_chat(owner, span_info(message))
			owner.overlay_fullscreen("oxy", /atom/movable/screen/fullscreen/oxy, 2)
		if(3)
			message = "3/4 - Hold your breath."
			to_chat(owner, span_info(message))
			owner.overlay_fullscreen("oxy", /atom/movable/screen/fullscreen/oxy, 3)
		if(4)
			message = "<b>死 - Full draw.</b>"
			to_chat(owner, span_nicegreen(message))
			owner.overlay_fullscreen("oxy", /atom/movable/screen/fullscreen/oxy, 4)

	owner.balloon_alert(owner, message)

/datum/status_effect/stacking/shi_east_target_aim/on_remove()
	. = ..()
	owner.clear_fullscreen("oxy")

/atom/movable/screen/alert/status_effect/shi_east_target_aim
	name = "Target Aim"
	desc = "Your next fired Shi East Arrow is empowered."
	icon = 'ModularLobotomy/_Lobotomyicons/shi_east_status_32x32.dmi'
	icon_state = "target_aim"

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
	display_icon_file = 'ModularLobotomy/_Lobotomyicons/shi_east_status_10x10.dmi'
	stacking_display_name = "lodged_arrow"
	var/list/lodged_arrows = list()
	var/duration_on_simplemobs = 20 SECONDS
	var/steps_per_movement_proc = 4
	var/steps = 0
	var/movement_proc_cooldown_duration = 1.2 SECONDS
	var/movement_proc_cooldown

/datum/status_effect/stacking/shi_east_lodged_arrow/can_have_status()
	return !QDELETED(owner)

/datum/status_effect/stacking/shi_east_lodged_arrow/on_creation(mob/living/new_owner, stacks_to_apply, obj/item/shi_east_arrow/source_arrow)
	if(!istype(new_owner) || !istype(source_arrow))
		return FALSE
	owner = new_owner
	. = ..()
	if(!.)
		return FALSE
	AddArrow(source_arrow)
	RegisterSignal(owner, COMSIG_PARENT_EXAMINE, PROC_REF(WhenOwnerExamined))
	movement_proc_cooldown = world.time + movement_proc_cooldown_duration
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(CallEmbedMovementProc))

/datum/status_effect/stacking/shi_east_lodged_arrow/proc/CallEmbedMovementProc(mob/living/victim)
	SIGNAL_HANDLER
	if(!istype(victim))
		return
	if(movement_proc_cooldown > world.time)
		return
	steps++
	if(steps >= steps_per_movement_proc)
		steps = 0
		movement_proc_cooldown = movement_proc_cooldown_duration + world.time
		for(var/probably_arrow in lodged_arrows)
			var/obj/item/shi_east_arrow/definitely_arrow = probably_arrow
			definitely_arrow.EmbedMovementProc(victim)

/datum/status_effect/stacking/shi_east_lodged_arrow/on_apply()
	. = ..()
	if(!owner)
		return FALSE
	RegisterSignal(owner, COMSIG_PARENT_QDELETING, PROC_REF(DropAllArrows))
	return TRUE

/datum/status_effect/stacking/shi_east_lodged_arrow/on_remove()
	. = ..()
	UnregisterSignal(owner, list(COMSIG_PARENT_QDELETING, COMSIG_PARENT_EXAMINE, COMSIG_MOVABLE_MOVED))
	DropAllArrows()

/// Registers an arrow into this status effect's list of arrows.
/datum/status_effect/stacking/shi_east_lodged_arrow/proc/AddArrow(obj/item/shi_east_arrow/embedding_arrow)
	if(!istype(embedding_arrow))
		return
	if((stacks + 1) > max_stacks)
		embedding_arrow.forceMove(get_turf(owner))
		return
	lodged_arrows |= embedding_arrow
	stacks = length(lodged_arrows)
	update_stacking_number()

	// For animals, remove the arrow on a timer.
	if(istype(owner, /mob/living/simple_animal))
		addtimer(CALLBACK(src, PROC_REF(RemoveArrow), owner), duration_on_simplemobs)

	return TRUE

/// Removes one of the arrows lodged into our owner.
/datum/status_effect/stacking/shi_east_lodged_arrow/proc/RemoveArrow(mob/living/removing, brutal = FALSE)
	if(EmptyCheck())
		return
	var/obj/item/shi_east_arrow/arrow = popleft(lodged_arrows) // In Theory(tm) popleft should ensure the arrows are removed FIFO.
	if(arrow)
		arrow.UnembedEffect(owner, brutal)
		arrow.Unembed(removing)
		lodged_arrows -= arrow
		EmptyCheck()

/datum/status_effect/stacking/shi_east_lodged_arrow/proc/DropAllArrows()
	var/turf/owner_turf = get_turf(owner)
	for(var/obj/item/shi_east_arrow/arrow in lodged_arrows)
		arrow.RemoveEmbedOverlay(owner)
		arrow.Unembed(owner_turf)
		lodged_arrows -= arrow
	EmptyCheck()

/datum/status_effect/stacking/shi_east_lodged_arrow/proc/EmptyCheck()
	if(!length(lodged_arrows) && !QDELETED(src))
		qdel(src)
		return TRUE
	stacks = length(lodged_arrows)
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
	icon = 'ModularLobotomy/_Lobotomyicons/shi_east_status_32x32.dmi'
	icon_state = "lodged_arrow"

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
#undef SHI_EAST_UNLOAD_MELEE
