import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/gdrive_adapter.dart';

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