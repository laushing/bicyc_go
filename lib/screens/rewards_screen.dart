import 'package:flutter/material.dart';
import '../widgets/reward_card.dart';
import '../services/rewards_service.dart';
import '../services/cycling_session_service.dart';
import '../services/app_state_service.dart';
import '../models/user_model.dart';
import '../models/cycling_activity.dart';
import '../widgets/session_status_banner.dart';
import 'dart:async';
import '../l10n/app_localization.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final RewardsService _rewardsService = RewardsService();
  final CyclingSessionService _sessionService = CyclingSessionService();
  final AppStateService _appStateService = AppStateService();

  List<Map<String, dynamic>> _rewards = [];
  List<CyclingActivity> _recentActivities = [];
  bool _isLoading = true;
  String? _error;

  // Cycling session tracking
  double _currentDistance = 0.0;
  int _currentDuration = 0;
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;
  Map<String, int> _speedZones = {};

  // Stream subscriptions
  StreamSubscription? _distanceSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _speedSubscription;
  StreamSubscription? _maxSpeedSubscription;
  StreamSubscription? _speedZonesSubscription;

  // Mock user with points - in a real app, this would come from user service
  final User _currentUser = User(id: '1', name: 'Cyclist', rewardPoints: 350);

  @override
  void initState() {
    super.initState();
    _loadRewards();
    _loadRecentActivities();

    // Initialize with current session state (if there's an active session)
    if (_sessionService.isSessionActive) {
      _currentDistance = _sessionService.totalDistance;
      _currentDuration = _sessionService.elapsedSeconds;
      _currentSpeed = _sessionService.currentSpeed;
    }

    _setupSessionListeners();
  }

  void _setupSessionListeners() {
    // Cancel any existing subscriptions first
    _disposeListeners();

    _distanceSubscription = _sessionService.distanceStream.listen((distance) {
      if (mounted) {
        setState(() {
          _currentDistance = distance;
        });
      }
    });

    _durationSubscription = _sessionService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _currentDuration = duration;
        });
      }
    });

    _speedSubscription = _sessionService.speedStream.listen((speed) {
      if (mounted) {
        setState(() {
          _currentSpeed = speed;
        });
      }
    });

    _maxSpeedSubscription = _sessionService.maxSpeedStream.listen((maxSpeed) {
      if (mounted) {
        setState(() {
          _maxSpeed = maxSpeed;
        });
      }
    });

    _speedZonesSubscription = _sessionService.speedZonesStream.listen((zones) {
      if (mounted) {
        setState(() {
          _speedZones = zones;
        });
      }
    });
  }

  void _disposeListeners() {
    _distanceSubscription?.cancel();
    _distanceSubscription = null;
    _durationSubscription?.cancel();
    _durationSubscription = null;
    _speedSubscription?.cancel();
    _speedSubscription = null;
    _maxSpeedSubscription?.cancel();
    _maxSpeedSubscription = null;
    _speedZonesSubscription?.cancel();
    _speedZonesSubscription = null;
  }

  Future<void> _loadRewards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rewards = await _rewardsService.getAvailableRewards();
      setState(() {
        _rewards = rewards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      final activities = await _rewardsService.getRecentActivities(_currentUser.id);
      setState(() {
        _recentActivities = activities;
      });
    } catch (e) {
      print('Error loading activities: $e');
    }
  }

  Future<void> _startCyclingSession() async {
    final started = await _sessionService.startSession();

    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start tracking. Please check location permissions.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Update app state to show we have an active session
    _appStateService.setActiveSession(true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cycling session started! Stay safe!'),
        backgroundColor: Colors.green,
      ),
    );

    // Force UI update
    setState(() {});
  }

  Future<void> _endCyclingSession() async {
    // Validate session - prevent ending sessions with minimal distance
    if (_currentDistance < 0.1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session too short to record. Please cycle at least 0.1 km.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Cycling Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You cycled ${_currentDistance.toStringAsFixed(2)} km.'),
              const SizedBox(height: 8),
              Text('Duration: ${_sessionService.formatDuration(_currentDuration)}'),
              const SizedBox(height: 8),
              Text('Average speed: ${_currentSpeed.toStringAsFixed(1)} km/h'),
              const SizedBox(height: 16),
              const Text('Do you want to end this session and claim your points?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('End & Claim Points'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Show loading dialog to prevent multiple taps and UI freezes
    final loadingDialogContext = await showDialog<BuildContext>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ending session..."),
                  Text("Please wait", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        );
      },
    );

    try {
      // End the session and get activity
      final activity = await _sessionService.endSession(_currentUser);

      // Update app state to show session is no longer active
      _appStateService.setActiveSession(false);

      // Make sure to always close the loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (activity != null && context.mounted) {
        setState(() {
          _recentActivities.insert(0, activity);
          _currentDistance = 0;
          _currentDuration = 0;
          _currentSpeed = 0;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Session completed successfully!'),
                Text('You earned ${activity.pointsEarned} points for cycling ${activity.distance.toStringAsFixed(2)} km',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Refresh rewards to update their availability
        _loadRewards();
      }
    } catch (e) {
      // Make sure to always close the loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Try to cancel/reset the session
      _sessionService.cancelSession();

      if (context.mounted) {
        setState(() {
          _currentDistance = 0;
          _currentDuration = 0;
          _currentSpeed = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadRewards();
          await _loadRecentActivities();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
                const SizedBox(height: 20),
                Text(
                  l10n.cyclingRewards,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // User points display
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.yourPoints.replaceFirst('{points}', _currentUser.rewardPoints.toString()),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  l10n.earnPointsPerKm,
                  style: const TextStyle(fontSize: 16),
                ),

                // Cycling session card
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: _sessionService.isSessionActive
                      ? Colors.green.shade50
                      : Colors.grey.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          _sessionService.isSessionActive
                              ? l10n.cyclingSessionActive
                              : l10n.startCyclingToEarnPoints,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _sessionService.isSessionActive
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Session stats
                        if (_sessionService.isSessionActive) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn(
                                l10n.distance,
                                '${_currentDistance.toStringAsFixed(2)} km',
                                Icons.straighten,
                              ),
                              _buildStatColumn(
                                l10n.duration,
                                _sessionService.formatDuration(_currentDuration),
                                Icons.timer,
                              ),
                              _buildStatColumn(
                                l10n.speed,
                                '${_currentSpeed.toStringAsFixed(1)} km/h',
                                Icons.speed,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.orange.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.flash_on, size: 16, color: Colors.orange.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${l10n.maxSpeed}: ${_maxSpeed.toStringAsFixed(1)} km/h',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Start/Stop button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _sessionService.isSessionActive
                                ? _endCyclingSession
                                : _startCyclingSession,
                            icon: Icon(
                              _sessionService.isSessionActive
                                  ? Icons.stop_circle
                                  : Icons.play_circle,
                            ),
                            label: Text(
                              _sessionService.isSessionActive
                                  ? l10n.endSession
                                  : l10n.startCycling,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _sessionService.isSessionActive
                                  ? Colors.red
                                  : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Recent activities section
                if (_recentActivities.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.recentActivities,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentActivities.length,
                      itemBuilder: (context, index) {
                        final activity = _recentActivities[index];
                        return Card(
                          margin: const EdgeInsets.only(right: 10),
                          color: Colors.blue.shade50,
                          child: Container(
                            width: 140,
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.directions_bike, color: Colors.blue.shade700, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${activity.distance.toStringAsFixed(2)} km',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text('${l10n.pointsEarned}: ${activity.pointsEarned}'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  activity.formattedDate,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Available rewards section
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.availableRewards,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Rewards list
                if (_isLoading)
                  const CircularProgressIndicator()
                else if (_error != null)
                  Column(
                    children: [
                      Text('${l10n.errorOccurred}: $_error', style: const TextStyle(color: Colors.red)),
                      ElevatedButton(
                        onPressed: _loadRewards,
                        child: Text(l10n.tryAgain),
                      ),
                    ],
                  )
                else if (_rewards.isEmpty)
                  Text(l10n.noRewardsAvailable)
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _rewards.length,
                      itemBuilder: (context, index) {
                        final reward = _rewards[index];
                        final bool canRedeem = _rewardsService.canRedeem(
                          _currentUser,
                          reward['pointsCost']
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: RewardCard(
                            reward: reward['name'],
                            points: '${reward['pointsCost']} ${l10n.pointsLabel}',
                            description: reward['description'],
                            isAvailable: canRedeem,
                            onRedeem: canRedeem
                                ? () => _redeemReward(reward)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green.shade700),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _redeemReward(Map<String, dynamic> reward) async {
    final l10n = AppLocalizations.of(context)!;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.confirmRedemption),
          content: Text('${l10n.redeemConfirmation} ${reward['name']} (${reward['pointsCost']})'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.redeem),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmed) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Processing..."),
            ],
          ),
        );
      },
    );

    try {
      final success = await _rewardsService.redeemReward(
        _currentUser.id,
        reward['id'],
        reward['pointsCost'],
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (success) {
        setState(() {
          _currentUser.rewardPoints -= reward['pointsCost'] as int;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${l10n.redeemSuccess} ${reward['name']}'),
                Text(l10n.pointsDeducted.replaceFirst('{pointsCost}', reward['pointsCost'].toString()).replaceFirst('{remainingPoints}', _currentUser.rewardPoints.toString()),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        _loadRewards();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.redeemFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.errorOccurred}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Only dispose listeners, but don't stop the session
    _disposeListeners();
    super.dispose();
  }
}
