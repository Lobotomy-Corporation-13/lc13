import { useBackend } from '../backend';
import {
  Box, Button, Flex, Icon, Section, Stack,
} from '../components';
import { Window } from '../layouts';

export const CoreTemplateVendor = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    balance = 0,
    templates = [],
  } = data;

  return (
    <Window
      width={400}
      height={450}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Section
              title={(
                <Box>
                  <Icon name="wallet" mr={1} />
                  Your Balance
                </Box>
              )}>
              <Box fontSize="20px" textAlign="center" bold>
                {balance} Ahn
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Section
              fill
              scrollable
              title={(
                <Box>
                  <Icon name="shopping-cart" mr={1} />
                  Navigation Core Templates
                </Box>
              )}>
              <Stack vertical>
                {templates.map((template, index) => (
                  <Stack.Item key={index}>
                    <TemplateCard
                      template={template}
                      balance={balance}
                      act={act} />
                  </Stack.Item>
                ))}
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Box fontSize="11px" color="label" textAlign="center">
              Templates are filled with enkephalin chems to create cores
            </Box>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const TemplateCard = props => {
  const { template, balance, act } = props;
  const canAfford = balance >= template.cost;
  const gradeColors = {
    1: '#8B7355', // Basic - Brown
    2: '#4A7C59', // Standard - Green
    3: '#4169E1', // Quality - Blue
    4: '#9932CC', // Superior - Purple
  };
  const gradeColor = gradeColors[template.grade] || '#888';

  return (
    <Box
      style={{
        border: '1px solid ' + gradeColor,
        borderRadius: '4px',
        padding: '8px',
        marginBottom: '4px',
        backgroundColor: gradeColor + '20',
      }}>
      <Flex align="center" mb={1}>
        <Flex.Item grow>
          <Box bold fontSize="14px" color={gradeColor}>
            {template.name}
          </Box>
        </Flex.Item>
        <Flex.Item>
          <Box bold color={canAfford ? 'good' : 'bad'}>
            {template.cost} Ahn
          </Box>
        </Flex.Item>
      </Flex>

      <Box fontSize="11px" color="label" mb={1}>
        {template.description}
      </Box>

      <Flex mb={1}>
        <Flex.Item basis="50%">
          <Box fontSize="11px">
            <Icon name="arrows-alt" mr={1} />
            Distance: {template.min_dist}-{template.max_dist}
          </Box>
        </Flex.Item>
        <Flex.Item basis="50%">
          <Box fontSize="11px">
            <Icon name="layer-group" mr={1} />
            Max Tier: {template.max_tier}
          </Box>
        </Flex.Item>
      </Flex>

      <Button
        fluid
        icon="shopping-cart"
        color={canAfford ? 'good' : 'default'}
        disabled={!canAfford}
        content={canAfford ? 'Purchase' : 'Insufficient Funds'}
        onClick={() => act('purchase', { grade: template.grade })} />
    </Box>
  );
};
