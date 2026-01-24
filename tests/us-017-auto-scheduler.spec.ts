import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const OSCARS_TRACKER_PATH = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker');

test.describe('US-017: Watch Plan - Auto Scheduler', () => {
  test('AutoSchedulerSheet.swift exists in WatchPlan folder', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    expect(fs.existsSync(filePath)).toBeTruthy();
  });

  test('AutoSchedulerSheet has proper structure', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for struct definition
    expect(content).toContain('struct AutoSchedulerSheet: View');

    // Check for required state properties
    expect(content).toContain('@ObservedObject var viewModel: WatchPlanViewModel');
    expect(content).toContain('selectedMovieIds');
    expect(content).toContain('suggestedSchedule');
    expect(content).toContain('showPreview');
  });

  test('Auto Scheduler toolbar button exists in WatchPlanView', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for toolbar with auto scheduler button
    expect(content).toContain('.toolbar');
    expect(content).toContain('wand.and.stars');
    expect(content).toContain('showAutoSchedulerSheet');
  });

  test('Auto Scheduler sheet is presented', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for sheet presentation
    expect(content).toContain('.sheet(isPresented: $showAutoSchedulerSheet)');
    expect(content).toContain('AutoSchedulerSheet(viewModel: viewModel)');
  });

  test('AutoSchedulerSheet shows list of unwatched movies', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for movie filtering
    expect(content).toContain('availableMovies');
    expect(content).toContain('watchedMovieIds');
    expect(content).toContain('plannedMovieIds');
  });

  test('User can select movies to schedule', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for selection functionality
    expect(content).toContain('selectedMovieIds');
    expect(content).toContain('movieSelectionRow');
    expect(content).toContain('Select All');
    expect(content).toContain('Deselect All');
  });

  test('Algorithm suggests dates to fill gaps', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for scheduling algorithm
    expect(content).toContain('generateSchedule');
    expect(content).toContain('existingDates');
    expect(content).toContain('calendar');

    // Check for Oscar deadline consideration
    expect(content).toContain('oscarDate');
  });

  test('Preview of suggested schedule is shown', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for preview section
    expect(content).toContain('previewSection');
    expect(content).toContain('schedulePreviewList');
    expect(content).toContain('schedulePreviewRow');

    // Check for summary header
    expect(content).toContain('summaryHeader');
    expect(content).toContain('Suggested Schedule');
  });

  test('Confirm button triggers bulk insert', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for confirm functionality
    expect(content).toContain('confirmSchedule');
    expect(content).toContain('Confirm Schedule');
    expect(content).toContain('bulkAddToPlan');
  });

  test('WatchPlanViewModel has bulkAddToPlan function', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'WatchPlanViewModel.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for bulk add function
    expect(content).toContain('func bulkAddToPlan');
    expect(content).toContain('movies: [(movieId: Int, date: Date)]');

    // Check for bulk insert pattern
    expect(content).toContain('insertData');
    expect(content).toContain('.insert(insertData)');
  });

  test('AutoSchedulerSheet handles overdue movies appropriately', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check that scheduling starts from today (not overdue)
    expect(content).toContain('currentDate = calendar.startOfDay(for: Date())');

    // Check that it avoids existing planned dates
    expect(content).toContain('existingDates.contains(currentDate)');
  });

  test('AutoSchedulerSheet has proper accessibility', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for accessibility labels
    expect(content).toContain('.accessibilityLabel');
    expect(content).toContain('.accessibilityHint');
  });

  test('AutoSchedulerSheet uses haptic feedback', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for haptic feedback
    expect(content).toContain('HapticManager.selection');
    expect(content).toContain('HapticManager.success');
    expect(content).toContain('HapticManager.error');
    expect(content).toContain('HapticManager.light');
  });

  test('AutoSchedulerSheet is registered in project.pbxproj', async () => {
    const pbxprojPath = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const content = fs.readFileSync(pbxprojPath, 'utf-8');

    // Check for file references
    expect(content).toContain('AutoSchedulerSheet.swift');
    expect(content).toContain('AutoSchedulerSheet.swift in Sources');
  });

  test('AutoSchedulerSheet shows loading state during scheduling', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for loading state
    expect(content).toContain('isScheduling');
    expect(content).toContain('ProgressView');
    expect(content).toContain('.disabled(isScheduling)');
  });

  test('AutoSchedulerSheet has back navigation from preview', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for back button functionality
    expect(content).toContain('showPreview ? "Back" : "Cancel"');
    expect(content).toContain('showPreview = false');
  });
});
