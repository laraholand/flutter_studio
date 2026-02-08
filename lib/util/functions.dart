import 'package:flutter/material.dart';

Widget buildButton({
  required double width,
  required IconData icon,
  required String text,
  required VoidCallback onPressed,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: SizedBox(
      width: width,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(text),
        ),
      ),
    ),
  );
}
