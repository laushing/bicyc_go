import 'package:flutter/material.dart';
import '../../l10n/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_sharing_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../services/biometric_service.dart';

class SettingsScreen extends StatefulWidget {
  final Function(Locale) onLocaleChanged;
  final Locale currentLocale;

  const SettingsScreen({
    super.key, 
    required this.onLocaleChanged, 
    required this.currentLocale
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _selectedLanguage;
  bool _locationSharingEnabled = false;
  bool _joinGroupRidesAutomatically = false;
  double _sharingRadius = 2.0; // in kilometers
  bool _fingerprintAuthEnabled = false;
  final LocationSharingService _locationSharingService = LocationSharingService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.currentLocale.languageCode;
    _loadSettings();
    _checkBiometricAvailability();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locationSharingEnabled = prefs.getBool('location_sharing_enabled') ?? false;
      _joinGroupRidesAutomatically = prefs.getBool('join_group_rides_auto') ?? false;
      _sharingRadius = prefs.getDouble('sharing_radius') ?? 2.0;
      _fingerprintAuthEnabled = prefs.getBool('fingerprint_auth_enabled') ?? false;
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_sharing_enabled', _locationSharingEnabled);
    await prefs.setBool('join_group_rides_auto', _joinGroupRidesAutomatically);
    await prefs.setDouble('sharing_radius', _sharingRadius);
    await prefs.setBool('fingerprint_auth_enabled', _fingerprintAuthEnabled);
  }

  Future<void> _changeLanguage(String languageCode) async {
    setState(() {
      _selectedLanguage = languageCode;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    
    widget.onLocaleChanged(Locale(languageCode));
  }
  
  void _toggleLocationSharing(bool value) {
    setState(() {
      _locationSharingEnabled = value;
    });
    _saveSettings();
    
    if (value) {
      _locationSharingService.startSimulation();
    } else {
      _locationSharingService.stopSimulation();
    }
  }
  
  void _toggleAutoJoinRides(bool value) {
    setState(() {
      _joinGroupRidesAutomatically = value;
    });
    _saveSettings();
  }
  
  void _updateSharingRadius(double value) {
    setState(() {
      _sharingRadius = value;
    });
    _saveSettings();
  }

  Future<void> _checkBiometricAvailability() async {
    bool canCheckBiometrics;
    List<BiometricType> availableBiometrics = [];
    
    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
      
      if (canCheckBiometrics) {
        availableBiometrics = await _localAuth.getAvailableBiometrics();
      }
    } on PlatformException catch (e) {
      canCheckBiometrics = false;
      print('Error checking biometrics: $e');
    }
    
    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
      _availableBiometrics = availableBiometrics;
    });
  }
  
  Future<bool> _authenticateWithBiometrics(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    bool authenticated = false;
    
    try {
      // First check if we can authenticate
      bool canAuthenticate = await _localAuth.canCheckBiometrics && 
                             await _localAuth.isDeviceSupported();
      
      if (!canAuthenticate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.biometricsNotAvailable ?? 
              'Biometric authentication not available on this device'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      
      authenticated = await _localAuth.authenticate(
        localizedReason: l10n?.fingerprintAuthReason ?? 
          'Scan your fingerprint to authenticate',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Error using biometric auth: $e');
      // Show a more user-friendly message based on the specific error
      String errorMessage = 'Authentication error';
      
      if (e.code == 'no_fragment_activity') {
        errorMessage = 'App configuration error - please contact support';
      } else if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        errorMessage = 'Biometric authentication not set up on this device';
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        errorMessage = 'Too many attempts - biometric authentication locked';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.fingerprintAuthError ?? errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    return authenticated;
  }

  Future<void> _toggleFingerprintAuth(bool value) async {
    if (value) {
      // Check if biometrics are available first
      bool isBiometricAvailable = await BiometricService.isBiometricAvailable();
      
      if (!isBiometricAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.biometricsNotAvailable ?? 
              'Biometric authentication not available on this device'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Try to authenticate
      final authenticated = await BiometricService.authenticateWithBiometrics(context);
      
      if (authenticated) {
        setState(() {
          _fingerprintAuthEnabled = true;
        });
        await _saveSettings();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.fingerprintEnabled ?? 
              'Fingerprint authentication enabled'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      setState(() {
        _fingerprintAuthEnabled = false;
      });
      await _saveSettings();
    }
  }
  
  @override
  void dispose() {
    _locationSharingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.settings ?? 'Settings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(l10n?.language ?? 'Language'),
                      trailing: const Icon(Icons.language),
                    ),
                    const Divider(),
                    RadioListTile<String>(
                      title: const Text('English'),
                      value: 'en',
                      groupValue: _selectedLanguage,
                      onChanged: (value) {
                        if (value != null) _changeLanguage(value);
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('中文 (Chinese)'),
                      value: 'zh',
                      groupValue: _selectedLanguage,
                      onChanged: (value) {
                        if (value != null) _changeLanguage(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(l10n?.locationSharing ?? 'Location Sharing'),
                      trailing: const Icon(Icons.location_on),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: Text(l10n?.enableLocationSharing ?? 'Enable Location Sharing'),
                      subtitle: Text(l10n?.shareLocationWithOtherCyclists ?? 
                                'Share your location with other cyclists'),
                      value: _locationSharingEnabled,
                      onChanged: _toggleLocationSharing,
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n?.sharingRadius ?? 'Sharing Radius'),
                          Slider(
                            min: 0.5,
                            max: 5.0,
                            divisions: 9,
                            value: _sharingRadius,
                            label: '${_sharingRadius.toStringAsFixed(1)} km',
                            onChanged: _locationSharingEnabled ? _updateSharingRadius : null,
                          ),
                          Text(
                            '${_sharingRadius.toStringAsFixed(1)} km', 
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    
                    SwitchListTile(
                      title: Text(l10n?.autoJoinGroupRides ?? 'Auto-join Group Rides'),
                      subtitle: Text(l10n?.automaticallyJoinRidesNearby ?? 
                                'Automatically join rides happening nearby'),
                      value: _joinGroupRidesAutomatically,
                      onChanged: _locationSharingEnabled ? _toggleAutoJoinRides : null,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(l10n?.security ?? 'Security'),
                      trailing: const Icon(Icons.security),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: Text(l10n?.enableFingerprintAuth ?? 'Enable Fingerprint Authentication'),
                      subtitle: Text(l10n?.useFingerprintToSecure ?? 
                                'Use fingerprint to secure your app'),
                      value: _fingerprintAuthEnabled,
                      onChanged: _toggleFingerprintAuth,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
