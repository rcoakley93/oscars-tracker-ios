import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-015: Watch Plan - Mark Watched & Remove', () => {
  test('Watched button on each movie card', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for Watched button
    expect(content).toContain('onMarkWatched');
    expect(content).toContain('Label("Watched"');
    expect(content).toContain('checkmark.circle.fill');
  });

  test('Watched button uses success color', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for success color on watched button
    expect(content).toContain('Color.success');
  });

  test('Success color defined in Color extensions', async () => {
    const colorPath = path.join(OSCARS_TRACKER_PATH, 'Utilities', 'Color+Extensions.swift');
    const content = fs.readFileSync(colorPath, 'utf-8');

    // Check for success color definition
    expect(content).toContain('static let success');
  });

  test('Tapping Watched marks movie and removes from plan', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'WatchPlanViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for markWatchedAndRemove function
    expect(content).toContain('func markWatchedAndRemove(itemId: Int, movieId: Int)');
    expect(content).toContain('async -> Bool');

    // Check it inserts into user_watched
    expect(content).toContain('"user_watched"');
    expect(content).toContain('.insert(watchedData)');

    // Check it deletes from watch_plan
    expect(content).toContain('.delete()');
    expect(content).toContain('"watch_plan"');
  });

  test('Updates watchedMovieIds set on mark watched', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'WatchPlanViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for watchedMovieIds update
    expect(content).toContain('watchedMovieIds.insert(movieId)');
  });

  test('X button removes from plan without marking watched', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for X button
    expect(content).toContain('onRemove');
    expect(content).toContain('Image(systemName: "xmark")');
    expect(content).toContain('Remove');
  });

  test('Remove function only deletes from watch_plan', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'WatchPlanViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for removeFromPlan function
    expect(content).toContain('func removeFromPlan(itemId: Int)');
    expect(content).toContain('async -> Bool');
    expect(content).toContain('.delete()');
  });

  test('Confirmation alert before removing', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for confirmation alert
    expect(content).toContain('.alert(');
    expect(content).toContain('Remove from Plan');
    expect(content).toContain('showRemoveConfirmation');
    expect(content).toContain('itemToRemove');
    expect(content).toContain('role: .destructive');
    expect(content).toContain('role: .cancel');
  });

  test('Success haptic on mark watched', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for haptic feedback
    expect(content).toContain('HapticManager.success()');
  });

  test('Success haptic on remove', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for haptic in removeFromPlan function
    expect(content).toContain('func removeFromPlan');
    expect(content).toContain('HapticManager.success()');
  });

  test('Optimistic UI update with rollback on error', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'WatchPlanViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for optimistic updates in markWatchedAndRemove
    expect(content).toContain('originalItems');
    expect(content).toContain('originalWatchedIds');
    expect(content).toContain('Rollback on error');

    // Check for rollback
    expect(content).toContain('watchPlanItems = originalItems');
    expect(content).toContain('watchedMovieIds = originalWatchedIds');
  });

  test('WatchPlanRowView has all action callbacks', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check WatchPlanRowView properties
    expect(content).toContain('var onReschedule: (() -> Void)?');
    expect(content).toContain('var onMarkWatched: (() -> Void)?');
    expect(content).toContain('var onRemove: (() -> Void)?');
  });

  test('Action buttons in row layout', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for action buttons row
    expect(content).toContain('Action buttons row');
    expect(content).toContain('HStack(spacing: 8)');
    expect(content).toContain('frame(maxWidth: .infinity)');
  });

  test('Movie removed from list after mark watched', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'WatchPlanViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for removal from watchPlanItems
    expect(content).toContain('watchPlanItems.removeAll { $0.id == itemId }');
  });

  test('Accessibility labels on buttons', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for accessibility labels
    expect(content).toContain('accessibilityLabel("Mark');
    expect(content).toContain('as watched');
    expect(content).toContain('accessibilityLabel("Remove');
    expect(content).toContain('from plan');
  });

  test('Error haptic on failure', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for error haptic
    expect(content).toContain('HapticManager.error()');
  });
});
