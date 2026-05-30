import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

class RouterNotifier extends AsyncNotifier<void> implements Listenable {
  VoidCallback? _routerListener;

  @override
  Future<void> build() async {
    ref.listen(authStateProvider, (_, _) => _routerListener?.call());
  }

  @override
  void addListener(VoidCallback listener) => _routerListener = listener;

  @override
  void removeListener(VoidCallback listener) => _routerListener = null;
}

final routerNotifierProvider =
    AsyncNotifierProvider<RouterNotifier, void>(RouterNotifier.new);
