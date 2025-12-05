import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:flutter/widgets.dart';

class AlcoholCalculationResult {
  const AlcoholCalculationResult({
    required this.currentAlcoholRemaining,
    required this.timeToSober,
    required this.progressPercentage,
    required this.statusMessage,
    required this.estimatedSoberTime,
    this.lastDrinkTime,
  });

  final double currentAlcoholRemaining;
  final double timeToSober;
  final double progressPercentage;
  final String statusMessage;
  final DateTime estimatedSoberTime;
  final DateTime? lastDrinkTime;
}

class AlcoholCalculator {
  static AlcoholCalculationResult calculate({
    required Map<String, dynamic>? userInfo,
    required List<DrinkingRecord> records,
    required DateTime now,
    required DateTime today,
  }) {
    // 1. Determine Metabolism Rate
    double weight = 70.0; // Default weight
    double height = 175.0; // Default height
    double age = 25.0; // Default age

    if (userInfo != null && userInfo['weight'] != null) {
      weight = (userInfo['weight'] as num).toDouble();
    }
    if (userInfo != null && userInfo['height'] != null) {
      height = (userInfo['height'] as num).toDouble();
    }
    if (userInfo != null && userInfo['age'] != null) {
      age = (userInfo['age'] as num).toDouble();
    }

    final tbw = (userInfo != null && userInfo['gender'] != null)
        ? (userInfo['gender'] == 'male')
              ? 2.447 - 0.09516 * age + 0.1074 * height + 0.3362 * weight
              : -2.097 + 0.1069 * height + 0.2466 * weight
        : 0.55 * weight + 4.9 * height - 4.7 * age;

    final beta = 0.015;

    // 2. Get records for today, yesterday, and day before
    final threeDaysAgo = today.subtract(const Duration(days: 2));
    final recentRecords = records.where((r) {
      return r.date.isAfter(threeDaysAgo) ||
          _getDateKey(r.date) == _getDateKey(threeDaysAgo);
    }).toList();

    // Sort by date ascending
    recentRecords.sort((a, b) => a.date.compareTo(b.date));

    // 3. Simulate Alcohol Metabolism
    double currentAlcoholRemaining = 0.0;

    if (recentRecords.isNotEmpty) {
      for (final record in recentRecords) {
        // Calculate time passed since last update
        final recordedTime = DateTime(
          record.date.year,
          record.date.month,
          record.date.day,
          21, // 9 PM
        );

        final duration = now.difference(recordedTime);
        final hoursPassed = duration.inMinutes / 60.0;

        // Add new alcohol from this record
        double recordAlcoholGrams = 0;
        for (final drink in record.drinkAmount) {
          debugPrint('drink: ${drink.amount} ${drink.alcoholContent}');
          recordAlcoholGrams += drink.amount * (drink.alcoholContent / 100);
        }
        debugPrint('recordAlcoholGrams: $recordAlcoholGrams');
        currentAlcoholRemaining +=
            ((recordAlcoholGrams / (tbw * 10)) * 0.7894 * 0.7 -
                    beta * hoursPassed)
                .clamp(0.0, double.infinity);
        debugPrint('currentAlcoholRemaining: $currentAlcoholRemaining');
      }
    }

    // 4. Calculate Derived Stats
    final timeToSober = currentAlcoholRemaining / beta;

    // Progress percentage based on current remaining vs total consumed (in recent period)
    // If fully sober, progress is 100% (or 0% remaining)
    // We want progress of "recovery". 100% means fully recovered.
    final progressPercentage = currentAlcoholRemaining > 0
        ? (100.0 - (currentAlcoholRemaining / 0.3) * 100).clamp(0.0, 100.0)
        : 100.0; // If no alcohol, 100% recovered

    debugPrint('progressPercentage: $progressPercentage');

    // Generate status message
    String statusMessage;
    if (currentAlcoholRemaining <= 0) {
      statusMessage = '깨끗한 상태입니다! 이미 모든 알콜이 분해되었어요 ☘';
    } else if (timeToSober < 1) {
      statusMessage = '곧 회복될 거예요! 조금만 더 기다리세요 ⏰';
    } else if (timeToSober < 3) {
      statusMessage = '${timeToSober.toStringAsFixed(1)}시간 후면 완전히 깰 거예요 🌱';
    } else {
      statusMessage =
          '아직 ${timeToSober.toStringAsFixed(1)}시간이 필요해요. 충분히 쉬세요 💤';
    }

    return AlcoholCalculationResult(
      currentAlcoholRemaining: currentAlcoholRemaining,
      timeToSober: timeToSober,
      progressPercentage: progressPercentage,
      statusMessage: statusMessage,
      estimatedSoberTime: now.add(
        Duration(minutes: (timeToSober * 60).round()),
      ),
      lastDrinkTime: recentRecords.isNotEmpty ? recentRecords.last.date : now,
    );
  }

  /// Helper to get date key for grouping
  static String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
