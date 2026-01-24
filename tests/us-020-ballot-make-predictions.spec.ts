import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-020: Ballot - Make Predictions', () => {
  test('NominationRow has radio button style selection', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for radio button UI elements
    expect(content).toContain('Circle()');
    expect(content).toContain('.stroke');
    expect(content).toContain('.fill');
    expect(content).toContain('frame(width: 22, height: 22)');
    expect(content).toContain('frame(width: 12, height: 12)');
  });

  test('NominationRow accepts isSelected and onSelect props', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for selection props
    expect(content).toContain('let isSelected: Bool');
    expect(content).toContain('let onSelect: () -> Void');
  });

  test('Only one nomination selectable per category (radio behavior)', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for predictions dictionary (categoryId -> nominationId)
    expect(content).toContain('predictions: [Int: Int]');
    expect(content).toContain('categoryId');
    expect(content).toContain('nominationId');
  });

  test('BallotViewModel has isSelected function', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for isSelected function
    expect(content).toContain('func isSelected(nomination: Nomination)');
    expect(content).toContain('predictions[categoryId] == nomination.id');
  });

  test('BallotViewModel has selectPrediction function', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for selectPrediction function
    expect(content).toContain('func selectPrediction(nomination: Nomination)');
    expect(content).toContain('predictions[categoryId] = nomination.id');
  });

  test('Gold highlight on selected nomination', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for gold styling on selected items
    expect(content).toContain('isSelected ? Color.goldPrimary');
    expect(content).toContain('Color.goldPrimary.opacity(0.1)');
    expect(content).toContain('Color.goldPrimary.opacity(0.3)');
  });

  test('Light haptic on selection', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for haptic feedback
    expect(content).toContain('HapticManager.light()');
  });

  test('Auto-saves to user_predictions via upsert', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for upsert to user_predictions
    expect(content).toContain('"user_predictions"');
    expect(content).toContain('.upsert');
    expect(content).toContain('onConflict');
  });

  test('Loads user predictions on data load', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for loading predictions
    expect(content).toContain('UserPrediction');
    expect(content).toContain('"user_predictions"');
    expect(content).toContain('predictionsMap');
  });

  test('Visual checkmark on selected item', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for checkmark icon
    expect(content).toContain('checkmark.circle.fill');
    expect(content).toContain('if isSelected');
  });

  test('Optimistic UI update pattern', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for optimistic update with rollback
    expect(content).toContain('previousPrediction');
    expect(content).toContain('Optimistic update');
    expect(content).toContain('Rollback');
  });

  test('NominationRow is wrapped in Button for tap handling', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for Button wrapper
    expect(content).toContain('Button(action: onSelect)');
    expect(content).toContain('.buttonStyle(.plain)');
  });

  test('CategoryCard passes viewModel.isSelected to NominationRow', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for passing isSelected to NominationRow
    expect(content).toContain('viewModel.isSelected(nomination: nomination)');
    expect(content).toContain('viewModel.selectPrediction(nomination: nomination)');
  });

  test('Accessibility labels for selected state', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for accessibility on selection
    expect(content).toContain('"selected"');
    expect(content).toContain('"not selected"');
    expect(content).toContain('accessibilityHint');
  });

  test('Error handling on save failure', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for error handling
    expect(content).toContain('HapticManager.error()');
    expect(content).toContain('Failed to save prediction');
    expect(content).toContain('errorMessage');
  });

  test('Prediction data structure matches Supabase schema', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for correct field names
    expect(content).toContain('"user_id"');
    expect(content).toContain('"category_id"');
    expect(content).toContain('"nomination_id"');
    expect(content).toContain('AnyJSON');
  });

  test('Gets current user from Supabase auth session', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for auth session usage
    expect(content).toContain('supabase.auth.session');
    expect(content).toContain('user.id');
    expect(content).toContain('uuidString');
  });

  test('PredictedCategories computed property', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for predictedCategories
    expect(content).toContain('predictedCategories');
    expect(content).toContain('predictions.count');
  });
});
