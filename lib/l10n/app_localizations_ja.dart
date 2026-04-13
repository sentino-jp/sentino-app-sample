// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Sentino';

  @override
  String get login => 'ログイン';

  @override
  String get register => '登録';

  @override
  String get logout => 'ログアウト';

  @override
  String get account => 'アカウント';

  @override
  String get password => 'パスワード';

  @override
  String get confirmPassword => 'パスワード確認';

  @override
  String get enterAccount => 'メールアドレスを入力';

  @override
  String get enterPassword => 'パスワードを入力';

  @override
  String get enterNewPassword => '新しいパスワードを入力';

  @override
  String get enterOldPassword => '現在のパスワードを入力';

  @override
  String get confirmNewPassword => '新しいパスワードを確認';

  @override
  String get passwordMismatch => 'パスワードが一致しません';

  @override
  String get passwordTooShort => 'パスワードは6文字以上必要です';

  @override
  String get agreePrivacy => 'プライバシーポリシーと利用規約に同意します';

  @override
  String get forgotPassword => 'パスワードを忘れた？';

  @override
  String get registerAccount => 'アカウント登録';

  @override
  String get haveAccount => 'アカウントをお持ちですか？ログイン';

  @override
  String get getVerifyCode => '認証コード取得';

  @override
  String get enterVerifyCode => '認証コードを入力';

  @override
  String get resetPassword => 'パスワードリセット';

  @override
  String get resetSuccess => 'パスワードリセット成功、ログインしてください';

  @override
  String get changePassword => 'パスワード変更';

  @override
  String get changePasswordSuccess => 'パスワード変更成功';

  @override
  String get confirmChange => '変更確認';

  @override
  String get home => 'ホーム';

  @override
  String get agent => 'エージェント';

  @override
  String get device => 'デバイス';

  @override
  String get mine => 'マイページ';

  @override
  String get settings => '設定';

  @override
  String get accountSecurity => 'アカウントセキュリティ';

  @override
  String get about => 'アプリについて';

  @override
  String get themeSettings => 'テーマ設定';

  @override
  String get lightMode => 'ライトモード';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get followSystem => 'システムに従う';

  @override
  String get languageSettings => '言語設定';

  @override
  String get deviceDetail => 'デバイス詳細';

  @override
  String get firmwareVersion => 'ファームウェア';

  @override
  String get macAddress => 'MACアドレス';

  @override
  String get networkType => 'ネットワーク種類';

  @override
  String get signalStrength => '信号強度';

  @override
  String get deviceId => 'デバイスID';

  @override
  String get unbindDevice => 'デバイス解除';

  @override
  String get unbindTitle => 'デバイス解除';

  @override
  String get unbindMessage => '解除方法を選択';

  @override
  String get cancel => 'キャンセル';

  @override
  String get unbindOnly => '解除のみ';

  @override
  String get unbindAndClean => '解除してデータ削除';

  @override
  String get checkFirmware => 'ファームウェア更新確認';

  @override
  String get online => 'オンライン';

  @override
  String get offline => 'オフライン';

  @override
  String deviceCount(int count) {
    return '$count 台のデバイス';
  }

  @override
  String get noDevice => 'デバイスなし';

  @override
  String get addDeviceHint => '右上をタップしてデバイスを追加';

  @override
  String get noDeviceAddFirst => 'デバイスなし、まずペアリングしてください';

  @override
  String get blePairing => 'Bluetoothペアリング';

  @override
  String get fourgPairing => '4Gペアリング';

  @override
  String get scanning => '近くのデバイスをスキャン中...';

  @override
  String foundDevices(int count) {
    return '$count 台のデバイスを発見';
  }

  @override
  String get moreDevices => 'その他のデバイス';

  @override
  String get sendingConfig => '設定データを送信中...';

  @override
  String get waitingBind => 'デバイスのバインドを待機中...';

  @override
  String get pairingSuccess => 'ペアリング成功';

  @override
  String get pairingFailed => 'ペアリング失敗';

  @override
  String get pairingInProgress => 'ペアリング中';

  @override
  String get waitingDeviceBind => 'デバイスバインド待機中';

  @override
  String get deviceCloudConnected => 'クラウドに接続済み';

  @override
  String get finishPairing => 'ペアリング完了';

  @override
  String get noDeviceFound => 'デバイスが見つかりません';

  @override
  String get rescan => '再スキャン';

  @override
  String get done => '完了';

  @override
  String get wifiConfig => 'WiFi設定';

  @override
  String get enterWifiInfo => 'WiFi情報を入力';

  @override
  String get wifiName => 'WiFi名';

  @override
  String get wifiPassword => 'WiFiパスワード';

  @override
  String get bleDirectConnect => 'Bluetooth直接接続';

  @override
  String get nearbyWifi => '近くのWiFi';

  @override
  String get noWifiFound => 'WiFiが見つかりません';

  @override
  String get savedWifi => '前回使用';

  @override
  String get startPairing => 'ペアリング開始';

  @override
  String get enterBindCode => 'デバイスバインドコードを入力';

  @override
  String get bindCodeHint => 'バインドコードはデバイスに表示または音声で通知される5桁の数字です';

  @override
  String get enterFiveDigitCode => '5桁のコードを入力';

  @override
  String get bindCodeError => '5桁の数字コードを入力してください';

  @override
  String get bindDevice => 'デバイスをバインド';

  @override
  String get bindSuccess => 'バインド成功';

  @override
  String get continueBind => 'バインドを続ける';

  @override
  String get recommendAgents => 'おすすめ';

  @override
  String get customAgents => 'カスタム';

  @override
  String get noAgent => 'エージェントなし';

  @override
  String get createCustomAgent => 'カスタムエージェント作成';

  @override
  String get agentDetail => 'エージェント詳細';

  @override
  String get bindToDevice => 'デバイスにバインド';

  @override
  String get bindToDeviceHint => 'デバイス詳細ページでエージェントをバインドしてください';

  @override
  String get createAgent => 'エージェント作成';

  @override
  String get agentName => 'エージェント名';

  @override
  String get agentDescription => '説明（任意）';

  @override
  String get advancedConfig => '詳細設定';

  @override
  String get advancedConfigHint => '言語、音声設定はAPI連携後に実装';

  @override
  String get create => '作成';

  @override
  String get firmwareUpgrade => 'ファームウェア更新';

  @override
  String get checkingUpdate => '更新を確認中...';

  @override
  String get latestVersion => '最新バージョンです';

  @override
  String get back => '戻る';

  @override
  String get newVersionFound => '新バージョンがあります';

  @override
  String get versionNumber => 'バージョン';

  @override
  String get fileSize => 'ファイルサイズ';

  @override
  String get upgradeNotes => '更新内容';

  @override
  String get upgradeNow => '今すぐ更新';

  @override
  String get downloadingFirmware => 'ファームウェアをダウンロード中...';

  @override
  String get flashingFirmware => 'ファームウェアを書き込み中...';

  @override
  String get doNotDisconnect => '更新中はデバイスを切断しないでください';

  @override
  String get upgradeSuccess => '更新成功';

  @override
  String get upgradeFailed => '更新失敗';

  @override
  String get retry => '再試行';

  @override
  String get loading => '読み込み中...';

  @override
  String version(String version) {
    return 'バージョン $version';
  }

  @override
  String get iotDeviceManagement => 'IoTデバイス管理';

  @override
  String get iotApp => 'IoTスマートデバイス管理アプリ';

  @override
  String get user => 'ユーザー';

  @override
  String get aboutAgPlay => 'Sentinoについて';

  @override
  String get myHome => 'マイホーム';

  @override
  String get verifyCode => '認証コード';

  @override
  String get barcode => 'バーコード';

  @override
  String get barcodeHint => 'バーコードはデバイス底面のラベルにあります';

  @override
  String get enterBarcode => 'バーコードを入力';

  @override
  String get verifyCodePairing => '認証コードペアリング';

  @override
  String get barcodePairing => 'バーコードペアリング';

  @override
  String get scanBarcode => 'バーコードをスキャン';

  @override
  String get putBarcodeInFrame => 'バーコードをフレーム内に配置してスキャン';

  @override
  String get connectingDevice => 'デバイスに接続中...';

  @override
  String get connectFailed => 'デバイスへの接続に失敗';

  @override
  String get deviceNotSupport => 'デバイスはペアリングをサポートしていません';

  @override
  String get sendPairingFailed => 'ペアリングデータの送信に失敗';

  @override
  String get bindTimeout => 'バインドタイムアウト、再試行してください';

  @override
  String get bluetoothNotAvailable => 'Bluetoothが利用できないか、オフです';

  @override
  String get permissionRequired => '権限が必要です';

  @override
  String get blePermissionHint =>
      'Bluetoothペアリングには、Bluetoothと位置情報の権限が必要です。設定で有効にしてください。';

  @override
  String get goSettings => '設定へ';

  @override
  String get blePermissionDenied => 'Bluetoothまたは位置情報の権限が拒否されました';

  @override
  String get loadingPanel => 'パネルを読み込み中...';

  @override
  String get noAgentData => 'エージェントデータなし';

  @override
  String get modelLabel => 'モデル';

  @override
  String get languageLabel => '言語';

  @override
  String get voiceTone => '音声';

  @override
  String get feedback => 'フィードバック';

  @override
  String get manualInput => '手動入力';

  @override
  String get enterBarcodeManually => 'バーコードを入力';

  @override
  String get confirm => '確認';

  @override
  String get delete => '削除';

  @override
  String get deleteConfirmTitle => '削除の確認';

  @override
  String get deleteConfirmMessage => '削除すると元に戻せません。本当に削除しますか？';

  @override
  String get clearChatConfirm => 'チャット履歴をすべて削除しますか？';

  @override
  String get clearCache => 'キャッシュクリア';

  @override
  String get clearCacheSuccess => 'キャッシュをクリアしました';

  @override
  String get clearCacheConfirm => 'キャッシュをクリアしますか？';

  @override
  String get selectFromGallery => 'ギャラリー';

  @override
  String get flashlight => 'ライト';

  @override
  String get devicePanel => 'デバイスパネル';

  @override
  String get enterChat => 'チャット';

  @override
  String get switchRole => 'ロール切替';

  @override
  String get roleMemory => 'ロール記憶';

  @override
  String get volume => '音量';

  @override
  String get deviceInfo => 'デバイス情報';

  @override
  String get deviceSn => 'デバイスSN';

  @override
  String get deviceTimezone => 'デバイスタイムゾーン';

  @override
  String get networkInfo => 'ネットワーク情報';

  @override
  String get ipAddress => 'IPアドレス';

  @override
  String get signalConnection => '信号';

  @override
  String get networkCheck => 'ネットワーク検出';

  @override
  String get networkChecking => '検出中...';

  @override
  String get signalGood => '良好';

  @override
  String get signalMedium => '普通';

  @override
  String get signalBad => '弱い';

  @override
  String get signalCheckFail => '検出失敗';

  @override
  String get copy => 'コピー';

  @override
  String get copied => 'コピーしました';

  @override
  String get removeDevice => 'デバイス削除';

  @override
  String get deviceUpgrade => 'デバイス更新';

  @override
  String get networkDetection => 'ネットワーク検出';

  @override
  String get detecting => '検出中...';

  @override
  String get signalTimeout => 'タイムアウト';

  @override
  String get latestFirmware => '最新バージョンです';

  @override
  String get roleName => '名前';

  @override
  String get enterRoleName => 'ロール名を入力';

  @override
  String get roleIntro => 'ロール紹介';

  @override
  String get polish => '推敲';

  @override
  String get selectLanguageOption => '言語を選択';

  @override
  String get editVoice => '編集';

  @override
  String get selectModel => 'モデルを選択';

  @override
  String get save => '保存';

  @override
  String get customRole => 'カスタムロール';

  @override
  String get editRole => 'ロール編集';

  @override
  String get editNickname => 'ニックネーム変更';

  @override
  String get enterNickname => 'ニックネームを入力';

  @override
  String get roleIntroExample => '例：あなたは天文学者で、豊富な知識を持っています...';

  @override
  String get noQrCode => 'QRコードがない場合、手動で追加';

  @override
  String get alignQrCode => 'QRコードを合わせると自動スキャン';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get userAgreement => '利用規約';

  @override
  String get agreePrivacyPrefix => '以下に同意します';

  @override
  String get and => 'と';

  @override
  String get chatHistory => 'チャット履歴';

  @override
  String get noConversation => '会話履歴なし';

  @override
  String get you => 'あなた';

  @override
  String get assistant => 'アシスタント';
}
