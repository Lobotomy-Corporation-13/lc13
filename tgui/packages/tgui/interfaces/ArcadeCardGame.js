/**
 * @file
 * @copyright 2024
 * @license MIT
 *
 * Fixer's Gambit - Deckbuilder card
 * combat arcade. Clear a Syndicate
 * hideout, 8 floors.
 */

import { Component, createRef } from 'inferno';
import { useBackend } from '../backend';
import { Window } from '../layouts';
import {
  acquireHotKey,
  releaseHotKey,
} from '../hotkeys';

// =========================================
// Constants
// =========================================

const CW = 520;
const CH = 480;
const CARD_W = 72;
const CARD_H = 100;
const START_HP = 60;
const START_LIGHT = 3;
const DRAW_N = 5;

const GS_TITLE = 0;
const GS_COMBAT = 1;
const GS_ANIM = 2;
const GS_REWARD = 3;
const GS_AUGMENT = 4;
const GS_VICTORY = 5;
const GS_DEFEAT = 6;
const GS_TARGETING = 7;
const GS_MAP = 8;
const GS_REST = 9;
const GS_SHOP = 10;
const GS_EVENT = 11;
const GS_CHARSEL = 12;
const NUM_ROWS = 12;

// Card upgrade bonuses
const UPGRADES = {
  slash: { dmg: 9, desc: 'Deal 9 damage.' },
  guard: { blk: 8, desc: 'Gain 8 block.' },
  heavy_swing: {
    dmg: 20, desc: 'Deal 20 damage.',
  },
  quick_jab: {
    dmg: 5, desc: 'Deal 5 damage.',
  },
  twin_strike: {
    dmg: 6, desc: 'Deal 6 damage twice.',
  },
  prosth_slam: {
    dmg: 14,
    desc: 'Deal 14. Apply 1 Vuln.',
  },
  nerve_strike: {
    dmg: 8,
    desc: 'Deal 8. Apply 1 Weak.',
  },
  shank: {
    dmg: 5, poison: 3,
    desc: 'Deal 5. Apply 3 Poison.',
  },
  eviscerate: {
    dmg: 32, desc: 'Deal 32 damage.',
  },
  iron_wall: {
    blk: 18, desc: 'Gain 18 block.',
  },
  parry: {
    blk: 11,
    desc: 'Gain 11 block. If foe\n'
      + 'attacks: +3 Strength.',
  },
  overclock: {
    light: 3,
    desc: 'Gain 3 Light this turn.',
  },
  sharpen: {
    str: 3, desc: 'Gain 3 Strength.',
  },
  toxic_cloud: {
    poisonAll: 6,
    desc: 'Apply 6 Poison to all.',
  },
};

// Event definitions
const EVENTS = {
  wounded_fixer: {
    title: 'Wounded Fixer',
    text: 'A fixer lies bleeding.\n'
      + 'They offer a card for help.',
    opt1: 'Help (-8 HP, gain card)',
    opt2: 'Ignore',
  },
  trap: {
    title: 'Booby Trap',
    text: 'A tripwire! React fast.',
    opt1: 'Dodge (lose random card)',
    opt2: 'Tank it (-12 HP)',
  },
  cache: {
    title: 'Hidden Cache',
    text: 'A stash behind a wall.',
    opt1: 'Take it (+40 Ahn)',
    opt2: 'Search deeper (+80 Ahn, -6 HP)',
  },
  merchant: {
    title: 'Black Market Dealer',
    text: 'Shady figure with wares.',
    opt1: 'Buy augment (-60 Ahn)',
    opt2: 'Walk away',
  },
  shrine: {
    title: 'Strange Shrine',
    text: 'An altar hums with energy.',
    opt1: 'Pray (+2 max HP)',
    opt2: 'Offer blood (-5 HP, +1 Str)',
  },
  gamble: {
    title: 'Fortune Wheel',
    text: 'A J Corp gambling device.',
    opt1: 'Spin (50%: +60 Ahn, 50%: -30)',
    opt2: 'Pass',
  },
};

const KEY_ENTER = 13;
const KEY_R = 82;
const KEY_ESC = 27;

// Card definitions: key -> data
const CARDS = {
  slash: {
    name: 'Slash', type: 'atk',
    cost: 1, dmg: 6,
    desc: 'Deal 6 damage.',
  },
  guard: {
    name: 'Guard', type: 'blk',
    cost: 1, blk: 5,
    desc: 'Gain 5 block.',
  },
  heavy_swing: {
    name: 'Heavy Swing', type: 'atk',
    cost: 2, dmg: 14,
    desc: 'Deal 14 damage.',
  },
  quick_jab: {
    name: 'Quick Jab', type: 'atk',
    cost: 0, dmg: 3,
    desc: 'Deal 3 damage.',
  },
  twin_strike: {
    name: 'Twin Strike', type: 'atk',
    cost: 1, dmg: 4, hits: 2,
    desc: 'Deal 4 damage twice.',
  },
  prosth_slam: {
    name: 'Prosth. Slam', type: 'atk',
    cost: 2, dmg: 10, vuln: 1,
    desc: 'Deal 10. Apply 1 Vuln.',
  },
  nerve_strike: {
    name: 'Nerve Strike', type: 'atk',
    cost: 1, dmg: 5, weak: 1,
    desc: 'Deal 5. Apply 1 Weak.',
  },
  shank: {
    name: 'Shank', type: 'atk',
    cost: 0, dmg: 3, poison: 2,
    desc: 'Deal 3. Apply 2 Poison.',
  },
  eviscerate: {
    name: 'Eviscerate', type: 'atk',
    cost: 3, dmg: 24,
    desc: 'Deal 24 damage.',
  },
  iron_wall: {
    name: 'Iron Wall', type: 'blk',
    cost: 2, blk: 12,
    desc: 'Gain 12 block.',
  },
  parry: {
    name: 'Parry', type: 'blk',
    cost: 1, blk: 7, parry: true,
    desc: 'Gain 7 block. If foe\n'
      + 'attacks: +3 Strength.',
  },
  overclock: {
    name: 'Overclock', type: 'skill',
    cost: 0, light: 2,
    desc: 'Gain 2 Light this turn.',
  },
  sharpen: {
    name: 'Sharpen', type: 'skill',
    cost: 1, str: 2,
    desc: 'Gain 2 Strength.',
  },
  toxic_cloud: {
    name: 'Toxic Cloud', type: 'skill',
    cost: 1, poisonAll: 4,
    desc: 'Apply 4 Poison to all.',
  },
};

// === Liu Associate cards ===
const LIU_CARDS = {
  flame_slash: {
    name: 'Flame Slash', type: 'atk',
    cost: 1, dmg: 7,
    desc: 'Deal 7 damage.',
  },
  liu_guard: {
    name: 'Iron Guard', type: 'blk',
    cost: 1, blk: 5,
    desc: 'Gain 5 block.',
  },
  ignite: {
    name: 'Ignite', type: 'atk',
    cost: 1, dmg: 3, burn: 3,
    desc: 'Deal 3. Apply 3 Burn.',
  },
  inferno_swing: {
    name: 'Inferno Swing', type: 'atk',
    cost: 2, dmg: 12, burn: 2,
    desc: 'Deal 12. Apply 2 Burn.',
  },
  blazing_rush: {
    name: 'Blazing Rush', type: 'atk',
    cost: 1, dmg: 5, hits: 2,
    desc: 'Deal 5 damage twice.',
  },
  flame_wall: {
    name: 'Flame Wall', type: 'blk',
    cost: 2, blk: 10, burn: 2,
    desc: 'Gain 10 block.\nApply 2 Burn to all.',
    burnAll: 2,
  },
  scorched_earth: {
    name: 'Scorched Earth', type: 'skill',
    cost: 1, burnAll: 4,
    desc: 'Apply 4 Burn to all.',
  },
  war_cry: {
    name: 'War Cry', type: 'skill',
    cost: 1, str: 2,
    desc: 'Gain 2 Strength.',
  },
  molten_armor: {
    name: 'Molten Armor', type: 'blk',
    cost: 1, blk: 8,
    desc: 'Gain 8 block.',
  },
  eruption: {
    name: 'Eruption', type: 'atk',
    cost: 3, dmg: 20, burn: 5,
    desc: 'Deal 20. Apply 5 Burn.',
  },
  forge: {
    name: 'Forge', type: 'skill',
    cost: 0, blk: 3, str: 1,
    desc: 'Gain 3 block, 1 Str.',
  },
  wildfire: {
    name: 'Wildfire', type: 'atk',
    cost: 2, dmg: 8, burnAll: 3,
    desc: 'Deal 8. Burn all for 3.',
  },
};

// === Shi Assassin cards ===
const SHI_CARDS = {
  silent_blade: {
    name: 'Silent Blade', type: 'atk',
    cost: 1, dmg: 5,
    desc: 'Deal 5 damage.',
  },
  fade: {
    name: 'Fade', type: 'blk',
    cost: 1, blk: 5,
    desc: 'Gain 5 block.',
  },
  needle_throw: {
    name: 'Needle Throw', type: 'skill',
    cost: 1, needles: 2,
    desc: 'Add 2 Needles to hand.',
  },
  mark_target: {
    name: 'Mark Target', type: 'atk',
    cost: 1, dmg: 3, poison: 3,
    desc: 'Deal 3. Apply 3 Poison.',
  },
  needle: {
    name: 'Needle', type: 'atk',
    cost: 0, dmg: 3, generated: true,
    desc: 'Deal 3 damage.',
  },
  throat_slit: {
    name: 'Throat Slit', type: 'atk',
    cost: 2, dmg: 14,
    desc: 'Deal 14 damage.',
  },
  shadow_step: {
    name: 'Shadow Step', type: 'blk',
    cost: 1, blk: 6, needles: 1,
    desc: 'Gain 6 block.\nAdd 1 Needle.',
  },
  poison_vial: {
    name: 'Poison Vial', type: 'skill',
    cost: 1, poisonAll: 3,
    desc: 'Apply 3 Poison to all.',
  },
  fan_needles: {
    name: 'Fan of Needles', type: 'skill',
    cost: 1, needles: 4,
    desc: 'Add 4 Needles to hand.',
  },
  vanish: {
    name: 'Vanish', type: 'blk',
    cost: 1, blk: 12,
    desc: 'Gain 12 block.',
  },
  death_mark: {
    name: 'Death Mark', type: 'atk',
    cost: 1, dmg: 4, poison: 4,
    desc: 'Deal 4. Apply 4 Poison.',
  },
  backstab: {
    name: 'Backstab', type: 'atk',
    cost: 0, dmg: 8, exhaust: true,
    desc: 'Deal 8. Exhaust.',
  },
  envenom: {
    name: 'Envenom', type: 'skill',
    cost: 2, poisonAll: 6,
    desc: 'Apply 6 Poison to all.',
  },
  blade_flurry: {
    name: 'Blade Flurry', type: 'atk',
    cost: 2, dmg: 3, hits: 4,
    desc: 'Deal 3 damage 4 times.',
  },
};

// === Blade Lineage cards ===
const BLADE_CARDS = {
  sword_draw: {
    name: 'Sword Draw', type: 'atk',
    cost: 1, dmg: 6,
    desc: 'Deal 6 damage.',
  },
  deflect: {
    name: 'Deflect', type: 'blk',
    cost: 1, blk: 5,
    desc: 'Gain 5 block.',
  },
  enter_striking: {
    name: 'Striking Stance', type: 'skill',
    cost: 1, stance: 'striking',
    desc: 'Enter Striking.\n1.5x dmg dealt/taken.',
  },
  enter_guarding: {
    name: 'Guarding Stance', type: 'skill',
    cost: 1, stance: 'guarding',
    desc: 'Enter Guarding.\n0.5x dmg, +4 blk/turn.',
  },
  moonlight_slash: {
    name: 'Moonlight Slash', type: 'atk',
    cost: 2, dmg: 16,
    desc: 'Deal 16 damage.',
  },
  cloud_step: {
    name: 'Cloud Step', type: 'blk',
    cost: 1, blk: 7, stance: 'flowing',
    desc: 'Gain 7 block.\nEnter Flowing.',
  },
  blade_dance: {
    name: 'Blade Dance', type: 'atk',
    cost: 1, dmg: 4, hits: 3,
    desc: 'Deal 4 damage 3 times.',
  },
  whirlwind_cut: {
    name: 'Whirlwind Cut', type: 'atk',
    cost: 2, dmg: 8, hitsAll: true,
    desc: 'Deal 8 to ALL enemies.',
  },
  meditation: {
    name: 'Meditation', type: 'skill',
    cost: 1, blk: 4, stance: 'guarding',
    desc: 'Gain 4 block.\nEnter Guarding.',
  },
  focused_strike: {
    name: 'Focused Strike', type: 'atk',
    cost: 1, dmg: 10,
    stanceBonus: true,
    desc: 'Deal 10. +6 in Striking.',
  },
  swift_blade: {
    name: 'Swift Blade', type: 'atk',
    cost: 0, dmg: 4,
    desc: 'Deal 4 damage.',
  },
  inner_peace: {
    name: 'Inner Peace', type: 'skill',
    cost: 1, stance: 'flowing', light: 1,
    desc: 'Enter Flowing.\nGain 1 Light.',
  },
  lotus_strike: {
    name: 'Lotus Strike', type: 'atk',
    cost: 2, dmg: 12, stance: 'flowing',
    desc: 'Deal 12.\nEnter Flowing.',
  },
  resolve: {
    name: 'Resolve', type: 'skill',
    cost: 1, str: 2, stance: 'striking',
    desc: 'Gain 2 Str.\nEnter Striking.',
  },
};

// Merge all character cards into CARDS
Object.assign(
  CARDS,
  LIU_CARDS, SHI_CARDS, BLADE_CARDS
);

// Character definitions
const CHARACTERS = {
  liu: {
    name: 'Liu Associate',
    desc: 'Flame-wreathed warrior.\n'
      + 'Burn enemies over time.\n'
      + 'Heals 4 HP after combat.',
    clr: '#cc6633',
    passive: 'liu',
    starter: [
      'flame_slash', 'flame_slash',
      'flame_slash', 'flame_slash',
      'flame_slash',
      'liu_guard', 'liu_guard',
      'liu_guard', 'liu_guard',
      'ignite',
    ],
    rewards: [
      'inferno_swing', 'blazing_rush',
      'flame_wall', 'scorched_earth',
      'war_cry', 'molten_armor',
      'eruption', 'forge',
      'wildfire', 'heavy_swing',
      'iron_wall', 'overclock',
    ],
  },
  shi: {
    name: 'Shi Assassin',
    desc: 'Silent killer.\n'
      + 'Poison and Needle swarm.\n'
      + 'Draw 2 extra on turn 1.',
    clr: '#6644aa',
    passive: 'shi',
    starter: [
      'silent_blade', 'silent_blade',
      'silent_blade', 'silent_blade',
      'fade', 'fade', 'fade', 'fade',
      'needle_throw', 'mark_target',
    ],
    rewards: [
      'throat_slit', 'shadow_step',
      'poison_vial', 'fan_needles',
      'vanish', 'death_mark',
      'backstab', 'envenom',
      'blade_flurry', 'shank',
      'nerve_strike', 'overclock',
    ],
  },
  blade: {
    name: 'Blade Lineage',
    desc: 'Disciplined swordsman.\n'
      + 'Switch stances for power.\n'
      + '+2 Light leaving Guard.',
    clr: '#3388aa',
    passive: 'blade',
    starter: [
      'sword_draw', 'sword_draw',
      'sword_draw', 'sword_draw',
      'deflect', 'deflect',
      'deflect', 'deflect',
      'enter_striking',
      'enter_guarding',
    ],
    rewards: [
      'moonlight_slash', 'cloud_step',
      'blade_dance', 'whirlwind_cut',
      'meditation', 'focused_strike',
      'swift_blade', 'inner_peace',
      'lotus_strike', 'resolve',
      'iron_wall', 'overclock',
    ],
  },
};

// Enemy definitions
const ENEMIES = {
  sewer_rat: {
    name: 'Sewer Rat', clr: '#886644',
    intents: [
      { t: 'atk', v: 4 },
      { t: 'atk', v: 4 },
      { t: 'atk', v: 6 },
    ],
  },
  rat_swarm: {
    name: 'Rat Swarm', clr: '#887755',
    intents: [
      { t: 'atk', v: 3 },
      { t: 'atk', v: 3 },
      { t: 'buff', v: 1 },
    ],
  },
  street_thug: {
    name: 'Street Thug', clr: '#556677',
    intents: [
      { t: 'atk', v: 7 },
      { t: 'blk', v: 6 },
      { t: 'atk', v: 9 },
    ],
  },
  knife_runner: {
    name: 'Knife Runner', clr: '#667755',
    intents: [
      { t: 'atk', v: 5 },
      { t: 'atk', v: 5 },
      { t: 'atk', v: 5 },
      { t: 'debuf', v: 1 },
    ],
  },
  enforcer: {
    name: 'Enforcer', clr: '#775544',
    intents: [
      { t: 'atk', v: 10 },
      { t: 'blk', v: 10 },
      { t: 'atk', v: 12 },
      { t: 'buff', v: 2 },
    ],
  },
  pipe_bomber: {
    name: 'Pipe Bomber', clr: '#886655',
    intents: [
      { t: 'debuf', v: 1 },
      { t: 'atk', v: 15 },
      { t: 'atk', v: 8 },
    ],
  },
  aug_bruiser: {
    name: 'Aug. Bruiser', clr: '#665577',
    intents: [
      { t: 'atk', v: 12 },
      { t: 'atk', v: 12 },
      { t: 'blk', v: 15 },
      { t: 'buff', v: 2 },
    ],
  },
  lieutenant: {
    name: 'Lieutenant', clr: '#556688',
    intents: [
      { t: 'atk', v: 9 },
      { t: 'debuf', v: 1 },
      { t: 'atk', v: 14 },
      { t: 'blk', v: 8 },
    ],
  },
  thumb_capo: {
    name: 'Thumb Capo', clr: '#aa7733',
    intents: [
      { t: 'atk', v: 10 },
      { t: 'blk', v: 12 },
      { t: 'atk', v: 14 },
      { t: 'buff', v: 2 },
    ],
    phase2: [
      { t: 'atk', v: 16 },
      { t: 'debuf', v: 1 },
      { t: 'atk', v: 20 },
      { t: 'atk', v: 12 },
    ],
    phase2hp: 0.45,
  },
};

// Augmentation definitions
const AUGS = {
  reinforced: {
    name: 'Reinforced Plating',
    desc: 'Start combat with 5 Block',
  },
  optical: {
    name: 'Optical Implant',
    desc: 'Draw 1 extra card/turn',
  },
  adrenal: {
    name: 'Adrenal Pump',
    desc: '+1 Light per turn',
  },
  prosth_arm: {
    name: 'Prosthetic Arm',
    desc: 'Attacks deal +2 damage',
  },
  subdermal: {
    name: 'Subdermal Armor',
    desc: 'Take 1 less damage (min 1)',
  },
  toxin_filter: {
    name: 'Toxin Filter',
    desc: 'Remove 1 debuff at turn start',
  },
  regenerator: {
    name: 'Regenerator',
    desc: 'Heal 2 HP after each combat',
  },
  reflexes: {
    name: 'Overclocked Reflexes',
    desc: 'First card each turn costs 0',
  },
};

// Card type colors
const CLR_ATK = '#cc3333';
const CLR_BLK = '#3366cc';
const CLR_SKL = '#33aa55';

// =========================================
// Game Engine
// =========================================

class CardEngine {
  constructor(canvas, act) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.act = act;
    this.state = GS_TITLE;
    this.rafId = null;
    this.lastTime = 0;

    // Static data from DM
    this.mapData = [];
    this.floorData = [];
    this.rewardData = [];
    this.augmentData = [];

    // Run state
    this.floor = 0;
    this.hp = START_HP;
    this.maxHp = START_HP;
    this.block = 0;
    this.light = START_LIGHT;
    this.maxLight = START_LIGHT;
    this.str = 0;
    this.vuln = 0;
    this.weak = 0;
    this.score = 0;
    this.augments = [];
    this.firstCard = true;

    // Deck
    this.deck = [];
    this.drawPile = [];
    this.discardPile = [];
    this.hand = [];

    // Enemies
    this.enemies = [];

    // UI state
    this.hoverCard = -1;
    this.selectedCard = -1;
    this.hoverEnemy = -1;
    this.rewardOpts = [];
    this.augOpts = [];
    this.augIdx = 0;

    // Animations
    this.anims = [];
    this.animCb = null;
    this.cardAnims = [];
    this.shake = 0;

    // Character
    this.charKey = null;
    this.charDef = null;
    this.stance = 'flowing';
    this.turnNum = 0;

    // Drag state
    this.dragging = false;
    this.dragCard = -1;
    this.dragX = 0;
    this.dragY = 0;
    this.dragStartX = 0;
    this.dragStartY = 0;

    // Deck viewer
    this.showDeck = false;
    this.deckScroll = 0;

    // Shop removal cost tracker
    this.removeCount = 0;

    // Map navigation
    this.mapRow = 0;
    this.mapNode = 0;
    this.curNode = null;
    this.hoverNode = -1;
    this.mapScroll = 0;
    this.visited = {};

    // Rest/Shop/Event state
    this.restSel = 0;
    this.shopSel = 0;
    this.eventSel = 0;
    this.upgradeSel = 0;
    this.upgradeMode = false;

    // Leaderboard
    this.leaderboard = [];

    // Mouse
    this.mx = 0;
    this.my = 0;
  }

  loadData(sd) {
    this.mapData = sd.map || [];
  }

  // ==================
  // RUN MANAGEMENT
  // ==================

  selectChar(key) {
    this.charKey = key;
    this.charDef = CHARACTERS[key];
    this.startRun();
  }

  startRun() {
    this.floor = 0;
    this.hp = START_HP;
    this.maxHp = START_HP;
    this.block = 0;
    this.str = 0;
    this.vuln = 0;
    this.weak = 0;
    this.score = 0;
    this.maxLight = START_LIGHT;
    this.augments = [];
    this.stance = 'flowing';
    this.turnNum = 0;
    // Build character starter deck
    if (this.charDef) {
      this.deck = this.charDef.starter
        .slice();
    } else {
      this.deck = [
        'slash', 'slash', 'slash',
        'slash', 'slash',
        'guard', 'guard', 'guard',
        'guard', 'guard',
      ];
    }
    this.ahn = 0;
    this.mapRow = 0;
    this.mapNode = 0;
    this.visited = {};
    this.removeCount = 0;
    this.showDeck = false;
    this.state = GS_MAP;
  }

  enterNode(row, nodeIdx) {
    this.mapRow = row;
    this.mapNode = nodeIdx;
    const rowData = this.mapData[row];
    if (!rowData) return;
    this.curNode = rowData[nodeIdx];
    if (!this.curNode) return;
    const key = row + ',' + nodeIdx;
    this.visited[key] = true;

    const ntype = this.curNode.type;
    if (ntype === 'combat'
      || ntype === 'elite'
      || ntype === 'boss') {
      this.startCombat(this.curNode);
    } else if (ntype === 'rest') {
      this.restSel = 0;
      this.upgradeMode = false;
      this.state = GS_REST;
    } else if (ntype === 'shop') {
      this.shopSel = 0;
      this.state = GS_SHOP;
    } else if (ntype === 'event') {
      this.eventSel = -1;
      this.state = GS_EVENT;
    }
  }

  startCombat(node) {
    const fd = node.enemies;
    if (!fd) return;
    this.enemies = [];
    for (let i = 0; i < fd.length; i++) {
      const e = fd[i];
      const def = ENEMIES[e.type];
      if (!def) continue;
      this.enemies.push({
        type: e.type,
        name: def.name,
        clr: def.clr,
        hp: e.hp,
        maxHp: e.hp,
        block: 0,
        str: 0,
        vuln: 0,
        weak: 0,
        poison: 0,
        burn: 0,
        intIdx: 0,
        intents: def.intents,
        phase2: def.phase2 || null,
        phase2hp: def.phase2hp || 0,
        inPhase2: false,
      });
    }
    // Augment: reinforced plating
    this.block = this.hasAug('reinforced')
      ? 5 : 0;
    // Shuffle deck into draw pile
    this.drawPile = this.deck.slice();
    this.shuffle(this.drawPile);
    this.discardPile = [];
    this.hand = [];
    this.firstCard = true;
    this.startTurn();
  }

  startTurn() {
    // Reset block
    this.block = this.hasAug('reinforced')
      && this.block === 0 ? 5 : 0;
    // Reset light
    this.light = this.maxLight
      + (this.hasAug('adrenal') ? 1 : 0);
    // Tick player statuses
    if (this.vuln > 0) this.vuln--;
    if (this.weak > 0) this.weak--;
    // Toxin filter
    if (this.hasAug('toxin_filter')) {
      if (this.vuln > 0) this.vuln--;
      else if (this.weak > 0) this.weak--;
    }
    // Tick enemy statuses
    for (let i = 0;
      i < this.enemies.length; i++) {
      const e = this.enemies[i];
      if (e.hp <= 0) continue;
      if (e.poison > 0) {
        e.hp -= e.poison;
        e.poison--;
        this.addAnim(
          'dmg', this.enemyX(i),
          100, e.poison + 1, '#44cc44'
        );
        if (e.hp <= 0) {
          this.score += 20;
        }
      }
      if (e.vuln > 0) e.vuln--;
      if (e.weak > 0) e.weak--;
      e.block = 0;
      // Boss phase check
      if (e.phase2 && !e.inPhase2
        && e.hp <= e.maxHp * e.phase2hp) {
        e.inPhase2 = true;
        e.intents = e.phase2;
        e.intIdx = 0;
      }
    }
    // Check if poison killed all enemies
    const allDead = !this.enemies.some(
      e => e.hp > 0
    );
    if (allDead) {
      this.checkCombatEnd();
      return;
    }
    // Burn ticking (like poison)
    for (let i = 0;
      i < this.enemies.length; i++) {
      const e = this.enemies[i];
      if (e.hp <= 0) continue;
      if (e.burn > 0) {
        e.hp -= e.burn;
        e.burn--;
        this.addAnim(
          'dmg', this.enemyX(i),
          100, e.burn + 1, '#ff6633'
        );
        if (e.hp <= 0) this.score += 20;
      }
    }
    // Liu burn self-damage
    if (this.charKey === 'liu') {
      const totalBurn = this.enemies
        .reduce(
          (s, e) => s + (e.burn || 0), 0
        );
      if (totalBurn > 0) {
        this.hp -= 1;
      }
    }
    // Re-check deaths after burn
    const allDead2 = !this.enemies.some(
      e => e.hp > 0
    );
    if (allDead2) {
      this.checkCombatEnd();
      return;
    }
    // Blade Lineage: guarding gives block
    if (this.stance === 'guarding') {
      this.block += 4;
    }
    this.turnNum++;
    this.firstCard = true;
    // Draw cards
    let n = DRAW_N
      + (this.hasAug('optical') ? 1 : 0);
    // Shi: extra draw on turn 1
    if (this.charKey === 'shi'
      && this.turnNum === 1) {
      n += 2;
    }
    this.drawCards(n);
    this.state = GS_COMBAT;
  }

  drawCards(n) {
    for (let i = 0; i < n; i++) {
      if (this.hand.length >= 10) break;
      if (this.drawPile.length === 0) {
        if (this.discardPile.length === 0) {
          break;
        }
        this.drawPile = this.discardPile
          .slice();
        this.shuffle(this.drawPile);
        this.discardPile = [];
      }
      const key = this.drawPile.pop();
      this.hand.push(key);
      // Draw animation
      this.cardAnims.push({
        idx: this.hand.length - 1,
        scale: 0.3,
        t: 0,
        dur: 0.6 + i * 0.08,
      });
    }
    this.act('sfx', { s: 'card' });
  }

  // ==================
  // CARD PLAY
  // ==================

  playCard(ci, ti) {
    const key = this.hand[ci];
    const card = this.getCard(key);
    if (!card) return;
    let cost = card.cost;
    // Reflexes: first card free
    if (this.firstCard
      && this.hasAug('reflexes')) {
      cost = 0;
    }
    if (this.light < cost) return;
    this.light -= cost;
    this.firstCard = false;

    // Remove from hand
    this.hand.splice(ci, 1);
    // Exhaust or discard
    if (card.exhaust) {
      // Exhausted cards don't go to discard
    } else {
      this.discardPile.push(key);
    }

    // Stance multiplier for damage
    let stanceDmgMult = 1;
    if (this.stance === 'striking') {
      stanceDmgMult = 1.5;
    }
    if (this.stance === 'guarding') {
      stanceDmgMult = 0.5;
    }

    // Resolve effects
    if (card.type === 'atk') {
      // hitsAll: damage every enemy
      if (card.hitsAll) {
        for (let ei = 0;
          ei < this.enemies.length; ei++) {
          if (this.enemies[ei].hp <= 0) {
            continue;
          }
          let dmg = card.dmg + this.str;
          if (this.hasAug('prosth_arm')) {
            dmg += 2;
          }
          dmg = Math.floor(
            dmg * stanceDmgMult
          );
          if (this.weak > 0) {
            dmg = Math.floor(dmg * 0.75);
          }
          if (this.enemies[ei].vuln > 0) {
            dmg = Math.floor(dmg * 1.5);
          }
          this.damageEnemy(ei, dmg);
        }
      } else {
        const target = this.enemies[ti];
        if (!target
          || target.hp <= 0) return;
        const hits = card.hits || 1;
        for (let h = 0; h < hits; h++) {
          let dmg = card.dmg + this.str;
          if (this.hasAug('prosth_arm')) {
            dmg += 2;
          }
          // Stance bonus
          if (card.stanceBonus
            && this.stance === 'striking') {
            dmg += 6;
          }
          dmg = Math.floor(
            dmg * stanceDmgMult
          );
          if (this.weak > 0) {
            dmg = Math.floor(dmg * 0.75);
          }
          if (target.vuln > 0) {
            dmg = Math.floor(dmg * 1.5);
          }
          this.damageEnemy(ti, dmg);
        }
        if (card.vuln) {
          target.vuln += card.vuln;
        }
        if (card.weak) {
          target.weak += card.weak;
        }
        if (card.poison) {
          target.poison += card.poison;
        }
        if (card.burn) {
          target.burn += card.burn;
        }
      }
      this.act('sfx', { s: 'hit' });
      this.addAnim(
        'slash', this.enemyX(
          card.hitsAll ? 0 : ti
        ), 90, 0, CLR_ATK
      );
    }

    if (card.type === 'blk') {
      this.block += (card.blk || 0);
      if (card.parry) {
        const anyAtk = this.enemies.some(
          e => e.hp > 0
            && e.intents[
              e.intIdx % e.intents.length
            ].t === 'atk'
        );
        if (anyAtk) this.str += 3;
      }
      this.act('sfx', { s: 'block' });
      this.addAnim(
        'shield', CW / 2, 210,
        card.blk || 0, CLR_BLK
      );
    }

    // Common effects for all card types
    if (card.light) {
      this.light += card.light;
    }
    if (card.str) this.str += card.str;
    if (card.poisonAll) {
      for (let i = 0;
        i < this.enemies.length; i++) {
        if (this.enemies[i].hp > 0) {
          this.enemies[i].poison
            += card.poisonAll;
        }
      }
    }
    if (card.burnAll) {
      for (let i = 0;
        i < this.enemies.length; i++) {
        if (this.enemies[i].hp > 0) {
          this.enemies[i].burn
            += card.burnAll;
        }
      }
    }
    // Needle generation
    if (card.needles) {
      for (let ni = 0;
        ni < card.needles; ni++) {
        if (this.hand.length < 10) {
          this.hand.push('needle');
        }
      }
    }
    // Stance switching
    if (card.stance) {
      const oldStance = this.stance;
      this.stance = card.stance;
      // Blade: +2 Light leaving guarding
      if (oldStance === 'guarding'
        && card.stance !== 'guarding'
        && this.charKey === 'blade') {
        this.light += 2;
      }
    }

    if (card.type === 'skill'
      && !card.blk) {
      this.act('sfx', { s: 'card' });
      this.addAnim(
        'sparkle', CW / 2, 200,
        0, CLR_SKL
      );
    }

    this.selectedCard = -1;
    this.checkCombatEnd();
  }

  endTurn() {
    // Discard hand
    for (let i = 0;
      i < this.hand.length; i++) {
      this.discardPile.push(this.hand[i]);
    }
    this.hand = [];

    // Check if all enemies already dead
    const allDead = !this.enemies.some(
      e => e.hp > 0
    );
    if (allDead) {
      this.checkCombatEnd();
      return;
    }

    // Enemy intents execute
    this.state = GS_ANIM;
    this.execEnemies(0);
  }

  execEnemies(idx) {
    if (idx >= this.enemies.length) {
      if (this.hp <= 0) {
        this.state = GS_DEFEAT;
        this.act('died');
        return;
      }
      this.startTurn();
      return;
    }
    const e = this.enemies[idx];
    if (e.hp <= 0) {
      this.execEnemies(idx + 1);
      return;
    }
    const intent = e.intents[
      e.intIdx % e.intents.length
    ];
    e.intIdx++;

    switch (intent.t) {
      case 'atk': {
        let dmg = intent.v + e.str;
        if (e.weak > 0) {
          dmg = Math.floor(dmg * 0.75);
        }
        if (this.vuln > 0) {
          dmg = Math.floor(dmg * 1.5);
        }
        // Striking: take 1.5x damage
        if (this.stance === 'striking') {
          dmg = Math.floor(dmg * 1.5);
        }
        if (this.hasAug('subdermal')) {
          dmg = Math.max(1, dmg - 1);
        }
        // Apply to block first
        if (this.block > 0) {
          if (dmg <= this.block) {
            this.block -= dmg;
            dmg = 0;
          } else {
            dmg -= this.block;
            this.block = 0;
          }
        }
        this.hp -= dmg;
        if (dmg > 0) {
          this.shake = 0.2;
          this.act('sfx', { s: 'hurt' });
          this.addAnim(
            'dmg', CW / 2, 210,
            dmg, '#ff4444'
          );
        }
        break;
      }
      case 'blk':
        e.block += intent.v;
        break;
      case 'buff':
        e.str += intent.v;
        break;
      case 'debuf':
        this.vuln += intent.v;
        break;
      default: break;
    }

    // Delay then next enemy
    setTimeout(
      () => this.execEnemies(idx + 1),
      350
    );
  }

  damageEnemy(idx, dmg) {
    const e = this.enemies[idx];
    if (e.block > 0) {
      if (dmg <= e.block) {
        e.block -= dmg;
        dmg = 0;
      } else {
        dmg -= e.block;
        e.block = 0;
      }
    }
    e.hp -= dmg;
    if (dmg > 0) {
      this.addAnim(
        'dmg', this.enemyX(idx), 80,
        dmg, '#ffcc44'
      );
    }
    if (e.hp <= 0) {
      e.hp = 0;
      this.score += 20;
      this.act('sfx', { s: 'kill' });
    }
  }

  checkCombatEnd() {
    const alive = this.enemies.some(
      e => e.hp > 0
    );
    if (!alive) {
      this.score += 100;
      const isElite = this.curNode
        && this.curNode.type === 'elite';
      this.ahn += isElite ? 40 : 20;
      // Regenerator augment
      if (this.hasAug('regenerator')) {
        this.hp = Math.min(
          this.maxHp, this.hp + 2
        );
      }
      // Liu passive: heal 4 after combat
      if (this.charKey === 'liu') {
        this.hp = Math.min(
          this.maxHp, this.hp + 4
        );
      }
      if (this.curNode
        && this.curNode.type === 'boss') {
        this.score += 200
          + this.hp * 2;
        this.state = GS_VICTORY;
        this.act('submit_score', {
          score: this.score,
        });
      } else {
        this.showReward();
      }
    }
  }

  showReward() {
    // Use character reward pool
    if (this.charDef
      && this.charDef.rewards) {
      const pool = this.charDef.rewards
        .slice();
      this.rewardOpts = [];
      for (let i = 0; i < 3
        && pool.length > 0; i++) {
        const ri = Math.floor(
          Math.random() * pool.length
        );
        this.rewardOpts.push(
          pool.splice(ri, 1)[0]
        );
      }
    } else if (this.curNode
      && this.curNode.rewards) {
      this.rewardOpts = this.curNode.rewards;
    } else {
      this.rewardOpts = [];
    }
    this.state = GS_REWARD;
  }

  pickReward(idx) {
    if (idx >= 0
      && idx < this.rewardOpts.length) {
      this.deck.push(this.rewardOpts[idx]);
    }
    this.advanceToMap();
  }

  advanceToMap() {
    // Move to next row on the map
    this.mapRow++;
    if (this.mapRow >= NUM_ROWS) {
      this.score += 200 + this.hp * 2;
      this.state = GS_VICTORY;
      this.act('submit_score', {
        score: this.score,
      });
    } else {
      this.state = GS_MAP;
    }
  }

  hasAug(key) {
    return this.augments.indexOf(key) >= 0;
  }

  // Get effective card data (with upgrades)
  getCard(key) {
    const base = key.replace('+', '');
    const card = CARDS[base];
    if (!card) return null;
    if (key.indexOf('+') < 0) return card;
    const upg = UPGRADES[base];
    if (!upg) return card;
    return Object.assign({}, card, upg, {
      name: card.name + '+',
    });
  }

  enemyX(idx) {
    const total = this.enemies.length;
    const spacing = Math.min(
      160, (CW - 40) / total
    );
    return CW / 2 - (total - 1)
      * spacing / 2 + idx * spacing;
  }

  // ==================
  // ANIMATIONS
  // ==================

  addAnim(type, x, y, val, clr) {
    this.anims.push({
      type, x, y, val, clr,
      t: 0, dur: 0.5,
    });
  }

  updateAnims(dt) {
    for (let i = this.anims.length - 1;
      i >= 0; i--) {
      this.anims[i].t += dt;
      if (this.anims[i].t
        >= this.anims[i].dur) {
        this.anims.splice(i, 1);
      }
    }
    // Card draw anims
    for (let i = this.cardAnims.length - 1;
      i >= 0; i--) {
      const ca = this.cardAnims[i];
      ca.t += dt;
      ca.scale = Math.min(
        1, 0.3 + (ca.t / ca.dur) * 0.7
      );
      if (ca.t >= ca.dur) {
        this.cardAnims.splice(i, 1);
      }
    }
    if (this.shake > 0) {
      this.shake -= dt;
    }
  }

  shuffle(arr) {
    for (let i = arr.length - 1;
      i > 0; i--) {
      const j = Math.floor(
        Math.random() * (i + 1)
      );
      const tmp = arr[i];
      arr[i] = arr[j];
      arr[j] = tmp;
    }
  }

  // ==================
  // RENDER
  // ==================

  start() {
    this.lastTime = performance.now();
    this.loop(this.lastTime);
  }

  stop() {
    if (this.rafId) {
      cancelAnimationFrame(this.rafId);
    }
  }

  loop(time) {
    const dt = Math.min(
      (time - this.lastTime) / 1000, 0.05
    );
    this.lastTime = time;
    this.updateAnims(dt);
    this.render();
    this.rafId = requestAnimationFrame(
      t => this.loop(t)
    );
  }

  render() {
    const ctx = this.ctx;
    ctx.fillStyle = '#0f0f18';
    ctx.fillRect(0, 0, CW, CH);

    if (this.state === GS_TITLE) {
      this.renderTitle();
      return;
    }
    if (this.state === GS_CHARSEL) {
      this.renderCharSel();
      return;
    }

    ctx.save();
    if (this.shake > 0) {
      ctx.translate(
        (Math.random() - 0.5) * 4, 0
      );
    }

    if (this.state === GS_COMBAT
      || this.state === GS_ANIM
      || this.state === GS_TARGETING) {
      this.renderCombat();
    }

    ctx.restore();

    if (this.state === GS_MAP) {
      this.renderMap();
    }
    if (this.state === GS_REWARD) {
      this.renderReward();
    }
    if (this.state === GS_AUGMENT) {
      this.renderAugPick();
    }
    if (this.state === GS_REST) {
      this.renderRest();
    }
    if (this.state === GS_SHOP) {
      this.renderShop();
    }
    if (this.state === GS_EVENT) {
      this.renderEvent();
    }
    if (this.state === GS_VICTORY) {
      this.renderVictory();
    }
    if (this.state === GS_DEFEAT) {
      this.renderDefeat();
    }

    // Floating anims
    this.renderAnims();
  }

  renderTitle() {
    const ctx = this.ctx;
    ctx.strokeStyle = '#aa6633';
    ctx.lineWidth = 2;
    ctx.strokeRect(
      10, 10, CW - 20, CH - 20
    );
    this.cText(
      "FIXER'S GAMBIT",
      '#aa6633', 18, -90
    );
    this.cText(
      'Syndicate Hideout Raid',
      '#777', 9, -66
    );
    this.cText(
      '8 floors. Build your deck.',
      '#aaa', 8, -42
    );
    this.cText(
      'Play cards with Light.',
      '#aaa', 8, -30
    );
    this.cText(
      'Defeat all enemies.',
      '#aaa', 8, -18
    );
    this.cText(
      'Click cards to play.',
      '#ccc', 8, 4
    );
    this.cText(
      'Click enemies to target.',
      '#ccc', 8, 16
    );
    this.cText(
      'Press ENTER to Start',
      '#44ff44', 10, 44
    );
    // Leaderboard
    this.cText(
      '-- LEADERBOARD --',
      '#ffaa44', 8, 68
    );
    const lb = this.leaderboard || [];
    if (!lb.length) {
      this.cText(
        'No scores yet', '#666', 7, 80
      );
    }
    for (let i = 0; i < lb.length
      && i < 5; i++) {
      const e = lb[i];
      const n = (e.name || '???')
        .substring(0, 10);
      this.cText(
        (i + 1) + '. ' + n
          + ' ' + (e.score || 0),
        '#ffff44', 7, 80 + i * 11
      );
    }
  }

  renderCombat() {
    const ctx = this.ctx;
    // Top HUD
    ctx.fillStyle = '#1a1a22';
    ctx.fillRect(0, 0, CW, 28);
    ctx.fillStyle = '#aaa';
    ctx.font = '9px monospace';
    ctx.fillText(
      'Row ' + (this.mapRow + 1)
        + '/' + NUM_ROWS,
      6, 18
    );
    ctx.fillText(
      'Draw:' + this.drawPile.length,
      120, 18
    );
    ctx.fillText(
      'Disc:' + this.discardPile.length,
      200, 18
    );
    ctx.fillStyle = '#ffcc44';
    ctx.fillText(
      'Score:' + this.score,
      CW - 80, 18
    );

    // Enemies
    this.renderEnemies();

    // Player stats bar
    this.renderPlayerBar();

    // Hand
    this.renderHand();

    // Drag targeting line
    if (this.dragging
      && this.dragCard >= 0) {
      const key = this.hand[this.dragCard];
      const card = this.getCard(key);
      if (card && card.type === 'atk') {
        ctx.strokeStyle = '#ff444488';
        ctx.lineWidth = 2;
        ctx.setLineDash([4, 4]);
        ctx.beginPath();
        ctx.moveTo(
          this.dragX, this.dragY
        );
        // Line from card to cursor pos
        ctx.lineTo(
          this.dragX,
          Math.min(this.dragY, 140)
        );
        ctx.stroke();
        ctx.setLineDash([]);
        ctx.lineWidth = 1;
      }
    }

    // End turn button
    if (this.state === GS_COMBAT) {
      this.renderEndTurn();
    }

    // Targeting prompt
    if (this.state === GS_TARGETING) {
      ctx.fillStyle = '#ffcc44';
      ctx.font = '10px monospace';
      ctx.fillText(
        'Click an enemy to target',
        CW / 2 - 75, 185
      );
    }
  }

  renderEnemies() {
    const ctx = this.ctx;
    for (let i = 0;
      i < this.enemies.length; i++) {
      const e = this.enemies[i];
      if (e.hp <= 0) continue;
      const x = this.enemyX(i);
      const y = 80;
      const w = 70;
      const h = 60;

      // Body
      const hover = i === this.hoverEnemy
        && this.state === GS_TARGETING;
      ctx.fillStyle = hover
        ? '#ffffff' : e.clr;
      ctx.fillRect(
        x - w / 2, y - h / 2, w, h
      );
      // Eyes
      ctx.fillStyle = '#ff3333';
      ctx.fillRect(
        x - 12, y - 8, 6, 6
      );
      ctx.fillRect(
        x + 6, y - 8, 6, 6
      );

      // Name
      ctx.fillStyle = '#ddd';
      ctx.font = '7px monospace';
      const nw = ctx.measureText(
        e.name
      ).width;
      ctx.fillText(
        e.name, x - nw / 2, y - h / 2 - 4
      );

      // HP bar
      const barW = 60;
      const barY = y + h / 2 + 4;
      ctx.fillStyle = '#333';
      ctx.fillRect(
        x - barW / 2, barY, barW, 6
      );
      ctx.fillStyle = '#cc3333';
      ctx.fillRect(
        x - barW / 2, barY,
        barW * (e.hp / e.maxHp), 6
      );
      ctx.fillStyle = '#fff';
      ctx.font = '7px monospace';
      ctx.fillText(
        e.hp + '/' + e.maxHp,
        x - 15, barY + 5
      );

      // Block
      if (e.block > 0) {
        ctx.fillStyle = '#3366cc';
        ctx.font = '8px monospace';
        ctx.fillText(
          'Blk:' + e.block,
          x - 15, barY + 16
        );
      }

      // Intent
      const intent = e.intents[
        e.intIdx % e.intents.length
      ];
      this.renderIntent(
        x, y + h / 2 + 22, intent, e
      );

      // Statuses
      let sx = x - 30;
      const ssy = barY + 28;
      if (e.str > 0) {
        ctx.fillStyle = '#ffaa44';
        ctx.fillText(
          'S' + e.str, sx, ssy
        );
        sx += 22;
      }
      if (e.vuln > 0) {
        ctx.fillStyle = '#ff6644';
        ctx.fillText(
          'V' + e.vuln, sx, ssy
        );
        sx += 22;
      }
      if (e.poison > 0) {
        ctx.fillStyle = '#44cc44';
        ctx.fillText(
          'P' + e.poison, sx, ssy
        );
        sx += 22;
      }
      if (e.burn > 0) {
        ctx.fillStyle = '#ff6633';
        ctx.fillText(
          'B' + e.burn, sx, ssy
        );
      }
    }
  }

  renderIntent(x, y, intent, e) {
    const ctx = this.ctx;
    ctx.font = '8px monospace';
    switch (intent.t) {
      case 'atk': {
        let d = intent.v + e.str;
        if (e.weak > 0) {
          d = Math.floor(d * 0.75);
        }
        ctx.fillStyle = '#ff4444';
        // Sword icon
        ctx.fillRect(x - 2, y - 6, 4, 12);
        ctx.fillRect(x - 6, y - 2, 12, 4);
        ctx.fillText(
          String(d), x + 10, y + 4
        );
        break;
      }
      case 'blk':
        ctx.fillStyle = '#4488cc';
        ctx.fillRect(
          x - 6, y - 6, 12, 12
        );
        ctx.fillText(
          String(intent.v), x + 10, y + 4
        );
        break;
      case 'buff':
        ctx.fillStyle = '#ffaa44';
        ctx.fillText(
          '+' + intent.v + ' Str',
          x - 12, y + 4
        );
        break;
      case 'debuf':
        ctx.fillStyle = '#ff6644';
        ctx.fillText(
          'Vuln', x - 10, y + 4
        );
        break;
      default: break;
    }
  }

  renderPlayerBar() {
    const ctx = this.ctx;
    const y = 195;
    ctx.fillStyle = '#1a1a22';
    ctx.fillRect(0, y, CW, 36);

    // HP
    ctx.fillStyle = '#333';
    ctx.fillRect(8, y + 6, 120, 10);
    const hpF = this.hp / this.maxHp;
    ctx.fillStyle = hpF > 0.5
      ? '#44aa44' : hpF > 0.25
        ? '#cccc44' : '#cc4444';
    ctx.fillRect(
      8, y + 6, 120 * hpF, 10
    );
    ctx.fillStyle = '#fff';
    ctx.font = '8px monospace';
    ctx.fillText(
      'HP:' + this.hp + '/'
        + this.maxHp,
      10, y + 14
    );

    // Block
    if (this.block > 0) {
      ctx.fillStyle = '#4488cc';
      ctx.fillText(
        'Blk:' + this.block,
        140, y + 14
      );
    }

    // Light
    ctx.fillStyle = '#ffcc44';
    ctx.fillText(
      'Light:' + this.light + '/'
        + (this.maxLight
          + (this.hasAug('adrenal')
            ? 1 : 0)),
      210, y + 14
    );

    // Strength
    if (this.str > 0) {
      ctx.fillStyle = '#ffaa44';
      ctx.fillText(
        'Str:' + this.str, 310, y + 14
      );
    }
    // Vuln/Weak
    if (this.vuln > 0) {
      ctx.fillStyle = '#ff6644';
      ctx.fillText(
        'Vuln:' + this.vuln,
        370, y + 14
      );
    }
    if (this.weak > 0) {
      ctx.fillStyle = '#cc66cc';
      ctx.fillText(
        'Weak:' + this.weak,
        430, y + 14
      );
    }

    // Stance (Blade Lineage)
    if (this.charKey === 'blade'
      && this.stance !== 'flowing') {
      const stClr = this.stance
        === 'striking'
        ? '#ff6644' : '#4488cc';
      ctx.fillStyle = stClr;
      ctx.fillText(
        'Stance:' + this.stance,
        310, y + 26
      );
    }

    // Character name
    if (this.charDef) {
      ctx.fillStyle = this.charDef.clr;
      ctx.fillText(
        this.charDef.name,
        CW - 100, y + 26
      );
    }

    // Augments
    ctx.fillStyle = '#888';
    ctx.font = '7px monospace';
    let ax = 8;
    for (let i = 0;
      i < this.augments.length; i++) {
      const a = AUGS[this.augments[i]];
      if (a) {
        ctx.fillText(
          '[' + a.name.substring(0, 8)
            + ']',
          ax, y + 28
        );
        ax += 65;
      }
    }
  }

  renderHand() {
    const ctx = this.ctx;
    const n = this.hand.length;
    if (n === 0) return;

    const fanY = 340;
    const fanCx = CW / 2;
    const maxW = CW - 40;
    const cardW = Math.min(
      CARD_W, (maxW - 20) / n
    );
    const totalW = cardW * n;
    const startX = fanCx - totalW / 2;

    for (let i = 0; i < n; i++) {
      const key = this.hand[i];
      const card = this.getCard(key);
      if (!card) continue;

      let cx = startX + i * cardW;
      let cy = fanY;
      let scale = 1;
      const sel = i === this.selectedCard;
      const hov = i === this.hoverCard;

      // Fan rotation
      const angle = (i - (n - 1) / 2)
        * 0.03;

      // Card draw animation
      const ca = this.cardAnims.find(
        a => a.idx === i
      );
      if (ca) {
        scale = ca.scale;
        cx = fanCx + (cx - fanCx) * scale;
        cy = fanY - 60 * (1 - scale)
          + 60 * scale;
      }

      // Dragging: follow mouse
      if (this.dragging
        && i === this.dragCard) {
        cx = this.dragX - CARD_W / 2;
        cy = this.dragY - CARD_H / 2;
        scale = 1.2;
      } else if (hov && !ca) {
        // Hover: lift and scale
        cy -= 40;
        scale = 1.4;
      }
      if (sel && !this.dragging) {
        cy -= 30;
      }

      const w = CARD_W * scale;
      const h = CARD_H * scale;
      const dx = cx + cardW / 2 - w / 2;
      const dy = cy;

      ctx.save();
      ctx.translate(
        dx + w / 2, dy + h / 2
      );
      ctx.rotate(hov ? 0 : angle);
      ctx.translate(
        -(dx + w / 2), -(dy + h / 2)
      );

      // Card bg
      let bgClr = '#333';
      if (card.type === 'atk') {
        bgClr = '#3a1515';
      }
      if (card.type === 'blk') {
        bgClr = '#15253a';
      }
      if (card.type === 'skill') {
        bgClr = '#153a20';
      }
      ctx.fillStyle = bgClr;
      ctx.fillRect(dx, dy, w, h);

      // Border
      ctx.strokeStyle = sel
        ? '#ffcc44' : hov
          ? '#ffffff' : '#555';
      ctx.lineWidth = sel || hov ? 2 : 1;
      ctx.strokeRect(dx, dy, w, h);
      ctx.lineWidth = 1;

      // Type bar
      let typeClr = CLR_ATK;
      if (card.type === 'blk') {
        typeClr = CLR_BLK;
      }
      if (card.type === 'skill') {
        typeClr = CLR_SKL;
      }
      ctx.fillStyle = typeClr;
      ctx.fillRect(
        dx, dy, w, 4 * scale
      );

      // Cost circle
      ctx.fillStyle = '#ffcc44';
      ctx.beginPath();
      ctx.arc(
        dx + 10 * scale,
        dy + 14 * scale,
        8 * scale, 0, Math.PI * 2
      );
      ctx.fill();
      ctx.fillStyle = '#000';
      ctx.font = Math.floor(
        9 * scale
      ) + 'px monospace';
      let costTxt = String(card.cost);
      if (this.firstCard
        && this.hasAug('reflexes')) {
        costTxt = '0';
      }
      ctx.fillText(
        costTxt,
        dx + 6 * scale,
        dy + 17 * scale
      );

      // Name
      ctx.fillStyle = '#ddd';
      ctx.font = Math.floor(
        8 * scale
      ) + 'px monospace';
      ctx.fillText(
        card.name,
        dx + 4 * scale,
        dy + 30 * scale
      );

      // Effect text (on hover)
      if ((hov || sel) && scale >= 1.2) {
        ctx.fillStyle = '#bbb';
        ctx.font = Math.floor(
          7 * scale
        ) + 'px monospace';
        const lines = card.desc.split('\n');
        for (let li = 0;
          li < lines.length; li++) {
          ctx.fillText(
            lines[li],
            dx + 4 * scale,
            dy + 44 * scale
              + li * 10 * scale
          );
        }
      }

      ctx.restore();
    }
  }

  renderEndTurn() {
    const ctx = this.ctx;
    const bw = 90;
    const bh = 28;
    const bx = CW / 2 - bw / 2;
    const by = CH - 36;
    ctx.fillStyle = '#aa6633';
    ctx.fillRect(bx, by, bw, bh);
    ctx.fillStyle = '#fff';
    ctx.font = '10px monospace';
    ctx.fillText(
      'END TURN', bx + 10, by + 18
    );
  }

  renderReward() {
    const ctx = this.ctx;
    ctx.fillStyle = 'rgba(0,0,0,0.8)';
    ctx.fillRect(0, 0, CW, CH);
    this.cText(
      'COMBAT CLEARED!',
      '#44ff44', 14, -120
    );
    this.cText(
      'Choose a card (or click Skip)',
      '#aaa', 9, -96
    );

    // 3 card options
    for (let i = 0;
      i < this.rewardOpts.length; i++) {
      const key = this.rewardOpts[i];
      const card = this.getCard(key);
      if (!card) continue;
      const x = 60 + i * 160;
      const y = 160;
      this.drawCardFull(x, y, card,
        i === this.hoverCard);
    }

    // Skip button
    ctx.fillStyle = '#555';
    ctx.fillRect(CW / 2 - 40, 380, 80, 28);
    ctx.fillStyle = '#ddd';
    ctx.font = '10px monospace';
    ctx.fillText('SKIP', CW / 2 - 14, 398);
  }

  renderAugPick() {
    const ctx = this.ctx;
    ctx.fillStyle = 'rgba(0,0,0,0.8)';
    ctx.fillRect(0, 0, CW, CH);
    this.cText(
      'CHOOSE AN AUGMENTATION',
      '#ffaa44', 14, -130
    );

    for (let i = 0;
      i < this.augOpts.length; i++) {
      const key = this.augOpts[i];
      const aug = AUGS[key];
      if (!aug) continue;
      const x = 40 + i * 160;
      const y = 170;
      const w = 140;
      const h = 100;
      const hov = i === this.hoverCard;
      ctx.fillStyle = hov
        ? '#2a3a2a' : '#1a2a1a';
      ctx.fillRect(x, y, w, h);
      ctx.strokeStyle = hov
        ? '#ffaa44' : '#555';
      ctx.lineWidth = hov ? 2 : 1;
      ctx.strokeRect(x, y, w, h);
      ctx.lineWidth = 1;
      ctx.fillStyle = '#ffaa44';
      ctx.font = '9px monospace';
      ctx.fillText(aug.name, x + 6, y + 18);
      ctx.fillStyle = '#ccc';
      ctx.font = '8px monospace';
      // Word wrap desc
      const words = aug.desc.split(' ');
      let line = '';
      let ly = y + 36;
      for (let wi = 0;
        wi < words.length; wi++) {
        if ((line + words[wi]).length > 20
          && line.length > 0) {
          ctx.fillText(line, x + 6, ly);
          ly += 12;
          line = words[wi];
        } else {
          line = line
            ? line + ' ' + words[wi]
            : words[wi];
        }
      }
      if (line) {
        ctx.fillText(line, x + 6, ly);
      }
    }
  }

  drawCardFull(x, y, card, hov) {
    const ctx = this.ctx;
    const w = 120;
    const h = 160;
    let bgClr = '#3a1515';
    if (card.type === 'blk') {
      bgClr = '#15253a';
    }
    if (card.type === 'skill') {
      bgClr = '#153a20';
    }
    ctx.fillStyle = bgClr;
    ctx.fillRect(x, y, w, h);
    ctx.strokeStyle = hov
      ? '#ffcc44' : '#555';
    ctx.lineWidth = hov ? 2 : 1;
    ctx.strokeRect(x, y, w, h);
    ctx.lineWidth = 1;

    // Cost
    ctx.fillStyle = '#ffcc44';
    ctx.beginPath();
    ctx.arc(
      x + 16, y + 20, 12, 0, Math.PI * 2
    );
    ctx.fill();
    ctx.fillStyle = '#000';
    ctx.font = '12px monospace';
    ctx.fillText(
      String(card.cost), x + 11, y + 24
    );

    // Name
    ctx.fillStyle = '#fff';
    ctx.font = '10px monospace';
    ctx.fillText(card.name, x + 6, y + 46);

    // Desc
    ctx.fillStyle = '#bbb';
    ctx.font = '9px monospace';
    const lines = card.desc.split('\n');
    for (let i = 0; i < lines.length; i++) {
      ctx.fillText(
        lines[i], x + 6, y + 66 + i * 14
      );
    }
  }

  renderVictory() {
    const ctx = this.ctx;
    ctx.fillStyle = 'rgba(0,0,0,0.7)';
    ctx.fillRect(0, 0, CW, CH);
    this.cText(
      'HIDEOUT CLEARED!', '#ffcc44', 16, -40
    );
    this.cText(
      'Score: ' + this.score,
      '#fff', 12, -10
    );
    this.cText(
      'Press R to play again',
      '#aaa', 9, 24
    );
  }

  renderDefeat() {
    const ctx = this.ctx;
    ctx.fillStyle = 'rgba(80,0,0,0.7)';
    ctx.fillRect(0, 0, CW, CH);
    this.cText(
      'FLATLINED', '#ff4444', 16, -40
    );
    this.cText(
      'Row: ' + (this.mapRow + 1)
        + '  Score: ' + this.score,
      '#fff', 10, -10
    );
    this.cText(
      'Press R to retry',
      '#aaa', 9, 24
    );
  }

  renderAnims() {
    const ctx = this.ctx;
    for (let i = 0;
      i < this.anims.length; i++) {
      const a = this.anims[i];
      const prog = a.t / a.dur;
      const alpha = 1 - prog;

      if (a.type === 'dmg') {
        ctx.fillStyle = a.clr;
        ctx.globalAlpha = alpha;
        ctx.font = '14px monospace';
        ctx.fillText(
          '-' + a.val,
          a.x - 10,
          a.y - prog * 30
        );
        ctx.globalAlpha = 1;
      }
      if (a.type === 'slash') {
        ctx.strokeStyle = a.clr;
        ctx.globalAlpha = alpha;
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.moveTo(a.x - 20, a.y - 15);
        ctx.lineTo(a.x + 20, a.y + 15);
        ctx.stroke();
        ctx.lineWidth = 1;
        ctx.globalAlpha = 1;
      }
      if (a.type === 'shield') {
        ctx.strokeStyle = a.clr;
        ctx.globalAlpha = alpha;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(
          a.x, a.y, 20 + prog * 10,
          0, Math.PI * 2
        );
        ctx.stroke();
        ctx.fillStyle = '#fff';
        ctx.font = '12px monospace';
        ctx.fillText(
          '+' + a.val,
          a.x - 8, a.y - 10 - prog * 20
        );
        ctx.lineWidth = 1;
        ctx.globalAlpha = 1;
      }
      if (a.type === 'sparkle') {
        ctx.fillStyle = a.clr;
        ctx.globalAlpha = alpha;
        for (let s = 0; s < 5; s++) {
          const sx = a.x - 20
            + Math.sin(s * 1.5
              + a.t * 8) * 15;
          const sy = a.y - prog * 20
            + Math.cos(s * 2
              + a.t * 6) * 10;
          ctx.fillRect(sx, sy, 3, 3);
        }
        ctx.globalAlpha = 1;
      }
    }
  }

  renderMap() {
    const ctx = this.ctx;
    ctx.fillStyle = '#0f0f18';
    ctx.fillRect(0, 0, CW, CH);

    // Title
    ctx.fillStyle = '#aa6633';
    ctx.font = '12px monospace';
    ctx.fillText(
      'SYNDICATE HIDEOUT', 160, 20
    );
    ctx.fillStyle = '#aaa';
    ctx.font = '8px monospace';
    ctx.fillText(
      'HP:' + this.hp + '/' + this.maxHp
        + '  Ahn:' + this.ahn
        + '  Deck:' + this.deck.length,
      10, 20
    );

    // Draw rows bottom to top
    const rowH = 32;
    const startY = CH - 50;
    const md = this.mapData;
    if (!md || !md.length) return;

    // Node colors
    const typeClr = {
      combat: '#cc4444',
      elite: '#cc44cc',
      rest: '#44cc44',
      shop: '#cccc44',
      event: '#4488cc',
      boss: '#ffaa33',
    };

    // Draw connections first
    for (let r = 0;
      r < md.length - 1; r++) {
      const row = md[r];
      const nextRow = md[r + 1];
      if (!row || !nextRow) continue;
      for (let n = 0;
        n < row.length; n++) {
        const node = row[n];
        const nx = this.nodeX(
          n, row.length
        );
        const ny = startY - r * rowH;
        const conns = node.conns || [];
        for (let ci = 0;
          ci < conns.length; ci++) {
          const ti = conns[ci] - 1;
          if (ti < 0
            || ti >= nextRow.length) {
            continue;
          }
          const tx = this.nodeX(
            ti, nextRow.length
          );
          const ty = startY
            - (r + 1) * rowH;
          ctx.strokeStyle = '#3a3a44';
          ctx.lineWidth = 2;
          ctx.beginPath();
          ctx.moveTo(nx, ny);
          ctx.lineTo(tx, ty);
          ctx.stroke();
          ctx.lineWidth = 1;
        }
      }
    }

    // Draw nodes
    for (let r = 0; r < md.length; r++) {
      const row = md[r];
      if (!row) continue;
      for (let n = 0;
        n < row.length; n++) {
        const node = row[n];
        const nx = this.nodeX(
          n, row.length
        );
        const ny = startY - r * rowH;
        const key = r + ',' + n;
        const vis = this.visited[key];
        const avail = this.isNodeAvail(
          r, n
        );
        const clr = typeClr[node.type]
          || '#888';

        // Node circle (larger)
        ctx.fillStyle = vis
          ? '#222' : '#1a1a22';
        ctx.beginPath();
        ctx.arc(
          nx, ny, 12, 0, Math.PI * 2
        );
        ctx.fill();

        // Check if this is last cleared
        const isLast = this.mapRow > 0
          && r === this.mapRow - 1
          && n === this.mapNode;

        // Colored border
        if (isLast) {
          ctx.strokeStyle = '#ffcc44';
          ctx.lineWidth = 3;
        } else if (avail && !vis) {
          ctx.strokeStyle = clr;
          ctx.lineWidth = 2;
        } else if (vis) {
          ctx.strokeStyle = '#444';
          ctx.lineWidth = 1;
        } else {
          ctx.strokeStyle = '#333';
          ctx.lineWidth = 1;
        }
        ctx.stroke();

        // Available node pulsing outline
        if (avail && !vis) {
          const pulse = Math.sin(
            performance.now() * 0.004
          );
          ctx.strokeStyle = clr;
          ctx.globalAlpha = 0.4
            + pulse * 0.3;
          ctx.lineWidth = 2;
          ctx.beginPath();
          ctx.arc(
            nx, ny, 15, 0, Math.PI * 2
          );
          ctx.stroke();
          ctx.globalAlpha = 1;
        }
        ctx.lineWidth = 1;

        // Hover glow
        if (r === this.mapRow
          && n === this.hoverNode
          && avail && !vis) {
          ctx.strokeStyle = '#fff';
          ctx.lineWidth = 2;
          ctx.beginPath();
          ctx.arc(
            nx, ny, 16, 0, Math.PI * 2
          );
          ctx.stroke();
          ctx.lineWidth = 1;
        }

        // Draw icon shape
        const ic = vis ? '#444' : clr;
        this.drawNodeIcon(
          nx, ny, node.type, ic
        );
      }
    }

    // View Deck button
    ctx.fillStyle = '#444';
    ctx.fillRect(CW - 90, CH - 30, 80, 22);
    ctx.fillStyle = '#ccc';
    ctx.font = '9px monospace';
    ctx.fillText(
      'View Deck', CW - 86, CH - 14
    );

    // Deck overlay
    if (this.showDeck) {
      this.renderDeckView();
    }

    // Legend with colored dots
    const leg = [
      ['Combat', '#cc4444', 'combat'],
      ['Elite', '#cc44cc', 'elite'],
      ['Rest', '#44cc44', 'rest'],
      ['Shop', '#cccc44', 'shop'],
      ['Event', '#4488cc', 'event'],
      ['Boss', '#ffaa33', 'boss'],
    ];
    for (let i = 0; i < leg.length; i++) {
      const lx = 10 + i * 80;
      const ly = CH - 12;
      // Mini node
      this.drawNodeIcon(
        lx + 6, ly, leg[i][2], leg[i][1]
      );
      ctx.fillStyle = leg[i][1];
      ctx.font = '7px monospace';
      ctx.fillText(
        leg[i][0], lx + 14, ly + 3
      );
    }
  }

  drawNodeIcon(x, y, type, clr) {
    const ctx = this.ctx;
    ctx.fillStyle = clr;
    ctx.strokeStyle = clr;
    ctx.lineWidth = 1.5;
    switch (type) {
      case 'combat':
        // Crossed swords
        ctx.beginPath();
        ctx.moveTo(x - 5, y - 6);
        ctx.lineTo(x + 5, y + 6);
        ctx.moveTo(x + 5, y - 6);
        ctx.lineTo(x - 5, y + 6);
        ctx.stroke();
        // Hilts
        ctx.fillRect(x - 3, y - 1, 2, 2);
        ctx.fillRect(x + 1, y - 1, 2, 2);
        break;
      case 'elite':
        // Skull shape
        ctx.beginPath();
        ctx.arc(x, y - 2, 5, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillRect(x - 3, y + 3, 6, 3);
        // Eyes
        ctx.fillStyle = '#1a1a22';
        ctx.fillRect(x - 3, y - 3, 2, 2);
        ctx.fillRect(x + 1, y - 3, 2, 2);
        break;
      case 'rest':
        // Campfire (triangle flame)
        ctx.beginPath();
        ctx.moveTo(x, y - 6);
        ctx.lineTo(x - 5, y + 4);
        ctx.lineTo(x + 5, y + 4);
        ctx.closePath();
        ctx.fill();
        // Log
        ctx.fillStyle = '#885533';
        ctx.fillRect(x - 5, y + 4, 10, 2);
        break;
      case 'shop':
        // Bag/sack shape
        ctx.beginPath();
        ctx.moveTo(x - 4, y - 2);
        ctx.lineTo(x - 5, y + 6);
        ctx.lineTo(x + 5, y + 6);
        ctx.lineTo(x + 4, y - 2);
        ctx.closePath();
        ctx.fill();
        // Tie at top
        ctx.fillRect(x - 2, y - 5, 4, 4);
        break;
      case 'event':
        // Question mark
        ctx.font = 'bold 14px monospace';
        ctx.fillText('?', x - 4, y + 5);
        break;
      case 'boss':
        // Crown
        ctx.beginPath();
        ctx.moveTo(x - 6, y + 4);
        ctx.lineTo(x - 6, y - 2);
        ctx.lineTo(x - 3, y + 1);
        ctx.lineTo(x, y - 5);
        ctx.lineTo(x + 3, y + 1);
        ctx.lineTo(x + 6, y - 2);
        ctx.lineTo(x + 6, y + 4);
        ctx.closePath();
        ctx.fill();
        break;
      default: break;
    }
    ctx.lineWidth = 1;
  }

  nodeX(idx, total) {
    const spacing = Math.min(
      100, (CW - 80) / Math.max(total, 1)
    );
    return CW / 2 - (total - 1)
      * spacing / 2 + idx * spacing;
  }

  isNodeAvail(row, nodeIdx) {
    if (row !== this.mapRow) return false;
    if (row === 0) return true;
    // Check if connected from previous node
    const prevRow = this.mapData[row - 1];
    if (!prevRow) return false;
    const prevNode = prevRow[this.mapNode];
    if (!prevNode) return false;
    const conns = prevNode.conns || [];
    return conns.indexOf(nodeIdx + 1) >= 0;
  }

  renderCharSel() {
    const ctx = this.ctx;
    ctx.fillStyle = '#0f0f18';
    ctx.fillRect(0, 0, CW, CH);

    this.cText(
      'CHOOSE YOUR FIXER',
      '#aa6633', 14, -180
    );

    const keys = Object.keys(CHARACTERS);
    this.charRects = [];
    for (let i = 0; i < keys.length; i++) {
      const ch = CHARACTERS[keys[i]];
      const bx = 20 + i * 165;
      const by = 80;
      const bw = 155;
      const bh = 300;
      const hov = this.mx >= bx
        && this.mx <= bx + bw
        && this.my >= by
        && this.my <= by + bh;

      // Card background
      ctx.fillStyle = hov
        ? '#1a1a28' : '#12121a';
      ctx.fillRect(bx, by, bw, bh);
      ctx.strokeStyle = hov
        ? ch.clr : '#333';
      ctx.lineWidth = hov ? 2 : 1;
      ctx.strokeRect(bx, by, bw, bh);
      ctx.lineWidth = 1;

      // Color bar
      ctx.fillStyle = ch.clr;
      ctx.fillRect(bx, by, bw, 6);

      // Name
      ctx.fillStyle = ch.clr;
      ctx.font = '11px monospace';
      ctx.fillText(
        ch.name, bx + 8, by + 24
      );

      // Description
      ctx.fillStyle = '#bbb';
      ctx.font = '8px monospace';
      const lines = ch.desc.split('\n');
      for (let li = 0;
        li < lines.length; li++) {
        ctx.fillText(
          lines[li],
          bx + 8, by + 44 + li * 12
        );
      }

      // Starter cards preview
      ctx.fillStyle = '#777';
      ctx.font = '7px monospace';
      ctx.fillText(
        'Starter deck:', bx + 8, by + 100
      );
      const seen = {};
      for (let si = 0;
        si < ch.starter.length; si++) {
        const sk = ch.starter[si];
        seen[sk] = (seen[sk] || 0) + 1;
      }
      let sy = by + 114;
      const skeys = Object.keys(seen);
      for (let si = 0;
        si < skeys.length; si++) {
        const sk = skeys[si];
        const sc = CARDS[sk];
        if (!sc) continue;
        let tc = '#cc4444';
        if (sc.type === 'blk') {
          tc = '#4488cc';
        }
        if (sc.type === 'skill') {
          tc = '#44aa66';
        }
        ctx.fillStyle = tc;
        ctx.fillText(
          seen[sk] + 'x ' + sc.name,
          bx + 12, sy
        );
        sy += 11;
      }

      this.charRects.push({
        x: bx, y: by, w: bw, h: bh,
        key: keys[i],
      });
    }

    ctx.fillStyle = '#555';
    ctx.font = '8px monospace';
    ctx.fillText(
      'Click a character to begin',
      CW / 2 - 80, CH - 20
    );
  }

  renderDeckView() {
    const ctx = this.ctx;
    ctx.fillStyle = 'rgba(0,0,0,0.9)';
    ctx.fillRect(0, 0, CW, CH);

    ctx.fillStyle = '#ffcc44';
    ctx.font = '12px monospace';
    ctx.fillText(
      'YOUR DECK (' + this.deck.length
        + ' cards)',
      CW / 2 - 80, 24
    );

    ctx.font = '9px monospace';
    const cols = 3;
    const perPage = 18;
    const start = this.deckScroll * perPage;
    for (let i = 0;
      i < perPage
      && start + i < this.deck.length;
      i++) {
      const key = this.deck[start + i];
      const card = this.getCard(key);
      if (!card) continue;
      const col = i % cols;
      const row = Math.floor(i / cols);
      const x = 20 + col * 170;
      const y = 40 + row * 22;

      let clr = '#cc4444';
      if (card.type === 'blk') {
        clr = '#4488cc';
      }
      if (card.type === 'skill') {
        clr = '#44aa66';
      }
      ctx.fillStyle = clr;
      ctx.fillText(
        card.name + ' (' + card.cost
          + ')',
        x, y
      );
      ctx.fillStyle = '#888';
      ctx.fillText(
        card.desc.split('\n')[0],
        x, y + 11
      );
    }

    // Page info
    const pages = Math.ceil(
      this.deck.length / perPage
    );
    ctx.fillStyle = '#666';
    ctx.font = '8px monospace';
    ctx.fillText(
      'Page ' + (this.deckScroll + 1)
        + '/' + Math.max(1, pages)
        + '  [ESC] close  [<>] page',
      CW / 2 - 90, CH - 12
    );
  }

  renderRest() {
    const ctx = this.ctx;
    ctx.fillStyle = 'rgba(0,0,0,0.85)';
    ctx.fillRect(0, 0, CW, CH);
    this.cText(
      'REST SITE', '#44cc44', 16, -100
    );
    this.cText(
      'HP: ' + this.hp + '/' + this.maxHp,
      '#aaa', 9, -74
    );

    this.restRects = [];
    if (!this.upgradeMode) {
      // Clickable buttons
      const opts = [
        'Heal (restore 25% HP)',
        'Upgrade a card',
      ];
      for (let i = 0;
        i < opts.length; i++) {
        const bx = CW / 2 - 100;
        const by = CH / 2 - 30 + i * 36;
        const hov = this.mx >= bx
          && this.mx <= bx + 200
          && this.my >= by
          && this.my <= by + 28;
        ctx.fillStyle = hov
          ? '#2a3a2a' : '#1a2a1a';
        ctx.fillRect(bx, by, 200, 28);
        ctx.strokeStyle = hov
          ? '#44cc44' : '#335533';
        ctx.strokeRect(bx, by, 200, 28);
        ctx.fillStyle = hov
          ? '#44cc44' : '#888';
        ctx.font = '10px monospace';
        ctx.fillText(
          opts[i], bx + 10, by + 18
        );
        this.restRects.push({
          x: bx, y: by, w: 200, h: 28,
          action: i === 0
            ? 'heal' : 'upgrade',
        });
      }
    } else {
      // Scrollable card upgrade list
      this.cText(
        'Click a card to upgrade',
        '#ffcc44', 10, -50
      );
      const perPage = 10;
      const start = this.deckScroll
        * perPage;
      for (let i = 0;
        i < perPage
        && start + i < this.deck.length;
        i++) {
        const di = start + i;
        const key = this.deck[di];
        const base = key.replace('+', '');
        const card = this.getCard(key);
        if (!card) continue;
        const upg = UPGRADES[base];
        const bx = 30;
        const by = CH / 2 - 60 + i * 22;
        const hov = this.mx >= bx
          && this.mx <= bx + CW - 60
          && this.my >= by
          && this.my <= by + 18;
        ctx.fillStyle = hov
          ? '#2a2a1a' : '#1a1a12';
        ctx.fillRect(
          bx, by, CW - 60, 18
        );
        ctx.fillStyle = hov
          ? '#ffcc44' : '#888';
        ctx.font = '9px monospace';
        const alreadyUp =
          key.indexOf('+') >= 0;
        const upTxt = alreadyUp
          ? ' (upgraded)'
          : upg
            ? ' -> ' + upg.desc
            : '';
        ctx.fillText(
          card.name + upTxt,
          bx + 4, by + 13
        );
        if (!alreadyUp && upg) {
          this.restRects.push({
            x: bx, y: by,
            w: CW - 60, h: 18,
            action: 'pick',
            deckIdx: di,
          });
        }
      }
      // Prev/Next buttons
      const pages = Math.ceil(
        this.deck.length / perPage
      );
      ctx.fillStyle = '#444';
      ctx.fillRect(
        CW / 2 - 80, CH - 28, 40, 18
      );
      ctx.fillRect(
        CW / 2 + 40, CH - 28, 40, 18
      );
      ctx.fillStyle = '#ccc';
      ctx.font = '8px monospace';
      ctx.fillText(
        '< Prev', CW / 2 - 76, CH - 14
      );
      ctx.fillText(
        'Next >', CW / 2 + 44, CH - 14
      );
      ctx.fillStyle = '#555';
      ctx.fillText(
        'Page ' + (this.deckScroll + 1)
          + '/' + Math.max(1, pages),
        CW / 2 - 20, CH - 14
      );
      this.restRects.push({
        x: CW / 2 - 80, y: CH - 28,
        w: 40, h: 18, action: 'prev',
      });
      this.restRects.push({
        x: CW / 2 + 40, y: CH - 28,
        w: 40, h: 18, action: 'next',
      });
    }
  }

  renderShop() {
    const ctx = this.ctx;
    ctx.fillStyle = 'rgba(0,0,0,0.85)';
    ctx.fillRect(0, 0, CW, CH);
    this.cText(
      'BACKSTREET SHOP', '#cccc44', 14, -120
    );
    ctx.fillStyle = '#ffcc44';
    ctx.font = '9px monospace';
    ctx.fillText(
      'Ahn: ' + this.ahn, CW / 2 - 25,
      CH / 2 - 96
    );

    const items = [];
    // Cards for sale
    const sc = this.curNode
      ? this.curNode.shopCards || [] : [];
    for (let i = 0; i < sc.length; i++) {
      const c = CARDS[sc[i]];
      if (c) {
        items.push({
          label: c.name + ' (50 Ahn)',
          action: 'card',
          key: sc[i],
          cost: 50,
        });
      }
    }
    // Remove card (escalating cost)
    const rmCost = 40
      + this.removeCount * 25;
    items.push({
      label: 'Remove a card ('
        + rmCost + ' Ahn)',
      action: 'remove', cost: rmCost,
    });
    // Augment
    if (this.curNode
      && this.curNode.shopAug) {
      const a = AUGS[this.curNode.shopAug];
      if (a) {
        items.push({
          label: a.name + ' (100 Ahn)',
          action: 'aug',
          key: this.curNode.shopAug,
          cost: 100,
        });
      }
    }
    items.push({
      label: 'Leave', action: 'leave',
      cost: 0,
    });
    this.shopItems = items;

    this.shopRects = [];
    ctx.font = '9px monospace';
    for (let i = 0; i < items.length; i++) {
      const bx = 60;
      const by = CH / 2 - 60 + i * 28;
      const hov = this.mx >= bx
        && this.mx <= bx + 400
        && this.my >= by
        && this.my <= by + 22;
      const afford = !items[i].cost
        || this.ahn >= items[i].cost;
      ctx.fillStyle = hov && afford
        ? '#2a2a1a' : '#1a1a12';
      ctx.fillRect(bx, by, 400, 22);
      ctx.strokeStyle = hov && afford
        ? '#cccc44' : '#333';
      ctx.strokeRect(bx, by, 400, 22);
      ctx.fillStyle = !afford
        ? '#555' : hov
          ? '#cccc44' : '#999';
      ctx.fillText(
        items[i].label, bx + 8, by + 15
      );
      this.shopRects.push({
        x: bx, y: by, w: 400, h: 22,
        idx: i,
      });
    }
    ctx.fillStyle = '#555';
    ctx.font = '8px monospace';
    ctx.fillText(
      'Click to select',
      CW / 2 - 40,
      CH / 2 + items.length * 28 - 40
    );
  }

  renderEvent() {
    const ctx = this.ctx;
    ctx.fillStyle = 'rgba(0,0,0,0.85)';
    ctx.fillRect(0, 0, CW, CH);

    if (!this.curNode) return;
    const eKey = this.curNode.event;
    const ev = EVENTS[eKey];
    if (!ev) {
      this.advanceToMap();
      return;
    }

    this.cText(ev.title, '#4488cc', 14, -80);
    // Word-wrap event text
    const lines = ev.text.split('\n');
    for (let i = 0; i < lines.length; i++) {
      this.cText(
        lines[i], '#ccc', 9, -50 + i * 14
      );
    }

    this.eventRects = [];
    const opts = [ev.opt1, ev.opt2];
    for (let i = 0; i < opts.length; i++) {
      const bx = CW / 2 - 150;
      const by = CH / 2 + 10 + i * 36;
      const hov = this.mx >= bx
        && this.mx <= bx + 300
        && this.my >= by
        && this.my <= by + 28;
      ctx.fillStyle = hov
        ? '#1a2a3a' : '#121a22';
      ctx.fillRect(bx, by, 300, 28);
      ctx.strokeStyle = hov
        ? '#4488cc' : '#334455';
      ctx.strokeRect(bx, by, 300, 28);
      ctx.fillStyle = hov
        ? '#4488cc' : '#888';
      ctx.font = '9px monospace';
      ctx.fillText(
        opts[i], bx + 10, by + 18
      );
      this.eventRects.push({
        x: bx, y: by, w: 300, h: 28,
      });
    }
  }

  // Event resolution
  resolveEvent(choice) {
    const eKey = this.curNode
      ? this.curNode.event : null;
    if (!eKey) {
      this.advanceToMap();
      return;
    }
    switch (eKey) {
      case 'wounded_fixer':
        if (choice === 0) {
          this.hp -= 8;
          // Add random reward card
          const pool = Object.keys(CARDS)
            .filter(k => k !== 'slash'
              && k !== 'guard');
          if (pool.length) {
            this.deck.push(
              pool[Math.floor(
                Math.random() * pool.length
              )]
            );
          }
        }
        break;
      case 'trap':
        if (choice === 0) {
          if (this.deck.length > 2) {
            const ri = Math.floor(
              Math.random()
              * this.deck.length
            );
            this.deck.splice(ri, 1);
          }
        } else {
          this.hp -= 12;
        }
        break;
      case 'cache':
        if (choice === 0) {
          this.ahn += 40;
        } else {
          this.ahn += 80;
          this.hp -= 6;
        }
        break;
      case 'merchant':
        if (choice === 0
          && this.ahn >= 60) {
          this.ahn -= 60;
          const pool2 = Object.keys(AUGS);
          if (pool2.length) {
            this.augments.push(
              pool2[Math.floor(
                Math.random()
                * pool2.length
              )]
            );
          }
        }
        break;
      case 'shrine':
        if (choice === 0) {
          this.maxHp += 2;
          this.hp += 2;
        } else {
          this.hp -= 5;
          this.str += 1;
        }
        break;
      case 'gamble':
        if (choice === 0) {
          if (Math.random() < 0.5) {
            this.ahn += 60;
          } else {
            this.ahn = Math.max(
              0, this.ahn - 30
            );
          }
        }
        break;
      default: break;
    }
    if (this.hp <= 0) {
      this.state = GS_DEFEAT;
      this.act('died');
      return;
    }
    this.advanceToMap();
  }

  cText(text, color, size, yOff) {
    const ctx = this.ctx;
    ctx.fillStyle = color;
    ctx.font = size + 'px monospace';
    const w = ctx.measureText(text).width;
    ctx.fillText(
      text,
      (CW - w) / 2,
      CH / 2 + (yOff || 0)
    );
  }

  // ==================
  // INPUT
  // ==================

  handleMouseDown(mx, my) {
    // Start drag if clicking a card
    if (this.state === GS_COMBAT
      && this.hoverCard >= 0
      && this.hoverCard
        < this.hand.length) {
      this.dragging = true;
      this.dragCard = this.hoverCard;
      this.dragX = mx;
      this.dragY = my;
      this.dragStartX = mx;
      this.dragStartY = my;
      return;
    }
    // Otherwise treat as click
    this.handleClick(mx, my);
  }

  handleMouseUp(mx, my) {
    if (!this.dragging) return;
    this.dragging = false;
    const ci = this.dragCard;
    this.dragCard = -1;

    // Check if dragged far enough
    const dist = Math.abs(
      my - this.dragStartY
    );
    if (dist < 30) return; // Too short

    // Get card info
    if (ci < 0
      || ci >= this.hand.length) return;
    const key = this.hand[ci];
    const card = this.getCard(key);
    if (!card) return;

    let cost = card.cost;
    if (this.firstCard
      && this.hasAug('reflexes')) {
      cost = 0;
    }
    if (this.light < cost) return;

    if (card.type === 'atk') {
      // Check if dropped on an enemy
      for (let i = 0;
        i < this.enemies.length; i++) {
        const e = this.enemies[i];
        if (e.hp <= 0) continue;
        const ex = this.enemyX(i);
        const dx = mx - ex;
        const dy = my - 90;
        if (dx * dx + dy * dy < 2000) {
          this.playCard(ci, i);
          return;
        }
      }
    } else {
      // Non-attack: play if dragged upward
      if (my < 250) {
        this.playCard(ci, -1);
      }
    }
  }

  handleClick(mx, my) {
    if (this.state === GS_TITLE) return;

    // Character select
    if (this.state === GS_CHARSEL
      && this.charRects) {
      for (let i = 0;
        i < this.charRects.length; i++) {
        const r = this.charRects[i];
        if (mx >= r.x && mx <= r.x + r.w
          && my >= r.y
          && my <= r.y + r.h) {
          this.selectChar(r.key);
          return;
        }
      }
      return;
    }

    if (this.state === GS_COMBAT) {
      // Check end turn button
      const bw = 90;
      const bx = CW / 2 - bw / 2;
      const by = CH - 36;
      if (mx >= bx && mx <= bx + bw
        && my >= by && my <= by + 28) {
        this.endTurn();
        return;
      }
      // Check card click
      if (this.hoverCard >= 0
        && this.hoverCard
          < this.hand.length) {
        const key = this.hand[
          this.hoverCard
        ];
        const card = this.getCard(key);
        if (!card) return;
        let cost = card.cost;
        if (this.firstCard
          && this.hasAug('reflexes')) {
          cost = 0;
        }
        if (this.light < cost) return;
        if (card.type === 'atk') {
          // Need target
          this.selectedCard
            = this.hoverCard;
          this.state = GS_TARGETING;
        } else {
          this.playCard(
            this.hoverCard, -1
          );
        }
        return;
      }
    }

    if (this.state === GS_TARGETING) {
      // Click enemy
      if (this.hoverEnemy >= 0) {
        this.playCard(
          this.selectedCard,
          this.hoverEnemy
        );
        this.state = GS_COMBAT;
        return;
      }
      // Click elsewhere = cancel
      this.selectedCard = -1;
      this.state = GS_COMBAT;
      return;
    }

    if (this.state === GS_REWARD) {
      // Card picks
      for (let i = 0;
        i < this.rewardOpts.length; i++) {
        const x = 60 + i * 160;
        if (mx >= x && mx <= x + 120
          && my >= 160 && my <= 320) {
          this.pickReward(i);
          return;
        }
      }
      // Skip
      if (mx >= CW / 2 - 40
        && mx <= CW / 2 + 40
        && my >= 380 && my <= 408) {
        this.pickReward(-1);
      }
      return;
    }

    if (this.state === GS_AUGMENT) {
      for (let i = 0;
        i < this.augOpts.length; i++) {
        const x = 40 + i * 160;
        if (mx >= x && mx <= x + 140
          && my >= 170 && my <= 270) {
          this.pickAugment(i);
          return;
        }
      }
    }

    // Rest click
    if (this.state === GS_REST
      && this.restRects) {
      for (let i = 0;
        i < this.restRects.length; i++) {
        const r = this.restRects[i];
        if (mx >= r.x && mx <= r.x + r.w
          && my >= r.y
          && my <= r.y + r.h) {
          if (r.action === 'heal') {
            this.hp = Math.min(
              this.maxHp,
              this.hp + Math.ceil(
                this.maxHp * 0.25
              )
            );
            this.advanceToMap();
          } else if (
            r.action === 'upgrade'
          ) {
            this.upgradeMode = true;
            this.deckScroll = 0;
          } else if (r.action === 'pick') {
            const k = this.deck[r.deckIdx];
            if (k
              && k.indexOf('+') < 0) {
              this.deck[r.deckIdx]
                = k + '+';
            }
            this.advanceToMap();
          } else if (r.action === 'prev') {
            this.deckScroll = Math.max(
              0, this.deckScroll - 1
            );
          } else if (r.action === 'next') {
            this.deckScroll++;
          }
          return;
        }
      }
    }

    // Shop click
    if (this.state === GS_SHOP
      && this.shopRects) {
      for (let i = 0;
        i < this.shopRects.length; i++) {
        const r = this.shopRects[i];
        if (mx >= r.x && mx <= r.x + r.w
          && my >= r.y
          && my <= r.y + r.h) {
          const item = this.shopItems
            ? this.shopItems[r.idx] : null;
          if (!item) return;
          if (item.action === 'leave') {
            this.advanceToMap();
          } else if (
            item.action === 'card'
            && this.ahn >= item.cost
          ) {
            this.ahn -= item.cost;
            this.deck.push(item.key);
          } else if (
            item.action === 'remove'
            && this.ahn >= item.cost
            && this.deck.length > 3
          ) {
            this.ahn -= item.cost;
            this.removeCount++;
            const ri = Math.floor(
              Math.random()
              * this.deck.length
            );
            const rm = this.deck[ri];
            const rc = this.getCard(rm);
            this.deck.splice(ri, 1);
            if (rc) {
              this.msg = 'Removed: '
                + rc.name;
              this.msgTimer = 1.5;
            }
          } else if (
            item.action === 'aug'
            && this.ahn >= item.cost
          ) {
            this.ahn -= item.cost;
            this.augments.push(item.key);
          }
          return;
        }
      }
    }

    // Event click
    if (this.state === GS_EVENT
      && this.eventRects) {
      for (let i = 0;
        i < this.eventRects.length; i++) {
        const r = this.eventRects[i];
        if (mx >= r.x && mx <= r.x + r.w
          && my >= r.y
          && my <= r.y + r.h) {
          this.resolveEvent(i);
          return;
        }
      }
    }

    // Map interactions
    if (this.state === GS_MAP) {
      // Deck view toggle
      if (this.showDeck) {
        this.showDeck = false;
        return;
      }
      if (mx >= CW - 90 && mx <= CW - 10
        && my >= CH - 30 && my <= CH - 8) {
        this.showDeck = !this.showDeck;
        this.deckScroll = 0;
        return;
      }
      const md = this.mapData;
      if (!md || !md[this.mapRow]) return;
      const row = md[this.mapRow];
      const startY = CH - 50;
      for (let n = 0;
        n < row.length; n++) {
        const nx = this.nodeX(
          n, row.length
        );
        const ny = startY
          - this.mapRow * 32;
        const dx = mx - nx;
        const dy = my - ny;
        if (dx * dx + dy * dy < 144
          && this.isNodeAvail(
            this.mapRow, n
          )) {
          this.enterNode(this.mapRow, n);
          return;
        }
      }
    }
  }

  handleHover(mx, my) {
    this.mx = mx;
    this.my = my;
    this.hoverCard = -1;
    this.hoverEnemy = -1;

    if (this.state === GS_COMBAT
      || this.state === GS_TARGETING) {
      // Cards
      const n = this.hand.length;
      if (n > 0) {
        const fanCx = CW / 2;
        const maxW = CW - 40;
        const cw = Math.min(
          CARD_W, (maxW - 20) / n
        );
        const totalW = cw * n;
        const startX = fanCx - totalW / 2;
        for (let i = n - 1; i >= 0; i--) {
          const cx = startX + i * cw;
          if (mx >= cx
            && mx <= cx + cw
            && my >= 300
            && my <= 300 + CARD_H) {
            this.hoverCard = i;
            break;
          }
        }
      }
      // Enemies
      if (this.state === GS_TARGETING) {
        for (let i = 0;
          i < this.enemies.length; i++) {
          const e = this.enemies[i];
          if (e.hp <= 0) continue;
          const ex = this.enemyX(i);
          if (mx >= ex - 35
            && mx <= ex + 35
            && my >= 50 && my <= 140) {
            this.hoverEnemy = i;
            break;
          }
        }
      }
    }

    if (this.state === GS_REWARD) {
      for (let i = 0;
        i < this.rewardOpts.length; i++) {
        const x = 60 + i * 160;
        if (mx >= x && mx <= x + 120
          && my >= 160 && my <= 320) {
          this.hoverCard = i;
          break;
        }
      }
    }

    // Map hover
    if (this.state === GS_MAP) {
      this.hoverNode = -1;
      const md = this.mapData;
      if (!md || !md[this.mapRow]) return;
      const row = md[this.mapRow];
      const startY = CH - 50;
      for (let n = 0;
        n < row.length; n++) {
        const nx = this.nodeX(
          n, row.length
        );
        const ny = startY
          - this.mapRow * 32;
        const ddx = mx - nx;
        const ddy = my - ny;
        if (ddx * ddx + ddy * ddy < 144
          && this.isNodeAvail(
            this.mapRow, n
          )) {
          this.hoverNode = n;
          break;
        }
      }
    }
  }

  handleKeyDown(code) {
    if (this.state === GS_TITLE
      && code === KEY_ENTER) {
      this.state = GS_CHARSEL;
    }
    if ((this.state === GS_VICTORY
      || this.state === GS_DEFEAT)
      && code === KEY_R) {
      this.state = GS_TITLE;
    }
    if (this.state === GS_TARGETING
      && code === KEY_ESC) {
      this.selectedCard = -1;
      this.state = GS_COMBAT;
    }

    // Deck viewer navigation
    if (this.state === GS_MAP
      && this.showDeck) {
      if (code === KEY_ESC) {
        this.showDeck = false;
      }
      if (code === 39) {
        this.deckScroll++;
      }
      if (code === 37) {
        this.deckScroll = Math.max(
          0, this.deckScroll - 1
        );
      }
      return;
    }

    // All rest/shop/event interactions
    // are now mouse-only (see handleClick)
  }
}

// =========================================
// TGUI Component
// =========================================

const ACQUIRED_KEYS = [KEY_R, KEY_ESC];

class ArcadeCardGameComp extends Component {
  constructor(props) {
    super(props);
    this.canvasRef = createRef();
    this.engine = null;
    this.keysAcquired = false;
  }

  componentDidMount() {
    const canvas = this.canvasRef.current;
    if (!canvas) return;

    for (let i = 0;
      i < ACQUIRED_KEYS.length; i++) {
      acquireHotKey(ACQUIRED_KEYS[i]);
    }
    this.keysAcquired = true;

    this.engine = new CardEngine(
      canvas, this.props.act
    );
    this.engine.leaderboard
      = this.props.data.leaderboard || [];

    const sd = this.props.data;
    if (sd && sd.map) {
      this.engine.loadData(sd);
    }

    this.engine.start();
    canvas.focus();
  }

  componentDidUpdate(prevProps) {
    if (!this.engine) return;
    const sd = this.props.data;
    if (sd && sd.map
      && sd !== prevProps.data
      && sd.map
        !== prevProps.data.map) {
      this.engine.loadData(sd);
      this.engine.state = GS_TITLE;
    }
    if (sd) {
      this.engine.leaderboard
        = sd.leaderboard || [];
    }
  }

  componentWillUnmount() {
    if (this.engine) this.engine.stop();
    if (this.keysAcquired) {
      for (let i = 0;
        i < ACQUIRED_KEYS.length; i++) {
        releaseHotKey(ACQUIRED_KEYS[i]);
      }
    }
  }

  render() {
    return (
      <canvas
        ref={this.canvasRef}
        width={CW}
        height={CH}
        tabIndex={0}
        onKeyDown={e => {
          e.preventDefault();
          if (this.engine) {
            this.engine.handleKeyDown(
              e.keyCode
            );
          }
        }}
        onMouseMove={e => {
          if (!this.engine) return;
          const r = e.target
            .getBoundingClientRect();
          const mx = e.clientX - r.left;
          const my = e.clientY - r.top;
          this.engine.handleHover(mx, my);
          if (this.engine.dragging) {
            this.engine.dragX = mx;
            this.engine.dragY = my;
          }
        }}
        onMouseDown={e => {
          if (!this.engine) return;
          const r = e.target
            .getBoundingClientRect();
          const mx = e.clientX - r.left;
          const my = e.clientY - r.top;
          this.engine.handleMouseDown(
            mx, my
          );
        }}
        onMouseUp={e => {
          if (!this.engine) return;
          const r = e.target
            .getBoundingClientRect();
          const mx = e.clientX - r.left;
          const my = e.clientY - r.top;
          this.engine.handleMouseUp(
            mx, my
          );
        }}
        style={{
          display: 'block',
          outline: 'none',
          cursor: 'pointer',
        }}
      />
    );
  }
}

export const ArcadeCardGame = (
  props, context
) => {
  const { act, data } = useBackend(context);
  return (
    <Window
      width={CW + 30}
      height={CH + 50}>
      <Window.Content>
        <ArcadeCardGameComp
          act={act}
          data={data}
        />
      </Window.Content>
    </Window>
  );
};
