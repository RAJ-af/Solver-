import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'history_tab.dart';
import 'solve_tab.dart';
import '../store/doubt_store.dart';

/// Bottom NavigationBar wala 2-tab shell. IndexedStack tab state preserve karta hai.
class RootShell extends StatefulWidget {
  const RootShell({super.key, this.skipInitialRefresh = false});
  final bool skipInitialRefresh;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.skipInitialRefresh) {
      context.read<DoubtStore>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const SolveTab(),
          HistoryTab(onGoToSolve: () => setState(() => _index = 0)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Solve',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
