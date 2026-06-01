/**
 * Hazard-tape overlay for under-construction Refraction Railway lines.
 *
 * Renders a translucent black backdrop with N diagonal yellow-and-black
 * tape strips at random angles, each slowly sliding along its angle and
 * flickering. A centered "UNDER CONSTRUCTION" label sits above the strips.
 *
 * Inline `<style>` block keeps the keyframes self-contained — no scss
 * pipeline change required. Each strip's animation delay + duration is
 * randomized at mount so two adjacent tape overlays don't pulse in sync.
 */
import { Component } from 'inferno';
import { Box } from '../../components';

const TAPE_BASE_ANGLES = [-65, -35, 35, 65];

const stripStyle = (cx, cy, angle, dur, delay, flickerDur, flickerDelay) => ({
  'position': 'absolute',
  'top': `${cy}%`,
  'left': `${cx}%`,
  'width': '180%',
  'height': '28px',
  'margin-top': '-14px',
  'margin-left': '-90%',
  'transform-origin': '50% 50%',
  'transform': `rotate(${angle}deg)`,
  'background': 'repeating-linear-gradient(90deg,'
    + ' #111 0px,'
    + ' #111 22px,'
    + ' #ffd400 22px,'
    + ' #ffd400 44px)',
  'box-shadow': '0 0 8px rgba(0, 220, 255, 0.45),'
    + ' inset 0 0 0 1px rgba(0, 220, 255, 0.55)',
  'border-top': '1px solid rgba(0, 220, 255, 0.45)',
  'border-bottom': '1px solid rgba(0, 220, 255, 0.45)',
  'animation':
    `tapeSlide ${dur}s linear ${delay}s infinite,`
    + ` tapeFlicker ${flickerDur}s ease-in-out ${flickerDelay}s`
    + ' infinite alternate',
});

const labelStyle = {
  'position': 'absolute',
  'top': '50%',
  'left': '50%',
  'transform': 'translate(-50%, -50%)',
  'font-family': 'Consolas, "Courier New", monospace',
  'font-size': '14px',
  'font-weight': 'bold',
  'letter-spacing': '3px',
  'color': '#fff8d6',
  'text-shadow':
    '0 0 6px rgba(0, 220, 255, 0.9),'
    + ' 0 0 12px rgba(0, 220, 255, 0.55),'
    + ' 0 2px 0 rgba(180, 30, 30, 0.85)',
  'pointer-events': 'none',
  'white-space': 'nowrap',
};

const backdropStyle = {
  'position': 'absolute',
  'top': 0,
  'left': 0,
  'right': 0,
  'bottom': 0,
  'overflow': 'hidden',
  'background-color': 'rgba(8, 6, 0, 0.45)',
  'pointer-events': 'none',
  'z-index': 30,
};

const tapeKeyframesCss = `
@keyframes tapeSlide {
  from { background-position: 0 0; }
  to   { background-position: 220px 0; }
}
@keyframes tapeFlicker {
  0%   { opacity: 0.94; }
  100% { opacity: 1; }
}
`;

export class HazardTape extends Component {
  constructor(props) {
    super(props);
    const count = props.count || 4;
    const strips = [];
    for (let i = 0; i < count; i++) {
      const base = TAPE_BASE_ANGLES[i % TAPE_BASE_ANGLES.length];
      strips.push({
        // Spread each strip's center across the container so they
        // cross at varied points instead of radiating from 50/50.
        cx: 20 + Math.random() * 60,
        cy: 20 + Math.random() * 60,
        angle: base + (Math.random() * 20 - 10),
        dur: 18 + Math.random() * 12,
        delay: -Math.random() * 18,
        flickerDur: 0.25 + Math.random() * 0.15,
        flickerDelay: -Math.random() * 0.3,
      });
    }
    this.strips = strips;
  }

  render() {
    const { label = 'UNDER CONSTRUCTION' } = this.props;
    return (
      <Box style={backdropStyle}>
        <style>{tapeKeyframesCss}</style>
        {this.strips.map((s, i) => (
          <div
            key={i}
            style={stripStyle(
              s.cx, s.cy, s.angle,
              s.dur, s.delay, s.flickerDur, s.flickerDelay)}
          />
        ))}
        <div style={labelStyle}>{label}</div>
      </Box>
    );
  }
}
