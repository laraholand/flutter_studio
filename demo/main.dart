// import 'package:flutter/material.dart';
// import 'package:code_forge/code_forge.dart';
// import 'package:permission_handler/permission_handler.dart';

// void main() {
// runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
// const MyApp({super.key});

// // This widget is the root of your application.
// @override
// Widget build(BuildContext context) {
// return MaterialApp(
// title: 'Flutter Demo',
// theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
// home: const MainPage(),
// );
// }
// }

// class MainPage extends StatefulWidget {
// const MainPage({super.key});

// @override
// State<MainPage> createState() => _MainPageState();
// }

// class _MainPageState extends State<MainPage> {
// @override
// void initState() {
// super.initState();
// _checkStoragePermission();
// }

// Future<void> _checkStoragePermission() async {
// final status = await Permission.manageExternalStorage.status;

// if (!status.isGranted) {
// await Permission.manageExternalStorage.request();
// }
// }

// @override
// Widget build(BuildContext context) {
// final lspConfig = LspSocketConfig(
// workspacePath: "/storage/emulated/0/IDE/Projects/Flutter/demo/",
// languageId: "dart",
// serverUrl: "ws://localhost:5656",
// );

// final controller = CodeForgeController(lspConfig: lspConfig);

// return Scaffold(
// body: CodeForge(
// controller: controller,
// filePath: "/storage/emulated/0/IDE/Projects/Flutter/demo/lib/main.dart",
// ),
// );
// }
// }
