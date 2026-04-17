import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../alarm/domain/entities/expected_code.dart';

enum CodeFormat {
  qr('QR code', 'qrCode'),
  code128('Code 128', 'code128'),
  ean13('EAN-13', 'ean13');

  const CodeFormat(this.label, this.scannerName);
  final String label;

  /// Must match `mobile_scanner`'s `BarcodeFormat.name` so [ExpectedCode]
  /// round-trips correctly against what the scanner will produce.
  final String scannerName;
}

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({this.returnAsCode = false, super.key});

  final bool returnAsCode;

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final _controller = TextEditingController(text: 'fajarly-123456');
  final _boundaryKey = GlobalKey();
  CodeFormat _format = CodeFormat.qr;
  int _ecLevel = QrErrorCorrectLevel.M;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate() {
    final text = _controller.text.trim();
    if (text.isEmpty) return 'Enter some content first';
    if (_format == CodeFormat.ean13) {
      final digitsOnly = RegExp(r'^\d{12,13}$');
      if (!digitsOnly.hasMatch(text)) {
        return 'EAN-13 needs exactly 12 or 13 digits';
      }
    }
    return null;
  }

  Future<Uint8List> _renderPng() async {
    if (_format == CodeFormat.qr) {
      // QR renders crisper via QrPainter at arbitrary resolution.
      final painter = QrPainter(
        data: _controller.text,
        version: QrVersions.auto,
        errorCorrectionLevel: _ecLevel,
        gapless: false,
        color: Colors.black,
        emptyColor: Colors.white,
      );
      final image = await painter.toImageData(1024, format: ui.ImageByteFormat.png);
      if (image == null) throw StateError('Failed to render QR code');
      return image.buffer.asUint8List();
    }
    // Barcodes: capture the on-screen widget via RepaintBoundary at 4× DPR.
    final boundary =
        _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 4.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw StateError('Failed to render barcode');
    return byteData.buffer.asUint8List();
  }

  Future<String> _writeTempPng(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/fajarly-${DateTime.now().millisecondsSinceEpoch}.png';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  Future<void> _runAction(Future<void> Function() action) async {
    final err = _validate();
    if (err != null) {
      _snack(err);
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _snack('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() => _runAction(() async {
        final bytes = await _renderPng();
        final path = await _writeTempPng(bytes);
        await Gal.putImage(path);
        _snack('Saved to gallery');
      });

  Future<void> _share() => _runAction(() async {
        final bytes = await _renderPng();
        await Share.shareXFiles(
          [XFile.fromData(bytes, mimeType: 'image/png', name: 'fajarly-code.png')],
          text: 'My Fajarly unlock code',
        );
      });

  Future<void> _print() => _runAction(() async {
        final bytes = await _renderPng();
        await Printing.layoutPdf(onLayout: (_) async => _buildPdf(bytes));
      });

  void _useAsCode() {
    final err = _validate();
    if (err != null) {
      _snack(err);
      return;
    }
    context.pop(ExpectedCode(
      value: _controller.text.trim(),
      formatName: _format.scannerName,
    ));
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate code')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 4)),
                ],
              ),
              child: RepaintBoundary(
                key: _boundaryKey,
                child: _Preview(
                  format: _format,
                  data: _controller.text.isEmpty ? ' ' : _controller.text,
                  ecLevel: _ecLevel,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Format', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<CodeFormat>(
            segments: CodeFormat.values
                .map((f) => ButtonSegment(value: f, label: Text(f.label)))
                .toList(),
            selected: {_format},
            onSelectionChanged: (s) => setState(() => _format = s.first),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              labelText: 'Content',
              helperText: switch (_format) {
                CodeFormat.qr => 'Any text, URL, or ID — this becomes the unlock key.',
                CodeFormat.code128 =>
                  'Any ASCII text or number — this becomes the unlock key.',
                CodeFormat.ean13 =>
                  'Exactly 12 or 13 digits — the checksum is generated automatically.',
              },
              border: const OutlineInputBorder(),
            ),
          ),
          if (_format == CodeFormat.qr) ...[
            const SizedBox(height: 20),
            Text('Error correction', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: QrErrorCorrectLevel.L, label: Text('L · 7%')),
                ButtonSegment(value: QrErrorCorrectLevel.M, label: Text('M · 15%')),
                ButtonSegment(value: QrErrorCorrectLevel.Q, label: Text('Q · 25%')),
                ButtonSegment(value: QrErrorCorrectLevel.H, label: Text('H · 30%')),
              ],
              selected: {_ecLevel},
              onSelectionChanged: (s) => setState(() => _ecLevel = s.first),
            ),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ActionChip(icon: Icons.save_alt, label: 'Save', onTap: _busy ? null : _save),
              _ActionChip(icon: Icons.ios_share, label: 'Share', onTap: _busy ? null : _share),
              _ActionChip(icon: Icons.print, label: 'Print', onTap: _busy ? null : _print),
            ],
          ),
          if (widget.returnAsCode) ...[
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _busy ? null : _useAsCode,
              icon: const Icon(Icons.check),
              label: const Text('Use this as unlock code'),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.format, required this.data, required this.ecLevel});
  final CodeFormat format;
  final String data;
  final int ecLevel;

  @override
  Widget build(BuildContext context) {
    switch (format) {
      case CodeFormat.qr:
        return QrImageView(
          data: data,
          version: QrVersions.auto,
          errorCorrectionLevel: ecLevel,
          size: 240,
          backgroundColor: Colors.white,
        );
      case CodeFormat.code128:
        return SizedBox(
          width: 280,
          height: 140,
          child: BarcodeWidget(
            barcode: Barcode.code128(),
            data: data,
            drawText: true,
            backgroundColor: Colors.white,
            color: Colors.black,
          ),
        );
      case CodeFormat.ean13:
        final cleaned = data.replaceAll(RegExp(r'\D'), '');
        if (cleaned.length < 12) {
          return const SizedBox(
            width: 280,
            height: 140,
            child: Center(child: Text('Enter 12–13 digits')),
          );
        }
        return SizedBox(
          width: 280,
          height: 140,
          child: BarcodeWidget(
            barcode: Barcode.ean13(),
            data: cleaned.length == 13 ? cleaned : cleaned.substring(0, 12),
            drawText: true,
            backgroundColor: Colors.white,
            color: Colors.black,
          ),
        );
    }
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

Future<Uint8List> _buildPdf(Uint8List pngBytes) async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Center(
        child: pw.Image(pw.MemoryImage(pngBytes), width: 400, height: 400),
      ),
    ),
  );
  return pdf.save();
}
