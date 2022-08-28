import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class EnvData {
  int val;
  String key = '';
  List<int> vals = [];
  List<String> keys = [];
  String name = '';

  EnvData({
    required int this.val,
    required List<int> this.vals,
    required List<String> this.keys,
    required String this.name}){
    set(val);
  }

  // 選択肢と同じものがなければひとつ大きいいものになる
  set(int? newval) {
    if (newval==null)
      return;
    if (vals.length > 0) {
      val = vals[0];
      for (var i=0; i<vals.length; i++) {
        if (newval <= vals[i]) {
          val = vals[i];
          if(keys.length>=i)
            key = keys[i];
          break;
        }
      }
    }
  }
}

/// Environment
class Environment {
  /// 間隔
  EnvData take_interval_sec = EnvData(
    val:60,
    vals:[30,60,300,600],
    keys:['30 sec','60 sec','5 min','10 min'],
    name:'take_interval_sec',
  );

  /// 自動停止
  EnvData autostop_sec = EnvData(
    val:3600,
    vals:[3600,21600,43200,86400],
    keys:['1 hour','6 hour','12 hour','24 hour'],
    name:'autostop_sec',
  );

  EnvData save_num = EnvData(
    val:100,
    vals:[100,500,1000],
    keys:['100','500','1000'],
    name:'save_num',
  );

  EnvData ex_save_num = EnvData(
    val:100,
    vals:[10,100,500,1000],
    keys:['10','100','500','1000'],
    name:'ex_save_num',
  );

  /// 外部ストレージ 0=None 1=PhotoLibrary
  EnvData ex_storage = EnvData(
    val:0,
    vals:[0,1,2],
    keys:['None','PhotoLibrary','GoogleDrive'],
    name:'ex_storage',
  );

  // 640x480 720x480
  // 352x288 320x240
  EnvData camera_height = EnvData(
    val:480,
    vals:[240,480,720,1080],
    keys: kIsWeb==false && Platform.isAndroid
        ? ['320X240','720x480','1280x720','1920x1080']
        : ['352x288','640x480','1280x720','1920x1080'],
    name:'camera_height',
  );

  // 0=back, 1=Front(Face)
  EnvData camera_pos = EnvData(
    val:0,
    vals:[0,1],
    keys:['back','front'],
    name:'camera_pos',
  );

  String trial_date = '';
  Future<bool> startTrial() async {
    //if(kIsWeb)  return false;
    trial_date = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    bool r = await prefs.setString('trial_date', trial_date);
    print('-- startTrial() ' + r.toString() +' '+ trial_date);
    return r;
  }

  // 開始からの時間
  int? trialHour(){
    int? h = null;
    //if(kIsWeb) return h;
    print('-- trial_date = ' + trial_date);
    if(trial_date.length<8) return h;
    try {
      DateTime tri = DateTime.parse(trial_date);
      Duration dur = DateTime.now().difference(tri);
      h = dur.inHours;
    } on Exception catch (e) {
      print('-- trialHour() Exception ' + e.toString() + ' ' + trial_date);
    }
    return h;
  }

  /// 0.9=開始から4時間
  bool isTrial() {
    bool r = false;
    try {
      int? h = trialHour();
      if(h!=null)
        if (0 <= h && h < 2)
          r = true;
      print('-- isTrial() is ' + r.toString());
    } on Exception catch (e) {
      print('-- isTrial() Exception ' + e.toString());
    }
    return r;
  }

  /// 0.9=常に
  /// 1.0=開始から48時間
  bool canReTrial() {
    return true;
    bool r = true;
    try {
      int? h = trialHour();
      if(h!=null)
        if (0 <= h && h < 48)
          r = false;
    } on Exception catch (e) {
      print('-- isTrial() Exception ' + e.toString());
    }
    return r;
  }

  bool isPremium() {
    return isTrial();
  }

  Future load() async {
    //if(kIsWeb) return;
    print('-- load()');
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _loadSub(prefs, take_interval_sec);
      _loadSub(prefs, save_num);
      _loadSub(prefs, ex_storage);
      _loadSub(prefs, ex_save_num);
      _loadSub(prefs, autostop_sec);
      _loadSub(prefs, camera_height);
      _loadSub(prefs, camera_pos);
      trial_date = prefs.getString('trial_date') ?? '';
    } on Exception catch (e) {
      print('-- load() e=' + e.toString());
    }
  }
  _loadSub(SharedPreferences prefs, EnvData data) {
    data.set(prefs.getInt(data.name) ?? data.val);
  }

  Future save(EnvData data) async {
    //if(kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(data.name, data.val);
  }
}

final environmentProvider = ChangeNotifierProvider((ref) => environmentNotifier(ref));
class environmentNotifier extends ChangeNotifier {
  Environment env = Environment();

  environmentNotifier(ref){
    env.load().then((_){
      this.notifyListeners();
    });
  }

  Future saveData(EnvData data, int newVal) async {
    if(data.val == newVal)
      return;
    roundVal(data, newVal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(data.name, data.val);
    this.notifyListeners();
  }

  roundVal(EnvData data, int newVal){
    for (var i=0; i<data.vals.length; i++){
      if (newVal <= data.vals[i]){
        getData(data).val = data.vals[i];
        getData(data).key = data.keys[i];
        return;
      }
    }
    getData(data).val = data.vals[0];
    getData(data).key = data.keys[0];
  }

  EnvData getData(EnvData data){
    EnvData ret = env.take_interval_sec;
    switch(data.name){
      case 'autostop_sec': ret = env.autostop_sec; break;
      case 'save_num': ret = env.save_num; break;
      case 'ex_save_num': ret = env.ex_save_num; break;
      case 'ex_storage': ret = env.ex_storage; break;
      case 'camera_height': ret = env.camera_height; break;
      case 'camera_pos': ret = env.camera_pos; break;
    }
    return ret;
  }

  Future startTrial() async {
    env.trial_date = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    bool r = await prefs.setString('trial_date', env.trial_date);
    print('-- startTrial() ' + r.toString() +' '+ env.trial_date);
    this.notifyListeners();
  }
}