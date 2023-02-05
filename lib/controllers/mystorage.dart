import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:photo_gallery/photo_gallery.dart';
import 'package:path/path.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:permission_handler/permission_handler.dart';
import 'package:file_saver/file_saver.dart';
import '/controllers/gdrive_adapter.dart';
import '/constants.dart';

class MyFile {
  String path = '';
  String name = '';
  DateTime date = DateTime(2000, 1, 1);
  int byte = 0;
  String thumb = '';
  bool isLibrary = false;
}

class MyStorage {
  List<MyFile> files = [];
  int totalBytes = 0;
  List<MyFile> libraryFiles = [];
  List<MyFile> gdriveFiles = [];

  /// In-app data
  Future getInApp(bool allinfo) async {
    if (kIsWeb) return;
    final dt1 = DateTime.now();
    files.clear();
    totalBytes = 0;
    final Directory appdir = await getApplicationDocumentsDirectory();
    final files_dir = Directory('${appdir.path}/files');
    await Directory('${appdir.path}/files').create(recursive: true);
    List<FileSystemEntity> _files = files_dir.listSync(recursive: true, followLinks: false);
    _files.sort((a, b) {
      return b.path.compareTo(a.path);
    });

    for (FileSystemEntity e in _files) {
      MyFile f = new MyFile();
      f.path = e.path;
      if (allinfo) {
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

  /// photo library
  Future getLibrary() async {
    if (kIsWeb) return;
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
              List<AssetEntity> paths = await a.getAssetListPaged(page: page, size: 100);
              // Android
              //List<AssetEntity> paths = await a.getAssetListPaged(0, 100);
              if (paths.length < 1) break;
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
        List<Album> images = await PhotoGallery.listAlbums(mediumType: MediumType.image);
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
        if (path.contains('.jpg')) {
          ext = "jpg";
          type = MimeType.JPEG;
        } else if (path.contains('.mp4')) {
          ext = "mp4";
          type = MimeType.MPEG;
        } else if (path.contains('.m4a')) {
          ext = "m4a";
          type = MimeType.AAC;
        }
        String res = await FileSaver.instance.saveAs(basenameWithoutExtension(path), b, ext, type);
        print('-- saveFileSaver ${res}');
      } else {
        // info.list
        // Supports Documents Browser
        final b = File(path).readAsBytesSync();
        String ext = "";
        MimeType type = MimeType.OTHER;
        if (path.contains('.jpg')) {
          ext = "jpg";
          type = MimeType.JPEG;
        } else if (path.contains('.mp4')) {
          ext = "mp4";
          type = MimeType.MPEG;
        } else if (path.contains('.m4a')) {
          ext = "m4a";
          type = MimeType.AAC;
        }
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
    if (gdriveAd.isSignedIn() == false) await gdriveAd.loginSilently();
    if (gdriveAd.isSignedIn() == false) return;

    await gdriveAd.getFiles();
    if (gdriveAd.gfilelist != null) {
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
      if (gdriveAd.isSignedIn() == true) {
        gdriveAd.uploadFile(path);
      } else {
        print('-- warn google not signed in');
      }
    } on Exception catch (e) {
      print('-- err saveGdrive=${e.toString()}');
    }
  }
}
