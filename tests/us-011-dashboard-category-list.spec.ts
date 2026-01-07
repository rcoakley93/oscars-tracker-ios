import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-011: Dashboard - Category List View', () => {
  test('Segmented picker to switch between Master List and By Category', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for segmented picker
    expect(content).toContain('Picker');
    expect(content).toContain('.pickerStyle(.segmented)');

    // Check for view mode binding
    expect(content).toContain('viewModel.viewMode');
    expect(content).toContain('DashboardViewMode');
  });

  test('DashboardViewMode enum exists with Master List and By Category options', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for enum definition
    expect(content).toContain('enum DashboardViewMode');
    expect(content).toContain('case masterList');
    expect(content).toContain('case byCategory');
    expect(content).toContain('Master List');
    expect(content).toContain('By Category');
  });

  test('CategoryListView exists and groups movies by category', async () => {
    const categoryListPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'CategoryListView.swift');
    expect(fs.existsSync(categoryListPath)).toBe(true);

    const content = fs.readFileSync(categoryListPath, 'utf-8');

    // Check for SwiftUI import and struct
    expect(content).toContain('import SwiftUI');
    expect(content).toContain('struct CategoryListView');

    // Check for categories data
    expect(content).toContain('categoriesWithMovies');
    expect(content).toContain('ForEach');
    expect(content).toContain('Section');
  });

  test('Category headers show category name', async () => {
    const categoryListPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'CategoryListView.swift');
    const content = fs.readFileSync(categoryListPath, 'utf-8');

    // Check for category header
    expect(content).toContain('CategoryHeaderView');
    expect(content).toContain('categoryName');
    expect(content).toContain('category.name');
  });

  test('Movies under each category with watch toggle', async () => {
    const categoryListPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'CategoryListView.swift');
    const content = fs.readFileSync(categoryListPath, 'utf-8');

    // Check for movie row with toggle
    expect(content).toContain('CategoryMovieRow');
    expect(content).toContain('onToggleWatched');
    expect(content).toContain('isWatched');
    expect(content).toContain('watchedMovieIds');
  });

  test('Same movie can appear in multiple categories', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for CategoryWithMovies structure handling
    expect(content).toContain('categoriesWithMovies');
    expect(content).toContain('CategoryWithMovies');

    // Check for loading nominations which links movies to categories
    expect(content).toContain('nominations');
    expect(content).toContain('categoryId');
  });

  test('CategoryWithMovies struct exists', async () => {
    const nominationPath = path.join(OSCARS_TRACKER_PATH, 'Models', 'Nomination.swift');
    const content = fs.readFileSync(nominationPath, 'utf-8');

    // Check for CategoryWithMovies struct
    expect(content).toContain('struct CategoryWithMovies');
    expect(content).toContain('Identifiable');
    expect(content).toContain('name: String');
    expect(content).toContain('movies: [Movie]');
  });

  test('DashboardViewModel loads categories with movies', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for loading categories
    expect(content).toContain('loadCategoriesWithMovies');
    expect(content).toContain('categories');
    expect(content).toContain('from("categories")');
  });

  test('Smooth animation on view switch', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for transition animation
    expect(content).toContain('.transition');
    expect(content).toContain('.opacity');
    expect(content).toContain('.animation');
    expect(content).toContain('.easeInOut');
  });

  test('View mode picker shows in Dashboard', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for view mode picker
    expect(content).toContain('viewModePicker');
    expect(content).toContain('View Mode');
  });

  test('CategoryListView displays when By Category is selected', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for category list view display
    expect(content).toContain('case .byCategory');
    expect(content).toContain('CategoryListView');
    expect(content).toContain('viewModel.categoriesWithMovies');
  });

  test('Files are registered in Xcode project', async () => {
    const pbxprojPath = path.join(XCODE_PROJECT_PATH, 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const pbxprojContent = fs.readFileSync(pbxprojPath, 'utf-8');

    // Check CategoryListView is in the project
    expect(pbxprojContent).toContain('CategoryListView.swift');
    expect(pbxprojContent).toContain('CategoryListView.swift in Sources');
  });

  test('Accessibility support for category list', async () => {
    const categoryListPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'CategoryListView.swift');
    const content = fs.readFileSync(categoryListPath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('accessibilityElement');
    expect(content).toContain('accessibilityLabel');
    expect(content).toContain('accessibilityHint');
  });

  test('Poster thumbnails in category rows', async () => {
    const categoryListPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'CategoryListView.swift');
    const content = fs.readFileSync(categoryListPath, 'utf-8');

    // Check for poster thumbnails
    expect(content).toContain('import Kingfisher');
    expect(content).toContain('KFImage');
    expect(content).toContain('posterUrl');
    expect(content).toContain('posterThumbnail');
  });

  test('Watch toggle button styling', async () => {
    const categoryListPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'CategoryListView.swift');
    const content = fs.readFileSync(categoryListPath, 'utf-8');

    // Check for watch toggle button
    expect(content).toContain('watchToggleButton');
    expect(content).toContain('checkmark.circle.fill');
    expect(content).toContain('circle');
    expect(content).toContain('goldPrimary');
  });
});
