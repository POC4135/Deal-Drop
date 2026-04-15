import 'dart:convert';

import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';

enum TrustBand {
  founderVerified,
  merchantConfirmed,
  userConfirmed,
  recentlyUpdated,
  needsRecheck,
  disputed,
}

TrustBand trustBandFromApi(String value) {
  return switch (value) {
    'founder_verified' => TrustBand.founderVerified,
    'merchant_confirmed' => TrustBand.merchantConfirmed,
    'user_confirmed' => TrustBand.userConfirmed,
    'recently_updated' => TrustBand.recentlyUpdated,
    'needs_recheck' => TrustBand.needsRecheck,
    'disputed' => TrustBand.disputed,
    _ => TrustBand.recentlyUpdated,
  };
}

String trustBandToApi(TrustBand value) {
  return switch (value) {
    TrustBand.founderVerified => 'founder_verified',
    TrustBand.merchantConfirmed => 'merchant_confirmed',
    TrustBand.userConfirmed => 'user_confirmed',
    TrustBand.recentlyUpdated => 'recently_updated',
    TrustBand.needsRecheck => 'needs_recheck',
    TrustBand.disputed => 'disputed',
  };
}

extension TrustBandX on TrustBand {
  String get label => switch (this) {
    TrustBand.founderVerified => 'Founder verified',
    TrustBand.merchantConfirmed => 'Merchant confirmed',
    TrustBand.userConfirmed => 'User confirmed',
    TrustBand.recentlyUpdated => 'Recently updated',
    TrustBand.needsRecheck => 'Needs recheck',
    TrustBand.disputed => 'Disputed',
  };

  String get shortLabel => switch (this) {
    TrustBand.founderVerified => 'Founder',
    TrustBand.merchantConfirmed => 'Merchant',
    TrustBand.userConfirmed => 'Users',
    TrustBand.recentlyUpdated => 'Fresh',
    TrustBand.needsRecheck => 'Recheck',
    TrustBand.disputed => 'Disputed',
  };

  String get explanation => switch (this) {
    TrustBand.founderVerified => 'Verified directly by DealDrop.',
    TrustBand.merchantConfirmed => 'Confirmed by venue staff recently.',
    TrustBand.userConfirmed => 'Backed by strong community confirmations.',
    TrustBand.recentlyUpdated => 'Fresh enough to be useful, but still moving.',
    TrustBand.needsRecheck => 'Still visible, but trust is slipping.',
    TrustBand.disputed =>
      'Recent reports conflict with the latest known details.',
  };

  Color get tint => switch (this) {
    TrustBand.founderVerified => DealDropPalette.goldSoft,
    TrustBand.merchantConfirmed => const Color(0xFFE3F9F1),
    TrustBand.userConfirmed => const Color(0xFFDDF7EE),
    TrustBand.recentlyUpdated => DealDropPalette.sky,
    TrustBand.needsRecheck => const Color(0xFFFFE5CC),
    TrustBand.disputed => const Color(0xFFFBE0E5),
  };

  Color get foreground => switch (this) {
    TrustBand.founderVerified => DealDropPalette.goldDeep,
    TrustBand.merchantConfirmed => DealDropPalette.mintDeep,
    TrustBand.userConfirmed => DealDropPalette.success,
    TrustBand.recentlyUpdated => const Color(0xFF2D7EEA),
    TrustBand.needsRecheck => DealDropPalette.warning,
    TrustBand.disputed => const Color(0xFFAF3150),
  };

  IconData get icon => switch (this) {
    TrustBand.founderVerified => Icons.workspace_premium_rounded,
    TrustBand.merchantConfirmed => Icons.storefront_rounded,
    TrustBand.userConfirmed => Icons.verified_user_rounded,
    TrustBand.recentlyUpdated => Icons.bolt_rounded,
    TrustBand.needsRecheck => Icons.schedule_rounded,
    TrustBand.disputed => Icons.error_outline_rounded,
  };
}

enum DealTone { peach, rose, sky, mint, gold, lilac }

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

class ListingOffer {
  const ListingOffer({
    required this.id,
    required this.title,
    required this.originalPrice,
    required this.dealPrice,
    required this.currency,
  });

  final String id;
  final String title;
  final double originalPrice;
  final double dealPrice;
  final String currency;

  factory ListingOffer.fromJson(Map<String, dynamic> json) {
    return ListingOffer(
      id: json['id'] as String,
      title: json['title'] as String,
      originalPrice: (json['originalPrice'] as num).toDouble(),
      dealPrice: (json['dealPrice'] as num).toDouble(),
      currency: (json['currency'] as String?) ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'originalPrice': originalPrice,
      'dealPrice': dealPrice,
      'currency': currency,
    };
  }
}

class TrustSummary {
  const TrustSummary({
    required this.band,
    required this.explanation,
    required this.confidenceScore,
    required this.freshUntilAt,
    required this.recheckAfterAt,
    required this.proofCount,
    required this.recentConfirmations,
    required this.disputeCount,
  });

  final TrustBand band;
  final String explanation;
  final double confidenceScore;
  final DateTime freshUntilAt;
  final DateTime recheckAfterAt;
  final int proofCount;
  final int recentConfirmations;
  final int disputeCount;

  factory TrustSummary.fromJson(Map<String, dynamic> json) {
    return TrustSummary(
      band: trustBandFromApi(json['band'] as String),
      explanation: json['explanation'] as String? ?? '',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0,
      freshUntilAt: DateTime.parse(json['freshUntilAt'] as String),
      recheckAfterAt: DateTime.parse(json['recheckAfterAt'] as String),
      proofCount: (json['proofCount'] as num?)?.toInt() ?? 0,
      recentConfirmations: (json['recentConfirmations'] as num?)?.toInt() ?? 0,
      disputeCount: (json['disputeCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'band': trustBandToApi(band),
      'explanation': explanation,
      'confidenceScore': confidenceScore,
      'freshUntilAt': freshUntilAt.toIso8601String(),
      'recheckAfterAt': recheckAfterAt.toIso8601String(),
      'proofCount': proofCount,
      'recentConfirmations': recentConfirmations,
      'disputeCount': disputeCount,
    };
  }
}

class Deal {
  const Deal({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.title,
    required this.neighborhood,
    required this.distanceMiles,
    required this.rating,
    required this.cuisine,
    required this.valueHook,
    required this.categoryLabel,
    required this.scheduleLabel,
    required this.trustBand,
    required this.freshnessText,
    required this.lastUpdatedAt,
    required this.affordabilityLabel,
    required this.conditions,
    required this.valueNote,
    required this.sourceNote,
    required this.latitude,
    required this.longitude,
    required this.offers,
    required this.description,
    required this.venueAddress,
    required this.confidenceScore,
    required this.freshUntilAt,
    required this.recheckAfterAt,
    required this.proofCount,
    required this.trustSummary,
    required this.tags,
    this.saved = false,
  });

  final String id;
  final String venueId;
  final String venueName;
  final String title;
  final String neighborhood;
  final double distanceMiles;
  final double rating;
  final String cuisine;
  final String valueHook;
  final String categoryLabel;
  final String scheduleLabel;
  final TrustBand trustBand;
  final String freshnessText;
  final DateTime? lastUpdatedAt;
  final String affordabilityLabel;
  final String conditions;
  final String valueNote;
  final String sourceNote;
  final double latitude;
  final double longitude;
  final List<ListingOffer> offers;
  final String description;
  final String venueAddress;
  final double confidenceScore;
  final DateTime freshUntilAt;
  final DateTime recheckAfterAt;
  final int proofCount;
  final TrustSummary trustSummary;
  final List<String> tags;
  final bool saved;

  factory Deal.fromCardJson(Map<String, dynamic> json) {
    final trustBand = trustBandFromApi(json['trustBand'] as String);
    final confidenceScore = (json['confidenceScore'] as num?)?.toDouble() ?? 0;
    final lastUpdatedAt = json['lastUpdatedAt'] as String?;
    return Deal(
      id: json['id'] as String,
      venueId: json['venueId'] as String,
      venueName: json['venueName'] as String,
      title: json['title'] as String,
      neighborhood: json['neighborhood'] as String,
      distanceMiles: (json['distanceMiles'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      cuisine: json['cuisine'] as String? ?? '',
      valueHook: json['title'] as String,
      categoryLabel: json['categoryLabel'] as String? ?? '',
      scheduleLabel: json['scheduleLabel'] as String? ?? '',
      trustBand: trustBand,
      freshnessText: json['freshnessText'] as String? ?? trustBand.label,
      lastUpdatedAt: lastUpdatedAt == null
          ? null
          : DateTime.tryParse(lastUpdatedAt),
      affordabilityLabel: json['affordabilityLabel'] as String? ?? 'Under \$15',
      conditions: '',
      valueNote: json['valueNote'] as String? ?? '',
      sourceNote: '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      offers: const [],
      description: '',
      venueAddress: '',
      confidenceScore: confidenceScore,
      freshUntilAt: DateTime.now(),
      recheckAfterAt: DateTime.now(),
      proofCount: 0,
      trustSummary: TrustSummary(
        band: trustBand,
        explanation: trustBand.explanation,
        confidenceScore: confidenceScore,
        freshUntilAt: DateTime.now(),
        recheckAfterAt: DateTime.now(),
        proofCount: 0,
        recentConfirmations: 0,
        disputeCount: 0,
      ),
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
      saved: json['saved'] as bool? ?? false,
    );
  }

  factory Deal.fromDetailJson(Map<String, dynamic> json) {
    final deal = Deal.fromCardJson(json);
    final trustSummaryJson = json['trustSummary'] as Map<String, dynamic>?;
    return Deal(
      id: deal.id,
      venueId: deal.venueId,
      venueName: deal.venueName,
      title: deal.title,
      neighborhood: deal.neighborhood,
      distanceMiles: deal.distanceMiles,
      rating: deal.rating,
      cuisine: deal.cuisine,
      valueHook: deal.valueHook,
      categoryLabel: deal.categoryLabel,
      scheduleLabel: deal.scheduleLabel,
      trustBand: deal.trustBand,
      freshnessText: deal.freshnessText,
      lastUpdatedAt: deal.lastUpdatedAt,
      affordabilityLabel: deal.affordabilityLabel,
      conditions: json['conditions'] as String? ?? '',
      valueNote: deal.valueNote,
      sourceNote: json['sourceNote'] as String? ?? '',
      latitude: deal.latitude,
      longitude: deal.longitude,
      offers: (json['offers'] as List<dynamic>? ?? const [])
          .map((offer) => ListingOffer.fromJson(offer as Map<String, dynamic>))
          .toList(),
      description: json['description'] as String? ?? '',
      venueAddress: json['venueAddress'] as String? ?? '',
      confidenceScore:
          (json['confidenceScore'] as num?)?.toDouble() ?? deal.confidenceScore,
      freshUntilAt: DateTime.parse(json['freshUntilAt'] as String),
      recheckAfterAt: DateTime.parse(json['recheckAfterAt'] as String),
      proofCount: (json['proofCount'] as num?)?.toInt() ?? 0,
      trustSummary: trustSummaryJson == null
          ? deal.trustSummary
          : TrustSummary.fromJson(trustSummaryJson),
      tags: deal.tags,
      saved: json['saved'] as bool? ?? deal.saved,
    );
  }

  Deal copyWith({
    bool? saved,
    double? confidenceScore,
    TrustBand? trustBand,
    String? freshnessText,
    TrustSummary? trustSummary,
  }) {
    return Deal(
      id: id,
      venueId: venueId,
      venueName: venueName,
      title: title,
      neighborhood: neighborhood,
      distanceMiles: distanceMiles,
      rating: rating,
      cuisine: cuisine,
      valueHook: valueHook,
      categoryLabel: categoryLabel,
      scheduleLabel: scheduleLabel,
      trustBand: trustBand ?? this.trustBand,
      freshnessText: freshnessText ?? this.freshnessText,
      lastUpdatedAt: lastUpdatedAt,
      affordabilityLabel: affordabilityLabel,
      conditions: conditions,
      valueNote: valueNote,
      sourceNote: sourceNote,
      latitude: latitude,
      longitude: longitude,
      offers: offers,
      description: description,
      venueAddress: venueAddress,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      freshUntilAt: freshUntilAt,
      recheckAfterAt: recheckAfterAt,
      proofCount: proofCount,
      trustSummary: trustSummary ?? this.trustSummary,
      tags: tags,
      saved: saved ?? this.saved,
    );
  }

  DealTone get tone => switch (trustBand) {
    TrustBand.founderVerified => DealTone.gold,
    TrustBand.merchantConfirmed => DealTone.mint,
    TrustBand.userConfirmed => DealTone.sky,
    TrustBand.recentlyUpdated => DealTone.lilac,
    TrustBand.needsRecheck => DealTone.peach,
    TrustBand.disputed => DealTone.rose,
  };

  IconData get icon {
    final cuisineValue = cuisine.toLowerCase();
    if (cuisineValue.contains('mex')) {
      return Icons.local_dining_rounded;
    }
    if (cuisineValue.contains('japan') || cuisineValue.contains('ramen')) {
      return Icons.ramen_dining_rounded;
    }
    if (cuisineValue.contains('pizza') || cuisineValue.contains('ital')) {
      return Icons.local_pizza_rounded;
    }
    if (cuisineValue.contains('bar') || tags.contains('drinks')) {
      return Icons.local_bar_rounded;
    }
    return Icons.storefront_rounded;
  }

  String get lastUpdatedText {
    final value = lastUpdatedAt;
    if (value == null) {
      return freshnessText;
    }
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes.clamp(1, 59)} min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hr ago';
    }
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venueId': venueId,
      'venueName': venueName,
      'title': title,
      'neighborhood': neighborhood,
      'distanceMiles': distanceMiles,
      'rating': rating,
      'cuisine': cuisine,
      'valueHook': valueHook,
      'categoryLabel': categoryLabel,
      'scheduleLabel': scheduleLabel,
      'trustBand': trustBandToApi(trustBand),
      'freshnessText': freshnessText,
      'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
      'affordabilityLabel': affordabilityLabel,
      'conditions': conditions,
      'valueNote': valueNote,
      'sourceNote': sourceNote,
      'latitude': latitude,
      'longitude': longitude,
      'offers': offers.map((offer) => offer.toJson()).toList(),
      'description': description,
      'venueAddress': venueAddress,
      'confidenceScore': confidenceScore,
      'freshUntilAt': freshUntilAt.toIso8601String(),
      'recheckAfterAt': recheckAfterAt.toIso8601String(),
      'proofCount': proofCount,
      'trustSummary': trustSummary.toJson(),
      'tags': tags,
      'saved': saved,
    };
  }
}

class FeedSectionModel {
  const FeedSectionModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<Deal> items;

  factory FeedSectionModel.fromJson(Map<String, dynamic> json) {
    return FeedSectionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) => Deal.fromCardJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FeedPayload {
  const FeedPayload({required this.sections, required this.nextCursor});

  final List<FeedSectionModel> sections;
  final String? nextCursor;

  factory FeedPayload.fromJson(Map<String, dynamic> json) {
    return FeedPayload(
      sections: (json['sections'] as List<dynamic>? ?? const [])
          .map(
            (item) => FeedSectionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );
  }
}

class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.neighborhood,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.listingIds,
    required this.tags,
    required this.activeListingCount,
  });

  final String id;
  final String name;
  final String neighborhood;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final List<String> listingIds;
  final List<String> tags;
  final int activeListingCount;

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as String,
      name: json['name'] as String,
      neighborhood: json['neighborhood'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      listingIds: (json['listingIds'] as List<dynamic>? ?? const [])
          .cast<String>(),
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
      activeListingCount: (json['activeListingCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class SearchPayload {
  const SearchPayload({
    required this.listings,
    required this.venues,
    required this.neighborhoods,
    required this.suggestions,
    required this.nextCursor,
  });

  final List<Deal> listings;
  final List<Venue> venues;
  final List<String> neighborhoods;
  final List<String> suggestions;
  final String? nextCursor;

  factory SearchPayload.fromJson(Map<String, dynamic> json) {
    return SearchPayload(
      listings: (json['listings'] as List<dynamic>? ?? const [])
          .map((item) => Deal.fromCardJson(item as Map<String, dynamic>))
          .toList(),
      venues: (json['venues'] as List<dynamic>? ?? const [])
          .map((item) => Venue.fromJson(item as Map<String, dynamic>))
          .toList(),
      neighborhoods: (json['neighborhoods'] as List<dynamic>? ?? const [])
          .cast<String>(),
      suggestions: (json['suggestions'] as List<dynamic>? ?? const [])
          .cast<String>(),
      nextCursor: json['nextCursor'] as String?,
    );
  }
}

class FiltersMetadataModel {
  const FiltersMetadataModel({
    required this.neighborhoods,
    required this.tags,
    required this.cuisines,
    required this.trustBands,
  });

  final List<String> neighborhoods;
  final List<String> tags;
  final List<String> cuisines;
  final List<TrustBand> trustBands;

  factory FiltersMetadataModel.fromJson(Map<String, dynamic> json) {
    return FiltersMetadataModel(
      neighborhoods: (json['neighborhoods'] as List<dynamic>? ?? const [])
          .cast<String>(),
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
      cuisines: (json['cuisines'] as List<dynamic>? ?? const []).cast<String>(),
      trustBands: (json['trustBands'] as List<dynamic>? ?? const [])
          .map((value) => trustBandFromApi(value as String))
          .toList(),
    );
  }
}

class ContributionRecordModel {
  const ContributionRecordModel({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.venueName,
    required this.neighborhood,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.summary,
    required this.pointsDelta,
    required this.pointsStatus,
  });

  final String id;
  final String listingId;
  final String listingTitle;
  final String venueName;
  final String neighborhood;
  final String type;
  final String status;
  final DateTime createdAt;
  final String summary;
  final int pointsDelta;
  final String pointsStatus;

  factory ContributionRecordModel.fromJson(Map<String, dynamic> json) {
    return ContributionRecordModel(
      id: json['id'] as String,
      listingId: json['listingId'] as String,
      listingTitle: json['listingTitle'] as String? ?? '',
      venueName: json['venueName'] as String? ?? '',
      neighborhood: json['neighborhood'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      summary: json['summary'] as String? ?? '',
      pointsDelta: (json['pointsDelta'] as num?)?.toInt() ?? 0,
      pointsStatus: json['pointsStatus'] as String? ?? 'pending',
    );
  }
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.readAt,
    required this.deepLink,
  });

  final String id;
  final String kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? deepLink;

  bool get isUnread => readAt == null;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final readAt = json['readAt'] as String?;
    return NotificationItem(
      id: json['id'] as String,
      kind: json['kind'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: readAt == null ? null : DateTime.tryParse(readAt),
      deepLink: json['deepLink'] as String?,
    );
  }

  NotificationItem copyWith({DateTime? readAt}) {
    return NotificationItem(
      id: id,
      kind: kind,
      title: title,
      body: body,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      deepLink: deepLink,
    );
  }
}

class NotificationsPayload {
  const NotificationsPayload({required this.items, required this.unreadCount});

  final List<NotificationItem> items;
  final int unreadCount;

  factory NotificationsPayload.fromJson(Map<String, dynamic> json) {
    return NotificationsPayload(
      items: (json['items'] as List<dynamic>? ?? const [])
          .map(
            (item) => NotificationItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class PreferencesModel {
  const PreferencesModel({
    required this.contributionResolved,
    required this.pointsFinalized,
    required this.trustStatusChanged,
    required this.marketingAnnouncements,
  });

  final bool contributionResolved;
  final bool pointsFinalized;
  final bool trustStatusChanged;
  final bool marketingAnnouncements;

  factory PreferencesModel.fromJson(Map<String, dynamic> json) {
    return PreferencesModel(
      contributionResolved: json['contributionResolved'] as bool? ?? true,
      pointsFinalized: json['pointsFinalized'] as bool? ?? true,
      trustStatusChanged: json['trustStatusChanged'] as bool? ?? true,
      marketingAnnouncements: json['marketingAnnouncements'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contributionResolved': contributionResolved,
      'pointsFinalized': pointsFinalized,
      'trustStatusChanged': trustStatusChanged,
      'marketingAnnouncements': marketingAnnouncements,
    };
  }
}

class AppProfile {
  const AppProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.homeNeighborhood,
    required this.role,
    required this.verifiedContributor,
  });

  final String id;
  final String email;
  final String displayName;
  final String homeNeighborhood;
  final String role;
  final bool verifiedContributor;

  factory AppProfile.fromJson(Map<String, dynamic> json) {
    return AppProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String? ?? '',
      homeNeighborhood: json['homeNeighborhood'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      verifiedContributor: json['verifiedContributor'] as bool? ?? false,
    );
  }
}

class LeaderboardEntryModel {
  const LeaderboardEntryModel({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.title,
    required this.points,
    required this.verifiedContributor,
  });

  final int rank;
  final String userId;
  final String displayName;
  final String title;
  final int points;
  final bool verifiedContributor;

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      verifiedContributor: json['verifiedContributor'] as bool? ?? false,
    );
  }
}

class BadgeModel {
  const BadgeModel({
    required this.code,
    required this.title,
    required this.description,
    required this.unlocked,
  });

  final String code;
  final String title;
  final String description;
  final bool unlocked;

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      unlocked: json['unlocked'] as bool? ?? false,
    );
  }
}

class KarmaSnapshot {
  const KarmaSnapshot({
    required this.userId,
    required this.points,
    required this.pendingPoints,
    required this.verifiedContributor,
    required this.currentStreakDays,
    required this.level,
    required this.nextLevelPoints,
    required this.impactUsersHelped,
    required this.approvedContributions,
    required this.pendingContributions,
    required this.badges,
    required this.leaderboardWindow,
    required this.leaderboard,
  });

  final String userId;
  final int points;
  final int pendingPoints;
  final bool verifiedContributor;
  final int currentStreakDays;
  final String level;
  final int nextLevelPoints;
  final int impactUsersHelped;
  final int approvedContributions;
  final int pendingContributions;
  final List<BadgeModel> badges;
  final String leaderboardWindow;
  final List<LeaderboardEntryModel> leaderboard;

  factory KarmaSnapshot.fromJson(Map<String, dynamic> json) {
    return KarmaSnapshot(
      userId: json['userId'] as String? ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      pendingPoints: (json['pendingPoints'] as num?)?.toInt() ?? 0,
      verifiedContributor: json['verifiedContributor'] as bool? ?? false,
      currentStreakDays: (json['currentStreakDays'] as num?)?.toInt() ?? 0,
      level: json['level'] as String? ?? 'Newcomer',
      nextLevelPoints: (json['nextLevelPoints'] as num?)?.toInt() ?? 0,
      impactUsersHelped: (json['impactUsersHelped'] as num?)?.toInt() ?? 0,
      approvedContributions:
          (json['approvedContributions'] as num?)?.toInt() ?? 0,
      pendingContributions:
          (json['pendingContributions'] as num?)?.toInt() ?? 0,
      badges: (json['badges'] as List<dynamic>? ?? const [])
          .map((badge) => BadgeModel.fromJson(badge as Map<String, dynamic>))
          .toList(),
      leaderboardWindow: json['leaderboardWindow'] as String? ?? 'weekly',
      leaderboard: (json['leaderboard'] as List<dynamic>? ?? const [])
          .map(
            (entry) =>
                LeaderboardEntryModel.fromJson(entry as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class AuthSessionModel {
  const AuthSessionModel({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    required this.verifiedContributor,
  });

  final String userId;
  final String email;
  final String displayName;
  final String role;
  final bool verifiedContributor;

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
      verifiedContributor: json['verifiedContributor'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'role': role,
      'verifiedContributor': verifiedContributor,
    };
  }
}

class AuthPayload {
  const AuthPayload({required this.session, required this.profile});

  final AuthSessionModel session;
  final AppProfile profile;

  factory AuthPayload.fromJson(Map<String, dynamic> json) {
    return AuthPayload(
      session: AuthSessionModel.fromJson(
        json['session'] as Map<String, dynamic>,
      ),
      profile: AppProfile.fromJson(json['profile'] as Map<String, dynamic>),
    );
  }
}

class MapDeal {
  const MapDeal({
    required this.listingId,
    required this.venueId,
    required this.venueName,
    required this.latitude,
    required this.longitude,
    required this.trustBand,
    required this.title,
    required this.neighborhood,
    required this.confidenceScore,
    required this.affordabilityLabel,
    required this.saved,
  });

  final String listingId;
  final String venueId;
  final String venueName;
  final double latitude;
  final double longitude;
  final TrustBand trustBand;
  final String title;
  final String neighborhood;
  final double confidenceScore;
  final String affordabilityLabel;
  final bool saved;

  factory MapDeal.fromJson(Map<String, dynamic> json) {
    return MapDeal(
      listingId: json['listingId'] as String,
      venueId: json['venueId'] as String,
      venueName: json['venueName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      trustBand: trustBandFromApi(json['trustBand'] as String),
      title: json['title'] as String,
      neighborhood: json['neighborhood'] as String? ?? '',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0,
      affordabilityLabel: json['affordabilityLabel'] as String? ?? 'Under \$15',
      saved: json['saved'] as bool? ?? false,
    );
  }
}

class OfflineMutation {
  const OfflineMutation({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
    this.actorUserId,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final String? actorUserId;

  factory OfflineMutation.fromJson(Map<String, dynamic> json) {
    return OfflineMutation(
      id: json['id'] as String,
      type: json['type'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      actorUserId: json['actorUserId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'actorUserId': actorUserId,
    };
  }
}

String encodeJsonList(List<Map<String, dynamic>> values) => jsonEncode(values);
