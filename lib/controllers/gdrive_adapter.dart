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

  ga.FileList? gfilelist = null;
  String? folderId;
  String folderName = ALBUM_NAME;

  /// Already logged in
  Future<bool> loginSilently() async {
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

  Future<void> getFolderId() async {
    var client = GoogleHttpClient(await gsa!.authHeaders);
    var drive = ga.DriveApi(client);
    try {
      // folder id
      if (folderId == null) {
        String q = "mimeType='application/vnd.google-apps.folder'";
        q += " and name='${folderName}'";
        q += " and trashed=False";
        q += " and 'root' in parents";
        ga.FileList folders = await drive.files.list(
          q: q,
        );
        for (var i = 0; i < folders.files!.length; i++) {
          if (folders.files![i].name == folderName && folders.files![i].id != null) {
            folderId = folders.files![i].id!;
            print('-- folderId=${folders.files![i].id} name=${folders.files![i].name}');
          }
        }
        // create folder
        if (folderId == null) {
          final googleApisFolder = ga.File();
          googleApisFolder.name = folderName;
          googleApisFolder.mimeType = 'application/vnd.google-apps.folder';
          final response = await drive.files.create(googleApisFolder);
          folderId = response.id;
          print('create folder');
        }
        print('folders.length=${folders.files!.length} folderid=${folderId}');
      }
    } on Exception catch (e) {
      print('-- err getFolderId() e=${e.toString()}');
    }
  }

  Future<void> getFiles() async {
    print('-- getFiles');
    if (isSignedIn() == false) {
      print('-- not SignedIn');
      return;
    }
    var client = GoogleHttpClient(await gsa!.authHeaders);
    var drive = ga.DriveApi(client);
    try {
      // folder id
      if (folderId == null) {
        await getFolderId();
      }

      // File list
      String q = "mimeType!='application/vnd.google-apps.folder' and '${folderId}' in parents";
      gfilelist = await drive.files.list(
        q: q,
        $fields: '*',
        orderBy: 'name',
        pageSize: 2000,
      );
      print('gfilelist.length=${gfilelist!.files!.length}');
    } on Exception catch (e) {
      print('-- err _getFiles=${e.toString()}');
    }
  }

  int getFileCount() {
    int r = 0;
    if (gfilelist != null && gfilelist!.files != null) r = gfilelist!.files!.length;
    return r;
  }

  int getFileMb() {
    int r = 0;
    if (gfilelist != null && gfilelist!.files != null) {
      int totalBytes = 0;
      for (ga.File f in gfilelist!.files!) {
        totalBytes += f.size != null ? int.parse(f.size!) : 0;
      }
      r = (totalBytes / 1024 / 1024).toInt();
    }
    return r;
  }

  Future<bool> uploadFile(String path) async {
    print('-- GoogleDriveAdapter.uploadFile()');
    if (isSignedIn() == false) {
      print('-- not SignedIn');
      return false;
    }
    if (folderId == null) {
      await getFolderId();
      if (folderId == null) {
        print('-- not folderId');
        return false;
      }
    }

    try {
      var client = GoogleHttpClient(await gsa!.authHeaders);
      var drive = ga.DriveApi(client);

      var request = new ga.File();
      File file = File(path);
      request.name = basename(path);
      request.parents = [];
      request.parents!.add(folderId!);

      var retfile = await drive.files.create(request, uploadMedia: ga.Media(file.openRead(), file.lengthSync()));
      print('-- uploadFile() id=${retfile.id}');
      return true;
    } catch (e) {
      print('-- err uploadFile() ${e}');
      return false;
    }
  }

  /// fileId = gfilelist!.files![n].id
  Future<void> deleteFile(String fileId) async {
    if (isSignedIn() == false) {
      print('-- not SignedIn');
      return;
    }
    var client = GoogleHttpClient(await gsa!.authHeaders);
    var drive = ga.DriveApi(client);

    drive.files.delete(fileId);
    gfilelist!.files!.removeAt(0);
  }
}
