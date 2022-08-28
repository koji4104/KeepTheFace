import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'localizations.dart';
import 'log_screen.dart';
import 'common.dart';
import 'gdrive_adapter.dart';
import 'environment.dart';
import 'base_settings_screen.dart';
import 'purchase_screen.dart';

bool IS_PREMIUM = false;

//----------------------------------------------------------
class SettingsScreen extends BaseSettingsScreen {
  @override
  Future init() async {
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context, ref);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n("settings_title")),
        backgroundColor:Color(0xFF000000),
        actions: <Widget>[],
      ),
      body: Container(
        margin: edge.settingsEdge,
        child: Stack(children: <Widget>[
          getList(context),
        ])
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

        if(IS_PREMIUM)
        MyLabel(''),
        if(IS_PREMIUM)
        MyLabel(l10n('premium')),
        if(IS_PREMIUM)
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
  late EnvData data;

  RadioListScreen({required EnvData data}){
    this.data = data;
    selVal = data.val;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context, ref);
    return Scaffold(
      appBar: AppBar(title: Text(l10n(data.name)), backgroundColor:Color(0xFF000000),),
      body: Container(
        margin: edge.settingsEdge,
        child:getList()
      ),
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
    ref.read(environmentProvider).saveData(data,selVal);
  }
}

//----------------------------------------------------------
// プレミアム
class PremiumScreen extends BaseSettingsScreen {
  @override
  Future init() async {
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context, ref);
    return  Scaffold(
      appBar: AppBar(title:Text(l10n('premium')), backgroundColor:Color(0xFF000000),),
      body: Container(
        margin: edge.settingsEdge,
        child:getList(),
      ),
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
          ok: true,
          onTap:() async {
            ref.read(environmentProvider).startTrial();
            redraw();
          }
        ),
        MyLabel(l10n('trial_desc')),

        MyLabel(''),
        MyLabel('Purchase'),
        MyTile(
          title:Text(l10n('Purchase_desc')),
        ),
        MyButton(
          title: 'Purchase',
          ok: true,
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
final exstragScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class ExStrageScreen extends BaseSettingsScreen {
  int selVal = 0;
  late EnvData data;
  GoogleDriveAdapter gdriveAd = GoogleDriveAdapter();

  @override
  Future init() async {
    selVal = env.ex_storage.val;
    redraw();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context, ref);
    return Scaffold(
      appBar: AppBar(title: Text(l10n('env.ex_storage.name')), backgroundColor:Color(0xFF000000),),
      body: Container(
        margin: edge.settingsEdge,
        child:getList(),
      ),
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
    ref.read(environmentProvider).saveData(env.ex_storage,selVal);
  }
}