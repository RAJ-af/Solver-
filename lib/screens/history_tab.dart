import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../store/doubt_store.dart';
import '../widgets/doubt_card.dart';
import '../widgets/empty_history.dart';

/// Tab 2 — saare past doubts.
class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key, required this.onGoToSolve});
  final VoidCallback onGoToSolve;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DoubtStore>();
    if (store.doubts.isEmpty) {
      return EmptyHistory(onGoToSolve: onGoToSolve);
    }
    return RefreshIndicator(
      onRefresh: store.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        itemCount: store.doubts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 0),
        itemBuilder: (_, i) => DoubtCard(doubt: store.doubts[i]),
      ),
    );
  }
}
