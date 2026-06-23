import 'package:flutter/material.dart';

/// Provides app-wide settings (theme, etc.) to descendant widgets.
class AppSettingsScope extends InheritedWidget {
  const AppSettingsScope({
    super.key,
    required this.isDarkMode,
    required this.setDarkMode,
    required super.child,
  });

  final bool isDarkMode;
  final ValueChanged<bool> setDarkMode;

  static AppSettingsScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppSettingsScope oldWidget) {
    return isDarkMode != oldWidget.isDarkMode;
  }
}
