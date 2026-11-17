import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sure_mobile/l10n/app_localizations.dart';
import 'package:sure_mobile/models/account.dart';
import 'package:sure_mobile/providers/auth_provider.dart';
import 'package:sure_mobile/providers/categories_provider.dart';
import 'package:sure_mobile/providers/privacy_provider.dart';
import 'package:sure_mobile/providers/transactions_provider.dart';
import 'package:sure_mobile/screens/transaction_form_screen.dart';

class _Auth extends AuthProvider {
  @override
  Future<String?> getValidAccessToken() async => 'test-token';
}

class _Categories extends CategoriesProvider {
  @override
  Future<void> fetchCategories({required String accessToken}) async {}
}

class _Transactions extends TransactionsProvider {
  Map<String, String?>? submitted;

  @override
  Future<bool> createTransaction({
    required String accessToken,
    required String accountId,
    required String name,
    required String date,
    required String amount,
    required String currency,
    required String nature,
    String? notes,
    String? categoryId,
    String? categoryName,
    String? merchantId,
    String? merchantName,
    List<String>? tagIds,
    List<String>? tagNames,
  }) async {
    submitted = {
      'amount': amount,
      'currency': currency,
      'name': name,
      'notes': notes,
      'date': date,
      'nature': nature,
    };
    // Exercise the visible failure path without writing to the local database.
    return false;
  }
}

void main() {
  testWidgets('Vietnamese transaction form preserves currency and API amounts',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final transactions = _Transactions();
    final account = Account(
      id: 'account-1',
      name: 'My USD account',
      balance: 'USD 100.00',
      currency: 'USD',
      accountType: 'depository',
    );
    final today = DateTime.now();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => _Auth()),
        ChangeNotifierProvider<CategoriesProvider>(
            create: (_) => _Categories()),
        ChangeNotifierProvider<TransactionsProvider>.value(value: transactions),
        ChangeNotifierProvider<PrivacyProvider>(
          create: (_) => PrivacyProvider(initialHidden: false),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('vi', 'VN'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: TransactionFormScreen(account: account)),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Giao dịch mới'), findsOneWidget);
    expect(find.text('My USD account'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '1.234,56');
    await tester.tap(find.text('Tạo giao dịch'));
    await tester.pumpAndSettle();
    expect(transactions.submitted?['amount'], '1234.56');
    expect(transactions.submitted?['currency'], 'USD');
    expect(transactions.submitted?['name'], 'SureApp');
    expect(transactions.submitted?['nature'], 'expense');
    expect(transactions.submitted?['date'],
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}');
    expect(transactions.submitted?['notes'],
        'Giao dịch này được tạo qua ứng dụng di động.');
    expect(find.text('Không thể tạo giao dịch'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    transactions.dispose();
  });
}
