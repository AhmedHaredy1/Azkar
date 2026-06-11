import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/quran_audio_provider.dart';

/// Shared reciter picker used by both Quran reading modes (text reader's
/// audio bar and the PDF mushaf's floating controls / ayah sheet).
///
/// Switching mid-playback resumes from the same ayah with the new reciter
/// (handled by [QuranAudioNotifier.setReciter]).
void showReciterPicker(BuildContext context, WidgetRef ref) {
  final currentReciterId = ref.read(quranAudioProvider).reciterId;
  // Capture the notifier before showing the sheet to avoid using ref
  // after the calling widget is disposed.
  final audioNotifier = ref.read(quranAudioProvider.notifier);

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2C1810),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'اختر القارئ',
                style: GoogleFonts.cairo(
                  color: const Color(0xFFD4A017),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            ...availableReciters.map((reciter) {
              final isSelected = reciter.id == currentReciterId;
              return ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color:
                      isSelected ? const Color(0xFFD4A017) : Colors.white54,
                  size: 20,
                ),
                title: Text(
                  reciter.nameAr,
                  style: GoogleFonts.cairo(
                    color: isSelected ? const Color(0xFFD4A017) : Colors.white,
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  reciter.nameEn,
                  style: GoogleFonts.cairo(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  audioNotifier.setReciter(reciter.id);
                  Navigator.pop(sheetContext);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}
