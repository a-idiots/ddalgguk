import 'package:flutter/material.dart';
import 'package:ddalgguk/features/profile/presentation/transitions/profile_transition_data.dart';
import 'package:ddalgguk/features/profile/presentation/transitions/profile_transition_builder.dart';
import 'package:ddalgguk/features/profile/presentation/profile_detail_screen.dart';

/// Custom PageRoute that allows drag-controlled transition
class DragTransitionRoute extends PageRoute<void> {
  DragTransitionRoute({
    required this.transitionData,
  });

  final ProfileTransitionData transitionData;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return ProfileTransitionBuilder(
      animation: animation,
      transitionData: transitionData,
      child: const ProfileDetailScreen(),
    );
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // The transition is handled by ProfileTransitionBuilder
    // which is already in buildPage, so we just return the child
    return child;
  }
}

/// Controller for manual drag-based navigation
class DragNavigationController {
  DragNavigationController({
    required this.context,
    required this.transitionData,
  });

  final BuildContext context;
  final ProfileTransitionData transitionData;

  double _dragDistance = 0;
  bool _isDragging = false;
  bool _isNavigating = false;

  bool get isDragging => _isDragging;
  double get dragProgress {
    if (!_isDragging) {
      return 0;
    }
    final screenHeight = MediaQuery.of(context).size.height;
    return (_dragDistance / (screenHeight * 0.5)).clamp(0.0, 1.0);
  }

  void handleDragStart(DragStartDetails details) {
    if (_isNavigating) {
      return;
    }
    _isDragging = true;
    _dragDistance = 0;
  }

  void handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _isNavigating) {
      return;
    }

    // Only track upward drag (negative delta.dy)
    if (details.delta.dy < 0) {
      _dragDistance += details.delta.dy.abs();
    } else {
      // Reduce distance when dragging down
      _dragDistance = (_dragDistance + details.delta.dy).clamp(0.0, double.infinity);
    }
  }

  Future<void> handleDragEnd(DragEndDetails details) async {
    if (!_isDragging || _isNavigating) {
      return;
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final threshold = screenHeight * 0.25; // 25% of screen height
    final velocity = details.velocity.pixelsPerSecond.dy;

    // Check if should complete transition
    final shouldComplete = _dragDistance > threshold || velocity < -500;

    if (shouldComplete) {
      _isNavigating = true;
      await Navigator.of(context).push(
        DragTransitionRoute(transitionData: transitionData),
      );
      _isNavigating = false;
    }

    _isDragging = false;
    _dragDistance = 0;
  }
}
