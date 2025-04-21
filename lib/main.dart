import 'package:flutter/material.dart';
import '../../l10n/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'config/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Get the saved locale if any
  final prefs = await SharedPreferences.getInstance();
  final String? languageCode = prefs.getString('language_code');
  final String? countryCode = prefs.getString('country_code');
  
  runApp(BicycGo(
    initialLanguageCode: languageCode, 
    initialCountryCode: countryCode
  ));
}

class BicycGo extends StatefulWidget {
  final String? initialLanguageCode;
  final String? initialCountryCode;
  
  const BicycGo({Key? key, this.initialLanguageCode, this.initialCountryCode}) : super(key: key);

  @override
  State<BicycGo> createState() => _BicycGoState();
}

class _BicycGoState extends State<BicycGo> {
  Locale? _locale;
  
  @override
  void initState() {
    super.initState();
    _locale = widget.initialLanguageCode != null
        ? Locale(widget.initialLanguageCode!, widget.initialCountryCode ?? '')
        : null;
  }
  
  void _setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BicycGo',
      theme: AppTheme.lightTheme,
      home: MainScreen(
        onLocaleChanged: _setLocale,
        currentLocale: _locale ?? const Locale('en'),
      ),
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates + [
        AppLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

class MainScreen extends StatefulWidget {
  final Function(Locale) onLocaleChanged;
  final Locale currentLocale;
  
  const MainScreen({
    Key? key, 
    required this.onLocaleChanged, 
    required this.currentLocale
  }) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      const MapScreen(),
      const RewardsScreen(),
      const ProfileScreen(),
      SettingsScreen(
        onLocaleChanged: widget.onLocaleChanged,
        currentLocale: widget.currentLocale,
      ),
    ];

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.appTitle ?? 'BicycGo'),
        backgroundColor: Colors.green,
      ),
      body: screens.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: l10n?.dashboard ?? 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: l10n?.map ?? 'Map',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.emoji_events),
            label: l10n?.rewards ?? 'Rewards',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: l10n?.profile ?? 'Profile',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n?.settings ?? 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
