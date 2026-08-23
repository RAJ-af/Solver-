/// Compact Hinglish relative time.
String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'abhi';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min pehle';
  if (diff.inHours < 24) return '${diff.inHours} ghante pehle';
  if (diff.inDays < 7) return '${diff.inDays} din pehle';
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}
