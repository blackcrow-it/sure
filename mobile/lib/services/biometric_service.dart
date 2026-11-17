import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import '../l10n/app_localizations.dart';
import 'log_service.dart';

class BiometricService {
  static final BiometricService instance = BiometricService._();
  BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Returns true when the platform supports biometrics AND at least one
  /// biometric is enrolled on the device.
  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Returns the list of enrolled biometric types (fingerprint, face, etc.).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Triggers the OS biometric prompt. Returns true if authentication succeeds.
  Future<bool> authenticate(
      {required String reason, required AppLocalizations localizations}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        authMessages: [
          AndroidAuthMessages(
            biometricHint: localizations.biometricHint,
            biometricNotRecognized: localizations.biometricNotRecognized,
            biometricSuccess: localizations.biometricSuccess,
            biometricRequiredTitle: localizations.biometricRequired,
            cancelButton: localizations.commonCancel,
            deviceCredentialsRequiredTitle:
                localizations.biometricCredentialsRequired,
            deviceCredentialsSetupDescription:
                localizations.biometricCredentialsRequired,
            goToSettingsButton: localizations.biometricGoToSettings,
            goToSettingsDescription: localizations.biometricAndroidSetup,
            signInTitle: localizations.biometricAuthenticationRequired,
          ),
          IOSAuthMessages(
            lockOut: localizations.biometricLockout,
            goToSettingsButton: localizations.biometricGoToSettings,
            goToSettingsDescription: localizations.biometricIosSetup,
            cancelButton: localizations.biometricOk,
          ),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      LogService.instance.error(
        'BiometricService',
        'authenticate() failed with ${e.runtimeType}',
      );
      return false;
    }
  }
}
