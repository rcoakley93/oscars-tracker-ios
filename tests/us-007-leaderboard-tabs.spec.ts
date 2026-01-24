import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const OSCARS_TRACKER_ROOT = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker');

test.describe('US-007: Implement Leaderboard with Tabs', () => {
  test('LeaderboardTab enum exists with Movies Watched and Correct Predictions', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check enum exists
    expect(content).toContain('enum LeaderboardTab');
    expect(content).toContain('case moviesWatched');
    expect(content).toContain('case correctPredictions');
  });

  test('LeaderboardTab has raw values for display', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check raw values
    expect(content).toContain('"Movies Watched"');
    expect(content).toContain('"Correct Predictions"');
  });

  test('LeaderboardView has selectedTab state variable', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check state variable
    expect(content).toContain('@State private var selectedTab');
    expect(content).toContain('LeaderboardTab');
  });

  test('Segmented control Picker exists for tab selection', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check Picker with segmented style
    expect(content).toContain('Picker(');
    expect(content).toContain('.pickerStyle(.segmented)');
    expect(content).toContain('selection: $selectedTab');
  });

  test('Content switches based on selectedTab', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check switch statement for tab content
    expect(content).toContain('switch selectedTab');
    expect(content).toContain('case .moviesWatched');
    expect(content).toContain('case .correctPredictions');
  });

  test('Movies Watched tab displays leaderboard list', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check moviesWatchedContent exists with leaderboard list
    expect(content).toContain('moviesWatchedContent');
    expect(content).toContain('leaderboardList');
  });

  test('LeaderboardRowView shows username', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check username display
    expect(content).toContain('Text(entry.username)');
  });

  test('LeaderboardRowView shows watched count', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check watched count display
    expect(content).toContain('entry.watchedCount');
    expect(content).toContain('"watched"');
  });

  test('LeaderboardRowView shows watched percentage', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check percentage display
    expect(content).toContain('watchedPercentageText');
    expect(content).toContain('% complete');
  });

  test('Correct Predictions tab shows Coming Soon placeholder', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check Coming Soon content
    expect(content).toContain('correctPredictionsContent');
    expect(content).toContain('"Coming Soon"');
  });

  test('Correct Predictions tab has sparkles icon', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check sparkles icon for coming soon
    expect(content).toContain('"sparkles"');
  });

  test('Correct Predictions tab has explanatory message', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check explanatory text
    expect(content).toContain('Academy Awards ceremony');
  });

  test('Data is fetched via loadData on appear', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check data loading
    expect(content).toContain('.task');
    expect(content).toContain('viewModel.loadData()');
  });

  test('Pull to refresh calls loadData', async () => {
    const leaderboardPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardPath, 'utf-8');

    // Check refreshable
    expect(content).toContain('.refreshable');
    expect(content).toContain('await viewModel.loadData()');
  });
});
