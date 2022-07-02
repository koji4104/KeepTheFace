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
      'take_interval_sec': 'Photo interval sec',
      'take_interval_sec_desc': 'Shoot at intervals.',
      'ex_storage':'External storage',
      'ex_storage_desc':'External storage',
      'ex_save_num':'External storage max number',
      'ex_save_num_desc':'External storage max number',
      'save_num': 'In-App max number',
      'save_num_desc': 'If the save size is exceeded, the oldest one will be deleted.',
      'autostop_sec': 'Automatic stop (Hour)',
      'autostop_sec_desc': 'Taking is automatically stopped. The black screen is maintained even if it is stopped.',
      'camera_height': 'camera size',
      'camera_height_desc': 'Select camera size.',
      'precautions':'precautions\nStop when the app goes to the background. Requires 5GB free space. Requires 10% battery.',
    },
    'ja': {
      'settings_title': '設定',
      'photolist_title': 'アプリ内データ',
      'take_interval_sec': '撮影間隔（秒）',
      'take_interval_sec_desc': '写真の撮影間隔を選んでください。',
      'ex_storage':'外部ストレージ',
      'ex_storage_desc':'外部ストレージ',
      'ex_save_num':'外部ストレージ上限枚数',
      'ex_save_num_desc':'外部ストレージ上限枚数',
      'save_num': 'アプリ内データ上限枚数',
      'save_num_desc': 'アプリ内データが上限枚数を超えると古いものから削除します。削除したくないファイルはフォトライブラリに移動してください。',
      'autostop_sec': '自動停止（時間）',
      'autostop_sec_desc': '自動的に撮影を停止します。停止しても黒画面を維持します。バッテリー残量10%以下で自動停止します。',
      'camera_height': 'カメラサイズ',
      'camera_height_desc': 'カメラサイズを選んでください。',
      'precautions':'注意事項\nアプリがバックグラウンドになると停止します。本体空き容量5GB以上必要です。バッテリー残量10%以上必要です。',
    },
  };

  String text(String text) {
    String? s;
    try {
      if (locale.languageCode == "ja")
        s = _localizedValues["ja"]?[text];
      else
        s = _localizedValues["en"]?[text];
    } on Exception catch (e) {}
    return s!=null ? s : text;
  }
}

