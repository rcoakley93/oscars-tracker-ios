import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const OSCARS_TRACKER_ROOT = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker');

test.describe('US-009: Secure Logout Redirection', () => {
  test('AuthViewModel signOut clears session immediately', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'AuthViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check signOut clears session
    expect(content).toContain('supabase.auth.signOut()');
  });

  test('AuthViewModel signOut sets isAuthenticated to false', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'AuthViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check isAuthenticated is set to false
    expect(content).toContain('isAuthenticated = false');
    expect(content).toContain('currentUser = nil');
  });

  test('AuthViewModel signOut clears needsOnboarding', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'AuthViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check needsOnboarding is reset
    expect(content).toContain('needsOnboarding = false');
  });

  test('ProfileView uses EnvironmentObject for AuthViewModel', async () => {
    const profileViewPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check for environment object
    expect(content).toContain('@EnvironmentObject');
    expect(content).toContain('authViewModel: AuthViewModel');
  });

  test('ProfileView signOut action uses authViewModel', async () => {
    const profileViewPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check signOut uses authViewModel
    expect(content).toContain('authViewModel.signOut()');
  });

  test('OscarsTrackerApp navigation is conditional on isAuthenticated', async () => {
    const appPath = path.join(OSCARS_TRACKER_ROOT, 'App', 'OscarsTrackerApp.swift');
    const content = fs.readFileSync(appPath, 'utf-8');

    // Check conditional navigation
    expect(content).toContain('if authViewModel.isCheckingSession');
    expect(content).toContain('else if authViewModel.isAuthenticated');
    expect(content).toContain('else');
    expect(content).toContain('LoginView');
  });

  test('OscarsTrackerApp provides authViewModel as environmentObject', async () => {
    const appPath = path.join(OSCARS_TRACKER_ROOT, 'App', 'OscarsTrackerApp.swift');
    const content = fs.readFileSync(appPath, 'utf-8');

    // Check environment object is provided
    expect(content).toContain('.environmentObject(authViewModel)');
  });

  test('Navigation uses Group for conditional view switching', async () => {
    const appPath = path.join(OSCARS_TRACKER_ROOT, 'App', 'OscarsTrackerApp.swift');
    const content = fs.readFileSync(appPath, 'utf-8');

    // Check Group wrapper for view switching (not NavigationStack with state)
    expect(content).toContain('Group {');
  });

  test('Delete account resets auth state', async () => {
    const profileViewPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check delete account resets auth
    expect(content).toContain('authViewModel.isAuthenticated = false');
    expect(content).toContain('authViewModel.currentUser = nil');
  });

  test('Logout confirmation alert exists', async () => {
    const profileViewPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check confirmation dialog
    expect(content).toContain('showSignOutConfirmation');
    expect(content).toContain('.alert("Sign Out"');
    expect(content).toContain('Are you sure you want to sign out?');
  });
});
