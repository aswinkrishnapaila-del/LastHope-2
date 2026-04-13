import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class ConnectivityService {
  // NEW (Railway Production)
  // Note: We use 'wss://' (Secure WebSocket) because Railway uses HTTPS.
  static const String serverUrl =
      'wss://web-production-9c601.up.railway.app/ws/emergency';

  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _isConnected = false;

  ConnectivityService() {
    connect();
  }

  void connect() {
    if (_isConnected) return;

    try {
      debugPrint("Attempting to connect to $serverUrl");
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      _isConnected = true;
      _connectionStatusController.add(true);
      _cancelReconnectTimer();

      _channel!.stream.listen(
        (message) {
          debugPrint("Received: $message");
        },
        onDone: () {
          debugPrint("Connection closed");
          _isConnected = false;
          _connectionStatusController.add(false);
          _scheduleReconnect();
        },
        onError: (error) {
          debugPrint("Connection error: $error");
          _isConnected = false;
          _connectionStatusController.add(false);
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint("Connection failed: $e");
      _isConnected = false;
      _connectionStatusController.add(false);
      _scheduleReconnect();
    }
  }

  void sendPing() {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(
        jsonEncode({
          "type": "PING",
          "timestamp": DateTime.now().toIso8601String(),
        }),
      );
      debugPrint("PING Sent");
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;

    debugPrint("Scheduling reconnect in 2 seconds...");
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      connect();
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void sendSos(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      final jsonPayload = jsonEncode(data);
      _channel!.sink.add(jsonPayload);
      debugPrint("SOS Sent: $jsonPayload");
    } else {
      debugPrint(
        "Cannot send SOS: Disconnected. Queuing not implemented in this MVP.",
      );
    }
  }

  void dispose() {
    _cancelReconnectTimer();
    _channel?.sink.close(status.goingAway);
  }
}
