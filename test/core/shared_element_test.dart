import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/core/navigation/shared_element_route.dart';
import 'package:jeeran_flutter/core/widgets/shared_photo.dart';

Widget _photo(Key key, double h) => SizedBox(key: key, height: h, width: double.infinity, child: const ColoredBox(color: Colors.blueGrey));

void main() {
  testWidgets('a card photo flies into the next screen and back, rounding off on the way', (tester) async {
    const tag = 'unit-photo-1-test';
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                GestureDetector(
                  key: const Key('card'),
                  onTap: () => Navigator.push(
                    context,
                    sharedElementRoute(
                      Scaffold(body: Column(children: [SharedPhoto(tag: tag, toRadius: 0, child: _photo(const Key('big'), 300)), const Text('details')])),
                    ),
                  ),
                  child: SharedPhoto(tag: tag, fromRadius: 18, child: _photo(const Key('small'), 120)),
                ),
                const Text('list'),
              ],
            ),
          ),
        ),
      ),
    );

    // push: mid-flight the photo is rounded between the card's corner and the page's (square) corner
    await tester.tap(find.byKey(const Key('card')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final flying = tester.widgetList<ClipRRect>(find.descendant(of: find.byType(Overlay), matching: find.byType(ClipRRect))).toList();
    expect(flying, isNotEmpty);
    final radius = (flying.first.borderRadius as BorderRadius).topLeft.x;
    expect(radius, inInclusiveRange(0.0, 18.0));
    expect(tester.takeException(), isNull);

    // landed: the page shows the big photo, the page content faded in
    await tester.pumpAndSettle();
    expect(find.text('details'), findsOneWidget);
    expect(find.byKey(const Key('big')), findsOneWidget);

    // back: the photo returns to the card
    Navigator.of(tester.element(find.text('details'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('list'), findsOneWidget);
    expect(find.byKey(const Key('small')), findsOneWidget);
  });
}
