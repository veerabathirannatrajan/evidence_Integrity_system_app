// evidence_list_screen.dart
// FIXED: dart:ui_web REMOVED — compiles on Android/iOS/Web/Desktop
// VIDEO: VideoPlayerController.networkUrl — works on all platforms
// IMAGE: Firebase REST token URL via http.get — no CORS, no platform issues
// UI: Premium light SaaS design, fully responsive, shimmer loading
import 'dart:convert';
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

// ─── Palette ─────────────────────────────────────────────────────────────────
class _P {
  static const bg         = Color(0xFFF4F7FF);
  static const card       = Colors.white;
  static const border     = Color(0xFFE8ECF4);
  static const ink        = Color(0xFF0A0E1A);
  static const slate      = Color(0xFF475569);
  static const muted      = Color(0xFF94A3B8);
  static const inputBg    = Color(0xFFF8FAFF);
  static const accent     = Color(0xFF3B5BDB);
  static const accentSoft = Color(0xFFEEF2FF);
  static const green      = Color(0xFF0D9488);
  static const greenSoft  = Color(0xFFECFDF5);
  static const red        = Color(0xFFDC2626);
  static const redSoft    = Color(0xFFFEF2F2);
  static const orange     = Color(0xFFD97706);
  static const purple     = Color(0xFF7C3AED);
  static const mobileBreak = 700.0;
}

// EVC kept for backward-compat with sub-widgets
class EVC {
  final bool isDark;
  EVC(this.isDark);
  Color get bg         => _P.bg;
  Color get card       => _P.card;
  Color get inputBg    => _P.inputBg;
  Color get border     => _P.border;
  Color get txtPrimary => _P.ink;
  Color get txtSecond  => _P.slate;
  Color get txtMuted   => _P.muted;
  Color get accent     => _P.accent;
}

// ─────────────────────────────────────────────────────────────────────────────
class EvidenceListScreen extends StatefulWidget {
  final String? filterByCaseId;
  const EvidenceListScreen({super.key, required this.filterByCaseId});
  @override State<EvidenceListScreen> createState() =>
      _EvidenceListScreenState();
}

class _EvidenceListScreenState extends State<EvidenceListScreen>
    with TickerProviderStateMixin {

  final _api        = ApiService();
  final _searchCtrl = TextEditingController();

  List<dynamic>              _cases       = [];
  Map<String, List<dynamic>> _evidenceMap = {};
  Set<String>                _expanded    = {};
  bool                       _loading     = true;
  String?                    _error;
  String                     _search      = '';
  String                     _filter      = 'all';
  Map<String, dynamic>?      _selected;
  bool                       _sidebarOpen = true;

  final Map<String, String>  _urlCache = {};
  final Map<String, String>  _imgCache = {};

  late AnimationController _entryCtrl;
  late Animation<double>   _entryOpacity;
  late Animation<Offset>   _entrySlide;
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _entryOpacity = _entryCtrl.drive(
        Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: const Interval(0, 0.65))));
    _entrySlide = _entryCtrl.drive(
        Tween(begin: const Offset(0, 0.03), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)));
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _entryCtrl.forward();
    _loadData();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _staggerCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Business logic unchanged ──────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (widget.filterByCaseId != null) {
        final caseData = await _api.getCaseById(widget.filterByCaseId!);
        final ev       = await _api.getEvidenceByCase(widget.filterByCaseId!);
        if (mounted) setState(() {
          _cases       = [caseData];
          _evidenceMap = {widget.filterByCaseId!: List.from(ev)};
          _expanded    = {widget.filterByCaseId!};
          _loading     = false;
          if (ev.isNotEmpty)
            _selectEvidence(Map<String, dynamic>.from(ev.first));
        });
      } else {
        final cases = await _api.getCasesWithEvidence();
        if (mounted) setState(() {
          _cases   = cases;
          _loading = false;
          if (cases.isNotEmpty) {
            final id = cases.first['_id'].toString();
            _expanded = {id};
            _loadCaseEvidence(id);
          }
        });
      }
      _staggerCtrl.forward(from: 0);
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Failed to load: $e'; _loading = false;
      });
    }
  }

  Future<void> _loadCaseEvidence(String caseId) async {
    if (_evidenceMap.containsKey(caseId)) return;
    try {
      final ev = await _api.getEvidenceByCase(caseId);
      if (mounted) setState(() => _evidenceMap[caseId] = List.from(ev));
    } catch (_) {}
  }

  void _toggle(String caseId) {
    setState(() {
      if (_expanded.contains(caseId)) _expanded.remove(caseId);
      else { _expanded.add(caseId); _loadCaseEvidence(caseId); }
    });
  }

  List<dynamic> _filteredEv(String caseId) {
    return (_evidenceMap[caseId] ?? []).where((e) {
      final s = (e['blockchainStatus'] as String?) ?? '';
      final t = e['isTampered'] == true;
      if (_filter == 'anchored' && s != 'anchored') return false;
      if (_filter == 'tampered' && !t)              return false;
      if (_filter == 'pending'  && s != 'pending')  return false;
      if (_search.isNotEmpty &&
          !(e['fileName'] ?? '').toLowerCase()
              .contains(_search.toLowerCase())) return false;
      return true;
    }).toList();
  }

  void _selectEvidence(Map<String, dynamic> ev) =>
      setState(() => _selected = ev);

  void _snack(String msg, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg), backgroundColor: c,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))));

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _snack('$label copied', _P.green);
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final C = EVC(false);
    return Scaffold(
      backgroundColor: _P.bg,
      body: FadeTransition(
        opacity: _entryOpacity,
        child: SlideTransition(
          position: _entrySlide,
          child: LayoutBuilder(builder: (ctx, cs) {
            if (cs.maxWidth < _P.mobileBreak)
              return _mobileLayout(C, cs);
            return _desktopLayout(C);
          }),
        ),
      ),
    );
  }

  // ── DESKTOP ───────────────────────────────────────────────────────────────
  Widget _desktopLayout(EVC C) {
    return Row(children: [
      // Sidebar
      AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        width: _sidebarOpen ? 340 : 0,
        child: _sidebarOpen ? _buildSidebar(C) : const SizedBox.shrink(),
      ),
      // Collapse handle
      GestureDetector(
        onTap: () => setState(() => _sidebarOpen = !_sidebarOpen),
        child: Container(
          width: 14, color: _P.bg,
          child: Center(child: Container(
              width: 4, height: 36,
              decoration: BoxDecoration(
                  color: _P.border,
                  borderRadius: BorderRadius.circular(2)))),
        ),
      ),
      // Main
      Expanded(child: _selected == null
          ? _emptyState() : _buildDetail(C)),
    ]);
  }

  // ── MOBILE ────────────────────────────────────────────────────────────────
  Widget _mobileLayout(EVC C, BoxConstraints cs) {
    return Scaffold(
      backgroundColor: _P.bg,
      drawer: Drawer(
        width: cs.maxWidth * 0.88,
        child: _buildSidebar(C),
      ),
      appBar: AppBar(
        backgroundColor: _P.card,
        elevation: 0, scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: _P.ink, size: 20),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        )),
        title: Text(
          _selected != null
              ? (_selected!['fileName'] as String? ?? 'Evidence')
              : 'Evidence Files',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _P.ink,
              fontSize: 14, fontWeight: FontWeight.w800),
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(color: _P.border, height: 1)),
      ),
      body: _selected == null ? _emptyState() : _buildDetail(C),
    );
  }

  // ── SIDEBAR ───────────────────────────────────────────────────────────────
  Widget _buildSidebar(EVC C) {
    return Container(
      decoration: BoxDecoration(
        color: _P.card,
        border: const Border(right: BorderSide(color: _P.border)),
        boxShadow: [BoxShadow(
            color: _P.accent.withOpacity(0.04),
            blurRadius: 20, offset: const Offset(4, 0))],
      ),
      child: Column(children: [
        // Header
        Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _P.border))),
          child: Row(children: [
            _IconBtn(Icons.arrow_back_rounded,
                    () => Navigator.pop(context), 'Back'),
            const SizedBox(width: 10),
            Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF3B5BDB), Color(0xFF2248C9)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(
                        color: _P.accent.withOpacity(0.3),
                        blurRadius: 10, offset: const Offset(0, 4))]),
                child: const Icon(Icons.folder_outlined,
                    color: Colors.white, size: 16)),
            const SizedBox(width: 10),
            Expanded(child: Text(
              widget.filterByCaseId != null
                  ? 'Case Evidence' : 'Evidence by Case',
              style: const TextStyle(color: _P.ink,
                  fontSize: 14, fontWeight: FontWeight.w800),
            )),
            _IconBtn(Icons.refresh_rounded, () {
              _urlCache.clear(); _imgCache.clear();
              _evidenceMap.clear(); _loadData();
            }, 'Refresh'),
          ]),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Container(
            decoration: BoxDecoration(
                color: _P.inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _P.border),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.025),
                    blurRadius: 6, offset: const Offset(0, 2))]),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: _P.ink, fontSize: 13),
              decoration: InputDecoration(
                  hintText: 'Search files…',
                  hintStyle: const TextStyle(color: _P.muted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 16, color: _P.muted),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 14, color: _P.muted),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      }) : null,
                  border: InputBorder.none, isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 14)),
            ),
          ),
        ),
        // Filters
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final f in ['all','anchored','tampered','pending'])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _FilterChip(
                    label: f[0].toUpperCase() + f.substring(1),
                    active: _filter == f,
                    color: _filterColor(f),
                    onTap: () => setState(() => _filter = f),
                  ),
                ),
            ]),
          ),
        ),
        // List
        Expanded(child: _loading
            ? const _ShimmerList()
            : _error != null
            ? _ErrorState(m: _error!, onRetry: _loadData)
            : _cases.isEmpty
            ? const _EmptyCases()
            : ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _cases.length,
          itemBuilder: (_, i) {
            final delay = (i * 0.08).clamp(0.0, 0.8);
            return AnimatedBuilder(
              animation: _staggerCtrl,
              builder: (_, child) {
                final t = Curves.easeOutCubic.transform(
                    ((_staggerCtrl.value - delay) / (1 - delay))
                        .clamp(0.0, 1.0));
                return Opacity(opacity: t,
                    child: Transform.translate(
                        offset: Offset(0, 14 * (1 - t)),
                        child: child));
              },
              child: _CaseBlock(
                caseData: _cases[i],
                evidenceMap: _evidenceMap,
                expanded: _expanded,
                filter: _filter, search: _search,
                selected: _selected,
                urlCache: _urlCache, C: C,
                onToggle: _toggle,
                onSelect: (ev) {
                  _selectEvidence(ev);
                  // close drawer on mobile
                  if (MediaQuery.of(context).size.width < _P.mobileBreak) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            );
          },
        )),
      ]),
    );
  }

  // ── DETAIL ────────────────────────────────────────────────────────────────
  Widget _buildDetail(EVC C) {
    final ev       = _selected!;
    final id       = ev['_id']?.toString() ?? '';
    final name     = ev['fileName'] as String? ?? '';
    final mime     = ev['fileType'] as String? ?? '';
    final path     = ev['storagePath'] as String? ?? '';
    final status   = ev['blockchainStatus'] as String? ?? 'pending';
    final tampered = ev['isTampered'] == true;
    final fileHash = ev['fileHash'] as String? ?? '';
    final txHash   = ev['blockchainTxHash'] as String?;
    final caseId   = ev['caseId']?.toString() ?? '';
    final desc     = ev['description'] as String? ?? '';

    return Column(children: [
      // Top bar
      Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            color: _P.card,
            border: const Border(bottom: BorderSide(color: _P.border)),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          _MimeTag(mime),
          const SizedBox(width: 12),
          Expanded(child: Text(name, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _P.ink,
                  fontSize: 14, fontWeight: FontWeight.w800))),
          _ActionBtn(Icons.verified_outlined, _P.green, 'Verify', () =>
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                      VerifyEvidenceScreen(evidenceId: id)))
                  .then((_) {
                _evidenceMap.clear();
                _urlCache.remove(id);
                _loadData();
              })),
          if (status == 'anchored' && txHash != null) ...[
            const SizedBox(width: 6),
            _ActionBtn(Icons.link_rounded, _P.purple, 'Blockchain', () =>
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) =>
                        BlockchainViewerScreen(
                            evidenceId: id, txHash: txHash)))),
          ],
          const SizedBox(width: 6),
          _IconBtn(Icons.close_rounded,
                  () => setState(() => _selected = null), 'Close'),
        ]),
      ),
      // Body
      Expanded(child: LayoutBuilder(builder: (ctx, cs) {
        final narrow = cs.maxWidth < 640;
        if (narrow) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tampered) ...[
                    _TamperBanner(evidenceId: id),
                    const SizedBox(height: 14),
                  ],
                  _PreviewWidget(
                      storagePath: path,
                      downloadURL: ev['downloadURL'] as String? ?? '',
                      mime: mime, fileName: name, evidenceId: id,
                      bucket: 'evidence-system-6f225.firebasestorage.app',
                      imgCache: _imgCache, onImgLoaded: (_) {}, C: C),
                  const SizedBox(height: 16),
                  Divider(color: _P.border),
                  const SizedBox(height: 12),
                  _MetaSidebar(
                      ev: ev, id: id, name: name, mime: mime,
                      status: status, tampered: tampered,
                      fileHash: fileHash, txHash: txHash,
                      caseId: caseId, desc: desc, onCopy: _copy),
                ]),
          );
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tampered) ...[
                    _TamperBanner(evidenceId: id),
                    const SizedBox(height: 16),
                  ],
                  _PreviewWidget(
                      storagePath: path,
                      downloadURL: ev['downloadURL'] as String? ?? '',
                      mime: mime, fileName: name, evidenceId: id,
                      bucket: 'evidence-system-6f225.firebasestorage.app',
                      imgCache: _imgCache, onImgLoaded: (_) {}, C: C),
                ]),
          )),
          VerticalDivider(color: _P.border, width: 1),
          SizedBox(width: 272, child: _MetaSidebar(
              ev: ev, id: id, name: name, mime: mime,
              status: status, tampered: tampered,
              fileHash: fileHash, txHash: txHash,
              caseId: caseId, desc: desc, onCopy: _copy)),
        ]);
      })),
    ]);
  }

  Widget _emptyState() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFFF4F7FF), Color(0xFFEEF2FF)],
      ),
    ),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 1.0),
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
        builder: (_, v, child) =>
            Transform.scale(scale: v, child: child),
        child: Container(
          width: 88, height: 88,
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _P.accent.withOpacity(0.15), _P.accent.withOpacity(0.04)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: _P.accent.withOpacity(0.14),
                  blurRadius: 28, offset: const Offset(0, 8))]),
          child: const Icon(Icons.touch_app_outlined,
              size: 38, color: _P.accent),
        ),
      ),
      const SizedBox(height: 20),
      const Text('Select an evidence file',
          style: TextStyle(color: _P.ink,
              fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      const Text('Tap any file from the list to preview it',
          style: TextStyle(color: _P.muted, fontSize: 13)),
    ])),
  );

  Color _filterColor(String f) => switch (f) {
    'anchored' => _P.green,
    'tampered' => _P.red,
    'pending'  => _P.orange,
    _          => _P.accent,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  CASE BLOCK
// ─────────────────────────────────────────────────────────────────────────────
class _CaseBlock extends StatefulWidget {
  final Map              caseData;
  final Map<String, List<dynamic>> evidenceMap;
  final Set<String>      expanded;
  final String           filter, search;
  final Map<String,dynamic>? selected;
  final Map<String,String>   urlCache;
  final EVC              C;
  final ValueChanged<String>              onToggle;
  final ValueChanged<Map<String,dynamic>> onSelect;

  const _CaseBlock({
    required this.caseData, required this.evidenceMap,
    required this.expanded, required this.filter, required this.search,
    required this.selected, required this.urlCache, required this.C,
    required this.onToggle, required this.onSelect,
  });
  @override State<_CaseBlock> createState() => _CaseBlockState();
}

class _CaseBlockState extends State<_CaseBlock> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final caseId   = widget.caseData['_id'].toString();
    final isOpen   = widget.expanded.contains(caseId);
    final stats    = widget.caseData['evidenceStats'] as Map? ?? {};
    final total    = stats['total']    as int? ?? 0;
    final tampered = stats['tampered'] as int? ?? 0;
    final anchored = stats['anchored'] as int? ?? 0;
    final hasBad   = tampered > 0;
    final title    = widget.caseData['title']   as String? ?? 'Untitled';
    final ref      = widget.caseData['caseRef'] as String? ?? '';
    final status   = widget.caseData['status']  as String? ?? 'open';

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit:  (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () => widget.onToggle(caseId),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: hasBad ? _P.red.withOpacity(0.04)
                      : isOpen || _hovered
                      ? _P.accent.withOpacity(0.04)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: hasBad ? _P.red.withOpacity(0.2)
                          : isOpen ? _P.accent.withOpacity(0.2)
                          : Colors.transparent),
                  boxShadow: _hovered ? [BoxShadow(
                      color: _P.accent.withOpacity(0.06),
                      blurRadius: 10, offset: const Offset(0, 2))] : []),
              child: Row(children: [
                Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: hasBad
                            ? _P.red.withOpacity(0.1)
                            : _P.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9)),
                    child: Icon(
                        hasBad ? Icons.warning_amber_rounded
                            : Icons.folder_outlined,
                        size: 18,
                        color: hasBad ? _P.red : _P.accent)),
                const SizedBox(width: 10),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _P.ink,
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Row(children: [
                        _StatusDot(status),
                        if (ref.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(ref, style: const TextStyle(
                              color: _P.accent, fontSize: 9,
                              fontFamily: 'monospace')),
                        ],
                      ]),
                    ])),
                const SizedBox(width: 6),
                Column(crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$total files',
                          style: const TextStyle(
                              color: _P.muted, fontSize: 9)),
                      const SizedBox(height: 3),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        if (anchored > 0)
                          _MiniTag('$anchored ✓', _P.green),
                        if (hasBad) ...[
                          const SizedBox(width: 4),
                          _MiniTag('$tampered ⚠', _P.red),
                        ],
                      ]),
                    ]),
                const SizedBox(width: 4),
                AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(Icons.expand_more_rounded,
                        size: 18, color: _P.muted)),
              ]),
            ),
          ),
        ),
        // Evidence tiles (animated expand)
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(left: 18, right: 8, top: 2),
            child: _buildTiles(caseId),
          ),
          crossFadeState: isOpen
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
        Divider(color: _P.border, height: 12),
      ]),
    );
  }

  Widget _buildTiles(String caseId) {
    final all = widget.evidenceMap[caseId];
    if (all == null) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(
                        color: _P.accent, strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Loading…',
                    style: TextStyle(color: _P.muted, fontSize: 12)),
              ]));
    }
    // filter
    final evidence = all.where((e) {
      final s = (e['blockchainStatus'] as String?) ?? '';
      final t = e['isTampered'] == true;
      if (widget.filter == 'anchored' && s != 'anchored') return false;
      if (widget.filter == 'tampered' && !t)              return false;
      if (widget.filter == 'pending'  && s != 'pending')  return false;
      if (widget.search.isNotEmpty &&
          !(e['fileName'] ?? '').toLowerCase()
              .contains(widget.search.toLowerCase())) return false;
      return true;
    }).toList();

    if (evidence.isEmpty) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(child: Text(
              all.isEmpty ? 'No evidence yet' : 'No results',
              style: const TextStyle(color: _P.muted, fontSize: 12))));
    }
    return Column(children: evidence.map((ev) =>
        _EvTile(ev: ev, selected: widget.selected,
            urlCache: widget.urlCache, C: widget.C,
            onSelect: widget.onSelect))
        .toList());
  }
}

// ── Evidence tile ─────────────────────────────────────────────────────────────
class _EvTile extends StatefulWidget {
  final Map ev;
  final Map<String,dynamic>? selected;
  final Map<String,String>   urlCache;
  final EVC C;
  final ValueChanged<Map<String,dynamic>> onSelect;
  const _EvTile({required this.ev, required this.selected,
    required this.urlCache, required this.C, required this.onSelect});
  @override State<_EvTile> createState() => _EvTileState();
}

class _EvTileState extends State<_EvTile> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final ev       = widget.ev;
    final id       = ev['_id']?.toString() ?? '';
    final name     = ev['fileName'] as String? ?? 'Unknown';
    final mime     = ev['fileType'] as String? ?? '';
    final status   = ev['blockchainStatus'] as String? ?? 'pending';
    final tampered = ev['isTampered'] == true;
    final path     = ev['storagePath'] as String? ?? '';
    final isActive = widget.selected?['_id'] == id;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onSelect(Map<String,dynamic>.from(ev)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 3),
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
              color: isActive
                  ? _P.accent.withOpacity(0.08)
                  : _hovered ? _P.accent.withOpacity(0.03)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isActive
                      ? _P.accent.withOpacity(0.3)
                      : Colors.transparent,
                  width: 1.5)),
          child: Row(children: [
            _StorageThumbnail(
                storagePath: path,
                downloadURL: ev['downloadURL'] as String? ?? '',
                mime: mime, tampered: tampered, C: widget.C,
                evidenceId: id,
                bucket: 'evidence-system-6f225.firebasestorage.app',
                urlCache: widget.urlCache),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, overflow: TextOverflow.ellipsis, maxLines: 1,
                      style: TextStyle(
                          color: isActive ? _P.accent : _P.ink,
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Row(children: [
                    _StatusPill(tampered ? 'tampered' : status),
                    const SizedBox(width: 5),
                    Text(_fmtSize(ev['fileSize']),
                        style: const TextStyle(
                            color: _P.muted, fontSize: 9)),
                  ]),
                ])),
            if (isActive)
              Container(width: 4, height: 30,
                  decoration: BoxDecoration(
                      color: _P.accent,
                      borderRadius: BorderRadius.circular(2))),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  META SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────
class _MetaSidebar extends StatelessWidget {
  final Map<String,dynamic> ev;
  final String id, name, mime, status, fileHash, caseId, desc;
  final bool   tampered;
  final String? txHash;
  final void Function(String,String) onCopy;

  const _MetaSidebar({
    required this.ev, required this.id, required this.name,
    required this.mime, required this.status, required this.tampered,
    required this.fileHash, required this.txHash, required this.caseId,
    required this.desc, required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section('Status'),
            const SizedBox(height: 8),
            _BigBadge(tampered ? 'TAMPERED' : status.toUpperCase(),
                tampered ? _P.red : _chainColor(status)),
            const SizedBox(height: 16),

            _Section('Evidence Details'),
            const SizedBox(height: 8),
            _Meta('ID', id, mono: true,
                onCopy: () => onCopy(id, 'ID')),
            _Meta('File', name),
            _Meta('Type', mime.isNotEmpty ? mime : '—'),
            _Meta('Size', _fmtSize(ev['fileSize'])),
            _Meta('Uploaded', _fmtDate(ev['createdAt']?.toString())),
            _Meta('Case ID', caseId, mono: true,
                onCopy: () => onCopy(caseId, 'Case ID')),
            if (desc.isNotEmpty) _Meta('Note', desc),
            const SizedBox(height: 16),

            _Section('SHA-256 Hash'),
            const SizedBox(height: 8),
            _HashBlock(hash: fileHash,
                onCopy: () => onCopy(fileHash, 'Hash')),
            const SizedBox(height: 16),

            _Section('Blockchain'),
            const SizedBox(height: 8),
            _Meta('Network', 'Polygon Amoy'),
            _Meta('Status',
                status[0].toUpperCase() + status.substring(1),
                valueColor: _chainColor(status)),
            if (txHash != null)
              _Meta('TX Hash', txHash!, mono: true,
                  onCopy: () => onCopy(txHash!, 'TX Hash')),
            if (ev['anchoredAt'] != null)
              _Meta('Anchored', _fmtDate(ev['anchoredAt']?.toString())),
          ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STORAGE THUMBNAIL
// ─────────────────────────────────────────────────────────────────────────────
class _StorageThumbnail extends StatefulWidget {
  final String storagePath, downloadURL, mime, evidenceId, bucket;
  final bool   tampered;
  final EVC    C;
  final Map<String,String> urlCache;
  const _StorageThumbnail({
    required this.storagePath, required this.downloadURL,
    required this.mime, required this.tampered, required this.C,
    required this.evidenceId, required this.bucket,
    required this.urlCache,
  });
  @override State<_StorageThumbnail> createState() =>
      _StorageThumbnailState();
}

class _StorageThumbnailState extends State<_StorageThumbnail> {
  String? _url;
  bool _loading = false, _error = false;

  @override
  void initState() {
    super.initState();
    if (widget.urlCache.containsKey(widget.evidenceId)) {
      _url = widget.urlCache[widget.evidenceId];
    } else if (widget.mime.startsWith('image/') &&
        widget.storagePath.isNotEmpty) {
      _loadUrl();
    }
  }

  Future<void> _loadUrl() async {
    if (_loading) return;
    if (mounted) setState(() => _loading = true);
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
    if (widget.tampered) {
      return Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: _P.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _P.red.withOpacity(0.3))),
          child: const Icon(Icons.warning_amber_rounded,
              size: 18, color: _P.red));
    }
    if (widget.mime.startsWith('image/')) {
      if (_loading) {
        return Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: _P.inputBg,
                borderRadius: BorderRadius.circular(9)),
            child: const Center(child: SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(
                    color: _P.accent, strokeWidth: 2))));
      }
      if (_url != null && !_error) {
        return ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.network(_url!,
                width: 40, height: 40, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _iconBox(widget.mime)));
      }
    }
    return _iconBox(widget.mime);
  }

  Widget _iconBox(String mime) {
    final d = _MimeData.from(mime);
    return Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
            color: d.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(9)),
        child: Icon(d.icon, size: 19, color: d.color));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PREVIEW WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _PreviewWidget extends StatefulWidget {
  final String storagePath, downloadURL, mime, fileName, evidenceId, bucket;
  final Map<String,String>  imgCache;
  final void Function(String?) onImgLoaded;
  final EVC C;
  const _PreviewWidget({
    required this.storagePath, required this.downloadURL,
    required this.mime, required this.fileName,
    required this.evidenceId, required this.bucket,
    required this.imgCache, required this.onImgLoaded, required this.C,
  });
  @override State<_PreviewWidget> createState() => _PreviewWidgetState();
}

class _PreviewWidgetState extends State<_PreviewWidget> {
  String? _imgUrl;
  bool _imgLoading = false, _imgError = false;
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false, _videoErr = false;

  @override
  void initState() { super.initState(); _init(); }

  @override
  void didUpdateWidget(_PreviewWidget old) {
    super.didUpdateWidget(old);
    if (old.storagePath != widget.storagePath) {
      _disposeVideo();
      setState(() {
        _imgUrl = null; _imgLoading = false; _imgError = false;
        _videoReady = false; _videoErr = false;
      });
      _init();
    }
  }

  void _init() {
    if (widget.mime.startsWith('image/'))      _loadImage();
    else if (widget.mime.startsWith('video/')) _loadVideo();
  }

  Future<void> _loadImage() async {
    if (widget.imgCache.containsKey(widget.evidenceId)) {
      final c = widget.imgCache[widget.evidenceId];
      if ((c?.isNotEmpty ?? false) && mounted) {
        setState(() => _imgUrl = c); return;
      }
    }
    if (_imgLoading) return;
    if (mounted) setState(() => _imgLoading = true);
    final url = await getStorageDownloadUrl(
        widget.storagePath, widget.bucket);
    if (url.isNotEmpty && mounted) {
      widget.imgCache[widget.evidenceId] = url;
      setState(() { _imgUrl = url; _imgLoading = false; });
    } else if (mounted) {
      setState(() { _imgLoading = false; _imgError = true; });
    }
  }

  Future<void> _loadVideo() async {
    final url = await getStorageDownloadUrl(
        widget.storagePath, widget.bucket);
    if (url.isEmpty) {
      if (mounted) setState(() => _videoErr = true); return;
    }
    // VideoPlayerController.networkUrl — works on ALL platforms
    _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (mounted) setState(() => _videoReady = true);
      }).catchError((_) {
        if (mounted) setState(() => _videoErr = true);
      });
  }

  void _disposeVideo() { _videoCtrl?.dispose(); _videoCtrl = null; }
  @override void dispose() { _disposeVideo(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final mime = widget.mime;
    final C    = widget.C;

    if (mime.startsWith('image/')) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _PreviewLabel(Icons.image_outlined, _P.accent, 'Image Preview'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
              color: const Color(0xFF0D0D14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _P.border),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20, offset: const Offset(0, 6))]),
          clipBehavior: Clip.hardEdge,
          constraints: const BoxConstraints(minHeight: 180, maxHeight: 500),
          child: _imgLoading || _imgUrl == null
              ? _imgPlaceholder()
              : _imgError ? _imgFail()
              : InteractiveViewer(
              minScale: 0.5, maxScale: 4.0,
              child: Image.network(_imgUrl!,
                  width: double.infinity, fit: BoxFit.contain,
                  loadingBuilder: (_, child, prog) =>
                  prog == null ? child : _imgPlaceholder(),
                  errorBuilder: (_, __, ___) {
                    WidgetsBinding.instance.addPostFrameCallback(
                            (_) { if (mounted)
                          setState(() => _imgError = true); });
                    return _imgFail();
                  })),
        ),
      ]);
    }

    if (mime.startsWith('video/')) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _PreviewLabel(Icons.videocam_outlined, _P.purple, 'Video Preview'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 22, offset: const Offset(0, 7))]),
          clipBehavior: Clip.hardEdge,
          child: _videoErr
              ? _videoBroken()
              : !_videoReady ? _videoLoading()
              : _VideoControls(ctrl: _videoCtrl!),
        ),
      ]);
    }

    if (mime.startsWith('audio/')) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _PreviewLabel(Icons.headphones_outlined, _P.green, 'Audio File'),
        const SizedBox(height: 10),
        _AudioCard(storagePath: widget.storagePath,
            downloadURL: widget.downloadURL, fileName: widget.fileName,
            bucket: widget.bucket, C: C),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _PreviewLabel(_docIcon(mime), _docColor(mime), _docLabel(mime)),
      const SizedBox(height: 10),
      _DocCard(storagePath: widget.storagePath,
          downloadURL: widget.downloadURL, fileName: widget.fileName,
          mime: mime, bucket: widget.bucket, C: C),
    ]);
  }

  Widget _imgPlaceholder() => SizedBox(height: 260,
      child: Center(child: Column(mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(width: 24, height: 24,
                child: CircularProgressIndicator(
                    color: _P.accent, strokeWidth: 2.5)),
            SizedBox(height: 12),
            Text('Loading image…',
                style: TextStyle(color: _P.muted, fontSize: 12)),
          ])));

  Widget _imgFail() => SizedBox(height: 200,
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.broken_image_outlined, size: 36, color: _P.muted),
        const SizedBox(height: 8),
        const Text('Could not load image',
            style: TextStyle(color: _P.muted, fontSize: 12)),
        if (_imgUrl?.isNotEmpty == true) ...[
          const SizedBox(height: 10),
          TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _imgUrl!));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('URL copied — paste in browser'),
                    backgroundColor: _P.accent,
                    behavior: SnackBarBehavior.floating));
              },
              icon: const Icon(Icons.copy_rounded, size: 13),
              label: const Text('Copy URL')),
        ],
      ])));

  Widget _videoBroken() => const SizedBox(height: 200,
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.videocam_off_outlined, size: 36, color: _P.muted),
        SizedBox(height: 8),
        Text('Could not load video',
            style: TextStyle(color: _P.muted, fontSize: 12)),
      ])));

  Widget _videoLoading() => const SizedBox(height: 200,
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 24, height: 24,
            child: CircularProgressIndicator(
                color: _P.purple, strokeWidth: 2.5)),
        SizedBox(height: 12),
        Text('Loading video…',
            style: TextStyle(color: _P.muted, fontSize: 12)),
      ])));

  Color    _docColor(String m) {
    if (m == 'application/pdf') return _P.red;
    if (m.contains('word') || m.contains('document')) return _P.accent;
    if (m.contains('sheet') || m.contains('excel')) return _P.green;
    return _P.muted;
  }
  IconData _docIcon(String m) {
    if (m == 'application/pdf') return Icons.picture_as_pdf_outlined;
    if (m.contains('word') || m.contains('document'))
      return Icons.description_outlined;
    if (m.contains('sheet') || m.contains('excel'))
      return Icons.table_chart_outlined;
    return Icons.insert_drive_file_outlined;
  }
  String   _docLabel(String m) {
    if (m == 'application/pdf') return 'PDF Document';
    if (m.contains('word') || m.contains('document')) return 'Word Document';
    if (m.contains('sheet') || m.contains('excel'))   return 'Spreadsheet';
    return 'Document';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  VIDEO CONTROLS — cross-platform (Android · iOS · Web · Windows · macOS)
// ─────────────────────────────────────────────────────────────────────────────
class _VideoControls extends StatefulWidget {
  final VideoPlayerController ctrl;
  const _VideoControls({required this.ctrl});
  @override State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  @override void initState() {
    super.initState(); widget.ctrl.addListener(_rebuild);
  }
  void _rebuild() { if (mounted) setState(() {}); }
  @override void dispose() {
    widget.ctrl.removeListener(_rebuild); super.dispose();
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2,'0')}:'
          '${d.inSeconds.remainder(60).toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    final v   = widget.ctrl.value;
    final dur = v.duration.inMilliseconds;
    final pos = v.position.inMilliseconds;
    final frac = dur > 0 ? (pos / dur).clamp(0.0, 1.0) : 0.0;

    return Column(children: [
      AspectRatio(
          aspectRatio: v.aspectRatio > 0 ? v.aspectRatio : 16/9,
          child: VideoPlayer(widget.ctrl)),
      Container(
        color: const Color(0xFF0D0D14),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
                activeTrackColor: _P.purple,
                inactiveTrackColor: Colors.white.withOpacity(0.14),
                thumbColor: _P.purple,
                thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6),
                trackHeight: 3,
                overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14)),
            child: Slider(
                value: frac.toDouble(),
                onChanged: (val) => widget.ctrl.seekTo(
                    Duration(milliseconds: (val * dur).toInt()))),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(v.position),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10)),
                Text(_fmt(v.duration),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10)),
              ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _VidBtn(Icons.replay_10_rounded, () => widget.ctrl.seekTo(
                v.position - const Duration(seconds: 10))),
            const SizedBox(width: 20),
            GestureDetector(
                onTap: () => v.isPlaying
                    ? widget.ctrl.pause()
                    : widget.ctrl.play(),
                child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                        color: _P.purple, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                            color: _P.purple.withOpacity(0.4),
                            blurRadius: 18, offset: const Offset(0, 5))]),
                    child: Icon(
                        v.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white, size: 28))),
            const SizedBox(width: 20),
            _VidBtn(Icons.forward_10_rounded, () => widget.ctrl.seekTo(
                v.position + const Duration(seconds: 10))),
          ]),
        ]),
      ),
    ]);
  }
}

class _VidBtn extends StatelessWidget {
  final IconData i; final VoidCallback t;
  const _VidBtn(this.i, this.t);
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: t,
      child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle),
          child: Icon(i, size: 18,
              color: Colors.white.withOpacity(0.8))));
}

// ─────────────────────────────────────────────────────────────────────────────
//  AUDIO CARD
// ─────────────────────────────────────────────────────────────────────────────
class _AudioCard extends StatefulWidget {
  final String storagePath, downloadURL, fileName, bucket;
  final EVC C;
  const _AudioCard({required this.storagePath, required this.downloadURL,
    required this.fileName, required this.bucket, required this.C});
  @override State<_AudioCard> createState() => _AudioCardState();
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
        duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _wave = _waveCtrl.drive(Tween(begin: 0.2, end: 1.0)
        .chain(CurveTween(curve: Curves.easeInOut)));
    _fetchUrl();
  }

  Future<void> _fetchUrl() async {
    final url = await getStorageDownloadUrl(
        widget.storagePath, widget.bucket);
    if (url.isNotEmpty && mounted) setState(() => _url = url);
  }

  @override void dispose() { _waveCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_P.green.withOpacity(0.08),
                _P.green.withOpacity(0.02)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.green.withOpacity(0.2)),
          boxShadow: [BoxShadow(
              color: _P.green.withOpacity(0.06),
              blurRadius: 14, offset: const Offset(0, 4))]),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(32, (i) {
              final baseH = 6.0 + (i % 7) * 5.0;
              return AnimatedBuilder(
                  animation: _wave,
                  builder: (_, __) {
                    final f = _playing
                        ? _wave.value * ((i % 3 == 0) ? 1.0 : 0.6) : 0.3;
                    return Container(
                        width: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        height: baseH * f + 4,
                        decoration: BoxDecoration(
                            color: _P.green.withOpacity(
                                _playing ? 0.8 : 0.3),
                            borderRadius: BorderRadius.circular(2)));
                  });
            })),
        const SizedBox(height: 20),
        Text(widget.fileName, textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _P.ink,
                fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Audio Evidence',
            style: TextStyle(color: _P.green,
                fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 20),
        GestureDetector(
            onTap: () => setState(() => _playing = !_playing),
            child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                    color: _P.green, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                        color: _P.green.withOpacity(0.35),
                        blurRadius: 18, offset: const Offset(0, 5))]),
                child: Icon(
                    _playing ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white, size: 30))),
        if (_url != null) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _url!));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Audio URL copied — paste in browser'),
                  backgroundColor: _P.green,
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating));
            },
            icon: const Icon(Icons.copy_rounded,
                size: 13, color: _P.green),
            label: const Text('Copy URL to play',
                style: TextStyle(color: _P.green, fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DOCUMENT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _DocCard extends StatefulWidget {
  final String storagePath, downloadURL, fileName, mime, bucket;
  final EVC C;
  const _DocCard({required this.storagePath, required this.downloadURL,
    required this.fileName, required this.mime,
    required this.bucket, required this.C});
  @override State<_DocCard> createState() => _DocCardState();
}

class _DocCardState extends State<_DocCard> {
  String? _url;
  bool _copied = false;

  @override void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    final url = await getStorageDownloadUrl(
        widget.storagePath, widget.bucket);
    if (url.isNotEmpty && mounted) setState(() => _url = url);
  }

  Color get _c {
    if (widget.mime == 'application/pdf') return _P.red;
    if (widget.mime.contains('word') || widget.mime.contains('document'))
      return _P.accent;
    if (widget.mime.contains('sheet') || widget.mime.contains('excel'))
      return _P.green;
    return _P.muted;
  }
  IconData _icon() {
    if (widget.mime == 'application/pdf')
      return Icons.picture_as_pdf_outlined;
    if (widget.mime.contains('word') || widget.mime.contains('document'))
      return Icons.description_outlined;
    if (widget.mime.contains('sheet') || widget.mime.contains('excel'))
      return Icons.table_chart_outlined;
    return Icons.insert_drive_file_outlined;
  }
  String _label() {
    if (widget.mime == 'application/pdf') return 'PDF Document';
    if (widget.mime.contains('word') || widget.mime.contains('document'))
      return 'Word Document';
    if (widget.mime.contains('sheet') || widget.mime.contains('excel'))
      return 'Spreadsheet';
    return 'Document';
  }

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
        color: _c.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _c.withOpacity(0.15)),
        boxShadow: [BoxShadow(
            color: _c.withOpacity(0.05),
            blurRadius: 14, offset: const Offset(0, 4))]),
    child: Column(children: [
      Container(
          width: 68, height: 68,
          decoration: BoxDecoration(
              color: _c.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(_icon(), size: 32, color: _c)),
      const SizedBox(height: 14),
      Text(widget.fileName, textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis, maxLines: 2,
          style: const TextStyle(color: _P.ink,
              fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
              color: _c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20)),
          child: Text(_label(),
              style: TextStyle(color: _c, fontSize: 10,
                  fontWeight: FontWeight.w700))),
      const SizedBox(height: 22),
      if (_url == null)
        SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(color: _c, strokeWidth: 2))
      else
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: _url!));
            setState(() => _copied = true);
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) setState(() => _copied = false);
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('URL copied — paste in browser'),
                backgroundColor: _c, behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))));
          },
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                  color: _copied ? _P.green : _c,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(
                      color: (_copied ? _P.green : _c).withOpacity(0.28),
                      blurRadius: 14, offset: const Offset(0, 5))]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_copied ? Icons.check_rounded : Icons.copy_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(_copied ? 'Copied!' : 'Copy File URL',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ])),
        ),
      const SizedBox(height: 10),
      const Text('Copy the URL and open in your browser.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _P.muted, fontSize: 11)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  TAMPER BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _TamperBanner extends StatelessWidget {
  final String evidenceId;
  const _TamperBanner({required this.evidenceId});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: _P.redSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.red.withOpacity(0.35), width: 1.5),
        boxShadow: [BoxShadow(
            color: _P.red.withOpacity(0.07),
            blurRadius: 14, offset: const Offset(0, 4))]),
    child: Row(children: [
      Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              color: _P.red.withOpacity(0.12), shape: BoxShape.circle),
          child: const Icon(Icons.warning_amber_rounded,
              size: 20, color: _P.red)),
      const SizedBox(width: 12),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Integrity Compromised',
            style: TextStyle(color: _P.red,
                fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text('Hash no longer matches the blockchain record.',
            style: TextStyle(color: _P.red.withOpacity(0.75),
                fontSize: 11, height: 1.4)),
      ])),
      const SizedBox(width: 10),
      GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) =>
                  VerifyEvidenceScreen(evidenceId: evidenceId))),
          child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                  color: _P.red,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(
                      color: _P.red.withOpacity(0.3),
                      blurRadius: 10, offset: const Offset(0, 3))]),
              child: const Text('Re-verify',
                  style: TextStyle(color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.w700)))),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  SMALL UI ATOMS
// ─────────────────────────────────────────────────────────────────────────────
class _FilterChip extends StatefulWidget {
  final String label; final bool active;
  final Color color; final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active,
    required this.color, required this.onTap});
  @override State<_FilterChip> createState() => _FilterChipState();
}
class _FilterChipState extends State<_FilterChip> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hov = true),
    onExit:  (_) => setState(() => _hov = false),
    child: GestureDetector(onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            color: widget.active ? widget.color
                : _hov ? widget.color.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: widget.active ? widget.color : _P.border)),
        child: Text(widget.label,
            style: TextStyle(
                color: widget.active ? Colors.white
                    : _hov ? widget.color : _P.slate,
                fontSize: 11,
                fontWeight: widget.active
                    ? FontWeight.w700 : FontWeight.w500)),
      ),
    ),
  );
}

class _IconBtn extends StatefulWidget {
  final IconData i; final VoidCallback t; final String tip;
  const _IconBtn(this.i, this.t, this.tip);
  @override State<_IconBtn> createState() => _IconBtnState();
}
class _IconBtnState extends State<_IconBtn> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: widget.tip,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hov = true),
      onExit:  (_) => setState(() => _hov = false),
      child: GestureDetector(onTap: widget.t,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 32, height: 32,
          decoration: BoxDecoration(
              color: _hov ? _P.accentSoft : _P.inputBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _hov ? _P.accent.withOpacity(0.3) : _P.border)),
          child: Icon(widget.i, size: 15,
              color: _hov ? _P.accent : _P.slate),
        ),
      ),
    ),
  );
}

class _ActionBtn extends StatefulWidget {
  final IconData i; final Color c; final String tip; final VoidCallback t;
  const _ActionBtn(this.i, this.c, this.tip, this.t);
  @override State<_ActionBtn> createState() => _ActionBtnState();
}
class _ActionBtnState extends State<_ActionBtn> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: widget.tip,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hov = true),
      onExit:  (_) => setState(() => _hov = false),
      child: GestureDetector(onTap: widget.t,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 32, height: 32,
          decoration: BoxDecoration(
              color: widget.c.withOpacity(_hov ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.c.withOpacity(0.3)),
              boxShadow: _hov ? [BoxShadow(
                  color: widget.c.withOpacity(0.18),
                  blurRadius: 8, offset: const Offset(0, 2))] : []),
          child: Icon(widget.i, size: 15, color: widget.c),
        ),
      ),
    ),
  );
}

Widget _StatusDot(String status) {
  final color = switch (status) {
    'open'         => _P.green,
    'under_review' => _P.orange,
    'closed'       => _P.muted,
    _              => _P.accent,
  };
  return Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 5, height: 5,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(status.replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 9,
            fontWeight: FontWeight.w600)),
  ]);
}

Widget _StatusPill(String status) {
  final map = { 'anchored': _P.green, 'pending': _P.orange,
    'failed': _P.red, 'tampered': _P.red };
  final color = map[status] ?? _P.muted;
  return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(),
          style: TextStyle(color: color, fontSize: 8,
              fontWeight: FontWeight.w800)));
}

Widget _MiniTag(String text, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
  decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4)),
  child: Text(text,
      style: TextStyle(color: color, fontSize: 9,
          fontWeight: FontWeight.w700)),
);

Widget _MimeTag(String mime) {
  final d = _MimeData.from(mime);
  return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: d.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: d.color.withOpacity(0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(d.icon, size: 12, color: d.color),
        const SizedBox(width: 5),
        Text(d.label,
            style: TextStyle(color: d.color, fontSize: 10,
                fontWeight: FontWeight.w800)),
      ]));
}

Widget _BigBadge(String text, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3))),
  child: Text(text,
      style: TextStyle(color: color, fontSize: 11,
          fontWeight: FontWeight.w800)),
);

Widget _Section(String title) => Row(children: [
  Container(width: 3, height: 12,
      color: _P.accent, margin: const EdgeInsets.only(right: 8)),
  Text(title, style: const TextStyle(color: _P.ink,
      fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
]);

class _Meta extends StatelessWidget {
  final String l, v; final bool mono;
  final Color? valueColor; final VoidCallback? onCopy;
  const _Meta(this.l, this.v, {this.mono=false,
    this.valueColor, this.onCopy});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l, style: const TextStyle(color: _P.muted,
          fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      const SizedBox(height: 2),
      Row(children: [
        Expanded(child: SelectableText(v,
            style: TextStyle(
                color: valueColor ?? _P.ink,
                fontSize: 11, fontWeight: FontWeight.w600,
                fontFamily: mono ? 'monospace' : null))),
        if (onCopy != null)
          GestureDetector(onTap: onCopy,
              child: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.copy_outlined,
                      size: 11, color: _P.muted))),
      ]),
    ]),
  );
}

class _HashBlock extends StatelessWidget {
  final String hash; final VoidCallback onCopy;
  const _HashBlock({required this.hash, required this.onCopy});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onCopy,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: _P.green.withOpacity(0.06),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _P.green.withOpacity(0.2))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: SelectableText(hash,
            style: const TextStyle(color: _P.green,
                fontSize: 9, fontFamily: 'monospace', height: 1.6))),
        const Icon(Icons.copy_outlined, size: 11, color: _P.green),
      ]),
    ),
  );
}

class _PreviewLabel extends StatelessWidget {
  final IconData i; final Color c; final String t;
  const _PreviewLabel(this.i, this.c, this.t);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 4, height: 16,
        decoration: BoxDecoration(
            color: c, borderRadius: BorderRadius.circular(2)),
        margin: const EdgeInsets.only(right: 8)),
    Icon(i, size: 14, color: c),
    const SizedBox(width: 6),
    Text(t, style: TextStyle(color: _P.ink, fontSize: 13,
        fontWeight: FontWeight.w700)),
  ]);
}

// ── Shimmer loading ────────────────────────────────────────────────────────
class _ShimmerList extends StatefulWidget {
  const _ShimmerList();
  @override State<_ShimmerList> createState() => _ShimmerListState();
}
class _ShimmerListState extends State<_ShimmerList>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))..repeat();
    _anim = _ctrl.drive(Tween(begin: -1.0, end: 2.0)
        .chain(CurveTween(curve: Curves.easeInOut)));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      itemCount: 5,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          _sbox(40, 40, r: 9),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sbox(14, double.infinity),
            const SizedBox(height: 6),
            _sbox(10, 80),
          ])),
        ]),
      ),
    ),
  );
  Widget _sbox(double h, double w, {double r = 4}) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: LinearGradient(
            colors: [
              const Color(0xFFEEF2FF),
              Color.lerp(const Color(0xFFEEF2FF),
                  const Color(0xFFDDE5FF),
                  _anim.value.clamp(0.0, 1.0))!,
              const Color(0xFFEEF2FF),
            ])),
  );
}

class _ErrorState extends StatelessWidget {
  final String m; final VoidCallback onRetry;
  const _ErrorState({required this.m, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline_rounded, size: 32, color: _P.muted),
    const SizedBox(height: 8),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(m, textAlign: TextAlign.center,
            style: const TextStyle(color: _P.muted, fontSize: 12))),
    const SizedBox(height: 12),
    TextButton(onPressed: onRetry,
        child: const Text('Retry',
            style: TextStyle(color: _P.accent))),
  ],
  ));
}

class _EmptyCases extends StatelessWidget {
  const _EmptyCases();
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min, children: [
    Container(width: 56, height: 56,
        decoration: const BoxDecoration(
            color: _P.accentSoft, shape: BoxShape.circle),
        child: const Icon(Icons.folder_off_outlined,
            size: 26, color: _P.accent)),
    const SizedBox(height: 12),
    const Text('No cases found',
        style: TextStyle(color: _P.ink,
            fontSize: 14, fontWeight: FontWeight.w700)),
    const SizedBox(height: 4),
    const Text('Create a case first',
        style: TextStyle(color: _P.muted, fontSize: 12)),
  ],
  ));
}

// ─────────────────────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class _MimeData {
  final IconData icon; final Color color; final String label;
  const _MimeData(this.icon, this.color, this.label);
  factory _MimeData.from(String mime) {
    if (mime.startsWith('image/'))
      return const _MimeData(Icons.image_outlined, _P.accent, 'IMAGE');
    if (mime.startsWith('video/'))
      return const _MimeData(Icons.videocam_outlined, _P.purple, 'VIDEO');
    if (mime.startsWith('audio/'))
      return const _MimeData(Icons.headphones_outlined, _P.green, 'AUDIO');
    if (mime == 'application/pdf')
      return const _MimeData(Icons.picture_as_pdf_outlined, _P.red, 'PDF');
    if (mime.contains('word') || mime.contains('document'))
      return const _MimeData(Icons.description_outlined,
          Color(0xFF0284C7), 'DOC');
    return const _MimeData(Icons.insert_drive_file_outlined, _P.muted, 'FILE');
  }
}

Color _chainColor(String s) => switch (s) {
  'anchored' => _P.green,
  'pending'  => _P.orange,
  'failed'   => _P.red,
  _          => _P.muted,
};

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
      '${l.month.toString().padLeft(2,'0')}/${l.year}  '
      '${l.hour.toString().padLeft(2,'0')}:'
      '${l.minute.toString().padLeft(2,'0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
//  FIREBASE STORAGE URL — REST API, works on ALL platforms, no dart:ui_web
// ─────────────────────────────────────────────────────────────────────────────
Future<String> getStorageDownloadUrl(
    String storagePath, String bucket) async {
  if (storagePath.isEmpty) return '';
  try {
    final encoded = Uri.encodeComponent(storagePath);
    final apiUrl  =
        'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encoded';
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data  = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['downloadTokens'] as String? ?? '';
      if (token.isNotEmpty) return '$apiUrl?alt=media&token=$token';
      return '$apiUrl?alt=media';
    }
  } catch (_) {}
  if (!kIsWeb) {
    try {
      return await FirebaseStorage.instance
          .ref().child(storagePath).getDownloadURL();
    } catch (e) { debugPrint('Storage SDK: $e'); }
  }
  return '';
}