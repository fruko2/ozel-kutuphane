import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/utils/isbn.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.ean13],
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _returning = false;
  String _status = 'Kitabın arka kapağındaki 978 veya 979 ile başlayan barkodu çerçevede tutun.';

  Future<void> _detected(BarcodeCapture capture) async {
    if (_returning) return;
    for (final barcode in capture.barcodes) {
      final value = Isbn.normalize(barcode.rawValue ?? '');
      if (!Isbn.isValid(value)) continue;
      _returning = true;
      setState(() => _status = 'Barkod okundu: $value');
      await _controller.stop();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context, value);
      return;
    }
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final capture = await _controller.analyzeImage(file.path);
    if (capture == null || capture.barcodes.isEmpty) {
      if (mounted) setState(() => _status = 'Fotoğrafta geçerli ISBN barkodu bulunamadı.');
      return;
    }
    await _detected(capture);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071914),
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF071914),
        title: const Text('ISBN Barkod Okuyucu'),
        leading: IconButton(
          tooltip: 'Kapat',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Fener',
            icon: const Icon(Icons.flashlight_on_rounded),
            onPressed: _controller.toggleTorch,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(controller: _controller, onDetect: _detected),
                  Center(
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * .82,
                      height: 125,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFFFE8A8), width: 3),
                        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 28, spreadRadius: 999)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              color: const Color(0xFF102D25),
              child: Column(
                children: [
                  Text(_status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, height: 1.45)),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Fotoğraftan okut'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

