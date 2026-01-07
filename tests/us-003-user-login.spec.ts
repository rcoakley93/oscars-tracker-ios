import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-003: User Authentication - Login', () => {
  test('LoginView with email and password fields exists', async () => {
    const loginViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'LoginView.swift');
    expect(fs.existsSync(loginViewPath)).toBe(true);

    const content = fs.readFileSync(loginViewPath, 'utf-8');

    // Check for SwiftUI import
    expect(content).toContain('import SwiftUI');

    // Check for LoginView struct
    expect(content).toContain('struct LoginView');

    // Check for email and password state variables
    expect(content).toContain('@State');
    expect(content).toContain('email');
    expect(content).toContain('password');

    // Check for TextField (email) and SecureField (password)
    expect(content).toContain('TextField');
    expect(content).toContain('SecureField');
  });

  test('Email format validation', async () => {
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    expect(fs.existsSync(authViewModelPath)).toBe(true);

    const content = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for email validation function
    expect(content).toContain('isValidEmail');

    // Check for email regex pattern in the code
    expect(content).toContain('emailRegex');
    expect(content).toContain('.regularExpression');
  });

  test('Password field with secure entry', async () => {
    const loginViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'LoginView.swift');
    const content = fs.readFileSync(loginViewPath, 'utf-8');

    // Check for SecureField for password
    expect(content).toContain('SecureField');

    // Check for password text content type
    expect(content).toContain('.password');
  });

  test('Sign In button triggers Supabase auth', async () => {
    const loginViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'LoginView.swift');
    const content = fs.readFileSync(loginViewPath, 'utf-8');

    // Check for Sign In button
    expect(content).toContain('Sign In');
    expect(content).toContain('Button');

    // Check for signIn function call
    expect(content).toContain('signIn');

    // Check AuthViewModel for Supabase auth call
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    const authContent = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for Supabase auth signIn
    expect(authContent).toContain('supabase.auth.signIn');
    expect(authContent).toContain('email');
    expect(authContent).toContain('password');
  });

  test('Error messages displayed for invalid credentials', async () => {
    const loginViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'LoginView.swift');
    const content = fs.readFileSync(loginViewPath, 'utf-8');

    // Check for error message display
    expect(content).toContain('errorMessage');

    // Check for error styling (destructive color)
    expect(content).toContain('destructive');

    // Check for error icon
    expect(content).toContain('exclamationmark');

    // Check AuthViewModel for error handling
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    const authContent = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for error message handling
    expect(authContent).toContain('@Published var errorMessage');
    expect(authContent).toContain('AuthError');
  });

  test('Successful login navigates to Dashboard', async () => {
    const appPath = path.join(OSCARS_TRACKER_PATH, 'App', 'OscarsTrackerApp.swift');
    const content = fs.readFileSync(appPath, 'utf-8');

    // Check for conditional navigation based on auth state
    expect(content).toContain('isAuthenticated');
    expect(content).toContain('ContentView');
    expect(content).toContain('LoginView');

    // Check AuthViewModel for isAuthenticated flag
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    const authContent = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for isAuthenticated being set on successful login
    expect(authContent).toContain('@Published var isAuthenticated');
    expect(authContent).toContain('isAuthenticated = true');
  });

  test('Loading state shown during authentication', async () => {
    const loginViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'LoginView.swift');
    const content = fs.readFileSync(loginViewPath, 'utf-8');

    // Check for loading indicator
    expect(content).toContain('ProgressView');
    expect(content).toContain('isLoading');

    // Check for disabled state during loading
    expect(content).toContain('.disabled');

    // Check AuthViewModel for isLoading flag
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    const authContent = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for isLoading state management
    expect(authContent).toContain('@Published var isLoading');
    expect(authContent).toContain('isLoading = true');
    expect(authContent).toContain('isLoading = false');
  });

  test('AuthViewModel is properly configured', async () => {
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    expect(fs.existsSync(authViewModelPath)).toBe(true);

    const content = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for SwiftUI and Supabase imports
    expect(content).toContain('import Foundation');
    expect(content).toContain('import Supabase');

    // Check for MainActor and ObservableObject
    expect(content).toContain('@MainActor');
    expect(content).toContain('ObservableObject');

    // Check for SupabaseClientManager usage
    expect(content).toContain('SupabaseClientManager');

    // Check for session checking
    expect(content).toContain('checkSession');
  });

  test('Files are registered in Xcode project', async () => {
    const pbxprojPath = path.join(XCODE_PROJECT_PATH, 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const pbxprojContent = fs.readFileSync(pbxprojPath, 'utf-8');

    // Check all auth files are in the project
    expect(pbxprojContent).toContain('AuthViewModel.swift');
    expect(pbxprojContent).toContain('LoginView.swift');

    // Check they're in the Sources build phase
    expect(pbxprojContent).toContain('AuthViewModel.swift in Sources');
    expect(pbxprojContent).toContain('LoginView.swift in Sources');

    // Check for Auth group in Views
    expect(pbxprojContent).toContain('/* Auth */');
  });

  test('Custom text field style exists', async () => {
    const loginViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'LoginView.swift');
    const content = fs.readFileSync(loginViewPath, 'utf-8');

    // Check for custom text field style
    expect(content).toContain('OscarsTextFieldStyle');
    expect(content).toContain('TextFieldStyle');

    // Check for proper styling
    expect(content).toContain('RoundedRectangle');
    expect(content).toContain('cornerRadius');
  });

  test('Accessibility labels are present', async () => {
    const loginViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'LoginView.swift');
    const content = fs.readFileSync(loginViewPath, 'utf-8');

    // Check for accessibility labels
    expect(content).toContain('accessibilityLabel');
    expect(content).toContain('accessibilityHint');
  });
});
