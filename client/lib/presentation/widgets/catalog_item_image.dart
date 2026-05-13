import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

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
          gaplessPlayback: true,
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
        gaplessPlayback: true,
        key: ValueKey<String>('net|$s'),
        errorBuilder: (_, __, ___) => CatalogItemImage._placeholder(),
      );
    }
    if (s.isNotEmpty) {
      return _ResolvedUrlImage(relativeOrAbsolute: s, fit: fit);
    }
    return CatalogItemImage._placeholder();
  }
}

/// Resolves relative paths once [TenantImageUrlCache] has base URL; avoids placeholder
/// flicker on every GridView rebuild when switching categories.
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
    final immediate = TenantImageUrlCache.resolveWhenBaseReady(widget.relativeOrAbsolute);
    if (immediate != null) {
      _url = immediate;
      _done = true;
    } else {
      TenantImageUrlCache.ensureBaseUrlLoaded().then((_) {
        if (!mounted) return;
        setState(() {
          _url = TenantImageUrlCache.resolveWhenBaseReady(widget.relativeOrAbsolute);
          _done = true;
        });
      });
    }
  }

  @override
  void didUpdateWidget(_ResolvedUrlImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.relativeOrAbsolute != widget.relativeOrAbsolute) {
      final immediate = TenantImageUrlCache.resolveWhenBaseReady(widget.relativeOrAbsolute);
      if (immediate != null) {
        setState(() {
          _url = immediate;
          _done = true;
        });
      } else {
        setState(() {
          _done = false;
        });
        TenantImageUrlCache.ensureBaseUrlLoaded().then((_) {
          if (!mounted) return;
          setState(() {
            _url = TenantImageUrlCache.resolveWhenBaseReady(widget.relativeOrAbsolute);
            _done = true;
          });
        });
      }
    }
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
      gaplessPlayback: true,
      key: ValueKey<String>('net|$_url'),
      errorBuilder: (_, __, ___) => CatalogItemImage._placeholder(),
    );
  }
}
