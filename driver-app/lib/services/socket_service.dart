import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_client.dart';

class SocketService {
  static io.Socket? _socket;
  static final Map<String, List<void Function(dynamic)>> _queuedListeners = {};

  static io.Socket? get socket => _socket;
  
  static bool get isConnected => _socket != null && _socket!.connected;
  
  static Future<bool> waitForConnection({int maxWaitMs = 5000}) async {
    if (_socket == null) return false;
    if (_socket!.connected) return true;
    
    final completer = Completer<bool>();
    Timer? timeout;
    
    void onConnect(_) {
      if (!completer.isCompleted) {
        completer.complete(true);
        _socket!.off('connect', onConnect);
        timeout?.cancel();
      }
    }
    
    _socket!.on('connect', onConnect);
    
    timeout = Timer(Duration(milliseconds: maxWaitMs), () {
      if (!completer.isCompleted) {
        completer.complete(false);
        _socket!.off('connect', onConnect);
      }
    });
    
    return completer.future;
  }

  static void _attachQueuedListeners() {
    if (_socket == null || !_socket!.connected) return;
    _queuedListeners.forEach((event, callbacks) {
      for (final callback in callbacks) {
        // Remove any existing listener for this callback before adding
        _socket!.off(event, callback);
        _socket!.on(event, callback);
      }
    });
  }

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print('SocketService: No token found, cannot initialize');
      return;
    }

    if (_socket != null && _socket!.connected) {
      print('SocketService: Socket already connected');
      return;
    }

    if (_socket != null) {
      _socket!.auth = {'token': token};
      if (!_socket!.connected) {
        _socket!.connect();
      }
      return;
    }

    print('SocketService: Initializing new socket connection to ${ApiClient.socketUrl}');
    _socket = io.io(
      ApiClient.socketUrl,
      <String, dynamic>{
        'transports': ['websocket'],
        'auth': {'token': token},
        'reconnection': true,
        'reconnectionAttempts': 10,
        'reconnectionDelay': 1000,
        'autoConnect': true,
      },
    );

    _socket!.on('connect', (_) {
      print('SocketService: Socket connected successfully');
      _attachQueuedListeners();
    });

    _socket!.on('disconnect', (_) {
      print('SocketService: Socket disconnected');
    });

    _socket!.on('connect_error', (error) {
      print('SocketService: Connection error: $error');
    });

    _attachQueuedListeners();

    _socket!.connect();
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket?.close();
    _socket = null;
  }

  static void on(String event, Function(dynamic) callback) {
    // Add callback to the list of listeners for this event (supports multiple listeners)
    final callbacks = _queuedListeners.putIfAbsent(
      event,
      () => <Function(dynamic)>[],
    );
    
    // Only add if not already present (avoid duplicates)
    if (!callbacks.contains(callback)) {
      callbacks.add(callback);
    }
    
    // Attach listener immediately if socket is connected, otherwise it will be attached on connect
    if (_socket != null && _socket!.connected) {
      print('SocketService: Attaching listener for event: $event (socket connected)');
      _socket!.on(event, callback);
    } else {
      print('SocketService: Queueing listener for event: $event (socket not connected yet)');
    }
  }
  
  /// Remove a specific listener
  static void removeListener(String event, Function(dynamic) callback) {
    final callbacks = _queuedListeners[event];
    if (callbacks == null) return;
    callbacks.remove(callback);
    if (callbacks.isEmpty) {
      _queuedListeners.remove(event);
    }
    _socket?.off(event, callback);
  }

  static void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  static void off(String event) {
    final callbacks = _queuedListeners.remove(event);
    if (_socket != null) {
      if (callbacks != null) {
        for (final callback in callbacks) {
          _socket!.off(event, callback);
        }
      } else {
        // Remove all listeners for this event
        _socket!.off(event);
      }
      print('SocketService: Removed listeners for event: $event');
    }
  }
}
