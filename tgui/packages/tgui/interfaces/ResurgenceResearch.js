import { useBackend, useLocalState } from '../backend';
import {
  Box, Button, Flex, Icon, ProgressBar, Section, Stack,
} from '../components';
import { Window } from '../layouts';

const BRANCHES = [
  { key: null, label: 'All', icon: 'list' },
  { key: 'production', label: 'Production', icon: 'industry' },
  { key: 'armor', label: 'Armor', icon: 'shield-alt' },
  { key: 'weapons', label: 'Weapons', icon: 'crosshairs' },
  { key: 'clothing', label: 'Clothing', icon: 'tshirt' },
  { key: 'food', label: 'Food', icon: 'utensils' },
  { key: 'decor', label: 'Decor', icon: 'paint-brush' },
  { key: 'utility', label: 'Utility', icon: 'wrench' },
];

export const ResurgenceResearch = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    current_faith = 0,
    nodes = [],
    researched_nodes = [],
    node_width = 140,
    node_height = 70,
    busy,
    has_research_in_progress,
    current_research_id,
    current_research_name,
    current_work = 0,
    total_work = 0,
    progress_percent = 0,
    faith_per_session = 1,
    work_per_session = 5,
    session_time = 5,
  } = data;

  const [selectedNode, setSelectedNode] = useLocalState(
    context,
    'selectedNode',
    null
  );

  const [branchFilter, setBranchFilter] = useLocalState(
    context,
    'branchFilter',
    null
  );

  // Find the selected node data
  const selectedNodeData = selectedNode
    ? nodes.find(n => n.id === selectedNode)
    : null;

  // Calculate canvas size based on node positions
  let maxX = 800;
  let maxY = 400;
  for (const node of nodes) {
    if (node.x + node_width > maxX) maxX = node.x + node_width + 40;
    if (node.y + node_height > maxY) maxY = node.y + node_height + 40;
  }

  // Build path highlighting sets
  const highlightedNodes = new Set();
  const highlightedLines = new Set();

  if (selectedNodeData) {
    highlightedNodes.add(selectedNodeData.id);

    if (selectedNodeData.is_researched) {
      // If researched, highlight paths TO dependent nodes
      const findDependents = (nodeId, visited = new Set()) => {
        if (visited.has(nodeId)) return;
        visited.add(nodeId);
        highlightedNodes.add(nodeId);

        for (const node of nodes) {
          if (node.prerequisites.includes(nodeId)) {
            highlightedLines.add(`${nodeId}-${node.id}`);
            findDependents(node.id, visited);
          }
        }
      };
      findDependents(selectedNodeData.id);
    } else {
      // If not researched, highlight paths FROM prerequisites
      const findPrereqs = (nodeId, visited = new Set()) => {
        if (visited.has(nodeId)) return;
        visited.add(nodeId);
        highlightedNodes.add(nodeId);

        const node = nodes.find(n => n.id === nodeId);
        if (node) {
          for (const prereqId of node.prerequisites) {
            highlightedLines.add(`${prereqId}-${nodeId}`);
            findPrereqs(prereqId, visited);
          }
        }
      };
      findPrereqs(selectedNodeData.id);
    }
  }

  // Branch filter: dim nodes not in selected branch
  const filteredOut = new Set();
  if (branchFilter) {
    for (const node of nodes) {
      const types = node.branch_types || [];
      if (!types.includes(branchFilter)) {
        filteredOut.add(node.id);
      }
    }
  }

  return (
    <Window
      width={920}
      height={800}>
      <Window.Content>
        <Stack fill vertical>
          {/* Header with faith display */}
          <Stack.Item>
            <Section>
              <Flex align="center" justify="space-between">
                <Flex.Item>
                  <Box bold fontSize="16px">
                    <Icon name="flask" color="purple" mr={1} />
                    Resurgence Research
                  </Box>
                </Flex.Item>
                <Flex.Item>
                  <Box bold fontSize="14px" color="blue">
                    <Icon name="star" mr={1} />
                    Faith: {current_faith}
                  </Box>
                </Flex.Item>
                <Flex.Item>
                  <Box color="label" fontSize="11px">
                    {researched_nodes.length}/{nodes.length} researched
                  </Box>
                </Flex.Item>
              </Flex>
            </Section>
          </Stack.Item>

          {/* Branch Filter */}
          <Stack.Item>
            <Flex wrap="wrap" align="center" ml={1}>
              {BRANCHES.map(b => (
                <Flex.Item key={b.label} mr={0.5} mb={0.5}>
                  <Button
                    icon={b.icon}
                    selected={branchFilter === b.key}
                    content={b.label}
                    onClick={() => setBranchFilter(
                      branchFilter === b.key ? null : b.key
                    )}
                  />
                </Flex.Item>
              ))}
            </Flex>
          </Stack.Item>

          {/* Research In Progress */}
          {!!has_research_in_progress && (
            <Stack.Item>
              <Section
                title="Research In Progress"
                buttons={(
                  <Button
                    icon="times"
                    color="bad"
                    content="Cancel"
                    disabled={busy}
                    tooltip="Cancel research (progress saved)"
                    onClick={() => act('cancel_research')}
                  />
                )}>
                <Stack vertical>
                  <Stack.Item>
                    <Box bold fontSize="14px" mb={1}>
                      <Icon name="flask" mr={1} />
                      {current_research_name}
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <ProgressBar
                      value={progress_percent / 100}
                      ranges={{
                        good: [0.67, 1],
                        average: [0.33, 0.67],
                        bad: [0, 0.33],
                      }}>
                      {progress_percent}% ({current_work}/{total_work} work)
                    </ProgressBar>
                  </Stack.Item>
                  <Stack.Item mt={1}>
                    <Button
                      fluid
                      icon={busy ? 'spinner' : 'play'}
                      color="good"
                      disabled={busy}
                      content={busy ? 'Researching...' : 'Continue Research'}
                      onClick={() => act('continue_research')}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Box color="label" fontSize="11px" mt={1}>
                      <Icon name="info-circle" mr={1} />
                      Each session: {work_per_session} work in {session_time}s,
                      costs {faith_per_session} faith.
                    </Box>
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>
          )}

          {/* Tech Tree */}
          <Stack.Item grow>
            <Section fill scrollable title="Technology Tree">
              <Box
                style={{
                  position: 'relative',
                  width: maxX + 'px',
                  height: maxY + 'px',
                  minWidth: '100%',
                  minHeight: '100%',
                }}>
                {/* SVG layer for connecting lines */}
                <svg
                  style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    width: '100%',
                    height: '100%',
                    pointerEvents: 'none',
                  }}>
                  {/* Draw all lines */}
                  {nodes.map(node => (
                    node.prerequisites.map(prereqId => {
                      const prereq = nodes.find(n => n.id === prereqId);
                      if (!prereq) return null;

                      const lineKey = `${prereqId}-${node.id}`;
                      const isHighlighted = highlightedLines.has(lineKey);
                      const bothResearched = node.is_researched
                        && prereq.is_researched;

                      const eitherFiltered
                        = filteredOut.has(node.id)
                        || filteredOut.has(prereqId);

                      return (
                        <PrerequisiteLine
                          key={lineKey}
                          fromX={prereq.x + node_width}
                          fromY={prereq.y + node_height / 2}
                          toX={node.x}
                          toY={node.y + node_height / 2}
                          isResearched={bothResearched}
                          isHighlighted={isHighlighted}
                          hasSelection={!!selectedNode}
                          isFilteredOut={eitherFiltered}
                        />
                      );
                    })
                  ))}
                </svg>

                {/* Render nodes */}
                {nodes.map(node => (
                  <ResearchNode
                    key={node.id}
                    node={node}
                    nodeWidth={node_width}
                    nodeHeight={node_height}
                    isSelected={selectedNode === node.id}
                    isHighlighted={highlightedNodes.has(node.id)}
                    hasSelection={!!selectedNode}
                    isCurrentResearch={current_research_id === node.id}
                    isFilteredOut={filteredOut.has(node.id)}
                    onSelect={() => setSelectedNode(
                      selectedNode === node.id ? null : node.id
                    )}
                  />
                ))}
              </Box>
            </Section>
          </Stack.Item>

          {/* Selected Node Details */}
          <Stack.Item>
            <Section
              title={
                selectedNodeData ? selectedNodeData.name : 'Select a node'
              }
              buttons={selectedNodeData && (
                <ResearchButton
                  node={selectedNodeData}
                  hasResearchInProgress={has_research_in_progress}
                  currentResearchId={current_research_id}
                  busy={busy}
                />
              )}>
              {selectedNodeData ? (
                <Flex>
                  <Flex.Item basis="50%" mr={2}>
                    <Box color="label" mb={1}>{selectedNodeData.desc}</Box>
                    <Box>
                      <Box inline bold mr={1}>Tier:</Box>
                      {selectedNodeData.tier}
                    </Box>
                    <Box>
                      <Box inline bold mr={1}>Work:</Box>
                      <Box inline>
                        {selectedNodeData.current_work}
                        /{selectedNodeData.total_work}
                      </Box>
                    </Box>
                    <Box>
                      <Box inline bold mr={1}>Faith needed:</Box>
                      <Box
                        inline
                        color={selectedNodeData.can_afford ? 'good' : 'bad'}>
                        ~{selectedNodeData.faith_cost} total
                      </Box>
                    </Box>
                    {selectedNodeData.prerequisites.length > 0 && (
                      <Box>
                        <Box inline bold mr={1}>Requires:</Box>
                        {selectedNodeData.prerequisites.map((prereq, i) => {
                          const pNode = nodes.find(n => n.id === prereq);
                          const isResearched = pNode?.is_researched;
                          return (
                            <Box
                              key={prereq}
                              inline
                              color={isResearched ? 'good' : 'bad'}
                              mr={1}>
                              {pNode?.name || prereq}
                              {i < selectedNodeData.prerequisites.length - 1
                                && ', '}
                            </Box>
                          );
                        })}
                      </Box>
                    )}
                  </Flex.Item>
                  <Flex.Item basis="50%">
                    <Box bold mb={0.5}>Unlocks:</Box>
                    <Box color="good" fontSize="12px">
                      {selectedNodeData.unlocks_desc}
                    </Box>
                  </Flex.Item>
                </Flex>
              ) : (
                <Box color="label" italic>
                  Click on a research node to view details.
                </Box>
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

// Research button component
const ResearchButton = (props, context) => {
  const { act } = useBackend(context);
  const {
    node,
    hasResearchInProgress,
    currentResearchId,
    busy,
  } = props;

  if (node.is_researched) {
    return (
      <Button
        icon="check"
        color="grey"
        disabled
        content="Already Researched"
      />
    );
  }

  if (!node.can_research) {
    return (
      <Button
        icon="lock"
        color="bad"
        disabled
        content="Prerequisites Required"
      />
    );
  }

  if (currentResearchId === node.id) {
    return (
      <Button
        icon="flask"
        color="good"
        disabled={busy}
        content="Currently Researching"
        onClick={() => act('continue_research')}
      />
    );
  }

  if (hasResearchInProgress) {
    return (
      <Button
        icon="exchange-alt"
        color="average"
        disabled={busy}
        content="Switch to This"
        onClick={() => act('start_research', { node: node.id })}
      />
    );
  }

  return (
    <Button
      icon="flask"
      color={node.can_afford ? 'good' : 'bad'}
      disabled={!node.can_afford || busy}
      content={node.can_afford ? 'Start Research' : 'Need Faith'}
      onClick={() => act('start_research', { node: node.id })}
    />
  );
};

// Rimworld-style bezier curve line
const PrerequisiteLine = props => {
  const {
    fromX,
    fromY,
    toX,
    toY,
    isResearched,
    isHighlighted,
    hasSelection,
    isFilteredOut,
  } = props;

  // Calculate control points for smooth S-curve
  const midX = (fromX + toX) / 2;

  // Determine line style based on state
  let strokeColor = '#444';
  let strokeWidth = 2;
  let opacity = isFilteredOut ? 0.15
    : hasSelection ? 0.2 : 0.6;

  if (isHighlighted) {
    strokeColor = isResearched ? '#4a4' : '#fa0';
    strokeWidth = 3;
    opacity = 1;
  } else if (isResearched) {
    strokeColor = '#4a4';
    opacity = hasSelection ? 0.3 : 0.8;
  }

  // Build the bezier path string
  const pathD = `M ${fromX} ${fromY} C ${midX} ${fromY}, `
    + `${midX} ${toY}, ${toX} ${toY}`;

  return (
    <g>
      {/* Glow effect for highlighted lines */}
      {isHighlighted && (
        <path
          d={pathD}
          fill="none"
          stroke={strokeColor}
          strokeWidth={strokeWidth + 4}
          opacity={0.3}
        />
      )}
      {/* Main line */}
      <path
        d={pathD}
        fill="none"
        stroke={strokeColor}
        strokeWidth={strokeWidth}
        opacity={opacity}
      />
      {/* Arrow at the end */}
      <polygon
        points={createArrowPoints(toX, toY, midX, toY)}
        fill={strokeColor}
        opacity={opacity}
      />
    </g>
  );
};

// Create arrow points for line endpoint
const createArrowPoints = (tipX, tipY, fromX, fromY) => {
  const arrowSize = 6;
  const angle = Math.atan2(tipY - fromY, tipX - fromX);
  const x1 = tipX - arrowSize * Math.cos(angle - Math.PI / 6);
  const y1 = tipY - arrowSize * Math.sin(angle - Math.PI / 6);
  const x2 = tipX - arrowSize * Math.cos(angle + Math.PI / 6);
  const y2 = tipY - arrowSize * Math.sin(angle + Math.PI / 6);
  return `${tipX},${tipY} ${x1},${y1} ${x2},${y2}`;
};

const ResearchNode = props => {
  const {
    node,
    nodeWidth,
    nodeHeight,
    isSelected,
    isHighlighted,
    hasSelection,
    isCurrentResearch,
    isFilteredOut,
    onSelect,
  } = props;

  // Determine node color based on state
  let bgColor = 'rgba(50, 50, 50, 0.9)';
  let borderColor = '#555';
  let textColor = '#888';
  let glowColor = null;

  if (node.is_researched) {
    bgColor = 'rgba(30, 80, 30, 0.9)';
    borderColor = '#4a4';
    textColor = '#8f8';
    if (isHighlighted) glowColor = '#4a4';
  } else if (isCurrentResearch) {
    bgColor = 'rgba(80, 60, 20, 0.9)';
    borderColor = '#fa0';
    textColor = '#ff0';
    glowColor = '#fa0';
  } else if (node.can_research) {
    bgColor = 'rgba(80, 70, 20, 0.9)';
    borderColor = node.can_afford ? '#aa0' : '#a84';
    textColor = node.can_afford ? '#ff0' : '#fa8';
    if (isHighlighted) glowColor = '#fa0';
  } else if (isHighlighted) {
    bgColor = 'rgba(60, 50, 50, 0.9)';
    borderColor = '#a55';
    glowColor = '#a55';
  }

  if (isSelected) {
    borderColor = '#fff';
    glowColor = '#fff';
  }

  // Dim non-highlighted nodes when something is selected
  const dimmed = isFilteredOut
    || (hasSelection && !isHighlighted && !isSelected);

  // Calculate progress percentage for display
  const progressPct = node.total_work > 0
    ? Math.round((node.current_work / node.total_work) * 100)
    : 0;

  return (
    <Box
      style={{
        position: 'absolute',
        left: node.x + 'px',
        top: node.y + 'px',
        width: nodeWidth + 'px',
        height: nodeHeight + 'px',
        backgroundColor: bgColor,
        border: '2px solid ' + borderColor,
        borderRadius: '6px',
        padding: '6px',
        cursor: 'pointer',
        overflow: 'hidden',
        opacity: dimmed ? 0.4 : 1,
        boxShadow: glowColor
          ? `0 0 10px ${glowColor}, 0 0 20px ${glowColor}`
          : 'none',
        transition: 'opacity 0.2s, box-shadow 0.2s',
      }}
      onClick={onSelect}>
      <Box bold fontSize="11px" color={textColor} mb={0.5}>
        {!!node.is_researched && <Icon name="check" mr={0.5} />}
        {!node.is_researched && !!node.can_research && (
          <Icon name="flask" mr={0.5} />
        )}
        {!node.is_researched && !node.can_research && (
          <Icon name="lock" mr={0.5} />
        )}
        {node.name}
      </Box>
      <Box fontSize="10px" color="label">
        Tier {node.tier}
      </Box>
      {node.is_researched ? (
        <Box fontSize="10px" color="good">
          <Icon name="check-circle" mr={0.5} />
          Complete
        </Box>
      ) : node.current_work > 0 ? (
        <Box fontSize="10px" color="average">
          <Icon name="spinner" mr={0.5} />
          {progressPct}% ({node.current_work}/{node.total_work})
        </Box>
      ) : (
        <Box fontSize="10px" color={node.can_afford ? 'label' : 'bad'}>
          <Icon name="star" mr={0.5} />
          ~{node.faith_cost} faith
        </Box>
      )}
    </Box>
  );
};
