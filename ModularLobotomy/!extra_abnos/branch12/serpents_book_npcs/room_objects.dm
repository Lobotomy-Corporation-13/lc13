// =============================================================================
// SERPENT'S BOOK - ROOM OBJECTS FOR NPC CHAPTERS
// =============================================================================
// Creepy ambient objects that populate each trapped resident's room.
// These add atmosphere and horror to the NPC encounters.
// Sprites are not done yet, but will be added later.
// =============================================================================

// =============================================================================
// CLOCKMAKER'S ROOM (Chapter 75)
// =============================================================================


// Sprites? [ ]
/obj/structure/serpent_clockwork_family
	name = "clockwork figure"
	desc = "A life-sized mechanical figure. Gears and springs are visible through gaps in its porcelain skin."
	icon = 'icons/obj/structures.dmi'
	icon_state = "yourfacewhen"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE
	/// Role in the family
	var/family_role = "figure"

/obj/structure/serpent_clockwork_family/examine(mob/user)
	. = ..()
	. += span_warning("Its eyes seem to follow you...")
	if(prob(20))
		. += span_danger("For a moment, you think you see something human beneath the porcelain.")

/obj/structure/serpent_clockwork_family/attack_hand(mob/user)
	. = ..()
	if(prob(30))
		visible_message(span_warning("[src] turns its head toward [user] with a grinding sound."))
		playsound(src, 'sound/machines/clockwork/clock_tick.ogg', 30, TRUE)
	else
		to_chat(user, span_notice("[src] is cold to the touch. You feel gears moving beneath the surface."))

// Sprites? [ ]
/obj/structure/serpent_clockwork_family/wife
	name = "clockwork wife"
	desc = "A mechanical woman in a faded dress. Her porcelain face is cracked in a permanent smile. Springs poke out from beneath her collar."
	family_role = "wife"

// Sprites? [ ]
/obj/structure/serpent_clockwork_family/son
	name = "clockwork son"
	desc = "A mechanical boy with brass fingers. His eyes are made of glass that reflects nothing."
	family_role = "son"

// Sprites? [ ]
/obj/structure/serpent_clockwork_family/daughter
	name = "clockwork daughter"
	desc = "A mechanical girl with a music box embedded in her chest. It plays a lullaby that never quite finishes."
	family_role = "daughter"

// Sprites? [ ]
/obj/structure/serpent_dinner_table
	name = "family dinner table"
	desc = "A worn wooden table set for a meal that never ends. The food appears to be made of iron nails and clock parts."
	icon = 'icons/obj/structures.dmi'
	icon_state = "yourfacewhen"
	anchored = TRUE
	density = TRUE

/obj/structure/serpent_dinner_table/examine(mob/user)
	. = ..()
	. += span_warning("The 'food' on the plates consists of small gears, springs, and iron nails.")
	. += span_danger("There are scratch marks on the inside of the plates.")

// =============================================================================
// PAINTER'S ROOM (Chapter 55)
// =============================================================================

// Sprites? [ ]
/obj/structure/serpent_living_painting
	name = "painting"
	desc = "A hauntingly beautiful portrait. The subject seems almost alive."
	icon = 'icons/obj/structures.dmi'
	icon_state = "yourfacewhen"
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE
	/// Description of the painting's subject
	var/subject_desc = "a person frozen in oil and canvas"
	/// Is this painting screaming?
	var/is_screaming = FALSE

/obj/structure/serpent_living_painting/Initialize(mapload)
	. = ..()
	if(prob(20))
		is_screaming = TRUE

/obj/structure/serpent_living_painting/examine(mob/user)
	. = ..()
	if(is_screaming)
		. += span_danger("The subject is frozen mid-scream, hands pressed against the canvas from the inside.")
	else
		. += span_warning("The subject's eyes seem to follow you around the room.")
	if(prob(10))
		. += span_userdanger("You swear you saw the painting move.")

/obj/structure/serpent_living_painting/attack_hand(mob/user)
	. = ..()
	if(prob(40))
		visible_message(span_warning("The figure in [src] shifts when [user] touches the frame!"))
		if(is_screaming)
			visible_message(span_danger("A muffled sound emerges from the canvas - like someone trying to scream through paint."))
	else
		to_chat(user, span_notice("The paint feels wet, even though it's clearly ancient."))

// Sprites? [ ]
/obj/structure/serpent_living_painting/screaming
	name = "screaming portrait"
	desc = "A portrait of someone frozen in a moment of pure terror. Their hands are pressed against the canvas from inside."
	is_screaming = TRUE
	subject_desc = "a person trapped mid-scream"

// Sprites? [ ]
/obj/structure/serpent_living_painting/beautiful
	name = "beautiful portrait"
	desc = "A portrait of striking beauty. The subject's eyes hold a desperate plea."
	subject_desc = "someone who was once very beautiful"

// Sprites? [ ]
/obj/structure/serpent_living_painting/empty_frame
	name = "empty ornate frame"
	desc = "An elaborate golden frame with no painting inside. A small placard reads: 'Reserved.'"
	is_screaming = FALSE

/obj/structure/serpent_living_painting/empty_frame/examine(mob/user)
	. = ..()
	. += span_warning("The frame seems to be waiting for something. Or someone.")

// Sprites? [ ]
/obj/structure/serpent_easel
	name = "painter's easel"
	desc = "An easel holding a half-finished canvas. The paint on the palette looks disturbingly like blood."
	icon = 'icons/obj/structures.dmi'
	icon_state = "yourfacewhen"
	anchored = TRUE
	density = TRUE

/obj/structure/serpent_easel/examine(mob/user)
	. = ..()
	. += span_warning("The brushes appear to be made of human hair.")
	. += span_danger("The 'red paint' smells of iron.")

// =============================================================================
// SURGEON'S ROOM (Chapter 35)
// =============================================================================

// Sprites? [ ]
/obj/structure/serpent_surgery_table
	name = "operating table"
	desc = "A blood-stained surgical table. The patient strapped to it is still breathing."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "yourfacewhen"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE
	/// What modification does this patient have?
	var/modification_type = "unknown"

/obj/structure/serpent_surgery_table/examine(mob/user)
	. = ..()
	. += span_danger("The patient's eyes are wide open, tracking you with desperate intensity.")
	. += span_warning("Their mouth has been sutured shut.")

/obj/structure/serpent_surgery_table/attack_hand(mob/user)
	. = ..()
	visible_message(span_warning("The patient on [src] strains against their restraints, eyes pleading with [user]!"))
	to_chat(user, span_danger("You hear muffled sounds - they're trying to speak through their sealed mouth."))

// Sprites? [ ]
/obj/structure/serpent_surgery_table/extra_arms
	name = "modified patient (extra limbs)"
	desc = "A patient with multiple arms grafted along their torso. All of them twitch independently."
	modification_type = "extra limbs"

/obj/structure/serpent_surgery_table/extra_arms/examine(mob/user)
	. = ..()
	. += span_danger("They have six arms - the extra four grafted crudely but somehow still functional.")

// Sprites? [ ]
/obj/structure/serpent_surgery_table/visible_organs
	name = "modified patient (exposed organs)"
	desc = "A patient whose torso has been replaced with a transparent panel. Their organs are visible and beating."
	modification_type = "visible organs"

/obj/structure/serpent_surgery_table/visible_organs/examine(mob/user)
	. = ..()
	. += span_danger("You can count four hearts, three kidneys, and something that doesn't look like any organ you recognize.")

// Sprites? [ ]
/obj/structure/serpent_surgery_table/rearranged
	name = "modified patient (rearranged)"
	desc = "A patient whose body has been 'reorganized.' Limbs are in wrong places. They shouldn't be alive, but they are."
	modification_type = "rearranged"

/obj/structure/serpent_surgery_table/rearranged/examine(mob/user)
	. = ..()
	. += span_danger("Their arms are where legs should be. Their head is... you don't want to look too closely.")

// Sprites? [ ]
/obj/structure/serpent_surgery_instruments
	name = "surgical instruments"
	desc = "A tray of surgical tools. Some appear to be fused directly into the wall, still covered in old blood."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "yourfacewhen"
	anchored = TRUE
	density = FALSE

/obj/structure/serpent_surgery_instruments/examine(mob/user)
	. = ..()
	. += span_warning("The instruments are arranged with obsessive precision.")
	. += span_danger("Some of them have designs you don't recognize from any medical textbook.")

// Sprites? [ ]
/obj/structure/serpent_specimen_jar
	name = "specimen jar"
	desc = "A large jar containing preserved... parts. They occasionally twitch."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "yourfacewhen"
	anchored = TRUE
	density = FALSE

/obj/structure/serpent_specimen_jar/examine(mob/user)
	. = ..()
	. += span_danger("The contents are still alive. You can see them moving.")
	if(prob(20))
		. += span_userdanger("One of the specimens presses against the glass, looking at you.")

// =============================================================================
// COLLECTOR'S ROOM (Chapter 20)
// =============================================================================

// Sprites? [ ]
/obj/structure/serpent_display_case
	name = "crystal display case"
	desc = "A transparent case containing a perfectly preserved specimen. The preservation method is unclear."
	icon = 'icons/obj/structures.dmi'
	icon_state = "yourfacewhen"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE
	/// What's in this case?
	var/specimen_type = "unknown specimen"
	/// Is the specimen human?
	var/human_specimen = FALSE

/obj/structure/serpent_display_case/examine(mob/user)
	. = ..()
	if(human_specimen)
		. += span_danger("The person inside is frozen in crystal, but their eyes... their eyes move.")
		. += span_warning("A small placard reads: 'Acquired - Date Unknown. Condition: Perfect.'")
	else
		. += span_notice("The specimen is perfectly preserved, untouched by time.")

/obj/structure/serpent_display_case/attack_hand(mob/user)
	. = ..()
	if(human_specimen)
		visible_message(span_warning("The figure inside [src] tracks [user]'s movement with desperate eyes!"))
		to_chat(user, span_danger("You see tears frozen mid-fall on their face."))
	else
		to_chat(user, span_notice("The crystal case is cold to the touch."))

// Sprites? [ ]
/obj/structure/serpent_display_case/dancer
	name = "display case - The Dancer"
	desc = "A woman frozen mid-pirouette, grace captured for eternity."
	specimen_type = "dancer"
	human_specimen = TRUE

/obj/structure/serpent_display_case/dancer/examine(mob/user)
	. = ..()
	. += span_danger("She was preserved at the apex of her final performance. Her expression shows she didn't know it would be final.")

// Sprites? [ ]
/obj/structure/serpent_display_case/poet
	name = "display case - The Poet"
	desc = "A man with gentle features, mouth open as if about to speak words that will never come."
	specimen_type = "poet"
	human_specimen = TRUE

/obj/structure/serpent_display_case/poet/examine(mob/user)
	. = ..()
	. += span_danger("His mouth is frozen mid-word. You wonder what he was trying to say.")

// Sprites? [ ]
/obj/structure/serpent_display_case/hands
	name = "display case - Perfect Hands"
	desc = "A display containing only hands - perfectly preserved, arranged like art. No body attached."
	specimen_type = "hands"
	human_specimen = TRUE

/obj/structure/serpent_display_case/hands/examine(mob/user)
	. = ..()
	. += span_danger("The hands are arranged in an elegant pattern. The placard says they belonged to a sculptor.")
	. += span_userdanger("The fingers occasionally twitch.")

// Sprites? [ ]
/obj/structure/serpent_display_case/smile
	name = "display case - The Perfect Smile"
	desc = "A face - just a face - preserved in crystal. It wears a beautiful smile that doesn't reach the eyes."
	specimen_type = "face"
	human_specimen = TRUE

/obj/structure/serpent_display_case/smile/examine(mob/user)
	. = ..()
	. += span_danger("Just the face. Nothing else. The eyes are very much aware.")

// Sprites? [ ]
/obj/structure/serpent_display_case/empty
	name = "empty display case"
	desc = "An empty crystal display case. A placard reads: 'Reserved for a Special Acquisition.'"
	specimen_type = "empty"
	human_specimen = FALSE

/obj/structure/serpent_display_case/empty/examine(mob/user)
	. = ..()
	. += span_userdanger("The case seems sized for a human. For someone about your size.")

/obj/structure/serpent_display_case/empty/attack_hand(mob/user)
	. = ..()
	to_chat(user, span_danger("The case door swings open easily. It's waiting for something. Or someone."))

// Sprites? [ ]
/obj/structure/serpent_artifact
	name = "rare artifact"
	desc = "An ancient artifact of immense value, perfectly preserved."
	icon = 'icons/obj/structures.dmi'
	icon_state = "yourfacewhen"
	anchored = TRUE
	density = FALSE

/obj/structure/serpent_catalog_desk
	name = "cataloging desk"
	desc = "A desk covered in meticulous records. Each specimen has a detailed entry documenting its 'acquisition.'"
	icon = 'icons/obj/structures.dmi'
	icon_state = "yourfacewhen"
	anchored = TRUE
	density = TRUE

/obj/structure/serpent_catalog_desk/examine(mob/user)
	. = ..()
	. += span_warning("The records go back centuries. All written in the same handwriting.")
	. += span_danger("You notice your description might fit an entry marked 'Pending.'")
