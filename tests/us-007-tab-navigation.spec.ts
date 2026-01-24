import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-007: Tab Navigation Structure', () => {
  test('TabView with 5 tabs exists', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for TabView
    expect(content).toContain('TabView');

    // Check for 5 tabs
    expect(content).toContain('Dashboard');
    expect(content).toContain('Watch Plan');
    expect(content).toContain('Ballot');
    expect(content).toContain('Leaderboard');
    expect(content).toContain('More');

    // Check for tabItem modifier
    expect(content).toContain('.tabItem');
    expect(content).toContain('.tag');
  });

  test('SF Symbol icons for each tab', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for SF Symbols in Labels
    expect(content).toContain('systemImage:');

    // Check for specific icons
    expect(content).toContain('film');
    expect(content).toContain('calendar');
    expect(content).toContain('checkmark.seal');
    expect(content).toContain('trophy');
    expect(content).toContain('ellipsis');
  });

  test('Gold tint for selected tab', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for gold tint
    expect(content).toContain('.tint');
    expect(content).toContain('.goldPrimary');
  });

  test('More tab shows menu with Groups and Profile options', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for MoreMenuView
    expect(content).toContain('MoreMenuView');
    expect(content).toContain('struct MoreMenuView');

    // Check for Groups and Profile in More menu
    expect(content).toContain('Groups');
    expect(content).toContain('Profile');
    expect(content).toContain('person.3');
    expect(content).toContain('person.circle');

    // Check for NavigationLink to Groups and Profile
    expect(content).toContain('NavigationLink');
    expect(content).toContain('GroupsPlaceholderView');
    expect(content).toContain('ProfilePlaceholderView');
  });

  test('iPad uses sidebar navigation instead of tab bar', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for horizontal size class environment
    expect(content).toContain('horizontalSizeClass');
    expect(content).toContain('@Environment');

    // Check for NavigationSplitView for iPad
    expect(content).toContain('NavigationSplitView');

    // Check for conditional rendering based on size class
    expect(content).toContain('.regular');

    // Check for sidebar list style
    expect(content).toContain('.sidebar');
    expect(content).toContain('.listStyle');
  });

  test('Navigation state persists across tab switches', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for @State selectedTab variable
    expect(content).toContain('@State');
    expect(content).toContain('selectedTab');

    // Check for Tab enum
    expect(content).toContain('enum Tab');
    expect(content).toContain('Hashable');

    // Check for binding with TabView selection
    expect(content).toContain('selection: $selectedTab');

    // Check Tab enum cases
    expect(content).toContain('case dashboard');
    expect(content).toContain('case watchPlan');
    expect(content).toContain('case ballot');
    expect(content).toContain('case leaderboard');
    expect(content).toContain('case more');
  });

  test('Placeholder views for each tab exist', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for placeholder views
    expect(content).toContain('DashboardPlaceholderView');
    expect(content).toContain('WatchPlanPlaceholderView');
    expect(content).toContain('BallotPlaceholderView');
    expect(content).toContain('LeaderboardPlaceholderView');
    expect(content).toContain('GroupsPlaceholderView');
    expect(content).toContain('ProfilePlaceholderView');

    // Check placeholder views have NavigationStack
    expect(content).toContain('NavigationStack');
    expect(content).toContain('.navigationTitle');
  });

  test('iPad sidebar has sections for main tabs and more', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for Section in sidebar
    expect(content).toContain('Section');
    expect(content).toContain('Section("More")');

    // Check iPad sidebar has Groups and Profile directly
    expect(content).toContain('Tab.groups');
    expect(content).toContain('Tab.profile');
  });

  test('Navigation split view for iPad has detail view', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for detail view with switch statement
    expect(content).toContain('detail:');
    expect(content).toContain('switch selectedTab');

    // Check detail handles all tab cases
    expect(content).toContain('case .dashboard');
    expect(content).toContain('case .watchPlan');
    expect(content).toContain('case .ballot');
    expect(content).toContain('case .leaderboard');
    expect(content).toContain('case .groups');
    expect(content).toContain('case .profile');
  });
});
