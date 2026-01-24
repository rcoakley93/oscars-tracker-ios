import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-012: Watch Plan - Date Grouped List', () => {
  test('WatchPlanView exists with NavigationStack', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    expect(fs.existsSync(watchPlanPath)).toBe(true);

    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for SwiftUI import and struct
    expect(content).toContain('import SwiftUI');
    expect(content).toContain('struct WatchPlanView');
    expect(content).toContain('NavigationStack');
  });

  test('Movies grouped by planned date', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'WatchPlanViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for groupedItems property
    expect(content).toContain('groupedItems');
    expect(content).toContain('date: Date');
    expect(content).toContain('label: String');
    expect(content).toContain('items: [WatchPlanItem]');
  });

  test('Sticky date headers', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for pinned section headers
    expect(content).toContain('pinnedViews');
    expect(content).toContain('.sectionHeaders');
    expect(content).toContain('dateHeader');
  });

  test('Today and Tomorrow labeled instead of date', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'WatchPlanViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for TODAY and TOMORROW labels
    expect(content).toContain('"TODAY"');
    expect(content).toContain('"TOMORROW"');
  });

  test('Overdue section in red at top', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'WatchPlanViewModel.swift');
    const vmContent = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for overdue handling in view model
    expect(vmContent).toContain('"OVERDUE"');
    expect(vmContent).toContain('overdueItems');

    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const viewContent = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for red styling on overdue
    expect(viewContent).toContain('isOverdue');
    expect(viewContent).toContain('Color.destructive');
  });

  test('Movie row shows poster, title, runtime', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for WatchPlanRowView
    expect(content).toContain('struct WatchPlanRowView');
    expect(content).toContain('movie?.title');
    expect(content).toContain('formattedRuntime');
    expect(content).toContain('posterView');
  });

  test('Missed badge on overdue movies', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for missed badge
    expect(content).toContain('missedBadge');
    expect(content).toContain('isMissed');
    expect(content).toContain('"MISSED"');
  });

  test('Pull to refresh updates data', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for refreshable
    expect(content).toContain('.refreshable');
    expect(content).toContain('loadData');
  });

  test('WatchPlanViewModel loads data from Supabase', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'WatchPlanViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for proper structure
    expect(content).toContain('import Foundation');
    expect(content).toContain('import Supabase');
    expect(content).toContain('@MainActor');
    expect(content).toContain('ObservableObject');

    // Check for published properties
    expect(content).toContain('@Published var watchPlanItems');
    expect(content).toContain('@Published var isLoading');

    // Check for Supabase query
    expect(content).toContain('"watch_plan"');
    expect(content).toContain('loadData');
  });

  test('Stats card shows planned/unplanned/watched counts', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for stats card
    expect(content).toContain('statsCard');
    expect(content).toContain('plannedCount');
    expect(content).toContain('unplannedCount');
    expect(content).toContain('watchedCount');
    expect(content).toContain('"planned"');
    expect(content).toContain('"unplanned"');
    expect(content).toContain('"watched"');
  });

  test('Empty state when no items', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for empty state
    expect(content).toContain('emptyStateView');
    expect(content).toContain('No movies planned');
  });

  test('Files are registered in Xcode project', async () => {
    const pbxprojPath = path.join(XCODE_PROJECT_PATH, 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const pbxprojContent = fs.readFileSync(pbxprojPath, 'utf-8');

    // Check files are in the project
    expect(pbxprojContent).toContain('WatchPlanView.swift');
    expect(pbxprojContent).toContain('WatchPlanViewModel.swift');
    expect(pbxprojContent).toContain('WatchPlanView.swift in Sources');
    expect(pbxprojContent).toContain('WatchPlanViewModel.swift in Sources');

    // Check for WatchPlan group
    expect(pbxprojContent).toContain('/* WatchPlan */');
  });

  test('Accessibility support', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('accessibilityElement');
    expect(content).toContain('accessibilityLabel');
  });
});
