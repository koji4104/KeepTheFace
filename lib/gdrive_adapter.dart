import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:path/path.dart';

String ALBUM_NAME = "TheseDays";

class GoogleHttpClient extends IOClient {
  Map<String, String> _headers;
  GoogleHttpClient(this._headers) : super();
  @override
  Future<IOStreamedResponse> send(http.BaseRequest request) =>
      super.send(request..headers.addAll(_headers));
  @override
  Future<http.Response> head(Object url, {Map<String, String>? headers}) =>
      super.head(url as Uri, headers: headers!..addAll(_headers));
}

class GoogleDriveAdapter {
  GoogleSignIn googleSignIn = GoogleSignIn(
    scopes:[ga.DriveApi.driveScope]
  );
  final storage = new FlutterSecureStorage();
  GoogleSignInAccount? gsa;
  bool isSignedIn(){ return gsa!=null; }

  /// displayName(email) or email
  String getAccountName(){
    String r = 'None';
    if(gsa!=null){
      if(gsa!.displayName!=null) {
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

  GoogleDriveAdapter(){}

  /// Already logged in
  Future<bool> loginSilently() async {
    gsa = null;
    try{
      if (await storage.read(key:'signedIn')=='true') {
        gsa = await googleSignIn.signInSilently();
        if(gsa==null){
          storage.write(key:'signedIn',value:'false');
        }
      }
    } on Exception catch (e) {
      print('-- err loginSilently() ${e.toString()}');
    }
    print('-- loginSilently() is ${gsa!=null}');
    return gsa!=null;
  }

  // New account or Existing account
  Future<bool> loginWithGoogle() async {
    print('-- loginWithGoogle()');
    try{
      gsa = await googleSignIn.signIn();
      if(gsa!=null) {
        storage.write(key:'signedIn',value:'true');
      }
    } on Exception catch (e) {
      print('-- err loginWithGoogle() ${e.toString()}');
    }
    print('-- loginWithGoogle() is ${gsa!=null}');
    return gsa!=null;
  }

  Future logout() async {
    print('-- logout');
    googleSignIn.signOut().then((value) {
      storage.write(key:'signedIn',value:'false').then((value) {
        gsa = null;
      });
    });
  }

  Future<void> getFiles() async {
    print('-- getFiles');
    if(isSignedIn()==false) {
      print('-- not SignedIn');
      return;
    }
    var client = GoogleHttpClient(await gsa!.authHeaders);
    var drive = ga.DriveApi(client);
    try{
      // folder id
      if(folderId==null) {
        String q = "mimeType='application/vnd.google-apps.folder'";
        q += " and name='${folderName}'";
        q += " and trashed=False";
        q += " and 'root' in parents";
        ga.FileList folders = await drive.files.list(
          q:q,
        );
        for (var i = 0; i < folders.files!.length; i++) {
          if (folders.files![i].name == folderName && folders.files![i].id != null ) {
            folderId = folders.files![i].id!;
            print('-- folderId=${folders.files![i].id} name=${folders.files![i].name}');
          }
        }
        // create folder
        if(folderId==null) {
          final googleApisFolder = ga.File();
          googleApisFolder.name = folderName;
          googleApisFolder.mimeType = 'application/vnd.google-apps.folder';
          final response = await drive.files.create(googleApisFolder);
          folderId = response.id;
          print('create folder');
        }
        print('folders.length=${folders.files!.length} folderid=${folderId}');
      }

      // File list
      String q = "mimeType!='application/vnd.google-apps.folder' and '${folderId}' in parents";
      gfilelist = await drive.files.list(
        q:q,
        $fields:'*',
        orderBy:'name',
      );
      print('gfilelist.length=${gfilelist!.files!.length}');

    } on Exception catch (e) {
      print('-- err _getFiles=${e.toString()}');
    }
  }

  Future<void> uploadFile(String path) async {
    print('-- GoogleDriveAdapter.uploadFile');
    if(isSignedIn()==false) {
      print('-- not SignedIn');
      return;
    }
    if(folderId==null) {
      print('-- not folderId');
      return;
    }
    var client = GoogleHttpClient(await gsa!.authHeaders);
    var drive = ga.DriveApi(client);

    var request = new ga.File();
    File file = File(path);
    request.name = basename(path);
    request.parents = [];
    request.parents!.add(folderId!);

    var res = await drive.files.create(
        request,
        uploadMedia:ga.Media(file.openRead(),file.lengthSync()));
    print(res);
  }

  /// fileId = gfilelist!.files![n].id
  Future<void> deleteFile(String fileId) async {
    if(isSignedIn()==false) {
      print('-- not SignedIn');
      return;
    }
    var client = GoogleHttpClient(await gsa!.authHeaders);
    var drive = ga.DriveApi(client);

    drive.files.delete(fileId);
    gfilelist!.files!.removeAt(0);
  }
}
