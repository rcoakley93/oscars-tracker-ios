import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-042: Fix Drag and Drop in Watch Plan', () => {
  test('User can long-press a movie card to start dragging via .draggable modifier', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for draggable modifier on row
    expect(content).toContain('struct DraggableWatchPlanRow');
    expect(content).toContain('.draggable(WatchPlanItemTransfer');
    expect(content).toContain('onDragStart');
    expect(content).toContain('HapticManager.medium()');
  });

  test('Drag preview appears showing the movie being dragged', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for drag preview
    expect(content).toContain('struct WatchPlanDragPreview');
    expect(content).toContain('WatchPlanDragPreview(movie: movie)');
    expect(content).toContain('movie?.title');
  });

  test('Drop zones highlight when dragging over valid date groups', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for highlight state and visual feedback
    expect(content).toContain('highlightedDateGroup');
    expect(content).toContain('isTargeted');
    expect(content).toContain('Color.goldPrimary.opacity(0.1)');

    // Check for "Drop here" indicator
    expect(content).toContain('Drop here');
    expect(content).toContain('arrow.down');
  });

  test('Dropping on a date group reschedules the movie', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for drop destination and reschedule call
    expect(content).toContain('.dropDestination(for: WatchPlanItemTransfer.self)');
    expect(content).toContain('viewModel.reschedule(itemId: droppedItem.itemId, to: group.date)');
  });

  test('Haptic feedback on successful drop', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for success haptic in drop handler
    expect(content).toContain('HapticManager.success()');
    expect(content).toContain('HapticManager.error()');
  });

  test('Cannot drop on OVERDUE section', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for overdue section filtering
    expect(content).toContain('group.label != "OVERDUE"');

    // Check that highlight is prevented for overdue section
    expect(content).toContain('if group.label != "OVERDUE"');
  });

  test('Uses .data contentType for cross-platform compatibility', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for .data content type instead of custom UTType
    expect(content).toContain('CodableRepresentation(contentType: .data)');
  });

  test('Content shape defined for proper drag recognition', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for contentShape on draggable and droppable areas
    expect(content).toContain('.contentShape(Rectangle())');
  });

  test('Visual drag feedback with opacity, scale, rotation, shadow', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for visual feedback properties
    expect(content).toContain('.opacity(isDragging ? 0.5 : 1.0)');
    expect(content).toContain('.scaleEffect(isDragging ? 0.95 : 1.0)');
    expect(content).toContain('.rotationEffect(.degrees(isDragging ? 2 : 0))');
    expect(content).toContain('.shadow(color: isDragging ?');
  });

  test('Drag state is properly reset after drop', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for state reset in drop handler
    expect(content).toContain('draggedItem = nil');
    expect(content).toContain('highlightedDateGroup = nil');
  });

  test('Drop zone background highlight on targeting', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for background highlight on drop zone
    expect(content).toContain('.background(');
    expect(content).toContain('RoundedRectangle(cornerRadius: 12)');
    expect(content).toContain('highlightedDateGroup == group.date');
  });

  test('Animation on highlight transition', async () => {
    const watchPlanPath = path.join(OSCARS_TRACKER_PATH, 'Views', 'WatchPlan', 'WatchPlanView.swift');
    const content = fs.readFileSync(watchPlanPath, 'utf-8');

    // Check for animated highlight
    expect(content).toContain('withAnimation(.easeInOut(duration: 0.15))');
  });
});
