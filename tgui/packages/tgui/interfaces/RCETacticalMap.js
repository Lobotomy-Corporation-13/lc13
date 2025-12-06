import { Component, createRef } from 'inferno';
import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Section,
  Stack,
  Input,
  Collapsible,
  LabeledList,
} from '../components';
import { Window } from '../layouts';

// Drawing tool constants
const TOOL_POINTER = 'pointer';
const TOOL_PENCIL = 'pencil';
const TOOL_LINE = 'line';
const TOOL_RECT = 'rect';
const TOOL_CIRCLE = 'circle';
const TOOL_TEXT = 'text';
const TOOL_ICON = 'icon';
const TOOL_ERASER = 'eraser';

// Preset colors
const PRESET_COLORS = [
  { name: 'Red', hex: '#ff4444' },
  { name: 'Blue', hex: '#4488ff' },
  { name: 'Green', hex: '#44ff44' },
  { name: 'Yellow', hex: '#ffff44' },
  { name: 'White', hex: '#ffffff' },
  { name: 'Orange', hex: '#ff8844' },
  { name: 'Purple', hex: '#aa44ff' },
  { name: 'Cyan', hex: '#44ffff' },
];

// Tactical icons
const TACTICAL_ICONS = [
  { id: 'target', label: '⊕', desc: 'Target' },
  { id: 'warning', label: '⚠', desc: 'Warning' },
  { id: 'rally', label: '★', desc: 'Rally Point' },
  { id: 'danger', label: '☠', desc: 'Danger' },
  { id: 'safe', label: '♥', desc: 'Safe Zone' },
  { id: 'arrow_n', label: '↑', desc: 'North' },
  { id: 'arrow_s', label: '↓', desc: 'South' },
  { id: 'arrow_e', label: '→', desc: 'East' },
  { id: 'arrow_w', label: '←', desc: 'West' },
];

// Canvas component for drawing
class TacticalCanvas extends Component {
  constructor(props) {
    super(props);
    this.canvasRef = createRef();
    this.state = {
      isDrawing: false,
      startX: 0,
      startY: 0,
      currentPoints: [],
    };
    // Bind methods
    this.handleMouseDown = this.handleMouseDown.bind(this);
    this.handleMouseMove = this.handleMouseMove.bind(this);
    this.handleMouseUp = this.handleMouseUp.bind(this);
    this.handleClick = this.handleClick.bind(this);
  }

  componentDidMount() {
    this.drawCanvas();
  }

  componentDidUpdate(prevProps) {
    if (
      prevProps.annotations !== this.props.annotations
      || prevProps.mapGrid !== this.props.mapGrid
    ) {
      this.drawCanvas();
    }
  }

  drawCanvas() {
    const canvas = this.canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    const { mapGrid, annotations, canvasWidth, canvasHeight } = this.props;

    // Clear canvas
    ctx.fillStyle = '#111111';
    ctx.fillRect(0, 0, canvasWidth, canvasHeight);

    // Draw map background
    if (mapGrid && mapGrid.length > 0) {
      const gridWidth = mapGrid.length;
      const gridHeight = mapGrid[0] ? mapGrid[0].length : 0;
      const cellWidth = canvasWidth / gridWidth;
      const cellHeight = canvasHeight / gridHeight;

      for (let x = 0; x < gridWidth; x++) {
        for (let y = 0; y < gridHeight; y++) {
          const color = mapGrid[x][gridHeight - 1 - y]; // Flip Y
          if (color && color !== '#000000') {
            ctx.fillStyle = color;
            ctx.fillRect(
              x * cellWidth,
              y * cellHeight,
              cellWidth + 1,
              cellHeight + 1
            );
          }
        }
      }
    }

    // Draw annotations
    if (annotations) {
      for (let i = 0; i < annotations.length; i++) {
        this.drawAnnotation(ctx, annotations[i]);
      }
    }

    // Draw current drawing preview
    if (this.state.isDrawing) {
      this.drawPreview(ctx);
    }
  }

  drawAnnotation(ctx, annotation) {
    const { canvasWidth, canvasHeight, mapWidth, mapHeight } = this.props;
    const scaleX = canvasWidth / (mapWidth || 1);
    const scaleY = canvasHeight / (mapHeight || 1);

    ctx.strokeStyle = annotation.color || '#ffffff';
    ctx.fillStyle = annotation.color || '#ffffff';
    ctx.lineWidth = 2;

    const x1 = (annotation.x1 || 0) * scaleX;
    const y1 = canvasHeight - (annotation.y1 || 0) * scaleY;
    const x2 = (annotation.x2 || 0) * scaleX;
    const y2 = canvasHeight - (annotation.y2 || 0) * scaleY;

    switch (annotation.type) {
      case 'point':
        ctx.beginPath();
        ctx.arc(x1, y1, 4, 0, Math.PI * 2);
        ctx.fill();
        break;

      case 'line':
        ctx.beginPath();
        ctx.moveTo(x1, y1);
        ctx.lineTo(x2, y2);
        ctx.stroke();
        break;

      case 'rect':
        ctx.strokeRect(x1, y1, x2 - x1, y2 - y1);
        break;

      case 'circle': {
        const radius = Math.sqrt(
          Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2)
        );
        ctx.beginPath();
        ctx.arc(x1, y1, radius, 0, Math.PI * 2);
        ctx.stroke();
        break;
      }

      case 'text':
        ctx.font = '14px monospace';
        ctx.fillText(annotation.text || '', x1, y1);
        break;

      case 'icon': {
        const iconData = TACTICAL_ICONS.find(
          i => i.id === annotation.icon
        );
        ctx.font = '20px monospace';
        ctx.fillText(iconData ? iconData.label : '?', x1 - 10, y1 + 7);
        break;
      }

      case 'freeform':
        if (annotation.points && annotation.points.length > 1) {
          ctx.beginPath();
          ctx.moveTo(
            annotation.points[0].x * scaleX,
            canvasHeight - annotation.points[0].y * scaleY
          );
          for (let i = 1; i < annotation.points.length; i++) {
            ctx.lineTo(
              annotation.points[i].x * scaleX,
              canvasHeight - annotation.points[i].y * scaleY
            );
          }
          ctx.stroke();
        }
        break;
    }
  }

  drawPreview(ctx) {
    const {
      selectedTool,
      selectedColor,
      canvasWidth,
      canvasHeight,
      mapWidth,
      mapHeight,
    } = this.props;
    const { currentPoints } = this.state;
    const scaleX = canvasWidth / (mapWidth || 1);
    const scaleY = canvasHeight / (mapHeight || 1);

    ctx.strokeStyle = selectedColor;
    ctx.fillStyle = selectedColor;
    ctx.lineWidth = 2;
    ctx.setLineDash([5, 5]);

    if (selectedTool === TOOL_PENCIL && currentPoints.length > 1) {
      ctx.beginPath();
      ctx.moveTo(
        currentPoints[0].x * scaleX,
        canvasHeight - currentPoints[0].y * scaleY
      );
      for (let i = 1; i < currentPoints.length; i++) {
        ctx.lineTo(
          currentPoints[i].x * scaleX,
          canvasHeight - currentPoints[i].y * scaleY
        );
      }
      ctx.stroke();
    }

    ctx.setLineDash([]);
  }

  getMapCoords(event) {
    const canvas = this.canvasRef.current;
    const rect = canvas.getBoundingClientRect();
    const { canvasWidth, canvasHeight, mapWidth, mapHeight } = this.props;

    const canvasX = event.clientX - rect.left;
    const canvasY = event.clientY - rect.top;

    const mapX = Math.round((canvasX / canvasWidth) * (mapWidth || 1));
    const mapY = Math.round(
      ((canvasHeight - canvasY) / canvasHeight) * (mapHeight || 1)
    );

    return { mapX: mapX, mapY: mapY };
  }

  handleMouseDown(event) {
    const { selectedTool, canEdit } = this.props;
    if (!canEdit) return;
    if (selectedTool === TOOL_POINTER || selectedTool === TOOL_ERASER) return;

    const coords = this.getMapCoords(event);

    this.setState({
      isDrawing: true,
      startX: coords.mapX,
      startY: coords.mapY,
      currentPoints: [{ x: coords.mapX, y: coords.mapY }],
    });
  }

  handleMouseMove(event) {
    const { selectedTool } = this.props;
    if (!this.state.isDrawing) return;

    const coords = this.getMapCoords(event);
    const self = this;

    if (selectedTool === TOOL_PENCIL) {
      this.setState(
        prevState => ({
          currentPoints: prevState.currentPoints.concat([
            { x: coords.mapX, y: coords.mapY },
          ]),
        }),
        () => { self.drawCanvas(); }
      );
    }
  }

  handleMouseUp(event) {
    const {
      selectedTool,
      selectedColor,
      selectedIcon,
      onAddAnnotation,
    } = this.props;
    if (!this.state.isDrawing) return;

    const coords = this.getMapCoords(event);
    const { startX, startY, currentPoints } = this.state;

    let annotationData = null;

    switch (selectedTool) {
      case TOOL_PENCIL:
        if (currentPoints.length > 1) {
          annotationData = {
            type: 'freeform',
            points: currentPoints,
            color: selectedColor,
          };
        }
        break;

      case TOOL_LINE:
        annotationData = {
          type: 'line',
          x1: startX,
          y1: startY,
          x2: coords.mapX,
          y2: coords.mapY,
          color: selectedColor,
        };
        break;

      case TOOL_RECT:
        annotationData = {
          type: 'rect',
          x1: startX,
          y1: startY,
          x2: coords.mapX,
          y2: coords.mapY,
          color: selectedColor,
        };
        break;

      case TOOL_CIRCLE:
        annotationData = {
          type: 'circle',
          x1: startX,
          y1: startY,
          x2: coords.mapX,
          y2: coords.mapY,
          color: selectedColor,
        };
        break;

      case TOOL_ICON:
        annotationData = {
          type: 'icon',
          x1: coords.mapX,
          y1: coords.mapY,
          icon: selectedIcon,
          color: selectedColor,
        };
        break;
    }

    if (annotationData && onAddAnnotation) {
      onAddAnnotation(annotationData);
    }

    this.setState({
      isDrawing: false,
      startX: 0,
      startY: 0,
      currentPoints: [],
    });
  }

  handleClick(event) {
    const {
      selectedTool,
      selectedColor,
      selectedIcon,
      onAddAnnotation,
      onTextPrompt,
      onEraseAt,
      canEdit,
    } = this.props;
    if (!canEdit) return;

    const coords = this.getMapCoords(event);

    if (selectedTool === TOOL_TEXT) {
      if (onTextPrompt) {
        onTextPrompt(coords.mapX, coords.mapY, selectedColor);
      }
    } else if (selectedTool === TOOL_ICON) {
      onAddAnnotation({
        type: 'icon',
        x1: coords.mapX,
        y1: coords.mapY,
        icon: selectedIcon,
        color: selectedColor,
      });
    } else if (selectedTool === TOOL_ERASER) {
      if (onEraseAt) {
        onEraseAt(coords.mapX, coords.mapY);
      }
    }
  }

  render() {
    const { canvasWidth, canvasHeight, canEdit, selectedTool } = this.props;

    let cursor = 'crosshair';
    if (!canEdit) {
      cursor = 'default';
    } else if (selectedTool === TOOL_POINTER) {
      cursor = 'default';
    } else if (selectedTool === TOOL_ERASER) {
      cursor = 'not-allowed';
    }

    return (
      <canvas
        ref={this.canvasRef}
        width={canvasWidth}
        height={canvasHeight}
        style={{
          cursor: cursor,
          border: '1px solid #444',
        }}
        onMouseDown={this.handleMouseDown}
        onMouseMove={this.handleMouseMove}
        onMouseUp={this.handleMouseUp}
        onClick={this.handleClick}
      />
    );
  }
}

// Tool button component
const ToolButton = props => {
  const { label, selected, onClick, tooltip } = props;
  return (
    <Button
      fluid
      selected={selected}
      onClick={onClick}
      tooltip={tooltip}
      style={{ marginBottom: '4px' }}>
      {label}
    </Button>
  );
};

// Color swatch component (using div for proper color display)
const ColorSwatch = props => {
  const { color, selected, onClick, tooltip } = props;
  return (
    <div
      style={{
        display: 'inline-block',
        width: '22px',
        height: '22px',
        margin: '2px',
        background: color,
        border: selected ? '2px solid white' : '1px solid #666',
        cursor: 'pointer',
        borderRadius: '2px',
        boxSizing: 'border-box',
      }}
      onClick={onClick}
      title={tooltip}
    />
  );
};

// Color picker component
const ColorPicker = props => {
  const { selectedColor, onColorSelect } = props;
  return (
    <Box>
      {PRESET_COLORS.map(color => (
        <ColorSwatch
          key={color.hex}
          color={color.hex}
          selected={selectedColor === color.hex}
          onClick={() => onColorSelect(color.hex)}
          tooltip={color.name}
        />
      ))}
    </Box>
  );
};

// Icon picker component
const IconPicker = props => {
  const { selectedIcon, onIconSelect } = props;
  return (
    <Box>
      {TACTICAL_ICONS.map(icon => (
        <Button
          key={icon.id}
          selected={selectedIcon === icon.id}
          onClick={() => onIconSelect(icon.id)}
          tooltip={icon.desc}
          style={{ margin: '2px', fontSize: '16px' }}>
          {icon.label}
        </Button>
      ))}
    </Box>
  );
};

// Get description of annotation for display
const getAnnotationDescription = annotation => {
  switch (annotation.type) {
    case 'freeform': {
      const pointCount = annotation.points ? annotation.points.length : 0;
      return 'Freeform (' + pointCount + ' points)';
    }
    case 'line':
      return 'Line ('
        + Math.round(annotation.x1) + ',' + Math.round(annotation.y1)
        + ' to '
        + Math.round(annotation.x2) + ',' + Math.round(annotation.y2) + ')';
    case 'rect':
      return 'Rectangle ('
        + Math.round(annotation.x1) + ',' + Math.round(annotation.y1)
        + ' to '
        + Math.round(annotation.x2) + ',' + Math.round(annotation.y2) + ')';
    case 'circle': {
      const radius = Math.round(Math.sqrt(
        Math.pow((annotation.x2 || 0) - (annotation.x1 || 0), 2)
        + Math.pow((annotation.y2 || 0) - (annotation.y1 || 0), 2)
      ));
      return 'Circle at ('
        + Math.round(annotation.x1) + ',' + Math.round(annotation.y1)
        + ') r=' + radius;
    }
    case 'text':
      return 'Text: "' + (annotation.text || '') + '"';
    case 'icon': {
      const iconData = TACTICAL_ICONS.find(
        i => i.id === annotation.icon
      );
      return 'Icon: ' + (iconData ? iconData.desc : annotation.icon);
    }
    default:
      return annotation.type;
  }
};

// Annotation list for admin view
const AnnotationList = props => {
  const { annotations, onDelete, isAdmin } = props;

  if (!annotations || annotations.length === 0) {
    return (
      <Box color="label" italic>
        No annotations yet.
      </Box>
    );
  }

  return (
    <Box style={{ maxHeight: '200px', overflowY: 'auto' }}>
      {annotations.map((annotation, index) => (
        <Box
          key={annotation.id || index}
          mb={1}
          p={0.5}
          style={{
            backgroundColor: 'rgba(255,255,255,0.1)',
            borderLeft: '3px solid ' + (annotation.color || '#fff'),
            borderRadius: '2px',
          }}>
          <Stack justify="space-between" align="center">
            <Stack.Item grow>
              <Box fontSize="11px">
                <Box bold>{getAnnotationDescription(annotation)}</Box>
                {annotation.ckey && (
                  <Box color="label">
                    Drawn by: {annotation.ckey}
                  </Box>
                )}
                {!annotation.ckey && annotation.author && (
                  <Box color="label">
                    Author: {annotation.author}
                  </Box>
                )}
              </Box>
            </Stack.Item>
            {isAdmin && onDelete && (
              <Stack.Item>
                <Button
                  icon="times"
                  color="bad"
                  compact
                  onClick={() => onDelete(annotation.id)}
                />
              </Stack.Item>
            )}
          </Stack>
        </Box>
      ))}
    </Box>
  );
};

// Main component
export const RCETacticalMap = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    annotations = [],
    mapGrid,
    mapWidth = 100,
    mapHeight = 100,
    maxAnnotations = 100,
    canEdit = true,
    isAdmin = false,
  } = data;

  const [selectedTool, setSelectedTool] = useLocalState(
    context,
    'selectedTool',
    TOOL_PENCIL
  );
  const [selectedColor, setSelectedColor] = useLocalState(
    context,
    'selectedColor',
    '#ff4444'
  );
  const [selectedIcon, setSelectedIcon] = useLocalState(
    context,
    'selectedIcon',
    'target'
  );
  const [textInput, setTextInput] = useLocalState(context, 'textInput', '');
  const [textPos, setTextPos] = useLocalState(context, 'textPos', null);
  const [showAnnotationList, setShowAnnotationList] = useLocalState(
    context,
    'showAnnotationList',
    false
  );

  const canvasWidth = 480;
  const canvasHeight = 480;

  const handleAddAnnotation = annotationData => {
    act('add_annotation', annotationData);
  };

  const handleTextPrompt = (x, y, color) => {
    setTextPos({ x: x, y: y, color: color });
  };

  const handleTextSubmit = () => {
    if (textInput && textPos) {
      act('add_annotation', {
        type: 'text',
        x1: textPos.x,
        y1: textPos.y,
        text: textInput,
        color: textPos.color,
      });
      setTextInput('');
      setTextPos(null);
    }
  };

  const handleEraseAt = (x, y) => {
    act('erase_at', { x: x, y: y });
  };

  const handleDeleteAnnotation = id => {
    act('delete_annotation', { id: id });
  };

  return (
    <Window
      title="RCE Tactical Map"
      width={700}
      height={620}>
      <Window.Content>
        <Stack fill>
          {/* Tool palette */}
          <Stack.Item basis="100px">
            <Section title="Tools" fill scrollable>
              <ToolButton
                label="Ptr"
                tooltip="Pointer"
                selected={selectedTool === TOOL_POINTER}
                onClick={() => setSelectedTool(TOOL_POINTER)}
              />
              <ToolButton
                label="Pen"
                tooltip="Pencil (Freeform)"
                selected={selectedTool === TOOL_PENCIL}
                onClick={() => setSelectedTool(TOOL_PENCIL)}
              />
              <ToolButton
                label="Line"
                tooltip="Line"
                selected={selectedTool === TOOL_LINE}
                onClick={() => setSelectedTool(TOOL_LINE)}
              />
              <ToolButton
                label="Rect"
                tooltip="Rectangle"
                selected={selectedTool === TOOL_RECT}
                onClick={() => setSelectedTool(TOOL_RECT)}
              />
              <ToolButton
                label="Circ"
                tooltip="Circle"
                selected={selectedTool === TOOL_CIRCLE}
                onClick={() => setSelectedTool(TOOL_CIRCLE)}
              />
              <ToolButton
                label="Text"
                tooltip="Text"
                selected={selectedTool === TOOL_TEXT}
                onClick={() => setSelectedTool(TOOL_TEXT)}
              />
              <ToolButton
                label="Icon"
                tooltip="Icon/Marker"
                selected={selectedTool === TOOL_ICON}
                onClick={() => setSelectedTool(TOOL_ICON)}
              />
              <ToolButton
                label="Erase"
                tooltip="Eraser - Click to delete nearby annotation"
                selected={selectedTool === TOOL_ERASER}
                onClick={() => setSelectedTool(TOOL_ERASER)}
              />

              <Box mt={2}>
                <Box bold mb={1}>Colors</Box>
                <ColorPicker
                  selectedColor={selectedColor}
                  onColorSelect={setSelectedColor}
                />
              </Box>

              {selectedTool === TOOL_ICON && (
                <Box mt={2}>
                  <Box bold mb={1}>Icons</Box>
                  <IconPicker
                    selectedIcon={selectedIcon}
                    onIconSelect={setSelectedIcon}
                  />
                </Box>
              )}
            </Section>
          </Stack.Item>

          {/* Main canvas area */}
          <Stack.Item grow>
            <Section
              title="Tactical Map"
              fill
              buttons={
                canEdit && (
                  <Box>
                    <Button
                      icon="undo"
                      onClick={() => act('undo')}
                      disabled={annotations.length === 0}
                      content="Undo"
                    />
                    <Button.Confirm
                      icon="trash"
                      color="bad"
                      onClick={() => act('clear_all')}
                      disabled={annotations.length === 0}
                      content="Clear All"
                      confirmContent="Confirm?"
                    />
                    <Button
                      icon="list"
                      selected={showAnnotationList}
                      onClick={() => setShowAnnotationList(!showAnnotationList)}
                      tooltip="Show annotation list"
                    />
                  </Box>
                )}>
              <Stack vertical fill>
                <Stack.Item>
                  <Box textAlign="center">
                    <TacticalCanvas
                      mapGrid={mapGrid}
                      mapWidth={mapWidth}
                      mapHeight={mapHeight}
                      annotations={annotations}
                      canvasWidth={canvasWidth}
                      canvasHeight={canvasHeight}
                      selectedTool={selectedTool}
                      selectedColor={selectedColor}
                      selectedIcon={selectedIcon}
                      canEdit={canEdit}
                      onAddAnnotation={handleAddAnnotation}
                      onTextPrompt={handleTextPrompt}
                      onEraseAt={handleEraseAt}
                    />

                    {/* Text input modal */}
                    {textPos && (
                      <Box
                        mt={1}
                        p={1}
                        backgroundColor="rgba(0,0,0,0.8)"
                        style={{ borderRadius: '4px' }}>
                        <Stack>
                          <Stack.Item grow>
                            <Input
                              fluid
                              placeholder="Enter text..."
                              value={textInput}
                              onChange={(e, value) => setTextInput(value)}
                            />
                          </Stack.Item>
                          <Stack.Item>
                            <Button
                              icon="check"
                              color="good"
                              onClick={handleTextSubmit}
                              content="Add"
                            />
                          </Stack.Item>
                          <Stack.Item>
                            <Button
                              icon="times"
                              color="bad"
                              onClick={() => {
                                setTextPos(null);
                                setTextInput('');
                              }}
                              content="Cancel"
                            />
                          </Stack.Item>
                        </Stack>
                      </Box>
                    )}

                    {/* Status bar */}
                    <Box mt={1} color="label" fontSize="11px">
                      Annotations: {annotations.length}/{maxAnnotations}
                      {!canEdit && ' (Read-only)'}
                      {selectedTool === TOOL_ERASER
                        && ' - Click on map to erase nearest annotation'}
                    </Box>
                  </Box>
                </Stack.Item>

                {/* Annotation list panel */}
                {showAnnotationList && (
                  <Stack.Item mt={1}>
                    <Section
                      title="Annotations"
                      scrollable
                      style={{ maxHeight: '150px' }}>
                      <AnnotationList
                        annotations={annotations}
                        onDelete={handleDeleteAnnotation}
                        isAdmin={isAdmin}
                      />
                    </Section>
                  </Stack.Item>
                )}
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
