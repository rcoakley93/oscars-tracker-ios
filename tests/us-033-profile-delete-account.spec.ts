import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-033: Profile - Delete Account', () => {
  test('ProfileView has delete account button', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for delete account button
    expect(content).toContain('Delete Account');
    expect(content).toContain('trash.fill');
  });

  test('Delete account button in account section', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for account section contains delete button
    const accountSectionMatch = content.match(/accountSection[\s\S]*?Delete Account/);
    expect(accountSectionMatch).not.toBeNull();
  });

  test('Delete account button uses destructive red styling', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for destructive button style
    expect(content).toContain('.buttonStyle(DestructiveButtonStyle())');
  });

  test('Delete account confirmation dialog exists', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for confirmation dialog
    expect(content).toContain('showDeleteAccountConfirmation');
    expect(content).toContain('.alert');
  });

  test('Confirmation dialog has warning text', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for warning text about permanent deletion
    expect(content).toContain('cannot be undone');
    expect(content).toContain('permanently deleted');
  });

  test('Confirmation dialog has cancel and delete buttons', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for dialog buttons
    expect(content).toContain('Button("Cancel", role: .cancel)');
    expect(content).toContain('Button("Delete Account", role: .destructive)');
  });

  test('ProfileViewModel has deleteAccount function', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for deleteAccount function
    expect(content).toContain('func deleteAccount()');
    expect(content).toContain('async');
  });

  test('Delete account calls delete_user RPC', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for Supabase RPC call
    expect(content).toContain('rpc("delete_user")');
  });

  test('Delete account signs out after deletion', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check that signOut is called after RPC in deleteAccount function
    const deleteMatch = content.match(/func deleteAccount[\s\S]*?rpc\("delete_user"\)[\s\S]*?signOut\(\)/);
    expect(deleteMatch).not.toBeNull();
  });

  test('Delete account clears local state', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check that deleteAccount clears local state
    const deleteMatch = content.match(/func deleteAccount[\s\S]*?profile = nil[\s\S]*?watchedCount = 0[\s\S]*?predictionsMade = 0[\s\S]*?correctPredictions = 0/);
    expect(deleteMatch).not.toBeNull();
  });

  test('Delete account handles errors', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for error handling in deleteAccount
    expect(content).toContain('mapDeleteAccountError');
    expect(content).toContain('Failed to delete account');
  });

  test('Delete account has loading state', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for isDeletingAccount state
    expect(content).toContain('isDeletingAccount');
    expect(content).toContain('@Published var isDeletingAccount');
  });

  test('Delete button shows loading indicator', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for loading state in button
    expect(content).toContain('viewModel.isDeletingAccount');
    expect(content).toContain('ProgressView()');
    expect(content).toContain('Deleting...');
  });

  test('Delete button disabled during deletion', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for disabled state
    expect(content).toContain('.disabled(viewModel.isDeletingAccount)');
  });

  test('Delete account button has accessibility labels', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('accessibilityLabel("Delete your account")');
    expect(content).toContain('accessibilityHint');
    expect(content).toContain('permanently delete');
  });

  test('Delete account uses haptic feedback', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for haptic feedback in deleteAccount function
    const deleteMatch = content.match(/func deleteAccount[\s\S]*?HapticManager\.(success|error)/);
    expect(deleteMatch).not.toBeNull();
  });

  test('DestructiveButtonStyle exists with red color', async () => {
    const buttonStylePath = path.join(OSCARS_TRACKER_PATH, 'Components', 'GoldButtonStyle.swift');
    const content = fs.readFileSync(buttonStylePath, 'utf-8');

    // Check for destructive button style
    expect(content).toContain('struct DestructiveButtonStyle');
    expect(content).toContain('Color.destructive');
  });
});
