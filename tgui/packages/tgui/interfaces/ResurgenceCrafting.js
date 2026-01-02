import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Flex,
  Icon,
  Input,
  NumberInput,
  ProgressBar,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

export const ResurgenceCrafting = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    recipes = [],
    categories = [],
    busy,
    action_verb,
    busy_verb,
    has_craft_in_progress,
    current_recipe,
    current_work = 0,
    total_work = 0,
    progress_percent,
    target_copies = 1,
    completed_copies = 0,
    skip_recipes = false,
    // Server-side pagination data
    current_page = 1,
    total_pages = 1,
    total_recipes = 0,
    search_text = '',
    active_category = 'All',
  } = data;

  // Local state for input (to avoid sending on every keystroke)
  const [localSearch, setLocalSearch] = useLocalState(
    context,
    'localSearch',
    search_text
  );

  // Sync local search with server state when it changes externally
  if (localSearch !== search_text && !busy) {
    // Only sync if significantly different (server reset)
    if (search_text === '' && localSearch !== '') {
      // Keep local state
    }
  }

  return (
    <Window
      width={500}
      height={600}>
      <Window.Content>
        <Stack fill vertical>
          {/* Current Craft In Progress */}
          {has_craft_in_progress && (
            <Stack.Item>
              <Section
                title="Craft In Progress"
                buttons={(
                  <Button
                    icon="times"
                    color="bad"
                    content="Cancel"
                    disabled={busy}
                    tooltip="Cancel craft (materials for current copy lost)"
                    onClick={() => act('cancel_craft')} />
                )}>
                <Stack vertical>
                  <Stack.Item>
                    <Box bold fontSize="14px" mb={1}>
                      <Icon name="hammer" mr={1} />
                      {current_recipe}
                      {target_copies > 1 && (
                        <Box inline color="label" ml={1}>
                          (Copy {completed_copies + 1} of {target_copies})
                        </Box>
                      )}
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <ProgressBar
                      value={progress_percent / 100}
                      ranges={{
                        good: [0.67, 1],
                        average: [0.33, 0.67],
                        bad: [0, 0.33],
                      }}>
                      {progress_percent}% ({current_work}/{total_work} work)
                    </ProgressBar>
                  </Stack.Item>
                  {target_copies > 1 && (
                    <Stack.Item>
                      <Box color="label" fontSize="11px" mt={0.5}>
                        <Icon name="layer-group" mr={1} />
                        Batch: {completed_copies}/{target_copies} copies
                      </Box>
                    </Stack.Item>
                  )}
                  <Stack.Item mt={1}>
                    <Button
                      fluid
                      icon={busy ? "spinner" : "play"}
                      color="good"
                      disabled={busy}
                      content={busy ? "Working..." : "Continue Working"}
                      onClick={() => act('continue_craft')} />
                  </Stack.Item>
                  <Stack.Item>
                    <Box color="label" fontSize="11px" mt={1}>
                      <Icon name="info-circle" mr={1} />
                      Auto-continues until interrupted.
                      Progress is saved if you leave.
                    </Box>
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>
          )}

          {/* Search Bar */}
          <Stack.Item>
            <Section>
              <Flex align="center">
                <Flex.Item grow>
                  <Input
                    fluid
                    placeholder="Search recipes..."
                    value={localSearch}
                    onInput={(e, value) => setLocalSearch(value)}
                    onEnter={(e, value) => {
                      act('set_search', { search: value });
                    }} />
                </Flex.Item>
                <Flex.Item ml={1}>
                  <Button
                    icon="search"
                    tooltip="Search"
                    onClick={() => act('set_search', { search: localSearch })} />
                </Flex.Item>
                {localSearch && (
                  <Flex.Item ml={0.5}>
                    <Button
                      icon="times"
                      tooltip="Clear search"
                      onClick={() => {
                        setLocalSearch('');
                        act('set_search', { search: '' });
                      }} />
                  </Flex.Item>
                )}
              </Flex>
            </Section>
          </Stack.Item>

          {/* Category Tabs */}
          {!search_text && categories.length > 1 && (
            <Stack.Item>
              <Tabs fluid>
                {categories.map(category => (
                  <Tabs.Tab
                    key={category}
                    selected={active_category === category}
                    onClick={() => act('set_category', { category: category })}>
                    {category}
                  </Tabs.Tab>
                ))}
              </Tabs>
            </Stack.Item>
          )}

          {/* Recipe List */}
          <Stack.Item grow>
            <Section
              fill
              scrollable
              title={`Recipes (${total_recipes})`}
              buttons={total_pages > 1 && (
                <Box inline>
                  <Button
                    icon="angles-left"
                    disabled={current_page <= 1}
                    tooltip="First page"
                    onClick={() => act('set_page', { page: 1 })} />
                  <Button
                    icon="angle-left"
                    disabled={current_page <= 1}
                    tooltip="Previous page"
                    onClick={() => act('set_page', { page: current_page - 1 })} />
                  <Box inline mx={1} color="label">
                    {current_page} / {total_pages}
                  </Box>
                  <Button
                    icon="angle-right"
                    disabled={current_page >= total_pages}
                    tooltip="Next page"
                    onClick={() => act('set_page', { page: current_page + 1 })} />
                  <Button
                    icon="angles-right"
                    disabled={current_page >= total_pages}
                    tooltip="Last page"
                    onClick={() => act('set_page', { page: total_pages })} />
                </Box>
              )}>
              <Stack vertical>
                {skip_recipes ? (
                  <Stack.Item>
                    <Box color="label" italic textAlign="center" mt={2}>
                      <Icon name="spinner" spin mr={1} />
                      Working...
                    </Box>
                  </Stack.Item>
                ) : recipes.length > 0 ? (
                  recipes.map(recipe => (
                    <Stack.Item key={recipe.name}>
                      <RecipeCard
                        recipe={recipe}
                        busy={busy}
                        has_craft_in_progress={has_craft_in_progress}
                        action_verb={action_verb} />
                    </Stack.Item>
                  ))
                ) : (
                  <Stack.Item>
                    <Box color="label" italic textAlign="center" mt={2}>
                      {search_text
                        ? `No recipes found matching "${search_text}"`
                        : "No recipes available"}
                    </Box>
                  </Stack.Item>
                )}
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const RecipeCard = (props, context) => {
  const { act } = useBackend(context);
  const { recipe, busy, has_craft_in_progress, action_verb } = props;

  // Local state for quantity selection per recipe
  const [quantity, setQuantity] = useLocalState(
    context,
    `quantity_${recipe.name}`,
    1
  );

  const canStart = recipe.can_craft && !busy && !has_craft_in_progress;
  const maxCraftable = recipe.max_craftable || 0;

  return (
    <Section
      title={(
        <Box inline>
          {recipe.name}
          {recipe.result_amount > 1 && (
            <Box inline color="label" ml={1}>
              (x{recipe.result_amount})
            </Box>
          )}
        </Box>
      )}
      buttons={(
        <Box inline color="label" fontSize="11px">
          <Icon name="clock" mr={0.5} />
          {recipe.total_work} work
        </Box>
      )}>
      <Stack vertical>
        {/* Description */}
        <Stack.Item>
          <Box color="label" fontSize="12px">
            {recipe.desc}
          </Box>
        </Stack.Item>

        {/* Materials */}
        <Stack.Item>
          <Flex wrap="wrap">
            {recipe.materials.map((mat, index) => (
              <Flex.Item key={index} mr={2} mb={0.5}>
                <Box
                  inline
                  color={mat.enough ? 'good' : 'bad'}
                  fontSize="12px">
                  <Icon
                    name={mat.enough ? 'check' : 'times'}
                    mr={0.5} />
                  {mat.name}: {mat.have}/{mat.needed}
                </Box>
              </Flex.Item>
            ))}
          </Flex>
        </Stack.Item>

        {/* Quantity Selector */}
        <Stack.Item>
          <Flex align="center">
            <Flex.Item>
              <Box color="label" fontSize="12px" mr={1}>
                Quantity:
              </Box>
            </Flex.Item>
            <Flex.Item>
              <Button
                icon="minus"
                disabled={quantity <= 1}
                onClick={() => setQuantity(Math.max(1, quantity - 1))} />
            </Flex.Item>
            <Flex.Item>
              <NumberInput
                width="50px"
                value={quantity}
                minValue={1}
                maxValue={Math.max(1, maxCraftable)}
                step={1}
                onChange={(e, value) => setQuantity(value)} />
            </Flex.Item>
            <Flex.Item>
              <Button
                icon="plus"
                disabled={quantity >= maxCraftable}
                onClick={() => setQuantity(
                  Math.min(maxCraftable, quantity + 1)
                )} />
            </Flex.Item>
            <Flex.Item grow>
              <Box color="label" fontSize="11px" ml={1}>
                (max: {maxCraftable})
              </Box>
            </Flex.Item>
          </Flex>
        </Stack.Item>

        {/* Start Craft Button */}
        <Stack.Item>
          <Button
            fluid
            icon="hammer"
            color={canStart ? 'good' : 'grey'}
            disabled={!canStart}
            content={
              has_craft_in_progress
                ? "Finish current craft first"
                : busy
                  ? "Busy..."
                  : !recipe.can_craft
                    ? "Missing Materials"
                    : quantity > 1
                      ? `Start ${action_verb} (${quantity}x)`
                      : `Start ${action_verb}`
            }
            onClick={() => act('start_craft', {
              recipe: recipe.name,
              quantity: quantity,
            })} />
        </Stack.Item>
      </Stack>
    </Section>
  );
};
