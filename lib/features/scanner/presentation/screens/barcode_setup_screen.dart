import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../alarm/domain/entities/expected_code.dart';

class BarcodeSetupScreen extends StatefulWidget {
  const BarcodeSetupScreen({super.key});

  @override
  State<BarcodeSetupScreen> createState() => _BarcodeSetupScreenState();
}

class _BarcodeSetupScreenState extends State<BarcodeSetupScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    // Explicit list so it's obvious we accept both QR and linear barcodes.
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.codabar,
      BarcodeFormat.itf,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.pdf417,
      BarcodeFormat.aztec,
    ],
  );
  ExpectedCode? _captured;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_captured != null) return;
    for (final b in capture.barcodes) {
      final value = b.rawValue;
      if (value == null || value.isEmpty) continue;
      setState(() {
        _captured = ExpectedCode(value: value, formatName: b.format.name);
      });
      _controller.stop();
      return;
    }
  }

  Future<void> _toggleTorch() => _controller.toggleTorch();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan any QR or barcode'),
        actions: [
          IconButton(
            tooltip: 'Toggle flashlight',
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          const Align(
            alignment: Alignment.topCenter,
            child: _TopHint(),
          ),
          const Center(child: _Viewfinder()),
          if (_captured != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _CapturedSheet(
                code: _captured!,
                onRescan: () {
                  setState(() => _captured = null);
                  _controller.start();
                },
                onSave: () => context.pop(_captured),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopHint extends StatelessWidget {
  const _TopHint();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Point at a product barcode (shampoo, book, food) or a printed QR code.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 3),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

class _CapturedSheet extends StatelessWidget {
  const _CapturedSheet({
    required this.code,
    required this.onRescan,
    required this.onSave,
  });
  final ExpectedCode code;
  final VoidCallback onRescan;
  final VoidCallback onSave;

  String get _friendlyFormat {
    switch (code.formatName) {
      case 'qrCode':
        return 'QR code';
      case 'ean13':
        return 'EAN-13 barcode';
      case 'ean8':
        return 'EAN-8 barcode';
      case 'upcA':
        return 'UPC-A barcode';
      case 'upcE':
        return 'UPC-E barcode';
      case 'code128':
        return 'Code 128 barcode';
      case 'code39':
        return 'Code 39 barcode';
      case 'code93':
        return 'Code 93 barcode';
      case 'codabar':
        return 'Codabar';
      case 'itf':
        return 'ITF barcode';
      case 'dataMatrix':
        return 'Data Matrix';
      case 'pdf417':
        return 'PDF417';
      case 'aztec':
        return 'Aztec code';
      default:
        return code.formatName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Detected  ·  $_friendlyFormat',
                  style: Theme.of(context).textTheme.labelLarge),
            ]),
            const SizedBox(height: 10),
            Text(
              code.value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: onRescan, child: const Text('Rescan'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: onSave, child: const Text('Save as unlock code'))),
            ]),
          ],
        ),
      ),
    );
  }
}
