import 'package:flutter/material.dart';
import '../code_forge.dart';
import 'package:flutter_studio/util/page_type.dart';

class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final UndoRedoController? currentUndoController;
  final bool isModified;
  final bool isEmpty;
  final bool isAppRunning;
  final VoidCallback onSave;
  final VoidCallback onRun;
  final VoidCallback onStop;
  final VoidCallback onHotReload;
  final VoidCallback onHotRestart;
  final VoidCallback onTerminal;
  final VoidCallback onSync;
  final VoidCallback onBuildOptions;
  final VoidCallback onCancel;
  final VoidCallback onPreviewReload;
  final VoidCallback onEdit;
  final VoidCallback onCreateNewTerminalSession;
  final PageType pageType;

  const EditorAppBar({
    super.key,
    this.currentUndoController,
    required this.isModified,
    required this.isEmpty,
    required this.isAppRunning,
    required this.onSave,
    required this.onRun,
    required this.onStop,
    required this.onHotReload,
    required this.onHotRestart,
    required this.onTerminal,
    required this.onSync,
    required this.onBuildOptions,
    required this.onCancel,
    required this.onPreviewReload,
    required this.onEdit,
    required this.onCreateNewTerminalSession,
    required this.pageType,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      actions: [
        if (pageType == PageType.EDITOR) ...[
          if (!isEmpty)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
          if (currentUndoController != null) ...[
            ListenableBuilder(
              listenable: currentUndoController!,
              builder: (context, child) {
                return IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: currentUndoController!.canUndo
                      ? () => currentUndoController!.undo()
                      : null,
                  tooltip: 'Undo',
                );
              },
            ),
            ListenableBuilder(
              listenable: currentUndoController!,
              builder: (context, child) {
                return IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: currentUndoController!.canRedo
                      ? () => currentUndoController!.redo()
                      : null,
                  tooltip: 'Redo',
                );
              },
            ),
          ],
          if (!isEmpty && isModified)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: onSave,
              tooltip: 'Save',
            ),
          if (isEmpty) ...[
            if (!isAppRunning) ...[
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: onRun,
                tooltip: 'Run',
              ),
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: onSync,
                tooltip: 'Sync',
              ),
              IconButton(
                icon: const Icon(Icons.terminal),
                onPressed: onTerminal,
                tooltip: 'Terminal',
              ),
            ] else ...[
              IconButton(
                icon: Image.asset(
                  'assets/icons/flash.png', 
                  width: 24,
                  height: 24,
                  color: Colors.yellow, 
                ),
                onPressed: onHotReload,
                tooltip: 'Hot Reload',
              ),
              IconButton(
                icon: const Icon(Icons.restart_alt),
                onPressed: onHotRestart,
                tooltip: 'Hot Restart',
              ),
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: onStop,
                tooltip: 'Stop App',
              ),
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: onSync,
                tooltip: 'Sync',
              ),
              IconButton(
                icon: const Icon(Icons.terminal),
                onPressed: onTerminal,
                tooltip: 'Terminal',
              ),
            ],
          ] else ...[
            if (!isAppRunning) ...[
              PopupMenuButton<String>(
                onSelected: (String result) {
                  switch (result) {
                    case 'run_app':
                      onRun();
                      break;
                    case 'open_terminal':
                      onTerminal();
                      break;
                    case 'sync_project':
                      onSync();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'run_app',
                    child: GestureDetector(
                      onLongPress: onBuildOptions,
                      child: const Row(
                        children: [
                          Icon(Icons.play_arrow),
                          SizedBox(width: 8),
                          Text('Run'),
                        ],
                      ),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'open_terminal',
                    child: Row(
                      children: [
                        Icon(Icons.terminal),
                        SizedBox(width: 8),
                        Text('Terminal'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'sync_project',
                    child: Row(
                      children: [
                        Icon(Icons.sync),
                        SizedBox(width: 8),
                        Text('Sync'),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              IconButton(
                icon: Image.asset(
                  'assets/icons/flash.png', 
                  width: 24,
                  height: 24,
                  color: Colors.yellow, 
                ),
                onPressed: onHotReload,
                tooltip: 'Hot Reload',
              ),

              PopupMenuButton<String>(
                onSelected: (String result) {
                  switch (result) {
                    case 'stop_app':
                      onStop();
                      break;
                    case 'open_terminal':
                      onTerminal();
                      break;
                    case 'sync_project':
                      onSync();
                      break;
                    case 'hot_restart': 
                      onHotRestart();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'stop_app',
                    child: Row(
                      children: [
                        Icon(Icons.stop),
                        SizedBox(width: 8),
                        Text('Stop'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'open_terminal',
                    child: Row(
                      children: [
                        Icon(Icons.terminal),
                        SizedBox(width: 8),
                        Text('Terminal'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'sync_project',
                    child: Row(
                      children: [
                        Icon(Icons.sync),
                        SizedBox(width: 8),
                        Text('Sync'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    
                    value: 'hot_restart',
                    child: Row(
                      children: [
                        Icon(Icons.restart_alt),
                        SizedBox(width: 8),
                        Text('Hot Restart'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ] else if (pageType == PageType.PREVIEW) ...[
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: onCancel,
            tooltip: 'Cancel',
          ),
          IconButton(
            icon: const Icon(Icons.loop),
            onPressed: onHotReload,
            tooltip: 'Reload',
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: onCancel,
            tooltip: 'Cancel',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onCreateNewTerminalSession,
            tooltip: 'Create new Terminal',
          ),
        ],
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
