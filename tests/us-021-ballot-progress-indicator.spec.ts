import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-021: Ballot - Progress Indicator', () => {
  test('BallotProgressCard exists in BallotView', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for BallotProgressCard struct
    expect(content).toContain('struct BallotProgressCard');
    expect(content).toContain('ballotProgressCard');
  });

  test('Progress card shows completed/total categories', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for count display
    expect(content).toContain('predictedCount');
    expect(content).toContain('totalCategories');
    expect(content).toContain('categories predicted');
  });

  test('Gold progress bar visualization', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for progress bar component
    expect(content).toContain('struct BallotProgressBar');
    expect(content).toContain('BallotProgressBar(progress:');
    expect(content).toContain('LinearGradient.gold');
  });

  test('Progress bar uses GeometryReader for width calculation', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for GeometryReader pattern
    expect(content).toContain('GeometryReader');
    expect(content).toContain('geometry.size.width * progress');
  });

  test('Progress bar has animation', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for animation
    expect(content).toContain('.animation(');
    expect(content).toContain('.easeInOut');
    expect(content).toContain('value: progress');
  });

  test('Updates in real-time via viewModel binding', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check that progress card uses viewModel's computed properties
    expect(content).toContain('viewModel.predictedCategories');
    expect(content).toContain('viewModel.totalCategories');
  });

  test('Shows percentage complete', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for percentage display
    expect(content).toContain('percentageString');
    expect(content).toContain('%.0f%%');
  });

  test('Progress calculation is correct', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for progress calculation
    expect(content).toContain('private var progress: Double');
    expect(content).toContain('Double(predictedCount) / Double(totalCategories)');
  });

  test('Handles zero total categories gracefully', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for guard against division by zero
    expect(content).toContain('guard totalCategories > 0');
    expect(content).toContain('return 0');
  });

  test('Progress card uses glass card styling', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for glass card styling
    expect(content).toContain('.glassCard()');
  });

  test('Progress card has header with icon', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for header elements
    expect(content).toContain('checkmark.seal.fill');
    expect(content).toContain('Ballot Progress');
    expect(content).toContain('Color.goldPrimary');
  });

  test('Accessibility support for progress card', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('accessibilityElement(children: .combine)');
    expect(content).toContain('accessibilityLabel');
    expect(content).toContain('Ballot progress');
  });

  test('BallotViewModel has predictedCategories computed property', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for predictedCategories
    expect(content).toContain('var predictedCategories: Int');
    expect(content).toContain('predictions.count');
  });

  test('BallotViewModel has totalCategories computed property', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for totalCategories
    expect(content).toContain('var totalCategories: Int');
    expect(content).toContain('categories.count');
  });

  test('Progress card positioned above category grid', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check that progress card appears before category grid
    const progressCardIndex = content.indexOf('ballotProgressCard');
    const categoryGridIndex = content.indexOf('categoryGrid');

    // ballotProgressCard should appear before categoryGrid in the else branch
    expect(progressCardIndex).toBeLessThan(categoryGridIndex);
  });

  test('Progress bar has rounded corners', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for rounded corners on progress bar
    expect(content).toContain('RoundedRectangle(cornerRadius:');
  });

  test('Progress bar has background track', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for background color
    expect(content).toContain('Color.borderColor');
    expect(content).toContain('ZStack(alignment: .leading)');
  });
});
