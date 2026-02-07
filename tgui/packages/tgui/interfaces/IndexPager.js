import { Component } from 'inferno';
import { resolveAsset } from '../assets';
import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  NoticeBox,
  Section,
  Tabs,
  TextArea,
} from '../components';
import { Window } from '../layouts';

const CHAR_MIN = 5;
const CHAR_MAX = 300;
const TYPEWRITER_SPEED = 50;
const WRAP_AFTER = 30;

// Insert zero-width spaces to allow line breaks in long text without spaces
const insertBreaks = text => {
  if (!text) return text;
  return text.replace(new RegExp(`(.{${WRAP_AFTER}})`, 'g'), '$1\u200B');
};

export const IndexPager = (props, context) => {
  const { data } = useBackend(context);
  const { is_ghost } = data;

  if (is_ghost) {
    return (
      <Window width={450} height={400}>
        <GhostView />
      </Window>
    );
  }

  return (
    <Window width={500} height={550} theme="hackerman">
      <Window.Content>
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            width: '100%',
            height: '100%',
            padding: '20px',
            boxSizing: 'border-box',
          }}>
          <div
            style={{
              backgroundColor: '#000000',
              border: '2px solid #224422',
              padding: '30px',
              width: '100%',
              maxWidth: '400px',
              overflow: 'hidden',
              minWidth: 0,
            }}>
            <HumanView />
          </div>
        </div>
      </Window.Content>
    </Window>
  );
};

const GhostView = (props, context) => {
  const { data } = useBackend(context);
  const { pending_judgments = [] } = data;
  const [tab, setTab] = useLocalState(context, 'ghostTab', 'submit');

  const judgmentCount = pending_judgments.length;

  return (
    <Window.Content scrollable>
      <Tabs fluid>
        <Tabs.Tab
          icon="paper-plane"
          selected={tab === 'submit'}
          onClick={() => setTab('submit')}>
          Submit
        </Tabs.Tab>
        <Tabs.Tab
          icon="gavel"
          selected={tab === 'judgment'}
          onClick={() => setTab('judgment')}>
          Judgment {judgmentCount > 0 && `(${judgmentCount})`}
        </Tabs.Tab>
        <Tabs.Tab
          icon="info-circle"
          selected={tab === 'status'}
          onClick={() => setTab('status')}>
          Status
        </Tabs.Tab>
      </Tabs>

      {tab === 'submit' && <SubmitTab />}
      {tab === 'judgment' && <JudgmentTab />}
      {tab === 'status' && <StatusTab />}
    </Window.Content>
  );
};

const SubmitTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    has_submitted,
    current_submission,
    draft_text,
    is_admin,
  } = data;

  const initialText = current_submission || draft_text || '';
  const [text, setText] = useLocalState(context, 'draft', initialText);
  const charCount = text.length;
  const isValidLength = charCount >= CHAR_MIN && charCount <= CHAR_MAX;

  const handleTextInput = (e, value) => {
    setText(value);
  };

  const handleTextChange = (e, value) => {
    act('update_draft', { text: value });
  };

  const handleSubmit = () => {
    if (isValidLength) {
      act('submit_prescript', { text: text });
    }
  };

  const handlePrioritySubmit = () => {
    if (isValidLength) {
      act('priority_submit', { text: text });
    }
  };

  return (
    <Section>
      <Box textAlign="center" mb={2}>
        <img
          src={resolveAsset('index_logo.png')}
          style={{
            width: '128px',
            height: 'auto',
          }}
        />
      </Box>

      <Section title="Rules">
        <Box color="label" fontSize="12px">
          1. All of the General LC13 Rules apply here.
        </Box>
        <Box color="label" fontSize="12px" mt={1}>
          2. Do not cause your prescripts to initiate a random Deathmatch
          or needless slaughter of staff. Your prescripts should tell the
          Index user to do something, not just &quot;kill everyone&quot;.
        </Box>
      </Section>

      <Section title={has_submitted ? 'Edit Prescript' : 'Submit Prescript'}>
        {has_submitted && (
          <NoticeBox success>
            Your prescript is in the pool. You can edit it below.
          </NoticeBox>
        )}
        <TextArea
          fluid
          height="120px"
          maxLength={CHAR_MAX}
          placeholder="Write your prescript here..."
          value={text}
          onInput={handleTextInput}
          onChange={handleTextChange}
        />
        <Box mt={1} color={isValidLength ? 'good' : 'bad'}>
          {charCount} / {CHAR_MAX} characters
          {charCount < CHAR_MIN && ` (minimum ${CHAR_MIN})`}
        </Box>
        <Button
          fluid
          mt={1}
          icon={has_submitted ? 'edit' : 'paper-plane'}
          content={has_submitted ? 'Update Prescript' : 'Submit Prescript'}
          disabled={!isValidLength}
          onClick={handleSubmit}
        />
        {is_admin && (
          <Button
            fluid
            mt={1}
            icon="bolt"
            color="red"
            content="Priority Submit (Admin)"
            disabled={!isValidLength}
            onClick={handlePrioritySubmit}
          />
        )}
      </Section>
    </Section>
  );
};

const JudgmentTab = (props, context) => {
  const { act, data } = useBackend(context);
  const { pending_judgments = [] } = data;

  if (pending_judgments.length === 0) {
    return (
      <Section title="Pending Judgments">
        <Box color="label" fontSize="12px">
          No pending judgments. When a proxy completes your prescript,
          you can reward or punish them here.
        </Box>
      </Section>
    );
  }

  return (
    <Section title="Pending Judgments">
      <Box color="label" fontSize="12px" mb={1}>
        Your prescripts have been completed. Reward or punish the proxy.
      </Box>
      {pending_judgments.map(entry => (
        <Box
          key={entry.id}
          mb={1}
          p={1}
          backgroundColor="rgba(0, 0, 0, 0.3)">
          <Box color="label" fontSize="12px">
            Completed by: {entry.recipient}
          </Box>
          <Box mt={1} style={{ fontStyle: 'italic' }} fontSize="12px">
            &quot;{entry.text}&quot;
          </Box>
          <Box mt={1}>
            <Button
              icon="heart"
              color="green"
              content="Heal"
              onClick={() => act('reward_prescript',
                { id: entry.id, type: 'heal' })}
            />
            <Button
              ml={1}
              icon="bolt"
              color="blue"
              content="Power"
              onClick={() => act('reward_prescript',
                { id: entry.id, type: 'buff' })}
            />
            <Button
              ml={1}
              icon="brain"
              color="orange"
              content="Damage"
              onClick={() => act('punish_prescript',
                { id: entry.id, type: 'damage' })}
            />
            <Button
              ml={1}
              icon="arrow-down"
              color="red"
              content="Weaken"
              onClick={() => act('punish_prescript',
                { id: entry.id, type: 'debuff' })}
            />
          </Box>
        </Box>
      ))}
    </Section>
  );
};

const StatusTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    is_admin,
    auto_select_paused,
    pool_count,
    prescript_text,
    prescript_recipient,
  } = data;

  return (
    <Section>
      <Section title="Active Prescript">
        {prescript_text ? (
          <Box>
            <Box color="label" fontSize="12px">
              Recipient: {prescript_recipient || 'Unknown'}
            </Box>
            <Box
              mt={1}
              p={1}
              backgroundColor="rgba(0, 0, 0, 0.3)"
              style={{ fontStyle: 'italic' }}>
              &quot;{prescript_text}&quot;
            </Box>
          </Box>
        ) : (
          <Box color="label" fontSize="12px">
            No active prescript.
          </Box>
        )}
      </Section>

      <Section title="Pool Status">
        <Box color="label">
          {pool_count} prescript(s) waiting in pool
        </Box>
      </Section>

      {is_admin && (
        <Section title="Admin Controls">
          <Button
            fluid
            icon={auto_select_paused ? 'play' : 'pause'}
            color={auto_select_paused ? 'good' : 'orange'}
            content={auto_select_paused
              ? 'Resume Auto-Select'
              : 'Pause Auto-Select'}
            onClick={() => act('toggle_auto_select')}
          />
          <Button
            fluid
            mt={1}
            icon="forward"
            color="blue"
            content="Skip Timer (Pick Now)"
            disabled={pool_count === 0}
            onClick={() => act('skip_timer')}
          />
        </Section>
      )}
    </Section>
  );
};

const HumanView = (props, context) => {
  const { data } = useBackend(context);
  const {
    active_prescripts = [],
    completed_prescripts = [],
  } = data;
  const [tab, setTab] = useLocalState(context, 'humanTab', 'current');

  const activeCount = active_prescripts.length;

  const tabStyle = {
    display: 'flex',
    gap: '4px',
    marginBottom: '16px',
    borderBottom: '1px solid #224422',
    paddingBottom: '8px',
  };

  const tabButtonStyle = selected => ({
    padding: '6px 12px',
    backgroundColor: selected ? '#224422' : 'transparent',
    border: '1px solid #224422',
    color: selected ? '#88c0d0' : '#666',
    cursor: 'pointer',
    fontFamily: 'Consolas, monospace',
    fontSize: '12px',
  });

  return (
    <div style={{ overflow: 'hidden', width: '100%', minWidth: 0 }}>
      <div style={{ textAlign: 'center', marginBottom: '16px' }}>
        <img
          src={resolveAsset('index_logo.png')}
          style={{ width: '100px', height: 'auto' }}
        />
      </div>

      <div style={tabStyle}>
        <button
          type="button"
          style={tabButtonStyle(tab === 'current')}
          onClick={() => setTab('current')}>
          Current
        </button>
        <button
          type="button"
          style={tabButtonStyle(tab === 'active')}
          onClick={() => setTab('active')}>
          Active {activeCount > 0 && `(${activeCount})`}
        </button>
        <button
          type="button"
          style={tabButtonStyle(tab === 'completed')}
          onClick={() => setTab('completed')}>
          Completed
        </button>
      </div>

      {tab === 'current' && <HumanCurrentTab />}
      {tab === 'active' && <HumanActiveTab />}
      {tab === 'completed' && <HumanCompletedTab />}
    </div>
  );
};

const HumanCurrentTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    prescript_text,
    prescript_recipient,
    prescript_loaded,
    prescript_displaying,
  } = data;

  const textStyle = {
    color: '#88c0d0',
    fontSize: '18px',
    fontFamily: 'Consolas, monospace',
    lineHeight: '1.6',
    wordBreak: 'break-all',
    overflowWrap: 'anywhere',
    width: '100%',
  };

  if (!prescript_text) {
    return (
      <div style={{ ...textStyle, color: '#666' }}>
        No prescript available.
      </div>
    );
  }

  return (
    <div>
      <div style={textStyle}>
        【To {prescript_recipient}】
      </div>
      {prescript_loaded ? (
        <div style={{ ...textStyle, marginTop: '16px' }}>
          【{insertBreaks(prescript_text)}】
        </div>
      ) : prescript_displaying ? (
        <div style={{ marginTop: '16px', overflow: 'hidden' }}>
          <TypewriterText
            text={insertBreaks(prescript_text)}
            onComplete={() => act('typing_complete')}
          />
        </div>
      ) : (
        <div style={{ ...textStyle, color: '#666', marginTop: '16px' }}>
          Loading...
        </div>
      )}
    </div>
  );
};

const HumanActiveTab = (props, context) => {
  const { act, data } = useBackend(context);
  const { active_prescripts = [] } = data;

  const textStyle = {
    color: '#88c0d0',
    fontSize: '12px',
    fontFamily: 'Consolas, monospace',
    wordBreak: 'break-all',
  };

  if (active_prescripts.length === 0) {
    return (
      <div style={{ ...textStyle, color: '#666' }}>
        No active prescripts. Complete some prescripts to see them here.
      </div>
    );
  }

  return (
    <div style={{ maxHeight: '280px', overflowY: 'auto' }}>
      {active_prescripts.map(entry => (
        <div
          key={entry.id}
          style={{
            marginBottom: '8px',
            padding: '8px',
            backgroundColor: 'rgba(0, 0, 0, 0.3)',
            border: '1px solid #224422',
          }}>
          <div style={textStyle}>
            {insertBreaks(entry.text)}
          </div>
          {entry.time_remaining && (
            <div
              style={{
                color: '#666',
                fontSize: '10px',
                marginTop: '4px',
              }}>
              Auto turn-in: {entry.time_remaining}
            </div>
          )}
          <Button
            mt={1}
            icon="check"
            color="green"
            content="Turn In"
            onClick={() => act('turn_in', { id: entry.id })}
          />
        </div>
      ))}
    </div>
  );
};

const HumanCompletedTab = (props, context) => {
  const { data } = useBackend(context);
  const { completed_prescripts = [] } = data;

  const textStyle = {
    color: '#666',
    fontSize: '12px',
    fontFamily: 'Consolas, monospace',
    wordBreak: 'break-all',
    textDecoration: 'line-through',
  };

  if (completed_prescripts.length === 0) {
    return (
      <div
        style={{
          color: '#666',
          fontSize: '12px',
          fontFamily: 'Consolas, monospace',
        }}>
        No completed prescripts yet.
      </div>
    );
  }

  return (
    <div style={{ maxHeight: '280px', overflowY: 'auto' }}>
      {completed_prescripts.map(entry => (
        <div
          key={entry.id}
          style={{
            marginBottom: '8px',
            padding: '8px',
            backgroundColor: 'rgba(0, 0, 0, 0.3)',
            border: '1px solid #446644',
          }}>
          <div style={textStyle}>
            {insertBreaks(entry.text)}
          </div>
          <div
            style={{
              color: '#446644',
              fontSize: '10px',
              marginTop: '4px',
            }}>
            ✓ Completed
          </div>
        </div>
      ))}
    </div>
  );
};

export class TypewriterText extends Component {
  constructor(props) {
    super(props);
    this.timer = null;
    this.state = {
      currentIndex: 0,
      displayedText: '',
    };
  }

  tick() {
    const { props, state } = this;
    if (state.currentIndex < props.text.length) {
      this.setState(prevState => ({
        currentIndex: prevState.currentIndex + 1,
        displayedText: props.text.substring(0, prevState.currentIndex + 1),
      }));
    } else {
      clearInterval(this.timer);
      if (props.onComplete) {
        props.onComplete();
      }
    }
  }

  componentDidMount() {
    this.timer = setInterval(() => this.tick(), TYPEWRITER_SPEED);
  }

  componentWillUnmount() {
    clearInterval(this.timer);
  }

  render() {
    const { state } = this;
    const isTyping = state.currentIndex < this.props.text.length;

    const textStyle = {
      color: '#88c0d0',
      fontSize: '18px',
      fontFamily: 'Consolas, monospace',
      lineHeight: '1.6',
      wordBreak: 'break-all',
      overflowWrap: 'anywhere',
      width: '100%',
    };

    return (
      <div style={textStyle}>
        【{state.displayedText}
        {isTyping ? (
          <span style={{ opacity: '0.7' }}>_</span>
        ) : (
          '】'
        )}
      </div>
    );
  }
}
