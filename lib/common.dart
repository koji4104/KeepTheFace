import 'package:flutter/material.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:photo_gallery/photo_gallery.dart';
import 'package:path/path.dart';
import 'package:photo_manager/photo_manager.dart';
import 'gdrive_adapter.dart';
import 'package:googleapis/drive/v3.dart' as ga;

import 'package:permission_handler/permission_handler.dart';

import 'package:file_saver/file_saver.dart';
import 'dart:convert' show utf8;

String ALBUM_NAME = "TheseDays";
String SAVE_DIR = "appdata";
final bool testMode = false;

class MyFile{
  String path = '';
  String name = '';
  DateTime date = DateTime(2000,1,1);
  int byte = 0;
  String thumb = '';
  bool isLibrary = false;
}

class MyStorage {
  List<MyFile> files = [];
  int totalBytes = 0;
  List<MyFile> libraryFiles = [];
  List<MyFile> gdriveFiles = [];

  // アプリ内データ
  Future getInApp(bool allinfo) async {
    if(kIsWeb) return;
    final dt1 = DateTime.now();
    files.clear();
    totalBytes = 0;
    final Directory appdir = await getApplicationDocumentsDirectory();
    final files_dir = Directory('${appdir.path}/files');
    await Directory('${appdir.path}/files').create(recursive:true);
    List<FileSystemEntity> _files = files_dir.listSync(recursive:true, followLinks:false);
    _files.sort((a,b) { return b.path.compareTo(a.path); });

    for (FileSystemEntity e in _files) {
      MyFile f = new MyFile();
      f.path = e.path;
      if(allinfo) {
        f.date = e.statSync().modified;
        f.name = basename(f.path);
        f.byte = e.statSync().size;
        totalBytes += f.byte;
      }
      files.add(f);
    }
    print('-- inapp files=${files.length}'
        ' msec=${DateTime.now().difference(dt1).inMilliseconds}');
  }

  // フォトライブラリ
  Future getLibrary() async {
    if(kIsWeb) return;
    print('-- WARN getLibrary()');
    /// Android (AndroidManifest.xml)
    /// READ_EXTERNAL_STORAGE (REQUIRED)
    /// WRITE_EXTERNAL_STORAGE
    /// ACCESS_MEDIA_LOCATION
    /// iOS (Info.plist)
    /// NSPhotoLibraryUsageDescription
    /// NSPhotoLibraryAddUsageDescription
    try {
      final dt1 = DateTime.now();
      libraryFiles.clear();
      if (Platform.isIOS) {
        final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList();
        print('-- ios albums.length=${albums.length}');
        for (AssetPathEntity a in albums) {
          if (a.name == ALBUM_NAME) {
            for (int page = 0; page < 10; page++) {
              // iOS
              List<AssetEntity> paths = await a.getAssetListPaged(page:page, size:100);
              // Android
              //List<AssetEntity> paths = await a.getAssetListPaged(0, 100);
              if (paths.length < 1)
                break;
              for (AssetEntity p in paths) {
                File? f = await p.loadFile(isOrigin: true);
                if (f != null) {
                  MyFile d = MyFile();
                  d.path = f.path;
                  d.name = basename(f.path);
                  libraryFiles.add(d);
                }
              }
            }
          }
        }
      } else {
        final dt1 = DateTime.now();
        List<Album> images = await PhotoGallery.listAlbums(mediumType:MediumType.image);
        for (Album album in images) {
          if (album.name == ALBUM_NAME) {
            MediaPage page = await album.listMedia();
            for (Medium media in page.items) {
              File f = await media.getFile();
              MyFile data = MyFile();
              data.path = f.path;
              data.name = basename(f.path);
              libraryFiles.add(data);
            }
          }
        }
      }
      print('-- Library files=${libraryFiles.length}'
          ' msec=${DateTime.now().difference(dt1).inMilliseconds}');
    } on Exception catch (e) {
      print('-- err MyStorage.getLibrary() ex=' + e.toString());
    }
  }

  saveLibrary(String path) async {
    try {
      if (Platform.isAndroid) {
        var permission = await Permission.storage.isGranted;
        if (permission == false) {
          var request = await Permission.storage.request();
          permission = request.isGranted;
        }
        if (permission) {
          await GallerySaver.saveImage(path, albumName: ALBUM_NAME);
        }
      } else {
        var permission = await Permission.storage.isGranted;
        if (permission == false) {
          var request = await Permission.storage.request();
          permission = request.isGranted;
        }
        if (permission) {
          var result = await GallerySaver.saveImage(path, albumName: ALBUM_NAME);
        }
      }
    } on Exception catch (e) {
      print('-- err saveGallery=${e.toString()}');
    }
  }

  saveFileSaver(String path) async {
    try {
      if (Platform.isAndroid) {
        ///storage/emulated/0/Android/data/com.github.koji4104.thesedays/files/2022-1005-125744.mp4
        final b = File(path).readAsBytesSync();
        String ext = "";
        MimeType type = MimeType.OTHER;
        if(path.contains('.jpg')){ ext="jpg"; type=MimeType.JPEG; }
        else if(path.contains('.mp4')){ ext="mp4"; type=MimeType.MPEG; }
        else if(path.contains('.m4a')){ ext="m4a"; type=MimeType.AAC; }
        String res = await FileSaver.instance.saveAs(basenameWithoutExtension(path), b, ext, type);
        print('-- saveFileSaver ${res}');

      } else {
        // info.list
        // Supports Documents Browser
        final b = File(path).readAsBytesSync();
        String ext = "";
        MimeType type = MimeType.OTHER;
        if(path.contains('.jpg')){ ext="jpg"; type=MimeType.JPEG; }
        else if(path.contains('.mp4')){ ext="mp4"; type=MimeType.MPEG; }
        else if(path.contains('.m4a')){ ext="m4a"; type=MimeType.AAC; }
        String res = await FileSaver.instance.saveAs(basenameWithoutExtension(path), b, ext, type);
        print('-- saveFileSaver ${res}');
      }
    } on Exception catch (e) {
      print('-- err saveGallery=${e.toString()}');
    }
  }

  GoogleDriveAdapter gdriveAd = GoogleDriveAdapter();
  Future getGdrive() async {
    gdriveFiles.clear();
    if(gdriveAd.isSignedIn()==false)
      await gdriveAd.loginSilently();
    if(gdriveAd.isSignedIn()==false)
      return;

    await gdriveAd.getFiles();
    if(gdriveAd.gfilelist!=null) {
      for (ga.File f in gdriveAd.gfilelist!.files!) {
        MyFile data = MyFile();
        data.path = f.id!;
        data.name = f.name!;
        gdriveFiles.add(data);
      }
    }
  }

  saveGdrive(String path) async {
    try {
      if(gdriveAd.isSignedIn()==true){
        gdriveAd.uploadFile(path);
      } else {
        print('-- warn google not signed in');
      }
    } on Exception catch (e) {
      print('-- err saveGdrive=${e.toString()}');
    }
  }
}

class MyUI {
  static final double mobileWidth = 700.0;
  static final double desktopWidth = 1100.0;

  static bool isMobile(BuildContext context) {
    return getWidth(context) < mobileWidth;
  }

  static bool isTablet(BuildContext context) {
    return getWidth(context) < desktopWidth &&
        getWidth(context) >= mobileWidth;
  }

  static bool isDesktop(BuildContext context) {
    return getWidth(context) >= desktopWidth;
  }

  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
}

class MyEdge {
  /// ホームバーの幅（アンドロイド）
  EdgeInsetsGeometry homebarEdge = EdgeInsets.all(0.0);

  /// 設定画面で左側の余白
  EdgeInsetsGeometry settingsEdge = EdgeInsets.all(0.0);

  MyEdge({ProviderBase? provider}) {
    if(provider!=null) this._provider = provider;
  }

  static double homebarWidth = 50.0; // ホームバーの幅
  static double margin = 10.0; // 基本マージン
  static double rightMargin = 200.0; // タブレット時の右マージン

  ProviderBase? _provider;
  double width = 100;

  /// Edgeを取得
  /// 各スクリーンのbuild()内で呼び出す
  void getEdge(BuildContext context, WidgetRef ref) async {
    if (width == MediaQuery.of(context).size.width)
      return;
    width = MediaQuery.of(context).size.width;
    print('-- getEdge() width=${width.toInt()}');

    if (!kIsWeb && Platform.isAndroid) {
      print('-- isAndroid');
      NativeDeviceOrientation ori = await NativeDeviceOrientationCommunicator().orientation();
      switch (ori) {
        case NativeDeviceOrientation.landscapeRight:
          homebarEdge = EdgeInsets.only(left: homebarWidth);
          print('-- droid landscapeRight');
          break;
        case NativeDeviceOrientation.landscapeLeft:
          homebarEdge = EdgeInsets.only(right: homebarWidth);
          break;
        case NativeDeviceOrientation.portraitDown:
        case NativeDeviceOrientation.portraitUp:
          homebarEdge = EdgeInsets.only(bottom: homebarWidth);
          break;
        default:
          break;
      }
    }

    EdgeInsetsGeometry leftrightEdge = EdgeInsets.all(0.0);
    if (width > 700) {
      leftrightEdge = EdgeInsets.only(left:width*10.0/100.0,right:width*10.0/100.0);
    }
    this.settingsEdge = EdgeInsets.all(margin);
    this.settingsEdge = this.settingsEdge.add(leftrightEdge);
    this.settingsEdge = this.settingsEdge.add(homebarEdge);
    if(_provider!=null)
      ref.read(_provider!).notifyListeners();
  }
}
