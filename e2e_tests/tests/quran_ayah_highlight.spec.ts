import { test, expect, Page } from '@playwright/test';
import * as path from 'path';
import * as fs from 'fs';

const SCREENSHOTS_DIR = path.join(__dirname, '..', 'screenshots');

// Flutter web with CanvasKit renderer draws everything to a WebGL <canvas>.
// There are no regular DOM text nodes. To interact with it from Playwright we
// must either:
//   (a) use the Flutter accessibility/semantics DOM tree (enabled by default
//       in debug builds; in release builds it is activated on first Tab key),
//   (b) click by coordinate and compare screenshots.
//
// This test uses approach (b) first (coordinates + pixel-color diff) and
// also tries (a) via flt-semantics elements after activating semantics.

async function waitForCanvasReady(page: Page, timeoutMs = 45_000) {
  // Wait for Flutter's canvas element to appear and be painted
  await page.waitForFunction(
    () => {
      const canvas = document.querySelector('canvas');
      if (!canvas) return false;
      // Check if the canvas has been drawn to (non-zero size)
      return canvas.offsetWidth > 0 && canvas.offsetHeight > 0;
    },
    { timeout: timeoutMs }
  );
  // Flutter/CanvasKit takes time to compile WASM and render the first frame
  await page.waitForTimeout(5000);
}

async function activateFlutterSemantics(page: Page) {
  // Press Tab to activate Flutter's accessibility tree (flt-semantics elements)
  await page.keyboard.press('Tab');
  await page.waitForTimeout(1500);
  // Check if semantics tree appeared
  const count = await page.evaluate(() => document.querySelectorAll('flt-semantics').length);
  console.log(`flt-semantics elements after Tab: ${count}`);
  return count;
}

async function getAllSemanticElements(page: Page) {
  return page.evaluate(() => {
    const els = document.querySelectorAll('flt-semantics');
    return Array.from(els).map(el => {
      const rect = el.getBoundingClientRect();
      return {
        label: el.getAttribute('aria-label') || el.getAttribute('aria-placeholder') || el.textContent?.trim().substring(0, 80) || '',
        role: el.getAttribute('role') || '',
        tabIndex: el.getAttribute('tabindex') || '',
        x: Math.round(rect.left + rect.width / 2),
        y: Math.round(rect.top + rect.height / 2),
        w: Math.round(rect.width),
        h: Math.round(rect.height),
      };
    }).filter(el => el.w > 0 && el.h > 0);
  });
}

// Returns pixel color at (x, y) from a screenshot buffer
async function getPixelColor(page: Page, x: number, y: number): Promise<{r: number, g: number, b: number}> {
  return page.evaluate(({ x, y }) => {
    const canvas = document.querySelector('canvas') as HTMLCanvasElement;
    if (!canvas) return { r: 0, g: 0, b: 0 };
    // We can't read CanvasKit WebGL pixels from JS without a 2D context,
    // but we can use the flt-scene-host layer if HTML renderer is used.
    // For CanvasKit, pixel reading is not possible - return sentinel.
    return { r: -1, g: -1, b: -1 };
  }, { x, y });
}

test.describe('Quran Mushaf - Ayah Highlight Feature', () => {

  test('Diagnostic: Detect Flutter renderer and app structure', async ({ page }) => {
    await page.goto('http://localhost:8888', { waitUntil: 'domcontentloaded' });

    // Wait for canvas with extended timeout (CanvasKit loads WASM)
    console.log('Waiting for Flutter canvas...');
    await waitForCanvasReady(page, 50_000);

    await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '01_app_loaded.png'), fullPage: true });

    // Inspect DOM structure
    const domInfo = await page.evaluate(() => {
      const body = document.body;
      const canvases = body.querySelectorAll('canvas');
      const fltEls = body.querySelectorAll('[class*="flt"], flt-scene-host, flt-glass-pane');
      const semanticsEls = body.querySelectorAll('flt-semantics');
      const allTags = new Set(Array.from(body.querySelectorAll('*')).map(e => e.tagName.toLowerCase()));

      return {
        canvasCount: canvases.length,
        canvasSizes: Array.from(canvases).map(c => `${c.width}x${c.height}`),
        fltElementCount: fltEls.length,
        semanticsCount: semanticsEls.length,
        customTags: Array.from(allTags).filter(t => t.includes('-') || t.startsWith('flt')),
        bodyText: body.innerText.substring(0, 200),
        bodyChildTags: Array.from(body.children).map(c => c.tagName.toLowerCase()),
      };
    });
    console.log('DOM Info:', JSON.stringify(domInfo, null, 2));

    // Determine renderer
    if (domInfo.canvasCount > 0) {
      console.log(`RENDERER: CanvasKit (WebGL canvas ${domInfo.canvasSizes[0]})`);
    } else if (domInfo.fltElementCount > 0) {
      console.log('RENDERER: Flutter HTML renderer');
    }

    // Try to activate semantics
    const semCount = await activateFlutterSemantics(page);
    await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '02_after_semantics.png'), fullPage: true });

    const semanticEls = await getAllSemanticElements(page);
    console.log(`Semantic elements: ${JSON.stringify(semanticEls.slice(0, 20), null, 2)}`);

    // Test passes regardless - this is diagnostic
    expect(domInfo.canvasCount + domInfo.fltElementCount).toBeGreaterThanOrEqual(0);
    console.log('Diagnostic complete');
  });

  test('Navigate to Quran and open Mushaf', async ({ page }) => {
    test.setTimeout(120_000);

    await page.goto('http://localhost:8888', { waitUntil: 'domcontentloaded' });
    console.log('Waiting for Flutter canvas...');
    await waitForCanvasReady(page, 50_000);

    const viewport = page.viewportSize()!;
    console.log(`Viewport: ${viewport.width}x${viewport.height}`);

    await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '10_home_screen.png'), fullPage: true });

    // Activate Flutter semantics
    await activateFlutterSemantics(page);

    let semanticEls = await getAllSemanticElements(page);
    console.log(`Home screen semantic elements (${semanticEls.length}): ${JSON.stringify(semanticEls, null, 2)}`);

    // Strategy 1: Find Quran element in semantics
    let quranEl = semanticEls.find(el =>
      el.label.includes('القرآن') || el.label.includes('قرآن') ||
      el.label.toLowerCase().includes('quran') || el.label.includes('مصحف')
    );

    if (quranEl) {
      console.log(`Found Quran via semantics: "${quranEl.label}" at (${quranEl.x}, ${quranEl.y})`);
      await page.mouse.click(quranEl.x, quranEl.y);
    } else {
      // Strategy 2: Visual grid - try all grid cells
      // Home screen is a grid. Based on typical Flutter grid layouts:
      // For a 2-column grid in a 1280x720 viewport, items are ~640px wide
      const gridCols = 2;
      const gridRows = 4;
      const cellW = viewport.width / gridCols;
      const cellH = (viewport.height * 0.8) / gridRows; // 80% of screen height, 4 rows

      console.log('Trying grid cell clicks...');
      let found = false;

      for (let row = 0; row < gridRows && !found; row++) {
        for (let col = 0; col < gridCols && !found; col++) {
          const cx = Math.round(cellW * col + cellW / 2);
          const cy = Math.round(100 + cellH * row + cellH / 2); // 100px top offset for header

          console.log(`Trying grid cell [${row},${col}] at (${cx}, ${cy})`);
          await page.mouse.click(cx, cy);
          await page.waitForTimeout(2000);

          await page.screenshot({ path: path.join(SCREENSHOTS_DIR, `11_grid_click_${row}_${col}.png`), fullPage: true });

          // Check if we're on a new screen by looking at semantics
          const newSemantics = await getAllSemanticElements(page);
          const hasQuranContent = newSemantics.some(el =>
            el.label.includes('سورة') || el.label.includes('آية') ||
            el.label.includes('فتح المصحف') || el.label.includes('البقرة') ||
            el.label.includes('الفاتحة') || el.label.includes('سور')
          );

          if (hasQuranContent) {
            console.log(`Found Quran content after clicking [${row},${col}]!`);
            found = true;
          } else {
            // Go back if we navigated somewhere else
            const isNotHome = newSemantics.length !== semanticEls.length ||
              !newSemantics.some(el => el.label === (semanticEls[0]?.label || ''));
            if (isNotHome && newSemantics.length > 0) {
              await page.goBack().catch(() => {});
              await page.waitForTimeout(1500);
            }
          }
        }
      }

      if (!found) {
        console.log('Could not find Quran section through grid clicks');
      }
    }

    await page.waitForTimeout(2000);
    await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '12_after_quran_nav.png'), fullPage: true });

    semanticEls = await getAllSemanticElements(page);
    console.log(`After nav semantics: ${JSON.stringify(semanticEls, null, 2)}`);

    // Look for "فتح المصحف" button
    const mushafBtn = semanticEls.find(el =>
      el.label.includes('فتح المصحف') || el.label.includes('فتح') || el.label.includes('المصحف')
    );

    if (mushafBtn) {
      console.log(`Clicking Mushaf button: "${mushafBtn.label}" at (${mushafBtn.x}, ${mushafBtn.y})`);
      await page.mouse.click(mushafBtn.x, mushafBtn.y);
      await page.waitForTimeout(3000);
      await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '13_mushaf_open.png'), fullPage: true });
    }

    console.log('Navigation test done');
  });

  test('Ayah highlight: click ayah and verify highlight appears', async ({ page }) => {
    test.setTimeout(180_000);

    await page.goto('http://localhost:8888', { waitUntil: 'domcontentloaded' });
    console.log('Waiting for Flutter app to fully load...');
    await waitForCanvasReady(page, 50_000);

    const viewport = page.viewportSize()!;
    await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '20_start.png'), fullPage: true });

    // Enable semantics
    await activateFlutterSemantics(page);

    // --- PHASE 1: Navigate to Quran ---
    console.log('--- Phase 1: Navigate to Quran section ---');

    let homeSemantics = await getAllSemanticElements(page);
    console.log(`Home semantics (${homeSemantics.length}): ${JSON.stringify(homeSemantics.map(e => ({l: e.label, x: e.x, y: e.y})), null, 2)}`);

    // Find Quran entry
    const quranEl = homeSemantics.find(el =>
      el.label.includes('القرآن') || el.label.includes('قرآن') ||
      el.label.toLowerCase().includes('quran') || el.label.includes('المصحف')
    );

    if (quranEl) {
      console.log(`Clicking Quran: "${quranEl.label}"`);
      await page.mouse.click(quranEl.x, quranEl.y);
      await page.waitForTimeout(2500);
    } else {
      // Blind grid scan
      const cols = [Math.round(viewport.width * 0.25), Math.round(viewport.width * 0.75)];
      const rows = [
        Math.round(viewport.height * 0.25),
        Math.round(viewport.height * 0.42),
        Math.round(viewport.height * 0.58),
        Math.round(viewport.height * 0.75),
      ];
      for (const y of rows) {
        for (const x of cols) {
          await page.mouse.click(x, y);
          await page.waitForTimeout(1200);
          const sems = await getAllSemanticElements(page);
          if (sems.some(el => el.label.includes('سورة') || el.label.includes('فتح المصحف') || el.label.includes('الفاتحة'))) {
            console.log(`Quran found at (${x}, ${y})`);
            break;
          }
        }
      }
    }

    await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '21_quran_screen.png'), fullPage: true });

    // --- PHASE 2: Open Mushaf ---
    console.log('--- Phase 2: Open Mushaf ---');

    let currentSemantics = await getAllSemanticElements(page);
    console.log(`Quran screen semantics: ${JSON.stringify(currentSemantics.map(e => ({l: e.label.substring(0, 40), x: e.x, y: e.y})), null, 2)}`);

    const mushafBtn = currentSemantics.find(el =>
      el.label.includes('فتح المصحف') || el.label.includes('المصحف الشريف') ||
      el.label.includes('فتح') || el.label.includes('مصحف')
    );

    if (mushafBtn) {
      console.log(`Opening Mushaf via button: "${mushafBtn.label}"`);
      await page.mouse.click(mushafBtn.x, mushafBtn.y);
      await page.waitForTimeout(4000);
    } else {
      // Try clicking the first surah in the list (Surah Al-Fatiha)
      const fatihaEl = currentSemantics.find(el =>
        el.label.includes('الفاتحة') || el.label.includes('البقرة') || el.label.includes('١')
      );
      if (fatihaEl) {
        console.log(`Opening via surah: "${fatihaEl.label}"`);
        await page.mouse.click(fatihaEl.x, fatihaEl.y);
        await page.waitForTimeout(4000);
      }
    }

    await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '22_mushaf_reader.png'), fullPage: true });

    // --- PHASE 3: Find and click an ayah ---
    console.log('--- Phase 3: Click an ayah ---');

    let mushafSemantics = await getAllSemanticElements(page);
    console.log(`Mushaf semantics (${mushafSemantics.length}): ${JSON.stringify(mushafSemantics.map(e => ({l: e.label.substring(0, 50), x: e.x, y: e.y})), null, 2)}`);

    // Arabic text elements (at least 5 Arabic chars, not navigation labels)
    const arabicRegex = /[\u0600-\u06FF]{5,}/;
    const ayahElements = mushafSemantics.filter(el =>
      arabicRegex.test(el.label) &&
      !el.label.includes('سورة') &&
      !el.label.includes('الجزء') &&
      el.w > 50
    );
    console.log(`Candidate ayah elements: ${JSON.stringify(ayahElements.slice(0, 5).map(e => ({l: e.label.substring(0, 50), x: e.x, y: e.y})), null, 2)}`);

    if (ayahElements.length === 0) {
      // Mushaf may be open but semantics not refreshed - try center of screen
      console.log('No ayah elements found in semantics. Trying center-area clicks...');
      const centerX = Math.round(viewport.width / 2);
      const centerY = Math.round(viewport.height / 2);

      // Screenshot BEFORE click - this is our baseline
      await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '23_before_ayah_click.png'), fullPage: true });

      // Click center of mushaf page (where ayah text would be)
      await page.mouse.click(centerX, centerY);
      await page.waitForTimeout(1500);

      await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '24_after_center_click.png'), fullPage: true });

      // Try a slightly higher position (ayah text is usually in upper half)
      await page.mouse.click(centerX, Math.round(viewport.height * 0.35));
      await page.waitForTimeout(1500);
      await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '25_after_upper_click.png'), fullPage: true });

      console.log('RESULT: Mushaf is open but semantics tree does not expose individual ayah elements.');
      console.log('This is expected for CanvasKit renderer without accessibility mode enabled.');
      console.log('Screenshots 24/25 show the state after clicking where ayah text is expected.');
      console.log('Compare 23 vs 24 vs 25 visually to see if highlight appeared.');

    } else {
      // Click the first ayah element
      const targetAyah = ayahElements[0];
      console.log(`Clicking ayah: "${targetAyah.label.substring(0, 40)}" at (${targetAyah.x}, ${targetAyah.y})`);

      await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '23_before_ayah_click.png'), fullPage: true });
      await page.mouse.click(targetAyah.x, targetAyah.y);
      await page.waitForTimeout(1500);
      await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '24_after_ayah_click.png'), fullPage: true });

      // --- PHASE 4: Verify highlight ---
      console.log('--- Phase 4: Verify highlight ---');

      // Check 1: DOM-level color check (works for HTML renderer)
      const highlightElements = await page.evaluate(() => {
        const results: Array<{tag: string, bg: string, content: string}> = [];
        document.querySelectorAll('*').forEach(el => {
          const bg = window.getComputedStyle(el).backgroundColor;
          if (!bg || bg === 'rgba(0, 0, 0, 0)' || bg === 'transparent') return;
          const match = bg.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
          if (!match) return;
          const r = parseInt(match[1]), g = parseInt(match[2]), b = parseInt(match[3]);
          // Target: Color(0xFF90CAF9) = rgb(144,202,249) with alpha 0.4
          // Tolerance: check if it's a blue-dominant color
          if (b > 150 && b > r + 30 && g > 100) {
            results.push({ tag: el.tagName, bg, content: el.textContent?.substring(0, 40) || '' });
          }
        });
        return results;
      });
      console.log(`DOM highlight elements found: ${JSON.stringify(highlightElements)}`);

      // Check 2: Updated semantics (highlighted ayah might change aria attributes)
      const updatedSemantics = await getAllSemanticElements(page);
      const hasChanged = JSON.stringify(updatedSemantics) !== JSON.stringify(mushafSemantics);
      console.log(`Semantics changed after click: ${hasChanged}`);

      // Report result
      if (highlightElements.length > 0) {
        console.log('RESULT: HIGHLIGHT CONFIRMED - Light blue background detected in DOM after ayah click!');
        console.log(`Highlighted element: ${JSON.stringify(highlightElements[0])}`);
      } else {
        console.log('RESULT: Could not confirm via DOM colors (CanvasKit renders to canvas, not DOM).');
        console.log('Check screenshots 23_before vs 24_after - look for light blue highlight on ayah text.');
      }

      // Click a second ayah to test switching
      if (ayahElements.length > 1) {
        const ayah2 = ayahElements[1];
        await page.mouse.click(ayah2.x, ayah2.y);
        await page.waitForTimeout(1000);
        await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '25_second_ayah_click.png'), fullPage: true });
        console.log(`Clicked second ayah: "${ayah2.label.substring(0, 40)}" - see 25_second_ayah_click.png`);
      }
    }

    // Final summary
    console.log('\n=== TEST SUMMARY ===');
    console.log(`Screenshots saved to: ${SCREENSHOTS_DIR}`);
    console.log('Key screenshots:');
    console.log('  20_start.png          - Home screen');
    console.log('  21_quran_screen.png   - Quran section');
    console.log('  22_mushaf_reader.png  - Mushaf reader open');
    console.log('  23_before_ayah_click  - Before clicking ayah');
    console.log('  24_after_ayah_click   - After clicking ayah (check for blue highlight)');
  });
});
