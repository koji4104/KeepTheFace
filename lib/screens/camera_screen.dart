import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'photolist_screen.dart';
import 'settings_screen.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as imglib;
import 'package:wakelock/wakelock.dart';
import 'package:record/record.dart';
import 'package:path/path.dart';

import 'package:disk_space/disk_space.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/controllers/camera_controller.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'log_screen.dart';
import '/common.dart';
import 'camera_adapter.dart';
import '/controllers/environment.dart';
import '/constants.dart';
import 'widgets.dart';
import 'base_screen.dart';

bool disableCamera = kIsWeb; // true=test

const Color COL_SS_TEXT = Color(0xFF808080);

class CameraScreen extends BaseScreen with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Record _record = Record();
  StateData _state = StateData();

  int _takeCount = 0;
  DateTime? _photoTime;
  DateTime? _videoTime;
  DateTime? _audioTime;
  DateTime? _waitTime;
  bool _bLogExstrageFull = true;

  Timer? _timer;
  ResolutionPreset _preset = ResolutionPreset.high; // 1280x720
  ImageFormatGroup _imageFormat = ImageFormatGroup.bgra8888;
  int _zoom10 = 10;

  final Battery _battery = Battery();
  int _batteryLevel = -1;
  int _batteryLevelStart = -1;
  MyStorage _storage = new MyStorage();

  @override
  Future init() async {
    _timer = Timer.periodic(Duration(seconds: 1), _onTimer);
    _initCameraSync(ref);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    if(_controller!=null) _controller!.dispose();
    if(_timer!=null) _timer!.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  // low 320x240 (4:3)
  // medium 640x480 (4:3)
  // high 1280x720
  // veryHigh 1920x1080
  // ultraHigh 3840x2160
  ResolutionPreset getPreset() {
    ResolutionPreset p = ResolutionPreset.high;
    int h = env.camera_height.val;
    if(h>=2160) p = ResolutionPreset.ultraHigh;
    else if(h>=1080) p = ResolutionPreset.veryHigh;
    else if(h>=720) p = ResolutionPreset.high;
    else if(h>=480) p = ResolutionPreset.medium;
    else if(h>=240) p = ResolutionPreset.low;
    return p;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive: print('-- inactive'); break;
      case AppLifecycleState.paused: print('-- paused'); break;
      case AppLifecycleState.resumed: print('-- resumed'); break;
      case AppLifecycleState.detached: print('-- detached'); break;
    }
    if(_state.isRunning==true && state!=null) {
      if (state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.detached) {
        MyLog.warn("App stopped or background");
        onStop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    subBuild(context, ref);
    this._state = ref
        .watch(stateProvider)
        .state;

    if (kIsWeb == false) {
      if (_state.isSaver) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
        Wakelock.enable();
      } else {
        //SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays:[]);
        //Wakelock.disable();
      }
    }

    if (_zoom10 != env.camera_zoom.val) {
      print('-- zoom ${env.camera_zoom.val}');
      zoomCamera(env.camera_zoom.val);
    }

    return Scaffold(
        key: _scaffoldKey,
        extendBody: true,
        body: Container(
          margin: edge.homebarEdge,
          child: Stack(children: <Widget>[

            // screen saver
            if (_state.isSaver == true)
              blackScreen(
                onPressed: () {
                  _waitTime = DateTime.now();
                  redraw();
                },
              ),

            // STOP
            if (_state.isSaver == true)
              if (env.saver_mode.val == 1 || (env.saver_mode.val == 2 && _waitTime != null))
                stopButton(
                    onPressed: () {
                      _waitTime = null;
                      ref.read(stateProvider).stop();
                    }
                ),

            if((_state.isSaver == false && env.saver_mode.val != 0) && env.take_mode.val != 2)
              _cameraWidget(context),

            // START
            if (_state.isSaver == false)
              recordButton(
                onPressed: () {
                  _waitTime = DateTime.now();
                  onStart();
                },
              ),

            // Camera Switch button
            if(_state.isSaver == false && env.take_mode.val != 2)
              MyIconButton(
                bottom: 40.0, right: 30.0,
                icon: Icon(Icons.autorenew, color: Colors.white),
                onPressed: () => _onCameraSwitch(ref),
              ),

            // PhotoList screen button
            if(_state.isSaver == false)
              MyIconButton(
                  top: 50.0, right: 30.0,
                  icon: Icon(Icons.folder, color: Colors.white),
                  onPressed: () async {
                    await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PhotoListScreen(),
                        )
                    );
                  }
              ),

            // Zoom button
            if(_state.isSaver == false && env.take_mode.val != 2)
              optionButton(context),

            // Settings button
            if(_state.isSaver == false)
              MyIconButton(
                  top: 50.0, left: 30.0,
                  icon: Icon(Icons.settings, color: Colors.white),
                  onPressed: () async {
                    await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(),
                        )
                    );
                    if (_preset != getPreset()) {
                      print('-- change camera ${env.camera_height.val}');
                      _preset = getPreset();
                      _initCameraSync(ref);
                    }
                  }
              ),
          ]),
        )
    );
  }

  Widget optionButton(BuildContext context) {
    int z = env.camera_zoom.val;
    String s = (z/10.0).toStringAsFixed(1);
    double y = 40.0 + 8.0 + 48.0;
    double b = 48.0;
    return Stack(children:<Widget>[
      MyIconButton(
          bottom:y + b, left:30.0,
          icon: Icon(Icons.add),
          iconSize: 30.0,
          onPressed:() async {
            zoomCamera(z+5);
          }
      ),
      Positioned(
          bottom:y, left:30.0,
          child:Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(child:
                Text(s,
                textAlign:TextAlign.center,
                style: TextStyle(fontSize:14, color: Colors.white)
            )),
          )
      ),
      MyIconButton(
          bottom:y - b, left:30.0,
          icon: Icon(Icons.remove),
          iconSize: 30.0,
          onPressed:() async {
            zoomCamera(z-5);
          }
      ),
    ]);
  }

  /// ズーム
  Future<void> zoomCamera(int zoom10) async {
    if(this._zoom10 == zoom10)
      return;

    if(kIsWeb){
      print('-- zoom=${zoom10}');
      if(zoom10 > 40) zoom10 = 40;
      if(zoom10 < 10) zoom10 = 10;
      ref.read(environmentProvider).saveDataNoRound(env.camera_zoom,(zoom10).toInt());
      this._zoom10 = zoom10;
      return;
    }
    if(disableCamera || _controller == null)
      return;
    int max_zoom = 40;
    int min_zoom = 10;
    if(zoom10 > max_zoom) zoom10 = max_zoom;
    if(zoom10 < min_zoom) zoom10 = min_zoom;
    try {
      _controller!.setZoomLevel(zoom10/10.0);
    } catch (e) {
      await MyLog.err('${e.toString()}');
    }
    this._zoom10 = zoom10;
    ref.read(environmentProvider).saveDataNoRound(env.camera_zoom,zoom10);
  }

  /// カメラウィジェット
  Widget _cameraWidget(BuildContext context) {
    if(disableCamera) {
      return Positioned(
        left:0, top:0, right:0, bottom:0,
        child: Container(color: Color(0xFF222244)));
    }
    if (_controller == null || _controller!.value.previewSize == null) {
      return Center(
        child: SizedBox(
          width:32, height:32,
          child: CircularProgressIndicator(),
        ),
      );
    }

    Size _screenSize = MediaQuery.of(context).size;
    Size _cameraSize = _controller!.value.previewSize!;
    double sw = _screenSize.width;
    double sh = _screenSize.height;
    double dw = sw>sh ? sw : sh;
    double dh = sw>sh ? sh : sw;
    double _aspect = sw>sh ? _controller!.value.aspectRatio : 1/_controller!.value.aspectRatio;

    // 16:10 (Up-down black) or 17:9 (Left-right black)
    // e.g. double _scale = dw/dh < 16.0/9.0 ? dh/dw * 16.0/9.0 : dw/dh * 9.0/16.0;
    double _scale = dw/dh < _cameraSize.width/_cameraSize.height ? dh/dw * _cameraSize.width/_cameraSize.height : dw/dh * _cameraSize.height/_cameraSize.width;

    print('-- screen=${sw.toInt()}x${sh.toInt()}'
      ' camera=${_cameraSize.width.toInt()}x${_cameraSize.height.toInt()}'
      ' aspect=${_aspect.toStringAsFixed(2)}'
      ' scale=${_scale.toStringAsFixed(2)}');

    if(IS_TEST){
      print('-- IS_TEST');
      return Center(
        child: Transform.scale(
          scale: _scale,
          child: AspectRatio(
              aspectRatio: _aspect,
              child: kIsWeb ?
              Image.network('/lib/assets/sample.png', fit:BoxFit.cover) :
              Image(image: AssetImage('lib/assets/sample.png')),
          ),
        ),
      );
    }

    return Center(
      child: Transform.scale(
        scale: _scale,
        child: AspectRatio(
          aspectRatio: _aspect,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  /// カメラ初期化
  Future<void> _initCameraSync(WidgetRef ref) async {
    if (disableCamera)
      return;
    print('-- _initCameraSync');
    _cameras = await availableCameras();
    int pos = env.camera_pos.val;
    if (_cameras.length <= 0) {
      MyLog.err("Camera not found");
      return;
    }
    if (_cameras.length == 1) {
      pos = 0;
    }
    _controller = CameraController(
        _cameras[pos],
        _preset,
        imageFormatGroup: _imageFormat,
        enableAudio: false
    );

    _controller!.initialize().then((_) {
      redraw();
    });
  }

  /// スイッチ
  Future<void> _onCameraSwitch(WidgetRef ref) async {
    if (disableCamera || _cameras.length < 2)
      return;

    int pos = env.camera_pos.val == 0 ? 1 : 0;
    env.camera_pos.set(pos);
    env.save(env.camera_pos);

    await _controller!.dispose();
    _controller = CameraController(
        _cameras[pos],
        _preset,
        imageFormatGroup: _imageFormat,
        enableAudio: false
    );
    try {
      _controller!.initialize().then((_) {
        redraw();
      });
    } catch (e) {
      await MyLog.err('${e.toString()}');
    }
    _zoom10 = 10;
  }

  /// START
  Future<bool> onStart() async {
    if(kIsWeb) {
      ref.read(stateProvider).start();
    }

    if (_controller!.value.isInitialized==false) {
      print('-- err _controller!.value.isInitialized==false');
      return false;
    }

    if (isUnitStorageFree()==false) {
      print('-- err isUnitStorageFree');
      return false;
    }

    _photoTime = null;
    _batteryLevelStart = await _battery.batteryLevel;
    _bLogExstrageFull = true;

    // 先にセーバー起動
    ref.read(stateProvider).start();

    await _storage.getInApp(false);
    if(env.isPremium()) {
      if(env.ex_storage.val==1)
        await _storage.getGdrive();
    }
    _takeCount = 0;
    if(env.take_mode.val==1 || env.take_mode.val==3)
      takePhoto();
    if(env.take_mode.val==2 || env.take_mode.val==3)
      startAudio();
    if(env.take_mode.val==4)
      startVideo();

    await MyLog.info("Start");
    return true;
  }

  /// STOP
  Future<void> onStop() async {
    print('-- onStop');
    try {
      String s = 'Stop';
      if (_state.startTime != null) {
        Duration dur = DateTime.now().difference(_state.startTime!);
        if (dur.inMinutes > 0)
          s += ' ${dur.inMinutes}min';
      }
      if (_batteryLevelStart - _batteryLevel > 0) {
        s += ' batt ${_batteryLevelStart}->${_batteryLevel}%';
      }
      MyLog.info(s);
      ref.read(stateProvider).stopped();

      if (env.take_mode.val == 1 || env.take_mode.val == 3)
        if (_controller!.value.isStreamingImages)
          await _controller!.stopImageStream();
      if (env.take_mode.val == 2 || env.take_mode.val == 3)
        await stopAudio();
      if (env.take_mode.val == 4)
        await stopVideo();

      await Future.delayed(Duration(milliseconds: 100));
      await _deleteCacheDir();
    } on Exception catch (e) {
      print('-- onStop() Exception ' + e.toString());
    }
  }

  // 写真
  Future<void> takePhoto() async {
    print("-- takePhoto");
    if (kIsWeb) return;
    _photoTime = null;
    DateTime dt = DateTime.now();
    try {
      if (Platform.isIOS) {
        imglib.Image? img = await CameraAdapter.takeImage(_controller);
        if (img != null) {
          String path = await getSavePath('.jpg');
          final File file = File(path);
          await file.writeAsBytes(imglib.encodeJpg(img));
          if (env.isPremium()) {
            if (env.ex_storage.val == 1) {
              if ((_storage.gdriveFiles.length + _takeCount) < env.ex_save_num.val) {
                _storage.saveGdrive(path);
              } else {
                if (_bLogExstrageFull) {
                  MyLog.warn('GoogleDrive is full');
                  _bLogExstrageFull = false;
                }
              }
            }
          }
          _photoTime = dt;
          _takeCount++;
        } else {
          print('-- photoShooting img=null');
        }
      } else {
        // android
        XFile xfile = await _controller!.takePicture();
        String path = await getSavePath('.jpg');
        await moveFile(src: xfile.path, dst: path);
        if (env.isPremium()) {
          if (env.ex_storage.val == 1) {
            if ((_storage.gdriveFiles.length + _takeCount) < env.ex_save_num.val) {
              _storage.saveGdrive(path);
            } else {
              if (_bLogExstrageFull) {
                MyLog.warn('GoogleDrive is full');
                _bLogExstrageFull = false;
              }
            }
          }
        }
        _photoTime = dt;
        _takeCount++;
      }
    } catch (e) {
      await MyLog.err('${e.toString()}');
    }
  }

  Future<void> startVideo() async {
    print("-- startVideo");
    if(kIsWeb) return;
    try {
      await _controller!.startVideoRecording();
      _videoTime = DateTime.now();
    } on CameraException catch (e) {
      MyLog.err('${e.code} ${e.description} startVideo()');
    } catch (e) {
      MyLog.err('${e.toString()} startVideo()');
    }
  }

  Future<void> stopVideo() async {
    print("-- stopVideo");
    if(kIsWeb) return;
    try {
      _videoTime = null;
      XFile xfile = await _controller!.stopVideoRecording();
      await moveFile(src:xfile.path, dst:await getSavePath('.mp4'));
    } catch (e) {
      await MyLog.err('${e.toString()} stopVideo()');
    }
  }

  Future<void> startAudio() async {
    print("-- startAudio");
    try{
      if (await _record.hasPermission()) {
        String path = await getSavePath('.m4a');
        await _record.start(
          path:path
        );
        _audioTime = DateTime.now();
      }
    } catch (e) {
      MyLog.err('${e.toString()} startAudio()');
    }
  }

  Future<void> stopAudio() async {
    try{
      _audioTime = null;
      final path = await _record.stop();
    } catch (e) {
      MyLog.err('${e.toString()} stopAudio()');
    }
  }

  Future<File> moveFile({required String src, required String dst}) async {
    File srcfile = File(src);
    try {
      for (var i = 1; i <= 5; i++) {
        if (await srcfile.exists()) {
          return await srcfile.rename(dst);
        } else {
          await Future.delayed(Duration(milliseconds: 400));
        }
      }
      MyLog.warn('move file not exists src=${src}');
      return srcfile;
    } on FileSystemException catch (e) {
      MyLog.err('move file e=${e.message} path=${e.path}');
      final newfile = await srcfile.copy(dst);
      await srcfile.delete();
      return newfile;
    }
  }

  /// タイマー
  void _onTimer(Timer timer) async {
    if (this._batteryLevel < 0)
      this._batteryLevel = await _battery.batteryLevel;

    // 停止ボタンを押したとき
    if (_state.isRunning == false && _state.startTime != null) {
      onStop();
      return;
    }

    // スクリーンセーバー中
    if (_state.isSaver == true) {
      if (env.saver_mode.val == 1) {
        ref.read(stopButtonTextProvider.state).state = takingString();
      } else if (env.saver_mode.val == 2 && _waitTime != null) {
        if (DateTime
            .now()
            .difference(_waitTime!)
            .inSeconds > 5) {
          _waitTime = null;
        }
        ref.read(stopButtonTextProvider.state).state = takingString();
      }
    }

    // 自動停止
    if (_state.isRunning == true && _state.startTime != null) {
      Duration dur = DateTime.now().difference(_state.startTime!);
      if (env.autostop_sec.val > 0 && dur.inSeconds > env.autostop_sec.val) {
        await MyLog.info("Autostop by settings");
        onStop();
        return;
      }
    }

    // バッテリーチェック（1分毎）
    if (_state.isRunning == true && DateTime
        .now()
        .second == 0) {
      this._batteryLevel = await _battery.batteryLevel;
      if (this._batteryLevel < 10) {
        await MyLog.warn("Low battery");
        onStop();
        return;
      }
    }

    // インターバル
    if (_state.isRunning == true) {
      if (_photoTime != null) {
        Duration dur = DateTime.now().difference(_photoTime!);
        if (dur.inSeconds > env.photo_interval_sec.val) {
          if (await isUnitStorageFree()) {
            takePhoto();
          } else {
            onStop();
          }
        }
      }
      if (_videoTime != null) {
        Duration dur = DateTime.now().difference(_videoTime!);
        if (dur.inSeconds > env.split_interval_sec.val) {
          if (await isUnitStorageFree()) {
            await stopVideo();
            await startVideo();
          } else {
            onStop();
          }
        }
      }
      if (_audioTime != null) {
        Duration dur = DateTime.now().difference(_audioTime!);
        if (dur.inSeconds > env.split_interval_sec.val) {
          if (await isUnitStorageFree()) {
            await stopAudio();
            await startAudio();
          } else {
            onStop();
          }
        }
      }
    }
  } // _onTimer

  Future<String> getSavePath(String ext) async {
    final Directory appdir = await getApplicationDocumentsDirectory();
    final String dirPath = '${appdir.path}/files';
    await Directory(dirPath).create(recursive: true);
    String dt = DateFormat("yyyy-MMdd-HHmmss").format(DateTime.now());
    return '${dirPath}/${dt}${ext}';
  }

  /// 本体ストレージの空き容量
  Future<bool> isUnitStorageFree() async {
    if(kIsWeb)
      return true;
    try {
      // アプリ内で上限を超えた古いものを削除
      if (env.save_num.val < await _storage.files.length) {
        await _storage.getInApp(false);
        for(int i=0; i<100; i++) {
          if ((env.save_num.val) < _storage.files.length)
            break;
          await File(_storage.files.last.path).delete();
          _storage.files.removeLast();
        }
      }

      // 本体の空きが5GB必要
      int enough = 5;
      if(kIsWeb)
        enough = 0;

      double? totalMb = await DiskSpace.getTotalDiskSpace;
      double? freeMb = await DiskSpace.getFreeDiskSpace;
      int totalGb = totalMb!=null ? (totalMb / 1024.0).toInt() : 0;
      int freeGb = freeMb!=null ? (freeMb / 1024.0).toInt() : 0;
      if(freeGb < enough) {
        await MyLog.warn("Not enough free space ${freeGb}/${totalGb} GB");
        return false;
      }

    } on Exception catch (e) {
      print('-- checkDiskFree() Exception ' + e.toString());
    }
    return true;
  }

  void logError(String code, String? message) {
    print('-- Error Code: $code\n-- Error Message: $message');
  }

  /// キャッシュ削除
  Future<void> _deleteCacheDir() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        List<FileSystemEntity> files = cacheDir.listSync(recursive: true, followLinks: false);
        if (files.length > 0) {
          for (FileSystemEntity e in files) {
            try {
              await File(e.path).delete();
              print('-- del ok ${basename(e.path)}');
            } on Exception catch (err) {
              print('-- del err ${basename(e.path)}');
            }
          }
        }
      }
    } on Exception catch (e) {
      print('-- Exception _deleteCacheDir() e=' + e.toString());
    }
  }

  @override
  bool get wantKeepAlive => true;

  Widget recordButton({required void Function()? onPressed}) {
    return Center(
        child: Container(
            width: 160, height: 160,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.black26,
                shape: const CircleBorder(
                  side: BorderSide(
                    color: Colors.white,
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
              child: Text('START', style: TextStyle(fontSize: 16, color: Colors.white)),
              onPressed: onPressed,
            )
        )
    );
  }

  Widget stopButton({required void Function()? onPressed}) {
    String text = ref.watch(stopButtonTextProvider);
    double d = ((DateTime
        .now()
        .second / 10) % 2).toInt() * 4.0;
    return Center(
        child: Container(
            width: 160 + d, height: 160 + d,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.black26,
                shape: const CircleBorder(
                  side: BorderSide(
                    color: COL_SS_TEXT,
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
              child: Text(text, style: TextStyle(fontSize: 16, color: COL_SS_TEXT), textAlign: TextAlign.center),
              onPressed: onPressed,
            )
        )
    );
  }

  String takingString() {
    String s = '1';
    if (_timer == null) {
      s = '2';
    } else if (_state.isRunning == false) {
      s = 'STOPPED\n--:--';
    } else if (_state.startTime != null && _state.isRunning) {
      Duration dur = DateTime.now().difference(_state.startTime!);
      s = 'STOP\n' + dur2str(dur);
    }
    return s;
  }

  /// 01:00:00
  String dur2str(Duration dur) {
    String s = "";
    if (dur.inHours > 0)
      s += dur.inHours.toString() + ':';
    s += dur.inMinutes.remainder(60).toString().padLeft(2, '0') + ':';
    s += dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    return s;
  }

  Widget blackScreen({required void Function()? onPressed}) {
    return Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        right: 0,
        child: TextButton(
          child: Text(''),
          style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.black)),
          onPressed: onPressed,
        )
    );
  }
}
