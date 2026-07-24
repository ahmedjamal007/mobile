import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:srrs_mobile/core/theme/app_theme.dart';
import 'package:srrs_mobile/screens/auth/splash_screen.dart';

void main() {
  testWidgets('Splash screen renders the branding', (tester) async {
    // Rendered in isolation so the test doesn't depend on secure-storage /
    // image-picker platform channels that aren't available in unit tests.
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SplashScreen()),
    );

    expect(find.text('Sudan Railways'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
