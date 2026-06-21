import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wombat/models/attachment.dart';
import 'package:wombat/models/chat_message.dart';
import 'package:wombat/models/usage.dart';
import 'package:wombat/providers/chat_provider.dart';
import 'package:wombat/widgets/model_selector.dart';

import '../helpers/fakes.dart';

/// Emits one chunk then hangs, keeping the provider in the responding state.
class _NeverEndingService extends FakeOpenRouterService {
  @override
  Stream<String> streamChat({
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
    bool imageOutput = false,
    void Function(TokenUsage usage)? onUsage,
    void Function(MessageAttachment image)? onImage,
    void Function(MessageAttachment audio)? onAudio,
    void Function(String debugSessionId)? onDebugSession,
  }) async* {
    yield 'partial';
    await Completer<void>().future;
  }
}

BoxShadow? _pillShadow(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(ModelSelector),
          matching: find.byType(Container),
        )
        .first,
  );
  final decoration = container.decoration as BoxDecoration?;
  final shadows = decoration?.boxShadow;
  return (shadows == null || shadows.isEmpty) ? null : shadows.first;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> load(WidgetTester tester) async {
    late ProviderContainer container;
    await tester.runAsync(() async {
      container = await createContainer(
        service: _NeverEndingService(),
        store: FakeConversationStore(),
      );
      await waitUntil(() => !container.read(chatProvider.notifier).loading);
    });
    addTearDown(container.dispose);
    return container;
  }

  testWidgets('the model pill glows while the model is responding',
      (tester) async {
    final container = await load(tester);
    container.read(chatProvider.notifier).newConversation();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: Center(child: ModelSelector())),
        ),
      ),
    );
    await tester.pump();

    // Idle: no glow around the pill.
    expect(_pillShadow(tester), isNull);

    // Start a reply (the fake hangs, so the chat stays responding).
    unawaited(container.read(chatProvider.notifier).sendMessage('hi'));
    await tester.pump();

    expect(container.read(chatProvider).isResponding, isTrue);
    // Responding: the pill now carries a glow.
    expect(_pillShadow(tester), isNotNull);

    // Stop the hung reply so no streaming timer/subscription outlives the test.
    container.read(chatProvider.notifier).stopResponding();
    await tester.pump();
    expect(_pillShadow(tester), isNull);
  });
}
