// Home / Dashboard — minimal modern.
// RTL. Hero = next prayer with countdown + 5-prayer ribbon.
// Below: greeting row, ayah of day, quick actions grid, streak mini.

function PrayerRibbon({ prayers, nextIdx }) {
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: `repeat(${prayers.length}, 1fr)`,
      gap: 4, marginTop: 20,
    }}>
      {prayers.map((p, i) => {
        const isNext = i === nextIdx;
        const isPast = i < nextIdx;
        return (
          <div key={p.name} style={{
            textAlign: 'center',
            padding: '10px 4px 12px',
            borderRadius: T.r_md,
            background: isNext ? 'rgba(255,255,255,0.14)' : 'transparent',
          }}>
            <div style={{
              fontFamily: T.fontArabic, fontSize: 13,
              color: isNext ? '#fff' : 'rgba(255,255,255,0.75)',
              fontWeight: isNext ? 600 : 400,
              marginBottom: 4,
              opacity: isPast ? 0.55 : 1,
            }}>{p.name}</div>
            <div style={{
              fontFamily: T.fontNum, fontSize: 11,
              color: 'rgba(255,255,255,0.7)',
              letterSpacing: 0.3,
              opacity: isPast ? 0.45 : 1,
            }}>{p.time}</div>
            {isNext && (
              <div style={{
                width: 4, height: 4, borderRadius: 99,
                background: '#fff', margin: '6px auto 0',
              }} />
            )}
          </div>
        );
      })}
    </div>
  );
}

function HeroPrayerCard() {
  const prayers = [
    { name: 'الفجر',    time: '04:52', ar: '٠٤:٥٢' },
    { name: 'الظهر',    time: '12:14', ar: '١٢:١٤' },
    { name: 'العصر',    time: '15:41', ar: '١٥:٤١' },
    { name: 'المغرب',   time: '18:27', ar: '١٨:٢٧' },
    { name: 'العشاء',   time: '19:48', ar: '١٩:٤٨' },
  ];
  const nextIdx = 2; // Asr
  return (
    <div style={{
      position: 'relative', borderRadius: T.r_xl,
      background: `linear-gradient(160deg, ${T.primary} 0%, #0F3A13 100%)`,
      padding: '22px 22px 18px',
      color: '#fff', overflow: 'hidden',
    }}>
      <GeoWatermark opacity={0.07} color="#D5B76A" size={280} top={-80} right={-80}/>
      <div style={{ position: 'relative' }}>
        {/* top row: next prayer label + mute icon */}
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 8,
            fontFamily: T.fontArabic, fontSize: 13,
            color: 'rgba(255,255,255,0.75)', letterSpacing: 0.2,
          }}>
            <StarMark size={11} color="#D5B76A"/>
            الصلاة القادمة
          </div>
          <div style={{
            width: 32, height: 32, borderRadius: T.r_pill,
            background: 'rgba(255,255,255,0.12)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="bell" size={15} color="#fff"/>
          </div>
        </div>

        {/* big prayer name + countdown */}
        <div style={{ marginTop: 10, display: 'flex', alignItems: 'baseline', gap: 14 }}>
          <div style={{
            fontFamily: T.fontArabic, fontSize: 44, fontWeight: 600,
            color: '#fff', letterSpacing: -0.5, lineHeight: 1,
          }}>العصر</div>
          <div style={{
            fontFamily: T.fontNum, fontSize: 18, color: '#D5B76A',
            letterSpacing: 0.5,
          }}>15:41</div>
        </div>

        <div style={{ marginTop: 8, display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            fontFamily: T.fontArabic, fontSize: 14,
            color: 'rgba(255,255,255,0.75)',
          }}>تبقّى</div>
          <div style={{
            fontFamily: T.fontNum, fontSize: 14,
            color: '#fff', letterSpacing: 0.3,
          }}>1h 27m</div>
        </div>

        <PrayerRibbon prayers={prayers} nextIdx={nextIdx}/>
      </div>
    </div>
  );
}

function AyahCard() {
  return (
    <div style={{
      borderRadius: T.r_lg, background: T.surface,
      padding: '18px 18px 16px', border: `1px solid ${T.hairline}`,
    }}>
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        marginBottom: 12,
      }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8,
          fontFamily: T.fontUi, fontSize: 11, fontWeight: 500,
          color: T.ink3, letterSpacing: 0.8, textTransform: 'uppercase',
        }}>
          <StarOutline size={11} color={T.gold} strokeWidth={1.2}/>
          آية اليوم
        </div>
        <div style={{
          fontFamily: T.fontUi, fontSize: 11, color: T.ink3,
        }}>البقرة · ٢٥٥</div>
      </div>
      <div style={{
        fontFamily: T.fontQuran, fontSize: 22, lineHeight: 1.9,
        color: T.ink, textAlign: 'right',
      }}>
        اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ
      </div>
      <div style={{
        marginTop: 12, paddingTop: 12, borderTop: `1px solid ${T.hairline}`,
        display: 'flex', gap: 18, fontFamily: T.fontUi, fontSize: 13, color: T.ink2,
      }}>
        <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <Icon name="play" size={13} color={T.ink2}/> استمع
        </span>
        <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <Icon name="share" size={13} color={T.ink2}/> شارك
        </span>
        <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <Icon name="copy" size={13} color={T.ink2}/> نسخ
        </span>
      </div>
    </div>
  );
}

function QuickActionTile({ icon, label }) {
  return (
    <div style={{
      background: T.surface, borderRadius: T.r_lg,
      border: `1px solid ${T.hairline}`,
      padding: '18px 12px 14px',
      display: 'flex', flexDirection: 'column',
      alignItems: 'center', gap: 10,
      minHeight: 96, boxSizing: 'border-box',
    }}>
      <div style={{
        width: 40, height: 40, borderRadius: T.r_md,
        background: T.primarySoft,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <Icon name={icon} size={20} color={T.primary}/>
      </div>
      <div style={{
        fontFamily: T.fontArabic, fontSize: 13, fontWeight: 500,
        color: T.ink, textAlign: 'center',
      }}>{label}</div>
    </div>
  );
}

function QuickActions() {
  const items = [
    { icon: 'quran',    label: 'المصحف' },
    { icon: 'azkar',    label: 'الأذكار' },
    { icon: 'names',    label: 'أسماء الله' },
    { icon: 'compass',  label: 'القبلة' },
    { icon: 'mosque',   label: 'المساجد' },
    { icon: 'tasbeeh',  label: 'المسبحة' },
  ];
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)',
      gap: 10,
    }}>
      {items.map(i => <QuickActionTile key={i.label} {...i}/>)}
    </div>
  );
}

function StreakMini() {
  // 14-day heatmap, most recent on the right (RTL flips it visually)
  const vals = [3,2,4,4,3,2,0,3,4,4,2,3,4,4];
  const tone = (v) => {
    if (v === 0) return T.surfaceSunk;
    if (v === 1) return '#DCE6DC';
    if (v === 2) return '#B9D0BB';
    if (v === 3) return '#6FA074';
    return T.primary;
  };
  return (
    <div style={{
      borderRadius: T.r_lg, background: T.surface,
      border: `1px solid ${T.hairline}`, padding: 16,
    }}>
      <div style={{
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        marginBottom: 12,
      }}>
        <div style={{ fontFamily: T.fontArabic, fontSize: 15, fontWeight: 600, color: T.ink }}>
          سلسلة الأذكار
        </div>
        <div style={{
          fontFamily: T.fontNum, fontSize: 13,
          color: T.primary, fontWeight: 600,
        }}>
          <span style={{ fontSize: 18 }}>١٢</span>
          <span style={{ fontFamily: T.fontArabic, fontSize: 12, color: T.ink3, marginInlineStart: 4 }}>يوم</span>
        </div>
      </div>
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(14, 1fr)',
        gap: 4, direction: 'ltr',
      }}>
        {vals.map((v, i) => (
          <div key={i} style={{
            aspectRatio: '1', borderRadius: 4,
            background: tone(v),
          }}/>
        ))}
      </div>
    </div>
  );
}

function SectionHeader({ title, action }) {
  return (
    <div style={{
      display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
      marginTop: 24, marginBottom: 12,
    }}>
      <div style={{
        fontFamily: T.fontArabic, fontSize: 16, fontWeight: 600,
        color: T.ink, letterSpacing: -0.1,
      }}>{title}</div>
      {action && (
        <div style={{
          fontFamily: T.fontArabic, fontSize: 12, color: T.ink3,
        }}>{action}</div>
      )}
    </div>
  );
}

function TabBar({ active = 0 }) {
  const tabs = [
    { icon: 'home',     label: 'الرئيسية' },
    { icon: 'azkar',    label: 'الأذكار'   },
    { icon: 'quran',    label: 'المصحف'    },
    { icon: 'settings', label: 'الإعدادات' },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      background: 'rgba(255,255,255,0.92)',
      backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
      borderTop: `1px solid ${T.hairline}`,
      padding: '8px 12px 26px',
      display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)',
      direction: 'rtl',
    }}>
      {tabs.map((t, i) => {
        const on = i === active;
        return (
          <div key={t.label} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            padding: '6px 0',
          }}>
            <Icon name={t.icon} size={22} color={on ? T.primary : T.ink3}/>
            <div style={{
              fontFamily: T.fontArabic, fontSize: 10.5,
              color: on ? T.primary : T.ink3,
              fontWeight: on ? 600 : 400,
            }}>{t.label}</div>
          </div>
        );
      })}
    </div>
  );
}

// Status bar for our screens (overlay the phone frame's one)
function ScreenStatusTime() { return null; }

function HomeScreen() {
  return (
    <div style={{
      height: '100%', background: T.bg,
      direction: 'rtl', fontFamily: T.fontArabic,
      display: 'flex', flexDirection: 'column',
      overflow: 'hidden', position: 'relative',
    }}>
      <div style={{
        flex: 1, overflow: 'auto',
        padding: '64px 18px 110px',
      }}>
        {/* greeting */}
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          marginBottom: 16, gap: 12,
        }}>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 12, color: T.ink3, marginBottom: 2, whiteSpace: 'nowrap' }}>السلام عليكم</div>
            <div style={{ fontSize: 18, fontWeight: 600, color: T.ink, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>أحمد</div>
          </div>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 8,
            padding: '6px 10px', borderRadius: T.r_pill,
            background: T.surface, border: `1px solid ${T.hairline}`,
            flexShrink: 0,
          }}>
            <Icon name="location" size={12} color={T.ink2}/>
            <div style={{ fontSize: 12, color: T.ink2, whiteSpace: 'nowrap' }}>الرياض</div>
          </div>
        </div>

        <HeroPrayerCard/>

        <SectionHeader title="الوصول السريع" action=""/>
        <QuickActions/>

        <SectionHeader title="آية اليوم"/>
        <AyahCard/>

        <SectionHeader title="نشاطك" action="عرض الكل"/>
        <StreakMini/>
      </div>
      <TabBar active={0}/>
    </div>
  );
}

Object.assign(window, {
  HomeScreen, HeroPrayerCard, AyahCard, QuickActions, StreakMini, TabBar, SectionHeader,
});
