import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/config/pos_app_runtime_config.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/network/base_url_resolver.dart';
import 'package:pos/core/network/pos_hub_auth.dart';
import 'package:pos/core/network/pos_server_settings.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Host / admin: show QR so other devices can join LOCAL mode without typing IPs.
class QrGenerateScreen extends StatefulWidget {
  const QrGenerateScreen({super.key});

  @override
  State<QrGenerateScreen> createState() => _QrGenerateScreenState();
}

class _QrGenerateScreenState extends State<QrGenerateScreen> {
  String? _qrJson;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _buildPayloadAsync();
  }

  Future<void> _buildPayloadAsync() async {
    try {
      final cfg = locator<PosAppRuntimeConfig>();
      final hub = locator<PosServerSettings>();
      final primaryNorm =
          cfg.primaryLanBaseUrl ?? BaseUrlResolver.hostUrlFromPreferred();
      final primary = PosServerSettings.normalizeRoot(primaryNorm);

      String? fallback = cfg.fallbackBaseUrl;
      if (fallback == null || fallback.trim().isEmpty) {
        final snap = hub.hubRoot;
        if (snap != null && snap.isNotEmpty) {
          final n = PosServerSettings.normalizeRoot(snap);
          if (n != primary) fallback = n;
        }
      } else {
        fallback = PosServerSettings.normalizeRoot(fallback);
        if (fallback == primary) fallback = null;
      }

      final payload = <String, dynamic>{
        'mode': 'LOCAL',
        'base_url': primary,
        'fallback_ip': fallback ?? '',
        'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
      final hubTok = (await locator<PosHubAuth>().bearerToken())?.trim();
      if (hubTok != null && hubTok.isNotEmpty) {
        payload['hub_token'] = hubTok;
      }
      setState(() {
        _qrJson = jsonEncode(payload);
        _loadError = null;
      });
    } catch (e) {
      setState(() {
        _qrJson = null;
        _loadError = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connect devices', style: AppStyles.getSemiBoldTextStyle(fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textColor,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_loadError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Could not build QR: $_loadError',
                    textAlign: TextAlign.center,
                    style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.red.shade800),
                  ),
                ),
              if (_qrJson != null) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: QrImageView(
                      data: _qrJson!,
                      version: QrVersions.auto,
                      size: 250,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Scan this QR from the other device',
                  textAlign: TextAlign.center,
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  _qrJson!,
                  style: AppStyles.getRegularTextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
