import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../services/image_service.dart';
import '../theme/app_theme.dart';
import '../widgets/solution_route.dart';

/// Tab 1 — hero + photo pick actions.
class SolveTab extends StatelessWidget {
  const SolveTab({super.key});

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final processed = await ImageService().process(picked.path, dir.path);
      navigator.push(SolutionRoute(processed));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Photo process nahi ho paayi: $e'),
        backgroundColor: AppTheme.teal,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [AppTheme.teal, Color(0xFF0093A8)],
                  ),
                  boxShadow: [
                    BoxShadow(color: AppTheme.teal.withValues(alpha: .35), blurRadius: 32, offset: const Offset(0, 12)),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, size: 44, color: AppTheme.lime),
              ),
            ),
            const SizedBox(height: 28),
            Text('Koi bhi doubt?\nPhoto kheencho!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 10),
            Text('Camera se question ki photo lo — step-by-step Hinglish solution turant.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 36),
            _ActionCard(
              icon: Icons.photo_camera_rounded,
              iconBg: AppTheme.teal.withValues(alpha: .15),
              iconColor: cs.primary,
              title: 'Camera se poochho',
              subtitle: 'Question ki photo click karo',
              onTap: () => _pick(context, ImageSource.camera),
            ),
            const SizedBox(height: 14),
            _ActionCard(
              icon: Icons.photo_library_rounded,
              iconBg: AppTheme.lime.withValues(alpha: .18),
              iconColor: const Color(0xFF7A9A00),
              title: 'Gallery se choose karo',
              subtitle: 'Pehle se saved screenshot/photo',
              onTap: () => _pick(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.subtitle, required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF131920) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: iconColor, size: 26)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ])),
            Icon(Icons.chevron_right_rounded, color: Theme.of(context).textTheme.bodySmall?.color),
          ]),
        ),
      ),
    );
  }
}
