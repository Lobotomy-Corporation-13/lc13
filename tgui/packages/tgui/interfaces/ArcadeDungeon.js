/**
 * @file
 * @copyright 2024
 * @license MIT
 *
 * L-Corp Depths - Darkest Dungeon
 * arcade. Turn-based dungeon crawl.
 */

import { Component, createRef } from 'inferno';
import { useBackend } from '../backend';
import { Window } from '../layouts';
import {
  acquireHotKey,
  releaseHotKey,
} from '../hotkeys';

// Canvas dimensions
const CW = 640;
const CH = 400;

// Game states
const GS_TITLE = 0;
const GS_CHARSEL = 1;
const GS_MAP = 2;
const GS_CORRIDOR = 3;
const GS_COMBAT = 4;
const GS_ANIM = 5;
const GS_TARGETING = 6;
const GS_LOOT = 7;
const GS_CURIO = 8;
const GS_VICTORY = 9;
const GS_DEFEAT = 10;
const GS_NAMEENTRY = 11;

// Key codes
const KEY_ENTER = 13;
const KEY_R = 82;
const KEY_ESC = 27;
const KEY_W = 87;
const KEY_A = 65;
const KEY_S = 83;
const KEY_D = 68;
const KEY_1 = 49;
const KEY_2 = 50;
const KEY_3 = 51;
const KEY_4 = 52;
const KEY_SPACE = 32;

// Character class definitions
const CHARACTERS = {
  thumb: {
    name: 'Thumb Enforcer',
    faction: 'Five Fingers',
    role: 'Tank',
    posMin: 1,
    posMax: 2,
    hp: 45,
    maxHp: 45,
    speed: 3,
    color: '#887766',
    skills: [
      {
        name: 'Crush',
        posMin: 1,
        posMax: 2,
        hitMin: 1,
        hitMax: 2,
        dmgMin: 6,
        dmgMax: 9,
        effects: {},
        desc: 'Heavy melee strike',
        targetType: 'enemy',
      },
      {
        name: 'Iron Stance',
        posMin: 1,
        posMax: 2,
        hitMin: 0,
        hitMax: 0,
        dmgMin: 0,
        dmgMax: 0,
        effects: { selfBlock: 10 },
        desc: 'Brace for impact',
        targetType: 'self',
      },
      {
        name: 'Intimidate',
        posMin: 1,
        posMax: 2,
        hitMin: 1,
        hitMax: 3,
        dmgMin: 4,
        dmgMax: 4,
        effects: { mark: 2 },
        desc: 'Mark a foe',
        targetType: 'enemy',
      },
    ],
  },
  index: {
    name: 'Index Blade',
    faction: 'Five Fingers',
    role: 'DPS',
    posMin: 1,
    posMax: 2,
    hp: 30,
    maxHp: 30,
    speed: 5,
    color: '#445566',
    skills: [
      {
        name: 'Precise Cut',
        posMin: 1,
        posMax: 2,
        hitMin: 1,
        hitMax: 2,
        dmgMin: 9,
        dmgMax: 13,
        effects: {},
        desc: 'Accurate blade strike',
        targetType: 'enemy',
      },
      {
        name: 'Flurry',
        posMin: 1,
        posMax: 1,
        hitMin: 1,
        hitMax: 2,
        dmgMin: 4,
        dmgMax: 4,
        effects: {},
        hits: 3,
        desc: 'Triple rapid slash',
        targetType: 'enemy',
      },
      {
        name: 'Lacerate',
        posMin: 1,
        posMax: 2,
        hitMin: 1,
        hitMax: 2,
        dmgMin: 5,
        dmgMax: 5,
        effects: { bleed: { v: 3, t: 2 } },
        desc: 'Bleeding wound',
        targetType: 'enemy',
      },
    ],
  },
  middle: {
    name: 'Middle Counter',
    faction: 'Five Fingers',
    role: 'Counter',
    posMin: 1,
    posMax: 3,
    hp: 35,
    maxHp: 35,
    speed: 4,
    color: '#666655',
    skills: [
      {
        name: 'Riposte Stance',
        posMin: 1,
        posMax: 3,
        hitMin: 0,
        hitMax: 0,
        dmgMin: 0,
        dmgMax: 0,
        effects: { riposte: 8 },
        desc: 'Counter next attack',
        targetType: 'self',
      },
      {
        name: 'Deflect',
        posMin: 1,
        posMax: 3,
        hitMin: 0,
        hitMax: 0,
        dmgMin: 0,
        dmgMax: 0,
        effects: {
          selfBlock: 6,
          parryDmg: 5,
        },
        desc: 'Block and parry',
        targetType: 'self',
      },
      {
        name: 'Punish',
        posMin: 1,
        posMax: 2,
        hitMin: 1,
        hitMax: 2,
        dmgMin: 6,
        dmgMax: 12,
        effects: {},
        desc: 'Bonus if took damage',
        targetType: 'enemy',
      },
    ],
  },
  ring: {
    name: 'Ring Aesthete',
    faction: 'Five Fingers',
    role: 'Debuffer',
    posMin: 3,
    posMax: 4,
    hp: 25,
    maxHp: 25,
    speed: 6,
    color: '#aa8899',
    skills: [
      {
        name: 'Dazzle',
        posMin: 3,
        posMax: 4,
        hitMin: 1,
        hitMax: 4,
        dmgMin: 0,
        dmgMax: 0,
        effects: { blind: 2 },
        desc: 'Blind a target',
        targetType: 'enemy',
      },
      {
        name: "Muse's Curse",
        posMin: 3,
        posMax: 4,
        hitMin: 1,
        hitMax: 4,
        dmgMin: 0,
        dmgMax: 0,
        effects: { weakDmg: { v: -4, t: 2 } },
        desc: 'Weaken enemy damage',
        targetType: 'enemy',
      },
      {
        name: 'Masterwork',
        posMin: 3,
        posMax: 4,
        hitMin: 1,
        hitMax: 2,
        dmgMin: 7,
        dmgMax: 10,
        effects: { vuln: 2 },
        desc: 'Strike with finesse',
        targetType: 'enemy',
      },
    ],
  },
  shi: {
    name: 'Shi Assassin',
    faction: 'Shi Assoc.',
    role: 'Poison DPS',
    posMin: 1,
    posMax: 2,
    hp: 28,
    maxHp: 28,
    speed: 7,
    color: '#6644aa',
    skills: [
      {
        name: 'Backstab',
        posMin: 1,
        posMax: 1,
        hitMin: 1,
        hitMax: 1,
        dmgMin: 11,
        dmgMax: 15,
        effects: {},
        desc: 'Lethal from front',
        targetType: 'enemy',
      },
      {
        name: 'Poison Blade',
        posMin: 1,
        posMax: 2,
        hitMin: 1,
        hitMax: 2,
        dmgMin: 4,
        dmgMax: 4,
        effects: {
          poison: { v: 3, t: 3 },
        },
        desc: 'Envenom the foe',
        targetType: 'enemy',
      },
      {
        name: 'Fade',
        posMin: 1,
        posMax: 2,
        hitMin: 0,
        hitMax: 0,
        dmgMin: 0,
        dmgMax: 0,
        effects: {
          selfBlock: 7,
          moveBack: 1,
        },
        desc: 'Dodge and retreat',
        targetType: 'self',
      },
    ],
  },
  liu: {
    name: 'Liu Associate',
    faction: 'Liu Assoc.',
    role: 'Burn DPS',
    posMin: 1,
    posMax: 2,
    hp: 32,
    maxHp: 32,
    speed: 5,
    color: '#cc6633',
    skills: [
      {
        name: 'Flame Slash',
        posMin: 1,
        posMax: 2,
        hitMin: 1,
        hitMax: 2,
        dmgMin: 7,
        dmgMax: 10,
        effects: {},
        desc: 'Blazing sword cut',
        targetType: 'enemy',
      },
      {
        name: 'Ignite',
        posMin: 1,
        posMax: 3,
        hitMin: 1,
        hitMax: 4,
        dmgMin: 3,
        dmgMax: 3,
        effects: {
          burn: { v: 4, t: 2 },
        },
        desc: 'Set ablaze',
        targetType: 'enemy',
      },
      {
        name: 'Inner Fire',
        posMin: 1,
        posMax: 2,
        hitMin: 0,
        hitMax: 0,
        dmgMin: 0,
        dmgMax: 0,
        effects: { selfHeal: 8 },
        desc: 'Heal with flame chi',
        targetType: 'self',
      },
    ],
  },
  zwei: {
    name: 'Zwei Guard',
    faction: 'Zwei Assoc.',
    role: 'Protector',
    posMin: 1,
    posMax: 2,
    hp: 40,
    maxHp: 40,
    speed: 2,
    color: '#556688',
    skills: [
      {
        name: 'Shield Bash',
        posMin: 1,
        posMax: 1,
        hitMin: 1,
        hitMax: 1,
        dmgMin: 5,
        dmgMax: 7,
        effects: { stun: 1 },
        desc: 'Stun with shield',
        targetType: 'enemy',
      },
      {
        name: 'Protect',
        posMin: 1,
        posMax: 2,
        hitMin: 0,
        hitMax: 0,
        dmgMin: 0,
        dmgMax: 0,
        effects: { protect: 1 },
        desc: 'Guard an ally',
        targetType: 'ally',
      },
      {
        name: 'Barricade',
        posMin: 1,
        posMax: 2,
        hitMin: 0,
        hitMax: 0,
        dmgMin: 0,
        dmgMax: 0,
        effects: { partyBlock: 4 },
        desc: 'Shield the party',
        targetType: 'party',
      },
    ],
  },
  doc: {
    name: 'Backstreet Doc',
    faction: 'Independent',
    role: 'Healer',
    posMin: 3,
    posMax: 4,
    hp: 22,
    maxHp: 22,
    speed: 4,
    color: '#44aa66',
    skills: [
      {
        name: 'Patch Up',
        posMin: 3,
        posMax: 4,
        hitMin: 0,
        hitMax: 0,
        dmgMin: 0,
        dmgMax: 0,
        effects: { heal: { v: 8, t: 12 } },
        desc: 'Heal an ally',
        targetType: 'ally',
      },
      {
        name: 'Calm Nerves',
        posMin: 3,
        posMax: 4,
        hitMin: 0,
        hitMax: 0,
        dmgMin: 0,
        dmgMax: 0,
        effects: { healStress: 15 },
        desc: 'Ease stress',
        targetType: 'ally',
      },
      {
        name: 'Scalpel',
        posMin: 3,
        posMax: 4,
        hitMin: 1,
        hitMax: 2,
        dmgMin: 5,
        dmgMax: 7,
        effects: {
          bleed: { v: 2, t: 2 },
        },
        desc: 'Surgical cut',
        targetType: 'enemy',
      },
    ],
  },
};

// Enemy definitions
const ENEMIES = {
  // --- Easy tier (Dawn ordeals) ---
  amber_bug: {
    name: 'Complete Food',
    hp: 20, speed: 3, color: '#ccaa33',
    intents: [
      { t: 'atk', v: 4, name: 'Claw' },
      { t: 'blk', v: 5, name: 'Burrow',
        selfHeal: 3 },
      { t: 'atk', v: 6, name: 'Emerge',
        bleed: 2 },
    ],
    spriteKey: 'amber_bug',
  },
  crimson_clown: {
    name: 'Cheers for the Start',
    hp: 28, speed: 4, color: '#cc3333',
    intents: [
      { t: 'atk', v: 6, name: 'Juggle' },
      { t: 'debuf', v: 1,
        name: 'Prank', stun: true },
      { t: 'atk', v: 8, name: 'Finale' },
    ],
    onDeath: { stressAll: 5 },
    spriteKey: 'crimson_clown',
  },
  green_bot: {
    name: 'Doubt',
    hp: 24, speed: 3, color: '#33aa55',
    intents: [
      { t: 'atk', v: 5, name: 'Stab',
        bleed: 1 },
      { t: 'atk', v: 7,
        name: 'Finish Off',
        bonusLowHp: 4 },
      { t: 'buff', v: 1, name: 'Scan' },
    ],
    spriteKey: 'green_bot',
  },
  // --- Medium tier (Noon ordeals) ---
  crimson_noon: {
    name: 'Harmony of Skin',
    hp: 40, speed: 5, color: '#aa2222',
    intents: [
      { t: 'atk', v: 9, name: 'Slam' },
      { t: 'atk', v: 9,
        name: 'Tumorous Grip',
        stress: 3 },
      { t: 'blk', v: 8,
        name: 'Shield Wall' },
      { t: 'atk', v: 12, name: 'Frenzy',
        vuln: 1 },
    ],
    onDeath: { stressAll: 5 },
    spriteKey: 'crimson_noon',
  },
  indigo_dawn: {
    name: 'Indigo Scout',
    hp: 35, speed: 6, color: '#4444bb',
    intents: [
      { t: 'atk', v: 7,
        name: 'Quick Strike' },
      { t: 'atk', v: 7, name: 'Devour',
        selfHeal: 4 },
      { t: 'atk', v: 10, name: 'Lunge',
        mark: 1 },
    ],
    spriteKey: 'indigo_dawn',
  },
  steel_dawn: {
    name: 'G Corp Remnant',
    hp: 38, speed: 3, color: '#888899',
    intents: [
      { t: 'atk', v: 8,
        name: 'Rifle Bash' },
      { t: 'blk', v: 10,
        name: 'Entrench', buff: 1 },
      { t: 'atk', v: 6,
        name: 'Suppressing Fire',
        weak: 1 },
    ],
    spriteKey: 'steel_dawn',
  },
  // --- Hard tier ---
  green_bot_big: {
    name: 'Process of Understanding',
    hp: 45, speed: 4, color: '#22cc55',
    intents: [
      { t: 'atk', v: 7,
        name: 'Sawblade', bleed: 2 },
      { t: 'atk', v: 4,
        name: 'Rapid Fire', hits: 3 },
      { t: 'heal', v: 10,
        name: 'Field Repair' },
      { t: 'blk', v: 6, name: 'Reload' },
    ],
    spriteKey: 'green_bot_big',
  },
  indigo_noon: {
    name: 'Indigo Sweeper',
    hp: 50, speed: 4, color: '#3333aa',
    intents: [
      { t: 'atk', v: 10, name: 'Sweep',
        stress: 2 },
      { t: 'atk', v: 14, name: 'Consume',
        selfHeal: 6 },
      { t: 'blk', v: 12,
        name: 'Armored Shell', buff: 2 },
      { t: 'atk', v: 8, name: 'Extract',
        mark: 1, stress: 3 },
    ],
    spriteKey: 'indigo_noon',
  },
  steel_noon: {
    name: 'G Corp Corporal',
    hp: 55, speed: 5, color: '#6677aa',
    intents: [
      { t: 'atk', v: 12,
        name: 'Power Strike' },
      { t: 'buff', v: 3, name: 'Rally',
        selfHeal: 5 },
      { t: 'atk', v: 15,
        name: 'Overcharge', stress: 2 },
      { t: 'blk', v: 10,
        name: 'Fortify' },
    ],
    spriteKey: 'steel_noon',
  },
  // --- Summoned minions ---
  spiderling: {
    name: 'Spiderling',
    hp: 10, speed: 5, color: '#886644',
    intents: [
      { t: 'atk', v: 3, name: 'Bite' },
      { t: 'atk', v: 4, name: 'Bite' },
    ],
    summoned: true,
    spriteKey: 'spider_minion',
  },
  bat: {
    name: 'Vampire Bat',
    hp: 8, speed: 6, color: '#553344',
    intents: [
      { t: 'atk', v: 3, name: 'Nibble' },
      { t: 'atk', v: 4, name: 'Drain',
        bleed: 1 },
    ],
    summoned: true,
    spriteKey: null,
  },
  // --- Miniboss ---
  spider_bud: {
    name: 'Spider Bud',
    hp: 80, speed: 3, color: '#886633',
    intents: [
      { t: 'debuf', v: 1,
        name: 'Web Shot', stun: true },
      { t: 'atk', v: 6,
        name: 'Poison Fang', poison: 2 },
      { t: 'summon', v: 0,
        name: 'Spawn Brood',
        summonKey: 'spiderling',
        summonCount: 2 },
      { t: 'blk', v: 10,
        name: 'Cocoon' },
    ],
    spriteKey: 'spider_bud',
  },
  // --- Final bosses ---
  big_bird: {
    name: 'Big Bird',
    hp: 120, speed: 5, color: '#ddaa22',
    intents: [
      { t: 'atk', v: 12, name: 'Peck' },
      { t: 'atk', v: 8,
        name: 'Wing Buffet',
        weakAll: 1 },
      { t: 'atk', v: 18,
        name: 'Judgement', stress: 5 },
      { t: 'special', v: 0,
        name: 'Lamp Hypnosis',
        stunCount: 2, stressV: 8 },
    ],
    phase2: {
      hpThreshold: 0.4,
      intents: [
        { t: 'atk', v: 16,
          name: 'Frenzy Peck' },
        { t: 'atk', v: 22,
          name: 'Devour',
          selfHeal: 10 },
        { t: 'special', v: 0,
          name: 'Lamp Hypnosis',
          stunCount: 2, stressV: 10 },
        { t: 'atk', v: 25,
          name: 'Crushing Blow' },
      ],
    },
    spriteKey: 'big_bird',
  },
  nosferatu: {
    name: 'Nosferatu',
    hp: 110, speed: 6, color: '#882244',
    bloodlust: true,
    intents: [
      { t: 'atk', v: 10,
        name: 'Blood Drain',
        selfHeal: 5 },
      { t: 'atk', v: 14,
        name: 'Shadow Claw', bleed: 1 },
      { t: 'summon', v: 0,
        name: 'Summon Bats',
        summonKey: 'bat',
        summonCount: 1 },
      { t: 'blk', v: 8,
        name: 'Mist Form',
        cleanse: true },
    ],
    banquet: {
      t: 'atk', v: 12,
      name: 'Banquet',
      hitAll: true, stress: 6,
    },
    spriteKey: 'nosferatu',
  },
};

// Curio definitions
const CURIOS = {
  broken_terminal: {
    title: 'Broken Terminal',
    desc: 'A flickering L-Corp terminal.',
    opt1: 'Access (+25 score)',
    opt2: 'Leave',
  },
  supply_crate: {
    title: 'Supply Crate',
    desc: 'Sealed military crate.',
    opt1: 'Open (heal 10 HP each)',
    opt2: 'Ignore',
  },
  strange_machine: {
    title: 'Strange Machine',
    desc: 'Humming apparatus.',
    opt1: 'Activate (random: heal 15 or'
      + ' 10 dmg)',
    opt2: 'Walk away',
  },
  old_locker: {
    title: 'Old Locker',
    desc: 'Rusted employee locker.',
    opt1: 'Search (-8 stress each)',
    opt2: 'Leave',
  },
};

// DungeonEngine class
class DungeonEngine {
  constructor(canvas, act) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.act = act;

    // Game state
    this.state = GS_TITLE;
    this.mapData = null;
    this.rooms = [];
    this.sprites = {};

    // Party (4 members, populated later)
    this.party = [];
    // Enemy instances for current combat
    this.enemies = [];

    // Combat state
    this.turnOrder = [];
    this.turnIdx = 0;
    this.selectedSkill = -1;
    this.targetIdx = -1;

    // Animation state
    this.animState = null;

    // UI state
    this.hoverIdx = -1;
    this.mx = 0;
    this.my = 0;
    this.selectedRoom = -1;

    // Map / exploration state
    this.currentRoom = 0;
    this.exploredRooms = [];
    this.roomsCleared = 0;
    this.light = 100;
    this.corridorTimer = 0;
    this.corridorDur = 1.2;

    // Scoring
    this.score = 0;
    this.leaderboard = [];

    // Name entry
    this.entryName = '';
    this.nameDone = false;

    // Character selection
    const keys = Object.keys(CHARACTERS);
    this.charPool = this.shuffle(
      keys.slice()
    );
    this.selectedChars = this.charPool
      .slice(0, 4);

    // Animation frame loop
    this.rafId = null;
    this.lastTime = 0;
    this.running = false;
  }

  /**
   * Shuffle an array in place
   * using Fisher-Yates algorithm.
   */
  shuffle(arr) {
    for (
      let i = arr.length - 1;
      i > 0;
      i--
    ) {
      const j = Math.floor(
        Math.random() * (i + 1)
      );
      const tmp = arr[i];
      arr[i] = arr[j];
      arr[j] = tmp;
    }
    return arr;
  }

  /**
   * Load dungeon data received
   * from the DM backend.
   */
  loadData(sd) {
    if (sd.dungeon) {
      this.rooms = sd.dungeon;
    }
    if (sd.sprites) {
      const keys = Object.keys(sd.sprites);
      for (let i = 0; i < keys.length; i++) {
        const k = keys[i];
        const img = new Image();
        img.src =
          'data:image/png;base64,'
          + sd.sprites[k];
        this.sprites[k] = img;
      }
    }
    if (sd.leaderboard) {
      this.leaderboard = sd.leaderboard;
    }
  }

  /**
   * Initialize a new run with the
   * selected party of 4 characters.
   */
  startRun() {
    this.party = [];
    for (
      let i = 0;
      i < this.selectedChars.length;
      i++
    ) {
      const key = this.selectedChars[i];
      const def = CHARACTERS[key];
      this.party.push({
        key: key,
        name: def.name,
        faction: def.faction,
        role: def.role,
        color: def.color,
        skills: def.skills,
        hp: def.hp,
        maxHp: def.maxHp,
        stress: 0,
        block: 0,
        pos: i + 1,
        statuses: {},
        alive: true,
        affliction: null,
        virtue: null,
        dmgTaken: 0,
        speed: def.speed,
        posMin: def.posMin,
        posMax: def.posMax,
      });
    }
    this.currentRoom = 0;
    this.exploredRooms = [];
    this.roomsCleared = 0;
    this.light = 100;
    this.score = 0;
    this.state = GS_MAP;
  }

  /**
   * Cycle the selected character
   * at the given slot index during
   * character selection screen.
   */
  cycleChar(slotIdx) {
    const pool = Object.keys(CHARACTERS);
    const cur = this.selectedChars[slotIdx];
    const ci = pool.indexOf(cur);
    let next = (ci + 1) % pool.length;
    // Skip characters already picked
    while (
      this.selectedChars.indexOf(
        pool[next]
      ) !== -1
      && pool[next] !== cur
    ) {
      next = (next + 1) % pool.length;
    }
    this.selectedChars[slotIdx] = pool[next];
  }

  // MAP SYSTEM

  findRoom(x, y) {
    for (let i = 0; i < this.rooms.length;
      i++) {
      if (this.rooms[i].x === x
        && this.rooms[i].y === y) {
        return i;
      }
    }
    return -1;
  }

  isConnected(ri1, ri2) {
    const r1 = this.rooms[ri1];
    const r2 = this.rooms[ri2];
    if (!r1 || !r2 || !r1.conns) {
      return false;
    }
    for (let i = 0;
      i < r1.conns.length; i++) {
      if (r1.conns[i][0] === r2.x
        && r1.conns[i][1] === r2.y) {
        return true;
      }
    }
    return false;
  }

  enterRoom(ri) {
    if (ri < 0
      || ri >= this.rooms.length) {
      return;
    }
    const room = this.rooms[ri];
    this.currentRoom = ri;
    if (this.exploredRooms
      .indexOf(ri) < 0) {
      this.exploredRooms.push(ri);
      this.light = Math.max(
        0, this.light - 7
      );
    }

    const t = room.type;
    // Check if first visit
    const firstVisit = this.exploredRooms
      .indexOf(ri)
      === this.exploredRooms.length - 1;

    if (t === 'start' || t === 'empty') {
      if (firstVisit) {
        for (let i = 0;
          i < this.party.length; i++) {
          if (this.party[i].alive) {
            this.party[i].stress
              = Math.max(
                0,
                this.party[i].stress - 3
              );
          }
        }
        this.roomsCleared++;
        this.score += 10;
      }
      this.state = GS_LOOT;
      this.lootMsg = t === 'start'
        ? 'Starting point. Stay alert.'
        : 'Empty room. Brief respite.';
      return;
    } else if (t.indexOf('combat') >= 0
      || t === 'miniboss'
      || t === 'boss') {
      this.startCombat(room);
    } else if (t === 'treasure') {
      this.handleTreasure();
    } else if (t === 'curio') {
      this.curioKey = 'broken_terminal';
      if (room.curio) {
        this.curioKey = room.curio;
      } else {
        const ck = Object.keys(CURIOS);
        this.curioKey = ck[
          Math.floor(
            Math.random() * ck.length
          )
        ];
      }
      this.curioChoice = -1;
      this.state = GS_CURIO;
    }
  }

  handleTreasure() {
    for (let i = 0;
      i < this.party.length; i++) {
      if (this.party[i].alive) {
        this.party[i].hp = Math.min(
          this.party[i].maxHp,
          this.party[i].hp + 10
        );
        this.party[i].stress = Math.max(
          0, this.party[i].stress - 5
        );
      }
    }
    this.roomsCleared++;
    this.score += 10;
    this.state = GS_LOOT;
    this.lootMsg = 'Found supplies!'
      + ' Party healed 10 HP,'
      + ' -5 stress.';
  }

  resolveCurio(choice) {
    const c = CURIOS[this.curioKey];
    if (!c) {
      this.roomsCleared++;
      this.state = GS_MAP;
      return;
    }
    if (this.curioKey
      === 'broken_terminal') {
      if (choice === 0) {
        this.score += 25;
      }
    } else if (this.curioKey
      === 'supply_crate') {
      if (choice === 0) {
        for (let i = 0;
          i < this.party.length; i++) {
          if (this.party[i].alive) {
            this.party[i].hp = Math.min(
              this.party[i].maxHp,
              this.party[i].hp + 10
            );
          }
        }
      }
    } else if (this.curioKey
      === 'strange_machine') {
      if (choice === 0) {
        if (Math.random() < 0.5) {
          for (let i = 0;
            i < this.party.length; i++) {
            if (this.party[i].alive) {
              this.party[i].hp = Math.min(
                this.party[i].maxHp,
                this.party[i].hp + 15
              );
            }
          }
        } else {
          for (let i = 0;
            i < this.party.length; i++) {
            if (this.party[i].alive) {
              this.party[i].hp
                -= 10;
              if (this.party[i].hp <= 0) {
                this.party[i].hp = 1;
              }
            }
          }
        }
      }
    } else if (this.curioKey
      === 'old_locker') {
      if (choice === 0) {
        for (let i = 0;
          i < this.party.length; i++) {
          if (this.party[i].alive) {
            this.party[i].stress
              = Math.max(
                0,
                this.party[i].stress - 8
              );
          }
        }
      }
    }
    this.roomsCleared++;
    this.score += 10;
    this.state = GS_MAP;
  }

  checkWinCondition() {
    const total = this.rooms.length;
    const needed = Math.ceil(
      (total - 1) * 0.8
    );
    const bossRoom = this.rooms.find(
      r => r.type === 'boss'
    );
    const bossDone = bossRoom
      && this.exploredRooms.indexOf(
        this.rooms.indexOf(bossRoom)
      ) >= 0;
    return this.roomsCleared >= needed
      && bossDone;
  }

  // COMBAT ENGINE

  startCombat(room) {
    const fd = room.enemies;
    if (!fd || !fd.length) {
      this.roomsCleared++;
      this.state = GS_MAP;
      return;
    }
    this.enemies = [];
    for (let i = 0; i < fd.length; i++) {
      const e = fd[i];
      const def = ENEMIES[e.type];
      if (!def) continue;
      const p2 = def.phase2 || null;
      this.enemies.push({
        type: e.type,
        name: def.name,
        hp: def.hp,
        maxHp: def.hp,
        block: 0,
        str: 0,
        speed: def.speed,
        color: def.color,
        intents: def.intents.slice(),
        intIdx: 0,
        pos: i + 1,
        statuses: {},
        alive: true,
        isBoss: !!e.boss,
        phase2: p2,
        phase2hp: p2
          ? p2.hpThreshold : 0,
        inPhase2: false,
        spriteKey: def.spriteKey
          || e.type,
        spriteImg: null,
        bloodlust: def.bloodlust
          ? 0 : undefined,
      });
    }
    // Reset party block
    for (let i = 0;
      i < this.party.length; i++) {
      this.party[i].block = 0;
      this.party[i].dmgTaken = 0;
      this.party[i].statuses = {};
    }
    this.combatRound = 0;
    this.buildTurnOrder();
    this.nextTurn();
  }

  buildTurnOrder() {
    this.turnOrder = [];
    for (let i = 0;
      i < this.party.length; i++) {
      if (this.party[i].alive) {
        this.turnOrder.push({
          type: 'party', idx: i,
          speed: this.party[i].speed,
        });
      }
    }
    for (let i = 0;
      i < this.enemies.length; i++) {
      if (this.enemies[i].alive) {
        this.turnOrder.push({
          type: 'enemy', idx: i,
          speed: this.enemies[i].speed,
        });
      }
    }
    // Sort by speed descending
    this.turnOrder.sort(
      (a, b) => b.speed - a.speed
    );
    this.turnIdx = -1;
  }

  nextTurn() {
    // Check combat end
    const partyAlive = this.party.some(
      p => p.alive
    );
    const enemyAlive = this.enemies.some(
      e => e.alive
    );
    if (!partyAlive) {
      this.state = GS_DEFEAT;
      this.act('died');
      return;
    }
    if (!enemyAlive) {
      this.endCombat();
      return;
    }

    this.turnIdx++;
    if (this.turnIdx
      >= this.turnOrder.length) {
      this.newRound();
      return;
    }

    const turn = this.turnOrder[
      this.turnIdx
    ];
    // Skip dead units
    if (turn.type === 'party') {
      const p = this.party[turn.idx];
      if (!p || !p.alive) {
        this.nextTurn();
        return;
      }
      // Check stun
      if (p.statuses.stun > 0) {
        p.statuses.stun--;
        this.nextTurn();
        return;
      }
      // Affliction: Paranoid skip
      if (p.affliction === 'paranoid'
        && Math.random() < 0.25) {
        this.nextTurn();
        return;
      }
      this.activeUnit = turn;
      this.selectedSkill = -1;
      this.targetIdx = -1;
      this.lastWasEnemy = false;
      this.state = GS_COMBAT;
    } else {
      const e = this.enemies[turn.idx];
      if (!e || !e.alive) {
        this.nextTurn();
        return;
      }
      if (e.statuses.stun > 0) {
        e.statuses.stun--;
        this.nextTurn();
        return;
      }
      // Delay between enemy turns so
      // animations don't overlap
      const delay = this.lastWasEnemy
        ? 1500 : 300;
      this.lastWasEnemy = true;
      this.state = GS_ANIM;
      setTimeout(
        () => this.executeEnemyTurn(
          turn.idx
        ),
        delay
      );
    }
  }

  newRound() {
    this.combatRound++;
    // Reset block for party
    for (let i = 0;
      i < this.party.length; i++) {
      const p = this.party[i];
      if (!p.alive) continue;
      p.block = 0;
      p.dmgTaken = 0;
      // Tick DoTs
      this.tickStatuses(p, true);
      // Virtue: stalwart
      if (p.virtue === 'stalwart') {
        for (let j = 0;
          j < this.party.length; j++) {
          if (this.party[j].alive) {
            this.party[j].stress
              = Math.max(
                0,
                this.party[j].stress - 2
              );
          }
        }
      }
    }
    // Reset block for enemies
    for (let i = 0;
      i < this.enemies.length; i++) {
      const e = this.enemies[i];
      if (!e.alive) continue;
      e.block = 0;
      this.tickStatuses(e, false);
      // Boss phase check
      if (e.phase2 && !e.inPhase2
        && e.hp <= e.maxHp
          * e.phase2hp) {
        e.inPhase2 = true;
        e.intents = e.phase2;
        e.intIdx = 0;
      }
    }
    // Check deaths from DoT
    this.checkDeaths();
    this.buildTurnOrder();
    this.nextTurn();
  }

  tickStatuses(unit, isParty) {
    const s = unit.statuses;
    if (s.bleed > 0) {
      unit.hp -= s.bleedV || 0;
      s.bleed--;
      if (s.bleed <= 0) {
        s.bleedV = 0;
      }
    }
    if (s.poison > 0) {
      unit.hp -= s.poisonV || 0;
      s.poison--;
      if (s.poisonV > 0) {
        s.poisonV--;
      }
    }
    if (s.burn > 0) {
      unit.hp -= s.burnV || 0;
      s.burn--;
      if (s.burn <= 0) {
        s.burnV = 0;
      }
    }
    if (s.mark > 0) s.mark--;
    if (s.blind > 0) s.blind--;
    if (s.vuln > 0) s.vuln--;
    if (s.weak > 0) s.weak--;
    if (s.riposte > 0) s.riposte--;
    if (s.protect) s.protect = null;
    if (unit.hp <= 0) {
      unit.hp = 0;
      unit.alive = false;
      if (isParty) {
        // Ally death stress
        for (let i = 0;
          i < this.party.length; i++) {
          if (this.party[i].alive) {
            this.addStress(
              this.party[i], 15
            );
          }
        }
      }
    }
  }

  checkDeaths() {
    for (let i = 0;
      i < this.party.length; i++) {
      if (this.party[i].hp <= 0) {
        this.party[i].alive = false;
      }
    }
    for (let i = 0;
      i < this.enemies.length; i++) {
      if (this.enemies[i].hp <= 0) {
        this.enemies[i].alive = false;
      }
    }
  }

  selectSkill(si) {
    const turn = this.activeUnit;
    if (!turn || turn.type !== 'party') {
      return;
    }
    const p = this.party[turn.idx];
    const skill = p.skills[si];
    if (!skill) return;
    // Check position requirement
    if (p.pos < skill.posMin
      || p.pos > skill.posMax) {
      return;
    }
    this.selectedSkill = si;
    if (skill.targetType === 'self'
      || skill.targetType === 'party') {
      this.executeSkill(si, -1);
    } else {
      this.state = GS_TARGETING;
      this.targetIdx = -1;
    }
  }

  selectTarget(ti) {
    if (this.selectedSkill < 0) return;
    const turn = this.activeUnit;
    const p = this.party[turn.idx];
    const skill = p.skills[
      this.selectedSkill
    ];
    if (skill.targetType === 'ally') {
      // ti is party index
      if (ti < 0
        || ti >= this.party.length
        || !this.party[ti].alive
        || ti === turn.idx) {
        return;
      }
      this.executeSkill(
        this.selectedSkill, ti
      );
    } else {
      // ti is enemy index
      if (ti < 0
        || ti >= this.enemies.length
        || !this.enemies[ti].alive) {
        return;
      }
      const e = this.enemies[ti];
      if (e.pos < skill.hitMin
        || e.pos > skill.hitMax) {
        return;
      }
      this.executeSkill(
        this.selectedSkill, ti
      );
    }
  }

  executeSkill(si, ti) {
    const turn = this.activeUnit;
    const p = this.party[turn.idx];
    const skill = p.skills[si];
    const eff = skill.effects || {};
    const tType = skill.targetType;

    // Ally/self: use 'support' anim type
    // Enemy: use 'party' attack anim
    if (tType === 'ally') {
      this.startSupportAnim(
        turn.idx, ti,
        () => this.resolveSkill(
          si, ti, turn.idx
        )
      );
    } else if (tType === 'self'
      || tType === 'party') {
      this.startSupportAnim(
        turn.idx, turn.idx,
        () => this.resolveSkill(
          si, ti, turn.idx
        )
      );
    } else {
      this.startAttackAnim(
        'party', turn.idx, ti,
        () => this.resolveSkill(
          si, ti, turn.idx
        )
      );
    }
  }

  resolveSkill(si, ti, pi) {
    const p = this.party[pi];
    const skill = p.skills[si];
    const eff = skill.effects || {};
    const tType = skill.targetType;

    if (tType === 'enemy') {
      const e = this.enemies[ti];
      if (!e || !e.alive) {
        this.nextTurn();
        return;
      }
      const hits = eff.hits || 1;
      for (let h = 0; h < hits; h++) {
        let dmg = this.rollDmg(
          skill.dmgMin, skill.dmgMax
        );
        // Affliction: Hopeless
        if (p.affliction === 'hopeless') {
          dmg = Math.floor(dmg * 0.7);
        }
        // Virtue: Courageous
        if (p.virtue === 'courageous') {
          dmg = Math.floor(dmg * 1.25);
        }
        // Weak debuff on attacker
        if (p.statuses.weak > 0) {
          dmg = Math.max(
            0, dmg - (p.statuses.weakV
              || 4)
          );
        }
        // Vuln on target
        if (e.statuses.vuln > 0) {
          dmg = Math.floor(dmg * 1.5);
        }
        // Mark on target
        if (e.statuses.mark > 0) {
          dmg = Math.floor(dmg * 1.5);
        }
        // Blind: miss chance
        if (p.statuses.blind > 0
          && Math.random() < 0.5) {
          dmg = 0;
        }
        this.damageUnit(e, dmg);
      }
      // Apply status effects
      if (eff.bleed) {
        e.statuses.bleed
          = (e.statuses.bleed || 0)
            + eff.bleed.t;
        e.statuses.bleedV = eff.bleed.v;
      }
      if (eff.poison) {
        e.statuses.poison
          = (e.statuses.poison || 0)
            + eff.poison.t;
        e.statuses.poisonV = eff.poison.v;
      }
      if (eff.burn) {
        e.statuses.burn
          = (e.statuses.burn || 0)
            + eff.burn.t;
        e.statuses.burnV = eff.burn.v;
      }
      if (eff.stun) {
        e.statuses.stun
          = (e.statuses.stun || 0)
            + eff.stun;
      }
      if (eff.mark) {
        e.statuses.mark = eff.mark;
      }
      if (eff.blind) {
        e.statuses.blind = eff.blind;
      }
      if (eff.vuln) {
        e.statuses.vuln = eff.vuln;
      }
      this.act('sfx', { s: 'hit' });
    } else if (tType === 'self') {
      if (eff.selfBlock) {
        p.block += eff.selfBlock;
      }
      if (eff.selfHeal) {
        p.hp = Math.min(
          p.maxHp, p.hp + eff.selfHeal
        );
      }
      if (eff.moveBack) {
        const np = p.pos + eff.moveBack;
        if (np >= 1 && np <= 4) {
          p.pos = np;
        }
      }
      if (eff.riposte) {
        p.statuses.riposte = 1;
        p.statuses.riposteDmg
          = eff.riposte;
      }
      if (eff.parryDmg) {
        p.statuses.riposte = 1;
        p.statuses.riposteDmg
          = eff.parryDmg;
      }
      this.act('sfx', { s: 'block' });
    } else if (tType === 'ally') {
      const ally = this.party[ti];
      if (!ally || !ally.alive) {
        this.nextTurn();
        return;
      }
      if (eff.heal) {
        const hv = typeof eff.heal === 'object'
          ? (eff.heal.v || 0) : eff.heal;
        const amt = this.rollDmg(hv, hv);
        if (ally.alive) {
          ally.hp = Math.min(
            ally.maxHp, ally.hp + amt
          );
        }
      }
      if (eff.healStress) {
        ally.stress = Math.max(
          0, ally.stress - eff.healStress
        );
      }
      if (eff.protect) {
        p.statuses.protect = ti;
      }
      this.act('sfx', { s: 'heal' });
    } else if (tType === 'party') {
      if (eff.partyBlock) {
        for (let i = 0;
          i < this.party.length; i++) {
          if (this.party[i].alive) {
            this.party[i].block
              += eff.partyBlock;
          }
        }
      }
      this.act('sfx', { s: 'block' });
    }

    this.selectedSkill = -1;
    this.state = GS_COMBAT;
    this.checkDeaths();
    // Check combat end
    const ea = this.enemies.some(
      e => e.alive
    );
    if (!ea) {
      this.endCombat();
      return;
    }
    this.nextTurn();
  }

  doSwap(allyIdx) {
    const turn = this.activeUnit;
    if (!turn
      || turn.type !== 'party') return;
    const p = this.party[turn.idx];
    const ally = this.party[allyIdx];
    if (!ally || !ally.alive) return;
    // Must be adjacent position
    if (Math.abs(p.pos - ally.pos) !== 1) {
      return;
    }
    const tmp = p.pos;
    p.pos = ally.pos;
    ally.pos = tmp;
    // Swap costs the turn
    this.nextTurn();
  }

  executeEnemyTurn(ei) {
    const e = this.enemies[ei];
    if (!e || !e.alive) {
      this.nextTurn();
      return;
    }

    // Nosferatu bloodlust check
    let intent;
    if (e.bloodlust !== undefined
      && e.bloodlust >= 4
      && ENEMIES[e.type]
      && ENEMIES[e.type].banquet) {
      intent = ENEMIES[e.type].banquet;
      e.bloodlust = 0;
    } else {
      intent = e.intents[
        e.intIdx % e.intents.length
      ];
      e.intIdx++;
    }
    // Increment bloodlust
    if (e.bloodlust !== undefined) {
      e.bloodlust++;
    }

    this.state = GS_ANIM;

    // Show attack name bubble
    if (intent.name) {
      const bClr = {
        atk: '#ff4444', blk: '#4488cc',
        heal: '#44cc44', buff: '#ccaa44',
        special: '#cc44cc',
        debuf: '#cc44cc',
        summon: '#cc8844',
      };
      this.atkBubble = {
        text: intent.name,
        clr: bClr[intent.t] || '#aaa',
        t: 0, dur: 1.0,
      };
    }

    // Find alive party members
    const alive = [];
    for (let i = 0;
      i < this.party.length; i++) {
      if (this.party[i].alive) {
        alive.push(i);
      }
    }
    if (!alive.length) {
      this.state = GS_DEFEAT;
      this.act('died');
      return;
    }
    const ti = alive[
      Math.floor(
        Math.random() * alive.length
      )
    ];

    switch (intent.t) {
      case 'atk': {
        if (intent.hitAll) {
          // AoE attack (Banquet)
          this.startAttackAnim(
            'enemy', ei, ti,
            () => {
              for (let i = 0;
                i < this.party.length;
                i++) {
                if (this.party[i].alive) {
                  this.resolveEnemyAtk(
                    ei, i, intent.v
                  );
                  if (intent.stress) {
                    this.addStress(
                      this.party[i],
                      intent.stress
                    );
                  }
                }
              }
            }
          );
        } else {
          const hits = intent.hits || 1;
          this.startAttackAnim(
            'enemy', ei, ti,
            () => {
              for (let h = 0;
                h < hits; h++) {
                let v = intent.v;
                if (intent.bonusLowHp
                  && this.party[ti].hp
                  < this.party[ti].maxHp
                    * 0.5) {
                  v += intent.bonusLowHp;
                }
                this.resolveEnemyAtk(
                  ei, ti, v
                );
              }
              // Post-attack effects
              const p = this.party[ti];
              if (intent.bleed && p.alive) {
                p.statuses.bleed
                  = (p.statuses.bleed || 0)
                    + intent.bleed;
                if (!p.statuses.bleedV) {
                  p.statuses.bleedV
                    = intent.bleed;
                }
              }
              if (intent.stress && p.alive) {
                this.addStress(
                  p, intent.stress
                );
              }
              if (intent.mark && p.alive) {
                p.statuses.mark
                  = (p.statuses.mark || 0)
                    + intent.mark;
              }
              if (intent.vuln && p.alive) {
                p.statuses.vuln
                  = (p.statuses.vuln || 0)
                    + intent.vuln;
              }
              if (intent.weak && p.alive) {
                p.statuses.weak
                  = (p.statuses.weak || 0)
                    + intent.weak;
                p.statuses.weakV = 2;
              }
              if (intent.poison
                && p.alive) {
                p.statuses.poison
                  = (p.statuses.poison || 0)
                    + intent.poison;
                p.statuses.poisonV
                  = intent.poison;
              }
              if (intent.selfHeal) {
                e.hp = Math.min(
                  e.maxHp,
                  e.hp + intent.selfHeal
                );
              }
              // weakAll
              if (intent.weakAll) {
                for (let i = 0;
                  i < this.party.length;
                  i++) {
                  if (this.party[i].alive) {
                    this.party[i]
                      .statuses.weak
                      = (this.party[i]
                        .statuses.weak
                        || 0)
                        + intent.weakAll;
                    this.party[i]
                      .statuses.weakV = 2;
                  }
                }
              }
            }
          );
        }
        return;
      }
      case 'blk':
        e.block += intent.v;
        if (intent.buff) e.str += intent.buff;
        if (intent.selfHeal) {
          e.hp = Math.min(
            e.maxHp,
            e.hp + intent.selfHeal
          );
        }
        this.act('sfx', { s: 'block' });
        break;
      case 'buff':
        e.str += intent.v;
        if (intent.selfHeal) {
          e.hp = Math.min(
            e.maxHp,
            e.hp + intent.selfHeal
          );
        }
        break;
      case 'heal': {
        const hv = typeof intent.v
          === 'object'
          ? (intent.v.v || 0) : intent.v;
        let target = e;
        for (let i = 0;
          i < this.enemies.length; i++) {
          if (this.enemies[i].alive
            && this.enemies[i].hp
              < target.hp) {
            target = this.enemies[i];
          }
        }
        target.hp = Math.min(
          target.maxHp,
          target.hp + hv
        );
        this.act('sfx', { s: 'heal' });
        break;
      }
      case 'debuf': {
        // Apply debuff to random target
        const p = this.party[ti];
        if (intent.stun && p.alive) {
          p.statuses.stun
            = (p.statuses.stun || 0) + 1;
        }
        if (intent.stress && p.alive) {
          this.addStress(
            p, intent.stress
          );
        }
        break;
      }
      case 'summon': {
        // Spawn minions
        const maxE = 4;
        const aliveE = this.enemies
          .filter(en => en.alive).length;
        const count = Math.min(
          intent.summonCount || 1,
          maxE - aliveE
        );
        for (let s = 0; s < count; s++) {
          const def = ENEMIES[
            intent.summonKey
          ];
          if (!def) continue;
          this.enemies.push({
            type: intent.summonKey,
            name: def.name,
            hp: def.hp,
            maxHp: def.hp,
            alive: true,
            block: 0,
            str: 0,
            speed: def.speed,
            intents: def.intents,
            intIdx: 0,
            color: def.color,
            spriteKey: def.spriteKey,
            spriteImg: null,
            statuses: {},
            summoned: true,
          });
        }
        this.act('sfx', { s: 'heal' });
        break;
      }
      case 'special': {
        // Boss specials
        if (intent.stunCount) {
          // Lamp Hypnosis
          const targets = alive.slice();
          for (let s = 0;
            s < intent.stunCount
            && targets.length > 0; s++) {
            const ri = Math.floor(
              Math.random()
              * targets.length
            );
            const pi = targets.splice(
              ri, 1
            )[0];
            this.party[pi].statuses.stun
              = (this.party[pi]
                .statuses.stun || 0) + 1;
            if (intent.stressV) {
              this.addStress(
                this.party[pi],
                intent.stressV
              );
            }
          }
        }
        // Cleanse (Mist Form)
        if (intent.cleanse) {
          e.statuses = {};
        }
        break;
      }
      default: break;
    }

    setTimeout(
      () => this.nextTurn(), 500
    );
  }

  resolveEnemyAtk(ei, ti, baseDmg) {
    const e = this.enemies[ei];
    const p = this.party[ti];
    if (!p || !p.alive) {
      this.nextTurn();
      return;
    }
    let dmg = baseDmg + (e.str || 0);
    // Vuln on target
    if (p.statuses.vuln > 0) {
      dmg = Math.floor(dmg * 1.5);
    }
    // Protect: redirect
    if (p.statuses.protect !== null
      && p.statuses.protect !== undefined) {
      const prot = this.party[
        p.statuses.protect
      ];
      if (prot && prot.alive) {
        this.damageUnit(prot, dmg);
        this.act('sfx', { s: 'hurt' });
        this.nextTurn();
        return;
      }
    }
    this.damageUnit(p, dmg);
    p.dmgTaken += dmg;
    // Stress from hit
    if (dmg > 8) {
      this.addStress(p, 5);
    }
    // Low light extra stress
    if (this.light < 30) {
      this.addStress(p, 3);
    }
    // Riposte check
    if (p.statuses.riposte > 0
      && p.alive) {
      const rd = p.statuses.riposteDmg
        || 5;
      this.damageUnit(e, rd);
    }
    this.act('sfx', { s: 'hurt' });
    this.checkDeaths();
    this.nextTurn();
  }

  damageUnit(unit, dmg) {
    if (unit.block > 0) {
      if (dmg <= unit.block) {
        unit.block -= dmg;
        this.addFloatText(
          CW / 2, 180,
          'Blocked!', '#4488cc'
        );
        return;
      }
      dmg -= unit.block;
      unit.block = 0;
    }
    unit.hp -= dmg;
    if (dmg > 0) {
      this.addFloatText(
        CW / 2 + (Math.random() - 0.5)
          * 60,
        170 + Math.random() * 20,
        '-' + dmg, '#ff4444'
      );
    }
    if (unit.hp <= 0) {
      unit.hp = 0;
      unit.alive = false;
      this.score += 5;
      // On-death effects
      const def = ENEMIES[unit.type];
      if (def && def.onDeath) {
        if (def.onDeath.stressAll) {
          for (let i = 0;
            i < this.party.length; i++) {
            if (this.party[i].alive) {
              this.addStress(
                this.party[i],
                def.onDeath.stressAll
              );
            }
          }
        }
      }
    }
  }

  rollDmg(min, max) {
    if (!min && !max) return 0;
    if (!max) return min;
    return min + Math.floor(
      Math.random() * (max - min + 1)
    );
  }

  addStress(p, amount) {
    if (!p.alive) return;
    p.stress += amount;
    if (p.stress >= 200) {
      // Heart attack
      p.hp = 0;
      p.alive = false;
      return;
    }
    if (p.stress >= 100
      && !p.affliction
      && !p.virtue) {
      // Affliction check
      if (Math.random() < 0.25) {
        // Virtue
        const v = ['courageous',
          'stalwart'];
        p.virtue = v[
          Math.floor(
            Math.random() * v.length
          )
        ];
      } else {
        const a = ['paranoid',
          'hopeless', 'selfish'];
        p.affliction = a[
          Math.floor(
            Math.random() * a.length
          )
        ];
      }
    }
  }

  endCombat() {
    this.roomsCleared++;
    this.score += 10;
    // Check for boss kill
    const hadBoss = this.enemies.some(
      e => e.isBoss
    );
    if (hadBoss) {
      this.score += 50;
    }
    this.state = GS_LOOT;
    this.lootMsg = 'Combat cleared!'
      + (hadBoss ? ' Boss defeated!' : '')
      + ' +' + (hadBoss ? 60 : 10)
      + ' score.';
    // Check win
    if (this.checkWinCondition()) {
      this.calcFinalScore();
      this.entryName = '';
      this.nameDone = false;
      this.state = GS_NAMEENTRY;
    }
  }

  calcFinalScore() {
    for (let i = 0;
      i < this.party.length; i++) {
      const p = this.party[i];
      if (p.alive) {
        this.score += p.hp * 2;
      }
      if (p.affliction) {
        this.score -= 10;
      }
      if (p.virtue) {
        this.score += 20;
      }
    }
    if (this.light > 50) {
      this.score = Math.floor(
        this.score * 1.2
      );
    }
  }

  // ANIMATION

  startAttackAnim(aType, ai, ti, cb) {
    this.animState = {
      type: aType,
      attackerIdx: ai,
      targetIdx: ti,
      phase: 'lunge',
      timer: 0,
      lungeTime: 0.2,
      zoomTime: 0.8,
      returnTime: 0.2,
      callback: cb,
    };
    this.state = GS_ANIM;
  }

  startSupportAnim(casterIdx, tgtIdx,
    cb) {
    this.animState = {
      type: 'support',
      attackerIdx: casterIdx,
      targetIdx: tgtIdx,
      phase: 'lunge',
      timer: 0,
      lungeTime: 0.15,
      zoomTime: 0.6,
      returnTime: 0.15,
      callback: cb,
    };
    this.state = GS_ANIM;
  }

  updateAnim(dt) {
    if (!this.animState) return;
    const a = this.animState;
    a.timer += dt;
    if (a.phase === 'lunge'
      && a.timer >= a.lungeTime) {
      a.phase = 'zoom';
      a.timer = 0;
      // Resolve effects at zoom start
      // so player sees them during zoom
      if (a.callback) a.callback();
      a.callback = null;
    } else if (a.phase === 'zoom'
      && a.timer >= a.zoomTime) {
      a.phase = 'return';
      a.timer = 0;
    } else if (a.phase === 'return'
      && a.timer >= a.returnTime) {
      this.animState = null;
    }
  }

  // Floating damage numbers
  addFloatText(x, y, text, clr) {
    this.floats.push({
      x, y, text, clr, t: 0, dur: 0.6,
    });
  }

  updateFloats(dt) {
    for (let i = this.floats.length - 1;
      i >= 0; i--) {
      this.floats[i].t += dt;
      if (this.floats[i].t
        >= this.floats[i].dur) {
        this.floats.splice(i, 1);
      }
    }
    // Attack name bubble decay
    if (this.atkBubble) {
      this.atkBubble.t += dt;
      if (this.atkBubble.t
        >= this.atkBubble.dur) {
        this.atkBubble = null;
      }
    }
  }

  // RENDER

  start() {
    this.lastTime = performance.now();
    this.running = true;
    this.floats = [];
    this.atkBubble = null;
    this.loop(this.lastTime);
  }

  stop() {
    this.running = false;
    if (this.rafId) {
      cancelAnimationFrame(this.rafId);
    }
  }

  loop(time) {
    if (!this.running) return;
    const dt = Math.min(
      (time - this.lastTime) / 1000,
      0.05
    );
    this.lastTime = time;
    this.updateAnim(dt);
    this.updateFloats(dt);
    // Corridor walk timer
    if (this.state === GS_CORRIDOR) {
      this.corridorTimer += dt;
      if (this.corridorTimer
        >= this.corridorDur) {
        this.enterRoom(
          this.corridorTarget
        );
      }
    }
    this.render();
    this.rafId = requestAnimationFrame(
      t => this.loop(t)
    );
  }

  render() {
    const ctx = this.ctx;
    ctx.fillStyle = '#0a0a12';
    ctx.fillRect(0, 0, CW, CH);

    switch (this.state) {
      case GS_TITLE:
        this.renderTitle();
        break;
      case GS_CHARSEL:
        this.renderCharSel();
        break;
      case GS_MAP:
        this.renderMap();
        break;
      case GS_CORRIDOR:
        this.renderCorridor();
        break;
      case GS_COMBAT:
      case GS_TARGETING:
      case GS_ANIM:
        this.renderCombat();
        break;
      case GS_LOOT:
        this.renderLoot();
        break;
      case GS_CURIO:
        this.renderCurio();
        break;
      case GS_VICTORY:
        this.renderVictory();
        break;
      case GS_DEFEAT:
        this.renderDefeat();
        break;
      case GS_NAMEENTRY:
        this.renderNameEntry();
        break;
      default: break;
    }
    this.renderFloats();
  }

  renderTitle() {
    const ctx = this.ctx;
    ctx.strokeStyle = '#4466aa';
    ctx.lineWidth = 3;
    ctx.strokeRect(
      10, 10, CW - 20, CH - 20
    );
    this.cText(
      'L-CORP DEPTHS', '#4466aa', 30, -100
    );
    this.cText(
      'Buried Facility Expedition',
      '#888', 14, -64
    );
    this.cText(
      'Clear the underground.',
      '#aaa', 12, -34
    );
    this.cText(
      'Turn-based combat.',
      '#aaa', 12, -16
    );
    this.cText(
      'Manage stress. Survive.',
      '#aaa', 12, 2
    );
    this.cText(
      'Press ENTER to Start',
      '#44ff44', 18, 44
    );
    this.cText(
      '-- LEADERBOARD --',
      '#ffaa44', 12, 80
    );
    const lb = this.leaderboard || [];
    if (!lb.length) {
      this.cText(
        'No scores yet', '#666', 11, 98
      );
    }
    for (let i = 0; i < lb.length
      && i < 5; i++) {
      const e = lb[i];
      const n = (e.name || '???')
        .substring(0, 6);
      this.cText(
        (i + 1) + '. ' + n
          + ' ' + (e.score || 0),
        '#ffff44', 11, 98 + i * 16
      );
    }
  }

  renderCharSel() {
    const ctx = this.ctx;
    this.cText(
      'SELECT YOUR PARTY',
      '#4466aa', 18, -160
    );
    this.cText(
      'Click a slot to cycle class',
      '#888', 10, -136
    );

    const keys = this.selectedChars;
    this.charRects = [];
    for (let i = 0; i < 4; i++) {
      const def = CHARACTERS[keys[i]];
      if (!def) continue;
      const bx = 20 + i * 155;
      const by = 70;
      const bw = 145;
      const bh = 260;
      const hov = this.mx >= bx
        && this.mx <= bx + bw
        && this.my >= by
        && this.my <= by + bh;

      ctx.fillStyle = hov
        ? '#1a1a28' : '#12121a';
      ctx.fillRect(bx, by, bw, bh);
      ctx.strokeStyle = hov
        ? def.color : '#333';
      ctx.lineWidth = hov ? 2 : 1;
      ctx.strokeRect(bx, by, bw, bh);
      ctx.lineWidth = 1;

      // Color bar
      ctx.fillStyle = def.color;
      ctx.fillRect(bx, by, bw, 5);

      // Name
      ctx.fillStyle = def.color;
      ctx.font = '10px monospace';
      ctx.fillText(
        def.name, bx + 6, by + 22
      );

      // Faction / Role
      ctx.fillStyle = '#888';
      ctx.font = '8px monospace';
      ctx.fillText(
        def.faction, bx + 6, by + 36
      );
      ctx.fillText(
        def.role + ' | Pos '
          + def.posMin + '-'
          + def.posMax,
        bx + 6, by + 48
      );

      // Stats
      ctx.fillStyle = '#aaa';
      ctx.fillText(
        'HP:' + def.hp
          + ' Spd:' + def.speed,
        bx + 6, by + 64
      );

      // Skills
      ctx.fillStyle = '#777';
      ctx.font = '7px monospace';
      let sy = by + 82;
      for (let si = 0;
        si < def.skills.length; si++) {
        const sk = def.skills[si];
        ctx.fillStyle = '#cc8844';
        ctx.fillText(
          sk.name, bx + 6, sy
        );
        ctx.fillStyle = '#888';
        ctx.fillText(
          sk.desc.substring(0, 22),
          bx + 6, sy + 10
        );
        sy += 24;
      }

      // Sprite placeholder
      ctx.fillStyle = def.color;
      ctx.fillRect(
        bx + 50, by + 210, 32, 40
      );

      this.charRects.push({
        x: bx, y: by, w: bw, h: bh,
        idx: i,
      });
    }

    // Start button
    const sbx = CW / 2 - 60;
    const sby = CH - 36;
    ctx.fillStyle = '#335533';
    ctx.fillRect(sbx, sby, 120, 28);
    ctx.strokeStyle = '#44cc44';
    ctx.strokeRect(sbx, sby, 120, 28);
    ctx.fillStyle = '#44cc44';
    ctx.font = '11px monospace';
    ctx.fillText(
      'BEGIN DESCENT', sbx + 8, sby + 18
    );
  }

  renderMap() {
    const ctx = this.ctx;
    // Header
    ctx.fillStyle = '#4466aa';
    ctx.font = '12px monospace';
    ctx.fillText(
      'L-CORP DEPTHS  B7', 10, 20
    );
    ctx.fillStyle = '#aaa';
    ctx.font = '9px monospace';
    ctx.fillText(
      'Light:' + this.light + '%'
        + '  Cleared:'
        + this.roomsCleared
        + '/' + this.rooms.length
        + '  Score:' + this.score,
      10, 36
    );

    // Draw 5x5 grid
    const gx = 60;
    const gy = 50;
    const cellW = 80;
    const cellH = 50;
    const nodeR = 16;

    // Draw corridors first
    for (let i = 0;
      i < this.rooms.length; i++) {
      const r = this.rooms[i];
      if (!r.conns) continue;
      const rx = gx
        + (r.x - 1) * cellW + cellW / 2;
      const ry = gy
        + (r.y - 1) * cellH + cellH / 2;
      for (let c = 0;
        c < r.conns.length; c++) {
        const tx = gx
          + (r.conns[c][0] - 1) * cellW
          + cellW / 2;
        const ty = gy
          + (r.conns[c][1] - 1) * cellH
          + cellH / 2;
        ctx.strokeStyle = '#2a2a35';
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.moveTo(rx, ry);
        ctx.lineTo(tx, ty);
        ctx.stroke();
        ctx.lineWidth = 1;
      }
    }

    // Draw room nodes
    const typeClr = {
      start: '#44cc44',
      combat_easy: '#cc4444',
      combat_med: '#cc6644',
      combat_hard: '#cc44cc',
      miniboss: '#ff44ff',
      boss: '#ffaa33',
      treasure: '#cccc44',
      curio: '#4488cc',
      empty: '#555',
    };

    for (let i = 0;
      i < this.rooms.length; i++) {
      const r = this.rooms[i];
      const nx = gx
        + (r.x - 1) * cellW + cellW / 2;
      const ny = gy
        + (r.y - 1) * cellH + cellH / 2;
      const explored = this.exploredRooms
        .indexOf(i) >= 0;
      const isCurrent = i
        === this.currentRoom;
      const clr = typeClr[r.type]
        || '#888';

      // Node circle
      ctx.fillStyle = explored
        ? '#1a1a22' : '#0f0f18';
      ctx.beginPath();
      ctx.arc(
        nx, ny, nodeR, 0, Math.PI * 2
      );
      ctx.fill();

      // Border
      if (isCurrent) {
        ctx.strokeStyle = '#ffcc44';
        ctx.lineWidth = 3;
      } else if (this.isReachable(i)) {
        ctx.strokeStyle = clr;
        ctx.lineWidth = 2;
      } else {
        ctx.strokeStyle = explored
          ? '#444' : '#222';
        ctx.lineWidth = 1;
      }
      ctx.stroke();
      ctx.lineWidth = 1;

      // Room type icon/label
      if (explored || this.isReachable(i)
        || isCurrent) {
        ctx.fillStyle = explored
          ? '#666' : clr;
        ctx.font = '7px monospace';
        const label = this.roomLabel(
          r.type
        );
        const lw = ctx.measureText(
          label
        ).width;
        ctx.fillText(
          label, nx - lw / 2, ny + 3
        );
      } else {
        ctx.fillStyle = '#333';
        ctx.font = '9px monospace';
        ctx.fillText('?', nx - 3, ny + 3);
      }
    }

    // Party summary at bottom
    this.renderPartySummary(310);

    // Instructions
    ctx.fillStyle = '#555';
    ctx.font = '8px monospace';
    ctx.fillText(
      'Click a connected room to enter',
      CW / 2 - 100, CH - 8
    );
  }

  isReachable(ri) {
    if (this.currentRoom < 0) {
      // First room: any start room
      return this.rooms[ri]
        && this.rooms[ri].type === 'start';
    }
    return this.isConnected(
      this.currentRoom, ri
    );
  }

  roomLabel(type) {
    switch (type) {
      case 'start': return 'START';
      case 'combat_easy': return 'FIGHT';
      case 'combat_med': return 'FIGHT';
      case 'combat_hard': return 'HARD';
      case 'miniboss': return 'MINI';
      case 'boss': return 'BOSS';
      case 'treasure': return 'LOOT';
      case 'curio': return 'CURIO';
      case 'empty': return 'SAFE';
      default: return '???';
    }
  }

  renderPartySummary(startY) {
    const ctx = this.ctx;
    const pw = 140;
    for (let i = 0;
      i < this.party.length; i++) {
      const p = this.party[i];
      const px = 20 + i * (pw + 10);
      const py = startY;

      ctx.fillStyle = p.alive
        ? '#12121a' : '#1a0a0a';
      ctx.fillRect(px, py, pw, 70);
      ctx.strokeStyle = p.alive
        ? p.color : '#444';
      ctx.strokeRect(px, py, pw, 70);

      // Name
      ctx.fillStyle = p.alive
        ? p.color : '#666';
      ctx.font = '8px monospace';
      ctx.fillText(
        p.name, px + 4, py + 12
      );

      // HP bar
      ctx.fillStyle = '#333';
      ctx.fillRect(
        px + 4, py + 18, pw - 8, 8
      );
      const hpF = p.hp / p.maxHp;
      ctx.fillStyle = hpF > 0.5
        ? '#44aa44' : hpF > 0.25
          ? '#cccc44' : '#cc4444';
      ctx.fillRect(
        px + 4, py + 18,
        (pw - 8) * hpF, 8
      );
      ctx.fillStyle = '#fff';
      ctx.font = '7px monospace';
      ctx.fillText(
        p.hp + '/' + p.maxHp,
        px + 6, py + 25
      );

      // Stress bar
      ctx.fillStyle = '#222';
      ctx.fillRect(
        px + 4, py + 30, pw - 8, 6
      );
      const stF = Math.min(
        1, p.stress / 100
      );
      ctx.fillStyle = stF > 0.75
        ? '#cc4444' : stF > 0.5
          ? '#cc8844' : '#ccaa44';
      ctx.fillRect(
        px + 4, py + 30,
        (pw - 8) * stF, 6
      );
      ctx.fillText(
        'St:' + p.stress,
        px + 6, py + 36
      );

      // Affliction/Virtue
      if (p.affliction) {
        ctx.fillStyle = '#ff4444';
        ctx.fillText(
          p.affliction, px + 4, py + 50
        );
      } else if (p.virtue) {
        ctx.fillStyle = '#44ff44';
        ctx.fillText(
          p.virtue, px + 4, py + 50
        );
      }

      // Position
      ctx.fillStyle = '#888';
      ctx.fillText(
        'Pos:' + p.pos,
        px + 4, py + 62
      );
    }
  }

  renderCombat() {
    const ctx = this.ctx;
    const t = performance.now();

    // === BACKGROUND ===
    // Ceiling/walls
    ctx.fillStyle = '#141420';
    ctx.fillRect(0, 0, CW, CH);
    // Back wall with panels
    ctx.fillStyle = '#1a1a28';
    ctx.fillRect(0, 0, CW, 160);
    for (let px = 0; px < CW; px += 80) {
      ctx.strokeStyle = '#222233';
      ctx.strokeRect(
        px + 2, 10, 76, 145
      );
      // Rivets
      ctx.fillStyle = '#2a2a38';
      ctx.fillRect(px + 6, 14, 3, 3);
      ctx.fillRect(px + 70, 14, 3, 3);
      ctx.fillRect(px + 6, 148, 3, 3);
      ctx.fillRect(px + 70, 148, 3, 3);
    }
    // Overhead lights
    for (let lx = 100; lx < CW;
      lx += 200) {
      const fl = Math.sin(
        t * 0.007 + lx * 0.05
      );
      ctx.fillStyle = 'rgba(120,140,160,'
        + (0.12 + fl * 0.06)
          .toFixed(3) + ')';
      ctx.fillRect(lx - 30, 155, 60, 3);
    }
    // Floor
    ctx.fillStyle = '#1c1c28';
    ctx.fillRect(0, 260, CW, 140);
    ctx.strokeStyle = '#222235';
    for (let fx = 0; fx < CW; fx += 64) {
      ctx.beginPath();
      ctx.moveTo(fx, 260);
      ctx.lineTo(fx, CH);
      ctx.stroke();
    }

    // === ZOOM TRANSFORM ===
    const zooming = this.animState
      && this.animState.phase === 'zoom';
    if (zooming) {
      ctx.save();
      // Focal point = target position
      const a = this.animState;
      let fx = CW / 2;
      let fy = 210;
      const isSup = a.type === 'support';
      const uw = 60;
      const ug = 8;
      if (a.type === 'party') {
        // Zoom on the enemy target
        const eLen = this.enemies.length;
        const esX = CW - 20
          - eLen * (uw + ug);
        const ti = a.targetIdx >= 0
          ? a.targetIdx : 0;
        fx = esX + ti * (uw + ug)
          + uw / 2;
      } else if (isSup) {
        // Zoom on the ally target
        const tgt = this.party[
          a.targetIdx
        ];
        if (tgt) {
          const ts = 4 - tgt.pos;
          fx = 20 + ts * (uw + ug)
            + uw / 2;
        }
      } else if (a.type === 'enemy') {
        // Zoom on the party target
        const tp = this.party[
          a.targetIdx
        ];
        if (tp) {
          const ts = 4 - tp.pos;
          fx = 20 + ts * (uw + ug)
            + uw / 2;
        }
      }
      const zs = 1.8;
      ctx.translate(fx, fy);
      ctx.scale(zs, zs);
      ctx.translate(-fx, -fy);
      // Dim overlay
      ctx.fillStyle = isSup
        ? 'rgba(0,20,0,0.2)'
        : 'rgba(0,0,0,0.15)';
      ctx.fillRect(
        -CW, -CH, CW * 3, CH * 3
      );
    }

    // Header
    ctx.fillStyle = 'rgba(10,10,18,0.8)';
    ctx.fillRect(0, 0, CW, 22);
    ctx.fillStyle = '#aaa';
    ctx.font = '9px monospace';
    ctx.fillText(
      'COMBAT  Round '
        + (this.combatRound + 1),
      10, 15
    );

    // Attack name bubble
    if (this.atkBubble) {
      const ab = this.atkBubble;
      const prog = ab.t / ab.dur;
      let alpha = 1;
      if (prog < 0.15) {
        alpha = prog / 0.15;
      } else if (prog > 0.8) {
        alpha = (1 - prog) / 0.2;
      }
      ctx.globalAlpha = Math.max(
        0, alpha
      );
      ctx.fillStyle = '#111';
      ctx.fillRect(
        CW / 2 - 80, 26, 160, 22
      );
      ctx.fillStyle = ab.clr;
      ctx.font = 'bold 12px monospace';
      const tw = ctx.measureText(
        ab.text
      ).width;
      ctx.fillText(
        ab.text,
        CW / 2 - tw / 2, 42
      );
      ctx.globalAlpha = 1;
    }

    // === HORIZONTAL LAYOUT ===
    // Party on left, enemies on right
    const rowY = 170;
    const unitW = 60;
    const unitH = 80;
    const gap = 8;

    // Position slot labels at top
    // Reversed: slot 4 at left, 1 at right
    const pStartLabel = 20;
    ctx.fillStyle = '#444';
    ctx.font = '7px monospace';
    ctx.fillText(
      'PARTY POSITIONS',
      pStartLabel, rowY - 28
    );
    for (let s = 0; s < 4; s++) {
      const lx = pStartLabel
        + s * (unitW + gap)
        + unitW / 2;
      ctx.fillStyle = '#333';
      ctx.fillText(
        'Pos ' + (4 - s),
        lx - 10, rowY - 18
      );
    }
    const eLabel = CW - 20
      - 4 * (unitW + gap);
    ctx.fillStyle = '#444';
    ctx.fillText(
      'ENEMY POSITIONS',
      eLabel, rowY - 28
    );

    // Store positions for click detection
    this.partyRects = [];
    this.enemyRects = [];

    // -- PARTY (left side, pos order) --
    // Pos 1 = rightmost (closest to foes)
    // Pos 4 = leftmost (farthest)
    const pStartX = 20;
    for (let i = 0;
      i < this.party.length; i++) {
      const p = this.party[i];
      // Reverse: pos 1 at right side
      const slot = 4 - p.pos;
      let ux = pStartX + slot
        * (unitW + gap);
      let uy = rowY;

      // Animation offset (attack)
      if (this.animState
        && this.animState.type === 'party'
        && this.animState.attackerIdx
          === i) {
        const a = this.animState;
        const prog = a.timer
          / (a.phase === 'lunge'
            ? a.lungeTime
            : a.phase === 'zoom'
              ? a.zoomTime
              : a.returnTime);
        // Move to target enemy position
        const eLen = this.enemies.length;
        const esX = CW - 20
          - eLen * (unitW + gap);
        const ti = a.targetIdx >= 0
          ? a.targetIdx : 0;
        const tgtX = esX
          + ti * (unitW + gap)
          - unitW / 2;
        if (a.phase === 'lunge') {
          ux += (tgtX - ux) * prog;
        } else if (a.phase === 'zoom') {
          ux = tgtX;
        } else if (
          a.phase === 'return'
        ) {
          const origX = pStartX
            + slot * (unitW + gap);
          ux = tgtX
            + (origX - tgtX) * prog;
        }
      }
      // Animation offset (support)
      if (this.animState
        && this.animState.type
          === 'support'
        && this.animState.attackerIdx
          === i) {
        const a = this.animState;
        const prog = a.timer
          / (a.phase === 'lunge'
            ? a.lungeTime
            : a.phase === 'zoom'
              ? a.zoomTime
              : a.returnTime);
        // Move next to target ally
        const tgt = this.party[
          a.targetIdx
        ];
        const tSlot = tgt
          ? tgt.pos - 1 : slot;
        const tgtX = pStartX
          + tSlot * (unitW + gap)
          + unitW + 4;
        if (a.phase === 'lunge') {
          ux += (tgtX - ux) * prog;
        } else if (a.phase === 'zoom') {
          ux = tgtX;
        } else if (
          a.phase === 'return'
        ) {
          const origX = pStartX
            + slot * (unitW + gap);
          ux = tgtX
            + (origX - tgtX) * prog;
        }
      }

      // Sprite body
      if (!p.alive) {
        ctx.globalAlpha = 0.4;
      }
      ctx.fillStyle = p.alive
        ? p.color : '#444';
      // Head
      ctx.beginPath();
      ctx.arc(
        ux + unitW / 2, uy + 10,
        8, 0, Math.PI * 2
      );
      ctx.fill();
      // Body
      ctx.fillRect(
        ux + unitW / 2 - 7,
        uy + 18, 14, 20
      );
      // Legs
      ctx.fillRect(
        ux + unitW / 2 - 6,
        uy + 38, 5, 12
      );
      ctx.fillRect(
        ux + unitW / 2 + 1,
        uy + 38, 5, 12
      );
      if (!p.alive) {
        ctx.globalAlpha = 1;
      }

      // Active turn glow
      if (this.activeUnit
        && this.activeUnit.type === 'party'
        && this.activeUnit.idx === i
        && this.state === GS_COMBAT) {
        ctx.strokeStyle = '#ffcc44';
        ctx.lineWidth = 2;
        ctx.strokeRect(
          ux - 2, uy - 4,
          unitW + 4, unitH + 8
        );
        ctx.lineWidth = 1;
      }

      // Ally hover highlight
      if (this.state === GS_TARGETING
        && this.hoverAlly === i) {
        ctx.strokeStyle = '#44ff44';
        ctx.lineWidth = 2;
        ctx.strokeRect(
          ux - 2, uy - 4,
          unitW + 4, unitH + 8
        );
        ctx.lineWidth = 1;
      }

      // Name
      ctx.fillStyle = p.alive
        ? '#ddd' : '#666';
      ctx.font = '7px monospace';
      const nw = ctx.measureText(
        p.name.substring(0, 8)
      ).width;
      ctx.fillText(
        p.name.substring(0, 8),
        ux + (unitW - nw) / 2,
        uy + 62
      );

      // HP bar / downed indicator
      const barW = unitW - 4;
      if (!p.alive) {
        // DOWNED overlay
        ctx.fillStyle = '#cc2222';
        ctx.font = 'bold 9px monospace';
        const dw = ctx.measureText(
          'DOWNED'
        ).width;
        ctx.fillText(
          'DOWNED',
          ux + (unitW - dw) / 2,
          uy + 70
        );
        // Red X over sprite
        ctx.strokeStyle = '#cc2222';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(
          ux + unitW / 2 - 12, uy + 2
        );
        ctx.lineTo(
          ux + unitW / 2 + 12, uy + 46
        );
        ctx.moveTo(
          ux + unitW / 2 + 12, uy + 2
        );
        ctx.lineTo(
          ux + unitW / 2 - 12, uy + 46
        );
        ctx.stroke();
        ctx.lineWidth = 1;
      } else {
        ctx.fillStyle = '#333';
        ctx.fillRect(
          ux + 2, uy + 66, barW, 5
        );
        const hpF = p.hp / p.maxHp;
        ctx.fillStyle = hpF > 0.5
          ? '#44aa44' : '#cc4444';
        ctx.fillRect(
          ux + 2, uy + 66,
          barW * hpF, 5
        );
      }

      // Stress bar (alive only)
      if (!p.alive) {
        // skip stress bar for downed
      } else {
      ctx.fillStyle = '#222';
      ctx.fillRect(
        ux + 2, uy + 72, barW, 3
      );
      const stF = Math.min(
        1, p.stress / 100
      );
      ctx.fillStyle = stF > 0.7
        ? '#cc4444' : '#ccaa44';
      ctx.fillRect(
        ux + 2, uy + 72,
        barW * stF, 3
      );
      } // end alive else block

      // Block
      if (p.block > 0) {
        ctx.fillStyle = '#4488cc';
        ctx.font = '6px monospace';
        ctx.fillText(
          'Blk:' + p.block,
          ux + 2, uy - 2
        );
      }

      // Position badge (prominent)
      const posX = ux + unitW / 2;
      ctx.fillStyle = '#2a2a3a';
      ctx.beginPath();
      ctx.arc(
        posX, uy - 12, 9,
        0, Math.PI * 2
      );
      ctx.fill();
      ctx.strokeStyle = '#666';
      ctx.lineWidth = 1;
      ctx.stroke();
      ctx.fillStyle = '#ffcc44';
      ctx.font = '9px monospace';
      ctx.fillText(
        String(p.pos),
        posX - 3, uy - 8
      );

      // Statuses
      let stx = ux;
      ctx.font = '5px monospace';
      if (p.statuses.bleed > 0) {
        ctx.fillStyle = '#cc3333';
        ctx.fillText('BLD', stx, uy + 88);
        stx += 18;
      }
      if (p.statuses.poison > 0) {
        ctx.fillStyle = '#44cc44';
        ctx.fillText('PSN', stx, uy + 88);
        stx += 18;
      }
      if (p.statuses.stun > 0) {
        ctx.fillStyle = '#ffcc44';
        ctx.fillText('STN', stx, uy + 88);
      }

      this.partyRects.push({
        x: pStartX
          + (4 - p.pos)
            * (unitW + gap),
        y: rowY, w: unitW, h: unitH,
        idx: i,
      });
    }

    // -- ENEMIES (right side) --
    const eStartX = CW - 20
      - this.enemies.length
        * (unitW + gap);
    for (let i = 0;
      i < this.enemies.length; i++) {
      const e = this.enemies[i];
      if (!e.alive) continue;
      let ux = eStartX
        + i * (unitW + gap);
      let uy = rowY;

      // Animation offset
      if (this.animState
        && this.animState.type === 'enemy'
        && this.animState.attackerIdx
          === i) {
        const a = this.animState;
        const prog = a.timer
          / (a.phase === 'lunge'
            ? a.lungeTime
            : a.phase === 'zoom'
              ? a.zoomTime
              : a.returnTime);
        // Move to target party pos
        const tp = this.party[
          a.targetIdx
        ];
        const tSlot = tp
          ? 4 - tp.pos : 3;
        const tgtX = pStartX
          + tSlot * (unitW + gap)
          + unitW + unitW / 2;
        if (a.phase === 'lunge') {
          ux += (tgtX - ux) * prog;
        } else if (a.phase === 'zoom') {
          ux = tgtX;
        } else if (
          a.phase === 'return'
        ) {
          const origX = eStartX
            + i * (unitW + gap);
          ux = tgtX
            + (origX - tgtX) * prog;
        }
      }

      // Sprite (from base64 or fallback)
      const spr = this.sprites[
        e.spriteKey
      ];
      if (spr && spr.complete) {
        ctx.imageSmoothingEnabled = false;
        ctx.drawImage(
          spr,
          ux + 6, uy, 48, 48
        );
        ctx.imageSmoothingEnabled = true;
      } else {
        ctx.fillStyle = e.color;
        ctx.fillRect(
          ux + 10, uy + 4, 40, 40
        );
      }

      // Name
      ctx.fillStyle = '#ddd';
      ctx.font = '7px monospace';
      const enw = ctx.measureText(
        e.name.substring(0, 9)
      ).width;
      ctx.fillText(
        e.name.substring(0, 9),
        ux + (unitW - enw) / 2,
        uy + 56
      );

      // HP bar
      const eBarW = unitW - 4;
      ctx.fillStyle = '#333';
      ctx.fillRect(
        ux + 2, uy + 60, eBarW, 5
      );
      const ehpF = e.hp / e.maxHp;
      ctx.fillStyle = '#cc3333';
      ctx.fillRect(
        ux + 2, uy + 60,
        eBarW * ehpF, 5
      );

      // Block
      if (e.block > 0) {
        ctx.fillStyle = '#4488cc';
        ctx.font = '6px monospace';
        ctx.fillText(
          'Blk:' + e.block,
          ux + 2, uy - 2
        );
      }

      // Position badge (prominent)
      const ePosX = ux + unitW / 2;
      ctx.fillStyle = '#2a1a1a';
      ctx.beginPath();
      ctx.arc(
        ePosX, uy - 12, 9,
        0, Math.PI * 2
      );
      ctx.fill();
      ctx.strokeStyle = '#664444';
      ctx.lineWidth = 1;
      ctx.stroke();
      ctx.fillStyle = '#ff6644';
      ctx.font = '9px monospace';
      ctx.fillText(
        String(e.pos),
        ePosX - 3, uy - 8
      );

      // Intent below
      let intent;
      if (e.bloodlust !== undefined
        && e.bloodlust >= 4
        && ENEMIES[e.type]
        && ENEMIES[e.type].banquet) {
        intent = ENEMIES[e.type].banquet;
      } else {
        intent = e.intents[
          e.intIdx % e.intents.length
        ];
      }
      this.renderIntent(
        ux + 4, uy + 74, intent, e
      );

      // Statuses
      let stx2 = ux;
      ctx.font = '5px monospace';
      if (e.statuses.bleed > 0) {
        ctx.fillStyle = '#cc3333';
        ctx.fillText(
          'BLD', stx2, uy + 82
        );
        stx2 += 18;
      }
      if (e.statuses.poison > 0) {
        ctx.fillStyle = '#44cc44';
        ctx.fillText(
          'PSN', stx2, uy + 82
        );
        stx2 += 18;
      }
      if (e.statuses.mark > 0) {
        ctx.fillStyle = '#ff44ff';
        ctx.fillText(
          'MRK', stx2, uy + 82
        );
      }

      // Bloodlust counter (Nosferatu)
      if (e.bloodlust !== undefined) {
        ctx.fillStyle = '#aa2244';
        ctx.font = '6px monospace';
        ctx.fillText(
          'Blood: '
            + e.bloodlust + '/4',
          ux, uy + 88
        );
      }

      // Target highlight
      if (this.state === GS_TARGETING
        && i === this.hoverEnemy) {
        ctx.strokeStyle = '#ff4444';
        ctx.lineWidth = 2;
        ctx.strokeRect(
          ux - 2, uy - 4,
          unitW + 4, unitH + 8
        );
        ctx.lineWidth = 1;
      }

      this.enemyRects.push({
        x: eStartX
          + i * (unitW + gap),
        y: rowY, w: unitW, h: unitH,
        idx: i,
      });
    }

    // Restore zoom transform
    if (zooming) {
      ctx.restore();
    }

    // Skill buttons (if party turn)
    if (this.state === GS_COMBAT
      && this.activeUnit
      && this.activeUnit.type
        === 'party') {
      this.renderSkillBar();
    }

    // Targeting prompt
    if (this.state === GS_TARGETING) {
      ctx.fillStyle = '#ffcc44';
      ctx.font = '10px monospace';
      let msg = 'Click an enemy'
        + ' (ESC cancel)';
      if (this.swapMode) {
        msg = 'Click an ally to swap'
          + ' (ESC cancel)';
      } else if (this.selectedSkill >= 0
        && this.activeUnit) {
        const sk = this.party[
          this.activeUnit.idx
        ].skills[this.selectedSkill];
        if (sk
          && sk.targetType === 'ally') {
          msg = 'Click an ally'
            + ' (ESC cancel)';
        }
      }
      ctx.fillText(
        msg, CW / 2 - 120, CH - 12
      );
    }
  }

  renderIntent(x, y, intent, e) {
    const ctx = this.ctx;
    ctx.font = '7px monospace';
    if (!intent) return;
    const nm = intent.name || '';
    const clrs = {
      atk: '#ff4444', blk: '#4488cc',
      buff: '#ffaa44', heal: '#44cc44',
      special: '#cc44cc',
      debuf: '#cc44cc',
      summon: '#cc8844',
    };
    ctx.fillStyle = clrs[intent.t]
      || '#aaa';
    switch (intent.t) {
      case 'atk': {
        let d = intent.v + (e.str || 0);
        const h = intent.hits
          ? 'x' + intent.hits : '';
        ctx.fillText(
          (nm || 'ATK') + ' '
            + d + h, x, y
        );
        break;
      }
      case 'blk':
        ctx.fillText(
          (nm || 'SHIELD') + ' '
            + intent.v, x, y
        );
        break;
      case 'buff':
        ctx.fillText(
          (nm || 'BUFF') + ' +'
            + intent.v, x, y
        );
        break;
      case 'heal':
        ctx.fillText(
          (nm || 'HEAL') + ' '
            + intent.v, x, y
        );
        break;
      case 'debuf':
        ctx.fillText(
          nm || 'DEBUFF', x, y
        );
        break;
      case 'summon':
        ctx.fillText(
          nm || 'SUMMON', x, y
        );
        break;
      case 'special':
        ctx.fillText(
          nm || 'SPECIAL', x, y
        );
        break;
      default: break;
    }
  }

  renderSkillBar() {
    const ctx = this.ctx;
    const p = this.party[
      this.activeUnit.idx
    ];
    if (!p) return;
    const barY = CH - 60;
    ctx.fillStyle = '#1a1a22';
    ctx.fillRect(0, barY, CW, 60);

    ctx.fillStyle = '#ffcc44';
    ctx.font = '9px monospace';
    ctx.fillText(
      p.name + '\'s Turn  [Pos '
        + p.pos + ']',
      10, barY + 14
    );

    // Skill buttons
    const bw = 130;
    const bh = 34;
    const startX = 10;
    this.skillRects = [];
    for (let i = 0;
      i < p.skills.length; i++) {
      const sk = p.skills[i];
      const bx = startX + i * (bw + 6);
      const by = barY + 18;
      const canUse = p.pos >= sk.posMin
        && p.pos <= sk.posMax;
      const hov = this.mx >= bx
        && this.mx <= bx + bw
        && this.my >= by
        && this.my <= by + bh;

      ctx.fillStyle = !canUse
        ? '#111' : hov
          ? '#2a2a3a' : '#1a1a2a';
      ctx.fillRect(bx, by, bw, bh);
      ctx.strokeStyle = !canUse
        ? '#333' : hov
          ? '#ffcc44' : '#555';
      ctx.strokeRect(bx, by, bw, bh);
      ctx.fillStyle = !canUse
        ? '#444' : '#ddd';
      ctx.font = '8px monospace';
      ctx.fillText(
        sk.name, bx + 4, by + 11
      );
      // Position requirement
      ctx.fillStyle = canUse
        ? '#558855' : '#884444';
      ctx.font = '6px monospace';
      const posStr = 'Pos '
        + sk.posMin + '-' + sk.posMax;
      ctx.fillText(
        posStr, bx + 80, by + 11
      );
      // Description
      ctx.fillStyle = '#888';
      ctx.fillText(
        sk.desc.substring(0, 22),
        bx + 4, by + 22
      );
      // If disabled, show why
      if (!canUse) {
        ctx.fillStyle = '#663333';
        ctx.fillText(
          'Need pos '
            + sk.posMin + '-'
            + sk.posMax,
          bx + 4, by + 30
        );
      }

      if (canUse) {
        this.skillRects.push({
          x: bx, y: by, w: bw, h: bh,
          idx: i,
        });
      }
    }

    // Swap button
    const swX = startX
      + p.skills.length * (bw + 6);
    const swY = barY + 22;
    ctx.fillStyle = '#1a2a1a';
    ctx.fillRect(swX, swY, 60, bh);
    ctx.strokeStyle = '#335533';
    ctx.strokeRect(swX, swY, 60, bh);
    ctx.fillStyle = '#44aa44';
    ctx.font = '8px monospace';
    ctx.fillText(
      'SWAP', swX + 8, swY + 18
    );
    this.swapRect = {
      x: swX, y: swY, w: 60, h: bh,
    };

    // Skip turn button
    const skX = swX + 68;
    const skY = barY + 22;
    ctx.fillStyle = '#2a1a1a';
    ctx.fillRect(skX, skY, 60, bh);
    ctx.strokeStyle = '#553333';
    ctx.strokeRect(skX, skY, 60, bh);
    ctx.fillStyle = '#cc6644';
    ctx.font = '8px monospace';
    ctx.fillText(
      'SKIP', skX + 10, skY + 18
    );
    this.skipRect = {
      x: skX, y: skY, w: 60, h: bh,
    };
  }

  renderCorridor() {
    const ctx = this.ctx;
    const prog = Math.min(
      1,
      this.corridorTimer
        / this.corridorDur
    );
    const t = performance.now();

    // Background
    ctx.fillStyle = '#0a0a12';
    ctx.fillRect(0, 0, CW, CH);

    // Steel ceiling
    ctx.fillStyle = '#1a1a25';
    ctx.fillRect(0, 0, CW, 100);
    // Ceiling pipes
    for (let px = 0; px < CW; px += 80) {
      ctx.fillStyle = '#2a2a35';
      ctx.fillRect(px, 60, 60, 6);
      ctx.fillStyle = '#333';
      ctx.fillRect(px + 10, 66, 4, 34);
    }

    // Steel floor
    ctx.fillStyle = '#222230';
    ctx.fillRect(0, CH - 90, CW, 90);
    // Floor tiles
    ctx.strokeStyle = '#2a2a38';
    for (let fx = -40 + (prog * -80);
      fx < CW + 40; fx += 80) {
      ctx.beginPath();
      ctx.moveTo(fx, CH - 90);
      ctx.lineTo(fx, CH);
      ctx.stroke();
    }

    // Flickering overhead lights
    for (let lx = 80; lx < CW; lx += 160) {
      const flk = Math.sin(
        t * 0.008 + lx * 0.1
      );
      const alpha = 0.3 + flk * 0.2;
      ctx.fillStyle = 'rgba(140,160,180,'
        + alpha.toFixed(2) + ')';
      ctx.fillRect(lx - 20, 95, 40, 4);
      // Light cone
      ctx.fillStyle = 'rgba(100,120,140,'
        + (alpha * 0.15).toFixed(3) + ')';
      ctx.beginPath();
      ctx.moveTo(lx - 20, 99);
      ctx.lineTo(lx - 60, CH - 90);
      ctx.lineTo(lx + 60, CH - 90);
      ctx.lineTo(lx + 20, 99);
      ctx.closePath();
      ctx.fill();
    }

    // L-Corp wall logo (scrolling)
    ctx.fillStyle = '#1a1a22';
    ctx.font = '11px monospace';
    const logoX = CW / 2 - 100
      - prog * 60;
    ctx.globalAlpha = 0.3;
    ctx.fillText(
      'LOBOTOMY CORPORATION',
      logoX, 150
    );
    ctx.globalAlpha = 1;

    // Walking party characters
    const baseY = CH - 130;
    for (let i = 0;
      i < this.party.length; i++) {
      const p = this.party[i];
      if (!p.alive) continue;
      // Move left to right across screen
      const cx = 80 + prog * (CW - 200)
        + i * 40;
      // Bounce: each char has offset
      const bounce = Math.abs(Math.sin(
        t * 0.008 + i * 1.5
      )) * 8;
      const cy = baseY - bounce;

      // Body (simple silhouette)
      ctx.fillStyle = p.color;
      // Head
      ctx.beginPath();
      ctx.arc(
        cx, cy - 20, 6, 0, Math.PI * 2
      );
      ctx.fill();
      // Torso
      ctx.fillRect(
        cx - 5, cy - 14, 10, 16
      );
      // Legs (alternate based on bounce)
      const legPhase = Math.sin(
        t * 0.008 + i * 1.5
      );
      ctx.fillRect(
        cx - 4 + legPhase * 3,
        cy + 2, 3, 10
      );
      ctx.fillRect(
        cx + 1 - legPhase * 3,
        cy + 2, 3, 10
      );
    }

    // "Entering room" text
    this.cText(
      'Entering room...',
      '#888', 10, 60
    );
  }

  renderLoot() {
    const ctx = this.ctx;
    ctx.fillStyle = 'rgba(0,0,0,0.8)';
    ctx.fillRect(0, 0, CW, CH);
    this.cText(
      this.lootMsg || 'Room cleared!',
      '#44ff44', 12, -20
    );
    this.cText(
      'Press ENTER to continue',
      '#aaa', 9, 20
    );
  }

  renderCurio() {
    const ctx = this.ctx;
    ctx.fillStyle = 'rgba(0,0,0,0.85)';
    ctx.fillRect(0, 0, CW, CH);
    const c = CURIOS[this.curioKey];
    if (!c) return;

    this.cText(
      c.title, '#4488cc', 16, -80
    );
    this.cText(c.desc, '#ccc', 10, -50);

    this.curioRects = [];
    const opts = [c.opt1, c.opt2];
    for (let i = 0; i < 2; i++) {
      const bx = CW / 2 - 140;
      const by = CH / 2 - 10 + i * 40;
      const hov = this.mx >= bx
        && this.mx <= bx + 280
        && this.my >= by
        && this.my <= by + 30;
      ctx.fillStyle = hov
        ? '#1a2a3a' : '#121a22';
      ctx.fillRect(bx, by, 280, 30);
      ctx.strokeStyle = hov
        ? '#4488cc' : '#334';
      ctx.strokeRect(bx, by, 280, 30);
      ctx.fillStyle = hov
        ? '#4488cc' : '#888';
      ctx.font = '10px monospace';
      ctx.fillText(
        opts[i], bx + 10, by + 20
      );
      this.curioRects.push({
        x: bx, y: by, w: 280, h: 30,
      });
    }
  }

  renderVictory() {
    const ctx = this.ctx;
    ctx.fillStyle = 'rgba(0,0,0,0.7)';
    ctx.fillRect(0, 0, CW, CH);
    this.cText(
      'FACILITY CLEARED!',
      '#ffcc44', 20, -40
    );
    this.cText(
      'Score: ' + this.score,
      '#fff', 14, -10
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
      'PARTY WIPED', '#ff4444', 20, -40
    );
    this.cText(
      'Score: ' + this.score,
      '#fff', 12, -10
    );
    this.cText(
      'Press R to retry',
      '#aaa', 9, 24
    );
  }

  renderNameEntry() {
    const ctx = this.ctx;
    ctx.fillStyle = 'rgba(0,0,0,0.85)';
    ctx.fillRect(0, 0, CW, CH);
    this.cText(
      'FACILITY CLEARED!',
      '#ffcc44', 20, -100
    );
    this.cText(
      'Score: ' + this.score,
      '#fff', 14, -70
    );
    this.cText(
      'ENTER YOUR NAME',
      '#aaa', 12, -30
    );
    const boxW = 28;
    const boxH = 32;
    const gap = 6;
    const totalW = 6 * boxW + 5 * gap;
    const sx = (CW - totalW) / 2;
    const sy = CH / 2 - 4;
    for (let i = 0; i < 6; i++) {
      const bx = sx + i * (boxW + gap);
      ctx.fillStyle = '#1a1a2a';
      ctx.fillRect(bx, sy, boxW, boxH);
      ctx.strokeStyle = i
          === this.entryName.length
        ? '#ffcc44' : '#555';
      ctx.lineWidth = i
          === this.entryName.length
        ? 2 : 1;
      ctx.strokeRect(bx, sy, boxW, boxH);
      ctx.lineWidth = 1;
      if (i < this.entryName.length) {
        ctx.fillStyle = '#fff';
        ctx.font = '18px monospace';
        const ch = this.entryName[i];
        const cw2 = ctx.measureText(
          ch
        ).width;
        ctx.fillText(
          ch,
          bx + (boxW - cw2) / 2,
          sy + 22
        );
      }
    }
    if (!this.nameDone
      && this.entryName.length < 6) {
      const ci = this.entryName.length;
      const cx = sx + ci * (boxW + gap);
      const blink = Math.sin(
        performance.now() * 0.006
      );
      if (blink > 0) {
        ctx.fillStyle = '#ffcc44';
        ctx.fillRect(
          cx + 8, sy + boxH - 4, 12, 2
        );
      }
    }
    if (this.nameDone) {
      this.cText(
        'Press R to play again',
        '#aaa', 9, 60
      );
    } else {
      this.cText(
        'Type A-Z then ENTER',
        '#888', 9, 60
      );
    }
  }

  renderFloats() {
    const ctx = this.ctx;
    for (let i = 0;
      i < this.floats.length; i++) {
      const f = this.floats[i];
      const prog = f.t / f.dur;
      ctx.globalAlpha = 1 - prog;
      ctx.fillStyle = f.clr;
      ctx.font = '12px monospace';
      ctx.fillText(
        f.text, f.x,
        f.y - prog * 20
      );
      ctx.globalAlpha = 1;
    }
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

  // INPUT

  handleClick(mx, my) {
    this.mx = mx;
    this.my = my;

    if (this.state === GS_TITLE) return;

    // Character selection
    if (this.state === GS_CHARSEL) {
      // Check char slots
      if (this.charRects) {
        for (let i = 0;
          i < this.charRects.length;
          i++) {
          const r = this.charRects[i];
          if (mx >= r.x
            && mx <= r.x + r.w
            && my >= r.y
            && my <= r.y + r.h) {
            this.cycleChar(r.idx);
            return;
          }
        }
      }
      // Start button
      const sbx = CW / 2 - 60;
      const sby = CH - 36;
      if (mx >= sbx && mx <= sbx + 120
        && my >= sby && my <= sby + 28) {
        this.startRun();
      }
      return;
    }

    // Map click
    if (this.state === GS_MAP) {
      const gx = 60;
      const gy = 50;
      const cellW = 80;
      const cellH = 50;
      for (let i = 0;
        i < this.rooms.length; i++) {
        const r = this.rooms[i];
        const nx = gx
          + (r.x - 1) * cellW
          + cellW / 2;
        const ny = gy
          + (r.y - 1) * cellH
          + cellH / 2;
        const dx = mx - nx;
        const dy = my - ny;
        const explored
          = this.exploredRooms
            .indexOf(i) >= 0;
        if (dx * dx + dy * dy < 256
          && this.isReachable(i)
          && !explored) {
          this.corridorTimer = 0;
          this.corridorTarget = i;
          this.state = GS_CORRIDOR;
          return;
        }
      }
      return;
    }

    // Combat: skill selection
    if (this.state === GS_COMBAT
      && this.skillRects) {
      for (let i = 0;
        i < this.skillRects.length;
        i++) {
        const r = this.skillRects[i];
        if (mx >= r.x
          && mx <= r.x + r.w
          && my >= r.y
          && my <= r.y + r.h) {
          this.selectSkill(r.idx);
          return;
        }
      }
      // Swap button
      if (this.swapRect) {
        const sr = this.swapRect;
        if (mx >= sr.x
          && mx <= sr.x + sr.w
          && my >= sr.y
          && my <= sr.y + sr.h) {
          this.swapMode = true;
          this.state = GS_TARGETING;
          return;
        }
      }
      // Skip turn button
      if (this.skipRect) {
        const kr = this.skipRect;
        if (mx >= kr.x
          && mx <= kr.x + kr.w
          && my >= kr.y
          && my <= kr.y + kr.h) {
          this.nextTurn();
          return;
        }
      }
    }

    // Targeting click
    if (this.state === GS_TARGETING) {
      // Determine target mode
      const isSwap = this.swapMode;
      let isAlly = false;
      if (!isSwap
        && this.selectedSkill >= 0
        && this.activeUnit) {
        const sk = this.party[
          this.activeUnit.idx
        ].skills[this.selectedSkill];
        isAlly = sk
          && sk.targetType === 'ally';
      }

      if ((isSwap || isAlly)
        && this.partyRects) {
        // Target party members
        for (let i = 0;
          i < this.partyRects.length;
          i++) {
          const r = this.partyRects[i];
          if (mx >= r.x
            && mx <= r.x + r.w
            && my >= r.y
            && my <= r.y + r.h) {
            if (isSwap) {
              this.swapMode = false;
              this.doSwap(r.idx);
            } else {
              this.selectTarget(r.idx);
            }
            return;
          }
        }
        return;
      }
      // Target enemies
      if (this.enemyRects) {
        for (let i = 0;
          i < this.enemyRects.length;
          i++) {
          const r = this.enemyRects[i];
          if (mx >= r.x
            && mx <= r.x + r.w
            && my >= r.y
            && my <= r.y + r.h) {
            this.selectTarget(r.idx);
            return;
          }
        }
      }
    }

    // Curio click
    if (this.state === GS_CURIO
      && this.curioRects) {
      for (let i = 0;
        i < this.curioRects.length;
        i++) {
        const r = this.curioRects[i];
        if (mx >= r.x
          && mx <= r.x + r.w
          && my >= r.y
          && my <= r.y + r.h) {
          this.resolveCurio(i);
          return;
        }
      }
    }
  }

  handleHover(mx, my) {
    this.mx = mx;
    this.my = my;
    this.hoverEnemy = -1;
    this.hoverAlly = -1;

    if (this.state !== GS_TARGETING) {
      return;
    }
    // Determine if ally targeting
    const isSwap = this.swapMode;
    let isAlly = false;
    if (!isSwap
      && this.selectedSkill >= 0
      && this.activeUnit) {
      const sk = this.party[
        this.activeUnit.idx
      ].skills[this.selectedSkill];
      isAlly = sk
        && sk.targetType === 'ally';
    }

    if ((isSwap || isAlly)
      && this.partyRects) {
      for (let i = 0;
        i < this.partyRects.length;
        i++) {
        const r = this.partyRects[i];
        if (mx >= r.x
          && mx <= r.x + r.w
          && my >= r.y
          && my <= r.y + r.h) {
          this.hoverAlly = r.idx;
          break;
        }
      }
    } else if (this.enemyRects) {
      for (let i = 0;
        i < this.enemyRects.length;
        i++) {
        const r = this.enemyRects[i];
        if (mx >= r.x
          && mx <= r.x + r.w
          && my >= r.y
          && my <= r.y + r.h) {
          this.hoverEnemy = r.idx;
          break;
        }
      }
    }
  }

  handleKeyDown(code) {
    if (this.state === GS_TITLE
      && code === KEY_ENTER) {
      this.state = GS_CHARSEL;
      return;
    }

    // Name entry
    if (this.state === GS_NAMEENTRY) {
      if (this.nameDone) {
        if (code === KEY_R) {
          this.state = GS_TITLE;
        }
        return;
      }
      if (code === KEY_ENTER
        && this.entryName.length > 0) {
        this.nameDone = true;
        this.act('submit_score', {
          score: this.score,
          name: this.entryName
            || 'ANON',
        });
        return;
      }
      if (code === 8
        && this.entryName.length > 0) {
        this.entryName
          = this.entryName.slice(0, -1);
        return;
      }
      if (code >= 65 && code <= 90
        && this.entryName.length < 6) {
        this.entryName += String
          .fromCharCode(code);
        return;
      }
      return;
    }

    if ((this.state === GS_VICTORY
      || this.state === GS_DEFEAT)
      && code === KEY_R) {
      this.state = GS_TITLE;
    }

    if (this.state === GS_LOOT
      && code === KEY_ENTER) {
      this.state = GS_MAP;
    }

    if (this.state === GS_TARGETING
      && code === KEY_ESC) {
      this.swapMode = false;
      this.selectedSkill = -1;
      this.state = GS_COMBAT;
    }

    // Number keys for skills
    if (this.state === GS_COMBAT
      && this.activeUnit
      && this.activeUnit.type
        === 'party') {
      if (code >= KEY_1
        && code <= KEY_4) {
        const si = code - KEY_1;
        this.selectSkill(si);
      }
    }
  }
}

// TGUI Component

const ACQUIRED_KEYS = [
  KEY_R, KEY_ESC, KEY_D,
  KEY_1, KEY_2, KEY_3, KEY_4,
];

class ArcadeDungeonComp extends Component {
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

    this.engine = new DungeonEngine(
      canvas, this.props.act
    );
    this.engine.leaderboard
      = this.props.data.leaderboard || [];

    const sd = this.props.data;
    if (sd) {
      this.engine.loadData(sd);
    }

    this.engine.start();
    canvas.focus();
  }

  componentDidUpdate(prevProps) {
    if (!this.engine) return;
    const sd = this.props.data;
    if (sd && sd.dungeon
      && sd !== prevProps.data
      && sd.dungeon
        !== prevProps.data.dungeon) {
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
        i < ACQUIRED_KEYS.length;
        i++) {
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
          this.engine.handleHover(
            e.clientX - r.left,
            e.clientY - r.top
          );
        }}
        onClick={e => {
          if (!this.engine) return;
          const r = e.target
            .getBoundingClientRect();
          this.engine.handleClick(
            e.clientX - r.left,
            e.clientY - r.top
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

export const ArcadeDungeon = (
  props, context
) => {
  const { act, data } = useBackend(
    context
  );
  return (
    <Window
      width={CW + 30}
      height={CH + 50}>
      <Window.Content>
        <ArcadeDungeonComp
          act={act}
          data={data}
        />
      </Window.Content>
    </Window>
  );
};
