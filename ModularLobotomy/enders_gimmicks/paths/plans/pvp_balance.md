# PvP Balance — Path Users vs Non-Path Humans

## System overview

Path damage to humans applies, in this order:

1. (PvE-only) elemental DMG, level-diff, RES, LC13 avg coefficient.
2. **PvP scaling factor** — applied only when the target has no path. Caps each ability's contribution against a per-class "target" trace level so default-trace players hit softer than the design baseline and trace upgrades grow into it.
3. **HP-ratio scaling**: `damage *= target.maxHealth / max(owner.maxHealth, 1)`. Path-vs-path = 1.0× (no change).
4. **Armor average**: `damage *= (100 - avg(red, white, black, pale)) / 100`. Reads from the target's `OCLOTHING` slot if it has an armor datum.

Damage *to* path users from non-path humans (`species.dm apply_damage`) still scales by `damage *= path.maxHealth / max(attacker.maxHealth, 1)`. Path-vs-path damage is symmetric (no scaling either direction).

Path stats also follow the **rebalanced curve** (5× growth from Lv 1 → Lv 80, was 7.4×) and the **flatter Basic scaling** (50% → 70% across L1 → L7, was 50% → 110%). DEF damage-reduction uses `def / (def + 800)` (was `def + 300`). These are baked into the worked examples below.

## The PvP scaling factor

For each ability, the multiplier applied to PvP damage is:

```
pvp_factor = scaling_table[actual_trace_level]
           / scaling_table[target_trace_level]
```

- **Below target** → factor < 1: default-trace players land below the design baseline.
- **At target** → factor = 1: the design-intent damage point.
- **Above target (L11–L12)** → factor slightly > 1: small reward for full progression.

The factor is per-ability — Basic, Skill, Ult, and Passive each compute their own using their own scaling table.

### Per-class target levels

Defined in `_path_defines.dm`:

| Ability class | Max | Target | L1 factor | L_target | L_max factor |
|---|---|---|---|---|---|
| Basic | 7 | **6** | 50/67 = 0.75× | 1.00× | 70/67 = 1.045× |
| Skill | 12 | **10** | 62.5/125 = 0.50× | 1.00× | 137.5/125 = 1.10× |
| Ultimate | 12 | **10** | varies (~0.67× for Destruction Blowout FH) | 1.00× | ~1.067–1.10× |
| Passive | 12 | **10** | varies | 1.00× | ~1.10× |

Note: the Basic factor curve is now **tighter** (0.75–1.045×, was 0.50–1.10×) because the underlying `atk_scaling` was flattened (50/53/57/60/63/67/70 instead of 50/60/70/80/90/100/110).

### What the factor does NOT touch

- **PvE damage** (mobs, abnormalities, ordeals).
- **Path-vs-path damage** (target has a path → factor is skipped).
- **Stat trace bonuses** (ATK +28%, DEF +12.5%, elemental DMG % from the trace tree). These flow through `GetStat()` and apply at full strength to PvP, intentionally rewarding full progression beyond ability levels.
- **Already-snapshotted DoTs** (Nihility burn locks its factor at apply time, then ticks at that rate for the full 20s duration).

## Scaling factor table per ability (Destruction reference)

### Basic — atk_scaling = [50, 53, 57, 60, 63, 67, 70]

| Trace | 1 | 2 | 3 | 4 | 5 | 6 (target) | 7 (max) |
|---|---|---|---|---|---|---|---|
| Factor | 0.75 | 0.79 | 0.85 | 0.90 | 0.94 | 1.00 | 1.045 |

### Skill — atk_scaling = [62.5, 68.75, 75, 81.25, 87.5, 93.75, 101.56, 109.38, 117.19, 125, 131.25, 137.5]

| Trace | 1 | 4 | 7 | 10 (target) | 11 | 12 (max) |
|---|---|---|---|---|---|---|
| Factor | 0.50 | 0.65 | 0.81 | 1.00 | 1.05 | 1.10 |

### Ultimate (Blowout FH) — [300, 315, 330, 345, 360, 375, 393.75, 412.5, 431.25, 450, 465, 480]

| Trace | 1 | 4 | 7 | 10 (target) | 11 | 12 (max) |
|---|---|---|---|---|---|---|
| Factor | 0.667 | 0.767 | 0.875 | 1.00 | 1.033 | 1.067 |

## Reference matchups (Destruction, post-rebalance)

Format: damage values are per full hit, rounded. PvP unit per 100% scaling = `ATK × 1.025 × 0.8 × (target_HP / owner_HP) × armor_factor`. Lever 2 preserves the path's ATK/HP ratio (~0.515), so unit values are essentially identical to pre-Lever-2 numbers.

### Lv 40 vs Little Brother (160 HP, 22.5 armor)

ATK 229, HP 445 → unit per 100% = **52.3**

| Ability | Default L1 | Target | Max |
|---|---|---|---|
| Basic L1 / L6 / L7 | 26 dmg | **35 dmg** (5 hits) | 37 dmg |
| Skill L1 / L10 / L12 | 33 dmg | **65 dmg** (3 skills) | 72 dmg |
| Ult Blowout FH L1 / L10 / L12 | 157 dmg | **236 dmg** (1-shot) | 251 dmg |

### Lv 54 vs East Soldato (180 HP, 35 armor)

ATK 309, HP 599 → unit per 100% = **49.5**

| Ability | Default L1 | Target | Max |
|---|---|---|---|
| Basic L1 / L6 / L7 | 25 | **33** (6 hits) | 35 |
| Skill L1 / L10 / L12 | 31 | **62** (3 skills) | 68 |
| Ult Blowout FH L1 / L10 / L12 | 149 | **223** (1-shot) | 238 |

### Lv 67 vs East Capo (200 HP, 55 armor)

ATK 364, HP 707 → unit per 100% = **38.0**

| Ability | Default L1 | Target | Max |
|---|---|---|---|
| Basic L1 / L6 / L7 | 19 | **26** (8 hits) | 27 (8 hits) |
| Skill L1 / L10 / L12 | 24 | **48** (5 skills) | 52 (4 skills) |
| Ult Blowout FH L1 / L10 / L12 | 114 | **171** (2 ults) | 182 (2 ults) |

### Lv 67 vs Big Brother (300 HP, 52.5 armor)

ATK 364, HP 707 → unit per 100% = **60.2**

| Ability | Default L1 | Target | Max |
|---|---|---|---|
| Basic L1 / L6 / L7 | 30 | **40** (8 hits) | 42 (8 hits) |
| Skill L1 / L10 / L12 | 38 | **75** (4 skills) | 83 (4 skills) |
| Ult Blowout FH L1 / L10 / L12 | 181 | **271** (2 ults) | 289 (2 ults) |

## Comparison to pre-rebalance numbers

The biggest visible change is **Basic damage at max trace dropping ~36%** (Lever 3): Basic L7 went from `1.10 × baseline` to `0.70 × baseline_old = 1.045 × new_baseline`. Skill and Ult numbers at target stay roughly the same as before (their scaling tables weren't touched).

| Tier | Old Basic L7 dmg | **New Basic L7 dmg** | Old Skill L10 dmg | **New Skill L10 dmg** |
|---|---|---|---|---|
| Lv 40 vs Lil Bro | 52 | **37** | 65 | 65 |
| Lv 54 vs Soldato | 54 | **35** | 61 | 62 |
| Lv 67 vs Capo | 42 | **27** | 47 | 48 |
| Lv 67 vs Big Bro | 67 | **42** | 76 | 75 |

Sustained Basic damage takes the biggest hit, so the path's "swing-trade" contribution drops. Skill / Ult bursts still land at the same numbers — bursts remain the path's "extraordinary" lever.

## Follow-up hits (10% chip)

Within a turn, a path user gets ~6 swings: 1 full + ~5 follow-ups at 10% damage each. The PvP factor applies identically to both — a follow-up hit is exactly 10% of whatever the full hit landed.

Per-turn total damage (1 × full + 5 × follow-up = 1.5 × full):

| Char Lv vs Capo | Full Basic L1 | Per turn L1 | Full Basic L7 | Per turn L7 |
|---|---|---|---|---|
| Any (PvP-invariant) | 19 | ~28.5 | 27 | ~40 |

Per-turn Basic damage at default L1 traces is ~71% of what it would be at max-trace (was 50% pre-rebalance) — because the Basic factor curve is now tighter (0.75–1.045 vs 0.50–1.10).

## Edge cases

- **Lv 1 path with maxed traces**: a brand-new pathstrider who somehow rushed all ability nodes hits non-path humans as if at L1 traces in the design's eyes — 0.5× baseline (Skill/Ult) or 0.75× baseline (Basic). The factor restores the curve. Stat trace bonuses (full-trace ATK +28%) still apply on top.
- **Lv 80 path with default L1 traces**: still hits at the same factor — character level alone gives no PvP advantage. Trace investment is the gating mechanism.
- **Empowered attacks** (Destruction Stardust Ace's empowered Basic, Preservation enhanced Basic): the factor is computed against the **Ultimate's** scaling table, since the empowered hit borrows the Ult's scaling. The flatter Basic curve from Lever 3 does NOT affect empowered hits.
- **Hunt Ult vs slowed**: factor uses the summed `base_scaling[i] + spd_bonus[i]` curve so target vs actual is computed against the same combined growth.
- **Nihility Burn DoT**: factor is snapshotted alongside `burn_damage` at Skill cast. All ticks during the 20s duration apply that snapshotted factor regardless of in-flight trace changes. The Ult's burn detonate inherits the same snapshotted factor from each victim's burn.
- **Harmony Benediction bonus**: the bonus Lightning hit (consumed on the ally's next attack) snapshots its factor at Skill cast, not at consume time — so a Harmony player who upgrades Skill mid-fight doesn't retroactively boost an already-applied Benediction.

## Maximum-progression PvP damage

For full transparency: a fully-traced max-level Destruction (L7 Basic, L12 Skill, L12 Ult, all stat trace nodes unlocked) deals roughly:

```
factor (1.10× from Skill/Ult ability traces)
× stat_trace_atk (1.28× from full ATK% nodes)
≈ 1.41× the design baseline (Skill/Ult)

factor (1.045× from Basic ability traces, Lever 3)
× stat_trace_atk (1.28×)
≈ 1.34× the design baseline (Basic)
```

This is intentional. Stat trace bonuses are kept fully active in PvP as a meaningful payoff for full progression. If the resulting cap feels too high in playtesting, the next lever is to scale stat trace bonuses in PvP — that's a separate change from this factor (see `lever_4_hp_growth_reduction.md` for related deferred work).
