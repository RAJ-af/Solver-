import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../store/doubt_store.dart';
import '../widgets/doubt_card.dart';
import '../widgets/empty_history.dart';
import '../widgets/shimmer_box.dart';

/// Tab 2 — saare past doubts.
class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key, required this.onGoToSolve});
  final VoidCallback onGoToSolve;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DoubtStore>();
    // Pehli load par empty-state flash na ho — card-shaped shimmer dikhao.
    if (store.loading && store.doubts.isEmpty) {
      return ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        children: List.generate(4,
            (_) => const Padding(padding: EdgeInsets.only(bottom: 12),
                child: ShimmerBox(height: 88, width: double.infinity, radius: 20))),
      );
    }
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
