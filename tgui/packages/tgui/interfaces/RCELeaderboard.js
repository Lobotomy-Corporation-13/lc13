import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Collapsible,
  Dimmer,
  Icon,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Table,
  Tabs,
} from '../components';
import { Window } from '../layouts';

export var RCELeaderboard = function (props, context) {
  var _useBackend = useBackend(context);
  var act = _useBackend.act;
  var data = _useBackend.data;

  var _useLocalState = useLocalState(context, 'tab', 'current');
  var tab = _useLocalState[0];
  var setTab = _useLocalState[1];

  var error = data.error;
  var current = data.current || {};
  var history = data.history || [];
  var all_time = data.all_time || {};

  if (error) {
    return (
      <Window title="R-Corp Expedition Records" width={700} height={600}>
        <Window.Content>
          <NoticeBox danger>{error}</NoticeBox>
        </Window.Content>
      </Window>
    );
  }

  return (
    <Window title="R-Corp Expedition Records" width={750} height={650}>
      <Window.Content scrollable>
        <Tabs fluid>
          <Tabs.Tab
            selected={tab === 'current'}
            onClick={function () {
              setTab('current');
            }}
          >
            Current Expedition
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 'history'}
            onClick={function () {
              setTab('history');
            }}
          >
            History ({history.length})
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 'alltime'}
            onClick={function () {
              setTab('alltime');
            }}
          >
            All-Time Records
          </Tabs.Tab>
        </Tabs>

        {tab === 'current' && <CurrentTab data={data} />}
        {tab === 'history' && <HistoryTab history={history} />}
        {tab === 'alltime' && <AllTimeTab allTime={all_time} />}
      </Window.Content>
    </Window>
  );
};

var CurrentTab = function (props, context) {
  var data = props.data;
  var current = data.current || {};
  var current_factories = data.current_factories || [];
  var current_mobs = data.current_mobs || [];
  var current_players = data.current_players || [];
  var materials = current.materials_consumed || {};

  return (
    <Box>
      <Section title={'Expedition #' + current.expedition_number}>
        <LabeledList>
          <LabeledList.Item label="Round Time">
            {current.round_time}
          </LabeledList.Item>
          <LabeledList.Item label="Players">
            {current.players_participated}
          </LabeledList.Item>
          <LabeledList.Item label="Heart Killed">
            {current.heart_killed ? (
              <Box color="good">YES</Box>
            ) : (
              <Box color="bad">NO</Box>
            )}
          </LabeledList.Item>
        </LabeledList>
      </Section>

      <Section title="Combat Statistics">
        <LabeledList>
          <LabeledList.Item label="Total Mob Kills">
            <Box color="good" bold>
              {current.total_mob_kills}
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Grenades Primed">
            {current.grenades_primed || 0}
          </LabeledList.Item>
          {current.most_deaths_player && (
            <LabeledList.Item label="Most Deaths">
              <Box color="bad">
                {current.most_deaths_player.name} ({current.most_deaths_player.deaths} deaths)
              </Box>
            </LabeledList.Item>
          )}
        </LabeledList>
        {current_mobs.length > 0 && (
          <Collapsible title="Kill Breakdown">
            <Table>
              <Table.Row header>
                <Table.Cell>Enemy Type</Table.Cell>
                <Table.Cell>Kills</Table.Cell>
              </Table.Row>
              {current_mobs.map(function (mob, index) {
                return (
                  <Table.Row key={index}>
                    <Table.Cell>{mob.name}</Table.Cell>
                    <Table.Cell>{mob.kills}</Table.Cell>
                  </Table.Row>
                );
              })}
            </Table>
          </Collapsible>
        )}
      </Section>

      <Section title="Production Statistics">
        <LabeledList>
          <LabeledList.Item label="Total Items Produced">
            <Box color="good" bold>
              {current.total_items_produced}
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Conveyor Belts Placed">
            {current.conveyor_belts_placed || 0}
          </LabeledList.Item>
          <LabeledList.Item label="Surgeries Completed">
            {current.surgeries_completed || 0}
          </LabeledList.Item>
        </LabeledList>
        <Box mt={1}>
          <LabeledList>
            <LabeledList.Item label="Green">
              {materials.green || 0}
            </LabeledList.Item>
            <LabeledList.Item label="Red">{materials.red || 0}</LabeledList.Item>
            <LabeledList.Item label="Blue">
              {materials.blue || 0}
            </LabeledList.Item>
            <LabeledList.Item label="Purple">
              {materials.purple || 0}
            </LabeledList.Item>
            <LabeledList.Item label="Orange">
              {materials.orange || 0}
            </LabeledList.Item>
            <LabeledList.Item label="Silver">
              {materials.silver || 0}
            </LabeledList.Item>
          </LabeledList>
        </Box>
        {current_factories.length > 0 && (
          <Collapsible title="Factory Breakdown">
            <Table>
              <Table.Row header>
                <Table.Cell>Factory</Table.Cell>
                <Table.Cell>Items</Table.Cell>
              </Table.Row>
              {current_factories.map(function (factory, index) {
                return (
                  <Table.Row key={index}>
                    <Table.Cell>{factory.name}</Table.Cell>
                    <Table.Cell>{factory.items_produced}</Table.Cell>
                  </Table.Row>
                );
              })}
            </Table>
          </Collapsible>
        )}
      </Section>

      <Section title="Participants">
        {current_players.length > 0 ? (
          <Table>
            <Table.Row header>
              <Table.Cell>Name</Table.Cell>
              <Table.Cell>Job</Table.Cell>
              <Table.Cell>CKey</Table.Cell>
            </Table.Row>
            {current_players.map(function (player, index) {
              return (
                <Table.Row key={index}>
                  <Table.Cell>{player.name}</Table.Cell>
                  <Table.Cell>{player.job}</Table.Cell>
                  <Table.Cell color="label">{player.ckey}</Table.Cell>
                </Table.Row>
              );
            })}
          </Table>
        ) : (
          <Box color="label">No participants recorded yet.</Box>
        )}
      </Section>
    </Box>
  );
};

var HistoryTab = function (props, context) {
  var history = props.history || [];

  var _useLocalState = useLocalState(context, 'selectedExpedition', null);
  var selectedExpedition = _useLocalState[0];
  var setSelectedExpedition = _useLocalState[1];

  if (history.length === 0) {
    return (
      <Section title="Expedition History">
        <NoticeBox>No expedition history available.</NoticeBox>
      </Section>
    );
  }

  return (
    <Section title="Expedition History">
      <Table>
        <Table.Row header>
          <Table.Cell>Expedition</Table.Cell>
          <Table.Cell>Date</Table.Cell>
          <Table.Cell>Duration</Table.Cell>
          <Table.Cell>Result</Table.Cell>
          <Table.Cell>Players</Table.Cell>
          <Table.Cell>Survivors</Table.Cell>
          <Table.Cell>Kills</Table.Cell>
          <Table.Cell>Items</Table.Cell>
        </Table.Row>
        {history.map(function (expedition, index) {
          var resultColor = 'label';
          if (expedition.heart_killed) {
            resultColor = 'good';
          } else if (
            expedition.end_condition === 'Total Loss' ||
            expedition.end_condition === 'Last Stand Failed'
          ) {
            resultColor = 'bad';
          } else if (expedition.end_condition === 'Shuttle Escape') {
            resultColor = 'average';
          }

          return (
            <Table.Row key={index}>
              <Table.Cell bold>#{expedition.expedition_number}</Table.Cell>
              <Table.Cell color="label">{expedition.timestamp}</Table.Cell>
              <Table.Cell>{expedition.duration}</Table.Cell>
              <Table.Cell color={resultColor}>{expedition.end_condition}</Table.Cell>
              <Table.Cell>{expedition.participants}</Table.Cell>
              <Table.Cell color={expedition.survivors > 0 ? 'good' : 'bad'}>
                {expedition.survivors}/{expedition.participants}
              </Table.Cell>
              <Table.Cell>{expedition.mob_kills}</Table.Cell>
              <Table.Cell>{expedition.items_produced}</Table.Cell>
            </Table.Row>
          );
        })}
      </Table>
    </Section>
  );
};

var AllTimeTab = function (props, context) {
  var allTime = props.allTime || {};
  var materials = allTime.total_materials_consumed || {};

  return (
    <Box>
      <Section title="All-Time Statistics">
        <Stack>
          <Stack.Item grow>
            <Section title="Expeditions">
              <LabeledList>
                <LabeledList.Item label="Total Expeditions">
                  {allTime.total_expeditions || 0}
                </LabeledList.Item>
                <LabeledList.Item label="Victories (Heart Killed)">
                  <Box color="good">{allTime.total_victories || 0}</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Shuttle Escapes">
                  <Box color="average">{allTime.total_shuttle_escapes || 0}</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Total Losses">
                  <Box color="bad">{allTime.total_all_died || 0}</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Last Stand Failures">
                  <Box color="bad">{allTime.total_all_died_lastwave || 0}</Box>
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section title="Personnel">
              <LabeledList>
                <LabeledList.Item label="Total Survivals">
                  <Box color="good">{allTime.total_player_survivals || 0}</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Total Deaths">
                  <Box color="bad">{allTime.total_player_deaths || 0}</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Most Participants (Round)">
                  {allTime.most_participants || 0}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
        </Stack>
      </Section>

      <Section title="Combat Records">
        <LabeledList>
          <LabeledList.Item label="Total Enemies Eliminated">
            <Box color="good" bold fontSize={1.2}>
              {allTime.total_mob_kills || 0}
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Highest Kills (Single Round)">
            {allTime.highest_mob_kills_round || 0}
          </LabeledList.Item>
          <LabeledList.Item label="Total Grenades Primed">
            {allTime.total_grenades_primed || 0}
          </LabeledList.Item>
        </LabeledList>
      </Section>

      <Section title="Production Records">
        <LabeledList>
          <LabeledList.Item label="Total Items Produced">
            <Box color="good" bold fontSize={1.2}>
              {allTime.total_items_produced || 0}
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Highest Production (Single Round)">
            {allTime.highest_items_produced_round || 0}
          </LabeledList.Item>
          <LabeledList.Item label="Total Conveyor Belts Placed">
            {allTime.total_conveyor_belts_placed || 0}
          </LabeledList.Item>
          <LabeledList.Item label="Total Surgeries Completed">
            {allTime.total_surgeries_completed || 0}
          </LabeledList.Item>
        </LabeledList>
        <Box mt={2}>
          <Box bold mb={1}>
            Total Materials Consumed:
          </Box>
          <Stack>
            <Stack.Item grow>
              <LabeledList>
                <LabeledList.Item label="Green">
                  {materials.green || 0}
                </LabeledList.Item>
                <LabeledList.Item label="Red">
                  {materials.red || 0}
                </LabeledList.Item>
                <LabeledList.Item label="Blue">
                  {materials.blue || 0}
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
            <Stack.Item grow>
              <LabeledList>
                <LabeledList.Item label="Purple">
                  {materials.purple || 0}
                </LabeledList.Item>
                <LabeledList.Item label="Orange">
                  {materials.orange || 0}
                </LabeledList.Item>
                <LabeledList.Item label="Silver">
                  {materials.silver || 0}
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
          </Stack>
        </Box>
      </Section>
    </Box>
  );
};
