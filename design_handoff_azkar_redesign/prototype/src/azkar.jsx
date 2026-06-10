// Azkar list + reading mode + Tasbeeh counter

function AzkarListScreen() {
  const categories = [
    { title: 'أذكار الصباح',   sub: 'بعد صلاة الفجر',  count: 28, icon: 'sun',    tint: '#F5E9CF', ic: '#B8892A' },
    { title: 'أذكار المساء',   sub: 'بعد صلاة العصر',  count: 27, icon: 'moon',   tint: '#E5E8EF', ic: '#4A5B7A' },
    { title: 'أذكار النوم',    sub: 'قبل النوم',       count: 18, icon: 'moon',   tint: '#EEF3EE', ic: T.primary },
    { title: 'أذكار الاستيقاظ',sub: 'عند الاستيقاظ',    count: 6,  icon: 'sun',    tint: '#F5E9CF', ic: '#B8892A' },
    { title: 'أذكار الصلاة',   sub: 'بعد كل فريضة',     count: 12, icon: 'tasbeeh',tint: '#EEF3EE', ic: T.primary },
    { title: 'أدعية من القرآن',sub: 'من الكتاب العزيز',  count: 42, icon: 'quran',  tint: '#F5E9CF', ic: '#B8892A' },
    { title: 'أدعية من السنة', sub: 'من الحديث الشريف',  count: 35, icon: 'verse',  tint: '#EEF3EE', ic: T.primary },
  ];
  return (
    <div style={{
      height: '100%', background: T.bg, direction: 'rtl',
      fontFamily: T.fontArabic, display: 'flex', flexDirection: 'column',
      overflow: 'hidden', position: 'relative',
    }}>
      <div style={{ flex: 1, overflow: 'auto', padding: '64px 18px 110px' }}>
        {/* title row */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 18 }}>
          <div style={{ fontSize: 26, fontWeight: 700, color: T.ink }}>الأذكار</div>
          <div style={{
            width: 36, height: 36, borderRadius: T.r_pill,
            background: T.surface, border: `1px solid ${T.hairline}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="heart" size={16} color={T.ink2}/>
          </div>
        </div>

        {/* search */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 10,
          padding: '12px 14px', borderRadius: T.r_md,
          background: T.surface, border: `1px solid ${T.hairline}`, marginBottom: 20,
        }}>
          <Icon name="search" size={16} color={T.ink3}/>
          <div style={{ fontSize: 14, color: T.ink3 }}>ابحث في الأذكار…</div>
        </div>

        {/* featured streak card */}
        <div style={{
          borderRadius: T.r_lg, padding: 16,
          background: 'linear-gradient(120deg, #F8F0DC 0%, #F2ECDC 100%)',
          border: `1px solid ${T.hairline}`, marginBottom: 20,
          display: 'flex', alignItems: 'center', gap: 14,
        }}>
          <div style={{
            width: 48, height: 48, borderRadius: T.r_md, background: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            border: `1px solid ${T.hairline}`,
          }}>
            <StarMark size={20} color={T.gold}/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14, fontWeight: 600, color: T.ink }}>أكمل أذكار المساء اليوم</div>
            <div style={{ fontSize: 12, color: T.ink2, marginTop: 2 }}>١٢ من ٢٧ · سلسلة ١٢ يوماً</div>
            <div style={{
              marginTop: 10, height: 4, borderRadius: 99,
              background: 'rgba(184,137,42,0.18)', overflow: 'hidden',
            }}>
              <div style={{ width: '44%', height: '100%', background: T.gold, borderRadius: 99 }}/>
            </div>
          </div>
        </div>

        {/* categories */}
        <div style={{
          fontSize: 11, fontWeight: 500, color: T.ink3,
          letterSpacing: 0.8, marginBottom: 10,
        }}>الفئات</div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {categories.map(c => (
            <div key={c.title} style={{
              background: T.surface, borderRadius: T.r_md,
              border: `1px solid ${T.hairline}`,
              padding: '14px 14px',
              display: 'flex', alignItems: 'center', gap: 14,
            }}>
              <div style={{
                width: 42, height: 42, borderRadius: T.r_sm,
                background: c.tint, display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name={c.icon} size={20} color={c.ic}/>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 15, fontWeight: 600, color: T.ink }}>{c.title}</div>
                <div style={{ fontSize: 12, color: T.ink3, marginTop: 2 }}>{c.sub}</div>
              </div>
              <div style={{
                fontFamily: T.fontNum, fontSize: 12, color: T.ink3,
                background: T.surfaceSunk, padding: '3px 8px', borderRadius: T.r_pill,
              }}>{toAr(c.count)}</div>
              <Icon name="chevL" size={16} color={T.ink3}/>
            </div>
          ))}
        </div>
      </div>
      <TabBar active={1}/>
    </div>
  );
}

function AzkarReadingScreen() {
  return (
    <div style={{
      height: '100%', background: T.bg, direction: 'rtl',
      fontFamily: T.fontArabic, display: 'flex', flexDirection: 'column',
      overflow: 'hidden', position: 'relative',
    }}>
      {/* Header */}
      <div style={{
        padding: '58px 18px 14px',
        background: T.bg,
        borderBottom: `1px solid ${T.hairline}`,
      }}>
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <Icon name="chevR" size={22} color={T.ink}/>
            <div>
              <div style={{ fontSize: 16, fontWeight: 600, color: T.ink }}>أذكار الصباح</div>
              <div style={{ fontSize: 11, color: T.ink3, marginTop: 2 }}>٣ من ٢٨</div>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <Icon name="eye" size={18} color={T.ink2}/>
            <Icon name="heart" size={18} color={T.ink2}/>
          </div>
        </div>
        {/* progress */}
        <div style={{
          marginTop: 14, height: 3, borderRadius: 99,
          background: T.hairline, overflow: 'hidden',
        }}>
          <div style={{ width: '11%', height: '100%', background: T.primary }}/>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '18px 18px 140px' }}>
        {/* Card 1 */}
        <div style={{
          background: T.surface, borderRadius: T.r_lg,
          border: `1px solid ${T.hairline}`, padding: '20px 20px 16px',
          marginBottom: 14, position: 'relative',
        }}>
          <div style={{
            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            marginBottom: 14,
          }}>
            <div style={{
              fontSize: 11, fontWeight: 500, color: T.ink3, letterSpacing: 0.8,
              textTransform: 'uppercase',
            }}>ذِكر ٣ · آية الكرسي</div>
            <div style={{
              fontFamily: T.fontNum, fontSize: 13, fontWeight: 600, color: T.primary,
              background: T.primarySoft, padding: '4px 10px', borderRadius: T.r_pill,
            }}>١×</div>
          </div>
          <div style={{
            fontFamily: T.fontQuran, fontSize: 22, lineHeight: 2.1,
            color: T.ink, textAlign: 'right',
          }}>
            اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ
          </div>
          <div style={{
            marginTop: 14, paddingTop: 12, borderTop: `1px solid ${T.hairline}`,
            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          }}>
            <div style={{ display: 'flex', gap: 16, color: T.ink2 }}>
              <Icon name="play" size={16} color={T.ink2}/>
              <Icon name="copy" size={16} color={T.ink2}/>
              <Icon name="share" size={16} color={T.ink2}/>
            </div>
            <div style={{ fontSize: 11, color: T.ink3 }}>البقرة ٢٥٥</div>
          </div>
        </div>

        {/* Card 2 — in progress */}
        <div style={{
          background: T.surface, borderRadius: T.r_lg,
          border: `2px solid ${T.primary}`, padding: '20px 20px 18px',
          marginBottom: 14,
        }}>
          <div style={{
            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            marginBottom: 14,
          }}>
            <div style={{
              fontSize: 11, fontWeight: 500, color: T.primary, letterSpacing: 0.8,
              textTransform: 'uppercase',
            }}>ذِكر ٤ · قراءة حالياً</div>
            <div style={{
              fontFamily: T.fontNum, fontSize: 13, fontWeight: 600, color: '#fff',
              background: T.primary, padding: '4px 10px', borderRadius: T.r_pill,
            }}>٢ / ٣</div>
          </div>
          <div style={{
            fontFamily: T.fontQuran, fontSize: 24, lineHeight: 2.1,
            color: T.ink, textAlign: 'right', fontWeight: 500,
          }}>
            أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ
          </div>
          <div style={{ marginTop: 14 }}>
            <div style={{ display: 'flex', gap: 6, marginBottom: 12 }}>
              {[1,2,3].map(n => (
                <div key={n} style={{
                  flex: 1, height: 4, borderRadius: 99,
                  background: n <= 2 ? T.primary : T.hairline,
                }}/>
              ))}
            </div>
            <div style={{
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            }}>
              <div style={{ display: 'flex', gap: 16, color: T.ink2 }}>
                <Icon name="play" size={16} color={T.ink2}/>
                <Icon name="copy" size={16} color={T.ink2}/>
                <Icon name="share" size={16} color={T.ink2}/>
              </div>
              <div style={{
                padding: '8px 18px', borderRadius: T.r_pill,
                background: T.primary, color: '#fff',
                fontSize: 13, fontWeight: 600,
              }}>اضغط للعد</div>
            </div>
          </div>
        </div>

        {/* Card 3 — collapsed */}
        <div style={{
          background: T.surface, borderRadius: T.r_lg,
          border: `1px solid ${T.hairline}`, padding: '16px',
          display: 'flex', alignItems: 'center', gap: 12, opacity: 0.7,
        }}>
          <div style={{
            width: 30, height: 30, borderRadius: T.r_pill,
            background: T.surfaceSunk, color: T.ink3,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: T.fontNum, fontSize: 12, fontWeight: 600,
          }}>٥</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: T.fontQuran, fontSize: 18, color: T.ink }}>
              بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ…
            </div>
          </div>
          <div style={{ fontFamily: T.fontNum, fontSize: 12, color: T.ink3 }}>٣×</div>
        </div>
      </div>
    </div>
  );
}

function TasbeehScreen() {
  const count = 33;
  const target = 33;
  const circumference = 2 * Math.PI * 130;
  const pct = count / target;
  return (
    <div style={{
      height: '100%', background: T.bg, direction: 'rtl',
      fontFamily: T.fontArabic, display: 'flex', flexDirection: 'column',
      overflow: 'hidden', position: 'relative',
    }}>
      {/* header */}
      <div style={{
        padding: '58px 18px 14px',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      }}>
        <Icon name="chevR" size={22} color={T.ink}/>
        <div style={{ fontSize: 16, fontWeight: 600, color: T.ink }}>المسبحة</div>
        <Icon name="settings" size={20} color={T.ink2}/>
      </div>

      <div style={{ flex: 1, padding: '0 24px', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        {/* dhikr text */}
        <div style={{ textAlign: 'center', marginTop: 16, marginBottom: 8 }}>
          <div style={{ fontSize: 11, color: T.ink3, letterSpacing: 0.8, textTransform: 'uppercase', marginBottom: 8 }}>
            الذِّكر الحالي
          </div>
          <div style={{ fontFamily: T.fontQuran, fontSize: 28, color: T.ink, fontWeight: 500 }}>
            سُبْحَانَ اللَّهِ
          </div>
          <div style={{ fontSize: 12, color: T.ink3, marginTop: 6 }}>
            ٣٣ مرة · بعد الصلاة
          </div>
        </div>

        {/* big counter */}
        <div style={{
          position: 'relative', width: 280, height: 280,
          marginTop: 24,
        }}>
          <svg viewBox="0 0 280 280" style={{ position: 'absolute', inset: 0 }}>
            <circle cx="140" cy="140" r="130" fill="none"
              stroke={T.hairline} strokeWidth="2"/>
            <circle cx="140" cy="140" r="130" fill="none"
              stroke={T.primary} strokeWidth="3"
              strokeLinecap="round"
              strokeDasharray={circumference}
              strokeDashoffset={circumference * (1 - pct)}
              transform="rotate(-90 140 140)"/>
            {/* tick marks around for 33 */}
            {Array.from({length: 33}).map((_, i) => {
              const a = (i / 33) * Math.PI * 2 - Math.PI / 2;
              const r1 = 118, r2 = 124;
              const x1 = 140 + r1 * Math.cos(a), y1 = 140 + r1 * Math.sin(a);
              const x2 = 140 + r2 * Math.cos(a), y2 = 140 + r2 * Math.sin(a);
              return <line key={i} x1={x1} y1={y1} x2={x2} y2={y2}
                stroke={i < count ? T.primary : T.hairlineStrong}
                strokeWidth="1.5" strokeLinecap="round"/>;
            })}
          </svg>
          <div style={{
            position: 'absolute', inset: 0,
            display: 'flex', flexDirection: 'column',
            alignItems: 'center', justifyContent: 'center',
          }}>
            <div style={{
              fontFamily: T.fontNum, fontSize: 76, fontWeight: 300,
              color: T.ink, letterSpacing: -2, lineHeight: 1,
            }}>{toAr(count)}</div>
            <div style={{
              fontFamily: T.fontNum, fontSize: 16, color: T.ink3, marginTop: 6,
            }}>/ {toAr(target)}</div>
            <div style={{
              marginTop: 14, padding: '4px 12px', borderRadius: T.r_pill,
              background: T.primarySoft, fontSize: 11, color: T.primary, fontWeight: 600,
            }}>مكتمل</div>
          </div>
        </div>

        {/* set selector — horizontally scrollable so no chip clips */}
        <div style={{
          marginTop: 22, display: 'flex', gap: 6,
          overflowX: 'auto', width: '100%',
          paddingBottom: 4, scrollbarWidth: 'none',
        }}>
          {['سبحان الله', 'الحمد لله', 'الله أكبر', 'لا إله إلا الله'].map((t, i) => (
            <div key={t} style={{
              padding: '8px 12px', borderRadius: T.r_pill,
              fontSize: 12, whiteSpace: 'nowrap', flexShrink: 0,
              background: i === 0 ? T.ink : T.surface,
              color: i === 0 ? '#fff' : T.ink2,
              border: `1px solid ${i === 0 ? T.ink : T.hairline}`,
              fontWeight: i === 0 ? 600 : 400,
            }}>{t}</div>
          ))}
        </div>

        {/* controls */}
        <div style={{
          display: 'flex', gap: 10, marginTop: 18, width: '100%',
        }}>
          <div style={{
            flex: 1, height: 48, borderRadius: T.r_md,
            background: T.surface, border: `1px solid ${T.hairline}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            color: T.ink2, fontSize: 13,
          }}>
            <Icon name="vibrate" size={16} color={T.ink2}/>
            اهتزاز
          </div>
          <div style={{
            flex: 1, height: 48, borderRadius: T.r_md,
            background: T.surface, border: `1px solid ${T.hairline}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: T.ink2, fontSize: 13,
          }}>إعادة تعيين</div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { AzkarListScreen, AzkarReadingScreen, TasbeehScreen });
