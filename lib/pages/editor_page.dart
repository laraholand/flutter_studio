import 'dart:io';

import 'package:flutter_studio/code_forge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_studio/librarys/dynamic_tab_bar.dart';
import 'package:flutter_studio/librarys/file_tree_view.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_studio/widgets/extra_keys_panel.dart';
import 'package:flutter_studio/widgets/editor_appbar.dart';
import 'package:flutter_studio/pages/terminal_page.dart';
import 'package:flutter_studio/util/page_type.dart';
import 'package:flutter_studio/pages/preview_page.dart';
import 'package:flutter_studio/util/terminal_manager.dart';
import 'package:sonner_toast/sonner_toast.dart';

class ExtendedTabData {
  String filePath;
  final CodeForgeController controller;
  final UndoRedoController undoController;
  bool isModified;
  String savedContent;

  ExtendedTabData({
    required this.filePath,
    required this.controller,
    required this.undoController,
    this.isModified = false,
    required this.savedContent,
  });
}

class EditorPage extends StatefulWidget {
  final String projectRootDir;
  const EditorPage({super.key, required this.projectRootDir});
  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  DateTime? _lastBackPressTime;
  late String _projectSessionId;
  final _termManager = TerminalManager();
  List<ExtendedTabData> openFiles = [];
  TabController? _tabController;
  int _currentIndex = 0;
  final bool _isDrawerCollapsed = false;

  bool _isAppRunning = false; 
  PageType _currentPage = PageType.EDITOR;

  UndoRedoController? get currentUndoController =>
      openFiles.isNotEmpty ? openFiles[_currentIndex].undoController : null;

  @override
  void initState() {
    super.initState();
    _projectSessionId = "shell";

    _termManager.sendToSession(
      id: _projectSessionId,
      command: "cd ${widget.projectRootDir} && bash",
    );
    _saveProjectDir();
  }

  Future<void> _saveProjectDir() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastProjectDir', widget.projectRootDir);
  }

  void _openFile(File file) {
    final existingIndex = openFiles.indexWhere(
      (tab) => tab.filePath == file.path,
    );

    if (existingIndex == -1) {
      final String initialContent = file.readAsStringSync();
      final undoController = UndoRedoController();
      final controller = CodeForgeController(
        lspConfig: LspSocketConfig(
          workspacePath: widget.projectRootDir,
          languageId: 'dart',
          serverUrl: 'ws://localhost:5656',
        ),
      );
      controller.setUndoController(undoController);
      controller.text = initialContent;

      controller.addListener(() {
        final fileIndex = openFiles.indexWhere(
          (f) => f.controller == controller,
        );
        if (fileIndex != -1) {
          final isActuallyModified =
              controller.text != openFiles[fileIndex].savedContent;
          if (openFiles[fileIndex].isModified != isActuallyModified) {
            if (mounted) {
              setState(() {
                openFiles[fileIndex].isModified = isActuallyModified;
              });
            }
          }
        }
      });
      final newIndex = openFiles.length;
      setState(() {
        openFiles.add(
          ExtendedTabData(
            filePath: file.path,
            controller: controller,
            undoController: undoController,
            savedContent: initialContent,
          ),
        );
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabController?.animateTo(newIndex);
        if (mounted) {
          setState(() {
            _currentIndex = newIndex;
          });
        }
      });
    } else {
      _tabController?.animateTo(existingIndex);
      if (mounted) {
        setState(() {
          _currentIndex = existingIndex;
        });
      }
    }
  }

  Future<void> _saveFile(int index) async {
    if (index < 0 || index >= openFiles.length) return;

    final fileData = openFiles[index];
    final file = File(fileData.filePath);
    await file.writeAsString(fileData.controller.text);

    if (mounted) {
      setState(() {
        fileData.isModified = false;
        fileData.savedContent = fileData.controller.text;
      });

      Sonner.toast(
        builder: (context, dismiss) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF414A4C), // primary color
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Saved ${path.basename(fileData.filePath)}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
        duration: const Duration(seconds: 3),
      );

      

      if (path.basename(fileData.filePath) == 'pubspec.yaml') {
        _syncProject();
      }
    }
  }

  void _showEditContextMenu(BuildContext context) {
    final RenderBox appBarBox = context.findRenderObject() as RenderBox;
    final Offset offset = appBarBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + 40, 
        offset.dy + kToolbarHeight, 
        offset.dx + 200, 
        0,
      ),
      items: [
        _contextMenuItem(Icons.copy, 'Copy line', () {}),
        _contextMenuItem(Icons.content_cut, 'Cut line', () {}),
        _contextMenuItem(Icons.delete, 'Delete line', () {}),
        _contextMenuItem(Icons.remove, 'Empty line', () {}),
        _contextMenuItem(Icons.swap_vert, 'Replace line', () {}),
        _contextMenuItem(
          Icons.control_point_duplicate,
          'Duplicate line',
          () {},
        ),
        _contextMenuItem(Icons.text_fields, 'Convert to uppercase', () {}),
        _contextMenuItem(
          Icons.text_fields_outlined,
          'Convert to lowercase',
          () {},
        ),
        _contextMenuItem(Icons.arrow_right, 'Increase Indent', () {}),
        _contextMenuItem(Icons.arrow_left, 'Decrease Indent', () {}),
        _contextMenuItem(Icons.code, 'Toggle comment', () {}),
      ],
    );
  }

  PopupMenuItem _contextMenuItem(
    IconData icon,
    String text,
    VoidCallback onTap,
  ) {
    return PopupMenuItem(
      child: ListTile(
        leading: Icon(icon),
        title: Text(text),
        onTap: () {
          Navigator.pop(context); 
          onTap();
        },
      ),
    );
  }

  Future<bool> _promptToSave(int index) async {
    final fileData = openFiles[index];
    if (!fileData.isModified) {
      return true; 
    }

    final result = await showDialog<DialogResult>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Save changes?'),
        content: Text(
          'Do you want to save the changes to ${path.basename(fileData.filePath)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, DialogResult.cancel),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, DialogResult.dontSave),
            child: Text("Don't Save"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, DialogResult.save),
            child: Text('Save'),
          ),
        ],
      ),
    );

    if (result == DialogResult.save) {
      await _saveFile(index);
      return true;
    }
    return result == DialogResult.dontSave;
  }

  Future<void> _closeFile(int index) async {
    if (!mounted) return;
    final canClose = await _promptToSave(index);
    if (canClose) {
      setState(() {
        openFiles.removeAt(index);
        if (_currentIndex >= openFiles.length) {
          _currentIndex = openFiles.length - 1;
        }
        if (_currentIndex < 0) _currentIndex = 0;

        if (openFiles.isNotEmpty) {
          _tabController?.animateTo(_currentIndex);
        }
      });
    }
  }

  Future<void> _closeAllFiles() async {
    if (!mounted) return;
    for (int i = openFiles.length - 1; i >= 0; i--) {
      final canClose = await _promptToSave(i);
      if (!canClose) return;
    }
    setState(() {
      openFiles.clear();
      _currentIndex = 0;
    });
  }

  Future<void> _closeOtherFiles(int index) async {
    if (!mounted) return;
    for (int i = openFiles.length - 1; i >= 0; i--) {
      if (i == index) continue;
      final canClose = await _promptToSave(i);
      if (!canClose) return;
    }
    setState(() {
      final file = openFiles[index];
      openFiles = [file];
      _currentIndex = 0;
      _tabController?.animateTo(0);
    });
  }

  void _showTabContextMenu(BuildContext context, int index) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox button = context.findRenderObject() as RenderBox;
    final position = button.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + button.size.height,
        position.dx + button.size.width,
        position.dy + button.size.height,
      ),
      items: [
        const PopupMenuItem<String>(value: 'close', child: Text('Close')),
        const PopupMenuItem<String>(
          value: 'close_others',
          child: Text('Close Others'),
        ),
        const PopupMenuItem<String>(
          value: 'close_all',
          child: Text('Close All'),
        ),
      ],
    ).then((String? value) {
      if (value != null) {
        switch (value) {
          case 'close':
            _closeFile(index);
            break;
          case 'close_others':
            _closeOtherFiles(index);
            break;
          case 'close_all':
            _closeAllFiles();
            break;
        }
      }
    });
  }

  void _runApp() {
    _termManager.sendToSession(
      id: _projectSessionId,
      command: 'flutter run -d web-server --web-port 8080',
    );
    setState(() {
      _isAppRunning = true;
      _currentPage = PageType.TERMINAL;
    });
  }

  void _stopApp() {
    _termManager.sendToSession(id: _projectSessionId, command: 'q');
    setState(() {
      _isAppRunning = false;

      _currentPage = PageType.EDITOR;
    });
  }

  void _hotReload() {
    _termManager.sendToSession(id: _projectSessionId, command: 'r');
    setState(() {
      _currentPage = PageType.PREVIEW;
    });
  }

  void _hotRestart() {
    _termManager.sendToSession(id: _projectSessionId, command: 'R');
    setState(() {
      _currentPage = PageType.PREVIEW;
    });
  }

  void _openTerminal(BuildContext context) {
    setState(() {
      _currentPage = PageType.TERMINAL;
    });
  }

  void _syncProject() {
    _termManager.sendToSession(
      id: _projectSessionId,
      command: 'flutter pub get',
    );

    Sonner.toast(
      builder: (context, dismiss) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF3B444B), 
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Project synced successfully',
            style: TextStyle(color: Colors.white),
          ),
        );
      },
      duration: const Duration(seconds: 6),
    );
  }

  String _buildFlutterCommand({
    required String platform,
    required String mode,
    required List<String> archs,
  }) {
    final isRelease = mode.toLowerCase() == 'release';
    final modeFlag = isRelease ? '--release' : '--debug';

    switch (platform) {
      case 'Android':
        if (archs.contains('arm64') && archs.contains('arm32')) {
          return 'flutter build apk $modeFlag --split-per-abi';
        }
        if (archs.contains('arm64')) {
          return 'flutter build apk $modeFlag --target-platform android-arm64';
        }
        if (archs.contains('arm32')) {
          return 'flutter build apk $modeFlag --target-platform android-arm';
        }
        if (archs.contains('x64')) {
          return 'flutter build apk $modeFlag --target-platform android-x64';
        }
        return 'flutter build apk $modeFlag';

      case 'Web':
        if (archs.contains('CanvasKit')) {
          return 'flutter build web $modeFlag --web-renderer canvaskit';
        }
        if (archs.contains('HTML')) {
          return 'flutter build web $modeFlag --web-renderer html';
        }
        return 'flutter build web $modeFlag';

      case 'Windows':
        return 'flutter build windows $modeFlag';

      case 'Linux':
        return 'flutter build linux $modeFlag';

      case 'MacOS':
        return 'flutter build macos $modeFlag';

      case 'iOS':
        return 'flutter build ios $modeFlag';

      default:
        return 'flutter build';
    }
  }

  Future<void> _showBuildOptionsDialog() async {
    final platform = await _showSelectionDialog('Select Platform', [
      'Android',
      'Web',
      'Windows',
      'Linux',
      'MacOS',
      'iOS',
    ]);
    if (platform == null || !mounted) return;

    final mode = await _showSelectionDialog('Select Mode', [
      'Debug',
      'Release',
    ]);
    if (mode == null || !mounted) return;

    List<String> archs;
    switch (platform) {
      case 'Android':
        archs = ['arm64', 'arm32', 'x64'];
        break;
      case 'Windows':
        archs = ['x64', 'arm64'];
        break;
      case 'Linux':
        archs = ['x64'];
        break;
      case 'MacOS':
        archs = ['x64', 'arm64'];
        break;
      case 'iOS':
        archs = ['arm64', 'Simulator'];
        break;
      case 'Web':
        archs = ['Default', 'CanvasKit', 'HTML'];
        break;
      default:
        archs = [];
    }

    final selectedArchs = await _showMultiSelectionDialog(
      'Select Architecture(s)',
      archs,
    );

    if (selectedArchs == null || selectedArchs.isEmpty || !mounted) return;

    final command = _buildFlutterCommand(
      platform: platform,
      mode: mode,
      archs: selectedArchs,
    );

    _termManager.sendToSession(id: _projectSessionId, command: command);

    setState(() {
      _currentPage = PageType.TERMINAL;
    });

    Sonner.toast(
      builder: (context, dismiss) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2E3B3E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Building for $platform ($mode)...',
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
      duration: const Duration(seconds: 4),
    );
  }

  Future<String?> _showSelectionDialog(String title, List<String> options) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: options.map((option) {
                return ListTile(
                  title: Text(option),
                  onTap: () => Navigator.pop(context, option),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<List<String>?> _showMultiSelectionDialog(
    String title,
    List<String> options,
  ) {
    final selectedValues = <String>{};
    return showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: ListBody(
                  children: options.map((option) {
                    return CheckboxListTile(
                      title: Text(option),
                      value: selectedValues.contains(option),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedValues.add(option);
                          } else {
                            selectedValues.remove(option);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, selectedValues.toList()),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  int get _pageIndex {
    switch (_currentPage) {
      case PageType.EDITOR:
        return 0;
      case PageType.PREVIEW:
        return 1;
      case PageType.TERMINAL:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<TabData> tabsWithMenu = [];
    for (int i = 0; i < openFiles.length; i++) {
      final fileData = openFiles[i];
      final fileName = path.basename(fileData.filePath);

      tabsWithMenu.add(
        TabData(
          index: i,
          title: Tab(
            child: Builder(
              builder: (BuildContext tabContext) {
                return GestureDetector(
                  onSecondaryTapDown: (details) =>
                      _showTabContextMenu(tabContext, i),
                  onTap: () {
                    if (i == _currentIndex) {
                      _showTabContextMenu(tabContext, i);
                    } else {
                      _tabController?.animateTo(i);
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(fileName),
                      if (fileData.isModified)
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.yellow.shade800,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          content: CodeForge(
            controller: fileData.controller,
            undoController: fileData.undoController,
            filePath: fileData.filePath,
            enableKeyboardSuggestions: false,
            deleteFoldRangeOnDeletingFirstLine: true,
          ),
        ),
      );
    }
    Future<void> _handleDoubleBack() async {
  final now = DateTime.now();

  if (_lastBackPressTime == null ||
      now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
    _lastBackPressTime = now;

    FocusScope.of(context).unfocus();

    Sonner.toast(
      builder: (context, dismiss) => const Text("Press back again"),
      duration: const Duration(seconds: 2),
    );

    return;
  }


  if (_currentPage != PageType.EDITOR) {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Leave this page?"),
        content: const Text("Go back to editor?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        _currentPage = PageType.EDITOR;
      });
    }

    return;
  }

  final exit = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Exit project?"),
      content: const Text("Are you sure you want to exit?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Exit"),
        ),
      ],
    ),
  );

  if (exit == true && mounted) {
    Navigator.pop(context);
  }
}
  return PopScope(
  canPop: false,
  onPopInvoked: (didPop) async {
    if (didPop) return;
    await _handleDoubleBack();
  },
    child: Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: EditorAppBar(
        currentUndoController: currentUndoController,
        isModified:
            openFiles.isNotEmpty &&
            _currentIndex < openFiles.length &&
            openFiles[_currentIndex].isModified,
        isEmpty: openFiles.isEmpty,
        isAppRunning: _isAppRunning,

        onSave: () => _saveFile(_currentIndex),
        onRun: _runApp,
        onStop: _stopApp,
        onHotReload: _hotReload,
        onHotRestart: _hotRestart,
        onTerminal: () => _openTerminal(context),
        onSync: _syncProject,
        onBuildOptions: _showBuildOptionsDialog,
        onEdit: () => _showEditContextMenu(context),
        onCreateNewTerminalSession: () =>
            TerminalManager().createSession(id: "terminal", command: "clear"),
        onCancel: () {
          setState(() {
            _currentPage = PageType.EDITOR;
          });
        },
        onPreviewReload: _hotReload,
        pageType: _currentPage,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: DirectoryTreeViewer(
            rootPath: widget.projectRootDir,
            enableCreateFolderOption: true,
            isUnfoldedFirst: !_isDrawerCollapsed,
            onFileTap: (file, details) {
              _openFile(file);
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: IndexedStack(
        index: _pageIndex, 
        children: [
          openFiles.isNotEmpty
              ? Column(
                  children: [
                    Expanded(
                      child: DynamicTabBarWidget(
                        isScrollable: true,
                        physicsTabBarView: NeverScrollableScrollPhysics(),
                        dynamicTabs: tabsWithMenu,
                        onTabControllerUpdated: (controller) {
                          _tabController = controller;
                        },
                        onTabChanged: (index) {
                          if (index != null) {
                            setState(() {
                              _currentIndex = index;
                            });
                          }
                        },
                      ),
                    ),
                    ExtraKeysPanel(
                      controller: openFiles.isNotEmpty
                          ? openFiles[_currentIndex].controller
                          : null,
                    ),
                  ],
                )
              : const Center(
                  child: Text('Open a file from the drawer to start editing'),
                ),

          // Preview view
          const PreviewPage(), // WebView at localhost:8080
          TerminalPage(),
        ],
      ),
    )
   ) ;
  }
}

enum DialogResult { save, dontSave, cancel }
