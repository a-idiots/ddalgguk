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
    this.dailyStatus,
    this.badges = const [],
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
      provider:
          LoginProvider.fromString(json['provider'] as String?) ??
          LoginProvider.google,
      photoURL: json['photoURL'] as String?,
      hasCompletedProfileSetup:
          json['hasCompletedProfileSetup'] as bool? ?? false,
      id: json['id'] as String?,
      name: json['name'] as String?,
      goal: json['goal'] as bool?,
      favoriteDrink: _parseFavoriteDrink(json['favoriteDrink']),
      maxAlcohol: json['maxAlcohol'] != null
          ? (json['maxAlcohol'] as num).toDouble()
          : null,
      weeklyDrinkingFrequency: json['weeklyDrinkingFrequency'] as int?,
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
      stats: json['stats'] != null
          ? Map<String, dynamic>.from(json['stats'] as Map)
          : const {},
      gender: json['gender'] as String?,
      birthDate: json['birthDate'] != null
          ? (json['birthDate'] is Timestamp
                ? (json['birthDate'] as Timestamp).toDate()
                : DateTime.tryParse(json['birthDate'].toString()))
          : null,
      height: json['height'] != null
          ? (json['height'] as num).toDouble()
          : null,
      weight: json['weight'] != null
          ? (json['weight'] as num).toDouble()
          : null,
    );
  }

  final String uid;
  final LoginProvider provider;
  final String? photoURL;
  final bool hasCompletedProfileSetup;

  // Basic Info
  final String? id;
  final String? name;
  final bool? goal; // true=즐거운 음주, false=건강한 금주
  final int? favoriteDrink; // 0=소주, 1=맥주, 2=와인, 3=기타
  final double? maxAlcohol;
  final int? weeklyDrinkingFrequency; // 일주일에 술을 마시는 횟수

  // Memo/Status
  final DailyStatus? dailyStatus;

  // Achievements
  final List<Badge> badges;

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

  /// Convert AppUser to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'provider': provider.value,
      'photoURL': photoURL,
      'hasCompletedProfileSetup': hasCompletedProfileSetup,
      'id': id,
      'name': name,
      'goal': goal,
      'favoriteDrink': favoriteDrink,
      'maxAlcohol': maxAlcohol,
      'weeklyDrinkingFrequency': weeklyDrinkingFrequency,
      'dailyStatus': dailyStatus?.toMap(),
      'badge': badges.map((e) => e.toJson()).toList(),
      'stats': stats,
      'gender': gender,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'height': height,
      'weight': weight,
    };
  }

  /// Create a copy with updated fields
  AppUser copyWith({
    String? uid,
    LoginProvider? provider,
    String? photoURL,
    bool? hasCompletedProfileSetup,
    String? id,
    String? name,
    bool? goal,
    int? favoriteDrink,
    double? maxAlcohol,
    int? weeklyDrinkingFrequency,
    DailyStatus? dailyStatus,
    List<Badge>? badges,
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
      goal: goal ?? this.goal,
      favoriteDrink: favoriteDrink ?? this.favoriteDrink,
      maxAlcohol: maxAlcohol ?? this.maxAlcohol,
      weeklyDrinkingFrequency:
          weeklyDrinkingFrequency ?? this.weeklyDrinkingFrequency,
      dailyStatus: dailyStatus ?? this.dailyStatus,
      badges: badges ?? this.badges,
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
        other.goal == goal &&
        other.favoriteDrink == favoriteDrink &&
        other.maxAlcohol == maxAlcohol &&
        other.weeklyDrinkingFrequency == weeklyDrinkingFrequency &&
        other.dailyStatus == dailyStatus &&
        _listEquals(other.badges, badges) &&
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
        goal.hashCode ^
        favoriteDrink.hashCode ^
        maxAlcohol.hashCode ^
        weeklyDrinkingFrequency.hashCode ^
        dailyStatus.hashCode ^
        badges.hashCode ^
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
