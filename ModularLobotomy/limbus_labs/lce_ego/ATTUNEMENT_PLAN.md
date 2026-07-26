# LCE Attunement System — Design Plan

## Context

Limbus abnos hand out "LCE" EGO gear. Today that gear is inert: the armor
(`/obj/item/clothing/suit/armor/ego_gear/lce/*`) only sets stat blocks, and the
matching LCE weapons (`/obj/item/ego_weapon/lce/*`) are **orphaned** — they have no
`ego_datum`, so no abno can actually expel them; abnos instead expel base-game
weapons. We want to turn LCE gear into a real mechanic built around **Attunement**,
and — just as importantly — build it so **future contributors can add a new LCE set
by filling in a few config vars**, not by re-implementing the system each time.

Core pitch (per the request):
- Each LCE **armor** carries an `attunement` value from 0-100%.
- How high you can push it *safely* depends on how much you've **interacted with the
  source abnormality**.
- Higher attunement = combat **buffs** (mainly weapon damage; optionally more ammo /
  on-hit effects / actions gated at X%+).
- Pushing past your **safe limit** = **debuffs** (reduced max SP, self-damage when you
  attack), built as **generic, reusable** effects shared across all LCE gear.
- Each armor is **paired with an LCE weapon that spawns with it**. A worn action
  **points an arrow to the dropped weapon**, or **summons it into your hands** if it was
  destroyed.
- Attunement is adjusted with **three action buttons** (lower, raise, cycle step
  1%/5%/10%), each with a **custom icon**, plus the locate/summon button.

The request explicitly favors simplicity and future-dev ease over per-item uniqueness:
"attunement just causes higher damage at high %s, with a few simple debuffs" is an
acceptable MVP. This plan is structured so the MVP is small and the richer per-gear
features are optional override hooks.

## Grounded facts (from codebase exploration)

- **Base armor** `/obj/item/clothing/suit/armor/ego_gear`
  (`code/modules/clothing/suits/ego_gear/_ego_gear.dm`): has `equipped(user, slot)` /
  `dropped(user)` (must call `..()`), `actions_types` + `item_action_slot_check(slot)`
  (return TRUE for `ITEM_SLOT_OCLOTHING` = worn-only buttons), and `SpecialEgoCheck()` /
  `SpecialGearRequirements()` hooks. Canonical "react while worn" pattern: register
  signals on the wearer in `equipped()`, unregister in `dropped()`
  (`non_abnormality/insurgence.dm`, `ego_gear/realized.dm` fallencolors).
- **Base weapon** `/obj/item/ego_weapon` (`ModularLobotomy/ego_weapons/_ego_weapon.dm`):
  `attack(target, user)`, `force`, `damtype`, `CanUseEgo()`. Ranged variant
  `/obj/item/ego_weapon/ranged` has `shotsleft`, `projectile_path`, ammo/reload.
- **LCE gear today**: `ModularLobotomy/limbus_labs/lce_ego/lce_armor.dm` (8 suits),
  `lce_datum.dm` (armor datums only), `lce_weapons.dm` (3 weapons: grinder/smile/
  unrequited, **no datums, unreachable**). Armor and weapon share only a name; nothing
  links them.
- **Abno → gear** is only the "Expel Ego" action (`lcl_abno.dm`
  `/datum/action/cooldown/limbus_abno_action/ego_refinement`): spawns
  `pick(ego_list).item_path` on the abno's turf and **wipes `attribute_requirements` to
  `list()`**. No death-drop, no roundstart cell spawn. Each abno's `ego_list` currently
  holds one base-game weapon datum + one LCE armor datum.
- **Interaction tracking**: `/datum/abnormality` has per-player `work_stats["real_name
  (ckey)"]` — but **limbus abnos do NOT use it**. They only have `desire`/`hunger` and a
  mob-ref `friend_list`. So a per-player interaction tally for limbus abnos **does not
  exist and must be added** (small).
- **SP / max SP**: `maxSanity` is recomputed every `updatehealth()` from PRUDENCE, so
  never set it directly. Reduce max SP via
  `adjust_attribute_buff(PRUDENCE_ATTRIBUTE, -X)` then `updatehealth()` (pattern:
  `dyscrasone_withdrawl`, `debuffs.dm`). Direct SP damage: `adjustSanityLoss(amount)`.
- **Status effects**: `owner.apply_status_effect(/type)` / `remove_status_effect` /
  `has_status_effect`; lifecycle `on_apply()` / `tick()` / `on_remove()`; LC13 wraps in
  `apply_lc_*()` (e.g. `apply_lc_offense_level_up`). A status effect can self-register
  `COMSIG_MOB_ITEM_ATTACK` (pattern: `poise`, `buffs.dm`).
- **On-attack self damage**: `COMSIG_MOB_ITEM_ATTACK` fires on the user
  (`_onclick/item_attack.dm`), args `(target, user, item)`. Self damage:
  `user.deal_damage(amount, WHITE_DAMAGE, user, attack_type = ATTACK_TYPE_SPECIAL)`.
  **Ability use sends no signal** — no ready hook (design around this).
- **Locate arrow (player-private, rotating)**: `/atom/movable/screen/arrow` +
  `Get_Angle(target_turf, our_turf)` + a rotation `matrix()` animated onto the wearer's
  `hud_used.team_finder_arrows` (`code/datums/components/team_monitor.dm`,
  `update_atom_dir`). `rose_sign.dm` is a *world-visible spark trail*, not a private
  arrow — use the `team_monitor` arrow.
- **Summon to hand**: `user.put_in_hands(obj/item)` (`code/modules/mob/inventory.dm`).
- **Track weapon destruction**: `RegisterSignal(weapon, COMSIG_PARENT_QDELETING,
  PROC_REF(OnWeaponDestroyed))`, null the ref in the handler (pattern:
  `ego_gear/realized.dm` crimson candidate list).
- **Worn action buttons**: `actions_types = list(/datum/action/item_action/...)`;
  `item_action_slot_check(slot)` → `slot == ITEM_SLOT_OCLOTHING`; `ui_action_click(user,
  action)` dispatches by `action.type`; custom icon via `icon_icon` +
  `button_icon_state` on the action datum. A worn suit can find itself from an ability
  via `user.get_item_by_slot(ITEM_SLOT_OCLOTHING)`.

## Architecture — who owns what

The whole system lives on **two base types plus one shared debuff file**, so a concrete
LCE set is just config.

- **`/obj/item/clothing/suit/armor/ego_gear/lce` (base armor)** owns:
  attunement state (`attunement`, `attunement_step`, computed `safe_limit`), the **four
  worn action buttons** (locate/summon + up/down/step), spawning + tracking the paired
  weapon, and applying/removing the **over-limit debuffs**. One central
  `RefreshAttunement(wearer)` recomputes everything.
- **`/obj/item/ego_weapon/lce` (base weapon)** reads the worn paired armor's attunement
  on attack to **scale damage (the buff)** and to **self-damage the wearer when
  over-limit (attack feedback debuff)**. Per-weapon extras (ammo, on-hit, gated actions)
  are override hooks.
- **Shared `attunement_family` key** (a string) set on both the armor and its weapon
  links a set; the same key is set on the **source abno** so interaction credits the
  right family. This is the single glue value.
- **Generic debuff status effects** (new file) — reusable by any LCE gear.
- **Global affinity store** — per `(ckey, family)` interaction tally the abno increments
  and the armor reads on equip to set `safe_limit`.

### Config surface for a new LCE set (the "ease of future dev" goal)

To add a set, a contributor writes only:
```dm
/obj/item/clothing/suit/armor/ego_gear/lce/newthing
    name = "..."; desc = "..."; icon_state = "..."; armor = list(...)
    attunement_family = "newthing"
    paired_weapon = /obj/item/ego_weapon/lce/newthing
    // optional: safe_limit_floor, max_damage_bonus, or override ApplyExtraBuffs()

/obj/item/ego_weapon/lce/newthing
    name = "..."; force = ...; damtype = ...; icon_state = "..."
    attunement_family = "newthing"
    // optional: override on-hit / ammo hooks

/datum/ego_datum/armor/lce/newthing { item_path = ...armor... }
// (weapon needs no datum — it spawns with the armor)

// source abno: attunement_family = "newthing"; ego_list = list(/datum/ego_datum/armor/lce/newthing)
```
Everything else — buttons, arrows, summon, buffs, debuffs — is inherited.

## Subsystem details

### 1. Attunement state & adjustment (base armor)
```dm
var/attunement = 0            // 0..100, current setting
var/attunement_step = 5       // 1 / 5 / 10, cycled by the step button
var/safe_limit = 0            // computed on equip from wearer affinity
var/attunement_family = ""    // links armor <-> weapon <-> abno
```
- **Three buttons** (worn-only `/datum/action/item_action`), dispatched in
  `ui_action_click(user, action)` by `action.type`:
  - `attunement_lower`: `attunement = max(0, attunement - attunement_step)`
  - `attunement_raise`: `attunement = min(100, attunement + attunement_step)` (allowed to
    exceed `safe_limit` — that is how you opt into debuffs)
  - `attunement_step_cycle`: `1 -> 5 -> 10 -> 1`; updates its own button icon to show the
    active step (`UpdateButtonIcon()` after changing `button_icon_state`).
  - Each change calls `RefreshAttunement(wearer)` and a brief `to_chat`/balloon showing
    `attunement% (safe up to safe_limit%)`.
- **Custom icons** for all three buttons + the locate button: new sheet
  `ModularLobotomy/_Lobotomyicons/lce_actions.dmi` (generated with the DMI pipeline),
  states e.g. `attune_up`, `attune_down`, `step_1`/`step_5`/`step_10`, `locate_weapon`.

### 2. Safe limit from interaction (new lightweight affinity)
Because expelled gear doesn't know its future wearer, `safe_limit` is computed **on
equip**, from a global tally keyed by wearer + family:
```dm
GLOBAL_LIST_EMPTY(lce_attunement_affinity)   // "[ckey]-[family]" -> interaction points

/proc/get_lce_affinity(mob/user, family)
    return GLOB.lce_attunement_affinity["[user.ckey]-[family]"] || 0
```
- **Limbus abno gains a `var/attunement_family`** and a `GainAffinity(mob/user, amt)`
  proc that increments the global tally (capped). Credit it from the existing interaction
  hooks that already hand us the player: `RepressionWork(dmg, type, user)`,
  `funpet(petter)`, `Hear()` (speaker), `OnCtrlShiftClick` (befriending), and optionally a
  slow proximity tick in `Life()`. Small, additive, no behavior change.
- On equip: `safe_limit = clamp(safe_limit_floor + round(get_lce_affinity(wearer,
  attunement_family) / POINTS_PER_PERCENT), safe_limit_floor, 100)`. A wearer who never
  touched the abno gets only `safe_limit_floor` (e.g. 20-30%); a regular handler can
  safely reach 100%.

### 3. Buffs (base weapon reads the worn armor)
Keep the MVP to **weapon damage scaling**:
```dm
// /obj/item/ego_weapon/lce
var/attunement_family = ""
var/max_damage_bonus = 0.5      // +50% force at 100% attunement
var/no_armor_penalty = 0.5      // -50% damage when the matching armor isn't worn

/obj/item/ego_weapon/lce/attack(mob/living/target, mob/living/user)
    var/obj/item/clothing/suit/armor/ego_gear/lce/armor = GetMatchingArmor(user)
    var/saved = force
    if(!armor)
        force = round(force * (1 - no_armor_penalty))   // no armor: half damage, no attunement
    else
        force = round(force * (1 + max_damage_bonus * armor.attunement / 100))
    . = ..()
    force = saved
    if(armor)
        HandleOverLimit(user, armor)   // over-limit debuff hook, see 4
```
`GetMatchingArmor(user)` = the worn suit via `get_item_by_slot(ITEM_SLOT_OCLOTHING)` if it
is an `ego_gear/lce` with the **same `attunement_family`**, else null.
- **Used without the matching armor:** no attunement scaling at all, and a flat
  `no_armor_penalty` (default 50%) damage cut. So the weapon is only strong as part of its
  set. (Attunement over-limit debuffs also don't apply — you can't overshoot a limit you
  aren't benefiting from.)
- **Richer buffs are override hooks**, off by default: `ApplyExtraBuffs(user, frac)` on
  the armor's `RefreshAttunement` for e.g. `apply_lc_offense_level_up`, extra ammo on a
  ranged LCE weapon (`shotsleft` bump), gated actions unlocked at `attunement >=
  threshold`. MVP ships none of these; they are documented extension points.

### 4. Debuffs beyond the safe limit (generic + reusable)
Two shared pieces, applied only while `attunement > safe_limit`, scaled by the overshoot
`over = attunement - safe_limit`:
- **Reduced max SP** — a generic status effect the armor applies/removes in
  `RefreshAttunement`:
  ```dm
  /datum/status_effect/attunement_overload   // duration = -1, alert_type = null
      var/applied = 0
  on_apply():  applied = round(over * SP_PER_OVER); owner.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, -applied); owner.updatehealth()
  on_remove(): owner.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, applied); owner.updatehealth()
  ```
  Re-applied (remove + re-add) whenever `over` changes so the reduction tracks the
  overshoot. Symmetric restore is essential.
- **Attack feedback** — when over-limit, the base LCE weapon's `HandleOverLimit(user,
  armor)` does `user.deal_damage(round(over * DMG_PER_OVER), BLACK_DAMAGE, user,
  attack_type = ATTACK_TYPE_SPECIAL)`. (Implemented on the weapon because weapons already
  have the attack hook and read the armor; equivalently packageable as a shared
  `poise`-style status effect if we want ability parity later.)
  - **Rate limit (1.5s) so attack speed doesn't matter:** without a gate, a fast weapon
    (e.g. the grinder chainsword's 4-hit flurry) would burn you far more per second than a
    slow one for the same overshoot. Gate the burn on a cooldown stored on the **armor**
    (one shared timer per wearer, so swapping between a fast and slow LCE weapon can't
    bypass it): `var/next_overlimit_burn = 0`, and in `HandleOverLimit`:
    ```dm
    if(world.time < armor.next_overlimit_burn)
        return
    armor.next_overlimit_burn = world.time + OVERLIMIT_BURN_COOLDOWN   // 1.5 SECONDS
    user.deal_damage(round(over * DMG_PER_OVER), BLACK_DAMAGE, user, attack_type = ATTACK_TYPE_SPECIAL)
    ```
    Net effect: overshoot damage ticks at most once per ~1.5s regardless of swing speed, so
    fast and slow LCE weapons take the same self-damage over time.
    (`OVERLIMIT_BURN_COOLDOWN` is a shared define so every LCE set stays consistent.)
- **Ability-use feedback (gap):** abilities emit no signal. For MVP, skip it. When a set
  adds an attunement-gated action, that action's own `Trigger()` should call a shared
  `armor.PayOverLimitCost(user)` helper so ability use also bites when over-limit. Note
  this in the extension guide.
- Both effects are removed on unequip and when `attunement <= safe_limit`.

### 5. Paired weapon: spawn, track, locate, summon (base armor)
```dm
var/paired_weapon = null                 // typepath
var/obj/item/ego_weapon/lce/tracked_weapon
```
- **Spawn with the armor**: in the armor's `Initialize()`, spawn `paired_weapon` at
  `get_turf(src)` (or `loc`), store `tracked_weapon`, and
  `RegisterSignal(tracked_weapon, COMSIG_PARENT_QDELETING, PROC_REF(OnWeaponDestroyed))`
  (handler nulls the ref). This satisfies "spawned in with the armor" for every path that
  creates the armor (Expel, vendor, admin). *Decision to confirm:* spawn at Initialize
  vs. on first equip (Initialize is simplest; on-equip avoids a loose weapon if the armor
  sits in a crate).
- **Expel change**: since the armor now brings its weapon, each abno's `ego_list` should
  hold **only the LCE armor datum** (drop the separate base-game weapon datum). This
  fixes the orphaned-LCE-weapon problem and makes expel deterministic (armor + its
  weapon). Also decide whether Expel should keep wiping `attribute_requirements` (it can;
  attunement is independent state and does not rely on the requirements list).
- **Locate / summon button** (worn-only): in `ui_action_click`:
  - `tracked_weapon` exists & same z → show the **private rotating arrow** toward
    `get_turf(tracked_weapon)` (team_monitor pattern: `new /atom/movable/screen/arrow`,
    add to `wearer.hud_used.team_finder_arrows`, `Get_Angle` into a `matrix().Turn(...)`,
    `animate`, `QDEL_IN` a few seconds; remove from the list on qdel).
  - `tracked_weapon` null (destroyed) → **summon**: spawn a fresh `paired_weapon`, place
    with `put_in_hands`, re-track + re-register the qdel signal. Put on a cooldown so it
    isn't a free infinite-respawn.
- **Lifecycle rules (important):**
  - **Unequip (`dropped()`):** keep the weapon in the world — you must still be able to
    locate it. Just tear down wearer-attack hooks / attunement effects.
  - **Armor destroyed (`Destroy()`):** the weapon **disappears with the armor** — `qdel`
    the `tracked_weapon` (after unregistering its qdel signal so the handler doesn't
    re-fire). The set is gone as a unit.
  - Contrast the two destroy directions: *weapon* destroyed while armor lives → the locate
    button flips to **summon** (respawn a fresh weapon). *Armor* destroyed → weapon is
    culled too and nothing remains to summon.

### 6. RefreshAttunement — the one place that reconciles state
Called on `equipped()`, on any button press, and on `dropped()` (with wearer = null to
clear). Steps: recompute `safe_limit` (on equip), compute `over`, apply/remove
`attunement_overload` to match `over`, run `ApplyExtraBuffs` hook, update the step
button icon, and refresh examine text. Idempotent (always remove-then-reapply so repeated
calls converge).

### 7. Gear registry (needed by weapon buffs AND the abno's Communion action)
Maintain a global registry of live LCE armor instances by family, so both the weapon and
the abno can find gear without scanning `GLOB.human_list`:
```dm
GLOBAL_LIST_EMPTY(lce_armors)          // family -> list of /obj/item/clothing/suit/armor/ego_gear/lce

/lce/Initialize(): GLOB.lce_armors[attunement_family] |= src
/lce/Destroy():    GLOB.lce_armors[attunement_family] -= src ; ...
```
"Who is wearing it" is derived on demand: an armor is *worn* when `isliving(loc)` and that
mob has it in `ITEM_SLOT_OCLOTHING`. (Registry-on-Initialize covers worn AND unworn
instances, which the Communion "view through the gear itself when not worn" case needs.
The alternate, no-registry approach — iterate `GLOB.human_list` + `get_item_by_slot` — is
the established codebase idiom but only finds *worn* gear.)

## 8. EGO Communion — the abno's remote-perspective / mind-influence action

A new LCL abno action (granted alongside the existing abno actions) that lets an abno reach
into anyone carrying its EGO. The abno's `attunement_family` selects which gear it commands.

### 8a. Commune: list wearers + swap perspective
- **Action "Commune with EGO"** (`/datum/action/cooldown/limbus_abno_action/ego_communion`):
  builds the target list from `GLOB.lce_armors[abno.attunement_family]` and presents it
  (simple `input(...) as anything in list` or a radial with wearer names / "unworn @
  area"). Each entry resolves to a **view target**:
  - armor **worn** by a human → view target = that human (and enable hearing relay + the
    influence sub-actions).
  - armor **not worn** (on the floor / in a bag) → view target = the armor object itself
    ("see through the gear itself"), hearing relay anchored on the gear, no mind-influence.
- **Perspective swap** (copy wizard clairvoyance `artefact.dm:355`): `abno.reset_perspective(view_target)`.
  Because the abno is `/mob/living`, the `living.dm` override auto-handles `update_sight()`
  and the `"remote_view"` fullscreen. Restore with `abno.reset_perspective(null)`
  (`camera_advanced.dm` teardown). Optionally set `abno.remote_control = view_target`.
- **Auto-teardown**: register `COMSIG_MOVABLE_MOVED` (target left range) + `COMSIG_LIVING_DEATH`
  / `COMSIG_PARENT_QDELETING` on the view target, and on the armor's `dropped()` (wearer took
  it off), each ending communion — mirroring `der_freischutz.dm:187`. Also end on abno death
  / possession loss.

### 8b. Hear what the target hears — as floating runechat, not to_chat
- On entering communion: `RegisterSignal(view_target, COMSIG_MOVABLE_HEAR, PROC_REF(RelayHeard))`.
- Handler (imaginary_friend.dm:153-156 pattern):
  ```dm
  /proc RelayHeard(datum/source, list/hearing_args)
      SIGNAL_HANDLER
      if(!client?.prefs?.chat_on_map) return
      create_chat_message(hearing_args[HEARING_SPEAKER], hearing_args[HEARING_LANGUAGE],
                          hearing_args[HEARING_RAW_MESSAGE], hearing_args[HEARING_SPANS])
  ```
  This renders exactly what the wearer hears as speech bubbles above the speakers' heads,
  visible only to the abno's client — the **spatial** layer. Requires the abno's
  `client.prefs.chat_on_map` = TRUE (all runechat call sites gate on it; force/warn if off).
  (§8f adds a parallel **text** layer: the same speech, plus emotes, as `to_chat` lines.)
- **Radio caveat**: radio speakers can be off-screen from the target, so their bubble may
  render somewhere the abno can't see. Decision: either accept it (only local speech shows
  as bubbles) or anchor radio bubbles on the target instead of the speaker. MVP: accept it —
  §8f's to_chat feed catches radio anyway.
- Unregister `COMSIG_MOVABLE_HEAR` on communion end.

### 8c. Telepathy (always available while communing with a *person*)
- Sub-action "Whisper" prompts text and delivers it privately to the wearer:
  `to_chat(wearer, span_hypnophrase("<i>[msg]</i>"))` (hypnosis.dm:51 style), plus
  `log_directed_talk(abno, wearer, msg, LOG_SAY, "EGO communion")`.

### 8d. Compulsion — force say/emote at 50%+ attunement, attunement-scaled cooldown
- Sub-action "Compel" is available only when the **selected wearer's armor
  `attunement >= 50`**. It lets the abno force the wearer to either speak or emote:
  - Force speech: `wearer.say(text, forced = "EGO compulsion")` (topic.dm:930 idiom —
    `forced` bypasses the IC filter and produces normal runechat speech others hear).
  - Force emote: `wearer.emote(key)` or `wearer.manual_emote(text)` (involuntary by default;
    blue_shepherd.dm:240 precedent).
- **Dynamic cooldown** (steam_transport_machine.dm:136 pattern): compute at trigger from the
  wearer's attunement, 40s at 50% down to 10s at 100% —
  `cooldown_time = 40 SECONDS - (clamp(attunement,50,100) - 50) * 0.6 SECONDS`, then
  `StartCooldown()`. Below 50% the sub-action is unavailable.

### 8f. Text feed of the target's surroundings — words AND emotes as to_chat
On top of the spatial runechat (§8b), while communing the abno also gets a plain `to_chat`
log of everything happening **around the wearer it is communing with**, so it catches what
the bubbles miss (radio, off-screen speech) and — importantly — **emotes**, which runechat
does not relay.

*Scope (confirmed):* "around them" = **around the communion target (the wearer)**. (The abno
already hears its *own* body's surroundings normally even while communing, so no work is
needed for that side.)

**Use BOTH hooks** (decided) — the no-core speech relay AND the core show_message relay —
so the abno sees everything the wearer perceives. Both are registered in `BeginCommunion`
and dropped in `EndCommunion`:
- **Speech (no core change):** reuse the `COMSIG_MOVABLE_HEAR` registration from §8b — in the
  same `RelayHeard` handler, additionally
  `to_chat(src, "[COMMUNE_TAG] [compose_message(speaker, language, raw_message, radio_freq, spans, message_mods)]")`
  (`compose_message` is in `code/game/say.dm`; this is the second half of the
  imaginary_friend.dm:153-156 pattern). Covers all speech the wearer hears, radio included.
- **Emotes / visible+audible messages (one small core hook):** emotes reach nearby mobs via
  `visible_message`/`audible_message` → `/mob/show_message` (`mob.dm:139`), and **nothing on
  that path sends a signal** (`COMSIG_MOB_EMOTE` fires on the *emoter*, not on observers, so
  it can't see other people's emotes near the wearer). So add one line to `/mob/show_message`
  — `SEND_SIGNAL(src, COMSIG_MOB_SHOW_MESSAGE, msg, type)` (new define) — then
  `RegisterSignal(view_target, COMSIG_MOB_SHOW_MESSAGE, PROC_REF(RelayShown))` and
  `to_chat(src, "[COMMUNE_TAG] [msg]")` in the handler. This relays every emote/visible/
  audible line the wearer perceives, from *everyone* around them.
- **Tag (required):** every relayed line is prefixed with a `[COMMUNE]:` tag so the abno can
  instantly tell its remote feed from its own local chatter. Define a shared macro, e.g.
  `#define COMMUNE_TAG "<span class='abductor'>\[COMMUNE\]:</span>"` (any distinct span), and
  prepend it in both `RelayHeard` and `RelayShown`. So a line reads like
  `[COMMUNE]: Alice says, "on my way"` / `[COMMUNE]: Bob waves.`

### 8e. Sub-action lifecycle
Whisper / Compel / End-Communion are granted when communion begins and removed when it ends,
so they only clutter the HUD while active. End-Communion (and all auto-teardown paths) call
one `EndCommunion()` that: `reset_perspective(null)`, `remote_control = null`, unregisters
`COMSIG_MOVABLE_HEAR` + `COMSIG_MOB_SHOW_MESSAGE` + the movement/death watchers, and removes
the sub-actions.

## Files to create / modify

**Create**
- `ModularLobotomy/limbus_labs/lce_ego/lce_attunement.dm` — base-armor attunement logic,
  the 4 `/datum/action/item_action/*` button types, `RefreshAttunement`, weapon
  spawn/track, locate/summon, affinity helpers/globals.
- `ModularLobotomy/limbus_labs/lce_ego/lce_attunement_effects.dm` — generic
  `/datum/status_effect/attunement_overload` (and any future shared LCE debuffs).
- `ModularLobotomy/_Lobotomyicons/lce_actions.dmi` — custom action-button icons. **Already
  generated**, with states `attune_up`, `attune_down`, `step_1/5/10`, `locate_weapon`,
  `commune`, `whisper`, `compel`, `end_communion`. (`.dme` needs the new `.dm` includes;
  `.dmi` loads as a resource with no include.)

**Modify**
- `lce_ego/lce_armor.dm` — add `attunement_family`, `paired_weapon`, `actions_types`,
  `item_action_slot_check`, `equipped/dropped/Initialize/Destroy` overrides on the base
  `/lce`; per-suit config on the 8 subtypes.
- `lce_ego/lce_weapons.dm` — add `attunement_family`, `max_damage_bonus`, the damage-scale
  + over-limit `attack()` on the base `/lce`; **create the 5 missing LCE weapons** so all
  8 armors can pair (art already exists in `icons/obj/lce_egoweapons.dmi`).
- `lce_ego/lce_datum.dm` — keep armor datums; ensure each armor's `paired_weapon` points
  at a real LCE weapon.
- `limbus_labs/limbus_abnos/lcl_abno.dm` — add `attunement_family` + `GainAffinity()` to
  the base abno; credit affinity in `RepressionWork` / `funpet` / `Hear` /
  `OnCtrlShiftClick` (and optional `Life` proximity). Set `attunement_family` on each abno
  subtype (mountain, queen_bee, pbird, laetitia, helper, scorched, pisc_mermaid...); trim
  their `ego_list` to just the LCE armor datum. Grant the **Communion action** in
  `Initialize()` (alongside the existing abno actions).
- `ModularLobotomy/limbus_labs/lce_ego/lce_communion.dm` (new) — the
  `/datum/action/cooldown/limbus_abno_action/ego_communion` action, the Whisper / Compel /
  End-Communion sub-actions, `GLOB.lce_armors` registry, and the abno-side communion procs
  (`BeginCommunion` / `RelayHeard` / `RelayShown` / `EndCommunion`). Keeping it separate from
  the gear file keeps the abno-facing code together.
- `code/modules/mob/mob.dm` — **one line** in `/mob/show_message` (the emote/visible/audible
  delivery proc): `SEND_SIGNAL(src, COMSIG_MOB_SHOW_MESSAGE, msg, type)`, so §8f can relay
  emotes near the wearer. (The only core-file touch in the whole feature.)
- `code/__DEFINES/dcs/signals.dm` — define `COMSIG_MOB_SHOW_MESSAGE` (mob-level signal).
- `.dme` — include the new `lce_attunement.dm`, `lce_attunement_effects.dm`, and
  `lce_communion.dm`.

## Phasing (keep the MVP small)

- **Phase 1 (MVP):** attunement var + 3 buttons (custom icons) + safe-limit from affinity
  (or the attribute fallback) + weapon damage scaling (incl. the no-armor 50% penalty) +
  the two generic over-limit debuffs + paired-weapon spawn + locate/summon + armor-destroy
  culls the weapon. All 8 sets wired with damage-only buffs.
- **Phase 2 — EGO Communion:** the abno action — list wearers, perspective swap (through
  wearer or gear), hearing-as-runechat relay, telepathy, and 50%+ compulsion on an
  attunement-scaled cooldown.
- **Phase 3 (per-set flavor, optional):** override `ApplyExtraBuffs` per set for ammo /
  on-hit / attunement-gated actions; ability-use over-limit cost; tune curves per abno.

(Communion is Phase 2 because it depends on Phase 1's `attunement_family`, the gear
registry, and the armor's `attunement` value already existing.)

## Open decisions to confirm before coding

1. **Safe limit source:** interaction affinity (recommended, small new abno code) vs.
   wearer-attributes fallback (zero new abno code, weaker theme). 
2. **Weapon spawn timing:** at armor `Initialize()` (simplest) vs. on first equip (no
   loose weapon if the armor is stored).
3. **Expel behavior:** switch `ego_list` to armor-only (weapon comes via pairing) — assumed
   yes. Keep wiping `attribute_requirements` — assumed yes (attunement is independent).
4. **Summon cost/cooldown:** cooldown length, and whether summoning a destroyed weapon
   costs anything (SP? attunement?).
5. **Curve numbers:** `max_damage_bonus`, `no_armor_penalty` (default 0.5),
   `safe_limit_floor`, `POINTS_PER_PERCENT`, `SP_PER_OVER`, `DMG_PER_OVER`, step values —
   pick starting values.
6. **Communion — anti-psychic:** should compulsion (and telepathy) respect
   tinfoil/anti-magic (`anti_magic_check`)? MVP recommends yes for compulsion.
7. **Communion — radio hearing:** accept that off-screen radio speech won't render as a
   bubble (MVP), or anchor radio bubbles on the target?
8. **Communion — target menu UI:** plain `input(...) as anything in list` vs. a radial with
   wearer names/portraits, and whether a wearer can refuse / is notified they're being
   viewed or compelled.
9. **Communion — range/leash:** how far the abno can commune (any z? same z? unlimited?),
   and what ends it automatically (target moves too far, unequips, dies, abno breaches).
10. **Communion — surroundings feed (§8f):** RESOLVED — scope is around the *wearer*; use
    **both** relays (no-core speech + one-line `show_message` core hook), and prefix every
    relayed line with a `[COMMUNE]:` tag.

## Verification (once built)

- Compile clean (`dm.exe`), tgui untouched.
- Equip an LCE suit: 4 buttons appear (3 attune + locate); unequip removes them.
- Raise attunement below/at/above safe limit: damage scales up; past the limit, max SP
  drops (check the SP bar) and attacking chips your health; stepping back restores both
  exactly (no SP drift after several cycles — verify symmetric restore).
- Step button cycles 1/5/10 and its icon changes.
- Drop the paired weapon across the room → locate shows a private arrow pointing at it;
  destroy the weapon → the button summons a fresh one into hand (on cooldown).
- Destroy the **armor** → the paired weapon vanishes too (no orphaned weapon left).
- Swing the weapon **without** the matching armor → ~50% damage and no attunement scaling.
- Interact with the source abno a lot on one ckey → that ckey's safe limit is higher than
  an unfamiliar ckey's for the same gear.
- **Communion:** as the abno, open the action → the wearer list matches who actually wears
  the gear; pick a worn one → your view snaps to them and restores cleanly on
  End/move-away/death; pick an unworn one → you view through the item.
- **Hearing relay:** have someone speak near the communed wearer → the line floats above the
  speaker's head for the abno (runechat) **and** appears as a `[COMMUNE]:`-tagged `to_chat`
  line.
- **Surroundings feed:** have a bystander *emote* near the communed wearer, and someone talk
  over *radio* → both reach the abno as `[COMMUNE]:`-tagged `to_chat` lines (runechat alone
  would miss them). Confirm the tag distinguishes them from the abno's own local chatter.
- **Telepathy:** Whisper delivers a private hypnophrase line to the wearer only.
- **Compulsion:** below 50% attunement the Compel sub-action is unavailable; at ≥50% it
  forces a say/emote and the cooldown shrinks from ~40s toward ~10s as attunement climbs to
  100%; anti-psychic gear (if the caveat is honored) blocks it.
