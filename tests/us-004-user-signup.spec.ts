import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-004: User Authentication - Sign Up', () => {
  test('SignUpView with email and password fields exists', async () => {
    const signUpViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'SignUpView.swift');
    expect(fs.existsSync(signUpViewPath)).toBe(true);

    const content = fs.readFileSync(signUpViewPath, 'utf-8');

    // Check for SwiftUI import
    expect(content).toContain('import SwiftUI');

    // Check for SignUpView struct
    expect(content).toContain('struct SignUpView');

    // Check for email and password state variables
    expect(content).toContain('@State');
    expect(content).toContain('email');
    expect(content).toContain('password');

    // Check for TextField and SecureField
    expect(content).toContain('TextField');
    expect(content).toContain('SecureField');
  });

  test('Password confirmation field exists', async () => {
    const signUpViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'SignUpView.swift');
    const content = fs.readFileSync(signUpViewPath, 'utf-8');

    // Check for confirm password field
    expect(content).toContain('confirmPassword');
    expect(content).toContain('Confirm Password');

    // Check for password match indicator
    expect(content).toContain('passwordsMatch');
    expect(content).toContain('Passwords match');
    expect(content).toContain('Passwords do not match');
  });

  test('Email format validation', async () => {
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    const content = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for email validation function
    expect(content).toContain('isValidEmail');

    // Check for email regex pattern usage
    expect(content).toContain('emailRegex');
    expect(content).toContain('.regularExpression');
  });

  test('Password strength requirements enforced', async () => {
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    const content = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for password validation function
    expect(content).toContain('validatePassword');

    // Check for password strength requirements
    expect(content).toContain('8 characters');
    expect(content).toContain('uppercase');
    expect(content).toContain('lowercase');
    expect(content).toContain('number');

    // Check for password strength enum
    expect(content).toContain('PasswordStrength');
    expect(content).toContain('weak');
    expect(content).toContain('medium');
    expect(content).toContain('strong');
  });

  test('Password strength indicator in UI', async () => {
    const signUpViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'SignUpView.swift');
    const content = fs.readFileSync(signUpViewPath, 'utf-8');

    // Check for password strength view
    expect(content).toContain('PasswordStrengthView');
    expect(content).toContain('passwordStrength');

    // Check for password requirements view
    expect(content).toContain('PasswordRequirementsView');
    expect(content).toContain('RequirementRow');
  });

  test('Sign Up button creates Supabase user', async () => {
    const signUpViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'SignUpView.swift');
    const content = fs.readFileSync(signUpViewPath, 'utf-8');

    // Check for Sign Up button
    expect(content).toContain('Sign Up');
    expect(content).toContain('Button');

    // Check for signUp function call
    expect(content).toContain('signUp');

    // Check AuthViewModel for Supabase signUp call
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    const authContent = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for Supabase auth signUp
    expect(authContent).toContain('supabase.auth.signUp');
    expect(authContent).toContain('email');
    expect(authContent).toContain('password');
  });

  test('Error handling for existing email', async () => {
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    const content = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for sign up error mapping
    expect(content).toContain('mapSignUpError');

    // Check for already exists error
    expect(content).toContain('already registered');
    expect(content).toContain('already exists');

    // Check for error display in SignUpView
    const signUpViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'SignUpView.swift');
    const signUpContent = fs.readFileSync(signUpViewPath, 'utf-8');

    expect(signUpContent).toContain('errorMessage');
    expect(signUpContent).toContain('destructive');
  });

  test('Successful signup triggers onboarding flow', async () => {
    const authViewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'AuthViewModel.swift');
    const content = fs.readFileSync(authViewModelPath, 'utf-8');

    // Check for needsOnboarding flag
    expect(content).toContain('needsOnboarding');

    // Check that sign up sets needsOnboarding to true
    expect(content).toContain('needsOnboarding = true');

    // Check for completeOnboarding function
    expect(content).toContain('completeOnboarding');
  });

  test('Loading state shown during signup', async () => {
    const signUpViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'SignUpView.swift');
    const content = fs.readFileSync(signUpViewPath, 'utf-8');

    // Check for loading indicator
    expect(content).toContain('ProgressView');
    expect(content).toContain('isLoading');
    expect(content).toContain('Creating Account');

    // Check for disabled state during loading
    expect(content).toContain('.disabled');
  });

  test('Navigation between Login and SignUp', async () => {
    // Check LoginView has navigation to SignUp
    const loginViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'LoginView.swift');
    const loginContent = fs.readFileSync(loginViewPath, 'utf-8');

    expect(loginContent).toContain('showSignUp');
    expect(loginContent).toContain('SignUpView');
    expect(loginContent).toContain('fullScreenCover');

    // Check SignUpView has back navigation
    const signUpViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'SignUpView.swift');
    const signUpContent = fs.readFileSync(signUpViewPath, 'utf-8');

    expect(signUpContent).toContain('showSignUp');
    expect(signUpContent).toContain('chevron.left');
    expect(signUpContent).toContain('Already have an account');
  });

  test('Files are registered in Xcode project', async () => {
    const pbxprojPath = path.join(XCODE_PROJECT_PATH, 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const pbxprojContent = fs.readFileSync(pbxprojPath, 'utf-8');

    // Check SignUpView is in the project
    expect(pbxprojContent).toContain('SignUpView.swift');

    // Check it's in the Sources build phase
    expect(pbxprojContent).toContain('SignUpView.swift in Sources');
  });

  test('Accessibility labels are present', async () => {
    const signUpViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Auth', 'SignUpView.swift');
    const content = fs.readFileSync(signUpViewPath, 'utf-8');

    // Check for accessibility labels
    expect(content).toContain('accessibilityLabel');
    expect(content).toContain('accessibilityHint');
  });
});
