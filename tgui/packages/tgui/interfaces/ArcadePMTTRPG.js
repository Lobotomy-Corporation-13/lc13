/**
 * @file
 * @copyright 2024
 * @license MIT
 *
 * The City - A Fixer's Chronicle
 * PM TTRPG Arcade - Turn-based tactical RPG
 */

import { Component, createRef } from 'inferno';
import { useBackend } from '../backend';
import { Window } from '../layouts';
import {
  acquireHotKey,
  releaseHotKey,
} from '../hotkeys';

// ========== CANVAS CONSTANTS ==========
const CW = 800;
const CH = 600;

// ========== KEY CODES ==========
const KEY_ENTER = 13;
const KEY_ESC = 27;
const KEY_TAB = 9;
const KEY_BACKSPACE = 8;
const KEY_SPACE = 32;
const KEY_UP = 38;
const KEY_DOWN = 40;
const KEY_LEFT = 37;
const KEY_RIGHT = 39;
const KEY_W = 87;
const KEY_A = 65;
const KEY_S = 83;
const KEY_D = 68;
const KEY_R = 82;
const KEY_E = 69;
const KEY_1 = 49;

// ========== GAME STATES ==========
const GS_TITLE = 0;
const GS_CREATE_STATS = 1;
const GS_CREATE_WEAPON = 2;
const GS_CREATE_OUTFIT = 3;
const GS_CREATE_AUGMENT = 4;
const GS_CREATE_SKILLS = 5;
const GS_CREATE_REVIEW = 6;
const GS_CREATED = 7;
const GS_COMBAT = 8;
const GS_COMBAT_VICTORY = 9;
const GS_COMBAT_DEFEAT = 10;

// Combat phases
const CP_IDLE = 'idle';
const CP_MOVING = 'moving';
const CP_ATTACKING = 'attacking';
const CP_PLAYER_REACT = 'player_react';
const CP_PLAYER_SKILL = 'player_skill';
const CP_ENEMY_THINKING = 'enemy_thinking';
const CP_ANIM = 'anim';

// Tile size in pixels
const TILE = 32;
// Grid offset in combat screen
const GRID_X = 20;
const GRID_Y = 50;

// ========== COLOR PALETTE ==========
const COL = {
  bg: '#0a0a14',
  panelBg: '#14142a',
  panelBorder: '#2a2a4a',
  text: '#e0e0e0',
  textDim: '#8888aa',
  textGold: '#ffcc44',
  textRed: '#ff4444',
  textGreen: '#44ff88',
  textBlue: '#44aaff',
  btnNorm: '#2a2a5a',
  btnHover: '#3a3a7a',
  btnActive: '#4a4aaa',
  btnDisabled: '#1a1a2a',
  hpBar: '#cc3333',
  stBar: '#cc9933',
  spBar: '#3366cc',
  lightOrb: '#ffee88',
  slash: '#ff6644',
  pierce: '#44ccff',
  blunt: '#ffaa22',
  tabActive: '#3344aa',
  tabInactive: '#1a1a3a',
  epFill: '#44aa66',
  epEmpty: '#1a2a1a',
  epNeg: '#aa4444',
  // Skill type tints
  skillAtkBg: '#5a2020',
  skillAtkBorder: '#ff4444',
  skillAtkText: '#ffd0d0',
  skillBlkBg: '#20355a',
  skillBlkBorder: '#4488ff',
  skillBlkText: '#d0dcff',
  skillEvdBg: '#5a4a20',
  skillEvdBorder: '#ffcc44',
  skillEvdText: '#ffecc0',
};

// ========== STATUS METADATA ==========
const STATUS_DISPLAY = {
  burn: { short: 'Bn', color: '#ff6644',
    name: 'Burn' },
  frostbite: { short: 'Fr',
    color: '#88ccff', name: 'Frostbite' },
  bleed: { short: 'Bl', color: '#cc2222',
    name: 'Bleed' },
  rupture: { short: 'Ru', color: '#ff4488',
    name: 'Rupture' },
  tremor: { short: 'Tr', color: '#aa66ff',
    name: 'Tremor' },
  sinking: { short: 'Si', color: '#4466cc',
    name: 'Sinking' },
  poise: { short: 'Po', color: '#ffcc44',
    name: 'Poise' },
  critical: { short: 'Cr', color: '#ffee88',
    name: 'Critical' },
  ruin: { short: 'Rn', color: '#884488',
    name: 'Ruin' },
  devastation: { short: 'Dv',
    color: '#aa44aa', name: 'Devastation' },
  strength: { short: 'St', color: '#ff8844',
    name: 'Strength' },
  feeble: { short: 'Fe', color: '#886644',
    name: 'Feeble' },
  endurance: { short: 'En', color: '#44ff88',
    name: 'Endurance' },
  disarm: { short: 'Di', color: '#448844',
    name: 'Disarm' },
  protection: { short: 'Pr',
    color: '#44ccff', name: 'Protection' },
  stagger_protection: { short: 'SP',
    color: '#4488cc', name: 'Stagger Prot' },
  fragile: { short: 'Fg', color: '#ffaaaa',
    name: 'Fragile' },
  stagger_fragile: { short: 'SF',
    color: '#cc8888', name: 'Stagger Frag' },
  haste: { short: 'Ha', color: '#88ff44',
    name: 'Haste' },
  bind: { short: 'Bi', color: '#886633',
    name: 'Bind' },
  paralysis: { short: 'Pa',
    color: '#aaaa44', name: 'Paralysis' },
};

function initStatusBlock() {
  return {
    burn: 0, frostbite: 0, bleed: 0,
    rupture: 0, tremor: 0, sinking: 0,
    poise: 0, critical: 0,
    ruin: 0, devastation: 0,
    strength: 0, feeble: 0,
    endurance: 0, disarm: 0,
    protection: 0, stagger_protection: 0,
    fragile: 0, stagger_fragile: 0,
    haste: 0, bind: 0,
    paralysis: 0, smoke: 0, charge: 0,
  };
}

// Skill type -> panel color lookup
function skillColors(type) {
  if (type === 'attack') return {
    bg: COL.skillAtkBg,
    border: COL.skillAtkBorder,
    text: COL.skillAtkText,
  };
  if (type === 'block') return {
    bg: COL.skillBlkBg,
    border: COL.skillBlkBorder,
    text: COL.skillBlkText,
  };
  if (type === 'evade') return {
    bg: COL.skillEvdBg,
    border: COL.skillEvdBorder,
    text: COL.skillEvdText,
  };
  return {
    bg: COL.panelBg,
    border: COL.panelBorder,
    text: COL.text,
  };
}

// ========== CREATE STEP NAMES ==========
const CREATE_STEPS = [
  'Stats', 'Weapon', 'Outfit',
  'Augment', 'Skills', 'Review',
];

// ========== STAT DEFINITIONS ==========
const STAT_DEFS = [
  {
    key: 'fortitude', name: 'Fortitude',
    short: 'FOR', color: '#ff6644',
    desc: '+8 HP per point',
  },
  {
    key: 'prudence', name: 'Prudence',
    short: 'PRU', color: '#aa44ff',
    desc: '+3 SP per point',
  },
  {
    key: 'justice', name: 'Justice',
    short: 'JUS', color: '#44ff88',
    desc: '+Speed, +Dash, +Status reduce',
  },
  {
    key: 'charm', name: 'Charm',
    short: 'CHA', color: '#ff44aa',
    desc: '+4 ST per point',
  },
  {
    key: 'insight', name: 'Insight',
    short: 'INS', color: '#44aaff',
    desc: '+Evade dice power',
  },
  {
    key: 'temperance', name: 'Temperance',
    short: 'TEM', color: '#ffcc44',
    desc: '+Block dice power',
  },
];

// ========== DAMAGE TYPE DEFS ==========
const DMG_TYPES = [
  { key: 'slash', name: 'Slash', color: COL.slash },
  { key: 'pierce', name: 'Pierce', color: COL.pierce },
  { key: 'blunt', name: 'Blunt', color: COL.blunt },
];

// ========== WEAPON FORM DEFS ==========
const MELEE_FORMS = [
  {
    key: 'small', name: 'Small',
    desc: '+1 Counter Reaction (stackable)',
  },
  {
    key: 'medium', name: 'Medium',
    desc: '+2 Dice Max',
  },
  {
    key: 'long', name: 'Long',
    desc: '2 SQR melee range. Push 1 SQR on CW.',
  },
  {
    key: 'sturdy', name: 'Sturdy',
    desc: '+1 Block Reaction (stackable)',
  },
  {
    key: 'hybrid', name: 'Hybrid',
    desc: 'Choose Melee or Ranged per attack.',
  },
];

const RANGED_FORMS = [
  {
    key: 'low_caliber', name: 'Low Caliber',
    desc: 'No movement cost on ranged attack.',
  },
  {
    key: 'high_caliber', name: 'High Caliber',
    desc: '+2 Dice Max',
  },
  {
    key: 'reactive', name: 'Reactive',
    desc: 'Counter for attacked allies in range.',
  },
  {
    key: 'hybrid', name: 'Hybrid',
    desc: 'Choose Melee or Ranged per attack.',
  },
];

// ========== WEAPON HAND DEFS ==========
const MELEE_HANDS = [
  {
    key: 'off_1h', name: 'Offensive 1H',
    desc: '+1 Power. +1 Reaction if not dual.',
    epBonus: 0,
  },
  {
    key: 'off_2h', name: 'Offensive 2H',
    desc: '+2 EP, +2 Power.',
    epBonus: 2,
  },
  {
    key: 'def_1h', name: 'Defensive 1H',
    desc: 'Convert attack to block after seeing'
      + ' result. +1 React if not dual.',
    epBonus: 0,
  },
  {
    key: 'def_2h', name: 'Defensive 2H',
    desc: '+2 EP. Free attack after Protect'
      + ' clash.',
    epBonus: 2,
  },
];

const RANGED_HANDS = [
  {
    key: 'off_1h', name: 'Offensive 1H',
    desc: '+1 Power. +1 Reaction if not dual.',
    epBonus: 0,
  },
  {
    key: 'off_2h', name: 'Offensive 2H',
    desc: '+2 EP, +2 Power.',
    epBonus: 2,
  },
];

// ========== OUTFIT PROPERTY DEFS ==========
const OUTFIT_PROPS = [
  {
    key: 'armored', name: 'Armored',
    desc: '+1 Block Power. On Block Win:'
      + ' deal half roll OR difference as'
      + ' ST DMG (whichever greater).',
    epBonus: 0,
  },
  {
    key: 'swift', name: 'Swift',
    desc: '+1 Evade Power. Recycled Evade'
      + ' penalty only -1 instead of -2.',
    epBonus: 0,
  },
  {
    key: 'balanced', name: 'Balanced',
    desc: '+2 EP, +1 Maximum Light.',
    epBonus: 2,
  },
];

// ========== RESISTANCE LEVELS ==========
const RESIST_LEVELS = [
  { key: 'fatal', name: 'Fatal', mult: 2.0,
    color: '#ff2222' },
  { key: 'weak', name: 'Weak', mult: 1.5,
    color: '#ff8844' },
  { key: 'normal', name: 'Normal', mult: 1.0,
    color: '#aaaaaa' },
  { key: 'endured', name: 'Endured', mult: 0.5,
    color: '#44aa44' },
  { key: 'ineffective', name: 'Ineff.', mult: 0.25,
    color: '#2288ff' },
  { key: 'immune', name: 'Immune', mult: 0.0,
    color: '#ffffff' },
];

// ========== SKILL TYPE DEFS ==========
const SKILL_TYPES = [
  {
    key: 'attack', name: 'Attack',
    desc: 'Enhances Attack actions and Counters.',
  },
  {
    key: 'block', name: 'Block',
    desc: 'Enhances Block reactions.',
  },
  {
    key: 'evade', name: 'Evade',
    desc: 'Enhances Evade reactions.',
  },
];

// ========== EFFECT DATA TABLES ==========
// Each effect: { name, desc, cost (per N),
//   maxAmt, procType, procOptions, canNeg,
//   restrictions }

// procType values:
//   always - always active, no selection
//   on_clash - during clash, no CW/CL
//   clash_result - needs CW or CL selection
//   combat_start - on combat start
//   round_start - at round start
//   clash_win_type - CW with Atk/Def selection
//   condition_type - conditional with Atk/Def sel
// Effect flags:
//   canNeg - can be taken as negative effect
//   needsResultSel - player picks CW or CL
//   needsTypeSel - player picks Atk or Def
//   flat - cost is flat, amount always 1

const WEAPON_EFFECTS = {
  dice_power_up: {
    name: 'Dice Power Up', cost: 8, maxAmt: 5,
    desc: '+N to weapon dice power.',
    procType: 'always', canNeg: true,
  },
  dice_max_up: {
    name: 'Dice Max Up', cost: 4, maxAmt: 5,
    desc: '+N to weapon dice max (faces).',
    procType: 'always', canNeg: true,
  },
  inflict_burn: {
    name: 'Inflict Burn', cost: 2, maxAmt: 5,
    desc: 'Apply N Burn to target.',
    procType: 'clash_result', canNeg: true,
    needsResultSel: true,
  },
  inflict_bleed: {
    name: 'Inflict Bleed', cost: 2, maxAmt: 5,
    desc: 'Apply N Bleed to target.',
    procType: 'clash_result', canNeg: true,
    needsResultSel: true,
  },
  inflict_rupture: {
    name: 'Inflict Rupture', cost: 1, maxAmt: 5,
    desc: 'Apply N Rupture next round (max 6).',
    procType: 'clash_result', canNeg: true,
    needsResultSel: true,
  },
  gain_poise: {
    name: 'Gain Poise', cost: 2, maxAmt: 5,
    desc: 'Apply N Poise to self. Neg: to target.',
    procType: 'clash_result', canNeg: true,
    needsResultSel: true,
  },
  inflict_ruin: {
    name: 'Inflict Ruin', cost: 2, maxAmt: 5,
    desc: 'Apply N Ruin to target. Neg: to self.',
    procType: 'clash_result', canNeg: true,
    needsResultSel: true,
  },
  enemy_power_down: {
    name: 'Enemy Power Down', cost: 8, maxAmt: 5,
    desc: '-N to enemy dice power in clash.',
    procType: 'on_clash', canNeg: true,
  },
  m_haste: {
    name: '[M] Haste', cost: 3, maxAmt: 5,
    desc: 'N Haste self next round. Neg: Bind.',
    procType: 'clash_result', canNeg: true,
    needsResultSel: true,
    restrictions: ['melee'],
  },
  double_edged: {
    name: 'Double-Edged', cost: 2, maxAmt: 1,
    desc: 'CW: 2 Bleed to target.'
      + ' CL: 2 Bleed to self.',
    procType: 'always', canNeg: false, flat: true,
  },
};

const OUTFIT_EFFECTS = {
  block_dice_power_up: {
    name: 'Block Dice Power Up', cost: 8,
    maxAmt: 5,
    desc: '+N to block dice power.',
    procType: 'always', canNeg: false,
  },
  evade_dice_power_up: {
    name: 'Evade Dice Power Up', cost: 8,
    maxAmt: 5,
    desc: '+N to evade dice power.',
    procType: 'always', canNeg: false,
  },
  padded_clothing: {
    name: 'Padded Clothing', cost: 2, maxAmt: 5,
    desc: 'Gain 3*N THP at combat start.'
      + ' Neg: take 3*N HP dmg.',
    procType: 'combat_start', canNeg: true,
  },
  damage_resistance: {
    name: 'Damage Resistance', cost: 4, maxAmt: 3,
    desc: '-N HP/ST DMG. Neg: +N DMG.',
    procType: 'always', canNeg: true,
  },
  inflict_burn: {
    name: 'Inflict Burn', cost: 2, maxAmt: 5,
    desc: 'Apply N Burn to attacker.',
    procType: 'clash_result', canNeg: true,
    needsResultSel: true,
  },
  burn_resistance: {
    name: 'Burn Resistance', cost: 2, maxAmt: 5,
    desc: '-N HP DMG from Burn. Neg: +N.',
    procType: 'always', canNeg: true,
  },
  bleed_resistance: {
    name: 'Bleed Resistance', cost: 3, maxAmt: 5,
    desc: '-N HP DMG from Bleed. Neg: +N.',
    procType: 'always', canNeg: true,
  },
  additional_reaction: {
    name: 'Additional Reaction', cost: 8,
    maxAmt: 1,
    desc: '+1 universal reaction.',
    procType: 'always', canNeg: false, flat: true,
  },
};

const AUGMENT_EFFECTS = {
  regen_hp: {
    name: 'Regen HP', cost: 1, maxAmt: 5,
    desc: 'Recover N HP on CW.'
      + ' Neg: take dmg on CL.',
    procType: 'clash_win_type', canNeg: true,
    needsTypeSel: true,
  },
  regen_st: {
    name: 'Regen ST', cost: 1, maxAmt: 5,
    desc: 'Recover N ST on CW.'
      + ' Neg: take dmg on CL.',
    procType: 'clash_win_type', canNeg: true,
    needsTypeSel: true,
  },
  inflict_burn: {
    name: 'Inflict Burn', cost: 2, maxAmt: 5,
    desc: 'Apply N Burn on Clash Win.',
    procType: 'clash_win_type', canNeg: false,
    needsTypeSel: true,
  },
  burn_bonus: {
    name: 'Burn Bonus', cost: 2, maxAmt: 1,
    desc: 'If target has 2+ Burn, +1 power.',
    procType: 'condition_type', canNeg: false,
    flat: true, needsTypeSel: true,
  },
  bleed_bonus: {
    name: 'Bleed Bonus', cost: 2, maxAmt: 1,
    desc: 'If target has Bleed, +1 power.',
    procType: 'condition_type', canNeg: false,
    flat: true, needsTypeSel: true,
  },
  activate_strength: {
    name: 'Activate Strength', cost: 6, maxAmt: 1,
    desc: '+1 Strength per 25% HP lost (max 3).'
      + ' Neg: gain Feeble instead.',
    procType: 'round_start', canNeg: true,
    flat: true,
  },
  stat_increase: {
    name: 'Stat Increase', cost: 6, maxAmt: 1,
    desc: '+1 to one chosen stat. Neg: -1.',
    procType: 'always', canNeg: true, flat: true,
  },
  damage_resistance: {
    name: 'Damage Resistance', cost: 4, maxAmt: 3,
    desc: '-N HP/ST DMG. Neg: +N DMG.',
    procType: 'always', canNeg: true,
  },
};

const SKILL_EFFECTS = {
  dice_power_up: {
    name: 'Dice Power Up', cost: 6, maxAmt: 5,
    desc: '+N to dice power.',
    procType: 'always', canNeg: true,
  },
  dice_max_up: {
    name: 'Dice Max Up', cost: 3, maxAmt: 5,
    desc: '+N to dice max.',
    procType: 'always', canNeg: true,
  },
  enemy_power_down: {
    name: 'Enemy Power Down', cost: 6, maxAmt: 5,
    desc: '-N to enemy dice power.',
    procType: 'on_clash', canNeg: true,
  },
  inflict_burn: {
    name: 'Inflict Burn', cost: 2, maxAmt: 5,
    desc: 'Apply N Burn to target.',
    procType: 'clash_result', canNeg: true,
    needsResultSel: true,
  },
  inflict_bleed: {
    name: 'Inflict Bleed', cost: 2, maxAmt: 5,
    desc: 'Apply N Bleed to target.',
    procType: 'clash_result', canNeg: true,
    needsResultSel: true,
  },
  inflict_rupture: {
    name: 'Inflict Rupture', cost: 1, maxAmt: 5,
    desc: 'Apply N Rupture next round.',
    procType: 'clash_result', canNeg: true,
    needsResultSel: true,
  },
  gain_poise: {
    name: 'Gain Poise', cost: 2, maxAmt: 5,
    desc: 'Apply N Poise to self. Neg: to target.',
    procType: 'clash_result', canNeg: true,
    needsResultSel: true,
  },
  regen_hp: {
    name: 'Regen HP', cost: 1, maxAmt: 5,
    desc: 'Recover 2*N HP. Neg: take dmg.',
    procType: 'clash_result', canNeg: true,
    needsResultSel: true,
  },
  haste: {
    name: 'Haste', cost: 3, maxAmt: 5,
    desc: 'N Haste next round. Neg: Bind.',
    procType: 'clash_result', canNeg: true,
    needsResultSel: true,
  },
  protection: {
    name: 'Protection', cost: 1, maxAmt: 5,
    desc: 'Apply N Protection next round.',
    procType: 'clash_result', canNeg: false,
    needsResultSel: true,
  },
};

// ========== EFFECT HANDLER REGISTRY ==========
// Each handler has optional lifecycle hooks.
// ctx = { self, target, dice, opponentDice,
//   isOffensive, wasAttacking, dmgResist,
//   burnReduction, bleedReduction }
const EFFECT_HANDLERS = {
  dice_power_up: {
    onDice: (ctx, eff) => {
      const s = eff.negative ? -1 : 1;
      ctx.dice.pow += s * eff.amount;
    },
  },
  dice_max_up: {
    onDice: (ctx, eff) => {
      const s = eff.negative ? -1 : 1;
      ctx.dice.max += s * eff.amount;
      if (ctx.dice.max < 1) {
        ctx.dice.pow -= (1 - ctx.dice.max);
        ctx.dice.max = 1;
      }
    },
  },
  block_dice_power_up: {
    onDice: (ctx, eff) => {
      const s = eff.negative ? -1 : 1;
      ctx.dice.pow += s * eff.amount;
    },
  },
  evade_dice_power_up: {
    onDice: (ctx, eff) => {
      const s = eff.negative ? -1 : 1;
      ctx.dice.pow += s * eff.amount;
    },
  },
  enemy_power_down: {
    onClash: (ctx, eff) => {
      if (!ctx.opponentDice) return;
      const s = eff.negative ? -1 : 1;
      ctx.opponentDice.pow -= s * eff.amount;
    },
  },
  inflict_burn: {
    onClashResult: (ctx, eff, result) => {
      if (eff.proc && eff.proc !== result) {
        return;
      }
      const tgt = eff.negative
        ? ctx.self : ctx.target;
      if (!tgt) return;
      tgt.statuses.burn += eff.amount;
    },
  },
  inflict_bleed: {
    onClashResult: (ctx, eff, result) => {
      if (eff.proc && eff.proc !== result) {
        return;
      }
      const tgt = eff.negative
        ? ctx.self : ctx.target;
      if (!tgt) return;
      tgt.statuses.bleed += eff.amount;
    },
  },
  inflict_rupture: {
    onClashResult: (ctx, eff, result) => {
      if (eff.proc && eff.proc !== result) {
        return;
      }
      const tgt = eff.negative
        ? ctx.self : ctx.target;
      if (!tgt) return;
      tgt.queuedStatuses.rupture = Math.min(6,
        tgt.queuedStatuses.rupture
          + eff.amount);
    },
  },
  gain_poise: {
    onClashResult: (ctx, eff, result) => {
      if (eff.proc && eff.proc !== result) {
        return;
      }
      const tgt = eff.negative
        ? ctx.target : ctx.self;
      if (!tgt) return;
      const wasZero = tgt.statuses.poise === 0;
      tgt.statuses.poise += eff.amount;
      if (wasZero
        && tgt.statuses.critical === 0) {
        tgt.statuses.critical = 1;
      }
    },
  },
  inflict_ruin: {
    onClashResult: (ctx, eff, result) => {
      if (eff.proc && eff.proc !== result) {
        return;
      }
      const tgt = eff.negative
        ? ctx.self : ctx.target;
      if (!tgt) return;
      const wasZero = tgt.statuses.ruin === 0;
      tgt.statuses.ruin += eff.amount;
      if (wasZero
        && tgt.statuses.devastation === 0) {
        tgt.statuses.devastation = 1;
      }
    },
  },
  m_haste: {
    onClashResult: (ctx, eff, result) => {
      if (eff.proc && eff.proc !== result) {
        return;
      }
      if (eff.negative) {
        ctx.self.queuedStatuses.bind
          += eff.amount;
      } else {
        ctx.self.queuedStatuses.haste
          += eff.amount;
      }
    },
  },
  double_edged: {
    onClashResult: (ctx, eff, result) => {
      if (result === 'clash_win') {
        if (ctx.target) {
          ctx.target.statuses.bleed += 2;
        }
      } else if (result === 'clash_lose') {
        ctx.self.statuses.bleed += 2;
      }
    },
  },
  padded_clothing: {
    onCombatStart: (ctx, eff) => {
      if (eff.negative) {
        ctx.self.hp = Math.max(1,
          ctx.self.hp - 3 * eff.amount);
      } else {
        ctx.self.tempHp += 3 * eff.amount;
      }
    },
  },
  damage_resistance: {
    onDamage: (ctx, eff) => {
      const s = eff.negative ? -1 : 1;
      ctx.dmgResist += s * eff.amount;
    },
  },
  burn_resistance: {
    onBurnTick: (ctx, eff) => {
      const s = eff.negative ? -1 : 1;
      ctx.burnReduction += s * eff.amount;
    },
  },
  bleed_resistance: {
    onBleedTick: (ctx, eff) => {
      const s = eff.negative ? -1 : 1;
      ctx.bleedReduction += s * eff.amount;
    },
  },
  additional_reaction: {
    onCombatStart: (ctx, eff) => {
      ctx.self.reactions += 1;
      ctx.self.reactionsLeft += 1;
    },
  },
  regen_hp: {
    onClashResult: (ctx, eff, result) => {
      if (result !== 'clash_win') return;
      if (eff.typeSel === 'attack'
        && !ctx.wasAttacking) return;
      if (eff.typeSel === 'defense'
        && ctx.wasAttacking) return;
      const s = eff.negative ? -1 : 1;
      ctx.self.hp = Math.max(0, Math.min(
        ctx.self.hpMax,
        ctx.self.hp + s * eff.amount));
    },
  },
  regen_st: {
    onClashResult: (ctx, eff, result) => {
      if (result !== 'clash_win') return;
      if (eff.typeSel === 'attack'
        && !ctx.wasAttacking) return;
      if (eff.typeSel === 'defense'
        && ctx.wasAttacking) return;
      const s = eff.negative ? -1 : 1;
      ctx.self.st = Math.max(0, Math.min(
        ctx.self.stMax,
        ctx.self.st + s * eff.amount));
    },
  },
  burn_bonus: {
    onCondition: (ctx, eff) => {
      if (!ctx.target) return;
      if (ctx.target.statuses.burn < 2) return;
      if (eff.typeSel === 'attack'
        && ctx.isOffensive) {
        ctx.dice.pow += 1;
      }
      if (eff.typeSel === 'defense'
        && !ctx.isOffensive) {
        ctx.dice.pow += 1;
      }
    },
  },
  bleed_bonus: {
    onCondition: (ctx, eff) => {
      if (!ctx.target) return;
      if (ctx.target.statuses.bleed < 1) {
        return;
      }
      if (eff.typeSel === 'attack'
        && ctx.isOffensive) {
        ctx.dice.pow += 1;
      }
      if (eff.typeSel === 'defense'
        && !ctx.isOffensive) {
        ctx.dice.pow += 1;
      }
    },
  },
  activate_strength: {
    onRoundStart: (ctx, eff) => {
      const pctLost = (ctx.self.hpMax
        - ctx.self.hp) / ctx.self.hpMax;
      const stacks = Math.min(3,
        Math.floor(pctLost / 0.25));
      if (stacks <= 0) return;
      if (eff.negative) {
        ctx.self.statuses.feeble += stacks;
      } else {
        ctx.self.statuses.strength += stacks;
      }
    },
  },
  stat_increase: {
    // Already baked into character stats
    // before combat starts - no hook needed
  },
  protection: {
    onClashResult: (ctx, eff, result) => {
      if (eff.proc && eff.proc !== result) {
        return;
      }
      ctx.self.queuedStatuses.protection
        += eff.amount;
    },
  },
  haste: {
    onClashResult: (ctx, eff, result) => {
      if (eff.proc && eff.proc !== result) {
        return;
      }
      if (eff.negative) {
        ctx.self.queuedStatuses.bind
          += eff.amount;
      } else {
        ctx.self.queuedStatuses.haste
          += eff.amount;
      }
    },
  },
};

// ========== DERIVED ATTRIBUTE CALC ==========
function calcDerived(stats, rank) {
  const r = rank || 1;
  return {
    hp: 64 + (stats.fortitude * 8) + (r * 32),
    st: 20 + (stats.charm * 4) + (r * 4),
    sp: 15 + (stats.prudence * 3),
    light: 3 + r,
    speed: '1d6+' + stats.justice,
    atkMod: r,
    evadeMod: stats.insight,
    blockMod: stats.temperance,
    actions: r >= 3 ? 2 : 1,
    reactions: r,
    movement: 6,
  };
}

// Calculate weapon dice preview
function calcWeaponDice(weapon) {
  let diceMax = 10;
  let dicePow = 0;
  // Form bonuses
  if (weapon.form === 'medium'
    || weapon.form === 'high_caliber') {
    diceMax += 2;
  }
  // Hand bonuses
  if (weapon.hand === 'off_1h') dicePow += 1;
  if (weapon.hand === 'off_2h') dicePow += 2;
  // Rank 1 attack mod
  dicePow += 1;
  // Effects
  for (let i = 0; i < weapon.effects.length; i++) {
    const e = weapon.effects[i];
    if (e.key === 'dice_power_up') {
      dicePow += (e.negative ? -e.amount : e.amount);
    }
    if (e.key === 'dice_max_up') {
      diceMax += (e.negative ? -e.amount : e.amount);
    }
  }
  if (diceMax < 1) {
    dicePow -= (1 - diceMax);
    diceMax = 1;
  }
  return { num: 1, max: diceMax, pow: dicePow };
}

// Calculate EP budget for weapon
function calcWeaponEP(weapon) {
  let base = 4;
  if (weapon.hand === 'off_2h'
    || weapon.hand === 'def_2h') {
    base += 2;
  }
  return base;
}

// Calculate EP budget for outfit
function calcOutfitEP(outfit) {
  let base = 4;
  if (outfit.property === 'balanced') base += 2;
  return base;
}

// Calculate EP spent on effects list
function calcEPSpent(effects, table) {
  let pos = 0;
  let neg = 0;
  for (let i = 0; i < effects.length; i++) {
    const e = effects[i];
    const def = table[e.key];
    if (!def) continue;
    const c = def.flat
      ? def.cost : def.cost * e.amount;
    if (e.negative) neg += c;
    else pos += c;
  }
  return { pos, neg };
}

// Trim effects from end until within budget.
// Returns true if any effects were removed.
function trimEffectsToFit(effects, table,
  budget) {
  let removed = false;
  while (effects.length > 0) {
    const spent = calcEPSpent(effects, table);
    const maxPos = budget + spent.neg;
    if (spent.pos <= maxPos
      && spent.neg <= budget) {
      break;
    }
    effects.pop();
    removed = true;
  }
  return removed;
}

// ========== SUMMARY GENERATORS ==========
// Build a natural-language sentence from an
// effect instance + its definition.
function effectSentence(e, def) {
  if (!def) return '';
  let desc = def.desc.replace(/N/g,
    '' + (e.amount || 1));
  let prefix = '';
  if (e.typeSel === 'attack') {
    prefix = 'On atk CW: ';
  } else if (e.typeSel === 'defense') {
    prefix = 'On def CW: ';
  } else if (e.proc === 'clash_win') {
    prefix = 'On CW: ';
  } else if (e.proc === 'clash_lose') {
    prefix = 'On CL: ';
  } else if (def.procType === 'always') {
    prefix = 'Always: ';
  } else if (def.procType === 'on_clash') {
    prefix = 'In clash: ';
  } else if (def.procType === 'combat_start') {
    prefix = 'On combat start: ';
  } else if (def.procType === 'round_start') {
    prefix = 'Round start: ';
  } else if (def.procType === 'condition_type') {
    prefix = 'Conditional: ';
  }
  if (e.negative) prefix = '(NEG) ' + prefix;
  return prefix + desc;
}

function summarizeWeapon(w) {
  const lines = [];
  const dice = calcWeaponDice(w);
  const forms = w.type === 'melee'
    ? MELEE_FORMS : RANGED_FORMS;
  const hands = w.type === 'melee'
    ? MELEE_HANDS : RANGED_HANDS;
  const form = forms.find(
    f => f.key === w.form);
  const hand = hands.find(
    h => h.key === w.hand);
  const typeName = w.type === 'melee'
    ? 'melee ' + (w.dmgType || 'slash')
    : 'ranged';
  lines.push(
    (hand ? hand.name : '?') + ' '
      + (form ? form.name : '?') + ' '
      + typeName + ' weapon.'
  );
  lines.push(
    'Rolls 1d' + dice.max
      + (dice.pow >= 0 ? '+' : '')
      + dice.pow + ' in clashes.'
  );
  if (w.effects.length === 0) {
    lines.push('No extra effects.');
  }
  for (let i = 0; i < w.effects.length; i++) {
    const e = w.effects[i];
    const def = WEAPON_EFFECTS[e.key];
    lines.push('- ' + effectSentence(e, def));
  }
  return lines;
}

function summarizeOutfit(o) {
  const lines = [];
  const prop = OUTFIT_PROPS.find(
    p => p.key === o.property);
  lines.push(
    (prop ? prop.name : '?')
      + ' outfit. Block 1d10, Evade 1d12.'
  );
  // List weak/fatal resistances
  const weaks = [];
  const endureds = [];
  const keys = ['slash_hp', 'pierce_hp',
    'blunt_hp', 'slash_st', 'pierce_st',
    'blunt_st'];
  const labels = ['Slash HP', 'Pierce HP',
    'Blunt HP', 'Slash ST', 'Pierce ST',
    'Blunt ST'];
  for (let i = 0; i < keys.length; i++) {
    const lvl = o.resistances[keys[i]];
    if (lvl === 'weak' || lvl === 'fatal') {
      weaks.push(labels[i]);
    } else if (lvl === 'endured'
      || lvl === 'ineffective'
      || lvl === 'immune') {
      endureds.push(labels[i]);
    }
  }
  if (weaks.length) {
    lines.push('Weak to: ' + weaks.join(', '));
  }
  if (endureds.length) {
    lines.push('Resists: '
      + endureds.join(', '));
  }
  if (o.effects.length === 0) {
    lines.push('No extra effects.');
  }
  for (let i = 0; i < o.effects.length; i++) {
    const e = o.effects[i];
    const def = OUTFIT_EFFECTS[e.key];
    lines.push('- ' + effectSentence(e, def));
  }
  return lines;
}

function summarizeAugment(a) {
  const lines = [];
  if (!a || !a.enabled) {
    lines.push('No augment installed.');
    return lines;
  }
  if (a.effects.length === 0) {
    lines.push('Augment installed, no'
      + ' effects chosen yet.');
    return lines;
  }
  for (let i = 0; i < a.effects.length; i++) {
    const e = a.effects[i];
    const def = AUGMENT_EFFECTS[e.key];
    lines.push('- ' + effectSentence(e, def));
  }
  return lines;
}

function summarizeSkill(s) {
  const lines = [];
  const sType = SKILL_TYPES.find(
    t => t.key === s.type);
  lines.push(
    (sType ? sType.name : 'No type')
      + ' skill. Costs '
      + s.lightCost + ' Light.'
  );
  if (s.effects.length === 0) {
    lines.push('No effects chosen yet.');
  }
  for (let i = 0; i < s.effects.length; i++) {
    const e = s.effects[i];
    const def = SKILL_EFFECTS[e.key];
    lines.push('- ' + effectSentence(e, def));
  }
  return lines;
}

// ========== DEBUG TEST BUILDERS ==========
function buildTestCharacter() {
  return {
    stats: {
      fortitude: 2, prudence: 1,
      justice: 1, charm: 0,
      insight: 0, temperance: 2,
    },
    weapon: {
      name: 'Test Blade',
      type: 'melee',
      dmgType: 'slash',
      form: 'medium',
      hand: 'off_1h',
      effects: [
        {
          key: 'dice_power_up',
          amount: 1, negative: false,
          proc: null, typeSel: null,
        },
        {
          key: 'inflict_burn',
          amount: 2, negative: false,
          proc: 'clash_win',
          typeSel: null,
        },
      ],
    },
    outfit: {
      name: 'Test Coat',
      property: 'balanced',
      resistances: {
        slash_hp: 'weak', pierce_hp: 'normal',
        blunt_hp: 'normal',
        slash_st: 'weak', pierce_st: 'normal',
        blunt_st: 'weak',
      },
      effects: [
        {
          key: 'padded_clothing',
          amount: 2, negative: false,
          proc: null, typeSel: null,
        },
        {
          key: 'damage_resistance',
          amount: 1, negative: false,
          proc: null, typeSel: null,
        },
      ],
    },
    augment: {
      enabled: true,
      effects: [
        {
          key: 'regen_hp',
          amount: 1, negative: false,
          proc: null, typeSel: 'attack',
        },
      ],
    },
    skills: [
      {
        name: 'Test Slash', type: 'attack',
        lightCost: 1,
        effects: [
          {
            key: 'dice_power_up',
            amount: 1, negative: false,
            proc: null, typeSel: null,
          },
          {
            key: 'inflict_bleed',
            amount: 2, negative: false,
            proc: 'clash_win',
            typeSel: null,
          },
        ],
      },
      {
        name: 'Test Guard', type: 'block',
        lightCost: 1,
        effects: [
          {
            key: 'dice_power_up',
            amount: 1, negative: false,
            proc: null, typeSel: null,
          },
          {
            key: 'gain_poise',
            amount: 2, negative: false,
            proc: 'clash_win',
            typeSel: null,
          },
        ],
      },
    ],
    charName: 'Debug Fixer',
  };
}

function buildTestEnemy() {
  return {
    id: 'enemy_0',
    name: 'Sparring Dummy',
    isPlayer: false,
    hp: 50, hpMax: 50,
    st: 15, stMax: 15,
    actions: 1, reactions: 1, move: 6,
    actionsLeft: 1, reactionsLeft: 1,
    moveLeft: 6,
    x: 12, y: 5,
    staggered: false,
    staggerTurns: 0,
    recycledEvades: 0,
    speed: 0,
    tempHp: 0,
    activeSkillIdx: -1,
    statuses: initStatusBlock(),
    queuedStatuses: initStatusBlock(),
    atkDice: { num: 1, max: 10, pow: 1 },
    dmgType: 'slash',
    blockDice: { num: 1, max: 10, pow: 0 },
    evadeDice: { num: 1, max: 12, pow: 0 },
    resist: {
      slash_hp: 1.0, pierce_hp: 1.0,
      blunt_hp: 1.0,
      slash_st: 1.0, pierce_st: 1.0,
      blunt_st: 1.0,
    },
    ai: 'aggressive',
    // Enemies don't have full equipment -
    // empty effect lists for uniform procs
    weapon: null,
    outfit: null,
    augment: null,
    skills: [],
  };
}

function buildTestArena() {
  // 15x10 tiles. 0 = floor, 1 = wall
  const W = 15;
  const H = 10;
  const tiles = new Array(W * H).fill(0);
  // Wall cluster top-center
  tiles[2 * W + 5] = 1;
  tiles[2 * W + 6] = 1;
  tiles[3 * W + 5] = 1;
  tiles[3 * W + 6] = 1;
  // Wall cluster bottom-center
  tiles[7 * W + 5] = 1;
  tiles[7 * W + 6] = 1;
  tiles[8 * W + 5] = 1;
  tiles[8 * W + 6] = 1;
  return { w: W, h: H, tiles: tiles };
}

// Check if adding an effect would fit budget
function canAddEffect(effects, table, budget,
  def, amount, negative) {
  const cost = def.flat ? def.cost
    : def.cost * amount;
  const cur = calcEPSpent(effects, table);
  if (negative) {
    const newNeg = cur.neg + cost;
    if (newNeg > budget) return false;
    return true;
  }
  const maxPos = budget + cur.neg;
  if (cur.pos + cost > maxPos) return false;
  return true;
}

// Resistance level indices for trading math
const RESIST_LEVEL_IDX = {
  fatal: 0, weak: 1, normal: 2,
  endured: 3, ineffective: 4, immune: 5,
};

// Sum resistance levels as points
function sumResistPoints(resistances) {
  let total = 0;
  const keys = Object.keys(resistances);
  for (let i = 0; i < keys.length; i++) {
    total += RESIST_LEVEL_IDX[
      resistances[keys[i]]] || 0;
  }
  return total;
}

// Rank 1: 1 Weak HP + 2 Weak ST
// = 3 Normal(HP) - 1 + 3 Normal(ST) - 2
// = 6*2 - 3 = 9 points baseline
const RANK1_RESIST_TOTAL = 9;
// At Rank 1, max resistance is Endured (idx 3)
const RANK1_RESIST_MAX_IDX = 3;

// ========== PMTTRPG ENGINE ==========
class PMTTRPGEngine {
  constructor(canvas, act) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.act = act;

    this.state = GS_TITLE;
    this.hasSave = false;
    this.saveData = null;
    this.leaderboard = [];

    // Title
    this.titleSel = 0;
    this.confirmDelete = false;

    // Character creation
    this.createStep = 0;
    this.cc = this.freshCC();

    // UI state
    this.cursor = 0;
    this.scroll = 0;
    this.mx = 0;
    this.my = 0;
    this.effectPicker = null;
    this.effectSearch = '';
    this.skillTab = 0;
    this.focusedField = null; // 'weapon','outfit',
    // 'skill0','skill1','char', null
    this.tooltip = null;

    // Animation
    this.running = false;
    this.lastTime = 0;
    this.rafId = null;
    this.blink = 0;

    // Combat state (null when not in combat)
    this.combat = null;
    this.combatAnimTimer = 0;
    this.combatAnimQueue = [];
    this.combatDebug = true;
  }

  freshCC() {
    return {
      stats: {
        fortitude: 0, prudence: 0,
        justice: 0, charm: 0,
        insight: 0, temperance: 0,
      },
      weapon: {
        type: 'melee', dmgType: 'slash',
        form: 'medium', hand: 'off_1h',
        effects: [], name: '',
      },
      outfit: {
        property: 'balanced',
        // Rank 1 defaults: 1 Weak HP, 2 Weak ST
        resistances: {
          slash_hp: 'weak', pierce_hp: 'normal',
          blunt_hp: 'normal',
          slash_st: 'weak', pierce_st: 'normal',
          blunt_st: 'weak',
        },
        effects: [], name: '',
      },
      augment: { enabled: false, effects: [] },
      skills: [
        {
          name: '', type: 'attack',
          lightCost: 1, effects: [],
        },
        {
          name: '', type: 'block',
          lightCost: 1, effects: [],
        },
      ],
      charName: '',
    };
  }

  loadData(data) {
    this.hasSave = !!data.has_save;
    this.saveData = data.save_data || null;
    this.leaderboard = data.leaderboard || [];
  }

  start() {
    this.lastTime = performance.now();
    this.running = true;
    this.loop(this.lastTime);
  }

  stop() {
    this.running = false;
    if (this.rafId) cancelAnimationFrame(this.rafId);
  }

  loop(time) {
    if (!this.running) return;
    const dt = Math.min(
      (time - this.lastTime) / 1000, 0.05
    );
    this.lastTime = time;
    this.blink += dt;
    if (this.blink > 1) this.blink -= 1;
    if (this.combat) {
      this.updateCombat(dt);
    }
    this.render();
    this.rafId = requestAnimationFrame(
      t => this.loop(t)
    );
  }

  // ========== RENDER DISPATCH ==========
  render() {
    const ctx = this.ctx;
    ctx.fillStyle = COL.bg;
    ctx.fillRect(0, 0, CW, CH);
    switch (this.state) {
      case GS_TITLE:
        this.renderTitle(); break;
      case GS_CREATE_STATS:
        this.renderCreateChrome();
        this.renderStats(); break;
      case GS_CREATE_WEAPON:
        this.renderCreateChrome();
        this.renderWeapon(); break;
      case GS_CREATE_OUTFIT:
        this.renderCreateChrome();
        this.renderOutfit(); break;
      case GS_CREATE_AUGMENT:
        this.renderCreateChrome();
        this.renderAugment(); break;
      case GS_CREATE_SKILLS:
        this.renderCreateChrome();
        this.renderSkills(); break;
      case GS_CREATE_REVIEW:
        this.renderCreateChrome();
        this.renderReview(); break;
      case GS_CREATED:
        this.renderCreated(); break;
      case GS_COMBAT:
        this.renderCombat(); break;
      case GS_COMBAT_VICTORY:
        this.renderCombatEnd('VICTORY!',
          COL.textGreen); break;
      case GS_COMBAT_DEFEAT:
        this.renderCombatEnd('DEFEATED',
          COL.textRed); break;
      default: break;
    }
    // Effect picker overlay on top
    if (this.effectPicker) {
      this.renderEffectPickerOverlay();
    }
  }

  // ========== TITLE SCREEN ==========
  renderTitle() {
    const ctx = this.ctx;
    // Border
    ctx.strokeStyle = COL.panelBorder;
    ctx.lineWidth = 2;
    ctx.strokeRect(20, 20, CW - 40, CH - 40);
    // Title
    this.drawTextC(
      'THE CITY', COL.textGold, 28, 120
    );
    this.drawTextC(
      'A Fixer\'s Chronicle',
      COL.textDim, 14, 155
    );
    this.drawTextC(
      'PM TTRPG Arcade',
      COL.textDim, 11, 175
    );
    // Menu items
    const items = ['New Game', 'Continue',
      'Delete Save', 'Debug Combat'];
    const avail = [true, this.hasSave,
      this.hasSave, true];
    for (let i = 0; i < 4; i++) {
      const y = 220 + i * 45;
      const sel = (this.titleSel === i);
      const ok = avail[i];
      let col;
      if (!ok) col = COL.textDim;
      else if (i === 3) {
        col = sel ? '#ffaa44' : '#aa6622';
      } else {
        col = sel ? COL.textGold : COL.text;
      }
      if (sel && ok) {
        ctx.fillStyle = COL.btnHover;
        ctx.fillRect(CW / 2 - 110, y - 5,
          220, 32);
      }
      this.drawTextC(
        (sel ? '> ' : '  ')
          + items[i]
          + (sel ? ' <' : ''), col, 16, y + 16
      );
    }
    // Delete confirmation
    if (this.confirmDelete) {
      ctx.fillStyle = 'rgba(0,0,0,0.7)';
      ctx.fillRect(0, 0, CW, CH);
      this.drawPanel(CW / 2 - 150,
        CH / 2 - 60, 300, 120);
      this.drawTextC('Delete save?',
        COL.textRed, 16, CH / 2 - 20);
      this.drawTextC(
        '[ENTER] Yes    [ESC] No',
        COL.text, 12, CH / 2 + 20
      );
    }
    // Leaderboard
    this.drawTextC('-- LEADERBOARD --',
      COL.textGold, 12, 440);
    const lb = this.leaderboard || [];
    if (!lb.length) {
      this.drawTextC('No scores yet',
        COL.textDim, 11, 460);
    }
    for (let i = 0; i < lb.length
      && i < 5; i++) {
      const e = lb[i];
      const n = (e.name || '???')
        .substring(0, 16);
      this.drawTextC(
        (i + 1) + '. ' + n + ' - '
          + (e.score || 0),
        COL.textGold, 11, 460 + i * 16
      );
    }
    // Controls
    this.drawTextC(
      'Arrow Keys to select, ENTER to confirm',
      COL.textDim, 11, CH - 40
    );
  }

  // ========== CREATE CHROME ==========
  renderCreateChrome() {
    const ctx = this.ctx;
    // Step tabs
    const tabW = 120;
    const tabH = 28;
    const startX = (CW - tabW * 6) / 2;
    for (let i = 0; i < 6; i++) {
      const x = startX + i * tabW;
      const active = (i === this.createStep);
      ctx.fillStyle = active
        ? COL.tabActive : COL.tabInactive;
      ctx.fillRect(x, 8, tabW - 4, tabH);
      ctx.fillStyle = active
        ? COL.textGold : COL.textDim;
      ctx.font = '11px monospace';
      ctx.fillText(
        (i + 1) + '.' + CREATE_STEPS[i],
        x + 6, 26
      );
    }
    // Divider line
    ctx.strokeStyle = COL.panelBorder;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(20, 42);
    ctx.lineTo(CW - 20, 42);
    ctx.stroke();
    // Back / Next buttons
    const canBack = this.createStep > 0;
    const canNext = this.canAdvanceStep();
    if (canBack) {
      this.drawBtn(
        '< Back', 30, CH - 40, 80, 28,
        COL.btnNorm
      );
    }
    const nextLabel = this.createStep === 5
      ? 'Confirm' : 'Next >';
    this.drawBtn(
      nextLabel, CW - 120, CH - 40, 90, 28,
      canNext ? COL.btnActive : COL.btnDisabled
    );
    // Right panel: derived stats (skip in
    // review step - it shows its own stats)
    if (this.state !== GS_CREATE_REVIEW) {
      this.renderDerivedPanel();
    }
  }

  renderDerivedPanel() {
    const ctx = this.ctx;
    const px = 580;
    const py = 50;
    const pw = 200;
    this.drawPanel(px, py, pw, 350);
    ctx.fillStyle = COL.textGold;
    ctx.font = '12px monospace';
    ctx.fillText('DERIVED ATTRIBUTES',
      px + 10, py + 20);
    const d = calcDerived(this.cc.stats, 1);
    const lines = [
      ['HP', '' + d.hp, COL.hpBar],
      ['ST', '' + d.st, COL.stBar],
      ['SP', '' + d.sp, COL.spBar],
      ['Light', '' + d.light, COL.lightOrb],
      ['Speed', d.speed, COL.textGreen],
      ['Atk Mod', '+' + d.atkMod, COL.text],
      ['Evade Mod', '+' + d.evadeMod,
        COL.text],
      ['Block Mod', '+' + d.blockMod,
        COL.text],
      ['Actions', '' + d.actions, COL.text],
      ['Reactions', '' + d.reactions,
        COL.text],
      ['Movement', d.movement + ' SQR',
        COL.text],
    ];
    for (let i = 0; i < lines.length; i++) {
      const y = py + 40 + i * 24;
      ctx.fillStyle = COL.textDim;
      ctx.font = '11px monospace';
      ctx.fillText(lines[i][0], px + 10, y);
      ctx.fillStyle = lines[i][2];
      ctx.fillText(lines[i][1],
        px + pw - 10
          - ctx.measureText(
            lines[i][1]).width, y);
    }
    // HP/ST/SP bars
    const barX = px + 10;
    const barW = pw - 20;
    this.drawBar(barX, py + 44, barW, 6,
      1, 1, COL.hpBar);
    this.drawBar(barX, py + 68, barW, 6,
      1, 1, COL.stBar);
    this.drawBar(barX, py + 92, barW, 6,
      1, 1, COL.spBar);
  }

  canAdvanceStep() {
    const cc = this.cc;
    switch (this.createStep) {
      case 0: {
        const s = cc.stats;
        const sum = s.fortitude + s.prudence
          + s.justice + s.charm + s.insight
          + s.temperance;
        return sum === 6;
      }
      case 1:
        return cc.weapon.type
          && cc.weapon.form && cc.weapon.hand;
      case 2: {
        // Outfit must be selected and the
        // resistance point total must match
        // the Rank 1 default (no freebies)
        if (!cc.outfit.property) return false;
        const pts = sumResistPoints(
          cc.outfit.resistances);
        return pts === RANK1_RESIST_TOTAL;
      }
      case 3:
        return true;
      case 4:
        return cc.skills[0].type
          && cc.skills[1].type;
      case 5:
        return cc.charName.length >= 1;
      default: return false;
    }
  }

  // ========== STEP 1: STATS ==========
  renderStats() {
    const ctx = this.ctx;
    ctx.fillStyle = COL.text;
    ctx.font = '14px monospace';
    ctx.fillText('STAT ALLOCATION', 40, 70);
    const sum = Object.values(this.cc.stats)
      .reduce((a, b) => a + b, 0);
    ctx.fillStyle = sum === 6
      ? COL.textGreen : COL.textRed;
    ctx.font = '12px monospace';
    ctx.fillText(
      'Points used: ' + sum + '/6'
        + (sum === 6 ? '  [READY]' : ''),
      40, 88
    );
    ctx.fillStyle = COL.textDim;
    ctx.font = '10px monospace';
    ctx.fillText(
      'Range: -1 to 3. Total must equal 6.',
      40, 104
    );
    for (let i = 0; i < STAT_DEFS.length; i++) {
      const sd = STAT_DEFS[i];
      const y = 130 + i * 56;
      const val = this.cc.stats[sd.key];
      const sel = (this.cursor === i);
      // Highlight row
      if (sel) {
        ctx.fillStyle = COL.btnHover;
        ctx.fillRect(30, y - 4, 520, 48);
      }
      // Stat name
      ctx.fillStyle = sd.color;
      ctx.font = '14px monospace';
      ctx.fillText(sd.name, 42, y + 16);
      // Description
      ctx.fillStyle = COL.textDim;
      ctx.font = '10px monospace';
      ctx.fillText(sd.desc, 42, y + 34);
      // [-] button
      this.drawBtn('-', 300, y, 30, 30,
        val > -1 ? COL.btnNorm
          : COL.btnDisabled);
      // Value
      ctx.fillStyle = val > 0
        ? COL.textGreen
        : val < 0 ? COL.textRed : COL.text;
      ctx.font = '20px monospace';
      const vs = (val >= 0 ? '+' : '') + val;
      ctx.fillText(vs, 345, y + 22);
      // [+] button
      this.drawBtn('+', 400, y, 30, 30,
        val < 3 ? COL.btnNorm
          : COL.btnDisabled);
    }
  }

  // ========== STEP 2: WEAPON ==========
  renderWeapon() {
    const ctx = this.ctx;
    const w = this.cc.weapon;
    let y = 55;
    ctx.fillStyle = COL.text;
    ctx.font = '13px monospace';
    ctx.fillText('WEAPON CREATION', 40, y);
    // Name input to the right of title
    ctx.fillStyle = COL.textDim;
    ctx.font = '10px monospace';
    ctx.fillText('Name:', 200, y);
    this.drawTextInput(
      w.name || '', 240, y - 14, 280,
      this.focusedField === 'weapon'
    );
    y += 24;
    // Type selector
    ctx.fillStyle = COL.textDim;
    ctx.font = '11px monospace';
    ctx.fillText('Type:', 40, y);
    this.drawBtn('Melee', 100, y - 12, 70, 22,
      w.type === 'melee'
        ? COL.btnActive : COL.btnNorm);
    this.drawBtn('Ranged', 180, y - 12, 70, 22,
      w.type === 'ranged'
        ? COL.btnActive : COL.btnNorm);
    y += 28;
    // DMG type (melee only)
    if (w.type === 'melee') {
      ctx.fillStyle = COL.textDim;
      ctx.font = '11px monospace';
      ctx.fillText('Damage:', 40, y);
      for (let i = 0; i < DMG_TYPES.length; i++) {
        const dt = DMG_TYPES[i];
        this.drawBtn(dt.name,
          100 + i * 80, y - 12, 70, 22,
          w.dmgType === dt.key
            ? COL.btnActive : COL.btnNorm);
      }
      y += 28;
    }
    // Form selector
    const forms = w.type === 'melee'
      ? MELEE_FORMS : RANGED_FORMS;
    ctx.fillStyle = COL.textDim;
    ctx.font = '11px monospace';
    ctx.fillText('Form:', 40, y);
    for (let i = 0; i < forms.length; i++) {
      const f = forms[i];
      const bx = 40 + (i % 3) * 170;
      const by = y + 6 + Math.floor(i / 3) * 46;
      const sel = (w.form === f.key);
      this.drawBtn(f.name, bx, by, 160, 18,
        sel ? COL.btnActive : COL.btnNorm);
      ctx.fillStyle = COL.textDim;
      ctx.font = '9px monospace';
      ctx.fillText(
        f.desc.substring(0, 28),
        bx + 2, by + 32
      );
    }
    y += 14 + Math.ceil(forms.length / 3) * 46;
    // Hand selector
    const hands = w.type === 'melee'
      ? MELEE_HANDS : RANGED_HANDS;
    ctx.fillStyle = COL.textDim;
    ctx.font = '11px monospace';
    ctx.fillText('Hand:', 40, y);
    for (let i = 0; i < hands.length; i++) {
      const h = hands[i];
      const bx = 40 + (i % 2) * 260;
      const by = y + 6 + Math.floor(i / 2) * 46;
      const sel = (w.hand === h.key);
      this.drawBtn(h.name, bx, by, 250, 18,
        sel ? COL.btnActive : COL.btnNorm);
      ctx.fillStyle = COL.textDim;
      ctx.font = '9px monospace';
      ctx.fillText(
        h.desc.substring(0, 40),
        bx + 2, by + 32
      );
    }
    y += 14 + Math.ceil(hands.length / 2) * 46;
    // EP and effects
    const budget = calcWeaponEP(w);
    const spent = calcEPSpent(
      w.effects, WEAPON_EFFECTS
    );
    this.renderEffects(
      w.effects, WEAPON_EFFECTS,
      budget, spent, y, 'weapon'
    );
    // Weapon preview in right panel area
    this.renderWeaponPreview();
  }

  renderWeaponPreview() {
    const ctx = this.ctx;
    const w = this.cc.weapon;
    const px = 580;
    const py = 410;
    const pw = 200;
    const ph = 140;
    this.drawPanel(px, py, pw, ph);
    ctx.fillStyle = COL.textGold;
    ctx.font = '11px monospace';
    ctx.fillText('WEAPON SUMMARY',
      px + 10, py + 18);
    // Name (or placeholder)
    ctx.fillStyle = w.name
      ? COL.text : COL.textDim;
    ctx.font = '10px monospace';
    ctx.fillText(
      '"' + (w.name || 'Unnamed') + '"',
      px + 10, py + 32
    );
    // Summary block (takes remaining space)
    this.renderSummaryBlock(
      px + 4, py + 38, pw - 8,
      summarizeWeapon(w),
      COL.text
    );
  }

  renderOutfitPreview() {
    const ctx = this.ctx;
    const o = this.cc.outfit;
    const px = 580;
    const py = 410;
    const pw = 200;
    const ph = 140;
    this.drawPanel(px, py, pw, ph);
    ctx.fillStyle = COL.textGold;
    ctx.font = '11px monospace';
    ctx.fillText('OUTFIT SUMMARY',
      px + 10, py + 18);
    ctx.fillStyle = o.name
      ? COL.text : COL.textDim;
    ctx.font = '10px monospace';
    ctx.fillText(
      '"' + (o.name || 'Unnamed') + '"',
      px + 10, py + 32
    );
    this.renderSummaryBlock(
      px + 4, py + 38, pw - 8,
      summarizeOutfit(o),
      COL.text
    );
  }

  renderAugmentPreview() {
    const ctx = this.ctx;
    const a = this.cc.augment;
    const px = 580;
    const py = 410;
    const pw = 200;
    const ph = 140;
    this.drawPanel(px, py, pw, ph);
    ctx.fillStyle = COL.textGold;
    ctx.font = '11px monospace';
    ctx.fillText('AUGMENT SUMMARY',
      px + 10, py + 18);
    this.renderSummaryBlock(
      px + 4, py + 24, pw - 8,
      summarizeAugment(a),
      COL.text
    );
  }

  renderSkillPreview() {
    const ctx = this.ctx;
    const s = this.cc.skills[this.skillTab];
    const cols = skillColors(s.type);
    const px = 580;
    const py = 410;
    const pw = 200;
    const ph = 140;
    this.drawColoredPanel(
      px, py, pw, ph, cols.bg, cols.border);
    ctx.fillStyle = cols.text;
    ctx.font = '11px monospace';
    ctx.fillText('SKILL SUMMARY',
      px + 10, py + 18);
    ctx.font = '10px monospace';
    ctx.fillText(
      '"' + (s.name || 'Unnamed') + '"',
      px + 10, py + 32
    );
    this.renderSummaryBlock(
      px + 4, py + 38, pw - 8,
      summarizeSkill(s),
      cols.text
    );
  }

  // ========== STEP 3: OUTFIT ==========
  renderOutfit() {
    const ctx = this.ctx;
    const o = this.cc.outfit;
    let y = 55;
    ctx.fillStyle = COL.text;
    ctx.font = '13px monospace';
    ctx.fillText('OUTFIT CREATION', 40, y);
    // Name input
    ctx.fillStyle = COL.textDim;
    ctx.font = '10px monospace';
    ctx.fillText('Name:', 200, y);
    this.drawTextInput(
      o.name || '', 240, y - 14, 280,
      this.focusedField === 'outfit'
    );
    y += 24;
    // Property selector
    ctx.fillStyle = COL.textDim;
    ctx.font = '11px monospace';
    ctx.fillText('Property:', 40, y);
    for (let i = 0;
      i < OUTFIT_PROPS.length; i++) {
      const p = OUTFIT_PROPS[i];
      const bx = 40 + i * 170;
      const by = y + 6;
      const sel = (o.property === p.key);
      this.drawBtn(p.name, bx, by, 160, 18,
        sel ? COL.btnActive : COL.btnNorm);
      ctx.fillStyle = COL.textDim;
      ctx.font = '9px monospace';
      const lines = this.wrapText(
        p.desc, 24
      );
      for (let j = 0;
        j < lines.length && j < 2; j++) {
        ctx.fillText(lines[j],
          bx + 2, by + 32 + j * 12);
      }
    }
    y += 70;
    // Resistances section
    ctx.fillStyle = COL.text;
    ctx.font = '12px monospace';
    ctx.fillText('RESISTANCES', 40, y);
    // Points balance indicator
    const curPts = sumResistPoints(
      o.resistances);
    const target = RANK1_RESIST_TOTAL;
    const balanced = curPts === target;
    ctx.fillStyle = balanced
      ? COL.textGreen : COL.textRed;
    ctx.font = '10px monospace';
    ctx.fillText(
      'Balance: ' + curPts + '/' + target
        + (balanced ? ' OK' : ' (must match)'),
      180, y
    );
    // Trading rules hint
    ctx.fillStyle = COL.textDim;
    ctx.font = '9px monospace';
    ctx.fillText(
      'Rank 1: Raise one by lowering another.'
        + ' Max level: Endured.'
        + ' Default: 1 Weak HP + 2 Weak ST.',
      40, y + 16
    );
    y += 22;
    // Header
    ctx.fillStyle = COL.textDim;
    ctx.font = '10px monospace';
    ctx.fillText('Type', 60, y + 18);
    ctx.fillText('HP Resist', 180, y + 18);
    ctx.fillText('ST Resist', 340, y + 18);
    y += 26;
    const resistKeys = ['slash', 'pierce',
      'blunt'];
    const resistNames = ['Slash', 'Pierce',
      'Blunt'];
    const resistColors = [COL.slash,
      COL.pierce, COL.blunt];
    for (let i = 0; i < 3; i++) {
      const ry = y + i * 34;
      ctx.fillStyle = resistColors[i];
      ctx.font = '11px monospace';
      ctx.fillText(resistNames[i], 60, ry + 14);
      // HP resist
      const hpKey = resistKeys[i] + '_hp';
      const hpLvl = o.resistances[hpKey]
        || 'normal';
      const hpR = RESIST_LEVELS.find(
        r => r.key === hpLvl
      );
      this.drawBtn('<', 180, ry, 20, 22,
        COL.btnNorm);
      ctx.fillStyle = hpR
        ? hpR.color : COL.text;
      ctx.font = '10px monospace';
      ctx.fillText(
        hpR ? hpR.name + ' x' + hpR.mult
          : hpLvl,
        206, ry + 14
      );
      this.drawBtn('>', 310, ry, 20, 22,
        COL.btnNorm);
      // ST resist
      const stKey = resistKeys[i] + '_st';
      const stLvl = o.resistances[stKey]
        || 'normal';
      const stR = RESIST_LEVELS.find(
        r => r.key === stLvl
      );
      this.drawBtn('<', 340, ry, 20, 22,
        COL.btnNorm);
      ctx.fillStyle = stR
        ? stR.color : COL.text;
      ctx.font = '10px monospace';
      ctx.fillText(
        stR ? stR.name + ' x' + stR.mult
          : stLvl,
        366, ry + 14
      );
      this.drawBtn('>', 470, ry, 20, 22,
        COL.btnNorm);
    }
    y += 3 * 34 + 14;
    // EP and effects
    const budget = calcOutfitEP(o);
    const spent = calcEPSpent(
      o.effects, OUTFIT_EFFECTS
    );
    this.renderEffects(
      o.effects, OUTFIT_EFFECTS,
      budget, spent, y, 'outfit'
    );
    this.renderOutfitPreview();
  }

  // ========== STEP 4: AUGMENT ==========
  renderAugment() {
    const ctx = this.ctx;
    const a = this.cc.augment;
    let y = 55;
    ctx.fillStyle = COL.text;
    ctx.font = '13px monospace';
    ctx.fillText('AUGMENT (Optional)', 40, y);
    y += 24;
    // Enable toggle
    this.drawBtn(
      a.enabled ? '[X] Enabled' : '[ ] Disabled',
      40, y, 150, 24,
      a.enabled ? COL.btnActive : COL.btnNorm
    );
    ctx.fillStyle = COL.textDim;
    ctx.font = '10px monospace';
    ctx.fillText(
      'Augments provide passive bonuses.'
        + ' Can represent cybernetics,'
        + ' training, etc.',
      40, y + 40
    );
    y += 60;
    if (a.enabled) {
      const budget = 4;
      const spent = calcEPSpent(
        a.effects, AUGMENT_EFFECTS
      );
      this.renderEffects(
        a.effects, AUGMENT_EFFECTS,
        budget, spent, y, 'augment'
      );
    }
    this.renderAugmentPreview();
  }

  // ========== STEP 5: SKILLS ==========
  renderSkills() {
    const ctx = this.ctx;
    let y = 55;
    ctx.fillStyle = COL.text;
    ctx.font = '13px monospace';
    ctx.fillText('SKILL CREATION (2 Skills)',
      40, y);
    y += 24;
    // Skill tabs
    for (let i = 0; i < 2; i++) {
      const tx = 40 + i * 260;
      const sel = (this.skillTab === i);
      this.drawBtn(
        'Skill ' + (i + 1),
        tx, y, 120, 22,
        sel ? COL.tabActive : COL.tabInactive
      );
    }
    y += 34;
    const skill = this.cc.skills[this.skillTab];
    const skillField = 'skill'
      + this.skillTab;
    // Name input
    ctx.fillStyle = COL.textDim;
    ctx.font = '11px monospace';
    ctx.fillText('Name:', 40, y);
    this.drawTextInput(
      skill.name || '', 100, y - 14, 280,
      this.focusedField === skillField
    );
    y += 28;
    // Type selector
    ctx.fillStyle = COL.textDim;
    ctx.font = '11px monospace';
    ctx.fillText('Type:', 40, y);
    for (let i = 0;
      i < SKILL_TYPES.length; i++) {
      const st = SKILL_TYPES[i];
      this.drawBtn(st.name,
        100 + i * 90, y - 12, 80, 22,
        skill.type === st.key
          ? COL.btnActive : COL.btnNorm);
    }
    y += 28;
    // Light cost
    ctx.fillStyle = COL.textDim;
    ctx.font = '11px monospace';
    ctx.fillText('Light Cost:', 40, y);
    this.drawBtn('-', 140, y - 12, 24, 22,
      skill.lightCost > 1
        ? COL.btnNorm : COL.btnDisabled);
    ctx.fillStyle = COL.textGold;
    ctx.font = '14px monospace';
    ctx.fillText('' + skill.lightCost,
      174, y + 2);
    this.drawBtn('+', 196, y - 12, 24, 22,
      skill.lightCost < 4
        ? COL.btnNorm : COL.btnDisabled);
    ctx.fillStyle = COL.textDim;
    ctx.font = '10px monospace';
    ctx.fillText(
      '(higher cost = more EP)',
      230, y
    );
    y += 30;
    // EP and effects
    const budget = 4
      + ((skill.lightCost - 1) * 1);
    const spent = calcEPSpent(
      skill.effects, SKILL_EFFECTS
    );
    this.renderEffects(
      skill.effects, SKILL_EFFECTS,
      budget, spent, y, 'skill'
    );
    this.renderSkillPreview();
  }

  // ========== STEP 6: REVIEW ==========
  renderReview() {
    const ctx = this.ctx;
    const cc = this.cc;
    // Title + name input
    ctx.fillStyle = COL.text;
    ctx.font = '12px monospace';
    ctx.fillText('CHARACTER REVIEW', 30, 58);
    ctx.fillStyle = COL.textDim;
    ctx.font = '10px monospace';
    ctx.fillText('Name:', 180, 58);
    this.drawTextInput(
      cc.charName, 220, 46, 180,
      this.focusedField === 'char'
    );
    // 2-column grid of 3 rows (6 panels)
    // Columns: left x=20 w=375, right x=405 w=375
    // Row heights: 150 each
    // Row Y: 75, 230, 385 => bottom 535 < 560
    const col1X = 20;
    const col2X = 405;
    const colW = 375;
    const rowH = 150;
    const row1Y = 75;
    const row2Y = 230;
    const row3Y = 385;
    // ----- Stats panel (col1, row1) -----
    this.drawPanel(col1X, row1Y, colW, rowH);
    ctx.fillStyle = COL.textGold;
    ctx.font = '11px monospace';
    ctx.fillText('STATS & DERIVED',
      col1X + 10, row1Y + 16);
    for (let i = 0;
      i < STAT_DEFS.length; i++) {
      const sd = STAT_DEFS[i];
      const val = cc.stats[sd.key];
      const cx = col1X + 12
        + (i % 3) * 120;
      const cy = row1Y + 36
        + Math.floor(i / 3) * 18;
      ctx.fillStyle = sd.color;
      ctx.font = '10px monospace';
      ctx.fillText(
        sd.short + ': '
          + (val >= 0 ? '+' : '') + val,
        cx, cy
      );
    }
    const d = calcDerived(cc.stats, 1);
    ctx.fillStyle = COL.textDim;
    ctx.font = '9px monospace';
    ctx.fillText(
      'HP: ' + d.hp + '  ST: ' + d.st
        + '  SP: ' + d.sp,
      col1X + 12, row1Y + 90
    );
    ctx.fillText(
      'Light: ' + d.light + '  Move: '
        + d.movement + ' SQR',
      col1X + 12, row1Y + 104
    );
    ctx.fillText(
      'Atk +' + d.atkMod + '  Blk +'
        + d.blockMod + '  Evd +'
        + d.evadeMod,
      col1X + 12, row1Y + 118
    );
    ctx.fillText(
      'Actions: ' + d.actions
        + '  Reactions: ' + d.reactions,
      col1X + 12, row1Y + 132
    );
    // ----- Weapon panel (col2, row1) -----
    const w = cc.weapon;
    this.drawPanel(col2X, row1Y, colW, rowH);
    ctx.fillStyle = COL.textGold;
    ctx.font = '11px monospace';
    ctx.fillText('WEAPON', col2X + 10,
      row1Y + 16);
    ctx.fillStyle = w.name
      ? COL.text : COL.textDim;
    ctx.font = '10px monospace';
    ctx.fillText(
      '"' + (w.name || 'Unnamed') + '"',
      col2X + 10, row1Y + 32
    );
    this.renderSummaryBlock(
      col2X + 4, row1Y + 38, colW - 8,
      summarizeWeapon(w), COL.text
    );
    // ----- Outfit panel (col1, row2) -----
    const o = cc.outfit;
    this.drawPanel(col1X, row2Y, colW, rowH);
    ctx.fillStyle = COL.textGold;
    ctx.font = '11px monospace';
    ctx.fillText('OUTFIT', col1X + 10,
      row2Y + 16);
    ctx.fillStyle = o.name
      ? COL.text : COL.textDim;
    ctx.font = '10px monospace';
    ctx.fillText(
      '"' + (o.name || 'Unnamed') + '"',
      col1X + 10, row2Y + 32
    );
    this.renderSummaryBlock(
      col1X + 4, row2Y + 38, colW - 8,
      summarizeOutfit(o), COL.text
    );
    // ----- Augment panel (col2, row2) -----
    this.drawPanel(col2X, row2Y, colW, rowH);
    ctx.fillStyle = COL.textGold;
    ctx.font = '11px monospace';
    ctx.fillText('AUGMENT', col2X + 10,
      row2Y + 16);
    this.renderSummaryBlock(
      col2X + 4, row2Y + 22, colW - 8,
      summarizeAugment(cc.augment),
      COL.text
    );
    // ----- Skill 1 (col1, row3) COLORED -----
    const s1 = cc.skills[0];
    const s1Cols = skillColors(s1.type);
    this.drawColoredPanel(
      col1X, row3Y, colW, rowH,
      s1Cols.bg, s1Cols.border
    );
    ctx.fillStyle = s1Cols.text;
    ctx.font = '11px monospace';
    ctx.fillText('SKILL 1', col1X + 10,
      row3Y + 16);
    ctx.font = '10px monospace';
    ctx.fillText(
      '"' + (s1.name || 'Unnamed') + '"',
      col1X + 10, row3Y + 32
    );
    this.renderSummaryBlock(
      col1X + 4, row3Y + 38, colW - 8,
      summarizeSkill(s1), s1Cols.text
    );
    // ----- Skill 2 (col2, row3) COLORED -----
    const s2 = cc.skills[1];
    const s2Cols = skillColors(s2.type);
    this.drawColoredPanel(
      col2X, row3Y, colW, rowH,
      s2Cols.bg, s2Cols.border
    );
    ctx.fillStyle = s2Cols.text;
    ctx.font = '11px monospace';
    ctx.fillText('SKILL 2', col2X + 10,
      row3Y + 16);
    ctx.font = '10px monospace';
    ctx.fillText(
      '"' + (s2.name || 'Unnamed') + '"',
      col2X + 10, row3Y + 32
    );
    this.renderSummaryBlock(
      col2X + 4, row3Y + 38, colW - 8,
      summarizeSkill(s2), s2Cols.text
    );
  }

  // ========== CREATED SCREEN ==========
  renderCreated() {
    this.drawTextC('Character Created!',
      COL.textGreen, 20, CH / 2 - 20);
    this.drawTextC(
      'Save data written. Press R for title.',
      COL.textDim, 12, CH / 2 + 20
    );
  }

  // ========== SHARED: EFFECT LIST ==========
  renderEffects(effects, table, budget, spent,
    y, category) {
    const ctx = this.ctx;
    const maxPos = budget + spent.neg;
    // EP bar
    ctx.fillStyle = COL.textDim;
    ctx.font = '11px monospace';
    ctx.fillText('EP: ' + spent.pos + '/'
      + maxPos
      + (spent.neg > 0
        ? ' (neg: ' + spent.neg + ')'
        : ''),
      40, y + 4
    );
    this.drawBar(40, y + 10, 200, 8,
      spent.pos / Math.max(maxPos, 1), 1,
      COL.epFill);
    y += 26;
    // Current effects
    for (let i = 0;
      i < effects.length; i++) {
      const e = effects[i];
      const def = table[e.key];
      if (!def) continue;
      let procLabel = '';
      if (e.proc === 'clash_win') {
        procLabel = ' [CW]';
      } else if (e.proc === 'clash_lose') {
        procLabel = ' [CL]';
      }
      if (e.typeSel === 'attack') {
        procLabel += ' (Atk)';
      } else if (e.typeSel === 'defense') {
        procLabel += ' (Def)';
      }
      const label = (e.negative ? '[-] ' : '[+] ')
        + def.name
        + (e.amount > 1
          ? ' x' + e.amount : '')
        + procLabel
        + ' (' + (def.flat ? def.cost
          : def.cost * e.amount) + ' EP)';
      ctx.fillStyle = e.negative
        ? COL.epNeg : COL.text;
      ctx.font = '10px monospace';
      ctx.fillText(label, 50, y + 12);
      // Remove button
      this.drawBtn('X', 430, y, 20, 18,
        COL.textRed);
      y += 22;
    }
    // Add button
    this.drawBtn('+ Add Effect', 40, y + 4,
      120, 22, COL.btnNorm);
    // Store for click detection
    this._effectsY = y + 4;
    this._effectsCategory = category;
    this._effectsBudget = budget;
    this._effectsSpent = spent;
  }

  // ========== EFFECT PICKER OVERLAY ==========
  renderEffectPickerOverlay() {
    const ctx = this.ctx;
    const ep = this.effectPicker;
    if (!ep) return;
    // Darken background
    ctx.fillStyle = 'rgba(0,0,0,0.6)';
    ctx.fillRect(0, 0, CW, CH);
    // Panel
    const px = 60;
    const py = 60;
    const pw = 500;
    const ph = 440;
    this.drawPanel(px, py, pw, ph);
    if (ep.configuring) {
      this.renderPickerConfig(px, py, pw, ph);
    } else {
      this.renderPickerList(px, py, pw, ph);
    }
  }

  renderPickerList(px, py, pw, ph) {
    const ctx = this.ctx;
    const ep = this.effectPicker;
    ctx.fillStyle = COL.textGold;
    ctx.font = '13px monospace';
    ctx.fillText('ADD EFFECT',
      px + 14, py + 24);
    // Close button
    this.drawBtn('X', px + pw - 30, py + 6,
      22, 22, COL.textRed);
    // Search
    ctx.fillStyle = COL.textDim;
    ctx.font = '10px monospace';
    ctx.fillText('Search:', px + 14, py + 46);
    this.drawTextInput(this.effectSearch,
      px + 70, py + 34, 200, true);
    // EP remaining
    const remain = ep.budget + ep.spent.neg
      - ep.spent.pos;
    ctx.fillStyle = remain > 0
      ? COL.textGreen : COL.textRed;
    ctx.font = '10px monospace';
    ctx.fillText('EP remaining: ' + remain,
      px + 300, py + 46);
    // Effect list
    const table = ep.table;
    const keys = Object.keys(table);
    const filtered = keys.filter(k => {
      const def = table[k];
      if (this.effectSearch
        && def.name.toLowerCase().indexOf(
          this.effectSearch.toLowerCase()
        ) === -1) {
        return false;
      }
      return true;
    });
    const listY = py + 60;
    const listH = ph - 80;
    const rowH = 52;
    const visible = Math.floor(listH / rowH);
    const maxScroll = Math.max(0,
      filtered.length - visible);
    if (this.scroll > maxScroll) {
      this.scroll = maxScroll;
    }
    for (let i = 0;
      i < visible && i + this.scroll
        < filtered.length; i++) {
      const key = filtered[i + this.scroll];
      const def = table[key];
      const ry = listY + i * rowH;
      const hov = this.mx >= px + 10
        && this.mx <= px + pw - 10
        && this.my >= ry
        && this.my <= ry + rowH - 2;
      if (hov) {
        ctx.fillStyle = COL.btnHover;
        ctx.fillRect(px + 10, ry,
          pw - 20, rowH - 2);
      }
      // Name and cost
      ctx.fillStyle = COL.text;
      ctx.font = '11px monospace';
      ctx.fillText(def.name, px + 18, ry + 14);
      ctx.fillStyle = COL.textDim;
      ctx.font = '10px monospace';
      ctx.fillText(
        'Cost: '
          + (def.flat ? def.cost + ' flat'
            : def.cost + '*N EP'),
        px + 250, ry + 14
      );
      // Description
      ctx.fillStyle = COL.textDim;
      ctx.font = '9px monospace';
      ctx.fillText(def.desc.substring(0, 55),
        px + 18, ry + 28);
      // Flags line (can be neg, needs CW/CL)
      let flags = 'Proc: ' + def.procType;
      if (def.canNeg) flags += ' | +/-';
      if (def.needsResultSel) {
        flags += ' | CW/CL';
      }
      if (def.needsTypeSel) {
        flags += ' | Atk/Def';
      }
      ctx.fillText(flags, px + 18, ry + 40);
      // Configure button (replaces Add)
      this.drawBtn('Config',
        px + pw - 70, ry + 4, 50, 18,
        COL.btnNorm);
    }
    // Scrollbar hint
    if (filtered.length > visible) {
      ctx.fillStyle = COL.textDim;
      ctx.font = '9px monospace';
      ctx.fillText(
        'Scroll: ' + (this.scroll + 1)
          + '-'
          + Math.min(
            this.scroll + visible,
            filtered.length)
          + '/' + filtered.length
          + ' (up/down keys)',
        px + 14, py + ph - 14
      );
    }
    // ESC hint
    ctx.fillStyle = COL.textDim;
    ctx.font = '9px monospace';
    ctx.fillText('[ESC] Close',
      px + pw - 80, py + ph - 14);
  }

  renderPickerConfig(px, py, pw, ph) {
    const ctx = this.ctx;
    const ep = this.effectPicker;
    const cfg = ep.configuring;
    const def = ep.table[cfg.key];
    if (!def) return;
    // Title
    ctx.fillStyle = COL.textGold;
    ctx.font = '13px monospace';
    ctx.fillText('CONFIGURE EFFECT',
      px + 14, py + 24);
    // Back/Close button
    this.drawBtn('X', px + pw - 30, py + 6,
      22, 22, COL.textRed);
    // Effect name + desc
    ctx.fillStyle = COL.text;
    ctx.font = '14px monospace';
    ctx.fillText(def.name, px + 14, py + 56);
    ctx.fillStyle = COL.textDim;
    ctx.font = '10px monospace';
    const dLines = this.wrapText(def.desc, 56);
    for (let i = 0;
      i < dLines.length && i < 3; i++) {
      ctx.fillText(dLines[i],
        px + 14, py + 78 + i * 14);
    }
    let y = py + 140;
    // Amount spinner (if not flat)
    if (!def.flat) {
      ctx.fillStyle = COL.textDim;
      ctx.font = '11px monospace';
      ctx.fillText('Amount:', px + 14, y);
      this.drawBtn('-', px + 90, y - 14, 24, 22,
        cfg.amount > 1
          ? COL.btnNorm : COL.btnDisabled);
      ctx.fillStyle = COL.textGold;
      ctx.font = '14px monospace';
      ctx.fillText('' + cfg.amount,
        px + 124, y);
      this.drawBtn('+', px + 146, y - 14,
        24, 22,
        cfg.amount < def.maxAmt
          ? COL.btnNorm : COL.btnDisabled);
      ctx.fillStyle = COL.textDim;
      ctx.font = '10px monospace';
      ctx.fillText(
        'Max: ' + def.maxAmt,
        px + 180, y);
      y += 36;
    }
    // Positive/Negative toggle
    if (def.canNeg) {
      ctx.fillStyle = COL.textDim;
      ctx.font = '11px monospace';
      ctx.fillText('Type:', px + 14, y);
      this.drawBtn('Positive',
        px + 90, y - 14, 90, 22,
        !cfg.negative
          ? COL.btnActive : COL.btnNorm);
      this.drawBtn('Negative',
        px + 190, y - 14, 90, 22,
        cfg.negative
          ? COL.epNeg : COL.btnNorm);
      y += 36;
    }
    // Clash result selector
    if (def.needsResultSel) {
      ctx.fillStyle = COL.textDim;
      ctx.font = '11px monospace';
      ctx.fillText('Proc:', px + 14, y);
      this.drawBtn('Clash Win',
        px + 90, y - 14, 100, 22,
        cfg.proc === 'clash_win'
          ? COL.btnActive : COL.btnNorm);
      this.drawBtn('Clash Lose',
        px + 200, y - 14, 100, 22,
        cfg.proc === 'clash_lose'
          ? COL.btnActive : COL.btnNorm);
      y += 36;
    }
    // Atk/Def selector
    if (def.needsTypeSel) {
      ctx.fillStyle = COL.textDim;
      ctx.font = '11px monospace';
      ctx.fillText('Dice:', px + 14, y);
      this.drawBtn('Attack',
        px + 90, y - 14, 90, 22,
        cfg.typeSel === 'attack'
          ? COL.btnActive : COL.btnNorm);
      this.drawBtn('Defense',
        px + 190, y - 14, 90, 22,
        cfg.typeSel === 'defense'
          ? COL.btnActive : COL.btnNorm);
      y += 36;
    }
    // Cost preview
    const cost = def.flat ? def.cost
      : def.cost * cfg.amount;
    const curSpent = calcEPSpent(
      ep.effects, ep.table);
    let newSpent;
    if (cfg.negative) {
      newSpent = {
        pos: curSpent.pos,
        neg: curSpent.neg + cost,
      };
    } else {
      newSpent = {
        pos: curSpent.pos + cost,
        neg: curSpent.neg,
      };
    }
    const fits = canAddEffect(
      ep.effects, ep.table, ep.budget,
      def, cfg.amount, cfg.negative);
    ctx.fillStyle = fits
      ? COL.textGreen : COL.textRed;
    ctx.font = '11px monospace';
    ctx.fillText(
      'Cost: ' + cost + ' EP  '
        + (cfg.negative
          ? '(negative)' : '(positive)')
        + (fits ? '' : '  [EXCEEDS BUDGET]'),
      px + 14, y + 10);
    y += 30;
    // Budget display
    ctx.fillStyle = COL.textDim;
    ctx.font = '10px monospace';
    ctx.fillText(
      'Budget: '
        + (ep.budget + newSpent.neg) + ' pos / '
        + ep.budget + ' neg max',
      px + 14, y);
    y += 16;
    ctx.fillText(
      'After add: ' + newSpent.pos
        + ' pos / ' + newSpent.neg + ' neg',
      px + 14, y);
    // Confirm / Back buttons at bottom
    this.drawBtn('Confirm',
      px + pw - 170, py + ph - 40, 80, 28,
      fits ? COL.btnActive : COL.btnDisabled);
    this.drawBtn('Back',
      px + pw - 80, py + ph - 40, 60, 28,
      COL.btnNorm);
  }

  // ========== DRAWING HELPERS ==========
  drawTextC(text, color, size, y) {
    const ctx = this.ctx;
    ctx.fillStyle = color;
    ctx.font = size + 'px monospace';
    const w = ctx.measureText(text).width;
    ctx.fillText(text, (CW - w) / 2, y);
  }

  drawPanel(x, y, w, h) {
    const ctx = this.ctx;
    ctx.fillStyle = COL.panelBg;
    ctx.fillRect(x, y, w, h);
    ctx.strokeStyle = COL.panelBorder;
    ctx.lineWidth = 1;
    ctx.strokeRect(x, y, w, h);
  }

  drawColoredPanel(x, y, w, h, bgCol,
    borderCol) {
    const ctx = this.ctx;
    ctx.fillStyle = bgCol;
    ctx.fillRect(x, y, w, h);
    ctx.strokeStyle = borderCol;
    ctx.lineWidth = 2;
    ctx.strokeRect(x, y, w, h);
    ctx.lineWidth = 1;
  }

  renderSummaryBlock(x, y, w, lines, textCol) {
    const ctx = this.ctx;
    ctx.fillStyle = textCol;
    ctx.font = '9px monospace';
    const maxChars = Math.max(10,
      Math.floor((w - 12) / 5.5));
    let dy = 0;
    for (let i = 0; i < lines.length; i++) {
      const wrapped = this.wrapText(
        lines[i], maxChars);
      for (let j = 0;
        j < wrapped.length; j++) {
        ctx.fillText(
          wrapped[j], x + 6, y + dy + 10);
        dy += 11;
      }
    }
    return dy;
  }

  drawBtn(text, x, y, w, h, color) {
    const ctx = this.ctx;
    ctx.fillStyle = color || COL.btnNorm;
    ctx.fillRect(x, y, w, h);
    ctx.strokeStyle = COL.panelBorder;
    ctx.lineWidth = 1;
    ctx.strokeRect(x, y, w, h);
    ctx.fillStyle = color === COL.btnDisabled
      ? COL.textDim : COL.text;
    ctx.font = '10px monospace';
    const tw = ctx.measureText(text).width;
    ctx.fillText(text,
      x + (w - tw) / 2, y + h / 2 + 4);
  }

  drawBar(x, y, w, h, frac, max, color) {
    const ctx = this.ctx;
    ctx.fillStyle = COL.epEmpty;
    ctx.fillRect(x, y, w, h);
    ctx.fillStyle = color;
    ctx.fillRect(x, y,
      w * Math.min(frac, 1), h);
  }

  drawTextInput(text, x, y, w, active) {
    const ctx = this.ctx;
    ctx.fillStyle = '#0a0a1a';
    ctx.fillRect(x, y, w, 20);
    ctx.strokeStyle = active
      ? COL.textGold : COL.panelBorder;
    ctx.lineWidth = 1;
    ctx.strokeRect(x, y, w, 20);
    ctx.fillStyle = COL.text;
    ctx.font = '11px monospace';
    ctx.fillText(text, x + 4, y + 14);
    // Cursor blink
    if (active && this.blink < 0.5) {
      const tw = ctx.measureText(text).width;
      ctx.fillStyle = COL.textGold;
      ctx.fillRect(x + 4 + tw, y + 3, 1, 14);
    }
  }

  wrapText(text, maxChars) {
    const words = text.split(' ');
    const lines = [];
    let line = '';
    for (let i = 0; i < words.length; i++) {
      if (line.length + words[i].length + 1
        > maxChars) {
        lines.push(line);
        line = words[i];
      } else {
        line += (line ? ' ' : '') + words[i];
      }
    }
    if (line) lines.push(line);
    return lines;
  }

  // ========== INPUT HANDLING ==========
  handleKeyDown(code) {
    // Effect picker takes priority
    if (this.effectPicker) {
      this.handleEffectPickerKey(code);
      return;
    }
    switch (this.state) {
      case GS_TITLE:
        this.handleTitleKey(code); break;
      case GS_CREATE_STATS:
      case GS_CREATE_WEAPON:
      case GS_CREATE_OUTFIT:
      case GS_CREATE_AUGMENT:
      case GS_CREATE_SKILLS:
      case GS_CREATE_REVIEW:
        this.handleCreateKey(code); break;
      case GS_CREATED:
        if (code === KEY_R) {
          this.state = GS_TITLE;
        }
        break;
      case GS_COMBAT:
        this.handleCombatKey(code); break;
      case GS_COMBAT_VICTORY:
      case GS_COMBAT_DEFEAT:
        if (code === KEY_R) {
          this.combat = null;
          this.combatAnimQueue = [];
          this.state = GS_TITLE;
        }
        break;
      default: break;
    }
  }

  handleTitleKey(code) {
    if (this.confirmDelete) {
      if (code === KEY_ENTER) {
        this.act('delete_save');
        this.hasSave = false;
        this.saveData = null;
        this.confirmDelete = false;
        this.titleSel = 0;
      }
      if (code === KEY_ESC) {
        this.confirmDelete = false;
      }
      return;
    }
    if (code === KEY_UP || code === KEY_W) {
      this.titleSel = Math.max(0,
        this.titleSel - 1);
    }
    if (code === KEY_DOWN || code === KEY_S) {
      this.titleSel = Math.min(3,
        this.titleSel + 1);
    }
    if (code === KEY_ENTER) {
      if (this.titleSel === 0) {
        // New Game
        this.cc = this.freshCC();
        this.createStep = 0;
        this.cursor = 0;
        this.state = GS_CREATE_STATS;
        this.act('sfx', { s: 'click' });
      } else if (this.titleSel === 1
        && this.hasSave) {
        // Continue (placeholder)
        this.state = GS_CREATED;
        this.act('sfx', { s: 'confirm' });
      } else if (this.titleSel === 2
        && this.hasSave) {
        this.confirmDelete = true;
      } else if (this.titleSel === 3) {
        // Debug Combat
        this.startDebugCombat();
      }
    }
  }

  handleCreateKey(code) {
    // Handle text input for focused field
    if (this.focusedField) {
      if (code === KEY_BACKSPACE) {
        this.typeIntoField('');
        return;
      }
      if (code === KEY_ENTER
        || code === KEY_TAB) {
        this.focusedField = null;
        return;
      }
      if (code === KEY_ESC) {
        this.focusedField = null;
        return;
      }
      if (code >= 32 && code <= 126) {
        const ch = String.fromCharCode(code);
        this.typeIntoField(ch);
        return;
      }
      return;
    }
    // ESC = back
    if (code === KEY_ESC) {
      if (this.createStep > 0) {
        this.createStep--;
        this.state = GS_CREATE_STATS
          + this.createStep;
        this.focusedField = null;
        this.act('sfx', { s: 'back' });
      } else {
        this.state = GS_TITLE;
      }
      return;
    }
    // ENTER = next
    if (code === KEY_ENTER) {
      if (this.canAdvanceStep()) {
        if (this.createStep < 5) {
          this.createStep++;
          this.state = GS_CREATE_STATS
            + this.createStep;
          this.cursor = 0;
          this.scroll = 0;
          this.focusedField = null;
          this.act('sfx', { s: 'click' });
        } else {
          this.submitCharacter();
        }
      } else {
        this.act('sfx', { s: 'error' });
      }
      return;
    }
    // Step-specific keys
    if (this.state === GS_CREATE_STATS) {
      this.handleStatsKey(code);
    }
    if (this.state === GS_CREATE_SKILLS) {
      if (code === KEY_TAB) {
        this.skillTab = 1 - this.skillTab;
      }
    }
  }

  handleStatsKey(code) {
    if (code === KEY_UP || code === KEY_W) {
      this.cursor = Math.max(0,
        this.cursor - 1);
    }
    if (code === KEY_DOWN || code === KEY_S) {
      this.cursor = Math.min(5,
        this.cursor + 1);
    }
    const key = STAT_DEFS[this.cursor].key;
    if (code === KEY_LEFT || code === KEY_A) {
      if (this.cc.stats[key] > -1) {
        this.cc.stats[key]--;
      }
    }
    if (code === KEY_RIGHT || code === KEY_D) {
      if (this.cc.stats[key] < 3) {
        this.cc.stats[key]++;
      }
    }
  }

  handleEffectPickerKey(code) {
    const ep = this.effectPicker;
    if (!ep) return;
    // Configuring mode: ESC goes to list
    if (ep.configuring) {
      if (code === KEY_ESC) {
        ep.configuring = null;
      }
      if (code === KEY_ENTER) {
        this.confirmConfiguring();
      }
      return;
    }
    if (code === KEY_ESC) {
      this.effectPicker = null;
      this.effectSearch = '';
      this.scroll = 0;
      return;
    }
    if (code === KEY_UP) {
      this.scroll = Math.max(0,
        this.scroll - 1);
      return;
    }
    if (code === KEY_DOWN) {
      this.scroll++;
      return;
    }
    if (code === KEY_BACKSPACE) {
      this.effectSearch = this.effectSearch
        .slice(0, -1);
      this.scroll = 0;
      return;
    }
    // Typing into search
    if (code >= 32 && code <= 126) {
      this.effectSearch
        += String.fromCharCode(code);
      this.scroll = 0;
    }
  }

  // ========== CLICK HANDLING ==========
  handleClick(x, y) {
    // Effect picker overlay
    if (this.effectPicker) {
      this.handleEffectPickerClick(x, y);
      return;
    }
    switch (this.state) {
      case GS_TITLE:
        this.handleTitleClick(x, y); break;
      case GS_CREATE_STATS:
        this.handleStatsClick(x, y); break;
      case GS_CREATE_WEAPON:
        this.handleWeaponClick(x, y); break;
      case GS_CREATE_OUTFIT:
        this.handleOutfitClick(x, y); break;
      case GS_CREATE_AUGMENT:
        this.handleAugmentClick(x, y); break;
      case GS_CREATE_SKILLS:
        this.handleSkillsClick(x, y); break;
      case GS_CREATE_REVIEW:
        this.handleReviewClick(x, y); break;
      case GS_COMBAT:
        this.handleCombatClick(x, y); break;
      default: break;
    }
    // Back/Next buttons (all create states)
    if (this.state >= GS_CREATE_STATS
      && this.state <= GS_CREATE_REVIEW) {
      // Back
      if (this.createStep > 0
        && this.hitTest(x, y, 30, CH - 40,
          80, 28)) {
        this.createStep--;
        this.state = GS_CREATE_STATS
          + this.createStep;
        this.focusedField = null;
        this.act('sfx', { s: 'back' });
        return;
      }
      // Next/Confirm
      if (this.hitTest(x, y, CW - 120,
        CH - 40, 90, 28)
        && this.canAdvanceStep()) {
        if (this.createStep < 5) {
          this.createStep++;
          this.state = GS_CREATE_STATS
            + this.createStep;
          this.cursor = 0;
          this.scroll = 0;
          this.focusedField = null;
          this.act('sfx', { s: 'click' });
        } else {
          this.submitCharacter();
        }
      }
    }
  }

  handleTitleClick(x, y) {
    for (let i = 0; i < 4; i++) {
      const iy = 220 + i * 45;
      if (this.hitTest(x, y, CW / 2 - 110,
        iy - 5, 220, 32)) {
        this.titleSel = i;
        this.handleTitleKey(KEY_ENTER);
        return;
      }
    }
  }

  handleStatsClick(x, y) {
    for (let i = 0; i < 6; i++) {
      const iy = 130 + i * 56;
      const key = STAT_DEFS[i].key;
      // [-]
      if (this.hitTest(x, y, 300, iy, 30, 30)
        && this.cc.stats[key] > -1) {
        this.cc.stats[key]--;
        this.cursor = i;
        return;
      }
      // [+]
      if (this.hitTest(x, y, 400, iy, 30, 30)
        && this.cc.stats[key] < 3) {
        this.cc.stats[key]++;
        this.cursor = i;
        return;
      }
    }
  }

  handleWeaponClick(x, y) {
    const w = this.cc.weapon;
    // Name input
    if (this.hitTest(x, y, 240, 41, 280, 20)) {
      this.focusedField = 'weapon';
      return;
    }
    // Type
    if (this.hitTest(x, y, 100, 67, 70, 22)) {
      if (w.type !== 'melee') {
        w.type = 'melee';
        w.form = 'medium';
        w.hand = 'off_1h';
        // Remove melee-only effects that no longer
        // fit, and trim to budget
        this.pruneWeaponEffects(w);
      }
      this.focusedField = null;
      return;
    }
    if (this.hitTest(x, y, 180, 67, 70, 22)) {
      if (w.type !== 'ranged') {
        w.type = 'ranged';
        w.form = 'high_caliber';
        w.hand = 'off_1h';
        this.pruneWeaponEffects(w);
      }
      this.focusedField = null;
      return;
    }
    // DMG type
    if (w.type === 'melee') {
      for (let i = 0; i < 3; i++) {
        if (this.hitTest(x, y, 100 + i * 80,
          95 - 12, 70, 22)) {
          w.dmgType = DMG_TYPES[i].key;
          this.focusedField = null;
          return;
        }
      }
    }
    // Forms
    let fy = w.type === 'melee' ? 129 : 101;
    const forms = w.type === 'melee'
      ? MELEE_FORMS : RANGED_FORMS;
    for (let i = 0; i < forms.length; i++) {
      const bx = 40 + (i % 3) * 170;
      const by = fy + Math.floor(i / 3) * 46;
      if (this.hitTest(x, y, bx, by,
        160, 18)) {
        w.form = forms[i].key;
        this.pruneWeaponEffects(w);
        this.focusedField = null;
        return;
      }
    }
    // Hands
    let hy = fy + Math.ceil(
      forms.length / 3) * 46 + 20;
    const hands = w.type === 'melee'
      ? MELEE_HANDS : RANGED_HANDS;
    for (let i = 0; i < hands.length; i++) {
      const bx = 40 + (i % 2) * 260;
      const by = hy + Math.floor(i / 2) * 46;
      if (this.hitTest(x, y, bx, by,
        250, 18)) {
        w.hand = hands[i].key;
        this.pruneWeaponEffects(w);
        this.focusedField = null;
        return;
      }
    }
    // Add Effect button
    if (this._effectsY
      && this.hitTest(x, y, 40,
        this._effectsY + 4, 120, 22)) {
      this.focusedField = null;
      this.openEffectPicker(
        'weapon', w.effects,
        WEAPON_EFFECTS, calcWeaponEP(w)
      );
      return;
    }
    // Remove effect buttons
    this.handleEffectRemoveClick(
      x, y, w.effects, WEAPON_EFFECTS
    );
    this.focusedField = null;
  }

  pruneWeaponEffects(w) {
    // Remove effects with restrictions
    // that don't match current type
    for (let i = w.effects.length - 1;
      i >= 0; i--) {
      const def = WEAPON_EFFECTS[w.effects[i].key];
      if (!def) continue;
      if (def.restrictions) {
        if (def.restrictions.indexOf(w.type)
          === -1) {
          w.effects.splice(i, 1);
        }
      }
    }
    // Trim remaining effects to fit budget
    trimEffectsToFit(w.effects, WEAPON_EFFECTS,
      calcWeaponEP(w));
  }

  handleOutfitClick(x, y) {
    const o = this.cc.outfit;
    // Name input
    if (this.hitTest(x, y, 240, 41, 280, 20)) {
      this.focusedField = 'outfit';
      return;
    }
    // Property
    for (let i = 0;
      i < OUTFIT_PROPS.length; i++) {
      if (this.hitTest(x, y,
        40 + i * 170, 85, 160, 18)) {
        o.property = OUTFIT_PROPS[i].key;
        // Trim effects if balanced removed
        trimEffectsToFit(o.effects,
          OUTFIT_EFFECTS, calcOutfitEP(o));
        this.focusedField = null;
        return;
      }
    }
    // Resistance buttons (shifted down 22px
    // to accommodate trading rules hint)
    const resistKeys = ['slash', 'pierce',
      'blunt'];
    const baseY = 197;
    for (let i = 0; i < 3; i++) {
      const ry = baseY + i * 34;
      // HP resist < >
      const hpKey = resistKeys[i] + '_hp';
      if (this.hitTest(x, y, 180, ry, 20, 22)) {
        this.cycleResist(o.resistances,
          hpKey, -1);
        this.focusedField = null;
        return;
      }
      if (this.hitTest(x, y, 310, ry, 20, 22)) {
        this.cycleResist(o.resistances,
          hpKey, 1);
        this.focusedField = null;
        return;
      }
      // ST resist < >
      const stKey = resistKeys[i] + '_st';
      if (this.hitTest(x, y, 340, ry, 20, 22)) {
        this.cycleResist(o.resistances,
          stKey, -1);
        this.focusedField = null;
        return;
      }
      if (this.hitTest(x, y, 470, ry, 20, 22)) {
        this.cycleResist(o.resistances,
          stKey, 1);
        this.focusedField = null;
        return;
      }
    }
    // Add Effect
    if (this._effectsY
      && this.hitTest(x, y, 40,
        this._effectsY + 4, 120, 22)) {
      this.openEffectPicker(
        'outfit', o.effects,
        OUTFIT_EFFECTS, calcOutfitEP(o)
      );
      return;
    }
    this.handleEffectRemoveClick(
      x, y, o.effects, OUTFIT_EFFECTS
    );
  }

  handleAugmentClick(x, y) {
    const a = this.cc.augment;
    // Toggle
    if (this.hitTest(x, y, 40, 79, 150, 24)) {
      a.enabled = !a.enabled;
      if (!a.enabled) a.effects = [];
      return;
    }
    if (a.enabled) {
      if (this._effectsY
        && this.hitTest(x, y, 40,
          this._effectsY + 4, 120, 22)) {
        this.openEffectPicker(
          'augment', a.effects,
          AUGMENT_EFFECTS, 4
        );
        return;
      }
      this.handleEffectRemoveClick(
        x, y, a.effects, AUGMENT_EFFECTS
      );
    }
  }

  handleSkillsClick(x, y) {
    // Tab buttons
    for (let i = 0; i < 2; i++) {
      if (this.hitTest(x, y,
        40 + i * 260, 79, 120, 22)) {
        this.skillTab = i;
        this.focusedField = null;
        return;
      }
    }
    const skill = this.cc.skills[this.skillTab];
    const skillField = 'skill'
      + this.skillTab;
    // Name input (new row)
    if (this.hitTest(x, y, 100, 99, 280, 20)) {
      this.focusedField = skillField;
      return;
    }
    // Type (shifted down 28px)
    for (let i = 0;
      i < SKILL_TYPES.length; i++) {
      if (this.hitTest(x, y,
        100 + i * 90, 129, 80, 22)) {
        skill.type = SKILL_TYPES[i].key;
        this.focusedField = null;
        return;
      }
    }
    // Light cost -/+
    if (this.hitTest(x, y, 140, 145, 24, 22)
      && skill.lightCost > 1) {
      skill.lightCost--;
      trimEffectsToFit(skill.effects,
        SKILL_EFFECTS,
        4 + ((skill.lightCost - 1) * 1));
      this.focusedField = null;
      return;
    }
    if (this.hitTest(x, y, 196, 145, 24, 22)
      && skill.lightCost < 4) {
      skill.lightCost++;
      this.focusedField = null;
      return;
    }
    // Add Effect
    if (this._effectsY
      && this.hitTest(x, y, 40,
        this._effectsY + 4, 120, 22)) {
      const budget = 4
        + ((skill.lightCost - 1) * 1);
      this.focusedField = null;
      this.openEffectPicker(
        'skill', skill.effects,
        SKILL_EFFECTS, budget
      );
      return;
    }
    this.handleEffectRemoveClick(
      x, y, skill.effects, SKILL_EFFECTS
    );
    this.focusedField = null;
  }

  handleReviewClick(x, y) {
    // Char name input at (220, 46, 180, 20)
    if (this.hitTest(x, y, 220, 46, 180, 20)) {
      this.focusedField = 'char';
      return;
    }
    this.focusedField = null;
  }

  // ========== EFFECT PICKER HELPERS ==========
  openEffectPicker(cat, effects, table,
    budget) {
    const spent = calcEPSpent(effects, table);
    this.effectPicker = {
      category: cat,
      effects: effects,
      table: table,
      budget: budget,
      spent: spent,
      // configuring = null means list view;
      // else contains config draft
      configuring: null,
    };
    this.effectSearch = '';
    this.scroll = 0;
  }

  startConfiguring(key) {
    const ep = this.effectPicker;
    if (!ep) return;
    const def = ep.table[key];
    if (!def) return;
    ep.configuring = {
      key: key,
      amount: 1,
      negative: false,
      proc: def.needsResultSel
        ? 'clash_win' : null,
      typeSel: def.needsTypeSel
        ? 'attack' : null,
    };
  }

  confirmConfiguring() {
    const ep = this.effectPicker;
    if (!ep || !ep.configuring) return;
    const cfg = ep.configuring;
    const def = ep.table[cfg.key];
    if (!def) return;
    // Check budget
    const ok = canAddEffect(
      ep.effects, ep.table, ep.budget,
      def, cfg.amount, cfg.negative
    );
    if (!ok) {
      this.act('sfx', { s: 'error' });
      return;
    }
    ep.effects.push({
      key: cfg.key,
      amount: cfg.amount,
      negative: cfg.negative,
      proc: cfg.proc,
      typeSel: cfg.typeSel,
    });
    ep.spent = calcEPSpent(
      ep.effects, ep.table);
    ep.configuring = null;
    this.act('sfx', { s: 'click' });
  }

  handleEffectPickerClick(x, y) {
    const ep = this.effectPicker;
    if (!ep) return;
    const px = 60;
    const py = 60;
    const pw = 500;
    const ph = 440;
    // Close button (shared)
    if (this.hitTest(x, y, px + pw - 30,
      py + 6, 22, 22)) {
      if (ep.configuring) {
        ep.configuring = null;
      } else {
        this.effectPicker = null;
        this.effectSearch = '';
      }
      return;
    }
    // Click outside panel closes
    if (x < px || x > px + pw
      || y < py || y > py + ph) {
      this.effectPicker = null;
      this.effectSearch = '';
      return;
    }
    if (ep.configuring) {
      this.handlePickerConfigClick(
        x, y, px, py, pw, ph);
      return;
    }
    // List view: Config buttons
    const table = ep.table;
    const keys = Object.keys(table);
    const filtered = keys.filter(k => {
      const def = table[k];
      if (this.effectSearch
        && def.name.toLowerCase().indexOf(
          this.effectSearch.toLowerCase()
        ) === -1) {
        return false;
      }
      return true;
    });
    const listY = py + 60;
    const rowH = 52;
    const visible = Math.floor(
      (ph - 80) / rowH
    );
    for (let i = 0;
      i < visible
        && i + this.scroll
          < filtered.length; i++) {
      const key = filtered[i + this.scroll];
      const ry = listY + i * rowH;
      // Config button
      if (this.hitTest(x, y, px + pw - 70,
        ry + 4, 50, 18)) {
        this.startConfiguring(key);
        this.act('sfx', { s: 'click' });
        return;
      }
    }
  }

  handlePickerConfigClick(x, y,
    px, py, pw, ph) {
    const ep = this.effectPicker;
    const cfg = ep.configuring;
    const def = ep.table[cfg.key];
    if (!def) return;
    let yc = py + 140;
    // Amount spinner
    if (!def.flat) {
      if (this.hitTest(x, y, px + 90,
        yc - 14, 24, 22)
        && cfg.amount > 1) {
        cfg.amount--;
        return;
      }
      if (this.hitTest(x, y, px + 146,
        yc - 14, 24, 22)
        && cfg.amount < def.maxAmt) {
        cfg.amount++;
        return;
      }
      yc += 36;
    }
    // Positive/Negative
    if (def.canNeg) {
      if (this.hitTest(x, y, px + 90,
        yc - 14, 90, 22)) {
        cfg.negative = false;
        return;
      }
      if (this.hitTest(x, y, px + 190,
        yc - 14, 90, 22)) {
        cfg.negative = true;
        return;
      }
      yc += 36;
    }
    // CW/CL
    if (def.needsResultSel) {
      if (this.hitTest(x, y, px + 90,
        yc - 14, 100, 22)) {
        cfg.proc = 'clash_win';
        return;
      }
      if (this.hitTest(x, y, px + 200,
        yc - 14, 100, 22)) {
        cfg.proc = 'clash_lose';
        return;
      }
      yc += 36;
    }
    // Atk/Def
    if (def.needsTypeSel) {
      if (this.hitTest(x, y, px + 90,
        yc - 14, 90, 22)) {
        cfg.typeSel = 'attack';
        return;
      }
      if (this.hitTest(x, y, px + 190,
        yc - 14, 90, 22)) {
        cfg.typeSel = 'defense';
        return;
      }
      yc += 36;
    }
    // Confirm button
    if (this.hitTest(x, y,
      px + pw - 170, py + ph - 40, 80, 28)) {
      this.confirmConfiguring();
      return;
    }
    // Back button
    if (this.hitTest(x, y,
      px + pw - 80, py + ph - 40, 60, 28)) {
      ep.configuring = null;
      return;
    }
  }

  handleEffectRemoveClick(x, y, effects,
    table) {
    // Check remove buttons (X at x=430)
    // Effects start rendering from a base y
    // that depends on the step. We use the
    // stored _effectsY minus the effect list.
    // Each effect row is 22px, starting from
    // the EP bar area.
    if (!this._effectsY) return;
    const baseY = this._effectsY - 26
      - effects.length * 22;
    for (let i = 0; i < effects.length; i++) {
      const ey = baseY + 26 + i * 22;
      if (this.hitTest(x, y, 430, ey, 20, 18)) {
        effects.splice(i, 1);
        return;
      }
    }
  }

  cycleResist(resists, key, dir) {
    const levels = ['fatal', 'weak', 'normal',
      'endured'];
    const cur = levels.indexOf(resists[key]);
    const next = cur + dir;
    if (next >= 0 && next < levels.length) {
      resists[key] = levels[next];
    }
  }

  typeIntoField(ch) {
    // ch === '' means backspace
    const field = this.focusedField;
    const maxLen = 24;
    let cur = '';
    if (field === 'weapon') {
      cur = this.cc.weapon.name || '';
    } else if (field === 'outfit') {
      cur = this.cc.outfit.name || '';
    } else if (field === 'skill0') {
      cur = this.cc.skills[0].name || '';
    } else if (field === 'skill1') {
      cur = this.cc.skills[1].name || '';
    } else if (field === 'char') {
      cur = this.cc.charName || '';
    } else {
      return;
    }
    let next;
    if (ch === '') {
      next = cur.slice(0, -1);
    } else if (cur.length >= maxLen) {
      return;
    } else {
      next = cur + ch;
    }
    if (field === 'weapon') {
      this.cc.weapon.name = next;
    } else if (field === 'outfit') {
      this.cc.outfit.name = next;
    } else if (field === 'skill0') {
      this.cc.skills[0].name = next;
    } else if (field === 'skill1') {
      this.cc.skills[1].name = next;
    } else if (field === 'char') {
      this.cc.charName = next;
    }
  }

  // ========== SUBMIT CHARACTER ==========
  submitCharacter() {
    const cc = this.cc;
    const mapEffect = e => ({
      key: e.key,
      amount: e.amount,
      negative: !!e.negative,
      proc: e.proc || null,
      type_sel: e.typeSel || null,
    });
    const payload = {
      name: cc.charName,
      stats: { ...cc.stats },
      weapon: {
        name: cc.weapon.name || '',
        type: cc.weapon.type,
        dmg_type: cc.weapon.dmgType,
        form: cc.weapon.form,
        hand: cc.weapon.hand,
        effects: cc.weapon.effects.map(mapEffect),
      },
      outfit: {
        name: cc.outfit.name || '',
        property: cc.outfit.property,
        resistances: { ...cc.outfit.resistances },
        effects: cc.outfit.effects.map(mapEffect),
      },
      augment: cc.augment.enabled
        ? {
          effects: cc.augment.effects.map(
            mapEffect),
        }
        : null,
      skills: cc.skills.map(s => ({
        name: s.name || '',
        type: s.type,
        light_cost: s.lightCost,
        effects: s.effects.map(mapEffect),
      })),
    };
    this.act('create_character', {
      data: JSON.stringify(payload),
    });
    this.state = GS_CREATED;
    this.act('sfx', { s: 'confirm' });
  }

  // ========== HIT TEST ==========
  hitTest(mx, my, x, y, w, h) {
    return mx >= x && mx <= x + w
      && my >= y && my <= y + h;
  }

  handleHover(x, y) {
    this.mx = x;
    this.my = y;
    if (this.state === GS_COMBAT) {
      this.handleCombatHover(x, y);
    }
  }

  // ========== COMBAT: INIT ==========
  startDebugCombat() {
    const cc = buildTestCharacter();
    this.cc = cc;
    const d = calcDerived(cc.stats, 1);
    const player = {
      id: 'player',
      name: cc.charName || 'You',
      isPlayer: true,
      hp: d.hp, hpMax: d.hp,
      st: d.st, stMax: d.st,
      sp: d.sp, spMax: d.sp,
      light: d.light, lightMax: d.light,
      actions: d.actions,
      reactions: d.reactions,
      move: d.movement,
      actionsLeft: d.actions,
      reactionsLeft: d.reactions,
      moveLeft: d.movement,
      x: 2, y: 5,
      staggered: false,
      staggerTurns: 0,
      recycledEvades: 0,
      tempHp: 0,
      activeSkillIdx: -1,
      statuses: initStatusBlock(),
      queuedStatuses: initStatusBlock(),
      weapon: cc.weapon,
      outfit: cc.outfit,
      augment: cc.augment,
      skills: cc.skills,
      stats: cc.stats,
      speed: this.rollDice(1, 6)
        + cc.stats.justice,
    };
    const enemy = buildTestEnemy();
    enemy.speed = this.rollDice(1, 6) + 2;
    const arena = buildTestArena();
    this.combat = {
      round: 1,
      turnIdx: 0,
      turnOrder: [],
      phase: CP_IDLE,
      combatants: {
        player: player,
        enemy_0: enemy,
      },
      grid: arena,
      selectedAction: null,
      hoveredTile: null,
      moveRange: null,
      atkRange: null,
      movePath: [],
      anim: null,
      log: [],
      pendingAttack: null,
      lastRoll: null,
      lastDamage: null,
      hoveredCombatant: null,
      inspectedId: 'player',
      pendingSkillChoice: null,
    };
    // Sort turn order by speed desc
    const ids = Object.keys(
      this.combat.combatants);
    this.combat.turnOrder = ids.sort((a, b) =>
      this.combat.combatants[b].speed
        - this.combat.combatants[a].speed);
    this.combat.turnIdx = 0;
    this.combatLog('Combat begins!');
    this.combatLog('Turn order: '
      + this.combat.turnOrder.map(
        id => this.combat.combatants[id].name
          + ' (' + this.combat.combatants[id]
            .speed + ')').join(', '));
    this.state = GS_COMBAT;
    this.act('sfx', { s: 'click' });
    // Apply combat-start effects before
    // the first turn begins
    this.processCombatStart();
    // Start the first turn (may trigger AI)
    this.startTurn();
  }

  resetDebugCombat() {
    this.combat = null;
    this.combatAnimQueue = [];
    this.startDebugCombat();
  }

  combatLog(msg) {
    if (!this.combat) return;
    this.combat.log.push(msg);
    if (this.combat.log.length > 40) {
      this.combat.log.shift();
    }
  }

  // ========== COMBAT: HELPERS ==========
  rollDice(num, max) {
    let total = 0;
    for (let i = 0; i < num; i++) {
      total += Math.floor(
        Math.random() * max) + 1;
    }
    return total;
  }

  distance(a, b) {
    // Chebyshev (8-directional)
    return Math.max(
      Math.abs(a.x - b.x),
      Math.abs(a.y - b.y));
  }

  isInMeleeRange(attacker, target) {
    return this.distance(
      attacker, target) <= 1;
  }

  getTileAt(x, y) {
    const g = this.combat.grid;
    if (x < 0 || x >= g.w
      || y < 0 || y >= g.h) {
      return -1;
    }
    return g.tiles[y * g.w + x];
  }

  isBlocked(x, y) {
    if (this.getTileAt(x, y) !== 0) return true;
    // Combatants block
    const c = this.combat.combatants;
    const keys = Object.keys(c);
    for (let i = 0; i < keys.length; i++) {
      const cm = c[keys[i]];
      if (cm.hp <= 0) continue;
      if (cm.x === x && cm.y === y) return true;
    }
    return false;
  }

  tilesInRange(sx, sy, range) {
    // BFS ignoring combatant block for start
    const g = this.combat.grid;
    const visited = {};
    const dist = {};
    visited[sx + ',' + sy] = true;
    dist[sx + ',' + sy] = 0;
    const q = [{ x: sx, y: sy, d: 0 }];
    while (q.length) {
      const cur = q.shift();
      if (cur.d >= range) continue;
      const dirs = [[1, 0], [-1, 0],
        [0, 1], [0, -1]];
      for (let i = 0; i < dirs.length; i++) {
        const nx = cur.x + dirs[i][0];
        const ny = cur.y + dirs[i][1];
        const key = nx + ',' + ny;
        if (visited[key]) continue;
        if (nx < 0 || nx >= g.w
          || ny < 0 || ny >= g.h) continue;
        // Walls block
        if (g.tiles[ny * g.w + nx] !== 0) {
          continue;
        }
        // Combatants block except start
        const c = this.combat.combatants;
        let blocked = false;
        const ckeys = Object.keys(c);
        for (let j = 0;
          j < ckeys.length; j++) {
          const cm = c[ckeys[j]];
          if (cm.hp <= 0) continue;
          if (cm.x === nx && cm.y === ny) {
            blocked = true;
            break;
          }
        }
        if (blocked) continue;
        visited[key] = true;
        dist[key] = cur.d + 1;
        q.push({ x: nx, y: ny, d: cur.d + 1 });
      }
    }
    return { visited, dist };
  }

  pathTo(sx, sy, tx, ty) {
    const g = this.combat.grid;
    const visited = {};
    const parent = {};
    visited[sx + ',' + sy] = true;
    const q = [{ x: sx, y: sy }];
    while (q.length) {
      const cur = q.shift();
      if (cur.x === tx && cur.y === ty) break;
      const dirs = [[1, 0], [-1, 0],
        [0, 1], [0, -1]];
      for (let i = 0; i < dirs.length; i++) {
        const nx = cur.x + dirs[i][0];
        const ny = cur.y + dirs[i][1];
        const key = nx + ',' + ny;
        if (visited[key]) continue;
        if (nx < 0 || nx >= g.w
          || ny < 0 || ny >= g.h) continue;
        if (g.tiles[ny * g.w + nx] !== 0) {
          continue;
        }
        // Block on combatants except target
        const c = this.combat.combatants;
        let blocked = false;
        const ckeys = Object.keys(c);
        for (let j = 0;
          j < ckeys.length; j++) {
          const cm = c[ckeys[j]];
          if (cm.hp <= 0) continue;
          if (cm.x === nx && cm.y === ny
            && !(nx === tx && ny === ty)) {
            blocked = true;
            break;
          }
        }
        if (blocked) continue;
        visited[key] = true;
        parent[key] = {
          x: cur.x, y: cur.y };
        q.push({ x: nx, y: ny });
      }
    }
    // Reconstruct
    const path = [];
    let cx = tx;
    let cy = ty;
    if (!visited[cx + ',' + cy]) return null;
    while (!(cx === sx && cy === sy)) {
      path.unshift({ x: cx, y: cy });
      const p = parent[cx + ',' + cy];
      if (!p) return null;
      cx = p.x;
      cy = p.y;
    }
    return path;
  }

  // Base dice before any modifiers
  getBaseAtkDice(c) {
    if (c.isPlayer) {
      // Base 1d10, no effects applied yet
      return { num: 1, max: 10, pow: 0 };
    }
    return {
      num: c.atkDice.num,
      max: c.atkDice.max,
      pow: c.atkDice.pow,
    };
  }

  getBaseBlockDice(c) {
    if (c.isPlayer) {
      return { num: 1, max: 10, pow: 0 };
    }
    return {
      num: c.blockDice.num,
      max: c.blockDice.max,
      pow: c.blockDice.pow,
    };
  }

  getBaseEvadeDice(c) {
    if (c.isPlayer) {
      return { num: 1, max: 12, pow: 0 };
    }
    return {
      num: c.evadeDice.num,
      max: c.evadeDice.max,
      pow: c.evadeDice.pow,
    };
  }

  // Full dice with all modifiers applied
  calcAtkDiceFor(c, target, skill) {
    const dice = this.getBaseAtkDice(c);
    if (c.isPlayer) {
      // Weapon form bonuses
      if (c.weapon.form === 'medium'
        || c.weapon.form === 'high_caliber') {
        dice.max += 2;
      }
      // Hand bonuses
      if (c.weapon.hand === 'off_1h') {
        dice.pow += 1;
      }
      if (c.weapon.hand === 'off_2h') {
        dice.pow += 2;
      }
      // Rank attack mod (Rank 1)
      dice.pow += 1;
      // Apply weapon always-active effects
      const ctx = {
        self: c, target: target, dice: dice,
        isOffensive: true,
        opponentDice: null,
      };
      this.procAlwaysActive(
        c.weapon.effects || [],
        WEAPON_EFFECTS, ctx);
      // Apply skill always-active effects
      if (skill) {
        this.procAlwaysActive(
          skill.effects || [],
          SKILL_EFFECTS, ctx);
      }
      // Apply augment condition effects
      if (c.augment && c.augment.enabled) {
        this.procOnCondition(
          c.augment.effects || [],
          AUGMENT_EFFECTS, ctx);
      }
    }
    // Status modifiers
    dice.pow += (c.statuses.strength || 0);
    dice.pow -= (c.statuses.feeble || 0);
    // Clamp
    if (dice.max < 1) {
      dice.pow -= (1 - dice.max);
      dice.max = 1;
    }
    return dice;
  }

  calcBlockDiceFor(c, skill) {
    const dice = this.getBaseBlockDice(c);
    if (c.isPlayer) {
      dice.pow += c.stats.temperance;
      const ctx = {
        self: c, target: null, dice: dice,
        isOffensive: false,
        opponentDice: null,
      };
      this.procAlwaysActive(
        c.outfit.effects || [],
        OUTFIT_EFFECTS, ctx);
      if (skill) {
        this.procAlwaysActive(
          skill.effects || [],
          SKILL_EFFECTS, ctx);
      }
      if (c.augment && c.augment.enabled) {
        this.procOnCondition(
          c.augment.effects || [],
          AUGMENT_EFFECTS, ctx);
      }
      if (c.outfit.property === 'armored') {
        dice.pow += 1;
      }
    }
    dice.pow += (c.statuses.endurance || 0);
    dice.pow -= (c.statuses.disarm || 0);
    if (dice.max < 1) {
      dice.pow -= (1 - dice.max);
      dice.max = 1;
    }
    return dice;
  }

  calcEvadeDiceFor(c, skill) {
    const dice = this.getBaseEvadeDice(c);
    if (c.isPlayer) {
      dice.pow += c.stats.insight;
      const ctx = {
        self: c, target: null, dice: dice,
        isOffensive: false,
        opponentDice: null,
      };
      this.procAlwaysActive(
        c.outfit.effects || [],
        OUTFIT_EFFECTS, ctx);
      if (skill) {
        this.procAlwaysActive(
          skill.effects || [],
          SKILL_EFFECTS, ctx);
      }
      if (c.augment && c.augment.enabled) {
        this.procOnCondition(
          c.augment.effects || [],
          AUGMENT_EFFECTS, ctx);
      }
      if (c.outfit.property === 'swift') {
        dice.pow += 1;
      }
    }
    dice.pow += (c.statuses.endurance || 0);
    dice.pow -= (c.statuses.disarm || 0);
    if (c.recycledEvades > 0) {
      dice.pow -= (c.recycledEvades * 2);
    }
    if (dice.max < 1) {
      dice.pow -= (1 - dice.max);
      dice.max = 1;
    }
    return dice;
  }

  // Legacy wrappers used by action-bar hover
  // display and reaction modal preview
  getEffectiveAtkDice(c) {
    return this.calcAtkDiceFor(c, null, null);
  }
  getEffectiveBlockDice(c) {
    return this.calcBlockDiceFor(c, null);
  }
  getEffectiveEvadeDice(c) {
    return this.calcEvadeDiceFor(c, null);
  }

  // ========== EFFECT PROC DISPATCHERS ==========
  procAlwaysActive(effects, table, ctx) {
    for (let i = 0; i < effects.length; i++) {
      const eff = effects[i];
      const h = EFFECT_HANDLERS[eff.key];
      if (!h || !h.onDice) continue;
      h.onDice(ctx, eff);
    }
  }

  procOnClash(effects, table, ctx) {
    for (let i = 0; i < effects.length; i++) {
      const eff = effects[i];
      const h = EFFECT_HANDLERS[eff.key];
      if (!h || !h.onClash) continue;
      h.onClash(ctx, eff);
    }
  }

  procOnCondition(effects, table, ctx) {
    for (let i = 0; i < effects.length; i++) {
      const eff = effects[i];
      const h = EFFECT_HANDLERS[eff.key];
      if (!h || !h.onCondition) continue;
      h.onCondition(ctx, eff);
    }
  }

  procOnClashResult(effects, table,
    ctx, result) {
    for (let i = 0; i < effects.length; i++) {
      const eff = effects[i];
      const h = EFFECT_HANDLERS[eff.key];
      if (!h || !h.onClashResult) continue;
      h.onClashResult(ctx, eff, result);
    }
  }

  procCombatStart(effects, table, ctx) {
    for (let i = 0; i < effects.length; i++) {
      const eff = effects[i];
      const h = EFFECT_HANDLERS[eff.key];
      if (!h || !h.onCombatStart) continue;
      h.onCombatStart(ctx, eff);
    }
  }

  procRoundStart(effects, table, ctx) {
    for (let i = 0; i < effects.length; i++) {
      const eff = effects[i];
      const h = EFFECT_HANDLERS[eff.key];
      if (!h || !h.onRoundStart) continue;
      h.onRoundStart(ctx, eff);
    }
  }

  // Run all combat-start effects for
  // all combatants
  processCombatStart() {
    const c = this.combat;
    const ids = Object.keys(c.combatants);
    for (let i = 0; i < ids.length; i++) {
      const cm = c.combatants[ids[i]];
      if (!cm.isPlayer) continue;
      const ctx = { self: cm };
      if (cm.weapon) {
        this.procCombatStart(
          cm.weapon.effects || [],
          WEAPON_EFFECTS, ctx);
      }
      if (cm.outfit) {
        this.procCombatStart(
          cm.outfit.effects || [],
          OUTFIT_EFFECTS, ctx);
      }
      if (cm.augment && cm.augment.enabled) {
        this.procCombatStart(
          cm.augment.effects || [],
          AUGMENT_EFFECTS, ctx);
      }
    }
    this.combatLog('Combat start effects'
      + ' applied.');
  }

  // Run round-start effects for a combatant
  processRoundStartFor(cm) {
    if (!cm.isPlayer) return;
    const ctx = { self: cm };
    if (cm.weapon) {
      this.procRoundStart(
        cm.weapon.effects || [],
        WEAPON_EFFECTS, ctx);
    }
    if (cm.outfit) {
      this.procRoundStart(
        cm.outfit.effects || [],
        OUTFIT_EFFECTS, ctx);
    }
    if (cm.augment && cm.augment.enabled) {
      this.procRoundStart(
        cm.augment.effects || [],
        AUGMENT_EFFECTS, ctx);
    }
  }

  // Run clash-result effects (win or lose)
  // for a combatant. ctx has self, target,
  // wasAttacking. Applied to weapon, skill,
  // augment and outfit.
  applyClashResultEffects(ctx, result, skill) {
    const c = ctx.self;
    if (!c.isPlayer) return;
    if (c.weapon) {
      this.procOnClashResult(
        c.weapon.effects || [],
        WEAPON_EFFECTS, ctx, result);
    }
    if (c.outfit) {
      this.procOnClashResult(
        c.outfit.effects || [],
        OUTFIT_EFFECTS, ctx, result);
    }
    if (c.augment && c.augment.enabled) {
      this.procOnClashResult(
        c.augment.effects || [],
        AUGMENT_EFFECTS, ctx, result);
    }
    if (skill) {
      this.procOnClashResult(
        skill.effects || [],
        SKILL_EFFECTS, ctx, result);
    }
  }

  // Apply On Clash effects (Enemy Power Down)
  applyOnClashEffects(c, ownDice,
    opponentDice, skill) {
    if (!c.isPlayer) return;
    const ctx = {
      self: c, target: null,
      dice: ownDice,
      opponentDice: opponentDice,
    };
    if (c.weapon) {
      this.procOnClash(
        c.weapon.effects || [],
        WEAPON_EFFECTS, ctx);
    }
    if (skill) {
      this.procOnClash(
        skill.effects || [],
        SKILL_EFFECTS, ctx);
    }
  }

  getAttackRange(c) {
    // Melee = 1, Long melee = 2, Ranged = 10
    if (c.isPlayer) {
      if (c.weapon.type === 'ranged') return 10;
      if (c.weapon.form === 'long') return 2;
      return 1;
    }
    return 1;
  }

  getDmgType(c) {
    if (c.isPlayer) return c.weapon.dmgType;
    return c.dmgType;
  }

  // ========== COMBAT: TURN CYCLE ==========
  startTurn() {
    const c = this.combat;
    const id = c.turnOrder[c.turnIdx];
    const me = c.combatants[id];
    if (me.hp <= 0) {
      this.endTurn();
      return;
    }
    // Stagger check BEFORE refreshing economy
    // so a staggered combatant cannot act OR
    // react on their turn.
    if (me.staggered) {
      if (me.staggerTurns > 0) {
        me.staggerTurns--;
        me.actionsLeft = 0;
        me.reactionsLeft = 0;
        me.moveLeft = 0;
        me.recycledEvades = 0;
        this.combatLog(me.name
          + ' is staggered, skips turn.');
        this.queueDelay(0.4, () => {
          this.endTurn();
        });
        return;
      }
      // Stagger timer elapsed: recover
      me.staggered = false;
      me.st = me.stMax + 10;
      this.combatLog(me.name
        + ' recovers from stagger.');
    }
    // Normal turn: refresh action economy
    me.actionsLeft = me.actions;
    me.reactionsLeft = me.reactions;
    me.moveLeft = me.move;
    me.recycledEvades = 0;
    me.activeSkillIdx = -1;
    // Apply movement status modifiers
    me.moveLeft += (me.statuses.haste || 0);
    me.moveLeft -= (me.statuses.bind || 0);
    me.moveLeft = Math.max(0, me.moveLeft);
    // Round-start effect procs (e.g.
    // Activate Strength)
    this.processRoundStartFor(me);
    c.phase = CP_IDLE;
    c.selectedAction = null;
    c.moveRange = null;
    c.atkRange = null;
    c.movePath = [];
    this.combatLog('--- '
      + me.name + '\'s turn ---');
    if (!me.isPlayer) {
      // Enemy AI runs after a short delay
      this.queueDelay(0.4, () => {
        this.runEnemyTurn(me);
      });
    }
  }

  endTurn() {
    const c = this.combat;
    // Check victory/defeat
    if (this.combat.combatants.player.hp <= 0) {
      this.state = GS_COMBAT_DEFEAT;
      return;
    }
    let anyEnemyAlive = false;
    const keys = Object.keys(c.combatants);
    for (let i = 0; i < keys.length; i++) {
      const cm = c.combatants[keys[i]];
      if (!cm.isPlayer && cm.hp > 0) {
        anyEnemyAlive = true;
      }
    }
    if (!anyEnemyAlive) {
      this.state = GS_COMBAT_VICTORY;
      return;
    }
    c.turnIdx++;
    if (c.turnIdx >= c.turnOrder.length) {
      // End of round: process ticks
      this.processRoundEnd();
      // Check victory/defeat again after
      // round end processing
      if (this.combat.combatants.player.hp
        <= 0) {
        this.state = GS_COMBAT_DEFEAT;
        return;
      }
      let alive = false;
      const ks = Object.keys(c.combatants);
      for (let i = 0; i < ks.length; i++) {
        const cm = c.combatants[ks[i]];
        if (!cm.isPlayer && cm.hp > 0) {
          alive = true;
        }
      }
      if (!alive) {
        this.state = GS_COMBAT_VICTORY;
        return;
      }
      c.turnIdx = 0;
      c.round++;
      this.combatLog('=== Round '
        + c.round + ' ===');
    }
    this.startTurn();
  }

  queueDelay(seconds, cb) {
    this.combatAnimQueue.push({
      type: 'delay',
      t: 0,
      dur: seconds,
      cb: cb,
    });
  }

  queueMove(combatant, path) {
    this.combatAnimQueue.push({
      type: 'move',
      t: 0,
      dur: path.length * 0.15,
      combatant: combatant,
      path: path,
      stepIdx: 0,
    });
  }

  queueClash(atk, def, data) {
    this.combatAnimQueue.push({
      type: 'clash',
      t: 0,
      dur: 1.6,
      atk: atk,
      def: def,
      data: data,
    });
  }

  updateCombat(dt) {
    if (this.combatAnimQueue.length === 0) {
      if (this.combat
        && this.combat.phase === CP_ANIM) {
        this.combat.phase = CP_IDLE;
      }
      return;
    }
    if (this.combat) {
      this.combat.phase = CP_ANIM;
    }
    const a = this.combatAnimQueue[0];
    a.t += dt;
    if (a.type === 'move') {
      const progress = Math.min(1,
        a.t / a.dur);
      const totalSteps = a.path.length;
      const curStep = Math.floor(
        progress * totalSteps);
      if (curStep > a.stepIdx
        && curStep < totalSteps) {
        a.combatant.x = a.path[curStep].x;
        a.combatant.y = a.path[curStep].y;
        a.stepIdx = curStep;
      }
    }
    if (a.t >= a.dur) {
      if (a.type === 'move') {
        // Snap to final tile
        const last = a.path[a.path.length - 1];
        a.combatant.x = last.x;
        a.combatant.y = last.y;
      }
      this.combatAnimQueue.shift();
      if (a.cb) a.cb();
    }
  }

  // ========== COMBAT: DAMAGE ==========
  calcDamage(roll, dmgType, defender) {
    const resistMap = {
      fatal: 2.0, weak: 1.5, normal: 1.0,
      endured: 0.5, ineffective: 0.25,
      immune: 0.0,
    };
    const hpKey = dmgType + '_hp';
    const stKey = dmgType + '_st';
    let hpMult;
    let stMult;
    if (defender.isPlayer) {
      hpMult = resistMap[
        defender.outfit.resistances[hpKey]]
        || 1.0;
      stMult = resistMap[
        defender.outfit.resistances[stKey]]
        || 1.0;
    } else {
      hpMult = defender.resist[hpKey] || 1.0;
      stMult = defender.resist[stKey] || 1.0;
    }
    if (defender.staggered) {
      hpMult = 2.0;
      stMult = 2.0;
    }
    // Flat Damage Resistance from equipment
    const dmgResist = this.getDamageResistance(
      defender);
    // Status modifiers
    const prot = defender.statuses.protection
      || 0;
    const sProt
      = defender.statuses.stagger_protection
      || 0;
    const frag = defender.statuses.fragile
      || 0;
    const sFrag
      = defender.statuses.stagger_fragile
      || 0;
    let hp = Math.floor(roll * hpMult);
    let st = Math.floor(roll * stMult);
    hp = Math.max(0,
      hp + frag - prot - dmgResist);
    st = Math.max(0,
      st + sFrag - sProt - dmgResist);
    return { hp: hp, st: st };
  }

  // Sum all Damage Resistance flat reductions
  getDamageResistance(c) {
    let total = 0;
    if (c.isPlayer && c.outfit
      && c.outfit.effects) {
      for (let i = 0;
        i < c.outfit.effects.length; i++) {
        const e = c.outfit.effects[i];
        if (e.key === 'damage_resistance') {
          total += e.negative
            ? -e.amount : e.amount;
        }
      }
    }
    if (c.isPlayer && c.augment
      && c.augment.enabled
      && c.augment.effects) {
      for (let i = 0;
        i < c.augment.effects.length; i++) {
        const e = c.augment.effects[i];
        if (e.key === 'damage_resistance') {
          total += e.negative
            ? -e.amount : e.amount;
        }
      }
    }
    return total;
  }

  // Sum all Burn Resistance reductions
  getBurnResistance(c) {
    let total = 0;
    if (c.isPlayer && c.outfit
      && c.outfit.effects) {
      for (let i = 0;
        i < c.outfit.effects.length; i++) {
        const e = c.outfit.effects[i];
        if (e.key === 'burn_resistance') {
          total += e.negative
            ? -e.amount : e.amount;
        }
      }
    }
    return total;
  }

  // Sum all Bleed Resistance reductions
  getBleedResistance(c) {
    let total = 0;
    if (c.isPlayer && c.outfit
      && c.outfit.effects) {
      for (let i = 0;
        i < c.outfit.effects.length; i++) {
        const e = c.outfit.effects[i];
        if (e.key === 'bleed_resistance') {
          total += e.negative
            ? -e.amount : e.amount;
        }
      }
    }
    return total;
  }

  // Apply hp damage with temp HP absorption
  applyHpDamage(c, dmg) {
    if (dmg <= 0) return 0;
    let remaining = dmg;
    if (c.tempHp > 0) {
      const absorb = Math.min(
        c.tempHp, remaining);
      c.tempHp -= absorb;
      remaining -= absorb;
    }
    c.hp = Math.max(0, c.hp - remaining);
    return dmg;
  }

  checkStagger(target) {
    if (target.st <= 0 && !target.staggered) {
      target.staggered = true;
      target.st = 0;
      target.staggerTurns = 2;
      // Zero out remaining action economy so
      // the staggered combatant cannot react or
      // act for the rest of the current round.
      target.actionsLeft = 0;
      target.reactionsLeft = 0;
      target.moveLeft = 0;
      target.recycledEvades = 0;
      this.combatLog(target.name
        + ' is STAGGERED!');
    }
  }

  checkKO(target) {
    if (target.hp <= 0) {
      target.hp = 0;
      this.combatLog(target.name
        + ' is DEFEATED!');
      if (this.combat.inspectedId
        === target.id) {
        this.combat.inspectedId = 'player';
      }
    }
  }

  // ========== COMBAT: ATTACKS ==========
  resolveOneSidedAttack(atk, def) {
    const dice = this.getEffectiveAtkDice(atk);
    const roll = this.rollDice(
      dice.num, dice.max) + dice.pow;
    const dmgType = this.getDmgType(atk);
    const result = this.calcDamage(
      roll, dmgType, def);
    def.hp = Math.max(0, def.hp - result.hp);
    def.st = Math.max(0, def.st - result.st);
    this.combat.lastRoll = roll;
    this.combat.lastDamage = result;
    this.combatLog(atk.name + ' attacks '
      + def.name + ' for ' + roll
      + ' (' + result.hp + ' HP, '
      + result.st + ' ST)');
    this.checkStagger(def);
    this.checkKO(def);
    atk.actionsLeft--;
    this.queueClash(atk, def, {
      atkRoll: roll,
      defRoll: null,
      winner: 'attacker',
      reactType: 'none',
      result: result,
    });
  }

  resolveClash(atk, def, reactType,
    atkSkillIdx, defSkillIdx) {
    // Resolve skill objects if provided
    let atkSkill = null;
    let defSkill = null;
    if (atkSkillIdx !== undefined
      && atkSkillIdx !== null
      && atkSkillIdx >= 0
      && atk.skills) {
      atkSkill = atk.skills[atkSkillIdx];
    }
    if (defSkillIdx !== undefined
      && defSkillIdx !== null
      && defSkillIdx >= 0
      && def.skills) {
      defSkill = def.skills[defSkillIdx];
    }
    // Step 1: Bleed on action
    this.procActionBleed(atk, 'action');
    if (atk.hp <= 0) {
      this.checkKO(atk);
      return;
    }
    if (reactType !== 'takehit'
      && reactType !== 'none') {
      this.procActionBleed(def, 'reaction');
      if (def.hp <= 0) {
        this.checkKO(def);
        return;
      }
    }
    // Step 2: Calculate dice with modifiers
    const atkDice = this.calcAtkDiceFor(
      atk, def, atkSkill);
    let defDice = null;
    if (reactType === 'block') {
      defDice = this.calcBlockDiceFor(
        def, defSkill);
    } else if (reactType === 'counter') {
      defDice = this.calcAtkDiceFor(
        def, atk, defSkill);
    } else if (reactType === 'evade') {
      defDice = this.calcEvadeDiceFor(
        def, defSkill);
    }
    // Step 3: On Clash effects
    this.applyOnClashEffects(
      atk, atkDice, defDice, atkSkill);
    if (defDice) {
      this.applyOnClashEffects(
        def, defDice, atkDice, defSkill);
    }
    // Step 4: Roll
    const atkRoll = this.rollDice(
      atkDice.num, atkDice.max) + atkDice.pow;
    let defRoll = 0;
    if (reactType !== 'takehit'
      && reactType !== 'none'
      && defDice) {
      defRoll = this.rollDice(
        defDice.num, defDice.max)
        + defDice.pow;
    }
    // Step 5: Determine winner
    let winner;
    if (reactType === 'takehit'
      || reactType === 'none') {
      winner = 'attacker';
    } else if (atkRoll > defRoll) {
      winner = 'attacker';
    } else if (defRoll > atkRoll) {
      winner = 'defender';
    } else {
      // Tie: reroll once
      return this.resolveClash(atk, def,
        reactType, atkSkillIdx, defSkillIdx);
    }
    // Step 6: Apply clash-result effects
    const winCtx = {
      self: atk, target: def,
      wasAttacking: true,
    };
    const loseCtx = {
      self: def, target: atk,
      wasAttacking: false,
    };
    if (winner === 'attacker') {
      this.applyClashResultEffects(
        winCtx, 'clash_win', atkSkill);
      if (reactType !== 'takehit'
        && reactType !== 'none') {
        this.applyClashResultEffects(
          loseCtx, 'clash_lose', defSkill);
      }
    } else {
      this.applyClashResultEffects(
        winCtx, 'clash_lose', atkSkill);
      this.applyClashResultEffects(
        loseCtx, 'clash_win', defSkill);
    }
    // Step 7: Apply damage
    this.applyClashDamageV2(atk, def,
      reactType, atkRoll, defRoll, winner);
    // Step 8: Crit + Devastation
    if (winner === 'attacker') {
      this.checkCrit(atk, def);
      this.checkDevastation(atk, def);
    }
    // Step 9: Burst
    if (winner === 'attacker') {
      this.autoProcBurst(atk, def);
    }
    // Step 10: Pay skill Light costs
    if (atkSkill) {
      atk.light = Math.max(0,
        atk.light - atkSkill.lightCost);
      atk.activeSkillIdx = -1;
    }
    if (defSkill) {
      def.light = Math.max(0,
        def.light - defSkill.lightCost);
      def.activeSkillIdx = -1;
    }
    // Step 11: Decrement reactions
    if (reactType !== 'takehit'
      && reactType !== 'none') {
      def.reactionsLeft--;
    }
    // Step 12: Animation + KO
    this.combat.lastRoll = atkRoll;
    this.queueClash(atk, def, {
      atkRoll: atkRoll,
      defRoll: defRoll,
      winner: winner,
      reactType: reactType,
    });
    this.checkKO(def);
    this.checkKO(atk);
  }

  applyClashDamageV2(atk, def, reactType,
    atkRoll, defRoll, winner) {
    if (winner === 'attacker') {
      const type = this.getDmgType(atk);
      let effectiveRoll = atkRoll;
      if (reactType === 'block') {
        effectiveRoll = Math.max(0,
          atkRoll - defRoll);
      }
      const result = this.calcDamage(
        effectiveRoll, type, def);
      this.applyHpDamage(def, result.hp);
      def.st = Math.max(0, def.st - result.st);
      this.combat.lastDamage = result;
      this.combatLog(atk.name + ' hits '
        + def.name + ' for ' + effectiveRoll
        + ' (' + result.hp + ' HP / '
        + result.st + ' ST)');
      this.checkStagger(def);
    } else {
      if (reactType === 'block') {
        const stDmg = defRoll - atkRoll;
        atk.st = Math.max(0, atk.st - stDmg);
        this.combatLog(def.name + ' blocks! '
          + stDmg + ' ST to ' + atk.name);
        this.checkStagger(atk);
      } else if (reactType === 'counter') {
        const type = this.getDmgType(def);
        const result = this.calcDamage(
          defRoll, type, atk);
        this.applyHpDamage(atk, result.hp);
        atk.st = Math.max(0,
          atk.st - result.st);
        this.combatLog(def.name
          + ' counters for ' + defRoll
          + ' (' + result.hp + ' HP / '
          + result.st + ' ST)');
        this.checkStagger(atk);
      } else if (reactType === 'evade') {
        def.st = Math.min(def.stMax,
          def.st + defRoll);
        def.recycledEvades++;
        this.combatLog(def.name
          + ' evades! +' + defRoll + ' ST');
      }
    }
  }

  checkCrit(atk, def) {
    if (atk.statuses.poise <= 0) return;
    const roll = this.rollDice(1, 10);
    if (roll <= atk.statuses.poise) {
      const stacks = Math.max(1,
        atk.statuses.critical || 0);
      let bonus = 0;
      for (let i = 0; i < stacks; i++) {
        bonus += this.rollDice(1, 10);
      }
      this.applyHpDamage(def, bonus);
      this.combatLog(atk.name
        + ' CRITICAL HIT! +' + bonus + ' HP');
      atk.statuses.poise = 0;
      atk.statuses.critical = 0;
    }
  }

  checkDevastation(atk, def) {
    if (def.statuses.ruin <= 0) return;
    const roll = this.rollDice(1, 10);
    if (roll <= def.statuses.ruin) {
      const stacks = Math.max(1,
        def.statuses.devastation || 0);
      let bonus = 0;
      for (let i = 0; i < stacks; i++) {
        bonus += this.rollDice(1, 8);
      }
      this.applyHpDamage(def, bonus);
      this.combatLog(def.name
        + ' DEVASTATING HIT! +'
        + bonus + ' HP');
      def.statuses.ruin = 0;
      def.statuses.devastation = 0;
    }
  }

  autoProcBurst(atk, def) {
    // Rupture
    if (def.statuses.rupture >= 3) {
      const amt = def.statuses.rupture;
      this.applyHpDamage(def, amt);
      this.combatLog(def.name
        + ' RUPTURE BURST: ' + amt + ' HP');
      def.statuses.rupture = 0;
    }
    // Tremor
    if (def.statuses.tremor >= 3) {
      const amt = def.statuses.tremor;
      def.st = Math.max(0, def.st - amt);
      this.combatLog(def.name
        + ' TREMOR BURST: ' + amt + ' ST');
      def.statuses.tremor = 0;
      this.checkStagger(def);
    }
    // Sinking
    if (def.statuses.sinking >= 3) {
      const amt = def.statuses.sinking;
      if (def.sp !== undefined
        && def.sp > 0) {
        def.sp = Math.max(0, def.sp - amt);
      } else {
        this.applyHpDamage(def, amt);
      }
      this.combatLog(def.name
        + ' SINKING BURST: ' + amt);
      def.statuses.sinking = 0;
    }
  }

  procActionBleed(c, context) {
    const bleed = c.statuses.bleed || 0;
    if (bleed <= 0) return;
    const reduction = this.getBleedResistance(
      c);
    const dmg = Math.max(0, bleed - reduction);
    this.applyHpDamage(c, dmg);
    c.statuses.bleed = Math.floor(bleed / 2);
    this.combatLog(c.name + ' bleeds '
      + dmg + ' (' + context + ')');
  }

  // Process end-of-round ticks for all
  // combatants
  processRoundEnd() {
    const c = this.combat;
    const ids = Object.keys(c.combatants);
    for (let i = 0; i < ids.length; i++) {
      const cm = c.combatants[ids[i]];
      if (cm.hp <= 0) continue;
      // Burn tick
      const burn = cm.statuses.burn || 0;
      if (burn > 0) {
        const red
          = this.getBurnResistance(cm);
        const dmg = Math.max(0, burn - red);
        this.applyHpDamage(cm, dmg);
        cm.statuses.burn
          = Math.floor(burn / 2);
        this.combatLog(cm.name + ' burns '
          + dmg + ' HP ('
          + cm.statuses.burn + ' left)');
      }
      // Frostbite tick
      const frost = cm.statuses.frostbite || 0;
      if (frost > 0) {
        cm.st = Math.max(0, cm.st - frost);
        cm.statuses.frostbite
          = Math.floor(frost / 2);
        this.combatLog(cm.name + ' frosts '
          + frost + ' ST');
        this.checkStagger(cm);
      }
      // Clear round-end statuses
      const clearList = ['rupture', 'tremor',
        'sinking', 'strength', 'feeble',
        'endurance', 'disarm', 'protection',
        'stagger_protection', 'fragile',
        'stagger_fragile', 'haste', 'bind',
        'paralysis'];
      for (let j = 0;
        j < clearList.length; j++) {
        cm.statuses[clearList[j]] = 0;
      }
      // Apply queued statuses
      const qkeys = Object.keys(
        cm.queuedStatuses);
      for (let j = 0;
        j < qkeys.length; j++) {
        const k = qkeys[j];
        if (cm.queuedStatuses[k] > 0) {
          cm.statuses[k]
            = (cm.statuses[k] || 0)
              + cm.queuedStatuses[k];
          cm.queuedStatuses[k] = 0;
        }
      }
      this.checkKO(cm);
    }
  }

  // ========== COMBAT: ENEMY AI ==========
  runEnemyTurn(enemy) {
    const player = this.combat
      .combatants.player;
    if (player.hp <= 0) {
      this.endTurn();
      return;
    }
    const dist = this.distance(enemy, player);
    if (dist > 1 && enemy.moveLeft > 0) {
      // Walk toward player, stop 1 tile away
      const path = this.pathTo(
        enemy.x, enemy.y,
        player.x, player.y);
      if (path && path.length > 0) {
        // Drop the last step (target tile)
        const reachable = path.slice(0,
          path.length - 1);
        const take = Math.min(
          enemy.moveLeft, reachable.length);
        if (take > 0) {
          const slice = reachable.slice(
            0, take);
          enemy.moveLeft -= take;
          this.queueMove(enemy, slice);
        }
      }
    }
    this.queueDelay(0.2, () => {
      if (enemy.hp <= 0) {
        this.endTurn();
        return;
      }
      if (this.distance(enemy, player) <= 1
        && enemy.actionsLeft > 0
        && player.hp > 0) {
        // Attack - if player has reactions,
        // show prompt; else one-sided
        enemy.actionsLeft--;
        if (player.reactionsLeft > 0
          && !player.staggered) {
          this.combat.phase = CP_PLAYER_REACT;
          this.combat.pendingAttack = {
            attacker: enemy,
            defender: player,
          };
        } else {
          this.resolveClash(
            enemy, player, 'takehit');
          this.queueDelay(0.3, () => {
            this.endTurn();
          });
        }
      } else {
        this.queueDelay(0.1, () => {
          this.endTurn();
        });
      }
    });
  }

  pickEnemyReaction(enemy, attacker) {
    if (enemy.reactionsLeft <= 0) {
      return 'takehit';
    }
    if (this.isInMeleeRange(enemy, attacker)
      && Math.random() < 0.5) {
      return 'counter';
    }
    if (Math.random() < 0.5) return 'block';
    return 'evade';
  }

  // ========== COMBAT: PLAYER ACTIONS ==========
  startPlayerMove() {
    if (this.combat.phase !== CP_IDLE) return;
    const me = this.combat.combatants.player;
    if (me.moveLeft <= 0) return;
    const r = this.tilesInRange(
      me.x, me.y, me.moveLeft);
    this.combat.moveRange = r;
    this.combat.phase = CP_MOVING;
    this.combat.selectedAction = 'move';
  }

  startPlayerAttack() {
    if (this.combat.phase !== CP_IDLE) return;
    const me = this.combat.combatants.player;
    if (me.actionsLeft <= 0) return;
    const range = this.getAttackRange(me);
    // Compute tiles within Chebyshev range
    const inRange = {};
    for (let dy = -range; dy <= range; dy++) {
      for (let dx = -range;
        dx <= range; dx++) {
        if (dx === 0 && dy === 0) continue;
        const nx = me.x + dx;
        const ny = me.y + dy;
        if (nx < 0 || nx >= this.combat.grid.w
          || ny < 0
          || ny >= this.combat.grid.h) {
          continue;
        }
        inRange[nx + ',' + ny] = true;
      }
    }
    this.combat.atkRange = inRange;
    this.combat.phase = CP_ATTACKING;
    this.combat.selectedAction = 'attack';
  }

  cancelAction() {
    this.combat.phase = CP_IDLE;
    this.combat.selectedAction = null;
    this.combat.moveRange = null;
    this.combat.atkRange = null;
    this.combat.movePath = [];
  }

  executePlayerMove(tx, ty) {
    const me = this.combat.combatants.player;
    const path = this.pathTo(
      me.x, me.y, tx, ty);
    if (!path || path.length === 0) return;
    if (path.length > me.moveLeft) return;
    me.moveLeft -= path.length;
    this.queueMove(me, path);
    this.cancelAction();
  }

  // Skill type that matches a given action /
  // reaction. Block reaction uses block
  // skills, Evade uses evade, Counter and
  // Attack action both use attack skills.
  skillTypeForAction(actionOrReact) {
    if (actionOrReact === 'attack') {
      return 'attack';
    }
    if (actionOrReact === 'counter') {
      return 'attack';
    }
    if (actionOrReact === 'block') {
      return 'block';
    }
    if (actionOrReact === 'evade') {
      return 'evade';
    }
    return null;
  }

  // Returns array of skill indices the
  // combatant could use right now for the
  // given action type. Filters by Light cost.
  getUsableSkills(c, actionType) {
    const skillType
      = this.skillTypeForAction(actionType);
    if (!skillType) return [];
    if (!c.skills) return [];
    if (c.staggered) return [];
    const out = [];
    for (let i = 0; i < c.skills.length; i++) {
      const s = c.skills[i];
      if (!s || s.type !== skillType) continue;
      if (c.light < s.lightCost) continue;
      out.push(i);
    }
    return out;
  }

  executePlayerAttack(targetId) {
    const me = this.combat.combatants.player;
    const target = this.combat
      .combatants[targetId];
    if (!target || target.hp <= 0) return;
    if (this.distance(me, target)
      > this.getAttackRange(me)) return;
    me.actionsLeft--;
    // Enemy picks reaction first so the
    // player knows what they're facing
    const reactType = this.pickEnemyReaction(
      target, me);
    this.cancelAction();
    // If player has any attack skill they
    // can afford, prompt before clashing
    const usable = this.getUsableSkills(
      me, 'attack');
    if (usable.length > 0) {
      this.combat.phase = CP_PLAYER_SKILL;
      this.combat.pendingSkillChoice = {
        context: 'attack',
        attacker: me,
        defender: target,
        reactType: reactType,
        defSkillIdx: -1,
        available: usable,
        skillType: 'attack',
      };
      return;
    }
    // No usable skill - resolve directly
    this.resolveClash(me, target, reactType,
      -1, -1);
  }

  playerEndTurn() {
    if (this.combat.phase !== CP_IDLE) return;
    this.endTurn();
  }

  playerChooseReaction(reactType) {
    if (this.combat.phase !== CP_PLAYER_REACT) {
      return;
    }
    const pa = this.combat.pendingAttack;
    if (!pa) return;
    this.combat.pendingAttack = null;
    const me = pa.defender;
    // Take Hit doesn't use skills
    if (reactType === 'takehit') {
      this.combat.phase = CP_IDLE;
      this.resolveClash(pa.attacker,
        pa.defender, reactType, -1, -1);
      this.queueDelay(0.3, () => {
        this.endTurn();
      });
      return;
    }
    // Check for usable matching skills
    const usable = this.getUsableSkills(
      me, reactType);
    if (usable.length > 0) {
      this.combat.phase = CP_PLAYER_SKILL;
      this.combat.pendingSkillChoice = {
        context: 'reaction',
        attacker: pa.attacker,
        defender: pa.defender,
        reactType: reactType,
        defSkillIdx: -1,
        available: usable,
        skillType: this.skillTypeForAction(
          reactType),
      };
      return;
    }
    // No skill - resolve directly
    this.combat.phase = CP_IDLE;
    this.resolveClash(
      pa.attacker, pa.defender, reactType,
      -1, -1);
    this.queueDelay(0.3, () => {
      this.endTurn();
    });
  }

  // Player selects a skill from the choice
  // modal. Pass -1 for "no skill".
  playerChooseSkill(skillIdx) {
    const c = this.combat;
    if (c.phase !== CP_PLAYER_SKILL) return;
    const psc = c.pendingSkillChoice;
    if (!psc) return;
    c.pendingSkillChoice = null;
    c.phase = CP_IDLE;
    if (psc.context === 'attack') {
      this.resolveClash(
        psc.attacker, psc.defender,
        psc.reactType, skillIdx, -1);
    } else {
      this.resolveClash(
        psc.attacker, psc.defender,
        psc.reactType, -1, skillIdx);
      this.queueDelay(0.3, () => {
        this.endTurn();
      });
    }
  }

  // ========== COMBAT: RENDER ==========
  renderCombat() {
    const ctx = this.ctx;
    if (!this.combat) return;
    this.renderTurnOrder();
    this.renderGrid();
    this.renderInfoPanel();
    this.renderActionBar();
    this.renderEndTurnBtn();
    if (this.combatDebug) {
      this.renderDebugHUD();
    }
    // Current animation overlay
    this.renderCombatAnim();
    // Reaction modal on top
    if (this.combat.phase === CP_PLAYER_REACT) {
      this.renderReactionModal();
    }
    // Skill choice modal on top
    if (this.combat.phase === CP_PLAYER_SKILL) {
      this.renderSkillChoiceModal();
    }
  }

  renderTurnOrder() {
    const ctx = this.ctx;
    const c = this.combat;
    ctx.fillStyle = COL.panelBg;
    ctx.fillRect(0, 0, CW, 42);
    ctx.strokeStyle = COL.panelBorder;
    ctx.strokeRect(0, 0, CW, 42);
    ctx.fillStyle = COL.textGold;
    ctx.font = '11px monospace';
    ctx.fillText('Round ' + c.round,
      10, 16);
    ctx.fillStyle = COL.textDim;
    ctx.font = '9px monospace';
    ctx.fillText(
      'Phase: ' + c.phase, 10, 32);
    // Turn order chips
    let tx = 120;
    for (let i = 0;
      i < c.turnOrder.length; i++) {
      const id = c.turnOrder[i];
      const cm = c.combatants[id];
      const active = (i === c.turnIdx);
      const chipW = 130;
      ctx.fillStyle = active
        ? COL.btnActive : COL.btnNorm;
      ctx.fillRect(tx, 4, chipW, 34);
      ctx.strokeStyle = active
        ? COL.textGold : COL.panelBorder;
      ctx.lineWidth = active ? 2 : 1;
      ctx.strokeRect(tx, 4, chipW, 34);
      ctx.lineWidth = 1;
      ctx.fillStyle = cm.hp > 0
        ? COL.text : COL.textDim;
      ctx.font = '10px monospace';
      ctx.fillText(cm.name.substring(0, 14),
        tx + 6, tx < 0 ? 0 : 17);
      // HP bar
      const hpFrac = cm.hpMax > 0
        ? cm.hp / cm.hpMax : 0;
      this.drawBar(tx + 6, 22,
        chipW - 12, 5, hpFrac, 1, COL.hpBar);
      // ST bar
      const stFrac = cm.stMax > 0
        ? cm.st / cm.stMax : 0;
      this.drawBar(tx + 6, 29,
        chipW - 12, 4, stFrac, 1, COL.stBar);
      tx += chipW + 6;
    }
  }

  renderGrid() {
    const ctx = this.ctx;
    const c = this.combat;
    const g = c.grid;
    // Compute grid origin
    const gx = GRID_X;
    const gy = GRID_Y;
    // Background
    ctx.fillStyle = '#0a0a14';
    ctx.fillRect(gx - 2, gy - 2,
      g.w * TILE + 4, g.h * TILE + 4);
    // Tiles
    for (let ty = 0; ty < g.h; ty++) {
      for (let tx = 0; tx < g.w; tx++) {
        const px = gx + tx * TILE;
        const py = gy + ty * TILE;
        const tile = g.tiles[ty * g.w + tx];
        if (tile === 1) {
          // Wall
          ctx.fillStyle = '#0a0a12';
          ctx.fillRect(px, py, TILE, TILE);
          ctx.strokeStyle = '#2a2a3a';
          ctx.strokeRect(
            px + 2, py + 2,
            TILE - 4, TILE - 4);
        } else {
          ctx.fillStyle = '#1a1a2e';
          ctx.fillRect(px, py, TILE, TILE);
          ctx.strokeStyle = '#12122a';
          ctx.strokeRect(px, py, TILE, TILE);
        }
      }
    }
    // Movement range highlights
    if (c.moveRange) {
      ctx.fillStyle = 'rgba(68,136,255,0.25)';
      const keys = Object.keys(
        c.moveRange.visited);
      for (let i = 0; i < keys.length; i++) {
        const parts = keys[i].split(',');
        const tx = parseInt(parts[0], 10);
        const ty = parseInt(parts[1], 10);
        ctx.fillRect(
          gx + tx * TILE, gy + ty * TILE,
          TILE, TILE);
      }
    }
    // Attack range highlights
    if (c.atkRange) {
      ctx.fillStyle = 'rgba(255,68,68,0.25)';
      const keys = Object.keys(c.atkRange);
      for (let i = 0; i < keys.length; i++) {
        const parts = keys[i].split(',');
        const tx = parseInt(parts[0], 10);
        const ty = parseInt(parts[1], 10);
        ctx.fillRect(
          gx + tx * TILE, gy + ty * TILE,
          TILE, TILE);
      }
    }
    // Hovered tile highlight
    if (c.hoveredTile && c.phase !== CP_ANIM) {
      ctx.strokeStyle = COL.textGold;
      ctx.lineWidth = 2;
      ctx.strokeRect(
        gx + c.hoveredTile.x * TILE,
        gy + c.hoveredTile.y * TILE,
        TILE, TILE);
      ctx.lineWidth = 1;
    }
    // Combatants
    const ids = Object.keys(c.combatants);
    for (let i = 0; i < ids.length; i++) {
      const cm = c.combatants[ids[i]];
      if (cm.hp <= 0) continue;
      const px = gx + cm.x * TILE;
      const py = gy + cm.y * TILE;
      // Inspection ring (drawn under circle)
      if (c.inspectedId === ids[i]) {
        ctx.strokeStyle = COL.textGold;
        ctx.lineWidth = 2;
        ctx.strokeRect(
          px + 1, py + 1,
          TILE - 2, TILE - 2);
        ctx.lineWidth = 1;
      }
      // Circle background
      const clr = cm.isPlayer
        ? '#44ffaa' : '#ff6644';
      ctx.fillStyle = cm.staggered
        ? '#ffcc44' : clr;
      ctx.beginPath();
      ctx.arc(px + TILE / 2,
        py + TILE / 2,
        TILE / 2 - 4, 0, Math.PI * 2);
      ctx.fill();
      ctx.strokeStyle = '#000';
      ctx.lineWidth = 2;
      ctx.stroke();
      ctx.lineWidth = 1;
      // Letter
      ctx.fillStyle = '#000';
      ctx.font = 'bold 16px monospace';
      const lbl = cm.isPlayer ? '@' : 'E';
      const lblW = ctx.measureText(lbl).width;
      ctx.fillText(lbl,
        px + (TILE - lblW) / 2,
        py + TILE / 2 + 5);
      // HP/ST mini bars below
      const bw = TILE - 4;
      this.drawBar(px + 2, py + TILE - 5,
        bw, 2, cm.hp / cm.hpMax, 1,
        COL.hpBar);
      this.drawBar(px + 2, py + TILE - 2,
        bw, 2, cm.st / cm.stMax, 1,
        COL.stBar);
      // Stagger marker
      if (cm.staggered) {
        ctx.fillStyle = '#ffcc44';
        ctx.font = 'bold 10px monospace';
        ctx.fillText('!!', px + 2, py + 10);
      }
      // Temp HP indicator
      if (cm.tempHp > 0) {
        ctx.fillStyle = '#44ffcc';
        ctx.font = 'bold 8px monospace';
        ctx.fillText('+' + cm.tempHp,
          px + TILE - 14, py + 9);
      }
      // Status icons above the tile
      this.drawStatusIcons(cm, px, py - 11);
    }
  }

  drawStatusIcons(cm, px, py) {
    const ctx = this.ctx;
    const activeStatuses = [];
    const keys = Object.keys(STATUS_DISPLAY);
    for (let i = 0; i < keys.length; i++) {
      const k = keys[i];
      if ((cm.statuses[k] || 0) > 0) {
        activeStatuses.push(k);
      }
    }
    if (activeStatuses.length === 0) return;
    const maxIcons = 3;
    const iconW = 10;
    const visible = Math.min(maxIcons,
      activeStatuses.length);
    for (let i = 0; i < visible; i++) {
      const k = activeStatuses[i];
      const def = STATUS_DISPLAY[k];
      const ix = px + i * (iconW + 1);
      ctx.fillStyle = def.color;
      ctx.fillRect(ix, py, iconW, 10);
      ctx.strokeStyle = '#000';
      ctx.strokeRect(ix, py, iconW, 10);
      ctx.fillStyle = '#000';
      ctx.font = 'bold 7px monospace';
      ctx.fillText('' + cm.statuses[k],
        ix + 3, py + 8);
    }
    if (activeStatuses.length > maxIcons) {
      const extra = activeStatuses.length
        - maxIcons;
      const ix = px + maxIcons * (iconW + 1);
      ctx.fillStyle = '#666';
      ctx.fillRect(ix, py, iconW, 10);
      ctx.fillStyle = '#fff';
      ctx.font = 'bold 7px monospace';
      ctx.fillText('+' + extra,
        ix + 1, py + 8);
    }
  }

  renderInfoPanel() {
    const ctx = this.ctx;
    const c = this.combat;
    const px = 520;
    const py = 50;
    const pw = 270;
    const ph = 430;
    this.drawPanel(px, py, pw, ph);
    // Resolve inspected combatant
    const inspId = c.inspectedId || 'player';
    const insp = c.combatants[inspId]
      || c.combatants.player;
    const isPlayer = insp.isPlayer;
    // Header
    ctx.fillStyle = COL.textGold;
    ctx.font = '11px monospace';
    ctx.fillText(
      isPlayer ? 'SELF' : 'TARGET',
      px + 10, py + 14);
    // Hint on the right
    ctx.fillStyle = COL.textDim;
    ctx.font = '8px monospace';
    ctx.fillText('click grid to inspect',
      px + pw - 115, py + 14);
    // Name row (accent colored)
    ctx.fillStyle = isPlayer
      ? '#44ffaa' : '#ff6644';
    ctx.font = 'bold 12px monospace';
    ctx.fillText(insp.name,
      px + 10, py + 30);
    // Role line
    ctx.fillStyle = COL.textDim;
    ctx.font = '9px monospace';
    ctx.fillText(
      isPlayer ? '[Player]' : '[Enemy]',
      px + 10, py + 42);
    // HP/ST/SP bars
    let by = py + 50;
    ctx.fillStyle = COL.text;
    ctx.font = '9px monospace';
    ctx.fillText('HP ' + insp.hp + '/'
      + insp.hpMax, px + 10, by + 8);
    this.drawBar(px + 80, by + 2,
      pw - 90, 8, insp.hp / insp.hpMax,
      1, COL.hpBar);
    by += 14;
    ctx.fillText('ST ' + insp.st + '/'
      + insp.stMax, px + 10, by + 8);
    this.drawBar(px + 80, by + 2,
      pw - 90, 8, insp.st / insp.stMax,
      1, COL.stBar);
    by += 14;
    if (isPlayer) {
      ctx.fillText('SP ' + insp.sp + '/'
        + insp.spMax, px + 10, by + 8);
      this.drawBar(px + 80, by + 2,
        pw - 90, 8, insp.sp / insp.spMax,
        1, COL.spBar);
      by += 14;
    }
    by += 4;
    // Action economy
    ctx.fillStyle = COL.text;
    ctx.font = '9px monospace';
    ctx.fillText(
      'Actions: ' + insp.actionsLeft
        + '/' + insp.actions,
      px + 10, by);
    ctx.fillText(
      'React: ' + insp.reactionsLeft
        + '/' + insp.reactions,
      px + 140, by);
    by += 12;
    ctx.fillText(
      'Move: ' + insp.moveLeft
        + '/' + insp.move + ' SQR',
      px + 10, by);
    by += 12;
    if (insp.staggered) {
      ctx.fillStyle = COL.textRed;
      ctx.font = 'bold 9px monospace';
      ctx.fillText('** STAGGERED **',
        px + 10, by);
      by += 12;
    }
    if (insp.recycledEvades > 0) {
      ctx.fillStyle = COL.textDim;
      ctx.font = '9px monospace';
      ctx.fillText('Recycled Evade -'
        + (insp.recycledEvades * 2)
        + ' pow', px + 10, by);
      by += 12;
    }
    // Separator
    ctx.strokeStyle = COL.panelBorder;
    ctx.beginPath();
    ctx.moveTo(px + 8, by + 2);
    ctx.lineTo(px + pw - 8, by + 2);
    ctx.stroke();
    by += 8;
    // Status section (always shown)
    by = this.renderInspectStatuses(
      insp, px, by, pw);
    // Loadout section
    by = this.renderInspectLoadout(
      insp, isPlayer, px, by, pw);
    // Combat log at the bottom of the panel
    const logY = py + ph - 82;
    ctx.strokeStyle = COL.panelBorder;
    ctx.beginPath();
    ctx.moveTo(px + 8, logY - 2);
    ctx.lineTo(px + pw - 8, logY - 2);
    ctx.stroke();
    ctx.fillStyle = COL.textGold;
    ctx.font = '9px monospace';
    ctx.fillText('-- LOG --',
      px + 10, logY + 10);
    ctx.fillStyle = COL.textDim;
    ctx.font = '8px monospace';
    const maxChars = Math.floor(
      (pw - 20) / 5);
    const startLog = Math.max(0,
      c.log.length - 5);
    let ly = logY + 22;
    for (let i = startLog;
      i < c.log.length; i++) {
      const line = c.log[i];
      const wrapped = this.wrapText(
        line, maxChars);
      for (let j = 0;
        j < wrapped.length && j < 2; j++) {
        if (ly > py + ph - 6) break;
        ctx.fillText(
          wrapped[j], px + 10, ly);
        ly += 10;
      }
    }
  }

  renderInspectStatuses(insp, px, by, pw) {
    const ctx = this.ctx;
    const lineX = px + 10;
    ctx.fillStyle = COL.textGold;
    ctx.font = 'bold 9px monospace';
    ctx.fillText('STATUSES', lineX, by);
    by += 11;
    const keys = Object.keys(STATUS_DISPLAY);
    let any = false;
    for (let i = 0; i < keys.length; i++) {
      const k = keys[i];
      const v = insp.statuses[k] || 0;
      if (v <= 0) continue;
      any = true;
      const def = STATUS_DISPLAY[k];
      ctx.fillStyle = def.color;
      ctx.font = '9px monospace';
      ctx.fillText(
        def.name + ' x' + v, lineX, by);
      by += 10;
    }
    // Show queued statuses (next round)
    const qkeys = Object.keys(
      insp.queuedStatuses);
    let qAny = false;
    for (let i = 0; i < qkeys.length; i++) {
      const k = qkeys[i];
      const v = insp.queuedStatuses[k] || 0;
      if (v <= 0) continue;
      if (!qAny) {
        ctx.fillStyle = COL.textDim;
        ctx.font = 'italic 8px monospace';
        ctx.fillText('(next round)',
          lineX, by);
        by += 10;
        qAny = true;
      }
      const def = STATUS_DISPLAY[k];
      if (!def) continue;
      ctx.fillStyle = def.color;
      ctx.font = 'italic 8px monospace';
      ctx.fillText('+ ' + def.name
        + ' x' + v, lineX, by);
      by += 10;
    }
    if (!any && !qAny) {
      ctx.fillStyle = COL.textDim;
      ctx.font = '9px monospace';
      ctx.fillText('(none)', lineX, by);
      by += 10;
    }
    by += 4;
    return by;
  }

  renderInspectLoadout(insp, isPlayer, px,
    by, pw) {
    const ctx = this.ctx;
    const lineX = px + 10;
    const maxChars = Math.floor(
      (pw - 20) / 5);
    if (isPlayer) {
      // Weapon
      ctx.fillStyle = COL.textGold;
      ctx.font = 'bold 9px monospace';
      ctx.fillText('WEAPON', lineX, by);
      by += 11;
      ctx.fillStyle = COL.text;
      ctx.font = '9px monospace';
      const wName = insp.weapon.name
        || 'Unnamed';
      ctx.fillText('"' + wName + '"',
        lineX, by);
      by += 11;
      const wLines = summarizeWeapon(
        insp.weapon);
      ctx.fillStyle = COL.textDim;
      ctx.font = '8px monospace';
      for (let i = 0;
        i < wLines.length; i++) {
        const wr = this.wrapText(
          wLines[i], maxChars);
        for (let j = 0;
          j < wr.length; j++) {
          ctx.fillText(wr[j], lineX, by);
          by += 10;
        }
      }
      by += 4;
      // Outfit
      ctx.fillStyle = COL.textGold;
      ctx.font = 'bold 9px monospace';
      ctx.fillText('OUTFIT', lineX, by);
      by += 11;
      ctx.fillStyle = COL.text;
      ctx.font = '9px monospace';
      const oName = insp.outfit.name
        || 'Unnamed';
      ctx.fillText('"' + oName + '"',
        lineX, by);
      by += 11;
      const oLines = summarizeOutfit(
        insp.outfit);
      ctx.fillStyle = COL.textDim;
      ctx.font = '8px monospace';
      for (let i = 0;
        i < oLines.length; i++) {
        const wr = this.wrapText(
          oLines[i], maxChars);
        for (let j = 0;
          j < wr.length; j++) {
          ctx.fillText(wr[j], lineX, by);
          by += 10;
        }
      }
      by += 4;
      // Skills (color-coded)
      ctx.fillStyle = COL.textGold;
      ctx.font = 'bold 9px monospace';
      ctx.fillText('SKILLS', lineX, by);
      by += 11;
      for (let i = 0;
        i < insp.skills.length; i++) {
        const s = insp.skills[i];
        const cols = skillColors(s.type);
        ctx.fillStyle = cols.border;
        ctx.font = 'bold 9px monospace';
        const sType = SKILL_TYPES.find(
          t => t.key === s.type);
        ctx.fillText(
          (i + 1) + '. "'
            + (s.name || 'Unnamed') + '" ('
            + (sType ? sType.name : '?')
            + ', ' + s.lightCost + 'L)',
          lineX, by);
        by += 10;
      }
    } else {
      // Enemy: simplified display
      ctx.fillStyle = COL.textGold;
      ctx.font = 'bold 9px monospace';
      ctx.fillText('LOADOUT', lineX, by);
      by += 11;
      ctx.fillStyle = COL.text;
      ctx.font = '9px monospace';
      const atk = insp.atkDice;
      ctx.fillText(
        'Attack: ' + atk.num + 'd'
          + atk.max
          + (atk.pow >= 0 ? '+' : '')
          + atk.pow + ' ' + insp.dmgType,
        lineX, by);
      by += 11;
      const blk = insp.blockDice;
      ctx.fillText(
        'Block:  ' + blk.num + 'd'
          + blk.max
          + (blk.pow >= 0 ? '+' : '')
          + blk.pow,
        lineX, by);
      by += 11;
      const evd = insp.evadeDice;
      ctx.fillText(
        'Evade:  ' + evd.num + 'd'
          + evd.max
          + (evd.pow >= 0 ? '+' : '')
          + evd.pow,
        lineX, by);
      by += 11;
      by += 4;
      ctx.fillStyle = COL.textDim;
      ctx.font = '8px monospace';
      ctx.fillText('Resistances:', lineX, by);
      by += 10;
      const labels = ['Slash', 'Pierce',
        'Blunt'];
      const keys = ['slash', 'pierce',
        'blunt'];
      for (let i = 0; i < 3; i++) {
        const hpM = insp.resist[
          keys[i] + '_hp'];
        const stM = insp.resist[
          keys[i] + '_st'];
        ctx.fillText(
          '  ' + labels[i]
            + '  HP x' + hpM
            + '  ST x' + stM,
          lineX, by);
        by += 10;
      }
      by += 4;
      ctx.fillText('AI: ' + insp.ai,
        lineX, by);
      by += 10;
    }
    return by;
  }

  renderActionBar() {
    const ctx = this.ctx;
    const c = this.combat;
    const me = c.combatants.player;
    const by = 495;
    ctx.fillStyle = COL.panelBg;
    ctx.fillRect(10, by, 500, 48);
    ctx.strokeStyle = COL.panelBorder;
    ctx.strokeRect(10, by, 500, 48);
    const isMyTurn = c.turnOrder[c.turnIdx]
      === 'player' && c.phase === CP_IDLE;
    const canMove = isMyTurn
      && me.moveLeft > 0;
    const canAtk = isMyTurn
      && me.actionsLeft > 0;
    this.drawBtn('Move (1)',
      20, by + 12, 90, 24,
      canMove ? (c.selectedAction === 'move'
        ? COL.btnActive : COL.btnNorm)
        : COL.btnDisabled);
    this.drawBtn('Attack (2)',
      120, by + 12, 90, 24,
      canAtk ? (c.selectedAction === 'attack'
        ? COL.btnActive : COL.btnNorm)
        : COL.btnDisabled);
    this.drawBtn('Cancel (ESC)',
      220, by + 12, 110, 24,
      c.selectedAction
        ? COL.btnNorm : COL.btnDisabled);
    this.drawBtn('Reset Combat',
      350, by + 12, 150, 24, COL.btnNorm);
  }

  renderEndTurnBtn() {
    const c = this.combat;
    const isMyTurn = c.turnOrder[c.turnIdx]
      === 'player' && c.phase === CP_IDLE;
    this.drawBtn('End Turn (SPACE)',
      10, 555, 200, 30,
      isMyTurn ? COL.btnActive
        : COL.btnDisabled);
  }

  renderDebugHUD() {
    const ctx = this.ctx;
    const c = this.combat;
    const px = 520;
    const py = 490;
    ctx.fillStyle = 'rgba(0,0,0,0.6)';
    ctx.fillRect(px, py, 270, 100);
    ctx.strokeStyle = '#aa6622';
    ctx.strokeRect(px, py, 270, 100);
    ctx.fillStyle = '#ffaa44';
    ctx.font = '9px monospace';
    ctx.fillText('DEBUG', px + 6, py + 12);
    ctx.fillStyle = COL.textDim;
    ctx.fillText('Turn: '
      + c.combatants[c.turnOrder[c.turnIdx]]
        .name,
      px + 6, py + 26);
    ctx.fillText('Phase: ' + c.phase,
      px + 6, py + 38);
    ctx.fillText(
      'Last roll: '
        + (c.lastRoll === null
          ? '-' : c.lastRoll),
      px + 6, py + 50);
    if (c.lastDamage) {
      ctx.fillText(
        'Last dmg: ' + c.lastDamage.hp
          + ' HP / ' + c.lastDamage.st
          + ' ST',
        px + 6, py + 62);
    }
    ctx.fillText('AnimQ: '
      + this.combatAnimQueue.length,
      px + 6, py + 74);
    ctx.fillText('Round ' + c.round,
      px + 6, py + 86);
  }

  renderCombatAnim() {
    const c = this.combat;
    if (this.combatAnimQueue.length === 0) {
      return;
    }
    const a = this.combatAnimQueue[0];
    if (a.type !== 'clash') return;
    const ctx = this.ctx;
    const cx = GRID_X
      + (c.grid.w * TILE) / 2;
    const cy = GRID_Y + 80;
    const progress = Math.min(1, a.t / a.dur);
    const showResult = progress > 0.4;
    // Resolve which side is player vs enemy
    const atk = a.atk;
    const def = a.def;
    const playerIsAtk = atk.isPlayer;
    const leftC = playerIsAtk ? atk : def;
    const rightC = playerIsAtk ? def : atk;
    // Compute each side's roll type + value +
    // winner flag based on who is attacker
    const atkLabel = 'ATTACK';
    const rType = a.data.reactType;
    let defLabel;
    if (rType === 'none') {
      defLabel = 'NO REACT';
    } else if (rType === 'takehit') {
      defLabel = 'TAKE HIT';
    } else {
      defLabel = rType.toUpperCase();
    }
    let leftLabel;
    let leftRoll;
    let leftWin;
    let rightLabel;
    let rightRoll;
    let rightWin;
    if (playerIsAtk) {
      leftLabel = atkLabel;
      leftRoll = a.data.atkRoll;
      leftWin = a.data.winner === 'attacker';
      rightLabel = defLabel;
      rightRoll = a.data.defRoll;
      rightWin = a.data.winner === 'defender';
    } else {
      leftLabel = defLabel;
      leftRoll = a.data.defRoll;
      leftWin = a.data.winner === 'defender';
      rightLabel = atkLabel;
      rightRoll = a.data.atkRoll;
      rightWin = a.data.winner === 'attacker';
    }
    // Panel background
    const panelX = cx - 160;
    const panelY = cy - 70;
    const panelW = 320;
    const panelH = 160;
    ctx.fillStyle = 'rgba(10,10,20,0.85)';
    ctx.fillRect(panelX, panelY,
      panelW, panelH);
    ctx.strokeStyle = COL.panelBorder;
    ctx.lineWidth = 1;
    ctx.strokeRect(panelX, panelY,
      panelW, panelH);
    // Draw left (player) side
    this.drawClashBox(
      cx - 140, cy - 50, 120, 110,
      leftC, leftLabel, leftRoll,
      leftWin, showResult, '#44ffaa'
    );
    // Draw right (enemy) side
    this.drawClashBox(
      cx + 20, cy - 50, 120, 110,
      rightC, rightLabel, rightRoll,
      rightWin, showResult, '#ff6644'
    );
    // VS text in the middle
    ctx.fillStyle = COL.textGold;
    ctx.font = 'bold 14px monospace';
    const vsW = ctx.measureText('VS').width;
    ctx.fillText('VS',
      cx - vsW / 2, cy + 10);
    // Result text at bottom
    if (showResult) {
      ctx.fillStyle = COL.textGold;
      ctx.font = 'bold 12px monospace';
      let msg;
      if (a.data.winner === 'attacker') {
        msg = rType === 'none'
          ? 'ONE-SIDED HIT!'
          : 'ATTACKER WINS';
      } else {
        msg = defLabel + ' WINS!';
      }
      const mw = ctx.measureText(msg).width;
      ctx.fillText(msg,
        cx - mw / 2, cy + 78);
    }
  }

  drawClashBox(x, y, w, h, combatant,
    roleLabel, rollValue, isWinner,
    showResult, accentCol) {
    const ctx = this.ctx;
    // Solid filled background FIRST - this
    // fixes the "pure white" bug where the
    // previous fillStyle bled through.
    ctx.fillStyle = COL.btnNorm;
    ctx.fillRect(x, y, w, h);
    // Border (winner gold, otherwise accent)
    ctx.strokeStyle = isWinner && showResult
      ? COL.textGold : accentCol;
    ctx.lineWidth = isWinner && showResult
      ? 3 : 2;
    ctx.strokeRect(x, y, w, h);
    ctx.lineWidth = 1;
    // Name at top (truncated to fit)
    ctx.fillStyle = accentCol;
    ctx.font = 'bold 10px monospace';
    const name = (combatant.name || '?')
      .substring(0, 14);
    const nameW = ctx.measureText(name).width;
    ctx.fillText(name,
      x + (w - nameW) / 2, y + 14);
    // Role label
    ctx.fillStyle = COL.textDim;
    ctx.font = '9px monospace';
    const rlW = ctx.measureText(roleLabel).width;
    ctx.fillText(roleLabel,
      x + (w - rlW) / 2, y + 30);
    // Roll value (big)
    ctx.fillStyle = COL.text;
    ctx.font = 'bold 28px monospace';
    let valStr;
    if (rollValue === null
      || rollValue === undefined) {
      valStr = '-';
    } else if (!showResult) {
      valStr = '?'
        + Math.floor(Math.random() * 10);
    } else {
      valStr = '' + rollValue;
    }
    const vW = ctx.measureText(valStr).width;
    ctx.fillText(valStr,
      x + (w - vW) / 2, y + 72);
    // "ROLL" label under the number
    ctx.fillStyle = COL.textDim;
    ctx.font = '8px monospace';
    ctx.fillText('ROLL',
      x + (w - ctx.measureText('ROLL').width)
        / 2, y + 92);
  }

  renderReactionModal() {
    const ctx = this.ctx;
    const c = this.combat;
    const pa = c.pendingAttack;
    if (!pa) return;
    // Dim bg
    ctx.fillStyle = 'rgba(0,0,0,0.55)';
    ctx.fillRect(0, 0, CW, CH);
    // Modal
    const px = 120;
    const py = 100;
    const pw = 560;
    const ph = 380;
    this.drawPanel(px, py, pw, ph);
    ctx.fillStyle = COL.textRed;
    ctx.font = 'bold 16px monospace';
    ctx.fillText('INCOMING ATTACK!',
      px + 20, py + 28);
    ctx.fillStyle = COL.text;
    ctx.font = '12px monospace';
    const atkDice = this.getEffectiveAtkDice(
      pa.attacker);
    ctx.fillText(
      pa.attacker.name
        + ' attacks with 1d' + atkDice.max
        + (atkDice.pow >= 0 ? '+' : '')
        + atkDice.pow + ' '
        + this.getDmgType(pa.attacker),
      px + 20, py + 52);
    ctx.fillStyle = COL.textDim;
    ctx.font = '10px monospace';
    ctx.fillText('Reactions remaining: '
      + pa.defender.reactionsLeft,
      px + 20, py + 70);
    // Reaction options
    const me = pa.defender;
    const optY = py + 90;
    const optH = 60;
    const optW = 520;
    // Block
    const blkDice = this.getEffectiveBlockDice(
      me);
    this.drawReactionOption(
      px + 20, optY, optW, optH,
      '[1] BLOCK', COL.stBar,
      '1d' + blkDice.max
        + (blkDice.pow >= 0 ? '+' : '')
        + blkDice.pow,
      'Win: negate + ST dmg.'
      + ' Lose: reduce attack.');
    // Counter
    const cntDice = this.getEffectiveAtkDice(
      me);
    this.drawReactionOption(
      px + 20, optY + optH + 6, optW, optH,
      '[2] COUNTER', COL.textRed,
      '1d' + cntDice.max
        + (cntDice.pow >= 0 ? '+' : '')
        + cntDice.pow,
      'Win: negate + deal full dmg.'
      + ' Lose: no benefit.');
    // Evade
    const evdDice = this.getEffectiveEvadeDice(
      me);
    this.drawReactionOption(
      px + 20, optY + (optH + 6) * 2,
      optW, optH,
      '[3] EVADE', COL.textGold,
      '1d' + evdDice.max
        + (evdDice.pow >= 0 ? '+' : '')
        + evdDice.pow
        + (me.recycledEvades > 0
          ? ' (-'
            + (me.recycledEvades * 2)
            + ' recycled)'
          : ''),
      'Win: negate + ST regen.'
      + ' Recycles penalty.');
    // Take Hit
    this.drawReactionOption(
      px + 20, optY + (optH + 6) * 3,
      optW, optH,
      '[4] TAKE HIT', COL.textDim,
      'No reaction used',
      'Accept the hit one-sided.');
  }

  renderSkillChoiceModal() {
    const ctx = this.ctx;
    const c = this.combat;
    const psc = c.pendingSkillChoice;
    if (!psc) return;
    // Dim background
    ctx.fillStyle = 'rgba(0,0,0,0.55)';
    ctx.fillRect(0, 0, CW, CH);
    // Modal panel
    const px = 120;
    const py = 100;
    const pw = 560;
    const ph = 380;
    this.drawPanel(px, py, pw, ph);
    // Title
    ctx.fillStyle = COL.textGold;
    ctx.font = 'bold 16px monospace';
    ctx.fillText('USE A SKILL?',
      px + 20, py + 28);
    // Subtitle - what action is pending
    ctx.fillStyle = COL.text;
    ctx.font = '11px monospace';
    let subtitle;
    if (psc.context === 'attack') {
      subtitle = 'Before attacking '
        + psc.defender.name + '...';
    } else {
      subtitle = 'Before reacting with '
        + psc.reactType.toUpperCase() + '...';
    }
    ctx.fillText(subtitle, px + 20, py + 50);
    // Light remaining
    const me = psc.context === 'attack'
      ? psc.attacker : psc.defender;
    ctx.fillStyle = COL.textDim;
    ctx.font = '10px monospace';
    ctx.fillText('Light: ' + me.light + '/'
      + me.lightMax,
      px + 20, py + 68);
    // Skill option buttons
    const optY = py + 90;
    const optH = 70;
    const optW = 520;
    for (let i = 0;
      i < psc.available.length; i++) {
      const idx = psc.available[i];
      const s = me.skills[idx];
      const cols = skillColors(s.type);
      const oy = optY + i * (optH + 6);
      this.drawSkillOption(
        px + 20, oy, optW, optH,
        '[' + (i + 1) + '] '
          + (s.name || 'Unnamed Skill'),
        cols, s);
    }
    // No Skill option always at the bottom
    const noY = optY
      + psc.available.length * (optH + 6);
    if (noY + optH < py + ph - 20) {
      this.drawSkillOption(
        px + 20, noY, optW, optH,
        '[0] NO SKILL', {
          bg: COL.btnNorm,
          border: COL.textDim,
          text: COL.text,
        }, null);
    }
  }

  drawSkillOption(x, y, w, h, label,
    cols, skill) {
    const ctx = this.ctx;
    ctx.fillStyle = cols.bg;
    ctx.fillRect(x, y, w, h);
    ctx.strokeStyle = cols.border;
    ctx.lineWidth = 2;
    ctx.strokeRect(x, y, w, h);
    ctx.lineWidth = 1;
    ctx.fillStyle = cols.text;
    ctx.font = 'bold 13px monospace';
    ctx.fillText(label, x + 10, y + 20);
    if (skill) {
      ctx.fillStyle = cols.text;
      ctx.font = '10px monospace';
      const sType = SKILL_TYPES.find(
        t => t.key === skill.type);
      ctx.fillText(
        (sType ? sType.name : '?')
          + ' | ' + skill.lightCost
          + ' Light',
        x + 10, y + 36);
      // Brief effect summary
      ctx.fillStyle = COL.textDim;
      ctx.font = '9px monospace';
      const effLines = [];
      for (let i = 0;
        i < skill.effects.length
          && i < 3; i++) {
        const e = skill.effects[i];
        const def = SKILL_EFFECTS[e.key];
        if (!def) continue;
        let prefix = '';
        if (e.proc === 'clash_win') {
          prefix = 'CW: ';
        } else if (e.proc === 'clash_lose') {
          prefix = 'CL: ';
        }
        effLines.push(
          prefix + def.name
            + (e.amount > 1
              ? ' x' + e.amount : ''));
      }
      const effStr = effLines.join('  |  ');
      ctx.fillText(effStr.substring(0, 70),
        x + 10, y + 54);
    } else {
      ctx.fillStyle = COL.textDim;
      ctx.font = '9px monospace';
      ctx.fillText(
        'Skip the skill and proceed.',
        x + 10, y + 36);
    }
  }

  drawReactionOption(x, y, w, h, label,
    labelCol, diceText, descText) {
    const ctx = this.ctx;
    ctx.fillStyle = COL.btnNorm;
    ctx.fillRect(x, y, w, h);
    ctx.strokeStyle = labelCol;
    ctx.lineWidth = 2;
    ctx.strokeRect(x, y, w, h);
    ctx.lineWidth = 1;
    ctx.fillStyle = labelCol;
    ctx.font = 'bold 13px monospace';
    ctx.fillText(label, x + 10, y + 20);
    ctx.fillStyle = COL.text;
    ctx.font = '11px monospace';
    ctx.fillText(diceText,
      x + 140, y + 20);
    ctx.fillStyle = COL.textDim;
    ctx.font = '9px monospace';
    ctx.fillText(descText,
      x + 10, y + 40);
  }

  renderCombatEnd(title, color) {
    const ctx = this.ctx;
    ctx.fillStyle = COL.bg;
    ctx.fillRect(0, 0, CW, CH);
    this.drawTextC(title, color, 36,
      CH / 2 - 30);
    this.drawTextC(
      'Press R to return to title',
      COL.textDim, 12, CH / 2 + 20);
    // Show a short summary
    if (this.combat) {
      this.drawTextC('Rounds: '
        + this.combat.round,
        COL.text, 11, CH / 2 + 50);
    }
  }

  // ========== COMBAT: INPUT ==========
  handleCombatKey(code) {
    const c = this.combat;
    if (!c) return;
    if (c.phase === CP_PLAYER_SKILL) {
      const psc = c.pendingSkillChoice;
      if (!psc) return;
      // 1-9 maps to available skill indices
      if (code >= KEY_1
        && code < KEY_1 + psc.available.length) {
        const i = code - KEY_1;
        this.playerChooseSkill(
          psc.available[i]);
        return;
      }
      // 0 or ESC = no skill
      if (code === 48 || code === KEY_ESC) {
        this.playerChooseSkill(-1);
        return;
      }
      return;
    }
    if (c.phase === CP_PLAYER_REACT) {
      if (code === KEY_1) {
        this.playerChooseReaction('block');
      } else if (code === KEY_1 + 1) {
        this.playerChooseReaction('counter');
      } else if (code === KEY_1 + 2) {
        this.playerChooseReaction('evade');
      } else if (code === KEY_1 + 3) {
        this.playerChooseReaction('takehit');
      }
      return;
    }
    if (c.phase !== CP_IDLE) {
      if (code === KEY_ESC) {
        this.cancelAction();
      }
      return;
    }
    if (code === KEY_1) {
      this.startPlayerMove();
    } else if (code === KEY_1 + 1) {
      this.startPlayerAttack();
    } else if (code === KEY_ESC) {
      this.cancelAction();
    } else if (code === KEY_SPACE) {
      this.playerEndTurn();
    }
  }

  handleCombatClick(x, y) {
    const c = this.combat;
    if (!c) return;
    // Skill choice modal takes priority
    if (c.phase === CP_PLAYER_SKILL) {
      this.handleSkillChoiceClick(x, y);
      return;
    }
    // Reaction modal takes priority
    if (c.phase === CP_PLAYER_REACT) {
      this.handleReactionClick(x, y);
      return;
    }
    // Grid click
    const gx = GRID_X;
    const gy = GRID_Y;
    const g = c.grid;
    if (x >= gx && x < gx + g.w * TILE
      && y >= gy && y < gy + g.h * TILE) {
      const tx = Math.floor(
        (x - gx) / TILE);
      const ty = Math.floor(
        (y - gy) / TILE);
      this.handleGridClick(tx, ty);
      return;
    }
    // Action bar buttons
    const by = 495;
    if (this.hitTest(x, y,
      20, by + 12, 90, 24)) {
      this.startPlayerMove();
      return;
    }
    if (this.hitTest(x, y,
      120, by + 12, 90, 24)) {
      this.startPlayerAttack();
      return;
    }
    if (this.hitTest(x, y,
      220, by + 12, 110, 24)) {
      this.cancelAction();
      return;
    }
    if (this.hitTest(x, y,
      350, by + 12, 150, 24)) {
      this.resetDebugCombat();
      return;
    }
    // End Turn button
    if (this.hitTest(x, y, 10, 555, 200, 30)) {
      this.playerEndTurn();
      return;
    }
  }

  handleGridClick(tx, ty) {
    const c = this.combat;
    if (c.phase === CP_MOVING) {
      const key = tx + ',' + ty;
      if (c.moveRange
        && c.moveRange.visited[key]) {
        this.executePlayerMove(tx, ty);
      }
      return;
    }
    if (c.phase === CP_ATTACKING) {
      const key = tx + ',' + ty;
      if (c.atkRange && c.atkRange[key]) {
        // Find enemy at that tile
        const ids = Object.keys(c.combatants);
        for (let i = 0;
          i < ids.length; i++) {
          const cm = c.combatants[ids[i]];
          if (cm.hp <= 0) continue;
          if (cm.isPlayer) continue;
          if (cm.x === tx && cm.y === ty) {
            this.executePlayerAttack(ids[i]);
            return;
          }
        }
      }
      return;
    }
    // Idle phase: click a combatant to
    // inspect their loadout
    if (c.phase === CP_IDLE) {
      const ids = Object.keys(c.combatants);
      for (let i = 0; i < ids.length; i++) {
        const cm = c.combatants[ids[i]];
        if (cm.hp <= 0) continue;
        if (cm.x === tx && cm.y === ty) {
          c.inspectedId = ids[i];
          return;
        }
      }
      // Clicked empty tile: reset to player
      c.inspectedId = 'player';
    }
  }

  handleReactionClick(x, y) {
    const c = this.combat;
    const px = 120;
    const py = 100;
    const optY = py + 90;
    const optH = 60;
    const optW = 520;
    const options = ['block', 'counter',
      'evade', 'takehit'];
    for (let i = 0; i < 4; i++) {
      const oy = optY + i * (optH + 6);
      if (this.hitTest(x, y,
        px + 20, oy, optW, optH)) {
        this.playerChooseReaction(options[i]);
        return;
      }
    }
  }

  handleSkillChoiceClick(x, y) {
    const c = this.combat;
    const psc = c.pendingSkillChoice;
    if (!psc) return;
    const px = 120;
    const py = 100;
    const optY = py + 90;
    const optH = 70;
    const optW = 520;
    // Skill option rows
    for (let i = 0;
      i < psc.available.length; i++) {
      const oy = optY + i * (optH + 6);
      if (this.hitTest(x, y,
        px + 20, oy, optW, optH)) {
        this.playerChooseSkill(
          psc.available[i]);
        return;
      }
    }
    // No Skill row
    const noY = optY
      + psc.available.length * (optH + 6);
    if (this.hitTest(x, y,
      px + 20, noY, optW, optH)) {
      this.playerChooseSkill(-1);
      return;
    }
  }

  handleCombatHover(x, y) {
    const c = this.combat;
    if (!c) return;
    const gx = GRID_X;
    const gy = GRID_Y;
    const g = c.grid;
    c.hoveredTile = null;
    c.hoveredCombatant = null;
    if (x >= gx && x < gx + g.w * TILE
      && y >= gy && y < gy + g.h * TILE) {
      const tx = Math.floor(
        (x - gx) / TILE);
      const ty = Math.floor(
        (y - gy) / TILE);
      c.hoveredTile = { x: tx, y: ty };
      // Check for combatant
      const ids = Object.keys(c.combatants);
      for (let i = 0; i < ids.length; i++) {
        const cm = c.combatants[ids[i]];
        if (cm.hp <= 0) continue;
        if (cm.x === tx && cm.y === ty) {
          c.hoveredCombatant = ids[i];
          break;
        }
      }
    }
  }
}

// ========== ACQUIRED KEYS ==========
// Acquire every key the player might press so
// that BYOND hotkeys (chat 'T', etc.) do not
// fire while the arcade window is focused.
const ACQUIRED_KEYS = (() => {
  const keys = [
    KEY_ESC, KEY_ENTER, KEY_TAB,
    KEY_BACKSPACE, KEY_SPACE,
    KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT,
    // Punctuation
    186, 187, 188, 189, 190, 191,
    192, 219, 220, 221, 222,
    // Numpad 0-9 and operators
    96, 97, 98, 99, 100, 101,
    102, 103, 104, 105,
    106, 107, 109, 110, 111,
  ];
  // Digits 0-9
  for (let i = 48; i <= 57; i++) keys.push(i);
  // Letters A-Z
  for (let i = 65; i <= 90; i++) keys.push(i);
  return keys;
})();

// ========== INFERNO COMPONENT ==========
class ArcadePMTTRPGComp extends Component {
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
    this.engine = new PMTTRPGEngine(
      canvas, this.props.act
    );
    const sd = this.props.data;
    if (sd) this.engine.loadData(sd);
    this.engine.start();
    canvas.focus();
  }

  componentDidUpdate(prevProps) {
    if (!this.engine) return;
    const sd = this.props.data;
    if (sd && sd !== prevProps.data) {
      this.engine.loadData(sd);
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

// ========== EXPORT ==========
export const ArcadePMTTRPG = (
  props, context
) => {
  const { act, data } = useBackend(context);
  return (
    <Window
      width={CW + 30}
      height={CH + 50}>
      <Window.Content>
        <ArcadePMTTRPGComp
          act={act}
          data={data}
        />
      </Window.Content>
    </Window>
  );
};
