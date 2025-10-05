#define SHOT_MODE 0
#define DOT_MODE 1
#define AOE_MODE 2

/obj/item/ego_weapon/ranged/star
	name = "sound of a star"
	desc = "The star shines brighter as our despair gathers. The weapon's small, evocative sphere fires a warm ray."
	icon_state = "star"
	inhand_icon_state = "star"
	special = "This gun scales with remaining SP."

	force = 33
	damtype = WHITE_DAMAGE
	attack_speed = 0.5

	projectile_path = /obj/projectile/ego_bullet/star
	weapon_weight = WEAPON_HEAVY
	spread = 5

	autofire = 0.25 SECONDS
	shotsleft = 333
	reloadtime = 2.1 SECONDS

	fire_sound = 'sound/weapons/ego/star.ogg'
	vary_fire_sound = TRUE
	fire_sound_volume = 25

	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 80
							)

/obj/item/ego_weapon/ranged/star/fire_projectile(atom/target, mob/living/user, params, distro, quiet, zone_override, spread, atom/fired_from, temporary_damage_multiplier)
	if(!ishuman(user))
		return ..()

	var/mob/living/carbon/human/H = user
	temporary_damage_multiplier = 1 + (H.sanityhealth / H.maxSanity * 0.5) // Maximum SP will add 50% to the damage
	return ..()

/obj/item/ego_weapon/ranged/star/suicide_act(mob/living/carbon/user)
	. = ..()
	user.visible_message(span_suicide("[user]'s legs distort and face opposite directions, as [user.p_their()] torso seems to pulsate! It looks like [user.p_theyre()] trying to commit suicide!"))
	playsound(src, 'sound/abnormalities/bluestar/pulse.ogg', 50, FALSE, 40, falloff_distance = 10)
	user.unequip_everything()
	QDEL_IN(user, 1)
	return MANUAL_SUICIDE

/obj/item/ego_weapon/ranged/adoration
	name = "adoration"
	desc = "A big mug filled with mysterious slime that never runs out. \
	It’s the byproduct of some horrid experiment in a certain laboratory that eventually failed."
	icon_state = "adoration"
	inhand_icon_state = "adoration"
	special = "Use in hand to swap between AOE, DOT and shotgun modes."

	force = 56
	damtype = BLACK_DAMAGE

	projectile_path = /obj/projectile/ego_bullet/adoration
	weapon_weight = WEAPON_HEAVY
	fire_delay = 10
	pellets = 3
	variance = 20

	fire_sound = 'sound/effects/attackblob.ogg'
	fire_sound_volume = 50

	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 80
							)
	var/mode = 0

/obj/item/ego_weapon/ranged/adoration/attack_self(mob/user)
	. = ..()
	switch(mode)
		if(SHOT_MODE)
			to_chat(user,"<span class='warning'>You focus, changing for a DOT blast</span>")
			projectile_path = /obj/projectile/ego_bullet/adoration/dot
			pellets = 1
			variance = 0
			mode = DOT_MODE
			return
		if(DOT_MODE)
			to_chat(user,"<span class='warning'>You focus, changing for an AOE blast</span>")
			projectile_path = /obj/projectile/ego_bullet/adoration/aoe
			mode = AOE_MODE
			return
		if(AOE_MODE)
			to_chat(user,"<span class='warning'>You focus, changing for a shotgun blast</span>")
			projectile_path = /obj/projectile/ego_bullet/adoration
			pellets = initial(pellets)
			variance = initial(variance)
			mode = SHOT_MODE
			return

#undef SHOT_MODE
#undef DOT_MODE
#undef AOE_MODE

/obj/item/ego_weapon/ranged/nihil
	name = "nihil"
	desc = "Having decided to trust its own intuition, the jester spake the names of everyone it had met on that path with each step it took."
	icon_state = "nihil"
	inhand_icon_state = "nihil"
	force = 56
	damtype = BLACK_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/nihil
	weapon_weight = WEAPON_HEAVY
	pellets = 4
	variance = 20
	fire_sound = 'sound/weapons/fixer/generic/energy1.ogg'
	fire_sound_volume = 50
	fire_delay = 10
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 80
							)
	var/wrath
	var/despair
	var/greed
	var/hate
	var/list/powers = list("hatred", "despair", "greed", "wrath")

/obj/item/ego_weapon/ranged/nihil/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	if(!istype(I, /obj/item/nihil))
		return

	if(powers[1] == "hatred" && istype(I, /obj/item/nihil/heart))
		powers[1] = "hearts"
		IncreaseAttributes(user, powers[1])
		qdel(I)
	else if(powers[2] == "despair" && istype(I, /obj/item/nihil/spade))
		powers[2] = "spades"
		IncreaseAttributes(user, powers[2])
		qdel(I)
	else if(powers[3] == "greed" && istype(I, /obj/item/nihil/diamond))
		powers[3] = "diamonds"
		IncreaseAttributes(user, powers[3])
		qdel(I)
	else if(powers[4] == "wrath" && istype(I, /obj/item/nihil/club))
		powers[4]= "clubs"
		IncreaseAttributes(user, powers[4])
		qdel(I)
	else
		to_chat(user,"<span class='warning'>You have already used this upgrade!</span>")

/obj/item/ego_weapon/ranged/nihil/proc/IncreaseAttributes(user, current_suit)
	for(var/atr in attribute_requirements)
		if(atr == TEMPERANCE_ATTRIBUTE)
			attribute_requirements[atr] += 5
		else
			attribute_requirements[atr] += 10
	to_chat(user,"<span class='warning'>The requirements to use [src] have increased!</span>")

	switch(current_suit)
		if("hearts")
			to_chat(user,"<span class='nicegreen'>The ace of [current_suit] has removed friendly fire from [src]!</span>")

		if("spades")
			to_chat(user,"<span class='nicegreen'>The ace of [current_suit] granted [src] the capability of dealing pale damage!</span>")

		if("diamonds")
			to_chat(user,"<span class='nicegreen'>The ace of [current_suit] granted [src] the capability of dealing red damage!</span>")

		if("clubs")
			to_chat(user,"<span class='nicegreen'>The ace of [current_suit] granted [src] the capability of dealing black damage!</span>")
	to_chat(user,"<span class='nicegreen'>The ace of [current_suit] fades away as it makes [src] become even more powerful!</span>")
	return

/obj/item/ego_weapon/ranged/pink
	name = "pink"
	desc = "Pink is considered to be the color of warmth and love, but is that true? \
			Can guns really bring peace and love?"
	icon_state = "pink"
	inhand_icon_state = "pink"
	special = "This weapon has a scope, and fires projectiles with zero travel time. Damage dealt is increased when hitting targets further away. Middle mouse button click/alt click to zoom in that direction."
	force = 56
	damtype = WHITE_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/pink
	weapon_weight = WEAPON_HEAVY
	fire_sound = 'sound/abnormalities/armyinblack/pink.ogg'
	fire_delay = 9
	zoomable = TRUE
	zoom_amt = 10
	zoom_out_amt = 13
	shotsleft = 5
	reloadtime = 2.1 SECONDS
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)
	var/mob/current_holder

/obj/item/ego_weapon/ranged/pink/MiddleClickAction(atom/target, mob/living/user)
	. = ..()
	if(.)
		return
	zoom(user, get_cardinal_dir(user, target))

/obj/item/ego_weapon/ranged/pink/zoom(mob/living/user, direc, forced_zoom)
	if(!CanUseEgo(user))
		return
	if(!user || !user.client)
		return
	if(isnull(forced_zoom))
		zoomed = !zoomed
	else
		zoomed = forced_zoom
	if(src != user.get_active_held_item())
		if(!zoomed)
			UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
			UnregisterSignal(user, COMSIG_ATOM_DIR_CHANGE)
			user.client.view_size.zoomIn()
		return
	if(!zoomed)
		UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
		UnregisterSignal(user, COMSIG_ATOM_DIR_CHANGE)
		user.client.view_size.zoomIn()
	else
		RegisterSignal(user, COMSIG_ATOM_DIR_CHANGE, PROC_REF(rotate))
		RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(UserMoved))
		user.client.view_size.zoomOut(zoom_out_amt, zoom_amt, direc)
	return zoomed

/obj/item/ego_weapon/ranged/pink/proc/UserMoved(mob/living/user, direc)
	SIGNAL_HANDLER
	zoom(user)//disengage

/obj/item/ego_weapon/ranged/pink/Destroy(mob/user)//FIXME: causes component runtimes
	if(!user)
		return ..()
	if(zoomed)
		UnregisterSignal(current_holder, COMSIG_MOVABLE_MOVED)
		UnregisterSignal(current_holder, COMSIG_ATOM_DIR_CHANGE)
		current_holder = null
		return ..()

/obj/item/ego_weapon/ranged/pink/dropped(mob/user)
	. = ..()
	if(!user)
		return
	if(zoomed)
		UnregisterSignal(current_holder, COMSIG_MOVABLE_MOVED)
		UnregisterSignal(current_holder, COMSIG_ATOM_DIR_CHANGE)
		current_holder = null

/obj/item/ego_weapon/ranged/arcadia
	name = "Et in Arcadia Ego"
	desc = "With the waxing of the sun, humanity wanes."
	icon_state = "arcadia"
	inhand_icon_state = "arcadia"
	special = "Use in hand to load bullets."
	force = 56
	projectile_path = /obj/projectile/ego_bullet/arcadia
	weapon_weight = WEAPON_HEAVY
	spread = 5
	recoil = 1.5
	fire_sound = 'sound/weapons/gun/rifle/shot_atelier.ogg'
	vary_fire_sound = TRUE
	fire_sound_volume = 30
	fire_delay = 7

	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 100
							)


	shotsleft = 16	//Based off a henry .44
	reloadtime = 0.5 SECONDS

/obj/item/ego_weapon/ranged/arcadia/reload_ego(mob/user)
	if(shotsleft == initial(shotsleft))
		return
	is_reloading = TRUE
	to_chat(user,"<span class='notice'>You start loading a bullet.</span>")
	if(do_after(user, reloadtime, src)) //gotta reload
		playsound(src, 'sound/weapons/gun/general/slide_lock_1.ogg', 50, TRUE)
		shotsleft +=1
	is_reloading = FALSE

/obj/item/ego_weapon/ranged/arcadia/judge
	name = "Judge"
	desc = "You will be judged; as I have."
	icon_state = "judge"
	inhand_icon_state = "judge"
	force = 56
	damtype = WHITE_DAMAGE
	weapon_weight = WEAPON_MEDIUM	//Cannot be dual wielded
	recoil = 2
	fire_sound_volume = 30
	fire_delay = 3	//FAN THE HAMMER

	shotsleft = 6	//Based off a colt Single Action Navy
	reloadtime = 1 SECONDS


/obj/item/ego_weapon/ranged/havana
	name = "havana"
	desc = "Within it's simple design lies a lot of struggle"
	icon_state = "havana"
	inhand_icon_state = "havana"
	force = 20
	damtype = PALE_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_hookah
	weapon_weight = WEAPON_HEAVY
	spread = 20
	fire_sound = 'sound/effects/smoke.ogg'
	autofire = 0.04 SECONDS
	fire_sound_volume = 5
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 100
	)
	shotsleft = 200

#define STATUS_EFFECT_ENTRENCHED_INITIAL /datum/status_effect/willing_weapon_entrenched
#define STATUS_EFFECT_ENTRENCHED_FINAL /datum/status_effect/willing_weapon_entrenched/final_stage

/obj/item/ego_weapon/ranged/willing
	name = "flesh is willing"
	desc = "And really nothing will stop it."
	icon_state = "willing"
	inhand_icon_state = "willing"
	damtype = RED_DAMAGE
	force = 60
	attack_speed = 1.5
	weapon_weight = WEAPON_HEAVY
	hitsound = 'sound/weapons/fast_slam.ogg'
	usesound = 'sound/effects/ordeals/amber/dusk_dead.ogg'

	fire_sound = 'sound/weapons/ego/willing_fire1.ogg'
	fire_sound_volume = 40
	projectile_path = /obj/projectile/ego_bullet/willing
	shotsleft = 100
	reloadtime = 3 SECONDS
	autofire = 1.4
	spread = 25

	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)
	special = "Reload this weapon by <b>alt-clicking</b> it.\n\
	You can <b>use this weapon in-hand</b> to spend health to enter the <b>Inexorable</b> state after a brief wind-up, \
	during which you will gain a slight slowdown, damage resistance, stun immunity, resistance to being pushed, and an unlimited amount of higher caliber bullets.\n\
	After 7 seconds of being in the Inexorable state, you will enter the <b>Entrenched</b> state, which increases damage resistance further \
	and empowers the bullets to deal more damage and pierce through a single target.\n\
	<b>If you move while Entrenched, you will exit the state</b>. \n\
	You can also cancel the process of activating Inexorable by swapping hands, or dropping or storing the weapon. \
	Once you've entered Inexorable or Entrenched, you cannot drop or store the weapon."

	// These two vars are for the timer that upgrades Inexorable to Entrenched. It starts running when you use the weapon's ability, and deletes the initial buff and replaces it with the final version.
	var/entrenchment_upgrade_timer
	var/entrenchment_upgrade_timer_duration = 7 SECONDS

	/// This cooldown is just so people don't spam the hell out of the sound.
	COOLDOWN_DECLARE(ability)

	/// Holds this weapon's attached Autofire component. We will be modifying it often.
	var/datum/component/automatic_fire/autofire_component

	// These vars are all associated lists, wherein each index corresponds to a state of the weapon. 1 for base, 2 for inexorable (initial buff) and 3 for entrenched (final buff).
	/// The spread of the weapon's bullets. Lower is more precise.
	var/list/entrenchment_stage_spread_values = list(27, 13, 4)
	/// The fire rate for the weapon. Higher is slower. The reason why it gets slower as your buff progresses, is because you get drastically more powerful ammo.
	var/list/entrenchment_stage_firerate_values = list(1.4, 2.35, 3.1)
	// These three lists are self explanatory. Projectile type, fire sound and volume used in each stage.
	var/list/entrenchment_stage_projectile_types = list(/obj/projectile/ego_bullet/willing, /obj/projectile/ego_bullet/willing/heavy, /obj/projectile/ego_bullet/willing/superheavy)
	var/list/entrenchment_stage_firesound = list('sound/weapons/ego/willing_fire1.ogg', 'sound/weapons/gun/rifle/shot_alt.ogg', 'sound/weapons/gun/sniper/shot.ogg')
	var/list/entrenchment_stage_volume = list(40, 35, 43)

	/// Lets you store this gun normally into your belt/suit storage/whatever. We disable this when the special ability is active.
	var/storeable = TRUE

/obj/item/ego_weapon/ranged/willing/Initialize(mapload)
	. = ..()
	// We're going to be using this component a few times so might as well pull it
	autofire_component = GetComponent(/datum/component/automatic_fire)
	// Keeps stats consistent to the entrenchment_stage_X_values variables. This is in case someone goes to buff/nerf this weapon but does it improperly, so the weapon remains consistent.
	ChangeStats(1)

/obj/item/ego_weapon/ranged/willing/mob_can_equip(mob/living/M, mob/living/equipper, slot, disable_warning, bypass_equip_delay_self)
	if(!storeable)
		return FALSE
	return ..()

/// When using the weapon in-hand, we activate the special ability. Reload is on altclick instead. Sorry.
/obj/item/ego_weapon/ranged/willing/attack_self(mob/user)
	if((!CanUseEgo(user)) || (CheckIfUserEntrenched(user)) || (!ishuman(user)) || !COOLDOWN_FINISHED(src, ability))
		return
	var/mob/living/carbon/human/entrencher = user
	if(entrencher.is_working)
		to_chat(user, span_danger("You can't call upon the power of [src] - it'd cloud your mind too much for you to be able to carry out the work."))
		return

	COOLDOWN_START(src, ability, 2 SECONDS)
	playsound(src, usesound, 80, FALSE)

	// There's a delay, but this happens on the move. You can still cancel obtaining the buff by swapping hands or dropping or storing the weapon.
	if((do_after(user, 2 SECONDS, timed_action_flags = IGNORE_USER_LOC_CHANGE, interaction_key = "willing_entrench", max_interact_count = 1)) && (!entrencher.is_working))
		entrencher.adjustBruteLoss(20)
		entrencher.apply_status_effect(STATUS_EFFECT_ENTRENCHED_INITIAL)
		entrenchment_upgrade_timer = addtimer(CALLBACK(src, PROC_REF(UpgradeEntrench), user), entrenchment_upgrade_timer_duration, TIMER_STOPPABLE)
		return
	else
		to_chat(entrencher, span_danger("You decide not to call upon the power of [src]."))

/obj/item/ego_weapon/ranged/willing/AltClick(mob/user)
	if(reloadtime && !is_reloading)
		INVOKE_ASYNC(src, PROC_REF(reload_ego), user)
	return ..()

/obj/item/ego_weapon/ranged/willing/proc/UpgradeEntrench(mob/user)
	if(ishuman(user))
		var/mob/living/carbon/human/entrencher = user
		var/datum/status_effect/willing_weapon_entrenched/buff = entrencher.has_status_effect(STATUS_EFFECT_ENTRENCHED_INITIAL)
		if(buff)
			entrencher.remove_status_effect(STATUS_EFFECT_ENTRENCHED_INITIAL)
			entrencher.apply_status_effect(STATUS_EFFECT_ENTRENCHED_FINAL)

/obj/item/ego_weapon/ranged/willing/proc/ChangeStats(stage)
	// If someone tries to give this proc a funny number that would cause an out of bounds error, early return.
	if(!(stage in 1 to 3))
		return FALSE

	shotsleft = initial(shotsleft)
	// Unlimited ammo if not in base state.
	if(stage == 1)
		reloadtime = initial(reloadtime)
	else
		reloadtime = 0

	// Adjust weapon stats and aesthetic elements to match the stage.
	projectile_path = entrenchment_stage_projectile_types[stage]
	spread = entrenchment_stage_spread_values[stage]
	autofire_component.autofire_shot_delay = entrenchment_stage_firerate_values[stage]

	fire_sound = entrenchment_stage_firesound[stage]
	fire_sound_volume = entrenchment_stage_volume[stage]

/// Proc that checks if the user has either of the status effects (inexorable, entrenched)
/obj/item/ego_weapon/ranged/willing/proc/CheckIfUserEntrenched(mob/living/carbon/human/user)
	if(istype(user))
		var/datum/status_effect/willing_weapon_entrenched/buff = user.has_status_effect(STATUS_EFFECT_ENTRENCHED_INITIAL)
		if(buff)
			return TRUE
	return FALSE

// Following code corresponds to the status effects granted by the Flesh is Willing weapon.
/datum/status_effect/willing_weapon_entrenched
	id = "willing_weapon_entrenched"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/willing_weapon_entrenched
	duration = 10 SECONDS // This status effect will be manually removed when upgraded to the next.

	/// Multiplier applied to subject's physiology resistances, so 0.5 means you take half damage. Should always be lower (stronger) for the final_stage version,
	/// and should NEVER be 0.
	var/physiology_multiplier = 0.8
	/// Whether this stage of the status effect roots you in place. If it does, you are very briefly immobilized when applied, then further movement breaks the status.
	/// If it doesn't, you get slowed down.
	var/should_immobilize = FALSE
	/// The stage of the weapon this status corresponds to, which controls the stats applied to the weapon according to its own a-lists. It is used as an index, basically.
	var/stage = 2
	/// The gun that we'll be modifying. This isn't necessarily (but should be in 99.99999% of cases) the gun that applied the effect.
	var/obj/item/ego_weapon/ranged/willing/linked_gun
	/// Visuals applied onto the user by the effect.
	var/mutable_appearance/visual_overlay

/// This is the final stage of the buff, where you get "immobilized" (you can move but it breaks the status) and get stronger buffs.
/datum/status_effect/willing_weapon_entrenched/final_stage
	physiology_multiplier = 0.6
	duration = 15 SECONDS
	stage = 3
	should_immobilize = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/willing_weapon_entrenched/final_stage

/// Needed because throws seemingly don't care about your move resistance.
/datum/status_effect/willing_weapon_entrenched/proc/HaltThrows()
	SIGNAL_HANDLER
	return COMPONENT_CANCEL_THROW

/datum/status_effect/willing_weapon_entrenched/on_apply()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/john_willing = owner
		var/obj/item/ego_weapon/ranged/willing/entrenching_gun = john_willing.is_holding_item_of_type(/obj/item/ego_weapon/ranged/willing)
		if(istype(entrenching_gun)) // We found the gun in our active hand or offhand(s)
			// Changes to gun
			linked_gun = entrenching_gun
			linked_gun.ChangeStats(stage) // Change the gun's stats (spread, fire rate, ammo type, etc)
			linked_gun.storeable = FALSE
			ADD_TRAIT(linked_gun, TRAIT_NODROP, "willing") // You can no longer drop or throw the gun.

			// Changes to user
			RegisterSignal(john_willing, COMSIG_WORK_STARTED, PROC_REF(Revert)) // If you try to start a work with this buff it falls off, because come on
			RegisterSignal(john_willing, COMSIG_MOVABLE_PRE_THROW, PROC_REF(HaltThrows)) // Necessary to stop being thrown by stuff like Ebony or LOOS
			john_willing.physiology.red_mod *= physiology_multiplier
			john_willing.physiology.white_mod *= physiology_multiplier
			john_willing.physiology.black_mod *= physiology_multiplier
			john_willing.physiology.pale_mod *= physiology_multiplier

			// I was tempted to add move force, but sadly the amount of force required to push Abnormalities aside will also forcibly move anchored objects like glass windows or machines
			john_willing.move_resist = MOVE_FORCE_OVERPOWERING
			ADD_TRAIT(john_willing, TRAIT_STUNIMMUNE, "willing")
			ADD_TRAIT(john_willing, TRAIT_PUSHIMMUNE, "willing")
			var/turf/user_turf = get_turf(john_willing)
			// Aesthetics.
			AestheticBloodsplatters(user_turf)

			// If this stage of the buff should immobilize us, we VERY BRIEFLY immobilize the user, and register a signal that breaks the buff if they move manually.
			// The reason for this is that being immobilized in combat is EXTREMELY deadly, especially at ALEPH tier. This weapon would be borderline unusable if it truly rooted you.
			if(should_immobilize)
				john_willing.Immobilize(1.5 SECONDS, TRUE)
				RegisterSignal(john_willing, COMSIG_MOVABLE_MOVED, PROC_REF(Revert))
				visual_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/48x48.dmi', "last_shot", ABOVE_MOB_LAYER)
				visual_overlay.transform *= 0.75
				visual_overlay.pixel_x -= 10
				visual_overlay.pixel_y -= 16
				john_willing.add_overlay(visual_overlay)
				john_willing.visible_message(span_danger("A fleshy barricade envelops [john_willing], protecting \him!"), span_nicegreen("Flesh envelops your body, protecting you."))
			// Otherwise we apply a slowdown.
			else
				john_willing.add_movespeed_modifier(/datum/movespeed_modifier/entrenched)
				visual_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/tegu_effects.dmi', "inexorable", ABOVE_MOB_LAYER)
				john_willing.add_overlay(visual_overlay)
				john_willing.visible_message(span_danger("Tendrils of flesh begin creeping up [john_willing], acting as armour for \him!"), span_nicegreen("Tendrils of flesh begin to creep up your body, acting as armour for you."))
			return TRUE

	return FALSE

// Clean up the unholy mess we stapled onto the gun and its user
/datum/status_effect/willing_weapon_entrenched/on_remove()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/john_willing = owner

		if(linked_gun)
			// Changes to gun
			linked_gun.ChangeStats(1)
			linked_gun.storeable = TRUE
			REMOVE_TRAIT(linked_gun, TRAIT_NODROP, "willing")
			deltimer(linked_gun.entrenchment_upgrade_timer)
			linked_gun = null

		// Changes to user
		UnregisterSignal(john_willing, COMSIG_WORK_STARTED)
		UnregisterSignal(john_willing, COMSIG_MOVABLE_PRE_THROW)
		john_willing.physiology.red_mod /= physiology_multiplier
		john_willing.physiology.white_mod /= physiology_multiplier
		john_willing.physiology.black_mod /= physiology_multiplier
		john_willing.physiology.pale_mod /= physiology_multiplier

		john_willing.move_resist = MOVE_FORCE_DEFAULT
		REMOVE_TRAIT(john_willing, TRAIT_STUNIMMUNE, "willing")
		REMOVE_TRAIT(john_willing, TRAIT_PUSHIMMUNE, "willing")

		if(should_immobilize)
			UnregisterSignal(john_willing, COMSIG_MOVABLE_MOVED)
			var/turf/user_turf = get_turf(john_willing)
			AestheticBloodsplatters(user_turf)
		else
			john_willing.remove_movespeed_modifier(/datum/movespeed_modifier/entrenched)

		john_willing.cut_overlay(visual_overlay)

/datum/status_effect/willing_weapon_entrenched/proc/Revert()
	if(ishuman(owner))
		var/mob/living/carbon/human/john_willing = owner
		john_willing.remove_status_effect(STATUS_EFFECT_ENTRENCHED_INITIAL)
		john_willing.remove_status_effect(STATUS_EFFECT_ENTRENCHED_FINAL)

/// Purely aesthetic effect used when the effect upgrades/is removed at last stage
/datum/status_effect/willing_weapon_entrenched/proc/AestheticBloodsplatters(turf/user_turf)
	for(var/i in 1 to 3)
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(user_turf, pick(GLOB.alldirs))
	new /obj/effect/decal/cleanable/blood(user_turf)
	playsound(user_turf, 'sound/effects/ordeals/crimson/dusk_dead.ogg', 25, FALSE)

/datum/movespeed_modifier/entrenched
	multiplicative_slowdown = 2.2

/atom/movable/screen/alert/status_effect/willing_weapon_entrenched
	name = "Inexorable"
	icon_state = "inexorable"
	desc = "Forward! Until the last bullet is spent!"

/atom/movable/screen/alert/status_effect/willing_weapon_entrenched/final_stage
	name = "Entrenched"
	icon_state = "entrenched"
	desc = "Despite the pain and suffering, even if torn to fleshy ribbons, you'll continue the fight."

#undef STATUS_EFFECT_ENTRENCHED_INITIAL
#undef STATUS_EFFECT_ENTRENCHED_FINAL

