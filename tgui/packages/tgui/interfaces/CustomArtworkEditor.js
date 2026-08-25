import {
  Component,
  createRef,
} from 'inferno';
import { useBackend } from '../backend';
import {
  Box,
  Button,
  Flex,
  ProgressBar,
  Section,
  Stack,
} from '../components';
import { Window } from '../layouts';

const GRID_SIZE = 48;
const PX_PER_CELL = 10;
const CANVAS_PX = GRID_SIZE * PX_PER_CELL;
const PART_SIZE = 32;

const TINTS = [
  { label: 'Normal', color: '#ffffff' },
  { label: 'Bloody', color: '#ff4444' },
  { label: 'Drained', color: '#888888' },
  { label: 'Pale', color: '#ddcccc' },
  { label: 'Necrotic', color: '#445544' },
];

const TOOLS = [
  { id: 'select', label: 'Select' },
  { id: 'place', label: 'Place' },
  { id: 'move', label: 'Move' },
  { id: 'vein', label: 'Draw Vein' },
  { id: 'erase_vein', label: 'Erase Vein' },
];

const ZONE_LABELS = {
  head: 'Head',
  chest: 'Chest',
  l_arm: 'L. Arm',
  r_arm: 'R. Arm',
  l_leg: 'L. Leg',
  r_leg: 'R. Leg',
};

class ArtworkCanvas extends Component {
  constructor(props) {
    super(props);
    this.canvasRef = createRef();
    this.imageCache = {};
    this.dragging = false;
    this.dragPartId = null;
    this.dragOffsetX = 0;
    this.dragOffsetY = 0;
    this.veinPainting = false;
    this.veinErasing = false;
    this.paintedCells = {};
    this.lastCell = null;
  }

  componentDidMount() {
    this.drawCanvas();
  }

  componentDidUpdate() {
    this._veinSet = null;
    this.drawCanvas();
  }

  getGridPos(e) {
    const rect = this.canvasRef.current
      .getBoundingClientRect();
    const x = Math.floor(
      (e.clientX - rect.left) / PX_PER_CELL
    );
    const y = Math.floor(
      (e.clientY - rect.top) / PX_PER_CELL
    );
    return { x, y };
  }

  getCropData(partId, rotation) {
    const key = partId + '_' + (rotation || 0);
    return this.imageCache[key] || null;
  }

  getPartAtPos(x, y) {
    const { placedParts } = this.props;
    for (let i = placedParts.length - 1; i >= 0; i--) {
      const p = placedParts[i];
      const crop = this.getCropData(p.id, p.rotation);
      const ox = crop ? crop.offsetX : 0;
      const oy = crop ? crop.offsetY : 0;
      const w = crop ? crop.width : PART_SIZE;
      const h = crop ? crop.height : PART_SIZE;
      if (
        x >= p.gridX + ox
        && x < p.gridX + ox + w
        && y >= p.gridY + oy
        && y < p.gridY + oy + h
      ) {
        return p.id;
      }
    }
    return null;
  }

  getVeinSet() {
    if (this._veinSet) return this._veinSet;
    const { veinPixels } = this.props;
    const s = {};
    if (veinPixels) {
      for (const p of veinPixels) {
        s[p.x + ',' + p.y] = true;
      }
    }
    this._veinSet = s;
    return s;
  }

  isVeinAt(x, y) {
    const key = x + ',' + y;
    if (this.paintedCells[key]) return true;
    return !!this.getVeinSet()[key];
  }

  countCardinalNeighbors(x, y) {
    let n = 0;
    if (this.isVeinAt(x - 1, y)) n++;
    if (this.isVeinAt(x + 1, y)) n++;
    if (this.isVeinAt(x, y - 1)) n++;
    if (this.isVeinAt(x, y + 1)) n++;
    return n;
  }

  canPlaceVein(x, y) {
    if (x < 1 || x > GRID_SIZE
      || y < 1 || y > GRID_SIZE) {
      return false;
    }
    if (this.isVeinAt(x, y)) return false;
    const dirs = [
      [-1, 0], [1, 0], [0, -1], [0, 1],
    ];
    let myNeighbors = 0;
    for (const [dx, dy] of dirs) {
      if (this.isVeinAt(x + dx, y + dy)) {
        myNeighbors++;
        const nn = this.countCardinalNeighbors(
          x + dx, y + dy
        );
        if (nn >= 2) return false;
      }
    }
    if (myNeighbors > 2) return false;
    return true;
  }

  paintCellAt(cx, cy) {
    if (this.canPlaceVein(cx, cy)) {
      this.paintedCells[cx + ',' + cy] = {
        x: cx,
        y: cy,
      };
    }
  }

  paintCellsAlongLine(x0, y0, x1, y1) {
    // Bresenham's line algorithm
    const dx = Math.abs(x1 - x0);
    const dy = -Math.abs(y1 - y0);
    const sx = x0 < x1 ? 1 : -1;
    const sy = y0 < y1 ? 1 : -1;
    let err = dx + dy;
    let x = x0;
    let y = y0;
    while (true) {
      this.paintCellAt(x, y);
      if (x === x1 && y === y1) break;
      const e2 = 2 * err;
      if (e2 >= dy) { err += dy; x += sx; }
      if (e2 <= dx) { err += dx; y += sy; }
    }
  }

  handleMouseDown(e) {
    const { tool, onSelect } = this.props;
    const pos = this.getGridPos(e);
    const cellX = pos.x + 1;
    const cellY = pos.y + 1;

    if (tool === 'select') {
      const partId = this.getPartAtPos(pos.x, pos.y);
      if (partId && onSelect) {
        onSelect(partId);
      }
    } else if (tool === 'move') {
      const partId = this.getPartAtPos(pos.x, pos.y);
      if (partId) {
        this.dragging = true;
        this.dragPartId = partId;
        const part = this.props.placedParts.find(
          p => p.id === partId
        );
        if (part) {
          this.dragOffsetX = pos.x - part.gridX;
          this.dragOffsetY = pos.y - part.gridY;
        }
      }
    } else if (tool === 'vein') {
      this.veinPainting = true;
      this.paintedCells = {};
      this.lastCell = { x: cellX, y: cellY };
      this.paintCellAt(cellX, cellY);
      this.drawCanvas();
    } else if (tool === 'erase_vein') {
      this.veinErasing = true;
      this.paintedCells = {};
      this.lastCell = { x: cellX, y: cellY };
      this.paintCellAt(cellX, cellY);
      this.drawCanvas();
    }
  }

  handleMouseMove(e) {
    const pos = this.getGridPos(e);
    const cellX = pos.x + 1;
    const cellY = pos.y + 1;

    if (this.dragging) {
      this.dragPreviewX = pos.x - this.dragOffsetX;
      this.dragPreviewY = pos.y - this.dragOffsetY;
      this.drawCanvas();
    } else if (
      this.veinPainting || this.veinErasing
    ) {
      if (!this.lastCell) {
        this.lastCell = { x: cellX, y: cellY };
      }
      this.paintCellsAlongLine(
        this.lastCell.x,
        this.lastCell.y,
        cellX,
        cellY
      );
      this.lastCell = { x: cellX, y: cellY };
      this.drawCanvas();
    }
  }

  handleKeyDown(e) {
    const { onMove, selectedPartId, placedParts }
      = this.props;
    if (!selectedPartId || !onMove) return;
    const part = placedParts.find(
      p => p.id === selectedPartId
    );
    if (!part) return;
    let dx = 0;
    let dy = 0;
    switch (e.key) {
      case 'ArrowUp': dy = -1; break;
      case 'ArrowDown': dy = 1; break;
      case 'ArrowLeft': dx = -1; break;
      case 'ArrowRight': dx = 1; break;
      default: return;
    }
    e.preventDefault();
    onMove(
      selectedPartId,
      part.gridX + dx,
      part.gridY + dy
    );
  }

  handleMouseUp(e) {
    const {
      tool,
      onMove,
      onPlace,
      onPaintVeins,
      onEraseVeins,
      selectedPartId,
    } = this.props;
    const pos = this.getGridPos(e);

    if (tool === 'move' && this.dragging) {
      const newX = pos.x - this.dragOffsetX;
      const newY = pos.y - this.dragOffsetY;
      if (onMove) {
        onMove(this.dragPartId, newX, newY);
      }
      this.dragging = false;
      this.dragPartId = null;
      this.dragPreviewX = undefined;
      this.dragPreviewY = undefined;
    } else if (tool === 'place' && selectedPartId) {
      const { cropData } = this.props;
      const rc = cropData
        && cropData[selectedPartId]
        && cropData[selectedPartId]['0']
        || null;
      const ox = rc ? rc.ox : 0;
      const oy = rc ? rc.oy : 0;
      const cw = rc ? rc.w : PART_SIZE;
      const ch = rc ? rc.h : PART_SIZE;
      const placeX = pos.x
        - Math.floor(cw / 2) - ox;
      const placeY = pos.y
        - Math.floor(ch / 2) - oy;
      if (onPlace) {
        onPlace(selectedPartId, placeX, placeY);
      }
    } else if (this.veinPainting) {
      const cells = Object.values(this.paintedCells);
      if (cells.length && onPaintVeins) {
        onPaintVeins(cells);
      }
      this.veinPainting = false;
      this.paintedCells = {};
      this.lastCell = null;
    } else if (this.veinErasing) {
      const cells = Object.values(this.paintedCells);
      if (cells.length && onEraseVeins) {
        onEraseVeins(cells);
      }
      this.veinErasing = false;
      this.paintedCells = {};
      this.lastCell = null;
    }
  }

  handleMouseLeave(e) {
    // Cancel any in-progress drawing
    if (this.veinPainting || this.veinErasing) {
      this.handleMouseUp(e);
    }
  }

  loadImage(partId, rotation) {
    const { partIcons, cropData } = this.props;
    const key = partId + '_' + rotation;
    if (this.imageCache[key]) {
      return this.imageCache[key];
    }
    const icons = partIcons[partId];
    if (!icons) return null;
    const base64 = icons[String(rotation || 0)];
    if (!base64) return null;
    const rotCrops = cropData
      && cropData[partId] || null;
    const crop = rotCrops
      && rotCrops[String(rotation || 0)]
      || null;
    const img = new Image();
    img.onload = () => {
      this.imageCache[key] = {
        img,
        offsetX: crop ? crop.ox : 0,
        offsetY: crop ? crop.oy : 0,
        width: crop ? crop.w : img.width,
        height: crop ? crop.h : img.height,
      };
      this.drawCanvas();
    };
    img.src = 'data:image/png;base64,' + base64;
    return null;
  }

  drawCanvas() {
    const canvas = this.canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, CANVAS_PX, CANVAS_PX);

    this.drawCheckerboard(ctx);
    if (!this.props.veinsAbove) {
      this.drawVeins(ctx);
    }
    this.drawParts(ctx);
    if (this.props.veinsAbove) {
      this.drawVeins(ctx);
    }
    this.drawSelection(ctx);
    this.drawGroundLine(ctx);
  }

  drawCheckerboard(ctx) {
    const s = PX_PER_CELL;
    for (let x = 0; x < GRID_SIZE; x++) {
      for (let y = 0; y < GRID_SIZE; y++) {
        ctx.fillStyle = (x + y) % 2 === 0
          ? '#2a2a2a' : '#222222';
        ctx.fillRect(x * s, y * s, s, s);
      }
    }
  }

  drawGroundLine(ctx) {
    const s = PX_PER_CELL;
    const dark = '#8b745c';
    const med = '#927d67';
    const light = '#978471';
    // Pedestal at grid (14,36)-(33,39)
    // matches statue.dmi "base" icon
    const bx = 14;
    const by = 36;
    const bw = 20;
    // Row 0: solid dark top edge
    ctx.fillStyle = dark;
    ctx.fillRect(bx * s, by * s, bw * s, s);
    // Row 1: dark edges, alternating pattern
    ctx.fillStyle = dark;
    ctx.fillRect(bx * s, (by + 1) * s, s, s);
    ctx.fillRect((bx + bw - 1) * s,
      (by + 1) * s, s, s);
    for (let i = 1; i < bw - 1; i++) {
      ctx.fillStyle = i % 2 === 0
        ? med : light;
      ctx.fillRect((bx + i) * s,
        (by + 1) * s, s, s);
    }
    // Row 2: inset by 1 on each side
    for (let i = 1; i < bw - 1; i++) {
      ctx.fillStyle = (i % 3 === 0)
        ? light : (i % 3 === 1)
          ? med : dark;
      ctx.fillRect((bx + i) * s,
        (by + 2) * s, s, s);
    }
    // Row 3: full width, mixed pattern
    for (let i = 0; i < bw; i++) {
      ctx.fillStyle = (i % 3 === 0)
        ? dark : (i % 3 === 1)
          ? med : light;
      ctx.fillRect((bx + i) * s,
        (by + 3) * s, s, s);
    }
  }

  drawVeins(ctx) {
    const { veinPixels } = this.props;
    const paintedLive = this.paintedCells || {};
    const paintedSet = {};

    if (veinPixels && veinPixels.length) {
      for (const p of veinPixels) {
        paintedSet[p.x + ',' + p.y] = true;
      }
    }

    // Apply live painted cells to preview
    if (this.veinPainting) {
      for (const key in paintedLive) {
        paintedSet[key] = true;
      }
    } else if (this.veinErasing) {
      for (const key in paintedLive) {
        delete paintedSet[key];
      }
    }

    ctx.fillStyle = '#8b0000';
    for (const key in paintedSet) {
      const [cx, cy] = key.split(',').map(Number);
      ctx.fillRect(
        (cx - 1) * PX_PER_CELL,
        (cy - 1) * PX_PER_CELL,
        PX_PER_CELL,
        PX_PER_CELL
      );
    }
  }

  drawParts(ctx) {
    const { placedParts } = this.props;
    if (!placedParts) return;

    ctx.imageSmoothingEnabled = false;
    for (const part of placedParts) {
      const crop = this.loadImage(
        part.id,
        part.rotation
      );
      if (!crop) continue;

      const { img, offsetX, offsetY, width, height }
        = crop;
      let gx = part.gridX;
      let gy = part.gridY;
      if (this.dragging
        && this.dragPartId === part.id
        && this.dragPreviewX !== undefined) {
        gx = this.dragPreviewX;
        gy = this.dragPreviewY;
      }
      const px = (gx + offsetX) * PX_PER_CELL;
      const py = (gy + offsetY) * PX_PER_CELL;
      const pw = width * PX_PER_CELL;
      const ph = height * PX_PER_CELL;

      if (part.tint && part.tint !== '#ffffff') {
        const tc = document.createElement('canvas');
        tc.width = pw;
        tc.height = ph;
        const tx = tc.getContext('2d');
        tx.imageSmoothingEnabled = false;
        tx.drawImage(
          img,
          offsetX, offsetY, width, height,
          0, 0, pw, ph
        );
        tx.globalCompositeOperation = 'multiply';
        tx.fillStyle = part.tint;
        tx.fillRect(0, 0, pw, ph);
        tx.globalCompositeOperation
          = 'destination-in';
        tx.drawImage(
          img,
          offsetX, offsetY, width, height,
          0, 0, pw, ph
        );
        ctx.drawImage(tc, px, py);
      } else {
        ctx.drawImage(
          img,
          offsetX, offsetY, width, height,
          px, py, pw, ph
        );
      }
    }
  }

  drawSelection(ctx) {
    const { placedParts, selectedPartId } = this.props;
    if (!selectedPartId || !placedParts) return;
    const part = placedParts.find(
      p => p.id === selectedPartId
    );
    if (!part) return;

    const crop = this.getCropData(
      part.id, part.rotation
    );
    const ox = crop ? crop.offsetX : 0;
    const oy = crop ? crop.offsetY : 0;
    const w = crop ? crop.width : PART_SIZE;
    const h = crop ? crop.height : PART_SIZE;

    let gx = part.gridX;
    let gy = part.gridY;
    if (this.dragging
      && this.dragPartId === part.id
      && this.dragPreviewX !== undefined) {
      gx = this.dragPreviewX;
      gy = this.dragPreviewY;
    }

    ctx.strokeStyle = '#4488ff';
    ctx.lineWidth = 2;
    ctx.setLineDash([4, 4]);
    ctx.strokeRect(
      (gx + ox) * PX_PER_CELL,
      (gy + oy) * PX_PER_CELL,
      w * PX_PER_CELL,
      h * PX_PER_CELL
    );
    ctx.setLineDash([]);
  }

  render() {
    return (
      <canvas
        ref={this.canvasRef}
        width={CANVAS_PX}
        height={CANVAS_PX}
        tabIndex="0"
        style={{
          cursor: 'crosshair',
          border: '1px solid #555',
          outline: 'none',
        }}
        onMouseDown={e => {
          this.handleMouseDown(e);
          this.canvasRef.current.focus();
        }}
        onMouseMove={e =>
          this.handleMouseMove(e)}
        onMouseUp={e =>
          this.handleMouseUp(e)}
        onMouseLeave={e =>
          this.handleMouseLeave(e)}
        onKeyDown={e =>
          this.handleKeyDown(e)}
      />
    );
  }
}

export const CustomArtworkEditor = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    storedParts = [],
    placedParts = [],
    veinPixels = [],
    veinsAbove,
  } = data;

  const partIcons = data.partIcons || {};
  const cropData = data.cropData || {};

  return (
    <Window width={790} height={640}>
      <Window.Content>
        <CustomArtworkEditorInner
          act={act}
          storedParts={storedParts}
          placedParts={placedParts}
          veinPixels={veinPixels}
          veinsAbove={veinsAbove}
          partIcons={partIcons}
          cropData={cropData}
          storedBlood={data.storedBlood || 0}
          bloodCost={data.bloodCost || 0}
          bloodRefund={data.bloodRefund || 0}
        />
      </Window.Content>
    </Window>
  );
};

class CustomArtworkEditorInner extends Component {
  constructor(props) {
    super(props);
    this.state = {
      tool: 'select',
      selectedPartId: null,
    };
  }

  render() {
    const {
      act,
      storedParts,
      placedParts,
      veinPixels,
      veinsAbove,
      partIcons,
      cropData,
      storedBlood,
      bloodCost,
      bloodRefund,
    } = this.props;
    const { tool, selectedPartId } = this.state;

    const selectedPlaced = placedParts.find(
      p => p.id === selectedPartId
    );

    return (
      <Flex>
        <Flex.Item>
          <ArtworkCanvas
            placedParts={placedParts}
            veinPixels={veinPixels}
            veinsAbove={veinsAbove}
            partIcons={partIcons}
            cropData={cropData}
            tool={tool}
            selectedPartId={selectedPartId}
            onSelect={id => {
              this.setState({
                selectedPartId: id,
              });
            }}
            onPlace={(id, x, y) => {
              act('place_part', { id, x, y });
            }}
            onMove={(id, x, y) => {
              act('move_part', { id, x, y });
            }}
            onPaintVeins={cells => {
              act('paint_veins', { cells });
            }}
            onEraseVeins={cells => {
              act('erase_veins', { cells });
            }}
          />
        </Flex.Item>
        <Flex.Item width="240px" ml={1}>
          <Stack vertical fill>
            <Stack.Item>
              <Section title="Tools">
                <Stack wrap>
                  {TOOLS.map(t => (
                    <Stack.Item
                      key={t.id}
                      mb={0.5}
                      mr={0.5}
                    >
                      <Button
                        selected={tool === t.id}
                        onClick={() => {
                          this.setState({
                            tool: t.id,
                          });
                        }}
                      >
                        {t.label}
                      </Button>
                    </Stack.Item>
                  ))}
                </Stack>
              </Section>
            </Stack.Item>
            <Stack.Item grow>
              <Section
                title="Body Parts"
                fill
                scrollable
              >
                {storedParts.map(part => (
                  <Button
                    key={part.id}
                    fluid
                    selected={
                      selectedPartId === part.id
                    }
                    color={part.placed
                      ? 'green' : 'default'}
                    onClick={() => {
                      this.setState({
                        selectedPartId: part.id,
                      });
                    }}
                  >
                    {ZONE_LABELS[part.bodyZone]
                      || part.bodyZone}
                    {part.placed ? ' (placed)' : ''}
                  </Button>
                ))}
              </Section>
            </Stack.Item>
            {!!selectedPlaced && (
              <Stack.Item>
                <Section title="Selected Part">
                  <Box mb={1}>
                    Rotation: {selectedPlaced.rotation}
                    &deg;
                  </Box>
                  <Stack wrap>
                    <Stack.Item mr={0.5} mb={0.5}>
                      <Button
                        onClick={() => act(
                          'rotate_part',
                          { id: selectedPartId }
                        )}
                      >
                        Rotate
                      </Button>
                    </Stack.Item>
                    <Stack.Item mr={0.5} mb={0.5}>
                      <Button
                        color="bad"
                        onClick={() => act(
                          'remove_part',
                          { id: selectedPartId }
                        )}
                      >
                        Remove
                      </Button>
                    </Stack.Item>
                  </Stack>
                  <Box mt={1}>Tint:</Box>
                  <Stack wrap>
                    {TINTS.map(t => (
                      <Stack.Item
                        key={t.color}
                        mr={0.5}
                        mb={0.5}
                      >
                        <Button
                          selected={
                            selectedPlaced.tint
                              === t.color
                          }
                          onClick={() => act(
                            'set_tint',
                            {
                              id: selectedPartId,
                              tint: t.color,
                            }
                          )}
                        >
                          <Box
                            inline
                            width="12px"
                            height="12px"
                            style={{
                              backgroundColor:
                                t.color,
                              border:
                                '1px solid #888',
                              verticalAlign:
                                'middle',
                              marginRight: '4px',
                            }}
                          />
                          {t.label}
                        </Button>
                      </Stack.Item>
                    ))}
                  </Stack>
                </Section>
              </Stack.Item>
            )}
            <Stack.Item>
              <Section title="Veins">
                <Box mb={0.5}>
                  <ProgressBar
                    value={storedBlood}
                    maxValue={500}
                    color="red"
                  >
                    {storedBlood
                      + 'u / 500u Blood'}
                  </ProgressBar>
                </Box>
                {!!bloodCost && (
                  <Box mb={0.5} color="bad">
                    Cost: {bloodCost}u
                  </Box>
                )}
                {!!bloodRefund && (
                  <Box mb={0.5} color="good">
                    Refund: {bloodRefund}u
                  </Box>
                )}
                <Stack>
                  <Stack.Item mr={0.5}>
                    <Button
                      onClick={() => act(
                        'toggle_veins_layer'
                      )}
                    >
                      {veinsAbove
                        ? 'Above Parts'
                        : 'Behind Parts'}
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      color="bad"
                      onClick={() => act(
                        'clear_veins'
                      )}
                    >
                      Clear All
                    </Button>
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>
            <Stack.Item>
              <Button
                fluid
                color="good"
                textAlign="center"
                onClick={() => act('submit')}
              >
                Submit Artwork
              </Button>
            </Stack.Item>
          </Stack>
        </Flex.Item>
      </Flex>
    );
  }
}
