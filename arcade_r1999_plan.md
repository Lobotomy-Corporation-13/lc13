# Plan — Reverse: 1999-Style Arcade Card Game

A living design + implementation document. Section ordering:

1. **Context** — what we're building and why.
2. **Architectural Pattern** — how to fit into LC13's existing arcade machine
   conventions.
3. **Core Mechanics** — stats, cards, ultimate (with the max-Moxie auto-inject
   rule), Moxie, statuses, damage resolution, effect vocabulary, passives.
   Applies to every character.
4. **Characters** — Regulus, Door, Зима spec'd; Aleph deferred (too
   complex for v1); one slot still TBD.
5. **Enemies** — placeholder section for the future enemy roster.
6. **Run Progression** — character selection → 3 enemy waves (boss on
   wave 3) → score submission.
7. **File Layout** — what code lands where.
8. **Open Questions** — design choices not yet pinned.
9. **Verification** — how we'll know it works.

The user has explicitly asked us to lock down **how a single character
functions** before going further. Sections 1–4 (Regulus only) are the
binding part of this plan; sections 5+ are scaffolding that subsequent
turns will fill in.

---

## 1. Context

The user wants to add a new arcade machine to Lobotomy Corp 13 inspired by
*Reverse: 1999*: party of **4 characters**, a **shared hand and shared 4-action
budget** per round (R1999-style), and a "merge two adjacent same-name
same-tier cards into a stronger version" core mechanic. Afflatus / elemental
triangle is deferred.

Cards mostly come from the shared deck, but **when a character's Moxie reaches
its max, that character's Ultimate is auto-injected into the leftmost slot
of the shared hand as a special, un-mergeable card.** Players can choose to
play it (consuming it and the Moxie) or ignore it. If Moxie drops below max
before it's played, the card is removed.

---

## 2. Architectural Pattern (mirror existing arcades)

LC13's existing arcade machines (`code/game/machinery/computer/arcade.dm`
plus `arcade_cardgame.dm`, `arcade_dungeon.dm`, `arcade_pmttrpg.dm`) all
follow the same shape:

- **DM side is a thin shell.** `/obj/machinery/computer/arcade/<name>`
  overrides only `ui_interact`, `ui_static_data`, `ui_data`, `ui_act`. It
  owns the leaderboard, prize vending (`prizevend()`), and throttled SFX
  playback. No game logic.
- **All gameplay runs in TGUI/Inferno on a `<canvas>`.**
  `tgui/packages/tgui/interfaces/Arcade<Name>.js` is the entire game engine —
  state machine of `GS_*` constants, hotkey wiring via `acquireHotKey` /
  `releaseHotKey`, character/enemy definitions as JS object literals,
  per-frame canvas rendering. See `ArcadeDungeon.js:53` for the canonical
  `CHARACTERS = { thumb: {...}, index: {...} }` pattern we'll follow.
- **Communication is minimal.** DM → JS via `ui_static_data` (one-time seed
  payload). JS → DM via `ui_act("submit_score", ...)`, `ui_act("died", ...)`,
  `ui_act("sfx", { s: "hit" })`. Idiom quoted from `arcade_cardgame.dm:98`.

The character module therefore lives **entirely in JavaScript** as a data
literal plus a small runtime evaluator. The DM side does not need to know
about stats, cards, or Moxie.

---

## 3. Core Mechanics

### 3.1 Stats

Two groups, both scaling with `(insight, level)`:

**Base stats** — `attack`, `health`, `realityDef`, `mentalDef`, `technique`
(turn order / speed; assumed by analogy to R1999).

**Special stats** — `critRate` (%), `critDmg` (%).

**Insight** is an enum `I | II | III` (permanent meta-progression — picked
at the start of a run for the arcade context). Each tier has its own max
level.

The character literal stores stats as a **flat array of breakpoint
values**, one per progression milestone — matching the column order of
the in-game stat table.

```js
stats: {
  // [defaultBaseLvl, defaultMaxLvl,
  //  insightI_MaxLvl, insightII_MaxLvl, insightIII_MaxLvl]
  //
  // Length-5 arrays = 6-star characters with full Insight III progression.
  // Length-4 arrays = lower rarities that cap at Insight II (e.g. Door).
  // For special stats that don't grow within the Default tier (crit),
  // the first two entries are equal.
  attack:     [266, 404, 677, 1009, 1186],
  health:     [1257, 1907, 3197, 4768, 5609],
  realityDef: [101, 153, 257, 382, 449],
  mentalDef:  [136, 206, 345, 514, 605],
  technique:  [368, 368, 417, 466, 515],
  critRate:   [12.2, 12.2, 13.9, 15.5, 17.1],
  critDmg:    [18.4, 18.4, 20.8, 23.3, 25.7],
}
```

Runtime resolution: `statAt(stat, insight, levelInTier)` interpolates
linearly between adjacent breakpoints (`breakpoints[i]` → `breakpoints[i+1]`)
based on the current level inside the active tier. Linear interpolation is
an explicit assumption — the source table only gives at-tier-max values.

Per §6.2, the arcade always launches characters at their highest available
Insight tier, max level. So in Phase 1 the resolver only needs to return
the last entry in the array; sub-tier interpolation is reserved for a
later difficulty-tunable Insight slider if we want one.

### 3.2 Incantations (Skill Cards)

A character has a fixed kit of skill cards (typically 2). Skill cards have
**3 power tiers** (`★☆☆`, `★★☆`, `★★★`) reached by merging two adjacent
same-`id` same-tier cards in hand. Each tier carries its own effect block;
higher tiers usually scale the multiplier *and* unlock new clauses.

```js
{
  id: 'treat_for_ears',
  name: 'Treat for the Ears',
  kind: 'skill',           // 'skill' | 'ultimate'
  school: 'arcane',
  tiers: [
    { mult: 200, dmgType: 'mental', target: 'single', clauses: [] },
    { mult: 300, dmgType: 'mental', target: 'single', clauses: [] },
    { mult: 500, dmgType: 'mental', target: 'single', clauses: [] },
  ],
}
```

**Targeting** values: `'self'`, `'single'`, `{ mass: N }`, `'allEnemies'`,
`'allAllies'`, `'primaryEnemy'`, `'primaryAlly'` (the player-designated
focus of an AoE-with-rider — see §3.7).

**Damage type** values: `'mental'` (vs `mentalDef`), `'reality'` (vs
`realityDef`), or `null` for non-damaging cards.

**Category** values per tier: `'attack'`, `'buff'`, `'debuff'`, `'heal'`,
`'counter'`. Mirrors R1999's "Attack/Buff/Debuff Attribute" tag on each
card tier and drives control statuses like `silence` (which blocks
non-attack categories) and `seal` (which blocks ultimates). The category
**can change between tiers of the same card** when adding a tier-3 rider
reclassifies it — e.g. Зима's `Sparrow` is `'attack'` at ★☆☆ but
`'debuff'` at ★★☆/★★★ once the Silence rider is attached.

**Clause `on`** triggers: `'cast'`, `'hit'`, `'crit'`, `'endRound'`, plus
the conditional gating used by Restless Heart (see Statuses).

**Damage scaling.** The `mult` field is a **percentage of the caster's
`attack` stat** — it is *not* a fixed damage number. Pre-defense damage =
`attack × (mult / 100) × critFactor`. So a card with `mult: 200` cast by a
caster with `attack = 400` deals 800 raw damage before the defender's DEF
and any status hooks reduce it. Defense reduction follows §3.6. Bigger ATK
= bigger numbers from every card; this is the only way skills meaningfully
scale with character level/insight.

### 3.3 Ultimate (with max-Moxie auto-inject)

The Ultimate is **not a normal deck card.** It's a per-character ability that
becomes playable through this lifecycle:

1. The character's Moxie counter rises during the round (see 3.4).
2. The instant `moxie === maxMoxie`, the engine **inserts that character's
   Ultimate card at index 0 of the shared hand** (i.e. the leftmost slot,
   pushing other cards right). Hand size grows by one while it sits there.
3. The card is visually distinct (gold frame, character portrait inset) and
   **cannot be merged or moved**. It is fixed in slot 0.
4. The player can spend an action to cast it like any other card. On cast:
   the Ultimate effects resolve, the carrier's Moxie resets to 0, and the
   card is removed from hand.
5. If the carrier's Moxie drops below max before the player casts it
   (e.g. an enemy debuff drains Moxie), the Ultimate card is removed from
   hand.
6. **If multiple party members hit max Moxie simultaneously**, their
   Ultimates stack at the leftmost slots in **party order** (slot 0 = party
   index 1, slot 1 = party index 2, …).

```js
ultimate: {
  id: 'sleepless_rave',
  name: 'Sleepless Rave',
  effects: [
    { kind: 'damage', mult: 300, dmgType: 'mental', target: 'allEnemies' },
    { kind: 'applyStatus', status: 'riot_and_roll',
      target: 'allAllies', duration: 1 },
    { kind: 'conditional', when: 'noSkillCastThisRound',
      then: { kind: 'applyStatus', status: 'restless_heart',
              target: 'self', trigger: 'endRound' } },
  ],
}
```

Ultimates do not carry a `tiers` array — they have one effect block. They
do not have a numeric `cost`; the cost is "spend the full Moxie bar by
playing this card." The `mult` field on an Ultimate's `damage` effect uses
the same ATK-percentage scaling as skill cards (§3.2).

### 3.4 Moxie

Per-character resource gating Ultimate availability. Stored as
`moxie: number` on the runtime character instance, max defined by character
(`maxMoxie`, default `5` — see open questions).

Mutations:
- `+1` on playing a skill card (carrier of the played card)
- `+1` on merging two cards (carrier of the merged card)
- Skill clauses can apply arbitrary deltas via `effect: 'enemyMoxie'` or
  `'allyMoxie'` clauses

State transitions:
- `moxie` rises to `maxMoxie` → engine inserts Ultimate card at hand[0]
  (see 3.3).
- `moxie` drops below `maxMoxie` while the Ultimate card is in hand → card
  is removed.
- Ultimate card cast → `moxie` set to 0, card removed.

UI: yellow diamond strip beneath each character's HP bar, count = `moxie`,
max = `maxMoxie`.

**Character-specific resources.** Some characters carry a *second* resource
beyond Moxie (e.g. Aleph's Eureka — see §4.3). These live under an
optional `resources` map on the character literal:

```js
resources: {
  eureka: { max: 7, start: 0 },     // Aleph
  // future characters can add other named pools
}
```

Resource pools are mutated by the `consumeResource` and `gainResource`
effect kinds (§3.7), and by passive hooks (e.g. Aleph's "+4 Eureka at
round start"). Unlike Moxie, character-specific resources do **not**
auto-inject any card and do **not** have universal accrual rules — every
mutation is explicit, scripted by clauses or passives. UI: a small named
chip beneath the Moxie strip, count = current / max.

### 3.5 Statuses

Statuses are not flat stat buffs — they are mini-objects with their own
trigger logic. Three patterns lifted directly from Regulus:

```js
const STATUSES = {
  riot_and_roll: {
    name: 'Riot and Roll',
    desc: 'Dodges any non-Ultimate attack. Dispels after the carrier acts.',
    hooks: {
      onIncomingAttack: (ctx) => ctx.attack.kind !== 'ultimate'
        ? { dodge: true } : null,
      onSelfAction: (ctx) => ({ remove: true }),
    },
  },
  restless_heart: {
    name: 'Restless Heart',
    desc: '+50% Crit Rate. Excess Crit Rate converts to Crit DMG. ' +
          'Cancels after scoring a crit.',
    hooks: {
      computeCritChance: (ctx, base) => base + 50,
      computeCritOverflow: (ctx, overflow) => ({ critDmgBonus: overflow }),
      onSelfCrit: (ctx) => ({ remove: true }),
    },
  },
  inspire: {
    name: 'Inspire',
    desc: 'Buff. Exact mechanical effect TBD — see open question §8.12.',
    duration: 2,
    hooks: {
      onRoundEnd: (ctx, status) => --status.duration <= 0
        ? { remove: true } : null,
      // additional hooks pending Inspire spec
    },
  },
  shield: {
    name: 'Shield',
    desc: 'HP buffer. Absorbs incoming damage before it reaches HP. ' +
          'Removed when depleted.',
    state: { hp: 0 },  // populated when applied
    hooks: {
      computeIncomingDmg: (ctx, dmg, status) => {
        const absorbed = Math.min(status.state.hp, dmg);
        status.state.hp -= absorbed;
        return { dmg: dmg - absorbed,
                 remove: status.state.hp <= 0 };
      },
    },
  },
  clarification: {
    name: 'Clarification',
    desc: 'Incantation Might +10% per stack. Stacks up to 4. ' +
          'Each stack is timed independently.',
    stacks: 1,
    duration: 3,
    independentStackTimers: true,    // each stack ticks separately
    hooks: {
      computeOutgoingDmg: (ctx, dmg, status) =>
        dmg * (1 + 0.10 * status.stacks),
      onRoundEnd: (ctx, status) => {
        // tick each stack timer; drop expired ones
        status.stackTimers = status.stackTimers.map(t => t - 1)
          .filter(t => t > 0);
        status.stacks = status.stackTimers.length;
        return status.stacks === 0 ? { remove: true } : null;
      },
    },
  },
  continuous_action_1: {
    name: 'Continuous Action I',
    desc: 'AP +1 for 1 round (5 actions instead of 4).',
    duration: 1,
    hooks: {
      modifyRoundActions: (ctx, base) => base + 1,
      onRoundEnd: () => ({ remove: true }),
    },
  },
  interpretation: {
    name: 'Interpretation',
    desc: 'Stacking debuff on enemies. Each stack contributes +80% Mental ' +
          'DMG to Aleph\'s final Impromptu Incantation hit. Cleared after ' +
          'that hit resolves.',
    stacks: 1,
    duration: null,             // doesn't auto-expire
    hooks: {
      // No passive effect; consumed by Impromptu Incantation's final
      // attack instance (§4.3 deferred mechanics).
    },
  },
  hyperthymesia: {
    name: 'Hyperthymesia',
    desc: 'Channel status. Carrier cannot act this round; queued ' +
          'memorized incantations resolve at next round start. ' +
          'Full mechanic deferred — see §8.16.',
    duration: 1,
    hooks: {
      onSelfAction: () => ({ block: true }),     // can't act while channeling
      onRoundEnd: (ctx, status, char) => {
        // Replay memorized incantations next round (deferred).
        ctx.queueMemorizedReplay(char);
        return { remove: true };
      },
    },
  },
  silence: {
    name: 'Silence',
    desc: 'Cannot cast Buff, Debuff, Heal, or Counter-type incantations. ' +
          'Attack-type cards still play normally.',
    duration: 1,                                 // populated on apply
    hooks: {
      canCast: (ctx, card) => {
        const blocked = ['buff', 'debuff', 'heal', 'counter'];
        return !blocked.includes(card.tier.category);
      },
      onRoundEnd: (ctx, status) => --status.duration <= 0
        ? { remove: true } : null,
    },
  },
  seal: {
    name: 'Seal',
    desc: 'Cannot cast Ultimate.',
    duration: 1,                                 // populated on apply
    hooks: {
      canCast: (ctx, card) => card.kind !== 'ultimate',
      onRoundEnd: (ctx, status) => --status.duration <= 0
        ? { remove: true } : null,
    },
  },
  paper_buff: {
    name: "Paper's Inspiration",
    desc: '+X% DMG Dealt and +X% incoming heal. ' +
          'X is set by the casting tier (15 / 20 / 25).',
    duration: 2,                                 // populated on apply
    state: { dmgDealtPct: 0, dmgHealPct: 0 },    // populated on apply
    hooks: {
      computeOutgoingDmg: (ctx, dmg, status) =>
        dmg * (1 + status.state.dmgDealtPct / 100),
      computeIncomingHeal: (ctx, heal, status) =>
        heal * (1 + status.state.dmgHealPct / 100),
      onRoundEnd: (ctx, status) => --status.duration <= 0
        ? { remove: true } : null,
    },
  },
};
```

The character runtime maintains `statuses: Status[]` and a dispatcher with
this hook set:

```
onRoundStart, onRoundEnd, onSelfAction, onCast, onHit, onSelfCrit,
onSelfDeath, onIncomingAttack, onAllyCast, onAllyResourceConsume,
canCast, computeCritChance, computeCritDmg, computePenetration,
computeOutgoingDmg, computeIncomingDmg, computeIncomingHeal,
modifyRoundActions, onMoxieChange, onResourceChange
```

`canCast(ctx, card)` is a veto-style hook used by control statuses
(`silence`, `seal`): it returns `true` if casting is allowed, `false`
otherwise. The resolver evaluates every status's `canCast` and disallows
the cast if any return `false`.

Each hook either mutates `ctx`, returns a value, or returns
`{ remove: true }` to signal the status should be cleaned up.

### 3.6 Damage Resolution (proposed)

```
critRolled  = rng() < applyHooks('computeCritChance', attacker.critRate) / 100
critFactor  = critRolled
              ? 1 + applyHooks('computeCritDmg', attacker.critDmg) / 100
              : 1
penetration = applyHooks('computePenetration', 0)        // 0..1
defStat     = (card.dmgType === 'mental' ? defender.mentalDef
                                         : defender.realityDef)
            * (1 - penetration)
raw         = attacker.attack * (card.mult / 100) * critFactor
mitigated   = raw * 1000 / (1000 + defStat)
final       = applyHooks('computeOutgoingDmg',
               applyHooks('computeIncomingDmg', mitigated))
```

The `1000 / (1000 + DEF)` shape gives diminishing returns; the `1000`
constant is a placeholder for tuning. R1999's exact formula isn't
documented; this is a reasonable starting point.

**Penetration** is a new pipeline step (added for Зима's passive). It
multiplies the defender's effective DEF by `(1 - penetration)` *before*
the diminishing-returns mitigation curve, so 10% Penetration shaves 10%
off the defender's DEF stat for that hit. Statuses and passives
contribute via the `computePenetration` hook (returning a value in
`[0, 1]`).

### 3.7 Effect Vocabulary

The `kind` field in an Ultimate's `effects[]` array (and inside skill
`clauses[]` where applicable) takes one of these values:

| `kind`         | Required fields                                | Behavior |
|----------------|------------------------------------------------|----------|
| `damage`       | `mult`, `dmgType`, `target`                    | ATK-scaled damage. `mult` = % of caster ATK; `dmgType` ∈ `'mental' \| 'reality'`. Applies §3.6 resolver. |
| `damageSelf`   | `mult`, `basis`                                | Self-inflicted damage as % of `basis` ∈ `'currentHp' \| 'maxHp'`. `mult: 100, basis: 'currentHp'` reduces caster to 0 HP. |
| `moxie`        | `target`, `amount`                             | Add (positive) or remove (negative) Moxie on a target group. |
| `applyStatus`  | `status`, `target`, `duration?`, `trigger?`    | Apply a named status from the catalog (§3.5) to a target group. |
| `applyShield`  | `target`, `amount`                             | Create a `shield` status on each target with HP set by `amount`. `amount` may be a number, or `{ basis: 'targetAttack' \| 'casterAttack', mult }` to scale off ATK. |
| `consumeResource` | `resource`, `amount`, `target?`             | Subtract `amount` from a named resource pool (e.g. `'eureka'`). Defaults to caster. Fails silently if pool is empty unless wrapped in a `conditional`. Fires `onAllyResourceConsume` for other allies' hooks. |
| `gainResource` | `resource`, `amount`, `target?`                | Add `amount` to a named resource pool. Caps at `max`. |
| `conditional`  | `when`, `then`, `else?`                        | Run the inner effect only if the named predicate matches (e.g. `when: 'noSkillCastThisRound'`, `when: 'hasResource:eureka>=2'`). |

`target` values: `'self'`, `'caster'`, `'single'`, `{ mass: N }`,
`'allEnemies'`, `'allAllies'`, `'otherAllies'`, `'primaryEnemy'`,
`'primaryAlly'`.

`'primaryEnemy'` / `'primaryAlly'` resolve to the **player-designated
focus** of an AoE attack — the unit the player clicked when launching the
card. Lets a single card both AoE-damage everyone and apply a rider to
the focus only (e.g. Зима's `Poem, Island, Breeze` damages all enemies
but only Seals the one she clicked).

The same vocabulary is used by enemy `actions[]` so the resolver doesn't
need to special-case attacker side.

### 3.8 Passives

A character may define an optional `passive` object — an always-active
ability that hooks into the runtime dispatcher. Passives use the **same
hook set as statuses** (§3.5) but are never removed during a battle.

```js
passive: {
  id: 'martyrs_call',
  name: "Martyr's Call",
  desc: 'When this character dies, every other living ally gains +1 Moxie.',
  hooks: {
    onSelfDeath: (ctx, char) => {
      ctx.party
        .filter(c => c !== char && c.hp > 0)
        .forEach(c => c.gainMoxie(1));
    },
  },
}
```

The `passive` field is optional; characters without an innate effect
simply omit it. New hooks needed by passives (e.g. `onSelfDeath`) extend
the dispatcher hook list in §3.5 — they apply to statuses too.

---

## 4. Characters

Four party slots. Slot 1 (Regulus) is fully specified below. Slots 2–4 are
placeholders to be filled in after the first character ships.

### 4.1 Regulus (slot 1) — Mental DPS, Star afflatus (deferred)

```js
regulus: {
  name: 'Regulus',
  rarity: 6,
  damageBias: 'mental',
  stats: {
    // [defaultBase, defaultMax, I_max, II_max, III_max]
    attack:     [266, 404, 677, 1009, 1186],
    health:     [1257, 1907, 3197, 4768, 5609],
    realityDef: [101, 153, 257, 382, 449],
    mentalDef:  [136, 206, 345, 514, 605],
    technique:  [368, 368, 417, 466, 515],
    critRate:   [12.2, 12.2, 13.9, 15.5, 17.1],
    critDmg:    [18.4, 18.4, 20.8, 23.3, 25.7],
  },
  maxMoxie: 5,                  // assumption — see open questions
  startMoxie: 0,
  incantations: [
    {
      id: 'treat_for_ears',
      name: 'Treat for the Ears',
      kind: 'skill',
      school: 'arcane',
      tiers: [
        { mult: 200, dmgType: 'mental', target: 'single',
          category: 'attack', clauses: [] },
        { mult: 300, dmgType: 'mental', target: 'single',
          category: 'attack', clauses: [] },
        { mult: 500, dmgType: 'mental', target: 'single',
          category: 'attack', clauses: [] },
      ],
    },
    {
      id: 'challenge_for_eyes',
      name: 'Challenge for the Eyes',
      kind: 'skill',
      school: 'arcane',
      tiers: [
        { mult: 150, dmgType: 'mental', target: { mass: 2 },
          category: 'attack', clauses: [] },
        { mult: 175, dmgType: 'mental', target: { mass: 2 },
          category: 'attack',
          clauses: [{ on: 'crit', effect: 'enemyMoxie', amount: -1 }] },
        { mult: 275, dmgType: 'mental', target: { mass: 2 },
          category: 'attack',
          clauses: [{ on: 'crit', effect: 'enemyMoxie', amount: -2 }] },
      ],
    },
  ],
  ultimate: {
    id: 'sleepless_rave',
    name: 'Sleepless Rave',
    effects: [
      { kind: 'damage', mult: 300, dmgType: 'mental', target: 'allEnemies' },
      { kind: 'applyStatus', status: 'riot_and_roll',
        target: 'allAllies', duration: 1 },
      { kind: 'conditional', when: 'noSkillCastThisRound',
        then: { kind: 'applyStatus', status: 'restless_heart',
                target: 'self', trigger: 'endRound' } },
    ],
  },
}
```

### 4.2 Door (slot 2) — Reality DPS / sacrifice support

Lower-rarity character (caps at Insight II — note the length-4 stat
arrays). His niche is high-damage Reality skills + a self-sacrificing
Ultimate that converts his own life into team-wide shields and Moxie.

```js
door: {
  name: 'Door',
  rarity: 4,
  damageBias: 'reality',
  stats: {
    // [defaultBase, defaultMax, I_max, II_max]  — no Insight III
    attack:     [211, 320, 536, 799],
    health:     [1270, 1927, 3231, 4818],
    realityDef: [110, 166, 278, 414],
    mentalDef:  [110, 166, 278, 414],
    technique:  [178, 178, 201, 224],     // "–" in source → same as base
    critRate:   [5.9, 5.9, 6.7, 7.4],
    critDmg:    [8.9, 8.9, 10, 11.2],
  },
  maxMoxie: 5,
  startMoxie: 0,
  passive: {
    id: 'martyrs_call',
    name: "Martyr's Call",
    desc: 'When Door dies, every other living ally gains +1 Moxie.',
    hooks: {
      onSelfDeath: (ctx, char) => {
        ctx.party
          .filter(c => c !== char && c.hp > 0)
          .forEach(c => c.gainMoxie(1));
      },
    },
  },
  incantations: [
    {
      id: 'deep_vortex',
      name: 'Deep Vortex',
      kind: 'skill',
      school: 'arcane',
      tiers: [
        { mult: 200, dmgType: 'reality', target: 'single',
          category: 'attack', clauses: [] },
        { mult: 300, dmgType: 'reality', target: 'single',
          category: 'attack', clauses: [] },
        { mult: 500, dmgType: 'reality', target: 'single',
          category: 'attack', clauses: [] },
      ],
    },
    {
      id: 'converging_mirror',
      name: 'Converging Mirror',
      kind: 'skill',
      school: 'arcane',
      tiers: [
        { mult: 150, dmgType: 'reality', target: { mass: 2 },
          category: 'attack', clauses: [] },
        { mult: 225, dmgType: 'reality', target: { mass: 2 },
          category: 'attack', clauses: [] },
        { mult: 375, dmgType: 'reality', target: { mass: 2 },
          category: 'attack', clauses: [] },
      ],
    },
  ],
  ultimate: {
    id: 'alley_universe',
    name: 'To the Universe in the Alley',
    effects: [
      // Self-sacrifice: drops caster to 0 HP, which then triggers the
      // passive `martyrs_call` (+1 Moxie to other allies) on top of the
      // explicit +2 below — net +3 Moxie to each surviving ally.
      { kind: 'damageSelf', mult: 100, basis: 'currentHp' },
      { kind: 'moxie', target: 'otherAllies', amount: +2 },
      // Shield HP scales off each ally's own ATK ("the target's ATK").
      // basis: 'targetAttack' = the ATK stat of the recipient, not the caster.
      { kind: 'applyShield', target: 'allAllies',
        amount: { basis: 'targetAttack', mult: 100 } },
      { kind: 'applyStatus', status: 'inspire',
        target: 'allAllies', duration: 2 },
    ],
  },
}
```

**Notes on Door's ultimate semantics:**

- The self-damage clause runs first; Door drops to 0 HP, which fires his
  `onSelfDeath` passive. Implementation must order `damageSelf` →
  passive trigger → remaining ult effects, otherwise the +2 Moxie clause
  resolves on a corpse-state Door before his passive fires (still works,
  but order matters for animation/SFX).
- "Inflicts a Shield with (the target's ATK x100%) HP on every ally" —
  reading "the target" as **each ally being shielded**, so each ally's
  shield = that ally's own `attack`. (Caster-ATK reading is plausible
  but less idiomatic for buff-distribution skills; flagged in §8.13.)
- Inspire's exact mechanical effect is not given by the source data —
  see §8.12.

### 4.3 Aleph (slot 3) — _DEFERRED — too complex for v1_

> **Status: deferred.** Aleph's full kit (Eureka resource, Inspiration
> accumulation, Impromptu Incantation virtual attack, Memorize /
> Hyperthymesia delayed-cast, cross-character `onAllyCast` broadcast)
> introduces too many new subsystems to ship in the first cut. The spec
> below stays in the doc as a roadmap, but **Aleph is not part of the
> initial roster**. The launch team is Regulus + Door + Зима + a fourth
> still-TBD character. Revisit Aleph once the Phase 1 combat loop is
> stable and the open questions §8.14–§8.18 have answers.

Aleph is the most mechanically dense character on the roster. He carries
a **second resource (Eureka)** alongside Moxie, accrues an **Inspiration**
point pool whenever any ally consumes Eureka, and powers a **virtual
attack ("Impromptu Incantation")** that triggers off ally activity
rather than hand cards. His ult further introduces a **Memorize /
Hyperthymesia** delayed-cast / channel mechanic.

To keep Phase 1 implementation tractable, Aleph is split into:

- **v1 (in scope):** stats, Eureka pool, both skill cards' base damage +
  Clarification stacking + Continuous Action I AP+1 + Eureka cost. The
  Ultimate applies `hyperthymesia` for 1 round (Aleph cannot act) but
  the actual "memorize and replay" payload is a stub.
- **v2 (deferred — see §8.14–§8.18):** Inspiration accumulation,
  Impromptu Incantation virtual attack, Memorize replay, full
  Interpretation interaction with the final Impromptu hit, Aleph's
  Eureka-spend trigger when an ally with Clarification casts.

```js
aleph: {
  name: 'Aleph',
  rarity: 6,
  damageBias: 'mental',
  stats: {
    // [defaultBase, defaultMax, I_max, II_max, III_max]
    attack:     [259, 393, 658, 980, 1153],
    health:     [1478, 2244, 3762, 5610, 6600],
    realityDef: [123, 187, 313, 467, 549],
    mentalDef:  [160, 243, 407, 607, 714],
    technique:  [327, 327, 370, 413, 456],
    critRate:   [10.9, 10.9, 12.3, 13.7, 15.2],
    critDmg:    [16.3, 16.3, 18.5, 20.6, 22.8],
  },
  maxMoxie: 5,
  startMoxie: 0,
  resources: {
    // Base maxEureka would be 5; passive bumps it to 7.
    // Stored post-passive for simplicity.
    eureka: { max: 7, start: 0 },
  },
  passive: {
    id: 'aleph_lecture',
    name: 'The Lecture Continues',
    desc: 'Max Eureka +2 (already baked into resources). +4 Eureka at ' +
          'every round start. Inspiration accumulates on ally Eureka ' +
          'consumption (v2). On ally-with-Clarification cast, spend 1 ' +
          'Eureka to mark next Impromptu Incantation hit with ' +
          'Interpretation (v2).',
    hooks: {
      onRoundStart: (ctx, char) => {
        char.gainResource('eureka', 4);
      },
      // v2 hooks — guarded so they no-op until the v2 mechanics ship:
      onAllyResourceConsume: (ctx, char, evt) => {
        if (!ctx.flags.alephV2) return;
        if (evt.resource !== 'eureka') return;
        ctx.run.inspiration = (ctx.run.inspiration || 0) + evt.amount;
      },
      onAllyCast: (ctx, char, evt) => {
        if (!ctx.flags.alephV2) return;
        if (!evt.caster.hasStatus('clarification')) return;
        if (char.eureka < 1) return;
        char.spendResource('eureka', 1);
        ctx.run.impromptu.interpretationFlags =
          (ctx.run.impromptu.interpretationFlags || 0) + 1;
      },
    },
  },
  incantations: [
    {
      id: 'disciplinary_power',
      name: 'Disciplinary Power',
      kind: 'skill',
      school: 'human',          // distinct from Regulus/Door's 'arcane'
      tiers: [
        { mult: 100, dmgType: 'mental', target: 'single', clauses: [
          { on: 'cast', kind: 'applyStatus',
            status: 'continuous_action_1', target: 'self', duration: 1 },
          { on: 'hit', kind: 'consumeResource',
            resource: 'eureka', amount: 2 },
          // v2: { on: 'hit', kind: 'modifyImpromptu',
          //       attackInstancesDelta: +1 },
        ] },
        { mult: 200, dmgType: 'mental', target: 'single', clauses: [
          { on: 'cast', kind: 'applyStatus',
            status: 'continuous_action_1', target: 'self', duration: 1 },
          { on: 'hit', kind: 'consumeResource',
            resource: 'eureka', amount: 2 },
        ] },
        { mult: 400, dmgType: 'mental', target: 'single', clauses: [
          { on: 'cast', kind: 'applyStatus',
            status: 'continuous_action_1', target: 'self', duration: 1 },
          { on: 'hit', kind: 'consumeResource',
            resource: 'eureka', amount: 2 },
        ] },
      ],
    },
    {
      id: 'idealists_declaration',
      name: "Idealist's Declaration",
      kind: 'skill',
      school: 'human',
      tiers: [
        // ★☆☆: 1 stack base + 1 bonus stack if 2 Eureka are consumed.
        { mult: 0, dmgType: null, target: 'allAllies', clauses: [
          { on: 'cast', kind: 'applyStatus',
            status: 'clarification', target: 'allAllies',
            stacks: 1, duration: 3 },
          { on: 'cast', kind: 'conditional',
            when: 'hasResource:eureka>=2',
            then: [
              { kind: 'consumeResource',
                resource: 'eureka', amount: 2 },
              { kind: 'applyStatus',
                status: 'clarification', target: 'allAllies',
                stacks: 1, duration: 3 },
            ] },
        ] },
        // ★★☆: 2 stacks base + 1 bonus.
        { mult: 0, dmgType: null, target: 'allAllies', clauses: [
          { on: 'cast', kind: 'applyStatus',
            status: 'clarification', target: 'allAllies',
            stacks: 2, duration: 3 },
          { on: 'cast', kind: 'conditional',
            when: 'hasResource:eureka>=2',
            then: [
              { kind: 'consumeResource',
                resource: 'eureka', amount: 2 },
              { kind: 'applyStatus',
                status: 'clarification', target: 'allAllies',
                stacks: 1, duration: 3 },
            ] },
        ] },
        // ★★★: 3 stacks base + 1 bonus.
        { mult: 0, dmgType: null, target: 'allAllies', clauses: [
          { on: 'cast', kind: 'applyStatus',
            status: 'clarification', target: 'allAllies',
            stacks: 3, duration: 3 },
          { on: 'cast', kind: 'conditional',
            when: 'hasResource:eureka>=2',
            then: [
              { kind: 'consumeResource',
                resource: 'eureka', amount: 2 },
              { kind: 'applyStatus',
                status: 'clarification', target: 'allAllies',
                stacks: 1, duration: 3 },
            ] },
        ] },
      ],
    },
  ],
  ultimate: {
    id: 'reflections_of_omniscience',
    name: 'Reflections of Omniscience',
    effects: [
      // v1 — applies the channel status. Memorize/replay payload deferred.
      // v2 will add a 'memorize' effect kind that snapshots the first 2
      // actively-cast incantations this round, and 'hyperthymesia''s
      // onRoundEnd hook will replay them via ctx.queueMemorizedReplay.
      { kind: 'applyStatus', status: 'hyperthymesia',
        target: 'self', duration: 1 },
    ],
  },
}
```

**Aleph's deferred mechanics (v2 punch-list).** None of these block Phase 1
character data, but they're real gameplay surface and need their own
design pass before Aleph plays "correctly":

1. **Inspiration accumulation.** A run-scoped counter (`ctx.run.inspiration`)
   that grows whenever any ally consumes Eureka. Open: amount per
   consumed unit, who can spend Inspiration, persistence across waves.
2. **Impromptu Incantation virtual attack.** Not a hand card — a queued
   attack instance that fires at end-of-round (or some trigger) and uses
   **average party stats** for damage calc. Inspiration scales both its
   damage (`+15% per point`) and its attack-instance count (`+1/2/3/5`
   at `3/6/12/20` Inspiration thresholds).
3. **Memorize / Hyperthymesia replay.** The ult snapshots the first 2
   actively-cast incantations of the round (their tier, Inspiration
   payload, any Rewrite effects), then re-casts them at the next round's
   start, attributed to Aleph but granting no Moxie.
4. **Interpretation final-hit bonus.** The final Impromptu Incantation
   attack instance deals `+(stacks × 80)% Mental DMG` to each enemy
   carrying Interpretation, then strips all Interpretation stacks.
5. **Cross-character `onAllyCast` / `onAllyResourceConsume` triggers.**
   Aleph's passive needs to fire when *another* character takes an
   action, which means the dispatcher has to broadcast cast and
   resource-consume events to every party member, not just the actor.

These extensions touch the combat loop and the round resolver, so they
should land together in a dedicated "Aleph v2" pass after the Phase 1
arcade loop is stable.

### 4.4 Зима (slot 4) — Mental control + scaling team buffer

Lower-rarity (caps at Insight II — length-4 stat arrays). She trades raw
damage for two things: **single-target Silence lockdown** and a
**stacking party-wide damage/heal-received buff**. Her ult drops a
neighborhood-Seal on the player-picked focus to time-out enemy
ultimates. Her HP-threshold passive flips between offensive penetration
when healthy and incoming-damage reduction when low.

```js
zima: {
  name: 'Зима',
  rarity: 4,
  damageBias: 'mental',
  stats: {
    // [defaultBase, defaultMax, I_max, II_max]   — caps at Insight II
    attack:     [242, 368, 616, 919],
    health:     [1263, 1917, 3214, 4793],
    realityDef: [106, 161, 269, 401],
    mentalDef:  [106, 161, 269, 401],
    technique:  [175, 175, 198, 221],          // "–" → same as base
    critRate:   [5.8, 5.8, 6.6, 7.3],
    critDmg:    [8.7, 8.7, 9.9, 11.0],
  },
  maxMoxie: 5,
  startMoxie: 0,
  passive: {
    id: 'frost_resilience',
    name: 'Frost Resilience',
    desc: 'When attacking with HP > 50%, Penetration Rate +10%. ' +
          'When attacked with HP < 50%, incoming DMG -10%.',
    hooks: {
      computePenetration: (ctx, base, char) =>
        (char.hp / char.maxHp) > 0.5 ? base + 0.10 : base,
      computeIncomingDmg: (ctx, dmg, _status, char) =>
        (char.hp / char.maxHp) < 0.5 ? dmg * 0.9 : dmg,
    },
  },
  incantations: [
    {
      id: 'sparrow',
      name: 'Sparrow',
      kind: 'skill',
      school: 'arcane',
      tiers: [
        // ★☆☆: pure attack — no Silence rider, so category stays 'attack'.
        { mult: 200, dmgType: 'mental', target: 'single',
          category: 'attack', clauses: [] },
        // ★★☆: same damage but adds Silence — reclassifies to 'debuff'.
        { mult: 200, dmgType: 'mental', target: 'single',
          category: 'debuff',
          clauses: [
            { on: 'hit', kind: 'applyStatus',
              status: 'silence', target: 'single', duration: 1 },
          ] },
        // ★★★: stronger damage and longer Silence — still 'debuff'.
        { mult: 300, dmgType: 'mental', target: 'single',
          category: 'debuff',
          clauses: [
            { on: 'hit', kind: 'applyStatus',
              status: 'silence', target: 'single', duration: 2 },
          ] },
      ],
    },
    {
      id: 'paper',
      name: 'Paper',
      kind: 'skill',
      school: 'arcane',
      tiers: [
        // ★☆☆: 15% / 15% for 2 rounds.
        { mult: 0, dmgType: null, target: 'allAllies', category: 'buff',
          clauses: [
            { on: 'cast', kind: 'applyStatus', status: 'paper_buff',
              target: 'allAllies', duration: 2,
              params: { dmgDealtPct: 15, dmgHealPct: 15 } },
          ] },
        // ★★☆: 20% / 20% for 2 rounds.
        { mult: 0, dmgType: null, target: 'allAllies', category: 'buff',
          clauses: [
            { on: 'cast', kind: 'applyStatus', status: 'paper_buff',
              target: 'allAllies', duration: 2,
              params: { dmgDealtPct: 20, dmgHealPct: 20 } },
          ] },
        // ★★★: 25% / 25% for 3 rounds.
        { mult: 0, dmgType: null, target: 'allAllies', category: 'buff',
          clauses: [
            { on: 'cast', kind: 'applyStatus', status: 'paper_buff',
              target: 'allAllies', duration: 3,
              params: { dmgDealtPct: 25, dmgHealPct: 25 } },
          ] },
      ],
    },
  ],
  ultimate: {
    id: 'poem_island_breeze',
    name: 'Poem, Island, Breeze',
    effects: [
      { kind: 'damage', mult: 250, dmgType: 'mental',
        target: 'allEnemies' },
      // Seal hits only the player-designated focus of the AoE.
      { kind: 'applyStatus', status: 'seal',
        target: 'primaryEnemy', duration: 2 },
    ],
  },
}
```

**Notes on Зима's semantics:**

- "DMG Heal +X%" is interpreted as **healing received** (incoming heal
  scaled +X%) — see §8.19 for the alternative reading (lifesteal /
  damage-as-heal).
- The Sparrow tier-2/3 reclassification (`'attack'` → `'debuff'`) is a
  real interaction: a Зима under Silence can still cast Sparrow ★☆☆
  (pure attack) but cannot cast ★★☆ or ★★★ until the Silence wears off.
- Her Penetration passive is the first user of the new
  `computePenetration` hook (§3.5) and the first contributor to the
  Penetration step in the damage formula (§3.6).
- The passive checks `char.hp / char.maxHp` against 0.5 — equality at
  exactly 50% gets neither bonus (`>` and `<` are strict). Confirm if
  the source intends `≥` / `≤`; flagged §8.20.

### 4.5 Statuses Catalog

Statuses pinned so far:

- `riot_and_roll` (Regulus) — see §3.5.
- `restless_heart` (Regulus) — see §3.5.
- `inspire` (Door) — see §3.5. **Mechanical effect TBD** (§8.12).
- `shield` (Door) — see §3.5. Stateful HP buffer, absorbs incoming damage
  before HP. Used by `applyShield` effects from any source.
- `clarification` (Aleph) — see §3.5. +10% outgoing damage per stack,
  max 4, each stack independently timed.
- `continuous_action_1` (Aleph) — see §3.5. +1 round action (5 instead
  of 4) for one round.
- `interpretation` (Aleph) — enemy-side stacking debuff; consumed by the
  final Impromptu Incantation attack instance. Full mechanic deferred
  with Aleph v2 (§8.17).
- `hyperthymesia` (Aleph) — channel status; Aleph cannot act for one
  round. Full Memorize replay deferred (§8.16).
- `silence` (Зима) — control status; blocks Buff/Debuff/Heal/Counter
  cards via the new `canCast` veto hook. Attack-type cards still play.
- `seal` (Зима) — control status; blocks Ultimate casts via `canCast`.
- `paper_buff` (Зима) — parameterized buff (`dmgDealtPct`,
  `dmgHealPct`); the Paper card writes its tier-specific values into
  `state` on apply.

The `STATUSES` object is intentionally open-ended; new statuses can be
appended as later characters introduce them. Required fields:
`name`, `desc`, `hooks` (subset of the dispatcher hook list in §3.5),
optional `duration`, `stacks`, `independentStackTimers`, and `state` (for
stateful statuses like `shield`).

---

## 5. Enemies _(deferred — placeholder)_

To be designed once the four characters are spec'd. Current intent:

- Each enemy is a JS object with the same `stats` block shape used by
  characters (so the damage formula doesn't have to special-case them) and
  a list of telegraphed actions.
- Enemies act after the player burns all 4 actions for the round. Action
  order is sorted by `technique` descending.
- Enemy attacks use the same `kind`/`dmgType`/`target` vocabulary as
  player cards so the same damage resolver runs both directions.
- An `ENEMIES = { …id: { name, stats, actions: [...] } }` literal will
  live next to `CHARACTERS` in `ArcadeR1999.js`.

Open: enemy AI shape (scripted pattern vs. weighted-random vs. priority
list), wave / encounter structure, boss mechanics.

---

## 6. Run Progression

A run is a single arcade session: pick a team, fight three waves, submit a
score. Game-state machine constants live in `ArcadeR1999.js` alongside the
existing `GS_*` precedent in `ArcadeDungeon.js:23`.

### 6.1 State Machine

```
GS_TITLE       ──Start────────► GS_TEAMSELECT
GS_TEAMSELECT  ──Confirm──────► GS_BATTLE (wave 1)
GS_BATTLE      ──wave clear───► GS_INTERMISSION ──► GS_BATTLE (next wave)
GS_BATTLE      ──party wipe───► GS_DEFEAT      ──► GS_TITLE
GS_BATTLE (wave 3 clear) ─────► GS_VICTORY     ──► GS_NAMEENTRY ──► GS_TITLE
```

### 6.2 Team Select (`GS_TEAMSELECT`)

The player picks **4 characters** from the roster.

- Roster initially = Regulus + three stub characters (`stubA`, `stubB`,
  `stubC`) that copy Regulus's stats and kit until §4.2–4.4 are filled in.
  This unblocks Phase 2 work without waiting for the full character data.
- All 4 slots must be filled. Duplicates are allowed for now (until the
  full roster is large enough to forbid).
- Insight tier defaults to **III at max level** for arcade-style play
  (peak power; no progression grind). See open question §8.8.
- Confirming the team transitions to `GS_BATTLE` for wave 1 with a fresh
  shared deck assembled from each chosen character's incantations (deck
  composition rules in open question §8.9).

### 6.3 Battle (`GS_BATTLE`)

Each wave runs this loop:

1. Spawn the wave's enemies (see §6.5).
2. Draw the shared hand to its default size (see open question §8.7).
3. Player has **4 actions**. Available actions (per §8.1 defaults):
   cast a card (1 action), move a card in hand (1 action), cast an
   auto-injected Ultimate card (1 action). Merging is **free** when two
   same-`id` same-tier cards become adjacent.
4. After the 4th action — or when the player presses *End Turn* early —
   each enemy acts in `technique`-descending order using its `actions[]`
   script.
5. End-of-round hooks fire (`onRoundEnd`). The hand is re-drawn back to
   its default size from the shared deck.
6. Repeat until either every enemy falls (advance to §6.4) or the entire
   party falls (advance to `GS_DEFEAT`).

Damage from cards uses ATK scaling (§3.2). Damage from enemy actions uses
the same resolver in reverse — enemies have the same `stats` block shape
as characters, so no special-casing.

### 6.4 Intermission (`GS_INTERMISSION`)

Between waves:

- **Full party heal** (default — see open question §8.10).
- All party statuses expire.
- **Moxie carries over** between waves.
- The shared deck carries over (no shuffle reset, no card pruning).
- A one-line preview of the next wave's enemy composition is shown.
- Player presses Continue to advance to the next `GS_BATTLE`.

### 6.5 Wave Composition

Three fixed waves per run:

| Wave | Composition          | Notes                                  |
|------|----------------------|----------------------------------------|
| 1    | 2× weak enemy        | Tutorial-ish ramp.                     |
| 2    | 1× elite + 1× weak   | Forces target prioritization.          |
| 3    | 1× boss              | Telegraphed, possibly multi-phase.     |

Enemy IDs (`weak1`, `elite1`, `boss1`) are placeholders; the enemy roster
in §5 will resolve them. Until §5 is filled, **stub enemies that mirror a
character's stat block (with `attack` and `health` halved for trash, kept
parity for boss)** keep the loop end-to-end playable.

### 6.6 Scoring (proposed)

Score accumulates over the run and is submitted via
`ui_act("submit_score", { name, score })` on victory, mirroring
`arcade_cardgame.dm:108`.

| Source                                          | Points |
|-------------------------------------------------|-------:|
| Each weak enemy killed                          |    +10 |
| Each elite enemy killed                         |    +50 |
| Boss killed                                     |   +200 |
| Per unspent action at end of wave               |     +5 |
| Wave finished with whole party above 75% HP     |    +50 |

Player name defaults to ckey, max 7 chars (mirrors arcade_cardgame's
truncation at `arcade_cardgame.dm:108`).

### 6.7 Victory (`GS_VICTORY`)

After the wave-3 boss falls: brief celebration, score readout, then
`GS_NAMEENTRY` for the leaderboard. Submitting returns to `GS_TITLE` and
triggers `prizevend()` on the DM side (`arcade.dm:77`).

### 6.8 Defeat (`GS_DEFEAT`)

If the entire party hits 0 HP at any point: show final wave reached and
score (informational only — no leaderboard submission on loss). "Press R
to retry" returns to `GS_TITLE`. Mirrors `ArcadeDungeon.js`'s defeat flow.

---

## 7. File Layout

New files (Phase 1 = character data + harness; combat loop fills in over
later phases):

| Path | Purpose |
|---|---|
| `lobotomy-corp13/arcade_r1999_plan.md` | **This file** — canonical design doc inside the codebase, kept alongside repo conventions like `seed_of_greed_plan.md`. Subsequent design changes update this file. |
| `lobotomy-corp13/code/game/machinery/computer/arcade_r1999.dm` | Thin DM shell — `/obj/machinery/computer/arcade/r1999`, mirrors `arcade_cardgame.dm:69`. Holds leaderboard, calls `ui_interact` with TGUI key `"ArcadeR1999"`. |
| `lobotomy-corp13/code/modules/circuitboards/computer/arcade.dm` *(extend)* | Add `/obj/item/circuitboard/computer/arcade/r1999`. Mirror existing entries. |
| `lobotomy-corp13/tgui/packages/tgui/interfaces/ArcadeR1999.js` | Inferno canvas component. Phase 1 contains only the `CHARACTERS` literal (Regulus filled, 3 stubs), the `STATUSES` literal, the `statAt()` resolver, the status hook dispatcher, the Moxie → Ultimate-card injection rule, and a debug panel that exercises them. No combat loop yet. |

Files to read for reference (not modify):
- `code/game/machinery/computer/arcade.dm:61` — base arcade obj, `prizevend()`.
- `code/game/machinery/computer/arcade_cardgame.dm:69-138` — closest analogue
  for the DM shell idiom.
- `tgui/packages/tgui/interfaces/ArcadeDungeon.js:53` — canonical
  `CHARACTERS = {…}` literal layout to mirror.
- `tgui/packages/tgui/interfaces/ArcadeDungeon.js:18-48` — canvas size
  constants and `GS_*` / hotkey conventions.

No existing card/deck/hand component to reuse — confirmed.

---

## 8. Open Questions (deferred — not blocking Phase 1 character data)

These don't affect the character data shape; they affect the battle loop
and run progression.

1. **Action costs.** Cast = 1 action confirmed. Does **moving a card** in
   the hand cost 1? Does **merging** cost an action or is it free when
   adjacency is achieved? Does the Ultimate cost an action from the
   4-budget? *(default assumption: cast = 1, move = 1, merge is free on
   adjacency, ultimate = 1.)*
2. **Moxie cap and starting value.** Default to `maxMoxie = 5,
   startMoxie = 0`?
3. **Moxie gain per merge.** 0, 1, or 2? *(default assumption: +1.)*
4. **Crit overflow ratio.** `Restless Heart` says "excess Crit Rate
   converts to Crit DMG" — 1:1 percentage points, or some ratio?
   *(default assumption: 1:1.)*
5. **Insight progression** — picked at run start (arcade-style loadout),
   or meta-currency that persists across runs?
6. **Ultimate card visuals.** Does the auto-injected Ultimate card share
   the same dimensions as a normal card, or is it visually larger to
   advertise itself? *(default: same size, gold frame.)*
7. **Default hand size.** R1999 uses 4. *(default assumption: 4.)*
8. **Insight tier on team select.** Always max (III, max level), or
   player-tunable for difficulty / score multiplier? *(default: forced
   max for arcade-style play.)*
9. **Deck composition per character.** How many copies of each skill card
   go into the shared deck? R1999 ships ~2 copies of each `★☆☆` card per
   character. *(default assumption: 2 copies × 2 skill cards × 4
   characters = 16-card shared deck.)*
10. **Inter-wave healing.** Full / partial / none? *(default: full heal
    + status wipe; Moxie + deck carry over.)*
11. **Boss multi-phase mechanics.** Does the wave-3 boss flip phases at
    HP thresholds, or is it a single-phase fight in v1? *(default: single
    phase in v1; phases deferred.)*
12. **`inspire` status effect.** Door's ultimate applies it for 2 rounds
    but the source text doesn't define what it does mechanically. R1999's
    canonical Inspire is something like "+30% damage dealt" or "next
    attack crits" — needs the user's call before it can be implemented.
    Until pinned, the runtime just treats it as a tracked-but-inert status.
13. **`applyShield` `targetAttack` interpretation.** Door's ult text reads
    "Shield with (the target's ATK x100%) HP on every ally". Currently
    interpreted as **each ally's own ATK** (so DPS allies get bigger
    shields). Alternative reading is **caster's ATK**, in which case all
    allies get the same shield amount. Confirm which.
14. **Aleph: Inspiration accrual rate.** "Whenever an ally consumes
    Eureka, accumulate points of Inspiration" — how many points per
    consumed unit (1:1?), and is Inspiration a run-scoped counter or
    per-round? Persistence across waves?
15. **Aleph: Impromptu Incantation trigger.** When does Impromptu
    Incantation actually fire? End of round? After every ally cast?
    Once per round? Spec says it scales off "average ally stats" and
    has variable attack instances — which step of round resolution
    runs it?
16. **Aleph: Memorize / Hyperthymesia replay.** When the channel ends,
    are memorized incantations replayed *in the new round* or *as part
    of the previous round's resolution*? Do they consume actions from
    the new round's budget? Do they re-pull Moxie costs etc.?
17. **Aleph: Interpretation final-hit bonus.** The "final Impromptu
    Incantation attack instance" needs an "is-final" flag during
    multi-instance resolution. Confirm bonus damage is `(per-target
    stacks × 80%)` summed across enemies hit, or applied per-target.
18. **Aleph v1 vs v2 cutover.** Should Phase 1 ship Aleph in v1 form
    (basic kit, stub ult), or wait for the v2 mechanics so he plays
    correctly the first time? *(Recommendation: ship v1 alongside the
    other characters; flag Aleph's ult as "incomplete" in the team
    select tooltip until v2 lands.)* **Resolved: Aleph deferred.** The
    launch roster is Regulus + Door + Зима + a fourth character TBD;
    Aleph re-enters the conversation once the basic loop is shipped.
19. **Зима: "DMG Heal" interpretation.** Paper buffs "DMG Dealt +X% and
    DMG Heal +X%". Currently read as **incoming heal +X%** (healing
    received scales). Alternative readings: (a) lifesteal — caster heals
    for X% of damage dealt, (b) outgoing-heal scaling for healers. R1999
    canonically means (a) lifesteal-style "Damage→Heal" in some sources
    and (b) "Healing dealt" in others. Confirm which.
20. **HP-threshold strictness.** Зима's passive triggers at HP "above
    50%" / "below 50%". Currently strict (`>` / `<`), so exactly 50% HP
    gets neither bonus. R1999 canonical thresholds are usually inclusive
    on one side (`≥` for the offensive bonus, `<` for the defensive).
    Confirm.

---

## 9. Verification (Phase 1)

Phase 1 is data + a static evaluator. Verification is:

1. **Compile clean.**
   `"C:\Program Files (x86)\BYOND\bin\dm.exe" "C:\Work\lc13\lobotomy-corp13\lobotomy-corp13.dme"`
   — must succeed with no new warnings.
2. **TGUI lint.** Run the awk line-length check on `ArcadeR1999.js`
   (max 80 chars) per CLAUDE.md.
3. **In-game smoke test.** Spawn the new arcade machine in a test world,
   `attack_hand` it, confirm the TGUI window opens to a debug panel that:
   - Renders Regulus's stats at `(Insight II, level max)` matching the
     source table within ±1.
   - Lists his 3 cards (2 skills × 3 tiers + ultimate) with their effect
     text.
   - Applies `Restless Heart` to a synthetic target and shows the resulting
     crit chance reaches 100% with overflow correctly bumping crit DMG.
   - Setting Regulus's Moxie to `maxMoxie` injects a non-mergeable
     `Sleepless Rave` card at hand index 0; lowering Moxie removes it.
4. **Static-data round-trip.** Confirm `ui_static_data` payload arrives in
   the JS component (log it in the debug panel).

Combat loop, hand UI, enemies, scoring, and prize vending are deferred to
Phase 2.
