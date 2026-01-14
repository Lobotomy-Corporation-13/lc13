import { useBackend, useLocalState } from '../backend';
import { Box, Button, Collapsible, Input, Section, Stack, Tabs, LabeledList, ProgressBar } from '../components';
import { Window } from '../layouts';

// Trait colors for display
const TRAIT_COLORS = {
  // Organic traits
  ORGANIC: '#88cc88',
  HYBRID: '#88aacc',
  MECHANICAL: '#aaaacc',
  // Role traits
  FODDER: '#888888',
  ELITE: '#ffcc44',
  // Combat traits
  HEAVY: '#cc8844',
  AGILE: '#44cccc',
  ARMORED: '#8888cc',
  VOLATILE: '#ff6644',
  WEAPONIZED: '#cc4444',
  PRECISION: '#44cc88',
  BRUTAL: '#cc4466',
  BERSERKER: '#ff4444',
  // Special traits
  TOXIC: '#44cc44',
  PSIONIC: '#cc44cc',
  ABERRANT: '#aa44aa',
  REGENERATIVE: '#44ff88',
  CORRUPTED: '#884488',
  HIVEMIND: '#664488',
  NEURAL: '#6688cc',
  OSSIFIED: '#ccaa88',
  LIGHTWEIGHT: '#aacccc',
  ERRATIC: '#ffaa44',
};

// Research status constants (must match DM defines)
const RESEARCH_LOCKED = 'locked';
const RESEARCH_AVAILABLE = 'available';
const RESEARCH_COMPLETED = 'completed';

// Branch colors
const BRANCH_COLORS = {
  hellfire: '#ff4444',
  venom: '#44ff44',
  storm: '#4488ff',
  utility: '#aaaaaa',
};

// Branch labels
const BRANCH_LABELS = {
  hellfire: 'Hellfire (Fire)',
  venom: 'Venom (Toxic)',
  storm: 'Storm (Electric)',
  utility: 'Utility (General)',
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
    branchEnabled = { hellfire: true, venom: true, storm: true, utility: true },
    researchStats = { hellfire: 0, venom: 0, storm: 0, utility: 0 },
    bestiary = [],
    isProcessing = false,
  } = data;

  const [bestiarySearch, setBestiarySearch] = useLocalState(
    context,
    'bestiarySearch',
    ''
  );

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
              <Tabs.Tab
                selected={tab === 'stats'}
                onClick={() => setTab('stats')}>
                Statistics
              </Tabs.Tab>
              <Tabs.Tab
                selected={tab === 'bestiary'}
                onClick={() => setTab('bestiary')}>
                Bestiary
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
                isProcessing={isProcessing}
              />
            )}
            {tab === 'samples' && (
              <SamplesTab
                partsList={partsList}
                selectedResearch={selectedResearch}
                currentResearch={currentResearch}
                storedParts={storedParts}
                isProcessing={isProcessing}
                bestiary={bestiary}
              />
            )}
            {tab === 'progress' && (
              <ProgressTab
                currentResearch={currentResearch}
                researchProgress={researchProgress}
                selectedResearch={selectedResearch}
              />
            )}
            {tab === 'stats' && (
              <StatisticsTab
                researchStats={researchStats}
              />
            )}
            {tab === 'bestiary' && (
              <BestiaryTab
                bestiary={bestiary}
                searchText={bestiarySearch}
                setSearchText={setBestiarySearch}
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
    isProcessing,
  } = props;

  // Group by branch
  const branches = {
    hellfire: researchTree.filter(n => n.branch === 'hellfire'),
    venom: researchTree.filter(n => n.branch === 'venom'),
    storm: researchTree.filter(n => n.branch === 'storm'),
    utility: researchTree.filter(n => n.branch === 'utility'),
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
        {['hellfire', 'venom', 'storm', 'utility'].map(branch => (
          <Stack.Item key={branch} grow basis="25%">
            <BranchList
              branch={branch}
              nodes={branches[branch]}
              selectedResearch={selectedResearch}
              researchProgress={researchProgress}
              nodeMap={nodeMap}
              isEnabled={branchEnabled[branch]}
              isProcessing={isProcessing}
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
    isProcessing,
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
              isProcessing={isProcessing}
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
  const {
    node,
    selected,
    progress,
    branchColor,
    nodeMap,
    isProcessing,
  } = props;

  const isLocked = node.status === RESEARCH_LOCKED;
  const isAvailable = node.status === RESEARCH_AVAILABLE;
  const isCompleted = node.status === RESEARCH_COMPLETED;
  const canSelect = isAvailable && !isProcessing;

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
        opacity: isLocked || isProcessing ? 0.6 : 1,
        cursor: canSelect ? 'pointer' : 'default',
      }}
      onClick={() => {
        if (canSelect) {
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
        <Box
          fontSize="9px"
          mt={0.5}
          style={{ borderTop: '1px solid #444', paddingTop: '4px' }}>
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

// Helper to find recommended mobs for a research project
const getRecommendedMobs = (currentResearch, bestiary) => {
  if (!currentResearch || !bestiary) return [];

  const requiredTraits = currentResearch.requiredTraits || [];
  const favoredTraits = Object.keys(currentResearch.favoredTraits || {});
  const allDesiredTraits = [...requiredTraits, ...favoredTraits];

  if (allDesiredTraits.length === 0) return [];

  const recommendations = [];

  bestiary.forEach(folder => {
    (folder.mobs || []).forEach(mob => {
      const mobTraits = mob.traits || [];
      // Check if mob has any required trait
      const hasRequired = requiredTraits.length === 0
        || requiredTraits.some(t => mobTraits.includes(t));
      if (!hasRequired) return;

      // Count matching favored traits
      const matchingFavored = favoredTraits.filter(
        t => mobTraits.includes(t)
      );
      if (matchingFavored.length === 0 && requiredTraits.length === 0) {
        return;
      }

      recommendations.push({
        ...mob,
        folder: folder.name,
        matchCount: matchingFavored.length,
        matchingTraits: matchingFavored,
      });
    });
  });

  // Sort by match count (descending)
  recommendations.sort((a, b) => b.matchCount - a.matchCount);
  return recommendations.slice(0, 5); // Top 5
};

// Samples Tab
const SamplesTab = (props, context) => {
  const { act } = useBackend(context);
  const {
    partsList,
    selectedResearch,
    currentResearch,
    storedParts,
    isProcessing,
    bestiary,
  } = props;

  // Sort parts by effectiveness if research is selected
  const sortedParts = selectedResearch
    ? [...partsList].sort((a, b) => b.effectiveness - a.effectiveness)
    : partsList;

  // Get recommended mobs for current research
  const recommendedMobs = getRecommendedMobs(currentResearch, bestiary);

  return (
    <Section
      fill
      scrollable
      title="Stored Samples"
      buttons={
        <>
          {!!isProcessing && (
            <Box inline color="yellow" mr={1}>
              Processing...
            </Box>
          )}
          <Button
            icon="play"
            disabled={!selectedResearch || storedParts === 0 || isProcessing}
            onClick={() => act('processPart')}>
            Process First
          </Button>
          <Button
            icon="forward"
            disabled={!selectedResearch || storedParts === 0 || isProcessing}
            onClick={() => act('processAll')}>
            Process All
          </Button>
        </>
      }>
      {selectedResearch ? (
        <Box
          mb={2}
          p={1}
          backgroundColor="rgba(68, 136, 255, 0.2)"
          style={{ borderRadius: '4px' }}>
          <Box bold>
            Current Target: {currentResearch?.name || 'Unknown'}
          </Box>
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
            disabled={isProcessing}
            onClick={() => act('deselectResearch')}>
            {isProcessing ? 'Processing...' : 'Deselect'}
          </Button>
          {/* Recommended Mobs Section */}
          {recommendedMobs.length > 0 && (
            <Box
              mt={2}
              p={1}
              backgroundColor="rgba(0, 100, 0, 0.2)"
              style={{ borderRadius: '4px' }}>
              <Box bold color="green" mb={1}>
                Recommended Targets:
              </Box>
              {recommendedMobs.map((mob, i) => (
                <Box key={i} fontSize="11px" mb={0.5}>
                  <Box as="span" bold color="#88ff88">
                    {mob.name}
                  </Box>
                  <Box as="span" color="label">
                    {' '}({mob.folder})
                  </Box>
                  <Box fontSize="10px" color="#88cc88">
                    Matching: {mob.matchingTraits.join(', ')}
                  </Box>
                </Box>
              ))}
            </Box>
          )}
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
              <Box mt={0.5}>
                <Stack>
                  {selectedResearch && part.meetsRequirements && (
                    <Stack.Item grow>
                      <Button
                        fluid
                        icon="flask"
                        color="good"
                        onClick={e => {
                          e.stopPropagation();
                          act('processSpecificPart', { partRef: part.ref });
                        }}>
                        Process (+{part.effectiveness} pts)
                      </Button>
                    </Stack.Item>
                  )}
                  <Stack.Item
                  grow={!selectedResearch || !part.meetsRequirements}>
                    <Button
                      fluid
                      icon="eject"
                      color="caution"
                      onClick={e => {
                        e.stopPropagation();
                        act('ejectPart', { partRef: part.ref });
                      }}>
                      Eject
                    </Button>
                  </Stack.Item>
                </Stack>
              </Box>
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

// Statistics Tab - Shows research completion counts per branch
const StatisticsTab = props => {
  const { researchStats } = props;

  const totalResearched = researchStats.hellfire + researchStats.venom
    + researchStats.storm + researchStats.utility;

  return (
    <Section fill title="Research Statistics">
      <Box mb={2} color="label" italic>
        Total items researched (repeatable only): {totalResearched}
      </Box>
      <Stack>
        {['hellfire', 'venom', 'storm', 'utility'].map(branch => (
          <Stack.Item key={branch} grow basis="25%">
            <Box
              p={2}
              m={1}
              textAlign="center"
              style={{
                border: `2px solid ${BRANCH_COLORS[branch]}`,
                borderRadius: '8px',
                backgroundColor: `${BRANCH_COLORS[branch]}22`,
              }}>
              <Box
                bold
                fontSize="16px"
                color={BRANCH_COLORS[branch]}
                mb={1}>
                {BRANCH_LABELS[branch]}
              </Box>
              <Box
                fontSize="32px"
                bold
                color={BRANCH_COLORS[branch]}>
                {researchStats[branch]}
              </Box>
              <Box color="label" fontSize="12px">
                items researched
              </Box>
            </Box>
          </Stack.Item>
        ))}
      </Stack>
      <Box mt={3} color="label" fontSize="11px" textAlign="center">
        Note: Only counts repeatable research (weapons, armor, starter kits).
        <br />
        One-time factory unlocks are not included.
      </Box>
    </Section>
  );
};

// Get trait color
const getTraitColor = trait => {
  return TRAIT_COLORS[trait] || '#aaaaaa';
};

// Rank order for sorting
const RANK_ORDER = {
  Elite: 0,
  Standard: 1,
  Fodder: 2,
};

// Bestiary Tab - Shows harvestable mobs organized by folder
const BestiaryTab = props => {
  const { bestiary, searchText, setSearchText } = props;

  if (!bestiary || bestiary.length === 0) {
    return (
      <Section fill title="Bestiary">
        <Box color="label" italic>
          No bestiary data available.
        </Box>
      </Section>
    );
  }

  // Filter mobs based on search
  const searchLower = (searchText || '').toLowerCase();
  const filteredBestiary = searchLower
    ? bestiary.map(folder => ({
      ...folder,
      mobs: (folder.mobs || []).filter(mob =>
        mob.name.toLowerCase().includes(searchLower)
        || (mob.traits || []).some(
          t => t.toLowerCase().includes(searchLower)
        )
        || (mob.lore || '').toLowerCase().includes(searchLower)
      ),
    })).filter(folder => folder.mobs.length > 0)
    : bestiary;

  return (
    <Section fill scrollable title="Harvestable Targets">
      <Box mb={2}>
        <Input
          fluid
          placeholder="Search by name, trait, or lore..."
          value={searchText}
          onInput={(e, value) => setSearchText(value)}
        />
      </Box>
      <Box mb={2} color="label">
        This bestiary contains information about all creatures that can be
        harvested for research samples using the R-Corp Harvester.
      </Box>
      {filteredBestiary.length === 0 ? (
        <Box color="label" italic textAlign="center" p={2}>
          No mobs match your search.
        </Box>
      ) : (
        filteredBestiary.map(folder => (
          <BestiaryFolder
            key={folder.id}
            folder={folder}
            searchText={searchLower}
          />
        ))
      )}
    </Section>
  );
};

// Bestiary Folder Component
const BestiaryFolder = props => {
  const { folder, searchText } = props;

  // Group mobs by rank
  const mobsByRank = {
    Elite: [],
    Standard: [],
    Fodder: [],
  };

  (folder.mobs || []).forEach(mob => {
    const rank = mob.rank || 'Standard';
    if (mobsByRank[rank]) {
      mobsByRank[rank].push(mob);
    }
  });

  // Get folder color based on id
  const folderColor = folder.id === 'xcorp' ? '#ffaa44' : '#aa44ff';

  return (
    <Collapsible
      title={folder.name}
      color={folderColor}
      open>
      {/* Folder Lore Section */}
      <Box
        p={2}
        mb={2}
        backgroundColor="rgba(100, 100, 100, 0.2)"
        style={{
          borderLeft: `3px solid ${folderColor}`,
          borderRadius: '0 4px 4px 0',
          fontStyle: 'italic',
        }}>
        {folder.lore}
      </Box>

      {/* Mobs by Rank */}
      {['Elite', 'Standard', 'Fodder'].map(rank => {
        const mobs = mobsByRank[rank];
        if (mobs.length === 0) return null;

        const rankColor = rank === 'Elite'
          ? '#ffcc44'
          : rank === 'Standard'
            ? '#aaaaaa'
            : '#666666';

        return (
          <Box key={rank} mb={2}>
            <Box
              bold
              p={1}
              backgroundColor={`${rankColor}33`}
              style={{
                borderBottom: `2px solid ${rankColor}`,
                marginBottom: '8px',
              }}>
              <Box as="span" color={rankColor}>{rank.toUpperCase()} RANK</Box>
            </Box>
            {mobs.map((mob, index) => (
              <MobEntry key={index} mob={mob} />
            ))}
          </Box>
        );
      })}
    </Collapsible>
  );
};

// Individual Mob Entry Component
const MobEntry = props => {
  const { mob } = props;

  return (
    <Box
      p={2}
      mb={1}
      backgroundColor="rgba(50, 50, 50, 0.5)"
      style={{
        borderRadius: '4px',
        border: '1px solid #444',
      }}>
      <Stack>
        {/* Mob Icon */}
        <Stack.Item>
          <Box
            style={{
              width: '64px',
              height: '64px',
              backgroundColor: 'rgba(0, 0, 0, 0.3)',
              borderRadius: '4px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              marginRight: '12px',
            }}>
            {mob.icon ? (
              <Box
                as="img"
                src={`data:image/png;base64,${mob.icon}`}
                style={{
                  imageRendering: 'pixelated',
                  maxWidth: '64px',
                  maxHeight: '64px',
                }}
              />
            ) : (
              <Box color="#666" fontSize="10px" textAlign="center">
                No Icon
              </Box>
            )}
          </Box>
        </Stack.Item>

        {/* Mob Info */}
        <Stack.Item grow>
          <Box bold fontSize="14px" mb={0.5}>
            {mob.name}
          </Box>
          <Box
            fontSize="11px"
            color="label"
            mb={1}
            style={{ fontStyle: 'italic' }}>
            {mob.lore}
          </Box>

          {/* Traits */}
          {mob.traits && mob.traits.length > 0 && (
            <Box fontSize="11px" mb={0.5}>
              <Box as="span" color="label">Traits: </Box>
              {mob.traits.map((trait, i) => (
                <Box
                  key={trait}
                  as="span"
                  color={getTraitColor(trait)}
                  style={{ marginRight: '4px' }}>
                  {trait}{i < mob.traits.length - 1 ? ',' : ''}
                </Box>
              ))}
            </Box>
          )}

          {/* Value and Drop Chance */}
          <Box fontSize="10px" color="label">
            Base Value: <Box as="span" color="#88ff88">{mob.baseValue} pts</Box>
            {' | '}
            Drop Chance: <Box as="span" color="#ffaa44">{mob.dropChance}%</Box>
          </Box>
        </Stack.Item>
      </Stack>
    </Box>
  );
};
