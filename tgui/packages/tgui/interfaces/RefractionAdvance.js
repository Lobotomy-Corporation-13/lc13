import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Stack } from '../components';
import { Window } from '../layouts';
import { RecordsModal } from './RefractionRailway';

const formatDs = ds => {
  if (!ds || ds <= 0) {
    return '0:00.0';
  }
  const totalSeconds = ds * 0.1;
  const min = Math.floor(totalSeconds / 60);
  const sec = totalSeconds - min * 60;
  const secStr
    = sec < 10 ? '0' + sec.toFixed(1) : sec.toFixed(1);
  return `${min}:${secStr}`;
};

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

const SectorResultRow = props => {
  const { sector } = props;
  const players = sector.players || [];
  const rooms = sector.rooms || [];
  return (
    <Box
      p={1}
      mb={0.5}
      backgroundColor="rgba(255, 255, 255, 0.04)"
      style={{ 'border-radius': '4px' }}>
      <Stack>
        <Stack.Item grow={1}>
          <Box bold>
            {`Sector ${sector.index}: ${sector.name || ''}`}
          </Box>
          <Box color="label" fontSize="11px">
            {`Time: ${formatDs(sector.time_ds)}`}
          </Box>
        </Stack.Item>
      </Stack>
      {!!rooms.length && (
        <Box mt={0.3} ml={1}>
          {rooms.map((room, ri) => (
            <Stack key={ri}>
              <Stack.Item grow={1} fontSize="11px" color="label">
                {`└ ${room.name || room.room_id}`}
              </Stack.Item>
              <Stack.Item fontSize="11px" color="label">
                {formatDs(room.time_ds)}
              </Stack.Item>
            </Stack>
          ))}
        </Box>
      )}
      <Box mt={0.5}>
        {players.length === 0 && (
          <Box color="label" fontSize="11px">
            (no loadouts recorded)
          </Box>
        )}
        {players.map(p => (
          <Box key={p.ckey} mt={0.5}>
            <Stack>
              <Stack.Item grow={1}>
                <Box fontSize="11px" bold>
                  {p.name || p.ckey}
                </Box>
              </Stack.Item>
              <Stack.Item>
                <LoadoutIcons
                  icons={p.loadout_icons || [null, null, null]}
                />
              </Stack.Item>
            </Stack>
          </Box>
        ))}
      </Box>
    </Box>
  );
};

const FinishedView = (props, context) => {
  const { act, data } = useBackend(context);
  const results = data.results || {};
  const sectors = results.sectors || [];
  return (
    <Section
      title={`${results.line_name || 'Refraction Line'} — Cleared!`}>
      <Box mb={1} bold color="good">
        {`Total time: ${formatDs(results.total_ds)}`}
      </Box>
      <Section scrollable fill height="320px">
        {sectors.map(s => (
          <SectorResultRow key={s.index} sector={s} />
        ))}
        {sectors.length === 0 && (
          <Box color="label">No sectors recorded.</Box>
        )}
      </Section>
      <Box mt={1}>
        <Button
          fluid
          icon="door-open"
          content="Return to Lobby"
          color="good"
          onClick={() => act('return_to_lobby')}
        />
        <Box color="label" fontSize="11px" mt={0.5}>
          Returns everyone to where they joined from. All E.G.O.
          weapons and armor issued for this run are surrendered on
          the way out.
        </Box>
      </Box>
    </Section>
  );
};

const StagingView = (props, context) => {
  const { act, data } = useBackend(context);
  const members = data.members || [];
  const isOwner = data.is_lobby_owner;
  const isOwnerActive = data.is_owner_active;
  const allReady = data.all_ready;
  const myReady = (members.find(m => m.ckey === data.my_ckey) || {}).ready;
  const nextSectorName = data.next_sector_name;
  const nextSectorIndex = data.next_sector_index;
  const sectionCount = data.section_count;
  const myLoadoutSet = data.my_loadout_set;
  const lastSectorTimeDs = data.last_sector_time_ds || 0;
  const currentSector = data.current_sector || 0;
  // Anyone can pull the rip cord if the owner is AFK / disconnected.
  const canAbandon = isOwner || !isOwnerActive;
  const [abandonArmed, setAbandonArmed] = useLocalState(
    context,
    'abandonArmed',
    false
  );
  const [forceArmed, setForceArmed] = useLocalState(
    context,
    'forceArmed',
    false
  );
  const [endEarlyArmed, setEndEarlyArmed] = useLocalState(
    context,
    'endEarlyArmed',
    false
  );
  const earlyPercent = sectionCount > 0
    ? Math.round((currentSector / sectionCount) * 100)
    : 0;
  return (
    <Section
      title={`Sector ${nextSectorIndex}/${sectionCount}: ${
        nextSectorName || '...'
      }`}>
      {currentSector > 0 && lastSectorTimeDs > 0 && (
        <Box
          mb={1}
          p={1}
          backgroundColor="rgba(0, 200, 0, 0.08)"
          color="good"
          style={{ 'border-radius': '4px' }}>
          {`Sector ${currentSector} cleared in ${formatDs(lastSectorTimeDs)}`}
        </Box>
      )}
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
      {isOwner && (
        <Box mt={1}>
          <Button
            fluid
            icon={forceArmed ? 'exclamation-triangle' : 'forward'}
            color="average"
            content={
              forceArmed
                ? 'Click again to confirm: FORCE START'
                : 'Force Start Sector (skip ready checks)'
            }
            onClick={() => {
              if (forceArmed) {
                setForceArmed(false);
                act('force_begin_sector');
              } else {
                setForceArmed(true);
              }
            }}
          />
          <Box color="label" fontSize="11px" mt={0.5}>
            Bypasses the ready-up gate so an AFK member can&apos;t hold up
            the sector. Unprepared members go in with whatever loadout
            they have (possibly none).
          </Box>
        </Box>
      )}
      {canAbandon && (
        <Box mt={1}>
          <Button
            fluid
            icon={abandonArmed ? 'exclamation-triangle' : 'door-closed'}
            color="bad"
            content={
              abandonArmed
                ? 'Click again to confirm: ABANDON RUN'
                : 'Abandon Run'
            }
            onClick={() => {
              if (abandonArmed) {
                setAbandonArmed(false);
                act('abandon_run');
              } else {
                setAbandonArmed(true);
              }
            }}
          />
          <Box color="label" fontSize="11px" mt={0.5}>
            Scraps the run, returns the team to the main lobby, and frees
            the loaded Z-level for other lobbies. No rewards.
            {!isOwner && !isOwnerActive && (
              <Box color="bad" mt={0.5}>
                Owner is AFK / disconnected — anyone can end the run.
              </Box>
            )}
          </Box>
        </Box>
      )}
      {isOwner && (
        <Box mt={1}>
          <Button
            fluid
            icon={endEarlyArmed ? 'exclamation-triangle' : 'flag'}
            color="average"
            content={
              endEarlyArmed
                ? 'Click again to confirm: END EARLY'
                : 'End Run Early (partial reward)'
            }
            onClick={() => {
              if (endEarlyArmed) {
                setEndEarlyArmed(false);
                act('end_run_early');
              } else {
                setEndEarlyArmed(true);
              }
            }}
          />
          <Box color="label" fontSize="11px" mt={0.5}>
            Ends the run cleanly and pays a fraction of the normal
            Starlight based on sectors cleared (
            {currentSector}/{sectionCount} ={' '}
            {earlyPercent}%). Does not unlock achievements for the
            line.
          </Box>
        </Box>
      )}
    </Section>
  );
};

export const RefractionAdvance = (props, context) => {
  const { data } = useBackend(context);
  const isFinished = data.lobby_state === 'lobby_finished';
  const [showRecords, setShowRecords] = useLocalState(
    context,
    'showRecords',
    false
  );
  return (
    <Window width={640} height={620} theme="syndicate">
      <Window.Content>
        {!isFinished && (
          <Box mb={1} textAlign="right">
            <Button
              icon="trophy"
              content="Records"
              onClick={() => setShowRecords(true)}
            />
          </Box>
        )}
        {isFinished ? <FinishedView /> : <StagingView />}
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
