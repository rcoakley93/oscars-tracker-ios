import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const PROJECT_ROOT = path.join(__dirname, '..');
const OSCARS_TRACKER_ROOT = path.join(PROJECT_ROOT, 'OscarsTracker', 'OscarsTracker');

test.describe('US-004: Fix Ballot Menu Image Loading', () => {
  test('BallotView imports Kingfisher for image loading', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check Kingfisher is imported
    expect(content).toContain('import Kingfisher');
  });

  test('NominationRow has posterView computed property', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check posterView exists
    expect(content).toContain('private var posterView');
    expect(content).toContain('KFImage');
  });

  test('NominationRow uses movie posterUrl for image loading', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check movie posterUrl is used
    expect(content).toContain('movie?.posterUrl');
    expect(content).toContain('URL(string: posterUrl)');
  });

  test('NominationRow has posterPlaceholder fallback', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check placeholder exists
    expect(content).toContain('private var posterPlaceholder');
    expect(content).toContain('Image(systemName: "film")');
  });

  test('KFImage uses placeholder for loading state', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check KFImage has placeholder
    expect(content).toMatch(/KFImage.*\.placeholder/s);
    expect(content).toContain('posterPlaceholder');
  });

  test('Poster image has correct frame dimensions', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check frame dimensions (40x60 for compact ballot view)
    expect(content).toMatch(/\.frame\(width:\s*40,\s*height:\s*60\)/);
  });

  test('Poster has rounded corners and border', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check clipShape and overlay for border
    expect(content).toContain('.clipShape(RoundedRectangle(cornerRadius: 6))');
    expect(content).toMatch(/\.overlay.*RoundedRectangle.*stroke/s);
  });

  test('NominationRow uses posterView instead of static placeholder', async () => {
    const ballotViewPath = path.join(OSCARS_TRACKER_ROOT, 'Views', 'Ballot', 'BallotView.swift');
    const content = fs.readFileSync(ballotViewPath, 'utf-8');

    // Check that NominationRow body uses posterView
    // Should NOT have inline RoundedRectangle placeholder in the HStack
    const nominationRowMatch = content.match(/struct NominationRow[\s\S]*?var body: some View \{[\s\S]*?HStack[\s\S]*?posterView/);
    expect(nominationRowMatch).not.toBeNull();
  });
});
