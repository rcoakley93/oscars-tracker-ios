import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-013: Watch Plan - Add Movie to Plan', () => {
  test('AddToPlanSheet exists in WatchPlan folder', async () => {
    const sheetPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    expect(fs.existsSync(sheetPath)).toBe(true);

    const content = fs.readFileSync(sheetPath, 'utf-8');

    // Check for SwiftUI import and struct
    expect(content).toContain('import SwiftUI');
    expect(content).toContain('struct AddToPlanSheet');
    expect(content).toContain('NavigationStack');
  });

  test('Floating action button opens AddToPlanSheet', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for FAB
    expect(content).toContain('floatingAddButton');
    expect(content).toContain('showAddSheet');
    expect(content).toContain('.sheet(isPresented:');
    expect(content).toContain('AddToPlanSheet');

    // Check for plus icon
    expect(content).toContain('Image(systemName: "plus")');
  });

  test('Sheet shows list of unwatched movies not in plan', async () => {
    const sheetPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(sheetPath, 'utf-8');

    // Check for available movies filtering
    expect(content).toContain('availableMovies');
    expect(content).toContain('watchedMovieIds');
    expect(content).toContain('plannedMovieIds');

    // Check for filtering logic
    expect(content).toContain('!viewModel.watchedMovieIds.contains');
    expect(content).toContain('!plannedMovieIds.contains');
  });

  test('Movie picker with search/filter capability', async () => {
    const sheetPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(sheetPath, 'utf-8');

    // Check for search text state
    expect(content).toContain('@State private var searchText');

    // Check for search field
    expect(content).toContain('TextField');
    expect(content).toContain('magnifyingglass');
    expect(content).toContain('Search movies');

    // Check for filtered movies
    expect(content).toContain('filteredMovies');
    expect(content).toContain('localizedCaseInsensitiveContains');
  });

  test('Date picker for selecting planned date', async () => {
    const sheetPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(sheetPath, 'utf-8');

    // Check for date state
    expect(content).toContain('@State private var selectedDate');

    // Check for date picker
    expect(content).toContain('DatePicker');
    expect(content).toContain('.graphical');
    expect(content).toContain('displayedComponents: .date');

    // Check that date starts from today (not past)
    expect(content).toContain('in: Date()...');
  });

  test('Add button inserts to watch_plan table', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'WatchPlanViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for addToPlan function
    expect(content).toContain('func addToPlan(movieId: Int, date: Date)');
    expect(content).toContain('async -> Bool');

    // Check for Supabase insert
    expect(content).toContain('.insert(');
    expect(content).toContain('"watch_plan"');
    expect(content).toContain('"user_id"');
    expect(content).toContain('"movie_id"');
    expect(content).toContain('"planned_date"');
  });

  test('New movie appears in correct date group', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'WatchPlanViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check that new item is added to local state
    expect(content).toContain('watchPlanItems.append');
  });

  test('Sheet dismisses on successful add', async () => {
    const sheetPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(sheetPath, 'utf-8');

    // Check for dismiss environment
    expect(content).toContain('@Environment(\\.dismiss)');

    // Check for dismiss call on success
    expect(content).toContain('if success');
    expect(content).toContain('dismiss()');
  });

  test('Movie selection with visual feedback', async () => {
    const sheetPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(sheetPath, 'utf-8');

    // Check for selected movie state
    expect(content).toContain('@State private var selectedMovie');

    // Check for selection indicator
    expect(content).toContain('checkmark.circle.fill');
    expect(content).toContain('selectedMovie?.id == movie.id');

    // Check for gold highlight
    expect(content).toContain('Color.goldPrimary');
  });

  test('Loading state during add operation', async () => {
    const sheetPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(sheetPath, 'utf-8');

    // Check for loading state
    expect(content).toContain('@State private var isAdding');
    expect(content).toContain('ProgressView');
    expect(content).toContain('.disabled(');
  });

  test('Add button disabled when no movie selected', async () => {
    const sheetPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(sheetPath, 'utf-8');

    // Check for conditional button state
    expect(content).toContain('selectedMovie != nil');
    expect(content).toContain('.disabled(selectedMovie == nil');
  });

  test('Haptic feedback on interactions', async () => {
    const sheetPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(sheetPath, 'utf-8');

    // Check for haptic feedback
    expect(content).toContain('HapticManager.selection()');
    expect(content).toContain('HapticManager.success()');
    expect(content).toContain('HapticManager.error()');
  });

  test('Movie row displays poster, title, runtime, year', async () => {
    const sheetPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(sheetPath, 'utf-8');

    // Check for movie row content
    expect(content).toContain('movie.title');
    expect(content).toContain('formattedRuntime');
    expect(content).toContain('releaseYear');
    expect(content).toContain('Image(systemName: "film")');
  });

  test('Empty state when no available movies', async () => {
    const sheetPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(sheetPath, 'utf-8');

    // Check for empty state
    expect(content).toContain('emptyStateView');
    expect(content).toContain('No movies available');
    expect(content).toContain('No matching movies');
  });

  test('Files are registered in Xcode project', async () => {
    const pbxprojPath = path.join(XCODE_PROJECT_PATH, 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const pbxprojContent = fs.readFileSync(pbxprojPath, 'utf-8');

    // Check files are in the project
    expect(pbxprojContent).toContain('AddToPlanSheet.swift');
    expect(pbxprojContent).toContain('AddToPlanSheet.swift in Sources');
  });

  test('Accessibility support', async () => {
    const sheetPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(sheetPath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('accessibilityLabel');
    expect(content).toContain('accessibilityHint');

    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const viewContent = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check FAB accessibility
    expect(viewContent).toContain('accessibilityLabel("Add movie to plan")');
  });

  test('Cancel button dismisses sheet', async () => {
    const sheetPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(sheetPath, 'utf-8');

    // Check for cancel button
    expect(content).toContain('ToolbarItem(placement: .cancellationAction)');
    expect(content).toContain('Button("Cancel")');
    expect(content).toContain('dismiss()');
  });
});
