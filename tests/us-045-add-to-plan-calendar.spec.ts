import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const OSCARS_TRACKER_PATH = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker');

test.describe('US-045: Redesign Add to Plan Calendar UX', () => {
  test('AddToPlanSheet.swift exists in WatchPlan folder', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    expect(fs.existsSync(filePath)).toBeTruthy();
  });

  test('Flow shows movie list first, then calendar on selection', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for showCalendar state for two-view flow
    expect(content).toContain('showCalendar');
    expect(content).toContain('moviePickerSection');
    expect(content).toContain('calendarSection');

    // Check for conditional view rendering
    expect(content).toContain('if showCalendar');
  });

  test('Tapping movie transitions to calendar', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for calendar transition on movie selection
    expect(content).toContain('showCalendar = true');
    expect(content).toContain('selectedMovie = movie');
  });

  test('Has white dot indicators for dates with scheduled movies', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for scheduled dates tracking
    expect(content).toContain('scheduledDates');
    expect(content).toContain('hasScheduledMovies');

    // Check for dot indicator rendering
    expect(content).toContain('Circle()');
    expect(content).toContain('.fill(');
    expect(content).toContain('frame(width: 6, height: 6)');
  });

  test('Has distinct styling for selected date', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for selected date styling
    expect(content).toContain('isSelected');
    expect(content).toContain('goldPrimary');

    // Check for selected date circle background
    expect(content).toContain('if isSelected');
    expect(content).toMatch(/Circle\(\)[\s\S]*?\.fill\(Color\.goldPrimary\)/);
  });

  test('Has distinct styling for today date', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for today styling
    expect(content).toContain('isToday');
    expect(content).toContain('isDateInToday');

    // Check for today stroke styling
    expect(content).toContain('.stroke(Color.goldPrimary');
  });

  test('Shows popover with scheduled movies when tapping a date with movies', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for popover state
    expect(content).toContain('showScheduledMoviesPopover');
    expect(content).toContain('popoverDate');

    // Check for popover presentation
    expect(content).toContain('.popover(isPresented:');
    expect(content).toContain('scheduledMoviesPopover');

    // Check for popover content
    expect(content).toContain('Scheduled for');
    expect(content).toContain('moviesForDate');
  });

  test('Compact calendar uses custom grid instead of DatePicker graphical', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for custom compact calendar (not graphical DatePicker)
    expect(content).toContain('compactCalendarView');
    expect(content).toContain('LazyVGrid');
    expect(content).toContain('daysInMonth');

    // Should NOT use graphical DatePicker
    expect(content).not.toContain('.datePickerStyle(.graphical)');
  });

  test('Compact calendar has month navigation', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for month navigation
    expect(content).toContain('currentMonth');
    expect(content).toContain('chevron.left');
    expect(content).toContain('chevron.right');
    expect(content).toContain('monthYearString');
  });

  test('Compact calendar has day of week headers', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for day headers
    expect(content).toContain('"S", "M", "T", "W", "T", "F", "S"');
  });

  test('Calendar disables past dates', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for past date handling
    expect(content).toContain('isPast');
    expect(content).toContain('.disabled(isPast)');
  });

  test('Has back navigation from calendar to movie list', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for back navigation
    expect(content).toContain('showCalendar ? "Back" : "Cancel"');
    expect(content).toContain('showCalendar = false');
  });

  test('Selected movie header shown in calendar view', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for selected movie header
    expect(content).toContain('selectedMovieHeader');
    expect(content).toContain('if let movie = selectedMovie');
  });

  test('Add button shows selected date', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for add button with date display
    expect(content).toContain('Add to Plan for');
    expect(content).toContain('formattedShortDate');
  });

  test('Has proper accessibility labels', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('.accessibilityLabel');
    expect(content).toContain('.accessibilityHint');
    expect(content).toContain('has');
    expect(content).toContain('scheduled movies');
  });

  test('Uses haptic feedback', async () => {
    const filePath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'AddToPlanSheet.swift');
    const content = fs.readFileSync(filePath, 'utf-8');

    // Check for haptic feedback
    expect(content).toContain('HapticManager.selection');
    expect(content).toContain('HapticManager.success');
    expect(content).toContain('HapticManager.error');
    expect(content).toContain('HapticManager.light');
  });

  test('AddToPlanSheet is registered in project.pbxproj', async () => {
    const pbxprojPath = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const content = fs.readFileSync(pbxprojPath, 'utf-8');

    // Check for file references
    expect(content).toContain('AddToPlanSheet.swift');
    expect(content).toContain('AddToPlanSheet.swift in Sources');
  });
});
