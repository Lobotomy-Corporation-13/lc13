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
| Vines | `/obj/item/stack/resurgence_vines` | Harvesting wild plants |
| Durathread | `/obj/item/grown/cotton/durathread` | Harvesting durathread plants |
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
| Plasteel | `/obj/item/stack/sheet/plasteel` | 2 Metal + 1 Coal | Forge |

### Precious Metals (Forge)
| Name | Type Path | Made From | Station |
|------|-----------|-----------|---------|
| Silver Sheet | `/obj/item/stack/sheet/mineral/silver` | 2 Silver Ore | Forge |
| Gold Sheet | `/obj/item/stack/sheet/mineral/gold` | 2 Gold Ore | Forge |

---

## Crafted Components (Resurgence-specific)

### Components (Crafting Table/Loom/Forge)
| Name | Type Path | Made From | Station |
|------|-----------|-----------|---------|
| Rope | `/obj/item/resurgence_component/rope` | 3 Cloth OR 8 Cotton OR 3 Vines | Crafting Table |
| Fertilizer | `/obj/item/stack/resurgence_fertilizer` | 5 Coal | Crafting Table |
| Ash Plating | `/obj/item/resurgence_component/ash_plating` | 10 Metal + 20 Coal | Forge |

### Faith Fabrics (Loom)
| Name | Type Path | Made From |
|------|-----------|-----------|
| Simple Azure Faith Fabric | `/obj/item/resurgence_fabric/simple` | 5 Cloth + 1 Rope |
| Advanced Azure Faith Fabric | `/obj/item/resurgence_fabric/advanced` | 8 Cloth + 3 Durathread + 2 Rope |
| Elegant Azure Faith Fabric | `/obj/item/resurgence_fabric/elegant` | 10 Cloth + 6 Durathread + 3 Rope |

---

## Floor Tiles (Crafting Table)
| Name | Type Path | Made From |
|------|-----------|-----------|
| Plasteel Floor Tiles (x4) | `/obj/item/stack/tile/plasteel` | 2 Plasteel |
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

### Construction (Blueprints)
- Wood, Metal Sheet, Metal Rods, Plasteel, Sandstone, Silver, Gold, Rope

### Metalworking (Forge)
- Iron Ore, Iron Scrap, Metal Sheet, Coal, Plasteel, Ash Plating

### Textiles (Loom)
- Cotton, Cloth, Rope, Durathread, Leather

### Leatherworking
- Animal Hide, Hairless Hide, Wet Hide, Leather

### Glassworking (Forge)
- Sand/Glass Ore, Glass Rubble, Glass Sheet

### Precious/Decorative
- Gold Ore, Gold Sheet, Silver Ore, Silver Sheet

---

## Quick Reference: Type Paths (Implemented)

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

// Textiles
/obj/item/stack/sheet/cotton
/obj/item/stack/sheet/cotton/cloth

// Leather Processing Chain
/obj/item/stack/sheet/animalhide/generic
/obj/item/stack/sheet/hairlesshide
/obj/item/stack/sheet/wethide
/obj/item/stack/sheet/leather

// Other Base Game
/obj/item/stack/rods

// Resurgence-Specific Materials (IMPLEMENTED)
/obj/item/resurgence_component/rope
/obj/item/resurgence_component/ash_plating
/obj/item/resurgence_component/microchip          // Basic
/obj/item/resurgence_component/microchip/advanced // Advanced
/obj/item/resurgence_component/microchip/super    // Super
/obj/item/stack/resurgence_vines
/obj/item/stack/resurgence_fertilizer
/obj/item/grown/cotton/durathread

// Faith Fabrics (IMPLEMENTED)
/obj/item/resurgence_fabric/simple
/obj/item/resurgence_fabric/advanced
/obj/item/resurgence_fabric/elegant

// Floor Tiles
/obj/item/stack/tile/plasteel
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

- **Plasteel** is crafted at the Forge (2 Metal + 1 Coal), requires advanced_metallurgy research
- **Rope** can be made from Cloth (3), Cotton (8), or Vines (3)
- **Ash Plating** is a high-tier component for advanced tools
- **Faith Fabrics** provide passive faith bonuses when attached to clothing
- Metal Rods use the existing `/obj/item/stack/rods` type
- All ore smelting happens at the Forge
- All textile processing happens at the Loom
- General component crafting happens at the Crafting Table

---

# Planned Materials (Not Yet Implemented)

The following materials are planned but have not been coded yet.

## Planned Advanced Materials

| Name | Planned Type Path | Notes |
|------|-------------------|-------|
| Reinforced Glass | `/obj/item/stack/sheet/rglass` | Glass + Metal Rod combination (exists in base game) |

## Recently Implemented

| Name | Type Path | Notes |
|------|-----------|-------|
| Basic Microchip | `/obj/item/resurgence_component/microchip` | For electronics |
| Advanced Microchip | `/obj/item/resurgence_component/microchip/advanced` | For advanced electronics |
| Super Microchip | `/obj/item/resurgence_component/microchip/super` | For high-tier electronics |

---

## Removed Components (Use Base Game Materials Instead)
- ~~wooden_plank~~ -> Use `/obj/item/stack/sheet/mineral/wood`
- ~~metal_plate~~ -> Use `/obj/item/stack/sheet/metal`
- ~~leather_strip~~ -> Use `/obj/item/stack/sheet/leather`
- ~~glass_lens~~ -> Use `/obj/item/stack/sheet/glass`
- ~~reinforced_plate~~ -> Use `/obj/item/stack/sheet/plasteel`
- ~~metal_frame~~ -> Removed
- ~~gear_assembly~~ -> Removed
- ~~carved_ornament~~ -> Removed
- ~~woven_tapestry~~ -> Removed
