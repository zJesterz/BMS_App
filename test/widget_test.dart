import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:battery_monitor/main.dart';
import 'package:battery_monitor/services/auth_service.dart';

void main() {
  testWidgets('Login flow shows dashboard with mock battery data', (WidgetTester tester) async {
    await tester.pumpWidget(
      BatteryMonitorApp(
        authService: MockAuthService(),
      ),
    );

    expect(find.text('Sign In'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'admin',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'admin',
    );
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Dashboard DataTable shows mock batteries.
    expect(find.text('Main Battery'), findsOneWidget);
    expect(find.text('Backup Battery'), findsOneWidget);
    // DataTable columns: Battery, Voltage, SOC, plus 2 battery rows.
    expect(find.text('SOC'), findsOneWidget);
    expect(find.text('Voltage'), findsOneWidget);
  });
}
