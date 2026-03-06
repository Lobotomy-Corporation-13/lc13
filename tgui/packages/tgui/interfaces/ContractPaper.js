import {
  useBackend,
  useSharedState,
} from '../backend';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Tabs,
} from '../components';
import { Window } from '../layouts';
import {
  PatrolRouteCanvas,
} from './PatrolRouteMap';

export const ContractPaper = (
  props,
  context,
) => {
  const { act, data } = useBackend(
    context,
  );
  const {
    contract_name = 'Contract',
    state = 'pending',
    has_map = false,
  } = data;
  const [tab, setTab] = useSharedState(
    context, 'paperTab', 0,
  );
  const showTabs = has_map;
  return (
    <Window
      title={contract_name}
      width={showTabs ? 580 : 360}
      height={showTabs ? 620 : 380}>
      <Window.Content scrollable>
        {showTabs ? (
          <>
            <Tabs>
              <Tabs.Tab
                selected={tab === 0}
                onClick={
                  () => setTab(0)
                }>
                Details
              </Tabs.Tab>
              <Tabs.Tab
                selected={tab === 1}
                onClick={
                  () => setTab(1)
                }>
                Map
              </Tabs.Tab>
            </Tabs>
            {tab === 0 && (
              <DetailsView
                act={act}
                data={data}
              />
            )}
            {tab === 1 && (
              <MapView data={data} />
            )}
          </>
        ) : (
          <DetailsView
            act={act}
            data={data}
          />
        )}
      </Window.Content>
    </Window>
  );
};

const DetailsView = props => {
  const { act, data } = props;
  const {
    contract_name = 'Contract',
    contract_type = 'generic',
    category = 'duration',
    state = 'pending',
    source = 'hana',
    payment = 0,
    issuer = 'Unknown',
    target = 'None',
    reports_filed = 0,
    required_reports = 0,
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
    <>
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
          {contract_type
            === 'investigate_person'
            && (
              <LabeledList.Item
                label="Reports">
                {reports_filed
                  + ' / '
                  + required_reports}
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
          {(isDuration
            || contract_type
              === 'investigate_person')
            && (
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
            onClick={
              () => act('accept')
            }
          />
        </Box>
      )}
      {state === 'active' && (
        <Box mt={1} textAlign="center">
          <Button
            content="Make Copy"
            icon="copy"
            onClick={
              () => act('make_copy')
            }
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
    </>
  );
};

const MapView = props => {
  const { data } = props;
  const {
    mapGrid,
    statusText = '',
    map_legend = [],
  } = data;
  if (!mapGrid) {
    return (
      <Section title="Route Map">
        <Box color="label" italic>
          Map data not available.
        </Box>
      </Section>
    );
  }
  return (
    <Section title="Route Map">
      <Box
        style={{
          display: 'flex',
          gap: '8px',
        }}>
        <Box
          style={{ flexShrink: 0 }}>
          <PatrolRouteCanvas
            data={data}
          />
        </Box>
        {!!map_legend.length && (
          <Box
            style={{
              flexShrink: 0,
              minWidth: '120px',
            }}>
            <PaperLegend
              legend={map_legend}
            />
          </Box>
        )}
      </Box>
      {!!statusText && (
        <Box
          mt={1}
          textAlign="center"
          bold
          fontSize="13px">
          {statusText}
        </Box>
      )}
    </Section>
  );
};

const PaperLegend = props => {
  const { legend = [] } = props;
  if (!legend.length) return null;
  return (
    <Section title="Legend">
      {legend.map(entry => (
        <Box
          key={entry.color}
          mb={0.5}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '4px',
          }}
          fontSize="11px"
          color="label">
          <Box
            inline
            style={{
              width: '10px',
              height: '10px',
              background: entry.color,
              flexShrink: 0,
            }}
          />
          {entry.name}
        </Box>
      ))}
    </Section>
  );
};
