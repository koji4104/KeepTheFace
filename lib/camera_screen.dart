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

import 'package:disk_space/disk_space.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'log_screen.dart';
import 'common.dart';
import 'camera_adapter.dart';
import 'environment.dart';

bool disableCamera = kIsWeb; // true=test
final bool _testMode = true;

const Color COL_SS_TEXT = Color(0xFFbbbbbb);
final cameraScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());

class CameraScreen extends ConsumerWidget {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Record _record = Record();

  StatusData _status = StatusData();

  int _takeCount = 0;
  DateTime? _photoTime;
  DateTime? _videoTime;
  DateTime? _audioTime;

  bool _bLogExstrageFull = true;

  Timer? _timer;
  Environment _env = Environment();
  ResolutionPreset _preset = ResolutionPreset.high; // 1280x720
  ImageFormatGroup _imageFormat = ImageFormatGroup.bgra8888;

  final Battery _battery = Battery();
  int _batteryLevel = -1;
  int _batteryLevelStart = -1;

  bool _bInit = false;
  late WidgetRef _ref;
  late BuildContext _context;
  AppLifecycleState? _state;

  MyEdge _edge = MyEdge(provider:cameraScreenProvider);
  MyStorage _storage = new MyStorage();

  void init(BuildContext context, WidgetRef ref) {
    if(_bInit == false){
      print('-- init()');
      _bInit = true;
      _timer = Timer.periodic(Duration(seconds:1), _onTimer);
      _initCameraSync(ref);
    }
  }

  @override
  void dispose() {
    if(_controller!=null) _controller!.dispose();
    if(_timer!=null) _timer!.cancel();
  }

  // low 320x240 (4:3)
  // medium 640x480 (4:3)
  // high 1280x720
  // veryHigh 1920x1080
  // ultraHigh 3840x2160
  ResolutionPreset getPreset() {
    ResolutionPreset p = ResolutionPreset.high;
    int h = _env.camera_height.val;
    if(h>=2160) p = ResolutionPreset.ultraHigh;
    else if(h>=1080) p = ResolutionPreset.veryHigh;
    else if(h>=720) p = ResolutionPreset.high;
    else if(h>=480) p = ResolutionPreset.medium;
    else if(h>=240) p = ResolutionPreset.low;
    return p;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //setState(() { _state = state; });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    this._ref = ref;
    this._context = context;
    this._env = ref.watch(environmentProvider).env;
    Future.delayed(Duration.zero, () => init(context,ref));
    ref.watch(cameraScreenProvider);
    this._status = _ref.watch(statusProvider).statsu;

    if(_status.isSaver) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays:[]);
      Wakelock.enable();
    } else {
      //SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays:[]);
      //Wakelock.disable();
    }
    _edge.getEdge(context,ref);

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      body: Container(
        margin: _edge.homebarEdge,
        child: Stack(children: <Widget>[

        // screen saver
        if (_status.isSaver)
          SaverScreen(),

        if(_status.isSaver==false && _env.take_mode.val!=2)
          _cameraWidget(context),

        // START
        if (_status.isSaver==false)
          RecordButton(
            onPressed:(){
              onStart();
            },
          ),

        // Camera Switch button
        if(_status.isSaver==false)
          MyButton(
            bottom: 30.0, right: 30.0,
            icon: Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed:() => _onCameraSwitch(ref),
          ),

        // PhotoList screen button
        if(_status.isSaver==false)
          MyButton(
            top:50.0, right:30.0,
            icon: Icon(Icons.folder, color: Colors.white),
            onPressed:() async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PhotoListScreen(),
                )
              );
            }
          ),

        // Settings screen button
        if(_status.isSaver==false)
          MyButton(
            top: 50.0, left: 30.0,
            icon: Icon(Icons.settings, color:Colors.white),
            onPressed:() async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(),
                )
              );
              if(_preset != getPreset()){
                print('-- change camera ${_env.camera_height.val}');
                _preset = getPreset();
                _initCameraSync(ref);
              }
            }
          ),
        ]
      ),
    ));
  }

  /// カメラウィジェット
  Widget _cameraWidget(BuildContext context) {
    if(disableCamera) {
      return Positioned(
        left:0, top:0, right:0, bottom:0,
        child: Container(color: Color(0xFF222222)));
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
    //double _scale = dw/dh < 16.0/9.0 ? dh/dw * 16.0/9.0 : dw/dh * 9.0/16.0;
    double _scale = dw/dh < _cameraSize.width/_cameraSize.height ? dh/dw * _cameraSize.width/_cameraSize.height : dw/dh * _cameraSize.height/_cameraSize.width;

    print('-- screen=${sw.toInt()}x${sh.toInt()}'
      ' camera=${_cameraSize.width.toInt()}x${_cameraSize.height.toInt()}'
      ' aspect=${_aspect.toStringAsFixed(2)}'
      ' scale=${_scale.toStringAsFixed(2)}');

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
    if(disableCamera)
      return;
    print('-- _initCameraSync');
    _cameras = await availableCameras();
    int pos = _env.camera_pos.val;
    if(_cameras.length<=0) {
      MyLog.err("Camera not found");
      return;
    }
    if(_cameras.length == 1) {
      pos = 0;
    }
    _controller = CameraController(
      _cameras[pos],
      _preset,
      imageFormatGroup:_imageFormat,
      enableAudio:false
    );

    _controller!.initialize().then((_) {
      _ref.read(cameraScreenProvider).notifyListeners();
    });
  }

  /// スイッチ
  Future<void> _onCameraSwitch(WidgetRef ref) async {
    if(disableCamera || _cameras.length<2)
      return;

    int pos = _env.camera_pos.val==0 ? 1 : 0;
    _env.camera_pos.set(pos);
    _env.save(_env.camera_pos);

    await _controller!.dispose();
    _controller = CameraController(
      _cameras[pos],
      _preset,
      imageFormatGroup:_imageFormat,
      enableAudio:false
    );
    try {
      _controller!.initialize().then((_) {
        _ref.read(cameraScreenProvider).notifyListeners();
      });
    } catch (e) {
      await MyLog.err('${e.toString()}');
    }
  }

  /// 開始
  Future<bool> onStart() async {
    if(kIsWeb) {
      _ref.read(statusProvider).start();
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
    _ref.read(statusProvider).start();

    await _storage.getInApp(false);
    if(_env.isPremium()) {
      if(_env.ex_storage.val==1)
        await _storage.getLibrary();
      else if(_env.ex_storage.val==2)
        await _storage.getGdrive();
    }
    _takeCount = 0;
    if(_env.take_mode.val==1 || _env.take_mode.val==3)
      takePhoto();
    if(_env.take_mode.val==2 || _env.take_mode.val==3)
      startAudio();
    if(_env.take_mode.val==4)
      startVideo();

    await MyLog.info("Start");
    return true;
  }

  /// 停止
  Future<void> onStop() async {
    print('-- onStop');
    try {
      String s = 'Stop';
      if(_status.startTime!=null) {
        Duration dur = DateTime.now().difference(_status.startTime!);
        if(dur.inMinutes>0)
          s += ' ${dur.inMinutes}min';
      }
      if(_batteryLevelStart-_batteryLevel>0) {
        s += ' batt${_batteryLevelStart}->${_batteryLevel}%';
      }
      MyLog.info(s);
      _ref.read(statusProvider).stop();

      if(_env.take_mode.val==1 || _env.take_mode.val==3)
        if(_controller!.value.isStreamingImages)
          await _controller!.stopImageStream();
      if(_env.take_mode.val==2 || _env.take_mode.val==3)
        await stopAudio();
      if(_env.take_mode.val==4)
        await stopVideo();

      await Future.delayed(Duration(milliseconds:100));
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

          if(_env.isPremium()) {
            if (_env.ex_storage.val == 1) {
              if((_storage.libraryFiles.length+_takeCount) < _env.ex_save_num.val) {
                _storage.saveLibrary(path);
              } else {
                if(_bLogExstrageFull) {
                  MyLog.warn('Photolibrary is full');
                  _bLogExstrageFull = false;
                }
              }

            } else if (_env.ex_storage.val == 2) {
              if((_storage.gdriveFiles.length+_takeCount) < _env.ex_save_num.val) {
                _storage.saveGdrive(path);
              } else {
                if(_bLogExstrageFull) {
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
        XFile xfile = await _controller!.takePicture();
        String path = await getSavePath('.jpg');
        await moveFile(src:xfile.path, dst:path);
        if(_env.isPremium()) {
          if (_env.ex_storage.val == 1) {
             if((_storage.libraryFiles.length+_takeCount) < _env.ex_save_num.val) {
               _storage.saveLibrary(path);
             } else {
               if(_bLogExstrageFull) {
                 MyLog.warn('Photolibrary is full');
                 _bLogExstrageFull = false;
               }
             }

          } else if (_env.ex_storage.val == 2) {
            if((_storage.gdriveFiles.length+_takeCount) < _env.ex_save_num.val) {
              _storage.saveGdrive(path);
            } else {
              if(_bLogExstrageFull) {
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
      MyLog.err('${e.code} ${e.description}');
    } catch (e) {
      MyLog.err('${e.toString()}');
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
      await MyLog.err('${e.toString()}');
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
      MyLog.err('${e.toString()}');
    }
  }

  Future<void> stopAudio() async {
    try{
      _audioTime = null;
      final path = await _record.stop();
    } catch (e) {
      MyLog.err('stop audio e=${e.toString()}');
    }
  }

  //src=/var/mobile/Containers/Data/Application/F168A64A-F632-469D-8CD6-390371BE4FAF/Documents/camera/videos/REC_E8ED36E1-3966-43A1-AB34-AA8AD34CEA08.mp4
  //dst=/var/mobile/Containers/Data/Application/F168A64A-F632-469D-8CD6-390371BE4FAF/Documents/photo/2022-0430-210906.mp4
  Future<File> moveFile({required String src, required String dst}) async {
    File srcfile = File(src);
    try {
      for(var i=1; i<=5; i++) {
        if (await srcfile.exists()) {
          return await srcfile.rename(dst);
        } else {
          await Future.delayed(Duration(milliseconds:400));
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
    if(this._batteryLevel<0)
      this._batteryLevel = await _battery.batteryLevel;

    // セーバーで停止ボタンを押したとき
    if(_status.isRunning==false && _status.startTime!=null) {
      onStop();
      return;
    }

    // 自動停止
    if(_status.isRunning==true && _status.startTime!=null) {
      Duration dur = DateTime.now().difference(_status.startTime!);
      if (_env.autostop_sec.val > 0 && dur.inSeconds>_env.autostop_sec.val) {
        await MyLog.info("Autostop");
        onStop();
        return;
      }
    }

    // バッテリーチェック（1分毎）
    if(_status.isRunning==true && DateTime.now().second == 0) {
      this._batteryLevel = await _battery.batteryLevel;
      if (this._batteryLevel < 10) {
        await MyLog.warn("Low battery");
        onStop();
        return;
      }
    }

    // インターバル
    if(_status.isRunning == true) {
      if(_photoTime!=null) {
        Duration dur = DateTime.now().difference(_photoTime!);
        if (dur.inSeconds > _env.photo_interval_sec.val) {
          if (await isUnitStorageFree()) {
            takePhoto();
          } else {
            onStop();
          }
        }
      }
      if(_videoTime!=null) {
        Duration dur = DateTime.now().difference(_videoTime!);
        if (dur.inSeconds > _env.video_interval_sec.val) {
          if (await isUnitStorageFree()) {
            await stopVideo();
            await startVideo();
          } else {
            onStop();
          }
        }
      }
      if(_audioTime!=null) {
        Duration dur = DateTime.now().difference(_audioTime!);
        if (dur.inSeconds > _env.audio_interval_sec.val) {
          if (await isUnitStorageFree()) {
            await stopAudio();
            await startAudio();
          } else {
            onStop();
          }
        }
      }
    }

    if(_status.isRunning==true && _state!=null) {
      if (_state == AppLifecycleState.inactive ||
          _state == AppLifecycleState.detached) {
        await MyLog.warn("App is stop or background");
        onStop();
        return;
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
      if (_env.save_num.val < await _storage.files.length) {
        await _storage.getInApp(false);
        for(int i=0; i<100; i++) {
          if ((_env.save_num.val) < _storage.files.length)
            break;
          await File(_storage.files.last.path).delete();
          _storage.files.removeLast();
        }
      }

      // 本体の空きが5GB必要
      int enough = 5;
      if(_testMode)
        enough = 0;

      double? totalMb = await DiskSpace.getTotalDiskSpace;
      double? freeMb = await DiskSpace.getFreeDiskSpace;
      int totalGb = totalMb!=null ? (totalMb / 1024.0).toInt() : 0;
      int freeGb = freeMb!=null ? (freeMb / 1024.0).toInt() : 0;
      if(freeGb < enough) {
        await MyLog.warn("Not enough free space ${freeGb}/${totalGb} GB");
        return false;
      }

      if(_env.ex_storage.val>0){
        _storage.getLibrary();
      }
    } on Exception catch (e) {
      print('-- checkDiskFree() Exception ' + e.toString());
    }
    return true;
  }

  void showSnackBar(String msg) {
    final snackBar = SnackBar(content: Text(msg));
    ScaffoldMessenger.of(_context).showSnackBar(snackBar);
  }

  void logError(String code, String? message) {
    print('-- Error Code: $code\n-- Error Message: $message');
  }

  /// キャッシュ削除
  /// data/user/0/com.github.koji4104/cache/CAP628722182744800763.mp4
  Future<void> _deleteCacheDir() async {
    try{
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        List<FileSystemEntity> files = cacheDir.listSync(recursive:true,followLinks:false);
        if(files.length>0) {
          for (FileSystemEntity e in files) {
            try{
              await File(e.path).delete();
              print('-- del ok ${e.path}');
            } on Exception catch (err) {
              print('-- del err ${e.path}');
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

  Widget MyButton({required Icon icon, required void Function()? onPressed,
    double? left, double? top, double? right, double? bottom}) {
    return Positioned(
      left:left, top:top, right:right, bottom:bottom,
      child: CircleAvatar(
        backgroundColor: Colors.black54,
        radius: 28.0,
        child: IconButton(
          icon: icon,
          iconSize: 38.0,
          onPressed: onPressed,
        )
      )
    );
  }

  Widget RecordButton({required void Function()? onPressed}) {
    return Center(
      child: Container(
        width:160, height:160,
        child:TextButton(
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
          child:Text('START', style:TextStyle(fontSize:16, color:Colors.white)),
          onPressed: onPressed,
        )
      )
    );
  }
}

final saverProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class SaverScreen extends ConsumerWidget {
  Timer? _timer;
  DateTime? _waitTime;
  late WidgetRef _ref;
  Environment _env = Environment();
  bool bInit = false;
  StatusData _status = StatusData();

  void init(WidgetRef ref) {
    if(bInit==false){
      bInit = true;
      _waitTime = DateTime.now();
      _env.load();
      _timer = Timer.periodic(Duration(seconds:1), _onTimer);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    this._ref = ref;
    Future.delayed(Duration.zero, () => init(ref));
    ref.watch(saverProvider);
    this._status = ref.read(statusProvider).statsu;

    return Scaffold(
      extendBody: true,
      body: Stack(children: <Widget>[
        // Tap
        Positioned(
          top:0, bottom:0, left:0, right:0,
          child: TextButton(
            child: Text(''),
            style: ButtonStyle(backgroundColor:MaterialStateProperty.all<Color>(Colors.black)),
            onPressed:(){
              _waitTime = DateTime.now();
            },
          )
        ),

        // STOP
        if(_waitTime!=null)
          Center(
            child: Container(
              width: 160, height: 160,
              child: StopButton(
                text:takingString(),
                onPressed:(){
                  _waitTime = null;
                  ref.read(statusProvider).stopflag();
                }
              )
            )
          ),
        ]
      )
    );
  }

  void _onTimer(Timer timer) async {
    try {
      if(_waitTime!=null) {
        if(DateTime.now().difference(_waitTime!).inSeconds > 5)
          _waitTime = null;
        _ref.read(saverProvider).notifyListeners();
      }
    } on Exception catch (e) {
      print('-- ScreenSaver _onTimer() Exception '+e.toString());
    }
  }

  Widget StopButton({required String text, required void Function()? onPressed}) {
    return TextButton(
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
      child: Text(text, style:TextStyle(fontSize:16, color:COL_SS_TEXT)),
      onPressed: onPressed,
    );
  }

  String takingString() {
    String s = '';
    if(_timer==null) {
      s = '';
    } else if(_status.isRunning==false) {
      s = 'STOP\n--:--';
    } else if(_status.startTime!=null && _status.isRunning){
      Duration dur = DateTime.now().difference(_status.startTime!);
      s = 'STOP\n' + dur2str(dur);
    }
    return s;
  }

  String elapsedTimeString(){
    String s = '';
    if(_status.startTime!=null && _status.isRunning) {
      Duration dur = DateTime.now().difference(_status.startTime!);
      s = dur2str(dur);
    }
    return s;
  }
  
  /// 01:00:00
  String dur2str(Duration dur) {
    String s = "";
    if(dur.inHours>0)
      s += dur.inHours.toString() + ':';
    s += dur.inMinutes.remainder(60).toString().padLeft(2,'0') + ':';
    s += dur.inSeconds.remainder(60).toString().padLeft(2,'0');
    return s;
  }
}