// custody_timeline_screen.dart
// Premium Glassmorphism UI — fully responsive (mobile + tablet + desktop)
// All original logic 100% preserved. Zero pixel overflow. No theme toggle.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

// ── Breakpoints ───────────────────────────────────────────────
const double _kMobile = 600;
const double _kTablet = 1024;

// ── Design tokens ─────────────────────────────────────────────
const Color _kPurple  = Color(0xFF7C3AED);
const Color _kBlue    = Color(0xFF2563EB);
const Color _kGreen   = Color(0xFF059669);
const Color _kAmber   = Color(0xFFD97706);
const Color _kRed     = Color(0xFFDC2626);
const Color _kBgBase  = Color(0xFFEEF2FF);
const Color _kBorderIdle = Color(0xFFD1D5DB);

class CustodyTimelineScreen extends StatefulWidget {
  final String? evidenceId;
  const CustodyTimelineScreen({super.key, required this.evidenceId});
  @override
  State<CustodyTimelineScreen> createState() => _CustodyTimelineScreenState();
}

class _CustodyTimelineScreenState extends State<CustodyTimelineScreen>
    with TickerProviderStateMixin {

  // ── Original state (all preserved) ───────────────────────────
  final _api = ApiService();

  Map<String, dynamic>?  _evidenceData;
  List<dynamic>          _chain        = [];
  List<dynamic>          _allEvidence  = [];
  String?                _selectedEvidenceId;
  Map<String, dynamic>?  _currentCustodian;

  bool    _loading         = true;
  bool    _evidenceLoading = true;
  bool    _transfering     = false;
  bool    _canTransfer     = false;
  String? _error;
  String? _successMsg;

  final _toUserCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();
  String? _toRole;
  List<Map<String, dynamic>> _allowedRoles = [];

  late TabController _tabCtrl;

  // ── Animations ────────────────────────────────────────────────
  late AnimationController _bgCtrl;
  late Animation<double>   _bgAnim;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulse;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);

    _bgCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
    _bgAnim  = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulse     = _pulseCtrl.drive(Tween(begin: 0.93, end: 1.07).chain(CurveTween(curve: Curves.easeInOut)));

    if (widget.evidenceId != null) _selectedEvidenceId = widget.evidenceId;
    _loadInitial();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    _toUserCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Original logic (all preserved exactly) ───────────────────
  Future<void> _loadInitial() async {
    await Future.wait([_loadAllEvidence(), _loadAllowedRoles()]);
    if (_selectedEvidenceId != null && mounted) {
      await _loadChain(_selectedEvidenceId!);
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAllEvidence() async {
    if (mounted) setState(() => _evidenceLoading = true);
    try {
      final cases = await _api.getAllCases();
      final List<dynamic> all = [];
      for (final c in cases) {
        try {
          final ev = await _api.getEvidenceByCase(c['_id'].toString());
          for (final e in ev) {
            all.add({...Map<String, dynamic>.from(e), 'caseTitle': c['title'] ?? 'Case'});
          }
        } catch (_) {}
      }
      if (mounted) setState(() { _allEvidence = all; _evidenceLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _evidenceLoading = false);
    }
  }

  Future<void> _loadAllowedRoles() async {
    try {
      final data = await _api.getAllowedRoles();
      if (mounted) {
        final roles = List<Map<String, dynamic>>.from(data['allowedRoles'] ?? []);
        setState(() { _allowedRoles = roles; _canTransfer = roles.isNotEmpty; });
      }
    } catch (_) {}
  }

  Future<void> _loadChain(String evidenceId) async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getCustodyHistory(evidenceId);
      if (mounted) setState(() {
        _evidenceData     = data['evidence'] as Map<String, dynamic>?;
        _chain            = data['chain'] as List? ?? [];
        _currentCustodian = data['currentCustodian'] as Map<String, dynamic>?;
        _loading          = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load: $e'; _loading = false; });
    }
  }

  Future<void> _transfer() async {
    final toUser = _toUserCtrl.text.trim();
    final reason = _reasonCtrl.text.trim();
    final notes  = _notesCtrl.text.trim();
    if (_selectedEvidenceId == null) { _showErr('Select an evidence item first'); return; }
    if (toUser.isEmpty)              { _showErr('Enter the recipient UID or email'); return; }
    if (_toRole == null)             { _showErr('Select the recipient role'); return; }
    if (reason.isEmpty)              { _showErr('Enter the reason for transfer'); return; }

    setState(() { _transfering = true; _error = null; _successMsg = null; });
    try {
      final result = await _api.transferCustody(
          _selectedEvidenceId!, toUser, reason, toRole: _toRole!, notes: notes);
      if (mounted) {
        setState(() {
          _transfering = false;
          _successMsg  = 'Custody transferred to ${result['to']?['name'] ?? toUser}';
          _toUserCtrl.clear(); _reasonCtrl.clear(); _notesCtrl.clear(); _toRole = null;
        });
        _loadChain(_selectedEvidenceId!);
        _tabCtrl.animateTo(0);
      }
    } catch (e) {
      if (mounted) setState(() {
        _transfering = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showErr(String msg) => setState(() { _error = msg; _successMsg = null; });

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$label copied'),
      backgroundColor: _kGreen,
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserProvider>().role ?? 'police';
    return Scaffold(
      backgroundColor: _kBgBase,
      body: Stack(children: [
        Positioned.fill(child: _AnimBg(anim: _bgAnim)),
        SafeArea(child: Column(children: [
          _buildAppBar(role),
          _buildPicker(),
          _buildTabBar(),
          Expanded(child: _buildTabContent(role)),
        ])),
      ]),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────
  Widget _buildAppBar(String role) {
    return ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
        height: 60,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.70),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5)))),
        child: Row(children: [
          _ABBtn(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
          const SizedBox(width: 8),
          Container(width: 32, height: 32,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [_kPurple, Color(0xFF4F46E5)])),
              child: const Icon(Icons.timeline_outlined, color: Colors.white, size: 16)),
          const SizedBox(width: 10),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Chain of Custody', overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                Text(_canTransfer ? 'View history & transfer evidence' : 'View custody history',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
              ])),
          const SizedBox(width: 8),
          AnimatedBuilder(animation: _pulse, builder: (_, __) =>
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: _roleColor(role).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _roleColor(role).withOpacity(0.28))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_roleIcon(role), size: 11, color: _roleColor(role)),
                    const SizedBox(width: 4),
                    Text(_roleLabel(role), style: TextStyle(color: _roleColor(role),
                        fontSize: 10, fontWeight: FontWeight.w600)),
                  ]))),
        ]),
      ),
    ));
  }

  // ── Evidence Picker ────────────────────────────────────────────
  Widget _buildPicker() {
    return ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.58),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5)))),
          child: _evidenceLoading
              ? Row(children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: _kPurple, strokeWidth: 2)),
            const SizedBox(width: 10),
            const Text('Loading evidence...', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ])
              : _allEvidence.isEmpty
              ? Row(children: [
            const Icon(Icons.info_outline, size: 16, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 8),
            const Text('No evidence found', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          ])
              : Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorderIdle, width: 1.2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: _selectedEvidenceId,
                isExpanded: true,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF9CA3AF)),
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                hint: const Text('Choose evidence to view custody chain',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                items: _allEvidence.map((ev) {
                  final id    = ev['_id']?.toString() ?? '';
                  final name  = ev['fileName'] as String? ?? 'Unknown';
                  final caseT = ev['caseTitle'] as String? ?? '';
                  return DropdownMenuItem<String>(value: id,
                      child: Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Container(width: 28, height: 28,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: _kPurple.withOpacity(0.08)),
                                child: const Icon(Icons.insert_drive_file_outlined, size: 14, color: _kPurple)),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min, children: [
                                  Text(name, overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600)),
                                  if (caseT.isNotEmpty)
                                    Text(caseT, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                                ])),
                          ])));
                }).toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() => _selectedEvidenceId = val);
                  _loadChain(val);
                },
              ))),
        )));
  }

  // ── Tab Bar ────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.65),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5)))),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: _kPurple,
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: _kPurple,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            onTap: (i) { if (i == 1 && !_canTransfer) _tabCtrl.animateTo(0); },
            tabs: [
              const Tab(icon: Icon(Icons.timeline_outlined, size: 16), text: 'Chain of Custody'),
              Tab(
                icon: Icon(Icons.swap_horiz_rounded, size: 16,
                    color: _canTransfer ? null : const Color(0xFF9CA3AF)),
                child: Text('Transfer Custody',
                    style: TextStyle(color: _canTransfer ? null : const Color(0xFF9CA3AF))),
              ),
            ],
          ),
        )));
  }

  // ── Tab content ────────────────────────────────────────────────
  Widget _buildTabContent(String role) {
    return TabBarView(
      controller: _tabCtrl,
      physics: _canTransfer ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
      children: [
        _chainView(),
        _canTransfer
            ? SingleChildScrollView(child: _transferView(role))
            : _noPermView(role),
      ],
    );
  }

  // ── Chain View ─────────────────────────────────────────────────
  Widget _chainView() {
    if (_selectedEvidenceId == null) return _emptyPickerState();
    if (_loading) return _loadingState();
    if (_error != null) return _errorState();

    return LayoutBuilder(builder: (_, constraints) {
      final w         = constraints.maxWidth;
      final isDesktop = w >= _kTablet;

      if (isDesktop) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 320, child: _sidePanel()),
          Container(width: 1, color: Colors.white.withOpacity(0.5)),
          Expanded(child: _timelineList()),
        ]);
      }
      return _mobileChainView();
    });
  }

  Widget _mobileChainView() => ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
      children: [
        if (_evidenceData != null) ...[_evSummaryCard(_evidenceData!), const SizedBox(height: 14)],
        if (_currentCustodian != null) ...[_custodianCard(_currentCustodian!), const SizedBox(height: 14)],
        _sectionHeader('Custody Timeline', Icons.timeline_outlined, _kPurple, count: _chain.length),
        const SizedBox(height: 12),
        if (_chain.isEmpty) _emptyChain()
        else ..._chain.asMap().entries.map((e) => _chainEventCard(e.value, e.key, _chain.length)),
      ]);

  Widget _sidePanel() => ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        if (_evidenceData != null) ...[_evSummaryCard(_evidenceData!), const SizedBox(height: 14)],
        if (_currentCustodian != null) ...[_custodianCard(_currentCustodian!), const SizedBox(height: 14)],
        _GlassCard(child: Padding(padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _PanelHdr(icon: Icons.info_outline_rounded, label: 'Evidence Summary', color: _kBlue),
              const SizedBox(height: 12),
              _infoRow('Total Events', '${_chain.length}'),
              _infoRow('Transfers', '${_chain.where((e) => e['type'] == 'transfer').length}'),
              _infoRow('Status', (_evidenceData?['blockchainStatus'] ?? 'pending').toString().toUpperCase(),
                  color: _statusColor(_evidenceData?['blockchainStatus'] ?? 'pending')),
              if (_evidenceData?['isTampered'] == true)
                _infoRow('Integrity', 'TAMPERED', color: _kRed),
            ]))),
      ]);

  Widget _timelineList() => ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        _sectionHeader('Custody Timeline', Icons.timeline_outlined, _kPurple, count: _chain.length),
        const SizedBox(height: 16),
        if (_chain.isEmpty) _emptyChain()
        else ..._chain.asMap().entries.map((e) => _chainEventCard(e.value, e.key, _chain.length)),
      ]);

  Widget _infoRow(String label, String value, {Color? color}) =>
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11))),
        Text(value, style: TextStyle(color: color ?? const Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.w700)),
      ]));

  // ── Evidence Summary Card ──────────────────────────────────────
  Widget _evSummaryCard(Map ev) {
    final tampered = ev['isTampered'] == true;
    final status   = ev['blockchainStatus'] as String? ?? 'pending';
    return _GlassCard(tint: tampered ? const Color(0xFFFFF1F2) : null,
        child: Padding(padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 42, height: 42,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(colors: tampered
                            ? [_kRed, _kRed.withOpacity(0.7)]
                            : [_kPurple, const Color(0xFF4F46E5)]),
                        boxShadow: [BoxShadow(color: (tampered ? _kRed : _kPurple).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))]),
                    child: Icon(tampered ? Icons.warning_amber_rounded : Icons.insert_drive_file_outlined,
                        size: 20, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ev['fileName'] as String? ?? '—', overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    _StatusBadge(status: status),
                    if (tampered) ...[const SizedBox(width: 6), _StatusBadge(status: 'tampered')],
                  ]),
                ])),
              ]),
              if (tampered) ...[
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _kRed.withOpacity(0.06), borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kRed.withOpacity(0.25))),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: _kRed),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                          'Integrity compromised · Tampered at ${_fmtDate(ev['tamperedAt']?.toString())}',
                          style: const TextStyle(color: _kRed, fontSize: 11))),
                    ])),
              ],
              const SizedBox(height: 12),
              Container(height: 1, color: Colors.white.withOpacity(0.6)),
              const SizedBox(height: 12),
              // Info grid — use Wrap to prevent overflow
              Wrap(spacing: 0, runSpacing: 8, children: [
                _infoChip('Evidence ID', _short(ev['id']?.toString() ?? ''),
                    copy: true, copyVal: ev['id']?.toString()),
                _infoChip('Case ID', _short(ev['caseId']?.toString() ?? '')),
                _infoChip('Uploaded', _fmtDate(ev['createdAt']?.toString())),
              ]),
              const SizedBox(height: 6),
              _hashRow('SHA-256', ev['fileHash'] as String? ?? '—',
                  copyVal: ev['fileHash'] as String?),
              if ((ev['blockchainTxHash'] as String? ?? '').isNotEmpty)
                _hashRow('TX Hash', ev['blockchainTxHash'] as String,
                    copyVal: ev['blockchainTxHash'] as String?),
            ])));
  }

  Widget _infoChip(String label, String value, {bool copy = false, String? copyVal}) =>
      SizedBox(width: double.infinity, child: Padding(padding: const EdgeInsets.only(bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.w600))),
            Expanded(child: Text(value, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.w600))),
            if (copy && copyVal != null)
              GestureDetector(onTap: () => _copy(copyVal, label),
                  child: const Icon(Icons.copy_outlined, size: 11, color: Color(0xFF9CA3AF))),
          ])));

  Widget _hashRow(String label, String value, {String? copyVal}) =>
      Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.w600))),
        Expanded(child: SelectableText(value, style: const TextStyle(color: _kPurple, fontSize: 11, fontFamily: 'monospace'))),
        if (copyVal != null)
          GestureDetector(onTap: () => _copy(copyVal, label),
              child: const Icon(Icons.copy_outlined, size: 11, color: Color(0xFF9CA3AF))),
      ]));

  // ── Custodian Card ─────────────────────────────────────────────
  Widget _custodianCard(Map custodian) {
    final role = custodian['role'] as String? ?? 'police';
    final name = custodian['name'] as String? ?? '—';
    return _GlassCard(child: Padding(padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_roleColor(role), _roleColor(role).withOpacity(0.75)]),
                  boxShadow: [BoxShadow(color: _roleColor(role).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))]),
              child: Icon(_roleIcon(role), size: 22, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Current Custodian', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            const SizedBox(height: 3),
            Text(name, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w800)),
            Text(_roleLabel(role), style: TextStyle(color: _roleColor(role), fontSize: 11, fontWeight: FontWeight.w600)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(color: _kGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kGreen.withOpacity(0.28))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AnimatedBuilder(animation: _pulse, builder: (_, __) =>
                    Transform.scale(scale: _pulse.value,
                        child: Container(width: 6, height: 6,
                            decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)))),
                const SizedBox(width: 5),
                const Text('In Custody', style: TextStyle(color: _kGreen, fontSize: 10, fontWeight: FontWeight.w700)),
              ])),
        ])));
  }

  // ── Section Header ─────────────────────────────────────────────
  Widget _sectionHeader(String label, IconData icon, Color color, {int? count}) =>
      Row(children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            margin: const EdgeInsets.only(right: 10)),
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w800)),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.2))),
              child: Text('$count events', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700))),
        ],
      ]);

  // ── Chain Event Card ───────────────────────────────────────────
  Widget _chainEventCard(Map event, int index, int total) {
    final type     = event['type'] as String? ?? 'transfer';
    final isFirst  = index == 0;
    final isLast   = index == total - 1;
    final isUpload = type == 'upload';
    final color    = isUpload ? _kBlue : _kPurple;

    return Padding(padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Spine
          SizedBox(width: 40, child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center, children: [
                if (!isFirst) Container(width: 2, height: 14, color: _kPurple.withOpacity(0.25)),
                Container(width: 38, height: 38,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [color, color.withOpacity(0.75)]),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))]),
                    child: Icon(isUpload ? Icons.cloud_upload_outlined : Icons.swap_horiz_rounded,
                        color: Colors.white, size: 17)),
                if (!isLast) Container(width: 2, height: 40, color: _kPurple.withOpacity(0.25)),
              ])),
          const SizedBox(width: 12),
          Expanded(child: _GlassCard(
              child: Padding(padding: const EdgeInsets.all(14),
                  child: isUpload ? _uploadEvent(event) : _transferEvent(event)))),
        ]));
  }

  Widget _uploadEvent(Map ev) {
    final bs = ev['status'] as String? ?? 'pending';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Evidence Uploaded & Registered',
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(_fmtDate(ev['timestamp']?.toString()),
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
        ])),
        _StatusBadge(status: 'upload'),
      ]),
      const SizedBox(height: 10),
      _evRow(Icons.person_outline_rounded, 'Uploaded by', ev['actor']?.toString() ?? '—'),
      _evRow(Icons.link_rounded, 'Blockchain', bs.toUpperCase(), color: _statusColor(bs)),
      if ((ev['txHash'] as String? ?? '').isNotEmpty)
        _evRow(Icons.tag_rounded, 'TX Hash', _short(ev['txHash'] as String),
            mono: true, copy: true, copyVal: ev['txHash'] as String),
      if ((ev['hash'] as String? ?? '').isNotEmpty)
        _evRow(Icons.fingerprint_rounded, 'Hash', _short(ev['hash'] as String, 14),
            mono: true, copy: true, copyVal: ev['hash'] as String),
    ]);
  }

  Widget _transferEvent(Map ev) {
    final fr = ev['fromRole'] as String? ?? 'police';
    final tr = ev['toRole']   as String? ?? 'police';
    final fn = ev['fromName'] as String? ?? '—';
    final tn = ev['toName']   as String? ?? '—';
    final rs = ev['reason']   as String? ?? '—';
    final nt = ev['notes']    as String? ?? '';
    final ps = ev['position'] as int? ?? 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Custody Transfer #$ps',
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(_fmtDate(ev['timestamp']?.toString()),
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
        ])),
        _StatusBadge(status: 'transfer'),
      ]),
      const SizedBox(height: 12),
      // From → To card — use Wrap to prevent overflow on very small screens
      Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.7))),
          child: LayoutBuilder(builder: (_, c) {
            // On very narrow screens stack vertically
            if (c.maxWidth < 280) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _rolePill(fn, fr, label: 'FROM'),
                Padding(padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Center(child: Container(padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: _kPurple.withOpacity(0.08), shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_downward_rounded, size: 14, color: _kPurple)))),
                _rolePill(tn, tr, label: 'TO', alignEnd: true),
              ]);
            }
            return Row(children: [
              Expanded(child: _rolePill(fn, fr, label: 'FROM')),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: _kPurple.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.arrow_forward_rounded, size: 14, color: _kPurple))),
              Expanded(child: _rolePill(tn, tr, label: 'TO', alignEnd: true)),
            ]);
          })),
      const SizedBox(height: 10),
      _evRow(Icons.info_outline_rounded, 'Reason', rs),
      if (nt.isNotEmpty) _evRow(Icons.notes_rounded, 'Notes', nt),
      if ((ev['hash'] as String? ?? '').isNotEmpty)
        _evRow(Icons.fingerprint_rounded, 'Hash', _short(ev['hash'] as String, 14),
            mono: true, copy: true, copyVal: ev['hash'] as String),
    ]);
  }

  Widget _rolePill(String name, String role, {required String label, bool alignEnd = false}) =>
      Column(crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start, children: [
          if (!alignEnd) ...[
            Container(width: 26, height: 26,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _roleColor(role).withOpacity(0.1)),
                child: Icon(_roleIcon(role), size: 13, color: _roleColor(role))),
            const SizedBox(width: 6),
          ],
          Flexible(child: Column(crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
            Text(name, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.w700)),
            Text(_roleLabel(role), style: TextStyle(color: _roleColor(role), fontSize: 9, fontWeight: FontWeight.w600)),
          ])),
          if (alignEnd) ...[
            const SizedBox(width: 6),
            Container(width: 26, height: 26,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _roleColor(role).withOpacity(0.1)),
                child: Icon(_roleIcon(role), size: 13, color: _roleColor(role))),
          ],
        ]),
      ]);

  Widget _evRow(IconData icon, String label, String value,
      {bool mono = false, bool copy = false, String? copyVal, Color? color}) =>
      Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 12, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 6),
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11))),
        Flexible(child: SelectableText(value, style: TextStyle(
            color: color ?? const Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.w600,
            fontFamily: mono ? 'monospace' : null))),
        if (copy && copyVal != null)
          GestureDetector(onTap: () => _copy(copyVal, label),
              child: const Padding(padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.copy_outlined, size: 11, color: Color(0xFF9CA3AF)))),
      ]));

  Widget _emptyChain() => _GlassCard(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: _kPurple.withOpacity(0.06)),
            child: const Icon(Icons.timeline_outlined, size: 28, color: _kPurple)),
        const SizedBox(height: 14),
        const Text('No transfers yet', style: TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('This evidence has not been transferred',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
      ])));

  // ── Transfer View ──────────────────────────────────────────────
  Widget _transferView(String role) => Padding(padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _permissionBanner(role),
        const SizedBox(height: 16),
        if (_successMsg != null) ...[_successBanner(), const SizedBox(height: 12)],
        if (_error != null)      ...[_errorBanner(),   const SizedBox(height: 12)],
        if (_selectedEvidenceId == null)
          _remindSelectCard()
        else ...[
          _GlassCard(child: Padding(padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionHeader('Transfer Details', Icons.swap_horiz_rounded, _kPurple),
                const SizedBox(height: 18),

                _FieldLabel(label: 'Recipient UID or Email'),
                const SizedBox(height: 6),
                _PremiumField(ctrl: _toUserCtrl, hint: 'Enter Firebase UID or email address',
                    icon: Icons.person_outline_rounded),
                const SizedBox(height: 14),

                _FieldLabel(label: 'Recipient Role'),
                const SizedBox(height: 6),
                _roleDd(),
                const SizedBox(height: 14),

                _FieldLabel(label: 'Reason for Transfer'),
                const SizedBox(height: 6),
                _PremiumField(ctrl: _reasonCtrl, hint: 'e.g. Forwarding for forensic analysis',
                    icon: Icons.info_outline_rounded, maxLines: 3),
                const SizedBox(height: 14),

                _FieldLabel(label: 'Additional Notes (Optional)'),
                const SizedBox(height: 6),
                _PremiumField(ctrl: _notesCtrl, hint: 'Any additional information...',
                    icon: Icons.notes_rounded, maxLines: 2),
                const SizedBox(height: 22),

                // Transfer button
                Container(width: double.infinity, height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: _transfering ? null : const LinearGradient(colors: [_kPurple, Color(0xFF4F46E5)]),
                      color: _transfering ? _kPurple.withOpacity(0.4) : null,
                      boxShadow: _transfering ? [] : [BoxShadow(color: _kPurple.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Material(color: Colors.transparent,
                        child: InkWell(onTap: _transfering ? null : _transfer, borderRadius: BorderRadius.circular(14),
                            child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                              _transfering
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                              Text(_transfering ? 'Transferring...' : 'Transfer Custody',
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                            ]))))),
                const SizedBox(height: 10),
                Center(child: const Text('Transfer will be recorded on the blockchain.\nHash at time of transfer will be saved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, height: 1.5))),
              ]))),
        ],
      ]));

  Widget _noPermView(String role) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 68, height: 68, decoration: BoxDecoration(shape: BoxShape.circle, color: _roleColor(role).withOpacity(0.07)),
        child: Icon(_roleIcon(role), size: 32, color: _roleColor(role).withOpacity(0.5))),
    const SizedBox(height: 16),
    const Text('No Transfer Permission', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text('${_roleLabel(role)} cannot transfer evidence.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13))),
  ]));

  Widget _permissionBanner(String role) => _GlassCard(
      tint: Color.lerp(_roleColor(role).withOpacity(0.05), Colors.white, 0.5),
      child: Padding(padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 36, height: 36,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: _roleColor(role).withOpacity(0.1)),
                child: Icon(_roleIcon(role), size: 18, color: _roleColor(role))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_roleLabel(role)} — Transfer Permissions',
                  style: TextStyle(color: _roleColor(role), fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(_allowedRoles.isEmpty
                  ? 'You cannot transfer evidence in your role.'
                  : 'Can transfer to: ${_allowedRoles.map((r) => r['label']).join(', ')}',
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 11, height: 1.4)),
            ])),
          ])));

  Widget _roleDd() => Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.75), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorderIdle, width: 1.2)),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: _toRole, isExpanded: true, dropdownColor: Colors.white,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF9CA3AF)),
        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
        hint: const Text('Select recipient role', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
        items: _allowedRoles.map((r) {
          final val = r['value'] as String;
          return DropdownMenuItem<String>(value: val,
              child: Row(children: [
                Icon(_roleIcon(val), size: 15, color: _roleColor(val)),
                const SizedBox(width: 8),
                Text(r['label'] as String, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13)),
              ]));
        }).toList(),
        onChanged: (v) => setState(() => _toRole = v),
      )));

  Widget _remindSelectCard() => _GlassCard(child: Padding(padding: const EdgeInsets.all(24),
      child: Column(children: [
        Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, color: _kPurple.withOpacity(0.07)),
            child: const Icon(Icons.insert_drive_file_outlined, size: 26, color: _kPurple)),
        const SizedBox(height: 12),
        const Text('Select an Evidence Item', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Use the dropdown above to select evidence',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
      ])));

  Widget _successBanner() => _GlassCard(tint: const Color(0xFFF0FDF4), child: Padding(padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: _kGreen.withOpacity(0.1)),
            child: const Icon(Icons.check_circle_outline_rounded, color: _kGreen, size: 16)),
        const SizedBox(width: 10),
        Expanded(child: Text(_successMsg!, style: const TextStyle(color: _kGreen, fontSize: 12, fontWeight: FontWeight.w600))),
        GestureDetector(onTap: () => setState(() => _successMsg = null),
            child: const Icon(Icons.close_rounded, size: 14, color: _kGreen)),
      ])));

  Widget _errorBanner() => _GlassCard(tint: const Color(0xFFFEF2F2), child: Padding(padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: _kRed.withOpacity(0.1)),
            child: const Icon(Icons.error_outline_rounded, color: _kRed, size: 16)),
        const SizedBox(width: 10),
        Expanded(child: Text(_error!, style: const TextStyle(color: _kRed, fontSize: 12))),
        GestureDetector(onTap: () => setState(() => _error = null),
            child: const Icon(Icons.close_rounded, size: 14, color: _kRed)),
      ])));

  // ── Empty / Loading / Error states ────────────────────────────
  Widget _emptyPickerState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, color: _kPurple.withOpacity(0.07)),
        child: const Icon(Icons.insert_drive_file_outlined, size: 30, color: _kPurple)),
    const SizedBox(height: 14),
    const Text('Select Evidence', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w700)),
    const SizedBox(height: 4),
    const Text('Choose an evidence item from the dropdown above',
        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
  ]));

  Widget _loadingState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    CircularProgressIndicator(color: _kPurple, strokeWidth: 2.5),
    const SizedBox(height: 14),
    const Text('Loading chain of custody...', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
  ]));

  Widget _errorState() => Center(child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded, size: 36, color: Color(0xFF9CA3AF)),
        const SizedBox(height: 10),
        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 14),
        GestureDetector(onTap: () => _loadChain(_selectedEvidenceId!),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kPurple, Color(0xFF4F46E5)]),
                    borderRadius: BorderRadius.circular(10)),
                child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
      ])));

  // ── Helpers ────────────────────────────────────────────────────
  Color _roleColor(String r) => switch (r) {
    'police'     => _kBlue,
    'forensic'   => _kPurple,
    'prosecutor' => _kGreen,
    'defense'    => const Color(0xFF0284C7),
    'court'      => _kAmber,
    _            => _kBlue,
  };

  IconData _roleIcon(String r) => switch (r) {
    'police'     => Icons.local_police_outlined,
    'forensic'   => Icons.biotech_outlined,
    'prosecutor' => Icons.gavel_outlined,
    'defense'    => Icons.balance_outlined,
    'court'      => Icons.account_balance_outlined,
    _            => Icons.person_outline,
  };

  String _roleLabel(String r) => switch (r) {
    'police'     => 'Police Officer',
    'forensic'   => 'Forensic Expert',
    'prosecutor' => 'Prosecutor',
    'defense'    => 'Defense Attorney',
    'court'      => 'Court Official',
    _            => r,
  };

  Color _statusColor(String s) => switch (s) {
    'anchored' => _kGreen,
    'pending'  => _kAmber,
    'failed'   => _kRed,
    _          => const Color(0xFF9CA3AF),
  };

  String _fmtDate(String? raw) {
    if (raw == null) return '—';
    final t = DateTime.tryParse(raw);
    if (t == null) return raw;
    final l = t.toLocal();
    return '${l.day.toString().padLeft(2,'0')}/${l.month.toString().padLeft(2,'0')}/${l.year}  ${l.hour.toString().padLeft(2,'0')}:${l.minute.toString().padLeft(2,'0')}';
  }

  String _short(String s, [int n = 10]) =>
      s.length > n * 2 + 3 ? '${s.substring(0, n)}…${s.substring(s.length - 7)}' : s;
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
      Positioned(left: -120 + t * 70, top: -90 + t * 50, child: _orb(320, _kPurple, 0.11)),
      Positioned(right: -80 + t * 40, bottom: 30 + t * 80, child: _orb(260, _kBlue, 0.09)),
      Positioned(left: MediaQuery.of(context).size.width * 0.4,
          top: MediaQuery.of(context).size.height * 0.35 - t * 50,
          child: _orb(180, _kGreen, 0.07)),
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6), spreadRadius: -2),
            BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 1, offset: const Offset(0, -1))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.65), width: 1.3),
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [(tint ?? Colors.white).withOpacity(0.90), (tint ?? Colors.white).withOpacity(0.58)])),
                  child: child))));
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color => switch (status) {
    'anchored'  => _kGreen,
    'pending'   => _kAmber,
    'failed'    => _kRed,
    'tampered'  => _kRed,
    'upload'    => _kBlue,
    'transfer'  => _kPurple,
    _           => const Color(0xFF9CA3AF),
  };

  String get _label => switch (status) {
    'anchored'  => 'ANCHORED',
    'pending'   => 'PENDING',
    'failed'    => 'FAILED',
    'tampered'  => 'TAMPERED',
    'upload'    => 'UPLOAD',
    'transfer'  => 'TRANSFER',
    _           => status.toUpperCase(),
  };

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: _color.withOpacity(0.10), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color.withOpacity(0.25))),
      child: Text(_label, style: TextStyle(color: _color, fontSize: 9, fontWeight: FontWeight.w800)));
}

class _PanelHdr extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _PanelHdr({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 26, height: 26, decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: color.withOpacity(0.08)),
        child: Icon(icon, size: 13, color: color)),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w700)),
  ]);
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(color: Color(0xFF374151), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.1));
}

class _PremiumField extends StatefulWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final int maxLines;
  const _PremiumField({required this.ctrl, required this.hint, required this.icon, this.maxLines = 1});
  @override State<_PremiumField> createState() => _PremiumFieldState();
}
class _PremiumFieldState extends State<_PremiumField> {
  bool _focused = false;
  late FocusNode _focus;
  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _focus.addListener(() { if (mounted) setState(() => _focused = _focus.hasFocus); });
  }
  @override void dispose() { _focus.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedContainer(duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
          boxShadow: _focused ? [BoxShadow(color: _kPurple.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 3), spreadRadius: -1)] : []),
      child: TextField(controller: widget.ctrl, focusNode: _focus, maxLines: widget.maxLines,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            prefixIcon: widget.maxLines == 1 ? Container(margin: const EdgeInsets.all(10), width: 30, height: 30,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                    color: _focused ? _kPurple.withOpacity(0.08) : const Color(0xFFF3F4F6)),
                child: Icon(widget.icon, size: 15, color: _focused ? _kPurple : const Color(0xFF9CA3AF))) : null,
            filled: true, fillColor: _focused ? const Color(0xFFF5F3FF) : Colors.white.withOpacity(0.75),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: widget.maxLines > 1 ? 12 : 14, horizontal: 14),
            border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorderIdle, width: 1.2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorderIdle, width: 1.2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPurple, width: 2.0)),
          )));
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
                  color: _h ? _kPurple.withOpacity(0.08) : Colors.transparent,
                  border: Border.all(color: _h ? _kPurple.withOpacity(0.2) : Colors.transparent)),
              child: Icon(widget.icon, size: 20, color: _h ? _kPurple : const Color(0xFF475569)))));
}