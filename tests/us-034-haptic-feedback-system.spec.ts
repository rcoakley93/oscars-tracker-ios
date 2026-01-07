import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

/**
 * US-034: Haptic Feedback System
 *
 * Acceptance Criteria:
 * - HapticManager utility class implemented
 * - Light impact for toggles and selections
 * - Medium impact for drag start
 * - Success notification for successful actions
 * - Error notification for failures
 * - Selection feedback for button taps
 */

const projectRoot = path.join(__dirname, '..');
const hapticManagerPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/Utilities/HapticManager.swift');

test.describe('US-034: Haptic Feedback System', () => {
  test('HapticManager.swift file exists', async () => {
    expect(fs.existsSync(hapticManagerPath)).toBe(true);
  });

  test('HapticManager has UIKit import', async () => {
    const content = fs.readFileSync(hapticManagerPath, 'utf-8');
    expect(content).toContain('import UIKit');
  });

  test('HapticManager is implemented as enum utility class', async () => {
    const content = fs.readFileSync(hapticManagerPath, 'utf-8');
    expect(content).toMatch(/enum\s+HapticManager/);
  });

  test('HapticManager has light impact function', async () => {
    const content = fs.readFileSync(hapticManagerPath, 'utf-8');
    expect(content).toMatch(/static\s+func\s+light\s*\(\s*\)/);
    expect(content).toContain('UIImpactFeedbackGenerator(style: .light)');
    expect(content).toContain('impactOccurred()');
  });

  test('HapticManager has medium impact function', async () => {
    const content = fs.readFileSync(hapticManagerPath, 'utf-8');
    expect(content).toMatch(/static\s+func\s+medium\s*\(\s*\)/);
    expect(content).toContain('UIImpactFeedbackGenerator(style: .medium)');
  });

  test('HapticManager has heavy impact function', async () => {
    const content = fs.readFileSync(hapticManagerPath, 'utf-8');
    expect(content).toMatch(/static\s+func\s+heavy\s*\(\s*\)/);
    expect(content).toContain('UIImpactFeedbackGenerator(style: .heavy)');
  });

  test('HapticManager has success notification function', async () => {
    const content = fs.readFileSync(hapticManagerPath, 'utf-8');
    expect(content).toMatch(/static\s+func\s+success\s*\(\s*\)/);
    expect(content).toContain('UINotificationFeedbackGenerator()');
    expect(content).toContain('notificationOccurred(.success)');
  });

  test('HapticManager has error notification function', async () => {
    const content = fs.readFileSync(hapticManagerPath, 'utf-8');
    expect(content).toMatch(/static\s+func\s+error\s*\(\s*\)/);
    expect(content).toContain('notificationOccurred(.error)');
  });

  test('HapticManager has warning notification function', async () => {
    const content = fs.readFileSync(hapticManagerPath, 'utf-8');
    expect(content).toMatch(/static\s+func\s+warning\s*\(\s*\)/);
    expect(content).toContain('notificationOccurred(.warning)');
  });

  test('HapticManager has selection feedback function', async () => {
    const content = fs.readFileSync(hapticManagerPath, 'utf-8');
    expect(content).toMatch(/static\s+func\s+selection\s*\(\s*\)/);
    expect(content).toContain('UISelectionFeedbackGenerator()');
    expect(content).toContain('selectionChanged()');
  });

  test('HapticManager functions have proper documentation', async () => {
    const content = fs.readFileSync(hapticManagerPath, 'utf-8');
    // Check for documentation comments
    expect(content).toContain('/// Light impact for toggles and selections');
    expect(content).toContain('/// Medium impact for drag start');
    expect(content).toContain('/// Success notification for successful actions');
    expect(content).toContain('/// Error notification for failures');
    expect(content).toContain('/// Selection feedback for button taps');
  });

  test('HapticManager is registered in Xcode project', async () => {
    const projectPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker.xcodeproj/project.pbxproj');
    const projectContent = fs.readFileSync(projectPath, 'utf-8');
    expect(projectContent).toContain('HapticManager.swift');
  });
});
