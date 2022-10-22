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
import 'package:video_thumbnail/video_thumbnail.dart' as video_thumbnail;
import 'package:video_player/video_player.dart';
import 'package:flutter_video_info/flutter_video_info.dart';

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
                SizedBox(width: 20),
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
                SizedBox(width:16),
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
                SizedBox(width:16),
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
                SizedBox(width:16),
                // 保存
                if(bSelectMode)
                IconButton(
                  icon: Icon(Icons.save),
                  iconSize: 32.0,
                  onPressed: () => _saveFileWithDialog(context,ref),
                ),
                SizedBox(width:16),
                // 削除
                if(bSelectMode)
                IconButton(
                  icon: Icon(Icons.delete),
                  iconSize: 32.0,
                  onPressed: () => _deleteFileWithDialog(context,ref),
                ),
                SizedBox(width: 20),
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

  // /data/user/0/com.github.koji4104/app_flutter/photo/2022-0417-170926.mp4
  Future<bool> readFiles() async {
    try {
      fileList.clear();
      if (kIsWeb) {
        for (int i = 1; i < 30; i++) {
          MyFile f = new MyFile();
          int h = (i / 10).toInt();
          int m = (i % 10).toInt();
          f.date = DateTime(2022, 10, 1, h, m, 0);
          f.path = (i%3==0)?'http://localhost:8000/test.mp4'
              :(i%3==1)?'http://localhost:8000/test.m4a'
              :'http://localhost:8000/test.jpg';
          f.thumb = 'http://localhost:8000/test.jpg';
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

        // thumb
        final Directory appdir = await getApplicationDocumentsDirectory();
        final _thumbdir = Directory('${appdir.path}/thumb');
        await Directory('${appdir.path}/thumb').create(recursive: true);
        List<FileSystemEntity> _entities = _thumbdir.listSync(recursive:true, followLinks:false);
        List<String> _thumbs = [];
        for (FileSystemEntity e in _entities) {
          _thumbs.add(e.path);
        }

        final String thumbDir = '${appdir.path}/thumb/';
        for (MyFile f in fileList) {
          if(f.path.contains('.mp4')) {
            f.thumb = thumbDir + basenameWithoutExtension(f.path) + ".jpg";
            if (await File(f.thumb).exists() == false) {
              String? s = await video_thumbnail.VideoThumbnail.thumbnailFile(
                  video: f.path,
                  thumbnailPath: f.thumb,
                  imageFormat: video_thumbnail.ImageFormat.JPEG,
                  maxHeight: 240,
                  quality: 70);
              f.thumb = (s != null) ? s : "";
            }
            if (_thumbs.indexOf(f.thumb) >= 0)
              _thumbs.removeAt(_thumbs.indexOf(f.thumb));
          }
        }
        // delete unused thumbnail
        for (String u1 in _thumbs) {
          if (await File(u1).exists()) {
            await File(u1).delete();
          }
        }
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
      Text btn = Text(l10n('save'), style: TextStyle(fontSize:16, color: Colors.lightBlue));
      //showDialogEx(context, msg, l10n('save'), _saveFile, list);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: msg,
            actions: <Widget>[
              Column(children:[
                MyTextButton(
                  label:l10n('cancel'),
                  onPressed:(){ Navigator.of(context).pop(); }
                ),
                MyTextButton(
                    label:l10n('save'),
                    onPressed:(){ _saveFile(list); Navigator.of(context).pop(); }
                ),
                MyTextButton(
                    label:'Google Drive',
                    onPressed:(){ _saveFile(list); Navigator.of(context).pop(); }
                ),
                MyTextButton(
                    label:'Keepに保存',
                    onPressed:(){ _saveFile(list); Navigator.of(context).pop(); }
                ),
              ])
            ],
          );
        }
      );
    }
  }
  _saveFile(List<MyFile> list) async {
    try {
      for(MyFile f in list){
        if(f.isLibrary==false) {
          if(f.path.contains('.jpg') || f.path.contains('.mp4'))
            await _storage.saveLibrary(f.path);
          else if(f.path.contains('.m4a'))
            await _storage.saveFileSaver(f.path);
          await new Future.delayed(new Duration(milliseconds:100));
        }
      }
    } on Exception catch (e) {
      print('-- _saveFile ${e.toString()}');
    }
  }

  Widget MyTextButton({required String label, required void Function()? onPressed,
    Color? fgcol}){
    if(fgcol==null) fgcol = Colors.white;
    return Container(
      width: 200,
      padding: EdgeInsets.symmetric(vertical:0,horizontal:0),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Color(0xFF606060),
          shape: RoundedRectangleBorder(borderRadius:BorderRadius.all(Radius.circular(40)))
        ),
        child: Text(label, style:TextStyle(color:fgcol), textAlign:TextAlign.center),
        onPressed: onPressed
      ),
    );
  }

  /// delete file
  _deleteFileWithDialog(BuildContext context, WidgetRef ref) async {
    List<MyFile> list = ref.read(selectedListProvider).list;
    if(list.length==0) {
      showSnackBar('Please select');
    } else {
      Text msg = Text(l10n('delete_files') + ' (${list.length})');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: msg,
            actions: <Widget>[
              Column(children:[
              MyTextButton(
                label: l10n('cancel'),
                onPressed:(){ Navigator.of(context).pop(); },
              ),
              MyTextButton(
                fgcol: Color(0xFFF08080),
                label: l10n('delete'),
                onPressed:(){ _deleteFile(list); Navigator.of(context).pop(); },
              ),
            ])
            ],
          );
        }
      );
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
    if(_init == false) {
      _init = true;
      /*
      if(kIsWeb) {
        if(data.path.contains('.m4a')) {
          _thumbWidget = Icon(
              Icons.mic,
              size: 48,
              color: Color(0xFF888888));
        } else {
          _thumbWidget = Image.network('/lib/assets/test.jpg', fit:BoxFit.cover);
        }
        ref.read(myCardScreenProvider).notifyListeners();
*/
      //if(await f.exists()==true){
        if(data.path.contains('.jpg')) {
          if(kIsWeb) {
            _thumbWidget = Image.network('/lib/assets/test.jpg', fit: BoxFit.cover);
          } else if(await File(data.path).exists()==true) {
            _thumbWidget = Image.file(File(data.path), fit: BoxFit.cover);
          }
        } else if(data.path.contains('.m4a')) {
          _thumbWidget = Icon(
              Icons.volume_mute ,
              size: 48,
              color: Color(0xFF666666));

        } else if(data.path.contains('.mp4')) {
          if(kIsWeb) {
            _thumbWidget = Image.network('/lib/assets/test.jpg', fit: BoxFit.cover);
          }  else if(await File(data.thumb).exists()==true) {
            _thumbWidget = Image.file(File(data.thumb), fit: BoxFit.cover);
          }
        }
        ref.read(myCardScreenProvider).notifyListeners();
      //}
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
            radius: _width<100 ? 12.0+4.0 : _width>200 ? 24.0+4.0 : 18.0+4.0,
            child: Icon(
              _selected ? Icons.check : null,
              size: _width<100 ? 24.0 : _width>200 ? 48.0 : 36.0,
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
    if(_width<100){
      fsize = 14;
      s = DateFormat("MM/dd").format(data.date);
    } else if(_width>200){
      fsize = 14;
      s = DateFormat("yyyy/MM/dd HH:mm").format(data.date);
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
  int _duration=0;
  int _orientation=0;
  bool _init = false;
  Offset _offset = Offset(0,0);
  MyEdge _edge = MyEdge(provider:previewScreenProvider);
  VideoPlayerController? _videoPlayer;
  bool _isPlaying = false;

  void init(BuildContext context, WidgetRef ref) async {
    if(_init == false){
      _init = true;
      //if(kIsWeb) return;
      try{
        if(data.path.contains('.jpg')){
          if(kIsWeb) {
            _img = Image.network('/lib/assets/test.jpg', fit: BoxFit.contain);
            ref.read(previewScreenProvider).notifyListeners();
          } else {
            _img = Image.file(File(data.path), fit: BoxFit.contain);
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

        } else if(data.path.contains('.m4a')) {
          if(kIsWeb) {
            _videoPlayer = VideoPlayerController.network(data.path)
              ..initialize().then((_) {
                _duration = _videoPlayer!.value.duration.inSeconds;
                ref.read(previewScreenProvider).notifyListeners();
              });

          } else {
            _videoPlayer = VideoPlayerController.file(File(data.path))
              ..initialize().then((_) {
                _duration = _videoPlayer!.value.duration.inSeconds;
                ref.read(previewScreenProvider).notifyListeners();
              });
          }

        } else if(data.path.contains('.mp4')) {
          if(kIsWeb){
            _videoPlayer = VideoPlayerController.network(data.path)
              ..initialize().then((_) {
                _duration = _videoPlayer!.value.duration.inSeconds;
                ref.read(previewScreenProvider).notifyListeners();
              });

          } else {
            _videoPlayer = VideoPlayerController.file(File(data.path))
              ..initialize().then((_) {
                _duration = _videoPlayer!.value.duration.inSeconds;
                _width = _videoPlayer!.value.size.width.toInt();
                _height = _videoPlayer!.value.size.height.toInt();
                ref.read(previewScreenProvider).notifyListeners();
              });

            final videoInfo = FlutterVideoInfo();
            var a = await videoInfo.getVideoInfo(data.path).then((value) {
              if(value!=null) {
                _orientation = value.orientation!=null ? value.orientation! : 0;
                ref.read(previewScreenProvider).notifyListeners();
              }
            });
          }

        }
      } on Exception catch (e) {
        print('-- PreviewScreen.init ${e.toString()}');
      }
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
          onPanUpdate: (DragUpdateDetails details) {
            if(details.delta.dy>10) {
              if(_videoPlayer!=null) {
                _videoPlayer!.dispose();
              }
              Navigator.of(context).pop();
            }
          },
          child: Stack(children: <Widget>[
            player(),
            getInfoText(),
            leftButton(),
            playButton(),
            rightButton(),
            if(_videoPlayer!=null)
        Positioned(
        left:0, right:0, bottom:10,
            child:VideoProgressIndicator(
              _videoPlayer!,
              allowScrubbing:true,
              colors: new VideoProgressColors(
                playedColor: Colors.red,
                bufferedColor: Colors.black,
                backgroundColor: Colors.black,
              ),
            )),
          ])
        ),
    ));
  }

  Widget player() {
    //if(kIsWeb) {
    //  return Center(child:Image.network('/lib/assets/test.jpg',fit:BoxFit.contain));
    if(data.path.contains('.jpg')) {
      return (_img!=null) ? Center(child:_img) : Container();
    } else if(data.path.contains('.mp4')) {
      if (_videoPlayer==null) {
        return Container();
      } else {
        double aspect = _videoPlayer!.value.size.aspectRatio;
        if(aspect<=0.0)
          return Container();
        else
          return Center(
            child: AspectRatio(
              aspectRatio: aspect,
              child: VideoPlayer(_videoPlayer!)
            )
          );
      }
    } else {
      return Container();
    }
  }

  Widget getInfoText(){
    if(data.path.contains('.jpg')) {
      if (_img == null) {
        return Container();
      } else {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            getText(DateFormat("yyyy-MM-dd HH:mm:ss").format(data.date)),
            getText('${(data.byte / 1024).toInt()} kb'),
            getText('${_width} x ${_height}'),
          ]
        );
      }

    } else if(data.path.contains('.m4a')) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          getText(DateFormat("yyyy-MM-dd HH:mm:ss").format(data.date)),
          getText('${(data.byte / 1024).toInt()} kb'),
          getText('${_duration} sec'),
        ]
      );

    } else if(data.path.contains('.mp4')) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          getText(DateFormat("yyyy-MM-dd HH:mm:ss").format(data.date)),
          getText('${(data.byte / 1024).toInt()} kb'),
          getText('${_width} x ${_height}'),
          getText('${(_duration).toInt()} sec'),
          getText('${_orientation} deg'),
        ]
      );
    } else {
      return Container();
    }
  }

  Widget leftButton() {
    if(data.path.contains('.jpg') || _videoPlayer==null)
      return Container();
    return Positioned(
        top:0, bottom:0, left:30,
        child: myButton(
          icon: Icon(Icons.chevron_left),
          onPressed:(){
            int sec = _videoPlayer!.value.position.inSeconds - 15;
            _videoPlayer!.seekTo(Duration(seconds:sec));
            _ref!.read(previewScreenProvider).notifyListeners();
          },
        )
    );
  }

  Widget rightButton() {
    if(data.path.contains('.jpg') || _videoPlayer==null)
      return Container();
    return Positioned(
      top:0, bottom:0, right:30,
      child: myButton(
        icon: Icon(Icons.chevron_right),
        onPressed:() async {
          int sec = _videoPlayer!.value.position.inSeconds + 15;
          _videoPlayer!.seekTo(Duration(seconds:sec));
          _ref!.read(previewScreenProvider).notifyListeners();
        },
      )
    );
  }

  Widget playButton() {
    if(data.path.contains('.jpg') || _videoPlayer==null)
      return Container();
    if(_isPlaying==false) {
      return Center(
        child: myButton(
          icon: Icon(Icons.play_arrow),
          onPressed:(){
            _videoPlayer!.play();
            _isPlaying = true;
            _ref!.read(previewScreenProvider).notifyListeners();
          },
        )
      );
    } else {
      return Center(
        child: myButton(
          icon: Icon(Icons.pause),
          onPressed:(){
            _videoPlayer!.pause();
            _isPlaying = false;
            _ref!.read(previewScreenProvider).notifyListeners();
          },
        )
      );
    }
  }

  Widget myButton({required Icon icon, required void Function()? onPressed}) {
    return CircleAvatar(
      backgroundColor: Colors.black38,
      radius: 38.0,
      child: IconButton(
        iconSize: 48,
        icon: icon,
        onPressed:onPressed,
      )
    );
  }

  Widget getText(String txt){
    return Container(
      padding: EdgeInsets.symmetric(vertical:2, horizontal:2),
      width: 200,
      color: Colors.black54,
      child: Align(alignment:Alignment.centerLeft,
        child:Text(txt,style:TextStyle(color:Colors.white, fontSize:16)),
      )
    );
  }
}