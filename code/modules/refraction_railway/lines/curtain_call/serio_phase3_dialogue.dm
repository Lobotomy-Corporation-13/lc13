/*
 * Phase 3 dialogue tables + sequencer.
 *
 * Each bracket opens with a 3-4 line exchange between the Caretaker,
 * the Sage, and the Knight. Final beat (after the B3 slash) closes
 * the encounter before the dissolve sequence.
 *
 * Build-order step 16 (per-bracket entries) + step 17 (final beat).
 *
 * Lines verbatim from /mnt/c/games/lc13_claude/serio_brainstorm.md
 * — Dialogue exchanges section.
 */

// Speaker role → mob ref on the Caretaker. Keeps the line tables free
// of typecast clutter.
/mob/living/simple_animal/hostile/serio_caretaker/proc/GetDialogueSpeaker(role)
	switch(role)
		if("caretaker")
			return src
		if("sage")
			return sage_ref
		if("knight")
			return knight_ref

/// Returns a list of (speaker_role, text) pairs for the given bracket.
/// Caller iterates and schedules each line via PlayBracketDialogue.
/mob/living/simple_animal/hostile/serio_caretaker/proc/GetBracketLines(bracket)
	switch(bracket)
		if(1)
			return list(
				list("speaker_role" = "caretaker", "text" = "Look at what you make. Look at who flinches. The honest move here is to put the stage down and never pick it up again. You stop the wounds by not making them."),
				list("speaker_role" = "sage", "text" = "And the same audience comes back the next day. That return is theirs — they're choosing it, knowing you'll miss again. Putting the stage down doesn't honor that. It overrides it."),
				list("speaker_role" = "caretaker", "text" = "They come back out of habit. Out of pity."),
				list("speaker_role" = "knight", "text" = "They come back because they want the next one. Make the next one."),
			)
		if(2)
			return list(
				list("speaker_role" = "caretaker", "text" = "Every hour here is an hour you aren't with them. The group is drifting and you're choosing the stage over them. Leave it. Be with them while they're still close."),
				list("speaker_role" = "sage", "text" = "The group is drifting because of the year. Children grow. Partners move. Jobs harden. The stage isn't the gap — it's what you can point at, so it's where the blame lands. The drift would happen if you walked off the stage tonight."),
				list("speaker_role" = "caretaker", "text" = "And if I'm wrong, the stage stays. If I'm right, you lose them. Which risk do you take?"),
				list("speaker_role" = "sage", "text" = "The one where Star gets to keep being Star while loving them. Neither of those needs the other to die."),
			)
		if(3)
			return list(
				list("speaker_role" = "caretaker", "text" = "You missed the last person you loved. You missed because you couldn't get out of your own head. You will do this again. The protection here is to leave the room. Stop reaching for them."),
				list("speaker_role" = "sage", "text" = "Or stay, and miss, and have someone next to you when you do. The pattern you're naming isn't 'Star hurts the people who stay.' It's 'Star misses, and the ones who stayed catch them.' That's what staying is for. Plan for the ones who'll do that."),
				list("speaker_role" = "caretaker", "text" = "Some won't stay for that."),
				list("speaker_role" = "knight", "text" = "Some will. Plan for the some."),
			)
	return list()

/// Schedules each line of the bracket exchange via addtimer + say(),
/// 2.5 seconds apart. Called from EnterPhase3 for B1 and from
/// OnKnightSlashLanded for B2/B3.
/mob/living/simple_animal/hostile/serio_caretaker/proc/PlayBracketDialogue(bracket)
	var/list/lines = GetBracketLines(bracket)
	if(!length(lines))
		return
	var/delay = 0
	for(var/list/L as anything in lines)
		var/mob/speaker = GetDialogueSpeaker(L["speaker_role"])
		var/text = L["text"]
		if(speaker && text)
			addtimer(CALLBACK(speaker, TYPE_PROC_REF(/atom/movable, say), text), delay, TIMER_STOPPABLE)
		delay += 2.5 SECONDS

/// Plays the post-B3-slash exchange. Called from EndEncounter.
/// 3 lines: Caretaker walks off saying it was right all along, Sage
/// leaves the door open, Knight closes with "Curtain."
/mob/living/simple_animal/hostile/serio_caretaker/proc/PlayFinalBeatDialogue()
	var/list/lines = list(
		list("speaker_role" = "caretaker", "text" = "...they'll see. Eventually. They'll see I was protecting them from you."),
		list("speaker_role" = "sage", "text" = "Then we'll be here for that conversation too. You can come back to it. We're not the door — we're a chair in the room."),
		list("speaker_role" = "knight", "text" = "Curtain."),
	)
	var/delay = 0
	for(var/list/L as anything in lines)
		var/mob/speaker = GetDialogueSpeaker(L["speaker_role"])
		var/text = L["text"]
		if(speaker && text)
			addtimer(CALLBACK(speaker, TYPE_PROC_REF(/atom/movable, say), text), delay, TIMER_STOPPABLE)
		delay += 2.5 SECONDS
