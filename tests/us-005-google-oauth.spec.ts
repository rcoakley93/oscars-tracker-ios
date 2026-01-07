import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-005: User Authentication - Google OAuth', () => {
  test('Continue with Google button on LoginView', async () => {
    const loginViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'LoginView.swift');
    expect(fs.existsSync(loginViewPath)).toBe(true);

    const content = fs.readFileSync(loginViewPath, 'utf-8');

    // Check for Continue with Google button
    expect(content).toContain('Continue with Google');
    expect(content).toContain('Button');

    // Check for signInWithGoogle function call
    expect(content).toContain('signInWithGoogle');

    // Check for Google logo component
    expect(content).toContain('GoogleLogoView');

    // Check for googleAuth button style
    expect(content).toContain('.googleAuth');

    // Check for disabled state during loading
    expect(content).toContain('.disabled(authViewModel.isLoading)');

    // Check for accessibility
    expect(content).toContain('accessibilityLabel');
    expect(content).toContain('Continue with Google');
  });

  test('Continue with Google button on SignUpView', async () => {
    const signUpViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'SignUpView.swift');
    expect(fs.existsSync(signUpViewPath)).toBe(true);

    const content = fs.readFileSync(signUpViewPath, 'utf-8');

    // Check for Continue with Google button
    expect(content).toContain('Continue with Google');
    expect(content).toContain('Button');

    // Check for signInWithGoogle function call
    expect(content).toContain('signInWithGoogle');

    // Check for Google logo component
    expect(content).toContain('GoogleLogoView');

    // Check for googleAuth button style
    expect(content).toContain('.googleAuth');
  });

  test('Google OAuth flow via Supabase', async () => {
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    expect(fs.existsSync(authViewModelPath)).toBe(true);

    const content = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for signInWithGoogle function
    expect(content).toContain('func signInWithGoogle()');

    // Check for Supabase OAuth method
    expect(content).toContain('getOAuthSignInURL');
    expect(content).toContain('provider: .google');

    // Check for redirect URL
    expect(content).toContain('oscarstracker://');
    expect(content).toContain('auth/callback');
  });

  test('ASWebAuthenticationSession for OAuth flow', async () => {
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    const content = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for AuthenticationServices import
    expect(content).toContain('import AuthenticationServices');

    // Check for ASWebAuthenticationSession usage
    expect(content).toContain('ASWebAuthenticationSession');

    // Check for callback URL scheme
    expect(content).toContain('callbackURLScheme');
    expect(content).toContain('oscarstracker');

    // Check for presentation context provider
    expect(content).toContain('presentationContextProvider');
    expect(content).toContain('WebAuthPresentationContextProvider');
  });

  test('Handles callback and session creation', async () => {
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    const content = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for session handling from callback URL
    expect(content).toContain('supabase.auth.session(from:');
    expect(content).toContain('callbackURL');

    // Check for user assignment
    expect(content).toContain('currentUser = session.user');

    // Check for authentication state update
    expect(content).toContain('isAuthenticated = true');
  });

  test('New Google users trigger onboarding', async () => {
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    const content = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for profile check function
    expect(content).toContain('checkIfNeedsOnboarding');

    // Check for profiles table query
    expect(content).toContain('from("profiles")');
    expect(content).toContain('.select()');

    // Check for needsOnboarding flag setting
    expect(content).toContain('needsOnboarding = true');
  });

  test('Existing Google users navigate to Dashboard', async () => {
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    const content = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for profile exists check
    expect(content).toContain('profiles.isEmpty');
    expect(content).toContain('username');

    // Check for needsOnboarding = false for existing users
    expect(content).toContain('needsOnboarding = false');
  });

  test('Error handling for Google OAuth', async () => {
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    const content = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for error mapping function
    expect(content).toContain('mapGoogleAuthError');

    // Check for cancelled login handling
    expect(content).toContain('canceledLogin');

    // Check for user-friendly error messages
    expect(content).toContain('Failed to sign in with Google');
    expect(content).toContain('Network error');
  });

  test('WebAuthPresentationContextProvider exists', async () => {
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    const content = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for presentation context provider class
    expect(content).toContain('class WebAuthPresentationContextProvider');
    expect(content).toContain('ASWebAuthenticationPresentationContextProviding');

    // Check for shared instance
    expect(content).toContain('static let shared');

    // Check for presentationAnchor function
    expect(content).toContain('func presentationAnchor');
    expect(content).toContain('ASPresentationAnchor');
  });

  test('GoogleLogoView component exists', async () => {
    const googleLogoPath = path.join(OSCARS_TRACKER_PATH, 'Components', 'GoogleLogoView.swift');
    expect(fs.existsSync(googleLogoPath)).toBe(true);

    const content = fs.readFileSync(googleLogoPath, 'utf-8');

    // Check for SwiftUI import
    expect(content).toContain('import SwiftUI');

    // Check for GoogleLogoView struct
    expect(content).toContain('struct GoogleLogoView');
    expect(content).toContain(': View');

    // Check for Google brand colors
    expect(content).toContain('66/255');   // Blue
    expect(content).toContain('52/255');   // Green
    expect(content).toContain('251/255');  // Yellow
    expect(content).toContain('234/255');  // Red
  });

  test('GoogleAuthButtonStyle exists', async () => {
    const buttonStylePath = path.join(OSCARS_TRACKER_PATH, 'Components', 'GoldButtonStyle.swift');
    expect(fs.existsSync(buttonStylePath)).toBe(true);

    const content = fs.readFileSync(buttonStylePath, 'utf-8');

    // Check for GoogleAuthButtonStyle
    expect(content).toContain('struct GoogleAuthButtonStyle');
    expect(content).toContain('ButtonStyle');

    // Check for extension with static var
    expect(content).toContain('static var googleAuth');
    expect(content).toContain('GoogleAuthButtonStyle()');
  });

  test('Files are registered in Xcode project', async () => {
    const pbxprojPath = path.join(XCODE_PROJECT_PATH, 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const pbxprojContent = fs.readFileSync(pbxprojPath, 'utf-8');

    // Check GoogleLogoView is in the project
    expect(pbxprojContent).toContain('GoogleLogoView.swift');
    expect(pbxprojContent).toContain('GoogleLogoView.swift in Sources');

    // Check it's in the Components group
    expect(pbxprojContent).toContain('/* Components */');
  });

  test('Or divider between email and Google login', async () => {
    const loginViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'LoginView.swift');
    const content = fs.readFileSync(loginViewPath, 'utf-8');

    // Check for "or" divider
    expect(content).toContain('"or"');
    expect(content).toContain('Rectangle()');
    expect(content).toContain('.fill(Color.borderColor)');
  });

  test('Loading state management for Google OAuth', async () => {
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    const content = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for loading state in signInWithGoogle
    expect(content).toMatch(/func signInWithGoogle[\s\S]*?isLoading = true/);
    expect(content).toMatch(/func signInWithGoogle[\s\S]*?isLoading = false/);
  });
});
