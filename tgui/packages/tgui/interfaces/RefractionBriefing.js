import { useBackend, useLocalState } from '../backend';
import { Box, Button, LabeledList, Section, Stack } from '../components';
import { Window } from '../layouts';

const damageTypeColor = type => {
  switch (type) {
    case 'RED_DAMAGE':
    case 'red':
      return '#ef4444';
    case 'WHITE_DAMAGE':
    case 'white':
      return '#cbd5e1';
    case 'BLACK_DAMAGE':
    case 'black':
      return '#a855f7';
    case 'PALE_DAMAGE':
    case 'pale':
      return '#38bdf8';
    default:
      return '#9ca3af';
  }
};

const cadenceFromMob = mob => {
  if (mob.attack_cooldown) {
    return `${(mob.attack_cooldown / 10).toFixed(1)}s`;
  }
  if (mob.rapid_melee && mob.rapid_melee > 1) {
    return `${mob.rapid_melee}x rapid`;
  }
  return '1.0s';
};

const tilesPerSecond = moveDelay => {
  if (!moveDelay || moveDelay <= 0) return '?';
  return (10 / moveDelay).toFixed(2);
};

const MobCardSilhouette = props => {
  const { mob, large } = props;
  const size = large ? '160px' : '64px';
  return (
    <Box>
      {mob.icon && (
        <img
          src={`data:image/jpeg;base64,${mob.icon}`}
          style={{
            'height': size,
            'filter': 'brightness(0)',
            'image-rendering': 'pixelated',
          }}
        />
      )}
    </Box>
  );
};

const MobCardIcon = props => {
  const { mob, large } = props;
  const size = large ? '160px' : '64px';
  return (
    <Box>
      {mob.icon && (
        <img
          src={`data:image/jpeg;base64,${mob.icon}`}
          style={{
            'height': size,
            'image-rendering': 'pixelated',
          }}
        />
      )}
    </Box>
  );
};

const UnrevealedSummary = props => {
  const { mob } = props;
  return (
    <Box>
      <Stack>
        <Stack.Item>
          <Box
            color={damageTypeColor(mob.melee_damage_type)}
            fontSize="11px"
            bold>
            Melee: {(mob.melee_damage_type || '???').replace('_DAMAGE', '')}
          </Box>
          {mob.ranged_damage_type && (
            <Box
              color={damageTypeColor(mob.ranged_damage_type)}
              fontSize="11px"
              bold>
              Ranged: {mob.ranged_damage_type.replace('_DAMAGE', '')}
            </Box>
          )}
        </Stack.Item>
      </Stack>
      <Box mt={0.5} fontSize="11px" color="label">
        Weakness: <Box inline color="good">{mob.weakness}</Box>
      </Box>
      <Box mt={0.5} fontSize="11px" color="label">
        HP: ??? &bull; Speed: ???
      </Box>
    </Box>
  );
};

const RevealedSummary = props => {
  const { mob } = props;
  return (
    <Box fontSize="11px">
      <Box bold>{mob.name}</Box>
      <Box color="label">
        HP: {mob.health}/{mob.max_health}
      </Box>
      <Box color={damageTypeColor(mob.melee_damage_type)}>
        Melee: {mob.melee_damage_lower}&ndash;{mob.melee_damage_upper}
        {' '}{(mob.melee_damage_type || '').replace('_DAMAGE', '')}
      </Box>
    </Box>
  );
};

const ResistanceRow = props => {
  const { resistances } = props;
  if (!resistances) return null;
  return (
    <Box fontSize="11px">
      <Box inline color="#ef4444" mr={1}>RED {resistances.red}</Box>
      <Box inline color="#cbd5e1" mr={1}>WHITE {resistances.white}</Box>
      <Box inline color="#a855f7" mr={1}>BLACK {resistances.black}</Box>
      <Box inline color="#38bdf8">PALE {resistances.pale}</Box>
    </Box>
  );
};

const FullDataSheet = props => {
  const { mob } = props;
  return (
    <Section title={mob.name || 'Unknown'}>
      <Stack>
        <Stack.Item>
          <MobCardIcon mob={mob} large />
        </Stack.Item>
        <Stack.Item grow={1}>
          <LabeledList>
            <LabeledList.Item label="HP">
              {mob.health} / {mob.max_health}
            </LabeledList.Item>
            <LabeledList.Item label="Move delay">
              {mob.move_to_delay} ({tilesPerSecond(mob.move_to_delay)} t/s)
            </LabeledList.Item>
            <LabeledList.Item label="Resistances">
              <ResistanceRow resistances={mob.resistances} />
            </LabeledList.Item>
            <LabeledList.Item label="Melee">
              <Box color={damageTypeColor(mob.melee_damage_type)}>
                {mob.melee_damage_lower}&ndash;{mob.melee_damage_upper}
                {' '}{(mob.melee_damage_type || '').replace('_DAMAGE', '')}
                , every {cadenceFromMob(mob)}
              </Box>
            </LabeledList.Item>
            {mob.is_ranged && (
              <LabeledList.Item label="Ranged">
                <Box color={damageTypeColor(mob.ranged_damage_type)}>
                  {mob.ranged_damage}{' '}
                  {(mob.ranged_damage_type || '').replace('_DAMAGE', '')}
                  , every {(mob.ranged_cooldown_time / 10).toFixed(1)}s
                </Box>
                {mob.rapid > 0 && (
                  <Box color="label">
                    Burst: {mob.rapid} shots @{' '}
                    {(mob.rapid_fire_delay / 10).toFixed(2)}s
                  </Box>
                )}
              </LabeledList.Item>
            )}
          </LabeledList>
          {mob.tip && (
            <Box mt={1} p={1} backgroundColor="rgba(34, 197, 94, 0.1)">
              <Box bold color="good" fontSize="11px">Tip</Box>
              <Box fontSize="11px">{mob.tip}</Box>
            </Box>
          )}
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const MobCard = props => {
  const { mob, onClick } = props;
  return (
    <Box
      p={1}
      mr={0.5}
      mb={0.5}
      style={{
        'cursor': 'pointer',
        'border-radius': '4px',
        'min-width': '140px',
      }}
      backgroundColor="rgba(255, 255, 255, 0.05)"
      onClick={onClick}>
      {mob.revealed ? (
        <Stack vertical>
          <Stack.Item>
            <MobCardIcon mob={mob} />
          </Stack.Item>
          <Stack.Item>
            <RevealedSummary mob={mob} />
          </Stack.Item>
        </Stack>
      ) : (
        <Stack vertical>
          <Stack.Item>
            <MobCardSilhouette mob={mob} />
          </Stack.Item>
          <Stack.Item>
            <UnrevealedSummary mob={mob} />
          </Stack.Item>
        </Stack>
      )}
    </Box>
  );
};

const MobModal = props => {
  const { mob, onClose } = props;
  return (
    <Box
      position="absolute"
      top={0}
      left={0}
      right={0}
      bottom={0}
      backgroundColor="rgba(0, 0, 0, 0.75)"
      style={{ 'z-index': 50 }}
      onClick={onClose}>
      <Box
        position="absolute"
        top="50%"
        left="50%"
        width="520px"
        style={{ transform: 'translate(-50%, -50%)' }}
        onClick={e => e.stopPropagation()}>
        {mob.revealed ? (
          <FullDataSheet mob={mob} />
        ) : (
          <Section
            title="Unidentified Hostile"
            buttons={<Button icon="times" onClick={onClose} />}>
            <Stack>
              <Stack.Item>
                <MobCardSilhouette mob={mob} large />
              </Stack.Item>
              <Stack.Item grow={1}>
                <UnrevealedSummary mob={mob} />
                <Box mt={1} color="label" fontSize="11px">
                  Engage this hostile in combat to reveal its full data.
                </Box>
              </Stack.Item>
            </Stack>
          </Section>
        )}
      </Box>
    </Box>
  );
};

export const RefractionBriefing = (props, context) => {
  const { data } = useBackend(context);
  const sector = data.sector;
  const sectorIndex = data.sector_index || 1;
  const nodes = data.nodes || [];
  const [modalMob, setModalMob] = useLocalState(context, 'modalMob', null);
  if (data.finished) {
    return (
      <Window width={640} height={300} theme="syndicate">
        <Window.Content>
          <Section title="Briefing">
            <Box color="good">All sectors cleared. Return to the hub.</Box>
          </Section>
        </Window.Content>
      </Window>
    );
  }
  return (
    <Window width={760} height={640} theme="syndicate">
      <Window.Content>
        <Section
          title={sector ? sector.name : `Sector ${sectorIndex}`}
          buttons={
            <Box color="label">
              {sector && sector.faction}
            </Box>
          }>
          {sector && sector.description && (
            <Box mb={1} color="label">{sector.description}</Box>
          )}
          {sector && sector.damage_hints && (
            <Box mb={1} color="average">{sector.damage_hints}</Box>
          )}
          {sector && sector.is_boss && (
            <Box mb={1} color="bad" bold>
              FINAL SECTOR &mdash; boss encounter ahead.
            </Box>
          )}
          {nodes.map((node, i) => (
            <Section
              key={i}
              title={node.name}
              level={2}>
              {node.description && (
                <Box mb={0.5} color="label">{node.description}</Box>
              )}
              <Stack wrap>
                {(node.mobs || []).map((mob, j) => (
                  <Stack.Item key={j}>
                    <MobCard mob={mob} onClick={() => setModalMob(mob)} />
                  </Stack.Item>
                ))}
              </Stack>
            </Section>
          ))}
        </Section>
        {modalMob && (
          <MobModal mob={modalMob} onClose={() => setModalMob(null)} />
        )}
      </Window.Content>
    </Window>
  );
};
