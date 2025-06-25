import 'package:flutter/material.dart';

/// A utility class to safely handle ScrollController operations
/// and prevent "ScrollController not attached to any scroll views" errors
class SafeScrollController {
  /// Safely perform an action if the controller is attached
  static void withController(
    ScrollController controller,
    Function(ScrollController) action,
  ) {
    if (controller.hasClients) {
      action(controller);
    }
  }

  /// Safely get a value from the controller, or return a default value if not attached
  static T getValue<T>(
    ScrollController controller,
    T Function(ScrollController) getter,
    T defaultValue,
  ) {
    if (controller.hasClients) {
      return getter(controller);
    }
    return defaultValue;
  }

  /// Safely add a listener with a null check and hasClients verification
  static void addListener(ScrollController controller, VoidCallback listener) {
    if (controller != null) {
      controller.addListener(() {
        if (controller.hasClients) {
          listener();
        }
      });
    }
  }

  /// Safely get the current scroll position, or 0.0 if not attached
  static double getOffset(ScrollController controller) {
    return getValue(controller, (c) => c.offset, 0.0);
  }

  /// Safely check if at the end of scroll
  static bool isAtEnd(ScrollController controller, {double threshold = 200.0}) {
    if (!controller.hasClients) return false;
    return controller.position.pixels >=
        controller.position.maxScrollExtent - threshold;
  }

  /// Safely check if the user pulled down to refresh
  static bool isPullDownActive(
    ScrollController controller, {
    double threshold = 100.0,
  }) {
    if (!controller.hasClients) return false;
    return controller.position.pixels < -threshold;
  }

  /// Safely animate to a specific position
  static Future<void> animateTo(
    ScrollController controller,
    double offset, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    if (controller.hasClients) {
      return controller.animateTo(offset, duration: duration, curve: curve);
    }
    return Future.value();
  }

  /// Safely jump to a specific position
  static void jumpTo(ScrollController controller, double offset) {
    if (controller.hasClients) {
      controller.jumpTo(offset);
    }
  }
}
