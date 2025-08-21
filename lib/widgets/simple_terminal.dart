import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

/// 简化的终端组件用于测试 xterm 4.0 API
class SimpleTerminal extends StatefulWidget {
  const SimpleTerminal({super.key});

  @override
  State<SimpleTerminal> createState() => _SimpleTerminalState();
}

class _SimpleTerminalState extends State<SimpleTerminal> {
  late Terminal terminal;

  @override
  void initState() {
    super.initState();
    terminal = Terminal();
    
    // 写入欢迎信息
    terminal.write('欢迎使用 SSH 客户端终端\r\n');
    terminal.write('xterm 4.0.0 测试版本\r\n\r\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('终端测试'),
      ),
      body: TerminalView(
        terminal,
      ),
    );
  }
}