import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Badge extends Equatable {
  const Badge({
    required this.group,
    required this.idx,
    required this.achievedDay,
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

  Map<String, dynamic> toJson() {
    return {
      'group': group,
      'idx': idx,
      'achievedDay': achievedDay.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [group, idx, achievedDay];
}
