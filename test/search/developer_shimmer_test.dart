import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/features/developers/presentation/widgets/developer_shimmer.dart';

void main() {
  testWidgets('shimmer placeholders lay out without overflow', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [DevListShimmer(), DeveloperBodyShimmer()],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('dev-shimmer')), findsOneWidget);
    expect(find.byKey(const Key('developer-shimmer')), findsOneWidget);
  });
}
