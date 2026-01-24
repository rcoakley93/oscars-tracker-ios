import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const XCODE_PROJECT_PATH = path.join(PROJECT_ROOT, 'OscarsTracker');
const OSCARS_TRACKER_PATH = path.join(XCODE_PROJECT_PATH, 'OscarsTracker');

test.describe('US-002: Design System Implementation', () => {
  test('Color+Extensions.swift with all theme colors', async () => {
    const colorExtPath = path.join(OSCARS_TRACKER_PATH, 'Utilities', 'Color+Extensions.swift');
    expect(fs.existsSync(colorExtPath)).toBe(true);

    const content = fs.readFileSync(colorExtPath, 'utf-8');

    // Check for gold theme colors
    expect(content).toContain('goldPrimary');
    expect(content).toContain('goldLight');
    expect(content).toContain('goldDark');

    // Check for background colors
    expect(content).toContain('appBackground');
    expect(content).toContain('cardBackground');

    // Check for text colors
    expect(content).toContain('textPrimary');
    expect(content).toContain('textMuted');

    // Check for gradient
    expect(content).toContain('LinearGradient');
    expect(content).toContain('gold');
  });

  test('Font+Extensions.swift with display and body font styles', async () => {
    const fontExtPath = path.join(OSCARS_TRACKER_PATH, 'Utilities', 'Font+Extensions.swift');
    expect(fs.existsSync(fontExtPath)).toBe(true);

    const content = fs.readFileSync(fontExtPath, 'utf-8');

    // Check for display fonts
    expect(content).toContain('displayLarge');
    expect(content).toContain('displayMedium');
    expect(content).toContain('displaySmall');

    // Check for heading fonts
    expect(content).toContain('headingLarge');
    expect(content).toContain('headingMedium');

    // Check for body fonts
    expect(content).toContain('bodyLarge');
    expect(content).toContain('bodyMedium');

    // Check for caption font
    expect(content).toContain('caption');
  });

  test('GlassCard component with blur and border effects', async () => {
    const glassCardPath = path.join(OSCARS_TRACKER_PATH, 'Components', 'GlassCard.swift');
    expect(fs.existsSync(glassCardPath)).toBe(true);

    const content = fs.readFileSync(glassCardPath, 'utf-8');

    // Check for SwiftUI import
    expect(content).toContain('import SwiftUI');

    // Check for GlassCard struct
    expect(content).toContain('struct GlassCard');

    // Check for blur/background effects
    expect(content).toContain('cardBackground');

    // Check for border effects (stroke overlay)
    expect(content).toContain('stroke');
    expect(content).toContain('RoundedRectangle');

    // Check for gradient effects
    expect(content).toContain('RadialGradient');

    // Check for view modifier extension
    expect(content).toContain('extension View');
    expect(content).toContain('glassCard');
  });

  test('GoldButtonStyle with gradient and press animation', async () => {
    const goldButtonPath = path.join(OSCARS_TRACKER_PATH, 'Components', 'GoldButtonStyle.swift');
    expect(fs.existsSync(goldButtonPath)).toBe(true);

    const content = fs.readFileSync(goldButtonPath, 'utf-8');

    // Check for SwiftUI import
    expect(content).toContain('import SwiftUI');

    // Check for ButtonStyle protocol
    expect(content).toContain('struct GoldButtonStyle: ButtonStyle');
    expect(content).toContain('makeBody');

    // Check for gradient background
    expect(content).toContain('LinearGradient.gold');

    // Check for press animation
    expect(content).toContain('isPressed');
    expect(content).toContain('scaleEffect');
    expect(content).toContain('animation');

    // Check for convenient static accessor
    expect(content).toContain('static var gold');
  });

  test('Gold glow modifier implemented', async () => {
    const goldGlowPath = path.join(OSCARS_TRACKER_PATH, 'Components', 'GoldGlowModifier.swift');
    expect(fs.existsSync(goldGlowPath)).toBe(true);

    const content = fs.readFileSync(goldGlowPath, 'utf-8');

    // Check for SwiftUI import
    expect(content).toContain('import SwiftUI');

    // Check for ViewModifier
    expect(content).toContain('struct GoldGlowModifier: ViewModifier');

    // Check for shadow effect (creates glow)
    expect(content).toContain('shadow');
    expect(content).toContain('goldPrimary');

    // Check for extension on View
    expect(content).toContain('extension View');
    expect(content).toContain('goldGlow');

    // Check for radius and opacity parameters
    expect(content).toContain('radius');
    expect(content).toContain('opacity');
  });

  test('Dark theme applied app-wide', async () => {
    const appPath = path.join(OSCARS_TRACKER_PATH, 'App', 'OscarsTrackerApp.swift');
    expect(fs.existsSync(appPath)).toBe(true);

    const content = fs.readFileSync(appPath, 'utf-8');

    // Check for dark color scheme
    expect(content).toContain('preferredColorScheme(.dark)');
  });

  test('Components are registered in Xcode project', async () => {
    const pbxprojPath = path.join(XCODE_PROJECT_PATH, 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const pbxprojContent = fs.readFileSync(pbxprojPath, 'utf-8');

    // Check all component files are in the project
    expect(pbxprojContent).toContain('GlassCard.swift');
    expect(pbxprojContent).toContain('GoldButtonStyle.swift');
    expect(pbxprojContent).toContain('GoldGlowModifier.swift');

    // Check they're in the Sources build phase
    expect(pbxprojContent).toContain('GlassCard.swift in Sources');
    expect(pbxprojContent).toContain('GoldButtonStyle.swift in Sources');
    expect(pbxprojContent).toContain('GoldGlowModifier.swift in Sources');
  });
});
