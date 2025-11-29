import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Stack, Tabs, LabeledList, ProgressBar, Tooltip } from '../components';

// Research status constants
const RESEARCH_LOCKED = 0;
const RESEARCH_AVAILABLE = 1;
const RESEARCH_COMPLETED = 2;

// Status colors
const STATUS_COLORS = {
  [RESEARCH_LOCKED]: '#666666',
  [RESEARCH_AVAILABLE]: '#4488ff',
  [RESEARCH_COMPLETED]: '#44ff44',
};

// Status labels
const STATUS_LABELS = {
  [RESEARCH_LOCKED]: 'Locked',
  [RESEARCH_AVAILABLE]: 'Available',
  [RESEARCH_COMPLETED]: 'Completed',
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
  } = data;

  // Derive currentResearch from selectedResearch and researchTree
  const currentResearch = selectedResearch && researchTree
    ? researchTree.find(n => n.id === selectedResearch)
    : null;

  return (
    <Box fillPositionedParent>
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
              Research Progress
            </Tabs.Tab>
          </Tabs>
        </Stack.Item>
        <Stack.Item grow>
          {tab === 'tree' && (
            <ResearchTreeTab
              researchTree={researchTree}
              selectedResearch={selectedResearch}
              researchProgress={researchProgress}
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
    </Box>
  );
};

// Research Tree Tab - Shows all research in a visual tree
const ResearchTreeTab = (props, context) => {
  const { act } = useBackend(context);
  const { researchTree, selectedResearch, researchProgress } = props;

  // Group research by tier
  const tiers = {};
  researchTree.forEach(node => {
    if (!tiers[node.tier]) {
      tiers[node.tier] = [];
    }
    tiers[node.tier].push(node);
  });

  return (
    <Section fill scrollable title="Research Tree">
      <Stack vertical fill>
        {Object.keys(tiers).sort((a, b) => a - b).map(tier => (
          <Stack.Item key={tier}>
            <Box bold mb={1}>Tier {tier}</Box>
            <Stack wrap>
              {tiers[tier].map(node => (
                <Stack.Item key={node.id} basis="200px" mb={1} mr={1}>
                  <ResearchNode
                    node={node}
                    selected={selectedResearch === node.id}
                    progress={researchProgress[node.id] || 0}
                  />
                </Stack.Item>
              ))}
            </Stack>
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

// Individual research node display
const ResearchNode = (props, context) => {
  const { act } = useBackend(context);
  const { node, selected, progress } = props;

  const statusColor = STATUS_COLORS[node.status];
  const statusLabel = STATUS_LABELS[node.status];
  const progressPercent = node.cost > 0 ? (progress / node.cost) * 100 : 0;

  return (
    <Box
      style={{
        border: selected ? '2px solid #ffff00' : '1px solid ' + statusColor,
        borderRadius: '4px',
        padding: '8px',
        backgroundColor: 'rgba(0, 0, 0, 0.5)',
        cursor: node.status === RESEARCH_AVAILABLE ? 'pointer' : 'default',
        opacity: node.status === RESEARCH_LOCKED ? 0.6 : 1,
      }}
      onClick={() => {
        if (node.status === RESEARCH_AVAILABLE) {
          act('selectResearch', { nodeId: node.id });
        }
      }}>
      <Box bold color={statusColor} mb={1}>
        {node.name}
      </Box>
      <Box fontSize="11px" mb={1} style={{ minHeight: '32px' }}>
        {node.desc}
      </Box>
      <Box fontSize="10px" color="label" mb={1}>
        Status: {statusLabel}
      </Box>
      {node.status !== RESEARCH_LOCKED && (
        <ProgressBar
          value={progressPercent}
          maxValue={100}
          color={node.status === RESEARCH_COMPLETED ? 'good' : 'blue'}>
          {progress}/{node.cost}
        </ProgressBar>
      )}
      {node.prerequisites && node.prerequisites.length > 0 && (
        <Box fontSize="10px" color="label" mt={1}>
          Requires: {node.prerequisites.join(', ')}
        </Box>
      )}
      {node.favoredTraits && Object.keys(node.favoredTraits).length > 0 && (
        <Box fontSize="10px" color="green" mt={1}>
          Favored: {Object.keys(node.favoredTraits).join(', ')}
        </Box>
      )}
      {node.requiredTraits && node.requiredTraits.length > 0 && (
        <Box fontSize="10px" color="orange" mt={1}>
          Required: {node.requiredTraits.join(', ')}
        </Box>
      )}
    </Box>
  );
};

// Samples Tab - Shows stored body parts
const SamplesTab = (props, context) => {
  const { act } = useBackend(context);
  const { partsList, selectedResearch, currentResearch, storedParts } = props;

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
            Process One
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
          {currentResearch?.requiredTraits && currentResearch.requiredTraits.length > 0 && (
            <Box fontSize="11px" color="orange">
              Required traits: {currentResearch.requiredTraits.join(', ')}
            </Box>
          )}
          {currentResearch?.favoredTraits && Object.keys(currentResearch.favoredTraits).length > 0 && (
            <Box fontSize="11px" color="green">
              Bonus traits: {Object.keys(currentResearch.favoredTraits).join(', ')}
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
          Select a research project from the Research Tree tab to begin processing samples.
        </Box>
      )}
      {partsList.length === 0 ? (
        <Box color="label" italic>
          No samples stored. Use the R-Corp Harvester to mark enemies, then kill them to collect samples.
        </Box>
      ) : (
        <Stack vertical>
          {partsList.map((part, index) => (
            <Stack.Item key={index}>
              <Box
                p={1}
                mb={1}
                backgroundColor="rgba(0, 0, 0, 0.3)"
                style={{ borderRadius: '4px' }}>
                <Box bold>{part.name}</Box>
                <Box fontSize="11px" color="label">
                  Source: {part.source}
                </Box>
                <Box fontSize="11px" color="label">
                  Base Value: {part.baseValue} points
                </Box>
                {part.traits && part.traits.length > 0 && (
                  <Box fontSize="11px" mt={1}>
                    Traits: {part.traits.join(', ')}
                  </Box>
                )}
              </Box>
            </Stack.Item>
          ))}
        </Stack>
      )}
    </Section>
  );
};

// Progress Tab - Shows current research progress
const ProgressTab = (props, context) => {
  const { act } = useBackend(context);
  const { currentResearch, researchProgress, selectedResearch } = props;

  if (!selectedResearch || !currentResearch) {
    return (
      <Section fill title="Research Progress">
        <Box color="label" italic>
          No research selected. Choose a research project from the Research Tree tab.
        </Box>
      </Section>
    );
  }

  const progress = researchProgress[selectedResearch] || 0;
  const progressPercent = currentResearch.cost > 0
    ? (progress / currentResearch.cost) * 100
    : 0;

  return (
    <Section fill title="Research Progress">
      <LabeledList>
        <LabeledList.Item label="Research">
          {currentResearch.name}
        </LabeledList.Item>
        <LabeledList.Item label="Description">
          {currentResearch.desc}
        </LabeledList.Item>
        <LabeledList.Item label="Tier">
          {currentResearch.tier}
        </LabeledList.Item>
        <LabeledList.Item label="Progress">
          <ProgressBar
            value={progressPercent}
            maxValue={100}
            color="blue">
            {progress}/{currentResearch.cost} points
          </ProgressBar>
        </LabeledList.Item>
        {currentResearch.requiredTraits && currentResearch.requiredTraits.length > 0 && (
          <LabeledList.Item label="Required Traits">
            <Box color="orange">
              {currentResearch.requiredTraits.join(', ')}
            </Box>
          </LabeledList.Item>
        )}
        {currentResearch.favoredTraits && Object.keys(currentResearch.favoredTraits).length > 0 && (
          <LabeledList.Item label="Favored Traits">
            <Box color="green">
              {Object.keys(currentResearch.favoredTraits).map(trait => (
                <Box key={trait}>
                  {trait}: +{Math.round(currentResearch.favoredTraits[trait] * 100)}%
                </Box>
              ))}
            </Box>
          </LabeledList.Item>
        )}
        {currentResearch.negativeTraits && Object.keys(currentResearch.negativeTraits).length > 0 && (
          <LabeledList.Item label="Negative Traits">
            <Box color="bad">
              {Object.keys(currentResearch.negativeTraits).map(trait => (
                <Box key={trait}>
                  {trait}: {Math.round(currentResearch.negativeTraits[trait] * 100)}%
                </Box>
              ))}
            </Box>
          </LabeledList.Item>
        )}
        {currentResearch.prerequisites && currentResearch.prerequisites.length > 0 && (
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
