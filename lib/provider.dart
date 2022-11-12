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

final isOptionProvider = StateProvider<bool>((ref) {
  return false;
});

final cardWidthProvider = StateProvider<int>((ref) {
  return 200;
});

class StatusData {
  bool isRunning = false;
  bool isSaver = false;
  DateTime? startTime;
}

final statusProvider = ChangeNotifierProvider((ref) => statusNotifier(ref));
class statusNotifier extends ChangeNotifier {
  StatusData statsu = StatusData();
  statusNotifier(ref){}
  start() {
    statsu.isRunning = true;
    statsu.isSaver = true;
    statsu.startTime = DateTime.now();
    this.notifyListeners();
  }
  stop() {
    statsu.isRunning = false;
    statsu.isSaver = false;
    this.notifyListeners();
  }
  stopped() {
    statsu.isRunning = false;
    statsu.startTime = null;
    this.notifyListeners();
  }
}

final gdriveProvider = ChangeNotifierProvider((ref) => gdriveNotifier(ref));
class gdriveNotifier extends ChangeNotifier {
  late GoogleDriveAdapter gdrive = GoogleDriveAdapter();
  gdriveNotifier(ref){
    gdrive.loginSilently().then((r){
      this.notifyListeners();
    });
  }
}