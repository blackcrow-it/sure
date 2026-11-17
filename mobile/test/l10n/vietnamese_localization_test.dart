import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sure_mobile/widgets/typing_indicator.dart';
import 'package:sure_mobile/screens/biometric_lock_screen.dart';
import 'package:sure_mobile/l10n/display_strings.dart';
import 'package:sure_mobile/l10n/sure_upgrader_messages.dart';
import 'package:upgrader/upgrader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sure_mobile/l10n/app_localizations.dart';
import 'package:sure_mobile/screens/intro_screen.dart';
import 'package:sure_mobile/widgets/sync_status_badge.dart';
import 'package:sure_mobile/models/offline_transaction.dart';
import 'package:sure_mobile/widgets/custom_proxy_headers_editor.dart';
import 'package:sure_mobile/models/custom_proxy_header.dart';

void main() {
  test('Vietnamese covers every English message and preserves metadata', () {
    final english = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final vietnamese =
        jsonDecode(File('lib/l10n/app_vi.arb').readAsStringSync())
            as Map<String, dynamic>;
    expect(vietnamese.keys.toSet(), english.keys.toSet());
    for (final key in english.keys
        .where((key) => key.startsWith('@') && key != '@@locale')) {
      expect(vietnamese[key], english[key], reason: key);
    }
    expect(vietnamese['@@locale'], 'vi');
    final placeholders = RegExp(r'{(\w+)(?=[},])');
    for (final key in english.keys.where((key) => !key.startsWith('@'))) {
      final translation = vietnamese[key] as String;
      expect(translation.trim(), isNotEmpty, reason: key);
      expect(
        placeholders.allMatches(translation).map((m) => m.group(1)).toSet(),
        placeholders
            .allMatches(english[key] as String)
            .map((m) => m.group(1))
            .toSet(),
        reason: key,
      );
    }
  });

  for (final locale in [const Locale('vi'), const Locale('vi', 'VN')]) {
    testWidgets('device $locale displays Vietnamese and Material translations',
        (tester) async {
      tester.platformDispatcher.localesTestValue = [locale];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
            builder: (context) => Scaffold(
                    body: Column(children: [
                  Text(AppLocalizations.of(context).loginSignIn),
                  Text(AppLocalizations.of(context)
                      .transactionsListDeletedMulti(3)),
                  Text(AppLocalizations.of(context)
                      .chatConversationGreetingWithName('An')),
                  Text(MaterialLocalizations.of(context).cancelButtonLabel),
                ]))),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('Đã xóa 3 giao dịch'), findsOneWidget);
      expect(find.text('Chào An, tôi có thể giúp gì cho bạn?'), findsOneWidget);
      expect(find.text('Huỷ'), findsOneWidget);
    });
  }

  for (final entry
      in {'en': 'Sign in', 'sv': 'Logga in', 'fr': 'Sign in'}.entries) {
    testWidgets('${entry.key} keeps the existing language or English fallback',
        (tester) async {
      tester.platformDispatcher.localesTestValue = [Locale(entry.key)];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
            builder: (context) =>
                Text(AppLocalizations.of(context).loginSignIn)),
      ));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
    });
  }

  testWidgets('pending badge translates visible and accessible labels',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: SyncStatusBadge(syncStatus: SyncStatus.pending)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Đang chờ'), findsOneWidget);
    expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.label == 'Giao dịch đang chờ đồng bộ'),
        findsOneWidget);
  });

  testWidgets(
      'header validation translates without weakening reserved header checks',
      (tester) async {
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
          body: Form(
              key: form,
              child: CustomProxyHeadersEditor(
                initialHeaders: [
                  CustomProxyHeader(name: 'Authorization', value: 'abc')
                ],
                onChanged: (_) {},
              ))),
    ));
    await tester.pumpAndSettle();
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Header này do ứng dụng quản lý'), findsOneWidget);
  });

  testWidgets(
      'biometric prompt sends Vietnamese native labels and preserves options',
      (tester) async {
    Map<Object?, Object?>? prompt;
    const channel = MethodChannel('plugins.flutter.io/local_auth');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      if (call.method == 'authenticate') {
        prompt = call.arguments as Map<Object?, Object?>;
        return true;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: BiometricLockScreen(onUnlocked: () {}),
    ));
    await tester.pumpAndSettle();
    expect(prompt?['localizedReason'], 'Mở khóa Sure để tiếp tục');
    expect(prompt?['signInTitle'], 'Yêu cầu xác thực');
    expect(prompt?['cancelButton'], 'Hủy');
    expect(prompt?['stickyAuth'], isTrue);
    expect(prompt?['biometricOnly'], isFalse);
  });

  test('update message preserves tokens consumed by Upgrader', () async {
    final l = await AppLocalizations.delegate.load(const Locale('vi', 'VN'));
    final messages = SureUpgraderMessages(l);
    expect(messages.message(UpgraderMessage.title), 'Có bản cập nhật');
    expect(messages.message(UpgraderMessage.body),
        contains('{{appName}} {{currentAppStoreVersion}}'));
    expect(messages.message(UpgraderMessage.body),
        contains('{{currentInstalledVersion}}'));
    expect(
        messages.message(UpgraderMessage.buttonTitleUpdate), 'Cập nhật ngay');
  });

  test('known errors translate while custom server content is preserved',
      () async {
    final l = await AppLocalizations.delegate.load(const Locale('vi'));
    expect(l.displayError('Network unavailable'), 'Không có kết nối mạng');
    expect(l.displayError('Login failed (status 503)'),
        'Đăng nhập thất bại (mã trạng thái 503)');
    expect(l.displayError('Custom server message for An'),
        'Custom server message for An');
    expect(l.accountType('depository'), 'Tài khoản ngân hàng');
    expect(l.accountType('custom_account_type'), 'custom_account_type');
  });

  testWidgets('assistant thinking indicator is localized', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: TypingIndicator()),
    ));
    await tester.pump();
    expect(find.text('Đang suy nghĩ'), findsOneWidget);
  });

  testWidgets('intro screen displays Vietnamese', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: IntroScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Trải nghiệm giới thiệu sắp ra mắt'), findsOneWidget);
  });
}
