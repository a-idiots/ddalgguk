import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppReviewService {
  InAppReviewService._();

  static const String _recordCountKey = 'total_record_count';
  static const List<int> _triggerCounts = [1, 5];

  /// Call after a drinking record is successfully saved.
  static Future<void> onRecordCreated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = (prefs.getInt(_recordCountKey) ?? 0) + 1;
      await prefs.setInt(_recordCountKey, count);

      if (_triggerCounts.contains(count)) {
        final inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          await inAppReview.requestReview();
        }
      }
    } catch (e) {
      debugPrint('InAppReviewService error: $e');
    }
  }
}
