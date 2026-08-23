import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../store/doubt_store.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_box.dart';

enum _Phase { analyzing, done, error }

/// Photo → API call → markdown solution. Success par auto-save.
class SolutionScreen extends StatefulWidget {
  const SolutionScreen({super.key, required this.imagePath, AnswerProvider? api})
      : _api = api; // ignore: prefer_initializing_formals

  final String imagePath;
  final AnswerProvider? _api;

  @override
  State<SolutionScreen> createState() => _SolutionScreenState();
}

class _SolutionScreenState extends State<SolutionScreen> {
  static const _statusMessages = [
    'Photo padh rahe hain…',
    'Question samajh rahe hain…',
    'Steps banaye ja rahe hain…',
    'Ox Alpha soch raha hai…',
  ];

  late final AnswerProvider _api = widget._api ?? ApiService();
  _Phase _phase = _Phase.analyzing;
  SolvedAnswer? _answer;
  String? _error;
  int _msgIndex = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() => _msgIndex = (_msgIndex + 1) % _statusMessages.length);
    });
    _solve();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _solve() async {
    setState(() {
      _phase = _Phase.analyzing;
      _error = null;
    });
    _ticker ??= Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() => _msgIndex = (_msgIndex + 1) % _statusMessages.length);
    });
    try {
      final answer = await _api.solveQuestion(widget.imagePath);
      if (!mounted) return;
      await context.read<DoubtStore>().addSaved(widget.imagePath, answer);
      if (!mounted) return;
      _ticker?.cancel();
      _ticker = null;
      setState(() {
        _answer = answer;
        _phase = _Phase.done;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      _ticker?.cancel();
      _ticker = null;
      setState(() {
        _error = e.message;
        _phase = _Phase.error;
      });
    } catch (e) {
      if (!mounted) return;
      _ticker?.cancel();
      _ticker = null;
      setState(() {
        _error = 'Kuch galat ho gaya: $e';
        _phase = _Phase.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solution')),
      body: SafeArea(
        child: switch (_phase) {
          _Phase.analyzing => _AnalyzingView(imagePath: widget.imagePath, message: _statusMessages[_msgIndex]),
          _Phase.done => _ResultView(answer: _answer!, imagePath: widget.imagePath),
          _Phase.error => _ErrorView(error: _error!, onRetry: _solve),
        },
      ),
    );
  }
}

class _AnalyzingView extends StatelessWidget {
  const _AnalyzingView({required this.imagePath, required this.message});
  final String imagePath;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(padding: const EdgeInsets.all(20), children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: Image.file(File(imagePath), fit: BoxFit.cover, width: double.infinity),
        ),
      ),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedSwitcher(duration: const Duration(milliseconds: 350),
          child: Text(message, key: ValueKey(message),
              style: Theme.of(context).textTheme.titleMedium)),
      ]),
      const SizedBox(height: 28),
      ...List.generate(4, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerBox(height: 14 + (i % 2) * 6,
            width: double.infinity, radius: 7),
      )),
      const SizedBox(height: 8),
      Center(child: Text('Ho sakta hai 30–60 second lag jayein…',
          style: Theme.of(context).textTheme.bodySmall)),
      if (!isDark) const SizedBox(height: 8),
    ]);
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.answer, required this.imagePath});
  final SolvedAnswer answer;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131920) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.teal.withValues(alpha: .25)),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(imagePath), width: 56, height: 56, fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(answer.title, style: Theme.of(context).textTheme.titleLarge)),
        ]),
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131920) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: GptMarkdown(answer.solution, style: Theme.of(context).textTheme.bodyMedium),
      ),
      const SizedBox(height: 24),
      Row(children: [
        Icon(Icons.check_circle_rounded, color: AppTheme.lime, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text('Solution history me save ho gaya',
            style: Theme.of(context).textTheme.bodySmall)),
      ]),
    ]);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 84, height: 84,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(24)),
            child: Icon(Icons.cloud_off_rounded, size: 40,
                color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 20),
          Text(error, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 26),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
        ]),
      ),
    );
  }
}
