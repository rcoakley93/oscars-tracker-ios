import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-019: Ballot - Category List', () => {
  test('BallotView exists with NavigationStack', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    expect(fs.existsSync(ballotPath)).toBe(true);

    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for SwiftUI import and struct
    expect(content).toContain('import SwiftUI');
    expect(content).toContain('struct BallotView');
    expect(content).toContain('NavigationStack');
  });

  test('BallotView shows all award categories', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for categories display
    expect(content).toContain('ForEach');
    expect(content).toContain('sortedCategories');
    expect(content).toContain('CategoryCard');
  });

  test('Categories sorted by points value (highest first)', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for sorting by points value
    expect(content).toContain('sortedCategories');
    expect(content).toContain('sorted');
    expect(content).toContain('pointsValue');
    expect(content).toContain('> ($1.pointsValue');
  });

  test('CategoryCard shows category name and points', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for CategoryCard struct
    expect(content).toContain('struct CategoryCard');
    expect(content).toContain('category.name');
    expect(content).toContain('pointsValue');
    expect(content).toContain('pts');
  });

  test('CategoryCard is expandable to show nominations', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for expandable functionality
    expect(content).toContain('@State private var isExpanded');
    expect(content).toContain('isExpanded.toggle()');
    expect(content).toContain('if isExpanded');
    expect(content).toContain('nominationsList');
  });

  test('CategoryCard shows chevron expand/collapse indicator', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for chevron icons
    expect(content).toContain('chevron.up');
    expect(content).toContain('chevron.down');
  });

  test('NominationRow shows movie title and detail text', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for NominationRow struct
    expect(content).toContain('struct NominationRow');
    expect(content).toContain('movie?.title');
    expect(content).toContain('detailText');
  });

  test('2-column grid on iPad', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for iPad grid layout
    expect(content).toContain('horizontalSizeClass');
    expect(content).toContain('regular');
    expect(content).toContain('LazyVGrid');
    expect(content).toContain('GridItem(.flexible())');
  });

  test('Pull to refresh reloads categories', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for refreshable
    expect(content).toContain('.refreshable');
    expect(content).toContain('await viewModel.loadData()');
  });

  test('BallotViewModel loads categories from Supabase', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for data loading
    expect(content).toContain('func loadData()');
    expect(content).toContain('"categories"');
    expect(content).toContain('"nominations"');
    expect(content).toContain('supabase');
  });

  test('BallotViewModel groups nominations by category', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for grouping logic
    expect(content).toContain('CategoryWithNominations');
    expect(content).toContain('categoryMap');
  });

  test('Loading state shown while data loads', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for loading state
    expect(content).toContain('isLoading');
    expect(content).toContain('loadingView');
    expect(content).toContain('ProgressView');
    expect(content).toContain('Loading categories');
  });

  test('Empty state when no categories', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for empty state
    expect(content).toContain('emptyStateView');
    expect(content).toContain('No categories found');
  });

  test('Files are registered in Xcode project', async () => {
    const pbxprojPath = path.join(XCODE_PROJECT_PATH, 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const pbxprojContent = fs.readFileSync(pbxprojPath, 'utf-8');

    // Check files are in the project
    expect(pbxprojContent).toContain('BallotView.swift');
    expect(pbxprojContent).toContain('BallotViewModel.swift');
    expect(pbxprojContent).toContain('BallotView.swift in Sources');
    expect(pbxprojContent).toContain('BallotViewModel.swift in Sources');
  });

  test('Accessibility support', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('accessibilityElement');
    expect(content).toContain('accessibilityLabel');
    expect(content).toContain('accessibilityHint');
  });

  test('Nomination count shown in category header', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for nomination count
    expect(content).toContain('nominations.count');
    expect(content).toContain('nominees');
  });

  test('Haptic feedback on category expand/collapse', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for haptic feedback
    expect(content).toContain('HapticManager.selection()');
  });

  test('ContentView uses BallotView for ballot tab', async () => {
    const contentPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentPath, 'utf-8');

    // Check BallotPlaceholderView uses BallotView
    expect(content).toContain('BallotPlaceholderView');
    expect(content).toContain('BallotView()');
  });

  test('Winner badge shown for winning nominations', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for winner badge
    expect(content).toContain('isWinner');
    expect(content).toContain('trophy.fill');
  });
});
