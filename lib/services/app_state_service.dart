import 'dart:async';

class AppStateService {
  // Singleton pattern
  static final AppStateService _instance = AppStateService._internal();
  factory AppStateService() => _instance;
  AppStateService._internal();
  
  // App state
  bool _hasActiveSession = false;
  
  // Controllers for state changes
  final _activeSessionController = StreamController<bool>.broadcast();
  
  // Streams
  Stream<bool> get activeSessionStream => _activeSessionController.stream;
  
  // Getters
  bool get hasActiveSession => _hasActiveSession;
  
  // Setters
  void setActiveSession(bool isActive) {
    _hasActiveSession = isActive;
    _activeSessionController.add(isActive);
  }
  
  void dispose() {
    _activeSessionController.close();
  }
}
