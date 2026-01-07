import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

/**
 * US-037: Empty States
 *
 * Acceptance Criteria:
 * - Empty state for Watch Plan (no movies planned)
 * - Empty state for Groups (no groups)
 * - Empty state for Leaderboard (no data)
 * - Each empty state has icon, title, subtitle
 * - Call to action button where appropriate
 */

const projectRoot = path.join(__dirname, '..');
const emptyStateViewPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/Components/EmptyStateView.swift');
const projectPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker.xcodeproj/project.pbxproj');

test.describe('US-037: Empty States', () => {
  test('EmptyStateView.swift file exists in Components folder', async () => {
    expect(fs.existsSync(emptyStateViewPath)).toBe(true);
  });

  test('EmptyStateView has SwiftUI import', async () => {
    const content = fs.readFileSync(emptyStateViewPath, 'utf-8');
    expect(content).toContain('import SwiftUI');
  });

  test('EmptyStateView component with icon, title, subtitle', async () => {
    const content = fs.readFileSync(emptyStateViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+EmptyStateView:\s*View/);
    expect(content).toContain('let icon: String');
    expect(content).toContain('let title: String');
    expect(content).toContain('let subtitle: String');
  });

  test('EmptyStateView has optional action button', async () => {
    const content = fs.readFileSync(emptyStateViewPath, 'utf-8');
    expect(content).toContain('let actionTitle: String?');
    expect(content).toContain('let action: (() -> Void)?');
    expect(content).toContain('.buttonStyle(.gold)');
  });

  test('EmptyStateView has accessibility support', async () => {
    const content = fs.readFileSync(emptyStateViewPath, 'utf-8');
    expect(content).toContain('.accessibilityElement');
    expect(content).toContain('.accessibilityLabel');
    expect(content).toContain('.accessibilityHint');
  });

  test('WatchPlanEmptyState for Watch Plan', async () => {
    const content = fs.readFileSync(emptyStateViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+WatchPlanEmptyState:\s*View/);
    expect(content).toContain('"calendar"');
    expect(content).toContain('No movies planned');
    expect(content).toContain('onAddMovie');
  });

  test('GroupsEmptyState for Groups', async () => {
    const content = fs.readFileSync(emptyStateViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+GroupsEmptyState:\s*View/);
    expect(content).toContain('"person.3.fill"');
    expect(content).toContain('No groups yet');
    expect(content).toContain('onCreateGroup');
  });

  test('LeaderboardEmptyState for Leaderboard', async () => {
    const content = fs.readFileSync(emptyStateViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+LeaderboardEmptyState:\s*View/);
    expect(content).toContain('"trophy.fill"');
    expect(content).toContain('No rankings yet');
  });

  test('BallotEmptyState for Ballot', async () => {
    const content = fs.readFileSync(emptyStateViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+BallotEmptyState:\s*View/);
    expect(content).toContain('"checkmark.seal.fill"');
    expect(content).toContain('No predictions yet');
  });

  test('DashboardEmptyState for Dashboard', async () => {
    const content = fs.readFileSync(emptyStateViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+DashboardEmptyState:\s*View/);
    expect(content).toContain('"film.fill"');
    expect(content).toContain('No movies found');
  });

  test('ProfileEmptyState for Profile', async () => {
    const content = fs.readFileSync(emptyStateViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+ProfileEmptyState:\s*View/);
    expect(content).toContain('"person.circle.fill"');
    expect(content).toContain('Start watching');
  });

  test('SearchEmptyState for search results', async () => {
    const content = fs.readFileSync(emptyStateViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+SearchEmptyState:\s*View/);
    expect(content).toContain('"magnifyingglass"');
    expect(content).toContain('No results');
    expect(content).toContain('let query: String');
  });

  test('CategoryEmptyState for categories', async () => {
    const content = fs.readFileSync(emptyStateViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+CategoryEmptyState:\s*View/);
    expect(content).toContain('"rectangle.stack.fill"');
    expect(content).toContain('No categories found');
  });

  test('EmptyStateView uses goldPrimary color for icon', async () => {
    const content = fs.readFileSync(emptyStateViewPath, 'utf-8');
    expect(content).toContain('.foregroundStyle(Color.goldPrimary)');
  });

  test('EmptyStateView uses correct text colors', async () => {
    const content = fs.readFileSync(emptyStateViewPath, 'utf-8');
    expect(content).toContain('Color.textPrimary');
    expect(content).toContain('Color.textMuted');
  });

  test('EmptyStateView has proper padding', async () => {
    const content = fs.readFileSync(emptyStateViewPath, 'utf-8');
    expect(content).toContain('.padding(32)');
    expect(content).toContain('.frame(maxWidth: .infinity)');
  });

  test('EmptyStateView subtitle is multiline centered', async () => {
    const content = fs.readFileSync(emptyStateViewPath, 'utf-8');
    expect(content).toContain('.multilineTextAlignment(.center)');
  });

  test('EmptyStateView has previews', async () => {
    const content = fs.readFileSync(emptyStateViewPath, 'utf-8');
    expect(content).toContain('#Preview');
  });

  test('EmptyStateView is registered in Xcode project', async () => {
    const projectContent = fs.readFileSync(projectPath, 'utf-8');
    expect(projectContent).toContain('EmptyStateView.swift');
  });

  // Verify views have empty state handling
  test('WatchPlanView has empty state', async () => {
    const viewPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/Views/WatchPlan/WatchPlanView.swift');
    const content = fs.readFileSync(viewPath, 'utf-8');
    expect(content).toContain('emptyStateView');
    expect(content).toContain('watchPlanItems.isEmpty');
  });

  test('GroupsView has empty state', async () => {
    const viewPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/Views/Groups/GroupsView.swift');
    const content = fs.readFileSync(viewPath, 'utf-8');
    expect(content).toContain('emptyStateView');
    expect(content).toContain('.isEmpty');
  });

  test('LeaderboardView has empty state', async () => {
    const viewPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/Views/Leaderboard/LeaderboardView.swift');
    const content = fs.readFileSync(viewPath, 'utf-8');
    expect(content).toContain('emptyStateView');
    expect(content).toContain('entries.isEmpty');
  });

  test('Dashboard has empty state', async () => {
    const viewPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/App/ContentView.swift');
    const content = fs.readFileSync(viewPath, 'utf-8');
    expect(content).toContain('movies.isEmpty');
    expect(content).toContain('No movies found');
  });
});
