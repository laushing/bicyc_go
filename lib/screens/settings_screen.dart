import 'package:flutter/material.dart';
import '../../l10n/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final Function(Locale) onLocaleChanged;
  final Locale currentLocale;

  const SettingsScreen({
    Key? key, 
    required this.onLocaleChanged, 
    required this.currentLocale
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.currentLocale.languageCode;
  }

  Future<void> _changeLanguage(String languageCode) async {
    setState(() {
      _selectedLanguage = languageCode;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    
    widget.onLocaleChanged(Locale(languageCode));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
                    trailing: Icon(Icons.language),
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
        ],
      ),
    );
  }
}
