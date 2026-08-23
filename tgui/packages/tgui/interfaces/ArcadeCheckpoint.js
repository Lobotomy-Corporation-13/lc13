/**
 * @file
 * @copyright 2024
 * @license MIT
 *
 * K Corp Immigration Checkpoint
 * Papers Please-inspired document checking
 * minigame at K Corp District 11.
 */

import { Component, createRef } from 'inferno';
import { useBackend } from '../backend';
import { Window } from '../layouts';
import {
  acquireHotKey,
  releaseHotKey,
} from '../hotkeys';

// Constants

const CW = 780;
const CH = 500;
const HUD_H = 28;
const ACT_H = 44;
const PAN_APP = 150;
const PAN_DOC = 350;
const PAN_RULE = 280;

const KEY_1 = 49;
const KEY_2 = 50;
const KEY_3 = 51;
const KEY_4 = 52;
const KEY_5 = 53;
const KEY_A = 65;
const KEY_D = 68;
const KEY_LEFT = 37;
const KEY_RIGHT = 39;
const KEY_ENTER = 13;
const KEY_R = 82;
const KEY_TAB = 9;

const GS_TITLE = 0;
const GS_DAY_START = 1;
const GS_REVIEWING = 2;
const GS_RESULT = 3;
const GS_DAY_END = 4;
const GS_GAMEOVER = 5;
const GS_WIN = 6;
const GS_NAMEENTRY = 7;

// Economy
const PAY_CORRECT = 50000;
const PAY_WRONG = -100000;
const DAILY_RENT = 500000;
const START_AHN = 300000;
const PERFECT_BONUS = 200000;

// Colors - K Corp emerald theme
const CB = '#0a1a12';
const CP = '#0d2218';
const CE = '#22cc66';
const CED = '#187744';
const CPP = '#e8e0d0';
const CPD = '#c8c0b0';
const CSA = '#22aa44';
const CSD = '#cc2222';

// Hair colors for rendering
const HAIR_COLORS = {
  black: '#222',
  brown: '#663322',
  blonde: '#ccaa44',
  red: '#aa3322',
  grey: '#888',
  white: '#ddd',
};

const EYE_COLORS = {
  brown: '#664422',
  blue: '#3366cc',
  green: '#338844',
  grey: '#777',
  amber: '#cc8833',
};

// Game Engine

class CheckpointEngine {
  constructor(canvas, act) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.act = act;
    this.keys = {};
    this.state = GS_TITLE;
    this.rafId = null;
    this.lastTime = 0;

    this.days = [];
    this.currentDay = 0;
    this.applicants = [];
    this.appIndex = 0;
    this.currentApp = null;
    this.docIndex = 0;
    this.timer = 0;
    this.ahn = START_AHN;
    this.mistakes = 0;
    this.correct = 0;
    this.totalProcessed = 0;
    this.leaderboard = 0;
    this.entryName = '';
    this.nameDone = false;
    this.resultTimer = 0;
    this.resultText = '';
    this.resultColor = '';
    this.dayStartTimer = 0;
    this.gameDate = '984-03-15';
    this.ruleScroll = 0;
    this.showRef = false;
  }

  loadData(sd) {
    if (sd.days) this.days = sd.days;
    if (sd.gameDate) this.gameDate = sd.gameDate;
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

  startDay(idx) {
    this.currentDay = idx;
    const day = this.days[idx];
    this.applicants = day.applicants || [];
    this.appIndex = 0;
    this.docIndex = 0;
    this.timer = day.timeLimit || 180;
    this.mistakes = 0;
    this.correct = 0;
    this.state = GS_DAY_START;
    this.dayStartTimer = 2.5;
    this.ruleScroll = 0;
    if (this.applicants.length > 0) {
      this.currentApp = this.applicants[0];
    }
  }

  nextApplicant() {
    this.appIndex++;
    this.docIndex = 0;
    if (this.appIndex >= this.applicants.length
      || this.timer <= 0) {
      this.endDay();
    } else {
      this.currentApp = this.applicants[
        this.appIndex
      ];
      this.state = GS_REVIEWING;
      this.act('sfx', { s: 'bell' });
    }
  }

  processVerdict(choice) {
    if (!this.currentApp) return;
    const correct = this.currentApp.verdict;
    this.totalProcessed++;
    if (choice === correct) {
      this.ahn += PAY_CORRECT;
      this.correct++;
      this.resultText = 'CORRECT +50,000';
      this.resultColor = CSA;
      this.act('sfx', { s: 'correct' });
    } else {
      this.ahn += PAY_WRONG;
      this.mistakes++;
      const r = this.currentApp.reasons;
      if (choice === 'APPROVE' && r.length) {
        this.resultText = 'WRONG: '
          + r[0];
      } else {
        this.resultText = 'WRONG: Was valid';
      }
      this.resultColor = CSD;
      this.act('sfx', { s: 'wrong' });
    }
    this.act('sfx', { s: 'stamp' });
    this.state = GS_RESULT;
    this.resultTimer = 1.5;
  }

  endDay() {
    this.ahn -= DAILY_RENT;
    if (this.mistakes === 0) {
      this.ahn += PERFECT_BONUS;
    }
    this.state = GS_DAY_END;
  }

  update(dt) {
    if (this.state === GS_DAY_START) {
      this.dayStartTimer -= dt;
      if (this.dayStartTimer <= 0) {
        this.state = GS_REVIEWING;
      }
      return;
    }
    if (this.state === GS_REVIEWING) {
      this.timer -= dt;
      if (this.timer <= 0) {
        this.timer = 0;
        this.endDay();
      }
    }
    if (this.state === GS_RESULT) {
      this.resultTimer -= dt;
      if (this.resultTimer <= 0) {
        this.nextApplicant();
      }
    }
  }

  render() {
    const ctx = this.ctx;
    ctx.fillStyle = CB;
    ctx.fillRect(0, 0, CW, CH);

    switch (this.state) {
      case GS_TITLE:
        this.renderTitle();
        break;
      case GS_DAY_START:
        this.renderDayStart();
        break;
      case GS_REVIEWING:
      case GS_RESULT:
        this.renderHUD();
        this.renderApplicant();
        if (this.showRef) {
          this.renderReference();
        } else {
          this.renderDocument();
        }
        this.renderRuleBook();
        this.renderActionBar();
        if (this.state === GS_RESULT) {
          this.renderResult();
        }
        break;
      case GS_DAY_END:
        this.renderDayEnd();
        break;
      case GS_GAMEOVER:
        this.renderGameOver();
        break;
      case GS_WIN:
        this.renderWin();
        break;
      case GS_NAMEENTRY:
        this.renderNameEntry();
        break;
      default:
        break;
    }
  }

  renderTitle() {
    const ctx = this.ctx;
    ctx.strokeStyle = CE;
    ctx.lineWidth = 3;
    ctx.strokeRect(10, 10, CW - 20, CH - 20);

    this.cText(
      'K CORP CHECKPOINT', CE, 36, -130
    );
    this.cText(
      'District 11 Immigration',
      '#888', 16, -94
    );
    this.cText(
      'Process documents.',
      '#aaa', 16, -56
    );
    this.cText(
      'Spot discrepancies.',
      '#aaa', 16, -34
    );
    this.cText(
      'Stamp APPROVED or DENIED.',
      '#aaa', 16, -12
    );
    this.cText(
      'A = Approve  D = Deny',
      '#ccc', 14, 22
    );
    this.cText(
      '1-5 = Switch docs',
      '#ccc', 14, 44
    );
    this.cText(
      'Earn Ahn. Pay rent. Survive.',
      '#ffcc44', 14, 74
    );
    this.cText(
      'Press ENTER to Start',
      '#44ff44', 20, 110
    );
    // Leaderboard
    this.cText(
      '-- LEADERBOARD --',
      '#ffaa44', 14, 140
    );
    const lb = this.leaderboard || [];
    if (lb.length === 0) {
      this.cText(
        'No scores yet', '#666', 12, 162
      );
    }
    for (let i = 0; i < lb.length
      && i < 5; i++) {
      const e = lb[i];
      const n = (e.name || '???')
        .substring(0, 10);
      const s = this.fmtAhn(e.score || 0);
      const t = (i + 1) + '. '
        + n + ' ' + s;
      this.cText(
        t, '#ffff44', 12, 162 + i * 17
      );
    }
  }

  renderDayStart() {
    const ctx = this.ctx;
    const d = this.days[this.currentDay];
    this.cText(
      'DAY ' + d.day, CE, 20, -30
    );
    this.cText(
      this.applicants.length
        + ' applicants',
      '#aaa', 10, 0
    );
    // Show new rules
    const rules = d.rules || [];
    for (let i = 0;
      i < rules.length && i < 6; i++) {
      this.cText(
        '- ' + rules[i],
        '#ffcc44', 8, 24 + i * 14
      );
    }
  }

  renderHUD() {
    const ctx = this.ctx;
    ctx.fillStyle = '#111';
    ctx.fillRect(0, 0, CW, HUD_H);

    ctx.fillStyle = '#fff';
    ctx.font = '10px monospace';
    const d = this.days[this.currentDay];
    ctx.fillText(
      'DAY ' + d.day, 6, 15
    );

    const secs = Math.ceil(this.timer);
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    const ts = m + ':' + (
      s < 10 ? '0' + s : s
    );
    ctx.fillText(ts, 70, 15);

    ctx.fillStyle = this.ahn >= 0
      ? '#ffcc44' : '#ff4444';
    ctx.fillText(
      this.fmtAhn(this.ahn) + ' Ahn',
      140, 15
    );

    ctx.fillStyle = '#aaa';
    ctx.fillText(
      (this.appIndex + 1) + '/'
        + this.applicants.length,
      CW - 40, 15
    );

    ctx.fillStyle = CSA;
    ctx.fillText(
      'OK:' + this.correct, 300, 15
    );
    ctx.fillStyle = CSD;
    ctx.fillText(
      'ERR:' + this.mistakes, 360, 15
    );
  }

  renderApplicant() {
    const ctx = this.ctx;
    const x = 0;
    const y = HUD_H;
    const w = PAN_APP;
    const h = CH - HUD_H - ACT_H;

    // Panel bg
    ctx.fillStyle = CP;
    ctx.fillRect(x, y, w, h);
    ctx.strokeStyle = CED;
    ctx.lineWidth = 1;
    ctx.strokeRect(x, y, w, h);

    if (!this.currentApp) return;
    const ap = this.currentApp.appearance;

    // Draw face
    const cx = x + w / 2;
    const fy = y + 60;

    // Head
    ctx.fillStyle = '#ddb088';
    ctx.beginPath();
    ctx.ellipse(
      cx, fy, 22, 28, 0, 0, Math.PI * 2
    );
    ctx.fill();

    // Hair
    ctx.fillStyle = HAIR_COLORS[ap.hair]
      || '#333';
    ctx.fillRect(cx - 24, fy - 30, 48, 18);
    ctx.fillRect(cx - 22, fy - 22, 6, 20);
    ctx.fillRect(cx + 16, fy - 22, 6, 20);

    // Eyes
    ctx.fillStyle = EYE_COLORS[ap.eyes]
      || '#555';
    ctx.fillRect(cx - 10, fy - 6, 6, 5);
    ctx.fillRect(cx + 4, fy - 6, 6, 5);

    // Mouth
    ctx.fillStyle = '#aa6655';
    ctx.fillRect(cx - 4, fy + 10, 8, 3);

    // Body
    ctx.fillStyle = '#556677';
    ctx.fillRect(cx - 20, fy + 32, 40, 50);

    // Prosthetic indicator
    if (ap.prosthetic !== 'none') {
      ctx.fillStyle = '#888899';
      if (ap.prosthetic === 'left arm') {
        ctx.fillRect(
          cx - 30, fy + 34, 10, 35
        );
      } else if (
        ap.prosthetic === 'right arm'
      ) {
        ctx.fillRect(
          cx + 20, fy + 34, 10, 35
        );
      } else if (ap.prosthetic === 'jaw') {
        ctx.fillRect(
          cx - 10, fy + 6, 20, 12
        );
      } else if (
        ap.prosthetic === 'eyes'
      ) {
        ctx.fillStyle = '#ff4444';
        ctx.fillRect(
          cx - 10, fy - 6, 6, 5
        );
        ctx.fillRect(
          cx + 4, fy - 6, 6, 5
        );
      }
    }

    // Gender label
    ctx.fillStyle = '#aaa';
    ctx.font = '10px monospace';
    ctx.fillText(
      ap.gender === 'M' ? 'Male' : 'Female',
      x + 6, y + h - 20
    );

    // Name below
    ctx.fillStyle = '#ddd';
    ctx.font = '10px monospace';
    const nm = this.currentApp.name;
    if (nm.length > 14) {
      ctx.fillText(
        nm.substring(0, 14),
        x + 4, y + h - 8
      );
    } else {
      ctx.fillText(nm, x + 4, y + h - 8);
    }
  }

  renderDocument() {
    const ctx = this.ctx;
    const x = PAN_APP;
    const y = HUD_H;
    const w = PAN_DOC;
    const h = CH - HUD_H - ACT_H;

    ctx.fillStyle = CP;
    ctx.fillRect(x, y, w, h);

    if (!this.currentApp) return;
    const docs = this.currentApp.documents;
    if (!docs || !docs.length) return;

    const di = Math.min(
      this.docIndex, docs.length - 1
    );
    const doc = docs[di];

    // Paper background
    const px = x + 10;
    const py = y + 8;
    const pw = w - 20;
    const ph = h - 40;
    ctx.fillStyle = CPP;
    ctx.fillRect(px, py, pw, ph);
    ctx.strokeStyle = CPD;
    ctx.lineWidth = 1;
    ctx.strokeRect(px, py, pw, ph);

    // Document header
    ctx.fillStyle = CED;
    ctx.fillRect(px, py, pw, 18);
    ctx.fillStyle = '#fff';
    ctx.font = 'bold 9px monospace';
    const titles = {
      passport: 'NEST ENTRY PASSPORT',
      visa: 'K CORP MIGRATION VISA',
      fixer: 'FIXER LICENSE',
      employment: 'WING EMPLOYMENT CERT',
      transit: 'BACKSTREETS TRANSIT PASS',
    };
    ctx.fillText(
      titles[doc.type] || doc.type,
      px + 6, py + 13
    );

    // Render fields
    ctx.font = '10px monospace';
    let ly = py + 32;
    const lx = px + 8;
    const lh = 16;

    const field = (label, val) => {
      ctx.fillStyle = '#666';
      ctx.fillText(label, lx, ly);
      ctx.fillStyle = '#222';
      ctx.fillText(
        String(val),
        lx + label.length * 5 + 4, ly
      );
      ly += lh;
    };

    switch (doc.type) {
      case 'passport':
        field('Name: ', doc.name);
        field('DOB: ', doc.dob);
        field('District: ', doc.district);
        field('Expires: ', doc.expires);
        field('Number: ', doc.number);
        field('Gender: ', doc.gender);
        ly += 6;
        // Photo info
        ctx.fillStyle = '#666';
        ctx.fillText(
          '--- Photo Data ---', lx, ly
        );
        ly += lh;
        field('Hair: ', doc.hair);
        field('Eyes: ', doc.eyes);
        field('Prosthetic: ',
          doc.prosthetic);
        // Seal
        ly += 6;
        ctx.fillStyle = CE;
        ctx.beginPath();
        ctx.arc(
          px + pw - 25, py + ph - 25,
          15, 0, Math.PI * 2
        );
        ctx.fill();
        ctx.fillStyle = '#fff';
        ctx.font = 'bold 10px monospace';
        ctx.fillText(
          'K', px + pw - 29, py + ph - 21
        );
        break;

      case 'visa':
        field('Name: ', doc.name);
        field('Type: ', doc.visaType);
        field('Issuer: ', doc.issuer);
        field('Expires: ', doc.expires);
        field('Duration: ',
          doc.duration + ' days');
        // Stamp
        ly += 8;
        ctx.fillStyle = CE;
        ctx.fillRect(
          lx, ly, 80, 16
        );
        ctx.fillStyle = '#fff';
        ctx.font = '10px monospace';
        ctx.fillText(
          'K CORP APPROVED', lx + 4, ly + 11
        );
        break;

      case 'fixer':
        field('Name: ', doc.name);
        field('Grade: ', doc.grade);
        field('Issuer: ', doc.issuer);
        field('Fitness: ', doc.fitness);
        field('Expires: ', doc.expires);
        // Hana stamp
        ly += 8;
        ctx.fillStyle = '#cc8844';
        ctx.fillRect(lx, ly, 90, 16);
        ctx.fillStyle = '#fff';
        ctx.font = '10px monospace';
        ctx.fillText(
          'HANA ASSOCIATION', lx + 4,
          ly + 11
        );
        break;

      case 'employment':
        field('Name: ', doc.name);
        field('Corp: ', doc.corp);
        field('Feather: ', doc.feather);
        field('Seal: ', doc.seal);
        // Corp seal circle
        ly += 8;
        const sealColors = {
          emerald: CE,
          red: '#cc3333',
          sepia: '#aa8855',
          silver: '#aaaaaa',
          white: '#dddddd',
          blue: '#3366cc',
          crimson: '#cc2244',
          gold: '#ccaa33',
        };
        ctx.fillStyle = sealColors[doc.seal]
          || '#888';
        ctx.beginPath();
        ctx.arc(
          lx + 20, ly + 10,
          12, 0, Math.PI * 2
        );
        ctx.fill();
        ctx.fillStyle = '#fff';
        ctx.font = 'bold 8px monospace';
        const sl = doc.corp.charAt(0);
        ctx.fillText(sl, lx + 17, ly + 14);
        break;

      case 'transit':
        field('Name: ', doc.name);
        field('Origin: ',
          'District ' + doc.origin);
        field('Dest: ',
          'District ' + doc.destination);
        field('Number: ', doc.number);
        // Date stamp
        ly += 8;
        ctx.fillStyle = '#886644';
        ctx.fillRect(lx, ly, 80, 16);
        ctx.fillStyle = '#fff';
        ctx.font = '10px monospace';
        ctx.fillText(
          'TRANSIT STAMP', lx + 6, ly + 11
        );
        break;
      default:
        break;
    }

    // Doc tabs at bottom of doc panel
    const tabY = y + h - 28;
    ctx.font = '10px monospace';
    for (let i = 0; i < docs.length; i++) {
      const tx = x + 12 + i * 54;
      const sel = i === di;
      ctx.fillStyle = sel ? CE : '#444';
      ctx.fillRect(tx, tabY, 50, 16);
      ctx.fillStyle = sel ? '#fff' : '#aaa';
      const tl = (i + 1) + ':'
        + docs[i].type.substring(0, 4);
      ctx.fillText(tl, tx + 4, tabY + 11);
    }
  }

  renderReference() {
    const ctx = this.ctx;
    const x = PAN_APP;
    const y = HUD_H;
    const w = PAN_DOC;
    const h = CH - HUD_H - ACT_H;

    // Background
    ctx.fillStyle = '#0c1810';
    ctx.fillRect(x, y, w, h);
    ctx.strokeStyle = CE;
    ctx.lineWidth = 1;
    ctx.strokeRect(x, y, w, h);

    // Header
    ctx.fillStyle = CED;
    ctx.fillRect(x, y, w, 18);
    ctx.fillStyle = '#fff';
    ctx.font = 'bold 9px monospace';
    ctx.fillText(
      'REFERENCE CARD [TAB to close]',
      x + 6, y + 13
    );

    ctx.font = '10px monospace';
    let ly = y + 32;
    const lx = x + 8;
    const lh = 14;

    const line = (text, color) => {
      ctx.fillStyle = color || '#ccc';
      ctx.fillText(text, lx, ly);
      ly += lh;
    };

    line('TODAY: ' + this.gameDate, CE);
    ly += 4;

    line('--- DOCUMENT CHECKS ---', '#ffcc44');
    line('Passport: valid district 1-26');
    line('  Check expiry vs today');
    line('  Photo: hair/eyes/prosthetic');
    ly += 4;

    line('Visa: name must match passport');
    line('  Visitor max: 30d (14d day 6+)');
    line('  Transit max: 7 days');
    line('  Issuer: K Corp. Bureau');
    ly += 4;

    line('Fixer License:', '#ffcc44');
    line('  Issuer must be Hana Assoc.');
    line('  Minimum age: 20');
    line('  Fitness stamp: must be PASS');
    ly += 4;

    line('Employment Cert:', '#ffcc44');
    line('  K Corp = emerald seal');
    line('  R Corp = red seal');
    line('  T Corp = sepia seal');
    line('  G Corp = silver seal');
    line('  N Corp = white seal');
    line('  W Corp = blue seal');
    line('  H Corp = crimson seal');
    line('  P Corp = gold seal');
    line('  Feather rank: K Corp ONLY');
    ly += 4;

    line('Transit Pass:', '#ffcc44');
    line('  Destination must be Dist 11');
    line('  Check bulletin for dupes');
  }

  renderRuleBook() {
    const ctx = this.ctx;
    const x = PAN_APP + PAN_DOC;
    const y = HUD_H;
    const w = PAN_RULE;
    const h = CH - HUD_H - ACT_H;

    ctx.fillStyle = '#0a0f0c';
    ctx.fillRect(x, y, w, h);
    ctx.strokeStyle = CED;
    ctx.lineWidth = 1;
    ctx.strokeRect(x, y, w, h);

    // Header
    ctx.fillStyle = CED;
    ctx.fillRect(x, y, w, 18);
    ctx.fillStyle = '#fff';
    ctx.font = 'bold 8px monospace';
    ctx.fillText(
      'DAILY BULLETIN', x + 6, y + 13
    );

    const d = this.days[this.currentDay];
    if (!d) return;

    ctx.font = '10px monospace';
    let ly = y + 32;
    const lx = x + 6;
    const lh = 14;
    const maxY = y + h - 8;

    // Rules
    ctx.fillStyle = '#ffcc44';
    ctx.fillText('RULES:', lx, ly);
    ly += lh;
    const rules = d.rules || [];
    for (let i = 0; i < rules.length; i++) {
      if (ly > maxY) break;
      ctx.fillStyle = '#ccc';
      const r = rules[i];
      // Word-wrap to fit panel
      const maxCh = Math.floor(
        (w - 16) / 6
      );
      const lines = this.wordWrap(
        r, maxCh
      );
      for (let li = 0;
        li < lines.length; li++) {
        if (ly > maxY) break;
        ctx.fillText(lines[li], lx, ly);
        ly += lh;
      }
      ly += lh;
    }

    // Banned districts
    const banned = d.banned || [];
    if (banned.length) {
      ly += 4;
      if (ly < maxY) {
        ctx.fillStyle = '#ff6644';
        ctx.fillText('BANNED:', lx, ly);
        ly += lh;
        for (let i = 0;
          i < banned.length; i++) {
          if (ly > maxY) break;
          ctx.fillStyle = '#ff8866';
          ctx.fillText(
            'District ' + banned[i],
            lx, ly
          );
          ly += lh;
        }
      }
    }

    // Stolen passports
    const stolen = d.stolen || [];
    if (stolen.length) {
      ly += 4;
      if (ly < maxY) {
        ctx.fillStyle = '#ff4444';
        ctx.fillText('STOLEN IDs:', lx, ly);
        ly += lh;
        for (let i = 0;
          i < stolen.length; i++) {
          if (ly > maxY) break;
          ctx.fillStyle = '#ff6666';
          ctx.fillText(stolen[i], lx, ly);
          ly += lh;
        }
      }
    }

    // Duplicate passes
    const dupes = d.dupes || [];
    if (dupes.length) {
      ly += 4;
      if (ly < maxY) {
        ctx.fillStyle = '#ff4444';
        ctx.fillText(
          'DUPLICATE PASSES:', lx, ly
        );
        ly += lh;
        for (let i = 0;
          i < dupes.length; i++) {
          if (ly > maxY) break;
          ctx.fillStyle = '#ff6666';
          ctx.fillText(dupes[i], lx, ly);
          ly += lh;
        }
      }
    }
  }

  renderActionBar() {
    const ctx = this.ctx;
    const y = CH - ACT_H;

    ctx.fillStyle = '#111';
    ctx.fillRect(0, y, CW, ACT_H);

    // Approve button
    ctx.fillStyle = CSA;
    ctx.fillRect(20, y + 8, 100, 24);
    ctx.fillStyle = '#fff';
    ctx.font = 'bold 10px monospace';
    ctx.fillText('[A] APPROVE', 28, y + 24);

    // Deny button
    ctx.fillStyle = CSD;
    ctx.fillRect(140, y + 8, 100, 24);
    ctx.fillStyle = '#fff';
    ctx.fillText('[D] DENY', 156, y + 24);

    // Doc nav + reference hint
    ctx.fillStyle = '#555';
    ctx.font = '10px monospace';
    ctx.fillText(
      '[1-5] Docs [<>] Nav',
      280, y + 24
    );
    ctx.fillStyle = this.showRef
      ? CE : '#555';
    ctx.fillText(
      '[TAB] Ref', 440, y + 24
    );
  }

  renderResult() {
    const ctx = this.ctx;
    // Overlay on doc area
    const x = PAN_APP + 20;
    const y = CH / 2 - 30;
    ctx.fillStyle = 'rgba(0,0,0,0.7)';
    ctx.fillRect(x, y, PAN_DOC - 40, 40);
    ctx.fillStyle = this.resultColor;
    ctx.font = 'bold 10px monospace';
    const tw = ctx.measureText(
      this.resultText
    ).width;
    ctx.fillText(
      this.resultText,
      x + (PAN_DOC - 40 - tw) / 2,
      y + 25
    );
  }

  renderDayEnd() {
    const ctx = this.ctx;
    const d = this.days[this.currentDay];

    this.cText(
      'DAY ' + d.day + ' COMPLETE',
      CE, 16, -60
    );
    this.cText(
      'Processed: ' + this.totalProcessed,
      '#aaa', 9, -34
    );
    this.cText(
      'Correct: ' + this.correct
        + '  Mistakes: ' + this.mistakes,
      '#aaa', 9, -20
    );

    const rentStr = '-'
      + this.fmtAhn(DAILY_RENT) + ' rent';
    this.cText(rentStr, '#ff6644', 9, 0);

    if (this.mistakes === 0) {
      this.cText(
        'PERFECT! +'
          + this.fmtAhn(PERFECT_BONUS),
        '#ffcc44', 9, 14
      );
    }

    this.cText(
      'Balance: '
        + this.fmtAhn(this.ahn) + ' Ahn',
      this.ahn >= 0 ? '#ffcc44' : '#ff4444',
      10, 36
    );

    if (this.ahn < 0) {
      this.cText(
        'Press ENTER to continue...',
        '#aaa', 8, 60
      );
    } else if (
      this.currentDay >= this.days.length - 1
    ) {
      this.cText(
        'Press ENTER to continue...',
        '#aaa', 8, 60
      );
    } else {
      this.cText(
        'Press ENTER for next day',
        '#44ff44', 9, 60
      );
    }
  }

  renderGameOver() {
    this.cText(
      'EVICTED', '#ff4444', 20, -30
    );
    this.cText(
      'You can no longer afford rent.',
      '#aaa', 9, 0
    );
    this.cText(
      'Final: ' + this.fmtAhn(this.ahn),
      '#ff6644', 10, 20
    );
    this.cText(
      'Press R to retry',
      '#aaa', 9, 50
    );
  }

  renderWin() {
    this.cText(
      'ALL 7 DAYS SURVIVED!',
      '#ffcc44', 16, -40
    );
    this.cText(
      'You kept your post.',
      '#aaa', 9, -14
    );
    this.cText(
      'Final Balance: '
        + this.fmtAhn(this.ahn) + ' Ahn',
      CE, 12, 10
    );
    this.cText(
      'Press R to play again',
      '#aaa', 9, 40
    );
  }

  renderNameEntry() {
    const ctx = this.ctx;
    this.cText(
      'YOU WIN!', '#ffcc44', 20, -100
    );
    this.cText(
      'Score: '
        + this.fmtAhn(this.ahn) + ' Ahn',
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

  wordWrap(text, maxCh) {
    if (text.length <= maxCh) {
      return [text];
    }
    const words = text.split(' ');
    const lines = [];
    let cur = '';
    for (let i = 0; i < words.length; i++) {
      const w = words[i];
      if (cur.length + w.length + 1
        > maxCh && cur.length > 0) {
        lines.push(cur);
        cur = w;
      } else {
        cur = cur
          ? cur + ' ' + w : w;
      }
    }
    if (cur) lines.push(cur);
    return lines;
  }

  fmtAhn(n) {
    if (n < 0) return '-' + this.fmtAhn(-n);
    if (n >= 1000000) {
      return (n / 1000000).toFixed(1) + 'M';
    }
    if (n >= 1000) {
      return Math.floor(n / 1000) + 'K';
    }
    return String(n);
  }

  handleKeyDown(code) {
    this.keys[code] = true;

    if (this.state === GS_TITLE
      && code === KEY_ENTER) {
      this.ahn = START_AHN;
      this.totalProcessed = 0;
      this.startDay(0);
    }

    if (this.state === GS_REVIEWING) {
      // Toggle reference card
      if (code === KEY_TAB) {
        this.showRef = !this.showRef;
      }
      if (code === KEY_A) {
        this.processVerdict('APPROVE');
      }
      if (code === KEY_D) {
        this.processVerdict('DENY');
      }
      // Doc tabs
      const docs = this.currentApp
        ? this.currentApp.documents : [];
      if (code >= KEY_1
        && code <= KEY_5) {
        const idx = code - KEY_1;
        if (idx < docs.length) {
          this.docIndex = idx;
        }
      }
      if (code === KEY_LEFT) {
        this.docIndex = Math.max(
          0, this.docIndex - 1
        );
      }
      if (code === KEY_RIGHT) {
        this.docIndex = Math.min(
          docs.length - 1,
          this.docIndex + 1
        );
      }
    }

    if (this.state === GS_DAY_END
      && code === KEY_ENTER) {
      if (this.ahn < 0) {
        this.state = GS_GAMEOVER;
        this.act('died');
      } else if (
        this.currentDay
        >= this.days.length - 1
      ) {
        this.entryName = '';
        this.nameDone = false;
        this.state = GS_NAMEENTRY;
      } else {
        this.startDay(this.currentDay + 1);
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
          score: Math.max(0, this.ahn),
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

    if ((this.state === GS_GAMEOVER
      || this.state === GS_WIN)
      && code === KEY_R) {
      this.state = GS_TITLE;
    }
  }

  handleKeyUp(code) {
    this.keys[code] = false;
  }

  handleClick(mx, my) {
    if (this.state !== GS_REVIEWING) return;
    const y = CH - ACT_H;
    if (my < y + 8 || my > y + 32) return;
    // Approve button 20-120
    if (mx >= 20 && mx <= 120) {
      this.processVerdict('APPROVE');
    }
    // Deny button 140-240
    if (mx >= 140 && mx <= 240) {
      this.processVerdict('DENY');
    }
  }
}

// TGUI Component

const ACQUIRED_KEYS = [
  KEY_1, KEY_2, KEY_3, KEY_4, KEY_5,
  KEY_A, KEY_D, KEY_LEFT, KEY_RIGHT,
  KEY_R, KEY_TAB,
];

class ArcadeCheckpointGame extends Component {
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

    this.engine = new CheckpointEngine(
      canvas, this.props.act
    );
    this.engine.highScore
      = this.props.data.leaderboard || [];

    const sd = this.props.data;
    if (sd && sd.days) {
      this.engine.loadData(sd);
    }

    this.engine.start();
    canvas.focus();
  }

  componentDidUpdate(prevProps) {
    if (!this.engine) return;
    const sd = this.props.data;
    if (sd && sd.days
      && sd !== prevProps.data
      && sd.days !== prevProps.data.days) {
      this.engine.loadData(sd);
      this.engine.state = GS_TITLE;
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
        onMouseDown={e => {
          if (!this.engine) return;
          const rect = e.target
            .getBoundingClientRect();
          const mx = e.clientX - rect.left;
          const my = e.clientY - rect.top;
          this.engine.handleClick(mx, my);
        }}
        style={{
          display: 'block',
          outline: 'none',
          cursor: 'default',
          width: '100%',
          height: '100%',
        }}
      />
    );
  }
}

export const ArcadeCheckpoint = (
  props, context
) => {
  const { act, data } = useBackend(context);
  return (
    <Window
      width={CW + 30}
      height={CH + 50}
      resizable>
      <Window.Content>
        <ArcadeCheckpointGame
          act={act}
          data={data}
        />
      </Window.Content>
    </Window>
  );
};
