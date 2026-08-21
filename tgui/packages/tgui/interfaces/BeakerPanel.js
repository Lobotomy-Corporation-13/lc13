import { resolveAsset } from '../assets';
import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, Section, Divider, Tab, Tabs, Input, Table, Slider, LabeledControls, BlockQuote, Stack, Collapsible, Dropdown, NumberInput } from '../components';
import { ButtonCheckbox } from '../components/Button';
import { FlexItem } from '../components/Flex';
import { TableCell, TableRow } from '../components/Table';
import { Window } from '../layouts';


/* ------------ Functional Components ------------*/
const SpawnButton = (props, context) => {
  const { container, reagents } = props;
  const { act } = useBackend(context);

  const GatherSpawnInfo = (container, reagents) => {
    if(!container || !reagents){
      return null;
    }

    let reagents_to_add = {};
    for (const r in reagents) {
      reagents_to_add[r] = reagents[r]["amount"]
    };

    let spawn_info = {
      container: container,
      reagents: reagents_to_add
    };

    return spawn_info;
  }

  return (
    <Button
      textAlign="center"
      content="Spawn!"
      color={"green"}
      onClick={() => act('spawn', {
        spawn_info: GatherSpawnInfo(container, reagents),
      })} />
  )
};


const NewReagentEntry = (props, context) => {
  const { addReagent, reagentList, reagent_name_to_type_map } = props;

  const newReagent = (chosen) => {
    let new_reagent_object = {
      type: reagent_name_to_type_map[chosen],
      name: chosen
    };
    addReagent(new_reagent_object, 10);
  };

  return (

      <Dropdown
        textAlign="center"
        displayText={"Choose a Reagent..."}
        width={"100%"}
        minWidth={"100%"}
        maxWidth={"100%"}
        options={reagentList}
        onSelected={value => {newReagent(value);}}/>

  )
};

const ReagentEntry = (props, context) => {
    const { subject, addReagent, removeReagent } = props;



    return (
          <TableRow style={{ border: '2px solid rgb(8, 8, 8)' }}>
            <TableCell color="label">
              {subject.type}
            </TableCell>
            <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} textAlign="center" nowrap>
              <NumberInput unit="u" value={subject.amount || 0} onChange={(e, value) => addReagent(subject, value)} minValue={0}/>
            </TableCell>
            <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} textAlign="center">
              <Button mx={1} icon="trash" color="red" onClick={() => removeReagent(subject)}/>
            </TableCell>
          </TableRow>

    )
  };

const ReagentStack = (props, context) => {
    const { filter, reagents, reagent_names, reagentStackCallback, currentReagents, reagent_name_to_type_map } = props;

    const addReagent = (reagent, amount) => {
      if(amount <= 0) {
        removeReagent(reagent);
        return;
      }

      let newReagents = { ...currentReagents };
      delete newReagents[reagent.type];
      newReagents[reagent.type] = {
        type: reagent.type,
        name: reagent.name,
        amount: amount
      };
      reagentStackCallback(newReagents);

    };

    const removeReagent = (reagent) => {
      let newReagents = {...currentReagents};
      delete newReagents[reagent.type];
      reagentStackCallback(newReagents);
    };

    let filtered_reagents = [];
    if (!filter) {
      filtered_reagents = reagent_names;
    } else {
      for (const reagent_name of reagent_names) {
        if (reagent_name.toLowerCase().includes(filter.toLowerCase())) {
          filtered_reagents.push(reagent_name);
        }
      };
    }

    let reagents_to_display = [];
    for (const current_reagent in currentReagents) {
      reagents_to_display.push(currentReagents[current_reagent]);
    };



    return (
      <Section fill minWidth={'100%'} title={`Reagents`}>
        <Table backgroundColor="#131212">
          {reagents_to_display.map(r => <ReagentEntry subject={r} addReagent={addReagent} removeReagent={removeReagent} />)}
        </Table>
        <Divider />
        <NewReagentEntry addReagent={addReagent} reagentList={filtered_reagents} reagent_name_to_type_map={reagent_name_to_type_map} />


      </Section>
    )
  };

const ContainerSection = (props, context) => {
    const { id, currentContainer, reagents, container_names, reagent_names, filter, reagentFilter, setterFunction, reagentStackCallback, currentReagents, reagent_name_to_type_map, container_name_to_type_map} = props;
    let filtered_containers = [];
    if (!filter) {
      filtered_containers = container_names;
    }
    else {
      for (const container_name of container_names) {
        if (container_name.includes(filter.toLowerCase())) {
          filtered_containers.push(container_name);
        }
      };
    };

    const setNewContainer = (chosen_name) => {
      setterFunction(container_name_to_type_map[chosen_name]);
    };

    return (
      <Section fill minWidth={'100%'} title={`Container ${id}: `}>
        <Flex direction="column">
          <Dropdown
          textAlign="center"
          displayText={currentContainer ? currentContainer : "Choose a Container..."}
          width={"100%"}
          minWidth={"100%"}
          maxWidth={"100%"}
          options={filtered_containers}
          onSelected={value => {setNewContainer(value);}}/>
        <ReagentStack reagents={reagents} filter={reagentFilter} reagent_names={reagent_names} reagentStackCallback={reagentStackCallback} currentReagents={currentReagents} reagent_name_to_type_map={reagent_name_to_type_map} />
        <SpawnButton container={currentContainer} reagents={currentReagents} />
        </Flex>

      </Section>
    )
  }


export const BeakerPanel = (props, context) => {
  const { act, data } = useBackend(context);
  const { reagents, containers } = data;
  const [containerFilter, setContainerFilter] = useLocalState(context, "containerFilter", "beaker");
  const [reagentFilter, setReagentFilter] = useLocalState(context, "reagentFilter", "");
  const [chosenContainerOne, setChosenContainerOne] = useLocalState(context, "chosenContainerOne", null);
  const [chosenContainerTwo, setChosenContainerTwo] = useLocalState(context, "chosenContainerTwo", null);
  const [reagentStackOne, setReagentStackOne] = useLocalState(context, "reagentStackOne", {});
  const [reagentStackTwo, setReagentStackTwo] = useLocalState(context, "reagentStackTwo", {});
  const [grenadeTimer, setGrenadeTimer] = useLocalState(context, "grenadeTimer", 5)

  const container_names = containers.map((container) => (container.name));
  const reagent_names = reagents.map((reagent) => (reagent.name));

  const container_name_to_type_map = {};
  for (const container of containers) {
    container_name_to_type_map[container.name] = container.type;
  };
  const reagent_name_to_type_map = {};
  for (const reagent of reagents) {
    reagent_name_to_type_map[reagent.name] = reagent.type;
  };

  const GenerateGrenadeSpawnInfo = () => {
     if(!chosenContainerOne || !chosenContainerTwo) {
      return null;
    }
    let spawn_info = [];
    let reagent_info = {};
    for (const r in reagentStackOne) {
      reagent_info[r] = reagentStackOne[r]["amount"]
    };
    let containerOneInfo = {
      container: chosenContainerOne,
      reagents: reagent_info
    };
    reagent_info = {};
    for (const r in reagentStackTwo) {
      reagent_info[r] = reagentStackTwo[r]["amount"]
    };
    let containerTwoInfo = {
      container: chosenContainerTwo,
      reagents: reagent_info
    };
    spawn_info.push(containerOneInfo, containerTwoInfo);

    return spawn_info;
  };



  return (
    <Window
      title="Spawn Reagent Container: LC13 Edition"
      width={800}
      height={600}>
      <Window.Content scrollable>
        <Flex minWidth="100%" direction='column'>

          <Flex.Item>
            uwah~ you need to select reagent containers dante... and then add reagents to them!
          </Flex.Item>
          <Flex.Item my={1}>
            <Divider />
          </Flex.Item>
          <Flex.Item grow align='center' minWidth={"100%"}>
            <Section title="Filters" align='center' >
              <Stack vertical>
                <Stack.Item>
                  Container Name:
                  <Input mx={1}
                    placeholder="Search..."
                    autoFocus
                    value={containerFilter}
                    onInput={(_, value) => { setContainerFilter(value); }}
                  />
                  <Button icon="trash" color="red" content="Clear"
                      onClick={() => { setContainerFilter("");}} />
                </Stack.Item>
                <Stack.Item>
                  Reagent Name:
                  <Input mx={1}
                    placeholder="Search..."
                    autoFocus
                    value={reagentFilter}
                    onInput={(_, value) => { setReagentFilter(value); }}
                  />
                  <Button icon="trash" color="red" content="Clear"
                      onClick={() => { setReagentFilter("");}} />
                </Stack.Item>
              </Stack>


            </Section>
          </Flex.Item>
          <Flex.Item>
            <Divider />
          </Flex.Item>
          <Flex.Item grow>

            <Flex minWidth="100%" direction="row" justify="space-evenly">
              <Flex.Item grow>
                <ContainerSection title={chosenContainerOne ? chosenContainerOne : "None"} id={1} currentContainer={chosenContainerOne} containers={containers} reagents={reagents}
                  filter={containerFilter} reagentFilter={reagentFilter}
                  setterFunction={setChosenContainerOne} reagentStackCallback={setReagentStackOne} currentReagents={reagentStackOne}
                  reagent_name_to_type_map={reagent_name_to_type_map} container_name_to_type_map={container_name_to_type_map}
                  container_names={container_names} reagent_names={reagent_names} />
              </Flex.Item>
              <Flex.Item>
                <Divider vertical />
              </Flex.Item>
              <Flex.Item grow>
                <ContainerSection title={chosenContainerTwo ? chosenContainerTwo : "None"} id={2} currentContainer={chosenContainerTwo} containers={containers} reagents={reagents}
                  filter={containerFilter} reagentFilter={reagentFilter}
                  setterFunction={setChosenContainerTwo} reagentStackCallback={setReagentStackTwo} currentReagents={reagentStackTwo}
                  reagent_name_to_type_map={reagent_name_to_type_map} container_name_to_type_map={container_name_to_type_map}
                  container_names={container_names} reagent_names={reagent_names} />
              </Flex.Item>

            </Flex>
          </Flex.Item>
        <Flex.Item>
          <Section title='"Hilarious" content'>
            <Flex direction="column">
              <Flex.Item mb={1}>
                <Button
                  color="red"
                  content="Spawn Grenade*"
                  onClick={() => act("spawngrenade", {
                    spawn_info: GenerateGrenadeSpawnInfo(),
                    grenade_info: {
                      detonation_type: "normal",
                      detonation_timer: grenadeTimer
                    }
                  })}
                />
              </Flex.Item>
              <Flex.Item>
                Detonation Timer: <NumberInput unit="s" value={grenadeTimer} onChange={(e, value) => setGrenadeTimer(value)} minValue={0} />
              </Flex.Item>
              <Flex.Item my={3}>
                * Requires two beaker-type containers. Spawns unprimed!
              </Flex.Item>
            </Flex>
          </Section>
        </Flex.Item>
        </Flex>
      </Window.Content>
    </Window>



  )

  }
