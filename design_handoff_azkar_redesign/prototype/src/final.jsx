// Final batch of screens: Search, Bookmarks, Profile/Stats, Notifications,
// Duas collection, About/Share, Prayer Tracker.

// ═══════════════════════════════════════════════════════════
// Reusable shell
// ═══════════════════════════════════════════════════════════
function ScreenShell({ title, sub, children, back = true, action, bg = T.bg }) {
  return (
    <div style={{
      width: '100%', height: '100%', background: bg,
      fontFamily: T.fontUi, direction: 'rtl',
      display: 'flex', flexDirection: 'column', overflow: 'hidden',
    }}>
      <div style={{ height: 54, flexShrink: 0 }}/>
      <div style={{
        padding: '8px 20px 14px', display: 'flex',
        alignItems: 'center', justifyContent: 'space-between', gap: 12,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, minWidth: 0 }}>
          {back && (
            <div style={{
              width: 36, height: 36, borderRadius: 99, background: T.surface,
              border: `1px solid ${T.hairline}`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
            }}>
              <Icon name="back" size={16} color={T.ink}/>
            </div>
          )}
          <div style={{ minWidth: 0 }}>
            <div style={{ fontSize: 17, fontWeight: 600, color: T.ink, lineHeight: 1.2 }}>{title}</div>
            {sub && <div style={{ fontSize: 12, color: T.ink3, marginTop: 2 }}>{sub}</div>}
          </div>
        </div>
        {action}
      </div>
      <div style={{ flex: 1, overflow: 'auto' }}>{children}</div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════
// 19 — Global Search
// ═══════════════════════════════════════════════════════════
function SearchScreen() {
  const recents = ['أذكار الصباح', 'سورة الكهف', 'دعاء السفر', 'اية الكرسي'];
  const results = [
    { type: 'ذكر',   ar: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', meta: 'أذكار الصباح · يُقال ١٠٠ مرة' },
    { type: 'سورة', ar: 'سورة الكهف',              meta: 'الجزء ١٥ · ١١٠ آيات · مكية' },
    { type: 'اسم',  ar: 'الرَّحْمَـٰنُ',              meta: 'الاسم ١ من أسماء الله الحسنى' },
    { type: 'دعاء', ar: 'اللَّهُمَّ بَارِكْ لَنَا',        meta: 'أدعية مأثورة · عند الطعام' },
  ];
  const Chip = ({ children, active }) => (
    <div style={{
      padding: '7px 14px', borderRadius: 99, fontSize: 12,
      background: active ? T.ink : T.surface,
      color:      active ? '#fff' : T.ink2,
      border: `1px solid ${active ? T.ink : T.hairline}`,
      whiteSpace: 'nowrap',
    }}>{children}</div>
  );
  return (
    <ScreenShell title="بحث" back={false}>
      <div style={{ padding: '0 20px 14px' }}>
        <div style={{
          background: T.surface, border: `1px solid ${T.hairline}`,
          borderRadius: T.r_md, padding: '12px 14px',
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <Icon name="search" size={18} color={T.ink3}/>
          <div style={{ fontSize: 15, color: T.ink, flex: 1 }}>الكهف</div>
          <div style={{
            width: 22, height: 22, borderRadius: 99, background: T.surfaceSunk,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="close" size={10} color={T.ink3}/>
          </div>
        </div>
      </div>

      <div style={{ padding: '0 20px 16px', display: 'flex', gap: 6, overflowX: 'auto' }}>
        <Chip active>الكل · ٢٤</Chip>
        <Chip>أذكار · ٨</Chip>
        <Chip>قرآن · ٩</Chip>
        <Chip>أدعية · ٥</Chip>
        <Chip>أسماء · ٢</Chip>
      </div>

      <div style={{ padding: '0 20px' }}>
        <div style={{ fontSize: 11, color: T.ink3, fontWeight: 600, marginBottom: 10, letterSpacing: 0.4 }}>
          ٢٤ نتيجة
        </div>
        <div style={{ background: T.surface, border: `1px solid ${T.hairline}`, borderRadius: T.r_md, overflow: 'hidden' }}>
          {results.map((r, i) => (
            <React.Fragment key={i}>
              <div style={{ padding: '14px 16px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                  <div style={{
                    fontSize: 10, fontWeight: 600, color: T.primary,
                    background: T.primarySoft, padding: '2px 8px', borderRadius: 99,
                  }}>{r.type}</div>
                </div>
                <div style={{
                  fontFamily: T.fontQuran, fontSize: 17, color: T.ink,
                  lineHeight: 1.6, marginBottom: 4,
                }}>{r.ar}</div>
                <div style={{ fontSize: 12, color: T.ink3 }}>{r.meta}</div>
              </div>
              {i < results.length - 1 && <Hair inset={16}/>}
            </React.Fragment>
          ))}
        </div>
      </div>

      <div style={{ padding: '20px', marginTop: 4 }}>
        <div style={{ fontSize: 11, color: T.ink3, fontWeight: 600, marginBottom: 10, letterSpacing: 0.4 }}>
          عمليات البحث الأخيرة
        </div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
          {recents.map((r, i) => (
            <div key={i} style={{
              padding: '8px 14px', borderRadius: 99, fontSize: 13,
              background: T.surface, color: T.ink2,
              border: `1px solid ${T.hairline}`,
              display: 'flex', alignItems: 'center', gap: 8,
            }}>
              <Icon name="search" size={11} color={T.ink3}/>
              {r}
            </div>
          ))}
        </div>
      </div>
    </ScreenShell>
  );
}

// ═══════════════════════════════════════════════════════════
// 20 — Bookmarks hub
// ═══════════════════════════════════════════════════════════
function BookmarksScreen() {
  const groups = [
    {
      label: 'القرآن الكريم',
      items: [
        { ar: 'سورة الكهف · الآية ١٠',  sub: 'يوم الجمعة · منذ ٣ أيام', kind: 'quran' },
        { ar: 'سورة يس · الآية ٨٢',      sub: 'منذ أسبوع', kind: 'quran' },
        { ar: 'سورة البقرة · الآية ٢٥٥', sub: 'آية الكرسي · محفوظة',  kind: 'quran' },
      ],
    },
    {
      label: 'أذكار',
      items: [
        { ar: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', sub: 'أذكار الصباح · يومي',  kind: 'zikr' },
        { ar: 'لَا إِلَهَ إِلَّا اللَّهُ',          sub: 'دعاء الاستغفار',      kind: 'zikr' },
      ],
    },
    {
      label: 'أدعية',
      items: [
        { ar: 'دعاء دخول المسجد', sub: 'مأثور',         kind: 'dua' },
        { ar: 'دعاء السفر',       sub: 'مُضاف منذ شهر', kind: 'dua' },
      ],
    },
  ];
  return (
    <ScreenShell title="المحفوظات" sub="٧ عناصر محفوظة">
      <div style={{ padding: '0 20px 24px' }}>
        {groups.map((g, gi) => (
          <div key={gi} style={{ marginBottom: 22 }}>
            <div style={{
              fontSize: 11, color: T.ink3, fontWeight: 600, marginBottom: 10,
              display: 'flex', justifyContent: 'space-between',
            }}>
              <div>{g.label}</div>
              <div style={{ color: T.ink4 }}>{g.items.length}</div>
            </div>
            <div style={{ background: T.surface, border: `1px solid ${T.hairline}`, borderRadius: T.r_md, overflow: 'hidden' }}>
              {g.items.map((it, i) => (
                <React.Fragment key={i}>
                  <div style={{ padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12 }}>
                    <div style={{
                      width: 38, height: 38, borderRadius: 10,
                      background: it.kind === 'quran' ? T.goldSoft : T.primarySoft,
                      display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                    }}>
                      <Icon name={it.kind === 'quran' ? 'quran' : it.kind === 'dua' ? 'heart' : 'azkar'}
                        size={18} color={it.kind === 'quran' ? T.gold : T.primary}/>
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{
                        fontSize: 14, fontWeight: 500, color: T.ink,
                        fontFamily: it.kind === 'quran' ? T.fontQuran : T.fontUi,
                        marginBottom: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                      }}>{it.ar}</div>
                      <div style={{ fontSize: 11, color: T.ink3 }}>{it.sub}</div>
                    </div>
                    <Icon name="bookmark" size={14} color={T.gold} fill="solid"/>
                  </div>
                  {i < g.items.length - 1 && <Hair inset={16}/>}
                </React.Fragment>
              ))}
            </div>
          </div>
        ))}
      </div>
    </ScreenShell>
  );
}

// ═══════════════════════════════════════════════════════════
// 21 — Profile / Stats / Streak
// ═══════════════════════════════════════════════════════════
function ProfileScreen() {
  const stats = [
    { label: 'الصلوات', value: '٣٥', total: '/٣٥', tag: 'هذا الأسبوع' },
    { label: 'الأذكار', value: '١٤٢', total: '',     tag: 'جلسة' },
    { label: 'تلاوة',   value: '١٢',  total: ' ج',   tag: 'جزء' },
  ];
  const days = ['س','ج','خ','أ','ث','إ','ح'];
  return (
    <ScreenShell title="حسابي" bg={T.bg}>
      {/* Streak hero */}
      <div style={{ padding: '0 20px 20px' }}>
        <div style={{
          background: T.ink, color: '#fff', borderRadius: T.r_lg,
          padding: '26px 22px', position: 'relative', overflow: 'hidden',
        }}>
          <GeoWatermark opacity={0.07} color="#fff" size={280} top={-80} right={-80}/>
          <div style={{ fontSize: 12, opacity: 0.65, marginBottom: 6 }}>سلسلة مستمرة</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
            <div style={{ fontSize: 56, fontWeight: 300, lineHeight: 1, letterSpacing: -1 }}>٤٢</div>
            <div style={{ fontSize: 14, opacity: 0.7 }}>يوماً</div>
          </div>
          <div style={{ fontSize: 12, opacity: 0.55, marginTop: 6 }}>آخر ذكر: قبل ٣ ساعات</div>
          <div style={{ display: 'flex', gap: 6, marginTop: 22 }}>
            {days.map((d, i) => {
              const done = i < 6;
              return (
                <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
                  <div style={{
                    width: '100%', aspectRatio: '1', borderRadius: 10,
                    background: done ? '#fff' : 'rgba(255,255,255,0.1)',
                    border: done ? 'none' : '1px dashed rgba(255,255,255,0.3)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                    {done && <StarMark size={10} color={T.ink}/>}
                  </div>
                  <div style={{ fontSize: 10, opacity: 0.6 }}>{d}</div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Stats */}
      <div style={{ padding: '0 20px 20px' }}>
        <div style={{ fontSize: 11, color: T.ink3, fontWeight: 600, marginBottom: 10 }}>إحصاءات الأسبوع</div>
        <div style={{ background: T.surface, border: `1px solid ${T.hairline}`, borderRadius: T.r_md, overflow: 'hidden' }}>
          {stats.map((s, i) => (
            <React.Fragment key={i}>
              <div style={{ padding: '16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                  <div style={{ fontSize: 13, color: T.ink, fontWeight: 500 }}>{s.label}</div>
                  <div style={{ fontSize: 11, color: T.ink3, marginTop: 2 }}>{s.tag}</div>
                </div>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 2 }}>
                  <div style={{ fontSize: 22, fontWeight: 500, color: T.ink, fontFamily: T.fontArabic }}>{s.value}</div>
                  <div style={{ fontSize: 13, color: T.ink3 }}>{s.total}</div>
                </div>
              </div>
              {i < stats.length - 1 && <Hair inset={16}/>}
            </React.Fragment>
          ))}
        </div>
      </div>

      {/* Achievements */}
      <div style={{ padding: '0 20px 24px' }}>
        <div style={{ fontSize: 11, color: T.ink3, fontWeight: 600, marginBottom: 10 }}>إنجازات</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10 }}>
          {[
            { i: 'sun', label: '٣٠ يوماً متواصلاً', color: T.gold, bg: T.goldSoft, got: true },
            { i: 'quran', label: 'ختمة كاملة',     color: T.primary, bg: T.primarySoft, got: true },
            { i: 'moon', label: 'قيام الليل ×٧',    color: T.ink3, bg: T.surfaceSunk, got: false },
          ].map((a, i) => (
            <div key={i} style={{
              background: T.surface, border: `1px solid ${T.hairline}`, borderRadius: T.r_md,
              padding: '16px 10px', textAlign: 'center', opacity: a.got ? 1 : 0.5,
            }}>
              <div style={{
                width: 40, height: 40, borderRadius: 99, background: a.bg, margin: '0 auto 8px',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name={a.i} size={18} color={a.color}/>
              </div>
              <div style={{ fontSize: 10.5, color: T.ink2, fontWeight: 500, lineHeight: 1.3 }}>{a.label}</div>
            </div>
          ))}
        </div>
      </div>
    </ScreenShell>
  );
}

// ═══════════════════════════════════════════════════════════
// 22 — Notifications / Reminders detail
// ═══════════════════════════════════════════════════════════
function NotificationsScreen() {
  const Row = ({ label, sub, on }) => {
    const [v, setV] = React.useState(on);
    return (
      <div style={{ padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 14, color: T.ink, fontWeight: 500 }}>{label}</div>
          {sub && <div style={{ fontSize: 11, color: T.ink3, marginTop: 2 }}>{sub}</div>}
        </div>
        <div onClick={() => setV(!v)} style={{
          width: 46, height: 28, borderRadius: 99,
          background: v ? T.primary : T.hairlineStrong,
          position: 'relative', cursor: 'pointer', transition: 'background 0.15s',
        }}>
          <div style={{
            position: 'absolute', top: 2, [v ? 'left' : 'right']: 2,
            width: 24, height: 24, borderRadius: 99, background: '#fff',
            boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
          }}/>
        </div>
      </div>
    );
  };
  return (
    <ScreenShell title="التنبيهات">
      <div style={{ padding: '0 20px 24px' }}>
        {/* Prayer reminders */}
        <div style={{ fontSize: 11, color: T.ink3, fontWeight: 600, marginBottom: 10 }}>الصلوات الخمس</div>
        <div style={{ background: T.surface, border: `1px solid ${T.hairline}`, borderRadius: T.r_md, overflow: 'hidden', marginBottom: 20 }}>
          <Row label="الفجر"   sub="٠٤:٥٢ · أذان كامل · ميكي"  on={true}/>
          <Hair inset={16}/>
          <Row label="الظهر"   sub="١٢:٤٠ · تنبيه خفيف"         on={true}/>
          <Hair inset={16}/>
          <Row label="العصر"   sub="١٦:٠٥ · أذان كامل"          on={true}/>
          <Hair inset={16}/>
          <Row label="المغرب"  sub="١٩:٢٢ · أذان كامل"          on={true}/>
          <Hair inset={16}/>
          <Row label="العشاء"  sub="٢٠:٥٣ · تنبيه خفيف"         on={false}/>
        </div>

        {/* Adhan sound */}
        <div style={{ fontSize: 11, color: T.ink3, fontWeight: 600, marginBottom: 10 }}>صوت الأذان</div>
        <div style={{ background: T.surface, border: `1px solid ${T.hairline}`, borderRadius: T.r_md, overflow: 'hidden', marginBottom: 20 }}>
          {[
            { n: 'المسجد الحرام · مكة',  sel: true  },
            { n: 'المسجد النبوي · المدينة', sel: false },
            { n: 'مشاري راشد العفاسي',      sel: false },
            { n: 'تنبيه قصير',               sel: false },
          ].map((o, i, a) => (
            <React.Fragment key={i}>
              <div style={{ padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{
                  width: 20, height: 20, borderRadius: 99, flexShrink: 0,
                  border: `2px solid ${o.sel ? T.primary : T.hairlineStrong}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  {o.sel && <div style={{ width: 10, height: 10, borderRadius: 99, background: T.primary }}/>}
                </div>
                <div style={{ flex: 1, fontSize: 14, color: T.ink, fontWeight: 500 }}>{o.n}</div>
                {o.sel && <Icon name="play" size={12} color={T.ink3} fill="solid"/>}
              </div>
              {i < a.length - 1 && <Hair inset={16}/>}
            </React.Fragment>
          ))}
        </div>

        {/* Azkar reminders */}
        <div style={{ fontSize: 11, color: T.ink3, fontWeight: 600, marginBottom: 10 }}>تذكير بالأذكار</div>
        <div style={{ background: T.surface, border: `1px solid ${T.hairline}`, borderRadius: T.r_md, overflow: 'hidden' }}>
          <Row label="أذكار الصباح" sub="الساعة ٠٦:٣٠ يومياً"   on={true}/>
          <Hair inset={16}/>
          <Row label="أذكار المساء" sub="الساعة ١٧:٠٠ يومياً"   on={true}/>
          <Hair inset={16}/>
          <Row label="قيام الليل"   sub="الساعة ٠٣:٣٠ · اختياري" on={false}/>
          <Hair inset={16}/>
          <Row label="سورة الكهف يوم الجمعة" sub="الفجر · تلقائي" on={true}/>
        </div>
      </div>
    </ScreenShell>
  );
}

// ═══════════════════════════════════════════════════════════
// 23 — Duas collection
// ═══════════════════════════════════════════════════════════
function DuasScreen() {
  const categories = [
    { ar: 'أدعية الصباح والمساء',   count: 24, i: 'sun' },
    { ar: 'أدعية من القرآن',         count: 48, i: 'quran' },
    { ar: 'أدعية الطعام والشراب',    count: 12, i: 'azkar' },
    { ar: 'أدعية السفر والخروج',     count: 16, i: 'location' },
    { ar: 'أدعية الكرب والحزن',      count: 22, i: 'heart' },
    { ar: 'أدعية الاستغفار والتوبة', count: 18, i: 'moon' },
  ];
  const featured = {
    ar: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
    ref: 'رواه مسلم · ٢٧٢١',
  };
  return (
    <ScreenShell title="الأدعية" sub="١٤٠ دعاء في ٦ تصنيفات">
      {/* Featured */}
      <div style={{ padding: '0 20px 20px' }}>
        <div style={{
          background: T.surface, border: `1px solid ${T.hairline}`, borderRadius: T.r_lg,
          padding: '24px', position: 'relative', overflow: 'hidden',
        }}>
          <GeoWatermark opacity={0.04} color={T.primary} size={200} top={-40} right={-40}/>
          <div style={{
            fontSize: 10, color: T.gold, fontWeight: 600, marginBottom: 12, letterSpacing: 0.8,
          }}>دعاء اليوم</div>
          <div style={{
            fontFamily: T.fontQuran, fontSize: 22, color: T.ink,
            lineHeight: 1.9, marginBottom: 14,
          }}>{featured.ar}</div>
          <div style={{
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            paddingTop: 14, borderTop: `1px solid ${T.hairline}`,
          }}>
            <div style={{ fontSize: 11, color: T.ink3 }}>{featured.ref}</div>
            <div style={{ display: 'flex', gap: 14 }}>
              <Icon name="play" size={16} color={T.ink2}/>
              <Icon name="copy" size={16} color={T.ink2}/>
              <Icon name="bookmark" size={16} color={T.ink2}/>
            </div>
          </div>
        </div>
      </div>

      {/* Categories */}
      <div style={{ padding: '0 20px 24px' }}>
        <div style={{ fontSize: 11, color: T.ink3, fontWeight: 600, marginBottom: 10 }}>التصنيفات</div>
        <div style={{ background: T.surface, border: `1px solid ${T.hairline}`, borderRadius: T.r_md, overflow: 'hidden' }}>
          {categories.map((c, i) => (
            <React.Fragment key={i}>
              <div style={{ padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{
                  width: 36, height: 36, borderRadius: 10, background: T.primarySoft,
                  display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                }}>
                  <Icon name={c.i} size={17} color={T.primary}/>
                </div>
                <div style={{ flex: 1, fontSize: 14, color: T.ink, fontWeight: 500 }}>{c.ar}</div>
                <div style={{ fontSize: 12, color: T.ink3, fontFamily: T.fontArabic }}>{toAr(c.count)}</div>
                <Icon name="chevL" size={14} color={T.ink4}/>
              </div>
              {i < categories.length - 1 && <Hair inset={16}/>}
            </React.Fragment>
          ))}
        </div>
      </div>
    </ScreenShell>
  );
}

// ═══════════════════════════════════════════════════════════
// 24 — Prayer tracker
// ═══════════════════════════════════════════════════════════
function PrayerTrackerScreen() {
  const days = [
    { d: 'السبت',   date: '١٤', prayers: [1,1,1,1,1] },
    { d: 'الجمعة',  date: '١٣', prayers: [1,1,1,1,1] },
    { d: 'الخميس',  date: '١٢', prayers: [1,1,1,1,0] },
    { d: 'الأربعاء', date: '١١', prayers: [1,1,1,1,1] },
    { d: 'الثلاثاء', date: '١٠', prayers: [1,1,0,1,1] },
    { d: 'الإثنين',  date: '٩',  prayers: [1,1,1,1,1] },
    { d: 'الأحد',    date: '٨',  prayers: [0,1,1,1,1] },
  ];
  const labels = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
  const today = [1, 1, 1, 0, 0];
  return (
    <ScreenShell title="متابعة الصلوات" sub="هذا الأسبوع">
      {/* Today hero */}
      <div style={{ padding: '0 20px 20px' }}>
        <div style={{
          background: T.surface, border: `1px solid ${T.hairline}`, borderRadius: T.r_lg,
          padding: '22px',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 20 }}>
            <div>
              <div style={{ fontSize: 11, color: T.ink3, fontWeight: 500, marginBottom: 4 }}>اليوم · السبت</div>
              <div style={{ fontSize: 22, fontWeight: 500, color: T.ink, fontFamily: T.fontArabic }}>
                ٣ <span style={{ fontSize: 14, color: T.ink3, fontWeight: 400 }}>/ ٥ صلوات</span>
              </div>
            </div>
            <div style={{
              fontSize: 11, color: T.primary, fontWeight: 600,
              background: T.primarySoft, padding: '4px 10px', borderRadius: 99,
            }}>في الموعد</div>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            {today.map((p, i) => (
              <div key={i} style={{ flex: 1, textAlign: 'center' }}>
                <div style={{
                  width: '100%', aspectRatio: '1', borderRadius: 12,
                  background: p ? T.primary : T.bg,
                  border: p ? 'none' : `1.5px dashed ${T.hairlineStrong}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  marginBottom: 8,
                }}>
                  {p ? (
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                      <path d="M5 12 L10 17 L19 7" stroke="#fff" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  ) : null}
                </div>
                <div style={{ fontSize: 10, color: p ? T.ink : T.ink3, fontWeight: p ? 600 : 500 }}>
                  {labels[i]}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Week history */}
      <div style={{ padding: '0 20px 24px' }}>
        <div style={{ fontSize: 11, color: T.ink3, fontWeight: 600, marginBottom: 10 }}>الأسبوع الماضي</div>
        <div style={{ background: T.surface, border: `1px solid ${T.hairline}`, borderRadius: T.r_md, overflow: 'hidden' }}>
          {days.map((day, di) => (
            <React.Fragment key={di}>
              <div style={{ padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 14 }}>
                <div style={{ minWidth: 56 }}>
                  <div style={{ fontSize: 13, color: T.ink, fontWeight: 500 }}>{day.d}</div>
                  <div style={{ fontSize: 11, color: T.ink3, marginTop: 2, fontFamily: T.fontArabic }}>{day.date} ذو القعدة</div>
                </div>
                <div style={{ flex: 1, display: 'flex', gap: 5 }}>
                  {day.prayers.map((p, pi) => (
                    <div key={pi} style={{
                      flex: 1, height: 8, borderRadius: 99,
                      background: p ? T.primary : T.surfaceSunk,
                    }}/>
                  ))}
                </div>
                <div style={{
                  fontSize: 12, color: T.ink2, fontWeight: 600, fontFamily: T.fontArabic, minWidth: 28,
                  textAlign: 'left',
                }}>
                  {toAr(day.prayers.reduce((a,b) => a+b, 0))}/{toAr(5)}
                </div>
              </div>
              {di < days.length - 1 && <Hair inset={16}/>}
            </React.Fragment>
          ))}
        </div>
        <div style={{ textAlign: 'center', marginTop: 16 }}>
          <div style={{
            display: 'inline-block', padding: '10px 18px', borderRadius: 99,
            background: T.surface, border: `1px solid ${T.hairline}`,
            fontSize: 12, color: T.ink2, fontWeight: 500,
          }}>عرض المزيد من الأيام</div>
        </div>
      </div>
    </ScreenShell>
  );
}

// ═══════════════════════════════════════════════════════════
// 25 — About & Share
// ═══════════════════════════════════════════════════════════
function AboutScreen() {
  return (
    <ScreenShell title="حول التطبيق" bg={T.bg}>
      <div style={{ padding: '20px 20px 32px', textAlign: 'center' }}>
        {/* Logo block */}
        <div style={{
          width: 88, height: 88, borderRadius: 24, background: T.ink,
          margin: '0 auto 16px', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 8px 20px rgba(20,24,20,0.2)',
        }}>
          <StarMark size={42} color={T.gold}/>
        </div>
        <div style={{ fontSize: 22, fontWeight: 600, color: T.ink, marginBottom: 4 }}>أذكار</div>
        <div style={{ fontSize: 12, color: T.ink3 }}>الإصدار ٣.٠.٠ · بناء ٢٤٠</div>
      </div>

      <div style={{ padding: '0 20px 24px' }}>
        {/* Share CTA */}
        <div style={{
          background: T.primary, color: '#fff', borderRadius: T.r_lg,
          padding: '22px 20px', marginBottom: 20, position: 'relative', overflow: 'hidden',
        }}>
          <GeoWatermark opacity={0.1} color="#fff" size={220} top={-60} right={-60}/>
          <div style={{
            fontFamily: T.fontQuran, fontSize: 18, lineHeight: 1.7, marginBottom: 14,
          }}>
            «الدَّالُّ عَلَى الْخَيْرِ كَفَاعِلِهِ»
          </div>
          <div style={{ fontSize: 11, opacity: 0.75, marginBottom: 16 }}>رواه الترمذي</div>
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{
              flex: 1, background: '#fff', color: T.ink, padding: '12px',
              borderRadius: 10, fontSize: 13, fontWeight: 600, textAlign: 'center',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            }}>
              <Icon name="share" size={14}/>
              شارك التطبيق
            </div>
            <div style={{
              flex: 1, background: 'rgba(255,255,255,0.15)', color: '#fff', padding: '12px',
              borderRadius: 10, fontSize: 13, fontWeight: 500, textAlign: 'center',
              border: '1px solid rgba(255,255,255,0.25)',
            }}>
              قيّمنا ★★★★★
            </div>
          </div>
        </div>

        {/* Info groups */}
        <div style={{ background: T.surface, border: `1px solid ${T.hairline}`, borderRadius: T.r_md, overflow: 'hidden', marginBottom: 20 }}>
          {[
            { l: 'مصادر البيانات',   r: 'نوعى · ثقات' },
            { l: 'المُدقّقون الشرعيون', r: 'أ.د. عبد الله' },
            { l: 'حقوق التلاوات',   r: 'بإذن القرّاء' },
            { l: 'الموقع الإلكتروني', r: 'azkar.app' },
          ].map((it, i, a) => (
            <React.Fragment key={i}>
              <div style={{ padding: '14px 16px', display: 'flex', justifyContent: 'space-between' }}>
                <div style={{ fontSize: 14, color: T.ink }}>{it.l}</div>
                <div style={{ fontSize: 13, color: T.ink3 }}>{it.r}</div>
              </div>
              {i < a.length - 1 && <Hair inset={16}/>}
            </React.Fragment>
          ))}
        </div>

        {/* Links */}
        <div style={{ background: T.surface, border: `1px solid ${T.hairline}`, borderRadius: T.r_md, overflow: 'hidden' }}>
          {['سياسة الخصوصية', 'شروط الاستخدام', 'التراخيص مفتوحة المصدر', 'تواصل معنا'].map((it, i, a) => (
            <React.Fragment key={i}>
              <div style={{ padding: '14px 16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div style={{ fontSize: 14, color: T.ink }}>{it}</div>
                <Icon name="chevL" size={14} color={T.ink4}/>
              </div>
              {i < a.length - 1 && <Hair inset={16}/>}
            </React.Fragment>
          ))}
        </div>

        <div style={{
          textAlign: 'center', marginTop: 28, fontSize: 11, color: T.ink3, lineHeight: 1.8,
        }}>
          صُنع بحب لخدمة القرآن والسنّة<br/>
          © ١٤٤٦هـ · مجاني بلا إعلانات
        </div>
      </div>
    </ScreenShell>
  );
}

Object.assign(window, {
  SearchScreen,
  BookmarksScreen,
  ProfileScreen,
  NotificationsScreen,
  DuasScreen,
  PrayerTrackerScreen,
  AboutScreen,
});
