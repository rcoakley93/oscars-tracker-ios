import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-027: Groups - Create Group', () => {
  test('Create button in navigation bar', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for toolbar with plus button
    expect(content).toContain('.toolbar');
    expect(content).toContain('ToolbarItem');
    expect(content).toContain('navigationBarTrailing');
    expect(content).toContain('plus');
    expect(content).toContain('Create group');
  });

  test('Create button shows create sheet', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check sheet binding
    expect(content).toContain('showCreateSheet');
    expect(content).toContain('.sheet(isPresented:');
    expect(content).toContain('CreateGroupSheet');
  });

  test('CreateGroupSheet exists with name input', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for CreateGroupSheet struct
    expect(content).toContain('struct CreateGroupSheet');
    expect(content).toContain('TextField');
    expect(content).toContain('newGroupName');
    expect(content).toContain('Group Name');
  });

  test('CreateGroupSheet has Cancel button', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for cancel functionality
    expect(content).toContain('Cancel');
    expect(content).toContain('navigationBarLeading');
    expect(content).toContain('resetCreateForm');
    expect(content).toContain('dismiss');
  });

  test('CreateGroupSheet has Create button', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for create button
    expect(content).toContain('Create Group');
    expect(content).toContain('createGroup');
    expect(content).toContain('.buttonStyle(.gold)');
  });

  test('Group name length validation (3-30 chars)', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for length validation
    expect(content).toContain('isNameLengthValid');
    expect(content).toContain('newGroupName.count >= 3');
    expect(content).toContain('newGroupName.count <= 30');
    expect(content).toContain('3-30 characters');
  });

  test('Group name profanity filter', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for profanity filter
    expect(content).toContain('profanityList');
    expect(content).toContain('nameContainsProfanity');
    expect(content).toContain('lowercased');
    expect(content).toContain('inappropriate content');
  });

  test('Group name validation combined check', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for combined validation
    expect(content).toContain('isGroupNameValid');
    expect(content).toContain('isNameLengthValid');
    expect(content).toContain('nameContainsProfanity');
    expect(content).toContain('validateGroupName');
  });

  test('Validation feedback in UI', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for validation UI
    expect(content).toContain('validationRow');
    expect(content).toContain('isNameLengthValid');
    expect(content).toContain('nameContainsProfanity');
    expect(content).toContain('checkmark.circle.fill');
  });

  test('Creates group in groups table', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for group creation
    expect(content).toContain('func createGroup');
    expect(content).toContain('from("groups")');
    expect(content).toContain('.insert');
    expect(content).toContain('newGroupData');
  });

  test('Auto-generates invite code', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for invite code generation
    expect(content).toContain('generateInviteCode');
    expect(content).toContain('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789');
    expect(content).toContain('randomElement');
    expect(content).toContain('invite_code');
  });

  test('Creator automatically added as member', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for member insertion
    expect(content).toContain('from("group_members")');
    expect(content).toContain('memberData');
    expect(content).toContain('group_id');
    expect(content).toContain('user_id');
  });

  test('New group appears in My Groups after creation', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for reload after creation
    expect(content).toContain('await loadData()');
    expect(content).toContain('showCreateSheet = false');
  });

  test('Loading state during creation', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for loading state
    expect(content).toContain('isCreating');
    expect(content).toContain('isCreating = true');
    expect(content).toContain('isCreating = false');
  });

  test('Loading indicator in UI', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for loading UI
    expect(content).toContain('isCreating');
    expect(content).toContain('ProgressView');
    expect(content).toContain('Creating...');
  });

  test('Button disabled during creation and when invalid', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for disabled state
    expect(content).toContain('.disabled');
    expect(content).toContain('isGroupNameValid');
    expect(content).toContain('isCreating');
  });

  test('Error handling for failed creation', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for error handling
    expect(content).toContain('catch');
    expect(content).toContain('errorMessage');
    expect(content).toContain('Failed to create group');
    expect(content).toContain('HapticManager.error');
  });

  test('Error message display in sheet', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for error display
    expect(content).toContain('errorMessage');
    expect(content).toContain('destructive');
  });

  test('Success haptic on creation', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for success haptic
    expect(content).toContain('HapticManager.success()');
  });

  test('Reset form function exists', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for reset form
    expect(content).toContain('func resetCreateForm');
    expect(content).toContain('newGroupName = ""');
  });

  test('Interactive dismiss disabled during creation', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for dismiss prevention
    expect(content).toContain('.interactiveDismissDisabled');
    expect(content).toContain('isCreating');
  });

  test('Text field auto-focus on appear', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for auto-focus
    expect(content).toContain('@FocusState');
    expect(content).toContain('isNameFocused');
    expect(content).toContain('.focused($isNameFocused)');
    expect(content).toContain('isNameFocused = true');
  });

  test('Accessibility labels for input field', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('accessibilityLabel');
    expect(content).toContain('accessibilityHint');
    expect(content).toContain('Enter a name for your new group');
  });

  test('ViewModel showCreateSheet binding', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for sheet state
    expect(content).toContain('@Published var showCreateSheet');
    expect(content).toContain('@Published var newGroupName');
  });
});
