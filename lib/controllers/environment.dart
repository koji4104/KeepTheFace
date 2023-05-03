import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:io';
import '/constants.dart';

class EnvData {
  int val;
  int def;
  String key = '';
  List<int> vals = [];
  List<String> keys = [];
  String name = '';

  EnvData(
      {required int this.val,
      required int this.def,
      required List<int> this.vals,
      required List<String> this.keys,
      required String this.name}) {
    setVal(val);
  }

  setVal(int? v) {
    if (v == null || vals.length == 0 || keys.length == 0) return;
    if (v > vals.last) v = def;
    for (var i = 0; i < vals.length; i++) {
      if (v <= vals[i]) {
        val = vals[i];
        key = keys[i];
        break;
      }
    }
  }
}

/// Environment
class Environment {
  /// 1photo 2audio 3photo+audio 4video
  EnvData take_mode = EnvData(
    val: 1,
    def: 1,
    vals: [1, 2, 4],
    keys: ['photo', 'audio', 'video'],
    name: 'take_mode',
  );

  /// Photo interval
  EnvData photo_interval_sec = EnvData(
    val: 60,
    def: 60,
    vals: IS_TEST ? [10, 300, 600] : [60, 300, 600],
    keys: IS_TEST ? ['10 sec', '5 min', '10 min'] : ['1 min', '5 min', '10 min'],
    name: 'photo_interval_sec',
  );

  /// Split (video, audio)
  EnvData split_interval_sec = EnvData(
    val: 600,
    def: 600,
    vals: IS_TEST ? [30, 300, 600] : [300, 600],
    keys: IS_TEST ? ['30 sec', '5 min', '10 min'] : ['5 min', '10 min'],
    name: 'split_interval_sec',
  );

  /// Screensaver 0=No 1=Yes 2=5 seconds
  EnvData saver_mode = EnvData(
    val: 1,
    def: 1,
    vals: [1, 2],
    keys: ['ON', 'Black'],
    name: 'saver_mode',
  );

  /// Automatic stop
  EnvData autostop_sec = EnvData(
    val: 0,
    def: 0,
    vals: IS_TEST ? [0, 120, 3600, 7200, 14400, 21600, 43200, 86400] : [0, 3600, 7200, 14400, 43200, 86400],
    keys: IS_TEST
        ? ['Nonstop', '2 min', '1 hour', '2 hour', '4 hour', '6 hour', '12 hour', '24 hour']
        : ['Nonstop', '1 hour', '2 hour', '4 hour', '12 hour', '24 hour'],
    name: 'autostop_sec',
  );

  /// MB of Save in-app
  /// Photo 1MB Audio 5MB Video 50-500-1400MB
  EnvData in_save_mb = EnvData(
    val: 10000,
    def: 10000,
    vals: IS_TEST ? [20, 500, 10000] : [1000, 10000, 50000, 100000],
    keys: IS_TEST ? ['20 mb', '500 mb', '10 gb'] : ['1 gb', '10 gb', '50 gb', '100 gb'],
    name: 'in_save_mb',
  );

  /// Num of Save in-app
  /// Photo 1MB 24H=1440pcs 24H=144pcs
  EnvData in_save_num = EnvData(
    val: 1000,
    def: 1000,
    vals: IS_TEST ? [20, 500, 1000] : [100, 1000, 5000, 10000],
    keys: IS_TEST ? ['20', '500', '1000'] : ['100', '1000', '5000', '10000'],
    name: 'in_save_num',
  );

  /// droid 320X240, 720x480..
  /// ios 352x288 640x480..
  EnvData camera_height = EnvData(
    val: 480,
    def: 480,
    vals: [240, 480, 720, 1080],
    keys: kIsWeb == false && Platform.isAndroid
        ? ['320X240', '720x480', '1280x720', '1920x1080']
        : ['352x288', '640x480', '1280x720', '1920x1080'],
    name: 'camera_height',
  );

  // Zoom x10
  EnvData camera_zoom = EnvData(
    val: 10,
    def: 10,
    vals: [10, 20, 30, 40],
    keys: ['1.0', '2.0', '3.0', '4.0'],
    name: 'camera_zoom',
  );

  // 0=back, 1=Front(Face)
  EnvData camera_pos = EnvData(
    val: 0,
    def: 0,
    vals: [0, 1],
    keys: ['back', 'front'],
    name: 'camera_pos',
  );

  EnvData ex_save_num = EnvData(
    val: 100,
    def: 100,
    vals: [100, 500],
    keys: ['100', '500'],
    name: 'ex_save_num',
  );

  /// external storage 0=None 1=GoogleDrive
  EnvData ex_storage = EnvData(
    val: 0,
    def: 0,
    vals: [0, 1, 2],
    keys: ['None', 'GoogleDrive'],
    name: 'ex_storage',
  );

  String trial_date = '';
  Future<bool> startTrial() async {
    trial_date = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    bool r = await prefs.setString('trial_date', trial_date);
    print('-- startTrial() ' + r.toString() + ' ' + trial_date);
    return r;
  }

  /// Time since trial start
  int? trialHour() {
    int? h = null;
    print('-- trial_date = ' + trial_date);
    if (trial_date.length < 8) return h;
    try {
      DateTime tri = DateTime.parse(trial_date);
      Duration dur = DateTime.now().difference(tri);
      h = dur.inHours;
    } on Exception catch (e) {
      print('-- trialHour() Exception ' + e.toString() + ' ' + trial_date);
    }
    return h;
  }

  bool isTrial() {
    bool r = false;
    try {
      int? h = trialHour();
      if (h != null) if (0 <= h && h < 2) r = true;
      print('-- isTrial() is ' + r.toString());
    } on Exception catch (e) {
      print('-- isTrial() Exception ' + e.toString());
    }
    return r;
  }

  bool canReTrial() {
    return true;
    bool r = true;
    try {
      int? h = trialHour();
      if (h != null) if (0 <= h && h < 48) r = false;
    } on Exception catch (e) {
      print('-- isTrial() Exception ' + e.toString());
    }
    return r;
  }

  bool isPremium() {
    return false;
    //return isTrial();
  }

  Future save(EnvData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(data.name, data.val);
  }
}

final environmentProvider = ChangeNotifierProvider((ref) => environmentNotifier(ref));

class environmentNotifier extends ChangeNotifier {
  Environment env = Environment();

  environmentNotifier(ref) {
    load().then((_) {
      this.notifyListeners();
    });
  }

  Future load() async {
    print('-- load()');
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _loadSub(prefs, env.take_mode);
      _loadSub(prefs, env.photo_interval_sec);
      _loadSub(prefs, env.split_interval_sec);
      _loadSub(prefs, env.in_save_num);
      _loadSub(prefs, env.in_save_mb);
      _loadSub(prefs, env.saver_mode);
      _loadSub(prefs, env.autostop_sec);
      _loadSub(prefs, env.camera_height);
      _loadSub(prefs, env.camera_zoom);
      _loadSub(prefs, env.camera_pos);
      //_loadSub(prefs, env.ex_storage);
      //_loadSub(prefs, env.ex_save_num);
      //env.trial_date = prefs.getString('trial_date') ?? '';
    } on Exception catch (e) {
      print('-- load() e=' + e.toString());
    }
  }

  _loadSub(SharedPreferences prefs, EnvData data) {
    data.setVal(prefs.getInt(data.name) ?? data.val);
  }

  Future saveData(EnvData data, int newVal) async {
    if (data.val == newVal) return;
    roundVal(data, newVal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(data.name, data.val);
    this.notifyListeners();
  }

  roundVal(EnvData data, int newVal) {
    if (newVal > getData(data).vals.last) newVal = getData(data).def;
    for (var i = 0; i < data.vals.length; i++) {
      if (newVal <= data.vals[i]) {
        getData(data).val = data.vals[i];
        getData(data).key = data.keys[i];
        return;
      }
    }
  }

  Future saveDataNoRound(EnvData data, int newVal) async {
    if (data.val == newVal) return;
    data.val = newVal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(data.name, data.val);
    this.notifyListeners();
  }

  EnvData getData(EnvData data) {
    EnvData ret = env.take_mode;
    switch (data.name) {
      case 'take_mode':
        ret = env.take_mode;
        break;
      case 'photo_interval_sec':
        ret = env.photo_interval_sec;
        break;
      case 'split_interval_sec':
        ret = env.split_interval_sec;
        break;
      case 'autostop_sec':
        ret = env.autostop_sec;
        break;
      case 'in_save_num':
        ret = env.in_save_num;
        break;
      case 'in_save_mb':
        ret = env.in_save_mb;
        break;
      case 'saver_mode':
        ret = env.saver_mode;
        break;
      case 'camera_height':
        ret = env.camera_height;
        break;
      case 'camera_zoom':
        ret = env.camera_zoom;
        break;
      case 'camera_pos':
        ret = env.camera_pos;
        break;
      case 'ex_save_num':
        ret = env.ex_save_num;
        break;
      case 'ex_storage':
        ret = env.ex_storage;
        break;
    }
    return ret;
  }

  Future startTrial() async {
    env.trial_date = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    bool r = await prefs.setString('trial_date', env.trial_date);
    print('-- startTrial() ' + r.toString() + ' ' + env.trial_date);
    this.notifyListeners();
  }
}
