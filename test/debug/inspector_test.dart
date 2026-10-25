import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/core/debug/network_inspector.dart';
import 'package:jeeran_flutter/core/services/app_settings_service.dart';

void main() {
  Widget host() => MaterialApp(
        builder: (c, child) => NetworkInspector.wrap(child),
        home: const Scaffold(body: Text('page')),
      );

  tearDown(() => AppSettingsService.instance.settings = null);

  testWidgets('hidden until settings load (default off)', (t) async {
    await t.pumpWidget(host());
    expect(find.byKey(const Key('network-inspector-fab')), findsNothing);
    expect(find.text('page'), findsOneWidget);
  });

  testWidgets('shown once the dashboard flag is on, on any environment', (t) async {
    AppSettingsService.instance.settings =
        const AppSettings(networkInspectorEnabled: true);
    await t.pumpWidget(host());
    expect(find.byKey(const Key('network-inspector-fab')), findsOneWidget);
  });

  testWidgets('hidden again once the dashboard flag is off', (t) async {
    AppSettingsService.instance.settings =
        const AppSettings(networkInspectorEnabled: false);
    await t.pumpWidget(host());
    expect(find.byKey(const Key('network-inspector-fab')), findsNothing);
  });
}
