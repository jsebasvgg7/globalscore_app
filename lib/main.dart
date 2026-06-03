import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'package:google_fonts/google_fonts.dart';

const String kSupabaseUrl = 'https://auquyjigjceqzwpjbbff.supabase.co';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = true;

  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF1cXV5amlnamNlcXp3cGpiYmZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ0MzAwNzksImV4cCI6MjA4MDAwNjA3OX0.aiFHuOp6CgyjN3VL8OQZp7U2bGLxZu9-OFlCGwkqq3w',
  );

  runApp(const ProviderScope(child: GlobalScoreApp()));
}

class GlobalScoreApp extends ConsumerWidget {
  const GlobalScoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
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
    );
  }
}