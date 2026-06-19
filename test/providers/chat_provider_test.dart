import 'package:flutter_test/flutter_test.dart';
import 'package:route/models/chat_message.dart';
import 'package:route/providers/chat_provider.dart';
import 'package:route/services/openrouter_service.dart';

import '../helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ChatProvider> buildChat({
    FakeOpenRouterService? service,
    FakeConversationStore? store,
    String? apiKey = 'test-key',
  }) async {
    final settings = await buildLoadedSettings(apiKey: apiKey);
    final chat = ChatProvider(
      service: service ?? FakeOpenRouterService(),
      store: store ?? FakeConversationStore(),
      settings: settings,
    );
    await waitUntil(() => !chat.loading);
    return chat;
  }

  group('conversation management', () {
    test('starts with no current conversation when store is empty', () async {
      final chat = await buildChat();
      expect(chat.conversations, isEmpty);
      expect(chat.current, isNull);
    });

    test('newConversation creates, selects and uses default model', () async {
      final chat = await buildChat();
      final convo = chat.newConversation();

      expect(chat.current, convo);
      expect(chat.conversations, contains(convo));
      expect(convo.modelId, 'test/model');
      expect(convo.title, 'New chat');
    });

    test('selectConversation switches the current conversation', () async {
      final chat = await buildChat();
      final first = chat.newConversation();
      final second = chat.newConversation();
      expect(chat.current, second);

      chat.selectConversation(first.id);
      expect(chat.current, first);
    });

    test('deleteConversation removes and re-points current', () async {
      final chat = await buildChat();
      final first = chat.newConversation();
      final second = chat.newConversation();

      await chat.deleteConversation(second.id);

      expect(chat.conversations.map((c) => c.id), [first.id]);
      expect(chat.current, first);
    });

    test('setModelForCurrent updates the active conversation', () async {
      final chat = await buildChat();
      chat.newConversation();
      chat.setModelForCurrent('openai/gpt-4o');
      expect(chat.current!.modelId, 'openai/gpt-4o');
    });
  });

  group('sendMessage', () {
    test('requires an API key', () async {
      final chat = await buildChat(apiKey: null);
      await chat.sendMessage('hello');

      expect(chat.error, contains('API key'));
      expect(chat.current, isNull);
    });

    test('appends user message and streamed assistant reply', () async {
      final service = FakeOpenRouterService(chunks: ['Hello', ' ', 'world']);
      final store = FakeConversationStore();
      final chat = await buildChat(service: service, store: store);

      await chat.sendMessage('hi there');

      final messages = chat.current!.messages;
      expect(messages, hasLength(2));
      expect(messages[0].role, MessageRole.user);
      expect(messages[0].content, 'hi there');
      expect(messages[1].role, MessageRole.assistant);
      expect(messages[1].content, 'Hello world');
      expect(messages[1].isStreaming, isFalse);
      expect(chat.isResponding, isFalse);
      expect(store.saveCount, greaterThan(0));
    });

    test('derives the conversation title from the first message', () async {
      final chat = await buildChat();
      await chat.sendMessage('What is the capital of France?');
      expect(chat.current!.title, 'What is the capital of France?');
    });

    test('truncates long titles', () async {
      final chat = await buildChat();
      final long = 'x' * 100;
      await chat.sendMessage(long);
      expect(chat.current!.title.length, lessThanOrEqualTo(41));
      expect(chat.current!.title, endsWith('…'));
    });

    test('excludes the assistant placeholder from request history', () async {
      final service = FakeOpenRouterService(chunks: ['ok']);
      final chat = await buildChat(service: service);

      await chat.sendMessage('first');

      // Only the user message should be sent, not the streaming placeholder.
      expect(service.lastMessages, hasLength(1));
      expect(service.lastMessages!.single.role, MessageRole.user);
      expect(service.lastApiKey, 'test-key');
    });

    test('ignores empty input', () async {
      final chat = await buildChat();
      await chat.sendMessage('   ');
      expect(chat.current, isNull);
    });

    test('records an error when the service throws', () async {
      final service = FakeOpenRouterService()
        ..errorToThrow = OpenRouterException('server exploded');
      final chat = await buildChat(service: service);

      await chat.sendMessage('hi');

      final assistant = chat.current!.messages.last;
      expect(assistant.error, contains('server exploded'));
      expect(assistant.content, contains('server exploded'));
      expect(assistant.isStreaming, isFalse);
      expect(chat.isResponding, isFalse);
      expect(chat.error, isNotNull);
    });
  });

  group('error + state helpers', () {
    test('clearError resets the error banner', () async {
      final chat = await buildChat(apiKey: null);
      await chat.sendMessage('hi');
      expect(chat.error, isNotNull);

      chat.clearError();
      expect(chat.error, isNull);
    });
  });
}
