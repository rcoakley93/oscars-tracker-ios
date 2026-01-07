import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-025: Leaderboard - Current User Highlight', () => {
  test('Gold border on current user row', async () => {
    const leaderboardViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardViewPath, 'utf-8');

    // Check for gold border on current user
    expect(content).toContain('isCurrentUser');
    expect(content).toContain('Color.goldPrimary');
    expect(content).toContain('.stroke(isCurrentUser ?');
  });

  test('Star icon next to current user', async () => {
    const leaderboardViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardViewPath, 'utf-8');

    // Check for star icon
    expect(content).toContain('if isCurrentUser');
    expect(content).toContain('star.fill');
  });

  test('ScrollViewReader wraps ScrollView for scroll control', async () => {
    const leaderboardViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardViewPath, 'utf-8');

    // Check for ScrollViewReader
    expect(content).toContain('ScrollViewReader');
    expect(content).toContain('proxy');
  });

  test('scrollToCurrentUser function exists', async () => {
    const leaderboardViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardViewPath, 'utf-8');

    // Check for scroll function
    expect(content).toContain('scrollToCurrentUser');
    expect(content).toContain('proxy.scrollTo');
  });

  test('Scroll uses animated transition', async () => {
    const leaderboardViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardViewPath, 'utf-8');

    // Check for animation
    expect(content).toContain('withAnimation');
    expect(content).toContain('.easeInOut');
  });

  test('Entries have id modifier for scroll targeting', async () => {
    const leaderboardViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardViewPath, 'utf-8');

    // Check for id modifier
    expect(content).toContain('.id(entry.id)');
  });

  test('onChange triggers scroll when entries change', async () => {
    const leaderboardViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardViewPath, 'utf-8');

    // Check for onChange
    expect(content).toContain('.onChange(of: viewModel.entries)');
    expect(content).toContain('scrollToCurrentUser');
  });

  test('LeaderboardViewModel has currentUserEntry property', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'LeaderboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for currentUserEntry
    expect(content).toContain('var currentUserEntry');
    expect(content).toContain('LeaderboardEntry?');
  });

  test('LeaderboardViewModel has isCurrentUser function', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'LeaderboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for isCurrentUser function
    expect(content).toContain('func isCurrentUser');
    expect(content).toContain('entry.userId == currentUserId');
  });

  test('Current user row has different line width', async () => {
    const leaderboardViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardViewPath, 'utf-8');

    // Check for different stroke width
    expect(content).toContain('lineWidth: isCurrentUser ? 2 : 1');
  });

  test('Current user username shown in gold', async () => {
    const leaderboardViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardViewPath, 'utf-8');

    // Check for gold username
    expect(content).toContain('isCurrentUser ? Color.goldPrimary : Color.textPrimary');
  });

  test('Scroll anchor is center', async () => {
    const leaderboardViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardViewPath, 'utf-8');

    // Check for center anchor
    expect(content).toContain('anchor: .center');
  });

  test('Scroll has delay for view rendering', async () => {
    const leaderboardViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardViewPath, 'utf-8');

    // Check for async delay
    expect(content).toContain('DispatchQueue.main.asyncAfter');
    expect(content).toContain('deadline');
  });

  test('Accessibility label includes current user indicator', async () => {
    const leaderboardViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Leaderboard', 'LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardViewPath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('this is you');
    expect(content).toContain('accessibilityLabel');
  });
});
