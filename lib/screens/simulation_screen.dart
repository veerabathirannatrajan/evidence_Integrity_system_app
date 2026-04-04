// lib/screens/simulation_screen.dart
// Simulation Mode — redesigned UI with larger icons, compact cards, dense layout

import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});
  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen>
    with TickerProviderStateMixin {
  final _api = ApiService();
  final _evidenceCtrl = TextEditingController();

  String? _selectedScenario;
  bool _running = false;
  Map<String, dynamic>? _result;
  String? _error;

  late AnimationController _bgCtrl;
  late Animation<double> _bgAnim;

  static const _bgBase   = Color(0xFFEEF2FF);
  static const _purple   = Color(0xFF7C3AED);
  static const _blue     = Color(0xFF2563EB);
  static const _green    = Color(0xFF059669);
  static const _amber    = Color(0xFFD97706);
  static const _red      = Color(0xFFDC2626);
  static const _orange   = Color(0xFFEA580C);
  static const _border   = Color(0xFFD1D5DB);
  static const _textPri  = Color(0xFF0F172A);
  static const _textSec  = Color(0xFF475569);
  static const _textMut  = Color(0xFF9CA3AF);

  static const _scenarios = [
    {
      'code':  'RAPID_TRANSFERS',
      'label': 'Rapid Transfers',
      'desc':  '3+ transfers within 10 min — triggers HIGH RISK. Detects abnormal transfer velocity.',
      'icon':  Icons.fast_forward_rounded,
      'color': 0xFFEA580C,
      'level': 'HIGH',
      'bg':    0xFFFFF4EE,
    },
    {
      'code':  'UNAUTHORIZED_ROLE',
      'label': 'Unauthorized Role',
      'desc':  'Defense → Police direct transfer — triggers VIOLATION. Catches role bypass attempts.',
      'icon':  Icons.block_rounded,
      'color': 0xFFDC2626,
      'level': 'VIOLATION',
      'bg':    0xFFFEF2F2,
    },
    {
      'code':  'CUSTODY_LOOPBACK',
      'label': 'Custody Loopback',
      'desc':  'Same examiner regains custody 3× — triggers SUSPICIOUS. Flags repeat handler patterns.',
      'icon':  Icons.loop_rounded,
      'color': 0xFF7C3AED,
      'level': 'SUSPICIOUS',
      'bg':    0xFFF5F3FF,
    },
    {
      'code':  'OFF_HOURS_ACCESS',
      'label': 'Off-Hours Access',
      'desc':  'Transfer at 02:34 AM — triggers ANOMALY. Monitors temporal access patterns.',
      'icon':  Icons.nights_stay_outlined,
      'color': 0xFFD97706,
      'level': 'ANOMALY',
      'bg':    0xFFFFFBEB,
    },
    {
      'code':  'BACKDATED_TRANSFER',
      'label': 'Backdated Transfer',
      'desc':  'Timestamp predates upload by 72 h — triggers VIOLATION. Catches timestamp fraud.',
      'icon':  Icons.history_outlined,
      'color': 0xFFDC2626,
      'level': 'VIOLATION',
      'bg':    0xFFFEF2F2,
    },
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 9))
      ..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);
    _loadFirstEvidence();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _evidenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFirstEvidence() async {
    try {
      final recent = await _api.getRecentEvidence(limit: 1);
      if (recent.isNotEmpty && mounted) {
        setState(() => _evidenceCtrl.text = recent.first['_id']?.toString() ?? '');
      }
    } catch (_) {}
  }

  Future<void> _runSimulation() async {
    final evidenceId = _evidenceCtrl.text.trim();
    if (_selectedScenario == null) { setState(() => _error = 'Select a scenario first'); return; }
    if (evidenceId.isEmpty) { setState(() => _error = 'Enter an Evidence ID'); return; }
    setState(() { _running = true; _error = null; _result = null; });
    try {
      final result = await _api.simulateRisk(_selectedScenario!, evidenceId);
      if (mounted) setState(() { _result = result; _running = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Simulation failed: ${e.toString().replaceAll('Exception: ', '')}';
        _running = false;
      });
    }
  }

  Color _levelColor(String l) => switch (l) {
    'VIOLATION'  => _red,
    'HIGH'       => _orange,
    'SUSPICIOUS' => _purple,
    'ANOMALY'    => _amber,
    'MEDIUM'     => _blue,
    _            => _green,
  };

  IconData _levelIcon(String l) => switch (l) {
    'VIOLATION'  => Icons.dangerous_outlined,
    'HIGH'       => Icons.warning_amber_rounded,
    'SUSPICIOUS' => Icons.visibility_outlined,
    'ANOMALY'    => Icons.access_time_rounded,
    'MEDIUM'     => Icons.info_outline_rounded,
    _            => Icons.check_circle_outline_rounded,
  };

  String _ruleLabel(String r) => switch (r) {
    'RAPID_TRANSFERS'   => 'Rapid Transfers Detected',
    'UNAUTHORIZED_ROLE' => 'Unauthorized Role Access',
    'CUSTODY_LOOPBACK'  => 'Custody Loopback',
    'OFF_HOURS_ACCESS'  => 'Off-Hours Access',
    'EXCESSIVE_CHAIN'   => 'Excessive Chain Length',
    'BACKDATED_TRANSFER'=> 'Backdated Transfer',
    'SIMULATION'        => 'Simulation Event',
    _                   => r,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBase,
      body: Stack(children: [
        Positioned.fill(child: _AnimBg(anim: _bgAnim)),
        SafeArea(child: Column(children: [
          _buildAppBar(),
          Expanded(child: _buildBody()),
        ])),
      ]),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return ClipRect(child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.72),
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5))),
        ),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withOpacity(0.6),
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 18, color: _textSec),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(colors: [_purple, _blue]),
            ),
            child: const Icon(Icons.science_outlined, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Simulation Mode', style: TextStyle(color: _textPri, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              Text('Trigger abnormal scenarios for demonstration', style: TextStyle(color: _textMut, fontSize: 10)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _purple.withOpacity(0.28)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.science_outlined, size: 11, color: _purple),
              SizedBox(width: 4),
              Text('DEMO', style: TextStyle(color: _purple, fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ),
    ));
  }

  // ── Responsive body ────────────────────────────────────────────
  Widget _buildBody() {
    return LayoutBuilder(builder: (_, cs) {
      final isWide = cs.maxWidth >= 700;
      if (isWide) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 32),
            child: Column(children: [
              _warningBanner(),
              const SizedBox(height: 14),
              _evidenceInputCard(),
              const SizedBox(height: 14),
              _scenarioSection(),
              if (_error != null) ...[const SizedBox(height: 12), _errorCard()],
              const SizedBox(height: 14),
              _runButton(),
              if (_result != null) ...[const SizedBox(height: 16), _resultCard()],
            ]),
          )),
          SizedBox(width: 270, child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 16, 18, 32),
            child: Column(children: [
              _howItWorksPanel(),
              const SizedBox(height: 14),
              _riskLevelsPanel(),
            ]),
          )),
        ]);
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
        child: Column(children: [
          _warningBanner(),
          const SizedBox(height: 12),
          _evidenceInputCard(),
          const SizedBox(height: 12),
          _scenarioSection(),
          if (_error != null) ...[const SizedBox(height: 10), _errorCard()],
          const SizedBox(height: 12),
          _runButton(),
          if (_result != null) ...[const SizedBox(height: 14), _resultCard()],
          const SizedBox(height: 14),
          _howItWorksPanel(),
          const SizedBox(height: 12),
          _riskLevelsPanel(),
        ]),
      );
    });
  }

  // ── Warning Banner ─────────────────────────────────────────────
  Widget _warningBanner() {
    return _GlassCard(tint: const Color(0xFFFFFBEB), child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _amber.withOpacity(0.15),
          ),
          child: const Icon(Icons.science_outlined, size: 20, color: _amber),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Simulation Mode Active', style: TextStyle(color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.w700)),
          SizedBox(height: 3),
          Text('Events are flagged SIM in the Risk Dashboard. They do not affect real evidence or blockchain records.',
              style: TextStyle(color: Color(0xFF78350F), fontSize: 11, height: 1.5)),
        ])),
      ]),
    ));
  }

  // ── Evidence Input ─────────────────────────────────────────────
  Widget _evidenceInputCard() {
    return _GlassCard(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: _blue.withOpacity(0.1)),
            child: const Icon(Icons.tag_rounded, size: 14, color: _blue),
          ),
          const SizedBox(width: 8),
          const Text('Target Evidence ID', style: TextStyle(color: _textPri, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _evidenceCtrl,
          style: const TextStyle(color: _textPri, fontSize: 13, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: 'e.g. 69b6b565ff08af25b2a44aa0',
            hintStyle: const TextStyle(color: _textMut, fontSize: 13),
            prefixIcon: const Icon(Icons.tag_rounded, size: 16, color: _textMut),
            helperText: 'Auto-filled with your most recent evidence ID.',
            helperStyle: const TextStyle(color: _textMut, fontSize: 11),
            filled: true,
            fillColor: Colors.white.withOpacity(0.7),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border, width: 1.2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border, width: 1.2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _blue, width: 2.0)),
          ),
        ),
      ]),
    ));
  }

  // ── Scenario Section ───────────────────────────────────────────
  Widget _scenarioSection() {
    return _GlassCard(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: _purple.withOpacity(0.1)),
            child: const Icon(Icons.science_outlined, size: 14, color: _purple),
          ),
          const SizedBox(width: 8),
          const Text('Choose Simulation Scenario', style: TextStyle(color: _textPri, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),
        Column(children: _scenarios.map((s) => _scenarioTile(s)).toList()),
      ]),
    ));
  }

  Widget _scenarioTile(Map s) {
    final code    = s['code'] as String;
    final active  = _selectedScenario == code;
    final color   = Color(s['color'] as int);
    final level   = s['level'] as String;
    final bgColor = Color(s['bg'] as int);
    final icon    = s['icon'] as IconData;

    return GestureDetector(
      onTap: () => setState(() { _selectedScenario = code; _error = null; _result = null; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.08) : Colors.white.withOpacity(0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? color : _border, width: active ? 1.8 : 1.2),
          boxShadow: active ? [BoxShadow(color: color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 3))] : [],
        ),
        child: Row(children: [
          // Large icon container
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: active
                  ? LinearGradient(colors: [color, color.withOpacity(0.75)])
                  : null,
              color: active ? null : color.withOpacity(0.10),
              boxShadow: active ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
            ),
            child: Icon(icon, size: 26, color: active ? Colors.white : color),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(s['label'] as String,
                style: TextStyle(
                  color: active ? color : _textPri,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              )),
              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: active ? color : color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(level, style: TextStyle(
                  color: active ? Colors.white : color,
                  fontSize: 9, fontWeight: FontWeight.w800,
                )),
              ),
            ]),
            const SizedBox(height: 4),
            Text(s['desc'] as String,
              style: const TextStyle(color: _textSec, fontSize: 11, height: 1.45),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
          ])),
          const SizedBox(width: 8),
          // Selection indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? color : Colors.transparent,
              border: Border.all(color: active ? color : _border, width: 1.5),
            ),
            child: active ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
          ),
        ]),
      ),
    );
  }

  // ── Error Card ─────────────────────────────────────────────────
  Widget _errorCard() {
    return _GlassCard(tint: const Color(0xFFFEF2F2), child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: _red, size: 17),
        const SizedBox(width: 10),
        Expanded(child: Text(_error!, style: const TextStyle(color: _red, fontSize: 12))),
        GestureDetector(onTap: () => setState(() => _error = null),
            child: const Icon(Icons.close_rounded, color: _red, size: 14)),
      ]),
    ));
  }

  // ── Run Button ─────────────────────────────────────────────────
  Widget _runButton() {
    final ready = _selectedScenario != null && _evidenceCtrl.text.trim().isNotEmpty && !_running;
    return Container(
      width: double.infinity, height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: ready ? const LinearGradient(colors: [_purple, _blue]) : null,
        color: ready ? null : _purple.withOpacity(0.35),
        boxShadow: ready ? [BoxShadow(color: _purple.withOpacity(0.38), blurRadius: 18, offset: const Offset(0, 6))] : [],
      ),
      child: Material(color: Colors.transparent,
        child: InkWell(
          onTap: ready ? _runSimulation : null,
          borderRadius: BorderRadius.circular(14),
          child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            _running
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Text(
              _running ? 'Running simulation...'
                  : _selectedScenario == null ? 'Select a scenario first'
                  : 'Run Simulation Now',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ])),
        ),
      ),
    );
  }

  // ── Result Card ────────────────────────────────────────────────
  Widget _resultCard() {
    final event = _result?['event'] as Map? ?? _result ?? {};
    final level = event['riskLevel'] as String? ?? 'UNKNOWN';
    final rule  = event['ruleCode']  as String? ?? '';
    final exp   = event['explanation'] as String? ?? '';
    final rec   = event['recommendedAction'] as String? ?? '';
    final color = _levelColor(level);

    return _GlassCard(tint: color.withOpacity(0.04), child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 5))],
              ),
              child: Icon(_levelIcon(level), size: 30, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Simulation Executed!', style: TextStyle(color: _textPri, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(level, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: const Text('SIMULATION', style: TextStyle(color: _purple, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ]),
          ])),
        ]),

        const SizedBox(height: 16),
        const Divider(color: Color(0xFFE2E8F0)),
        const SizedBox(height: 12),

        _rRow('Rule Fired', _ruleLabel(rule)),
        _rRow('Risk Level', level),
        _rRow('Evidence ID', event['evidenceId']?.toString() ?? '—'),

        const SizedBox(height: 10),
        const Text('Explanation', style: TextStyle(color: _textMut, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Text(exp, style: const TextStyle(color: _textSec, fontSize: 12, height: 1.65)),

        if (rec.isNotEmpty && rec != 'This is a simulated risk event for demonstration purposes.') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _amber.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _amber.withOpacity(0.25)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.gavel_outlined, size: 16, color: _amber),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Recommended Judicial Action', style: TextStyle(color: Color(0xFF92400E), fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(rec, style: const TextStyle(color: _textSec, fontSize: 12, height: 1.55)),
              ])),
            ]),
          ),
        ],

        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _OutlineBtn(
            label: 'Run Another', icon: Icons.refresh_rounded, color: color,
            onTap: () => setState(() { _result = null; _selectedScenario = null; _error = null; }),
          )),
          const SizedBox(width: 10),
          Expanded(child: _GradBtn(
            label: 'View Dashboard', icon: Icons.dashboard_outlined, color: color,
            onTap: () => Navigator.pop(context),
          )),
        ]),
      ]),
    ));
  }

  Widget _rRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 90, child: Text(label, style: const TextStyle(color: _textMut, fontSize: 11))),
      Text(value, style: const TextStyle(color: _textPri, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );

  // ── How It Works Panel ─────────────────────────────────────────
  Widget _howItWorksPanel() {
    return _GlassCard(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 28, height: 28,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: _blue.withOpacity(0.1)),
            child: const Icon(Icons.info_outline_rounded, size: 14, color: _blue),
          ),
          const SizedBox(width: 8),
          const Text('How simulation works', style: TextStyle(color: _textPri, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        ...[
          'Generates a realistic risk event flagged as SIMULATION.',
          'Appears in Risk Dashboard with a SIM badge.',
          'Does NOT affect real evidence or blockchain records.',
          'Judges can review and dismiss simulation events.',
          'Perfect for court demonstrations and testing.',
        ].map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 18, height: 18, margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(shape: BoxShape.circle, color: _blue.withOpacity(0.1)),
              child: const Icon(Icons.check_rounded, size: 10, color: _blue),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(t, style: const TextStyle(color: _textSec, fontSize: 12, height: 1.5))),
          ]),
        )),
      ]),
    ));
  }

  // ── Risk Levels Panel ──────────────────────────────────────────
  Widget _riskLevelsPanel() {
    return _GlassCard(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 28, height: 28,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: _purple.withOpacity(0.1)),
            child: const Icon(Icons.bar_chart_rounded, size: 14, color: _purple),
          ),
          const SizedBox(width: 8),
          const Text('Risk levels explained', style: TextStyle(color: _textPri, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        ...[
          ['VIOLATION',  'Critical rule broken — unauthorized access', 0xFFDC2626],
          ['HIGH',       'Multiple rapid transfers detected',          0xFFEA580C],
          ['SUSPICIOUS', 'Custody loopback pattern found',            0xFF7C3AED],
          ['ANOMALY',    'Off-hours or unusual timing',               0xFFD97706],
          ['MEDIUM',     'Excessive chain length',                    0xFF0284C7],
          ['LOW',        'No abnormal behavior detected',             0xFF059669],
        ].map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Color(r[2] as int).withOpacity(0.1),
              ),
              child: Icon(_levelIcon(r[0] as String), size: 16, color: Color(r[2] as int)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r[0] as String, style: TextStyle(color: Color(r[2] as int), fontSize: 11, fontWeight: FontWeight.w700)),
              Text(r[1] as String, style: const TextStyle(color: _textMut, fontSize: 11)),
            ])),
          ]),
        )),
      ]),
    ));
  }
}

// ─────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? tint;
  const _GlassCard({required this.child, this.tint});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 5), spreadRadius: -2),
        BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 1, offset: const Offset(0, -1)),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.65), width: 1.3),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [(tint ?? Colors.white).withOpacity(0.90), (tint ?? Colors.white).withOpacity(0.58)],
            ),
          ),
          child: child,
        ),
      ),
    ),
  );
}

class _GradBtn extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap;
  const _GradBtn({required this.label, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: color,
      boxShadow: [BoxShadow(color: color.withOpacity(0.32), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Material(color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: Colors.white), const SizedBox(width: 7),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    ),
  );
}

class _OutlineBtn extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: Colors.white.withOpacity(0.65),
      border: Border.all(color: color.withOpacity(0.35), width: 1.5),
    ),
    child: Material(color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: color), const SizedBox(width: 7),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    ),
  );
}

class _AnimBg extends StatelessWidget {
  final Animation<double> anim;
  const _AnimBg({required this.anim});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: anim,
    builder: (_, __) {
      final t = anim.value;
      return Container(color: const Color(0xFFEEF2FF), child: Stack(children: [
        Positioned(left: -120 + t * 70, top: -90 + t * 50,
            child: _orb(320, const Color(0xFF7C3AED), 0.10)),
        Positioned(right: -80 + t * 40, bottom: 30 + t * 80,
            child: _orb(260, const Color(0xFF2563EB), 0.08)),
      ]));
    },
  );
  Widget _orb(double sz, Color c, double op) => Container(
    width: sz, height: sz,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [c.withOpacity(op), c.withOpacity(0)]),
    ),
  );
}