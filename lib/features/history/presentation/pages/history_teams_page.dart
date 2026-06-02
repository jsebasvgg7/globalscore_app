import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/history_service.dart';
import '../../domain/history_models.dart';
import '../../domain/history_providers.dart';
import '../widgets/history_app_bar.dart';

const _kAccent = Color(0xFF5B4FD8);
const _kBg = Color(0xFFF0EDE8);
const _kDark = Color(0xFF1A1A2E);
const _kMuted = Color(0xFF88887D);
const _kBorder = Color(0xFFC4BFB8);

TextStyle _mono({
  Color color = _kDark,
  double size = 12,
  FontWeight weight = FontWeight.normal,
  double letterSpacing = 0,
}) =>
    GoogleFonts.dmMono(
      color: color,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      decoration: TextDecoration.none,
    );

// ══════════════════════════════════════════════════════════════
//  TEAMS PAGE
// ══════════════════════════════════════════════════════════════

class HistoryTeamsPage extends ConsumerStatefulWidget {
  const HistoryTeamsPage({super.key});

  @override
  ConsumerState<HistoryTeamsPage> createState() => _HistoryTeamsPageState();
}

class _HistoryTeamsPageState extends ConsumerState<HistoryTeamsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedTeamProvider);
    if (selected != null) return _TeamDetailView(team: selected);
    return _TeamListView(searchCtrl: _searchCtrl);
  }
}

// ══════════════════════════════════════════════════════════════
//  LIST VIEW — 2-column grid
// ══════════════════════════════════════════════════════════════

class _TeamListView extends ConsumerWidget {
  final TextEditingController searchCtrl;
  const _TeamListView({required this.searchCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(filteredTeamsProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          HistoryAppBar(
            title: 'EQUIPOS',
            subtitle: 'Clubes y selecciones legendarias',
            icon: Icons.shield_outlined,
            onBack: () => ref.read(historySectionProvider.notifier).goBack(),
          ),

          // Search
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _kBorder)),
            ),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(color: _kBorder),
                color: Colors.white,
              ),
              child: TextField(
                controller: searchCtrl,
                style: _mono(size: 12),
                decoration: InputDecoration(
                  hintText: 'Buscar equipo…',
                  hintStyle: _mono(size: 12, color: _kMuted),
                  prefixIcon: const Icon(Icons.search, size: 16, color: _kMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  suffixIcon: searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 14),
                          onPressed: () {
                            searchCtrl.clear();
                             ref.read(teamSearchProvider.notifier).set('');
                          },
                        )
                      : null,
                ),
                onChanged: (v) => ref.read(teamSearchProvider.notifier).set(v),
              ),
            ),
          ),

          // Grid
          Expanded(
            child: teamsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: _kAccent)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (teams) {
                if (teams.isEmpty) {
                  return Center(child: Text('Sin resultados', style: _mono(color: _kMuted)));
                }
                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: teams.length,
                  itemBuilder: (_, i) => _TeamCard(
                    team: teams[i],
                    onTap: () => ref.read(selectedTeamProvider.notifier).select(teams[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final HistoricalTeam team;
  final VoidCallback onTap;
  const _TeamCard({required this.team, required this.onTap});

  Color get _primaryColor {
    if (team.primaryColor == null) return _kAccent;
    try {
      final hex = team.primaryColor!.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return _kAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imgUrl = getHistoricalImageUrl(team.imagePath);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: _kBorder),
          color: _kBg,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            SizedBox(
              width: 64,
              height: 64,
              child: imgUrl != null
                  ? Image.network(imgUrl, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(Icons.shield, size: 36, color: _primaryColor))
                  : Icon(Icons.shield, size: 36, color: _primaryColor),
            ),
            const SizedBox(height: 10),

            Text(
              team.name.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _mono(size: 10, weight: FontWeight.w800),
            ),
            const SizedBox(height: 4),

            if (team.era != null)
              Text(team.era!, style: _mono(size: 9, color: _kMuted), textAlign: TextAlign.center),

            if (team.country != null)
              Text(team.country!, style: _mono(size: 9, color: _kMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  DETAIL VIEW
// ══════════════════════════════════════════════════════════════

class _TeamDetailView extends ConsumerWidget {
  final HistoricalTeam team;
  const _TeamDetailView({required this.team});

  Color get _primaryColor {
    if (team.primaryColor == null) return _kAccent;
    try {
      final hex = team.primaryColor!.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return _kAccent;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imgUrl = getHistoricalImageUrl(team.imagePath);

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          HistoryAppBar(
            title: team.name.toUpperCase(),
            subtitle: team.era ?? team.country ?? '',
            icon: Icons.shield_outlined,
            onBack: () => ref.read(selectedTeamProvider.notifier).select(null),
          ),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo
                        if (imgUrl != null)
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: Image.network(imgUrl, fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(Icons.shield, size: 60, color: _primaryColor)),
                          )
                        else
                          Icon(Icons.shield, size: 60, color: _primaryColor),

                        const SizedBox(height: 16),
                        Text(team.name, style: _mono(size: 20, weight: FontWeight.w800), textAlign: TextAlign.center),

                        const SizedBox(height: 12),

                        // Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            if (team.country != null)
                              _InfoChip(label: team.country!, icon: Icons.flag_outlined),
                            if (team.era != null)
                              _InfoChip(label: team.era!, icon: Icons.access_time_rounded),
                          ],
                        ),

                        if (team.description != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(color: _kBorder),
                            ),
                            child: Text(team.description!, style: _mono(size: 12, color: _kMuted)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: _kMuted),
          const SizedBox(width: 5),
          Text(label, style: _mono(size: 10, color: _kDark)),
        ],
      ),
    );
  }
}
