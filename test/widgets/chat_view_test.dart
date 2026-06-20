import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wombat/providers/chat_provider.dart';
import 'package:wombat/widgets/chat_input.dart';
import 'package:wombat/widgets/chat_view.dart';
import 'package:wombat/widgets/model_selector.dart';

import '../helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Settings/provider setup relies on real timers and platform channels, so the
  // container is built inside runAsync (see chat_input_test for the pattern).
  Future<ProviderContainer> load(WidgetTester tester) async {
    late ProviderContainer container;
    await tester.runAsync(() async {
      container = await createContainer(
        service: FakeOpenRouterService(),
        store: FakeConversationStore(),
      );
      await waitUntil(() => !container.read(chatProvider.notifier).loading);
    });
    addTearDown(container.dispose);
    return container;
  }

  Future<void> pump(WidgetTester tester, ProviderContainer container) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: ChatView(showMenuButton: true)),
        ),
      ),
    );
  }

  testWidgets('initial launch hides the model selector, new chat and composer',
      (tester) async {
    final container = await load(tester);
    await pump(tester, container);
    await tester.pump();

    // Nothing has been started yet.
    expect(container.read(chatProvider.notifier).current, isNull);

    expect(find.byType(ModelSelector), findsNothing);
    expect(find.byType(ChatInput), findsNothing);
    expect(find.byTooltip('New chat'), findsNothing);

    // The drawer button stays, so the user can reach "+ New chat".
    expect(find.byTooltip('Conversations'), findsOneWidget);
  });

  testWidgets('starting a chat reveals the model selector and composer',
      (tester) async {
    final container = await load(tester);
    await pump(tester, container);

    container.read(chatProvider.notifier).newConversation();
    await tester.pump();

    expect(find.byType(ModelSelector), findsOneWidget);
    expect(find.byType(ChatInput), findsOneWidget);
    expect(find.byTooltip('New chat'), findsOneWidget);
  });
}
