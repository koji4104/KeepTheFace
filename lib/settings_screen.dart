import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future load() async {
    if(kIsWeb)
      return;
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
  BuildContext? _context;
  WidgetRef? _ref;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      padding: EdgeInsets.symmetric(horizontal:14, vertical:3),
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

  String l10n(String text) {
    if(this._context!=null)
      return Localized.of(this._context!).text(text);
    else
      return text;
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
      _ref!.read(settingsScreenProvider).notifyListeners();
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
    int ex=env.ex_storage.val; // 0=none 1=library
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(8,8,8,8),
      child: Column(children: [
        MyValue(data: env.camera_height),
        MyValue(data: env.take_interval_sec),
        MyValue(data: env.save_num),
        MyValue(data: env.autostop_sec),
        MyText('Premium'),
        MyListTile(
          title:Text('Premium'),
          onTap:(){
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PremiumScreen(),
              )
            );
          }
        ),
        MyValue(data: env.ex_storage),
        if(ex==1) MyValue(data: env.ex_save_num),
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
        Navigator.of(_context!).push(
          MaterialPageRoute<int>(
            builder: (BuildContext context) {
              return RadioListScreen(data: data);
          })).then((ret) {
            if (data.val != ret) {
              data.set(ret);
              env.save(data);
              _ref!.read(settingsScreenProvider).notifyListeners();
            }
          }
        );
      }
    );
  }
}

//----------------------------------------------------------
final radioSelectedProvider = StateProvider<int>((ref) {
  return 0;
});
final radioListScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class RadioListScreen extends BaseSettingsScreen {
  int selected = 0;
  EnvData data;
  MyEdge _edge = MyEdge(provider:radioListScreenProvider);

  RadioListScreen({required EnvData this.data}){
    selected = data.val;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(radioSelectedProvider);
    ref.watch(radioListScreenProvider);
    this._context = context;
    this._ref = ref;
    _edge.getEdge(context,ref);

    return WillPopScope(
      onWillPop:() async {
        Navigator.of(context).pop(selected);
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n(data.name)), backgroundColor:Color(0xFF000000),),
        body: Container(
          margin: _edge.settingsEdge,
          child:getListView()
        ),
      )
    );
  }

  Widget getListView() {
    List<Widget> list = [];
    for(int i=0; i<data.vals.length; i++){
      list.add(
        Container(
          margin: EdgeInsets.symmetric(horizontal:14, vertical:0),
          child: RadioListTile(
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
          tileColor: Color(0xFF333333),
          activeColor: Colors.blueAccent,
          title: Text(l10n(data.keys[i])),
          value: data.vals[i],
          groupValue: selected,
          onChanged: (value) => _onRadioSelected(data.vals[i]),
      )));
    }
    list.add(MyText(data.name+'_desc')); // 説明
    return Column(children:list);
  }

  _onRadioSelected(value) {
    if(_ref!=null){
      selected = value;
      _ref!.read(radioSelectedProvider.state).state = selected;
    };
  }
}

//----------------------------------------------------------
final premiumScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class PremiumScreen extends BaseSettingsScreen {
  MyEdge _edge = MyEdge(provider:premiumScreenProvider);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(radioSelectedProvider);
    ref.watch(radioListScreenProvider);
    this._context = context;
    this._ref = ref;
    _edge.getEdge(context,ref);

    return WillPopScope(
        onWillPop:() async {
          return Future.value(true);
        },
        child: Scaffold(
          appBar: AppBar(title: Text('Premium'), backgroundColor:Color(0xFF000000),),
          body: Container(
            margin: _edge.settingsEdge,
            child:Container()
          ),
        )
    );
  }
}