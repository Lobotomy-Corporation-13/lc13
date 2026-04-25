/**
 * @file
 * @copyright 2024
 * @license MIT
 *
 * R Corp Hatchery - A DOOM-like FPS arcade
 * minigame. R Corp rabbit combat training.
 * Raycasting engine running
 * client-side for 60fps gameplay.
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

const SCREEN_W = 320;
const SCREEN_H = 200;
const CANVAS_W = 640;
const CANVAS_H = 400;
const FOV = Math.PI / 3;
const HALF_FOV = FOV / 2;
const MAX_DEPTH = 24;
const TILE_SIZE = 1;

// Key codes
const KEY_W = 87;
const KEY_A = 65;
const KEY_S = 83;
const KEY_D = 68;
const KEY_UP = 38;
const KEY_DOWN = 40;
const KEY_LEFT = 37;
const KEY_RIGHT = 39;
const KEY_SPACE = 32;
const KEY_1 = 49;
const KEY_2 = 50;
const KEY_ENTER = 13;
const KEY_R = 82;

// Player settings
const MOVE_SPEED = 3.0;
const ROT_SPEED = 2.5;
const PLAYER_RADIUS = 0.2;

// Weapon defs: [name, damage, cooldown, ammoCost, spread]
const WEAPONS = [
  ['RC Pistol', 1, 0.4, 1, 0],
  ['RC Scatter', 1, 0.8, 4, 0.1],
];

// Enemy defs: [hp, speed, damage, attackRange, color]
const ENEMY_DEFS = {
  enemy_blob: [5, 1.0, 8, 1.5, '#44cc44'],
  enemy_alien: [3, 2.5, 5, 1.2, '#cc44cc'],
  enemy_cult: [3, 1.5, 10, 8.0, '#cc4444'],
  // Crimson Clown: rushes and detonates
  enemy_exploder: [3, 2.5, 35, 2.0, '#ff8800'],
  // Crimson Dusk: charges in a line
  enemy_charger: [8, 1.2, 12, 8.0, '#aa2222'],
  // Steel Stalker: nearly invisible
  enemy_stealth: [4, 1.8, 8, 1.5, '#8888aa'],
  // Boss: powerful, multi-phase
  enemy_boss: [50, 1.0, 15, 8.0, '#ddaa00'],
};

// Game states
const STATE_TITLE = 0;
const STATE_PLAYING = 1;
const STATE_DEAD = 2;
const STATE_LEVEL_COMPLETE = 3;
const STATE_WIN = 4;
const STATE_NAMEENTRY = 5;

// =========================================
// Procedural Texture Generator
// =========================================

const makeTexture = (size, drawFn) => {
  const data = new Uint8ClampedArray(size * size * 4);
  drawFn(data, size);
  return { data, size };
};

const setPixel = (data, size, x, y, r, g, b) => {
  const i = (y * size + x) * 4;
  data[i] = r;
  data[i + 1] = g;
  data[i + 2] = b;
  data[i + 3] = 255;
};

const generateTextures = () => {
  const S = 32;
  const textures = {};

  // Wall 1: Iron/metal panels (grey with rivets)
  textures[1] = makeTexture(S, (d, s) => {
    for (let y = 0; y < s; y++) {
      for (let x = 0; x < s; x++) {
        let r = 100;
        let g = 105;
        let b = 110;
        // Panel lines
        if (x === 0 || y === 0) { r = 70; g = 75; b = 80; }
        if (x === s - 1 || y === s - 1) {
          r = 130; g = 135; b = 140;
        }
        // Rivets at corners
        const rx = x % 16;
        const ry = y % 16;
        if ((rx === 2 || rx === 3) && (ry === 2 || ry === 3)) {
          r = 140; g = 145; b = 150;
        }
        // Noise
        const n = ((x * 7 + y * 13) % 11) - 5;
        setPixel(d, s, x, y, r + n, g + n, b + n);
      }
    }
  });

  // Wall 2: Brick
  textures[2] = makeTexture(S, (d, s) => {
    for (let y = 0; y < s; y++) {
      for (let x = 0; x < s; x++) {
        let r = 160;
        let g = 80;
        let b = 60;
        // Mortar lines
        const by = y % 8;
        const off = (Math.floor(y / 8) % 2) * 8;
        const bx = (x + off) % 16;
        if (by === 0 || bx === 0) {
          r = 180; g = 175; b = 165;
        }
        const n = ((x * 3 + y * 7) % 9) - 4;
        setPixel(d, s, x, y, r + n, g + n, b + n);
      }
    }
  });

  // Wall 3: Rock/stone
  textures[3] = makeTexture(S, (d, s) => {
    for (let y = 0; y < s; y++) {
      for (let x = 0; x < s; x++) {
        const n1 = ((x * 17 + y * 31) % 23) - 11;
        const n2 = ((x * 7 + y * 3) % 13) - 6;
        const base = 90 + n1 + n2;
        setPixel(d, s, x, y, base, base - 5, base - 10);
      }
    }
  });

  // Wall 4: Cult (dark red with symbols)
  textures[4] = makeTexture(S, (d, s) => {
    for (let y = 0; y < s; y++) {
      for (let x = 0; x < s; x++) {
        let r = 80;
        let g = 20;
        let b = 30;
        // Pentagram-ish lines
        const cx = Math.abs(x - 16);
        const cy = Math.abs(y - 16);
        if (cx + cy === 12 || cx + cy === 13) {
          r = 160; g = 40; b = 50;
        }
        if (x === 16 && cy < 14) {
          r = 140; g = 35; b = 45;
        }
        const n = ((x * 11 + y * 7) % 7) - 3;
        setPixel(d, s, x, y, r + n, g + n, b + n);
      }
    }
  });

  // Wall 5: Exit door (bright green frame)
  textures[5] = makeTexture(S, (d, s) => {
    for (let y = 0; y < s; y++) {
      for (let x = 0; x < s; x++) {
        let r = 40;
        let g = 40;
        let b = 40;
        // Green door frame
        if (x < 3 || x >= s - 3 || y < 3) {
          r = 30; g = 180; b = 30;
        }
        // Door handle
        if (x >= 22 && x <= 24
          && y >= 14 && y <= 16) {
          r = 200; g = 200; b = 50;
        }
        // EXIT text area (simple horizontal bar)
        if (y >= 6 && y <= 9
          && x >= 6 && x <= 25) {
          r = 20; g = 140; b = 20;
        }
        setPixel(d, s, x, y, r, g, b);
      }
    }
  });

  // Wall 9: Locked door (red frame)
  textures[9] = makeTexture(S, (d, s) => {
    for (let y = 0; y < s; y++) {
      for (let x = 0; x < s; x++) {
        let r = 40;
        let g = 40;
        let b = 40;
        if (x < 3 || x >= s - 3 || y < 3) {
          r = 180; g = 30; b = 30;
        }
        if (x >= 22 && x <= 24
          && y >= 14 && y <= 16) {
          r = 200; g = 200; b = 50;
        }
        if (y >= 6 && y <= 9
          && x >= 6 && x <= 25) {
          r = 140; g = 20; b = 20;
        }
        setPixel(d, s, x, y, r, g, b);
      }
    }
  });

  // Wall 6: Amber/chitin (organic hive)
  textures[6] = makeTexture(S, (d, s) => {
    for (let y = 0; y < s; y++) {
      for (let x = 0; x < s; x++) {
        let r = 180;
        let g = 130;
        let b = 50;
        // Organic vein patterns
        const vx = (x * 5 + y * 3) % 17;
        const vy = (x * 3 + y * 7) % 13;
        if (vx < 2 || vy < 2) {
          r = 200; g = 150; b = 40;
        }
        // Chitin highlight bands
        if ((x + y) % 8 === 0) {
          r += 30; g += 20;
        }
        const n = (
          (x * 11 + y * 7) % 9
        ) - 4;
        setPixel(
          d, s, x, y,
          r + n, g + n, b + n
        );
      }
    }
  });

  // Wall 7: Green/tech (circuit board)
  textures[7] = makeTexture(S, (d, s) => {
    for (let y = 0; y < s; y++) {
      for (let x = 0; x < s; x++) {
        let r = 30;
        let g = 100;
        let b = 50;
        // Circuit traces
        if (x % 8 === 0 || y % 8 === 0) {
          r = 50; g = 180; b = 80;
        }
        // Solder points
        if (x % 8 < 2 && y % 8 < 2) {
          r = 80; g = 200; b = 100;
        }
        const n = (
          (x * 3 + y * 5) % 7
        ) - 3;
        setPixel(
          d, s, x, y,
          r + n, g + n, b + n
        );
      }
    }
  });

  // Wall 8: Violet/eldritch (dark purple)
  textures[8] = makeTexture(S, (d, s) => {
    for (let y = 0; y < s; y++) {
      for (let x = 0; x < s; x++) {
        let r = 60;
        let g = 20;
        let b = 80;
        // Glowing rune lines
        const rx = Math.abs(x - 16);
        const ry = Math.abs(y - 16);
        if ((rx + ry) % 10 < 2) {
          r = 120; g = 50; b = 180;
        }
        // Pulsing center rune
        if (rx < 3 && ry < 3) {
          r = 140; g = 60; b = 200;
        }
        const n = (
          (x * 7 + y * 11) % 9
        ) - 4;
        setPixel(
          d, s, x, y,
          r + n, g + n, b + n
        );
      }
    }
  });

  return textures;
};

// =========================================
// Map
// =========================================

class GameMap {
  constructor(mapData) {
    this.w = mapData.width;
    this.h = mapData.height;

    // Multi-layer support
    if (mapData.layers) {
      this.layers = mapData.layers;
      this.currentLayer = mapData.startLayer
        || (this.layers.length - 1);
      this.numLayers = this.layers.length;
    } else {
      // Legacy single-layer format
      this.layers = [mapData];
      this.currentLayer = 0;
      this.numLayers = 1;
    }

    // Build hole sets for each layer
    this.holeSets = [];
    for (let i = 0; i < this.numLayers; i++) {
      const s = new Set();
      const h = this.layers[i].holes;
      if (h) {
        for (let j = 0; j < h.length; j++) {
          s.add(h[j]);
        }
      }
      this.holeSets.push(s);
    }

    // Alias active layer properties
    this.syncLayer();
  }

  syncLayer() {
    const l = this.layers[this.currentLayer];
    this.cells = l.cells;
    this.floorH = l.floorH || null;
    this.ceilH = l.ceilH || null;
    this.elevators = l.elevators || null;
    this.slopes = l.slopes || null;
  }

  switchLayer(idx) {
    if (idx < 0 || idx >= this.numLayers) {
      return;
    }
    this.currentLayer = idx;
    this.syncLayer();
  }

  isHole(x, y) {
    const idx = y * this.w + x + 1;
    return this.holeSets[this.currentLayer]
      .has(idx);
  }

  get(x, y) {
    if (x < 0 || x >= this.w
      || y < 0 || y >= this.h) {
      return 1;
    }
    return this.cells[y * this.w + x];
  }

  getFloorH(x, y) {
    if (!this.floorH) return 0;
    if (x < 0 || x >= this.w
      || y < 0 || y >= this.h) return 0;
    return this.floorH[y * this.w + x];
  }

  getCeilH(x, y) {
    if (!this.ceilH) return 1;
    if (x < 0 || x >= this.w
      || y < 0 || y >= this.h) return 1;
    return this.ceilH[y * this.w + x];
  }

  setFloorH(x, y, val) {
    if (!this.floorH) return;
    if (x < 0 || x >= this.w
      || y < 0 || y >= this.h) return;
    this.floorH[y * this.w + x] = val;
  }

  // Get interpolated floor height at a
  // world position, accounting for slopes
  getFloorHAt(wx, wy) {
    const gx = Math.floor(wx);
    const gy = Math.floor(wy);
    const base = this.getFloorH(gx, gy);
    if (!this.slopes) return base;
    const idx = gy * this.w + gx;
    if (idx < 0 || idx >= this.slopes.length) {
      return base;
    }
    const s = this.slopes[idx];
    if (!s) return base;
    // Fraction within cell (0..1)
    const fx = wx - gx;
    const fy = wy - gy;
    switch (s.dir) {
      case 0: return base + fy * s.rise;
      case 1: return base + fx * s.rise;
      case 2: return base + (1 - fy) * s.rise;
      case 3: return base + (1 - fx) * s.rise;
      default: return base;
    }
  }

  isWall(x, y) {
    return this.get(x, y) !== 0;
  }

  // Check if cell is a full solid wall
  // (floor meets ceiling)
  isFullWall(x, y) {
    return this.get(x, y) !== 0;
  }

  canMove(wx, wy, playerZ) {
    const r = PLAYER_RADIUS;
    const corners = [
      [wx - r, wy - r],
      [wx + r, wy - r],
      [wx - r, wy + r],
      [wx + r, wy + r],
    ];
    const pz = playerZ || 0;
    for (let i = 0; i < corners.length; i++) {
      const px = corners[i][0];
      const py = corners[i][1];
      const gx = Math.floor(px);
      const gy = Math.floor(py);
      // Full walls always block
      if (this.isFullWall(gx, gy)) {
        return false;
      }
      // Height-based blocking
      if (this.floorH) {
        const fh = this.slopes
          ? this.getFloorHAt(px, py)
          : this.getFloorH(gx, gy);
        const ch = this.getCeilH(gx, gy);
        // Can't step up more than 0.3
        if (fh - pz > 0.3) return false;
        // Can't fit if gap too small
        if (ch - Math.max(fh, pz) < 0.6) {
          return false;
        }
      }
    }
    return true;
  }
}

// =========================================
// Entity (enemies + pickups)
// =========================================

class Entity {
  constructor(type, x, y) {
    this.type = type;
    this.x = x;
    this.y = y;
    this.alive = true;
    this.hurtTimer = 0;

    const def = ENEMY_DEFS[type];
    if (def) {
      this.isEnemy = true;
      this.hp = def[0];
      this.maxHp = def[0];
      this.speed = def[1];
      this.damage = def[2];
      this.attackRange = def[3];
      this.color = def[4];
      this.state = 'idle';
      this.attackCooldown = 0;
      this.seesPlayer = false;
      // Ranged telegraph
      this.windupTimer = 0;
      this.fireFlash = 0;
      // Exploder countdown
      this.detonateTimer = -1;
      // Charger dash
      this.chargeDir = null;
      this.chargeTimer = 0;
      this.recoveryTimer = 0;
      // Stealth visibility (0..1)
      this.visibility = 1;
      // Boss phases
      if (type === 'enemy_boss') {
        this.bossPhase = 'chase';
        this.phaseTimer = 3.0;
        this.chargesLeft = 0;
      }
    } else if (type === 'projectile_fireball') {
      this.isEnemy = false;
      this.isFireball = true;
      this.lifetime = 8;
      this.fbSpeed = 2.0;
      this.color = '#ff8800';
      this.damage = 15;
    } else {
      this.isEnemy = false;
    }
  }

  update(dt, player, map, engine) {
    if (!this.alive) return;
    if (this.hurtTimer > 0) this.hurtTimer -= dt;
    if (this.fireFlash > 0) this.fireFlash -= dt;

    // Fireball homing projectile
    if (this.isFireball) {
      this.lifetime -= dt;
      if (this.lifetime <= 0) {
        this.alive = false;
        return;
      }
      const fdx = player.x - this.x;
      const fdy = player.y - this.y;
      const fd = Math.sqrt(
        fdx * fdx + fdy * fdy
      );
      if (fd > 0.1) {
        const mx = (fdx / fd)
          * this.fbSpeed * dt;
        const my = (fdy / fd)
          * this.fbSpeed * dt;
        this.x += mx;
        this.y += my;
      }
      // Hit player
      if (fd < 0.6) {
        player.takeDamage(this.damage);
        this.alive = false;
        if (engine) {
          engine.addEffect(
            'explosion',
            this.x, this.y, 0.3
          );
        }
        return;
      }
      // Hit boss (damages boss)
      if (engine) {
        for (let bi = 0;
          bi < engine.entities.length;
          bi++) {
          const b = engine.entities[bi];
          if (b.type !== 'enemy_boss'
            || !b.alive) continue;
          const bdx = b.x - this.x;
          const bdy = b.y - this.y;
          if (bdx * bdx + bdy * bdy
            < 1.0) {
            b.takeDamage(10);
            this.alive = false;
            engine.addEffect(
              'explosion',
              this.x, this.y, 0.3
            );
            return;
          }
        }
      }
      return;
    }

    if (!this.isEnemy) return;
    if (this.attackCooldown > 0) {
      this.attackCooldown -= dt;
    }

    const dx = player.x - this.x;
    const dy = player.y - this.y;
    const dist = Math.sqrt(dx * dx + dy * dy);

    this.seesPlayer = this.hasLOS(
      player.x, player.y, map
    );

    // Stealth visibility
    if (this.type === 'enemy_stealth') {
      if (this.hurtTimer > 0) {
        this.visibility = 1;
      } else if (dist < 3) {
        this.visibility = Math.max(
          0.08, 1 - dist / 3
        );
      } else {
        this.visibility = 0.03;
      }
    }

    // Exploder detonation countdown
    if (this.type === 'enemy_exploder'
      && this.detonateTimer >= 0) {
      this.detonateTimer -= dt;
      if (this.detonateTimer <= 0) {
        this.alive = false;
        if (engine) {
          engine.addEffect(
            'explosion', this.x, this.y, 0.5
          );
          engine.triggerSound('explode');
          if (dist < 4) {
            const dmg = Math.floor(
              this.damage * (1 - dist / 4)
            );
            player.takeDamage(dmg);
          }
        }
      }
      return;
    }

    // Charger special states
    if (this.type === 'enemy_charger') {
      if (this.state === 'windup') {
        this.windupTimer -= dt;
        if (this.windupTimer <= 0) {
          this.state = 'charging';
          this.chargeTimer = 0.8;
        }
        return;
      }
      if (this.state === 'charging') {
        this.chargeTimer -= dt;
        const spd = 8 * dt;
        const nx = this.x
          + this.chargeDir.x * spd;
        const ny = this.y
          + this.chargeDir.y * spd;
        if (map.canMove(nx, ny)) {
          this.x = nx;
          this.y = ny;
        } else {
          this.chargeTimer = 0;
        }
        const cd = player.x - this.x;
        const cdy = player.y - this.y;
        if (cd * cd + cdy * cdy < 0.8) {
          player.takeDamage(this.damage);
          this.chargeTimer = 0;
        }
        if (this.chargeTimer <= 0) {
          this.state = 'recovery';
          this.recoveryTimer = 1.5;
        }
        return;
      }
      if (this.state === 'recovery') {
        this.recoveryTimer -= dt;
        if (this.recoveryTimer <= 0) {
          this.state = 'chase';
        }
        return;
      }
    }

    // Boss AI
    if (this.type === 'enemy_boss') {
      this.phaseTimer -= dt;

      if (this.bossPhase === 'chase') {
        if (this.seesPlayer && dist > 3) {
          const mx = (dx / dist)
            * this.speed * dt;
          const my = (dy / dist)
            * this.speed * dt;
          if (map.canMove(
            this.x + mx, this.y
          )) {
            this.x += mx;
          }
          if (map.canMove(
            this.x, this.y + my
          )) {
            this.y += my;
          }
        }
        if (this.phaseTimer <= 0) {
          const roll = Math.random();
          if (roll < 0.4) {
            this.bossPhase = 'charge_combo';
            this.chargesLeft = 3;
            this.windupTimer = 0.5;
            const d2 = Math.max(dist, 0.1);
            this.chargeDir = {
              x: dx / d2, y: dy / d2,
            };
          } else if (roll < 0.7) {
            this.bossPhase = 'summon';
            this.windupTimer = 0.5;
          } else {
            this.bossPhase = 'fireball';
            this.windupTimer = 0.8;
          }
        }
        return;
      }

      if (this.bossPhase === 'charge_combo') {
        if (this.windupTimer > 0) {
          this.windupTimer -= dt;
          return;
        }
        if (this.chargeTimer <= 0
          && this.chargesLeft > 0) {
          this.chargeTimer = 0.8;
        }
        if (this.chargeTimer > 0) {
          this.chargeTimer -= dt;
          const spd = 8 * dt;
          const nx = this.x
            + this.chargeDir.x * spd;
          const ny = this.y
            + this.chargeDir.y * spd;
          if (map.canMove(nx, ny)) {
            this.x = nx;
            this.y = ny;
          } else {
            // Hit wall: re-target
            this.chargeTimer = 0;
          }
          const cd = player.x - this.x;
          const cdy = player.y - this.y;
          if (cd * cd + cdy * cdy < 1.0) {
            player.takeDamage(this.damage);
            this.chargeTimer = 0;
          }
          if (this.chargeTimer <= 0) {
            this.chargesLeft--;
            if (this.chargesLeft > 0) {
              this.windupTimer = 0.3;
              const d3 = Math.max(
                Math.sqrt(
                  (player.x - this.x) ** 2
                  + (player.y - this.y) ** 2
                ), 0.1
              );
              this.chargeDir = {
                x: (player.x - this.x)
                  / d3,
                y: (player.y - this.y)
                  / d3,
              };
            } else {
              this.bossPhase = 'chase';
              this.phaseTimer = 3
                + Math.random() * 2;
            }
          }
        }
        return;
      }

      if (this.bossPhase === 'summon') {
        this.windupTimer -= dt;
        if (this.windupTimer <= 0 && engine) {
          const types = [
            'enemy_blob',
            'enemy_exploder',
          ];
          for (let si = 0; si < 2; si++) {
            const st = types[si];
            const sx = this.x
              + (Math.random() - 0.5) * 3;
            const sy = this.y
              + (Math.random() - 0.5) * 3;
            engine.entities.push(
              new Entity(st, sx, sy)
            );
          }
          this.bossPhase = 'chase';
          this.phaseTimer = 4
            + Math.random() * 2;
        }
        return;
      }

      if (this.bossPhase === 'fireball') {
        this.windupTimer -= dt;
        if (this.windupTimer <= 0 && engine) {
          for (let fi = 0; fi < 2; fi++) {
            const fx = this.x
              + (Math.random() - 0.5) * 2;
            const fy = this.y
              + (Math.random() - 0.5) * 2;
            engine.entities.push(
              new Entity(
                'projectile_fireball',
                fx, fy
              )
            );
          }
          engine.triggerSound('explode');
          this.bossPhase = 'chase';
          this.phaseTimer = 3
            + Math.random() * 2;
        }
        return;
      }
      return;
    }

    // Standard AI: idle/chase/attack
    if (this.state === 'idle'
      && this.seesPlayer) {
      this.state = 'chase';
    }

    if (this.state === 'chase') {
      if (!this.seesPlayer) {
        this.state = 'idle';
        return;
      }
      if (dist <= this.attackRange) {
        this.state = 'attack';
      } else {
        const mx = (dx / dist)
          * this.speed * dt;
        const my = (dy / dist)
          * this.speed * dt;
        if (map.canMove(
          this.x + mx, this.y
        )) {
          this.x += mx;
        }
        if (map.canMove(
          this.x, this.y + my
        )) {
          this.y += my;
        }
      }
    }

    if (this.state === 'attack') {
      if (dist > this.attackRange * 1.2) {
        this.state = 'chase';
        return;
      }
      if (this.attackCooldown <= 0) {
        if (this.type === 'enemy_cult') {
          // Ranged: windup then fire
          if (this.windupTimer > 0) {
            this.windupTimer -= dt;
            if (this.windupTimer <= 0) {
              player.takeDamage(this.damage);
              this.fireFlash = 0.25;
              this.attackCooldown = 1.5;
              if (engine) {
                engine.triggerSound('shoot');
              }
            }
          } else if (this.fireFlash <= 0) {
            this.windupTimer = 0.6;
          }
        } else if (
          this.type === 'enemy_exploder'
        ) {
          this.detonateTimer = 0.8;
        } else if (
          this.type === 'enemy_charger'
        ) {
          this.windupTimer = 0.5;
          this.state = 'windup';
          const d = Math.max(dist, 0.1);
          this.chargeDir = {
            x: dx / d, y: dy / d,
          };
          this.attackCooldown = 3.0;
        } else {
          // Default melee attack
          player.takeDamage(this.damage);
          this.attackCooldown = 1.0;
        }
      }
    }

    // Keep minimum distance from player
    // so enemies stay visible on screen
    if (this.state !== 'charging') {
      const ex = this.x - player.x;
      const ey = this.y - player.y;
      const ed = Math.sqrt(
        ex * ex + ey * ey
      );
      if (ed < 0.8 && ed > 0.01) {
        const push = 0.8 - ed;
        const nx = this.x
          + (ex / ed) * push;
        const ny = this.y
          + (ey / ed) * push;
        if (map.canMove(nx, ny)) {
          this.x = nx;
          this.y = ny;
        }
      }
    }
  }

  hasLOS(px, py, map) {
    const dx = px - this.x;
    const dy = py - this.y;
    const dist = Math.sqrt(dx * dx + dy * dy);
    if (dist > MAX_DEPTH) return false;
    const steps = Math.ceil(dist * 2);
    for (let i = 0; i <= steps; i++) {
      const t = i / steps;
      const cx = this.x + dx * t;
      const cy = this.y + dy * t;
      if (map.isWall(
        Math.floor(cx), Math.floor(cy)
      )) {
        return false;
      }
    }
    return true;
  }

  takeDamage(dmg) {
    if (!this.alive) return;
    this.hp -= dmg;
    this.hurtTimer = 0.15;
    if (this.hp <= 0) {
      this.alive = false;
    }
  }
}

// =========================================
// Player
// =========================================

class Player {
  constructor(startData) {
    this.x = startData.x;
    this.y = startData.y;
    this.angle = startData.angle;
    this.hp = 100;
    this.maxHp = 100;
    this.ammo = 50;
    this.score = 0;
    this.weapon = 0;
    this.weaponCooldown = 0;
    this.hurtFlash = 0;
    this.weaponBob = 0;
    this.weaponKick = 0;
    this.moving = false;
    this.pitch = 0;
    this.z = 0;
    this.vz = 0;
    this.eyeHeight = 0.6;
    this.hasKey = false;
  }

  takeDamage(dmg) {
    this.hp -= dmg;
    this.hurtFlash = 0.3;
    if (this.hp < 0) this.hp = 0;
  }
}

// =========================================
// Renderer (DDA Raycaster)
// =========================================

class Renderer {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    // Offscreen buffer at internal resolution
    this.buf = document.createElement('canvas');
    this.buf.width = SCREEN_W;
    this.buf.height = SCREEN_H;
    this.bctx = this.buf.getContext('2d');
    this.imgData = this.bctx.createImageData(
      SCREEN_W, SCREEN_H
    );
    this.depthBuf = new Float32Array(SCREEN_W);
    this.textures = generateTextures();
  }

  render(player, map, entities, effects) {
    const d = this.imgData.data;
    const horizon = Math.floor(
      SCREEN_H / 2 + player.pitch
    );
    // Clear to ceiling + floor
    for (let y = 0; y < SCREEN_H; y++) {
      for (let x = 0; x < SCREEN_W; x++) {
        const i = (y * SCREEN_W + x) * 4;
        if (y < horizon) {
          const h = Math.max(horizon, 1);
          const f = y / h;
          d[i] = Math.floor(20 + 20 * f);
          d[i + 1] = Math.floor(
            20 + 25 * f
          );
          d[i + 2] = Math.floor(
            40 + 30 * f
          );
        } else {
          const floorH = SCREEN_H - horizon;
          const fh = Math.max(floorH, 1);
          const f = (y - horizon) / fh;
          const v = Math.floor(30 + 50 * f);
          d[i] = v;
          d[i + 1] = v;
          d[i + 2] = v - 5;
        }
        d[i + 3] = 255;
      }
    }

    // Raycast walls
    for (let col = 0; col < SCREEN_W; col++) {
      const rayAngle = player.angle - HALF_FOV
        + (col / SCREEN_W) * FOV;
      this.castRay(
        col, player, map, rayAngle, d
      );
    }

    this.bctx.putImageData(this.imgData, 0, 0);
    this.drawSprites(player, entities);
    this.drawEffects(player, effects || []);
    this.drawHUD(player);
    this.drawWeapon(player);

    // Hurt flash overlay
    if (player.hurtFlash > 0) {
      this.bctx.fillStyle = 'rgba(255,0,0,'
        + (player.hurtFlash * 0.6).toFixed(2)
        + ')';
      this.bctx.fillRect(
        0, 0, SCREEN_W, SCREEN_H
      );
    }

    // Scale up to display canvas
    this.ctx.imageSmoothingEnabled = false;
    this.ctx.drawImage(
      this.buf, 0, 0, CANVAS_W, CANVAS_H
    );
  }

  castRay(col, player, map, angle, d) {
    const sinA = Math.sin(angle);
    const cosA = Math.cos(angle);
    let mapX = Math.floor(player.x);
    let mapY = Math.floor(player.y);
    const ddx = Math.abs(1 / (cosA || 1e-10));
    const ddy = Math.abs(1 / (sinA || 1e-10));
    let stepX, stepY, sideDistX, sideDistY;
    let side;

    if (cosA < 0) {
      stepX = -1;
      sideDistX = (player.x - mapX) * ddx;
    } else {
      stepX = 1;
      sideDistX = (mapX + 1 - player.x) * ddx;
    }
    if (sinA < 0) {
      stepY = -1;
      sideDistY = (player.y - mapY) * ddy;
    } else {
      stepY = 1;
      sideDistY = (mapY + 1 - player.y) * ddy;
    }

    const pitchOff = Math.floor(player.pitch);
    const eyeZ = player.z + player.eyeHeight;
    const hasHeights = !!map.floorH;
    let prevFloorH = hasHeights
      ? (map.slopes
        ? map.getFloorHAt(player.x, player.y)
        : map.getFloorH(mapX, mapY))
      : 0;
    let prevCeilH = hasHeights
      ? map.getCeilH(mapX, mapY) : 1;

    // Track drawn screen boundaries
    let yTop = 0;
    let yBot = SCREEN_H - 1;

    // DDA loop - continue through cells
    let depth = 0;
    this.depthBuf[col] = MAX_DEPTH;

    while (depth < MAX_DEPTH
      && yTop < yBot) {
      if (sideDistX < sideDistY) {
        sideDistX += ddx;
        mapX += stepX;
        side = 0;
      } else {
        sideDistY += ddy;
        mapY += stepY;
        side = 1;
      }
      depth++;

      // Perpendicular distance to this cell
      let perpDist;
      let wallX;
      if (side === 0) {
        perpDist = (
          mapX - player.x
            + (1 - stepX) / 2
        ) / cosA;
        wallX = player.y + perpDist * sinA;
      } else {
        perpDist = (
          mapY - player.y
            + (1 - stepY) / 2
        ) / sinA;
        wallX = player.x + perpDist * cosA;
      }
      wallX -= Math.floor(wallX);
      if (perpDist <= 0.01) continue;

      const cellType = map.get(mapX, mapY);
      const cellCeilH = hasHeights
        ? map.getCeilH(mapX, mapY) : 1;

      // Get floor height — use slope
      // interpolation at ray hit point
      const hitWX = player.x + perpDist * cosA;
      const hitWY = player.y + perpDist * sinA;
      let cellFloorH;
      const hasSlope = map.slopes
        && map.slopes[mapY * map.w + mapX];
      if (hasSlope) {
        cellFloorH = map.getFloorHAt(
          hitWX, hitWY
        );
      } else {
        cellFloorH = hasHeights
          ? map.getFloorH(mapX, mapY) : 0;
      }

      // Any non-zero cell type is a solid wall
      const isFullWall = cellType !== 0;

      // Scale factor for this distance
      const wallUnit = SCREEN_H
        / (perpDist || 0.01);
      const shade = side === 1 ? 0.7 : 1.0;
      const fog = 1 - Math.min(
        perpDist / MAX_DEPTH, 0.8
      );

      // Helper to get screen Y for a height
      const hToY = h => {
        return Math.floor(
          SCREEN_H / 2
            - (h - eyeZ) * wallUnit
            + pitchOff
        );
      };

      if (isFullWall) {
        // Draw full wall and stop
        const wTop = hToY(cellCeilH);
        const wBot = hToY(cellFloorH);
        // Red door when locked
        const drawType = (
          cellType === 5
          && this.needsKeyDoor
        ) ? 9 : cellType;
        this.drawWallSlice(
          col, d, wallX,
          Math.max(wTop, yTop),
          Math.min(wBot, yBot),
          wTop, wBot - wTop,
          drawType, shade, fog
        );
        this.depthBuf[col] = perpDist;
        return;
      }

      if (hasHeights) {
        // Floor height change (up or down)
        const floorDiff = cellFloorH
          - prevFloorH;
        if (Math.abs(floorDiff) > 0.01) {
          const bPrev = hToY(prevFloorH);
          const bCurr = hToY(cellFloorH);
          const t = Math.max(
            Math.min(bCurr, bPrev), yTop
          );
          const b = Math.min(
            Math.max(bCurr, bPrev), yBot
          );
          if (b > t) {
            const wType = cellType || 3;
            if (hasSlope) {
              this.drawSlopeSlice(
                col, d, t, b,
                shade, fog
              );
            } else {
              this.drawWallSlice(
                col, d, wallX, t, b,
                t, b - t,
                wType, shade, fog
              );
            }
            if (floorDiff > 0) {
              // Step up: clamp bottom
              yBot = Math.min(yBot, t);
            }
          }
        }

        // Ceiling height change
        const ceilDiff = cellCeilH
          - prevCeilH;
        if (Math.abs(ceilDiff) > 0.01) {
          const cPrev = hToY(prevCeilH);
          const cCurr = hToY(cellCeilH);
          const t = Math.max(
            Math.min(cPrev, cCurr), yTop
          );
          const b = Math.min(
            Math.max(cPrev, cCurr), yBot
          );
          if (b > t) {
            const wType = cellType || 1;
            this.drawWallSlice(
              col, d, wallX, t, b,
              t, b - t,
              wType, shade, fog
            );
            if (ceilDiff < 0) {
              // Ceiling drop: clamp top
              yTop = Math.max(yTop, b);
            }
          }
        }

        prevFloorH = cellFloorH;
        prevCeilH = cellCeilH;
      }

      // Update depth for sprites
      if (this.depthBuf[col] >= MAX_DEPTH) {
        this.depthBuf[col] = perpDist;
      }
    }
  }

  drawWallSlice(
    col, d, wallX,
    drawTop, drawBot,
    rawTop, rawH,
    wallType, shade, fog
  ) {
    const tex = this.textures[wallType];
    if (!tex) return;
    const texX = Math.floor(
      wallX * tex.size
    ) % tex.size;
    const s = shade * fog;
    const h = Math.max(rawH, 1);

    for (let y = drawTop; y <= drawBot; y++) {
      if (y < 0 || y >= SCREEN_H) continue;
      const texY = Math.floor(
        ((y - rawTop) / h) * tex.size
      ) % tex.size;
      const ti = (texY * tex.size + texX) * 4;
      const pi = (y * SCREEN_W + col) * 4;
      d[pi] = Math.floor(tex.data[ti] * s);
      d[pi + 1] = Math.floor(
        tex.data[ti + 1] * s
      );
      d[pi + 2] = Math.floor(
        tex.data[ti + 2] * s
      );
    }
  }

  drawSlopeSlice(col, d, top, bot, shade, fog) {
    const s = shade * fog;
    for (let y = top; y <= bot; y++) {
      if (y < 0 || y >= SCREEN_H) continue;
      const pi = (y * SCREEN_W + col) * 4;
      // Brown/tan slope surface color
      d[pi] = Math.floor(120 * s);
      d[pi + 1] = Math.floor(90 * s);
      d[pi + 2] = Math.floor(60 * s);
    }
  }

  drawSprites(player, entities) {
    // Collect visible, alive entities
    const visible = [];
    for (let i = 0; i < entities.length; i++) {
      const e = entities[i];
      if (!e.alive) continue;
      const dx = e.x - player.x;
      const dy = e.y - player.y;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < 0.3 || dist > MAX_DEPTH) continue;
      visible.push({ e, dx, dy, dist });
    }

    // Sort far to near
    visible.sort((a, b) => b.dist - a.dist);

    const ctx = this.bctx;
    for (let i = 0; i < visible.length; i++) {
      const { e, dx, dy, dist } = visible[i];
      // Transform relative to player view
      const invDet = 1.0 / (
        Math.cos(player.angle)
          * Math.sin(player.angle + Math.PI / 2)
        - Math.sin(player.angle)
          * Math.cos(player.angle + Math.PI / 2)
      );
      // Simplified: project to screen
      const angle = Math.atan2(dy, dx);
      let relAngle = angle - player.angle;
      // Normalize to -PI..PI
      while (relAngle > Math.PI) {
        relAngle -= 2 * Math.PI;
      }
      while (relAngle < -Math.PI) {
        relAngle += 2 * Math.PI;
      }
      if (Math.abs(relAngle) > HALF_FOV + 0.2) {
        continue;
      }

      const screenX = Math.floor(
        (0.5 + relAngle / FOV) * SCREEN_W
      );
      let spScale = 0.8;
      if (e.type === 'enemy_boss') {
        spScale = 1.4;
      } else if (e.isFireball) {
        spScale = 0.4;
      }
      const spriteH = Math.floor(
        SCREEN_H / dist * spScale
      );
      const spriteW = spriteH;
      const sx = screenX - spriteW / 2;
      const pitchY = Math.floor(player.pitch);
      const sy = (SCREEN_H - spriteH) / 2
        + pitchY;

      // Determine color and alpha
      let color;
      let alpha = 1;
      if (e.isEnemy) {
        color = e.hurtTimer > 0
          ? '#ffffff' : e.color;
        if (e.type === 'enemy_stealth') {
          alpha = e.visibility;
        }
      } else if (e.isFireball) {
        color = '#ff8800';
      } else if (e.type === 'pickup_key') {
        color = '#ffdd00';
      } else if (e.type === 'pickup_health') {
        color = '#44ff44';
      } else {
        color = '#ffff44';
      }

      const colStart = Math.max(
        0, Math.floor(sx)
      );
      const colEnd = Math.min(
        SCREEN_W - 1,
        Math.floor(sx + spriteW)
      );

      // Set alpha for stealth
      const prevAlpha = ctx.globalAlpha;
      ctx.globalAlpha = alpha;
      ctx.fillStyle = color;

      for (let c = colStart; c <= colEnd; c++) {
        if (this.depthBuf[c] < dist) continue;
        const sprFrac = (c - sx) / spriteW;

        if (e.isEnemy) {
          if (e.type === 'enemy_exploder') {
            // Spiky star shape
            const cx2 = sprFrac - 0.5;
            const ang = Math.abs(cx2) * 12;
            const spike = 0.3 + Math.abs(
              Math.sin(ang)
            ) * 0.2;
            const y1 = Math.floor(
              sy + spriteH * (0.5 - spike)
            );
            const y2 = Math.floor(
              sy + spriteH * (0.5 + spike)
            );
            // Pulse when detonating
            if (e.detonateTimer >= 0) {
              const pulse = Math.sin(
                e.detonateTimer * 20
              );
              ctx.fillStyle = pulse > 0
                ? '#ffff00' : '#ff4400';
            }
            ctx.fillRect(c, y1, 1, y2 - y1);
            ctx.fillStyle = color;
          } else if (
            e.type === 'enemy_charger'
          ) {
            // Arrow/wedge shape
            const cx2 = sprFrac - 0.5;
            let h2;
            if (e.state === 'charging') {
              // Stretched during charge
              h2 = Math.max(
                0, 0.4 - Math.abs(cx2) * 1.2
              );
            } else {
              h2 = Math.max(
                0, 0.35 - Math.abs(cx2)
              );
            }
            const y1 = Math.floor(
              sy + spriteH * (0.5 - h2)
            );
            const y2 = Math.floor(
              sy + spriteH * (0.5 + h2)
            );
            ctx.fillRect(c, y1, 1, y2 - y1);
            // Horns on front
            if (sprFrac > 0.4
              && sprFrac < 0.6) {
              ctx.fillStyle = '#ff4444';
              ctx.fillRect(
                c,
                Math.floor(
                  sy + spriteH * 0.15
                ),
                1,
                Math.max(1, spriteH / 8)
              );
              ctx.fillStyle = color;
            }
          } else if (
            e.type === 'enemy_boss'
          ) {
            // Boss: large circle + crown
            const cx2 = sprFrac - 0.5;
            const h2 = Math.sqrt(
              Math.max(0, 0.25 - cx2 * cx2)
            );
            const y1 = Math.floor(
              sy + spriteH * (0.5 - h2)
            );
            const y2 = Math.floor(
              sy + spriteH * (0.5 + h2)
            );
            ctx.fillRect(
              c, y1, 1, y2 - y1
            );
            // Crown spikes
            if (Math.abs(cx2) < 0.4) {
              const spike = Math.sin(
                cx2 * 20
              ) * 0.08;
              ctx.fillStyle = '#ffcc00';
              ctx.fillRect(
                c,
                Math.floor(
                  sy + spriteH
                    * (0.15 + spike)
                ),
                1,
                Math.max(1, spriteH / 6)
              );
              ctx.fillStyle = color;
            }
            // Glowing eyes
            if ((sprFrac > 0.3
              && sprFrac < 0.42)
              || (sprFrac > 0.58
              && sprFrac < 0.7)) {
              ctx.fillStyle = '#ff0000';
              ctx.fillRect(
                c,
                Math.floor(
                  sy + spriteH * 0.38
                ),
                1,
                Math.max(2, spriteH / 8)
              );
              ctx.fillStyle = color;
            }
          } else {
            // Standard circle shape
            const cx2 = sprFrac - 0.5;
            const h2 = Math.sqrt(
              Math.max(0, 0.25 - cx2 * cx2)
            );
            const y1 = Math.floor(
              sy + spriteH * (0.5 - h2)
            );
            const y2 = Math.floor(
              sy + spriteH * (0.5 + h2)
            );
            ctx.fillRect(c, y1, 1, y2 - y1);
            // Eyes
            if (sprFrac > 0.3
              && sprFrac < 0.45) {
              ctx.fillStyle = '#ff0000';
              ctx.fillRect(
                c,
                Math.floor(
                  sy + spriteH * 0.35
                ),
                1,
                Math.max(1, spriteH / 10)
              );
              ctx.fillStyle = color;
            }
            if (sprFrac > 0.55
              && sprFrac < 0.7) {
              ctx.fillStyle = '#ff0000';
              ctx.fillRect(
                c,
                Math.floor(
                  sy + spriteH * 0.35
                ),
                1,
                Math.max(1, spriteH / 10)
              );
              ctx.fillStyle = color;
            }
          }
        } else if (e.isFireball) {
          // Pulsing fireball orb
          const cx2 = sprFrac - 0.5;
          const pulse = Math.sin(
            performance.now() * 0.01
          );
          const r2 = 0.2 + pulse * 0.05;
          if (cx2 * cx2 < r2 * r2) {
            const fh = Math.sqrt(
              r2 * r2 - cx2 * cx2
            );
            const y1 = Math.floor(
              sy + spriteH * (0.5 - fh)
            );
            const y2 = Math.floor(
              sy + spriteH * (0.5 + fh)
            );
            ctx.fillStyle = pulse > 0
              ? '#ffaa00' : '#ff6600';
            ctx.fillRect(
              c, y1, 1, y2 - y1
            );
            ctx.fillStyle = color;
          }
        } else if (e.type === 'pickup_key') {
          // Cross shape for key
          const kx = sprFrac - 0.5;
          if (Math.abs(kx) < 0.15) {
            const y1 = Math.floor(
              sy + spriteH * 0.2
            );
            const y2 = Math.floor(
              sy + spriteH * 0.8
            );
            ctx.fillRect(
              c, y1, 1, y2 - y1
            );
          } else if (Math.abs(kx) < 0.35) {
            const y1 = Math.floor(
              sy + spriteH * 0.35
            );
            const y2 = Math.floor(
              sy + spriteH * 0.65
            );
            ctx.fillRect(
              c, y1, 1, y2 - y1
            );
          }
        } else {
          // Diamond shape for pickups
          const cx2 = Math.abs(
            sprFrac - 0.5
          ) * 2;
          const h2 = (1 - cx2) * 0.5;
          const y1 = Math.floor(
            sy + spriteH * (0.5 - h2)
          );
          const y2 = Math.floor(
            sy + spriteH * (0.5 + h2)
          );
          ctx.fillRect(c, y1, 1, y2 - y1);
        }
      }

      ctx.globalAlpha = 1;

      // Cult ranged: windup glow + fire beam
      if (e.type === 'enemy_cult'
        && e.windupTimer > 0) {
        // Pulsing red glow around sprite
        const glowR = spriteW * 0.8;
        const pulse = Math.sin(
          e.windupTimer * 15
        );
        const ga = 0.2 + pulse * 0.15;
        ctx.fillStyle = 'rgba(255,60,60,'
          + ga.toFixed(2) + ')';
        ctx.beginPath();
        ctx.arc(
          screenX,
          sy + spriteH / 2,
          glowR, 0, Math.PI * 2
        );
        ctx.fill();
        // Targeting line to crosshair
        const crossY = Math.floor(
          SCREEN_H / 2 + player.pitch
        );
        ctx.strokeStyle = 'rgba(255,80,80,'
          + (0.3 + pulse * 0.2).toFixed(2)
          + ')';
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.moveTo(
          screenX, sy + spriteH / 2
        );
        ctx.lineTo(
          SCREEN_W / 2, crossY
        );
        ctx.stroke();
      }
      if (e.type === 'enemy_cult'
        && e.fireFlash > 0) {
        // Bright beam from enemy to player
        const crossY = Math.floor(
          SCREEN_H / 2 + player.pitch
        );
        const fa = (
          e.fireFlash / 0.25
        ).toFixed(2);
        ctx.strokeStyle = 'rgba(255,200,50,'
          + fa + ')';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(
          screenX, sy + spriteH / 2
        );
        ctx.lineTo(
          SCREEN_W / 2, crossY
        );
        ctx.stroke();
        ctx.lineWidth = 1;
      }

      // Boss windup glow
      if (e.type === 'enemy_boss'
        && e.windupTimer > 0) {
        const glowR = spriteW;
        const pulse = Math.sin(
          e.windupTimer * 12
        );
        const bClr = (
          e.bossPhase === 'charge_combo'
        ) ? '255,50,50' : '255,180,0';
        const ga = (
          0.3 + pulse * 0.2
        ).toFixed(2);
        ctx.fillStyle = 'rgba('
          + bClr + ',' + ga + ')';
        ctx.beginPath();
        ctx.arc(
          screenX, sy + spriteH / 2,
          glowR, 0, Math.PI * 2
        );
        ctx.fill();
      }

      // Health bar for enemies
      if (e.isEnemy && e.hp < e.maxHp) {
        const barW = spriteW * 0.6;
        const barX = screenX - barW / 2;
        const barY = sy - 4;
        ctx.fillStyle = '#333';
        ctx.fillRect(barX, barY, barW, 3);
        ctx.fillStyle = '#ff0000';
        ctx.fillRect(
          barX, barY,
          barW * (e.hp / e.maxHp), 3
        );
      }
    }
  }

  drawWeapon(player) {
    const ctx = this.bctx;
    const w = WEAPONS[player.weapon];
    const bobX = Math.sin(
      player.weaponBob
    ) * 3;
    const bobY = Math.abs(Math.cos(
      player.weaponBob
    )) * 2;
    const kickY = player.weaponKick * 20;
    const baseX = SCREEN_W / 2 - 20 + bobX;
    const baseY = SCREEN_H - 65 + bobY - kickY;

    // Weapon body
    if (player.weapon === 0) {
      // Pistol
      ctx.fillStyle = '#888';
      ctx.fillRect(
        baseX + 15, baseY, 10, 30
      );
      ctx.fillStyle = '#666';
      ctx.fillRect(
        baseX + 12, baseY + 25, 16, 12
      );
      ctx.fillStyle = '#555';
      ctx.fillRect(
        baseX + 17, baseY - 5, 6, 8
      );
      // Muzzle flash
      if (player.weaponKick > 0.15) {
        ctx.fillStyle = '#ffff44';
        ctx.fillRect(
          baseX + 14, baseY - 12, 12, 10
        );
      }
    } else {
      // Shotgun
      ctx.fillStyle = '#777';
      ctx.fillRect(
        baseX + 10, baseY - 5, 8, 40
      );
      ctx.fillRect(
        baseX + 22, baseY - 5, 8, 40
      );
      ctx.fillStyle = '#996633';
      ctx.fillRect(
        baseX + 8, baseY + 30, 24, 15
      );
      ctx.fillStyle = '#555';
      ctx.fillRect(
        baseX + 12, baseY - 10, 16, 8
      );
      if (player.weaponKick > 0.15) {
        ctx.fillStyle = '#ffaa22';
        ctx.fillRect(
          baseX + 8, baseY - 20, 24, 14
        );
      }
    }
  }

  drawHUD(player) {
    const ctx = this.bctx;

    // Health bar - bottom left
    ctx.fillStyle = '#333333';
    ctx.fillRect(8, SCREEN_H - 18, 80, 10);
    const hpFrac = player.hp / player.maxHp;
    ctx.fillStyle = hpFrac > 0.5
      ? '#44cc44'
      : hpFrac > 0.25
        ? '#cccc44'
        : '#cc4444';
    ctx.fillRect(
      8, SCREEN_H - 18,
      Math.floor(80 * hpFrac), 10
    );
    ctx.fillStyle = '#ffffff';
    ctx.font = '8px monospace';
    ctx.fillText(
      'HP:' + player.hp,
      10, SCREEN_H - 10
    );

    // Ammo - bottom right
    ctx.fillStyle = '#ffffff';
    ctx.font = '8px monospace';
    ctx.fillText(
      'AMMO:' + player.ammo,
      SCREEN_W - 60, SCREEN_H - 10
    );

    // Weapon name
    ctx.fillText(
      WEAPONS[player.weapon][0],
      SCREEN_W / 2 - 15, SCREEN_H - 10
    );

    // Score - top right
    ctx.fillText(
      'SCORE:' + player.score,
      SCREEN_W - 70, 12
    );

    // Key indicator
    if (this.engine && this.engine.levelNeedsKey) {
      ctx.fillStyle = player.hasKey
        ? '#ffdd00' : '#553300';
      ctx.fillText(
        'KEY:' + (player.hasKey
          ? 'YES' : 'NO'),
        SCREEN_W / 2 - 15, 12
      );
    }

    // Boss HP bar
    if (this.engine
      && this.engine.isBossLevel) {
      const boss = this.engine.entities.find(
        e => e.type === 'enemy_boss'
          && e.alive
      );
      if (boss) {
        const bW = SCREEN_W * 0.6;
        const bX = (SCREEN_W - bW) / 2;
        ctx.fillStyle = '#333';
        ctx.fillRect(bX, 20, bW, 6);
        ctx.fillStyle = '#dd8800';
        ctx.fillRect(
          bX, 20,
          bW * (boss.hp / boss.maxHp), 6
        );
        ctx.fillStyle = '#ffdd00';
        ctx.font = '7px monospace';
        ctx.fillText(
          'BOSS', bX + bW / 2 - 10, 18
        );
      }
    }

    // Crosshair (follows pitch)
    const crossY = Math.floor(
      SCREEN_H / 2 + player.pitch
    );
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(
      SCREEN_W / 2 - 1,
      crossY - 4, 2, 8
    );
    ctx.fillRect(
      SCREEN_W / 2 - 4,
      crossY - 1, 8, 2
    );

    // Minimap - top left
    this.drawMinimap(ctx, player);
  }

  drawMinimap(ctx, player) {
    if (!this.map) return;
    const size = 3;
    const ox = 4;
    const oy = 4;
    const range = 8;
    const px = Math.floor(player.x);
    const py = Math.floor(player.y);

    for (let dy = -range; dy <= range; dy++) {
      for (let dx = -range; dx <= range; dx++) {
        const mx = px + dx;
        const my = py + dy;
        const sx = ox + (dx + range) * size;
        const sy = oy + (dy + range) * size;
        const cell = this.map.get(mx, my);
        if (cell !== 0) {
          if (cell === 5) {
            ctx.fillStyle = (
              this.engine
              && this.engine.levelNeedsKey
              && !player.hasKey
            ) ? '#ff0000' : '#00ff00';
          } else {
            ctx.fillStyle = '#555';
          }
        } else if (this.map.isHole(mx, my)) {
          ctx.fillStyle = '#880000';
        } else {
          ctx.fillStyle = '#222';
        }
        ctx.fillRect(sx, sy, size, size);
      }
    }
    // Player dot
    ctx.fillStyle = '#ff0';
    ctx.fillRect(
      ox + range * size,
      oy + range * size,
      size, size
    );
    // Direction indicator
    const dirX = Math.cos(player.angle)
      * size * 2;
    const dirY = Math.sin(player.angle)
      * size * 2;
    ctx.fillStyle = '#ff0';
    ctx.fillRect(
      ox + range * size + dirX,
      oy + range * size + dirY,
      2, 2
    );
  }

  drawEffects(player, effects) {
    const ctx = this.bctx;
    for (let i = 0; i < effects.length; i++) {
      const fx = effects[i];
      const dx = fx.x - player.x;
      const dy = fx.y - player.y;
      const dist = Math.sqrt(
        dx * dx + dy * dy
      );
      if (dist > MAX_DEPTH || dist < 0.2) {
        continue;
      }

      // Project to screen
      const angle = Math.atan2(dy, dx);
      let relA = angle - player.angle;
      while (relA > Math.PI) {
        relA -= 2 * Math.PI;
      }
      while (relA < -Math.PI) {
        relA += 2 * Math.PI;
      }
      if (Math.abs(relA) > HALF_FOV + 0.3) {
        continue;
      }

      const scrX = Math.floor(
        (0.5 + relA / FOV) * SCREEN_W
      );
      const scrY = Math.floor(
        SCREEN_H / 2 + player.pitch
      );

      if (fx.type === 'explosion') {
        const prog = 1 - fx.timer
          / fx.maxTimer;
        const radius = Math.floor(
          (30 + 60 * prog) / dist
        );
        const a = (1 - prog).toFixed(2);
        // Outer ring
        ctx.strokeStyle = 'rgba(255,150,0,'
          + a + ')';
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.arc(
          scrX, scrY,
          radius, 0, Math.PI * 2
        );
        ctx.stroke();
        // Inner flash
        ctx.fillStyle = 'rgba(255,255,100,'
          + (a * 0.6).toFixed(2) + ')';
        ctx.beginPath();
        ctx.arc(
          scrX, scrY,
          radius * 0.5, 0, Math.PI * 2
        );
        ctx.fill();
        ctx.lineWidth = 1;
      }
    }
  }
}

// =========================================
// Game Engine
// =========================================

class GameEngine {
  constructor(canvas, act) {
    this.canvas = canvas;
    this.act = act;
    this.renderer = new Renderer(canvas);
    this.keys = {};
    this.gameState = STATE_TITLE;
    this.player = null;
    this.map = null;
    this.entities = [];
    this.rafId = null;
    this.lastTime = 0;
    this.level = 1;
    this.maxLevel = 7;
    this.mouseDX = 0;
    this.mouseDY = 0;
    this.mouseSensX = 0.003;
    this.mouseSensY = 1.5;
    this.pointerLocked = false;
    this.effects = [];
    this.sfxThrottle = {};
    this.entryName = '';
    this.nameDone = false;
    this.levelNeedsKey = false;
    this.isBossLevel = false;
    this.doorMessage = 0;
    this.doorMessageText = '';
    this.renderer.engine = this;
  }

  addEffect(type, x, y, duration) {
    this.effects.push({
      type, x, y,
      timer: duration,
      maxTimer: duration,
    });
  }

  triggerSound(snd) {
    const now = performance.now();
    const last = this.sfxThrottle[snd] || 0;
    if (now - last < 150) return;
    this.sfxThrottle[snd] = now;
    this.act('sfx', { s: snd });
  }

  loadLevel(staticData) {
    const newLvl = staticData.level || 1;
    // Preserve score when advancing
    const prevScore = (
      this.player
      && newLvl > this.level
    ) ? this.player.score : 0;

    this.map = new GameMap(staticData.map);
    this.renderer.map = this.map;
    this.player = new Player(
      staticData.player_start
    );
    this.player.score = prevScore;
    // Snap player Z to floor at spawn point
    if (this.map.floorH) {
      const sp = staticData.player_start;
      this.player.z = this.map.slopes
        ? this.map.getFloorHAt(sp.x, sp.y)
        : this.map.getFloorH(
          Math.floor(sp.x),
          Math.floor(sp.y)
        );
    }
    this.entities = [];
    this.effects = [];
    if (staticData.entities) {
      for (let i = 0;
        i < staticData.entities.length;
        i++) {
        const ed = staticData.entities[i];
        this.entities.push(
          new Entity(ed.type, ed.x, ed.y)
        );
      }
    }
    this.level = newLvl;
    if (staticData.maxLevel) {
      this.maxLevel = staticData.maxLevel;
    }
    this.levelNeedsKey = !!staticData.needsKey;
    this.isBossLevel = !!staticData.isBossLevel;
    this.doorMessage = 0;
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
    if (this.gameState !== STATE_PLAYING) return;
    if (!this.player || !this.map) return;

    const p = this.player;
    p.moving = false;

    // Mouse look
    if (this.mouseDX !== 0) {
      p.angle += this.mouseDX * this.mouseSensX;
      this.mouseDX = 0;
    }
    if (this.mouseDY !== 0) {
      p.pitch -= this.mouseDY * this.mouseSensY;
      p.pitch = Math.max(
        -80, Math.min(80, p.pitch)
      );
      this.mouseDY = 0;
    }

    // Arrow key rotation
    if (this.keys[KEY_LEFT]) {
      p.angle -= ROT_SPEED * dt;
    }
    if (this.keys[KEY_RIGHT]) {
      p.angle += ROT_SPEED * dt;
    }

    // Movement (WASD)
    let mx = 0;
    let my = 0;
    if (this.keys[KEY_UP]
      || this.keys[KEY_W]) {
      mx += Math.cos(p.angle) * MOVE_SPEED * dt;
      my += Math.sin(p.angle) * MOVE_SPEED * dt;
      p.moving = true;
    }
    if (this.keys[KEY_DOWN]
      || this.keys[KEY_S]) {
      mx -= Math.cos(p.angle) * MOVE_SPEED * dt;
      my -= Math.sin(p.angle) * MOVE_SPEED * dt;
      p.moving = true;
    }
    // A/D strafe
    if (this.keys[KEY_A]) {
      const sa = p.angle - Math.PI / 2;
      mx += Math.cos(sa) * MOVE_SPEED * dt;
      my += Math.sin(sa) * MOVE_SPEED * dt;
      p.moving = true;
    }
    if (this.keys[KEY_D]) {
      const sa = p.angle + Math.PI / 2;
      mx += Math.cos(sa) * MOVE_SPEED * dt;
      my += Math.sin(sa) * MOVE_SPEED * dt;
      p.moving = true;
    }

    // Collision per-axis (height-aware)
    if (this.map.canMove(p.x + mx, p.y, p.z)) {
      p.x += mx;
    }
    if (this.map.canMove(p.x, p.y + my, p.z)) {
      p.y += my;
    }

    // Check for holes — drop to layer below
    if (this.map.numLayers > 1
      && this.map.currentLayer > 0) {
      const hx = Math.floor(p.x);
      const hy = Math.floor(p.y);
      if (this.map.isHole(hx, hy)) {
        this.map.switchLayer(
          this.map.currentLayer - 1
        );
        p.vz = 0;
      }
    }

    // Vertical physics (slope-aware)
    if (this.map.floorH) {
      const fh = this.map.slopes
        ? this.map.getFloorHAt(p.x, p.y)
        : this.map.getFloorH(
          Math.floor(p.x),
          Math.floor(p.y)
        );
      if (p.z > fh + 0.01) {
        // Falling
        p.vz -= 9.8 * dt;
        p.z += p.vz * dt;
        if (p.z <= fh) {
          p.z = fh;
          p.vz = 0;
        }
      } else {
        // Snap to floor (stairs/slopes)
        p.z = fh;
        p.vz = 0;
      }
    }

    // Update elevators
    if (this.map.elevators) {
      this.updateElevators(dt);
    }

    // Weapon bob
    if (p.moving) {
      p.weaponBob += dt * 8;
    } else {
      p.weaponBob *= 0.9;
    }

    // Weapon cooldown + kick decay
    if (p.weaponCooldown > 0) {
      p.weaponCooldown -= dt;
    }
    if (p.weaponKick > 0) {
      p.weaponKick -= dt * 4;
      if (p.weaponKick < 0) p.weaponKick = 0;
    }

    // Hurt flash decay
    if (p.hurtFlash > 0) {
      p.hurtFlash -= dt;
    }
    // Door message decay
    if (this.doorMessage > 0) {
      this.doorMessage -= dt;
    }

    // Weapon switch
    if (this.keys[KEY_1]) p.weapon = 0;
    if (this.keys[KEY_2]) p.weapon = 1;

    // Shooting
    if (this.keys[KEY_SPACE]
      && p.weaponCooldown <= 0) {
      this.shoot();
    }

    // Update entities
    for (let i = 0; i < this.entities.length;
      i++) {
      this.entities[i].update(
        dt, p, this.map, this
      );
    }

    // Update effects
    for (let i = this.effects.length - 1;
      i >= 0; i--) {
      this.effects[i].timer -= dt;
      if (this.effects[i].timer <= 0) {
        this.effects.splice(i, 1);
      }
    }

    // Check pickup collisions
    for (let i = 0; i < this.entities.length;
      i++) {
      const e = this.entities[i];
      if (e.isEnemy || !e.alive) continue;
      const dx = e.x - p.x;
      const dy = e.y - p.y;
      if (dx * dx + dy * dy < 0.5) {
        e.alive = false;
        this.triggerSound('pickup');
        if (e.type === 'pickup_health') {
          p.hp = Math.min(
            p.hp + 25, p.maxHp
          );
          p.score += 50;
        } else if (e.type === 'pickup_ammo') {
          p.ammo += 15;
          p.score += 25;
        } else if (e.type === 'pickup_key') {
          p.hasKey = true;
          p.score += 100;
        }
      }
    }

    // Check exit - player is adjacent to door
    const nearExit = this.isNearExit(p);
    if (nearExit) {
      if (this.level >= this.maxLevel) {
        p.score += 500;
        this.entryName = '';
        this.nameDone = false;
        this.gameState = STATE_NAMEENTRY;
      } else {
        this.gameState = STATE_LEVEL_COMPLETE;
        p.score += 200;
      }
    }

    // Check death
    if (p.hp <= 0) {
      this.gameState = STATE_DEAD;
      this.act('died');
    }
  }

  isNearExit(p) {
    const r = 0.6;
    const checks = [
      [Math.floor(p.x + r), Math.floor(p.y)],
      [Math.floor(p.x - r), Math.floor(p.y)],
      [Math.floor(p.x), Math.floor(p.y + r)],
      [Math.floor(p.x), Math.floor(p.y - r)],
    ];
    for (let i = 0; i < checks.length; i++) {
      if (this.map.get(
        checks[i][0], checks[i][1]
      ) === 5) {
        // Key lock check
        if (this.levelNeedsKey
          && !p.hasKey) {
          this.doorMessage = 1.5;
          this.doorMessageText
            = 'FIND THE KEY!';
          return false;
        }
        // Boss lock check
        if (this.isBossLevel) {
          const alive = this.entities.some(
            e => e.isEnemy && e.alive
          );
          if (alive) {
            this.doorMessage = 1.5;
            this.doorMessageText
              = 'DEFEAT THE BOSS!';
            return false;
          }
        }
        return true;
      }
    }
    return false;
  }

  updateElevators(dt) {
    const m = this.map;
    const p = this.player;
    const elevs = m.elevators;
    for (let i = 0; i < elevs.length; i++) {
      const e = elevs[i];
      if (!e.dir) e.dir = 1;
      if (!e.currentH && e.currentH !== 0) {
        e.currentH = e.minH || 0;
      }
      e.currentH += e.dir * e.speed * dt;
      if (e.currentH >= e.maxH) {
        e.currentH = e.maxH;
        e.dir = -1;
      }
      if (e.currentH <= e.minH) {
        e.currentH = e.minH;
        e.dir = 1;
      }
      m.setFloorH(e.x, e.y, e.currentH);
      // Move player if standing on it
      const px = Math.floor(p.x);
      const py = Math.floor(p.y);
      if (px === e.x && py === e.y) {
        p.z = e.currentH;
      }
    }
  }

  shoot() {
    const p = this.player;
    const w = WEAPONS[p.weapon];
    if (p.ammo < w[3]) return;
    p.ammo -= w[3];
    p.weaponCooldown = w[2];
    p.weaponKick = 0.3;

    // Hitscan - cast ray and check enemies
    const spread = w[4];
    this.triggerSound(
      spread > 0 ? 'shotgun' : 'shoot'
    );
    const shots = spread > 0 ? 5 : 1;
    const dmgPer = spread > 0
      ? w[1] : w[1];

    for (let s = 0; s < shots; s++) {
      const angle = p.angle
        + (spread > 0
          ? (Math.random() - 0.5) * spread * 2
          : 0);
      const cosA = Math.cos(angle);
      const sinA = Math.sin(angle);

      // Find nearest enemy along ray
      let bestDist = MAX_DEPTH;
      let bestEnemy = null;

      for (let i = 0; i < this.entities.length;
        i++) {
        const e = this.entities[i];
        if (!e.isEnemy || !e.alive) continue;
        const dx = e.x - p.x;
        const dy = e.y - p.y;
        // Project onto ray
        const dot = dx * cosA + dy * sinA;
        if (dot <= 0 || dot >= bestDist) continue;
        // Perpendicular distance to ray
        const perp = Math.abs(
          dx * sinA - dy * cosA
        );
        if (perp < 0.4) {
          // Check wall between
          let blocked = false;
          const steps = Math.ceil(dot * 2);
          for (let j = 0; j < steps; j++) {
            const t = j / steps;
            if (this.map.isWall(
              Math.floor(p.x + cosA * dot * t),
              Math.floor(p.y + sinA * dot * t)
            )) {
              blocked = true;
              break;
            }
          }
          if (!blocked) {
            bestDist = dot;
            bestEnemy = e;
          }
        }
      }

      if (bestEnemy) {
        bestEnemy.takeDamage(dmgPer);
        if (!bestEnemy.alive) {
          p.score += 100;
          this.triggerSound('kill');
        }
      }
    }
  }

  render() {
    const ctx = this.renderer.bctx;

    if (this.gameState === STATE_TITLE) {
      this.renderTitle();
      // Scale up
      this.renderer.ctx.imageSmoothingEnabled
        = false;
      this.renderer.ctx.drawImage(
        this.renderer.buf,
        0, 0, CANVAS_W, CANVAS_H
      );
      return;
    }

    if (this.player && this.map) {
      this.renderer.needsKeyDoor = (
        this.levelNeedsKey
        && !this.player.hasKey
      );
      this.renderer.render(
        this.player, this.map,
        this.entities, this.effects
      );
      // Door locked message on screen
      if (this.doorMessage > 0) {
        const a = Math.min(
          1, this.doorMessage
        ).toFixed(2);
        this.drawCenterText(
          this.doorMessageText,
          'rgba(255,60,60,' + a + ')',
          12, -50
        );
        // Re-scale after overlay text
        this.renderer.ctx
          .imageSmoothingEnabled = false;
        this.renderer.ctx.drawImage(
          this.renderer.buf,
          0, 0, CANVAS_W, CANVAS_H
        );
      }
    }

    // Overlay for non-playing states
    if (this.gameState === STATE_DEAD) {
      this.renderer.bctx.fillStyle
        = 'rgba(200,0,0,0.5)';
      this.renderer.bctx.fillRect(
        0, 0, SCREEN_W, SCREEN_H
      );
      this.drawCenterText(
        'YOU DIED', '#ff0000', 16
      );
      this.drawCenterText(
        'Score: ' + this.player.score,
        '#ffffff', 8, 20
      );
      this.drawCenterText(
        'Press R to restart',
        '#aaaaaa', 8, 36
      );
      // Re-scale after overlay
      this.renderer.ctx.imageSmoothingEnabled
        = false;
      this.renderer.ctx.drawImage(
        this.renderer.buf,
        0, 0, CANVAS_W, CANVAS_H
      );
    }

    if (this.gameState === STATE_LEVEL_COMPLETE) {
      this.renderer.bctx.fillStyle
        = 'rgba(0,0,0,0.6)';
      this.renderer.bctx.fillRect(
        0, 0, SCREEN_W, SCREEN_H
      );
      this.drawCenterText(
        'SECTOR ' + this.level + ' CLEARED!',
        '#44ff44', 14
      );
      this.drawCenterText(
        'Score: ' + this.player.score,
        '#ffffff', 8, 20
      );
      this.drawCenterText(
        'Press ENTER for next sector',
        '#aaaaaa', 8, 36
      );
      this.renderer.ctx.imageSmoothingEnabled
        = false;
      this.renderer.ctx.drawImage(
        this.renderer.buf,
        0, 0, CANVAS_W, CANVAS_H
      );
    }

    if (this.gameState === STATE_WIN) {
      this.renderer.bctx.fillStyle
        = 'rgba(0,0,0,0.7)';
      this.renderer.bctx.fillRect(
        0, 0, SCREEN_W, SCREEN_H
      );
      this.drawCenterText(
        'TRAINING COMPLETE!',
        '#ffff00', 14
      );
      this.drawCenterText(
        'Final Score: ' + this.player.score,
        '#ffffff', 10, 24
      );
      this.drawCenterText(
        'Press R to play again',
        '#aaaaaa', 8, 42
      );
      this.renderer.ctx.imageSmoothingEnabled
        = false;
      this.renderer.ctx.drawImage(
        this.renderer.buf,
        0, 0, CANVAS_W, CANVAS_H
      );
    }

    if (this.gameState
      === STATE_NAMEENTRY) {
      this.renderNameEntry();
    }
  }

  renderNameEntry() {
    const ctx = this.renderer.bctx;
    ctx.fillStyle = 'rgba(0,0,0,0.85)';
    ctx.fillRect(
      0, 0, SCREEN_W, SCREEN_H
    );
    this.drawCenterText(
      'YOU WIN!', '#ffcc44', 14, -50
    );
    this.drawCenterText(
      'Score: ' + this.player.score,
      '#fff', 9, -32
    );
    this.drawCenterText(
      'ENTER YOUR NAME',
      '#aaa', 7, -12
    );
    const boxW = 14;
    const boxH = 16;
    const gap = 3;
    const totalW = 6 * boxW + 5 * gap;
    const sx = (SCREEN_W - totalW) / 2;
    const sy = SCREEN_H / 2 + 2;
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
        ctx.font = '10px monospace';
        const ch = this.entryName[i];
        const cw2 = ctx.measureText(
          ch
        ).width;
        ctx.fillText(
          ch,
          bx + (boxW - cw2) / 2,
          sy + 12
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
          cx + 4, sy + boxH - 2, 6, 1
        );
      }
    }
    if (this.nameDone) {
      this.drawCenterText(
        'Press R to play again',
        '#aaa', 7, 30
      );
    } else {
      this.drawCenterText(
        'Type A-Z then ENTER',
        '#888', 7, 30
      );
    }
    // Scale up
    this.renderer.ctx.imageSmoothingEnabled
      = false;
    this.renderer.ctx.drawImage(
      this.renderer.buf,
      0, 0, CANVAS_W, CANVAS_H
    );
  }

  renderTitle() {
    const ctx = this.renderer.bctx;
    ctx.fillStyle = '#111';
    ctx.fillRect(0, 0, SCREEN_W, SCREEN_H);

    // Decorative border
    ctx.strokeStyle = '#cc4444';
    ctx.lineWidth = 2;
    ctx.strokeRect(10, 10,
      SCREEN_W - 20, SCREEN_H - 20);

    this.drawCenterText(
      'R CORP HATCHERY',
      '#ff6633', 18, -30
    );
    this.drawCenterText(
      'Combat Training Simulation',
      '#888888', 7, -5
    );
    this.drawCenterText(
      'WASD: Move  Mouse: Look',
      '#aaaaaa', 7, 20
    );
    this.drawCenterText(
      'LClick/SPACE: Shoot  1/2: Weapons',
      '#aaaaaa', 7, 33
    );
    this.drawCenterText(
      'Click to capture mouse',
      '#aaaaaa', 7, 46
    );
    this.drawCenterText(
      'Press ENTER to Start',
      '#44ff44', 10, 63
    );
    // Leaderboard
    this.drawCenterText(
      '-- LEADERBOARD --',
      '#ffaa44', 8, 72
    );
    const lb = this.leaderboard || [];
    if (lb.length === 0) {
      this.drawCenterText(
        'No scores yet',
        '#666666', 7, 84
      );
    }
    for (let i = 0; i < lb.length
      && i < 5; i++) {
      const e = lb[i];
      const n = e.name || '???';
      const s = e.score || 0;
      const t = (i + 1) + '. '
        + n.substring(0, 10) + ' ' + s;
      this.drawCenterText(
        t, '#ffff44', 7, 84 + i * 10
      );
    }
  }

  drawCenterText(text, color, size, yOff) {
    const ctx = this.renderer.bctx;
    ctx.fillStyle = color;
    ctx.font = size + 'px monospace';
    const w = ctx.measureText(text).width;
    ctx.fillText(
      text,
      (SCREEN_W - w) / 2,
      SCREEN_H / 2 + (yOff || 0)
    );
  }

  handleKeyDown(code) {
    this.keys[code] = true;

    if (this.gameState === STATE_TITLE
      && code === KEY_ENTER) {
      this.gameState = STATE_PLAYING;
    }

    if (this.gameState === STATE_DEAD
      && code === KEY_R) {
      this.act('restart');
    }

    if (this.gameState === STATE_LEVEL_COMPLETE
      && code === KEY_ENTER) {
      this.act('next_level');
    }

    if (this.gameState === STATE_WIN
      && code === KEY_R) {
      this.act('restart');
    }

    // Name entry input
    if (this.gameState
      === STATE_NAMEENTRY) {
      if (this.nameDone) {
        if (code === KEY_R) {
          this.act('restart');
        }
        return;
      }
      if (code === KEY_ENTER
        && this.entryName.length > 0) {
        this.nameDone = true;
        this.act('submit_score', {
          score: this.player.score,
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
  }

  handleKeyUp(code) {
    this.keys[code] = false;
  }

  handleMouseMove(e) {
    if (this.pointerLocked) {
      // Pointer lock: use movement deltas
      this.mouseDX += e.movementX || 0;
      this.mouseDY += e.movementY || 0;
    } else if (this.gameState
      === STATE_PLAYING) {
      // Fallback: track position relative
      // to canvas center
      const rect = this.canvas
        .getBoundingClientRect();
      const cx = rect.left + rect.width / 2;
      const cy = rect.top + rect.height / 2;
      const dx = e.clientX - cx;
      const dy = e.clientY - cy;
      this.mouseDX = dx * 0.05;
      this.mouseDY = dy * 0.05;
    }
  }

  handleClick() {
    if (this.gameState === STATE_PLAYING
      && this.player
      && this.player.weaponCooldown <= 0) {
      this.shoot();
    }
  }
}

// =========================================
// TGUI Component
// =========================================

const ACQUIRED_KEYS = [
  KEY_W, KEY_A, KEY_S, KEY_D,
  KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT,
  KEY_1, KEY_2, KEY_R,
];

class ArcadeFpsGame extends Component {
  constructor(props) {
    super(props);
    this.canvasRef = createRef();
    this.engine = null;
    this.keysAcquired = false;
  }

  componentDidMount() {
    const canvas = this.canvasRef.current;
    if (!canvas) return;

    // Acquire hotkeys so WASD doesn't move
    // the SS13 character
    for (let i = 0; i < ACQUIRED_KEYS.length; i++) {
      acquireHotKey(ACQUIRED_KEYS[i]);
    }
    this.keysAcquired = true;

    this.engine = new GameEngine(
      canvas, this.props.act
    );
    this.engine.highScore
      = this.props.data.leaderboard || [];

    // Load level from static data
    const sd = this.props.data;
    if (sd && sd.map) {
      this.engine.loadLevel(sd);
    }

    // Pointer lock for mouse look
    this.onPointerLockChange = () => {
      const locked = (
        document.pointerLockElement === canvas
      );
      if (this.engine) {
        this.engine.pointerLocked = locked;
      }
    };
    document.addEventListener(
      'pointerlockchange',
      this.onPointerLockChange
    );

    this.engine.start();
    canvas.focus();
  }

  componentDidUpdate(prevProps) {
    if (!this.engine) return;
    const sd = this.props.data;
    // Check if static data changed (new level)
    if (sd && sd.map
      && prevProps.data.level !== sd.level) {
      this.engine.loadLevel(sd);
      this.engine.gameState = STATE_PLAYING;
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
    if (document.pointerLockElement) {
      document.exitPointerLock();
    }
    if (this.onPointerLockChange) {
      document.removeEventListener(
        'pointerlockchange',
        this.onPointerLockChange
      );
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
            this.engine.handleKeyDown(e.keyCode);
          }
        }}
        onKeyUp={e => {
          e.preventDefault();
          if (this.engine) {
            this.engine.handleKeyUp(e.keyCode);
          }
        }}
        onMouseMove={e => {
          if (this.engine) {
            this.engine.handleMouseMove(e);
          }
        }}
        onMouseDown={e => {
          if (e.button !== 0) return;
          if (!this.engine) return;
          const eng = this.engine;
          if (eng.pointerLocked) {
            eng.handleClick();
          } else {
            // Try pointer lock, also fire
            const c = this.canvasRef.current;
            if (c && c.requestPointerLock) {
              c.requestPointerLock();
            }
            eng.handleClick();
          }
        }}
        style={{
          display: 'block',
          outline: 'none',
          cursor: 'crosshair',
          'image-rendering': 'pixelated',
        }}
      />
    );
  }
}

export const ArcadeFps = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Window
      width={CANVAS_W + 30}
      height={CANVAS_H + 50}>
      <Window.Content>
        <ArcadeFpsGame act={act} data={data} />
      </Window.Content>
    </Window>
  );
};
