import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const OSCARS_TRACKER_PATH = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker');

test.describe('US-039: Accessibility', () => {
  test('AccessibilityManager.swift exists', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Utilities', 'AccessibilityManager.swift');
    expect(fs.existsSync(filePath)).toBeTruthy();
  });

  test('AccessibilityManager checks for Reduce Motion', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Utilities', 'AccessibilityManager.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    expect(content).toContain('reduceMotionEnabled');
    expect(content).toContain('UIAccessibility.isReduceMotionEnabled');
  });

  test('AccessibilityManager checks for VoiceOver', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Utilities', 'AccessibilityManager.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    expect(content).toContain('voiceOverRunning');
    expect(content).toContain('UIAccessibility.isVoiceOverRunning');
  });

  test('AccessibilityManager provides animation duration helper', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Utilities', 'AccessibilityManager.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    expect(content).toContain('animationDuration');
    expect(content).toContain('reduceMotionEnabled ? 0');
  });

  test('View extension for accessibility animation exists', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Utilities', 'AccessibilityManager.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    expect(content).toContain('accessibilityAnimation');
    expect(content).toContain('withReduceMotionAnimation');
  });

  test('Font+Extensions uses Dynamic Type text styles', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Utilities', 'Font+Extensions.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for text styles that support Dynamic Type
    expect(content).toContain('.largeTitle');
    expect(content).toContain('.title');
    expect(content).toContain('.title2');
    expect(content).toContain('.title3');
    expect(content).toContain('.headline');
    expect(content).toContain('.body');
    expect(content).toContain('.callout');
    expect(content).toContain('.footnote');
    expect(content).toContain('.caption');
    expect(content).toContain('.caption2');
  });

  test('Dynamic Type scaling extension exists', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Utilities', 'Font+Extensions.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    expect(content).toContain('scaledFont');
    expect(content).toContain('minimumScaleFactor');
    expect(content).toContain('dynamicLineLimit');
  });

  test('VoiceOver labels exist on interactive elements', async () => {
    // Check multiple files for accessibility labels
    const filesToCheck = [
      'Views/Dashboard/MovieCardView.swift',
      'Views/WatchPlan/WatchPlanView.swift',
      'Views/Ballot/BallotView.swift',
      'Views/Profile/ProfileView.swift',
    ];

    for (const file of filesToCheck) {
      const filePath = path.join(OSCARS_TRACKER_PATH, file);
      const content = fs.readFileSync(filePath, 'utf-8');
      expect(content).toContain('.accessibilityLabel');
    }
  });

  test('Accessibility hints exist on buttons', async () => {
    const filesToCheck = [
      'Views/WatchPlan/WatchPlanView.swift',
      'Views/WatchPlan/AutoSchedulerSheet.swift',
    ];

    for (const file of filesToCheck) {
      const filePath = path.join(OSCARS_TRACKER_PATH, file);
      const content = fs.readFileSync(filePath, 'utf-8');
      expect(content).toContain('.accessibilityHint');
    }
  });

  test('Accessibility traits are set properly', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Utilities', 'AccessibilityManager.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    expect(content).toContain('.accessibilityAddTraits');
    expect(content).toContain('.isButton');
    expect(content).toContain('.isHeader');
    expect(content).toContain('.isStaticText');
  });

  test('AccessibilityManager helper functions exist', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Utilities', 'AccessibilityManager.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    expect(content).toContain('accessibilityAsButton');
    expect(content).toContain('accessibilityAsHeader');
    expect(content).toContain('accessibilityAsStaticText');
  });

  test('Color extensions include accessible gold color', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Utilities', 'Color+Extensions.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for contrast-related definitions or accessible colors
    expect(content).toContain('goldPrimary');
  });

  test('Accessibility comments exist in AccessibilityManager', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Utilities', 'AccessibilityManager.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for WCAG reference or accessibility comments
    expect(content).toContain('WCAG');
    expect(content).toContain('contrast');
  });

  test('AccessibilityManager is registered in project.pbxproj', async () => {
    const pbxprojPath = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const content = fs.readFileSync(pbxprojPath, 'utf-8');

    expect(content).toContain('AccessibilityManager.swift');
    expect(content).toContain('AccessibilityManager.swift in Sources');
  });

  test('Bold Text preference check exists', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Utilities', 'AccessibilityManager.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    expect(content).toContain('boldTextEnabled');
    expect(content).toContain('UIAccessibility.isBoldTextEnabled');
  });

  test('Reduce Transparency preference check exists', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Utilities', 'AccessibilityManager.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    expect(content).toContain('reduceTransparencyEnabled');
    expect(content).toContain('UIAccessibility.isReduceTransparencyEnabled');
  });

  test('Elements use accessibilityElement for combining', async () => {
    const filesToCheck = [
      'Views/Dashboard/MovieCardView.swift',
      'Views/Dashboard/CategoryListView.swift',
    ];

    for (const file of filesToCheck) {
      const filePath = path.join(OSCARS_TRACKER_PATH, file);
      const content = fs.readFileSync(filePath, 'utf-8');
      expect(content).toContain('.accessibilityElement(children:');
    }
  });
});
