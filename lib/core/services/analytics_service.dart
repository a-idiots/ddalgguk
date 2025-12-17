import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._internal();

  static final AnalyticsService _instance = AnalyticsService._internal();
  static AnalyticsService get instance => _instance;

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Generic helper to log events safely
  Future<void> _logEvent(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      debugPrint('Analytics: $name $parameters');
    } catch (e) {
      debugPrint('Analytics Error ($name): $e');
    }
  }

  // --- 1. Onboarding ---

  Future<void> logLoginStart(String method) async {
    await _logEvent('login_start', {'method': method});
  }

  Future<void> logLoginSuccess(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUpSuccess(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logProfileSetupComplete() async {
    await _logEvent('profile_setup_complete');
  }

  // --- 2. Calendar ---

  Future<void> logDrinkRecordStart() async {
    await _logEvent('drink_record_start');
  }

  Future<void> logDrinkRecordComplete({required String type}) async {
    // type: 'drink' or 'sober'
    await _logEvent('drink_record_complete', {'type': type});
  }

  Future<void> logDrinkRecordCancel() async {
    await _logEvent('drink_record_cancel');
  }

  // --- 3. Friends ---

  Future<void> logSendFriendRequest() async {
    await _logEvent('send_friend_request');
  }

  Future<void> logUpdateStatusMessage() async {
    await _logEvent('update_status_message');
  }

  // --- 4. Report ---

  Future<void> logViewReportTab(String tabName) async {
    // tabName: 'alcohol', 'spending', 'recap'
    await _logEvent('view_report_tab', {'tab_name': tabName});
  }

  Future<void> logDownloadReport() async {
    await _logEvent('download_report');
  }

  Future<void> logShareReport(String method) async {
    // method: 'instagram', 'system'
    await _logEvent('share_report', {'method': method});
  }

  // --- 5. Settings ---

  Future<void> logDeleteAccount({String? reason}) async {
    await _logEvent('delete_account', {'reason': reason ?? 'unknown'});
  }

  Future<void> logUpdateProfile() async {
    await _logEvent('update_profile');
  }
}
