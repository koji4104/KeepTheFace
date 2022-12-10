import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'common.dart';
import 'gdrive_adapter.dart';

final selectedListProvider = ChangeNotifierProvider((ref) => selectedListNotifier(ref));
class selectedListNotifier extends ChangeNotifier {
  List<MyFile> list = [];
  selectedListNotifier(ref){}

  select(MyFile f) {
    if(list.contains(f)) {
      list.remove(f);
    } else {
      list.add(f);
    }
    this.notifyListeners();
  }

  bool contains(MyFile f) {
    return list.contains(f);
  }

  clear() {
    list.clear();
    this.notifyListeners();
  }
}

final fileListProvider = ChangeNotifierProvider((ref) => fileListNotifier(ref));
class fileListNotifier extends ChangeNotifier {
  List<MyFile> list = [];
  fileListNotifier(ref){}
}

final isSelectModeProvider = StateProvider<bool>((ref) {
  return false;
});

final cardWidthProvider = StateProvider<int>((ref) {
  return 200;
});

final stopButtonTextProvider = StateProvider<String>((ref) {
  return '';
});

class StateData {
  bool isRunning = false;
  bool isSaver = false;
  DateTime? startTime;
}

final stateProvider = ChangeNotifierProvider((ref) => stateNotifier(ref));
class stateNotifier extends ChangeNotifier {
  StateData state = StateData();
  stateNotifier(ref){}
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
}

final gdriveProvider = ChangeNotifierProvider((ref) => gdriveNotifier(ref));
class gdriveNotifier extends ChangeNotifier {
  GoogleDriveAdapter gdrive = GoogleDriveAdapter();
  gdriveNotifier(ref){
    gdrive.loginSilently().then((r){
      this.notifyListeners();
    });
  }
  Future loginWithGoogle() async {
    gdrive.loginWithGoogle().then((_) {
      this.notifyListeners();
    });
  }
  Future logout() async {
    gdrive.logout().then((_) {
      this.notifyListeners();
    });
  }
}