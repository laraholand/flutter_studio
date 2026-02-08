import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:xterm/xterm.dart';

class TerminalSession {
  late Future<void> ready;
  final String id;
  final String command;
  final String serverHost;
  final String serverPort;

  late Terminal terminal;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;

  bool _connected = false;

  TerminalSession({
  required this.id,
  required this.command,
  required this.serverHost,
  required this.serverPort,
  }) {
    terminal = Terminal();
    terminal.onOutput = _onOutput;
    ready = _connect();  
  }

  Future<void> _connect() async {
    final pid = await _createSession();
    if (pid == null) {
      _retry();
      throw Exception("session create failed");
    }
  
    final wsUrl = 'ws://$serverHost:$serverPort/terminals/$pid';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
  
    final completer = Completer<void>();
  
    _sub = _channel!.stream.listen(
      (event) {
        if (!_connected) {
          _connected = true;
          sendCommand(command);
          completer.complete();   
        }
  
        terminal.write(event is String ? event : utf8.decode(event));
      },
      onDone: _retry,
      onError: (_) => _retry(),
    );
  
    return completer.future;
  }

  Future<String?> _createSession() async {
    try {
      final res = await http.post(
        Uri.parse('http://$serverHost:$serverPort/terminals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cols': 100, 'rows': 30}),
      );

      if (res.statusCode == 200) {
        return res.body;
      }
    } catch (_) {}
    return null;
  }

  void _retry() {
    _connected = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), _connect);
  }

  void _onOutput(String text) {
    if (_connected) {
      _channel?.sink.add(text);
    }
  }

  void sendCommand(String cmd) {
    if (_connected) {
      _channel?.sink.add("$cmd\n");
    }
  }

  bool get isConnected => _connected;

  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
    _reconnectTimer?.cancel();
  }
}
