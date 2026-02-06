import { useBackend } from '../backend';
import { Box, Button, Section, Stack } from '../components';
import { Window } from '../layouts';

const RESULT_COLORS = {
  'PERFECT!': '#ffd700',
  'Good': '#7cfc00',
  'Okay': '#daa520',
  'Miss': '#dc143c',
};

const GRADE_COLORS = {
  F: '#8b0000',
  C: '#cd853f',
  B: '#b8860b',
  A: '#228b22',
  S: '#ffd700',
};

export const SculptingMinigame = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    active,
    currentRound,
    totalRounds,
    score,
    combo,
    bestCombo,
    needlePosition,
    sweetSpots = [],
    awaitingInput,
    lastHitResult,
    difficulty,
    gameOver,
    finalGrade,
  } = data;

  return (
    <Window width={520} height={400} title="Sculpting">
      <Window.Content
        style={{
          background:
            'linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f0f23 100%)',
        }}
      >
        <Stack vertical fill>
          {!active && !gameOver && <StartScreen />}
          {!!active && !gameOver && (
            <GameScreen
              currentRound={currentRound}
              totalRounds={totalRounds}
              score={score}
              combo={combo}
              bestCombo={bestCombo}
              needlePosition={needlePosition}
              sweetSpots={sweetSpots}
              awaitingInput={awaitingInput}
              lastHitResult={lastHitResult}
              difficulty={difficulty}
            />
          )}
          {!!gameOver && (
            <GameOverScreen
              score={score}
              bestCombo={bestCombo}
              finalGrade={finalGrade}
            />
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};

const StartScreen = (props, context) => {
  const { act } = useBackend(context);

  return (
    <Section
      fill
      style={{
        border: '2px solid #8b4513',
        borderRadius: '8px',
        background: 'rgba(0, 0, 0, 0.4)',
      }}
    >
      <Stack vertical fill justify="center" align="center">
        <Stack.Item>
          <Box
            fontSize="1.8em"
            bold
            textAlign="center"
            mb={1}
            style={{
              color: '#d4af37',
              textShadow: '0 0 10px rgba(212, 175, 55, 0.5)',
              fontStyle: 'italic',
            }}
          >
            The Art of Refinement
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box
            textAlign="center"
            color="label"
            mb={2}
            style={{ lineHeight: '1.6' }}
          >
            Time your sculpts to strike the golden zones.
            <br />
            <Box as="span" color="#ffd700">
              Perfect strikes
            </Box>{' '}
            at the center yield greater rewards.
            <br />
            Chain your successes to build{' '}
            <Box as="span" color="#7cfc00">
              artistic momentum
            </Box>
            .
          </Box>
        </Stack.Item>
        <Stack.Item mt={2}>
          <Button
            fluid
            fontSize="1.3em"
            icon="palette"
            content="Begin Refinement"
            onClick={() => act('start')}
            style={{
              background: 'linear-gradient(135deg, #8b4513, #d4af37)',
              border: 'none',
              padding: '10px 30px',
            }}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const GameScreen = (props, context) => {
  const { act } = useBackend(context);
  const {
    currentRound,
    totalRounds,
    score,
    combo,
    bestCombo,
    needlePosition,
    sweetSpots,
    awaitingInput,
    lastHitResult,
  } = props;

  return (
    <Stack vertical fill>
      {/* Header Stats */}
      <Stack.Item>
        <Section
          style={{
            border: '1px solid #8b4513',
            background: 'rgba(0, 0, 0, 0.3)',
          }}
        >
          <Stack justify="space-between" align="center">
            <Stack.Item>
              <Box bold color="#d4af37">
                Round: {currentRound}/{totalRounds}
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Box
                bold
                fontSize="1.2em"
                style={{
                  color: '#ffd700',
                  textShadow: '0 0 5px rgba(255, 215, 0, 0.3)',
                }}
              >
                Score: {score || 0}
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Box bold color={combo >= 3 ? '#7cfc00' : '#aaa'}>
                Combo: {combo || 0}
                {!!combo && combo >= 5 && ' (x2)'}
                {!!combo && combo >= 3 && combo < 5 && ' (x1.5)'}
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Box color="label" fontSize="0.9em">
                Best: {bestCombo || 0}
              </Box>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>

      {/* The Bar */}
      <Stack.Item grow>
        <Section
          fill
          style={{
            border: '1px solid #8b4513',
            background: 'rgba(0, 0, 0, 0.3)',
          }}
        >
          <Stack vertical fill justify="center">
            <Stack.Item>
              <TimingBar
                needlePosition={needlePosition}
                sweetSpots={sweetSpots}
              />
            </Stack.Item>

            {/* Result Display */}
            <Stack.Item>
              <Box
                textAlign="center"
                fontSize="2em"
                bold
                mt={2}
                style={{
                  minHeight: '2.5em',
                  color: RESULT_COLORS[lastHitResult] || 'transparent',
                  textShadow: lastHitResult
                    ? `0 0 15px ${RESULT_COLORS[lastHitResult] || '#fff'}`
                    : 'none',
                  fontStyle: 'italic',
                }}
              >
                {lastHitResult || '\u00A0'}
              </Box>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>

      {/* Input Button */}
      <Stack.Item>
        <Button
          fluid
          disabled={!awaitingInput}
          fontSize="1.4em"
          icon="hammer"
          content={awaitingInput ? 'SCULPT! (Click or Spacebar)' : 'Wait...'}
          onClick={() => act('sculpt')}
          style={{
            background: awaitingInput
              ? 'linear-gradient(135deg, #228b22, #32cd32)'
              : 'linear-gradient(135deg, #333, #444)',
            border: awaitingInput ? '2px solid #7cfc00' : '2px solid #555',
            padding: '12px',
            transition: 'all 0.2s ease',
          }}
        />
      </Stack.Item>
    </Stack>
  );
};

const TimingBar = (props) => {
  const { needlePosition, sweetSpots } = props;
  const safePosition = needlePosition || 0;

  return (
    <Box
      style={{
        position: 'relative',
        height: '80px',
        background:
          'linear-gradient(180deg, #1a1a1a 0%, #2d2d2d 50%, #1a1a1a 100%)',
        border: '3px solid #8b4513',
        borderRadius: '8px',
        overflow: 'visible',
        boxShadow: 'inset 0 2px 10px rgba(0, 0, 0, 0.5)',
      }}
    >
      {/* Track markings */}
      {[0, 25, 50, 75, 100].map(mark => (
        <Box
          key={mark}
          style={{
            position: 'absolute',
            left: `${mark}%`,
            top: '0',
            width: '1px',
            height: '100%',
            backgroundColor: 'rgba(139, 69, 19, 0.3)',
            zIndex: 1,
          }}
        />
      ))}

      {/* Sweet Spots */}
      {sweetSpots.map((spot, index) => {
        const width = (spot.end || 0) - (spot.start || 0);
        const perfectWidth = (spot.perfectEnd || 0) - (spot.perfectStart || 0);
        const perfectOffset = ((spot.perfectStart || 0) - (spot.start || 0))
          / (width || 1) * 100;
        const perfectWidthPct = perfectWidth / (width || 1) * 100;

        return (
          <Box
            key={index}
            style={{
              position: 'absolute',
              left: `${spot.start || 0}%`,
              width: `${width}%`,
              height: '100%',
              background:
                'linear-gradient(180deg, rgba(34, 139, 34, 0.6) 0%, '
                + 'rgba(34, 139, 34, 0.4) 50%, rgba(34, 139, 34, 0.6) 100%)',
              borderLeft: '2px solid #32cd32',
              borderRight: '2px solid #32cd32',
              zIndex: 2,
              boxSizing: 'border-box',
            }}
          >
            {/* Perfect Center Zone */}
            <Box
              style={{
                position: 'absolute',
                left: `${perfectOffset}%`,
                width: `${perfectWidthPct}%`,
                height: '100%',
                background:
                  'linear-gradient(180deg, rgba(255, 215, 0, 0.8) 0%, '
                  + 'rgba(255, 215, 0, 0.6) 50%, rgba(255, 215, 0, 0.8) 100%)',
                boxShadow: '0 0 10px rgba(255, 215, 0, 0.5)',
              }}
            />
          </Box>
        );
      })}

      {/* Needle Glow */}
      <Box
        style={{
          position: 'absolute',
          left: `${safePosition}%`,
          top: '0',
          width: '20px',
          height: '100%',
          background:
            'radial-gradient(ellipse at center, '
            + 'rgba(255, 255, 255, 0.3) 0%, transparent 70%)',
          transform: 'translateX(-50%)',
          zIndex: 3,
          pointerEvents: 'none',
        }}
      />

      {/* Needle */}
      <Box
        style={{
          position: 'absolute',
          left: `${safePosition}%`,
          top: '0',
          width: '4px',
          height: '100%',
          backgroundColor: '#fff',
          boxShadow: '0 0 8px #fff, 0 0 15px rgba(255, 255, 255, 0.5)',
          transform: 'translateX(-50%)',
          zIndex: 4,
        }}
      />

      {/* Needle Arrow at top */}
      <Box
        style={{
          position: 'absolute',
          left: `${safePosition}%`,
          top: '-12px',
          transform: 'translateX(-50%)',
          width: '0',
          height: '0',
          borderLeft: '10px solid transparent',
          borderRight: '10px solid transparent',
          borderTop: '12px solid #ffd700',
          filter: 'drop-shadow(0 0 4px rgba(255, 215, 0, 0.8))',
          zIndex: 5,
        }}
      />
    </Box>
  );
};

const GameOverScreen = (props, context) => {
  const { act } = useBackend(context);
  const { score, bestCombo, finalGrade } = props;

  const gradeColor = GRADE_COLORS[finalGrade] || '#fff';
  const isExcellent = finalGrade === 'S' || finalGrade === 'A';

  return (
    <Section
      fill
      style={{
        border: '2px solid #8b4513',
        borderRadius: '8px',
        background: 'rgba(0, 0, 0, 0.4)',
      }}
    >
      <Stack vertical fill justify="center" align="center">
        <Stack.Item>
          <Box
            fontSize="1.6em"
            bold
            textAlign="center"
            mb={1}
            style={{
              color: '#d4af37',
              fontStyle: 'italic',
            }}
          >
            Refinement Complete
          </Box>
        </Stack.Item>

        <Stack.Item>
          <Box
            fontSize="5em"
            bold
            textAlign="center"
            style={{
              color: gradeColor,
              textShadow: isExcellent
                ? `0 0 30px ${gradeColor}, 0 0 60px ${gradeColor}`
                : `0 0 15px ${gradeColor}`,
              fontFamily: 'serif',
            }}
          >
            {finalGrade}
          </Box>
        </Stack.Item>

        <Stack.Item>
          <Box textAlign="center" color="label" mb={2} fontSize="1.1em">
            <Box>
              Final Score:{' '}
              <Box as="span" color="#ffd700" bold>
                {score || 0}
              </Box>
            </Box>
            <Box mt={0.5}>
              Best Combo:{' '}
              <Box as="span" color="#7cfc00" bold>
                {bestCombo || 0}
              </Box>
            </Box>
          </Box>
        </Stack.Item>

        <Stack.Item>
          <GradeDescription grade={finalGrade} />
        </Stack.Item>

        <Stack.Item mt={2}>
          <Button
            fluid
            icon="check"
            content="Complete"
            onClick={() => act('close')}
            style={{
              background: 'linear-gradient(135deg, #8b4513, #d4af37)',
              border: 'none',
              padding: '10px 40px',
              fontSize: '1.1em',
            }}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const GradeDescription = (props) => {
  const { grade } = props;

  const descriptions = {
    F: 'The work speaks of untrained hands and wavering vision.',
    C: 'Competence emerges, though refinement remains elusive.',
    B: 'A steady hand guides deliberate strokes of intention.',
    A: 'Mastery flows through each precise, purposeful motion.',
    S: 'Transcendence - where artist and art become one.',
  };

  return (
    <Box
      textAlign="center"
      italic
      fontSize="1.05em"
      style={{
        color: GRADE_COLORS[grade] || '#aaa',
        textShadow: `0 0 8px ${GRADE_COLORS[grade] || '#aaa'}33`,
        padding: '0 20px',
        lineHeight: '1.5',
      }}
    >
      &quot;{descriptions[grade] || 'Unknown'}&quot;
    </Box>
  );
};
