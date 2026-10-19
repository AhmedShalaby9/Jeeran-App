import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/listing/listing_api.dart';
import 'package:jeeran_flutter/features/listing/listing_draft.dart';
import 'package:jeeran_flutter/features/listing/alert_shortcut_page.dart';
import 'package:jeeran_flutter/features/listing/listing_checklist.dart';
import 'package:jeeran_flutter/features/listing/listing_flow.dart';
import 'package:jeeran_flutter/features/listing/price_alert_api.dart';
import 'package:jeeran_flutter/features/listing/price_shortcut_page.dart';
import 'package:jeeran_flutter/features/listing/shortcut_hub.dart';
import 'package:jeeran_flutter/features/listing/shortcut_page.dart';
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
          'user_type': 'customer',
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
  final priceCalls = <({String text, int? id})>[];
  final updates = <({int id, Map<String, dynamic> body})>[];
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

  List<String> describedWith = [];
  bool describeFails = false;

  @override
  Future<ListingCopy> describe(ListingDraft d, String lang) async {
    describedWith = List.of(d.said);
    if (describeFails) throw Exception('assistant down');
    final ar = lang == 'ar';
    return ListingCopy(
      title: ar ? 'شاليه على اللاجون' : 'Lagoon-front chalet',
      description: ar ? 'ثلاث غرف نوم، جاهز للسكن.' : 'Three bedrooms, ready to move.',
      titleAr: 'شاليه على اللاجون',
      descriptionAr: 'ثلاث غرف نوم، جاهز للسكن.',
      titleEn: 'Lagoon-front chalet',
      descriptionEn: 'Three bedrooms, ready to move.',
    );
  }

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

  static const _a = ListingBrief(11, 'Twinhouse', 'Marassi', 18500000);
  static const _b = ListingBrief(12, 'Apartment', 'Madinaty', 30000);

  @override
  Future<PriceReply> priceChange(
    String text,
    String lang, {
    int? listingId,
  }) async {
    priceCalls.add((text: text, id: listingId));
    if (listingId == null && text.contains('make it')) {
      return const PriceReply(
        question: 'Which one of these?',
        candidates: [_a, _b],
      );
    }
    if (listingId == 11) {
      return const PriceReply(
        listing: _a,
        oldPrice: 18500000,
        newPrice: 9000000,
        changePercent: -51.4,
        savers: 2,
      );
    }
    return const PriceReply(
      listing: _a,
      oldPrice: 18500000,
      newPrice: 18300000,
      changePercent: -1.1,
    );
  }

  Map<String, dynamic>? coverDetails;

  @override
  Future<String> cover(List<String> sources, {Map<String, dynamic>? details}) async {
    coverCalls.add(sources);
    coverDetails = details;
    return 'https://r2/new-cover.png';
  }

  @override
  Future<Map<String, dynamic>> property(int id) async => prop;

  @override
  Future<bool> update(int id, Map<String, dynamic> body) async {
    updatedId = id;
    updated = body;
    updates.add((id: id, body: body));
    return inReview;
  }

  @override
  Future<void> create(Map<String, dynamic> body) async {
    if (createFails) throw Exception('nope');
    created = body;
  }
}

class _Alerts extends PriceAlertApi {
  _Alerts() : super(_You());
  final parsed = <String>[];
  final created = <PriceAlertDraft>[];
  final removed = <int>[];
  static const _marassi = CompoundRef(4, 'مراسي', 'Marassi');

  @override
  Future<AlertReply> parse(
    String text,
    PriceAlertDraft? prev,
    String lang,
  ) async {
    parsed.add(text);
    if (text.contains('11 million')) {
      return AlertReply(
        alert: const PriceAlertDraft(
          compoundId: 4,
          minBedrooms: 3,
          maxPrice: 11000000,
        ),
        compound: _marassi,
        unknownCompound: false,
        complete: true,
        now: const AlertMarket(0, 12400000, 2),
        question: null,
      );
    }
    return AlertReply(
      alert: const PriceAlertDraft(compoundId: 4),
      compound: _marassi,
      unknownCompound: false,
      complete: false,
      now: null,
      question: 'What price should I wait for?',
    );
  }

  @override
  Future<SavedAlert> create(PriceAlertDraft a) async {
    created.add(a);
    return SavedAlert(7, a, _marassi, const AlertMarket(0, 12400000, 2));
  }

  @override
  Future<List<SavedAlert>> list() async => [
    SavedAlert(
      7,
      const PriceAlertDraft(compoundId: 4, minBedrooms: 3, maxPrice: 11000000),
      _marassi,
      const AlertMarket(2, 9900000, 3),
    ),
  ];

  @override
  Future<void> remove(int id) async => removed.add(id);
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

/// Stands in for the gallery: picking photos returns two files.
class _Gallery extends ImagePickerPlatform {
  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async => [XFile('/tmp/a.jpg'), XFile('/tmp/b.jpg')];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  ImagePickerPlatform.instance = _Gallery();

  test('type-specific areas: garden for flats/chalets/duplexes, plot for villas, outdoor for shops', () {
    Map<String, dynamic> body(ListingDraft d) {
      d
        ..compound = _marassi
        ..size = '120'
        ..price = '5,000,000'
        ..title = 'T'
        ..description = 'D';
      return d.toBody(images: ['a'], ar: false, admin: false);
    }

    // an apartment says whether it is a ground-floor unit with a garden, then how big
    var b = body(ListingDraft()..type = 'apartment'..groundGarden = true..garden = '45');
    expect(b['has_garden'], true);
    expect(b['garden_size'], 45);
    b = body(ListingDraft()..type = 'duplex'..groundGarden = false..garden = '45');
    expect(b['has_garden'], false);
    expect(b.containsKey('garden_size'), isFalse); // "no garden" sends no size
    b = body(ListingDraft()..type = 'chalet');
    expect(b.containsKey('has_garden'), isFalse); // not answered: nothing sent

    // every kind of villa: the plot next to the built-up area
    for (final t in ListingDraft.villaTypes) {
      b = body(ListingDraft()..type = t..land = '400');
      expect(b['land_size'], 400, reason: t);
      expect(b['size'], 120, reason: t);
    }
    expect(body(ListingDraft()..type = 'apartment'..land = '400').containsKey('land_size'), isFalse);

    // a shop: an outdoor area or not, and its size
    b = body(ListingDraft()..type = 'shop'..outdoor = true..outdoorSize = '30');
    expect(b['has_outdoor'], true);
    expect(b['outdoor_size'], 30);
    b = body(ListingDraft()..type = 'shop'..outdoor = false..outdoorSize = '30');
    expect(b['has_outdoor'], false);
    expect(b.containsKey('outdoor_size'), isFalse);

    // they survive a saved draft
    final back = ListingDraft.fromStore((ListingDraft()..type = 'shop'..outdoor = true..outdoorSize = '30'..land = '9'..groundGarden = true).toStore());
    expect((back.outdoor, back.outdoorSize, back.land, back.groundGarden), (true, '30', '9', true));
  });

  test('what the chat understood about areas fills the draft and shows in the checklist', () {
    final villa = ListingDraft()..type = 'villa';
    villa.apply({'land_size': 450, 'size': 300}, null, ['land_size', 'size']);
    expect((villa.land, villa.size), ('450', '300'));
    expect(villa.ai, contains('land'));
    expect(checklistRows(villa, admin: false, ar: false, paymentSet: false).any((r) => r.key == 'land' && r.value == '450 m²'), isTrue);

    final flat = ListingDraft()..type = 'apartment';
    flat.apply({'garden_size': 40}, null, ['garden_size']); // a size alone means it has a garden
    expect((flat.groundGarden, flat.garden), (true, '40'));
    expect(checklistRows(flat, admin: false, ar: false, paymentSet: false).firstWhere((r) => r.key == 'garden').value, endsWith('40 m²'));
    flat.apply({'has_garden': false}, null, ['has_garden']);
    expect(flat.groundGarden, false);

    final shop = ListingDraft()..type = 'shop';
    shop.apply({'has_outdoor': true, 'outdoor_size': 25}, null, ['has_outdoor', 'outdoor_size']);
    expect((shop.outdoor, shop.outdoorSize), (true, '25'));
    expect(checklistRows(shop, admin: false, ar: false, paymentSet: false).firstWhere((r) => r.key == 'outdoor').value, endsWith('25 m²'));
    // and the parser gets them back with the next sentence
    expect(shop.toParserJson()['outdoor_size'], 25);
  });

  test('a resale gives its down payment as an amount and its price is the total contract value', () {
    final d = ListingDraft()
      ..type = 'chalet'
      ..compound = _marassi
      ..size = '165'
      ..price = '8,000,000'
      ..payment = 'installments'
      ..downAmount = '2,000,000'
      ..years = '5'
      ..title = 'T'
      ..description = 'D'
      ..listingType = 'resale';
    final b = d.toBody(images: ['a'], ar: false, admin: false);
    expect(b['listing_type'], 'resale');
    expect(b['price'], 8000000);
    expect(b['down_payment_amount'], 2000000);
    expect(b.containsKey('down_payment_percent'), isFalse); // the server derives it
    expect(b['installment_years'], 5);
    final plan = d.plan!;
    expect(plan.down, 2000000);
    expect(plan.total, 8000000);
    expect(plan.monthly, closeTo(6000000 / 60, 0.01));
    // more than the whole price is not a plan
    d.downAmount = '9,000,000';
    expect(d.plan, isNull);
    // the assistant only heard "25% down": that share of the price stands in until an amount is typed
    d.downAmount = '';
    d.down = '25';
    expect(d.plan!.down, 2000000);
    // a primary unit keeps its percentage
    d.listingType = 'primary';
    final p = d.toBody(images: ['a'], ar: false, admin: false);
    expect(p['down_payment_percent'], 25);
    expect(p.containsKey('down_payment_amount'), isFalse);
  });

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
      ..description = 'D'
      ..listingType = 'primary';
    // only an admin lists a primary unit: anyone else's draft goes out as a resale, whatever it says
    expect(d.toBody(images: ['a'], ar: false, admin: false)['listing_type'], 'resale');
    final b = d.toBody(images: ['a'], ar: false, admin: true);
    expect(b['compound_id'], 4);
    expect(b['listing_type'], 'primary');
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
      d.toBody(images: [], ar: false, admin: true)['delivery_date'],
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
        // PACKAGES DISABLED: no "N of M listings used" line any more
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
        // the text is complete but the card still needs photos: it says so, and offers Upload
        expect(find.byKey(const Key('photos-hint')), findsOneWidget);
        expect(find.byKey(const Key('review-publish')), findsNothing);
        expect(find.byKey(const Key('media-photos')), findsOneWidget);
        expect(find.byKey(const Key('media-plan')), findsOneWidget);
        expect(find.byKey(const Key('media-video')), findsOneWidget);
        await tester.ensureVisible(find.byKey(const Key('media-photos')));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('media-photos')),
            matching: find.text('listing.upload'.tr()),
          ),
        );
        await settle();
        expect(find.byKey(const Key('photos-hint')), findsNothing);
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

        // step 4: the title and description arrive by themselves (marked as Jeeran's); only the photo is still needed
        await settle();
        expect(
          find.text(locale.languageCode == 'ar' ? 'شاليه على اللاجون' : 'Lagoon-front chalet'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('write-for-me')), findsNothing); // already written
        await tester.tap(find.byKey(const Key('listing-primary')));
        await settle();
        expect(
          find.byKey(const Key('listing-primary')),
          findsOneWidget,
        ); // blocked: no photo
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

        // ── nobody pressed "Write it for me": reaching the last step writes the title and description
        final apiW = _Api();
        final dW = ListingDraft()
          ..type = 'chalet'
          ..compound = _marassi
          ..size = '165'
          ..price = '11500000';
        host.value = ListingFlow(
          api: apiW,
          youApi: YouApi(_You()),
          initialDraft: dW,
          initialView: ListingView.form,
          initialStep: 3,
        );
        await settle(400);
        await tester.tap(find.byKey(const Key('listing-primary'))); // to step 4
        await settle(400);
        await settle(400);
        expect(dW.title, isNotEmpty);
        expect(dW.description, isNotEmpty);
        expect(dW.ai, containsAll(['title', 'desc']));
        // both languages are written and shown
        expect(dW.titleAlt, isNotEmpty);
        expect(dW.descriptionAlt, isNotEmpty);
        expect(find.byKey(const Key('alt-language')), findsOneWidget);
        expect(find.byKey(const Key('f-title-alt')), findsOneWidget);
        final bodyW = dW.toBody(images: ['x'], ar: locale.languageCode == 'ar', admin: false);
        expect(bodyW['title_ar'], 'شاليه على اللاجون');
        expect(bodyW['title_en'], 'Lagoon-front chalet');
        expect(bodyW['content_ar'], isNotEmpty);
        expect(bodyW['content_en'], isNotEmpty);
        // the assistant is down: a plain factual text, never an empty box
        final apiD = _Api()..describeFails = true;
        final dD = ListingDraft()
          ..type = 'chalet'
          ..compound = _marassi
          ..size = '165'
          ..price = '11500000';
        host.value = ListingFlow(
          api: apiD,
          youApi: YouApi(_You()),
          initialDraft: dD,
          initialView: ListingView.form,
          initialStep: 3,
        );
        await settle(400);
        await tester.tap(find.byKey(const Key('listing-primary')));
        await settle(400);
        await settle(400);
        expect(dD.title, isNotEmpty);
        expect(dD.description, isNotEmpty);
        // what the seller already wrote is never replaced
        final dK = ListingDraft()
          ..type = 'chalet'
          ..compound = _marassi
          ..size = '165'
          ..price = '11500000'
          ..title = 'My own title';
        host.value = ListingFlow(
          api: _Api(),
          youApi: YouApi(_You()),
          initialDraft: dK,
          initialView: ListingView.form,
          initialStep: 3,
        );
        await settle(400);
        await tester.tap(find.byKey(const Key('listing-primary')));
        await settle(400);
        await settle(400);
        expect(dK.title, 'My own title');

        // ── the review is editable: a change there reaches the server, contact details included
        final api6 = _Api();
        final d6 = ListingDraft()
          ..type = 'chalet'
          ..compound = _marassi
          ..size = '165'
          ..price = '11500000'
          ..title = 'T'
          ..description = 'D'
          ..photos.add(XFile('/tmp/a.jpg'));
        host.value = ListingFlow(
          api: api6,
          youApi: YouApi(_You()),
          initialDraft: d6,
          initialView: ListingView.review,
        );
        await settle(400);
        expect(find.byKey(const Key('f-contact-phone')), findsOneWidget);
        expect(d6.contactPhone, '+201000000004'); // from the account
        await tester.ensureVisible(find.byKey(const Key('f-size')));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.enterText(find.byKey(const Key('f-size')), '180');
        await tester.ensureVisible(find.byKey(const Key('f-contact-phone')));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.enterText(find.byKey(const Key('f-contact-phone')), '+201555555555');
        await tester.pump(const Duration(milliseconds: 300));
        expect(d6.size, '180');
        await tester.ensureVisible(find.byKey(const Key('listing-primary')));
        await tester.tap(find.byKey(const Key('listing-primary'))); // publish
        await settle(400);
        await settle(400);
        expect(api6.created!['size'], 180);
        expect(api6.created!['agent_mobile'], '+201555555555');
        expect(api6.created!['agent_whatsapp'], '+201555555555');

        // ── nobody pressed "make a cover": reaching the review makes one, once, and publishing waits for it
        final api5 = _Api();
        final d5 = ListingDraft()
          ..type = 'chalet'
          ..compound = _marassi
          ..size = '165'
          ..price = '11500000'
          ..title = 'T'
          ..description = 'D'
          ..photos.add(XFile('/tmp/a.jpg'));
        host.value = ListingFlow(
          api: api5,
          youApi: YouApi(_You()),
          initialDraft: d5,
          initialView: ListingView.form,
          initialStep: 4,
        );
        await settle(400);
        await tester.tap(find.byKey(const Key('listing-primary'))); // review
        await settle(400);
        await settle(400);
        expect(api5.coverCalls, hasLength(1));
        // the server reads compound, developer and area itself; the app sends the id and the facts
        expect(api5.coverDetails!['compound_id'], 4);
        expect(api5.coverDetails!['price'], 11500000);
        expect(api5.coverDetails!['type'], 'chalet');
        expect(d5.coverUrl, 'https://r2/new-cover.png');
        await tester.tap(find.byKey(const Key('listing-primary'))); // publish
        await settle(400);
        expect(api5.created!['images'].first, 'https://r2/new-cover.png');
        expect(api5.created!['cover_is_ai'], true);

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
        expect(u['listing_type'], 'resale'); // an edit keeps the sale type, and lets the seller change it
        expect(
          u.containsKey('payment_options'),
          isFalse,
        ); // mortgage was not touched
        expect(u['images'], ['https://r2/cover.png', 'https://r2/a.jpg']);
        expect(u['cover_is_ai'], true);
        expect(u['features'], ['lagoon_view']);
        expect(find.text('listing.edit_review_title'.tr()), findsOneWidget);

        // ── the "Do it" hub offers both shortcuts
        final apiH = _Api();
        host.value = ShortcutHub(
          api: apiH,
          recorder: _Rec(),
          voiceApi: VoiceApi(_Voice()),
        );
        await settle(300);
        expect(find.byKey(const Key('tile-alert')), findsNothing); // no price-alert tile any more
        expect(
          find.byKey(const Key('tile-list')),
          findsNothing,
        ); // a buyer cannot list
        expect(find.byKey(const Key('tile-price')), findsNothing);
        host.value = ShortcutHub(
          api: apiH,
          canList: true,
          recorder: _Rec(),
          voiceApi: VoiceApi(_Voice()),
        );
        await settle(300);
        expect(find.byKey(const Key('tile-list')), findsOneWidget);
        expect(find.byKey(const Key('tile-price')), findsOneWidget);
        expect(find.byKey(const Key('tile-alert')), findsNothing);

        // ── the missing rows can be filled right in the chat, no assistant needed
        var formOpened = 0;
        final apiS = _Api();
        host.value = ShortcutPage(
          draft: ListingDraft(),
          api: apiS,
          recorder: _Rec(),
          voiceApi: VoiceApi(_Voice()),
          onClose: () {},
          onReview: () {},
          onOpenForm: () => formOpened++,
        );
        await settle(300);
        // tapping an example sends it straight away; it is not just copied into the box
        await tester.tap(find.text('“${'listing.ai_ex1'.tr()}”'));
        await settle();
        expect(apiS.parsed, ['listing.ai_ex1'.tr()]);
        await tester.enterText(
          find.byKey(const Key('ai-input')),
          'chalet in marassi 3 bed 165 m',
        );
        await tester.tap(find.byKey(const Key('ai-send')));
        await settle();
        Future<void> openRow(String label) async {
          final row = find.byKey(Key('row-${label.tr()}'));
          await tester.ensureVisible(row);
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(row);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
        }

        Future<void> done() async {
          await tester.tap(find.byKey(const Key('field-done')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
        }

        // price (a resale's "Total contract value"): a sheet with a number box; the card updates behind it
        await openRow('listing.f_contract_total');
        await tester.enterText(find.byKey(const Key('field-price')), '9000000');
        await tester.pump();
        await done();
        expect(find.text('EGP 9,000,000'), findsOneWidget);
        // payment is never assumed: it stays needed until chosen
        expect(find.byKey(const Key('review-publish')), findsNothing);
        await openRow('listing.f_payment');
        await tester.tap(find.text('listing.cash'.tr()).last);
        await tester.pump();
        await done();
        // type can be changed too
        await openRow('listing.f_type');
        await tester.tap(find.text('listing.t_villa'.tr()));
        await tester.pump();
        await done();
        expect(find.textContaining('listing.t_villa'.tr()), findsWidgets);
        // text is complete, so the card now asks only for photos
        expect(find.byKey(const Key('photos-hint')), findsOneWidget);
        expect(formOpened, 0); // none of it left the chat

        for (final writerDown in [false, true]) {
          // ── Review & publish from the card: the title and description are written first, then the review opens
          final apiR = _Api()..describeFails = writerDown;
          host.value = ListingFlow(
            api: apiR,
            youApi: YouApi(_You()),
            recorder: _Rec(),
            voiceApi: VoiceApi(_Voice()),
          );
          await settle();
          await tester.tap(find.byKey(const Key('path-ai')));
          await settle();
          await tester.enterText(
            find.byKey(const Key('ai-input')),
            'chalet in marassi 3 bed 165 m',
          );
          await tester.tap(find.byKey(const Key('ai-send')));
          await settle();
          for (final label in ['listing.f_contract_total', 'listing.f_payment']) {
            final row = find.byKey(Key('row-${label.tr()}'));
            await tester.ensureVisible(row);
            await tester.pump(const Duration(milliseconds: 400));
            await tester.tap(row);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
            if (label == 'listing.f_contract_total') {
              await tester.enterText(
                find.byKey(const Key('field-price')),
                '9000000',
              );
            } else {
              await tester.tap(find.text('listing.cash'.tr()).last);
            }
            await tester.pump();
            await tester.tap(find.byKey(const Key('field-done')));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
          }
          await tester.ensureVisible(find.byKey(const Key('media-photos')));
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(
            find.descendant(
              of: find.byKey(const Key('media-photos')),
              matching: find.text('listing.upload'.tr()),
            ),
          );
          await settle();
          await tester.ensureVisible(find.byKey(const Key('review-publish')));
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(find.byKey(const Key('review-publish')));
          await settle(600);
          await settle(600);
          expect(find.text('listing.how_buyers'.tr()), findsOneWidget);
          if (writerDown) {
            // the assistant could not write it: a plain title from the card is used instead
            expect(find.textContaining('listing.t_chalet'.tr()), findsWidgets);
          } else {
            // the preview and the editable title field both show it
            expect(
              find.text(locale.languageCode == 'ar' ? 'شاليه على اللاجون' : 'Lagoon-front chalet'),
              findsWidgets,
            );
            // the review shows everything, editable: every section, both languages and the contact details
            for (final n in [1, 2, 3, 4, 5]) {
              expect(find.byKey(Key('review-section-$n')), findsOneWidget);
            }
            expect(find.byKey(const Key('f-title-alt')), findsOneWidget);
            expect(find.byKey(const Key('f-contact-phone')), findsOneWidget);
            // the seller's own words went along, so details without a field reach the copy
            expect(
              apiR.describedWith,
              contains('chalet in marassi 3 bed 165 m'),
            );
          }
          expect(tester.takeException(), isNull);
        }

        // ── change a price: pick the listing, see the change, apply, undo; a second request is cancelled
        final apiP = _Api();
        host.value = PriceShortcutPage(
          api: apiP,
          recorder: _Rec(),
          voiceApi: VoiceApi(_Voice()),
        );
        await settle(300);
        await tester.enterText(
          find.byKey(const Key('ai-input')),
          'make it 9 million',
        );
        await tester.tap(find.byKey(const Key('ai-send')));
        await settle(300);
        expect(find.byKey(const Key('pick-11')), findsOneWidget);
        expect(
          find.byKey(const Key('price-card')),
          findsNothing,
        ); // nothing proposed until the listing is known
        await tester.ensureVisible(find.byKey(const Key('pick-11')));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(find.byKey(const Key('pick-11')));
        await settle(300);
        expect(apiP.priceCalls.last.id, 11);
        expect(
          apiP.priceCalls.last.text,
          'make it 9 million',
        ); // the same request, now with the listing
        expect(find.byKey(const Key('price-card')), findsOneWidget);
        expect(
          find.textContaining('51'),
          findsWidgets,
        ); // a big change is flagged
        expect(apiP.updates, isEmpty); // nothing happens before the tap
        await tester.ensureVisible(find.byKey(const Key('price-apply')));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(find.byKey(const Key('price-apply')));
        await settle(300);
        expect(apiP.updates.single.id, 11);
        expect(apiP.updates.single.body, {'price': 9000000.0});
        expect(find.byKey(const Key('price-undo')), findsOneWidget);
        await tester.ensureVisible(find.byKey(const Key('price-undo')));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(find.byKey(const Key('price-undo')));
        await settle(300);
        expect(apiP.updates.last.body, {'price': 18500000.0});
        expect(find.byKey(const Key('price-card')), findsNothing);
        await tester.enterText(find.byKey(const Key('ai-input')), 'lower 200k');
        await tester.tap(find.byKey(const Key('ai-send')));
        await settle(300);
        await tester.ensureVisible(find.byKey(const Key('price-cancel')));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(find.byKey(const Key('price-cancel')));
        await settle(300);
        expect(apiP.updates.length, 2); // apply + undo only

        // ── a price alert: asked for the missing price, then the card, turn on, undo
        final alerts = _Alerts();
        host.value = AlertShortcutPage(
          api: alerts,
          recorder: _Rec(),
          voiceApi: VoiceApi(_Voice()),
        );
        await settle(300);
        await tester.enterText(
          find.byKey(const Key('ai-input')),
          'watch Marassi',
        );
        await tester.tap(find.byKey(const Key('ai-send')));
        await settle(300);
        expect(
          find.byKey(const Key('alert-card')),
          findsNothing,
        ); // incomplete: it asks instead
        expect(find.text('What price should I wait for?'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('ai-input')),
          'a 3 bed under 11 million',
        );
        await tester.tap(find.byKey(const Key('ai-send')));
        await settle(300);
        expect(find.byKey(const Key('alert-card')), findsOneWidget);
        expect(alerts.created, isEmpty); // nothing is saved before the tap
        await tester.ensureVisible(find.byKey(const Key('alert-on')));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(find.byKey(const Key('alert-on')));
        await settle(300);
        expect(alerts.created.single.maxPrice, 11000000);
        expect(alerts.created.single.minBedrooms, 3);
        expect(alerts.created.single.compoundId, 4);
        await tester.ensureVisible(find.byKey(const Key('alert-undo')));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(find.byKey(const Key('alert-undo')));
        await settle(300);
        expect(alerts.removed, [7]);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('price-card')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
