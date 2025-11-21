import 'package:ddalgguk/features/calendar/data/services/drinking_record_service.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Export the service for use in other modules
export 'package:ddalgguk/features/calendar/data/services/drinking_record_service.dart';

/// Provider for DrinkingRecordService
/// This is the central provider for accessing drinking record data throughout the app
final drinkingRecordServiceProvider = Provider<DrinkingRecordService>((ref) {
  return DrinkingRecordService();
});

/// Provider for streaming records for a specific month
/// Returns a stream of drinking records for the given month
final monthRecordsProvider =
    StreamProvider.autoDispose.family<List<DrinkingRecord>, DateTime>((ref, date) {
      final service = ref.watch(drinkingRecordServiceProvider);
      return service.streamRecordsByMonth(date.year, date.month);
    });
