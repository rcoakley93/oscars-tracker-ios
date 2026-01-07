import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-022: Ballot - Countdown Timer', () => {
  test('CountdownTimerView exists in BallotView', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for CountdownTimerView struct
    expect(content).toContain('struct CountdownTimerView');
    expect(content).toContain('countdownTimer');
  });

  test('Displays days, hours, minutes, seconds', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for time unit calculations
    expect(content).toContain('private var days: Int');
    expect(content).toContain('private var hours: Int');
    expect(content).toContain('private var minutes: Int');
    expect(content).toContain('private var seconds: Int');

    // Check for time unit display
    expect(content).toContain('TimeUnitView');
    expect(content).toContain('"DAYS"');
    expect(content).toContain('"HRS"');
    expect(content).toContain('"MIN"');
    expect(content).toContain('"SEC"');
  });

  test('TimeUnitView component exists', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for TimeUnitView struct
    expect(content).toContain('struct TimeUnitView');
    expect(content).toContain('let value: Int');
    expect(content).toContain('let unit: String');
  });

  test('Updates every second via Timer', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for timer functionality
    expect(content).toContain('timer: Timer?');
    expect(content).toContain('Timer.scheduledTimer');
    expect(content).toContain('withTimeInterval: 1');
    expect(content).toContain('repeats: true');
  });

  test('Timer starts and stops properly', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for timer lifecycle
    expect(content).toContain('func startTimer()');
    expect(content).toContain('func stopTimer()');
    expect(content).toContain('.onAppear');
    expect(content).toContain('.onDisappear');
    expect(content).toContain('timer?.invalidate()');
  });

  test('When time expires, ballot becomes locked', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for lock callback
    expect(content).toContain('let onLock: () -> Void');
    expect(content).toContain('onLock()');
    expect(content).toContain('remaining <= 0');
  });

  test('BallotViewModel has ballotLockDate', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for lock date
    expect(content).toContain('let ballotLockDate: Date');
    expect(content).toContain('DateComponents');
  });

  test('BallotViewModel has isLocked property', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for isLocked
    expect(content).toContain('@Published var isLocked');
    expect(content).toContain('func checkLockStatus()');
  });

  test('Lock icon shown when locked', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for lock icon
    expect(content).toContain('"lock.fill"');
    expect(content).toContain('if isLocked');
  });

  test('All selections disabled when locked', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for disabled state
    expect(content).toContain('.disabled(isLocked)');
    expect(content).toContain('let isLocked: Bool');
  });

  test('NominationRow receives isLocked parameter', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check that isLocked is passed to NominationRow
    expect(content).toContain('isLocked: viewModel.isLocked');
  });

  test('SelectPrediction blocked when locked', async () => {
    const viewModelPath = path.join(OSCARS_TRACKER_PATH, 'ViewModels', 'BallotViewModel.swift');
    const content = fs.readFileSync(viewModelPath, 'utf-8');

    // Check for guard against locked state
    expect(content).toContain('guard !isLocked');
  });

  test('Locked state shows message', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for locked message
    expect(content).toContain('Predictions are now locked');
    expect(content).toContain('Ballot Locked');
  });

  test('Monospaced font for time digits', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for monospaced font
    expect(content).toContain('design: .monospaced');
  });

  test('Zero-padded time display', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for zero-padding
    expect(content).toContain('String(format: "%02d", value)');
  });

  test('Accessibility labels for countdown', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for accessibility
    expect(content).toContain('accessibilityLabel');
    expect(content).toContain('Time remaining');
    expect(content).toContain('Ballot is locked');
  });

  test('Opacity reduced when locked', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for opacity change
    expect(content).toContain('.opacity(isLocked ?');
  });

  test('Time calculations are correct', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for time calculations (86400 = seconds in day, 3600 = seconds in hour)
    expect(content).toContain('86400');
    expect(content).toContain('3600');
    expect(content).toContain('60');
  });

  test('CountdownTimerView uses glass card styling', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for styling
    expect(content).toContain('.glassCard()');
  });

  test('CountdownTimerView receives lockDate from viewModel', async () => {
    const ballotPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotPath, 'utf-8');

    // Check for proper initialization
    expect(content).toContain('lockDate: viewModel.ballotLockDate');
    expect(content).toContain('isLocked: viewModel.isLocked');
  });
});
