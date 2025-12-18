import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App state for managing navigation flow
class AppState {
  const AppState({
    this.splashAnimationCompleted = false,
    this.justLoggedIn = false,
  });

  /// Whether the splash screen animation has completed
  final bool splashAnimationCompleted;

  /// Whether the user just logged in (to skip splash screen)
  final bool justLoggedIn;

  AppState copyWith({bool? splashAnimationCompleted, bool? justLoggedIn}) {
    return AppState(
      splashAnimationCompleted:
          splashAnimationCompleted ?? this.splashAnimationCompleted,
      justLoggedIn: justLoggedIn ?? this.justLoggedIn,
    );
  }
}

/// Provider for app state
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState());

  void setSplashAnimationCompleted() {
    state = state.copyWith(splashAnimationCompleted: true);
  }

  void setJustLoggedIn(bool value) {
    state = state.copyWith(justLoggedIn: value);
  }

  void reset() {
    state = const AppState();
  }
}

/// App state provider
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>(
  (ref) => AppStateNotifier(),
);
