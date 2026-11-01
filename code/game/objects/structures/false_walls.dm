/*
 * False Walls
 */
/obj/structure/falsewall
	name = "wall"
	desc = "A huge chunk of metal used to separate rooms."
	anchored = TRUE
	icon = 'icons/turf/walls/wall.dmi'
	icon_state = "wall-0"
	base_icon_state = "wall"
	layer = LOW_OBJ_LAYER
	density = TRUE
	opacity = TRUE
	max_integrity = 100
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_CLOSED_TURFS, SMOOTH_GROUP_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_WALLS)
	can_be_unanchored = FALSE
	// CanAtmosPass = ATMOS_PASS_DENSITY
	flags_1 = RAD_PROTECT_CONTENTS_1 | RAD_NO_CONTAMINATE_1
	rad_insulation = RAD_MEDIUM_INSULATION
	var/mineral = /obj/item/stack/sheet/metal
	var/mineral_amount = 2
	var/walltype = /turf/closed/wall
	var/girder_type = /obj/structure/girder/displaced
	var/opening = FALSE
	/// Stem for the open and travel frames inside icon. A sheet that carries
	/// more than one wall look needs a prefix here or its sets collide.
	var/fwall_state = "fwall"


/* /obj/structure/falsewall/Initialize()
	. = ..()
	air_update_turf(TRUE, TRUE) */

/obj/structure/falsewall/attack_hand(mob/user)
	if(opening)
		return
	. = ..()
	if(.)
		return

	opening = TRUE
	update_icon()
	if(!density)
		var/srcturf = get_turf(src)
		for(var/mob/living/obstacle in srcturf) //Stop people from using this as a shield
			opening = FALSE
			return
	addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/structure/falsewall, toggle_open)), 5)

/obj/structure/falsewall/proc/toggle_open()
	if(!QDELETED(src))
		density = !density
		set_opacity(density)
		opening = FALSE
		update_icon()
		// air_update_turf(TRUE, !density)

/obj/structure/falsewall/update_icon()//Calling icon_update will refresh the smoothwalls if it's closed, otherwise it will make sure the icon is correct if it's open
	if(opening)
		if(density)
			icon_state = "[fwall_state]_opening"
			smoothing_flags = NONE
			clear_smooth_overlays()
		else
			icon_state = "[fwall_state]_closing"
	else
		if(density)
			icon_state = "[base_icon_state]-[smoothing_junction]"
			smoothing_flags = SMOOTH_BITMASK
			QUEUE_SMOOTH(src)
		else
			icon_state = "[fwall_state]_open"

/obj/structure/falsewall/proc/ChangeToWall(delete = 1)
	var/turf/T = get_turf(src)
	T.PlaceOnTop(walltype)
	if(delete)
		qdel(src)
	return T

/obj/structure/falsewall/attackby(obj/item/W, mob/user, params)
	if(opening)
		to_chat(user, span_warning("You must wait until the door has stopped moving!"))
		return

	if(W.tool_behaviour == TOOL_SCREWDRIVER)
		if(density)
			var/turf/T = get_turf(src)
			if(T.density)
				to_chat(user, span_warning("[src] is blocked!"))
				return
			if(!isfloorturf(T))
				to_chat(user, span_warning("[src] bolts must be tightened on the floor!"))
				return
			user.visible_message(span_notice("[user] tightens some bolts on the wall."), span_notice("You tighten the bolts on the wall."))
			ChangeToWall()
		else
			to_chat(user, span_warning("You can't reach, close it first!"))

	else if(W.tool_behaviour == TOOL_WELDER)
		if(W.use_tool(src, user, 0, volume=50))
			dismantle(user, TRUE)
	else
		return ..()

/obj/structure/falsewall/proc/dismantle(mob/user, disassembled=TRUE, obj/item/tool = null)
	user.visible_message(span_notice("[user] dismantles the false wall."), span_notice("You dismantle the false wall."))
	if(tool)
		tool.play_tool_sound(src, 100)
	else
		playsound(src, 'sound/items/welder.ogg', 100, TRUE)
	deconstruct(disassembled)

/obj/structure/falsewall/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(disassembled)
			new girder_type(loc)
		if(mineral_amount)
			for(var/i in 1 to mineral_amount)
				new mineral(loc)
	qdel(src)

/obj/structure/falsewall/get_dumping_location(obj/item/storage/source,mob/user)
	return null

/obj/structure/falsewall/examine_status(mob/user) //So you can't detect falsewalls by examine.
	to_chat(user, span_notice("The outer plating is <b>welded</b> firmly in place."))
	return null

/*
 * False R-Walls
 */

/obj/structure/falsewall/reinforced
	name = "reinforced wall"
	desc = "A huge chunk of reinforced metal used to separate rooms."
	icon = 'icons/turf/walls/reinforced_wall.dmi'
	icon_state = "reinforced_wall-0"
	base_icon_state = "reinforced_wall"
	walltype = /turf/closed/wall/r_wall
	mineral = /obj/item/stack/sheet/plasteel
	smoothing_flags = SMOOTH_BITMASK

/obj/structure/falsewall/reinforced/examine_status(mob/user)
	to_chat(user, span_notice("The outer <b>grille</b> is fully intact."))
	return null

/obj/structure/falsewall/reinforced/attackby(obj/item/tool, mob/user)
	..()
	if(tool.tool_behaviour == TOOL_WIRECUTTER)
		dismantle(user, TRUE, tool)

/*
 * Uranium Falsewalls
 */

/obj/structure/falsewall/uranium
	name = "uranium wall"
	desc = "A wall with uranium plating. This is probably a bad idea."
	icon = 'icons/turf/walls/uranium_wall.dmi'
	icon_state = "uranium_wall-0"
	base_icon_state = "uranium_wall"
	mineral = /obj/item/stack/sheet/mineral/uranium
	walltype = /turf/closed/wall/mineral/uranium
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_URANIUM_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_URANIUM_WALLS)
	var/active = null
	var/last_event = 0

/obj/structure/falsewall/uranium/attackby(obj/item/W, mob/user, params)
	radiate()
	return ..()

/obj/structure/falsewall/uranium/attack_hand(mob/user)
	radiate()
	. = ..()

/obj/structure/falsewall/uranium/proc/radiate()
	if(!active)
		if(world.time > last_event+15)
			active = 1
			radiation_pulse(src, 150)
			for(var/turf/closed/wall/mineral/uranium/T in orange(1,src))
				T.radiate()
			last_event = world.time
			active = null
			return
	return
/*
 * Other misc falsewall types
 */

/obj/structure/falsewall/gold
	name = "gold wall"
	desc = "A wall with gold plating. Swag!"
	icon = 'icons/turf/walls/gold_wall.dmi'
	icon_state = "gold_wall-0"
	base_icon_state = "gold_wall"
	mineral = /obj/item/stack/sheet/mineral/gold
	walltype = /turf/closed/wall/mineral/gold
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_GOLD_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_GOLD_WALLS)

/obj/structure/falsewall/silver
	name = "silver wall"
	desc = "A wall with silver plating. Shiny."
	icon = 'icons/turf/walls/silver_wall.dmi'
	icon_state = "silver_wall-0"
	base_icon_state = "silver_wall"
	mineral = /obj/item/stack/sheet/mineral/silver
	walltype = /turf/closed/wall/mineral/silver
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_SILVER_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_SILVER_WALLS)

/obj/structure/falsewall/diamond
	name = "diamond wall"
	desc = "A wall with diamond plating. You monster."
	icon = 'icons/turf/walls/diamond_wall.dmi'
	icon_state = "diamond_wall-0"
	base_icon_state = "diamond_wall"
	mineral = /obj/item/stack/sheet/mineral/diamond
	walltype = /turf/closed/wall/mineral/diamond
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_DIAMOND_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_DIAMOND_WALLS)
	max_integrity = 800

/obj/structure/falsewall/plasma
	name = "plasma wall"
	desc = "A wall with plasma plating. This is definitely a bad idea."
	icon = 'icons/turf/walls/plasma_wall.dmi'
	icon_state = "plasma_wall-0"
	base_icon_state = "plasma_wall"
	mineral = /obj/item/stack/sheet/mineral/plasma
	walltype = /turf/closed/wall/mineral/plasma
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_PLASMA_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_PLASMA_WALLS)

/* /obj/structure/falsewall/plasma/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/atmos_sensitive) */

/obj/structure/falsewall/plasma/attackby(obj/item/W, mob/user, params)
	if(W.get_temperature())
		var/turf/T = get_turf(src)
		message_admins("Plasma falsewall ignited by [ADMIN_LOOKUPFLW(user)] in [ADMIN_VERBOSEJMP(T)]")
		log_game("Plasma falsewall ignited by [key_name(user)] in [AREACOORD(T)]")
		playsound(src, 'sound/items/welder.ogg', 100, TRUE)
		explosion(T, 0, 0, 5, 8, flame_range = 2)
		new /obj/structure/girder/displaced(loc)
		qdel(src)

/* /obj/structure/falsewall/plasma/should_atmos_process(datum/gas_mixture/air, exposed_temperature)
	return exposed_temperature > 300

/obj/structure/falsewall/plasma/atmos_expose(datum/gas_mixture/air, exposed_temperature)
	burnbabyburn()

/obj/structure/falsewall/plasma/proc/burnbabyburn(user)
	playsound(src, 'sound/items/welder.ogg', 100, TRUE)
	explosion(target_turf, 0, 0, 5, 8, flame_range = 2)
	new /obj/structure/girder/displaced(loc)
	qdel(src)
*/
/obj/structure/falsewall/bananium
	name = "bananium wall"
	desc = "A wall with bananium plating. Honk!"
	icon = 'icons/turf/walls/bananium_wall.dmi'
	icon_state = "bananium_wall-0"
	base_icon_state = "bananium_wall"
	mineral = /obj/item/stack/sheet/mineral/bananium
	walltype = /turf/closed/wall/mineral/bananium
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_BANANIUM_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_BANANIUM_WALLS)


/obj/structure/falsewall/sandstone
	name = "sandstone wall"
	desc = "A wall with sandstone plating. Rough."
	icon = 'icons/turf/walls/sandstone_wall.dmi'
	icon_state = "sandstone_wall-0"
	base_icon_state = "sandstone_wall"
	mineral = /obj/item/stack/sheet/mineral/sandstone
	walltype = /turf/closed/wall/mineral/sandstone
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_SANDSTONE_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_SANDSTONE_WALLS)

/obj/structure/falsewall/wood
	name = "wooden wall"
	desc = "A wall with wooden plating. Stiff."
	icon = 'icons/turf/walls/wood_wall.dmi'
	icon_state = "wood_wall-0"
	base_icon_state = "wood_wall"
	mineral = /obj/item/stack/sheet/mineral/wood
	walltype = /turf/closed/wall/mineral/wood
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_WOOD_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_WOOD_WALLS)

/obj/structure/falsewall/iron
	name = "rough metal wall"
	desc = "A wall with rough metal plating."
	icon = 'icons/turf/walls/iron_wall.dmi'
	icon_state = "iron_wall-0"
	base_icon_state = "iron_wall"
	mineral = /obj/item/stack/rods
	mineral_amount = 5
	walltype = /turf/closed/wall/mineral/iron
	base_icon_state = "iron_wall"
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_IRON_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_IRON_WALLS)

/obj/structure/falsewall/abductor
	name = "alien wall"
	desc = "A wall with alien alloy plating."
	icon = 'icons/turf/walls/abductor_wall.dmi'
	icon_state = "abductor_wall-0"
	base_icon_state = "abductor_wall"
	mineral = /obj/item/stack/sheet/mineral/abductor
	walltype = /turf/closed/wall/mineral/abductor
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_ABDUCTOR_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_ABDUCTOR_WALLS)

/obj/structure/falsewall/titanium
	name = "wall"
	desc = "A light-weight titanium wall used in shuttles."
	icon = 'icons/turf/walls/shuttle_wall.dmi'
	icon_state = "shuttle_wall-0"
	base_icon_state = "shuttle_wall"
	mineral = /obj/item/stack/sheet/mineral/titanium
	walltype = /turf/closed/wall/mineral/titanium
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_TITANIUM_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_TITANIUM_WALLS, SMOOTH_GROUP_AIRLOCK, SMOOTH_GROUP_SHUTTLE_PARTS)

/obj/structure/falsewall/plastitanium
	name = "wall"
	desc = "An evil wall of plasma and titanium."
	icon = 'icons/turf/walls/plastitanium_wall.dmi'
	icon_state = "plastitanium_wall-0"
	base_icon_state = "plastitanium_wall"
	mineral = /obj/item/stack/sheet/mineral/plastitanium
	walltype = /turf/closed/wall/mineral/plastitanium
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_PLASTITANIUM_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_PLASTITANIUM_WALLS, SMOOTH_GROUP_AIRLOCK, SMOOTH_GROUP_SHUTTLE_PARTS)

// City stock.

/obj/structure/falsewall/city/concrete
	name = "concrete wall"
	desc = "Poured concrete, patched and repatched. Water has run down it for \
		long enough to leave its own map."
	icon = 'icons/turf/walls/city_concrete.dmi'
	icon_state = "concrete-0"
	base_icon_state = "concrete"
	walltype = /turf/closed/wall/city/concrete

/obj/structure/falsewall/city/plank
	name = "plank wall"
	desc = "Weathered board siding, silvered by rain and sprung loose in places. \
		You can see daylight between some of them."
	icon = 'icons/turf/walls/city_plank.dmi'
	icon_state = "plank-0"
	base_icon_state = "plank"
	mineral = /obj/item/stack/sheet/mineral/wood
	walltype = /turf/closed/wall/city/plank

/obj/structure/falsewall/city/stone
	name = "stone wall"
	desc = "Rough masonry, laid by hand and never squared off. The mortar has gone \
		to powder in the joints."
	icon = 'icons/turf/walls/city_stone.dmi'
	icon_state = "stone-0"
	base_icon_state = "stone"
	walltype = /turf/closed/wall/city/stone

/obj/structure/falsewall/city/render
	name = "rendered wall"
	desc = "Render sheeting away from the brick beneath it in long ragged patches. \
		Nobody is coming to repair it."
	icon = 'icons/turf/walls/city_render.dmi'
	icon_state = "render-0"
	base_icon_state = "render"
	walltype = /turf/closed/wall/city/render

/obj/structure/falsewall/city/timber
	name = "timber-framed wall"
	desc = "Dark structural beams with plaster panelled between them. The brace has \
		taken on a lean it was never meant to have."
	icon = 'icons/turf/walls/city_timber.dmi'
	icon_state = "timber-0"
	base_icon_state = "timber"
	mineral = /obj/item/stack/sheet/mineral/wood
	walltype = /turf/closed/wall/city/timber

/obj/structure/falsewall/city/boarded
	name = "boarded wall"
	desc = "A plank wall sealed over with battens, nailed on in a hurry and never \
		taken down. Whatever was behind it stayed there."
	icon = 'icons/turf/walls/city_boarded.dmi'
	icon_state = "boarded-0"
	base_icon_state = "boarded"
	mineral = /obj/item/stack/sheet/mineral/wood
	walltype = /turf/closed/wall/city/boarded

/obj/structure/falsewall/city/panel
	name = "panel wall"
	desc = "Precast cladding on a concrete frame, joints picked out in grime. \
		Somebody upstairs still pays for this address."
	icon = 'icons/turf/walls/city_panel.dmi'
	icon_state = "panel-0"
	base_icon_state = "panel"
	walltype = /turf/closed/wall/city/panel

/obj/structure/falsewall/city/redbrick
	name = "red brick wall"
	desc = "Fired red brick, laid in a running bond. The mortar has been repointed \
		so many times it is half a different wall."
	icon = 'icons/turf/walls/city_redbrick.dmi'
	icon_state = "redbrick-0"
	base_icon_state = "redbrick"
	walltype = /turf/closed/wall/city/redbrick

/obj/structure/falsewall/city/oldstone
	name = "old stone wall"
	desc = "Pale dressed stone, the capping course scrubbed white by rain. It \
		predates most of the district standing on it."
	icon = 'icons/turf/walls/city_oldstone.dmi'
	icon_state = "oldstone-0"
	base_icon_state = "oldstone"
	walltype = /turf/closed/wall/city/oldstone

/obj/structure/falsewall/city/corrugated
	name = "corrugated wall"
	desc = "Ribbed sheet bolted over a frame. It drums in the wind and rusts from \
		the bottom up."
	icon = 'icons/turf/walls/city_corrugated.dmi'
	icon_state = "corrugated-0"
	base_icon_state = "corrugated"
	walltype = /turf/closed/wall/city/corrugated

/obj/structure/falsewall/city/cityblock
	name = "block wall"
	desc = "Municipal blockwork in the old civic green, banded with a tan capping. \
		Put up by an authority that no longer maintains it."
	icon = 'icons/turf/walls/city_cityblock.dmi'
	icon_state = "cityblock-0"
	base_icon_state = "cityblock"
	walltype = /turf/closed/wall/city/cityblock

/obj/structure/falsewall/city/richpanel
	name = "panelled wall"
	desc = "Cream panelling over a dark ground, joints picked out in shadow. \
		Somebody upstairs still pays for the address."
	icon = 'icons/turf/walls/city_richpanel.dmi'
	icon_state = "richpanel-0"
	base_icon_state = "richpanel"
	walltype = /turf/closed/wall/city/richpanel

/obj/structure/falsewall/city/scrapwall
	name = "scrap wall"
	desc = "Mismatched plate riveted over whatever was already there. Every panel \
		came off something else."
	icon = 'icons/turf/walls/city_scrapwall.dmi'
	icon_state = "scrapwall-0"
	base_icon_state = "scrapwall"
	walltype = /turf/closed/wall/city/scrapwall

/obj/structure/falsewall/city/ironplate
	name = "iron plate wall"
	desc = "Riveted steel panel over a frame. Someone has been painting over \
		the rust rather than dealing with it."
	icon = 'icons/turf/walls/city_ironplate.dmi'
	icon_state = "ironplate-0"
	base_icon_state = "ironplate"
	walltype = /turf/closed/wall/city/ironplate

/obj/structure/falsewall/city/boiler
	name = "boiler plate wall"
	desc = "Lapped strakes and a forest of rivets, still warm to the back of \
		your hand."
	icon = 'icons/turf/walls/city_boiler.dmi'
	icon_state = "boiler-0"
	base_icon_state = "boiler"
	walltype = /turf/closed/wall/city/boiler

/obj/structure/falsewall/city/sootbrick
	name = "sooted brick wall"
	desc = "Brick blacked by decades of flue smoke. It comes off on anything \
		that touches it."
	icon = 'icons/turf/walls/city_sootbrick.dmi'
	icon_state = "sootbrick-0"
	base_icon_state = "sootbrick"
	walltype = /turf/closed/wall/city/sootbrick

/obj/structure/falsewall/city/glazedtile
	name = "glazed tile wall"
	desc = "Green glazed brick, laid when this place was meant to be kept \
		clean. The grout has gone black."
	icon = 'icons/turf/walls/city_glazedtile.dmi'
	icon_state = "glazedtile-0"
	base_icon_state = "glazedtile"
	walltype = /turf/closed/wall/city/glazedtile

/obj/structure/falsewall/city/conduit
	name = "conduit wall"
	desc = "Pipe runs strapped down the face of it, every one of them going \
		somewhere you are not cleared for."
	icon = 'icons/turf/walls/city_conduit.dmi'
	icon_state = "conduit-0"
	base_icon_state = "conduit"
	walltype = /turf/closed/wall/city/conduit

/obj/structure/falsewall/city/breezeblock
	name = "block wall"
	desc = "Cast concrete block, laid fast and never faced. Back of house, \
		and it shows."
	icon = 'icons/turf/walls/city_breezeblock.dmi'
	icon_state = "breezeblock-0"
	base_icon_state = "breezeblock"
	walltype = /turf/closed/wall/city/breezeblock

/obj/structure/falsewall/city/container
	name = "container wall"
	desc = "The corrugated flank of a shipping container, welded into place and \
		lived in. Somebody has bolted a light fitting to it."
	icon = 'icons/turf/walls/container.dmi'
	icon_state = "container-0"
	base_icon_state = "container"
	walltype = /turf/closed/wall/container

// Imitating walls that cannot themselves be broken, so screwing one down hands
// the mapper's indestructible turf back rather than a breakable copy.

/obj/structure/falsewall/city/facility
	name = "reinforced wall"
	desc = "A huge chunk of reinforced metal used to separate rooms. Effectively impervious to conventional methods of destruction."
	icon = 'icons/turf/walls/facility.dmi'
	icon_state = "facility-0"
	base_icon_state = "facility"
	walltype = /turf/closed/indestructible/reinforced

/obj/structure/falsewall/city/facility_old
	name = "reinforced wall"
	desc = "A huge chunk of reinforced metal used to separate rooms. Effectively impervious to conventional methods of destruction."
	icon = 'icons/turf/walls/facility_old.dmi'
	icon_state = "facility-0"
	base_icon_state = "facility"
	walltype = /turf/closed/indestructible/reinforced/old

/obj/structure/falsewall/city/cheap
	name = "reinforced wall"
	desc = "A huge chunk of reinforced metal used to separate rooms. Effectively impervious to conventional methods of destruction."
	icon = 'icons/turf/walls/cheap_wall.dmi'
	icon_state = "icon-0"
	base_icon_state = "icon"
	walltype = /turf/closed/indestructible/reinforced/cheap

/obj/structure/falsewall/city/cheap_blue
	name = "reinforced wall"
	desc = "A huge chunk of reinforced metal used to separate rooms. Effectively impervious to conventional methods of destruction."
	icon = 'icons/turf/walls/blue_wall.dmi'
	icon_state = "icon-0"
	base_icon_state = "icon"
	walltype = /turf/closed/indestructible/reinforced/cheap/blue

/obj/structure/falsewall/city/cheap_brown
	name = "reinforced wall"
	desc = "A huge chunk of reinforced metal used to separate rooms. Effectively impervious to conventional methods of destruction."
	icon = 'icons/turf/walls/brown_wall.dmi'
	icon_state = "icon-0"
	base_icon_state = "icon"
	walltype = /turf/closed/indestructible/reinforced/cheap/brown

/obj/structure/falsewall/city/cheap_cream
	name = "reinforced wall"
	desc = "A huge chunk of reinforced metal used to separate rooms. Effectively impervious to conventional methods of destruction."
	icon = 'icons/turf/walls/cream_wall.dmi'
	icon_state = "icon-0"
	base_icon_state = "icon"
	walltype = /turf/closed/indestructible/reinforced/cheap/cream

/obj/structure/falsewall/city/cheap_green
	name = "reinforced wall"
	desc = "A huge chunk of reinforced metal used to separate rooms. Effectively impervious to conventional methods of destruction."
	icon = 'icons/turf/walls/green_wall.dmi'
	icon_state = "icon-0"
	base_icon_state = "icon"
	walltype = /turf/closed/indestructible/reinforced/cheap/green

/obj/structure/falsewall/city/cheap_purple
	name = "reinforced wall"
	desc = "A huge chunk of reinforced metal used to separate rooms. Effectively impervious to conventional methods of destruction."
	icon = 'icons/turf/walls/purple_wall.dmi'
	icon_state = "icon-0"
	base_icon_state = "icon"
	walltype = /turf/closed/indestructible/reinforced/cheap/purple

/obj/structure/falsewall/city/cheap_red
	name = "reinforced wall"
	desc = "A huge chunk of reinforced metal used to separate rooms. Effectively impervious to conventional methods of destruction."
	icon = 'icons/turf/walls/red_wall.dmi'
	icon_state = "icon-0"
	base_icon_state = "icon"
	walltype = /turf/closed/indestructible/reinforced/cheap/red

/obj/structure/falsewall/city/cheap_fancy
	name = "reinforced wall"
	desc = "A huge chunk of reinforced metal used to separate rooms. Effectively impervious to conventional methods of destruction."
	icon = 'icons/turf/walls/fancy_wall.dmi'
	icon_state = "icon-0"
	base_icon_state = "icon"
	walltype = /turf/closed/indestructible/reinforced/cheap/fancy

/obj/structure/falsewall/city/cheap_yellow
	name = "reinforced wall"
	desc = "A huge chunk of reinforced metal used to separate rooms. Effectively impervious to conventional methods of destruction."
	icon = 'icons/turf/walls/yellow_wall.dmi'
	icon_state = "icon-0"
	base_icon_state = "icon"
	walltype = /turf/closed/indestructible/reinforced/cheap/yellow

// Seven wall looks share lce_map_turfs.dmi, so each needs its own state stem.

/obj/structure/falsewall/city/lce_wall
	name = "LCE corridor wall"
	desc = "A heavy panelled wall in Limbus Company house brown. The recessed plate is thick \
		enough to hide the conduit runs behind it."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_map/lce_map_turfs.dmi'
	icon_state = "lce_wall-0"
	base_icon_state = "lce_wall"
	fwall_state = "lce_wall_fwall"
	walltype = /turf/closed/indestructible/reinforced/cheap/lce

/obj/structure/falsewall/city/lce_wall_dark
	name = "unlit LCE corridor wall"
	desc = "A heavy panelled wall in Limbus Company house brown. The recessed plate is thick \
		enough to hide the conduit runs behind it."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_map/lce_map_turfs.dmi'
	icon_state = "lce_wall_dark-0"
	base_icon_state = "lce_wall_dark"
	fwall_state = "lce_wall_dark_fwall"
	walltype = /turf/closed/indestructible/reinforced/cheap/lce/dark

/obj/structure/falsewall/city/lce_wall_bright
	name = "lit LCE corridor wall"
	desc = "A heavy panelled wall in Limbus Company house brown. The recessed plate is thick \
		enough to hide the conduit runs behind it."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_map/lce_map_turfs.dmi'
	icon_state = "lce_wall_bright-0"
	base_icon_state = "lce_wall_bright"
	fwall_state = "lce_wall_bright_fwall"
	walltype = /turf/closed/indestructible/reinforced/cheap/lce/bright

/obj/structure/falsewall/city/lce_wall_alarm
	name = "restricted LCE corridor wall"
	desc = "A heavy panelled wall. The trim is painted the red that means do not pass this point."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_map/lce_map_turfs.dmi'
	icon_state = "lce_wall_alarm-0"
	base_icon_state = "lce_wall_alarm"
	fwall_state = "lce_wall_alarm_fwall"
	walltype = /turf/closed/indestructible/reinforced/cheap/lce/alarm

/obj/structure/falsewall/city/lce_panel
	name = "LCE panel wall"
	desc = "A flat inset panel wall, the kind used where the rooms have to be kept clean."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_map/lce_map_turfs.dmi'
	icon_state = "lce_panel-0"
	base_icon_state = "lce_panel"
	fwall_state = "lce_panel_fwall"
	walltype = /turf/closed/indestructible/reinforced/lce_panel

/obj/structure/falsewall/city/lce_panel_dark
	name = "unlit LCE panel wall"
	desc = "A flat inset panel wall, the kind used where the rooms have to be kept clean."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_map/lce_map_turfs.dmi'
	icon_state = "lce_panel_dark-0"
	base_icon_state = "lce_panel_dark"
	fwall_state = "lce_panel_dark_fwall"
	walltype = /turf/closed/indestructible/reinforced/lce_panel/dark

/obj/structure/falsewall/city/lce_service
	name = "LCE service wall"
	desc = "Riveted structural plate, left bare. Nobody was expected to see this side of it."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_map/lce_map_turfs.dmi'
	icon_state = "lce_rivet-0"
	base_icon_state = "lce_rivet"
	fwall_state = "lce_rivet_fwall"
	walltype = /turf/closed/indestructible/reinforced/lce_service

// The syndicate wall already has hand drawn frames in its own sheet.

/obj/structure/falsewall/city/syndicate
	name = "wall"
	desc = "Effectively impervious to conventional methods of destruction."
	icon = 'icons/turf/walls/plastitanium_wall.dmi'
	icon_state = "plastitanium_wall-0"
	base_icon_state = "plastitanium_wall"
	mineral = /obj/item/stack/sheet/mineral/plastitanium
	walltype = /turf/closed/indestructible/syndicate
