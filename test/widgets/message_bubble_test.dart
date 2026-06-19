import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route/models/chat_message.dart';
import 'package:route/widgets/message_bubble.dart';

Widget _wrap(ChatMessage message) => MaterialApp(
      home: Scaffold(body: MessageBubble(message: message)),
    );

void main() {
  testWidgets('renders a user message with the "You" label', (tester) async {
    await tester.pumpWidget(_wrap(
      ChatMessage(id: '1', role: MessageRole.user, content: 'Hello there'),
    ));

    expect(find.text('You'), findsOneWidget);
    expect(find.text('Hello there'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('renders an assistant message as Markdown with a copy button',
      (tester) async {
    await tester.pumpWidget(_wrap(
      ChatMessage(id: '1', role: MessageRole.assistant, content: '# Title'),
    ));

    expect(find.text('Assistant'), findsOneWidget);
    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
  });

  testWidgets('shows a typing indicator while streaming with no content',
      (tester) async {
    await tester.pumpWidget(_wrap(
      ChatMessage(
        id: '1',
        role: MessageRole.assistant,
        content: '',
        isStreaming: true,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    // Three animated dots, and no copy button while streaming.
    expect(find.byType(CircleAvatar), findsNWidgets(3));
    expect(find.text('Copy'), findsNothing);
  });

  testWidgets('hides the copy button for empty assistant content',
      (tester) async {
    await tester.pumpWidget(_wrap(
      ChatMessage(id: '1', role: MessageRole.assistant, content: ''),
    ));
    expect(find.text('Copy'), findsNothing);
  });
}
