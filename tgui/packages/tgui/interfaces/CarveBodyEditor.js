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

const MIN_PX = 4;
const MAX_PX = 12;
const TARGET_CANVAS = 640;
const MIN_SECTION = 8;

class CarveCanvas extends Component {
  constructor(props) {
    super(props);
    this.canvasRef = createRef();
    this.imgCache = null;
    this.opaqueSet = null;
    this.painting = false;
    this.paintMode = 'select';
    this.paintedPixels = [];
    this.localSelected = {};
    this.lastPos = null;
  }

  componentDidMount() {
    this.buildOpaqueSet();
    this.syncSelected();
    this.drawCanvas();
  }

  componentDidUpdate(prevProps) {
    if (prevProps.sourceBase64
      !== this.props.sourceBase64) {
      this.imgCache = null;
      this.buildOpaqueSet();
    }
    if (prevProps.selectedPixels
      !== this.props.selectedPixels) {
      this.syncSelected();
    }
    this.drawCanvas();
  }

  buildOpaqueSet() {
    const { opaquePixels } = this.props;
    const s = {};
    if (opaquePixels) {
      for (const p of opaquePixels) {
        s[p.x + ',' + p.y] = true;
      }
    }
    this.opaqueSet = s;
  }

  syncSelected() {
    const { selectedPixels } = this.props;
    const s = {};
    if (selectedPixels) {
      for (const p of selectedPixels) {
        s[p.x + ',' + p.y] = true;
      }
    }
    this.localSelected = s;
  }

  getPxPerCell() {
    const { sourceWidth } = this.props;
    return Math.max(MIN_PX, Math.min(MAX_PX,
      Math.floor(TARGET_CANVAS / sourceWidth)
    ));
  }

  getPixelPos(e) {
    const rect = this.canvasRef.current
      .getBoundingClientRect();
    const ppc = this.getPxPerCell();
    const x = Math.floor(
      (e.clientX - rect.left) / ppc
    );
    const y = Math.floor(
      (e.clientY - rect.top) / ppc
    );
    return { x, y };
  }

  isOpaque(x, y) {
    if (!this.opaqueSet) return false;
    return !!this.opaqueSet[x + ',' + y];
  }

  handleMouseDown(e) {
    const pos = this.getPixelPos(e);
    if (!this.isOpaque(pos.x, pos.y)) return;

    const key = pos.x + ',' + pos.y;
    this.paintMode = this.localSelected[key]
      ? 'deselect' : 'select';
    this.painting = true;
    this.paintedPixels = [];
    this.lastPos = pos;
    this.togglePixel(pos.x, pos.y);
    this.drawCanvas();
  }

  handleMouseMove(e) {
    if (!this.painting) return;
    const pos = this.getPixelPos(e);
    if (this.lastPos) {
      this.paintLine(
        this.lastPos.x, this.lastPos.y,
        pos.x, pos.y
      );
    }
    this.lastPos = pos;
    this.drawCanvas();
  }

  handleMouseUp() {
    if (!this.painting) return;
    this.painting = false;
    this.lastPos = null;
    if (this.paintedPixels.length) {
      const { onToggle } = this.props;
      if (onToggle) {
        onToggle(
          this.paintedPixels,
          this.paintMode
        );
      }
      this.paintedPixels = [];
    }
  }

  handleMouseLeave() {
    if (this.painting) {
      this.handleMouseUp();
    }
  }

  togglePixel(x, y) {
    if (!this.isOpaque(x, y)) return;
    const key = x + ',' + y;
    if (this.paintMode === 'select') {
      if (this.localSelected[key]) return;
      this.localSelected[key] = true;
    } else {
      if (!this.localSelected[key]) return;
      delete this.localSelected[key];
    }
    this.paintedPixels.push({ x, y });
  }

  paintLine(x0, y0, x1, y1) {
    const dx = Math.abs(x1 - x0);
    const dy = -Math.abs(y1 - y0);
    const sx = x0 < x1 ? 1 : -1;
    const sy = y0 < y1 ? 1 : -1;
    let err = dx + dy;
    let x = x0;
    let y = y0;
    while (true) {
      this.togglePixel(x, y);
      if (x === x1 && y === y1) break;
      const e2 = 2 * err;
      if (e2 >= dy) { err += dy; x += sx; }
      if (e2 <= dx) { err += dx; y += sy; }
    }
  }

  loadImage() {
    if (this.imgCache) return this.imgCache;
    const { sourceBase64 } = this.props;
    if (!sourceBase64) return null;
    const img = new Image();
    img.onload = () => {
      this.imgCache = img;
      this.drawCanvas();
    };
    img.src = 'data:image/png;base64,'
      + sourceBase64;
    return null;
  }

  drawCanvas() {
    const canvas = this.canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const { sourceWidth, sourceHeight }
      = this.props;
    const ppc = this.getPxPerCell();
    const cw = sourceWidth * ppc;
    const ch = sourceHeight * ppc;

    ctx.clearRect(0, 0, cw, ch);
    this.drawCheckerboard(ctx, ppc);
    this.drawSprite(ctx, ppc);
    this.drawTransparentOverlay(ctx, ppc);
    this.drawSelection(ctx, ppc);
    this.drawSectionOutlines(ctx, ppc);
  }

  drawCheckerboard(ctx, ppc) {
    const { sourceWidth, sourceHeight }
      = this.props;
    for (let y = 0; y < sourceHeight; y++) {
      for (let x = 0; x < sourceWidth; x++) {
        ctx.fillStyle = (x + y) % 2 === 0
          ? '#2a2a2a' : '#222222';
        ctx.fillRect(
          x * ppc, y * ppc, ppc, ppc
        );
      }
    }
  }

  drawSprite(ctx, ppc) {
    const img = this.loadImage();
    if (!img) return;
    const { sourceWidth, sourceHeight }
      = this.props;
    ctx.imageSmoothingEnabled = false;
    ctx.drawImage(
      img, 0, 0,
      sourceWidth * ppc,
      sourceHeight * ppc
    );
  }

  drawTransparentOverlay(ctx, ppc) {
    const { sourceWidth, sourceHeight }
      = this.props;
    ctx.fillStyle = 'rgba(0, 0, 0, 0.5)';
    for (let y = 0; y < sourceHeight; y++) {
      for (let x = 0; x < sourceWidth; x++) {
        if (!this.isOpaque(x, y)) {
          ctx.fillRect(
            x * ppc, y * ppc, ppc, ppc
          );
        }
      }
    }
  }

  drawSelection(ctx, ppc) {
    ctx.fillStyle = 'rgba(68, 136, 255, 0.35)';
    for (const key in this.localSelected) {
      const [x, y] = key.split(',').map(Number);
      ctx.fillRect(
        x * ppc, y * ppc, ppc, ppc
      );
    }
  }

  drawSectionOutlines(ctx, ppc) {
    const { sections } = this.props;
    if (!sections) return;
    for (const section of sections) {
      const color = section.valid
        ? 'rgba(0, 200, 0, 0.7)'
        : 'rgba(200, 0, 0, 0.7)';
      ctx.strokeStyle = color;
      ctx.lineWidth = 2;
      const pxSet = {};
      for (const p of section.pixels) {
        pxSet[p.x + ',' + p.y] = true;
      }
      for (const p of section.pixels) {
        const px = p.x * ppc;
        const py = p.y * ppc;
        if (!pxSet[(p.x - 1) + ',' + p.y]) {
          ctx.beginPath();
          ctx.moveTo(px, py);
          ctx.lineTo(px, py + ppc);
          ctx.stroke();
        }
        if (!pxSet[(p.x + 1) + ',' + p.y]) {
          ctx.beginPath();
          ctx.moveTo(px + ppc, py);
          ctx.lineTo(px + ppc, py + ppc);
          ctx.stroke();
        }
        if (!pxSet[p.x + ',' + (p.y - 1)]) {
          ctx.beginPath();
          ctx.moveTo(px, py);
          ctx.lineTo(px + ppc, py);
          ctx.stroke();
        }
        if (!pxSet[p.x + ',' + (p.y + 1)]) {
          ctx.beginPath();
          ctx.moveTo(px, py + ppc);
          ctx.lineTo(px + ppc, py + ppc);
          ctx.stroke();
        }
      }
    }
  }

  render() {
    const { sourceWidth, sourceHeight }
      = this.props;
    const ppc = this.getPxPerCell();
    return (
      <canvas
        ref={this.canvasRef}
        width={sourceWidth * ppc}
        height={sourceHeight * ppc}
        tabIndex="0"
        style={{
          cursor: 'crosshair',
          border: '1px solid #555',
          outline: 'none',
        }}
        onMouseDown={e =>
          this.handleMouseDown(e)}
        onMouseMove={e =>
          this.handleMouseMove(e)}
        onMouseUp={() =>
          this.handleMouseUp()}
        onMouseLeave={() =>
          this.handleMouseLeave()}
      />
    );
  }
}

export const CarveBodyEditor = (
  props, context
) => {
  const { act, data } = useBackend(context);
  const {
    selectedPixels = [],
    sections = [],
  } = data;
  const sourceBase64 = data.sourceBase64 || '';
  const sourceWidth = data.sourceWidth || 32;
  const sourceHeight = data.sourceHeight || 32;
  const opaquePixels = data.opaquePixels || [];
  const mobName = data.mobName || 'creature';
  const hasBoth = data.hasBothSprites || false;
  const usingLiving = data.usingLiving || false;

  const ppc = Math.max(MIN_PX, Math.min(MAX_PX,
    Math.floor(TARGET_CANVAS / sourceWidth)
  ));
  const canvasW = sourceWidth * ppc;
  const canvasH = sourceHeight * ppc;

  const validCount = sections.filter(
    s => s.valid
  ).length;
  const totalSelected = selectedPixels.length;

  return (
    <Window
      width={Math.max(canvasW + 230, 500)}
      height={Math.max(canvasH + 50, 400)}
    >
      <Window.Content>
        <Flex>
          <Flex.Item>
            <CarveCanvas
              sourceBase64={sourceBase64}
              sourceWidth={sourceWidth}
              sourceHeight={sourceHeight}
              opaquePixels={opaquePixels}
              selectedPixels={selectedPixels}
              sections={sections}
              onToggle={(pixels, mode) => {
                act('toggle_pixels', {
                  pixels,
                  mode,
                });
              }}
            />
          </Flex.Item>
          <Flex.Item
            width="210px"
            ml={1}
          >
            <Stack vertical fill>
              <Stack.Item>
                <Section title={mobName}>
                  <Box>
                    Size: {sourceWidth}
                    x{sourceHeight}
                  </Box>
                  <Box mt={0.5}>
                    Selected: {totalSelected}
                    {' pixels'}
                  </Box>
                  <Box mt={0.5}>
                    Valid groups: {validCount}
                  </Box>
                  {!!hasBoth && (
                    <Box mt={1}>
                      <Button
                        fluid
                        icon="sync"
                        onClick={() => act(
                          'switch_sprite'
                        )}
                      >
                        {usingLiving
                          ? 'Living'
                          : 'Dead'}
                        {' Sprite'}
                      </Button>
                    </Box>
                  )}
                </Section>
              </Stack.Item>
              <Stack.Item grow>
                <Section
                  title="Sections"
                  fill
                  scrollable
                >
                  {sections.length === 0 && (
                    <Box color="label">
                      Select pixels to
                      create sections.
                    </Box>
                  )}
                  {sections.map((s, i) => (
                    <Box
                      key={i}
                      mb={0.5}
                      color={s.valid
                        ? 'good' : 'bad'}
                    >
                      Group {i + 1}:
                      {' '}{s.size} pixels
                      {s.valid
                        ? '' : ' (need 8+)'}
                    </Box>
                  ))}
                </Section>
              </Stack.Item>
              <Stack.Item>
                <Stack>
                  <Stack.Item grow>
                    <Button
                      fluid
                      onClick={() => act(
                        'clear_selection'
                      )}
                    >
                      Clear
                    </Button>
                  </Stack.Item>
                </Stack>
              </Stack.Item>
              <Stack.Item>
                <Button
                  fluid
                  color="good"
                  disabled={!validCount}
                  textAlign="center"
                  onClick={() => act(
                    'carve_out'
                  )}
                >
                  Carve Out
                  ({validCount} piece
                  {validCount !== 1
                    ? 's' : ''})
                </Button>
              </Stack.Item>
            </Stack>
          </Flex.Item>
        </Flex>
      </Window.Content>
    </Window>
  );
};
