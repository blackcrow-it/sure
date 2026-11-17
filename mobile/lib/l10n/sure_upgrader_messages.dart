import 'package:upgrader/upgrader.dart';

import 'app_localizations.dart';

class SureUpgraderMessages extends UpgraderMessages {
  SureUpgraderMessages(this.localizations);

  final AppLocalizations localizations;

  @override
  String get title => localizations.updateTitle;

  @override
  String get body => localizations.updateBody(
        '{{appName}}',
        '{{currentAppStoreVersion}}',
        '{{currentInstalledVersion}}',
      );

  @override
  String get buttonTitleUpdate => localizations.updateNow;

  @override
  String get buttonTitleLater => localizations.updateLater;

  @override
  String get releaseNotes => '';
}
