import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _logoCtrl;
  late AnimationController _rippleCtrl;
  late AnimationController _textCtrl;
  late AnimationController _progressCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset>  _textSlide;
  late Animation<double> _subOpacity;
  late Animation<double> _progressVal;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _rippleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));

    _logoScale = _logoCtrl.drive(
        Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)));
    _logoOpacity = _logoCtrl.drive(
        Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: const Interval(0, 0.4))));
    _textOpacity = _textCtrl.drive(
        Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: const Interval(0, 0.65))));
    _textSlide = _textCtrl.drive(
        Tween(begin: const Offset(0, 0.25), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOut)));
    _subOpacity = _textCtrl.drive(
        Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: const Interval(0.35, 1.0))));
    _progressVal = _progressCtrl.drive(
        Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)));

    _run();
  }

  Future<void> _run() async {
    await Future.delayed(const Duration(milliseconds: 250));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 480));
    _textCtrl.forward();
    _progressCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const LoginScreen(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _rippleCtrl.dispose();
    _textCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [

          // ── Top-right decorative blob ──────────────────
          Positioned(
            top: 0, right: 0,
            child: Container(
              width: 340, height: 260,
              decoration: const BoxDecoration(
                color: Color(0xFFDEEAFF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(280),
                ),
              ),
            ),
          ),

          // ── Bottom-left small blob ─────────────────────
          Positioned(
            bottom: 0, left: 0,
            child: Container(
              width: 200, height: 160,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(200),
                ),
              ),
            ),
          ),

          // ── Centered card content ──────────────────────
          Center(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Logo + ripple centered above text
                  Center(
                    child: AnimatedBuilder(
                      animation: Listenable.merge(
                          [_logoCtrl, _rippleCtrl]),
                      builder: (_, __) {
                        final r = _rippleCtrl.value;
                        final r2 = ((r - 0.2) % 1.0 + 1.0) % 1.0;
                        final r3 = ((r - 0.4) % 1.0 + 1.0) % 1.0;

                        return SizedBox(
                          width: 200, height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Ripple rings
                              _ring(r,  96, 0.05),
                              _ring(r2, 76, 0.10),
                              _ring(r3, 58, 0.16),

                              // Logo
                              Opacity(
                                opacity: _logoOpacity.value,
                                child: Transform.scale(
                                  scale: _logoScale.value,
                                  child: Container(
                                    width: 88, height: 88,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2563EB)
                                              .withOpacity(0.30),
                                          blurRadius: 40,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.shield_rounded,
                                      color: Colors.white,
                                      size: 42,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  FadeTransition(
                    opacity: _textOpacity,
                    child: SlideTransition(
                      position: _textSlide,
                      child: const Text('EvidenceChain',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          )),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Subtitle
                  FadeTransition(
                    opacity: _subOpacity,
                    child: const Text(
                      'Blockchain Evidence Integrity System',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Progress bar + label
                  AnimatedBuilder(
                    animation: _progressCtrl,
                    builder: (_, __) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SizedBox(
                            width: double.infinity,
                            height: 4,
                            child: Stack(children: [
                              Container(color: const Color(0xFFE2E8F0)),
                              FractionallySizedBox(
                                widthFactor: _progressVal.value,
                                child: Container(
                                    color: const Color(0xFF2563EB)),
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Initializing secure environment...',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Version bottom-center ──────────────────────
          const Positioned(
            bottom: 24, left: 0, right: 0,
            child: Text(
              'v1.0.0  •  Powered by Polygon',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double t, double maxR, double maxOpacity) {
    return Container(
      width: maxR * 2 * t,
      height: maxR * 2 * t,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2563EB)
            .withOpacity(maxOpacity * (1 - t)),
      ),
    );
  }
}