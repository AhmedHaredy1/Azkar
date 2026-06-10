class MushafIndex {
  final Map<int, int> surahToPdfPage;
  final int totalPdfPages;

  const MushafIndex({
    required this.surahToPdfPage,
    required this.totalPdfPages,
  });

  int getSurahStartPage(int surahNumber) {
    return surahToPdfPage[surahNumber] ?? 1;
  }

  int? getSurahForPage(int pdfPage) {
    int? result;
    for (int i = 1; i <= 114; i++) {
      final p = surahToPdfPage[i];
      if (p == null) continue;
      if (p <= pdfPage) {
        result = i;
      } else {
        break;
      }
    }
    return result;
  }

  int getSurahEndPage(int surahNumber) {
    for (int n = surahNumber + 1; n <= 114; n++) {
      final next = surahToPdfPage[n];
      if (next == null) continue;
      if (next == surahToPdfPage[surahNumber]) continue;
      return next - 1;
    }
    return totalPdfPages;
  }
}

const Map<int, int> _widePages = {
  1: 4, 2: 5, 3: 53, 4: 80, 5: 109, 6: 131, 7: 154, 8: 180, 9: 190, 10: 211,
  11: 224, 12: 238, 13: 252, 14: 258, 15: 265, 16: 270, 17: 285, 18: 296,
  19: 308, 20: 315, 21: 325, 22: 335, 23: 345, 24: 353, 25: 362, 26: 370,
  27: 380, 28: 388, 29: 399, 30: 407, 31: 414, 32: 418, 33: 421, 34: 431,
  35: 437, 36: 443, 37: 449, 38: 456, 39: 461, 40: 470, 41: 480, 42: 486,
  43: 492, 44: 499, 45: 502, 46: 505, 47: 510, 48: 514, 49: 518, 50: 521,
  51: 523, 52: 526, 53: 529, 54: 531, 55: 534, 56: 537, 57: 540, 58: 545,
  59: 548, 60: 552, 61: 554, 62: 556, 63: 557, 64: 559, 65: 561, 66: 563,
  67: 565, 68: 567, 69: 569, 70: 571, 71: 573, 72: 575, 73: 577, 74: 578,
  75: 580, 76: 581, 77: 583, 78: 585, 79: 586, 80: 588, 81: 589, 82: 590,
  83: 590, 84: 592, 85: 593, 86: 594, 87: 594, 88: 595, 89: 596, 90: 597,
  91: 598, 92: 598, 93: 599, 94: 599, 95: 600, 96: 600, 97: 601, 98: 601,
  99: 602, 100: 602, 101: 603, 102: 603, 103: 604, 104: 604, 105: 604,
  106: 605, 107: 605, 108: 605, 109: 606, 110: 606, 111: 606, 112: 607,
  113: 607, 114: 607,
};

const Map<int, int> _standardthreePages = {
  1: 4, 2: 5, 3: 44, 4: 66, 5: 89, 6: 107, 7: 125, 8: 147, 9: 155, 10: 171,
  11: 183, 12: 195, 13: 207, 14: 212, 15: 218, 16: 223, 17: 235, 18: 245,
  19: 255, 20: 262, 21: 270, 22: 278, 23: 286, 24: 293, 25: 302, 26: 308,
  27: 317, 28: 325, 29: 334, 30: 340, 31: 346, 32: 349, 33: 352, 34: 360,
  35: 366, 36: 371, 37: 376, 38: 382, 39: 387, 40: 394, 41: 402, 42: 407,
  43: 413, 44: 419, 45: 421, 46: 425, 47: 429, 48: 432, 49: 436, 50: 439,
  51: 441, 52: 444, 53: 446, 54: 449, 55: 451, 56: 454, 57: 457, 58: 461,
  59: 464, 60: 467, 61: 470, 62: 471, 63: 473, 64: 474, 65: 476, 66: 478,
  67: 480, 68: 482, 69: 484, 70: 486, 71: 488, 72: 490, 73: 492, 74: 493,
  75: 495, 76: 497, 77: 499, 78: 500, 79: 502, 80: 503, 81: 504, 82: 505,
  83: 506, 84: 507, 85: 508, 86: 509, 87: 510, 88: 511, 89: 512, 90: 513,
  91: 514, 92: 514, 93: 515, 94: 516, 95: 516, 96: 516, 97: 517, 98: 518,
  99: 518, 100: 519, 101: 519, 102: 520, 103: 520, 104: 521, 105: 521,
  106: 522, 107: 522, 108: 522, 109: 523, 110: 523, 111: 523, 112: 524,
  113: 524, 114: 524,
};

const Map<String, MushafIndex> mushafIndices = {
  'khass1brown':
      MushafIndex(surahToPdfPage: _widePages, totalPdfPages: 640),
  'mumtaz': MushafIndex(surahToPdfPage: _widePages, totalPdfPages: 640),
  'standard39':
      MushafIndex(surahToPdfPage: _widePages, totalPdfPages: 640),
  'wasat39': MushafIndex(surahToPdfPage: _widePages, totalPdfPages: 640),
  'standardthree':
      MushafIndex(surahToPdfPage: _standardthreePages, totalPdfPages: 560),
};

MushafIndex? getIndexFor(String mushafId) => mushafIndices[mushafId];
