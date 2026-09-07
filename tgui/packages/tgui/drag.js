/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { storage } from 'common/storage';
import { vecAdd, vecInverse, vecMultiply, vecScale } from 'common/vector';
import { createLogger } from './logging';

const logger = createLogger('drag');

let windowKey = window.__windowId__;
let dragging = false;
let resizing = false;
let screenOffset = [0, 0];
let screenOffsetPromise;
let dragPointOffset;
let dragDpr = 1;
let resizeMatrix;
let resizeMouseStart;
let resizeDpr = 1;
let initialSize;
let size;

export const setWindowKey = key => {
  windowKey = key;
};

export const getWindowPosition = () => [
  window.screenLeft,
  window.screenTop,
];

export const getWindowSize = () => [
  window.innerWidth,
  window.innerHeight,
];

export const setWindowPosition = vec => {
  const dpr = window.devicePixelRatio || 1;
  const byondPos = vecAdd(
    vecScale(vec, dpr), screenOffset);
  return Byond.winset(window.__windowId__, {
    pos: Math.round(byondPos[0])
      + ',' + Math.round(byondPos[1]),
  });
};

export const setWindowSize = vec => {
  const dpr = window.devicePixelRatio || 1;
  return Byond.winset(window.__windowId__, {
    size: Math.round(vec[0] * dpr)
      + 'x' + Math.round(vec[1] * dpr),
  });
};

export const getScreenPosition = () => {
  const dpr = window.devicePixelRatio || 1;
  return [
    -screenOffset[0] / dpr,
    -screenOffset[1] / dpr,
  ];
};

export const getScreenSize = () => [
  window.screen.availWidth,
  window.screen.availHeight,
];

/**
 * Moves an item to the top of the recents array, and keeps its length
 * limited to the number in `limit` argument.
 *
 * Uses a strict equality check for comparisons.
 *
 * Returns new recents and an item which was trimmed.
 */
const touchRecents = (recents, touchedItem, limit = 50) => {
  const nextRecents = [touchedItem];
  let trimmedItem;
  for (let i = 0; i < recents.length; i++) {
    const item = recents[i];
    if (item === touchedItem) {
      continue;
    }
    if (nextRecents.length < limit) {
      nextRecents.push(item);
    }
    else {
      trimmedItem = item;
    }
  }
  return [nextRecents, trimmedItem];
};

export const storeWindowGeometry = async () => {
  logger.log('storing geometry');
  const geometry = {
    pos: getWindowPosition(),
    size: getWindowSize(),
  };
  storage.set(windowKey, geometry);
  // Update the list of stored geometries
  const [geometries, trimmedKey] = touchRecents(
    await storage.get('geometries') || [],
    windowKey);
  if (trimmedKey) {
    storage.remove(trimmedKey);
  }
  storage.set('geometries', geometries);
};

export const recallWindowGeometry = async (options = {}) => {
  // Only recall geometry in fancy mode
  const geometry = options.fancy && await storage.get(windowKey);
  if (geometry) {
    logger.log('recalled geometry:', geometry);
  }
  let pos = geometry?.pos || options.pos;
  let size = options.size;
  // Wait until screen offset gets resolved
  await screenOffsetPromise;
  const areaAvailable = [
    window.screen.availWidth,
    window.screen.availHeight,
  ];
  // Set window size
  if (size) {
    // Constraint size to not exceed available screen area.
    size = [
      Math.min(areaAvailable[0], size[0]),
      Math.min(areaAvailable[1], size[1]),
    ];
    setWindowSize(size);
  }
  // Set window position
  if (pos) {
    // Constraint window position if monitor lock was set in preferences.
    if (size && options.locked) {
      pos = constraintPosition(pos, size)[1];
    }
    setWindowPosition(pos);
  }
  // Set window position at the center of the screen.
  else if (size) {
    pos = vecAdd(
      vecScale(areaAvailable, 0.5),
      vecScale(size, -0.5),
      vecScale(screenOffset,
        -1.0 / (window.devicePixelRatio || 1)));
    setWindowPosition(pos);
  }
};

export const setupDrag = async () => {
  // Calculate chrome offset (title bar, borders) in physical
  // pixels. Factor out DPI so this is position-independent.
  screenOffsetPromise = Byond.winget(window.__windowId__, 'pos')
    .then(pos => {
      const dpr = window.devicePixelRatio || 1;
      return [
        pos.x - window.screenLeft * dpr,
        pos.y - window.screenTop * dpr,
      ];
    });
  screenOffset = await screenOffsetPromise;
  logger.debug('screen offset', screenOffset);
};

/**
 * Constraints window position to safe screen area, accounting for safe
 * margins which could be a system taskbar.
 */
const constraintPosition = (pos, size) => {
  const screenPos = getScreenPosition();
  const screenSize = getScreenSize();
  const nextPos = [pos[0], pos[1]];
  let relocated = false;
  for (let i = 0; i < 2; i++) {
    const leftBoundary = screenPos[i];
    const rightBoundary = screenPos[i] + screenSize[i];
    if (pos[i] < leftBoundary) {
      nextPos[i] = leftBoundary;
      relocated = true;
    }
    else if (pos[i] + size[i] > rightBoundary) {
      nextPos[i] = rightBoundary - size[i];
      relocated = true;
    }
  }
  return [relocated, nextPos];
};

export const dragStartHandler = event => {
  logger.log('drag start');
  dragging = true;
  // DPI scaling: event.screenX is CSS pixels but
  // Byond.winset expects physical pixels. Compute
  // the offset in physical pixel space so the drag
  // stays accurate at any display scaling (>100%).
  dragDpr = window.devicePixelRatio || 1;
  const byondX = window.screenLeft * dragDpr
    + screenOffset[0];
  const byondY = window.screenTop * dragDpr
    + screenOffset[1];
  dragPointOffset = [
    byondX - event.screenX * dragDpr,
    byondY - event.screenY * dragDpr,
  ];
  // Focus click target
  event.target?.focus();
  document.addEventListener('mousemove', dragMoveHandler);
  document.addEventListener('mouseup', dragEndHandler);
  dragMoveHandler(event);
};

const dragEndHandler = event => {
  logger.log('drag end');
  dragMoveHandler(event);
  document.removeEventListener('mousemove', dragMoveHandler);
  document.removeEventListener('mouseup', dragEndHandler);
  dragging = false;
  storeWindowGeometry();
};

const dragMoveHandler = event => {
  if (!dragging) {
    return;
  }
  event.preventDefault();
  // Compute position in physical pixels directly
  const bx = Math.round(
    event.screenX * dragDpr + dragPointOffset[0]);
  const by = Math.round(
    event.screenY * dragDpr + dragPointOffset[1]);
  Byond.winset(window.__windowId__, {
    pos: bx + ',' + by,
  });
};

export const resizeStartHandler = (x, y) => event => {
  resizeMatrix = [x, y];
  logger.log('resize start', resizeMatrix);
  resizing = true;
  // DPI scaling: compute delta in physical pixels
  // to match what Byond expects for size.
  resizeDpr = window.devicePixelRatio || 1;
  resizeMouseStart = [
    event.screenX,
    event.screenY,
  ];
  initialSize = [
    Math.round(window.innerWidth * resizeDpr),
    Math.round(window.innerHeight * resizeDpr),
  ];
  // Focus click target
  event.target?.focus();
  document.addEventListener('mousemove', resizeMoveHandler);
  document.addEventListener('mouseup', resizeEndHandler);
  resizeMoveHandler(event);
};

const resizeEndHandler = event => {
  logger.log('resize end', size);
  resizeMoveHandler(event);
  document.removeEventListener('mousemove', resizeMoveHandler);
  document.removeEventListener('mouseup', resizeEndHandler);
  resizing = false;
  storeWindowGeometry();
};

const resizeMoveHandler = event => {
  if (!resizing) {
    return;
  }
  event.preventDefault();
  // Mouse delta in physical pixels
  const delta = [
    (event.screenX - resizeMouseStart[0])
      * resizeDpr,
    (event.screenY - resizeMouseStart[1])
      * resizeDpr,
  ];
  size = vecAdd(initialSize,
    vecMultiply(resizeMatrix, delta));
  // Sane window size values
  size[0] = Math.max(size[0], 150);
  size[1] = Math.max(size[1], 50);
  size[0] = Math.round(size[0]);
  size[1] = Math.round(size[1]);
  Byond.winset(window.__windowId__, {
    size: size[0] + 'x' + size[1],
  });
};
