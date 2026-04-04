// lib/screens/dashboards/police_dashboard.dart
// Uses GlobalKey scaffold — no Scaffold.of() bug
// Risk Intelligence + Simulation Mode fully routed

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../dashboard_widgets.dart';
import '../dashboard_scaffold.dart';
import '../login_screen.dart';
import '../create_case_screen.dart';
import '../upload_evidence_screen.dart';
import '../evidence_list_screen.dart' show EvidenceListScreen;
import '../verify_evidence_screen.dart';
import '../custody_timeline_screen.dart' show CustodyTimelineScreen;
import '../blockchain_viewer_screen.dart';
import '../risk_dashboard_screen.dart';
import '../simulation_screen.dart';

class PoliceDashboard extends StatefulWidget {
  const PoliceDashboard({super.key});
  @override
  State<PoliceDashboard> createState() => _PoliceDashboardState();
}

class _PoliceDashboardState extends State<PoliceDashboard>
    with TickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _api = ApiService();
  bool _sidebarExpanded = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _activity = [];
  bool _statsLoading = true, _actLoading = true;
  String? _statsError, _actError;
  Timer? _refreshTimer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulse = _pulseCtrl.drive(
        Tween(begin: 0.96, end: 1.04)
            .chain(CurveTween(curve: Curves.easeInOut)));
    _loadAll();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadAll());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _loadStats();
    _loadActivity();
  }

  Future<void> _loadStats() async {
    setState(() {
      _statsLoading = true;
      _statsError = null;
    });
    try {
      final d = await _api.getDashboardStats();
      if (mounted) setState(() {
        _stats = d;
        _statsLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _statsError = 'Failed';
        _statsLoading = false;
      });
    }
  }

  Future<void> _loadActivity() async {
    setState(() {
      _actLoading = true;
      _actError = null;
    });
    try {
      final data = await _api.getRecentActivity();
      final items = <Map<String, dynamic>>[];
      for (final e in (data['recentEvidence'] as List? ?? [])) {
        items.add({...Map<String, dynamic>.from(e), '_type': 'evidence'});
      }
      for (final c in (data['recentCustody'] as List? ?? [])) {
        items.add({...Map<String, dynamic>.from(c), '_type': 'custody'});
      }
      items.sort((a, b) {
        final ta = DateTime.tryParse(a['createdAt'] ?? a['timestamp'] ?? '') ?? DateTime(0);
        final tb = DateTime.tryParse(b['createdAt'] ?? b['timestamp'] ?? '') ?? DateTime(0);
        return tb.compareTo(ta);
      });
      if (mounted) setState(() {
        _activity = items.take(8).toList();
        _actLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _actError = 'Failed to load activity';
        _actLoading = false;
      });
    }
  }

  void _go(Widget w) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
        context: context, builder: (_) => const LogoutDialog());
    if (ok == true && mounted) {
      context.read<UserProvider>().clear();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _handleNav(String screen) {
    switch (screen) {
      case 'create_case':
        _go(const CreateCaseScreen());
        break;
      case 'upload':
        _go(const UploadEvidenceScreen());
        break;
      case 'evidence':
        _go(EvidenceListScreen(filterByCaseId: null));
        break;
      case 'verify':
        _go(const VerifyEvidenceScreen());
        break;
      case 'custody':
        _go(CustodyTimelineScreen(evidenceId: null));
        break;
      case 'blockchain':
        _go(const BlockchainViewerScreen());
        break;
      case 'risk':
        _go(const RiskDashboardScreen());
        break;
      case 'simulation':
        _go(const SimulationScreen());
        break;
    }
  }

  static const _navItems = <Map<String, dynamic>>[
    {'label': 'MAIN', 'section': true},
    {
      'label': 'Create Case',
      'icon': Icons.create_new_folder_outlined,
      'screen': 'create_case'
    },
    {
      'label': 'Upload Evidence',
      'icon': Icons.upload_file_outlined,
      'screen': 'upload'
    },
    {
      'label': 'View Evidence',
      'icon': Icons.insert_drive_file_outlined,
      'screen': 'evidence'
    },
    {'label': 'ACTIONS', 'section': true},
    {
      'label': 'Verify Evidence',
      'icon': Icons.verified_outlined,
      'screen': 'verify'
    },
    {
      'label': 'Transfer Custody',
      'icon': Icons.swap_horiz_rounded,
      'screen': 'custody'
    },
    {'label': 'INTELLIGENCE', 'section': true},
    {
      'label': 'Risk Intelligence',
      'icon': Icons.shield_outlined,
      'screen': 'risk'
    },
    {
      'label': 'Simulation Mode',
      'icon': Icons.science_outlined,
      'screen': 'simulation'
    },
    {'label': 'BLOCKCHAIN', 'section': true},
    {
      'label': 'Blockchain Viewer',
      'icon': Icons.link_rounded,
      'screen': 'blockchain'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final user = context.watch<UserProvider>();
    final C = DC(false);
    final email = user.email ?? '';
    final total = _stats['totalEvidence'] ?? 0;
    final anchored = _stats['anchored'] ?? 0;

    return buildDashboardScaffold(
      scaffoldKey: _scaffoldKey,
      role: 'police',
      email: email,
      title: 'Police Dashboard',
      sidebarExpanded: _sidebarExpanded,
      onToggleSidebar: () =>
          setState(() => _sidebarExpanded = !_sidebarExpanded),
      onRefresh: () {
        _loadAll();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Refreshing...'),
          backgroundColor: const Color(0xFF4F46E5),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      },
      navItems: _navItems,
      onNavTap: _handleNav,
      onLogout: _logout,
      theme: theme,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FadeSlide(
            delayMs: 0,
            child: WelcomeBanner(
              email: email,
              role: 'police',
              subtitle:
              'Police Officer  ·  Create cases · Upload evidence · Monitor risk intelligence',
              stats: {
                'Cases': '${_stats['totalCases'] ?? 0}',
                'Evidence': '$total',
                'Anchored': '$anchored',
              },
              pulse: _pulse,
            ),
          ),
          const SizedBox(height: 16),
          FadeSlide(
            delayMs: 100,
            child: StatsGrid(cards: [
              StatCard(
                C: C,
                label: 'Active Cases',
                value: '${_stats['totalCases'] ?? 0}',
                sub: 'Open investigations',
                icon: Icons.folder_outlined,
                color: const Color(0xFF2563EB),
                loading: _statsLoading,
                onTap: () => _go(EvidenceListScreen(filterByCaseId: null)),
              ),
              StatCard(
                C: C,
                label: 'Evidence Uploaded',
                value: '$total',
                sub: 'Total files on record',
                icon: Icons.upload_file_outlined,
                color: const Color(0xFF7C3AED),
                loading: _statsLoading,
                onTap: () => _go(EvidenceListScreen(filterByCaseId: null)),
              ),
              StatCard(
                C: C,
                label: 'Blockchain Anchored',
                value: total > 0 ? '$anchored / $total' : '0',
                sub: 'Hash on Polygon Amoy',
                icon: Icons.verified_outlined,
                color: const Color(0xFF059669),
                loading: _statsLoading,
                onTap: () => _go(const BlockchainViewerScreen()),
              ),
              StatCard(
                C: C,
                label: 'Tamper Alerts',
                value: '${_stats['tampered'] ?? 0}',
                sub: 'Compromised evidence',
                icon: Icons.warning_amber_outlined,
                color: const Color(0xFFDC2626),
                loading: _statsLoading,
                onTap: () => _go(const VerifyEvidenceScreen()),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _ResponsiveRow(
            activity: _actSec(C),
            actions: _actionsSec(C),
          ),
          const SizedBox(height: 14),
          FadeSlide(
            delayMs: 450,
            child: BlockchainStatusBar(
              C: C,
              pulse: _pulse,
              onViewTap: () => _go(const BlockchainViewerScreen()),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _actSec(DC C) => FadeSlide(
    delayMs: 250,
    child: GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'Recent Activity',
              Icons.history_rounded,
              const Color(0xFF4F46E5),
              onTap: () => _go(EvidenceListScreen(filterByCaseId: null)),
            ),
            const SizedBox(height: 12),
            if (_actError != null)
              errorRow(C, _actError!, _loadActivity)
            else if (_actLoading)
              ...shimmerRows(C, 4)
            else if (_activity.isEmpty)
                _emptyState()
              else
                ...List.generate(
                  _activity.length > 6 ? 6 : _activity.length,
                      (i) => ActivityRow(
                    C: C,
                    item: _activity[i] as Map<String, dynamic>,
                    isLast: i ==
                        (_activity.length > 6 ? 5 : _activity.length - 1),
                  ),
                ),
          ]),
    ),
  );

  Widget _actionsSec(DC C) => FadeSlide(
    delayMs: 320,
    child: GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'Police Actions',
              Icons.local_police_outlined,
              const Color(0xFF2563EB),
            ),
            const SizedBox(height: 12),
            ActionCard(
              C: C,
              label: 'Create New Case',
              sub: 'Start a new investigation',
              icon: Icons.create_new_folder_outlined,
              color: const Color(0xFF2563EB),
              onTap: () => _go(const CreateCaseScreen()),
            ),
            const SizedBox(height: 7),
            ActionCard(
              C: C,
              label: 'Upload Evidence',
              sub: 'Add files to a case',
              icon: Icons.upload_file_outlined,
              color: const Color(0xFF7C3AED),
              onTap: () => _go(const UploadEvidenceScreen()),
            ),
            const SizedBox(height: 7),
            ActionCard(
              C: C,
              label: 'Transfer Custody',
              sub: 'Send evidence to forensic',
              icon: Icons.swap_horiz_rounded,
              color: const Color(0xFF059669),
              onTap: () => _go(CustodyTimelineScreen(evidenceId: null)),
            ),
            const SizedBox(height: 7),
            ActionCard(
              C: C,
              label: 'Risk Intelligence',
              sub: 'Monitor anomalies & alerts',
              icon: Icons.shield_outlined,
              color: const Color(0xFFDC2626),
              onTap: () => _go(const RiskDashboardScreen()),
            ),
            const SizedBox(height: 7),
            ActionCard(
              C: C,
              label: 'Simulation Mode',
              sub: 'Run demo risk scenarios',
              icon: Icons.science_outlined,
              color: const Color(0xFF7C3AED),
              onTap: () => _go(const SimulationScreen()),
            ),
            const SizedBox(height: 7),
            ActionCard(
              C: C,
              label: 'View All Evidence',
              sub: 'Browse all uploaded files',
              icon: Icons.insert_drive_file_outlined,
              color: const Color(0xFFD97706),
              onTap: () => _go(EvidenceListScreen(filterByCaseId: null)),
            ),
          ]),
    ),
  );

  Widget _emptyState() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 18),
    child: Center(
        child: Text('No activity yet',
            style:
            TextStyle(color: Color(0xFF64748B), fontSize: 13))),
  );

  Widget _sectionHeader(String title, IconData icon, Color color,
      {VoidCallback? onTap}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: color.withOpacity(0.1)),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ]),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.18)),
              ),
              child: Text('View all',
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          ),
      ]);
}

class _ResponsiveRow extends StatelessWidget {
  final Widget activity, actions;
  const _ResponsiveRow({required this.activity, required this.actions});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
    if (c.maxWidth < kMobile) {
      return Column(children: [
        activity,
        const SizedBox(height: 12),
        actions,
      ]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 3, child: activity),
      const SizedBox(width: 12),
      Expanded(flex: 2, child: actions),
    ]);
  });
}