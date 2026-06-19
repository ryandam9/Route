import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:route/models/chat_message.dart';
import 'package:route/models/usage.dart';
import 'package:route/services/openrouter_service.dart';

void main() {
  group('OpenRouterService.fetchModels', () {
    test('parses and sorts models by display name', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/models'));
        expect(request.headers['Authorization'], 'Bearer key');
        return http.Response(
          jsonEncode({
            'data': [
              {'id': 'z/zeta', 'name': 'Zeta'},
              {'id': 'a/alpha', 'name': 'Alpha'},
            ]
          }),
          200,
        );
      });

      final models = await OpenRouterService(client: client).fetchModels('key');

      expect(models.map((m) => m.name), ['Alpha', 'Zeta']);
    });

    test('throws OpenRouterException with API message on non-200', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'message': 'Invalid API key'}
          }),
          401,
        );
      });

      expect(
        () => OpenRouterService(client: client).fetchModels('bad'),
        throwsA(
          isA<OpenRouterException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', 'Invalid API key'),
        ),
      );
    });

    test('wraps network errors', () async {
      final client = MockClient((request) async {
        throw const SocketExceptionLike();
      });

      expect(
        () => OpenRouterService(client: client).fetchModels('key'),
        throwsA(isA<OpenRouterException>()
            .having((e) => e.message, 'message', contains('Network error'))),
      );
    });
  });

  group('OpenRouterService.streamChat', () {
    http.StreamedResponse sse(List<String> lines, {int status = 200}) {
      final body = lines.map((l) => utf8.encode('$l\n'));
      return http.StreamedResponse(Stream.fromIterable(body), status);
    }

    test('yields content deltas and stops at [DONE]', () async {
      final client = MockClient.streaming((request, bodyStream) async {
        final body = await bodyStream.bytesToString();
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        expect(decoded['stream'], true);
        expect(decoded['model'], 'test/model');
        return sse([
          'data: {"choices":[{"delta":{"content":"Hel"}}]}',
          ': OPENROUTER PROCESSING',
          '',
          'data: {"choices":[{"delta":{"content":"lo"}}]}',
          'data: [DONE]',
          'data: {"choices":[{"delta":{"content":"ignored"}}]}',
        ]);
      });

      final chunks = await OpenRouterService(client: client)
          .streamChat(
            apiKey: 'key',
            model: 'test/model',
            messages: [
              ChatMessage(id: '1', role: MessageRole.user, content: 'hi'),
            ],
          )
          .toList();

      expect(chunks, ['Hel', 'lo']);
    });

    test('skips malformed frames without aborting', () async {
      final client = MockClient.streaming((request, bodyStream) async {
        return sse([
          'data: not-json',
          'data: {"choices":[{"delta":{"content":"ok"}}]}',
          'data: [DONE]',
        ]);
      });

      final chunks = await OpenRouterService(client: client)
          .streamChat(apiKey: 'k', model: 'm', messages: []).toList();

      expect(chunks, ['ok']);
    });

    test('throws with API message on non-200 stream', () async {
      final client = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode(
              jsonEncode({'error': {'message': 'rate limited'}}))),
          429,
        );
      });

      expect(
        () => OpenRouterService(client: client)
            .streamChat(apiKey: 'k', model: 'm', messages: []).toList(),
        throwsA(isA<OpenRouterException>()
            .having((e) => e.statusCode, 'statusCode', 429)
            .having((e) => e.message, 'message', 'rate limited')),
      );
    });

    test('reports usage from the final chunk via onUsage', () async {
      final client = MockClient.streaming((request, bodyStream) async {
        return sse([
          'data: {"choices":[{"delta":{"content":"hi"}}]}',
          'data: {"choices":[],"usage":{"prompt_tokens":12,'
              '"completion_tokens":3,"cost":0.0005}}',
          'data: [DONE]',
        ]);
      });

      TokenUsage? captured;
      final chunks = await OpenRouterService(client: client)
          .streamChat(
            apiKey: 'k',
            model: 'm',
            messages: [],
            onUsage: (u) => captured = u,
          )
          .toList();

      expect(chunks, ['hi']);
      expect(captured, isNotNull);
      expect(captured!.promptTokens, 12);
      expect(captured!.completionTokens, 3);
      expect(captured!.cost, 0.0005);
    });
  });

  group('OpenRouterService.fetchCredits', () {
    test('parses the balance', () async {
      final client = MockClient((request) async {
        expect(request.url.path, endsWith('/credits'));
        return http.Response(
          jsonEncode({
            'data': {'total_credits': 10, 'total_usage': 4}
          }),
          200,
        );
      });

      final credits = await OpenRouterService(client: client).fetchCredits('k');

      expect(credits.totalCredits, 10);
      expect(credits.totalUsage, 4);
      expect(credits.remaining, 6);
    });

    test('throws on non-200 (e.g. key without credit access)', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': {'message': 'forbidden'}}),
          403,
        );
      });

      expect(
        () => OpenRouterService(client: client).fetchCredits('k'),
        throwsA(isA<OpenRouterException>()
            .having((e) => e.statusCode, 'statusCode', 403)),
      );
    });
  });
}

/// A lightweight stand-in to simulate a transport-level failure.
class SocketExceptionLike implements Exception {
  const SocketExceptionLike();
  @override
  String toString() => 'Connection refused';
}
