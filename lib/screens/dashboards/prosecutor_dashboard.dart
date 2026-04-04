// prosecutor_dashboard.dart — Uses GlobalKey scaffold, no Scaffold.of() bug, no theme toggle
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../dashboard_widgets.dart';
import '../dashboard_scaffold.dart';
import '../login_screen.dart';
import '../evidence_list_screen.dart' show EvidenceListScreen;
import '../verify_evidence_screen.dart';
import '../custody_timeline_screen.dart' show CustodyTimelineScreen;
import '../blockchain_viewer_screen.dart';
import '../risk_dashboard_screen.dart';
import '../simulation_screen.dart';

class ProsecutorDashboard extends StatefulWidget {
  const ProsecutorDashboard({super.key});
  @override State<ProsecutorDashboard> createState() => _ProsecutorDashboardState();
}

class _ProsecutorDashboardState extends State<ProsecutorDashboard> with TickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _api = ApiService();
  bool _sidebarExpanded = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _activity = [];
  bool _statsLoading = true, _actLoading = true;
  String? _statsError, _actError;
  Timer? _timer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _pulse = _pulseCtrl.drive(Tween(begin: 0.96, end: 1.04).chain(CurveTween(curve: Curves.easeInOut)));
    _loadAll();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadAll());
  }
  @override void dispose() { _timer?.cancel(); _pulseCtrl.dispose(); super.dispose(); }
  Future<void> _loadAll() async { _loadStats(); _loadActivity(); }

  Future<void> _loadStats() async {
    setState(() { _statsLoading = true; _statsError = null; });
    try { final d = await _api.getDashboardStats(); if (mounted) setState(() { _stats = d; _statsLoading = false; }); }
    catch (e) { if (mounted) setState(() { _statsError = 'Failed'; _statsLoading = false; }); }
  }

  Future<void> _loadActivity() async {
    setState(() { _actLoading = true; _actError = null; });
    try {
      final data = await _api.getRecentActivity();
      final items = <Map<String, dynamic>>[];
      for (final e in (data['recentEvidence'] as List? ?? [])) items.add({...Map<String, dynamic>.from(e), '_type': 'evidence'});
      for (final c in (data['recentCustody']  as List? ?? [])) items.add({...Map<String, dynamic>.from(c), '_type': 'custody'});
      items.sort((a, b) { final ta = DateTime.tryParse(a['createdAt'] ?? a['timestamp'] ?? '') ?? DateTime(0); final tb = DateTime.tryParse(b['createdAt'] ?? b['timestamp'] ?? '') ?? DateTime(0); return tb.compareTo(ta); });
      if (mounted) setState(() { _activity = items.take(8).toList(); _actLoading = false; });
    } catch (e) { if (mounted) setState(() { _actError = 'Failed'; _actLoading = false; }); }
  }

  void _go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
  Future<void> _logout() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => const LogoutDialog());
    if (ok == true && mounted) { context.read<UserProvider>().clear(); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); }
  }
  void _handleNav(String screen) {
    switch (screen) {
      case 'evidence':   _go(EvidenceListScreen(filterByCaseId: null)); break;
      case 'verify':     _go(const VerifyEvidenceScreen()); break;
      case 'custody':    _go(CustodyTimelineScreen(evidenceId: null)); break;
      case 'blockchain': _go(const BlockchainViewerScreen()); break;
      case 'risk':       _go(const RiskDashboardScreen()); break;
      case 'simulation': _go(const SimulationScreen()); break;
    }
  }

  static const _navItems = <Map<String, dynamic>>[
    {'label': 'REVIEW', 'section': true},
    {'label': 'View Evidence',       'icon': Icons.gavel_outlined,    'screen': 'evidence'},
    {'label': 'Verify Authenticity', 'icon': Icons.verified_outlined, 'screen': 'verify'},
    {'label': 'LEGAL', 'section': true},
    {'label': 'Custody Chain',       'icon': Icons.timeline_outlined, 'screen': 'custody'},
    {'label': 'BLOCKCHAIN', 'section': true},
    {'label': 'Blockchain Proof',    'icon': Icons.link_rounded,      'screen': 'blockchain'},
    {'label': 'INTELLIGENCE', 'section': true},
    {'label': 'Risk Intelligence',   'icon': Icons.shield_outlined,    'screen': 'risk'},
    {'label': 'Simulation Mode',     'icon': Icons.science_outlined,   'screen': 'simulation'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final user  = context.watch<UserProvider>();
    final C     = DC(false);
    final email = user.email ?? '';
    final total = _stats['totalEvidence'] ?? 0;
    final anc   = _stats['anchored'] ?? 0;
    final rate  = total > 0 ? '${((anc / total) * 100).toStringAsFixed(1)}%' : '0%';

    return buildDashboardScaffold(
      scaffoldKey: _scaffoldKey, role: 'prosecutor', email: email, title: 'Prosecutor Dashboard',
      sidebarExpanded: _sidebarExpanded, onToggleSidebar: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
      onRefresh: _loadAll, navItems: _navItems, onNavTap: _handleNav, onLogout: _logout, theme: theme,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FadeSlide(delayMs: 0, child: WelcomeBanner(email: email, role: 'prosecutor',
              subtitle: 'Prosecutor  ·  Review evidence · Verify blockchain records · Prepare for trial',
              stats: {'Evidence': '$total', 'Verified': '$anc', 'Rate': rate}, pulse: _pulse)),
          const SizedBox(height: 16),
          FadeSlide(delayMs: 100, child: StatsGrid(cards: [
            StatCard(C: C, label: 'Total Evidence',      value: '$total',                       sub: 'Available for review',   icon: Icons.gavel_outlined,          color: const Color(0xFF059669), loading: _statsLoading, onTap: () => _go(EvidenceListScreen(filterByCaseId: null))),
            StatCard(C: C, label: 'Blockchain Verified', value: '$anc',                         sub: 'On Polygon Amoy',        icon: Icons.link_rounded,            color: const Color(0xFF7C3AED), loading: _statsLoading, onTap: () => _go(const BlockchainViewerScreen())),
            StatCard(C: C, label: 'Integrity Rate',      value: rate,                           sub: 'Evidence authenticity',  icon: Icons.verified_user_outlined,  color: const Color(0xFF059669), loading: _statsLoading, onTap: () => _go(const VerifyEvidenceScreen())),
            StatCard(C: C, label: 'Tamper Alerts',       value: '${_stats['tampered'] ?? 0}',   sub: 'Compromised evidence',   icon: Icons.warning_amber_outlined,  color: const Color(0xFFDC2626), loading: _statsLoading, onTap: () => _go(const VerifyEvidenceScreen())),
          ])),
          const SizedBox(height: 16),
          _RR(activity: _actSec(C), actions: _actionsSec(C)),
          const SizedBox(height: 14),
          FadeSlide(delayMs: 450, child: BlockchainStatusBar(C: C, pulse: _pulse, onViewTap: () => _go(const BlockchainViewerScreen()))),
        ]),
      ),
    );
  }

  Widget _actSec(DC C) => FadeSlide(delayMs: 250, child: GlassCard(padding: const EdgeInsets.all(16), radius: 20,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _h('Recent Activity', Icons.history_rounded, const Color(0xFF059669), onTap: () => _go(EvidenceListScreen(filterByCaseId: null))),
        const SizedBox(height: 12),
        if (_actError != null) errorRow(C, _actError!, _loadActivity)
        else if (_actLoading) ...shimmerRows(C, 4)
        else if (_activity.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('No activity', style: TextStyle(color: Color(0xFF64748B), fontSize: 13))))
          else ...List.generate(_activity.length > 6 ? 6 : _activity.length, (i) => ActivityRow(C: C, item: _activity[i] as Map<String, dynamic>, isLast: i == (_activity.length > 6 ? 5 : _activity.length - 1))),
      ])));

  Widget _actionsSec(DC C) => FadeSlide(delayMs: 320, child: GlassCard(padding: const EdgeInsets.all(16), radius: 20,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _h('Prosecutor Actions', Icons.gavel_outlined, const Color(0xFF059669)),
        const SizedBox(height: 12),
        ActionCard(C: C, label: 'Review Evidence',     sub: 'Examine all case files',    icon: Icons.gavel_outlined,       color: const Color(0xFF059669), onTap: () => _go(EvidenceListScreen(filterByCaseId: null))),
        const SizedBox(height: 7),
        ActionCard(C: C, label: 'Verify Authenticity', sub: 'Re-upload file to verify',  icon: Icons.verified_outlined,    color: const Color(0xFF2563EB), onTap: () => _go(const VerifyEvidenceScreen())),
        const SizedBox(height: 7),
        ActionCard(C: C, label: 'View Custody Chain',  sub: 'Full transfer history',     icon: Icons.timeline_outlined,    color: const Color(0xFF7C3AED), onTap: () => _go(CustodyTimelineScreen(evidenceId: null))),
        const SizedBox(height: 7),
        ActionCard(C: C, label: 'Blockchain Proof',    sub: 'View on Polygonscan',       icon: Icons.link_rounded,         color: const Color(0xFF0284C7), onTap: () => _go(const BlockchainViewerScreen())),
        const SizedBox(height: 7),
        ActionCard(C: C, label: 'Risk Intelligence',   sub: 'Monitor anomalies',         icon: Icons.shield_outlined,      color: const Color(0xFFDC2626), onTap: () => _go(const RiskDashboardScreen())),
        const SizedBox(height: 7),
        ActionCard(C: C, label: 'Simulation Mode',     sub: 'Run demo scenarios',        icon: Icons.science_outlined,     color: const Color(0xFF7C3AED), onTap: () => _go(const SimulationScreen())),
      ])));

  Widget _h(String t, IconData ic, Color c, {VoidCallback? onTap}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [Container(width: 28, height: 28, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: c.withOpacity(0.1)), child: Icon(ic, size: 14, color: c)), const SizedBox(width: 8), Text(t, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700))]),
        if (onTap != null) GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: c.withOpacity(0.07), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(0.18))), child: Text('View all', style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w600)))),
      ]);
}
class _RR extends StatelessWidget {
  final Widget activity, actions;
  const _RR({required this.activity, required this.actions});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
    if (c.maxWidth < kMobile) return Column(children: [activity, const SizedBox(height: 12), actions]);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: activity), const SizedBox(width: 12), Expanded(flex: 2, child: actions)]);
  });
}