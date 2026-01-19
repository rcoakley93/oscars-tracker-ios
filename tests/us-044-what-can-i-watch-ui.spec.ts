import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const OSCARS_TRACKER_PATH = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker');

test.describe('US-044: Update "What Can I Watch" UI to Match Web', () => {
  test('WhatCanIWatchSheet.swift exists in WatchPlan folder', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    expect(fs.existsSync(filePath)).toBeTruthy();
  });

  test('TimeOption enum has correct four options', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for TimeOption enum with four cases
    expect(content).toContain('enum TimeOption');
    expect(content).toContain('case short');
    expect(content).toContain('case medium');
    expect(content).toContain('case standard');
    expect(content).toContain('case unlimited');
  });

  test('Short filter is under 40 minutes', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for short filter < 40 min
    expect(content).toContain('case .short: return runtime < 40');
    expect(content).toContain('"< 40m"');
  });

  test('Medium filter is 40-90 minutes', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for medium filter 40-90 min
    expect(content).toContain('runtime >= 40 && runtime < 90');
    expect(content).toContain('"< 90m"');
  });

  test('Standard filter is 91-120 minutes', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for standard filter 91-120 min
    expect(content).toContain('runtime >= 91 && runtime <= 120');
    expect(content).toContain('"< 2h"');
  });

  test('Unlimited filter shows 3 longest movies', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for unlimited showing 3 longest
    expect(content).toContain('case .unlimited');
    expect(content).toContain('.prefix(3)');
    expect(content).toContain('3 longest');
  });

  test('Modal has "How much time do you have?" header', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    expect(content).toContain('"How much time do you have?"');
  });

  test('UI uses 2x2 grid layout for time options', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for LazyVGrid with 2 columns
    expect(content).toContain('LazyVGrid');
    expect(content).toContain('GridItem(.flexible())');
    expect(content).toContain('[GridItem(.flexible()), GridItem(.flexible())]');
  });

  test('On selection, shows random movie recommendation', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for random selection
    expect(content).toContain('randomElement');
    expect(content).toContain('recommendedMovies');
    expect(content).toContain('generateRecommendations');
  });

  test('Has recommendation view with movie card', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for recommendation view
    expect(content).toContain('recommendationView');
    expect(content).toContain('recommendedMovieCard');
    expect(content).toContain('recommendationHeader');
  });

  test('Has Try Another button to shuffle recommendations', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for try another functionality
    expect(content).toContain('tryAnotherButton');
    expect(content).toContain('"Try Another"');
    expect(content).toContain('shuffle');
  });

  test('Quick add to plan functionality exists', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for quick add functionality
    expect(content).toContain('quickAddToPlan');
    expect(content).toContain('addToPlan');
    expect(content).toContain('"Add to Plan"');
  });

  test('Has proper accessibility labels', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('.accessibilityLabel');
    expect(content).toContain('.accessibilityHint');
  });

  test('Uses haptic feedback', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for haptic feedback
    expect(content).toContain('HapticManager.selection');
    expect(content).toContain('HapticManager.success');
    expect(content).toContain('HapticManager.error');
  });

  test('Has back navigation from recommendation view', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for back navigation
    expect(content).toContain('selectedOption == nil ? "Done" : "Back"');
    expect(content).toContain('selectedOption = nil');
  });

  test('Has empty state for each filter', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for empty state messages
    expect(content).toContain('emptyStateMessage');
    expect(content).toContain('emptyRecommendationState');
    expect(content).toContain('under 40 minutes');
    expect(content).toContain('40-90 minutes');
    expect(content).toContain('91-120 minutes');
  });

  test('Shows stats section with unwatched and planned counts', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for stats section
    expect(content).toContain('statsSection');
    expect(content).toContain('Unwatched');
    expect(content).toContain('Planned');
  });

  test('Time option buttons show movie count', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for count display
    expect(content).toContain('countForOption');
    expect(content).toContain('movie');
    expect(content).toContain('None available');
  });

  test('Disabled state for options with no movies', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WhatCanIWatchSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for disabled state
    expect(content).toContain('isDisabled');
    expect(content).toContain('.disabled(isDisabled)');
    expect(content).toContain('.opacity(isDisabled ? 0.5 : 1)');
  });

  test('WhatCanIWatchSheet is registered in project.pbxproj', async () => {
    const pbxprojPath = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const content = fs.readFileSync(pbxprojPath, 'utf-8');

    // Check for file references
    expect(content).toContain('WhatCanIWatchSheet.swift');
    expect(content).toContain('WhatCanIWatchSheet.swift in Sources');
  });
});
