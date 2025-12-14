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

/// Provider to track when drinking records are updated
/// Used to trigger refreshes of dependent providers
final drinkingRecordsLastUpdatedProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

/// Provider for fetching records for a specific month
/// Returns a list of drinking records for the given month
/// Updates when drinkingRecordsLastUpdatedProvider changes
final monthRecordsProvider = FutureProvider.autoDispose
    .family<List<DrinkingRecord>, DateTime>((ref, date) {
      ref.watch(drinkingRecordsLastUpdatedProvider);
      final service = ref.watch(drinkingRecordServiceProvider);
      return service.getRecordsByMonth(date.year, date.month);
    });
