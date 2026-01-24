import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-028: Groups - Join Group', () => {
  test('Join button in navigation bar', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for toolbar with join button
    expect(content).toContain('navigationBarLeading');
    expect(content).toContain('person.badge.plus');
    expect(content).toContain('Join group');
  });

  test('Join button shows join sheet', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check sheet binding
    expect(content).toContain('showJoinSheet');
    expect(content).toContain('JoinGroupSheet');
  });

  test('JoinGroupSheet exists with TextField', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for JoinGroupSheet struct
    expect(content).toContain('struct JoinGroupSheet');
    expect(content).toContain('TextField');
    expect(content).toContain('inviteCodeInput');
    expect(content).toContain('Invite Code');
  });

  test('TextField has proper placeholder', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for placeholder
    expect(content).toContain('Enter 6-character code');
  });

  test('TextField auto-capitalizes input', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for auto-capitalization
    expect(content).toContain('.textInputAutocapitalization(.characters)');
    expect(content).toContain('uppercased');
  });

  test('TextField limits to 6 characters', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for character limit
    expect(content).toContain('.onChange');
    expect(content).toContain('count > 6');
    expect(content).toContain('prefix(6)');
  });

  test('Join button with gold style', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for join button
    expect(content).toContain('Join Group');
    expect(content).toContain('joinGroup');
    expect(content).toContain('.buttonStyle(.gold)');
  });

  test('Invite code validation (6 alphanumeric)', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for validation
    expect(content).toContain('isInviteCodeValid');
    expect(content).toContain('[A-Z0-9]{6}');
    expect(content).toContain('uppercased');
  });

  test('Validation feedback in UI', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for validation UI in JoinGroupSheet
    expect(content).toContain('isInviteCodeValid');
    expect(content).toContain('checkmark.circle.fill');
    expect(content).toContain('6 alphanumeric characters');
  });

  test('Join function looks up group by invite_code', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for group lookup
    expect(content).toContain('func joinGroup');
    expect(content).toContain('from("groups")');
    expect(content).toContain('.eq("invite_code"');
  });

  test('Error shown if group not found', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for not found error
    expect(content).toContain('No group found with that invite code');
  });

  test('Checks if user already a member', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for existing member check
    expect(content).toContain('existingMembers');
    expect(content).toContain('from("group_members")');
    expect(content).toContain('.eq("group_id"');
    expect(content).toContain('.eq("user_id"');
  });

  test('Error shown if already a member', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for already member error
    expect(content).toContain('already a member');
    expect(content).toContain('!existingMembers.isEmpty');
  });

  test('Adds user to group_members table', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for member insertion
    expect(content).toContain('from("group_members")');
    expect(content).toContain('.insert(memberData)');
    expect(content).toContain('group_id');
    expect(content).toContain('user_id');
  });

  test('Joined group appears in Joined Groups section', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for reload after join
    expect(content).toContain('await loadData()');
    expect(content).toContain('showJoinSheet = false');
  });

  test('Loading state during join', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for loading state
    expect(content).toContain('isJoining');
    expect(content).toContain('isJoining = true');
    expect(content).toContain('isJoining = false');
  });

  test('Loading indicator in UI', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for loading UI
    expect(content).toContain('isJoining');
    expect(content).toContain('ProgressView');
    expect(content).toContain('Joining...');
  });

  test('Button disabled when invalid or joining', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for disabled state
    expect(content).toContain('.disabled');
    expect(content).toContain('isInviteCodeValid');
    expect(content).toContain('isJoining');
  });

  test('Success haptic on successful join', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for success haptic
    expect(content).toContain('HapticManager.success()');
  });

  test('Error haptic on failed join', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for error haptic
    expect(content).toContain('HapticManager.error()');
  });

  test('Cancel button dismisses sheet', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for cancel in JoinGroupSheet
    expect(content).toContain('Cancel');
    expect(content).toContain('resetJoinForm');
    expect(content).toContain('dismiss');
  });

  test('Reset join form function', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for reset function
    expect(content).toContain('func resetJoinForm');
    expect(content).toContain('inviteCodeInput = ""');
  });

  test('Interactive dismiss disabled during join', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for dismiss prevention in JoinGroupSheet
    expect(content).toContain('.interactiveDismissDisabled');
    expect(content).toContain('isJoining');
  });

  test('Text field auto-focus on appear', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for auto-focus in JoinGroupSheet
    expect(content).toContain('@FocusState');
    expect(content).toContain('isCodeFocused');
    expect(content).toContain('.focused($isCodeFocused)');
    expect(content).toContain('isCodeFocused = true');
  });

  test('Accessibility labels for input', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('accessibilityLabel');
    expect(content).toContain('accessibilityHint');
    expect(content).toContain('6-character invite code');
  });

  test('ViewModel has join sheet state', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for state
    expect(content).toContain('@Published var showJoinSheet');
    expect(content).toContain('@Published var inviteCodeInput');
  });

  test('Error message display in sheet', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for error display in JoinGroupSheet
    expect(content).toContain('errorMessage');
    expect(content).toContain('destructive');
  });
});
