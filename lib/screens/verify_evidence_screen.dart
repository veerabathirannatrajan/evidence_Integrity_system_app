// verify_evidence_screen.dart
// Premium Glassmorphism UI — fully responsive (mobile + tablet + desktop)
// All original logic 100% preserved. UI transformed.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

// ── Breakpoints ───────────────────────────────────────────────
const double _kMobile = 600;
const double _kTablet = 1024;

// ── Design tokens ─────────────────────────────────────────────
const Color _kGreen    = Color(0xFF059669);
const Color _kBlue     = Color(0xFF2563EB);
const Color _kPurple   = Color(0xFF7C3AED);
const Color _kRed      = Color(0xFFDC2626);
const Color _kRedLight = Color(0xFFEF4444);
const Color _kBgBase   = Color(0xFFEEF2FF);
const Color _kBorderIdle = Color(0xFFD1D5DB);

class VerifyEvidenceScreen extends StatefulWidget {
  final String? evidenceId;
  const VerifyEvidenceScreen({super.key, this.evidenceId});

  @override
  State<VerifyEvidenceScreen> createState() => _VerifyEvidenceScreenState();
}

class _VerifyEvidenceScreenState extends State<VerifyEvidenceScreen>
    with TickerProviderStateMixin {

  // ── Original state (all preserved) ───────────────────────────
  final _api    = ApiService();
  final _idCtrl = TextEditingController();
  PlatformFile? _file;
  bool _verifying = false;
  Map<String, dynamic>? _result;
  String? _error;

  // ── Animations ────────────────────────────────────────────────
  late AnimationController _entryCtrl;
  late AnimationController _bgCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _resultCtrl;
  late Animation<double>   _opacity;
  late Animation<Offset>   _slide;
  late Animation<double>   _bgAnim;
  late Animation<double>   _pulse;
  late Animation<double>   _resultOpacity;
  late Animation<Offset>   _resultSlide;

  bool _dropHovered = false;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _opacity   = _entryCtrl.drive(Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: const Interval(0, 0.7))));
    _slide     = _entryCtrl.drive(Tween(begin: const Offset(0, 0.04), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)));
    _entryCtrl.forward();

    _bgCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
    _bgAnim  = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulse     = _pulseCtrl.drive(Tween(begin: 0.94, end: 1.06).chain(CurveTween(curve: Curves.easeInOut)));

    _resultCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _resultOpacity = _resultCtrl.drive(Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)));
    _resultSlide   = _resultCtrl.drive(Tween(begin: const Offset(0, 0.06), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)));

    if (widget.evidenceId != null) _idCtrl.text = widget.evidenceId!;
    _idCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _entryCtrl.dispose(); _bgCtrl.dispose();
    _pulseCtrl.dispose(); _resultCtrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }

  // ── Original logic (all preserved exactly) ───────────────────
  Future<void> _pick() async {
    final r = await FilePicker.platform.pickFiles(
        type: FileType.any, withData: true, allowMultiple: false);
    if (r != null && r.files.isNotEmpty) {
      setState(() { _file = r.files.first; _result = null; _error = null; });
    }
  }

  Future<void> _verify() async {
    final id = _idCtrl.text.trim();
    if (id.isEmpty)    { setState(() => _error = 'Enter the Evidence ID'); return; }
    if (_file == null) { setState(() => _error = 'Select the file to verify'); return; }
    final bytes = _file!.bytes;
    if (bytes == null) { setState(() => _error = 'Could not read file'); return; }

    setState(() { _verifying = true; _error = null; _result = null; });
    _resultCtrl.reset();

    try {
      final res = await _api.verifyEvidenceBytes(
          bytes, _file!.name, id,
          mimeType: _mime(_file!.extension ?? ''));
      if (mounted) {
        setState(() { _result = res; _verifying = false; });
        _resultCtrl.forward();
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Verification failed: $e'; _verifying = false; });
    }
  }

  String _mime(String e) {
    switch (e.toLowerCase()) {
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png':  return 'image/png';
      case 'pdf':  return 'application/pdf';
      case 'mp4':  return 'video/mp4';
      case 'mp3':  return 'audio/mpeg';
      default:     return 'application/octet-stream';
    }
  }

  String _sz(int b) {
    if (b < 1024)    return '$b B';
    if (b < 1048576) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / 1048576).toStringAsFixed(1)} MB';
  }

  String _sh(String h) {
    if (h.length <= 20) return h;
    return '${h.substring(0, 10)}...${h.substring(h.length - 8)}';
  }

  void _copy(String t, String l) {
    Clipboard.setData(ClipboardData(text: t));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$l copied'),
      backgroundColor: _kGreen,
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgBase,
      body: Stack(children: [
        Positioned.fill(child: _AnimBg(anim: _bgAnim)),
        SafeArea(child: FadeTransition(opacity: _opacity,
            child: SlideTransition(position: _slide,
                child: Column(children: [
                  _buildAppBar(),
                  Expanded(child: _buildBody()),
                ])))),
      ]),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(height: 60, padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.70),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5)))),
        child: Row(children: [
          _ABBtn(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
          const SizedBox(width: 8),
          Container(width: 32, height: 32,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [_kGreen, Color(0xFF0D9488)])),
              child: const Icon(Icons.verified_outlined, color: Colors.white, size: 16)),
          const SizedBox(width: 10),
          const Flexible(child: Text('Verify Evidence Integrity',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.3))),
          const Spacer(),
          // Status badge
          AnimatedBuilder(animation: _pulse, builder: (_, __) =>
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _kGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kGreen.withOpacity(0.28))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Transform.scale(scale: _pulse.value,
                        child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle))),
                    const SizedBox(width: 5),
                    const Text('Blockchain Ready', style: TextStyle(color: _kGreen, fontSize: 10, fontWeight: FontWeight.w600)),
                  ]))),
          const SizedBox(width: 8),
        ]),
      ),
    ));
  }

  // ── Responsive body ────────────────────────────────────────────
  Widget _buildBody() {
    return LayoutBuilder(builder: (_, constraints) {
      final w        = constraints.maxWidth;
      final isMobile = w < _kMobile;
      final isTablet = w >= _kMobile && w < _kTablet;

      if (isMobile) {
        return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
            child: Column(children: [
              _infoBanner(),
              const SizedBox(height: 14),
              _step1Card(),
              const SizedBox(height: 14),
              _step2Card(),
              if (_error != null) ...[const SizedBox(height: 12), _errorCard()],
              const SizedBox(height: 14),
              _verifyButton(),
              if (_result != null) ...[const SizedBox(height: 16), _resultCard()],
              const SizedBox(height: 14),
              _stepsPanel(),
              const SizedBox(height: 14),
              _rolesPanel(),
            ]));
      }

      if (isTablet) {
        return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: Column(children: [
                _infoBanner(),
                const SizedBox(height: 14),
                _step1Card(),
                const SizedBox(height: 14),
                _step2Card(),
                if (_error != null) ...[const SizedBox(height: 12), _errorCard()],
                const SizedBox(height: 14),
                _verifyButton(),
                if (_result != null) ...[const SizedBox(height: 16), _resultCard()],
              ])),
              const SizedBox(width: 16),
              SizedBox(width: 230, child: Column(children: [
                _stepsPanel(),
                const SizedBox(height: 14),
                _rolesPanel(),
              ])),
            ]));
      }

      // Desktop — split layout
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 3, child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
            child: Column(children: [
              _infoBanner(),
              const SizedBox(height: 18),
              _step1Card(),
              const SizedBox(height: 18),
              _step2Card(),
              if (_error != null) ...[const SizedBox(height: 14), _errorCard()],
              const SizedBox(height: 18),
              _verifyButton(),
              if (_result != null) ...[const SizedBox(height: 20), _resultCard()],
            ]))),
        Container(width: 1, color: Colors.white.withOpacity(0.5)),
        SizedBox(width: 290, child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 24, 20, 40),
            child: Column(children: [
              _stepsPanel(),
              const SizedBox(height: 16),
              _rolesPanel(),
              const SizedBox(height: 16),
              _hashInfoPanel(),
            ]))),
      ]);
    });
  }

  // ── Info Banner ────────────────────────────────────────────────
  Widget _infoBanner() {
    return _GlassCard(tint: const Color(0xFFF0F9FF), child: Padding(padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 34, height: 34,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [_kBlue, Color(0xFF4F46E5)])),
              child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 17)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('How Verification Works',
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(
              'Re-upload the original file. The system computes its SHA-256 hash and '
                  'compares it with the hash stored in MongoDB and anchored on the Polygon '
                  'blockchain. Even a single-bit change will be detected immediately.',
              style: TextStyle(color: const Color(0xFF475569).withOpacity(0.9), fontSize: 12, height: 1.6),
            ),
          ])),
        ])));
  }

  // ── Step 1: Evidence ID ────────────────────────────────────────
  Widget _step1Card() {
    return _GlassCard(child: Padding(padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _StepHeader(num: '1', label: 'Enter Evidence ID', icon: Icons.tag_rounded, color: _kBlue),
          const SizedBox(height: 14),
          TextField(
            controller: _idCtrl,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'e.g. 69b6b565ff08af25b2a44aa0',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              prefixIcon: Container(margin: const EdgeInsets.all(10), width: 30, height: 30,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                      color: _idCtrl.text.isNotEmpty ? _kBlue.withOpacity(0.08) : const Color(0xFFF3F4F6)),
                  child: Icon(Icons.tag_rounded, size: 15,
                      color: _idCtrl.text.isNotEmpty ? _kBlue : const Color(0xFF9CA3AF))),
              helperText: 'Find the Evidence ID in the Blockchain Viewer or evidence detail page.',
              helperStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
              filled: true,
              fillColor: Colors.white.withOpacity(0.70),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorderIdle, width: 1.2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorderIdle, width: 1.2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBlue, width: 2.0)),
            ),
          ),
        ])));
  }

  // ── Step 2: File ───────────────────────────────────────────────
  Widget _step2Card() {
    return _GlassCard(child: Padding(padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _StepHeader(num: '2', label: 'Upload the Same File', icon: Icons.upload_file_outlined, color: _kPurple),
          const SizedBox(height: 14),
          _file == null ? _dropZone() : _fileTile(),
        ])));
  }

  Widget _dropZone() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _dropHovered = true),
      onExit:  (_) => setState(() => _dropHovered = false),
      child: GestureDetector(onTap: _pick,
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36),
          decoration: BoxDecoration(
            color: _dropHovered ? _kPurple.withOpacity(0.05) : Colors.white.withOpacity(0.42),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: _dropHovered ? _kPurple.withOpacity(0.5) : _kBorderIdle,
                width: 1.8),
            boxShadow: _dropHovered
                ? [BoxShadow(color: _kPurple.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(children: [
            AnimatedContainer(duration: const Duration(milliseconds: 200),
                width: 62, height: 62,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: _dropHovered ? _kPurple.withOpacity(0.14) : _kPurple.withOpacity(0.07)),
                child: Icon(Icons.cloud_upload_outlined, size: 28,
                    color: _dropHovered ? _kPurple : _kPurple.withOpacity(0.65))),
            const SizedBox(height: 14),
            const Text('Click to select the original file',
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            const Text('Upload the exact same file that was originally submitted',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
            const SizedBox(height: 16),
            AnimatedContainer(duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: _dropHovered ? const LinearGradient(colors: [_kPurple, Color(0xFF4F46E5)]) : null,
                  color: _dropHovered ? null : _kPurple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kPurple.withOpacity(0.3)),
                ),
                child: Text('Browse Files',
                    style: TextStyle(
                        color: _dropHovered ? Colors.white : _kPurple,
                        fontSize: 13, fontWeight: FontWeight.w700))),
          ]),
        ),
      ),
    );
  }

  Widget _fileTile() {
    final f = _file!;
    return AnimatedContainer(duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPurple.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kPurple.withOpacity(0.28), width: 1.5),
        boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(width: 48, height: 48,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [_kPurple, Color(0xFF4F46E5)]),
                boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))]),
            child: const Icon(Icons.insert_drive_file_outlined, size: 22, color: Colors.white)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f.name, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: _kPurple.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
                child: Text((f.extension ?? 'file').toUpperCase(),
                    style: const TextStyle(color: _kPurple, fontSize: 9, fontWeight: FontWeight.w700))),
            const SizedBox(width: 8),
            Text(_sz(f.size), style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
          ]),
        ])),
        const SizedBox(width: 8),
        _iconBtn(Icons.edit_outlined,    _kBlue,     _pick),
        const SizedBox(width: 6),
        _iconBtn(Icons.close_rounded,    _kRedLight, () => setState(() { _file = null; _result = null; })),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
          child: Container(width: 32, height: 32,
              decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.2))),
              child: Icon(icon, size: 15, color: color)));

  // ── Error Card ─────────────────────────────────────────────────
  Widget _errorCard() {
    return _GlassCard(tint: const Color(0xFFFEF2F2), child: Padding(padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: _kRedLight.withOpacity(0.1)),
              child: const Icon(Icons.error_outline_rounded, color: _kRedLight, size: 17)),
          const SizedBox(width: 10),
          Expanded(child: Text(_error!, style: const TextStyle(color: _kRed, fontSize: 13))),
          GestureDetector(onTap: () => setState(() => _error = null),
              child: const Icon(Icons.close_rounded, color: _kRedLight, size: 16)),
        ])));
  }

  // ── Verify Button ──────────────────────────────────────────────
  Widget _verifyButton() {
    final canVerify = _file != null && _idCtrl.text.isNotEmpty && !_verifying;
    return Container(width: double.infinity, height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: canVerify ? const LinearGradient(colors: [_kGreen, Color(0xFF0D9488)]) : null,
        color: canVerify ? null : _kGreen.withOpacity(0.35),
        boxShadow: canVerify ? [BoxShadow(color: _kGreen.withOpacity(0.38), blurRadius: 18, offset: const Offset(0, 6))] : [],
      ),
      child: Material(color: Colors.transparent,
        child: InkWell(onTap: canVerify ? _verify : null,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withOpacity(0.15),
          child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            _verifying
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Icon(Icons.verified_outlined, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              _verifying ? 'Verifying integrity...'
                  : _file == null ? 'Select a file first'
                  : 'Verify Evidence Integrity',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ])),
        ),
      ),
    );
  }

  // ── Result Card ────────────────────────────────────────────────
  Widget _resultCard() {
    final r    = _result!;
    final ok   = r['status'] == 'VERIFIED';
    final col  = ok ? _kGreen : _kRed;
    final tint = ok ? const Color(0xFFF0FDF4) : const Color(0xFFFFF1F2);

    final originalHash = r['originalHash'] as String? ?? r['hash'] as String? ?? '';
    final newHash      = r['newHash']      as String? ?? '';
    final txHash       = r['blockchainTxHash'] as String? ?? '';

    return FadeTransition(opacity: _resultOpacity,
        child: SlideTransition(position: _resultSlide,
            child: _GlassCard(tint: tint, child: Padding(padding: const EdgeInsets.all(22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // ── Status Header ──────────────────────────────
                  Row(children: [
                    // Animated icon
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (_, v, child) => Transform.scale(scale: v, child: child),
                      child: Container(width: 56, height: 56,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [col, col.withOpacity(0.75)]),
                              boxShadow: [BoxShadow(color: col.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))]),
                          child: Icon(ok ? Icons.verified_rounded : Icons.warning_amber_rounded,
                              size: 28, color: Colors.white)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(ok ? 'VERIFIED' : 'TAMPERED',
                          style: TextStyle(color: col, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 3),
                      Text(ok ? 'Evidence integrity confirmed' : '⚠️  Evidence has been compromised',
                          style: TextStyle(color: col.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                    ])),
                    // Result badge
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [col, col.withOpacity(0.8)]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: col.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]),
                        child: Text(ok ? '✓ INTACT' : '✗ CHANGED',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
                  ]),

                  const SizedBox(height: 20),
                  Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(
                      colors: [col.withOpacity(0.3), Colors.transparent]))),
                  const SizedBox(height: 16),

                  // ── Detail rows ────────────────────────────────
                  _resRow('Evidence ID',  r['evidenceId'] as String? ?? '—',       copy: r['evidenceId'] as String?),
                  _resRow('File Name',    r['fileName']   as String? ?? '—'),
                  _resRow('Hash Match',
                      (r['hashMatch'] == true) ? '✓ Hashes match' : '✗ Hash mismatch',
                      valColor: r['hashMatch'] == true ? _kGreen : _kRed),
                  _resRow('Blockchain',
                      r['blockchainValid'] == true  ? '✓ Valid on Polygon Amoy'
                          : r['blockchainValid'] == false ? '✗ Invalid on-chain'
                          : '⏳ Pending blockchain anchor',
                      valColor: r['blockchainValid'] == true  ? _kGreen
                          : r['blockchainValid'] == false ? _kRed
                          : const Color(0xFFD97706)),

                  if (!ok && originalHash.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _resRow('Original Hash', _sh(originalHash), mono: true, copy: originalHash),
                    if (newHash.isNotEmpty)
                      _resRow('New Hash', _sh(newHash), mono: true, copy: newHash, valColor: _kRed),
                  ],
                  if (ok && originalHash.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _resRow('SHA-256 Hash', _sh(originalHash), mono: true, copy: originalHash),
                  ],
                  if (txHash.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _resRow('TX Hash', _sh(txHash), mono: true, copy: txHash),
                  ],

                  const SizedBox(height: 20),

                  // ── Action buttons ─────────────────────────────
                  Row(children: [
                    Expanded(child: _OutlineBtn(label: 'Verify Another', icon: Icons.refresh_rounded, color: col,
                        onTap: () => setState(() {
                          _file = null; _result = null;
                          if (widget.evidenceId == null) _idCtrl.clear();
                        }))),
                    const SizedBox(width: 10),
                    Expanded(child: _GradBtn(label: 'Dashboard', icon: Icons.dashboard_outlined,
                        color: col, onTap: () => Navigator.pop(context))),
                  ]),
                ])))));
  }

  Widget _resRow(String label, String value, {String? copy, bool mono = false, Color? valColor}) =>
      Padding(padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(width: 100, child: Text(label,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11))),
            Expanded(child: Text(value, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: valColor ?? const Color(0xFF0F172A), fontSize: 12,
                    fontWeight: FontWeight.w600, fontFamily: mono ? 'monospace' : null))),
            if (copy != null && copy.isNotEmpty)
              GestureDetector(onTap: () => _copy(copy, label),
                  child: const Padding(padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.copy_outlined, size: 12, color: Color(0xFF9CA3AF)))),
          ]));

  // ── Right Panel: Steps ─────────────────────────────────────────
  Widget _stepsPanel() {
    return _GlassCard(child: Padding(padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _PanelHdr(icon: Icons.info_outline_rounded, label: 'Verification Steps', color: _kBlue),
          const SizedBox(height: 14),
          ...[
            ['1', 'Enter the Evidence ID'],
            ['2', 'Upload the original file'],
            ['3', 'SHA-256 hash computed from bytes'],
            ['4', 'Hash compared with MongoDB record'],
            ['5', 'Verified against Polygon blockchain'],
            ['6', 'VERIFIED or TAMPERED result shown'],
          ].map((s) => Padding(padding: const EdgeInsets.only(bottom: 11),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 20, height: 20,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [_kGreen, Color(0xFF0D9488)])),
                    child: Center(child: Text(s[0], style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)))),
                const SizedBox(width: 10),
                Expanded(child: Text(s[1], style: const TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.45))),
              ]))),
        ])));
  }

  // ── Right Panel: Roles ─────────────────────────────────────────
  Widget _rolesPanel() {
    return _GlassCard(tint: const Color(0xFFF5F3FF), child: Padding(padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _PanelHdr(icon: Icons.people_outline_rounded, label: 'Who Can Verify', color: _kPurple),
          const SizedBox(height: 12),
          ...[
            ['🚔', 'Police Officer',    _kBlue],
            ['🔬', 'Forensic Expert',   _kPurple],
            ['⚖️',  'Prosecutor',       _kGreen],
            ['🛡️', 'Defense Attorney',  const Color(0xFF0284C7)],
            ['🏛️', 'Court Official',    const Color(0xFFD97706)],
          ].map((r) => Padding(padding: const EdgeInsets.only(bottom: 9),
              child: Row(children: [
                Container(width: 32, height: 32,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                        color: (r[2] as Color).withOpacity(0.08)),
                    child: Center(child: Text(r[0] as String, style: const TextStyle(fontSize: 14)))),
                const SizedBox(width: 10),
                Text(r[1] as String, style: const TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600)),
              ]))),
        ])));
  }

  // ── Right Panel: Hash Info ─────────────────────────────────────
  Widget _hashInfoPanel() {
    return _GlassCard(tint: const Color(0xFFF0FDF4), child: Padding(padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _PanelHdr(icon: Icons.fingerprint_rounded, label: 'SHA-256 Fingerprint', color: _kGreen),
          const SizedBox(height: 12),
          const Text(
            'SHA-256 produces a unique 64-character hex digest for every file. '
                'Even a 1-byte change produces a completely different hash — '
                'making tampering instantly detectable.',
            style: TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.55),
          ),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _kGreen.withOpacity(0.06), borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kGreen.withOpacity(0.2))),
              child: Row(children: [
                const Icon(Icons.lock_outline_rounded, size: 14, color: _kGreen),
                const SizedBox(width: 8),
                Expanded(child: Text('Anchored on Polygon Amoy blockchain — immutable proof.',
                    style: TextStyle(color: _kGreen.withOpacity(0.85), fontSize: 11, height: 1.45))),
              ])),
        ])));
  }
}

// ─────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────

class _AnimBg extends StatelessWidget {
  final Animation<double> anim;
  const _AnimBg({required this.anim});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: anim, builder: (_, __) {
    final t = anim.value;
    return Container(color: _kBgBase, child: Stack(children: [
      Positioned(left: -120 + t * 70, top: -90 + t * 50, child: _orb(320, _kGreen,  0.11)),
      Positioned(right: -80 + t * 40, bottom: 30 + t * 80, child: _orb(260, _kBlue, 0.09)),
      Positioned(left: MediaQuery.of(context).size.width * 0.4,
          top: MediaQuery.of(context).size.height * 0.3 - t * 50,
          child: _orb(190, _kPurple, 0.08)),
    ]));
  });
  Widget _orb(double sz, Color c, double op) => Container(width: sz, height: sz,
      decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [c.withOpacity(op), c.withOpacity(0)])));
}

class _GlassCard extends StatelessWidget {
  final Widget child; final Color? tint;
  const _GlassCard({required this.child, this.tint});
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.07), blurRadius: 22, offset: const Offset(0, 7), spreadRadius: -2),
            BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 1, offset: const Offset(0, -1))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.65), width: 1.3),
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [(tint ?? Colors.white).withOpacity(0.90), (tint ?? Colors.white).withOpacity(0.58)])),
                  child: child))));
}

class _StepHeader extends StatelessWidget {
  final String num, label; final IconData icon; final Color color;
  const _StepHeader({required this.num, required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 30, height: 30,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(colors: [color, color.withOpacity(0.75)])),
        child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)))),
    const SizedBox(width: 10),
    Icon(icon, size: 16, color: color),
    const SizedBox(width: 7),
    Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w700))),
    const SizedBox(width: 12),
    Expanded(child: Container(height: 1,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.35), Colors.transparent])))),
  ]);
}

class _PanelHdr extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _PanelHdr({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 28, height: 28,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: color.withOpacity(0.08)),
        child: Icon(icon, size: 14, color: color)),
    const SizedBox(width: 9),
    Text(label, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700)),
  ]);
}

class _GradBtn extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap;
  const _GradBtn({required this.label, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(height: 44,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
          color: color,
          boxShadow: [BoxShadow(color: color.withOpacity(0.32), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Material(color: Colors.transparent,
          child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 15, color: Colors.white), const SizedBox(width: 7),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ]))));
}

class _OutlineBtn extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(height: 44,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.65),
          border: Border.all(color: color.withOpacity(0.35), width: 1.5)),
      child: Material(color: Colors.transparent,
          child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 15, color: color), const SizedBox(width: 7),
                Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
              ]))));
}

class _ABBtn extends StatefulWidget {
  final IconData icon; final VoidCallback onTap;
  const _ABBtn({required this.icon, required this.onTap});
  @override State<_ABBtn> createState() => _ABBtnState();
}
class _ABBtnState extends State<_ABBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: GestureDetector(onTap: widget.onTap,
          child: AnimatedContainer(duration: const Duration(milliseconds: 150),
              width: 38, height: 38,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                  color: _h ? _kGreen.withOpacity(0.08) : Colors.transparent,
                  border: Border.all(color: _h ? _kGreen.withOpacity(0.2) : Colors.transparent)),
              child: Icon(widget.icon, size: 20, color: _h ? _kGreen : const Color(0xFF475569)))));
}