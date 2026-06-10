import 'dart:convert';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import '../../../../core/services/global_audio_handler.dart';
import '../../../../core/services/storage_service.dart';
import '../../../quran/presentation/providers/quran_audio_provider.dart';
import '../../../quran_listen/presentation/providers/quran_listen_provider.dart';

class RadioStation {
  final String id;
  final String nameAr;
  final String nameEn;
  final String audioUrl;
  final String? videoUrl; // HLS video stream (null = audio only)
  final String icon;

  const RadioStation({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.audioUrl,
    this.videoUrl,
    required this.icon,
  });

  bool get hasVideo => videoUrl != null;
}

const radioStations = [
  RadioStation(
    id: 'saudi_quran',
    nameAr: 'إذاعة القرآن الكريم',
    nameEn: 'Saudi Quran Radio',
    audioUrl: 'https://win.holol.com/live/quran/playlist.m3u8',
    videoUrl:
        'https://cdn-globecast.akamaized.net/live/eds/saudi_quran/hls_roku/index.m3u8',
    icon: '🕌',
  ),
  RadioStation(
    id: 'saudi_sunnah',
    nameAr: 'إذاعة السنة النبوية',
    nameEn: 'Saudi Sunnah Radio',
    audioUrl: 'https://win.holol.com/live/sunnah/playlist.m3u8',
    videoUrl:
        'https://cdn-globecast.akamaized.net/live/eds/saudi_sunnah/hls_roku/index.m3u8',
    icon: '📖',
  ),
  RadioStation(
    id: 'egypt_quran',
    nameAr: 'إذاعة القرآن الكريم من مصر',
    nameEn: 'Egypt Quran Radio',
    audioUrl: 'https://n09.radiojar.com/8s5u5tpdtwzuv?rj-ttl=5&rj-tok=AAABnYaiaJ4Aq9RqzPTsTgiBjQ',
    icon: '🇪🇬',
  ),
];

class LiveRadioState {
  final String? playingStationId;
  final bool isLoading;
  final bool isPlaying;
  final bool isVideoMode;
  final String? error;

  const LiveRadioState({
    this.playingStationId,
    this.isLoading = false,
    this.isPlaying = false,
    this.isVideoMode = false,
    this.error,
  });

  LiveRadioState copyWith({
    String? playingStationId,
    bool? isLoading,
    bool? isPlaying,
    bool? isVideoMode,
    String? error,
    bool clearStation = false,
    bool clearError = false,
  }) {
    return LiveRadioState(
      playingStationId:
          clearStation ? null : (playingStationId ?? this.playingStationId),
      isLoading: isLoading ?? this.isLoading,
      isPlaying: isPlaying ?? this.isPlaying,
      isVideoMode: isVideoMode ?? this.isVideoMode,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LiveRadioNotifier extends StateNotifier<LiveRadioState> {
  final AudioPlayer _player = AudioPlayer();
  final Ref _ref;

  LiveRadioNotifier(this._ref) : super(const LiveRadioState()) {
    _player.playerStateStream.listen((ps) {
      if (!mounted) return;
      state = state.copyWith(
        isPlaying: ps.playing,
        isLoading: ps.processingState == ProcessingState.loading ||
            ps.processingState == ProcessingState.buffering,
      );
    });
  }

  void _stopOtherPlayers() {
    try {
      _ref.read(quranAudioProvider.notifier).stop();
    } catch (_) {}
    try {
      _ref.read(listenPlayerProvider.notifier).stop();
    } catch (_) {}
  }

  void _attachToHandler({required String title, String? subtitle}) {
    try {
      final handler = _ref.read(globalAudioHandlerProvider);
      handler.attachPlayer(_player, ActiveAudioSource.liveRadio,
          title: title, subtitle: subtitle);
    } catch (_) {}
  }

  void _detachFromHandler() {
    try {
      final handler = _ref.read(globalAudioHandlerProvider);
      if (handler.activeSource == ActiveAudioSource.liveRadio) {
        handler.detachPlayer();
      }
    } catch (_) {}
  }

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    ));
  }

  Future<void> playStation(RadioStation station, {bool videoMode = false}) async {
    try {
      // If same station is playing or loading in same mode, stop it (toggle)
      if (state.playingStationId == station.id &&
          (state.isPlaying || state.isLoading) &&
          state.isVideoMode == videoMode) {
        await stop();
        return;
      }

      // If already loading a different station, stop current first
      if (state.isLoading) {
        await _player.stop();
      }

      _stopOtherPlayers();

      // If switching mode on same station, stop first
      if (state.playingStationId == station.id &&
          state.isVideoMode != videoMode) {
        await _player.stop();
      }

      state = state.copyWith(
        isLoading: true,
        playingStationId: station.id,
        isVideoMode: videoMode && station.hasVideo,
        clearError: true,
      );

      // Video mode is handled by the screen with VideoPlayer widget,
      // audio mode uses just_audio
      if (!videoMode || !station.hasVideo) {
        await _configureAudioSession();
        await _player.setUrl(station.audioUrl);
        _attachToHandler(
          title: station.nameAr,
          subtitle: station.nameEn,
        );
        await _player.play();
      } else {
        // For video mode, set state — the screen uses VideoPlayerController
        // No lock-screen controls for video
        state = state.copyWith(
          isLoading: false,
          isPlaying: true,
        );
      }
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        error: 'فشل تشغيل البث. تأكد من اتصال الإنترنت.',
      );
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _detachFromHandler();
    state = state.copyWith(
      isPlaying: false,
      isVideoMode: false,
      clearStation: true,
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final liveRadioProvider =
    StateNotifierProvider<LiveRadioNotifier, LiveRadioState>((ref) {
  return LiveRadioNotifier(ref);
});

// ──────────────────────────────────────────────
// mp3quran.net Reciter Radios
// ──────────────────────────────────────────────

/// A radio stream from mp3quran.net API.
class Mp3QuranRadio {
  final int id;
  final String name;
  final String url;

  const Mp3QuranRadio({
    required this.id,
    required this.name,
    required this.url,
  });

  factory Mp3QuranRadio.fromJson(Map<String, dynamic> json) {
    return Mp3QuranRadio(
      id: json['id'] as int,
      name: (json['name'] as String).trim(),
      url: json['url'] as String,
    );
  }

  /// Convert to RadioStation for unified playback.
  RadioStation toRadioStation() {
    return RadioStation(
      id: 'mp3quran_$id',
      nameAr: name,
      nameEn: '',
      audioUrl: url,
      icon: '📻',
    );
  }
}

/// Fetches reciter radios from mp3quran.net, filtering out translation radios.
final mp3QuranRadiosProvider = FutureProvider<List<Mp3QuranRadio>>((ref) async {
  final response = await http.get(
    Uri.parse('https://www.mp3quran.net/api/v3/radios?language=ar'),
  );

  if (response.statusCode != 200) {
    throw Exception('فشل تحميل قائمة الإذاعات');
  }

  final body = json.decode(response.body);
  final List<dynamic> radiosJson = body['radios'] ?? body;

  final radios = <Mp3QuranRadio>[];
  for (final item in radiosJson) {
    final radio = Mp3QuranRadio.fromJson(item as Map<String, dynamic>);
    // Filter out translation radios
    if (radio.name.contains('ترجمة')) continue;
    radios.add(radio);
  }

  return radios;
});

// ──────────────────────────────────────────────
// Nationality Mapping for Reciters
// ──────────────────────────────────────────────

const String kAllCountries = 'الكل';
const String kFavorites = 'المفضلة';

/// Maps reciter name keywords to nationality.
String getReciterNationality(String name) {
  final n = name.trim();

  // Saudi reciters
  const saudiReciters = [
    'ماهر المعيقلي', 'سعود الشريم', 'عبدالرحمن السديس', 'السديس',
    'ياسر الدوسري', 'بندر بليلة', 'فارس عباد', 'سعد الغامدي',
    'خالد الجليل', 'عبدالله الجهني', 'إبراهيم الأخضر', 'علي الحذيفي',
    'أحمد الحواشي', 'الشريم', 'المعيقلي', 'الغامدي', 'الجهني',
    'عبدالمحسن القاسم', 'عبدالباري الثبيتي', 'الثبيتي', 'القاسم',
    'صلاح بو خاطر', 'بو خاطر', 'ناصر القطامي', 'القطامي',
    'عبدالله الماطرود', 'محمد اللحيدان', 'اللحيدان', 'عادل الكلباني',
    'الكلباني', 'يوسف الشويعي', 'عبدالعزيز الأحمد', 'توفيق الصايغ',
    'الصايغ', 'صالح الصاهود', 'محمد البراك', 'عبدالله بصفر',
    'فيصل الجهني', 'عبدالله خياط', 'خياط', 'أحمد العجمي', 'العجمي',
    'محمد أيوب', 'أيوب', 'عبدالرشيد صوفي', 'صوفي',
    'علي جابر', 'جابر', 'محمد المحيسني', 'المحيسني',
  ];

  // Egyptian reciters
  const egyptianReciters = [
    'عبدالباسط', 'محمود خليل الحصري', 'الحصري', 'المنشاوي',
    'محمد صديق المنشاوي', 'الطبلاوي', 'أحمد نعينع', 'نعينع',
    'محمود علي البنا', 'البنا', 'شعبان الصياد', 'الصياد',
    'أحمد صابر', 'صابر', 'محمد جبريل', 'جبريل',
    'محمود الشحات', 'الشحات', 'شيخ الشعراوي', 'الشعراوي',
    'مصطفى إسماعيل', 'محمد رفعت', 'رفعت', 'عبد الباسط',
    'ياسين', 'القارئ ياسين', 'محمود الحصري',
    'شعبان', 'مصطفى رعد العزاوي',
  ];

  // Kuwaiti reciters
  const kuwaitiReciters = [
    'مشاري العفاسي', 'العفاسي', 'مشاري بن راشد',
    'أحمد عبدالعزيز عوض',
  ];

  // Sudanese reciters
  const sudaneseReciters = [
    'الزين محمد أحمد', 'الزين', 'نورين محمد صديق',
  ];

  // Emirati reciters
  const emiratiReciters = [
    'وليد النائحي', 'أكرم العلاقمي',
  ];

  // Yemeni reciters
  const yemeniReciters = [
    'محمد صالح', 'عبدالله العمري',
  ];

  // Syrian reciters
  const syrianReciters = [
    'محمد اللحيدان', 'مصطفى الفرج',
  ];

  // Iraqi reciters
  const iraqiReciters = [
    'رعد الكردي', 'الكردي',
  ];

  // Bahraini reciters
  const bahrainiReciters = [
    'عبدالله البعيجان',
  ];

  // Algerian reciters
  const algerianReciters = [
    'محمد حبلص',
  ];

  // Mauritanian reciters
  const mauritanianReciters = [
    'الشيخ ولد محمدن',
  ];

  for (final keyword in saudiReciters) {
    if (n.contains(keyword)) return '🇸🇦 السعودية';
  }
  for (final keyword in egyptianReciters) {
    if (n.contains(keyword)) return '🇪🇬 مصر';
  }
  for (final keyword in kuwaitiReciters) {
    if (n.contains(keyword)) return '🇰🇼 الكويت';
  }
  for (final keyword in sudaneseReciters) {
    if (n.contains(keyword)) return '🇸🇩 السودان';
  }
  for (final keyword in emiratiReciters) {
    if (n.contains(keyword)) return '🇦🇪 الإمارات';
  }
  for (final keyword in yemeniReciters) {
    if (n.contains(keyword)) return '🇾🇪 اليمن';
  }
  for (final keyword in syrianReciters) {
    if (n.contains(keyword)) return '🇸🇾 سوريا';
  }
  for (final keyword in iraqiReciters) {
    if (n.contains(keyword)) return '🇮🇶 العراق';
  }
  for (final keyword in bahrainiReciters) {
    if (n.contains(keyword)) return '🇧🇭 البحرين';
  }
  for (final keyword in algerianReciters) {
    if (n.contains(keyword)) return '🇩🇿 الجزائر';
  }
  for (final keyword in mauritanianReciters) {
    if (n.contains(keyword)) return '🇲🇷 موريتانيا';
  }

  // Catch-all by analyzing the URL slug for common patterns
  return 'أخرى';
}

/// Get unique nationalities from a list of radios.
List<String> getAvailableNationalities(List<Mp3QuranRadio> radios) {
  final nationalities = <String>{};
  for (final radio in radios) {
    nationalities.add(getReciterNationality(radio.name));
  }
  final sorted = nationalities.toList()..sort();
  return [kAllCountries, ...sorted];
}

// ──────────────────────────────────────────────
// Radio Favorites
// ──────────────────────────────────────────────

class RadioFavoritesNotifier extends StateNotifier<Set<int>> {
  final StorageService _storage;

  RadioFavoritesNotifier(this._storage) : super({}) {
    _load();
  }

  void _load() {
    final saved = _storage.getSetting<List>('radioFavorites');
    if (saved != null) {
      state = saved.cast<int>().toSet();
    }
  }

  Future<void> toggle(int radioId) async {
    final updated = Set<int>.from(state);
    if (updated.contains(radioId)) {
      updated.remove(radioId);
    } else {
      updated.add(radioId);
    }
    state = updated;
    await _storage.putSetting('radioFavorites', updated.toList());
  }

  bool isFavorite(int radioId) => state.contains(radioId);
}

final radioFavoritesProvider =
    StateNotifierProvider<RadioFavoritesNotifier, Set<int>>((ref) {
  return RadioFavoritesNotifier(ref.watch(storageServiceProvider));
});
