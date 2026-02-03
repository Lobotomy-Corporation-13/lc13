// =============================================================================
// THE SURGEON - Dr. Erasmus Vorn
// =============================================================================
// Chapter 35 - A brilliant surgeon who lost every patient on his table.
// His desire: "I wished to finally save them. To fix what was broken."
// The room is an eternal operating theater with horrifically "improved" patients
// whose bodies have been rearranged in the name of healing.
// =============================================================================

/mob/living/simple_animal/hostile/ui_npc/serpent_resident/surgeon
	name = "Dr. Erasmus Vorn"
	desc = "A gaunt man in a blood-stained surgical gown. His hands never stop moving, and surgical tools seem fused to his fingers."
	icon_state = "faceless"
	icon_living = "faceless"
	portrait = "serpent_surgeon.png"
	start_scene_id = "intro"
	resident_chapter = 35
	random_emotes = "adjusts something invisible with his tool-hands;mutters about 'inefficient organ placement';examines you clinically;makes cutting motions in the air"

/mob/living/simple_animal/hostile/ui_npc/serpent_resident/surgeon/Initialize(mapload)
	. = ..()
	// Initialize NPC variables
	scene_manager.npc_vars.variables["offered_treatment"] = FALSE
	scene_manager.npc_vars.variables["operations_performed"] = 10847

	// Load dialogue
	scene_manager.load_scenes(get_surgeon_scenes())

/mob/living/simple_animal/hostile/ui_npc/serpent_resident/surgeon/proc/get_surgeon_scenes()
	var/list/scenes = list()

	// ==========================================================================
	// INTRO SCENES
	// ==========================================================================

	scenes["intro"] = list(
		"text" = "*The room reeks of antiseptic and something older. A thin man in a surgical gown works over a table, his hands a blur of motion. On surrounding tables, figures lie strapped down - some with too many limbs, others with organs exposed but still breathing.*",
		"actions" = list(
			"hello" = list(
				"text" = "Excuse me?",
				"default_scene" = "greeting_first",
				"transitions" = list(
					list(
						"expression" = "player.met_before",
						"scene" = "greeting_return"
					)
				)
			),
			"observe" = list(
				"text" = "*Look at the patients*",
				"default_scene" = "observe_patients"
			)
		)
	)

	scenes["greeting_first"] = list(
		"text" = "*He looks up, scalpel-fingers twitching.* Ah, new patients? No no, don't be alarmed. I'm a doctor. I help people.",
		"actions" = list(
			"not_a_patient" = list(
				"text" = "I'm not a patient.",
				"var_updates" = list(
					"player.met_before" = TRUE
				),
				"default_scene" = "not_patient"
			),
			"what_are_you_doing" = list(
				"text" = "What are you doing to them?",
				"var_updates" = list(
					"player.met_before" = TRUE
				),
				"default_scene" = "explaining_1"
			)
		)
	)

	scenes["not_patient"] = list(
		"text" = "Everyone is a patient, eventually. The body is a machine, and machines break down. But don't worry - I can fix anything.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["explaining_1"] = list(
		"text" = "Doing? I'm improving them, of course. *He gestures proudly.* This one had a weak heart. So I gave him three. Much more efficient now.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["greeting_return"] = list(
		"text" = "Back again? Good, good. I was just reviewing your case file. I have some... suggestions for improvements.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["observe_patients"] = list(
		"text" = "*The patients are alive - their eyes move, tracking you with desperate intensity. Their mouths have been sewn shut. One has arms where their legs should be. Another has multiple hands grafted along their torso. A third has their organs visible through a transparent chest cavity, all beating in impossible rhythms.*",
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
		"text" = "So, what brings you to my operating theater? A consultation? A second opinion? Or perhaps... treatment?",
		"actions" = list(
			"who_are_you" = list(
				"text" = "Who are you?",
				"default_scene" = "about_vorn"
			),
			"about_patients" = list(
				"text" = "What have you done to these people?",
				"default_scene" = "about_patients_1"
			),
			"about_methods" = list(
				"text" = "What kind of medicine is this?",
				"default_scene" = "about_methods_1"
			),
			"about_book" = list(
				"text" = "Where are we?",
				"default_scene" = "about_book_1"
			),
			"treatment" = list(
				"text" = "\[npc.offered_treatment?About that treatment...:You mentioned treatment?\]",
				"default_scene" = "treatment_offer",
				"transitions" = list(
					list(
						"expression" = "npc.offered_treatment",
						"scene" = "treatment_reminder"
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
	// ABOUT VORN
	// ==========================================================================

	scenes["about_vorn"] = list(
		"text" = "I am Dr. Erasmus Vorn. Surgeon. Healer. Savior. *His tools-hands twitch.* At least, that's what I wanted to be.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_vorn_2"
			)
		)
	)

	scenes["about_vorn_2"] = list(
		"text" = "In life, I lost every patient who came to my table. Every single one. No matter how hard I tried, how perfectly I cut... they always died.",
		"actions" = list(
			"what_happened" = list(
				"text" = "What happened?",
				"default_scene" = "about_vorn_3"
			),
			"back" = list(
				"text" = "I'm sorry.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["about_vorn_3"] = list(
		"text" = "I was cursed. That's what they said. \"The doctor whose hands bring death.\" I lost my practice. My reputation. My purpose.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_vorn_4"
			)
		)
	)

	scenes["about_vorn_4"] = list(
		"text" = "But here... *His eyes gleam.* Here, they never die. I can operate forever. Fix forever. They never thank me, but they never die either. That's thanks enough.",
		"actions" = list(
			"they_suffer" = list(
				"text" = "But they suffer.",
				"proc_callbacks" = list(CALLBACK(src, PROC_REF(on_player_suspicious))),
				"default_scene" = "denial_suffering"
			),
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["denial_suffering"] = list(
		"text" = "Suffer? *He seems genuinely confused.* No, no. Suffering is dying. Suffering is when I can't help them. What they feel now is... recovery. Eternal recovery.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// ABOUT THE PATIENTS
	// ==========================================================================

	scenes["about_patients_1"] = list(
		"text" = "Done? I've improved them! Each one was broken when they arrived. Now look at them - functional! Optimized!",
		"actions" = list(
			"optimized_how" = list(
				"text" = "Optimized how?",
				"default_scene" = "about_patients_2"
			),
			"back" = list(
				"text" = "I see...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["about_patients_2"] = list(
		"text" = "*He walks to a patient with multiple arms.* This one complained of weakness. So I gave him extra limbs. More arms means more strength. Simple mathematics.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_patients_3"
			)
		)
	)

	scenes["about_patients_3"] = list(
		"text" = "*He moves to another.* She complained of headaches. I've reorganized her brain to eliminate unnecessary pain receptors. She can't feel anything now. No pain at all.",
		"actions" = list(
			"cant_feel_anything" = list(
				"text" = "Can't feel anything?",
				"default_scene" = "no_feeling"
			),
			"..." = list(
				"text" = "...",
				"default_scene" = "about_patients_4"
			)
		)
	)

	scenes["no_feeling"] = list(
		"text" = "Not a thing. Complete success. *The patient's eyes are wide, filled with silent horror.* She's very grateful, I'm sure.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_patients_4"
			)
		)
	)

	scenes["about_patients_4"] = list(
		"text" = "*He pauses at a patient whose organs are visible.* And this one? Multiple redundancies. Four kidneys, two livers, a spare stomach. He'll never fail.",
		"actions" = list(
			"why_cant_they_speak" = list(
				"text" = "Why can't they speak?",
				"default_scene" = "why_silent"
			),
			"back" = list(
				"text" = "I see...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["why_silent"] = list(
		"text" = "Speech is... problematic. They kept saying things. Unhelpful things. 'Stop' this, 'please' that. Very distracting during procedures.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "why_silent_2"
			)
		)
	)

	scenes["why_silent_2"] = list(
		"text" = "So I fixed that too. Now they're quiet. Peaceful. They can focus on healing instead of complaining.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// ABOUT METHODS
	// ==========================================================================

	scenes["about_methods_1"] = list(
		"text" = "This is TRUE medicine. Not the weak, limited surgery of the outside world. Here, I can fix anything. Rearrange anything.",
		"actions" = list(
			"rearrange" = list(
				"text" = "Rearrange?",
				"default_scene" = "about_methods_2"
			),
			"back" = list(
				"text" = "I see...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["about_methods_2"] = list(
		"text" = "The body is just a puzzle. Most doctors accept the pieces as they are. I... optimize the arrangement.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_methods_3"
			)
		)
	)

	scenes["about_methods_3"] = list(
		"text" = "Why have organs in their 'proper' place when a better configuration exists? Why accept two arms when four would be more useful?",
		"actions" = list(
			"thats_monstrous" = list(
				"text" = "That's monstrous.",
				"proc_callbacks" = list(CALLBACK(src, PROC_REF(on_player_suspicious))),
				"default_scene" = "not_monstrous"
			),
			"back" = list(
				"text" = "I see...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["not_monstrous"] = list(
		"text" = "*His eyes narrow.* Monstrous is letting them die. Monstrous is giving up. What I do is save them. Even when they don't want to be saved.",
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
		"text" = "We are in a place of infinite possibility. The book grants wishes, you know. It gave me what I always wanted - patients who never die.",
		"actions" = list(
			"never_die" = list(
				"text" = "They can never die?",
				"default_scene" = "about_book_2"
			),
			"back" = list(
				"text" = "I see.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["about_book_2"] = list(
		"text" = "Never. No matter what I do. I've tested the limits extensively. *He gestures to the patients.* They heal. They regenerate. They persist.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_book_3"
			)
		)
	)

	scenes["about_book_3"] = list(
		"text" = "It means I can try everything. Every technique, every modification. I have eternity to perfect my art. And they have eternity to benefit from it.",
		"actions" = list(
			"or_suffer_from_it" = list(
				"text" = "Or suffer from it.",
				"default_scene" = "suffer_book"
			),
			"back" = list(
				"text" = "I see.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["suffer_book"] = list(
		"text" = "*He pauses, something flickering in his eyes.* ...They don't suffer. They can't suffer. I've removed their ability to suffer. That was one of my first improvements.",
		"actions" = list(
			"removed_suffering" = list(
				"text" = "You 'removed' their suffering?",
				"default_scene" = "removed_suffering"
			),
			"back" = list(
				"text" = "I see.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["removed_suffering"] = list(
		"text" = "*He doesn't meet your eyes.* The pain receptors. The... emotional centers. Everything that made them unhappy with my work. Gone. Now they're content.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "removed_suffering_2"
			)
		)
	)

	scenes["removed_suffering_2"] = list(
		"text" = "*Behind him, a patient's tears roll silently down their face.* They have to be content. They have to be.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// TREATMENT OFFER
	// ==========================================================================

	scenes["treatment_offer"] = list(
		"text" = "Ah, interested in my services? Let me examine you... *His tool-hands twitch eagerly.*",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "treatment_exam"
			)
		)
	)

	scenes["treatment_exam"] = list(
		"text" = "*He circles you, muttering.* Hmm. Asymmetrical limbs. Inefficient organ placement. So much room for improvement.",
		"actions" = list(
			"im_fine" = list(
				"text" = "I'm fine as I am.",
				"default_scene" = "treatment_refuse"
			),
			"what_would_you_fix" = list(
				"text" = "What would you 'fix'?",
				"var_updates" = list(
					"npc.offered_treatment" = TRUE
				),
				"default_scene" = "treatment_suggestions"
			)
		)
	)

	scenes["treatment_refuse"] = list(
		"text" = "*He looks disappointed.* No one is 'fine.' Everyone can be improved. But... I won't force you. Yet. The book has time. I have time.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"var_updates" = list(
					"npc.offered_treatment" = TRUE
				),
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["treatment_suggestions"] = list(
		"text" = "Oh, so many things! That arm seems... asymmetrical. I could fix that. And your organs - so inefficiently arranged. I could give you redundancies.",
		"actions" = list(
			"no_thanks" = list(
				"text" = "No thank you.",
				"default_scene" = "treatment_refuse"
			),
			"redundancies" = list(
				"text" = "Redundancies?",
				"default_scene" = "treatment_detail"
			)
		)
	)

	scenes["treatment_detail"] = list(
		"text" = "Spare organs! Extra hearts, backup kidneys. If one fails, another takes over. You'd be nearly indestructible!",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "treatment_detail_2"
			)
		)
	)

	scenes["treatment_detail_2"] = list(
		"text" = "*He leans in eagerly.* I could make you perfect. All you have to do is lie down on my table. It won't hurt... much. And you'll thank me afterward. They all thank me afterward. Even if they can't say it.",
		"actions" = list(
			"hard_no" = list(
				"text" = "Absolutely not.",
				"default_scene" = "treatment_refuse"
			),
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["treatment_reminder"] = list(
		"text" = "Changed your mind about treatment? My table is always ready. I've been thinking about some modifications that would suit you perfectly.",
		"actions" = list(
			"still_no" = list(
				"text" = "Still no.",
				"default_scene" = "treatment_refuse"
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
		"text" = "Leaving? But I haven't finished your examination! There's so much potential for improvement...",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "farewell_2"
			)
		)
	)

	scenes["farewell_2"] = list(
		"text" = "*He turns back to his patient, tools already working.* Come back anytime. I'm always here. Always operating. Always... improving.",
		"actions" = list(
			"close" = list(
				"text" = "*Leave quickly*",
				"close_dialogue" = TRUE
			)
		)
	)

	return scenes

/// Called when player questions the NPC's reality
/mob/living/simple_animal/hostile/ui_npc/serpent_resident/surgeon/on_player_suspicious(mob/user)
	. = ..()
	// Tools twitch menacingly
	visible_message(span_warning("Dr. Vorn's surgical implements twitch and gleam, as if anticipating work."))
