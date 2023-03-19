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
      'take_mode_desc': 'Please select a shooting mode.',
      'photo_interval_sec': 'Photo interval',
      'photo_interval_sec_desc': 'Photo interval',
      'split_interval_sec': 'Video audio split',
      'split_interval_sec_desc': 'video and audio split time',
      'ex_storage': 'External storage',
      'ex_storage_desc': 'External storage',
      'ex_save_num': 'External storage max number',
      'ex_save_num_desc': 'External storage max number',
      'save_num': 'In-App max number',
      'save_num_desc':
          'When the in-app data exceeds the upper limit, the oldest data will be deleted. Save the files you want to keep in the photo library.',
      'autostop_sec': 'Automatic stop',
      'autostop_sec_desc':
          'Taking is automatically stopped. Automatically stops when the remaining battery level is 10% or less.',
      'camera_height': 'Camera size',
      'camera_height_desc': 'Select camera size.',
      'saver_mode': 'Screen Saver',
      'saver_mode_desc':
          'Black will turn into a black screen after 6 seconds, and tap to cancel.',
      'precautions':
          'precautions\nStop when the app goes to the background. Requires 5GB free space. Requires 10% battery.',
      'trial': 'trial',
      'trial_desc':
          'You can turn it on for 4 hours for free. You can turn it on again after 48 hours.',
      'Purchase': 'Purchase',
      'Purchase_desc': 'in preparation',
      'premium': 'premium',
      'premium_desc': 'Photo library and Google Drive will be available.',
      'save_files': 'Save to the phones photo library',
      'delete_files': 'Are you sure you want to delete?',
      'save_photo_app': 'Copy to Photos app\nVideo and photo only',
      'save_file_app': 'Copy to Files app\nUp to 5 at a time',
      'save_gdrive': 'Copy to Google Drive',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'photo': 'Photo',
      'audio': 'Audio',
      'photo_audio': 'Photo Audio',
      'video': 'Video',
      'not_login': 'Not Login',
      'login': 'Login',
      'logout': 'Logout',
    },
    'ja': {
      'settings_title': '設定',
      'photolist_title': 'アプリ内データ',
      'take_mode': '撮影モード',
      'take_mode_desc': '撮影モードを選んでください。',
      'photo_interval_sec': '写真間隔',
      'photo_interval_sec_desc': '写真の撮影間隔を選んでください。',
      'split_interval_sec': 'ビデオと音声の分割',
      'split_interval_sec_desc': 'ビデオと音声の分割時間を選んでください。',
      'ex_storage': '外部ストレージ',
      'ex_storage_desc': '外部ストレージ',
      'ex_save_num': '外部ストレージ上限数',
      'ex_save_num_desc': '外部ストレージ上限数',
      'save_num': 'アプリ内データ保存数',
      'save_num_desc':
          'アプリ内データが保存数を超えると古いものから削除されます。残したいデータはアプリ内データからコピーしてください。本体の空き容量が5GB以下のとき保存されません。',
      'autostop_sec': '自動停止',
      'autostop_sec_desc': '自動的に撮影を停止します。バッテリー残量10%以下でも自動的に停止します。',
      'camera_height': 'カメラサイズ',
      'camera_height_desc': 'カメラのサイズを選んでください。',
      'saver_mode': 'スクリーンセーバー',
      'saver_mode_desc': 'Black は6秒後に黒画面になります。タップすると解除できます。',
      'precautions':
          '注意事項\nアプリがバックグラウンドになると停止します。本体空き容量5GB以上必要です。バッテリー残量10%以上必要です。',
      'trial': 'お試し',
      'trial_desc': '無料で4時間プレミアム機能をONにできます。48時間後に再度ONにできます。',
      'Purchase': '購入',
      'Purchase_desc': '準備中',
      'premium': 'プレミアム機能',
      'premium_desc': 'プレミアム機能をONにすると、本体のフォトライブラリとGoogleドライブが利用可能になります。',
      'save_files': '本体の写真ライブラリに保存します。\nよろしいですか？',
      'delete_files': '削除します。よろしいですか？',
      'save_photo_app': '写真アプリにコピー\n写真とビデオのみ',
      'save_file_app': 'ファイルアプリにコピー\n一度に5個まで',
      'save_gdrive': 'Google Drive にコピー',
      'delete': '削除',
      'cancel': 'キャンセル',
      'photo': '写真',
      'audio': '音声',
      'photo_audio': '写真 音声',
      'video': 'ビデオ',
      'not_login': 'ログインしていません',
      'login': 'ログイン',
      'logout': 'ログアウト',
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
