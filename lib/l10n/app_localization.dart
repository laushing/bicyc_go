import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localization_en.dart';
import 'app_localization_zh.dart';

abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('zh', ''),
  ];

  String get appTitle;

  String get dashboard;
  
  String get map;
  
  String get rewards;
  
  String get profile;
  
  String get settings;
  
  String get language;
  
  String get planRoute;
  
  String get createCustomRoute;
  
  String get saveRoute;
  
  String get cancel;
  
  String get addPoint;
  
  String get editRouteName;
  
  String get routeNameHint;
  
  String get pointAdded;

  String get routeSaved;

  String get routeSaveError;

  String get needMorePoints;

  String get tapToAddPoint;

  String get routeSelected;

  String get startNavigation;

  String get navigationStarted;

  String get routeName;

  String get plannedDateTime;

  String get date;

  String get time;
  
  String get location;

  String get addPointToRoute;

  String get noRoutesAvailable;

  String get failedToLoadRoutes;

  String get start;

  String get end;
  
  String get english;
  
  String get chineseTraditional;

  String get loadRoutesError;

  String get navigationComplete;

  String get reachedDestination;

  String get returnToMap;

  String get navigating;

  String get waypoint;

  String get distanceToNextTurn;

  String get estimatedTimeRemaining;

  String get turnLeft;

  String get turnRight;

  String get continuesStraight;

  String get nearbyCyclistsInfo;

  String get locationSharingEnabled;

  String get more;

  String get grantPermission;

  String get pleaseEnableLocation;

  String get locationSharing;

  String get enableLocationSharing;

  String get shareLocationWithOtherCyclists;

  String get sharingRadius;

  String get autoJoinGroupRides;

  String get automaticallyJoinRidesNearby;

  String get cyclingRewards;

  String get yourPoints;

  String get earnPointsPerKm;

  String get cyclingSessionActive;

  String get startCyclingToEarnPoints;

  String get distance;

  String get distanceValue;

  String get duration;

  String get speed;

  String get maxSpeed;

  String get endSession;

  String get startCycling;

  String get recentActivities;

  String get pointsEarned;

  String get availableRewards;

  String get errorOccurred;

  String get tryAgain;

  String get noRewardsAvailable;

  String get pointsCost;

  String get pointsLabel;

  String get confirmRedemption;

  String get redeemConfirmation;

  String get redeem;

  String get redeemSuccess;

  String get pointsDeducted;

  String get redeemFailed;

  String get cyclistProfile;

  String get connectWithCyclists;

  String get totalDistance;

  String get achievements;

  String get badges;

  String get none;

  String get favoriteRoute;

  String get cyclingConnections;

  String get connections;

  String get requests;

  String get findCyclists;

  String get editProfile;

  String get connectionRequests;

  String get noConnectionRequests;

  String get nowConnectedWith;

  String get requestSentTo;

  String get searchCyclists;

  String get noSearchResults;

  String get noConnectionsYet;

  String get connect;

  String get myConnections;

  String get connectToSeeHere;

  String get cyclingCommunications;
  
  String get messages;
  
  String get nearbyCyclists;
  
  String get noMessagesYet;
  
  String get noCyclistsNearby;
  
  String get createGroup;
  
  String get messageHint;
  
  String get shareRoute;
  
  String get activeNow;
  
  String get lastActive;
  
  String get findRealCyclists;
  
  String get realTimeChat;
  
  String get groupCycling;
  
  String get sendMessage;
  
  String get typeMessage;
  
  String get nearbyDistance;
  
  String get createCyclingGroup;
  
  String get groupInfo;
  
  String get inviteToRide;
  
  String get routeShared;
  
  String get viewProfile;
  
  String get joinGroupRide;

  String get refresh;
  
  String get recentRides;
  
  String get rewardPoints;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }
  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale".',
  );
}