import 'package:flutter_test/flutter_test.dart';
import 'package:wombat/models/chat_message.dart';
import 'package:wombat/models/conversation.dart';

void main() {
  group('Conversation', () {
    test('round-trips through JSON including nested messages', () {
      final convo = Conversation(
        id: 'c1',
        title: 'Test',
        modelId: 'openai/gpt-4o-mini',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
        messages: [
          ChatMessage(id: 'm1', role: MessageRole.user, content: 'hi'),
          ChatMessage(id: 'm2', role: MessageRole.assistant, content: 'hello'),
        ],
      );

      final restored = Conversation.fromJson(convo.toJson());

      expect(restored.id, 'c1');
      expect(restored.title, 'Test');
      expect(restored.modelId, 'openai/gpt-4o-mini');
      expect(restored.createdAt, DateTime.utc(2026, 1, 1));
      expect(restored.updatedAt, DateTime.utc(2026, 1, 2));
      expect(restored.messages, hasLength(2));
      expect(restored.messages.first.content, 'hi');
      expect(restored.messages.last.role, MessageRole.assistant);
    });

    test('applies sensible defaults for missing fields', () {
      final restored = Conversation.fromJson({'id': 'only-id'});
      expect(restored.title, 'New chat');
      expect(restored.modelId, '');
      expect(restored.messages, isEmpty);
      expect(restored.createdAt, isA<DateTime>());
      expect(restored.updatedAt, isA<DateTime>());
    });

    test('defaults messages to an empty growable list', () {
      final convo = Conversation(id: 'c', title: 't', modelId: 'm');
      expect(convo.messages, isEmpty);
      convo.messages.add(
        ChatMessage(id: '1', role: MessageRole.user, content: 'x'),
      );
      expect(convo.messages, hasLength(1));
    });
  });
}
