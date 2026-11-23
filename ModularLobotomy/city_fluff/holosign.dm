/// Create bracket-mount subtypes for a sign path, mirroring the directional
/// helper idiom used elsewhere for wall-mounted things. The panel state is
/// passed in so each variant carries the sprite it will actually wear.
#define HOLOSIGN_MOUNTS(path, state) ##path/left {\
	mount = "_l"; \
	icon_state = state + "_l"; \
} \
##path/right {\
	mount = "_r"; \
	icon_state = state + "_r"; \
}

/obj/structure/sign/holosign
	name = "holographic sign"
	desc = "A backlit sign in a dented iron frame. The tube inside has seen better years."
	icon = 'ModularLobotomy/_Lobotomyicons/city_signs.dmi'
	icon_state = "holosign_warm"
	buildable_sign = FALSE
	density = FALSE
	/// Panel colour: warm, cyan, white, red, green or violet.
	var/panel = "warm"
	/// Bracket: "" hangs from above, "_l" and "_r" bracket off a wall.
	var/mount = ""
	/// Floating icon over the panel, if any.
	var/glyph
	var/lit = TRUE

/obj/structure/sign/holosign/Initialize(mapload)
	. = ..()
	update_icon()
	refresh_light()

/obj/structure/sign/holosign/update_icon_state()
	. = ..()
	icon_state = lit ? "holosign_[panel][mount]" : "holosign_off[mount]"

/obj/structure/sign/holosign/update_overlays()
	. = ..()
	if(glyph)
		. += mutable_appearance(icon, "glyph_[glyph][mount]")

/// The panel throws a little coloured light onto the wall around it.
/obj/structure/sign/holosign/proc/refresh_light()
	if(!lit)
		set_light(0)
		return
	var/glow
	switch(panel)
		if("cyan")
			glow = "#68e2d6"
		if("white")
			glow = "#e2ecf4"
		if("red")
			glow = "#e86e66"
		if("green")
			glow = "#7cde90"
		if("violet")
			glow = "#ac88e8"
		else
			glow = "#f4e0a4"
	set_light(2, 0.7, glow)

/obj/structure/sign/holosign/proc/set_lit(new_lit)
	lit = new_lit
	update_icon()
	refresh_light()

/obj/structure/sign/holosign/examine(mob/user)
	. = ..()
	. += lit ? span_notice("It buzzes and stutters.") : span_notice("It is dark.")

// -------------------------------------------------------------- the offices
// One per fixer office in the City game mode.

/obj/structure/sign/holosign/workshop
	name = "\improper Workshop Office sign"
	desc = "A workshop sign. The screw painted on it has worn down to the primer."
	panel = "warm"
	glyph = "screw"
	icon_state = "holosign_warm"

/obj/structure/sign/holosign/fishing
	name = "\improper Fishing Office sign"
	desc = "A fishing office sign, lit the same washed-out green as everything else on the water."
	panel = "cyan"
	glyph = "fish"
	icon_state = "holosign_cyan"

/obj/structure/sign/holosign/combat
	name = "\improper Combat Office sign"
	desc = "Crossed blades over a red panel. Subtlety was not the intent."
	panel = "red"
	glyph = "blades"
	icon_state = "holosign_red"

/obj/structure/sign/holosign/protection
	name = "\improper Protection Office sign"
	desc = "A shield on a cold white panel. Protection, for a fee."
	panel = "white"
	glyph = "shield"
	icon_state = "holosign_white"

/obj/structure/sign/holosign/recon
	name = "\improper Recon Office sign"
	desc = "An open eye. It is not clear whether that is a promise or a warning."
	panel = "green"
	glyph = "eye"
	icon_state = "holosign_green"

/obj/structure/sign/holosign/peacekeeper
	name = "\improper Peacekeeper Office sign"
	desc = "A badge, of the sort nobody in this district recognises as authority."
	panel = "violet"
	glyph = "badge"
	icon_state = "holosign_violet"

/obj/structure/sign/holosign/contract
	name = "\improper Contract Office sign"
	desc = "A sealed document. Whatever gets signed under this sign is binding."
	panel = "warm"
	glyph = "contract"
	icon_state = "holosign_warm"

/obj/structure/sign/holosign/banking
	name = "\improper Banking Office sign"
	desc = "A coin, struck with a diagonal. Ahn changes hands here."
	panel = "green"
	glyph = "coin"
	icon_state = "holosign_green"

/obj/structure/sign/holosign/office
	name = "\improper office sign"
	desc = "A plain office sign, the sort every second door in the City carries."
	panel = "white"
	glyph = "page"
	icon_state = "holosign_white"

/obj/structure/sign/holosign/diner
	name = "\improper diner sign"
	desc = "A steaming bowl. The place below it is open at hours no honest business keeps."
	panel = "cyan"
	glyph = "bowl"
	icon_state = "holosign_cyan"

// ------------------------------------------------------------ blank panels
// For streets that want light and colour without claiming a trade.

/obj/structure/sign/holosign/blank
	name = "\improper blank sign"
	desc = "A backlit panel with nothing painted on it. Either new, or scrubbed."
	icon_state = "holosign_warm"

/obj/structure/sign/holosign/blank/cyan
	panel = "cyan"
	icon_state = "holosign_cyan"

/obj/structure/sign/holosign/blank/white
	panel = "white"
	icon_state = "holosign_white"

/obj/structure/sign/holosign/blank/red
	panel = "red"
	icon_state = "holosign_red"

/obj/structure/sign/holosign/blank/green
	panel = "green"
	icon_state = "holosign_green"

/obj/structure/sign/holosign/blank/violet
	panel = "violet"
	icon_state = "holosign_violet"

/obj/structure/sign/holosign/dark
	name = "\improper dead sign"
	desc = "A sign box with nothing running in it. The tube is long gone."
	icon_state = "holosign_off"
	lit = FALSE

// Bracket variants for every sign, so mappers can hang them off a wall
// on either side as well as from an overhead beam.
HOLOSIGN_MOUNTS(/obj/structure/sign/holosign/workshop, "holosign_warm")
HOLOSIGN_MOUNTS(/obj/structure/sign/holosign/fishing, "holosign_cyan")
HOLOSIGN_MOUNTS(/obj/structure/sign/holosign/combat, "holosign_red")
HOLOSIGN_MOUNTS(/obj/structure/sign/holosign/protection, "holosign_white")
HOLOSIGN_MOUNTS(/obj/structure/sign/holosign/recon, "holosign_green")
HOLOSIGN_MOUNTS(/obj/structure/sign/holosign/peacekeeper, "holosign_violet")
HOLOSIGN_MOUNTS(/obj/structure/sign/holosign/contract, "holosign_warm")
HOLOSIGN_MOUNTS(/obj/structure/sign/holosign/banking, "holosign_green")
HOLOSIGN_MOUNTS(/obj/structure/sign/holosign/office, "holosign_white")
HOLOSIGN_MOUNTS(/obj/structure/sign/holosign/diner, "holosign_cyan")
HOLOSIGN_MOUNTS(/obj/structure/sign/holosign/dark, "holosign_off")
HOLOSIGN_MOUNTS(/obj/structure/sign/holosign/blank, "holosign_warm")
HOLOSIGN_MOUNTS(/obj/structure/sign/holosign/blank/cyan, "holosign_cyan")
HOLOSIGN_MOUNTS(/obj/structure/sign/holosign/blank/white, "holosign_white")
HOLOSIGN_MOUNTS(/obj/structure/sign/holosign/blank/red, "holosign_red")
HOLOSIGN_MOUNTS(/obj/structure/sign/holosign/blank/green, "holosign_green")
HOLOSIGN_MOUNTS(/obj/structure/sign/holosign/blank/violet, "holosign_violet")
HOLOSIGN_MOUNTS(/obj/structure/sign/holosign, "holosign_warm")
