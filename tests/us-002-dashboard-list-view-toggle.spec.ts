import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const OSCARS_TRACKER_ROOT = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker');

test.describe('US-002: Implement Dashboard List View Toggle', () => {
  test('MasterListDisplayMode enum exists with grid and list cases', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check enum exists
    expect(content).toContain('enum MasterListDisplayMode');
    expect(content).toContain('case grid');
    expect(content).toContain('case list');
  });

  test('DashboardViewModel has masterListDisplayMode state variable', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check state variable exists
    expect(content).toContain('@Published var masterListDisplayMode');
    expect(content).toContain('MasterListDisplayMode');
  });

  test('ContentView has displayModePicker for Grid/List toggle', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_ROOT, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check display mode picker exists
    expect(content).toContain('displayModePicker');
    expect(content).toContain('MasterListDisplayMode.allCases');
  });

  test('ContentView shows Grid/List toggle only in Master List mode', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_ROOT, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check conditional display
    expect(content).toContain('viewModel.viewMode == .masterList');
    expect(content).toContain('displayModePicker');
  });

  test('MovieListView exists for list display mode', async () => {
    const movieCardPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Dashboard', 'MovieCardView.swift');
    const content = fs.readFileSync(movieCardPath, 'utf-8');

    // Check MovieListView struct exists
    expect(content).toContain('struct MovieListView');
    expect(content).toContain('let movies: [Movie]');
    expect(content).toContain('let watchedMovieIds: Set<Int>');
  });

  test('MovieListRow exists for compact row display', async () => {
    const movieCardPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Dashboard', 'MovieCardView.swift');
    const content = fs.readFileSync(movieCardPath, 'utf-8');

    // Check MovieListRow struct exists
    expect(content).toContain('struct MovieListRow');
    expect(content).toContain('let movie: Movie');
    expect(content).toContain('let isWatched: Bool');
  });

  test('Dashboard content switches between grid and list based on displayMode', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_ROOT, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check conditional rendering
    expect(content).toContain('masterListDisplayMode == .grid');
    expect(content).toContain('MovieGridView');
    expect(content).toContain('MovieListView');
  });

  test('Grid/List toggle has proper icons', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_ROOT, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check icons for grid and list
    expect(content).toContain('square.grid.2x2');
    expect(content).toContain('list.bullet');
  });

  test('MovieListRow has poster thumbnail with Kingfisher', async () => {
    const movieCardPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Dashboard', 'MovieCardView.swift');
    const content = fs.readFileSync(movieCardPath, 'utf-8');

    // Check poster loading in list row
    expect(content).toContain('posterThumbnail');
    expect(content).toContain('KFImage');
    expect(content).toContain('movie.posterUrl');
  });

  test('MovieListRow has watch toggle button', async () => {
    const movieCardPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Dashboard', 'MovieCardView.swift');
    const content = fs.readFileSync(movieCardPath, 'utf-8');

    // Check watch toggle in list row
    expect(content).toContain('watchToggleButton');
    expect(content).toContain('checkmark.circle.fill');
  });
});
