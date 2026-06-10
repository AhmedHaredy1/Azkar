# Handoff — Azkar App Redesign

## Overview

A full-product visual redesign of an existing Flutter Azkar app (Islamic prayer / Quran / remembrance). The redesign pushes the product toward a **minimal, modern, Arabic-first** aesthetic with a restrained Islamic green accent, reserved gold highlights for Quranic content, and warm off-white surfaces. 25 screens designed across iOS and Android, covering the complete product surface.

## About the Design Files

The files in `prototype/` are **design references created in HTML** — React + inline JSX prototypes showing intended look and behavior. They are **not production code** to copy directly.

**Your task:** recreate these designs in the existing Flutter codebase, using the app's established widgets, routing, and state patterns. Treat the HTML as a visual spec. Every numeric value (color, spacing, radius, font size, weight) in the HTML is deliberate and should be preserved when translated to Flutter `TextStyle`, `BoxDecoration`, `EdgeInsets`, etc.

If there is no existing code pattern for something (e.g. the 8-point star ornament, the streak day grid, the waveform), build a new widget that matches the visual.

## Fidelity

**High-fidelity.** Final colors, typography, spacing, and interaction intent are decided. Developer should recreate pixel-perfectly.

- All numeric values in the HTML are intentional — match them.
- Arabic text samples are placeholder; pull real data from the app's existing sources.
- Iconography is a custom thin-line set (1.5px stroke, 24×24 viewBox) — SVG paths are in `prototype/src/tokens.jsx` under `ICONS`. These should be converted to Flutter `CustomPainter`s or exported as SVG assets.

## Design Tokens

Single source of truth: `prototype/src/tokens.jsx`. Reproduce these as Dart constants (e.g. `lib/theme/tokens.dart`).

### Colors

| Token              | Hex                          | Usage                                         |
| ------------------ | ---------------------------- | --------------------------------------------- |
| `primary`          | `#1B5E20`                    | Islamic green — accent only, restrained        |
| `primarySoft`      | `#EEF3EE`                    | Tint fill behind primary text / icons          |
| `primaryInk`       | `#0F3A13`                    | Text on `primarySoft`                          |
| `gold`             | `#B8892A`                    | Reserved: Quran hero, streaks, highlights      |
| `goldSoft`         | `#F5ECD9`                    | Tint fill for gold icons                       |
| `bg`               | `#FAF8F3`                    | Page background (warm off-white)               |
| `surface`          | `#FFFFFF`                    | Cards                                          |
| `surfaceSunk`      | `#F2EFE8`                    | Quiet sunken surfaces, chip tracks             |
| `hairline`         | `rgba(27,47,31,0.08)`        | Default border / divider                       |
| `hairlineStrong`   | `rgba(27,47,31,0.14)`        | Stronger divider                               |
| `ink`              | `#141814`                    | Primary text                                   |
| `ink2`             | `#4A524B`                    | Secondary text                                 |
| `ink3`             | `#8A8F88`                    | Tertiary / meta                                |
| `ink4`             | `#B8BAB4`                    | Placeholders, chevrons                         |
| `danger`           | `#B42318`                    | Errors                                         |

### Radii (px)
`sm 10` · `md 14` · `lg 20` · `xl 28` · `pill 999`

### Spacing scale (4pt grid, px)
`s1 4` · `s2 8` · `s3 12` · `s4 16` · `s5 20` · `s6 24` · `s7 32` · `s8 40` · `s9 56`

### Typography

| Role     | Stack                                                    | Notes                          |
| -------- | -------------------------------------------------------- | ------------------------------ |
| UI       | IBM Plex Sans Arabic → IBM Plex Sans → system            | All UI chrome, labels, headers |
| Arabic display | IBM Plex Sans Arabic → Noto Kufi Arabic            | Large Arabic headlines         |
| Quran    | Noto Naskh Arabic → Amiri → Scheherazade New → serif     | Quranic verses, hadith متن, duas |
| Numerals | IBM Plex Sans → ui-monospace                              | Latin digits, mono contexts    |

**Font files to bundle in Flutter:** IBM Plex Sans Arabic (weights 300/400/500/600/700), Noto Naskh Arabic (400/500/600/700). All available from Google Fonts and free to redistribute.

**Arabic-Indic numerals** (٠١٢٣٤٥٦٧٨٩) are used in most places; the `toAr(n)` helper in `tokens.jsx` shows the mapping. Latin digits are used only for version strings and similar.

### Iconography

One thin-line icon set, 1.5px stroke, rounded caps/joins, 24×24 viewBox. All paths in `ICONS` object in `tokens.jsx`. Icon names:

`home, azkar, quran, settings, compass, mosque, heart, share, copy, search, play, pause, bookmark, chevR, chevL, chevD, chevU, plus, minus, moon, sun, bell, tasbeeh, download, verse, calendar, location, vibrate, close, back, eye, names, ramadan, wudu, radio`

### Ornamentation

**Single ornament:** 8-point geometric star (`StarMark` and `StarOutline` in `tokens.jsx`). Used sparingly — app logo, streak completion marker, occasional accent. Nothing else decorative.

**Faint geometric watermark** (`GeoWatermark`) — ~5% opacity, offset outside card bounds. Only on hero surfaces (streak hero, dua of day, share CTA). Never on list rows.

### Direction & Layout

- **RTL throughout.** Set `Directionality(textDirection: TextDirection.rtl)` at app root.
- Icons that imply direction (back chevron, forward chevron) flip: in the prototype, `chevL` is used where visually the chevron points "forward" in RTL (toward the left). Verify each usage.

---

## Screen Inventory

25 unique screens. Every screen was designed on both iOS and Android frames where the layout or component set differs materially; where iOS and Android share identical layouts the single screen component is reused inside both frames.

| #  | Screen             | Source file            | Component             |
| -- | ------------------ | ---------------------- | --------------------- |
| 01 | Home / Dashboard   | `src/home.jsx`         | `HomeScreen`          |
| 02 | Azkar list         | `src/azkar.jsx`        | `AzkarListScreen`     |
| 03 | Azkar reading mode | `src/azkar.jsx`        | `AzkarReadingScreen`  |
| 04 | Tasbeeh counter    | `src/azkar.jsx`        | `TasbeehScreen`       |
| 05 | Surah list         | `src/quran.jsx`        | `SurahListScreen`     |
| 06 | Mushaf page        | `src/quran.jsx`        | `MushafScreen`        |
| 07 | Qibla compass      | `src/more.jsx`         | `QiblaScreen`         |
| 08 | Prayer times       | `src/more.jsx`         | `PrayerTimesScreen`   |
| 09 | Hijri calendar     | `src/more.jsx`         | `HijriCalendarScreen` |
| 10 | Settings           | `src/more.jsx`         | `SettingsScreen`      |
| 11 | Onboarding         | `src/extras.jsx`       | `OnboardingScreen`    |
| 12 | Nearby mosques     | `src/extras.jsx`       | `NearbyMosquesScreen` |
| 13 | Asma Allah (99 names) | `src/extras.jsx`    | `AsmaAllahScreen`     |
| 14 | Ramadan            | `src/extras.jsx`       | `RamadanScreen`       |
| 15 | Wudu guide         | `src/extras.jsx`       | `WuduScreen`          |
| 16 | Hadith of day      | `src/extras.jsx`       | `HadithScreen`        |
| 17 | Live Quran radio   | `src/extras.jsx`       | `LiveRadioScreen`     |
| 18 | Reciter picker     | `src/extras.jsx`       | `ReciterPickerScreen` |
| 19 | Search             | `src/final.jsx`        | `SearchScreen`        |
| 20 | Bookmarks          | `src/final.jsx`        | `BookmarksScreen`     |
| 21 | Profile / Streak   | `src/final.jsx`        | `ProfileScreen`       |
| 22 | Notifications      | `src/final.jsx`        | `NotificationsScreen` |
| 23 | Duas collection    | `src/final.jsx`        | `DuasScreen`          |
| 24 | Prayer tracker     | `src/final.jsx`        | `PrayerTrackerScreen` |
| 25 | About & Share      | `src/final.jsx`        | `AboutScreen`         |

---

## Screen Specs

Layout values are from the prototype source files — open each `.jsx` in `prototype/src/` to read exact JSX.

### Global patterns (shared across screens)

- **Frame dimensions** used for the mocks: 402×874px (iPhone 15 Pro / Pixel 8 approximation). Translate to Flutter as responsive layouts scaled to the device.
- **Screen top padding:** reserve `54px` of space for the native status bar, then `8px 20px 14px` for the header row.
- **Header row:** 36×36 rounded (`r_pill`) circular back button on the right (RTL lead), 1px `hairline` border, `surface` bg, `back` icon 16px. Title: 17px/600 `ink` with optional 12px/`ink3` subtitle.
- **List card pattern:** `surface` bg, 14px (`r_md`) radius, `1px hairline` border, `overflow: hidden`. Rows are `14px 16px` padding. Dividers are full-width `Hair` with `inset: 16` (16px inset from each side).
- **Section label:** 11px, 600 weight, `ink3` color, `marginBottom: 10`, sits above each card.
- **Tap targets** minimum 44×44 for touchable elements (buttons, toggles, row affordances).

### 01 · Home / Dashboard

See `src/home.jsx`.

- Warm `bg` page. Greeting line + city + date row at top.
- **Next-prayer hero card:** dark `ink` background, rounded `r_lg`, `GeoWatermark` at 7% opacity upper-right. Prayer name (Arabic), large countdown `HH:MM` in `fontArabic` at ~52px/300 weight, Hijri date under it. ~26×22 padding.
- **Quick-actions grid:** 2×3 of equal tiles. Each tile `surface`, `r_md`, 16px padding, icon in `primarySoft` circle top, label below (13px/500).
- **Verse of the day card:** `goldSoft` tint, Quranic font for the verse, small reference chip.
- Bottom tab bar: 5 tabs (Home / Azkar / Quran / Qibla / More). Active tab has `primary` icon color and 2px top accent.

### 02 · Azkar list

See `src/azkar.jsx` — `AzkarListScreen`.

- Category grid of tinted cards. Each card has a soft tint bg (one of `goldSoft`, `primarySoft`, cool blue-green, etc.), icon, title, dhikr count (Arabic-Indic). 16px/12px padding. Radius `r_md`.

### 03 · Azkar reading mode

- Dark calm vertical layout. One zikr per "card" with: Arabic text (Quranic font, 22–24px), latin reference line (`ink3`, 11px), counter pill on bottom-right showing remaining repetitions.
- Tap anywhere decrements counter. When it hits 0, the card fades and the next zikr slides up.
- Top of screen: category title + progress chip (e.g. "٣/٢٨").

### 04 · Tasbeeh counter

- Centered circular ring widget. Outer ring of 33 tick marks that light up sequentially in `primary`. Inner: large count (`fontArabic`, ~96px/300, `ink`), small "/٣٣" beneath.
- Below the ring: current dhikr text (Quranic font), change-dhikr row, reset + vibrate toggle.

### 05 · Surah list

- **Continue-reading anchor** at the top — `primary` filled card, last surah/ayah reference, resume CTA.
- Search bar (`search` icon, placeholder).
- Surah rows: numeral in an 8-point-star-framed square on the right (number in Arabic-Indic), surah name in `fontArabic` (17–18px/500), meta (`الجزء N · X آية · مكية/مدنية`) in 12px/`ink3`.

### 06 · Mushaf page

- Cream page bg (slightly warmer than `bg`). Decorative header band with surah name in ornamental frame.
- Verse text block: Quranic font, ~24px, `lineHeight: 2.0`, `textAlign: justify`, RTL. Verse numbers in circled Arabic-Indic glyphs (🕉-style — use a `Stack` with circled container).
- Bottom bar: page number + juz indicator.

### 07 · Qibla compass

- Large dial graphic with cardinal labels (ش/غ/ج/ق) and a single pointer that rotates toward the Kaaba. Current heading numerical readout below.
- "Align with" chip: "قبلة مكة المكرمة".
- Small map/coordinates footer.

### 08 · Prayer times

- Location row at top (`location` icon + city + method chip).
- 5 prayer rows. Each: prayer name (`fontArabic`), time (Arabic-Indic), sub-time (shuruq for fajr), subtle icon on the side. The **active** (next) prayer has a filled `ink` background with white text; past prayers are dimmed; future are neutral.

### 09 · Hijri calendar

- Oversized today hero at top: large Hijri day number (`fontArabic`, ~72px/300), full Hijri date, Gregorian date meta.
- 7-col calendar grid beneath. Today cell has `primary` ring. Friday column subtly tinted `goldSoft`. Month nav chevrons.

### 10 · Settings

- Grouped list. Groups: Appearance (theme, language, font scale), Prayer (location, calculation method, asr school, adjustments), Azkar (reminder frequency, vibration, auto-advance), Data (backup, clear cache), About.
- Each row: icon in tinted square, label, right-aligned value chip or chevron.

### 11 · Onboarding

- 3 steps. Hero slot at top (placeholder for illustration — 200px tall, `primarySoft` with centered 8-point star), title (20px/600), body (14px/`ink2` / 1.6 line-height), 3-dot progress indicator, primary CTA pill at bottom.

### 12 · Nearby mosques

- Stylized top "map" — not a real map. A `surfaceSunk` panel with a few stylized cross streets drawn in `hairline`, a `primary` location pin at center, circles at radius distances.
- Distance-sorted list below: mosque name, street, distance in Arabic-Indic km, directions chevron.

### 13 · Asma Allah (99 names)

- Grid-feel list (2 columns). Each tile: Arabic name in large Quranic font, numeral in a `goldSoft` square frame top-right, transliteration in Latin 11px/`ink3`, meaning 12px/`ink2`. Tap expands to detail with audio play.

### 14 · Ramadan

- Iftar/Suhoor countdown hero — dark `ink` bg with `GeoWatermark`, large countdown, switches between iftar / suhoor based on time.
- 30-day meter: 30 small pill segments horizontally, filled ones in `primary`, today pulsing.
- 2×2 sub-feature grid: Taraweeh tracker, Zakat calc, Duaa night-of-Qadr, Charity.

### 15 · Wudu guide

- Vertical numbered rail (1–8). Current step is expanded with a visual placeholder, audio-play pill, and description. Other steps are collapsed rows with number, label, checkmark if done.

### 16 · Hadith of day

- Source chip (`goldSoft` pill with "صحيح البخاري · ٥٠٦٣").
- Matn in Quranic font (Quranic typography rules — full justify, 2.0 line-height).
- Sharh (explanation) in UI font below. Archive button → list of past hadiths.

### 17 · Live Quran radio

- Now-playing hero: large reciter name, surah + verse range, small 8-point-star badge.
- Waveform visual (stylized — 40 vertical bars, heights randomized within range).
- Transport controls: prev / play-pause / next. Volume slider. Station switcher chips.
- Persistent mini-player at bottom (40px tall, `surface`, play/pause + reciter name + close).

### 18 · Reciter picker

- Scrollable list of ~17 reciters. Each row: photo placeholder circle, name (`fontArabic`), style description (مجود / مرتل / حفص), download state chip:
  - Not downloaded → "تحميل" with `download` icon
  - Downloading → progress bar inline
  - Downloaded → checkmark in `primary`
- Search at top, filter chips for riwayah.

### 19 · Search

- Large search input with `search` icon, filled query ("الكهف"), clear button.
- Filter chips row: All · Azkar · Quran · Duas · Names (active = `ink` filled).
- Result count label ("٢٤ نتيجة").
- Results card — rows with a type chip (e.g. "سورة"), Arabic text in Quranic font, meta line.
- Recent-searches as ghost pills below.

### 20 · Bookmarks

- 3 labeled groups (Quran / Azkar / Duas). Each group title row shows count.
- Rows: 38×38 icon tile (`goldSoft` for Quran, `primarySoft` for others), title (font depending on source), meta, filled `bookmark` icon (gold) on left.

### 21 · Profile / Streak

- **Streak hero** — dark `ink` bg, `GeoWatermark`, "سلسلة مستمرة" label, 56px/300 number + "يوماً", last-dhikr timestamp.
- Week strip: 7 squares, done days filled white with 8-point star inside, today has dashed border if incomplete.
- Stats card: 3 rows (prayers / azkar / recitation) with label, tag, large Arabic-Indic value.
- Achievements grid — 3 tiles, each with icon in colored circle and label. Locked achievements are at 0.5 opacity.

### 22 · Notifications

- Toggle-row patterns. Each prayer row: name (`fontArabic`), sub (time + adhan choice), 46×28 pill toggle (`primary` when on, `hairlineStrong` when off), 24px thumb.
- Adhan sound group — radio rows with 20×20 circle + 10×10 inner dot when selected, play icon when selected.
- Azkar reminder group — same toggle pattern as prayers.

### 23 · Duas

- Featured dua card (`surface`, `GeoWatermark` at 4%, "دعاء اليوم" gold micro-label, Quranic font 22px / 1.9 line-height, reference under a hairline divider, row of play / copy / bookmark icons).
- 6 category rows in one card, each with `primarySoft` icon tile + title + count + chevron.

### 24 · Prayer tracker

- Today hero: "اليوم · السبت", "٣ / ٥ صلوات", status chip ("في الموعد"). Row of 5 prayer squares below — completed ones `primary` filled with white check, pending are dashed border.
- Weekly history card: 7 rows. Each row: day + Hijri date, 5 horizontal bar segments showing each prayer's state, count `N/٥`.
- "View more" pill at bottom.

### 25 · About & Share

- Logo block centered: 88×88 dark `ink` rounded-square with large gold 8-point star, version meta.
- Share CTA card (`primary` bg, `GeoWatermark` at 10%, hadith quote, share + rate buttons).
- Info card (4 rows: data sources, scholars, recitation rights, website).
- Links card (privacy / terms / OSS / contact).
- Footer credit line.

---

## Interactions & Behavior

High-level interaction patterns to implement:

- **Tab bar navigation** — Home / Azkar / Quran / Qibla / More. Persisted across app launches.
- **Tasbeeh:**
  - Tap anywhere on the circle decrements (or increments toward target).
  - Haptic feedback on each tap (light), stronger on target reached.
  - Auto-advance to next dhikr after target if the list mode is active.
- **Azkar reading:** tap card → decrement counter → fade + next on 0. Left/right swipe should navigate between dhikr items.
- **Qibla:** uses device compass + Kaaba heading. Pointer rotates continuously. Show "ضع هاتفك مسطحاً" if tilt >30°.
- **Prayer times:** "Active" prayer is determined by `now` vs computed times. Active state should re-render at each prayer boundary.
- **Search:** debounced 200ms, client-side fuzzy match across a local index.
- **Bookmarks:** tapping the filled bookmark icon on a row unbookmarks with a 1s undo snackbar.
- **Streak:** one completion per calendar day counts. Missing a day resets. Streak updates at Fajr, not midnight.
- **Notifications:** per-prayer toggles, each with its own sound selection. Respect OS DND.
- **Mushaf:** horizontal swipe between pages with a subtle page-curl. Double-tap a verse to bookmark.

## State Management

Follow the existing app's conventions. Likely additions:

- `streakService` — tracks daily completion, persists to local storage, exposes current streak + week.
- `bookmarksService` — list of `{ id, type, ref, timestamp }`. Backed by local DB.
- `searchIndex` — pre-built offline index of all Azkar + Surah names + Dua categories + Name-of-Allah entries.
- `playerController` — global Quran audio, survives navigation, exposes mini-player state.
- `reminderService` — schedules local notifications per settings.

## Assets

- **Fonts:** IBM Plex Sans Arabic, Noto Naskh Arabic — bundle from Google Fonts.
- **Icons:** custom SVG path set in `prototype/src/tokens.jsx`. Convert to Flutter (options: `flutter_svg` with raw strings, or `CustomPainter` for core ones).
- **Ornaments:** 8-point star and `GeoWatermark` — reproduce as Flutter `CustomPainter`.
- **No bitmap assets** required from the designer. Reciter photos, mosque illustrations, onboarding art are placeholders — product can add real images later.

## Files in this bundle

```
prototype/
  Azkar App Design.html     ← open this in a browser to explore all 25 screens
  frames/
    ios-frame.jsx           ← iOS status bar + dynamic island approximation
    android-frame.jsx       ← Android status bar + nav
    design-canvas.jsx       ← canvas wrapper (panning, zoom, section labels)
  src/
    tokens.jsx              ← design system (colors, spacing, type, icons, ornaments)
    home.jsx                ← screen 01
    azkar.jsx               ← screens 02–04
    quran.jsx               ← screens 05–06
    more.jsx                ← screens 07–10
    extras.jsx              ← screens 11–18
    final.jsx               ← screens 19–25
```

To preview: open `prototype/Azkar App Design.html` in any modern browser. All 25 screens render on a zoomable/pannable canvas. Press the toolbar **Tweaks** toggle (if opened inside the original design tool) to adjust accent color, Arabic scale, and density.

---

## Translation notes (HTML → Flutter)

- Every `T.hairline` border becomes `BorderSide(color: TokensColors.hairline, width: 1)`.
- Every `T.r_md` is `BorderRadius.circular(14)`.
- Every `fontFamily: T.fontQuran` text becomes `TextStyle(fontFamily: 'NotoNaskhArabic', ...)`.
- The `ScreenShell` wrapper pattern maps to a reusable `AppScaffold` widget.
- Rows with `Hair inset={16}` dividers → `Divider(indent: 16, endIndent: 16, height: 1, color: hairline)`.
- Toggle pill is a `Switch` with custom `activeColor: primary`; the exact dimensions (46×28, 24 thumb) should be matched via a `Transform.scale` if needed, or a custom-built switch widget.
- RTL text direction: rely on `Directionality(textDirection: TextDirection.rtl)` globally. Horizontal padding/margins set via `EdgeInsetsDirectional`.
- Arabic-Indic numerals: convert at the presentation layer only. Keep underlying model values as Latin ints.
