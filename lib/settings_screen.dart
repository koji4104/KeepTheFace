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
import 'provider.dart';
import 'constants.dart';

/// Settings
class SettingsScreen extends BaseSettingsScreen {
  late GoogleDriveAdapter gdriveAd;
  @override
  Future init() async {
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context, ref);
    this.gdriveAd = ref.watch(gdriveProvider).gdrive;

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
    bool pre = env.isPremium();
    int ex = env.ex_storage.val; // 0=none 1=Google
    String gd = '--';
    if(gdriveAd.isInitialized==false) gd='--';
    else if(gdriveAd.isSignedIn()) gd='ON';
    else if(gdriveAd.isSignedIn()==false) gd='OFF';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(8,8,8,8),
      child: Column(children: [
        MyLabel('Settings'),
        MyValue(data: env.take_mode),
        MyValue(data: env.camera_height),
        MyValue(data: env.photo_interval_sec),
        MyValue(data: env.split_interval_sec),
        MyValue(data: env.save_num),
        MyValue(data: env.autostop_sec),
        MyListTile(
            title:MyText('Google Drive'),
            title2:MyText(gd),
            onTap:() => NavigatorPush(GoogleDriveScreen()),
        ),

        if(IS_PREMIUM)
        MyLabel(''),
        if(IS_PREMIUM)
        MyLabel('Premium'),
        if(IS_PREMIUM)
        MyListTile(
            title:MyText('premium'),
            title2:env.isTrial() ? MyText('ON') : MyText('OFF'),
            onTap:() => NavigatorPush(PremiumScreen()),
        ),
        /*
        if(pre)
          MyListTile(
            title:Text(l10n(env.ex_storage.name),style:ts),
            title2:Text(l10n(env.ex_storage.key),style:ts),
            onTap:(){
              NavigatorPush(ExStrageScreen());
            }
          ),
        if(ex==1 || ex==2) MyValue(data: env.ex_save_num),
        */

        MyLabel(''),
        MyLabel('Logs'),
        MyListTile(
          title:MyText('Logs'),
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

/// Premium
class PremiumScreen extends BaseSettingsScreen {
  @override
  Future init() async {
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context,ref);
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
          title:MyText('trial'),
          title2:env.isTrial() ? MyText('ON') : Text('OFF')
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
        MyTile(title:Text(l10n('Purchase_desc'))),
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

/// GoogleDrive
class GoogleDriveScreen extends BaseSettingsScreen {
  int selVal = 0;
  late EnvData data;
  late GoogleDriveAdapter gdriveAd;

  @override
  Future init() async {
    selVal = env.ex_storage.val;
    redraw();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context, ref);
    this.gdriveAd = ref.watch(gdriveProvider).gdrive;
    return Scaffold(
      appBar: AppBar(title: Text(l10n('Google Drive')), backgroundColor:Color(0xFF000000),),
      body: Container(
        margin: edge.settingsEdge,
        child:getList(),
      ),
    );
  }

  Widget getList() {
    if (gdriveAd.isInitialized == false) {
      return Center(
        child: SizedBox(
          width:32,height:32,
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Column(children: [
        if(gdriveAd.isSignedIn() == false)
          MyTile(title: MyText('not_login')),
        if(gdriveAd.isSignedIn())
          MyTile(title: Text(gdriveAd.getAccountName())),

        if(gdriveAd.isSignedIn() == false)
          MyTextButton(
              label: 'Login',
              onPressed: () {
                gdriveAd.loginWithGoogle().then((_) {
                  redraw();
                });
              }
          ),
        if(gdriveAd.isSignedIn())
          MyTextButton(
              label: 'Logout',
              onPressed: () {
                gdriveAd.logout().then((_) {
                  redraw();
                });
              }
          ),

        if(gdriveAd.loginerr == '')
          MyTile(title: MyText(gdriveAd.loginerr), title2: Text('')),

      ]);
    };
  }
}