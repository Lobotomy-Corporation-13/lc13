import { useBackend } from '../backend';
import {
  Box,
  Button,
  Collapsible,
  Divider,
  Flex,
  Icon,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
} from '../components';
import { Window } from '../layouts';

export const ResourcesRecorder = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    in_warehouse,
    exporting,
    phase,
    scanned_closets = [],
    export_objectives = [],
  } = data;

  return (
    <Window
      width={500}
      height={600}>
      <Window.Content scrollable>
        {!in_warehouse && (
          <NoticeBox danger>
            This console is not in an Export Warehouse room.
            Designate the room first using an Outpost Planner.
          </NoticeBox>
        )}
        {!!in_warehouse && (
          <>
            <ExportObjectivesSection
              objectives={export_objectives}
              phase={phase}
            />
            <Divider />
            <WarehouseContentsSection
              closets={scanned_closets}
              exporting={exporting}
              phase={phase}
            />
          </>
        )}
      </Window.Content>
    </Window>
  );
};

const ExportObjectivesSection = (props, context) => {
  const { objectives, phase } = props;

  if (phase < 2) {
    return (
      <Section title="Export Objectives">
        <NoticeBox info>
          Export objectives unlock after completing all building objectives.
        </NoticeBox>
      </Section>
    );
  }

  return (
    <Section title="Export Objectives">
      <Stack vertical>
        {objectives.map((obj, index) => (
          <Stack.Item key={index}>
            <Flex align="center">
              <Flex.Item grow={1}>
                <Box
                  color={obj.completed ? 'good' : 'label'}
                  bold={!obj.completed}>
                  {obj.completed && <Icon name="check" color="good" mr={1} />}
                  {obj.name}
                </Box>
              </Flex.Item>
              <Flex.Item width="120px">
                <ProgressBar
                  value={obj.current}
                  maxValue={obj.required}
                  color={obj.completed ? 'good' : 'average'}>
                  {obj.current} / {obj.required}
                </ProgressBar>
              </Flex.Item>
            </Flex>
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

const WarehouseContentsSection = (props, context) => {
  const { act } = useBackend(context);
  const { closets, exporting, phase } = props;

  const selectedCount = closets.filter(c => c.selected).length;

  return (
    <Section
      title="Warehouse Contents"
      buttons={(
        <>
          <Button
            icon="sync"
            content="Scan Warehouse"
            onClick={() => act('scan')}
            disabled={exporting}
          />
          {closets.length > 0 && (
            <>
              <Button
                icon="check-square"
                content="Select All"
                onClick={() => act('select_all')}
                disabled={exporting}
              />
              <Button
                icon="square"
                content="Deselect All"
                onClick={() => act('deselect_all')}
                disabled={exporting}
              />
            </>
          )}
        </>
      )}>
      {closets.length === 0 && (
        <NoticeBox>
          No containers found. Click &quot;Scan Warehouse&quot;
          to detect closets and crates.
        </NoticeBox>
      )}
      {closets.length > 0 && (
        <Stack vertical>
          {closets.map((closet, index) => (
            <Stack.Item key={closet.ref}>
              <ClosetEntry closet={closet} exporting={exporting} />
            </Stack.Item>
          ))}
          <Stack.Item>
            <Divider />
          </Stack.Item>
          <Stack.Item>
            <Flex justify="flex-end">
              <Flex.Item>
                <Button
                  icon="paper-plane"
                  content={`Export Selected (${selectedCount})`}
                  color="good"
                  disabled={
                    exporting || selectedCount === 0 || phase < 2
                  }
                  tooltip={
                    phase < 2 ? "Complete building objectives first" : null
                  }
                  onClick={() => act('export')}
                />
              </Flex.Item>
            </Flex>
          </Stack.Item>
        </Stack>
      )}
      {exporting && (
        <NoticeBox info mt={2}>
          <Icon name="spinner" spin mr={1} />
          Exporting resources...
        </NoticeBox>
      )}
    </Section>
  );
};

const ClosetEntry = (props, context) => {
  const { act } = useBackend(context);
  const { closet, exporting } = props;

  const hasContributingItems = closet.contents.some(item => item.contributes);

  return (
    <Collapsible
      title={(
        <Flex align="center" inline width="100%">
          <Flex.Item>
            <Button
              icon={closet.selected ? 'check-square-o' : 'square-o'}
              color={closet.selected ? 'good' : 'default'}
              onClick={e => {
                e.stopPropagation();
                act('toggle_select', { ref: closet.ref });
              }}
              disabled={exporting}
            />
          </Flex.Item>
          <Flex.Item grow={1} ml={1}>
            <Box inline bold color={hasContributingItems ? 'good' : 'label'}>
              {closet.name}
            </Box>
            <Box inline ml={1} color="label">
              ({closet.total_items} items)
            </Box>
          </Flex.Item>
          {hasContributingItems && (
            <Flex.Item>
              <Icon
                name="star"
                color="gold"
                title="Contains items for objectives" />
            </Flex.Item>
          )}
        </Flex>
      )}>
      <Box pl={3}>
        {closet.contents.map((item, index) => (
          <Box key={index} color={item.contributes ? 'good' : 'label'}>
            {item.contributes && (
              <Icon name="arrow-right" color="good" mr={1} />
            )}
            {item.name}: {item.count}
          </Box>
        ))}
      </Box>
    </Collapsible>
  );
};
