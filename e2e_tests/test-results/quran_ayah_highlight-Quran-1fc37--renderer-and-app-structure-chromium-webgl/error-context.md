# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: quran_ayah_highlight.spec.ts >> Quran Mushaf - Ayah Highlight Feature >> Diagnostic: Detect Flutter renderer and app structure
- Location: tests\quran_ayah_highlight.spec.ts:74:7

# Error details

```
Error: page.waitForFunction: Target page, context or browser has been closed
```

# Test source

```ts
  1   | import { test, expect, Page } from '@playwright/test';
  2   | import * as path from 'path';
  3   | import * as fs from 'fs';
  4   | 
  5   | const SCREENSHOTS_DIR = path.join(__dirname, '..', 'screenshots');
  6   | 
  7   | // Flutter web with CanvasKit renderer draws everything to a WebGL <canvas>.
  8   | // There are no regular DOM text nodes. To interact with it from Playwright we
  9   | // must either:
  10  | //   (a) use the Flutter accessibility/semantics DOM tree (enabled by default
  11  | //       in debug builds; in release builds it is activated on first Tab key),
  12  | //   (b) click by coordinate and compare screenshots.
  13  | //
  14  | // This test uses approach (b) first (coordinates + pixel-color diff) and
  15  | // also tries (a) via flt-semantics elements after activating semantics.
  16  | 
  17  | async function waitForCanvasReady(page: Page, timeoutMs = 45_000) {
  18  |   // Wait for Flutter's canvas element to appear and be painted
> 19  |   await page.waitForFunction(
      |              ^ Error: page.waitForFunction: Target page, context or browser has been closed
  20  |     () => {
  21  |       const canvas = document.querySelector('canvas');
  22  |       if (!canvas) return false;
  23  |       // Check if the canvas has been drawn to (non-zero size)
  24  |       return canvas.offsetWidth > 0 && canvas.offsetHeight > 0;
  25  |     },
  26  |     { timeout: timeoutMs }
  27  |   );
  28  |   // Flutter/CanvasKit takes time to compile WASM and render the first frame
  29  |   await page.waitForTimeout(5000);
  30  | }
  31  | 
  32  | async function activateFlutterSemantics(page: Page) {
  33  |   // Press Tab to activate Flutter's accessibility tree (flt-semantics elements)
  34  |   await page.keyboard.press('Tab');
  35  |   await page.waitForTimeout(1500);
  36  |   // Check if semantics tree appeared
  37  |   const count = await page.evaluate(() => document.querySelectorAll('flt-semantics').length);
  38  |   console.log(`flt-semantics elements after Tab: ${count}`);
  39  |   return count;
  40  | }
  41  | 
  42  | async function getAllSemanticElements(page: Page) {
  43  |   return page.evaluate(() => {
  44  |     const els = document.querySelectorAll('flt-semantics');
  45  |     return Array.from(els).map(el => {
  46  |       const rect = el.getBoundingClientRect();
  47  |       return {
  48  |         label: el.getAttribute('aria-label') || el.getAttribute('aria-placeholder') || el.textContent?.trim().substring(0, 80) || '',
  49  |         role: el.getAttribute('role') || '',
  50  |         tabIndex: el.getAttribute('tabindex') || '',
  51  |         x: Math.round(rect.left + rect.width / 2),
  52  |         y: Math.round(rect.top + rect.height / 2),
  53  |         w: Math.round(rect.width),
  54  |         h: Math.round(rect.height),
  55  |       };
  56  |     }).filter(el => el.w > 0 && el.h > 0);
  57  |   });
  58  | }
  59  | 
  60  | // Returns pixel color at (x, y) from a screenshot buffer
  61  | async function getPixelColor(page: Page, x: number, y: number): Promise<{r: number, g: number, b: number}> {
  62  |   return page.evaluate(({ x, y }) => {
  63  |     const canvas = document.querySelector('canvas') as HTMLCanvasElement;
  64  |     if (!canvas) return { r: 0, g: 0, b: 0 };
  65  |     // We can't read CanvasKit WebGL pixels from JS without a 2D context,
  66  |     // but we can use the flt-scene-host layer if HTML renderer is used.
  67  |     // For CanvasKit, pixel reading is not possible - return sentinel.
  68  |     return { r: -1, g: -1, b: -1 };
  69  |   }, { x, y });
  70  | }
  71  | 
  72  | test.describe('Quran Mushaf - Ayah Highlight Feature', () => {
  73  | 
  74  |   test('Diagnostic: Detect Flutter renderer and app structure', async ({ page }) => {
  75  |     await page.goto('http://localhost:8888', { waitUntil: 'domcontentloaded' });
  76  | 
  77  |     // Wait for canvas with extended timeout (CanvasKit loads WASM)
  78  |     console.log('Waiting for Flutter canvas...');
  79  |     await waitForCanvasReady(page, 50_000);
  80  | 
  81  |     await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '01_app_loaded.png'), fullPage: true });
  82  | 
  83  |     // Inspect DOM structure
  84  |     const domInfo = await page.evaluate(() => {
  85  |       const body = document.body;
  86  |       const canvases = body.querySelectorAll('canvas');
  87  |       const fltEls = body.querySelectorAll('[class*="flt"], flt-scene-host, flt-glass-pane');
  88  |       const semanticsEls = body.querySelectorAll('flt-semantics');
  89  |       const allTags = new Set(Array.from(body.querySelectorAll('*')).map(e => e.tagName.toLowerCase()));
  90  | 
  91  |       return {
  92  |         canvasCount: canvases.length,
  93  |         canvasSizes: Array.from(canvases).map(c => `${c.width}x${c.height}`),
  94  |         fltElementCount: fltEls.length,
  95  |         semanticsCount: semanticsEls.length,
  96  |         customTags: Array.from(allTags).filter(t => t.includes('-') || t.startsWith('flt')),
  97  |         bodyText: body.innerText.substring(0, 200),
  98  |         bodyChildTags: Array.from(body.children).map(c => c.tagName.toLowerCase()),
  99  |       };
  100 |     });
  101 |     console.log('DOM Info:', JSON.stringify(domInfo, null, 2));
  102 | 
  103 |     // Determine renderer
  104 |     if (domInfo.canvasCount > 0) {
  105 |       console.log(`RENDERER: CanvasKit (WebGL canvas ${domInfo.canvasSizes[0]})`);
  106 |     } else if (domInfo.fltElementCount > 0) {
  107 |       console.log('RENDERER: Flutter HTML renderer');
  108 |     }
  109 | 
  110 |     // Try to activate semantics
  111 |     const semCount = await activateFlutterSemantics(page);
  112 |     await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '02_after_semantics.png'), fullPage: true });
  113 | 
  114 |     const semanticEls = await getAllSemanticElements(page);
  115 |     console.log(`Semantic elements: ${JSON.stringify(semanticEls.slice(0, 20), null, 2)}`);
  116 | 
  117 |     // Test passes regardless - this is diagnostic
  118 |     expect(domInfo.canvasCount + domInfo.fltElementCount).toBeGreaterThanOrEqual(0);
  119 |     console.log('Diagnostic complete');
```