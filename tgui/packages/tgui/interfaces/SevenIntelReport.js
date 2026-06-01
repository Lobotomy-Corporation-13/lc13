import { useBackend } from '../backend';
import {
  Box,
  Button,
  Input,
  LabeledList,
  NoticeBox,
  Section,
} from '../components';
import { Window } from '../layouts';

export const SevenIntelReport = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    filed,
    has_photo,
    field_target_name,
    field_target_role,
    field_round_time,
    field_held_items = [],
    field_backpack = [],
    held_count,
    backpack_count,
    field_extra_notes,
    accuracy_score,
    scan_description,
    accuracy_feedback = [],
    photo_name,
    photo_desc,
    photo_ref,
  } = data;
  return (
    <Window
      width={450}
      height={600}>
      <Window.Content scrollable>
        {filed && (
          <NoticeBox info>
            Report filed.
            Accuracy: {accuracy_score}/10
          </NoticeBox>
        )}
        {!has_photo && !filed && (
          <NoticeBox warning>
            No photo attached. Use a Seven
            intel photo on this report.
          </NoticeBox>
        )}
        {!!scan_description && (
          <Section title="Scanner Data">
            <Box
              preserveWhitespace
              color="good">
              {scan_description}
            </Box>
          </Section>
        )}
        {has_photo && (
          <Section
            title="Attached Photo"
            buttons={(
              <Button
                content="View Photo"
                icon="camera"
                onClick={() => act(
                  'view_photo'
                )} />
            )}>
            <LabeledList>
              <LabeledList.Item
                label="Name">
                {photo_name}
              </LabeledList.Item>
              <LabeledList.Item
                label="Details">
                <Box
                  preserveWhitespace
                  color="label">
                  {photo_desc}
                </Box>
              </LabeledList.Item>
            </LabeledList>
          </Section>
        )}
        <Section title="Intelligence Report">
          <LabeledList>
            <LabeledList.Item
              label="Target Name">
              <Input
                fluid
                value={field_target_name}
                disabled={filed || !has_photo}
                onChange={(e, val) => act(
                  'set_field',
                  {
                    field: 'target_name',
                    value: val,
                  }
                )} />
            </LabeledList.Item>
            <LabeledList.Item
              label="Role">
              <Input
                fluid
                value={field_target_role}
                disabled={filed || !has_photo}
                onChange={(e, val) => act(
                  'set_field',
                  {
                    field: 'target_role',
                    value: val,
                  }
                )} />
            </LabeledList.Item>
            <LabeledList.Item
              label="Time">
              <Input
                fluid
                value={field_round_time}
                disabled={filed || !has_photo}
                onChange={(e, val) => act(
                  'set_field',
                  {
                    field: 'round_time',
                    value: val,
                  }
                )} />
            </LabeledList.Item>
          </LabeledList>
        </Section>
        {held_count > 0 && (
          <Section title="Held Items">
            <LabeledList>
              {field_held_items.map(
                (val, i) => (
                  <LabeledList.Item
                    key={i}
                    label={
                      'Held Item #'
                      + (i + 1)
                    }>
                    <Input
                      fluid
                      value={val}
                      disabled={
                        filed
                        || !has_photo
                      }
                      onChange={(e, v) =>
                        act('set_held_item', {
                          index: i + 1,
                          value: v,
                        })} />
                  </LabeledList.Item>
                )
              )}
            </LabeledList>
          </Section>
        )}
        {backpack_count > 0 && (
          <Section title="Backpack Contents">
            <LabeledList>
              {field_backpack.map(
                (val, i) => (
                  <LabeledList.Item
                    key={i}
                    label={
                      'Backpack Item #'
                      + (i + 1)
                    }>
                    <Input
                      fluid
                      value={val}
                      disabled={
                        filed
                        || !has_photo
                      }
                      onChange={(e, v) =>
                        act('set_backpack_item', {
                          index: i + 1,
                          value: v,
                        })} />
                  </LabeledList.Item>
                )
              )}
            </LabeledList>
          </Section>
        )}
        <Section title="Extra Notes">
          <Input
            fluid
            value={field_extra_notes}
            disabled={filed || !has_photo}
            onChange={(e, val) => act(
              'set_field',
              {
                field: 'extra_notes',
                value: val,
              }
            )} />
        </Section>
        {filed && (
          <Section title="Accuracy Results">
            <Box mb={1}>
              Score: {accuracy_score}/10
            </Box>
            {accuracy_feedback.map(
              (fb, i) => (
                <FeedbackEntry
                  key={i}
                  feedback={fb} />
              )
            )}
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};

const FeedbackEntry = (props, context) => {
  const { feedback } = props;
  if (feedback.items) {
    return (
      <Box mb={0.5}>
        <Box bold>{feedback.field}:</Box>
        {feedback.items.map(
          (item, i) => (
            <Box
              key={i}
              ml={1}
              color={item.correct
                ? 'good' : 'bad'}>
              {'#' + item.index + ': '}
              {item.correct
                ? 'Correct'
                : 'Wrong \u2014 was: '
                  + item.answer}
            </Box>
          )
        )}
      </Box>
    );
  }
  return (
    <Box
      mb={0.5}
      color={feedback.correct
        ? 'good' : 'bad'}>
      <Box inline bold mr={1}>
        {feedback.field}:
      </Box>
      {feedback.correct
        ? 'Correct'
        : 'Wrong \u2014 was: '
          + feedback.answer}
    </Box>
  );
};
