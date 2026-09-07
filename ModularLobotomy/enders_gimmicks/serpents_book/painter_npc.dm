// =============================================================================
// THE PAINTER - Madame Rosalind
// =============================================================================
// Chapter 55 - A celebrated portrait artist whose work was never appreciated.
// Her desire: "I wished for my art to be seen, truly seen, forever."
// The room is an opulent gallery with living paintings - trapped souls
// frozen in oil and canvas.
// =============================================================================

/mob/living/simple_animal/hostile/ui_npc/serpent_resident/painter
	name = "Madame Rosalind"
	desc = "An elegant woman in paint-stained finery. Her brushes are made of something disturbingly hair-like."
	icon_state = "faceless"
	icon_living = "faceless"
	portrait = "serpent_painter.png"
	start_scene_id = "intro"
	resident_chapter = 55
	random_emotes = "examines an invisible canvas critically;dips a brush into something red;hums while studying your features;whispers to a painting that seems to shudder"

/mob/living/simple_animal/hostile/ui_npc/serpent_resident/painter/Initialize(mapload)
	. = ..()
	// Initialize NPC variables
	scene_manager.npc_vars.variables["offered_portrait"] = FALSE
	scene_manager.npc_vars.variables["paintings_count"] = 47

	// Load dialogue
	scene_manager.load_scenes(get_painter_scenes())

/mob/living/simple_animal/hostile/ui_npc/serpent_resident/painter/proc/get_painter_scenes()
	var/list/scenes = list()

	// ==========================================================================
	// INTRO SCENES
	// ==========================================================================

	scenes["intro"] = list(
		"text" = "*A woman in an elegant but paint-stained dress stands before an easel. Around her, dozens of portraits line the walls - all depicting people in exquisite, lifelike detail. Their eyes seem to follow you.*",
		"actions" = list(
			"hello" = list(
				"text" = "Hello?",
				"default_scene" = "greeting_first",
				"transitions" = list(
					list(
						"expression" = "player.met_before",
						"scene" = "greeting_return"
					)
				)
			),
			"observe" = list(
				"text" = "*Look at the paintings*",
				"default_scene" = "observe_paintings"
			)
		)
	)

	scenes["greeting_first"] = list(
		"text" = "*She turns, eyes lighting up.* Welcome, welcome to my gallery! A new face! How delightful!",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"var_updates" = list(
					"player.met_before" = TRUE
				),
				"default_scene" = "greeting_2"
			)
		)
	)

	scenes["greeting_2"] = list(
		"text" = "*She approaches, studying your face with unsettling intensity.* Such interesting features. Such expressive eyes. They would look magnificent on canvas.",
		"actions" = list(
			"thank_you" = list(
				"text" = "...Thank you?",
				"default_scene" = "main_menu"
			),
			"back_away" = list(
				"text" = "*Step back*",
				"default_scene" = "dont_be_shy"
			)
		)
	)

	scenes["dont_be_shy"] = list(
		"text" = "Oh, don't be shy! I'm simply appreciating. An artist must observe, after all. Every detail is precious.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["greeting_return"] = list(
		"text" = "Ah, my returning patron! Have you come to admire the collection again? Or perhaps... to add to it?",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["observe_paintings"] = list(
		"text" = "*The paintings are hauntingly beautiful. Each subject seems frozen in a moment of intense emotion - some joyful, some terrified. One painting clearly shows a figure mid-scream, their hands pressed against the canvas from the inside.*",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "intro"
			)
		)
	)

	// ==========================================================================
	// MAIN MENU
	// ==========================================================================

	scenes["main_menu"] = list(
		"text" = "Now then, what brings you to my gallery? Not many appreciate true art these days.",
		"actions" = list(
			"who_are_you" = list(
				"text" = "Who are you?",
				"default_scene" = "about_rosalind"
			),
			"about_paintings" = list(
				"text" = "Tell me about your paintings.",
				"default_scene" = "about_art_1"
			),
			"about_subjects" = list(
				"text" = "Who are the people in these paintings?",
				"default_scene" = "about_subjects_1"
			),
			"about_book" = list(
				"text" = "Where are we?",
				"default_scene" = "about_book_1"
			),
			"portrait_offer" = list(
				"text" = "\[npc.offered_portrait?About that portrait...:I notice empty frames on the wall.\]",
				"default_scene" = "empty_frames",
				"transitions" = list(
					list(
						"expression" = "npc.offered_portrait",
						"scene" = "portrait_reminder"
					)
				)
			),
			"leave" = list(
				"text" = "I should go.",
				"default_scene" = "farewell"
			)
		)
	)

	// ==========================================================================
	// ABOUT ROSALIND
	// ==========================================================================

	scenes["about_rosalind"] = list(
		"text" = "I am Madame Rosalind, portrait artist extraordinaire. Or at least, that's what the critics should have called me.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_rosalind_2"
			)
		)
	)

	scenes["about_rosalind_2"] = list(
		"text" = "In life, they said my work was 'too intense.' 'Disturbing.' They couldn't see the truth I captured.",
		"actions" = list(
			"what_truth" = list(
				"text" = "What truth?",
				"default_scene" = "about_rosalind_3"
			),
			"back" = list(
				"text" = "I see.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["about_rosalind_3"] = list(
		"text" = "The soul, darling. I paint souls. Every brushstroke captures something essential, eternal. And here... here my art is finally appreciated.",
		"actions" = list(
			"appreciated_by_whom" = list(
				"text" = "Appreciated by whom?",
				"default_scene" = "about_rosalind_4"
			),
			"back" = list(
				"text" = "I see.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["about_rosalind_4"] = list(
		"text" = "*She gestures to the paintings.* By them, of course. They see themselves every day. Forever watching. Forever seen. Forever... appreciated.",
		"actions" = list(
			"theyre_trapped" = list(
				"text" = "They're trapped.",
				"proc_callbacks" = list(CALLBACK(src, PROC_REF(on_player_suspicious))),
				"default_scene" = "denial_trapped"
			),
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["denial_trapped"] = list(
		"text" = "Trapped? *She laughs.* Preserved, darling. There's a difference. Trapping is cruel. Preservation is love.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// ABOUT THE ART
	// ==========================================================================

	scenes["about_art_1"] = list(
		"text" = "My paintings? Each one is a masterwork. Every subject... so willing to be preserved.",
		"actions" = list(
			"willing" = list(
				"text" = "Willing?",
				"default_scene" = "about_art_2"
			),
			"back" = list(
				"text" = "They're certainly... striking.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["about_art_2"] = list(
		"text" = "Oh yes. Everyone wants to be remembered. To be seen. I simply... help them achieve that dream.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_art_3"
			)
		)
	)

	scenes["about_art_3"] = list(
		"text" = "*She strokes a nearby painting. The figure within seems to flinch.* Some take a little convincing, but they always thank me in the end.",
		"actions" = list(
			"it_moved" = list(
				"text" = "Did that painting just move?",
				"default_scene" = "painting_moved"
			),
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["painting_moved"] = list(
		"text" = "Of course it moved. Art should be alive, shouldn't it? What's the point of capturing someone's essence if it doesn't breathe?",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// ABOUT THE SUBJECTS
	// ==========================================================================

	scenes["about_subjects_1"] = list(
		"text" = "My subjects? They're guests, like you. People who wandered into my gallery seeking... something.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_subjects_2"
			)
		)
	)

	scenes["about_subjects_2"] = list(
		"text" = "*She points to various paintings.* That one wanted to be famous. She is now - everyone who enters sees her face. Forever beautiful, forever young.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_subjects_3"
			)
		)
	)

	scenes["about_subjects_3"] = list(
		"text" = "That one was afraid of being forgotten. Now he'll never be forgotten. I've captured him at his most terrified - such raw emotion!",
		"actions" = list(
			"theyre_screaming" = list(
				"text" = "Some of them look like they're screaming.",
				"default_scene" = "screaming"
			),
			"back" = list(
				"text" = "I see...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["screaming"] = list(
		"text" = "Art speaks to those who listen, darling. Sometimes it whispers. Sometimes it screams. *She pauses.* Don't mind the sounds. That's just the canvas settling.",
		"actions" = list(
			"i_hear_them" = list(
				"text" = "I can hear them.",
				"default_scene" = "hear_them"
			),
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["hear_them"] = list(
		"text" = "*Her smile flickers.* Some are louder than others. The ones who weren't... fully committed to the process. But they'll quiet down. Eventually. They always do.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// ABOUT THE BOOK
	// ==========================================================================

	scenes["about_book_1"] = list(
		"text" = "We are in a place between pages. A story that writes itself. The Serpent calls it a library, but I think of it as... a gallery of desires.",
		"actions" = list(
			"desires" = list(
				"text" = "A gallery of desires?",
				"default_scene" = "about_book_2"
			),
			"back" = list(
				"text" = "I see.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["about_book_2"] = list(
		"text" = "Everyone here wanted something badly enough to be trapped by it. My desire was simple - for my art to be seen. Truly seen. Forever.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_book_3"
			)
		)
	)

	scenes["about_book_3"] = list(
		"text" = "And now it is. Every subject I paint lives on. Every visitor who passes through sees my work. I am finally... appreciated.",
		"actions" = list(
			"at_what_cost" = list(
				"text" = "At what cost?",
				"default_scene" = "cost"
			),
			"back" = list(
				"text" = "I see.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["cost"] = list(
		"text" = "*She pauses, something flickering behind her eyes.* Cost? Art requires sacrifice, darling. The subjects... they give themselves to something greater. That's not cost. That's purpose.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// EMPTY FRAMES / PORTRAIT OFFER
	// ==========================================================================

	scenes["empty_frames"] = list(
		"text" = "Ah, yes. Spaces for new works. Every artist needs room to grow, don't they?",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "empty_frames_2"
			)
		)
	)

	scenes["empty_frames_2"] = list(
		"text" = "*She studies you with renewed interest.* You know, I've been looking for a new subject. Someone with character. With depth. Someone like you.",
		"actions" = list(
			"refuse" = list(
				"text" = "I don't think so.",
				"default_scene" = "portrait_refuse"
			),
			"consider" = list(
				"text" = "What would that involve?",
				"var_updates" = list(
					"npc.offered_portrait" = TRUE
				),
				"default_scene" = "portrait_process"
			)
		)
	)

	scenes["portrait_refuse"] = list(
		"text" = "*Her smile doesn't waver, but something cold enters her eyes.* Pity. You would have been magnificent. But don't worry - I'm patient. Good subjects are worth waiting for.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"var_updates" = list(
					"npc.offered_portrait" = TRUE
				),
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["portrait_process"] = list(
		"text" = "Oh, it's quite simple. You sit. I paint. And when I'm finished... you become eternal. Your beauty preserved forever. Your essence captured in oil and canvas.",
		"actions" = list(
			"what_happens" = list(
				"text" = "What happens to the person after?",
				"default_scene" = "portrait_truth"
			),
			"refuse_now" = list(
				"text" = "I'll pass.",
				"default_scene" = "portrait_refuse"
			)
		)
	)

	scenes["portrait_truth"] = list(
		"text" = "*She tilts her head.* After? Darling, there is no 'after.' You become the painting. The painting becomes you. You'll live forever in that moment of perfect beauty.",
		"actions" = list(
			"thats_death" = list(
				"text" = "That sounds like death.",
				"default_scene" = "not_death"
			),
			"refuse_now" = list(
				"text" = "No thank you.",
				"default_scene" = "portrait_refuse"
			)
		)
	)

	scenes["not_death"] = list(
		"text" = "Death? Death is being forgotten. Death is fading away. This is the opposite of death. This is eternal presence. Eternal... being seen.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["portrait_reminder"] = list(
		"text" = "Changed your mind about the portrait? I do still have that lovely frame waiting...",
		"actions" = list(
			"still_no" = list(
				"text" = "No.",
				"default_scene" = "portrait_refuse"
			),
			"back" = list(
				"text" = "I was just asking.",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// FAREWELL
	// ==========================================================================

	scenes["farewell"] = list(
		"text" = "Leaving so soon? Well, art waits for no one. Except when it's on canvas - then it waits forever.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "farewell_2"
			)
		)
	)

	scenes["farewell_2"] = list(
		"text" = "*She picks up her brush, turning back to a half-finished painting. The subject within seems to be crying.* Do visit again. And remember - I'm always looking for new... inspiration.",
		"actions" = list(
			"close" = list(
				"text" = "*Leave*",
				"close_dialogue" = TRUE
			)
		)
	)

	return scenes

/// Called when player questions the NPC's reality
/mob/living/simple_animal/hostile/ui_npc/serpent_resident/painter/on_player_suspicious(mob/user)
	. = ..()
	// Paintings seem to react
	visible_message(span_warning("The paintings on the walls seem to shift, their eyes tracking [user] more intently."))
