import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:provider/provider.dart';

import '../models/doubt.dart';
import '../store/doubt_store.dart';
import '../utils/time_ago.dart';

/// Saved doubt ka poora view + delete action.
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.doubt});
  final Doubt doubt;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete karein?'),
        content: const Text('Ye doubt aur uski photo permanently delete ho jayegi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<DoubtStore>().remove(doubt);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(timeAgo(doubt.createdAt)),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () => _confirmDelete(context)),
        ],
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          if (File(doubt.imagePath).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: Image.file(File(doubt.imagePath), fit: BoxFit.cover, width: double.infinity),
              ),
            ),
          const SizedBox(height: 18),
          Text(doubt.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131920) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: GptMarkdown(doubt.solution, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ]),
      ),
    );
  }
}
