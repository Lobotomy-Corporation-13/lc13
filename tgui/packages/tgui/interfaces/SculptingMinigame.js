import { useBackend } from '../backend';
import { Box, Button, Section, Stack } from '../components';
import { Window } from '../layouts';

const RESULT_COLORS = {
  'PERFECT!': '#ffd700',
  'Good': '#00ff00',
  'Okay': '#ffff00',
  'Miss': '#ff0000',
};

const GRADE_COLORS = {
  'F': '#ff4444',
  'C': '#ff8844',
  'B': '#ffff44',
  'A': '#44ff44',
  'S': '#ffd700',
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
    <Window width={500} height={350} title="Sculpting">
      <Window.Content>
        <Stack vertical fill>
          {!active && !gameOver && <StartScreen />}
          {active && !gameOver && (
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
          {gameOver && (
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
    <Section fill>
      <Stack vertical fill justify="center" align="center">
        <Stack.Item>
          <Box fontSize="1.5em" bold textAlign="center" mb={2}>
            Sculpting Minigame
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box textAlign="center" color="label" mb={2}>
            Time your sculpts to hit the green zones!
            <br />
            Perfect hits in the bright center score more points.
            <br />
            Build combos for bonus multipliers!
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Button
            fluid
            color="good"
            fontSize="1.2em"
            icon="play"
            content="Begin Sculpting"
            onClick={() => act('start')}
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
        <Section>
          <Stack justify="space-between">
            <Stack.Item>
              <Box bold>
                Round: {currentRound}/{totalRounds}
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Box bold>Score: {score}</Box>
            </Stack.Item>
            <Stack.Item>
              <Box bold color={combo >= 3 ? 'good' : 'white'}>
                Combo: {combo}
                {combo >= 5 && ' (x2)'}
                {combo >= 3 && combo < 5 && ' (x1.5)'}
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Box color="label">Best: {bestCombo}</Box>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>

      {/* The Bar */}
      <Stack.Item grow>
        <Section fill>
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
                fontSize="1.5em"
                bold
                mt={2}
                color={RESULT_COLORS[lastHitResult] || 'white'}
                style={{ minHeight: '2em' }}
              >
                {lastHitResult}
              </Box>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>

      {/* Input Button */}
      <Stack.Item>
        <Button
          fluid
          color={awaitingInput ? 'good' : 'grey'}
          disabled={!awaitingInput}
          fontSize="1.3em"
          icon="hand-pointer"
          content={awaitingInput ? 'SCULPT! (Click or Spacebar)' : 'Wait...'}
          onClick={() => act('sculpt')}
        />
      </Stack.Item>
    </Stack>
  );
};

const TimingBar = (props) => {
  const { needlePosition, sweetSpots } = props;

  return (
    <Box
      style={{
        position: 'relative',
        height: '60px',
        backgroundColor: '#333',
        border: '2px solid #666',
        borderRadius: '4px',
        overflow: 'hidden',
      }}
    >
      {/* Sweet Spots */}
      {sweetSpots.map((spot, index) => (
        <Box
          key={index}
          style={{
            position: 'absolute',
            left: `${spot.start}%`,
            width: `${spot.end - spot.start}%`,
            height: '100%',
            backgroundColor: 'rgba(0, 128, 0, 0.5)',
            borderLeft: '2px solid #0f0',
            borderRight: '2px solid #0f0',
          }}
        >
          {/* Perfect Center Zone */}
          <Box
            style={{
              position: 'absolute',
              left: `${((spot.perfectStart - spot.start) / (spot.end - spot.start)) * 100}%`,
              width: `${((spot.perfectEnd - spot.perfectStart) / (spot.end - spot.start)) * 100}%`,
              height: '100%',
              backgroundColor: 'rgba(0, 255, 0, 0.7)',
            }}
          />
        </Box>
      ))}

      {/* Needle */}
      <Box
        style={{
          position: 'absolute',
          left: `${needlePosition}%`,
          top: '0',
          width: '4px',
          height: '100%',
          backgroundColor: '#fff',
          boxShadow: '0 0 10px #fff',
          transform: 'translateX(-50%)',
          transition: 'left 0.05s linear',
        }}
      />

      {/* Needle Arrow at bottom */}
      <Box
        style={{
          position: 'absolute',
          left: `${needlePosition}%`,
          bottom: '-10px',
          transform: 'translateX(-50%)',
          width: '0',
          height: '0',
          borderLeft: '8px solid transparent',
          borderRight: '8px solid transparent',
          borderBottom: '10px solid #fff',
        }}
      />
    </Box>
  );
};

const GameOverScreen = (props, context) => {
  const { act } = useBackend(context);
  const { score, bestCombo, finalGrade } = props;

  return (
    <Section fill>
      <Stack vertical fill justify="center" align="center">
        <Stack.Item>
          <Box fontSize="1.5em" bold textAlign="center" mb={1}>
            Refinement Complete!
          </Box>
        </Stack.Item>

        <Stack.Item>
          <Box
            fontSize="4em"
            bold
            textAlign="center"
            color={GRADE_COLORS[finalGrade] || 'white'}
            style={{
              textShadow:
                finalGrade === 'S' ? '0 0 20px gold' : '0 0 10px currentColor',
            }}
          >
            {finalGrade}
          </Box>
        </Stack.Item>

        <Stack.Item>
          <Box textAlign="center" color="label" mb={2}>
            Final Score: {score}
            <br />
            Best Combo: {bestCombo}
          </Box>
        </Stack.Item>

        <Stack.Item>
          <GradeDescription grade={finalGrade} />
        </Stack.Item>

        <Stack.Item mt={2}>
          <Button
            fluid
            color="blue"
            icon="check"
            content="Close"
            onClick={() => act('close')}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const GradeDescription = (props) => {
  const { grade } = props;

  const descriptions = {
    F: 'The craftsmanship is crude and amateurish.',
    C: 'Basic competence, but lacking refinement.',
    B: 'Solid technique with clear artistic intent.',
    A: 'Masterful technique, every cut deliberate.',
    S: 'Transcendent skill that defies comprehension.',
  };

  return (
    <Box
      textAlign="center"
      italic
      color={GRADE_COLORS[grade]}
      fontSize="1.1em"
    >
      "{descriptions[grade] || 'Unknown'}"
    </Box>
  );
};
