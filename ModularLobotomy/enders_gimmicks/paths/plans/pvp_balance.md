# PvP Balance — Path Users vs Non-Path Humans

## System
Bidirectional linear HP-ratio scaling + armor average.

### Outgoing Path Damage vs Humans (`deal_path_damage` in `_path_datum.dm`)
```
damage *= target.maxHealth / max(owner.maxHealth, 1)
damage *= (100 - avg_armor) / 100
```
- Armor average: sum all 4 armor values on target's EGO suit, divide by 4

### Incoming Human Damage to Path Users (`species.dm apply_damage`)
```
damage_amount *= path_user.maxHealth / max(attacker.maxHealth, 1)
```
- Applied before armor/DEF resist calculations
- Only triggers when attacker is human AND target has a path

### Does NOT affect:
- Path vs mobs (PvE unchanged)
- Mob vs path user (only human attackers trigger boost)
- Path vs path (ratio = 1.0, no change)

## Design Intent
- **Capo wins sustained DPS** due to continuous swinging vs turn-limited path attacks
- **Path user can win with good ability usage** (Skill/Ult burst)
- **No one-shots** — path user needs 6+ hits to kill a well-armored human
- **Low-level path users lose** to geared enemies
- **2-3 humans can overwhelm** a path user
- Path users are "extraordinary" but not invincible

## Reference Matchups (Destruction Path)

### Lv67 Path vs East Capo (100 stats, 200 HP, podao force 60, armor avg 55)
- **Path → Capo**: 33 dmg/full hit, 6 full hits to kill, ~30s with turn system
- **Capo → Path**: 133 dmg/hit, 8 hits to kill, ~20s
- **Winner**: Capo wins sustained, Path wins with burst abilities

### All Matchups (realistic PvP, 1 hit per 2.5s)

| Matchup | Path dmg/hit | Path hits to kill | Enemy dmg/hit | Enemy hits to kill |
|---------|-------------|-------------------|--------------|-------------------|
| Lv40 vs Little Brother (60 stats, 160 HP, 34 force, 22.5 armor) | 41 | 4 | 73 | 8 |
| Lv54 vs East Soldato (80 stats, 180 HP, 60 force, 35 armor) | 43 | 4 | 125 | 6 |
| Lv54 vs Younger Brother (80 stats, 180 HP, 49 force, 32.5 armor) | 45 | 4 | 102 | 7 |
| Lv67 vs East Capo (100 stats, 200 HP, 60 force, 55 armor) | 33 | 6 | 133 | 8 |
| Lv67 vs Big Brother (150 stats, 300 HP, 63 force, 52.5 armor) | 52 | 6 | 93 | 11 |

### Key: Turn System Matters
- Path users only get 1 full-power basic attack per 5s turn
- Follow-up attacks in same turn deal 10% damage
- Skill costs AP + turn, Ult costs full energy
- Non-path users swing continuously (~1 hit per 2.5s in real PvP)
- Effective path DPS = ~1 meaningful hit per 5 seconds
- Non-path DPS = ~1 hit per 2.5 seconds

### Role Balance Tiers
- **Grunts** (Little Brother, 60 stats): Path user wins but takes hits
- **Mid-tier** (Soldato/Younger Brother, 80 stats): Competitive fight
- **Leaders** (East Capo, 100 stats): Very close, Capo has DPS advantage
- **Bosses** (Big Brother, 150+ stats): Path user needs burst to win
