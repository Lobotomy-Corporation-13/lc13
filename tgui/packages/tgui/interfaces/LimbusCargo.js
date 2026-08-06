import { toArray } from 'common/collections';
import { useBackend, useSharedState } from '../backend';
import { AnimatedNumber, Box, Button, Flex, NoticeBox, Section, Table, Tabs } from '../components';
import { formatMoney } from '../format';
import { Window } from '../layouts';

// Deliberately self-contained rather than reusing CargoCatalog from Cargo.js. That component
// hardcodes ' cr', renders cart controls this console does not have, and dispatches act('add')
// into a shopping list that only exists when there is a supply shuttle. Limbus Labs has no
// shuttle - orders are charged and podded immediately - so the two consoles genuinely differ.

export const LimbusCargo = (props, context) => {
  return (
    <Window
      width={700}
      height={620}>
      <Window.Content scrollable>
        <LimbusCargoStatus />
        <LimbusCargoCatalog />
      </Window.Content>
    </Window>
  );
};

const LimbusCargoStatus = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    points,
    pad_found,
  } = data;
  return (
    <Section
      title="Requisitions"
      buttons={(
        <Button
          icon="upload"
          disabled={!pad_found}
          content="Export pad contents"
          onClick={() => act('export')} />
      )}>
      <Box fontSize="1.5rem" bold>
        <AnimatedNumber
          value={points}
          format={formatMoney} />
        {' Ahn'}
      </Box>
      {!pad_found && (
        <NoticeBox danger mt={1}>
          No requisition pad in range. Nothing can be sent or delivered.
        </NoticeBox>
      )}
    </Section>
  );
};

const LimbusCargoCatalog = (props, context) => {
  const { act, data } = useBackend(context);
  const supplies = toArray(data.supplies);
  const [
    activeSupplyName,
    setActiveSupplyName,
  ] = useSharedState(context, 'lce_supply', supplies[0]?.name);
  const activeSupply = supplies.find(supply => {
    return supply.name === activeSupplyName;
  });
  return (
    <Section title="Catalogue">
      <Flex>
        <Flex.Item ml={-1} mr={1}>
          <Tabs vertical>
            {supplies.map(supply => (
              <Tabs.Tab
                key={supply.name}
                selected={supply.name === activeSupplyName}
                onClick={() => setActiveSupplyName(supply.name)}>
                {supply.name} ({supply.packs.length})
              </Tabs.Tab>
            ))}
          </Tabs>
        </Flex.Item>
        <Flex.Item grow={1} basis={0}>
          <Table>
            {activeSupply?.packs.map(pack => (
              <Table.Row
                key={pack.name}
                className="candystripe">
                <Table.Cell>
                  {pack.name}
                </Table.Cell>
                <Table.Cell
                  collapsing
                  textAlign="right">
                  <Button
                    fluid
                    tooltip={pack.desc}
                    tooltipPosition="left"
                    onClick={() => act('order', {
                      id: pack.id,
                    })}>
                    {formatMoney(pack.cost)}
                    {' Ahn'}
                  </Button>
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Flex.Item>
      </Flex>
    </Section>
  );
};
