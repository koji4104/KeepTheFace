import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '/localizations.dart';
import 'log_screen.dart';
import '/common.dart';
import '/gdrive_adapter.dart';
import '/controllers/environment.dart';
import 'base_screen.dart';
import 'purchase_screen.dart';
import '/controllers/provider.dart';
import '/constants.dart';
import 'widgets.dart';

/// Settings
class SettingsScreen extends BaseSettingsScreen {
  late GoogleDriveAdapter gdriveAd;

  @override
  Future init() async {
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    subBuild(context, ref);
    this.gdriveAd = ref
        .watch(gdriveProvider)
        .gdrive;
    return Scaffold(
        appBar: AppBar(
          title: Text(l10n("settings_title")),
          backgroundColor: Color(0xFF000000),
          actions: <Widget>[],
        ),
        body:
        (is2screen())
            ? SingleChildScrollView(
            padding: EdgeInsets.all(8),
            child: Stack(children: [
              Container(
                margin: leftMargin(),
                child: getList(),
              ),
              Container(
                margin: rightMargin(),
                child: rightScreen != null ? rightScreen!.getList() : null,
              )
            ]))
            : SingleChildScrollView(
            padding: EdgeInsets.all(8),
            child: Container(
              margin: edge.settingsEdge,
              child: getList(),
            )
        )
    );
  }

  @override
  Widget getList() {
    bool pre = env.isPremium();
    int ex = env.ex_storage.val; // 0=none 1=Google
    String gd = '--';
    if (gdriveAd.isInitialized == false)
      gd = '--';
    else if (gdriveAd.isSignedIn())
      gd = 'ON';
    else if (gdriveAd.isSignedIn() == false) gd = 'OFF';

    return Column(children: [
      MyValue(data: env.take_mode),
      MyValue(data: env.camera_height),
      MyValue(data: env.photo_interval_sec),
      MyValue(data: env.split_interval_sec),
      MyValue(data: env.save_num),
      MyValue(data: env.saver_mode),
      MyValue(data: env.autostop_sec),
      MyListTile(
          title: MyText('Google Drive'),
          title2: MyText(gd),
          onPressed: () {
            if (is2screen()) {
              this.rightScreen = GoogleDriveScreen();
              this.rightScreen!.baseProvider = baseProvider;
              this.rightScreen!.subBuild(context, ref);
              redraw();
            } else {
              NavigatorPush(GoogleDriveScreen());
            }
          }
      ),

      if(IS_PREMIUM)
        MyLabel(''),
      if(IS_PREMIUM)
        MyLabel('Premium'),
      if(IS_PREMIUM)
        MyListTile(
          title: MyText('premium'),
          title2: env.isTrial() ? MyText('ON') : MyText('OFF'),
          onPressed: () => NavigatorPush(PremiumScreen()),
        ),
      MyLabel(''),
      MyListTile(
          title: MyText('Logs'),
          onPressed: () {
            Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LogScreen(),
                )
            );
          }
      ),
    ]);
  }
}

/// Premium
class PremiumScreen extends BaseSettingsScreen {
  @override
  Future init() async {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    subBuild(context,ref);
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
        MyListTile(
          title:MyText('trial'),
          title2:env.isTrial() ? MyText('ON') : Text('OFF')
        ),
        MyTextButton(
          title: 'trial',
          onPressed:() async {
            ref.read(environmentProvider).startTrial();
            redraw();
          }
        ),
        MyLabel(l10n('trial_desc')),

        MyLabel(''),
        MyLabel('Purchase'),
        MyListTile(title:Text(l10n('Purchase_desc'))),
        MyTextButton(
          title: 'Purchase',
            onPressed:(){
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
  GoogleDriveAdapter? gdriveAd;

  @override
  Future init() async {
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    subBuild(context, ref);
    return Scaffold(
      appBar: AppBar(title: Text(l10n('Google Drive')), backgroundColor: Color(0xFF000000),),
      body: Container(
        margin: edge.settingsEdge,
        child: getList(),
      ),
    );
  }

  @override
  void subBuild(BuildContext context, WidgetRef ref) {
    super.subBuild(context, ref);
    this.gdriveAd = ref.watch(gdriveProvider).gdrive;
  }

  @override
  Widget getList() {
    if (gdriveAd == null || gdriveAd!.isInitialized == false) {
      return Center(
        child: SizedBox(
          width: 32, height: 32,
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Column(children: [
        MyLabel(''),
        if(gdriveAd!.isSignedIn() == false)
          MyGoogleTile(title: l10n('not_login')),
        if(gdriveAd!.isSignedIn())
          MyGoogleTile(title: gdriveAd!.getAccountName()),
        MyLabel(''),
        if(gdriveAd!.isSignedIn() == false)
          MyTextButton(
              width: 200,
              title: l10n('login'),
              onPressed: () {
                ref.watch(gdriveProvider).loginWithGoogle();
              }
          ),
        if(gdriveAd!.isSignedIn())
          MyTextButton(
              width: 220,
              title: l10n('logout'),
              onPressed: () {
                ref.watch(gdriveProvider).logout();
              }
          ),
        if(gdriveAd!.loginerr != '')
          MyListTile(title: MyText(gdriveAd!.loginerr), title2: Text('')),
      ]);
    };
  }

  Widget MyGoogleTile({required String title}) {
    return Container(
      width: 220,
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(title, style: TextStyle(color: textColor, fontSize: 16), textAlign: TextAlign.center),
    );
  }
}