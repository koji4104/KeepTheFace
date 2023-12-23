import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path/path.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:permission_handler/permission_handler.dart';
import '/controllers/gdrive_adapter.dart';
import 'package:document_file_save_plus/document_file_save_plus.dart';
import '/constants.dart';
import 'dart:typed_data'; // Uint8List
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/material.dart';

class MyFile {
  String path = '';
  String name = '';
  DateTime date = DateTime(2000, 1, 1);
  int byte = -1;
  String thumb = '';
  bool isLibrary = false;
}

final myStorageProvider = ChangeNotifierProvider((ref) => MyStorageNotifier(ref));

class MyStorageNotifier extends ChangeNotifier {
  MyStorageNotifier(ref) {}

  GoogleDriveAdapter gdriveAd = GoogleDriveAdapter();
  List<MyFile> inappFiles = [];
  List<MyFile> gdriveFiles = [];
  int inappTotalMb = -1;
  int gdriveTotalMb = -1;

  /// In-app data
  Future getInApp(bool allinfo) async {
    if (kIsWeb) return;
    try {
      final dt1 = DateTime.now();
      inappFiles.clear();
      final Directory appdir = await getApplicationDocumentsDirectory();
      final files_dir = Directory('${appdir.path}/files');
      await Directory('${appdir.path}/files').create(recursive: true);
      List<FileSystemEntity> _files = files_dir.listSync(recursive: true, followLinks: false);

      // sort
      _files.sort((a, b) {
        return b.path.compareTo(a.path);
      });

      int totalBytes = 0;
      for (FileSystemEntity e in _files) {
        MyFile f = new MyFile();
        f.path = e.path;
        f.byte = e.statSync().size;
        totalBytes += f.byte;
        if (allinfo) {
          f.date = e.statSync().modified;
          f.name = basename(f.path);
        }
        inappFiles.add(f);
      }
      inappTotalMb = (totalBytes / 1024 / 1024).toInt();
      print('-- inapp files=${inappFiles.length}'
          ' msec=${DateTime.now().difference(dt1).inMilliseconds}');
    } on Exception catch (e) {
      print('-- err getInApp ex=' + e.toString());
      inappTotalMb = -1;
    }
  }

  Future saveLibrary(String path) async {
    try {
      if (Platform.isAndroid) {
        var permission = await Permission.storage.isGranted;
        if (permission == false) {
          var request = await Permission.storage.request();
          permission = request.isGranted;
        }
        if (permission) {
          if (path.contains('.mp4')) {
            await GallerySaver.saveVideo(path, albumName: ALBUM_NAME);
          } else if (path.contains('.jpg')) {
            await GallerySaver.saveImage(path, albumName: ALBUM_NAME);
          }
        }
      } else {
        var permission = await Permission.storage.isGranted;
        if (permission == false) {
          var request = await Permission.storage.request();
          permission = request.isGranted;
        }
        if (permission) {
          if (path.contains('.mp4')) {
            await GallerySaver.saveVideo(path, albumName: ALBUM_NAME);
          } else if (path.contains('.jpg')) {
            await GallerySaver.saveImage(path, albumName: ALBUM_NAME);
          }
        }
      }
    } on Exception catch (e) {
      print('-- err saveGallery=${e.toString()}');
    }
  }

  /// Download folder (Android), or show save dialog (iOS)
  Future<String> saveFolder(List<MyFile> list) async {
    String errmsg = '';
    try {
      List<Uint8List> dataList = [];
      List<String> fileNameList = [];
      List<String> mimeTypeList = [];
      for (MyFile f in list) {
        dataList.add(File(f.path).readAsBytesSync());
        String fname = basename(f.path);
        fileNameList.add(fname);
        if (fname.contains('.jpg')) {
          mimeTypeList.add('image/jpeg');
        } else if (fname.contains('.m4a')) {
          mimeTypeList.add('audio/mp4');
        }
      }
      DocumentFileSavePlus().saveMultipleFiles(
        dataList: dataList,
        fileNameList: fileNameList,
        mimeTypeList: mimeTypeList,
      );
      print('-- saveFolder()');
    } on Exception catch (e) {
      print('-- err saveFolder()=${e.toString()}');
      errmsg = e.toString();
    }
    return errmsg;
  }

  bool _needToInitGetGdrive = true;
  Future InitGetGdrive() async {
    if (_needToInitGetGdrive) getGdrive();
    _needToInitGetGdrive = false;
  }

  Future getGdrive() async {
    final dt1 = DateTime.now();

    gdriveFiles.clear();
    gdriveTotalMb = -1;
    if (gdriveAd.isSignedIn() == false) {
      print('-- gdriveAd.loginSilently()');
      await gdriveAd.loginSilently();
    }
    if (gdriveAd.isSignedIn() == false) {
      print('-- err gdriveAd.isSignedIn() == false -> return');
      return;
    }

    await gdriveAd.getKeepFiles();
    await gdriveAd.getTempFiles();
    /*
    if (gdriveAd.gaFiles.length > 0) {
      int totalBytes = 0;
      for (ga.File f in gdriveAd.gaFiles) {
        MyFile data = MyFile();
        data.path = f.id!;
        data.name = f.name!;
        data.byte = f.size != null ? int.parse(f.size!) : 0;
        totalBytes += data.byte;
        gdriveFiles.add(data);
      }
      gdriveTotalMb = (totalBytes / 1024 / 1024).toInt();
      if (gdriveTotalMb == 0 && totalBytes > 0) gdriveTotalMb = 1;
    }
*/
    print('-- getGdrive() gdriveFiles=${gdriveFiles.length}'
        ' msec=${DateTime.now().difference(dt1).inMilliseconds}');
  }

  Future<bool> uploadKeepFile(String path, String name) async {
    return await gdriveAd.uploadKeepFile(path, name);
  }

  Future<bool> uploadTempFile(String path, String name, int mb) async {
    await gdriveAd.deleteOldTempFile(mb);
    return await gdriveAd.uploadTempFile(path, name);
  }
}
