import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-009: Dashboard - Movie Grid (Master List)', () => {
  test('MovieCardView exists with poster, title, runtime', async () => {
    const movieCardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'MovieCardView.swift');
    expect(fs.existsSync(movieCardPath)).toBe(true);

    const content = fs.readFileSync(movieCardPath, 'utf-8');

    // Check for SwiftUI import and struct
    expect(content).toContain('import SwiftUI');
    expect(content).toContain('struct MovieCardView');

    // Check for movie data display
    expect(content).toContain('movie.title');
    expect(content).toContain('formattedRuntime');

    // Check for poster image handling
    expect(content).toContain('posterUrl');
    expect(content).toContain('posterImage');
  });

  test('LazyVGrid displays movies', async () => {
    const movieCardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'MovieCardView.swift');
    const content = fs.readFileSync(movieCardPath, 'utf-8');

    // Check for LazyVGrid
    expect(content).toContain('LazyVGrid');
    expect(content).toContain('GridItem');

    // Check for MovieGridView struct
    expect(content).toContain('struct MovieGridView');
    expect(content).toContain('ForEach');
  });

  test('2 columns on iPhone, more on iPad', async () => {
    const movieCardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'MovieCardView.swift');
    const content = fs.readFileSync(movieCardPath, 'utf-8');

    // Check for horizontal size class
    expect(content).toContain('horizontalSizeClass');

    // Check for column count logic
    expect(content).toContain('.regular');
    expect(content).toContain('columnCount');
  });

  test('Watched indicator (checkmark) on watched movies', async () => {
    const movieCardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'MovieCardView.swift');
    const content = fs.readFileSync(movieCardPath, 'utf-8');

    // Check for watched state
    expect(content).toContain('isWatched');

    // Check for checkmark indicator
    expect(content).toContain('checkmark');
    expect(content).toContain('watchedIndicator');
  });

  test('Posters loaded async with Kingfisher', async () => {
    const movieCardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'MovieCardView.swift');
    const content = fs.readFileSync(movieCardPath, 'utf-8');

    // Check for Kingfisher import
    expect(content).toContain('import Kingfisher');
    expect(content).toContain('KFImage');
  });

  test('Placeholder shown while loading images', async () => {
    const movieCardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'MovieCardView.swift');
    const content = fs.readFileSync(movieCardPath, 'utf-8');

    // Check for placeholder
    expect(content).toContain('.placeholder');
    expect(content).toContain('posterPlaceholder');
  });

  test('Pull to refresh reloads data', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for refreshable modifier
    expect(content).toContain('.refreshable');
    expect(content).toContain('loadData');
  });

  test('MovieGridView integrated in Dashboard', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for MovieGridView usage
    expect(content).toContain('MovieGridView');
    expect(content).toContain('viewModel.movies');
    expect(content).toContain('watchedMovieIds');
  });

  test('Toggle watched callback wired up', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for toggle watched callback
    expect(content).toContain('onToggleWatched');
    expect(content).toContain('toggleWatched');
  });

  test('Loading state shown while data loads', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for loading state
    expect(content).toContain('isLoading');
    expect(content).toContain('ProgressView');
    expect(content).toContain('Loading movies');
  });

  test('Empty state when no movies', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for empty state
    expect(content).toContain('movies.isEmpty');
    expect(content).toContain('No movies found');
  });

  test('Files are registered in Xcode project', async () => {
    const pbxprojPath = path.join(XCODE_PROJECT_PATH, 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const pbxprojContent = fs.readFileSync(pbxprojPath, 'utf-8');

    // Check MovieCardView is in the project
    expect(pbxprojContent).toContain('MovieCardView.swift');
    expect(pbxprojContent).toContain('MovieCardView.swift in Sources');
  });

  test('Accessibility support', async () => {
    const movieCardPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'MovieCardView.swift');
    const content = fs.readFileSync(movieCardPath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('accessibilityElement');
    expect(content).toContain('accessibilityLabel');
    expect(content).toContain('accessibilityHint');
  });
});
