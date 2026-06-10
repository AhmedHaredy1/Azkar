# Implementation Plan: Azkar — Islamic Mobile App (Hisn Al-Muslim Style)

## Overview

A production-ready Flutter mobile application providing a comprehensive Islamic daily companion. The app bundles offline Azkar (Morning/Evening/Sleep/Various), Duas, full Quran reader, digital Sebha (tasbeeh counter), location-based prayer times, compass-based Qibla direction, and a scheduled notification system. The primary language is Arabic (RTL), targeting Android first with iOS readiness.

Ahmed Haredy is an experienced SAP ABAP developer building his first Flutter app. This plan is structured to be beginner-approachable while maintaining professional architecture standards.

---

## Section 1: Product Breakdown

### 1.1 Core Features and Sub-Features

**Feature 1: Splash Screen (شاشة البداية)**
- Display app logo and name for 2 seconds
- Check first-launch status (show onboarding or go to home)
- Initialize local database (Hive)

**Feature 2: Onboarding (شاشة الترحيب) — First Launch Only**
- 3 swipeable pages explaining app features
- Request location permission (for prayer times)
- Request notification permission
- "Get Started" button leading to Home

**Feature 3: Home Dashboard (الرئيسية)**
- Greeting based on time of day (صباح الخير / مساء الخير)
- Next prayer time countdown card
- Quick-access grid: Azkar, Quran, Sebha, Prayer Times, Qibla, Duas
- Daily Ayah card (random verse displayed each day)
- Morning/Evening Azkar shortcut buttons (contextual — morning button before Dhuhr, evening button after)

**Feature 4: Azkar (الأذكار)**
- Sub-feature 4a: Category List — Morning (أذكار الصباح), Evening (أذكار المساء), Sleep (أذكار النوم), After Prayer (أذكار بعد الصلاة), Waking Up (أذكار الاستيقاظ), Entering Mosque, Leaving Mosque, Entering Home, Various (أذكار متنوعة)
- Sub-feature 4b: Azkar Detail Screen — Shows each dhikr text (Arabic), repetition count, counter button (tap to decrement), vibration on each tap, auto-advance to next dhikr when count reaches zero
- Sub-feature 4c: Progress indicator — "3 of 12 Azkar completed"
- Sub-feature 4d: Completion screen — "أحسنت! أتممت أذكار الصباح" with share button
- Sub-feature 4e: Favorites — Mark individual Azkar as favorites for quick access

**Feature 5: Duas (الأدعية)**
- Sub-feature 5a: Category list — Quran Duas, Prophet Duas, Travel, Sickness, Exams, Rain, etc.
- Sub-feature 5b: Dua detail — Arabic text, optional transliteration, source/reference
- Sub-feature 5c: Copy and share individual Dua
- Sub-feature 5d: Favorites

**Feature 6: Quran (القرآن الكريم)**
- Sub-feature 6a: Surah list — 114 Surahs with Arabic name, English name, number of Ayahs, Makki/Madani badge
- Sub-feature 6b: Surah reader — Bismillah header (except Al-Tawba), Ayahs displayed in traditional Arabic typography, Ayah numbers in Arabic numerals
- Sub-feature 6c: Juz (Part) browser — Navigate by Juz (1-30)
- Sub-feature 6d: Bookmark — Save last read position, resume reading
- Sub-feature 6e: Search — Search Quran text by Arabic keywords
- Sub-feature 6f: Audio recitation — Deferred to future enhancement (Phase 2)

**Feature 7: Sebha / Tasbeeh Counter (السبحة)**
- Sub-feature 7a: Large circular tap area in center of screen
- Sub-feature 7b: Counter display (current count, total cumulative)
- Sub-feature 7c: Preset dhikr phrases — سبحان الله, الحمد لله, الله أكبر, لا إله إلا الله, custom text
- Sub-feature 7d: Vibration feedback on each tap
- Sub-feature 7e: Reset button with confirmation dialog
- Sub-feature 7f: Target count (33, 99, 100, custom) with completion notification
- Sub-feature 7g: Persist count across sessions

**Feature 8: Prayer Times (مواقيت الصلاة)**
- Sub-feature 8a: Today's 5 prayer times + Sunrise (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha)
- Sub-feature 8b: Next prayer highlighted with countdown timer
- Sub-feature 8c: Location-based calculation using Adhan package (offline calculation, not API)
- Sub-feature 8d: Calculation method selector (Egyptian General Authority, Umm Al-Qura, ISNA, Muslim World League, etc.)
- Sub-feature 8e: Manual location override (city search)
- Sub-feature 8f: Monthly calendar view (deferred to Phase 2)

**Feature 9: Qibla Direction (اتجاه القبلة)**
- Sub-feature 9a: Compass needle pointing toward Kaaba
- Sub-feature 9b: Degree display (e.g., 135.4 degrees)
- Sub-feature 9c: Calibration instruction ("Move your phone in a figure-8 pattern")
- Sub-feature 9d: Location-based Qibla angle calculation

**Feature 10: Notifications (التنبيهات)**
- Sub-feature 10a: Prayer time Adhan notifications (per-prayer toggle)
- Sub-feature 10b: Morning Azkar reminder (configurable time, default 06:00)
- Sub-feature 10c: Evening Azkar reminder (configurable time, default 16:00)
- Sub-feature 10d: Custom reminder (user picks any time)
- Sub-feature 10e: Notification sound selection (silent, default, custom)

**Feature 11: Settings (الإعدادات)**
- Sub-feature 11a: Prayer time calculation method
- Sub-feature 11b: Notification preferences (on/off per type)
- Sub-feature 11c: Font size slider (for Azkar/Quran text)
- Sub-feature 11d: Theme (Light/Dark/System)
- Sub-feature 11e: Location settings
- Sub-feature 11f: About / Contact / Rate App
- Sub-feature 11g: Reset Sebha counter
- Sub-feature 11h: Language toggle (Arabic only for MVP, multi-language in future)

**Feature 12: Quran Listen (استمع للقرآن)**
- Sub-feature 12a: Surah selector (1-114 with Arabic names)
- Sub-feature 12b: Moshaf type filter (مرتل, مجود, معلم, ورش, etc.)
- Sub-feature 12c: Reciter list — filtered by surah availability per moshaf
- Sub-feature 12d: Full-surah streaming via mp3quran.net API
- Sub-feature 12e: Mini audio player bar (play/pause, progress, reciter name)
- Sub-feature 12f: API response caching (24h refresh)

**Feature 13: Live Islamic Radio (البث المباشر)**
- Sub-feature 13a: Saudi Quran Radio (إذاعة القرآن الكريم)
- Sub-feature 13b: Saudi Sunnah Radio (إذاعة السنة النبوية)
- Sub-feature 13c: Egypt Quran Radio (إذاعة القرآن الكريم من مصر)
- Sub-feature 13d: LIVE indicator with play/stop controls

**Feature 14: Hajj & Umrah Guide (دليل الحج والعمرة)**
- Sub-feature 14a: Umrah step-by-step guide (إحرام → طواف → سعي → تحلل)
- Sub-feature 14b: Hajj step-by-step guide (Day 8-13 Dhul Hijjah)
- Sub-feature 14c: Duas for each ritual/location
- Sub-feature 14d: Prohibitions of Ihram (محظورات الإحرام)
- Sub-feature 14e: Offline — bundled JSON data

### 1.2 User Flows

**Flow A: App Open (cold start)**
Splash (2s) --> Check first launch --> [First time: Onboarding --> Home] / [Returning: Home]

**Flow B: Morning Azkar**
Home --> Tap "أذكار الصباح" --> Azkar Detail --> Tap counter for each dhikr --> Auto-advance --> Completion screen --> Back to Home

**Flow C: Quran Reading**
Home --> Tap "القرآن" --> Surah List --> Tap Surah --> Read Ayahs --> Bookmark --> Back

**Flow D: Sebha**
Home --> Tap "السبحة" --> Select dhikr phrase --> Tap center circle repeatedly --> See count --> Reset or continue

**Flow E: Prayer Times**
Home --> See next prayer countdown on dashboard card --> Tap card --> Full Prayer Times screen --> See all 5 times --> Go to Settings to change calculation method

**Flow F: Qibla**
Home --> Tap "القبلة" --> Grant location permission (if not yet) --> See compass with Qibla direction --> Calibrate if needed

---

## Section 2: Technical Architecture

### 2.1 Architecture Pattern: Clean Architecture (Feature-First)

Three layers per feature:
- **Presentation Layer** — Screens (pages), Widgets, Riverpod Providers (state)
- **Domain Layer** — Models (entities), Repositories (abstract interfaces)
- **Data Layer** — Repository implementations, Local data sources (Hive), JSON loaders

### 2.2 State Management: Riverpod 2.x (with code generation)

Why Riverpod:
- Compile-safe, testable, no BuildContext dependency for providers
- Supports async (FutureProvider, StreamProvider) natively
- flutter_riverpod + riverpod_annotation for code generation
- Excellent for a first Flutter project — explicit and traceable

Provider types to use:
- `Provider` — for repository instances, computed values
- `NotifierProvider` — for mutable state (Sebha counter, Azkar progress)
- `FutureProvider` — for async data loading (prayer times, Quran data)
- `StreamProvider` — for compass heading stream (Qibla)

### 2.3 Navigation: go_router

- Declarative routing
- Deep link support (future: open specific Surah via link)
- Shell route for bottom navigation bar on Home/Azkar/Quran/Settings

### 2.4 Folder Structure

```
lib/
├── main.dart                          # Entry point, ProviderScope, MaterialApp.router
├── app.dart                           # MaterialApp.router configuration, theme, locale
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            # Color palette (Islamic green/gold theme)
│   │   ├── app_strings.dart           # Static Arabic strings (non-data)
│   │   ├── app_assets.dart            # Asset paths (images, JSON, fonts)
│   │   └── app_dimensions.dart        # Spacing, radius, sizing constants
│   ├── theme/
│   │   ├── app_theme.dart             # ThemeData for light and dark modes
│   │   └── text_styles.dart           # Arabic text styles (Amiri, Scheherazade fonts)
│   ├── router/
│   │   └── app_router.dart            # go_router configuration, all routes
│   ├── services/
│   │   ├── notification_service.dart  # flutter_local_notifications wrapper
│   │   ├── location_service.dart      # Geolocator wrapper
│   │   ├── compass_service.dart       # flutter_compass wrapper
│   │   ├── storage_service.dart       # Hive initialization and box access
│   │   └── audio_service.dart         # (Future) audio playback
│   ├── utils/
│   │   ├── date_utils.dart            # Hijri date helpers
│   │   ├── arabic_number_utils.dart   # Convert 1,2,3 to ١,٢,٣
│   │   └── prayer_calculation.dart    # Adhan package wrapper
│   └── widgets/
│       ├── app_scaffold.dart          # Shared scaffold with RTL AppBar
│       ├── loading_widget.dart
│       ├── error_widget.dart
│       └── arabic_text.dart           # Text widget with Arabic font defaults
│
├── features/
│   ├── splash/
│   │   └── presentation/
│   │       └── splash_screen.dart
│   │
│   ├── onboarding/
│   │   └── presentation/
│   │       ├── onboarding_screen.dart
│   │       └── widgets/
│   │           └── onboarding_page.dart
│   │
│   ├── home/
│   │   └── presentation/
│   │       ├── home_screen.dart
│   │       ├── providers/
│   │       │   └── home_provider.dart
│   │       └── widgets/
│   │           ├── prayer_countdown_card.dart
│   │           ├── quick_access_grid.dart
│   │           └── daily_ayah_card.dart
│   │
│   ├── azkar/
│   │   ├── data/
│   │   │   ├── azkar_local_source.dart       # Loads from JSON
│   │   │   └── azkar_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── azkar_category.dart
│   │   │   │   └── dhikr.dart
│   │   │   └── repositories/
│   │   │       └── azkar_repository.dart      # Abstract
│   │   └── presentation/
│   │       ├── azkar_categories_screen.dart
│   │       ├── azkar_detail_screen.dart
│   │       ├── azkar_completion_screen.dart
│   │       ├── providers/
│   │       │   ├── azkar_provider.dart
│   │       │   └── azkar_progress_provider.dart
│   │       └── widgets/
│   │           ├── azkar_category_card.dart
│   │           ├── dhikr_card.dart
│   │           └── dhikr_counter_button.dart
│   │
│   ├── duas/
│   │   ├── data/
│   │   │   ├── duas_local_source.dart
│   │   │   └── duas_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── dua_category.dart
│   │   │   │   └── dua.dart
│   │   │   └── repositories/
│   │   │       └── duas_repository.dart
│   │   └── presentation/
│   │       ├── duas_categories_screen.dart
│   │       ├── dua_detail_screen.dart
│   │       ├── providers/
│   │       │   └── duas_provider.dart
│   │       └── widgets/
│   │           ├── dua_category_card.dart
│   │           └── dua_text_card.dart
│   │
│   ├── quran/
│   │   ├── data/
│   │   │   ├── quran_local_source.dart
│   │   │   └── quran_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── surah.dart
│   │   │   │   ├── ayah.dart
│   │   │   │   └── bookmark.dart
│   │   │   └── repositories/
│   │   │       └── quran_repository.dart
│   │   └── presentation/
│   │       ├── surah_list_screen.dart
│   │       ├── surah_reader_screen.dart
│   │       ├── providers/
│   │       │   ├── quran_provider.dart
│   │       │   ├── bookmark_provider.dart
│   │       │   └── quran_search_provider.dart
│   │       └── widgets/
│   │           ├── surah_list_tile.dart
│   │           ├── ayah_text_widget.dart
│   │           ├── bismillah_header.dart
│   │           └── surah_header_widget.dart
│   │
│   ├── sebha/
│   │   ├── domain/
│   │   │   └── models/
│   │   │       └── sebha_state.dart
│   │   └── presentation/
│   │       ├── sebha_screen.dart
│   │       ├── providers/
│   │       │   └── sebha_provider.dart
│   │       └── widgets/
│   │           ├── sebha_circle.dart
│   │           ├── sebha_counter_display.dart
│   │           └── dhikr_selector.dart
│   │
│   ├── prayer_times/
│   │   ├── data/
│   │   │   └── prayer_times_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── prayer_time.dart
│   │   │   └── repositories/
│   │   │       └── prayer_times_repository.dart
│   │   └── presentation/
│   │       ├── prayer_times_screen.dart
│   │       ├── providers/
│   │       │   └── prayer_times_provider.dart
│   │       └── widgets/
│   │           ├── prayer_time_row.dart
│   │           └── next_prayer_card.dart
│   │
│   ├── qibla/
│   │   └── presentation/
│   │       ├── qibla_screen.dart
│   │       ├── providers/
│   │       │   └── qibla_provider.dart
│   │       └── widgets/
│   │           └── qibla_compass.dart
│   │
│   ├── notifications/
│   │   ├── domain/
│   │   │   └── models/
│   │   │       └── notification_setting.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── notification_provider.dart
│   │       └── (no screen — managed from Settings)
│   │
│   └── settings/
│       └── presentation/
│           ├── settings_screen.dart
│           ├── providers/
│           │   └── settings_provider.dart
│           └── widgets/
│               ├── theme_selector.dart
│               ├── font_size_slider.dart
│               ├── calculation_method_picker.dart
│               └── notification_toggles.dart
│
├── l10n/                              # (Future) localization files
│   └── app_ar.arb
│
assets/
├── data/
│   ├── azkar.json                     # All Azkar data (categories + items)
│   ├── duas.json                      # All Duas data (categories + items)
│   └── quran.json                     # Full Quran text (114 Surahs, all Ayahs)
├── images/
│   ├── app_logo.png
│   ├── splash_bg.png
│   ├── qibla_compass.png
│   ├── kaaba_icon.png
│   ├── onboarding_1.png
│   ├── onboarding_2.png
│   └── onboarding_3.png
├── fonts/
│   ├── Amiri-Regular.ttf             # For Quran text
│   ├── Amiri-Bold.ttf
│   ├── ScheherazadeNew-Regular.ttf   # For Azkar/Dua text
│   └── Cairo-Regular.ttf             # For UI text (modern Arabic)
└── icons/
    ├── azkar_icon.svg
    ├── quran_icon.svg
    ├── sebha_icon.svg
    ├── prayer_icon.svg
    ├── qibla_icon.svg
    └── dua_icon.svg
```

### 2.5 Key Packages (pubspec.yaml)

| Package | Version (approx) | Purpose |
|---------|------------------|---------|
| `flutter_riverpod` | ^2.5.x | State management |
| `riverpod_annotation` | ^2.3.x | Code generation for providers |
| `go_router` | ^14.x | Declarative routing |
| `hive_flutter` | ^1.1.x | Local storage (fast, no SQL) |
| `hive_ce` | ^2.x | Community edition of Hive (actively maintained) |
| `flutter_local_notifications` | ^17.x | Scheduled notifications |
| `adhan` | ^2.0.x | Prayer time calculation (offline, no API) |
| `geolocator` | ^12.x | GPS location |
| `flutter_compass` | ^0.8.x | Device compass heading |
| `permission_handler` | ^11.x | Runtime permissions |
| `flutter_svg` | ^2.x | SVG icon rendering |
| `share_plus` | ^9.x | Share Azkar/Dua text |
| `vibration` | ^2.x | Haptic feedback for Sebha/Azkar |
| `hijri` | ^3.x | Hijri calendar date |
| `flutter_native_splash` | ^2.4.x | Native splash screen |
| `flutter_launcher_icons` | ^0.14.x | App icon generation |
| `build_runner` | ^2.4.x | (dev) Code generation runner |
| `riverpod_generator` | ^2.4.x | (dev) Riverpod code gen |
| `hive_generator` | ^2.x | (dev) Hive TypeAdapter gen |
| `flutter_test` | SDK | (dev) Testing |
| `mocktail` | ^1.x | (dev) Mocking for tests |

### 2.6 Navigation Structure (go_router)

```
Routes:
  /splash                              → SplashScreen
  /onboarding                          → OnboardingScreen
  /                                    → ShellRoute (bottom nav)
    /home                              → HomeScreen (tab 0)
    /azkar                             → AzkarCategoriesScreen (tab 1)
    /quran                             → SurahListScreen (tab 2)
    /settings                          → SettingsScreen (tab 3)
  /azkar/:categoryId                   → AzkarDetailScreen
  /azkar/:categoryId/complete          → AzkarCompletionScreen
  /duas                                → DuasCategoriesScreen
  /duas/:categoryId                    → DuaDetailScreen
  /quran/:surahNumber                  → SurahReaderScreen
  /sebha                               → SebhaScreen
  /prayer-times                        → PrayerTimesScreen
  /qibla                               → QiblaScreen
```

Bottom Navigation Tabs (4 tabs):
- Home (الرئيسية) — icon: home
- Azkar (الأذكار) — icon: book
- Quran (القرآن) — icon: menu_book
- Settings (الإعدادات) — icon: settings

Sebha, Prayer Times, Qibla, and Duas are accessed from the Home screen grid, not from bottom nav tabs.

---

## Section 3: Data Design

### 3.1 Models

**AzkarCategory**
```
- id: String (e.g., "morning", "evening", "sleep")
- nameAr: String (e.g., "أذكار الصباح")
- icon: String (asset path or icon name)
- sortOrder: int
- azkarList: List<Dhikr>
```

**Dhikr**
```
- id: int
- categoryId: String
- textAr: String (the Arabic text of the dhikr)
- repetitions: int (e.g., 3, 7, 10, 33)
- source: String (e.g., "صحيح البخاري", "صحيح مسلم")
- note: String? (optional fadl/benefit text)
```

**DuaCategory**
```
- id: String (e.g., "quran_duas", "prophet_duas", "travel")
- nameAr: String
- icon: String
- sortOrder: int
- duasList: List<Dua>
```

**Dua**
```
- id: int
- categoryId: String
- textAr: String
- source: String
- note: String?
```

**Surah**
```
- number: int (1-114)
- nameAr: String (e.g., "الفاتحة")
- nameEn: String (e.g., "Al-Fatiha")
- ayahCount: int
- revelationType: String ("meccan" | "medinan")
- ayahs: List<Ayah>
```

**Ayah**
```
- number: int (Ayah number within Surah)
- numberInQuran: int (global Ayah number, 1-6236)
- textAr: String (Arabic text with tashkeel)
- juz: int (1-30)
- page: int (Mushaf page number)
```

**Bookmark**
```
- surahNumber: int
- ayahNumber: int
- createdAt: DateTime
```

**PrayerTime**
```
- name: String (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha)
- nameAr: String (الفجر, الشروق, الظهر, العصر, المغرب, العشاء)
- time: DateTime
- isNext: bool (calculated field — is this the upcoming prayer?)
```

**SebhaState**
```
- currentCount: int
- totalCount: int (cumulative across all sessions)
- targetCount: int (33, 99, 100, or custom)
- selectedDhikr: String (e.g., "سبحان الله")
```

**NotificationSetting**
```
- id: String (e.g., "fajr", "dhuhr", "morning_azkar", "evening_azkar")
- nameAr: String
- isEnabled: bool
- customTime: DateTime? (for Azkar reminders)
```

**AppSettings**
```
- themeMode: String ("light", "dark", "system")
- fontSize: double (14.0 to 30.0)
- calculationMethod: String (e.g., "egyptian", "umm_al_qura")
- latitude: double?
- longitude: double?
- cityName: String?
- isFirstLaunch: bool
```

### 3.2 Local Storage with Hive

Hive boxes (each box is like a lightweight table):

| Box Name | Content | Type |
|----------|---------|------|
| `settings` | AppSettings | Single object |
| `bookmarks` | Quran bookmarks | List of Bookmark |
| `favorites_azkar` | Favorited Dhikr IDs | List of int |
| `favorites_duas` | Favorited Dua IDs | List of int |
| `sebha` | SebhaState | Single object |
| `notifications` | NotificationSetting list | List of NotificationSetting |

Azkar, Duas, and Quran data are NOT stored in Hive. They are loaded from bundled JSON files in assets. This is because:
- The data is read-only (user does not modify Azkar text)
- JSON is simpler to manage and update
- Hive is used only for user-generated or preference data

### 3.3 JSON Data Structure

**assets/data/azkar.json**
```json
{
  "categories": [
    {
      "id": "morning",
      "nameAr": "أذكار الصباح",
      "icon": "sunrise",
      "sortOrder": 1,
      "azkar": [
        {
          "id": 1,
          "textAr": "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ...",
          "repetitions": 1,
          "source": "صحيح مسلم",
          "note": "تقال مرة واحدة"
        }
      ]
    }
  ]
}
```

**assets/data/quran.json**
```json
{
  "surahs": [
    {
      "number": 1,
      "nameAr": "الفاتحة",
      "nameEn": "Al-Fatiha",
      "ayahCount": 7,
      "revelationType": "meccan",
      "ayahs": [
        {
          "number": 1,
          "numberInQuran": 1,
          "textAr": "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
          "juz": 1,
          "page": 1
        }
      ]
    }
  ]
}
```

### 3.4 Data Sources for Content

- **Azkar Data**: Hisn Al-Muslim book (حصن المسلم). Available as open-source JSON from multiple GitHub repositories (e.g., `islamic-network/cdn` or `osamayy/azkar-db`). Will need to curate and validate.
- **Quran Data**: Available from `quran.com` API export or `tanzil.net` (provides verified, tashkeel-accurate Quran text as XML/JSON). Use the `uthmani` text type for proper Arabic rendering.
- **Duas Data**: Manually curated from authentic Hadith collections, or sourced from existing open-source Islamic apps.

---

## Section 4: UI/UX Plan

### 4.1 Design Language

- **Color Palette**: Deep Islamic green (#1B5E20) as primary, gold (#D4A847) as accent, cream/off-white (#FFF8E1) as background in light mode, dark charcoal (#1A1A2E) for dark mode
- **Typography**: Amiri font for Quran text (traditional Naskh), Scheherazade New for Azkar/Dua text, Cairo for UI elements (modern, clean Arabic font)
- **Icons**: Outlined style, Islamic geometric patterns for decorative elements
- **Cards**: Rounded corners (16px radius), subtle shadows, generous padding for Arabic text readability
- **Spacing**: Minimum 16px padding around text containers for comfortable Arabic reading

### 4.2 RTL Support Strategy

Flutter's `Directionality` widget and `MaterialApp`'s `locale` handle RTL automatically when configured correctly. Specific actions:

1. Set `locale: const Locale('ar')` in MaterialApp — this makes the entire app RTL by default
2. Use `TextDirection.rtl` as the default text direction
3. Use `Alignment.centerRight` instead of `centerLeft` for text alignment (or rely on auto-RTL)
4. All `Row` widgets, `ListView` items, and navigation will automatically flip
5. AppBar back button moves to the right side automatically
6. Bottom navigation labels are Arabic
7. Use `EdgeInsetsDirectional` instead of `EdgeInsets` where start/end matter
8. Test every screen by checking visual alignment after implementation

### 4.3 Screen-by-Screen Layout

**Screen 1: Splash Screen**
- Full-screen background (cream/green gradient)
- Centered app logo (Islamic geometric design)
- App name "رفيق المسلم" in large Amiri font below logo
- Subtle fade-in animation
- Duration: 2 seconds, then navigate

**Screen 2: Onboarding (3 pages)**
- Page 1: Image of prayer beads + text "أذكارك اليومية في مكان واحد" (Your daily Azkar in one place)
- Page 2: Image of mosque + text "مواقيت الصلاة واتجاه القبلة" (Prayer times and Qibla direction)
- Page 3: Image of Quran + text "المصحف الشريف في جيبك" (The Holy Quran in your pocket)
- Dot indicator at bottom
- "ابدأ" (Start) button on last page
- Skip button on first two pages

**Screen 3: Home Dashboard**
- Layout: Single-column scrollable
- Section 1 (top): Greeting + Hijri date + Gregorian date
- Section 2: Next prayer countdown card (prominent, colored card showing prayer name + time + countdown "بعد ٢:١٥:٣٠")
- Section 3: Quick Access Grid (2x3 grid of large tappable cards):
  - Row 1: أذكار الصباح | أذكار المساء
  - Row 2: القرآن | السبحة
  - Row 3: مواقيت الصلاة | القبلة
  - Row 4: الأدعية | (empty or "المزيد")
- Section 4: Daily Ayah card (decorative border, random verse, Surah reference)
- Bottom: Bottom Navigation Bar (4 tabs)

**Screen 4: Azkar Categories**
- AppBar title: "الأذكار"
- List of category cards (vertical list)
- Each card: Category icon (left/right depending on RTL) + Arabic name + item count badge
- Categories: أذكار الصباح, أذكار المساء, أذكار النوم, أذكار الاستيقاظ, أذكار بعد الصلاة, أذكار دخول المسجد, أذكار الخروج من المسجد, أذكار متنوعة
- Search bar at top (optional, Phase 2)

**Screen 5: Azkar Detail**
- AppBar title: Category name (e.g., "أذكار الصباح")
- AppBar subtitle: Progress "٣ من ١٢" (3 of 12)
- Linear progress indicator below AppBar
- Body: PageView (swipeable) or scrollable list
  - Each dhikr card shows: Arabic text (large, Scheherazade font), repetition counter circle (e.g., "٣" displayed large), source text (small, gray)
  - Tap anywhere on the card to decrement counter
  - Vibration on tap
  - When counter reaches 0, card animates (fade/slide) and moves to next
- FAB or bottom button: "التالي" (Next) to manually advance

**Screen 6: Azkar Completion**
- Centered checkmark animation (green)
- Text: "أحسنت! أتممت أذكار الصباح" (Well done! You completed Morning Azkar)
- "مشاركة" (Share) button
- "العودة للرئيسية" (Back to Home) button

**Screen 7: Duas Categories**
- Same layout pattern as Azkar Categories
- Categories: أدعية من القرآن, أدعية نبوية, أدعية السفر, أدعية المريض, أدعية الامتحانات, أدعية المطر, أدعية متنوعة

**Screen 8: Dua Detail**
- Scrollable list of Duas in the category
- Each Dua card: Arabic text (large), source (small), copy button (icon), share button (icon), favorite heart button

**Screen 9: Surah List (Quran)**
- AppBar title: "القرآن الكريم"
- Search bar below AppBar
- Tab bar: "السور" (Surahs) | "الأجزاء" (Juz) — two ways to browse
- Surah tab: ListView of 114 items
  - Each item: Surah number (in decorative frame) + Arabic name + English name + Ayah count + Makki/Madani badge (مكية/مدنية)
- Juz tab: ListView of 30 items, each showing Juz number and starting Surah/Ayah
- Floating "Last read" chip at bottom (if bookmark exists) — tap to jump to bookmarked position

**Screen 10: Surah Reader**
- AppBar title: Surah Arabic name
- AppBar actions: Bookmark icon, font size icon
- Body: Scrollable column
  - Bismillah header (decorative, except for Surah 9)
  - Ayahs displayed as flowing Arabic text with Ayah number markers (ornamental circles with Arabic numerals)
  - Text style: Amiri font, configurable size (from Settings)
  - Tap an Ayah to highlight it and show a bottom sheet with: Copy, Share, Bookmark options
- Reading position auto-saved on scroll

**Screen 11: Sebha (Tasbeeh Counter)**
- No bottom navigation bar (full-screen experience)
- AppBar title: "السبحة"
- AppBar actions: Reset button
- Top section: Selected dhikr text displayed (e.g., "سبحان الله")
- Center: Large circular button (gradient green, 200x200dp) showing current count in large Arabic numerals
- Below circle: Target count display "٣٣ / ٣٣" and total cumulative count
- Bottom section: Horizontal scrollable chips for dhikr selection (سبحان الله | الحمد لله | الله أكبر | لا إله إلا الله | مخصص)
- Tap the large circle to increment
- Vibration on each tap
- Animation pulse on the circle on tap
- When target reached: Celebration animation + option to continue or reset

**Screen 12: Prayer Times**
- AppBar title: "مواقيت الصلاة"
- AppBar subtitle: City name + Hijri date
- Top card: Next prayer countdown (same style as Home but larger)
- Below: List of 6 prayer time rows
  - Each row: Prayer name (Arabic) | Time (e.g., ٤:٣٢ ص) | Notification bell icon (toggle)
  - Next prayer row highlighted with accent color
- Bottom: "طريقة الحساب" (Calculation Method) text button linking to Settings

**Screen 13: Qibla**
- Full-screen compass
- Top: Degree display "١٣٥.٤°"
- Center: Compass image (rotating based on device heading)
  - Qibla direction needle/marker overlaid on compass
  - Kaaba icon at Qibla direction
- Bottom: Calibration instruction text (shown only when compass accuracy is low)
- Location info: "القاهرة، مصر" (or user's city)

**Screen 14: Settings**
- Grouped list sections:
  - **المظهر (Appearance)**: Theme selector (Light/Dark/System), Font size slider with preview text
  - **مواقيت الصلاة (Prayer Times)**: Calculation method picker, Location (auto-detect or manual)
  - **التنبيهات (Notifications)**: Master toggle, per-prayer toggles, Morning Azkar time, Evening Azkar time
  - **عام (General)**: About the app, Rate on Play Store, Share the app, Contact developer
  - **إعادة تعيين (Reset)**: Reset Sebha counter, Clear bookmarks, Clear favorites

---

## Section 5: Notifications System

### 5.1 Technology

Package: `flutter_local_notifications` (cross-platform, supports scheduled notifications, channels on Android)

### 5.2 Notification Types

| Type | Trigger | Default Time | User Configurable? |
|------|---------|-------------|-------------------|
| Fajr Adhan | Scheduled daily | Calculated from prayer times | On/Off |
| Dhuhr Adhan | Scheduled daily | Calculated from prayer times | On/Off |
| Asr Adhan | Scheduled daily | Calculated from prayer times | On/Off |
| Maghrib Adhan | Scheduled daily | Calculated from prayer times | On/Off |
| Isha Adhan | Scheduled daily | Calculated from prayer times | On/Off |
| Morning Azkar | Scheduled daily | 06:00 AM | On/Off + Time |
| Evening Azkar | Scheduled daily | 04:00 PM | On/Off + Time |

### 5.3 Implementation Strategy

1. **Android Notification Channel**: Create channel "prayer_times" (high importance) and "azkar_reminders" (default importance) during app initialization
2. **Scheduling**: Use `zonedSchedule()` with `DateTimeComponents.dateAndTime` for exact daily scheduling
3. **Prayer Time Recalculation**: Every time the app opens, recalculate today's and tomorrow's prayer times and reschedule all prayer notifications. This ensures accuracy even if the user traveled.
4. **Background Recalculation**: On Android, use `android_alarm_manager_plus` or `workmanager` to reschedule notifications daily at midnight even if the app is not opened. On iOS, rely on the next app open to reschedule (iOS background execution is limited).
5. **Notification Content**:
   - Prayer: Title "حان وقت صلاة الفجر" (It's time for Fajr prayer), Body: "٤:٣٢ ص" (time)
   - Azkar: Title "أذكار الصباح" (Morning Azkar), Body: "حان وقت أذكار الصباح، ابدأ الآن" (Time for morning Azkar, start now). Tap opens Azkar detail screen directly (deep link via go_router).
6. **Permissions**: Request notification permission on onboarding (Android 13+ requires explicit permission). Handle denial gracefully — show a banner in Settings explaining why notifications are useful.

### 5.4 Edge Cases

- **User changes time zone**: Recalculate on app open
- **User denies notification permission**: Store preference, show prompt in Settings
- **Device reboot clears alarms**: Use `RECEIVE_BOOT_COMPLETED` on Android to reschedule after reboot
- **Exact alarm permission (Android 12+)**: Request `SCHEDULE_EXACT_ALARM` permission; fall back to inexact if denied

---

## Section 6: Device Features Plan

### 6.1 Location (for Prayer Times and Qibla)

**Package**: `geolocator`

**Strategy**:
1. Request location permission during onboarding
2. Get current position (latitude, longitude) on first launch
3. Store coordinates in Hive settings
4. On subsequent launches, use stored coordinates (do not request GPS every time)
5. Provide a "Refresh Location" button in Settings and Prayer Times screen
6. Provide manual city search as fallback (hardcoded list of major cities with coordinates)

**Permission Flow**:
- `locationWhenInUse` is sufficient (no need for `always`)
- If denied: Show prayer times with default location (Makkah) and prompt to update
- If permanently denied: Direct user to device Settings

### 6.2 Compass (for Qibla)

**Package**: `flutter_compass`

**Strategy**:
1. `flutter_compass` provides a stream of `CompassEvent` with heading in degrees
2. Calculate Qibla angle from user's coordinates to Kaaba coordinates (21.4225, 39.8262) using the formula: `atan2(sin(dLon), cos(lat1)*tan(lat2) - sin(lat1)*cos(dLon))`
3. Rotate compass image by: `qiblaAngle - deviceHeading`
4. Show calibration warning when `CompassEvent.accuracy` is low

**Compass Calibration**:
- If accuracy < threshold, show overlay: "قم بتحريك الهاتف على شكل رقم ٨ لمعايرة البوصلة" (Move your phone in a figure-8 pattern to calibrate the compass)

**Platform Notes**:
- iOS: Compass works via CoreMotion (no extra setup)
- Android: Requires magnetometer sensor. Not all Android devices have one. Detect absence and show message: "جهازك لا يدعم البوصلة" (Your device does not support compass)

### 6.3 Permissions Summary

| Permission | When Requested | Fallback |
|------------|----------------|----------|
| Location (whenInUse) | Onboarding + Prayer Times first open | Default to Makkah coordinates |
| Notifications | Onboarding | Notifications disabled, banner in Settings |
| Exact Alarm (Android 12+) | First notification schedule | Inexact alarm |
| RECEIVE_BOOT_COMPLETED | Auto (manifest) | Notifications re-scheduled on next app open |

---

## Section 7: Development Roadmap

### Phase 1: Foundation and MVP Core (Days 1-5)

**Day 1: Project Setup**
- Create Flutter project: `flutter create --org com.ahmedharedy azkar`
- Configure `pubspec.yaml` with all dependencies
- Set up folder structure (all directories as listed in Section 2.4)
- Configure `app_theme.dart` with color palette, Arabic fonts
- Configure `main.dart` with `ProviderScope`, `MaterialApp.router`, RTL locale
- Set up Hive initialization in `main.dart`
- Create `app_router.dart` with all route definitions (screens will be placeholder widgets)
- Add Arabic fonts to assets and register in pubspec

**Day 2: Splash + Onboarding + Home Shell**
- Implement SplashScreen with timer and navigation logic
- Implement OnboardingScreen (3-page PageView) with dot indicator
- Store `isFirstLaunch` flag in Hive after onboarding completion
- Implement Home screen shell with BottomNavigationBar (ShellRoute)
- Implement quick access grid (tappable cards navigating to placeholder screens)

**Day 3: Azkar Feature (Complete)**
- Prepare `azkar.json` data file (at least Morning, Evening, Sleep categories with real Hisn Al-Muslim content)
- Implement `AzkarLocalSource` — loads and parses JSON from assets
- Implement `AzkarRepository` (abstract) and `AzkarRepositoryImpl`
- Implement `azkar_provider.dart` — loads categories, exposes to UI
- Implement `AzkarCategoriesScreen` — list of category cards
- Implement `AzkarDetailScreen` — PageView with counter tap logic, vibration, auto-advance
- Implement `azkar_progress_provider.dart` — tracks current dhikr index and count
- Implement `AzkarCompletionScreen`

**Day 4: Sebha Feature (Complete)**
- Implement `SebhaState` model
- Implement `sebha_provider.dart` — counter logic, persistence to Hive
- Implement `SebhaScreen` — large circle button, count display, dhikr selector
- Add vibration feedback
- Add target count logic and reset with confirmation

**Day 5: Duas Feature (Complete)**
- Prepare `duas.json` data file
- Implement Duas data layer (same pattern as Azkar)
- Implement `DuasCategoriesScreen` and `DuaDetailScreen`
- Add copy and share functionality
- Add favorites (store in Hive)

### Phase 2: Quran Feature (Days 6-9)

**Day 6: Quran Data Preparation**
- Source Quran JSON data from tanzil.net or existing open-source datasets
- Validate: 114 Surahs, correct Ayah counts, proper tashkeel
- Format into `quran.json` matching the data model
- Implement `QuranLocalSource` — load and parse (lazy loading by Surah)
- Implement `QuranRepository`

**Day 7: Surah List Screen**
- Implement `surah_list_screen.dart` — ListView of 114 Surahs
- Implement `surah_list_tile.dart` — decorative Surah number, names, badges
- Add Juz tab (group Surahs by Juz)
- Implement search functionality (filter Surahs by Arabic name)

**Day 8: Surah Reader Screen**
- Implement `surah_reader_screen.dart` — scrollable Ayah text
- Implement `bismillah_header.dart` — decorative Bismillah (skip for Surah 9)
- Implement `ayah_text_widget.dart` — Arabic text with ornamental Ayah number markers
- Apply Amiri font with configurable size
- Handle large Surahs (Al-Baqarah: 286 Ayahs) with efficient rendering

**Day 9: Quran Bookmarks and Polish**
- Implement bookmark saving (tap Ayah -> bottom sheet -> bookmark)
- Implement `bookmark_provider.dart` — save/load from Hive
- Add "Last read" floating chip on Surah list
- Add font size control (from Settings or in-screen button)
- Test reading experience, adjust padding and line height

### Phase 3: Prayer Times and Qibla (Days 10-12)

**Day 10: Prayer Times**
- Implement `location_service.dart` — wrap `geolocator` package
- Implement `prayer_calculation.dart` — wrap `adhan` package, expose clean API
- Implement `prayer_times_provider.dart` — calculate times for today
- Implement `PrayerTimesScreen` — list of 6 prayer rows + next prayer card
- Implement countdown timer for next prayer (updates every second)
- Add calculation method picker (store preference in Hive)

**Day 11: Qibla Direction**
- Implement `compass_service.dart` — wrap `flutter_compass`, expose heading stream
- Implement `qibla_provider.dart` — combine heading + Qibla angle calculation
- Implement `QiblaScreen` — compass image rotating with device heading, Qibla marker
- Add calibration detection and warning
- Handle missing compass sensor gracefully

**Day 12: Home Dashboard Integration**
- Connect prayer countdown card on Home to real data
- Implement daily Ayah card (random verse from Quran data, changes daily based on date seed)
- Implement greeting based on time of day
- Add Hijri date display (using `hijri` package)
- Polish Home screen layout and visual hierarchy

### Phase 4: Notifications and Settings (Days 13-15)

**Day 13: Notification System**
- Implement `notification_service.dart` — initialize channels, schedule/cancel methods
- Implement prayer time notification scheduling (5 prayers)
- Implement Azkar reminder scheduling (morning + evening)
- Handle Android 13+ notification permission
- Handle exact alarm permission for Android 12+

**Day 14: Settings Screen**
- Implement `SettingsScreen` with all grouped sections
- Theme switching (Light/Dark/System) — persist to Hive, apply via `settings_provider`
- Font size slider with live preview
- Prayer calculation method picker
- Notification toggles per prayer + Azkar reminders
- Location refresh button

**Day 15: Notifications Polish and Testing**
- Test notification delivery on Android (real device)
- Test deep linking from notification tap to Azkar detail
- Handle boot completed receiver (reschedule after reboot)
- Handle edge cases: permission denied, time zone change, travel

### Phase 5: Polish, Testing, and Deployment (Days 16-20)

**Day 16: UI Polish**
- Review all screens for RTL correctness
- Add subtle animations (page transitions, card taps, counter animations)
- Ensure consistent spacing, colors, and typography across all screens
- Add empty states, loading states, and error states
- Handle dark mode for every screen

**Day 17: App Icon and Splash**
- Design app icon (Islamic geometric pattern, green and gold, "أذكار" text)
- Configure `flutter_launcher_icons` in pubspec and generate
- Configure `flutter_native_splash` (green gradient background, logo)
- Generate splash screen for Android and iOS

**Day 18: Testing**
- Write unit tests for: prayer time calculation, Qibla angle calculation, Azkar counter logic, Sebha counter logic, JSON parsing
- Write widget tests for: Home screen rendering, Azkar detail counter interaction, Surah list rendering
- Manual testing checklist (see Section 8)

**Day 19: Performance Optimization**
- Profile app startup time — ensure < 3 seconds
- Profile Quran reader scrolling — ensure 60fps
- Optimize Quran JSON loading (lazy load by Surah, not entire file at once)
- Check APK size — target < 30MB (Quran JSON is ~4MB)
- Test on low-end Android device

**Day 20: Build and Deploy**
- Generate signed AAB for Google Play
- Prepare Play Store listing (screenshots, description in Arabic, feature graphic)
- Upload to Google Play Console
- Set up internal testing track first
- Promote to production after testing

---

## Section 8: Testing Strategy

### 8.1 Unit Tests

| Test File | What to Test |
|-----------|-------------|
| `prayer_calculation_test.dart` | Verify prayer times for known location/date match expected values |
| `qibla_calculation_test.dart` | Verify Qibla angle from Cairo = ~136 degrees, from New York = ~58 degrees |
| `azkar_repository_test.dart` | JSON parsing returns correct number of categories and items |
| `quran_repository_test.dart` | Parsing returns 114 Surahs, Al-Fatiha has 7 Ayahs, Al-Baqarah has 286 |
| `sebha_provider_test.dart` | Increment, reset, target completion logic |
| `azkar_progress_test.dart` | Counter decrement, auto-advance at zero, completion detection |
| `arabic_number_utils_test.dart` | Conversion of 0-9 to ٠-٩ |
| `date_utils_test.dart` | Hijri date conversion correctness |

### 8.2 Widget Tests

| Test File | What to Test |
|-----------|-------------|
| `home_screen_test.dart` | All 6 quick-access cards render, prayer card shows, daily Ayah shows |
| `azkar_categories_test.dart` | Correct number of category cards render, tap navigates |
| `dhikr_card_test.dart` | Counter displays, tap decrements, reaches zero triggers callback |
| `surah_list_test.dart` | 114 items render, search filters correctly |
| `sebha_screen_test.dart` | Circle tap increments count, reset clears |
| `prayer_time_row_test.dart` | Correct time format, next prayer highlighted |

### 8.3 Integration Tests

| Test | Flow |
|------|------|
| `onboarding_flow_test.dart` | Splash -> Onboarding -> Home. Verify first launch flag set. |
| `azkar_flow_test.dart` | Home -> Azkar Categories -> Morning Azkar -> Complete all -> Completion screen |
| `quran_flow_test.dart` | Surah List -> Tap Al-Fatiha -> Read -> Bookmark -> Back -> Verify bookmark chip |

### 8.4 Manual Testing Checklist

- [ ] App launches without crash on Android 10, 12, 13, 14
- [ ] RTL layout correct on every screen (text right-aligned, back button on right)
- [ ] Arabic text renders with correct tashkeel (diacritical marks)
- [ ] Azkar counter vibrates on tap
- [ ] Azkar auto-advances when count reaches zero
- [ ] Sebha count persists after killing and reopening app
- [ ] Quran reader scrolls smoothly on Al-Baqarah (longest Surah)
- [ ] Quran bookmark saves and restores correctly
- [ ] Prayer times are accurate (compare with known prayer time app)
- [ ] Qibla direction is accurate (compare with physical compass or known Qibla app)
- [ ] Notification fires at correct time for each prayer
- [ ] Notification tap opens correct screen
- [ ] Dark mode applies to all screens without broken colors
- [ ] Font size change applies to Azkar, Duas, and Quran text
- [ ] Onboarding only shows on first launch
- [ ] Location permission denial shows fallback (Makkah times)
- [ ] Compass sensor absence shows graceful error message
- [ ] Share button works for Azkar, Duas, and Ayahs
- [ ] App does not crash when rotating device
- [ ] App works in airplane mode (all features except GPS refresh)

---

## Section 9: Performance and Optimization

### 9.1 Quran Data Handling

The full Quran JSON (all 6,236 Ayahs with tashkeel) is approximately 3-5 MB. Loading it all into memory at once is wasteful.

**Strategy: Lazy Loading by Surah**
1. Split `quran.json` into 114 individual files: `surah_001.json` through `surah_114.json`. Alternatively, keep one file but parse only the metadata (Surah names, Ayah counts) on first load, and parse individual Surah Ayahs only when the user opens that Surah.
2. Recommended approach: Keep a single `quran_index.json` (~5KB) with Surah metadata. Keep full text in `quran_full.json`. Load index at startup. Load Ayahs for a specific Surah on demand using `rootBundle.loadString` and parse only the needed Surah section.
3. Cache loaded Surahs in memory (LRU cache of last 5 Surahs) so navigating back is instant.

### 9.2 Startup Performance

Target: App usable (Home screen rendered) within 2.5 seconds of cold start.

Actions:
- Initialize Hive boxes asynchronously in `main()` before `runApp()`
- Do NOT load Quran data at startup. Load only Settings, Azkar categories (lightweight), and prayer times.
- Splash screen runs for 2 seconds — use this time for initialization
- Use `const` constructors wherever possible
- Use `const` for all static widgets and text

### 9.3 Scrolling Performance

- Quran reader: Use `ListView.builder` (not `Column` with all Ayahs) for efficient rendering
- Surah list: Use `ListView.builder` for 114 items
- Azkar detail: Use `PageView.builder` for swipeable dhikr cards
- Avoid rebuilding entire widget tree — use `select` on Riverpod providers to watch only the needed state slice

### 9.4 APK Size Optimization

Target: < 25 MB for APK, < 15 MB for AAB (with app bundles)

- Use `--split-per-abi` when building APK to generate architecture-specific builds
- Compress PNG images (use TinyPNG or similar)
- Use SVG instead of PNG for icons where possible
- Arabic fonts are large (Amiri ~400KB, Scheherazade ~300KB, Cairo ~200KB) — total ~900KB, acceptable
- Quran JSON (~4MB) is the largest asset — consider gzip compression (Flutter can read compressed assets)
- Remove unused packages before release build
- Run `flutter build apk --analyze-size` to identify bloat

### 9.5 Battery and Resource Optimization

- Compass stream: Subscribe only when Qibla screen is visible. Dispose stream on screen exit.
- Prayer countdown timer: Use a single `Timer.periodic(Duration(seconds: 1))` on the Home screen. Cancel when screen is not visible.
- GPS: Request location once, cache it. Do not run continuous location tracking.
- Notifications: Schedule all at once (7 notifications per day max). Reschedule only when prayer times change.

---

## Section 10: Deployment Plan

### 10.1 Pre-Deployment Checklist

- [x] App name set: "رفيق المسلم" (Arabic) / "Muslim Companion" (English fallback)
- [ ] Package name: `com.ahmedharedy.azkar`
- [ ] Version: 1.0.0+1
- [ ] App icon generated (adaptive icon for Android)
- [ ] Splash screen configured
- [ ] All debug prints removed
- [ ] No TODO comments remaining in production code
- [ ] Proguard/R8 rules configured (if using native plugins)
- [ ] `flutter build appbundle --release` succeeds without errors

### 10.2 Android Build Steps

1. Generate upload keystore:
   ```
   keytool -genkey -v -keystore azkar-upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `android/key.properties` file (NOT committed to git):
   ```
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=<path>/azkar-upload-keystore.jks
   ```
3. Configure `android/app/build.gradle` to read keystore properties
4. Build AAB: `flutter build appbundle --release`
5. Build APK (for testing): `flutter build apk --release --split-per-abi`

### 10.3 Google Play Store Listing

| Field | Value |
|-------|-------|
| App name | رفيق المسلم |
| Short description (80 chars) | أذكار وأدعية وقرآن ومواقيت صلاة وسبحة واتجاه القبلة في تطبيق واحد |
| Full description | Detailed Arabic description covering all features |
| Category | Lifestyle or Books & Reference |
| Content rating | Everyone |
| Target audience | 13+ (general Muslim audience) |
| Screenshots | Minimum 4: Home, Azkar Detail, Quran Reader, Prayer Times |
| Feature graphic | 1024x500 banner image |
| Privacy policy | Required — create a simple page (can use GitHub Pages) |

### 10.4 Release Strategy

1. **Internal Testing** — Upload AAB to internal testing track. Test on 2-3 real devices.
2. **Closed Testing** — Share with 10-15 friends/family for feedback. Run for 3-5 days.
3. **Production Release** — Promote to production after addressing feedback.
4. **Post-Launch** — Monitor crash reports (Firebase Crashlytics — optional), respond to reviews, plan updates.

---

## Section 11: Future Enhancements (Post-MVP)

### Phase 2 Enhancements (Version 1.1)

| Enhancement | Description | Complexity |
|-------------|-------------|------------|
| Quran Audio | Stream recitation from cdn.islamic.network (128kbps). Per-Surah ayah-by-ayah playback with sync highlight. | High |
| Home Screen Widget | Android widget showing next prayer time or daily Ayah | Medium |
| Monthly Prayer Calendar | Calendar view of prayer times for the entire month | Low |
| Azkar Search | Search across all Azkar categories by text | Low |
| Quran Page View | Display Quran in Mushaf page layout (image-based) alongside text | High |

### Phase 3 Enhancements (Version 1.2)

| Enhancement | Description | Complexity |
|-------------|-------------|------------|
| Multi-Language | Support English, Urdu, Turkish, French, Malay | Medium |
| Cloud Sync | Sync bookmarks and favorites via Firebase | Medium |
| Quran Translation | Show translation below each Ayah (English, Urdu, etc.) | Medium |
| Hadith Section | Daily Hadith with categorized Hadith collection | High |
| Islamic Calendar | Full Hijri calendar with Islamic events and occasions | Medium |

### Phase 4 Enhancements (Version 2.0)

| Enhancement | Description | Complexity |
|-------------|-------------|------------|
| iOS Release | Publish on Apple App Store | Medium (mostly config) |
| Quran Tafsir | Tap Ayah to see tafsir (explanation) from Ibn Kathir or others | High |
| Community Features | Share Azkar completion count, challenge friends | High |
| Wear OS | Companion app for smartwatch (Sebha + next prayer) | High |
| Offline Maps for Qibla | Show Qibla direction on a map without internet | Medium |

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Quran text accuracy | Medium | Critical | Use verified sources (tanzil.net). Have a knowledgeable person review text. |
| Arabic font rendering issues | Medium | High | Test on multiple devices early. Use well-established fonts (Amiri, Scheherazade). |
| Prayer time calculation inaccuracy | Low | High | Use the proven `adhan` package. Cross-verify with established apps (Muslim Pro, Athan). |
| Compass inaccuracy on some Android devices | High | Medium | Show calibration instructions. Allow manual Qibla degree entry as fallback. |
| Notification not firing (Doze mode, OEM restrictions) | High | Medium | Use exact alarms. Document for users: "Disable battery optimization for Azkar app." |
| Large APK size from Quran data | Medium | Low | Use AAB (app bundles), compress JSON, split APK by ABI. |
| First Flutter project learning curve | High | Medium | Follow this plan step-by-step. Each day produces a working feature. Use ChatGPT/Claude for Flutter questions as they arise. |
| RTL layout bugs | Medium | Medium | Set Arabic locale from day 1. Test every screen immediately after building it. |

---

## Success Criteria

- [ ] App launches and shows Home screen within 3 seconds
- [ ] All 8+ Azkar categories load with correct Arabic text and repetition counts
- [ ] Azkar counter works correctly: tap to decrement, vibrate, auto-advance, complete
- [ ] Duas categories load and display correctly with copy/share
- [ ] Full Quran (114 Surahs, 6236 Ayahs) loads and is readable with proper Arabic typography
- [ ] Quran bookmark saves and restores position
- [ ] Sebha counter increments, persists across sessions, and resets correctly
- [ ] Prayer times are accurate for user's location (within 1-2 minutes of reference app)
- [ ] Qibla direction points correctly toward Makkah
- [ ] Notifications fire for prayer times and Azkar reminders
- [ ] Dark mode works on all screens
- [ ] Font size setting applies globally to all Arabic text
- [ ] App works fully offline (except GPS refresh)
- [ ] APK size < 30 MB
- [ ] No crashes on Android 10-14
- [ ] RTL layout correct on every screen
- [ ] Published on Google Play Store

---

---

## TODO Tracker (Updated: 12.04.2026)

### Feature 1: Splash Screen
- [x] Display app logo and name
- [x] Initialize Hive
- [x] Navigate to Home

### Feature 2: Onboarding
- [x] 3 swipeable pages explaining features
- [x] Request location permission
- [x] Request notification permission
- [x] "Get Started" button
- [x] First-launch flag

### Feature 3: Home Dashboard
- [x] Quick-access grid (Azkar, Quran, Sebha, Prayer Times, Qibla, Duas)
- [x] Basic home layout
- [x] Greeting based on time of day
- [x] Next prayer countdown card (connected to real data)
- [x] Daily Ayah card (random verse)
- [x] Morning/Evening Azkar contextual shortcuts
- [x] Hijri date display

### Feature 4: Azkar
- [x] Category list with icons and Arabic names
- [x] Azkar detail screen with dhikr cards
- [x] Data loading from azkar.json
- [x] Counter tap to decrement + vibration + auto-advance
- [x] Progress indicator ("3 of 12 completed")
- [x] Completion screen
- [x] Favorites

### Feature 5: Duas
- [x] Category list
- [x] Dua detail screen with Arabic text
- [x] Data loading from duas.json
- [x] Copy and share functionality
- [x] Favorites

### Feature 6: Quran
- [x] Surah list (114 surahs with Arabic/English names, Makki/Madani badges)
- [x] Mushaf page view (604 pages, RTL PageView)
- [x] Keyboard + on-screen arrow navigation
- [x] Surah header + Bismillah (deduplicated)
- [x] Ayah number markers in Arabic numerals
- [x] Justified text alignment (Mushaf style)
- [x] Tap-to-highlight ayah with auto-save/restore
- [x] Clear highlight option
- [x] Last read page persistence
- [x] Search ayahs by Arabic text
- [x] Bookmarks (backend)
- [x] Audio recitation — 7 reciters, ayah-by-ayah streaming
- [x] Sync highlight with audio (read while listen)
- [x] Auto page-turn during audio playback
- [x] Play from highlighted/clicked ayah
- [x] Next/prev ayah controls
- [x] Reciter picker (bottom sheet)
- [x] Adaptive font sizing
- [x] Juz browser (navigate by Juz 1-30)
- [x] Bookmarks list screen (UI to view/manage saved bookmarks)

### Feature 7: Sebha / Tasbeeh
- [x] Large circular tap area
- [x] Counter display
- [x] Preset dhikr phrases
- [x] Vibration feedback
- [x] Persist count across sessions
- [x] Reset with confirmation dialog
- [x] Target count (33, 99, custom) with completion notification
- [x] Cumulative total count

### Feature 8: Prayer Times
- [x] 6 prayer times (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha)
- [x] Next prayer highlighted
- [x] Location-based calculation (Adhan package)
- [x] 9 calculation methods
- [x] DST/timezone handled correctly (via OS)
- [x] Settings integration (calculation method applied)
- [x] Countdown timer for next prayer
- [x] Manual location override (city search)
- [x] Monthly calendar view

### Feature 9: Qibla
- [x] Compass pointing toward Kaaba
- [x] Degree display
- [x] Location-based calculation
- [x] Calibration instruction
- [x] Missing compass sensor handling

### Feature 10: Notifications
- [x] Prayer time Adhan notifications (per-prayer toggle)
- [x] Morning Azkar reminder
- [x] Evening Azkar reminder
- [x] Handle Android 13+ notification permission
- [x] Handle exact alarm permission (Android 12+)
- [x] Deep link from notification to correct screen

### Feature 11: Settings
- [x] Calculation method selector
- [x] Font size slider
- [x] Theme switching (Light/Dark/System)
- [x] Notification toggles
- [x] Location refresh button
- [x] About / version info

### Deployment
- [x] App icon (Islamic design, green & gold)
- [x] Native splash screen
- [x] Remove debug prints / TODO comments
- [x] Fix all analyzer issues (0 warnings)
- [ ] Generate signed AAB
- [ ] Play Store listing (Arabic description, screenshots)
- [ ] Internal testing
- [ ] Production release

### Feature 12: Quran Listen
- [x] mp3quran.net API integration & caching
- [x] Surah selector with Arabic names
- [x] Moshaf type filter chips
- [x] Reciter list filtered by surah+moshaf availability
- [x] Full-surah audio streaming
- [x] Mini audio player bar
- [x] Auto-continue to next surah when current finishes
- [x] Audio session config (music content type, high-quality pipeline)

### Feature 13: Live Islamic Radio
- [x] Saudi Quran Radio stream
- [x] Saudi Sunnah Radio stream
- [x] Egypt Quran Radio stream (fixed: zeno.fm HTTPS)
- [x] LIVE indicator + play/stop controls
- [x] Saudi Quran TV video stream (chewie + video_player)
- [x] Audio/Video mode toggle for video-capable stations

### Feature 14: Hajj & Umrah Guide
- [x] Hajj & Umrah JSON data (expanded)
- [x] Umrah step-by-step guide (detailed with sunnah acts, conditions)
- [x] Hajj step-by-step guide (day-by-day with fiqh notes)
- [x] All 3 Hajj types: Tamattu', Qiran, Ifrad (new tab)
- [x] Duas for each ritual (9 occasions with notes)
- [x] Ihram prohibitions (categorized: shared/men/women with penalties)

### Feature 15: Audio Quality & Auto-Continue
- [x] Audio session configuration (AudioSession, Android music attributes)
- [x] Per-ayah player: auto-continue to next surah on completion
- [x] Full-surah player: auto-continue to next surah (same reciter/moshaf)
- [x] ConcatenatingAudioSource useLazyPreparation: false (preload next ayah)

### Deployment
- [x] App icon (Islamic design, green & gold)
- [x] Native splash screen
- [x] Remove debug prints / TODO comments
- [x] Fix all analyzer issues (0 warnings)
- [ ] Generate signed AAB
- [ ] Play Store listing (Arabic description, screenshots)
- [ ] Internal testing
- [ ] Production release

### Future Enhancements (Post-MVP)
- [ ] Home screen Android widget
- [ ] Quran translation
- [ ] Cloud sync (Firebase)
- [ ] Multi-language support
- [ ] Hadith section
- [ ] Islamic calendar
- [ ] iOS release
- [ ] Quran Tafsir

---

### Progress Summary (Updated: 13.04.2026)

| Category | Done | Total | % |
|----------|------|-------|---|
| Splash | 3 | 3 | 100% |
| Onboarding | 5 | 5 | 100% |
| Home | 7 | 7 | 100% |
| Azkar | 7 | 7 | 100% |
| Duas | 5 | 5 | 100% |
| Quran | 20 | 20 | 100% |
| Sebha | 8 | 8 | 100% |
| Prayer Times | 9 | 9 | 100% |
| Qibla | 5 | 5 | 100% |
| Notifications | 6 | 6 | 100% |
| Settings | 6 | 6 | 100% |
| Quran Listen | 8 | 8 | 100% |
| Live Radio | 6 | 6 | 100% |
| Hajj & Umrah | 6 | 6 | 100% |
| Audio Quality | 4 | 4 | 100% |
| Deployment | 4 | 8 | 50% |
| **TOTAL** | **113** | **117** | **97%** |

Key files referenced:
- **`C:\Users\ahmed\Downloads\Azkar\PLAN.md`** -- The full implementation plan (this document)
- **`C:\Users\ahmed\Downloads\Azkar\SESSION_HISTORY.md`** -- Session tracking file (already exists)
- **`C:\Users\ahmed\Downloads\Azkar\SESSION_COMPACT.md`** -- Session summary file (already exists)
