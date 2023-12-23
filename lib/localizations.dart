import 'package:flutter/material.dart';

class SampleLocalizationsDelegate extends LocalizationsDelegate<Localized> {
  const SampleLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['en', 'ja'].contains(locale.languageCode);
  @override
  Future<Localized> load(Locale locale) async => Localized(locale);
  @override
  bool shouldReload(SampleLocalizationsDelegate old) => false;
}

class Localized {
  Localized(this.locale);
  final Locale locale;

  static Localized of(BuildContext context) {
    return Localizations.of(context, Localized)!;
  }

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings_title': 'Settings',
      'photolist_title': 'In-app data',
      'take_mode': 'Mode',
      'take_mode_desc':
          'Photo: Take pictures regularly. \nAudio: Divide every 10 minutes. \nStop when the app goes to background',
      'image_interval_sec': 'Photo interval',
      'image_interval_sec_desc': 'Photo interval',
      'ex_storage_type': 'External storage',
      'ex_storage_type_desc': 'External storage',
      'ex_save_mb': 'External storage max size',
      'ex_save_mb_desc': 'If the external storage limit is exceeded, data will not be saved. Please delete it.',
      'in_save_mb': 'In-App max size',
      'in_save_mb_desc': 'Old data will be deleted when in-app data exceeds the max size.',
      'timer_mode': 'Automatic stop',
      'timer_mode_desc':
          'Automatically stop shooting. It will stop when the remaining battery level is 10% or less. Stop when the app goes to background.',
      'timer_stop_sec': 'Autostop sec',
      'timer_stop_sec_desc': 'Autostop sec',
      'image_camera_height': 'Photo camera size',
      'image_camera_height_desc': 'Select the camera size for the photo.',
      'video_camera_height': 'Video camera size',
      'video_camera_height_desc': 'Select the camera size for the video.',
      'screensaver_mode': 'Screen Saver',
      'screensaver_mode_desc':
          'ON: Stop button is displayed. \nBlack: It becomes a black screen after 8 seconds and can be canceled by tapping.',
      'precautions': 'precautions\nStop when the app goes to the background. Requires 10% battery.',
      'trial': 'trial',
      'trial_desc': 'You can turn it on for 4 hours for free. You can turn it on again after 48 hours.',
      'Purchase': 'Purchase',
      'Purchase_desc': 'in preparation',
      'premium': 'premium',
      'premium_desc': 'Photo library and Google Drive will be available.',
      'save_files': 'Save to the phones photo library',
      'delete_files': 'Are you sure you want to delete?',
      'save_photo_app': 'Copy to Photos app (photo, video)',
      'save_file_app': 'Copy to Files app',
      'save_gdrive': 'Copy to external storage',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'mode_image': 'photo',
      'mode_audio': 'audio',
      'mode_video': 'video',
      'not_login': 'Not Login',
      'google_login': 'Login Google',
      'google_logout': 'Logout Google',
      'gdrive_note': '''
If external storage is turned on, it will be saved to external storage and in-app data.
If the external storage maximum capacity (changeable) is exceeded, it will not be saved. Please delete it manually.
Even if saving to external storage fails, it will be saved to in-app data.
''',
    },
    'ja': {
      'settings_title': '設定',
      'photolist_title': 'アプリ内データ',
      'take_mode': '撮影モード',
      'take_mode_desc': '写真：定期的に撮影します。\nビデオ：10分毎に分割されます。\n録音：10分毎に分割されます。\nアプリがバックグラウンドになると停止します。',
      'image_interval_sec': '写真間隔',
      'image_interval_sec_desc': '写真の撮影間隔を選んでください。',
      'ex_storage_type': '外部ストレージ',
      'ex_storage_type_desc': '外部ストレージ',
      'ex_save_mb': '外部ストレージ一時容量',
      'ex_save_mb_desc': '一時フォルダ(Temp)が容量を超えると古いものが削除されます。',
      'in_save_mb': 'アプリ内データ最大容量',
      'in_save_mb_desc': 'アプリ内データが最大容量を超えると古いものが削除されます。',
      'timer_mode': '自動停止',
      'timer_mode_desc': '自動的に撮影を停止します。バッテリー残量10%以下で停止します。アプリがバックグラウンドになると停止します。',
      'timer_stop_sec': '自動停止時間',
      'timer_stop_sec_desc': '自動停止時間',
      'image_camera_height': '写真のカメラサイズ',
      'image_camera_height_desc': '写真のカメラのサイズを選んでください。',
      'video_camera_height': 'ビデオのカメラサイズ',
      'video_camera_height_desc': 'ビデオのカメラのサイズを選んでください。',
      'screensaver_mode': 'スクリーンセーバー',
      'screensaver_mode_desc': 'ON：停止ボタンが表示されます。\nBlack：8秒後に黒画面になりタップで解除できます。',
      'precautions': '注意事項\nアプリがバックグラウンドになると停止します。バッテリー残量10%以下で停止します。',
      'trial': 'お試し',
      'trial_desc': '無料で4時間プレミアム機能をONにできます。48時間後に再度ONにできます。',
      'Purchase': '購入',
      'Purchase_desc': '準備中',
      'premium': 'プレミアム機能',
      'premium_desc': 'プレミアム機能をONにすると、本体のフォトライブラリとGoogleドライブが利用可能になります。',
      'save_files': '本体の写真ライブラリに保存します。\nよろしいですか？',
      'delete_files': '削除します。よろしいですか？',
      'save_photo_app': '写真アプリにコピー（写真とビデオ）',
      'save_file_app': 'ファイルアプリにコピー',
      'save_gdrive': '外部ストレージにコピー',
      'delete': '削除',
      'cancel': 'キャンセル',
      'mode_image': '写真',
      'mode_audio': '録音',
      'mode_video': 'ビデオ',
      'not_login': 'ログインしていません',
      'google_login': 'Googleにログイン',
      'google_logout': 'Googleにログアウト',
      'gdrive_note': '''
外部ストレージが ON のとき外部ストレージとアプリ内データの両方に保存されます。
外部ストレージに保存がしてもアプリ内データには保存されます。
''',
    },
  };

  String text(String text) {
    String? s;
    try {
      if (locale.languageCode == "ja")
        s = _localizedValues["ja"]?[text];
      else
        s = _localizedValues["en"]?[text];
    } on Exception catch (e) {
      print('Localized.text() ${e.toString()}');
    }
    if (s == null && text.contains('_desc')) s = '';
    return s != null ? s : text;
  }
}
