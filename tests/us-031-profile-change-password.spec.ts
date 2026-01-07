import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

/**
 * US-031: Profile - Change Password
 *
 * Acceptance Criteria:
 * - Change Password row opens sheet
 * - Current password field
 * - New password field with confirmation
 * - Password strength requirements
 * - Supabase auth update on submit
 * - Success/error feedback
 */

const projectRoot = path.join(__dirname, '..');
const profileViewPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/Views/Profile/ProfileView.swift');
const profileViewModelPath = path.join(projectRoot, 'OscarsTracker/OscarsTracker/ViewModels/ProfileViewModel.swift');

test.describe('US-031: Profile - Change Password', () => {
  test('ProfileView exists', async () => {
    expect(fs.existsSync(profileViewPath)).toBe(true);
  });

  test('ProfileViewModel exists', async () => {
    expect(fs.existsSync(profileViewModelPath)).toBe(true);
  });

  test('ProfileView has Change Password button', async () => {
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check for Change Password button
    expect(content).toContain('Change Password');
    expect(content).toContain('key.fill');
    expect(content).toContain('openChangePasswordSheet');
  });

  test('ProfileView has sheet for Change Password', async () => {
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check for sheet presentation
    expect(content).toContain('.sheet(isPresented: $viewModel.showChangePasswordSheet)');
    expect(content).toContain('ChangePasswordSheet');
  });

  test('ChangePasswordSheet has current password field', async () => {
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check for current password field
    expect(content).toContain('Current Password');
    expect(content).toContain('currentPassword');
    expect(content).toContain('SecureField');
    expect(content).toContain('.textContentType(.password)');
  });

  test('ChangePasswordSheet has new password field with strength indicator', async () => {
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check for new password field
    expect(content).toContain('New Password');
    expect(content).toContain('newPassword');
    expect(content).toContain('.textContentType(.newPassword)');

    // Check for password strength indicator
    expect(content).toContain('ChangePasswordStrengthView');
    expect(content).toContain('newPasswordStrength');
  });

  test('ChangePasswordSheet has confirm password field with match indicator', async () => {
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check for confirm password field
    expect(content).toContain('Confirm New Password');
    expect(content).toContain('confirmNewPassword');

    // Check for password match indicator
    expect(content).toContain('passwordsMatch');
    expect(content).toContain('Passwords match');
    expect(content).toContain('Passwords do not match');
  });

  test('ChangePasswordSheet has password requirements view', async () => {
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check for password requirements
    expect(content).toContain('ChangePasswordRequirementsView');
    expect(content).toContain('Password requirements:');
    expect(content).toContain('At least 8 characters');
    expect(content).toContain('One uppercase letter');
    expect(content).toContain('One lowercase letter');
    expect(content).toContain('One number');
  });

  test('ChangePasswordSheet has submit button with loading state', async () => {
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check for submit button
    expect(content).toContain('changePassword()');
    expect(content).toContain('isChangingPassword');
    expect(content).toContain('Changing Password...');
    expect(content).toContain('isChangePasswordFormValid');
  });

  test('ChangePasswordSheet has error message display', async () => {
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check for error display
    expect(content).toContain('errorMessage');
    expect(content).toContain('exclamationmark.triangle.fill');
    expect(content).toContain('Color.destructive');
  });

  test('ChangePasswordSheet has cancel button', async () => {
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check for cancel button
    expect(content).toContain('Button("Cancel")');
    expect(content).toContain('cancelChangePassword');
    expect(content).toContain('.navigationBarLeading');
  });

  test('ProfileViewModel has change password state properties', async () => {
    const content = fs.readFileSync(profileViewModelPath, 'utf-8');

    // Check for state properties
    expect(content).toContain('@Published var showChangePasswordSheet');
    expect(content).toContain('@Published var currentPassword');
    expect(content).toContain('@Published var newPassword');
    expect(content).toContain('@Published var confirmNewPassword');
    expect(content).toContain('@Published var isChangingPassword');
    expect(content).toContain('@Published var changePasswordSuccessMessage');
  });

  test('ProfileViewModel has password validation computed properties', async () => {
    const content = fs.readFileSync(profileViewModelPath, 'utf-8');

    // Check for validation properties
    expect(content).toContain('var isNewPasswordLengthValid: Bool');
    expect(content).toContain('var newPasswordHasUppercase: Bool');
    expect(content).toContain('var newPasswordHasLowercase: Bool');
    expect(content).toContain('var newPasswordHasNumber: Bool');
    expect(content).toContain('var passwordsMatch: Bool');
    expect(content).toContain('var isNewPasswordValid: Bool');
    expect(content).toContain('var isChangePasswordFormValid: Bool');
  });

  test('ProfileViewModel has password strength calculation', async () => {
    const content = fs.readFileSync(profileViewModelPath, 'utf-8');

    // Check for password strength
    expect(content).toContain('var newPasswordStrength: PasswordStrength');
    expect(content).toContain('.weak');
    expect(content).toContain('.medium');
    expect(content).toContain('.strong');
  });

  test('ProfileViewModel has openChangePasswordSheet function', async () => {
    const content = fs.readFileSync(profileViewModelPath, 'utf-8');

    // Check for function
    expect(content).toContain('func openChangePasswordSheet()');
    expect(content).toContain('showChangePasswordSheet = true');
  });

  test('ProfileViewModel has cancelChangePassword function', async () => {
    const content = fs.readFileSync(profileViewModelPath, 'utf-8');

    // Check for function
    expect(content).toContain('func cancelChangePassword()');
    expect(content).toContain('showChangePasswordSheet = false');
  });

  test('ProfileViewModel has changePassword async function', async () => {
    const content = fs.readFileSync(profileViewModelPath, 'utf-8');

    // Check for async function
    expect(content).toContain('func changePassword() async');
    expect(content).toContain('isChangePasswordFormValid');
    expect(content).toContain('isChangingPassword = true');
  });

  test('ProfileViewModel verifies current password before changing', async () => {
    const content = fs.readFileSync(profileViewModelPath, 'utf-8');

    // Check for current password verification
    expect(content).toContain('supabase.auth.signIn');
    expect(content).toContain('currentPassword');
    expect(content).toContain('Current password is incorrect');
  });

  test('ProfileViewModel calls Supabase auth update for password change', async () => {
    const content = fs.readFileSync(profileViewModelPath, 'utf-8');

    // Check for Supabase update call
    expect(content).toContain('supabase.auth.update');
    expect(content).toContain('UserAttributes');
    expect(content).toContain('password: newPassword');
  });

  test('ProfileViewModel has success feedback after password change', async () => {
    const content = fs.readFileSync(profileViewModelPath, 'utf-8');

    // Check for success feedback
    expect(content).toContain('changePasswordSuccessMessage');
    expect(content).toContain('Password changed successfully');
    expect(content).toContain('HapticManager.success()');
  });

  test('ProfileViewModel has error mapping for password change', async () => {
    const content = fs.readFileSync(profileViewModelPath, 'utf-8');

    // Check for error mapping function
    expect(content).toContain('mapChangePasswordError');
    expect(content).toContain('HapticManager.error()');
  });

  test('ProfileView shows success message after password change', async () => {
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check for success message display
    expect(content).toContain('changePasswordSuccessMessage');
    expect(content).toContain('checkmark.circle.fill');
    expect(content).toContain('Color.success');
  });

  test('ChangePasswordSheet has focus management', async () => {
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check for FocusState
    expect(content).toContain('@FocusState');
    expect(content).toContain('focusedField');
    expect(content).toContain('.focused($focusedField');
    expect(content).toContain('.submitLabel');
    expect(content).toContain('.onSubmit');
  });

  test('ChangePasswordSheet prevents dismiss during submission', async () => {
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check for interactive dismiss disabled
    expect(content).toContain('.interactiveDismissDisabled(viewModel.isChangingPassword)');
  });

  test('ChangePasswordSheet clears error on field changes', async () => {
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check for onChange handlers that clear errors
    expect(content).toContain('.onChange(of: viewModel.currentPassword)');
    expect(content).toContain('.onChange(of: viewModel.newPassword)');
    expect(content).toContain('.onChange(of: viewModel.confirmNewPassword)');
    expect(content).toContain('viewModel.errorMessage = nil');
  });

  test('ChangePasswordSheet has accessibility labels', async () => {
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('.accessibilityLabel("Current password")');
    expect(content).toContain('.accessibilityLabel("New password")');
    expect(content).toContain('.accessibilityLabel("Confirm new password")');
    expect(content).toContain('.accessibilityLabel("Change password")');
  });

  test('Change Password button has accessibility', async () => {
    const content = fs.readFileSync(profileViewPath, 'utf-8');

    // Check for button accessibility
    expect(content).toContain('.accessibilityLabel("Change your password")');
    expect(content).toContain('.accessibilityHint("Tap to change your account password")');
  });
});
