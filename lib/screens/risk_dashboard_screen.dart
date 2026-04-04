// lib/screens/risk_dashboard_screen.dart
// Risk Intelligence Dashboard — improved categorization and UI

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class RiskDashboardScreen extends StatefulWidget {
  const RiskDashboardScreen({super.key});
  @override
  State<RiskDashboardScreen> createState() => _RiskDashboardScreenState();
}

class _RiskDashboardScreenState extends State<RiskDashboardScreen>
    with TickerProviderStateMixin {
  final _api = ApiService();

  Map<String, dynamic> _dashboard = {};
  List<dynamic>        _items     = [];
  Map<String, dynamic> _stats     = {};
  bool   _loading = true;
  String? _error;
  String  _filter = 'ALL';
  Map<String, dynamic>? _selected;

  late AnimationController _bgCtrl;
  late Animation<double>   _bgAnim;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulse;

  static const _bgBase   = Color(0xFFEEF2FF);
  static const _purple   = Color(0xFF7C3AED);
  static const _blue     = Color(0xFF2563EB);
  static const _green    = Color(0xFF059669);
  static const _amber    = Color(0xFFD97706);
  static const _red      = Color(0xFFDC2626);
  static const _orange   = Color(0xFFEA580C);
  static const _textPri  = Color(0xFF0F172A);
  static const _textSec  = Color(0xFF475569);
  static const _textMut  = Color(0xFF9CA3AF);
  static const _border   = Color(0xFFD1D5DB);

  static const _filterDefs = [
    {'code': 'ALL',        'label': 'All Events',    'icon': Icons.dashboard_outlined,       'color': 0xFF2563EB},
    {'code': 'VIOLATION',  'label': 'Violations',    'icon': Icons.dangerous_outlined,        'color': 0xFFDC2626},
    {'code': 'HIGH',       'label': 'High Risk',     'icon': Icons.warning_amber_rounded,     'color': 0xFFEA580C},
    {'code': 'SUSPICIOUS', 'label': 'Suspicious',    'icon': Icons.visibility_outlined,       'color': 0xFF7C3AED},
    {'code': 'ANOMALY',    'label': 'Anomalies',     'icon': Icons.access_time_rounded,       'color': 0xFFD97706},
    {'code': 'MEDIUM',     'label': 'Medium',        'icon': Icons.info_outline_rounded,      'color': 0xFF0284C7},
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulse = _pulseCtrl.drive(Tween(begin: 0.94, end: 1.06).chain(CurveTween(curve: Curves.easeInOut)));
    _load();
  }

  @override
  void dispose() { _bgCtrl.dispose(); _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _api.getRiskDashboard(riskLevel: _filter == 'ALL' ? null : _filter),
        _api.getRiskStats(),
      ]);
      if (!mounted) return;
      setState(() {
        _dashboard = results[0] as Map<String, dynamic>;
        _stats     = results[1] as Map<String, dynamic>;
        _items     = (_dashboard['items'] as List? ?? []);
        _loading   = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load risk data: $e'; _loading = false; });
    }
  }

  Future<void> _reviewEvent(String eventId) async {
    try {
      await _api.reviewRiskEvent(eventId, notes: 'Reviewed by court official');
      _load();
      _snack('Event marked as reviewed', _green);
    } catch (e) {
      _snack('Failed to review: $e', _red);
    }
  }

  void _snack(String msg, Color c) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: c, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _snack('Copied to clipboard', _green);
  }

  Color _riskColor(String level) => switch (level) {
    'VIOLATION'  => _red,
    'HIGH'       => _orange,
    'SUSPICIOUS' => _purple,
    'ANOMALY'    => _amber,
    'MEDIUM'     => _blue,
    _            => _green,
  };

  IconData _riskIcon(String level) => switch (level) {
    'VIOLATION'  => Icons.dangerous_outlined,
    'HIGH'       => Icons.warning_amber_rounded,
    'SUSPICIOUS' => Icons.visibility_outlined,
    'ANOMALY'    => Icons.access_time_rounded,
    'MEDIUM'     => Icons.info_outline_rounded,
    _            => Icons.check_circle_outline_rounded,
  };

  String _roleLabel(String r) => switch (r) {
    'police'     => 'Police Officer',
    'forensic'   => 'Forensic Expert',
    'prosecutor' => 'Prosecutor',
    'defense'    => 'Defense Attorney',
    'court'      => 'Court Official',
    _            => r,
  };

  String _ruleLabel(String rule) => switch (rule) {
    'RAPID_TRANSFERS'    => 'Rapid Custody Transfers',
    'UNAUTHORIZED_ROLE'  => 'Unauthorized Role Access',
    'CUSTODY_LOOPBACK'   => 'Custody Loopback Detected',
    'OFF_HOURS_ACCESS'   => 'Off-Hours Access',
    'EXCESSIVE_CHAIN'    => 'Excessive Chain Length',
    'BACKDATED_TRANSFER' => 'Backdated Transfer',
    'SIMULATION'         => 'Simulated Scenario',
    _                    => rule,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBase,
      body: Stack(children: [
        Positioned.fill(child: _AnimBg(anim: _bgAnim)),
        SafeArea(child: Column(children: [
          _buildAppBar(),
          _buildStatsRow(),
          _buildFilterBar(),
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
              gradient: const LinearGradient(colors: [_red, _orange]),
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Risk Intelligence', style: TextStyle(color: _textPri, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              Text('Evidence anomaly detection · Judicial review', style: TextStyle(color: _textMut, fontSize: 10)),
            ],
          )),
          AnimatedBuilder(animation: _pulse, builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _red.withOpacity(0.28)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Transform.scale(scale: _pulse.value,
                  child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: _red, shape: BoxShape.circle))),
              const SizedBox(width: 5),
              const Text('Live', style: TextStyle(color: _red, fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _load,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withOpacity(0.6),
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.refresh_rounded, size: 16, color: _textSec),
            ),
          ),
        ]),
      ),
    ));
  }

  // ── Stats Row ──────────────────────────────────────────────────
  Widget _buildStatsRow() {
    if (_stats.isEmpty) return const SizedBox.shrink();
    return ClipRect(child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.62),
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5))),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _statPill('Total',     '${_stats['total']      ?? 0}', _blue),
            const SizedBox(width: 8),
            _statPill('Violations','${_stats['violations'] ?? 0}', _red),
            const SizedBox(width: 8),
            _statPill('High Risk', '${_stats['high']       ?? 0}', _orange),
            const SizedBox(width: 8),
            _statPill('Suspicious','${_stats['suspicious'] ?? 0}', _purple),
            const SizedBox(width: 8),
            _statPill('Anomalies', '${_stats['anomalies']  ?? 0}', _amber),
            const SizedBox(width: 8),
            _statPill('Unreviewed','${_stats['unreviewed'] ?? 0}', _red),
            const SizedBox(width: 8),
            _statPill('Last 24h',  '${_stats['last24h']   ?? 0}', _green),
          ]),
        ),
      ),
    ));
  }

  Widget _statPill(String label, String val, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: c.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.withOpacity(0.22)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('$label ', style: TextStyle(color: c.withOpacity(0.7), fontSize: 11)),
      Text(val, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w800)),
    ]),
  );

  // ── Filter Bar ─────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return ClipRect(child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5))),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _filterDefs.map((f) {
            final code   = f['code'] as String;
            final active = _filter == code;
            final color  = Color(f['color'] as int);
            final icon   = f['icon'] as IconData;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () { setState(() => _filter = code); _load(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? color : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? color : _border, width: 1.2),
                    boxShadow: active ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))] : [],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 13, color: active ? Colors.white : color),
                    const SizedBox(width: 5),
                    Text(f['label'] as String, style: TextStyle(
                      color: active ? Colors.white : _textSec,
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    )),
                  ]),
                ),
              ),
            );
          }).toList()),
        ),
      ),
    ));
  }

  // ── Body ───────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) return _loadingState();
    if (_error != null) return _errorState();

    return LayoutBuilder(builder: (_, cs) {
      final isDesktop = cs.maxWidth >= 900;
      if (isDesktop) {
        return Row(children: [
          SizedBox(width: 420, child: _itemList()),
          Container(width: 1, color: Colors.white.withOpacity(0.5)),
          Expanded(child: _selected == null ? _emptyDetail() : _RiskDetailView(
            item: _selected!,
            onReview: _reviewEvent,
            onCopy: _copy,
            riskColor: _riskColor,
            riskIcon: _riskIcon,
            ruleLabel: _ruleLabel,
            roleLabel: _roleLabel,
          )),
        ]);
      }
      return _itemList();
    });
  }

  Widget _itemList() {
    if (_items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _green.withOpacity(0.07)),
          child: const Icon(Icons.verified_user_outlined, size: 34, color: _green),
        ),
        const SizedBox(height: 16),
        const Text('No risk events detected', style: TextStyle(color: _textPri, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(_filter == 'ALL' ? 'All evidence within normal parameters' : 'No $_filter events found',
            style: const TextStyle(color: _textMut, fontSize: 13)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: _items.length,
      itemBuilder: (_, i) => _riskCard(_items[i]),
    );
  }

  Widget _riskCard(Map item) {
    final eid       = item['evidenceId']?.toString() ?? '';
    final name      = item['evidenceName'] as String? ?? 'Unknown';
    final level     = item['riskLevel'] as String? ?? 'LOW';
    final events    = item['events'] as List? ?? [];
    final custodian = item['currentCustodian'] as Map? ?? {};
    final action    = item['recommendedAction'] as String? ?? '';
    final color     = _riskColor(level);
    final isSelected = _selected?['evidenceId'] == eid;
    final unreviewedCount = events.where((e) => e['reviewed'] != true).length;

    return GestureDetector(
      onTap: () {
        setState(() => _selected = Map<String, dynamic>.from(item));
        if (MediaQuery.of(context).size.width < 900) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => _RiskDetailPage(
              item: item, onReview: _reviewEvent, onCopy: _copy,
              riskColor: _riskColor, riskIcon: _riskIcon,
              ruleLabel: _ruleLabel, roleLabel: _roleLabel,
            ),
          ));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.06) : Colors.white.withOpacity(0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.4) : Colors.white.withOpacity(0.8),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: [BoxShadow(color: color.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            // Risk level dot
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: color, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6, spreadRadius: 2)],
              ),
            ),
            const SizedBox(width: 8),
            // Risk badge
            _RiskBadge(level: level, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(name, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _textPri, fontSize: 13, fontWeight: FontWeight.w700))),
            // Events count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text('${events.length} event${events.length != 1 ? 's' : ''}',
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
            if (unreviewedCount > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: _red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('$unreviewedCount new', style: const TextStyle(color: _red, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ],
          ]),

          const SizedBox(height: 8),

          // Evidence ID
          Row(children: [
            const Icon(Icons.tag_rounded, size: 11, color: _textMut),
            const SizedBox(width: 4),
            Expanded(child: Text(eid, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _blue, fontSize: 10, fontFamily: 'monospace'))),
            GestureDetector(onTap: () => _copy(eid),
                child: const Icon(Icons.copy_outlined, size: 11, color: _textMut)),
          ]),

          // Current custodian
          if (custodian.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.person_outline, size: 12, color: color.withOpacity(0.7)),
              const SizedBox(width: 5),
              Expanded(child: Text(
                '${custodian['name'] ?? custodian['user'] ?? '—'} · ${_roleLabel(custodian['role'] as String? ?? '')}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _textSec, fontSize: 11),
              )),
            ]),
          ],

          // Triggered rules chips
          if (events.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 5, runSpacing: 5, children: (events as List).take(3).map((e) {
              final ruleCode = e['ruleCode'] as String? ?? '';
              final isSim    = e['isSimulation'] == true;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (isSim) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Text('SIM', style: TextStyle(color: _purple, fontSize: 8, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(_ruleLabel(ruleCode), style: const TextStyle(color: _textSec, fontSize: 10)),
                ]),
              );
            }).toList()),
            if (events.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text('+${events.length - 3} more', style: const TextStyle(color: _textMut, fontSize: 10)),
              ),
          ],

          // Judicial action snippet
          if (action.isNotEmpty && level != 'LOW' && level != 'MEDIUM') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.gavel_outlined, size: 12, color: color),
                const SizedBox(width: 6),
                Expanded(child: Text(action, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color.withOpacity(0.85), fontSize: 10, height: 1.4))),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _emptyDetail() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 72, height: 72,
      decoration: BoxDecoration(shape: BoxShape.circle, color: _red.withOpacity(0.06)),
      child: const Icon(Icons.touch_app_outlined, size: 32, color: _red),
    ),
    const SizedBox(height: 16),
    const Text('Select an evidence item', style: TextStyle(color: _textPri, fontSize: 16, fontWeight: FontWeight.w700)),
    const SizedBox(height: 6),
    const Text('Click any item to view risk details\nand judicial recommendations',
        textAlign: TextAlign.center,
        style: TextStyle(color: _textMut, fontSize: 13)),
  ]));

  Widget _loadingState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const CircularProgressIndicator(color: _red, strokeWidth: 2.5),
    const SizedBox(height: 16),
    const Text('Loading risk intelligence data...', style: TextStyle(color: _textSec, fontSize: 13)),
  ]));

  Widget _errorState() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, size: 36, color: _textMut),
      const SizedBox(height: 10),
      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: _textSec, fontSize: 13)),
      const SizedBox(height: 16),
      GestureDetector(onTap: _load, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(10)),
        child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      )),
    ]),
  ));
}

// ─────────────────────────────────────────────────────────────
// Risk Detail View
// ─────────────────────────────────────────────────────────────

class _RiskDetailView extends StatelessWidget {
  final Map item;
  final Future<void> Function(String) onReview;
  final void Function(String) onCopy;
  final Color Function(String) riskColor;
  final IconData Function(String) riskIcon;
  final String Function(String) ruleLabel;
  final String Function(String) roleLabel;

  const _RiskDetailView({
    required this.item, required this.onReview, required this.onCopy,
    required this.riskColor, required this.riskIcon,
    required this.ruleLabel, required this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    final eid       = item['evidenceId']?.toString() ?? '';
    final name      = item['evidenceName'] as String? ?? 'Unknown';
    final level     = item['riskLevel'] as String? ?? 'LOW';
    final events    = item['events'] as List? ?? [];
    final custodian = item['currentCustodian'] as Map? ?? {};
    final action    = item['recommendedAction'] as String? ?? '';
    final color     = riskColor(level);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header
        _GlassCard(child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: Icon(riskIcon(level), size: 24, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Row(children: [
                  _RiskBadge(level: level, color: color),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                    child: Text('${events.length} events', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ])),
            ]),
            const SizedBox(height: 14),
            _DRow(label: 'Evidence ID', value: eid, mono: true, copy: eid, onCopy: onCopy),
            if (custodian.isNotEmpty)
              _DRow(label: 'Custodian', value:
              '${custodian['name'] ?? custodian['user']} · ${roleLabel(custodian['role'] as String? ?? '')}'),
            _DRow(label: 'Total Events', value: '${events.length} detected'),
            _DRow(label: 'Unreviewed',
                value: '${events.where((e) => e['reviewed'] != true).length} pending'),
          ]),
        )),

        const SizedBox(height: 14),

        // Judicial Action
        if (action.isNotEmpty)
          _GlassCard(tint: color.withOpacity(0.04), child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 28, height: 28,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: color.withOpacity(0.1)),
                  child: Icon(Icons.gavel_outlined, size: 14, color: color),
                ),
                const SizedBox(width: 8),
                Text('Recommended Judicial Action', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 10),
              Text(action, style: const TextStyle(color: Color(0xFF374151), fontSize: 13, height: 1.65)),
            ]),
          )),

        if (action.isNotEmpty) const SizedBox(height: 14),

        // Events
        if (events.isNotEmpty) ...[
          Row(children: [
            Container(width: 4, height: 16, color: color, margin: const EdgeInsets.only(right: 8)),
            const Text('Triggered Risk Events', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
              child: Text('${events.length}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 12),
          ...events.map((e) => _EventCard(
            event: e, onReview: onReview, riskColor: riskColor, ruleLabel: ruleLabel,
          )),
        ],
      ]),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Map event;
  final Future<void> Function(String) onReview;
  final Color Function(String) riskColor;
  final String Function(String) ruleLabel;
  const _EventCard({required this.event, required this.onReview, required this.riskColor, required this.ruleLabel});

  @override
  Widget build(BuildContext context) {
    final level    = event['riskLevel'] as String? ?? 'LOW';
    final rule     = event['ruleCode']  as String? ?? '';
    final exp      = event['explanation'] as String? ?? '';
    final rec      = event['recommendedAction'] as String? ?? '';
    final reviewed = event['reviewed'] == true;
    final isSim    = event['isSimulation'] == true;
    final eventId  = event['_id']?.toString() ?? '';
    final color    = riskColor(level);

    String _fmtDate(String? raw) {
      if (raw == null || raw.isEmpty) return '—';
      final t = DateTime.tryParse(raw);
      if (t == null) return raw;
      final l = t.toLocal();
      return '${l.day.toString().padLeft(2,'0')}/${l.month.toString().padLeft(2,'0')}/${l.year}  ${l.hour.toString().padLeft(2,'0')}:${l.minute.toString().padLeft(2,'0')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: reviewed ? Colors.white.withOpacity(0.45) : Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: reviewed ? const Color(0xFFD1D5DB) : color.withOpacity(0.35), width: 1.2),
        boxShadow: reviewed ? [] : [BoxShadow(color: color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _RiskBadge(level: level, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(ruleLabel(rule),
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w700))),
            if (isSim)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('SIM', style: TextStyle(color: Color(0xFF7C3AED), fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            if (reviewed)
              const Padding(padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF059669))),
          ]),
          const SizedBox(height: 4),
          Text(_fmtDate(event['createdAt'] as String?),
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
          const SizedBox(height: 8),
          Text(exp, style: const TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.6)),
          if (rec.isNotEmpty && !reviewed && rec != 'This is a simulated risk event for demonstration purposes.') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD97706).withOpacity(0.3)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.gavel_outlined, size: 12, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                Expanded(child: Text(rec, style: const TextStyle(color: Color(0xFF374151), fontSize: 11, height: 1.5))),
              ]),
            ),
          ],
          if (!reviewed && eventId.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => onReview(eventId),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF0D9488)]),
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [BoxShadow(color: const Color(0xFF059669).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Mark Reviewed', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// Mobile detail page
class _RiskDetailPage extends StatelessWidget {
  final Map item;
  final Future<void> Function(String) onReview;
  final void Function(String) onCopy;
  final Color Function(String) riskColor;
  final IconData Function(String) riskIcon;
  final String Function(String) ruleLabel;
  final String Function(String) roleLabel;
  const _RiskDetailPage({required this.item, required this.onReview, required this.onCopy,
    required this.riskColor, required this.riskIcon, required this.ruleLabel, required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    final level = item['riskLevel'] as String? ?? 'LOW';
    final color = riskColor(level);
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FF),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)), onPressed: () => Navigator.pop(context)),
        title: Row(children: [
          _RiskBadge(level: level, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(item['evidenceName'] as String? ?? '—',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w700))),
        ]),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1),
            child: Divider(color: Color(0xFFE2E8F0), height: 1)),
      ),
      body: _RiskDetailView(item: item, onReview: onReview, onCopy: onCopy,
          riskColor: riskColor, riskIcon: riskIcon, ruleLabel: ruleLabel, roleLabel: roleLabel),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────

class _RiskBadge extends StatelessWidget {
  final String level;
  final Color color;
  const _RiskBadge({required this.level, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(level, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
  );
}

class _DRow extends StatelessWidget {
  final String label, value;
  final bool mono;
  final String? copy;
  final void Function(String)? onCopy;
  const _DRow({required this.label, required this.value, this.mono = false, this.copy, this.onCopy});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11))),
      Expanded(child: Text(value, style: TextStyle(
        color: const Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600,
        fontFamily: mono ? 'monospace' : null,
      ))),
      if (copy != null && onCopy != null)
        GestureDetector(onTap: () => onCopy!(copy!),
            child: const Padding(padding: EdgeInsets.only(left: 5),
                child: Icon(Icons.copy_outlined, size: 11, color: Color(0xFF9CA3AF)))),
    ]),
  );
}

class _GlassCard extends StatelessWidget {
  final Widget child; final Color? tint;
  const _GlassCard({required this.child, this.tint});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: const Color(0xFFDC2626).withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 5), spreadRadius: -2),
        BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 1, offset: const Offset(0, -1)),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.65), width: 1.3),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [(tint ?? Colors.white).withOpacity(0.90), (tint ?? Colors.white).withOpacity(0.58)]),
          ),
          child: child,
        ),
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
        Positioned(left: -120 + t * 70, top: -90 + t * 50, child: _orb(320, const Color(0xFFDC2626), 0.09)),
        Positioned(right: -80 + t * 40, bottom: 30 + t * 80, child: _orb(260, const Color(0xFFEA580C), 0.08)),
        Positioned(left: MediaQuery.of(context).size.width * 0.4,
            top: MediaQuery.of(context).size.height * 0.35 - t * 50,
            child: _orb(180, const Color(0xFF7C3AED), 0.07)),
      ]));
    },
  );
  Widget _orb(double sz, Color c, double op) => Container(
    width: sz, height: sz,
    decoration: BoxDecoration(shape: BoxShape.circle,
        gradient: RadialGradient(colors: [c.withOpacity(op), c.withOpacity(0)])),
  );
}