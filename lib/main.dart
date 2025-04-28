import 'package:flutter/material.dart';
import '../../l10n/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'config/theme.dart';
import 'services/biometric_service.dart'; // Add this import

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
  
  const BicycGo({super.key, this.initialLanguageCode, this.initialCountryCode});

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
    super.key, 
    required this.onLocaleChanged, 
    required this.currentLocale
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isAuthenticated = false;
  
  @override
  void initState() {
    super.initState();
    _checkBiometricAuth();
  }
  
  Future<void> _checkBiometricAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final bool fingerprintEnabled = prefs.getBool('fingerprint_auth_enabled') ?? false;
    
    if (fingerprintEnabled) {
      // Delay a bit to ensure context is available and app is built
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (!mounted) return;
        
        bool authenticated = await BiometricService.authenticateWithBiometrics(context);
        setState(() {
          _isAuthenticated = authenticated;
        });
        
        if (!authenticated) {
          // If authentication fails, show a dialog and don't allow app access
          if (!mounted) return;
          _showAuthFailedDialog();
        }
      });
    } else {
      setState(() {
        _isAuthenticated = true; // No authentication required
      });
    }
  }
  
  void _showAuthFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: const Text('Fingerprint authentication is required to use this app.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkBiometricAuth(); // Try again
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              // Exit app functionality would go here
              // For now, we'll just keep showing the dialog
              Navigator.of(context).pop();
              _showAuthFailedDialog();
            },
            child: const Text('Exit App'),
          ),
        ],
      ),
    );
  }
  
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

    void onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    final l10n = AppLocalizations.of(context);

    // Show a loading screen while authenticating
    if (!_isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(l10n?.authenticating ?? 'Authenticating...'),
            ],
          ),
        ),
      );
    }

    // Show the regular app after authentication
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
        onTap: onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
