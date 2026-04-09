import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:uuid/uuid.dart';
import '../utils/app_config.dart';
import '../utils/mqtt_logger.dart';

/// MQTT service: connection, subscription and message dispatch
class MqttService {
  MqttServerClient? _client;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription? _updatesSub;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> connect(String userId) async {
    if (isConnected) return;
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final userName = '$userId|signMethod=hmacSha256,ts=$ts';
    final password = _hmacSha256('uuid=$userId,ts=$ts', AppConfig.appId);
    final clientId = 'app_$userId|${const Uuid().v4().replaceAll('-', '')}';

    AppMqttLogger.log('INIT', 'host=${AppConfig.mqttHost}:${AppConfig.mqttPort} user=$userName clientId=$clientId appId=${AppConfig.appId}');
    debugPrint('[MQTT] Connecting to ${AppConfig.mqttHost}:${AppConfig.mqttPort}');
    _client = MqttServerClient.withPort(AppConfig.mqttHost, clientId, AppConfig.mqttPort);
    _client!.keepAlivePeriod = 45;
    _client!.autoReconnect = true;
    _client!.logging(on: false);
    _client!.onConnected = () {
      debugPrint('[MQTT] Connected');
      AppMqttLogger.log('CONNECT', 'Connected to ${AppConfig.mqttHost}:${AppConfig.mqttPort}');
      _setupMessageListener();
      _resubscribe();
    };
    _client!.onDisconnected = () {
      debugPrint('[MQTT] Disconnected');
      AppMqttLogger.log('DISCONNECT', 'Disconnected');
    };
    _client!.onAutoReconnect = () {
      debugPrint('[MQTT] Auto reconnecting...');
      AppMqttLogger.log('RECONNECT', 'Reconnecting');
    };
    _client!.onAutoReconnected = () {
      debugPrint('[MQTT] Auto reconnected');
      AppMqttLogger.log('RECONNECT', 'Reconnected');
      _setupMessageListener();
      _resubscribe();
    };
    _client!.onSubscribed = (String topic) {
      debugPrint('[MQTT] Subscribed: $topic');
      AppMqttLogger.log('SUBSCRIBE', topic);
    };
    final connMsg = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(userName, password)
        .startClean();
    _client!.connectionMessage = connMsg;
    try {
      final status = await _client!.connect();
      debugPrint('[MQTT] Status: ${status?.state}');
      AppMqttLogger.log('STATUS', '${status?.state}');
    } catch (e) {
      debugPrint('[MQTT] Error: $e');
      AppMqttLogger.log('ERROR', '$e');
      _client?.disconnect();
    }
  }

  void _setupMessageListener() {
    _updatesSub?.cancel();
    _updatesSub = _client?.updates?.listen((List<MqttReceivedMessage<MqttMessage>> msgs) {
      for (final msg in msgs) {
        final pubMsg = msg.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(pubMsg.payload.message);
        debugPrint('[MQTT] ${msg.topic}: $payload');
        AppMqttLogger.log('MSG', '${msg.topic}: $payload');
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _messageController.add(data);
        } catch (e) {
          debugPrint('[MQTT] Parse error: $e');
        }
      }
    });
  }

  final List<String> _subscribedTopics = [];

  void subscribeAsset(String assetId) => _subscribe('app/v2/$assetId/notify');
  void subscribeUser(String userId) => _subscribe('app/v2/$userId/userNotify');

  void _subscribe(String topic) {
    if (!_subscribedTopics.contains(topic)) _subscribedTopics.add(topic);
    if (isConnected && _client != null) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
      debugPrint('[MQTT] Subscribing: $topic');
    } else {
      debugPrint('[MQTT] Queued: $topic');
    }
  }

  void _resubscribe() {
    if (_client == null || !isConnected) return;
    for (final topic in _subscribedTopics) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
    }
  }

  void disconnect() {
    _subscribedTopics.clear();
    _updatesSub?.cancel();
    _client?.disconnect();
    _client = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }

  String _hmacSha256(String content, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(content);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }
}
