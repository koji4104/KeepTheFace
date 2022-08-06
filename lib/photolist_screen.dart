import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'provider.dart';
import 'localizations.dart';
import 'common.dart';

final photoListScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class PhotoListScreen extends ConsumerWidget {
  PhotoListScreen(){}

  String title='In-app data';
  List<MyFile> fileList = [];
  List<MyCard> cardList = [];

  int _crossAxisCount = 3;
  int _gridZoom = 0;
  int _photocount = 0;
  int _sizemb = 0;

  bool _init = false;
  int selectedIndex = 0;
  late BuildContext _context;
  late WidgetRef _ref;
  MyEdge _edge = MyEdge(provider:photoListScreenProvider);
  MyStorage _storage = new MyStorage();

  void init(BuildContext context, WidgetRef ref) {
    if(_init) return;
    readFiles();
    // 392x829
    double w = MediaQuery.of(context).size.width;
    if(w>800)
      _crossAxisCount = 5;
    else if(w>600)
      _crossAxisCount = 4;
    _init = true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future.delayed(Duration.zero, () => init(context,ref));
    this._context = context;
    this._ref = ref;
    _edge.getEdge(context,ref);

    bool bSelectMode = ref.watch(isSelectModeProvider);
    ref.watch(photoListScreenProvider);

    return Scaffold(
      appBar: AppBar(
        title:Row(children:[
          Text(l10n("photolist_title")),
          Expanded(child: SizedBox(width:1)),
          Text(_photocount.toString() +' pcs '+_sizemb.toString() + ' mb',style:TextStyle(fontSize:13)),
        ]),
        backgroundColor:Color(0xFF000000),
        actions: <Widget>[
        ],
      ),
      body: Container(
        margin: _edge.homebarEdge,
        child: Stack(children: <Widget>[
          Positioned(
            top:0, left:0, right:0, height:50,
            child: Container(
              color: Color(0xFF444444),
              child: Row(children: [
                SizedBox(width: 30),
                // ズームイン
                IconButton(
                  icon: Icon(Icons.zoom_out),
                  iconSize: 32.0,
                  onPressed:(){
                    if(_gridZoom<2) {
                      _gridZoom++;
                      ref.read(cardWidthProvider.state).state = (_edge.width/(_crossAxisCount + _gridZoom)).toInt();
                      redraw();
                    }
                  },
                ),
                SizedBox(width:20),
                // ズームアウト
                IconButton(
                  icon: Icon(Icons.zoom_in),
                  iconSize: 32.0,
                  onPressed:(){
                    if(_gridZoom>-2) {
                      _gridZoom--;
                      ref.read(cardWidthProvider.state).state = (_edge.width/(_crossAxisCount + _gridZoom)).toInt();
                      redraw();
                    }
                  },
                ),
                SizedBox(width:20),
                IconButton(
                  icon: bSelectMode==false ?
                    Icon(Icons.check_circle_outline) :
                    Icon(Icons.check_circle),
                  iconSize: 32.0,
                  onPressed:(){
                    _ref.read(isSelectModeProvider.state).state = !bSelectMode;
                    _ref.read(selectedListProvider).clear();
                    redraw();
                  },
                ),
                SizedBox(width:20),
                // 保存
                if(bSelectMode)
                IconButton(
                  icon: Icon(Icons.save),
                  iconSize: 32.0,
                  onPressed: () => _saveFileWithDialog(context,ref),
                ),
                SizedBox(width:20),
                // 削除
                if(bSelectMode)
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
            child:getList(context,ref),
          ),
        ])
      )
    );
  }

  Widget getList(BuildContext context, WidgetRef ref) {
    if(_init==false)
      return Container();
    return Container(
      padding: EdgeInsets.symmetric(vertical:4, horizontal:6),
      child: GridView.count(
          crossAxisCount: _crossAxisCount + _gridZoom,
          children: List.generate(cardList.length, (index) {
            return cardList[index];
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
          f.byte = 2*1024*1024;
          fileList.add(f);
        }
        _photocount = fileList.length;
        _sizemb = 1;

      } else {
        // アプリ内データ
        await _storage.getInApp(true);
        fileList = _storage.files;
        _photocount = fileList.length;
        _sizemb = (_storage.totalBytes/1024/1024).toInt();
        if(_storage.totalBytes>0 && _sizemb==0)
          _sizemb = 1;
      }

      for (MyFile f in fileList) {
        cardList.add(MyCard(data:f));
      }

      _ref.read(selectedListProvider).clear();
      redraw();
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
      Text msg = Text(l10n('save_files') + ' (${list.length})');
      Text btn = Text(l10n('save'), style: TextStyle(fontSize: 16, color: Colors.lightBlue));
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
      //readFiles();
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
      Text msg = Text(l10n('delete_files') + ' (${list.length})');
      Text btn = Text(l10n('delete'), style: TextStyle(fontSize:16, color:Colors.redAccent));
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
              child: Text(l10n('cancel'), style:TextStyle(fontSize:16, color:Color(0xFFcccccc))),
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
    return Localized.of(_context).text(text);
  }

  void showSnackBar(String msg) {
    final snackBar = SnackBar(content:Text(msg));
    ScaffoldMessenger.of(_context).showSnackBar(snackBar);
  }

  redraw(){
    _ref.read(photoListScreenProvider).notifyListeners();
  }
}

///--------------------------------------------------------
/// MyCard
class MyCard extends ConsumerWidget {
  final myCardScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
  MyCard({MyFile? data}) {
    if(data!=null) this.data = data;
  }

  MyFile data = MyFile();
  bool _selected = false;
  WidgetRef? _ref;
  int _width = 200;

  Widget? _thumbWidget ;

  bool _init = false;
  void init(BuildContext context, WidgetRef ref) async {
    if(_init == false){
      print('-- card init');
      _init = true;
      if(kIsWeb) {
        _thumbWidget = Image.network('/lib/assets/test.png', fit:BoxFit.cover);
        ref.read(myCardScreenProvider).notifyListeners();
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
    bool bSelectMode = ref.watch(isSelectModeProvider);
    _width = ref.watch(cardWidthProvider);

    return Container(
      width: 100.0, height: 100.0,
      margin: EdgeInsets.all(2),
      padding: EdgeInsets.all(0),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap:(){
          bSelectMode ?
          ref.read(selectedListProvider).select(data) :
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PreviewScreen(data:data),
            )
          );
        },
        onLongPress:(){
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PreviewScreen(data:data),
            )
          );
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
        getThumbnail(),

        // 日付
        getDateText(),

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
            backgroundColor: _selected ? Color(0xFF303030) : Color(0x00000000),
            radius: _width<150 ? 12.0+4.0 : _width>300 ? 24.0+4.0 : 18.0+4.0,
            child: Icon(
              _selected ? Icons.check : null,
              size: _width<150 ? 24.0 : _width>300 ? 48.0 : 36.0,
              color: Colors.white
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

  Widget getThumbnail() {
    if (_thumbWidget == null) {
      return Center(
          child: SizedBox(
            width: 32, height: 32,
            child: CircularProgressIndicator(),
          ));
    } else {
      return _thumbWidget!;
    }
  }

  Widget getDateText(){
    double fsize = 14;
    String s = DateFormat("MM/dd HH:mm").format(data.date);
    if(_width<150){
      fsize = 13;
      s = DateFormat("MM/dd HH").format(data.date);
    } else if(_width>300){
      fsize = 15;
    }
    return Container(
      child: Text(' ' + s + ' ',
        style: TextStyle(fontSize:fsize, color:Colors.white, backgroundColor:Colors.black38),
      ),);
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