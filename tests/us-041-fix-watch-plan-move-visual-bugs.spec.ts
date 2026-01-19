import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-041: Fix Visual Bugs in Watch Plan Move Functionality', () => {
  test('Move modal/sheet opens without visual glitches - uses large detent', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check that RescheduleSheet uses .large detent for proper calendar display
    expect(content).toContain('.sheet(item: $itemToReschedule)');
    expect(content).toContain('.presentationDetents([.large])');
  });

  test('Calendar component is properly positioned and aligned', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for proper layout structure in RescheduleSheet
    expect(content).toContain('struct RescheduleSheet');
    expect(content).toContain('VStack(spacing: 0)');
    expect(content).toContain('.padding(.horizontal)');

    // Check for date picker section with proper spacing
    expect(content).toContain('Select New Date');
    expect(content).toContain('.datePickerStyle(.graphical)');
    expect(content).toContain('.padding(.horizontal, 8)');

    // Check for divider between sections
    expect(content).toContain('Divider()');
    expect(content).toContain('.padding(.vertical, 16)');
  });

  test('Transitions/animations are smooth when opening', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for appearance animation
    expect(content).toContain('isAppeared');
    expect(content).toContain('.onAppear');
    expect(content).toContain('withAnimation(.easeOut(duration: 0.3)');

    // Check for opacity and offset animation
    expect(content).toContain('.opacity(isAppeared ? 1 : 0)');
    expect(content).toContain('.offset(y: isAppeared ? 0 : 20)');
  });

  test('Transitions/animations are smooth when closing', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for small delay before dismiss for visual feedback
    expect(content).toContain('Task.sleep(nanoseconds: 200_000_000)');
    expect(content).toContain('onDismiss()');
  });

  test('No overlapping elements or misaligned components', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for proper spacing structure
    expect(content).toContain('movieHeader');
    expect(content).toContain('.padding(.horizontal)');
    expect(content).toContain('.padding(.top)');

    // Check for Spacer to push button to bottom
    expect(content).toContain('Spacer()');
    expect(content).toContain('rescheduleButton');
    expect(content).toContain('.padding()');
  });

  test('Interactive dismiss is disabled during reschedule operation', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for interactiveDismissDisabled
    expect(content).toContain('.interactiveDismissDisabled(isRescheduling)');

    // Check that cancel button is disabled during reschedule
    expect(content).toContain('.disabled(isRescheduling)');
  });

  test('iPad frame sizes accommodate graphical calendar', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for proper iPad frame constraints that fit calendar
    expect(content).toContain('minHeight: 550');
    expect(content).toContain('maxHeight: 700');
  });

  test('Movie header shows current date badge', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for current date badge showing where movie is moving from
    expect(content).toContain('currentDateBadge');
    expect(content).toContain('FROM');
    expect(content).toContain('formattedCurrentDate');
  });

  test('Movie header shows year in addition to runtime', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check that movieHeader shows year
    expect(content).toContain('movie?.releaseYear');
  });

  test('Reschedule button has calendar icon and loading state text', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for button with icon
    expect(content).toContain('Image(systemName: "calendar.badge.clock")');
    expect(content).toContain('Text("Move to Date")');

    // Check for loading state text
    expect(content).toContain('Text("Moving...")');
  });

  test('Navigation title is descriptive', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for descriptive navigation title
    expect(content).toContain('.navigationTitle("Move Movie")');
  });

  test('Accessibility hints are provided for reschedule button', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for accessibility support
    expect(content).toContain('.accessibilityLabel("Move movie to selected date")');
    expect(content).toContain('.accessibilityHint');
  });
});
