// prosecutor_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../dashboard_widgets.dart';
import '../login_screen.dart';
import '../evidence_list_screen.dart';
import '../verify_evidence_screen.dart';
import '../custody_timeline_screen.dart';
import '../blockchain_viewer_screen.dart';

class ProsecutorDashboard extends StatefulWidget {
  const ProsecutorDashboard({super.key});
  @override
  State<ProsecutorDashboard> createState() => _ProsecutorDashboardState();
}

class _ProsecutorDashboardState extends State<ProsecutorDashboard>
    with TickerProviderStateMixin {
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

  @override
  void dispose() { _timer?.cancel(); _pulseCtrl.dispose(); super.dispose(); }

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
      for (final c in (data['recentCustody'] as List? ?? [])) items.add({...Map<String, dynamic>.from(c), '_type': 'custody'});
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
    }
  }

  static const _navItems = [
    {'label': 'REVIEW', 'section': true},
    {'label': 'View Evidence',     'icon': Icons.gavel_outlined,              'screen': 'evidence'},
    {'label': 'Verify Authenticity','icon': Icons.verified_outlined,          'screen': 'verify'},
    {'label': 'LEGAL', 'section': true},
    {'label': 'Custody Chain',     'icon': Icons.timeline_outlined,           'screen': 'custody'},
    {'label': 'BLOCKCHAIN', 'section': true},
    {'label': 'Blockchain Proof',  'icon': Icons.link_rounded,                'screen': 'blockchain'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final user  = context.watch<UserProvider>();
    final C     = DC(theme.isDark);
    final total = _stats['totalEvidence'] ?? 0;
    final anchored = _stats['anchored'] ?? 0;
    final rate = total > 0 ? '${((anchored / total) * 100).toStringAsFixed(1)}%' : '0%';

    return Scaffold(
      backgroundColor: C.bg,
      body: Row(children: [
        DashboardSidebar(C: C, expanded: _sidebarExpanded, role: 'prosecutor',
            email: user.email ?? '', navItems: _navItems, onNavTap: _handleNav, onLogout: _logout),
        Expanded(child: Column(children: [
          DashboardAppBar(C: C, title: 'Prosecutor Dashboard', sidebarExpanded: _sidebarExpanded,
              onMenuTap: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
              onRefresh: _loadAll, theme: theme, role: 'prosecutor'),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 22, 26, 26),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _banner(C, user.email ?? '', total, rate),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: StatCard(C: C, label: 'Total Evidence', value: '$total',
                    sub: 'Available for review', icon: Icons.gavel_outlined,
                    color: const Color(0xFF059669), loading: _statsLoading,
                    onTap: () => _go(EvidenceListScreen(filterByCaseId: null)))),
                const SizedBox(width: 14),
                Expanded(child: StatCard(C: C, label: 'Blockchain Verified', value: '$anchored',
                    sub: 'On Polygon Amoy', icon: Icons.link_rounded,
                    color: const Color(0xFF7C3AED), loading: _statsLoading,
                    onTap: () => _go(const BlockchainViewerScreen()))),
                const SizedBox(width: 14),
                Expanded(child: StatCard(C: C, label: 'Integrity Rate', value: rate,
                    sub: 'Evidence authenticity', icon: Icons.verified_user_outlined,
                    color: const Color(0xFF059669), loading: _statsLoading,
                    onTap: () => _go(const VerifyEvidenceScreen()))),
                const SizedBox(width: 14),
                Expanded(child: StatCard(C: C, label: 'Tamper Alerts', value: '${_stats['tampered'] ?? 0}',
                    sub: 'Compromised evidence', icon: Icons.warning_amber_outlined,
                    color: const Color(0xFFDC2626), loading: _statsLoading,
                    onTap: () => _go(const VerifyEvidenceScreen()))),
              ]),
              const SizedBox(height: 24),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: _actSection(C)),
                const SizedBox(width: 18),
                Expanded(flex: 2, child: _actionsSection(C)),
              ]),
              const SizedBox(height: 18),
              BlockchainStatusBar(C: C, pulse: _pulse, onViewTap: () => _go(const BlockchainViewerScreen())),
            ]),
          )),
        ])),
      ]),
    );
  }

  Widget _banner(DC C, String email, int total, String rate) {
    final h = DateTime.now().hour;
    final g = h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
    return Container(width: double.infinity, padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: C.isDark ? [const Color(0xFF064E3B), const Color(0xFF022C22), const Color(0xFF011912)]
                    : [const Color(0xFF059669), const Color(0xFF047857), const Color(0xFF065F46)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: const Color(0xFF059669).withOpacity(C.isDark ? 0.1 : 0.25), blurRadius: 24, offset: const Offset(0, 8))]),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 10),
            Text('$g, ${email.split('@').first}!', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const SizedBox(height: 4),
            Text('Prosecutor  ·  Review evidence · Verify blockchain records · Prepare for trial', style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 12)),
          ])),
          _bs('Evidence', '$total'), const SizedBox(width: 10), _bs('Rate', rate),
        ]));
  }

  Widget _bs(String l, String v) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withOpacity(0.2))),
      child: Column(children: [Text(v, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)), Text(l, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10))]));

  Widget _actSection(DC C) => Container(padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(13), border: Border.all(color: C.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Recent Activity', style: TextStyle(color: C.txtPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          GestureDetector(onTap: () => _go(EvidenceListScreen(filterByCaseId: null)),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: C.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: C.accent.withOpacity(0.22))),
                  child: Text('View all', style: TextStyle(color: C.accent, fontSize: 11, fontWeight: FontWeight.w600)))),
        ]),
        const SizedBox(height: 14),
        if (_actError != null) errorRow(C, _actError!, _loadActivity)
        else if (_actLoading) ...shimmerRows(C, 4)
        else if (_activity.isEmpty) Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text('No activity', style: TextStyle(color: C.txtSecond))))
          else ...List.generate(_activity.length > 6 ? 6 : _activity.length, (i) =>
                ActivityRow(C: C, item: _activity[i] as Map<String, dynamic>, isLast: i == (_activity.length > 6 ? 5 : _activity.length - 1))),
      ]));

  Widget _actionsSection(DC C) => Container(padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(13), border: Border.all(color: C.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.gavel_outlined, size: 15, color: const Color(0xFF059669)), const SizedBox(width: 7),
          Text('Prosecutor Actions', style: TextStyle(color: C.txtPrimary, fontSize: 14, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 14),
        ActionCard(C: C, label: 'Review Evidence', sub: 'Examine all case files', icon: Icons.gavel_outlined, color: const Color(0xFF059669), onTap: () => _go(EvidenceListScreen(filterByCaseId: null))),
        const SizedBox(height: 8),
        ActionCard(C: C, label: 'Verify Authenticity', sub: 'Re-upload file to verify', icon: Icons.verified_outlined, color: const Color(0xFF2563EB), onTap: () => _go(const VerifyEvidenceScreen())),
        const SizedBox(height: 8),
        ActionCard(C: C, label: 'View Custody Chain', sub: 'Full transfer history', icon: Icons.timeline_outlined, color: const Color(0xFF7C3AED), onTap: () => _go(CustodyTimelineScreen(evidenceId: null))),
        const SizedBox(height: 8),
        ActionCard(C: C, label: 'Blockchain Proof', sub: 'View on Polygonscan', icon: Icons.link_rounded, color: const Color(0xFF0284C7), onTap: () => _go(const BlockchainViewerScreen())),
      ]));
}