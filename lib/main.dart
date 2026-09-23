import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/services/auth_sync_service.dart';
import 'data/services/book_lookup_service.dart';
import 'presentation/providers/library_provider.dart';
import 'presentation/screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  final authSync = AuthSyncService(database);
  await authSync.initialize();
  runApp(KutuphaneApp(database: database, authSync: authSync));
}
class KutuphaneApp extends StatelessWidget {
  const KutuphaneApp({required this.database, required this.authSync, super.key});

  final AppDatabase database;
  final AuthSyncService authSync;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LibraryProvider(
        database: database,
        lookupService: BookLookupService(),
        authSync: authSync,
      )..initialize(),
      child: MaterialApp(
        title: 'Kütüphane-i Şahsî',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('tr', 'TR'),
        supportedLocales: const [Locale('tr', 'TR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const HomeShell(),
      ),
    );
  }
}
