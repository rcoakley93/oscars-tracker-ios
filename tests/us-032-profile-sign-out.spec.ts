import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-032: Profile - Sign Out', () => {
  test('ProfileView has sign out button', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for sign out button
    expect(content).toContain('Sign Out');
    expect(content).toContain('rectangle.portrait.and.arrow.right');
  });

  test('Sign out button in account section', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for account section
    expect(content).toContain('accountSection');
    expect(content).toContain('Account');
    expect(content).toContain('Button');
  });

  test('Sign out confirmation dialog exists', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for confirmation dialog
    expect(content).toContain('showSignOutConfirmation');
    expect(content).toContain('.alert');
    expect(content).toContain('Are you sure you want to sign out?');
  });

  test('Confirmation dialog has cancel and sign out buttons', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for dialog buttons
    expect(content).toContain('Button("Cancel", role: .cancel)');
    expect(content).toContain('Button("Sign Out", role: .destructive)');
  });

  test('ProfileViewModel has signOut function', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for signOut function
    expect(content).toContain('func signOut()');
    expect(content).toContain('async');
  });

  test('Sign out calls Supabase auth signOut', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for Supabase signOut call
    expect(content).toContain('supabase.auth.signOut()');
  });

  test('Sign out clears local state', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check that local state is cleared
    expect(content).toContain('profile = nil');
    expect(content).toContain('watchedCount = 0');
    expect(content).toContain('predictionsMade = 0');
    expect(content).toContain('correctPredictions = 0');
  });

  test('Sign out handles errors', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for error handling
    expect(content).toContain('catch');
    expect(content).toContain('Failed to sign out');
    expect(content).toContain('HapticManager.error()');
  });

  test('Sign out button uses GoldButtonStyle', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for button styling
    expect(content).toContain('.buttonStyle(GoldButtonStyle())');
  });

  test('Sign out button has accessibility label', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('accessibilityLabel');
    expect(content).toContain('Sign out');
  });

  test('Account section uses glass card styling', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check that account section has proper styling
    const accountSectionMatch = content.match(/accountSection[\s\S]*?\.glassCard\(\)/);
    expect(accountSectionMatch).not.toBeNull();
  });

  test('Sign out shows loading state', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for loading state in signOut
    const signOutMatch = content.match(/func signOut[\s\S]*?isLoading = true/);
    expect(signOutMatch).not.toBeNull();
  });

  test('Account section displayed when profile loaded', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check that accountSection is in the view hierarchy
    expect(content).toContain('profileHeader');
    expect(content).toContain('statsCard');
    expect(content).toContain('accountSection');
  });
});
