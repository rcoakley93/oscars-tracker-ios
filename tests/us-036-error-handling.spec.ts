import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

/**
 * US-036: Error Handling
 *
 * Acceptance Criteria:
 * - ErrorView component for failed loads
 * - Retry button to reload data
 * - Toast notifications for action errors
 * - Network error detection and messaging
 * - Graceful degradation on partial failures
 */

const projectRoot = path.join(__dirname, '..');
const errorViewPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/Components/ErrorView.swift');
const projectPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker.xcodeproj/project.pbxproj');

test.describe('US-036: Error Handling', () => {
  test('ErrorView.swift file exists in Components folder', async () => {
    expect(fs.existsSync(errorViewPath)).toBe(true);
  });

  test('ErrorView has SwiftUI import', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toContain('import SwiftUI');
  });

  test('ErrorView component for failed loads', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+ErrorView:\s*View/);
    expect(content).toContain('let title: String');
    expect(content).toContain('let message: String');
  });

  test('ErrorView has customizable icon', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toContain('let icon: String');
    expect(content).toContain('Image(systemName: icon)');
  });

  test('ErrorView has retry button', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toContain('let retryAction');
    expect(content).toContain('Button(action: retryAction)');
    expect(content).toContain('Try Again');
  });

  test('ErrorView has accessibility support', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toContain('.accessibilityElement');
    expect(content).toContain('.accessibilityLabel');
    expect(content).toContain('.accessibilityHint');
  });

  test('NetworkErrorView exists for network-specific errors', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+NetworkErrorView:\s*View/);
    expect(content).toContain('wifi.slash');
    expect(content).toContain('No Connection');
  });

  test('ToastView component for transient messages', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+ToastView:\s*View/);
    expect(content).toContain('let message: String');
    expect(content).toContain('let type: ToastType');
  });

  test('ToastType enum with error, success, warning, info', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toContain('enum ToastType');
    expect(content).toContain('case error');
    expect(content).toContain('case success');
    expect(content).toContain('case warning');
    expect(content).toContain('case info');
  });

  test('ToastType has icon property', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toContain('var icon: String');
    expect(content).toContain('xmark.circle.fill');
    expect(content).toContain('checkmark.circle.fill');
  });

  test('ToastType has color property', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toContain('var color: Color');
    expect(content).toContain('.destructive');
    expect(content).toContain('.success');
  });

  test('ToastView has dismiss button', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toContain('let onDismiss');
    expect(content).toContain('Image(systemName: "xmark")');
  });

  test('ToastModifier view modifier exists', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+ToastModifier:\s*ViewModifier/);
    expect(content).toContain('@Binding var toast: ToastData?');
  });

  test('ToastModifier supports top and bottom positions', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toContain('enum ToastPosition');
    expect(content).toContain('case top');
    expect(content).toContain('case bottom');
  });

  test('ToastData model exists', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+ToastData/);
    expect(content).toContain('let message: String');
    expect(content).toContain('let type: ToastView.ToastType');
    expect(content).toContain('let autoDismiss: Bool');
    expect(content).toContain('let duration: TimeInterval');
  });

  test('ToastData has convenience static methods', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toContain('static func error');
    expect(content).toContain('static func success');
    expect(content).toContain('static func warning');
    expect(content).toContain('static func info');
  });

  test('View extension for toast modifier', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toContain('extension View');
    expect(content).toContain('func toast');
    expect(content).toContain('modifier(ToastModifier');
  });

  test('Toast auto-dismiss functionality', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toContain('if toast.autoDismiss');
    expect(content).toContain('DispatchQueue.main.asyncAfter');
    expect(content).toContain('toast.duration');
  });

  test('ErrorBanner for inline form errors', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+ErrorBanner:\s*View/);
    expect(content).toContain('exclamationmark.circle.fill');
  });

  test('PartialErrorView for graceful degradation', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+PartialErrorView:\s*View/);
    expect(content).toContain('exclamationmark.triangle.fill');
  });

  test('ErrorView is registered in Xcode project', async () => {
    const projectContent = fs.readFileSync(projectPath, 'utf-8');
    expect(projectContent).toContain('ErrorView.swift');
  });

  test('ErrorView has preview', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toContain('#Preview');
  });

  // Verify ViewModels have error handling
  test('DashboardViewModel has errorMessage property', async () => {
    const viewModelPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/ViewModels/DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');
    expect(content).toContain('@Published var errorMessage: String?');
    expect(content).toContain('catch');
  });

  test('WatchPlanViewModel has error handling', async () => {
    const viewModelPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/ViewModels/WatchPlanViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');
    expect(content).toContain('@Published var errorMessage');
    expect(content).toContain('catch');
  });

  test('BallotViewModel has error handling', async () => {
    const viewModelPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/ViewModels/BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');
    expect(content).toContain('catch');
  });

  test('LeaderboardViewModel has error handling', async () => {
    const viewModelPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/ViewModels/LeaderboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');
    expect(content).toContain('catch');
  });

  test('ProfileViewModel has error handling', async () => {
    const viewModelPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/ViewModels/ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');
    expect(content).toContain('@Published var errorMessage');
    expect(content).toContain('catch');
  });

  test('GroupsViewModel has error handling', async () => {
    const viewModelPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/ViewModels/GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');
    expect(content).toContain('@Published var errorMessage');
    expect(content).toContain('catch');
  });

  test('Toast animation with spring response', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toContain('.spring');
    expect(content).toContain('.transition');
  });

  test('Toast has proper styling', async () => {
    const content = fs.readFileSync(errorViewPath, 'utf-8');
    expect(content).toContain('RoundedRectangle');
    expect(content).toContain('.shadow');
    expect(content).toContain('Color.cardBackground');
  });
});
