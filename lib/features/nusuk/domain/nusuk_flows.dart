import 'nusuk_step.dart';
import 'nusuk_type.dart';

/// Authored ritual scripts (the ordered steps) for each [NusukType].
///
/// Content is adapted from the app's existing vetted guide
/// (`assets/data/hajj_umrah.json`) plus the standard manasik sequence. It is
/// intended as a practical step-by-step companion — the full educational
/// detail still lives in the «دليل الحج والعمرة» guide.
///
/// The Hajj flows are *date-aware*: dated steps carry a [NusukStep.hajjDay]
/// (the Dhul-Ḥijjah day they become valid) which the engine enforces in
/// [NusukMode.live]. The Days of Tashreeq are modelled day-by-day — each day
/// has its own المبيت (Mabit) step and the three Jamarat (الصغرى → الوسطى →
/// الكبرى) as separate ordered counter steps — and a النَّفْر (التعجّل/التأخّر)
/// decision after the 12th drops the 13 Dhul-Ḥijjah steps when the pilgrim
/// leaves early.
///
/// ⚠️ FIQH REVIEW: sequences/duas should be reviewed by Ahmed before release.
/// Notable madhab-sensitive points: placement/counting of Saʿy (the Qārin and
/// Mufrid suffice with one Saʿy; the Mutamattiʿ does two), and the obligation
/// of Hady (required for Tamattuʿ and Qirān, not for Ifrād).
///
/// TODO(content): Ahmed will supply the OFFICIAL Hajj & Umrah book to verify
/// and correct these sequences/duas. File path NOT yet provided — once
/// received, replace/validate the content in this file against that source.
List<NusukStep> stepsForType(NusukType type) {
  switch (type) {
    case NusukType.umrah:
      return _umrah();
    case NusukType.tamattu:
      return _tamattu();
    case NusukType.qiran:
      return _qiran();
    case NusukType.ifrad:
      return _ifrad();
  }
}

/// Total number of steps in a flow — handy for progress math without building
/// the full list twice.
int stepCountForType(NusukType type) => stepsForType(type).length;

/// Stable id of the النَّفْر (early-departure) decision step, and its choice ids.
/// The engine reads these to drop the 13 Dhul-Ḥijjah steps on التعجّل.
const String kNafrahStepId = 'nafrah';
const String kTaajjulChoiceId = 'taajjul';
const String kTaakhurChoiceId = 'taakhur';

// ─────────────────────────── Shared content ───────────────────────────

const String _talbiyah =
    'لبَّيْكَ اللّهُمَّ لبَّيْك، لبَّيْكَ لا شريكَ لكَ لبَّيْك، '
    'إنَّ الحمدَ والنِّعمةَ لكَ والمُلْك، لا شريكَ لك';

const List<String> _tawafDuas = [
  'بِسْمِ اللهِ واللهُ أكبَر (عند محاذاة الحجر الأسود في بداية كل شوط)',
  'رَبَّنا آتِنا في الدُّنيا حَسَنةً وفي الآخِرةِ حَسَنةً وقِنا عَذابَ النار '
      '(بين الركن اليماني والحجر الأسود)',
  'سُبْحانَ اللهِ، والحَمْدُ لله، ولا إلهَ إلا الله، واللهُ أكبَر، '
      'ولا حَوْلَ ولا قُوّةَ إلا بالله',
];

const List<String> _saeeDuas = [
  'إنَّ الصَّفا والمَرْوةَ مِن شَعائِرِ الله، أبدَأُ بما بدَأَ اللهُ به',
  'لا إلهَ إلا اللهُ وحدَه لا شريكَ له، له المُلْكُ وله الحمدُ يُحيي ويُميت، '
      'وهو على كلِّ شيءٍ قدير، لا إلهَ إلا اللهُ وحدَه، أنجَزَ وعدَه، '
      'ونصَرَ عبدَه، وهزَمَ الأحزابَ وحدَه',
  'رَبِّ اغْفِرْ وارْحَمْ، إنَّكَ أنتَ الأعزُّ الأكرَم',
];

// ─────────────────────────── Step builders ───────────────────────────

NusukStep _ihram({
  required String id,
  required String title,
  required String intent,
  required String description,
  String? dayLabel,
  int? hajjDay,
  String? guidance,
}) {
  return NusukStep(
    id: id,
    title: title,
    description: description,
    dayLabel: dayLabel,
    hajjDay: hajjDay,
    talbiyah: _talbiyah,
    duas: [
      intent,
      'اللّهُمَّ إنِّي أسألُكَ رِضاكَ والجَنَّة، وأعوذُ بكَ مِن سَخَطِكَ والنَّار',
    ],
    guidance: guidance ??
        'اغتسل وتطيّب في بدنك، والبس ثياب الإحرام، ثم اعقد النية وارفع صوتك '
            'بالتلبية واستمرّ فيها. المرأة تُحرم في ثيابها الساترة بلا نقاب ولا قفازين.',
  );
}

NusukStep _tawaf(
  String id, {
  String title = 'الطواف',
  String? dayLabel,
  int? hajjDay,
  String? extra,
}) {
  return NusukStep(
    id: id,
    title: title,
    kind: NusukStepKind.counter,
    counterTarget: 7,
    counterUnit: 'شوط',
    dayLabel: dayLabel,
    hajjDay: hajjDay,
    description:
        'طُف بالكعبة سبعةَ أشواط، تبدأ كلَّ شوطٍ من الحجر الأسود وتنتهي إليه، '
        'جاعلاً الكعبةَ عن يسارك.\n'
        '• استلِم الحجر الأسود وكبّر إن تيسّر، وإلا فأشِر إليه بيدك وكبّر.\n'
        '• كن على طهارة وستر عورتك.\n'
        '• أكثِر من الذكر والدعاء بما تحب.'
        '${extra == null ? '' : '\n$extra'}',
    duas: _tawafDuas,
    guidance:
        'سجّل كلَّ شوطٍ بالضغط على الزر؛ يكتمل الطواف تلقائياً بعد الشوط السابع.',
  );
}

NusukStep _saee(
  String id, {
  String title = 'السعي بين الصفا والمروة',
  String? dayLabel,
  int? hajjDay,
  String? note,
}) {
  return NusukStep(
    id: id,
    title: title,
    kind: NusukStepKind.counter,
    counterTarget: 7,
    counterUnit: 'شوط',
    dayLabel: dayLabel,
    hajjDay: hajjDay,
    description:
        'اسعَ بين الصفا والمروة سبعةَ أشواط، تبدأ بالصفا وتنتهي بالمروة '
        '(الذهابُ شوطٌ والعودةُ شوط).\n'
        '• ارقَ على الصفا واستقبِل القبلة وكبّر وادعُ، وكرّر ذلك ثلاثاً.\n'
        '• أسرِع بين العلمين الأخضرين (للرجال).'
        '${note == null ? '' : '\n• $note'}',
    duas: _saeeDuas,
    guidance:
        'سجّل كلَّ شوطٍ بالضغط على الزر؛ يكتمل السعي تلقائياً بعد الشوط السابع.',
  );
}

NusukStep _halqOrTaqsir({
  String id = 'halq',
  String title = 'الحلق أو التقصير',
  String? dayLabel,
  int? hajjDay,
  String? guidance,
}) {
  return NusukStep(
    id: id,
    title: title,
    kind: NusukStepKind.choice,
    dayLabel: dayLabel,
    hajjDay: hajjDay,
    description:
        'تحلّل بحلق الرأس أو التقصير من جميع جوانبه. الحلقُ أفضلُ للرجل، '
        'وأما المرأة فتُقصّر قدرَ أُنملةٍ من شعرها.',
    choices: const [
      NusukChoice(
        id: 'halq',
        label: 'الحلق',
        note: 'حلق جميع شعر الرأس — وهو الأفضل للرجل',
      ),
      NusukChoice(
        id: 'taqsir',
        label: 'التقصير',
        note: 'الأخذ من جميع جوانب الرأس',
      ),
    ],
    guidance: guidance ??
        'اختر ما قمت به ثم اضغط «إتمام الخطوة». بالحلق أو التقصير يحصل التحلّل.',
  );
}

NusukStep _minaTarwiyah() => const NusukStep(
      id: 'mina_tarwiyah',
      title: 'التوجّه إلى منى',
      dayLabel: 'يوم التروية — ٨ ذو الحجة',
      hajjDay: 8,
      description:
          'توجّه إلى منى ضحى يوم التروية، وصلِّ بها الظهر والعصر والمغرب والعشاء '
          'والفجر، تَقصُر الرباعية بلا جمع، وبِت بها ليلة التاسع.',
      guidance: 'المبيت بمنى ليلة عرفة سُنّة، وأكثِر من الذكر والتلبية.',
    );

NusukStep _arafah() => const NusukStep(
      id: 'arafah',
      title: 'الوقوف بعرفة',
      dayLabel: 'يوم عرفة — ٩ ذو الحجة',
      hajjDay: 9,
      description:
          'الوقوف بعرفة هو الركن الأعظم للحج، من زالت شمسُ التاسع إلى فجر العاشر.\n'
          '• ادفَع إلى عرفة بعد طلوع الشمس، وتأكّد أنك داخل حدودها.\n'
          '• اجمَع وقصُر الظهر والعصر جمعَ تقديم.\n'
          '• تفرّغ للدعاء مستقبلاً القبلة رافعاً يديك حتى الغروب.',
      duas: [
        'لا إلهَ إلا اللهُ وحدَه لا شريكَ له، له المُلْكُ وله الحمد، '
            'وهو على كلِّ شيءٍ قدير (أكثِر منها يوم عرفة)',
        'اللّهُمَّ لكَ الحمدُ كالذي نقول، وخيراً مما نقول، '
            'اللّهُمَّ لكَ صلاتي ونُسُكي ومَحْياي ومَماتي، وإليكَ مآبي',
      ],
      guidance: 'لا تغادر عرفة قبل غروب الشمس. اجتهد في الدعاء فهو خيرُ يومٍ تُجاب فيه.',
    );

NusukStep _muzdalifah() => const NusukStep(
      id: 'muzdalifah',
      title: 'المبيت بمزدلفة',
      dayLabel: 'ليلة العيد — ١٠ ذو الحجة',
      hajjDay: 9,
      description:
          'ادفَع من عرفة بعد الغروب بسكينة إلى مزدلفة.\n'
          '• اجمَع المغربَ والعشاءَ (المغرب ثلاثاً والعشاء ركعتين).\n'
          '• بِت بها إلى الفجر، والْتَقِط حصى الجمار (سبعاً لجمرة العقبة).\n'
          '• صلِّ الفجر مبكراً وأكثِر من الدعاء عند المشعر الحرام.',
      guidance: 'يجوز للضعفة والنساء الدفعُ من مزدلفة بعد منتصف الليل.',
    );

NusukStep _jamratAqaba() => const NusukStep(
      id: 'jamrat_aqaba',
      title: 'رمي جمرة العقبة الكبرى',
      kind: NusukStepKind.counter,
      counterTarget: 7,
      counterUnit: 'حصاة',
      dayLabel: 'يوم النحر — ١٠ ذو الحجة',
      hajjDay: 10,
      description:
          'ارمِ جمرةَ العقبة الكبرى بسبع حصياتٍ متعاقبات، تُكبّر مع كلِّ حصاة.\n'
          '• حجمُ الحصاة كحبّة الحمّص تقريباً.\n'
          '• هذا أولُ أعمال يوم النحر، وبه يبدأ التحلّل.',
      guidance: 'سجّل كلَّ حصاةٍ بالضغط على الزر؛ تكتمل الجمرة بعد الحصاة السابعة.',
    );

NusukStep _hady() => const NusukStep(
      id: 'hady',
      title: 'ذبح الهَدْي',
      dayLabel: 'يوم النحر — ١٠ ذو الحجة',
      hajjDay: 10,
      description:
          'اذبَح هَدْيك (شاة، أو سُبع بدنة أو بقرة) شكراً لله. وهو واجبٌ على '
          'المتمتّع والقارن.\n'
          '• يجوز توكيل الجهات المعتمدة بالذبح في الحرم.\n'
          '• من لم يجد الهَدْي صام ثلاثة أيامٍ في الحج وسبعةً إذا رجع.',
      guidance: 'يُجزئ توكيلُ مشروع الهَدْي الرسمي؛ سجِّل الخطوة بعد إتمام التوكيل أو الذبح.',
    );

NusukStep _tawafWada() => _tawaf(
      'tawaf_wada',
      title: 'طواف الوداع',
      dayLabel: 'عند مغادرة مكة',
      extra: '• اجعله آخرَ عهدك بالبيت قبل سفرك. (يسقط عن الحائض والنفساء.)',
    );

// ── Days of Tashreeq (11–13 Dhul-Ḥijjah) building blocks ──

/// One night's Mabit (overnight stay) in Mina — a dedicated tracked step.
NusukStep _mabitMina(
  String id, {
  required String dayLabel,
  required int hajjDay,
}) {
  return NusukStep(
    id: id,
    title: 'المبيت بمنى',
    dayLabel: dayLabel,
    hajjDay: hajjDay,
    description:
        'بِت بمنى هذه الليلة من ليالي التشريق؛ المبيت بمنى ليالي التشريق واجبٌ '
        'من واجبات الحج.\n'
        '• أحْيِ ليلتك بالذكر والدعاء وصلاةِ ما تيسّر.\n'
        '• استعدّ لرمي الجمرات الثلاث بعد زوال شمس الغد.',
    guidance: 'بِت معظمَ الليل بمنى، ثم سجّل الخطوة.',
  );
}

/// One of the three Jamarat on a Tashreeq day. They must be done in order —
/// الصغرى ثم الوسطى ثم الكبرى — which the engine's sequence gating enforces.
NusukStep _jamra(
  String id, {
  required String title,
  required String dayLabel,
  required int hajjDay,
  required String description,
}) {
  return NusukStep(
    id: id,
    title: title,
    kind: NusukStepKind.counter,
    counterTarget: 7,
    counterUnit: 'حصاة',
    dayLabel: dayLabel,
    hajjDay: hajjDay,
    description: description,
    guidance: 'الترتيب: الصغرى ثم الوسطى ثم الكبرى. سجّل كلَّ حصاةٍ بالزر؛ '
        'تكتمل الجمرة بعد الحصاة السابعة.',
  );
}

/// The three ordered Jamarat for a single Tashreeq day (Ṣughrā → Wusṭā → Kubrā).
List<NusukStep> _tashreeqDay({
  required int day,
  required String dayLabel,
  required String suffix,
}) {
  return [
    _mabitMina('mabit_$suffix', dayLabel: dayLabel, hajjDay: day),
    _jamra(
      'ramy_sughra_$suffix',
      title: 'رمي الجمرة الصغرى',
      dayLabel: dayLabel,
      hajjDay: day,
      description:
          'ارمِ الجمرةَ الصغرى (وهي أبعدُ الجمرات عن مكة، تلي مسجدَ الخَيْف) '
          'بسبع حصياتٍ متعاقبات، تُكبّر مع كلِّ حصاة.\n'
          '• يكون الرمي بعد زوال الشمس (دخول وقت الظهر).\n'
          '• ثم تقدّم قليلاً واستقبِل القبلة وادعُ دعاءً طويلاً رافعاً يديك.',
    ),
    _jamra(
      'ramy_wusta_$suffix',
      title: 'رمي الجمرة الوسطى',
      dayLabel: dayLabel,
      hajjDay: day,
      description:
          'ارمِ الجمرةَ الوسطى بسبع حصياتٍ متعاقبات مع التكبير.\n'
          '• بعد الرمي تقدّم وخُذ ذاتَ اليسار واستقبِل القبلة وقِف للدعاء طويلاً.',
    ),
    _jamra(
      'ramy_aqaba_$suffix',
      title: 'رمي الجمرة الكبرى (العقبة)',
      dayLabel: dayLabel,
      hajjDay: day,
      description:
          'ارمِ الجمرةَ الكبرى (جمرةَ العقبة) بسبع حصياتٍ متعاقبات مع التكبير.\n'
          '• هي آخرُ الجمرات الثلاث، ولا تقِف بعدها للدعاء بل تنصرف.',
    ),
  ];
}

/// The التعجّل/التأخّر decision, placed right after the 12th-day stoning.
NusukStep _nafrah() => const NusukStep(
      id: kNafrahStepId,
      title: 'النَّفْر: التعجّل أم التأخّر؟',
      kind: NusukStepKind.choice,
      dayLabel: 'بعد رمي يوم ١٢ ذو الحجة',
      hajjDay: 12,
      description:
          'بعد إتمام رمي اليوم الثاني عشر يُخيَّر الحاجّ بين أمرين:\n'
          '• التعجّل: يخرج من منى قبل غروب شمس الثاني عشر، فيسقط عنه مبيتُ '
          'ورميُ اليوم الثالث عشر.\n'
          '• التأخّر: يبقى لليوم الثالث عشر فيبيت ويرمي، وهو الأفضلُ والأكمل.\n'
          'قال تعالى: ﴿فمَن تعجَّل في يومينِ فلا إثمَ عليه ومَن تأخَّر فلا '
          'إثمَ عليه لمَنِ اتَّقى﴾.',
      choices: [
        NusukChoice(
          id: kTaajjulChoiceId,
          label: 'التعجّل',
          note: 'المغادرة بعد رمي اليوم الثاني عشر — وتُسقَط خطوات اليوم الثالث عشر',
        ),
        NusukChoice(
          id: kTaakhurChoiceId,
          label: 'التأخّر',
          note: 'البقاء لليوم الثالث عشر (مبيتٌ ورمي) — وهو الأفضل',
        ),
      ],
      guidance: 'إن اخترت التعجّل فاحرص على الخروج من منى قبل غروب الشمس، '
          'وإلا لزِمك المبيتُ والرميُ في اليوم الثالث عشر.',
    );

/// Shared يوم النحر + أيام التشريق tail for all three Hajj types. [hady] and a
/// second [saeeOnNahr] vary by type; [ifadahNote] tunes the Tawaf-al-Ifadah
/// footnote.
List<NusukStep> _nahrAndTashreeq({
  required bool hady,
  required bool saeeOnNahr,
  required String ifadahNote,
}) {
  return [
    _jamratAqaba(),
    if (hady) _hady(),
    _halqOrTaqsir(dayLabel: 'يوم النحر — ١٠ ذو الحجة', hajjDay: 10),
    _tawaf(
      'tawaf_ifadah',
      title: 'طواف الإفاضة',
      dayLabel: 'يوم النحر — ١٠ ذو الحجة',
      hajjDay: 10,
      extra: ifadahNote,
    ),
    if (saeeOnNahr)
      _saee(
        'saee_hajj',
        title: 'سعي الحج',
        dayLabel: 'يوم النحر — ١٠ ذو الحجة',
        hajjDay: 10,
        note: 'سعيُ الحج ركنٌ على المتمتّع بعد طواف الإفاضة.',
      ),
    ..._tashreeqDay(
      day: 11,
      dayLabel: 'اليوم الحادي عشر — ١١ ذو الحجة',
      suffix: '11',
    ),
    ..._tashreeqDay(
      day: 12,
      dayLabel: 'اليوم الثاني عشر — ١٢ ذو الحجة',
      suffix: '12',
    ),
    _nafrah(),
    ..._tashreeqDay(
      day: 13,
      dayLabel: 'اليوم الثالث عشر — ١٣ ذو الحجة',
      suffix: '13',
    ),
    _tawafWada(),
  ];
}

// ─────────────────────────────── Flows ───────────────────────────────

List<NusukStep> _umrah() => [
      _ihram(
        id: 'ihram',
        title: 'الإحرام والنيّة والتلبية',
        intent: 'لبَّيْكَ اللّهُمَّ عُمْرَة',
        description:
            'الإحرام نيّةُ الدخول في النُّسُك، وهو ركنُ العمرة. أحرِم من '
            'الميقات المعتبر لجهتك، وانوِ العمرة بقلبك قائلاً: «لبَّيْكَ '
            'اللّهُمَّ عُمْرَة»، ثم الزَم التلبية إلى أن تبدأ الطواف.',
      ),
      _tawaf('tawaf'),
      const NusukStep(
        id: 'maqam',
        title: 'الصلاة خلف مقام إبراهيم',
        description:
            'بعد الطواف صلِّ ركعتين خلف مقام إبراهيم إن تيسّر، وإلا ففي أي مكانٍ '
            'من المسجد.\n'
            '• تقرأ في الأولى: ﴿قُلْ يَا أَيُّهَا الْكَافِرُونَ﴾، وفي الثانية: '
            '﴿قُلْ هُوَ اللَّهُ أَحَدٌ﴾.\n'
            '• ثم اشرَب من ماء زمزم وادعُ بما تحب.',
        duas: [
          'اللّهُمَّ إنِّي أسألُكَ عِلماً نافعاً، ورِزقاً واسعاً، '
              'وشِفاءً من كلِّ داء',
        ],
        guidance: 'لا تُزاحم على المقام؛ الركعتان تصحّان في أي موضعٍ من الحرم.',
      ),
      _saee('saee'),
      _halqOrTaqsir(),
    ];

List<NusukStep> _tamattu() => [
      _ihram(
        id: 'umrah_ihram',
        title: 'الإحرام بالعمرة',
        intent: 'لبَّيْكَ اللّهُمَّ عُمْرَة',
        description:
            'حج التمتّع يبدأ بعمرةٍ كاملة في أشهر الحج (شوال وذو القعدة وعشرُ ذي '
            'الحجة)، تُؤدّى قبل يوم التروية. أحرِم بالعمرة من الميقات قائلاً: '
            '«لبَّيْكَ اللّهُمَّ عُمْرَة».',
      ),
      _tawaf('umrah_tawaf', title: 'طواف العمرة'),
      _saee('umrah_saee', title: 'سعي العمرة'),
      _halqOrTaqsir(
        id: 'umrah_taqsir',
        title: 'التقصير وإتمام العمرة',
        guidance:
            'الأفضل للمتمتّع التقصيرُ ليُبقي شعره للحج. بعدها تتحلّل تحلّلاً '
            'كاملاً وتلبَس ثيابك حتى يوم التروية.',
      ),
      _ihram(
        id: 'hajj_ihram',
        title: 'الإحرام بالحج',
        intent: 'لبَّيْكَ اللّهُمَّ حَجّاً',
        dayLabel: 'يوم التروية — ٨ ذو الحجة',
        hajjDay: 8,
        description:
            'في صباح اليوم الثامن (بعد إتمام العمرة) أحرِم بالحج من مكانك '
            '(من حيث أنت نازل) قائلاً: «لبَّيْكَ اللّهُمَّ حَجّاً»، ثم توجّه '
            'إلى منى. لا يصحّ بدء الحج قبل إتمام عمرة التمتّع.',
        guidance: 'اغتسِل وتطيّب والبس ثياب الإحرام، ثم الزَم التلبية.',
      ),
      _minaTarwiyah(),
      _arafah(),
      _muzdalifah(),
      ..._nahrAndTashreeq(
        hady: true,
        saeeOnNahr: true,
        ifadahNote: '• طوافُ الإفاضة ركنٌ لا يصحّ الحج إلا به.',
      ),
    ];

List<NusukStep> _qiran() => [
      _ihram(
        id: 'ihram',
        title: 'الإحرام بالحج والعمرة معاً',
        intent: 'لبَّيْكَ اللّهُمَّ حَجّاً وعُمْرَة',
        description:
            'القارنُ يجمع بين الحج والعمرة بإحرامٍ واحد من الميقات، فينوي '
            'النُّسُكين معاً قائلاً: «لبَّيْكَ اللّهُمَّ حَجّاً وعُمْرَة»، '
            'ويبقى محرِماً إلى يوم النحر.',
      ),
      _tawaf(
        'tawaf_qudum',
        title: 'طواف القدوم',
        extra: '• طوافُ القدوم سُنّة عند الوصول إلى مكة.',
      ),
      _saee(
        'saee',
        title: 'السعي',
        note: 'سعيُ القارن واحدٌ يُجزئه عن الحج والعمرة، '
            'ويجوز تقديمه بعد طواف القدوم.',
      ),
      _minaTarwiyah(),
      _arafah(),
      _muzdalifah(),
      ..._nahrAndTashreeq(
        hady: true,
        saeeOnNahr: false,
        ifadahNote: '• طوافُ الإفاضة ركنٌ لا يصحّ الحج إلا به. '
            '(لا يلزم القارنَ سعيٌ ثانٍ إن كان قد سعى بعد القدوم.)',
      ),
    ];

List<NusukStep> _ifrad() => [
      _ihram(
        id: 'ihram',
        title: 'الإحرام بالحج',
        intent: 'لبَّيْكَ اللّهُمَّ حَجّاً',
        description:
            'المُفرِد يُحرم بالحج وحده من الميقات قائلاً: «لبَّيْكَ اللّهُمَّ '
            'حَجّاً»، ويبقى محرِماً إلى يوم النحر. وليس على المُفرِد هَدْيٌ واجب.',
      ),
      _tawaf(
        'tawaf_qudum',
        title: 'طواف القدوم',
        extra: '• طوافُ القدوم سُنّة عند الوصول إلى مكة.',
      ),
      _saee(
        'saee',
        title: 'سعي الحج',
        note: 'يجوز تقديمُ السعي بعد طواف القدوم، أو تأخيره بعد طواف الإفاضة.',
      ),
      _minaTarwiyah(),
      _arafah(),
      _muzdalifah(),
      ..._nahrAndTashreeq(
        hady: false,
        saeeOnNahr: false,
        ifadahNote: '• طوافُ الإفاضة ركنٌ لا يصحّ الحج إلا به. '
            '(لا يلزم المُفرِدَ سعيٌ ثانٍ إن كان قد سعى بعد القدوم.)',
      ),
    ];
