import 'package:flutter/material.dart';
import 'package:flutter_studio/code_forge.dart';
import 'package:flutter_studio/util/keys.dart';

class ExtraKeysPanel extends StatelessWidget {
  final CodeForgeController? controller;

  const ExtraKeysPanel({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return const SizedBox.shrink();
    }
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme
          .surface,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: row1Keys.map((key) {
                return KeyButton(keyboardKey: key, controller: controller!);
              }).toList(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: row2Keys.map((key) {
                return KeyButton(keyboardKey: key, controller: controller!);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class KeyButton extends StatelessWidget {
  final dynamic keyboardKey;
  final CodeForgeController controller;

  const KeyButton({
    super.key,
    required this.keyboardKey,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final BorderRadiusGeometry borderRadius = BorderRadius.circular(
      12.0,
    ); 
    return InkWell(
      onTap: () {
        if (keyboardKey == 'Action') {
          controller.getCodeAction();
        } else if (keyboardKey == 'SIGN') {
          controller.callSignatureHelp();
        } else if (keyboardKey == 'TAB') {
          controller.insertAtCurrentCursor("\t");
        } else if (keyboardKey == 'Dup') {
          controller.duplicateLine();
        } else if (keyboardKey == 'ESC') {
        controller.clearAllSuggestions();
        } else if (keyboardKey == Icons.arrow_left) {
          controller.pressLetfArrowKey();
        } else if (keyboardKey == Icons.arrow_right) {
          controller.pressRightArrowKey();
        } else if (keyboardKey == Icons.arrow_upward) {
          controller.pressUpArrowKey();
        } else if (keyboardKey == Icons.arrow_downward) {
          controller.pressDownArrowKey();
        } else if(keyboardKey == "LSP"){}else if (keyboardKey is String) {
          controller.insertAtCurrentCursor(keyboardKey);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme
              .surface, 
          borderRadius: borderRadius,
          border: Border.all(
            color: colorScheme.onPrimary,
            width: 1,
          ), 
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(77),
              spreadRadius: 0.5,
              blurRadius: 0.5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: keyboardKey is String
            ? Text(
                keyboardKey,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                ),
              )
            : Icon(
                keyboardKey,
                size: 18,
                color: colorScheme
                    .onPrimary, 
              ),
      ),
    );
  }
}
