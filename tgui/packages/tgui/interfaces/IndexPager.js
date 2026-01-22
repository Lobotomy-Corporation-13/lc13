import { Component } from 'inferno';
import { resolveAsset } from '../assets';
import { useBackend, useLocalState } from '../backend';
import { Box, Button, NoticeBox, Section, TextArea } from '../components';
import { Window } from '../layouts';

const CHAR_MIN = 5;
const CHAR_MAX = 300;
const TYPEWRITER_SPEED = 50;
const WRAP_AFTER = 30;

// Insert zero-width spaces to allow line breaks in long text without spaces
const insertBreaks = (text) => {
  if (!text) return text;
  return text.replace(new RegExp(`(.{${WRAP_AFTER}})`, 'g'), '$1\u200B');
};

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
  const { act, data } = useBackend(context);
  const {
    has_submitted,
    current_submission,
    draft_text,
  } = data;

  // Initialize with current submission (for editing) or draft
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
          {charCount < CHAR_MIN
            && ` (minimum ${CHAR_MIN})`}
        </Box>
        <Button
          fluid
          mt={1}
          icon={has_submitted ? 'edit' : 'paper-plane'}
          content={has_submitted ? 'Update Prescript' : 'Submit Prescript'}
          disabled={!isValidLength}
          onClick={handleSubmit}
        />
      </Section>
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
      <div style={{ overflow: 'hidden', width: '100%', minWidth: 0 }}>
        <div style={{ textAlign: 'center', marginBottom: '24px' }}>
          <img
            src={resolveAsset('index_logo.png')}
            style={{ width: '150px', height: 'auto' }}
          />
        </div>
        <div style={{ ...textStyle, color: '#666' }}>
          No prescript available.
        </div>
      </div>
    );
  }

  return (
    <div style={{ overflow: 'hidden', width: '100%', minWidth: 0 }}>
      <div style={{ textAlign: 'center', marginBottom: '24px' }}>
        <img
          src={resolveAsset('index_logo.png')}
          style={{ width: '150px', height: 'auto' }}
        />
      </div>
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
