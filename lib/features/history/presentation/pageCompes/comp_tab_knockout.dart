import 'package:flutter/material.dart';
import '../../domain/history_models.dart';
import '../widgets/knockout_bracket_widget.dart';
import 'history_competitions_shared.dart';

class CompTabKnockout extends StatelessWidget {
  final CompetitionDetail detail;
  const CompTabKnockout({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    if (detail.knockout.isEmpty) {
      return Center(
        child: Text('Sin partidos registrados.',
            style: monoStyle(color: kHistMuted)),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: KnockoutBracketWidget(matches: detail.knockout),
    );
  }
}
