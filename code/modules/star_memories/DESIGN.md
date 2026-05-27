# Secrets of the Stars — Design

A side feature bolted onto the Refraction Railway. Players who have
completed at least one railway run gain access to a hidden room with a
memory-viewing console. Each "memory" is a small lore vignette about
Serio Zeal (the Young Star). Selecting a memory loads its own
Z-level, projects the lobby's minds into ghostly observer mobs, runs a
dev-authored script of NPC says/emotes/walks, then ~3 seconds after
the script ends returns each mind to its original body.

This document is the architecture spec. **No code in this folder is
implemented yet** — this is step 1 of the implementation order at the
bottom of this file.

---

## Scope

- **Door gate**: any ckey that has ever finished any Refraction
  Railway line. Lookup goes through
  `SSrefraction_railway.leaderboards` — the data already persists
  across rounds in `data/refraction_railway_leaderboards.json`, no new
  save file needed.
- **Concurrency**: **lobby-based**, mirroring the railway hub. Players
  form a memory-viewing lobby; the leader starts the session; all
  members project simultaneously at the same player-spawn landmark
  (extra members stack on the same tile).

---

## Module layout

New top-level module: `code/modules/star_memories/`.

| File | Purpose |
|---|---|
| `_memory_subsystem.dm` | `/datum/controller/subsystem/star_memories` — registers memories, owns Z-lane bookkeeping, mirrors `SSrefraction_railway` structure |
| `memory_datum.dm` | `/datum/star_memory` — id, name, description, map_path, npc roster, script |
| `memory_lobby.dm` | `/datum/star_memory_lobby` — lobby + active-session datum (mirrors `/datum/refraction_run`) |
| `console.dm` | `/obj/machinery/computer/star_memory_console` — TGUI entry point |
| `door.dm` | `/obj/machinery/door/star_memory_gate` — gates entry by completion check |
| `landmarks.dm` | `/obj/effect/landmark/star_memory/...` subtypes |
| `mobs.dm` | `/mob/living/simple_animal/star_memory_observer` + `/star_memory_npc` |
| `client_colour.dm` | `/datum/client_colour/star_memory_vision` |
| `scripts/<memory_id>.dm` | one file per memory — the dev-authored datum subtype with its script |

Memories register via `/datum/star_memory` subtypes, collected by
`subtypesof()` at subsystem init (the same trick `InitializeLines()`
uses in `_railway_subsystem.dm:89`). DMM files for memories live in
`_maps/star_memories/<memory_id>.dmm`.

New TGUI interface:
`tgui/packages/tgui/interfaces/StarMemoryViewer.js` — sidebar of
memories + lobby panel + Begin button. Pattern lifted directly from
`RefractionRailway.js`.

---

## Persistence + door gate

Helper proc, placed next to the data it reads in
`code/modules/refraction_railway/_railway_subsystem.dm`:

```dm
/datum/controller/subsystem/refraction_railway/proc/HasCkeyCompletedAnyLine(ckey)
    if(!ckey)
        return FALSE
    for(var/line_id in leaderboards)
        for(var/list/entry in leaderboards[line_id])
            if(entry["ckey"] == ckey)
                return TRUE
    return FALSE
```

The door:

```dm
/obj/machinery/door/star_memory_gate/attack_hand(mob/user)
    if(!SSrefraction_railway.HasCkeyCompletedAnyLine(user.ckey))
        to_chat(user, span_warning("The door does not respond. It \
            will not open for those who have not yet walked the \
            railway."))
        return
    return ..()  // standard door open
```

---

## Console + lobby flow

The console mirrors the refraction hub console's TGUI shape verbatim.
Concrete proc mapping:

| Refraction (existing) | Star Memory (new) |
|---|---|
| `refraction_railway_console` | `/obj/machinery/computer/star_memory_console` |
| `BuildLinesPayload(user)` | `BuildMemoriesPayload(user)` — list of `{id, name, description}` |
| `BuildMyRunPayload(user)` | `BuildMyLobbyPayload(user)` |
| `BuildOpenLobbiesPayload()` | `BuildOpenLobbiesPayload()` (same idea) |
| `ui_act("create_lobby")` | `ui_act("create_lobby")` — `params["memory_id"]` |
| `ui_act("join_lobby")` | same |
| `ui_act("start_run")` | `ui_act("start_viewing")` |

Lobby state machine:

1. **Forming** — players join via `create_lobby` / `join_lobby`. The
   leader sees a "Begin" button.
2. **Loading** — `start_viewing` claims (or loads) the memory's Z
   lane, spawns NPCs from the script roster, projects all lobby
   members.
3. **Playing** — script runs. Each member's screen tinted; original
   bodies in godmode + immobilized.
4. **Ending** — script finishes; subsystem waits 3 seconds; pulls
   every member's mind back to their original body; clears tint +
   godmode + immobilize; releases the Z lane.

---

## Z-level lifecycle

**One shared Z-level for every memory.** A single dmm at
`_maps/star_memories/memories.dmm` lays out every memory's room
side-by-side; each room has its own landmarks scoped by the memory's
id prefix. The first time anyone clicks "Begin" at the console, the
subsystem loads that single dmm to a Z-level and keeps it loaded for
the round. Every memory viewed afterward — same memory or different
— reuses that Z.

Use the same dmm-load helper as the railway
(`_railway_subsystem.dm:431-447`'s `LoadLineZ`, including the
`SSatoms.initialized_changed` save/restore dance). State on the
subsystem:

```dm
var/star_memory_z = 0                    // 0 until the dmm is loaded
var/list/claimed_memories = list()       // memory_id => owning lobby datum
```

Lifecycle:

- First lobby ever to hit "Begin" → `LoadStarMemoryZ()` sets
  `star_memory_z`; lobby claims its memory via
  `claimed_memories[memory_id] = lobby`.
- Subsequent lobbies for a **different** memory → reuse the existing
  Z, claim their memory. Two lobbies can run two different memories
  in parallel because each memory's room and landmarks are separate
  on the same Z.
- Lobby for an **already-claimed** memory → reject with "This memory
  is already being witnessed."
- Session end → `claimed_memories -= memory_id` and the memory's
  NPCs are despawned. The Z itself stays loaded.

---

## Mind projection

For each lobby member, on session start:

```dm
/datum/star_memory_lobby/proc/ProjectMember(mob/living/carbon/human/H)
    var/turf/T = pick(GetLandmarks(/obj/effect/landmark/star_memory/player_spawn))
    var/mob/living/simple_animal/star_memory_observer/G = new(T)
    G.original_body = H
    G.parent_lobby = src
    H.status_flags |= GODMODE
    ADD_TRAIT(H, TRAIT_IMMOBILIZED, STAR_MEMORY_TRAIT)
    H.mind?.transfer_to(G, force_key_move = 1)
    G.add_client_colour(/datum/client_colour/star_memory_vision)
    projected_members += G
```

The observer mob:

```dm
/mob/living/simple_animal/star_memory_observer
    name = "memory"
    icon = 'icons/mob/mob.dmi'
    icon_state = "ghost"
    icon_living = "ghost"
    density = FALSE
    pass_flags = PASSEVERYTHING
    mob_biotypes = MOB_HUMANOID
    health = INFINITY
    maxHealth = INFINITY
    status_flags = GODMODE
    melee_damage_lower = 0
    melee_damage_upper = 0
    can_be_held = FALSE
    response_help_continuous = "looks through"
    var/mob/living/original_body
    var/datum/star_memory_lobby/parent_lobby

/mob/living/simple_animal/star_memory_observer/AttackingTarget(atom/_)
    return FALSE
/mob/living/simple_animal/star_memory_observer/start_pulling(atom/_)
    return FALSE
```

Client tint:

```dm
/datum/client_colour/star_memory_vision
    colour = "#defaff"
    priority = PRIORITY_NORMAL
    fade_in = 8
    fade_out = 8
```

On session end the subsystem iterates `projected_members`, calls
`transfer_to(observer.original_body, force_key_move = 1)`, removes
the client colour, clears `status_flags &= ~GODMODE`, removes the
trait, and `qdel`s the observer. Defensive cleanup runs on lobby
`Destroy()` too (covers disconnects mid-session).

---

## NPC mobs

```dm
/mob/living/simple_animal/star_memory_npc
    name = "static"
    icon = 'icons/effects/effects.dmi'
    icon_state = "static"
    icon_living = "static"
    density = FALSE
    can_be_held = FALSE
    health = 1
    maxHealth = 1
    status_flags = GODMODE
    AIStatus = AI_OFF                // no wander, no aggression
    a_intent = INTENT_HELP
    var/role_id = ""                 // matches script "actor" field
```

`AIStatus = AI_OFF` (per `simple_animal.dm:132`) disables all
automated behavior; the script becomes the sole driver. `density =
FALSE` so player-observers can phase through them.

NPC spawning at session start:

- Subsystem reads the memory's `npcs` roster — an assoc list of
  `role_id => landmark_id`.
- For each entry, finds the matching
  `/obj/effect/landmark/star_memory/npc_spawn` on the loaded Z whose
  `id` matches, spawns an NPC with that `role_id`.
- Stores `npcs_by_role[role_id] = the_npc` for the script driver.

---

## Memory script DSL

List-of-dicts. Each step is one self-contained dict. Delays are
**absolute deciseconds from session start**, so re-ordering or
inserting a step requires only changing one delay value (no cascade).
This matches the existing line-authoring style (`sector_briefings`,
`AddNode` calls — dicts you can scan top to bottom).

```dm
/datum/star_memory/young_star_origin_1
    id          = "young_star_origin_1"
    name        = "First Curtain"
    description = "The night a child first heard the audience clap."
    map_path    = "_maps/star_memories/young_star_origin_1.dmm"
    npcs = list(
        "playwright"  = "memory_young_star_origin_1_lm_centre",
        "page"        = "memory_young_star_origin_1_lm_wing",
        "stagehand"   = "memory_young_star_origin_1_lm_back",
    )
    script = list(
        list("at" = 0,   "actor" = "playwright", "do" = "say",   "text" = "Hold the curtain. Hold it."),
        list("at" = 0,   "actor" = "stagehand",  "do" = "move",  "landmark" = "memory_young_star_origin_1_lm_back"),
        list("at" = 25,  "actor" = "page",       "do" = "emote", "text" = "looks down at the floorboards."),
        list("at" = 60,  "actor" = "page",       "do" = "say",   "text" = "I am sorry, sir. I —"),
        list("at" = 90,  "actor" = "playwright", "do" = "move",  "landmark" = "memory_young_star_origin_1_lm_wing"),
        list("at" = 130, "actor" = "playwright", "do" = "say",   "text" = "You are not sorry yet. But you will be."),
        list("at" = 130, "actor" = "page",       "do" = "face",  "target_role" = "playwright"),
        list("at" = 180, "actor" = "stagehand",  "do" = "emote", "text" = "begins to fade backstage."),
    )
```

Multiple steps can share the same `at` value — they all fire on the
same tick. The first and second entries above both fire at t=0, and
the playwright's line at t=130 fires together with the page turning
to face them.

Supported `do` values:

| `do` | Required fields | Effect |
|---|---|---|
| `"say"` | `text` | NPC `say(text)` |
| `"emote"` | `text` | NPC `visible_message("\<name\> [text]")` |
| `"move"` | `landmark` | `walk_to(npc, landmark_turf, 0)` until arrival |
| `"face"` | `target_role` OR `dir` | NPC turns to face another role's NPC, or a static direction |

There is no `"wait"` step — gaps between event timestamps already act
as waits, and same-timestamp events fire simultaneously.

The script runner is a single proc on the lobby. Steps that share an
`at` value naturally fire on the same tick because `delay_ds <= 0`
skips the sleep:

```dm
/datum/star_memory_lobby/proc/RunScript()
    var/start_time = world.time
    for(var/list/step as anything in memory.script)
        var/target_time = start_time + step["at"]
        var/delay_ds = target_time - world.time
        if(delay_ds > 0)
            sleep(delay_ds)
        if(state == LOBBY_STATE_ABORTED)
            return
        ExecuteStep(step)
    addtimer(CALLBACK(src, PROC_REF(EndSession)), 3 SECONDS)
```

Authors should pre-sort steps by `at` ascending; the runner does not
re-sort and a step with an `at` value behind the previous step's
real time will fire immediately, which is rarely what you want.

`ExecuteStep` is a switch on `step["do"]` that calls the matching
proc on the resolved NPC (`npcs_by_role[step["actor"]]`). Bad step
data (unknown actor, unknown landmark) logs a `stack_trace` and is
skipped — it never crashes the cutscene.

---

## Landmark types

```dm
/obj/effect/landmark/star_memory
    name = "star memory landmark"

/obj/effect/landmark/star_memory/player_spawn   // the observer spawn tile
/obj/effect/landmark/star_memory/npc_spawn      // initial NPC tiles
/obj/effect/landmark/star_memory/walk_target    // intermediate "move" landmarks
```

Per-memory subtypes with hard-coded `id`s, exactly like the railway
landmark pattern (`run_datum.dm`'s `GetRefractionLandmarks` is the
lookup reference). Example:

```dm
/obj/effect/landmark/star_memory/player_spawn/young_star_origin_1
    id = "memory_young_star_origin_1_player"

/obj/effect/landmark/star_memory/walk_target/young_star_origin_1_centre
    id = "memory_young_star_origin_1_lm_centre"
```

The .dmm uses the typed paths directly; no per-tile id editing needed
(matches `lines/nova_flare/landmarks.dm` convention).

---

## Hidden room placement

The hidden room and its door live in `_maps/star_memories/hub.dmm` — a
small fixed map loaded at world init alongside the refraction
checkpoint room. The door (`/obj/machinery/door/star_memory_gate`) is
the only entrypoint. Inside: the console + atmospheric décor. The
room can be reached only via teleport from the refraction-railway
checkpoint area or by walking through the gated door — final
placement is the map-author's call.

---

## Verification

1. **Compile clean** — all new files included via `lobotomy-corp13.dme`
   under a fresh `// Star Memories` block.
2. **Gate check** — fresh ckey with no railway history walks up to
   the door: gets the "the door does not respond" message. Same ckey
   after one completed Nova Flare run: door opens.
3. **Single-player viewing** — solo lobby, pick a memory, start
   viewing. Confirm:
   - Lavender tint applied; original body in godmode, immobilized.
   - Observer mob spawned at the player landmark, mind transferred.
   - NPCs appear at their npc-spawn landmarks.
   - Script runs in order; `at` deltas match real-time delays.
   - 3 seconds after the last step, mind returns; tint, godmode,
     trait, observer mob all cleaned up.
4. **Lobby viewing** — two players in the same lobby. Both project
   to the same tile, both see the tint, both share the cutscene,
   both return at the same time.
5. **Concurrency** — player A starts memory M; player B (separate
   lobby) selects M and gets "this memory is already being
   witnessed." Player B selects memory N — joins the same shared Z
   in a different room and plays in parallel with lobby A.
6. **Disconnect mid-session** — player A's lobby member disconnects
   while the script is running. Their observer should `qdel` on the
   next `Life` tick; their body's godmode/trait cleared on the
   lobby's `Destroy()`. Other lobby members keep watching.
7. **Re-run a memory in same round** — viewing memory M for the
   second time reuses the same shared Z; NPCs re-spawn at their
   landmarks (subsystem clears the previous NPC pool first).
8. **Z is loaded once** — confirm only one `LoadStarMemoryZ()` call
   per round, even after multiple sessions across multiple memories.

---

## Open questions

- **Hub room placement** — confirm whether `_maps/star_memories/hub.dmm`
  is its own standalone tiny map loaded at world init, or whether the
  hidden room should be appended to the existing refraction checkpoint
  dmm.
- **Sanity on return** — Secrets of the Stars is lore-heavy.
  Should witnessing a memory take a small sanity hit on return (per
  Limbus Company's *Distortion is contagious* tone)? Default: no
  sanity effect — purely cosmetic.
- **NPC chat attribution** — `say()` will show the NPC's `name` field
  in chat. Placeholder NPCs are all named "static". Once real names
  are authored we'll likely want to display `role_id` instead.
  Recommendation: defer until a real memory is being authored.
- **Abort on hostile spawn?** — if some other event spawns a hostile
  mob on the memory Z (admins, mostly), should the cutscene auto-abort?
  Default: no — let the script run; observer mobs are invulnerable.

---

## Implementation order

1. **(this file)** — DESIGN.md committed for review. *(current step)*
2. Subsystem + datum scaffold (no script execution yet).
3. Landmarks + observer mob + NPC mob + client colour.
4. Console + TGUI sidebar (read-only).
5. Lobby state machine + Z-lane loader.
6. Mind projection + return flow.
7. Script DSL runner.
8. One example memory + dmm (smoke test).
9. Door + gate proc + completion helper.
10. Final hookup in `.dme`.

Steps 2–10 happen in follow-up sessions, gated on this design being
reviewed and accepted.
