import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localization.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Check if biometrics are available on the device
  static Future<bool> isBiometricAvailable() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (canCheckBiometrics && isDeviceSupported) {
        List<BiometricType> availableBiometrics = 
            await _localAuth.getAvailableBiometrics();
        return availableBiometrics.isNotEmpty;
      }
      return false;
    } on PlatformException catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }
  
  // Authenticate with biometrics
  static Future<bool> authenticateWithBiometrics(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    
    try {
      // First check if device supports biometrics
      if (!await isBiometricAvailable()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.biometricsNotAvailable ?? 
              'Biometric authentication not available on this device'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      
      return await _localAuth.authenticate(
        localizedReason: l10n?.fingerprintAuthReason ?? 
          'Scan your fingerprint to authenticate',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/pattern as fallback
        ),
      );
    } on PlatformException catch (e) {
      print('Error using biometric auth: $e');
      
      String errorMessage;
      switch (e.code) {
        case 'no_fragment_activity':
          errorMessage = 'App needs to be reconfigured. Please restart.';
          break;
        case 'NotAvailable':
        case 'NotEnrolled':
          errorMessage = 'No biometrics enrolled on this device.';
          break;
        case 'LockedOut':
          errorMessage = 'Too many attempts. Try again later.';
          break;
        case 'PermanentlyLockedOut':
          errorMessage = 'Biometrics permanently locked. Use device password.';
          break;
        default:
          errorMessage = 'Authentication error: ${e.message}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.fingerprintAuthError ?? errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }
}
