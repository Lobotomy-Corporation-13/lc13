/**
 * @file
 * @copyright 2024
 * @license MIT
 *
 * Delivery Dash - Devyat' Association
 * courier game.
 * Top-down maze runner: deliver packages
 * before the Poludnitsa trunk explodes.
 */

import { Component, createRef } from 'inferno';
import { useBackend } from '../backend';
import { Window } from '../layouts';
import {
  acquireHotKey,
  releaseHotKey,
} from '../hotkeys';

// Constants

const TILE = 24;
const MAP_W = 25;
const MAP_H = 13;
const CANVAS_W = MAP_W * TILE;
const CANVAS_H = MAP_H * TILE + 40;
const HUD_H = 40;

const T_FLOOR = 0;
const T_WALL = 1;
const T_CRATE = 2;

const KEY_W = 87;
const KEY_A = 65;
const KEY_S = 83;
const KEY_D = 68;
const KEY_UP = 38;
const KEY_DOWN = 40;
const KEY_LEFT = 37;
const KEY_RIGHT = 39;
const KEY_ENTER = 13;
const KEY_R = 82;

const GS_TITLE = 0;
const GS_PLAYING = 1;
const GS_DEAD = 2;
const GS_WIN = 3;
const GS_ROUND_CLEAR = 4;
const GS_NAMEENTRY = 5;

const BASE_SPEED = 90;
const PLAYER_R = 6;

// Colors
const C_BG = '#1a1a22';
const C_FLOOR = '#2a2a35';
const C_WALL = '#4a4044';
const C_WALLTOP = '#5a5054';
const C_PLAYER = '#44aaff';
const C_TRUNK = '#aa44ff';
const C_PICKUP = '#ffcc00';
const C_DELIVER = '#44ff44';
const C_THUG = '#cc4444';

// Game Engine

class DeliveryEngine {
  constructor(canvas, act) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.act = act;
    this.keys = {};
    this.state = GS_TITLE;
    this.rafId = null;
    this.lastTime = 0;

    // Map data (multiple rounds)
    this.maps = [];
    this.round = 0;
    this.mapW = MAP_W;
    this.mapH = MAP_H;
    this.cells = null;

    // Player
    this.px = 0;
    this.py = 0;
    this.score = 0;

    // Delivery
    this.pickupX = 0;
    this.pickupY = 0;
    this.deliverX = 0;
    this.deliverY = 0;
    this.hasPackage = false;
    this.delivered = false;

    // Timer
    this.timeLimit = 30;
    this.timer = 0;

    // Trunk effects
    this.trunkGlow = 0;
    this.screenShake = 0;
    this.explodeTimer = 0;

    // Thugs (obstacles)
    this.thugs = [];

    // High score
    this.leaderboard = 0;

    // Name entry
    this.entryName = '';
    this.nameDone = false;

    // Bonus pickups (Ahn on the ground)
    this.bonuses = [];
  }

  loadMaps(staticData) {
    this.maps = staticData.maps || [];
  }

  startRound(roundIdx) {
    this.round = roundIdx;
    const mIdx = roundIdx % this.maps.length;
    const m = this.maps[mIdx];
    this.mapW = m.width;
    this.mapH = m.height;
    this.cells = m.cells;

    // Place player at top-left floor
    this.px = 1.5 * TILE;
    this.py = 1.5 * TILE;
    this.hasPackage = false;
    this.delivered = false;

    // Timer gets tighter each round
    this.timeLimit = Math.max(
      12, 30 - roundIdx * 3
    );
    this.timer = this.timeLimit;
    this.trunkGlow = 0;
    this.screenShake = 0;
    this.explodeTimer = 0;

    // Place pickup and delivery points
    // on floor tiles far apart
    const floors = this.getFloorTiles();
    if (floors.length < 2) return;

    // Pickup near top-left area
    this.placePoints(floors);

    // Spawn thugs (more each round)
    this.thugs = [];
    const thugCount = Math.min(
      3 + roundIdx, 8
    );
    this.spawnThugs(floors, thugCount);

    // Bonus Ahn pickups
    this.bonuses = [];
    const bonusCount = Math.min(
      2 + roundIdx, 6
    );
    this.spawnBonuses(floors, bonusCount);
  }

  getFloorTiles() {
    const floors = [];
    for (let y = 0; y < this.mapH; y++) {
      for (let x = 0; x < this.mapW; x++) {
        if (this.getCell(x, y) === T_FLOOR) {
          floors.push([x, y]);
        }
      }
    }
    return floors;
  }

  placePoints(floors) {
    // Pickup: random floor in top half
    const top = floors.filter(
      f => f[1] < this.mapH / 2
    );
    const bot = floors.filter(
      f => f[1] >= this.mapH / 2
    );
    if (top.length && bot.length) {
      const pi = Math.floor(
        Math.random() * top.length
      );
      this.pickupX = top[pi][0] * TILE
        + TILE / 2;
      this.pickupY = top[pi][1] * TILE
        + TILE / 2;
      const di = Math.floor(
        Math.random() * bot.length
      );
      this.deliverX = bot[di][0] * TILE
        + TILE / 2;
      this.deliverY = bot[di][1] * TILE
        + TILE / 2;
    }
  }

  spawnThugs(floors, count) {
    const used = new Set();
    const pgx = Math.floor(
      this.px / TILE
    );
    const pgy = Math.floor(
      this.py / TILE
    );
    for (let i = 0; i < count; i++) {
      let attempts = 0;
      while (attempts < 50) {
        attempts++;
        const fi = Math.floor(
          Math.random() * floors.length
        );
        const f = floors[fi];
        const key = f[0] + ',' + f[1];
        if (used.has(key)) continue;
        // Not near player start
        const dx = f[0] - pgx;
        const dy = f[1] - pgy;
        if (dx * dx + dy * dy < 9) continue;
        used.add(key);
        this.thugs.push({
          x: f[0] * TILE + TILE / 2,
          y: f[1] * TILE + TILE / 2,
          dir: Math.floor(
            Math.random() * 4
          ),
          moveTimer: 0,
          speed: 30 + Math.random() * 20,
        });
        break;
      }
    }
  }

  spawnBonuses(floors, count) {
    const used = new Set();
    for (let i = 0; i < count; i++) {
      let attempts = 0;
      while (attempts < 50) {
        attempts++;
        const fi = Math.floor(
          Math.random() * floors.length
        );
        const f = floors[fi];
        const key = f[0] + ',' + f[1];
        if (used.has(key)) continue;
        used.add(key);
        this.bonuses.push({
          x: f[0] * TILE + TILE / 2,
          y: f[1] * TILE + TILE / 2,
          alive: true,
          value: 15 + this.round * 5,
        });
        break;
      }
    }
  }

  getCell(gx, gy) {
    if (gx < 0 || gx >= this.mapW
      || gy < 0 || gy >= this.mapH) {
      return T_WALL;
    }
    return this.cells[gy * this.mapW + gx];
  }

  isWalkable(gx, gy) {
    return this.getCell(gx, gy) === T_FLOOR;
  }

  start() {
    this.lastTime = performance.now();
    this.loop(this.lastTime);
  }

  stop() {
    if (this.rafId) {
      cancelAnimationFrame(this.rafId);
      this.rafId = null;
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

  update(dt) {
    if (this.state !== GS_PLAYING) return;
    if (!this.cells) return;

    // Explosion animation
    if (this.explodeTimer > 0) {
      this.explodeTimer -= dt;
      if (this.explodeTimer <= 0) {
        this.state = GS_DEAD;
        this.act('died');
      }
      return;
    }

    // Timer countdown
    this.timer -= dt;
    if (this.timer <= 0) {
      this.timer = 0;
      this.explodeTimer = 1.0;
      this.act('sfx', { s: 'explode' });
      return;
    }

    // Trunk urgency effects
    const frac = this.timer / this.timeLimit;
    if (frac < 0.25) {
      this.trunkGlow = 1;
      this.screenShake = (
        Math.random() - 0.5
      ) * 3;
    } else if (frac < 0.5) {
      this.trunkGlow = 0.5;
      this.screenShake = (
        Math.random() - 0.5
      ) * 1;
    } else {
      this.trunkGlow = 0;
      this.screenShake = 0;
    }

    // Speed scales with urgency
    let speed = BASE_SPEED;
    if (frac < 0.25) {
      speed = BASE_SPEED * 2.0;
    } else if (frac < 0.5) {
      speed = BASE_SPEED * 1.5;
    }

    // Movement
    let mx = 0;
    let my = 0;
    if (this.keys[KEY_W]
      || this.keys[KEY_UP]) {
      my = -speed * dt;
    }
    if (this.keys[KEY_S]
      || this.keys[KEY_DOWN]) {
      my = speed * dt;
    }
    if (this.keys[KEY_A]
      || this.keys[KEY_LEFT]) {
      mx = -speed * dt;
    }
    if (this.keys[KEY_D]
      || this.keys[KEY_RIGHT]) {
      mx = speed * dt;
    }

    // Collision
    const r = PLAYER_R;
    if (mx !== 0) {
      const gx = Math.floor(
        (this.px + mx + (mx > 0 ? r : -r))
        / TILE
      );
      const gy1 = Math.floor(
        (this.py - r) / TILE
      );
      const gy2 = Math.floor(
        (this.py + r) / TILE
      );
      if (this.isWalkable(gx, gy1)
        && this.isWalkable(gx, gy2)) {
        this.px += mx;
      }
    }
    if (my !== 0) {
      const gy = Math.floor(
        (this.py + my + (my > 0 ? r : -r))
        / TILE
      );
      const gx1 = Math.floor(
        (this.px - r) / TILE
      );
      const gx2 = Math.floor(
        (this.px + r) / TILE
      );
      if (this.isWalkable(gx1, gy)
        && this.isWalkable(gx2, gy)) {
        this.py += my;
      }
    }

    // Pickup package
    if (!this.hasPackage) {
      const dx = this.pickupX - this.px;
      const dy = this.pickupY - this.py;
      if (dx * dx + dy * dy < 144) {
        this.hasPackage = true;
        this.act('sfx', { s: 'pickup' });
      }
    }

    // Deliver package
    if (this.hasPackage && !this.delivered) {
      const dx = this.deliverX - this.px;
      const dy = this.deliverY - this.py;
      if (dx * dx + dy * dy < 144) {
        this.delivered = true;
        const bonus = Math.floor(
          this.timer * 10
        );
        this.score += 100 + bonus;
        this.act('sfx', { s: 'deliver' });
        this.state = GS_ROUND_CLEAR;
      }
    }

    // Bonus Ahn
    for (let i = 0;
      i < this.bonuses.length; i++) {
      const b = this.bonuses[i];
      if (!b.alive) continue;
      const dx = b.x - this.px;
      const dy = b.y - this.py;
      if (dx * dx + dy * dy < 100) {
        b.alive = false;
        this.score += b.value;
        this.act('sfx', { s: 'pickup' });
      }
    }

    // Thug AI (simple patrol)
    for (let i = 0;
      i < this.thugs.length; i++) {
      const t = this.thugs[i];
      t.moveTimer -= dt;
      if (t.moveTimer <= 0) {
        t.dir = Math.floor(
          Math.random() * 4
        );
        t.moveTimer = 1 + Math.random() * 2;
      }
      const dirs = [
        [0, -1], [1, 0], [0, 1], [-1, 0],
      ];
      const d = dirs[t.dir];
      const tmx = d[0] * t.speed * dt;
      const tmy = d[1] * t.speed * dt;
      const tgx = Math.floor(
        (t.x + tmx
          + (tmx > 0 ? 8 : -8)) / TILE
      );
      const tgy = Math.floor(
        (t.y + tmy
          + (tmy > 0 ? 8 : -8)) / TILE
      );
      if (this.isWalkable(tgx,
        Math.floor(t.y / TILE))) {
        t.x += tmx;
      } else {
        t.dir = (t.dir + 2) % 4;
      }
      if (this.isWalkable(
        Math.floor(t.x / TILE), tgy)) {
        t.y += tmy;
      } else {
        t.dir = (t.dir + 1) % 4;
      }

      // Thug collision with player
      const dx = t.x - this.px;
      const dy = t.y - this.py;
      if (dx * dx + dy * dy < 100) {
        const frac2 = this.timer
          / this.timeLimit;
        const canPlow = frac2 < 0.25
          || this.round
          >= this.maps.length * 2 - 1;
        if (canPlow) {
          // At max speed: plow through
          this.thugs.splice(i, 1);
          i--;
          this.score += 25;
          this.act('sfx', { s: 'explode' });
          continue;
        }
        // Knock player back + steal time
        this.timer -= 2;
        if (this.timer < 0) this.timer = 0;
        const push = 30;
        const pd = Math.sqrt(
          dx * dx + dy * dy
        ) || 1;
        const kx = -(dx / pd) * push;
        const ky = -(dy / pd) * push;
        const nkx = this.px + kx;
        const nky = this.py + ky;
        const kr = PLAYER_R;
        const kgx = Math.floor(
          (nkx + (kx > 0 ? kr : -kr))
          / TILE
        );
        const kgy = Math.floor(
          (nky + (ky > 0 ? kr : -kr))
          / TILE
        );
        if (this.isWalkable(
          kgx, Math.floor(this.py / TILE)
        )) {
          this.px = nkx;
        }
        if (this.isWalkable(
          Math.floor(this.px / TILE), kgy
        )) {
          this.py = nky;
        }
        t.dir = (t.dir + 2) % 4;
        this.act('sfx', { s: 'warn' });
      }
    }
  }

  render() {
    const ctx = this.ctx;
    ctx.fillStyle = C_BG;
    ctx.fillRect(
      0, 0, CANVAS_W, CANVAS_H
    );

    if (this.state === GS_TITLE) {
      this.renderTitle();
      return;
    }

    if (!this.cells) return;

    ctx.save();
    ctx.translate(
      this.screenShake, HUD_H
    );

    // Draw map
    for (let gy = 0; gy < this.mapH; gy++) {
      for (let gx = 0;
        gx < this.mapW; gx++) {
        const c = this.getCell(gx, gy);
        const sx = gx * TILE;
        const sy = gy * TILE;
        if (c === T_WALL) {
          ctx.fillStyle = C_WALL;
          ctx.fillRect(
            sx, sy, TILE, TILE
          );
          ctx.fillStyle = C_WALLTOP;
          ctx.fillRect(
            sx, sy, TILE, 2
          );
        } else {
          ctx.fillStyle = C_FLOOR;
          ctx.fillRect(
            sx, sy, TILE, TILE
          );
          if ((gx + gy) % 5 === 0) {
            ctx.fillStyle = '#2e2e38';
            ctx.fillRect(
              sx + 4, sy + 4, 3, 3
            );
          }
        }
      }
    }

    // Draw pickup point
    if (!this.hasPackage) {
      const pulse = Math.sin(
        performance.now() * 0.005
      );
      const sz = 6 + pulse * 2;
      ctx.fillStyle = C_TRUNK;
      ctx.beginPath();
      ctx.arc(
        this.pickupX, this.pickupY,
        sz, 0, Math.PI * 2
      );
      ctx.fill();
      ctx.fillStyle = '#ffffff';
      ctx.font = '8px monospace';
      ctx.fillText(
        'PKG',
        this.pickupX - 9,
        this.pickupY - sz - 3
      );
    }

    // Draw delivery point
    if (this.hasPackage && !this.delivered) {
      const pulse = Math.sin(
        performance.now() * 0.006
      );
      const sz = 6 + pulse * 2;
      ctx.strokeStyle = C_DELIVER;
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.arc(
        this.deliverX, this.deliverY,
        sz, 0, Math.PI * 2
      );
      ctx.stroke();
      ctx.lineWidth = 1;
      ctx.fillStyle = '#ffffff';
      ctx.font = '8px monospace';
      ctx.fillText(
        'DROP',
        this.deliverX - 11,
        this.deliverY - sz - 3
      );
    }

    // Draw bonuses
    for (let i = 0;
      i < this.bonuses.length; i++) {
      const b = this.bonuses[i];
      if (!b.alive) continue;
      const pulse = Math.sin(
        performance.now() * 0.004 + i
      );
      ctx.fillStyle = C_PICKUP;
      ctx.beginPath();
      ctx.arc(
        b.x, b.y, 3 + pulse,
        0, Math.PI * 2
      );
      ctx.fill();
    }

    // Draw thugs
    for (let i = 0;
      i < this.thugs.length; i++) {
      const t = this.thugs[i];
      ctx.fillStyle = C_THUG;
      ctx.fillRect(
        t.x - 5, t.y - 5, 10, 10
      );
      ctx.fillStyle = '#ff6666';
      ctx.fillRect(
        t.x - 3, t.y - 7, 6, 3
      );
    }

    // Draw player
    const frac = this.timer / this.timeLimit;
    let pColor = C_PLAYER;
    if (frac < 0.25) {
      // Intense glow when near death
      const p2 = Math.sin(
        performance.now() * 0.015
      );
      pColor = p2 > 0
        ? '#ff8844' : '#ffaa66';
    } else if (frac < 0.5) {
      pColor = '#66bbff';
    }
    ctx.fillStyle = pColor;
    ctx.beginPath();
    ctx.arc(
      this.px, this.py, PLAYER_R,
      0, Math.PI * 2
    );
    ctx.fill();

    // Trunk indicator on player
    if (this.hasPackage) {
      ctx.fillStyle = C_TRUNK;
      ctx.fillRect(
        this.px - 3,
        this.py - PLAYER_R - 5,
        6, 4
      );
    }

    // Explosion animation
    if (this.explodeTimer > 0) {
      const prog = 1 - this.explodeTimer;
      const rad = prog * 150;
      const a = this.explodeTimer;
      ctx.fillStyle = 'rgba(255,100,0,'
        + a.toFixed(2) + ')';
      ctx.beginPath();
      ctx.arc(
        this.px, this.py, rad,
        0, Math.PI * 2
      );
      ctx.fill();
      ctx.fillStyle = 'rgba(255,255,100,'
        + (a * 0.8).toFixed(2) + ')';
      ctx.beginPath();
      ctx.arc(
        this.px, this.py, rad * 0.5,
        0, Math.PI * 2
      );
      ctx.fill();
    }

    ctx.restore();

    // HUD (above map)
    this.renderHUD();

    // State overlays
    if (this.state === GS_ROUND_CLEAR) {
      ctx.fillStyle = 'rgba(0,0,0,0.5)';
      ctx.fillRect(
        0, 0, CANVAS_W, CANVAS_H
      );
      this.centerText(
        'DELIVERED!', C_DELIVER, 16
      );
      const bonus = Math.floor(
        this.timer * 10
      );
      this.centerText(
        'Time bonus: +' + bonus,
        '#ffffff', 10, 22
      );
      this.centerText(
        'Press ENTER for next run',
        '#aaaaaa', 9, 42
      );
    }

    if (this.state === GS_DEAD) {
      ctx.fillStyle = 'rgba(100,0,0,0.6)';
      ctx.fillRect(
        0, 0, CANVAS_W, CANVAS_H
      );
      this.centerText(
        'TRUNK EXPLODED!',
        '#ff4444', 16
      );
      this.centerText(
        'Score: ' + this.score,
        '#ffffff', 10, 22
      );
      this.centerText(
        'Press R to retry',
        '#aaaaaa', 9, 40
      );
    }

    if (this.state === GS_WIN) {
      ctx.fillStyle = 'rgba(0,0,0,0.6)';
      ctx.fillRect(
        0, 0, CANVAS_W, CANVAS_H
      );
      this.centerText(
        'ALL DELIVERIES COMPLETE!',
        '#ffdd00', 14
      );
      this.centerText(
        'Final Score: ' + this.score,
        '#ffffff', 10, 22
      );
      this.centerText(
        'Press R to play again',
        '#aaaaaa', 9, 40
      );
    }

    if (this.state === GS_NAMEENTRY) {
      this.renderNameEntry();
    }
  }

  renderHUD() {
    const ctx = this.ctx;

    // Timer bar
    const frac = this.timer / this.timeLimit;
    ctx.fillStyle = '#222';
    ctx.fillRect(4, 4, CANVAS_W - 8, 10);
    let barColor = '#44aa44';
    if (frac < 0.25) barColor = '#ff4444';
    else if (frac < 0.5) barColor = '#ffaa44';
    ctx.fillStyle = barColor;
    ctx.fillRect(
      4, 4,
      Math.max(0, (CANVAS_W - 8) * frac), 10
    );

    // Timer text
    ctx.fillStyle = '#ffffff';
    ctx.font = '10px monospace';
    const secs = Math.ceil(this.timer);
    ctx.fillText(
      secs + 's',
      CANVAS_W / 2 - 10, 12
    );

    // Score
    ctx.fillText(
      'AHN:' + this.score, 4, 28
    );

    // Round
    ctx.fillText(
      'Run ' + (this.round + 1),
      CANVAS_W - 55, 28
    );

    // Package status
    if (!this.hasPackage) {
      ctx.fillStyle = C_TRUNK;
      ctx.fillText('GET PACKAGE', 4, 38);
    } else if (!this.delivered) {
      ctx.fillStyle = C_DELIVER;
      ctx.fillText('DELIVER!', 4, 38);
    }

    // Speed indicator
    if (frac < 0.25) {
      ctx.fillStyle = '#ff4444';
      ctx.fillText(
        'SPEED x2!',
        CANVAS_W / 2 - 25, 28
      );
    } else if (frac < 0.5) {
      ctx.fillStyle = '#ffaa44';
      ctx.fillText(
        'SPEED x1.5',
        CANVAS_W / 2 - 28, 28
      );
    }
  }

  renderTitle() {
    const ctx = this.ctx;

    ctx.strokeStyle = '#aa44ff';
    ctx.lineWidth = 3;
    ctx.strokeRect(
      10, 10, CANVAS_W - 20, CANVAS_H - 20
    );

    this.centerText(
      'DELIVERY DASH', '#aa44ff', 28, -90
    );
    this.centerText(
      'Devyat\' Association',
      '#888888', 14, -60
    );
    this.centerText(
      'Deliver packages before',
      '#aaaaaa', 13, -32
    );
    this.centerText(
      'the Poludnitsa trunk',
      '#aaaaaa', 13, -16
    );
    this.centerText(
      'explodes!', '#ff6644', 13, 0
    );
    this.centerText(
      'Low time = faster speed',
      '#ffaa44', 12, 24
    );
    this.centerText(
      'Avoid Syndicate thugs',
      '#cc4444', 12, 40
    );
    this.centerText(
      'Collect Ahn for bonus',
      '#ffcc00', 12, 56
    );
    this.centerText(
      'WASD/Arrows to move',
      '#aaaaaa', 12, 78
    );
    this.centerText(
      'Press ENTER to Start',
      '#44ff44', 17, 102
    );
    // Leaderboard
    this.centerText(
      '-- LEADERBOARD --',
      '#ffaa44', 12, 122
    );
    const lb = this.leaderboard || [];
    if (lb.length === 0) {
      this.centerText(
        'No scores yet', '#666', 11, 140
      );
    }
    for (let i = 0; i < lb.length
      && i < 5; i++) {
      const e = lb[i];
      const n = (e.name || '???')
        .substring(0, 10);
      const t = (i + 1) + '. '
        + n + ' ' + (e.score || 0);
      this.centerText(
        t, '#ffff44', 11, 140 + i * 15
      );
    }
  }

  renderNameEntry() {
    const ctx = this.ctx;
    ctx.fillStyle = 'rgba(0,0,0,0.85)';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    this.centerText(
      'YOU WIN!', '#ffcc44', 20, -80
    );
    this.centerText(
      'Score: ' + this.score,
      '#fff', 14, -52
    );
    this.centerText(
      'ENTER YOUR NAME',
      '#aaa', 12, -20
    );
    const boxW = 28;
    const boxH = 32;
    const gap = 6;
    const totalW = 6 * boxW + 5 * gap;
    const sx = (CANVAS_W - totalW) / 2;
    const sy = CANVAS_H / 2 + 4;
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
      this.centerText(
        'Press R to play again',
        '#aaa', 9, 60
      );
    } else {
      this.centerText(
        'Type A-Z then ENTER',
        '#888', 9, 60
      );
    }
  }

  centerText(text, color, size, yOff) {
    const ctx = this.ctx;
    ctx.fillStyle = color;
    ctx.font = size + 'px monospace';
    const w = ctx.measureText(text).width;
    ctx.fillText(
      text,
      (CANVAS_W - w) / 2,
      CANVAS_H / 2 + (yOff || 0)
    );
  }

  handleKeyDown(code) {
    this.keys[code] = true;

    if (this.state === GS_TITLE
      && code === KEY_ENTER) {
      this.state = GS_PLAYING;
      this.score = 0;
      this.startRound(0);
    }

    if (this.state === GS_ROUND_CLEAR
      && code === KEY_ENTER) {
      const nextRound = this.round + 1;
      if (nextRound >= this.maps.length * 2) {
        // Beat all rounds
        this.score += 500;
        this.entryName = '';
        this.nameDone = false;
        this.state = GS_NAMEENTRY;
      } else {
        this.state = GS_PLAYING;
        this.startRound(nextRound);
      }
    }

    // Name entry input
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
          name: this.entryName || 'ANON',
        });
        return;
      }
      if (code === 8
        && this.entryName.length > 0) {
        this.entryName = this.entryName
          .slice(0, -1);
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

// TGUI Component

const ACQUIRED_KEYS = [
  KEY_W, KEY_A, KEY_S, KEY_D,
  KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT,
  KEY_R,
];

class ArcadeDeliveryGame extends Component {
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

    this.engine = new DeliveryEngine(
      canvas, this.props.act
    );
    this.engine.highScore
      = this.props.data.leaderboard || [];

    const sd = this.props.data;
    if (sd && sd.maps) {
      this.engine.loadMaps(sd);
    }

    this.engine.start();
    canvas.focus();
  }

  componentDidUpdate(prevProps) {
    if (!this.engine) return;
    const sd = this.props.data;
    if (sd) {
      this.engine.highScore
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
        width={CANVAS_W}
        height={CANVAS_H}
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

export const ArcadeDelivery = (
  props, context
) => {
  const { act, data } = useBackend(context);
  return (
    <Window
      width={CANVAS_W + 30}
      height={CANVAS_H + 50}>
      <Window.Content>
        <ArcadeDeliveryGame
          act={act}
          data={data}
        />
      </Window.Content>
    </Window>
  );
};
