// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Sentino';

  @override
  String get login => '登录';

  @override
  String get register => '注册';

  @override
  String get logout => '退出登录';

  @override
  String get account => '账号';

  @override
  String get password => '密码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get enterAccount => '请输入账号';

  @override
  String get enterPassword => '请输入密码';

  @override
  String get enterNewPassword => '请输入新密码';

  @override
  String get enterOldPassword => '请输入旧密码';

  @override
  String get confirmNewPassword => '请确认新密码';

  @override
  String get passwordMismatch => '两次输入的密码不一致';

  @override
  String get passwordTooShort => '密码长度不少于6位';

  @override
  String get agreePrivacy => '我已阅读并同意隐私协议和用户条款';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get registerAccount => '注册账号';

  @override
  String get haveAccount => '已有账号？去登录';

  @override
  String get getVerifyCode => '获取验证码';

  @override
  String get enterVerifyCode => '请输入验证码';

  @override
  String get resetPassword => '重置密码';

  @override
  String get resetSuccess => '密码重置成功，请返回登录';

  @override
  String get changePassword => '修改密码';

  @override
  String get changePasswordSuccess => '密码修改成功';

  @override
  String get confirmChange => '确认修改';

  @override
  String get home => '首页';

  @override
  String get agent => '智能体';

  @override
  String get device => '设备';

  @override
  String get mine => '我的';

  @override
  String get settings => '设置';

  @override
  String get accountSecurity => '账号安全';

  @override
  String get about => '关于';

  @override
  String get themeSettings => '主题设置';

  @override
  String get lightMode => '明亮模式';

  @override
  String get darkMode => '暗黑模式';

  @override
  String get followSystem => '跟随系统';

  @override
  String get languageSettings => '语言设置';

  @override
  String get deviceDetail => '设备详情';

  @override
  String get firmwareVersion => '固件版本';

  @override
  String get macAddress => 'MAC 地址';

  @override
  String get networkType => '网络类型';

  @override
  String get signalStrength => '信号强度';

  @override
  String get deviceId => '设备 ID';

  @override
  String get unbindDevice => '解绑设备';

  @override
  String get unbindTitle => '解绑设备';

  @override
  String get unbindMessage => '请选择解绑方式';

  @override
  String get cancel => '取消';

  @override
  String get unbindOnly => '仅解绑';

  @override
  String get unbindAndClean => '解绑并清除数据';

  @override
  String get checkFirmware => '检查固件升级';

  @override
  String get online => '在线';

  @override
  String get offline => '离线';

  @override
  String deviceCount(int count) {
    return '$count 台设备';
  }

  @override
  String get noDevice => '暂无设备';

  @override
  String get addDeviceHint => '点击右上角添加设备';

  @override
  String get noDeviceAddFirst => '暂无设备，请先配网添加';

  @override
  String get blePairing => '蓝牙配网';

  @override
  String get fourgPairing => '4G 配网';

  @override
  String get scanning => '正在扫描附近的设备...';

  @override
  String foundDevices(int count) {
    return '发现 $count 台设备';
  }

  @override
  String get moreDevices => '更多设备';

  @override
  String get sendingConfig => '正在发送配网数据...';

  @override
  String get waitingBind => '正在等待设备绑定...';

  @override
  String get pairingSuccess => '配网成功';

  @override
  String get pairingFailed => '配网失败';

  @override
  String get pairingInProgress => '正在配网';

  @override
  String get waitingDeviceBind => '等待设备绑定';

  @override
  String get deviceCloudConnected => '已连上设备云';

  @override
  String get finishPairing => '完成配网';

  @override
  String get noDeviceFound => '未发现可配网设备';

  @override
  String get rescan => '重新扫描';

  @override
  String get done => '完成';

  @override
  String get wifiConfig => 'WiFi 配置';

  @override
  String get enterWifiInfo => '请输入 WiFi 信息';

  @override
  String get wifiName => 'WiFi 名称';

  @override
  String get wifiPassword => 'WiFi 密码';

  @override
  String get bleDirectConnect => '蓝牙直连';

  @override
  String get nearbyWifi => '附近的 WiFi';

  @override
  String get noWifiFound => '未发现 WiFi';

  @override
  String get savedWifi => '上次使用';

  @override
  String get startPairing => '开始配网';

  @override
  String get enterBindCode => '请输入设备绑定码';

  @override
  String get bindCodeHint => '绑定码为设备显示或语音播报的5位数字';

  @override
  String get enterFiveDigitCode => '请输入5位绑定码';

  @override
  String get bindCodeError => '请输入5位纯数字绑定码';

  @override
  String get bindDevice => '绑定设备';

  @override
  String get bindSuccess => '绑定成功';

  @override
  String get continueBind => '继续绑定';

  @override
  String get recommendAgents => '为我推荐';

  @override
  String get customAgents => '自定义';

  @override
  String get noAgent => '暂无智能体';

  @override
  String get createCustomAgent => '创建自定义智能体';

  @override
  String get agentDetail => '智能体详情';

  @override
  String get bindToDevice => '绑定到设备';

  @override
  String get bindToDeviceHint => '请在设备详情页中选择绑定智能体';

  @override
  String get createAgent => '创建智能体';

  @override
  String get agentName => '智能体名称';

  @override
  String get agentDescription => '描述（可选）';

  @override
  String get advancedConfig => '高级配置';

  @override
  String get advancedConfigHint => '语言、音色等配置待接口对接后实现';

  @override
  String get create => '创建';

  @override
  String get firmwareUpgrade => '固件升级';

  @override
  String get checkingUpdate => '正在检查固件更新...';

  @override
  String get latestVersion => '当前已是最新版本';

  @override
  String get back => '返回';

  @override
  String get newVersionFound => '发现新版本';

  @override
  String get versionNumber => '版本号';

  @override
  String get fileSize => '文件大小';

  @override
  String get upgradeNotes => '升级说明';

  @override
  String get upgradeNow => '立即升级';

  @override
  String get downloadingFirmware => '正在下载固件...';

  @override
  String get flashingFirmware => '正在烧录固件...';

  @override
  String get doNotDisconnect => '升级过程中请勿断开设备';

  @override
  String get upgradeSuccess => '升级成功';

  @override
  String get upgradeFailed => '升级失败';

  @override
  String get retry => '重试';

  @override
  String get loading => '加载中...';

  @override
  String version(String version) {
    return '版本 $version';
  }

  @override
  String get iotDeviceManagement => 'IoT 智能设备管理';

  @override
  String get iotApp => 'IoT 智能设备管理应用';

  @override
  String get user => '用户';

  @override
  String get aboutAgPlay => '关于 Sentino';

  @override
  String get myHome => '我的家';

  @override
  String get verifyCode => '验证码';

  @override
  String get barcode => '条形码';

  @override
  String get barcodeHint => '条形码位于设备底部标签上';

  @override
  String get enterBarcode => '请输入条形码';

  @override
  String get verifyCodePairing => '验证码配网';

  @override
  String get barcodePairing => '条形码配网';

  @override
  String get scanBarcode => '扫描条形码';

  @override
  String get putBarcodeInFrame => '将条形码放入框内自动扫描';

  @override
  String get connectingDevice => '正在连接设备...';

  @override
  String get connectFailed => '连接设备失败';

  @override
  String get deviceNotSupport => '设备不支持配网';

  @override
  String get sendPairingFailed => '发送配网数据失败';

  @override
  String get bindTimeout => '绑定超时，请重试';

  @override
  String get bluetoothNotAvailable => '蓝牙不可用或未开启';

  @override
  String get permissionRequired => '需要权限';

  @override
  String get blePermissionHint => '蓝牙配网需要蓝牙和位置权限，请在设置中开启';

  @override
  String get goSettings => '去设置';

  @override
  String get blePermissionDenied => '蓝牙或位置权限未授权';

  @override
  String get loadingPanel => '加载面板中...';

  @override
  String get noAgentData => '无智能体数据';

  @override
  String get modelLabel => '模型';

  @override
  String get languageLabel => '语言';

  @override
  String get voiceTone => '音色';

  @override
  String get feedback => '问题反馈';

  @override
  String get manualInput => '手动输入';

  @override
  String get enterBarcodeManually => '请输入条形码';

  @override
  String get confirm => '确定';

  @override
  String get delete => '删除';

  @override
  String get deleteConfirmTitle => '确认删除';

  @override
  String get deleteConfirmMessage => '删除后无法恢复，确定要删除吗？';

  @override
  String get clearChatConfirm => '确定要清空对话历史吗？';

  @override
  String get clearCache => '清理缓存';

  @override
  String get clearCacheSuccess => '缓存已清理';

  @override
  String get clearCacheConfirm => '确定要清理缓存吗？';

  @override
  String get selectFromGallery => '从相册选择';

  @override
  String get flashlight => '照明';

  @override
  String get devicePanel => '设备面板';

  @override
  String get enterChat => '进入对话';

  @override
  String get switchRole => '切换角色';

  @override
  String get roleMemory => '角色记忆';

  @override
  String get volume => '音量';

  @override
  String get deviceInfo => '设备信息';

  @override
  String get deviceSn => '设备SN';

  @override
  String get deviceTimezone => '设备时区';

  @override
  String get networkInfo => '网络信息';

  @override
  String get ipAddress => 'IP地址';

  @override
  String get signalConnection => '信号连接';

  @override
  String get networkCheck => '网络检测';

  @override
  String get networkChecking => '正在检测...';

  @override
  String get signalGood => '信号良好';

  @override
  String get signalMedium => '信号一般';

  @override
  String get signalBad => '信号较差';

  @override
  String get signalCheckFail => '检测失败';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get removeDevice => '移除设备';

  @override
  String get deviceUpgrade => '设备升级';

  @override
  String get networkDetection => '网络检测';

  @override
  String get detecting => '检测中...';

  @override
  String get signalTimeout => '检测超时';

  @override
  String get latestFirmware => '已经是最新版本';

  @override
  String get roleName => '名称';

  @override
  String get enterRoleName => '请输入角色名称';

  @override
  String get roleIntro => '角色介绍';

  @override
  String get polish => '润色';

  @override
  String get selectLanguageOption => '请选择语种';

  @override
  String get editVoice => '去编辑';

  @override
  String get selectModel => '请选择模型';

  @override
  String get save => '保存';

  @override
  String get customRole => '自定义角色';

  @override
  String get editRole => '编辑角色';

  @override
  String get editNickname => '修改昵称';

  @override
  String get enterNickname => '请输入昵称';

  @override
  String get roleIntroExample => '举例：你是一名天文学家，你有着丰富的知识储备...';

  @override
  String get noQrCode => '没有二维码，手动添加';

  @override
  String get alignQrCode => '对准二维码，即可自动扫描';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get userAgreement => '用户协议';

  @override
  String get agreePrivacyPrefix => '我已阅读并同意';

  @override
  String get and => '和';

  @override
  String get chatHistory => '对话历史';

  @override
  String get noConversation => '暂无对话记录';

  @override
  String get you => '你';

  @override
  String get assistant => '智能体';
}
