import { useBackend, useLocalState } from '../backend';
import {
  Box, Button, Divider, Flex, Icon, Input, NoticeBox, NumberInput,
  Section, Stack, Tabs,
} from '../components';
import { Window } from '../layouts';

export const FactionTrader = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    trader_name,
    trader_title,
    faction_name,
    can_trade,
    credits = 0,
    discount_percent = 10,
  } = data;

  const [activeTab, setActiveTab] = useLocalState(
    context,
    'activeTab',
    'buy'
  );

  if (!can_trade) {
    return (
      <Window width={550} height={400}>
        <Window.Content>
          <NoticeBox danger>
            This trader refuses to do business with you.
          </NoticeBox>
        </Window.Content>
      </Window>
    );
  }

  return (
    <Window width={600} height={700}>
      <Window.Content>
        <Stack fill vertical>
          {/* Header */}
          <Stack.Item>
            <Section>
              <Flex align="center" justify="space-between">
                <Flex.Item>
                  <Box bold fontSize="16px" color="gold">
                    {trader_name}
                  </Box>
                  <Box color="label" fontSize="12px">
                    {trader_title} - {faction_name}
                  </Box>
                </Flex.Item>
                <Flex.Item>
                  <Box
                    style={{
                      backgroundColor: 'rgba(45, 74, 45, 0.5)',
                      border: '1px solid #4a7c4a',
                      borderRadius: '4px',
                      padding: '5px 10px',
                    }}>
                    <Icon name="percentage" color="good" mr={1} />
                    {discount_percent}% In-Person Discount!
                  </Box>
                </Flex.Item>
              </Flex>
            </Section>
          </Stack.Item>

          {/* Credits Display */}
          <Stack.Item>
            <Section>
              <Box bold>
                <Icon name="coins" color="gold" mr={1} />
                Outpost Credits: {credits}
              </Box>
            </Section>
          </Stack.Item>

          {/* Tabs */}
          <Stack.Item>
            <Tabs fluid>
              <Tabs.Tab
                icon="arrow-down"
                selected={activeTab === 'buy'}
                onClick={() => setActiveTab('buy')}>
                Buy
              </Tabs.Tab>
              <Tabs.Tab
                icon="arrow-up"
                selected={activeTab === 'sell'}
                onClick={() => setActiveTab('sell')}>
                Sell
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>

          {/* Tab Content */}
          <Stack.Item grow>
            {activeTab === 'buy' && <BuyTab />}
            {activeTab === 'sell' && <SellTab />}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

// Buy Tab with cart system
const BuyTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    faction_stock = [],
    cart = [],
    cart_total = 0,
    credits = 0,
    faction_name,
    busy,
  } = data;

  const [searchText, setSearchText] = useLocalState(
    context,
    'buySearchText',
    ''
  );

  const canAfford = credits >= cart_total;

  // Filter stock based on search
  const filteredStock = faction_stock.filter(item => {
    if (!searchText) return true;
    return item.name.toLowerCase().includes(searchText.toLowerCase());
  });

  return (
    <Section
      fill
      scrollable
      title={'Buy from ' + faction_name}
      buttons={(
        <Box>Your Credits: {credits}</Box>
      )}>
      <Stack vertical fill>
        {/* Search bar */}
        <Stack.Item>
          <Flex align="center">
            <Flex.Item>
              <Icon name="search" mr={1} />
            </Flex.Item>
            <Flex.Item grow>
              <Input
                fluid
                placeholder="Search items..."
                value={searchText}
                onInput={(e, value) => setSearchText(value)}
              />
            </Flex.Item>
            {searchText && (
              <Flex.Item ml={1}>
                <Button
                  icon="times"
                  onClick={() => setSearchText('')}
                />
              </Flex.Item>
            )}
          </Flex>
        </Stack.Item>

        {/* Stock list */}
        <Stack.Item grow>
          {filteredStock.length === 0 ? (
            <NoticeBox>
              {searchText
                ? 'No items match your search.'
                : 'This trader has no stock available.'}
            </NoticeBox>
          ) : (
            <Stack vertical>
              {filteredStock.map(item => (
                <Stack.Item key={item.type}>
                  <StockItemRow item={item} />
                </Stack.Item>
              ))}
            </Stack>
          )}
        </Stack.Item>

        <Divider />

        {/* Shopping Cart */}
        <Stack.Item>
          <Section title="Shopping Cart">
            {cart.length === 0 ? (
              <Box color="label">Cart is empty</Box>
            ) : (
              <Stack vertical>
                {cart.map(item => (
                  <Stack.Item key={item.type}>
                    <Flex justify="space-between" align="center">
                      <Flex.Item grow>
                        {item.name} x{item.quantity}
                      </Flex.Item>
                      <Flex.Item>
                        {item.total} credits
                      </Flex.Item>
                      <Flex.Item ml={1}>
                        <Button
                          icon="times"
                          color="bad"
                          onClick={() => act('remove_from_cart', {
                            type: item.type,
                          })}
                        />
                      </Flex.Item>
                    </Flex>
                  </Stack.Item>
                ))}
                <Divider />
                <Stack.Item>
                  <Flex justify="space-between" bold>
                    <Flex.Item>Total:</Flex.Item>
                    <Flex.Item
                      color={canAfford ? 'good' : 'bad'}>
                      {cart_total} credits
                    </Flex.Item>
                  </Flex>
                </Stack.Item>
              </Stack>
            )}

            <Flex justify="flex-end" mt={2}>
              <Flex.Item mr={1}>
                <Button
                  icon="trash"
                  disabled={cart.length === 0}
                  onClick={() => act('clear_cart')}>
                  Clear Cart
                </Button>
              </Flex.Item>
              <Flex.Item>
                <Button
                  icon="shopping-cart"
                  color="good"
                  disabled={
                    cart_total === 0
                    || !canAfford
                    || busy
                  }
                  onClick={() => act('purchase')}>
                  Purchase - {cart_total}
                </Button>
              </Flex.Item>
            </Flex>
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

// Stock Item Row for buying
const StockItemRow = (props, context) => {
  const { act } = useBackend(context);
  const { item } = props;

  const [quantity, setQuantity] = useLocalState(
    context,
    'qty_' + item.type,
    1
  );

  return (
    <Box
      style={{
        border: '1px solid #555',
        borderRadius: '4px',
        padding: '8px',
        marginBottom: '4px',
      }}>
      <Flex align="center">
        <Flex.Item grow>
          <Box bold>{item.name}</Box>
          <Box color="label">
            Stock: {item.quantity} | Price: {item.price} each
          </Box>
        </Flex.Item>
        <Flex.Item>
          <NumberInput
            value={quantity}
            minValue={1}
            maxValue={item.quantity}
            onChange={(e, val) => setQuantity(val)}
            width="60px"
          />
        </Flex.Item>
        <Flex.Item ml={1}>
          <Button
            icon="plus"
            disabled={item.quantity === 0}
            onClick={() => act('add_to_cart', {
              type: item.type,
              quantity: quantity,
            })}>
            Add
          </Button>
        </Flex.Item>
      </Flex>
    </Box>
  );
};

// Sell Tab
const SellTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    faction_name,
    faction_cash = 0,
    scanned_crates = [],
    selected_total = 0,
    busy,
  } = data;

  const canAfford = faction_cash >= selected_total;

  return (
    <Section
      fill
      scrollable
      title={'Sell to ' + faction_name}
      buttons={(
        <Box>Faction Cash: {faction_cash}</Box>
      )}>
      <Stack vertical fill>
        {/* Instructions */}
        <Stack.Item>
          <NoticeBox info>
            Place crates near the trader, then click
            &quot;Scan Nearby Crates&quot; to see sellable items.
          </NoticeBox>
        </Stack.Item>

        {/* Scan buttons */}
        <Stack.Item>
          <Flex>
            <Flex.Item>
              <Button
                icon="sync"
                onClick={() => act('scan_crates')}>
                Scan Nearby Crates
              </Button>
            </Flex.Item>
            <Flex.Item ml={1}>
              <Button
                icon="check-square"
                onClick={() => act('select_all')}>
                Select All
              </Button>
            </Flex.Item>
            <Flex.Item ml={1}>
              <Button
                icon="square"
                onClick={() => act('deselect_all')}>
                Deselect All
              </Button>
            </Flex.Item>
          </Flex>
        </Stack.Item>

        {/* Crate list */}
        <Stack.Item grow>
          {scanned_crates.length === 0 ? (
            <NoticeBox>
              No crates found nearby.
              Bring crates from your expedition and scan again.
            </NoticeBox>
          ) : (
            <Stack vertical>
              {scanned_crates.map(crate => (
                <Stack.Item key={crate.ref}>
                  <CrateCard crate={crate} />
                </Stack.Item>
              ))}
            </Stack>
          )}
        </Stack.Item>

        <Divider />

        {/* Sale summary */}
        <Stack.Item>
          <Flex justify="space-between" align="center">
            <Flex.Item>
              <Box bold>Selected Total: {selected_total} credits</Box>
              <Box color={canAfford ? 'good' : 'bad'}>
                {canAfford
                  ? 'Trader can afford'
                  : 'Trader cannot afford (reduce selection)'}
              </Box>
            </Flex.Item>
            <Flex.Item>
              <Button
                icon="paper-plane"
                color="good"
                disabled={
                  !canAfford
                  || selected_total === 0
                  || busy
                }
                onClick={() => act('sell')}>
                Sell - {selected_total} credits
              </Button>
            </Flex.Item>
          </Flex>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

// Crate Card for selling
const CrateCard = (props, context) => {
  const { act } = useBackend(context);
  const { crate } = props;

  return (
    <Box
      style={{
        border: crate.selected ? '2px solid #4a4' : '1px solid #555',
        borderRadius: '4px',
        padding: '8px',
        marginBottom: '4px',
        backgroundColor: crate.selected
          ? 'rgba(26, 71, 42, 0.2)'
          : 'transparent',
      }}>
      <Flex align="center">
        <Flex.Item>
          <Button
            icon={crate.selected ? 'check-square' : 'square'}
            color={crate.selected ? 'good' : 'default'}
            onClick={() => act('toggle_crate', { ref: crate.ref })}
          />
        </Flex.Item>
        <Flex.Item grow ml={1}>
          <Box bold>{crate.name}</Box>
          <Box color="label" fontSize="11px">
            {crate.items.map((item, i) => (
              <Box key={i}>
                {item.name}
                {item.count > 1 ? ` x${item.count}` : ''}
                {' - '}
                {item.value} credits
              </Box>
            ))}
          </Box>
        </Flex.Item>
        <Flex.Item>
          <Box bold color="good">
            {crate.total_value} credits
          </Box>
        </Flex.Item>
      </Flex>
    </Box>
  );
};
