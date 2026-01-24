import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-026: Groups - View My Groups', () => {
  test('GroupsView exists with proper structure', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    expect(fs.existsSync(groupsViewPath)).toBe(true);

    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for SwiftUI import and struct
    expect(content).toContain('import SwiftUI');
    expect(content).toContain('struct GroupsView');
    expect(content).toContain('View');
  });

  test('GroupsView has My Groups section', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for My Groups section
    expect(content).toContain('My Groups');
    expect(content).toContain('myGroups');
    expect(content).toContain('viewModel.myGroups');
  });

  test('GroupsView has Joined Groups section', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for Joined Groups section
    expect(content).toContain('Joined Groups');
    expect(content).toContain('joinedGroups');
    expect(content).toContain('viewModel.joinedGroups');
  });

  test('GroupCard component exists with required properties', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for GroupCard struct
    expect(content).toContain('struct GroupCard');
    expect(content).toContain('let group: GroupWithMemberCount');
  });

  test('GroupCard displays group name', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for group name display
    expect(content).toContain('group.name');
    expect(content).toContain('Text(group.name)');
  });

  test('GroupCard displays invite code', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for invite code display
    expect(content).toContain('inviteCode');
    expect(content).toContain('group.inviteCode');
    expect(content).toContain('monospaced');
  });

  test('GroupCard displays member count', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for member count display
    expect(content).toContain('memberCount');
    expect(content).toContain('members');
    expect(content).toContain('person.2.fill');
  });

  test('Copy button copies invite code to clipboard', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for copy functionality
    expect(content).toContain('onCopyCode');
    expect(content).toContain('doc.on.doc');
    expect(content).toContain('Copy invite code');
  });

  test('GroupsViewModel has copy to clipboard function', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for clipboard functionality
    expect(content).toContain('import UIKit');
    expect(content).toContain('func copyInviteCode');
    expect(content).toContain('UIPasteboard');
    expect(content).toContain('general.string');
  });

  test('Tap group navigates to group leaderboard', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for navigation to leaderboard
    expect(content).toContain('NavigationLink');
    expect(content).toContain('GroupLeaderboardView');
    expect(content).toContain('group:');
  });

  test('GroupLeaderboardView exists', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for GroupLeaderboardView
    expect(content).toContain('struct GroupLeaderboardView');
    expect(content).toContain('let group: GroupWithMemberCount');
  });

  test('GroupsViewModel exists with proper structure', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    expect(fs.existsSync(viewModelPath)).toBe(true);

    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for ViewModel
    expect(content).toContain('import Foundation');
    expect(content).toContain('import Supabase');
    expect(content).toContain('class GroupsViewModel');
    expect(content).toContain('ObservableObject');
  });

  test('GroupWithMemberCount struct exists', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for GroupWithMemberCount struct
    expect(content).toContain('struct GroupWithMemberCount');
    expect(content).toContain('Identifiable');
    expect(content).toContain('let id: Int');
    expect(content).toContain('let name: String');
    expect(content).toContain('let inviteCode: String');
    expect(content).toContain('let memberCount: Int');
  });

  test('GroupsViewModel has myGroups and joinedGroups properties', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for published properties
    expect(content).toContain('@Published var myGroups');
    expect(content).toContain('@Published var joinedGroups');
    expect(content).toContain('[GroupWithMemberCount]');
  });

  test('GroupsViewModel loads data from Supabase', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for Supabase data loading
    expect(content).toContain('func loadData');
    expect(content).toContain('SupabaseClientManager');
    expect(content).toContain('from("groups")');
  });

  test('GroupsViewModel identifies owner groups by created_by', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'GroupsViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for owner identification
    expect(content).toContain('createdBy');
    expect(content).toContain('isOwner');
  });

  test('GroupCard shows Owner badge for owned groups', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for Owner badge
    expect(content).toContain('isOwner');
    expect(content).toContain('Owner');
    expect(content).toContain('group.isOwner');
  });

  test('GroupsView has loading state', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for loading state
    expect(content).toContain('isLoading');
    expect(content).toContain('ProgressView');
    expect(content).toContain('Loading groups');
  });

  test('GroupsView has empty state', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for empty state
    expect(content).toContain('emptyStateView');
    expect(content).toContain('No groups yet');
    expect(content).toContain('person.3.fill');
  });

  test('GroupsView has pull-to-refresh', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for refresh
    expect(content).toContain('.refreshable');
    expect(content).toContain('viewModel.loadData()');
  });

  test('GroupsView has NavigationStack', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for NavigationStack
    expect(content).toContain('NavigationStack');
    expect(content).toContain('.navigationTitle');
    expect(content).toContain('Groups');
  });

  test('Files are registered in Xcode project', async () => {
    const pbxprojPath = path.join(XCODE_PROJECT_PATH, 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const pbxprojContent = fs.readFileSync(pbxprojPath, 'utf-8');

    // Check GroupsView and GroupsViewModel are in the project
    expect(pbxprojContent).toContain('GroupsView.swift');
    expect(pbxprojContent).toContain('GroupsViewModel.swift');
  });

  test('Accessibility support for GroupCard', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('accessibilityElement');
    expect(content).toContain('accessibilityLabel');
    expect(content).toContain('accessibilityHint');
  });

  test('GroupCard has glassCard styling', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for glassCard modifier
    expect(content).toContain('.glassCard()');
  });

  test('Section headers show count badge', async () => {
    const groupsViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Groups', 'GroupsView.swift');
    const content = fs.readFileSync(groupsViewPath, 'utf-8');

    // Check for count in section header
    expect(content).toContain('sectionHeader');
    expect(content).toContain('count');
    expect(content).toContain('goldPrimary');
  });

  test('ContentView uses GroupsView', async () => {
    const contentViewPath = path.join(OSCARS_TRACKER_PATH, 'App', 'ContentView.swift');
    const content = fs.readFileSync(contentViewPath, 'utf-8');

    // Check GroupsView is used
    expect(content).toContain('GroupsView()');
  });
});
