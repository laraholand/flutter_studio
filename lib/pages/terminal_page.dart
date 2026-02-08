import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'package:flutter_studio/util/terminal_manager.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage>
    with TickerProviderStateMixin {
  final manager = TerminalManager();
  late TabController _controller;

  @override
  void initState() {
    super.initState();

    manager.bootDefaultSessions();

    _controller = TabController(
      length: manager.allSessions.length,
      vsync: this,
    );
  }

  void _addShellSession() {
    final id = "shell_${DateTime.now().millisecondsSinceEpoch}";
    manager.createSession(id: id, command: "clear");

    setState(() {
      _controller = TabController(
        length: manager.allSessions.length,
        vsync: this,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessions = manager.allSessions;

    return Scaffold(
      body: TabBarView(
        controller: _controller,
        children: sessions
            .map(
              (s) => TerminalView(
                s.terminal,
                textStyle: const TerminalStyle(fontSize: 13),
              ),
            )
            .toList(),
      ),
    );
  }
}
