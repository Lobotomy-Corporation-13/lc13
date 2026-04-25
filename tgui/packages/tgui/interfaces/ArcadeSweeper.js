/**
 * @file
 * @copyright 2024
 * @license MIT
 *
 * Sweeper Survival - Survive the Night
 * in the Backstreets.
 * Top-down survival: dodge 3 Sweeper waves,
 * collect Ahn, hide in buildings.
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

const SCREEN_W = 384;
const SCREEN_H = 384;
const CANVAS_W = 384;
const CANVAS_H = 384;
const TILE = 12;
const MAP_W = 32;
const MAP_H = 32;

// Tile types
const T_STREET = 0;
const T_WALL = 1;
const T_DOOR = 2;
const T_FLOOR = 3;

// Key codes
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

// Game states
const GS_TITLE = 0;
const GS_PLAYING = 1;
const GS_DEAD = 2;
const GS_WIN = 3;
const GS_NAMEENTRY = 4;

// Game duration (81 seconds)
const GAME_TIME = 81;

// Sweeper wave times (seconds into game)
const WAVE_TIMES = [20, 45, 70];
// Warning before wave (seconds)
const WARN_TIME = 5;
// Wave duration (seconds to cross map)
const WAVE_DURATION = 3;

const MOVE_SPEED = 60; // pixels per second
const PICKUP_RADIUS = 8;

// Colors
const C_STREET = '#2a2a35';
const C_WALL = '#4a4040';
const C_WALL_TOP = '#5a5050';
const C_DOOR = '#6a5530';
const C_FLOOR = '#3a3535';
const C_PLAYER = '#44aaff';
const C_AHN = '#ffdd00';
const C_SWEEPER = '#cc2222';

// =========================================
// Game Engine
// =========================================

class SweeperEngine {
  constructor(canvas, act) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.act = act;
    this.keys = {};
    this.state = GS_TITLE;
    this.rafId = null;
    this.lastTime = 0;

    // Map
    this.mapW = MAP_W;
    this.mapH = MAP_H;
    this.cells = null;

    // Player
    this.px = 0;
    this.py = 0;
    this.score = 0;
    this.alive = true;
    this.inside = false;

    // Pickups
    this.pickups = [];

    // Waves
    this.timer = 0;
    this.waveIndex = 0;
    this.waveActive = false;
    this.waveY = 0;
    this.warning = false;

    // High score
    this.leaderboard = 0;

    // Name entry
    this.entryName = '';
    this.nameDone = false;

    // Powerups
    this.powerups = [];
    this.speedBuff = 0;

    // Message overlay
    this.message = '';
    this.messageTimer = 0;
  }

  loadMap(staticData) {
    const m = staticData.map;
    this.mapW = m.width;
    this.mapH = m.height;
    this.cells = m.cells;

    // Find a street tile for player start
    // (bottom-center area)
    this.px = 15 * TILE;
    this.py = 29 * TILE;

    this.pickups = [];
    if (staticData.spawns) {
      for (let i = 0;
        i < staticData.spawns.length; i++) {
        const s = staticData.spawns[i];
        this.pickups.push({
          x: s.x * TILE + TILE / 2,
          y: s.y * TILE + TILE / 2,
          alive: true,
          value: 10 + Math.floor(
            Math.random() * 20
          ),
        });
      }
    }

    this.timer = 0;
    this.waveIndex = 0;
    this.waveActive = false;
    this.warning = false;
    this.score = 0;
    this.alive = true;
    this.inside = false;
    this.powerups = [];
    this.speedBuff = 0;
  }

  /// Get all street tile positions
  getStreetTiles() {
    const tiles = [];
    for (let y = 0; y < this.mapH; y++) {
      for (let x = 0; x < this.mapW; x++) {
        if (this.getCell(x, y) === T_STREET) {
          tiles.push([x, y]);
        }
      }
    }
    return tiles;
  }

  /// Respawn pickups on random streets
  respawnPickups() {
    this.pickups = [];
    const streets = this.getStreetTiles();
    const count = 12 + Math.floor(
      Math.random() * 6
    );
    for (let i = 0; i < count
      && i < streets.length; i++) {
      const si = Math.floor(
        Math.random() * streets.length
      );
      const s = streets[si];
      this.pickups.push({
        x: s[0] * TILE + TILE / 2,
        y: s[1] * TILE + TILE / 2,
        alive: true,
        value: 10 + Math.floor(
          Math.random() * 20
        ),
      });
    }
  }

  /// Spawn a speed powerup on a random street
  spawnSpeedPowerup() {
    const streets = this.getStreetTiles();
    if (!streets.length) return;
    const si = Math.floor(
      Math.random() * streets.length
    );
    const s = streets[si];
    this.powerups.push({
      x: s[0] * TILE + TILE / 2,
      y: s[1] * TILE + TILE / 2,
      alive: true,
      type: 'speed',
    });
  }

  getCell(gx, gy) {
    if (gx < 0 || gx >= this.mapW
      || gy < 0 || gy >= this.mapH) {
      return T_WALL;
    }
    return this.cells[gy * this.mapW + gx];
  }

  isWalkable(gx, gy) {
    const c = this.getCell(gx, gy);
    return c !== T_WALL;
  }

  isInside(gx, gy) {
    const c = this.getCell(gx, gy);
    return c === T_FLOOR;
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

    // Message decay
    if (this.messageTimer > 0) {
      this.messageTimer -= dt;
    }

    // Game timer
    this.timer += dt;

    // Check win
    if (this.timer >= GAME_TIME
      && !this.waveActive) {
      this.score += 200;
      this.entryName = '';
      this.nameDone = false;
      this.state = GS_NAMEENTRY;
      return;
    }

    // Speed buff decay
    if (this.speedBuff > 0) {
      this.speedBuff -= dt;
    }
    const spd = this.speedBuff > 0
      ? MOVE_SPEED * 1.6 : MOVE_SPEED;

    // Movement
    let mx = 0;
    let my = 0;
    if (this.keys[KEY_W]
      || this.keys[KEY_UP]) {
      my = -spd * dt;
    }
    if (this.keys[KEY_S]
      || this.keys[KEY_DOWN]) {
      my = spd * dt;
    }
    if (this.keys[KEY_A]
      || this.keys[KEY_LEFT]) {
      mx = -spd * dt;
    }
    if (this.keys[KEY_D]
      || this.keys[KEY_RIGHT]) {
      mx = spd * dt;
    }

    // Collision per axis
    const r = 4; // player radius
    const nx = this.px + mx;
    const ny = this.py + my;

    // X axis
    if (mx !== 0) {
      const gx = Math.floor(
        (nx + (mx > 0 ? r : -r)) / TILE
      );
      const gy1 = Math.floor(
        (this.py - r) / TILE
      );
      const gy2 = Math.floor(
        (this.py + r) / TILE
      );
      if (this.isWalkable(gx, gy1)
        && this.isWalkable(gx, gy2)) {
        this.px = nx;
      }
    }
    // Y axis
    if (my !== 0) {
      const gy = Math.floor(
        (ny + (my > 0 ? r : -r)) / TILE
      );
      const gx1 = Math.floor(
        (this.px - r) / TILE
      );
      const gx2 = Math.floor(
        (this.px + r) / TILE
      );
      if (this.isWalkable(gx1, gy)
        && this.isWalkable(gx2, gy)) {
        this.py = ny;
      }
    }

    // Clamp to map
    this.px = Math.max(
      r, Math.min(
        this.mapW * TILE - r, this.px
      )
    );
    this.py = Math.max(
      r, Math.min(
        this.mapH * TILE - r, this.py
      )
    );

    // Check if inside a building
    const pgx = Math.floor(this.px / TILE);
    const pgy = Math.floor(this.py / TILE);
    this.inside = this.isInside(pgx, pgy);

    // Pickup collection
    for (let i = 0;
      i < this.pickups.length; i++) {
      const p = this.pickups[i];
      if (!p.alive) continue;
      const dx = p.x - this.px;
      const dy = p.y - this.py;
      if (dx * dx + dy * dy
        < PICKUP_RADIUS * PICKUP_RADIUS) {
        p.alive = false;
        this.score += p.value;
        this.act('sfx', { s: 'pickup' });
      }
    }

    // Powerup collection
    for (let i = this.powerups.length - 1;
      i >= 0; i--) {
      const pu = this.powerups[i];
      if (!pu.alive) continue;
      const dx = pu.x - this.px;
      const dy = pu.y - this.py;
      if (dx * dx + dy * dy
        < PICKUP_RADIUS * PICKUP_RADIUS) {
        pu.alive = false;
        if (pu.type === 'speed') {
          this.speedBuff = 8;
          this.message = 'SPEED BOOST!';
          this.messageTimer = 1.5;
        }
        this.act('sfx', { s: 'pickup' });
      }
    }

    // Wave logic
    if (this.waveIndex < WAVE_TIMES.length) {
      const wt = WAVE_TIMES[this.waveIndex];

      // Warning phase
      if (!this.warning
        && this.timer >= wt - WARN_TIME) {
        this.warning = true;
        this.message = 'SWEEPERS INCOMING!';
        this.messageTimer = WARN_TIME - 0.5;
        this.act('sfx', { s: 'siren' });
      }

      // Wave starts
      if (!this.waveActive
        && this.timer >= wt) {
        this.waveActive = true;
        this.waveY = -TILE * 2;
        this.act('sfx', { s: 'sweep' });
      }

      // Wave moving
      if (this.waveActive) {
        const wSpeed = (
          this.mapH * TILE + TILE * 4
        ) / WAVE_DURATION;
        this.waveY += wSpeed * dt;

        // Wave destroys pickups it passes
        const waveTop = this.waveY
          - TILE * 2;
        const waveBot = this.waveY
          + TILE * 2;
        for (let pi = 0;
          pi < this.pickups.length; pi++) {
          const pk = this.pickups[pi];
          if (pk.alive
            && pk.y >= waveTop
            && pk.y <= waveBot) {
            pk.alive = false;
          }
        }
        // Also destroys powerups
        for (let pi = 0;
          pi < this.powerups.length;
          pi++) {
          const pu = this.powerups[pi];
          if (pu.alive
            && pu.y >= waveTop
            && pu.y <= waveBot) {
            pu.alive = false;
          }
        }

        // Check if wave hits player
        if (!this.inside) {
          if (this.py >= waveTop
            && this.py <= waveBot) {
            this.alive = false;
            this.state = GS_DEAD;
            this.act('died');
            return;
          }
        }

        // Wave passed
        if (this.waveY
          > this.mapH * TILE + TILE * 4) {
          this.waveActive = false;
          this.warning = false;
          this.waveIndex++;
          this.score += 50;
          // Wave clears all remaining Ahn
          for (let pi = 0;
            pi < this.pickups.length;
            pi++) {
            this.pickups[pi].alive = false;
          }
          // Respawn fresh Ahn
          this.respawnPickups();
          // Spawn speed powerup
          this.spawnSpeedPowerup();
          if (this.waveIndex
            < WAVE_TIMES.length) {
            this.message = 'WAVE SURVIVED!'
              + ' Ahn respawned!';
            this.messageTimer = 2;
          } else {
            this.message = 'ALL WAVES '
              + 'PASSED! SURVIVE TO WIN!';
            this.messageTimer = 3;
          }
        }
      }
    }
  }

  render() {
    const ctx = this.ctx;
    ctx.fillStyle = '#111';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);

    if (this.state === GS_TITLE) {
      this.renderTitle();
      return;
    }

    if (!this.cells) return;

    // Camera centered on player
    const camX = Math.max(0, Math.min(
      this.mapW * TILE - CANVAS_W,
      this.px - CANVAS_W / 2
    ));
    const camY = Math.max(0, Math.min(
      this.mapH * TILE - CANVAS_H,
      this.py - CANVAS_H / 2
    ));

    // Draw map
    const startGX = Math.floor(
      camX / TILE
    );
    const startGY = Math.floor(
      camY / TILE
    );
    const endGX = Math.min(
      this.mapW,
      startGX + Math.ceil(
        CANVAS_W / TILE
      ) + 1
    );
    const endGY = Math.min(
      this.mapH,
      startGY + Math.ceil(
        CANVAS_H / TILE
      ) + 1
    );

    for (let gy = startGY; gy < endGY; gy++) {
      for (let gx = startGX;
        gx < endGX; gx++) {
        const c = this.getCell(gx, gy);
        const sx = gx * TILE - camX;
        const sy = gy * TILE - camY;

        switch (c) {
          case T_STREET:
            ctx.fillStyle = C_STREET;
            ctx.fillRect(
              sx, sy, TILE, TILE
            );
            // Street detail
            if ((gx + gy) % 4 === 0) {
              ctx.fillStyle = '#333340';
              ctx.fillRect(
                sx + 2, sy + 2, 2, 2
              );
            }
            break;
          case T_WALL:
            ctx.fillStyle = C_WALL;
            ctx.fillRect(
              sx, sy, TILE, TILE
            );
            // Wall top highlight
            ctx.fillStyle = C_WALL_TOP;
            ctx.fillRect(
              sx, sy, TILE, 2
            );
            break;
          case T_DOOR:
            ctx.fillStyle = C_DOOR;
            ctx.fillRect(
              sx, sy, TILE, TILE
            );
            // Door frame
            ctx.fillStyle = '#8a7540';
            ctx.fillRect(
              sx + 2, sy, TILE - 4, 2
            );
            ctx.fillRect(
              sx + 2, sy + TILE - 2,
              TILE - 4, 2
            );
            break;
          case T_FLOOR:
            ctx.fillStyle = C_FLOOR;
            ctx.fillRect(
              sx, sy, TILE, TILE
            );
            // Floor pattern
            if ((gx + gy) % 3 === 0) {
              ctx.fillStyle = '#3f3838';
              ctx.fillRect(
                sx + 4, sy + 4, 4, 4
              );
            }
            break;
          default:
            break;
        }
      }
    }

    // Draw pickups
    for (let i = 0;
      i < this.pickups.length; i++) {
      const p = this.pickups[i];
      if (!p.alive) continue;
      const sx = p.x - camX;
      const sy = p.y - camY;
      if (sx < -10 || sx > CANVAS_W + 10
        || sy < -10 || sy > CANVAS_H + 10) {
        continue;
      }
      // Pulsing Ahn coin
      const pulse = Math.sin(
        performance.now() * 0.005 + i
      );
      const sz = 3 + pulse;
      ctx.fillStyle = C_AHN;
      ctx.beginPath();
      ctx.arc(sx, sy, sz, 0, Math.PI * 2);
      ctx.fill();
    }

    // Draw powerups
    for (let i = 0;
      i < this.powerups.length; i++) {
      const pu = this.powerups[i];
      if (!pu.alive) continue;
      const sx = pu.x - camX;
      const sy = pu.y - camY;
      if (sx < -10 || sx > CANVAS_W + 10
        || sy < -10
        || sy > CANVAS_H + 10) {
        continue;
      }
      const pulse = Math.sin(
        performance.now() * 0.008
      );
      // Speed powerup: cyan diamond
      ctx.fillStyle = '#44ffff';
      ctx.save();
      ctx.translate(sx, sy);
      ctx.rotate(Math.PI / 4);
      const ds = 4 + pulse;
      ctx.fillRect(
        -ds, -ds, ds * 2, ds * 2
      );
      ctx.restore();
      // Arrow icon
      ctx.fillStyle = '#ffffff';
      ctx.fillRect(sx - 1, sy - 3, 2, 6);
      ctx.fillRect(sx - 2, sy - 2, 4, 2);
    }

    // Draw sweeper wave
    if (this.waveActive) {
      const wy = this.waveY - camY;
      const wh = TILE * 4;
      // Red sweeping line
      const grad = ctx.createLinearGradient(
        0, wy - wh / 2, 0, wy + wh / 2
      );
      grad.addColorStop(0, 'rgba(200,0,0,0)');
      grad.addColorStop(
        0.3, 'rgba(200,30,30,0.7)'
      );
      grad.addColorStop(
        0.5, 'rgba(255,50,50,0.9)'
      );
      grad.addColorStop(
        0.7, 'rgba(200,30,30,0.7)'
      );
      grad.addColorStop(1, 'rgba(200,0,0,0)');
      ctx.fillStyle = grad;
      ctx.fillRect(
        0, wy - wh / 2, CANVAS_W, wh
      );
      // Sweeper figures inside the wave
      for (let sx = 20;
        sx < CANVAS_W; sx += 40) {
        ctx.fillStyle = '#ff4444';
        ctx.fillRect(
          sx - 3, wy - 6, 6, 12
        );
        ctx.fillStyle = '#cc0000';
        ctx.fillRect(
          sx - 2, wy - 8, 4, 4
        );
      }
    }

    // Warning tint
    if (this.warning && !this.waveActive) {
      const pulse = Math.sin(
        performance.now() * 0.008
      );
      const a = 0.1 + pulse * 0.05;
      ctx.fillStyle = 'rgba(255,0,0,'
        + a.toFixed(3) + ')';
      ctx.fillRect(
        0, 0, CANVAS_W, CANVAS_H
      );
    }

    // Draw player
    const psx = this.px - camX;
    const psy = this.py - camY;
    ctx.fillStyle = this.inside
      ? '#2288cc' : C_PLAYER;
    ctx.beginPath();
    ctx.arc(
      psx, psy, 4, 0, Math.PI * 2
    );
    ctx.fill();
    // Direction dot
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(psx - 1, psy - 1, 2, 2);

    // HUD
    this.renderHUD();

    // Message overlay
    if (this.messageTimer > 0) {
      const a = Math.min(
        1, this.messageTimer
      );
      ctx.fillStyle = 'rgba(255,255,255,'
        + a.toFixed(2) + ')';
      ctx.font = '12px monospace';
      const w = ctx.measureText(
        this.message
      ).width;
      ctx.fillText(
        this.message,
        (CANVAS_W - w) / 2,
        CANVAS_H / 2 - 40
      );
    }

    // Death overlay
    if (this.state === GS_DEAD) {
      ctx.fillStyle = 'rgba(150,0,0,0.6)';
      ctx.fillRect(
        0, 0, CANVAS_W, CANVAS_H
      );
      this.centerText(
        'CONSUMED BY SWEEPERS',
        '#ff4444', 14
      );
      this.centerText(
        'Score: ' + this.score,
        '#ffffff', 10, 20
      );
      this.centerText(
        'Press R to retry',
        '#aaaaaa', 9, 38
      );
    }

    // Win overlay
    if (this.state === GS_WIN) {
      ctx.fillStyle = 'rgba(0,0,0,0.6)';
      ctx.fillRect(
        0, 0, CANVAS_W, CANVAS_H
      );
      this.centerText(
        'YOU SURVIVED THE NIGHT!',
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

    // Timer bar (top)
    const elapsed = Math.min(
      this.timer, GAME_TIME
    );
    const frac = elapsed / GAME_TIME;
    ctx.fillStyle = '#222';
    ctx.fillRect(4, 4, CANVAS_W - 8, 8);
    // Color based on wave proximity
    let barColor = '#44aa44';
    if (this.warning) barColor = '#cc4444';
    else if (frac > 0.8) barColor = '#cccc44';
    ctx.fillStyle = barColor;
    ctx.fillRect(
      4, 4,
      (CANVAS_W - 8) * frac, 8
    );

    // Wave markers on timer bar
    for (let i = 0;
      i < WAVE_TIMES.length; i++) {
      const wf = WAVE_TIMES[i] / GAME_TIME;
      const wx = 4 + (CANVAS_W - 8) * wf;
      ctx.fillStyle = i < this.waveIndex
        ? '#44ff44' : '#ff4444';
      ctx.fillRect(wx - 1, 2, 2, 12);
    }

    // Timer text
    const remaining = Math.max(
      0, Math.ceil(GAME_TIME - this.timer)
    );
    ctx.fillStyle = '#ffffff';
    ctx.font = '9px monospace';
    ctx.fillText(
      remaining + 's', CANVAS_W - 28, 22
    );

    // Score
    ctx.fillText(
      'AHN:' + this.score, 4, 22
    );

    // Inside indicator
    if (this.inside) {
      ctx.fillStyle = '#44cc44';
      ctx.fillText('SHELTERED', 4, 34);
    } else if (this.warning) {
      ctx.fillStyle = '#ff4444';
      ctx.fillText('FIND SHELTER!', 4, 34);
    }

    // Speed buff indicator
    if (this.speedBuff > 0) {
      ctx.fillStyle = '#44ffff';
      ctx.fillText(
        'SPEED x1.6 ['
          + Math.ceil(this.speedBuff)
          + 's]',
        CANVAS_W / 2 - 35, 34
      );
    }

    // Wave counter
    ctx.fillStyle = '#aaaaaa';
    ctx.fillText(
      'Wave ' + this.waveIndex + '/3',
      CANVAS_W / 2 - 20, 22
    );
  }

  renderTitle() {
    const ctx = this.ctx;

    ctx.strokeStyle = '#cc4444';
    ctx.lineWidth = 3;
    ctx.strokeRect(
      10, 10, CANVAS_W - 20, CANVAS_H - 20
    );

    this.centerText(
      'SWEEPER SURVIVAL', '#cc4444', 24, -100
    );
    this.centerText(
      'The Night in the Backstreets',
      '#888888', 12, -74
    );
    this.centerText(
      'Survive 81 seconds.',
      '#aaaaaa', 12, -48
    );
    this.centerText(
      '3 Sweeper waves will march',
      '#aaaaaa', 11, -26
    );
    this.centerText(
      'across the streets.',
      '#aaaaaa', 11, -10
    );
    this.centerText(
      'Hide inside buildings',
      '#ffdd00', 11, 12
    );
    this.centerText(
      '(enter through doors)',
      '#ffdd00', 11, 28
    );
    this.centerText(
      'Collect Ahn for points',
      '#aaaaaa', 11, 50
    );
    this.centerText(
      'WASD/Arrows to move',
      '#aaaaaa', 11, 68
    );
    this.centerText(
      'Press ENTER to Start',
      '#44ff44', 16, 96
    );
    // Leaderboard
    this.centerText(
      '-- LEADERBOARD --',
      '#ffaa44', 12, 118
    );
    const lb = this.leaderboard || [];
    if (lb.length === 0) {
      this.centerText(
        'No scores yet', '#666', 11, 136
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
        t, '#ffff44', 11, 136 + i * 14
      );
    }
  }

  renderNameEntry() {
    const ctx = this.ctx;
    ctx.fillStyle = 'rgba(0,0,0,0.85)';
    ctx.fillRect(
      0, 0, CANVAS_W, CANVAS_H
    );
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

    if (this.state === GS_DEAD
      && code === KEY_R) {
      this.act('restart');
    }

    if (this.state === GS_WIN
      && code === KEY_R) {
      this.act('restart');
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
  KEY_R,
];

class ArcadeSweeperGame extends Component {
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

    this.engine = new SweeperEngine(
      canvas, this.props.act
    );
    this.engine.highScore
      = this.props.data.leaderboard || [];

    const sd = this.props.data;
    if (sd && sd.map) {
      this.engine.loadMap(sd);
    }

    this.engine.start();
    canvas.focus();
  }

  componentDidUpdate(prevProps) {
    if (!this.engine) return;
    const sd = this.props.data;
    // Reload on restart (new static data)
    if (sd && sd.map
      && sd !== prevProps.data
      && sd.map !== prevProps.data.map) {
      this.engine.loadMap(sd);
      this.engine.state = GS_PLAYING;
    }
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

export const ArcadeSweeper = (
  props, context
) => {
  const { act, data } = useBackend(context);
  return (
    <Window
      width={CANVAS_W + 30}
      height={CANVAS_H + 50}>
      <Window.Content>
        <ArcadeSweeperGame
          act={act}
          data={data}
        />
      </Window.Content>
    </Window>
  );
};
