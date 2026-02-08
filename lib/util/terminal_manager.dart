import 'package:flutter_studio/util/terminal_session.dart';

class TerminalManager {
  static final TerminalManager _instance = TerminalManager._();
  factory TerminalManager() => _instance;
  TerminalManager._();

  final Map<String, TerminalSession> _sessions = {};

  final host = '127.0.0.1';
  final port = '8767';

  final dartLSP =
      "./lsp-ws-proxy --listen 5656 -- dart language-server --protocol=lsp";

  final htmlLSP = "./lsp-ws-proxy --listen 5657 -- html-languageserver --stdio";

  TerminalSession createSession({required String id, required String command}) {
    if (_sessions.containsKey(id)) {
      return _sessions[id]!;
    }

    final s = TerminalSession(
      id: id,
      command: command,
      serverHost: host,
      serverPort: port,
    );

    _sessions[id] = s;
    return s;
  }

  TerminalSession? getSession({required String id}) => _sessions[id];

  void sendToSession({required String id, required String command}) {
    final s = _sessions[id];
    if (s == null) {
      print("Session $id not found");
      return;
    }
    s.sendCommand(command);
  }

  List<TerminalSession> get allSessions => _sessions.values.toList();

  void bootDefaultSessions() {
    if (_sessions.isNotEmpty) return;

    createSession(id: "dartLSP", command: dartLSP);
    createSession(id: "htmlLSP", command: htmlLSP);
    createSession(id: "shell", command: "clear");
  }

  void disposeAll() {
    for (var s in _sessions.values) {
      s.dispose();
    }
    _sessions.clear();
  }
}
