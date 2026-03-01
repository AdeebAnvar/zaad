import 'package:flutter/material.dart';

Future<String?> showServerUrlDialog(BuildContext context) async {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Server URL"),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: "Enter server URL",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, controller.text.trim());
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}
