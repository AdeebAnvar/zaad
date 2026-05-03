import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos/core/utils/image_utils.dart';
import 'package:pos/data/local/drift_database.dart';

/// Renders a catalog [Item] from [localImagePath] when the file exists; otherwise
/// shows the server [imagePath] (absolute or resolved with API base), then a placeholder.
class CatalogItemImage extends StatelessWidget {
  const CatalogItemImage({
    super.key,
    required this.item,
    this.fit = BoxFit.cover,
  });

  final Item item;
  final BoxFit fit;

  static Widget _placeholder() {
    return ColoredBox(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.fastfood, size: 40, color: Colors.black38),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = item.localImagePath?.trim();
    if (local != null && local.isNotEmpty) {
      final file = File(p.normalize(local));
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          errorBuilder: (_, __, ___) => _RemoteOrPlaceholder(item: item, fit: fit),
        );
      }
    }
    return _RemoteOrPlaceholder(item: item, fit: fit);
  }
}

class _RemoteOrPlaceholder extends StatelessWidget {
  const _RemoteOrPlaceholder({required this.item, required this.fit});

  final Item item;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final s = item.imagePath?.trim() ?? '';
    if (s.startsWith('http://') || s.startsWith('https://')) {
      return Image.network(
        s,
        fit: fit,
        errorBuilder: (_, __, ___) => CatalogItemImage._placeholder(),
      );
    }
    if (s.isNotEmpty) {
      return _ResolvedUrlImage(relativeOrAbsolute: s, fit: fit);
    }
    return CatalogItemImage._placeholder();
  }
}

/// One-shot resolve relative image URLs (same as sync download) then [Image.network].
class _ResolvedUrlImage extends StatefulWidget {
  const _ResolvedUrlImage({required this.relativeOrAbsolute, required this.fit});

  final String relativeOrAbsolute;
  final BoxFit fit;

  @override
  State<_ResolvedUrlImage> createState() => _ResolvedUrlImageState();
}

class _ResolvedUrlImageState extends State<_ResolvedUrlImage> {
  String? _url;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final base = prefs.getString('baseUrl') ?? '';
    final u = ImageUtils.resolveToAbsoluteImageUrl(
      widget.relativeOrAbsolute,
      baseUrlOverride: base,
    );
    if (!mounted) return;
    setState(() {
      _url = u;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_done) {
      return CatalogItemImage._placeholder();
    }
    if (_url == null || _url!.isEmpty) {
      return CatalogItemImage._placeholder();
    }
    return Image.network(
      _url!,
      fit: widget.fit,
      errorBuilder: (_, __, ___) => CatalogItemImage._placeholder(),
    );
  }
}
