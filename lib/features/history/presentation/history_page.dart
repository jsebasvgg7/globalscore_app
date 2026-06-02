import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/history_providers.dart';
import 'page/history_vault_page.dart';
import 'pageCompes/history_competitions_page.dart';
import 'pageEvents/history_events_page.dart';
import 'pageTeams/history_teams_page.dart';
import 'pagePlayers/history_players_page.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(historySectionProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: _buildSection(section),
    );
  }

  Widget _buildSection(String section) {
    switch (section) {
      case 'competitions':
        return const HistoryCompetitionsPage(key: ValueKey('competitions'));
      case 'events':
        return const HistoryEventsPage(key: ValueKey('events'));
      case 'teams':
        return const HistoryTeamsPage(key: ValueKey('teams'));
      case 'players':
        return const HistoryPlayersPage(key: ValueKey('players'));
      default:
        return const HistoryVaultPage(key: ValueKey('vault'));
    }
  }
}