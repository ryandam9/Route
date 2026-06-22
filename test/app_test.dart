import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wombat/app.dart';

import 'helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('builds without a global SelectionArea (selection is scoped)',
      (tester) async {
    late ProviderContainer container;
    await tester.runAsync(() async {
      container = await createContainer(
        service: FakeOpenRouterService(),
        store: FakeConversationStore(),
      );
    });
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WombatApp()),
    );
    await tester.pump();

    // Selection is scoped to the chat transcript (see ChatView) rather than a
    // single app-wide SelectionArea, which tripped a SelectableRegion framework
    // crash. The dashboard has no transcript, so no SelectionArea here.
    expect(tester.takeException(), isNull);
    expect(find.byType(SelectionArea), findsNothing);
  });
}
