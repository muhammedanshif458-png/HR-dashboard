import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/config.dart';
import '../core/department_helper.dart';
import '../models/hr_models.dart';
import 'api_service.dart';

/// Service managing real-time Socket.IO bidirectional connection for Department Chat.
class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;
  ChatSocketService._internal();

  io.Socket? _socket;
  String? _currentDepartmentKey;
  bool _isConnected = false;
  DateTime? _lastDisconnectTime;
  bool isTestMode = false;

  final List<void Function(ChatMessage message)> _messageListeners = [];
  final List<
          void Function(
              String messageId, bool deletedForEveryone, String? departmentKey)>
      _deleteListeners = [];
  final List<void Function(String deptKey)> _reconnectListeners = [];
  final List<void Function(bool isConnected)> _connectionListeners = [];

  bool get isConnected => _isConnected;
  String? get currentDepartmentKey => _currentDepartmentKey;

  /// Initialize and connect the socket using the current authenticated token.
  void connect({String? token, String? baseUrl}) {
    if (isTestMode) {
      _isConnected = true;
      _notifyConnectionStatus(true);
      return;
    }

    final effectiveToken = token ?? ApiService.token;
    final effectiveUrl = baseUrl ?? AppConfig.apiBaseUrl;

    if (effectiveToken == null || effectiveToken.isEmpty) {
      return;
    }

    // If socket exists and already connected with the same url, return
    if (_socket != null && _socket!.connected) {
      return;
    }

    // Clean up previous socket if any
    disposeSocket();

    try {
      final opts = io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': effectiveToken})
          .setExtraHeaders({'Authorization': 'Bearer $effectiveToken'})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .setTimeout(10000)
          .build();

      _socket = io.io(effectiveUrl, opts);

      _socket!.onConnect((_) {
        _isConnected = true;
        _notifyConnectionStatus(true);

        // Rejoin active department room upon connect / reconnect
        if (_currentDepartmentKey != null &&
            _currentDepartmentKey!.isNotEmpty) {
          _emitJoinDepartment(_currentDepartmentKey!);
        }

        // If previously disconnected, notify listeners to fetch missed messages
        if (_lastDisconnectTime != null && _currentDepartmentKey != null) {
          final dept = _currentDepartmentKey!;
          for (final listener in List.of(_reconnectListeners)) {
            try {
              listener(dept);
            } catch (_) {}
          }
        }
        _lastDisconnectTime = null;
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        _lastDisconnectTime = DateTime.now();
        _notifyConnectionStatus(false);
      });

      _socket!.onConnectError((err) {
        _isConnected = false;
        _notifyConnectionStatus(false);
      });

      // Handle server events
      _socket!.on('new_message', (data) => _handleIncomingMessage(data));
      _socket!.on('message_received', (data) => _handleIncomingMessage(data));
      _socket!.on('message_deleted', (data) => _handleMessageDeleted(data));
    } catch (_) {
      _isConnected = false;
      _notifyConnectionStatus(false);
    }
  }

  void _handleIncomingMessage(dynamic data) {
    if (data == null) return;
    try {
      final Map<String, dynamic> json = data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);
      final msg = ChatMessage.fromJson(json);

      for (final listener in List.of(_messageListeners)) {
        try {
          listener(msg);
        } catch (_) {}
      }
    } catch (_) {}
  }

  void _handleMessageDeleted(dynamic data) {
    if (data == null) return;
    try {
      final Map<String, dynamic> json = data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);
      final messageId =
          json['messageId']?.toString() ?? json['id']?.toString() ?? '';
      final deletedForEveryone = json['deletedForEveryone'] == true;
      final departmentKey = json['departmentKey']?.toString();

      if (messageId.isNotEmpty) {
        for (final listener in List.of(_deleteListeners)) {
          try {
            listener(messageId, deletedForEveryone, departmentKey);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  void _notifyConnectionStatus(bool connected) {
    for (final listener in List.of(_connectionListeners)) {
      try {
        listener(connected);
      } catch (_) {}
    }
  }

  /// Subscribes to the canonical department room on the backend.
  void joinDepartment(String deptKey) {
    final canonicalKey = DepartmentHelper.normalize(deptKey);
    if (canonicalKey.isEmpty) return;

    if (_currentDepartmentKey != null &&
        _currentDepartmentKey != canonicalKey) {
      leaveDepartment();
    }

    _currentDepartmentKey = canonicalKey;

    if (_socket == null || !_socket!.connected) {
      connect();
    } else {
      _emitJoinDepartment(canonicalKey);
    }
  }

  void _emitJoinDepartment(String canonicalKey) {
    if (isTestMode) return;
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_department', {'departmentKey': canonicalKey});
    }
  }

  /// Leaves the current department room.
  void leaveDepartment() {
    if (_currentDepartmentKey != null) {
      if (!isTestMode && _socket != null && _socket!.connected) {
        _socket!
            .emit('leave_department', {'departmentKey': _currentDepartmentKey});
      }
      _currentDepartmentKey = null;
    }
  }

  // --- Test Simulation Methods ---

  void emitTestIncomingMessage(ChatMessage msg) {
    for (final listener in List.of(_messageListeners)) {
      try {
        listener(msg);
      } catch (_) {}
    }
  }

  void emitTestMessageDeleted(
    String messageId,
    bool deletedForEveryone, {
    String? departmentKey,
  }) {
    for (final listener in List.of(_deleteListeners)) {
      try {
        listener(messageId, deletedForEveryone, departmentKey);
      } catch (_) {}
    }
  }

  void emitTestReconnect(String deptKey) {
    for (final listener in List.of(_reconnectListeners)) {
      try {
        listener(deptKey);
      } catch (_) {}
    }
  }

  // Listener registrations

  void Function() addMessageListener(
      void Function(ChatMessage message) listener) {
    _messageListeners.add(listener);
    return () => _messageListeners.remove(listener);
  }

  void Function() addDeleteListener(
      void Function(
              String messageId, bool deletedForEveryone, String? departmentKey)
          listener) {
    _deleteListeners.add(listener);
    return () => _deleteListeners.remove(listener);
  }

  void Function() addReconnectListener(void Function(String deptKey) listener) {
    _reconnectListeners.add(listener);
    return () => _reconnectListeners.remove(listener);
  }

  void Function() addConnectionListener(
      void Function(bool isConnected) listener) {
    _connectionListeners.add(listener);
    return () => _connectionListeners.remove(listener);
  }

  /// Clean up listeners and disconnect socket.
  void disposeSocket() {
    leaveDepartment();
    if (_socket != null) {
      try {
        _socket!.off('new_message');
        _socket!.off('message_received');
        _socket!.off('message_deleted');
        _socket!.disconnect();
        _socket!.dispose();
      } catch (_) {}
      _socket = null;
    }
    _isConnected = false;
  }
}
