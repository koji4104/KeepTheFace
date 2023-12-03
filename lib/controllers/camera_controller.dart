import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/models/camera_model.dart';

final stateProvider = ChangeNotifierProvider((ref) => stateNotifier(ref));

class stateNotifier extends ChangeNotifier {
  StateData state = StateData();
  stateNotifier(ref) {}
  start() {
    print('-- stateNotifier start');
    state.isRunning = true;
    state.isScreensaver = true;
    state.startTime = DateTime.now();
    this.notifyListeners();
  }

  stop() {
    print('-- stateNotifier stop');
    state.isRunning = false;
    state.isScreensaver = false;
    this.notifyListeners();
  }

  autostop() {
    state.isRunning = false;
    state.isScreensaver = true;
    this.notifyListeners();
  }

  pause() {
    state.isRunning = true;
    state.isScreensaver = true;
    this.notifyListeners();
  }

  /// show waiting screen
  showWaitingScreen() {
    state.waitTime = DateTime.now();
    this.notifyListeners();
  }

  /// hide waiting screen
  hideWaitingScreen() {
    state.waitTime = null;
    this.notifyListeners();
  }
}

final stopButtonProvider = StateProvider<String>((ref) {
  return '';
});
