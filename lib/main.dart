import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app/router.dart';
import 'core/theme/app_theme.dart';
import 'state/auth_provider.dart';
import 'state/notifications_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SudanRailwaysApp());
}

class SudanRailwaysApp extends StatelessWidget {
  const SudanRailwaysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..bootstrap()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
      ],
      child: Builder(
        builder: (context) {
          final auth = context.read<AuthProvider>();
          final router = buildRouter(auth);
          return MaterialApp.router(
            title: 'Sudan Railways',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: router,
            // English-first; the delegates + supportedLocales make adding
            // Arabic (with automatic RTL) a locale switch, not a rewrite.
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
            ],
            locale: const Locale('en'),
          );
        },
      ),
    );
  }
}
