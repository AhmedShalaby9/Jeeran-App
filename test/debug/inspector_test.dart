import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/core/config/app_config.dart';
import 'package:jeeran_flutter/core/debug/network_inspector.dart';

void main() {
  Widget host() => MaterialApp(
        builder: (c, child) => NetworkInspector.wrap(child),
        home: const Scaffold(body: Text('page')),
      );

  testWidgets('staging shows the inspector button over the app', (t) async {
    AppConfig.setEnvironment(AppEnvironment.staging);
    await t.pumpWidget(host());
    expect(find.byKey(const Key('network-inspector-fab')), findsOneWidget);
    expect(find.text('page'), findsOneWidget);
  });

  testWidgets('production never shows it', (t) async {
    AppConfig.setEnvironment(AppEnvironment.production);
    await t.pumpWidget(host());
    expect(find.byKey(const Key('network-inspector-fab')), findsNothing);
    AppConfig.setEnvironment(AppEnvironment.staging);
  });
}
