import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thesedays/models/photolist.dart';
import '/common.dart';

final photolistProvider = ChangeNotifierProvider((ref) => PhotolistNotifier(ref));
class PhotolistNotifier extends ChangeNotifier {
  PhotolistNotifier(ref){}
  PhotolistData data = PhotolistData();
}

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


