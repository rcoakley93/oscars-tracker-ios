import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-023: Ballot - Winner Display', () => {
  test('isWinner field in Nomination model', async () => {
    const nominationPath = path.join(OSCARS_TRACKER_PATH, 'Models', 'Nomination.swift');
    const content = fs.readFileSync(nominationPath, 'utf-8');

    // Check for isWinner field
    expect(content).toContain('isWinner');
    expect(content).toContain('is_winner');
    expect(content).toContain('Bool?');
  });

  test('WinnerBadge component exists', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check for WinnerBadge struct
    expect(content).toContain('struct WinnerBadge');
    expect(content).toContain('trophy.fill');
    expect(content).toContain('WINNER');
  });

  test('Winner badge shown on winning nomination', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check for winner badge display
    expect(content).toContain('if isWinner');
    expect(content).toContain('WinnerBadge()');
  });

  test('NominationRow has isWinner parameter', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check NominationRow parameters
    expect(content).toContain('let isWinner: Bool');
  });

  test('NominationRow has isUserCorrect parameter', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check for user correct parameter
    expect(content).toContain('let isUserCorrect: Bool');
  });

  test('NominationRow has isUserIncorrect parameter', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check for user incorrect parameter
    expect(content).toContain('let isUserIncorrect: Bool');
  });

  test('Correct predictions highlighted with success color', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check for success color on correct predictions
    expect(content).toContain('isUserCorrect');
    expect(content).toContain('Color.success');
  });

  test('Incorrect predictions shown with destructive color', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check for destructive color on incorrect predictions
    expect(content).toContain('isUserIncorrect');
    expect(content).toContain('Color.destructive');
  });

  test('BallotViewModel has hasWinner function', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for hasWinner function
    expect(content).toContain('func hasWinner(for category:');
    expect(content).toContain('isWinner == true');
  });

  test('BallotViewModel has winningNomination function', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for winningNomination function
    expect(content).toContain('func winningNomination(for category:');
    expect(content).toContain('Nomination?');
  });

  test('BallotViewModel has isPredictionCorrect function', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for isPredictionCorrect function
    expect(content).toContain('func isPredictionCorrect(for category:');
    expect(content).toContain('userPredictionId == winner.id');
  });

  test('BallotViewModel has isPredictionIncorrect function', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for isPredictionIncorrect function
    expect(content).toContain('func isPredictionIncorrect(for category:');
    expect(content).toContain('!isPredictionCorrect');
  });

  test('Points earned displayed per category', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for pointsEarned function
    expect(content).toContain('func pointsEarned(for category:');
    expect(content).toContain('category.pointsValue');
  });

  test('CategoryCard shows points earned when winner announced', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check for points display in category header
    expect(content).toContain('pointsEarned');
    expect(content).toContain('hasWinner');
    expect(content).toContain('+\\(pointsEarned) pts');
  });

  test('CategoryCard has border based on prediction result', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check for border overlay
    expect(content).toContain('.overlay(');
    expect(content).toContain('RoundedRectangle(cornerRadius: 16)');
    expect(content).toContain('.stroke(');
    expect(content).toContain('isPredictionCorrect');
  });

  test('Checkmark icon shown for correct prediction', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check for checkmark icon
    expect(content).toContain('checkmark.circle.fill');
  });

  test('X icon shown for incorrect prediction', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check for xmark icon
    expect(content).toContain('xmark.circle.fill');
  });

  test('Total points earned computed property', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for totalPointsEarned property
    expect(content).toContain('var totalPointsEarned: Int');
    expect(content).toContain('reduce(0)');
  });

  test('Max possible points computed property', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for maxPossiblePoints property
    expect(content).toContain('var maxPossiblePoints: Int');
  });

  test('Background color changes based on prediction result', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check for backgroundColor computed property
    expect(content).toContain('var backgroundColor: Color');
    expect(content).toContain('success.opacity');
    expect(content).toContain('destructive.opacity');
  });

  test('Title color changes based on prediction result', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check for titleColor computed property
    expect(content).toContain('var titleColor: Color');
    expect(content).toContain('foregroundStyle(titleColor)');
  });

  test('Accessibility labels updated for winner status', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check for accessibility labels
    expect(content).toContain('winner');
    expect(content).toContain('correct prediction');
    expect(content).toContain('incorrect prediction');
    expect(content).toContain('accessibilityLabel');
  });
});
