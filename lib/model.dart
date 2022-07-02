import 'dart:core';

class PhotoData{
  String path = '';
  String name = '';
  DateTime date = DateTime(2000,1,1);
  String thumb = '';
  int byte = 0;
  PhotoData(String path) {
    this.path = path;
  }
  bool isGallery = false;
}

