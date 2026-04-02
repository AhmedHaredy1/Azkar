import '../domain/models/surah.dart';
import '../domain/repositories/quran_repository.dart';
import 'quran_local_source.dart';

class QuranRepositoryImpl implements QuranRepository {
  final QuranLocalSource _localSource;

  QuranRepositoryImpl(this._localSource);

  @override
  Future<List<Surah>> getSurahs() {
    return _localSource.loadSurahs();
  }

  @override
  Future<Surah?> getSurahByNumber(int number) {
    return _localSource.getSurahByNumber(number);
  }

  @override
  Future<List<Surah>> searchAyahs(String query) async {
    final surahs = await _localSource.loadSurahs();
    return surahs.where((surah) {
      return surah.ayahs.any((ayah) => ayah.textAr.contains(query));
    }).toList();
  }
}
