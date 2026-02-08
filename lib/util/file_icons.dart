import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as path;

Widget getIconForFile(File file) {
  final extension = path.extension(file.path).toLowerCase().replaceAll('.', '');

  const Map<String, String> extensionToIconName = {
    'dart': 'dart',
    'js': 'javascript',
    'ts': 'typescript',
    'py': 'python',
    'java': 'java',
    'c': 'c',
    'cpp': 'cplusplus',
    'cs': 'csharp',
    'html': 'html5',
    'css': 'css3',
    'scss': 'sass',
    'json': 'json',
    'xml': 'xml',
    'yaml': 'yaml',
    'md': 'markdown',
    'gitignore': 'git',
    'lock': 'yarn', 
    'svg': 'svg',
    'png': 'image',
    'jpg': 'image',
    'jpeg': 'image',
    'gif': 'image',
  };

  final iconName = extensionToIconName[extension];

  if (iconName != null) {
    final iconPath = 'assets/icons/$iconName/$iconName-original.svg';
    return SvgPicture.asset(
      iconPath,
      width: 24,
      height: 24,
      placeholderBuilder: (BuildContext context) =>
          const Icon(Icons.insert_drive_file, size: 24),
    );
  }

  return const Icon(Icons.insert_drive_file, size: 24);
}
