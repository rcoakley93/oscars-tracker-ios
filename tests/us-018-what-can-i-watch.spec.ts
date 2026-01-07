import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const OSCARS_TRACKER_PATH = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker');

test.describe('US-018: Watch Plan - What Can I Watch', () => {
  test('WhatCanIWatchSheet.swift exists in WatchPlan folder', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    expect(fs.existsSync(filePath)).toBeTruthy();
  });

  test('WhatCanIWatchSheet has proper structure', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for struct definition
    expect(content).toContain('struct WhatCanIWatchSheet: View');

    // Check for required properties
    expect(content).toContain('@ObservedObject var viewModel: WatchPlanViewModel');
    expect(content).toContain('selectedFilter');
  });

  test('What Can I Watch button exists in WatchPlanView toolbar', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for toolbar button
    expect(content).toContain('showWhatCanIWatchSheet');
    expect(content).toContain('questionmark.circle');
  });

  test('What Can I Watch sheet is presented', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for sheet presentation
    expect(content).toContain('.sheet(isPresented: $showWhatCanIWatchSheet)');
    expect(content).toContain('WhatCanIWatchSheet(viewModel: viewModel)');
  });

  test('WhatCanIWatchSheet shows unwatched movies', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for movie filtering
    expect(content).toContain('availableMovies');
    expect(content).toContain('watchedMovieIds');
    expect(content).toContain('plannedMovieIds');
  });

  test('RuntimeFilter enum exists with all options', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for RuntimeFilter enum
    expect(content).toContain('enum RuntimeFilter');
    expect(content).toContain('case all');
    expect(content).toContain('case short');
    expect(content).toContain('case medium');
    expect(content).toContain('case long');
  });

  test('Filter by runtime (short, medium, long)', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for runtime filtering logic
    expect(content).toContain('func matches(_ movie: Movie) -> Bool');
    expect(content).toContain('runtime < 90');
    expect(content).toContain('runtime >= 90 && runtime <= 120');
    expect(content).toContain('runtime > 120');
  });

  test('Filter chips UI with descriptions', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for filter descriptions
    expect(content).toContain('Under 90 min');
    expect(content).toContain('90-120 min');
    expect(content).toContain('Over 2 hours');

    // Check for filter UI
    expect(content).toContain('filterChip');
    expect(content).toContain('filterSection');
  });

  test('Quick add to plan from filtered list', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for quick add functionality
    expect(content).toContain('quickAddToPlan');
    expect(content).toContain('plus.circle.fill');
    expect(content).toContain('viewModel.addToPlan');
  });

  test('WhatCanIWatchSheet has proper accessibility', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for accessibility labels
    expect(content).toContain('.accessibilityLabel');
    expect(content).toContain('.accessibilityHint');
    expect(content).toContain('.accessibilityAddTraits');
  });

  test('WhatCanIWatchSheet uses haptic feedback', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for haptic feedback
    expect(content).toContain('HapticManager.selection');
    expect(content).toContain('HapticManager.success');
    expect(content).toContain('HapticManager.error');
  });

  test('WhatCanIWatchSheet is registered in project.pbxproj', async () => {
    const pbxprojPath = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const content = fs.readFileSync(pbxprojPath, 'utf-8');

    // Check for file references
    expect(content).toContain('WhatCanIWatchSheet.swift');
    expect(content).toContain('WhatCanIWatchSheet.swift in Sources');
  });

  test('Movie list shows runtime with color coding', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for runtime color coding
    expect(content).toContain('runtimeColor');
    expect(content).toContain('Color.success');
    expect(content).toContain('Color.goldPrimary');
    expect(content).toContain('Color.destructive');
  });

  test('Summary header shows movie count and total runtime', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for summary header
    expect(content).toContain('summaryHeader');
    expect(content).toContain('filteredMovies.count');
    expect(content).toContain('totalRuntime');
  });

  test('Empty state shows appropriate message per filter', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for empty state messages
    expect(content).toContain('emptyStateView');
    expect(content).toContain('emptyStateMessage');
    expect(content).toContain('No short movies');
    expect(content).toContain('No medium-length movies');
    expect(content).toContain('No long movies');
  });

  test('Loading state during quick add', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for loading state
    expect(content).toContain('isAddingMovie');
    expect(content).toContain('ProgressView');
  });

  test('Filter shows count for each option', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for count display in filter
    expect(content).toContain('countForFilter');
    expect(content).toContain('count > 0');
  });

  test('Done button dismisses sheet', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for done button
    expect(content).toContain('Button("Done")');
    expect(content).toContain('dismiss()');
  });
});
