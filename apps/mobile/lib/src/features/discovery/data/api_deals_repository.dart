import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../domain/deal.dart';
import 'seed_deals_repository.dart';

// NYC East Village bounding box used to normalise lat/lng → map (0–1) coords.
const _lngMin = -74.01;
const _lngMax = -73.97;
const _latMin = 40.72;
const _latMax = 40.76;

class ApiDealsRepository implements DealsRepository {
  const ApiDealsRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Deal>> listDeals() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/v1/listings',
      queryParameters: {'limit': 50},
    );

    final body = response.data!;
    final items = (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return items.map(_mapToDeal).toList();
  }
}

Deal _mapToDeal(Map<String, dynamic> r) {
  final category = r['category'] as String;
  final trustBandStr = r['trustBand'] as String;
  final confirmationCount = (r['confirmationCount'] as num).toInt();
  final confidenceScore = double.tryParse(r['confidenceScore'] as String? ?? '') ?? 80.0;
  final lat = (r['latitude'] as num?)?.toDouble();
  final lng = (r['longitude'] as num?)?.toDouble();
  final tags = (r['tags'] as List<dynamic>).cast<String>();
  final schedules = (r['schedules'] as List<dynamic>).cast<Map<String, dynamic>>();
  final updatedAt = DateTime.tryParse(r['updatedAt'] as String? ?? '') ?? DateTime.now();
  final freshnessAt = r['freshnessAt'] != null
      ? DateTime.tryParse(r['freshnessAt'] as String)
      : null;

  return Deal(
    id: r['id'] as String,
    venueName: r['venueName'] as String,
    cuisine: _cuisineFromTags(tags, category),
    neighborhood: r['venueNeighborhood'] as String? ?? '',
    distanceMiles: 0.0, // requires user location — Phase D
    rating: _ratingFromScore(confidenceScore),
    valueHook: r['title'] as String,
    categoryLabel: _categoryLabel(category),
    scheduleLabel: _scheduleLabel(schedules),
    trustBand: _trustBand(trustBandStr),
    freshnessText: _freshnessText(trustBandStr, confirmationCount, freshnessAt),
    lastUpdatedText: _lastUpdatedText(updatedAt),
    conditions: r['description'] as String? ?? '',
    valueNote: r['description'] as String? ?? r['title'] as String,
    sourceNote: _sourceNote(trustBandStr),
    tone: _toneFromCategory(category),
    mapDx: _normalizeLng(lng),
    mapDy: _normalizeLat(lat),
    lat: lat,
    lng: lng,
    icon: _iconFromCategory(category),
    offers: const [], // structured offer prices not in schema yet
  );
}

// ── Derivation helpers ────────────────────────────────────────────────────────

String _cuisineFromTags(List<String> tags, String category) {
  const cuisineTags = {
    'pizza': 'Pizza',
    'indian': 'Indian',
    'burger': 'American',
    'ramen': 'Japanese',
    'tacos': 'Mexican',
    'vegetarian': 'Vegetarian',
  };
  for (final tag in tags) {
    final match = cuisineTags[tag.toLowerCase()];
    if (match != null) return match;
  }
  return _categoryLabel(category);
}

double _ratingFromScore(double score) {
  // Map 0–100 confidence score to 3.0–5.0 star range.
  return (3.0 + (score / 100.0) * 2.0).clamp(3.0, 5.0);
}

String _categoryLabel(String category) => switch (category) {
      'cheap_eats' => 'Cheap eats',
      'food_deal' => 'Food deal',
      'drink_deal' => 'Drink deal',
      'student_offer' => 'Student offer',
      'special' => 'Special',
      'happy_hour' => 'Happy hour',
      _ => category,
    };

TrustBand _trustBand(String raw) => switch (raw) {
      'founder_verified' => TrustBand.founderVerified,
      'merchant_confirmed' => TrustBand.founderVerified,
      'user_confirmed' => TrustBand.userConfirmed,
      'recently_updated' => TrustBand.recentlyUpdated,
      _ => TrustBand.needsRecheck,
    };

String _freshnessText(String trustBand, int count, DateTime? freshnessAt) {
  if (trustBand == 'founder_verified' || trustBand == 'merchant_confirmed') {
    return 'Founder verified';
  }
  if (count > 0) {
    return '$count recent confirmation${count > 1 ? 's' : ''}';
  }
  if (freshnessAt != null) {
    final diff = DateTime.now().difference(freshnessAt);
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
    return 'Updated ${diff.inDays}d ago';
  }
  return 'Recently updated';
}

String _lastUpdatedText(DateTime updatedAt) {
  final now = DateTime.now();
  final diff = now.difference(updatedAt);
  final timeStr =
      '${updatedAt.hour % 12 == 0 ? 12 : updatedAt.hour % 12}:${updatedAt.minute.toString().padLeft(2, '0')} ${updatedAt.hour < 12 ? 'AM' : 'PM'}';
  if (diff.inDays == 0) return 'Today at $timeStr';
  if (diff.inDays == 1) return 'Yesterday at $timeStr';
  return '${updatedAt.month}/${updatedAt.day} at $timeStr';
}

String _sourceNote(String trustBand) => switch (trustBand) {
      'founder_verified' => 'Founder-added with direct verification.',
      'merchant_confirmed' => 'Confirmed directly by the merchant.',
      'user_confirmed' => 'Multiple user confirmations on record.',
      'recently_updated' => 'Recently updated via public sources.',
      'needs_recheck' => 'Needs reconfirmation — may be outdated.',
      'disputed' => 'Currently disputed by multiple users.',
      _ => 'Community sourced.',
    };

DealTone _toneFromCategory(String category) => switch (category) {
      'cheap_eats' => DealTone.peach,
      'food_deal' => DealTone.sky,
      'drink_deal' => DealTone.rose,
      'student_offer' => DealTone.mint,
      'special' => DealTone.gold,
      'happy_hour' => DealTone.lilac,
      _ => DealTone.gold,
    };

IconData _iconFromCategory(String category) => switch (category) {
      'cheap_eats' => Icons.local_dining_rounded,
      'food_deal' => Icons.restaurant_rounded,
      'drink_deal' => Icons.local_bar_rounded,
      'student_offer' => Icons.school_rounded,
      'special' => Icons.star_rounded,
      'happy_hour' => Icons.local_drink_rounded,
      _ => Icons.local_offer_rounded,
    };

/// Build a human-readable schedule label from the schedule list.
/// Finds today's active slot first, then tonight, then falls back to a summary.
String _scheduleLabel(List<Map<String, dynamic>> schedules) {
  if (schedules.isEmpty) return 'Check venue for hours';

  final now = DateTime.now();
  final todayDow = now.weekday % 7; // Dart: Mon=1…Sun=7 → 0=Sun…6=Sat

  final todays = schedules.where((s) => (s['dayOfWeek'] as int) == todayDow).toList();

  for (final s in todays) {
    final start = _parseTime(s['startTime'] as String);
    final end = _parseTime(s['endTime'] as String);
    if (start == null || end == null) continue;
    final nowMins = now.hour * 60 + now.minute;
    final startMins = start.$1 * 60 + start.$2;
    final endMins = end.$1 * 60 + end.$2;
    if (nowMins >= startMins && nowMins < endMins) {
      return 'Live now • ${_dowLabel(todayDow)} ${_fmtTime(start)}–${_fmtTime(end)}';
    }
    // Tonight: starts later today
    if (nowMins < startMins) {
      return 'Tonight • ${_dowLabel(todayDow)} ${_fmtTime(start)}–${_fmtTime(end)}';
    }
  }

  // Summarise recurring days
  final days = schedules.map((s) => s['dayOfWeek'] as int).toSet().toList()..sort();
  final start = _parseTime(schedules.first['startTime'] as String);
  final end = _parseTime(schedules.first['endTime'] as String);
  final timeRange = (start != null && end != null)
      ? '${_fmtTime(start)}–${_fmtTime(end)}'
      : '';
  final dayStr = days.map(_dowLabel).join(', ');
  return '$dayStr $timeRange'.trim();
}

(int, int)? _parseTime(String t) {
  final parts = t.split(':');
  if (parts.length < 2) return null;
  return (int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
}

String _fmtTime((int, int) t) {
  final h = t.$1;
  final m = t.$2;
  final suffix = h < 12 ? 'AM' : 'PM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return m == 0 ? '$h12$suffix' : '$h12:${m.toString().padLeft(2, '0')}$suffix';
}

String _dowLabel(int dow) => const [
      'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
    ][dow.clamp(0, 6)];

double _normalizeLng(double? lng) {
  if (lng == null) return 0.5;
  return ((lng - _lngMin) / (_lngMax - _lngMin)).clamp(0.0, 1.0);
}

double _normalizeLat(double? lat) {
  if (lat == null) return 0.5;
  // Invert: higher lat = lower on screen (mapDy 0 = top)
  return (1.0 - (lat - _latMin) / (_latMax - _latMin)).clamp(0.0, 1.0);
}
