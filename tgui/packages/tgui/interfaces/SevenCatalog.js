import { useBackend } from '../backend';
import {
  Box,
  Button,
  Section,
  Table,
} from '../components';
import { formatMoney } from '../format';
import { Window } from '../layouts';

export const SevenCatalog = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    balance = 0,
    items = [],
  } = data;
  return (
    <Window
      width={420}
      height={380}>
      <Window.Content scrollable>
        <Section title="Seven Requisition Catalog">
          <Box mb={1} bold>
            Balance: {formatMoney(balance)} Ahn
          </Box>
          <Table>
            <Table.Row header>
              <Table.Cell>Item</Table.Cell>
              <Table.Cell>Cost</Table.Cell>
              <Table.Cell />
            </Table.Row>
            {items.map((item, i) => (
              <Table.Row key={i}>
                <Table.Cell>
                  <Box bold>
                    {item.name}
                  </Box>
                  <Box color="label"
                    fontSize="11px">
                    {item.desc}
                  </Box>
                </Table.Cell>
                <Table.Cell>
                  {formatMoney(item.cost)} Ahn
                </Table.Cell>
                <Table.Cell>
                  <Button
                    content="Buy"
                    disabled={
                      balance < item.cost
                    }
                    onClick={() => act(
                      'purchase',
                      { index: i + 1 }
                    )} />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
      </Window.Content>
    </Window>
  );
};
