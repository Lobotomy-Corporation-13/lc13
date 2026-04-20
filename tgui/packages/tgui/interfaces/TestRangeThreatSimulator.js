import { useBackend, useLocalState } from '../backend';
import { Button, Divider, LabeledList, Section, Flex, Tabs, Stack, Box, Icon, Collapsible, BlockQuote, ByondUi, Slider } from '../components';
import { FlexItem } from '../components/Flex';
import { Window } from '../layouts';

export const TestRangeThreatSimulator = (props, context) => {
  const { act, data } = useBackend(context);
  const { threats, arenas, map_ref, current_arena } = data;

  const [currentlyDetailedThreat, setCurrentlyDetailedThreat] = useLocalState(context, "currentlyDetailedThreat", null);
  const [mainTab, setMainTab] = useLocalState(context, "mainTab", 1);
  const [tuningSliders, setTuningSliders] = useLocalState(context, "tuningSliders", {});

  /* Returns a slider for the datum's tuning parameter,
  using its minimum and maximum values.
  */
  const GetDatumTuningSlider = datum => {

    const SetDatumTuning = (ref, val) => {
      let newSliders = { ...tuningSliders };
      newSliders[ref] = val;
      setTuningSliders(newSliders);
    };

    return (
      <Slider
        value={(tuningSliders[datum.reference]
          ? tuningSliders[datum.reference] : datum.tuning_min)}
        minValue={datum.tuning_min}
        maxValue={datum.tuning_limit}
        step={1}
        stepPixelSize={(250 / datum.tuning_limit)}
        onChange={(e, value) => { SetDatumTuning(datum.reference, value); }} />
    );
  };

  // 1-5 star icons to denote difficulty, colour depends on how many.
  const GetDifficultyStarIcons = difficulty => {
    let appropiate_color = (difficulty > 3 ? "red" : difficulty > 2 ? "orange" : difficulty > 1 ? "yellow" : "green");
    let icons = [];
    for (let i = 0; i < difficulty; i++) {
      icons.push(<Icon name="star" color={appropiate_color} />);
    }
    return (icons);
  };

  // Functional component: details of a selected threat.
  const SelectedThreatDetails = (props, context) => {
    const { datum } = props;

    return (
      <Flex direction="column">
        <Flex.Item>
          Name: {datum.name}
        </Flex.Item>
        <Flex.Item>
          Origin: {datum.origin} - {datum.origin_detailed}
        </Flex.Item>
        <Flex.Item>
          Estimated Difficulty: {GetDifficultyStarIcons(datum.difficulty)}
        </Flex.Item>
        <Divider />
        <Flex.Item>
          Description:
          <BlockQuote my={1}>
            {datum.desc}
          </BlockQuote>

        </Flex.Item>

        <Flex.Item my={1} grow>
          <Collapsible content="View Battle Guide">
            <BlockQuote inline style={{ 'white-space': 'pre-wrap' }}>
              {datum.battle_guide}
            </BlockQuote>
          </Collapsible>
        </Flex.Item>

        <Flex.Item>
          Currently spawned: {datum.max_spawns ? datum.current_spawns + "/" + datum.max_spawns : datum.current_spawns}
        </Flex.Item>

        {datum.tuning_name
        && (
        <Flex.Item my={3}>
          <Section title="Tuning">
            {datum.tuning_name + ":"}
            {GetDatumTuningSlider(datum)}

          </Section>
        </Flex.Item>
        )}

        <Flex.Item mt={2}>
          <Button color="green"
            onClick={() => act('spawn_threat',
              { chosen_threat: datum.reference,
                tuning: tuningSliders[datum.reference],
              })}>Spawn
          </Button>
        </Flex.Item>
        <Flex.Item mt={2}>
          <Button color="red"
            onClick={() => act('despawn_one',
              { chosen_threat: datum.reference,
              })}>Despawn One
          </Button>
        </Flex.Item>
        <Flex.Item mt={1}>
          <Button color="red"
            onClick={() => act('despawn_all',
              { chosen_threat: datum.reference,
              })}>Despawn All
          </Button>
        </Flex.Item>
      </Flex>

    );

  };

  // Functional component: shows up when no threat is selected.
  const EmptyThreatDetails = (props, context) => {
    return (
      <Flex>
        <BlockQuote>
          Please select a threat to view more information,
          adjust threat tuning (where applicable) or despawn existing instances.
        </BlockQuote>

      </Flex>
    );
  };

  /* Functional component: returns
  EmptyThreatDetails/SelectedThreatDetails as appropiate.
  */
  const ThreatDetails = (props, context) => {
    return (
      <Section scrollable fill title="Threat Details">
        {currentlyDetailedThreat !== null
          ? <SelectedThreatDetails datum={currentlyDetailedThreat} />
          : <EmptyThreatDetails />}
      </Section>
    );

  };


  // Functional component: threat entry in our list.
  const ThreatDatumEntry = (props, context) => {
    const { datum } = props;

    return (
      <Flex.Item grow={1}>
        <Divider />

        <Flex>
          <Flex.Item>
            <Box
              as="img"
              mb={1}
              src={`data:image/jpeg;base64,${datum.icon}`}
              height="72px"
              width="72px"
              style={{
                '-ms-interpolation-mode': 'nearest-neighbor',
              }} />
          </Flex.Item>

          <Flex.Item>
            <Divider vertical />
          </Flex.Item>

          <Flex.Item align="center" minWidth="28rem">
            <Flex direction="column">
              <Flex.Item textAlign="left" align="left">
                {datum.name}
              </Flex.Item>
              <Flex.Item align="left" textAlign="left">
                Difficulty: {GetDifficultyStarIcons(datum.difficulty)}
              </Flex.Item>
            </Flex>
          </Flex.Item>

          <Flex.Item>
            <Divider vertical />
          </Flex.Item>

          <Flex.Item align="center">

            <Flex direction="column">
              <Flex.Item my={1}>
                <Button fluid align="center"
                  content="View Details"
                  onClick={() => setCurrentlyDetailedThreat(datum)} />
              </Flex.Item>

              <Flex.Item>
                <Button fluid align="center"
                  content="Spawn"
                  color="green"
                  onClick={() => act('spawn_threat', { chosen_threat: datum.reference, tuning: tuningSliders[datum.reference] })} />
              </Flex.Item>

            </Flex>
          </Flex.Item>

        </Flex>
      </Flex.Item>

    );

  };

  // Functional component: our list of threats.
  const ThreatsList = (props, context) => {

    return (
      <Flex direction="column">
        {threats?.map(threat =>
          <ThreatDatumEntry datum={threat} key={threat.reference} />)}
      </Flex>

    );

  };

  /* Functional component: window content, including tabs,
  threat list (left) and threat details (right).
  */
  const ThreatsWindow = (props, context) => {

    return (

      <Window.Content scrollable>
        <MainTabs />
        <Flex minHeight="100%">
          <Flex.Item grow={3}>
            <Section scrollable fill minHeight="100%" minWidth="100%">
              <ThreatsList />
            </Section>

          </Flex.Item>
          <Flex.Item>
            <Divider vertical />
          </Flex.Item>
          <Flex.Item grow={2}>
            <ThreatDetails />
          </Flex.Item>
        </Flex>
      </Window.Content>
    );

  };


  // Functional component: our list of arenas.
  const ArenasList = (props, context) => {

    return (
      <Flex direction="column" fill>
        <Section title="Available Arenas" fill>

          {arenas.map(string => (<Button key={string} align="center" fluid content={string} onClick={() => { act('change_camera', { arena: string }); }} />))}

        </Section>
      </Flex>

    );

  };

  // Functional component: roughly emulates the CameraConsole.js layout.
  const ArenasWindow = (props, context) => {

    return (
      <Window.Content scrollable>

        <div className="CameraConsole__left">
          <MainTabs />
          <ArenasList />
        </div>

        <div className="CameraConsole__right">
          <div className="CameraConsole__toolbar">
            <b>Arena: </b>
            {current_arena || '—'}
          </div>

          <ByondUi
            className="CameraConsole__map"
            params={{
              id: map_ref,
              type: 'map',
            }} />
        </div>

      </Window.Content>
    );
  };

  // Functional component: list of tabs (threats, arenas)
  const MainTabs = (props, context) => {

    return (
      <Tabs>
        <Tabs.Tab selected={mainTab === 1} onClick={() => setMainTab(1)}>
          Threats
        </Tabs.Tab>
        <Tabs.Tab selected={mainTab === 2} onClick={() => setMainTab(2)}>
          Arenas
        </Tabs.Tab>
      </Tabs>
    );
  };


  // The actual return of TestRangeThreatSimulator.js
  return (
    <Window
      width={1100}
      height={900}>
      { mainTab === 1 ? <ThreatsWindow /> : <ArenasWindow /> }
    </Window>
  );

};
