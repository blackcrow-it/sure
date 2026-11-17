import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// The app follows device preferences. UI and HTTP use the same supported-locale
/// resolution, including regional matches and the English fallback. Resolve on
/// every request so background work also observes device language changes.
class AppLocale {
  static Locale resolve(
    List<Locale>? preferredLocales,
    Iterable<Locale> supportedLocales,
  ) =>
      basicLocaleListResolution(preferredLocales, supportedLocales);

  static Locale get current => resolve(
        WidgetsFlutterBinding.ensureInitialized().platformDispatcher.locales,
        AppLocalizations.supportedLocales,
      );
}
