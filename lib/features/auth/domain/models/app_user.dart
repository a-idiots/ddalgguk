import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ddalgguk/core/constants/storage_keys.dart';
import 'package:ddalgguk/features/auth/domain/models/badge.dart';
import 'package:ddalgguk/features/social/domain/models/daily_status.dart';

/// Application user model
class AppUser {
  const AppUser({
    required this.uid,
    required this.provider,
    this.photoURL,
    this.hasCompletedProfileSetup = false,
    this.id,
    this.name,
    this.goal,
    this.favoriteDrink,
    this.maxAlcohol,
    this.weeklyDrinkingFrequency,
    this.coefficient,
    this.currentDrunkLevel,
    this.weeklyDrunkLevels,
    this.lastDrinkDate,
    this.dailyStatus,
    this.badges = const [],
    this.pinnedBadges = const [],
    this.stats = const {},
    this.gender,
    this.birthDate,
    this.height,
    this.weight,
  });

  /// Create AppUser from Firebase User
  factory AppUser.fromFirebaseUser({
    required String uid,
    required String? photoURL,
    required LoginProvider provider,
  }) {
    return AppUser(uid: uid, photoURL: photoURL, provider: provider);
  }

  /// Create AppUser from JSON (Firestore)
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      provider: LoginProvider.fromString(json['provider'] as String?) ??
          LoginProvider.google,
      photoURL: json['photoURL'] as String?,
      hasCompletedProfileSetup:
          json['hasCompletedProfileSetup'] as bool? ?? false,
      id: json['id'] as String?,
      name: json['name'] as String?,
      maxAlcohol: json['maxAlcohol'] != null
          ? (json['maxAlcohol'] as num).toDouble()
          : null,
      goal: json['goal'] as bool?,
      weeklyDrinkingFrequency: json['weeklyDrinkingFrequency'] as int?,
      favoriteDrink: _parseFavoriteDrink(json['favoriteDrink']),
      coefficient: json['coefficient'] != null
          ? (json['coefficient'] as num).toDouble()
          : null,
      currentDrunkLevel: json['currentDrunkLevel'] as int?,
      weeklyDrunkLevels: json['weeklyDrunkLevels'] != null
          ? List<int>.from(json['weeklyDrunkLevels'] as List)
          : null,
      lastDrinkDate: json['lastDrinkDate'] != null
          ? (json['lastDrinkDate'] as Timestamp).toDate()
          : null,
      dailyStatus: json['dailyStatus'] != null
          ? DailyStatus.fromFirestore(
              json['dailyStatus'] as Map<String, dynamic>,
            )
          : null,
      badges: json['badge'] != null
          ? (json['badge'] as List)
              .map((e) => Badge.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      pinnedBadges: json['pinnedBadges'] != null
          ? List<String>.from(json['pinnedBadges'] as List)
          : const [],
      stats: json['stats'] != null
          ? Map<String, dynamic>.from(json['stats'] as Map)
          : const {},
      gender: json['gender'] as String?,
      birthDate: json['birthDate'] != null
          ? (json['birthDate'] is Timestamp
              ? (json['birthDate'] as Timestamp).toDate()
              : DateTime.tryParse(json['birthDate'].toString()))
          : null,
      height:
          json['height'] != null ? (json['height'] as num).toDouble() : null,
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : null,
    );
  }

  // Stats (Basic user info)
  final String uid;
  final LoginProvider provider;
  final String? photoURL;
  final bool hasCompletedProfileSetup;
  final String? id;
  final String? name;

  // Health Info
  final double? maxAlcohol; // 주량 (소주 병 수)
  final bool? goal; // true=즐거운 음주, false=건강한 금주
  final int? weeklyDrinkingFrequency; // 일주일에 술을 마시는 횟수
  final int? favoriteDrink; // 0=소주, 1=맥주, 2=와인, 3=기타
  final double? coefficient; // 계산된 계수 (추후 프론트에서 계산)

  // Recent Drink Info
  final int? currentDrunkLevel; // 현재 술 레벨 (0-10)
  final List<int>?
      weeklyDrunkLevels; // 최근 7일 술 레벨 (-1: 기록없음, 0: 금주, 1-100: 음주레벨)
  final DateTime? lastDrinkDate; // 마지막 음주 날짜

  // Daily Status
  final DailyStatus? dailyStatus;

  // Badges
  final List<Badge> badges; // all badges
  final List<String> pinnedBadges; // pinned badge IDs

  // Stats
  final Map<String, dynamic> stats;

  // Physical Info
  final String? gender; // 'male', 'female'
  final DateTime? birthDate;
  final double? height;
  final double? weight;

  /// Parse favoriteDrink from JSON - handles both int and List formats
  static int? _parseFavoriteDrink(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is List && value.isNotEmpty) {
      return value.first as int;
    }
    return null;
  }

  /// Convert AppUser to JSON (for cache and Firestore)
  /// Dates are stored as ISO 8601 strings for JSON compatibility
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'provider': provider.value,
      'photoURL': photoURL,
      'hasCompletedProfileSetup': hasCompletedProfileSetup,
      'id': id,
      'name': name,
      'maxAlcohol': maxAlcohol,
      'goal': goal,
      'weeklyDrinkingFrequency': weeklyDrinkingFrequency,
      'favoriteDrink': favoriteDrink,
      'coefficient': coefficient,
      'currentDrunkLevel': currentDrunkLevel,
      'weeklyDrunkLevels': weeklyDrunkLevels,
      'lastDrinkDate': lastDrinkDate?.toIso8601String(),
      'dailyStatus': dailyStatus?.toMap(),
      'badge': badges.map((e) => e.toJson()).toList(),
      'pinnedBadges': pinnedBadges,
      'stats': stats,
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'height': height,
      'weight': weight,
    };
  }

  /// Convert AppUser to Firestore format with Timestamps
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    // Convert date strings to Firestore Timestamps
    if (birthDate != null) {
      json['birthDate'] = Timestamp.fromDate(birthDate!);
    }
    if (lastDrinkDate != null) {
      json['lastDrinkDate'] = Timestamp.fromDate(lastDrinkDate!);
    }
    return json;
  }

  /// Create a copy with updated fields
  AppUser copyWith({
    String? uid,
    LoginProvider? provider,
    String? photoURL,
    bool? hasCompletedProfileSetup,
    String? id,
    String? name,
    double? maxAlcohol,
    bool? goal,
    int? weeklyDrinkingFrequency,
    int? favoriteDrink,
    double? coefficient,
    int? currentDrunkLevel,
    List<int>? weeklyDrunkLevels,
    DateTime? lastDrinkDate,
    DailyStatus? dailyStatus,
    List<Badge>? badges,
    List<String>? pinnedBadges,
    Map<String, dynamic>? stats,
    String? gender,
    DateTime? birthDate,
    double? height,
    double? weight,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      provider: provider ?? this.provider,
      photoURL: photoURL ?? this.photoURL,
      hasCompletedProfileSetup:
          hasCompletedProfileSetup ?? this.hasCompletedProfileSetup,
      id: id ?? this.id,
      name: name ?? this.name,
      maxAlcohol: maxAlcohol ?? this.maxAlcohol,
      goal: goal ?? this.goal,
      weeklyDrinkingFrequency:
          weeklyDrinkingFrequency ?? this.weeklyDrinkingFrequency,
      favoriteDrink: favoriteDrink ?? this.favoriteDrink,
      coefficient: coefficient ?? this.coefficient,
      currentDrunkLevel: currentDrunkLevel ?? this.currentDrunkLevel,
      weeklyDrunkLevels: weeklyDrunkLevels ?? this.weeklyDrunkLevels,
      lastDrinkDate: lastDrinkDate ?? this.lastDrinkDate,
      dailyStatus: dailyStatus ?? this.dailyStatus,
      badges: badges ?? this.badges,
      pinnedBadges: pinnedBadges ?? this.pinnedBadges,
      stats: stats ?? this.stats,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      height: height ?? this.height,
      weight: weight ?? this.weight,
    );
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, provider: ${provider.value}, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AppUser &&
        other.uid == uid &&
        other.provider == provider &&
        other.photoURL == photoURL &&
        other.hasCompletedProfileSetup == hasCompletedProfileSetup &&
        other.id == id &&
        other.name == name &&
        other.height == height &&
        other.weight == weight &&
        other.maxAlcohol == maxAlcohol &&
        other.goal == goal &&
        other.weeklyDrinkingFrequency == weeklyDrinkingFrequency &&
        other.favoriteDrink == favoriteDrink &&
        other.coefficient == coefficient &&
        other.currentDrunkLevel == currentDrunkLevel &&
        _listEquals(other.weeklyDrunkLevels, weeklyDrunkLevels) &&
        other.lastDrinkDate == lastDrinkDate &&
        other.dailyStatus == dailyStatus &&
        _listEquals(other.badges, badges) &&
        _listEquals(other.pinnedBadges, pinnedBadges) &&
        other.stats.toString() == stats.toString() &&
        other.gender == gender &&
        other.birthDate == birthDate &&
        other.height == height &&
        other.weight == weight;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        provider.hashCode ^
        photoURL.hashCode ^
        hasCompletedProfileSetup.hashCode ^
        id.hashCode ^
        name.hashCode ^
        height.hashCode ^
        weight.hashCode ^
        maxAlcohol.hashCode ^
        goal.hashCode ^
        weeklyDrinkingFrequency.hashCode ^
        favoriteDrink.hashCode ^
        coefficient.hashCode ^
        currentDrunkLevel.hashCode ^
        weeklyDrunkLevels.hashCode ^
        lastDrinkDate.hashCode ^
        dailyStatus.hashCode ^
        badges.hashCode ^
        pinnedBadges.hashCode ^
        stats.hashCode ^
        gender.hashCode ^
        birthDate.hashCode ^
        height.hashCode ^
        weight.hashCode;
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
