import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const OSCARS_TRACKER_ROOT = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker');

test.describe('US-006: Prioritize Unwatched Movies in Dashboard Sorting', () => {
  test('sortedMovies separates unwatched and watched movies', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check that movies are separated into unwatched and watched groups
    expect(content).toContain('let unwatched = movies.filter { !watchedMovieIds.contains($0.id) }');
    expect(content).toContain('let watched = movies.filter { watchedMovieIds.contains($0.id) }');
  });

  test('sortedMovies returns unwatched movies before watched', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check that unwatched are concatenated before watched
    expect(content).toContain('return sortedUnwatched + sortedWatched');
  });

  test('applySortOption helper function exists for secondary sorting', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check that helper function exists
    expect(content).toContain('private func applySortOption(to movieList: [Movie]) -> [Movie]');
  });

  test('secondary sorting is applied to both unwatched and watched groups', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check that sort option is applied to both groups
    expect(content).toContain('let sortedUnwatched = applySortOption(to: unwatched)');
    expect(content).toContain('let sortedWatched = applySortOption(to: watched)');
  });

  test('applySortOption handles all four sort options', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Extract the applySortOption function content
    const funcMatch = content.match(/private func applySortOption[\s\S]*?switch sortOption[\s\S]*?case \.runtimeDesc:[\s\S]*?}/);
    expect(funcMatch).toBeTruthy();

    if (funcMatch) {
      const funcContent = funcMatch[0];
      // Check all four cases are handled
      expect(funcContent).toContain('case .titleAZ');
      expect(funcContent).toContain('case .titleZA');
      expect(funcContent).toContain('case .runtimeAsc');
      expect(funcContent).toContain('case .runtimeDesc');
    }
  });

  test('default sort option is Title (A-Z)', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check default value
    expect(content).toContain('@Published var sortOption: DashboardSortOption = .titleAZ');
  });

  test('sortedMovies comment explains unwatched-first behavior', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check descriptive comment
    expect(content).toContain('unwatched first');
  });

  test('toggling watched uses optimistic update for immediate UI response', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check optimistic update pattern (modify local state before server call)
    expect(content).toContain('watchedMovieIds.remove(movieId)');
    expect(content).toContain('watchedMovieIds.insert(movieId)');
  });

  test('sortedMovies uses watchedMovieIds to determine movie status', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check that watchedMovieIds is used for filtering
    expect(content).toContain('watchedMovieIds.contains($0.id)');
  });
});
