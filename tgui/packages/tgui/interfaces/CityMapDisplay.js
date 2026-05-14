import {
  Component,
  createRef,
} from 'inferno';
import {
  useBackend,
  useSharedState,
} from '../backend';
import {
  Box,
  Button,
  Section,
} from '../components';
import { Window } from '../layouts';

const MAX_CANVAS = 500;
const PLAYER_COLOR = '#44ff44';
const PLAYER_RADIUS = 6;
const VOID_COLOR = '#000000';
const WALL_COLOR = '#444444';
// Holomap green tint (matches
// HOLOMAP_HOLOFIER #79ff79)
const HOLO_R = 0x79 / 255;
const HOLO_G = 0xFF / 255;
const HOLO_B = 0x79 / 255;
const SCAN_ALPHA = 0.04;
const SCAN_SPACING = 3;
const DIM_OVERLAY = 'rgba(0,0,0,0.5)';
const FOCUS_COLOR = '#ffff44';
const ZOOM_STEPS = [1, 2, 4];

// Apply holomap green tint by
// multiplying RGB with #79ff79.
const holoTint = function (hex) {
  const r = parseInt(
    hex.slice(1, 3), 16,
  );
  const g = parseInt(
    hex.slice(3, 5), 16,
  );
  const b = parseInt(
    hex.slice(5, 7), 16,
  );
  const nr = Math.floor(r * HOLO_R);
  const ng = Math.floor(g * HOLO_G);
  const nb = Math.floor(b * HOLO_B);
  return (
    '#'
    + nr.toString(16).padStart(2, '0')
    + ng.toString(16).padStart(2, '0')
    + nb.toString(16).padStart(2, '0')
  );
};

export const CityMapDisplay = (
  props,
  context,
) => {
  const { data } = useBackend(context);
  const {
    mapGrid,
    gridWidth = 0,
    gridHeight = 0,
    map_legend = [],
  } = data;
  const [selColor, setSelColor]
    = useSharedState(
      context, 'selColor', '',
    );
  const [zoom, setZoom]
    = useSharedState(
      context, 'zoom', 1,
    );
  const [focusX, setFocusX]
    = useSharedState(
      context, 'focusX', -1,
    );
  const [focusY, setFocusY]
    = useSharedState(
      context, 'focusY', -1,
    );
  const toggleColor = color => {
    setSelColor(
      selColor === color ? '' : color,
    );
  };
  const setFocus = (fx, fy) => {
    setFocusX(fx);
    setFocusY(fy);
  };
  const zoomIn = () => {
    const i = ZOOM_STEPS.indexOf(zoom);
    if (i < ZOOM_STEPS.length - 1) {
      setZoom(ZOOM_STEPS[i + 1]);
    }
  };
  const zoomOut = () => {
    const i = ZOOM_STEPS.indexOf(zoom);
    if (i > 0) {
      setZoom(ZOOM_STEPS[i - 1]);
    }
  };
  const hasFocus = focusX >= 0
    && focusY >= 0;
  const canZoomIn = hasFocus
    && zoom < ZOOM_STEPS[
      ZOOM_STEPS.length - 1
    ];
  const canZoomOut = zoom > 1;
  if (!mapGrid || !gridWidth) {
    return (
      <Window
        title="City Holomap"
        width={400}
        height={300}>
        <Window.Content>
          <Section title="City Holomap">
            <Box color="label" italic>
              Map data not available.
            </Box>
          </Section>
        </Window.Content>
      </Window>
    );
  }
  return (
    <Window
      title="City Holomap"
      width={700}
      height={700}>
      <Window.Content scrollable>
        <Section title="City Holomap">
          <Box
            style={{
              display: 'flex',
              gap: '8px',
            }}>
            <Box
              style={{
                flexShrink: 0,
              }}>
              <CityMapCanvas
                data={data}
                selectedColor={selColor}
                onSelectColor={toggleColor}
                zoomLevel={zoom}
                focusX={focusX}
                focusY={focusY}
                onSetFocus={setFocus}
              />
              <Box
                mt={0.5}
                textAlign="center">
                <Button
                  icon="search-minus"
                  disabled={!canZoomOut}
                  onClick={zoomOut}
                />
                <Box
                  inline
                  mx={1}
                  bold
                  color="label">
                  {zoom + 'x'}
                </Box>
                <Button
                  icon="search-plus"
                  disabled={!canZoomIn}
                  onClick={zoomIn}
                />
              </Box>
            </Box>
            <Box
              style={{
                flexShrink: 0,
                minWidth: '130px',
              }}>
              <MapLegend
                legend={map_legend}
                selectedColor={selColor}
                onSelectColor={toggleColor}
              />
            </Box>
          </Box>
          <HelpGuide />
        </Section>
      </Window.Content>
    </Window>
  );
};

class CityMapCanvas extends Component {
  constructor(props) {
    super(props);
    this.canvasRef = createRef();
    this.handleClick
      = this.handleClick.bind(this);
    this._cellPx = 1;
    this._startX = 0;
    this._startY = 0;
  }

  componentDidMount() {
    this.drawMap();
  }

  componentDidUpdate() {
    this.drawMap();
  }

  handleClick(event) {
    const canvas
      = this.canvasRef.current;
    if (!canvas) return;
    const rect
      = canvas.getBoundingClientRect();
    const cx
      = event.clientX - rect.left;
    const cy
      = event.clientY - rect.top;
    const { data } = this.props;
    const {
      mapGrid,
      gridWidth = 0,
      gridHeight = 0,
    } = data;
    if (!mapGrid || !gridWidth) {
      return;
    }
    const gx = Math.floor(
      cx / this._cellPx,
    ) + this._startX;
    const gy = Math.floor(
      cy / this._cellPx,
    ) + this._startY;
    if (
      gx < 0
      || gx >= gridWidth
      || gy < 0
      || gy >= gridHeight
    ) {
      return;
    }
    const raw = mapGrid[gx][
      gridHeight - 1 - gy
    ];
    // Color selection toggle
    if (
      raw
      && raw !== VOID_COLOR
      && raw !== WALL_COLOR
    ) {
      this.props.onSelectColor(raw);
    } else {
      this.props.onSelectColor('');
    }
    // Focus point (only at zoom 1)
    const {
      zoomLevel,
      onSetFocus,
    } = this.props;
    if (
      zoomLevel === 1
      && onSetFocus
    ) {
      onSetFocus(gx, gy);
    }
  }

  drawMap() {
    const canvas
      = this.canvasRef.current;
    if (!canvas) return;
    const ctx
      = canvas.getContext('2d');
    const {
      data,
      selectedColor,
      zoomLevel = 1,
      focusX = -1,
      focusY = -1,
    } = this.props;
    const {
      mapGrid,
      gridWidth = 0,
      gridHeight = 0,
      offsetX = 0,
      offsetY = 0,
      player_x = 0,
      player_y = 0,
    } = data;
    if (
      !mapGrid
      || !gridWidth
      || !gridHeight
    ) {
      ctx.fillStyle = '#040a04';
      ctx.fillRect(
        0, 0,
        canvas.width,
        canvas.height,
      );
      return;
    }
    // Viewport from zoom level
    const zm = Math.max(1, zoomLevel);
    const basePx = Math.max(
      2,
      Math.floor(
        MAX_CANVAS
          / Math.max(
            gridWidth,
            gridHeight,
          ),
      ),
    );
    let visW = gridWidth;
    let visH = gridHeight;
    let sX = 0;
    let sY = 0;
    let cellPx = basePx;
    if (
      zm > 1
      && focusX >= 0
      && focusY >= 0
    ) {
      visW = Math.ceil(
        gridWidth / zm,
      );
      visH = Math.ceil(
        gridHeight / zm,
      );
      cellPx = Math.max(
        2,
        Math.floor(
          MAX_CANVAS
            / Math.max(visW, visH),
        ),
      );
      sX = Math.max(
        0,
        Math.min(
          focusX
            - Math.floor(visW / 2),
          gridWidth - visW,
        ),
      );
      sY = Math.max(
        0,
        Math.min(
          focusY
            - Math.floor(visH / 2),
          gridHeight - visH,
        ),
      );
    }
    // Store for click handler
    this._cellPx = cellPx;
    this._startX = sX;
    this._startY = sY;
    const cW = visW * cellPx;
    const cH = visH * cellPx;
    canvas.width = cW;
    canvas.height = cH;
    // Dark green background
    ctx.fillStyle = '#040a04';
    ctx.fillRect(0, 0, cW, cH);
    // Draw tiles with holo tint
    const groups = {};
    const tintCache = {};
    const endX = Math.min(
      sX + visW, gridWidth,
    );
    const endY = Math.min(
      sY + visH, gridHeight,
    );
    for (
      let x = sX;
      x < endX;
      x++
    ) {
      for (
        let y = sY;
        y < endY;
        y++
      ) {
        const color
          = mapGrid[x][
            gridHeight - 1 - y
          ];
        if (
          color
          && color !== VOID_COLOR
        ) {
          if (!tintCache[color]) {
            tintCache[color]
              = holoTint(color);
          }
          const tinted
            = tintCache[color];
          if (!groups[tinted]) {
            groups[tinted] = [];
          }
          groups[tinted].push({
            x: x - sX,
            y: y - sY,
            raw: color,
          });
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
    // Dim + re-highlight if selected
    if (selectedColor) {
      ctx.fillStyle = DIM_OVERLAY;
      ctx.fillRect(0, 0, cW, cH);
      const tinted
        = tintCache[selectedColor]
        || holoTint(selectedColor);
      ctx.fillStyle = tinted;
      for (
        const col in groups
      ) {
        const cells = groups[col];
        for (
          let i = 0;
          i < cells.length;
          i++
        ) {
          const c = cells[i];
          if (
            c.raw === selectedColor
          ) {
            ctx.fillRect(
              c.x * cellPx,
              c.y * cellPx,
              cellPx + 1,
              cellPx + 1,
            );
          }
        }
      }
    }
    // Scan lines overlay
    ctx.fillStyle
      = 'rgba(0, 255, 0, '
      + SCAN_ALPHA + ')';
    for (
      let sy = 0;
      sy < cH;
      sy += SCAN_SPACING
    ) {
      ctx.fillRect(0, sy, cW, 1);
    }
    // Focus point crosshair
    if (
      focusX >= 0
      && focusY >= 0
      && zm === 1
    ) {
      const fx
        = (focusX - sX + 0.5)
        * cellPx;
      const fy
        = (focusY - sY + 0.5)
        * cellPx;
      ctx.strokeStyle = FOCUS_COLOR;
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.moveTo(fx - 8, fy);
      ctx.lineTo(fx + 8, fy);
      ctx.moveTo(fx, fy - 8);
      ctx.lineTo(fx, fy + 8);
      ctx.stroke();
    }
    // Player marker
    if (player_x && player_y) {
      const gx
        = player_x - offsetX;
      const gy
        = player_y - offsetY;
      const plx = gx - 1;
      const ply = gridHeight - gy;
      if (
        plx >= sX
        && plx < sX + visW
        && ply >= sY
        && ply < sY + visH
      ) {
        const px
          = (plx - sX + 0.5)
          * cellPx;
        const py
          = (ply - sY + 0.5)
          * cellPx;
        const r = Math.max(
          PLAYER_RADIUS,
          cellPx,
        );
        // Glow
        ctx.shadowColor
          = PLAYER_COLOR;
        ctx.shadowBlur = 8;
        // Outer ring
        ctx.strokeStyle
          = PLAYER_COLOR;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(
          px, py, r + 2,
          0, Math.PI * 2,
        );
        ctx.stroke();
        // Inner dot
        ctx.fillStyle
          = PLAYER_COLOR;
        ctx.beginPath();
        ctx.arc(
          px, py, r * 0.5,
          0, Math.PI * 2,
        );
        ctx.fill();
        ctx.shadowBlur = 0;
      }
    }
  }

  render() {
    return (
      <canvas
        ref={this.canvasRef}
        width={MAX_CANVAS}
        height={MAX_CANVAS}
        style={{
          border:
            '1px solid #2a5a2a',
          boxShadow:
            '0 0 8px #22442244',
          cursor: 'crosshair',
        }}
        onClick={this.handleClick}
      />
    );
  }
}

const MapLegend = props => {
  const {
    legend = [],
    selectedColor = '',
    onSelectColor,
  } = props;
  if (!legend.length) return null;
  const isSel = color =>
    selectedColor === color;
  const selBorder
    = '1px solid #79ff79';
  const selBg
    = 'rgba(121, 255, 121, 0.15)';
  return (
    <Section title="Legend">
      {legend.map(entry => (
        <Box
          key={entry.color}
          mb={0.5}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '4px',
            padding: '2px 4px',
            cursor: 'pointer',
            borderRadius: '2px',
            border:
              isSel(entry.color)
                ? selBorder
                : '1px solid'
                  + ' transparent',
            background:
              isSel(entry.color)
                ? selBg
                : 'transparent',
          }}
          fontSize="11px"
          color="label"
          onClick={() =>
            onSelectColor(entry.color)}>
          <Box
            inline
            style={{
              width: '12px',
              height: '12px',
              background:
                holoTint(entry.color),
              flexShrink: 0,
              border:
                '1px solid #2a5a2a',
            }}
          />
          {entry.name}
        </Box>
      ))}
      <Box
        mt={1}
        mb={0.5}
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '4px',
          padding: '2px 4px',
        }}
        fontSize="11px"
        color="label">
        <Box
          inline
          style={{
            width: '12px',
            height: '12px',
            background:
              holoTint(WALL_COLOR),
            flexShrink: 0,
            border:
              '1px solid #2a5a2a',
          }}
        />
        Walls
      </Box>
      <Box
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '4px',
          padding: '2px 4px',
        }}
        fontSize="11px">
        <Box
          inline
          style={{
            width: '12px',
            height: '12px',
            border:
              '2px solid '
              + PLAYER_COLOR,
            borderRadius: '50%',
            flexShrink: 0,
          }}
        />
        <Box color="label">
          You Are Here
        </Box>
      </Box>
      <Box
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '4px',
          padding: '2px 4px',
        }}
        fontSize="11px">
        <Box
          inline
          style={{
            width: '12px',
            height: '2px',
            background: FOCUS_COLOR,
            flexShrink: 0,
          }}
        />
        <Box color="label">
          Focus Point
        </Box>
      </Box>
    </Section>
  );
};

const HelpGuide = () => (
  <Box
    mt={1}
    pt={0.5}
    style={{
      borderTop:
        '1px solid #2a5a2a',
    }}
    fontSize="11px"
    italic
    color="label">
    <Box bold mb={0.5}>
      Controls
    </Box>
    <Box>
      {'- Click a tile to highlight'}
      {' its area in the legend'}
    </Box>
    <Box>
      {'- Click a legend entry to'}
      {' outline matching tiles'}
    </Box>
    <Box>
      - Click again to deselect
    </Box>
    <Box>
      {'- Set a focus point by'}
      {' clicking the map when'}
      {' fully zoomed out'}
    </Box>
    <Box>
      {'- Use +/- to zoom in/out'}
      {' around the focus point'}
    </Box>
  </Box>
);
