import 'package:equatable/equatable.dart';

class Badge extends Equatable {
  final String group; // 'drinking' or 'sobriety'
  final int idx;
  final DateTime achievedDay;

  const Badge({
    required this.group,
    required this.idx,
    required this.achievedDay,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      group: json['group'] as String,
      idx: json['idx'] as int,
      achievedDay: DateTime.parse(json['achievedDay'] as String),
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
  List<Object?> get props => [group, idx, achievedDay];
}
