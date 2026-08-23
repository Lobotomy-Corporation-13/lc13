/**
 * @file
 * @copyright 2024
 * @license MIT
 *
 * L Corp Overtime - FNAF-style survival.
 * Last manager at a fallen L Corp facility.
 * Monitor cameras, close doors, manage
 * enkephalin power. Survive 5 nights.
 */

import { Component, createRef } from 'inferno';
import { useBackend } from '../backend';
import { Window } from '../layouts';
import {
  acquireHotKey,
  releaseHotKey,
} from '../hotkeys';

// Constants

const CW = 520;
const CH = 400;
const HUD_H = 22;
const BAR_H = 32;

const GS_TITLE = 0;
const GS_OFFICE = 1;
const GS_CAMERA = 2;
const GS_DEAD = 3;
const GS_WIN = 4;
const GS_NIGHT_START = 5;
const GS_NIGHT_END = 6;
const GS_NAMEENTRY = 7;

const KEY_ENTER = 13;
const KEY_R = 82;

// Night duration in seconds (6 hours)
const NIGHT_DUR = 270;
const NUM_NIGHTS = 5;

// Camera names
const CAMS = [
  'Containment A', 'Main Hall',
  'Containment B', 'Left Corridor',
  'Break Room', 'Right Corridor',
  'Generator Room', 'Server Room',
];

// Abnormality room paths
// Index into CAMS: left path 0->1->3->DOOR
// right path 2->1->5->DOOR
const LEFT_PATH = [0, 1, 3, -1];
const RIGHT_PATH = [2, 1, 5, -1];
// -1 = at your door

// Game Engine

class OvertimeEngine {
  constructor(canvas, act) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.act = act;
    this.state = GS_TITLE;
    this.rafId = null;
    this.lastTime = 0;

    // Sprites (base64 from DM)
    this.sprites = {};
    this.spriteImgs = {};

    // Night state
    this.night = 0;
    this.timer = 0;
    this.power = 100;
    this.passiveDrain = 0.15;

    // Doors
    this.leftDoor = false;
    this.rightDoor = false;
    this.leftLight = 0;
    this.rightLight = 0;

    // Camera
    this.camIdx = 0;

    // Abnormalities
    this.abnos = [];

    // DRV presence
    this.drvPresence = 0;

    // Fairy charge
    this.fairyCharge = 0;
    this.fairyCharging = false;

    // Score
    this.score = 0;
    this.leaderboard = [];

    // UI
    this.nightStartTimer = 0;
    this.deathMsg = '';
    this.mx = 0;
    this.my = 0;

    // Name entry
    this.entryName = '';

    // Static effect
    this.staticLevel = 0;
  }

  loadData(sd) {
    if (sd.sprites) {
      this.sprites = sd.sprites;
      // Preload images
      for (const key in this.sprites) {
        const img = new Image();
        img.src = this.sprites[key];
        this.spriteImgs[key] = img;
      }
    }
  }

  // GAME FLOW

  startGame() {
    this.night = 0;
    this.score = 0;
    this.startNight();
  }

  startNight() {
    this.timer = 0;
    this.power = 100;
    this.leftDoor = false;
    this.rightDoor = false;
    this.leftLight = 0;
    this.rightLight = 0;
    this.camIdx = 0;
    this.drvPresence = 0;
    this.fairyCharge = 0;
    this.fairyCharging = false;
    this.staticLevel = 0;
    this.state = GS_NIGHT_START;
    this.nightStartTimer = 2.5;

    // Set passive drain per night
    const drains = [
      0.15, 0.18, 0.22, 0.25, 0.30,
    ];
    this.passiveDrain = drains[
      Math.min(this.night, 4)
    ];

    // Init abnormalities
    this.abnos = [];
    // Night 1+: Punishing Bird (left)
    this.abnos.push({
      key: 'pbird', name: 'P-Bird',
      side: 'left', pathIdx: 0,
      moveTimer: 0,
      moveInterval: [8, 12],
      active: true,
      atDoor: false,
    });
    // Night 1+: Beauty (right)
    this.abnos.push({
      key: 'beauty', name: 'Beauty',
      side: 'right', pathIdx: 0,
      moveTimer: 0,
      moveInterval: [10, 15],
      active: true,
      atDoor: false,
    });
    // Night 2+: Schadenfreude (left watcher)
    if (this.night >= 1) {
      this.abnos.push({
        key: 'schadenfreude',
        name: 'Schadenfreude',
        side: 'left', pathIdx: 0,
        moveTimer: 0,
        moveInterval: [3, 3],
        active: true,
        atDoor: false,
        watchMove: true,
      });
    }
    // Night 2+: Red Shoes (right watcher)
    if (this.night >= 1) {
      this.abnos.push({
        key: 'redshoes',
        name: 'Red Shoes',
        side: 'right', pathIdx: 0,
        moveTimer: 0,
        moveInterval: [15, 15],
        active: true,
        atDoor: false,
        watchAccel: true,
        watchTimer: 0,
      });
    }
    // Night 3+: Clayman (random side)
    if (this.night >= 2) {
      const cSide = Math.random() < 0.5
        ? 'left' : 'right';
      this.abnos.push({
        key: 'clayman', name: 'Clayman',
        side: cSide, pathIdx: 0,
        moveTimer: 0,
        moveInterval: [6, 10],
        active: true,
        atDoor: false,
        canDash: true,
      });
    }
    // Night 3+: Fairy (generator room)
    if (this.night >= 2) {
      this.fairyCharge = 0;
      this.fairyCharging = false;
    }
    // Night 4+: DRV (invisible intruder)
    if (this.night >= 3) {
      this.drvPresence = 0;
    }
  }

  die(msg) {
    this.deathMsg = msg;
    this.state = GS_DEAD;
    this.act('died');
    this.act('sfx', { s: 'jumpscare' });
  }

  getHour() {
    const frac = this.timer / NIGHT_DUR;
    const hour = Math.floor(frac * 6);
    return hour === 0 ? 12 : hour;
  }

  getAmPm() {
    return this.timer < NIGHT_DUR / 2
      ? 'AM' : 'AM';
  }

  // UPDATE

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

  update(dt) {
    if (this.state === GS_NIGHT_START) {
      this.nightStartTimer -= dt;
      if (this.nightStartTimer <= 0) {
        this.state = GS_OFFICE;
      }
      return;
    }

    if (this.state !== GS_OFFICE
      && this.state !== GS_CAMERA) return;

    // Time
    this.timer += dt;
    if (this.timer >= NIGHT_DUR) {
      // Survived the night!
      const bonus = Math.floor(
        this.power * 10
      );
      this.score += 1000 + bonus;
      this.night++;
      if (this.night >= NUM_NIGHTS) {
        this.score += 2000;
        this.entryName = '';
        this.state = GS_NAMEENTRY;
      } else {
        this.state = GS_NIGHT_END;
        this.nightStartTimer = 2;
      }
      return;
    }

    // Power drain
    this.power -= this.passiveDrain * dt;
    if (this.state === GS_CAMERA) {
      this.power -= 0.8 * dt;
    }
    if (this.leftDoor) {
      this.power -= 1.2 * dt;
    }
    if (this.rightDoor) {
      this.power -= 1.2 * dt;
    }
    // Light decay
    if (this.leftLight > 0) {
      this.leftLight -= dt;
    }
    if (this.rightLight > 0) {
      this.rightLight -= dt;
    }

    // Power out = death
    if (this.power <= 0) {
      this.power = 0;
      this.die(
        'Enkephalin depleted.'
        + ' The lights go out...'
      );
      return;
    }

    // Update abnormalities
    this.updateAbnos(dt);

    // DRV presence (night 4+)
    if (this.night >= 3) {
      if (this.state === GS_CAMERA) {
        this.drvPresence += 1.0 * dt;
        this.staticLevel = Math.min(
          1, this.drvPresence / 80
        );
      } else {
        this.drvPresence = Math.max(
          0, this.drvPresence - 3 * dt
        );
        this.staticLevel = Math.max(
          0, this.staticLevel - 0.5 * dt
        );
      }
      if (this.drvPresence >= 100) {
        this.die(
          'The Dimensional Refraction'
          + ' Variant found you.'
        );
        return;
      }
    }

    // Fairy charge (night 3+)
    if (this.night >= 2) {
      if (this.state === GS_CAMERA
        && this.camIdx === 6) {
        // Looking at generator room
        this.fairyCharge = 0;
        this.fairyCharging = false;
      } else {
        this.fairyCharge += 5 * dt;
      }
      if (this.fairyCharge >= 100
        && !this.fairyCharging) {
        this.fairyCharging = true;
        // 2 second warning
        setTimeout(() => {
          if (this.fairyCharging) {
            if (!this.leftDoor) {
              this.die(
                'Fairy Festival got you!'
              );
            } else {
              this.fairyCharge = 0;
              this.fairyCharging = false;
            }
          }
        }, 2000);
        this.act('sfx', { s: 'charge' });
      }
    }
  }

  updateAbnos(dt) {
    for (let i = 0;
      i < this.abnos.length; i++) {
      const a = this.abnos[i];
      if (!a.active || a.atDoor) continue;

      // Watcher: only moves when watched
      if (a.watchMove) {
        if (this.state !== GS_CAMERA) {
          continue;
        }
        const path = a.side === 'left'
          ? LEFT_PATH : RIGHT_PATH;
        const cam = path[a.pathIdx];
        if (this.camIdx !== cam) continue;
        // Move while watching
        a.moveTimer += dt;
        if (a.moveTimer >= a.moveInterval[0]) {
          a.moveTimer = 0;
          a.pathIdx++;
          if (a.pathIdx >= path.length - 1) {
            a.atDoor = true;
          }
        }
        continue;
      }

      // Watch accelerator
      if (a.watchAccel) {
        const path = a.side === 'left'
          ? LEFT_PATH : RIGHT_PATH;
        const cam = path[a.pathIdx];
        let interval = a.moveInterval[0];
        if (this.state === GS_CAMERA
          && this.camIdx === cam) {
          a.watchTimer += dt;
          if (a.watchTimer > 2) {
            interval = 4;
          }
        } else {
          a.watchTimer = 0;
        }
        a.moveTimer += dt;
        if (a.moveTimer >= interval) {
          a.moveTimer = 0;
          a.pathIdx++;
          if (a.pathIdx >= path.length - 1) {
            a.atDoor = true;
          }
        }
        continue;
      }

      // Normal movement
      a.moveTimer += dt;
      const intv = a.moveInterval[0]
        + Math.random()
          * (a.moveInterval[1]
            - a.moveInterval[0]);
      if (a.moveTimer >= intv) {
        a.moveTimer = 0;
        const path = a.side === 'left'
          ? LEFT_PATH : RIGHT_PATH;
        let advance = 1;
        if (a.canDash
          && Math.random() < 0.2) {
          advance = 2;
        }
        a.pathIdx = Math.min(
          a.pathIdx + advance,
          path.length - 1
        );
        if (a.pathIdx >= path.length - 1) {
          a.atDoor = true;
        }
      }
    }

    // Check door kills
    for (let i = 0;
      i < this.abnos.length; i++) {
      const a = this.abnos[i];
      if (!a.atDoor) continue;
      const door = a.side === 'left'
        ? this.leftDoor : this.rightDoor;
      if (door) {
        // Blocked! Reset after delay
        a.atDoor = false;
        a.pathIdx = 0;
        a.moveTimer = 0;
      } else {
        // At door and door open
        // Only kill if in office view
        if (this.state === GS_OFFICE) {
          // Check with light or just die
          this.die(a.name + ' got you!');
          return;
        }
        // In camera: random chance to
        // enter per second
        a.moveTimer += 0;
        if (Math.random() < 0.02) {
          this.die(a.name + ' got you!');
          return;
        }
      }
    }
  }

  // Get abnormality at a given camera
  abnoAtCam(camIdx) {
    for (let i = 0;
      i < this.abnos.length; i++) {
      const a = this.abnos[i];
      if (!a.active || a.atDoor) continue;
      // Skip invisible DRV
      if (a.key === 'drv') continue;
      const path = a.side === 'left'
        ? LEFT_PATH : RIGHT_PATH;
      if (a.pathIdx < path.length
        && path[a.pathIdx] === camIdx) {
        return a;
      }
    }
    return null;
  }

  // Check if abno is at left/right door
  abnoAtDoor(side) {
    for (let i = 0;
      i < this.abnos.length; i++) {
      const a = this.abnos[i];
      if (a.atDoor && a.side === side) {
        return a;
      }
    }
    return null;
  }

  // RENDER

  render() {
    const ctx = this.ctx;
    ctx.fillStyle = '#0a0a12';
    ctx.fillRect(0, 0, CW, CH);

    switch (this.state) {
      case GS_TITLE:
        this.renderTitle();
        break;
      case GS_NIGHT_START:
        this.renderNightStart();
        break;
      case GS_OFFICE:
        this.renderOffice();
        this.renderHUD();
        this.renderMiniMap();
        break;
      case GS_CAMERA:
        this.renderCameraFeed();
        this.renderHUD();
        this.renderCamBar();
        this.renderMiniMap();
        break;
      case GS_DEAD:
        this.renderDeath();
        break;
      case GS_WIN:
        this.renderWin();
        break;
      case GS_NIGHT_END:
        this.renderNightEnd();
        break;
      case GS_NAMEENTRY:
        this.renderNameEntry();
        break;
      default: break;
    }
  }

  renderHUD() {
    const ctx = this.ctx;
    ctx.fillStyle = 'rgba(0,0,0,0.8)';
    ctx.fillRect(0, 0, CW, HUD_H);
    ctx.fillStyle = '#aaa';
    ctx.font = '9px monospace';

    // Power bar
    ctx.fillText('Enkephalin:', 6, 15);
    ctx.fillStyle = '#333';
    ctx.fillRect(85, 5, 100, 12);
    const pClr = this.power > 50
      ? '#44aa44' : this.power > 25
        ? '#ccaa44' : '#cc4444';
    ctx.fillStyle = pClr;
    ctx.fillRect(
      85, 5,
      Math.max(0, this.power), 12
    );
    ctx.fillStyle = '#fff';
    ctx.font = '8px monospace';
    ctx.fillText(
      Math.ceil(this.power) + '%',
      90, 14
    );

    // Time
    const h = this.getHour();
    ctx.fillStyle = '#aaa';
    ctx.font = '10px monospace';
    ctx.fillText(
      h + ':00 AM', CW - 75, 15
    );

    // Night
    ctx.fillText(
      'Night ' + (this.night + 1),
      CW / 2 - 25, 15
    );

    // DRV warning
    if (this.night >= 3
      && this.drvPresence > 50) {
      const pulse = Math.sin(
        performance.now() * 0.01
      );
      ctx.fillStyle = 'rgba(255,0,0,'
        + (0.3 + pulse * 0.2)
          .toFixed(2) + ')';
      ctx.fillText(
        'ANOMALY DETECTED',
        200, 15
      );
    }
  }

  renderOffice() {
    const ctx = this.ctx;
    const t = performance.now();
    const y = HUD_H;
    const h = CH - HUD_H - BAR_H;

    // Office background
    ctx.fillStyle = '#12121e';
    ctx.fillRect(0, y, CW, h);

    // Back wall
    ctx.fillStyle = '#1a1a28';
    ctx.fillRect(60, y, CW - 120, h - 40);

    // Wall panels
    for (let px = 80; px < CW - 80;
      px += 90) {
      ctx.strokeStyle = '#222233';
      ctx.strokeRect(
        px, y + 10, 80, h - 60
      );
    }

    // Desk
    ctx.fillStyle = '#2a2a35';
    ctx.fillRect(
      120, y + h - 80, CW - 240, 40
    );
    // Monitor glow
    const fl = Math.sin(t * 0.003);
    ctx.fillStyle = 'rgba(80,120,80,'
      + (0.3 + fl * 0.1).toFixed(2) + ')';
    ctx.fillRect(
      CW / 2 - 30, y + h - 110, 60, 35
    );
    ctx.strokeStyle = '#444';
    ctx.strokeRect(
      CW / 2 - 30, y + h - 110, 60, 35
    );
    // Papers
    ctx.fillStyle = '#ddd8cc';
    ctx.save();
    ctx.translate(200, y + h - 70);
    ctx.rotate(0.2);
    ctx.fillRect(0, 0, 15, 20);
    ctx.restore();
    ctx.save();
    ctx.translate(300, y + h - 65);
    ctx.rotate(-0.1);
    ctx.fillRect(0, 0, 12, 18);
    ctx.restore();

    // Emergency light
    const el = Math.sin(t * 0.005);
    ctx.fillStyle = 'rgba(200,50,30,'
      + (0.15 + el * 0.1).toFixed(3)
      + ')';
    ctx.fillRect(0, y, CW, 3);

    // Overhead flicker
    const fk = Math.sin(
      t * 0.007 + Math.sin(t * 0.003) * 2
    );
    if (fk > 0.3) {
      ctx.fillStyle = 'rgba(150,160,170,'
        + (0.05 + fk * 0.03)
          .toFixed(3) + ')';
      ctx.fillRect(
        CW / 2 - 40, y + 2, 80, 3
      );
    }

    // LEFT doorway
    ctx.fillStyle = '#0a0a14';
    ctx.fillRect(0, y + 30, 55, h - 70);
    if (this.leftDoor) {
      // Blast door
      ctx.fillStyle = '#3a3a44';
      ctx.fillRect(0, y + 30, 55, h - 70);
      ctx.strokeStyle = '#555';
      ctx.strokeRect(2, y + 32, 51, h - 74);
      // Rivets
      ctx.fillStyle = '#666';
      ctx.fillRect(6, y + 36, 3, 3);
      ctx.fillRect(46, y + 36, 3, 3);
      ctx.fillRect(6, y + h - 48, 3, 3);
      ctx.fillRect(46, y + h - 48, 3, 3);
    } else if (this.leftLight > 0) {
      // Lit hallway
      ctx.fillStyle = '#1e1e2a';
      ctx.fillRect(0, y + 30, 55, h - 70);
      // Show abno if at door
      const la = this.abnoAtDoor('left');
      if (la) {
        this.drawAbnoSprite(
          20, y + 60, la.key
        );
      }
    }

    // RIGHT doorway
    ctx.fillStyle = '#0a0a14';
    ctx.fillRect(
      CW - 55, y + 30, 55, h - 70
    );
    if (this.rightDoor) {
      ctx.fillStyle = '#3a3a44';
      ctx.fillRect(
        CW - 55, y + 30, 55, h - 70
      );
      ctx.strokeStyle = '#555';
      ctx.strokeRect(
        CW - 53, y + 32, 51, h - 74
      );
      ctx.fillStyle = '#666';
      ctx.fillRect(CW - 49, y + 36, 3, 3);
      ctx.fillRect(CW - 9, y + 36, 3, 3);
    } else if (this.rightLight > 0) {
      ctx.fillStyle = '#1e1e2a';
      ctx.fillRect(
        CW - 55, y + 30, 55, h - 70
      );
      const ra = this.abnoAtDoor('right');
      if (ra) {
        this.drawAbnoSprite(
          CW - 45, y + 60, ra.key
        );
      }
    }

    // Door buttons (left)
    const by = y + h - 35;
    // Light button
    ctx.fillStyle = this.leftLight > 0
      ? '#cccc44' : '#444';
    ctx.fillRect(5, by - 30, 45, 20);
    ctx.fillStyle = '#fff';
    ctx.font = '8px monospace';
    ctx.fillText('LIGHT', 10, by - 15);
    // Door button
    ctx.fillStyle = this.leftDoor
      ? '#cc4444' : '#44cc44';
    ctx.fillRect(5, by, 45, 20);
    ctx.fillText(
      this.leftDoor ? 'CLOSE' : 'OPEN',
      10, by + 14
    );

    // Door buttons (right)
    ctx.fillStyle = this.rightLight > 0
      ? '#cccc44' : '#444';
    ctx.fillRect(
      CW - 50, by - 30, 45, 20
    );
    ctx.fillStyle = '#fff';
    ctx.fillText(
      'LIGHT', CW - 45, by - 15
    );
    ctx.fillStyle = this.rightDoor
      ? '#cc4444' : '#44cc44';
    ctx.fillRect(CW - 50, by, 45, 20);
    ctx.fillText(
      this.rightDoor ? 'CLOSE' : 'OPEN',
      CW - 45, by + 14
    );

    // Bottom bar: open cameras
    ctx.fillStyle = '#1a1a22';
    ctx.fillRect(0, CH - BAR_H, CW, BAR_H);
    ctx.fillStyle = '#555';
    ctx.fillRect(
      CW / 2 - 60, CH - BAR_H + 6, 120, 20
    );
    ctx.fillStyle = '#ccc';
    ctx.font = '9px monospace';
    ctx.fillText(
      'OPEN CAMERAS', CW / 2 - 42,
      CH - BAR_H + 19
    );
  }

  renderCameraFeed() {
    const ctx = this.ctx;
    const t = performance.now();
    const y = HUD_H;
    const h = CH - HUD_H - BAR_H;

    // Room rendering based on camIdx
    this.drawRoom(this.camIdx, y, h);

    // Abnormality on this camera
    const abno = this.abnoAtCam(this.camIdx);
    if (abno) {
      this.drawAbnoSprite(
        CW / 2 - 16, y + h / 2 - 20,
        abno.key
      );
    }

    // Fairy in generator room
    if (this.camIdx === 6
      && this.night >= 2) {
      this.drawAbnoSprite(
        CW / 2 + 30, y + h / 2, 'fairy'
      );
      // Charge bar
      ctx.fillStyle = '#333';
      ctx.fillRect(
        CW / 2 - 40, y + h - 30, 80, 6
      );
      ctx.fillStyle = this.fairyCharge > 80
        ? '#cc4444' : '#ccaa44';
      ctx.fillRect(
        CW / 2 - 40, y + h - 30,
        80 * (this.fairyCharge / 100), 6
      );
    }

    // Camera static overlay
    const stInt = 0.1 + this.staticLevel
      * 0.4;
    for (let sy = y; sy < y + h; sy += 2) {
      if (Math.random() < stInt) {
        const grey = Math.floor(
          Math.random() * 60
        );
        ctx.fillStyle = 'rgba('
          + grey + ',' + grey + ','
          + grey + ',0.3)';
        ctx.fillRect(
          0, sy, CW, 2
        );
      }
    }

    // Scanlines
    ctx.fillStyle = 'rgba(0,0,0,0.15)';
    for (let sl = y; sl < y + h; sl += 3) {
      ctx.fillRect(0, sl, CW, 1);
    }

    // Camera label
    ctx.fillStyle = 'rgba(0,0,0,0.6)';
    ctx.fillRect(0, y, CW, 18);
    ctx.fillStyle = '#88cc88';
    ctx.font = '9px monospace';
    ctx.fillText(
      'CAM ' + (this.camIdx + 1)
        + ': ' + CAMS[this.camIdx],
      8, y + 13
    );
    // REC indicator
    const blink = Math.sin(t * 0.005) > 0;
    if (blink) {
      ctx.fillStyle = '#ff3333';
      ctx.beginPath();
      ctx.arc(
        CW - 30, y + 9, 4, 0, Math.PI * 2
      );
      ctx.fill();
      ctx.fillText('REC', CW - 24, y + 13);
    }
  }

  renderCamBar() {
    const ctx = this.ctx;
    const by = CH - BAR_H;
    ctx.fillStyle = '#1a1a22';
    ctx.fillRect(0, by, CW, BAR_H);

    // Camera buttons
    for (let i = 0; i < 8; i++) {
      const bx = 10 + i * 52;
      const sel = i === this.camIdx;
      ctx.fillStyle = sel
        ? '#446644' : '#333';
      ctx.fillRect(bx, by + 6, 46, 20);
      ctx.fillStyle = sel
        ? '#88cc88' : '#888';
      ctx.font = '8px monospace';
      ctx.fillText(
        'CAM' + (i + 1), bx + 4, by + 19
      );
    }

    // Close button
    ctx.fillStyle = '#553333';
    ctx.fillRect(
      CW - 55, by + 6, 50, 20
    );
    ctx.fillStyle = '#cc8888';
    ctx.fillText(
      'CLOSE', CW - 50, by + 19
    );
  }

  renderMiniMap() {
    const ctx = this.ctx;
    this.mapRects = [];
    // Map position: top-right corner
    const mx = CW - 155;
    const my = HUD_H + 6;
    const mw = 148;
    const mh = 88;

    // Background
    ctx.fillStyle = 'rgba(10,10,18,0.85)';
    ctx.fillRect(mx, my, mw, mh);
    ctx.strokeStyle = '#333';
    ctx.lineWidth = 1;
    ctx.strokeRect(mx, my, mw, mh);

    // Room layout (3x3 grid roughly)
    // Row 1: ContA(0), MainHall(1), ContB(2)
    // Row 2: LCorridor(3), Break(4), RCorr(5)
    // Row 3: Generator(6), OFFICE, Server(7)
    const rooms = [
      { x: 0, y: 0, l: 'CA', i: 0 },
      { x: 1, y: 0, l: 'MH', i: 1 },
      { x: 2, y: 0, l: 'CB', i: 2 },
      { x: 0, y: 1, l: 'LC', i: 3 },
      { x: 1, y: 1, l: 'BR', i: 4 },
      { x: 2, y: 1, l: 'RC', i: 5 },
      { x: 0, y: 2, l: 'GN', i: 6 },
      { x: 1, y: 2, l: 'YOU', i: -1 },
      { x: 2, y: 2, l: 'SV', i: 7 },
    ];

    const rw = 44;
    const rh = 24;
    const gp = 4;

    // Draw connections (lines between rooms)
    ctx.strokeStyle = '#2a2a3a';
    ctx.lineWidth = 1;
    // Left path: CA->MH->LC->OFFICE
    const conns = [
      [0, 1], [1, 2], [0, 3], [2, 5],
      [3, 7], [5, 7], [1, 4],
      [3, 6], [5, 8], [6, 7], [7, 8],
    ];
    for (let ci = 0;
      ci < conns.length; ci++) {
      const a = rooms[conns[ci][0]];
      const b = rooms[conns[ci][1]];
      const ax = mx + a.x * (rw + gp)
        + rw / 2 + 4;
      const ay = my + a.y * (rh + gp)
        + rh / 2 + 4;
      const bx = mx + b.x * (rw + gp)
        + rw / 2 + 4;
      const by2 = my + b.y * (rh + gp)
        + rh / 2 + 4;
      ctx.beginPath();
      ctx.moveTo(ax, ay);
      ctx.lineTo(bx, by2);
      ctx.stroke();
    }

    // Draw rooms
    for (let ri = 0;
      ri < rooms.length; ri++) {
      const r = rooms[ri];
      const rx = mx + r.x * (rw + gp) + 4;
      const ry = my + r.y * (rh + gp) + 4;

      // Room background
      const isOffice = r.i === -1;
      const isCurrent = this.state
        === GS_CAMERA
        && this.camIdx === r.i;

      if (isOffice) {
        ctx.fillStyle = '#2a3a2a';
      } else if (isCurrent) {
        ctx.fillStyle = '#2a2a3a';
      } else {
        ctx.fillStyle = '#1a1a22';
      }
      ctx.fillRect(rx, ry, rw, rh);

      // Border
      if (isCurrent) {
        ctx.strokeStyle = '#88cc88';
      } else if (isOffice) {
        ctx.strokeStyle = '#44aa44';
      } else {
        ctx.strokeStyle = '#333';
      }
      ctx.strokeRect(rx, ry, rw, rh);

      // Room label
      ctx.fillStyle = isOffice
        ? '#44cc44' : isCurrent
          ? '#88cc88' : '#555';
      ctx.font = '6px monospace';
      ctx.fillText(
        r.l, rx + 2, ry + 9
      );

      // Clickable camera indicator
      if (r.i >= 0) {
        ctx.fillStyle = '#444';
        ctx.font = '5px monospace';
        ctx.fillText(
          'CAM' + (r.i + 1),
          rx + rw - 20, ry + rh - 3
        );
      }

      // Store rect for click detection
      if (r.i >= 0) {
        if (!this.mapRects) {
          this.mapRects = [];
        }
        this.mapRects.push({
          x: rx, y: ry,
          w: rw, h: rh,
          camIdx: r.i,
        });
      }
    }

    // DRV presence warning
    if (this.night >= 3
      && this.drvPresence > 30) {
      const pulse = Math.sin(
        performance.now() * 0.008
      );
      ctx.fillStyle = 'rgba(100,50,150,'
        + (0.3 + pulse * 0.2)
          .toFixed(2) + ')';
      ctx.font = '5px monospace';
      ctx.fillText(
        'DRV: ' + Math.floor(
          this.drvPresence
        ) + '%',
        mx + 4, my + mh - 3
      );
    }

    // Fairy charge on map
    if (this.night >= 2
      && this.fairyCharge > 20) {
      ctx.fillStyle = this.fairyCharge > 80
        ? '#cc4444' : '#ccaa44';
      ctx.font = '5px monospace';
      ctx.fillText(
        'Fairy: ' + Math.floor(
          this.fairyCharge
        ) + '%',
        mx + mw - 48, my + mh - 3
      );
    }
  }

  drawRoom(idx, y, h) {
    const ctx = this.ctx;
    const t = performance.now();

    // Base: dark room
    ctx.fillStyle = '#141420';
    ctx.fillRect(0, y, CW, h);

    switch (idx) {
      case 0: // Containment A
      case 2: // Containment B
        // Cell walls
        ctx.strokeStyle = '#2a2a3a';
        ctx.lineWidth = 2;
        ctx.strokeRect(
          40, y + 20, CW - 80, h - 40
        );
        // Broken glass (zigzag)
        ctx.strokeStyle = '#8899aa';
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.moveTo(CW / 2 - 30, y + 20);
        for (let gx = -25; gx <= 25;
          gx += 10) {
          ctx.lineTo(
            CW / 2 + gx,
            y + 20 + (gx % 20 ? 8 : 0)
          );
        }
        ctx.stroke();
        // Equipment
        ctx.fillStyle = '#2a2a33';
        ctx.fillRect(
          60, y + h - 50, 40, 30
        );
        ctx.fillRect(
          CW - 100, y + h - 50, 40, 30
        );
        // Blink dots
        ctx.fillStyle = Math.sin(
          t * 0.003
        ) > 0 ? '#44cc44' : '#333';
        ctx.fillRect(70, y + h - 44, 3, 3);
        ctx.fillRect(
          CW - 90, y + h - 44, 3, 3
        );
        break;

      case 1: // Main Hall
        // Perspective corridor
        ctx.fillStyle = '#1a1a28';
        ctx.beginPath();
        ctx.moveTo(0, y + h);
        ctx.lineTo(CW / 4, y + 20);
        ctx.lineTo(CW * 3 / 4, y + 20);
        ctx.lineTo(CW, y + h);
        ctx.fill();
        // Wall panels
        for (let px = CW / 4;
          px < CW * 3 / 4; px += 60) {
          ctx.strokeStyle = '#222233';
          ctx.strokeRect(
            px, y + 25, 55, h - 60
          );
        }
        // Fluorescent light
        const fl = Math.sin(
          t * 0.007
            + Math.sin(t * 0.002) * 3
        );
        if (fl > 0.2) {
          ctx.fillStyle = 'rgba(180,190,'
            + '200,'
            + (0.08 + fl * 0.04)
              .toFixed(3) + ')';
          ctx.fillRect(
            CW / 3, y + 22, CW / 3, 3
          );
        }
        // Enkephalin stain
        const grd = ctx.createRadialGradient(
          CW / 2, y + h - 30, 2,
          CW / 2, y + h - 30, 20
        );
        grd.addColorStop(
          0, 'rgba(255,170,50,0.15)'
        );
        grd.addColorStop(
          1, 'rgba(255,170,50,0)'
        );
        ctx.fillStyle = grd;
        ctx.fillRect(
          CW / 2 - 25, y + h - 55, 50, 50
        );
        break;

      case 3: // Left Corridor
      case 5: // Right Corridor
        ctx.fillStyle = '#161622';
        ctx.fillRect(
          80, y + 10, CW - 160, h - 20
        );
        // Damaged panels
        ctx.strokeStyle = '#222233';
        for (let px = 90;
          px < CW - 90; px += 70) {
          ctx.strokeRect(
            px, y + 15, 60, h - 30
          );
        }
        // Cracks
        ctx.strokeStyle = '#1a1a2a';
        ctx.beginPath();
        ctx.moveTo(200, y + 40);
        ctx.lineTo(210, y + 55);
        ctx.lineTo(205, y + 65);
        ctx.lineTo(215, y + 80);
        ctx.stroke();
        // Exposed wires
        ctx.strokeStyle = '#cc4444';
        ctx.beginPath();
        ctx.moveTo(300, y + 12);
        ctx.lineTo(305, y + 40);
        ctx.stroke();
        ctx.strokeStyle = '#cccc44';
        ctx.beginPath();
        ctx.moveTo(310, y + 12);
        ctx.lineTo(308, y + 35);
        ctx.stroke();
        // Red emergency light
        const rg = ctx.createRadialGradient(
          CW / 2, y + h - 10, 2,
          CW / 2, y + h - 10, 40
        );
        rg.addColorStop(
          0, 'rgba(200,40,30,0.2)'
        );
        rg.addColorStop(
          1, 'rgba(200,40,30,0)'
        );
        ctx.fillStyle = rg;
        ctx.fillRect(
          CW / 2 - 45, y + h - 55, 90, 50
        );
        break;

      case 4: // Break Room
        ctx.fillStyle = '#181825';
        ctx.fillRect(
          40, y + 10, CW - 80, h - 20
        );
        // Tables
        ctx.fillStyle = '#2a2a35';
        ctx.fillRect(
          100, y + h / 2 - 10, 80, 20
        );
        ctx.fillRect(
          300, y + h / 2 - 10, 80, 20
        );
        // Overturned chair
        ctx.fillStyle = '#333';
        ctx.save();
        ctx.translate(200, y + h / 2 + 20);
        ctx.rotate(0.8);
        ctx.fillRect(0, 0, 15, 15);
        ctx.restore();
        // Vending machine
        ctx.fillStyle = '#222';
        ctx.fillRect(
          CW - 80, y + 30, 30, 60
        );
        const vg = Math.sin(t * 0.002);
        ctx.fillStyle = 'rgba(80,180,80,'
          + (0.2 + vg * 0.1).toFixed(2)
          + ')';
        ctx.fillRect(
          CW - 76, y + 34, 22, 20
        );
        break;

      case 6: // Generator Room
        // Generator
        ctx.fillStyle = '#2a2a33';
        ctx.fillRect(
          CW / 2 - 50, y + 30, 100, 80
        );
        // Amber core (pulsing)
        const gp = Math.sin(t * 0.004);
        const gg = ctx.createRadialGradient(
          CW / 2, y + 70, 5,
          CW / 2, y + 70, 30
        );
        gg.addColorStop(
          0, 'rgba(255,170,50,'
            + (0.4 + gp * 0.2)
              .toFixed(2) + ')'
        );
        gg.addColorStop(
          1, 'rgba(255,170,50,0)'
        );
        ctx.fillStyle = gg;
        ctx.fillRect(
          CW / 2 - 35, y + 40, 70, 60
        );
        // Pipes
        ctx.fillStyle = '#333';
        ctx.fillRect(
          60, y + 50, CW / 2 - 110, 6
        );
        ctx.fillRect(
          CW / 2 + 50, y + 50,
          CW / 2 - 110, 6
        );
        // Sparks (low power)
        if (this.power < 40) {
          if (Math.random() < 0.3) {
            ctx.fillStyle = '#ffcc44';
            ctx.fillRect(
              CW / 2 - 45
                + Math.random() * 90,
              y + 35 + Math.random() * 70,
              2, 2
            );
          }
        }
        break;

      case 7: // Server Room
        // Blue tint
        ctx.fillStyle = '#101828';
        ctx.fillRect(
          40, y + 10, CW - 80, h - 20
        );
        // Server racks
        for (let rx = 60; rx < CW - 60;
          rx += 80) {
          ctx.fillStyle = '#1a1a2a';
          ctx.fillRect(
            rx, y + 20, 30, h - 40
          );
          // Blinking dots
          for (let dy = 0; dy < 8; dy++) {
            const on = Math.sin(
              t * 0.003 + rx + dy
            ) > 0;
            ctx.fillStyle = on
              ? '#4488cc' : '#222';
            ctx.fillRect(
              rx + 4, y + 28 + dy * 14,
              3, 3
            );
            ctx.fillStyle = on
              ? '#44cc44' : '#222';
            ctx.fillRect(
              rx + 10, y + 28 + dy * 14,
              3, 3
            );
          }
        }
        break;
      default: break;
    }

    // Floor for all rooms
    ctx.fillStyle = '#1c1c28';
    ctx.fillRect(0, y + h - 15, CW, 15);
  }

  drawAbnoSprite(x, y, key) {
    const ctx = this.ctx;
    const img = this.spriteImgs[key];
    if (img && img.complete
      && img.naturalWidth > 0) {
      ctx.drawImage(img, x, y, 32, 32);
    } else {
      // Fallback colored rect
      const clrs = {
        pbird: '#ff4444',
        beauty: '#cc88aa',
        clayman: '#888844',
        schadenfreude: '#666688',
        redshoes: '#cc3344',
        fairy: '#88ccaa',
        drv: '#444466',
      };
      ctx.fillStyle = clrs[key] || '#888';
      ctx.fillRect(x, y, 24, 32);
      ctx.fillStyle = '#fff';
      ctx.font = '6px monospace';
      ctx.fillText(
        key.substring(0, 4), x, y + 40
      );
    }
  }

  renderTitle() {
    const ctx = this.ctx;
    ctx.strokeStyle = '#cc6633';
    ctx.lineWidth = 2;
    ctx.strokeRect(
      10, 10, CW - 20, CH - 20
    );
    ctx.lineWidth = 1;

    this.cText(
      'L CORP OVERTIME', '#cc6633', 18, -80
    );
    this.cText(
      'Fallen Facility - District 12',
      '#666', 8, -56
    );
    this.cText(
      'Monitor cameras.', '#aaa', 8, -30
    );
    this.cText(
      'Close doors. Manage power.', '#aaa',
      8, -18
    );
    this.cText(
      'Don\'t let them in.', '#cc4444', 9, 0
    );
    this.cText(
      'Survive 5 nights.', '#aaa', 8, 18
    );
    this.cText(
      'Press ENTER to Start',
      '#44ff44', 10, 50
    );
    // Leaderboard
    this.cText(
      '-- LEADERBOARD --',
      '#ffaa44', 8, 74
    );
    const lb = this.leaderboard || [];
    if (!lb.length) {
      this.cText(
        'No scores yet', '#555', 7, 86
      );
    }
    for (let i = 0; i < lb.length
      && i < 5; i++) {
      const e = lb[i];
      const n = (e.name || '???')
        .substring(0, 6);
      this.cText(
        (i + 1) + '. ' + n + ' '
          + (e.score || 0),
        '#ffff44', 7, 86 + i * 11
      );
    }
  }

  renderNightStart() {
    this.cText(
      'Night ' + (this.night + 1),
      '#cc6633', 20, -10
    );
    this.cText(
      '12:00 AM', '#888', 10, 16
    );
  }

  renderNightEnd() {
    this.cText(
      '6 AM', '#ffcc44', 20, -20
    );
    this.cText(
      'Night ' + this.night
        + ' survived!',
      '#44cc44', 10, 10
    );
    this.cText(
      'Score: ' + this.score,
      '#aaa', 9, 30
    );
  }

  renderDeath() {
    const ctx = this.ctx;
    ctx.fillStyle = 'rgba(80,0,0,0.8)';
    ctx.fillRect(0, 0, CW, CH);
    this.cText(
      'GAME OVER', '#ff4444', 18, -30
    );
    this.cText(
      this.deathMsg, '#ccc', 9, 0
    );
    this.cText(
      'Night ' + (this.night + 1)
        + '  Score: ' + this.score,
      '#aaa', 9, 20
    );
    this.cText(
      'Press R to retry', '#888', 8, 50
    );
  }

  renderWin() {
    this.cText(
      'ALL 5 NIGHTS SURVIVED!',
      '#ffcc44', 16, -30
    );
    this.cText(
      'Final Score: ' + this.score,
      '#fff', 12, 0
    );
    this.cText(
      'Press R to play again',
      '#aaa', 9, 30
    );
  }

  renderNameEntry() {
    this.cText(
      'ALL 5 NIGHTS SURVIVED!',
      '#ffcc44', 14, -60
    );
    this.cText(
      'Score: ' + this.score,
      '#fff', 10, -36
    );
    this.cText(
      'Enter your name:', '#aaa', 9, -10
    );
    const ctx = this.ctx;
    ctx.fillStyle = '#222';
    ctx.fillRect(
      CW / 2 - 50, CH / 2 + 4, 100, 22
    );
    ctx.fillStyle = '#ffcc44';
    ctx.font = '14px monospace';
    ctx.fillText(
      this.entryName + '_',
      CW / 2 - 40, CH / 2 + 20
    );
    this.cText(
      'Type name, press ENTER',
      '#666', 8, 40
    );
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

    if (this.state === GS_NIGHT_END) {
      this.startNight();
      return;
    }

    if (this.state === GS_OFFICE) {
      const y = HUD_H;
      const h = CH - HUD_H - BAR_H;
      const by = y + h - 35;

      // Left light
      if (mx >= 5 && mx <= 50
        && my >= by - 30 && my <= by - 10) {
        this.leftLight = 0.8;
        this.power -= 0.4;
        this.act('sfx', { s: 'light' });
        return;
      }
      // Left door
      if (mx >= 5 && mx <= 50
        && my >= by && my <= by + 20) {
        this.leftDoor = !this.leftDoor;
        this.act('sfx', { s: 'door' });
        return;
      }
      // Right light
      if (mx >= CW - 50 && mx <= CW - 5
        && my >= by - 30 && my <= by - 10) {
        this.rightLight = 0.8;
        this.power -= 0.4;
        this.act('sfx', { s: 'light' });
        return;
      }
      // Right door
      if (mx >= CW - 50 && mx <= CW - 5
        && my >= by && my <= by + 20) {
        this.rightDoor = !this.rightDoor;
        this.act('sfx', { s: 'door' });
        return;
      }
      // Open cameras
      if (mx >= CW / 2 - 60
        && mx <= CW / 2 + 60
        && my >= CH - BAR_H + 6
        && my <= CH - BAR_H + 26) {
        this.state = GS_CAMERA;
        this.act('sfx', { s: 'cam' });
        return;
      }
      // Minimap room click
      if (this.mapRects) {
        for (let i = 0;
          i < this.mapRects.length; i++) {
          const r = this.mapRects[i];
          if (mx >= r.x && mx <= r.x + r.w
            && my >= r.y
            && my <= r.y + r.h) {
            this.camIdx = r.camIdx;
            this.state = GS_CAMERA;
            this.act('sfx', { s: 'cam' });
            return;
          }
        }
      }
    }

    if (this.state === GS_CAMERA) {
      const by = CH - BAR_H;
      // Camera buttons
      for (let i = 0; i < 8; i++) {
        const bx = 10 + i * 52;
        if (mx >= bx && mx <= bx + 46
          && my >= by + 6
          && my <= by + 26) {
          this.camIdx = i;
          this.act('sfx', { s: 'cam' });
          return;
        }
      }
      // Close cameras
      if (mx >= CW - 55
        && mx <= CW - 5
        && my >= by + 6
        && my <= by + 26) {
        this.state = GS_OFFICE;
        return;
      }
      // Minimap room click (camera view)
      if (this.mapRects) {
        for (let i = 0;
          i < this.mapRects.length; i++) {
          const r = this.mapRects[i];
          if (mx >= r.x && mx <= r.x + r.w
            && my >= r.y
            && my <= r.y + r.h) {
            this.camIdx = r.camIdx;
            this.act('sfx', { s: 'cam' });
            return;
          }
        }
      }
    }
  }

  handleKeyDown(code) {
    if (this.state === GS_TITLE
      && code === KEY_ENTER) {
      this.startGame();
    }
    if ((this.state === GS_DEAD
      || this.state === GS_WIN)
      && code === KEY_R) {
      this.state = GS_TITLE;
    }
    // Name entry
    if (this.state === GS_NAMEENTRY) {
      if (code === KEY_ENTER
        && this.entryName.length > 0) {
        this.act('submit_score', {
          score: this.score,
          name: this.entryName,
        });
        this.state = GS_WIN;
      } else if (code === 8) {
        this.entryName = this.entryName
          .substring(
            0, this.entryName.length - 1
          );
      } else if (code >= 65 && code <= 90
        && this.entryName.length < 6) {
        this.entryName += String
          .fromCharCode(code);
      }
    }
  }
}

// TGUI Component

const ACQUIRED_KEYS = [KEY_R];

class ArcadeLCOvertimeGame extends Component {
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

    this.engine = new OvertimeEngine(
      canvas, this.props.act
    );
    this.engine.leaderboard
      = this.props.data.leaderboard || [];

    const sd = this.props.data;
    if (sd) this.engine.loadData(sd);

    this.engine.start();
    canvas.focus();
  }

  componentDidUpdate(prevProps) {
    if (!this.engine) return;
    const sd = this.props.data;
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
        onMouseDown={e => {
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

export const ArcadeLCOvertime = (
  props, context
) => {
  const { act, data } = useBackend(context);
  return (
    <Window
      width={CW + 30}
      height={CH + 50}>
      <Window.Content>
        <ArcadeLCOvertimeGame
          act={act}
          data={data}
        />
      </Window.Content>
    </Window>
  );
};
