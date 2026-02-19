import { useBackend } from '../backend';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
} from '../components';
import { Window } from '../layouts';

export const ContractPaper = (
  props,
  context,
) => {
  const { act, data } = useBackend(context);
  const {
    contract_name = 'Contract',
    contract_type = 'generic',
    category = 'duration',
    state = 'pending',
    source = 'hana',
    payment = 0,
    issuer = 'Unknown',
    target = 'None',
    tier_name = 'N/A',
    status_text = 'Unknown',
    completion_exp = 0,
    exp_multiplier = 1,
    can_accept = false,
  } = data;
  const isDuration
    = category === 'duration';
  const isCivilian
    = source === 'civilian';
  return (
    <Window
      title={contract_name}
      width={360}
      height={380}>
      <Window.Content scrollable>
        {isCivilian && (
          <NoticeBox success>
            Civilian contract
            {' \u2014 '}
            2x EXP bonus!
          </NoticeBox>
        )}
        <Section title="Contract Details">
          <LabeledList>
            <LabeledList.Item
              label="Type">
              {contract_name}
            </LabeledList.Item>
            <LabeledList.Item
              label="Category">
              {isDuration
                ? 'Duration-based'
                : 'Objective-based'}
            </LabeledList.Item>
            {isDuration && (
              <LabeledList.Item
                label="Duration">
                {tier_name}
              </LabeledList.Item>
            )}
            <LabeledList.Item
              label="Payment">
              {payment + ' Ahn'}
            </LabeledList.Item>
            <LabeledList.Item
              label="Issuer">
              {issuer}
            </LabeledList.Item>
            {target !== 'None' && (
              <LabeledList.Item
                label="Target">
                {target}
              </LabeledList.Item>
            )}
          </LabeledList>
        </Section>
        <Section title="Rewards">
          <LabeledList>
            <LabeledList.Item
              label="Completion EXP">
              {completion_exp
                * exp_multiplier}
            </LabeledList.Item>
            {isDuration && (
              <LabeledList.Item
                label="Passive EXP">
                {'1 per 10s'
                  + (isCivilian
                    ? ' (x2)'
                    : '')}
              </LabeledList.Item>
            )}
            <LabeledList.Item
              label="EXP Multiplier">
              {exp_multiplier + 'x'}
            </LabeledList.Item>
          </LabeledList>
        </Section>
        {can_accept && (
          <Box mt={1} textAlign="center">
            <Button
              content="Accept Contract"
              color="green"
              fontSize="14px"
              onClick={() => act('accept')}
            />
          </Box>
        )}
        <Box
          mt={1}
          italic
          color="label"
          textAlign="center">
          {'Status: ' + status_text}
        </Box>
      </Window.Content>
    </Window>
  );
};
