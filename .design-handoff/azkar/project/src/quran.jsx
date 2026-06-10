// Quran surah list + Mushaf page

function SurahListScreen() {
  const surahs = [
    { n: 1,   ar: 'الفاتحة',    meaning: 'المكية',  ayat: 7   },
    { n: 2,   ar: 'البقرة',     meaning: 'المدنية', ayat: 286 },
    { n: 3,   ar: 'آل عمران',   meaning: 'المدنية', ayat: 200 },
    { n: 4,   ar: 'النساء',     meaning: 'المدنية', ayat: 176 },
    { n: 5,   ar: 'المائدة',    meaning: 'المدنية', ayat: 120 },
    { n: 6,   ar: 'الأنعام',    meaning: 'المكية',  ayat: 165 },
    { n: 7,   ar: 'الأعراف',    meaning: 'المكية',  ayat: 206 },
    { n: 18,  ar: 'الكهف',      meaning: 'المكية',  ayat: 110 },
  ];
  return (
    <div style={{
      height: '100%', background: T.bg, direction: 'rtl',
      fontFamily: T.fontArabic, display: 'flex', flexDirection: 'column',
      overflow: 'hidden', position: 'relative',
    }}>
      <div style={{ flex: 1, overflow: 'auto', padding: '64px 18px 110px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 18 }}>
          <div style={{ fontSize: 26, fontWeight: 700, color: T.ink }}>المصحف</div>
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{
              width: 36, height: 36, borderRadius: T.r_pill,
              background: T.surface, border: `1px solid ${T.hairline}`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Icon name="search" size={15} color={T.ink2}/>
            </div>
            <div style={{
              width: 36, height: 36, borderRadius: T.r_pill,
              background: T.surface, border: `1px solid ${T.hairline}`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Icon name="bookmark" size={15} color={T.ink2}/>
            </div>
          </div>
        </div>

        {/* Continue reading hero */}
        <div style={{
          borderRadius: T.r_xl, padding: '20px',
          background: '#FAF3E1', border: `1px solid rgba(184,137,42,0.18)`,
          marginBottom: 22, position: 'relative', overflow: 'hidden',
        }}>
          <GeoWatermark opacity={0.12} color={T.gold} size={220} top={-60} right={-60}/>
          <div style={{ position: 'relative' }}>
            <div style={{
              fontSize: 11, fontWeight: 500, color: T.gold,
              letterSpacing: 0.8, textTransform: 'uppercase', marginBottom: 8,
              display: 'flex', alignItems: 'center', gap: 6,
            }}>
              <StarMark size={10} color={T.gold}/>
              متابعة القراءة
            </div>
            <div style={{ fontSize: 22, fontWeight: 600, color: T.ink, marginBottom: 2 }}>
              سورة الكهف
            </div>
            <div style={{ fontSize: 13, color: T.ink2 }}>
              الآية ٤٢ · الجزء ١٥ · صفحة ٢٩٥
            </div>
            <div style={{
              marginTop: 14, display: 'flex', gap: 10, alignItems: 'center',
            }}>
              <div style={{
                flex: 1, height: 4, borderRadius: 99,
                background: 'rgba(184,137,42,0.18)',
              }}>
                <div style={{ width: '38%', height: '100%', background: T.gold, borderRadius: 99 }}/>
              </div>
              <div style={{
                fontFamily: T.fontNum, fontSize: 11, color: T.gold, fontWeight: 600,
              }}>38%</div>
            </div>
          </div>
        </div>

        {/* Filter chips */}
        <div style={{ display: 'flex', gap: 6, marginBottom: 16 }}>
          {['السور', 'الأجزاء', 'المفضلة', 'التنزيلات'].map((t, i) => (
            <div key={t} style={{
              padding: '7px 14px', borderRadius: T.r_pill,
              fontSize: 12, fontWeight: i === 0 ? 600 : 400,
              background: i === 0 ? T.ink : 'transparent',
              color: i === 0 ? '#fff' : T.ink2,
              border: `1px solid ${i === 0 ? T.ink : T.hairline}`,
            }}>{t}</div>
          ))}
        </div>

        {/* Surah rows */}
        <div style={{
          background: T.surface, borderRadius: T.r_md,
          border: `1px solid ${T.hairline}`, overflow: 'hidden',
        }}>
          {surahs.map((s, i) => (
            <div key={s.n}>
              <div style={{
                display: 'flex', alignItems: 'center', gap: 14, padding: '14px 16px',
              }}>
                {/* star-framed number */}
                <div style={{ position: 'relative', width: 38, height: 38,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <StarOutline size={38} color={T.primary} strokeWidth={1}/>
                  <div style={{
                    position: 'absolute', fontFamily: T.fontNum, fontSize: 13,
                    color: T.primary, fontWeight: 600,
                  }}>{toAr(s.n)}</div>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{
                    fontFamily: T.fontQuran, fontSize: 19, color: T.ink, fontWeight: 600,
                  }}>{s.ar}</div>
                  <div style={{ fontSize: 11, color: T.ink3, marginTop: 2 }}>
                    {s.meaning} · {toAr(s.ayat)} آية
                  </div>
                </div>
                <div style={{
                  fontFamily: T.fontNum, fontSize: 11, color: T.ink3,
                }}>{toAr(s.n)}</div>
              </div>
              {i < surahs.length - 1 && <Hair inset={16}/>}
            </div>
          ))}
        </div>
      </div>
      <TabBar active={2}/>
    </div>
  );
}

function MushafScreen() {
  // Mushaf page — like a real Quran page layout
  const verses = [
    'وَإِذَا قِيلَ لَهُمْ لَا تُفْسِدُوا فِي الْأَرْضِ قَالُوا إِنَّمَا نَحْنُ مُصْلِحُونَ',
    'أَلَا إِنَّهُمْ هُمُ الْمُفْسِدُونَ وَلَٰكِن لَّا يَشْعُرُونَ',
    'وَإِذَا قِيلَ لَهُمْ آمِنُوا كَمَا آمَنَ النَّاسُ قَالُوا أَنُؤْمِنُ كَمَا آمَنَ السُّفَهَاءُ',
    'أَلَا إِنَّهُمْ هُمُ السُّفَهَاءُ وَلَٰكِن لَّا يَعْلَمُونَ',
    'وَإِذَا لَقُوا الَّذِينَ آمَنُوا قَالُوا آمَنَّا وَإِذَا خَلَوْا إِلَىٰ شَيَاطِينِهِمْ',
    'قَالُوا إِنَّا مَعَكُمْ إِنَّمَا نَحْنُ مُسْتَهْزِئُونَ',
  ];
  return (
    <div style={{
      height: '100%', background: '#FBF7EA', direction: 'rtl',
      fontFamily: T.fontQuran, display: 'flex', flexDirection: 'column',
      overflow: 'hidden', position: 'relative',
    }}>
      {/* top bar */}
      <div style={{
        padding: '54px 18px 10px', display: 'flex', justifyContent: 'space-between',
        alignItems: 'center',
      }}>
        <Icon name="chevR" size={22} color={T.ink}/>
        <div style={{
          display: 'flex', flexDirection: 'column', alignItems: 'center',
          fontFamily: T.fontArabic,
        }}>
          <div style={{ fontSize: 11, color: T.ink3, letterSpacing: 0.4 }}>سورة</div>
          <div style={{ fontSize: 15, fontWeight: 600, color: T.ink }}>البقرة</div>
        </div>
        <Icon name="bookmark" size={20} color={T.ink2}/>
      </div>

      {/* ornate surah header */}
      <div style={{
        margin: '6px 22px 14px',
        borderRadius: T.r_md,
        border: `1.5px solid ${T.gold}`,
        padding: '14px 18px',
        background: 'rgba(245,236,217,0.5)',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{
          fontFamily: T.fontArabic, fontSize: 11, color: T.ink3,
        }}>جزء ١</div>
        <div style={{
          fontSize: 22, fontWeight: 700, color: T.ink, letterSpacing: 0.5,
        }}>سُورَةُ الْبَقَرَةِ</div>
        <div style={{
          fontFamily: T.fontArabic, fontSize: 11, color: T.ink3,
        }}>مدنية</div>
      </div>

      {/* mushaf body */}
      <div style={{
        flex: 1, overflow: 'auto',
        padding: '0 26px 80px',
        textAlign: 'justify',
        fontSize: 22, lineHeight: 2.4,
        color: T.ink,
        direction: 'rtl',
      }}>
        {verses.map((v, i) => (
          <React.Fragment key={i}>
            {v}
            {' '}
            <span style={{
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
              position: 'relative',
              width: 26, height: 26, margin: '0 2px', verticalAlign: 'middle',
            }}>
              <StarOutline size={26} color={T.gold} strokeWidth={0.8}/>
              <span style={{
                position: 'absolute', fontFamily: T.fontNum, fontSize: 10.5,
                color: T.gold, fontWeight: 600,
              }}>{toAr(11 + i)}</span>
            </span>
            {' '}
          </React.Fragment>
        ))}
      </div>

      {/* footer — page number + hizb marker */}
      <div style={{
        padding: '12px 22px 26px',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        fontFamily: T.fontArabic, fontSize: 11, color: T.ink3,
        borderTop: `1px solid ${T.hairline}`,
        background: '#FBF7EA',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <Icon name="play" size={16} color={T.ink2}/>
          <div>الحفص عن عاصم</div>
        </div>
        <div style={{
          fontFamily: T.fontNum, fontSize: 13, color: T.ink, fontWeight: 600,
        }}>{toAr(3)}</div>
      </div>
    </div>
  );
}

Object.assign(window, { SurahListScreen, MushafScreen });
