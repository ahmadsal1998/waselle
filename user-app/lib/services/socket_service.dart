import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/api_service.dart';

class SocketService {
  static io.Socket? _socket;
  static final Map<String, List<void Function(dynamic)>> _queuedListeners = {};

  static io.Socket? get socket => _socket;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    if (_socket != null) {
      _socket!.auth = {'token': token};
      if (!_socket!.connected) {
        _socket!.connect();
      }
      return;
    }

    _socket = io.io(
      ApiService.socketUrl,
      <String, dynamic>{
        'transports': ['websocket', 'polling'], // Fallback to polling for Render free hosting
        'auth': {'token': token},
        'reconnection': true,
        'reconnectionAttempts': 10,
        'reconnectionDelay': 1000,
        'reconnectionDelayMax': 5000,
        'timeout': 20000, // 20 seconds timeout for Render free hosting delays
        'autoConnect': true,
        'forceNew': false,
        'upgrade': true,
      },
    );

    _socket!.on('connect', (_) => _attachQueuedListeners());
    _attachQueuedListeners();
    _socket!.connect();
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket?.close();
    _socket = null;
  }

  static void on(String event, void Function(dynamic) callback) {
    final callbacks = _queuedListeners.putIfAbsent(
      event,
      () => <void Function(dynamic)>[],
    );
    callbacks.add(callback);
    _socket?.off(event, callback);
    _socket?.on(event, callback);
  }

  static void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  static void off(String event) {
    final callbacks = _queuedListeners.remove(event);
    if (callbacks == null) {
      _socket?.off(event);
      return;
    }
    for (final callback in callbacks) {
      _socket?.off(event, callback);
    }
  }

  static void removeListener(
    String event,
    void Function(dynamic) callback,
  ) {
    final callbacks = _queuedListeners[event];
    if (callbacks == null) return;
    callbacks.remove(callback);
    if (callbacks.isEmpty) {
      _queuedListeners.remove(event);
    }
    _socket?.off(event, callback);
  }

  static void _attachQueuedListeners() {
    if (_socket == null) return;
    _queuedListeners.forEach((event, callbacks) {
      for (final callback in callbacks) {
        _socket!.off(event, callback);
        _socket!.on(event, callback);
      }
    });
  }
}
