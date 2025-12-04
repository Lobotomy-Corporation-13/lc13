import { Component, createRef } from 'inferno';
import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Stack, Input } from '../components';
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
// Uses 3-layer system for performance:
// 1. Background canvas - map grid (drawn once)
// 2. Annotations canvas - existing shapes (updated when annotations change)
// 3. Preview canvas - current drawing (updated during active drawing)
class TacticalCanvas extends Component {
  constructor(props) {
    super(props);
    this.backgroundCanvasRef = createRef();
    this.annotationsCanvasRef = createRef();
    this.previewCanvasRef = createRef();
    this.state = {
      isDrawing: false,
      startX: 0,
      startY: 0,
      currentPoints: [],
      mapGridDrawn: false,
    };
    // Bind methods
    this.handleMouseDown = this.handleMouseDown.bind(this);
    this.handleMouseMove = this.handleMouseMove.bind(this);
    this.handleMouseUp = this.handleMouseUp.bind(this);
    this.handleClick = this.handleClick.bind(this);
    // Throttle mouse move to 30Hz (33ms)
    this.throttledMouseMove = this.throttle(this.handleMouseMove.bind(this), 33);
  }

  // Simple throttle implementation
  throttle(func, delay) {
    let lastCall = 0;
    return function(...args) {
      const now = Date.now();
      if (now - lastCall >= delay) {
        lastCall = now;
        return func(...args);
      }
    };
  }

  componentDidMount() {
    this.drawMapGrid();
    this.drawAnnotations();
  }

  componentDidUpdate(prevProps) {
    // Only redraw map grid if it changed (rare)
    if (prevProps.mapGrid !== this.props.mapGrid) {
      this.drawMapGrid();
    }
    // Only redraw annotations if they changed
    if (prevProps.annotations !== this.props.annotations) {
      this.drawAnnotations();
    }
  }

  // Draw map background layer (only once or when map changes)
  drawMapGrid() {
    const canvas = this.backgroundCanvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    const { mapGrid, canvasWidth, canvasHeight } = this.props;

    // Clear canvas
    ctx.fillStyle = '#111111';
    ctx.fillRect(0, 0, canvasWidth, canvasHeight);

    // Draw map background with optimized rendering
    if (mapGrid && mapGrid.length > 0) {
      const gridWidth = mapGrid.length;
      const gridHeight = mapGrid[0] ? mapGrid[0].length : 0;
      const cellWidth = canvasWidth / gridWidth;
      const cellHeight = canvasHeight / gridHeight;

      // Group cells by color to minimize fillStyle changes
      const colorGroups = {};
      for (let x = 0; x < gridWidth; x++) {
        for (let y = 0; y < gridHeight; y++) {
          const color = mapGrid[x][gridHeight - 1 - y]; // Flip Y
          if (color && color !== '#000000') {
            if (!colorGroups[color]) {
              colorGroups[color] = [];
            }
            colorGroups[color].push({ x, y });
          }
        }
      }

      // Draw each color group in batch
      for (const color in colorGroups) {
        ctx.fillStyle = color;
        const cells = colorGroups[color];
        for (let i = 0; i < cells.length; i++) {
          const cell = cells[i];
          ctx.fillRect(
            cell.x * cellWidth,
            cell.y * cellHeight,
            cellWidth + 1,
            cellHeight + 1
          );
        }
      }
    }

    this.setState({ mapGridDrawn: true });
  }

  // Draw annotations layer (when annotations change)
  drawAnnotations() {
    const canvas = this.annotationsCanvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    const { annotations, canvasWidth, canvasHeight } = this.props;

    // Clear canvas
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);

    // Draw annotations
    if (annotations) {
      for (let i = 0; i < annotations.length; i++) {
        this.drawAnnotation(ctx, annotations[i]);
      }
    }
  }

  // Draw preview layer (during active drawing)
  drawPreview() {
    const canvas = this.previewCanvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    const { canvasWidth, canvasHeight } = this.props;

    // Clear canvas
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);

    // Draw current drawing preview
    if (this.state.isDrawing) {
      this.drawPreviewShape(ctx);
    }
  }

  drawAnnotation(ctx, annotation) {
    const { canvasWidth, canvasHeight, mapWidth, mapHeight } = this.props;
    const scaleX = canvasWidth / (mapWidth || 1);
    const scaleY = canvasHeight / (mapHeight || 1);

    ctx.strokeStyle = annotation.color || '#ffffff';
    ctx.fillStyle = annotation.color || '#ffffff';
    ctx.lineWidth = 2;

    // Visual distinction for pending (draft) annotations
    if (annotation.pending) {
      ctx.globalAlpha = 0.6; // Semi-transparent
      ctx.setLineDash([5, 3]); // Dashed lines
    } else {
      ctx.globalAlpha = 1.0;
      ctx.setLineDash([]);
    }

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
        const dx = x2 - x1;
        const dy = y2 - y1;
        const radius = Math.sqrt(dx * dx + dy * dy);
        ctx.beginPath();
        ctx.arc(x1, y1, radius, 0, Math.PI * 2);
        ctx.stroke();
        break;
      }

      case 'text': {
        const textSize = annotation.fontSize || 14;
        ctx.font = textSize + 'px monospace';
        ctx.fillText(annotation.text || '', x1, y1);
        break;
      }

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

    // Reset canvas state after drawing
    ctx.globalAlpha = 1.0;
    ctx.setLineDash([]);
  }

  drawPreviewShape(ctx) {
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
    // Use preview canvas for coordinate calculation (top layer)
    const canvas = this.previewCanvasRef.current;
    if (!canvas) return { mapX: 0, mapY: 0 };

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

    if (selectedTool === TOOL_PENCIL) {
      // Batch point updates - add point to array
      this.setState(
        prevState => ({
          currentPoints: prevState.currentPoints.concat([
            { x: coords.mapX, y: coords.mapY },
          ]),
        }),
        () => {
          // Only redraw preview layer (not entire canvas)
          this.drawPreview();
        }
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
    }, () => {
      // Clear preview canvas after drawing completes
      this.drawPreview();
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

    const canvasStyle = {
      position: 'absolute',
      top: 0,
      left: 0,
    };

    return (
      <div
        style={{
          position: 'relative',
          width: canvasWidth + 'px',
          height: canvasHeight + 'px',
          border: '1px solid #444',
        }}>
        {/* Layer 1: Background (map grid) - bottom layer */}
        <canvas
          ref={this.backgroundCanvasRef}
          width={canvasWidth}
          height={canvasHeight}
          style={canvasStyle}
        />
        {/* Layer 2: Annotations - middle layer */}
        <canvas
          ref={this.annotationsCanvasRef}
          width={canvasWidth}
          height={canvasHeight}
          style={canvasStyle}
        />
        {/* Layer 3: Preview (current drawing) - top layer with interactions */}
        <canvas
          ref={this.previewCanvasRef}
          width={canvasWidth}
          height={canvasHeight}
          style={{
            ...canvasStyle,
            cursor: cursor,
          }}
          onMouseDown={this.handleMouseDown}
          onMouseMove={this.throttledMouseMove}
          onMouseUp={this.handleMouseUp}
          onClick={this.handleClick}
        />
      </div>
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
      return 'Line (' + Math.round(annotation.x1) + ','
        + Math.round(annotation.y1) + ' to '
        + Math.round(annotation.x2) + ',' + Math.round(annotation.y2) + ')';
    case 'rect':
      return 'Rectangle (' + Math.round(annotation.x1) + ','
        + Math.round(annotation.y1) + ' to '
        + Math.round(annotation.x2) + ',' + Math.round(annotation.y2) + ')';
    case 'circle': {
      const radius = Math.round(Math.sqrt(
        Math.pow((annotation.x2 || 0) - (annotation.x1 || 0), 2)
        + Math.pow((annotation.y2 || 0) - (annotation.y1 || 0), 2)
      ));
      return 'Circle at (' + Math.round(annotation.x1) + ','
        + Math.round(annotation.y1) + ') r=' + radius;
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
            backgroundColor: annotation.pending
              ? 'rgba(255,200,0,0.15)' // Yellow tint for drafts
              : 'rgba(255,255,255,0.1)',
            borderLeft: '3px solid ' + (annotation.color || '#fff'),
            borderRadius: '2px',
            opacity: annotation.pending ? 0.8 : 1,
          }}>
          <Stack justify="space-between" align="center">
            <Stack.Item grow>
              <Box fontSize="11px">
                <Box bold>
                  {getAnnotationDescription(annotation)}
                  {annotation.pending && (
                    <Box inline color="yellow" ml={1}>(DRAFT)</Box>
                  )}
                </Box>
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
            {onDelete && (annotation.pending || isAdmin) && (
              <Stack.Item>
                <Button
                  icon="times"
                  color="bad"
                  compact
                  onClick={() => onDelete(annotation.id)}
                  tooltip={annotation.pending ? "Remove draft" : "Delete annotation"}
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
export const FacilityTacticalMap = (props, context) => {
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
    context, 'selectedTool', TOOL_PENCIL
  );
  const [selectedColor, setSelectedColor] = useLocalState(
    context, 'selectedColor', '#ff4444'
  );
  const [selectedIcon, setSelectedIcon] = useLocalState(
    context, 'selectedIcon', 'target'
  );
  const [textInput, setTextInput] = useLocalState(
    context, 'textInput', ''
  );
  const [textPos, setTextPos] = useLocalState(
    context, 'textPos', null
  );
  const [showAnnotationList, setShowAnnotationList] = useLocalState(
    context, 'showAnnotationList', false
  );
  const [zoomLevel, setZoomLevel] = useLocalState(
    context, 'zoomLevel', 1
  );
  const [fontSize, setFontSize] = useLocalState(
    context, 'fontSize', 14
  );
  // Local draft annotations (not yet submitted to backend)
  const [pendingAnnotations, setPendingAnnotations] = useLocalState(
    context, 'pendingAnnotations', []
  );
  // Counter for generating local IDs for pending annotations
  const [pendingIdCounter, setPendingIdCounter] = useLocalState(
    context, 'pendingIdCounter', 0
  );

  // Calculate canvas dimensions based on map aspect ratio and zoom
  const baseCanvasSize = 480;
  const aspectRatio = mapWidth / (mapHeight || 1);
  let baseWidth, baseHeight;
  if (aspectRatio >= 1) {
    // Wider than tall
    baseWidth = baseCanvasSize;
    baseHeight = Math.round(baseCanvasSize / aspectRatio);
  } else {
    // Taller than wide
    baseHeight = baseCanvasSize;
    baseWidth = Math.round(baseCanvasSize * aspectRatio);
  }
  // Apply zoom
  const canvasWidth = Math.round(baseWidth * zoomLevel);
  const canvasHeight = Math.round(baseHeight * zoomLevel);

  // Add annotation to local drafts (not sent to backend yet)
  const handleAddAnnotation = annotationData => {
    const newAnnotation = {
      ...annotationData,
      id: 'pending_' + pendingIdCounter, // Temporary local ID
      pending: true, // Mark as pending
    };
    setPendingAnnotations([...pendingAnnotations, newAnnotation]);
    setPendingIdCounter(pendingIdCounter + 1);
  };

  const handleTextPrompt = (x, y, color) => {
    setTextPos({ x: x, y: y, color: color });
  };

  const handleTextSubmit = () => {
    if (textInput && textPos) {
      handleAddAnnotation({
        type: 'text',
        x1: textPos.x,
        y1: textPos.y,
        text: textInput,
        color: textPos.color,
        fontSize: fontSize,
      });
      setTextInput('');
      setTextPos(null);
    }
  };

  const handleEraseAt = (x, y) => {
    // Erase from pending annotations first
    const newPending = pendingAnnotations.filter(ann => {
      const distance = Math.sqrt(
        Math.pow(ann.x1 - x, 2) + Math.pow(ann.y1 - y, 2)
      );
      return distance > 10; // Keep if distance > radius
    });
    setPendingAnnotations(newPending);

    // Also erase from backend
    act('erase_at', { x: x, y: y });
  };

  const handleDeleteAnnotation = id => {
    // Check if it's a pending annotation
    if (String(id).startsWith('pending_')) {
      setPendingAnnotations(
        pendingAnnotations.filter(ann => ann.id !== id)
      );
    } else {
      // Delete from backend
      act('delete_annotation', { id: id });
    }
  };

  // Submit all pending annotations to the backend
  const handleSubmitAnnotations = () => {
    if (pendingAnnotations.length === 0) {
      return;
    }

    // Send each pending annotation to the backend
    for (const annotation of pendingAnnotations) {
      const { id, pending, ...annotationData } = annotation; // Remove local-only fields
      act('add_annotation', annotationData);
    }

    // Clear pending annotations
    setPendingAnnotations([]);
  };

  // Manually refresh data from backend
  const handleUpdate = () => {
    act('refresh');
  };

  // Discard all pending annotations
  const handleDiscardDrafts = () => {
    setPendingAnnotations([]);
  };

  // Combine backend annotations and pending annotations for display
  const allAnnotations = [...annotations, ...pendingAnnotations];

  return (
    <Window
      title="Facility Tactical Map"
      width={canEdit ? 700 : 550}
      height={620}>
      <Window.Content>
        <Stack fill>
          {/* Tool palette - only shown when user can edit */}
          {canEdit ? (
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

                {selectedTool === TOOL_ICON ? (
                  <Box mt={2}>
                    <Box bold mb={1}>Icons</Box>
                    <IconPicker
                      selectedIcon={selectedIcon}
                      onIconSelect={setSelectedIcon}
                    />
                  </Box>
                ) : null}

                {selectedTool === TOOL_TEXT ? (
                  <Box mt={2}>
                    <Box bold mb={1}>Font Size</Box>
                    <Stack align="center">
                      <Stack.Item>
                        <Button
                          icon="minus"
                          onClick={() => setFontSize(Math.max(8, fontSize - 2))}
                          disabled={fontSize <= 8}
                        />
                      </Stack.Item>
                      <Stack.Item>
                        <Box inline mx={1}>{fontSize}px</Box>
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          icon="plus"
                          onClick={() => setFontSize(
                            Math.min(48, fontSize + 2)
                          )}
                          disabled={fontSize >= 48}
                        />
                      </Stack.Item>
                    </Stack>
                  </Box>
                ) : null}
              </Section>
            </Stack.Item>
          ) : null}

          {/* Main canvas area */}
          <Stack.Item grow>
            <Section
              title="Tactical Map"
              fill
              buttons={
                <Box>
                  {/* Zoom controls - always visible */}
                  <Button
                    icon="search-minus"
                    onClick={() => setZoomLevel(
                      Math.max(0.5, zoomLevel - 0.25)
                    )}
                    disabled={zoomLevel <= 0.5}
                    tooltip="Zoom out"
                  />
                  <Button
                    content={Math.round(zoomLevel * 100) + '%'}
                    onClick={() => setZoomLevel(1)}
                    tooltip="Reset zoom"
                  />
                  <Button
                    icon="search-plus"
                    onClick={() => setZoomLevel(
                      Math.min(3, zoomLevel + 0.25)
                    )}
                    disabled={zoomLevel >= 3}
                    tooltip="Zoom in"
                  />
                  {/* Submit/Update controls - always visible when can edit */}
                  {canEdit ? (
                    <>
                      <Button
                        icon="upload"
                        color="good"
                        onClick={handleSubmitAnnotations}
                        disabled={pendingAnnotations.length === 0}
                        tooltip="Submit all draft annotations to save globally">
                        Submit ({pendingAnnotations.length})
                      </Button>
                      <Button
                        icon="sync"
                        onClick={handleUpdate}
                        tooltip="Update map from server (fetch latest annotations)">
                        Update
                      </Button>
                      {pendingAnnotations.length > 0 && (
                        <Button.Confirm
                          icon="times"
                          color="bad"
                          onClick={handleDiscardDrafts}
                          confirmContent="Discard?"
                          tooltip="Discard all draft annotations">
                          Discard
                        </Button.Confirm>
                      )}
                      <Button
                        icon="undo"
                        onClick={() => act('undo')}
                        disabled={annotations.length === 0}
                        tooltip="Undo"
                      />
                      <Button.Confirm
                        icon="trash"
                        color="bad"
                        onClick={() => act('clear_all')}
                        disabled={annotations.length === 0}
                        confirmContent="Clear?"
                        tooltip="Clear all"
                      />
                      <Button
                        icon="list"
                        selected={showAnnotationList}
                        onClick={() => setShowAnnotationList(
                          !showAnnotationList
                        )}
                        tooltip="Show annotation list"
                      />
                    </>
                  ) : null}
                </Box>
              }>
              <Stack vertical fill>
                <Stack.Item grow>
                  <Box
                    style={{
                      overflow: 'auto',
                      height: Math.min(baseHeight, 480) + 'px',
                      width: Math.min(baseWidth, 480) + 'px',
                      margin: '0 auto',
                      border: '1px solid #333',
                    }}>
                    <TacticalCanvas
                      mapGrid={mapGrid}
                      mapWidth={mapWidth}
                      mapHeight={mapHeight}
                      annotations={allAnnotations}
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
                  </Box>
                </Stack.Item>

                {/* Text input modal */}
                {textPos ? (
                  <Stack.Item>
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
                  </Stack.Item>
                ) : null}

                {/* Status bar */}
                <Stack.Item>
                  <Box mt={1} color="label" fontSize="11px" textAlign="center">
                    Saved: {annotations.length} | Drafts: {pendingAnnotations.length} | Total: {allAnnotations.length}/{maxAnnotations}
                    {!canEdit && ' (Read-only)'}
                    {selectedTool === TOOL_ERASER
                      && ' - Click on map to erase nearest annotation'}
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
                        annotations={allAnnotations}
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
