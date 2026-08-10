import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yallasplit_app/core/config/app_theme.dart';
import 'package:yallasplit_app/features/addition/presentation/providers/scan_receipt_notifier.dart';
import '../providers/addition_providers.dart';

class ScanReceiptScreen extends ConsumerStatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  ConsumerState<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends ConsumerState<ScanReceiptScreen> {
  final _picker = ImagePicker();
  Uint8List? _previewBytes;

  Future<void> _capture(ImageSource source) async {
    final xfile = await _picker.pickImage(source: source, imageQuality: 85);
    if (xfile == null) return;

    final bytes = await xfile.readAsBytes();
    setState(() => _previewBytes = bytes);

    if (!mounted) return;
    await ref.read(scanReceiptProvider.notifier).scan(bytes, xfile.name);

    if (!mounted) return;
    final state = ref.read(scanReceiptProvider);

    if (state.status == ScanStatus.scanned) {
      context.push('/review-items');
    } else if (state.status == ScanStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage ?? 'Échec de la lecture du reçu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanReceiptProvider);
    final isScanning = scanState.status == ScanStatus.scanning;

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildPreviewArea(),
                  Positioned.fromRelativeRect(
                    rect: RelativeRect.fromLTRB(40, 60, 40, 60),
                    child: IgnorePointer(child: _buildCornerFrame()),
                  ),
                  if (isScanning)
                    Positioned(
                      bottom: 24,
                      child: _buildStatusPill('Reading items · Arabic & English'),
                    ),
                ],
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleButton(
            icon: Icons.close,
            onTap: () => context.pop(),
          ),
          Text('Scan receipt', style: AppTextStyles.h2),
          _circleButton(icon: Icons.flash_on_outlined, onTap: () {}),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.text, size: 20),
      ),
    );
  }

  Widget _buildPreviewArea() {
    if (_previewBytes == null) {
      return Container(
        margin: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Icon(Icons.receipt_long_outlined, color: AppColors.muted.withValues(alpha: 0.4), size: 64),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: MemoryImage(_previewBytes!), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildCornerFrame() {
    return CustomPaint(painter: _CornerFramePainter());
  }

  Widget _buildStatusPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppColors.actionGradient,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final isScanning = ref.watch(scanReceiptProvider).status == ScanStatus.scanning;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleButton(
            icon: Icons.photo_library_outlined,
            onTap: isScanning ? () {} : () => _capture(ImageSource.gallery),
          ),
          GestureDetector(
            onTap: isScanning ? null : () => _capture(ImageSource.camera),
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              ),
            ),
          ),
          _circleButton(icon: Icons.text_fields, onTap: () {}),
        ],
      ),
    );
  }
}

class _CornerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.violet
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 24.0;
    final w = size.width;
    final h = size.height;

    // Coin haut-gauche
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, len), paint);
    // Coin haut-droit
    canvas.drawLine(Offset(w, 0), Offset(w - len, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, len), paint);
    // Coin bas-gauche
    canvas.drawLine(Offset(0, h), Offset(len, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - len), paint);
    // Coin bas-droit
    canvas.drawLine(Offset(w, h), Offset(w - len, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}