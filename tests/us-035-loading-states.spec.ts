import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

/**
 * US-035: Loading States
 *
 * Acceptance Criteria:
 * - Skeleton views shown while data loads
 * - LoadingView component with gold spinner
 * - Each screen shows appropriate loading state
 * - No flash of empty content
 */

const projectRoot = path.join(__dirname, '..');
const loadingViewPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/Components/LoadingView.swift');
const projectPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker.xcodeproj/project.pbxproj');

test.describe('US-035: Loading States', () => {
  test('LoadingView.swift file exists in Components folder', async () => {
    expect(fs.existsSync(loadingViewPath)).toBe(true);
  });

  test('LoadingView has SwiftUI import', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toContain('import SwiftUI');
  });

  test('LoadingView component implemented with gold spinner', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+LoadingView:\s*View/);
    expect(content).toContain('ProgressView()');
    expect(content).toContain('.tint(Color.goldPrimary)');
  });

  test('LoadingView has customizable message', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toContain('let message: String');
    expect(content).toContain('init(_ message: String');
  });

  test('LoadingView has accessibility support', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toContain('.accessibilityElement');
    expect(content).toContain('.accessibilityLabel');
  });

  test('SkeletonView component implemented with pulse animation', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+SkeletonView:\s*View/);
    expect(content).toContain('@State private var isAnimating');
    expect(content).toContain('.animation');
    expect(content).toContain('repeatForever');
  });

  test('SkeletonView has configurable dimensions', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toContain('let width: CGFloat?');
    expect(content).toContain('let height: CGFloat');
    expect(content).toContain('let cornerRadius: CGFloat');
  });

  test('MovieCardSkeletonView exists for movie cards', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+MovieCardSkeletonView:\s*View/);
    // Should have poster and title placeholders
    expect(content).toContain('Poster placeholder');
    expect(content).toContain('Title placeholder');
  });

  test('ListRowSkeletonView exists for list items', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+ListRowSkeletonView:\s*View/);
    expect(content).toContain('Thumbnail placeholder');
  });

  test('ProgressHeroSkeletonView exists for progress hero', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+ProgressHeroSkeletonView:\s*View/);
    expect(content).toContain('Progress bar placeholder');
  });

  test('MovieGridSkeletonView exists for movie grid', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+MovieGridSkeletonView:\s*View/);
    expect(content).toContain('LazyVGrid');
    expect(content).toContain('MovieCardSkeletonView');
  });

  test('LeaderboardSkeletonView exists for leaderboard', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+LeaderboardSkeletonView:\s*View/);
  });

  test('BallotCategorySkeletonView exists for ballot categories', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+BallotCategorySkeletonView:\s*View/);
  });

  test('WatchPlanSkeletonView exists for watch plan', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+WatchPlanSkeletonView:\s*View/);
  });

  test('ProfileSkeletonView exists for profile', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+ProfileSkeletonView:\s*View/);
  });

  test('GroupsSkeletonView exists for groups list', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toMatch(/struct\s+GroupsSkeletonView:\s*View/);
  });

  test('SkeletonView uses borderColor for fill', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toContain('.fill(Color.borderColor)');
  });

  test('SkeletonView is hidden from accessibility tree', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toContain('.accessibilityHidden(true)');
  });

  test('MovieGridSkeletonView supports iPad column count', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toContain('horizontalSizeClass');
  });

  test('LoadingView is registered in Xcode project', async () => {
    const projectContent = fs.readFileSync(projectPath, 'utf-8');
    expect(projectContent).toContain('LoadingView.swift');
  });

  test('LoadingView has preview', async () => {
    const content = fs.readFileSync(loadingViewPath, 'utf-8');
    expect(content).toContain('#Preview');
  });

  // Verify screens use loading patterns
  test('Dashboard shows loading state', async () => {
    const contentViewPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/App/ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');
    expect(content).toContain('viewModel.isLoading');
    expect(content).toContain('ProgressView');
  });

  test('Leaderboard shows loading state', async () => {
    const leaderboardViewPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/Views/Leaderboard/LeaderboardView.swift');
    const content = fs.readFileSync(leaderboardViewPath, 'utf-8');
    expect(content).toContain('viewModel.isLoading');
    expect(content).toContain('loadingView');
  });

  test('Watch Plan shows loading state', async () => {
    const watchPlanViewPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/Views/WatchPlan/WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');
    expect(content).toContain('viewModel.isLoading');
  });

  test('Ballot shows loading state', async () => {
    const ballotViewPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/Views/Ballot/BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');
    expect(content).toContain('viewModel.isLoading');
  });

  test('Profile shows loading state', async () => {
    const profileViewPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/Views/Profile/ProfileView.swift');
    const content = fs.readFileSync(profileViewPath, 'utf-8');
    expect(content).toContain('viewModel.isLoading');
  });

  test('Groups shows loading state', async () => {
    const groupsViewPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/Views/Groups/GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');
    expect(content).toContain('viewModel.isLoading');
  });
});
