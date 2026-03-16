import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import 'dashboard_screen.dart';

/// Desktop-first login screen.
/// Left half: form card on white background.
/// Right half: pale blue background with the character image.
/// Sizes are fixed pixel values appropriate for 1280×800+ Windows screens.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  // ── Form ────────────────────────────────────────────────────
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  final _auth         = AuthService();
  final _api          = ApiService();

  bool   _isLogin   = true;
  bool   _isLoading = false;
  bool   _obscure   = true;
  bool   _remember  = false;
  String _role      = 'police';
  String? _error;

  // ── Entry animation ──────────────────────────────────────────
  late AnimationController _entryCtrl;
  late Animation<double>   _opacity;
  late Animation<Offset>   _slide;

  final _roles = const [
    {'value': 'police',     'label': 'Police Officer'},
    {'value': 'forensic',   'label': 'Forensic Expert'},
    {'value': 'prosecutor', 'label': 'Prosecutor'},
    {'value': 'defense',    'label': 'Defense Attorney'},
    {'value': 'court',      'label': 'Court Official'},
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _opacity = _entryCtrl.drive(
        Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: const Interval(0, 0.65))));
    _slide = _entryCtrl.drive(
        Tween(begin: const Offset(-0.03, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Auth ─────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      if (_isLogin) {
        await _auth.login(
            _emailCtrl.text.trim(), _passwordCtrl.text.trim());
        await context.read<UserProvider>().loadFromFirebase();
        if (mounted) _nav();
      } else {
        final u = await _auth.register(
            _emailCtrl.text.trim(), _passwordCtrl.text.trim());
        if (u != null) {
          await _api.createUser(u.uid, _nameCtrl.text.trim(),
              _emailCtrl.text.trim(), _role);
          await context.read<UserProvider>().loadFromFirebase();
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

  // ── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Center(
        // Outer window card — fixed width, height adapts to form content
        child: Container(
          width: 900,
          // Login = 560, Register = 660 (extra fields need more height)
          height: _isLogin ? 560 : 660,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.10),
                blurRadius: 60,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                // ── LEFT: Form ─────────────────────────────
                _buildFormPanel(),
                // ── RIGHT: Image ───────────────────────────
                _buildImagePanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── LEFT PANEL ───────────────────────────────────────────────
  Widget _buildFormPanel() {
    return SizedBox(
      width: 420,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 44, vertical: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // App name + subtitle
                Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(8),
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
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          )),
                      Text('Blockchain Evidence System',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          )),
                    ],
                  ),
                ]),

                const SizedBox(height: 30),

                // Tab row
                _buildTabs(),

                const SizedBox(height: 24),

                // Form
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          if (!_isLogin) ...[
                            _label('Full Name'),
                            const SizedBox(height: 6),
                            _textField(
                              ctrl: _nameCtrl,
                              hint: 'Your full name',
                              icon: Icons.person_outline_rounded,
                              validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Name is required' : null,
                            ),
                            const SizedBox(height: 16),
                          ],

                          _label('Email Address'),
                          const SizedBox(height: 6),
                          _textField(
                            ctrl: _emailCtrl,
                            hint: 'name@example.com',
                            icon: Icons.mail_outline_rounded,
                            type: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email is required';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          _label('Password'),
                          const SizedBox(height: 6),
                          _passwordField(),

                          if (!_isLogin) ...[
                            const SizedBox(height: 16),
                            _label('Your Role'),
                            const SizedBox(height: 6),
                            _roleDropdown(), // FIXED: Now clearly visible!
                          ],

                          if (_isLogin) ...[
                            const SizedBox(height: 12),
                            _rememberRow(),
                          ],

                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            _errorBanner(),
                          ],

                          const SizedBox(height: 20),

                          _submitButton(),

                          const SizedBox(height: 16),

                          // Toggle
                          Center(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _isLogin = !_isLogin; _error = null;
                              }),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: RichText(
                                  text: TextSpan(children: [
                                    TextSpan(
                                        text: _isLogin
                                            ? "Don't have an account?  "
                                            : 'Already have an account?  ',
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 13,
                                        )),
                                    TextSpan(
                                        text: _isLogin ? 'Register' : 'Login',
                                        style: const TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── RIGHT PANEL ──────────────────────────────────────────────
  Widget _buildImagePanel() {
    return Expanded(
      child: Container(
        // Pale blue background matching the image background
        color: const Color(0xFFE8F1FF),
        child: Stack(
          children: [
            // Large soft circle (like the blue blob in image)
            Positioned(
              top: -60, left: -40,
              child: Container(
                width: 320, height: 320,
                decoration: const BoxDecoration(
                  color: Color(0xFFCFDEFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Bottom-right small circle
            Positioned(
              bottom: -30, right: -20,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFBDD4FF).withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // The actual character image from assets
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'images/login_character.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        _characterFallback(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown while image asset is missing — gives correct visual hint
  Widget _characterFallback() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 260, height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFFDEEAFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined,
                  color: Color(0xFF93B4D8), size: 48),
              SizedBox(height: 12),
              Text(
                'Add image to:\nassets/images/login_character.png',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF7BA7CC),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tabs ─────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          _tab('Login',    true),
          const SizedBox(width: 8),
          _tab('Register', false),
        ],
      ),
    );
  }

  Widget _tab(String label, bool isLoginTab) {
    final active = _isLogin == isLoginTab;
    return GestureDetector(
      onTap: () {
        if (_isLogin != isLoginTab) {
          setState(() { _isLogin = isLoginTab; _error = null; });
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          margin: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active
                    ? const Color(0xFF2563EB)
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(label,
              style: TextStyle(
                color: active
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF94A3B8),
                fontWeight:
                active ? FontWeight.w700 : FontWeight.w400,
                fontSize: 15,
              )),
        ),
      ),
    );
  }

  // ── Label ────────────────────────────────────────────────────
  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(
          color: Color(0xFF374151),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ));
  }

  // ── Text field ───────────────────────────────────────────────
  Widget _textField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: validator,
      style: const TextStyle(
          color: Color(0xFF0F172A), fontSize: 14),
      decoration: _deco(hint, icon),
    );
  }

  // ── Password field ───────────────────────────────────────────
  Widget _passwordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscure,
      style: const TextStyle(
          color: Color(0xFF0F172A), fontSize: 14),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required';
        if (!_isLogin && v.length < 6) return 'Min 6 characters';
        return null;
      },
      decoration: _deco('••••••••', Icons.lock_outline_rounded,
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
                size: 18,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          color: Color(0xFFCBD5E1), fontSize: 14),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFF),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
          vertical: 13, horizontal: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: Color(0xFF2563EB), width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444))),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: Color(0xFFEF4444), width: 1.5)),
      errorStyle: const TextStyle(
          color: Color(0xFFEF4444), fontSize: 11),
    );
  }

  // ── Role dropdown ─────────────────────────────────────────────
  Widget _roleDropdown() {
    return Container(
      width: double.infinity, // Same width as other fields
      height: 50, // Fixed height same as text fields
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _role,
          isExpanded: true,
          isDense: false,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 24, color: Color(0xFF2563EB)),
          style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w500),
          items: _roles.map((r) => DropdownMenuItem(
            value: r['value'],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(_roleIcon(r['value']!),
                      size: 18, color: const Color(0xFF2563EB)),
                  const SizedBox(width: 12),
                  Text(
                    r['label']!,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _role = v);
          },
        ),
      ),
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

  // ── Remember me ──────────────────────────────────────────────
  Widget _rememberRow() {
    return Row(
      children: [
        SizedBox(
          width: 18, height: 18,
          child: Checkbox(
            value: _remember,
            onChanged: (v) =>
                setState(() => _remember = v ?? false),
            activeColor: const Color(0xFF2563EB),
            side: const BorderSide(
                color: Color(0xFFCBD5E1), width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        const Text('Keep me logged in',
            style: TextStyle(
                color: Color(0xFF64748B), fontSize: 13)),
      ],
    );
  }

  // ── Error banner ──────────────────────────────────────────────
  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: Color(0xFFEF4444), size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(_error!,
              style: const TextStyle(
                  color: Color(0xFFDC2626), fontSize: 13)),
        ),
      ]),
    );
  }

  // ── Submit button ─────────────────────────────────────────────
  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          disabledBackgroundColor:
          const Color(0xFF2563EB).withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
        child: _isLoading
            ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5))
            : Text(
            _isLogin ? 'Log In' : 'Create Account',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            )),
      ),
    );
  }
}