import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'localizations.dart';
import 'log_screen.dart';
import 'common.dart';
import 'gdrive_adapter.dart';
import 'environment.dart';

//----------------------------------------------------------
class BaseSettingsScreen extends ConsumerWidget {
  late BuildContext _context;
  late WidgetRef _ref;
  final _baseProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
  late MyEdge _edge = MyEdge(provider:_baseProvider);

  bool bInit = false;
  Environment env = new Environment();

  TextStyle tsOn = TextStyle(color:Colors.lightGreenAccent);
  TextStyle tsNg = TextStyle(color:Colors.grey);

  Color btnTextColor = Colors.white;
  Color btnTileColor = Color(0xFF404040);
  Color btnHoverColor = Color(0xFF505050);

  Color tileColor = Color(0xFF404040);
  Color hoverColor = Color(0xFF505050);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container();
  }

  @override
  Future init() async {
    if(bInit) return;
    env.load().then((_){
      redraw();
    });
    bInit = true;
  }

  void baseBuild(BuildContext context, WidgetRef ref) {
    _context = context;
    _ref = ref;
    _edge.getEdge(context,ref);
    ref.watch(_baseProvider);
    Future.delayed(Duration.zero, () => init());
  }

  Widget MyLabel(String label) {
    return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal:12, vertical:4),
          child: Text(label, style:TextStyle(fontSize:13, color:Colors.white)),
        )
    );
  }

  Widget MyListTile({required Widget title, Widget? title2, required Function() onTap}) {
    Widget exp = Expanded(child: SizedBox(width:1));
    return Container(
      padding: EdgeInsets.symmetric(vertical:2, horizontal:8),
      child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
          title: title2!=null ?
          Row(children:[title, exp, title2]) :
          Row(children:[exp, title, exp]),
          trailing: Icon(Icons.arrow_forward_ios),
          tileColor: tileColor,
          hoverColor: hoverColor,
          onTap: onTap
      ),
    );
  }

  Widget MyTile({required Widget title, Widget? title2}) {
    Widget exp = Expanded(child: SizedBox(width:1));
    return Container(
      padding: EdgeInsets.symmetric(vertical:2, horizontal:8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
        title: title2!=null ?
        Row(children:[title, exp, title2]) :
        Row(children:[exp, title, exp]),
        tileColor: Color(0xFF000000),
      ),
    );
  }

  Widget MyButton({required String title, required Function() onTap}) {
    Widget exp = Expanded(child: SizedBox(width:1));
    return Container(
      padding: EdgeInsets.symmetric(vertical:2, horizontal:80),
      child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
          title: Row(children:[
            exp,
            Text(title,style:TextStyle(color:btnTextColor)),
            exp
          ]),
          tileColor: btnTileColor,
          hoverColor: btnHoverColor,
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
        margin: EdgeInsets.symmetric(vertical:2, horizontal:8),
        child: RadioListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
          tileColor: tileColor,
          activeColor: Colors.white,
          title: Text(l10n(title)),
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
        )
    );
  }

  Future<int> NavigatorPush(var screen) async {
    int? ret = await Navigator.of(_context).push(
        MaterialPageRoute<int>(
            builder: (context) {
              return screen;
            }
        )
    );
    ret = ret ?? 0;
    if (ret==1) {
      env.load().then((_) {
        redraw();
      });
    }
    return ret;
  }

  String l10n(String text) {
    return Localized.of(this._context).text(text);
  }

  redraw(){
    _ref.read(_baseProvider).notifyListeners();
  }
}

//----------------------------------------------------------
class SettingsScreen extends BaseSettingsScreen {
  @override
  Future init() async {
    if(bInit) return;
    super.init();
    bInit = true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context, ref);

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
    bool pre = env.isPremium();
    int ex = env.ex_storage.val; // 0=none 1=library 2=Google
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(8,8,8,8),
      child: Column(children: [
        MyValue(data: env.camera_height),
        MyValue(data: env.take_interval_sec),
        MyValue(data: env.save_num),
        MyValue(data: env.autostop_sec),
        MyLabel(''),
        MyLabel(l10n('premium')),
        MyListTile(
          title:Text(l10n('premium')),
          title2:env.isTrial() ? Text('ON',style:tsOn) : Text('OFF',style:tsNg),
          onTap:(){
            NavigatorPush(PremiumScreen());
          }
        ),
        if(pre)
          MyListTile(
            title:Text(l10n(env.ex_storage.name),style:ts),
            title2:Text(l10n(env.ex_storage.key),style:ts),
            onTap:(){
              NavigatorPush(ExStrageScreen());
            }
          ),
        if(ex==1 || ex==2) MyValue(data: env.ex_save_num),
        MyLabel(''),
        MyLabel('Logs'),
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
        title:Text(l10n(data.name), style:ts),
        title2:Text(l10n(data.key), style:ts),
        onTap:() {
          NavigatorPush(RadioListScreen(data:data));
        }
    );
  }
}

//----------------------------------------------------------
class RadioListScreen extends BaseSettingsScreen {
  int selVal = 0;
  int selOld = 0;
  late EnvData data;

  RadioListScreen({required EnvData data}){
    this.data = data;
    selVal = data.val;
    selOld = selVal;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context, ref);
    return WillPopScope(
      onWillPop:() async {
        int r = 0;
        if(selOld!=selVal) {
          data.set(selVal);
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
          groupValue: selVal,
          onChanged:(value) => _onRadioSelected(data.vals[i]),
        )
      );
    }
    list.add(MyLabel(l10n(data.name+'_desc')));
    return Column(children:list);
  }

  _onRadioSelected(value) {
    selVal = value;
    redraw();
  }
}

//----------------------------------------------------------
// プレミアム
class PremiumScreen extends BaseSettingsScreen {
  @override
  Future init() async {
    if(bInit) return;
    super.init();
    bInit = true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context, ref);
    return WillPopScope(
      onWillPop:() async {
        Navigator.of(context).pop(1);
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(title:Text(l10n('premium')), backgroundColor:Color(0xFF000000),),
        body: Container(
          margin: _edge.settingsEdge,
          child:getList(),
        ),
      )
    );
  }

  Widget getList() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(8,8,8,8),
      child: Column(children:[
        MyLabel(l10n('premium_desc')),
        MyTile(
          title:Text(l10n('trial')),
          title2:env.isTrial() ? Text('ON',style:tsOn) : Text('OFF',style:tsNg)
        ),
        MyButton(
          title: 'trial',
          onTap:() async {
            await env.startTrial();
            redraw();
          }
        ),
        MyLabel(l10n('trial_desc')),
        /*
        MyLabel(''),
        MyLabel('Purchase'),
        MyTile(
          title:Text(l10n('Purchase_desc')),
        ),
        MyListTile(
          title:Text('Purchase'),
          onTap:(){
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MyPurchase(),
              )
            );
          }
        ),*/
      ])
    );
  }
}

//----------------------------------------------------------
// 外部ストレージ
final exstragScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class ExStrageScreen extends BaseSettingsScreen {
  MyEdge _edge = MyEdge(provider:exstragScreenProvider);
  Environment env = Environment();
  int selVal = 0;
  int selOld = 0;
  late EnvData data;
  bool bInit = false;
  GoogleDriveAdapter gdriveAd = GoogleDriveAdapter();

  @override
  Future init() async {
    if(bInit) return;
    try {
      await env.load();
      selVal = env.ex_storage.val;
      selOld = selVal;
      await gdriveAd.loginSilently();
      redraw();
    } on Exception catch (e) {
      print('-- ExStrageScreen init e=' + e.toString());
    }
    bInit = true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context, ref);
    return WillPopScope(
      onWillPop:() async {
        int r = 0;
        if(selOld!=selVal) {
          env.ex_storage.set(selVal);
          env.save(env.ex_storage);
          r = 1;
        }
        Navigator.of(context).pop(r);
        return Future.value(false);
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
    return Column(children:[
      MyRadioListTile(
        title: env.ex_storage.keys[0],
        value: env.ex_storage.vals[0],
        groupValue: selVal,
        onChanged: (value) => _onRadioSelected(env.ex_storage.vals[0]),
      ),
      MyRadioListTile(
        title: env.ex_storage.keys[1],
        value: env.ex_storage.vals[1],
        groupValue: selVal,
        onChanged: (value) => _onRadioSelected(env.ex_storage.vals[1]),
      ),
      MyRadioListTile(
        title: env.ex_storage.keys[2],
        value: env.ex_storage.vals[2],
        groupValue: selVal,
        onChanged: (value) => _onRadioSelected(env.ex_storage.vals[2]),
      ),

      MyLabel(''),
      MyLabel('GoogleDrive'),
      if(gdriveAd.isSignedIn()==false)
        MyTile(title:Text('OFF',style:tsNg),title2:Text('')),

      if(gdriveAd.isSignedIn()==true)
        MyTile(title:Text(gdriveAd.getAccountName(),style:tsOn),title2:Text('')),

      if(gdriveAd.isSignedIn()==false)
        MyButton(
          title:'Login GoogleDrive',
          onTap:() {
            gdriveAd.loginWithGoogle().then((r){
              if(r) redraw();
            });
          }
        ),

      if(gdriveAd.isSignedIn()==true)
        MyButton(
          title:'Logout GoogleDrive',
          onTap:() {
            gdriveAd.logout().then((_){
              redraw();
            });
          }
        ),
    ]);
  }

  _onRadioSelected(value) {
    selVal = value;
    redraw();
  }
}