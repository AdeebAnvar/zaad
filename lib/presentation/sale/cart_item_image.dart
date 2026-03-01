import 'dart:io';

import 'package:flutter/material.dart';

class CartItemImage extends StatelessWidget {
  final String? path;

  const CartItemImage({this.path});

  @override
  Widget build(BuildContext context) {
    final hasImage = path != null && path!.isNotEmpty && File(path!).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 60,
        height: 60,
        color: Colors.grey.shade200,
        child: hasImage ? Image.file(File(path!), fit: BoxFit.cover) : const Icon(Icons.fastfood, color: Colors.grey),
      ),
    );
  }
}
