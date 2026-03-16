// evidence_list_screen.dart
// Image preview approach:
//   Web:    HtmlElementView with <img> tag (bypasses CORS completely)
//   Native: Image.network() with Firebase Storage SDK URL
// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'verify_evidence_screen.dart';
import 'blockchain_viewer_screen.dart';

class EvidenceListScreen extends StatefulWidget {
  final String? filterByCaseId;
  const EvidenceListScreen({super.key, required this.filterByCaseId});

  @override
  State<EvidenceListScreen> createState() => _EvidenceListScreenState();
}

class _EvidenceListScreenState extends State<EvidenceListScreen>
    with TickerProviderStateMixin {

  final _api = ApiService();
  final _searchCtrl = TextEditingController();

  List<dynamic>                  _cases       = [];
  Map<String, List<dynamic>>     _evidenceMap = {};
  Set<String>                    _expanded    = {};
  bool                           _loading     = true;
  String?                        _error;
  String                         _search      = '';
  String                         _filter      = 'all';
  Map<String, dynamic>?          _selected;

  // Cache for Firebase Storage download URLs
  final Map<String, String>      _urlCache    = {};
  // Cache for image bytes
  // URL cache for images (getDownloadURL results)
  final Map<String, String>      _imgCache    = {};

  late AnimationController _entryCtrl;
  late Animation<double>   _entryOpacity;
  late Animation<Offset>   _entrySlide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _entryOpacity = _entryCtrl.drive(
        Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: const Interval(0, 0.6))));
    _entrySlide = _entryCtrl.drive(
        Tween(begin: const Offset(0, 0.025), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)));
    _entryCtrl.forward();
    _loadData();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (widget.filterByCaseId != null) {
        final caseData = await _api.getCaseById(widget.filterByCaseId!);
        final ev = await _api.getEvidenceByCase(widget.filterByCaseId!);
        if (mounted) setState(() {
          _cases       = [caseData];
          _evidenceMap = {widget.filterByCaseId!: List.from(ev)};
          _expanded    = {widget.filterByCaseId!};
          _loading     = false;
          if (ev.isNotEmpty) {
            _selectEvidence(Map<String, dynamic>.from(ev.first));
          }
        });
      } else {
        final cases = await _api.getCasesWithEvidence();
        if (mounted) setState(() {
          _cases   = cases;
          _loading = false;
          if (cases.isNotEmpty) {
            final firstId = cases.first['_id'].toString();
            _expanded = {firstId};
            _loadCaseEvidence(firstId);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _error   = 'Failed to load: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadCaseEvidence(String caseId) async {
    if (_evidenceMap.containsKey(caseId)) return;
    try {
      final ev = await _api.getEvidenceByCase(caseId);
      if (mounted) setState(() {
        _evidenceMap[caseId] = List.from(ev);
      });
    } catch (_) {}
  }

  void _toggle(String caseId) {
    setState(() {
      if (_expanded.contains(caseId)) {
        _expanded.remove(caseId);
      } else {
        _expanded.add(caseId);
        _loadCaseEvidence(caseId);
      }
    });
  }

  List<dynamic> _filteredEv(String caseId) {
    return (_evidenceMap[caseId] ?? []).where((e) {
      final s = (e['blockchainStatus'] as String?) ?? '';
      final t = e['isTampered'] == true;
      if (_filter == 'anchored' && s != 'anchored') return false;
      if (_filter == 'tampered' && !t)              return false;
      if (_filter == 'pending'  && s != 'pending')  return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        if (!(e['fileName'] ?? '').toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
  }

  void _selectEvidence(Map<String, dynamic> ev) {
    setState(() => _selected = ev);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: color,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8))));
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _snack('$label copied', const Color(0xFF059669));
  }

  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final C      = EVC(isDark);

    return Scaffold(
      backgroundColor: C.bg,
      body: FadeTransition(
        opacity: _entryOpacity,
        child: SlideTransition(
          position: _entrySlide,
          child: Row(children: [

            // ── LEFT: Case + Evidence list ──────────────
            Container(
              width: 360,
              decoration: BoxDecoration(
                  color: C.card,
                  border: Border(
                      right: BorderSide(color: C.border))),
              child: Column(children: [
                _leftHeader(C),
                _searchAndFilter(C),
                Expanded(child: _caseListView(C)),
              ]),
            ),

            // ── RIGHT: Preview + Metadata ───────────────
            Expanded(
              child: _selected == null
                  ? _emptyDetailState(C)
                  : _rightPanel(C, _selected!),
            ),
          ]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // LEFT PANEL
  // ════════════════════════════════════════════════════════

  Widget _leftHeader(EVC C) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: C.border))),
      child: Row(children: [
        GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: C.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: C.border)),
                child: Icon(Icons.arrow_back_rounded,
                    size: 16, color: C.txtSecond))),
        const SizedBox(width: 12),
        Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.folder_outlined,
                color: Colors.white, size: 16)),
        const SizedBox(width: 10),
        Expanded(child: Text(
            widget.filterByCaseId != null
                ? 'Case Evidence' : 'Evidence by Case',
            style: TextStyle(color: C.txtPrimary,
                fontSize: 14, fontWeight: FontWeight.w800))),
        GestureDetector(
            onTap: () { _urlCache.clear(); _imgCache.clear();
            _evidenceMap.clear(); _loadData(); },
            child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                    color: C.bg,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: C.border)),
                child: Icon(Icons.refresh_rounded,
                    size: 15, color: C.txtSecond))),
      ]),
    );
  }

  Widget _searchAndFilter(EVC C) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: C.border))),
      child: Column(children: [
        Container(
          decoration: BoxDecoration(
              color: C.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: C.border)),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            style: TextStyle(color: C.txtPrimary, fontSize: 13),
            decoration: InputDecoration(
                hintText: 'Search files...',
                hintStyle: TextStyle(color: C.txtMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 16, color: C.txtMuted),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 14, color: C.txtMuted),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _search = '');
                    })
                    : null,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 11, horizontal: 14)),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final f in ['all','anchored','tampered','pending'])
              Padding(padding: const EdgeInsets.only(right: 6),
                  child: _filterChip(C, f)),
          ]),
        ),
      ]),
    );
  }

  Widget _filterChip(EVC C, String f) {
    final active = _filter == f;
    final color  = _filterColor(f);
    return GestureDetector(
        onTap: () => setState(() => _filter = f),
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
                color: active ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? color : C.border)),
            child: Text(
                f[0].toUpperCase() + f.substring(1),
                style: TextStyle(
                    color: active ? Colors.white : C.txtSecond,
                    fontSize: 11,
                    fontWeight: active
                        ? FontWeight.w700 : FontWeight.w400))));
  }

  Widget _caseListView(EVC C) {
    if (_loading) {
      return Center(child: Column(
          mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(
                color: C.accent, strokeWidth: 2.5)),
        const SizedBox(height: 12),
        Text('Loading cases...',
            style: TextStyle(color: C.txtSecond, fontSize: 12)),
      ]));
    }
    if (_error != null) {
      return Center(child: Column(
          mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded,
            size: 30, color: C.txtMuted),
        const SizedBox(height: 8),
        Text(_error!,
            style: TextStyle(color: C.txtSecond, fontSize: 12)),
        const SizedBox(height: 10),
        TextButton(onPressed: _loadData,
            child: Text('Retry',
                style: TextStyle(color: C.accent))),
      ]));
    }
    if (_cases.isEmpty) {
      return Center(child: Column(
          mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.folder_off_outlined,
            size: 36, color: C.txtMuted),
        const SizedBox(height: 10),
        Text('No cases found',
            style: TextStyle(color: C.txtPrimary,
                fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text('Create a case first',
            style: TextStyle(color: C.txtMuted, fontSize: 12)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _cases.length,
      itemBuilder: (_, i) => _caseBlock(C, _cases[i]),
    );
  }

  Widget _caseBlock(EVC C, Map c) {
    final caseId   = c['_id'].toString();
    final expanded = _expanded.contains(caseId);
    final stats    = c['evidenceStats'] as Map? ?? {};
    final total    = stats['total']    as int? ?? 0;
    final tampered = stats['tampered'] as int? ?? 0;
    final anchored = stats['anchored'] as int? ?? 0;
    final hasBad   = tampered > 0;
    final title    = c['title']   as String? ?? 'Untitled';
    final ref      = c['caseRef'] as String? ?? '';
    final status   = c['status']  as String? ?? 'open';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Case header
        GestureDetector(
          onTap: () => _toggle(caseId),
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 4, 10, 0),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
                color: hasBad
                    ? const Color(0xFFDC2626).withOpacity(0.05)
                    : expanded
                    ? C.accent.withOpacity(0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                    color: hasBad
                        ? const Color(0xFFDC2626).withOpacity(0.3)
                        : expanded
                        ? C.accent.withOpacity(0.3)
                        : Colors.transparent)),
            child: Row(children: [
              Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: hasBad
                              ? [const Color(0xFFDC2626).withOpacity(0.2),
                            const Color(0xFFDC2626).withOpacity(0.1)]
                              : [C.accent.withOpacity(0.2),
                            C.accent.withOpacity(0.08)]),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(
                      hasBad
                          ? Icons.warning_amber_rounded
                          : Icons.folder_outlined,
                      size: 19,
                      color: hasBad
                          ? const Color(0xFFDC2626) : C.accent)),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: C.txtPrimary,
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Row(children: [
                    _statusDot(C, status),
                    if (ref.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(ref, style: TextStyle(
                          color: C.accent, fontSize: 9,
                          fontFamily: 'monospace')),
                    ],
                  ]),
                ],
              )),
              const SizedBox(width: 6),
              Column(crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$total files',
                        style: TextStyle(color: C.txtMuted,
                            fontSize: 9)),
                    const SizedBox(height: 2),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      if (anchored > 0)
                        _miniTag('$anchored ✓',
                            const Color(0xFF059669)),
                      if (hasBad) ...[
                        const SizedBox(width: 4),
                        _miniTag('$tampered ⚠',
                            const Color(0xFFDC2626)),
                      ],
                    ]),
                  ]),
              const SizedBox(width: 4),
              AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(Icons.expand_more_rounded,
                      size: 18, color: C.txtMuted)),
            ]),
          ),
        ),

        // Evidence tiles
        if (expanded)
          _evTilesForCase(C, caseId),

        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: C.border, height: 8)),
      ],
    );
  }

  Widget _evTilesForCase(EVC C, String caseId) {
    final all      = _evidenceMap[caseId];
    final evidence = _filteredEv(caseId);

    if (all == null) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(
                        color: C.accent, strokeWidth: 2)),
                const SizedBox(width: 8),
                Text('Loading...',
                    style: TextStyle(color: C.txtSecond, fontSize: 12)),
              ]));
    }

    if (evidence.isEmpty) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(child: Text(
              all.isEmpty
                  ? 'No evidence uploaded yet'
                  : 'No results',
              style: TextStyle(color: C.txtMuted, fontSize: 12))));
    }

    return Padding(
        padding: const EdgeInsets.only(left: 20, right: 10),
        child: Column(children: List.generate(evidence.length,
                (i) => _evTile(C, evidence[i]))));
  }

  Widget _evTile(EVC C, Map ev) {
    final id       = ev['_id']?.toString() ?? '';
    final name     = ev['fileName'] as String? ?? 'Unknown';
    final mime     = ev['fileType'] as String? ?? '';
    final status   = ev['blockchainStatus'] as String? ?? 'pending';
    final tampered = ev['isTampered'] == true;
    final path     = ev['storagePath'] as String? ?? '';
    final isActive = _selected?['_id'] == id;

    return GestureDetector(
      onTap: () => _selectEvidence(Map<String, dynamic>.from(ev)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
            color: isActive
                ? C.accent.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
                color: isActive
                    ? C.accent.withOpacity(0.35)
                    : Colors.transparent,
                width: 1.5)),
        child: Row(children: [
          // Thumbnail using downloadURL from MongoDB (no CORS issues)
          _StorageThumbnail(
              storagePath: path,
              downloadURL: ev['downloadURL'] as String? ?? '',
              mime: mime,
              tampered: tampered, C: C,
              evidenceId: id,
              bucket: 'evidence-system-6f225.firebasestorage.app',
              urlCache: _urlCache),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                      color: isActive ? C.accent : C.txtPrimary,
                      fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Row(children: [
                _statusDot2(tampered ? 'tampered' : status),
                const SizedBox(width: 5),
                Text(_fmtSize(ev['fileSize']),
                    style: TextStyle(color: C.txtMuted,
                        fontSize: 9)),
              ]),
            ],
          )),
          if (isActive)
            Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                    color: C.accent,
                    borderRadius: BorderRadius.circular(2))),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // RIGHT PANEL
  // ════════════════════════════════════════════════════════
  Widget _rightPanel(EVC C, Map<String, dynamic> ev) {
    final id        = ev['_id']?.toString() ?? '';
    final name      = ev['fileName'] as String? ?? '';
    final mime      = ev['fileType'] as String? ?? '';
    final storagePath = ev['storagePath'] as String? ?? '';
    final status    = ev['blockchainStatus'] as String? ?? 'pending';
    final tampered  = ev['isTampered'] == true;
    final fileHash  = ev['fileHash'] as String? ?? '';
    final txHash    = ev['blockchainTxHash'] as String?;
    final caseId    = ev['caseId']?.toString() ?? '';
    final desc      = ev['description'] as String? ?? '';

    return Column(children: [

      // ── Top bar ────────────────────────────────────────
      Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            color: C.card,
            border: Border(bottom: BorderSide(color: C.border))),
        child: Row(children: [
          // File type badge
          _mimeTag(C, mime),
          const SizedBox(width: 12),
          Expanded(child: Text(name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: C.txtPrimary,
                  fontSize: 14, fontWeight: FontWeight.w800))),
          // Action buttons
          _iconAction(C, Icons.verified_outlined,
              const Color(0xFF059669), 'Verify integrity',
                  () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                      VerifyEvidenceScreen(evidenceId: id)))
                  .then((_) {
                _evidenceMap.clear();
                _urlCache.remove(id);  // clear URL cache for this evidence
                _loadData();
              })),
          if (status == 'anchored' && txHash != null) ...[
            const SizedBox(width: 6),
            _iconAction(C, Icons.link_rounded,
                const Color(0xFF7C3AED), 'View on blockchain',
                    () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) =>
                        BlockchainViewerScreen(
                            evidenceId: id, txHash: txHash)))),
          ],
          const SizedBox(width: 6),
          GestureDetector(
              onTap: () => setState(() => _selected = null),
              child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                      color: C.bg,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: C.border)),
                  child: Icon(Icons.close_rounded,
                      size: 14, color: C.txtSecond))),
        ]),
      ),

      // ── Content ────────────────────────────────────────
      Expanded(child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Preview area (wider)
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Tamper warning
                  if (tampered) ...[
                    _tamperBanner(C, id),
                    const SizedBox(height: 16),
                  ],

                  // File preview
                  _PreviewWidget(
                    storagePath: storagePath,
                    downloadURL: ev['downloadURL'] as String? ?? '',
                    mime: mime,
                    fileName: name,
                    evidenceId: id,
                    bucket: 'evidence-system-6f225.firebasestorage.app',
                    imgCache: _imgCache,
                    onImgLoaded: (_) {},
                    C: C,
                  ),
                ],
              ),
            ),
          ),

          // Divider
          VerticalDivider(color: C.border, width: 1),

          // Metadata sidebar (narrower)
          SizedBox(
            width: 280,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Status
                  _sideSection(C, 'Status'),
                  const SizedBox(height: 8),
                  Row(children: [
                    _bigBadge(
                        tampered ? 'TAMPERED' : status.toUpperCase(),
                        tampered
                            ? const Color(0xFFDC2626)
                            : _chainColor(status)),
                  ]),
                  const SizedBox(height: 14),

                  // Details
                  _sideSection(C, 'Evidence Details'),
                  const SizedBox(height: 8),
                  _metaItem(C, 'ID', id, mono: true, copy: true),
                  _metaItem(C, 'File', name),
                  _metaItem(C, 'Type', mime.isNotEmpty ? mime : '—'),
                  _metaItem(C, 'Size', _fmtSize(ev['fileSize'])),
                  _metaItem(C, 'Uploaded',
                      _fmtDate(ev['createdAt']?.toString())),
                  _metaItem(C, 'Case ID', caseId,
                      mono: true, copy: true),
                  if (desc.isNotEmpty)
                    _metaItem(C, 'Note', desc),
                  const SizedBox(height: 14),

                  // Hash
                  _sideSection(C, 'SHA-256 Hash'),
                  const SizedBox(height: 8),
                  _hashBlock(C, fileHash),
                  const SizedBox(height: 14),

                  // Blockchain
                  _sideSection(C, 'Blockchain'),
                  const SizedBox(height: 8),
                  _metaItem(C, 'Network', 'Polygon Amoy'),
                  _metaItem(C, 'Status',
                      status[0].toUpperCase() + status.substring(1),
                      valueColor: _chainColor(status)),
                  if (txHash != null)
                    _metaItem(C, 'TX Hash', txHash,
                        mono: true, copy: true),
                  if (ev['anchoredAt'] != null)
                    _metaItem(C, 'Anchored',
                        _fmtDate(ev['anchoredAt']?.toString())),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      )),
    ]);
  }

  // ── Empty right state ─────────────────────────────────
  Widget _emptyDetailState(EVC C) {
    return Container(
      color: C.bg,
      child: Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [C.accent.withOpacity(0.15),
                        C.accent.withOpacity(0.05)]),
                  shape: BoxShape.circle),
              child: Icon(Icons.touch_app_outlined,
                  size: 36, color: C.accent)),
          const SizedBox(height: 18),
          Text('Select an evidence file',
              style: TextStyle(color: C.txtPrimary,
                  fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Click any file from the list to preview',
              style: TextStyle(color: C.txtSecond, fontSize: 13)),
        ],
      )),
    );
  }

  Widget _tamperBanner(EVC C, String id) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFDC2626).withOpacity(0.4),
              width: 1.5)),
      child: Row(children: [
        Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded,
                size: 20, color: Color(0xFFDC2626))),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Integrity Compromised',
                style: TextStyle(color: Color(0xFFDC2626),
                    fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(
                'This file has been tampered. '
                    'Hash no longer matches blockchain record.',
                style: TextStyle(
                    color: const Color(0xFFDC2626).withOpacity(0.75),
                    fontSize: 11, height: 1.4)),
          ],
        )),
        const SizedBox(width: 10),
        GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) =>
                    VerifyEvidenceScreen(evidenceId: id))),
            child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('Re-verify',
                    style: TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w700)))),
      ]),
    );
  }

  // ── Sidebar helpers ───────────────────────────────────
  Widget _sideSection(EVC C, String title) {
    return Row(children: [
      Container(width: 3, height: 12,
          color: C.accent,
          margin: const EdgeInsets.only(right: 8)),
      Text(title, style: TextStyle(color: C.txtPrimary,
          fontSize: 11, fontWeight: FontWeight.w800,
          letterSpacing: 0.5)),
    ]);
  }

  Widget _metaItem(EVC C, String label, String value, {
    bool mono = false, bool copy = false, Color? valueColor,
  }) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: C.txtMuted, fontSize: 9,
                      fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Row(children: [
                Expanded(child: SelectableText(value,
                    style: TextStyle(
                        color: valueColor ?? C.txtPrimary,
                        fontSize: 11, fontWeight: FontWeight.w600,
                        fontFamily: mono ? 'monospace' : null))),
                if (copy)
                  GestureDetector(
                      onTap: () => _copy(value, label),
                      child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.copy_outlined,
                              size: 11, color: C.txtMuted))),
              ]),
            ]));
  }

  Widget _hashBlock(EVC C, String hash) {
    return GestureDetector(
        onTap: () => _copy(hash, 'Hash'),
        child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF059669).withOpacity(0.25))),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: SelectableText(hash,
                      style: const TextStyle(
                          color: Color(0xFF059669), fontSize: 9,
                          fontFamily: 'monospace', height: 1.6))),
                  const Icon(Icons.copy_outlined,
                      size: 11, color: Color(0xFF059669)),
                ])));
  }

  Widget _mimeTag(EVC C, String mime) {
    final d = _mimeData(mime);
    return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
            color: d.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: d.color.withOpacity(0.25))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(d.icon, size: 13, color: d.color),
          const SizedBox(width: 5),
          Text(d.label, style: TextStyle(color: d.color,
              fontSize: 10, fontWeight: FontWeight.w800)),
        ]));
  }

  Widget _bigBadge(String text, Color color) {
    return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Text(text, style: TextStyle(color: color,
            fontSize: 11, fontWeight: FontWeight.w800)));
  }

  Widget _iconAction(EVC C, IconData icon, Color color,
      String tip, VoidCallback onTap) {
    return Tooltip(message: tip,
        child: GestureDetector(onTap: onTap,
            child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.3))),
                child: Icon(icon, size: 15, color: color))));
  }

  Widget _statusDot(EVC C, String status) {
    final color = switch (status) {
      'open'         => const Color(0xFF059669),
      'under_review' => const Color(0xFFD97706),
      'closed'       => const Color(0xFF94A3B8),
      _              => const Color(0xFF2563EB),
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6,
          decoration: BoxDecoration(
              color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(status.replaceAll('_', ' '),
          style: TextStyle(color: color, fontSize: 9,
              fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _statusDot2(String status) {
    final map = {
      'anchored': const Color(0xFF059669),
      'pending':  const Color(0xFFD97706),
      'failed':   const Color(0xFFDC2626),
      'tampered': const Color(0xFFDC2626),
    };
    final color = map[status] ?? const Color(0xFF94A3B8);
    return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20)),
        child: Text(status.toUpperCase(),
            style: TextStyle(color: color, fontSize: 8,
                fontWeight: FontWeight.w800)));
  }

  Widget _miniTag(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: color,
          fontSize: 9, fontWeight: FontWeight.w700)));

  // Helpers
  Color _filterColor(String f) => switch (f) {
    'anchored' => const Color(0xFF059669),
    'tampered' => const Color(0xFFDC2626),
    'pending'  => const Color(0xFFD97706),
    _          => const Color(0xFF2563EB),
  };

  Color _chainColor(String s) => switch (s) {
    'anchored' => const Color(0xFF059669),
    'pending'  => const Color(0xFFD97706),
    'failed'   => const Color(0xFFDC2626),
    _          => const Color(0xFF94A3B8),
  };

  _MimeData _mimeData(String mime) {
    if (mime.startsWith('image/'))
      return _MimeData(Icons.image_outlined,
          const Color(0xFF2563EB), 'IMAGE');
    if (mime.startsWith('video/'))
      return _MimeData(Icons.videocam_outlined,
          const Color(0xFF7C3AED), 'VIDEO');
    if (mime.startsWith('audio/'))
      return _MimeData(Icons.music_note_outlined,
          const Color(0xFF059669), 'AUDIO');
    if (mime == 'application/pdf')
      return _MimeData(Icons.picture_as_pdf_outlined,
          const Color(0xFFDC2626), 'PDF');
    if (mime.contains('word') || mime.contains('document'))
      return _MimeData(Icons.description_outlined,
          const Color(0xFF0284C7), 'DOC');
    if (mime.contains('spreadsheet') || mime.contains('excel'))
      return _MimeData(Icons.table_chart_outlined,
          const Color(0xFF059669), 'XLS');
    return _MimeData(Icons.insert_drive_file_outlined,
        const Color(0xFF64748B), 'FILE');
  }

  String _fmtSize(dynamic b) {
    if (b == null) return '—';
    final n = b is int ? b : int.tryParse('$b') ?? 0;
    if (n < 1024)    return '$n B';
    if (n < 1048576) return '${(n/1024).toStringAsFixed(1)} KB';
    return '${(n/1048576).toStringAsFixed(1)} MB';
  }

  String _fmtDate(String? raw) {
    if (raw == null) return '—';
    final t = DateTime.tryParse(raw);
    if (t == null) return raw;
    final l = t.toLocal();
    return '${l.day.toString().padLeft(2,'0')}/'
        '${l.month.toString().padLeft(2,'0')}/'
        '${l.year}  '
        '${l.hour.toString().padLeft(2,'0')}:'
        '${l.minute.toString().padLeft(2,'0')}';
  }
}

// ════════════════════════════════════════════════════════════
// STORAGE THUMBNAIL — 40×40 image using getDownloadURL()
// Works on Web, Windows, Android, iOS
// getData() is NOT supported on Flutter Web/Windows
// ════════════════════════════════════════════════════════════
class _StorageThumbnail extends StatefulWidget {
  final String storagePath;
  final String downloadURL;
  final String mime;
  final bool tampered;
  final EVC C;
  final String evidenceId;
  final String bucket;
  final Map<String, String> urlCache;

  const _StorageThumbnail({
    required this.storagePath,
    required this.downloadURL,
    required this.mime,
    required this.tampered, required this.C,
    required this.evidenceId,
    required this.bucket,
    required this.urlCache,
  });

  @override
  State<_StorageThumbnail> createState() =>
      _StorageThumbnailState();
}

class _StorageThumbnailState extends State<_StorageThumbnail> {
  String? _url;
  bool _loading = false;
  bool _error   = false;

  @override
  void initState() {
    super.initState();
    if (widget.urlCache.containsKey(widget.evidenceId)) {
      // Use cached token URL
      _url = widget.urlCache[widget.evidenceId];
    } else if (widget.mime.startsWith('image/') &&
        widget.storagePath.isNotEmpty) {
      // Get token URL from SDK
      _loadUrl();
    }
  }

  Future<void> _loadUrl() async {
    if (_loading) return;
    if (mounted) setState(() => _loading = true);

    // Use universal getter — REST API on web, SDK on native
    final url = await getStorageDownloadUrl(
        widget.storagePath, widget.bucket);

    if (url.isNotEmpty && mounted) {
      widget.urlCache[widget.evidenceId] = url;
      setState(() { _url = url; _loading = false; });
    } else if (mounted) {
      setState(() { _loading = false; _error = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = widget.C;

    if (widget.tampered) {
      return Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFFDC2626).withOpacity(0.3))),
          child: const Icon(Icons.warning_amber_rounded,
              size: 20, color: Color(0xFFDC2626)));
    }

    if (widget.mime.startsWith('image/')) {
      if (_loading) {
        return Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.circular(8)),
            child: const Center(child: SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(
                    color: Color(0xFF2563EB), strokeWidth: 2))));
      }
      if (_url != null && !_error) {
        return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _url!,
              width: 42, height: 42, fit: BoxFit.cover,
              // Proxy URL is same-origin — no CORS issue
              errorBuilder: (ctx, err, stack) {
                debugPrint('Thumbnail net error: $err');
                return _iconBox(C, widget.mime);
              },
            ));
      }
    }
    return _iconBox(C, widget.mime);
  }

  Widget _iconBox(EVC C, String mime) {
    final d = _MimeData.from(mime);
    return Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
            color: d.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(d.icon, size: 20, color: d.color));
  }
}

// ════════════════════════════════════════════════════════════
// PREVIEW WIDGET — full preview using Firebase Storage
// ════════════════════════════════════════════════════════════
class _PreviewWidget extends StatefulWidget {
  final String storagePath;
  final String downloadURL;
  final String mime;
  final String fileName;
  final String evidenceId;
  final String bucket;
  final Map<String, String> imgCache;
  final void Function(String?) onImgLoaded;
  final EVC C;

  const _PreviewWidget({
    required this.storagePath,
    required this.downloadURL,
    required this.mime,
    required this.fileName,
    required this.evidenceId,
    required this.bucket,
    required this.imgCache,
    required this.onImgLoaded,
    required this.C,
  });

  @override
  State<_PreviewWidget> createState() => _PreviewWidgetState();
}

class _PreviewWidgetState extends State<_PreviewWidget> {

  // Image URL (getDownloadURL - works on Web/Windows/Mobile)
  String? _imgUrl;
  bool _imgLoading = false;
  bool _imgError   = false;
  // Fallback: use downloadURL from MongoDB if Firebase Storage SDK fails

  // Video
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  bool _videoErr   = false;
  String? _videoUrl;

  @override
  void initState() {
    super.initState();
    _initPreview();
  }

  @override
  void didUpdateWidget(_PreviewWidget old) {
    super.didUpdateWidget(old);
    if (old.storagePath != widget.storagePath) {
      _disposeVideo();
      setState(() {
        _imgUrl      = null;
        _imgLoading  = false;
        _imgError    = false;
        _videoReady  = false;
        _videoErr    = false;
        _videoUrl    = null;
      });
      _initPreview();
    }
  }

  void _initPreview() {
    if (widget.mime.startsWith('image/')) {
      _loadImage();
    } else if (widget.mime.startsWith('video/')) {
      _loadVideoUrl();
    }
  }

  Future<void> _loadImage() async {
    // Check cache first
    if (widget.imgCache.containsKey(widget.evidenceId)) {
      final cached = widget.imgCache[widget.evidenceId];
      if ((cached?.isNotEmpty ?? false) && mounted) {
        setState(() { _imgUrl = cached; _imgLoading = false; });
        return;
      }
    }
    if (_imgLoading) return;
    if (mounted) setState(() => _imgLoading = true);

    // Use universal getter — REST API on web, SDK on native
    final url = await getStorageDownloadUrl(
        widget.storagePath, widget.bucket);

    if (url.isNotEmpty && mounted) {
      debugPrint('✅ Image URL: $url');
      widget.imgCache[widget.evidenceId] = url;
      setState(() { _imgUrl = url; _imgLoading = false; });
    } else if (mounted) {
      debugPrint('🔴 Failed to get image URL for ${widget.storagePath}');
      setState(() { _imgLoading = false; _imgError = true; });
    }
  }

  Future<void> _loadVideoUrl() async {
    final url = await getStorageDownloadUrl(
        widget.storagePath, widget.bucket);
    if (url.isNotEmpty && mounted) {
      setState(() => _videoUrl = url);
      _initVideoPlayer(url);
    } else if (mounted) {
      setState(() => _videoErr = true);
    }
  }

  void _initVideoPlayer(String url) {
    _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (mounted) setState(() => _videoReady = true);
      }).catchError((_) {
        if (mounted) setState(() => _videoErr = true);
      });
  }

  void _disposeVideo() {
    _videoCtrl?.dispose();
    _videoCtrl = null;
  }

  @override
  void dispose() { _disposeVideo(); super.dispose(); }

  // Shows error + copyable URL when image fails to load
  Widget _imgErrorWidget(EVC C, String url) {
    return Container(
        height: 200,
        child: Center(child: Column(
            mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.broken_image_outlined, size: 36, color: C.txtMuted),
          const SizedBox(height: 8),
          Text('Image failed to load', style: TextStyle(
              color: C.txtMuted, fontSize: 12)),
          if (url.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('URL copied — paste in browser'),
                          backgroundColor: Color(0xFF2563EB),
                          behavior: SnackBarBehavior.floating));
                },
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3))),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.copy_rounded, size: 12, color: Color(0xFF2563EB)),
                      SizedBox(width: 6),
                      Text('Copy Image URL', style: TextStyle(
                          color: Color(0xFF2563EB), fontSize: 11,
                          fontWeight: FontWeight.w600)),
                    ]))),
          ],
        ])));
  }

  @override
  Widget build(BuildContext context) {
    final C    = widget.C;
    final mime = widget.mime;

    // ── IMAGE ──────────────────────────────────────────
    if (mime.startsWith('image/')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _previewLabel(C, Icons.image_outlined,
              const Color(0xFF2563EB), 'Image Preview'),
          const SizedBox(height: 10),
          Container(
              decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: C.border)),
              clipBehavior: Clip.hardEdge,
              constraints: const BoxConstraints(
                  minHeight: 200, maxHeight: 500),
              child: _imgUrl == null
                  ? Container(height: 280,
                  child: Center(child: Column(
                      mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(
                            color: C.accent, strokeWidth: 2.5)),
                    const SizedBox(height: 12),
                    Text('Loading image...',
                        style: TextStyle(color: C.txtSecond, fontSize: 12)),
                  ])))
                  : _imgError
                  ? _imgErrorWidget(C, _imgUrl ?? '')
                  : InteractiveViewer(
                  minScale: 0.5, maxScale: 4.0,
                  child: Image.network(
                      _imgUrl!,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(height: 280,
                            child: Center(child: Column(
                                mainAxisSize: MainAxisSize.min, children: [
                              CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                      : null,
                                  color: C.accent, strokeWidth: 2.5),
                              const SizedBox(height: 10),
                              Text('Loading image...',
                                  style: TextStyle(color: C.txtSecond, fontSize: 12)),
                            ])));
                      },
                      errorBuilder: (_, err, __) {
                        debugPrint('Image load error: $err');
                        WidgetsBinding.instance.addPostFrameCallback(
                                (_) { if (mounted) setState(() => _imgError = true); });
                        return _imgErrorWidget(C, _imgUrl ?? '');
                      }))),
        ],
      );
    }

    // ── VIDEO ──────────────────────────────────────────
    if (mime.startsWith('video/')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _previewLabel(C, Icons.videocam_outlined,
              const Color(0xFF7C3AED), 'Video Preview'),
          const SizedBox(height: 10),
          Container(
              decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: C.border)),
              clipBehavior: Clip.hardEdge,
              child: _videoErr
                  ? Container(height: 200,
                  child: Center(child: Column(
                      mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.videocam_off_outlined,
                        size: 36, color: C.txtMuted),
                    const SizedBox(height: 8),
                    Text('Could not load video',
                        style: TextStyle(
                            color: C.txtMuted, fontSize: 12)),
                  ])))
                  : !_videoReady
                  ? Container(height: 200,
                  child: Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(
                                color: const Color(0xFF7C3AED),
                                strokeWidth: 2.5)),
                        const SizedBox(height: 12),
                        Text('Loading video...',
                            style: TextStyle(
                                color: C.txtSecond, fontSize: 12)),
                      ])))
                  : _videoPlayer(C)),
        ],
      );
    }

    // ── AUDIO ──────────────────────────────────────────
    if (mime.startsWith('audio/')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _previewLabel(C, Icons.music_note_outlined,
              const Color(0xFF059669), 'Audio File'),
          const SizedBox(height: 10),
          _AudioCard(
              storagePath: widget.storagePath,
              downloadURL: widget.downloadURL,
              fileName: widget.fileName,
              bucket: widget.bucket,
              C: C),
        ],
      );
    }

    // ── PDF / DOCUMENT ─────────────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _previewLabel(C, _docIcon(mime),
            _docColor(mime), _docLabel(mime)),
        const SizedBox(height: 10),
        _DocCard(
            storagePath: widget.storagePath,
            downloadURL: widget.downloadURL,
            fileName: widget.fileName,
            mime: mime,
            bucket: widget.bucket,
            C: C),
      ],
    );
  }

  Widget _previewLabel(EVC C, IconData icon,
      Color color, String text) {
    return Row(children: [
      Container(width: 4, height: 16,
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2)),
          margin: const EdgeInsets.only(right: 8)),
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Text(text, style: TextStyle(color: C.txtPrimary,
          fontSize: 13, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _videoPlayer(EVC C) {
    return Column(children: [
      AspectRatio(
          aspectRatio: _videoCtrl!.value.aspectRatio,
          child: VideoPlayer(_videoCtrl!)),
      Container(
        color: const Color(0xFF0D0D0D),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(children: [
          // Progress
          ValueListenableBuilder(
              valueListenable: _videoCtrl!,
              builder: (_, val, __) {
                final dur = val.duration.inMilliseconds;
                final pos = val.position.inMilliseconds;
                return Column(children: [
                  SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF7C3AED),
                          inactiveTrackColor:
                          Colors.white.withOpacity(0.15),
                          thumbColor: const Color(0xFF7C3AED),
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          trackHeight: 3,
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14)),
                      child: Slider(
                          value: dur > 0
                              ? (pos / dur).clamp(0, 1) : 0,
                          onChanged: (v) => _videoCtrl!.seekTo(
                              Duration(
                                  milliseconds: (v * dur).toInt())))),
                  Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_dur(val.position),
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10)),
                        Text(_dur(val.duration),
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10)),
                      ]),
                ]);
              }),
          // Controls
          Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _vidBtn(Icons.replay_10_rounded, () {
                  _videoCtrl!.seekTo(
                      _videoCtrl!.value.position -
                          const Duration(seconds: 10));
                }),
                const SizedBox(width: 20),
                GestureDetector(
                    onTap: () => setState(() {
                      _videoCtrl!.value.isPlaying
                          ? _videoCtrl!.pause()
                          : _videoCtrl!.play();
                    }),
                    child: Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(
                                color: const Color(0xFF7C3AED).withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4))]),
                        child: Icon(
                            _videoCtrl!.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white, size: 28))),
                const SizedBox(width: 20),
                _vidBtn(Icons.forward_10_rounded, () {
                  _videoCtrl!.seekTo(
                      _videoCtrl!.value.position +
                          const Duration(seconds: 10));
                }),
              ]),
        ]),
      ),
    ]);
  }

  Widget _vidBtn(IconData icon, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
          child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle),
              child: Icon(icon, size: 18,
                  color: Colors.white.withOpacity(0.8))));

  String _dur(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2,'0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2,'0');
    return '$m:$s';
  }

  Color _docColor(String mime) {
    if (mime == 'application/pdf')    return const Color(0xFFDC2626);
    if (mime.contains('word') || mime.contains('document'))
      return const Color(0xFF2563EB);
    if (mime.contains('sheet') || mime.contains('excel'))
      return const Color(0xFF059669);
    return const Color(0xFF64748B);
  }

  IconData _docIcon(String mime) {
    if (mime == 'application/pdf')    return Icons.picture_as_pdf_outlined;
    if (mime.contains('word') || mime.contains('document'))
      return Icons.description_outlined;
    if (mime.contains('sheet') || mime.contains('excel'))
      return Icons.table_chart_outlined;
    return Icons.insert_drive_file_outlined;
  }

  String _docLabel(String mime) {
    if (mime == 'application/pdf')    return 'PDF Document';
    if (mime.contains('word') || mime.contains('document'))
      return 'Word Document';
    if (mime.contains('sheet') || mime.contains('excel'))
      return 'Spreadsheet';
    if (mime == 'text/plain')         return 'Text File';
    return 'Document';
  }
}

// ════════════════════════════════════════════════════════════
// AUDIO CARD
// ════════════════════════════════════════════════════════════
class _AudioCard extends StatefulWidget {
  final String storagePath;
  final String downloadURL;
  final String fileName;
  final String bucket;
  final EVC C;
  const _AudioCard({required this.storagePath,
    required this.downloadURL,
    required this.fileName,
    required this.bucket,
    required this.C});

  @override
  State<_AudioCard> createState() => _AudioCardState();
}

class _AudioCardState extends State<_AudioCard>
    with SingleTickerProviderStateMixin {
  String? _url;
  late AnimationController _waveCtrl;
  late Animation<double> _wave;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _wave = _waveCtrl.drive(Tween(begin: 0.2, end: 1.0)
        .chain(CurveTween(curve: Curves.easeInOut)));
    // Use MongoDB downloadURL directly
    // Always fetch token URL from SDK
    _fetchUrl();
  }

  @override
  void dispose() { _waveCtrl.dispose(); super.dispose(); }

  Future<void> _fetchUrl() async {
    final url = await getStorageDownloadUrl(
        widget.storagePath, widget.bucket);
    if (url.isNotEmpty && mounted) setState(() => _url = url);
  }

  @override
  Widget build(BuildContext context) {
    final C = widget.C;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF059669).withOpacity(0.1),
                const Color(0xFF059669).withOpacity(0.03)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF059669).withOpacity(0.25))),
      child: Column(children: [
        // Waveform
        Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(32, (i) {
              final baseH = 6.0 + (i % 7) * 5.0;
              return AnimatedBuilder(
                  animation: _wave,
                  builder: (_, __) {
                    final factor = _playing
                        ? _wave.value * ((i % 3 == 0) ? 1.0 : 0.6)
                        : 0.3;
                    return Container(
                        width: 3,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 1.5),
                        height: baseH * factor + 4,
                        decoration: BoxDecoration(
                            color: const Color(0xFF059669)
                                .withOpacity(_playing ? 0.8 : 0.3),
                            borderRadius: BorderRadius.circular(2)));
                  });
            })),
        const SizedBox(height: 20),
        Text(widget.fileName,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: C.txtPrimary,
                fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Audio Evidence',
            style: TextStyle(color: Color(0xFF059669),
                fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 20),
        // Play button
        GestureDetector(
            onTap: () => setState(() => _playing = !_playing),
            child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                        color: const Color(0xFF059669).withOpacity(0.4),
                        blurRadius: 20, offset: const Offset(0, 6))]),
                child: Icon(
                    _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white, size: 30))),
        const SizedBox(height: 16),
        if (_url != null)
          GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _url!));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Audio URL copied — paste in browser'),
                        backgroundColor: Color(0xFF059669),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating));
              },
              child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: const Color(0xFF059669).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF059669).withOpacity(0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.copy_rounded,
                        size: 13, color: Color(0xFF059669)),
                    const SizedBox(width: 6),
                    const Text('Copy URL to play',
                        style: TextStyle(
                            color: Color(0xFF059669), fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]))),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// DOCUMENT CARD
// ════════════════════════════════════════════════════════════
class _DocCard extends StatefulWidget {
  final String storagePath;
  final String downloadURL;
  final String fileName;
  final String mime;
  final String bucket;
  final EVC C;
  const _DocCard({required this.storagePath,
    required this.downloadURL,
    required this.fileName, required this.mime,
    required this.bucket,
    required this.C});

  @override
  State<_DocCard> createState() => _DocCardState();
}

class _DocCardState extends State<_DocCard> {
  String? _url;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    // Use MongoDB downloadURL directly — no SDK call needed
    // Always fetch token URL from SDK
    _fetchUrl();
  }

  Future<void> _fetchUrl() async {
    final url = await getStorageDownloadUrl(
        widget.storagePath, widget.bucket);
    if (url.isNotEmpty && mounted) setState(() => _url = url);
  }

  Color get _color {
    if (widget.mime == 'application/pdf')
      return const Color(0xFFDC2626);
    if (widget.mime.contains('word') ||
        widget.mime.contains('document'))
      return const Color(0xFF2563EB);
    if (widget.mime.contains('sheet') ||
        widget.mime.contains('excel'))
      return const Color(0xFF059669);
    return const Color(0xFF64748B);
  }

  IconData get _icon {
    if (widget.mime == 'application/pdf')
      return Icons.picture_as_pdf_outlined;
    if (widget.mime.contains('word') ||
        widget.mime.contains('document'))
      return Icons.description_outlined;
    if (widget.mime.contains('sheet') ||
        widget.mime.contains('excel'))
      return Icons.table_chart_outlined;
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final C = widget.C;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
          color: _color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _color.withOpacity(0.2))),
      child: Column(children: [
        Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
                color: _color.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(_icon, size: 34, color: _color)),
        const SizedBox(height: 14),
        Text(widget.fileName,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(color: C.txtPrimary,
                fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: _color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(
                widget.mime == 'application/pdf' ? 'PDF Document'
                    : widget.mime.contains('word') ? 'Word Document'
                    : widget.mime.contains('sheet') ? 'Spreadsheet'
                    : 'Document',
                style: TextStyle(color: _color, fontSize: 10,
                    fontWeight: FontWeight.w700))),
        const SizedBox(height: 20),
        if (_url == null)
          SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(
                  color: _color, strokeWidth: 2))
        else
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _url!));
              setState(() => _copied = true);
              Future.delayed(const Duration(seconds: 2),
                      () { if (mounted) setState(() => _copied = false); });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text(
                      'URL copied — paste in browser to open'),
                  backgroundColor: _color,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))));
            },
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                    color: _copied
                        ? const Color(0xFF059669) : _color,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(
                        color: (_copied
                            ? const Color(0xFF059669) : _color)
                            .withOpacity(0.3),
                        blurRadius: 12, offset: const Offset(0, 4))]),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      _copied ? Icons.check_rounded
                          : Icons.copy_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                      _copied ? 'Copied!' : 'Copy File URL',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ])),
          ),
        const SizedBox(height: 8),
        Text(
            'Copy the URL and paste in your browser\nto open or download this file.',
            textAlign: TextAlign.center,
            style: TextStyle(color: C.txtMuted,
                fontSize: 11, height: 1.5)),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════
class _MimeData {
  final IconData icon;
  final Color color;
  final String label;
  const _MimeData(this.icon, this.color, this.label);

  factory _MimeData.from(String mime) {
    if (mime.startsWith('image/'))
      return const _MimeData(Icons.image_outlined,
          Color(0xFF2563EB), 'IMAGE');
    if (mime.startsWith('video/'))
      return const _MimeData(Icons.videocam_outlined,
          Color(0xFF7C3AED), 'VIDEO');
    if (mime.startsWith('audio/'))
      return const _MimeData(Icons.music_note_outlined,
          Color(0xFF059669), 'AUDIO');
    if (mime == 'application/pdf')
      return const _MimeData(Icons.picture_as_pdf_outlined,
          Color(0xFFDC2626), 'PDF');
    if (mime.contains('word') || mime.contains('document'))
      return const _MimeData(Icons.description_outlined,
          Color(0xFF0284C7), 'DOC');
    return const _MimeData(Icons.insert_drive_file_outlined,
        Color(0xFF64748B), 'FILE');
  }
}

// ── URL fixer ───────────────────────────────────────────────────────
String fixStorageUrl(String url) {
  if (url.isEmpty) return url;
  if (url.contains('firebasestorage.googleapis.com')) return url;
  final regex = RegExp(r'https://storage\.googleapis\.com/([^/]+)/(.+)');
  final match = regex.firstMatch(url);
  if (match != null) {
    final bucket  = match.group(1)!;
    final path    = match.group(2)!;
    final encoded = Uri.encodeComponent(path);
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encoded?alt=media';
  }
  return url;
}

// ── Firebase Storage URL getter ──────────────────────────────────────
// CORS is configured on the bucket — Image.network works on all platforms
// Uses Firebase REST API to get token URL (works on web + native)
Future<String> getStorageDownloadUrl(
    String storagePath, String bucket) async {
  if (storagePath.isEmpty) return '';

  try {
    // Firebase REST API — returns download token URL
    // Works on ALL platforms (web, Windows, Android, iOS)
    // Token URL bypasses any remaining CORS issues
    final encoded  = Uri.encodeComponent(storagePath);
    final apiUrl   =
        'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encoded';
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data  = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['downloadTokens'] as String? ?? '';
      if (token.isNotEmpty) {
        return '$apiUrl?alt=media&token=$token';
      }
      return '$apiUrl?alt=media';
    }
  } catch (_) {}

  // Fallback: Firebase Storage SDK (native only)
  if (!kIsWeb) {
    try {
      return await FirebaseStorage.instance
          .ref().child(storagePath).getDownloadURL();
    } catch (e) {
      debugPrint('🔴 Storage SDK error: $e');
    }
  }
  return '';
}

// ── Color palette ─────────────────────────────────────────
class EVC {
  final bool isDark;
  EVC(this.isDark);
  Color get bg         => isDark ? const Color(0xFF0B0F1A) : const Color(0xFFF0F4FF);
  Color get card       => isDark ? const Color(0xFF111827) : Colors.white;
  Color get inputBg    => isDark ? const Color(0xFF1A2540) : const Color(0xFFF8FAFF);
  Color get border     => isDark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0);
  Color get txtPrimary => isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  Color get txtSecond  => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get txtMuted   => isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);
  Color get accent     => const Color(0xFF2563EB);
}