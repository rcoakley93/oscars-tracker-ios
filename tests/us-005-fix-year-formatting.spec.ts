import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const OSCARS_TRACKER_ROOT = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker');

test.describe('US-005: Fix Year Number Formatting', () => {
  test('CategoryListView uses verbatim for year display', async () => {
    const categoryListPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Dashboard', 'CategoryListView.swift');
    const content = fs.readFileSync(categoryListPath, 'utf-8');

    // Check verbatim is used for year to prevent comma formatting
    expect(content).toMatch(/Text\(verbatim.*year/);
  });

  test('Year format does not use automatic number formatting', async () => {
    const categoryListPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Dashboard', 'CategoryListView.swift');
    const content = fs.readFileSync(categoryListPath, 'utf-8');

    // Should NOT have plain Text("\(year)") without verbatim
    // This would cause locale-based formatting like "2,025"
    const hasPlainYearInterpolation = /Text\("\\\(year\)"\)/.test(content);
    expect(hasPlainYearInterpolation).toBe(false);
  });

  test('Subheadline year format uses String interpolation not number', async () => {
    const categoryListPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Dashboard', 'CategoryListView.swift');
    const content = fs.readFileSync(categoryListPath, 'utf-8');

    // Check subheadline format: "Movie Title (2025)"
    // Should use string interpolation which is safe - \(movie.title) (\(year))
    expect(content).toContain('\\(movie.title) (\\(year))');
  });

  test('Year is displayed with proper formatting in category rows', async () => {
    const categoryListPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Dashboard', 'CategoryListView.swift');
    const content = fs.readFileSync(categoryListPath, 'utf-8');

    // Verify year display logic exists
    expect(content).toContain('movie.releaseYear');
    expect(content).toContain('let year = movie.releaseYear');
  });
});
