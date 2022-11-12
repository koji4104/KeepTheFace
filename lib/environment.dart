import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:io';
import 'constants.dart';

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

  /// 1photo 2audio 3photo+audio 4video
  EnvData take_mode = EnvData(
    val:1,
    vals:[1,2,3,4],
    keys:['photo','audio','photo_audio','video'],
    name:'take_mode',
  );

  /// 間隔
  EnvData photo_interval_sec = EnvData(
    val:60,
    vals:[30,60,120,300,600,900],
    keys:['30 sec','1 min','2 min','5 min','10 min','15 min'],
    name:'photo_interval_sec',
  );

  /// 分割
  EnvData split_interval_sec = EnvData(
    val:300,
    vals:IS_TEST?
         [30,300,600]:
         [300,600],
    keys:IS_TEST?
         ['30 sec','5 min','10 min']:
         ['5 min','10 min'],
    name:'split_interval_sec',
  );

  /// 自動停止
  EnvData autostop_sec = EnvData(
    val:7200,
    vals:IS_TEST?
         [0,120,3600,7200,14400,21600,43200,86400]:
         [0,1800,3600,7200,14400,21600,43200,86400],
    keys:IS_TEST?
         ['Nonstop','2 min','1 hour','2 hour','4 hour','6 hour','12 hour','24 hour']:
         ['Nonstop','30 min','1 hour','2 hour','4 hour','6 hour','12 hour','24 hour'],
    name:'autostop_sec',
  );

  /// Num of Save
  EnvData save_num = EnvData(
    val:100,
    vals:IS_TEST?
         [20,500,1000]:
         [100,500,1000],
    keys:IS_TEST?
         ['20','500','1000']:
         ['100','500','1000'],
    name:'save_num',
  );

  EnvData ex_save_num = EnvData(
    val:100,
    vals:[100,500],
    keys:['100','500'],
    name:'ex_save_num',
  );

  /// 外部ストレージ 0=None 1=GoogleDrive
  EnvData ex_storage = EnvData(
    val:0,
    vals:[0,1,2],
    keys:['None','GoogleDrive'],
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

  // Zoom x10
  EnvData camera_zoom = EnvData(
    val:10,
    vals:[10,20,30,40],
    keys:['1.0','2.0','3.0','4.0'],
    name:'camera_zoom',
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
    return false;
    //return isTrial();
  }

  Future load() async {
    //if(kIsWeb) return;
    print('-- load()');
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _loadSub(prefs, take_mode);
      _loadSub(prefs, photo_interval_sec);
      _loadSub(prefs, split_interval_sec);
      _loadSub(prefs, save_num);
      _loadSub(prefs, ex_storage);
      _loadSub(prefs, ex_save_num);
      _loadSub(prefs, autostop_sec);
      _loadSub(prefs, camera_height);
      _loadSub(prefs, camera_zoom);
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

  Future saveDataNoRound(EnvData data, int newVal) async {
    if(data.val == newVal)
      return;
    data.val = newVal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(data.name, data.val);
    this.notifyListeners();
  }

  EnvData getData(EnvData data){
    EnvData ret = env.take_mode;
    switch(data.name){
      case 'take_mode': ret = env.take_mode; break;
      case 'photo_interval_sec': ret = env.photo_interval_sec; break;
      case 'split_interval_sec': ret = env.split_interval_sec; break;
      case 'autostop_sec': ret = env.autostop_sec; break;
      case 'save_num': ret = env.save_num; break;
      case 'ex_save_num': ret = env.ex_save_num; break;
      case 'ex_storage': ret = env.ex_storage; break;
      case 'camera_height': ret = env.camera_height; break;
      case 'camera_zoom': ret = env.camera_zoom; break;
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