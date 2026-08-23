import 'dart:io';

import 'package:flutter/material.dart';

import '../models/doubt.dart';
import '../screens/detail_screen.dart';
import '../utils/time_ago.dart';

/// History list ka single card — thumbnail + title + relative time.
class DoubtCard extends StatelessWidget {
  const DoubtCard({super.key, required this.doubt});
  final Doubt doubt;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(File(doubt.imagePath),
              width: 64, height: 64, fit: BoxFit.cover,
              cacheWidth: 128,
              errorBuilder: (_, _, _) => Container(width: 64, height: 64,
                  color: Theme.of(context).dividerColor,
                  child: const Icon(Icons.image_not_supported_outlined, size: 24))),
        ),
        title: Text(doubt.title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(timeAgo(doubt.createdAt), style: Theme.of(context).textTheme.bodySmall),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DetailScreen(doubt: doubt))),
      ),
    );
  }
}
