import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'provider.dart';
//import 'package:video_thumbnail/video_thumbnail.dart' as video_thumbnail;
import 'model.dart';
//import 'package:flutter_video_info/flutter_video_info.dart';
import 'localizations.dart';
//import 'package:video_player/video_player.dart';
import 'dart:math';
import 'common.dart';
import 'package:photo_gallery/photo_gallery.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image/image.dart' as imglib;

final photoListScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());

class PhotoListScreen extends ConsumerWidget {
  PhotoListScreen(){}

  String title='In-app data';
  List<MyFile> fileList = [];
  int numIndex = 20;

  bool _init = false;
  int selectedIndex = 0;
  BuildContext? _context;
  WidgetRef? _ref;
  MyEdge _edge = MyEdge(provider:photoListScreenProvider);
  MyStorage _storage = new MyStorage();

  void init(BuildContext context, WidgetRef ref) {
    if(_init == false){
      readFiles();
      _init = true;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    this._context = context;
    this._ref = ref;
    int num = ref.watch(photoListProvider).num;
    int size = ref.watch(photoListProvider).size;
    int sizemb = (size/1024/1024).toInt();

    ref.watch(photoListScreenProvider);
    _edge.getEdge(context,ref);

    Future.delayed(Duration.zero, () => init(context,ref));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n("photolist_title")),
        backgroundColor:Color(0xFF000000),
        actions: <Widget>[
        ],
      ),
      body: Container(
        margin: _edge.homebarEdge,
        child: Stack(children: <Widget>[
          Positioned(
            top:0, left:0, right:0,
            height: 50,
            child: Container(
              color: Color(0xFF444444),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 50),
                IconButton(
                  icon: Icon(Icons.save),
                  iconSize: 32.0,
                  onPressed: () => _saveFileWithDialog(context,ref),
                ),
                Expanded(child: Text(num.toString() +' pcs '+sizemb.toString() + ' mb',textAlign:TextAlign.center)),
                IconButton(
                  icon: Icon(Icons.delete),
                  iconSize: 32.0,
                  onPressed: () => _deleteFileWithDialog(context,ref),
                ),
                SizedBox(width: 50),
              ]
            )
          )),
          Container(
            margin: EdgeInsets.only(top:52),
            child:getListView(context,ref),
          ),
        ])
      )
    );
  }

  Widget getListView(BuildContext context, WidgetRef ref) {
    int crossAxisCount = 3;
    double w = MediaQuery.of(context).size.width;
    if(w>800)
      crossAxisCount = 5;
    else if(w>600)
      crossAxisCount = 4;

    return Container(
      padding: EdgeInsets.symmetric(vertical:4, horizontal:6),
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        children: List.generate(fileList.length, (index) {
          return MyCard(data: fileList[index]);
        })),
    );
  }

  // /data/user/0/com.example.take/app_flutter/photo/2022-0417-170926.mp4
  Future<bool> readFiles() async {
    try {
      fileList.clear();
      if (kIsWeb) {
        for (int i = 1; i < 30; i++) {
          MyFile f = new MyFile();
          int h = (i / 10).toInt();
          int m = (i % 10).toInt();
          f.date = DateTime(2022, 1, 1, h, m, 0);
          f.path = 'aaa.mp4';
          fileList.add(f);
        }

      } else {
        // アプリ内データ
        await _storage.getInApp(true);
        fileList = _storage.files;
      }

      if(_ref!=null) {
        _ref!.read(photoListProvider).num = _storage.files.length;
        _ref!.read(photoListProvider).size = _storage.totalBytes;
        _ref!.read(photoListProvider).notifyListeners();
        _ref!.read(selectedListProvider).clear();
      }

    } on Exception catch (e) {
      print('-- readFiles() e=' + e.toString());
    }
    return true;
  }

  /// Save file
  _saveFileWithDialog(BuildContext context, WidgetRef ref) async {
    List<MyFile> list = ref.read(selectedListProvider).list;
    if(list.length==0) {
      showSnackBar('Please select');
    } else {
      Text msg = Text('Save to photolibrary (${list.length})');
      Text btn = Text('OK', style: TextStyle(fontSize: 16, color: Colors.lightBlue));
      showDialogEx(context, msg, btn, _saveFile, list);
    }
  }
  _saveFile(List<MyFile> list) async {
    try {
      for(MyFile f in list){
        if(f.isLibrary==false) {
          await _storage.saveLibrary(f.path);
          await new Future.delayed(new Duration(milliseconds:100));
        }
      }
      readFiles();
    } on Exception catch (e) {
      print('-- _saveFile ${e.toString()}');
    }
  }

  /// delete file
  _deleteFileWithDialog(BuildContext context, WidgetRef ref) async {
    List<MyFile> list = ref.read(selectedListProvider).list;
    if(list.length==0) {
      showSnackBar('Please select');
    } else {
      Text msg = Text('Delete files (${list.length})');
      Text btn = Text('Delete', style: TextStyle(fontSize: 16, color: Colors.lightBlue));
      showDialogEx(context, msg, btn, _deleteFile, list);
    }
  }
  _deleteFile(List<MyFile> list) async {
    try {
      for(MyFile f in list){
        await File(f.path).delete();
        if(await File(f.thumb).exists())
          await File(f.thumb).delete();
        await new Future.delayed(new Duration(milliseconds:100));
      };
      readFiles();
    } on Exception catch (e) {
      print('-- _deleteFile ${e.toString()}');
    }
  }

  /// Show dialog (OK or Cancel)
  Future<void> showDialogEx(
      BuildContext context,
      Text msg,
      Text buttonText,
      Function func,
      List<MyFile> list
    ) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: msg,
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style:TextStyle(fontSize:16, color:Colors.lightBlue)),
              onPressed:(){ Navigator.of(context).pop(); },
            ),
            TextButton(
              child: buttonText,
              onPressed:(){ func(list); Navigator.of(context).pop(); },
            ),
          ],
        );
      }
    );
  }

  String l10n(String text){
    if(_context!=null) {
      return Localized.of(_context!).text(text);
    }
    return '';
  }

  void showSnackBar(String msg) {
    if(_context!=null) {
      final snackBar = SnackBar(content: Text(msg));
      ScaffoldMessenger.of(_context!).showSnackBar(snackBar);
    }
  }
}

/// MyCard
class MyCard extends ConsumerWidget {
  final myCardScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
  MyCard({MyFile? data}) {
    if(data!=null) this.data = data;
  }

  MyFile data = MyFile();
  bool _selected = false;
  WidgetRef? _ref;

  Widget _thumbWidget = Center(
    child: SizedBox(
      width:32,height:32,
      child: CircularProgressIndicator(),
    ));

  bool _init = false;
  void init(BuildContext context, WidgetRef ref) async {
    if(_init == false){
      _init = true;
      if(kIsWeb) {
        _thumbWidget = Image.network('/lib/assets/test.png', fit: BoxFit.cover);
      } else if(await File(data.path).exists()==true){
        _thumbWidget = Image.file(File(data.path), fit:BoxFit.cover);
        ref.read(myCardScreenProvider).notifyListeners();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref){
    _selected = ref.watch(selectedListProvider).contains(data);
    ref.watch(myCardScreenProvider);
    this._ref = ref;
    Future.delayed(Duration.zero, () => init(context,ref));

    return Container(
      width: 100.0, height: 100.0,
      margin: EdgeInsets.all(4),
      padding: EdgeInsets.all(0),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap:(){
          ref.read(selectedListProvider).select(data);
        },
        onLongPress:(){
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PreviewScreen(data:data),
            ));
        },
        child: getWidget(ref),
      ),
    );
  }

  Widget getWidget(WidgetRef ref){
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // サムネイル
        _thumbWidget,

        // 日付
        Container(
          child: Text(' ' + DateFormat("MM/dd HH:mm").format(data.date) + ' ',
            style: TextStyle(fontSize:14, color:Colors.white, backgroundColor:Colors.black38),
        ),),

        // 保存済アイコン
        if(data.isLibrary)
          Positioned(
            right:4.0, top:4.0,
            child: CircleAvatar(
              radius: 20.0,
              backgroundColor: Colors.black54,
              child: Icon(
                Icons.save,
                size: 24,
                color: Color(0xFFFFFFFF)
              )
            )
          ),

        // 選択状態
        Positioned(
          right:6.0, bottom:6.0,
          child: CircleAvatar(
            backgroundColor: _selected ? Colors.black54 : Color(0x00000000),
            child: Icon(
              _selected ? Icons.check : null,
              size: 36,
              color: Colors.blueAccent
            )
          )
        ),
      ]
    );
  }

  String sec2strtime(int sec) {
    String s = "";
    s += (sec/3600).toInt().toString() + ':';
    s += (sec.remainder(3600)/60).toInt().toString().padLeft(2,'0') + ':';
    s += sec.remainder(60).toString().padLeft(2,'0');
    return s;
  }
}

final previewScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class PreviewScreen extends ConsumerWidget {
  PreviewScreen({MyFile? data}) {
    if(data!=null) this.data = data;
  }

  MyFile data = MyFile();
  WidgetRef? _ref;
  Image? _img;
  int _width=0;
  int _height=0;
  bool _init = false;
  MyEdge _edge = MyEdge(provider:previewScreenProvider);

  void init(BuildContext context, WidgetRef ref) async {
    if(_init == false){
      try{
        if(data.path.contains('.jpg')){
          //_img = Image.file(File(data.path), fit:BoxFit.contain);
          //ref.read(previewScreenProvider).notifyListeners();

          _img = Image.file(File(data.path), fit:BoxFit.contain);
          _img!.image.resolve(ImageConfiguration.empty).addListener(
            ImageStreamListener((ImageInfo info, bool b) {
                print('width=${info.image.width}');
                _width = info.image.width.toInt();
                _height = info.image.height.toInt();
                ref.read(previewScreenProvider).notifyListeners();
              },
            ),
          );
        }
      } on Exception catch (e) {
        print('-- PreviewScreen.init ${e.toString()}');
      }
      _init = true;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref){
    Future.delayed(Duration.zero, () => init(context,ref));
    ref.watch(previewScreenProvider);
    this._ref = ref;
    _edge.getEdge(context,ref);

    return Scaffold(
      appBar: AppBar(
        title: Text('Preview'),
        actions: <Widget>[],
      ),
      body: Container(
        margin: _edge.homebarEdge,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap:(){
            Navigator.of(context).pop();
          },
          child: Stack(children: <Widget>[
            player(),
            getInfoText(),
          ])
        ),
    ));
  }

  Widget player() {
    if(kIsWeb) {
      return Center(child:Image.network('/lib/assets/test.png',fit:BoxFit.contain));
    } else if(data.path.contains('.jpg')) {
      return (_img!=null) ? Center(child:_img) : Container();
    } else {
      return Center(child:Image.network('/lib/assets/test.png',fit:BoxFit.contain));
    }
  }

  Widget getInfoText(){
    if(data.path.contains('.jpg')) {
      if(_img==null){
        return Container();
      } else {
        return Container(
          padding: EdgeInsets.symmetric(vertical:4, horizontal:8),
          width:160, height:66,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              getText(DateFormat("yyyy-MM-dd HH:mm:ss").format(data.date)),
              getText('${_width} x ${_height}'),
              getText('${(data.byte/1024).toInt()} KB'),
            ]
          )
        );
      }
    } else {
      return Container();
    }
  }

  Widget getText(String txt){
    return Align(alignment:Alignment.centerLeft,
      child:Text(txt),
    );
  }
}