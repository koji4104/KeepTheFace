import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'localizations.dart';
import 'log_screen.dart';
import 'common.dart';
import 'purchase_screen.dart';

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
    keys:['30','60','300','600'],
    name:'take_interval_sec',
  );

  /// 自動停止
  EnvData autostop_sec = EnvData(
    val:3600,
    vals:[60,3600,21600,43200,86400],
    keys:['60 sec','1','6','12','24'],
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
    vals:[100,500,1000],
    keys:['100','500','1000'],
    name:'ex_save_num',
  );

  /// 外部ストレージ 0=None 1=PhotoLibrary
  EnvData ex_storage = EnvData(
    val:0,
    vals:[0,1,2],
    keys:['None','PhotoLibrary','GoogleDrive'],
    name:'ex_storage',
  );

  EnvData camera_height = EnvData(
    val:480,
    vals:[240,480,720,1080],
    keys:['320X240','640x480','1280x720','1920x1080'],
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
    if(kIsWeb)  return false;
    String stime = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('trial_date', stime);
    return true;
  }

  // 開始から4時間
  bool isTrial() {
    bool r = false;
    if(kIsWeb) return r;
    if(trial_date.length<8)
      return r;
    try {
      DateTime tri = DateTime.parse(trial_date);
      Duration dur = DateTime.now().difference(tri);
      if(-1<dur.inMinutes && dur.inMinutes<245)
        r = true;
    } on Exception catch (e) {
      print('-- isTrial() Exception ' + e.toString());
    }
    return r;
  }

  // 開始から48時間
  bool canStartTrial() {
    bool r = true;
    if(kIsWeb) return true;
    if(trial_date.length<8)
      return true;
    try {
      DateTime tri = DateTime.parse(trial_date);
      Duration dur = DateTime.now().difference(tri);
      if(dur.inHours<48)
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
    if(kIsWeb) return;
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
    if(kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(data.name, data.val);
  }
}

//----------------------------------------------------------
class BaseSettingsScreen extends ConsumerWidget {
  late BuildContext _context;
  late WidgetRef _ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _context = context;
    _ref = ref;
    return Container();
  }

  Widget MyText(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical:10, horizontal:20),
        child: Text(label, style:TextStyle(fontSize:13, color:Colors.white)),
      )
    );
  }

  Widget MyListTile({required Widget title, required Function() onTap}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: ListTile(
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
          title: title,
          trailing: Icon(Icons.arrow_forward_ios),
          tileColor: Color(0xFF333333),
          hoverColor: Color(0xFF444444),
          onTap: onTap
      ),
    );
  }

  Widget MyRadioListTile(
      { required String title,
        required int value,
        required int groupValue,
        required void Function(int?)? onChanged}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal:14, vertical:0),
      child: RadioListTile(
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        tileColor: Color(0xFF333333),
        activeColor: Colors.blueAccent,
        title: Text(l10n(title)),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
      )
    );
  }

  String l10n(String text) {
    return Localized.of(this._context).text(text);
  }
}

//----------------------------------------------------------
final settingsScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class SettingsScreen extends BaseSettingsScreen {
  SettingsScreen(){}
  Environment env = new Environment();
  bool bInit = false;

  Future init() async {
    if(bInit) return;
      bInit = true;
    try {
      await env.load();
      _ref.read(settingsScreenProvider).notifyListeners();
    } on Exception catch (e) {
      print('-- SettingsScreen init e=' + e.toString());
    }
    return true;
  }

  MyEdge _edge = MyEdge(provider:settingsScreenProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _context = context;
    _ref = ref;
    Future.delayed(Duration.zero, () => init());
    ref.watch(settingsScreenProvider);

    _edge.getEdge(context,ref);
    print('-- build');
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(true);
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n("settings_title")),
          backgroundColor:Color(0xFF000000),
          actions: <Widget>[],
        ),
        body: Container(
          margin: _edge.settingsEdge,
          child: Stack(children: <Widget>[
            getList(context),
          ])
        )
      )
    );
  }

  Widget getList(BuildContext context) {
    TextStyle ts = TextStyle(fontSize:16, color:Colors.white);
    TextStyle tsOn = TextStyle(color:Colors.blueAccent);
    TextStyle tsNg = TextStyle(color:Colors.grey);
    bool pre = env.isPremium();
    int ex = env.ex_storage.val; // 0=none 1=library 2=Google
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(8,8,8,8),
      child: Column(children: [
        MyValue(data: env.camera_height),
        MyValue(data: env.take_interval_sec),
        MyValue(data: env.save_num),
        MyValue(data: env.autostop_sec),
        MyText('Premium'),
        MyListTile(
          title:Row(children:[
            Text('Premium'),
            Expanded(child: SizedBox(width:1)),
            env.isTrial() ? Text('ON',style:tsOn) : Text('OFF',style:tsNg),
          ]),
          onTap:(){
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PremiumScreen(),
              )
            );
          }
        ),
        if(pre)
          MyListTile(
            title:Row(children:[
              Text(l10n(env.ex_storage.name),style:ts),
              Expanded(child: SizedBox(width:1)),
              Text(l10n(env.ex_storage.key),style:ts),
            ]),
            onTap:(){
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ExStrageScreen(),
                )
              );
            }
          ),
        if(ex==1 || ex==2) MyValue(data: env.ex_save_num),
        MyText('Logs'),
        MyListTile(
          title:Text('Logs'),
          onTap:(){
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => LogScreen(),
              )
            );
          }
        ),
      ])
    );
  }

  Widget MyValue({required EnvData data}) {
    TextStyle ts = TextStyle(fontSize:16, color:Colors.white);
    return MyListTile(
      title:Row(children:[
        Text(l10n(data.name), style:ts),
        Expanded(child: SizedBox(width:1)),
        Text(l10n(data.key), style:ts),
      ]),
      onTap:() {
        Navigator.of(_context).push(
          MaterialPageRoute<int>(
            builder: (BuildContext context) {
              return RadioListScreen(data: data);
          })).then((ret) {
            if (ret==1) {
              env.load();
              _ref.read(settingsScreenProvider).notifyListeners();
            }
          }
        );
      }
    );
  }
}

//----------------------------------------------------------
final radioListScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class RadioListScreen extends BaseSettingsScreen {
  int selValue = 0;
  int selValueOld = 0;
  late EnvData data;
  Environment env = Environment();
  MyEdge _edge = MyEdge(provider:radioListScreenProvider);

  RadioListScreen({required EnvData data}){
    this.data = data;
    selValue = data.val;
    selValueOld = selValue;
    env.load();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(radioListScreenProvider);
    this._context = context;
    this._ref = ref;
    _edge.getEdge(context,ref);

    return WillPopScope(
      onWillPop:() async {
        int r = 0;
        if(selValueOld!=selValue) {
          data.set(selValue);
          env.save(data);
          r = 1;
        }
        Navigator.of(context).pop(r);
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n(data.name)), backgroundColor:Color(0xFF000000),),
        body: Container(
          margin: _edge.settingsEdge,
          child:getList()
        ),
      )
    );
  }

  Widget getList() {
    List<Widget> list = [];
    for(int i=0; i<data.vals.length; i++){
      list.add(
        MyRadioListTile(
          title: data.keys[i],
          value: data.vals[i],
          groupValue: selValue,
          onChanged:(value) => _onRadioSelected(data.vals[i]),
        )
      );
    }
    list.add(MyText(l10n(data.name+'_desc')));
    return Column(children:list);
  }

  _onRadioSelected(value) {
    selValue = value;
    _ref.watch(radioListScreenProvider).notifyListeners();
  }
}

//----------------------------------------------------------
// プレミアム
final premiumScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class PremiumScreen extends BaseSettingsScreen {
  MyEdge _edge = MyEdge(provider:premiumScreenProvider);
  Environment env = Environment();
  bool bInit = false;

  Future init() async {
    if(bInit) return;
    bInit = true;
    try {
      await env.load();
      _ref.read(premiumScreenProvider).notifyListeners();
    } on Exception catch (e) {
      print('-- PremiumScreen init e=' + e.toString());
    }
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(premiumScreenProvider);
    this._context = context;
    this._ref = ref;
    Future.delayed(Duration.zero, () => init());
    _edge.getEdge(context,ref);

    return WillPopScope(
      onWillPop:() async {
        Navigator.of(context).pop(1);
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Premium'), backgroundColor:Color(0xFF000000),),
        body: Container(
          margin: _edge.settingsEdge,
          child:getList(context),
        ),
      )
    );
  }

  Widget getList(BuildContext context) {
    TextStyle tsOn = TextStyle(color:Colors.blueAccent);
    TextStyle tsNg = TextStyle(color:Colors.grey);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(8,8,8,8),
      child: Column(children:[
        MyText('Trial'),
        MyListTile(
          title:Row(children:[
            Text('Trial'),
            Expanded(child: SizedBox(width:1)),
            env.isTrial() ? Text('ON',style:tsOn) : Text('OFF',style:tsNg),
          ]),
          onTap:(){
            env.startTrial();
            _ref.watch(premiumScreenProvider).notifyListeners();
          }
        ),
        MyText('Purchase'),
        MyListTile(
          title:Text('Purchase'),
          onTap:(){
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MyPurchase(),
              )
            );
          }
        ),
      ])
    );
  }
}

//----------------------------------------------------------
// 外部ストレージ
final exStragScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class ExStrageScreen extends BaseSettingsScreen {
  MyEdge _edge = MyEdge(provider:exStragScreenProvider);
  Environment env = Environment();
  int selValue = 0;
  int selValueOld = 0;
  late EnvData data;
  bool bInit = false;

  Future init() async {
    if(bInit) return;
    bInit = true;
    try {
      await env.load();
      data = env.ex_storage;
      _ref.read(exStragScreenProvider).notifyListeners();
    } on Exception catch (e) {
      print('-- ExStrageScreen init e=' + e.toString());
    }
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(exStragScreenProvider);
    this._context = context;
    this._ref = ref;
    Future.delayed(Duration.zero, () => init());
    _edge.getEdge(context,ref);

    return WillPopScope(
      onWillPop:() async {
        Navigator.of(context).pop(1);
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n('env.ex_storage.name')), backgroundColor:Color(0xFF000000),),
        body: Container(
          margin: _edge.settingsEdge,
          child:getList(),
        ),
      )
    );
  }

  Widget getList() {
    List<Widget> list = [];
    int i = 0;
    list.add(
      MyRadioListTile(
        title: env.ex_storage.keys[i],
        value: env.ex_storage.vals[i],
        groupValue: selValue,
        onChanged: (value) => _onRadioSelected(data.vals[i]),
      )
    );
    i++;
    list.add(
      MyRadioListTile(
        title: env.ex_storage.keys[i],
        value: env.ex_storage.vals[i],
        groupValue: selValue,
        onChanged: (value) => _onRadioSelected(env.ex_storage.vals[i]),
      )
    );
    i++;
    list.add(
      MyRadioListTile(
        title: env.ex_storage.keys[i],
        value: env.ex_storage.vals[i],
        groupValue: selValue,
        onChanged: (value) => _onRadioSelected(env.ex_storage.vals[i]),
      )
    );
    return Column(children:list);
  }

  _onRadioSelected(value) {
    selValue = value;
    _ref.read(exStragScreenProvider).notifyListeners();
  }
}