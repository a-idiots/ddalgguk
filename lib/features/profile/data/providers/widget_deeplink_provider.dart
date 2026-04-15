import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pending widget deep-link action. Non-null means a home-screen widget tap
/// is waiting to be processed by [MainNavigation]. The consumer should
/// immediately reset it to `null` after handling.
///
/// Currently only `'goal'` is emitted (tap on the 음주 목표 widget).
final widgetDeepLinkProvider = StateProvider<String?>((ref) => null);
