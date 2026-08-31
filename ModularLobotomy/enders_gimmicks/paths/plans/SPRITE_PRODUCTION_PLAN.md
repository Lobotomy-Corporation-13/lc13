# Sprite Production Plan - Pathstrider Update

How I would make every new sprite for this update: the progression materials
(with filter-driven rarity), the Omni-Synthesizer machine, and the Calyx
structures. Grounded in the existing scratchpad pipeline used for the abno
sprites.

## 0. Pipeline recap (what we build with)

- **No Pillow.** DMIs are written with pure stdlib (zlib + struct) via
  `spritelib.py` in the session scratchpad: parametrised `canvas / px / ell / tri
  / line` drawing, `add_shade_outline(cv, factor)`, `write_dmi(states)`,
  `blit_rotated` (for animation), plus `compare()` for visual verification.
- **House style: darker-shade outline (no black).** Each silhouette edge is a
  darker shade of the fill it borders (`add_shade_outline(cv, factor=0.55)`). Use
  this on every new sprite so the update matches the recent abnos.
- **Per-asset draw scripts** (like `gigs.py`), one per DMI, that draw -> shade -> 
  `write_dmi` -> emit a `cmp_*.png`. Iterate against the reference until close.
- **Install carefully:** `cp -f` into `ModularLobotomy/_Lobotomyicons/` + `sync` +
  md5 verify (WSL /mnt/c writes can silently not persist).

## 1. The key art-saver: rarity is a runtime FILTER, not baked art

Each material family needs only **one** base icon_state. The three rarities
(T1/T2/T3) are the same sprite with a **light colored outline applied as a BYOND
filter at runtime**, per the request:

- T1 -> green outline, T2 -> blue outline, T3 -> purple outline.
- Proposed colors: green `#8CFF66`, blue `#5AA0FF`, purple `#B266FF`.

DM wiring (in the material stack's `Initialize`), driven by the item's `tier`:

```
add_filter("rarity", 1, list("type" = "outline", "color" = rarity_colors[tier], "size" = 1))
```

So 7 path families + 4 trace families = **11 base item sprites**, not 33. The
baked darker-shade outline stays subtle (it reads as the object's own edge); the
filter adds the brighter colored ring that reads as rarity, so the two edges don't
fight. Caveat to verify in-game: confirm the outline filter renders in the
inventory/HUD slot and on examine, not just on the floor.

## 2. Material designs (11 base sprites, 32x32)

All 32x32, single icon_state each, drawn as one bold readable object silhouette in
the family's theme color, shade-outlined. Group into two DMIs to keep the file
count low:

### 2a. Path materials -> `path_materials.dmi` (7 states, sin-themed)

| Family (path / sin) | icon_state | Silhouette idea | Base color |
|---|---|---|---|
| Destruction / Wrath | `mat_wrath` | jagged cracked ember shard, glowing seam | dark red / ember orange |
| The Hunt / Envy | `mat_envy` | curved arrowhead / claw | teal-green steel |
| Erudition / Pride | `mat_pride` | faceted prism / cut gem | pale gold / white |
| Nihility / Gloom | `mat_gloom` | hollow ring with a void center | desaturated indigo / near-black |
| Harmony / Lust | `mat_lust` | tuning-fork / chord crystal | warm rose / pink |
| Preservation / Sloth | `mat_sloth` | thick brick / shield chip | slate grey / bronze |
| Abundance / Gluttony | `mat_gluttony` | budding seed / fruit pod | green / amber |

### 2b. Trace materials -> `trace_materials.dmi` (4 states, cluster-themed)

| Family (cluster) | icon_state | Silhouette idea | Base color |
|---|---|---|---|
| Fang (Destruction+Hunt) | `trace_fang` | single curved black fang, wet sheen | bone white on dark |
| Lens (Erudition+Nihility) | `trace_lens` | floating eye / concave lens | glassy cyan |
| Ichor (Abundance+Harmony) | `trace_ichor` | droplet in a small vial | deep crimson |
| Ward (Preservation) | `trace_ward` | broken armor plate corner | tempered steel blue |

Each should read at a glance in a 32x32 inventory slot; keep one dominant shape +
one accent, avoid fine detail that muddies under the rarity outline filter.

## 3. Omni-Synthesizer -> `omni_synthesizer.dmi` (machine, per Image #2)

A wall-mounted spherical device with a glowing split core (orange), throwing
sparks. Suggested 32x32 (fits the roundish device); go 32x48 only if we want a
mounting bracket below.

- **States:**
  - `omni_idle` - dark metallic sphere, thin banded plating, a horizontal core
    seam with a dim glow.
  - `omni_work` - brighter core, a couple of spark pixels, for the crafting moment
    (swap on `ui_act`, revert after a beat). Optionally a 3-4 frame pulse anim
    using the frame-major layout `spritelib` already supports.
- **Glow as a separate additive overlay** (`omni_core` state, drawn in
  white/greyscale) layered over the base with `blend_mode = BLEND_ADD` (or an
  emissive plane) so the molten seam actually glows and animates independently of
  the shell. Same technique as the Calyx core (Section 4), reused.
- Metallic shell uses the shade-outline; the core overlay stays neutral so it can
  be tinted/pulsed in code.

## 4. Calyx -> `calyx.dmi` (structure, per Image #12)

Blackened crystal-laced tendrils curling around a molten-light core, erupting from
cracked ground. Tall growth, so **64x64** (offset so the cracked base sits on the
tile; tendrils splay into the upper cells). Go 64x96 only if the splay needs more
height.

- **Two structure states (open / closed), light NOT baked in:**
  - `calyx_closed` - dormant: tendrils curled tight inward, a thin sliver of core
    visible, cracked base. This is the spawned/dormant look.
  - `calyx_open` - activated: tendrils splayed outward (like Image #12), the core
    channel wide open. Swap closed->open on `Activate()`.
- **The inner light is a SEPARATE, colorable overlay** (`calyx_core` state):
  - Drawn in **white/greyscale** (a vertical light column + glow) so a simple
    `overlay.color = ordeal_hex` cleanly tints it to the Calyx's ordeal color
    (green, amber, crimson, ...). Neutral art = correct multiply-tint.
  - Added as an overlay above the structure; use `BLEND_ADD` / emissive so it
    reads as emitted light, not a decal.
  - A `calyx_core_open` (or just a scaled/brighter version) for the open state so
    activation visibly floods more light.
- **Tendrils** are dark brown/black with the darker-shade outline; the molten
  veins can be a second faint additive overlay if we want them to glow too.
- **Optional polish:** a short emerge animation (alpha/pixel-y rise) is done in
  code, not sprites; a subtle 2-3 frame core flicker can live in `calyx_core`.

Why split the core out: it gives us open/closed x any-ordeal-color from just
`2 structure states + 1-2 neutral core states`, instead of a sprite per
color/state combination.

## 5. DMI / file layout

All under `ModularLobotomy/_Lobotomyicons/`:

| DMI | States | Cell size |
|---|---|---|
| `path_materials.dmi` | 7 (`mat_*`) | 32x32 |
| `trace_materials.dmi` | 4 (`trace_*`) | 32x32 |
| `omni_synthesizer.dmi` | `omni_idle`, `omni_work`, `omni_core` | 32x32 |
| `calyx.dmi` | `calyx_closed`, `calyx_open`, `calyx_core`, `calyx_core_open` | 64x64 |

Items/structures set `icon` to the dedicated DMI + `icon_state`; never edit the
shared 1000-state sheets. Materials pick their state by `family` and get the
rarity outline by `tier` in code (Section 1).

## 6. Production order + verification

1. Extend `spritelib.py` if needed (it already covers everything except maybe a
   simple radial-glow helper for the cores).
2. Materials first (11 states, 2 DMIs) - cheapest and unblocks the item code.
3. Omni-Synthesizer (reuses the additive-core technique).
4. Calyx (biggest; validate the open/closed + colored-core overlay in a test
   scene across 2-3 ordeal colors).
5. Verify each with `compare()` / decode+upscale; then `cp -f` + `sync` + md5.
6. In-game checks: rarity outline visible in inventory + floor; Calyx core tints
   per ordeal color and brightens on open; Omni core glows.

## 7. Open questions

1. **Rarity outline weight** - size 1 (thin, "light") as requested; confirm it
   isn't lost against dark backgrounds (may need size 1 + slight alpha bump).
2. **Base art per rarity** - keep the base identical across T1/T2/T3 (outline-only
   distinction, recommended), or add a tiny extra crystal/glow per tier for
   readability at a glance?
3. **Calyx size** - 64x64 vs 64x96 for the tendril splay.
4. **Glow tech** - `BLEND_ADD` overlay vs emissive plane for the cores (pick one
   and reuse for Omni + Calyx).
5. **Material silhouettes** - are the 11 shape ideas in Section 2 the right read,
   or do any families want a different icon?
