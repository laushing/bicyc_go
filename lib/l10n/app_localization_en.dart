import 'package:intl/intl.dart' as intl;
import 'app_localization.dart';

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get english => 'English';

  @override
  String get appTitle => 'BicycGo';

 @override
  String get dashboard => 'Dashboard';
  
  @override
  String get map => 'Map';
  
  @override
  String get rewards => 'Rewards';
  
  @override
  String get profile => 'Profile';
  
  @override
  String get settings => 'Settings';
  
  @override
  String get language => 'Language';
  
  @override
  String get planRoute  => 'Plan Route';
  
  @override
  String get createCustomRoute => 'Create Custom Route';
  
  @override
  String get saveRoute => 'Save Route';
  
  @override
  String get cancel => 'Cancel';
  
  @override
  String get addPoint => 'Add Point';
  
  @override
  String get editRouteName  => 'Edit Route Name';
  
  @override
  String get routeNameHint => 'Enter route name here';
  
  @override
  String get pointAdded => 'Point added successfully!';

  @override
  String get routeSaved => 'Route saved successfully!';

  @override
  String get routeSaveError => 'Error saving route! Please try again.';

  @override
  String get needMorePoints => 'You need to add more points to create a route.';

  @override
  String get tapToAddPoint => 'Tap on the map to add a point.';

  @override
  String get routeSelected => 'Route selected successfully!';

  @override
  String get startNavigation => 'Start Navigation';

  @override
  String get navigationStarted => 'Navigation started!';

  @override
  String get routeName => 'Route Name';

  @override
  String get plannedDateTime => 'Planned Date & Time';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';
  
  @override
  String get location => 'Location';

  @override
  String get addPointToRoute => 'Add Point to Route';

  @override
  String get noRoutesAvailable => 'No routes available. Please create a route first.';

  @override
  String get failedToLoadRoutes => 'Failed to load routes. Please check your internet connection.';

  @override
  String get start => 'Start';

  @override
  String get loadRoutesError => 'Error loading routes! Please try again.';

  @override
  String get end => 'End';

  @override
  String get chineseTraditional => 'Chinese (Traditional)';
}