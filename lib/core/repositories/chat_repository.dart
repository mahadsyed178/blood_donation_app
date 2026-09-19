import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../models/chat.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

/// `/chat/*` — REST history/send plus the live socket.
class ChatRepository {
  final ApiClient _api;
  final TokenStorage _tokens;
  const ChatRepository(this._api, this._tokens);

  Future<List<ChatThreadSummary>> listThreads({int limit = 50, int offset = 0}) async {
    final raw = await _api.get<List<dynamic>>(
      '/chat/threads',
      query: {'limit': limit, 'offset': offset},
    );
    return raw.map((e) => ChatThreadSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ChatMessage>> listMessages(String matchId) async {
    final raw = await _api.get<List<dynamic>>('/chat/$matchId/messages');
    return raw.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// REST fallback used when the socket is down.
  Future<ChatMessage> sendMessage(String matchId, String content) async =>
      ChatMessage.fromJson(await _api.post<Map<String, dynamic>>(
        '/chat/$matchId/messages',
        body: {'content': content},
      ));

  /// Opens `/chat/ws/{match_id}?token=…`. The token goes in the query string
  /// because the backend reads it from there (browsers can't set headers on
  /// a WebSocket handshake).
  Future<ChatSocket> connect(String matchId) async {
    final session = await _tokens.read();
    if (session == null) {
      throw StateError('Cannot open chat socket without a session');
    }
    final uri = Uri.parse('${AppConfig.wsBaseUrl}/chat/ws/$matchId')
        .replace(queryParameters: {'token': session.token});
    return ChatSocket._(uri);
  }
}

/// One live connection to a match's chat thread, with reconnection.
///
/// Incoming frames are either a broadcast `ChatMessageOut` or
/// `{"error": "..."}`. Close code 4401 means the token was rejected; we do
/// not reconnect in that case.
class ChatSocket {
  final Uri _uri;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  final _messages = StreamController<ChatMessage>.broadcast();
  final _errors = StreamController<String>.broadcast();
  final _connection = StreamController<bool>.broadcast();
  bool _closed = false;
  bool _isConnected = false;
  int _attempt = 0;
  Timer? _reconnectTimer;

  ChatSocket._(this._uri) {
    _open();
  }

  Stream<ChatMessage> get messages => _messages.stream;
  Stream<String> get errors => _errors.stream;
  Stream<bool> get connectionState => _connection.stream;
  bool get isConnected => _isConnected;

  void _open() {
    if (_closed) return;
    try {
      _channel = WebSocketChannel.connect(_uri);
    } catch (e) {
      _scheduleReconnect();
      return;
    }
    _channel!.ready.then((_) {
      _attempt = 0;
      _setConnected(true);
    }).catchError((Object e) {
      debugPrint('[chat-ws] connect failed: $e');
      _setConnected(false);
      _scheduleReconnect();
    });

    _sub = _channel!.stream.listen(
      (raw) {
        try {
          final json = jsonDecode(raw as String);
          if (json is Map<String, dynamic>) {
            if (json.containsKey('error')) {
              _errors.add(json['error'].toString());
            } else {
              _messages.add(ChatMessage.fromJson(json));
            }
          }
        } catch (e) {
          debugPrint('[chat-ws] bad frame: $e');
        }
      },
      onError: (Object e) {
        debugPrint('[chat-ws] stream error: $e');
        _setConnected(false);
        _scheduleReconnect();
      },
      onDone: () {
        _setConnected(false);
        final code = _channel?.closeCode;
        if (code == 4401) {
          _errors.add('Session expired — please log in again');
          _closed = true;
          return;
        }
        _scheduleReconnect();
      },
      cancelOnError: true,
    );
  }

  void _setConnected(bool value) {
    if (_isConnected == value) return;
    _isConnected = value;
    if (!_connection.isClosed) _connection.add(value);
  }

  void _scheduleReconnect() {
    if (_closed || _reconnectTimer != null) return;
    // 1s, 2s, 4s … capped at 15s.
    final seconds = (1 << _attempt).clamp(1, 15);
    _attempt = (_attempt + 1).clamp(0, 4);
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      _reconnectTimer = null;
      _sub?.cancel();
      _open();
    });
  }

  /// Returns false if the socket is not connected; callers should then fall
  /// back to [ChatRepository.sendMessage].
  bool send(String content) {
    if (!_isConnected || _channel == null) return false;
    _channel!.sink.add(jsonEncode({'content': content}));
    return true;
  }

  Future<void> dispose() async {
    _closed = true;
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    await _messages.close();
    await _errors.close();
    await _connection.close();
  }
}
