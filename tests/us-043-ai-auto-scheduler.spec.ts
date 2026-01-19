import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const OSCARS_TRACKER_PATH = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker');

test.describe('US-043: AI-Powered Auto Scheduler (Match Web)', () => {
  test('AutoSchedulerSheet.swift exists in WatchPlan folder', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    expect(fs.existsSync(filePath)).toBeTruthy();
  });

  test('AutoSchedulerSheet has text input field for natural language prompts', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for text input/prompt field
    expect(content).toContain('userPrompt');
    expect(content).toContain('TextEditor');
    expect(content).toContain('promptInput');

    // Check for placeholder text with examples
    expect(content).toContain("Plan my weekends");
    expect(content).toContain("I missed yesterday, fix it");
  });

  test('AutoSchedulerSheet has quick action buttons', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for QuickAction enum
    expect(content).toContain('enum QuickAction');
    expect(content).toContain('case fillGaps');
    expect(content).toContain('case rescheduleOverdue');
    expect(content).toContain('case reorganizePlan');

    // Check for quick action button display names
    expect(content).toContain('"Fill Gaps"');
    expect(content).toContain('"Reschedule Overdue"');
    expect(content).toContain('"Reorganize Plan"');

    // Check for quick actions section
    expect(content).toContain('quickActionsSection');
    expect(content).toContain('Quick Actions');
  });

  test('AutoSchedulerSheet has Generate Plan button', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for Generate Plan button
    expect(content).toContain('Generate Plan');
    expect(content).toContain('generateWithPrompt');

    // Check for sparkles icon (AI indicator)
    expect(content).toContain('sparkles');
  });

  test('WatchPlanViewModel has callAutoScheduler function for Supabase Edge Function', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'WatchPlanViewModel.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for auto scheduler function
    expect(content).toContain('func callAutoScheduler');
    expect(content).toContain('userPrompt: String');
    expect(content).toContain('moviesPool: [Movie]');
    expect(content).toContain('existingSchedule: [WatchPlanItem]');

    // Check for edge function call
    expect(content).toContain('supabase.functions');
    expect(content).toContain('"auto-scheduler"');
    expect(content).toContain('FunctionInvokeOptions');
  });

  test('Edge function request includes required parameters', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'WatchPlanViewModel.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for request body with required fields
    expect(content).toContain('"user_prompt"');
    expect(content).toContain('"today"');
    expect(content).toContain('"movies_pool"');
    expect(content).toContain('"existing_schedule"');
  });

  test('AutoSchedulerResponse handles plan array with movie_id, date, and reason', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'WatchPlanViewModel.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for response structure
    expect(content).toContain('struct AutoSchedulerResponse');
    expect(content).toContain('let plan: [ScheduledItem]');

    // Check for ScheduledItem structure
    expect(content).toContain('struct ScheduledItem');
    expect(content).toContain('let movieId: Int');
    expect(content).toContain('let date: String');
    expect(content).toContain('let reason: String?');

    // Check for CodingKeys mapping
    expect(content).toContain('case movieId = "movie_id"');
  });

  test('Preview shows suggested schedule with AI reasons', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for preview section
    expect(content).toContain('previewSection');
    expect(content).toContain('AI Suggested Schedule');

    // Check for reason display in preview rows
    expect(content).toContain('reason: String?');
    expect(content).toContain('if let reason = reason');

    // Check for AI sparkles indicator with reason
    expect(content).toMatch(/sparkles[\s\S]*reason/);
  });

  test('AutoSchedulerSheet stores schedule with reasons', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for schedule state with reason
    expect(content).toContain('suggestedSchedule: [(movie: Movie, date: Date, reason: String?)]');
  });

  test('Quick action buttons trigger AI generation', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check that quick actions call generateWithPrompt
    expect(content).toContain('quickActionButton');
    expect(content).toContain('generateWithPrompt(action.prompt)');

    // Check for prompt property on QuickAction
    expect(content).toContain('var prompt: String');
  });

  test('AutoSchedulerSheet has loading state for AI generation', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for generating state
    expect(content).toContain('isGenerating');
    expect(content).toContain('ProgressView');

    // Check for disabled state during generation
    expect(content).toContain('.disabled(');
    expect(content).toContain('isGenerating');
  });

  test('AutoSchedulerSheet shows stats summary', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for stats summary
    expect(content).toContain('statsSummary');
    expect(content).toContain('Unwatched');
    expect(content).toContain('Scheduled');
    expect(content).toContain('Overdue');
  });

  test('AutoSchedulerSheet has proper accessibility', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for accessibility labels
    expect(content).toContain('.accessibilityLabel');
    expect(content).toContain('.accessibilityHint');
  });

  test('AutoSchedulerSheet uses haptic feedback', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for haptic feedback
    expect(content).toContain('HapticManager.selection');
    expect(content).toContain('HapticManager.success');
    expect(content).toContain('HapticManager.error');
  });

  test('AutoSchedulerSheet handles empty preview state', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for empty state handling
    expect(content).toContain('emptyPreviewState');
    expect(content).toContain('No schedule generated');
    expect(content).toContain('suggestedSchedule.isEmpty');
  });

  test('AutoSchedulerSheet has AI header with icon', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for AI header
    expect(content).toContain('aiHeader');
    expect(content).toContain('AI-Powered Scheduler');
    expect(content).toContain('wand.and.stars');
  });

  test('AutoSchedulerSheet navigation title reflects AI', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AutoSchedulerSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for navigation titles
    expect(content).toContain('"AI Schedule Preview"');
    expect(content).toContain('"AI Scheduler"');
  });

  test('AutoSchedulerSheet is registered in project.pbxproj', async () => {
    const pbxprojPath = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const content = fs.readFileSync(pbxprojPath, 'utf-8');

    // Check for file references
    expect(content).toContain('AutoSchedulerSheet.swift');
    expect(content).toContain('AutoSchedulerSheet.swift in Sources');
  });
});
