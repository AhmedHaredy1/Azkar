// Remaining screens: Onboarding, Nearby Mosques, Asma Allah, Ramadan, Wudu, Hadith, Live Radio, Reciter picker

function OnboardingScreen() {
  return (
    <div style={{
      height: '100%', background: T.bg, direction: 'rtl',
      fontFamily: T.fontArabic, display: 'flex', flexDirection: 'column',
      overflow: 'hidden', position: 'relative',
    }}>
      <div style={{ flex: 1, padding: '80px 26px 0', display: 'flex', flexDirection: 'column' }}>
        {/* hero illustration slot */}
        <div style={{
          flex: '0 0 auto', aspectRatio: '1 / 0.8',
          borderRadius: T.r_xl, background: T.surface,
          border: `1px solid ${T.hairline}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          position: 'relative', overflow: 'hidden', marginBottom: 40,
        }}>
          <GeoWatermark opacity={0.12} color={T.primary} size={300} top={-40} right={-40}/>
          <div style={{ position: 'relative', textAlign: 'center' }}>
            <div style={{
              width: 96, height: 96, borderRadius: T.r_pill,
              background: T.primarySoft, display: 'flex',
              alignItems: 'center', justifyContent: 'center', margin: '0 auto 16px',
            }}>
              <StarMark size={48} color={T.primary}/>
            </div>
            <div style={{
              fontFamily: T.fontUi, fontSize: 10, color: T.ink3,
              letterSpacing: 1, textTransform: 'uppercase',
            }}>خطوة ١ من ٣</div>
          </div>
        </div>

        {/* copy */}
        <div style={{ flex: 1 }}>
          <div style={{
            fontSize: 30, fontWeight: 700, color: T.ink,
            letterSpacing: -0.5, lineHeight: 1.3,
          }}>رافقك في يومك</div>
          <div style={{
            marginTop: 14, fontSize: 15, color: T.ink2, lineHeight: 1.8,
          }}>مواقيت دقيقة، أذكار الصباح والمساء، ومصحف كامل — كل شيء في مكان واحد، بدون تشتيت.</div>
        </div>

        {/* dots + button */}
        <div style={{ paddingBottom: 44 }}>
          <div style={{ display: 'flex', gap: 6, justifyContent: 'center', marginBottom: 22 }}>
            <div style={{ width: 22, height: 6, borderRadius: 99, background: T.primary }}/>
            <div style={{ width: 6,  height: 6, borderRadius: 99, background: T.hairlineStrong }}/>
            <div style={{ width: 6,  height: 6, borderRadius: 99, background: T.hairlineStrong }}/>
          </div>
          <div style={{
            height: 54, borderRadius: T.r_md, background: T.primary,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: '#fff', fontSize: 15, fontWeight: 600, letterSpacing: 0.2,
          }}>متابعة</div>
          <div style={{
            textAlign: 'center', marginTop: 14, fontSize: 12, color: T.ink3,
          }}>تخطّي المقدمة</div>
        </div>
      </div>
    </div>
  );
}

function NearbyMosquesScreen() {
  const mosques = [
    { name: 'جامع الملك خالد', dist: '٠.٤ كم', addr: 'حي الرحمانية', open: true },
    { name: 'مسجد الإمام تركي', dist: '٠.٨ كم', addr: 'حي المروج',   open: true },
    { name: 'مسجد بلال بن رباح', dist: '١.٢ كم', addr: 'حي الورود',   open: false },
    { name: 'جامع الراجحي',      dist: '١.٦ كم', addr: 'حي النخيل',   open: true },
  ];
  return (
    <div style={{
      height: '100%', background: T.bg, direction: 'rtl',
      fontFamily: T.fontArabic, display: 'flex', flexDirection: 'column',
      overflow: 'hidden', position: 'relative',
    }}>
      {/* header */}
      <div style={{
        padding: '58px 18px 14px', display: 'flex',
        justifyContent: 'space-between', alignItems: 'center',
        background: T.bg, zIndex: 2,
      }}>
        <Icon name="chevR" size={22} color={T.ink}/>
        <div style={{ fontSize: 16, fontWeight: 600, color: T.ink }}>المساجد القريبة</div>
        <Icon name="search" size={20} color={T.ink2}/>
      </div>

      {/* map */}
      <div style={{
        height: 300, margin: '0 18px', borderRadius: T.r_lg, overflow: 'hidden',
        background: '#E8EDE7', position: 'relative',
        border: `1px solid ${T.hairline}`,
      }}>
        {/* simulated map lines */}
        <svg viewBox="0 0 400 300" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}>
          <rect width="400" height="300" fill="#E8EDE7"/>
          {/* streets */}
          <path d="M-10 80 L410 60" stroke="#fff" strokeWidth="12"/>
          <path d="M-10 180 L410 220" stroke="#fff" strokeWidth="16"/>
          <path d="M120 -10 L90 310" stroke="#fff" strokeWidth="14"/>
          <path d="M280 -10 L310 310" stroke="#fff" strokeWidth="10"/>
          {/* blocks */}
          <rect x="20" y="95" width="55" height="70" fill="#DDE3DA" rx="3"/>
          <rect x="135" y="95" width="130" height="70" fill="#DDE3DA" rx="3"/>
          <rect x="325" y="95" width="70" height="70" fill="#DDE3DA" rx="3"/>
          <rect x="20" y="235" width="60" height="60" fill="#DDE3DA" rx="3"/>
          <rect x="140" y="235" width="150" height="60" fill="#DDE3DA" rx="3"/>
          {/* parks */}
          <rect x="325" y="200" width="70" height="100" fill="#CDE0CE" rx="3"/>
        </svg>
        {/* mosque pins */}
        {[[120,130],[240,180],[310,110],[90,240]].map(([x,y], i) => (
          <div key={i} style={{
            position: 'absolute', left: x, top: y, transform: 'translate(-50%, -100%)',
          }}>
            <div style={{
              width: 28, height: 28, borderRadius: T.r_pill, background: T.primary,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 4px 12px rgba(27,94,32,0.3)',
              border: '2px solid #fff',
            }}>
              <Icon name="mosque" size={12} color="#fff"/>
            </div>
            <div style={{
              width: 0, height: 0, margin: '0 auto',
              borderLeft: '5px solid transparent', borderRight: '5px solid transparent',
              borderTop: `6px solid ${T.primary}`,
            }}/>
          </div>
        ))}
        {/* user location */}
        <div style={{
          position: 'absolute', left: 200, top: 150, transform: 'translate(-50%, -50%)',
          width: 16, height: 16, borderRadius: 99, background: '#2868E0',
          border: '3px solid #fff', boxShadow: '0 0 0 6px rgba(40,104,224,0.2)',
        }}/>
      </div>

      {/* list */}
      <div style={{ flex: 1, overflow: 'auto', padding: '14px 18px 40px' }}>
        <div style={{
          fontSize: 11, fontWeight: 500, color: T.ink3,
          letterSpacing: 0.8, textTransform: 'uppercase',
          marginBottom: 10, display: 'flex', justifyContent: 'space-between',
        }}>
          <span>ضمن نطاق ٢ كم</span>
          <span style={{ color: T.ink2 }}>{toAr(4)} مساجد</span>
        </div>
        <div style={{
          background: T.surface, borderRadius: T.r_md,
          border: `1px solid ${T.hairline}`, overflow: 'hidden',
        }}>
          {mosques.map((m, i) => (
            <React.Fragment key={m.name}>
              <div style={{ padding: '14px 16px', display: 'flex', gap: 14, alignItems: 'center' }}>
                <div style={{
                  width: 40, height: 40, borderRadius: T.r_sm,
                  background: T.primarySoft, display: 'flex',
                  alignItems: 'center', justifyContent: 'center',
                }}>
                  <Icon name="mosque" size={18} color={T.primary}/>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14, fontWeight: 600, color: T.ink }}>{m.name}</div>
                  <div style={{
                    fontSize: 11, color: T.ink3, marginTop: 2,
                    display: 'flex', alignItems: 'center', gap: 8,
                  }}>
                    <span>{m.addr}</span>
                    <span style={{
                      width: 3, height: 3, borderRadius: 99, background: T.ink4,
                    }}/>
                    <span style={{ color: m.open ? T.primary : T.ink3 }}>
                      {m.open ? 'مفتوح' : 'مغلق'}
                    </span>
                  </div>
                </div>
                <div style={{ textAlign: 'end' }}>
                  <div style={{
                    fontFamily: T.fontNum, fontSize: 13, color: T.ink, fontWeight: 600,
                  }}>{m.dist}</div>
                  <div style={{ fontSize: 10, color: T.ink3, marginTop: 2 }}>افتح في الخرائط</div>
                </div>
              </div>
              {i < mosques.length - 1 && <Hair inset={16}/>}
            </React.Fragment>
          ))}
        </div>
      </div>
    </div>
  );
}

function AsmaAllahScreen() {
  const names = [
    { n: 1, ar: 'الرَّحْمٰنُ',   trans: 'Ar-Rahmān',   meaning: 'الرحمن الذي وسعت رحمته كل شيء' },
    { n: 2, ar: 'الرَّحِيمُ',    trans: 'Ar-Rahīm',    meaning: 'الرحيم بالمؤمنين' },
    { n: 3, ar: 'الْمَلِكُ',     trans: 'Al-Malik',    meaning: 'المالك لجميع الأشياء' },
    { n: 4, ar: 'الْقُدُّوسُ',    trans: 'Al-Quddūs',   meaning: 'المنزّه عن كل نقص' },
    { n: 5, ar: 'السَّلَامُ',    trans: 'As-Salām',    meaning: 'السالم من كل عيب' },
    { n: 6, ar: 'الْمُؤْمِنُ',   trans: 'Al-Mu’min',   meaning: 'المصدّق رسله' },
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
          <div style={{ fontSize: 16, fontWeight: 600, color: T.ink }}>أسماء الله الحسنى</div>
          <Icon name="search" size={20} color={T.ink2}/>
        </div>

        {/* hero count */}
        <div style={{
          marginTop: 20, borderRadius: T.r_xl, padding: '24px',
          background: '#FAF3E1', border: `1px solid rgba(184,137,42,0.18)`,
          position: 'relative', overflow: 'hidden', textAlign: 'center',
        }}>
          <GeoWatermark opacity={0.1} color={T.gold} size={280} top={-80} right={-80}/>
          <div style={{ position: 'relative' }}>
            <div style={{
              fontSize: 11, fontWeight: 500, color: T.gold,
              letterSpacing: 1, textTransform: 'uppercase', marginBottom: 10,
            }}>الأسماء الحسنى</div>
            <div style={{
              fontFamily: T.fontQuran, fontSize: 28, color: T.ink, fontWeight: 600,
              lineHeight: 1.4,
            }}>وَلِلّٰهِ الْأَسْمَاءُ الْحُسْنَىٰ فَادْعُوهُ بِهَا</div>
            <div style={{
              marginTop: 14, display: 'flex', justifyContent: 'center', gap: 24,
              paddingTop: 14, borderTop: '1px solid rgba(184,137,42,0.18)',
            }}>
              <div>
                <div style={{ fontFamily: T.fontNum, fontSize: 22, color: T.ink, fontWeight: 600 }}>٩٩</div>
                <div style={{ fontSize: 11, color: T.ink3 }}>اسماً</div>
              </div>
              <div style={{ width: 1, background: 'rgba(184,137,42,0.18)' }}/>
              <div>
                <div style={{ fontFamily: T.fontNum, fontSize: 22, color: T.ink, fontWeight: 600 }}>٦</div>
                <div style={{ fontSize: 11, color: T.ink3 }}>مقروءة</div>
              </div>
            </div>
          </div>
        </div>

        {/* list */}
        <div style={{
          marginTop: 20, display: 'flex', flexDirection: 'column', gap: 8,
        }}>
          {names.map(n => (
            <div key={n.n} style={{
              background: T.surface, borderRadius: T.r_md,
              border: `1px solid ${T.hairline}`, padding: '14px 16px',
              display: 'flex', alignItems: 'center', gap: 14,
            }}>
              <div style={{ position: 'relative', width: 40, height: 40,
                display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
              }}>
                <StarOutline size={40} color={T.gold} strokeWidth={1}/>
                <div style={{
                  position: 'absolute', fontFamily: T.fontNum, fontSize: 12,
                  color: T.gold, fontWeight: 600,
                }}>{toAr(n.n)}</div>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 10 }}>
                  <div style={{ fontFamily: T.fontQuran, fontSize: 22, color: T.ink, fontWeight: 600 }}>
                    {n.ar}
                  </div>
                  <div style={{ fontFamily: T.fontUi, fontSize: 11, color: T.ink3, direction: 'ltr' }}>
                    {n.trans}
                  </div>
                </div>
                <div style={{
                  fontSize: 12, color: T.ink2, marginTop: 4,
                  whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                }}>{n.meaning}</div>
              </div>
              <Icon name="play" size={14} color={T.ink3}/>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function RamadanScreen() {
  return (
    <div style={{
      height: '100%', background: T.bg, direction: 'rtl',
      fontFamily: T.fontArabic, display: 'flex', flexDirection: 'column',
      overflow: 'hidden', position: 'relative',
    }}>
      <div style={{ flex: 1, overflow: 'auto', padding: '58px 18px 40px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Icon name="chevR" size={22} color={T.ink}/>
          <div style={{ fontSize: 16, fontWeight: 600, color: T.ink }}>رمضان</div>
          <Icon name="share" size={18} color={T.ink2}/>
        </div>

        {/* Iftar countdown hero */}
        <div style={{
          marginTop: 20, borderRadius: T.r_xl, padding: '26px 22px',
          background: `linear-gradient(155deg, #1B3A3F 0%, #0F2326 100%)`,
          color: '#fff', position: 'relative', overflow: 'hidden',
        }}>
          <GeoWatermark opacity={0.08} color="#E8C77A" size={320} top={-100} right={-100}/>
          <div style={{ position: 'relative' }}>
            <div style={{
              fontSize: 11, letterSpacing: 1, color: 'rgba(255,255,255,0.7)',
              textTransform: 'uppercase', marginBottom: 10,
              display: 'flex', alignItems: 'center', gap: 6,
            }}>
              <Icon name="ramadan" size={12} color="#E8C77A"/>
              الإفطار بعد
            </div>
            <div style={{
              fontFamily: T.fontNum, fontSize: 52, fontWeight: 600,
              letterSpacing: -1, lineHeight: 1, marginBottom: 8,
            }}>
              02<span style={{ color: 'rgba(255,255,255,0.4)' }}>:</span>47<span style={{ color: 'rgba(255,255,255,0.4)' }}>:</span>12
            </div>
            <div style={{
              fontSize: 13, color: 'rgba(255,255,255,0.75)',
              display: 'flex', justifyContent: 'space-between',
              paddingTop: 16, marginTop: 16,
              borderTop: '1px solid rgba(255,255,255,0.12)',
            }}>
              <div>
                <div style={{ fontSize: 10, letterSpacing: 0.6, color: 'rgba(255,255,255,0.5)' }}>السحور</div>
                <div style={{ fontFamily: T.fontNum, fontSize: 14, color: '#fff', marginTop: 2 }}>٠٤:١٢</div>
              </div>
              <div>
                <div style={{ fontSize: 10, letterSpacing: 0.6, color: 'rgba(255,255,255,0.5)' }}>الإفطار</div>
                <div style={{ fontFamily: T.fontNum, fontSize: 14, color: '#E8C77A', marginTop: 2 }}>١٨:٢٧</div>
              </div>
              <div>
                <div style={{ fontSize: 10, letterSpacing: 0.6, color: 'rgba(255,255,255,0.5)' }}>الصيام اليوم</div>
                <div style={{ fontFamily: T.fontNum, fontSize: 14, color: '#fff', marginTop: 2 }}>١٤س ١٥د</div>
              </div>
            </div>
          </div>
        </div>

        {/* Day meter */}
        <div style={{
          marginTop: 18, borderRadius: T.r_lg, padding: 16,
          background: T.surface, border: `1px solid ${T.hairline}`,
        }}>
          <div style={{
            display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 12,
          }}>
            <div style={{ fontSize: 14, fontWeight: 600, color: T.ink }}>يوم ١٢ من ٣٠</div>
            <div style={{ fontSize: 12, color: T.ink3 }}>١٨ يوماً متبقي</div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(30, 1fr)', gap: 3 }}>
            {Array.from({ length: 30 }).map((_, i) => (
              <div key={i} style={{
                aspectRatio: '1', borderRadius: 2,
                background: i < 12 ? T.primary : (i === 12 ? T.gold : T.surfaceSunk),
                opacity: i < 12 ? 1 : (i === 12 ? 1 : 0.7),
              }}/>
            ))}
          </div>
        </div>

        {/* Cards */}
        <div style={{
          marginTop: 18, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10,
        }}>
          {[
            { label: 'أدعية الإفطار',    icon: 'verse',   tint: T.primarySoft, ic: T.primary },
            { label: 'قيام الليل',       icon: 'moon',    tint: '#E5E8EF',     ic: '#4A5B7A' },
            { label: 'ليلة القدر',       icon: 'names',   tint: T.goldSoft,    ic: T.gold    },
            { label: 'أعمال العشر الأواخر', icon: 'tasbeeh', tint: T.primarySoft, ic: T.primary },
          ].map(c => (
            <div key={c.label} style={{
              background: T.surface, borderRadius: T.r_lg,
              border: `1px solid ${T.hairline}`, padding: 14,
              minHeight: 100, display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: T.r_sm,
                background: c.tint, display: 'flex',
                alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name={c.icon} size={18} color={c.ic}/>
              </div>
              <div style={{ fontSize: 14, fontWeight: 600, color: T.ink }}>{c.label}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function WuduScreen() {
  const steps = [
    { n: 1, title: 'النية',          sub: 'انوي الوضوء بقلبك'                 },
    { n: 2, title: 'التسمية',        sub: 'قل: بسم الله'                      },
    { n: 3, title: 'غسل الكفين',     sub: 'ثلاث مرات'                         },
    { n: 4, title: 'المضمضة والاستنشاق', sub: 'ثلاث مرات'                     },
    { n: 5, title: 'غسل الوجه',      sub: 'ثلاث مرات، من منابت الشعر للذقن'    },
    { n: 6, title: 'غسل اليدين للمرفقين', sub: 'اليمنى ثم اليسرى، ثلاثاً'      },
    { n: 7, title: 'مسح الرأس والأذنين', sub: 'مرة واحدة'                     },
    { n: 8, title: 'غسل الرجلين',    sub: 'إلى الكعبين، ثلاثاً'                },
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
          <div style={{ fontSize: 16, fontWeight: 600, color: T.ink }}>الوضوء</div>
          <Icon name="play" size={18} color={T.ink2}/>
        </div>

        <div style={{
          marginTop: 20, borderRadius: T.r_lg,
          background: T.surface, border: `1px solid ${T.hairline}`,
          padding: '18px', display: 'flex', gap: 14, alignItems: 'center',
        }}>
          <div style={{
            width: 48, height: 48, borderRadius: T.r_pill,
            background: T.primarySoft,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="wudu" size={24} color={T.primary}/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 600, color: T.ink }}>الوضوء الشرعي</div>
            <div style={{ fontSize: 12, color: T.ink2, marginTop: 3, lineHeight: 1.5 }}>
              ٨ خطوات مع صور توضيحية ومقطع صوتي
            </div>
          </div>
        </div>

        {/* step rail */}
        <div style={{ marginTop: 20, position: 'relative' }}>
          <div style={{
            position: 'absolute', right: 19, top: 24, bottom: 24,
            width: 1.5, background: T.hairline,
          }}/>
          {steps.map((s, i) => {
            const isActive = i === 2;
            const isDone   = i < 2;
            return (
              <div key={s.n} style={{
                display: 'flex', gap: 14, marginBottom: 12, position: 'relative',
              }}>
                <div style={{
                  width: 38, height: 38, borderRadius: T.r_pill,
                  background: isActive ? T.primary : (isDone ? T.primarySoft : T.surface),
                  border: `1.5px solid ${isActive ? T.primary : (isDone ? T.primarySoft : T.hairlineStrong)}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0, position: 'relative', zIndex: 1,
                }}>
                  {isDone ? (
                    <svg width="14" height="14" viewBox="0 0 24 24">
                      <path d="M4 12 L10 18 L20 6" stroke={T.primary} strokeWidth="2.5"
                        fill="none" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  ) : (
                    <div style={{
                      fontFamily: T.fontNum, fontSize: 13,
                      color: isActive ? '#fff' : T.ink3, fontWeight: 600,
                    }}>{toAr(s.n)}</div>
                  )}
                </div>
                <div style={{
                  flex: 1, background: T.surface,
                  border: `1px solid ${isActive ? T.primary : T.hairline}`,
                  borderWidth: isActive ? 2 : 1,
                  borderRadius: T.r_md, padding: '12px 14px',
                }}>
                  <div style={{ fontSize: 14, fontWeight: 600, color: T.ink }}>{s.title}</div>
                  <div style={{ fontSize: 12, color: T.ink3, marginTop: 3 }}>{s.sub}</div>
                  {isActive && (
                    <div style={{
                      marginTop: 10, paddingTop: 10, borderTop: `1px solid ${T.hairline}`,
                      display: 'flex', gap: 16, fontSize: 12, color: T.ink2,
                    }}>
                      <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                        <Icon name="play" size={13} color={T.ink2}/> مقطع ١٢ث
                      </span>
                      <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                        <Icon name="eye" size={13} color={T.ink2}/> صورة
                      </span>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

function HadithScreen() {
  return (
    <div style={{
      height: '100%', background: T.bg, direction: 'rtl',
      fontFamily: T.fontArabic, display: 'flex', flexDirection: 'column',
      overflow: 'hidden', position: 'relative',
    }}>
      <div style={{ flex: 1, overflow: 'auto', padding: '58px 18px 40px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Icon name="chevR" size={22} color={T.ink}/>
          <div style={{ fontSize: 16, fontWeight: 600, color: T.ink }}>حديث اليوم</div>
          <Icon name="bookmark" size={18} color={T.ink2}/>
        </div>

        {/* date */}
        <div style={{
          marginTop: 18, fontSize: 12, color: T.ink3, textAlign: 'center',
        }}>الأحد، ١ ذو القعدة ١٤٤٧ هـ</div>

        {/* Hadith card */}
        <div style={{
          marginTop: 14, borderRadius: T.r_xl,
          background: T.surface, border: `1px solid ${T.hairline}`,
          padding: '28px 24px', position: 'relative', overflow: 'hidden',
        }}>
          <GeoWatermark opacity={0.05} color={T.primary} size={240} top={-60} right={-60}/>
          <div style={{ position: 'relative' }}>
            {/* source tag */}
            <div style={{
              display: 'inline-flex', alignItems: 'center', gap: 6,
              padding: '5px 12px', borderRadius: T.r_pill,
              background: T.primarySoft, color: T.primary,
              fontSize: 11, fontWeight: 600, letterSpacing: 0.3,
            }}>
              <StarMark size={9} color={T.primary}/>
              صحيح البخاري
            </div>

            <div style={{
              marginTop: 18,
              fontFamily: T.fontQuran, fontSize: 22, lineHeight: 2.1,
              color: T.ink, textAlign: 'right',
            }}>
              عَنْ أَبِي هُرَيْرَةَ رَضِيَ اللهُ عَنْهُ قَالَ: قَالَ رَسُولُ اللهِ ﷺ:
              <span style={{ color: T.primary }}>
                «مَنْ كَانَ يُؤْمِنُ بِاللهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ»
              </span>
            </div>

            <div style={{
              marginTop: 20, paddingTop: 16, borderTop: `1px solid ${T.hairline}`,
              fontSize: 13, color: T.ink2, lineHeight: 1.8,
            }}>
              <div style={{ fontWeight: 600, color: T.ink, marginBottom: 6, fontSize: 12 }}>الشرح</div>
              يحثّ الحديث على حفظ اللسان والتحرّز من فضول الكلام، وجعل المنطق في الخير وحده.
            </div>

            <div style={{
              marginTop: 18, display: 'flex', justifyContent: 'space-between',
              fontSize: 13, color: T.ink2,
            }}>
              <div style={{ display: 'flex', gap: 18 }}>
                <Icon name="play" size={16} color={T.ink2}/>
                <Icon name="copy" size={16} color={T.ink2}/>
                <Icon name="share" size={16} color={T.ink2}/>
              </div>
              <div style={{ fontSize: 11, color: T.ink3 }}>رقم ٦٤٧٥</div>
            </div>
          </div>
        </div>

        {/* previous */}
        <div style={{
          marginTop: 18, fontSize: 11, fontWeight: 500, color: T.ink3,
          letterSpacing: 0.8, textTransform: 'uppercase', marginBottom: 10,
        }}>أحاديث سابقة</div>
        <div style={{
          background: T.surface, borderRadius: T.r_md,
          border: `1px solid ${T.hairline}`, overflow: 'hidden',
        }}>
          {[
            { date: 'أمس',          text: 'إنما الأعمال بالنيات…',    src: 'البخاري' },
            { date: 'قبل يومين',    text: 'الدين النصيحة…',           src: 'مسلم'    },
            { date: 'قبل ٣ أيام',   text: 'لا يؤمن أحدكم حتى يحب…',    src: 'البخاري' },
          ].map((h, i, a) => (
            <React.Fragment key={i}>
              <div style={{ padding: '12px 16px', display: 'flex', gap: 12, alignItems: 'center' }}>
                <div style={{ flex: 1 }}>
                  <div style={{
                    fontFamily: T.fontQuran, fontSize: 15, color: T.ink,
                    whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                  }}>{h.text}</div>
                  <div style={{ fontSize: 11, color: T.ink3, marginTop: 3 }}>
                    {h.date} · {h.src}
                  </div>
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

function LiveRadioScreen() {
  const stations = [
    { name: 'إذاعة القرآن الكريم',     sub: 'المملكة العربية السعودية', listeners: '١٢.٤ك', live: true  },
    { name: 'إذاعة الحرم المكي',       sub: 'بث مباشر',                  listeners: '٩.٢ك',  live: true  },
    { name: 'إذاعة المسجد النبوي',     sub: 'بث مباشر',                  listeners: '٧.٨ك',  live: true  },
    { name: 'إذاعة طيبة',              sub: 'دروس وتلاوات',              listeners: '٢.١ك',  live: false },
  ];
  return (
    <div style={{
      height: '100%', background: T.bg, direction: 'rtl',
      fontFamily: T.fontArabic, display: 'flex', flexDirection: 'column',
      overflow: 'hidden', position: 'relative',
    }}>
      <div style={{ flex: 1, overflow: 'auto', padding: '58px 18px 140px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Icon name="chevR" size={22} color={T.ink}/>
          <div style={{ fontSize: 16, fontWeight: 600, color: T.ink }}>الإذاعات</div>
          <Icon name="heart" size={18} color={T.ink2}/>
        </div>

        {/* Now playing */}
        <div style={{
          marginTop: 20, borderRadius: T.r_xl, padding: '22px',
          background: `linear-gradient(155deg, ${T.primary} 0%, #0F3A13 100%)`,
          color: '#fff', position: 'relative', overflow: 'hidden',
        }}>
          <GeoWatermark opacity={0.07} color="#D5B76A" size={260} top={-70} right={-70}/>
          <div style={{ position: 'relative' }}>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 8,
              fontSize: 10, letterSpacing: 1, textTransform: 'uppercase',
            }}>
              <span style={{ width: 6, height: 6, borderRadius: 99, background: '#E55' }}/>
              بث مباشر
              <span style={{ color: 'rgba(255,255,255,0.5)', margin: '0 4px' }}>·</span>
              <span style={{ color: 'rgba(255,255,255,0.7)' }}>١٢.٤ك مستمع</span>
            </div>
            <div style={{ fontSize: 22, fontWeight: 600, marginTop: 10 }}>إذاعة القرآن الكريم</div>
            <div style={{
              marginTop: 6, fontFamily: T.fontQuran, fontSize: 15,
              color: 'rgba(255,255,255,0.8)',
            }}>يتلو الآن · الشيخ ماهر المعيقلي · سورة يس</div>

            {/* waveform */}
            <div style={{
              marginTop: 16, height: 38, display: 'flex', alignItems: 'center', gap: 2,
            }}>
              {Array.from({length: 50}).map((_, i) => {
                const h = 6 + Math.abs(Math.sin(i * 0.8) * 26) + Math.abs(Math.cos(i * 0.4) * 8);
                return <div key={i} style={{
                  flex: 1, height: h, borderRadius: 2,
                  background: i < 20 ? '#D5B76A' : 'rgba(255,255,255,0.25)',
                }}/>;
              })}
            </div>

            <div style={{
              marginTop: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            }}>
              <div style={{ display: 'flex', gap: 18, alignItems: 'center' }}>
                <Icon name="share" size={18} color="rgba(255,255,255,0.7)"/>
                <Icon name="heart" size={18} color="rgba(255,255,255,0.7)"/>
              </div>
              <div style={{
                width: 56, height: 56, borderRadius: T.r_pill,
                background: '#fff',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name="pause" size={24} color={T.primary}/>
              </div>
              <div style={{
                fontFamily: T.fontNum, fontSize: 11,
                color: 'rgba(255,255,255,0.7)',
              }}>LIVE</div>
            </div>
          </div>
        </div>

        {/* list */}
        <div style={{
          marginTop: 22, fontSize: 11, fontWeight: 500, color: T.ink3,
          letterSpacing: 0.8, textTransform: 'uppercase', marginBottom: 10,
        }}>جميع الإذاعات</div>
        <div style={{
          background: T.surface, borderRadius: T.r_md,
          border: `1px solid ${T.hairline}`, overflow: 'hidden',
        }}>
          {stations.map((s, i) => (
            <React.Fragment key={s.name}>
              <div style={{ padding: '14px 16px', display: 'flex', gap: 14, alignItems: 'center' }}>
                <div style={{
                  width: 40, height: 40, borderRadius: T.r_sm,
                  background: T.primarySoft, display: 'flex',
                  alignItems: 'center', justifyContent: 'center',
                }}>
                  <Icon name="radio" size={18} color={T.primary}/>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{
                    fontSize: 14, fontWeight: 600, color: T.ink,
                    display: 'flex', alignItems: 'center', gap: 8,
                  }}>
                    {s.name}
                    {s.live && <span style={{
                      fontSize: 9, fontWeight: 700, letterSpacing: 0.5,
                      padding: '2px 6px', borderRadius: 4,
                      background: '#FBEAEA', color: '#B42318',
                    }}>LIVE</span>}
                  </div>
                  <div style={{ fontSize: 11, color: T.ink3, marginTop: 2 }}>
                    {s.sub} · {s.listeners}
                  </div>
                </div>
                <Icon name="play" size={18} color={T.ink2}/>
              </div>
              {i < stations.length - 1 && <Hair inset={16}/>}
            </React.Fragment>
          ))}
        </div>
      </div>

      {/* mini player */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0,
        padding: '12px 18px 28px',
        background: 'rgba(255,255,255,0.96)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: `1px solid ${T.hairline}`,
      }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <div style={{
            width: 40, height: 40, borderRadius: T.r_sm,
            background: T.primarySoft, display: 'flex',
            alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="radio" size={18} color={T.primary}/>
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{
              fontSize: 13, fontWeight: 600, color: T.ink,
              whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
            }}>إذاعة القرآن الكريم</div>
            <div style={{
              fontSize: 11, color: T.ink3, marginTop: 2,
              whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
            }}>الشيخ ماهر المعيقلي</div>
          </div>
          <div style={{
            width: 36, height: 36, borderRadius: T.r_pill, background: T.primary,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="pause" size={14} color="#fff"/>
          </div>
        </div>
      </div>
    </div>
  );
}

function ReciterPickerScreen() {
  const reciters = [
    { name: 'مشاري العفاسي',  sub: 'حفص عن عاصم',   dl: 'تم التنزيل', sel: false },
    { name: 'عبدالباسط عبدالصمد', sub: 'ترتيل · حفص',   dl: 'تم التنزيل', sel: true  },
    { name: 'ماهر المعيقلي',   sub: 'إمام الحرم المكي', dl: '١٢٤ م.ب',    sel: false },
    { name: 'سعد الغامدي',      sub: 'حفص عن عاصم',    dl: 'تنزيل',      sel: false },
    { name: 'أبو بكر الشاطري',  sub: 'حفص عن عاصم',    dl: 'تنزيل',      sel: false },
    { name: 'محمود خليل الحصري', sub: 'المعلم · حفص',   dl: 'تنزيل',      sel: false },
    { name: 'السديس والشريم',   sub: 'إمام الحرم',      dl: 'تنزيل',      sel: false },
  ];
  return (
    <div style={{
      height: '100%', background: T.bg, direction: 'rtl',
      fontFamily: T.fontArabic, display: 'flex', flexDirection: 'column',
      overflow: 'hidden', position: 'relative',
    }}>
      <div style={{ flex: 1, overflow: 'auto', padding: '58px 18px 40px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Icon name="close" size={22} color={T.ink}/>
          <div style={{ fontSize: 16, fontWeight: 600, color: T.ink }}>اختيار القارئ</div>
          <div style={{ fontSize: 13, color: T.primary, fontWeight: 600 }}>حفظ</div>
        </div>

        {/* search */}
        <div style={{
          marginTop: 16, display: 'flex', alignItems: 'center', gap: 10,
          padding: '12px 14px', borderRadius: T.r_md,
          background: T.surface, border: `1px solid ${T.hairline}`,
        }}>
          <Icon name="search" size={16} color={T.ink3}/>
          <div style={{ fontSize: 14, color: T.ink3 }}>ابحث عن قارئ…</div>
        </div>

        {/* chips */}
        <div style={{ display: 'flex', gap: 6, marginTop: 14, overflowX: 'auto', scrollbarWidth: 'none' }}>
          {['الكل', 'المفضلة', 'تم التنزيل', 'مرتل', 'مجوّد'].map((t, i) => (
            <div key={t} style={{
              padding: '7px 14px', borderRadius: T.r_pill,
              fontSize: 12, fontWeight: i === 0 ? 600 : 400,
              background: i === 0 ? T.ink : 'transparent',
              color: i === 0 ? '#fff' : T.ink2,
              border: `1px solid ${i === 0 ? T.ink : T.hairline}`,
              whiteSpace: 'nowrap', flexShrink: 0,
            }}>{t}</div>
          ))}
        </div>

        <div style={{
          marginTop: 18, display: 'flex', flexDirection: 'column', gap: 8,
        }}>
          {reciters.map(r => (
            <div key={r.name} style={{
              background: T.surface, borderRadius: T.r_md,
              border: `${r.sel ? 2 : 1}px solid ${r.sel ? T.primary : T.hairline}`,
              padding: '14px 14px', display: 'flex', gap: 14, alignItems: 'center',
            }}>
              <div style={{
                width: 44, height: 44, borderRadius: T.r_pill,
                background: r.sel ? T.primary : T.primarySoft,
                color: r.sel ? '#fff' : T.primary,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 17, fontWeight: 600,
              }}>{r.name.charAt(0)}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600, color: T.ink }}>{r.name}</div>
                <div style={{ fontSize: 11, color: T.ink3, marginTop: 2 }}>{r.sub}</div>
              </div>
              <div style={{ textAlign: 'end' }}>
                <Icon name={r.sel ? 'play' : 'download'} size={18} color={r.sel ? T.primary : T.ink2}/>
                <div style={{ fontSize: 10, color: T.ink3, marginTop: 4 }}>{r.dl}</div>
              </div>
              {r.sel && (
                <div style={{
                  width: 20, height: 20, borderRadius: 99, background: T.primary,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <svg width="10" height="10" viewBox="0 0 24 24">
                    <path d="M4 12 L10 18 L20 6" stroke="#fff" strokeWidth="3" fill="none"
                      strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {
  OnboardingScreen, NearbyMosquesScreen, AsmaAllahScreen, RamadanScreen,
  WuduScreen, HadithScreen, LiveRadioScreen, ReciterPickerScreen,
});
