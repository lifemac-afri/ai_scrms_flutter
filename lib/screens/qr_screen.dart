import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';

class QrScreen extends StatefulWidget {
  final bool active;
  const QrScreen({super.key, this.active = false});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  MobileScannerController? _ctrl;
  bool _scanned = false;
  bool _loading = false;
  String? _result;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _initController();
    }
  }

  @override
  void didUpdateWidget(QrScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _initController();
    } else if (!widget.active && oldWidget.active) {
      _disposeController();
    }
  }

  void _initController() {
    if (_ctrl != null) return;
    setState(() {
      _ctrl = MobileScannerController();
    });
  }

  void _disposeController() {
    _ctrl?.dispose();
    _ctrl = null;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned || _loading || _ctrl == null) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    setState(() { _scanned = true; _loading = true; });
    await _ctrl!.stop();
    final res = await ApiService.checkIn(code);
    if (mounted) {
      setState(() {
        _loading = false;
        _success = res['success'] == true;
        _result = _success
            ? res['message'] ?? 'Checked in successfully!'
            : res['error'] ?? 'Check-in failed';
      });
    }
  }

  void _reset() {
    setState(() { _scanned = false; _loading = false; _result = null; _success = false; });
    _ctrl?.start();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SectionHeader(
            title: 'QR Check-In',
            subtitle: 'Scan your booking QR code to check in',
          ),
          const SizedBox(height: 16),
          if (_result != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (_success ? AppTheme.green : AppTheme.red).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: (_success ? AppTheme.green : AppTheme.red).withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Icon(_success ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      size: 48, color: _success ? AppTheme.green : AppTheme.red),
                  const SizedBox(height: 12),
                  Text(
                    _result!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _success ? AppTheme.green : AppTheme.red,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _reset,
                    child: const Text('Scan Another'),
                  ),
                ],
              ),
            )
          else if (_loading)
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.teal),
                    SizedBox(height: 16),
                    Text('Verifying check-in…', style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 300,
                child: Stack(
                  children: [
                    if (_ctrl != null)
                      MobileScanner(controller: _ctrl!, onDetect: _onDetect)
                    else
                      const Center(
                        child: CircularProgressIndicator(color: AppTheme.teal),
                      ),
                    // Overlay
                    Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.teal, width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('Point camera at QR code',
                              style: TextStyle(color: Colors.white, fontSize: 13),
                              textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.teal.withValues(alpha: 0.2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How to Check In',
                    style: TextStyle(
                        color: AppTheme.teal, fontWeight: FontWeight.w700, fontSize: 14)),
                SizedBox(height: 8),
                Text('1. Open My Bookings and tap the QR Code button',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 4),
                Text('2. Show your QR code to this scanner',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 4),
                Text('3. Check-in opens 15 min before your booking',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 4),
                Text('4. You have a 15-min window after start time',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
