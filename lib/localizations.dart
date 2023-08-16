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
      'photo_interval_sec': 'Photo interval',
      'photo_interval_sec_desc': 'Photo interval',
      'split_interval_sec': 'Audio split',
      'split_interval_sec_desc': 'Audio split time',
      'ex_storage': 'External storage',
      'ex_storage_desc': 'External storage',
      'ex_save_num': 'External storage max number',
      'ex_save_num_desc': 'External storage max number',
      'in_save_num': 'In-App max number',
      'in_save_num_desc':
          'Old data will be deleted when in-app data exceeds the max number. Please move the data you want to keep.',
      'autostop_sec': 'Automatic stop',
      'autostop_sec_desc':
          'Automatically stop shooting. It will stop when the remaining battery level is 10% or less. Stop when the app goes to background.',
      'camera_height': 'Camera size',
      'camera_height_desc': 'Select the camera size for the photo.',
      'saver_mode': 'Screen Saver',
      'saver_mode_desc':
          'ON: Stop button is displayed. \nBlack: It becomes a black screen after 6 seconds and can be canceled by tapping.',
      'precautions': 'precautions\nStop when the app goes to the background. Requires 10% battery.',
      'trial': 'trial',
      'trial_desc':
          'You can turn it on for 4 hours for free. You can turn it on again after 48 hours.',
      'Purchase': 'Purchase',
      'Purchase_desc': 'in preparation',
      'premium': 'premium',
      'premium_desc': 'Photo library and Google Drive will be available.',
      'save_files': 'Save to the phones photo library',
      'delete_files': 'Are you sure you want to delete?',
      'save_photo_app': 'Copy to Photos app (photo only)',
      'save_file_app': 'Copy to Files app',
      'save_gdrive': 'Copy to Google Drive',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'mode_photo': 'photo',
      'mode_audio': 'audio',
      'mode_photo_audio': 'photo audio',
      'not_login': 'Not Login',
      'login': 'Login',
      'logout': 'Logout',
    },
    'ja': {
      'settings_title': '設定',
      'photolist_title': 'アプリ内データ',
      'take_mode': '撮影モード',
      'take_mode_desc': '写真：定期的に撮影します。\n録音：10分毎に分割されます。\nアプリがバックグラウンドになると停止します。',
      'photo_interval_sec': '写真間隔',
      'photo_interval_sec_desc': '写真の撮影間隔を選んでください。',
      'split_interval_sec': '録音の分割時間',
      'split_interval_sec_desc': '録音の分割時間を選んでください。',
      'ex_storage': '外部ストレージ',
      'ex_storage_desc': '外部ストレージ',
      'ex_save_num': '外部ストレージ上限数',
      'ex_save_num_desc': '外部ストレージ上限数',
      'in_save_num': 'アプリ内データ上限数',
      'in_save_num_desc': 'アプリ内データが上限数を超えると古いものから削除します。残したいデータは移動してください。',
      'autostop_sec': '自動停止',
      'autostop_sec_desc': '自動的に撮影を停止します。バッテリー残量10%以下で停止します。アプリがバックグラウンドになると停止します。',
      'camera_height': 'カメラサイズ',
      'camera_height_desc': '写真のカメラのサイズを選んでください。',
      'saver_mode': 'スクリーンセーバー',
      'saver_mode_desc': 'ON：停止ボタンが表示されます。\nBlack：6秒後に黒画面になりタップで解除できます。',
      'precautions': '注意事項\nアプリがバックグラウンドになると停止します。バッテリー残量10%以上必要です。',
      'trial': 'お試し',
      'trial_desc': '無料で4時間プレミアム機能をONにできます。48時間後に再度ONにできます。',
      'Purchase': '購入',
      'Purchase_desc': '準備中',
      'premium': 'プレミアム機能',
      'premium_desc': 'プレミアム機能をONにすると、本体のフォトライブラリとGoogleドライブが利用可能になります。',
      'save_files': '本体の写真ライブラリに保存します。\nよろしいですか？',
      'delete_files': '削除します。よろしいですか？',
      'save_photo_app': '写真アプリにコピー（写真のみ）',
      'save_file_app': 'ファイルアプリにコピー',
      'save_gdrive': 'Google Drive にコピー',
      'delete': '削除',
      'cancel': 'キャンセル',
      'mode_photo': '写真',
      'mode_audio': '録音',
      'mode_photo_audio': '写真と録音',
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
