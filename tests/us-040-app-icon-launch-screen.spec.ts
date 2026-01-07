import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const OSCARS_TRACKER_PATH = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker');
const ASSETS_PATH = path.join(OSCARS_TRACKER_PATH, 'Resources', 'Assets.xcassets');

test.describe('US-040: App Icon & Launch Screen', () => {
  test('AppIcon.appiconset exists', async () => {
    const dirPath = path.join(ASSETS_PATH, 'AppIcon.appiconset');
    expect(fs.existsSync(dirPath)).toBeTruthy();
  });

  test('AppIcon Contents.json has proper structure', async () => {
    const filePath = path.join(ASSETS_PATH, 'AppIcon.appiconset', 'Contents.json');
    const content = JSON.parse(fs.readFileSync(filePath, 'utf-8'));

    // Check for images array
    expect(content.images).toBeDefined();
    expect(Array.isArray(content.images)).toBeTruthy();
    expect(content.images.length).toBeGreaterThan(0);
  });

  test('AppIcon has 1024x1024 size for App Store', async () => {
    const filePath = path.join(ASSETS_PATH, 'AppIcon.appiconset', 'Contents.json');
    const content = JSON.parse(fs.readFileSync(filePath, 'utf-8'));

    const hasAppStoreSize = content.images.some(
      (img: any) => img.size === '1024x1024' && img.platform === 'ios'
    );
    expect(hasAppStoreSize).toBeTruthy();
  });

  test('AppIcon supports dark mode appearance', async () => {
    const filePath = path.join(ASSETS_PATH, 'AppIcon.appiconset', 'Contents.json');
    const content = JSON.parse(fs.readFileSync(filePath, 'utf-8'));

    const hasDarkVariant = content.images.some(
      (img: any) => img.appearances?.some((a: any) => a.value === 'dark')
    );
    expect(hasDarkVariant).toBeTruthy();
  });

  test('AppIcon supports tinted appearance', async () => {
    const filePath = path.join(ASSETS_PATH, 'AppIcon.appiconset', 'Contents.json');
    const content = JSON.parse(fs.readFileSync(filePath, 'utf-8'));

    const hasTintedVariant = content.images.some(
      (img: any) => img.appearances?.some((a: any) => a.value === 'tinted')
    );
    expect(hasTintedVariant).toBeTruthy();
  });

  test('LaunchBackgroundColor.colorset exists', async () => {
    const dirPath = path.join(ASSETS_PATH, 'LaunchBackgroundColor.colorset');
    expect(fs.existsSync(dirPath)).toBeTruthy();
  });

  test('LaunchBackgroundColor matches app background color', async () => {
    const filePath = path.join(ASSETS_PATH, 'LaunchBackgroundColor.colorset', 'Contents.json');
    const content = JSON.parse(fs.readFileSync(filePath, 'utf-8'));

    // Check for color definition
    expect(content.colors).toBeDefined();
    expect(content.colors.length).toBeGreaterThan(0);

    // Check color components match app background (0.05 brightness = dark)
    const color = content.colors[0].color;
    expect(color['color-space']).toBe('srgb');

    // App background is very dark (0.05 brightness)
    const components = color.components;
    expect(parseFloat(components.red)).toBeLessThanOrEqual(0.1);
    expect(parseFloat(components.green)).toBeLessThanOrEqual(0.1);
    expect(parseFloat(components.blue)).toBeLessThanOrEqual(0.1);
  });

  test('Project uses launch screen generation', async () => {
    const pbxprojPath = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const content = fs.readFileSync(pbxprojPath, 'utf-8');

    expect(content).toContain('INFOPLIST_KEY_UILaunchScreen_Generation = YES');
  });

  test('Assets.xcassets has Contents.json', async () => {
    const filePath = path.join(ASSETS_PATH, 'Contents.json');
    expect(fs.existsSync(filePath)).toBeTruthy();
  });

  test('AccentColor.colorset exists', async () => {
    const dirPath = path.join(ASSETS_PATH, 'AccentColor.colorset');
    expect(fs.existsSync(dirPath)).toBeTruthy();
  });

  test('Project build settings reference AppIcon', async () => {
    const pbxprojPath = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker.xcodeproj', 'project.pbxproj');
    const content = fs.readFileSync(pbxprojPath, 'utf-8');

    expect(content).toContain('ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon');
  });

  test('AppIcon filenames are defined for each variant', async () => {
    const filePath = path.join(ASSETS_PATH, 'AppIcon.appiconset', 'Contents.json');
    const content = JSON.parse(fs.readFileSync(filePath, 'utf-8'));

    // Check that each image has a filename defined
    for (const img of content.images) {
      expect(img.filename).toBeDefined();
      expect(img.filename.endsWith('.png')).toBeTruthy();
    }
  });

  test('AppIcon universal idiom for iOS', async () => {
    const filePath = path.join(ASSETS_PATH, 'AppIcon.appiconset', 'Contents.json');
    const content = JSON.parse(fs.readFileSync(filePath, 'utf-8'));

    const hasUniversal = content.images.every(
      (img: any) => img.idiom === 'universal'
    );
    expect(hasUniversal).toBeTruthy();
  });

  test('Assets have proper xcode author', async () => {
    const filePath = path.join(ASSETS_PATH, 'AppIcon.appiconset', 'Contents.json');
    const content = JSON.parse(fs.readFileSync(filePath, 'utf-8'));

    expect(content.info.author).toBe('xcode');
    expect(content.info.version).toBe(1);
  });

  test('LaunchBackgroundColor has proper xcode metadata', async () => {
    const filePath = path.join(ASSETS_PATH, 'LaunchBackgroundColor.colorset', 'Contents.json');
    const content = JSON.parse(fs.readFileSync(filePath, 'utf-8'));

    expect(content.info.author).toBe('xcode');
    expect(content.info.version).toBe(1);
  });
});
