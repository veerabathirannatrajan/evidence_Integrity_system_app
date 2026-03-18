// custody_timeline_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class CustodyTimelineScreen extends StatefulWidget {
  final String? evidenceId;
  const CustodyTimelineScreen({super.key, required this.evidenceId});
  @override
  State<CustodyTimelineScreen> createState() => _CustodyTimelineScreenState();
}

// TickerProviderStateMixin (plural) — avoids "multiple tickers" assertion
class _CustodyTimelineScreenState extends State<CustodyTimelineScreen>
    with TickerProviderStateMixin {

  final _api = ApiService();

  Map<String, dynamic>?  _evidenceData;
  List<dynamic>          _chain        = [];
  List<dynamic>          _allEvidence  = [];
  String?                _selectedEvidenceId;
  Map<String, dynamic>?  _currentCustodian;

  bool   _loading         = true;
  bool   _evidenceLoading = true;
  bool   _transfering     = false;
  bool   _canTransfer     = false;
  String? _error;
  String? _successMsg;

  final _toUserCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();
  String? _toRole;
  List<Map<String, dynamic>> _allowedRoles = [];

  // ALWAYS length 2 — never recreated after init
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    if (widget.evidenceId != null) _selectedEvidenceId = widget.evidenceId;
    _loadInitial();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _toUserCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

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
            all.add({...Map<String, dynamic>.from(e),
              'caseTitle': c['title'] ?? 'Case'});
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
      final data  = await _api.getAllowedRoles();
      if (mounted) {
        final roles = List<Map<String, dynamic>>.from(data['allowedRoles'] ?? []);
        // Only update state — NEVER dispose/recreate _tabCtrl here
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
      backgroundColor: const Color(0xFF059669),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final role   = context.watch<UserProvider>().role ?? 'police';
    final C      = _CC(isDark);

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(children: [
        _header(C, role),
        _picker(C),
        _tabBar(C),
        Expanded(child: _tabView(C, role)),
      ]),
    );
  }

  // ── Tab Bar — always 2, second grayed out if no permission ───────────────
  Widget _tabBar(_CC C) => Container(
    color: C.card,
    child: TabBar(
      controller: _tabCtrl,
      labelColor: C.accent,
      unselectedLabelColor: C.txtSecond,
      indicatorColor: C.accent,
      indicatorWeight: 2.5,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 13),
      onTap: (i) { if (i == 1 && !_canTransfer) _tabCtrl.animateTo(0); },
      tabs: [
        const Tab(icon: Icon(Icons.timeline_outlined, size: 16),
            text: 'Chain of Custody'),
        Tab(
          icon: Icon(Icons.swap_horiz_rounded, size: 16,
              color: _canTransfer ? null : C.txtMuted),
          child: Text('Transfer Custody',
              style: TextStyle(color: _canTransfer ? null : C.txtMuted)),
        ),
      ],
    ),
  );

  Widget _tabView(_CC C, String role) => TabBarView(
    controller: _tabCtrl,
    physics: _canTransfer
        ? const AlwaysScrollableScrollPhysics()
        : const NeverScrollableScrollPhysics(),
    children: [
      _chainView(C),
      _canTransfer
          ? SingleChildScrollView(child: _transferView(C, role))
          : _noPermView(C, role),
    ],
  );

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _header(_CC C, String role) => Container(
    padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
    decoration: BoxDecoration(
        color: C.card, border: Border(bottom: BorderSide(color: C.border))),
    child: Row(children: [
      GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: C.bg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: C.border)),
              child: Icon(Icons.arrow_back_rounded, size: 18, color: C.txtSecond))),
      const SizedBox(width: 14),
      Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.timeline_outlined, color: Colors.white, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Chain of Custody',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        Text(_canTransfer ? 'View history & transfer evidence' : 'View custody history',
            style: TextStyle(color: C.txtSecond, fontSize: 11)),
      ])),
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: _rc(role).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _rc(role).withOpacity(0.3))),
          child: Text(_rl(role),
              style: TextStyle(color: _rc(role), fontSize: 11,
                  fontWeight: FontWeight.w700))),
    ]),
  );

// ── Evidence Picker ───────────────────────────────────────────────────────
  Widget _picker(_CC C) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    decoration: BoxDecoration(
        color: C.card, border: Border(bottom: BorderSide(color: C.border))),
    child: _evidenceLoading
        ? Row(children: [
      SizedBox(width: 16, height: 16,
          child: CircularProgressIndicator(color: C.accent, strokeWidth: 2)),
      const SizedBox(width: 10),
      Text('Loading evidence...', style: TextStyle(color: C.txtSecond, fontSize: 13)),
    ])
        : _allEvidence.isEmpty
        ? Row(children: [
      Icon(Icons.info_outline, size: 16, color: C.txtMuted),
      const SizedBox(width: 8),
      Text('No evidence found', style: TextStyle(color: C.txtMuted, fontSize: 13)),
    ])
        : DropdownButtonFormField<String>(
      value: _selectedEvidenceId,
      dropdownColor: C.card,
      isExpanded: true,
      style: TextStyle(color: C.txtPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: 'Select Evidence',
        labelStyle: TextStyle(color: C.txtMuted, fontSize: 12),
        prefixIcon: Icon(Icons.insert_drive_file_outlined, size: 16, color: C.txtMuted),
        filled: true, fillColor: C.inputBg, isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: C.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: C.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: C.accent, width: 1.5)),
      ),
      hint: Text('Choose evidence to view custody chain',
          style: TextStyle(color: C.txtMuted, fontSize: 12)),
      items: _allEvidence.map((ev) {
        final id    = ev['_id']?.toString() ?? '';
        final name  = ev['fileName'] as String? ?? 'Unknown';
        final caseT = ev['caseTitle'] as String? ?? '';
        return DropdownMenuItem<String>(
          value: id,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: name,
                  style: TextStyle(
                    color: C.txtPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700, // Bold
                  ),
                ),
                TextSpan(
                  text: '  •  ',
                  style: TextStyle(
                    color: C.txtMuted,
                    fontSize: 11,
                  ),
                ),
                TextSpan(
                  text: caseT,
                  style: TextStyle(
                    color: C.txtMuted,
                    fontSize: 18,
                    fontWeight: FontWeight.w400, // Normal
                  ),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: (val) {
        if (val == null) return;
        setState(() => _selectedEvidenceId = val);
        _loadChain(val);
      },
    ),
  );

  // ── Chain View ────────────────────────────────────────────────────────────
  Widget _chainView(_CC C) {
    if (_selectedEvidenceId == null) return _emptyPicker(C);
    if (_loading) return _spinner(C);
    if (_error != null) return _errView(C);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_evidenceData != null) _evSummary(C, _evidenceData!),
        if (_evidenceData != null) const SizedBox(height: 20),
        if (_currentCustodian != null) _custodianCard(C, _currentCustodian!),
        if (_currentCustodian != null) const SizedBox(height: 20),
        Row(children: [
          Container(width: 4, height: 18, color: const Color(0xFF7C3AED),
              margin: const EdgeInsets.only(right: 10)),
          Text('Custody Timeline', style: TextStyle(color: C.txtPrimary,
              fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(width: 10),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${_chain.length} events',
                  style: const TextStyle(color: Color(0xFF7C3AED),
                      fontSize: 10, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 16),
        if (_chain.isEmpty)
          _emptyChain(C)
        else
          ..._chain.asMap().entries.map((e) =>
              _chainEvent(C, e.value, e.key, _chain.length)),
      ],
    );
  }

  Widget _evSummary(_CC C, Map ev) {
    final tampered = ev['isTampered'] == true;
    final status   = ev['blockchainStatus'] as String? ?? 'pending';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: C.card, borderRadius: BorderRadius.circular(13),
          border: Border.all(
              color: tampered ? const Color(0xFFDC2626).withOpacity(0.4) : C.border,
              width: tampered ? 1.5 : 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(
                  color: tampered
                      ? const Color(0xFFDC2626).withOpacity(0.1)
                      : const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(
                  tampered ? Icons.warning_amber_rounded
                      : Icons.insert_drive_file_outlined,
                  size: 20,
                  color: tampered ? const Color(0xFFDC2626)
                      : const Color(0xFF7C3AED))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ev['fileName'] as String? ?? '—',
                    style: TextStyle(color: C.txtPrimary, fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(children: [
                  _badge(status.toUpperCase(), _cc(status)),
                  if (tampered) ...[
                    const SizedBox(width: 6),
                    _badge('TAMPERED', const Color(0xFFDC2626)),
                  ],
                ]),
              ])),
        ]),
        if (tampered) ...[
          const SizedBox(height: 10),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFDC2626).withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Expanded(child: Text(
                    'Integrity compromised · Tampered at '
                        '${_fd(ev['tamperedAt']?.toString())}',
                    style: const TextStyle(
                        color: Color(0xFFDC2626), fontSize: 11))),
              ])),
        ],
        const SizedBox(height: 10),
        Divider(color: C.border, height: 1),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _iCol(C, 'Evidence ID',
              _sh(ev['id']?.toString() ?? ''),
              copy: true, cv: ev['id']?.toString())),
          Expanded(child: _iCol(C, 'Case ID',
              _sh(ev['caseId']?.toString() ?? ''))),
          Expanded(child: _iCol(C, 'Uploaded',
              _fd(ev['createdAt']?.toString()))),
        ]),
        const SizedBox(height: 8),
        _iCol(C, 'SHA-256 Hash', ev['fileHash'] as String? ?? '—',
            mono: true, copy: true, cv: ev['fileHash'] as String?),
        if ((ev['blockchainTxHash'] as String? ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          _iCol(C, 'TX Hash', _sh(ev['blockchainTxHash'] as String),
              mono: true, copy: true, cv: ev['blockchainTxHash'] as String?),
        ],
      ]),
    );
  }

  Widget _custodianCard(_CC C, Map custodian) {
    final role = custodian['role'] as String? ?? 'police';
    final name = custodian['name'] as String? ?? '—';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft,
              end: Alignment.bottomRight, colors: [
                _rc(role).withOpacity(C.isDark ? 0.15 : 0.08),
                _rc(role).withOpacity(0.04),
              ]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _rc(role).withOpacity(0.3))),
      child: Row(children: [
        Container(width: 44, height: 44,
            decoration: BoxDecoration(
                color: _rc(role).withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(_ri(role), size: 22, color: _rc(role))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Custodian', style: TextStyle(color: C.txtMuted,
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              const SizedBox(height: 3),
              Text(name, style: TextStyle(color: C.txtPrimary,
                  fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(_rl(role), style: TextStyle(color: _rc(role),
                  fontSize: 11, fontWeight: FontWeight.w600)),
            ])),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF059669).withOpacity(0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFF4ADE80), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              const Text('In Custody', style: TextStyle(
                  color: Color(0xFF059669), fontSize: 10,
                  fontWeight: FontWeight.w700)),
            ])),
      ]),
    );
  }

  Widget _chainEvent(_CC C, Map event, int index, int total) {
    final type     = event['type'] as String? ?? 'transfer';
    final isFirst  = index == 0;
    final isLast   = index == total - 1;
    final isUpload = type == 'upload';
    final color = isUpload ? const Color(0xFF2563EB) : const Color(0xFF7C3AED);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Spine — FIXED heights only, never double.infinity
        SizedBox(
          width: 36,
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center, children: [
                if (!isFirst) Container(width: 2, height: 12,
                    color: const Color(0xFF7C3AED).withOpacity(0.3)),
                Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: color.withOpacity(0.3),
                            blurRadius: 8, offset: const Offset(0, 2))]),
                    child: Icon(
                        isUpload ? Icons.cloud_upload_outlined
                            : Icons.swap_horiz_rounded,
                        color: Colors.white, size: 16)),
                if (!isLast) Container(width: 2, height: 40,
                    color: const Color(0xFF7C3AED).withOpacity(0.3)),
              ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: C.card, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.border)),
            child: isUpload ? _upEv(C, event) : _trEv(C, event),
          ),
        ),
      ]),
    );
  }

  Widget _upEv(_CC C, Map ev) {
    final bs = ev['status'] as String? ?? 'pending';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Evidence Uploaded & Registered', style: TextStyle(
                  color: C.txtPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(_fd(ev['timestamp']?.toString()),
                  style: TextStyle(color: C.txtMuted, fontSize: 10)),
            ])),
        _badge('UPLOAD', const Color(0xFF2563EB)),
      ]),
      const SizedBox(height: 10),
      _eRow(C, Icons.person_outline_rounded, 'Uploaded by',
          ev['actor']?.toString() ?? '—'),
      _eRow(C, Icons.link_rounded, 'Blockchain', bs, vc: _cc(bs)),
      if ((ev['txHash'] as String? ?? '').isNotEmpty)
        _eRow(C, Icons.tag_rounded, 'TX Hash', _sh(ev['txHash'] as String),
            mono: true, copy: true, cv: ev['txHash'] as String),
      if ((ev['hash'] as String? ?? '').isNotEmpty)
        _eRow(C, Icons.fingerprint_rounded, 'Hash',
            _sh(ev['hash'] as String, 20),
            mono: true, copy: true, cv: ev['hash'] as String),
    ]);
  }

  Widget _trEv(_CC C, Map ev) {
    final fr = ev['fromRole'] as String? ?? 'police';
    final tr = ev['toRole']   as String? ?? 'police';
    final fn = ev['fromName'] as String? ?? '—';
    final tn = ev['toName']   as String? ?? '—';
    final rs = ev['reason']   as String? ?? '—';
    final nt = ev['notes']    as String? ?? '';
    final ps = ev['position'] as int? ?? 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Custody Transfer #$ps', style: TextStyle(
                  color: C.txtPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(_fd(ev['timestamp']?.toString()),
                  style: TextStyle(color: C.txtMuted, fontSize: 10)),
            ])),
        _badge('TRANSFER', const Color(0xFF7C3AED)),
      ]),
      const SizedBox(height: 12),
      Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: C.inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: C.border)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FROM', style: TextStyle(color: C.txtMuted, fontSize: 9,
                      fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(width: 26, height: 26,
                        decoration: BoxDecoration(
                            color: _rc(fr).withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(_ri(fr), size: 13, color: _rc(fr))),
                    const SizedBox(width: 7),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(fn, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: C.txtPrimary, fontSize: 11,
                              fontWeight: FontWeight.w700)),
                      Text(_rl(fr), style: TextStyle(color: _rc(fr),
                          fontSize: 9, fontWeight: FontWeight.w600)),
                    ])),
                  ]),
                ])),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: Color(0xFF7C3AED)))),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TO', style: TextStyle(color: C.txtMuted, fontSize: 9,
                      fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(tn, overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(color: C.txtPrimary, fontSize: 11,
                              fontWeight: FontWeight.w700)),
                      Text(_rl(tr), style: TextStyle(color: _rc(tr),
                          fontSize: 9, fontWeight: FontWeight.w600)),
                    ])),
                    const SizedBox(width: 7),
                    Container(width: 26, height: 26,
                        decoration: BoxDecoration(
                            color: _rc(tr).withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(_ri(tr), size: 13, color: _rc(tr))),
                  ]),
                ])),
          ])),
      const SizedBox(height: 10),
      _eRow(C, Icons.info_outline_rounded, 'Reason', rs),
      if (nt.isNotEmpty) _eRow(C, Icons.notes_rounded, 'Notes', nt),
      if ((ev['hash'] as String? ?? '').isNotEmpty)
        _eRow(C, Icons.fingerprint_rounded, 'Hash at Transfer',
            _sh(ev['hash'] as String, 20),
            mono: true, copy: true, cv: ev['hash'] as String),
    ]);
  }

  Widget _eRow(_CC C, IconData icon, String label, String value, {
    bool mono = false, bool copy = false, String? cv, Color? vc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 12, color: C.txtMuted),
        const SizedBox(width: 6),
        SizedBox(width: 90,
            child: Text(label, style: TextStyle(color: C.txtMuted, fontSize: 11))),
        Expanded(child: SelectableText(value,
            style: TextStyle(color: vc ?? C.txtPrimary,
                fontSize: 11, fontWeight: FontWeight.w600,
                fontFamily: mono ? 'monospace' : null))),
        if (copy)
          GestureDetector(
              onTap: () => _copy(cv ?? value, label),
              child: Padding(padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.copy_outlined,
                      size: 11, color: C.txtMuted))),
      ]),
    );
  }

  Widget _iCol(_CC C, String label, String value, {
    bool mono = false, bool copy = false, String? cv,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: C.txtMuted, fontSize: 9,
            fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Row(children: [
          Expanded(child: SelectableText(value,
              style: TextStyle(color: C.txtPrimary, fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: mono ? 'monospace' : null))),
          if (copy)
            GestureDetector(
                onTap: () => _copy(cv ?? value, label),
                child: Icon(Icons.copy_outlined,
                    size: 11, color: C.txtMuted)),
        ]),
      ]),
    );
  }

  Widget _emptyChain(_CC C) => Center(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.timeline_outlined, size: 44, color: C.txtMuted),
        const SizedBox(height: 12),
        Text('No transfers yet', style: TextStyle(color: C.txtPrimary,
            fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('This evidence has not been transferred',
            style: TextStyle(color: C.txtMuted, fontSize: 12)),
      ])));

  // ── Transfer View ─────────────────────────────────────────────────────────
  Widget _transferView(_CC C, String role) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _permBanner(C, role),
      const SizedBox(height: 20),
      if (_successMsg != null) ...[_okBanner(C), const SizedBox(height: 14)],
      if (_error != null)      ...[_errBanner(C), const SizedBox(height: 14)],
      if (_selectedEvidenceId == null)
        _remindSelect(C)
      else ...[
        _secHead(C, 'Transfer Details',
            Icons.swap_horiz_rounded, const Color(0xFF7C3AED)),
        const SizedBox(height: 14),
        _lbl(C, 'Recipient UID or Email'),
        const SizedBox(height: 6),
        _fld(C, _toUserCtrl,
            hint: 'Enter Firebase UID or email address',
            icon: Icons.person_outline_rounded),
        const SizedBox(height: 14),
        _lbl(C, 'Recipient Role'),
        const SizedBox(height: 6),
        _roleDd(C),
        const SizedBox(height: 14),
        _lbl(C, 'Reason for Transfer'),
        const SizedBox(height: 6),
        _fld(C, _reasonCtrl,
            hint: 'e.g. Forwarding for forensic analysis',
            icon: Icons.info_outline_rounded, ml: 3),
        const SizedBox(height: 14),
        _lbl(C, 'Additional Notes (Optional)'),
        const SizedBox(height: 6),
        _fld(C, _notesCtrl,
            hint: 'Any additional information...',
            icon: Icons.notes_rounded, ml: 2),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            onPressed: _transfering ? null : _transfer,
            icon: _transfering
                ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
                : const Icon(Icons.swap_horiz_rounded,
                color: Colors.white, size: 20),
            label: Text(_transfering ? 'Transferring...' : 'Transfer Custody',
                style: const TextStyle(color: Colors.white,
                    fontSize: 15, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              disabledBackgroundColor:
              const Color(0xFF7C3AED).withOpacity(0.4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(
            'Transfer will be recorded on the blockchain.\n'
                'Hash at time of transfer will be saved.',
            textAlign: TextAlign.center,
            style: TextStyle(color: C.txtMuted, fontSize: 11, height: 1.5))),
      ],
    ]),
  );

  Widget _noPermView(_CC C, String role) => Center(child: Column(
      mainAxisSize: MainAxisSize.min, children: [
    Icon(_ri(role), size: 48, color: C.txtMuted),
    const SizedBox(height: 16),
    Text('No Transfer Permission', style: TextStyle(color: C.txtPrimary,
        fontSize: 16, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text('${_rl(role)} cannot transfer evidence.',
            textAlign: TextAlign.center,
            style: TextStyle(color: C.txtMuted, fontSize: 13))),
  ]));

  Widget _permBanner(_CC C, String role) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: _rc(role).withOpacity(C.isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _rc(role).withOpacity(0.25))),
    child: Row(children: [
      Icon(_ri(role), size: 18, color: _rc(role)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_rl(role)} — Transfer Permissions',
                style: TextStyle(color: _rc(role), fontSize: 12,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(_allowedRoles.isEmpty
                ? 'You cannot transfer evidence in your role.'
                : 'Can transfer to: ${_allowedRoles.map((r) => r['label']).join(', ')}',
                style: TextStyle(color: C.txtSecond, fontSize: 11, height: 1.4)),
          ])),
    ]),
  );

  Widget _roleDd(_CC C) => DropdownButtonFormField<String>(
    value: _toRole, dropdownColor: C.card, isExpanded: true,
    style: TextStyle(color: C.txtPrimary, fontSize: 13),
    decoration: InputDecoration(
      prefixIcon: Icon(Icons.badge_outlined, size: 16, color: C.txtMuted),
      hintText: 'Select recipient role',
      hintStyle: TextStyle(color: C.txtMuted, fontSize: 12),
      filled: true, fillColor: C.inputBg, isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: C.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: C.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: C.accent, width: 1.5)),
    ),
    items: _allowedRoles.map((r) {
      final val = r['value'] as String;
      return DropdownMenuItem<String>(
        value: val,
        child: Row(children: [
          Icon(_ri(val), size: 15, color: _rc(val)),
          const SizedBox(width: 8),
          Text(r['label'] as String,
              style: TextStyle(color: C.txtPrimary, fontSize: 13)),
        ]),
      );
    }).toList(),
    onChanged: (v) => setState(() => _toRole = v),
  );

  Widget _remindSelect(_CC C) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: C.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF7C3AED).withOpacity(0.25))),
    child: Column(children: [
      Icon(Icons.insert_drive_file_outlined, size: 36, color: C.txtMuted),
      const SizedBox(height: 10),
      Text('Select an Evidence Item', style: TextStyle(color: C.txtPrimary,
          fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('Use the dropdown above to select evidence',
          style: TextStyle(color: C.txtMuted, fontSize: 12)),
    ]),
  );

  Widget _secHead(_CC C, String t, IconData icon, Color color) => Row(children: [
    Container(width: 4, height: 16,
        decoration: BoxDecoration(color: color,
            borderRadius: BorderRadius.circular(2)),
        margin: const EdgeInsets.only(right: 8)),
    Icon(icon, size: 15, color: color),
    const SizedBox(width: 7),
    Text(t, style: TextStyle(color: C.txtPrimary, fontSize: 14,
        fontWeight: FontWeight.w800)),
  ]);

  Widget _lbl(_CC C, String t) => Text(t, style: TextStyle(
      color: C.txtSecond, fontSize: 12, fontWeight: FontWeight.w600));

  Widget _fld(_CC C, TextEditingController ctrl, {
    required String hint, required IconData icon, int ml = 1,
  }) => TextField(
    controller: ctrl, maxLines: ml,
    style: TextStyle(color: C.txtPrimary, fontSize: 13),
    decoration: InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: C.txtMuted, fontSize: 12),
      prefixIcon: ml == 1 ? Icon(icon, size: 16, color: C.txtMuted) : null,
      filled: true, fillColor: C.inputBg, isDense: true,
      contentPadding: EdgeInsets.symmetric(
          vertical: ml > 1 ? 12 : 11, horizontal: ml > 1 ? 14 : 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: C.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: C.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: C.accent, width: 1.5)),
    ),
  );

  Widget _okBanner(_CC C) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF059669).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF059669).withOpacity(0.3))),
      child: Row(children: [
        const Icon(Icons.check_circle_outline_rounded,
            color: Color(0xFF059669), size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(_successMsg!,
            style: const TextStyle(color: Color(0xFF059669),
                fontSize: 12, fontWeight: FontWeight.w600))),
        GestureDetector(onTap: () => setState(() => _successMsg = null),
            child: const Icon(Icons.close_rounded,
                size: 14, color: Color(0xFF059669))),
      ]));

  Widget _errBanner(_CC C) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.3))),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: Color(0xFFDC2626), size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(_error!,
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12))),
        GestureDetector(onTap: () => setState(() => _error = null),
            child: const Icon(Icons.close_rounded,
                size: 14, color: Color(0xFFDC2626))),
      ]));

  Widget _emptyPicker(_CC C) => Center(child: Column(
      mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.insert_drive_file_outlined, size: 44, color: C.txtMuted),
    const SizedBox(height: 14),
    Text('Select Evidence', style: TextStyle(color: C.txtPrimary,
        fontSize: 16, fontWeight: FontWeight.w700)),
    const SizedBox(height: 4),
    Text('Choose an evidence item from the dropdown above',
        style: TextStyle(color: C.txtMuted, fontSize: 12)),
  ]));

  Widget _spinner(_CC C) => Center(child: Column(
      mainAxisSize: MainAxisSize.min, children: [
    CircularProgressIndicator(color: C.accent, strokeWidth: 2.5),
    const SizedBox(height: 12),
    Text('Loading chain of custody...',
        style: TextStyle(color: C.txtSecond, fontSize: 13)),
  ]));

  Widget _errView(_CC C) => Center(child: Column(
      mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.error_outline_rounded, size: 36, color: C.txtMuted),
    const SizedBox(height: 8),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(_error!, textAlign: TextAlign.center,
            style: TextStyle(color: C.txtSecond, fontSize: 13))),
    const SizedBox(height: 10),
    ElevatedButton(
        onPressed: () => _loadChain(_selectedEvidenceId!),
        style: ElevatedButton.styleFrom(
            backgroundColor: C.accent, elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8))),
        child: const Text('Retry',
            style: TextStyle(color: Colors.white))),
  ]));

  Widget _badge(String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color,
          fontSize: 9, fontWeight: FontWeight.w800)));

  Color _rc(String r) => switch (r) {
    'police'     => const Color(0xFF2563EB),
    'forensic'   => const Color(0xFF7C3AED),
    'prosecutor' => const Color(0xFF059669),
    'defense'    => const Color(0xFF0284C7),
    'court'      => const Color(0xFFD97706),
    _            => const Color(0xFF2563EB),
  };

  IconData _ri(String r) => switch (r) {
    'police'     => Icons.local_police_outlined,
    'forensic'   => Icons.biotech_outlined,
    'prosecutor' => Icons.gavel_outlined,
    'defense'    => Icons.balance_outlined,
    'court'      => Icons.account_balance_outlined,
    _            => Icons.person_outline,
  };

  String _rl(String r) => switch (r) {
    'police'     => 'Police Officer',
    'forensic'   => 'Forensic Expert',
    'prosecutor' => 'Prosecutor',
    'defense'    => 'Defense Attorney',
    'court'      => 'Court Official',
    _            => r,
  };

  Color _cc(String s) => switch (s) {
    'anchored' => const Color(0xFF059669),
    'pending'  => const Color(0xFFD97706),
    'failed'   => const Color(0xFFDC2626),
    _          => const Color(0xFF94A3B8),
  };

  String _fd(String? raw) {
    if (raw == null) return '—';
    final t = DateTime.tryParse(raw);
    if (t == null) return raw;
    final l = t.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/'
        '${l.month.toString().padLeft(2, '0')}/'
        '${l.year}  '
        '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }

  String _sh(String s, [int n = 12]) =>
      s.length > n * 2 + 3
          ? '${s.substring(0, n)}...${s.substring(s.length - 8)}'
          : s;
}

class _CC {
  final bool isDark;
  _CC(this.isDark);
  Color get bg         => isDark ? const Color(0xFF0B0F1A) : const Color(0xFFF0F4FF);
  Color get card       => isDark ? const Color(0xFF111827) : Colors.white;
  Color get inputBg    => isDark ? const Color(0xFF1A2540) : const Color(0xFFF8FAFF);
  Color get border     => isDark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0);
  Color get txtPrimary => isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  Color get txtSecond  => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get txtMuted   => isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);
  Color get accent     => const Color(0xFF7C3AED);
}