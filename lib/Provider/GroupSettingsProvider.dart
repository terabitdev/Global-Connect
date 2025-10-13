import 'package:flutter/material.dart';

class GroupSettingsProvider extends ChangeNotifier {
  bool _muteNotifications = false;
  bool _shareLocation = false;

  bool get muteNotifications => _muteNotifications;
  bool get shareLocation => _shareLocation;

  void toggleMuteNotifications(bool value) {
    _muteNotifications = value;
    notifyListeners();
  }

  void toggleShareLocation(bool value) {
    _shareLocation = value;
    notifyListeners();
  }
} 