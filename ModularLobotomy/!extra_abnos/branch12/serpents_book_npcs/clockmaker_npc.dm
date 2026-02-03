// =============================================================================
// THE CLOCKMAKER - Heinrich Valdis
// =============================================================================
// Chapter 75 - A master watchmaker who lost his family to illness.
// His desire: "I wished my family would stay perfect, forever unchanging."
// The room is a household frozen in eternal dinner, with a mechanical family
// that falls apart when he's not looking.
// =============================================================================

/mob/living/simple_animal/hostile/ui_npc/serpent_resident/clockmaker
	name = "Heinrich Valdis"
	desc = "An elderly man in a worn waistcoat, surrounded by the constant ticking of clocks. His eyes hold a desperate, fragile hope."
	icon_state = "faceless"
	icon_living = "faceless"
	portrait = "serpent_clockmaker.png"
	start_scene_id = "intro"
	resident_chapter = 75
	random_emotes = "winds something in his pocket;glances at his family with a loving smile;adjusts an invisible clock hand;hums a lullaby softly"

/mob/living/simple_animal/hostile/ui_npc/serpent_resident/clockmaker/Initialize(mapload)
	. = ..()
	// Initialize NPC variables
	scene_manager.npc_vars.variables["family_intact"] = TRUE
	scene_manager.npc_vars.variables["wound_wife"] = FALSE
	scene_manager.npc_vars.variables["wound_children"] = FALSE

	// Load dialogue
	scene_manager.load_scenes(get_clockmaker_scenes())

/mob/living/simple_animal/hostile/ui_npc/serpent_resident/clockmaker/proc/get_clockmaker_scenes()
	var/list/scenes = list()

	// ==========================================================================
	// INTRO SCENES
	// ==========================================================================

	scenes["intro"] = list(
		"text" = "*An elderly man sits at a dinner table with three figures - a woman and two children. He looks up as you enter, surprised but pleased.*",
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
				"text" = "*Look around the room*",
				"default_scene" = "observe_room"
			)
		)
	)

	scenes["greeting_first"] = list(
		"text" = "Ah, visitors! How wonderful! My family and I were just sitting down to dinner. Won't you join us?",
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
		"text" = "*He gestures to the figures at the table.* This is my wife, Elara. And my children - Wilhelm and little Greta.",
		"actions" = list(
			"hello_family" = list(
				"text" = "Hello to you all.",
				"default_scene" = "family_greeting"
			),
			"something_wrong" = list(
				"text" = "They seem... odd.",
				"default_scene" = "denial_1"
			)
		)
	)

	scenes["greeting_return"] = list(
		"text" = "Ah, our guest has returned! Come, come. Elara has prepared the same wonderful meal as always.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["observe_room"] = list(
		"text" = "*The room is filled with ticking clocks - hundreds of them covering every wall. The family at the table sits perfectly still. Their joints seem... mechanical. A spring pokes out from beneath the wife's collar.*",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "intro"
			)
		)
	)

	scenes["family_greeting"] = list(
		"text" = "*The figures turn their heads with a faint grinding sound. The wife's porcelain face cracks into a smile.* \"Wel-come to our home.\" *Her voice is like a music box winding down.*",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["denial_1"] = list(
		"text" = "Odd? *He laughs nervously.* Oh, they're just tired. We've had a long day. Haven't we, dear?",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "denial_2"
			)
		)
	)

	scenes["denial_2"] = list(
		"text" = "*The wife's head rotates with a clicking sound.* \"Yes... dear. A long... day.\"",
		"actions" = list(
			"theyre_machines" = list(
				"text" = "They're not real. They're machines.",
				"proc_callbacks" = list(CALLBACK(src, PROC_REF(on_player_suspicious))),
				"default_scene" = "confrontation_1"
			),
			"drop_it" = list(
				"text" = "...Nevermind.",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// MAIN MENU
	// ==========================================================================

	scenes["main_menu"] = list(
		"text" = "So, what brings you to our little home? Not many visitors find their way here.",
		"actions" = list(
			"who_are_you" = list(
				"text" = "Who are you?",
				"default_scene" = "about_heinrich"
			),
			"about_family" = list(
				"text" = "Tell me about your family.",
				"default_scene" = "about_family_1"
			),
			"about_book" = list(
				"text" = "Do you know where we are?",
				"default_scene" = "about_book_1"
			),
			"about_serpent" = list(
				"text" = "Have you seen a serpent creature?",
				"default_scene" = "about_serpent_1"
			),
			"help_escape" = list(
				"text" = "Can you help me escape?",
				"default_scene" = "help_1"
			),
			"leave" = list(
				"text" = "I should go.",
				"default_scene" = "farewell"
			)
		)
	)

	// ==========================================================================
	// ABOUT HEINRICH
	// ==========================================================================

	scenes["about_heinrich"] = list(
		"text" = "Me? I'm Heinrich Valdis. Master clockmaker. Or I was, before I found this place.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_heinrich_2"
			)
		)
	)

	scenes["about_heinrich_2"] = list(
		"text" = "I spent my whole life making timepieces. Beautiful things that measured the passing of moments. But time... time is cruel.",
		"actions" = list(
			"what_happened" = list(
				"text" = "What happened?",
				"default_scene" = "about_heinrich_3"
			),
			"back" = list(
				"text" = "I see.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["about_heinrich_3"] = list(
		"text" = "I lost them. One by one. The sickness took them from me. My Elara. My Wilhelm. My little Greta. Time took everything.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_heinrich_4"
			)
		)
	)

	scenes["about_heinrich_4"] = list(
		"text" = "*He smiles, but his eyes are hollow.* But not anymore. Here, time stands still. They never age. They never change. They never leave.",
		"actions" = list(
			"theyre_not_real" = list(
				"text" = "But they're not really your family.",
				"proc_callbacks" = list(CALLBACK(src, PROC_REF(on_player_suspicious))),
				"default_scene" = "confrontation_1"
			),
			"im_sorry" = list(
				"text" = "I'm sorry for your loss.",
				"default_scene" = "about_heinrich_5"
			)
		)
	)

	scenes["about_heinrich_5"] = list(
		"text" = "Don't be. I have them back now. Isn't that what every father wants?",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// ABOUT FAMILY
	// ==========================================================================

	scenes["about_family_1"] = list(
		"text" = "My family? *His face lights up.* They are my everything. My reason for being.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_family_2"
			)
		)
	)

	scenes["about_family_2"] = list(
		"text" = "My wife makes the most wonderful... *He pauses, as if trying to remember something.* ...meals. Every night. The same wonderful meal.",
		"actions" = list(
			"same_meal" = list(
				"text" = "The same meal every night?",
				"default_scene" = "about_family_3"
			),
			"children" = list(
				"text" = "And your children?",
				"default_scene" = "about_children"
			)
		)
	)

	scenes["about_family_3"] = list(
		"text" = "Yes! Isn't it wonderful? Perfect consistency. She never forgets the recipe. Never burns anything. Never... changes.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_family_4"
			)
		)
	)

	scenes["about_family_4"] = list(
		"text" = "*Behind him, you notice the wife dropping small iron nails into her mouth, chewing with a grinding sound.*",
		"actions" = list(
			"shes_eating_nails" = list(
				"text" = "She's eating... nails?",
				"default_scene" = "denial_food"
			),
			"ignore" = list(
				"text" = "*Say nothing*",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["denial_food"] = list(
		"text" = "What? No, no. That's just her special dietary needs. Very nutritious. Good for the... constitution.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["about_children"] = list(
		"text" = "Wilhelm wants to be a clockmaker like his father. He has such steady hands. And Greta... she just learned to read.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_children_2"
			)
		)
	)

	scenes["about_children_2"] = list(
		"text" = "*One of the children's arms falls off with a clatter of gears. Heinrich quickly picks it up and reattaches it.* She's just a bit... clumsy today. Growing pains.",
		"actions" = list(
			"thats_not_normal" = list(
				"text" = "That's not normal!",
				"proc_callbacks" = list(CALLBACK(src, PROC_REF(on_player_suspicious))),
				"default_scene" = "confrontation_1"
			),
			"pretend_normal" = list(
				"text" = "...Of course. Growing pains.",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// ABOUT THE BOOK
	// ==========================================================================

	scenes["about_book_1"] = list(
		"text" = "Where we are? We're home, of course. Our perfect little home.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_book_2"
			)
		)
	)

	scenes["about_book_2"] = list(
		"text" = "I remember... there was a book. I found it in the ruins of my old workshop. It promised me everything I wanted.",
		"actions" = list(
			"what_did_it_promise" = list(
				"text" = "What did it promise?",
				"default_scene" = "about_book_3"
			),
			"back" = list(
				"text" = "I see.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["about_book_3"] = list(
		"text" = "It promised that time would stop. That I could have them back. That nothing would ever change again.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_book_4"
			)
		)
	)

	scenes["about_book_4"] = list(
		"text" = "And here we are. Forever. Isn't it perfect?",
		"actions" = list(
			"its_a_prison" = list(
				"text" = "It's a prison.",
				"default_scene" = "denial_prison"
			),
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["denial_prison"] = list(
		"text" = "Prison? *He laughs.* No, no. A prison keeps you from what you love. Here, I have everything I could ever want.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// ABOUT THE SERPENT
	// ==========================================================================

	scenes["about_serpent_1"] = list(
		"text" = "The Serpent? *A flicker of fear crosses his face.* Yes, I know the Serpent. It is the keeper of this place.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_serpent_2"
			)
		)
	)

	scenes["about_serpent_2"] = list(
		"text" = "It gave me this gift. This perfect, frozen moment. In exchange, I simply... stay.",
		"actions" = list(
			"stay_forever" = list(
				"text" = "Stay forever?",
				"default_scene" = "about_serpent_3"
			),
			"is_it_dangerous" = list(
				"text" = "Is it dangerous?",
				"default_scene" = "serpent_dangerous"
			)
		)
	)

	scenes["about_serpent_3"] = list(
		"text" = "Time means nothing here. Forever is just... a longer dinner. And my family never leaves the table.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["serpent_dangerous"] = list(
		"text" = "Dangerous? Only to those who try to leave. It doesn't like when guests depart early.",
		"actions" = list(
			"what_happens" = list(
				"text" = "What happens to them?",
				"default_scene" = "serpent_warning"
			),
			"back" = list(
				"text" = "I see.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["serpent_warning"] = list(
		"text" = "*He leans in close, whispering.* They become part of the stories. Pages in the book. Their desires made real... forever.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// HELP / ESCAPE
	// ==========================================================================

	scenes["help_1"] = list(
		"text" = "Escape? *He looks confused.* Why would you want to escape? Everything you need is here.",
		"actions" = list(
			"i_dont_belong" = list(
				"text" = "I don't belong here.",
				"default_scene" = "help_2"
			),
			"back" = list(
				"text" = "Never mind.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["help_2"] = list(
		"text" = "No one belongs anywhere until they accept it. I didn't belong here either, once. Now I can't imagine being anywhere else.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "help_3"
			)
		)
	)

	scenes["help_3"] = list(
		"text" = "But if you truly wish to leave... the door always leads closer to zero. The beginning. The end. Chapter 0 is the exit, they say.",
		"actions" = list(
			"chapter_zero" = list(
				"text" = "Chapter 0?",
				"default_scene" = "chapter_zero_info"
			),
			"thank_you" = list(
				"text" = "Thank you.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["chapter_zero_info"] = list(
		"text" = "The first page. Or the last, depending on how you read it. But be warned - the closer you get to leaving, the more the book... changes you.",
		"actions" = list(
			"changes_how" = list(
				"text" = "Changes me how?",
				"default_scene" = "curse_warning"
			),
			"back" = list(
				"text" = "I see.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["curse_warning"] = list(
		"text" = "The pages want to keep you. The deeper you go, the more you become like us. Part of the story. Part of the book.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "curse_warning_2"
			)
		)
	)

	scenes["curse_warning_2"] = list(
		"text" = "*He looks at his own hands. For a moment, you see brass gears turning beneath his skin.* We all become what we most desire, in the end.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// CONFRONTATION
	// ==========================================================================

	scenes["confrontation_1"] = list(
		"text" = "*His face contorts with sudden rage.* They ARE real! They're as real as anything in this place!",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "confrontation_2"
			)
		)
	)

	scenes["confrontation_2"] = list(
		"text" = "*The clocks on the walls begin ticking louder, faster.* I MADE them real! Every gear, every spring, every... every...",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "confrontation_3"
			)
		)
	)

	scenes["confrontation_3"] = list(
		"text" = "*He collapses back into his chair, suddenly exhausted.* ...Every piece of them that I could remember.",
		"actions" = list(
			"im_sorry" = list(
				"text" = "I'm sorry. I didn't mean to...",
				"default_scene" = "confrontation_resolution"
			),
			"truth" = list(
				"text" = "You know the truth, don't you?",
				"default_scene" = "truth_1"
			)
		)
	)

	scenes["confrontation_resolution"] = list(
		"text" = "*He takes a deep breath.* No. No, it's... it's fine. I know what they are. I've always known. But knowing doesn't make it hurt less.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["truth_1"] = list(
		"text" = "*His voice is barely a whisper.* Of course I know. Every night, I wind them up. Every morning, I find pieces of them scattered across the floor.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "truth_2"
			)
		)
	)

	scenes["truth_2"] = list(
		"text" = "Sometimes... sometimes when I look away, I hear them scream. Voices in the gears. Begging me to let them rest.",
		"actions" = list(
			"let_them_go" = list(
				"text" = "Then let them go.",
				"default_scene" = "cant_let_go"
			),
			"..." = list(
				"text" = "...",
				"default_scene" = "truth_3"
			)
		)
	)

	scenes["truth_3"] = list(
		"text" = "But I can't. I won't. Because then I'd have nothing. And nothing is worse than this beautiful, terrible lie.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["cant_let_go"] = list(
		"text" = "Let them go? *He laughs bitterly.* I tried once. I stopped winding them. Let them fall silent.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "cant_let_go_2"
			)
		)
	)

	scenes["cant_let_go_2"] = list(
		"text" = "Three days of silence. Three days alone. Then the Serpent came. It said I had a choice - wind them again, or become one of them.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "cant_let_go_3"
			)
		)
	)

	scenes["cant_let_go_3"] = list(
		"text" = "So I wound them. And I keep winding them. Because at least this way, I can pretend.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// FAREWELL
	// ==========================================================================

	scenes["farewell"] = list(
		"text" = "Leaving already? Well, you're always welcome back. We don't get many visitors.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "farewell_2"
			)
		)
	)

	scenes["farewell_2"] = list(
		"text" = "*He turns back to his family, picking up a fork.* Come now, everyone. Let's eat before it gets cold. Even though it never does.",
		"actions" = list(
			"close" = list(
				"text" = "*Leave*",
				"close_dialogue" = TRUE
			)
		)
	)

	return scenes

/// Called when player questions the NPC's reality
/mob/living/simple_animal/hostile/ui_npc/serpent_resident/clockmaker/on_player_suspicious(mob/user)
	. = ..()
	// The clocks tick faster when confronted
	playsound(src, 'sound/machines/clockwork/clock_tick.ogg', 50, TRUE)
