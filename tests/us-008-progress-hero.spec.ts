import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-008: Dashboard - Progress Hero', () => {
  test('ProgressHeroView displays watched count and total', async () => {
    const progressHeroPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'ProgressHeroView.swift');
    expect(fs.existsSync(progressHeroPath)).toBe(true);

    const content = fs.readFileSync(progressHeroPath, 'utf-8');

    // Check for SwiftUI import and struct
    expect(content).toContain('import SwiftUI');
    expect(content).toContain('struct ProgressHeroView');

    // Check for watched count and total count properties
    expect(content).toContain('watchedCount');
    expect(content).toContain('totalCount');

    // Check for display of count
    expect(content).toContain('movies watched');
  });

  test('Percentage calculated and displayed prominently', async () => {
    const progressHeroPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'ProgressHeroView.swift');
    const content = fs.readFileSync(progressHeroPath, 'utf-8');

    // Check for percentage calculation
    expect(content).toContain('percentage');
    expect(content).toContain('Double(watchedCount)');
    expect(content).toContain('Double(totalCount)');

    // Check for percentage string formatting
    expect(content).toContain('percentageString');
    expect(content).toContain('%');
  });

  test('Gold gradient progress bar shows completion', async () => {
    const progressHeroPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'ProgressHeroView.swift');
    const content = fs.readFileSync(progressHeroPath, 'utf-8');

    // Check for ProgressBarView component
    expect(content).toContain('ProgressBarView');
    expect(content).toContain('struct ProgressBarView');

    // Check for gold gradient
    expect(content).toContain('LinearGradient.gold');

    // Check for progress calculation
    expect(content).toContain('geometry.size.width * progress');

    // Check for RoundedRectangle shape
    expect(content).toContain('RoundedRectangle');
  });

  test('Movies per day calculation shown (days until March 15)', async () => {
    const progressHeroPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'ProgressHeroView.swift');
    const content = fs.readFileSync(progressHeroPath, 'utf-8');

    // Check for days remaining calculation
    expect(content).toContain('daysRemaining');
    expect(content).toContain('oscarDate');

    // Check for movies per day calculation
    expect(content).toContain('moviesPerDay');
    expect(content).toContain('movies/day');

    // Check for display
    expect(content).toContain('days left');
    expect(content).toContain('to finish on time');
  });

  test('Glass card styling with radial gradient background', async () => {
    const progressHeroPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'ProgressHeroView.swift');
    const content = fs.readFileSync(progressHeroPath, 'utf-8');

    // Check for glass card usage
    expect(content).toContain('.glassCard()');

    // Check for gold glow on percentage
    expect(content).toContain('.goldGlow()');
  });

  test('DashboardViewModel configured for data loading', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'DashboardViewModel.swift');
    expect(fs.existsSync(viewModelPath)).toBe(true);

    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for proper structure
    expect(content).toContain('import Foundation');
    expect(content).toContain('import Supabase');
    expect(content).toContain('@MainActor');
    expect(content).toContain('ObservableObject');

    // Check for published properties
    expect(content).toContain('@Published var movies');
    expect(content).toContain('@Published var watchedMovieIds');
    expect(content).toContain('@Published var isLoading');

    // Check for computed properties
    expect(content).toContain('watchedCount');
    expect(content).toContain('totalCount');

    // Check for Oscar date
    expect(content).toContain('oscarDate');
    expect(content).toContain('2026');
    expect(content).toContain('.month = 3');
    expect(content).toContain('.day = 15');
  });

  test('Updates when watched status changes', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'DashboardViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for toggle watched function
    expect(content).toContain('toggleWatched');

    // Check for optimistic update
    expect(content).toContain('watchedMovieIds.contains');
    expect(content).toContain('watchedMovieIds.remove');
    expect(content).toContain('watchedMovieIds.insert');

    // Check for Supabase integration
    expect(content).toContain('user_watched');
    expect(content).toContain('loadData');
  });

  test('ProgressHeroView integrated in Dashboard', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check for ProgressHeroView usage
    expect(content).toContain('ProgressHeroView');

    // Check for DashboardViewModel
    expect(content).toContain('DashboardViewModel');
    expect(content).toContain('@StateObject');

    // Check for pull to refresh
    expect(content).toContain('.refreshable');
    expect(content).toContain('loadData');
  });

  test('Files are registered in Xcode project', async () => {
    const pbxprojPath = path.join(XCODE_PROJECT_PATH, 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const pbxprojContent = fs.readFileSync(pbxprojPath, 'utf-8');

    // Check all dashboard files are in the project
    expect(pbxprojContent).toContain('ProgressHeroView.swift');
    expect(pbxprojContent).toContain('DashboardViewModel.swift');

    // Check they're in the Sources build phase
    expect(pbxprojContent).toContain('ProgressHeroView.swift in Sources');
    expect(pbxprojContent).toContain('DashboardViewModel.swift in Sources');

    // Check for Dashboard group
    expect(pbxprojContent).toContain('/* Dashboard */');
  });

  test('Accessibility support', async () => {
    const progressHeroPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Dashboard', 'ProgressHeroView.swift');
    const content = fs.readFileSync(progressHeroPath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('accessibilityElement');
    expect(content).toContain('accessibilityLabel');
  });
});
