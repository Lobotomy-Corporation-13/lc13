// =============================================================================
// THE COLLECTOR - Lord Aldric Thorne
// =============================================================================
// Chapter 20 - A wealthy aristocrat obsessed with owning rare, beautiful things.
// His desire: "I wished to possess everything precious. To own beauty itself."
// The room is a museum filled with preserved specimens - including conscious
// humans frozen in crystal display cases.
// =============================================================================

/mob/living/simple_animal/hostile/ui_npc/serpent_resident/collector
	name = "Lord Aldric Thorne"
	desc = "An impeccably dressed nobleman with cold, appraising eyes. His hands never stop adjusting and positioning things."
	icon_state = "faceless"
	icon_living = "faceless"
	portrait = "serpent_collector.png"
	start_scene_id = "intro"
	resident_chapter = 20
	random_emotes = "polishes an invisible display;adjusts something with precise movements;appraises you with a calculating look;mutters about 'market value'"

/mob/living/simple_animal/hostile/ui_npc/serpent_resident/collector/Initialize(mapload)
	. = ..()
	// Initialize NPC variables
	scene_manager.npc_vars.variables["offered_deal"] = FALSE
	scene_manager.npc_vars.variables["collection_size"] = 342

	// Load dialogue
	scene_manager.load_scenes(get_collector_scenes())

/mob/living/simple_animal/hostile/ui_npc/serpent_resident/collector/proc/get_collector_scenes()
	var/list/scenes = list()

	// ==========================================================================
	// INTRO SCENES
	// ==========================================================================

	scenes["intro"] = list(
		"text" = "*You enter a vast hall filled with display cases. Rare artifacts, extinct creatures preserved in crystal, and... people. Beautiful people frozen in glass cases like specimens. An elegantly dressed man notices your arrival.*",
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
				"text" = "*Look at the displays*",
				"default_scene" = "observe_displays"
			)
		)
	)

	scenes["greeting_first"] = list(
		"text" = "*He approaches with measured steps, eyes scanning you from head to toe.* Welcome, welcome to my collection! The finest gathering of rarities in any reality.",
		"actions" = list(
			"thank_you" = list(
				"text" = "Thank you...",
				"var_updates" = list(
					"player.met_before" = TRUE
				),
				"default_scene" = "greeting_2"
			),
			"those_are_people" = list(
				"text" = "Are those... people?",
				"var_updates" = list(
					"player.met_before" = TRUE
				),
				"default_scene" = "people_direct"
			)
		)
	)

	scenes["greeting_2"] = list(
		"text" = "*His eyes linger on your features.* Hmm. Interesting bone structure. Expressive eyes. Tell me, have you ever considered... immortality?",
		"actions" = list(
			"what" = list(
				"text" = "What?",
				"default_scene" = "main_menu"
			),
			"suspicious" = list(
				"text" = "Why are you looking at me like that?",
				"default_scene" = "appraisal"
			)
		)
	)

	scenes["people_direct"] = list(
		"text" = "People? *He chuckles.* Specimens. The rarest and most beautiful specimens in existence. Each one preserved at the peak of their perfection.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["appraisal"] = list(
		"text" = "Forgive me. Old habits. I simply can't help but appraise... beauty. You have certain qualities that catch my eye.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["greeting_return"] = list(
		"text" = "Ah, my frequent visitor returns! Have you come to admire the collection? Or perhaps... to discuss a transaction?",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["observe_displays"] = list(
		"text" = "*The display cases contain wonders and horrors. A butterfly with wings of pure gold. An extinct flower that still blooms. And the people - frozen mid-motion, their eyes somehow still aware, tracking you as you pass. A small placard reads: 'Acquired - Date Unknown. Condition: Perfect.'*",
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
		"text" = "Now then, how may I assist you? Are you a fellow collector? A curious visitor? Or perhaps... a potential acquisition?",
		"actions" = list(
			"who_are_you" = list(
				"text" = "Who are you?",
				"default_scene" = "about_thorne"
			),
			"about_collection" = list(
				"text" = "Tell me about your collection.",
				"default_scene" = "about_collection_1"
			),
			"about_specimens" = list(
				"text" = "The people in the cases - who are they?",
				"default_scene" = "about_specimens_1"
			),
			"about_book" = list(
				"text" = "Where are we?",
				"default_scene" = "about_book_1"
			),
			"empty_case" = list(
				"text" = "I notice an empty display case.",
				"default_scene" = "empty_case_1",
				"transitions" = list(
					list(
						"expression" = "npc.offered_deal",
						"scene" = "deal_reminder"
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
	// ABOUT THORNE
	// ==========================================================================

	scenes["about_thorne"] = list(
		"text" = "I am Lord Aldric Thorne. Collector. Connoisseur. Curator of the exquisite.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_thorne_2"
			)
		)
	)

	scenes["about_thorne_2"] = list(
		"text" = "In life, I amassed the greatest collection of rarities in the known world. Art, artifacts, creatures... I owned them all.",
		"actions" = list(
			"what_happened" = list(
				"text" = "What happened?",
				"default_scene" = "about_thorne_3"
			),
			"back" = list(
				"text" = "Impressive.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["about_thorne_3"] = list(
		"text" = "But it was never enough. Things break. Things age. Things are stolen. I wanted my collection to be eternal. To own beauty itself, forever.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_thorne_4"
			)
		)
	)

	scenes["about_thorne_4"] = list(
		"text" = "And here, in the book's pages, I can. Everything beautiful deserves to be preserved. Owned. Protected from the ravages of time.",
		"actions" = list(
			"protected_or_trapped" = list(
				"text" = "Protected or trapped?",
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
		"text" = "*He waves dismissively.* Semantics. A rare flower in a garden is at the mercy of weather, pests, time. A rare flower in my collection exists forever, unchanging, perfect. Which is truly free?",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// ABOUT COLLECTION
	// ==========================================================================

	scenes["about_collection_1"] = list(
		"text" = "My collection? *His eyes gleam with pride.* Over three hundred specimens. Each one unique. Each one... mine.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_collection_2"
			)
		)
	)

	scenes["about_collection_2"] = list(
		"text" = "*He gestures to various displays.* That golden butterfly? The last of its kind. That flower? Extinct for ten thousand years. And those... *He points to the human displays.* ...those are my pride and joy.",
		"actions" = list(
			"the_people" = list(
				"text" = "The people?",
				"default_scene" = "about_specimens_1"
			),
			"how_preserved" = list(
				"text" = "How do you preserve them?",
				"default_scene" = "preservation"
			)
		)
	)

	scenes["preservation"] = list(
		"text" = "The book provides. The crystal cases freeze time itself. Nothing ages. Nothing decays. They exist in perfect stasis, forever beautiful, forever mine.",
		"actions" = list(
			"are_they_aware" = list(
				"text" = "Are they aware?",
				"default_scene" = "awareness"
			),
			"back" = list(
				"text" = "I see...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["awareness"] = list(
		"text" = "*He pauses.* ...Perhaps. Some say they can see their eyes move. But what does it matter? They are preserved. They are beautiful. They are appreciated.",
		"actions" = list(
			"it_matters" = list(
				"text" = "It matters a great deal.",
				"proc_callbacks" = list(CALLBACK(src, PROC_REF(on_player_suspicious))),
				"default_scene" = "dismissive_awareness"
			),
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["dismissive_awareness"] = list(
		"text" = "*He frowns.* To whom? Outside, they would age. Grow ugly. Die. Here, they are eternal. I have given them the greatest gift - preservation.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// ABOUT SPECIMENS (PEOPLE)
	// ==========================================================================

	scenes["about_specimens_1"] = list(
		"text" = "My human specimens? The crown jewels of my collection. Each one selected for specific qualities.",
		"actions" = list(
			"qualities" = list(
				"text" = "What qualities?",
				"default_scene" = "about_specimens_2"
			),
			"back" = list(
				"text" = "I see...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["about_specimens_2"] = list(
		"text" = "*He leads you to a case containing a woman frozen mid-dance.* This one? A dancer. Perfect grace. I captured her at the apex of her final performance.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_specimens_3"
			)
		)
	)

	scenes["about_specimens_3"] = list(
		"text" = "*He moves to another - a man with a gentle smile.* That one? A poet. The most beautiful words flowed from his lips. Now his beauty is silent but eternal.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "about_specimens_4"
			)
		)
	)

	scenes["about_specimens_4"] = list(
		"text" = "*He pauses at a case containing only hands - perfectly preserved, arranged like an art piece.* Sometimes I only need a part. Those hands belonged to a sculptor. Perfect bone structure.",
		"actions" = list(
			"just_hands" = list(
				"text" = "Just... hands?",
				"default_scene" = "just_parts"
			),
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["just_parts"] = list(
		"text" = "Why preserve imperfection when perfection can be isolated? Some specimens are beautiful only in part. I keep the parts worth keeping.",
		"actions" = list(
			"thats_horrible" = list(
				"text" = "That's horrible.",
				"proc_callbacks" = list(CALLBACK(src, PROC_REF(on_player_suspicious))),
				"default_scene" = "horrible_response"
			),
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["horrible_response"] = list(
		"text" = "Horrible? *He seems genuinely confused.* Waste is horrible. Letting beauty fade is horrible. I simply... curate. Select. Preserve what matters.",
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
		"text" = "We are in the Serpent's Library. A place where desires become reality. My desire was simple - to own everything precious. Forever.",
		"actions" = list(
			"the_serpent" = list(
				"text" = "The Serpent?",
				"default_scene" = "about_book_2"
			),
			"back" = list(
				"text" = "I see.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["about_book_2"] = list(
		"text" = "The keeper of this place. It grants wishes, but always with a price. My price? I can never leave. But why would I want to? My collection is here.",
		"actions" = list(
			"price" = list(
				"text" = "What price do others pay?",
				"default_scene" = "about_book_3"
			),
			"back" = list(
				"text" = "I see.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["about_book_3"] = list(
		"text" = "Others? They become what they desire most. Some become prisoners of their dreams. Some become... acquisitions. *His eyes flick to you.* The book is always collecting.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// EMPTY CASE / DEAL
	// ==========================================================================

	scenes["empty_case_1"] = list(
		"text" = "*His eyes light up.* Ah, you've noticed! Yes, I have a space reserved for something truly special. Something I haven't found yet.",
		"actions" = list(
			"what_are_you_looking_for" = list(
				"text" = "What are you looking for?",
				"default_scene" = "empty_case_2"
			),
			"back" = list(
				"text" = "I see.",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["empty_case_2"] = list(
		"text" = "Something unique. Something with... presence. *He studies you intently.* Tell me, do you consider yourself special?",
		"actions" = list(
			"why_ask" = list(
				"text" = "Why do you ask?",
				"default_scene" = "the_offer"
			),
			"no" = list(
				"text" = "Not particularly.",
				"default_scene" = "everyone_special"
			)
		)
	)

	scenes["everyone_special"] = list(
		"text" = "Everyone is special in some way. It's simply a matter of finding the right angle. The right... frame. *He gestures to the empty case.*",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "the_offer"
			)
		)
	)

	scenes["the_offer"] = list(
		"text" = "I see you admiring my pieces. You have an eye for quality. Such lovely eyes... I could give them a place of honor. A place where they'd be appreciated forever.",
		"actions" = list(
			"youre_offering" = list(
				"text" = "You're offering to... collect me?",
				"var_updates" = list(
					"npc.offered_deal" = TRUE
				),
				"default_scene" = "offer_direct"
			),
			"absolutely_not" = list(
				"text" = "Absolutely not.",
				"default_scene" = "offer_refused"
			)
		)
	)

	scenes["offer_direct"] = list(
		"text" = "I prefer 'preserve.' Think of it - no aging, no decay, no pain of living. Just... existing. Perfect. Admired. Forever.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "offer_detail"
			)
		)
	)

	scenes["offer_detail"] = list(
		"text" = "The process is painless. One moment you're here, the next... you're eternal. Visitors will come. They'll see you. They'll remember you. Isn't that what everyone wants?",
		"actions" = list(
			"no" = list(
				"text" = "No.",
				"default_scene" = "offer_refused"
			),
			"thats_death" = list(
				"text" = "That sounds like death.",
				"default_scene" = "not_death"
			)
		)
	)

	scenes["not_death"] = list(
		"text" = "Death is being forgotten. Death is fading away. This is the opposite of death. This is eternal presence. Eternal... ownership.",
		"actions" = list(
			"still_no" = list(
				"text" = "Still no.",
				"default_scene" = "offer_refused"
			),
			"..." = list(
				"text" = "...",
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["offer_refused"] = list(
		"text" = "*Something cold enters his eyes.* Pity. But I am patient. Beauty is worth waiting for. And you cannot leave forever. Sooner or later, everyone... joins the collection.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"var_updates" = list(
					"npc.offered_deal" = TRUE
				),
				"default_scene" = "main_menu"
			)
		)
	)

	scenes["deal_reminder"] = list(
		"text" = "Changed your mind about the display case? It remains empty. Reserved for something special. Reserved, perhaps... for you.",
		"actions" = list(
			"still_no" = list(
				"text" = "Still not interested.",
				"default_scene" = "offer_refused"
			),
			"back" = list(
				"text" = "I was just looking.",
				"default_scene" = "main_menu"
			)
		)
	)

	// ==========================================================================
	// FAREWELL
	// ==========================================================================

	scenes["farewell"] = list(
		"text" = "Leaving so soon? Do come back. My doors are always open to those who appreciate... beauty.",
		"actions" = list(
			"..." = list(
				"text" = "...",
				"default_scene" = "farewell_2"
			)
		)
	)

	scenes["farewell_2"] = list(
		"text" = "*He turns back to his displays, adjusting a case slightly.* Remember - everything beautiful ends up in a collection eventually. The only question is... whose.",
		"actions" = list(
			"close" = list(
				"text" = "*Leave*",
				"close_dialogue" = TRUE
			)
		)
	)

	return scenes

/// Called when player questions the NPC's reality
/mob/living/simple_animal/hostile/ui_npc/serpent_resident/collector/on_player_suspicious(mob/user)
	. = ..()
	// The display cases seem to close in
	visible_message(span_warning("The preserved figures in the display cases seem to lean toward [user], their frozen eyes pleading."))
