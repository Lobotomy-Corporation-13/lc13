# Lever 4 — HP-only further reduction (deferred)

This is a **future-iteration** lever that was scoped out of the initial 3-lever rebalance package (DEF formula, stat_table flatten to 5×, Basic scaling cap). Apply only after playtesting the 3-lever package; if path durability still feels disproportionate at HE/WAW tiers, this knocks it down further without touching DPS.

## Why

Even after the 3-lever package, path users are still **3.0–3.5× tankier** than tier-matched EGO agents at the HE/WAW (Noon/Dusk) bracket:

| Tier | Path EHP (post-3-lever) | Agent EHP | Path / Agent ratio |
|---|---|---|---|
| Lv 27 / TETH | 446 | ~147 | 3.0× |
| Lv 54 / HE | 772 | ~218 | 3.5× |
| Lv 80 / WAW | 1131 | ~339 | 3.3× |
| Lv 80 / ALEPH | 1131 | ~700 | 1.6× |

The mismatch isn't from path DEF (Lever 1 already fixed that); it's from path HP being 5× the Lv 1 baseline while agent EGO armor at tiers 2–3 is light (5–17% avg). Reducing path HP growth specifically targets that gap, leaving ATK/DEF growth and ability scaling untouched.

## Proposed change

In every path's `stat_table`, **scale the HP column down by an additional factor of `0.8`** on top of Lever 2's 0.627×. ATK and DEF stay at their Lever 2 values.

Math: HP growth becomes 4× (was 5× post-Lever-2, was 7.4× originally). Per-path Lv 80 HP endpoints:

| Path | HP at Lv 1 | HP Lv 80 (Lever 2 only) | **HP Lv 80 (Lever 2 + 4)** |
|---|---|---|---|
| Destruction | 163 | 815 | **652** |
| Hunt | 120 | 598 | **478** |
| Erudition | 129 | 645 | **516** |
| Nihility | 120 | 598 | **478** |
| Harmony | 115 | 573 | **458** |
| Preservation | 168 | 841 | **673** |
| Abundance | 158 | 789 | **631** |

Implementation: for each path's `stat_table`, recompute the HP column with the `0.5` scale factor applied to the growth portion (i.e., `new_HP = HP_lv1 + (old_HP_post_lever2 - HP_lv1) × 0.8`). ATK and DEF columns are untouched.

(Equivalently: `new_HP = HP_lv1 + (original_HP - HP_lv1) × 0.502` directly from the original tables, where `0.502 = 0.627 × 0.8`.)

## Expected effect

Effective HP at Lv 80 with new DEF DR formula (lever 1 = `def + 800`):

| Tier | Path HP (post 2+4) | DR | Path EHP | Agent EHP | Path / Agent |
|---|---|---|---|---|---|
| Lv 1 | 163 | 7.2% | 175.6 | ~102 | 1.7× |
| Lv 27 | 324 | 15.3% | 382.5 | ~147 | 2.6× |
| Lv 54 | 491 | 22.2% | 631 | ~218 | 2.9× |
| Lv 80 | 652 | 27.9% | 904 | ~339 (WAW) | **2.7×** |
| Lv 80 | 652 | 27.9% | 904 | ~700 (ALEPH) | **1.3×** |

Mid-tier ratio drops from 3.3–3.5× to **2.6–2.9×**. ALEPH-tier matchup lands at **1.3×** — basically tied.

## Side-effects to watch

### PvP outgoing damage shifts up ~25%

The path's ATK/HP ratio shifts:
- Pre-Lever-4: Lv 80 ATK 420 / HP 815 = 0.515
- Post-Lever-4: Lv 80 ATK 420 / HP 652 = 0.644 (+25%)

PvP damage formula uses `damage *= target.maxHealth / max(owner.maxHealth, 1)`. Lower owner HP → smaller denominator → 25% higher PvP damage per ATK at any character level.

The `PvPScalingFactor` mechanism (already shipped) caps trace levels above target so the *shape* of the curve is unchanged — only the absolute baseline shifts up. Update `pvp_balance.md` worked-example numbers if applying.

### PvP TTK against paths is self-normalizing

The non-path → path damage formula in `species.dm` (`damage_amount *= path.maxHealth / max(attacker.maxHealth, 1)`) cancels with the lower path HP. PvP time-to-kill against path users stays exactly the same as with the 3-lever package alone.

### Mob-vs-path PvE durability drops further

PvE incoming damage doesn't have HP-ratio scaling — only DEF DR. With lower HP, mob hits chew through paths faster:

```
PvE TTK ≈ HP / (mob_force × (1 - DR))
        = 652 / (mob_force × 0.721)   [Lv 80, 2+4 levers]
        = 905 / mob_force

  vs. Lever 2 only:
        = 815 / (mob_force × 0.721)
        = 1131 / mob_force
```

20% less time before death from mob attacks. Acceptable as the entire intent of the lever is to bring path durability closer to ALEPH-agent levels.

### Ability HP-scaling

Several path abilities scale off `path.HP`:
- **Abundance Skill / Ult heals** — `instant_amount = max_hp × instant_hp_pct + flat`. Lower max_hp → smaller heals.
- **Preservation Shield** — flat + DEF%, not HP%. Unaffected.
- **Preservation Ult** — ATK + DEF based, not HP. Unaffected.

Abundance heals drop ~20% at Lv 80. May warrant a small `instant_hp_pct` / `hot_hp_pct` bump to compensate; flag for the same playtest pass.

## When to apply

Defer until after the 3-lever package is shipped and tested in-game across at least:
- A Lv 1 newly-spawned path holder
- A Lv 27 / Dawn-tier sweep
- A Lv 54 / Noon-tier sweep
- A Lv 80 / Dusk + Midnight sweep

If at Lv 54 / 80 against Noon / Dusk content the path still feels too tanky relative to a tier-matched agent, fold this lever in.

## Files to modify (when applied)

- `lobotomy-corp13\ModularLobotomy\enders_gimmicks\paths\paths_destruction.dm` — HP column only
- `lobotomy-corp13\ModularLobotomy\enders_gimmicks\paths\paths_hunt.dm` — HP column only
- `lobotomy-corp13\ModularLobotomy\enders_gimmicks\paths\paths_erudition.dm` — HP column only
- `lobotomy-corp13\ModularLobotomy\enders_gimmicks\paths\paths_nihility.dm` — HP column only
- `lobotomy-corp13\ModularLobotomy\enders_gimmicks\paths\paths_harmony.dm` — HP column only
- `lobotomy-corp13\ModularLobotomy\enders_gimmicks\paths\paths_preservation.dm` — HP column only
- `lobotomy-corp13\ModularLobotomy\enders_gimmicks\paths\paths_abundance.dm` — HP column only (consider bumping heal scaling to compensate)
- `lobotomy-corp13\ModularLobotomy\enders_gimmicks\paths\plans\pvp_balance.md` — re-document new PvP baseline numbers (+25% per-hit)
