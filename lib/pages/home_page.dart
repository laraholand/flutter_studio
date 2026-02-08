import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:flutter_studio/pages/editor_page.dart';
import 'package:flutter_studio/pages/terminal_page.dart';
import 'package:flutter_studio/util/functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:android_intent_plus/android_intent.dart';
import 'package:xterm/xterm.dart';
import 'package:flutter_studio/util/terminal_manager.dart';
import 'package:flutter_studio/util/terminal_session.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _packageName = TextEditingController();
  final TextEditingController _projectName = TextEditingController();
  final TextEditingController _projectPath = TextEditingController();
  late TerminalSession session;

  @override
  void initState() {
    super.initState();
    _checkStoragePermission();
    _checkForLastProject();
    _runAxsCommand();
  }

  Future<void> _runAxsCommand() async {
    final intent = AndroidIntent(
      action: 'com.termux.RUN_COMMAND',
      package: 'com.termux',
      componentName: 'com.termux.app.RunCommandService',
      arguments: <String, dynamic>{
        'com.termux.RUN_COMMAND_PATH':
            '/data/data/com.termux/files/usr/bin/axs',
        'com.termux.RUN_COMMAND_BACKGROUND': true,
        'com.termux.RUN_COMMAND_SESSION_ACTION': '0',
      },
    );
    

    try {
      await intent.sendService();    
    } catch (e) {
      debugPrint("Failed to send intent: $e");
    }
    TerminalManager().bootDefaultSessions();

    session = TerminalManager().getSession(id: "shell")!;

     await session.ready;  
  }

  Future<void> _checkForLastProject() async {
    final prefs = await SharedPreferences.getInstance();
    final lastProjectDir = prefs.getString('lastProjectDir');
    if (lastProjectDir != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Re-open Project?'),
          content: Text(
            'Do you want to re-open the last project: ${path.basename(lastProjectDir)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditorPage(projectRootDir: lastProjectDir),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _checkStoragePermission() async {
    final status = await Permission.manageExternalStorage.status;

    if (!status.isGranted) {
      await Permission.manageExternalStorage.request();
    }
  }

  void _cloneGitRepo(String repoUrl) {
    const baseDir = '/storage/emulated/0/FlutterStudio/Git_Repo';

    final command =
        '''
mkdir -p $baseDir &&
cd $baseDir &&
git clone $repoUrl
''';

    TerminalManager().sendToSession(id: "shell", command: command);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Git Clone Output'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: TerminalView(
              session.terminal,
              textStyle: const TerminalStyle(fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double buttonWidth = size.width > 600 ? 420 : size.width * 0.85;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flutter_dash,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                "Welcome to Flutter Studio",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Create, open or manage your Flutter projects easily on mobile",
                textAlign: TextAlign.center,
              ),
              SizedBox(height: size.height * 0.05),

              // Create new project button
              buildButton(
                width: buttonWidth,
                icon: Icons.add,
                text: "Create new project",
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Create new project'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _projectName,
                              decoration: const InputDecoration(
                                labelText: "Project name",
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _packageName,
                              decoration: const InputDecoration(
                                labelText:
                                    "Package name (e.g. com.example.app)",
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _projectPath,
                              decoration: const InputDecoration(
                                labelText: "Path",
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final projectName = _projectName.text.trim();
                              final packageName = _packageName.text.trim();
                              final projectPath = _projectPath.text.trim();

                              if (projectName.isEmpty ||
                                  packageName.isEmpty ||
                                  projectPath.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please fill all fields"),
                                  ),
                                );
                                return;
                              }

                              final fullProjectPath =
                                  '$projectPath$projectName';

                              // Generate flutter create command
                              final command =
                                  'flutter create --project-name $projectName --org $packageName $fullProjectPath';

                              
                              Clipboard.setData(ClipboardData(text: command));

                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Flutter command copied to clipboard!",
                                  ),
                                ),
                              );

                             
                              TerminalManager().sendToSession(
                                id: "shell",
                                command: command,
                              );

                             
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Terminal Output'),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      height: 300,
                                      child: TerminalView(
                                        session.terminal,
                                        textStyle: const TerminalStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      // Manual Close
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(
                                            context,
                                          ); // close dialog
                                        },
                                        child: const Text('Close'),
                                      ),
                                     
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(
                                            context,
                                          ); // close dialog
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditorPage(
                                                projectRootDir: fullProjectPath,
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text('Successful?'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              
                              
                            },
                            child: const Text("Create"),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              
              buildButton(
                width: buttonWidth,
                icon: Icons.folder,
                text: "Open existing project",
                onPressed: () async {
                  String? selectedDirectory = await FilePicker.platform
                      .getDirectoryPath();
                  if (selectedDirectory != null) {
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditorPage(projectRootDir: selectedDirectory),
                      ),
                    );
                  }
                },
              ),

              
              buildButton(
                width: buttonWidth,
                icon: Icons.cloud_download,
                text: "Clone git repo",
                onPressed: () {
                  final TextEditingController repoController =
                      TextEditingController();

                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Clone Git Repository'),
                        content: TextField(
                          controller: repoController,
                          decoration: const InputDecoration(
                            labelText: 'Git repo URL',
                            hintText: 'https://github.com/user/repo.git',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final repoUrl = repoController.text.trim();
                              if (repoUrl.isEmpty) return;

                              Navigator.pop(context);
                              _cloneGitRepo(repoUrl);
                            },
                            child: const Text('Clone'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              buildButton(
                width: buttonWidth,
                icon: Icons.arrow_forward,
                text: "Open Terminal",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TerminalPage()),
                  );
                },
              ),
              
              

              SizedBox(height: size.height * 0.04),
              Text(
                "Flutter - Fast - Beautiful",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
