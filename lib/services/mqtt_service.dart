import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:uuid/uuid.dart';
import '../utils/app_config.dart';

/// MQTT 服务：管理连接、订阅和消息分发
class MqttService {
  MqttServerClient? _client;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  /// 消息流，外部监听 MQTT 推送
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  bool get isConnected => _client?.connectionStatus?.state == MqttConnectionState.connected;

  /// 连接 MQTT
  Future<void> connect(String userId) async {
    if (isConnected) return;

    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final userName = '$userId|signMethod=hmacSha256,ts=$ts';
    final password = _hmacSha256('uuid=$userId,ts=$ts', AppConfig.appId);
    final clientId = 'app_$userId|${const Uuid().v4().replaceAll('-', '')}';

    _client = MqttServerClient(AppConfig.mqttHost, clientId);
    _client!.port = AppConfig.mqttPort;
    _client!.keepAlivePeriod = 45;
    _client!.autoReconnect = true;
    _client!.logging(on: false);

    _client!.onConnected = () => debugPrint('[MQTT] Connected');
    _client!.onDisconnected = () => debugPrint('[MQTT] Disconnected');
    _client!.onAutoReconnect = () => debugPrint('[MQTT] Auto reconnecting...');
    _client!.onAutoReconnected = () {
      debugPrint('[MQTT] Auto reconnected');
      _resubscribe();
    };

    _client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final msg in messages) {
        final pubMsg = msg.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(pubMsg.payload.message);
        debugPrint('[MQTT] ${msg.topic}: $payload');
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _messageController.add(data);
        } catch (e) {
          debugPrint('[MQTT] Parse error: $e');
        }
      }
    });

    final connMsg = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(userName, password)
        .startClean();
    _client!.connectionMessage = connMsg;

    try {
      await _client!.connect();
      debugPrint('[MQTT] Connection status: ${_client!.connectionStatus}');
    } catch (e) {
      debugPrint('[MQTT] Connect error: $e');
      _client!.disconnect();
    }
  }

  final List<String> _subscribedTopics = [];

  /// 订阅 asset 通知 topic
  void subscribeAsset(String assetId) {
    final topic = 'app/v2/$assetId/notify';
    _subscribe(topic);
  }

  /// 订阅用户通知 topic
  void subscribeUser(String userId) {
    final topic = 'app/v2/$userId/userNotify';
    _subscribe(topic);
  }

  void _subscribe(String topic) {
    if (!_subscribedTopics.contains(topic)) {
      _subscribedTopics.add(topic);
    }
    if (isConnected) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
      debugPrint('[MQTT] Subscribed: $topic');
    }
  }

  void _resubscribe() {
    for (final topic in _subscribedTopics) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
      debugPrint('[MQTT] Resubscribed: $topic');
    }
  }

  /// 断开连接
  void disconnect() {
    _subscribedTopics.clear();
    _client?.disconnect();
    _client = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }

  /// HMAC-SHA256 签名
  String _hmacSha256(String content, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(content);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }
}
