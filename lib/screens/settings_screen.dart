import 'package:flutter/material.dart';
import '../../l10n/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_sharing_service.dart';

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
  final LocationSharingService _locationSharingService = LocationSharingService();

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.currentLocale.languageCode;
    _loadLocationSharingSettings();
  }
  
  Future<void> _loadLocationSharingSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locationSharingEnabled = prefs.getBool('location_sharing_enabled') ?? false;
      _joinGroupRidesAutomatically = prefs.getBool('join_group_rides_auto') ?? false;
      _sharingRadius = prefs.getDouble('sharing_radius') ?? 2.0;
    });
  }
  
  Future<void> _saveLocationSharingSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_sharing_enabled', _locationSharingEnabled);
    await prefs.setBool('join_group_rides_auto', _joinGroupRidesAutomatically);
    await prefs.setDouble('sharing_radius', _sharingRadius);
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
    _saveLocationSharingSettings();
    
    // Start or stop location sharing service
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
    _saveLocationSharingSettings();
  }
  
  void _updateSharingRadius(double value) {
    setState(() {
      _sharingRadius = value;
    });
    _saveLocationSharingSettings();
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
            
            // Language settings
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
            
            // Location sharing settings
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
          ],
        ),
      ),
    );
  }
}
