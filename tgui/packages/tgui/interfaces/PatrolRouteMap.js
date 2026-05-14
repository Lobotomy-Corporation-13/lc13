import { Component, createRef } from 'inferno';
import { useBackend } from '../backend';
import {
  Box,
  Section,
} from '../components';
import { Window } from '../layouts';

const MAX_CANVAS = 500;
const WP_COLOR = '#d4a017';
const WP_ACTIVE = '#44ff44';
const LINE_COLOR = '#d4a017';

export const PatrolRouteMap = (
  props,
  context,
) => {
  const { data } = useBackend(context);
  const { statusText = '' } = data;
  return (
    <Window
      title="Patrol Route"
      width={560}
      height={600}>
      <Window.Content scrollable>
        <Section title="Patrol Route Map">
          <Box textAlign="center">
            <PatrolRouteCanvas
              data={data}
            />
          </Box>
          <Box
            mt={1}
            textAlign="center"
            bold
            fontSize="13px">
            {statusText}
          </Box>
        </Section>
      </Window.Content>
    </Window>
  );
};

export class PatrolRouteCanvas
  extends Component {
  constructor(props) {
    super(props);
    this.canvasRef = createRef();
  }

  componentDidMount() {
    this.drawMap();
  }

  componentDidUpdate() {
    this.drawMap();
  }

  drawMap() {
    const canvas
      = this.canvasRef.current;
    if (!canvas) return;
    const ctx
      = canvas.getContext('2d');
    const { data } = this.props;
    const {
      mapGrid,
      gridWidth = 0,
      gridHeight = 0,
      waypoints = [],
      currentWaypoint = 1,
    } = data;
    if (
      !mapGrid
      || !gridWidth
      || !gridHeight
    ) {
      ctx.fillStyle = '#111';
      ctx.fillRect(
        0, 0,
        canvas.width,
        canvas.height,
      );
      return;
    }
    const cellPx = Math.max(
      2,
      Math.floor(
        MAX_CANVAS
          / Math.max(
            gridWidth,
            gridHeight,
          ),
      ),
    );
    const cW = gridWidth * cellPx;
    const cH = gridHeight * cellPx;
    canvas.width = cW;
    canvas.height = cH;
    // Background
    ctx.fillStyle = '#111111';
    ctx.fillRect(0, 0, cW, cH);
    // Draw tiles (color-grouped)
    const groups = {};
    for (let x = 0; x < gridWidth; x++) {
      for (
        let y = 0;
        y < gridHeight;
        y++
      ) {
        const color
          = mapGrid[x][gridHeight - 1 - y];
        if (
          color
          && color !== '#000000'
        ) {
          if (!groups[color]) {
            groups[color] = [];
          }
          groups[color].push({ x, y });
        }
      }
    }
    for (const color in groups) {
      ctx.fillStyle = color;
      const cells = groups[color];
      for (
        let i = 0;
        i < cells.length;
        i++
      ) {
        const c = cells[i];
        ctx.fillRect(
          c.x * cellPx,
          c.y * cellPx,
          cellPx + 1,
          cellPx + 1,
        );
      }
    }
    if (!waypoints.length) return;
    // Convert world-coord waypoints
    // to canvas pixel positions.
    // Grid coords: gx = worldX - offsetX + 1
    const offX = data.offsetX || 0;
    const offY = data.offsetY || 0;
    const wpCoords = [];
    for (
      let i = 0;
      i < waypoints.length;
      i++
    ) {
      const wp = waypoints[i];
      const gx = wp.x - offX;
      const gy = wp.y - offY;
      const px
        = (gx - 1 + 0.5) * cellPx;
      const py
        = cH
        - (gy - 1 + 0.5) * cellPx;
      wpCoords.push({ px, py });
    }
    // Draw connecting lines
    ctx.strokeStyle = LINE_COLOR;
    ctx.lineWidth = 2;
    ctx.setLineDash([6, 4]);
    ctx.beginPath();
    for (
      let i = 0;
      i < wpCoords.length;
      i++
    ) {
      const pt = wpCoords[i];
      if (i === 0) {
        ctx.moveTo(pt.px, pt.py);
      } else {
        ctx.lineTo(pt.px, pt.py);
      }
    }
    ctx.stroke();
    ctx.setLineDash([]);
    // Draw waypoint markers
    const wpR = Math.max(
      6,
      Math.floor(cellPx * 1.5),
    );
    for (
      let i = 0;
      i < wpCoords.length;
      i++
    ) {
      const pt = wpCoords[i];
      const isCurrent
        = i + 1 === currentWaypoint;
      const isDone
        = i + 1 < currentWaypoint;
      ctx.fillStyle = isCurrent
        ? WP_ACTIVE
        : isDone
          ? '#666666'
          : WP_COLOR;
      ctx.beginPath();
      ctx.arc(
        pt.px, pt.py, wpR,
        0, Math.PI * 2,
      );
      ctx.fill();
      // Order number
      ctx.fillStyle = '#000';
      ctx.font
        = 'bold '
        + Math.max(10, wpR)
        + 'px monospace';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(
        String(i + 1),
        pt.px,
        pt.py,
      );
    }
  }

  render() {
    return (
      <canvas
        ref={this.canvasRef}
        width={MAX_CANVAS}
        height={MAX_CANVAS}
        style={{
          border: '1px solid #444',
        }}
      />
    );
  }
}
