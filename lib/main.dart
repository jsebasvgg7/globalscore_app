import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/lifecycle/app_lifecycle_observer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/app_secrets.dart';

const String kSupabaseUrl = AppSecrets.supabaseUrl;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppSecrets.supabaseUrl,
    anonKey: AppSecrets.supabaseAnonKey,
  );
  runApp(const ProviderScope(child: GlobalScoreApp()));
}

class GlobalScoreApp extends ConsumerWidget {
  const GlobalScoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return AppLifecycleObserver(
      child: MaterialApp.router(
        title: 'GlobalScore',
        routerConfig: router,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5B4FD8),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.dmMonoTextTheme(),
          useMaterial3: true,
        ),
      ),
    );
  }
}