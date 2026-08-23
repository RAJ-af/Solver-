import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Khali history ka illustration-style empty state.
class EmptyHistory extends StatelessWidget {
  const EmptyHistory({super.key, required this.onGoToSolve});
  final VoidCallback onGoToSolve;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          Stack(alignment: Alignment.center, children: [
            Container(width: 132, height: 132,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: AppTheme.teal.withValues(alpha: .10))),
            Container(width: 96, height: 96,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: AppTheme.teal.withValues(alpha: .18)),
              child: Icon(Icons.help_outline_rounded, size: 42, color: AppTheme.teal)),
            Positioned(
              top: 4, right: 8,
              child: Container(width: 30, height: 30,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: AppTheme.lime.withValues(alpha: .9)),
                child: const Icon(Icons.auto_awesome, size: 15, color: Colors.black)),
            ),
          ]),
          const SizedBox(height: 28),
          Text('Abhi koi doubt solve nahi hua', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Koi bhi question ki photo kheencho —\nsolution yahan save hota rahega.',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onGoToSolve,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Solve karo'),
          ),
        ]),
      ),
    );
  }
}
