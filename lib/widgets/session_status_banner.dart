import 'package:flutter/material.dart';
import '../services/cycling_session_service.dart';
import 'dart:async';

class SessionStatusBanner extends StatefulWidget {
  final VoidCallback onOpenSession;
  
  const SessionStatusBanner({
    super.key,
    required this.onOpenSession,
  });

  @override
  State<SessionStatusBanner> createState() => _SessionStatusBannerState();
}

class _SessionStatusBannerState extends State<SessionStatusBanner> {
  final CyclingSessionService _sessionService = CyclingSessionService();
  Timer? _refreshTimer;
  
  double _distance = 0.0;
  int _duration = 0;
  
  @override
  void initState() {
    super.initState();
    
    // Update initial values
    _distance = _sessionService.totalDistance;
    _duration = _sessionService.elapsedSeconds;
    
    // Set up a timer to refresh UI periodically
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _distance = _sessionService.totalDistance;
          _duration = _sessionService.elapsedSeconds;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onOpenSession,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          border: Border(bottom: BorderSide(color: Colors.green.shade300, width: 1)),
        ),
        child: Row(
          children: [
            Icon(Icons.directions_bike, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Cycling Session in Progress',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${_distance.toStringAsFixed(2)} km · ${_sessionService.formatDuration(_duration)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: widget.onOpenSession,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                visualDensity: VisualDensity.compact,
                foregroundColor: Colors.green.shade700,
                side: BorderSide(color: Colors.green.shade300),
              ),
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
