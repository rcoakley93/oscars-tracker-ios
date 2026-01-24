import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const OSCARS_TRACKER_ROOT = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker');

test.describe('US-008: Add Launch Splash Screen', () => {
  test('SplashView file exists in Views/Splash folder', async () => {
    const splashViewPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Splash', 'SplashView.swift');
    expect(fs.existsSync(splashViewPath)).toBe(true);
  });

  test('SplashView contains app branding with trophy icon', async () => {
    const splashViewPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Splash', 'SplashView.swift');
    const content = fs.readFileSync(splashViewPath, 'utf-8');

    // Check for trophy icon
    expect(content).toContain('trophy.fill');
    // Check for app name
    expect(content).toContain('Oscars Tracker');
  });

  test('SplashView has loading indicator', async () => {
    const splashViewPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Splash', 'SplashView.swift');
    const content = fs.readFileSync(splashViewPath, 'utf-8');

    // Check for loading indicator
    expect(content).toContain('ProgressView');
  });

  test('SplashView has smooth animation on appear', async () => {
    const splashViewPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Splash', 'SplashView.swift');
    const content = fs.readFileSync(splashViewPath, 'utf-8');

    // Check for animation state and onAppear
    expect(content).toContain('@State');
    expect(content).toContain('isAnimating');
    expect(content).toContain('.onAppear');
    expect(content).toContain('withAnimation');
  });

  test('SplashView uses gold theme colors', async () => {
    const splashViewPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Splash', 'SplashView.swift');
    const content = fs.readFileSync(splashViewPath, 'utf-8');

    // Check for gold colors
    expect(content).toContain('goldPrimary');
    expect(content).toContain('appBackground');
  });

  test('AuthViewModel has isCheckingSession state variable', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'AuthViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for session checking state
    expect(content).toContain('@Published var isCheckingSession');
  });

  test('AuthViewModel sets isCheckingSession during session check', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_ROOT, 'ViewModels', 'AuthViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check that checkSession manages the state
    expect(content).toContain('isCheckingSession = true');
    expect(content).toContain('isCheckingSession = false');
  });

  test('OscarsTrackerApp shows SplashView while checking session', async () => {
    const appPath = path.join(OSCARS_TRACKER_ROOT, 'App', 'OscarsTrackerApp.swift');
    const content = fs.readFileSync(appPath, 'utf-8');

    // Check for splash screen condition
    expect(content).toContain('authViewModel.isCheckingSession');
    expect(content).toContain('SplashView()');
  });

  test('OscarsTrackerApp has smooth transition between views', async () => {
    const appPath = path.join(OSCARS_TRACKER_ROOT, 'App', 'OscarsTrackerApp.swift');
    const content = fs.readFileSync(appPath, 'utf-8');

    // Check for transitions
    expect(content).toContain('.transition');
    expect(content).toContain('.animation');
  });

  test('OscarsTrackerApp navigates to ContentView when authenticated', async () => {
    const appPath = path.join(OSCARS_TRACKER_ROOT, 'App', 'OscarsTrackerApp.swift');
    const content = fs.readFileSync(appPath, 'utf-8');

    // Check for authenticated navigation
    expect(content).toContain('authViewModel.isAuthenticated');
    expect(content).toContain('ContentView()');
  });

  test('OscarsTrackerApp navigates to LoginView when not authenticated', async () => {
    const appPath = path.join(OSCARS_TRACKER_ROOT, 'App', 'OscarsTrackerApp.swift');
    const content = fs.readFileSync(appPath, 'utf-8');

    // Check for login navigation
    expect(content).toContain('LoginView(authViewModel: authViewModel)');
  });

  test('SplashView is registered in Xcode project', async () => {
    const projectPath = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const content = fs.readFileSync(projectPath, 'utf-8');

    // Check file is registered
    expect(content).toContain('SplashView.swift');
    expect(content).toContain('/* Splash */');
  });
});
