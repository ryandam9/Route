import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:route/models/openrouter_model.dart';
import 'package:route/providers/settings_provider.dart';
import 'package:route/screens/model_picker_screen.dart';
import 'package:route/services/openrouter_service.dart';

import '../helpers/fakes.dart';

OpenRouterModel _model(
  String id,
  String name, {
  int? context,
  double? prompt,
  List<String> params = const [],
}) =>
    OpenRouterModel(
      id: id,
      name: name,
      contextLength: context,
      promptPrice: prompt,
      completionPrice: prompt,
      supportedParameters: params,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsProvider settings;
  late FakeOpenRouterService service;

  setUp(() async {
    settings = await buildLoadedSettings(defaultModel: 'a/alpha');
    service = FakeOpenRouterService()
      ..models = [
        _model('a/alpha', 'Alpha', context: 200000, prompt: 0.000002,
            params: ['tools']),
        _model('b/beta', 'Beta', context: 8000, prompt: 0),
      ];
  });

  Future<void> pump(WidgetTester tester, {Size size = const Size(1300, 1000)}) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          Provider<OpenRouterService>.value(value: service),
        ],
        child: const MaterialApp(home: ModelPickerScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists models with a detail panel on a wide screen',
      (tester) async {
    await pump(tester);

    expect(find.text('Alpha'), findsWidgets);
    expect(find.text('Beta'), findsWidgets);
    // The detail panel defaults to the configured default model.
    expect(find.text('Selected model'), findsOneWidget);
    expect(find.text('Select model'), findsOneWidget);
    expect(find.text('Key details'), findsOneWidget);
  });

  testWidgets('Free filter narrows the list to free models', (tester) async {
    // Narrow surface → no detail panel, so only the grid is on screen.
    await pump(tester, size: const Size(700, 1000));

    await tester.tap(find.widgetWithText(FilterChip, 'Free'));
    await tester.pumpAndSettle();

    expect(find.text('Beta'), findsWidgets); // free
    expect(find.text('Alpha'), findsNothing); // paid, filtered out
  });

  testWidgets('bookmark toggles a favorite in settings', (tester) async {
    await pump(tester);
    expect(settings.isFavoriteModel('b/beta'), isFalse);

    await tester.tap(find.byIcon(Icons.bookmark_border).first);
    await tester.pumpAndSettle();

    expect(settings.favoriteModels, isNotEmpty);
  });
}
