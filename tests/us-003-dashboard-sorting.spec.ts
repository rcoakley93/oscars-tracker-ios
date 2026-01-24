import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const OSCARS_TRACKER_ROOT = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker');

test.describe('US-003: Add Dashboard Sorting Logic', () => {
  test('DashboardSortOption enum exists with all sort options', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check enum exists with all cases
    expect(content).toContain('enum DashboardSortOption');
    expect(content).toContain('case titleAZ');
    expect(content).toContain('case titleZA');
    expect(content).toContain('case runtimeAsc');
    expect(content).toContain('case runtimeDesc');
  });

  test('DashboardSortOption has display names', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check display names
    expect(content).toContain('Title (A-Z)');
    expect(content).toContain('Title (Z-A)');
    expect(content).toContain('Runtime');
  });

  test('DashboardViewModel has sortOption state variable', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check state variable exists
    expect(content).toContain('@Published var sortOption');
    expect(content).toContain('DashboardSortOption');
  });

  test('DashboardViewModel has sortedMovies computed property', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check computed property exists
    expect(content).toContain('var sortedMovies');
    expect(content).toContain('switch sortOption');
  });

  test('Sorting logic handles title A-Z correctly', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check title sorting uses case-insensitive comparison
    expect(content).toContain('localizedCaseInsensitiveCompare');
    expect(content).toContain('.orderedAscending');
  });

  test('Sorting logic handles title Z-A correctly', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check Z-A sorting
    expect(content).toContain('.orderedDescending');
  });

  test('Sorting logic handles runtime ascending', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check runtime ascending sorting
    expect(content).toMatch(/runtimeMinutes.*<.*runtimeMinutes/);
  });

  test('Sorting logic handles runtime descending', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check runtime descending sorting
    expect(content).toMatch(/runtimeMinutes.*>.*runtimeMinutes/);
  });

  test('ContentView has sortMenu in toolbar', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_ROOT, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check sort menu exists
    expect(content).toContain('sortMenu');
    expect(content).toContain('.toolbar');
    expect(content).toContain('ToolbarItem');
  });

  test('Sort menu shows all options', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_ROOT, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check menu iterates over all options
    expect(content).toContain('DashboardSortOption.allCases');
    expect(content).toContain('Menu');
  });

  test('Sort menu has accessible label', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_ROOT, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check accessibility
    expect(content).toContain('accessibilityLabel("Sort movies")');
  });

  test('Dashboard uses sortedMovies instead of movies', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_ROOT, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check sorted movies are used
    expect(content).toContain('viewModel.sortedMovies');
  });
});
