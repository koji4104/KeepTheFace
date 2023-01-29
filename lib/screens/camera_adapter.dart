import 'package:camera/camera.dart';
import 'package:image/image.dart' as imglib;
import 'dart:async';
import 'dart:typed_data'; // Uint8List

class CameraAdapter {
  /// Take image silently
  /// - i.g. imglib.Image? img = await CameraAdapter.takeImage(_controller);
  /// - If it fails. CameraController.imageFormatGroup yuv420 -> bgra8888
  static Future<imglib.Image?> takeImage(CameraController? controller) async {
    if (controller == null) {
      return null;
    }
    imglib.Image? img;
    controller.startImageStream((CameraImage cameraImage) async {
      controller.stopImageStream();
      img = await _toImage(controller, cameraImage);
    });
    for (var i = 0; i < 200; i++) {
      await Future.delayed(Duration(milliseconds: 100));
      if (img != null) break;
    }
    return img;
  }

  static Future<imglib.Image?> _toImage(
      CameraController? controller, CameraImage? cameraImage) async {
    if (controller == null || cameraImage == null) {
      return null;
    }
    imglib.Image? img;
    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      img = await _fromYuv(cameraImage);
      if (img != null) {
        int angle = controller.description.sensorOrientation;
        if (angle > 0) img = imglib.copyRotate(img, angle: angle);
      }
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      img = _fromRgb(cameraImage);
    }
    return img;
  }

  static Future<imglib.Image?> _fromYuv(CameraImage? image) async {
    if (image == null) return null;
    final int width = image.width;
    final int height = image.height;

    if (image.planes.length < 3) {
      print('err _fromYuv() planes.length=${image.planes.length}');
      return null;
    } else if (image.planes[1].bytesPerPixel == null) {
      print('err _fromYuv() planes[1].bytesPerPixel=null');
      return null;
    } else if (image.planes[0].bytes.length < width * height) {
      print(
          'err _fromYuv() planes[0].bytes.length=${image.planes[0].bytes.length}');
      return null;
    }

    try {
      imglib.Image img = imglib.Image(width: width, height: height);
      final int perRow = image.planes[1].bytesPerRow;
      final int perPixel = image.planes[1].bytesPerPixel!;

      // YUV -> RGB
      for (int ay = 0; ay < height; ay++) {
        for (int ax = 0; ax < width; ax++) {
          final int index = ax + (ay * width);
          final int uvIndex =
              perPixel * (ax / 2).floor() + perRow * (ay / 2).floor();
          final y = image.planes[0].bytes[index];
          final u = image.planes[1].bytes[uvIndex];
          final v = image.planes[2].bytes[uvIndex];
          int r = (y + v * 1436 / 1024 - 179).round().clamp(0, 255);
          int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91)
              .round()
              .clamp(0, 255);
          int b = (y + u * 1814 / 1024 - 227).round().clamp(0, 255);
          img.setPixelRgb(ax, ay, r, g, b);
        }
      }
      return img;
    } catch (e) {
      print("err _fromYuv() " + e.toString());
    }
    return null;
  }

  static imglib.Image _fromRgb(CameraImage image) {
    print('_fromRgb() planes.length=${image.planes.length}');
    final int width = image.width;
    final int height = image.height;

    imglib.Image img = imglib.Image(width: width, height: height);
    try {
      for (int ay = 0; ay < height; ay++) {
        for (int ax = 0; ax < width; ax++) {
          final int index = (ax + (ay * width)) * 4;

          int b = image.planes[0].bytes[index + 0];
          int g = image.planes[0].bytes[index + 1];
          int r = image.planes[0].bytes[index + 2];
          int a = image.planes[0].bytes[index + 3];

          img.setPixelRgb(ax, ay, r, g, b);
        }
      }
    } catch (e) {
      print("err _fromYuv() " + e.toString());
    }
    return img;
  }
}
