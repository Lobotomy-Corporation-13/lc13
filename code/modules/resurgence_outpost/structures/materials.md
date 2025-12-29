# Resurgence Outpost - Materials Reference

This document lists all materials available to players for crafting recipes.

---

## Raw Materials (Gathered/Found)

### Ores (Mined from deposits)
| Name | Type Path | Source |
|------|-----------|--------|
| Iron Ore | `/obj/item/stack/ore/iron` | Mining |
| Coal | `/obj/item/stack/sheet/mineral/coal` | Mining |
| Rock | `/obj/item/stack/ore/rock` | Mining |
| Silver Ore | `/obj/item/stack/ore/silver` | Mining |
| Gold Ore | `/obj/item/stack/ore/gold` | Mining |

### Wood & Stone (Gathered)
| Name | Type Path | Source |
|------|-----------|--------|
| Wood | `/obj/item/stack/sheet/mineral/wood` | Chopping trees |
| Sandstone | `/obj/item/stack/sheet/mineral/sandstone` | Mining/gathering |
| Glass Rubble | `/obj/item/stack/ore/glassrubble` | Scavenging |
| Sand/Glass Ore | `/obj/item/stack/ore/glass` | Mining |
| Iron Scrap | `/obj/item/stack/ore/ironscrap` | Scavenging |

### Fibers & Hides (Gathered/Hunted)
| Name | Type Path | Source |
|------|-----------|--------|
| Cotton | `/obj/item/stack/sheet/cotton` | Harvesting cotton plants |
| Animal Hide | `/obj/item/stack/sheet/animalhide/generic` | Hunting animals |
| Hairless Hide | `/obj/item/stack/sheet/hairlesshide` | Processing hide (cut with knife) |
| Wet Hide | `/obj/item/stack/sheet/wethide` | Washing hairless hide |

---

## Processed Materials (Made at Stations)

### Basic Processed (Forge/Crafting Table)
| Name | Type Path | Made From | Station |
|------|-----------|-----------|---------|
| Metal Sheet | `/obj/item/stack/sheet/metal` | 2 Iron Ore | Forge |
| Glass Sheet | `/obj/item/stack/sheet/glass` | 2 Sand | Forge |
| Metal Rods | `/obj/item/stack/rods` | 1 Metal Sheet | Crafting Table |
| Cloth | `/obj/item/stack/sheet/cotton/cloth` | 3 Cotton | Loom |
| Leather | `/obj/item/stack/sheet/leather` | Drying wet hide | Drying/Heat |
| Reinforced Glass | `/obj/item/stack/sheet/rglass` | 1 Glass + 1 Metal Rod | Crafting Table (future) |
| Plasteel | `/obj/item/stack/sheet/plasteel` | Special (rare material) | N/A |

### Precious Metals (Forge)
| Name | Type Path | Made From | Station |
|------|-----------|-----------|---------|
| Silver Sheet | `/obj/item/stack/sheet/mineral/silver` | 2 Silver Ore | Forge |
| Gold Sheet | `/obj/item/stack/sheet/mineral/gold` | 2 Gold Ore | Forge |

### Advanced Textiles (Loom)
| Name | Type Path | Made From | Station |
|------|-----------|-----------|---------|
| Durathread | `/obj/item/stack/sheet/durathread` | Special fiber | Loom (future) |

---

## Crafted Components (Resurgence-specific)

### Components (Crafting Table)
| Name | Type Path | Made From |
|------|-----------|-----------|
| Rope | `/obj/item/resurgence_component/rope` | 3 Cloth |
| Nails (x10) | `/obj/item/stack/resurgence_nails` | 1 Metal Sheet |
| Ash Plating | `/obj/item/resurgence_component/ash_plating` | TBD |
| Basic Microchip | `/obj/item/resurgence_component/microchip` | TBD |
| Advanced Microchip | `/obj/item/resurgence_component/microchip/advanced` | TBD |
| Super Microchip | `/obj/item/resurgence_component/microchip/super` | TBD |

---

## Floor Tiles (Crafting Table)
| Name | Type Path | Made From |
|------|-----------|-----------|
| Wood Floor Tiles (x4) | `/obj/item/stack/tile/wood` | 1 Wood |
| Plasteel Floor Tiles (x4) | `/obj/item/stack/tile/plasteel` | 1 Plasteel |
| Carpet Tiles (x4) | `/obj/item/stack/tile/carpet` | 2 Cloth |
| Black Carpet (x4) | `/obj/item/stack/tile/carpet/black` | 2 Cloth |
| Blue Carpet (x4) | `/obj/item/stack/tile/carpet/blue` | 2 Cloth |
| Cyan Carpet (x4) | `/obj/item/stack/tile/carpet/cyan` | 2 Cloth |
| Green Carpet (x4) | `/obj/item/stack/tile/carpet/green` | 2 Cloth |
| Orange Carpet (x4) | `/obj/item/stack/tile/carpet/orange` | 2 Cloth |
| Purple Carpet (x4) | `/obj/item/stack/tile/carpet/purple` | 2 Cloth |
| Red Carpet (x4) | `/obj/item/stack/tile/carpet/red` | 2 Cloth |
| Royal Black Carpet (x4) | `/obj/item/stack/tile/carpet/royalblack` | 2 Cloth + 1 Gold |
| Royal Blue Carpet (x4) | `/obj/item/stack/tile/carpet/royalblue` | 2 Cloth + 1 Gold |

---

## Material Categories by Use

### Construction
- Wood, Metal Sheet, Metal Rods, Nails, Plasteel

### Metalworking
- Iron Ore, Iron Scrap, Metal Sheet, Metal Rods, Plasteel

### Textiles
- Cotton, Cloth, Rope, Durathread

### Leatherworking
- Animal Hide, Hairless Hide, Wet Hide, Leather

### Glassworking
- Sand/Glass Ore, Glass Rubble, Glass Sheet, Reinforced Glass

### Precious/Decorative
- Gold Ore, Gold Sheet, Silver Ore, Silver Sheet

---

## Quick Reference: Type Paths

```dm
// Raw Ores
/obj/item/stack/ore/iron
/obj/item/stack/ore/ironscrap
/obj/item/stack/ore/glass
/obj/item/stack/ore/glassrubble
/obj/item/stack/ore/rock
/obj/item/stack/ore/silver
/obj/item/stack/ore/gold

// Basic Sheets
/obj/item/stack/sheet/metal
/obj/item/stack/sheet/glass
/obj/item/stack/sheet/mineral/wood
/obj/item/stack/sheet/mineral/sandstone
/obj/item/stack/sheet/mineral/coal
/obj/item/stack/sheet/mineral/silver
/obj/item/stack/sheet/mineral/gold
/obj/item/stack/sheet/plasteel
/obj/item/stack/sheet/rglass

// Textiles
/obj/item/stack/sheet/cotton
/obj/item/stack/sheet/cotton/cloth
/obj/item/stack/sheet/durathread

// Leather Processing Chain
/obj/item/stack/sheet/animalhide/generic  // Raw hide from animals
/obj/item/stack/sheet/hairlesshide        // After cutting with knife
/obj/item/stack/sheet/wethide             // After washing
/obj/item/stack/sheet/leather             // After drying

// Other
/obj/item/stack/rods
/obj/item/stack/resurgence_nails

// Resurgence Components
/obj/item/resurgence_component/rope
/obj/item/resurgence_component/ash_plating
/obj/item/resurgence_component/microchip
/obj/item/resurgence_component/microchip/advanced
/obj/item/resurgence_component/microchip/super

// Floor Tiles
/obj/item/stack/tile/wood
/obj/item/stack/tile/plasteel
/obj/item/stack/tile/carpet
/obj/item/stack/tile/carpet/black
/obj/item/stack/tile/carpet/blue
/obj/item/stack/tile/carpet/cyan
/obj/item/stack/tile/carpet/green
/obj/item/stack/tile/carpet/orange
/obj/item/stack/tile/carpet/purple
/obj/item/stack/tile/carpet/red
/obj/item/stack/tile/carpet/royalblack
/obj/item/stack/tile/carpet/royalblue
```

---

## Leather Processing Chain

1. **Animal Hide** (`/obj/item/stack/sheet/animalhide/generic`) - Raw drop from animals
2. **Hairless Hide** (`/obj/item/stack/sheet/hairlesshide`) - Cut hide with knife/sharp object
3. **Wet Hide** (`/obj/item/stack/sheet/wethide`) - Wash hairless hide (washing machine)
4. **Leather** (`/obj/item/stack/sheet/leather`) - Dry wet hide (heat/microwave)

---

## Notes

- **Plasteel** is rare/special and not easily obtainable - used for high-tier recipes
- **Durathread** requires special processing (future implementation)
- Metal Rods use the existing `/obj/item/stack/rods` type
- Use existing game materials where possible instead of custom components
- All ore smelting happens at the Forge
- All textile processing happens at the Loom
- General component crafting happens at the Crafting Table

### Removed Components (Use Base Game Materials Instead)
- ~~wooden_plank~~ → Use `/obj/item/stack/sheet/mineral/wood`
- ~~metal_plate~~ → Use `/obj/item/stack/sheet/metal`
- ~~leather_strip~~ → Use `/obj/item/stack/sheet/leather`
- ~~glass_lens~~ → Use `/obj/item/stack/sheet/glass`
- ~~reinforced_plate~~ → Use `/obj/item/stack/sheet/plasteel`
- ~~metal_frame~~ → Removed
- ~~gear_assembly~~ → Removed
- ~~carved_ornament~~ → Removed
- ~~woven_tapestry~~ → Removed
