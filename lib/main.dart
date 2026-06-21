import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/app_providers.dart';

/// flutter_svg / vector_graphics log unsupported SVG elements (e.g. `<filter>`,
/// `<foreignObject>` contents like `<div>`) via `print` when a model reply
/// embeds an SVG they can't fully render. The SVG still draws its supported
/// parts, so these lines are benign console noise — drop them.
bool isSvgRenderNoise(String line) =>
    line.contains('unhandled element') && line.contains('Svg loader');

Future<void> main() async {
  // Run the binding and the app in one zone whose `print` filters the benign
  // flutter_svg "unhandled element" noise (see [isSvgRenderNoise]).
  runZoned(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      final prefs = await SharedPreferences.getInstance();

      runApp(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const WombatApp(),
        ),
      );
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        if (isSvgRenderNoise(line)) return;
        parent.print(zone, line);
      },
    ),
  );
}
