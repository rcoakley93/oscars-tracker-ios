import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-016: Watch Plan - Drag and Drop', () => {
  test('WatchPlanItemTransfer struct for drag data', async () => {
    const watchPlanViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');

    // Check for Transferable struct
    expect(content).toContain('struct WatchPlanItemTransfer');
    expect(content).toContain('Codable');
    expect(content).toContain('Transferable');
    expect(content).toContain('itemId');
    expect(content).toContain('movieId');
  });

  test('Custom UTType for watch plan items', async () => {
    const watchPlanViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');

    // Check for UTType extension
    expect(content).toContain('extension UTType');
    expect(content).toContain('watchPlanItem');
    expect(content).toContain('UTType(exportedAs:');
  });

  test('DraggableWatchPlanRow with draggable modifier', async () => {
    const watchPlanViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');

    // Check for DraggableWatchPlanRow struct
    expect(content).toContain('struct DraggableWatchPlanRow');
    expect(content).toContain('.draggable(');
    expect(content).toContain('WatchPlanItemTransfer');
  });

  test('Drag callbacks for start and end', async () => {
    const watchPlanViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');

    // Check for drag callbacks
    expect(content).toContain('onDragStart');
    expect(content).toContain('onDragEnd');
  });

  test('Visual feedback during drag (rotation, scale, shadow)', async () => {
    const watchPlanViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');

    // Check for visual feedback
    expect(content).toContain('isDragging');
    expect(content).toContain('.scaleEffect(');
    expect(content).toContain('.rotationEffect(');
    expect(content).toContain('.shadow(');
    expect(content).toContain('.opacity(');
  });

  test('Drop destination for date groups', async () => {
    const watchPlanViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');

    // Check for dropDestination modifier
    expect(content).toContain('.dropDestination(');
    expect(content).toContain('for: WatchPlanItemTransfer.self');
    expect(content).toContain('isTargeted');
  });

  test('Drop target highlights when dragging over', async () => {
    const watchPlanViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');

    // Check for highlight state
    expect(content).toContain('highlightedDateGroup');
    expect(content).toContain('isHighlighted');
    expect(content).toContain('goldPrimary.opacity(0.1)');
  });

  test('Medium haptic on drag start', async () => {
    const watchPlanViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');

    // Check for medium haptic on drag start
    expect(content).toContain('HapticManager.medium()');
  });

  test('Success haptic on drop', async () => {
    const watchPlanViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');

    // Check for success haptic on drop
    expect(content).toContain('HapticManager.success()');
  });

  test('Supabase updated on drop via reschedule function', async () => {
    const watchPlanViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');

    // Check that drop triggers reschedule
    expect(content).toContain('viewModel.reschedule(itemId: droppedItem.itemId');
  });

  test('Drag preview shows movie title', async () => {
    const watchPlanViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');

    // Check for drag preview
    expect(content).toContain('WatchPlanDragPreview');
    expect(content).toContain('movie?.title');
  });

  test('Drag handle indicator in row', async () => {
    const watchPlanViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');

    // Check for drag handle
    expect(content).toContain('line.3.horizontal');
  });

  test('Cannot drop on overdue section', async () => {
    const watchPlanViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');

    // Check for overdue section filtering
    expect(content).toContain('OVERDUE');
    expect(content).toContain('group.label != "OVERDUE"');
  });

  test('Date header shows drop indicator when highlighted', async () => {
    const watchPlanViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');

    // Check for drop indicator in header
    expect(content).toContain('arrow.down.circle.fill');
    expect(content).toContain('isHighlighted');
  });

  test('Animation during highlight transitions', async () => {
    const watchPlanViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');

    // Check for animation
    expect(content).toContain('.animation(');
    expect(content).toContain('.easeInOut');
    expect(content).toContain('value: isHighlighted');
  });

  test('UniformTypeIdentifiers imported', async () => {
    const watchPlanViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');

    // Check for import
    expect(content).toContain('import UniformTypeIdentifiers');
  });

  test('Accessibility hint updated for drag support', async () => {
    const watchPlanViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');

    // Check for updated accessibility hint
    expect(content).toContain('Long press and drag');
    expect(content).toContain('accessibilityHint');
  });

  test('Dragged item state tracked', async () => {
    const watchPlanViewPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanViewPath, 'utf-8');

    // Check for dragged item state
    expect(content).toContain('@State private var draggedItem');
    expect(content).toContain('WatchPlanItem?');
  });
});
