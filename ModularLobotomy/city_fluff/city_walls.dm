/turf/closed/indestructible/city
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_CLOSED_TURFS, SMOOTH_GROUP_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_WALLS)

// ------------------------------------------------------------------------
// Standing City stock.

/turf/closed/wall/city/concrete
	name = "concrete wall"
	desc = "Poured concrete, patched and repatched. Water has run down it for \
		long enough to leave its own map."
	icon = 'icons/turf/walls/city_concrete.dmi'
	icon_state = "concrete-0"
	base_icon_state = "concrete"
	baseturfs = /turf/open/floor/plating
	sheet_type = /obj/item/stack/sheet/metal
	sheet_amount = 2
	hardness = 25

/turf/closed/indestructible/city/concrete
	name = "concrete wall"
	desc = "Poured concrete, thick enough that nobody in this district is \
		getting through it."
	icon = 'icons/turf/walls/city_concrete.dmi'
	icon_state = "concrete-0"
	base_icon_state = "concrete"

/turf/closed/wall/city/plank
	name = "plank wall"
	desc = "Weathered board siding, silvered by rain and sprung loose in places. \
		You can see daylight between some of them."
	icon = 'icons/turf/walls/city_plank.dmi'
	icon_state = "plank-0"
	base_icon_state = "plank"
	baseturfs = /turf/open/floor/plating
	hardness = 20

/turf/closed/indestructible/city/plank
	name = "plank wall"
	desc = "Weathered board siding, silvered by rain and sprung loose in places. \
		You can see daylight between some of them."
	icon = 'icons/turf/walls/city_plank.dmi'
	icon_state = "plank-0"
	base_icon_state = "plank"

/turf/closed/wall/city/stone
	name = "stone wall"
	desc = "Rough masonry, laid by hand and never squared off. The mortar has gone \
		to powder in the joints."
	icon = 'icons/turf/walls/city_stone.dmi'
	icon_state = "stone-0"
	base_icon_state = "stone"
	baseturfs = /turf/open/floor/plating
	hardness = 45

/turf/closed/indestructible/city/stone
	name = "stone wall"
	desc = "Rough masonry, laid by hand and never squared off. The mortar has gone \
		to powder in the joints."
	icon = 'icons/turf/walls/city_stone.dmi'
	icon_state = "stone-0"
	base_icon_state = "stone"

/turf/closed/wall/city/render
	name = "rendered wall"
	desc = "Render sheeting away from the brick beneath it in long ragged patches. \
		Nobody is coming to repair it."
	icon = 'icons/turf/walls/city_render.dmi'
	icon_state = "render-0"
	base_icon_state = "render"
	baseturfs = /turf/open/floor/plating
	hardness = 30

/turf/closed/indestructible/city/render
	name = "rendered wall"
	desc = "Render sheeting away from the brick beneath it in long ragged patches. \
		Nobody is coming to repair it."
	icon = 'icons/turf/walls/city_render.dmi'
	icon_state = "render-0"
	base_icon_state = "render"

/turf/closed/wall/city/timber
	name = "timber-framed wall"
	desc = "Dark structural beams with plaster panelled between them. The brace has \
		taken on a lean it was never meant to have."
	icon = 'icons/turf/walls/city_timber.dmi'
	icon_state = "timber-0"
	base_icon_state = "timber"
	baseturfs = /turf/open/floor/plating
	hardness = 25

/turf/closed/indestructible/city/timber
	name = "timber-framed wall"
	desc = "Dark structural beams with plaster panelled between them. The brace has \
		taken on a lean it was never meant to have."
	icon = 'icons/turf/walls/city_timber.dmi'
	icon_state = "timber-0"
	base_icon_state = "timber"

/turf/closed/wall/city/boarded
	name = "boarded wall"
	desc = "A plank wall sealed over with battens, nailed on in a hurry and never \
		taken down. Whatever was behind it stayed there."
	icon = 'icons/turf/walls/city_boarded.dmi'
	icon_state = "boarded-0"
	base_icon_state = "boarded"
	baseturfs = /turf/open/floor/plating
	hardness = 22

/turf/closed/indestructible/city/boarded
	name = "boarded wall"
	desc = "A plank wall sealed over with battens, nailed on in a hurry and never \
		taken down. Whatever was behind it stayed there."
	icon = 'icons/turf/walls/city_boarded.dmi'
	icon_state = "boarded-0"
	base_icon_state = "boarded"

/turf/closed/wall/city/panel
	name = "panel wall"
	desc = "Precast cladding on a concrete frame, joints picked out in grime. \
		Somebody upstairs still pays for this address."
	icon = 'icons/turf/walls/city_panel.dmi'
	icon_state = "panel-0"
	base_icon_state = "panel"
	baseturfs = /turf/open/floor/plating
	hardness = 40

/turf/closed/indestructible/city/panel
	name = "panel wall"
	desc = "Precast cladding on a concrete frame, joints picked out in grime. \
		Somebody upstairs still pays for this address."
	icon = 'icons/turf/walls/city_panel.dmi'
	icon_state = "panel-0"
	base_icon_state = "panel"

// A second set, textured after the WoD13 sheet

/turf/closed/wall/city/redbrick
	name = "red brick wall"
	desc = "Fired red brick, laid in a running bond. The mortar has been repointed \
		so many times it is half a different wall."
	icon = 'icons/turf/walls/city_redbrick.dmi'
	icon_state = "redbrick-0"
	base_icon_state = "redbrick"
	baseturfs = /turf/open/floor/plating
	hardness = 35

/turf/closed/indestructible/city/redbrick
	name = "red brick wall"
	desc = "Fired red brick, laid in a running bond. The mortar has been repointed \
		so many times it is half a different wall."
	icon = 'icons/turf/walls/city_redbrick.dmi'
	icon_state = "redbrick-0"
	base_icon_state = "redbrick"

/turf/closed/wall/city/oldstone
	name = "old stone wall"
	desc = "Pale dressed stone, the capping course scrubbed white by rain. It \
		predates most of the district standing on it."
	icon = 'icons/turf/walls/city_oldstone.dmi'
	icon_state = "oldstone-0"
	base_icon_state = "oldstone"
	baseturfs = /turf/open/floor/plating
	hardness = 50

/turf/closed/indestructible/city/oldstone
	name = "old stone wall"
	desc = "Pale dressed stone, the capping course scrubbed white by rain. It \
		predates most of the district standing on it."
	icon = 'icons/turf/walls/city_oldstone.dmi'
	icon_state = "oldstone-0"
	base_icon_state = "oldstone"

/turf/closed/wall/city/corrugated
	name = "corrugated wall"
	desc = "Ribbed sheet bolted over a frame. It drums in the wind and rusts from \
		the bottom up."
	icon = 'icons/turf/walls/city_corrugated.dmi'
	icon_state = "corrugated-0"
	base_icon_state = "corrugated"
	baseturfs = /turf/open/floor/plating
	hardness = 18

/turf/closed/indestructible/city/corrugated
	name = "corrugated wall"
	desc = "Ribbed sheet bolted over a frame. It drums in the wind and rusts from \
		the bottom up."
	icon = 'icons/turf/walls/city_corrugated.dmi'
	icon_state = "corrugated-0"
	base_icon_state = "corrugated"

/turf/closed/wall/city/cityblock
	name = "block wall"
	desc = "Municipal blockwork in the old civic green, banded with a tan capping. \
		Put up by an authority that no longer maintains it."
	icon = 'icons/turf/walls/city_cityblock.dmi'
	icon_state = "cityblock-0"
	base_icon_state = "cityblock"
	baseturfs = /turf/open/floor/plating
	hardness = 42

/turf/closed/indestructible/city/cityblock
	name = "block wall"
	desc = "Municipal blockwork in the old civic green, banded with a tan capping. \
		Put up by an authority that no longer maintains it."
	icon = 'icons/turf/walls/city_cityblock.dmi'
	icon_state = "cityblock-0"
	base_icon_state = "cityblock"

/turf/closed/wall/city/richpanel
	name = "panelled wall"
	desc = "Cream panelling over a dark ground, joints picked out in shadow. \
		Somebody upstairs still pays for the address."
	icon = 'icons/turf/walls/city_richpanel.dmi'
	icon_state = "richpanel-0"
	base_icon_state = "richpanel"
	baseturfs = /turf/open/floor/plating
	hardness = 38

/turf/closed/indestructible/city/richpanel
	name = "panelled wall"
	desc = "Cream panelling over a dark ground, joints picked out in shadow. \
		Somebody upstairs still pays for the address."
	icon = 'icons/turf/walls/city_richpanel.dmi'
	icon_state = "richpanel-0"
	base_icon_state = "richpanel"

/turf/closed/wall/city/scrapwall
	name = "scrap wall"
	desc = "Mismatched plate riveted over whatever was already there. Every panel \
		came off something else."
	icon = 'icons/turf/walls/city_scrapwall.dmi'
	icon_state = "scrapwall-0"
	base_icon_state = "scrapwall"
	baseturfs = /turf/open/floor/plating
	hardness = 20

/turf/closed/indestructible/city/scrapwall
	name = "scrap wall"
	desc = "Mismatched plate riveted over whatever was already there. Every panel \
		came off something else."
	icon = 'icons/turf/walls/city_scrapwall.dmi'
	icon_state = "scrapwall-0"
	base_icon_state = "scrapwall"

// The works district: riveted plate, boiler strake, soot, glazed dado, pipe
// runs and cast block, off the factory and workshop CGs.

/turf/closed/wall/city/ironplate
	name = "iron plate wall"
	desc = "Riveted steel panel over a frame. Someone has been painting over \
		the rust rather than dealing with it."
	icon = 'icons/turf/walls/city_ironplate.dmi'
	icon_state = "ironplate-0"
	base_icon_state = "ironplate"
	baseturfs = /turf/open/floor/plating
	sheet_type = /obj/item/stack/sheet/metal
	sheet_amount = 2
	hardness = 15

/turf/closed/indestructible/city/ironplate
	name = "iron plate wall"
	desc = "Riveted steel panel over a frame, backed by something heavier."
	icon = 'icons/turf/walls/city_ironplate.dmi'
	icon_state = "ironplate-0"
	base_icon_state = "ironplate"

/turf/closed/wall/city/boiler
	name = "boiler plate wall"
	desc = "Lapped strakes and a forest of rivets, still warm to the back of \
		your hand."
	icon = 'icons/turf/walls/city_boiler.dmi'
	icon_state = "boiler-0"
	base_icon_state = "boiler"
	baseturfs = /turf/open/floor/plating
	sheet_type = /obj/item/stack/sheet/metal
	sheet_amount = 2
	hardness = 15

/turf/closed/indestructible/city/boiler
	name = "boiler plate wall"
	desc = "Lapped strakes and a forest of rivets, still warm to the back of \
		your hand."
	icon = 'icons/turf/walls/city_boiler.dmi'
	icon_state = "boiler-0"
	base_icon_state = "boiler"

/turf/closed/wall/city/sootbrick
	name = "sooted brick wall"
	desc = "Brick blacked by decades of flue smoke. It comes off on anything \
		that touches it."
	icon = 'icons/turf/walls/city_sootbrick.dmi'
	icon_state = "sootbrick-0"
	base_icon_state = "sootbrick"
	baseturfs = /turf/open/floor/plating
	hardness = 25

/turf/closed/indestructible/city/sootbrick
	name = "sooted brick wall"
	desc = "Brick blacked by decades of flue smoke. It comes off on anything \
		that touches it."
	icon = 'icons/turf/walls/city_sootbrick.dmi'
	icon_state = "sootbrick-0"
	base_icon_state = "sootbrick"

/turf/closed/wall/city/glazedtile
	name = "glazed tile wall"
	desc = "Green glazed brick, laid when this place was meant to be kept \
		clean. The grout has gone black."
	icon = 'icons/turf/walls/city_glazedtile.dmi'
	icon_state = "glazedtile-0"
	base_icon_state = "glazedtile"
	baseturfs = /turf/open/floor/plating
	hardness = 25

/turf/closed/indestructible/city/glazedtile
	name = "glazed tile wall"
	desc = "Green glazed brick, laid when this place was meant to be kept \
		clean. The grout has gone black."
	icon = 'icons/turf/walls/city_glazedtile.dmi'
	icon_state = "glazedtile-0"
	base_icon_state = "glazedtile"

/turf/closed/wall/city/conduit
	name = "conduit wall"
	desc = "Pipe runs strapped down the face of it, every one of them going \
		somewhere you are not cleared for."
	icon = 'icons/turf/walls/city_conduit.dmi'
	icon_state = "conduit-0"
	base_icon_state = "conduit"
	baseturfs = /turf/open/floor/plating
	sheet_type = /obj/item/stack/sheet/metal
	sheet_amount = 2
	hardness = 20

/turf/closed/indestructible/city/conduit
	name = "conduit wall"
	desc = "Pipe runs strapped down the face of it, every one of them going \
		somewhere you are not cleared for."
	icon = 'icons/turf/walls/city_conduit.dmi'
	icon_state = "conduit-0"
	base_icon_state = "conduit"

/turf/closed/wall/city/breezeblock
	name = "block wall"
	desc = "Cast concrete block, laid fast and never faced. Back of house, \
		and it shows."
	icon = 'icons/turf/walls/city_breezeblock.dmi'
	icon_state = "breezeblock-0"
	base_icon_state = "breezeblock"
	baseturfs = /turf/open/floor/plating
	hardness = 25

/turf/closed/indestructible/city/breezeblock
	name = "block wall"
	desc = "Cast concrete block, laid fast and never faced. Back of house, \
		and it shows."
	icon = 'icons/turf/walls/city_breezeblock.dmi'
	icon_state = "breezeblock-0"
	base_icon_state = "breezeblock"

// The port. This one smooths against ordinary walls rather than keeping to
// itself, since containers get welded into whatever is already standing.
/turf/closed/wall/container
	name = "container wall"
	desc = "The corrugated flank of a shipping container, welded into place and \
		lived in. Somebody has bolted a light fitting to it."
	icon = 'icons/turf/walls/container.dmi'
	icon_state = "container-0"
	base_icon_state = "container"
	baseturfs = /turf/open/floor/city/container
	sheet_type = /obj/item/stack/sheet/metal
	sheet_amount = 4
	hardness = 30

/turf/closed/indestructible/container
	name = "container wall"
	desc = "The corrugated flank of a shipping container, welded into place. \
		This one is part of the stack holding everything above it up."
	icon = 'icons/turf/walls/container.dmi'
	icon_state = "container-0"
	base_icon_state = "container"
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_WINDOW_FULLTILE, SMOOTH_GROUP_AIRLOCK)
