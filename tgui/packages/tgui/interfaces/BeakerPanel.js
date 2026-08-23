import { useBackend, useLocalState } from '../backend';
import { Button, Flex, Section, Divider, Input, Table, Stack, Dropdown, NumberInput } from '../components';
import { TableCell, TableRow } from '../components/Table';
import { Window } from '../layouts';


// This is a button that spawns a container for its section, based on the chosen container type and reagent stack.
const SpawnButton = (props, context) => {
  const { container, reagents, currentTemperature } = props;
  const { act } = useBackend(context);

  // Assembles the spawn info in the format expected by the .dm file.
  const GatherSpawnInfo = (container, reagents) => {
    if (!container || !reagents) {
      return null;
    }

    let reagents_to_add = {};
    for (const r in reagents) {
      reagents_to_add[r] = reagents[r]["amount"];
    }

    // Container is a string (path) and reagents is an object (keys are paths and values are amounts)
    let spawn_info = {
      container: container,
      reagents: reagents_to_add,
      temperature: currentTemperature,
    };

    return spawn_info;
  };

  return (
    <Button
      textAlign="center"
      content="Spawn!"
      tooltip="Will handle reactions immediately."
      color={"green"}
      onClick={() => act('spawn', {
        spawn_info: GatherSpawnInfo(container, reagents),
      })} />
  );
};


// Dropdown that creates and adds a new reagent object to the container section's reagent stack.
const NewReagentEntry = (props, context) => {
  const { addReagent, reagentList, reagent_name_to_type_map } = props;

  const newReagent = chosen => {
    let new_reagent_object = {
      type: reagent_name_to_type_map[chosen],
      name: chosen,
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
      onSelected={value => { newReagent(value); }} />
  );
};

// A table row representing a reagent object. Has a button to delete it or an input to modify its amount.
const ReagentEntry = (props, context) => {
  const { subject, addReagent, removeReagent } = props;

  return (
    <TableRow style={{ border: '2px solid rgb(8, 8, 8)' }}>
      <TableCell color="label">
        {subject.type}
      </TableCell>
      <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} textAlign="center" nowrap>
        <NumberInput unit="u" value={subject.amount || 0} onChange={(e, value) => addReagent(subject, value)} minValue={0} />
      </TableCell>
      <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} textAlign="center">
        <Button mx={1} icon="trash" color="red" onClick={() => removeReagent(subject)} />
      </TableCell>
    </TableRow>

  );
};

// Consists of the current reagent stack for this container section, and NewReagentEntry to add more.
const ReagentStack = (props, context) => {
  const { filter, reagent_names, reagentStackCallback, currentReagents, reagent_name_to_type_map } = props;

  // addReagent is what's used to both modify an existing reagent object's amount, or add a new one.
  // Previous instances of the reagent in the stack will be deleted to avoid duplicates,
  // so the order of the reagents array will change.
  const addReagent = (reagent, amount) => {
    // Zero, or negative values, means the user wants to get rid of the reagent.
    if (amount <= 0) {
      removeReagent(reagent);
      return;
    }

    // We can't mutate state directly, so we have to piece it back together with our changes.
    let newReagents = { ...currentReagents };
    delete newReagents[reagent.type];
    newReagents[reagent.type] = {
      type: reagent.type,
      name: reagent.name,
      amount: amount,
    };
    // Set the reagent stack's state to the new one.
    reagentStackCallback(newReagents);
  };

  // removeReagent removes a reagent object from the stack entirely. Uses basically identical logic to addReagent.
  const removeReagent = reagent => {
    let newReagents = { ...currentReagents };
    delete newReagents[reagent.type];
    reagentStackCallback(newReagents);
  };

  // We need to know what reagent names we should show in the NewReagentEntry dropdown, so apply our filter.
  let filtered_reagents = [];
  if (!filter) {
    filtered_reagents = reagent_names;
  } else {
    for (const reagent_name of reagent_names) {
      if (reagent_name.toLowerCase().includes(filter.toLowerCase())) {
        filtered_reagents.push(reagent_name);
      }
    }
  }

  // Need to know which reagent objects are already in our reagent stack,
  // and add them to an array so we can display them in a table.
  let reagents_to_display = [];
  for (const current_reagent in currentReagents) {
    reagents_to_display.push(currentReagents[current_reagent]);
  }

  return (
    <Section fill minWidth={'100%'} title={`Reagents`}>
      <Table backgroundColor="#131212">
        {(reagents_to_display.map(r =>
        <ReagentEntry key={r.type} subject={r} addReagent={addReagent} removeReagent={removeReagent} />))}
      </Table>
      <Divider />
      <NewReagentEntry addReagent={addReagent} reagentList={filtered_reagents}
        reagent_name_to_type_map={reagent_name_to_type_map} />
    </Section>
  );
};

// A large functional component containing all the info and buttons to manage containers and reagents in this interface.
const ContainerSection = (props, context) => {
  const { id, currentContainer, reagents, container_paths, reagent_names,
    filter, currentTemperature, temperatureSetter,
    reagentFilter, setterFunction, reagentStackCallback,
    currentReagents, reagent_name_to_type_map } = props;

  // filtered_containers should contain only the container paths which pass our active filter.
  let filtered_containers = [];
  if (!filter) {
    filtered_containers = container_paths;
  }
  else {
    for (const container_path of container_paths) {
      if (container_path.includes(filter.toLowerCase())) {
        filtered_containers.push(container_path);
      }
    }
  }

  // setNewContainer will automatically handle setting the chosen container!
  const setNewContainer = chosen_path => {
    setterFunction(chosen_path);
  };

  // Unfortunately we have to do a biblical amount of prop drilling here for ReagentStack.
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
          onSelected={value => { setNewContainer(value); }} />
        <Flex.Item my={1}>
          Temperature: <NumberInput onChange={(e, value) => temperatureSetter(value)} value={currentTemperature} minValue={1} maxValue={10000} unit="K" />
        </Flex.Item>
        <ReagentStack reagents={reagents} filter={reagentFilter} reagent_names={reagent_names}
          reagentStackCallback={reagentStackCallback} currentReagents={currentReagents}
          reagent_name_to_type_map={reagent_name_to_type_map} />
        <SpawnButton container={currentContainer} reagents={currentReagents} currentTemperature={currentTemperature} />
      </Flex>
    </Section>
  );
};


// The actual interface, the main component, our export.
export const BeakerPanel = (props, context) => {
  const { act, data } = useBackend(context);
  const { reagents, containers } = data;

  // ---* States *---
  // Simple text filters.
  const [containerFilter, setContainerFilter] = useLocalState(context, "containerFilter", "beaker");
  const [reagentFilter, setReagentFilter] = useLocalState(context, "reagentFilter", "");
  // Chosen container; this holds a container type.
  const [chosenContainerOne, setChosenContainerOne] = useLocalState(context, "chosenContainerOne", null);
  const [chosenContainerTwo, setChosenContainerTwo] = useLocalState(context, "chosenContainerTwo", null);
  // Container temperatures!
  const [containerOneTemp, setContainerOneTemp] = useLocalState(context, "containerOneTemp", 150);
  const [containerTwoTemp, setContainerTwoTemp] = useLocalState(context, "containerTwoTemp", 150);
  // Currently assembled reagent stacks. Holds an object with reagent types and amounts.
  const [reagentStackOne, setReagentStackOne] = useLocalState(context, "reagentStackOne", {});
  const [reagentStackTwo, setReagentStackTwo] = useLocalState(context, "reagentStackTwo", {});
  // Grenade detonation timer, in seconds.
  const [grenadeTimer, setGrenadeTimer] = useLocalState(context, "grenadeTimer", 5);

  // ---* Names and Mapping *---
  // Arrays with the paths/names of all containers/reagents.
  const container_paths = containers.map(container => (container.type));
  const reagent_names = reagents.map(reagent => (reagent.name));
  // Objects which are maps that convert readable names to typepaths.

  /* So problem with this one, we have a bunch of containers with duplicate names. God damn it.
  const container_name_to_type_map = {};
  for (const container of containers) {
    container_name_to_type_map[container.name] = container.type;
  };
  */
  const reagent_name_to_type_map = {};
  for (const reagent of reagents) {
    reagent_name_to_type_map[reagent.name] = reagent.type;
  }

  // ---* Functions *---
  // There are other functions in the other components.
  // This one simply assembles the correct spawn_info for grenades.
  const GenerateGrenadeSpawnInfo = () => {
    if (!chosenContainerOne || !chosenContainerTwo) {
      return null;
    }
    let spawn_info = [];
    let reagent_info = {};
    for (const r in reagentStackOne) {
      reagent_info[r] = reagentStackOne[r]["amount"];
    }
    let containerOneInfo = {
      container: chosenContainerOne,
      reagents: reagent_info,
      temperature: containerOneTemp,
    };
    reagent_info = {};
    for (const r in reagentStackTwo) {
      reagent_info[r] = reagentStackTwo[r]["amount"];
    }
    let containerTwoInfo = {
      container: chosenContainerTwo,
      reagents: reagent_info,
      temperature: containerTwoTemp,
    };
    spawn_info.push(containerOneInfo, containerTwoInfo);

    return spawn_info;
  };

  // Unfortunately, we have to do a whole lot of prop drilling here.
  // Deeply nested functional components need access to our maps/states we establish here.
  // I believe actual React has a way to deal with this, but I haven't seen it used anywhere in our codebase.
  // For now, this works.

  // What this interface looks like, from the top to bottom:
  // First, a simple explanation of what the interface does.
  // Second, text search filters for containers and reagents.
  // Third, two container sections side-by-side where you choose a container from a dropdown.
  // Fourth, listing of current reagents and a dropdown to add more to the container section.
  // Fifth, the spawn button for either section.
  // Sixth, a separate section that holds the 'spawn grenade' feature.
  return (
    <Window
      title="Spawn Reagent Container: LC13 Edition"
      width={800}
      height={600}>
      <Window.Content scrollable>
        <Flex minWidth="100%" direction="column">
          <Flex.Item>
            uwah~ you need to select reagent containers dante... and then add reagents to them!
          </Flex.Item>
          <Flex.Item my={1}>
            <Divider />
          </Flex.Item>
          <Flex.Item grow align="center" minWidth={"100%"}>
            <Section title="Filters" align="center" >
              <Stack vertical>
                <Stack.Item>
                  Container Path:
                  <Input mx={1}
                    placeholder="Search..."
                    autoFocus
                    value={containerFilter}
                    onInput={(_, value) => { setContainerFilter(value); }}
                  />
                  <Button icon="trash" color="red" content="Clear"
                    onClick={() => { setContainerFilter(""); }} />
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
                    onClick={() => { setReagentFilter(""); }} />
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
                <ContainerSection title={chosenContainerOne ? chosenContainerOne : "None"} id={1}
                  currentContainer={chosenContainerOne} containers={containers} reagents={reagents}
                  currentTemperature={containerOneTemp} temperatureSetter={setContainerOneTemp}
                  filter={containerFilter} reagentFilter={reagentFilter}
                  setterFunction={setChosenContainerOne}
                  reagentStackCallback={setReagentStackOne} currentReagents={reagentStackOne}
                  reagent_name_to_type_map={reagent_name_to_type_map}
                  reagent_names={reagent_names} container_paths={container_paths} />
              </Flex.Item>
              <Flex.Item>
                <Divider vertical />
              </Flex.Item>
              <Flex.Item grow>
                <ContainerSection title={chosenContainerTwo ? chosenContainerTwo : "None"} id={2}
                  currentContainer={chosenContainerTwo} containers={containers} reagents={reagents}
                  currentTemperature={containerTwoTemp} temperatureSetter={setContainerTwoTemp}
                  filter={containerFilter} reagentFilter={reagentFilter}
                  setterFunction={setChosenContainerTwo}
                  reagentStackCallback={setReagentStackTwo} currentReagents={reagentStackTwo}
                  reagent_name_to_type_map={reagent_name_to_type_map}
                  reagent_names={reagent_names} container_paths={container_paths} />
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
                    tooltip="Seriously it won't work if you don't use beakers."
                    tooltipPosition="right"
                    onClick={() => act("spawngrenade", {
                      spawn_info: GenerateGrenadeSpawnInfo(),
                      grenade_info: {
                        detonation_type: "normal",
                        detonation_timer: grenadeTimer,
                      },
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
  );
};
