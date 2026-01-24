import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const OSCARS_TRACKER_ROOT = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker');

test.describe('US-001: Fix Actor Category Display Hierarchy', () => {
  test('CategoryNominee struct exists with movie and detailText properties', async () => {
    const nominationPath = path.join(OSCARS_TRACKER_ROOT, 'Models', 'Nomination.swift');
    const content = fs.readFileSync(nominationPath, 'utf-8');

    // Check CategoryNominee struct exists
    expect(content).toContain('struct CategoryNominee');
    expect(content).toContain('let movie: Movie');
    expect(content).toContain('let detailText: String?');
    expect(content).toContain('var hasActorDetail: Bool');
  });

  test('CategoryWithMovies has isActorCategory computed property', async () => {
    const nominationPath = path.join(OSCARS_TRACKER_ROOT, 'Models', 'Nomination.swift');
    const content = fs.readFileSync(nominationPath, 'utf-8');

    // Check CategoryWithMovies has isActorCategory
    expect(content).toContain('struct CategoryWithMovies');
    expect(content).toContain('var isActorCategory: Bool');
    expect(content).toContain('let nominees: [CategoryNominee]');
  });

  test('CategoryMovieRow accepts nominee and isActorCategory parameters', async () => {
    const categoryListPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Dashboard', 'CategoryListView.swift');
    const content = fs.readFileSync(categoryListPath, 'utf-8');

    // Check CategoryMovieRow has correct parameters
    expect(content).toContain('struct CategoryMovieRow');
    expect(content).toContain('let nominee: CategoryNominee');
    expect(content).toContain('let isActorCategory: Bool');
  });

  test('Actor categories display actor name as primary headline', async () => {
    const categoryListPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Dashboard', 'CategoryListView.swift');
    const content = fs.readFileSync(categoryListPath, 'utf-8');

    // Check headline logic prioritizes actor name for actor categories
    expect(content).toContain('headlineText');
    expect(content).toContain('isActorCategory');
    expect(content).toMatch(/if isActorCategory.*actorName.*nominee\.detailText/s);
  });

  test('Actor categories display movie title with year as subheadline', async () => {
    const categoryListPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Dashboard', 'CategoryListView.swift');
    const content = fs.readFileSync(categoryListPath, 'utf-8');

    // Check subheadline shows movie title with year for actor categories
    expect(content).toContain('subheadlineText');
    // Format: "Movie Title (2025)"
    expect(content).toMatch(/\(movie\.title\).*\(year\)/);
  });

  test('DashboardViewModel loads nominees with detailText', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check ViewModel creates CategoryNominee with detailText
    expect(content).toContain('CategoryNominee');
    expect(content).toContain('detailText: nomination.detailText');
  });

  test('Actor categories sort by actor name', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check sorting logic for actor categories
    expect(content).toContain('isActorCategory');
    expect(content).toMatch(/sorted.*detailText/);
  });

  test('Accessibility labels include actor name for actor categories', async () => {
    const categoryListPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Dashboard', 'CategoryListView.swift');
    const content = fs.readFileSync(categoryListPath, 'utf-8');

    // Check accessibility label includes actor name
    expect(content).toContain('accessibilityLabelText');
    expect(content).toMatch(/actorName.*in.*movie\.title/);
  });

  test('Year is displayed using verbatim interpolation to avoid formatting', async () => {
    const categoryListPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Dashboard', 'CategoryListView.swift');
    const content = fs.readFileSync(categoryListPath, 'utf-8');

    // Check year uses verbatim or proper string formatting
    // Should not use automatic number formatting that adds commas
    expect(content).toMatch(/Text\(verbatim.*year\)|String\(year\)/);
  });
});
