import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Stack, Tabs, LabeledList, ProgressBar } from '../components';
import { Window } from '../layouts';

// Research status constants (must match DM defines)
const RESEARCH_LOCKED = 'locked';
const RESEARCH_AVAILABLE = 'available';
const RESEARCH_COMPLETED = 'completed';

// Branch colors
const BRANCH_COLORS = {
  hellfire: '#ff4444',
  venom: '#44ff44',
  storm: '#4488ff',
};

// Branch labels
const BRANCH_LABELS = {
  hellfire: 'Hellfire (Fire)',
  venom: 'Venom (Toxic)',
  storm: 'Storm (Electric)',
};

export const RCEResearch = (props, context) => {
  const { act, data } = useBackend(context);
  const [tab, setTab] = useLocalState(context, 'tab', 'tree');

  const {
    selectedResearch,
    storedParts = 0,
    researchTree = [],
    partsList = [],
    researchProgress = {},
    branchEnabled = { hellfire: true, venom: true, storm: true },
  } = data;

  const currentResearch = selectedResearch && researchTree
    ? researchTree.find(n => n.id === selectedResearch)
    : null;

  return (
    <Window
      title="R-Corp Biological Research Station"
      width={800}
      height={600}>
      <Window.Content scrollable>
        <Stack fill vertical>
          <Stack.Item>
            <Tabs fluid>
              <Tabs.Tab
                selected={tab === 'tree'}
                onClick={() => setTab('tree')}>
                Research Tree
              </Tabs.Tab>
              <Tabs.Tab
                selected={tab === 'samples'}
                onClick={() => setTab('samples')}>
                Samples ({storedParts})
              </Tabs.Tab>
              <Tabs.Tab
                selected={tab === 'progress'}
                onClick={() => setTab('progress')}>
                Current Research
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            {tab === 'tree' && (
              <ResearchTreeTab
                researchTree={researchTree}
                selectedResearch={selectedResearch}
                researchProgress={researchProgress}
                branchEnabled={branchEnabled}
              />
            )}
            {tab === 'samples' && (
              <SamplesTab
                partsList={partsList}
                selectedResearch={selectedResearch}
                currentResearch={currentResearch}
                storedParts={storedParts}
              />
            )}
            {tab === 'progress' && (
              <ProgressTab
                currentResearch={currentResearch}
                researchProgress={researchProgress}
                selectedResearch={selectedResearch}
              />
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

// Research Tree Tab - Simple list layout with three branches
const ResearchTreeTab = (props, context) => {
  const { act } = useBackend(context);
  const {
    researchTree,
    selectedResearch,
    researchProgress,
    branchEnabled,
  } = props;

  // Group by branch
  const branches = {
    hellfire: researchTree.filter(n => n.branch === 'hellfire'),
    venom: researchTree.filter(n => n.branch === 'venom'),
    storm: researchTree.filter(n => n.branch === 'storm'),
  };

  // Sort each branch by tier
  Object.keys(branches).forEach(branch => {
    branches[branch].sort((a, b) => (a.tier || 0) - (b.tier || 0));
  });

  // Create node lookup for prerequisite names
  const nodeMap = {};
  researchTree.forEach(node => {
    nodeMap[node.id] = node;
  });

  return (
    <Section fill scrollable title="Research Tree">
      <Stack>
        {['hellfire', 'venom', 'storm'].map(branch => (
          <Stack.Item key={branch} grow basis="33%">
            <BranchList
              branch={branch}
              nodes={branches[branch]}
              selectedResearch={selectedResearch}
              researchProgress={researchProgress}
              nodeMap={nodeMap}
              isEnabled={branchEnabled[branch]}
            />
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

// Branch list component
const BranchList = (props, context) => {
  const { act } = useBackend(context);
  const {
    branch,
    nodes,
    selectedResearch,
    researchProgress,
    nodeMap,
    isEnabled,
  } = props;

  const branchColor = isEnabled ? BRANCH_COLORS[branch] : '#666';
  const branchLabel = BRANCH_LABELS[branch];

  return (
    <Box
      style={{
        border: `2px solid ${branchColor}`,
        borderRadius: '4px',
        margin: '0 4px',
        opacity: isEnabled ? 1 : 0.6,
      }}>
      {/* Header */}
      <Box
        bold
        textAlign="center"
        p={1}
        style={{
          backgroundColor: branchColor + '44',
          borderBottom: `1px solid ${branchColor}`,
          color: branchColor,
        }}>
        {branchLabel}
        {!isEnabled && (
          <Box color="#ff4444" fontSize="10px">
            [DISABLED]
          </Box>
        )}
      </Box>

      {/* Nodes */}
      <Box p={1}>
        {!isEnabled ? (
          <Box color="label" textAlign="center" p={2}>
            This research branch is currently disabled.
          </Box>
        ) : nodes.length === 0 ? (
          <Box color="label" textAlign="center" p={2}>
            No research available
          </Box>
        ) : (
          nodes.map(node => (
            <ResearchNodeCard
              key={node.id}
              node={node}
              selected={selectedResearch === node.id}
              progress={researchProgress[node.id] || 0}
              branchColor={branchColor}
              nodeMap={nodeMap}
            />
          ))
        )}
      </Box>
    </Box>
  );
};

// Individual research node card
const ResearchNodeCard = (props, context) => {
  const { act } = useBackend(context);
  const { node, selected, progress, branchColor, nodeMap } = props;

  const isLocked = node.status === RESEARCH_LOCKED;
  const isAvailable = node.status === RESEARCH_AVAILABLE;
  const isCompleted = node.status === RESEARCH_COMPLETED;

  // Get prerequisite names
  const prereqNames = (node.prerequisites || [])
    .map(id => nodeMap[id]?.name || id)
    .join(', ');

  // Determine border color
  let borderColor = '#555';
  if (isCompleted) {
    borderColor = '#44ff44';
  } else if (isAvailable) {
    borderColor = branchColor;
  } else if (selected) {
    borderColor = '#ffff00';
  }

  const progressPercent = node.cost > 0 ? (progress / node.cost) * 100 : 0;

  return (
    <Box
      mb={1}
      p={1}
      style={{
        border: selected ? '2px solid #ffff00' : `1px solid ${borderColor}`,
        borderRadius: '4px',
        backgroundColor: isLocked ? 'rgba(30, 30, 30, 0.8)' : 'rgba(50, 50, 50, 0.8)',
        opacity: isLocked ? 0.6 : 1,
        cursor: isAvailable ? 'pointer' : 'default',
      }}
      onClick={() => {
        if (isAvailable) {
          act('selectResearch', { nodeId: node.id });
        }
      }}>
      {/* Title row */}
      <Stack justify="space-between" align="center">
        <Stack.Item grow>
          <Box bold color={isCompleted ? '#44ff44' : (isAvailable ? branchColor : '#888')}>
            {node.name}
          </Box>
        </Stack.Item>
        <Stack.Item>
          {isCompleted && (
            <Box color="#44ff44" bold>[DONE]</Box>
          )}
          {isAvailable && (
            <Box color={branchColor}>[AVAILABLE]</Box>
          )}
          {isLocked && (
            <Box color="#666">[LOCKED]</Box>
          )}
        </Stack.Item>
      </Stack>

      {/* Description */}
      <Box fontSize="11px" color="label" mt={0.5}>
        {node.desc}
      </Box>

      {/* Tier */}
      <Box fontSize="10px" color="label" mt={0.5}>
        Tier: {node.tier === 0 ? 'ROOT' : node.tier} | Cost: {node.cost} points
      </Box>

      {/* Prerequisites - IMPORTANT: Shows what you need */}
      {prereqNames && (
        <Box fontSize="10px" color={isLocked ? 'orange' : 'label'} mt={0.5}>
          <b>Requires:</b> {prereqNames}
        </Box>
      )}

      {/* What this unlocks */}
      {node.unlocks && node.unlocks.length > 0 && (
        <Box fontSize="10px" color="green" mt={0.5}>
          <b>Unlocks:</b> {node.unlocks.join(', ')}
        </Box>
      )}

      {/* Progress bar for non-locked */}
      {!isLocked && (
        <Box mt={0.5}>
          <ProgressBar
            value={progressPercent}
            maxValue={100}
            color={isCompleted ? 'good' : 'blue'}>
            {progress}/{node.cost}
          </ProgressBar>
        </Box>
      )}

      {/* Traits info */}
      {(node.requiredTraits?.length > 0
        || Object.keys(node.favoredTraits || {}).length > 0
        || Object.keys(node.negativeTraits || {}).length > 0) && (
        <Box fontSize="9px" mt={0.5} style={{ borderTop: '1px solid #444', paddingTop: '4px' }}>
          {node.requiredTraits?.length > 0 && (
            <Box color="orange">
              Required: {node.requiredTraits.join(', ')}
            </Box>
          )}
          {Object.keys(node.favoredTraits || {}).length > 0 && (
            <Box color="green">
              Bonus: {Object.keys(node.favoredTraits).join(', ')}
            </Box>
          )}
          {Object.keys(node.negativeTraits || {}).length > 0 && (
            <Box color="red">
              Penalty: {Object.keys(node.negativeTraits).join(', ')}
            </Box>
          )}
        </Box>
      )}
    </Box>
  );
};

// Helper to get effectiveness color
const getEffectivenessColor = (effectiveness, baseValue) => {
  if (effectiveness === 0) return '#ff4444';
  if (effectiveness > baseValue * 1.5) return '#44ff44';
  if (effectiveness > baseValue) return '#88ff88';
  if (effectiveness < baseValue) return '#ffaa44';
  return '#ffffff';
};

// Helper to get effectiveness label
const getEffectivenessLabel = (effectiveness, baseValue, meetsRequirements) => {
  if (!meetsRequirements) return 'INCOMPATIBLE';
  const ratio = effectiveness / baseValue;
  if (ratio >= 2) return 'Excellent';
  if (ratio >= 1.5) return 'Good';
  if (ratio >= 1) return 'Normal';
  if (ratio >= 0.5) return 'Poor';
  return 'Minimal';
};

// Samples Tab
const SamplesTab = (props, context) => {
  const { act } = useBackend(context);
  const { partsList, selectedResearch, currentResearch, storedParts } = props;

  // Sort parts by effectiveness if research is selected
  const sortedParts = selectedResearch
    ? [...partsList].sort((a, b) => b.effectiveness - a.effectiveness)
    : partsList;

  return (
    <Section
      fill
      scrollable
      title="Stored Samples"
      buttons={
        <>
          <Button
            icon="play"
            disabled={!selectedResearch || storedParts === 0}
            onClick={() => act('processPart')}>
            Process First
          </Button>
          <Button
            icon="forward"
            disabled={!selectedResearch || storedParts === 0}
            onClick={() => act('processAll')}>
            Process All
          </Button>
        </>
      }>
      {selectedResearch ? (
        <Box mb={2} p={1} backgroundColor="rgba(68, 136, 255, 0.2)" style={{ borderRadius: '4px' }}>
          <Box bold>Current Target: {currentResearch?.name || 'Unknown'}</Box>
          {currentResearch?.requiredTraits?.length > 0 && (
            <Box fontSize="11px" color="orange">
              Required traits: {currentResearch.requiredTraits.join(', ')}
            </Box>
          )}
          {Object.keys(currentResearch?.favoredTraits || {}).length > 0
            && (
              <Box fontSize="11px" color="green">
                Bonus: {Object.keys(currentResearch.favoredTraits).map(
                  trait => `${trait} (+${Math.round(
                    currentResearch.favoredTraits[trait] * 100
                  )}%)`
                ).join(', ')}
              </Box>
            )}
          {Object.keys(currentResearch?.negativeTraits || {}).length > 0
            && (
              <Box fontSize="11px" color="red">
                Penalty: {Object.keys(currentResearch.negativeTraits).map(
                  trait => `${trait} (${Math.round(
                    currentResearch.negativeTraits[trait] * 100
                  )}%)`
                ).join(', ')}
              </Box>
            )}
          <Button
            mt={1}
            icon="times"
            color="bad"
            onClick={() => act('deselectResearch')}>
            Deselect
          </Button>
        </Box>
      ) : (
        <Box mb={2} color="label" italic>
          Select a research project from the Research Tree tab
          to see sample effectiveness.
        </Box>
      )}
      {partsList.length === 0 ? (
        <Box color="label" italic>
          No samples stored. Use the R-Corp Harvester to collect samples.
        </Box>
      ) : (
        <>
          {selectedResearch && (
            <Box mb={1} fontSize="11px" color="label">
              Click a sample to process it. Sorted by effectiveness.
            </Box>
          )}
          {sortedParts.map(part => (
            <Box
              key={part.ref}
              p={1}
              mb={1}
              backgroundColor={
                !part.meetsRequirements && selectedResearch
                  ? 'rgba(255, 0, 0, 0.15)'
                  : part.effectiveness > part.baseValue && selectedResearch
                    ? 'rgba(0, 255, 0, 0.15)'
                    : 'rgba(0, 0, 0, 0.3)'
              }
              style={{
                borderRadius: '4px',
                border: selectedResearch
                  ? `1px solid ${getEffectivenessColor(
                    part.effectiveness,
                    part.baseValue
                  )}`
                  : '1px solid #444',
                cursor: selectedResearch && part.meetsRequirements
                  ? 'pointer'
                  : 'default',
                opacity: !part.meetsRequirements && selectedResearch
                  ? 0.6
                  : 1,
              }}
              onClick={() => {
                if (selectedResearch && part.meetsRequirements) {
                  act('processSpecificPart', { partRef: part.ref });
                }
              }}>
              <Stack justify="space-between" align="center">
                <Stack.Item grow>
                  <Box bold>{part.name}</Box>
                </Stack.Item>
                {selectedResearch && (
                  <Stack.Item>
                    <Box
                      bold
                      color={getEffectivenessColor(
                        part.effectiveness,
                        part.baseValue
                      )}
                      style={{ textAlign: 'right' }}>
                      {part.meetsRequirements ? (
                        <>
                          {part.effectiveness} pts
                          <Box fontSize="10px">
                            ({getEffectivenessLabel(
                              part.effectiveness,
                              part.baseValue,
                              part.meetsRequirements
                            )})
                          </Box>
                        </>
                      ) : (
                        <Box color="#ff4444">INCOMPATIBLE</Box>
                      )}
                    </Box>
                  </Stack.Item>
                )}
              </Stack>
              <Box fontSize="11px" color="label">
                Source: {part.source} | Base: {part.baseValue} pts
              </Box>
              {part.traits?.length > 0 && (
                <Box fontSize="11px" mt={0.5}>
                  <Box as="span" color="label">Traits: </Box>
                  {part.traits.map((trait, i) => {
                    let traitColor = '#aaa';
                    if (selectedResearch && currentResearch) {
                      if (currentResearch.requiredTraits?.includes(trait)) {
                        traitColor = '#ffaa00';
                      } else if (currentResearch.favoredTraits?.[trait]) {
                        traitColor = '#44ff44';
                      } else if (currentResearch.negativeTraits?.[trait]) {
                        traitColor = '#ff4444';
                      }
                    }
                    return (
                      <Box key={trait} as="span" color={traitColor}>
                        {trait}{i < part.traits.length - 1 ? ', ' : ''}
                      </Box>
                    );
                  })}
                </Box>
              )}
              {selectedResearch && part.meetsRequirements && (
                <Box mt={0.5}>
                  <Button
                    fluid
                    icon="flask"
                    color="good"
                    onClick={e => {
                      e.stopPropagation();
                      act('processSpecificPart', { partRef: part.ref });
                    }}>
                    Process This Sample (+{part.effectiveness} pts)
                  </Button>
                </Box>
              )}
            </Box>
          ))}
        </>
      )}
    </Section>
  );
};

// Progress Tab
const ProgressTab = (props, context) => {
  const { act } = useBackend(context);
  const { currentResearch, researchProgress, selectedResearch } = props;

  if (!selectedResearch || !currentResearch) {
    return (
      <Section fill title="Current Research">
        <Box color="label" italic>
          No research selected. Choose a project from the
          Research Tree tab.
        </Box>
      </Section>
    );
  }

  const progress = researchProgress[selectedResearch] || 0;
  const progressPercent = currentResearch.cost > 0
    ? (progress / currentResearch.cost) * 100
    : 0;

  return (
    <Section fill title="Current Research">
      <LabeledList>
        <LabeledList.Item label="Research">
          {currentResearch.name}
        </LabeledList.Item>
        <LabeledList.Item label="Description">
          {currentResearch.desc}
        </LabeledList.Item>
        <LabeledList.Item label="Branch">
          <Box color={BRANCH_COLORS[currentResearch.branch]}>
            {BRANCH_LABELS[currentResearch.branch]}
          </Box>
        </LabeledList.Item>
        <LabeledList.Item label="Tier">
          {currentResearch.tier === 0 ? 'ROOT' : currentResearch.tier}
        </LabeledList.Item>
        <LabeledList.Item label="Progress">
          <ProgressBar
            value={progressPercent}
            maxValue={100}
            color="blue">
            {progress}/{currentResearch.cost} points
          </ProgressBar>
        </LabeledList.Item>
        {currentResearch.requiredTraits?.length > 0 && (
          <LabeledList.Item label="Required Traits">
            <Box color="orange">{currentResearch.requiredTraits.join(', ')}</Box>
          </LabeledList.Item>
        )}
        {Object.keys(currentResearch.favoredTraits || {}).length > 0 && (
          <LabeledList.Item label="Favored Traits">
            <Box color="green">
              {Object.keys(currentResearch.favoredTraits).map(trait => (
                <Box key={trait}>
                  {trait}: +{Math.round(
                    currentResearch.favoredTraits[trait] * 100
                  )}%
                </Box>
              ))}
            </Box>
          </LabeledList.Item>
        )}
        {Object.keys(currentResearch.negativeTraits || {}).length > 0 && (
          <LabeledList.Item label="Negative Traits">
            <Box color="red">
              {Object.keys(currentResearch.negativeTraits).map(trait => (
                <Box key={trait}>
                  {trait}: {Math.round(
                    currentResearch.negativeTraits[trait] * 100
                  )}%
                </Box>
              ))}
            </Box>
          </LabeledList.Item>
        )}
        {currentResearch.prerequisites?.length > 0 && (
          <LabeledList.Item label="Prerequisites">
            {currentResearch.prerequisites.join(', ')}
          </LabeledList.Item>
        )}
      </LabeledList>
      <Box mt={2}>
        <Button
          icon="times"
          color="bad"
          onClick={() => act('deselectResearch')}>
          Deselect Research
        </Button>
      </Box>
    </Section>
  );
};
