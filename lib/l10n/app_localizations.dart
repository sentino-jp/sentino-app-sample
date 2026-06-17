import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'Sentino'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get login;

  /// No description provided for @register.
  ///
  /// In zh, this message translates to:
  /// **'注册'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get logout;

  /// No description provided for @account.
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get account;

  /// No description provided for @password.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In zh, this message translates to:
  /// **'确认密码'**
  String get confirmPassword;

  /// No description provided for @enterAccount.
  ///
  /// In zh, this message translates to:
  /// **'请输入邮箱地址'**
  String get enterAccount;

  /// No description provided for @invalidEmail.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的邮箱地址'**
  String get invalidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In zh, this message translates to:
  /// **'请输入密码'**
  String get enterPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In zh, this message translates to:
  /// **'请输入新密码'**
  String get enterNewPassword;

  /// No description provided for @enterOldPassword.
  ///
  /// In zh, this message translates to:
  /// **'请输入旧密码'**
  String get enterOldPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In zh, this message translates to:
  /// **'请确认新密码'**
  String get confirmNewPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In zh, this message translates to:
  /// **'两次输入的密码不一致'**
  String get passwordMismatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In zh, this message translates to:
  /// **'密码长度不少于6位'**
  String get passwordTooShort;

  /// No description provided for @agreePrivacy.
  ///
  /// In zh, this message translates to:
  /// **'我已阅读并同意隐私协议和用户条款'**
  String get agreePrivacy;

  /// No description provided for @forgotPassword.
  ///
  /// In zh, this message translates to:
  /// **'忘记密码？'**
  String get forgotPassword;

  /// No description provided for @registerAccount.
  ///
  /// In zh, this message translates to:
  /// **'注册账号'**
  String get registerAccount;

  /// No description provided for @haveAccount.
  ///
  /// In zh, this message translates to:
  /// **'已有账号？去登录'**
  String get haveAccount;

  /// No description provided for @getVerifyCode.
  ///
  /// In zh, this message translates to:
  /// **'获取验证码'**
  String get getVerifyCode;

  /// No description provided for @enterVerifyCode.
  ///
  /// In zh, this message translates to:
  /// **'请输入验证码'**
  String get enterVerifyCode;

  /// No description provided for @verifyCodeSent.
  ///
  /// In zh, this message translates to:
  /// **'我们发送了6位验证码至{email}'**
  String verifyCodeSent(String email);

  /// No description provided for @resendCode.
  ///
  /// In zh, this message translates to:
  /// **'重新发送'**
  String get resendCode;

  /// No description provided for @resendCodeCountdown.
  ///
  /// In zh, this message translates to:
  /// **'重新发送 {seconds} 秒'**
  String resendCodeCountdown(int seconds);

  /// No description provided for @notReceivedCode.
  ///
  /// In zh, this message translates to:
  /// **'未收到验证码？'**
  String get notReceivedCode;

  /// No description provided for @notReceivedCodeTitle.
  ///
  /// In zh, this message translates to:
  /// **'未收到验证码'**
  String get notReceivedCodeTitle;

  /// No description provided for @notReceivedCodeHint.
  ///
  /// In zh, this message translates to:
  /// **'如果没有收到验证码，建议您先确认以下操作：\n\n1. 请您先核实App注册页面的国家/地区是否选择正确\n2. 请检查您的手机是否停机或者无网络\n3. 请检查您输入的手机/邮箱是否正确\n4. 请检查您的验证码是否被系统屏蔽或者隔离\n\n如果以上确认无误，或者无法收到校验码，可以发邮件至：'**
  String get notReceivedCodeHint;

  /// No description provided for @nextStep.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get nextStep;

  /// No description provided for @invalidVerifyCode.
  ///
  /// In zh, this message translates to:
  /// **'验证码无效，请重新输入'**
  String get invalidVerifyCode;

  /// No description provided for @resetPassword.
  ///
  /// In zh, this message translates to:
  /// **'重置密码'**
  String get resetPassword;

  /// No description provided for @resetSuccess.
  ///
  /// In zh, this message translates to:
  /// **'密码重置成功，请返回登录'**
  String get resetSuccess;

  /// No description provided for @changePassword.
  ///
  /// In zh, this message translates to:
  /// **'修改密码'**
  String get changePassword;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In zh, this message translates to:
  /// **'密码修改成功'**
  String get changePasswordSuccess;

  /// No description provided for @confirmChange.
  ///
  /// In zh, this message translates to:
  /// **'确认修改'**
  String get confirmChange;

  /// No description provided for @home.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get home;

  /// No description provided for @agent.
  ///
  /// In zh, this message translates to:
  /// **'智能体'**
  String get agent;

  /// No description provided for @device.
  ///
  /// In zh, this message translates to:
  /// **'设备'**
  String get device;

  /// No description provided for @mine.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get mine;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @accountSecurity.
  ///
  /// In zh, this message translates to:
  /// **'账号安全'**
  String get accountSecurity;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @themeSettings.
  ///
  /// In zh, this message translates to:
  /// **'主题设置'**
  String get themeSettings;

  /// No description provided for @lightMode.
  ///
  /// In zh, this message translates to:
  /// **'明亮模式'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In zh, this message translates to:
  /// **'暗黑模式'**
  String get darkMode;

  /// No description provided for @followSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get followSystem;

  /// No description provided for @languageSettings.
  ///
  /// In zh, this message translates to:
  /// **'语言设置'**
  String get languageSettings;

  /// No description provided for @deviceDetail.
  ///
  /// In zh, this message translates to:
  /// **'设备详情'**
  String get deviceDetail;

  /// No description provided for @firmwareVersion.
  ///
  /// In zh, this message translates to:
  /// **'固件版本'**
  String get firmwareVersion;

  /// No description provided for @macAddress.
  ///
  /// In zh, this message translates to:
  /// **'MAC 地址'**
  String get macAddress;

  /// No description provided for @networkType.
  ///
  /// In zh, this message translates to:
  /// **'网络类型'**
  String get networkType;

  /// No description provided for @signalStrength.
  ///
  /// In zh, this message translates to:
  /// **'信号强度'**
  String get signalStrength;

  /// No description provided for @deviceId.
  ///
  /// In zh, this message translates to:
  /// **'设备 ID'**
  String get deviceId;

  /// No description provided for @unbindDevice.
  ///
  /// In zh, this message translates to:
  /// **'解绑设备'**
  String get unbindDevice;

  /// No description provided for @unbindTitle.
  ///
  /// In zh, this message translates to:
  /// **'解绑设备'**
  String get unbindTitle;

  /// No description provided for @unbindMessage.
  ///
  /// In zh, this message translates to:
  /// **'请选择解绑方式'**
  String get unbindMessage;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @unbindOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅解绑'**
  String get unbindOnly;

  /// No description provided for @unbindAndClean.
  ///
  /// In zh, this message translates to:
  /// **'解绑并清除数据'**
  String get unbindAndClean;

  /// No description provided for @checkFirmware.
  ///
  /// In zh, this message translates to:
  /// **'检查固件升级'**
  String get checkFirmware;

  /// No description provided for @online.
  ///
  /// In zh, this message translates to:
  /// **'在线'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In zh, this message translates to:
  /// **'离线'**
  String get offline;

  /// No description provided for @deviceCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 台设备'**
  String deviceCount(int count);

  /// No description provided for @noDevice.
  ///
  /// In zh, this message translates to:
  /// **'暂无设备'**
  String get noDevice;

  /// No description provided for @addDeviceHint.
  ///
  /// In zh, this message translates to:
  /// **'点击右上角添加设备'**
  String get addDeviceHint;

  /// No description provided for @noDeviceAddFirst.
  ///
  /// In zh, this message translates to:
  /// **'暂无设备，请先配网添加'**
  String get noDeviceAddFirst;

  /// No description provided for @blePairing.
  ///
  /// In zh, this message translates to:
  /// **'蓝牙配网'**
  String get blePairing;

  /// No description provided for @fourgPairing.
  ///
  /// In zh, this message translates to:
  /// **'4G 配网'**
  String get fourgPairing;

  /// No description provided for @scanning.
  ///
  /// In zh, this message translates to:
  /// **'正在扫描附近的设备...'**
  String get scanning;

  /// No description provided for @foundDevices.
  ///
  /// In zh, this message translates to:
  /// **'发现 {count} 台设备'**
  String foundDevices(int count);

  /// No description provided for @moreDevices.
  ///
  /// In zh, this message translates to:
  /// **'更多设备'**
  String get moreDevices;

  /// No description provided for @sendingConfig.
  ///
  /// In zh, this message translates to:
  /// **'正在发送配网数据...'**
  String get sendingConfig;

  /// No description provided for @waitingBind.
  ///
  /// In zh, this message translates to:
  /// **'正在等待设备绑定...'**
  String get waitingBind;

  /// No description provided for @pairingSuccess.
  ///
  /// In zh, this message translates to:
  /// **'配网成功'**
  String get pairingSuccess;

  /// No description provided for @pairingFailed.
  ///
  /// In zh, this message translates to:
  /// **'配网失败'**
  String get pairingFailed;

  /// No description provided for @pairingInProgress.
  ///
  /// In zh, this message translates to:
  /// **'正在配网'**
  String get pairingInProgress;

  /// No description provided for @waitingDeviceBind.
  ///
  /// In zh, this message translates to:
  /// **'等待设备绑定'**
  String get waitingDeviceBind;

  /// No description provided for @deviceCloudConnected.
  ///
  /// In zh, this message translates to:
  /// **'已连上设备云'**
  String get deviceCloudConnected;

  /// No description provided for @finishPairing.
  ///
  /// In zh, this message translates to:
  /// **'完成配网'**
  String get finishPairing;

  /// No description provided for @noDeviceFound.
  ///
  /// In zh, this message translates to:
  /// **'未发现可配网设备'**
  String get noDeviceFound;

  /// No description provided for @rescan.
  ///
  /// In zh, this message translates to:
  /// **'重新扫描'**
  String get rescan;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @wifiConfig.
  ///
  /// In zh, this message translates to:
  /// **'WiFi 配置'**
  String get wifiConfig;

  /// No description provided for @enterWifiInfo.
  ///
  /// In zh, this message translates to:
  /// **'请输入 WiFi 信息'**
  String get enterWifiInfo;

  /// No description provided for @wifiName.
  ///
  /// In zh, this message translates to:
  /// **'WiFi 名称'**
  String get wifiName;

  /// No description provided for @wifiPassword.
  ///
  /// In zh, this message translates to:
  /// **'WiFi 密码'**
  String get wifiPassword;

  /// No description provided for @bleDirectConnect.
  ///
  /// In zh, this message translates to:
  /// **'蓝牙直连'**
  String get bleDirectConnect;

  /// No description provided for @nearbyWifi.
  ///
  /// In zh, this message translates to:
  /// **'附近的 WiFi'**
  String get nearbyWifi;

  /// No description provided for @noWifiFound.
  ///
  /// In zh, this message translates to:
  /// **'未发现 WiFi'**
  String get noWifiFound;

  /// No description provided for @savedWifi.
  ///
  /// In zh, this message translates to:
  /// **'上次使用'**
  String get savedWifi;

  /// No description provided for @startPairing.
  ///
  /// In zh, this message translates to:
  /// **'开始配网'**
  String get startPairing;

  /// No description provided for @enterBindCode.
  ///
  /// In zh, this message translates to:
  /// **'请输入设备绑定码'**
  String get enterBindCode;

  /// No description provided for @bindCodeHint.
  ///
  /// In zh, this message translates to:
  /// **'绑定码为设备显示或语音播报的5位数字'**
  String get bindCodeHint;

  /// No description provided for @enterFiveDigitCode.
  ///
  /// In zh, this message translates to:
  /// **'请输入5位绑定码'**
  String get enterFiveDigitCode;

  /// No description provided for @bindCodeError.
  ///
  /// In zh, this message translates to:
  /// **'请输入5位纯数字绑定码'**
  String get bindCodeError;

  /// No description provided for @bindDevice.
  ///
  /// In zh, this message translates to:
  /// **'绑定设备'**
  String get bindDevice;

  /// No description provided for @bindSuccess.
  ///
  /// In zh, this message translates to:
  /// **'绑定成功'**
  String get bindSuccess;

  /// No description provided for @continueBind.
  ///
  /// In zh, this message translates to:
  /// **'继续绑定'**
  String get continueBind;

  /// No description provided for @recommendAgents.
  ///
  /// In zh, this message translates to:
  /// **'为我推荐'**
  String get recommendAgents;

  /// No description provided for @customAgents.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get customAgents;

  /// No description provided for @myAgents.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get myAgents;

  /// No description provided for @noAgent.
  ///
  /// In zh, this message translates to:
  /// **'暂无智能体'**
  String get noAgent;

  /// No description provided for @createCustomAgent.
  ///
  /// In zh, this message translates to:
  /// **'创建自定义智能体'**
  String get createCustomAgent;

  /// No description provided for @agentDetail.
  ///
  /// In zh, this message translates to:
  /// **'智能体详情'**
  String get agentDetail;

  /// No description provided for @bindToDevice.
  ///
  /// In zh, this message translates to:
  /// **'绑定到设备'**
  String get bindToDevice;

  /// No description provided for @bindToDeviceHint.
  ///
  /// In zh, this message translates to:
  /// **'请在设备详情页中选择绑定智能体'**
  String get bindToDeviceHint;

  /// No description provided for @createAgent.
  ///
  /// In zh, this message translates to:
  /// **'创建智能体'**
  String get createAgent;

  /// No description provided for @agentName.
  ///
  /// In zh, this message translates to:
  /// **'智能体名称'**
  String get agentName;

  /// No description provided for @agentDescription.
  ///
  /// In zh, this message translates to:
  /// **'描述（可选）'**
  String get agentDescription;

  /// No description provided for @advancedConfig.
  ///
  /// In zh, this message translates to:
  /// **'高级配置'**
  String get advancedConfig;

  /// No description provided for @advancedConfigHint.
  ///
  /// In zh, this message translates to:
  /// **'语言、音色等配置待接口对接后实现'**
  String get advancedConfigHint;

  /// No description provided for @create.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get create;

  /// No description provided for @firmwareUpgrade.
  ///
  /// In zh, this message translates to:
  /// **'固件升级'**
  String get firmwareUpgrade;

  /// No description provided for @checkingUpdate.
  ///
  /// In zh, this message translates to:
  /// **'正在检查固件更新...'**
  String get checkingUpdate;

  /// No description provided for @latestVersion.
  ///
  /// In zh, this message translates to:
  /// **'当前已是最新版本'**
  String get latestVersion;

  /// No description provided for @back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get back;

  /// No description provided for @newVersionFound.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本'**
  String get newVersionFound;

  /// No description provided for @versionNumber.
  ///
  /// In zh, this message translates to:
  /// **'版本号'**
  String get versionNumber;

  /// No description provided for @fileSize.
  ///
  /// In zh, this message translates to:
  /// **'文件大小'**
  String get fileSize;

  /// No description provided for @upgradeNotes.
  ///
  /// In zh, this message translates to:
  /// **'升级说明'**
  String get upgradeNotes;

  /// No description provided for @upgradeNow.
  ///
  /// In zh, this message translates to:
  /// **'立即升级'**
  String get upgradeNow;

  /// No description provided for @downloadingFirmware.
  ///
  /// In zh, this message translates to:
  /// **'正在下载固件...'**
  String get downloadingFirmware;

  /// No description provided for @flashingFirmware.
  ///
  /// In zh, this message translates to:
  /// **'正在烧录固件...'**
  String get flashingFirmware;

  /// No description provided for @doNotDisconnect.
  ///
  /// In zh, this message translates to:
  /// **'升级过程中请勿断开设备'**
  String get doNotDisconnect;

  /// No description provided for @upgradeSuccess.
  ///
  /// In zh, this message translates to:
  /// **'升级成功'**
  String get upgradeSuccess;

  /// No description provided for @upgradeFailed.
  ///
  /// In zh, this message translates to:
  /// **'升级失败'**
  String get upgradeFailed;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get loading;

  /// No description provided for @version.
  ///
  /// In zh, this message translates to:
  /// **'版本 {version}'**
  String version(String version);

  /// No description provided for @iotDeviceManagement.
  ///
  /// In zh, this message translates to:
  /// **'IoT 智能设备管理'**
  String get iotDeviceManagement;

  /// No description provided for @iotApp.
  ///
  /// In zh, this message translates to:
  /// **'IoT 智能设备管理应用'**
  String get iotApp;

  /// No description provided for @user.
  ///
  /// In zh, this message translates to:
  /// **'用户'**
  String get user;

  /// No description provided for @aboutAgPlay.
  ///
  /// In zh, this message translates to:
  /// **'关于 Sentino'**
  String get aboutAgPlay;

  /// No description provided for @myHome.
  ///
  /// In zh, this message translates to:
  /// **'我的家'**
  String get myHome;

  /// No description provided for @verifyCode.
  ///
  /// In zh, this message translates to:
  /// **'验证码'**
  String get verifyCode;

  /// No description provided for @barcode.
  ///
  /// In zh, this message translates to:
  /// **'条形码'**
  String get barcode;

  /// No description provided for @barcodeHint.
  ///
  /// In zh, this message translates to:
  /// **'条形码位于设备底部标签上'**
  String get barcodeHint;

  /// No description provided for @enterBarcode.
  ///
  /// In zh, this message translates to:
  /// **'请输入条形码'**
  String get enterBarcode;

  /// No description provided for @verifyCodePairing.
  ///
  /// In zh, this message translates to:
  /// **'验证码配网'**
  String get verifyCodePairing;

  /// No description provided for @barcodePairing.
  ///
  /// In zh, this message translates to:
  /// **'条形码配网'**
  String get barcodePairing;

  /// No description provided for @scanBarcode.
  ///
  /// In zh, this message translates to:
  /// **'扫描条形码'**
  String get scanBarcode;

  /// No description provided for @putBarcodeInFrame.
  ///
  /// In zh, this message translates to:
  /// **'将条形码放入框内自动扫描'**
  String get putBarcodeInFrame;

  /// No description provided for @connectingDevice.
  ///
  /// In zh, this message translates to:
  /// **'正在连接设备...'**
  String get connectingDevice;

  /// No description provided for @connectFailed.
  ///
  /// In zh, this message translates to:
  /// **'连接设备失败'**
  String get connectFailed;

  /// No description provided for @deviceNotSupport.
  ///
  /// In zh, this message translates to:
  /// **'设备不支持配网'**
  String get deviceNotSupport;

  /// No description provided for @sendPairingFailed.
  ///
  /// In zh, this message translates to:
  /// **'发送配网数据失败'**
  String get sendPairingFailed;

  /// No description provided for @bindTimeout.
  ///
  /// In zh, this message translates to:
  /// **'绑定超时，请重试'**
  String get bindTimeout;

  /// No description provided for @bluetoothNotAvailable.
  ///
  /// In zh, this message translates to:
  /// **'蓝牙不可用或未开启'**
  String get bluetoothNotAvailable;

  /// No description provided for @permissionRequired.
  ///
  /// In zh, this message translates to:
  /// **'需要权限'**
  String get permissionRequired;

  /// No description provided for @blePermissionHint.
  ///
  /// In zh, this message translates to:
  /// **'蓝牙配网需要蓝牙和位置权限，请在设置中开启'**
  String get blePermissionHint;

  /// No description provided for @goSettings.
  ///
  /// In zh, this message translates to:
  /// **'去设置'**
  String get goSettings;

  /// No description provided for @blePermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'蓝牙或位置权限未授权'**
  String get blePermissionDenied;

  /// No description provided for @loadingPanel.
  ///
  /// In zh, this message translates to:
  /// **'加载面板中...'**
  String get loadingPanel;

  /// No description provided for @noAgentData.
  ///
  /// In zh, this message translates to:
  /// **'无智能体数据'**
  String get noAgentData;

  /// No description provided for @modelLabel.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get modelLabel;

  /// No description provided for @languageLabel.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get languageLabel;

  /// No description provided for @voiceTone.
  ///
  /// In zh, this message translates to:
  /// **'音色'**
  String get voiceTone;

  /// No description provided for @feedback.
  ///
  /// In zh, this message translates to:
  /// **'问题反馈'**
  String get feedback;

  /// No description provided for @manualInput.
  ///
  /// In zh, this message translates to:
  /// **'手动输入'**
  String get manualInput;

  /// No description provided for @enterBarcodeManually.
  ///
  /// In zh, this message translates to:
  /// **'请输入条形码'**
  String get enterBarcodeManually;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'删除后无法恢复，确定要删除吗？'**
  String get deleteConfirmMessage;

  /// No description provided for @clearChatConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要清空对话历史吗？'**
  String get clearChatConfirm;

  /// No description provided for @clearCache.
  ///
  /// In zh, this message translates to:
  /// **'清理缓存'**
  String get clearCache;

  /// No description provided for @clearCacheSuccess.
  ///
  /// In zh, this message translates to:
  /// **'缓存已清理'**
  String get clearCacheSuccess;

  /// No description provided for @clearCacheConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要清理缓存吗？'**
  String get clearCacheConfirm;

  /// No description provided for @selectFromGallery.
  ///
  /// In zh, this message translates to:
  /// **'从相册选择'**
  String get selectFromGallery;

  /// No description provided for @flashlight.
  ///
  /// In zh, this message translates to:
  /// **'照明'**
  String get flashlight;

  /// No description provided for @devicePanel.
  ///
  /// In zh, this message translates to:
  /// **'设备面板'**
  String get devicePanel;

  /// No description provided for @enterChat.
  ///
  /// In zh, this message translates to:
  /// **'进入对话'**
  String get enterChat;

  /// No description provided for @switchRole.
  ///
  /// In zh, this message translates to:
  /// **'切换角色'**
  String get switchRole;

  /// No description provided for @roleMemory.
  ///
  /// In zh, this message translates to:
  /// **'角色记忆'**
  String get roleMemory;

  /// No description provided for @volume.
  ///
  /// In zh, this message translates to:
  /// **'音量'**
  String get volume;

  /// No description provided for @deviceInfo.
  ///
  /// In zh, this message translates to:
  /// **'设备信息'**
  String get deviceInfo;

  /// No description provided for @deviceSn.
  ///
  /// In zh, this message translates to:
  /// **'设备SN'**
  String get deviceSn;

  /// No description provided for @deviceTimezone.
  ///
  /// In zh, this message translates to:
  /// **'设备时区'**
  String get deviceTimezone;

  /// No description provided for @networkInfo.
  ///
  /// In zh, this message translates to:
  /// **'网络信息'**
  String get networkInfo;

  /// No description provided for @ipAddress.
  ///
  /// In zh, this message translates to:
  /// **'IP地址'**
  String get ipAddress;

  /// No description provided for @signalConnection.
  ///
  /// In zh, this message translates to:
  /// **'信号连接'**
  String get signalConnection;

  /// No description provided for @networkCheck.
  ///
  /// In zh, this message translates to:
  /// **'网络检测'**
  String get networkCheck;

  /// No description provided for @networkChecking.
  ///
  /// In zh, this message translates to:
  /// **'正在检测...'**
  String get networkChecking;

  /// No description provided for @signalGood.
  ///
  /// In zh, this message translates to:
  /// **'信号良好'**
  String get signalGood;

  /// No description provided for @signalMedium.
  ///
  /// In zh, this message translates to:
  /// **'信号一般'**
  String get signalMedium;

  /// No description provided for @signalBad.
  ///
  /// In zh, this message translates to:
  /// **'信号较差'**
  String get signalBad;

  /// No description provided for @signalCheckFail.
  ///
  /// In zh, this message translates to:
  /// **'检测失败'**
  String get signalCheckFail;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get copied;

  /// No description provided for @removeDevice.
  ///
  /// In zh, this message translates to:
  /// **'移除设备'**
  String get removeDevice;

  /// No description provided for @deviceUpgrade.
  ///
  /// In zh, this message translates to:
  /// **'设备升级'**
  String get deviceUpgrade;

  /// No description provided for @networkDetection.
  ///
  /// In zh, this message translates to:
  /// **'网络检测'**
  String get networkDetection;

  /// No description provided for @detecting.
  ///
  /// In zh, this message translates to:
  /// **'检测中...'**
  String get detecting;

  /// No description provided for @signalTimeout.
  ///
  /// In zh, this message translates to:
  /// **'检测超时'**
  String get signalTimeout;

  /// No description provided for @latestFirmware.
  ///
  /// In zh, this message translates to:
  /// **'已经是最新版本'**
  String get latestFirmware;

  /// No description provided for @roleName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get roleName;

  /// No description provided for @enterRoleName.
  ///
  /// In zh, this message translates to:
  /// **'请输入角色名称'**
  String get enterRoleName;

  /// No description provided for @roleIntro.
  ///
  /// In zh, this message translates to:
  /// **'角色介绍'**
  String get roleIntro;

  /// No description provided for @polish.
  ///
  /// In zh, this message translates to:
  /// **'润色'**
  String get polish;

  /// No description provided for @selectLanguageOption.
  ///
  /// In zh, this message translates to:
  /// **'请选择语种'**
  String get selectLanguageOption;

  /// No description provided for @editVoice.
  ///
  /// In zh, this message translates to:
  /// **'去编辑'**
  String get editVoice;

  /// No description provided for @selectModel.
  ///
  /// In zh, this message translates to:
  /// **'请选择模型'**
  String get selectModel;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @customRole.
  ///
  /// In zh, this message translates to:
  /// **'自定义角色'**
  String get customRole;

  /// No description provided for @editRole.
  ///
  /// In zh, this message translates to:
  /// **'编辑角色'**
  String get editRole;

  /// No description provided for @agentIdLabel.
  ///
  /// In zh, this message translates to:
  /// **'Agent ID'**
  String get agentIdLabel;

  /// No description provided for @enterAgentId.
  ///
  /// In zh, this message translates to:
  /// **'请输入 Agent ID'**
  String get enterAgentId;

  /// No description provided for @apiKeyLabel.
  ///
  /// In zh, this message translates to:
  /// **'API Key'**
  String get apiKeyLabel;

  /// No description provided for @enterApiKey.
  ///
  /// In zh, this message translates to:
  /// **'请输入 API Key'**
  String get enterApiKey;

  /// No description provided for @apiKeyEditHint.
  ///
  /// In zh, this message translates to:
  /// **'留空则不修改'**
  String get apiKeyEditHint;

  /// No description provided for @greetingMessageLabel.
  ///
  /// In zh, this message translates to:
  /// **'欢迎语'**
  String get greetingMessageLabel;

  /// No description provided for @enterGreetingMessage.
  ///
  /// In zh, this message translates to:
  /// **'请输入欢迎语'**
  String get enterGreetingMessage;

  /// No description provided for @editNickname.
  ///
  /// In zh, this message translates to:
  /// **'修改昵称'**
  String get editNickname;

  /// No description provided for @enterNickname.
  ///
  /// In zh, this message translates to:
  /// **'请输入昵称'**
  String get enterNickname;

  /// No description provided for @roleIntroExample.
  ///
  /// In zh, this message translates to:
  /// **'举例：你是一名天文学家，你有着丰富的知识储备...'**
  String get roleIntroExample;

  /// No description provided for @noQrCode.
  ///
  /// In zh, this message translates to:
  /// **'没有二维码，手动添加'**
  String get noQrCode;

  /// No description provided for @alignQrCode.
  ///
  /// In zh, this message translates to:
  /// **'对准二维码，即可自动扫描'**
  String get alignQrCode;

  /// No description provided for @privacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get privacyPolicy;

  /// No description provided for @userAgreement.
  ///
  /// In zh, this message translates to:
  /// **'用户协议'**
  String get userAgreement;

  /// No description provided for @agreePrivacyPrefix.
  ///
  /// In zh, this message translates to:
  /// **'我已阅读并同意'**
  String get agreePrivacyPrefix;

  /// No description provided for @and.
  ///
  /// In zh, this message translates to:
  /// **'和'**
  String get and;

  /// No description provided for @chatHistory.
  ///
  /// In zh, this message translates to:
  /// **'对话历史'**
  String get chatHistory;

  /// No description provided for @noConversation.
  ///
  /// In zh, this message translates to:
  /// **'暂无对话记录'**
  String get noConversation;

  /// No description provided for @you.
  ///
  /// In zh, this message translates to:
  /// **'你'**
  String get you;

  /// No description provided for @assistant.
  ///
  /// In zh, this message translates to:
  /// **'智能体'**
  String get assistant;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
