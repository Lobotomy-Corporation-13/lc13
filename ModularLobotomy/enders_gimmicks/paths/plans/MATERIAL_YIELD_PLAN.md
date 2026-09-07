# Material Yield Brainstorm - How Much Each Source Gives

Companion to PROGRESSION_MATERIALS_PLAN (which defines the *costs*) and
CALYX_SYSTEM_PLAN. This doc brainstorms the *supply* side: how much material each
source hands out, as tunable ranges, calibrated so a dedicated Pathstrider can
fully ascend in ~1-2 shifts but maxing every trace stays a multi-shift endgame
grind.

There are exactly **two sources of material**:

1. **Abnos via the Extraction Module** - working and force-breaching abnormalities.
   Yields the path's sin-tied **Main** (Path) material.
2. **Calyxes** - opt-in Fragmentum incursion waves. Yield the color's **Trace**
   material (and a small chance at Main).

Ordeals give **nothing**. All numbers are first-pass and tunable. T1 = 2-star,
T2 = 3-star, T3 = 4-star.

---

## 0. What we are calibrating against (demand recap)

From PROGRESSION_MATERIALS_PLAN Sections 5-6, per path:

| Goal | Main T1 | Main T2 | Main T3 | Trace T1 | Trace T2 | Trace T3 |
|---|---|---|---|---|---|---|
| Full ascension (0->6, cap 80) | 25 | 28 | 3 | - | - | - |
| Basic ATK trace 1->6 | 4 | 5 | 5 | 2 | 6 | 8 |
| One of Skill/Ult/Passive 1->10 | 6 | 10 | 5 | 2 | 12 | 23 |
| All 3 (Skill+Ult+Passive) | 18 | 30 | 15 | 6 | 36 | 69 |
| Bonus + stat nodes (main only, rough) | ~15 | ~15 | ~13 | - | - | - |
| **Grand total, fully maxed path** | **~62** | **~78** | **~39** | **~8** | **~42** | **~77** |

Two milestones frame the economy:

- **"Ascend to 80"** (unlock the cap): 25 T1 + 28 T2 + 3 T3 **Main**, from abnos.
  Should feel achievable in **1-2 shifts**. The T3 here is tiny (3) and comes from
  synthesizing T2 up (3:1), so the real ask is ~25 T1 and ~37 T2-equivalent of Main.
- **"Max a single trace to 10"**: ~23 **Trace** T3 + supporting T2, from Calyxes.
  This is the **long-tail**; one maxed trace should take **2-4 shifts** of high-tier
  Calyxes, and maxing all four traces across every path is never a one-shift thing.

The synthesizer (3:1 rarity-up) means every source feeds a **pool** - T1 surplus
becomes T2, T2 becomes T3 - so the tables list what drops *directly* and the rollup
(Section 5) accounts for conversion.

---

## 1. Source A1 - Extraction Module passive trickle (per completed work)

Hooks `work_complete()`; awards the abno's sin-family **Main** material at T1,
scaled by work result and PE. A steady drip that funds ascension T1 and early
traces just by doing normal containment work.

| Work result | Main T1 per work | Rare T2 chance |
|---|---|---|
| Bad | 0-1 (avg ~0.3) | - |
| Neutral | 1 | - |
| Good | 1-2 | ~5% for 1 T2 |
| Great (high PE) | 2-3 | ~10-15% for 1 T2 |

- A worker doing **20-40 on-sin work actions** a shift nets **~25-60 Main T1** and
  **~1-4 Main T2** from the trickle alone.
- Deliberately never drops T3, and only trickles T2 - covers ascension **T1** and
  stalls before it can fund a full ascension by itself.
- Knob: if it floods, make the base award probabilistic instead of guaranteed.

## 2. Source A2 - Extraction Module forced breach (per breach)

Reward drops when the **breached** abno dies. The main Main-T2 tap. Yield scales
with the abno's **threat grade**, mixed T1 + T2, laddered so a genuinely dangerous
breach is a real payout rather than a linear tick (and mirrors the facility risk).

| Abno grade | Main T1 | Main T2 | Notes |
|---|---|---|---|
| ZAYIN / TETH | 3-5 | 1-2 | baseline, easy breach |
| HE | 5-8 | 3-5 | decent step up from TETH |
| WAW | 11-16 | 7-12 | massive step up from HE (~2x) |
| ALEPH | 15-22 | 11-17 | top of the ladder |

- Charges: **3 max, ~1 per 10 min regen** (materials plan 2c). A ~2-hour shift
  supports **6-12 forced breaches** (3 stock + regen, minus downtime and risk).
- Per-shift breach supply, **typical (mostly TETH/HE):** ~30-100 Main T1 and
  ~18-60 Main T2. A single **WAW or ALEPH** breach alone matches a whole shift of
  low-grade breaching. With the trickle this covers a full ascension's 25 T1 / 28 T2
  in a shift or two, risk/alert cost gating the pace.
- No direct T3: the ascension's 3 T3 (and any trace Main T3) is **synthesized** from
  breach-won T2 (3 T2 -> 1 T3). So breaching is indirectly the Main-T3 source too,
  at a 3:1 tax.

## 3. Source B - Calyxes (the sole Trace source)

Opt-in Fragmentum waves, spawned 2-4 per meltdown (CALYX_SYSTEM_PLAN). Each is
themed to an ordeal **color** (sets the Trace family) and rolls a **danger tier**
gated by roundtime (sets the rarity mix). Clearing one drops the color's **Trace**
material, plus a small chance at the themed path's **Main** material. This is the
*only* way to get Trace Material - ordeals give nothing.

Per Fragmentum-mob death:

| Calyx danger tier (grade) | Trace per mob | Main-material chance |
|---|---|---|
| Lesser (Dawn) | 1-2 T1 | ~10% for 1 Main T1 |
| Common (Noon) | 1-2 T1, ~15% for 1 T2 | ~12% for 1 Main T1 |
| Greater (Dusk) | 1-2 T2, ~15% for 1 T3 | ~15% for 1 Main T2 |
| Fractal (Midnight) | 2-3 T2, ~25-35% for 1 T3 | ~20% for 1 Main T2 |

Wave stock (`max_spawns`) is roughly **8-20 mobs** per Calyx (scale up with tier).
Optionally a small on-clear bundle to survivors (2-4 of the tier's rarities) on top.
Per fully-cleared Calyx:

- **Lesser:** ~10-30 Trace T1 (+ a few Main T1).
- **Common:** ~10-30 Trace T1 + ~1-4 Trace T2.
- **Greater:** ~12-36 Trace T2 + ~2-6 Trace T3.
- **Fractal:** ~20-50 Trace T2 + ~6-16 Trace T3.

Because tiers are roundtime-gated, **T3 farming is a late-shift activity** - early
meltdowns bloom Lesser/Common Calyxes (T1/T2), late ones bloom Greater/Fractal
(T2/T3). A single Greater/Fractal clear can be a third of a maxed trace's T3, which
is the payoff that justifies opening one. Trace supply is therefore paced by how
many meltdowns a shift sees and how many high-tier Calyxes the crew can handle.

## 4. Synthesizer - not a source, an effective multiplier

The Omni-Synthesizer creates nothing; it retimes what you have:

- **Synthesis 3:1** - 3 lower -> 1 higher, same family. So Main T3 costs 3 T2 (9 T1)
  of effort; Trace T3 costs 3 Trace T2. Every "T3" demand reads as "3x T2" when
  direct T3 is short.
- **Exchange 2:1** - 2 of one path family -> 1 of another, same rarity (Main only;
  Trace families never exchange). A catch-up valve at a 2:1 tax.

Calibration implication: the direct drops only need to cover T1/T2 demand
comfortably; T3 demand is met by leaving headroom in T2 supply for the 3:1
conversions. The tables above are set so T2 supply exceeds T2 demand enough to feed
T3 synthesis on both sides (Main via breaches, Trace via Calyxes).

---

## 5. Per-shift rollup (one engaged Pathstrider, ~2h shift)

Rough expected haul if the player works/breaches their sin abnos and clears the
Calyxes matching their cluster. Main assumes mostly TETH/HE breaches (a WAW/ALEPH
spikes it); Trace assumes ~2-5 cleared Calyxes scaling from Lesser early to
Greater/Fractal late.

| Resource | Trickle | Breach | Calyxes | Shift total |
|---|---|---|---|---|
| Main T1 | 25-60 | 30-100 | 0-6 | **~55-165** |
| Main T2 | 1-4 | 18-60 | 0-6 | **~19-70** |
| Main T3 | - | (synth) | - | **~6-23 via 3:1** |
| Trace T1 | - | - | 20-50 | **~20-50** |
| Trace T2 | - | - | 20-60 | **~20-60** |
| Trace T3 | - | - | 10-35 | **~10-35** |

Against demand:

- **Full ascension (25 T1 / 28 T2 / 3 T3 Main):** one strong shift roughly covers
  T1 and T2; two shifts is comfortable. Matches the "ascend to 80 in 1-2 shifts"
  target.
- **One trace to 10 (~23 Trace T3):** ~2-4 shifts, since Trace T3 caps at ~10-35 and
  depends on reaching enough Greater/Fractal Calyxes. Matches the long-tail intent.
- **Fully maxed path (~62/78/39 Main, ~8/42/77 Trace):** deliberately many shifts;
  Trace T3 (~77) is the binding constraint, gating on repeated high-tier Calyxes.
- **Quiet shift risk:** with few meltdowns, few Calyxes spawn and Trace supply
  craters, while ascension (abno-driven) keeps flowing. That asymmetry is the main
  open balance question (Section 7).

## 6. Knobs (fastest levers if pacing is off)

1. **Ascension too fast/slow** -> forced-breach T2 range (Section 2) and charge
   regen time. The single biggest ascension knob.
2. **Traces too fast/slow** -> Calyx spawn count per meltdown, per-mob Trace amounts,
   and the danger-tier roundtime gates. These set the long-tail length directly,
   especially the Greater/Fractal T3 rates.
3. **Trickle flooding** -> make the base T1 award probabilistic; drop the great-work
   T2 chance.
4. **Calyxes trivializing the grind** -> lower wave `max_spawns` or per-mob amounts,
   or the global active-Calyx cap (CALYX_SYSTEM_PLAN Section 8).
5. **Player-count scaling** -> Calyx wave totals scale with headcount; per-mob
   *rates* (not per-clear totals) are the population-safe knob.

## 7. Open questions

1. **Quiet-shift Trace floor** - Trace comes only from Calyxes (meltdown-gated), so
   a low-meltdown shift starves traces. Accept it (Calyxes are the deliberate farm),
   or add a small Calyx-independent floor?
2. Per-mob drop **rates vs guaranteed** small amounts - probabilistic (chosen here,
   population-safe) or fixed small quantities?
3. Should the optional on-clear Calyx bonus scale with **contribution** (damage/
   kills) or be flat per survivor?
4. Calyx **Main-material** side-chance (Section 3) - keep the small drop as a bonus,
   or make Calyxes Trace-only and leave all Main to the module?
5. Do we want a **shift cap** on any single source so one method can't dominate, or
   let meltdown/charge cadence self-limit it?
