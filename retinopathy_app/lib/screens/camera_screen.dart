import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'result_screen.dart';
import 'package:retinopathy/services/api_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    _controller = CameraController(
      _cameras!.first,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
    if (!mounted) return;

    setState(() => _isInitialized = true);
  }

  Future<void> _toggleTorch() async {
    if (_controller == null) return;
    _isTorchOn = !_isTorchOn;
    await _controller!.setFlashMode(
      _isTorchOn ? FlashMode.torch : FlashMode.off,
    );
    setState(() {});
  }

  Future<void> _captureAndPredict() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final XFile image = await _controller!.takePicture();
      await _sendToBackend(File(image.path));
    } catch (e) {
      _showError('Failed to capture image: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    await _sendToBackend(File(image.path));
  }

  Future<void> _sendToBackend(File imageFile) async {
    setState(() => _isCapturing = true);

    try {
      final result = await ApiService.predict(imageFile);

      if (!mounted) return;

      // Quality check failed — show retake prompt
      if (!result['quality_ok']) {
        _showRetakeDialog(result['quality_msg']);
        return;
      }

      // Navigate to result screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(result: result, imageFile: imageFile),
        ),
      );
    } catch (e) {
      _showError(
        'Could not connect to server. Check your network and try again.',
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _showRetakeDialog(String reason) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF0A500)),
            SizedBox(width: 8),
            Text('Retake Required', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Text(reason, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF2D9E6B))),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Camera preview ──────────────────────────────────────────
            if (_isInitialized && _controller != null)
              Positioned.fill(child: CameraPreview(_controller!))
            else
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF2D9E6B)),
              ),

            // ── Retinal alignment guide overlay ─────────────────────────
            if (_isInitialized)
              Positioned.fill(
                child: CustomPaint(painter: _AlignmentOverlayPainter()),
              ),

            // ── Top bar ─────────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Align retina within circle',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const Spacer(),
                    // Torch toggle
                    GestureDetector(
                      onTap: _toggleTorch,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _isTorchOn
                              ? const Color(0xFF2D9E6B)
                              : Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isTorchOn
                              ? Icons.flashlight_on
                              : Icons.flashlight_off,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom controls ─────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 36),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Gallery button
                    GestureDetector(
                      onTap: _isCapturing ? null : _pickFromGallery,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),

                    // Capture button
                    GestureDetector(
                      onTap: _isCapturing ? null : _captureAndPredict,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCapturing ? Colors.white38 : Colors.white,
                          border: Border.all(
                            color: const Color(0xFF2D9E6B),
                            width: 3,
                          ),
                        ),
                        child: _isCapturing
                            ? const Padding(
                                padding: EdgeInsets.all(18),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF2D9E6B),
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_outlined,
                                color: Color(0xFF1A5C3A),
                                size: 30,
                              ),
                      ),
                    ),

                    // Placeholder to balance layout
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            // ── Loading overlay ─────────────────────────────────────────
            if (_isCapturing)
              Positioned.fill(
                child: Container(
                  color: Colors.black45,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF2D9E6B)),
                        SizedBox(height: 16),
                        Text(
                          'Analysing retinal image…',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Alignment overlay painter ─────────────────────────────────────────────────

class _AlignmentOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width * 0.38;

    // Dim everything outside the circle
    final outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: radius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(outerPath, Paint()..color = Colors.black.withOpacity(0.5));

    // Green guide circle
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = const Color(0xFF2D9E6B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Corner tick marks
    const tickLen = 16.0;
    final tickPaint = Paint()
      ..color = const Color(0xFF2D9E6B)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final offsets = [
      [cx - radius * 0.7, cy - radius * 0.7],
      [cx + radius * 0.7, cy - radius * 0.7],
      [cx - radius * 0.7, cy + radius * 0.7],
      [cx + radius * 0.7, cy + radius * 0.7],
    ];
    for (final o in offsets) {
      canvas.drawLine(
        Offset(o[0] - tickLen / 2, o[1]),
        Offset(o[0] + tickLen / 2, o[1]),
        tickPaint,
      );
      canvas.drawLine(
        Offset(o[0], o[1] - tickLen / 2),
        Offset(o[0], o[1] + tickLen / 2),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
