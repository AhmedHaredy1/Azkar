import '../models/surah.dart';

abstract class QuranRepository {
  Future<List<Surah>> getSurahs();
  Future<Surah?> getSurahByNumber(int number);
  Future<List<Surah>> searchAyahs(String query);
}
