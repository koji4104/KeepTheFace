import 'package:camera/camera.dart';
import 'package:image/image.dart' as imglib;
import 'dart:async';

class CameraImageConverter {
  static Future<imglib.Image?> toImage(CameraController? cameraController, CameraImage? cameraImage) async {
    
    if(cameraController==null || cameraImage==null) {
      print('err cameraController==null || cameraImage==null');
      return null;
    }
    imglib.Image? img;
    if (cameraImage!.format.group == ImageFormatGroup.yuv420) {
      print('yuv420');
      img = await _convertYuv(cameraImage!);
      if(img!=null){
        int angle = cameraController!.description.sensorOrientation;
        if(angle>0)
          img = imglib.copyRotate(img, angle);
      }
    } else if (cameraImage!.format.group == ImageFormatGroup.bgra8888) {
      print('bgra8888');
      img = _convertRgb(cameraImage!);
    }
    if(img==null)
      print('err img=null');

    return img;
  }

  static Future<imglib.Image?> _convertYuv(CameraImage image) async {
    final int width = image.width;
    final int height = image.height;

    if(image.planes.length<3) {
      print('err convertYuv() planes.length=${image.planes.length}');
      return null;
    } else if(image.planes[1].bytesPerPixel==null) {
      print('err convertYuv() planes[1].bytesPerPixel=null');
      return null;
    } else if(image.planes[0].bytes.length<width*height) {
      print('err convertYuv() planes[0].bytes.length=${image.planes[0].bytes.length}');
      print('err convertYuv() planes[1].bytes.length=${image.planes[1].bytes.length}');
      print('err convertYuv() planes[2].bytes.length=${image.planes[2].bytes.length}');
      return null;
    }

    try {
      imglib.Image img = imglib.Image(image.width, image.height);
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel!;
      //print('uvRowStride=${uvRowStride} uvPixelStride=${uvPixelStride}');

      // RGB from YUV420_888
      for(int x=0; x < width; x++) {
        for(int y=0; y < height; y++) {
          final int uvIndex = uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
          final int index = y * width + x;

          final yp = image.planes[0].bytes[index];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];

          // Calculate pixel color
          int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
          int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
          int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
          img.data[index] = (0xFF << 24) | (b << 16) | (g << 8) | r;
        }
      }
      return img;
    } catch (e) {
      print("err convertYuv() " + e.toString());
    }
    return null;
  }

  static imglib.Image _convertRgb(CameraImage image) {
    return imglib.Image.fromBytes(
      image.width, image.height,
      image.planes[0].bytes,
      format: imglib.Format.bgra,
    );
  }
}