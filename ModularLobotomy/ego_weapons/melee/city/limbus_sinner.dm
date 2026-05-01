//Sinner weapons - TETH
/obj/item/ego_weapon/mini/hayong
	name = "ha yong"
	desc = "Have you heard of the taxidermied genius?"
	special = "This weapon attacks very fast. Use this weapon in hand to dodgeroll."
	icon_state = "hayong"
	icon = 'icons/obj/limbus_weapons.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/limbus_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/limbus_righthand.dmi'
	force = 7
	attack_speed = 0.3
	damtype = WHITE_DAMAGE
	hitsound = 'sound/weapons/bladeslice.ogg'
	var/dodgelanding

/obj/item/ego_weapon/mini/hayong/attack_self(mob/living/carbon/user)
	if(user.dir == 1)
		dodgelanding = locate(user.x, user.y + 5, user.z)
	if(user.dir == 2)
		dodgelanding = locate(user.x, user.y - 5, user.z)
	if(user.dir == 4)
		dodgelanding = locate(user.x + 5, user.y, user.z)
	if(user.dir == 8)
		dodgelanding = locate(user.x - 5, user.y, user.z)
	user.adjustStaminaLoss(20, TRUE, TRUE)
	user.throw_at(dodgelanding, 3, 2, spin = TRUE)

/obj/item/ego_weapon/shield/parry/walpurgisnacht
	name = "walpurgisnacht"
	desc = "Man errs so long as he strives."
	icon_state = "walpurgisnacht"
	icon = 'icons/obj/limbus_weapons.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/limbus_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/limbus_righthand.dmi'
	force = 33
	attack_speed = 1.6
	damtype = WHITE_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP

	attack_verb_continuous = list("cuts", "smacks", "bashes")
	attack_verb_simple = list("cuts", "smacks", "bashes")
	hitsound = 'sound/weapons/bladeslice.ogg'
	reductions = list(20, 30, 10, 0) // 60
	projectile_block_duration = 1 SECONDS
	block_duration = 1 SECONDS
	block_cooldown = 3 SECONDS
	block_sound = 'sound/weapons/ego/clash1.ogg'
	projectile_block_message = "You swat the projectile out of the air!"
	block_message = "You attempt to parry the attack!"
	hit_message = "parries the attack!"
	block_cooldown_message = "You rearm your blade."

/obj/item/ego_weapon/lance/suenoimpossible
	name = "sueno impossible"
	desc = "To reach the unreachable star!"
	icon_state = "sueno_impossible"
	icon = 'icons/obj/limbus_weapons.dmi'
	lefthand_file = 'icons/mob/inhands/96x96_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/96x96_righthand.dmi'
	inhand_x_dimension = 96
	inhand_y_dimension = 96
	force = 38
	reach = 2		//Has 2 Square Reach.
	stuntime = 5
	attack_speed = 1.6// really slow
	damtype = RED_DAMAGE

	attack_verb_continuous = list("bludgeons", "whacks")
	attack_verb_simple = list("bludgeon", "whack")
	hitsound = 'sound/weapons/fixer/generic/spear2.ogg'

/obj/item/ego_weapon/shield/parry/sangria
	name = "S.A.N.G.R.I.A"
	desc = "Succinct abbreviation naturally germinates rather immaculate art."
	special = "Blocking with this weapon does not reduce damage, instead attacks all nearby targets when blocking."
	icon_state = "sangria"
	icon = 'icons/obj/limbus_weapons.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/limbus_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/limbus_righthand.dmi'
	hitsound = 'sound/weapons/bladeslice.ogg'
	force = 32
	stuntime = 5
	damtype = BLACK_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP

	attack_verb_continuous = list("pokes", "jabs", "tears", "lacerates", "gores")
	attack_verb_simple = list("poke", "jab", "tear", "lacerate", "gore")
	reductions = list(0, 0, 0, 0) // You're countering all attacks
	projectile_block_duration = 0 SECONDS //No ranged parry
	block_duration = 0.5 SECONDS
	block_cooldown = 3 SECONDS
	block_sound = 'sound/weapons/parry.ogg'
	block_message = "You prepare to strike those around you..."
	hit_message = "prepares to strike!"
	block_cooldown_message = "You rearm your blade."
	/// Map of finger key -> broken bool. Set TRUE as each Finger role breaks their seal.
	var/list/seals_broken = list("pinky" = FALSE, "ring" = FALSE, "middle" = FALSE, "thumb" = FALSE, "index" = FALSE)
	/// Latches TRUE when all five seals are broken; unlocks the dash + examine buttons.
	var/awakened = FALSE
	/// Wielder toggle for the awakened-form dash afterattack.
	var/dash_enabled = TRUE
	/// The total amount of lines you need within your chat to do the dash attack.
	var/lines_needed = 25

// Five-Seal system: each Finger role can break their corresponding seal. Once all 5 are broken,
// the blade awakens — gains a chat-consuming ranged dash-afterattack and two examine buttons
// (toggle the dash, fully unsheathe into Arayashiki).
GLOBAL_LIST_INIT(sangria_finger_roles, list(
	"pinky" = list("Dihui Star"),
	"ring" = list("Corporist Maestro"),
	"middle" = list("Ex Great Brother"),
	"thumb" = list("Ex Thumb Sottocapo"),
	"index" = list("Oracle Proxy"),
))

/obj/item/ego_weapon/shield/sangria/examine(mob/user)
	. = ..()
	. += span_notice("The blade bears five seals:")
	for(var/finger in seals_broken)
		var/state = seals_broken[finger] ? span_nicegreen("broken") : span_warning("sealed")
		var/line = "- [capitalize(finger)]: [state]"
		if(!seals_broken[finger] && user.mind && (user.mind.assigned_role in GLOB.sangria_finger_roles[finger]))
			line += " <a href='byond://?src=[REF(src)];sangria_break_seal=[finger]'>\[Break the [capitalize(finger)] seal\]</a>"
		. += line
	if(awakened && (user == loc || (ismob(loc) && (src in user.held_items))))
		. += span_warning("The blade hungers. The seals are gone.")
		. += "<a href='byond://?src=[REF(src)];sangria_toggle_dash=1'>\[Toggle dash afterattack: [dash_enabled ? "ON" : "OFF"]\]</a>"
		. += "<a href='byond://?src=[REF(src)];sangria_unsheathe=1'>\[Fully unsheathe the blade\]</a>"

/obj/item/ego_weapon/shield/sangria/Topic(href, list/href_list)
	. = ..()
	if(href_list["sangria_break_seal"])
		var/finger = href_list["sangria_break_seal"]
		if(!(finger in seals_broken) || seals_broken[finger])
			return
		var/list/eligible = GLOB.sangria_finger_roles[finger]
		if(!length(eligible) || !usr.mind || !(usr.mind.assigned_role in eligible))
			return
		seals_broken[finger] = TRUE
		visible_message(span_userdanger("[usr] presses their authority into the Sangria - the [finger] seal cracks."), \
			span_userdanger("You break the [finger] seal. The blade trembles in your hand."))
		playsound(src, 'sound/weapons/parry.ogg', 60, TRUE)
		CheckAwaken()
		return
	if(href_list["sangria_toggle_dash"])
		if(!awakened || usr.get_active_held_item() != src)
			return
		dash_enabled = !dash_enabled
		to_chat(usr, span_notice("Sangria's dash afterattack is now [dash_enabled ? "ENABLED" : "DISABLED"]."))
		return
	if(href_list["sangria_unsheathe"])
		if(!awakened || usr.get_active_held_item() != src)
			return
		UnsheatheToArayashiki(usr)
		return

/obj/item/ego_weapon/shield/sangria/proc/CheckAwaken()
	if(awakened)
		return
	for(var/seal in seals_broken)
		if(!seals_broken[seal])
			return
	awakened = TRUE
	name = "S.A.N.G.R.I.A. (Awakened)"
	desc += " All five seals are broken; the blade hungers."
	visible_message(span_userdanger("Sangria's seals are all broken. The blade hums with newfound hunger."))

/obj/item/ego_weapon/shield/sangria/proc/UnsheatheToArayashiki(mob/user)
	if(!user || !ismob(user))
		return
	var/turf/T = get_turf(user)
	if(!T)
		return
	var/obj/item/ego_weapon/city/arayashiki/A = new(T)
	user.visible_message(span_userdanger("Sangria slips from its sheath. Arayashiki \u963F\u983C\u8036\u8B58 stands revealed."), \
		span_userdanger("You draw the true blade."))
	user.dropItemToGround(src, force = TRUE, silent = TRUE)
	user.put_in_active_hand(A)
	qdel(src)

/obj/item/ego_weapon/shield/sangria/afterattack(atom/A, mob/living/user, proximity_flag, params)
	. = ..()
	if(!awakened || !dash_enabled)
		return
	if(!CanUseEgo(user))
		return
	if(!isliving(A))
		return
	if(proximity_flag)
		return
	if(!can_see(user, A, 7))
		to_chat(user, span_warning("You cannot see your target."))
		return
	if(get_dist(user, A) < 2)
		return

	// Chat threshold: server-side counter of dispatched chat lines. 50% must be >= 100, so total >= 200.
	var/lines = user.client?.chat_message_count
	if(!lines || lines < lines_needed)
		to_chat(user, span_warning("Sangria stirs but finds no memory worth devouring."))
		return

	arayashiki_prune_chat(user.client, 50)

	for(var/i in 2 to get_dist(user, A))
		step_towards(user, A)
	playsound(get_turf(src), 'sound/weapons/fwoosh.ogg', 300, FALSE, 9)
	to_chat(user, span_warning("Sangria devours your memory and pulls you to [A]!"))

	if(get_dist(user, A) >= 2)
		return
	var/mob/living/L = A
	var/justmod = ishuman(user) ? (1 + get_modified_attribute_level(user, JUSTICE_ATTRIBUTE) / 100) : 1
	var/dmg = 55 * justmod
	if(istype(L, /mob/living/simple_animal))
		dmg *= 5
	L.deal_damage(dmg, PALE_DAMAGE, source = user, attack_type = ATTACK_TYPE_MELEE)

	if(iscarbon(L))
		var/datum/status_effect/stacking/sever_the_thread/S = L.has_status_effect(/datum/status_effect/stacking/sever_the_thread)
		if(!S)
			L.apply_status_effect(/datum/status_effect/stacking/sever_the_thread, 10)
		else
			S.add_stacks(10)
		if(!L.GetComponent(/datum/component/tiansha_bladewound))
			L.AddComponent(/datum/component/tiansha_bladewound)


/obj/item/ego_weapon/mini/soleil
	name = "soleil"
	desc = "Today I killed my mother, or maybe it was yesterday?"
	icon_state = "soleil"
	icon = 'icons/obj/limbus_weapons.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/limbus_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/limbus_righthand.dmi'
	force = 11
	attack_speed = 0.5
	damtype = RED_DAMAGE


/obj/item/ego_weapon/taixuhuanjing
	name = "tai xuhuan jing"
	desc = "Jade has its flaws, and life its vicissitudes."
	icon_state = "tai_xuhuan_jing"
	icon = 'icons/obj/limbus_weapons.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/limbus_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/limbus_righthand.dmi'
	force = 22
	reach = 2		//Has 2 Square Reach.
	attack_speed = 1.2
	damtype = WHITE_DAMAGE

	attack_verb_continuous = list("pokes", "jabs", "tears", "lacerates", "gores")
	attack_verb_simple = list("poke", "jab", "tear", "lacerate", "gore")
	hitsound = 'sound/weapons/ego/sword1.ogg'

/obj/item/ego_weapon/revenge
	name = "revenge"
	desc = "I have not broken your heart - YOU have; and in breaking it, you have broken mine."
	icon_state = "revenge"
	icon = 'icons/obj/limbus_weapons.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/limbus_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/limbus_righthand.dmi'
	force = 35
	attack_speed = 1.6
	damtype = BLACK_DAMAGE

	attack_verb_continuous = list("beats", "smacks")
	attack_verb_simple = list("beat", "smack")

/obj/item/ego_weapon/revenge/attack(mob/living/target, mob/living/user)
	. = ..()
	if(!.)
		return FALSE
	var/atom/throw_target = get_edge_target_turf(target, user.dir)
	if(!target.anchored)
		var/whack_speed = (prob(60) ? 1 : 4)
		target.throw_at(throw_target, rand(1, 2), whack_speed, user)

/obj/item/ego_weapon/mini/hearse
	name = "hearse"
	desc = "That bastard's still alive out there..."
	icon_state = "hearse"
	icon = 'icons/obj/limbus_weapons.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/limbus_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/limbus_righthand.dmi'
	force = 33				//Lots of damage, way less DPS
	damtype = WHITE_DAMAGE

	attack_speed = 2 // Really Slow
	attack_verb_continuous = list("smashes", "bludgeons", "crushes")
	attack_verb_simple = list("smash", "bludgeon", "crush")

/obj/item/ego_weapon/shield/hearse
	name = "hearse"
	desc = "Call me Ishmael."
	special = "This weapon has a slow attack speed and deals atrocious damage."
	icon_state = "hearse_shield"
	icon = 'icons/obj/limbus_weapons.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/limbus_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/limbus_righthand.dmi'
	force = 40
	damtype = WHITE_DAMAGE

	attack_verb_continuous = list("shoves", "bashes")
	attack_verb_simple = list("shove", "bash")
	hitsound = 'sound/weapons/genhit2.ogg'
	reductions = list(40, 20, 30, 0) // 90
	projectile_block_duration = 3 SECONDS
	block_duration = 3 SECONDS
	block_cooldown = 3 SECONDS
	block_sound_volume = 30

/obj/item/ego_weapon/raskolot //horn but a boomerang
	name = "raskolot"
	desc = "If only she could forget everything and begin afresh."
	icon_state = "raskolot"
	icon = 'icons/obj/limbus_weapons.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/limbus_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/limbus_righthand.dmi'
	force = 22
	throwforce = 30
	throw_speed = 1
	throw_range = 7
	damtype = RED_DAMAGE

	hitsound = 'sound/weapons/ego/axe2.ogg'

/obj/item/ego_weapon/raskolot/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/caught = hit_atom.hitby(src, FALSE, FALSE, throwingdatum=throwingdatum)
	if(thrownby && !caught)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, throw_at), thrownby, throw_range+2, throw_speed, null, TRUE), 1)
	if(caught)
		return
	else
		return ..()

/obj/item/ego_weapon/vogel
	name = "vogel"
	desc = "The world of evil had begun there, right in the middle of our house."
	icon_state = "vogel"
	icon = 'icons/obj/limbus_weapons.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/limbus_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/limbus_righthand.dmi'
	force = 22
	reach = 2		//Has 2 Square Reach.
	attack_speed = 1.2
	damtype = RED_DAMAGE

	attack_verb_continuous = list("pokes", "jabs", "tears", "lacerates", "gores")
	attack_verb_simple = list("poke", "jab", "tear", "lacerate", "gore")
	hitsound = 'sound/weapons/ego/axe2.ogg'

/obj/item/ego_weapon/nobody
	name = "nobody"
	desc = "I am nothing at all."
	special = "This E.G.O. functions as both a gun and a melee weapon."
	icon_state = "nobody"
	icon = 'icons/obj/limbus_weapons.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/limbus_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/limbus_righthand.dmi'
	force = 19
	damtype = RED_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP

	attack_speed = 0.8
	attack_verb_continuous = list("cuts", "slices")
	attack_verb_simple = list("cuts", "slices")
	hitsound = 'sound/weapons/ego/sword2.ogg'

	var/gun_cooldown
	var/blademark_cooldown
	var/gunmark_cooldown
	var/gun_cooldown_time = 1.2 SECONDS

/obj/item/ego_weapon/nobody/Initialize()
	RegisterSignal(src, COMSIG_PROJECTILE_ON_HIT, PROC_REF(projectile_hit))
	return ..()

/obj/item/ego_weapon/nobody/afterattack(atom/target, mob/living/user, proximity_flag, clickparams)
	if(!CanUseEgo(user))
		return
	if(!proximity_flag && gun_cooldown <= world.time)
		var/turf/proj_turf = user.loc
		if(!isturf(proj_turf))
			return
		var/obj/projectile/ego_bullet/nobody/G = new /obj/projectile/ego_bullet/nobody(proj_turf)
		G.fired_from = src //for signal check
		playsound(user, 'sound/weapons/gun/shotgun/shot_alt.ogg', 100, TRUE)
		G.firer = user
		G.preparePixelProjectile(target, user, clickparams)
		G.fire()
		gun_cooldown = world.time + gun_cooldown_time
		return

/obj/item/ego_weapon/nobody/proc/projectile_hit(atom/fired_from, atom/movable/firer, atom/target, Angle)
	SIGNAL_HANDLER
	return TRUE

/obj/projectile/ego_bullet/nobody
	name = "gunblade bullet"
	damage = 20
	damage_type = RED_DAMAGE


/obj/item/ego_weapon/ungezifer
	name = "ungezifer"
	desc = "As I awoke one morning from uneasy dreams I found myself transformed in my bed into a gigantic insect."
	icon_state = "ungezifer"
	icon = 'icons/obj/limbus_weapons.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/limbus_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/limbus_righthand.dmi'
	force = 38				//Lots of damage, way less DPS
	damtype = BLACK_DAMAGE

	attack_speed = 2 // Really Slow
	attack_verb_continuous = list("smashes", "bludgeons", "crushes")
	attack_verb_simple = list("smash", "bludgeon", "crush")
	hitsound = 'sound/weapons/ego/justitia2.ogg'
