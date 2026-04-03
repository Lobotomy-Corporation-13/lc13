/**
 * @file
 * @copyright 2024
 * @license MIT
 *
 * Great Lake Trawler - Dredge-inspired
 * fishing arcade. U Corp District 21.
 * Fish, manage cargo, sell at port,
 * survive the night.
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

const CW = 480;
const CH = 420;
const TL = 12;
const MW = 40;
const MH = 30;
const MAP_H = 360;
const HUD_TOP = 20;
const HUD_BOT = 40;

const T_WATER = 0;
const T_LAND = 1;
const T_PORT = 2;
const T_REEF = 3;

const KEY_W = 87;
const KEY_A = 65;
const KEY_S = 83;
const KEY_D = 68;
const KEY_UP = 38;
const KEY_DOWN = 40;
const KEY_LEFT = 37;
const KEY_RIGHT = 39;
const KEY_SPACE = 32;
const KEY_R = 82;
const KEY_ENTER = 13;
const KEY_ESC = 27;

const GS_TITLE = 0;
const GS_PLAY = 1;
const GS_FISH = 2;
const GS_CARGO = 3;
const GS_PORT = 4;
const GS_DEAD = 5;
const GS_WIN = 6;

const DAY_LEN = 90;
const NIGHT_LEN = 30;
const NUM_DAYS = 3;
const BOAT_SPD = 50;
const BOAT_REEF = 25;

// Fish definitions
// [name,shape,value,weight,tier,nightOnly,clr]
// shape: array of [dx,dy] offsets
const FISH = [
  ['Lake Shrimp', [[0, 0]],
    5, 30, 0, false, '#ff9966'],
  ['Mudskipper', [[0, 0], [1, 0]],
    10, 25, 0, false, '#88aa66'],
  ['Lake Perch', [[0, 0], [1, 0]],
    15, 20, 0, false, '#66aacc'],
  ['Trash Crab',
    [[0, 0], [1, 0], [2, 0], [1, 1]],
    20, 15, 1, false, '#aa6644'],
  ['P. Lamprey', [[0, 0], [0, 1]],
    25, 12, 1, false, '#775566'],
  ['Lake Pike',
    [[0, 0], [1, 0], [2, 0]],
    30, 8, 2, false, '#5588aa'],
  ['Pallid Tuna',
    [[0, 0], [0, 1], [1, 1]],
    40, 6, 2, false, '#99aabb'],
  ['Lovestruck',
    [[0, 0], [1, 0]],
    50, 10, 3, true, '#ff66aa'],
  ['Abyssal Eel',
    [[0, 0], [0, 1]],
    60, 8, 3, true, '#6644aa'],
  ['Fishmael', [[0, 0]],
    100, 2, 4, true, '#ffdd44'],
];

// Tier: [speed(rev/s), greenDeg, hits]
// Fast fish = fewer hits, slow big = more
const TIERS = [
  [1.0, 90, 1],
  [1.2, 70, 1],
  [1.0, 60, 2],
  [1.4, 50, 1],
  [1.6, 40, 2],
];

// Pixel art for each fish (drawn in cell)
// Each is a function(ctx, x, y, s) where
// s = cell size
const FISH_ART = {
  'Lake Shrimp': (ctx, x, y, s) => {
    ctx.fillStyle = '#ff9966';
    ctx.fillRect(x + 2, y + 4, s - 4, 3);
    ctx.fillRect(x + s - 5, y + 3, 2, 2);
    ctx.fillStyle = '#cc7744';
    ctx.fillRect(x + 1, y + 5, 2, 2);
    ctx.fillRect(x + 3, y + 6, 2, 2);
  },
  'Mudskipper': (ctx, x, y, s) => {
    ctx.fillStyle = '#88aa66';
    ctx.fillRect(x + 2, y + 3, s - 4, 5);
    ctx.fillStyle = '#667744';
    ctx.fillRect(x + s - 4, y + 2, 3, 2);
    ctx.fillRect(x + s - 4, y + 7, 3, 2);
    ctx.fillStyle = '#222';
    ctx.fillRect(x + 3, y + 4, 2, 2);
  },
  'Lake Perch': (ctx, x, y, s) => {
    ctx.fillStyle = '#66aacc';
    ctx.fillRect(x + 3, y + 2, s - 6, 6);
    ctx.fillStyle = '#4488aa';
    ctx.fillRect(x + 1, y + 4, 3, 3);
    ctx.fillRect(x + s - 5, y + 1, 2, 3);
    ctx.fillStyle = '#222';
    ctx.fillRect(x + s - 5, y + 4, 2, 2);
  },
  'Trash Crab': (ctx, x, y, s) => {
    ctx.fillStyle = '#aa6644';
    ctx.fillRect(x + 2, y + 3, s - 4, 4);
    ctx.fillStyle = '#884422';
    ctx.fillRect(x + 1, y + 2, 2, 3);
    ctx.fillRect(x + s - 3, y + 2, 2, 3);
    ctx.fillStyle = '#222';
    ctx.fillRect(x + 4, y + 4, 1, 1);
    ctx.fillRect(x + 7, y + 4, 1, 1);
  },
  'P. Lamprey': (ctx, x, y, s) => {
    ctx.fillStyle = '#775566';
    ctx.fillRect(x + 3, y + 1, 4, s - 2);
    ctx.fillStyle = '#995577';
    ctx.fillRect(x + 4, y + 1, 2, 3);
    ctx.fillStyle = '#222';
    ctx.fillRect(x + 4, y + 2, 1, 1);
    ctx.fillRect(x + 6, y + 2, 1, 1);
  },
  'Lake Pike': (ctx, x, y, s) => {
    ctx.fillStyle = '#5588aa';
    ctx.fillRect(x + 2, y + 3, s - 4, 4);
    ctx.fillStyle = '#336688';
    ctx.fillRect(x + 1, y + 4, 2, 2);
    ctx.fillRect(x + s - 3, y + 2, 3, 2);
    ctx.fillRect(x + s - 3, y + 7, 3, 2);
    ctx.fillStyle = '#222';
    ctx.fillRect(x + s - 4, y + 4, 2, 1);
  },
  'Pallid Tuna': (ctx, x, y, s) => {
    ctx.fillStyle = '#99aabb';
    ctx.fillRect(x + 2, y + 2, s - 4, 6);
    ctx.fillStyle = '#778899';
    ctx.fillRect(x + 1, y + 4, 2, 3);
    ctx.fillRect(x + s - 4, y + 1, 3, 3);
    ctx.fillStyle = '#222';
    ctx.fillRect(x + s - 4, y + 4, 2, 2);
  },
  'Lovestruck': (ctx, x, y, s) => {
    ctx.fillStyle = '#ff66aa';
    ctx.fillRect(x + 2, y + 2, s - 4, 6);
    ctx.fillStyle = '#ff99cc';
    ctx.fillRect(x + 3, y + 3, 4, 2);
    ctx.fillStyle = '#cc2266';
    ctx.fillRect(x + s - 4, y + 3, 2, 4);
    ctx.fillStyle = '#222';
    ctx.fillRect(x + s - 4, y + 4, 1, 1);
  },
  'Abyssal Eel': (ctx, x, y, s) => {
    ctx.fillStyle = '#6644aa';
    ctx.fillRect(x + 3, y + 1, 4, s - 2);
    ctx.fillStyle = '#8855cc';
    ctx.fillRect(x + 4, y + 1, 2, 4);
    ctx.fillStyle = '#ff4444';
    ctx.fillRect(x + 4, y + 2, 1, 1);
    ctx.fillRect(x + 6, y + 2, 1, 1);
  },
  'Fishmael': (ctx, x, y, s) => {
    ctx.fillStyle = '#ffdd44';
    ctx.fillRect(x + 2, y + 2, s - 4, 6);
    ctx.fillStyle = '#ffaa00';
    ctx.fillRect(x + 1, y + 4, 2, 2);
    ctx.fillRect(x + s - 3, y + 1, 2, 3);
    ctx.fillRect(x + s - 3, y + 7, 2, 2);
    ctx.fillStyle = '#ff2200';
    ctx.fillRect(x + s - 4, y + 4, 2, 2);
  },
};

// Colors
const C_WATER = '#1a3a5a';
const C_WATER_N = '#0a1525';
const C_LAND = '#4a6a3a';
const C_PORT = '#8a6a3a';
const C_REEF = '#3a7a6a';
const C_BOAT = '#dddddd';
const C_AHN = '#ffcc44';

// =========================================
// Game Engine
// =========================================

class GreatLakeEngine {
  constructor(canvas, act) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.act = act;
    this.keys = {};
    this.state = GS_TITLE;
    this.rafId = null;
    this.lastTime = 0;

    // Map
    this.cells = null;
    this.fishSpots = [];
    this.ports = [];
    this.whalePath = [];

    // Boat
    this.bx = 0;
    this.by = 0;
    this.bdir = 0;
    this.bspd = BOAT_SPD;

    // Time
    this.day = 0;
    this.dayTimer = 0;
    this.isNight = false;
    this.panic = 0;
    this.totalTime = 0;

    // Economy
    this.ahn = 0;

    // Cargo grid
    this.cargoW = 5;
    this.cargoH = 4;
    this.grid = [];
    this.cargoFish = [];
    this.cargoCount = 0;

    // Placing piece
    this.piece = null;
    this.pieceX = 0;
    this.pieceY = 0;

    // Fishing
    this.fAngle = 0;
    this.fSpeed = 0;
    this.fGreen = 0;
    this.fGreenStart = 0;
    this.fHits = 0;
    this.fNeeded = 0;
    this.fDef = null;
    this.fSpot = -1;
    this.spotCooldowns = [];

    // Port menu
    this.portIdx = 0;
    this.portSel = 0;
    this.upgrades = {
      hold: false,
      lantern: false,
      hull: false,
      rod: false,
    };

    // Whale
    this.wx = 0;
    this.wy = 0;
    this.wIdx = 0;
    this.wSpd = 30;

    // Leaderboard
    this.leaderboard = [];

    // Message
    this.msg = '';
    this.msgTimer = 0;
  }

  loadData(sd) {
    if (sd.map) {
      this.cells = sd.map.cells;
    }
    this.fishSpots = sd.fishSpots || [];
    this.ports = sd.ports || [];
    this.whalePath = sd.whalePath || [];
    this.spotCooldowns = [];
    for (let i = 0;
      i < this.fishSpots.length; i++) {
      this.spotCooldowns.push(0);
    }
  }

  initGame() {
    this.day = 0;
    this.ahn = 0;
    this.panic = 0;
    this.bspd = BOAT_SPD;
    this.cargoW = 5;
    this.cargoH = 4;
    this.upgrades = {
      hold: false,
      lantern: false,
      hull: false,
      rod: false,
    };
    this.resetGrid();
    this.startDay();
  }

  resetGrid() {
    this.grid = [];
    for (let y = 0; y < this.cargoH; y++) {
      const row = [];
      for (let x = 0; x < this.cargoW; x++) {
        row.push(null);
      }
      this.grid.push(row);
    }
    this.cargoFish = [];
    this.cargoCount = 0;
  }

  startDay() {
    this.dayTimer = DAY_LEN;
    this.isNight = false;
    this.panic = 0;
    // Place boat at first port
    if (this.ports.length > 0) {
      this.bx = this.ports[0].x * TL + TL / 2;
      this.by = this.ports[0].y * TL + TL / 2;
    }
    // Reset whale
    if (this.whalePath.length > 0) {
      this.wx = this.whalePath[0].x * TL;
      this.wy = this.whalePath[0].y * TL;
      this.wIdx = 0;
      this.wSpd = 30 + this.day * 15;
    }
    this.msg = 'Day ' + (this.day + 1);
    this.msgTimer = 2;
  }

  getCell(gx, gy) {
    if (gx < 0 || gx >= MW
      || gy < 0 || gy >= MH) {
      return T_LAND;
    }
    return this.cells[gy * MW + gx];
  }

  isWalkable(gx, gy) {
    const c = this.getCell(gx, gy);
    return c !== T_LAND;
  }

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
    this.update(dt);
    this.render();
    this.rafId = requestAnimationFrame(
      t => this.loop(t)
    );
  }

  // ==================
  // UPDATE
  // ==================

  update(dt) {
    if (this.state !== GS_PLAY
      && this.state !== GS_FISH) return;

    if (this.msgTimer > 0) this.msgTimer -= dt;

    // Spot cooldowns
    for (let i = 0;
      i < this.spotCooldowns.length; i++) {
      if (this.spotCooldowns[i] > 0) {
        this.spotCooldowns[i] -= dt;
      }
    }

    // Day/night timer
    if (this.state === GS_PLAY) {
      this.dayTimer -= dt;
      if (this.dayTimer <= 0) {
        if (!this.isNight) {
          // Transition to night
          this.isNight = true;
          this.dayTimer = NIGHT_LEN;
          this.msg = 'NIGHT FALLS...';
          this.msgTimer = 2;
          this.act('sfx', { s: 'night' });
        } else {
          // Night ended
          this.day++;
          if (this.day >= NUM_DAYS) {
            this.ahn += 200;
            this.state = GS_WIN;
            this.act('submit_score', {
              score: this.ahn,
            });
            return;
          }
          this.startDay();
        }
      }

      // Boat movement
      this.updateBoat(dt);

      // Whale (night only)
      if (this.isNight) {
        this.updateWhale(dt);
        this.updatePanic(dt);
      }
    }

    // Fishing minigame
    if (this.state === GS_FISH) {
      this.fAngle += this.fSpeed
        * Math.PI * 2 * dt;
      if (this.fAngle > Math.PI * 2) {
        this.fAngle -= Math.PI * 2;
      }
    }
  }

  updateBoat(dt) {
    let mx = 0;
    let my = 0;
    if (this.keys[KEY_W]
      || this.keys[KEY_UP]) my = -1;
    if (this.keys[KEY_S]
      || this.keys[KEY_DOWN]) my = 1;
    if (this.keys[KEY_A]
      || this.keys[KEY_LEFT]) mx = -1;
    if (this.keys[KEY_D]
      || this.keys[KEY_RIGHT]) mx = 1;

    if (mx === 0 && my === 0) return;

    // Direction
    this.bdir = Math.atan2(my, mx);

    // Speed check (reef)
    const gx = Math.floor(this.bx / TL);
    const gy = Math.floor(this.by / TL);
    const onReef = this.getCell(gx, gy)
      === T_REEF;
    const spd = onReef
      ? this.bspd * 0.5 : this.bspd;

    const r = 4;
    const nx = this.bx + mx * spd * dt;
    const ny = this.by + my * spd * dt;

    // X collision
    const cgx = Math.floor(
      (nx + (mx > 0 ? r : -r)) / TL
    );
    if (this.isWalkable(
      cgx, Math.floor(this.by / TL)
    )) {
      this.bx = nx;
    }
    // Y collision
    const cgy = Math.floor(
      (ny + (my > 0 ? r : -r)) / TL
    );
    if (this.isWalkable(
      Math.floor(this.bx / TL), cgy
    )) {
      this.by = ny;
    }

    // Clamp
    this.bx = Math.max(
      r, Math.min(MW * TL - r, this.bx)
    );
    this.by = Math.max(
      r, Math.min(MH * TL - r, this.by)
    );
  }

  updateWhale(dt) {
    if (!this.whalePath.length) return;
    const wp = this.whalePath[this.wIdx];
    const tx = wp.x * TL;
    const ty = wp.y * TL;
    const dx = tx - this.wx;
    const dy = ty - this.wy;
    const d = Math.sqrt(dx * dx + dy * dy);
    if (d < 5) {
      this.wIdx = (this.wIdx + 1)
        % this.whalePath.length;
    } else {
      this.wx += (dx / d) * this.wSpd * dt;
      this.wy += (dy / d) * this.wSpd * dt;
    }
    // Check collision
    const bdx = this.bx - this.wx;
    const bdy = this.by - this.wy;
    if (bdx * bdx + bdy * bdy < 400) {
      this.state = GS_DEAD;
      this.msg = 'CONSUMED BY THE DEEP';
      this.act('died');
      this.act('sfx', { s: 'whale' });
    }
  }

  updatePanic(dt) {
    // Check if at port
    const gx = Math.floor(this.bx / TL);
    const gy = Math.floor(this.by / TL);
    if (this.getCell(gx, gy) === T_PORT) {
      this.panic = 0;
      return;
    }
    // Near whale?
    const dx = this.bx - this.wx;
    const dy = this.by - this.wy;
    const near = dx * dx + dy * dy < 10000;
    this.panic += (near ? 4 : 2) * dt;
    if (this.panic >= 100) {
      this.panic = 100;
      this.state = GS_DEAD;
      this.msg = 'LOST TO PANIC';
      this.act('died');
    }
  }

  // ==================
  // FISHING
  // ==================

  nearSpot() {
    for (let i = 0;
      i < this.fishSpots.length; i++) {
      if (this.spotCooldowns[i] > 0) {
        continue;
      }
      const s = this.fishSpots[i];
      const dx = s.x * TL + TL / 2
        - this.bx;
      const dy = s.y * TL + TL / 2
        - this.by;
      if (dx * dx + dy * dy < 400) {
        return i;
      }
    }
    return -1;
  }

  startFishing(si) {
    // Pick fish
    const pool = [];
    let totalW = 0;
    for (let i = 0; i < FISH.length; i++) {
      const f = FISH[i];
      if (f[5] && !this.isNight) continue;
      pool.push(i);
      totalW += f[3];
    }
    let r = Math.random() * totalW;
    let fi = pool[0];
    for (let i = 0; i < pool.length; i++) {
      r -= FISH[pool[i]][3];
      if (r <= 0) { fi = pool[i]; break; }
    }
    const def = FISH[fi];
    const tier = TIERS[def[4]];

    this.fDef = def;
    this.fSpot = si;
    this.fAngle = 0;
    this.fSpeed = this.upgrades.rod
      ? tier[0] * 0.7 : tier[0];
    this.fGreen = tier[1] * Math.PI / 180;
    this.fGreenStart = Math.random()
      * Math.PI * 2;
    this.fNeeded = tier[2];
    this.fHits = 0;
    this.state = GS_FISH;
  }

  checkFishHit() {
    // Is marker in green zone?
    let a = this.fAngle % (Math.PI * 2);
    let gs = this.fGreenStart;
    let ge = gs + this.fGreen;
    // Normalize
    if (a < 0) a += Math.PI * 2;
    const inZone = (ge <= Math.PI * 2)
      ? (a >= gs && a <= ge)
      : (a >= gs || a <= ge - Math.PI * 2);

    if (inZone) {
      this.fHits++;
      this.act('sfx', { s: 'splash' });
      if (this.fHits >= this.fNeeded) {
        // Caught!
        this.act('sfx', { s: 'catch' });
        this.spotCooldowns[this.fSpot] = 10;
        this.startPlacement(this.fDef);
        return;
      }
      // Move green zone for next hit
      this.fGreenStart = Math.random()
        * Math.PI * 2;
    } else {
      // Miss - back to sailing
      this.msg = 'Missed!';
      this.msgTimer = 1;
      this.state = GS_PLAY;
    }
  }

  // ==================
  // CARGO
  // ==================

  startPlacement(def) {
    this.piece = def;
    this.pieceX = 0;
    this.pieceY = 0;
    this.state = GS_CARGO;
  }

  canFit(shape, px, py) {
    for (let i = 0; i < shape.length; i++) {
      const cx = px + shape[i][0];
      const cy = py + shape[i][1];
      if (cx < 0 || cx >= this.cargoW
        || cy < 0 || cy >= this.cargoH) {
        return false;
      }
      if (this.grid[cy][cx] !== null) {
        return false;
      }
    }
    return true;
  }

  placePiece() {
    if (!this.piece) return;
    const shape = this.piece[1];
    if (!this.canFit(
      shape, this.pieceX, this.pieceY
    )) return;
    const idx = this.cargoFish.length;
    for (let i = 0; i < shape.length; i++) {
      const cx = this.pieceX + shape[i][0];
      const cy = this.pieceY + shape[i][1];
      this.grid[cy][cx] = idx;
    }
    this.cargoFish.push(this.piece);
    this.cargoCount += shape.length;
    this.piece = null;
    this.state = GS_PLAY;
    this.msg = this.cargoFish[idx][0]
      + ' stored!';
    this.msgTimer = 1.5;
  }

  rotatePiece() {
    if (!this.piece) return;
    // Rotate shape 90 degrees CW
    const shape = this.piece[1];
    const rotated = [];
    for (let i = 0; i < shape.length; i++) {
      rotated.push([-shape[i][1],
        shape[i][0]]);
    }
    // Normalize to positive coords
    let minX = 0;
    let minY = 0;
    for (let i = 0; i < rotated.length; i++) {
      if (rotated[i][0] < minX) {
        minX = rotated[i][0];
      }
      if (rotated[i][1] < minY) {
        minY = rotated[i][1];
      }
    }
    for (let i = 0; i < rotated.length; i++) {
      rotated[i][0] -= minX;
      rotated[i][1] -= minY;
    }
    // Create rotated copy
    this.piece = [
      this.piece[0], rotated,
      this.piece[2], this.piece[3],
      this.piece[4], this.piece[5],
      this.piece[6],
    ];
  }

  discardPiece() {
    this.piece = null;
    this.state = GS_PLAY;
    this.msg = 'Discarded';
    this.msgTimer = 1;
  }

  // ==================
  // PORT
  // ==================

  nearPort() {
    const gx = Math.floor(this.bx / TL);
    const gy = Math.floor(this.by / TL);
    if (this.getCell(gx, gy) !== T_PORT) {
      return -1;
    }
    for (let i = 0;
      i < this.ports.length; i++) {
      const p = this.ports[i];
      const dx = gx - p.x;
      const dy = gy - p.y;
      if (Math.abs(dx) <= 1
        && Math.abs(dy) <= 1) {
        return i;
      }
    }
    return -1;
  }

  openPort(pi) {
    this.portIdx = pi;
    this.portSel = 0;
    this.state = GS_PORT;
  }

  sellAll() {
    if (this.cargoFish.length === 0) return;
    let total = 0;
    let crabs = 0;
    for (let i = 0;
      i < this.cargoFish.length; i++) {
      const f = this.cargoFish[i];
      total += f[2];
      if (f[0] === 'Trash Crab') crabs++;
    }
    // Full hold bonus
    const maxCells = this.cargoW
      * this.cargoH;
    if (this.cargoCount >= maxCells) {
      total = Math.floor(total * 1.2);
    }
    // Trash Crab Wine bonus
    if (crabs >= 3) total += 30;
    // Twinhook night bonus
    const p = this.ports[this.portIdx];
    if (p && p.name === 'Twinhook Cove'
      && this.isNight) {
      total = Math.floor(total * 1.5);
    }
    this.ahn += total;
    this.msg = 'Sold for ' + total + ' Ahn!';
    this.msgTimer = 2;
    this.resetGrid();
    this.act('sfx', { s: 'sell' });
  }

  buyUpgrade(id) {
    const costs = {
      hold: 100, lantern: 80,
      hull: 120, rod: 90,
    };
    const cost = costs[id];
    if (!cost || this.upgrades[id]) return;
    if (this.ahn < cost) return;
    this.ahn -= cost;
    this.upgrades[id] = true;
    if (id === 'hold') {
      this.cargoW = 6;
      this.resetGrid();
    }
    if (id === 'hull') {
      this.bspd = 65;
    }
    this.msg = 'Upgraded!';
    this.msgTimer = 1.5;
  }

  // ==================
  // RENDER
  // ==================

  render() {
    const ctx = this.ctx;
    ctx.fillStyle = '#0a0a15';
    ctx.fillRect(0, 0, CW, CH);

    if (this.state === GS_TITLE) {
      this.renderTitle();
      return;
    }

    // Camera
    const camX = Math.max(0, Math.min(
      MW * TL - CW,
      this.bx - CW / 2
    ));
    const camY = Math.max(0, Math.min(
      MH * TL - MAP_H,
      this.by - MAP_H / 2
    ));

    ctx.save();
    ctx.translate(0, HUD_TOP);

    // Map tiles
    const waterC = this.isNight
      ? C_WATER_N : C_WATER;
    const sg = Math.floor(camX / TL);
    const sy = Math.floor(camY / TL);
    const eg = Math.min(
      MW, sg + Math.ceil(CW / TL) + 1
    );
    const eyg = Math.min(
      MH, sy + Math.ceil(MAP_H / TL) + 1
    );
    for (let gy = sy; gy < eyg; gy++) {
      for (let gx = sg; gx < eg; gx++) {
        const c = this.getCell(gx, gy);
        const sx = gx * TL - camX;
        const syy = gy * TL - camY;
        switch (c) {
          case T_WATER:
            ctx.fillStyle = waterC;
            ctx.fillRect(
              sx, syy, TL, TL
            );
            break;
          case T_LAND:
            ctx.fillStyle = C_LAND;
            ctx.fillRect(
              sx, syy, TL, TL
            );
            break;
          case T_PORT:
            ctx.fillStyle = C_PORT;
            ctx.fillRect(
              sx, syy, TL, TL
            );
            break;
          case T_REEF:
            ctx.fillStyle = C_REEF;
            ctx.fillRect(
              sx, syy, TL, TL
            );
            break;
          default: break;
        }
      }
    }

    // Fish spots
    for (let i = 0;
      i < this.fishSpots.length; i++) {
      const s = this.fishSpots[i];
      const sx = s.x * TL + TL / 2 - camX;
      const syy = s.y * TL + TL / 2 - camY;
      if (sx < -20 || sx > CW + 20
        || syy < -20 || syy > MAP_H + 20) {
        continue;
      }
      const cool = this.spotCooldowns[i] > 0;
      if (cool) continue;
      const pulse = Math.sin(
        performance.now() * 0.005 + i
      );
      ctx.fillStyle = this.isNight
        ? '#8844aa' : '#44aaff';
      ctx.beginPath();
      ctx.arc(
        sx, syy, 3 + pulse,
        0, Math.PI * 2
      );
      ctx.fill();
    }

    // Port labels
    for (let i = 0;
      i < this.ports.length; i++) {
      const p = this.ports[i];
      const sx = p.x * TL - camX;
      const syy = p.y * TL - camY - 8;
      ctx.fillStyle = '#ffcc44';
      ctx.font = '7px monospace';
      ctx.fillText(
        p.name, sx - 15, syy
      );
    }

    // Whale (night)
    if (this.isNight) {
      const wsx = this.wx - camX;
      const wsy = this.wy - camY;
      const vis = this.upgrades.lantern
        ? 120 : 80;
      const dx = this.bx - this.wx;
      const dy = this.by - this.wy;
      const wd = Math.sqrt(
        dx * dx + dy * dy
      );
      if (wd < vis + 30) {
        ctx.fillStyle = '#1a1a2a';
        ctx.beginPath();
        ctx.ellipse(
          wsx, wsy, 20, 10,
          0, 0, Math.PI * 2
        );
        ctx.fill();
        // Eyes
        ctx.fillStyle = '#aaaa44';
        ctx.fillRect(
          wsx - 6, wsy - 3, 3, 3
        );
        ctx.fillRect(
          wsx + 3, wsy - 3, 3, 3
        );
      }
    }

    // Boat
    const bsx = this.bx - camX;
    const bsy = this.by - camY;
    ctx.fillStyle = C_BOAT;
    ctx.save();
    ctx.translate(bsx, bsy);
    ctx.rotate(this.bdir);
    ctx.beginPath();
    ctx.moveTo(6, 0);
    ctx.lineTo(-4, -4);
    ctx.lineTo(-4, 4);
    ctx.closePath();
    ctx.fill();
    ctx.restore();

    // Night overlay
    if (this.isNight) {
      const vis = this.upgrades.lantern
        ? 120 : 80;
      const grad = ctx.createRadialGradient(
        bsx, bsy, vis * 0.3,
        bsx, bsy, vis
      );
      grad.addColorStop(
        0, 'rgba(0,0,20,0)'
      );
      grad.addColorStop(
        1, 'rgba(0,0,20,0.92)'
      );
      ctx.fillStyle = grad;
      ctx.fillRect(0, 0, CW, MAP_H);
    }

    ctx.restore();

    // HUD
    this.renderHUD();

    // Overlays
    if (this.state === GS_FISH) {
      this.renderFishing();
    }
    if (this.state === GS_CARGO) {
      this.renderCargoOverlay();
    }
    if (this.state === GS_PORT) {
      this.renderPortMenu();
    }

    // Message
    if (this.msgTimer > 0) {
      const a = Math.min(
        1, this.msgTimer
      ).toFixed(2);
      ctx.fillStyle = 'rgba(255,255,255,'
        + a + ')';
      ctx.font = '11px monospace';
      const w = ctx.measureText(
        this.msg
      ).width;
      ctx.fillText(
        this.msg,
        (CW - w) / 2,
        HUD_TOP + MAP_H / 2 - 20
      );
    }

    // Death/Win
    if (this.state === GS_DEAD) {
      ctx.fillStyle = 'rgba(100,0,0,0.6)';
      ctx.fillRect(0, 0, CW, CH);
      this.cText(this.msg, '#ff4444', 14);
      this.cText(
        'Ahn: ' + this.ahn, '#fff', 10, 22
      );
      this.cText(
        'Press R to retry', '#aaa', 8, 42
      );
    }
    if (this.state === GS_WIN) {
      ctx.fillStyle = 'rgba(0,0,0,0.6)';
      ctx.fillRect(0, 0, CW, CH);
      this.cText(
        'SURVIVED ALL 3 NIGHTS!',
        '#ffcc44', 14
      );
      this.cText(
        'Final: ' + this.ahn + ' Ahn',
        '#fff', 10, 22
      );
      this.cText(
        'Press R to play again',
        '#aaa', 8, 42
      );
    }
  }

  renderHUD() {
    const ctx = this.ctx;
    // Top HUD
    ctx.fillStyle = '#111';
    ctx.fillRect(0, 0, CW, HUD_TOP);
    ctx.fillStyle = '#fff';
    ctx.font = '9px monospace';
    ctx.fillText(
      'Day ' + (this.day + 1) + '/'
        + NUM_DAYS, 4, 14
    );
    const secs = Math.ceil(this.dayTimer);
    ctx.fillText(
      (this.isNight ? 'NIGHT ' : '')
        + secs + 's',
      80, 14
    );
    ctx.fillStyle = C_AHN;
    ctx.fillText(
      this.ahn + ' Ahn', 170, 14
    );
    // Panic (night)
    if (this.isNight && this.panic > 0) {
      ctx.fillStyle = '#333';
      ctx.fillRect(280, 4, 80, 10);
      ctx.fillStyle = '#cc4444';
      ctx.fillRect(
        280, 4,
        80 * (this.panic / 100), 10
      );
      ctx.fillStyle = '#fff';
      ctx.font = '7px monospace';
      ctx.fillText('PANIC', 282, 12);
    }

    // Nearby prompts
    if (this.state === GS_PLAY) {
      const si = this.nearSpot();
      const pi = this.nearPort();
      ctx.font = '8px monospace';
      if (si >= 0) {
        ctx.fillStyle = '#44aaff';
        ctx.fillText(
          '[SPACE] Fish', 400, 14
        );
      } else if (pi >= 0) {
        ctx.fillStyle = '#ffcc44';
        ctx.fillText(
          '[SPACE] Port', 400, 14
        );
      }
    }

    // Bottom HUD - mini cargo grid
    const by = CH - HUD_BOT;
    ctx.fillStyle = '#111';
    ctx.fillRect(0, by, CW, HUD_BOT);
    const cs = 6;
    const gox = 6;
    const goy = by + 6;
    for (let cy = 0; cy < this.cargoH; cy++) {
      for (let cx = 0;
        cx < this.cargoW; cx++) {
        const v = this.grid[cy]
          ? this.grid[cy][cx] : null;
        if (v !== null
          && this.cargoFish[v]) {
          ctx.fillStyle
            = this.cargoFish[v][6];
        } else {
          ctx.fillStyle = '#222';
        }
        ctx.fillRect(
          gox + cx * cs,
          goy + cy * cs,
          cs - 1, cs - 1
        );
      }
    }
    ctx.fillStyle = '#aaa';
    ctx.font = '8px monospace';
    ctx.fillText(
      'Cargo: ' + this.cargoCount + '/'
        + (this.cargoW * this.cargoH),
      gox + this.cargoW * cs + 6,
      goy + 10
    );
    // Fish count
    ctx.fillText(
      'Fish: ' + this.cargoFish.length,
      gox + this.cargoW * cs + 6,
      goy + 22
    );
  }

  renderFishing() {
    const ctx = this.ctx;
    const cx = CW / 2;
    const cy = HUD_TOP + MAP_H / 2;
    const r = 60;

    // Dim background
    ctx.fillStyle = 'rgba(0,0,0,0.5)';
    ctx.fillRect(
      0, HUD_TOP, CW, MAP_H
    );

    // Circle
    ctx.strokeStyle = '#333';
    ctx.lineWidth = 8;
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.stroke();

    // Green zone
    ctx.strokeStyle = '#22cc44';
    ctx.lineWidth = 8;
    ctx.beginPath();
    ctx.arc(
      cx, cy, r,
      this.fGreenStart,
      this.fGreenStart + this.fGreen
    );
    ctx.stroke();
    ctx.lineWidth = 1;

    // Marker
    const mx = cx + Math.cos(
      this.fAngle
    ) * r;
    const my = cy + Math.sin(
      this.fAngle
    ) * r;
    ctx.fillStyle = '#ffffff';
    ctx.beginPath();
    ctx.arc(mx, my, 5, 0, Math.PI * 2);
    ctx.fill();

    // Fish name
    ctx.fillStyle = this.fDef[6];
    ctx.font = '10px monospace';
    const nm = this.fDef[0];
    const tw = ctx.measureText(nm).width;
    ctx.fillText(nm, cx - tw / 2, cy - r - 12);

    // Hits
    ctx.fillStyle = '#fff';
    ctx.font = '8px monospace';
    ctx.fillText(
      'Hits: ' + this.fHits
        + '/' + this.fNeeded,
      cx - 25, cy + r + 18
    );
    ctx.fillText(
      '[SPACE] catch  [ESC] cancel',
      cx - 75, cy + r + 30
    );
  }

  renderCargoOverlay() {
    const ctx = this.ctx;
    // Dim
    ctx.fillStyle = 'rgba(0,0,0,0.6)';
    ctx.fillRect(0, HUD_TOP, CW, MAP_H);

    const cs = 20;
    const gw = this.cargoW * cs;
    const gh = this.cargoH * cs;
    const ox = (CW - gw) / 2;
    const oy = HUD_TOP + (MAP_H - gh) / 2
      - 20;

    // Title
    ctx.fillStyle = '#fff';
    ctx.font = '10px monospace';
    ctx.fillText(
      'Place: ' + this.piece[0],
      ox, oy - 8
    );

    // Grid with fish pixel art
    const drawn = new Set();
    for (let cy = 0; cy < this.cargoH; cy++) {
      for (let cx = 0;
        cx < this.cargoW; cx++) {
        const v = this.grid[cy]
          ? this.grid[cy][cx] : null;
        const sx = ox + cx * cs;
        const syy = oy + cy * cs;
        if (v !== null) {
          ctx.fillStyle = '#1a2a2a';
          ctx.fillRect(
            sx, syy, cs - 1, cs - 1
          );
          // Draw fish art once per fish
          if (!drawn.has(v)) {
            drawn.add(v);
            const f = this.cargoFish[v];
            const art = FISH_ART[f[0]];
            if (art) {
              art(ctx, sx, syy, cs);
            } else {
              ctx.fillStyle = f[6];
              ctx.fillRect(
                sx + 2, syy + 2,
                cs - 5, cs - 5
              );
            }
          }
        } else {
          ctx.fillStyle = '#1a2a2a';
          ctx.fillRect(
            sx, syy, cs - 1, cs - 1
          );
        }
      }
    }

    // Piece preview
    if (this.piece) {
      const shape = this.piece[1];
      const fits = this.canFit(
        shape, this.pieceX, this.pieceY
      );
      ctx.fillStyle = fits
        ? this.piece[6] : '#cc2222';
      for (let i = 0;
        i < shape.length; i++) {
        const px = this.pieceX + shape[i][0];
        const py = this.pieceY + shape[i][1];
        ctx.fillRect(
          ox + px * cs + 1,
          oy + py * cs + 1,
          cs - 3, cs - 3
        );
      }
    }

    // Controls
    ctx.fillStyle = '#aaa';
    ctx.font = '8px monospace';
    const iy = oy + gh + 12;
    ctx.fillText(
      'Arrows:move R:rotate', ox, iy
    );
    ctx.fillText(
      'SPACE:place  D:discard',
      ox, iy + 12
    );
  }

  renderPortMenu() {
    const ctx = this.ctx;
    ctx.fillStyle = 'rgba(0,0,0,0.7)';
    ctx.fillRect(0, HUD_TOP, CW, MAP_H);

    const p = this.ports[this.portIdx];
    const ox = CW / 2 - 100;
    let oy = HUD_TOP + 40;

    ctx.fillStyle = C_AHN;
    ctx.font = '12px monospace';
    ctx.fillText(
      p ? p.name : 'Port', ox, oy
    );
    oy += 20;

    const items = [
      ['Sell All ('
        + this.cargoFish.length
        + ' fish)', 'sell'],
    ];
    if (!this.upgrades.hold) {
      items.push(
        ['Bigger Hold (100 Ahn)', 'hold']
      );
    }
    if (!this.upgrades.lantern) {
      items.push(
        ['Lantern (80 Ahn)', 'lantern']
      );
    }
    if (!this.upgrades.hull) {
      items.push(
        ['Fast Hull (120 Ahn)', 'hull']
      );
    }
    if (!this.upgrades.rod) {
      items.push(
        ['Steady Rod (90 Ahn)', 'rod']
      );
    }
    items.push(['Leave', 'leave']);

    ctx.font = '9px monospace';
    for (let i = 0; i < items.length; i++) {
      const sel = i === this.portSel;
      ctx.fillStyle = sel
        ? '#ffcc44' : '#888';
      ctx.fillText(
        (sel ? '> ' : '  ')
          + items[i][0],
        ox, oy + i * 18
      );
    }

    // Store items ref for selection
    this.portItems = items;

    ctx.fillStyle = '#666';
    ctx.font = '8px monospace';
    ctx.fillText(
      'Up/Down:select  SPACE:confirm',
      ox, oy + items.length * 18 + 14
    );
    ctx.fillText(
      'Ahn: ' + this.ahn,
      ox, oy + items.length * 18 + 28
    );
  }

  renderTitle() {
    const ctx = this.ctx;
    ctx.strokeStyle = '#2266aa';
    ctx.lineWidth = 2;
    ctx.strokeRect(10, 10, CW - 20, CH - 20);

    this.cText(
      'GREAT LAKE TRAWLER',
      '#2266aa', 16, -80
    );
    this.cText(
      'U Corp. District 21',
      '#666', 8, -58
    );
    this.cText(
      'Fish the Great Lake.', '#aaa', 8, -34
    );
    this.cText(
      'Manage your cargo hold.', '#aaa', 8, -22
    );
    this.cText(
      'Sell at port for Ahn.', '#aaa', 8, -10
    );
    this.cText(
      'Survive 3 nights.', '#ff6644', 9, 8
    );
    this.cText(
      'WASD:sail SPACE:interact',
      '#ccc', 8, 30
    );
    this.cText(
      'Beware the Calamity Whale.',
      '#aa4466', 8, 48
    );
    this.cText(
      'Press ENTER to Start',
      '#44ff44', 10, 72
    );
    // Leaderboard
    this.cText(
      '-- LEADERBOARD --',
      '#ffaa44', 8, 92
    );
    const lb = this.leaderboard || [];
    if (lb.length === 0) {
      this.cText(
        'No scores yet', '#666', 7, 104
      );
    }
    for (let i = 0; i < lb.length
      && i < 5; i++) {
      const e = lb[i];
      const n = (e.name || '???')
        .substring(0, 10);
      const t = (i + 1) + '. '
        + n + ' ' + (e.score || 0);
      this.cText(
        t, '#ffff44', 7, 104 + i * 10
      );
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

  // ==================
  // INPUT
  // ==================

  handleKeyDown(code) {
    this.keys[code] = true;

    if (this.state === GS_TITLE
      && code === KEY_ENTER) {
      this.initGame();
      this.state = GS_PLAY;
    }

    if (this.state === GS_PLAY) {
      if (code === KEY_SPACE) {
        const si = this.nearSpot();
        if (si >= 0) {
          this.startFishing(si);
          return;
        }
        const pi = this.nearPort();
        if (pi >= 0) {
          this.openPort(pi);
          return;
        }
      }
    }

    if (this.state === GS_FISH) {
      if (code === KEY_SPACE) {
        this.checkFishHit();
      }
      if (code === KEY_ESC) {
        this.state = GS_PLAY;
      }
    }

    if (this.state === GS_CARGO) {
      if (code === KEY_LEFT) {
        this.pieceX = Math.max(
          0, this.pieceX - 1
        );
      }
      if (code === KEY_RIGHT) {
        this.pieceX = Math.min(
          this.cargoW - 1, this.pieceX + 1
        );
      }
      if (code === KEY_UP) {
        this.pieceY = Math.max(
          0, this.pieceY - 1
        );
      }
      if (code === KEY_DOWN) {
        this.pieceY = Math.min(
          this.cargoH - 1, this.pieceY + 1
        );
      }
      if (code === KEY_R) {
        this.rotatePiece();
      }
      if (code === KEY_SPACE) {
        this.placePiece();
      }
      if (code === KEY_D) {
        this.discardPiece();
      }
    }

    if (this.state === GS_PORT) {
      if (code === KEY_UP) {
        this.portSel = Math.max(
          0, this.portSel - 1
        );
      }
      if (code === KEY_DOWN) {
        const max = this.portItems
          ? this.portItems.length - 1 : 0;
        this.portSel = Math.min(
          max, this.portSel + 1
        );
      }
      if (code === KEY_SPACE) {
        const items = this.portItems || [];
        const sel = items[this.portSel];
        if (sel) {
          if (sel[1] === 'sell') {
            this.sellAll();
          } else if (sel[1] === 'leave') {
            this.state = GS_PLAY;
          } else {
            this.buyUpgrade(sel[1]);
          }
        }
      }
      if (code === KEY_ESC) {
        this.state = GS_PLAY;
      }
    }

    if ((this.state === GS_DEAD
      || this.state === GS_WIN)
      && code === KEY_R) {
      this.state = GS_TITLE;
    }
  }

  handleKeyUp(code) {
    this.keys[code] = false;
  }
}

// =========================================
// TGUI Component
// =========================================

const ACQUIRED_KEYS = [
  KEY_W, KEY_A, KEY_S, KEY_D,
  KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT,
  KEY_SPACE, KEY_R, KEY_ESC,
];

class ArcadeGreatLakeGame extends Component {
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

    this.engine = new GreatLakeEngine(
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
      && sd.map !== prevProps.data.map) {
      this.engine.loadData(sd);
      this.engine.state = GS_TITLE;
    }
    if (sd) {
      this.engine.leaderboard
        = sd.leaderboard || [];
    }
  }

  componentWillUnmount() {
    if (this.engine) {
      this.engine.stop();
    }
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
        onKeyUp={e => {
          e.preventDefault();
          if (this.engine) {
            this.engine.handleKeyUp(
              e.keyCode
            );
          }
        }}
        style={{
          display: 'block',
          outline: 'none',
          cursor: 'default',
          'image-rendering': 'pixelated',
        }}
      />
    );
  }
}

export const ArcadeGreatLake = (
  props, context
) => {
  const { act, data } = useBackend(context);
  return (
    <Window
      width={CW + 30}
      height={CH + 50}>
      <Window.Content>
        <ArcadeGreatLakeGame
          act={act}
          data={data}
        />
      </Window.Content>
    </Window>
  );
};
