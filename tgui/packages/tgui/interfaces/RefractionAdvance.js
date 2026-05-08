import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Stack } from '../components';
import { Window } from '../layouts';
import { RecordsModal } from './RefractionRailway';

const LoadoutIcons = props => {
  const { icons } = props;
  return (
    <Stack>
      {icons.map((icon, i) => (
        <Stack.Item key={i}>
          {icon ? (
            <img
              src={`data:image/jpeg;base64,${icon}`}
              style={{
                'height': '32px',
                'image-rendering': 'pixelated',
              }}
            />
          ) : (
            <Box
              width="32px"
              height="32px"
              backgroundColor="rgba(255, 255, 255, 0.05)"
              textAlign="center"
              color="label"
              fontSize="10px">
              ?
            </Box>
          )}
        </Stack.Item>
      ))}
    </Stack>
  );
};

const MemberRow = props => {
  const { member } = props;
  const dot = member.ready ? 'good' : 'bad';
  return (
    <Box
      p={1}
      mb={0.5}
      backgroundColor="rgba(255, 255, 255, 0.04)"
      style={{ 'border-radius': '4px' }}>
      <Stack>
        <Stack.Item width="20px" color={dot} bold>
          &bull;
        </Stack.Item>
        <Stack.Item grow={1}>
          <Box bold>{member.name}</Box>
          <Box color="label" fontSize="11px">
            {member.ckey}
            {member.is_owner && ' (owner)'}
            {!member.is_alive && ' [DEAD]'}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <LoadoutIcons icons={member.loadout_icons || [null, null, null]} />
        </Stack.Item>
      </Stack>
    </Box>
  );
};

export const RefractionAdvance = (props, context) => {
  const { act, data } = useBackend(context);
  const members = data.members || [];
  const isOwner = data.is_lobby_owner;
  const allReady = data.all_ready;
  const myReady = (members.find(m => m.ckey === data.my_ckey) || {}).ready;
  const nextSectorName = data.next_sector_name;
  const nextSectorIndex = data.next_sector_index;
  const sectionCount = data.section_count;
  const myLoadoutSet = data.my_loadout_set;
  const [showRecords, setShowRecords] = useLocalState(
    context,
    'showRecords',
    false
  );
  return (
    <Window width={640} height={560} theme="syndicate">
      <Window.Content>
        <Section
          title={`Sector ${nextSectorIndex}/${sectionCount}: ${
            nextSectorName || '...'
          }`}
          buttons={
            <Button
              icon="trophy"
              content="Records"
              onClick={() => setShowRecords(true)}
            />
          }>
          <Box mb={1}>
            {members.map(member => (
              <MemberRow key={member.ckey} member={member} />
            ))}
            {members.length === 0 && (
              <Box color="label">No members in this lobby.</Box>
            )}
          </Box>
          <Stack>
            <Stack.Item grow={1}>
              <Button
                fluid
                icon={myReady ? 'times' : 'check'}
                content={myReady ? 'Unready' : 'Ready Up'}
                color={myReady ? 'bad' : 'good'}
                disabled={!myLoadoutSet}
                onClick={() => act('toggle_ready')}
              />
              {!myLoadoutSet && (
                <Box color="bad" fontSize="11px" mt={0.5}>
                  Confirm a loadout before readying up.
                </Box>
              )}
            </Stack.Item>
            <Stack.Item grow={1}>
              <Button
                fluid
                icon="play"
                content={`Begin Sector ${nextSectorIndex}`}
                color="good"
                disabled={!isOwner || !allReady}
                onClick={() => act('begin_sector')}
              />
              {isOwner && !allReady && (
                <Box color="label" fontSize="11px" mt={0.5}>
                  Waiting on every live member to ready up.
                </Box>
              )}
            </Stack.Item>
          </Stack>
        </Section>
        {showRecords && (
          <RecordsModal
            lineId={data.line_id}
            lineName={data.line_id}
            leaderboard={data.leaderboard}
            onClose={() => setShowRecords(false)}
          />
        )}
      </Window.Content>
    </Window>
  );
};
