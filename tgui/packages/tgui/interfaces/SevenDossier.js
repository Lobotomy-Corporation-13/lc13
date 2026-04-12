import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  LabeledList,
  Section,
  Table,
} from '../components';
import { Window } from '../layouts';

export const SevenDossier = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    total_filed,
    subjects = [],
  } = data;
  const [
    expanded,
    setExpanded,
  ] = useLocalState(context, 'expanded', null);
  return (
    <Window
      width={450}
      height={400}>
      <Window.Content scrollable>
        <Section title={'Dossier - '
          + total_filed + ' Reports Filed'}>
          {subjects.length === 0 && (
            <Box color="average">
              No reports filed yet. Use intel
              reports on this dossier to file them.
            </Box>
          )}
          <Table>
            <Table.Row header>
              <Table.Cell>Subject</Table.Cell>
              <Table.Cell>Reports</Table.Cell>
              <Table.Cell>Avg Accuracy</Table.Cell>
              <Table.Cell />
            </Table.Row>
            {subjects.map(subject => (
              <SubjectRow
                key={subject.key}
                subject={subject}
                expanded={expanded === subject.key}
                act={act}
                onToggle={() => setExpanded(
                  expanded === subject.key
                    ? null
                    : subject.key
                )} />
            ))}
          </Table>
        </Section>
      </Window.Content>
    </Window>
  );
};

const SubjectRow = (props, context) => {
  const {
    subject, expanded, onToggle, act,
  } = props;
  return (
    <>
      <Table.Row>
        <Table.Cell>
          {subject.name}
        </Table.Cell>
        <Table.Cell>
          {subject.count}
        </Table.Cell>
        <Table.Cell>
          {subject.avg_accuracy}/10
        </Table.Cell>
        <Table.Cell>
          <Button
            icon={expanded
              ? 'chevron-up'
              : 'chevron-down'}
            onClick={onToggle} />
        </Table.Cell>
      </Table.Row>
      {expanded && subject.reports
        && subject.reports.map((report, i) => (
          <Table.Row key={i}>
            <Table.Cell colSpan={4}>
              <Box ml={2} mb={1}>
                <LabeledList>
                  <LabeledList.Item
                    label="Role">
                    {report.target_role || 'N/A'}
                  </LabeledList.Item>
                  <LabeledList.Item
                    label="Time">
                    {report.round_time || 'N/A'}
                  </LabeledList.Item>
                  <LabeledList.Item
                    label="Notes">
                    {report.extra_notes || 'N/A'}
                  </LabeledList.Item>
                  <LabeledList.Item
                    label="Accuracy">
                    {report.accuracy}/10
                  </LabeledList.Item>
                  {!!report.photo_ref && (
                    <LabeledList.Item
                      label="Photo">
                      <Button
                        content="View Photo"
                        icon="camera"
                        onClick={() => act(
                          'view_photo',
                          {
                            photo_ref:
                              report.photo_ref,
                          }
                        )} />
                    </LabeledList.Item>
                  )}
                  <LabeledList.Item
                    label="Filed">
                    {report.filed_time}
                  </LabeledList.Item>
                </LabeledList>
              </Box>
            </Table.Cell>
          </Table.Row>
        ))}
    </>
  );
};
