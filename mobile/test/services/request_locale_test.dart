import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sure_mobile/main.dart';
import 'package:sure_mobile/services/preferences_service.dart';
import 'package:sure_mobile/models/custom_proxy_header.dart';
import 'package:sure_mobile/services/api_config.dart';
import 'package:sure_mobile/services/auth_service.dart';
import 'package:sure_mobile/services/chat_service.dart';
import 'package:sure_mobile/services/transactions_service.dart';

class _RealHttp extends HttpOverrides {}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ApiConfig.clearApiKeyAuth();
    ApiConfig.setCustomProxyHeaders([
      CustomProxyHeader(name: 'X-Proxy-Token', value: 'proxy-token'),
      CustomProxyHeader(name: 'accept-language', value: 'fr'),
    ]);
  });
  tearDown(() {
    binding.platformDispatcher.clearLocalesTestValue();
    ApiConfig.clearApiKeyAuth();
    ApiConfig.setCustomProxyHeaders([]);
    ApiConfig.setBaseUrl(ApiConfig.defaultBaseUrl);
  });

  for (final (locales, expected) in [
    ([const Locale('vi')], 'vi'),
    ([const Locale('vi', 'VN')], 'vi'),
    ([const Locale('en', 'US')], 'en'),
    ([const Locale('sv', 'SE')], 'sv'),
    ([const Locale('fr', 'FR')], 'en'),
    ([const Locale('fr'), const Locale('vi', 'VN')], 'vi'),
  ]) {
    for (final apiKey in [false, true]) {
      test('chat HTTP resolves $locales to $expected with apiKey=$apiKey',
          () async {
        binding.platformDispatcher.localesTestValue = locales;
        if (apiKey) ApiConfig.setApiKeyAuth('api-secret');
        await _captureRequest(
            () => ChatService().createChat(
                  accessToken: 'bearer-secret',
                  initialMessage: 'Tài khoản USD của tôi',
                ), (request, body) {
          expect(request.uri.path, '/api/v1/chats');
          expect(request.headers.value('accept-language'), expected);
          expect(request.headers.value('x-proxy-token'), 'proxy-token');
          expect(request.headers.value('accept'), 'application/json');
          expect(request.headers.contentType?.mimeType, 'application/json');
          expect(request.headers.value('authorization'),
              apiKey ? null : 'Bearer bearer-secret');
          expect(
              request.headers.value('x-api-key'), apiKey ? 'api-secret' : null);
          expect(jsonDecode(body), {'message': 'Tài khoản USD của tôi'});
        });
        expect(ApiConfig.jsonHeaders()['Accept-Language'], expected);
        expect(ApiConfig.htmlHeaders()['Accept-Language'], expected);
      });
    }
  }

  test('requests follow device changes without restarting or caching locale',
      () async {
    for (final (locale, expected) in [
      (const Locale('vi', 'VN'), 'vi'),
      (const Locale('sv'), 'sv'),
      (const Locale('ja'), 'en')
    ]) {
      binding.platformDispatcher.localesTestValue = [locale];
      await _captureRequest(() => ChatService().getChats(accessToken: 'token'),
          (request, body) {
        expect(request.headers.value('accept-language'), expected);
      });
    }
  });

  test('API key sign-in uses locale and proxy without stale auth headers',
      () async {
    binding.platformDispatcher.localesTestValue = [const Locale('vi', 'VN')];
    await _captureRequest(
        () => AuthService().loginWithApiKey(apiKey: 'new-key'),
        (request, body) {
      expect(request.headers.value('accept-language'), 'vi');
      expect(request.headers.value('x-api-key'), 'new-key');
      expect(request.headers.value('authorization'), isNull);
      expect(request.headers.value('x-proxy-token'), 'proxy-token');
    });
  });

  test('login language is a header and does not set a persisted server locale',
      () async {
    binding.platformDispatcher.localesTestValue = [const Locale('vi')];
    await _captureRequest(
        () => AuthService().login(
            email: 'an@example.test',
            password: 'test-password',
            deviceInfo: {}), (request, body) {
      expect(request.headers.value('accept-language'), 'vi');
      expect(jsonDecode(body), {
        'email': 'an@example.test',
        'password': 'test-password',
        'device': {}
      });
    });
  });

  test('transaction request preserves canonical amount and currency', () async {
    binding.platformDispatcher.localesTestValue = [const Locale('vi', 'VN')];
    await _captureRequest(
        () => TransactionsService().createTransaction(
            accessToken: 'token',
            accountId: 'account-1',
            name: 'Coffee',
            date: '2026-11-17',
            amount: '1234.56',
            currency: 'USD',
            nature: 'expense'), (request, body) {
      expect(request.headers.value('accept-language'), 'vi');
      final transaction = jsonDecode(body)['transaction'];
      expect(transaction['amount'], '1234.56');
      expect(transaction['currency'], 'USD');
      expect(transaction['date'], '2026-11-17');
      expect(transaction.containsKey('locale'), isFalse);
    });
  });

  testWidgets('SureApp and chat HTTP follow the same live resolved locale',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.resetForTest();
    const channels = [
      'dev.fluttercommunity.plus/connectivity',
      'dev.fluttercommunity.plus/connectivity_status',
      'com.llfbandit.app_links/messages',
      'com.llfbandit.app_links/events',
    ];
    for (final name in channels) {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), (call) async {
        if (call.method == 'check') return ['none'];
        return null;
      });
    }
    addTearDown(() {
      for (final name in channels) {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(MethodChannel(name), null);
      }
    });
    tester.platformDispatcher.localesTestValue = [const Locale('vi', 'VN')];
    await tester.pumpWidget(const SureApp());
    await tester.pumpAndSettle();
    for (final (locale, expected) in [
      (const Locale('vi', 'VN'), 'vi'),
      (const Locale('sv'), 'sv'),
      (const Locale('fr'), 'en')
    ]) {
      tester.platformDispatcher.localesTestValue = [locale];
      await tester.pumpAndSettle();
      expect(
          Localizations.localeOf(tester.element(find.byType(AppWrapper)))
              .languageCode,
          expected);
      await tester.runAsync(() => _captureRequest(
            () => ChatService().getChats(accessToken: 'token'),
            (request, body) =>
                expect(request.headers.value('accept-language'), expected),
          ));
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _captureRequest(Future<Object?> Function() send,
    void Function(HttpRequest, String) verify) async {
  await HttpOverrides.runWithHttpOverrides(() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    ApiConfig.setBaseUrl('http://${server.address.host}:${server.port}');
    final received = server.first.then((request) async {
      final body = await utf8.decoder.bind(request).join();
      request.response
        ..statusCode = 422
        ..headers.contentType = ContentType.json
        ..write('{"error":"test response"}');
      await request.response.close();
      return (request, body);
    });
    try {
      await send();
      final (request, body) = await received;
      verify(request, body);
    } finally {
      await server.close(force: true);
    }
  }, _RealHttp());
}
