import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/listing/listing_api.dart';
import 'package:jeeran_flutter/features/listing/listing_draft.dart';
import 'package:jeeran_flutter/features/listing/listing_flow.dart';
import 'package:jeeran_flutter/features/voice/voice_api.dart';
import 'package:jeeran_flutter/features/voice/voice_services.dart';
import 'package:jeeran_flutter/features/you/you_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _marassi = CompoundRef(
  4,
  'مراسي',
  'Marassi',
  developerAr: 'إعمار مصر',
  developerEn: 'Emaar Misr',
  areaAr: 'الساحل الشمالي',
  areaEn: 'North Coast',
);

class _You extends ApiClient {
  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
  }) async => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {
      'success': true,
      'data': {
        'user': {
          'name': 'Karim',
          'email': 'k@x.eg',
          'phone': '+201000000004',
          'user_type': 'seller',
        },
        'plan': {
          'name_en': 'Growth',
          'name_ar': 'نمو',
          'is_free': false,
          'used': 18,
          'total': 20,
          'remaining': 2,
        },
        'listings': {'live': 3, 'in_review': 1, 'rejected': 0},
        'ai_ads': {'count': 0},
        'notifications': {'unread': 0, 'received_30d': 0, 'places_followed': 0},
      },
    },
  );
}

class _Api extends ListingApi {
  _Api() : super(_You());
  final parsed = <String>[];
  Map<String, dynamic>? created;
  final uploaded = <String>[];
  bool createFails = false;
  final coverCalls = <List<String>>[];
  Map<String, dynamic>? updated;
  int? updatedId;
  bool inReview = true;
  Map<String, dynamic> prop = {
    'id': 9,
    'property_type': 'chalet',
    'property_status': 'for_sale',
    'compound': {'id': 4, 'name_ar': 'مراسي', 'name_en': 'Marassi'},
    'bedrooms': 3,
    'bathrooms': 2,
    'size': '165.00',
    'price': '11500000.00',
    'title_en': 'Lagoon chalet',
    'title_ar': 'شاليه لاجون',
    'content_en': 'Ready to move',
    'content_ar': 'جاهز',
    'images': ['https://r2/cover.png', 'https://r2/a.jpg'],
    'cover_is_ai': true,
    'payment_options': ['mortgage'],
    'features': ['lagoon_view'],
    'delivery_date': '2020-01-01',
    'finishing': 'fully_finished',
  };

  @override
  Future<DraftReply> parse(String text, ListingDraft draft, String lang) async {
    parsed.add(text);
    if (text.contains('11.5')) {
      return DraftReply(
        draft: {
          'price': 11500000,
          'payment': 'installments',
          'down_payment_percent': 10,
          'installment_years': 7,
        },
        compound: null,
        unknownCompound: false,
        filled: const [
          'price',
          'payment',
          'down_payment_percent',
          'installment_years',
        ],
        missing: const [],
        complete: true,
        question: null,
        replies: const [],
      );
    }
    return const DraftReply(
      draft: {
        'type': 'chalet',
        'status': 'for_sale',
        'bedrooms': 3,
        'size': 165,
        'level': 'Ground · garden',
        'delivery': 'ready',
        'view': 'lagoon_view',
      },
      compound: _marassi,
      unknownCompound: false,
      filled: [
        'type',
        'status',
        'bedrooms',
        'size',
        'level',
        'delivery',
        'view',
        'compound_id',
      ],
      missing: ['price', 'payment'],
      complete: false,
      question: "What's the asking price?",
      replies: [],
    );
  }

  @override
  Future<({String title, String description})> describe(
    ListingDraft d,
    String lang,
  ) async => (
    title: 'Lagoon-front chalet',
    description: 'Three bedrooms, ready to move.',
  );

  @override
  Future<PriceBand> priceBand(ListingDraft d) async =>
      const PriceBand(14, 10400000, 11000000, 11800000, 12900000, 13600000);

  @override
  Future<List<CompoundRef>> compounds() async => const [
    _marassi,
    CompoundRef(5, 'مدينتي', 'Madinaty'),
  ];

  @override
  Future<String> upload(String path) async {
    uploaded.add(path);
    return 'https://r2/$path';
  }

  @override
  Future<String> cover(List<String> sources) async {
    coverCalls.add(sources);
    return 'https://r2/new-cover.png';
  }

  @override
  Future<Map<String, dynamic>> property(int id) async => prop;

  @override
  Future<bool> update(int id, Map<String, dynamic> body) async {
    updatedId = id;
    updated = body;
    return inReview;
  }

  @override
  Future<void> create(Map<String, dynamic> body) async {
    if (createFails) throw Exception('nope');
    created = body;
  }
}

class _Rec implements VoiceRecorder {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> start() async {}
  @override
  Future<String?> stop() async => '/tmp/v.m4a';
  @override
  Future<void> cancel() async {}
  @override
  void dispose() {}
}

class _Voice extends ApiClient {
  @override
  Future<Response> postMultipart(
    String path, {
    required String filePath,
    String fileField = 'file',
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? fields,
    DioMediaType? contentType,
  }) async => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {
      'success': true,
      'data': {
        'id': 3,
        'transcript': 'it is 11.5 million on installments',
        'language': 'en',
      },
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('body: delivery, view, instalments, language and who is listing', () {
    final d = ListingDraft()
      ..type = 'chalet'
      ..compound = _marassi
      ..size = '165'
      ..price = '11,500,000'
      ..bedrooms = 3
      ..delivery = 'ready'
      ..view = 'lagoon_view'
      ..payment = 'installments'
      ..down = '10'
      ..years = '7'
      ..level = 'Ground'
      ..title = 'T'
      ..description = 'D';
    final b = d.toBody(images: ['a'], ar: false, admin: false);
    expect(b['compound_id'], 4);
    expect(b['listing_type'], 'resale');
    expect(b['title_en'], 'T');
    expect(
      b.containsKey('title_ar'),
      isFalse,
    ); // the server translates the other side
    expect(b['features'], ['lagoon_view']);
    expect(b['payment_options'], ['installments']);
    expect(b['down_payment_percent'], 10);
    expect(b['installment_years'], 7);
    expect(b['price'], 11500000);
    expect((b['delivery_date'] as String).length, 10);
    expect(
      d.toBody(images: [], ar: true, admin: true)['listing_type'],
      'primary',
    );
    expect(d.toBody(images: [], ar: true, admin: true)['title_ar'], 'T');
    d.delivery = '2028';
    expect(
      d.toBody(images: [], ar: false, admin: false)['delivery_date'],
      '2028-12-31',
    );

    final plan = d.plan!;
    expect(plan.down, closeTo(1150000, 1));
    expect(plan.monthly, closeTo(10350000 / 84, 1));
  });

  test(
    'apply marks what the assistant filled and a stored draft round-trips',
    () {
      final d = ListingDraft();
      d.apply(
        {
          'type': 'villa',
          'bedrooms': 4,
          'size': 300,
          'down_payment_percent': 20,
        },
        _marassi,
        ['type', 'bedrooms', 'size', 'compound_id', 'down_payment_percent'],
      );
      expect(d.type, 'villa');
      expect(d.bedroomsSet, isTrue);
      expect(
        d.ai,
        containsAll(['type', 'bedrooms', 'size', 'compound', 'down']),
      );
      final back = ListingDraft.fromStore(d.toStore());
      expect(back.type, 'villa');
      expect(back.compound!.nameEn, 'Marassi');
      expect(back.size, '300');
      expect(ListingDraft().isBlank, isTrue);
      expect(back.isBlank, isFalse);
    },
  );

  group('screens', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      Hive.init(
        Directory.systemTemp.createTempSync('jeeran_listing_test').path,
      );
      await Hive.openBox('jeeran_prefs');
    });

    for (final locale in const [Locale('en'), Locale('ar')]) {
      testWidgets('tell Jeeran, fix the form, publish — ${locale.languageCode}', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390 * 3, 2200 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        final api = _Api();
        final host = ValueNotifier<Widget>(const SizedBox());
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('en'), Locale('ar')],
            path: 'assets/translations',
            fallbackLocale: const Locale('en'),
            startLocale: locale,
            saveLocale: false,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: ValueListenableBuilder<Widget>(
                  valueListenable: host,
                  builder: (_, page, _) =>
                      KeyedSubtree(key: ObjectKey(page), child: page),
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump(const Duration(milliseconds: 300));

        Future<void> settle([int ms = 300]) async {
          await tester.pump();
          await tester.pump(Duration(milliseconds: ms));
        }

        // ── start: two ways in, plan line from the real summary
        host.value = ListingFlow(
          api: api,
          youApi: YouApi(_You()),
          recorder: _Rec(),
          voiceApi: VoiceApi(_Voice()),
        );
        await settle();
        expect(find.byKey(const Key('path-ai')), findsOneWidget);
        expect(find.byKey(const Key('path-form')), findsOneWidget);
        expect(find.textContaining('18'), findsWidgets);
        expect(tester.takeException(), isNull);

        // ── the assistant: a sentence fills the card and asks for the price
        await tester.tap(find.byKey(const Key('path-ai')));
        await settle();
        await tester.enterText(
          find.byKey(const Key('ai-input')),
          'chalet in marassi 3 bed 165 m',
        );
        await tester.tap(find.byKey(const Key('ai-send')));
        await settle();
        expect(find.byKey(const Key('action-card')), findsOneWidget);
        expect(find.text('listing.needed'.tr()), findsWidgets);
        expect(
          find.byKey(const Key('review-publish')),
          findsNothing,
        ); // not complete yet
        expect(tester.takeException(), isNull);

        // ── answering by voice completes it
        await tester.tap(find.byKey(const Key('ai-mic')));
        await settle(1200);
        await tester.tap(find.byKey(const Key('ai-mic')));
        await settle(500);
        expect(api.parsed.last, contains('11.5'));
        expect(find.byKey(const Key('review-publish')), findsOneWidget);

        // ── open the form: the assistant's fields carry its mark
        await tester.ensureVisible(find.byKey(const Key('open-form')));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(find.byKey(const Key('open-form')));
        await settle();
        expect(find.text('Jeeran'), findsWidgets);

        // ── step 1 → 2 → 3 (price band is real) → 4
        await tester.tap(find.byKey(const Key('listing-primary')));
        await settle();
        await tester.tap(find.byKey(const Key('listing-primary')));
        await settle();
        expect(find.byKey(const Key('band-card')), findsOneWidget);
        expect(find.byKey(const Key('f-price')), findsOneWidget);
        await tester.tap(find.byKey(const Key('listing-primary')));
        await settle();

        // step 4 needs a photo: add one, "write it for me", continue to review
        expect(find.byKey(const Key('write-for-me')), findsOneWidget);
        await tester.tap(find.byKey(const Key('listing-primary')));
        await settle();
        expect(
          find.byKey(const Key('listing-primary')),
          findsOneWidget,
        ); // blocked: no photo, no text
        await tester.tap(find.byKey(const Key('write-for-me')));
        await settle();
        expect(find.text('Lagoon-front chalet'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // ── review → publish: photos upload first, the body reaches the server, "sent for review"
        final api2 = _Api();
        final d = ListingDraft()
          ..type = 'chalet'
          ..compound = _marassi
          ..size = '165'
          ..price = '11500000'
          ..title = 'Lagoon-front chalet'
          ..description = 'Ready to move'
          ..photos.add(XFile('/tmp/a.jpg'))
          ..photos.add(XFile('/tmp/b.jpg'));
        host.value = ListingFlow(
          api: api2,
          youApi: YouApi(_You()),
          initialDraft: d,
          initialView: ListingView.review,
        );
        await settle(400);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const Key('listing-primary')));
        await settle(400);
        expect(api2.uploaded, ['/tmp/a.jpg', '/tmp/b.jpg']);
        expect(api2.created!['images'], [
          'https://r2//tmp/a.jpg',
          'https://r2//tmp/b.jpg',
        ]);
        expect(api2.created!['compound_id'], 4);
        expect(api2.created!['agent_mobile'], '+201000000004');
        expect(find.text('listing.sent_title'.tr()), findsOneWidget);

        // ── a free Jeeran cover from the selected photos goes first and is flagged
        final api3 = _Api();
        final d3 = ListingDraft()
          ..type = 'chalet'
          ..compound = _marassi
          ..size = '165'
          ..price = '11500000'
          ..title = 'T'
          ..description = 'D'
          ..photos.add(XFile('/tmp/a.jpg'))
          ..photos.add(XFile('/tmp/b.jpg'));
        host.value = ListingFlow(
          api: api3,
          youApi: YouApi(_You()),
          initialDraft: d3,
          initialView: ListingView.form,
          initialStep: 4,
        );
        await settle(400);
        await tester.ensureVisible(find.byKey(const Key('cover-make')));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(find.byKey(const Key('cover-make')));
        await settle(400);
        expect(api3.coverCalls.single, [
          'https://r2//tmp/a.jpg',
          'https://r2//tmp/b.jpg',
        ]);
        expect(find.text('listing.cover_ai_note'.tr()), findsOneWidget);
        await tester.tap(find.byKey(const Key('listing-primary'))); // review
        await settle(400);
        await tester.tap(find.byKey(const Key('listing-primary'))); // publish
        await settle(400);
        expect(api3.created!['images'].first, 'https://r2/new-cover.png');
        expect(api3.created!['cover_is_ai'], true);
        expect(api3.created!['images'].length, 3);

        // "use my photo" drops the flag
        d3.coverUrl = null;
        expect(
          d3.toBody(images: ['x'], ar: false, admin: false)['cover_is_ai'],
          false,
        );

        // ── a seller edits their own listing: loaded, no draft button, nothing clobbered, back to review
        final api4 = _Api();
        host.value = ListingFlow(
          api: api4,
          youApi: YouApi(_You()),
          editId: 9,
          initialView: ListingView.form,
        );
        await settle(400);
        expect(find.text('listing.edit_title'.tr()), findsOneWidget);
        expect(find.byKey(const Key('save-draft')), findsNothing);
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.byKey(const Key('listing-primary')));
          await settle(300);
        }
        expect(find.byKey(const Key('cover-card')), findsOneWidget);
        await tester.tap(find.byKey(const Key('listing-primary'))); // review
        await settle(400);
        await tester.tap(
          find.byKey(const Key('listing-primary')),
        ); // save changes
        await settle(400);
        expect(api4.updatedId, 9);
        final u = api4.updated!;
        expect(u.containsKey('listing_type'), isFalse);
        expect(
          u.containsKey('payment_options'),
          isFalse,
        ); // mortgage was not touched
        expect(u['images'], ['https://r2/cover.png', 'https://r2/a.jpg']);
        expect(u['cover_is_ai'], true);
        expect(u['features'], ['lagoon_view']);
        expect(find.text('listing.edit_review_title'.tr()), findsOneWidget);
      });
    }
  });
}
