import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';

import 'log_screen.dart';
import '/controllers/gdrive_adapter.dart';
import '/controllers/environment.dart';
import '/commons/base_screen.dart';
import 'purchase_screen.dart';
import '/controllers/provider.dart';
import '/constants.dart';
import '/commons/widgets.dart';

/// Settings
class SettingsScreen extends BaseSettingsScreen {
  late GoogleDriveAdapter gdriveAd;

  @override
  Future init() async {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);
    this.gdriveAd = ref.watch(gdriveProvider).gdrive;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n("settings_title")),
        backgroundColor: Color(0xFF000000),
        actions: <Widget>[],
      ),
      body: (is2screen())
          ? SingleChildScrollView(
              padding: EdgeInsets.all(8),
              child: Stack(
                children: [
                  Container(
                    margin: leftMargin(),
                    child: getList(),
                  ),
                  Container(
                    margin: rightMargin(),
                    child: rightScreen != null ? rightScreen!.getList() : null,
                  )
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(8),
              child: Container(
                margin: edge.settingsEdge,
                child: getList(),
              ),
            ),
    );
  }

  @override
  Widget getList() {
    bool pre = env.isPremium();
    int ex = env.ex_storage_type.val; // 0=none 1=Google
    String gd = '--';
    if (gdriveAd.isInitialized == false)
      gd = '--';
    else if (gdriveAd.isSignedIn())
      gd = 'ON';
    else if (gdriveAd.isSignedIn() == false) gd = 'OFF';
    bool isImage = env.take_mode == 1;
    bool isAudio = env.take_mode == 2;
    bool isVideo = env.take_mode == 4;
    return Column(
      children: [
        MyValue(data: env.take_mode),
        MyValue(data: env.image_interval_sec),
        MyValue(data: env.image_camera_height),
        MyValue(data: env.video_camera_height),
        MyValue(data: env.in_save_mb),
        MyValue(data: env.ex_save_mb),
        MyValue(data: env.screensaver_mode),
        MyValue(data: env.timer_mode),
        MyValue(data: env.timer_stop_sec),
        MyValue(data: env.timer_start_hour),
        MyListTile(
          title: MyText('Prefix'),
          title2: MyText(env.file_prefix),
          onPressed: () {
            if (is2screen()) {
              this.rightScreen = EditTextScreen();
              this.rightScreen!.baseProvider = baseProvider;
              this.rightScreen!.build(context, ref);
            } else {
              NavigatorPush(EditTextScreen());
            }
          },
        ),
        MyListTile(
          title: MyText(l10n('ex_storage_type')),
          title2: MyText(gd),
          onPressed: () {
            if (is2screen()) {
              this.rightScreen = GoogleDriveScreen();
              this.rightScreen!.baseProvider = baseProvider;
              this.rightScreen!.build(context, ref);
            } else {
              NavigatorPush(GoogleDriveScreen());
            }
          },
        ),
        if (IS_PREMIUM) MyLabel(''),
        if (IS_PREMIUM) MyLabel('Premium'),
        if (IS_PREMIUM)
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
              ),
            );
          },
        ),
        MyListTile(
          title: MyText('Licenses'),
          onPressed: () async {
            final info = await PackageInfo.fromPlatform();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) {
                return LicensePage(
                  applicationName: 'Keep the face',
                  applicationVersion: info.version,
                  applicationIcon: Container(
                    padding: EdgeInsets.all(8),
                    child: kIsWeb
                        ? Image.network('/lib/assets/appicon.png', width: 32, height: 32)
                        : Image(image: AssetImage('lib/assets/appicon.png'), width: 32, height: 32),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

/// Premium
class PremiumScreen extends BaseSettingsScreen {
  @override
  Future init() async {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n('premium')),
        backgroundColor: Color(0xFF000000),
      ),
      body: Container(
        margin: edge.settingsEdge,
        child: getList(),
      ),
    );
  }

  Widget getList() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        children: [
          MyLabel(l10n('premium_desc')),
          MyListTile(title: MyText('trial'), title2: env.isTrial() ? MyText('ON') : Text('OFF')),
          MyTextButton(
            title: 'trial',
            onPressed: () async {
              ref.read(environmentProvider).startTrial();
            },
          ),
          MyLabel(l10n('trial_desc')),
          MyLabel(''),
          MyLabel('Purchase'),
          MyListTile(title: Text(l10n('Purchase_desc'))),
          MyTextButton(
            title: 'Purchase',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => MyPurchase(),
              ));
            },
          ),
        ],
      ),
    );
  }
}

/// GoogleDrive
class GoogleDriveScreen extends BaseSettingsScreen {
  GoogleDriveAdapter? gdriveAd;
  bool bInit = false;

  @override
  Future init() async {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    subBuild(context, ref);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n('Google Drive')),
        backgroundColor: Color(0xFF000000),
      ),
      body: Container(
        margin: edge.settingsEdge,
        child: getList(),
      ),
    );
  }

  @override
  void subBuild(BuildContext context, WidgetRef ref) {
    super.build(context, ref);
    this.gdriveAd = ref.watch(gdriveProvider).gdrive;
    if (bInit == false && gdriveAd != null && gdriveAd!.isInitialized) {
      ref.watch(gdriveProvider).getFiles();
    }
  }

  @override
  Widget getList() {
    if (gdriveAd == null || gdriveAd!.isInitialized == false) {
      return Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Column(children: [
        MyLabel(''),
        MyGoogleTile(),
        SizedBox(height: 4),
        if (gdriveAd!.isSignedIn() == false)
          MyTextButton(
            width: 220,
            title: l10n('google_login'),
            onPressed: () {
              ref.watch(gdriveProvider).loginWithGoogle();
            },
          ),
        if (gdriveAd!.isSignedIn())
          MyTextButton(
            width: 220,
            title: l10n('google_logout'),
            onPressed: () {
              ref.watch(gdriveProvider).logout();
            },
          ),
        MyLabel(l10n('gdrive_note')),
        if (gdriveAd!.loginerr != '') MyListTile(title: MyText(gdriveAd!.loginerr), title2: Text(''), textonly: true),
      ]);
    }
  }

  Widget MyGoogleTile() {
    String txt = "";
    if (gdriveAd!.isSignedIn() == false) {
      txt = l10n('not_login');
    } else {
      txt += gdriveAd!.getAccountName();
      txt += "\n" + gdriveAd!.getFileMb().toString() + " mb";
      txt += "\n" + gdriveAd!.getFileCount().toString() + " pcs";
    }
    return Container(
      width: 210,
      height: 100,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Center(
        child: Text(txt, style: TextStyle(fontSize: 14), textAlign: TextAlign.center),
      ),
    );
  }
}

/// Edit text
class EditTextScreen extends BaseSettingsScreen {
  String _text = '';
  String _textOld = '';
  TextEditingController _textController = TextEditingController(text: "");

  EditTextScreen() {}

  @override
  Future init() async {
    _text = _textOld = this.env.file_prefix;
    _textController = TextEditingController(text: _text);
    redraw();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);
    return Scaffold(
      appBar: AppBar(title: Text('URL ${num}'), backgroundColor: Color(0xFF000000)),
      body: Container(
        margin: edge.settingsEdge,
        child: getList(),
      ),
    );
  }

  Widget getList() {
    bool isChanged = (_textOld != _textController.text);
    double buttonWidth = 100.0;
    return Column(children: [
      MyLabel('Prefix'),
      MyTextField(controller: _textController, keyboardType: TextInputType.text),
      MyLabel(''),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        MyTextButton(
          width: buttonWidth,
          title: l10n('Undo'),
          cancelStyle: isChanged ? null : true,
          onPressed: isChanged
              ? () async {
                  _textController.text = _textOld;
                  redraw();
                }
              : null,
        ),
        MyTextButton(
          width: buttonWidth,
          title: l10n('Save'),
          cancelStyle: isChanged ? null : true,
          onPressed: isChanged
              ? () async {
                  _text = _textOld = _textController.text;
                  ref.read(environmentProvider).saveFilePrefix(_text);
                }
              : null,
        ),
        MyTextButton(
          width: buttonWidth,
          title: l10n('None'),
          cancelStyle: isChanged ? null : true,
          onPressed: isChanged
              ? () async {
                  _textController.text = "";
                  redraw();
                }
              : null,
        ),
      ]),
      MyLabel('e.g. xxxx-2023-1001-101010.jpg\nNone=2023-1001-101010.jpg'),
    ]);
  }

  Widget MyTextField({required TextEditingController controller, TextInputType? keyboardType}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      child: TextField(
        style: TextStyle(color: Colors.white, fontSize: 14),
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: [
          LengthLimitingTextInputFormatter(8),
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
        ],
        onChanged: (_) {
          redraw();
        },
      ),
    );
  }
}
