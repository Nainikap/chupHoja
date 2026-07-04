import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final File imageFile;

  const ResultScreen({
    super.key,
    required this.result,
    required this.imageFile,
  });

  Color get _severityColor => Color(
    int.parse((result['severity_color'] as String).replaceFirst('#', '0xFF')),
  );

  @override
  Widget build(BuildContext context) {
    final int grade = result['grade'];
    final String gradeLabel = result['grade_label'];
    final double confidence = (result['confidence'] as num).toDouble();
    final String referral = result['referral'];
    final bool lowConfidence = result['low_confidence'];
    final List<dynamic> probs = result['probabilities'];
    final String gradcamB64 = result['gradcam_b64'];

    final gradeLabels = [
      'No DR',
      'Mild DR',
      'Moderate DR',
      'Severe DR',
      'Proliferative DR',
    ];
    final gradeColors = [
      const Color(0xFF2D9E6B),
      const Color(0xFFF0A500),
      const Color(0xFFE67E22),
      const Color(0xFFE74C3C),
      const Color(0xFF8E44AD),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0FAF4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A5C3A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Screening Result',
          style: TextStyle(
            color: Color(0xFF1A5C3A),
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Grade badge ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: _severityColor.withOpacity(0.1),
                border: Border.all(color: _severityColor.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Grade circle
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _severityColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$grade',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gradeLabel,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: _severityColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${confidence.toStringAsFixed(1)}% confidence',
                          style: TextStyle(
                            fontSize: 14,
                            color: _severityColor.withOpacity(0.8),
                          ),
                        ),
                        if (lowConfidence) ...[
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 13,
                                color: Color(0xFFF0A500),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Low confidence — seek second opinion',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFF0A500),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Referral recommendation ────────────────────────────────
            _Card(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.local_hospital_outlined,
                    color: _severityColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Referral Recommendation',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: Color(0xFF1A5C3A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          referral,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2D5C42),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Grad-CAM heatmap ───────────────────────────────────────
            if (gradcamB64.isNotEmpty) ...[
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.biotech_outlined,
                          color: Color(0xFF2D9E6B),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Retinal Heatmap',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: Color(0xFF1A5C3A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Red regions indicate areas that influenced the prediction.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7AAB90)),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        base64Decode(gradcamB64),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── Per-grade probability bars ─────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        color: Color(0xFF2D9E6B),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Confidence per Grade',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Color(0xFF1A5C3A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(5, (i) {
                    final pct = (probs[i] as num).toDouble();
                    final isTop = i == grade;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(
                              gradeLabels[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isTop
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isTop
                                    ? gradeColors[i]
                                    : const Color(0xFF3B7A57),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 8,
                                backgroundColor: const Color(0xFFE0F5EB),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isTop
                                      ? gradeColors[i]
                                      : const Color(
                                          0xFF2D9E6B,
                                        ).withOpacity(0.4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 42,
                            child: Text(
                              '${pct.toStringAsFixed(1)}%',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isTop
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isTop
                                    ? gradeColors[i]
                                    : const Color(0xFF3B7A57),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Disclaimer ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F7EF),
                border: Border.all(color: const Color(0xFFA3D9BB), width: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFF2D9E6B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This result is a screening aid only. It does not constitute a clinical diagnosis. Please refer to a qualified ophthalmologist for confirmation.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2A6644),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Retake button ──────────────────────────────────────────
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                label: const Text('Screen another patient'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2D9E6B),
                  side: const BorderSide(color: Color(0xFF2D9E6B)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB6DFC8), width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}
