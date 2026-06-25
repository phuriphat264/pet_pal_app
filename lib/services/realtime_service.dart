// Owns the single live WebSocket connection to the backend (chat + push
// notifications share one socket). REST stays the source of truth for
// history; this only delivers events to whoever's on-screen right now.
import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_client.dart';
import 'auth_service.dart';

class RealtimeService {
  final AuthService authService;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _shouldStayConnected = false;

  RealtimeService({required this.authService}) {
    authService.addListener(_onAuthChanged);
    if (authService.isLoggedIn) connect();
  }

  void _onAuthChanged() {
    if (authService.isLoggedIn) {
      connect();
    } else {
      disconnect();
    }
  }

  Stream<Map<String, dynamic>> get events => _controller.stream;

  /// Sends a JSON-encodable event back over the socket (e.g. call signaling).
  /// No-ops if we're currently disconnected -- callers should treat this as
  /// best-effort, same as the rest of the realtime layer.
  void send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  Future<void> connect() async {
    final token = await authService.ensureValidAccessToken();
    if (token == null) return;

    _shouldStayConnected = true;
    _disconnectSocket();

    final wsBase = apiBaseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
    final channel = WebSocketChannel.connect(Uri.parse('$wsBase/chat/ws?token=$token'));
    _channel = channel;
    _subscription = channel.stream.listen(
      (raw) {
        try {
          final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
          _controller.add(decoded);
        } catch (_) {}
      },
      onError: (_) => _scheduleReconnect(),
      onDone: () => _scheduleReconnect(),
      cancelOnError: true,
    );
  }

  void _scheduleReconnect() {
    if (!_shouldStayConnected) return;
    Future.delayed(const Duration(seconds: 3), () {
      if (_shouldStayConnected) connect();
    });
  }

  void _disconnectSocket() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void disconnect() {
    _shouldStayConnected = false;
    _disconnectSocket();
  }

  void dispose() {
    authService.removeListener(_onAuthChanged);
    disconnect();
    _controller.close();
  }
}
