import {
  Component,
  createRef,
} from 'inferno';
import { useBackend } from '../backend';
import {
  Box,
  Button,
  Flex,
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

  getPartAtPos(x, y) {
    const { placedParts } = this.props;
    for (let i = placedParts.length - 1; i >= 0; i--) {
      const p = placedParts[i];
      if (
        x >= p.gridX
        && x < p.gridX + PART_SIZE
        && y >= p.gridY
        && y < p.gridY + PART_SIZE
      ) {
        return p.id;
      }
    }
    return null;
  }

  paintCellAt(cx, cy) {
    // 2x2 brush for visibility
    for (let dx = 0; dx < 2; dx++) {
      for (let dy = 0; dy < 2; dy++) {
        const x = cx + dx;
        const y = cy + dy;
        if (x >= 1 && x <= GRID_SIZE
          && y >= 1 && y <= GRID_SIZE) {
          this.paintedCells[x + ',' + y] = { x, y };
        }
      }
    }
  }

  paintCellsAlongLine(x0, y0, x1, y1) {
    // Bresenham's line algorithm, 2x2 brush at each step
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

    if (this.veinPainting || this.veinErasing) {
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
    } else if (tool === 'place' && selectedPartId) {
      const placeX = pos.x - Math.floor(PART_SIZE / 2);
      const placeY = pos.y - Math.floor(PART_SIZE / 2);
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
    const { partIcons } = this.props;
    const key = partId + '_' + rotation;
    if (this.imageCache[key]) {
      return this.imageCache[key];
    }
    const icons = partIcons[partId];
    if (!icons) return null;
    const base64 = icons[String(rotation || 0)];
    if (!base64) return null;
    const img = new Image();
    img.onload = () => {
      this.imageCache[key] = img;
      this.drawCanvas();
    };
    img.src = base64;
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
    // Solid ground bar at the bottom of the canvas
    const barHeight = PX_PER_CELL;
    const barY = CANVAS_PX - barHeight;
    ctx.fillStyle = '#3a2a1a';
    ctx.fillRect(0, barY, CANVAS_PX, barHeight);
    ctx.strokeStyle = '#5a3a2a';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, barY);
    ctx.lineTo(CANVAS_PX, barY);
    ctx.stroke();
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
      const img = this.loadImage(
        part.id,
        part.rotation
      );
      if (!img) continue;

      const px = part.gridX * PX_PER_CELL;
      const py = part.gridY * PX_PER_CELL;
      const pw = PART_SIZE * PX_PER_CELL;
      const ph = PART_SIZE * PX_PER_CELL;

      ctx.save();
      ctx.drawImage(img, px, py, pw, ph);

      if (part.tint && part.tint !== '#ffffff') {
        ctx.globalCompositeOperation = 'multiply';
        ctx.fillStyle = part.tint;
        ctx.fillRect(px, py, pw, ph);
        ctx.globalCompositeOperation = 'source-over';
      }
      ctx.restore();
    }
  }

  drawSelection(ctx) {
    const { placedParts, selectedPartId } = this.props;
    if (!selectedPartId || !placedParts) return;
    const part = placedParts.find(
      p => p.id === selectedPartId
    );
    if (!part) return;

    ctx.strokeStyle = '#4488ff';
    ctx.lineWidth = 2;
    ctx.setLineDash([4, 4]);
    ctx.strokeRect(
      part.gridX * PX_PER_CELL,
      part.gridY * PX_PER_CELL,
      PART_SIZE * PX_PER_CELL,
      PART_SIZE * PX_PER_CELL
    );
    ctx.setLineDash([]);
  }

  render() {
    return (
      <canvas
        ref={this.canvasRef}
        width={CANVAS_PX}
        height={CANVAS_PX}
        style={{
          cursor: 'crosshair',
          border: '1px solid #555',
        }}
        onMouseDown={e => this.handleMouseDown(e)}
        onMouseMove={e => this.handleMouseMove(e)}
        onMouseUp={e => this.handleMouseUp(e)}
        onMouseLeave={e => this.handleMouseLeave(e)}
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

  const staticData = data;
  const partIcons = staticData.partIcons || {};

  const [
    selectedPartId,
    setSelectedPartId,
  ] = [null, () => {}];

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
