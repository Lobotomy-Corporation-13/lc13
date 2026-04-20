# Middle Nursefather — Ex-Great Brother

## Lore Summary
The Middle Nursefather is a former Great Brother of the Middle who was demoted after suspicion arose around how he acquired Laevateinn, a burning Relic sword. He is a bulky man with dark skin, short white hair, blunt bangs, thick gold-bridged sunglasses, and a white suit over a black dress shirt (unbuttoned, revealing a chest scar). His body is covered in enhancement tattoos. He is missing his right arm. He wears a massive Middle-pattern coat over his shoulders and keeps a Book of Vengeance on his left hip. His right leg shifts into a claw via tattoos, though his primary weapon is Laevateinn — an oversized metallic sword bound by three layers of chain seals.

Personality: Boisterous, toy-obsessed, short attention span, deeply selfish hedonist who superficially plays the doting father figure. Brutal and capable in combat despite his immaturity.

---

## Stats & Role Identity

- **Fortitude:** 500
- **Prudence:** 500
- **Temperance:** 100
- **Justice:** 100
- **Core Identity:** Tankiest nursefather. Highest HP pool. Weapon starts weak but scales as HP drops.

---

## Weapon: Laevateinn (Sealed Relic Sword)

### Icon Files
- `icons/obj/spider_house/middle/laevateinn_icon.dmi` (inventory/ground)
- `icons/obj/spider_house/middle/laevateinn_left.dmi` (held left)
- `icons/obj/spider_house/middle/laevateinn_right.dmi` (held right)
- `icons/obj/spider_house/middle/laevateinn_worn.dmi` (worn on back)

### Icon States (progressive unseal)
1. `laevateinn_fullseal` — All 3 seals intact (starting state)
2. `laevateinn_unseal1` — 2 seals remaining (75% HP threshold)
3. `laevateinn_unseal2` — 1 seal remaining (50% HP threshold)
4. `laevateinn_fullpower` — Fully unsealed (25% HP threshold)

### Seal Mechanic
Each time the Ex-Great Brother drops below a 25% HP threshold (75%, 50%, 25%), an unseal cutscene triggers:

**During Cutscene:**
- All incoming damage is reduced to 1
- All debuff/status damage is reduced to 0
- Brief cinematic effect (screen flash, sound, icon update)

**After Cutscene:**
- A random adjacent tile gets a 1x1 warning effect for 1.5 seconds
- A seal structure lands on that tile (becomes a density-blocking structure)
- Debug sprite: `"uzi9mm-0"` from `icons/obj/ammo.dmi`

### Damage Scaling

| Stage | Seal State | Base Damage | Burn Bypass % | Notes |
|-------|-----------|-------------|---------------|-------|
| 1 | Full Seal | ~40% of target DPS | 0% | Very weak, all physical |
| 2 | Unseal 1 | ~60% of target DPS | 25% burn bypass | Starting to heat up |
| 3 | Unseal 2 | ~85% of target DPS | 50% burn bypass | Yellow light aura, inflicts Overheat to nearby living mobs (self gets 50% less) |
| 4 | Full Power | 100% target DPS | 100% burn bypass (pure burn) | Brighter light, increased Overheat output |

"Target DPS" = equivalent damage output of other nursefather weapons at 500 fort.

### Overheat Aura (Stage 3+)
- Applies Overheat status to all living mobs within range (TBD tiles)
- Self receives 50% less Overheat stacks
- Stage 4: increased Overheat application rate, brighter yellow light

### Light Emission
- Stage 3 (Unseal 2): Yellow light, moderate radius
- Stage 4 (Full Power): Brighter yellow light, larger radius

---

## Armor: Middle Coat

### Icon Files
- `icons/obj/spider_house/middle/middle_spider_worn.dmi` (worn)
- `icons/obj/spider_house/middle/middle_spider_icon.dmi` (inventory/ground)

### Icon States
- `middlefather_outfit` — main armor sprite
- `middlefather_cloak` — cape overlay

---

## Accessories

### Book of Vengeance
- Icon state: `middlefather_vengeance`
- Flavor item / potential mechanic hook later

### Sunglasses
- Icon state: `middlefather_sunglasses`
- Worn on eyes slot

---

## Physical Appearance (Coded)

- **Missing right arm** — right arm bodypart removed on spawn
- **White gloves** — worn on hands slot

---

## Outfit Summary

| Slot | Item |
|------|------|
| Suit | Middle Coat (middlefather_outfit + middlefather_cloak cape) |
| Eyes | Gold-bridge sunglasses (middlefather_sunglasses) |
| Gloves | White gloves |
| Back | Laevateinn (worn on back, laevateinn_worn) |
| Belt/Hip | Book of Vengeance (middlefather_vengeance) |
| R_arm | MISSING (removed on spawn) |

---

## Equip Order (after_spawn / debug tool)

### Constraints
1. Missing right arm — only left hand available for holding
2. EGO gear has 7-second equip delay normally — must bypass for spawn (`equip_delay_self = 0` override or `special` flag)
3. Sword on back requires EGO gear in suit slot first — it uses the suit's `s_store` (allowed storage) slot
4. Outfit datum can auto-equip slots, but suit slot EGO has delay issues

### Proposed Equip Sequence
1. **Remove right arm** — `H.get_bodypart(BODY_ZONE_R_ARM)` → `qdel()` or `drop_limb()`
2. **Equip base outfit via datum** (uniform, shoes, ID, belt, glasses, gloves):
   - `uniform` = charcoal suit / black dress shirt
   - `shoes` = laceup shoes
   - `glasses` = middlefather sunglasses (custom `/obj/item/clothing/glasses`)
   - `gloves` = white gloves (`/obj/item/clothing/gloves/color/white`)
   - `id` = silver/plastic ID
   - `belt` = PDA
   - `l_pocket` = Book of Vengeance (custom item)
   - `r_pocket` = apprentice recruitment scroll
3. **Force-equip EGO armor to suit slot** — bypass equip delay by calling `H.equip_to_slot_or_del(armor, ITEM_SLOT_OCLOTHING)` or setting `equip_delay_self = 0` on this specific armor subtype
4. **Place Laevateinn in suit storage** — `H.s_store = sword` or `armor.attackby(sword, H)` to store it, making it display on back
5. **Grant nursefather components** (passive + music)

### Alternative: No equip delay on this armor
Override `equip_delay_self = 0` on the Middle armor subtype since it's a role spawn, not player-equipped mid-round. This lets the outfit datum handle it cleanly:
- `suit` = Middle Coat in the outfit datum
- Then after outfit equip, place sword in s_store


---

## Nursefather Passive Override

The Middle Nursefather uses a modified passive component:
- **No dodge** — no guaranteed evade, no 50% random dodge
- **2.5% clone damage** instead of the standard 5%

Implementation: Subtype `/datum/component/nursefather_passive/middle` that overrides `on_damage_taken()` to skip all dodge logic and use `damage * 0.025` for clone damage.

---

## Combo System

All combos initiate a cutscene duel (using `/datum/component/cutscene_duel` pattern from `_cutscene_duel.dm`):
- Both the Ex-Great Brother and the target are immobilized during the combo
- Outside damage to either is denied (only the Ex-Great Brother can damage the target)
- Debuff/status damage to both is reduced to 0 during the combo
- Once triggered, the combo plays out fully — no additional player input needed

### Wall-Breaking Knockback
Combos with heavy knockback (Combo 1 finisher, Combo 5 finisher) can send the target through walls:
- Target is launched in the direction of the attack
- If a tile has `/turf/closed` (but NOT `/turf/closed/indestructible/rock` or space), the wall breaks
- Broken wall becomes a `/obj/structure/wall_rubble` (passable, records original wall type)
- After 2 minutes, rubble attempts self-repair if no mobs can see it
- If someone is watching, retry in 1 minute
- Target keeps traveling until hitting an indestructible wall, space border, or running out of knockback tiles

---

## Core Mechanic: The Middle - Grudge

A stacking buff on the Middle Nursefather that fuels his entire kit.

### Gaining Grudge
- **Getting hit:** Each time the Middle Nursefather takes damage from a living mob, gain Grudge stacks:
  - Damage < 20: gain 1 stack
  - Damage 20-49: gain 2 stacks
  - Damage 50-99: gain 3 stacks
  - Damage 100+: gain 5 stacks
- **Punching:** Each unarmed hit on a target grants 1 Grudge stack
- **Max stacks:** 20

### Spending Grudge
- **Combo attacks:** Consuming Grudge amplifies combo damage (bonus damage = Grudge stacks * multiplier)
- **Sword attacks:** Each Laevateinn hit consumes 1 Grudge stack for bonus damage
- **Grudge Dash:** Ranged gap-closer costs 5 Grudge (see below)

### Implementation
```dm
var/grudge_stacks = 0
var/max_grudge = 20
```
Use a HUD alert icon showing current stack count. Register `COMSIG_MOB_APPLY_DAMGE` on the owner to gain stacks when hit.

---

## Unseal Healthgates

The Middle Nursefather has HP thresholds at 75%, 50%, and 25% of max HP. When damage would reduce his health past a gate that hasn't been triggered yet, the damage is **capped at that gate** (he lands exactly on the threshold, excess damage is lost).

### How It Works
Register on `COMSIG_MOB_APPLY_DAMGE`. Before damage is applied:
1. Calculate what HP would be after damage: `projected_hp = owner.health - damage`
2. Find the next untriggered gate below current HP
3. If `projected_hp` would skip past that gate, reduce damage so HP lands exactly on the gate
4. Trigger the unseal cutscene for that gate
5. The next hit can then push past into the next segment normally

### Example
The Middle Nursefather has 500 max HP (from 500 Fort). Gates are at 375, 250, 125.
- At 400 HP, takes 100 damage → projected 300, would skip past 375 gate → damage reduced to 25, HP = 375, unseal 1 triggers
- Next hit at 375 HP, takes 50 damage → projected 325, no gate between 375 and 250 → full 50 damage, HP = 325
- At 260 HP, takes 80 damage → projected 180, would skip past 250 gate → damage reduced to 10, HP = 250, unseal 2 triggers

### Implementation
```dm
var/list/unseal_gates = list() // populated on spawn: list(0.75, 0.5, 0.25) * maxHealth
var/list/gates_triggered = list(FALSE, FALSE, FALSE)

/datum/component/laevateinn_seal/proc/on_damage_taken(datum/source, damage, damagetype, def_zone, attack_source)
	SIGNAL_HANDLER
	var/mob/living/owner = parent
	var/projected = owner.health - damage
	for(var/i in 1 to 3)
		if(gates_triggered[i])
			continue
		var/gate_hp = unseal_gates[i]
		if(owner.health > gate_hp && projected < gate_hp)
			// Cap damage at the gate
			var/capped_damage = owner.health - gate_hp
			// Modify the damage argument (need to use COMPONENT_MOB_OVERRIDE_DAMAGE or similar)
			gates_triggered[i] = TRUE
			INVOKE_ASYNC(src, PROC_REF(trigger_unseal), i)
			break
```

---

## Grabs on Simple Mobs

Normal BYOND grabs don't work on `/mob/living/simple_animal`. The Middle Nursefather needs a custom grab system that works on both humans and simple mobs.

### Approach: Virtual Grab (No BYOND Grab)

Don't use BYOND's built-in grab system at all. Instead, track the grab as a **variable on the component/weapon**:

```dm
var/mob/living/grabbed_target = null
var/grab_active = FALSE
```

### How It Works

1. **Initiating a grab** (on punch of Weakened target, or Grudge Dash on Weakened target):
   - Set `grabbed_target = target`
   - Set `grab_active = TRUE`
   - Immobilize target for grab duration (use `target.Immobilize()` — works on simple mobs)
   - Register movement signal on user: if user moves more than 2 tiles from target, auto-release

2. **During grab:**
   - Target is immobilized but keeps their items
   - The Middle Nursefather can still attack (punches trigger combos)
   - Both move together if the Middle Nursefather moves (target is `forceMove()`d to stay adjacent)
   - Grab lasts max 5 seconds if no combo is triggered (auto-release with cooldown)

3. **Releasing grab:**
   - Set `grabbed_target = null`, `grab_active = FALSE`
   - Remove immobilize from target

4. **Combo consumption:**
   - When a combo triggers, it consumes the grab (sets `grab_active = FALSE`)
   - The combo itself handles immobilization via `cutscene_duel`

### Simple Mob Handling
`Immobilize()` does NOT work on simple mobs. Instead, use the same pattern as `thumb.dm` (line 1091-1094):
- Save their AI state: `saved_ai = target.AIStatus`
- Disable AI: `target.toggle_ai(AI_OFF)`
- Stop pathfinding: `target.Goto(get_turf(target))` + `target.patrol_reset()`
- On release: `target.toggle_ai(saved_ai)` to restore

```dm
var/mob/living/grabbed_target = null
var/grab_active = FALSE
var/saved_target_ai = null // stored AI state for simple mob grabs

/proc/initiate_grab(mob/living/target, mob/living/carbon/human/user)
	grabbed_target = target
	grab_active = TRUE

	if(istype(target, /mob/living/simple_animal/hostile))
		// Simple mobs: disable AI (Immobilize doesn't work on them)
		var/mob/living/simple_animal/hostile/SM = target
		saved_target_ai = SM.AIStatus
		SM.toggle_ai(AI_OFF)
		SM.Goto(get_turf(SM))
		SM.patrol_reset()
	else if(iscarbon(target))
		// Carbons: use real grab system, but skip weapon drop
		// 1. Start pulling (passive grab)
		user.start_pulling(target)
		// 2. Add TRAIT_YOURFAULT_YOURPROBLEM temporarily to prevent drop_all_held_items()
		ADD_TRAIT(target, TRAIT_MIDDLEFATHER_GRAB, "middlefather")
		// 3. Upgrade to aggressive via setGrabState (skips grippedby which has the do_mob delay)
		user.setGrabState(GRAB_AGGRESSIVE)
		user.set_pull_offsets(target, GRAB_AGGRESSIVE)
		// 4. Remove the trait after the grab state is set
		REMOVE_TRAIT(target, TRAIT_MIDDLEFATHER_GRAB, "middlefather")

	// Register cleanup signals
	RegisterSignal(target, COMSIG_LIVING_DEATH, PROC_REF(release_grab))
	RegisterSignal(target, COMSIG_PARENT_QDELETING, PROC_REF(release_grab))

	// Auto-release timer (5 seconds max if no combo triggered)
	addtimer(CALLBACK(src, PROC_REF(release_grab)), 5 SECONDS)

/proc/release_grab()
	if(!grabbed_target)
		return
	// Restore AI for simple mobs
	if(istype(grabbed_target, /mob/living/simple_animal/hostile))
		var/mob/living/simple_animal/hostile/SM = grabbed_target
		if(saved_target_ai != null)
			SM.toggle_ai(saved_target_ai)
			saved_target_ai = null
	else if(iscarbon(grabbed_target))
		// Release the real grab
		var/mob/living/carbon/human/user = parent // or however we ref the user
		if(user?.pulling == grabbed_target)
			user.stop_pulling()

	// Unregister signals
	UnregisterSignal(grabbed_target, COMSIG_LIVING_DEATH)
	UnregisterSignal(grabbed_target, COMSIG_PARENT_QDELETING)

	grabbed_target = null
	grab_active = FALSE
```

### Preventing Weapon Drop on Aggressive Grab

The problem: `grippedby()` in `living_defense.dm` line 170 calls `drop_all_held_items()` when upgrading to `GRAB_AGGRESSIVE`.

**Solution:** Add a new trait `TRAIT_MIDDLEFATHER_GRAB`. Override the weapon drop in `grippedby()` or — simpler — skip `grippedby()` entirely and use `setGrabState()` directly, which doesn't call `drop_all_held_items()`.

The code above uses the direct approach:
1. `user.start_pulling(target)` — initiates passive grab
2. `user.setGrabState(GRAB_AGGRESSIVE)` — jumps straight to aggressive without going through `grippedby()`
3. `user.set_pull_offsets(target, GRAB_AGGRESSIVE)` — positions them correctly

This completely bypasses the `drop_all_held_items()` call since we never go through the `grippedby()` upgrade path. No trait needed after all.

### Compatibility Notes
- `toggle_ai(AI_OFF)` + `Goto()` + `patrol_reset()` stops simple mobs from moving/attacking — proven pattern from thumb.dm flurry
- `forceMove()` works on all mobs for repositioning during grab
- `apply_damage()` works on simple mobs for combo damage
- `cutscene_duel` component registers on `COMSIG_MOB_APPLY_DAMGE` which fires for all living mobs

### Edge Cases
- **Target dies during grab:** Register `COMSIG_LIVING_DEATH` on target → `release_grab()`
- **Middle Nursefather dies during grab:** Cleanup in `Destroy()` or death signal → `release_grab()`
- **Target is deleted (qdel):** Register `COMSIG_PARENT_QDELETING` on target → `release_grab()`
- **Multiple Middle Nursefathers grabbing same target:** Check `grabbed_target` on target before initiating — deny if already grabbed
- **Mega-sized mobs (2x2+):** May want a size check to prevent grabbing megafauna bosses (check `mob_size >= MOB_SIZE_LARGE` to deny)

---

## Core Mechanic: Weakened State + Auto-Grab

### Punch → Weaken → Grab Flow
1. **Punch (unarmed hit):** Target gets a "Weakened" status for 6 seconds. the Middle Nursefather gains 1 Grudge.
2. **Second punch within 6 seconds on a Weakened target:** Automatically initiates an **aggressive grab** (target does NOT drop weapons). Target is now grabbed.
3. **While grabbed:** the Middle Nursefather can trigger combos based on conditions.

### Weakened Status
- `/datum/status_effect/middlefather_weakened`
- Duration: 6 seconds
- No gameplay effect on its own — purely a setup marker for the grab
- Visual: small stagger indicator on target

---

## Combo Trigger System

### Weapon States
Laevateinn can be in two states:
- **Sheathed** (stored in suit s_store) — the Middle Nursefather fights with fists/kicks (unarmed)
- **Drawn** (held in left hand) — the Middle Nursefather fights with the sword

Toggle via **pressing E** (equip to/from suit slot) or **attack_self()** on the weapon.

### Trigger Conditions

| Combo | Trigger | Weapon State | Additional Condition |
|-------|---------|-------------|---------------------|
| 1 — Chain Grapple | Punch target while grabbed | Sheathed | None |
| 2 — Stomping | Punch target while grabbed AND target <50% HP | Sheathed | 30s cooldown |
| 3 — Gut Ya Like a Fish | Draw sword (press E) while target is grabbed | Drawn | Seal stage 2+ |
| 4 — Gut Stab | attack_self() with sword while target is grabbed | Drawn | Seal stage 3+, 45s cooldown |
| 5 — Total Extermination | **Action button** (HUD) | Either (auto-draws) | Seal stage 4 (full unseal), 90s cooldown |

### Grudge Consumption on Combos
| Combo | Grudge Consumed | Bonus Effect |
|-------|----------------|-------------|
| 1 — Chain Grapple | All current stacks | +3 damage per stack consumed to finisher hit |
| 2 — Stomping | All current stacks | +2 damage per stack consumed, extra stomp per 5 stacks |
| 3 — Gut Ya Like a Fish | All current stacks | +3 BURN damage per stack consumed to fire slashes |
| 4 — Gut Stab | All current stacks | +4 damage per stack consumed to final twist |
| 5 — Total Extermination | All current stacks | +5 damage per stack consumed to overhead cleave |

### Combo Priority
If multiple combos could trigger (e.g., target is grabbed, <50% HP, seal 2+), priority goes to the **most specific** combo:
- Stomping beats Chain Grapple when target <50% HP
- Gut Ya Fish triggers when drawing sword, not punching
- Gut Stab triggers from attack_self(), distinct input

---

## Grudge Dash (afterattack)

When Laevateinn is **sheathed** (unarmed mode), clicking on a target **3+ tiles away** triggers a Grudge Dash:

### Conditions
- Target is 3-7 tiles away
- The Middle Nursefather has **5+ Grudge stacks**
- Not on cooldown (10s cooldown)

### Effect
1. Consume 5 Grudge stacks
2. The Middle Nursefather dashes to the target (pixel fade-out → forceMove → fade-in, with beam trail)
3. Delivers a flying punch on arrival
4. If target has the **Weakened** status, auto-grab them immediately (skipping the 2-punch requirement)
5. If target does NOT have Weakened, apply Weakened (next punch within 6s will grab)

### Implementation
```dm
// On the nursefather's unarmed attack handler (component or species override)
/proc/afterattack_unarmed(atom/target, mob/living/user, proximity_flag, click_parameters)
	if(!isliving(target))
		return
	var/mob/living/L = target
	var/dist = get_dist(user, L)
	if(dist < 3 || dist > 7)
		return
	if(grudge_stacks < 5)
		to_chat(user, span_warning("Not enough Grudge to dash! ([grudge_stacks]/5)"))
		return
	if(!COOLDOWN_FINISHED(src, grudge_dash_cd))
		return

	grudge_stacks -= 5
	COOLDOWN_START(src, grudge_dash_cd, 10 SECONDS)

	// Dash animation — smoke at origin, smoke trail on path
	var/turf/origin = get_turf(user)
	var/dash_dir = get_dir(user, L)
	var/obj/effect/temp_visual/dir_setting/smoke_afterdash/aftersmoke = new(origin, dash_dir)
	aftersmoke.color = "#D8B4FE"
	var/turf/current = origin
	for(var/i in 1 to get_dist(user, L) - 1)
		current = get_step(current, dash_dir)
		if(current)
			var/obj/effect/temp_visual/dir_setting/smoke_dash/trailsmoke = new(current, dash_dir)
			trailsmoke.color = "#D8B4FE"
	animate(user, alpha = 0, pixel_y = user.base_pixel_y + 16, time = 0.15 SECONDS)
	sleep(0.15 SECONDS)
	user.forceMove(get_step(L, get_dir(L, user))) // land adjacent to target
	user.pixel_y = user.base_pixel_y + 12
	animate(user, alpha = 255, pixel_y = user.base_pixel_y, time = 0.15 SECONDS, easing = BOUNCE_EASING)

	// Punch on arrival
	user.do_attack_animation(L)
	L.apply_damage(20, BRUTE)
	new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(L), dash_dir)
	playsound(L, 'sound/weapons/punch1.ogg', 55, TRUE)
	shake_camera(L, 2, 2)

	// Check weakened → auto-grab
	if(L.has_status_effect(/datum/status_effect/middlefather_weakened))
		new /obj/effect/temp_visual/dir_setting/laevateinn_blast(get_turf(L))
		initiate_grab(L, user) // aggressive grab, no weapon drop
	else
		new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(L), dash_dir)
		L.apply_status_effect(/datum/status_effect/middlefather_weakened)
```

### Tracking Variables (on weapon datum / component)
```dm
var/grudge_stacks = 0
var/max_grudge = 20
var/mob/living/grabbed_target    // Currently grabbed target (for combo checks)
COOLDOWN_DECLARE(combo2_cd)       // 30s cooldown for Stomping
COOLDOWN_DECLARE(combo4_cd)       // 45s cooldown for Gut Stab
COOLDOWN_DECLARE(combo5_cd)       // 90s cooldown for Total Extermination
COOLDOWN_DECLARE(grudge_dash_cd)  // 10s cooldown for Grudge Dash
```

---

## Visual Effects Catalog

### Custom Middle Effects (in `ModularLobotomy/lc13_effects.dm`)
| Effect | Path | Visual | Duration | Used For |
|--------|------|--------|----------|----------|
| Middle punch slash | `/obj/effect/temp_visual/dir_setting/middle_basic_slash` | Purple wide arc (48x48, 4-dir) | 50ds | Unarmed wide attacks, centered on user |
| Laevateinn slash | `/obj/effect/temp_visual/dir_setting/laevateinn_basic_slash` | Orange/fire wide arc (48x48, 4-dir) | 50ds | Sword wide attacks, centered on user |
| Middle slam | `/obj/effect/temp_visual/middle_slam` | Purple particles spreading (64x64, 1-dir) | 45ds | Ground slam AoE on target tile |
| Smoke dash trail | `/obj/effect/temp_visual/dir_setting/smoke_dash` | White smoke trail (64x64, 4-dir) | 80ds | Each tile crossed during dash |
| Smoke afterdash | `/obj/effect/temp_visual/dir_setting/smoke_afterdash` | White smoke cloud dissipating (64x64, 4-dir) | 75ds | Origin tile where dash started |
| Middle stab | `/obj/effect/temp_visual/dir_setting/middle_slash` | Purple pierce line (64x64, 4-dir) | 40ds | Precise stab effects |
| Laevateinn stab | `/obj/effect/temp_visual/dir_setting/laevateinn_stab` | Orange pierce line (64x64, 4-dir) | 40ds | Laevateinn stab/impale (Combo 4) |
| Middle blast | `/obj/effect/temp_visual/dir_setting/middle_blast` | Purple energy burst (64x64, 4-dir) | 40ds | Punch impact / Weakened application |
| Laevateinn blast | `/obj/effect/temp_visual/dir_setting/laevateinn_blast` | Orange energy burst (64x64, 4-dir) | 40ds | Grab initiation effect |

### HUD / Action Button Icons
| Element | Icon File | Icon State | Used For |
|---------|----------|-----------|----------|
| Combo 5 action button | `icons/obj/spider_house/middle/middle_spider_icon.dmi` | `"laevateinn"` | Total Extermination HUD action |
| Grudge buff alert | `icons/obj/spider_house/middle/middle_spider_icon.dmi` | `"middle_grudge"` | Grudge stack HUD alert icon |
| Grudge stacking 10x10 | `ModularLobotomy/_Lobotomyicons/tegu_effects10x10.dmi` | `"middle_grudge"` | Small stacking indicator on mob |

### Other Effects Used (Existing in Codebase)
| Effect | Path | Duration | Used For |
|--------|------|----------|----------|
| Fire burst | `/obj/effect/temp_visual/fire` | 10ds | Fire ground effects (Combo 3, 4, 5) |
| Quick fire | `/obj/effect/temp_visual/fire/fast` | 5ds | Rapid fire hits |
| Explosion | `/obj/effect/temp_visual/explosion` | 8ds | Combo finishers (96x96) |
| Kinetic blast | `/obj/effect/temp_visual/kinetic_blast` | 4ds | Knockback origin |
| Burn indicator | `/obj/effect/temp_visual/damage_effect/burn` | 8ds | Burn hit indicator |
| Beam/trail | `origin.Beam(dest, "1-full", time=N)` | variable | Dash trails |

### Status Effects (Existing in Codebase)
All use mob helper procs for clean application:

| Effect | Apply Proc | Path | Description |
|--------|-----------|------|-------------|
| Burn | `target.apply_lc_burn(stacks)` | `/datum/status_effect/stacking/lc_burn` | 1.5 burn dmg per stack every 5s, fire overlay at high stacks |
| Overheat | `target.apply_lc_overheat(stacks)` | `/datum/status_effect/stacking/lc_overheat` | True damage every 5s (stacks*4 on non-humans), max 50 stacks |
| Bleed | `target.apply_lc_bleed(stacks)` | `/datum/status_effect/stacking/lc_bleed` | Bleeds on movement |
| Tremor | `target.apply_lc_tremor(stacks, burst_threshold)` | `/datum/status_effect/stacking/lc_tremor` | Stacks → TremorBurst at threshold |
| Vengeance Mark | `target.apply_vengeance_mark(stacks)` | `/datum/status_effect/stacking/vengeance_mark` | Middle-specific! Max 20 stacks, decays after 2.5min. Middle weapons deal bonus damage based on stacks |
| Rupture | `target.apply_lc_rupture(stacks)` | rupture path | RED/BLACK trigger → BRUTE damage |
| Sinking | `target.apply_lc_sinking(stacks)` | sinking path | WHITE/PALE trigger → sanity damage |

**Note:** Vengeance Mark exists but is not used for now — may integrate later.

### Effects We'd Ideally Want (Custom — Need New Sprites)
| Desired Effect | Purpose | Workaround Using Existing |
|---------------|---------|--------------------------|
| Middle emblem sphere | Large purple/pink sphere around both (Combo 1) | Recolored `/obj/effect/temp_visual/explosion` with purple tint |
| Laevateinn fire trail | Burning sword slash arc (Combo 3, 4, 5) | `/obj/effect/temp_visual/fire` + `/obj/effect/temp_visual/dir_setting/slash` layered |
| Flower petal burst | Blue/orange petals during Gut Stab (Combo 4) | Recolored `/obj/effect/temp_visual/sparks` with blue/orange |
| Stomp crack ground | Ground cracking under stomps (Combo 2) | `/obj/effect/temp_visual/smash_effect` + `/obj/effect/temp_visual/kinetic_blast` |
| Full-screen fire flash | Screen-wide flame (Combo 5 finisher) | `shake_camera()` + orange screen flash overlay |
| Impaled sword overlay | Laevateinn stuck in target (Combo 4) | Overlay image on target mob during combo |

### Screen Effects
```dm
shake_camera(target, 2, 2)   // Light — per-hit shake
shake_camera(target, 2, 4)   // Medium — combo transition
shake_camera(target, 3, 5)   // Heavy — finisher hit
// For area shake (all nearby viewers):
for(var/mob/M in viewers(7, get_turf(user)))
    shake_camera(M, 3, 5)
```

---

### Combo 1 — "Don't Let Somethin' Like This Break Ya!" (Chain Grapple → Sword Sweep)

**Trigger:** 3rd consecutive unarmed hit on same target (weapon sheathed)

**Description:**
1. The Ex-Great Brother seizes the target and pulls them close
2. A purple energy burst erupts as they're locked in
3. The Ex-Great Brother punches the target, dealing blunt damage
4. He draws Laevateinn and performs a wide sweeping slash, causing Bleed
5. Follows up with a second heavy slash arc
6. Finishes with a devastating strike that sends the target flying (knockback)

**Placeholder Code:**
```dm
/obj/item/ego_weapon/city/laevateinn/proc/combo_chain_grapple(mob/living/target, mob/living/carbon/human/user)
	set waitfor = FALSE
	if(!target || !user || user.stat == DEAD)
		return

	// Lock both in cutscene
	target.AddComponent(/datum/component/cutscene_duel, user, 10 SECONDS)
	user.Immobilize(10 SECONDS)
	target.Immobilize(10 SECONDS)

	// Step 1: Grab and yank target close with pixel shift
	user.visible_message(span_danger("[user] seizes [target]!"))
	new /obj/effect/temp_visual/dir_setting/laevateinn_blast(get_turf(target))
	playsound(user, 'sound/weapons/punch1.ogg', 60, TRUE)
	// Target jolts toward user
	animate(target, pixel_x = target.base_pixel_x + (get_dir(target, user) & EAST ? 6 : -6), time = 0.2 SECONDS, easing = BACK_EASING)
	animate(pixel_x = target.base_pixel_x, time = 0.3 SECONDS, easing = QUAD_EASING)
	sleep(0.8 SECONDS)

	// Step 2: Purple blast on lockdown
	new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(target))
	// Target shakes in place from the bind pressure
	animate(target, pixel_x = target.base_pixel_x + 3, time = 0.05 SECONDS)
	animate(pixel_x = target.base_pixel_x - 3, time = 0.05 SECONDS)
	animate(pixel_x = target.base_pixel_x + 2, time = 0.05 SECONDS)
	animate(pixel_x = target.base_pixel_x - 2, time = 0.05 SECONDS)
	animate(pixel_x = target.base_pixel_x, time = 0.05 SECONDS)
	sleep(0.5 SECONDS)

	// Step 3: Punch — user lunges forward with pixel shift
	animate(user, pixel_x = user.base_pixel_x + (get_dir(user, target) & EAST ? 8 : -8), time = 0.1 SECONDS, easing = QUAD_EASING)
	user.do_attack_animation(target)
	target.apply_damage(30, BRUTE, pick(BODY_ZONES_MINUS_CHEST))
	new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(target))
	// Target recoils from punch
	animate(target, pixel_x = target.base_pixel_x + (get_dir(user, target) & EAST ? 4 : -4), time = 0.1 SECONDS, easing = QUAD_EASING)
	animate(target, pixel_x = target.base_pixel_x, time = 0.2 SECONDS, easing = QUAD_EASING)
	shake_camera(target, 2, 2)
	playsound(target, 'sound/weapons/punch1.ogg', 50, TRUE)
	animate(user, pixel_x = user.base_pixel_x, time = 0.2 SECONDS, easing = QUAD_EASING)
	sleep(0.5 SECONDS)

	// Step 4: Draw Laevateinn + first slash — wide arc centered on user
	animate(user, transform = matrix(45, MATRIX_ROTATE), time = 0.15 SECONDS, easing = QUAD_EASING)
	animate(transform = null, time = 0.15 SECONDS, easing = QUAD_EASING)
	user.do_attack_animation(target)
	new /obj/effect/temp_visual/dir_setting/laevateinn_basic_slash(get_turf(user), user.dir)
	target.apply_damage(40, BRUTE)
	target.apply_lc_bleed(5)
	// Target knocked sideways
	animate(target, pixel_x = target.base_pixel_x + 6, pixel_y = target.base_pixel_y - 3, time = 0.1 SECONDS, easing = QUAD_EASING)
	animate(pixel_x = target.base_pixel_x, pixel_y = target.base_pixel_y, time = 0.2 SECONDS, easing = QUAD_EASING)
	shake_camera(target, 2, 3)
	playsound(target, 'sound/weapons/bladeslice.ogg', 60, TRUE)
	sleep(0.4 SECONDS)

	// Step 5: Second slash arc — reverse spin, wide arc centered on user
	animate(user, transform = matrix(-60, MATRIX_ROTATE), time = 0.15 SECONDS, easing = QUAD_EASING)
	animate(transform = null, time = 0.15 SECONDS, easing = QUAD_EASING)
	user.do_attack_animation(target)
	new /obj/effect/temp_visual/dir_setting/laevateinn_basic_slash(get_turf(user), turn(user.dir, 180))
	target.apply_damage(45, BRUTE)
	// Target flinches other direction
	animate(target, pixel_x = target.base_pixel_x - 6, pixel_y = target.base_pixel_y - 2, time = 0.1 SECONDS, easing = QUAD_EASING)
	animate(pixel_x = target.base_pixel_x, pixel_y = target.base_pixel_y, time = 0.2 SECONDS, easing = QUAD_EASING)
	shake_camera(target, 2, 3)
	playsound(target, 'sound/weapons/bladeslice.ogg', 60, TRUE)
	sleep(0.5 SECONDS)

	// Step 6: Finisher strike — user spins full 360 into the hit
	user.SpinAnimation(3, 1)
	sleep(0.2 SECONDS)
	user.visible_message(span_userdanger("[user] sends [target] flying!"))
	target.apply_damage(50, BRUTE)
	new /obj/effect/temp_visual/kinetic_blast(get_turf(target))
	shake_camera(target, 3, 5)
	playsound(target, 'sound/weapons/punch1.ogg', 70, TRUE)

	// Wall-breaking knockback
	wall_breaking_knockback(target, user, get_dir(user, target), 5)

	// Reset pixels
	animate(user, pixel_x = user.base_pixel_x, pixel_y = user.base_pixel_y, transform = null, time = 0.1 SECONDS)
	user.SetImmobilized(0)
```

**Statuses Applied:** Bleed

**Has Knockback:** Yes (finisher) — can break walls

---

### Combo 2 — "Stomping!" (Ground Stomp Beatdown)

**Trigger:** Unarmed hit on target at <50% HP (weapon sheathed), 30s cooldown

**Description:**
1. The Ex-Great Brother stomps on a downed/grabbed target repeatedly
2. Multiple rapid stomp hits with impact sparks and ground cracks
3. AoE shockwave on 3rd stomp, hitting nearby mobs
4. Final stomp launches the target with Bleed applied

**Placeholder Code:**
```dm
/obj/item/ego_weapon/city/laevateinn/proc/combo_stomping(mob/living/target, mob/living/carbon/human/user)
	set waitfor = FALSE
	if(!target || !user || user.stat == DEAD)
		return

	target.AddComponent(/datum/component/cutscene_duel, user, 8 SECONDS)
	user.Immobilize(8 SECONDS)
	target.Immobilize(8 SECONDS)
	target.Knockdown(8 SECONDS)

	user.visible_message(span_danger("[user] pins [target] underfoot!"))
	playsound(user, 'sound/weapons/punch1.ogg', 50, TRUE)
	sleep(0.3 SECONDS)

	// Stomp loop
	for(var/i in 1 to 5)
		// User stomps down — pixel shift foot down
		animate(user, pixel_y = user.base_pixel_y + 4, time = 0.1 SECONDS, easing = QUAD_EASING)
		animate(pixel_y = user.base_pixel_y, time = 0.1 SECONDS, easing = BOUNCE_EASING)
		user.do_attack_animation(target)
		target.apply_damage(25, BRUTE, BODY_ZONE_CHEST)
		new /obj/effect/temp_visual/middle_slam(get_turf(target))
		new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(target))
		// Target jolts from each stomp
		animate(target, pixel_x = target.base_pixel_x + rand(-4, 4), pixel_y = target.base_pixel_y - 2, time = 0.05 SECONDS)
		animate(pixel_x = target.base_pixel_x, pixel_y = target.base_pixel_y, time = 0.15 SECONDS, easing = QUAD_EASING)
		shake_camera(target, 2, 2)
		playsound(target, 'sound/weapons/punch[rand(1,4)].ogg', 55, TRUE)

		// AoE shockwave on 3rd stomp
		if(i == 3)
			new /obj/effect/temp_visual/middle_slam(get_turf(user))
			for(var/mob/living/L in orange(1, user))
				if(L == target)
					continue
				L.apply_damage(15, BRUTE)
				new /obj/effect/temp_visual/sparks(get_turf(L))
				animate(L, pixel_x = L.base_pixel_x + rand(-4, 4), time = 0.1 SECONDS)
				animate(pixel_x = L.base_pixel_x, time = 0.2 SECONDS)
			playsound(user, 'sound/weapons/punch1.ogg', 50, TRUE)
		sleep(0.4 SECONDS)

	// Final stomp — user leaps up then slams down
	animate(user, pixel_y = user.base_pixel_y + 16, time = 0.2 SECONDS, easing = QUAD_EASING)
	sleep(0.2 SECONDS)
	animate(user, pixel_y = user.base_pixel_y, time = 0.1 SECONDS, easing = BOUNCE_EASING)
	user.visible_message(span_userdanger("[user] delivers a devastating final stomp!"))
	target.apply_damage(35, BRUTE)
	target.apply_lc_bleed(5)
	new /obj/effect/temp_visual/middle_slam(get_turf(target))
	shake_camera(target, 3, 4)

	// Moderate knockback (no wall break)
	target.throw_at(get_ranged_target_turf_direct(user, target, 3), 3, 4, user, TRUE)

	// Reset pixels
	animate(user, pixel_x = user.base_pixel_x, pixel_y = user.base_pixel_y, transform = null, time = 0.1 SECONDS)
	user.SetImmobilized(0)
	COOLDOWN_START(src, combo2_cd, 30 SECONDS)
```

**Statuses Applied:** Bleed

**Has Knockback:** Moderate (finisher only, no wall break)

---

### Combo 3 — "I'll Gut Ya Like a Fish" (Laevateinn Fire Combo)

**Trigger:** 3rd consecutive sword hit on same target (weapon drawn), seal stage 2+

**Description:**
1. The Ex-Great Brother grabs the target and shouts "TAAAAKE THAAAAAT!"
2. Rapid punches while flames erupt around both combatants
3. Ground catches fire, flames spread around the arena
4. Overhead sword swing — Laevateinn ignites fully
5. Multiple rapid slash hits through the flames with Burn + Burn Count applied
6. Finishes with a massive burning overhead cleave, huge fire explosion effect

**Placeholder Code:**
```dm
/obj/item/ego_weapon/city/laevateinn/proc/combo_gut_fish(mob/living/target, mob/living/carbon/human/user)
	set waitfor = FALSE
	if(!target || !user || user.stat == DEAD)
		return

	target.AddComponent(/datum/component/cutscene_duel, user, 10 SECONDS)
	user.Immobilize(10 SECONDS)
	target.Immobilize(10 SECONDS)

	// Step 1: Grab + shout
	user.say("TAAAAKE THAAAAAT!")
	playsound(user, 'sound/weapons/punch1.ogg', 50, TRUE)
	sleep(0.3 SECONDS)

	// Step 2: Rapid punches — alternating left/right pixel lunges
	for(var/i in 1 to 3)
		var/punch_offset = (i % 2 == 1) ? 6 : -6
		animate(user, pixel_x = user.base_pixel_x + punch_offset, time = 0.08 SECONDS, easing = QUAD_EASING)
		user.do_attack_animation(target)
		target.apply_damage(20, BRUTE)
		// Target recoils opposite direction
		animate(target, pixel_x = target.base_pixel_x - punch_offset, time = 0.08 SECONDS, easing = QUAD_EASING)
		animate(pixel_x = target.base_pixel_x, time = 0.15 SECONDS, easing = QUAD_EASING)
		new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(target))
		shake_camera(target, 1, 2)
		playsound(target, 'sound/weapons/punch[rand(1,4)].ogg', 50, TRUE)
		animate(user, pixel_x = user.base_pixel_x, time = 0.1 SECONDS, easing = QUAD_EASING)
		sleep(0.3 SECONDS)

	// Step 3: Ground fire (cosmetic)
	for(var/turf/T in orange(2, user))
		if(prob(40))
			new /obj/effect/temp_visual/fire(T)
	sleep(0.5 SECONDS)

	// Step 4-5: Burning slashes — user rotates with each swing, escalating
	for(var/i in 1 to 4)
		var/rotation = (i % 2 == 1) ? 45 + (i * 10) : -(45 + (i * 10))
		animate(user, transform = matrix(rotation, MATRIX_ROTATE), time = 0.1 SECONDS, easing = QUAD_EASING)
		animate(transform = null, time = 0.15 SECONDS, easing = QUAD_EASING)
		user.do_attack_animation(target)
		new /obj/effect/temp_visual/dir_setting/laevateinn_basic_slash(get_turf(user), user.dir)
		new /obj/effect/temp_visual/fire/fast(get_turf(target))
		target.apply_damage(30, BURN)
		target.apply_lc_overheat(3)
		// Target staggers from each slash
		animate(target, pixel_y = target.base_pixel_y - 3, pixel_x = target.base_pixel_x + rand(-3, 3), time = 0.08 SECONDS)
		animate(pixel_y = target.base_pixel_y, pixel_x = target.base_pixel_x, time = 0.15 SECONDS, easing = QUAD_EASING)
		shake_camera(target, 2, 3)
		playsound(target, 'sound/weapons/bladeslice.ogg', 55, TRUE)
		sleep(0.35 SECONDS)

	// Step 6: Fire explosion finisher — user leaps up + overhead cleave
	animate(user, pixel_y = user.base_pixel_y + 20, time = 0.2 SECONDS, easing = QUAD_EASING)
	sleep(0.2 SECONDS)
	// Slam down with 180 degree rotation
	animate(user, pixel_y = user.base_pixel_y, transform = matrix(180, MATRIX_ROTATE), time = 0.15 SECONDS, easing = BOUNCE_EASING)
	animate(transform = null, time = 0.1 SECONDS)
	user.visible_message(span_userdanger("[user] brings Laevateinn down in a blazing cleave!"))
	target.apply_damage(60, BURN)
	target.apply_lc_overheat(8)
	// Target slams into ground
	animate(target, pixel_y = target.base_pixel_y - 6, time = 0.05 SECONDS)
	animate(pixel_y = target.base_pixel_y, time = 0.3 SECONDS, easing = BOUNCE_EASING)
	new /obj/effect/temp_visual/explosion(get_turf(target))
	for(var/turf/T in orange(2, target))
		new /obj/effect/temp_visual/fire(T)
	for(var/mob/M in viewers(7, get_turf(user)))
		shake_camera(M, 3, 5)
	playsound(target, 'sound/effects/explosion1.ogg', 60, TRUE)

	// Reset pixels
	animate(user, pixel_x = user.base_pixel_x, pixel_y = user.base_pixel_y, transform = null, time = 0.1 SECONDS)
	user.SetImmobilized(0)
```

**Statuses Applied:** Overheat

**Has Knockback:** No — target stays in place, fire everywhere

---

### Combo 4 — "Gut Stab [Laevateinn]" (Repeated Sword Impalement)

**Trigger:** attack_self() while adjacent to last-hit target (weapon drawn), seal stage 3+, 45s cooldown

**Description:**
1. The Ex-Great Brother impales the target through the gut with Laevateinn
2. "Be warned, it's gonna be hot." — the blade heats up while embedded
3. Repeated stab-twist motions (6-8 stabs total)
4. Each stab applies Burn stacks, fire and flower-petal effects swirl around
5. Blue/orange flower motifs appear as damage ramps up
6. Final twist + pull-out with burning AoE explosion, massive damage spike
8. "Hot as hell!" on the finisher

**Placeholder Code:**
```dm
/obj/item/ego_weapon/city/laevateinn/proc/combo_gut_stab(mob/living/target, mob/living/carbon/human/user)
	set waitfor = FALSE
	if(!target || !user || user.stat == DEAD)
		return

	target.AddComponent(/datum/component/cutscene_duel, user, 12 SECONDS)
	user.Immobilize(12 SECONDS)
	target.Immobilize(12 SECONDS)

	// Step 1: Impale — position user slightly to the left of target
	var/attack_dir = get_dir(user, target)
	user.setDir(attack_dir)
	// Shift user slightly left of target for side-on stabbing angle
	animate(user, pixel_x = user.base_pixel_x - 6, time = 0.1 SECONDS, easing = QUAD_EASING)
	user.do_attack_animation(target)
	user.visible_message(span_danger("[user] drives Laevateinn through [target]'s gut!"))
	target.apply_damage(25, BRUTE, BODY_ZONE_CHEST)
	new /obj/effect/temp_visual/dir_setting/laevateinn_stab(get_turf(target), EAST)
	// Add sword overlay on target
	var/mutable_appearance/impale_overlay = mutable_appearance(icon, icon_state, ABOVE_MOB_LAYER)
	impale_overlay.pixel_x = 8
	target.add_overlay(impale_overlay)
	playsound(target, 'sound/weapons/bladeslice.ogg', 65, TRUE)
	shake_camera(target, 2, 3)
	sleep(0.6 SECONDS)

	// Step 2: Warning
	user.say("Be warned, it's gonna be hot.")
	sleep(0.8 SECONDS)

	// Step 3-4: Stab loop (8 stabs) — user twists with each stab, target shudders
	for(var/i in 1 to 8)
		// User twists blade — small rotation back and forth, escalating
		var/twist_angle = 10 + (i * 3)
		animate(user, transform = matrix(twist_angle, MATRIX_ROTATE), time = 0.08 SECONDS, easing = QUAD_EASING)
		animate(transform = matrix(-twist_angle * 0.5, MATRIX_ROTATE), time = 0.08 SECONDS, easing = QUAD_EASING)
		animate(transform = null, time = 0.1 SECONDS)
		// User pushes forward into target with each stab
		animate(user, pixel_x = user.base_pixel_x + (get_dir(user, target) & EAST ? 4 : -4), time = 0.08 SECONDS, easing = QUAD_EASING)
		animate(pixel_x = user.base_pixel_x, time = 0.15 SECONDS, easing = QUAD_EASING)
		user.do_attack_animation(target)
		var/stab_damage = 15 + (i * 3)
		target.apply_damage(stab_damage, BURN)
		target.apply_lc_overheat(2)
		new /obj/effect/temp_visual/dir_setting/laevateinn_stab(get_turf(target), EAST)
		new /obj/effect/temp_visual/fire/fast(get_turf(target))
		// Target shudders from each stab — escalating shake
		animate(target, pixel_x = target.base_pixel_x + rand(-2 - i, 2 + i), pixel_y = target.base_pixel_y + rand(-1, 1), time = 0.05 SECONDS)
		animate(pixel_x = target.base_pixel_x, pixel_y = target.base_pixel_y, time = 0.1 SECONDS, easing = QUAD_EASING)
		shake_camera(target, 1, 2)
		playsound(target, 'sound/weapons/bladeslice.ogg', 45, TRUE)

		// Step 5: Flower effects on later stabs
		if(i >= 5)
			var/obj/effect/temp_visual/sparks/petal = new(get_turf(target))
			petal.color = pick("#4169E1", "#FF8C00")
		sleep(0.4 SECONDS)

	// Step 6: Final twist — full spin rip-out + explosion
	user.SpinAnimation(3, 1)
	sleep(0.2 SECONDS)
	user.visible_message(span_userdanger("[user] twists Laevateinn and rips it free in a burst of flame!"))
	target.apply_damage(80, BURN)
	target.apply_lc_overheat(10)
	target.cut_overlay(impale_overlay)
	// Target thrown backward from the rip
	animate(target, pixel_x = target.base_pixel_x + (get_dir(user, target) & EAST ? 10 : -10), pixel_y = target.base_pixel_y - 4, time = 0.15 SECONDS, easing = QUAD_EASING)
	animate(pixel_x = target.base_pixel_x, pixel_y = target.base_pixel_y, time = 0.3 SECONDS, easing = QUAD_EASING)
	new /obj/effect/temp_visual/explosion/fast(get_turf(target))
	for(var/turf/T in orange(1, target))
		new /obj/effect/temp_visual/fire(T)
	for(var/mob/M in viewers(7, get_turf(user)))
		shake_camera(M, 3, 5)
	playsound(target, 'sound/effects/explosion1.ogg', 65, TRUE)

	// Step 8: Quip
	user.say("Hot as hell!")

	// Reset pixels
	animate(user, pixel_x = user.base_pixel_x, pixel_y = user.base_pixel_y, transform = null, time = 0.1 SECONDS)
	animate(target, pixel_x = target.base_pixel_x, pixel_y = target.base_pixel_y, transform = null, time = 0.1 SECONDS)
	user.SetImmobilized(0)
	COOLDOWN_START(src, combo4_cd, 45 SECONDS)
```

**Statuses Applied:** Overheat (heavy stacking)

**Has Knockback:** No — sustained pinning attack

---

### Combo 5 — "Complete and Total Extermination [Laevateinn]" (Ultimate — Full Unseal Required)

**Trigger:** HUD action button, seal stage 4 only (full unseal / 25% HP), 90s cooldown

**Description:**
1. The Ex-Great Brother performs a massive fiery horizontal slash, launching the target away
2. Dashes to the target's landing spot and slams them into the ground
3. Fire explosion dome erupts on the downed target
4. Wide burning sword sweep launches them again
5. The Ex-Great Brother dashes to the target and drags them back
6. Sustained fire slashes — rapid alternating hits
7. Impales target with Laevateinn — sustained burning impalement
8. Kicks the impaled target while blade is still embedded
9. Final burning stab-through — drives the blade deeper with full-screen fire
10. Rips blade free — "Hah! Bullseye!" — extreme wall-breaking knockback

**Placeholder Code:**
```dm
/obj/item/ego_weapon/city/laevateinn/proc/combo_total_extermination(mob/living/target, mob/living/carbon/human/user)
	set waitfor = FALSE
	if(!target || !user || user.stat == DEAD)
		return

	target.AddComponent(/datum/component/cutscene_duel, user, 18 SECONDS)
	user.Immobilize(18 SECONDS)
	target.Immobilize(18 SECONDS)

	// Step 1: Big fiery horizontal slash — wide arc centered on user, launch target
	user.visible_message(span_userdanger("[user] unleashes Laevateinn in a blazing arc!"))
	user.SpinAnimation(3, 1)
	sleep(0.15 SECONDS)
	user.do_attack_animation(target)
	target.apply_damage(40, BURN)
	target.apply_lc_overheat(5)
	new /obj/effect/temp_visual/dir_setting/laevateinn_basic_slash(get_turf(user), user.dir)
	for(var/turf/T in orange(2, user))
		if(prob(50))
			new /obj/effect/temp_visual/fire(T)
	// Target launched with spin
	target.SpinAnimation(5, 1)
	shake_camera(target, 3, 4)
	playsound(target, 'sound/weapons/bladeslice.ogg', 70, TRUE)
	target.throw_at(get_ranged_target_turf_direct(user, target, 3), 3, 4, user, TRUE)
	sleep(0.6 SECONDS)

	// Step 2: Dash to target + slam — smoke at origin, smoke trail on path, slam on arrival
	var/turf/dash_origin = get_turf(user)
	var/dash_dir = get_dir(user, target)
	// Smoke afterdash at origin
	new /obj/effect/temp_visual/dir_setting/smoke_afterdash(dash_origin, dash_dir)
	// Smoke trail on each tile in the path
	var/turf/current = dash_origin
	for(var/i in 1 to get_dist(user, target))
		current = get_step(current, dash_dir)
		if(current)
			var/obj/effect/temp_visual/dir_setting/smoke_dash/trailsmoke = new(current, dash_dir)
			trailsmoke.color = "#D8B4FE"
	animate(user, alpha = 0, pixel_y = user.base_pixel_y + 16, time = 0.15 SECONDS, easing = QUAD_EASING)
	sleep(0.15 SECONDS)
	user.forceMove(get_turf(target))
	// Reappear above target, slam down
	user.pixel_y = user.base_pixel_y + 20
	animate(user, alpha = 255, pixel_y = user.base_pixel_y, time = 0.15 SECONDS, easing = BOUNCE_EASING)
	user.do_attack_animation(target)
	target.apply_damage(35, BRUTE)
	target.Knockdown(5 SECONDS)
	// Target slammed into floor
	animate(target, pixel_y = target.base_pixel_y - 8, time = 0.05 SECONDS)
	animate(pixel_y = target.base_pixel_y, time = 0.3 SECONDS, easing = BOUNCE_EASING)
	new /obj/effect/temp_visual/middle_slam(get_turf(target))
	new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(target))
	shake_camera(target, 3, 5)
	playsound(target, 'sound/weapons/punch1.ogg', 65, TRUE)
	sleep(0.5 SECONDS)

	// Step 3: Fire explosion dome on downed target
	target.apply_damage(50, BURN)
	target.apply_lc_overheat(5)
	new /obj/effect/temp_visual/explosion(get_turf(target))
	for(var/turf/T in orange(2, target))
		new /obj/effect/temp_visual/fire(T)
	// Target shakes violently from explosion
	animate(target, pixel_x = target.base_pixel_x + 5, time = 0.05 SECONDS)
	animate(pixel_x = target.base_pixel_x - 5, time = 0.05 SECONDS)
	animate(pixel_x = target.base_pixel_x + 4, time = 0.05 SECONDS)
	animate(pixel_x = target.base_pixel_x - 4, time = 0.05 SECONDS)
	animate(pixel_x = target.base_pixel_x, time = 0.05 SECONDS)
	for(var/mob/M in viewers(7, get_turf(user)))
		shake_camera(M, 3, 5)
	playsound(target, 'sound/effects/explosion1.ogg', 70, TRUE)
	sleep(0.7 SECONDS)

	// Step 4: Burning sword sweep — wide arc + launch again
	animate(user, transform = matrix(90, MATRIX_ROTATE), time = 0.1 SECONDS, easing = QUAD_EASING)
	animate(transform = null, time = 0.15 SECONDS, easing = QUAD_EASING)
	user.do_attack_animation(target)
	target.apply_damage(40, BURN)
	new /obj/effect/temp_visual/dir_setting/laevateinn_basic_slash(get_turf(user), user.dir)
	new /obj/effect/temp_visual/fire/fast(get_turf(target))
	target.SpinAnimation(5, 1)
	shake_camera(target, 2, 4)
	playsound(target, 'sound/weapons/bladeslice.ogg', 60, TRUE)
	target.throw_at(get_ranged_target_turf_direct(user, target, 4), 4, 4, user, TRUE)
	sleep(0.6 SECONDS)

	// Step 5: Dash to target + drag them back
	var/turf/dash5_origin = get_turf(user)
	var/dash5_dir = get_dir(user, target)
	var/obj/effect/temp_visual/dir_setting/smoke_afterdash/aftersmoke5 = new(dash5_origin, dash5_dir)
	aftersmoke5.color = "#D8B4FE"
	animate(user, alpha = 0, time = 0.1 SECONDS)
	sleep(0.1 SECONDS)
	user.forceMove(get_turf(target))
	animate(user, alpha = 255, time = 0.1 SECONDS)
	new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(target))
	playsound(target, 'sound/weapons/punch1.ogg', 60, TRUE)
	sleep(0.3 SECONDS)
	// Drag target back adjacent
	target.forceMove(get_step(user, get_dir(user, target)))
	sleep(0.3 SECONDS)

	// Step 6: Sustained fire slashes — alternating swing directions with rotation
	for(var/i in 1 to 4)
		var/swing_angle = (i % 2 == 1) ? 60 : -60
		animate(user, transform = matrix(swing_angle, MATRIX_ROTATE), time = 0.08 SECONDS, easing = QUAD_EASING)
		animate(transform = null, time = 0.12 SECONDS, easing = QUAD_EASING)
		user.do_attack_animation(target)
		target.apply_damage(25, BURN)
		target.apply_lc_overheat(3)
		new /obj/effect/temp_visual/fire/fast(get_turf(target))
		new /obj/effect/temp_visual/dir_setting/middle_slash(get_turf(target), user.dir)
		// Target jolts from each hit
		animate(target, pixel_x = target.base_pixel_x + (swing_angle > 0 ? 4 : -4), time = 0.05 SECONDS)
		animate(pixel_x = target.base_pixel_x, time = 0.1 SECONDS, easing = QUAD_EASING)
		shake_camera(target, 2, 3)
		playsound(target, 'sound/weapons/bladeslice.ogg', 50, TRUE)
		sleep(0.3 SECONDS)

	// Step 7: Impale with Laevateinn — user lunges forward, stab effect facing right
	animate(user, pixel_x = user.base_pixel_x - 6, time = 0.1 SECONDS, easing = QUAD_EASING)
	user.visible_message(span_danger("[user] drives Laevateinn through [target]!"))
	user.do_attack_animation(target)
	target.apply_damage(50, BURN)
	new /obj/effect/temp_visual/dir_setting/laevateinn_stab(get_turf(target), EAST)
	var/mutable_appearance/impale = mutable_appearance(icon, icon_state, ABOVE_MOB_LAYER)
	impale.pixel_x = 8
	target.add_overlay(impale)
	new /obj/effect/temp_visual/dir_setting/laevateinn_blast(get_turf(target))
	// Target recoils back from impalement
	animate(target, pixel_x = target.base_pixel_x + (get_dir(user, target) & EAST ? 6 : -6), time = 0.08 SECONDS, easing = QUAD_EASING)
	animate(pixel_x = target.base_pixel_x, time = 0.2 SECONDS, easing = QUAD_EASING)
	animate(user, pixel_x = user.base_pixel_x, time = 0.2 SECONDS, easing = QUAD_EASING)
	shake_camera(target, 3, 4)
	playsound(target, 'sound/weapons/bladeslice.ogg', 70, TRUE)
	sleep(0.6 SECONDS)

	// Step 8: Kick while impaled — user's foot rises + slams
	animate(user, pixel_y = user.base_pixel_y + 4, time = 0.1 SECONDS, easing = QUAD_EASING)
	animate(pixel_y = user.base_pixel_y, time = 0.08 SECONDS, easing = BOUNCE_EASING)
	user.do_attack_animation(target)
	target.apply_damage(30, BRUTE)
	// Target buckles from the kick
	animate(target, pixel_y = target.base_pixel_y - 4, pixel_x = target.base_pixel_x + rand(-3, 3), time = 0.05 SECONDS)
	animate(pixel_y = target.base_pixel_y, pixel_x = target.base_pixel_x, time = 0.2 SECONDS, easing = QUAD_EASING)
	new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(target))
	shake_camera(target, 2, 3)
	playsound(target, 'sound/weapons/punch1.ogg', 55, TRUE)
	sleep(0.4 SECONDS)

	// Step 9: Final burning stab-through — user drives forward with full weight
	animate(user, pixel_x = user.base_pixel_x + (get_dir(user, target) & EAST ? 12 : -12), transform = matrix(15, MATRIX_ROTATE), time = 0.15 SECONDS, easing = QUAD_EASING)
	animate(pixel_x = user.base_pixel_x, transform = null, time = 0.2 SECONDS, easing = QUAD_EASING)
	user.do_attack_animation(target)
	target.apply_damage(80, BURN)
	target.apply_lc_overheat(10)
	// Target shakes violently from the final thrust
	animate(target, pixel_x = target.base_pixel_x + 6, time = 0.03 SECONDS)
	animate(pixel_x = target.base_pixel_x - 6, time = 0.03 SECONDS)
	animate(pixel_x = target.base_pixel_x + 5, time = 0.03 SECONDS)
	animate(pixel_x = target.base_pixel_x - 5, time = 0.03 SECONDS)
	animate(pixel_x = target.base_pixel_x, time = 0.05 SECONDS)
	for(var/turf/T in orange(3, target))
		if(prob(60))
			new /obj/effect/temp_visual/fire(T)
	for(var/mob/M in viewers(10, get_turf(user)))
		shake_camera(M, 4, 6)
	playsound(target, 'sound/effects/explosion1.ogg', 75, TRUE)
	sleep(0.8 SECONDS)

	// Step 10: Rip blade free — user spins away + "Hah! Bullseye!" + extreme knockback
	user.SpinAnimation(3, 1)
	target.cut_overlay(impale)
	sleep(0.2 SECONDS)
	user.say("Hah! Bullseye!")
	target.apply_damage(40, BRUTE)
	// Middle emblem swirl (recolored explosion)
	var/obj/effect/temp_visual/explosion/emblem = new(get_turf(target))
	emblem.color = "#9932CC"
	new /obj/effect/temp_visual/kinetic_blast(get_turf(target))

	// Wall-breaking knockback — 8 tiles
	wall_breaking_knockback(target, user, get_dir(user, target), 8)

	// Reset pixels
	animate(user, pixel_x = user.base_pixel_x, pixel_y = user.base_pixel_y, transform = null, time = 0.1 SECONDS)
	user.SetImmobilized(0)
	COOLDOWN_START(src, combo5_cd, 90 SECONDS)
```

**Statuses Applied:** Overheat (massive stacking), Bleed

**Has Knockback:** Yes (extreme) — breaks multiple walls, 8 tile launch

---

## Wall Rubble System

### `/obj/structure/wall_rubble`
- Dense = FALSE (passable)
- Stores original wall type path for reconstruction
- Icon: debris/rubble sprite (TBD)
- `var/original_wall_type` — the `/turf/closed` path that was here
- `var/repair_timer_id`

### Repair Logic
- On creation: start 2-minute timer → `try_repair()`
- `try_repair()`:
  - Check if any living mob has this in `view(7)`
  - If no watchers: reconstruct original wall via `ChangeTurf(original_wall_type)`, qdel rubble
  - If watchers: restart timer for 1 minute, try again

### Breaking Logic (called from combo knockback)
- For each tile in knockback path:
  - If `/turf/closed/indestructible/rock` → stop, target takes impact damage
  - If space (`/turf/open/space`) → stop, target takes impact damage
  - If `/turf/closed` (destructible wall) → replace with `/turf/open/floor`, spawn wall_rubble, continue
  - If dense object → stop, target takes impact damage

---

## Weapon Numbers: Laevateinn

**Attribute Requirements:** 100 Fort / 100 Prud / 100 Temp / 100 Just
**Damage Type:** RED_DAMAGE (physical) → transitions to BURN as seals break
**Attack Speed:** 1.5 (slow, heavy two-handed sword feel — one-armed swing)
**Reach:** 2 (oversized sword)

### Normal Attack Damage by Seal Stage

| Stage | force | Burn Bypass % | Effective DPS Notes |
|-------|-------|--------------|---------------------|
| Full Seal | 20 | 0% | Very weak — ~40% of target. Encourages using fists/combos |
| Unseal 1 (75% HP) | 35 | 25% | ~60% of target. Getting warmer |
| Unseal 2 (50% HP) | 50 | 50% | ~85% of target. Fire damage starts hurting |
| Full Power (25% HP) | 65 | 100% (pure BURN) | Full power — matches other nursefather weapons |

"Burn bypass" means that % of damage ignores armor (dealt as forced BURN). At full power, all 65 force is armor-bypassing BURN.

### Overheat on Hit
- Unseal 2+: Each normal hit applies 2 Overheat stacks to target
- Full Power: Each normal hit applies 4 Overheat stacks to target

### Combo Damage Summary
| Combo | Total Damage | Overheat Applied | Cooldown |
|-------|-------------|-----------------|----------|
| 1 — Chain Grapple | ~210 (BRUTE + Bleed) | 0 | None (3-hit trigger) |
| 2 — Stomping | ~160 (BRUTE + Bleed) | 0 | 30s |
| 3 — Gut Ya Like a Fish | ~250 (BRUTE → BURN) | 20 stacks | None (3-hit trigger) |
| 4 — Gut Stab | ~295 (BURN, escalating) | 26 stacks | 45s |
| 5 — Total Extermination | ~550 (mixed, massive) | 30+ stacks | 90s |

---

## Armor Numbers: Middle Nursefather Coat

**Attribute Requirements:** 100 Fort / 100 Prud / 100 Temp / 100 Just (same tier as Big Brother)

### Armor Values
Follows the Middle pattern (RED-heavy, balanced others) but above Big Brother tier:
```
armor = list(RED_DAMAGE = 70, WHITE_DAMAGE = 55, BLACK_DAMAGE = 55, PALE_DAMAGE = 55)
```

**Comparison to existing Middle armor:**
| Rank | RED | WHITE | BLACK | PALE | Total |
|------|-----|-------|-------|------|-------|
| Little Brother | 30 | 20 | 20 | 20 | 90 |
| Younger Brother | 40 | 30 | 30 | 30 | 130 |
| Big Brother | 60 | 50 | 50 | 50 | 210 |
| **Nursefather (Ex-Great)** | **70** | **55** | **55** | **55** | **235** |

### Armor Special Properties
- `equip_delay_self = 0` — no equip delay (role spawn item, not player-acquired mid-round)
- Includes cape via `neck` slot: `/obj/item/clothing/neck/ego_neck/middle_cape/nursefather`
- `flags_inv = HIDEJUMPSUIT` — hides uniform underneath
- Has the suit storage `allowed` list for Laevateinn back display

### Accessory Stats

**Sunglasses** — `/obj/item/clothing/glasses/middle_sunglasses/nursefather`
- Same as regular Middle sunglasses but with `middlefather_sunglasses` icon_state
- Flash protection, slight darkness vision

**Book of Vengeance** — `/obj/item/storage/book/middle/nursefather`
- Same vengeance mark mechanic as Big Brother's book but with `middlefather_vengeance` icon_state
- `vengeance_mark_stacks = 3` (slightly more than Big Brother's 2)
- Note: Vengeance Mark not actively used by combos for now, but the book still applies it passively

**White Gloves** — standard `/obj/item/clothing/gloves/color/white`

---

---

## Implementation Checklist

### Files in the NURSEFATHER BRANCH (core PR)
The core branch creates all files as **stubs** (1-line comment placeholders) and adds the **DME includes**. The sub-PR fills in the actual content.

#### Already Complete
- [x] `code/datums/components/nursefather_passive.dm` — already exists
- [x] `code/datums/components/nursefather_music.dm` — already exists
- [x] `code/datums/components/nursefather_music_debug.dm` — already exists
- [x] `ModularLobotomy/nursefathers/apprentice_recruitment.dm` — already exists
- [x] `code/__DEFINES/sound.dm` — CHANNEL_NURSEFATHER already added
- [x] `code/modules/client/preferences.dm` — player_ambience_volume already added
- [x] `ModularLobotomy/lc13_effects.dm` — middle temp visual effects already added

#### Still Needed in Core Branch
- [ ] `code/datums/components/nursefather_passive.dm` — add `/middle` subtype (no dodge, 2.5% clone)
- [ ] Create **stub files** for all Middle sub-PR files (see below) — 1-line comment each
- [ ] Add **DME includes** for all stub files in `lobotomy-corp13.dme`

### Files Needed in the MIDDLE SUB-PR
All of these files are created as stubs in the core branch. The sub-PR replaces stub content with actual code.

#### Files to Populate (stubs created in core)

1. **Job Definition** — `code/modules/jobs/job_types/trusted_players/middle_nursefather.dm`
   - `/datum/job/middle_nursefather` (title, outfit, stats 500/500/100/100, trusted_only)
   - `/datum/job/middle_nursefather/after_spawn()` — equip sequence:
     1. Remove right arm (`qdel(H.get_bodypart(BODY_ZONE_R_ARM))`)
     2. Add traits (TRAIT_COMBATFEAR_IMMUNE, TRAIT_WORK_FORBIDDEN)
     3. Add nursefather_passive/middle subtype
     4. Add nursefather_music (NURSEFATHER_FINGER_MIDDLE)
     5. Force-equip armor to suit slot (equip_delay_self = 0)
     6. Place Laevateinn in suit s_store
     7. Grant rules action
   - `/datum/outfit/job/middle_nursefather` (uniform, shoes, glasses, gloves, belt items)
   - Apprentice recruitment subtype
   - Role rules action (view_role_rules subtype)
   - Debug transform item (`/obj/item/middle_nursefather_debug`)
   - Ghost poll spawn item (`/obj/item/middle_nursefather_ghost_spawn`)

2. **Weapon: Laevateinn** — `ModularLobotomy/ego_weapons/melee/city/middle_laevateinn.dm`
   - `/obj/item/ego_weapon/city/laevateinn` — the sealed relic sword
     - Variables: seal_stage (0-3), icon states for each stage
     - force scaling: 20 → 35 → 50 → 65
     - Burn bypass % scaling per stage
     - attack_speed = 1.5, reach = 2
     - Overheat application at stage 2+
     - `attack()` override — consume Grudge for bonus damage on sword hits
     - `afterattack()` override — Grudge Dash when clicking 3-7 tiles away while sheathed
     - `attack_self()` override — trigger Combo 4 (Gut Stab) when grabbed target adjacent

3. **Combo System** — `ModularLobotomy/nursefathers/middle_combos.dm`
   - Combo 1: `combo_chain_grapple()` proc
   - Combo 2: `combo_stomping()` proc
   - Combo 3: `combo_gut_fish()` proc
   - Combo 4: `combo_gut_stab()` proc
   - Combo 5: `combo_total_extermination()` proc
   - `wall_breaking_knockback()` shared proc
   - Combo trigger logic (checking grab state, seal stage, cooldowns)

4. **Grudge System** — `ModularLobotomy/nursefathers/middle_grudge.dm`
   - `/datum/component/middle_grudge` — component on the Middle Nursefather
     - `grudge_stacks` var, max 20
     - Signal handler for `COMSIG_MOB_APPLY_DAMGE` — gain stacks when hit (scaling with damage)
     - HUD alert showing stack count
     - Procs: `add_grudge()`, `consume_grudge()`, `has_grudge(amount)`

5. **Seal System** — `ModularLobotomy/nursefathers/middle_seal.dm`
   - `/datum/component/laevateinn_seal` — component on the Middle Nursefather
     - Healthgate logic (cap damage at 75%/50%/25% thresholds)
     - Unseal cutscene proc (damage reduction during cutscene, icon update, seal structure spawn)
     - Signal handler for `COMSIG_MOB_APPLY_DAMGE`
     - Overheat aura at stage 2+ (process tick, apply to nearby mobs)
     - Light emission at stage 2+

6. **Grab System** — `ModularLobotomy/nursefathers/middle_grab.dm`
   - `/datum/component/middle_grab` — or procs on the weapon/grudge component
     - `initiate_grab()` — carbon (real grab via setGrabState) vs simple mob (toggle_ai)
     - `release_grab()` — cleanup, restore AI
     - Weakened status effect: `/datum/status_effect/middlefather_weakened` (6 second duration)
     - Combo routing logic: which combo triggers based on grab + weapon state + seal + HP

7. **Wall Rubble** — `ModularLobotomy/nursefathers/middle_wall_rubble.dm`
   - `/obj/structure/wall_rubble` — passable structure, stores original wall type
     - Repair timer: 2 minutes if unobserved, retry in 1 minute if observed
     - `try_repair()` proc with viewer check
   - `wall_breaking_knockback()` proc — tile-by-tile knockback with wall destruction

8. **Seal Structure** — `ModularLobotomy/nursefathers/middle_seal_structure.dm`
   - `/obj/structure/laevateinn_seal` — dense structure dropped when a seal breaks
     - Debug sprite: `"uzi9mm-0"` from `icons/obj/ammo.dmi` (placeholder)
     - Warning effect (1x1, 1.5 seconds) on random tile before landing

9. **Middle Nursefather Armor** — `code/modules/clothing/suits/ego_gear/non_abnormality/middle.dm` (append to existing)
   - `/obj/item/clothing/suit/armor/ego_gear/city/middle_nursefather` — Ex-Great Brother coat
     - armor = list(RED = 70, WHITE = 55, BLACK = 55, PALE = 55)
     - equip_delay_self = 0
     - neck = cape subtype
     - icon/worn_icon using `middle_spider_icon.dmi` / `middle_spider_worn.dmi`
     - icon_state = "middlefather_outfit"
   - `/obj/item/clothing/neck/ego_neck/middle_cape/nursefather` — nursefather cape
     - icon_state = "middlefather_cloak"
   - `/obj/item/clothing/glasses/middle_sunglasses/nursefather` — nursefather sunglasses
     - icon_state = "middlefather_sunglasses"
   - `/obj/item/storage/book/middle/nursefather` — nursefather Book of Vengeance
     - icon_state = "middlefather_vengeance"
     - vengeance_mark_stacks = 3

10. **Combo 5 Action Button** — part of the combo system file
    - `/datum/action/cooldown/total_extermination` — HUD action, 90s cooldown, seal stage 4 only

#### Files Modified in Core Branch (stubs + DME)

1. **`lobotomy-corp13.dme`** — Add includes for all new stub files (done in core branch)

2. **`code/datums/components/nursefather_passive.dm`** — Add `/middle` subtype (done in core branch)

3. **`code/__DEFINES/traits.dm`** — Add `TRAIT_MIDDLEFATHER_GRAB` if needed (done in core branch)

4. **`code/__DEFINES/dcs/signals.dm`** — Add any new signals if needed (done in core branch)

5. **`code/modules/jobs/jobs.dm`** — Add Middle Nursefather job to the job list (done in core branch)

#### Files Modified in Sub-PR Only

1. **`code/modules/clothing/suits/ego_gear/non_abnormality/middle.dm`** — Append nursefather armor subtypes (content change, no new file)

#### Things That Already Exist and Can Be Reused

| System | Path | What It Provides |
|--------|------|-----------------|
| Cutscene duel | `ModularLobotomy/associations/skills/_cutscene_duel.dm` | Damage denial during combos |
| Vengeance Mark | `code/datums/status_effects/debuffs.dm` | Stacking debuff (not used in combos for now, but Book applies it) |
| Overheat status | `code/datums/status_effects/debuffs.dm` | `apply_lc_overheat()` for fire damage |
| Bleed status | `code/datums/status_effects/debuffs.dm` | `apply_lc_bleed()` for movement-based damage |
| Book of Vengeance | `code/modules/clothing/suits/ego_gear/non_abnormality/middle.dm` | Belt item with vengeance mark on hit |
| Middle sunglasses | same file | Flash protection, darkness view |
| Middle cape | same file | Neck slot cape |
| Beam system | `origin.Beam()` | Chain/trail visual effects |
| throw_at | built-in | Knockback mechanics |
| toggle_ai | simple_animal | AI disable for grab on simple mobs |
| SpinAnimation | `code/__HELPERS/matrices.dm` | Sprite rotation |
| shake_camera | `code/modules/mob/mob_helpers.dm` | Screen shake |
| Laevateinn icons | `icons/obj/spider_house/middle/` | All 4 DMI files for the sword |
| Middle armor icons | `icons/obj/spider_house/middle/` | Both icon + worn DMIs |
| Sound tracks | `sound/ambience/nursefathers/` | middle_nursefather_passive.ogg, middle_nursefather_combat.ogg |
| Custom temp visuals | `ModularLobotomy/lc13_effects.dm` | All 9 middle combat effects |

#### Estimated File Count
- **New files:** ~10
- **Modified files:** ~6
- **Total new code:** ~2000-3000 lines estimated

---

## TODO
- [ ] Determine exact damage numbers for each seal stage
- [ ] Determine Overheat aura range and tick rate
- [ ] Determine cutscene duration and effects (screen flash, sound, etc.)
- [ ] Seal structure stats (HP? Destructible? Pure obstacle?)
- [ ] Apprentice design (Kira?)
- [ ] Role rules text
- [ ] Debug tool + ghost poll spawn item
