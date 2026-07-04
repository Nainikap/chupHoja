import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D9E6B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.remove_red_eye_outlined,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),

              // App name
              const Text(
                'DrishtiAI',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A5C3A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),

              // Tagline
              const Text(
                'Diabetic retinopathy screening for everyone',
                style: TextStyle(fontSize: 15, color: Color(0xFF3B7A57)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Instructions card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFB6DFC8),
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card title
                    Row(
                      children: const [
                        Icon(
                          Icons.checklist_rounded,
                          color: Color(0xFF2D9E6B),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'How it works',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A5C3A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _Step(
                      number: 1,
                      title: 'Attach the clip-on lens',
                      body: 'to your tablet or phone camera before starting.',
                    ),
                    _Step(
                      number: 2,
                      title: 'Position the camera',
                      body:
                          '2–3 cm from the patient\'s eye in a dimly lit room.',
                    ),
                    _Step(
                      number: 3,
                      title: 'Tap "Start screening"',
                      body:
                          'and follow the on-screen alignment guide until the retina is in focus.',
                    ),
                    _Step(
                      number: 4,
                      title: 'Hold still',
                      body:
                          '— the app captures the image automatically when quality is sufficient.',
                    ),
                    _Step(
                      number: 5,
                      title: 'Review the result',
                      body:
                          '— DR grade (0–4), confidence score, and referral recommendation appear in seconds.',
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Disclaimer notice
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EF),
                  border: Border.all(
                    color: const Color(0xFFA3D9BB),
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(
                      Icons.info_outline,
                      size: 17,
                      color: Color(0xFF2D9E6B),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This tool is a screening aid only. It does not replace a clinical diagnosis by a qualified ophthalmologist.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2A6644),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // CTA button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: navigate to camera screen
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen()));
                  },
                  icon: const Icon(Icons.camera_alt_outlined, size: 22),
                  label: const Text(
                    'Start screening',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D9E6B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Footer
              const Text(
                'Ensure the patient\'s consent before capturing\nany retinal images.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7AAB90),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String title;
  final String body;
  final bool isLast;

  const _Step({
    required this.number,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number circle
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F5EB),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A6E42),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Step text
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2D5C42),
                  height: 1.55,
                ),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A5C3A),
                    ),
                  ),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
