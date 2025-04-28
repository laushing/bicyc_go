import 'app_localization.dart';

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([super.locale = 'en']);

  @override
  String get english => 'English';

  @override
  String get appTitle => 'BicycGo';

  // Basic navigation items
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
  
  // Route planning
  @override
  String get planRoute => 'Plan Route';
  
  @override
  String get createCustomRoute => 'Create Custom Route';
  
  @override
  String get saveRoute => 'Save Route';
  
  @override
  String get cancel => 'Cancel';
  
  @override
  String get addPoint => 'Add Point';
  
  @override
  String get editRouteName => 'Edit Route Name';
  
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

  // Navigation
  @override
  String get navigationComplete => 'Navigation Complete';

  @override
  String get reachedDestination => 'You have reached your destination on {routeName}!';

  @override
  String get returnToMap => 'Return to Map';

  @override
  String get navigating => 'Navigating';

  @override
  String get waypoint => 'Waypoint';

  @override
  String get distanceToNextTurn => 'Distance to next turn: {distance} km';

  @override
  String get estimatedTimeRemaining => 'Estimated time remaining: {time} hours';

  @override
  String get turnLeft => 'Turn left at the next intersection';

  @override
  String get turnRight => 'Turn right at the next intersection';

  @override
  String get continuesStraight => 'Continue straight';

  // Location sharing and nearby cyclists
  @override
  String get nearbyCyclists => 'Nearby Cyclists';

  @override
  String get locationSharingEnabled => 'Location sharing enabled!';

  @override
  String get more => 'More';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get pleaseEnableLocation => 'Please enable location services to use this feature.';

  @override
  String get locationSharing => 'Location Sharing';

  @override
  String get enableLocationSharing => 'Enable Location Sharing';

  @override
  String get shareLocationWithOtherCyclists => 'Share your location with other cyclists';

  @override
  String get sharingRadius => 'Sharing Radius';

  @override
  String get autoJoinGroupRides => 'Auto Join Group Rides';

  @override
  String get automaticallyJoinRidesNearby => 'Automatically join group rides nearby';

  // Rewards
  @override
  String get cyclingRewards => 'Cycling Rewards';

  @override
  String get yourPoints => 'Your Points';

  @override
  String get earnPointsPerKm => 'Earn {points} points per km';

  @override
  String get cyclingSessionActive => 'Cycling session active!';

  @override
  String get startCyclingToEarnPoints => 'Start cycling to earn points!';

  @override
  String get distance => 'Distance';

  @override
  String get distanceValue => 'Distance: {distance} km';

  @override
  String get duration => 'Duration';

  @override
  String get speed => 'Speed';

  @override
  String get maxSpeed => 'Max Speed';

  @override
  String get endSession => 'End Session';

  @override
  String get startCycling => 'Start Cycling';

  @override
  String get recentActivities => 'Recent Activities';

  @override
  String get pointsEarned => 'Points Earned';

  @override
  String get availableRewards => 'Available Rewards';

  @override
  String get errorOccurred => 'An error occurred! Please try again.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get noRewardsAvailable => 'No rewards available at the moment.';

  @override
  String get pointsCost => 'Points Cost';

  @override
  String get pointsLabel => 'Points';

  @override
  String get confirmRedemption => 'Are you sure you want to redeem this reward?';

  @override
  String get redeemConfirmation => 'Redeem Confirmation';

  @override
  String get redeem => 'Redeem';

  @override
  String get redeemSuccess => 'Reward redeemed successfully!';

  @override
  String get pointsDeducted => 'Points deducted: {points}';

  @override
  String get redeemFailed => 'Failed to redeem reward! Please try again.';

  @override
  String get refresh => 'Refresh';
  
  @override
  String get recentRides => 'Recent Rides';
  
  @override
  String get rewardPoints => 'Reward Points';

  // Profile and connections
  @override
  String get cyclistProfile => 'Cyclist Profile';

  @override
  String get connectWithCyclists => 'Connect with other cyclists';

  @override
  String get totalDistance => 'Total Distance: {distance} km';

  @override
  String get achievements => 'Achievements';

  @override
  String get badges => 'Badge';

  @override
  String get none => 'None';

  @override
  String get favoriteRoute => 'Favourite Routes';

  @override
  String get cyclingConnections => 'Cycling Connections';

  @override
  String get connections => 'Connections';

  @override
  String get requests => 'Requests';

  @override
  String get findCyclists => 'Find Cyclists';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get connectionRequests => 'Connection Requests';

  @override
  String get noConnectionRequests => 'No connection requests available.';

  @override
  String get nowConnectedWith => 'You are now connected with {name}!';

  @override
  String get requestSentTo => 'Connection request sent to {name}.';

  @override
  String get searchCyclists => 'Search Cyclists';

  @override
  String get noSearchResults => 'No search results found.';

  @override
  String get noConnectionsYet => 'No connections yet.';

  @override
  String get connect => 'Connect';

  @override
  String get myConnections => 'My Connections';

  @override
  String get connectToSeeHere => 'Connect with other cyclists to see their activities here.';

  @override
  String get chineseTraditional => 'Chinese (Traditional)';

  // Messaging and communication features
  @override
  String get createGroup => 'Create Group';

  @override
  String get cyclingCommunications => 'Cycling Communications';
  
  @override
  String get messages => 'Messages';
  
  @override
  String get noMessagesYet => 'No messages yet';
  
  @override
  String get noCyclistsNearby => 'No cyclists nearby';
  
  @override
  String get messageHint => 'Type a message...';
  
  @override
  String get shareRoute => 'Share Route';
  
  @override
  String get activeNow => 'Active now';
  
  @override
  String get lastActive => 'Last active';
  
  @override
  String get findRealCyclists => 'Find Real Cyclists';
  
  @override
  String get realTimeChat => 'Real-time Chat';
  
  @override
  String get groupCycling => 'Group Cycling';
  
  @override
  String get sendMessage => 'Send Message';
  
  @override
  String get typeMessage => 'Type a message';
  
  @override
  String get nearbyDistance => '{distance} km away';
  
  @override
  String get createCyclingGroup => 'Create Cycling Group';
  
  @override
  String get groupInfo => 'Group Info';
  
  @override
  String get inviteToRide => 'Invite to Ride';
  
  @override
  String get routeShared => 'Route shared';
  
  @override
  String get viewProfile => 'View Profile';
  
  @override
  String get joinGroupRide => 'Join Group Ride';

  @override
  String get nearbyCyclistsInfo => 'Nearby Cyclists Info';

  @override
  String get security => 'Security';

  @override
  String get enableFingerprintAuth => 'Enable Fingerprint Authentication';

  @override
  String get useFingerprintToSecure => 'Use fingerprint to secure your account';

  @override
  String get fingerprintAuthReason => 'To secure your account and make it easier to log in.';

  @override
  String get fingerprintAuthError => 'Fingerprint authentication failed! Please try again.';

  @override
  String get biometricsNotAvailable => 'Biometric authentication is not available on this device.';

  @override
  String get fingerprintEnabled => 'Fingerprint authentication enabled!';

  @override
  String get authenticating => 'Authenticating...';

  @override
  String get cyclingForum => 'Cycling Forum';

  @override
  String get writeNewPost => 'Write a new post';

  @override
  String get general => 'General';

  @override
  String get routeTips => 'Cycling Tips';

  @override
  String get equipment => 'Equipment';

  @override
  String get events => 'Events';

  @override
  String get noPostsYet => 'No posts yet';

  @override
  String get likes => 'Likes';

  @override
  String get comments => 'Comments';

  @override
  String get share => 'Share';

  @override
  String get post => 'Post';
}