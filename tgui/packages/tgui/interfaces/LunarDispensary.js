import { useBackend, useLocalState } from '../backend';
import { Box, Button, ColorBox, Input, LabeledList, Section }
  from '../components';
import { Window } from '../layouts';

// A chem-dispenser-style window for the Lunar Physician. Dispenses reagents
// into the held container, shows contents, and renames/recolors each chemical.
const AMOUNTS = [1, 5, 10, 15, 20, 25, 30, 50];

export const LunarDispensary = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    amount,
    hasContainer,
    containerName,
    contents = [],
    currentVolume,
    maxVolume,
    purgeReady,
    chemicals = [],
  } = data;
  const [search, setSearch] = useLocalState(context, 'search', '');
  const query = search.toLowerCase();
  const filtered = chemicals.filter(
    c => c.name.toLowerCase().includes(query));
  return (
    <Window title="Dispensary" width={600} height={640}>
      <Window.Content scrollable>
        <Section title="Container">
          {hasContainer ? (
            <LabeledList>
              <LabeledList.Item label="Held">
                {containerName}
              </LabeledList.Item>
              <LabeledList.Item label="Volume">
                {currentVolume} / {maxVolume} units
              </LabeledList.Item>
            </LabeledList>
          ) : (
            <Box color="bad">
              You are not holding a container. Pick one up first.
            </Box>
          )}
        </Section>
        {!!hasContainer && (
          <Section
            title="Contents"
            buttons={contents.length > 0 && (
              <Button
                icon="trash"
                color="bad"
                disabled={!purgeReady}
                tooltip={!purgeReady && 'On cooldown'}
                content="Purge"
                onClick={() => act('purge')} />
            )}>
            {contents.length === 0 ? (
              <Box color="label">Empty.</Box>
            ) : (
              contents.map(chem => (
                <Box key={chem.id} mb={1}>
                  <ColorBox color={chem.color} mr={1} />
                  <Box inline bold>{chem.name}</Box>
                  <Box inline color="label" ml={1}>
                    {chem.volume}u
                  </Box>
                  <Box inline ml={1}>
                    <Button
                      icon="pen"
                      content="Rename"
                      onClick={() =>
                        act('rename', { id: chem.id })} />
                    <Button
                      icon="palette"
                      content="Recolor"
                      onClick={() =>
                        act('recolor', { id: chem.id })} />
                    <Button
                      icon="times"
                      color="bad"
                      onClick={() =>
                        act('remove', { id: chem.id })} />
                  </Box>
                </Box>
              ))
            )}
          </Section>
        )}
        <Section
          title="Dispense"
          buttons={AMOUNTS.map(a => (
            <Button
              key={a}
              icon="plus"
              selected={a === amount}
              content={a}
              onClick={() => act('amount', { amount: a })} />
          ))}>
          <Box mb={1}>
            <Input
              fluid
              placeholder="Search chemicals..."
              value={search}
              onInput={(e, value) => setSearch(value)} />
          </Box>
          <Box mr={-1}>
            {filtered.map(chem => (
              <Button
                key={chem.id}
                icon="tint"
                width="130px"
                lineHeight={1.75}
                disabled={!hasContainer}
                content={chem.name}
                onClick={() =>
                  act('dispense', { reagent: chem.id })} />
            ))}
          </Box>
        </Section>
      </Window.Content>
    </Window>
  );
};
