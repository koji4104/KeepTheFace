import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:path/path.dart';
import '/constants.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GoogleHttpClient extends IOClient {
  Map<String, String> _headers;
  GoogleHttpClient(this._headers) : super();
  @override
  Future<IOStreamedResponse> send(http.BaseRequest request) => super.send(request..headers.addAll(_headers));
  @override
  Future<http.Response> head(Object url, {Map<String, String>? headers}) =>
      super.head(url as Uri, headers: headers!..addAll(_headers));
}

class GoogleDriveAdapter {
  GoogleDriveAdapter() {}

  GoogleSignIn googleSignIn = GoogleSignIn(scopes: [ga.DriveApi.driveScope]);

  final storage = new FlutterSecureStorage();
  GoogleSignInAccount? gsa;
  bool isSignedIn() {
    return gsa != null;
  }

  bool isInitialized = false;
  String loginerr = '';

  /// displayName
  String getAccountName() {
    String r = 'None';
    if (gsa != null) {
      if (gsa!.displayName != null) {
        r = '${gsa!.displayName!}\n${gsa!.email}';
      } else {
        r = '${gsa!.email}';
      }
    }
    return r;
  }

  //ga.FileList? gfilelist = null;
  List<ga.File> gaKeepFiles = [];
  List<ga.File> gaTempFiles = [];

  String? mainFolderId;
  String mainFolderName = ALBUM_NAME;

  String? keepFolderId;
  String keepFolderName = KEEP_NAME;

  String? tempFolderId;
  String tempFolderName = TEMP_NAME;

  /// Already logged in
  Future<bool> loginSilently() async {
    print('-- loginSilently() start');
    gsa = null;
    loginerr = '';
    try {
      if (await storage.read(key: 'signedIn') == 'true') {
        gsa = await googleSignIn.signInSilently();
        if (gsa == null) {
          storage.write(key: 'signedIn', value: 'false');
        }
      }
    } on Exception catch (e) {
      print('-- err loginSilently() ${e.toString()}');
      loginerr = e.toString();
    }
    isInitialized = true;
    print('-- loginSilently() is ${gsa != null}');
    return gsa != null;
  }

  // New account or Existing account
  // com.google.android.gms.common.api.ApiException: 10 -> finger print
  Future<bool> loginWithGoogle() async {
    print('-- loginWithGoogle()');
    loginerr = '';
    try {
      gsa = await googleSignIn.signIn();
      if (gsa != null) {
        storage.write(key: 'signedIn', value: 'true');
      }
    } on Exception catch (e) {
      print('-- err loginWithGoogle() ${e.toString()}');
      loginerr = e.toString();
    }
    print('-- loginWithGoogle() is ${gsa != null}');
    return gsa != null;
  }

  Future logout() async {
    print('-- logout');
    await googleSignIn.signOut();
    await storage.write(key: 'signedIn', value: 'false');
    gsa = null;
  }

  /*
  Future<void> getMainFolderId(bool needToCreate) async {
    var client = GoogleHttpClient(await gsa!.authHeaders);
    var drive = ga.DriveApi(client);
    try {
      // folder id
      if (mainFolderId == null) {
        String q = "mimeType='application/vnd.google-apps.folder'";
        q += " and name='${mainFolderName}'";
        q += " and trashed=False";
        q += " and 'root' in parents";
        ga.FileList folders = await drive.files.list(
          q: q,
        );
        for (var i = 0; i < folders.files!.length; i++) {
          if (folders.files![i].name == mainFolderName && folders.files![i].id != null) {
            mainFolderId = folders.files![i].id!;
            print('-- folderId=${folders.files![i].id} name=${folders.files![i].name}');
          }
        }
        // create folder
        if (needToCreate == true && mainFolderId == null) {
          mainFolderId = await createFolder(mainFolderName);
        }
        print('folders.length=${folders.files!.length} mainFolderId=${mainFolderId}');
      }
    } on Exception catch (e) {
      print('-- err getFolderId() e=${e.toString()}');
    }
  }
*/
  Future<String?> getKeepFolderId(bool bCreate) async {
    if (mainFolderId == null) {
      mainFolderId = await getFolderId(mainFolderName, 'root', bCreate);
    }
    if (mainFolderId != null && keepFolderId == null) {
      keepFolderId = await getFolderId(keepFolderName, mainFolderId!, bCreate);
    }
    return keepFolderId;
  }

  Future<String?> getTempFolderId(bool bCreate) async {
    if (mainFolderId == null) {
      mainFolderId = await getFolderId(mainFolderName, 'root', bCreate);
    }
    if (mainFolderId != null && tempFolderId == null) {
      tempFolderId = await getFolderId(tempFolderName, mainFolderId!, bCreate);
    }
    return tempFolderId;
  }

  Future<String?> getFolderId(String folderName, String parents, bool bCreate) async {
    String? id;
    var client = GoogleHttpClient(await gsa!.authHeaders);
    var drive = ga.DriveApi(client);
    try {
      // folder id
      String q = "mimeType='application/vnd.google-apps.folder'";
      //q += " and name='${folderName}'";
      q += " and trashed=False";
      q += " and '${parents}' in parents";
      ga.FileList folders = await drive.files.list(
        q: q,
      );
      print('-- ${folderName} folders.length=${folders.files!.length}');
      for (var i = 0; i < folders.files!.length; i++) {
        if (folders.files![i].name == folderName && folders.files![i].id != null) {
          id = folders.files![i].id;
          print('-- name=${folders.files![i].name} folderId=${folders.files![i].id}');
        }
      }
      // create folder
      if (bCreate == true && id == null) {
        id = await createFolder(folderName, parents);
      }
      print('-- id=${id}');
    } on Exception catch (e) {
      print('-- err getFolderId() folderName=${folderName} e=${e.toString()}');
    }
    return id;
  }

  Future<String?> createFolder(String folderName, String parents) async {
    var client = GoogleHttpClient(await gsa!.authHeaders);
    var drive = ga.DriveApi(client);
    final googleApisFolder = ga.File();
    googleApisFolder.parents = [parents];
    googleApisFolder.name = folderName;
    googleApisFolder.mimeType = 'application/vnd.google-apps.folder';
    final response = await drive.files.create(googleApisFolder);
    return response.id;
  }

  Future<void> getKeepFiles() async {
    print('-- gdrive getKeepFiles()');
    gaKeepFiles.clear();
    if (isSignedIn() == false) return;
    if (await getKeepFolderId(false) != null) {
      gaKeepFiles = await getFiles(keepFolderId!);
    }
  }

  Future<void> getTempFiles() async {
    print('-- gdrive getTempFiles()');
    gaTempFiles.clear();
    if (isSignedIn() == false) return;
    if (await getTempFolderId(false) != null) {
      gaTempFiles = await getFiles(tempFolderId!);
    }
  }

  Future<List<ga.File>> getFiles(String folderId) async {
    List<ga.File> galist = [];
    if (isSignedIn() == false) return galist;
    var client = GoogleHttpClient(await gsa!.authHeaders);
    var drive = ga.DriveApi(client);
    try {
      // File list
      String? pageToken = "";
      String q = "mimeType!='application/vnd.google-apps.folder'";
      q += " and '${folderId}' in parents";
      q += " and trashed=False";
      for (int i = 0; i < 20; i++) {
        ga.FileList list = await drive.files.list(
          q: q,
          $fields: '*',
          pageSize: 100,
          pageToken: pageToken,
        );
        if (list.files != null) {
          galist.addAll(list.files!.cast());
        }
        int count = list.files != null ? list.files!.length : -1;
        print('-- drive.files.list() x${i} n=${count} token=${pageToken}');
        pageToken = list.nextPageToken;
        if (pageToken == null) break;
      }
      // sort
      galist.sort((a, b) {
        return (a.name ?? "").compareTo(b.name ?? "");
      });
      print('-- galist.length=${galist.length}');
    } on Exception catch (e) {
      print('-- err getFiles()=${e.toString()}');
    }
    return galist;
  }

  int getKeepFileCount() {
    return gaKeepFiles.length;
  }

  int getKeepFileMb() {
    int bytes = 0;
    for (ga.File f in gaKeepFiles) {
      bytes += f.size != null ? int.parse(f.size!) : 0;
    }
    int mb = (bytes / 1024 / 1024).toInt();
    return mb;
  }

  int getTempFileCount() {
    return gaTempFiles.length;
  }

  int getTempFileMb() {
    int bytes = 0;
    for (ga.File f in gaTempFiles) {
      bytes += f.size != null ? int.parse(f.size!) : 0;
    }
    int mb = (bytes / 1024 / 1024).toInt();
    return mb;
  }

  Future<bool> uploadKeepFile(String path, String name) async {
    print('-- uploadFileToKeep() start');
    if (isSignedIn() == false) {
      return false;
    }

    await getKeepFolderId(true);
    if (keepFolderId == null) {
      print('-- not keepFolderId');
      return false;
    }

    return _uploadFile(path, name, keepFolderId!);
  }

  Future<bool> uploadTempFile(String path, String name) async {
    print('-- uploadFileToTemp() start');
    if (isSignedIn() == false) {
      return false;
    }

    await getTempFolderId(true);
    if (tempFolderId == null) {
      print('-- not tempFolderId');
      return false;
    }

    return _uploadFile(path, name, tempFolderId!);
  }

  Future<bool> _uploadFile(String path, String name, String folderId) async {
    if (isSignedIn() == false) return false;
    try {
      var client = GoogleHttpClient(await gsa!.authHeaders);
      var drive = ga.DriveApi(client);

      var request = new ga.File();
      File file = File(path);
      request.name = name;
      request.parents = [folderId];

      var res = await drive.files.create(request, uploadMedia: ga.Media(file.openRead(), file.lengthSync()));
      print('-- _uploadFile() id=${res.id}');
      return true;
    } catch (e) {
      print('-- err _uploadFile() ${e}');
      return false;
    }
  }

  Future<bool> deleteTempFileByName(String name) async {
    print('-- deleteFileByName()');
    if (isSignedIn() == false) {
      print('-- not SignedIn');
      return false;
    }
    var client = GoogleHttpClient(await gsa!.authHeaders);
    var drive = ga.DriveApi(client);
    try {
      if (this.tempFolderId == null) {
        await getTempFolderId(false);
        if (tempFolderId == null) {
          print('-- not folderId');
          return false;
        }
      }

      String q = "mimeType!='application/vnd.google-apps.folder'";
      q += " and '${tempFolderId}' in parents";
      q += " and trashed=False";
      q += " and name = ${name}";

      ga.FileList list = await drive.files.list(
        q: q,
        $fields: '*',
        pageSize: 10,
      );
      if (list.files != null) {
        if (list.files!.length >= 1) deleteFileById(list.files![0].id);
        if (list.files!.length >= 2) deleteFileById(list.files![1].id);
        print('-- deleteFileByName() name=${name}');
      }
    } on Exception catch (e) {
      print('-- err deleteFileByName=${e.toString()}');
    }
    return true;
  }

  /// fileId = gfilelist!.files![n].id
  Future<void> deleteFileById(String? fileId) async {
    if (fileId == null) return;
    if (fileId.length < 3) return;
    if (isSignedIn() == false) return;

    var client = GoogleHttpClient(await gsa!.authHeaders);
    var drive = ga.DriveApi(client);
    drive.files.delete(fileId);
  }

  Future<void> deleteOldTempFile(int mb) async {
    await getTempFiles();
    gaTempFiles.sort((b, a) {
      return (a.createdTime ?? DateTime.now()).compareTo(b.createdTime ?? DateTime.now());
    });
    for (int i = 0; i < 10; i++) {
      if (getTempFileMb() < mb) return;
      deleteFileById(gaTempFiles.last.id);
      gaTempFiles.removeLast();
    }
  }
}
