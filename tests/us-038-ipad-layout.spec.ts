import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const OSCARS_TRACKER_PATH = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker');

test.describe('US-038: iPad Layout Optimization', () => {
  test('ContentView has sidebar navigation for iPad', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for iPad-specific navigation
    expect(content).toContain('horizontalSizeClass');
    expect(content).toContain('.regular');
    expect(content).toContain('iPadNavigationView');
    expect(content).toContain('NavigationSplitView');
  });

  test('Sidebar uses NavigationSplitView with proper sections', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for sidebar list with sections
    expect(content).toContain('.listStyle(.sidebar)');
    expect(content).toContain('Section("More")');
    expect(content).toContain('NavigationLink');
  });

  test('MovieGridView uses 5 columns on iPad', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'MovieCardView.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for adaptive columns
    expect(content).toContain('horizontalSizeClass');
    expect(content).toContain('.regular ? 5 : 2');
    expect(content).toContain('GridItem(.flexible()');
  });

  test('CategoryListView uses 2-column grid on iPad', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'CategoryListView.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for iPad grid layout
    expect(content).toContain('horizontalSizeClass');
    expect(content).toContain('useGridLayout');
    expect(content).toContain('iPadGridLayout');
    expect(content).toContain('LazyVGrid');
    expect(content).toContain('GridItem(.flexible())');
  });

  test('BallotView uses 2-column grid on iPad', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for iPad grid
    expect(content).toContain('horizontalSizeClass');
    expect(content).toContain('.regular');
    expect(content).toContain('GridItem(.flexible()), GridItem(.flexible())');
  });

  test('WatchPlanView detects iPad with isIPad property', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for iPad detection
    expect(content).toContain('horizontalSizeClass');
    expect(content).toContain('isIPad');
    expect(content).toContain('.regular');
  });

  test('Sheets adapt presentation on iPad', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for iPad-specific sheet presentation
    expect(content).toContain('.presentationDragIndicator');
    expect(content).toContain('isIPad ? .hidden : .visible');
    expect(content).toContain('.if(isIPad)');
    expect(content).toContain('frame(minWidth:');
  });

  test('View extension for conditional modifiers exists', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Utilities', 'Color+Extensions.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for if extension
    expect(content).toContain('extension View');
    expect(content).toContain('func `if`');
    expect(content).toContain('@ViewBuilder');
    expect(content).toContain('transform: (Self) -> Content');
  });

  test('ContentView switches between tab and sidebar based on size class', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for conditional navigation
    expect(content).toContain('if horizontalSizeClass == .regular');
    expect(content).toContain('iPadNavigationView');
    expect(content).toContain('iPhoneTabView');
  });

  test('iPad navigation shows detail view', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for detail view
    expect(content).toContain('} detail: {');
    expect(content).toContain('switch selectedTab');
  });

  test('CategoryListView has iPhone list layout', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'CategoryListView.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for iPhone layout
    expect(content).toContain('iPhoneListLayout');
    expect(content).toContain('LazyVStack');
    expect(content).toContain('pinnedViews: [.sectionHeaders]');
  });

  test('iPad previews exist in ContentView', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for iPad preview
    expect(content).toContain('#Preview("iPad")');
    expect(content).toContain('iPad Pro');
  });

  test('Tab enum supports iPad-only tabs', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for additional tabs available on iPad sidebar
    expect(content).toContain('case groups');
    expect(content).toContain('case profile');
    expect(content).toContain('.groups');
    expect(content).toContain('.profile');
  });

  test('Sheets use presentationDetents', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for detents
    expect(content).toContain('.presentationDetents');
    expect(content).toContain('[.large]');
    expect(content).toContain('[.medium]');
  });
});
