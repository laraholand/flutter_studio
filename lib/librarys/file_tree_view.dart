import 'dart:async';
import 'dart:io';
import 'package:flutter_studio/librarys/style.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_studio/util/file_icons.dart';

late bool isParentOpen;
String? currentDir;

class DirectoryTreeViewer extends StatelessWidget {
  /// The root path of the directory to display.
  final String rootPath;

  /// Initial state of the [DirectoryTreeViewer].
  /// isUnfoldedFirst = true by defualt
  final bool isUnfoldedFirst;

  /// Enables folder creation option
  final bool enableCreateFolderOption;

  /// Enables file creation option
  final bool enableCreateFileOption;

  ///Enables folder deletion option
  final bool enableDeleteFolderOption;

  /// Enables file deletion option
  final bool enableDeleteFileOption;

  /// Customizable folder styling
  final FolderStyle? folderStyle;

  /// Customizable file styling
  final FileStyle? fileStyle;

  /// Custom styling for text editing field.
  final EditingFieldStyle? editingFieldStyle;

  /// Callback function when a file is tapped. Accepts a [File] and [TapDownDetails] as parameters.
  final void Function(File, TapDownDetails)? onFileTap;

  /// Callback function when a file is right-clicked.
  final void Function(File, TapDownDetails)? onFileSecondaryTap;

  /// Callback function when a directory is tapped.
  final void Function(Directory, TapDownDetails)? onDirTap;

  /// Callback function when a directory is right-clicked.
  final void Function(Directory, TapDownDetails)? onDirSecondaryTap;

  ///Additional folder action widgets
  final List<Widget>? folderActions;

  ///Additional file action widgets
  final List<Widget>? fileActions;

  /// A function that returns a custom file icon based on the file extension.
  final Widget Function(String fileExtension)? fileIconBuilder;

  /// Constructs a [DirectoryTreeViewer] with the given properties.
  const DirectoryTreeViewer({
    super.key,
    required this.rootPath,
    this.onFileTap,
    this.onFileSecondaryTap,
    this.onDirTap,
    this.onDirSecondaryTap,
    this.folderActions,
    this.fileActions,
    this.folderStyle,
    this.fileStyle,
    this.isUnfoldedFirst = true,
    this.editingFieldStyle,
    this.enableCreateFileOption = true,
    this.enableCreateFolderOption = false,
    this.enableDeleteFileOption = true,
    this.enableDeleteFolderOption = true,
    this.fileIconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    /// Check if the platform is Web or WASM, and display a message if it is.
    if (kIsWasm || kIsWeb) {
      return const AlertDialog(title: Text("Web platform is not supported"));
    }
    isParentOpen = isUnfoldedFirst;
    return DirectoryTreeStateProvider(
      notifier: DirectoryTreeStateNotifier(),
      child: FoldableDirectoryTree(
        folderStyle: folderStyle,
        fileStyle: fileStyle,
        editingFieldStyle: editingFieldStyle,
        enableCreateFolderOption: enableCreateFolderOption,
        enableCreateFileOption: enableCreateFileOption,
        enableDeleteFileOption: enableDeleteFileOption,
        enableDeleteFolderOption: enableDeleteFolderOption,
        folderActions: folderActions,
        fileActions: fileActions,
        rootPath: rootPath,
        onFileTap: onFileTap,
        onFileSecondaryTap: onFileSecondaryTap,
        onDirTap: onDirTap,
        onDirSecondaryTap: onDirSecondaryTap,
        fileIconBuilder: fileIconBuilder,
      ),
    );
  }
}

/// Manages the state of the directory tree, handling folder expansion and file operations.
class DirectoryTreeStateNotifier extends ChangeNotifier {
  ///// Tracks open/close state of folders
  final Map<String, bool> _folderStates = {};

  ///Watches for file system changes
  StreamSubscription<FileSystemEvent>? _directoryWatcher;

  /// Checks if a folder is expanded or collapsed
  bool isUnfolded(String dirPath, String rootPath) => dirPath == rootPath
      ? _folderStates[rootPath] = isParentOpen
      : (_folderStates[dirPath] ?? false);

  /// Toggles folder expansion/collapse state
  void toggleFolder(String dirPath, String rootPath) {
    if (dirPath != rootPath) {
      _folderStates[dirPath] = !(_folderStates[dirPath] ?? false);
    }
    notifyListeners();
  }

  /// Watches the given directory for changes and updates the UI accordingly
  void watchDirectory(String directoryPath) {
    _directoryWatcher?.cancel();
    final dir = Directory(directoryPath);
    if (dir.existsSync()) {
      _directoryWatcher = dir.watch(recursive: true).listen((event) {
        if (event is FileSystemCreateEvent ||
            event is FileSystemModifyEvent ||
            event is FileSystemDeleteEvent) {
          notifyListeners();
        }
      });
    }
  }
}

/// A provider that supplies [DirectoryTreeStateNotifier] to its descendants in the widget tree.
class DirectoryTreeStateProvider
    extends InheritedNotifier<DirectoryTreeStateNotifier> {
  /// Constructs a [DirectoryTreeStateProvider] with the given notifier and child widget.
  const DirectoryTreeStateProvider({
    super.key,
    required DirectoryTreeStateNotifier super.notifier,
    required super.child,
  });

  /// Accesses the [DirectoryTreeStateNotifier] in the widget tree.
  static DirectoryTreeStateNotifier of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<DirectoryTreeStateProvider>();
    assert(provider != null, 'No DirectoryTreeStateProvider found in context');
    return provider!.notifier!;
  }
}

/// A widget that displays a foldable directory tree, showing files and subdirectories.
class FoldableDirectoryTree extends StatefulWidget {
  final String rootPath;
  final bool enableCreateFolderOption, enableCreateFileOption;
  final bool enableDeleteFolderOption, enableDeleteFileOption;
  final FolderStyle? folderStyle;
  final FileStyle? fileStyle;
  final EditingFieldStyle? editingFieldStyle;
  final void Function(File, TapDownDetails)? onFileTap;
  final void Function(File, TapDownDetails)? onFileSecondaryTap;
  final void Function(Directory, TapDownDetails)? onDirTap;
  final void Function(Directory, TapDownDetails)? onDirSecondaryTap;
  final List<Widget>? folderActions;
  final List<Widget>? fileActions;
  final Widget Function(String fileExtension)? fileIconBuilder;

  const FoldableDirectoryTree({
    super.key,
    required this.rootPath,
    this.onFileTap,
    this.onFileSecondaryTap,
    this.onDirTap,
    this.onDirSecondaryTap,
    this.folderStyle,
    this.fileStyle,
    this.folderActions,
    this.fileActions,
    this.editingFieldStyle,
    this.enableCreateFileOption = false,
    this.enableCreateFolderOption = false,
    this.enableDeleteFileOption = false,
    this.enableDeleteFolderOption = false,
    this.fileIconBuilder,
  });

  @override
  State<FoldableDirectoryTree> createState() => _FoldableDirectoryTreeState();
}

/// Recursively builds the directory tree for a given [directory] using [stateNotifier] to manage folder states.
class _FoldableDirectoryTreeState extends State<FoldableDirectoryTree> {
  Future<void> _showCreateRenameDialog({
    required FileSystemEntity entity,
    bool isFolder = false,
    bool isRename = false,
  }) async {
    final controller = TextEditingController();
    if (isRename) {
      controller.text = path.basename(entity.path);
    }

    final String title = isRename
        ? 'Rename ${entity is Directory ? 'Folder' : 'File'}'
        : 'Create New ${isFolder ? 'Folder' : 'File'}';
    final String buttonText = isRename ? 'Rename' : 'Create';

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: isFolder ? 'Folder Name' : 'File Name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(buttonText),
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  if (isRename) {
                    final newPath = path.join(entity.parent.path, name);
                    entity.renameSync(newPath);
                  } else {
                    final newPath = path.join(entity.path, name);
                    if (isFolder) {
                      Directory(newPath).createSync();
                    } else {
                      File(newPath).createSync();
                    }
                  }
                  setState(() {});
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showBottomSheet(BuildContext context, FileSystemEntity entity) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        final isDirectory = entity is Directory;

        bool showDeleteOption = false;
        if (entity is File && widget.enableDeleteFileOption) {
          showDeleteOption = true;
        } else if (isDirectory && widget.enableDeleteFolderOption) {
          showDeleteOption = true;
        }

        return Wrap(
          children: <Widget>[
           
            if (showDeleteOption) // Conditionally show Delete ListTile
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () async {
                  
                  Navigator.pop(context); 

                  final confirmDelete = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('Confirm Deletion'),
                        content: Text(
                          'Are you sure you want to delete ${path.basename(entity.path)}? This action cannot be undone.',
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmDelete == true) {
                    try {
                      entity.deleteSync(recursive: true);
                      if (mounted) {
                        
                        setState(() {}); 
                      }
                    } catch (e) {
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error deleting ${path.basename(entity.path)}: $e',
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            if (isDirectory) ...[
              if (widget.enableCreateFileOption) 
                ListTile(
                  leading: const Icon(Icons.note_add),
                  title: const Text('New file'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateRenameDialog(entity: entity, isFolder: false);
                  },
                ),
              if (widget
                  .enableCreateFolderOption) 
                ListTile(
                  leading: const Icon(Icons.create_new_folder),
                  title: const Text('New folder'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateRenameDialog(entity: entity, isFolder: true);
                  },
                ),
            ],
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showCreateRenameDialog(entity: entity, isRename: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy path'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: entity.path));
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDirectoryTree(
    Directory directory,
    DirectoryTreeStateNotifier stateNotifier,
  ) {
    final entries = directory.listSync();
    entries.sort((a, b) {
      if (a is Directory && b is File) return -1;
      if (a is File && b is Directory) return 1;
      return a.path.compareTo(b.path);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onSecondaryTapDown: (details) {
            if (widget.onDirSecondaryTap != null) {
              widget.onDirSecondaryTap!(directory, details);
            }
          },
          onLongPress: () {
            _showBottomSheet(context, directory);
          },
          onTap: () {
            stateNotifier.toggleFolder(directory.path, widget.rootPath);
            currentDir = directory.path;
            if (directory.path == widget.rootPath) {
              setState(() {
                isParentOpen = !isParentOpen;
              });
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(
              children: [
                directory.path != widget.rootPath
                    ? (stateNotifier.isUnfolded(directory.path, widget.rootPath)
                          ? widget.folderStyle?.folderOpenedicon ??
                                const Icon(Icons.arrow_drop_down)
                          : widget.folderStyle?.folderClosedicon ??
                                const Icon(Icons.arrow_right))
                    : isParentOpen
                    ? widget.folderStyle?.rootFolderOpenedIcon ??
                          const Icon(Icons.arrow_drop_down)
                    : widget.folderStyle?.rootFolderClosedIcon ??
                          const Icon(Icons.arrow_right),
                const SizedBox(width: 8),
                Text(
                  path.basename(directory.path),
                  style:
                      widget.folderStyle?.folderNameStyle ??
                      const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        if (stateNotifier.isUnfolded(directory.path, widget.rootPath))
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...entries.map((entry) {
                  if (entry is Directory) {
                    return _buildDirectoryTree(
                      Directory(entry.path),
                      stateNotifier,
                    );
                  } else if (entry is File) {
                    return _buildFileItem(entry);
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFileItem(File file) {
    return GestureDetector(
      onTap: () {
        final details = TapDownDetails();
        if (widget.onFileTap != null) {
          widget.onFileTap!(file, details);
        }
      },
      onSecondaryTapDown: (details) {
        if (widget.onFileSecondaryTap != null) {
          widget.onFileSecondaryTap!(file, details);
        }
      },
      onLongPress: () {
        _showBottomSheet(context, file);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          children: [
            getIconForFile(file),
            const SizedBox(width: 8),
            Text(
              path.basename(file.path),
              style:
                  widget.fileStyle?.fileNameStyle ??
                  const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateNotifier = DirectoryTreeStateProvider.of(context);
    stateNotifier.watchDirectory(widget.rootPath);
    final rootDirectory = Directory(widget.rootPath);

    if (!rootDirectory.existsSync()) {
      return const Center(child: Text('Directory does not exist'));
    }

    return SingleChildScrollView(
      child: _buildDirectoryTree(rootDirectory, stateNotifier),
    );
  }
}
