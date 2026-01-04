import { resolveAsset } from '../assets';
import { useBackend, useLocalState } from '../backend';
import {
  Box, Button, Divider, Flex, Icon, Input, NoticeBox, NumberInput,
  Section, Stack, Tabs,
} from '../components';
import { Window } from '../layouts';

// Static fade duration in milliseconds (2 seconds)
const STATIC_FADE_DURATION = 2000;

export const ResurgenceTrading = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    in_warehouse,
    busy,
    credits = 0,
    connected_faction,
  } = data;

  const [activeTab, setActiveTab] = useLocalState(
    context,
    'activeTab',
    'factions'
  );

  if (!in_warehouse) {
    return (
      <Window width={600} height={400}>
        <Window.Content>
          <NoticeBox danger>
            This console must be placed in an Export Warehouse room.
          </NoticeBox>
        </Window.Content>
      </Window>
    );
  }

  return (
    <Window width={650} height={750}>
      <Window.Content>
        <Stack fill vertical>
          {/* Speaker Panel */}
          {connected_faction && (
            <Stack.Item>
              <SpeakerPanel faction={connected_faction} />
            </Stack.Item>
          )}

          {/* Credits Display */}
          <Stack.Item>
            <Section>
              <Flex align="center" justify="space-between">
                <Flex.Item>
                  <Box bold>
                    <Icon name="coins" color="gold" mr={1} />
                    Outpost Credits: {credits}
                  </Box>
                </Flex.Item>
                {connected_faction && (
                  <Flex.Item>
                    <Button
                      icon="times"
                      color="bad"
                      onClick={() => act('disconnect')}>
                      Disconnect
                    </Button>
                  </Flex.Item>
                )}
              </Flex>
            </Section>
          </Stack.Item>

          {/* Tabs */}
          <Stack.Item>
            <Tabs fluid>
              <Tabs.Tab
                icon="users"
                selected={activeTab === 'factions'}
                onClick={() => setActiveTab('factions')}>
                Factions
              </Tabs.Tab>
              <Tabs.Tab
                icon="arrow-up"
                selected={activeTab === 'sell'}
                disabled={!connected_faction || !connected_faction.can_trade}
                onClick={() => setActiveTab('sell')}>
                Sell
              </Tabs.Tab>
              <Tabs.Tab
                icon="arrow-down"
                selected={activeTab === 'buy'}
                disabled={!connected_faction || !connected_faction.can_trade}
                onClick={() => setActiveTab('buy')}>
                Buy
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>

          {/* Tab Content */}
          <Stack.Item grow>
            {activeTab === 'factions' && <FactionsTab />}
            {activeTab === 'sell' && <SellTab />}
            {activeTab === 'buy' && <BuyTab />}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

// Speaker Panel Component with portrait and static effect
const SpeakerPanel = (props, context) => {
  const { data } = useBackend(context);
  const { faction } = props;
  const { connection_time = 0, current_time = 0 } = data;

  // Calculate static opacity based on connection time
  // For insurgence_clan, always show full static
  const isInsurgence = faction.id === 'insurgence_clan';

  // Time since connection in deciseconds (BYOND uses deciseconds)
  const timeSinceConnect = current_time - connection_time;
  // Convert to milliseconds for comparison
  const timeSinceConnectMs = timeSinceConnect * 100;

  // Calculate opacity: starts at 1, fades to 0.12 over 2 seconds
  let staticOpacity = 1;
  if (!isInsurgence && connection_time > 0) {
    if (timeSinceConnectMs >= STATIC_FADE_DURATION) {
      staticOpacity = 0.12; // 30/255 approximately
    } else {
      // Linear interpolation from 1 to 0.12
      const progress = timeSinceConnectMs / STATIC_FADE_DURATION;
      staticOpacity = 1 - (progress * 0.88);
    }
  }

  // For insurgence, always full opacity
  if (isInsurgence) {
    staticOpacity = 1;
  }

  return (
    <Section>
      <Flex align="center">
        <Flex.Item>
          <Box
            style={{
              width: '96px',
              height: '96px',
              border: '2px solid #555',
              borderRadius: '4px',
              backgroundColor: '#222',
              position: 'relative',
              overflow: 'hidden',
            }}>
            {/* Portrait Image */}
            <img
              src={resolveAsset(faction.speaker_portrait)}
              style={{
                width: '100%',
                height: '100%',
                objectFit: 'cover',
                display: 'block',
              }}
            />
            {/* Static Overlay */}
            <img
              src={resolveAsset('trader_static.gif')}
              style={{
                position: 'absolute',
                top: 0,
                left: 0,
                width: '100%',
                height: '100%',
                objectFit: 'cover',
                opacity: staticOpacity,
                transition: isInsurgence ? 'none' : 'opacity 0.1s linear',
                pointerEvents: 'none',
              }}
            />
          </Box>
        </Flex.Item>
        <Flex.Item grow ml={2}>
          <Box
            italic
            style={{
              backgroundColor: 'rgba(0, 0, 0, 0.3)',
              padding: '10px',
              borderRadius: '4px',
              borderLeft: '3px solid #666',
            }}>
            &quot;{faction.current_dialogue}&quot;
          </Box>
          <Box color="label" textAlign="right" mt={1}>
            - {faction.speaker_name}, {faction.speaker_title}
          </Box>
        </Flex.Item>
      </Flex>
    </Section>
  );
};

// Factions Tab
const FactionsTab = (props, context) => {
  const { act, data } = useBackend(context);
  const { factions = [], connected_faction } = data;

  return (
    <Section fill scrollable title="Select Faction">
      <Stack vertical>
        {factions.map(faction => (
          <Stack.Item key={faction.id}>
            <FactionCard faction={faction} />
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

// Faction Card
const FactionCard = (props, context) => {
  const { act } = useBackend(context);
  const { faction } = props;

  // For undiscovered factions, show mystery display
  const isDiscovered = faction.discovered;

  // Only calculate stars for discovered factions
  const stars = isDiscovered ? Math.floor(faction.reputation / 20) : 0;
  const starDisplay = isDiscovered
    ? '\u2605'.repeat(stars) + '\u2606'.repeat(5 - stars)
    : '\u2606\u2606\u2606\u2606\u2606';

  let repColor = 'label';
  if (isDiscovered) {
    if (faction.reputation >= 60) repColor = 'good';
    else if (faction.reputation < 30) repColor = 'bad';
    else repColor = 'white';
  }

  return (
    <Box
      style={{
        border: faction.is_connected
          ? '2px solid #4a4'
          : '1px solid #555',
        borderRadius: '4px',
        padding: '10px',
        marginBottom: '8px',
        backgroundColor: faction.is_connected
          ? 'rgba(26, 71, 42, 0.3)'
          : 'transparent',
      }}>
      <Flex align="center">
        <Flex.Item grow>
          <Box bold fontSize="14px">
            <Box inline color={isDiscovered ? 'gold' : 'label'}>
              {starDisplay}
            </Box>
            {' '}{faction.name}
            {faction.is_connected && (
              <Box inline color="good" ml={1}>
                [Connected]
              </Box>
            )}
          </Box>
          <Box color="label" italic mt={1}>{faction.desc}</Box>
          {isDiscovered ? (
            <>
              <Box mt={1}>
                <Box inline color={repColor}>
                  Reputation: {faction.reputation}
                  {' '}({faction.reputation_label})
                </Box>
              </Box>
              {faction.can_trade && (
                <Box>
                  Cash: {faction.current_cash} / {faction.max_cash}
                </Box>
              )}
              {!faction.can_trade && (
                <Box color="bad">Cannot trade with this faction</Box>
              )}
            </>
          ) : (
            <Box color="label" mt={1}>
              Connect to learn more about this faction.
            </Box>
          )}
        </Flex.Item>
        <Flex.Item>
          <Button
            icon={faction.is_connected ? 'check' : 'plug'}
            color={faction.is_connected ? 'good' : 'default'}
            disabled={faction.is_connected}
            onClick={() => act('connect', { faction: faction.id })}>
            {faction.is_connected ? 'Connected' : 'Connect'}
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
    connected_faction,
    scanned_closets = [],
    selected_total = 0,
    busy,
  } = data;

  if (!connected_faction) {
    return (
      <Section fill>
        <NoticeBox warning>
          Connect to a faction first using the Factions tab.
        </NoticeBox>
      </Section>
    );
  }

  const canAfford = connected_faction.current_cash >= selected_total;

  return (
    <Section
      fill
      scrollable
      title={'Sell to: ' + connected_faction.name}
      buttons={(
        <Box>Faction Cash: {connected_faction.current_cash}</Box>
      )}>
      <Stack vertical fill>
        {/* Scan buttons */}
        <Stack.Item>
          <Flex>
            <Flex.Item>
              <Button
                icon="sync"
                onClick={() => act('scan')}>
                Scan Warehouse
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

        {/* Closet list */}
        <Stack.Item grow>
          {scanned_closets.length === 0 ? (
            <NoticeBox>
              Click &quot;Scan Warehouse&quot; to find containers.
            </NoticeBox>
          ) : (
            <Stack vertical>
              {scanned_closets.map(closet => (
                <Stack.Item key={closet.ref}>
                  <ClosetCard closet={closet} />
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
              <Box bold>Selected Total: {selected_total}</Box>
              <Box color={canAfford ? 'good' : 'bad'}>
                {canAfford
                  ? 'Faction can afford'
                  : 'Faction cannot afford (reduce selection)'}
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

// Closet Card for selling - now shows combined items cleanly
const ClosetCard = (props, context) => {
  const { act } = useBackend(context);
  const { closet } = props;

  return (
    <Box
      style={{
        border: closet.selected ? '2px solid #4a4' : '1px solid #555',
        borderRadius: '4px',
        padding: '8px',
        marginBottom: '4px',
        backgroundColor: closet.selected
          ? 'rgba(26, 71, 42, 0.2)'
          : 'transparent',
      }}>
      <Flex align="center">
        <Flex.Item>
          <Button
            icon={closet.selected ? 'check-square' : 'square'}
            color={closet.selected ? 'good' : 'default'}
            onClick={() => act('toggle_select', { ref: closet.ref })}
          />
        </Flex.Item>
        <Flex.Item grow ml={1}>
          <Box bold>{closet.name}</Box>
          <Box color="label" fontSize="11px">
            {closet.items.map((item, i) => (
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
            {closet.total_value} credits
          </Box>
        </Flex.Item>
      </Flex>
    </Box>
  );
};

// Buy Tab with search functionality
const BuyTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    connected_faction,
    faction_stock = [],
    cart = [],
    cart_total = 0,
    credits = 0,
    busy,
  } = data;

  const [searchText, setSearchText] = useLocalState(
    context,
    'buySearchText',
    ''
  );

  if (!connected_faction) {
    return (
      <Section fill>
        <NoticeBox warning>
          Connect to a faction first using the Factions tab.
        </NoticeBox>
      </Section>
    );
  }

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
      title={'Buy from: ' + connected_faction.name}
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
                : 'This faction has no stock available.'}
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
                    <Flex.Item>{cart_total} credits</Flex.Item>
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
