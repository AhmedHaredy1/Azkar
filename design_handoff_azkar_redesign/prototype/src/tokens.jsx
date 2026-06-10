// Azkar design system — minimal, modern, spiritual.
// Single source of truth for colors, spacing, type, and small primitives.

const T = {
  // Palette — restrained green + warm neutrals. Green used sparingly.
  primary:        '#1B5E20',         // deep Islamic green — accent only
  primarySoft:    '#EEF3EE',         // fills behind primary text
  primaryInk:     '#0F3A13',         // text on primarySoft
  gold:           '#B8892A',         // reserved highlight (Quran hero, streaks)
  goldSoft:       '#F5ECD9',

  bg:             '#FAF8F3',         // warm off-white page bg
  surface:        '#FFFFFF',         // cards
  surfaceSunk:    '#F2EFE8',         // quiet sunken surfaces
  hairline:       'rgba(27,47,31,0.08)',
  hairlineStrong: 'rgba(27,47,31,0.14)',

  ink:            '#141814',         // primary text
  ink2:           '#4A524B',         // secondary text
  ink3:           '#8A8F88',         // tertiary / meta
  ink4:           '#B8BAB4',         // placeholders

  // Utility
  danger:         '#B42318',
  success:        '#1B5E20',

  // Radii
  r_sm: 10,
  r_md: 14,
  r_lg: 20,
  r_xl: 28,
  r_pill: 999,

  // Spacing grid (4pt)
  s1: 4, s2: 8, s3: 12, s4: 16, s5: 20, s6: 24, s7: 32, s8: 40, s9: 56,

  // Type
  fontUi:     '"IBM Plex Sans Arabic", "IBM Plex Sans", -apple-system, Inter, system-ui, sans-serif',
  fontArabic: '"IBM Plex Sans Arabic", "Noto Kufi Arabic", system-ui, sans-serif',
  fontQuran:  '"Noto Naskh Arabic", "Amiri", "Scheherazade New", serif',
  fontNum:    '"IBM Plex Sans", ui-monospace, SFMono-Regular, Menlo, monospace',
};

// ────────────────────────────────────────────────────────────
// 8-point star — the only ornament we use. Restrained, geometric.
// ────────────────────────────────────────────────────────────
function StarMark({ size = 14, color = T.primary, opacity = 1 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={{ opacity }}>
      <path
        d="M12 1 L14.6 9.4 L23 12 L14.6 14.6 L12 23 L9.4 14.6 L1 12 L9.4 9.4 Z"
        fill={color}
      />
    </svg>
  );
}

// Thin 2-lined 8-point star (outlined version)
function StarOutline({ size = 18, color = T.primary, strokeWidth = 1 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <path
        d="M12 2 L13.8 10.2 L22 12 L13.8 13.8 L12 22 L10.2 13.8 L2 12 L10.2 10.2 Z"
        stroke={color} strokeWidth={strokeWidth} strokeLinejoin="round"
      />
    </svg>
  );
}

// ────────────────────────────────────────────────────────────
// Minimal icon set — thin line, 1.5 stroke. Consistent feel.
// Usage: <Icon name="quran" size={22} color={T.ink} />
// ────────────────────────────────────────────────────────────
const ICONS = {
  home: 'M3 11 L12 3 L21 11 V20 A1 1 0 0 1 20 21 H15 V14 H9 V21 H4 A1 1 0 0 1 3 20 Z',
  azkar: 'M12 3 C7 3 5 7 5 11 C5 14 7 17 12 21 C17 17 19 14 19 11 C19 7 17 3 12 3 Z M12 8 V14 M9 11 H15',
  quran: 'M4 4 H11 A3 3 0 0 1 14 7 V20 A2 2 0 0 0 12 18 H4 Z M20 4 H13 A3 3 0 0 0 10 7 V20 A2 2 0 0 1 12 18 H20 Z',
  settings: 'M12 8 A4 4 0 1 1 12 16 A4 4 0 1 1 12 8 Z M19.4 15 A7.5 7.5 0 0 0 19.5 12 Q19.5 10.5 19.4 9 L21.5 7.4 L19.5 4 L17 4.9 A7.5 7.5 0 0 0 14.5 3.5 L14 1 H10 L9.5 3.5 A7.5 7.5 0 0 0 7 4.9 L4.5 4 L2.5 7.4 L4.6 9 Q4.5 10.5 4.5 12 T4.6 15 L2.5 16.6 L4.5 20 L7 19.1 A7.5 7.5 0 0 0 9.5 20.5 L10 23 H14 L14.5 20.5 A7.5 7.5 0 0 0 17 19.1 L19.5 20 L21.5 16.6 Z',
  compass: 'M12 2 A10 10 0 1 1 12 22 A10 10 0 1 1 12 2 Z M15 9 L13 13 L9 15 L11 11 Z',
  mosque: 'M3 21 V11 C3 9 4 7.5 6 7 V21 M18 21 V7 C20 7.5 21 9 21 11 V21 M6 7 Q7.5 5.5 9 5 M18 7 Q16.5 5.5 15 5 M9 5 Q9 3 12 2 Q15 3 15 5 M12 2 V4 M8 21 H16 V13 Q12 12 8 13 Z',
  heart: 'M12 20 C5 14.5 3 11.5 3 8.5 A4.5 4.5 0 0 1 12 6.5 A4.5 4.5 0 0 1 21 8.5 C21 11.5 19 14.5 12 20 Z',
  share: 'M8 12 L16 6 M8 12 L16 18 M18 6 A2 2 0 1 1 18 2 A2 2 0 1 1 18 6 Z M6 14 A2 2 0 1 1 6 10 A2 2 0 1 1 6 14 Z M18 22 A2 2 0 1 1 18 18 A2 2 0 1 1 18 22 Z',
  copy: 'M8 4 H18 V16 M4 8 H14 V20 H4 Z',
  search: 'M11 4 A7 7 0 1 1 11 18 A7 7 0 1 1 11 4 Z M16.5 16.5 L21 21',
  play: 'M7 4 V20 L19 12 Z',
  pause: 'M7 4 V20 M17 4 V20',
  bookmark: 'M6 3 H18 V21 L12 17 L6 21 Z',
  chevR: 'M9 6 L15 12 L9 18',
  chevL: 'M15 6 L9 12 L15 18',
  chevD: 'M6 9 L12 15 L18 9',
  chevU: 'M6 15 L12 9 L18 15',
  plus: 'M12 4 V20 M4 12 H20',
  minus: 'M4 12 H20',
  moon: 'M20 14 A8 8 0 1 1 10 4 A6 6 0 0 0 20 14 Z',
  sun: 'M12 4 V2 M12 22 V20 M20 12 H22 M2 12 H4 M17.6 6.4 L19 5 M5 19 L6.4 17.6 M17.6 17.6 L19 19 M5 5 L6.4 6.4 M12 7 A5 5 0 1 1 12 17 A5 5 0 1 1 12 7 Z',
  bell: 'M6 16 V11 A6 6 0 0 1 18 11 V16 L20 18 H4 Z M10 20 A2 2 0 0 0 14 20',
  tasbeeh: 'M12 3 A9 9 0 1 1 12 21 A9 9 0 1 1 12 3 M12 3 V6 M12 18 V21 M3 12 H6 M18 12 H21',
  download: 'M12 4 V16 M7 11 L12 16 L17 11 M4 20 H20',
  verse: 'M4 6 H16 M4 12 H20 M4 18 H12',
  calendar: 'M5 6 H19 V20 H5 Z M5 10 H19 M9 4 V8 M15 4 V8',
  location: 'M12 22 C7 16 4 13 4 10 A8 8 0 0 1 20 10 C20 13 17 16 12 22 Z M12 11 A2 2 0 1 1 12 7 A2 2 0 1 1 12 11 Z',
  vibrate: 'M2 9 V15 M22 9 V15 M5 7 V17 M19 7 V17 M8 5 H16 V19 H8 Z',
  close: 'M6 6 L18 18 M18 6 L6 18',
  back: 'M15 6 L9 12 L15 18',
  eye: 'M2 12 Q6 5 12 5 Q18 5 22 12 Q18 19 12 19 Q6 19 2 12 Z M12 9 A3 3 0 1 1 12 15 A3 3 0 1 1 12 9 Z',
  names: 'M12 3 L14 10 L21 10 L15 14 L17 21 L12 17 L7 21 L9 14 L3 10 L10 10 Z',
  ramadan: 'M16 18 A8 8 0 1 1 16 4 A6 6 0 0 0 16 18 Z M19 6 L20 8 L22 9 L20 10 L19 12 L18 10 L16 9 L18 8 Z',
  wudu: 'M12 4 C8 10 6 13 6 15 A6 6 0 0 0 18 15 C18 13 16 10 12 4 Z',
  radio: 'M4 8 H20 V20 H4 Z M8 4 L12 8 L16 4 M8 14 A2 2 0 1 1 8 18 A2 2 0 1 1 8 14 Z M14 14 H18 M14 17 H18',
};

function Icon({ name, size = 22, color = 'currentColor', strokeWidth = 1.5, fill = 'none' }) {
  const d = ICONS[name];
  if (!d) return null;
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={fill} style={{ flexShrink: 0 }}>
      <path d={d} stroke={color} strokeWidth={strokeWidth}
        strokeLinecap="round" strokeLinejoin="round" fill={fill === 'none' ? 'none' : color}/>
    </svg>
  );
}

// ────────────────────────────────────────────────────────────
// Faint geometric watermark — used on hero cards. Very subtle.
// ────────────────────────────────────────────────────────────
function GeoWatermark({ opacity = 0.05, color = T.primary, size = 260, top = -60, right = -60 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 100 100"
      style={{ position: 'absolute', top, right, opacity, pointerEvents: 'none' }}>
      <g fill="none" stroke={color} strokeWidth="0.5">
        <circle cx="50" cy="50" r="40"/>
        <circle cx="50" cy="50" r="30"/>
        <path d="M50 10 L60 40 L90 50 L60 60 L50 90 L40 60 L10 50 L40 40 Z"/>
        <path d="M50 20 L55 45 L80 50 L55 55 L50 80 L45 55 L20 50 L45 45 Z"/>
      </g>
    </svg>
  );
}

// Arabic-Indic numerals helper (user's codebase uses them)
function toAr(n) {
  const ar = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
  return String(n).replace(/\d/g, d => ar[+d]);
}

// Hair divider
function Hair({ inset = 0, color = T.hairline }) {
  return <div style={{ height: 1, background: color, marginInline: inset }} />;
}

// A thin "frame" label shown above each phone on the canvas
function FrameLabel({ children }) {
  return (
    <div style={{
      position: 'absolute', top: -28, left: 0,
      fontSize: 11, fontWeight: 500, color: 'rgba(40,30,20,0.65)',
      fontFamily: T.fontUi, letterSpacing: 0.2,
    }}>{children}</div>
  );
}

Object.assign(window, { T, StarMark, StarOutline, Icon, ICONS, GeoWatermark, toAr, Hair, FrameLabel });
