import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';

enum DiscoveryFilter { all, nearMe, topRated, fresh }

enum DealTone { peach, rose, sky, mint, gold, lilac }

enum TrustBand { founderVerified, userConfirmed, recentlyUpdated, needsRecheck }

class DealOffer {
  const DealOffer({
    required this.title,
    required this.originalPrice,
    required this.dealPrice,
  });

  final String title;
  final double originalPrice;
  final double dealPrice;
}

class Deal {
  const Deal({
    required this.id,
    required this.venueName,
    required this.cuisine,
    required this.neighborhood,
    required this.distanceMiles,
    required this.rating,
    required this.valueHook,
    required this.categoryLabel,
    required this.scheduleLabel,
    required this.trustBand,
    required this.freshnessText,
    required this.lastUpdatedText,
    required this.conditions,
    required this.valueNote,
    required this.sourceNote,
    required this.tone,
    required this.mapDx,
    required this.mapDy,
    required this.icon,
    required this.offers,
  });

  final String id;
  final String venueName;
  final String cuisine;
  final String neighborhood;
  final double distanceMiles;
  final double rating;
  final String valueHook;
  final String categoryLabel;
  final String scheduleLabel;
  final TrustBand trustBand;
  final String freshnessText;
  final String lastUpdatedText;
  final String conditions;
  final String valueNote;
  final String sourceNote;
  final DealTone tone;
  final double mapDx;
  final double mapDy;
  final IconData icon;
  final List<DealOffer> offers;
}

extension DiscoveryFilterX on DiscoveryFilter {
  String get label => switch (this) {
        DiscoveryFilter.all => 'All',
        DiscoveryFilter.nearMe => 'Near Me',
        DiscoveryFilter.topRated => 'Top Rated',
        DiscoveryFilter.fresh => 'New',
      };
}

extension DealToneX on DealTone {
  Color get surfaceTint => switch (this) {
        DealTone.peach => DealDropPalette.coral,
        DealTone.rose => DealDropPalette.rose,
        DealTone.sky => DealDropPalette.sky,
        DealTone.mint => const Color(0xFFDDF7EE),
        DealTone.gold => DealDropPalette.goldSoft,
        DealTone.lilac => DealDropPalette.lilac,
      };

  Color get accent => switch (this) {
        DealTone.peach => DealDropPalette.warning,
        DealTone.rose => const Color(0xFFC26A7A),
        DealTone.sky => const Color(0xFF2D7EEA),
        DealTone.mint => DealDropPalette.mintDeep,
        DealTone.gold => DealDropPalette.goldDeep,
        DealTone.lilac => const Color(0xFF7D63D7),
      };
}

extension TrustBandX on TrustBand {
  String get label => switch (this) {
        TrustBand.founderVerified => 'Founder verified',
        TrustBand.userConfirmed => 'User confirmed',
        TrustBand.recentlyUpdated => 'Recently updated',
        TrustBand.needsRecheck => 'Needs recheck',
      };

  Color get tint => switch (this) {
        TrustBand.founderVerified => DealDropPalette.goldSoft,
        TrustBand.userConfirmed => const Color(0xFFDDF7EE),
        TrustBand.recentlyUpdated => DealDropPalette.sky,
        TrustBand.needsRecheck => const Color(0xFFFFE5CC),
      };

  Color get foreground => switch (this) {
        TrustBand.founderVerified => DealDropPalette.goldDeep,
        TrustBand.userConfirmed => DealDropPalette.success,
        TrustBand.recentlyUpdated => const Color(0xFF2D7EEA),
        TrustBand.needsRecheck => DealDropPalette.warning,
      };
}
