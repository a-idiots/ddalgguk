import 'package:ddalgguk/core/constants/storage_keys.dart';

/// Application user model
class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    required this.provider,
    required this.createdAt,
    this.lastLoginAt,
    this.id,
    this.name,
    this.goal,
    this.favoriteDrink,
    this.maxAlcohol,
    this.hasCompletedProfileSetup = false,
  });

  /// Create AppUser from Firebase User
  factory AppUser.fromFirebaseUser({
    required String uid,
    required String? email,
    required String? displayName,
    required String? photoURL,
    required LoginProvider provider,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      provider: provider,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }

  /// Create AppUser from JSON (Firestore)
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      provider: LoginProvider.fromString(json['provider'] as String?) ??
          LoginProvider.google,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      id: json['id'] as String?,
      name: json['name'] as String?,
      goal: json['goal'] as bool?,
      favoriteDrink: json['favoriteDrink'] != null
          ? List<int>.from(json['favoriteDrink'] as List)
          : null,
      maxAlcohol: json['maxAlcohol'] != null
          ? (json['maxAlcohol'] as num).toDouble()
          : null,
      hasCompletedProfileSetup:
          json['hasCompletedProfileSetup'] as bool? ?? false,
    );
  }

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final LoginProvider provider;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  // Profile setup fields
  final String? id; // User ID (Instagram-like username)
  final String? name; // User's name
  final bool? goal; // true = 즐거운 음주 (enjoyable drinking), false = 건강한 금주 (healthy abstinence)
  final List<int>? favoriteDrink; // 0=소주, 1=맥주, 2=와인, 3=기타
  final double? maxAlcohol; // Maximum alcohol consumption
  final bool hasCompletedProfileSetup; // Whether profile setup is completed

  /// Convert AppUser to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'provider': provider.value,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'id': id,
      'name': name,
      'goal': goal,
      'favoriteDrink': favoriteDrink,
      'maxAlcohol': maxAlcohol,
      'hasCompletedProfileSetup': hasCompletedProfileSetup,
    };
  }

  /// Create a copy with updated fields
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    LoginProvider? provider,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? id,
    String? name,
    bool? goal,
    List<int>? favoriteDrink,
    double? maxAlcohol,
    bool? hasCompletedProfileSetup,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      id: id ?? this.id,
      name: name ?? this.name,
      goal: goal ?? this.goal,
      favoriteDrink: favoriteDrink ?? this.favoriteDrink,
      maxAlcohol: maxAlcohol ?? this.maxAlcohol,
      hasCompletedProfileSetup:
          hasCompletedProfileSetup ?? this.hasCompletedProfileSetup,
    );
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, displayName: $displayName, provider: ${provider.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AppUser &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoURL == photoURL &&
        other.provider == provider &&
        other.createdAt == createdAt &&
        other.lastLoginAt == lastLoginAt &&
        other.id == id &&
        other.name == name &&
        other.goal == goal &&
        _listEquals(other.favoriteDrink, favoriteDrink) &&
        other.maxAlcohol == maxAlcohol &&
        other.hasCompletedProfileSetup == hasCompletedProfileSetup;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        photoURL.hashCode ^
        provider.hashCode ^
        createdAt.hashCode ^
        lastLoginAt.hashCode ^
        id.hashCode ^
        name.hashCode ^
        goal.hashCode ^
        favoriteDrink.hashCode ^
        maxAlcohol.hashCode ^
        hasCompletedProfileSetup.hashCode;
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
