import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-024: Leaderboard - Global Rankings', () => {
  test('LeaderboardView exists', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check for LeaderboardView struct
    expect(content).toContain('struct LeaderboardView');
    expect(content).toContain('NavigationStack');
  });

  test('LeaderboardViewModel exists', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'LeaderboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for LeaderboardViewModel class
    expect(content).toContain('class LeaderboardViewModel');
    expect(content).toContain('ObservableObject');
  });

  test('Calls get_leaderboard RPC', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'LeaderboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for RPC call
    expect(content).toContain('.rpc("get_leaderboard")');
    expect(content).toContain('LeaderboardEntry');
  });

  test('Displays users sorted by rank', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check for user display
    expect(content).toContain('entry.rank');
    expect(content).toContain('entry.username');
  });

  test('LeaderboardRowView exists', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check for row view
    expect(content).toContain('struct LeaderboardRowView');
    expect(content).toContain('let entry: LeaderboardEntry');
  });

  test('Shows medal for top 3 (gold, silver, bronze)', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'LeaderboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for medal types
    expect(content).toContain('enum MedalType');
    expect(content).toContain('case gold');
    expect(content).toContain('case silver');
    expect(content).toContain('case bronze');
  });

  test('medalType function returns correct medal for rank', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'LeaderboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for medalType function
    expect(content).toContain('func medalType(for rank: Int)');
    expect(content).toContain('case 1:');
    expect(content).toContain('case 2:');
    expect(content).toContain('case 3:');
    expect(content).toContain('return .gold');
    expect(content).toContain('return .silver');
    expect(content).toContain('return .bronze');
  });

  test('Shows watched count per user', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check for watched count display
    expect(content).toContain('entry.watchedCount');
    expect(content).toContain('watched');
    expect(content).toContain('eye.fill');
  });

  test('Shows prediction score per user', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check for prediction score display
    expect(content).toContain('entry.predictionScore');
    expect(content).toContain('correct');
    expect(content).toContain('checkmark.circle.fill');
  });

  test('Pull to refresh functionality', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check for refresh
    expect(content).toContain('.refreshable');
    expect(content).toContain('viewModel.loadData()');
  });

  test('Highlights current user', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const viewModelContent = fs.readFileSync(path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'LeaderboardViewModel.swift'), 'utf-8');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check for current user handling
    expect(viewModelContent).toContain('currentUserId');
    expect(viewModelContent).toContain('func isCurrentUser');
    expect(content).toContain('isCurrentUser');
    expect(content).toContain('star.fill');
  });

  test('Medal colors for top 3', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check for medal colors
    expect(content).toContain('func medalColor');
    expect(content).toContain('Color.goldPrimary');
  });

  test('Loading state shown', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check for loading state
    expect(content).toContain('viewModel.isLoading');
    expect(content).toContain('loadingView');
    expect(content).toContain('ProgressView()');
  });

  test('Empty state shown when no entries', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check for empty state
    expect(content).toContain('emptyStateView');
    expect(content).toContain('entries.isEmpty');
    expect(content).toContain('No rankings yet');
  });

  test('Glass card styling for rows', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check for card styling
    expect(content).toContain('RoundedRectangle');
    expect(content).toContain('Color.cardBackground');
    expect(content).toContain('Color.borderColor');
  });

  test('Accessibility labels for rows', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('accessibilityElement');
    expect(content).toContain('accessibilityLabel');
    expect(content).toContain('Rank');
  });

  test('Files registered in Xcode project', async () => {
    const projectPath = path.join(XCODE_PROJECT_PATH, 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const content = fs.readFileSync(projectPath, 'utf-8');

    // Check that files are registered
    expect(content).toContain('LeaderboardView.swift');
    expect(content).toContain('LeaderboardViewModel.swift');
  });

  test('ContentView uses LeaderboardView', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check that LeaderboardView is used
    expect(content).toContain('LeaderboardView()');
  });

  test('ViewModel has entries @Published property', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'LeaderboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for entries property
    expect(content).toContain('@Published var entries: [LeaderboardEntry]');
  });

  test('Error handling in loadData', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'LeaderboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for error handling
    expect(content).toContain('errorMessage');
    expect(content).toContain('catch');
    expect(content).toContain('Failed to load leaderboard');
  });
});
