import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-029: Profile - View Profile', () => {
  test('ProfileView exists', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for ProfileView struct
    expect(content).toContain('struct ProfileView');
    expect(content).toContain('NavigationStack');
  });

  test('ProfileViewModel exists', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for ProfileViewModel class
    expect(content).toContain('class ProfileViewModel');
    expect(content).toContain('ObservableObject');
  });

  test('Displays username from profiles table', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const viewModelContent = fs.readFileSync(path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift'), 'utf-8');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for username display
    expect(viewModelContent).toContain('"profiles"');
    expect(viewModelContent).toContain('Profile');
    expect(content).toContain('profile?.username');
  });

  test('Shows avatar placeholder', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for avatar placeholder
    expect(content).toContain('Circle()');
    expect(content).toContain('person.fill');
    expect(content).toContain('frame(width: 100, height: 100)');
  });

  test('Avatar has gold border', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for gold border on avatar
    expect(content).toContain('Color.goldPrimary');
    expect(content).toContain('.stroke');
    expect(content).toContain('lineWidth: 3');
  });

  test('Displays member since date', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const viewModelContent = fs.readFileSync(path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift'), 'utf-8');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for member since display
    expect(viewModelContent).toContain('memberSinceFormatted');
    expect(viewModelContent).toContain('createdAt');
    expect(content).toContain('Member since');
    expect(content).toContain('calendar');
  });

  test('Date formatting function exists', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for date formatting
    expect(content).toContain('func memberSinceFormatted()');
    expect(content).toContain('ISO8601DateFormatter');
    expect(content).toContain('DateFormatter');
  });

  test('Shows watched count', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const viewModelContent = fs.readFileSync(path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift'), 'utf-8');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for watched count
    expect(viewModelContent).toContain('watchedCount');
    expect(viewModelContent).toContain('user_watched');
    expect(content).toContain('Watched');
    expect(content).toContain('eye.fill');
  });

  test('Shows predictions made count', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const viewModelContent = fs.readFileSync(path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift'), 'utf-8');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for predictions count
    expect(viewModelContent).toContain('predictionsMade');
    expect(viewModelContent).toContain('user_predictions');
    expect(content).toContain('Predictions');
    expect(content).toContain('checkmark.seal.fill');
  });

  test('Shows correct predictions count', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const viewModelContent = fs.readFileSync(path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift'), 'utf-8');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for correct predictions count
    expect(viewModelContent).toContain('correctPredictions');
    expect(content).toContain('Correct');
    expect(content).toContain('star.fill');
  });

  test('StatItemView component exists', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for StatItemView
    expect(content).toContain('struct StatItemView');
    expect(content).toContain('let value: Int');
    expect(content).toContain('let label: String');
    expect(content).toContain('let icon: String');
  });

  test('Pull to refresh functionality', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for refresh
    expect(content).toContain('.refreshable');
    expect(content).toContain('viewModel.loadData()');
  });

  test('Loading state shown', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for loading state
    expect(content).toContain('viewModel.isLoading');
    expect(content).toContain('loadingView');
    expect(content).toContain('ProgressView()');
    expect(content).toContain('Loading profile');
  });

  test('Empty state shown when no profile', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for empty state
    expect(content).toContain('emptyStateView');
    expect(content).toContain('profile == nil');
    expect(content).toContain('Profile not found');
  });

  test('Stats card uses glass card styling', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for styling
    expect(content).toContain('.glassCard()');
    expect(content).toContain('statsCard');
  });

  test('Accessibility labels for profile', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('accessibilityElement');
    expect(content).toContain('accessibilityLabel');
  });

  test('Files registered in Xcode project', async () => {
    const projectPath = path.join(XCODE_PROJECT_PATH, 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const content = fs.readFileSync(projectPath, 'utf-8');

    // Check that files are registered
    expect(content).toContain('ProfileView.swift');
    expect(content).toContain('ProfileViewModel.swift');
  });

  test('ContentView uses ProfileView', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check that ProfileView is used
    expect(content).toContain('ProfileView()');
  });

  test('ViewModel has profile @Published property', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for profile property
    expect(content).toContain('@Published var profile: Profile?');
  });

  test('Error handling in loadData', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for error handling
    expect(content).toContain('errorMessage');
    expect(content).toContain('catch');
    expect(content).toContain('Failed to load profile');
  });

  test('Gets current user from Supabase auth', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for auth session
    expect(content).toContain('supabase.auth.session');
    expect(content).toContain('user.id');
  });

  test('Stats displayed in horizontal layout', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for HStack layout with dividers
    expect(content).toContain('HStack');
    expect(content).toContain('Divider()');
    expect(content).toContain('StatItemView');
  });
});
