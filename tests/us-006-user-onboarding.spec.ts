import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-006: User Onboarding - Username Setup', () => {
  test('OnboardingView exists and is presented as sheet', async () => {
    const onboardingViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Onboarding', 'OnboardingView.swift');
    expect(fs.existsSync(onboardingViewPath)).toBe(true);

    const content = fs.readFileSync(onboardingViewPath, 'utf-8');

    // Check for SwiftUI import
    expect(content).toContain('import SwiftUI');

    // Check for OnboardingView struct
    expect(content).toContain('struct OnboardingView');

    // Check it's presented as sheet in app
    const appPath = path.join(OSCARS_TRACKER_PATH, 'App', 'OscarsTrackerApp.swift');
    const appContent = fs.readFileSync(appPath, 'utf-8');

    expect(appContent).toContain('.sheet');
    expect(appContent).toContain('needsOnboarding');
    expect(appContent).toContain('OnboardingView');

    // Check sheet cannot be dismissed by swiping
    expect(content).toContain('interactiveDismissDisabled');
  });

  test('Username text field with validation exists', async () => {
    const onboardingViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Onboarding', 'OnboardingView.swift');
    const content = fs.readFileSync(onboardingViewPath, 'utf-8');

    // Check for username text field
    expect(content).toContain('TextField');
    expect(content).toContain('username');

    // Check for validation indicators
    expect(content).toContain('isLengthValid');
    expect(content).toContain('isFormatValid');
    expect(content).toContain('3-20 characters');
    expect(content).toContain('Letters, numbers, underscores');
  });

  test('Profanity filter on username implemented', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'OnboardingViewModel.swift');
    expect(fs.existsSync(viewModelPath)).toBe(true);

    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for profanity list
    expect(content).toContain('profanityList');
    expect(content).toContain('Set<String>');

    // Check for profanity check function
    expect(content).toContain('containsProfanity');

    // Check profanity is used in validation
    const onboardingViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Onboarding', 'OnboardingView.swift');
    const viewContent = fs.readFileSync(onboardingViewPath, 'utf-8');

    expect(viewContent).toContain('containsProfanity');
    expect(viewContent).toContain('inappropriate');
  });

  test('Username saved to profiles table', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'OnboardingViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for saveUsername function
    expect(content).toContain('saveUsername');

    // Check for Supabase profiles table upsert
    expect(content).toContain('profiles');
    expect(content).toContain('upsert');
    expect(content).toContain('username');
  });

  test('Continue button dismisses sheet and shows Dashboard', async () => {
    const onboardingViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Onboarding', 'OnboardingView.swift');
    const content = fs.readFileSync(onboardingViewPath, 'utf-8');

    // Check for Continue button
    expect(content).toContain('Continue');
    expect(content).toContain('Button');

    // Check for completeOnboarding call
    expect(content).toContain('completeOnboarding');

    // Verify completeOnboarding exists in AuthViewModel
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    const authContent = fs.readFileSync(authViewModelPath, 'utf-8');

    expect(authContent).toContain('completeOnboarding');
    expect(authContent).toContain('needsOnboarding = false');
  });

  test('Cannot proceed without valid username', async () => {
    const onboardingViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Onboarding', 'OnboardingView.swift');
    const content = fs.readFileSync(onboardingViewPath, 'utf-8');

    // Check for disabled state on button
    expect(content).toContain('.disabled');
    expect(content).toContain('isUsernameValid');

    // Check ViewModel has isUsernameValid
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'OnboardingViewModel.swift');
    const vmContent = fs.readFileSync(viewModelPath, 'utf-8');

    expect(vmContent).toContain('isUsernameValid');
    expect(vmContent).toContain('isLengthValid');
    expect(vmContent).toContain('isFormatValid');
    expect(vmContent).toContain('containsProfanity');
  });

  test('OnboardingViewModel properly configured', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'OnboardingViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for proper imports and decorators
    expect(content).toContain('import Foundation');
    expect(content).toContain('import Supabase');
    expect(content).toContain('@MainActor');
    expect(content).toContain('ObservableObject');

    // Check for Published properties
    expect(content).toContain('@Published var username');
    expect(content).toContain('@Published var isLoading');
    expect(content).toContain('@Published var errorMessage');

    // Check for validation methods
    expect(content).toContain('validateUsername');
  });

  test('Loading state shown during save', async () => {
    const onboardingViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Onboarding', 'OnboardingView.swift');
    const content = fs.readFileSync(onboardingViewPath, 'utf-8');

    // Check for loading indicator
    expect(content).toContain('ProgressView');
    expect(content).toContain('isLoading');
    expect(content).toContain('Saving');
  });

  test('Error message display', async () => {
    const onboardingViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Onboarding', 'OnboardingView.swift');
    const content = fs.readFileSync(onboardingViewPath, 'utf-8');

    // Check for error message display
    expect(content).toContain('errorMessage');
    expect(content).toContain('destructive');
    expect(content).toContain('exclamationmark');
  });

  test('Files are registered in Xcode project', async () => {
    const pbxprojPath = path.join(XCODE_PROJECT_PATH, 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const pbxprojContent = fs.readFileSync(pbxprojPath, 'utf-8');

    // Check all onboarding files are in the project
    expect(pbxprojContent).toContain('OnboardingView.swift');
    expect(pbxprojContent).toContain('OnboardingViewModel.swift');

    // Check they're in the Sources build phase
    expect(pbxprojContent).toContain('OnboardingView.swift in Sources');
    expect(pbxprojContent).toContain('OnboardingViewModel.swift in Sources');

    // Check for Onboarding group
    expect(pbxprojContent).toContain('/* Onboarding */');
  });

  test('Accessibility labels are present', async () => {
    const onboardingViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Onboarding', 'OnboardingView.swift');
    const content = fs.readFileSync(onboardingViewPath, 'utf-8');

    // Check for accessibility labels
    expect(content).toContain('accessibilityLabel');
    expect(content).toContain('accessibilityHint');
  });
});
