import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Badge extends Equatable {
  const Badge({
    required this.group,
    required this.idx,
    required this.achievedDay,
    this.isPinned = false,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      group: json['group'] as String,
      idx: json['idx'] as int,
      achievedDay: (json['achievedDay'] as Timestamp).toDate(),
    );
  }

  final String group; // 'drinking' or 'sobriety'
  final int idx;
  final DateTime achievedDay;
  final bool isPinned;

  String get id => '${group}_${idx}';

  Badge copyWith({
    String? group,
    int? idx,
    DateTime? achievedDay,
    bool? isPinned,
  }) {
    return Badge(
      group: group ?? this.group,
      idx: idx ?? this.idx,
      achievedDay: achievedDay ?? this.achievedDay,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group': group,
      'idx': idx,
      'achievedDay': achievedDay.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [group, idx, achievedDay, isPinned];
}
