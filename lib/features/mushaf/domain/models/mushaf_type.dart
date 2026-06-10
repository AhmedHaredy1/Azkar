import '../mushaf_index.dart';

class MushafType {
  final String id;
  final String nameAr;
  final String nameEn;
  final String fileName;
  final String downloadUrl;
  final int totalPdfPages;
  final int fileSizeMB;
  final String descriptionAr;

  const MushafType({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.fileName,
    required this.downloadUrl,
    required this.totalPdfPages,
    required this.fileSizeMB,
    this.descriptionAr = '',
  });

  MushafIndex? get index => getIndexFor(id);

  int getSurahStartPage(int surahNumber) =>
      index?.getSurahStartPage(surahNumber) ?? 1;

  int? getSurahForPage(int pdfPage) => index?.getSurahForPage(pdfPage);

  int getSurahEndPage(int surahNumber) =>
      index?.getSurahEndPage(surahNumber) ?? totalPdfPages;

  /// Front-matter (cover/intro) pages before the printed mushaf page ١.
  /// Derived from where Al-Fatihah starts in the PDF, so it stays correct
  /// per mushaf without hardcoding.
  int get pdfPageOffset => getSurahStartPage(1) - 1;

  /// Number of printed mushaf pages (PDF pages minus front matter).
  int get totalMushafPages => totalPdfPages - pdfPageOffset;

  /// Printed mushaf page number shown to the user for a raw PDF page.
  /// Front-matter pages display as page ١.
  int mushafPageFromPdf(int pdfPage) =>
      (pdfPage - pdfPageOffset).clamp(1, totalMushafPages);

  /// Raw PDF page for a printed mushaf page the user entered.
  int pdfPageFromMushaf(int mushafPage) =>
      (mushafPage + pdfPageOffset).clamp(1, totalPdfPages);
}

const List<MushafType> availableMushafs = [
  MushafType(
    id: 'khass1brown',
    nameAr: 'مصحف خاص بُنّي',
    nameEn: 'Khass Brown',
    fileName: 'khass1brown.pdf',
    downloadUrl:
        'https://www.dropbox.com/scl/fi/ptpsoa0pvt8t6pmki2tbx/khass1brown.pdf?rlkey=n9kybtbhi1ofcrxz3499t8lwh&st=9rbma8uq&dl=1',
    totalPdfPages: 640,
    fileSizeMB: 581,
    descriptionAr: 'مصحف بتصميم خاص بخلفية بُنّية',
  ),
  MushafType(
    id: 'wasat39',
    nameAr: 'مصحف وسط ٣٩',
    nameEn: 'Wasat 39-line',
    fileName: 'wasat39.pdf',
    downloadUrl:
        'https://www.dropbox.com/scl/fi/cx8teua0y4b1dlm0wxboo/wasat39.pdf?rlkey=bfjoq3qr8zobkjgvvxvyufk2h&st=uz92gs2s&dl=1',
    totalPdfPages: 640,
    fileSizeMB: 202,
    descriptionAr: 'مصحف وسط ٣٩ سطرًا بحجم متوسط',
  ),
  MushafType(
    id: 'standardthree',
    nameAr: 'مصحف ستاندرد ثري',
    nameEn: 'Standard Three',
    fileName: 'standardthree.pdf',
    downloadUrl:
        'https://www.dropbox.com/scl/fi/2ibf8uru6p3pxv61wuqfa/standardthree.pdf?rlkey=nvrpp4cbzmf7rqtqq88wfo2cl&st=9k3263tm&dl=1',
    totalPdfPages: 560,
    fileSizeMB: 228,
    descriptionAr: 'مصحف ستاندرد ثري بتصميم كلاسيكي',
  ),
  MushafType(
    id: 'mumtaz',
    nameAr: 'مصحف ممتاز',
    nameEn: 'Mumtaz',
    fileName: 'mumtaz.pdf',
    downloadUrl:
        'https://www.dropbox.com/scl/fi/vvqdoubvio1d18lkmp9zw/mumtaz.pdf?rlkey=csx7znt1135apudpf46a85wbw&st=jjybqa5i&dl=1',
    totalPdfPages: 640,
    fileSizeMB: 343,
    descriptionAr: 'مصحف ممتاز بجودة عالية',
  ),
  MushafType(
    id: 'standard39',
    nameAr: 'مصحف ستاندرد ٣٩',
    nameEn: 'Standard 39-line',
    fileName: 'standard39.pdf',
    downloadUrl:
        'https://www.dropbox.com/scl/fi/w5du8w9b86ak1e807zbhy/standard39.pdf?rlkey=36ea6ftym6901lq3qbbiyfrcw&st=lpblw9is&dl=1',
    totalPdfPages: 640,
    fileSizeMB: 232,
    descriptionAr: 'مصحف ستاندرد ٣٩ سطرًا',
  ),
];

MushafType? getMushafById(String id) {
  for (final m in availableMushafs) {
    if (m.id == id) return m;
  }
  return null;
}
