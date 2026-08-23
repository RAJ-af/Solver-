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
      body: _FadeIndexedStack(
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

/// Spec: "Tab switch: NavigationBar default + subtle fade via IndexedStack".
/// IndexedStack hi rehta hai (children kabhi unmount nahi hote — tab state
/// preserve), sirf index change par ~250ms easeOut fade chalti hai.
class _FadeIndexedStack extends StatefulWidget {
  const _FadeIndexedStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<_FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    // Pehla frame full opacity — fade sirf tab SWITCH par, app-open par nahi.
    value: 1.0,
  );

  @override
  void didUpdateWidget(covariant _FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) _fade.forward(from: 0);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
      child: IndexedStack(index: widget.index, children: widget.children),
    );
  }
}
