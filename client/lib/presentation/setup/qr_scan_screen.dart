import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/routes.dart';
import 'package:pos/core/config/app_mode.dart';
import 'package:pos/core/config/pos_app_runtime_config.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/network/base_url_resolver.dart';
import 'package:pos/core/network/pos_hub_auth.dart';
import 'package:pos/core/network/pos_server_settings.dart';
import 'package:pos/presentation/setup/setup_hub_socket.dart';

/// Scan LOCAL setup QR → persist prefs → validate hub → go to login.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  late final MobileScannerController _controller;
  bool _handled = false;
  bool _busy = false;
  String? _error;
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    _requestCamera();
  }

  Future<void> _requestCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() {
        _error = 'Camera permission is required to scan the QR code.';
        _cameraReady = false;
      });
      return;
    }
    setState(() {
      _cameraReady = true;
      _error = null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processCapture(BarcodeCapture capture) async {
    if (_handled || _busy || !mounted) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue ?? barcodes.first.displayValue;
    if (raw == null || raw.trim().isEmpty) return;

    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(raw.trim());
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return;
    }

    if (data == null) return;
    final mode = data['mode']?.toString();
    if (mode != 'LOCAL') return;

    setState(() {
      _busy = true;
      _error = null;
    });
    _handled = true;
    await _controller.stop();

    final primary = BaseUrlResolver.normalizeLanHubUrl(data['base_url']?.toString());
    if (primary == null || primary.isEmpty) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Invalid QR: missing or bad base_url.';
          _handled = false;
        });
      }
      await _controller.start();
      return;
    }

    final fbRaw = data['fallback_ip']?.toString();
    final fallback = BaseUrlResolver.normalizeLanHubUrl(
      (fbRaw != null && fbRaw.trim().isNotEmpty) ? fbRaw : null,
    );

    final cfg = locator<PosAppRuntimeConfig>();
    final hub = locator<PosServerSettings>();
    final resolver = locator<BaseUrlResolver>();

    try {
      await cfg.setMode(AppMode.local);
      await cfg.setPrimaryLanBaseUrl(primary);
      if (fallback != null && fallback.isNotEmpty) {
        await cfg.setFallbackUrl(fallback);
      } else {
        await cfg.clearFallbackBaseUrl();
      }

      final resolved = await resolver.resolveLocalBaseUrl().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Health check timed out'),
          );
      await hub.setBaseUrl(resolved);
      final hubTok = data['hub_token']?.toString().trim();
      if (hubTok != null && hubTok.isNotEmpty) {
        await locator<PosHubAuth>().setBearerToken(hubTok);
      }
      await cfg.markSetupCompleted();
      cfg.logDiagnostics();
      debugPrint('[POS] QR setup OK → hub $resolved');
      await applyHubSocketAfterLocalSetupChange();

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (_) => false);
    } catch (e) {
      debugPrint('[POS] QR setup failed: $e');
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Cannot reach POS server. Check Wi‑Fi and try again.\n$e';
          _handled = false;
        });
      }
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR', style: AppStyles.getSemiBoldTextStyle(fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.red.shade800),
              ),
            ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_cameraReady)
                  MobileScanner(
                    controller: _controller,
                    onDetect: (BarcodeCapture c) => unawaited(_processCapture(c)),
                  )
                else
                  Center(
                    child: _error != null
                        ? TextButton(
                            onPressed: _requestCamera,
                            child: const Text('Grant camera access'),
                          )
                        : const CircularProgressIndicator(),
                  ),
                if (_busy)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Point the camera at the QR on the main POS machine.',
              textAlign: TextAlign.center,
              style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.hintFontColor),
            ),
          ),
        ],
      ),
    );
  }
}
