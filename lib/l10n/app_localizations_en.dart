// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sentino';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get logout => 'Logout';

  @override
  String get account => 'Account';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get enterAccount => 'Enter email address';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get enterNewPassword => 'Enter new password';

  @override
  String get enterOldPassword => 'Enter old password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get agreePrivacy =>
      'I have read and agree to the Privacy Policy and Terms';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get registerAccount => 'Register';

  @override
  String get haveAccount => 'Already have an account? Login';

  @override
  String get getVerifyCode => 'Get Code';

  @override
  String get enterVerifyCode => 'Enter verification code';

  @override
  String verifyCodeSent(String email) {
    return 'We sent a 6-digit code to $email';
  }

  @override
  String get resendCode => 'Resend';

  @override
  String resendCodeCountdown(int seconds) {
    return 'Resend ${seconds}s';
  }

  @override
  String get notReceivedCode => 'Didn\'t receive the code?';

  @override
  String get notReceivedCodeTitle => 'Didn\'t receive the code';

  @override
  String get notReceivedCodeHint =>
      'If you didn\'t receive the verification code, please check the following:\n\n1. Make sure the country/region is selected correctly\n2. Check if your phone has network access\n3. Verify the phone number/email you entered is correct\n4. Check if the code was blocked by your system\n\nIf the issue persists, please contact us at:';

  @override
  String get nextStep => 'Next';

  @override
  String get invalidVerifyCode => 'Invalid verification code, please try again';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetSuccess => 'Password reset successful, please login';

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordSuccess => 'Password changed successfully';

  @override
  String get confirmChange => 'Confirm';

  @override
  String get home => 'Home';

  @override
  String get agent => 'Agent';

  @override
  String get device => 'Device';

  @override
  String get mine => 'Me';

  @override
  String get settings => 'Settings';

  @override
  String get accountSecurity => 'Account Security';

  @override
  String get about => 'About';

  @override
  String get themeSettings => 'Theme';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get followSystem => 'Follow System';

  @override
  String get languageSettings => 'Language';

  @override
  String get deviceDetail => 'Device Detail';

  @override
  String get firmwareVersion => 'Firmware';

  @override
  String get macAddress => 'MAC Address';

  @override
  String get networkType => 'Network Type';

  @override
  String get signalStrength => 'Signal Strength';

  @override
  String get deviceId => 'Device ID';

  @override
  String get unbindDevice => 'Unbind Device';

  @override
  String get unbindTitle => 'Unbind Device';

  @override
  String get unbindMessage => 'Choose unbind method';

  @override
  String get cancel => 'Cancel';

  @override
  String get unbindOnly => 'Unbind Only';

  @override
  String get unbindAndClean => 'Unbind & Clear Data';

  @override
  String get checkFirmware => 'Check Firmware Update';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String deviceCount(int count) {
    return '$count devices';
  }

  @override
  String get noDevice => 'No devices';

  @override
  String get addDeviceHint => 'Tap top-right to add device';

  @override
  String get noDeviceAddFirst => 'No devices, please pair first';

  @override
  String get blePairing => 'BLE Pairing';

  @override
  String get fourgPairing => '4G Pairing';

  @override
  String get scanning => 'Scanning nearby devices...';

  @override
  String foundDevices(int count) {
    return 'Found $count devices';
  }

  @override
  String get moreDevices => 'More Devices';

  @override
  String get sendingConfig => 'Sending configuration...';

  @override
  String get waitingBind => 'Waiting for device binding...';

  @override
  String get pairingSuccess => 'Pairing successful';

  @override
  String get pairingFailed => 'Pairing failed';

  @override
  String get pairingInProgress => 'Pairing in progress';

  @override
  String get waitingDeviceBind => 'Waiting for device binding';

  @override
  String get deviceCloudConnected => 'Device connected to cloud';

  @override
  String get finishPairing => 'Finish Pairing';

  @override
  String get noDeviceFound => 'No devices found';

  @override
  String get rescan => 'Rescan';

  @override
  String get done => 'Done';

  @override
  String get wifiConfig => 'WiFi Configuration';

  @override
  String get enterWifiInfo => 'Enter WiFi information';

  @override
  String get wifiName => 'WiFi Name';

  @override
  String get wifiPassword => 'WiFi Password';

  @override
  String get bleDirectConnect => 'BLE Direct Connect';

  @override
  String get nearbyWifi => 'Nearby WiFi';

  @override
  String get noWifiFound => 'No WiFi found';

  @override
  String get savedWifi => 'Last used';

  @override
  String get startPairing => 'Start Pairing';

  @override
  String get enterBindCode => 'Enter device bind code';

  @override
  String get bindCodeHint =>
      'The bind code is a 5-digit number displayed or announced by the device';

  @override
  String get enterFiveDigitCode => 'Enter 5-digit code';

  @override
  String get bindCodeError => 'Please enter a 5-digit numeric code';

  @override
  String get bindDevice => 'Bind Device';

  @override
  String get bindSuccess => 'Bind successful';

  @override
  String get continueBind => 'Continue Binding';

  @override
  String get recommendAgents => 'Recommended';

  @override
  String get customAgents => 'Custom';

  @override
  String get myAgents => 'My Agents';

  @override
  String get noAgent => 'No agents';

  @override
  String get createCustomAgent => 'Create Custom Agent';

  @override
  String get agentDetail => 'Agent Detail';

  @override
  String get bindToDevice => 'Bind to Device';

  @override
  String get bindToDeviceHint =>
      'Please select bind agent in device detail page';

  @override
  String get createAgent => 'Create Agent';

  @override
  String get agentName => 'Agent Name';

  @override
  String get agentDescription => 'Description (optional)';

  @override
  String get advancedConfig => 'Advanced Config';

  @override
  String get advancedConfigHint =>
      'Language, voice config pending API integration';

  @override
  String get create => 'Create';

  @override
  String get firmwareUpgrade => 'Firmware Upgrade';

  @override
  String get checkingUpdate => 'Checking for updates...';

  @override
  String get latestVersion => 'Already up to date';

  @override
  String get back => 'Back';

  @override
  String get newVersionFound => 'New version available';

  @override
  String get versionNumber => 'Version';

  @override
  String get fileSize => 'File Size';

  @override
  String get upgradeNotes => 'Release Notes';

  @override
  String get upgradeNow => 'Upgrade Now';

  @override
  String get downloadingFirmware => 'Downloading firmware...';

  @override
  String get flashingFirmware => 'Flashing firmware...';

  @override
  String get doNotDisconnect => 'Do not disconnect during upgrade';

  @override
  String get upgradeSuccess => 'Upgrade successful';

  @override
  String get upgradeFailed => 'Upgrade failed';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get iotDeviceManagement => 'IoT Device Management';

  @override
  String get iotApp => 'IoT Smart Device Management App';

  @override
  String get user => 'User';

  @override
  String get aboutAgPlay => 'About Sentino';

  @override
  String get myHome => 'My Home';

  @override
  String get verifyCode => 'Verify Code';

  @override
  String get barcode => 'Barcode';

  @override
  String get barcodeHint => 'Barcode is on the bottom label of the device';

  @override
  String get enterBarcode => 'Enter barcode';

  @override
  String get verifyCodePairing => 'Verify Code Pairing';

  @override
  String get barcodePairing => 'Barcode Pairing';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get putBarcodeInFrame => 'Place barcode in frame to scan';

  @override
  String get connectingDevice => 'Connecting to device...';

  @override
  String get connectFailed => 'Failed to connect to device';

  @override
  String get deviceNotSupport => 'Device does not support pairing';

  @override
  String get sendPairingFailed => 'Failed to send pairing data';

  @override
  String get bindTimeout => 'Binding timeout, please try again';

  @override
  String get bluetoothNotAvailable =>
      'Bluetooth is not available or turned off';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get blePermissionHint =>
      'Bluetooth pairing requires Bluetooth and Location permissions. Please enable them in Settings.';

  @override
  String get goSettings => 'Go to Settings';

  @override
  String get blePermissionDenied => 'Bluetooth or Location permission denied';

  @override
  String get loadingPanel => 'Loading panel...';

  @override
  String get noAgentData => 'No agent data';

  @override
  String get modelLabel => 'Model';

  @override
  String get languageLabel => 'Language';

  @override
  String get voiceTone => 'Voice';

  @override
  String get feedback => 'Feedback';

  @override
  String get manualInput => 'Manual Input';

  @override
  String get enterBarcodeManually => 'Enter barcode';

  @override
  String get confirm => 'OK';

  @override
  String get delete => 'Delete';

  @override
  String get deleteConfirmTitle => 'Confirm Delete';

  @override
  String get deleteConfirmMessage => 'This cannot be undone. Are you sure?';

  @override
  String get clearChatConfirm => 'Clear all chat history?';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get clearCacheSuccess => 'Cache cleared';

  @override
  String get clearCacheConfirm => 'Are you sure you want to clear cache?';

  @override
  String get selectFromGallery => 'Gallery';

  @override
  String get flashlight => 'Flash';

  @override
  String get devicePanel => 'Device Panel';

  @override
  String get enterChat => 'Chat';

  @override
  String get switchRole => 'Switch Role';

  @override
  String get roleMemory => 'Role Memory';

  @override
  String get volume => 'Volume';

  @override
  String get deviceInfo => 'Device Info';

  @override
  String get deviceSn => 'Device SN';

  @override
  String get deviceTimezone => 'Device Timezone';

  @override
  String get networkInfo => 'Network Info';

  @override
  String get ipAddress => 'IP Address';

  @override
  String get signalConnection => 'Signal';

  @override
  String get networkCheck => 'Network Check';

  @override
  String get networkChecking => 'Checking...';

  @override
  String get signalGood => 'Good Signal';

  @override
  String get signalMedium => 'Medium Signal';

  @override
  String get signalBad => 'Poor Signal';

  @override
  String get signalCheckFail => 'Check Failed';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get removeDevice => 'Remove Device';

  @override
  String get deviceUpgrade => 'Device Upgrade';

  @override
  String get networkDetection => 'Network Detection';

  @override
  String get detecting => 'Detecting...';

  @override
  String get signalTimeout => 'Detection Timeout';

  @override
  String get latestFirmware => 'Already up to date';

  @override
  String get roleName => 'Name';

  @override
  String get enterRoleName => 'Enter role name';

  @override
  String get roleIntro => 'Role Introduction';

  @override
  String get polish => 'Polish';

  @override
  String get selectLanguageOption => 'Select language';

  @override
  String get editVoice => 'Edit';

  @override
  String get selectModel => 'Select model';

  @override
  String get save => 'Save';

  @override
  String get customRole => 'Custom Role';

  @override
  String get editRole => 'Edit Role';

  @override
  String get agentIdLabel => 'Agent ID';

  @override
  String get enterAgentId => 'Enter Agent ID';

  @override
  String get apiKeyLabel => 'API Key';

  @override
  String get enterApiKey => 'Enter API Key';

  @override
  String get apiKeyEditHint => 'Leave empty to keep unchanged';

  @override
  String get greetingMessageLabel => 'Greeting';

  @override
  String get enterGreetingMessage => 'Enter greeting message';

  @override
  String get editNickname => 'Edit Nickname';

  @override
  String get enterNickname => 'Enter nickname';

  @override
  String get roleIntroExample =>
      'Example: You are an astronomer with rich knowledge...';

  @override
  String get noQrCode => 'No QR code? Add manually';

  @override
  String get alignQrCode => 'Align QR code to scan automatically';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get userAgreement => 'User Agreement';

  @override
  String get agreePrivacyPrefix => 'I have read and agree to the';

  @override
  String get and => 'and';

  @override
  String get chatHistory => 'Chat History';

  @override
  String get noConversation => 'No conversation history';

  @override
  String get you => 'You';

  @override
  String get assistant => 'Assistant';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get agreePrivacyRequired =>
      'Please read and agree to the Terms and Privacy Policy first';
}
