// Qibla compass + Prayer times detail + Hijri calendar + Settings

function QiblaScreen() {
  const heading = 218;      // pointer target angle
  const qiblaFrom = -18;    // currently offset (rotate indicator)
  return (
    <div style={{
      height: '100%', background: T.bg, direction: 'rtl',
      fontFamily: T.fontArabic, display: 'flex', flexDirection: 'column',
      overflow: 'hidden', position: 'relative',
    }}>
      <div style={{ padding: '58px 18px 14px',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Icon name="chevR" size={22} color={T.ink}/>
        <div style={{ fontSize: 16, fontWeight: 600, color: T.ink }}>القبلة</div>
        <div style={{ width: 22 }}/>
      </div>

      <div style={{
        flex: 1, padding: '12px 22px',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
      }}>
        {/* status pill */}
        <div style={{
          padding: '8px 14px', borderRadius: T.r_pill,
          background: T.primarySoft, color: T.primary,
          fontSize: 12, fontWeight: 600,
          display: 'flex', alignItems: 'center', gap: 6,
        }}>
          <div style={{ width: 6, height: 6, borderRadius: 99, background: T.primary }}/>
          استدر قليلاً إلى اليسار
        </div>

        {/* compass */}
        <div style={{
          position: 'relative', width: 300, height: 300, marginTop: 32,
        }}>
          <svg viewBox="0 0 300 300" style={{ position: 'absolute', inset: 0 }}>
            {/* outer ring */}
            <circle cx="150" cy="150" r="140" fill={T.surface}
              stroke={T.hairlineStrong} strokeWidth="1"/>
            <circle cx="150" cy="150" r="130" fill="none"
              stroke={T.hairline} strokeWidth="1" strokeDasharray="2 4"/>
            {/* cardinal markers */}
            {Array.from({length: 72}).map((_, i) => {
              const a = (i / 72) * Math.PI * 2 - Math.PI / 2;
              const major = i % 9 === 0;
              const r1 = major ? 120 : 126;
              const x1 = 150 + r1 * Math.cos(a), y1 = 150 + r1 * Math.sin(a);
              const x2 = 150 + 134 * Math.cos(a), y2 = 150 + 134 * Math.sin(a);
              return <line key={i} x1={x1} y1={y1} x2={x2} y2={y2}
                stroke={major ? T.ink2 : T.ink4} strokeWidth={major ? 1.5 : 1}/>;
            })}
            {/* cardinal labels */}
            {[['ش',0],['ق',90],['ج',180],['غ',270]].map(([l, deg]) => {
              const a = (deg / 360) * Math.PI * 2 - Math.PI / 2;
              const x = 150 + 106 * Math.cos(a), y = 150 + 106 * Math.sin(a) + 5;
              return <text key={l} x={x} y={y} textAnchor="middle"
                fontFamily={T.fontArabic} fontSize="13"
                fill={l === 'ش' ? T.danger : T.ink2} fontWeight={l === 'ش' ? 700 : 500}>{l}</text>;
            })}

            {/* kaaba marker pointing toward qibla */}
            <g transform={`rotate(${qiblaFrom} 150 150)`}>
              <line x1="150" y1="150" x2="150" y2="44"
                stroke={T.primary} strokeWidth="2" strokeLinecap="round"/>
              <polygon points="150,30 144,52 156,52" fill={T.primary}/>
              <circle cx="150" cy="24" r="16" fill={T.primary}/>
              <rect x="143" y="18" width="14" height="12" fill="#0F3A13"/>
              <rect x="143" y="18" width="14" height="3" fill="#D5B76A"/>
            </g>

            {/* center */}
            <circle cx="150" cy="150" r="6" fill={T.ink}/>
            <circle cx="150" cy="150" r="2" fill="#fff"/>
          </svg>
        </div>

        {/* degrees readout */}
        <div style={{
          marginTop: 32, display: 'flex', gap: 30,
        }}>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 11, color: T.ink3, marginBottom: 4, letterSpacing: 0.6 }}>اتجاه القبلة</div>
            <div style={{ fontFamily: T.fontNum, fontSize: 24, color: T.ink, fontWeight: 600 }}>
              {toAr(heading)}°
            </div>
          </div>
          <div style={{ width: 1, background: T.hairline }}/>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 11, color: T.ink3, marginBottom: 4, letterSpacing: 0.6 }}>المسافة لمكة</div>
            <div style={{ fontFamily: T.fontNum, fontSize: 24, color: T.ink, fontWeight: 600 }}>
              ٨٨٧ <span style={{ fontSize: 14, color: T.ink3, fontWeight: 400 }}>كم</span>
            </div>
          </div>
        </div>

        {/* calibration note */}
        <div style={{
          marginTop: 28, padding: '10px 14px',
          background: T.surfaceSunk, borderRadius: T.r_md,
          fontSize: 11, color: T.ink3, textAlign: 'center',
        }}>
          حرّك الهاتف على شكل ٨ للمعايرة
        </div>
      </div>
    </div>
  );
}

function PrayerTimesScreen() {
  const prayers = [
    { name: 'الفجر',   time: '04:52', ar: '٠٤:٥٢', sub: 'الشروق ٠٦:١٤', icon: 'sun',   active: false, past: true },
    { name: 'الظهر',   time: '12:14', ar: '١٢:١٤', sub: 'أذان مباشر',    icon: 'sun',   active: false, past: true },
    { name: 'العصر',   time: '15:41', ar: '١٥:٤١', sub: 'بعد ساعة و ٢٧ دقيقة', icon: 'sun',   active: true,  past: false },
    { name: 'المغرب',  time: '18:27', ar: '١٨:٢٧', sub: 'الإفطار',       icon: 'moon',  active: false, past: false },
    { name: 'العشاء',  time: '19:48', ar: '١٩:٤٨', sub: 'أذان كامل',      icon: 'moon',  active: false, past: false },
  ];
  return (
    <div style={{
      height: '100%', background: T.bg, direction: 'rtl',
      fontFamily: T.fontArabic, display: 'flex', flexDirection: 'column',
      overflow: 'hidden', position: 'relative',
    }}>
      <div style={{ flex: 1, overflow: 'auto', padding: '58px 18px 40px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Icon name="chevR" size={22} color={T.ink}/>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 14, fontWeight: 600, color: T.ink }}>مواقيت الصلاة</div>
            <div style={{ fontSize: 11, color: T.ink3, marginTop: 2 }}>الرياض · السعودية</div>
          </div>
          <Icon name="calendar" size={20} color={T.ink2}/>
        </div>

        {/* date card */}
        <div style={{
          marginTop: 18, borderRadius: T.r_lg,
          background: T.surface, border: `1px solid ${T.hairline}`,
          padding: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        }}>
          <div>
            <div style={{ fontSize: 11, color: T.ink3, letterSpacing: 0.6, marginBottom: 4 }}>اليوم</div>
            <div style={{ fontSize: 17, fontWeight: 600, color: T.ink }}>الأحد، ١٩ أبريل</div>
            <div style={{ fontSize: 12, color: T.ink2, marginTop: 2 }}>١ ذو القعدة ١٤٤٧ هـ</div>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{
              width: 34, height: 34, borderRadius: T.r_pill,
              background: T.surfaceSunk,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Icon name="chevR" size={14} color={T.ink2}/>
            </div>
            <div style={{
              width: 34, height: 34, borderRadius: T.r_pill,
              background: T.surfaceSunk,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Icon name="chevL" size={14} color={T.ink2}/>
            </div>
          </div>
        </div>

        {/* Prayer list */}
        <div style={{
          marginTop: 18, borderRadius: T.r_lg,
          background: T.surface, border: `1px solid ${T.hairline}`, overflow: 'hidden',
        }}>
          {prayers.map((p, i) => (
            <div key={p.name}>
              <div style={{
                padding: '16px 18px',
                display: 'flex', alignItems: 'center', gap: 14,
                background: p.active ? T.primarySoft : 'transparent',
              }}>
                <div style={{
                  width: 38, height: 38, borderRadius: T.r_sm,
                  background: p.active ? T.primary : T.surfaceSunk,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  opacity: p.past ? 0.5 : 1,
                }}>
                  <Icon name={p.icon} size={18} color={p.active ? '#fff' : T.ink2}/>
                </div>
                <div style={{ flex: 1, opacity: p.past ? 0.55 : 1 }}>
                  <div style={{
                    fontSize: 16, fontWeight: p.active ? 700 : 600,
                    color: p.active ? T.primaryInk : T.ink,
                  }}>{p.name}</div>
                  <div style={{ fontSize: 11, color: p.active ? T.primary : T.ink3, marginTop: 2 }}>{p.sub}</div>
                </div>
                <div style={{
                  fontFamily: T.fontNum, fontSize: 18, fontWeight: 600,
                  color: p.active ? T.primary : (p.past ? T.ink3 : T.ink),
                  letterSpacing: 0.3,
                }}>{p.time}</div>
                <Icon name="bell" size={16} color={p.active ? T.primary : T.ink3}/>
              </div>
              {i < prayers.length - 1 && <Hair inset={18}/>}
            </div>
          ))}
        </div>

        {/* Method footer */}
        <div style={{
          marginTop: 14, padding: '12px 16px',
          background: 'transparent', borderRadius: T.r_md,
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          fontSize: 12, color: T.ink3,
        }}>
          <div>طريقة الحساب · أم القرى</div>
          <div style={{ color: T.ink2, fontWeight: 500 }}>تغيير</div>
        </div>
      </div>
    </div>
  );
}

function HijriCalendarScreen() {
  // Ramadan layout
  const month = 'ذو القعدة';
  const year = '١٤٤٧';
  const startDay = 3; // offset
  const days = 30;
  const today = 1;
  const weekdays = ['أ', 'ث', 'ر', 'خ', 'ج', 'س', 'ح']; // initials
  return (
    <div style={{
      height: '100%', background: T.bg, direction: 'rtl',
      fontFamily: T.fontArabic, display: 'flex', flexDirection: 'column',
      overflow: 'hidden', position: 'relative',
    }}>
      <div style={{ flex: 1, overflow: 'auto', padding: '58px 18px 40px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Icon name="chevR" size={22} color={T.ink}/>
          <div style={{ fontSize: 16, fontWeight: 600, color: T.ink }}>التقويم الهجري</div>
          <Icon name="plus" size={20} color={T.ink2}/>
        </div>

        {/* Hero hijri */}
        <div style={{
          marginTop: 20, borderRadius: T.r_xl,
          padding: '22px 22px 20px',
          background: `linear-gradient(135deg, ${T.primary} 0%, #0F3A13 100%)`,
          position: 'relative', overflow: 'hidden', color: '#fff',
        }}>
          <GeoWatermark opacity={0.08} color="#D5B76A" size={260} top={-70} right={-70}/>
          <div style={{ position: 'relative' }}>
            <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.7)', letterSpacing: 0.8 }}>
              اليوم · الأحد
            </div>
            <div style={{ fontSize: 64, fontWeight: 600, lineHeight: 1, marginTop: 8 }}>
              ١
            </div>
            <div style={{ fontSize: 16, marginTop: 4 }}>{month} {year} هـ</div>
            <div style={{
              fontSize: 12, color: 'rgba(255,255,255,0.75)', marginTop: 10,
              paddingTop: 10, borderTop: '1px solid rgba(255,255,255,0.15)',
              display: 'flex', justifyContent: 'space-between',
            }}>
              <div>الموافق ١٩ أبريل ٢٠٢٦</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                <StarMark size={9} color="#D5B76A"/>
                ٦٠ يوماً لرمضان
              </div>
            </div>
          </div>
        </div>

        {/* month nav */}
        <div style={{
          marginTop: 22, display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          padding: '0 4px',
        }}>
          <Icon name="chevR" size={18} color={T.ink3}/>
          <div style={{ fontSize: 15, fontWeight: 600, color: T.ink }}>{month} {year} هـ</div>
          <Icon name="chevL" size={18} color={T.ink3}/>
        </div>

        {/* weekday header */}
        <div style={{
          marginTop: 14, display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)',
          gap: 2, padding: '0 2px',
        }}>
          {weekdays.map((d, i) => (
            <div key={i} style={{
              textAlign: 'center', fontSize: 11, color: T.ink3, fontWeight: 500,
            }}>{d}</div>
          ))}
        </div>

        {/* grid */}
        <div style={{
          marginTop: 8, display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)',
          gap: 4,
        }}>
          {Array.from({length: startDay}).map((_, i) => <div key={'e'+i}/>)}
          {Array.from({length: days}).map((_, i) => {
            const d = i + 1;
            const isToday = d === today;
            const hasEvent = [1, 10, 15].includes(d);
            return (
              <div key={d} style={{
                aspectRatio: '1', borderRadius: T.r_sm,
                background: isToday ? T.primary : T.surface,
                border: `1px solid ${isToday ? T.primary : T.hairline}`,
                display: 'flex', flexDirection: 'column', alignItems: 'center',
                justifyContent: 'center', position: 'relative',
              }}>
                <div style={{
                  fontFamily: T.fontNum, fontSize: 13,
                  color: isToday ? '#fff' : T.ink, fontWeight: isToday ? 600 : 400,
                }}>{toAr(d)}</div>
                {hasEvent && !isToday && (
                  <div style={{
                    position: 'absolute', bottom: 4,
                    width: 4, height: 4, borderRadius: 99,
                    background: T.gold,
                  }}/>
                )}
              </div>
            );
          })}
        </div>

        {/* upcoming events */}
        <div style={{
          marginTop: 22, fontSize: 11, fontWeight: 500, color: T.ink3,
          letterSpacing: 0.8, textTransform: 'uppercase', marginBottom: 10,
        }}>المناسبات القادمة</div>
        <div style={{
          background: T.surface, borderRadius: T.r_md,
          border: `1px solid ${T.hairline}`, overflow: 'hidden',
        }}>
          {[
            { name: 'اليوم العاشر من ذو الحجة', sub: 'يوم النحر', days: '٧٠' },
            { name: 'عاشوراء',                  sub: '١٠ محرم',  days: '١٢٩' },
            { name: 'شهر رمضان',                sub: 'بداية الصيام', days: '٦٠' },
          ].map((e, i, a) => (
            <React.Fragment key={e.name}>
              <div style={{
                padding: '14px 16px', display: 'flex', gap: 14, alignItems: 'center',
              }}>
                <div style={{
                  width: 44, borderRadius: T.r_sm, background: T.goldSoft,
                  padding: '6px 0', textAlign: 'center',
                }}>
                  <div style={{ fontFamily: T.fontNum, fontSize: 16, fontWeight: 600, color: '#8F6A1F' }}>{e.days}</div>
                  <div style={{ fontSize: 9, color: '#8F6A1F' }}>يوم</div>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14, fontWeight: 600, color: T.ink }}>{e.name}</div>
                  <div style={{ fontSize: 11, color: T.ink3, marginTop: 2 }}>{e.sub}</div>
                </div>
                <Icon name="chevL" size={14} color={T.ink3}/>
              </div>
              {i < a.length - 1 && <Hair inset={16}/>}
            </React.Fragment>
          ))}
        </div>
      </div>
    </div>
  );
}

function SettingsScreen() {
  const Group = ({ label, children }) => (
    <div style={{ marginBottom: 22 }}>
      <div style={{
        fontSize: 11, fontWeight: 500, color: T.ink3,
        letterSpacing: 0.8, textTransform: 'uppercase', marginBottom: 10, paddingInline: 4,
      }}>{label}</div>
      <div style={{
        background: T.surface, borderRadius: T.r_md,
        border: `1px solid ${T.hairline}`, overflow: 'hidden',
      }}>{children}</div>
    </div>
  );
  const Row = ({ icon, label, value, toggle, last, color }) => (
    <div>
      <div style={{
        padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 14,
      }}>
        <div style={{
          width: 32, height: 32, borderRadius: T.r_sm,
          background: T.surfaceSunk, display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name={icon} size={16} color={color || T.ink2}/>
        </div>
        <div style={{ flex: 1, fontSize: 14, color: T.ink, fontWeight: 500 }}>{label}</div>
        {value && <div style={{ fontSize: 13, color: T.ink3 }}>{value}</div>}
        {toggle !== undefined && (
          <div style={{
            width: 40, height: 24, borderRadius: 99,
            background: toggle ? T.primary : T.hairlineStrong,
            padding: 2, display: 'flex', justifyContent: toggle ? 'flex-start' : 'flex-end',
            direction: 'ltr',
          }}>
            <div style={{
              width: 20, height: 20, borderRadius: 99, background: '#fff',
              boxShadow: '0 1px 2px rgba(0,0,0,0.15)',
            }}/>
          </div>
        )}
        {!toggle && value === undefined && <Icon name="chevL" size={14} color={T.ink3}/>}
      </div>
      {!last && <Hair inset={16}/>}
    </div>
  );
  return (
    <div style={{
      height: '100%', background: T.bg, direction: 'rtl',
      fontFamily: T.fontArabic, display: 'flex', flexDirection: 'column',
      overflow: 'hidden', position: 'relative',
    }}>
      <div style={{ flex: 1, overflow: 'auto', padding: '64px 18px 110px' }}>
        <div style={{ fontSize: 26, fontWeight: 700, color: T.ink, marginBottom: 20 }}>الإعدادات</div>

        {/* profile */}
        <div style={{
          background: T.surface, borderRadius: T.r_lg,
          border: `1px solid ${T.hairline}`, padding: 16, marginBottom: 22,
          display: 'flex', alignItems: 'center', gap: 14,
        }}>
          <div style={{
            width: 52, height: 52, borderRadius: T.r_pill,
            background: T.primarySoft, color: T.primary,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 20, fontWeight: 600,
          }}>أ</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 600, color: T.ink }}>أحمد عبدالله</div>
            <div style={{ fontSize: 12, color: T.ink3, marginTop: 2 }}>الرياض · سلسلة ١٢ يوماً</div>
          </div>
          <Icon name="chevL" size={16} color={T.ink3}/>
        </div>

        <Group label="الصلاة">
          <Row icon="location" label="الموقع" value="الرياض"/>
          <Row icon="mosque"   label="طريقة الحساب" value="أم القرى"/>
          <Row icon="radio"    label="المؤذن" value="المسجد الحرام"/>
          <Row icon="bell"     label="تنبيه قبل الأذان" value="١٥ دقيقة" last/>
        </Group>

        <Group label="الإشعارات">
          <Row icon="bell"    label="تنبيهات الأذان" toggle={true}/>
          <Row icon="tasbeeh" label="تذكير الأذكار"   toggle={true}/>
          <Row icon="verse"   label="آية اليوم"       toggle={false} last/>
        </Group>

        <Group label="المظهر">
          <Row icon="sun"     label="المظهر" value="فاتح"/>
          <Row icon="verse"   label="حجم الخط" value="متوسط" last/>
        </Group>

        <Group label="عام">
          <Row icon="share"    label="شارك التطبيق"/>
          <Row icon="download" label="التنزيلات" value="١٢٤ م.ب"/>
          <Row icon="heart"    label="قيّم التطبيق" last/>
        </Group>

        <div style={{
          textAlign: 'center', fontSize: 11, color: T.ink4, marginTop: 10,
        }}>أذكار · الإصدار ٢.٠.١</div>
      </div>
      <TabBar active={3}/>
    </div>
  );
}

Object.assign(window, { QiblaScreen, PrayerTimesScreen, HijriCalendarScreen, SettingsScreen });
