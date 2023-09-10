import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/controllers/mystorage.dart';

class PhotolistData {
  PhotolistData() {}
  bool isSelectMode = false;
  int cardWidth = 200;
  List<MyFile> files = [];
}

final photolistProvider = ChangeNotifierProvider((ref) => PhotolistNotifier(ref));

class PhotolistNotifier extends ChangeNotifier {
  PhotolistNotifier(ref) {}
  PhotolistData data = PhotolistData();
  setfiles() {}
}

final selectedListProvider = ChangeNotifierProvider((ref) => selectedListNotifier(ref));

class selectedListNotifier extends ChangeNotifier {
  List<MyFile> list = [];
  selectedListNotifier(ref) {}

  select(MyFile f) {
    if (list.contains(f)) {
      list.remove(f);
    } else {
      if (list.length < 20) list.add(f);
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
