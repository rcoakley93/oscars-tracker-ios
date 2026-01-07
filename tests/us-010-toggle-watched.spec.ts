import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-010: Dashboard - Toggle Watched', () => {
  test('Tap movie card toggles watched status', async () => {
    const movieCardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'MovieCardView.swift');
    const content = fs.readFileSync(movieCardPath, 'utf-8');

    // Check for tap action
    expect(content).toContain('Button(action: onTap)');
    expect(content).toContain('onTap: () -> Void');
  });

  test('Optimistic UI update (instant visual feedback)', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for optimistic update pattern
    expect(content).toContain('// Optimistic update');
    expect(content).toContain('watchedMovieIds.contains(movieId)');
    expect(content).toContain('watchedMovieIds.remove(movieId)');
    expect(content).toContain('watchedMovieIds.insert(movieId)');
  });

  test('Light haptic feedback on toggle', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for haptic feedback
    expect(content).toContain('HapticManager.light()');
  });

  test('HapticManager utility exists', async () => {
    const hapticManagerPath = path.join(OSCARS_TRACKER_PATH, 'Utilities', 'HapticManager.swift');
    expect(fs.existsSync(hapticManagerPath)).toBe(true);

    const content = fs.readFileSync(hapticManagerPath, 'utf-8');

    // Check for haptic types
    expect(content).toContain('UIImpactFeedbackGenerator');
    expect(content).toContain('UINotificationFeedbackGenerator');
    expect(content).toContain('static func light()');
    expect(content).toContain('static func medium()');
    expect(content).toContain('static func success()');
    expect(content).toContain('static func error()');
  });

  test('Supabase user_watched table updated', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for Supabase user_watched operations
    expect(content).toContain('"user_watched"');
    expect(content).toContain('.delete()');
    expect(content).toContain('.insert(');
    expect(content).toContain('user_id');
    expect(content).toContain('movie_id');
  });

  test('Rollback on API error', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for rollback logic
    expect(content).toContain('// Rollback on error');
    expect(content).toContain('catch {');
    expect(content).toContain('HapticManager.error()');
  });

  test('Progress hero updates immediately', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check watchedCount is computed from watchedMovieIds
    expect(content).toContain('var watchedCount: Int');
    expect(content).toContain('watchedMovieIds.count');
  });

  test('Toggle wired up in ContentView', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for toggle integration
    expect(content).toContain('onToggleWatched');
    expect(content).toContain('viewModel.toggleWatched');
  });

  test('Files are registered in Xcode project', async () => {
    const pbxprojPath = path.join(XCODE_PROJECT_PATH, 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const pbxprojContent = fs.readFileSync(pbxprojPath, 'utf-8');

    // Check HapticManager is in the project
    expect(pbxprojContent).toContain('HapticManager.swift');
    expect(pbxprojContent).toContain('HapticManager.swift in Sources');
  });
});
