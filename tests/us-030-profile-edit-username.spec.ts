import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-030: Profile - Edit Username', () => {
  test('Edit button exists next to username', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for edit button with pencil icon
    expect(content).toContain('pencil.circle.fill');
    expect(content).toContain('Edit username');
    expect(content).toContain('startEditingUsername');
  });

  test('ViewModel has edit username state properties', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for editing state properties
    expect(content).toContain('@Published var isEditingUsername');
    expect(content).toContain('@Published var editedUsername');
    expect(content).toContain('@Published var isSavingUsername');
  });

  test('Inline editing view exists', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for edit view with text field
    expect(content).toContain('usernameEditView');
    expect(content).toContain('TextField("Username"');
    expect(content).toContain('$viewModel.editedUsername');
  });

  test('Start editing function initializes state', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for start editing function
    expect(content).toContain('func startEditingUsername()');
    expect(content).toContain('isEditingUsername = true');
    expect(content).toContain('editedUsername = profile?.username');
  });

  test('Cancel editing function exists', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for cancel function
    expect(content).toContain('func cancelEditingUsername()');
    expect(content).toContain('isEditingUsername = false');
  });

  test('Cancel button in edit view', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for cancel button
    expect(content).toContain('Button("Cancel")');
    expect(content).toContain('cancelEditingUsername');
  });

  test('Save button exists', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for save button
    expect(content).toContain('Text("Save")');
    expect(content).toContain('saveUsername()');
  });

  test('Save function updates Supabase profiles table', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for Supabase update
    expect(content).toContain('func saveUsername()');
    expect(content).toContain('.update(["username": editedUsername])');
    expect(content).toContain('"profiles"');
    expect(content).toContain('.eq("id"');
  });

  test('Username length validation (3-20 characters)', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for length validation
    expect(content).toContain('isUsernameLengthValid');
    expect(content).toContain('editedUsername.count >= 3');
    expect(content).toContain('editedUsername.count <= 20');
  });

  test('Username format validation (alphanumeric and underscores)', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for format validation with regex
    expect(content).toContain('isUsernameFormatValid');
    expect(content).toContain('[A-Za-z0-9_]');
    expect(content).toContain('.regularExpression');
  });

  test('Profanity filter exists', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for profanity filter
    expect(content).toContain('profanityList');
    expect(content).toContain('usernameContainsProfanity');
    expect(content).toContain('lowercased');
  });

  test('Combined username validation', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for combined validation
    expect(content).toContain('isEditedUsernameValid');
    expect(content).toContain('isUsernameLengthValid');
    expect(content).toContain('isUsernameFormatValid');
    expect(content).toContain('usernameContainsProfanity');
  });

  test('Validation indicators shown in UI', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for validation indicators
    expect(content).toContain('validationRow');
    expect(content).toContain('3-20 characters');
    expect(content).toContain('Letters, numbers, underscores');
    expect(content).toContain('checkmark.circle.fill');
  });

  test('Save button disabled for invalid username', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check that save is disabled when invalid
    expect(content).toContain('.disabled(!viewModel.isEditedUsernameValid');
  });

  test('Loading state during save', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for loading state
    expect(content).toContain('viewModel.isSavingUsername');
    expect(content).toContain('ProgressView()');
    expect(content).toContain('Saving...');
  });

  test('Success feedback after save', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const viewModelContent = fs.readFileSync(viewModelPath, 'utf-8');
    const viewContent = fs.readFileSync(profilePath, 'utf-8');

    // Check for success message
    expect(viewModelContent).toContain('usernameSuccessMessage');
    expect(viewModelContent).toContain('Username updated!');
    expect(viewModelContent).toContain('HapticManager.success()');
    expect(viewContent).toContain('usernameSuccessMessage');
    expect(viewContent).toContain('Color.success');
  });

  test('Error message displayed on validation failure', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for error display
    expect(content).toContain('viewModel.errorMessage');
    expect(content).toContain('Color.destructive');
  });

  test('Error haptic on save failure', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for error haptic
    expect(content).toContain('HapticManager.error()');
  });

  test('Local profile updated after save', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check that local profile is updated
    expect(content).toContain('updatedProfile.username = editedUsername');
    expect(content).toContain('profile = updatedProfile');
  });

  test('View toggles between display and edit modes', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for conditional view
    expect(content).toContain('if viewModel.isEditingUsername');
    expect(content).toContain('usernameEditView');
    expect(content).toContain('usernameDisplayView');
  });

  test('Text field has proper styling', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for text field styling
    expect(content).toContain('OscarsTextFieldStyle');
    expect(content).toContain('.textContentType(.username)');
    expect(content).toContain('.autocorrectionDisabled()');
  });

  test('Animation on mode switch', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for animation
    expect(content).toContain('.animation(.easeInOut');
    expect(content).toContain('value: viewModel.isEditingUsername');
  });

  test('Accessibility labels on edit controls', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('accessibilityLabel("Edit username")');
    expect(content).toContain('accessibilityLabel("Save username")');
    expect(content).toContain('accessibilityLabel("Cancel editing")');
  });

  test('FocusState for text field', async () => {
    const profilePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Profile', 'ProfileView.swift');
    const content = fs.readFileSync(profilePath, 'utf-8');

    // Check for focus state
    expect(content).toContain('@FocusState');
    expect(content).toContain('.focused($isUsernameFieldFocused)');
  });

  test('Success message clears after delay', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for delayed clear
    expect(content).toContain('Task.sleep');
    expect(content).toContain('usernameSuccessMessage = nil');
  });

  test('Validate username function returns error messages', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'ProfileViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for validation error messages
    expect(content).toContain('validateUsername()');
    expect(content).toContain('Please enter a username');
    expect(content).toContain('must be 3-20 characters');
    expect(content).toContain('letters, numbers, and underscores');
    expect(content).toContain('inappropriate content');
  });
});
