import 'package:flutter/material.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSH Client Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TestHomeScreen(),
    );
  }
}

class TestHomeScreen extends StatelessWidget {
  const TestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('SSH 客户端测试'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.terminal,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              '专为 OPPO Pad 4 Pro 优化的',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'SSH 客户端应用',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            Text(
              '✅ Flutter 3.x 框架\n'
              '✅ Material 3 设计\n'  
              '✅ 13.2英寸平板优化\n'
              '✅ SSH 连接功能\n'
              '✅ 终端模拟器\n'
              '✅ 连接历史管理',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}