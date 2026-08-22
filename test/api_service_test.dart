import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_doubt_solver/services/api_service.dart';

const env = {
  'API_BASE_URL': 'https://example.test/v1/chat/completions',
  'API_KEY': 'sk-test',
  'API_MODEL': 'test-model',
};

http.Response okBody(String content) => http.Response(
    jsonEncode({'choices': [
      {'message': {'role': 'assistant', 'content': content}}
    ]}), 200);

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('api_test');
    File('${tmp.path}/p.jpg').writeAsBytesSync(Uint8List.fromList([1, 2, 3]));
    dotenv.loadFromString(envString: '''
API_BASE_URL=https://example.test/v1/chat/completions
API_KEY=sk-dotenv
API_MODEL=m-dotenv
''');
  });

  tearDown(() async => tmp.delete(recursive: true));

  test('TITLE: prefix parse hota hai', () async {
    final svc = ApiService(envOverride: env, client: MockClient(
        (_) async => okBody('TITLE: Integral of x^2\n\n## Step 1\n\$\\int x^2 dx\$\n')));
    final ans = await svc.solveQuestion('${tmp.path}/p.jpg');
    expect(ans.title, 'Integral of x^2');
    expect(ans.solution, '## Step 1\n\$\\int x^2 dx\$');
  });

  test('prefix na ho to fallback title', () async {
    final svc = ApiService(envOverride: env, client: MockClient(
        (_) async => okBody('Yeh raha solution.\nAur bhi steps.')));
    final ans = await svc.solveQuestion('${tmp.path}/p.jpg');
    expect(ans.title, 'Yeh raha solution.');
    expect(ans.solution, contains('Aur bhi steps.'));
  });

  test('request OpenAI-compatible shape me jaata hai', () async {
    Uri? capturedUri;
    Map<String, dynamic>? capturedBody;
    final svc = ApiService(envOverride: env, client: MockClient((req) async {
      capturedUri = req.url;
      capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
      return okBody('TITLE: T\nSol');
    }));

    await svc.solveQuestion('${tmp.path}/p.jpg');

    expect(capturedUri.toString(), 'https://example.test/v1/chat/completions');
    expect(capturedBody!['model'], 'test-model');
    final msg = (capturedBody!['messages'] as List).single as Map<String, dynamic>;
    expect(msg['role'], 'user');
    final parts = msg['content'] as List;
    expect(parts[0]['type'], 'text');
    expect(parts[0]['text'], contains('TITLE:'));
    expect(parts[1]['type'], 'image_url');
    expect((parts[1]['image_url'] as Map)['url'], startsWith('data:image/jpeg;base64,'));
  });

  test('HTTP 401 → HttpApiError with friendly message', () async {
    final svc = ApiService(envOverride: env, client: MockClient(
        (_) async => http.Response('{"error":"bad key"}', 401)));
    await expectLater(svc.solveQuestion('${tmp.path}/p.jpg'),
        throwsA(isA<HttpApiError>().having((e) => e.message, 'msg', contains('key'))));
  });

  test('SocketException → NetworkError', () async {
    final svc = ApiService(envOverride: env, client: MockClient(
        (_) async => throw const SocketException('no net')));
    await expectLater(svc.solveQuestion('${tmp.path}/p.jpg'),
        throwsA(isA<NetworkError>()));
  });

  test('config missing → MissingConfigError', () async {
    final svc = ApiService(client: MockClient((_) async => okBody('x')),
        envOverride: {'API_BASE_URL': '', 'API_KEY': '', 'API_MODEL': ''});
    await expectLater(svc.solveQuestion('${tmp.path}/p.jpg'),
        throwsA(isA<MissingConfigError>()));
  });

  test('malformed JSON → BadResponseError', () async {
    final svc = ApiService(envOverride: env, client: MockClient(
        (_) async => http.Response(jsonEncode({'weird': true}), 200)));
    await expectLater(svc.solveQuestion('${tmp.path}/p.jpg'),
        throwsA(isA<BadResponseError>()));
  });
}
