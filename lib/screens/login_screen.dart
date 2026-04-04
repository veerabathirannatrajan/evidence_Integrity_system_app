import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import 'dashboard_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  EVIDENCE CHAIN — Professional Login
//  Right panel: Animated blockchain network visualization
//  No characters, no cartoon elements. Clean + professional.
// ═══════════════════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  // ── Form state (unchanged) ────────────────────────────────────
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  final _auth         = AuthService();
  final _api          = ApiService();

  bool    _isLogin   = true;
  bool    _isLoading = false;
  bool    _obscure   = true;
  bool    _remember  = false;
  String  _role      = 'police';
  String? _error;

  final _roles = const [
    {'value': 'police',     'label': 'Police Officer'},
    {'value': 'forensic',   'label': 'Forensic Expert'},
    {'value': 'prosecutor', 'label': 'Prosecutor'},
    {'value': 'defense',    'label': 'Defense Attorney'},
    {'value': 'court',      'label': 'Court Official'},
  ];

  // ── Animations ────────────────────────────────────────────────
  late AnimationController _entryCtrl;
  late AnimationController _blockchainCtrl; // blockchain network pulse
  late AnimationController _shimmerCtrl;
  late AnimationController _pulseCtrl;      // node pulse rings

  late Animation<double> _fadeAnim;
  late Animation<Offset>  _slideAnim;
  late Animation<double>  _blockchainAnim;
  late Animation<double>  _shimmerAnim;
  late Animation<double>  _pulseAnim;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0, 0.7, curve: Curves.easeOut));
    _slideAnim = Tween(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();

    _blockchainCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _blockchainAnim = Tween(begin: 0.0, end: 1.0).animate(_blockchainCtrl);

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _shimmerAnim = Tween(begin: -1.0, end: 2.0).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _pulseAnim = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _blockchainCtrl.dispose();
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Auth logic (unchanged) ────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      if (_isLogin) {
        await _auth.login(_emailCtrl.text.trim(), _passwordCtrl.text.trim());
        await context.read<UserProvider>().loadFromBackend();
        if (mounted) _nav();
      } else {
        final u = await _auth.register(
            _emailCtrl.text.trim(), _passwordCtrl.text.trim());
        if (u != null) {
          await _api.createUser(u.uid, _nameCtrl.text.trim(),
              _emailCtrl.text.trim(), _role);
          await context.read<UserProvider>().loadFromBackend();
          if (mounted) _nav();
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _msg(e.code));
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nav() => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const DashboardScreen()));

  String _msg(String c) => switch (c) {
    'user-not-found'       => 'No account found with this email.',
    'wrong-password'       => 'Incorrect password.',
    'email-already-in-use' => 'Email already in use.',
    'weak-password'        => 'Password must be at least 6 characters.',
    'invalid-email'        => 'Enter a valid email address.',
    _                      => 'Authentication failed. Please try again.',
  };

  // ── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEDF5),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: LayoutBuilder(builder: (ctx, constraints) {
              final isMobile = constraints.maxWidth < 760;
              return isMobile
                  ? _mobileLayout(constraints)
                  : _desktopLayout(constraints);
            }),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  DESKTOP
  // ─────────────────────────────────────────────────────────────
  Widget _desktopLayout(BoxConstraints c) {
    return Center(
      child: Container(
        width:  math.min(960.0, c.maxWidth  - 48),
        height: math.min(680.0, c.maxHeight - 48),
        decoration: _cardDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 420, child: _formPanel(isMobile: false)),
              Expanded(child: _blockchainPanel()),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  MOBILE
  // ─────────────────────────────────────────────────────────────
  Widget _mobileLayout(BoxConstraints c) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: math.min(420.0, c.maxWidth - 40)),
          child: Container(
            decoration: _cardDecoration(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 200, child: _blockchainPanel()),
                  _formPanel(isMobile: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF4F46E5).withOpacity(0.12),
          blurRadius: 70,
          offset: const Offset(0, 24),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  BLOCKCHAIN ANIMATION PANEL
  // ─────────────────────────────────────────────────────────────
  Widget _blockchainPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF0F172A)],
        ),
      ),
      child: Stack(
        children: [
          // Blockchain network animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _blockchainAnim,
              builder: (_, __) => CustomPaint(
                painter: _BlockchainNetworkPainter(
                    progress: _blockchainAnim.value),
              ),
            ),
          ),

          // Pulse rings on main node
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => CustomPaint(
                painter: _PulseRingPainter(progress: _pulseAnim.value),
              ),
            ),
          ),

          // Text overlay at bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0F172A).withOpacity(0.95),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Evidence Integrity\nBlockchain System',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    _statChip(Icons.link_rounded, 'Immutable Records'),
                    const SizedBox(width: 8),
                    _statChip(Icons.lock_outline_rounded, 'SHA-256'),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: const Color(0xFF818CF8)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            )),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  FORM PANEL
  // ─────────────────────────────────────────────────────────────
  Widget _formPanel({required bool isMobile}) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 28 : 40,
        vertical:   isMobile ? 28 : 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.shield_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EvidenceChain',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    )),
                Text('Blockchain Evidence System',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ]),

          SizedBox(height: isMobile ? 22 : 32),

          // Heading
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Align(
              alignment: Alignment.centerLeft,
              key: ValueKey(_isLogin),
              child: Text(
                _isLogin ? 'Sign in' : 'Create account',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Align(
              alignment: Alignment.centerLeft,
              key: ValueKey('sub$_isLogin'),
              child: Text(
                _isLogin
                    ? 'Access the secure evidence portal'
                    : 'Register your officer credentials',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Form
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isLogin) ...[
                  _fieldBlock(
                    ctrl: _nameCtrl,
                    label: 'Full Name',
                    hint: 'Your full name',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                _fieldBlock(
                  ctrl: _emailCtrl,
                  label: 'Email Address',
                  hint: 'you@example.com',
                  icon: Icons.mail_outline_rounded,
                  type: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _passwordBlock(),

                if (!_isLogin) ...[
                  const SizedBox(height: 16),
                  _roleBlock(),
                ],

                if (_isLogin) ...[
                  const SizedBox(height: 14),
                  _rememberForgotRow(),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _errorBanner(),
                ],

                const SizedBox(height: 24),
                _primaryButton(),
                const SizedBox(height: 10),
                _secondaryButton(),
                const SizedBox(height: 22),

                // Footer
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mail_outline_rounded,
                          size: 13, color: Color(0xFFCBD5E1)),
                      const SizedBox(width: 5),
                      const Text('Help@EvidenceChain.com',
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Form helpers ──────────────────────────────────────────────
  Widget _fieldBlock({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _lbl(label),
        const SizedBox(height: 7),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          validator: validator,
          style: const TextStyle(
              color: Color(0xFF0F172A), fontSize: 14),
          decoration: _deco(hint, icon),
        ),
      ],
    );
  }

  Widget _passwordBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _lbl('Password'),
        const SizedBox(height: 7),
        TextFormField(
          controller: _passwordCtrl,
          obscureText: _obscure,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password required';
            if (!_isLogin && v.length < 6) return 'Min 6 characters';
            return null;
          },
          decoration: _deco(
            '••••••••',
            Icons.lock_outline_rounded,
            suffix: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18, color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _roleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _lbl('Your Role'),
        const SizedBox(height: 7),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _role,
              isExpanded: true,
              isDense: true,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: Color(0xFF9CA3AF)),
              style: const TextStyle(
                  color: Color(0xFF0F172A), fontSize: 14),
              items: _roles.map((r) => DropdownMenuItem(
                value: r['value'],
                child: Row(children: [
                  Icon(_roleIcon(r['value']!),
                      size: 16, color: const Color(0xFF4F46E5)),
                  const SizedBox(width: 10),
                  Text(r['label']!),
                ]),
              )).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _role = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  IconData _roleIcon(String r) => switch (r) {
    'police'     => Icons.local_police_outlined,
    'forensic'   => Icons.biotech_outlined,
    'prosecutor' => Icons.gavel_outlined,
    'defense'    => Icons.balance_outlined,
    'court'      => Icons.account_balance_outlined,
    _            => Icons.person_outline,
  };

  Widget _lbl(String t) => Text(t,
      style: const TextStyle(
        color: Color(0xFF334155),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ));

  InputDecoration _deco(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFFB0B7C3)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFF),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
          vertical: 15, horizontal: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: Color(0xFF4F46E5), width: 1.8)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444))),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: Color(0xFFEF4444), width: 1.8)),
      errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
    );
  }

  Widget _rememberForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          SizedBox(
            width: 17, height: 17,
            child: Checkbox(
              value: _remember,
              onChanged: (v) => setState(() => _remember = v ?? false),
              activeColor: const Color(0xFF4F46E5),
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 7),
          const Text('Remember me',
              style: TextStyle(
                  color: Color(0xFF64748B), fontSize: 12.5)),
        ]),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {},
            child: const Text('Forgot password?',
                style: TextStyle(
                  color: Color(0xFF4F46E5),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ),
      ],
    );
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: Color(0xFFEF4444), size: 15),
        const SizedBox(width: 8),
        Expanded(child: Text(_error!,
            style: const TextStyle(
                color: Color(0xFFDC2626), fontSize: 12.5))),
      ]),
    );
  }

  Widget _primaryButton() {
    return _HoverButton(
      onTap: _isLoading ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          gradient: _isLoading ? null : const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          color: _isLoading
              ? const Color(0xFF4F46E5).withOpacity(0.45) : null,
          boxShadow: _isLoading ? [] : [
            BoxShadow(
              color: const Color(0xFF4F46E5).withOpacity(0.40),
              blurRadius: 20,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(children: [
            if (!_isLoading)
              AnimatedBuilder(
                animation: _shimmerAnim,
                builder: (_, __) => Positioned.fill(
                  child: CustomPaint(
                    painter: _ShimmerPainter(pos: _shimmerAnim.value),
                  ),
                ),
              ),
            Center(
              child: _isLoading
                  ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
                  : Text(
                  _isLogin ? 'Sign In' : 'Create Account',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  )),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _secondaryButton() {
    return _HoverButton(
      onTap: () => setState(() { _isLogin = !_isLogin; _error = null; }),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Center(
          child: Text(
            _isLogin ? 'Create Account' : 'Sign In Instead',
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  BLOCKCHAIN NETWORK PAINTER
//  Draws interconnected nodes with animated data packets flowing
//  along edges — like a real blockchain network visualization.
// ═══════════════════════════════════════════════════════════════════

class _BlockchainNetworkPainter extends CustomPainter {
  final double progress; // 0→1 looping

  _BlockchainNetworkPainter({required this.progress});

  // Fixed node positions (relative 0–1)
  static const _nodes = [
    Offset(0.50, 0.22),  // 0 — center-top (main/genesis)
    Offset(0.20, 0.40),  // 1
    Offset(0.78, 0.38),  // 2
    Offset(0.12, 0.62),  // 3
    Offset(0.45, 0.58),  // 4
    Offset(0.82, 0.60),  // 5
    Offset(0.28, 0.78),  // 6
    Offset(0.65, 0.80),  // 7
    Offset(0.92, 0.30),  // 8
    Offset(0.06, 0.28),  // 9
  ];

  // Edges (pairs of node indices)
  static const _edges = [
    [0, 1], [0, 2], [0, 9],
    [1, 3], [1, 4], [2, 5], [2, 8],
    [3, 6], [4, 6], [4, 7], [5, 7],
    [0, 4], [2, 4], [1, 9],
  ];

  // Colors
  static const _nodeColor   = Color(0xFF4F46E5);
  static const _glowColor   = Color(0xFF818CF8);
  static const _edgeColor   = Color(0xFF312E81);
  static const _packetColor = Color(0xFF818CF8);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    Offset toScreen(Offset rel) => Offset(rel.dx * w, rel.dy * h);

    // ── Draw edges ───────────────────────────────────────────
    for (final edge in _edges) {
      final a = toScreen(_nodes[edge[0]]);
      final b = toScreen(_nodes[edge[1]]);

      // Base edge line
      canvas.drawLine(a, b,
          Paint()
            ..color = _edgeColor.withOpacity(0.55)
            ..strokeWidth = 1.2
            ..style = PaintingStyle.stroke);

      // Animated packet along edge
      _drawPacket(canvas, a, b, edge[0], edge[1]);
    }

    // ── Draw nodes ───────────────────────────────────────────
    for (int i = 0; i < _nodes.length; i++) {
      final pos = toScreen(_nodes[i]);
      final isMain = i == 0;
      _drawNode(canvas, pos, isMain);
    }
  }

  void _drawPacket(Canvas canvas, Offset a, Offset b,
      int fromIdx, int toIdx) {
    // Each edge gets a unique phase offset so packets stagger
    final phase = ((fromIdx * 3 + toIdx * 7) % 10) / 10.0;
    final t = ((progress + phase) % 1.0);

    final px = a.dx + (b.dx - a.dx) * t;
    final py = a.dy + (b.dy - a.dy) * t;
    final packetPos = Offset(px, py);

    // Glow trail
    canvas.drawCircle(packetPos, 5.0,
        Paint()
          ..color = _packetColor.withOpacity(0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // Packet dot
    canvas.drawCircle(packetPos, 2.5,
        Paint()..color = _packetColor.withOpacity(0.85));
  }

  void _drawNode(Canvas canvas, Offset pos, bool isMain) {
    final radius = isMain ? 16.0 : 10.0;

    // Outer glow
    canvas.drawCircle(pos, radius * 2.2,
        Paint()
          ..color = _glowColor.withOpacity(isMain ? 0.18 : 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));

    // Ring
    canvas.drawCircle(pos, radius + 4,
        Paint()
          ..color = _nodeColor.withOpacity(isMain ? 0.25 : 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);

    // Fill
    canvas.drawCircle(pos, radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              isMain
                  ? const Color(0xFF818CF8)
                  : const Color(0xFF6366F1),
              isMain
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFF3730A3),
            ],
          ).createShader(Rect.fromCircle(center: pos, radius: radius)));

    // Inner highlight
    canvas.drawCircle(
        Offset(pos.dx - radius * 0.25, pos.dy - radius * 0.25),
        radius * 0.35,
        Paint()..color = Colors.white.withOpacity(0.25));

    // Block hash label on main node
    if (isMain) {
      _drawBlockLabel(canvas, pos);
    }
  }

  void _drawBlockLabel(Canvas canvas, Offset pos) {
    // Small hash badge below main node
    final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(pos.dx, pos.dy + 30),
            width: 78, height: 18),
        const Radius.circular(4));
    canvas.drawRRect(rect,
        Paint()..color = const Color(0xFF312E81).withOpacity(0.85));

    final tp = TextPainter(
      text: const TextSpan(
        text: '0x4f46e5…',
        style: TextStyle(
          color: Color(0xFFA5B4FC),
          fontSize: 8,
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(pos.dx - tp.width / 2, pos.dy + 30 - tp.height / 2));
  }

  @override
  bool shouldRepaint(_BlockchainNetworkPainter old) =>
      old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════
//  PULSE RING PAINTER — expanding rings from main node
// ═══════════════════════════════════════════════════════════════════

class _PulseRingPainter extends CustomPainter {
  final double progress;
  _PulseRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Main node is at (0.50, 0.22)
    final center = Offset(size.width * 0.50, size.height * 0.22);

    for (int i = 0; i < 3; i++) {
      final phase = (progress - i * 0.33).clamp(0.0, 1.0);
      if (phase <= 0) continue;

      final maxR = size.width * 0.28;
      final r = maxR * phase;
      final opacity = (1.0 - phase) * 0.4;

      canvas.drawCircle(center, r,
          Paint()
            ..color = const Color(0xFF818CF8).withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(_PulseRingPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════
//  SHIMMER PAINTER
// ═══════════════════════════════════════════════════════════════════

class _ShimmerPainter extends CustomPainter {
  final double pos;
  _ShimmerPainter({required this.pos});

  @override
  void paint(Canvas canvas, Size size) {
    final x = pos * size.width;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withOpacity(0.0),
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromLTWH(
              x - size.width * 0.4, 0,
              size.width * 0.8, size.height)));
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.pos != pos;
}

// ═══════════════════════════════════════════════════════════════════
//  HOVER BUTTON
// ═══════════════════════════════════════════════════════════════════

class _HoverButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _HoverButton({required this.child, this.onTap});

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 1.025).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter:  (_) { if (widget.onTap != null) _ctrl.forward(); },
      onExit:   (_) => _ctrl.reverse(),
      child: GestureDetector(
        onTap:       widget.onTap,
        onTapDown:   (_) => _ctrl.forward(),
        onTapUp:     (_) => _ctrl.reverse(),
        onTapCancel: ()  => _ctrl.reverse(),
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}