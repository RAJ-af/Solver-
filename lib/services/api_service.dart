import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Ek solved question ka parsed result.
class SolvedAnswer {
  const SolvedAnswer({required this.title, required this.solution});
  final String title;
  final String solution;
}

/// Kisi bhi OpenAI-compatible vision endpoint se answer la sakta hai.
abstract class AnswerProvider {
  Future<SolvedAnswer> solveQuestion(String imagePath);
}

sealed class ApiError implements Exception {
  const ApiError(this.message);
  final String message;
  @override
  String toString() => message;
}

class MissingConfigError extends ApiError {
  const MissingConfigError()
      : super('.env me API_BASE_URL / API_KEY / API_MODEL set karo — '
            'phir dubara try karo.');
}

class NetworkError extends ApiError {
  const NetworkError(super.message);
}

class HttpApiError extends ApiError {
  const HttpApiError(this.statusCode, String message)
      : super(message);
  final int statusCode;
}

class BadResponseError extends ApiError {
  const BadResponseError() : super('Server ka response samajh nahi aaya. Dubara try karo.');
}

class ApiService implements AnswerProvider {
  ApiService({http.Client? client, Map<String, String>? envOverride})
      : _client = client ?? http.Client(),
        // ignore: prefer_initializing_formals
        _envOverride = envOverride;

  final http.Client _client;
  final Map<String, String>? _envOverride;

  static const _prompt = '''
Ye ek question ki photo hai. Isko solve karo:

Sabse pehli line par SIRF ye likho (uske baad kabhi repeat mat karna):
TITLE: <question ka chhota summary, max 60 characters>

Uske baad poora solution do:
- Step-by-step numbered, easy Hinglish me samjhao
- Formulas LaTeX me likho (\$...\$ ya \$\$...\$\$)
- End me "## Final Answer" section ho
''';

  String _env(String key) {
    final o = _envOverride?[key];
    if (o != null) return o.trim();
    return (dotenv.maybeGet(key) ?? '').trim();
  }

  @override
  Future<SolvedAnswer> solveQuestion(String imagePath) async {
    final base = _env('API_BASE_URL');
    final key = _env('API_KEY');
    final model = _env('API_MODEL');
    if (base.isEmpty || key.isEmpty || model.isEmpty) throw const MissingConfigError();

    final imageBytes = await File(imagePath).readAsBytes();
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';

    final body = jsonEncode({
      'model': model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': _prompt},
            {'type': 'image_url', 'image_url': {'url': dataUrl}},
          ],
        }
      ],
    });

    http.Response resp;
    try {
      resp = await _client
          .post(Uri.parse(base),
              headers: {
                'Authorization': 'Bearer $key',
                'Content-Type': 'application/json',
              },
              body: body)
          .timeout(const Duration(seconds: 90));
    } on SocketException {
      throw const NetworkError('Internet nahi mil raha. Connection check karke retry karo.');
    } on http.ClientException {
      throw const NetworkError('Server tak nahi pahunch paaye. Thodi der baad retry karo.');
    } on TimeoutException {
      throw const NetworkError('Bahut time lag gaya (90s+). Dubara try karo.');
    }

    if (resp.statusCode != 200) throw HttpApiError(resp.statusCode, _friendly(resp.statusCode));

    final content = _extractContent(utf8.decode(resp.bodyBytes));
    return _splitTitle(content);
  }

  String _friendly(int code) {
    switch (code) {
      case 401 || 403:
        return 'API key galat ya expired lagti hai (.env check karo).';
      case 402:
        return 'Is provider ke credits khatam ho gaye.';
      case 429:
        return 'Bahut zyada requests — thoda ruk ke retry karo.';
      default:
        return 'Server ne error diya ($code). Thodi der baad retry karo.';
    }
  }

  String _extractContent(String responseBody) {
    try {
      final map = jsonDecode(responseBody) as Map<String, dynamic>;
      final choices = map['choices'] as List;
      final msg = choices.first as Map<String, dynamic>;
      final content = (msg['message'] as Map<String, dynamic>)['content'];
      if (content is String && content.trim().isNotEmpty) return content;
    } on FormatException {
      // fall through — JSON malformed
    } catch (_) {
      // structure unexpected
    }
    throw const BadResponseError();
  }

  /// "TITLE: ...\n`<rest>`" split; warna fallback pehli non-empty line.
  SolvedAnswer _splitTitle(String content) {
    final m = RegExp(r'^\s*TITLE:\s*(.*)\r?\n?', caseSensitive: false).firstMatch(content);
    if (m != null) {
      var title = m.group(1)?.trim() ?? '';
      if (title.isEmpty) title = 'Doubt';
      if (title.length > 60) title = '${title.substring(0, 57)}…';
      return SolvedAnswer(title: title, solution: content.substring(m.end).trim());
    }
    var title = content
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => 'Doubt');
    if (title.startsWith('#')) title = title.replaceAll('#', '').trim();
    if (title.length > 60) title = '${title.substring(0, 57)}…';
    return SolvedAnswer(title: title, solution: content.trim());
  }
}
