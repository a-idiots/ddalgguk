import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/features/calendar/data/providers/calendar_providers.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';

/// Provider for filtered drinking records (amount > 0) for analytics
/// Used in SpendingTab and RecapTab to exclude zero-amount records
final analyticsMonthRecordsProvider = FutureProvider.autoDispose
    .family<List<DrinkingRecord>, DateTime>((ref, date) async {
      final records = await ref.watch(monthRecordsProvider(date).future);
      return records.where((record) {
        if (record.drinkAmount.isEmpty) {
          return false;
        }
        final totalAmount = record.drinkAmount.fold(
          0.0,
          (sum, item) => sum + item.amount,
        );
        return totalAmount > 0;
      }).toList();
    });
