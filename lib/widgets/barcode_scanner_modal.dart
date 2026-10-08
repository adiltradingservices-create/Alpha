import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerModal extends StatefulWidget {
  final String title;
  final bool continuousMode;
  final ValueChanged<List<String>> onScanned;

  const BarcodeScannerModal({
    super.key,
    this.title = 'Scan Hardware Barcode / QR',
    this.continuousMode = false,
    required this.onScanned,
  });

  static Future<List<String>?> show(
    BuildContext context, {
    String title = 'Scan Hardware Barcode / QR',
    bool continuousMode = false,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BarcodeScannerModal(
        title: title,
        continuousMode: continuousMode,
        onScanned: (results) => Navigator.pop(ctx, results),
      ),
    );
  }

  @override
  State<BarcodeScannerModal> createState() => _BarcodeScannerModalState();
}

class _BarcodeScannerModalState extends State<BarcodeScannerModal> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final List<String> _scannedCodes = [];
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        if (widget.continuousMode) {
          if (!_scannedCodes.contains(raw)) {
            setState(() {
              _scannedCodes.insert(0, raw);
            });
          }
        } else {
          widget.onScanned([raw]);
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF030712),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        widget.continuousMode
                            ? 'Batch Mode: Multiple serials can be captured'
                            : 'Single Snap: Point reticle at 1D Barcode or 2D QR',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 7.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: _torchOn ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  tooltip: 'Flashlight',
                  onPressed: () {
                    _controller.toggleTorch();
                    setState(() => _torchOn = !_torchOn);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFFFB7185), size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),

          // Camera Viewfinder Box
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: _handleDetect,
                  ),
                ),
                // Scanner Targeting Reticle
                Container(
                  width: 260,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF10B981), width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _cornerPiece(top: true, left: true),
                          _cornerPiece(top: true, left: false),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _cornerPiece(top: false, left: true),
                          _cornerPiece(top: false, left: false),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Continuous Scan Tray (if enabled)
          if (widget.continuousMode)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF0B132B),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SCANNED HARDWARE SERIALS (${_scannedCodes.length})',
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (_scannedCodes.isNotEmpty)
                          TextButton(
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                            onPressed: () => setState(() => _scannedCodes.clear()),
                            child: const Text('CLEAR ALL', style: TextStyle(color: Color(0xFFFB7185), fontSize: 7)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: _scannedCodes.isEmpty
                          ? const Center(
                              child: Text(
                                'Align camera over barcodes to populate serial list...',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 8),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _scannedCodes.length,
                              itemBuilder: (ctx, idx) {
                                final code = _scannedCodes[idx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF161F30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.qr_code_2_rounded, color: Color(0xFF10B981), size: 14),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          code,
                                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFB7185), size: 14),
                                        onPressed: () => setState(() => _scannedCodes.removeAt(idx)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 16),
                        label: Text(
                          'CONFIRM ${_scannedCodes.length} SERIAL CODES',
                          style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                        onPressed: _scannedCodes.isEmpty ? null : () => widget.onScanned(_scannedCodes),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cornerPiece({required bool top, required bool left}) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Color(0xFF10B981), width: 3) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Color(0xFF10B981), width: 3) : BorderSide.none,
          left: left ? const BorderSide(color: Color(0xFF10B981), width: 3) : BorderSide.none,
          right: !left ? const BorderSide(color: Color(0xFF10B981), width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}
