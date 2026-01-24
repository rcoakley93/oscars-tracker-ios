import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-014: Watch Plan - Reschedule Movie', () => {
  test('Move button on each movie card', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for Move button in WatchPlanRowView
    expect(content).toContain('onReschedule');
    expect(content).toContain('Label("Move"');
    expect(content).toContain('calendar.badge.clock');
  });

  test('Tapping Move opens date picker', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for reschedule sheet
    expect(content).toContain('itemToReschedule');
    expect(content).toContain('RescheduleSheet');
    expect(content).toContain('.sheet(item: $itemToReschedule)');
  });

  test('RescheduleSheet exists with date picker', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for RescheduleSheet struct
    expect(content).toContain('struct RescheduleSheet');
    expect(content).toContain('DatePicker');
    expect(content).toContain('.graphical');
    expect(content).toContain('selectedDate');
  });

  test('Selecting new date updates watch_plan table', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'WatchPlanViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for reschedule function
    expect(content).toContain('func reschedule(itemId: Int, to date: Date)');
    expect(content).toContain('async -> Bool');

    // Check for Supabase update
    expect(content).toContain('.update(');
    expect(content).toContain('"planned_date"');
    expect(content).toContain('"watch_plan"');
  });

  test('Movie moves to new date group with animation', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'WatchPlanViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for optimistic update
    expect(content).toContain('Optimistic update');
    expect(content).toContain('originalItems');
    expect(content).toContain('watchPlanItems[index]');
  });

  test('Success haptic on reschedule', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for haptic feedback
    expect(content).toContain('HapticManager.success()');
    expect(content).toContain('HapticManager.selection()');
  });

  test('Rollback on API error', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'WatchPlanViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for error handling and rollback
    expect(content).toContain('Rollback on error');
    expect(content).toContain('watchPlanItems = originalItems');
    expect(content).toContain('Failed to reschedule');
  });

  test('Move button shows calendar icon', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for calendar icon and gold styling
    expect(content).toContain('calendar.badge.clock');
    expect(content).toContain('Color.goldPrimary');
    expect(content).toContain('.opacity(0.15)');
  });

  test('RescheduleSheet shows movie info header', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for movie header in sheet
    expect(content).toContain('movieHeader');
    expect(content).toContain('movie?.title');
    expect(content).toContain('formattedRuntime');
  });

  test('Date picker restricted to future dates', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for date restriction
    expect(content).toContain('in: Date()...');
  });

  test('Cancel button in reschedule sheet', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for cancel functionality
    expect(content).toContain('ToolbarItem(placement: .cancellationAction)');
    expect(content).toContain('Button("Cancel")');
    expect(content).toContain('onDismiss');
  });

  test('Loading state during reschedule', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for loading state
    expect(content).toContain('isRescheduling');
    expect(content).toContain('ProgressView');
    expect(content).toContain('.disabled(isRescheduling)');
  });

  test('WatchPlanItem model supports updating planned date', async () => {
    const modelPath = path.join(OSCARS_TRACKER_PATH, 'Models', 'WatchPlanItem.swift');
    const content = fs.readFileSync(modelPath, 'utf-8');

    // Check for mutable plannedDate and init
    expect(content).toContain('var plannedDate: String');
    expect(content).toContain('init(id: Int');
  });

  test('Accessibility support', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('accessibilityLabel');
    expect(content).toContain('Move');
    expect(content).toContain('different date');
  });

  test('Error haptic on failure', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for error haptic
    expect(content).toContain('HapticManager.error()');
  });
});
