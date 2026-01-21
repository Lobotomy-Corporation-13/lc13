import { Component } from 'inferno';
import { resolveAsset } from '../assets';
import { useBackend, useLocalState } from '../backend';
import { Box, Button, NoticeBox, Section, TextArea } from '../components';
import { Window } from '../layouts';

const CHAR_MIN = 5;
const CHAR_MAX = 300;
const TYPEWRITER_SPEED = 50;

export const IndexPager = (props, context) => {
  const { data } = useBackend(context);
  const { is_ghost } = data;

  if (is_ghost) {
    return (
      <Window width={450} height={500}>
        <Window.Content>
          <GhostView />
        </Window.Content>
      </Window>
    );
  }

  return (
    <Window width={500} height={400} theme="hackerman">
      <Window.Content>
        <Box
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            width: '100%',
            height: '100%',
            padding: '20px',
            boxSizing: 'border-box',
          }}>
          <Box
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
          </Box>
        </Box>
      </Window.Content>
    </Window>
  );
};

const GhostView = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    on_cooldown,
    submission_window_open,
    has_submitted,
    draft_text,
  } = data;

  const [text, setText] = useLocalState(context, 'draft', draft_text || '');
  const charCount = text.length;
  const isValidLength = charCount >= CHAR_MIN && charCount <= CHAR_MAX;

  const handleTextInput = (e, value) => {
    setText(value);
  };

  const handleTextChange = (e, value) => {
    act('update_draft', { text: value });
  };

  const handleSubmit = () => {
    if (isValidLength && !has_submitted && !on_cooldown) {
      act('submit_prescript', { text: text });
      setText('');
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

      {on_cooldown ? (
        <NoticeBox info>
          The pager is on cooldown. Please wait for the next cycle.
        </NoticeBox>
      ) : has_submitted ? (
        <NoticeBox success>
          Your prescript has been submitted. Waiting for selection...
        </NoticeBox>
      ) : (
        <Section title="Submit Prescript">
          {submission_window_open && (
            <NoticeBox info>
              Submission window is open! Submit your prescript now.
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
            {charCount < CHAR_MIN
              && ` (minimum ${CHAR_MIN})`}
          </Box>
          <Button
            fluid
            mt={1}
            icon="paper-plane"
            content="Submit Prescript"
            disabled={!isValidLength}
            onClick={handleSubmit}
          />
        </Section>
      )}
    </Section>
  );
};

const HumanView = (props, context) => {
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
      <Box>
        <Box style={{ textAlign: 'center', marginBottom: '24px' }}>
          <img
            src={resolveAsset('index_logo.png')}
            style={{ width: '150px', height: 'auto' }}
          />
        </Box>
        <Box style={{ ...textStyle, color: '#666' }}>
          No prescript available.
        </Box>
      </Box>
    );
  }

  return (
    <Box>
      <Box style={{ textAlign: 'center', marginBottom: '24px' }}>
        <img
          src={resolveAsset('index_logo.png')}
          style={{ width: '150px', height: 'auto' }}
        />
      </Box>
      <div style={textStyle}>
        【To {prescript_recipient}】
      </div>
      {prescript_loaded ? (
        <div style={{ ...textStyle, marginTop: '16px' }}>
          【{prescript_text}】
        </div>
      ) : prescript_displaying ? (
        <Box style={{ marginTop: '16px' }}>
          <TypewriterText
            text={prescript_text}
            onComplete={() => act('typing_complete')}
          />
        </Box>
      ) : (
        <Box style={{ ...textStyle, color: '#666', marginTop: '16px' }}>
          Loading...
        </Box>
      )}
    </Box>
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
