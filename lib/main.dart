import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/chat_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/usage_provider.dart';
import 'services/conversation_store.dart';
import 'services/debug_log.dart';
import 'services/openrouter_service.dart';
import 'services/secure_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsProvider(SecureStorageService(), prefs);
  final debug = DebugLog();
  final service = OpenRouterService(debug: debug);
  final store = ConversationStore();
  final usage = UsageProvider(service: service, settings: settings);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        Provider<OpenRouterService>.value(value: service),
        ChangeNotifierProvider<DebugLog>.value(value: debug),
        ChangeNotifierProvider<UsageProvider>.value(value: usage),
        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(
            service: service,
            store: store,
            settings: settings,
            usage: usage,
          ),
        ),
      ],
      child: const RouteApp(),
    ),
  );
}
