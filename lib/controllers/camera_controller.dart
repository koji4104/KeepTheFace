import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class StateData {
  bool isRunning = false;
  bool isSaver = false;
  DateTime? startTime;
  DateTime? waitTime;
}

final stateProvider = ChangeNotifierProvider((ref) => stateNotifier(ref));

class stateNotifier extends ChangeNotifier {
  StateData state = StateData();
  stateNotifier(ref) {}
  start() {
    print('-- stateNotifier start');
    state.isRunning = true;
    state.isSaver = true;
    state.startTime = DateTime.now();
    this.notifyListeners();
  }

  stop() {
    print('-- stateNotifier stop');
    state.isRunning = false;
    state.isSaver = false;
    this.notifyListeners();
  }

  stopped() {
    state.isRunning = false;
    state.startTime = null;
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
