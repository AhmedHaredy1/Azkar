import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/arabic_number_utils.dart';
import '../../prayer_times/presentation/providers/prayer_times_provider.dart';

class Mosque {
  final String name;
  final double lat;
  final double lng;
  final double distanceMeters;
  const Mosque({
    required this.name,
    required this.lat,
    required this.lng,
    required this.distanceMeters,
  });
}

const _overpassEndpoints = <String>[
  // Official Overpass server — most reliable, keep first.
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
  'https://overpass.openstreetmap.fr/api/interpreter',
  'https://overpass.osm.ch/api/interpreter',
];

Future<http.Response> _postOverpass(String endpoint, String body) async {
  final r = await http.post(
    Uri.parse(endpoint),
    headers: const {
      'User-Agent': 'Azkar-Flutter/1.0 (github.com/AhmedHaredy1/Azkar)',
      'Accept': 'application/json',
    },
    // http's Map body encodes as application/x-www-form-urlencoded
    // which is exactly what Overpass expects for POST queries.
    body: {'data': body},
  ).timeout(const Duration(seconds: 25));
  if (r.statusCode != 200) {
    throw http.ClientException('HTTP ${r.statusCode}', Uri.parse(endpoint));
  }
  return r;
}

Future<List<Mosque>> _fetchNearbyMosques(Position pos) async {
  const radiusMeters = 5000;
  final around = 'around:$radiusMeters,${pos.latitude},${pos.longitude}';
  // Simple, standard OSM selectors. `amenity=place_of_worship + religion=muslim`
  // is the canonical tag; `building=mosque` and `amenity=mosque` cover legacy
  // tagging. Dropping the name-regex clauses keeps the server-side query fast
  // enough that free Overpass endpoints don't time out.
  final body = '''
[out:json][timeout:25];
(
  nwr["amenity"="place_of_worship"]["religion"="muslim"]($around);
  nwr["building"="mosque"]($around);
  nwr["amenity"="mosque"]($around);
);
out center tags;
''';

  // Try endpoints sequentially. The first success wins; we only hit the
  // next server if the previous one timed out or returned non-200.
  http.Response? resp;
  Object? lastError;
  for (final endpoint in _overpassEndpoints) {
    try {
      resp = await _postOverpass(endpoint, body);
      if (resp.statusCode == 200) break;
    } catch (e) {
      lastError = e;
      resp = null;
    }
  }

  if (resp == null || resp.statusCode != 200) {
    throw Exception(lastError == null
        ? 'تعذّر الاتصال بخادم المساجد. تأكد من اتصال الإنترنت ثم أعد المحاولة.'
        : 'تعذّر الاتصال بخادم المساجد. تأكد من اتصال الإنترنت ثم أعد المحاولة.');
  }

  final data = json.decode(resp.body) as Map<String, dynamic>;
  final elements = (data['elements'] as List?) ?? const [];

  final out = <Mosque>[];
  final seenIds = <String>{};
  for (final e in elements) {
    final id = '${e['type']}/${e['id']}';
    if (!seenIds.add(id)) continue;

    final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? {};
    final name = (tags['name:ar'] ?? tags['name'] ?? 'مسجد') as String;
    double? lat;
    double? lng;
    if (e['lat'] != null && e['lon'] != null) {
      lat = (e['lat'] as num).toDouble();
      lng = (e['lon'] as num).toDouble();
    } else if (e['center'] is Map) {
      final c = e['center'] as Map;
      lat = (c['lat'] as num?)?.toDouble();
      lng = (c['lon'] as num?)?.toDouble();
    }
    if (lat == null || lng == null) continue;

    final amenity = tags['amenity'];
    final building = tags['building'];
    final religion = tags['religion'];
    final isClearlyMosque =
        (amenity == 'place_of_worship' && religion == 'muslim') ||
            amenity == 'mosque' ||
            building == 'mosque';
    if (!isClearlyMosque) {
      if (amenity != null && amenity != 'place_of_worship') continue;
      if (building != null && building != 'yes') continue;
    }

    final dist = _haversine(pos.latitude, pos.longitude, lat, lng);
    out.add(Mosque(name: name, lat: lat, lng: lng, distanceMeters: dist));
  }
  out.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  return out;
}

double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLon = (lon2 - lon1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

final nearbyMosquesProvider = FutureProvider<List<Mosque>>((ref) async {
  final pos = await ref.watch(locationProvider.future);
  return _fetchNearbyMosques(pos);
});

class NearbyMosquesScreen extends ConsumerWidget {
  const NearbyMosquesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(nearbyMosquesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'المساجد القريبة',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(nearbyMosquesProvider),
            icon: const Icon(Icons.refresh, size: 20, color: AppColors.ink2),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: async.when(
        loading: () => const _Loading(),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(nearbyMosquesProvider),
        ),
        data: (mosques) {
          if (mosques.isEmpty) return const _Empty();
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(count: mosques.length),
                const SizedBox(height: AppSpacing.sm + 2),
                _MosqueList(mosques: mosques),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  const _Header({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'ضمن نطاق ٥ كم',
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.ink3,
          ),
        ),
        Text(
          '${ArabicNumberUtils.toEasternArabic(count)} مسجداً',
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.ink2,
          ),
        ),
      ],
    );
  }
}

class _MosqueList extends StatelessWidget {
  final List<Mosque> mosques;
  const _MosqueList({required this.mosques});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            for (int i = 0; i < mosques.length; i++) ...[
              _MosqueRow(mosque: mosques[i]),
              if (i < mosques.length - 1)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.md + 4,
                  ),
                  child: Container(height: 1, color: AppColors.hairline),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MosqueRow extends StatelessWidget {
  final Mosque mosque;
  const _MosqueRow({required this.mosque});

  @override
  Widget build(BuildContext context) {
    final distText = _formatDistance(mosque.distanceMeters);
    return InkWell(
      onTap: () => _openInMap(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 4,
          vertical: AppSpacing.md + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.mosque_outlined,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mosque.name,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'افتح في الخرائط',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  distText,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                const Icon(
                  Icons.chevron_left,
                  size: 16,
                  color: AppColors.ink3,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double m) {
    if (m < 1000) {
      return ArabicNumberUtils.toEasternArabicFromString(
        '${m.toStringAsFixed(0)} م',
      );
    }
    return ArabicNumberUtils.toEasternArabicFromString(
      '${(m / 1000).toStringAsFixed(2)} كم',
    );
  }

  Future<void> _openInMap(BuildContext context) async {
    final googleMaps = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${mosque.lat},${mosque.lng}',
    );
    final ok = await launchUrl(
      googleMaps,
      mode: LaunchMode.externalApplication,
    );
    if (ok || !context.mounted) return;

    final web = Uri.parse(
      'https://www.openstreetmap.org/?mlat=${mosque.lat}&mlon=${mosque.lng}#map=17/${mosque.lat}/${mosque.lng}',
    );
    await launchUrl(web, mode: LaunchMode.externalApplication);
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'جاري البحث عن المساجد القريبة...',
            style: GoogleFonts.cairo(color: AppColors.ink2),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mosque_outlined,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md + 2),
            Text(
              'لم يتم العثور على مساجد في نطاق ٥ كم',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'تعذّر تحميل المساجد',
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.ink2,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSpacing.md + 2),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(
                'إعادة المحاولة',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.hairlineStrong),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm + 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
