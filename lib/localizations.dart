import 'package:flutter/material.dart';

class SampleLocalizationsDelegate extends LocalizationsDelegate<Localized> {
  const SampleLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['en','ja'].contains(locale.languageCode);
  @override
  Future<Localized> load(Locale locale) async => Localized(locale);
  @override
  bool shouldReload(SampleLocalizationsDelegate old) => false;
}

class Localized {
  Localized(this.locale);
  final Locale locale;

  static Localized of(BuildContext context) {
    return Localizations.of (context, Localized)!;
  }

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings_title': 'Settings',
      'photolist_title': 'In-app data',
      'take_interval_sec': 'Photo interval',
      'take_interval_sec_desc': 'Shoot at intervals.',
      'ex_storage':'External storage',
      'ex_storage_desc':'External storage',
      'ex_save_num':'External storage max number',
      'ex_save_num_desc':'External storage max number',
      'save_num': 'In-App max number',
      'save_num_desc': 'When the in-app data exceeds the upper limit, the oldest data will be deleted. Save the files you want to keep in the photo library.',
      'autostop_sec': 'Automatic stop',
      'autostop_sec_desc': 'Taking is automatically stopped. Automatically stops when the remaining battery level is 10% or less.',
      'camera_height': 'camera size',
      'camera_height_desc': 'Select camera size.',
      'precautions':'precautions\nStop when the app goes to the background. Requires 5GB free space. Requires 10% battery.',
      'trial':'trial',
      'trial_desc':'You can turn it on for 4 hours for free. You can turn it on again after 48 hours.',
      'Purchase':'Purchase',
      'Purchase_desc':'in preparation',
      'premium':'premium',
      'premium_desc':'Photo library and Google Drive will be available.',
      'save_files':'Save to the phones photo library',
      'delete_files':'Are you sure you want to delete?',
      'save':'Save',
      'delete':'Delete',
      'cancel':'Cancel',
    },
    'ja': {
      'settings_title': '設定',
      'photolist_title': 'アプリ内データ',
      'take_interval_sec': '撮影間隔',
      'take_interval_sec_desc': '写真の撮影間隔を選んでください。',
      'ex_storage':'外部ストレージ',
      'ex_storage_desc':'外部ストレージ',
      'ex_save_num':'外部ストレージ上限枚数',
      'ex_save_num_desc':'外部ストレージ上限数',
      'save_num': 'アプリ内データ上限数',
      'save_num_desc': 'アプリ内データが上限数を超えると古いものから削除します。残したいファイルはフォトライブラリに保存してください。',
      'autostop_sec': '自動停止',
      'autostop_sec_desc': '自動的に撮影を停止します。バッテリー残量10%以下で自動停止します。',
      'camera_height': 'カメラサイズ',
      'camera_height_desc': 'カメラのサイズを選んでください。',
      'precautions':'注意事項\nアプリがバックグラウンドになると停止します。本体空き容量5GB以上必要です。バッテリー残量10%以上必要です。',
      'trial':'お試し',
      'trial_desc':'無料で4時間プレミアム機能をONにできます。48時間後に再度ONにできます。',
      'Purchase':'購入',
      'Purchase_desc':'準備中',
      'premium':'プレミアム機能',
      'premium_desc':'プレミアム機能をONにすると、本体のフォトライブラリとGoogleドライブが利用可能になります。',
      'save_files':'本体の写真ライブラリに保存します。\nよろしいですか？',
      'delete_files':'削除します。\nよろしいですか？',
      'save':'保存',
      'delete':'削除',
      'cancel':'キャンセル',
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
    return s!=null ? s : text;
  }
}

